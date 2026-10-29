// The report2cloud playground of the site - three columns side by side: the
// classic report, the class the converter writes of it, and that class
// running as an abap2UI5 app - and below them what happened, step by step,
// and what the converter found.
//
// The converter is tools/report2cloud, bundled for the browser
// (scripts/build-site.mjs); a report is converted in the page as it is typed
// or pasted, with the text pool of its .prog.xml when that is pasted too, and
// kept in this browser (localStorage) for the next visit. The examples are
// the reports of the converter's own corpus (examples.json, written by the
// build with their text pools).
//
// Run starts the class in the third column: the abap2UI5 playground of this
// site (playground/, built with report2cloud by scripts/build-playground.mjs)
// in its app-only view (?view=full) - no editor, no bar, only the app. It is
// handed the report, with its .prog.xml, in the fragment of its URL, as the
// playground's own share links carry files (src/shell/share.mjs there: "2",
// then the JSON of the files deflated and base64url), converts it the same
// way and starts it. Nothing goes to a server. The frame is of this site, so
// the page reads its status line to say how far the start got.
import { convert, defaultClassName } from "../tools/report2cloud/lib/convert.mjs";
import { migrationReport } from "../tools/report2cloud/lib/report.mjs";
import { parseTextpool } from "../tools/report2cloud/lib/textpool.mjs";

const $ = (id) => document.getElementById(id);
const source = $("source");
const output = $("output");
const tabs = $("tabs");
const status = $("status");
const example = $("example");
const classname = $("classname");
const textpoolXml = $("textpool");
const frame = $("app");
const cover = $("app-cover");
const appState = $("app-state");
const STORE = "report2cloud.own";

let mode = "own";
let examples = [];
let files = {};
let current = "";
// the last conversion, and the source the app in the frame was started with
let last;
let running;
let runs = 0;
// the steps of "What happened": the reading, the conversion, the start
const steps = { read: undefined, convert: undefined, run: undefined };

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

const rowOf = (x) => el("span", { class: "row" }, x.row ? `${x.row}:${x.col ?? 1}` : "");

/** one info panel: its count and its list, or the word for none */
function panel(id, items, empty, render) {
  $(`n-${id}`).textContent = items.length ? String(items.length) : "";
  const box = $(id);
  if (!items.length) {
    box.className = "muted";
    box.textContent = empty;
    return;
  }
  box.className = "";
  box.replaceChildren(render(items));
}
const listOf = (items, li) => {
  const ul = el("ul");
  for (const it of items) ul.append(li(it));
  return ul;
};

function renderSteps() {
  const list = $("steps");
  list.replaceChildren(...[steps.read, steps.convert, steps.run].filter(Boolean)
    .map((s) => el("li", { class: s.state }, s.text)));
}

/** the report and its text pool as the converter takes them */
function input() {
  const text = source.value;
  const name = /^\s*(?:report|program)\s+([\w/]+)/im.exec(text)?.[1]?.toLowerCase() ?? "zreport";
  const chosen = mode === "example" ? examples.find((e) => e.name === example.value && e.source === text) : undefined;
  let textpool = chosen?.textpool;
  const xml = mode === "own" ? textpoolXml.value.trim() : chosen?.xml;
  if (mode === "own" && xml) {
    try {
      textpool = parseTextpool(xml);
    } catch {
      textpool = undefined;
    }
  }
  return { text, name, textpool, xml };
}

function run() {
  const { text, name, textpool } = input();
  if (!text.trim()) {
    files = {};
    last = undefined;
    tabs.replaceChildren();
    output.replaceChildren(el("span", { class: "muted" }, "The generated class appears here."));
    status.className = "status";
    status.textContent = "";
    steps.read = steps.convert = undefined;
    renderSteps();
    for (const [id, empty] of [["refused", "Nothing."], ["todo", "Nothing."], ["release", "Nothing to check."], ["mapped", "Nothing yet."]]) panel(id, [], empty);
    $("migration").textContent = "";
    markStale();
    return;
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
  last = { result, text };

  files = { ...(result.ok ? result.files : result.draft) };
  const report = migrationReport(result, { source: `${name}.prog.abap` });
  files[`${result.className}.migration.md`] = report;
  tabs.replaceChildren(...Object.keys(files)
    .sort((a, b) => (a.endsWith(".clas.abap") ? -1 : b.endsWith(".clas.abap") ? 1 : a.localeCompare(b)))
    .map((f) => {
      const b = el("button", { type: "button", role: "tab", "data-name": f }, f.replace(`${result.className}.`, ""));
      b.onclick = () => show(f);
      return b;
    }));
  show(Object.keys(files).find((f) => f === `${result.className}.clas.abap`) ?? Object.keys(files)[0]);

  status.className = result.ok ? "status ok" : "status bad";
  status.textContent = result.ok
    ? `Converted into ${result.className} - ${result.mapped.length} statement(s) mapped, ${result.todos.length} TODO(s), ${result.release.length} object(s) to check for ABAP Cloud.`
    : `Refused: ${result.refusals.length} statement(s) have no counterpart - the draft shows how far it got; nothing can run until they are rewritten.`;

  const lines = text.split("\n").length;
  steps.read = { state: "ok", text: `Read the report ${name.toUpperCase()}: ${lines} lines${textpool ? ", with its text pool" : " - no text pool, the labels are the field names"}.` };
  steps.convert = result.ok
    ? { state: "ok", text: `Converted it into the class ${result.className}${Object.keys(result.files).filter((f) => f.endsWith(".abap")).length > 1 ? ` and ${Object.keys(result.files).filter((f) => f.endsWith(".abap") && !f.startsWith(`${result.className}.clas.abap`)).join(", ")}` : ""} - ${result.mapped.length} statements mapped onto abap-cloud-gui.` }
    : { state: "bad", text: `Refused ${result.refusals.length} statement(s) - see Refused; the class is a draft.` };
  renderSteps();

  panel("refused", result.refusals, "Nothing.", (items) => listOf(items, (r) => el("li", { class: "bad" }, rowOf(r), r.message)));
  panel("todo", result.todos, "Nothing.", (items) => listOf(items, (t) => el("li", { class: "warn" }, rowOf(t), t.message)));
  panel("release", result.release, "Nothing to check.", (items) => listOf(items, (r) => el("li", {}, rowOf(r), `${r.kind} ${r.name}${r.successor ? ` - ${r.successor}` : ""}`)));
  panel("mapped", result.mapped, "Nothing yet.", (items) => {
    const table = el("table", { class: "mapped" }, el("thead", {}, el("tr", {}, el("th", {}, "Line"), el("th", {}, "Classic"), el("th", {}, "abap-cloud-gui"))));
    const body = el("tbody");
    // the target as the migration report writes it: `code` in backticks
    const target = (text) => text.split("`").map((part, i) => (i % 2 ? el("code", {}, part) : part));
    for (const m of items) body.append(el("tr", {}, el("td", {}, String(m.row ?? "")), el("td", {}, el("code", {}, m.classic.slice(0, 120))), el("td", {}, ...target(m.target))));
    table.append(body);
    return table;
  });
  $("migration").textContent = report;
  markStale();
}

/** the app in the frame was started with another source - Run starts this one */
function markStale() {
  if (running === undefined) return;
  const same = last && running === last.text;
  appState.textContent = same ? "" : "the report changed - Run starts it again";
}

// the files for the playground: the report - the first file, the app - and
// its text pool. abapGit's name of it, lower case; a namespace (/abc/rep)
// has no file name the playground takes, so such a report goes as zreport
async function fragmentOf() {
  const { text, name: program, xml } = input();
  const name = /^[a-z][a-z0-9_]*$/.test(program) ? program : "zreport";
  const list = [{ name: `${name}.prog.abap`, source: text }];
  if (xml) list.push({ name: `${name}.prog.xml`, source: xml });
  const bytes = new TextEncoder().encode(JSON.stringify(list));
  const deflated = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new CompressionStream("deflate-raw"))).arrayBuffer());
  let binary = "";
  for (let i = 0; i < deflated.length; i += 0x8000) binary += String.fromCharCode(...deflated.subarray(i, i + 0x8000));
  return `2${btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "")}`;
}

/** starts the class in the third column, and follows the start */
async function runApp() {
  if (!source.value.trim()) {
    status.className = "status bad";
    status.textContent = "Paste a report first - or pick an example.";
    return;
  }
  if (!last || last.text !== source.value) run();
  if (!last.result.ok) {
    steps.run = { state: "bad", text: "Not started: the converter refused statements of the report - rewrite them first." };
    renderSteps();
    cover.hidden = false;
    cover.textContent = "The report has statements the converter refuses - see Refused below.";
    return;
  }
  running = last.text;
  appState.textContent = "";
  const run = ++runs;
  steps.run = { state: "wait", text: "Starting it: the abap2UI5 runtime, the report runtime of abap-cloud-gui and the class are loaded in this browser..." };
  renderSteps();
  cover.hidden = false;
  cover.textContent = "Starting...";
  frame.src = new URL(`playground/?view=full&run=${run}#${await fragmentOf()}`, document.baseURI).href;
  // the frame's status line - the page and the frame are of one site
  const started = Date.now();
  const poll = () => {
    if (run !== runs) return;
    let said = "";
    try {
      said = frame.contentDocument?.getElementById("status")?.textContent?.trim() ?? "";
    } catch {
      said = "";
    }
    if (/^running/.test(said)) {
      cover.hidden = true;
      steps.run = { state: "ok", text: `Started the class ${last.result.className} as an abap2UI5 app - in the column above, in ${((Date.now() - started) / 1000).toFixed(1)} s. Use it like the report: the selection screen, Execute (F8), the list.` };
      renderSteps();
      return;
    }
    if (/could not|cannot|error/i.test(said)) {
      cover.hidden = false;
      let log = "";
      try {
        log = frame.contentDocument?.querySelector(".log-body")?.textContent?.trim() ?? "";
      } catch {
        log = "";
      }
      cover.textContent = `It did not start: ${said}`;
      steps.run = { state: "bad", text: `It did not start: ${said}${log ? ` - ${log.slice(0, 300)}` : ""}` };
      renderSteps();
      return;
    }
    if (Date.now() - started > 120000) {
      steps.run = { state: "bad", text: "It did not start within two minutes - is the network down?" };
      renderSteps();
      return;
    }
    if (said) {
      cover.textContent = said;
      steps.run = { state: "wait", text: `Starting it: ${said}` };
      renderSteps();
    }
    setTimeout(poll, 400);
  };
  setTimeout(poll, 400);
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

// the mode already shown is not started again
$("mode-own").onclick = () => mode !== "own" && setMode("own");
$("mode-example").onclick = () => mode !== "example" && setMode("example");
$("run").onclick = () => runApp();
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
// an example: converted and started at once
example.onchange = () => {
  const e = examples.find((x) => x.name === example.value);
  if (!e) return;
  source.value = e.source;
  classname.value = "";
  classname.placeholder = defaultClassName(e.name);
  run();
  // the example that runs already stays as it is - Run starts it again
  if (running !== source.value) runApp();
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
