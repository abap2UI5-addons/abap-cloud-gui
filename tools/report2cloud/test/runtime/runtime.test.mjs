// report2cloud, golden master lite: the generated classes RUN.
//
// The corpus is converted, the classes are transpiled with src/01
// against @abap2ui5/node-runtime (backend.mjs), the stubs of the flight
// tables are seeded (seed.mjs), and every report is operated the way a user
// operates it - start the app, fill the selection screen, Execute, click a
// line - through the JSON protocol of the UI5 frontend (driver.mjs, the app
// client of the abap2UI5 MCP server). The answers are read semantically: the
// agent snapshot (fields, actions, tables, messages) and the lines of the
// list. Every expectation is written by hand - what the classic report
// prints for the seeded rows - except where the comment says the list or the
// runtime differs on purpose.
//
//   npm run test:report2cloud:runtime
//
// Opt-in, like the abaplint gates it complements: it needs an mcp-server
// checkout (MCP_SERVER_HOME or ../mcp-server), git and network for the first
// install of the runtime (A2UI5_MCP_WORKSPACE, default ~/.abap2ui5-mcp). Without
// an mcp-server checkout every test is skipped with the reason.
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { rmSync } from "node:fs";
import { corpus, convertEntry, DDIC } from "../corpus.mjs";
import { buildBackend, resolveMcpServer, startBackend } from "./backend.mjs";
import { createDriver } from "./driver.mjs";
import { dateIn, seedSql } from "./seed.mjs";

const PORT = Number(process.env.REPORT2CLOUD_RUNTIME_PORT || 4481);
const mcp = resolveMcpServer();
const skip = mcp.missing || false;

/** a date as the list writes it (the default format of the UI5 frontend, MM/DD/YYYY) */
const listDate = (yyyymmdd) => `${yyyymmdd.slice(4, 6)}/${yyyymmdd.slice(6, 8)}/${yyyymmdd.slice(0, 4)}`;

let build;
let backend;
let d;

before(async () => {
  if (skip) return;
  const files = {};
  for (const e of corpus()) {
    const { result } = convertEntry(e);
    if (result.ok) Object.assign(files, result.files);
  }
  const log = [];
  build = await buildBackend({ files, ddic: DDIC, seed: seedSql(), onLine: (l) => log.push(l) });
  assert.ok(build.ok, `the backend did not build: ${build.reason}\n${log.slice(-30).join("\n")}`);
  // the CLASS-DATA of the local classes of the reports cleared before every
  // request - a roundtrip is a session of its own on a system
  backend = await startBackend({ build, port: PORT, freshStatics: "^CLAS-Z2UI5_CL_CGUI_R2C_\\d+-" });
  d = await createDriver({ mcp: mcp.dir, url: backend.url });
}, { timeout: 20 * 60_000 });

after(async () => {
  if (backend) await backend.stop();
  if (build?.dir && !process.env.REPORT2CLOUD_RUNTIME_KEEP) rmSync(build.dir, { recursive: true, force: true });
});

const fieldsOf = (s) => s.fields.map((f) => `${f.name}=${JSON.stringify(f.value)}${f.required ? "*" : ""}`);
const toasts = (s) => s.messages.filter((m) => m.source === "toast").map((m) => m.text);
const boxes = (s) => s.messages.filter((m) => m.source === "box").map((m) => m.text);
/** the message popover of the main view (z2ui5_cl_cgui_report messages_render): "<type>: <title>" per message of the run */
const popover = (s) => s.messages.filter((m) => m.source === "popover").map((m) => `${m.type}: ${m.text}`);
/** the value states of the selection screen's fields */
const valueStates = (s) => s.messages.filter((m) => m.source === "field").map((m) => `${m.type}: ${m.text}`);
const rowsOf = (t) => t.rows.map((r) => `${r.WERKS} ${r.NAME}`);
const actionsOf = (s, event) => s.actions.filter((a) => a.event === event);

test("zr2c_01_hello: parameters, OBLIGATORY, a DO loop of WRITEs", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_01");
  assert.equal(s.title, "Hello World");
  assert.deepEqual(fieldsOf(s), ['P_NAME=""*', "P_TIMES=3"]);
  // the command field of the SAP GUI in the page header, empty
  assert.equal(s.command?.value, "");
  assert.deepEqual(s.fields.map((f) => f.label), ["Your name", "Lines"]);

  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(valueStates(s), ["error: Fill in the required field Your name"], "OBLIGATORY keeps the screen");
  assert.deepEqual(popover(s), valueStates(s), "the popover collects the messages of the run");

  s = await d.act(s.session, { values: { P_NAME: "World" }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Hello World", "---", "Line 1", "Line 2", "Line 3", "", "Done."]);

  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_TIMES: 1 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Hello World", "---", "Line 1", "", "Done."], "the screen kept World");
});

test("zr2c_02_flights: SELECT with a select-option, TOP-OF-PAGE, colors, HIDE, AT LINE-SELECTION, END-OF-SELECTION", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_02");
  assert.equal(s.title, "Flights of an Airline");
  // a select-option shows its first line as inputs from and to, bound to the
  // runtime's buffer mt_cgui_so - INITIALIZATION's interval
  assert.deepEqual(fieldsOf(s), ['P_CARRID="LH"*', `MT_CGUI_SO-0-LOW="${dateIn(0)}"`, `MT_CGUI_SO-0-HIGH="${dateIn(90)}"`, "P_MAX=100"]);
  assert.equal(actionsOf(s, "CGUI_SELECT_OPTION")[0].args[0], "S_FLDATE");

  // INITIALIZATION: today .. today + 90 - two of the four LH flights
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const header = ["Airline No. Date Price Occupied", "---"];
  const flights = [`LH 0400 ${listDate(dateIn(10))} 666.00 EUR 120`, `LH 0402 ${listDate(dateIn(30))} 777.50 EUR 385`];
  assert.deepEqual(d.lines(), [...header, ...flights, "", "Seats occupied in total: 505"]);
  // the carrier is the hotspot, its HIDE the key of the flight
  const clicks = actionsOf(s, "CGUI_LINE_SELECTION");
  assert.deepEqual(clicks.map((a) => a.args[1]), [`LH\t0400\t${dateIn(10)}`, `LH\t0402\t${dateIn(30)}`]);

  // AT LINE-SELECTION reads the HIDE fields and the table of the run
  s = await d.act(s.session, { event: clicks[1].id });
  assert.deepEqual(boxes(s), ["Flight LH 0402: 385 seats occupied"]);

  // a second run starts afresh - the total is not summed up twice
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().slice(-1), ["Seats occupied in total: 505"]);

  // AT SELECTION-SCREEN: MESSAGE e001 keeps the selection screen
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_MAX: 2000 }, event: "CGUI_EXECUTE" });
  assert.ok(s.fields.length, "still on the selection screen");
  assert.deepEqual(popover(s), ["error: At most 1000 rows, not 2000"]);

  // no flight: MESSAGE s002 and RETURN - the classic END-OF-SELECTION still
  // ran, and the header came with its first WRITE
  s = await d.act(s.session, { values: { P_MAX: 100, P_CARRID: "XX" }, event: "CGUI_EXECUTE" });
  assert.deepEqual(toasts(s), ["No flights of airline XX"]);
  assert.deepEqual(d.lines(), [...header, "", "Seats occupied in total: 0"]);
});

test("zr2c_03_forms: FORMs with USING, CHANGING, TABLES, RANGES - the totals", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_03");
  assert.deepEqual(s.fields.map((f) => `${f.name}=${f.value}${f.required ? "*" : ""}`), ["P_ITEMS=5*", "P_DISC=0.05", "P_VAT=true"]);

  // five items, quantity 2i at 10 + i; only item 5 (quantity 10) gets the discount
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const items = ["1 PROD-1 2 11.00", "2 PROD-2 4 12.00", "3 PROD-3 6 13.00", "4 PROD-4 8 14.00", "5 PROD-5 10 15.00"];
  assert.deepEqual(d.lines(), [...items, "---", "Net: 402.50", "Gross: 478.98"]);

  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_VAT: false }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().slice(-2), ["Net: 402.50", "Gross: 402.50"], "a second run: the items are not appended to the first run's");

  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_ITEMS: 60 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(s.messages.filter((m) => m.source === "field").map((m) => m.text), ["Between 1 and 50 items"]);
});

test("zr2c_04_salv: CL_SALV_TABLE as alv( ) - column texts, hidden columns, the list header", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_04");
  // S_CARRID (OBLIGATORY, DEFAULT 'LH') from and to, S_CITYFR (NO INTERVALS) from only
  assert.deepEqual(fieldsOf(s), ['MT_CGUI_SO-0-LOW="LH"*', 'MT_CGUI_SO-0-HIGH=""*', 'MT_CGUI_SO-1-LOW=""', "P_ROWS=200"]);
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const [t] = s.tables;
  assert.equal(t.label, "Flight connections (3)");
  assert.deepEqual(t.rows.map((r) => `${r.CARRID} ${r.CONNID} ${r.CITYFROM}`), ["LH 0400 FRANKFURT", "LH 0402 FRANKFURT", "LH 2402 BERLIN"]);
  const columns = t.columns.map((c) => c.name);
  assert.ok(!columns.includes("MANDT") && !columns.includes("FLTIME"), "set_technical / set_visible( abap_false )");
  assert.equal(t.columns.find((c) => c.name === "CITYFROM").label, "Departure city", "the longest text wins");

  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_ROWS: 1 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(s.tables[0].rows.map((r) => r.CONNID), ["0400"], "UP TO p_rows ROWS");
});

test("zr2c_05_reuse: REUSE_ALV_GRID_DISPLAY with a field catalog and the USER_COMMAND callback", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_05");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const [t] = s.tables;
  assert.equal(t.label, "Airlines (3)");
  assert.deepEqual(t.columns.map((c) => `${c.name}:${c.label}`), ["CARRID:Airline", "CARRNAME:Name", "CURRCODE:Currency", "URL:Website"]);
  assert.deepEqual(t.rows.map((r) => r.CARRID), ["AA", "LH", "SQ"]);

  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_CURR: "EUR" }, event: "CGUI_EXECUTE" });
  assert.deepEqual(s.tables[0].rows.map((r) => r.CARRNAME), ["Lufthansa"]);
  // the double click (&IC1) - the row path is what the browser computes
  s = await d.act(s.session, { event: "CGUI_ALV_LINE_SELECTION", args: ["/GT_SCARR/0"] });
  assert.deepEqual(boxes(s), ["Lufthansa: http://www.lufthansa.com"]);
});

test("zr2c_19_grid: cl_gui_alv_grid on a screen - the grid, its toolbar, the double click, the hotspot, the PAI module", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_19");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const [t] = s.tables;
  assert.equal(t.label, "Flights (4)");
  const cols = t.columns.map((c) => `${c.name}:${c.label}`);
  assert.ok(cols.includes("CONNID:Flight") && cols.includes("SEATSOCC:Occupied"), cols.join(" "));
  assert.ok(!t.columns.some((c) => c.name === "MANDT"), "the field catalog hides MANDT");
  assert.deepEqual(t.rows.map((r) => r.CONNID), ["0400", "0400", "0402", "2402"]);
  assert.ok(s.texts.includes("Total Occupied 815"), "the total of the do_sum column: 120 + 385 + 300 + 10");
  // the buttons of the TOOLBAR handler and of the status MAIN, the hotspot and the double click
  for (const f of ["FULL", "ALL", "REFRESH", "CGUI_ALV_HOTSPOT", "CGUI_ALV_LINE_SELECTION"]) assert.ok(actionsOf(s, f).length >= 1, `an action ${f}`);

  // USER_COMMAND handler: one flight is full
  s = await d.act(s.session, { event: "FULL" });
  assert.deepEqual(toasts(s), ["1 full flights"]);
  // HOTSPOT_CLICK on CONNID of the third row
  s = await d.act(s.session, { event: "CGUI_ALV_HOTSPOT", args: ["/GT_FLIGHT/2", "CONNID"] });
  assert.deepEqual(toasts(s), ["Connection 0402"]);
  // DOUBLE_CLICK on the last row
  s = await d.act(s.session, { event: "CGUI_ALV_LINE_SELECTION", args: ["/GT_FLIGHT/3"] });
  assert.equal(boxes(s).length, 1);
  assert.match(boxes(s)[0], /^Flight 2402 on /);
  // the PAI module: REFRESH reads the flights again; Back is the selection screen
  s = await d.act(s.session, { event: "ALL" });
  assert.deepEqual(toasts(s), ["4 flights"]);
  s = await d.act(s.session, { event: "REFRESH" });
  assert.equal(s.tables[0].rows.length, 4);
  s = await d.act(s.session, { event: "CGUI_BACK" });
  assert.ok(s.fields.some((f) => f.name === "P_CARRID"), "the selection screen");
});

test("zr2c_23_dynpro: a dynpro of fields - CALL SCREEN, PBO with status and LOOP AT SCREEN, PAI modules, SET SCREEN, LEAVE TO SCREEN", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_23");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.equal(s.title, "Booking on airline LH", "SET TITLEBAR of the PBO module");
  assert.deepEqual(fieldsOf(s), ['P_CARRID="LH"', 'GV_CONNID="0000"*', "GV_SEATS=0", "GV_WINDOW=false", "GV_ECO=true", "GV_BUS=false"]);
  for (const f of ["SAVE", "CHECK"]) assert.ok(actionsOf(s, f).length >= 1, `an action ${f}`);

  // the required field first, then FIELD gv_connid MODULE check_connid ON INPUT
  s = await d.act(s.session, { values: { GV_CONNID: "" }, event: "SAVE" });
  assert.deepEqual(valueStates(s), ["error: Fill in the required field Connection"]);
  s = await d.act(s.session, { values: { GV_CONNID: "9999" }, event: "CGUI_ENTER" });
  assert.deepEqual(popover(s), ["error: No such connection"]);
  // the push button; Save before the check is an error of user_command_0100
  s = await d.act(s.session, { values: { GV_CONNID: "0400" }, event: "SAVE" });
  assert.deepEqual(popover(s), ["error: Check the connection and enter the seats"]);
  s = await d.act(s.session, { event: "CHECK" });
  assert.deepEqual(toasts(s), ["The connection has seats"]);

  // SET SCREEN 200, Back there is LEAVE TO SCREEN 100, Book is LEAVE TO SCREEN 0
  s = await d.act(s.session, { values: { GV_SEATS: 2 }, event: "SAVE" });
  assert.ok(s.texts.includes("Book the seats now?"), s.texts.join(" | "));
  s = await d.act(s.session, { event: "CGUI_BACK" });
  assert.ok(s.fields.some((f) => f.name === "GV_CONNID"), "screen 0100 again");
  s = await d.act(s.session, { event: "SAVE" });
  s = await d.act(s.session, { event: "BOOK" });
  // what followed CALL SCREEN: after_call_screen( )
  assert.deepEqual(d.lines(), ["Booked: 2 seat(s) on LH 0400"]);

  // AT EXIT-COMMAND on screen 0100: nothing booked
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  s = await d.act(s.session, { event: "CGUI_BACK" });
  assert.deepEqual(d.lines(), ["Nothing booked"]);
});

test("zr2c_24_gridinline: no selection screen - the grid created inline in INITIALIZATION shows at once, its VALUE field catalog applied", { skip }, async () => {
  // no selection screen: INITIALIZATION goes straight on, the grid is the first page
  let s = await d.start("z2ui5_cl_cgui_r2c_24");
  assert.deepEqual(s.fields, []);
  // the table is no attribute: alv( ) copied it into a data reference, bound as {/MR_CGUI_ALV/*}
  const xml = d.state().slots.MAIN.xml;
  assert.match(xml, /rows="\{\/MR_CGUI_ALV\/\*\}"/);
  assert.equal(s.tables.length, 1);
  assert.equal(s.tables[0].label, "Connections in a grid (4)");
  assert.deepEqual(s.tables[0].rows.map((r) => `${r.CARRID} ${r.CONNID}`), ["AA 0017", "LH 0400", "LH 0402", "LH 2402"], "ORDER BY carrid, connid");
  // the VALUE field catalog: the column texts, MANDT hidden
  for (const label of ["Airline", "Flight", "From", "To"]) assert.match(xml, new RegExp(`text="${label}"`), label);
  assert.doesNotMatch(xml, /text="MANDT"|"\{MANDT\}"/, "MANDT is hidden");

  // the PAI module: Back leaves the screen - an empty selection screen, Execute runs it again
  s = await d.act(s.session, { event: "CGUI_BACK" });
  assert.deepEqual(s.fields, []);
  assert.ok(actionsOf(s, "CGUI_EXECUTE").length >= 1);
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.equal(s.tables[0].label, "Connections in a grid (4)");
});

test("zr2c_25_textedit: a text editor and an HTML viewer in the custom control areas of a dynpro - typed, previewed, saved", { skip }, async () => {
  const gui = () => d.state().models.MAIN.data.MT_CGUI_GUI;
  const html = () => gui().filter((c) => c.KIND === "HTML" && !c.FREED).map((c) => c.HTML).join("");
  let s = await d.start("z2ui5_cl_cgui_r2c_25");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  // the PBO module created the controls once: the text of gt_notes, the preview
  const editor = s.fields.find((f) => f.control === "sap.m.TextArea");
  assert.ok(editor, fieldsOf(s).join(" "));
  assert.equal(editor.value, "First line of the notes\nSecond line");
  assert.equal(editor.editable, true);
  assert.match(html(), /<h3>Notes of LH<\/h3>\n<p>First line of the notes<\/p>/);
  assert.match(d.state().slots.MAIN.xml, /<core:HTML [^>]*sanitizeContent="true"/);

  // typed and checked: the PAI reads the editor, the preview follows
  s = await d.act(s.session, { values: { [editor.name]: "Alpha\nBeta" }, event: "CHECK" });
  assert.match(html(), /<p>Alpha<\/p>\n<p>Beta<\/p>/);
  assert.equal(s.fields.find((f) => f.control === "sap.m.TextArea").value, "Alpha\nBeta", "the PBO does not set the text again");

  // saved: the notes are the list after CALL SCREEN
  s = await d.act(s.session, { event: "SAVE" });
  assert.deepEqual(d.lines(), ["Alpha", "Beta"]);

  // a run anew: new controls in the areas, the ones before are gone
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.equal((d.state().slots.MAIN.xml.match(/<TextArea /g) || []).length, 1);
  assert.equal(s.fields.find((f) => f.control === "sap.m.TextArea").value, "First line of the notes\nSecond line");
  s = await d.act(s.session, { event: "CGUI_BACK" });
  assert.deepEqual(d.lines(), ["Nothing saved"]);
});

test("zr2c_26_events: a toolbar, the links of an HTML viewer and a dialog box - their events reach the handler methods of a local class", { skip }, async () => {
  const gui = () => d.state().models.MAIN.data.MT_CGUI_GUI;
  const html = () => gui().filter((c) => c.KIND === "HTML" && !c.FREED).map((c) => c.HTML).join("");
  const boxes = () => gui().filter((c) => c.DIALOG && !c.FREED).length;
  const press = (s, fcode) => {
    const a = actionsOf(s, "CGUI_GUI").find((x) => x.args.includes(fcode));
    assert.ok(a, `a button ${fcode}: ${JSON.stringify(actionsOf(s, "CGUI_GUI").map((x) => x.args))}`);
    // by its id: the arguments are static - the control, the event, the function code
    return d.act(s.session, { event: a.id });
  };
  // no selection screen: START-OF-SELECTION calls the screen at once
  let s = await d.start("z2ui5_cl_cgui_r2c_26");
  assert.match(html(), /Shown 1 time\(s\)/);
  // FUNCTION_SELECTED: Refresh shows the document again
  s = await press(s, "REFRESH");
  assert.match(html(), /Shown 2 time\(s\)/);
  // SAPEVENT: the action and the query table of the link
  s = await press(s, "SHOW?CONNID=0402");
  assert.deepEqual(toasts(s), ["SHOW 0402"]);
  // Details opens the dialog box once; its CLOSE frees it, a new one after that
  s = await press(s, "DETAILS");
  assert.equal(boxes(), 1);
  s = await press(s, "DETAILS");
  assert.equal(boxes(), 1, "mo_box is set - no second box");
  s = await press(s, "CLOSE");
  assert.equal(boxes(), 0, "on_close freed the sender");
  s = await press(s, "DETAILS");
  assert.equal(boxes(), 1);
});

test("zr2c_27_gridlocal: a grid in a local class - in the custom control area of its dynpro, the field catalog, the toolbar function, double click and hotspot to the handlers", { skip }, async () => {
  const rows = () => d.state().models.MAIN.data.MR_CGUI_ALV["*"];
  // no selection screen: START-OF-SELECTION calls the screen, its PBO creates the grid
  let s = await d.start("z2ui5_cl_cgui_r2c_27");
  const xml = () => d.state().slots.MAIN.xml;
  assert.match(xml(), /rows="\{\/MR_CGUI_ALV\/\*\}"/, "the grid in the custom control area");
  assert.deepEqual(rows().map((r) => `${r.CARRID} ${r.CONNID}`), ["AA 0017", "LH 0400", "LH 0402", "LH 2402"]);
  // the field catalog: its texts, the hotspot of the city
  for (const label of ["Airline", "Flight", "From", "To"]) assert.match(xml(), new RegExp(`text="${label}"`), label);
  assert.equal(s.tables[0]?.label, "Connections (4)", "grid_title of the layout, the ALV counts the rows");

  // double click and hotspot: the handlers read the row of their own table
  s = await d.act(s.session, { event: "CGUI_ALV_LINE_SELECTION", args: ["/MR_CGUI_ALV/*/1"] });
  assert.deepEqual(toasts(s), ["LH 0400"]);
  s = await d.act(s.session, { event: "CGUI_ALV_HOTSPOT", args: ["/MR_CGUI_ALV/*/2", "CITYFROM"] });
  assert.deepEqual(toasts(s), ["CITYFROM: FRANKFURT"]);

  // the function of the toolbar handler: user_command adds a row, refresh_table_display( ) shows it
  assert.ok(actionsOf(s, "ADD").length >= 1, JSON.stringify(s.actions.map((a) => a.event)));
  s = await d.act(s.session, { event: "ADD" });
  assert.equal(rows().length, 5);
  assert.equal(rows()[4].CARRID, "UA");

  // Back: LEAVE TO SCREEN 0 of the PAI module
  s = await d.act(s.session, { event: "CGUI_BACK" });
  assert.doesNotMatch(xml() ?? "", /MR_CGUI_ALV/);
});

test("zr2c_48_twogrids: two grids in a splitter - the first one shows, the other offers to show; the double click refreshes the items, which show then; back to the airlines", { skip }, async () => {
  const rows = () => d.state().models.MAIN.data.MR_CGUI_ALV["*"];
  const xml = () => d.state().slots.MAIN.xml;
  const show = (s) => {
    const a = actionsOf(s, "CGUI_GUI").find((x) => x.args.includes("CGUI_SHOW"));
    assert.ok(a, `a Show button: ${JSON.stringify(actionsOf(s, "CGUI_GUI").map((x) => x.args))}`);
    return d.act(s.session, { event: a.id });
  };
  // the first grid displayed shows; the second one, displayed after it, waits in its cell
  let s = await d.start("z2ui5_cl_cgui_r2c_48");
  assert.deepEqual(rows().map((r) => r.CARRID), ["AA", "LH", "SQ"]);
  assert.equal(s.tables[0]?.label, "Airlines (3)");
  assert.match(xml(), /text="Connections \(0\)"/, "the items grid offers to show");

  // the double click on Lufthansa: refresh_table_display( ) of the items shows them
  s = await d.act(s.session, { event: "CGUI_ALV_LINE_SELECTION", args: ["/MR_CGUI_ALV/*/1"] });
  assert.deepEqual(rows().map((r) => `${r.CARRID} ${r.CONNID}`), ["LH 0400", "LH 0402", "LH 2402"]);
  assert.equal(s.tables[0]?.label, "Connections (3)");
  assert.match(xml(), /text="Airlines \(3\)"/, "now the airlines offer to show");

  // back to the airlines - their handler still answers the double click
  s = await show(s);
  assert.deepEqual(rows().map((r) => r.CARRID), ["AA", "LH", "SQ"]);
  s = await d.act(s.session, { event: "CGUI_ALV_LINE_SELECTION", args: ["/MR_CGUI_ALV/*/0"] });
  assert.deepEqual(rows().map((r) => `${r.CARRID} ${r.CONNID}`), ["AA 0017"]);
  // the items again, the airlines in their cell
  s = await show(s);
  assert.deepEqual(rows().map((r) => r.CARRID), ["AA", "LH", "SQ"]);
  assert.match(xml(), /text="Connections \(1\)"/);
});

test("zr2c_49_coltree: a column tree - the header, the nodes with their cells beside them, a click on a node and on a link to the handlers", { skip }, async () => {
  const xml = () => d.state().slots.MAIN.xml;
  const press = (s, kind) => {
    const a = actionsOf(s, "CGUI_GUI").find((x) => x.args[1] === kind);
    assert.ok(a, `a ${kind}: ${JSON.stringify(actionsOf(s, "CGUI_GUI").map((x) => x.args))}`);
    return d.act(s.session, { event: a.id });
  };
  // no selection screen: START-OF-SELECTION calls the screen, its PBO builds the tree
  let s = await d.start("z2ui5_cl_cgui_r2c_49");
  // the headers, the text of a node from its item of the hierarchy column
  for (const text of ["Airline", "From", "To", "American Airlines", "Lufthansa"]) assert.match(xml(), new RegExp(`text="${text}"`), text);
  // Lufthansa expanded: its connections with the cities in their columns
  assert.match(xml(), /text="LH 0400"/);
  assert.match(xml(), /text="NEW YORK"/);
  assert.doesNotMatch(xml(), /text="AA 0017"/, "American Airlines is not expanded");
  // the address of an airline is a link: link_click with the node and the item
  s = await press(s, "LINK");
  assert.deepEqual(toasts(s), ["Open AA FROM"]);
  // a click on a node: item_double_click of the hierarchy column
  s = await press(s, "CLICK");
  assert.deepEqual(toasts(s), ["AA TREE"]);
});

test("zr2c_50_listtree: a list tree - the items of a node on its line, a click on a node and on a link to the handlers", { skip }, async () => {
  const xml = () => d.state().slots.MAIN.xml;
  const press = (s, kind) => {
    const a = actionsOf(s, "CGUI_GUI").find((x) => x.args[1] === kind);
    assert.ok(a, `a ${kind}: ${JSON.stringify(actionsOf(s, "CGUI_GUI").map((x) => x.args))}`);
    return d.act(s.session, { event: a.id });
  };
  let s = await d.start("z2ui5_cl_cgui_r2c_50");
  // the first item the text of the node, the others after it - no header
  for (const text of ["American Airlines", "Lufthansa", "0400", "FRANKFURT", "NEW YORK"]) assert.match(xml(), new RegExp(`text="${text}"`), text);
  assert.doesNotMatch(xml(), /design="Bold"/, "no header row");
  // the address of an airline is a link
  s = await press(s, "LINK");
  assert.deepEqual(toasts(s), ["Open AA"]);
  // a click on a node is one on its first item, by its name
  s = await press(s, "CLICK");
  assert.deepEqual(toasts(s), ["AA 1"]);
});

test("zr2c_21_lclreport: a local report class that reads the selection screen, writes the list and calls a FORM", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_21");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  // SELECT SINGLE into the TABLES work area, the local class's list, gc_max
  // of its constants, the FORM it PERFORMs with the total it summed up
  assert.deepEqual(d.lines(), [
    "Airline: Lufthansa",
    "Flights",
    "0400 300",
    "0400 120",
    "0402 385",
    "Seats occupied in the first 3 flights: 805",
  ]);
  // the instance kept from INITIALIZATION runs again, the total starts afresh
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().slice(-1), ["Seats occupied in the first 3 flights: 805"]);
  // an unknown airline: LEAVE PROGRAM is the selection screen again
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_CARRID: "XX" }, event: "CGUI_EXECUTE" });
  assert.ok(s.fields.some((f) => f.name === "P_CARRID"), "back on the selection screen");
  assert.deepEqual(toasts(s), ["Unknown airline"]);
});

test("zr2c_06_dynamic: radio buttons and checkbox with USER-COMMAND, MODIF ID, LOOP AT SCREEN, a push button, an own F4", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_06");
  assert.equal(s.title, "Dynamic Selection Screen");
  assert.deepEqual(fieldsOf(s), ["P_DISP=true", "P_CREA=false", 'P_MATNR=""', 'P_UNIT="PC"', "P_EXPERT=false"], "display mode: the CRE and EXP groups are inactive");

  // the radio button's USER-COMMAND: AT SELECTION-SCREEN sets the plant, OUTPUT switches the groups
  s = await d.act(s.session, { values: { P_CREA: true, P_DISP: false }, event: "MODE" });
  assert.deepEqual(fieldsOf(s), ["P_DISP=false", "P_CREA=true", 'P_NAME=""*', "P_QTY=0*", 'P_UNIT="PC"', "P_EXPERT=false"]);
  assert.ok(s.texts.includes("New materials are always created in plant 1000."));

  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(valueStates(s), ["error: Fill in the required field Description", "error: Fill in the required field Quantity"], "screen-required = 1");
  assert.deepEqual(popover(s), valueStates(s));

  s = await d.act(s.session, { values: { P_NAME: "Bolt", P_QTY: 10000 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(s.messages.filter((m) => m.source === "field").map((m) => m.text), ["At most 9999 pieces"], "AT SELECTION-SCREEN ON p_qty");

  s = await d.act(s.session, { values: { P_QTY: 12 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Material created: Bolt 12", "Plant: 1000 PC", "Started by: ZR2C_06_DYNAMIC"]);

  // the expert checkbox shows the plant with its own F4
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_EXPERT: true }, event: "EXPERT" });
  assert.equal(s.fields.find((f) => f.name === "P_PLANT")?.value, "1000", "the plant MODE set");
  s = await d.act(s.session, { event: "CGUI_VALUE_REQUEST" });
  assert.equal(s.layer, "popup");
  // the F4 popup (z2ui5_cl_cgui_select, the runtime's own value selection) is a table of the snapshot
  let [f4] = s.tables;
  assert.equal(f4.control, "sap.m.TableSelectDialog");
  assert.deepEqual(rowsOf(f4), ["1000 Hamburg", "2000 Walldorf", "3000 Berlin"]);
  s = await d.act(s.session, { event: "CGUI_SEL_CANCEL" });
  assert.equal(s.layer, "main");
  assert.equal(s.fields.find((f) => f.name === "P_PLANT").value, "1000", "a cancel picks nothing");

  // search, then pick: the confirm with `row` selects the row as a click does
  s = await d.act(s.session, { event: "CGUI_VALUE_REQUEST" });
  s = await d.act(s.session, { event: "CGUI_SEL_SEARCH", args: ["Ber"] });
  [f4] = s.tables;
  assert.deepEqual(rowsOf(f4), ["3000 Berlin"]);
  s = await d.act(s.session, { event: "CGUI_SEL_CONFIRM", row: 0 });
  assert.equal(s.layer, "main");
  assert.equal(s.fields.find((f) => f.name === "P_PLANT").value, "3000", "the picked row's WERKS");

  // the push button
  s = await d.act(s.session, { event: "RESET" });
  assert.deepEqual(toasts(s), ["Selection screen reset"]);
  assert.equal(s.fields.find((f) => f.name === "P_NAME").value, "");
});

test("zr2c_07_messages: every form of MESSAGE", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_07");
  assert.deepEqual(fieldsOf(s), ['P_TYPE="S"*', "P_NUM=42"]);

  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  // MESSAGE s013 ... INTO with the class of MESSAGE-ID, then shown again through sy-msg*
  assert.deepEqual(toasts(s), ["A status message", "Number 42 processed"]);
  assert.deepEqual(d.lines(), ["Last message: Number 42 processed"]);

  const run = async (values) => {
    s = await d.act(s.session, { event: "CGUI_BACK" });
    s = await d.act(s.session, { values, event: "CGUI_EXECUTE" });
  };
  await run({ P_TYPE: "I" });
  assert.deepEqual(boxes(s), ["TEXT-001"], "no text pool: the placeholder the migration report names");
  await run({ P_TYPE: "W" });
  assert.deepEqual(popover(s), ["warning: Number 42 is a warning"]);
  await run({ P_TYPE: "E" });
  assert.deepEqual(popover(s), ["warning: Number 42 is not allowed"], "S DISPLAY LIKE E: a warning, the run goes on");
  assert.deepEqual(d.lines(), ["Last message: Number 42 processed"]);
  await run({ P_TYPE: "X" });
  assert.ok(s.fields.length, "E in AT SELECTION-SCREEN keeps the screen");
  assert.deepEqual(popover(s), ["error: Message type X is not S, I, W or E"]);
  s = await d.act(s.session, { values: { P_TYPE: "S", P_NUM: -1 }, event: "CGUI_EXECUTE" });
  assert.equal(popover(s).length, 1);
  assert.match(popover(s)[0], /^error: .*1.* is negative$/);
});

test("zr2c_08_listformat: FORMAT, AS CHECKBOX, AS ICON, HOTSPOT, HIDE, NEW-PAGE", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_08");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  // DD/MM/YYYY is not carried over (the migration report says so) - the list writes its default format
  assert.deepEqual(d.lines(), [
    `Tasks ${listDate(dateIn(0))}`,
    "---",
    "[x] <sap-icon://accept> 1 Write the report 01/10/2026",
    "[ ] <sap-icon://status-negative> 2 Convert the report 01/20/2026",
    "[ ] <sap-icon://status-negative> 3 Test the class 01/30/2026",
    "",
    "Open tasks: 2",
    "#",
    "Second page",
  ]);
  const clicks = actionsOf(s, "CGUI_LINE_SELECTION");
  assert.deepEqual(clicks.map((a) => a.label), ["Write the report", "Convert the report", "Test the class"]);
  s = await d.act(s.session, { event: clicks[1].id });
  assert.deepEqual(boxes(s), ["Task 2: Convert the report"]);

  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_PAGES: false }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().slice(-1), ["Open tasks: 2"], "no NEW-PAGE, and the open tasks are counted afresh");
});

test("zr2c_09_localclass: local classes and an interface in the class's local types", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_09");
  assert.deepEqual(s.fields.map((f) => f.name), ["P_A", "P_B", "P_DEC"]);
  // round( dec = 0 ): 1.005 + 2.5 = 3.505 -> 4, 1.005 -> 1
  s = await d.act(s.session, { values: { P_DEC: 0 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Sum: 4", "Rounded A: 1"]);
});

test("zr2c_09_localclass: round( dec = 2 )", {
  skip,
  todo: "the transpiled runtime has no round( ) with decimals (@abaplint/runtime: \"round(), todo, handle decimals\") - the report's own logic, not the conversion",
}, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_09");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Sum: 3.51", "Rounded A: 1.01"]);
});

test("zr2c_11_legacy: SELECT-OPTIONS DEFAULT, IN, WRITE TO, CONCATENATE, global field symbols", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_11");
  assert.deepEqual(fieldsOf(s), ['MT_CGUI_SO-0-LOW="1"', 'MT_CGUI_SO-0-HIGH="20"', 'P_TITLE="Numbers"']);
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const numbers = Array.from({ length: 20 }, (_, i) => String(i + 1));
  // P_TITLE has no LOWER CASE: the screen converts the input to upper case,
  // as the classic selection screen does on Execute
  assert.deepEqual(d.lines(), ["NUMBERS", ...numbers, "Sum: 210"]);
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().slice(-1), ["Sum: 210"], "the sum and the numbers start afresh");
});

test("zr2c_12_pages: LINE-COUNT, TOP-OF-PAGE with sy-pagno, END-OF-PAGE, NEW-PAGE NO-HEADING, ON BLOCK and ON RADIOBUTTON GROUP", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_12");
  assert.deepEqual(fieldsOf(s), ["P_LINES=7", 'MT_CGUI_SO-0-LOW=""', "P_LIST=true", "P_LAST=false"], "S_SKIP has NO INTERVALS");

  // LINE-COUNT 6(1): the runtime breaks after 6 lines of the list and
  // writes header and footer around them (the classic 6 counted the header
  // and the footer too - the migration report says so); the header is
  // repeated on the next page, sy-pagno is the number of the page it stands on
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), [
    "Numbers - page 1", "---", "1", "2", "3", "4", "5", "6", "continued",
    "#",
    "Numbers - page 2", "---", "7", "Count: 7", "continued",
  ]);

  // NEW-PAGE NO-HEADING: the last page has no header; END-OF-SELECTION
  // writes on it. The runtime ends the last page with the footer too - the
  // classic END-OF-PAGE ran only when a page was full (a TODO of the migration report)
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_LAST: true, P_LIST: false, P_LINES: 3 }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Numbers - page 1", "---", "1", "2", "3", "continued", "#", "Last page", "Count: 3", "continued"]);
  const clicks = actionsOf(s, "CGUI_LINE_SELECTION");
  assert.deepEqual(clicks.map((a) => a.label), ["1", "2", "3"]);

  // TOP-OF-PAGE DURING LINE-SELECTION heads the secondary list
  s = await d.act(s.session, { event: clicks[1].id });
  assert.deepEqual(d.lines(), ["Detail", "---", "Number 2"]);

  // ON BLOCK b1: the message marks the first field of the block
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_LINES: 30 }, event: "CGUI_EXECUTE" });
  assert.ok(s.fields.length, "still on the selection screen");
  assert.deepEqual(valueStates(s), ["error: At most 20 lines"]);
  // ON RADIOBUTTON GROUP mode: the message belongs to the first button of the group
  s = await d.act(s.session, { values: { P_LINES: 1 }, event: "CGUI_EXECUTE" });
  assert.ok(s.fields.length, "still on the selection screen");
  assert.deepEqual(popover(s), ["error: A last page needs two lines"]);
});

test("zr2c_22_files: GUI_UPLOAD of a path typed in - the upload dialog opens for it instead of a file error, Cancel goes back", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_22");
  s = await d.act(s.session, { values: { P_FILE: "C:\\data\\seats.txt" }, event: "CGUI_EXECUTE" });
  assert.equal(s.layer, "popup");
  assert.deepEqual(actionsOf(s, "CGUI_FILE_UPLOAD").map((a) => a.control), ["z2ui5.cc.FileUploader"]);
  assert.equal(actionsOf(s, "CGUI_FILE_CANCEL")[0].label, "seats.txt", "the dialog names the file");
  assert.deepEqual(popover(s), [], "no message that the file cannot be read");
  // the upload itself is no field of the app client (a custom control) -
  // the second run with the picked file is the unit test file_upload_and_download
  s = await d.act(s.session, { event: actionsOf(s, "CGUI_FILE_CANCEL").find((a) => a.control === "sap.m.Button").id });
  assert.deepEqual(fieldsOf(s), ['P_FILE="C:\\\\data\\\\seats.txt"*', "P_SAVE=false"]);
});

/** the content of the core:HTML controls of the main view */
const htmlOf = () => [...(d.state().slots.MAIN?.xml ?? "").matchAll(/<core:HTML[^>]*content="([^"]*)"/g)].map((m) => {
  // a binding {/MT_CGUI_GUI/1/HTML}: its value in the model of the view
  const path = /^\{\/(.*)\}$/.exec(m[1]);
  if (!path) return m[1];
  return String(path[1].split("/").reduce((o, k) => o?.[k], d.state().models.MAIN?.data) ?? "");
});
const guiAction = (s, label) => s.actions.find((a) => a.event === "CGUI_GUI" && a.label === label);

test("zr2c_28_browser: cl_abap_browser=>show_html( ) on cl_gui_container=>default_screen - the page above the list of the run", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_28");
  s = await d.act(s.session, { values: { P_DISC: 20 }, event: "CGUI_EXECUTE" });
  assert.equal(s.layer, "main");
  assert.equal((d.state().slots.MAIN.xml.match(/<core:HTML/g) ?? []).length, 1, "one document on the screen");
  assert.deepEqual(boxes(s), [], "no dialog box - the container is the screen");
});

test("zr2c_29_demooutput: cl_demo_output - sections, a text, the tables as columns, the value of display( )", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_29");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const lines = d.lines().filter((l) => l !== "");
  assert.deepEqual(lines, ["Inventory", "4 items, 173 pieces in stock", "Stock", "ITEM QUANTITY SHELF", "BOLT 120 A1", "NUT 3 A2", "WASHER 48 B1", "SCREW 2 B4",
    "To reorder", "Below the minimum", "ITEM QUANTITY SHELF", "NUT 3 A2", "SCREW 2 B4", "173"]);
});

test("zr2c_30_salvcolumns: a LOOP over get_columns( )->get( ) - every column header its name and its text", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_30");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.equal(s.tables.length, 1);
  // the components of a local type have no DDIC text - their text is their name
  assert.deepEqual(s.tables[0].columns.map((c) => c.label), ["STUDENT (STUDENT)", "SUBJECT (SUBJECT)", "POINTS (POINTS)", "PASSED (PASSED)"]);
  assert.equal(s.tables[0].rowCount, 3);
});

test("zr2c_31_toolbar: a toolbar and an HTML viewer on the screen - a static method of a local class handles the button", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_31");
  assert.match(htmlOf().join(), /Count: 0/);
  s = await d.act(s.session, { event: guiAction(s, "Up").id });
  s = await d.act(s.session, { event: guiAction(s, "Up").id });
  assert.match(htmlOf().join(), /Count: 2/, "the handler counted up twice");
  s = await d.act(s.session, { event: guiAction(s, "Down").id });
  assert.match(htmlOf().join(), /Count: 1/);
});

test("zr2c_32_xmlpopup: cl_abap_browser=>show_xml( ) without a container - a dialog box with the XML as text, Close ends it", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_32");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Order 4711 with 3 item(s) shown as XML"]);
  assert.match(htmlOf().join(), /&lt;order id=/, "the XML escaped in a pre");
  s = await d.act(s.session, { event: guiAction(s, "Close").id });
  assert.deepEqual(htmlOf(), [], "closed");
  assert.deepEqual(d.lines(), ["Order 4711 with 3 item(s) shown as XML"]);
});

test("zr2c_33_strings: SPLIT, CONCATENATE, REPLACE, TRANSLATE and the string functions", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_33");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Input: ada   augusta  lovelace", "Condensed: ada augusta lovelace", "Parts: 3", "---",
    "1 Ada 3", "2 Augusta 7", "3 Lovelace 8", "---", "Initials: A.A.L.", "Upper case: ADA AUGUSTA LOVELACE",
    "With dashes: ada-augusta-lovelace", "Vowels raised: AdA AUgUstA lOvElAcE", "Reversed: ecalevol atsugua ada"]);
});

test("zr2c_34_controllevels: AT FIRST, AT NEW, AT END OF and AT LAST over a sorted table", { skip }, async () => {
  await d.start("z2ui5_cl_cgui_r2c_34");
  assert.deepEqual(d.lines(), ["Sales per region", "---", "NORTH", "01 120.00", "01 30.00", "02 99.90", "Total 249.90", "",
    "SOUTH", "01 80.50", "02 150.00", "Total 230.50", "", "---", "All regions 480.40"]);
});

test("zr2c_35_dates: date arithmetic - days between, working days, first and last of the month, week days", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_35");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Days between start and end: 74", `After 10 working days: ${listDate("20260119")}`, "---",
    `First of the month: ${listDate("20260101")} Thursday`, `Last of the month: ${listDate("20260131")} Saturday`, `Start: ${listDate("20260105")} Monday`]);
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_END: "2026-01-01" }, event: "CGUI_EXECUTE" });
  assert.ok(s.fields.length, "the end before the start keeps the screen");
});

test("zr2c_36_ranges: IN on select-options over local data, DELETE ADJACENT DUPLICATES", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_36");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["3 product(s) in the selection", "---", "HOME CHAIR 120", "HOME LAMP 45", "OUT TENT 210"]);
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { values: { P_UNIQ: false }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["4 product(s) in the selection", "---", "HOME CHAIR 120", "HOME LAMP 45", "HOME LAMP 45", "OUT TENT 210"]);
});

test("zr2c_37_expressions: FILTER, REDUCE, VALUE FOR, COND, SWITCH, CORRESPONDING", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_37");
  s = await d.act(s.session, { values: { P_TEAM: "B" }, event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines(), ["Team B: 2 members, 13 goals", "---", "Noah 2 scorer Beta", "Finn 11 star Beta", "---", "More than five goals: Mia, Finn"]);
});

test("zr2c_38_confirm: POPUP_TO_CONFIRM in START-OF-SELECTION - the run goes on with the answer", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_38");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.equal(s.layer, "popup");
  s = await d.act(s.session, { event: actionsOf(s, "CGUI_POP_OPTION_1")[0].id });
  assert.deepEqual(d.lines(), ["The tasks that are done were deleted.", "---", "[ ] Test it"]);
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  s = await d.act(s.session, { event: actionsOf(s, "CGUI_POP_OPTION_2")[0].id });
  assert.deepEqual(d.lines(), ["Nothing was deleted.", "---", "[x] Write the report", "[ ] Test it", "[x] Ship it"]);
});

test("zr2c_39_textedit: a text editor and a toolbar on the screen - the handler of a local class reads the text", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_39");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  s = await d.act(s.session, { event: guiAction(s, "Count").id });
  assert.deepEqual(toasts(s), ["The note has 8 characters"]);
});

test("zr2c_40_sapevent: the SAPEVENT links of an HTML page reach the handler of a local class", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_40");
  assert.deepEqual(s.actions.filter((a) => a.control === "sap.m.Link").map((a) => a.label), ["Soup of the day", "Pasta"]);
  s = await d.act(s.session, { event: guiAction(s, "Pasta").id });
  assert.deepEqual(toasts(s), ["You picked PASTA"]);
});

test("zr2c_41_picture: DP_CREATE_URL of the bytes of a GIF, cl_gui_picture shows it - a click reaches the handler", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_41");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const xml = d.state().slots.MAIN.xml;
  const src = /<Image[^>]*src="\{\/(MT_CGUI_GUI\/[^}]*)\}"/.exec(xml);
  assert.ok(src, "an Image bound to the control");
  const url = src[1].split("/").reduce((o, k) => o?.[k], d.state().models.MAIN?.data);
  assert.equal(url, "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==");
  assert.match(xml, /<Image[^>]*width="100%"/, "fitted to the width");
  const click = s.actions.find((a) => a.event === "CGUI_GUI" && a.control === "sap.m.Image");
  s = await d.act(s.session, { event: click.id });
  s = await d.act(s.session, { event: click.id });
  assert.deepEqual(toasts(s), ["2 stamp(s)"]);
});

test("zr2c_42_demoget: cl_demo_output=>get( ) - the output as an HTML page for cl_abap_browser, not in the list", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_42");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().filter((l) => l.trim() !== ""), ["25 bottles in the cellar"]);
  const [page] = htmlOf();
  assert.match(page, /<pre>Cellar[\s\S]*Riesling[\s\S]*Rose/);
  assert.doesNotMatch(page, /Merlot/);
});

test("zr2c_43_base64: SCMS_* and SSFC_BASE64_ENCODE as methods of the frontend, a text editor created with NEW #( )", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_43");
  s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  assert.deepEqual(d.lines().filter((l) => l.trim() !== ""), ["15 bytes in 2 lines", "The bytes came back unchanged"]);
  const bound = /<TextArea[^>]*value="\{\/(MT_CGUI_GUI\/[^}]*)\}"/.exec(d.state().slots.MAIN.xml);
  assert.ok(bound, "a text area bound to the control");
  assert.equal(bound[1].split("/").reduce((o, k) => o?.[k], d.state().models.MAIN?.data), "U2VlIHlvdSBhdCBub29u");
});

test("zr2c_44_cursor: GET CURSOR FIELD VALUE LINE in AT LINE-SELECTION - the field written, its value and its line", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_44");
  if (!actionsOf(s, "CGUI_LINE_SELECTION").length) s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const clicks = actionsOf(s, "CGUI_LINE_SELECTION");
  assert.equal(clicks.length, 6, "a name and a height on each of three lines");
  s = await d.act(s.session, { event: clicks[2].id });
  // the line is the line of the list of the runtime - the classic counts its page header too
  assert.match(d.lines().filter((l) => l.trim() !== "").join("\n"), /^Line (\d+): GS_PEAK-NAME = Watzmann$/);
  const second = Number(/^Line (\d+)/.exec(d.lines().find((l) => l.startsWith("Line")))[1]);
  s = await d.act(s.session, { event: "CGUI_BACK" });
  s = await d.act(s.session, { event: actionsOf(s, "CGUI_LINE_SELECTION")[5].id });
  assert.deepEqual(d.lines().filter((l) => l.trim() !== ""), [`Line ${second + 1}: GS_PEAK-HEIGHT = 1493`]);
});

test("zr2c_45_salvlocal: a SALV kept by a local class - a function of its own over the rows selected, double click and link to the handlers, the statics kept", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_45");
  if (!s.tables.length) s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const [t] = s.tables;
  assert.ok(t, "the grid of the SALV");
  assert.match(t.label, /^Packing list/);
  assert.deepEqual(t.rows.map((r) => r.NAME), ["Tent", "Sleeping bag", "Stove"]);
  assert.ok(t.columns.some((c) => c.name === "WEIGHT" && /Weight \(g\)/.test(c.label)), t.columns.map((c) => c.label).join(" "));
  // the function added - a button that raises added_function
  assert.ok(actionsOf(s, "WEIGH").length >= 1, "a button WEIGH");
  // two rows selected, then the button: the handler reads them through get_selected_rows( )
  s = await d.act(s.session, { values: { [`${t.path}/0/ZZSELKZ`]: true, [`${t.path}/2/ZZSELKZ`]: true }, event: "WEIGH" });
  assert.deepEqual(toasts(s), ["2 item(s), 2750 g"]);
  // a double click on the second row - double_click with the row
  s = await d.act(s.session, { event: "CGUI_ALV_LINE_SELECTION", args: [`${t.path}/1`] });
  assert.deepEqual(toasts(s), ["Sleeping bag in row 2"]);
  // the item is a hotspot - link_click with row and column
  s = await d.act(s.session, { event: "CGUI_ALV_HOTSPOT", args: [`${t.path}/2`, "ITEM"] });
  assert.deepEqual(toasts(s), ["Item 003 (ITEM)"]);
});

test("zr2c_46_treelist: RS_TREE_CONSTRUCT and RS_TREE_LIST_DISPLAY - the nodes as the tree of the report, TLEVEL the hierarchy", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_46");
  if (!s.tables.length) s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const [t] = s.tables;
  assert.ok(t, "the tree");
  assert.equal(t.label, "Flights as a tree list");
  // the nodes in their order, LEVEL from TLEVEL - every node open
  const view = d.state().models.MAIN.data.MT_CGUI_TREE_VIEW;
  assert.deepEqual(view.map((n) => `${n.LEVEL} ${n.TEXT}`), [
    "0 Airlines",
    "1 LH Lufthansa",
    "2 0400 Frankfurt - New York",
    "2 0402 Frankfurt - New York",
    "1 AA American Airlines",
    "2 0017 New York - San Francisco",
  ]);
});

test("zr2c_47_salvtree: CL_SALV_TREE as the stand-in - the nodes below their related node, a sibling beside it, the header, a click to the handler", { skip }, async () => {
  let s = await d.start("z2ui5_cl_cgui_r2c_47");
  if (!s.tables.length) s = await d.act(s.session, { event: "CGUI_EXECUTE" });
  const [t] = s.tables;
  assert.ok(t, "the tree");
  assert.equal(t.label, "Seats per flight");
  const view = d.state().models.MAIN.data.MT_CGUI_TREE_VIEW;
  // American Airlines the next sibling of Lufthansa - a root as well
  assert.deepEqual(view.map((n) => `${n.LEVEL} ${n.TEXT}`), ["0 Lufthansa", "1 0400", "1 0402", "0 American Airlines", "1 0017"]);
  // the columns of the table: CARRID hidden, SEATS with its text
  assert.deepEqual(t.columns.map((c) => c.label), ["Airline", "CONNID", "Free seats"]);
  // a click on 0402 - double_click with its key, the handler reads its text
  s = await d.act(s.session, { event: "CGUI_TREE_NODE", args: [String(view[2].KEY)] });
  assert.deepEqual(toasts(s), ["0402 picked"]);
});
