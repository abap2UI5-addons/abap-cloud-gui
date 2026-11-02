// The report2UI5 part of the site, on two pages:
//
// - Samples: a report of the converter's own corpus (examples.json, written
//   by scripts/build-site.mjs with its text pool), the class the converter
//   writes of it and that class running as an abap2UI5 app - side by side,
//   started when the sample is picked.
// - Playground, top to bottom: (1) where to start from - your own source
//   (converted as it is typed, kept in this browser for the next visit), a
//   GitHub link (site/github.mjs) or an abapGit zip; a folder or a zip lists
//   its reports, each of which opens as your own source; (2) the class the
//   converter writes; (3) the preview - Run starts the class as an app;
//   (4) the conversion in detail, in tabs: what happened, refused, to do,
//   mapped, the migration report, the summary of a package.
//
// The converter is tools/report2ui5, bundled for the browser. A class runs
// in the abap2UI5 playground itself (https://abap2ui5.github.io/playground/),
// framed in its app-only view (?embed=1&view=app) - no editor, no bar, only
// the app. It is handed the class the converter wrote, the report runtime of
// src/01 and the demo tables with their rows, in the fragment of its URL, as
// the playground's own share links carry files (src/shell/share.mjs there:
// "2", then the JSON of the files deflated and base64url). Nothing goes to a
// server. The frame is of another site, so the page listens to what the
// playground says to the page that framed it (src/shell/embed.mjs there):
// its status line, and the abaplint errors that stopped a Run.
//
// The page is VitePress (site/.vitepress): its Playground component renders
// the markup and calls mount( ) once it is in the document - again after
// every visit of the page, as VitePress navigates without a reload; the
// function mount( ) answers takes the listeners of the window down. This
// module is bundled by scripts/build-site.mjs into public/r2u/playground.js,
// beside examples.json and runtime.json, which it fetches relative to itself.
import { convert, defaultClassName } from "../tools/report2ui5/lib/convert.mjs";
import { migrationReport } from "../tools/report2ui5/lib/report.mjs";
import { parseTextpool } from "../tools/report2ui5/lib/textpool.mjs";
import { highlightAbap, highlightFile } from "./highlight.mjs";
import { abapgitZip } from "./zip.mjs";
import { unzipTexts } from "./unzip.mjs";
import { convertPackage } from "../tools/report2ui5/lib/package.mjs";
import { folderFiles, getText, parseGithub, rawUrl } from "./github.mjs";
import { SCARR, SPFLI, sflight } from "../tools/report2ui5/test/runtime/seed.mjs";

const $ = (id) => document.getElementById(id);
const STORE = "report2ui5.own";

// your own report, kept in this browser - an empty or blocked storage is no error
const keep = (own) => {
  try {
    localStorage.setItem(STORE, JSON.stringify(own));
  } catch {
    /* no storage in this context */
  }
};
const kept = () => {
  try {
    // the key of the name before report2UI5 - a report kept then is read once more
    return JSON.parse(localStorage.getItem(STORE) ?? localStorage.getItem("report2cloud.own") ?? "null");
  } catch {
    return null;
  }
};

const el = (tag, attrs = {}, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v;
    else e.setAttribute(k, v);
  }
  for (const k of kids) e.append(k);
  return e;
};

// ------------------------------------------------------------ shared parts

const nameOf = (text) => /^\s*(?:report|program)\s+([\w/]+)/im.exec(text)?.[1]?.toLowerCase() ?? "zreport";

/** a report converted: the result, its files with the migration report, and
 *  the class first */
function convertReport(text, { textpool, className } = {}) {
  const name = nameOf(text);
  const result = convert(text, { file: `${name.replace(/\//g, "#")}.prog.abap`, programName: name, className, textpool });
  const report = migrationReport(result, { source: `${name}.prog.abap` });
  const files = { ...(result.ok ? result.files : result.draft), [`${result.className}.migration.md`]: report };
  return { name, result, report, files };
}

/** the files of a conversion as tabs over a <pre>, highlighted; answers the
 *  name of the file shown */
function fileTabs(tabs, output, files, className) {
  let current;
  const show = (name) => {
    current = name;
    output.innerHTML = highlightFile(name, files[name] ?? "");
    for (const b of tabs.children) b.setAttribute("aria-selected", String(b.dataset.name === name));
  };
  tabs.replaceChildren(...Object.keys(files)
    .sort((a, b) => (a === `${className}.clas.abap` ? -1 : b === `${className}.clas.abap` ? 1 : a.localeCompare(b)))
    .map((f) => {
      const b = el("button", { type: "button", role: "tab", "data-name": f }, f.replace(`${className}.`, ""));
      b.onclick = () => show(f);
      return b;
    }));
  show(Object.keys(files).find((f) => f === `${className}.clas.abap`) ?? Object.keys(files)[0]);
  return () => current;
}

const rowOf = (x) => el("span", { class: "row" }, x.row ? `${x.row}:${x.col ?? 1}` : "");
const listOf = (items, li) => {
  const ul = el("ul");
  for (const it of items) ul.append(li(it));
  return ul;
};

/** one info panel: its count and its list, or the word for none */
function panel(id, items, empty, render) {
  const count = $(id.replace(/^(s-)?/, "$1n-"));
  if (count) count.textContent = items.length ? String(items.length) : "";
  const box = $(id);
  if (!items.length) {
    box.className = "muted";
    box.textContent = empty;
    return;
  }
  box.className = "";
  box.replaceChildren(render(items));
}

/** the panels of a conversion; prefix "s-" for the samples */
function panels(prefix, result) {
  if (!result) {
    for (const [id, empty] of [["refused", "Nothing."], ["todo", "Nothing."], ["mapped", "Nothing yet."]]) {
      if ($(prefix + id)) panel(prefix + id, [], empty);
    }
    return;
  }
  if ($(`${prefix}refused`)) panel(`${prefix}refused`, result.refusals, "Nothing.", (items) => listOf(items, (r) => el("li", { class: "bad" }, rowOf(r), r.message)));
  panel(`${prefix}todo`, result.todos, "Nothing.", (items) => listOf(items, (t) => el("li", { class: "warn" }, rowOf(t), t.message)));
  panel(`${prefix}mapped`, result.mapped, "Nothing yet.", (items) => {
    const table = el("table", { class: "mapped" }, el("thead", {}, el("tr", {}, el("th", {}, "Line"), el("th", {}, "Classic"), el("th", {}, "abap-cloud-gui"))));
    const body = el("tbody");
    // the target as the migration report writes it: `code` in backticks
    const target = (text) => text.split("`").map((part, i) => (i % 2 ? el("code", {}, part) : part));
    for (const m of items) body.append(el("tr", {}, el("td", {}, String(m.row ?? "")), el("td", {}, el("code", {}, m.classic.slice(0, 120))), el("td", {}, ...target(m.target))));
    table.append(body);
    return table;
  });
}

/** the steps of "What happened" */
function renderSteps(list, steps) {
  list.replaceChildren(...[steps.read, steps.convert, steps.run].filter(Boolean).map((s) => el("li", { class: s.state }, s.text)));
}

function stepsOf(name, text, textpool, result) {
  const files = Object.keys(result.files).filter((f) => f.endsWith(".abap") && !f.startsWith(`${result.className}.clas`));
  return {
    read: { state: "ok", text: `Read the report ${name.toUpperCase()}: ${text.split("\n").length} lines${textpool ? ", with its text pool" : " - no text pool, the labels are the field names"}.` },
    convert: result.ok
      ? { state: "ok", text: `Converted it into the class ${result.className}${files.length ? ` and ${files.join(", ")}` : ""} - ${result.mapped.length} statements mapped onto abap-cloud-gui.` }
      : { state: "bad", text: `Refused ${result.refusals.length} statement(s) - the class is a draft, nothing can run until they are rewritten.` },
  };
}

const PLAYGROUND = "https://abap2ui5.github.io/playground/";
const FROM_PLAYGROUND = "abap2ui5-playground";

/** the .abap files of a conversion, the class first - the playground takes
 *  the first file as the app */
const classFiles = (all, className) => Object.fromEntries(Object.entries(all)
  .filter(([n]) => n.endsWith(".abap"))
  .sort(([a], [b]) => (a === `${className}.clas.abap` ? -1 : b === `${className}.clas.abap` ? 1 : a.localeCompare(b))));

// the report runtime and the demo tables (runtime.json, scripts/build-site.mjs),
// fetched once, when the first app starts
let runtime;
const runtimeFiles = () => (runtime ??= fetch(new URL("runtime.json", import.meta.url)).then((r) => {
  if (!r.ok) throw new Error(`runtime.json: ${r.status}`);
  return r.json();
}));

/** the rows of the demo tables, as the playground's .tabu.json takes them -
 *  the flight dates count from today */
const demoRows = () => [
  { name: "scarr.tabu.json", source: JSON.stringify(SCARR, null, 1) },
  { name: "spfli.tabu.json", source: JSON.stringify(SPFLI, null, 1) },
  { name: "sflight.tabu.json", source: JSON.stringify(sflight(), null, 1) },
];

/** everything the playground runs: the class files first, then the runtime */
async function playgroundFiles(classes) {
  const own = Object.entries(classes).map(([name, source]) => ({ name, source }));
  const taken = new Set(own.map((f) => f.name));
  return [...own, ...(await runtimeFiles()).filter((f) => !taken.has(f.name)), ...demoRows().filter((f) => !taken.has(f.name))];
}

/** files in the fragment of the playground's URL, as its share links carry them */
async function fragmentOf(list) {
  const bytes = new TextEncoder().encode(JSON.stringify(list));
  const deflated = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new CompressionStream("deflate-raw"))).arrayBuffer());
  let binary = "";
  for (let i = 0; i < deflated.length; i += 0x8000) binary += String.fromCharCode(...deflated.subarray(i, i + 0x8000));
  return `2${btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "")}`;
}

/** an app in a frame: start( classes, className ) - the class files of a
 *  conversion, the app's class first - and the start followed, onStep( {
 *  state, text } ) as it goes. `open` is a link that opens the same files in
 *  the playground with its editor. Answers how it ended: { ok, said, problems
 *  } - problems what stopped the Run in the playground, by file and line. */
function appFrame(frame, cover, onStep, open, signal) {
  let runs = 0;
  let heard = () => {};
  window.addEventListener("message", (e) => {
    if (e.source === frame.contentWindow && e.data?.source === FROM_PLAYGROUND) heard(e.data);
  }, { signal });
  return async (classes, className) => {
    const run = ++runs;
    onStep({ state: "wait", text: "Starting it in the abap2UI5 playground: the abap2UI5 runtime, the report runtime of abap-cloud-gui and the class are loaded in this browser..." });
    cover.hidden = false;
    cover.textContent = "Starting...";
    let fragment;
    try {
      fragment = await fragmentOf(await playgroundFiles(classes));
    } catch (e) {
      cover.textContent = "The report runtime could not be loaded.";
      onStep({ state: "bad", text: `The report runtime could not be loaded: ${e?.message ?? e}` });
      return { ok: false, said: String(e?.message ?? e), problems: [] };
    }
    if (run !== runs) return { ok: false, said: "started again", problems: [] };
    if (open) {
      open.href = `${PLAYGROUND}#${fragment}`;
      open.hidden = false;
    }
    const started = Date.now();
    let problems = [];
    return new Promise((resolve) => {
      const done = (outcome) => {
        clearTimeout(timer);
        heard = () => {};
        resolve(outcome);
      };
      const timer = setTimeout(() => {
        onStep({ state: "bad", text: "It did not start within two minutes - is the network down?" });
        done({ ok: false, said: "no start within two minutes", problems: [] });
      }, 120000);
      heard = (m) => {
        if (run !== runs) return done({ ok: false, said: "started again", problems: [] });
        if (m.type === "problems" && Array.isArray(m.problems)) problems = m.problems;
        if (m.type !== "status" || typeof m.message !== "string") return;
        const said = m.message.trim();
        if (m.state === "running" && /^running/.test(said)) {
          cover.hidden = true;
          onStep({ state: "ok", text: `Started the class ${className} as an abap2UI5 app, in ${((Date.now() - started) / 1000).toFixed(1)} s. Use it like the report: the selection screen, Execute (F8), the list.` });
          return done({ ok: true, said, problems: [] });
        }
        if (m.state === "error") {
          cover.textContent = `It did not start: ${said}`;
          onStep({ state: "bad", text: `It did not start: ${said}` });
          return done({ ok: false, said, problems });
        }
        if (said) {
          cover.textContent = said;
          onStep({ state: "wait", text: `Starting it: ${said}` });
        }
      };
      frame.src = `${PLAYGROUND}?embed=1&view=app&run=${run}#${fragment}`;
    });
  };
}

const copyTo = (button, text) => async () => {
  try {
    await navigator.clipboard.writeText(text() ?? "");
    const was = button.textContent;
    button.textContent = "Copied";
    setTimeout(() => { button.textContent = was; }, 1200);
  } catch {
    /* no clipboard in this context - the text can be selected by hand */
  }
};

// one file of the class, as it is
const download = (name, text, type = "text/plain") => {
  const a = el("a", { href: URL.createObjectURL(new Blob([text], { type })), download: name });
  document.body.append(a);
  a.click();
  setTimeout(() => {
    URL.revokeObjectURL(a.href);
    a.remove();
  }, 0);
};

// all the files as the zip abapGit imports offline (Repository - New Offline,
// then Import zip): .abapgit.xml and the objects under src/ - the way into
// the system in one click
const downloadZip = (files, className) => download(`${className}.zip`, abapgitZip(files, className), "application/zip");

/** the playground on a page: the samples (site/samples.md) or your own
 *  report, GitHub and the package (site/playground.md) - whichever sections
 *  the page has. go( path ) navigates within the site (VitePress' router).
 *  Answers the function that takes it down again. */
export async function mount({ go = (path) => { location.href = new URL(`..${path}`, import.meta.url).href; } } = {}) {
  const ac = new AbortController();
  const { signal } = ac;
  if ($("samples")) {
    let examples = [];
    try {
      // the Maps of a text pool come as { "$map": entries } (scripts/build-site.mjs)
      const reviver = (k, v) => (v && typeof v === "object" && Array.isArray(v.$map) ? new Map(v.$map) : v);
      examples = JSON.parse(await (await fetch(new URL("examples.json", import.meta.url))).text(), reviver);
    } catch {
      examples = [];
    }
    // the page was left while the examples loaded
    if (!$("samples")) return () => {};
    samplesSection(examples, signal, go);
  }
  if ($("playground")) {
    switches();
    const own = ownSection(signal);
    const pkg = packageSection(own);
    githubSection(own, pkg, signal);
  }
  return () => ac.abort();
}

/** the tab rows of the page ([data-tabs]): a button with data-tab shows the
 *  panel of that id and hides the panels of the others */
function switches() {
  for (const list of document.querySelectorAll("[data-tabs]")) {
    const buttons = [...list.querySelectorAll("[data-tab]")];
    for (const b of buttons) {
      b.onclick = () => {
        for (const x of buttons) {
          const on = x === b;
          x.setAttribute("aria-selected", String(on));
          $(x.dataset.tab).hidden = !on;
        }
      };
    }
  }
}

/** shows a tab of a row - onlyIfHidden: only when the selected tab is gone */
function selectTab(id, onlyIfHidden = false) {
  const b = document.querySelector(`[data-tab="${id}"]`);
  if (!b) return;
  if (onlyIfHidden && [...b.parentElement.querySelectorAll("[data-tab]")].some((x) => x.getAttribute("aria-selected") === "true" && !x.hidden)) return;
  b.click();
}

// ---------------------------------------------------------------- samples

function samplesSection(examples, signal, go) {

  const select = $("s-example");
  const steps = {};
  const stepList = $("s-steps");
  let sample;
  let shown = () => undefined;
  let files = {};
  const start = appFrame($("s-app"), $("s-cover"), (s) => {
    steps.run = s;
    renderSteps(stepList, steps);
  }, $("s-open"), signal);

  const pick = () => {
    const e = examples.find((x) => x.name === select.value);
    if (!e) return;
    sample = e;
    $("s-name").textContent = `${e.name}.prog.abap`;
    $("s-source").innerHTML = highlightAbap(e.source);
    const c = convertReport(e.source, { textpool: e.textpool });
    files = c.files;
    shown = fileTabs($("s-tabs"), $("s-output"), files, c.result.className);
    Object.assign(steps, stepsOf(c.name, e.source, e.textpool, c.result), { run: undefined });
    panels("s-", c.result);
    if (c.result.ok) start(classFiles(files, c.result.className), c.result.className);
    else {
      $("s-app").src = "about:blank";
      $("s-open").hidden = true;
      $("s-cover").hidden = false;
      $("s-cover").textContent = "This sample is refused - the converter says which statements it cannot map, under Refused.";
      steps.run = undefined;
    }
    renderSteps(stepList, steps);
  };

  select.replaceChildren(...examples.map((e) => el("option", { value: e.name }, `${e.name} - ${e.title}`)));
  select.onchange = pick;
  const step = (by) => () => {
    select.selectedIndex = (select.selectedIndex + by + select.options.length) % select.options.length;
    pick();
  };
  $("s-prev").onclick = step(-1);
  $("s-next").onclick = step(1);
  $("s-restart").onclick = () => pick();
  $("s-copy").onclick = copyTo($("s-copy"), () => files[shown()]);
  $("s-download").onclick = () => shown() && download(shown(), files[shown()]);
  $("s-zip").onclick = () => sample && Object.keys(files).length && downloadZip(files, convertReport(sample.source, { textpool: sample.textpool }).result.className);
  // the sample as your own report, to change it: kept as your own, then the
  // playground, which takes what is kept
  $("s-try").onclick = () => {
    if (!sample) return;
    keep({ source: sample.source, textpool: sample.xml ?? "", classname: "" });
    go("/playground");
  };
  if (examples.length) {
    select.value = examples[0].name;
    // started once the section comes into view - not for a visitor who never scrolls there
    const observer = new IntersectionObserver((entries) => {
      if (!entries.some((x) => x.isIntersecting)) return;
      observer.disconnect();
      pick();
    }, { rootMargin: "200px" });
    observer.observe($("samples"));
    signal.addEventListener("abort", () => observer.disconnect());
  } else {
    $("samples").hidden = true;
  }
}

// ---------------------------------------------------------- your own report

const COVER = "Run starts the class as an abap2UI5 app - the selection screen, Execute (F8), the list.";

/** the editor of your own report - answers open( { source, xml } ), which
 *  makes a report your own: kept, converted, shown */
function ownSection(signal) {

  const source = $("source");
  const highlighted = $("source-hl");
  const output = $("output");
  const status = $("status");
  const classname = $("classname");
  const textpoolXml = $("textpool");
  const appState = $("app-state");
  const runButton = $("run");
  const stepList = $("steps");
  const steps = {};
  let files = {};
  let shown = () => undefined;
  // the last conversion, and the source the app in the frame was started with
  let last;
  let running;

  const start = appFrame($("own-app"), $("own-app-cover"), (s) => {
    steps.run = s;
    renderSteps(stepList, steps);
  }, $("own-app-open"), signal);

  // the highlighted copy under the text area: the same text, the same scroll
  const paint = () => {
    // a last line break shows as a line in a text area, not in a <pre>
    highlighted.innerHTML = `${highlightAbap(source.value)}\n`;
    highlighted.scrollTop = source.scrollTop;
    highlighted.scrollLeft = source.scrollLeft;
  };
  source.addEventListener("scroll", () => {
    highlighted.scrollTop = source.scrollTop;
    highlighted.scrollLeft = source.scrollLeft;
  });

  const textpoolOf = () => {
    const xml = textpoolXml.value.trim();
    if (!xml) return {};
    try {
      return { xml, textpool: parseTextpool(xml) };
    } catch {
      return { xml };
    }
  };

  const run = () => {
    const text = source.value;
    paint();
    if (!text.trim()) {
      files = {};
      last = undefined;
      $("tabs").replaceChildren();
      output.replaceChildren(el("span", { class: "muted" }, "The generated class appears here."));
      status.className = "status";
      status.textContent = "";
      steps.read = steps.convert = undefined;
      renderSteps(stepList, steps);
      panels("", undefined);
      $("migration").textContent = "";
      markStale();
      return;
    }
    const { textpool } = textpoolOf();
    if (!classname.value.trim()) classname.placeholder = defaultClassName(nameOf(text));
    let c;
    try {
      c = convertReport(text, { textpool, className: classname.value.trim() || undefined });
    } catch (e) {
      status.className = "status bad";
      status.textContent = `The converter crashed - a bug worth an issue: ${e?.message ?? e}`;
      return;
    }
    last = { result: c.result, text };
    files = c.files;
    shown = fileTabs($("tabs"), output, files, c.result.className);
    const { result } = c;
    status.className = result.ok ? "status ok" : "status bad";
    status.textContent = result.ok
      ? `Converted into ${result.className} - ${result.mapped.length} statement(s) mapped, ${result.todos.length} TODO(s).`
      : `Refused: ${result.refusals.length} statement(s) have no counterpart - the draft shows how far it got; nothing can run until they are rewritten.`;
    Object.assign(steps, stepsOf(c.name, text, textpool, result));
    // the app in the frame is of another report - its start is no step of this one
    if (running !== text) steps.run = undefined;
    renderSteps(stepList, steps);
    panels("", result);
    $("migration").textContent = c.report;
    markStale();
  };

  /** the app in the frame was started with another source - Run starts this one */
  function markStale() {
    if (running === undefined) {
      $("own-app-cover").textContent = COVER;
      return;
    }
    appState.textContent = last && running === last.text ? "" : "the report changed - Run starts it again";
  }

  const runApp = () => {
    if (!source.value.trim()) {
      status.className = "status bad";
      status.textContent = "Start from a report first - your own source, a GitHub link or a zip (1).";
      $("own-app-cover").hidden = false;
      $("own-app-cover").textContent = "No report yet - start from one under 1, or take a sample (Samples, Edit it in the playground).";
      return;
    }
    if (!last || last.text !== source.value) run();
    if (!last.result.ok) {
      steps.run = { state: "bad", text: "Not started: the converter refused statements of the report - rewrite them first." };
      renderSteps(stepList, steps);
      $("own-app-cover").hidden = false;
      $("own-app-cover").textContent = "The report has statements the converter refuses - see Refused below.";
      selectTab("det-refused");
      return;
    }
    running = last.text;
    appState.textContent = "";
    start(classFiles(files, last.result.className), last.result.className);
  };

  const save = () => keep({ source: source.value, textpool: textpoolXml.value, classname: classname.value });

  // converted as it is typed or pasted - a pause of a moment first; the
  // highlighting follows every key at once
  let timer;
  const later = () => {
    paint();
    clearTimeout(timer);
    timer = setTimeout(() => {
      save();
      run();
    }, 350);
  };

  runButton.onclick = () => runApp();
  $("convert").onclick = () => {
    save();
    run();
  };
  $("clear").onclick = () => {
    source.value = "";
    textpoolXml.value = "";
    classname.value = "";
    save();
    run();
    source.focus();
  };
  source.addEventListener("input", later);
  textpoolXml.addEventListener("input", later);
  classname.addEventListener("input", later);
  source.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
      clearTimeout(timer);
      save();
      run();
    }
    // a tab indents, as in an editor
    if (e.key === "Tab" && !e.shiftKey && !e.ctrlKey && !e.metaKey) {
      e.preventDefault();
      document.execCommand?.("insertText", false, "  ") || source.setRangeText("  ", source.selectionStart, source.selectionEnd, "end");
      later();
    }
  });
  $("copy").onclick = copyTo($("copy"), () => files[shown()]);
  $("download").onclick = () => shown() && download(shown(), files[shown()]);
  $("download-all").onclick = () => last?.result.ok && downloadZip(files, last.result.className);

  signal.addEventListener("abort", () => clearTimeout(timer));

  const was = kept();
  source.value = was?.source ?? "";
  textpoolXml.value = was?.textpool ?? "";
  classname.value = was?.classname ?? "";
  run();

  const open = ({ source: text, xml }) => {
    source.value = text;
    textpoolXml.value = xml ?? "";
    classname.value = "";
    save();
    run();
    selectTab("src-own");
    $("converted").scrollIntoView({ behavior: "smooth" });
  };
  return { open };
}

// ---------------------------------------------------------- a whole package

/** the files of a dropped zip (or the files themselves), or of a folder on
 *  GitHub, converted in this browser, one zip back - answers convertFiles(
 *  files, name ); a report of the table opens in the editor (own.open) */
function packageSection(own) {

  const drop = $("pkg-drop");
  const input = $("pkg-files");
  const text = $("pkg-drop-text");
  const zipButton = $("pkg-zip");
  const clear = $("pkg-clear");
  const result = $("pkg-result");
  let out;
  // the files converted, for Open
  let sources = {};

  const show = (pkg, name) => {
    out = pkg;
    const converted = pkg.rows.filter((r) => r.ok).length;
    $("pkg-summary").textContent = pkg.rows.length
      ? `${name}: ${pkg.rows.length} report(s), ${converted} converted, ${pkg.rows.length - converted} refused.`
      : `${name}: no report in it - a report is a .prog.abap with a REPORT or PROGRAM statement.`;
    $("pkg-table").querySelector("tbody").replaceChildren(...pkg.rows.map((r, i) => {
      return el("tr", {},
        el("td", {}, String(i + 1)),
        el("td", { class: "mono" }, r.name),
        el("td", { class: "mono" }, r.className),
        el("td", { class: r.ok ? "ok" : "bad" }, r.ok ? "converted" : r.crashed ? `crashed: ${r.crashed}` : `refused: ${[...new Set(r.refusalKinds)].join("; ")}`),
        el("td", {}, r.ok ? String(r.todos.length) : "-"),
      el("td", {}, openButton(r.file)));
    }));
    $("pkg-overview").textContent = pkg.summary;
    $("det-tab-pkg").hidden = false;
    result.hidden = false;
    zipButton.disabled = converted === 0;
    clear.hidden = false;
    text.textContent = `${name} - drop another to replace it`;
  };

  /** a report of the package into the editor, with its text pool */
  const openButton = (file) => {
    const b = el("button", { class: "link", type: "button", title: "Convert this report on its own, show its class and run it" }, "Open");
    const path = Object.keys(sources).find((x) => x.split("/").pop() === file);
    const xml = Object.keys(sources).find((x) => x.split("/").pop().toLowerCase() === file.replace(/\.abap$/i, ".xml").toLowerCase());
    b.onclick = () => path && own.open({ source: sources[path], xml: xml && sources[xml] });
    return b;
  };

  const convertFiles = async (files, name) => {
    sources = files;
    text.textContent = "Converting...";
    // the conversion on the next frame, so the text shows first
    await new Promise((r) => setTimeout(r, 0));
    show(convertPackage(files), name);
    result.scrollIntoView({ behavior: "smooth", block: "nearest" });
  };

  const take = async (list) => {
    const files = {};
    let name = "";
    for (const f of list) {
      if (/\.zip$/i.test(f.name)) {
        name = name || f.name.replace(/\.zip$/i, "");
        try {
          Object.assign(files, await unzipTexts(await f.arrayBuffer()));
        } catch (e) {
          text.textContent = `${f.name}: ${e.message}`;
          return;
        }
      } else if (/\.(abap|xml)$/i.test(f.name)) files[f.name] = (await f.text()).replace(/^\uFEFF/, "");
    }
    await convertFiles(files, name || "package");
  };

  input.onchange = () => input.files.length && take([...input.files]);
  drop.ondragover = (e) => {
    e.preventDefault();
    drop.classList.add("over");
  };
  drop.ondragleave = () => drop.classList.remove("over");
  drop.ondrop = (e) => {
    e.preventDefault();
    drop.classList.remove("over");
    if (e.dataTransfer?.files?.length) take([...e.dataTransfer.files]);
  };
  zipButton.onclick = () => out && download("report2ui5.zip", abapgitZip(out.output, "report2ui5"), "application/zip");
  clear.onclick = () => {
    out = undefined;
    sources = {};
    result.hidden = true;
    $("det-tab-pkg").hidden = true;
    selectTab("det-steps", true);
    zipButton.disabled = true;
    clear.hidden = true;
    input.value = "";
    text.textContent = "Drop the zip or the files here, or click to choose";
  };
  return { convertFiles };
}

// ---------------------------------------------------------------- GitHub

/** Import from GitHub: a link to a .prog.abap opens it in the editor (with
 *  the .prog.xml beside it); a link to a repository or a folder converts its
 *  reports as a package. ?github=<link> in the page's URL imports at once. */
function githubSection(own, pkg, signal) {
  const input = $("gh-url");
  const button = $("gh-import");
  const status = $("gh-status");
  const say = (state, text) => {
    status.className = `status ${state}`;
    status.textContent = text;
  };

  const importFrom = async (link) => {
    const at = parseGithub(link);
    if (!at) {
      say("bad", "That is no GitHub link - a repository, a folder (…/tree/…) or a file (…/blob/….prog.abap).");
      return;
    }
    button.disabled = true;
    try {
      if (at.file) {
        if (!/\.abap$/i.test(at.path)) throw new Error("A file to import is a .prog.abap - link a folder to convert all reports in it.");
        say("", `Reading ${at.path}...`);
        const source = await getText(rawUrl(at, at.path));
        if (source === undefined) throw new Error("Not found on GitHub - is the repository public, and the branch and path right?");
        const xml = /\.prog\.abap$/i.test(at.path) ? await getText(rawUrl(at, at.path.replace(/\.abap$/i, ".xml"))) : undefined;
        if (signal.aborted) return;
        own.open({ source, xml });
        say("ok", `Imported ${at.path.split("/").pop()}${xml ? " with its text pool" : ""} from ${at.owner}/${at.repo}.`);
      } else {
        say("", `Reading ${at.owner}/${at.repo}${at.path ? `/${at.path}` : ""}...`);
        const { files, ref, truncated } = await folderFiles(at, (n, all) => say("", `Reading the files: ${n} of ${all}...`));
        if (signal.aborted) return;
        const reports = Object.keys(files).filter((f) => /\.prog\.abap$/i.test(f)).length;
        if (!reports) throw new Error("No .prog.abap there - the reports of an abapGit repository are files like zreport.prog.abap.");
        await pkg.convertFiles(files, `${at.owner}/${at.repo}${at.path ? `/${at.path}` : ""}@${ref}`);
        say("ok", `Imported ${Object.keys(files).length} files from ${at.owner}/${at.repo}@${ref}${truncated ? " - the repository is too big for one read, some files may be missing" : ""}. Open a report of the table below to edit it.`);
      }
    } catch (e) {
      say("bad", e?.message ?? String(e));
    } finally {
      button.disabled = false;
    }
  };

  button.onclick = () => importFrom(input.value);
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") importFrom(input.value);
  }, { signal });
  for (const a of document.querySelectorAll("[data-gh]")) {
    a.addEventListener("click", (e) => {
      e.preventDefault();
      input.value = a.dataset.gh;
      importFrom(input.value);
    }, { signal });
  }
  const linked = new URLSearchParams(location.search).get("github");
  if (linked) {
    selectTab("src-gh");
    input.value = linked;
    importFrom(linked);
  }
}
