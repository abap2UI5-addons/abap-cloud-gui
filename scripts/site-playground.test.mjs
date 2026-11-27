// The app frame of the playground (site/playground.mjs appFrame( )): a Run
// started while another one still waits settles the one before - its timer
// of two minutes cannot speak over the newer run later, or take the newer
// run's listener down.
import { test, mock } from "node:test";
import assert from "node:assert/strict";

const FROM_PLAYGROUND = "abap2ui5-playground";
const tick = () => new Promise((resolve) => setImmediate(resolve));
const until = async (ok) => {
  for (let i = 0; i < 1000 && !ok(); i++) await tick();
  assert.ok(ok(), "timed out");
};

test("a second Run settles the first: the first's timer neither reports nor takes the second's listener down", async () => {
  let listener;
  globalThis.window = { addEventListener: (type, fn) => { if (type === "message") listener = fn; } };
  // runtime.json of the site - empty here
  globalThis.fetch = async () => ({ ok: true, json: async () => [] });
  const { appFrame } = await import("../site/playground.mjs");
  mock.timers.enable({ apis: ["setTimeout"] });
  try {
    const frame = { contentWindow: {}, src: "" };
    const cover = { hidden: false, textContent: "" };
    const steps = [];
    const start = appFrame(frame, cover, (s) => steps.push(s), undefined, undefined);
    const say = (data) => listener({ source: frame.contentWindow, data: { source: FROM_PLAYGROUND, ...data } });

    let first;
    start({ "zcl_a.clas.abap": "CLASS zcl_a DEFINITION. ENDCLASS." }, "zcl_a").then((x) => { first = x; });
    await until(() => frame.src.includes("run=1"));
    mock.timers.tick(60000);

    let second;
    start({ "zcl_b.clas.abap": "CLASS zcl_b DEFINITION. ENDCLASS." }, "zcl_b").then((x) => { second = x; });
    await until(() => first !== undefined);
    assert.deepEqual(first, { ok: false, said: "started again", problems: [] });
    await until(() => frame.src.includes("run=2"));

    // two minutes after the first Run: its timer is gone
    steps.length = 0;
    mock.timers.tick(61000);
    await tick();
    assert.deepEqual(steps.filter((s) => /two minutes/.test(s.text)), []);
    assert.equal(second, undefined);

    // the second Run still hears the frame
    say({ type: "status", state: "running", message: "running" });
    await until(() => second !== undefined);
    assert.equal(second.ok, true);
    assert.match(steps.at(-1).text, /^Started the class zcl_b/);
    assert.equal(cover.hidden, true);
  } finally {
    mock.timers.reset();
    delete globalThis.window;
    delete globalThis.fetch;
  }
});

test("a Run that hears nothing for two minutes says so", async () => {
  let listener;
  globalThis.window = { addEventListener: (type, fn) => { if (type === "message") listener = fn; } };
  globalThis.fetch = async () => ({ ok: true, json: async () => [] });
  const { appFrame } = await import("../site/playground.mjs");
  mock.timers.enable({ apis: ["setTimeout"] });
  try {
    const frame = { contentWindow: {}, src: "" };
    const steps = [];
    let outcome;
    appFrame(frame, { hidden: false, textContent: "" }, (s) => steps.push(s))({ "zcl_a.clas.abap": "" }, "zcl_a").then((x) => { outcome = x; });
    await until(() => frame.src.includes("run=1"));
    mock.timers.tick(120000);
    await until(() => outcome !== undefined);
    assert.deepEqual(outcome, { ok: false, said: "no start within two minutes", problems: [] });
    assert.match(steps.at(-1).text, /two minutes/);
    void listener;
  } finally {
    mock.timers.reset();
    delete globalThis.window;
    delete globalThis.fetch;
  }
});
