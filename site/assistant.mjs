// The AI assistant of the site - for the statements report2cloud refuses.
//
// The converter stays the judge. The assistant rewrites the classic report -
// only the refused statements and what they need - so that the converter
// accepts it; every answer goes through the converter again, and what is
// still refused goes back to the model, for at most ROUNDS rounds. What the
// user gets is a report the converter took, and the diff to theirs - or, after
// the last round, what is still refused.
//
// What the model is given: the report, its refusals with the line and the
// statement, for each the entry of the refusal catalogue (why it has no
// counterpart, and the rewrite in the classic report that unblocks it -
// tools/report2cloud/lib/refusals.mjs), and samples of the converter's corpus
// closest to the report, as reports it accepts. No training: the samples and
// the catalogue are the context.
//
// The second stage polishes the class the converter wrote: names, structure,
// the TODOs the converter left where the report's intent is clear - what a
// person writing abap-cloud-gui by hand would do. Here the judge is the
// start: each answer runs in the preview, the syntax check of the playground
// against the report runtime and abap2UI5 first, and what stops it goes back
// to the model, for at most ROUNDS rounds.
//
// The key is the user's own: it stays in this browser (kept only when they
// ask) and goes to api.anthropic.com with the request, nowhere else.
import Anthropic from "@anthropic-ai/sdk";
import { refusalOf } from "../tools/report2cloud/lib/refusals.mjs";

export const MODEL = "claude-opus-5-5";
const ROUNDS = 3;
const SAMPLES = 3;

const SYSTEM = `You help move classic ABAP reports to ABAP Cloud. A deterministic converter, report2cloud, turns a classic report (REPORT, PARAMETERS, SELECT-OPTIONS, event blocks, FORMs, WRITE lists, ALV, popups, local classes) into a class of abap-cloud-gui, which runs it as an abap2UI5 app. It refuses each statement it has no counterpart for, with the line and a reason.

Your job: rewrite the report so that the converter accepts it.
- Change only the refused statements and what they need. Every other line stays exactly as it is - its text, its order, its comments.
- The result is still a classic report: REPORT, the event blocks, FORMs. Do not write the class; the converter writes it.
- Use the constructs the converter accepts. The rewrite each refusal comes with says which; the sample reports show them in use.
- Keep what the report does. Where a statement has no counterpart in a browser app at all (a background job, the SAP GUI frontend, a system call), take the nearest one that keeps the report useful, and say so in a comment on the line before it, starting with "AI:".
- Do not invent DDIC objects, function modules or classes the report does not already name.

Answer in two parts and nothing else: first a short list, one line per refused statement, of what you changed; then the whole rewritten report in one \`\`\`abap code block.`;

/** the samples closest to the report: the most words in common */
function closest(report, samples) {
  const words = (text) => new Set(text.toLowerCase().match(/[a-z_][\w-]{2,}/g) ?? []);
  const mine = words(report);
  return samples
    .map((s) => {
      const theirs = words(s.source);
      let common = 0;
      for (const w of theirs) if (mine.has(w)) common++;
      return { s, score: common / Math.sqrt(theirs.size || 1) };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, SAMPLES)
    .map((x) => x.s);
}

/** the refusals as the model reads them: line, statement, message, and the
 *  catalogue's why and rewrite - each entry once */
function refusalsText(report, refusals) {
  const lines = report.split("\n");
  const entries = new Map();
  const list = refusals.map((r) => {
    const entry = refusalOf(r.message);
    if (entry) entries.set(entry.id, entry);
    return `- line ${r.row}: \`${(lines[r.row - 1] ?? "").trim()}\` - ${r.message}${entry ? ` [${entry.id}]` : ""}`;
  });
  const guide = [...entries.values()].map((e) => `### [${e.id}] ${e.title}\n\nWhy: ${e.why}\n\nRewrite:\n${e.rewrite}`);
  return `${list.join("\n")}\n\n## What the converter says about them\n\n${guide.join("\n\n")}`;
}

/** the rewritten report and the list before it, from the model's answer */
function answerOf(text) {
  const blocks = [...text.matchAll(/```abap\s*\n([\s\S]*?)```/gi)];
  if (!blocks.length) return undefined;
  const last = blocks.at(-1);
  return { source: last[1].replace(/\s+$/, "\n"), notes: text.slice(0, last.index).trim() };
}

/** the tokens of the answers so far, summed - what the evaluation
 *  (tools/report2cloud/eval.mjs) prices */
function addUsage(sum, usage = {}) {
  for (const k of ["input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"]) sum[k] = (sum[k] ?? 0) + (usage[k] ?? 0);
  return sum;
}

const textOf = (message) => message.content.filter((b) => b.type === "text").map((b) => b.text).join("\n");

/**
 * Rewrites the refused statements of a report.
 *   convert(source) - the converter: { ok, refusals }
 *   onStep({ state, text }) - the progress
 *   client, model - another client than the one of apiKey, another model
 *   (the evaluation's)
 * Answers { source, notes, result, rounds, usage } - result the conversion of
 * the last answer (result.ok: the converter took it), usage the tokens of
 * all rounds.
 */
export async function rewriteRefused({ apiKey, client: given, model = MODEL, report, result, samples, convert, onStep = () => {}, signal }) {
  const client = given ?? new Anthropic({ apiKey, dangerouslyAllowBrowser: true, maxRetries: 1 });
  const usage = {};
  const examples = closest(report, samples)
    .map((s) => `### ${s.name} - ${s.title}\n\n\`\`\`abap\n${s.source.trim()}\n\`\`\``).join("\n\n");
  const messages = [{
    role: "user",
    content: [
      // the samples first: the same for every report alike, the start of the prompt the cache keeps
      { type: "text", text: `## Reports the converter accepts\n\n${examples}` },
      { type: "text", text: `## The report\n\n\`\`\`abap\n${report.trim()}\n\`\`\`\n\n## What the converter refuses\n\n${refusalsText(report, result.refusals)}` },
    ],
  }];

  let answer;
  let converted = result;
  for (let round = 1; round <= ROUNDS; round++) {
    onStep({ state: "wait", text: round === 1
      ? `Asked ${model} to rewrite ${result.refusals.length} refused statement(s)...`
      : `Round ${round}: asked it again, with the ${converted.refusals.length} statement(s) still refused...` });
    const stream = client.beta.messages.stream({
      model,
      max_tokens: 64000,
      // a decline for policy reasons is retried on the model the API picks
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: { effort: "high" },
      cache_control: { type: "ephemeral" },
      system: SYSTEM,
      messages,
    }, { signal });
    const message = await stream.finalMessage();
    addUsage(usage, message.usage);
    if (message.stop_reason === "refusal") throw new Error("the model declined the request");
    if (message.stop_reason === "max_tokens") throw new Error("the answer was cut off - the report is too long for one answer");
    const text = textOf(message);
    const next = answerOf(text);
    if (!next) throw new Error("the answer has no ```abap block with the report");
    answer = next;
    converted = convert(answer.source);
    if (converted.ok) {
      onStep({ state: "ok", text: `Round ${round}: the converter takes the rewritten report.` });
      return { ...answer, result: converted, rounds: round, usage };
    }
    onStep({ state: "bad", text: `Round ${round}: the converter still refuses ${converted.refusals.length} statement(s).` });
    messages.push({ role: "assistant", content: message.content });
    messages.push({ role: "user", content: `The converter still refuses these statements of your report:\n\n${refusalsText(answer.source, converted.refusals)}\n\nRewrite them the same way, and answer with the list and the whole report again.` });
  }
  return { ...answer, result: converted, rounds: ROUNDS, usage };
}

const POLISH = `You polish ABAP classes that a deterministic converter, report2cloud, wrote from classic reports. The class inherits from z2ui5_cl_cgui_report of abap-cloud-gui, which runs it as an abap2UI5 app: the event blocks of the report are methods of the same name, PARAMETERS and SELECT-OPTIONS are attributes, write( ) writes the list, alv( ) shows a grid.

The converter is exact but mechanical. Make the class read like one a person wrote by hand for abap-cloud-gui:
- clear names for methods and variables where the converted ones are cryptic;
- the structure the logic asks for - a long method split, a repeated block once;
- the TODOs the converter left, where the report makes clear what was meant; the others stay, as they are;
- comments only where they say something the code does not.

Keep, exactly:
- what the class does - the selection screen, the list, the grid, the messages, in the same order;
- the class name, INHERITING FROM z2ui5_cl_cgui_report, the redefined event methods and their names;
- the public attributes of the selection screen and their names - a variant stored for the report reads them;
- the names of the files.
Use only what the class already uses of the runtime and of abap2UI5 - the reference classes show more of it. ABAP 7.50: no constructs of a later release.

Answer with a short list of what you changed, then each file you changed: a line "### <file name>", then the whole file in one \`\`\`abap code block. Leave out the files you did not change.`;

/** the files of an answer: "### name" then a code block */
function filesOf(text, names) {
  const out = {};
  for (const m of text.matchAll(/^###\s+`?([\w#/.-]+?)`?\s*\n+```abap\s*\n([\s\S]*?)```/gm)) {
    if (names.includes(m[1])) out[m[1]] = m[2].replace(/\s+$/, "\n");
  }
  const first = text.search(/^###\s/m);
  return { files: out, notes: (first < 0 ? text : text.slice(0, first)).trim() };
}

const problemsText = (outcome) => (outcome.problems.length
  ? outcome.problems.map((p) => `- ${p.file}:${p.line} - ${p.message}`).join("\n")
  : `- ${outcome.said}`);

/**
 * Polishes the class the converter wrote.
 *   files - the converted ABAP files, { name: source }, the class first
 *   check(files) - starts them: { ok, said, problems }
 * Answers { files, notes, ok, rounds } - files all of them, the changed ones
 * the model's; ok when the last answer started.
 */
export async function polishClass({ apiKey, report, files, todos, references, check, onStep, signal }) {
  const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true, maxRetries: 1 });
  const names = Object.keys(files);
  const block = (name, source) => `### ${name}\n\n\`\`\`abap\n${source.trim()}\n\`\`\``;
  const messages = [{
    role: "user",
    content: [
      { type: "text", text: `## Reference classes - written by the converter from other reports\n\n${references.map((r) => block(r.name, r.source)).join("\n\n")}` },
      { type: "text", text: `## The classic report\n\n\`\`\`abap\n${report.trim()}\n\`\`\`\n\n## The class the converter wrote of it\n\n${names.map((n) => block(n, files[n])).join("\n\n")}\n\n## The TODOs the converter left\n\n${todos.length ? todos.map((t) => `- line ${t.row} of the report: ${t.message}`).join("\n") : "None."}` },
    ],
  }];
  let current = { ...files };
  let notes = "";
  for (let round = 1; round <= ROUNDS; round++) {
    onStep({ state: "wait", text: round === 1 ? `Asked ${MODEL} to polish the class...` : `Round ${round}: asked it again, with what stopped the start...` });
    const stream = client.beta.messages.stream({
      model: MODEL,
      max_tokens: 64000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: { effort: "high" },
      cache_control: { type: "ephemeral" },
      system: POLISH,
      messages,
    }, { signal });
    const message = await stream.finalMessage();
    if (message.stop_reason === "refusal") throw new Error("the model declined the request");
    if (message.stop_reason === "max_tokens") throw new Error("the answer was cut off - the class is too long for one answer");
    const answer = filesOf(textOf(message), names);
    if (!Object.keys(answer.files).length) throw new Error("the answer has no file of the class in it");
    current = { ...current, ...answer.files };
    notes = answer.notes;
    onStep({ state: "wait", text: `Round ${round}: starting the polished class in the preview...` });
    const outcome = await check(current);
    if (outcome.ok) {
      onStep({ state: "ok", text: `Round ${round}: the polished class starts.` });
      return { files: current, notes, ok: true, rounds: round };
    }
    onStep({ state: "bad", text: `Round ${round}: it does not start - ${outcome.problems.length ? `${outcome.problems.length} error(s) in the ABAP` : outcome.said}.` });
    messages.push({ role: "assistant", content: message.content });
    messages.push({ role: "user", content: `The polished class does not start:\n\n${problemsText(outcome)}\n\nFix that, and answer with the list and the files you changed again - whole files.` });
  }
  return { files: current, notes, ok: false, rounds: ROUNDS };
}

/** a message for an error of the API - what the user can do about it */
export function errorText(e) {
  if (e instanceof Anthropic.AuthenticationError) return "the API key was refused - check it";
  if (e instanceof Anthropic.PermissionDeniedError) return "the API key may not use this model";
  if (e instanceof Anthropic.RateLimitError) return "rate limited - try again in a minute";
  if (e instanceof Anthropic.APIUserAbortError) return "stopped";
  if (e instanceof Anthropic.APIConnectionError) return "no connection to api.anthropic.com";
  if (e instanceof Anthropic.APIError) return `the API answered ${e.status}: ${e.message}`;
  return e?.message ?? String(e);
}

/** a line diff of two texts: [{ kind: " " | "-" | "+", text }] */
export function lineDiff(before, after) {
  const a = before.replace(/\s+$/, "").split("\n");
  const b = after.replace(/\s+$/, "").split("\n");
  // the longest common subsequence, from the end
  const n = a.length;
  const m = b.length;
  const len = Array.from({ length: n + 1 }, () => new Uint32Array(m + 1));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) len[i][j] = a[i] === b[j] ? len[i + 1][j + 1] + 1 : Math.max(len[i + 1][j], len[i][j + 1]);
  }
  const out = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (a[i] === b[j]) {
      out.push({ kind: " ", text: a[i++] });
      j++;
    } else if (len[i + 1][j] >= len[i][j + 1]) out.push({ kind: "-", text: a[i++] });
    else out.push({ kind: "+", text: b[j++] });
  }
  while (i < n) out.push({ kind: "-", text: a[i++] });
  while (j < m) out.push({ kind: "+", text: b[j++] });
  return out;
}
