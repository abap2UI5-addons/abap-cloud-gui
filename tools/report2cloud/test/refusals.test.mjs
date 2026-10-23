// The catalogue of refusals (lib/refusals.mjs): every refusal the converter
// can write has its entry - why, and the rewrite - and docs/refusals.md is
// written from it. convert.test.mjs checks the refusals of the corpus and of
// its own cases at its end; this file the statements and function modules
// refused as a whole, and a message of every other kind.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { REFUSED_MESSAGES } from "../lib/convert.mjs";
import { CATALOGUE, refusalOf, refusalsMarkdown } from "../lib/refusals.mjs";
import { REFUSALS_DOC } from "../docs.mjs";

test("docs/refusals.md is written from the catalogue - npm run report2cloud:docs", () => {
  assert.equal(readFileSync(REFUSALS_DOC, "utf8"), refusalsMarkdown());
});

test("every entry has an id of its own, a title, the why and the rewrite", () => {
  const ids = CATALOGUE.map((e) => e.id);
  assert.equal(new Set(ids).size, ids.length);
  for (const e of CATALOGUE) {
    assert.match(e.id, /^[a-z0-9-]+$/);
    assert.ok(e.title && e.why.length > 40 && e.rewrite.length > 30, e.id);
  }
});

test("every statement and function module refused as a whole has its entry", () => {
  const missing = REFUSED_MESSAGES().filter((m) => !refusalOf(m));
  assert.deepEqual(missing, []);
});

// one message of every kind the converter writes with values of its own -
// as the refuse( ) calls of lib/convert.mjs put them together
const SAMPLES = {
  "dynpro": ["SET SCREEN of another screen - one screen is converted", "MODULE - the report calls more than one screen; the screen of one grid is converted"],
  "leave": ["LEAVE PROGRAM - the app has no screens or transactions to leave; RETURN ends the event block"],
  "perform-mismatch": ["PERFORM fill - no FORM fill in this report", "PERFORM fill passes 3 parameter(s)", "PERFORM fill: 'X' is passed to cv_x, which the FORM changes", "PERFORM top - the FORM is a callback of the ALV and is not converted"],
  "reserved-name": ["LIST is the name of a component of z2ui5_cl_cgui_report - a global of the report becomes an attribute"],
  "local-class": ["WRITE in a local class - the class has no list and no FORMs of the report", "the local class uses gt_x, a global of the report - a local class of the generated class cannot reach it"],
  "hide": ["HIDE gs_x - the field is not a global field", "HIDE without a WRITE before it in the same block", "HIDE of other fields (a, b) than elsewhere (c)"],
  "message": ["MESSAGE without a message class - neither in the statement nor MESSAGE-ID of REPORT", "MESSAGE ... RAISING - classic exceptions"],
  "screen-loop": ["LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT", "MODIFY SCREEN outside of LOOP AT SCREEN", "SCREEN-COLOR has no counterpart - loop_at_screen( ) has name"],
  "page-events": ["a second TOP-OF-PAGE", "a second END-OF-PAGE", "TOP-OF-PAGE with other statements than WRITE, ULINE, SKIP, NEW-LINE and FORMAT - the runtime writes"],
  "selscreen-event-field": ["ON p_x - no parameter or select-option of that name", "ON BLOCK b1 - no SELECTION-SCREEN BEGIN OF BLOCK b1", "ON END OF s_x - no select-option of that name", "ON RADIOBUTTON GROUP g1 - no radio button of that group", "ON VALUE-REQUEST FOR p_x - no parameter", "ON HELP-REQUEST FOR p_x - no parameter", "a second ON VALUE-REQUEST for P_X - a select-option has one F4", "a second ON HELP-REQUEST for P_X - a select-option has one F1"],
  "selscreen": ["SELECTION-SCREEN INCLUDE - the included selection screen is not part of the input", "this SELECTION-SCREEN statement is not supported: SELECTION-SCREEN X", "SELECTION-SCREEN TAB t1 without DEFAULT SCREEN - the subscreen", "SELECTION-SCREEN TAB ... DEFAULT SCREEN 0101 - no SELECTION-SCREEN BEGIN OF SCREEN"],
  "call-selection-screen": ["CALL SELECTION-SCREEN 0200 - no SELECTION-SCREEN BEGIN OF SCREEN 0200 in the report", "a second CALL SELECTION-SCREEN 0100 with statements after it"],
  "submit": ["SUBMIT ... EXPORTING LIST TO MEMORY - the list", "SUBMIT ... TO SAP-SPOOL - no spool", "SUBMIT ... VIA JOB - no background jobs", "SUBMIT ... USING SELECTION-SCREEN / SELECTION-SETS OF PROGRAM - the class", "SUBMIT ... WITH S_X NOT IN - a range cannot be handed over negated", "SUBMIT ... WITH P_X FOO - not a comparison of a range", "this SUBMIT is not understood: SUBMIT x"],
  "logical-database": ["SUBMIT ... WITH-FREE SELECTIONS - logical database selections have no counterpart", "SELECTION-SCREEN DYNAMIC SELECTIONS - logical database selections"],
  "popup": ["POPUP_TO_CONFIRM without TEXT_QUESTION - not understood", "POPUP_TO_CONFIRM_STEP without TEXTLINE1 - not understood", "POPUP_TO_DECIDE without TEXTLINE1, TEXT_OPTION1 and TEXT_OPTION2 - not understood", "POPUP_GET_VALUES without TABLES fields - not understood"],
  "alv-classic": ["CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE' - only REUSE_ALV_GRID_DISPLAY / REUSE_ALV_LIST_DISPLAY with TABLES t_outtab are converted", "REUSE_ALV_GRID_DISPLAY without TABLES t_outtab - not understood", "cl_salv_table=>factory( ) without r_salv_table and t_table - not understood", "FORM user_command is the USER_COMMAND callback of the ALV and needs two parameters (r_ucomm, rs_selfield)", "FORM user_command: rs_selfield-value has no counterpart - at_line_selection( ) has the row only"],
  "alv-grid": ["set_drop_down_table( ) of cl_gui_alv_grid - no counterpart in alv( ); port it by hand", "the DATA_CHANGED handler of the grid - an edited cell arrives in at_data_changed( row column )", "the AFTER_REFRESH handler of the grid - no counterpart in alv( )", "go_grid, the grid object, is used here - alv( ) has no object", "the local class lcl_h handles events of cl_gui_alv_grid and has other methods or attributes", "the toolbar handler on_tb: a button without FUNCTION", "the toolbar handler on_tb: this APPEND is not understood", "the toolbar handler on_tb: only buttons appended to e_object->mt_toolbar are converted", "on_dc: sender - the grid object has no counterpart", "on_dc: the handler uses me-> - in the report class me is the report", "on_dc: e_column has no counterpart in at_line_selection( ) - it knows the row only", "set_table_for_first_display( ) without CHANGING it_outtab - not understood"],
  "f4": ["F4IF_INT_TABLE_VALUE_REQUEST outside of AT SELECTION-SCREEN ON VALUE-REQUEST", "F4IF_INT_TABLE_VALUE_REQUEST without TABLES value_tab - not understood"],
  "sap-gui": ["SAP GUI controls (cl_gui_*) need a dynpro container - use alv( ) or an abap2UI5 view", "cl_gui_frontend_services - there is no SAP GUI frontend"],
  "foreign-field": ["ASSIGN of a field of another program ('(PROG)FIELD') - field symbols"],
  "select-short-form": ["SELECT without INTO - the short form reads into the TABLES work area"],
  "declarations": ["TABLES inside a FORM or event block", "STATICS outside of a FORM - use DATA", "the TABLES parameter tt_log of FORM add is used with its header line, and has no type"],
  "window": ["WINDOW outside of AT LINE-SELECTION - window( ) shows the secondary list"],
  "function-keys": ["AT PF05 - a second block for the key", "AT PF99 - no function key of that number"],
  "syntax": ["the parser does not understand this statement - a syntax error", "no END FORM for this statement"],
  "list-control": ["LEAVE TO LIST-PROCESSING - the list is shown after start_of_selection( )", "NEW-PAGE PRINT ON - printing is not supported"],
};

test("a message of every kind finds its entry - and the right one", () => {
  const wrong = [];
  for (const [id, messages] of Object.entries(SAMPLES)) {
    for (const m of messages) {
      const e = refusalOf(m);
      if (e?.id !== id) wrong.push(`${m} -> ${e?.id ?? "none"} (expected ${id})`);
    }
  }
  assert.deepEqual(wrong, []);
});
