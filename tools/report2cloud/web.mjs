#!/usr/bin/env node
// report2cloud web corpus - the converter measured on the open-source ABAP of
// the web, the number every stage of the roadmap is measured by.
//
//   node tools/report2cloud/web.mjs [--list url|file] [--cache dir] [--limit n]
//        [--lint] [--json file] [--summary file] [--offline]
//
// The repositories are the ones the community list of ABAP projects names
// (dotabap-list, list.json - "owner/repo" strings), cloned shallow and
// sparse into the cache (default build/web-corpus): only *.prog.abap and
// *.prog.xml, nothing else of a repository is fetched. The code is read, never run,
// and none of it is part of this repository - the cache is under build/.
// A clone that is there already is kept (--offline uses the cache alone).
//
// Every report is converted with its includes from its own repository
// (coverage( ) of coverage.mjs) and named z2ui5_cl_cgui_w<n> - the reports
// of two repositories often share a name. With --lint the converted classes
// are linted together, v750 with the repository's config (abaplint, a
// scratch copy of the repository): the findings in the generated classes,
// ranked - most of them name a dependency of the report that is not in the
// sparse clone, the parser errors and redefinitions are the converter's.
//
// Prints the summary; --summary appends it as Markdown (the job summary of
// the weekly workflow), --json writes a line per report. Exit code 1 when a
// report crashes the converter - a crash is a bug, a refusal is not - else 0.
import { appendFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { dirname, join, relative, resolve } from "node:path";
import { coverage, programs, ranked } from "./coverage.mjs";
import { includesFrom } from "./lib/includes.mjs";
import { REPO } from "./lib/gate.mjs";

export const LIST_URL = "https://raw.githubusercontent.com/dotabap/dotabap-list/main/list.json";

const USAGE = `usage: node tools/report2cloud/web.mjs [--list url|file] [--cache dir] [--limit n] [--lint] [--json file] [--summary file] [--offline]`;

function args(argv) {
  const opts = { list: LIST_URL, cache: join(REPO, "build", "web-corpus") };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") opts.help = true;
    else if (a === "--lint") opts.lint = true;
    else if (a === "--offline") opts.offline = true;
    else if (["--list", "--cache", "--limit", "--json", "--summary"].includes(a)) {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else throw new Error(`unknown option ${a}`);
  }
  return opts;
}

/** "owner/repo" strings of the list - a URL or a file */
async function repositories(list) {
  const text = /^https?:/.test(list) ? await (await fetch(list)).text() : readFileSync(list, "utf8");
  const names = JSON.parse(text);
  if (!Array.isArray(names)) throw new Error(`${list}: not a JSON array`);
  return names.filter((n) => typeof n === "string" && /^[\w.-]+\/[\w.-]+$/.test(n));
}

const folderOf = (name) => name.replace("/", "__");

function git(cwd, ...argv) {
  return new Promise((done) => {
    const p = spawn("git", argv, { cwd, stdio: "ignore", env: { ...process.env, GIT_TERMINAL_PROMPT: "0" } });
    const timer = setTimeout(() => p.kill("SIGKILL"), 180_000);
    p.on("close", (code) => {
      clearTimeout(timer);
      done(code === 0);
    });
  });
}

/** a shallow clone of the reports of one repository - true when it is there */
async function clone(name, cache) {
  const dir = join(cache, folderOf(name));
  if (existsSync(join(dir, ".git"))) return true;
  if (!(await git(cache, "clone", "--quiet", "--depth", "1", "--filter=blob:none", "--sparse", `https://github.com/${name}`, folderOf(name)))) return false;
  return git(dir, "sparse-checkout", "set", "--no-cone", "*.prog.abap", "*.prog.xml");
}

async function fetchAll(names, cache, parallel = 8) {
  const failed = [];
  let next = 0;
  await Promise.all(Array.from({ length: parallel }, async () => {
    while (next < names.length) {
      const name = names[next++];
      if (!(await clone(name, cache))) failed.push(name);
    }
  }));
  return failed;
}

/** what a lint finding is about, without the names of one report */
const kindOf = (f) => `${f.key}: ${String(f.message).replace(/"[^"]*"/g, "\"…\"").replace(/\b[A-Z0-9_]{3,}\b/g, "…").slice(0, 100)}`;

export function markdown({ rows, repos, failed, findings }) {
  const converted = rows.filter((r) => r.ok).length;
  const crashed = rows.filter((r) => r.crashed);
  const pct = (n) => (rows.length ? `${Math.round((n / rows.length) * 100)} %` : "-");
  const lines = [
    "## report2cloud on the web corpus",
    "",
    `**${converted} of ${rows.length} reports converted (${pct(converted)})** - ${rows.length - converted - crashed.length} refused, ${crashed.length} crashed; ${repos} repositor${repos === 1 ? "y" : "ies"}${failed.length ? `, ${failed.length} not cloned` : ""}.`,
    "",
    "| reports | share | refused for |",
    "|---:|---:|---|",
    ...ranked(rows.filter((r) => r.ok === false), "refusals").slice(0, 20).map(([k, n]) => `| ${n} | ${pct(n)} | ${k.replace(/\|/g, "\\|")} |`),
  ];
  if (findings) {
    const byKind = new Map();
    for (const f of findings) byKind.set(kindOf(f), (byKind.get(kindOf(f)) ?? 0) + 1);
    const parser = findings.filter((f) => f.key === "parser_error").length;
    lines.push("", `abaplint v750 over the converted classes: ${findings.length} finding(s), ${parser} parser error(s) - most findings name a dependency the sparse clone does not have.`, "",
      "| findings | kind |", "|---:|---|",
      ...[...byKind].sort((a, b) => b[1] - a[1]).slice(0, 15).map(([k, n]) => `| ${n} | ${k.replace(/\|/g, "\\|")} |`));
  }
  if (crashed.length) lines.push("", "Crashed the converter:", "", ...crashed.map((c) => `- \`${c.file}\`: ${c.crashed}`));
  return `${lines.join("\n")}\n`;
}

async function main() {
  let opts;
  try {
    opts = args(process.argv.slice(2));
  } catch (e) {
    console.error(`${e.message}\n\n${USAGE}`);
    return 1;
  }
  if (opts.help) {
    console.log(USAGE);
    return 0;
  }
  const cache = resolve(opts.cache);
  mkdirSync(cache, { recursive: true });
  let names = opts.offline ? readdirSync(cache).filter((d) => d.includes("__")).map((d) => d.replace("__", "/")) : await repositories(opts.list);
  if (opts.limit) names = names.slice(0, Number(opts.limit));
  const failed = opts.offline ? [] : await fetchAll(names, cache);
  if (failed.length) console.log(`${failed.length} repositor${failed.length === 1 ? "y" : "ies"} not cloned: ${failed.slice(0, 10).join(", ")}${failed.length > 10 ? ", …" : ""}`);

  // a report's includes from its own repository only
  let n = 0;
  const rows = [];
  for (const name of names) {
    const dir = join(cache, folderOf(name));
    if (!existsSync(dir)) continue;
    const files = programs(dir);
    const read = includesFrom([...new Set(files.map(dirname))]);
    for (const row of coverage(files, { read, keep: opts.lint, className: () => `z2ui5_cl_cgui_w${String(++n).padStart(4, "0")}` })) {
      rows.push({ ...row, file: relative(cache, row.file) });
    }
  }

  let findings;
  if (opts.lint) {
    const { lint } = await import("./lib/gate.mjs");
    const files = Object.assign({}, ...rows.filter((r) => r.files).map((r) => r.files));
    findings = Object.keys(files).length ? lint({ files, target: "v750", naming: false }).generated : [];
    for (const r of rows) delete r.files;
  }

  const md = markdown({ rows, repos: names.length, failed, findings });
  console.log(md);
  if (opts.summary) appendFileSync(opts.summary, md);
  if (opts.json) writeFileSync(resolve(opts.json), `${rows.map((r) => JSON.stringify(r)).join("\n")}\n`);
  return rows.some((r) => r.crashed) ? 1 : 0;
}

if (process.argv[1] && resolve(process.argv[1]) === new URL(import.meta.url).pathname) {
  process.exitCode = await main();
}
