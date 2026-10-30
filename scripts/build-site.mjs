#!/usr/bin/env node
// The site of the repository (site/) - the page that presents the addon and
// the report2cloud playground, the converter bundled for the browser - into
// build/site, which the Pages workflow (.github/workflows/pages.yaml) deploys.
// A converted report runs in the abap2UI5 playground itself
// (https://abap2ui5.github.io/playground/), handed the class, the report
// runtime and the demo tables in its URL - runtime.json below.
//
//   npm run site           build/site
//   npm run site -- --serve   and serve it on http://localhost:8080
//
// examples.json: the reports of the converter's corpus that convert, with
// their text pools - the examples of the playground.
// runtime.json: what the playground needs beside a converted class
// (scripts/playground-runtime.mjs).
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";
import { convert } from "../tools/report2cloud/lib/convert.mjs";
import { parseTextpool } from "../tools/report2cloud/lib/textpool.mjs";
import { runtimeFiles } from "./playground-runtime.mjs";

const ROOT = join(fileURLToPath(import.meta.url), "..", "..");
const OUT = join(ROOT, "build", "site");
const CORPUS = join(ROOT, "tools", "report2cloud", "test", "corpus");

rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });
for (const f of ["index.html", "style.css"]) cpSync(join(ROOT, "site", f), join(OUT, f));

await build({
  entryPoints: [join(ROOT, "site", "playground.mjs")],
  bundle: true,
  format: "esm",
  platform: "browser",
  target: "es2022",
  minify: true,
  // abaplint finds its statement handlers by class name
  keepNames: true,
  outfile: join(OUT, "playground.js"),
  logLevel: "warning",
  // abaplint's downport rule requires crypto - the converter does not run it
  alias: { crypto: join(ROOT, "site", "shims", "crypto.mjs") },
  // and its built-in constants use Buffer.from( )
  inject: [join(ROOT, "site", "shims", "buffer.mjs")],
});

// a report with includes of its own is no example - the page has no includes;
// neither is an include
const examples = [];
for (const f of readdirSync(CORPUS).filter((x) => x.endsWith(".prog.abap")).sort()) {
  const source = readFileSync(join(CORPUS, f), "utf8");
  if (/^\s*include\s/im.test(source)) continue;
  // an include of a report is no report of its own
  if (!/^\s*(?:report|program)\s/im.test(source)) continue;
  const name = f.replace(/\.prog\.abap$/, "");
  const xml = join(CORPUS, `${name}.prog.xml`);
  const xmlText = existsSync(xml) ? readFileSync(xml, "utf8").replace(/^\uFEFF/, "") : undefined;
  const textpool = xmlText ? parseTextpool(xmlText) : undefined;
  const title = /^\*&\s+(?!Report\b)(.+?)\s*$/m.exec(source)?.[1] ?? name;
  const result = convert(source, { file: f, programName: name, textpool });
  examples.push({ name, title: title.replace(/[-,:]\s*$/, "").slice(0, 70), source, textpool, xml: xmlText, ok: result.ok });
}
// the ones that convert first, one that is refused at the end
examples.sort((a, b) => Number(b.ok) - Number(a.ok) || a.name.localeCompare(b.name));
// a text pool holds Maps - written as { "$map": entries }, revived by the page
const replacer = (k, v) => (v instanceof Map ? { $map: [...v] } : v);
writeFileSync(join(OUT, "examples.json"), JSON.stringify(examples.map(({ ok, ...e }) => e), replacer));
const runtime = runtimeFiles(ROOT);
writeFileSync(join(OUT, "runtime.json"), JSON.stringify(runtime));
console.log(`build/site: runtime.json, ${runtime.length} files for the playground`);
console.log(`build/site: ${examples.length} examples, ${examples.filter((e) => !e.ok).length} of them refused`);

if (process.argv.includes("--serve")) {
  const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".json": "application/json" };
  createServer((req, res) => {
    const path = join(OUT, decodeURIComponent(new URL(req.url, "http://x").pathname).replace(/\/$/, "/index.html"));
    if (!path.startsWith(OUT) || !existsSync(path)) {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, { "content-type": types[extname(path)] ?? "application/octet-stream" }).end(readFileSync(path));
  }).listen(8080, () => console.log("http://localhost:8080"));
}
