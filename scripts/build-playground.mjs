#!/usr/bin/env node
// The playground of the site: abap2UI5/playground at a pin, with the
// report2cloud patch of this repository applied, built with the addon of
// this checkout - a classic report as the first file is converted on Run and
// its class runs on the stage. The playground itself knows nothing of
// reports; everything that does is in site/playground/report2cloud.patch.
//
//   npm run site:playground            build/site/playground (after npm run site)
//   npm run site:playground -- --test  and run the patch's browser tests
//
// The clone is build/playground: fetched at the pin once, put back to the pin
// and patched again on every run - its build/, deps/ and node_modules stay,
// so the playground's own stamps keep a second build to the steps whose
// inputs moved (the downport of the framework and the UI5 build take minutes
// cold). A pin bump is the sha below; when the patch no longer applies, the
// playground moved under it, and the patch is made again on the new pin
// (site/playground/README.md says how).
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const PIN = {
  url: "https://github.com/abap2UI5/playground",
  sha: "42ac65a68f6b08d7676d8b42ab985a3d389d7570",
};

const ROOT = join(fileURLToPath(import.meta.url), "..", "..");
const SRC = join(ROOT, "build", "playground");
const PATCH = join(ROOT, "site", "playground", "report2cloud.patch");
const OUT = join(ROOT, "build", "site", "playground");
const log = (line) => console.log(`build-playground: ${line}`);
const run = (cmd, args, opts = {}) => execFileSync(cmd, args, { cwd: SRC, stdio: "inherit", ...opts });
const git = (...args) => execFileSync("git", args, { cwd: SRC, encoding: "utf8" }).trim();

if (!existsSync(join(ROOT, "build", "site", "index.html"))) {
  console.error("build-playground: build/site is missing - run npm run site first");
  process.exit(1);
}

// the pin, clean
if (!existsSync(join(SRC, ".git"))) {
  mkdirSync(SRC, { recursive: true });
  git("init", "-q");
  git("remote", "add", "origin", PIN.url);
}
if (headOf() !== PIN.sha) {
  log(`fetching ${PIN.url} @ ${PIN.sha.slice(0, 12)}`);
  git("fetch", "-q", "--depth", "1", "origin", PIN.sha);
  git("checkout", "-q", "--force", "--detach", PIN.sha);
}
// the clone only - what a patch applied or someone staged there goes
git("reset", "-q", "--hard");
git("clean", "-q", "-fd");

// the patch - a failure here is the playground having moved under it
try {
  git("apply", "--whitespace=nowarn", PATCH);
} catch {
  console.error(`build-playground: site/playground/report2cloud.patch does not apply to the playground @ ${PIN.sha.slice(0, 12)} - make it again (site/playground/README.md)`);
  process.exit(1);
}
log("report2cloud.patch applied");

// its dependencies, again only when its lockfile moved
const lock = createHash("sha256").update(readFileSync(join(SRC, "package-lock.json"))).digest("hex");
const lockStamp = join(SRC, "node_modules", ".lock-stamp");
if (!existsSync(lockStamp) || readFileSync(lockStamp, "utf8") !== lock) {
  run("npm", ["ci", "--no-audit", "--no-fund"]);
  writeFileSync(lockStamp, lock);
}

// the build, the addon of this checkout in it
const env = { ...process.env, R2C_ADDON: ROOT, R2C_COMMIT: commitOfRoot() };
run(process.execPath, ["tools/build.mjs"], { env });

rmSync(OUT, { recursive: true, force: true });
cpSync(join(SRC, "dist"), OUT, { recursive: true });
log(`build/site/playground (the playground @ ${PIN.sha.slice(0, 12)}, the addon @ ${env.R2C_COMMIT.slice(0, 12)})`);

if (process.argv.includes("--test")) {
  // the playground's own Playwright, and its browser on CI
  if (process.env.CI) run("npx", ["playwright", "install", "--with-deps", "chromium"]);
  run("npx", ["playwright", "test", "tests/report2cloud.spec.js"], { env });
  run(process.execPath, ["--test", "tests/node/report-files.test.mjs"], { env });
}

function headOf() {
  try {
    return git("rev-parse", "HEAD");
  } catch {
    // a fresh clone has no commit yet
    return undefined;
  }
}

function commitOfRoot() {
  try {
    return execFileSync("git", ["rev-parse", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim();
  } catch {
    return "local";
  }
}
