// The conversion of the corpus: snapshots of every generated file and of
// the migration report, the abapGit format of the files, and the mapping
// table construct by construct. UPDATE_SNAPSHOTS=1 writes the snapshots
// anew, and the test set src/03 - review the diff before committing it.
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { convert, defaultClassName, FRONTEND, GUI, RESERVED_METHODS, SALV, UNCATALOGUED } from "../lib/convert.mjs";
import { corpus, convertEntry, inTestSet, SNAPSHOTS, TEST_SET } from "./corpus.mjs";
import { parseTextpool } from "../lib/textpool.mjs";
import { dependenciesOf, dependencyIndex } from "../lib/deps.mjs";
import { tmpdir } from "node:os";

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

  test(`test set src/03: ${e.name}`, () => {
    const c = converted.get(e.name);
    const mine = readdirSync(TEST_SET).filter((f) => f.startsWith(`${c.result.className}.`)).sort();
    if (UPDATE) {
      for (const f of mine) rmSync(join(TEST_SET, f));
      if (inTestSet(c)) for (const [name, text] of Object.entries(c.result.files)) writeFileSync(join(TEST_SET, name), text);
      return;
    }
    if (!inTestSet(c)) {
      assert.deepEqual(mine, [], `${e.name} needs ${c.result.release.map((x) => x.name).join(", ") || "its refusals fixed"} - not in src/03, which activates on ABAP Cloud too`);
      return;
    }
    assert.deepEqual(mine, Object.keys(c.result.files).sort(), `src/03 holds the files of ${e.name} - run UPDATE_SNAPSHOTS=1 npm run test:report2cloud`);
    for (const [name, text] of Object.entries(c.result.files)) {
      assert.equal(readFileSync(join(TEST_SET, name), "utf8"), text, `src/03/${name} differs from the conversion`);
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
  // the global data starts fresh on its own - the runtime restarts the
  // report on Back from the list (set_fresh_start( )), no CLEAR is written
  assert.match(abap, /METHOD start_of_selection\.\n\n {4}SELECT /);
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

test("CL_SALV_TABLE: a column of an inline CAST - DATA(x) = CAST cl_salv_column_table( o->get_columns( )->get_column( ) )", () => {
  const src = "REPORT zt.\nTYPES: BEGIN OF ty, a TYPE i, b TYPE i, END OF ty.\nDATA gt TYPE STANDARD TABLE OF ty WITH DEFAULT KEY.\nDATA go TYPE REF TO cl_salv_table.\nSTART-OF-SELECTION.\n"
    + "  cl_salv_table=>factory( IMPORTING r_salv_table = go CHANGING t_table = gt ).\n"
    + "  DATA(lo_col) = CAST cl_salv_column_table( go->get_columns( )->get_column( 'A' ) ).\n"
    + "  lo_col->set_long_text( 'Amount' ).\n"
    + "  DATA(lo_print) = go->get_print( ).\n"
    + "  go->display( ).\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  assert.match(r.files["zcl_t.clas.abap"], /alv\( gt\n {8}\)->set_column_text\( name = `A`\n {28}text = 'Amount' \)\./);
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
    "28:3 CALL TRANSACTION ... USING",
    "32:3 EXEC SQL",
    "36:3 CALL SCREEN",
    "38:1 MODULE",
    "42:1 MODULE",
  ]);
  assert.match(result.draft["z2ui5_cl_cgui_r2c_10.clas.abap"], /" report2cloud refused \(line 36\): CALL SCREEN 100/);
});

test("CALL TRANSACTION [AND SKIP FIRST SCREEN] -> call_transaction( ), the class of the catalog; USING stays refused", () => {
  const r = convert([
    "REPORT zt.",
    "DATA gv_tcode TYPE c LENGTH 20 VALUE 'ZFLY'.",
    "START-OF-SELECTION.",
    "  SET PARAMETER ID 'CAR' FIELD 'LH'.",
    "  CALL TRANSACTION 'ZFLY' AND SKIP FIRST SCREEN.",
    "  CALL TRANSACTION gv_tcode WITH AUTHORITY-CHECK.",
  ].join("\n"), { file: "zt.prog.abap", className: "zcl_t" });
  assert.equal(r.ok, true, r.refusals.map((x) => x.message).join("\n"));
  const cls = r.draft["zcl_t.clas.abap"];
  assert.match(cls, /call_transaction\( code       = 'ZFLY'\n\s+skip_first = abap_true \)\./);
  assert.match(cls, /call_transaction\( gv_tcode \)\./);
  assert.ok(r.todos.some((t) => /the transaction must be in the catalog/.test(t.message)));
  assert.ok(r.todos.some((t) => /the statements after CALL TRANSACTION ran when the transaction came back/.test(t.message)));
  const u = convert("REPORT zt.\nDATA gt TYPE STANDARD TABLE OF i WITH DEFAULT KEY.\nSTART-OF-SELECTION.\n  CALL TRANSACTION 'VA02' USING gt MODE 'N'.", { file: "zt.prog.abap", className: "zcl_t" });
  assert.equal(u.ok, false);
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

test("LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT loops at current_screen( ) - with a TODO", () => {
  const r = convert("REPORT zt.\nPARAMETERS p TYPE i.\nAT SELECTION-SCREEN.\n  LOOP AT SCREEN.\n    screen-input = '0'.\n    MODIFY SCREEN.\n  ENDLOOP.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /DATA\(lt_screen\) = current_screen\( \)->loop_at_screen\( \)\./);
  assert.match(cls, /current_screen\( \)->modify_screen\( ls_screen \)\./);
  assert.ok(r.todos.some((t) => t.row === 4 && /its changes are not shown/.test(t.message)));
});

test("LOOP AT SCREEN in a method of a local class: the screen through current_screen( ) of the report", () => {
  const r = convert("REPORT zt.\nPARAMETERS p TYPE i MODIF ID a.\nCLASS lcl DEFINITION.\n  PUBLIC SECTION.\n    CLASS-METHODS pbo.\nENDCLASS.\nCLASS lcl IMPLEMENTATION.\n  METHOD pbo.\n    LOOP AT SCREEN.\n      IF screen-group1 = 'A'.\n        screen-active = '0'.\n        MODIFY SCREEN.\n      ENDIF.\n    ENDLOOP.\n  ENDMETHOD.\nENDCLASS.\nAT SELECTION-SCREEN OUTPUT.\n  lcl=>pbo( ).\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const imp = r.files["zcl_t.clas.locals_imp.abap"];
  assert.match(imp, /DATA\(lt_screen\) = lcl_r2c=>app->current_screen\( \)->loop_at_screen\( \)\./);
  assert.match(imp, /IF ls_screen-group1 = 'A'\./);
  assert.match(imp, /lcl_r2c=>app->current_screen\( \)->modify_screen\( ls_screen \)\./);
});

test("LOOP AT SCREEN in a FORM of AT SELECTION-SCREEN OUTPUT: the FORM gets the screen", () => {
  const src = "REPORT zt.\nPARAMETERS: p_a TYPE c AS CHECKBOX, p_b TYPE i MODIF ID b.\nAT SELECTION-SCREEN OUTPUT.\n  PERFORM hide.\nFORM hide.\n  PERFORM inner.\nENDFORM.\nFORM inner.\n  LOOP AT SCREEN.\n    IF screen-group1 = 'B' AND p_a = abap_true.\n      screen-active = '0'.\n      MODIFY SCREEN.\n    ENDIF.\n  ENDLOOP.\nENDFORM.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /METHODS hide\s+IMPORTING\s+screen TYPE REF TO z2ui5_cl_cgui_selscreen\./);
  assert.match(cls, /METHODS inner\s+IMPORTING\s+screen TYPE REF TO z2ui5_cl_cgui_selscreen\./);
  assert.match(cls, /^\s+hide\( screen \)\.$/m);
  assert.match(cls, /^\s+inner\( screen \)\.$/m);
  assert.match(cls, /DATA\(lt_screen\) = screen->loop_at_screen\( \)\./);
  // performed from elsewhere, the FORM changes a screen built afresh
  const elsewhere = convert(src.replace("AT SELECTION-SCREEN OUTPUT.", "AT SELECTION-SCREEN."), { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(elsewhere.refusals, []);
  assert.match(elsewhere.files["zcl_t.clas.abap"], /^\s+hide\( current_screen\( \) \)\.$/m);
  assert.ok(elsewhere.todos.some((t) => t.row === 4 && /PERFORM hide outside of AT SELECTION-SCREEN OUTPUT/.test(t.message)));
});

test("a global named like a component of the report class is renamed - components and keywords are not", () => {
  const r = convert("REPORT zt.\nTYPES: BEGIN OF ty, message TYPE string, END OF ty.\nDATA message TYPE string.\nDATA ls TYPE ty.\nSTART-OF-SELECTION.\n  message = 'Hello'.\n  ls-message = message.\n  WRITE: / message, ls-message.\n  MESSAGE message TYPE 'S'.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /DATA gv_message TYPE string\./);
  assert.match(cls, /ls-message = gv_message\./);
  assert.match(cls, /^\s+message TYPE string,$/m);
  assert.match(cls, /message\( gv_message \)\./);
  assert.ok(r.notes.some((n) => /renamed to gv_message/.test(n.text)));
});

test("DYNP_VALUES_READ / _UPDATE: the field names name attributes - ASSIGN (fieldname)", () => {
  const src = "REPORT zt.\nPARAMETERS: p_dir TYPE string LOWER CASE, p_file TYPE string LOWER CASE.\nAT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.\n  DATA lt_fields TYPE STANDARD TABLE OF dynpread WITH DEFAULT KEY.\n  lt_fields = VALUE #( ( fieldname = 'P_DIR' ) ).\n  CALL FUNCTION 'DYNP_VALUES_READ'\n    EXPORTING\n      dyname     = sy-repid\n      dynumb     = sy-dynnr\n    TABLES\n      dynpfields = lt_fields\n    EXCEPTIONS\n      OTHERS     = 1.\n  p_file = lt_fields[ 1 ]-fieldvalue && '/a.txt'.\n  CALL FUNCTION 'DYNP_VALUES_UPDATE'\n    EXPORTING\n      dyname     = sy-repid\n      dynumb     = sy-dynnr\n    TABLES\n      dynpfields = lt_fields.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /LOOP AT lt_fields ASSIGNING FIELD-SYMBOL\(<ls_r2c_dynp1>\)\.\s+ASSIGN \(<ls_r2c_dynp1>-fieldname\) TO FIELD-SYMBOL\(<lv_r2c_dynp1>\)\.\s+IF sy-subrc = 0\.\s+<ls_r2c_dynp1>-fieldvalue = <lv_r2c_dynp1>\./);
  assert.match(cls, /<lv_r2c_dynp2> = <ls_r2c_dynp2>-fieldvalue\./);
  assert.ok(r.todos.some((t) => t.row === 6 && /EXCEPTIONS are gone/.test(t.message)));
  assert.ok(!r.todos.some((t) => t.row === 15));
});

test("declarations: the same DATA in two event blocks once, SELECT-OPTIONS FOR <fs>-comp typed by the field symbol", () => {
  const r = convert("REPORT zt.\nTYPES: BEGIN OF ty, d TYPE d, END OF ty.\nFIELD-SYMBOLS <fs> TYPE ty.\nSELECT-OPTIONS s_d FOR <fs>-d.\nAT SELECTION-SCREEN OUTPUT.\n  DATA: lv_key TYPE string,\n        lv_err TYPE string.\n  lv_key = 'a'.\nAT SELECTION-SCREEN.\n  DATA: lv_key TYPE string,\n        lv_err TYPE string.\n  lv_err = lv_key.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.equal(cls.match(/^\s+lv_key TYPE string,$/gm).length, 1);
  assert.match(cls, /DATA s_d TYPE RANGE OF ty-d\./);
  assert.ok(r.notes.some((n) => /lv_key is declared twice the same way/.test(n.text)));
});

test("local classes: a chained DEFINITION DEFERRED copied once, a class a macro writes as it expands", () => {
  const r = convert("REPORT zt.\nDEFINE gen.\n  CLASS lcl_&1 DEFINITION.\n    PUBLIC SECTION.\n      DATA value TYPE &2.\n  ENDCLASS.\nEND-OF-DEFINITION.\ngen: x i, y string.\nCLASS: lcl_a DEFINITION DEFERRED,\n       lcl_b DEFINITION DEFERRED.\nCLASS lcl_a DEFINITION.\n  PUBLIC SECTION.\n    CLASS-METHODS run.\nENDCLASS.\nCLASS lcl_b DEFINITION.\nENDCLASS.\nCLASS lcl_a IMPLEMENTATION.\n  METHOD run.\n    WRITE / 'a'.\n  ENDMETHOD.\nENDCLASS.\nDATA go_x TYPE REF TO lcl_x.\nSTART-OF-SELECTION.\n  lcl_a=>run( ).\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const all = `${r.files["zcl_t.clas.locals_def.abap"] ?? ""}\n${r.files["zcl_t.clas.locals_imp.abap"]}`;
  assert.equal(all.match(/CLASS: lcl_a\s+DEFINITION DEFERRED,\n\s+lcl_b\s+DEFINITION DEFERRED\./g).length, 1);
  assert.match(all, /CLASS lcl_x DEFINITION\.\n\s+PUBLIC SECTION\.\n\s+DATA value TYPE i\./);
  assert.match(all, /CLASS lcl_y DEFINITION\.\n\s+PUBLIC SECTION\.\n\s+DATA value TYPE string\./);
  assert.doesNotMatch(all, /gen:/);
});

test("the ALV USER_COMMAND callback: fieldname is the hotspot column, value its cell, refresh is moot", () => {
  const src = "REPORT zt.\nDATA gt_out TYPE STANDARD TABLE OF i WITH DEFAULT KEY.\nSTART-OF-SELECTION.\n  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'\n    EXPORTING\n      i_callback_program      = sy-repid\n      i_callback_user_command = 'USER_COMMAND'\n    TABLES\n      t_outtab                = gt_out.\nFORM user_command USING r_ucomm LIKE sy-ucomm rs_selfield TYPE slis_selfield.\n  IF rs_selfield-fieldname = 'CARRID'.\n    WRITE / rs_selfield-value.\n  ENDIF.\n  rs_selfield-refresh = 'X'.\n  rs_selfield-row_stable = abap_true.\nENDFORM.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /READ TABLE gt_out INDEX row ASSIGNING FIELD-SYMBOL\(<ls_r2c_row>\)\./);
  assert.match(cls, /ASSIGN COMPONENT hide OF STRUCTURE <ls_r2c_row> TO FIELD-SYMBOL\(<lv_r2c_value>\)\./);
  assert.match(cls, /IF hide = 'CARRID'\./);
  assert.match(cls, /write\( lv_r2c_value \)/);
  assert.doesNotMatch(cls, /refresh|row_stable/);
  assert.ok(r.todos.some((t) => /column of a hotspot click/.test(t.message)));
  assert.match(refusalOf(src.replace("rs_selfield-refresh = 'X'.", "WRITE / rs_selfield-sumindex."))[0], /rs_selfield-sumindex has no counterpart/);
});

test("the toolbar handler of the grid: MOVE ... TO ls_button-function is an assignment like any other", () => {
  const src = readFileSync(new URL("./corpus/zr2c_19_grid.prog.abap", import.meta.url), "utf8");
  const moved = src.replace("ls_button-function = 'FULL'.", "MOVE 'FULL' TO ls_button-function.").replace("ls_button-text = 'Full flights'.", "MOVE 'Full flights' TO ls_button-text.");
  assert.notEqual(moved, src);
  const a = convert(src, { file: "z.prog.abap", className: "zcl_t" });
  const b = convert(moved, { file: "z.prog.abap", className: "zcl_t" });
  assert.deepEqual(b.refusals, []);
  assert.equal(b.files["zcl_t.clas.abap"], a.files["zcl_t.clas.abap"]);
});

test("the grid handlers: e_row_id, e_column_id used as a whole are rebuilt from row and column", () => {
  const src = readFileSync(new URL("./corpus/zr2c_19_grid.prog.abap", import.meta.url), "utf8");
  const v = src.replace("    READ TABLE gt_flight INDEX e_row_id-index INTO gs_flight.\n    IF e_column_id-fieldname = 'CONNID'.\n      MESSAGE |Connection { gs_flight-connid }| TYPE 'S'.\n    ENDIF.",
    "    PERFORM show USING e_row_id e_column_id.\n    CASE e_column_id.\n      WHEN 'CONNID'.\n        MESSAGE 'Connection' TYPE 'S'.\n    ENDCASE.") +
    "\nFORM show USING is_row TYPE lvc_s_row is_col TYPE lvc_s_col.\n  READ TABLE gt_flight INDEX is_row-index INTO gs_flight.\nENDFORM.\n";
  assert.notEqual(v.indexOf("PERFORM show"), -1);
  const r = convert(v, { file: "z.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /DATA\(e_row_id\) = VALUE z2ui5_cl_cgui_alv=>ty_s_lvc_row\( index = row \)\./);
  assert.match(cls, /DATA\(e_column_id\) = VALUE z2ui5_cl_cgui_alv=>ty_s_lvc_col\( fieldname = column \)\./);
  assert.match(cls, /is_row TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_row\n\s+is_col TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_col\./);
});

test("SELECT COUNT(*) without INTO is no short form; itab[] is a variable for a CHANGING parameter", () => {
  const r = convert("REPORT zt.\nPARAMETERS p TYPE c LENGTH 40.\nDATA lr TYPE RANGE OF i.\nSTART-OF-SELECTION.\n  SELECT COUNT(*) FROM reposrc WHERE progname = p.\n  PERFORM fill CHANGING lr[].\nFORM fill CHANGING ct LIKE lr.\n  CLEAR ct.\nENDFORM.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /SELECT COUNT\(\*\) FROM reposrc WHERE progname = @p\./);
  assert.match(cls, /ct = lr\[\] \)\./);
});

test("ON VALUE-REQUEST FOR s_x-low and FOR s_x-high: one WHEN, value_request_part( ) tells them apart", () => {
  const src = "REPORT zt.\nDATA gv TYPE c LENGTH 10.\nSELECT-OPTIONS s_x FOR gv.\nAT SELECTION-SCREEN ON VALUE-REQUEST FOR s_x-low.\n  s_x-low = `A`.\nAT SELECTION-SCREEN ON VALUE-REQUEST FOR s_x-high.\n  s_x-high = `Z`.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals, []);
  assert.match(r.files["zcl_t.clas.abap"], /WHEN `S_X`\.\n\s+IF value_request_part\( \) = z2ui5_cl_cgui_selscreen=>cs_part-high\.\n\s+ls_s_x-high = `Z`\.\n\s+ELSE\.\n\s+ls_s_x-low = `A`\.\n\s+ENDIF\./);
  assert.ok(r.todos.some((t) => t.row === 4 && /wrote the line on the screen/.test(t.message)));
  assert.match(refusalOf(`${src}AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_x-high.\n  s_x-high = 'Y'.\n`)[0], /^8:1 a second ON VALUE-REQUEST for S_X/);
});

test("the files of the user: cl_gui_frontend_services and GUI_UPLOAD as z2ui5_cl_cgui_frontend, EXCEPTIONS kept", () => {
  const cls = classOf("zr2c_22_files");
  const { result } = converted.get("zr2c_22_files");
  assert.equal(result.ok, true, result.refusals.map((x) => x.message).join("\n"));
  assert.match(cls, /z2ui5_cl_cgui_frontend=>gui_upload\( EXPORTING  filename            = p_file\n(.*\n)*?\s+CHANGING   data_tab            = gt_seats\n\s+EXCEPTIONS file_open_error     = 1\n\s+OTHERS              = 2 \)\./);
  assert.match(cls, /^\s+z2ui5_cl_cgui_frontend=>file_open_dialog\(\n\s+EXPORTING\n/m);
  assert.match(cls, /lt_files  TYPE z2ui5_cl_cgui_frontend=>ty_t_file_table,/);
  assert.match(cls, /lv_action = z2ui5_cl_cgui_frontend=>action_ok/);
  assert.match(cls, /z2ui5_cl_cgui_frontend=>gui_download\(\n/);
  assert.doesNotMatch(cls, /cl_gui_frontend_services|filetable/i);
});

test("cl_gui_frontend_services: a member or a parameter the browser has no counterpart for is refused", () => {
  const src = "REPORT zt.\nDATA lv TYPE string.\nSTART-OF-SELECTION.\n  cl_gui_frontend_services=>get_gui_version( CHANGING version_table = lv ).\n  cl_gui_frontend_services=>gui_upload( EXPORTING filename = lv check_bom = abap_true CHANGING data_tab = lv ).\n  CALL FUNCTION 'GUI_UPLOAD' EXPORTING filename = lv no_auth_check = 'X' TABLES data_tab = lv.\n  cl_gui_cfw=>flush( ).\n";
  assert.deepEqual(refusalOf(src).map((x) => x.split(";")[0]), [
    "4:3 cl_gui_frontend_services - get_gui_version has no counterpart in the browser",
    "5:3 cl_gui_frontend_services - gui_upload( check_bom = ... ) is not supported",
    "6:3 CALL FUNCTION 'GUI_UPLOAD' - EXPORTING no_auth_check has no counterpart in z2ui5_cl_cgui_frontend=>gui_upload( )",
  ]);
});

test("the table of z2ui5_cl_cgui_frontend in the converter is the class - its constants, methods, parameters, exceptions", () => {
  const text = readFileSync(new URL("../../../src/01/z2ui5_cl_cgui_frontend.clas.abap", import.meta.url), "utf8");
  const def = text.slice(0, text.indexOf("PROTECTED SECTION"));
  const methods = {};
  // a signature ends with the period at the end of its line - not at the one of DEFAULT '*.*'
  for (const m of def.matchAll(/^\s*CLASS-METHODS\s+(\w+)([\s\S]*?)\.\s*$/gim)) {
    let section;
    const params = [];
    const exceptions = [];
    for (const line of m[2].split("\n").map((l) => l.trim()).filter(Boolean)) {
      if (/^(IMPORTING|EXPORTING|CHANGING|RETURNING|EXCEPTIONS)$/.test(line)) section = line;
      else if (section === "EXCEPTIONS") exceptions.push(line.toLowerCase());
      else if (section && section !== "RETURNING") params.push(line.split(/\s+/)[0].toLowerCase());
    }
    methods[m[1].toLowerCase()] = { params, exceptions };
  }
  const constants = [...def.matchAll(/^\s*CONSTANTS\s+(\w+)\s/gim)].map((m) => m[1].toLowerCase());
  assert.deepEqual({ constants, methods }, FRONTEND);
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

test("refused: BDC_OPEN_GROUP, PERFORM IN PROGRAM - a table with a header line, a popup and a function key no longer", () => {
  const r = refusalOf([
    "REPORT zt.",
    "DATA gt TYPE i OCCURS 0.",
    "SELECTION-SCREEN FUNCTION KEY 1.",
    "START-OF-SELECTION.",
    "  CALL FUNCTION 'BDC_OPEN_GROUP' EXPORTING group = 'x'.",
    "  PERFORM x IN PROGRAM zother.",
  ].join("\n"));
  assert.deepEqual(r.map((x) => x.split(" - ")[0]), [
    "5:3 CALL FUNCTION 'BDC_OPEN_GROUP'",
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

test("the synchronous popups: popup_to_decide( ) / popup_get_values_sval( ), the block cut at the call and continued in the callback on_popup_n( answer )", () => {
  const cls = classOf("zr2c_16_popups");
  const { result } = converted.get("zr2c_16_popups");
  assert.equal(result.ok, true);
  // POPUP_TO_DECIDE in AT LINE-SELECTION: the two lines joined, the options, the CASE on the answer continued
  assert.match(cls, /METHOD at_line_selection\.\n\n(.*\n)*?\s+popup_to_decide\( question = 'Book the flight' && ` ` && gs_flight-connid\n\s+options  = VALUE #\( \( `Book now` \) \( `Waiting list` \) \)\n\s+then     = `ON_POPUP_1`\n\s+title    = 'Booking' \)\.\n\n\s+ENDMETHOD\./);
  // the callbacks are public methods - the runtime calls them by name
  assert.match(cls, /PUBLIC SECTION\.\n(.*\n)*?\s+METHODS on_popup_1\n\s+IMPORTING\n\s+answer TYPE string\.\n(.*\n)*?\s+PROTECTED SECTION\./);
  assert.ok(!/METHODS at_user_command REDEFINITION/.test(cls) || /CASE ucomm/.test(cls));
  assert.match(cls, /METHOD on_popup_1\.\n\n\s+lv_answer = answer\.\n\s+CASE lv_answer\.\n\s+WHEN '1'\.\n\s+book\( gs_flight \)\./);
  // POPUP_TO_CONFIRM inside a WHEN: the branch continued, the IF sy-subrc of the EXCEPTIONS dropped, the other WHEN kept
  assert.match(cls, /WHEN 'CANCEL'\.\n\s+popup_to_decide\( question = 'Cancel all bookings of this run\?'\n\s+options  = VALUE #\( \( `Cancel them` \) \( `Keep them` \) \)\n\s+then     = `ON_POPUP_2`\n\s+title    = 'Cancel bookings' \)\.\n\s+WHEN 'PASSENGER'\./);
  assert.match(cls, /METHOD on_popup_2\.\n\n\s+gv_answer = answer\.\n\s+IF gv_answer = '1'\./);
  assert.ok(!/sy-subrc/.test(cls));
  assert.ok(!/could not be shown/.test(cls));
  // POPUP_GET_VALUES in a FORM: converted, not cut - the ucomm, a TODO, the answer lines as TODOs
  assert.match(cls, /popup_get_values_sval\( sval  = lt_fields\n\s+ucomm = `POPUP_3`\n\s+title = 'Passenger' \)\.\n\s+" TODO in at_user_command\( \) with ucomm POPUP_3: lv_rc = /);
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
  assert.match(cls, /METHOD on_popup_1\.\n\n(.*\n)*?\s+lv_rc = SWITCH #\( answer WHEN 'A' THEN 'A' ELSE space \)\.\n\s+popup_values_sval\( CHANGING sval = lt_fields \)\.\n\s+IF lv_rc = 'A'\./);
  // the second popup is cut out of the first continuation
  assert.match(cls, /then\s+= `ON_POPUP_2`/);
  assert.match(cls, /METHOD on_popup_2\.\n\n\s+lv_rc = SWITCH #\( answer WHEN '1' THEN 'J' WHEN '2' THEN 'N' ELSE 'A' \)\.\n\s+IF lv_rc = 'J'\./);
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
  const conv = (src) => convert(src, { file: "zt.prog.abap", className: "zcl_t", commandField: false });
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

// ------------------------------------------- the catalogue of refusals

test("every refusal of the corpus and of the cases above has its entry in the catalogue (lib/refusals.mjs)", () => {
  assert.deepEqual([...UNCATALOGUED], [], "add an entry, or widen the pattern of one");
  const { result } = converted.get("zr2c_10_refused");
  assert.ok(result.refusals.every((r) => r.code !== "other"));
});

test("a dynpro of fields: the screens of the .prog.xml, the modules as methods, CALL SCREEN and what follows it", () => {
  const cls = classOf("zr2c_23_dynpro");
  const { result } = converted.get("zr2c_23_dynpro");
  assert.equal(result.ok, true, result.refusals.map((x) => x.message).join("\n"));
  assert.match(cls, /call_screen\( `0100` \)\.\n\n\s+ENDMETHOD\./);
  assert.match(cls, /METHOD after_call_screen\.\n\n\s+CASE dynnr\.\n\s+WHEN `0100`\.\n\s+IF gv_booked = 'X'\./);
  // the fields: a frame a block, a text before an input its label, an output field read-only
  assert.match(cls, /screen->block_begin\( `Booking`\n\s+\)->parameter\( val {7}= p_carrid\n\s+text {6}= `Airline`\n\s+read_only = abap_true\n/);
  assert.match(cls, /\)->parameter\( val {8}= gv_connid\n\s+text {7}= `Connection`\n\s+obligatory = abap_true\n/);
  assert.match(cls, /\)->line_begin\(\n\s+\)->parameter\( val {6}= gv_seats\n(.*\n){2}\s+\)->button\( text {2}= `Check`\n\s+event = `CHECK`\n\s+\)->line_end\(/);
  assert.match(cls, /\)->radiobutton\( val {3}= gv_bus\n\s+text {2}= `Business`\n\s+group = `RB_GV_ECO`\n\s+\)->block_end\( \)\./);
  assert.match(cls, /screen->comment\( `Book the seats now\?`\n/);
  // the flow logic: the PBO module gets the screen, the PAI the OK code and the order of the modules
  assert.match(cls, /METHOD dynpro_pbo\.\n\n\s+CASE dynnr\.\n\s+WHEN `0100`\.\n\s+status_0100\( current_screen\( \) \)\./);
  assert.match(cls, /WHEN `0100`\.\n\s+ok_code = ucomm\.\n\s+" AT EXIT-COMMAND - the functions that leave\n\s+IF ucomm = `BACK` OR ucomm = `EXIT` OR ucomm = `CANC` OR ucomm = `CANCEL`\.\n\s+exit_0100\( \)\.\n(.*\n){4}\s+IF gv_connid IS NOT INITIAL\.\n\s+check_connid\( \)\.\n\s+ENDIF\.\n\s+IF screen_left\( \) = abap_true\.\n\s+RETURN\.\n\s+ENDIF\.\n\s+user_command_0100\( \)\./);
  // SET SCREEN, LEAVE TO SCREEN, sy-ucomm of a PAI module
  assert.match(cls, /set_screen\( `0200` \)\./);
  assert.match(cls, /METHOD user_command_0200\.\n\n\s+CASE ok_code\.\n\s+WHEN 'BOOK'\.\n\s+gv_booked = 'X'\.\n\s+leave_to_screen\( `0000` \)\.\n\s+RETURN\./);
  assert.match(cls, /leave_to_screen\( `0100` \)\./);
  assert.deepEqual(result.todos.map((t) => t.message), []);
});

test("a dynpro the converter does not build is refused at its modules - a control, LOOP, a screen in a variable, no .prog.xml", () => {
  const xml = (container, flow) => `<abapGit><asx:abap><asx:values><DYNPROS><item><HEADER><PROGRAM>ZT</PROGRAM><SCREEN>0100</SCREEN><TYPE>N</TYPE></HEADER>
<CONTAINERS><RPY_DYCATT><TYPE>SCREEN</TYPE><NAME>SCREEN</NAME></RPY_DYCATT>${container}</CONTAINERS>
<FIELDS><RPY_DYFATC><CONT_TYPE>SCREEN</CONT_TYPE><TYPE>OKCODE</TYPE><NAME>OK_CODE</NAME></RPY_DYFATC></FIELDS>
<FLOW_LOGIC>${flow.map((l) => `<RPY_DYFLOW><LINE>${l}</LINE></RPY_DYFLOW>`).join("")}</FLOW_LOGIC></item></DYNPROS></asx:values></asx:abap></abapGit>`;
  const src = "REPORT zt.\nDATA ok_code TYPE sy-ucomm.\nSTART-OF-SELECTION.\n  CALL SCREEN 100.\nMODULE user_command_0100 INPUT.\n  LEAVE TO SCREEN 0.\nENDMODULE.\n";
  const refused = (source, x) => convert(source, { file: "zt.prog.abap", className: "zcl_t", textpool: parseTextpool(x) }).refusals.map((r) => `${r.row}:${r.col} ${r.message.split(" - a dynpro of fields")[0]}`);
  const pai = ["PROCESS AFTER INPUT.", "  MODULE user_command_0100."];
  assert.deepEqual(refused(src, xml("", pai)), []);
  assert.deepEqual(refused(src, xml("<RPY_DYCATT><TYPE>CUST_CTRL</TYPE><NAME>CONT</NAME></RPY_DYCATT>", pai)), [
    "4:3 CALL SCREEN - the dynpro is not converted (a dynpro of fields is, from the .prog.xml - see the MODULE refusals); else build the screen as an abap2UI5 view or a popup",
    "5:1 MODULE - screen 0100 has a custom control (a SAP GUI control) CONT",
  ]);
  assert.deepEqual(refused(src, xml("", ["PROCESS AFTER INPUT.", "  LOOP AT gt_x.", "  ENDLOOP.", "  MODULE user_command_0100."])), [
    "4:3 CALL SCREEN - the dynpro is not converted (a dynpro of fields is, from the .prog.xml - see the MODULE refusals); else build the screen as an abap2UI5 view or a popup",
    "5:1 MODULE - screen 0100: LOOP AT GT_X in the flow logic; screen 0100: ENDLOOP in the flow logic",
  ]);
  assert.match(refused(src.replace("CALL SCREEN 100", "CALL SCREEN gv_dynnr"), xml("", pai)).find((x) => x.startsWith("5:1")), /^5:1 MODULE - CALL SCREEN with a variable/);
  assert.match(refused(src, undefined).find((x) => x.startsWith("5:1")), /^5:1 MODULE - the screens are in the \.prog\.xml \(--texts\), which was not passed/);
  assert.match(refused(src, xml("", ["PROCESS AFTER INPUT.", "  MODULE user_command_0200."])).find((x) => x.startsWith("5:1")), /^5:1 MODULE - screen 0100 calls MODULE user_command_0200, which is not in the report/);
});

test("a grid created inline, a VALUE field catalog, no selection screen: alv( ) in start_of_selection( ), the IF sy-subrc around CALL SCREEN gone", () => {
  const cls = classOf("zr2c_24_gridinline");
  const { result } = converted.get("zr2c_24_gridinline");
  assert.equal(result.ok, true, result.refusals.map((x) => x.message).join("\n"));
  // INITIALIZATION went straight on with START-OF-SELECTION - its statements are there
  assert.match(cls, /METHOD initialization\.\n\n\s+" the command field[^\n]*\n\s+set_command_field\( \)\.\n\n\s+set_title\( `Connections in a grid` \)\.\n\n\s+ENDMETHOD\./);
  assert.match(cls, /METHOD start_of_selection\.\n\n\s+SELECT \* FROM spfli INTO TABLE @DATA\(connections\)/);
  assert.match(cls, /alv\( connections\n\s+\)->set_column_text\( name = `CARRID`\n\s+text = 'Airline'\n(.*\n){4}\s+\)->set_column_text\( name = `CITYTO`\n\s+text = 'To'\n\s+\)->set_column_hidden\( `MANDT` \)\./);
  assert.doesNotMatch(cls, /cl_gui_|DATA\(grid\)|DATA\(fcat\)|IF sy-subrc/i);
  assert.ok(result.mapped.some((m) => /no selection screen: INITIALIZATION went straight on/.test(m.target)));
});

test("a report with a selection screen keeps its INITIALIZATION; an IF of the source that is empty stays", () => {
  const src = "REPORT zt.\nPARAMETERS p TYPE i.\nINITIALIZATION.\n  p = 1.\nSTART-OF-SELECTION.\n  IF p = 2.\n  ENDIF.\n  WRITE p.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t", commandField: false });
  assert.match(r.files["zcl_t.clas.abap"], /METHOD initialization\.\n\n\s+p = 1\./);
  // by default the command field of the SAP GUI comes first
  const on = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.match(on.files["zcl_t.clas.abap"], /METHOD initialization\.\n\n\s+" the command field[^\n]*\n\s+set_command_field\( \)\.\n\n\s+p = 1\./);
  assert.match(r.files["zcl_t.clas.abap"], /IF p = 2\.\n\s+ENDIF\./);
});

test("the grid of REUSE_ALV_GRID_DISPLAY_LVC: GET_GLOBALS_FROM_SLVC_FULLSCR, CHECK on the grid and check_changed_data( ) go", () => {
  const src = `REPORT zt.
DATA gt TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
START-OF-SELECTION.
  SELECT * FROM scarr INTO TABLE gt.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_structure_name = 'SCARR'
    TABLES
      t_outtab         = gt.
FORM flush_alv.
  DATA lo_grid TYPE REF TO cl_gui_alv_grid.
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = lo_grid.
  CHECK: lo_grid IS NOT INITIAL.
  IF ( lo_grid IS INITIAL ).
    RETURN.
  ENDIF.
  lo_grid->check_changed_data( ).
ENDFORM.
`;
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.doesNotMatch(cls, /lo_grid|GET_GLOBALS_FROM_SLVC_FULLSCR|check_changed_data/i);
  assert.ok(r.mapped.some((m) => /GET_GLOBALS_FROM_SLVC_FULLSCR - the grid of the ALV display is alv\( \)/.test(m.target)));
  assert.ok(r.mapped.some((m) => /CHECK on the grid object/.test(m.target)));
});

test("cl_gui_frontend_services=>directory_list_files( files_only ) is z2ui5_cl_cgui_frontend's, with its EXCEPTIONS", () => {
  const src = "REPORT zt.\nDATA gt TYPE STANDARD TABLE OF file_info WITH DEFAULT KEY.\nDATA gv_n TYPE i.\nSTART-OF-SELECTION.\n  cl_gui_frontend_services=>directory_list_files( EXPORTING directory = 'C:\\' files_only = abap_true CHANGING file_table = gt count = gv_n EXCEPTIONS cntl_error = 1 OTHERS = 2 ).\n  WRITE gv_n.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  assert.match(r.files["zcl_t.clas.abap"], /z2ui5_cl_cgui_frontend=>directory_list_files\(/);
});

test("the table of the SAP GUI stand-ins in the converter is the classes - their constants, attributes, methods, parameters, exceptions", () => {
  for (const [cls, members] of Object.entries(GUI.members)) {
    const text = readFileSync(new URL(`../../../src/01/${cls}.clas.abap`, import.meta.url), "utf8");
    const def = text.slice(text.indexOf("PUBLIC SECTION"), text.indexOf("PROTECTED SECTION"));
    const methods = {};
    for (const m of def.matchAll(/^\s*(?:CLASS-)?METHODS\s+(\w+)([\s\S]*?)\.\s*$/gim)) {
      let section;
      const params = [];
      const exceptions = [];
      for (const line of m[2].split("\n").map((l) => l.trim()).filter(Boolean)) {
        if (/^(IMPORTING|EXPORTING|CHANGING|RETURNING|EXCEPTIONS)$/.test(line)) section = line;
        else if (/^PREFERRED/.test(line)) continue;
        else if (section === "EXCEPTIONS") exceptions.push(line.toLowerCase());
        else if (section && section !== "RETURNING") params.push(line.split(/\s+/)[0].toLowerCase());
      }
      methods[m[1].toLowerCase()] = { params, exceptions };
    }
    const parent = (/INHERITING FROM\s+(\w+)/i.exec(text) ?? [])[1]?.toLowerCase();
    const constants = [...def.matchAll(/^\s*CONSTANTS\s+(\w+)\s/gim)].map((m) => m[1].toLowerCase());
    const attributes = [...def.matchAll(/^\s*(?:CLASS-)?DATA\s+(\w+)\s/gim)].map((m) => m[1].toLowerCase());
    const events = [...def.matchAll(/^\s*EVENTS\s+(\w+)\s*(?:\.|\n\s*EXPORTING)/gm)].map((m) => m[1].toLowerCase());
    assert.deepEqual({ ...(parent ? { parent } : {}), constants, attributes, events, methods }, members, cls);
  }
  for (const standin of [...Object.values(GUI.classes), ...Object.values(SALV.classes)]) assert.ok(GUI.members[standin], standin);
});

test("SAP GUI controls: the containers, the text editor and the HTML viewer become their stand-ins, CREATE OBJECT is NEW", () => {
  const cls = classOf("zr2c_25_textedit");
  const { result } = converted.get("zr2c_25_textedit");
  assert.equal(result.ok, true, result.refusals.map((x) => x.message).join("\n"));
  assert.match(cls, /DATA go_notes\s+TYPE REF TO z2ui5_cl_cgui_gui_container\./);
  assert.match(cls, /DATA go_editor\s+TYPE REF TO z2ui5_cl_cgui_gui_textedit\./);
  assert.match(cls, /DATA go_html\s+TYPE REF TO z2ui5_cl_cgui_gui_html_viewer\./);
  assert.match(cls, /go_notes = NEW #\( container_name = 'NOTES' \)\./);
  assert.match(cls, /go_editor = NEW #\( parent {21}= go_notes\n\s+wordwrap_mode {14}= z2ui5_cl_cgui_gui_textedit=>wordwrap_at_fixed_position/);
  assert.match(cls, /go_editor->set_toolbar_mode\( z2ui5_cl_cgui_gui_textedit=>false \)\./);
  assert.match(cls, /go_html->load_data\( IMPORTING assigned_url = lv_url\n\s+CHANGING {2}data_table {3}= lt_html \)\./);
  // the custom control areas of the screen, after the line of the buttons
  assert.match(cls, /\)->line_end\(\n\s+\)->custom_control\( `NOTES`\n\s+\)->custom_control\( `PREVIEW` \)\./);
  assert.doesNotMatch(cls, /cl_gui_/i);
});

test("SAP GUI controls: a member, a parameter or an event the stand-ins do not have is refused; other controls are", () => {
  const head = "REPORT zt.\nDATA go_c TYPE REF TO cl_gui_custom_container.\nDATA go_e TYPE REF TO cl_gui_textedit.\nSTART-OF-SELECTION.\n  CREATE OBJECT go_c EXPORTING container_name = 'CC'.\n";
  const refused = (body) => refusalOf(`${head}${body}`).map((x) => x.replace(/^\d+:\d+ /, ""));
  assert.deepEqual(refused("  CREATE OBJECT go_e EXPORTING parent = go_c.\n  go_e->set_textstream( 'x' ).\n"), []);
  // NEW #( ) of a control: the constructor of the class it is assigned to
  assert.deepEqual(refused("  go_e = NEW #( parent = go_c wordwrap_mode = cl_gui_textedit=>wordwrap_at_windowborder ).\n"), []);
  assert.deepEqual(refused("  go_e = NEW #( parent = go_c colour = 1 ).\n"), ["SAP GUI controls: colour is no parameter of the method called in the stand-in - port this statement by hand"]);
  assert.deepEqual(refused("  go_e->set_comments_string( ).\n"), ["SAP GUI controls: go_e->set_comments_string has no counterpart in z2ui5_cl_cgui_gui_textedit - port this statement by hand"]);
  assert.deepEqual(refused("  go_e->set_textstream( text = 'x' colour = 1 ).\n"), ["SAP GUI controls: colour is no parameter of the method called in the stand-in - port this statement by hand"]);
  assert.deepEqual(refusalOf(`${head}DATA go_p TYPE REF TO cl_gui_simple_tree.\n`).map((x) => x.replace(/^\d+:\d+ /, "")), ["SAP GUI controls: cl_gui_simple_tree has no counterpart - the containers, cl_gui_textedit, cl_gui_html_viewer, cl_gui_toolbar, cl_gui_picture and cl_gui_alv_grid have (z2ui5_cl_cgui_gui*)"]);
});

test("SAP GUI controls: SET HANDLER of a local class's method is set_handler( ) of the stand-in; what it cannot call is refused", () => {
  const cls = (decl, body) => `REPORT zt.\nCLASS lcl DEFINITION.\n  PUBLIC SECTION.\n    DATA mo_t TYPE REF TO cl_gui_toolbar.\n    DATA mo_c TYPE REF TO cl_gui_custom_container.\n    METHODS run.\n${decl}ENDCLASS.\nCLASS lcl IMPLEMENTATION.\n  METHOD run.\n    CREATE OBJECT mo_c EXPORTING container_name = 'CC'.\n    CREATE OBJECT mo_t EXPORTING parent = mo_c.\n${body}  ENDMETHOD.\n  METHOD on_f.\n  ENDMETHOD.\nENDCLASS.\nSTART-OF-SELECTION.\n  NEW lcl( )->run( ).\n`;
  const handler = "    METHODS on_f FOR EVENT function_selected OF cl_gui_toolbar IMPORTING fcode.\n";
  const r = convert(cls(handler, "    SET HANDLER me->on_f FOR mo_t.\n    SET HANDLER on_f FOR mo_t ACTIVATION abap_false.\n"), { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const text = Object.values(r.files).join("\n");
  assert.match(text, /mo_t->set_handler\( handler = me\n\s+method {2}= `ON_F`\n\s+event {3}= `FUNCTION_SELECTED` \)\./);
  assert.match(text, /activation = abap_false \)\./);
  // the handler object is in the session: serializable
  assert.match(text, /CLASS lcl DEFINITION[^.]*\.\n\s+PUBLIC SECTION\.\n\s+INTERFACES if_serializable_object\./);
  assert.match(text, /METHODS on_f FOR EVENT function_selected OF z2ui5_cl_cgui_gui_toolbar/);

  const refused = (decl, body) => convert(cls(decl, body), { file: "zt.prog.abap", className: "zcl_t" }).refusals.map((x) => x.message.split(" - ")[0]);
  assert.deepEqual(refused(handler, "    SET HANDLER on_f FOR ALL INSTANCES.\n"), ["SAP GUI controls: SET HANDLER ... FOR ALL INSTANCES"]);
  // a static method: called through an object of its local class (RTTI
  // finds the class by the object), with a constructor that takes
  // parameters by the absolute name of the class
  const statics = (ctor) => convert(cls(`    CLASS-METHODS on_f FOR EVENT function_selected OF cl_gui_toolbar IMPORTING fcode.\n${ctor}`, "    SET HANDLER lcl=>on_f FOR mo_t.\n"), { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(statics("").refusals.map((x) => x.message), []);
  assert.match(Object.values(statics("").files).join("\n"), /mo_t->set_handler\( handler = NEW lcl\( \)\n\s+method {2}= `ON_F`/);
  assert.match(Object.values(statics("    METHODS constructor IMPORTING iv_x TYPE i.\n").draft).join("\n"), /mo_t->set_handler\( class {2}= `\\CLASS-POOL=ZCL_T\\CLASS=LCL`/);
  // an event the stand-in does not raise
  assert.deepEqual(refused("    METHODS on_f FOR EVENT dropdown_clicked OF cl_gui_toolbar IMPORTING fcode.\n", "    SET HANDLER on_f FOR mo_c.\n"), ["SAP GUI controls: SET HANDLER on_f"]);
});

test("TYPE (name) / FOR (name) of a fixed name - a literal or a DATA with a VALUE nothing else names - is typed statically; a name set at runtime is refused", () => {
  const src = "REPORT zt.\nTABLES vbak.\nDATA selectiontext TYPE string VALUE 'VBAK-VBELN'.\nSELECT-OPTIONS: so_vbeln FOR (selectiontext).\nSELECT-OPTIONS s_subj FOR ('STRING') NO INTERVALS.\nPARAMETERS p_mat TYPE ('MATNR').\nSTART-OF-SELECTION.\n  WRITE: / lines( so_vbeln ), lines( s_subj ), p_mat.\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /DATA so_vbeln_type TYPE vbak-vbeln\./);
  assert.match(cls, /DATA s_subj_type\s+TYPE string\./);
  assert.match(cls, /DATA so_vbeln LIKE RANGE OF so_vbeln_type\./);
  assert.match(cls, /DATA p_mat\s+TYPE matnr\./);
  // the name is a parameter - its value is known at runtime only
  const dyn = "REPORT zt.\nPARAMETERS p_type TYPE c LENGTH 30 DEFAULT 'MATNR'.\nPARAMETERS p_data LIKE (p_type).\n";
  assert.match(convert(dyn, { file: "zt.prog.abap", className: "zcl_t" }).refusals[0].message, /^P_DATA is typed at runtime/);
  // a DATA with a VALUE that is changed is no fixed name
  const set = "REPORT zt.\nDATA gv_name TYPE string VALUE 'MATNR'.\nSELECT-OPTIONS s_x FOR (gv_name).\nINITIALIZATION.\n  gv_name = 'WERKS'.\n";
  assert.match(convert(set, { file: "zt.prog.abap", className: "zcl_t" }).refusals[0].message, /^S_X is typed at runtime/);
});

test("SAP GUI controls: a grid in a local class is the grid stand-in - VALUE #( ) of a generic parameter takes the classic type, refresh_table_display( ) is passed the table", () => {
  const src = (refresh) => `REPORT zt.\nCLASS lcl DEFINITION.\n  PUBLIC SECTION.\n    DATA mt TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.\n    DATA mo_grid TYPE REF TO cl_gui_alv_grid.\n    METHODS show.\n    METHODS on_cmd FOR EVENT user_command OF cl_gui_alv_grid IMPORTING e_ucomm sender.\nENDCLASS.\nCLASS lcl IMPLEMENTATION.\n  METHOD show.\n    mo_grid = NEW cl_gui_alv_grid( i_parent = NEW cl_gui_custom_container( container_name = 'CC' ) ).\n    SET HANDLER on_cmd FOR mo_grid.\n    mo_grid->set_table_for_first_display( EXPORTING is_layout = VALUE #( zebra = abap_true ) it_toolbar_excluding = VALUE #( ( cl_gui_alv_grid=>mc_fc_excl_all ) ) CHANGING it_outtab = mt ).\n  ENDMETHOD.\n  METHOD on_cmd.\n    ${refresh}\n  ENDMETHOD.\nENDCLASS.\nSTART-OF-SELECTION.\n  NEW lcl( )->show( ).\n`;
  const r = convert(src("sender->refresh_table_display( is_stable = VALUE #( row = abap_true ) )."), { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const text = Object.values(r.files).join("\n");
  assert.match(text, /mo_grid = NEW z2ui5_cl_cgui_gui_alv_grid\( i_parent = NEW z2ui5_cl_cgui_gui_container\( container_name = 'CC' \) \)\./);
  assert.match(text, /is_layout = VALUE lvc_s_layo\( zebra = abap_true \)/);
  assert.match(text, /it_toolbar_excluding = VALUE ui_functions\( \( z2ui5_cl_cgui_gui_alv_grid=>mc_fc_excl_all \) \)/);
  assert.match(text, /sender->refresh_table_display\( EXPORTING is_stable = VALUE lvc_s_stbl\( row = abap_true \) CHANGING it_outtab = mt \)\./);
  assert.match(convert(src("mo_grid->refresh_table_display( )."), { file: "zt.prog.abap", className: "zcl_t" }).files["zcl_t.clas.locals_imp.abap"], /mo_grid->refresh_table_display\( CHANGING it_outtab = mt \)\./);
  // a grid of another object: its table is not in reach here
  const other = src("DATA(lo) = NEW lcl( ).\n    lo->mo_grid->refresh_table_display( ).");
  assert.match(convert(other, { file: "zt.prog.abap", className: "zcl_t" }).refusals[0]?.message ?? "", /refresh_table_display\( \) - the grid shows a copy of its table/);
});

test("what the syntax check of the web corpus found: MESSAGE of an exception of a multi-line CATCH or a local class, DATA( ) in a local class, the fields a SELECTION-SCREEN declares, a label set at runtime", () => {
  const src = [
    "REPORT zt.",
    "DATA lv_result TYPE i.",
    "SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE b1_title.",
    "SELECTION-SCREEN COMMENT 1(20) sc_t001.",
    "PARAMETERS p_x TYPE c.",
    "SELECTION-SCREEN END OF BLOCK b1.",
    "CLASS lcl DEFINITION.",
    "  PUBLIC SECTION.",
    "    DATA error TYPE REF TO cx_root.",
    "    METHODS run.",
    "ENDCLASS.",
    "CLASS lcl IMPLEMENTATION.",
    "  METHOD run.",
    "    DATA(lv_result) = 2.",
    "    b1_title = 'Title'.",
    "    %_p_x_%_app_%-text = 'Mark'.",
    "    TRY.",
    "      CATCH cx_sy_zerodivide INTO error.",
    "        MESSAGE error TYPE 'W'.",
    "    ENDTRY.",
    "  ENDMETHOD.",
    "ENDCLASS.",
    "INITIALIZATION.",
    "  NEW lcl( )->run( ).",
    "START-OF-SELECTION.",
    "  TRY.",
    "    CATCH cx_sy_zerodivide",
    "          cx_sy_arithmetic_overflow",
    "    INTO DATA(lx).",
    "      MESSAGE lx TYPE 'E'.",
    "  ENDTRY.",
    "",
  ].join("\n");
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const cls = r.files["zcl_t.clas.abap"];
  const imp = r.files["zcl_t.clas.locals_imp.abap"];
  assert.match(cls, /message\( text = lx->get_text\( \)/);
  assert.match(imp, /lcl_r2c=>app->message\( text = error->get_text\( \)/);
  // the local variable of the method, not the report's global
  assert.match(imp, /DATA\(lv_result\) = 2\./);
  assert.match(imp, /lcl_r2c=>app->b1_title = 'Title'\./);
  // a comment field is c LENGTH 83, as in the classic
  assert.match(cls, /DATA sc_t001\s+TYPE c LENGTH 83\./);
  // the label set at runtime: a global, shown while set
  assert.match(cls, /DATA gv_label_p_x\s+TYPE string\./);
  assert.match(imp, /lcl_r2c=>app->gv_label_p_x = 'Mark'\./);
  assert.match(cls, /text\s*= gv_label_p_x/);
  // a comment in a chain of TYPES does not cut it in two
  const chain = convert("REPORT zt.\nTYPES: BEGIN OF ty_s,\n         a TYPE i, \"one\n         b TYPE string, \"two\n       END OF ty_s.\nDATA gs TYPE ty_s.\nSTART-OF-SELECTION.\n  WRITE gs-b.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.match(chain.files["zcl_t.clas.abap"], /BEGIN OF ty_s,\n\s+a TYPE i,\n\s+b TYPE string,\n\s+END OF ty_s\./);
});

test("MESSAGE of an exception object is its text; MODULE x OUTPUT and MODULE x INPUT are two methods", () => {
  const r = convert("REPORT zt.\nSTART-OF-SELECTION.\n  TRY.\n      RAISE EXCEPTION TYPE cx_sy_zerodivide.\n    CATCH cx_root INTO DATA(lx).\n      MESSAGE lx TYPE 'I'.\n  ENDTRY.\n", { file: "zt.prog.abap", className: "zcl_t" });
  assert.match(r.files["zcl_t.clas.abap"], /message\( text = lx->get_text\( \)\n\s+type = `I` \)\./);
  const xml = `<abapGit><asx:abap><asx:values><DYNPROS><item><HEADER><PROGRAM>ZT</PROGRAM><SCREEN>0100</SCREEN><TYPE>N</TYPE></HEADER>
<CONTAINERS><RPY_DYCATT><TYPE>SCREEN</TYPE><NAME>SCREEN</NAME></RPY_DYCATT></CONTAINERS><FIELDS></FIELDS>
<FLOW_LOGIC><RPY_DYFLOW><LINE>PROCESS BEFORE OUTPUT.</LINE></RPY_DYFLOW><RPY_DYFLOW><LINE>MODULE init_0100.</LINE></RPY_DYFLOW><RPY_DYFLOW><LINE>PROCESS AFTER INPUT.</LINE></RPY_DYFLOW><RPY_DYFLOW><LINE>MODULE init_0100.</LINE></RPY_DYFLOW></FLOW_LOGIC></item></DYNPROS></asx:values></asx:abap></abapGit>`;
  const src = "REPORT zt.\nDATA gv TYPE i.\nSTART-OF-SELECTION.\n  CALL SCREEN 100.\nMODULE init_0100 OUTPUT.\n  gv = 1.\nENDMODULE.\nMODULE init_0100 INPUT.\n  LEAVE TO SCREEN 0.\nENDMODULE.\n";
  const d = convert(src, { file: "zt.prog.abap", className: "zcl_t", textpool: parseTextpool(xml) });
  assert.deepEqual(d.refusals.map((x) => x.message), []);
  const cls = d.files["zcl_t.clas.abap"];
  assert.match(cls, /METHOD dynpro_pbo\.\n\n\s+CASE dynnr\.\n\s+WHEN `0100`\.\n\s+init_0100\( \)\./);
  assert.match(cls, /METHOD dynpro_pai\.(.*\n)*?\s+init_0100_pai\( \)\./);
  assert.match(cls, /METHOD init_0100_pai\.\n\n\s+leave_to_screen\( `0000` \)\./);
});

test("SAP GUI controls: a control handed to a class of the report's own is refused - it takes a cl_gui_* object", () => {
  const src = "REPORT zt.\nDATA go_c TYPE REF TO cl_gui_custom_container.\nSTART-OF-SELECTION.\n  CREATE OBJECT go_c EXPORTING container_name = 'CC'.\n  zcl_my_button=>create( parent = go_c ).\n";
  assert.deepEqual(refusalOf(src).map((x) => x.replace(/^\d+:\d+ /, "")), ["SAP GUI controls: go_c, a SAP GUI control, is handed to a method that is no stand-in - it takes a cl_gui_* object - port this statement by hand"]);
});

test("the dependencies of a report type what it reads of them - an inline declaration of an event block read in another one", () => {
  const src = "REPORT zt.\nINITIALIZATION.\n  DATA(lo_log) = zcl_app_factory=>create_logger( ).\nSTART-OF-SELECTION.\n  lo_log->add( `x` ).\n";
  const factory = "CLASS zcl_app_factory DEFINITION PUBLIC CREATE PUBLIC.\n  PUBLIC SECTION.\n    CLASS-METHODS create_logger RETURNING VALUE(result) TYPE REF TO zcl_app_log.\nENDCLASS.\nCLASS zcl_app_factory IMPLEMENTATION.\n  METHOD create_logger.\n  ENDMETHOD.\nENDCLASS.\n";
  const log = "CLASS zcl_app_log DEFINITION PUBLIC CREATE PUBLIC.\n  PUBLIC SECTION.\n    METHODS add IMPORTING t TYPE string.\nENDCLASS.\nCLASS zcl_app_log IMPLEMENTATION.\n  METHOD add.\n  ENDMETHOD.\nENDCLASS.\n";
  assert.match(convert(src, { file: "zt.prog.abap", className: "zcl_t" }).refusals[0].message, /^lo_log is declared inline in an event block/);

  const dir = join(tmpdir(), `r2c-deps-${process.pid}`);
  mkdirSync(join(dir, "src", "sub"), { recursive: true });
  try {
    writeFileSync(join(dir, "src", "zcl_app_factory.clas.abap"), factory);
    writeFileSync(join(dir, "src", "sub", "zcl_app_log.clas.abap"), log);
    writeFileSync(join(dir, "src", "zcl_app_factory.clas.testclasses.abap"), "CLASS ltcl DEFINITION FOR TESTING. ENDCLASS.\n");
    writeFileSync(join(dir, "src", "zcl_unused.clas.abap"), "CLASS zcl_unused DEFINITION PUBLIC. ENDCLASS.\n");
    const index = dependencyIndex([dir]);
    // what the report names, and what that names in turn - no test class, nothing unnamed
    const deps = dependenciesOf(src, index);
    assert.deepEqual(deps.map((d) => d.name).sort(), ["zcl_app_factory.clas.abap", "zcl_app_log.clas.abap"]);
    assert.deepEqual(dependenciesOf(src, index, 1).map((d) => d.name), ["zcl_app_factory.clas.abap"]);
    const r = convert(src, { file: "zt.prog.abap", className: "zcl_t", deps });
    assert.deepEqual(r.refusals, []);
    assert.match(r.files["zcl_t.clas.abap"], /DATA lo_log TYPE REF TO zcl_app_log\./);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("a name every JavaScript object has - constructor, toString - is no SAP GUI class, icon or ALV type", () => {
  const src = "REPORT zt.\nDATA go_c TYPE REF TO cl_gui_custom_container.\nCLASS lcl DEFINITION.\n  PUBLIC SECTION.\n    METHODS constructor.\n    METHODS tostring RETURNING VALUE(r) TYPE string.\nENDCLASS.\nCLASS lcl IMPLEMENTATION.\n  METHOD constructor.\n  ENDMETHOD.\n  METHOD tostring.\n    r = `x`.\n  ENDMETHOD.\nENDCLASS.\nSTART-OF-SELECTION.\n  go_c = NEW #( container_name = 'CC' ).\n  WRITE NEW lcl( )->tostring( ).\n";
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.deepEqual(r.refusals.map((x) => x.message), []);
  const text = Object.values(r.files).join("\n");
  assert.doesNotMatch(text, /native code|function Object/);
  assert.match(text, /METHODS constructor\./);
});

test("cl_demo_output and if_demo_output are the stand-in that writes into the list - a method it does not have stays and is named for the release", () => {
  const r = convert(`REPORT zdemo.
DATA itab TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA out TYPE REF TO if_demo_output.
START-OF-SELECTION.
  APPEND 1 TO itab.
  cl_demo_output=>begin_section( 'Numbers' ).
  cl_demo_output=>write( itab ).
  out = cl_demo_output=>new( ).
  out->write_text( 'x' )->line( )->display( ).
  cl_demo_output=>display( itab ).
  cl_demo_output=>write_xml( '<a/>' ).`, { file: "zdemo.prog.abap" });
  assert.equal(r.ok, true);
  const cls = r.files["zcl_demo.clas.abap"];
  assert.match(cls, /DATA out\s+TYPE REF TO z2ui5_if_cgui_demo_output\./);
  assert.match(cls, /z2ui5_cl_cgui_demo_output=>begin_section\( 'Numbers' \)\./);
  assert.match(cls, /out = z2ui5_cl_cgui_demo_output=>new\( \)\./);
  assert.match(cls, /z2ui5_cl_cgui_demo_output=>display\( itab \)\./);
  assert.match(cls, /cl_demo_output=>write_xml/);
  assert.deepEqual(r.release.map((x) => x.name), ["CL_DEMO_OUTPUT"]);
});

test("the converter runs in the browser too - no node: import in convert.mjs and what it imports (the playground of the site)", () => {
  const lib = new URL("../lib/", import.meta.url);
  const seen = new Set();
  const walk = (file) => {
    if (seen.has(file)) return;
    seen.add(file);
    const text = readFileSync(new URL(file, lib), "utf8");
    for (const m of text.matchAll(/^import\s[^;]*?from\s+"([^"]+)"/gms)) {
      assert.ok(!m[1].startsWith("node:"), `${file} imports ${m[1]}`);
      if (m[1].startsWith("./")) walk(m[1].slice(2));
    }
  };
  walk("convert.mjs");
  walk("report.mjs");
  assert.ok(seen.has("abap.mjs") && seen.has("refusals.mjs"));
});

test("wrappers: a function module without a counterpart behind a method of a wrapper class - the parameters as the call passes them, the EXCEPTIONS and sy-subrc kept", () => {
  const src = "REPORT zt.\nDATA lv TYPE string.\nDATA lt TYPE STANDARD TABLE OF string.\nSTART-OF-SELECTION.\n" +
    "  CALL FUNCTION 'Z_LEGACY_READ'\n    EXPORTING\n      iv_key = 'A'\n    IMPORTING\n      ev_text = lv\n    TABLES\n      et_lines = lt\n    EXCEPTIONS\n      not_found = 1\n      OTHERS = 2.\n" +
    "  WRITE lv.\n";
  const off = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.match(off.files["zcl_t.clas.abap"], /CALL FUNCTION 'Z_LEGACY_READ'/);
  assert.equal(off.files["zcl_t_fmw.clas.abap"], undefined);

  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t", wrappers: true });
  assert.equal(r.ok, true, r.refusals.map((x) => x.message).join("\n"));
  const cls = r.files["zcl_t.clas.abap"];
  assert.doesNotMatch(cls, /CALL FUNCTION/);
  assert.match(cls, /zcl_t_fmw=>z_legacy_read\( EXPORTING\s+iv_key\s+= 'A'\n\s+IMPORTING\s+ev_text\s+= lv\n\s+CHANGING\s+et_lines\s+= lt\n\s+EXCEPTIONS not_found = 1\n\s+OTHERS\s+= 2 \)\./);
  const w = r.files["zcl_t_fmw.clas.abap"];
  assert.match(w, /CLASS-METHODS z_legacy_read\n\s+IMPORTING\n\s+iv_key TYPE any OPTIONAL\n\s+EXPORTING\n\s+ev_text TYPE any\n\s+CHANGING\n\s+et_lines TYPE STANDARD TABLE\n\s+EXCEPTIONS\n\s+not_found\n\s+error\./);
  assert.match(w, /CALL FUNCTION 'Z_LEGACY_READ'[\s\S]*TABLES\n\s+et_lines = et_lines[\s\S]*WHEN 1\.\n\s+RAISE not_found\./);
  assert.ok(r.files["zcl_t_fmw.clas.xml"]);
  // the function module is still one to check - in the wrapper
  assert.deepEqual(r.release.filter((x) => x.kind === "function module").map((x) => `${x.name} ${x.file}`), ["Z_LEGACY_READ zcl_t_fmw.clas.abap"]);
});

test("successors: a SELECT of a table with a released successor reads it - the columns under their old names, only when every column maps", () => {
  const src = "REPORT zt.\nPARAMETERS p_carr TYPE c LENGTH 3.\nDATA gt TYPE STANDARD TABLE OF sflight.\nDATA gs TYPE scarr.\nSTART-OF-SELECTION.\n" +
    "  SELECT carrid connid fldate FROM sflight INTO CORRESPONDING FIELDS OF TABLE gt WHERE carrid = p_carr ORDER BY fldate.\n" +
    "  SELECT SINGLE url FROM scarr INTO gs-url WHERE carrid = p_carr.\n" +
    "  SELECT SINGLE * FROM scarr INTO gs WHERE carrid = p_carr.\n  WRITE gs-carrid.\n";
  const off = convert(src, { file: "zt.prog.abap", className: "zcl_t" });
  assert.doesNotMatch(off.files["zcl_t.clas.abap"], /\/dmo\//);
  const r = convert(src, { file: "zt.prog.abap", className: "zcl_t", successors: true });
  const cls = r.files["zcl_t.clas.abap"];
  assert.match(cls, /SELECT carrier_id AS carrid, connection_id AS connid, flight_date AS fldate FROM \/dmo\/flight INTO CORRESPONDING FIELDS OF TABLE @gt WHERE carrier_id = @p_carr ORDER BY flight_date\./);
  // a column without a certain counterpart, and SELECT *: the table stays
  assert.match(cls, /SELECT SINGLE url FROM scarr/);
  assert.match(cls, /SELECT SINGLE \* FROM scarr/);
  assert.ok(r.todos.some((t) => /url has no certain counterpart in \/dmo\/carrier/.test(t.message)));
  assert.ok(r.todos.some((t) => /SELECT \* FROM scarr/.test(t.message)));
});
