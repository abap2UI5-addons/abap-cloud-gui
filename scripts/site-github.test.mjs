// The GitHub links the playground's import understands (site/github.mjs).
import { test } from "node:test";
import assert from "node:assert/strict";
import { parseGithub, rawUrl } from "../site/github.mjs";

test("a repository, by link or as owner/repo", () => {
  const repo = { owner: "abap2UI5-addons", repo: "abap-cloud-gui", ref: "", path: "", file: false };
  assert.deepEqual(parseGithub("https://github.com/abap2UI5-addons/abap-cloud-gui"), repo);
  assert.deepEqual(parseGithub("github.com/abap2UI5-addons/abap-cloud-gui.git/"), repo);
  assert.deepEqual(parseGithub("abap2UI5-addons/abap-cloud-gui"), repo);
});

test("a folder", () => {
  assert.deepEqual(parseGithub("https://github.com/o/r/tree/main/src/reports?x=1"), { owner: "o", repo: "r", ref: "main", path: "src/reports", file: false });
  assert.deepEqual(parseGithub("https://github.com/o/r/tree/v1.0.0"), { owner: "o", repo: "r", ref: "v1.0.0", path: "", file: false });
});

test("a file, as blob or raw link", () => {
  const file = { owner: "o", repo: "r", ref: "main", path: "src/zflights.prog.abap", file: true };
  assert.deepEqual(parseGithub("https://github.com/o/r/blob/main/src/zflights.prog.abap#L10"), file);
  assert.deepEqual(parseGithub("https://raw.githubusercontent.com/o/r/main/src/zflights.prog.abap"), file);
  assert.equal(rawUrl(file, file.path), "https://raw.githubusercontent.com/o/r/main/src/zflights.prog.abap");
  assert.equal(rawUrl(file, "src/z#a.prog.abap"), "https://raw.githubusercontent.com/o/r/main/src/z%23a.prog.abap");
});

test("anything else is no GitHub link", () => {
  for (const x of ["", "zreport", "https://gitlab.com/o/r", "https://github.com/o", "https://github.com/o/r/issues/1"]) {
    assert.equal(parseGithub(x), undefined, x);
  }
});
