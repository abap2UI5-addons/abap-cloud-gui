// The report2cloud playground of the site - the converter of
// tools/report2cloud, bundled for the browser (scripts/build-site.mjs).
// A report is converted in the page; nothing is sent anywhere. Your own
// report is converted as it is typed or pasted, with the text pool of its
// .prog.xml when that is pasted too, and kept in this browser (localStorage)
// for the next visit. The examples are the reports of the converter's own
// corpus (examples.json, written by the build with their text pools).
import { convert, defaultClassName } from "../tools/report2cloud/lib/convert.mjs";
import { migrationReport } from "../tools/report2cloud/lib/report.mjs";
import { parseTextpool } from "../tools/report2cloud/lib/textpool.mjs";

const $ = (id) => document.getElementById(id);
const source = $("source");
const output = $("output");
const tabs = $("tabs");
const status = $("status");
const findings = $("findings");
const example = $("example");
const classname = $("classname");
const textpoolXml = $("textpool");
const STORE = "report2cloud.own";

let mode = "own";
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
  if (!text.trim()) {
    files = {};
    tabs.replaceChildren();
    output.replaceChildren(el("span", { class: "muted" }, "The generated class appears here."));
    status.className = "status";
    status.textContent = "";
    findings.replaceChildren();
    return;
  }
  const chosen = mode === "example" ? examples.find((e) => e.name === example.value && e.source === text) : undefined;
  let textpool = chosen?.textpool;
  if (mode === "own" && textpoolXml.value.trim()) {
    try {
      textpool = parseTextpool(textpoolXml.value);
    } catch {
      textpool = undefined;
    }
  }
  if (!classname.value.trim()) classname.placeholder = defaultClassName(name);
  let result;
  try {
    result = convert(text, {
      file: `${name.replace(/\//g, "#")}.prog.abap`,
      programName: name,
      className: classname.value.trim() || undefined,
      textpool,
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

// your own report: kept in this browser - an empty or blocked storage is no error
const save = () => {
  if (mode !== "own") return;
  try {
    localStorage.setItem(STORE, JSON.stringify({ source: source.value, textpool: textpoolXml.value, classname: classname.value }));
  } catch {
    /* no storage in this context */
  }
};
const load = () => {
  try {
    return JSON.parse(localStorage.getItem(STORE) ?? "null");
  } catch {
    return null;
  }
};

// converted as it is typed or pasted - a pause of a moment first
let timer;
const later = () => {
  clearTimeout(timer);
  timer = setTimeout(() => {
    save();
    run();
  }, 350);
};

// the buttons and fields of a mode - without touching the source
function showMode(next) {
  mode = next;
  $("mode-own").setAttribute("aria-pressed", String(mode === "own"));
  $("mode-example").setAttribute("aria-pressed", String(mode === "example"));
  $("example-label").hidden = mode !== "example";
  $("texts").hidden = mode !== "own";
}

function setMode(next) {
  showMode(next);
  if (mode === "own") {
    const kept = load();
    source.value = kept?.source ?? "";
    textpoolXml.value = kept?.textpool ?? "";
    classname.value = kept?.classname ?? "";
    run();
    source.focus();
  } else {
    example.onchange();
  }
}

$("mode-own").onclick = () => setMode("own");
$("mode-example").onclick = () => setMode("example");
$("convert").onclick = () => {
  save();
  run();
};
$("clear").onclick = () => {
  showMode("own");
  source.value = "";
  textpoolXml.value = "";
  classname.value = "";
  save();
  run();
  source.focus();
};
source.addEventListener("input", () => {
  // an example edited is your own report from now on
  if (mode === "example") showMode("own");
  later();
});
textpoolXml.addEventListener("input", later);
classname.addEventListener("input", later);
source.addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
    clearTimeout(timer);
    save();
    run();
  }
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

// the files as abapGit wants them beside each other - one download each
const download = (name) => {
  const a = el("a", { href: URL.createObjectURL(new Blob([files[name]], { type: "text/plain" })), download: name });
  document.body.append(a);
  a.click();
  setTimeout(() => {
    URL.revokeObjectURL(a.href);
    a.remove();
  }, 0);
};
$("download").onclick = () => {
  if (files[current] !== undefined) download(current);
};
$("download-all").onclick = () => {
  Object.keys(files).forEach((f, i) => setTimeout(() => download(f), i * 250));
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
if (examples.length) example.value = examples[0].name;
$("mode-example").disabled = !examples.length;
// your own report when one was kept, else the first example
setMode(load()?.source?.trim() || !examples.length ? "own" : "example");
