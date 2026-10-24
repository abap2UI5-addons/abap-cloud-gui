#!/usr/bin/env node
// npm run report2cloud:docs - writes docs/refusals.md from the catalogue of
// refusals (lib/refusals.mjs). The test of the corpus checks that the file is
// up to date.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { refusalsMarkdown } from "./lib/refusals.mjs";

export const REFUSALS_DOC = join(dirname(fileURLToPath(import.meta.url)), "docs", "refusals.md");

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  mkdirSync(dirname(REFUSALS_DOC), { recursive: true });
  writeFileSync(REFUSALS_DOC, refusalsMarkdown());
  console.log(`report2cloud: ${REFUSALS_DOC} written`);
}
