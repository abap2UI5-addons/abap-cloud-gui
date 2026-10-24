// The report2cloud playground of the site - the converter of
// tools/report2cloud, bundled for the browser (scripts/build-site.mjs).
// A report is converted in the page; nothing is sent anywhere. The examples
// are the reports of the converter's own corpus (examples.json, written by
// the build with their text pools).
import { convert, defaultClassName } from "../tools/report2cloud/lib/convert.mjs";
import { migrationReport } from "../tools/report2cloud/lib/report.mjs";

const $ = (id) => document.getElementById(id);
const source = $("source");
const output = $("output");
const tabs = $("tabs");
const status = $("status");
const findings = $("findings");
const example = $("example");
const classname = $("classname");

let examples = [];
let files = {};
let current = "";

const el = (tag, attrs = {}, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v;
    else e.setAttribute(k, v);
  }
  for (const k of kids) e.append(k);
  return e;
};

function show(name) {
  current = name;
  output.textContent = files[name] ?? "";
  for (const b of tabs.children) b.setAttribute("aria-selected", String(b.dataset.name === name));
}

function list(title, items, render) {
  if (!items.length) return;
  findings.append(el("h3", {}, `${title} (${items.length})`));
  const ul = el("ul");
  for (const it of items) ul.append(render(it));
  findings.append(ul);
}

const rowOf = (x) => el("span", { class: "row" }, x.row ? `${x.row}:${x.col ?? 1}` : "");

function run() {
  const text = source.value;
  const name = /^\s*(?:report|program)\s+([\w/]+)/im.exec(text)?.[1]?.toLowerCase() ?? "zreport";
  const chosen = examples.find((e) => e.name === example.value && e.source === text);
  let result;
  try {
    result = convert(text, {
      file: `${name.replace(/\//g, "#")}.prog.abap`,
      programName: name,
      className: classname.value.trim() || undefined,
      textpool: chosen?.textpool,
    });
  } catch (e) {
    status.className = "status bad";
    status.textContent = `The converter crashed - a bug worth an issue: ${e?.message ?? e}`;
    return;
  }

  files = { ...(result.ok ? result.files : result.draft) };
  files[`${result.className}.migration.md`] = migrationReport(result, { source: `${name}.prog.abap` });
  tabs.replaceChildren(...Object.keys(files)
    .sort((a, b) => (a.endsWith(".clas.abap") ? -1 : b.endsWith(".clas.abap") ? 1 : a.localeCompare(b)))
    .map((f) => {
      const b = el("button", { type: "button", role: "tab", "data-name": f }, f.replace(`${result.className}.`, ""));
      b.onclick = () => show(f);
      return b;
    }));
  show(Object.keys(files).find((f) => f.endsWith(".clas.abap")) ?? Object.keys(files)[0]);

  status.className = result.ok ? "status ok" : "status bad";
  status.textContent = result.ok
    ? `Converted into ${result.className} - ${result.mapped.length} statement(s) mapped, ${result.todos.length} TODO(s), ${result.release.length} object(s) to check for ABAP Cloud.`
    : `Refused: ${result.refusals.length} statement(s) have no counterpart - the draft shows how far it got.`;

  findings.replaceChildren();
  list("Refused", result.refusals, (r) => el("li", { class: "bad" }, rowOf(r), r.message));
  list("TODO", result.todos, (t) => el("li", { class: "warn" }, rowOf(t), t.message));
  list("Not released on ABAP Cloud", result.release, (r) => el("li", {}, rowOf(r), `${r.kind} ${r.name}${r.successor ? ` - ${r.successor}` : ""}`));
  list("Notes", result.notes, (n) => el("li", {}, n.text));
  list("Mapped", result.mapped, (m) => el("li", {}, rowOf(m), el("code", {}, m.classic.slice(0, 90)), " → ", m.target));
}

$("convert").onclick = run;
source.addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "Enter") run();
});
$("copy").onclick = async () => {
  try {
    await navigator.clipboard.writeText(files[current] ?? "");
    $("copy").textContent = "Copied";
    setTimeout(() => { $("copy").textContent = "Copy"; }, 1200);
  } catch {
    /* no clipboard in this context - the text can be selected by hand */
  }
};
example.onchange = () => {
  const e = examples.find((x) => x.name === example.value);
  if (!e) return;
  source.value = e.source;
  classname.value = "";
  classname.placeholder = defaultClassName(e.name);
  run();
};

try {
  // the Maps of a text pool come as { "$map": entries } (scripts/build-site.mjs)
  const reviver = (k, v) => (v && typeof v === "object" && Array.isArray(v.$map) ? new Map(v.$map) : v);
  examples = JSON.parse(await (await fetch("examples.json")).text(), reviver);
} catch {
  examples = [];
}
example.replaceChildren(...examples.map((e) => el("option", { value: e.name }, `${e.name} - ${e.title}`)));
if (examples.length) {
  example.value = examples[0].name;
  example.onchange();
}
