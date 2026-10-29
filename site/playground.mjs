// The report2cloud part of the site, in two sections:
//
// - Samples: a report of the converter's own corpus (examples.json, written
//   by scripts/build-site.mjs with its text pool), the class the converter
//   writes of it and that class running as an abap2UI5 app - side by side,
//   started when the sample is picked.
// - Your own report: a report pasted or typed, converted as it is typed and
//   kept in this browser (localStorage) for the next visit; Preview starts
//   its class as an app beside it. Below, what happened and what the
//   converter found.
//
// The converter is tools/report2cloud, bundled for the browser. An app runs in
// the abap2UI5 playground of this site (playground/, built with report2cloud
// by scripts/build-playground.mjs) in its app-only view (?view=full) - no
// editor, no bar, only the app. It is handed the report, with its .prog.xml,
// in the fragment of its URL, as the playground's own share links carry files
// (src/shell/share.mjs there: "2", then the JSON of the files deflated and
// base64url), converts it the same way and starts it. Nothing goes to a
// server. The frame is of this site, so the page reads its status line to say
// how far the start got.
import { convert, defaultClassName } from "../tools/report2cloud/lib/convert.mjs";
import { migrationReport } from "../tools/report2cloud/lib/report.mjs";
import { parseTextpool } from "../tools/report2cloud/lib/textpool.mjs";
import { highlightAbap, highlightFile } from "./highlight.mjs";
import { MODEL, errorText, lineDiff, polishClass, rewriteRefused } from "./assistant.mjs";

const $ = (id) => document.getElementById(id);
const STORE = "report2cloud.own";
const KEY_STORE = "report2cloud.ai-key";

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
    for (const [id, empty] of [["refused", "Nothing."], ["todo", "Nothing."], ["release", "Nothing to check."], ["mapped", "Nothing yet."]]) {
      if ($(prefix + id)) panel(prefix + id, [], empty);
    }
    return;
  }
  if ($(`${prefix}refused`)) panel(`${prefix}refused`, result.refusals, "Nothing.", (items) => listOf(items, (r) => el("li", { class: "bad" }, rowOf(r), r.message)));
  panel(`${prefix}todo`, result.todos, "Nothing.", (items) => listOf(items, (t) => el("li", { class: "warn" }, rowOf(t), t.message)));
  panel(`${prefix}release`, result.release, "Nothing to check.", (items) => listOf(items, (r) => el("li", {}, rowOf(r), `${r.kind} ${r.name}${r.successor ? ` - ${r.successor}` : ""}`)));
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

// the files for the playground: the report - the first file, the app - and
// its text pool. abapGit's name of it, lower case; a namespace (/abc/rep)
// has no file name the playground takes, so such a report goes as zreport
function reportFiles(text, xml) {
  const program = nameOf(text);
  const name = /^[a-z][a-z0-9_]*$/.test(program) ? program : "zreport";
  const list = [{ name: `${name}.prog.abap`, source: text }];
  if (xml) list.push({ name: `${name}.prog.xml`, source: xml });
  return list;
}

/** files in the fragment of the playground's URL, as its share links carry them */
async function fragmentOf(list) {
  const bytes = new TextEncoder().encode(JSON.stringify(list));
  const deflated = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new CompressionStream("deflate-raw"))).arrayBuffer());
  let binary = "";
  for (let i = 0; i < deflated.length; i += 0x8000) binary += String.fromCharCode(...deflated.subarray(i, i + 0x8000));
  return `2${btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "")}`;
}

/** an app in a frame: start( files, className ) - the report and its text
 *  pool, or a class of the report runtime first - and the start followed,
 *  onStep( { state, text } ) as it goes. Answers how it ended: { ok, said,
 *  problems } - problems what stopped the Run in the playground, by file and
 *  line (its __pgProblems). */
function appFrame(frame, cover, onStep) {
  let runs = 0;
  return async (files, className) => {
    const run = ++runs;
    onStep({ state: "wait", text: "Starting it: the abap2UI5 runtime, the report runtime of abap-cloud-gui and the class are loaded in this browser..." });
    cover.hidden = false;
    cover.textContent = "Starting...";
    frame.src = new URL(`playground/?view=full&run=${run}#${await fragmentOf(files)}`, document.baseURI).href;
    const started = Date.now();
    const read = (pick) => {
      try {
        return pick(frame.contentDocument)?.textContent?.trim() ?? "";
      } catch {
        return "";
      }
    };
    const problems = () => {
      try {
        return frame.contentWindow?.__pgProblems ?? [];
      } catch {
        return [];
      }
    };
    return new Promise((resolve) => {
      const poll = () => {
        if (run !== runs) return resolve({ ok: false, said: "started again", problems: [] });
        const said = read((d) => d?.getElementById("status"));
        if (/^running/.test(said)) {
          cover.hidden = true;
          onStep({ state: "ok", text: `Started the class ${className} as an abap2UI5 app, in ${((Date.now() - started) / 1000).toFixed(1)} s. Use it like the report: the selection screen, Execute (F8), the list.` });
          return resolve({ ok: true, said, problems: [] });
        }
        if (/could not|cannot|error/i.test(said)) {
          const log = read((d) => d?.querySelector(".log-body"));
          cover.textContent = `It did not start: ${said}`;
          onStep({ state: "bad", text: `It did not start: ${said}${log ? ` - ${log.slice(0, 300)}` : ""}` });
          return resolve({ ok: false, said: log ? `${said} - ${log}` : said, problems: problems() });
        }
        if (Date.now() - started > 120000) {
          onStep({ state: "bad", text: "It did not start within two minutes - is the network down?" });
          return resolve({ ok: false, said: "no start within two minutes", problems: [] });
        }
        if (said) {
          cover.textContent = said;
          onStep({ state: "wait", text: `Starting it: ${said}` });
        }
        setTimeout(poll, 400);
      };
      setTimeout(poll, 400);
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

// the files as abapGit wants them beside each other - one download each
const download = (name, text) => {
  const a = el("a", { href: URL.createObjectURL(new Blob([text], { type: "text/plain" })), download: name });
  document.body.append(a);
  a.click();
  setTimeout(() => {
    URL.revokeObjectURL(a.href);
    a.remove();
  }, 0);
};

// for the code on the page that is no sample: the example class of "How"
for (const code of document.querySelectorAll("code.abap")) code.innerHTML = highlightAbap(code.textContent);

let examples = [];
try {
  // the Maps of a text pool come as { "$map": entries } (scripts/build-site.mjs)
  const reviver = (k, v) => (v && typeof v === "object" && Array.isArray(v.$map) ? new Map(v.$map) : v);
  examples = JSON.parse(await (await fetch("examples.json")).text(), reviver);
} catch {
  examples = [];
}

// ---------------------------------------------------------------- samples

{
  const select = $("s-example");
  const steps = {};
  const stepList = $("s-steps");
  let sample;
  let shown = () => undefined;
  let files = {};
  const start = appFrame($("s-app"), $("s-cover"), (s) => {
    steps.run = s;
    renderSteps(stepList, steps);
  });

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
    if (c.result.ok) start(reportFiles(e.source, e.xml), c.result.className);
    else {
      $("s-app").src = "about:blank";
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
  // the sample as your own report, to change it
  $("s-try").onclick = () => sample && window.dispatchEvent(new CustomEvent("r2c-own", { detail: sample }));
  if (examples.length) {
    select.value = examples[0].name;
    // started once the section comes into view - not for a visitor who never scrolls there
    new IntersectionObserver((entries, observer) => {
      if (!entries.some((x) => x.isIntersecting)) return;
      observer.disconnect();
      pick();
    }, { rootMargin: "200px" }).observe($("samples"));
  } else {
    $("samples").hidden = true;
  }
}

// ---------------------------------------------------------- your own report

{
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

  const start = appFrame($("app"), $("app-cover"), (s) => {
    steps.run = s;
    renderSteps(stepList, steps);
  });

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
    polished = undefined;
    shown = fileTabs($("tabs"), output, files, c.result.className);
    const { result } = c;
    status.className = result.ok ? "status ok" : "status bad";
    status.textContent = result.ok
      ? `Converted into ${result.className} - ${result.mapped.length} statement(s) mapped, ${result.todos.length} TODO(s), ${result.release.length} object(s) to check for ABAP Cloud.`
      : `Refused: ${result.refusals.length} statement(s) have no counterpart - the draft shows how far it got; nothing can run until they are rewritten.`;
    Object.assign(steps, stepsOf(c.name, text, textpool, result));
    renderSteps(stepList, steps);
    panels("", result);
    $("migration").textContent = c.report;
    markStale();
    aiReady();
  };

  /** the app in the frame was started with another source - Preview starts this one */
  function markStale() {
    if (running === undefined) return;
    appState.textContent = last && running === last.text ? "" : "the report changed - Preview starts it again";
  }

  const preview = (on) => {
    $("preview").hidden = !on;
    $("own-panes").classList.toggle("with-preview", on);
    runButton.setAttribute("aria-pressed", String(on));
  };

  const runApp = () => {
    if (!source.value.trim()) {
      status.className = "status bad";
      status.textContent = "Paste a report first - or take a sample above (Edit it below).";
      return;
    }
    if (!last || last.text !== source.value) run();
    preview(true);
    if (!last.result.ok) {
      steps.run = { state: "bad", text: "Not started: the converter refused statements of the report - rewrite them first." };
      renderSteps(stepList, steps);
      $("app-cover").hidden = false;
      $("app-cover").textContent = "The report has statements the converter refuses - see Refused below.";
      return;
    }
    running = last.text;
    appState.textContent = "";
    start(reportFiles(last.text, textpoolOf().xml), last.result.className);
  };

  // kept in this browser - an empty or blocked storage is no error
  const save = () => {
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
  $("download-all").onclick = () => Object.keys(files).forEach((f, i) => setTimeout(() => download(f, files[f]), i * 250));

  // a sample to edit: it becomes your own report
  window.addEventListener("r2c-own", (e) => {
    source.value = e.detail.source;
    textpoolXml.value = e.detail.xml ?? "";
    classname.value = "";
    save();
    run();
    $("playground").scrollIntoView({ behavior: "smooth" });
    source.focus({ preventScroll: true });
  });

  // ---- the AI assistant: the refused statements rewritten (the converter the
  // judge), then the class polished (the start the judge)
  const aiKey = $("ai-key");
  const aiRun = $("ai-run");
  const aiPolish = $("ai-polish");
  const aiSteps = $("ai-steps");
  let aiAnswer;
  let aiAbort;
  // the polished files, while they are what the class pane shows
  let polished;
  const aiLog = [];
  const aiStep = (s) => {
    if (aiLog.at(-1)?.state === "wait") aiLog.pop();
    aiLog.push(s);
    aiSteps.replaceChildren(...aiLog.map((x) => el("li", { class: x.state }, x.text)));
  };
  function aiReady() {
    const key = Boolean(aiKey.value.trim());
    const busy = Boolean(aiAbort);
    const refused = last && !last.result.ok;
    const converted = last && last.result.ok;
    aiRun.disabled = !refused || !key || busy;
    aiRun.title = !refused ? "Nothing is refused - nothing for the assistant to do" : !key ? "Your Anthropic API key first" : "";
    aiPolish.disabled = !converted || !key || busy;
    aiPolish.title = !converted ? "The report converts first - rewrite what is refused" : !key ? "Your Anthropic API key first" : "";
  }
  try {
    aiKey.value = localStorage.getItem(KEY_STORE) ?? "";
    $("ai-remember").checked = Boolean(aiKey.value);
  } catch {
    /* no storage in this context */
  }
  const keepKey = () => {
    try {
      if ($("ai-remember").checked && aiKey.value.trim()) localStorage.setItem(KEY_STORE, aiKey.value.trim());
      else localStorage.removeItem(KEY_STORE);
    } catch {
      /* no storage in this context */
    }
  };
  aiKey.addEventListener("input", () => {
    keepKey();
    aiReady();
  });
  $("ai-remember").addEventListener("change", keepKey);

  /** the changed lines with three lines around them, as HTML */
  const diffHtml = (before, after) => {
    const rows = lineDiff(before, after);
    const near = rows.map((r, i) => rows.slice(Math.max(0, i - 3), i + 4).some((x) => x.kind !== " "));
    const out = [];
    let gap = false;
    rows.forEach((r, i) => {
      if (!near[i]) {
        if (!gap) out.push(`<span class="gap">...</span>`);
        gap = true;
        return;
      }
      gap = false;
      const code = highlightAbap(r.text) || " ";
      out.push(`<span class="${r.kind === "+" ? "add" : r.kind === "-" ? "del" : "ctx"}">${r.kind === " " ? " " : r.kind} ${code}</span>`);
    });
    // a line each - the spans are blocks
    return out.join("");
  };
  const escape = (t) => t.replace(/&/g, "&amp;").replace(/</g, "&lt;");

  // the assistant at work: one at a time, Stop for it
  const working = async (job) => {
    aiLog.length = 0;
    $("ai-result").hidden = true;
    aiAbort = new AbortController();
    aiReady();
    $("ai-stop").hidden = false;
    try {
      await job(aiAbort.signal);
    } catch (e) {
      aiStep({ state: "bad", text: `The assistant stopped: ${errorText(e)}.` });
    } finally {
      aiAbort = undefined;
      $("ai-stop").hidden = true;
      aiReady();
    }
  };
  const okSamples = () => examples.filter((e) => e.source !== last?.text).map((e) => ({ e, c: convertReport(e.source, { textpool: e.textpool }) })).filter((x) => x.c.result.ok);

  aiRun.onclick = () => working(async (signal) => {
    if (!last || last.result.ok) return;
    const report = last.text;
    const { textpool } = textpoolOf();
    const answer = await rewriteRefused({
      apiKey: aiKey.value.trim(),
      report,
      result: last.result,
      samples: okSamples().map((x) => x.e),
      convert: (text) => convertReport(text, { textpool, className: classname.value.trim() || undefined }).result,
      onStep: aiStep,
      signal,
    });
    aiAnswer = { kind: "report", ...answer };
    $("ai-notes").textContent = answer.notes;
    $("ai-diff").innerHTML = diffHtml(report, answer.source);
    $("ai-result").hidden = false;
    $("ai-take").textContent = answer.result.ok ? "Take it" : "Take it anyway";
    if (!answer.result.ok) aiStep({ state: "bad", text: `After ${answer.rounds} rounds, ${answer.result.refusals.length} statement(s) are still refused - take what it did and rewrite those by hand, or discard it.` });
  });

  // the ABAP files of the class, the class first - what the playground runs
  const classFiles = (all, className) => Object.fromEntries(Object.entries(all)
    .filter(([n]) => n.endsWith(".abap"))
    .sort(([a], [b]) => (a === `${className}.clas.abap` ? -1 : b === `${className}.clas.abap` ? 1 : a.localeCompare(b))));

  aiPolish.onclick = () => working(async (signal) => {
    if (!last || !last.result.ok) return;
    const { className } = last.result;
    const before = classFiles(files, className);
    // the classes of the two samples closest to the report: the runtime's API in use
    const words = new Set(last.text.toLowerCase().match(/[a-z_][\w-]{2,}/g) ?? []);
    const references = okSamples()
      .map((x) => ({ x, score: (x.e.source.toLowerCase().match(/[a-z_][\w-]{2,}/g) ?? []).filter((w) => words.has(w)).length }))
      .sort((a, b) => b.score - a.score).slice(0, 2)
      .map(({ x }) => ({ name: `${x.c.result.className}.clas.abap`, source: x.c.files[`${x.c.result.className}.clas.abap`] }));
    const answer = await polishClass({
      apiKey: aiKey.value.trim(),
      report: last.text,
      files: before,
      todos: last.result.todos,
      references,
      // the preview the judge: the polished files started there
      check: (next) => {
        preview(true);
        running = undefined;
        return start(Object.entries(next).map(([name, source]) => ({ name, source })), className);
      },
      onStep: aiStep,
      signal,
    });
    aiAnswer = { kind: "class", before, ...answer };
    const changed = Object.keys(answer.files).filter((n) => answer.files[n] !== before[n]);
    $("ai-notes").textContent = answer.notes;
    $("ai-diff").innerHTML = changed.map((n) => `<span class="gap">${escape(n)}</span>${diffHtml(before[n], answer.files[n])}`).join("");
    $("ai-result").hidden = false;
    $("ai-take").textContent = answer.ok ? "Take it" : "Take it anyway";
    if (!answer.ok) aiStep({ state: "bad", text: `After ${answer.rounds} rounds the polished class still does not start - take it to fix it by hand, or discard it.` });
  });

  $("ai-stop").onclick = () => aiAbort?.abort();
  $("ai-take").onclick = () => {
    if (!aiAnswer) return;
    if (aiAnswer.kind === "report") {
      source.value = aiAnswer.source;
      save();
      run();
      aiStep({ state: "ok", text: "Taken into your report - converted again above." });
    } else {
      // the class pane shows the polished files - until the report is converted again
      polished = { text: last.text, files: aiAnswer.files };
      Object.assign(files, aiAnswer.files);
      shown = fileTabs($("tabs"), output, files, last.result.className);
      status.className = "status ok";
      status.textContent = `Polished by the AI assistant - ${last.result.className} as it started in the preview. A change to the report converts it again and replaces it.`;
      aiStep({ state: "ok", text: "Taken into the class - Copy, Download and All files give the polished files." });
    }
    $("ai-result").hidden = true;
    aiAnswer = undefined;
  };
  $("ai-drop").onclick = () => {
    $("ai-result").hidden = true;
    aiAnswer = undefined;
    // the preview showed the polished class: the converted one again
    if (!polished && last?.result.ok && $("preview").hidden === false) runApp();
  };
  $("ai").querySelector("h3 .muted").textContent = `- ${MODEL}`;

  const kept = load();
  source.value = kept?.source ?? "";
  textpoolXml.value = kept?.textpool ?? "";
  classname.value = kept?.classname ?? "";
  run();
}
