#!/usr/bin/env node
// report2cloud eval - the AI loop of the site measured on a corpus.
//
//   node tools/report2cloud/eval.mjs [--cache dir | --corpus test] [--limit n]
//        [--model id] [--parallel n] [--json file] [--summary file] [--dry]
//
// The assistant of the site (site/assistant.mjs, rewriteRefused) rewrites
// the statements the converter refuses, and the converter judges every
// answer, for at most three rounds. Here the same loop runs over the reports
// of a corpus that the converter refuses - the web corpus of web.mjs in its
// cache (default build/web-corpus, filled by npm run report2cloud:web), or
// the converter's own test corpus with --corpus test - and the numbers say
// how far it gets:
//
// - accepted: the converter takes the last answer;
// - clean: accepted, and the report is still the report - at least KEEP of
//   the lines that were not refused are unchanged in the answer. A loop that
//   deletes what it cannot convert, or writes another report, is accepted
//   but not clean;
// - per kind of refusal (the entry of the refusal catalogue): in how many
//   reports it was, and in how many of them the loop removed it;
// - the rounds, the errors, and the tokens of the model.
//
// --limit n takes n of the refused reports, spread evenly over the corpus
// (the same ones for the same corpus, so two runs compare). The key is
// ANTHROPIC_API_KEY; --dry needs none - a model that answers the report
// unchanged, which measures nothing but runs everything else (the floor:
// 0 accepted). Prints the summary, --summary appends it as Markdown (the job
// summary of the workflow), --json writes a line per report.
import { appendFileSync, existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { reasonOf, reportOf } from "./coverage.mjs";
import { cachedRepositories, repositoriesIn } from "./web.mjs";
import { refusalOf } from "./lib/refusals.mjs";
import { convert } from "./lib/convert.mjs";
import { parseTextpool } from "./lib/textpool.mjs";
import { REPO } from "./lib/gate.mjs";
import { lineDiff, MODEL, rewriteRefused } from "../../site/assistant.mjs";

/** the share of the lines that were not refused which the answer keeps */
export const KEEP = 0.9;

const CORPUS = join(REPO, "tools", "report2cloud", "test", "corpus");

const USAGE = `usage: node tools/report2cloud/eval.mjs [--cache dir | --corpus test] [--limit n] [--model id] [--parallel n] [--json file] [--summary file] [--dry]`;

function args(argv) {
  const opts = { cache: join(REPO, "build", "web-corpus"), parallel: "4", model: MODEL };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") opts.help = true;
    else if (a === "--dry") opts.dry = true;
    else if (["--cache", "--corpus", "--limit", "--model", "--parallel", "--json", "--summary"].includes(a)) {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else throw new Error(`unknown option ${a}`);
  }
  if (opts.corpus !== undefined && opts.corpus !== "test") throw new Error(`--corpus knows test only`);
  return opts;
}

/** the samples of the prompt: the reports of the test corpus that convert,
 *  without includes - the ones the site shows */
export function samples() {
  return readdirSync(CORPUS).filter((f) => f.endsWith(".prog.abap")).sort().flatMap((f) => {
    const source = readFileSync(join(CORPUS, f), "utf8");
    if (/^\s*include\s/im.test(source) || !/^\s*(?:report|program)\s/im.test(source)) return [];
    const name = f.replace(/\.prog\.abap$/, "");
    const xml = join(CORPUS, `${name}.prog.xml`);
    const textpool = existsSync(xml) ? parseTextpool(readFileSync(xml, "utf8")) : undefined;
    if (!convert(source, { file: f, programName: name, textpool }).ok) return [];
    const title = /^\*&\s+(?!Report\b)(.+?)\s*$/m.exec(source)?.[1] ?? name;
    return [{ name, title, source }];
  });
}

/** the reports the converter refuses: { file, source, refusals, convert } */
export function refusedReports({ cache, corpus }) {
  const out = [];
  const take = (report, file) => {
    if (!report) return;
    let result;
    try {
      result = report.convert(report.includes.source);
    } catch {
      // a crash is the converter's bug, web.mjs counts those
      return;
    }
    if (!result.ok) out.push({ file, source: report.includes.source, result, convert: report.convert });
  };
  if (corpus === "test") {
    for (const f of readdirSync(CORPUS).filter((x) => x.endsWith(".prog.abap")).sort()) take(reportOf(join(CORPUS, f)), f);
    return out;
  }
  let n = 0;
  for (const { files, read, deps } of repositoriesIn(cache, cachedRepositories(cache))) {
    for (const file of files) take(reportOf(file, { read, deps, className: () => `z2ui5_cl_cgui_w${String(++n).padStart(4, "0")}` }), relative(cache, file));
  }
  return out;
}

/** n of the list, spread evenly over it - the same n for the same list */
export function spread(list, n) {
  if (!n || n >= list.length) return list;
  return Array.from({ length: n }, (_, i) => list[Math.floor((i * list.length) / n)]);
}

const kindOf = (r) => {
  const e = refusalOf(r.message);
  return e ? `${e.title} [${e.id}]` : reasonOf(r.message);
};

/** the share of the report's lines that were not refused and are still in
 *  the answer, unchanged */
export function kept(report, answer, refusals) {
  const refused = new Set(refusals.map((r) => r.row));
  const lines = lineDiff(report, answer);
  let row = 0;
  let total = 0;
  let same = 0;
  for (const l of lines) {
    if (l.kind === "+") continue;
    row++;
    if (refused.has(row) || !l.text.trim()) continue;
    total++;
    if (l.kind === " ") same++;
  }
  return total ? same / total : 1;
}

/** one report through the loop: the row of the result */
export async function evaluate(entry, { client, model, examples }) {
  const before = entry.result.refusals;
  const row = { file: entry.file, refused: before.length, kinds: [...new Set(before.map(kindOf))] };
  try {
    const answer = await rewriteRefused({ client, model, report: entry.source, result: entry.result, samples: examples, convert: entry.convert });
    const after = answer.result.refusals ?? [];
    row.accepted = answer.result.ok;
    row.rounds = answer.rounds;
    row.left = after.length;
    row.kept = Math.round(kept(entry.source, answer.source, before) * 1000) / 1000;
    row.clean = row.accepted && row.kept >= KEEP;
    row.removed = row.kinds.filter((k) => !after.some((r) => kindOf(r) === k));
    row.ai = (answer.source.match(/^\s*["*]\s*AI:/gm) ?? []).length;
    row.usage = answer.usage;
  } catch (e) {
    row.error = String(e?.message ?? e);
  }
  return row;
}

/** a model that answers the report unchanged - the floor, and the harness
 *  run without a key */
export function echoClient() {
  return {
    beta: {
      messages: {
        stream: (params) => ({
          finalMessage: async () => {
            const text = params.messages.at(-1).content;
            const all = typeof text === "string" ? text : text.map((b) => b.text).join("\n");
            // the report of the first message, as it was given
            const first = params.messages[0].content.map((b) => b.text).join("\n");
            const report = /## The report\n\n```abap\n([\s\S]*?)\n```/.exec(first)?.[1] ?? all;
            return { content: [{ type: "text", text: `- nothing changed\n\n\`\`\`abap\n${report}\n\`\`\`` }], stop_reason: "end_turn", usage: { input_tokens: 0, output_tokens: 0 } };
          },
        }),
      },
    },
  };
}

async function pool(items, parallel, work) {
  const out = new Array(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.max(1, parallel) }, async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await work(items[i], i);
    }
  }));
  return out;
}

export function markdown({ rows, total, model, dry }) {
  const pct = (n, of = rows.length) => (of ? `${Math.round((n / of) * 100)} %` : "-");
  const done = rows.filter((r) => !r.error);
  const accepted = done.filter((r) => r.accepted);
  const clean = done.filter((r) => r.clean);
  const sum = (k) => rows.reduce((s, r) => s + (r.usage?.[k] ?? 0), 0);
  const lines = [
    `## report2cloud AI loop on ${total} refused report(s)${dry ? " - dry run, the model answers the report unchanged" : ""}`,
    "",
    `**${clean.length} of ${rows.length} clean (${pct(clean.length)})** - ${accepted.length} accepted by the converter (${pct(accepted.length)}), ${accepted.length - clean.length} of them keep less than ${Math.round(KEEP * 100)} % of the lines that were not refused, ${rows.length - done.length} stopped with an error. Model \`${model}\`, at most three rounds each.`,
    "",
    "| rounds | reports |", "|---:|---:|",
    ...[1, 2, 3].map((n) => `| ${n} | ${accepted.filter((r) => r.rounds === n).length} |`),
    `| not accepted | ${done.length - accepted.length} |`,
    "",
    `Tokens: ${sum("input_tokens")} input, ${sum("cache_read_input_tokens")} read from the cache, ${sum("cache_creation_input_tokens")} written to it, ${sum("output_tokens")} output.`,
  ];
  const byKind = new Map();
  for (const r of done) {
    for (const k of r.kinds) {
      const x = byKind.get(k) ?? { in: 0, removed: 0 };
      x.in++;
      if (r.removed.includes(k)) x.removed++;
      byKind.set(k, x);
    }
  }
  if (byKind.size) {
    lines.push("", "| reports | removed | share | refused for |", "|---:|---:|---:|---|",
      ...[...byKind].sort((a, b) => b[1].in - a[1].in || a[0].localeCompare(b[0])).slice(0, 25)
        .map(([k, x]) => `| ${x.in} | ${x.removed} | ${pct(x.removed, x.in)} | ${k.replace(/\|/g, "\\|")} |`));
  }
  const errors = new Map();
  for (const r of rows.filter((x) => x.error)) errors.set(r.error, (errors.get(r.error) ?? 0) + 1);
  if (errors.size) {
    lines.push("", "| reports | error |", "|---:|---|", ...[...errors].sort((a, b) => b[1] - a[1]).slice(0, 10).map(([e, n]) => `| ${n} | ${e.replace(/\|/g, "\\|").slice(0, 160)} |`));
  }
  return `${lines.join("\n")}\n`;
}

async function main() {
  let opts;
  try {
    opts = args(process.argv.slice(2));
  } catch (e) {
    console.error(`${e.message}\n\n${USAGE}`);
    return 2;
  }
  if (opts.help) {
    console.log(USAGE);
    return 0;
  }
  let client;
  if (opts.dry) client = echoClient();
  else {
    if (!process.env.ANTHROPIC_API_KEY) {
      console.error("ANTHROPIC_API_KEY is not set - or --dry for a run without a model");
      return 2;
    }
    const { default: Anthropic } = await import("@anthropic-ai/sdk");
    client = new Anthropic({ maxRetries: 3 });
  }
  const cache = resolve(opts.cache);
  if (opts.corpus !== "test" && !existsSync(cache)) {
    console.error(`${cache}: no web corpus - run npm run report2cloud:web first, or --corpus test`);
    return 2;
  }
  const refused = refusedReports({ cache, corpus: opts.corpus });
  const chosen = spread(refused, Number(opts.limit) || 0);
  const examples = samples();
  console.log(`${refused.length} refused report(s), ${chosen.length} of them through the loop, ${examples.length} sample(s) in the prompt`);
  const rows = await pool(chosen, Number(opts.parallel), async (entry, i) => {
    const row = await evaluate(entry, { client, model: opts.model, examples });
    console.log(`${String(i + 1).padStart(4)}/${chosen.length} ${row.error ? `error: ${row.error}` : row.clean ? "clean" : row.accepted ? "accepted" : `${row.left} left`}  ${row.file}`);
    return row;
  });
  const md = markdown({ rows, total: chosen.length, model: opts.dry ? "dry" : opts.model, dry: opts.dry });
  console.log(md);
  if (opts.summary) appendFileSync(opts.summary, md);
  if (opts.json) writeFileSync(resolve(opts.json), `${rows.map((r) => JSON.stringify(r)).join("\n")}\n`);
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === new URL(import.meta.url).pathname) {
  process.exitCode = await main();
}
