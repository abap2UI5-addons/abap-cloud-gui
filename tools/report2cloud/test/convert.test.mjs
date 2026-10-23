// The conversion of the corpus: snapshots of every generated file and of
// the migration report, the abapGit format of the files, and the mapping
// table construct by construct. UPDATE_SNAPSHOTS=1 writes the snapshots
// anew - review the diff before committing it.
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { convert, defaultClassName, RESERVED_METHODS } from "../lib/convert.mjs";
import { corpus, convertEntry, SNAPSHOTS } from "./corpus.mjs";

const UPDATE = process.env.UPDATE_SNAPSHOTS === "1";
const entries = corpus();
const converted = new Map(entries.map((e) => [e.name, convertEntry(e)]));
const classOf = (name) => {
  const { result } = converted.get(name);
  return result.draft[`${result.className}.clas.abap`];
};

test("the corpus has ten reports and more", () => {
  assert.ok(entries.length >= 10, `${entries.length} reports in test/corpus`);
});

for (const e of entries) {
  test(`snapshot: ${e.name}`, () => {
    const { result, report } = converted.get(e.name);
    const dir = join(SNAPSHOTS, e.name);
    const actual = { ...result.files, [`${result.className}.migration.md`]: report };
    if (UPDATE) {
      rmSync(dir, { recursive: true, force: true });
      mkdirSync(dir, { recursive: true });
      for (const [name, text] of Object.entries(actual)) writeFileSync(join(dir, name), text);
      return;
    }
    assert.ok(existsSync(dir), `no snapshot for ${e.name} - run UPDATE_SNAPSHOTS=1 npm run test:report2cloud`);
    assert.deepEqual(readdirSync(dir).sort(), Object.keys(actual).sort(), "the generated files");
    for (const [name, text] of Object.entries(actual)) {
      assert.equal(text, readFileSync(join(dir, name), "utf8"), `${e.name}/${name} differs from its snapshot`);
    }
  });

  test(`deterministic: ${e.name}`, () => {
    const again = convertEntry(e);
    assert.deepEqual(again.result.draft, converted.get(e.name).result.draft);
    assert.equal(again.report, converted.get(e.name).report);
  });

  test(`abapGit format: ${e.name}`, () => {
    const { result } = converted.get(e.name);
    for (const [name, text] of Object.entries(result.draft)) {
      if (name.endsWith(".xml")) {
        assert.ok(text.startsWith("﻿<?xml"), `${name}: the sidecar starts with the BOM`);
        assert.match(text, new RegExp(`<CLSNAME>${result.className.toUpperCase()}</CLSNAME>`));
        assert.ok(!/'/.test(text), `${name}: an apostrophe is written as &apos;`);
      } else {
        assert.ok(!text.startsWith("﻿"), `${name}: no BOM in ABAP source`);
      }
      assert.ok(!text.includes("\r"), `${name}: LF only`);
      assert.ok(!text.includes("\t"), `${name}: no tabs`);
      assert.ok(text.endsWith("\n") && !text.endsWith("\n\n"), `${name}: exactly one newline at the end`);
      text.split("\n").forEach((line, i) => {
        assert.ok(!/\s$/.test(line), `${name}:${i + 1}: trailing blank`);
        assert.ok(line.length <= 255, `${name}:${i + 1}: ${line.length} characters`);
      });
    }
  });
}

// ------------------------------------------------------------- mapping table

test("PARAMETERS: type, DEFAULT, OBLIGATORY, LOWER CASE, selection texts", () => {
  const abap = classOf("zr2c_01_hello");
  assert.match(abap, /DATA p_name {2}TYPE string\./);
  assert.match(abap, /p_times = 3\./);
  assert.match(abap, /screen->parameter\( val {8}= p_name\n {23}text {7}= `Your name`\n {23}obligatory = abap_true/);
  assert.match(abap, /set_title\( `Hello World` \)\./);
});

test("SELECT-OPTIONS FOR a TABLES field: range attribute, the TABLES work area dropped", () => {
  const { result } = converted.get("zr2c_02_flights");
  const abap = classOf("zr2c_02_flights");
  assert.match(abap, /DATA s_fldate TYPE RANGE OF sflight-fldate\./);
  assert.match(abap, /DATA p_carrid TYPE sflight-carrid\./, "LIKE a field of the dropped TABLES becomes TYPE");
  assert.ok(!/DATA sflight /.test(abap));
  assert.ok(result.mapped.some((m) => /^TABLES sflight/.test(m.classic) && /dropped/.test(m.target)));
});

test("the header line of a select-option becomes a work area", () => {
  const abap = classOf("zr2c_02_flights");
  assert.match(abap, /DATA ls_s_fldate LIKE LINE OF s_fldate\./);
  assert.match(abap, /ls_s_fldate-sign {3}= 'I'\./);
  assert.match(abap, /APPEND ls_s_fldate TO s_fldate\./);
});

test("BEGIN OF BLOCK WITH FRAME TITLE TEXT-001: the text of the text pool", () => {
  assert.match(classOf("zr2c_02_flights"), /screen->block_begin\( `Flights`/);
});

test("TOP-OF-PAGE, END-OF-SELECTION, HIDE and AT LINE-SELECTION", () => {
  const abap = classOf("zr2c_02_flights");
  assert.match(abap, /METHOD start_of_selection\.\n\n {4}" every run starts [^\n]*\n {4}CLEAR: gt_flight,\n {11}gs_flight,\n {11}gv_total\.\n\n {4}SELECT /);
  assert.match(abap, /METHODS top_of_page REDEFINITION\./);
  // END-OF-SELECTION is the event of the runtime, which runs it after the
  // RETURN of START-OF-SELECTION as well
  assert.match(abap, /PROTECTED SECTION\.[\s\S]*METHODS end_of_selection REDEFINITION\.[\s\S]*PRIVATE SECTION/);
  assert.match(abap, /message\( lv_message \)\.\n {6}RETURN\./);
  assert.doesNotMatch(abap, /end_of_selection\( \)/);
  assert.match(abap, /METHOD end_of_selection\.\n\n {4}list\( \)->skip\( \)\./);
  assert.match(abap, /hide {4}= \|\{ gs_flight-carrid \}\\t\{ gs_flight-connid \}\\t\{ gs_flight-fldate \}\|/);
  assert.match(abap, /SPLIT hide AT \|\\t\| INTO TABLE DATA\(lt_hide\)\.\n {4}gs_flight-carrid = VALUE #\( lt_hide\[ 1 \] OPTIONAL \)\./);
});

test("ABAP SQL in strict mode: host variables escaped, the lists separated", () => {
  const abap = classOf("zr2c_02_flights");
  assert.match(abap, /SELECT carrid, connid, fldate, price, currency, seatsmax, seatsocc/);
  assert.match(abap, /INTO TABLE @gt_flight\n {6}UP TO @p_max ROWS\n {6}WHERE carrid = @p_carrid\n {8}AND fldate IN @s_fldate\./);
  assert.match(classOf("zr2c_04_salv"), /ORDER BY carrid, connid\./, "ORDER BY is a list as well");
});

test("MESSAGE: literal, text symbol, message class short and long form, DISPLAY LIKE, sy-msgty", () => {
  const abap = classOf("zr2c_07_messages");
  assert.match(abap, /MESSAGE e010\(zr2c\) WITH p_type INTO DATA\(lv_message\)\.\n {6}message\( text = lv_message\n {15}type = `E` \)\.\n {6}RETURN\./);
  assert.match(abap, /MESSAGE ID 'ZR2C' TYPE 'E' NUMBER '011' WITH p_num 'is negative' INTO lv_message\./);
  assert.match(abap, /message\( 'A status message' \)\./);
  assert.match(abap, /message\( text = gv_text\n {17}type = `W` \)\./, "S DISPLAY LIKE E is a warning");
  assert.match(abap, /MESSAGE s013\(zr2c\) WITH p_num INTO gv_text\./, "MESSAGE ... INTO stays, with the class of MESSAGE-ID");
  assert.match(abap, /type = sy-msgty \)\./);
  const { result } = converted.get("zr2c_07_messages");
  assert.ok(result.todos.some((t) => /TEXT-001 is not in the text pool/.test(t.message)));
  assert.ok(result.release.some((r) => r.kind === "message class" && r.name === "ZR2C"));
});

test("FORM / PERFORM: USING, CHANGING, TABLES STRUCTURE, VALUE( ), RANGES", () => {
  const abap = classOf("zr2c_03_forms");
  assert.match(abap, /METHODS build_items\n {6}IMPORTING\n {8}VALUE\(iv_count\) TYPE i\n {6}CHANGING\n {8}ct_items TYPE ty_items\./);
  assert.match(abap, /TYPES ty_t_gs_template LIKE STANDARD TABLE OF gs_template WITH DEFAULT KEY\./);
  assert.match(abap, /total\( EXPORTING\n {13}iv_discount = p_disc\n {11}CHANGING\n {13}it_items {4}= gt_items\n {13}cv_net {6}= gv_net \)\./);
  assert.match(abap, /write_item\( ls_item \)\./);
  assert.match(abap, /output\( \)\./);
  assert.match(abap, /DATA lr_big LIKE RANGE OF ls_item-quantity\./);
});

test("AT SELECTION-SCREEN ON field: CASE field, an E message returns", () => {
  assert.match(classOf("zr2c_03_forms"), /CASE field\.\n {6}WHEN `P_ITEMS`\./);
});

test("CL_SALV_TABLE: one alv( ) chain with title, column texts, hidden columns; TRY/CATCH cx_salv_* gone", () => {
  const abap = classOf("zr2c_04_salv");
  assert.match(abap, /alv\( gt_spfli\n {8}\)->set_title\( 'Flight connections'\n {8}\)->set_column_text\( name = `CITYFROM`\n {28}text = 'Departure city'\n {8}\)->set_column_hidden\( `MANDT`\n {8}\)->set_column_hidden\( `FLTIME` \)\./);
  assert.ok(!/salv/i.test(abap.replace(/report2cloud/g, "")), "no CL_SALV_* left");
  assert.ok(!/TRY\./.test(abap));
});

test("REUSE_ALV_GRID_DISPLAY: field catalog, title, USER_COMMAND callback as at_line_selection", () => {
  const abap = classOf("zr2c_05_reuse");
  assert.match(abap, /alv\( gt_scarr\n {8}\)->set_title\( 'Airlines'/);
  assert.match(abap, /set_column_text\( name = `CURRCODE`\n {28}text = 'Currency'/, "APPEND VALUE #( ) to the field catalog");
  assert.match(abap, /set_column_hidden\( `MANDT`/);
  assert.match(abap, /\)->set_line_selection\( \)\./);
  assert.match(abap, /METHOD at_line_selection\.[\s\S]*READ TABLE gt_scarr INTO gs_scarr INDEX row\./);
  assert.ok(!/slis_|fieldcat|build_fieldcat|sy-subrc <> 0/.test(abap), "field catalog, layout and the EXCEPTIONS check are gone");
});

test("dynamic selection screen: MODIF ID, USER-COMMAND, LOOP AT SCREEN, push button, F4", () => {
  const abap = classOf("zr2c_06_dynamic");
  assert.match(abap, /radiobutton\( val {10}= p_disp\n {24}text {9}= `Display material`\n {24}group {8}= `MODE`\n {24}user_command = `MODE`/);
  assert.match(abap, /checkbox\( val {10}= p_expert\n {21}text {9}= `Expert settings`\n {21}user_command = `EXPERT`/);
  assert.match(abap, /DATA\(lt_screen\) = screen->loop_at_screen\( \)\.\n {4}LOOP AT lt_screen INTO DATA\(ls_screen\)\./);
  assert.match(abap, /ls_screen-active = abap_false\./);
  assert.match(abap, /ls_screen-required = abap_true\./);
  assert.match(abap, /screen->modify_screen\( ls_screen \)\./);
  assert.match(abap, /\)->button\( text {2}= b_reset\n {19}event = `RESET`/);
  assert.match(abap, /parameter\( val        = p_plant\n {22}text       = `Plant`\n {22}value_help = abap_true/);
  assert.match(abap, /value_help_popup\( tab = gt_plant\n {26}col = `WERKS` \)\./);
  assert.match(abap, /METHOD at_user_command\.[\s\S]*at_selection_screen_ucomm\( ucomm \)\./);
  assert.match(abap, /METHOD at_selection_screen\.[\s\S]*at_selection_screen_ucomm\( `ONLI` \)\./);
  assert.match(abap, /METHOD at_selection_screen_ucomm\.\n\n {4}CASE ucomm\./, "sscrfields-ucomm became ucomm");
  assert.match(abap, /CLEAR: p_matnr, p_name, p_qty, p_plant, p_token\./);
});

test("list: FORMAT in a branch is a runtime color, AS CHECKBOX, AS ICON, NEW-PAGE, SKIP n", () => {
  const abap = classOf("zr2c_08_listformat");
  assert.match(abap, /DATA lv_color TYPE string\./);
  assert.match(abap, /lv_color = z2ui5_cl_cgui_list=>cs_color-positive\./);
  assert.match(abap, /list\( \)->write_as_checkbox\( gs_task-done \)\./);
  assert.match(abap, /list\( \)->write_as_icon\( `sap-icon:\/\/accept` \)\./);
  assert.match(abap, /list\( \)->new_page\( \)\./);
  assert.match(abap, /list\( \)->skip\( 2 \)\./);
  assert.match(abap, /color = z2ui5_cl_cgui_list=>cs_color-total/, "an explicit COLOR 3 wins over FORMAT");
});

test("local classes and interfaces: locals_def when the class is typed with them", () => {
  const { result } = converted.get("zr2c_09_localclass");
  assert.match(result.files["z2ui5_cl_cgui_r2c_09.clas.locals_def.abap"], /^INTERFACE lif_rounding\./);
  assert.match(result.files["z2ui5_cl_cgui_r2c_09.clas.locals_imp.abap"], /^CLASS lcl_calculator IMPLEMENTATION\./);
  assert.match(classOf("zr2c_09_localclass"), /DATA go_calc TYPE REF TO lif_rounding\./);
});

test("legacy statements: WRITE TO, global field symbols, SET PF-STATUS, AT USER-COMMAND", () => {
  const { result } = converted.get("zr2c_11_legacy");
  const abap = classOf("zr2c_11_legacy");
  assert.match(abap, /gv_text = \|\{ p_title \}\|\./);
  assert.match(abap, /METHOD start_of_selection\.\n\n {4}FIELD-SYMBOLS <gv_number> TYPE i\./);
  assert.match(abap, /s_range = VALUE #\( \( sign = `I` option = `BT` low = 1 high = 20 \) \)\./);
  assert.match(abap, /CASE ucomm\.\n {6}WHEN 'BACK'\.\n {8}leave_to_selection_screen\( \)\./);
  assert.ok(result.todos.some((t) => /SET PF-STATUS/.test(t.message)));
  assert.ok(!/PF-STATUS/.test(abap));
});

test("refusals: every statement without a counterpart, with file, row and column", () => {
  const { result } = converted.get("zr2c_10_refused");
  assert.equal(result.ok, false);
  assert.deepEqual(result.files, {}, "no class is written");
  assert.deepEqual(result.refusals.map((r) => `${r.row}:${r.col} ${r.message.split(" - ")[0]}`), [
    "26:3 ASSIGN of a field of another program ('(PROG)FIELD')",
    "28:3 CALL TRANSACTION",
    "32:3 EXEC SQL",
    "36:3 CALL SCREEN",
    "38:1 MODULE",
    "42:1 MODULE",
  ]);
  assert.match(result.draft["z2ui5_cl_cgui_r2c_10.clas.abap"], /" report2cloud refused \(line 36\): CALL SCREEN 100/);
});

test("SUBMIT ... AND RETURN starts the class of the called report with the values, CALL SELECTION-SCREEN goes on in after_call_selection_screen( )", () => {
  const cls = classOf("zr2c_15_submit");
  assert.match(cls, /DATA lt_r2c_submit_1 TYPE z2ui5_cl_cgui_variant=>ty_t_value\.\n\s+DATA lt_r2c_lines_1 TYPE z2ui5_cl_cgui_variant=>ty_t_value\.\n\s+CLEAR lt_r2c_submit_1\.\n\s+INSERT VALUE #\( name = `P_CARRID` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = p_carrid \) INTO TABLE lt_r2c_submit_1\.\n\s+lt_r2c_lines_1 = z2ui5_cl_cgui_variant=>range_lines_get\( name = `S_FLDATE` range = s_fldate \)\.\n\s+APPEND LINES OF lt_r2c_lines_1 TO lt_r2c_submit_1\.\n\s+INSERT VALUE #\( name = `P_MAX` kind = z2ui5_cl_cgui_variant=>cs_kind-select_option sign = 'E' option = `NE` low = p_max \) INTO TABLE lt_r2c_submit_1\.\n\s+submit\( report = `Z2UI5_CL_CGUI_R2C_02`\n\s+values = lt_r2c_submit_1 \)\./);
  assert.match(cls, /lt_r2c_lines_2 = z2ui5_cl_cgui_variant=>selection_table_get\( gt_rspar \)\.\n\s+APPEND LINES OF lt_r2c_lines_2 TO lt_r2c_submit_2\.\n\s+submit\( report\s+= `Z2UI5_CL_CGUI_R2C_01`\n\s+values\s+= lt_r2c_submit_2\n\s+via_selection_screen = abap_true\n\s+using_variant\s+= 'DEFAULT' \)\./);
  // without AND RETURN the classic ended the caller
  assert.match(cls, /submit\( report = `Z2UI5_CL_CGUI_R2C_01`\n\s+values = VALUE #\( \( name = `P_NAME` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = 'Bye' \) \) \)\.\n\s+RETURN\./);
  // the screen of its own, and the dialog
  assert.match(cls, /METHOD selection_screen_dynnr\.\n\n\s+CASE dynnr\.\n\s+WHEN `0100`\.\n\s+screen->parameter\( val\s+= p_seats\n\s+text\s+= `Seats`\n\s+obligatory = abap_true \)\.\n\s+ENDCASE\./);
  assert.match(cls, /WHEN 'BOOK'\.\n\s+call_selection_screen\( dynnr = `0100`\n\s+title = `Booking` \)\.\n\s+WHEN 'HELLO'\./);
  assert.match(cls, /METHOD after_call_selection_screen\.\n\n\s+CASE dynnr\.\n\s+WHEN `0100`\.\n\s+IF subrc = 0\.\n\s+gv_seats = p_seats\./);
  assert.ok(!/sy-subrc/.test(cls));
});

test("SUBMIT: a report that is not part of the input, a dynamic name, the forms without a counterpart", () => {
  const src = (stmt) => `REPORT zt.\nDATA gv TYPE string.\nDATA gt TYPE STANDARD TABLE OF string WITH DEFAULT KEY.\nSTART-OF-SELECTION.\n  ${stmt}\n`;
  const r = convert(src("SUBMIT zother WITH p_a = 'X' AND RETURN."), { file: "zt.prog.abap", className: "zcl_t" });
  assert.match(r.draft["zcl_t.clas.abap"], /submit\( report = `ZCL_OTHER`/);
  assert.ok(r.todos.some((t) => /SUBMIT ZOTHER: the report is not part of the input/.test(t.message)));
  const d = convert(src("SUBMIT (gv) AND RETURN."), { file: "zt.prog.abap", className: "zcl_t" });
  assert.match(d.draft["zcl_t.clas.abap"], /submit\( report = gv \)\./);
  assert.ok(d.todos.some((t) => /SUBMIT \(name\)/.test(t.message)));
  assert.deepEqual(refusalOf(src("SUBMIT zother EXPORTING LIST TO MEMORY AND RETURN.")).map((x) => x.split(" - ")[0]), ["5:3 SUBMIT ... EXPORTING LIST TO MEMORY"]);
  assert.deepEqual(refusalOf(src("SUBMIT zother VIA JOB 'X' NUMBER gv AND RETURN.")).map((x) => x.split(" - ")[0]), ["5:3 SUBMIT ... VIA JOB"]);
  assert.deepEqual(refusalOf(src("CALL SELECTION-SCREEN 200.")).map((x) => x.split(" - ")[0]), ["5:3 CALL SELECTION-SCREEN 0200"]);
});

// --------------------------------------------------- refusals, one at a time

const refusalOf = (source) => convert(source, { file: "zt.prog.abap", className: "zcl_t" }).refusals.map((r) => `${r.row}:${r.col} ${r.message}`);

test("refused: MESSAGE of a message class without MESSAGE-ID", () => {
  assert.match(refusalOf("REPORT zt.\nSTART-OF-SELECTION.\n  MESSAGE e001.\n")[0], /^3:3 MESSAGE without a message class/);
});

test("refused: LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT", () => {
  assert.match(refusalOf("REPORT zt.\nPARAMETERS p TYPE i.\nAT SELECTION-SCREEN.\n  LOOP AT SCREEN.\n  ENDLOOP.\n")[0], /^4:3 LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT/);
});

test("a TABLES parameter used with its header line gets a work area of the method", () => {
  const r = convert("REPORT zt.\nDATA gt TYPE STANDARD TABLE OF i.\nSTART-OF-SELECTION.\n  PERFORM f TABLES gt.\nFORM f TABLES tt STRUCTURE gt.\n  LOOP AT tt.\n    WRITE tt.\n  ENDLOOP.\n  CLEAR tt.\n  tt = 7.\n  APPEND tt.\nENDFORM.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.draft["zcl_t.clas.abap"];
  assert.match(cls, /DATA ls_tt LIKE LINE OF tt\./);
  assert.match(cls, /LOOP AT tt INTO ls_tt\./);
  assert.match(cls, /write\( ls_tt \)/);
  assert.match(cls, /CLEAR ls_tt\./);
  assert.match(cls, /ls_tt = 7\./);
  assert.match(cls, /APPEND ls_tt TO tt\./);
});

test("refused: GUI_DOWNLOAD, PERFORM IN PROGRAM - a table with a header line, a popup and a function key no longer", () => {
  const r = refusalOf([
    "REPORT zt.",
    "DATA gt TYPE i OCCURS 0.",
    "SELECTION-SCREEN FUNCTION KEY 1.",
    "START-OF-SELECTION.",
    "  CALL FUNCTION 'GUI_DOWNLOAD' EXPORTING filename = 'x'.",
    "  PERFORM x IN PROGRAM zother.",
  ].join("\n"));
  assert.deepEqual(r.map((x) => x.split(" - ")[0]), [
    "5:3 CALL FUNCTION 'GUI_DOWNLOAD'",
    "6:3 PERFORM of a FORM of another program, dynamic or ON COMMIT",
  ]);
});

test("the selection screen of a grown report: tabs on subscreens, function keys with text and icon, an own F1", () => {
  const cls = classOf("zr2c_20_tabs");
  const { result } = converted.get("zr2c_20_tabs");
  assert.equal(result.ok, true, result.refusals.map((x) => x.message).join("\n"));
  assert.match(cls, /screen->function_key\( number = 1\n\s+text   = 'Today'\n\s+\)->function_key\( number = 2\n\s+text   = 'Reset'\n\s+icon   = `sap-icon:\/\/refresh`/);
  assert.match(cls, /\)->tabbed_block_begin\(\n\s+\)->tab\( tab_main\n\s+\)->parameter\( val  = p_carrid\n(.*\n)*?\s+\)->tab\( tab_opt\n\s+\)->parameter\( val          = p_max\n\s+text         = `Maximum flights`\n\s+help_request = abap_true\n(.*\n)*?\s+\)->tabbed_block_end\( \)\./);
  assert.match(cls, /DATA tab_main TYPE c LENGTH 20\./);
  assert.match(cls, /tab_main = 'Flights'\./);
  assert.match(cls, /METHOD at_selection_screen_on_help\.\n\n\s+CASE field\.\n\s+WHEN `P_MAX`\.\n(.*\n)*?\s+WHEN OTHERS\.\n\s+super->at_selection_screen_on_help\( field \)\./);
  // FC01 / FC02 arrive as user commands, AT SELECTION-SCREEN reads them as ucomm
  assert.match(cls, /at_selection_screen_ucomm\( ucomm \)\./);
  assert.match(cls, /WHEN 'FC02'\./);
  assert.ok(!/sscrfields|smp_dyntxt|ls_text|tabs-activetab/i.test(cls));
  assert.ok(result.todos.some((t) => /tabs-activetab/.test(t.message)));
});

test("a tab without DEFAULT SCREEN, a subscreen on no tab, a FUNCTION KEY without text", () => {
  const r = convert([
    "REPORT zt.",
    "SELECTION-SCREEN FUNCTION KEY 3.",
    "SELECTION-SCREEN BEGIN OF TABBED BLOCK tb FOR 5 LINES.",
    "SELECTION-SCREEN TAB (10) t1 USER-COMMAND u1.",
    "SELECTION-SCREEN END OF BLOCK tb.",
    "SELECTION-SCREEN BEGIN OF SCREEN 300 AS SUBSCREEN.",
    "PARAMETERS p_x TYPE i.",
    "SELECTION-SCREEN END OF SCREEN 300.",
  ].join("\n"), { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message.split(" - ")[0]), ["SELECTION-SCREEN TAB t1 without DEFAULT SCREEN"]);
  assert.ok(r.todos.some((t) => /FUNCTION KEY 3: no sscrfields-functxt_03/.test(t.message)));
  assert.ok(r.todos.some((t) => /subscreen 0300 is on no tab/.test(t.message)));
});

test("the synchronous popups: popup_to_decide( ) / popup_get_values_sval( ), the block cut at the call and continued in at_user_command( )", () => {
  const cls = classOf("zr2c_16_popups");
  const { result } = converted.get("zr2c_16_popups");
  assert.equal(result.ok, true);
  // POPUP_TO_DECIDE in AT LINE-SELECTION: the two lines joined, the options, the CASE on the answer continued
  assert.match(cls, /METHOD at_line_selection\.\n\n(.*\n)*?\s+popup_to_decide\( question = 'Book the flight' && ` ` && gs_flight-connid\n\s+options  = VALUE #\( \( `Book now` \) \( `Waiting list` \) \)\n\s+ucomm    = `POPUP_1`\n\s+title    = 'Booking' \)\.\n\n\s+ENDMETHOD\./);
  assert.match(cls, /WHEN `POPUP_1`\.\n\s+lv_answer = popup_answer\( \)\.\n\s+CASE lv_answer\.\n\s+WHEN '1'\.\n\s+book\( gs_flight \)\./);
  // POPUP_TO_CONFIRM inside a WHEN: the branch continued, the IF sy-subrc of the EXCEPTIONS dropped, the other WHEN kept
  assert.match(cls, /WHEN 'CANCEL'\.\n\s+popup_to_decide\( question = 'Cancel all bookings of this run\?'\n\s+options  = VALUE #\( \( `Cancel them` \) \( `Keep them` \) \)\n\s+ucomm    = `POPUP_2`\n\s+title    = 'Cancel bookings' \)\.\n\s+WHEN 'PASSENGER'\./);
  assert.match(cls, /WHEN `POPUP_2`\.\n\s+gv_answer = popup_answer\( \)\.\n\s+IF gv_answer = '1'\./);
  assert.ok(!/sy-subrc/.test(cls));
  assert.ok(!/could not be shown/.test(cls));
  // POPUP_GET_VALUES in a FORM: converted, not cut - a TODO
  assert.match(cls, /popup_get_values_sval\( sval  = lt_fields\n\s+ucomm = `POPUP_3`\n\s+title = 'Passenger' \)\./);
  assert.ok(result.todos.some((t) => /POPUP_GET_VALUES' in FORM passenger/.test(t.message)));
  assert.ok(result.mapped.some((m) => /dropped - the IF sy-subrc after POPUP_TO_CONFIRM/.test(m.target)));
});

test("a popup at the top of an event block: the answer and the SVAL values first, a local declared inline gets a TODO", () => {
  const r = convert([
    "REPORT zt.",
    "TYPES: BEGIN OF ty_sval, fieldname TYPE c LENGTH 30, value TYPE c LENGTH 132, END OF ty_sval.",
    "DATA lt_fields TYPE STANDARD TABLE OF ty_sval WITH DEFAULT KEY.",
    "DATA lv_rc TYPE c LENGTH 1.",
    "START-OF-SELECTION.",
    "  DATA(lv_n) = 1.",
    "  CALL FUNCTION 'POPUP_GET_VALUES' EXPORTING popup_title = 'T' IMPORTING returncode = lv_rc TABLES fields = lt_fields.",
    "  IF lv_rc = 'A'.",
    "    RETURN.",
    "  ENDIF.",
    "  WRITE: / lt_fields[ 1 ]-value, lv_n.",
    "  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP' EXPORTING textline1 = 'Go on?' titel = 'T' IMPORTING answer = lv_rc.",
    "  IF lv_rc = 'J'.",
    "    WRITE 'yes'.",
    "  ENDIF.",
  ].join("\n"), { file: "zt.prog.abap", className: "zcl_t" });
  const cls = r.draft["zcl_t.clas.abap"];
  assert.match(cls, /WHEN `POPUP_1`\.\n\s+lv_rc = SWITCH #\( popup_answer\( \) WHEN 'A' THEN 'A' ELSE space \)\.\n\s+popup_values_sval\( CHANGING sval = lt_fields \)\.\n\s+IF lv_rc = 'A'\./);
  // the second popup is cut out of the first continuation
  assert.match(cls, /WHEN `POPUP_2`\.\n\s+lv_rc = SWITCH #\( popup_answer\( \) WHEN '1' THEN 'J' WHEN '2' THEN 'N' ELSE 'A' \)\.\n\s+IF lv_rc = 'J'\./);
  assert.ok(r.todos.some((t) => /lv_n was declared inline before the call/.test(t.message)));
});

// ------------------------------------------------------- cl_gui_alv_grid

test("cl_gui_alv_grid on a screen: alv( ) with the field catalog, the handlers as methods, the PAI module as at_user_command( )", () => {
  const cls = classOf("zr2c_19_grid");
  const { result } = converted.get("zr2c_19_grid");
  assert.equal(result.ok, true, result.refusals.map((r) => r.message).join("\n"));
  assert.ok(!/cl_gui_|TYPE REF TO lcl_handler|go_grid|go_cont|ok_code|save_ok|\blvc_[ts]_/i.test(cls), "no grid, container, handler, OK code or LVC type is left");
  assert.equal(result.draft["z2ui5_cl_cgui_r2c_19.clas.locals_imp.abap"], undefined, "the handler class is gone");
  // the PBO module in place of CALL SCREEN, the chain from the field catalog, the layout and the toolbar handler
  assert.match(cls, /ORDER BY PRIMARY KEY\.\n\n\s+set_pf_status\( functions = VALUE #\( \( name = `REFRESH`/);
  assert.match(cls, /alv\( gt_flight\n\s+\)->set_title\( 'Flights'\n\s+\)->set_column_text\( name = `CONNID`\n\s+text = 'Flight'/);
  assert.match(cls, /\)->set_column_hidden\( `MANDT`\n\s+\)->set_column_hotspot\( `CONNID`\n\s+\)->set_column_sum\( `SEATSOCC`\n\s+\)->add_function\( name    = `FULL`\n\s+text    = 'Full flights'\n\s+icon    = `sap-icon:\/\/accept`\n\s+tooltip = 'Count the full flights'\n\s+\)->add_function\( name = `ALL`\n\s+text = 'All flights'\n\s+\)->set_line_selection\( \)\./);
  // the handlers
  assert.match(cls, /METHOD at_line_selection\.\n\n\s+" the DOUBLE_CLICK handler of the grid - lcl_handler->on_double_click\n\s+READ TABLE gt_flight INDEX row INTO gs_flight\./);
  assert.match(cls, /METHOD at_link_click\.\n\n(.*\n)*?\s+IF column = 'CONNID'\./);
  // the PAI module: the OK code is ucomm, LEAVE TO SCREEN 0 the selection screen; then the USER_COMMAND handler
  assert.match(cls, /" the PAI module of the screen - the OK code is ucomm\n\s+CASE ucomm\.\n\s+WHEN 'BACK' OR 'EXIT' OR 'CANCEL'\.\n\s+leave_to_selection_screen\( \)\./);
  assert.equal(result.todos.length, 0, result.todos.map((t) => t.message).join("\n"));
});

test("cl_gui_alv_grid: get_selected_rows( ) - the selection column, LVC_T_ROW the row type of the runtime", () => {
  const r = convert([
    "REPORT zt.",
    "DATA gt TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
    "DATA gt_rows TYPE lvc_t_row.",
    "DATA gt_ids TYPE lvc_t_roid.",
    "DATA go_grid TYPE REF TO cl_gui_alv_grid.",
    "START-OF-SELECTION.",
    "  CREATE OBJECT go_grid EXPORTING i_parent = cl_gui_container=>default_screen.",
    "  go_grid->set_table_for_first_display( CHANGING it_outtab = gt ).",
    "  go_grid->get_selected_rows( IMPORTING et_index_rows = gt_rows et_row_no = gt_ids ).",
  ].join("\n"), { file: "zt.prog.abap", className: "zcl_t" });
  const cls = r.draft["zcl_t.clas.abap"];
  assert.equal(r.ok, true, r.refusals.map((x) => x.message).join("\n"));
  assert.match(cls, /gt_rows TYPE z2ui5_cl_cgui_alv=>ty_t_lvc_row/);
  assert.match(cls, /gt_ids\s+TYPE z2ui5_cl_cgui_alv=>ty_t_lvc_roid/);
  assert.match(cls, /alv\( gt\n\s+\)->set_selection_mode\( \)\./);
  assert.match(cls, /gt_rows = VALUE #\( FOR lv_r2c_row IN get_selected_rows\( \) \( index = lv_r2c_row \) \)\.\n\s+gt_ids = VALUE #\( FOR lv_r2c_row IN get_selected_rows\( \) \( row_id = lv_r2c_row \) \)\./);
  assert.ok(!/go_grid|cl_gui_/.test(cls));
});

test("cl_gui_alv_grid: what has no counterpart is refused", () => {
  const head = [
    "REPORT zt.",
    "DATA gt TYPE STANDARD TABLE OF i WITH DEFAULT KEY.",
    "DATA go_grid TYPE REF TO cl_gui_alv_grid.",
  ];
  const r = refusalOf([...head,
    "CLASS lcl_h DEFINITION.",
    "  PUBLIC SECTION.",
    "    METHODS on_changed FOR EVENT data_changed OF cl_gui_alv_grid IMPORTING er_data_changed.",
    "ENDCLASS.",
    "CLASS lcl_h IMPLEMENTATION.",
    "  METHOD on_changed.",
    "  ENDMETHOD.",
    "ENDCLASS.",
    "START-OF-SELECTION.",
    "  CREATE OBJECT go_grid EXPORTING i_parent = cl_gui_container=>default_screen.",
    "  go_grid->set_table_for_first_display( CHANGING it_outtab = gt ).",
    "  go_grid->set_drop_down_table( it_drop_down = gt ).",
    "  WRITE space.",
  ].join("\n")).map((x) => x.split(" - ")[0]);
  assert.deepEqual(r, ["6:5 the DATA_CHANGED handler of the grid", "15:3 set_drop_down_table( ) of cl_gui_alv_grid"]);
  // two screens: the modules stay refused
  const two = refusalOf([...head, "START-OF-SELECTION.", "  CALL SCREEN 100.", "  CALL SCREEN 200.", "MODULE pbo OUTPUT.", "ENDMODULE."].join("\n"));
  assert.ok(two.some((x) => /MODULE - the report calls more than one screen/.test(x)));
  assert.ok(two.some((x) => /CALL SCREEN/.test(x)));
});

// ------------------------------------------- columns and secondary lists

test("WRITE AT pos(len), UNDER, NO-GAP, POSITION, RESERVE, sy-linno / sy-colno, sy-lsind and WINDOW", () => {
  const cls = classOf("zr2c_18_columns");
  const { result } = converted.get("zr2c_18_columns");
  assert.equal(result.ok, true);
  assert.match(cls, /write\( val  = 'Flight'\n\s+pos  = 1\n\s+name = `Flight`/);
  assert.match(cls, /write\( val     = gs_flight-connid\n\s+under   = `Flight`/);
  assert.match(cls, /write\( val    = gs_flight-seatsmax\n\s+pos    = gv_col\n\s+len    = 6\n\s+no_gap = abap_true/);
  assert.match(cls, /list\( \)->reserve\( 2 \)\./);
  assert.match(cls, /list\( \)->position\( 25 \)\./);
  assert.match(cls, /write\( list\( \)->current_line\( \) \)/);
  assert.match(cls, /write\( list\( \)->current_column\( \) \)/);
  assert.match(cls, /IF lsind\( \) > 2\.\n\s+set_lsind\( 2 \)\./);
  assert.match(cls, /window\( columns = 60\n\s+lines   = 10 \)\./);
  assert.ok(!/sy-(lsind|colno|linno)/.test(cls));
  assert.ok(!result.notes.some((n) => /position|NO-GAP|UNDER/i.test(n.text)), result.notes.map((n) => n.text).join("\n"));
});

test("SKIP TO LINE, WRITE /(len) and (*), WINDOW outside of AT LINE-SELECTION", () => {
  const r = convert([
    "REPORT zt.",
    "DATA gv TYPE i.",
    "START-OF-SELECTION.",
    "  SKIP TO LINE 5.",
    "  WRITE /(10) gv.",
    "  WRITE AT (*) gv.",
    "  WINDOW STARTING AT 1 1.",
  ].join("\n"), { file: "zt.prog.abap", className: "zcl_t" });
  const cls = r.draft["zcl_t.clas.abap"];
  assert.match(cls, /list\( \)->skip_to_line\( 5 \)\./);
  assert.match(cls, /list\( \)->new_line\(\n\s+\)->write\( val = gv\n\s+len = 10 \)\./);
  assert.deepEqual(r.refusals.map((x) => x.message.split(" - ")[0]), ["WINDOW outside of AT LINE-SELECTION"]);
});

// ------------------------------------------------------- the GUI status

test("SET PF-STATUS: the buttons and function keys of the status in the .prog.xml, EXCLUDING, SET TITLEBAR WITH", () => {
  const cls = classOf("zr2c_17_status");
  const { result } = converted.get("zr2c_17_status");
  assert.equal(result.ok, true);
  assert.match(cls, /set_pf_status\( functions = VALUE #\( \( name = `REFRESH` icon = `sap-icon:\/\/refresh` tooltip = `Read the flights again \(F5\)` \)\n\s+\( name = `DELE` text = `Delete` icon = `sap-icon:\/\/delete` tooltip = `Delete empty flights \(Shift\+F2\)` \) \)\n\s+shortcuts = VALUE #\( \( key = `F5` ucomm = `REFRESH` \)\n\s+\( key = `Shift\+F2` ucomm = `DELE` \) \)\n\s+excluding = gt_excl \)\./);
  assert.match(cls, /excluding = VALUE string_table\( \( `DELE` \) \) \)\./);
  assert.match(cls, /set_title\( \|Flights of airline \{ p_carrid \}\| \)\./);
  // Back is the runtime's own
  assert.ok(!/`BACK`/.test(cls));
  assert.ok(!result.todos.some((t) => /PF-STATUS|TITLEBAR|sy-ucomm/.test(t.message)), result.todos.map((t) => t.message).join("\n"));
});

test("SET PF-STATUS without the .prog.xml, of another program, by a field, space; AT PFnn", () => {
  const conv = (src) => convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  const r = conv("REPORT zt.\nDATA gv TYPE string.\nSTART-OF-SELECTION.\n  SET PF-STATUS 'MAIN'.\n  SET PF-STATUS gv.\n  SET PF-STATUS 'X' OF PROGRAM 'ZOTHER'.\n  SET PF-STATUS space.\n  SET TITLEBAR 'T01'.\n");
  assert.deepEqual(r.todos.map((t) => t.message.split(" - ")[0].split(":")[0]), [
    "SET PF-STATUS 'MAIN' dropped",
    "SET PF-STATUS gv",
    "SET PF-STATUS 'X' OF PROGRAM",
    "SET TITLEBAR 'T01' dropped",
  ]);
  assert.match(r.draft["zcl_t.clas.abap"], /set_pf_status\( VALUE #\( \) \)\./);
  const pf = conv("REPORT zt.\nSTART-OF-SELECTION.\n  WRITE 'x'.\nAT PF05.\n  WRITE sy-ucomm.\nAT PF13.\n  WRITE 'y'.\n");
  const cls = pf.draft["zcl_t.clas.abap"];
  assert.equal(pf.ok, true);
  assert.match(cls, /METHOD initialization\.\n\n\s+" AT PFnn - the function keys of the standard list status\n\s+set_pf_status\( functions = VALUE #\( \( name = `PF05` text = `F5` \)\n\s+\( name = `PF13` text = `Shift\+F1` \) \)\n\s+shortcuts = VALUE #\( \( key = `F5` ucomm = `PF05` \)\n\s+\( key = `Shift\+F1` ucomm = `PF13` \) \) \)\./);
  assert.match(cls, /CASE ucomm\.\n\s+WHEN `PF05`\.\n\s+write\( ucomm \)\.\n\s+WHEN `PF13`\./);
});

// ------------------------------------------------ tables with a header line

test("a global table with a header line is a table and a work area attribute, and every short form is written out", () => {
  const src = [
    "REPORT zt.",
    "DATA gt_num TYPE i OCCURS 0 WITH HEADER LINE.",
    "DATA: BEGIN OF gt_sum OCCURS 0,",
    "        key TYPE c LENGTH 2,",
    "        val TYPE i,",
    "      END OF gt_sum,",
    "      gt_car TYPE TABLE OF scarr WITH HEADER LINE,",
    "      gv_n TYPE i.",
    "START-OF-SELECTION.",
    "  REFRESH gt_num.",
    "  gt_num = 1.",
    "  APPEND gt_num.",
    "  gt_sum-key = 'A'. gt_sum-val = 2.",
    "  COLLECT gt_sum.",
    "  INSERT gt_sum INDEX 1.",
    "  LOOP AT gt_num.",
    "    gt_num = gt_num * 2.",
    "    MODIFY gt_num.",
    "    INSERT gt_num.",
    "  ENDLOOP.",
    "  READ TABLE gt_sum WITH KEY key = 'A'.",
    "  SELECT * FROM scarr INTO TABLE gt_car.",
    "  SELECT SINGLE * FROM scarr INTO gt_car WHERE carrid = 'LH'.",
    "  MOVE-CORRESPONDING gt_car TO gt_sum.",
    "  IF gt_sum IS INITIAL. ENDIF.",
    "  DESCRIBE TABLE gt_num LINES gv_n.",
    "  SORT gt_num.",
    "  PERFORM show TABLES gt_num USING gt_sum.",
    "  CLEAR gt_sum. CLEAR gt_sum[].",
    "FORM show TABLES tt USING us TYPE any.",
    "  DATA lt TYPE i OCCURS 0.",
    "  lt = 1.",
    "  APPEND lt.",
    "  LOOP AT lt.",
    "    WRITE lt.",
    "  ENDLOOP.",
    "ENDFORM.",
  ].join("\n");
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const cls = r.draft["zcl_t.clas.abap"];
  // the declarations
  assert.match(cls, /DATA gt_num TYPE STANDARD TABLE OF i WITH DEFAULT KEY\.\n\s+DATA wa_gt_num LIKE LINE OF gt_num\./);
  assert.match(cls, /BEGIN OF wa_gt_sum,\n\s+key TYPE c LENGTH 2,\n\s+val TYPE i,\n\s+END OF wa_gt_sum,/);
  assert.match(cls, /DATA gt_sum LIKE STANDARD TABLE OF wa_gt_sum WITH DEFAULT KEY\./);
  assert.match(cls, /gt_car TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY,/);
  assert.match(cls, /DATA wa_gt_car LIKE LINE OF gt_car\./);
  // the work areas start fresh with the globals
  assert.match(cls, /CLEAR: gt_num,\n\s+wa_gt_num,\n\s+gt_sum,\n\s+wa_gt_sum,/);
  // the short forms
  assert.match(cls, /CLEAR gt_num\.\n\s+wa_gt_num = 1\.\n\s+APPEND wa_gt_num TO gt_num\./);
  assert.match(cls, /wa_gt_sum-key = 'A'\.\n\s+wa_gt_sum-val = 2\./);
  assert.match(cls, /COLLECT wa_gt_sum INTO gt_sum\./);
  assert.match(cls, /INSERT wa_gt_sum INTO gt_sum INDEX 1\./);
  assert.match(cls, /LOOP AT gt_num INTO wa_gt_num\.\n\s+wa_gt_num = wa_gt_num \* 2\.\n\s+MODIFY gt_num FROM wa_gt_num\.\n\s+INSERT wa_gt_num INTO gt_num INDEX sy-tabix\./);
  assert.match(cls, /READ TABLE gt_sum WITH KEY key = 'A' INTO wa_gt_sum\./);
  // the table stays the table, the header line is the structure
  assert.match(cls, /INTO TABLE @gt_car/);
  assert.match(cls, /INTO @wa_gt_car/);
  assert.match(cls, /MOVE-CORRESPONDING wa_gt_car TO wa_gt_sum\./);
  assert.match(cls, /IF wa_gt_sum IS INITIAL\./);
  assert.match(cls, /DESCRIBE TABLE gt_num LINES gv_n\./);
  assert.match(cls, /SORT gt_num\./);
  assert.match(cls, /show\( EXPORTING\n\s+us = wa_gt_sum\n\s+CHANGING\n\s+tt = gt_num \)\./);
  assert.match(cls, /CLEAR wa_gt_sum\.\n\s+CLEAR gt_sum\./);
  // a FORM's own table: the work area right after it
  assert.match(cls, /DATA lt TYPE STANDARD TABLE OF i WITH DEFAULT KEY\.\n\s+DATA ls_lt LIKE LINE OF lt\.\n\s+ls_lt = 1\.\n\s+APPEND ls_lt TO lt\.\n\s+LOOP AT lt INTO ls_lt\.\n\s+write\( ls_lt \)/);
});
