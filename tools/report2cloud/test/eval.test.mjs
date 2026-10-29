// The evaluation of the AI loop (eval.mjs) without a model: clients that
// answer the way a model might - the report unchanged, the refused lines
// dropped, another report altogether - and what the harness makes of each.
import { test } from "node:test";
import assert from "node:assert/strict";
import { convert } from "../lib/convert.mjs";
import { echoClient, evaluate, kept, KEEP, markdown, refusedReports, samples, spread } from "../eval.mjs";

const REPORT = `REPORT zeval.
PARAMETERS p_text TYPE string.
START-OF-SELECTION.
  EXEC SQL.
    COMMIT
  ENDEXEC.
  WRITE / p_text.
${Array.from({ length: 20 }, (_, i) => `  WRITE / 'line ${i + 1}'.`).join("\n")}
  WRITE / 'done'.
`;

const entry = (source = REPORT) => {
  const options = { file: "zeval.prog.abap", programName: "zeval" };
  return { file: "zeval.prog.abap", source, result: convert(source, options), convert: (text) => convert(text, options) };
};

/** a client whose model answers with answer(report, refusedRows) */
function client(answer) {
  const calls = [];
  return {
    calls,
    beta: {
      messages: {
        stream: (params) => {
          calls.push(params);
          return {
            finalMessage: async () => {
              const first = params.messages[0].content.map((b) => b.text).join("\n");
              const report = /## The report\n\n```abap\n([\s\S]*?)\n```/.exec(first)[1];
              const rows = [...first.matchAll(/^- line (\d+):/gm)].map((m) => Number(m[1]));
              return {
                content: [{ type: "text", text: `- changed\n\n\`\`\`abap\n${answer(report, rows)}\n\`\`\`` }],
                stop_reason: "end_turn",
                usage: { input_tokens: 100, output_tokens: 10, cache_read_input_tokens: 50 },
              };
            },
          };
        },
      },
    },
  };
}

test("the refused lines dropped: accepted and clean, the kind removed, in one round", async () => {
  const e = entry();
  assert.equal(e.result.ok, false);
  const c = client((report, rows) => {
    const lines = report.split("\n");
    // EXEC SQL to ENDEXEC: the refused line and the block it opens
    const from = rows[0] - 1;
    const to = lines.findIndex((l, i) => i >= from && /ENDEXEC/i.test(l));
    lines.splice(from, to - from + 1, `  " AI: the native SQL has no counterpart`);
    return lines.join("\n");
  });
  const row = await evaluate(e, { client: c, model: "m", examples: samples().slice(0, 3) });
  assert.equal(row.error, undefined);
  assert.equal(row.accepted, true);
  assert.equal(row.clean, true);
  assert.equal(row.rounds, 1);
  assert.equal(row.ai, 1);
  assert.deepEqual(row.removed, row.kinds);
  assert.match(row.kinds[0], /native-sql/);
  assert.equal(row.usage.input_tokens, 100);
  assert.equal(c.calls[0].model, "m");
});

test("the report unchanged: three rounds, nothing removed", async () => {
  const row = await evaluate(entry(), { client: echoClient(), model: "m", examples: [] });
  assert.equal(row.accepted, false);
  assert.equal(row.clean, false);
  assert.equal(row.rounds, 3);
  assert.deepEqual(row.removed, []);
  assert.equal(row.left, row.refused);
});

test("another report altogether: accepted, not clean", async () => {
  const row = await evaluate(entry(), { client: client(() => "REPORT zeval.\nSTART-OF-SELECTION.\n  WRITE / 'other'.\n"), model: "m", examples: [] });
  assert.equal(row.accepted, true);
  assert.equal(row.clean, false);
  assert.ok(row.kept < KEEP);
});

test("an answer without the report is an error of the row, not of the run", async () => {
  const bad = { beta: { messages: { stream: () => ({ finalMessage: async () => ({ content: [{ type: "text", text: "no code" }], stop_reason: "end_turn" }) }) } } };
  const row = await evaluate(entry(), { client: bad, model: "m", examples: [] });
  assert.match(row.error, /no ```abap block/);
});

test("kept: the lines that were not refused, unchanged", () => {
  assert.equal(kept(REPORT, REPORT, []), 1);
  // a refused line may change, the others count
  assert.equal(kept(REPORT, REPORT.replace("EXEC SQL.", "\" gone"), [{ row: 4 }]), 1);
  assert.ok(kept(REPORT, REPORT.replace("WRITE / p_text.", "WRITE / 'x'."), []) < 1);
});

test("spread: n of the list, evenly and the same each time", () => {
  const list = Array.from({ length: 10 }, (_, i) => i);
  assert.deepEqual(spread(list, 3), [0, 3, 6]);
  assert.deepEqual(spread(list, 3), spread(list, 3));
  assert.equal(spread(list, 0).length, 10);
  assert.equal(spread(list, 20).length, 10);
});

test("the test corpus: its refused report, and the samples of the prompt convert", () => {
  const refused = refusedReports({ corpus: "test" });
  assert.ok(refused.length >= 1);
  assert.ok(refused.every((r) => r.result.ok === false && typeof r.convert === "function"));
  assert.ok(samples().length >= 10);
});

test("the summary: clean, accepted, rounds, the kinds ranked, the errors", () => {
  const md = markdown({
    model: "m",
    total: 3,
    rows: [
      { file: "a", kinds: ["K1"], removed: ["K1"], accepted: true, clean: true, rounds: 1, usage: { input_tokens: 5 } },
      { file: "b", kinds: ["K1", "K2"], removed: ["K2"], accepted: false, clean: false, rounds: 3 },
      { file: "c", kinds: ["K1"], error: "the model declined the request" },
    ],
  });
  assert.match(md, /\*\*1 of 3 clean \(33 %\)\*\* - 1 accepted/);
  assert.match(md, /\| 2 \| 1 \| 50 % \| K1 \|/);
  assert.match(md, /\| 1 \| 1 \| 100 % \| K2 \|/);
  assert.match(md, /\| 1 \| the model declined the request \|/);
  assert.match(md, /Tokens: 5 input/);
});
