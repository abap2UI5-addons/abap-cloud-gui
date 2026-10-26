// The catalogue of refusals: every statement the converter refuses belongs to
// one entry - why it has no counterpart in a browser app, and the rewrite in
// the classic report that unblocks the conversion. A refusal finds its entry
// by its message (the first entry whose pattern matches); the migration
// report links it, the coverage run ranks by it, and docs/refusals.md is
// written from it (npm run report2cloud:docs). A message no entry matches is
// a gap here - the test of the corpus fails on it.

export const DOCS_URL = "https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2cloud/docs/refusals.md";

const abap = (text) => ["```abap", text.trim(), "```"].join("\n");

export const CATALOGUE = [
  {
    id: "dynpro",
    title: "Dynpros: CALL SCREEN, MODULE, SET SCREEN, CONTROLS",
    match: /^(CALL SCREEN|SET SCREEN|MODULE\b|CONTROLS|CALL SUBSCREEN|CALL DIALOG|SET SCREEN of another|SET CURSOR|LOCAL\b)/,
    why: "A dynpro is a screen of the SAP GUI with its own flow logic. A browser app has no screens of that kind: abap-cloud-gui has the selection screen, the list, the ALV and popups. Two kinds of screen are converted. A dynpro of fields - texts, inputs, checkboxes, radio buttons, frames and push buttons, read from the screens abapGit writes into the .prog.xml: the modules become methods, the flow logic `dynpro_pbo( )` and `dynpro_pai( )`, `CALL SCREEN` becomes `call_screen( )` and what follows it `after_call_screen( )`. And the screen of one `cl_gui_alv_grid` - its PBO modules go where `CALL SCREEN` stood, its PAI modules become `at_user_command( )`. A screen with a custom control, a subscreen, a table control or a tabstrip, or flow logic with LOOP or CALL SUBSCREEN, is refused.",
    rewrite: `Ask the user with the selection screen or a popup, and show the result as a list or an ALV:

${abap(`
* before
CALL SCREEN 100.          " fields p_name, p_city on the dynpro
MODULE user_command_0100 INPUT.
  CASE ok_code. WHEN 'SAVE'. PERFORM save. ENDCASE.
ENDMODULE.

* after - a screen of the report's own, called as a dialog
SELECTION-SCREEN BEGIN OF SCREEN 100 AS WINDOW.
PARAMETERS: p_name TYPE string, p_city TYPE string.
SELECTION-SCREEN END OF SCREEN 100.
...
CALL SELECTION-SCREEN 100.
IF sy-subrc = 0.
  PERFORM save.
ENDIF.
`)}

A screen with a table control, a subscreen or a tabstrip is on the roadmap (Stage 5).`,
  },
  {
    id: "call-transaction",
    title: "CALL TRANSACTION ... USING and batch input",
    match: /^(CALL TRANSACTION|CALL FUNCTION 'BDC_)/,
    why: "Batch input (`CALL TRANSACTION ... USING`, `BDC_*` sessions) plays the screens of a transaction - there are none in a browser app, and on ABAP Cloud batch input is no API at all. A plain `CALL TRANSACTION` is converted: `call_transaction( )` starts the report class the catalog names.",
    rewrite: `Call the released API of the application instead of driving its screens:

${abap(`
* before
CALL TRANSACTION 'VA02' USING gt_bdc MODE 'N'.

* after - the released API, for example the RAP business object of the sales order
MODIFY ENTITIES OF i_salesordertp
  ENTITY salesorder UPDATE FIELDS ( purchaseorderbycustomer )
  WITH VALUE #( ( salesorder = p_vbeln purchaseorderbycustomer = p_bstkd ) ).
COMMIT ENTITIES.
`)}

To open another app, a converted report can \`submit( )\` its class or \`call_transaction( )\` a transaction of the catalog.`,
  },
  {
    id: "native-sql",
    title: "Native SQL: EXEC SQL",
    match: /^EXEC SQL/,
    why: "Native SQL talks to the database directly. ABAP Cloud has no native SQL, and the generated class is meant to run there.",
    rewrite: abap(`
* before
EXEC SQL.
  SELECT COUNT(*) INTO :gv_count FROM vbak
ENDEXEC.

* after - ABAP SQL on a released CDS view
SELECT COUNT(*) FROM i_salesdocument INTO @gv_count.
`),
  },
  {
    id: "include-missing",
    title: "INCLUDE without its file",
    match: /^INCLUDE - no such include/,
    why: "The includes of a report are inlined before the conversion, from the files beside it as abapGit writes them (`<include>.prog.abap`). An include that is not there cannot be inlined. `INCLUDE x IF FOUND` without a file is dropped, as the compiler drops it.",
    rewrite: `Put the include beside the report, or name its folder:

\`\`\`bash
node tools/report2cloud/cli.mjs src/zreport.prog.abap --includes src/includes
\`\`\``,
  },
  {
    id: "logical-database",
    title: "Logical databases: NODES, GET, REJECT, dynamic and free selections",
    match: /^(NODES|GET - logical|REJECT|SELECTION-SCREEN DYNAMIC SELECTIONS|SUBMIT \.\.\. WITH-FREE SELECTIONS)/,
    why: "A logical database reads the data for the report and adds its own selection screen. There are none on ABAP Cloud.",
    rewrite: abap(`
* before
NODES spfli.
GET spfli.
  WRITE: / spfli-carrid, spfli-connid.

* after - read the data yourself
SELECT carrid, connid FROM spfli INTO TABLE @DATA(lt_spfli).
LOOP AT lt_spfli INTO DATA(ls_spfli).
  WRITE: / ls_spfli-carrid, ls_spfli-connid.
ENDLOOP.
`),
  },
  {
    id: "foreign-field",
    title: "Fields of another program: ASSIGN ('(PROG)FIELD')",
    match: /^ASSIGN of a field of another program/,
    why: "A field symbol to a field of another program (or of a screen) reaches into memory the class does not share, and ABAP Cloud does not allow it.",
    rewrite: "Pass the value as a parameter, or read it again from the database. Within the report, a global of the report is an attribute of the class and is reached directly.",
  },
  {
    id: "sap-gui",
    title: "The SAP GUI frontend: controls, the frontend services the browser has no counterpart for",
    match: /^(SAP GUI controls|cl_gui_frontend_services|CALL FUNCTION '(GUI_|WS_|SAPGUI_PROGRESS))/,
    why: "There is no SAP GUI on the other side: no custom container to put a control in, no file system of the user. A `cl_gui_alv_grid` is converted to `alv( )`. The containers, `cl_gui_textedit`, `cl_gui_html_viewer`, `cl_gui_toolbar`, `cl_gui_picture` and `cl_gui_simple_tree` of a report without a grid become stand-ins with the same methods (`z2ui5_cl_cgui_gui*`): a custom control area of a dynpro holds them, the text editor is a text area of the page, the HTML viewer shows its document, the toolbar its buttons, the tree its nodes (`MTREESNODE`). A `cl_gui_alv_grid` of a local class is `z2ui5_cl_cgui_gui_alv_grid`, the ALV of the report in its container - `refresh_table_display( )` is passed the table it shows, which must be in reach. `SET HANDLER` of a handler method of a local class is `set_handler( )`: the stand-in raises `function_selected`, `dropdown_clicked`, `sapevent`, `picture_click`, `node_double_click`, `selection_changed`, `expand_no_children` and `close` from the browser. Refused are the other controls (the column and list trees, the calendar), an event a stand-in does not raise, a handler for all instances or a static one, and a member the stand-ins do not have. The files are converted: `cl_gui_frontend_services` is `z2ui5_cl_cgui_frontend` - `file_open_dialog` in an F4 opens an upload in the browser and runs the F4 again with the file, `gui_upload` reads it, `gui_download` is a download of the browser, `GUI_UPLOAD` / `GUI_DOWNLOAD` become its methods. What it does not have - the registry, the GUI version, an option of a method it does not take - is refused.",
    rewrite: "Remove the call, or write it with what `z2ui5_cl_cgui_frontend` has: the file dialogs, `gui_upload`, `gui_download`, the folders, `execute` of a URL, `clipboard_export`. A control becomes `alv( )` or an abap2UI5 view. A progress indicator is simply dropped.",
  },
  {
    id: "desktop",
    title: "Desktop integration and system calls: OLE, CALL 'C-function', EDITOR-CALL, GENERATE",
    match: /^(CREATE OBJECT (OF|\.\.\. OLE)|CALL METHOD OF|SET PROPERTY OF|GET PROPERTY OF|CALL '|CALL - system functions|SYSTEM-CALL|EDITOR-CALL|GENERATE|INSERT REPORT|SUPPLY|DEMAND|CONTEXTS|COMMUNICATION)/i,
    why: "OLE automation of desktop programs, kernel calls, the ABAP editor and generated programs belong to the SAP GUI and the classic application server. None of it exists for a browser app or on ABAP Cloud.",
    rewrite: "Remove the statement, or replace it by what it was used for: a file export for Excel automation, a released API for a kernel call, a class instead of a generated subroutine pool.",
  },
  {
    id: "list-read",
    title: "Reading the list back: READ LINE, MODIFY LINE, GET CURSOR outside of a line selection",
    match: /^(GET CURSOR|READ LINE|MODIFY LINE)/,
    why: "These statements work on the list as the SAP GUI shows it. `GET CURSOR FIELD / VALUE / LINE / OFFSET` in `AT LINE-SELECTION` is converted to `z2ui5_cl_cgui_gui=>get_cursor_field( )`; the runtime has counterparts of the others too - `list( )->read_line( )`, `read_value( )`, `modify_line( )` - but the converter does not map them yet.",
    rewrite: abap(`
* before
AT LINE-SELECTION.
  READ LINE sy-lilli FIELD VALUE gv_flag.

* after - in at_line_selection( row hide ) of the class
gv_flag = list( )->read_value( get_cursor( )-line ).
`) + "\n\nOften the data the line was written from is the better source: keep it in an internal table and read the row with `HIDE` or `row`.",
  },
  {
    id: "list-control",
    title: "List control without a counterpart: SCROLL LIST, SET USER-COMMAND, print control",
    match: /^(SCROLL LIST|SET USER-COMMAND|NEW-PAGE PRINT ON|PRINT-CONTROL|LEAVE TO LIST-PROCESSING)/,
    why: "The list of the runtime is a page in the browser: it has no scroll position the program sets, raises no user command by itself, and prints through the browser. `LEAVE TO LIST-PROCESSING` is not needed - the list shows after `start_of_selection( )`.",
    rewrite: "Remove the statement. Run what `SET USER-COMMAND` triggered directly (a `PERFORM`), and write the list in `START-OF-SELECTION` instead of switching to list processing from a screen.",
  },
  {
    id: "leave",
    title: "LEAVE PROGRAM, LEAVE TO TRANSACTION, LEAVE TO SCREEN",
    match: /^LEAVE\b.* - the app has no screens or transactions to leave/,
    why: "A browser app has no screens or transactions to leave. `RETURN` ends the event block, `leave_to_selection_screen( )` goes back to the selection screen (`LEAVE LIST-PROCESSING` is converted to it).",
    rewrite: abap(`
* before
IF gt_data IS INITIAL.
  MESSAGE 'Nothing found' TYPE 'S'.
  LEAVE PROGRAM.
ENDIF.

* after
IF gt_data IS INITIAL.
  MESSAGE 'Nothing found' TYPE 'S'.
  LEAVE LIST-PROCESSING.     " converted to leave_to_selection_screen( )
ENDIF.
`),
  },
  {
    id: "perform-foreign",
    title: "PERFORM of another program, dynamic or ON COMMIT",
    match: /^PERFORM of a FORM of another program/,
    why: "A FORM becomes a private method of the class. A FORM of another program is not part of the input, a dynamic name has no method to call, and `ON COMMIT` has no commit to wait for.",
    rewrite: abap(`
* before
PERFORM read_customer IN PROGRAM zcommon USING lv_kunnr.

* after - the routine as a method of a class both reports use
zcl_common=>read_customer( lv_kunnr ).
`),
  },
  {
    id: "perform-mismatch",
    title: "PERFORM that does not fit its FORM",
    match: /^PERFORM \S+( - no FORM| passes|: .* is passed to| - the FORM is a callback)/,
    why: "Each FORM becomes a method with typed parameters, and each PERFORM a call of it. A PERFORM of a FORM that is not in the report, with another number of parameters, or with a literal for a parameter the FORM changes, cannot be written as a call.",
    rewrite: "Make the PERFORM match its FORM: the same number of parameters in `TABLES`, `USING` and `CHANGING`, a variable for every parameter the FORM writes, and the FORM in the report or its includes.",
  },
  {
    id: "reserved-name",
    title: "A name of the runtime: a parameter named like a component of z2ui5_cl_cgui_report",
    match: /is the name of a component of z2ui5_cl_cgui_report/,
    why: "Every global of the report becomes an attribute of the class, which inherits from `z2ui5_cl_cgui_report`. A global with the name of one of its methods or attributes (`list`, `message`, `alv`, `client`, ...) would collide. A global `DATA` or `CONSTANTS` is renamed by the converter (`message` becomes `gv_message`, the migration report says so); a parameter or select-option is not - the text pool and every `SUBMIT ... WITH` know its name.",
    rewrite: "Rename the parameter in the report and in its selection texts, then convert again - for example `list` to `p_list`.",
  },
  {
    id: "local-class",
    title: "A local class that writes the list or uses the report's globals",
    match: /(in a local class - the class has no list|the local class uses .*, a global of the report)/,
    why: "Local classes are carried over into the local types of the generated class. There they cannot reach the report's globals (attributes of the class) or its list and FORMs.",
    rewrite: abap(`
* before
CLASS lcl_calc IMPLEMENTATION.
  METHOD total.
    LOOP AT gt_items INTO DATA(ls).   " gt_items: a global of the report
      rv = rv + ls-amount.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

* after - the global as a parameter
METHODS total IMPORTING it_items TYPE ty_t_items RETURNING VALUE(rv) TYPE p.
...
gv_total = NEW lcl_calc( )->total( gt_items ).
`),
  },
  {
    id: "hide",
    title: "HIDE that cannot be restored",
    match: /^HIDE\b/,
    why: "A `HIDE` field is stored with the line and restored in `at_line_selection( )`. That needs a global field, a `WRITE` before it in the same block (the hotspot it is attached to), and one set of hidden fields for the report.",
    rewrite: "Hide a global field right after the `WRITE` of its line, and hide the same fields wherever the report hides fields - or hide the key of the row and read the row in `AT LINE-SELECTION`.",
  },
  {
    id: "message",
    title: "MESSAGE without a message class, MESSAGE ... RAISING",
    match: /^MESSAGE (without a message class|\.\.\. RAISING)/,
    why: "A class has no `MESSAGE-ID`: the short form `MESSAGE e001` needs the class from `REPORT ... MESSAGE-ID`. `RAISING` raises a classic exception of a FORM or function, which the generated methods do not declare.",
    rewrite: abap(`
* before
REPORT zflights.            " no MESSAGE-ID
...
MESSAGE e001.

* after
MESSAGE e001(zflights).
`),
  },
  {
    id: "screen-loop",
    title: "LOOP AT SCREEN nested, with a field symbol, or with a screen field the runtime does not know",
    match: /^(LOOP AT SCREEN|MODIFY SCREEN outside|SCREEN-\S+ has no counterpart)/,
    why: "`LOOP AT SCREEN` becomes `screen->loop_at_screen( )` in `at_selection_screen_output( screen )` and in the FORMs it performs; in a method of a local class and in other event blocks it is `current_screen( )->loop_at_screen( )` - the screen of AT SELECTION-SCREEN OUTPUT while it runs, elsewhere one built afresh whose changes are not shown. One loop at a time, into a work area. The screen knows `name`, `group1`, `input`, `invisible`, `active`, `required`, `intensified` and `length`.",
    rewrite: abap(`
* after - in AT SELECTION-SCREEN OUTPUT, with a work area
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-group1 = 'EXP'.
      ls_screen-active = 0.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.
`),
  },
  {
    id: "page-events",
    title: "TOP-OF-PAGE and END-OF-PAGE with logic, or twice",
    match: /^(a second (TOP-OF-PAGE|END-OF-PAGE)|(TOP-OF-PAGE|END-OF-PAGE).* with other statements than WRITE)/,
    why: "The runtime records what the header or footer writes once and repeats it on every page. So only a fixed header or footer is converted: `WRITE`, `ULINE`, `SKIP`, `NEW-LINE` and `FORMAT`.",
    rewrite: "Compute what the header needs before the list starts, keep it in a global, and write only that in `TOP-OF-PAGE`. Merge two `TOP-OF-PAGE` blocks into one.",
  },
  {
    id: "selscreen-event-field",
    title: "AT SELECTION-SCREEN ON ... of a field, block or group that does not exist",
    match: /^(ON (VALUE-REQUEST FOR |HELP-REQUEST FOR |BLOCK |END OF |RADIOBUTTON GROUP )?\S+ - no |a second ON (VALUE|HELP)-REQUEST)/,
    why: "The events of the selection screen are methods with a `CASE` on the field, block or group. One that names nothing on the screen has no `WHEN`. A select-option has one F4 for `-LOW` and one for `-HIGH` (`value_request_part( )` tells them apart in one `WHEN`), and one F1 for both.",
    rewrite: "Correct the name, or merge the blocks of the same field (two F4 of `-LOW`, two F1) into one.",
  },
  {
    id: "inline-global",
    title: "An inline declaration of an event block, used in another one, of a type that cannot be told",
    match: /is declared inline in an event block and used in another one/,
    why: "Event blocks open no scope: `DATA(x) = ...` in `INITIALIZATION` is a global of the report, and `START-OF-SELECTION` may use it. In the class it becomes an attribute, which needs its type. The converter takes it from a constructor expression (`NEW lcl( )`, `VALUE ty( )`) or from abaplint's syntax check - not from a method of a class that is not part of the input.",
    rewrite: abap(`
* before
INITIALIZATION.
  DATA(go_app) = zcl_app=>create( ).
START-OF-SELECTION.
  go_app->run( ).

* after
DATA go_app TYPE REF TO zcl_app.
INITIALIZATION.
  go_app = zcl_app=>create( ).
`),
  },
  {
    id: "dynamic-screen-type",
    title: "A field of the selection screen typed at runtime (TYPE (name), FOR (name)) or with a local type",
    match: /is typed (at runtime \(TYPE \(name\) \/ FOR \(name\)\)|with a local type of the report)/,
    why: "Every field of the selection screen becomes a public attribute of the class - typed when the class is written. A name that is fixed - a literal, `FOR ('STRING')`, or a global DATA with a literal VALUE that nothing else names - is converted: the field is typed with it. A type taken from a variable set at runtime has nothing to type it with, and a type of a local class (`lcl_x=>ty_name`) cannot type a public attribute: the local types of a class pool only reach its private section.",
    rewrite: abap(`
* before
PARAMETERS p_value TYPE (p_type).
SELECT-OPTIONS s_vbeln FOR (gv_name).

* after - the type the report really asks for
PARAMETERS p_value TYPE string.
SELECT-OPTIONS s_vbeln FOR vbak-vbeln.
`),
  },
  {
    id: "selscreen",
    title: "SELECTION-SCREEN INCLUDE and other screen statements",
    match: /^(SELECTION-SCREEN INCLUDE|this SELECTION-SCREEN statement|SELECTION-SCREEN TAB)/,
    why: "The selection screen is built by `selection_screen( )` of the class. A screen included from another program is not part of the input, and a tab needs its subscreen in this report as `DEFAULT SCREEN` - the runtime has no subscreen it switches at runtime.",
    rewrite: abap(`
* before
SELECTION-SCREEN TAB (20) tab1 USER-COMMAND uc1.      " tb-dynnr = 101 at runtime

* after
SELECTION-SCREEN TAB (20) tab1 USER-COMMAND uc1 DEFAULT SCREEN 101.
`),
  },
  {
    id: "call-selection-screen",
    title: "CALL SELECTION-SCREEN of a screen the report does not have, or twice",
    match: /^(CALL SELECTION-SCREEN|a second CALL SELECTION-SCREEN)/,
    why: "`CALL SELECTION-SCREEN n` opens the screen of `SELECTION-SCREEN BEGIN OF SCREEN n` of this report as a dialog; the statements after the call go on in `after_call_selection_screen( dynnr subrc )`, once per screen.",
    rewrite: "Declare the screen in the report, and call each screen from one place - put the call into a FORM you `PERFORM` where you need it.",
  },
  {
    id: "submit",
    title: "SUBMIT forms without a counterpart",
    match: /^(SUBMIT \.\.\.|this SUBMIT is not understood)/,
    why: "`SUBMIT ... AND RETURN` starts the class of the called report with `submit( )`. Its list is not in memory (`EXPORTING LIST TO MEMORY`), there is no spool or background job from a browser app, and a class has its standard selection screen and its own variants only.",
    rewrite: abap(`
* before
SUBMIT zflights WITH p_carrid = 'LH' EXPORTING LIST TO MEMORY AND RETURN.
CALL FUNCTION 'LIST_FROM_MEMORY' ...

* after - the data, not the list: a method both reports use
DATA(lt_flights) = zcl_flights=>read( 'LH' ).
`),
  },
  {
    id: "popup",
    title: "Popups with a message, a list or a DDIC check",
    match: /^(CALL FUNCTION 'POPUP_|POPUP_\S+ without)/,
    why: "`POPUP_TO_CONFIRM`, `POPUP_TO_CONFIRM_STEP`, `POPUP_TO_DECIDE` and `POPUP_GET_VALUES` are converted: the block is cut at the call and goes on in `at_user_command( )`. The variants with a T100 message, a list or a DDIC check are not, nor a call without the parameters the popup needs.",
    rewrite: abap(`
* before
CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE' EXPORTING diagnosetext1 = 'Delete?' ...

* after - the converted one
CALL FUNCTION 'POPUP_TO_CONFIRM'
  EXPORTING text_question = 'Delete the selected flights?'
  IMPORTING answer        = lv_answer.
IF lv_answer = '1'.
  PERFORM delete.
ENDIF.
`),
  },
  {
    id: "alv-classic",
    title: "ALV function modules and SALV calls without a counterpart",
    match: /^(CALL FUNCTION '(REUSE_ALV|LVC_)|\S+ without TABLES t_outtab|cl_salv_table=>factory\( \) without|FORM \S+ is the USER_COMMAND callback|FORM \S+: \S+-\S+ has no counterpart|SALV: )/,
    why: "`REUSE_ALV_GRID_DISPLAY` / `REUSE_ALV_LIST_DISPLAY` with `TABLES t_outtab` and `CL_SALV_TABLE` become `alv( )`; a `CL_SALV_TABLE` the report keeps and uses after `display( )` - an attribute of a local class, its event handlers, the rows selected - its stand-in `z2ui5_cl_cgui_salv_table`, which has the table, its columns, settings, functions, selections and events but not the Excel export (`cl_salv_ex_util`, `cl_salv_bs_*`) or the LVC field catalog of `cl_salv_controller_metadata`. A hierarchical list, the ALV popup, the other `REUSE_ALV_*` and `LVC_*` modules and a USER_COMMAND callback that reads more than the row (`rs_selfield-tabindex`), the column of a hotspot (`-fieldname`) and its cell (`-value`) have no counterpart - `-refresh` and the stable flags are dropped, the ALV is drawn anew on every roundtrip.",
    rewrite: abap(`
* before
CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT' EXPORTING i_tabname = 'GT_CARR' ...

* after - an F4 or a value help popup on the table
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_carrid.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'CARRID' value_org = 'S'
    TABLES value_tab = gt_carr.
`),
  },
  {
    id: "alv-grid",
    title: "cl_gui_alv_grid beyond its simple handlers",
    match: /(of cl_gui_alv_grid - no counterpart|handler of the grid|the grid object, is used here|handles events of cl_gui_alv_grid and has other|the toolbar handler|: sender - the grid object|the handler uses me->|set_table_for_first_display\( \) without|has no counterpart in at_(line_selection|link_click|user_command)|MODULE - the report calls more than one screen)/,
    why: "The grid becomes `alv( )` with the field catalog, and the handlers of `DOUBLE_CLICK`, `HOTSPOT_CLICK`, `USER_COMMAND` and `TOOLBAR` become methods of the class. Other events, other methods of the grid and handlers that use the handler object itself (`me`, `sender`) have no counterpart.",
    rewrite: `Keep the handlers to the four events, write the toolbar as buttons appended to \`e_object->mt_toolbar\`, and read the row from \`e_row-index\` / \`e_row_id-index\` only. An editable grid arrives in \`at_data_changed( row column )\` of the class - port a \`DATA_CHANGED\` handler there by hand.`,
  },
  {
    id: "f4",
    title: "F4 outside of the selection screen, search helps",
    match: /^(F4IF_INT_TABLE_VALUE_REQUEST|CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST')/,
    why: "`F4IF_INT_TABLE_VALUE_REQUEST` becomes `value_help_popup( )` in `at_value_request( field )` - an F4 of the selection screen. A search help called by name (`F4IF_FIELD_VALUE_REQUEST`) needs the DDIC, which ABAP Cloud does not have.",
    rewrite: "Read the values into an internal table and call `F4IF_INT_TABLE_VALUE_REQUEST` with `TABLES value_tab` in `AT SELECTION-SCREEN ON VALUE-REQUEST`.",
  },
  {
    id: "dynpro-fields",
    title: "Reading and writing dynpro fields: DYNP_VALUES_*, RS_REFRESH_FROM_SELECTOPTIONS",
    match: /^CALL FUNCTION '(DYNP_VALUES|RS_REFRESH_FROM_SELECTOPTIONS)/,
    why: "On the selection screen of the runtime the fields are the attributes of the class: they hold what the user entered on every roundtrip, so there is nothing to read from the screen. `DYNP_VALUES_READ` and `DYNP_VALUES_UPDATE` with `TABLES dynpfields` are converted - every field name of the table is assigned dynamically (`ASSIGN (fieldname)`); without the table, and `RS_REFRESH_FROM_SELECTOPTIONS`, are not.",
    rewrite: abap(`
* before
CALL FUNCTION 'DYNP_VALUES_READ' ... TABLES dynpfields = lt_fields.
READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'P_CARRID'.

* after
lv_carrid = p_carrid.
`),
  },
  {
    id: "select-short-form",
    title: "SELECT without INTO",
    match: /^SELECT without INTO/,
    why: "The short form reads into the work area of `TABLES dbtab`, which a class does not have.",
    rewrite: abap(`
* before
TABLES sflight.
SELECT * FROM sflight WHERE carrid = p_carrid.
  WRITE: / sflight-connid.
ENDSELECT.

* after
SELECT * FROM sflight INTO @DATA(ls_flight) WHERE carrid = @p_carrid.
  WRITE: / ls_flight-connid.
ENDSELECT.
`),
  },
  {
    id: "declarations",
    title: "TABLES and STATICS in the wrong place, a TABLES parameter without a type",
    match: /^(TABLES inside a FORM|STATICS outside of a FORM|the TABLES parameter \S+ of FORM)/,
    why: "`TABLES` is a global declaration of the report, `STATICS` belongs into a FORM. A `TABLES` parameter used with its header line gets a work area of the method, which needs the line type.",
    rewrite: abap(`
* before
FORM add TABLES tt_log USING iv_text.
  tt_log = iv_text.
  APPEND tt_log.
ENDFORM.

* after
FORM add TABLES tt_log TYPE ty_t_log USING iv_text TYPE string.
`),
  },
  {
    id: "window",
    title: "WINDOW outside of AT LINE-SELECTION",
    match: /^WINDOW outside of AT LINE-SELECTION/,
    why: "`window( )` shows the secondary list a line selection writes in a dialog box - there is no secondary list elsewhere.",
    rewrite: "Move the `WINDOW` statement into `AT LINE-SELECTION`, before the `WRITE`s of the secondary list.",
  },
  {
    id: "function-keys",
    title: "AT PFnn twice, or of a key that does not exist",
    match: /^AT PF\d+ - /,
    why: "`AT PFnn` becomes a `WHEN` of `at_user_command( )` for the keys F1 to Ctrl+Shift+F12 (PF01 to PF48), one block per key.",
    rewrite: "Merge the blocks of the same key; use a key from PF01 to PF48.",
  },
  {
    id: "syntax",
    title: "A statement the parser does not understand, a block without its end",
    match: /^(the parser does not understand|no [A-Z ]+ for this statement)/,
    why: "The converter reads the report with abaplint. A syntax error, a statement of a newer release than the parser knows, or a FORM, MODULE or class without its end stop the conversion.",
    rewrite: "Check the report in the ABAP editor (or with `abaplint`) and correct it, then convert again.",
  },
];

/** the catalogue entry of a refusal message - undefined when none matches */
export function refusalOf(message) {
  return CATALOGUE.find((e) => e.match.test(message));
}

/** the link to the entry's section of docs/refusals.md */
export function refusalLink(entry) {
  return `${DOCS_URL}#${entry.id}`;
}

/** docs/refusals.md - written from the catalogue */
export function refusalsMarkdown() {
  const out = [
    "# What report2cloud refuses - and the rewrite that unblocks it",
    "",
    "<!-- written by `npm run report2cloud:docs` from tools/report2cloud/lib/refusals.mjs - edit the catalogue, not this file -->",
    "",
    "A refused statement has no counterpart in an abap-cloud-gui report. The converter writes no class then (`--partial` writes the draft with a mark at each refusal), and the migration report links each refusal here. Rewrite the statement in the classic report and convert again - the rewrites keep the report a classic report, so it still runs where it ran.",
    "",
    "| Refusal | |",
    "|---|---|",
    ...CATALOGUE.map((e) => `| [${e.title}](#${e.id}) | \`${e.id}\` |`),
    "",
  ];
  for (const e of CATALOGUE) {
    out.push(`<a id="${e.id}"></a>`, "", `## ${e.title}`, "", `**Why.** ${e.why}`, "", "**Rewrite.**", "", e.rewrite.trim(), "");
  }
  return `${out.join("\n").replace(/\n{3,}/g, "\n\n").trim()}\n`;
}
