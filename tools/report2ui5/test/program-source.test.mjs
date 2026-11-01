// The classic report as the semantic test runs it as a program
// (test/runtime/program-source.mjs), and the comparison of two lists
// (test/runtime/semantic.test.mjs) - without a backend.
import { test } from "node:test";
import assert from "node:assert/strict";
import { asProgram, normalize } from "./runtime/program-source.mjs";

test("the selection screen as data: the defaults where the run starts, then INITIALIZATION, then the values of the user", () => {
  const out = asProgram([
    "REPORT zt.",
    "PARAMETERS: p_name TYPE c LENGTH 10 LOWER CASE OBLIGATORY,",
    "            p_flag AS CHECKBOX DEFAULT 'X',",
    "            p_n    TYPE i DEFAULT 3.",
    "INITIALIZATION.",
    "  p_n = 4.",
    "START-OF-SELECTION.",
    "  FORMAT INTENSIFIED ON.",
    "  DATA gv_total TYPE i.",
    "  DATA(lv_text) = |{ p_name } { p_n }|.",
    "  WRITE: /5 lv_text, / p_flag.",
  ].join("\n"), { P_NAME: "Ada" });
  const code = out.split("\n").filter((l) => !l.startsWith("*")).map((l) => l.trim()).filter(Boolean);
  // the parameters as data, their type without the additions of the screen
  assert.deepEqual(code.slice(1, 4), ["DATA p_name TYPE c LENGTH 10.", "DATA p_flag TYPE c LENGTH 1.", "DATA p_n TYPE i."]);
  // INITIALIZATION a block of the run before the others, the defaults first in it
  const init = code.indexOf("PERFORM r2c_block_1.");
  assert.ok(init > 0 && code[init - 1] === "START-OF-SELECTION.", out);
  const form1 = code.slice(code.indexOf("FORM r2c_block_1."), code.indexOf("ENDFORM."));
  assert.deepEqual(form1.slice(1), ["p_flag = 'X'.", "p_n = 3.", "p_n = 4."]);
  // the user's value after them; the DATA of the block global, the inline one in the FORM
  const form2 = code.slice(code.indexOf("FORM r2c_block_2."));
  assert.equal(form2[1], "p_name = 'Ada'.");
  assert.ok(code.indexOf("DATA gv_total TYPE i.") < code.indexOf("FORM r2c_block_1."), out);
  assert.ok(form2.includes("DATA(lv_text) = |{ p_name } { p_n }|."), out);
  // FORMAT dropped, the position of a new line too
  assert.ok(!code.some((l) => /^FORMAT/.test(l)), out);
  assert.ok(form2.includes("WRITE: / lv_text, / p_flag."), out);
});

test("a program without START-OF-SELECTION cannot take values", () => {
  assert.throws(() => asProgram("REPORT zt.\nPARAMETERS p TYPE i.\nWRITE p.", { P: 1 }), /START-OF-SELECTION/);
});

test("the comparison: blanks, the format of a number or a date and ULINE alike - a text, an order, a line break not", () => {
  const classic = ["Hello Ada", "--------------------------------------------------", "Line1", "Total 1.234,50", "Due 20260119", "", ""];
  const converted = ["Hello  Ada", "---", "Line 1", "Total 1,234.50", "Due 01/19/2026"];
  assert.deepEqual(normalize(converted), normalize(classic));
  assert.notDeepEqual(normalize(["Hello Ada", "---", "Line 2"]), normalize(classic.slice(0, 3)));
  assert.notDeepEqual(normalize(["Line1", "Hello Ada"]), normalize(["Hello Ada", "Line1"]));
  assert.notDeepEqual(normalize(["Hello Ada Line1"]), normalize(["Hello Ada", "Line1"]));
});
