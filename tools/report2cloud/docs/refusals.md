# What report2cloud refuses - and the rewrite that unblocks it

<!-- written by `npm run report2cloud:docs` from tools/report2cloud/lib/refusals.mjs - edit the catalogue, not this file -->

A refused statement has no counterpart in an abap-cloud-gui report. The converter writes no class then (`--partial` writes the draft with a mark at each refusal), and the migration report links each refusal here. Rewrite the statement in the classic report and convert again - the rewrites keep the report a classic report, so it still runs where it ran.

| Refusal | |
|---|---|
| [Dynpros: CALL SCREEN, MODULE, SET SCREEN, CONTROLS](#dynpro) | `dynpro` |
| [CALL TRANSACTION ... USING and batch input](#call-transaction) | `call-transaction` |
| [Native SQL: EXEC SQL](#native-sql) | `native-sql` |
| [INCLUDE without its file](#include-missing) | `include-missing` |
| [Logical databases: NODES, GET, REJECT, dynamic and free selections](#logical-database) | `logical-database` |
| [Fields of another program: ASSIGN ('(PROG)FIELD')](#foreign-field) | `foreign-field` |
| [The SAP GUI frontend: controls, the frontend services the browser has no counterpart for](#sap-gui) | `sap-gui` |
| [Desktop integration and system calls: OLE, CALL 'C-function', EDITOR-CALL, GENERATE](#desktop) | `desktop` |
| [Reading the list back: READ LINE, MODIFY LINE, GET CURSOR outside of a line selection](#list-read) | `list-read` |
| [List control without a counterpart: SCROLL LIST, SET USER-COMMAND, print control](#list-control) | `list-control` |
| [LEAVE PROGRAM, LEAVE TO TRANSACTION, LEAVE TO SCREEN](#leave) | `leave` |
| [PERFORM of another program, dynamic or ON COMMIT](#perform-foreign) | `perform-foreign` |
| [PERFORM that does not fit its FORM](#perform-mismatch) | `perform-mismatch` |
| [A name of the runtime: a parameter named like a component of z2ui5_cl_cgui_report](#reserved-name) | `reserved-name` |
| [A local class that writes the list or uses the report's globals](#local-class) | `local-class` |
| [HIDE that cannot be restored](#hide) | `hide` |
| [MESSAGE without a message class, MESSAGE ... RAISING](#message) | `message` |
| [LOOP AT SCREEN nested, with a field symbol, or with a screen field the runtime does not know](#screen-loop) | `screen-loop` |
| [TOP-OF-PAGE and END-OF-PAGE with logic, or twice](#page-events) | `page-events` |
| [AT SELECTION-SCREEN ON ... of a field, block or group that does not exist](#selscreen-event-field) | `selscreen-event-field` |
| [An inline declaration of an event block, used in another one, of a type that cannot be told](#inline-global) | `inline-global` |
| [A field of the selection screen typed at runtime (TYPE (name), FOR (name)) or with a local type](#dynamic-screen-type) | `dynamic-screen-type` |
| [SELECTION-SCREEN INCLUDE and other screen statements](#selscreen) | `selscreen` |
| [CALL SELECTION-SCREEN of a screen the report does not have, or twice](#call-selection-screen) | `call-selection-screen` |
| [SUBMIT forms without a counterpart](#submit) | `submit` |
| [Popups with a message, a list or a DDIC check](#popup) | `popup` |
| [ALV function modules and SALV calls without a counterpart](#alv-classic) | `alv-classic` |
| [cl_gui_alv_grid beyond its simple handlers](#alv-grid) | `alv-grid` |
| [F4 outside of the selection screen, search helps](#f4) | `f4` |
| [Reading and writing dynpro fields: DYNP_VALUES_*, RS_REFRESH_FROM_SELECTOPTIONS](#dynpro-fields) | `dynpro-fields` |
| [SELECT without INTO](#select-short-form) | `select-short-form` |
| [TABLES and STATICS in the wrong place, a TABLES parameter without a type](#declarations) | `declarations` |
| [WINDOW outside of AT LINE-SELECTION](#window) | `window` |
| [AT PFnn twice, or of a key that does not exist](#function-keys) | `function-keys` |
| [A statement the parser does not understand, a block without its end](#syntax) | `syntax` |

<a id="dynpro"></a>

## Dynpros: CALL SCREEN, MODULE, SET SCREEN, CONTROLS

**Why.** A dynpro is a screen of the SAP GUI with its own flow logic. A browser app has no screens of that kind: abap-cloud-gui has the selection screen, the list, the ALV and popups. Two kinds of screen are converted. A dynpro of fields - texts, inputs, checkboxes, radio buttons, frames and push buttons, read from the screens abapGit writes into the .prog.xml: the modules become methods, the flow logic `dynpro_pbo( )` and `dynpro_pai( )`, `CALL SCREEN` becomes `call_screen( )` and what follows it `after_call_screen( )`. And the screen of one `cl_gui_alv_grid` - its PBO modules go where `CALL SCREEN` stood, its PAI modules become `at_user_command( )`. A screen with a custom control, a subscreen, a table control or a tabstrip, or flow logic with LOOP or CALL SUBSCREEN, is refused.

**Rewrite.**

Ask the user with the selection screen or a popup, and show the result as a list or an ALV:

```abap
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
```

A screen with a table control, a subscreen or a tabstrip is on the roadmap (Stage 5).

<a id="call-transaction"></a>

## CALL TRANSACTION ... USING and batch input

**Why.** Batch input (`CALL TRANSACTION ... USING`, `BDC_*` sessions) plays the screens of a transaction - there are none in a browser app, and on ABAP Cloud batch input is no API at all. A plain `CALL TRANSACTION` is converted: `call_transaction( )` starts the report class the catalog names.

**Rewrite.**

Call the released API of the application instead of driving its screens:

```abap
* before
CALL TRANSACTION 'VA02' USING gt_bdc MODE 'N'.

* after - the released API, for example the RAP business object of the sales order
MODIFY ENTITIES OF i_salesordertp
  ENTITY salesorder UPDATE FIELDS ( purchaseorderbycustomer )
  WITH VALUE #( ( salesorder = p_vbeln purchaseorderbycustomer = p_bstkd ) ).
COMMIT ENTITIES.
```

To open another app, a converted report can `submit( )` its class or `call_transaction( )` a transaction of the catalog.

<a id="native-sql"></a>

## Native SQL: EXEC SQL

**Why.** Native SQL talks to the database directly. ABAP Cloud has no native SQL, and the generated class is meant to run there.

**Rewrite.**

```abap
* before
EXEC SQL.
  SELECT COUNT(*) INTO :gv_count FROM vbak
ENDEXEC.

* after - ABAP SQL on a released CDS view
SELECT COUNT(*) FROM i_salesdocument INTO @gv_count.
```

<a id="include-missing"></a>

## INCLUDE without its file

**Why.** The includes of a report are inlined before the conversion, from the files beside it as abapGit writes them (`<include>.prog.abap`). An include that is not there cannot be inlined. `INCLUDE x IF FOUND` without a file is dropped, as the compiler drops it.

**Rewrite.**

Put the include beside the report, or name its folder:

```bash
node tools/report2cloud/cli.mjs src/zreport.prog.abap --includes src/includes
```

<a id="logical-database"></a>

## Logical databases: NODES, GET, REJECT, dynamic and free selections

**Why.** A logical database reads the data for the report and adds its own selection screen. There are none on ABAP Cloud.

**Rewrite.**

```abap
* before
NODES spfli.
GET spfli.
  WRITE: / spfli-carrid, spfli-connid.

* after - read the data yourself
SELECT carrid, connid FROM spfli INTO TABLE @DATA(lt_spfli).
LOOP AT lt_spfli INTO DATA(ls_spfli).
  WRITE: / ls_spfli-carrid, ls_spfli-connid.
ENDLOOP.
```

<a id="foreign-field"></a>

## Fields of another program: ASSIGN ('(PROG)FIELD')

**Why.** A field symbol to a field of another program (or of a screen) reaches into memory the class does not share, and ABAP Cloud does not allow it.

**Rewrite.**

Pass the value as a parameter, or read it again from the database. Within the report, a global of the report is an attribute of the class and is reached directly.

<a id="sap-gui"></a>

## The SAP GUI frontend: controls, the frontend services the browser has no counterpart for

**Why.** There is no SAP GUI on the other side: no custom container to put a control in, no file system of the user. A `cl_gui_alv_grid` is converted to `alv( )`. The containers, `cl_gui_textedit`, `cl_gui_html_viewer` and `cl_gui_toolbar` of a report without a grid become stand-ins with the same methods (`z2ui5_cl_cgui_gui*`): a custom control area of a dynpro holds them, the text editor is a text area of the page, the HTML viewer shows its document, the toolbar its buttons. A `cl_gui_alv_grid` of a local class is `z2ui5_cl_cgui_gui_alv_grid`, the ALV of the report in its container - `refresh_table_display( )` is passed the table it shows, which must be in reach. `SET HANDLER` of a handler method of a local class is `set_handler( )`: the stand-in raises `function_selected`, `dropdown_clicked`, `sapevent` and `close` from the browser. Refused are the other controls (pictures, trees), an event a stand-in does not raise, a handler for all instances or a static one, and a member the stand-ins do not have. The files are converted: `cl_gui_frontend_services` is `z2ui5_cl_cgui_frontend` - `file_open_dialog` in an F4 opens an upload in the browser and runs the F4 again with the file, `gui_upload` reads it, `gui_download` is a download of the browser, `GUI_UPLOAD` / `GUI_DOWNLOAD` become its methods. What it does not have - the registry, the GUI version, an option of a method it does not take - is refused.

**Rewrite.**

Remove the call, or write it with what `z2ui5_cl_cgui_frontend` has: the file dialogs, `gui_upload`, `gui_download`, the folders, `execute` of a URL, `clipboard_export`. A control becomes `alv( )` or an abap2UI5 view. A progress indicator is simply dropped.

<a id="desktop"></a>

## Desktop integration and system calls: OLE, CALL 'C-function', EDITOR-CALL, GENERATE

**Why.** OLE automation of desktop programs, kernel calls, the ABAP editor and generated programs belong to the SAP GUI and the classic application server. None of it exists for a browser app or on ABAP Cloud.

**Rewrite.**

Remove the statement, or replace it by what it was used for: a file export for Excel automation, a released API for a kernel call, a class instead of a generated subroutine pool.

<a id="list-read"></a>

## Reading the list back: READ LINE, MODIFY LINE, GET CURSOR outside of a line selection

**Why.** These statements work on the list as the SAP GUI shows it. `GET CURSOR FIELD / VALUE / LINE / OFFSET` in `AT LINE-SELECTION` is converted to `z2ui5_cl_cgui_gui=>get_cursor_field( )`; the runtime has counterparts of the others too - `list( )->read_line( )`, `read_value( )`, `modify_line( )` - but the converter does not map them yet.

**Rewrite.**

```abap
* before
AT LINE-SELECTION.
  READ LINE sy-lilli FIELD VALUE gv_flag.

* after - in at_line_selection( row hide ) of the class
gv_flag = list( )->read_value( get_cursor( )-line ).
```

Often the data the line was written from is the better source: keep it in an internal table and read the row with `HIDE` or `row`.

<a id="list-control"></a>

## List control without a counterpart: SCROLL LIST, SET USER-COMMAND, print control

**Why.** The list of the runtime is a page in the browser: it has no scroll position the program sets, raises no user command by itself, and prints through the browser. `LEAVE TO LIST-PROCESSING` is not needed - the list shows after `start_of_selection( )`.

**Rewrite.**

Remove the statement. Run what `SET USER-COMMAND` triggered directly (a `PERFORM`), and write the list in `START-OF-SELECTION` instead of switching to list processing from a screen.

<a id="leave"></a>

## LEAVE PROGRAM, LEAVE TO TRANSACTION, LEAVE TO SCREEN

**Why.** A browser app has no screens or transactions to leave. `RETURN` ends the event block, `leave_to_selection_screen( )` goes back to the selection screen (`LEAVE LIST-PROCESSING` is converted to it).

**Rewrite.**

```abap
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
```

<a id="perform-foreign"></a>

## PERFORM of another program, dynamic or ON COMMIT

**Why.** A FORM becomes a private method of the class. A FORM of another program is not part of the input, a dynamic name has no method to call, and `ON COMMIT` has no commit to wait for.

**Rewrite.**

```abap
* before
PERFORM read_customer IN PROGRAM zcommon USING lv_kunnr.

* after - the routine as a method of a class both reports use
zcl_common=>read_customer( lv_kunnr ).
```

<a id="perform-mismatch"></a>

## PERFORM that does not fit its FORM

**Why.** Each FORM becomes a method with typed parameters, and each PERFORM a call of it. A PERFORM of a FORM that is not in the report, with another number of parameters, or with a literal for a parameter the FORM changes, cannot be written as a call.

**Rewrite.**

Make the PERFORM match its FORM: the same number of parameters in `TABLES`, `USING` and `CHANGING`, a variable for every parameter the FORM writes, and the FORM in the report or its includes.

<a id="reserved-name"></a>

## A name of the runtime: a parameter named like a component of z2ui5_cl_cgui_report

**Why.** Every global of the report becomes an attribute of the class, which inherits from `z2ui5_cl_cgui_report`. A global with the name of one of its methods or attributes (`list`, `message`, `alv`, `client`, ...) would collide. A global `DATA` or `CONSTANTS` is renamed by the converter (`message` becomes `gv_message`, the migration report says so); a parameter or select-option is not - the text pool and every `SUBMIT ... WITH` know its name.

**Rewrite.**

Rename the parameter in the report and in its selection texts, then convert again - for example `list` to `p_list`.

<a id="local-class"></a>

## A local class that writes the list or uses the report's globals

**Why.** Local classes are carried over into the local types of the generated class. There they cannot reach the report's globals (attributes of the class) or its list and FORMs.

**Rewrite.**

```abap
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
```

<a id="hide"></a>

## HIDE that cannot be restored

**Why.** A `HIDE` field is stored with the line and restored in `at_line_selection( )`. That needs a global field, a `WRITE` before it in the same block (the hotspot it is attached to), and one set of hidden fields for the report.

**Rewrite.**

Hide a global field right after the `WRITE` of its line, and hide the same fields wherever the report hides fields - or hide the key of the row and read the row in `AT LINE-SELECTION`.

<a id="message"></a>

## MESSAGE without a message class, MESSAGE ... RAISING

**Why.** A class has no `MESSAGE-ID`: the short form `MESSAGE e001` needs the class from `REPORT ... MESSAGE-ID`. `RAISING` raises a classic exception of a FORM or function, which the generated methods do not declare.

**Rewrite.**

```abap
* before
REPORT zflights.            " no MESSAGE-ID
...
MESSAGE e001.

* after
MESSAGE e001(zflights).
```

<a id="screen-loop"></a>

## LOOP AT SCREEN nested, with a field symbol, or with a screen field the runtime does not know

**Why.** `LOOP AT SCREEN` becomes `screen->loop_at_screen( )` in `at_selection_screen_output( screen )` and in the FORMs it performs; in a method of a local class and in other event blocks it is `current_screen( )->loop_at_screen( )` - the screen of AT SELECTION-SCREEN OUTPUT while it runs, elsewhere one built afresh whose changes are not shown. One loop at a time, into a work area. The screen knows `name`, `group1`, `input`, `invisible`, `active`, `required`, `intensified` and `length`.

**Rewrite.**

```abap
* after - in AT SELECTION-SCREEN OUTPUT, with a work area
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-group1 = 'EXP'.
      ls_screen-active = 0.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.
```

<a id="page-events"></a>

## TOP-OF-PAGE and END-OF-PAGE with logic, or twice

**Why.** The runtime records what the header or footer writes once and repeats it on every page. So only a fixed header or footer is converted: `WRITE`, `ULINE`, `SKIP`, `NEW-LINE` and `FORMAT`.

**Rewrite.**

Compute what the header needs before the list starts, keep it in a global, and write only that in `TOP-OF-PAGE`. Merge two `TOP-OF-PAGE` blocks into one.

<a id="selscreen-event-field"></a>

## AT SELECTION-SCREEN ON ... of a field, block or group that does not exist

**Why.** The events of the selection screen are methods with a `CASE` on the field, block or group. One that names nothing on the screen has no `WHEN`. A select-option has one F4 for `-LOW` and one for `-HIGH` (`value_request_part( )` tells them apart in one `WHEN`), and one F1 for both.

**Rewrite.**

Correct the name, or merge the blocks of the same field (two F4 of `-LOW`, two F1) into one.

<a id="inline-global"></a>

## An inline declaration of an event block, used in another one, of a type that cannot be told

**Why.** Event blocks open no scope: `DATA(x) = ...` in `INITIALIZATION` is a global of the report, and `START-OF-SELECTION` may use it. In the class it becomes an attribute, which needs its type. The converter takes it from a constructor expression (`NEW lcl( )`, `VALUE ty( )`) or from abaplint's syntax check - not from a method of a class that is not part of the input.

**Rewrite.**

```abap
* before
INITIALIZATION.
  DATA(go_app) = zcl_app=>create( ).
START-OF-SELECTION.
  go_app->run( ).

* after
DATA go_app TYPE REF TO zcl_app.
INITIALIZATION.
  go_app = zcl_app=>create( ).
```

<a id="dynamic-screen-type"></a>

## A field of the selection screen typed at runtime (TYPE (name), FOR (name)) or with a local type

**Why.** Every field of the selection screen becomes a public attribute of the class - typed when the class is written. A name that is fixed - a literal, `FOR ('STRING')`, or a global DATA with a literal VALUE that nothing else names - is converted: the field is typed with it. A type taken from a variable set at runtime has nothing to type it with, and a type of a local class (`lcl_x=>ty_name`) cannot type a public attribute: the local types of a class pool only reach its private section.

**Rewrite.**

```abap
* before
PARAMETERS p_value TYPE (p_type).
SELECT-OPTIONS s_vbeln FOR (gv_name).

* after - the type the report really asks for
PARAMETERS p_value TYPE string.
SELECT-OPTIONS s_vbeln FOR vbak-vbeln.
```

<a id="selscreen"></a>

## SELECTION-SCREEN INCLUDE and other screen statements

**Why.** The selection screen is built by `selection_screen( )` of the class. A screen included from another program is not part of the input, and a tab needs its subscreen in this report as `DEFAULT SCREEN` - the runtime has no subscreen it switches at runtime.

**Rewrite.**

```abap
* before
SELECTION-SCREEN TAB (20) tab1 USER-COMMAND uc1.      " tb-dynnr = 101 at runtime

* after
SELECTION-SCREEN TAB (20) tab1 USER-COMMAND uc1 DEFAULT SCREEN 101.
```

<a id="call-selection-screen"></a>

## CALL SELECTION-SCREEN of a screen the report does not have, or twice

**Why.** `CALL SELECTION-SCREEN n` opens the screen of `SELECTION-SCREEN BEGIN OF SCREEN n` of this report as a dialog; the statements after the call go on in `after_call_selection_screen( dynnr subrc )`, once per screen.

**Rewrite.**

Declare the screen in the report, and call each screen from one place - put the call into a FORM you `PERFORM` where you need it.

<a id="submit"></a>

## SUBMIT forms without a counterpart

**Why.** `SUBMIT ... AND RETURN` starts the class of the called report with `submit( )`. Its list is not in memory (`EXPORTING LIST TO MEMORY`), there is no spool or background job from a browser app, and a class has its standard selection screen and its own variants only.

**Rewrite.**

```abap
* before
SUBMIT zflights WITH p_carrid = 'LH' EXPORTING LIST TO MEMORY AND RETURN.
CALL FUNCTION 'LIST_FROM_MEMORY' ...

* after - the data, not the list: a method both reports use
DATA(lt_flights) = zcl_flights=>read( 'LH' ).
```

<a id="popup"></a>

## Popups with a message, a list or a DDIC check

**Why.** `POPUP_TO_CONFIRM`, `POPUP_TO_CONFIRM_STEP`, `POPUP_TO_DECIDE` and `POPUP_GET_VALUES` are converted: the block is cut at the call and goes on in `at_user_command( )`. The variants with a T100 message, a list or a DDIC check are not, nor a call without the parameters the popup needs.

**Rewrite.**

```abap
* before
CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE' EXPORTING diagnosetext1 = 'Delete?' ...

* after - the converted one
CALL FUNCTION 'POPUP_TO_CONFIRM'
  EXPORTING text_question = 'Delete the selected flights?'
  IMPORTING answer        = lv_answer.
IF lv_answer = '1'.
  PERFORM delete.
ENDIF.
```

<a id="alv-classic"></a>

## ALV function modules and SALV calls without a counterpart

**Why.** `REUSE_ALV_GRID_DISPLAY` / `REUSE_ALV_LIST_DISPLAY` with `TABLES t_outtab` and `CL_SALV_TABLE` become `alv( )`; a `CL_SALV_TABLE` the report keeps and uses after `display( )` - an attribute of a local class, its event handlers, the rows selected - its stand-in `z2ui5_cl_cgui_salv_table`, which has the table, its columns, settings, functions, selections and events but not the Excel export (`cl_salv_ex_util`, `cl_salv_bs_*`) or the LVC field catalog of `cl_salv_controller_metadata`. A hierarchical list, the ALV popup, the other `REUSE_ALV_*` and `LVC_*` modules and a USER_COMMAND callback that reads more than the row (`rs_selfield-tabindex`), the column of a hotspot (`-fieldname`) and its cell (`-value`) have no counterpart - `-refresh` and the stable flags are dropped, the ALV is drawn anew on every roundtrip.

**Rewrite.**

```abap
* before
CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT' EXPORTING i_tabname = 'GT_CARR' ...

* after - an F4 or a value help popup on the table
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_carrid.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'CARRID' value_org = 'S'
    TABLES value_tab = gt_carr.
```

<a id="alv-grid"></a>

## cl_gui_alv_grid beyond its simple handlers

**Why.** The grid becomes `alv( )` with the field catalog, and the handlers of `DOUBLE_CLICK`, `HOTSPOT_CLICK`, `USER_COMMAND` and `TOOLBAR` become methods of the class. Other events, other methods of the grid and handlers that use the handler object itself (`me`, `sender`) have no counterpart.

**Rewrite.**

Keep the handlers to the four events, write the toolbar as buttons appended to `e_object->mt_toolbar`, and read the row from `e_row-index` / `e_row_id-index` only. An editable grid arrives in `at_data_changed( row column )` of the class - port a `DATA_CHANGED` handler there by hand.

<a id="f4"></a>

## F4 outside of the selection screen, search helps

**Why.** `F4IF_INT_TABLE_VALUE_REQUEST` becomes `value_help_popup( )` in `at_value_request( field )` - an F4 of the selection screen. A search help called by name (`F4IF_FIELD_VALUE_REQUEST`) needs the DDIC, which ABAP Cloud does not have.

**Rewrite.**

Read the values into an internal table and call `F4IF_INT_TABLE_VALUE_REQUEST` with `TABLES value_tab` in `AT SELECTION-SCREEN ON VALUE-REQUEST`.

<a id="dynpro-fields"></a>

## Reading and writing dynpro fields: DYNP_VALUES_*, RS_REFRESH_FROM_SELECTOPTIONS

**Why.** On the selection screen of the runtime the fields are the attributes of the class: they hold what the user entered on every roundtrip, so there is nothing to read from the screen. `DYNP_VALUES_READ` and `DYNP_VALUES_UPDATE` with `TABLES dynpfields` are converted - every field name of the table is assigned dynamically (`ASSIGN (fieldname)`); without the table, and `RS_REFRESH_FROM_SELECTOPTIONS`, are not.

**Rewrite.**

```abap
* before
CALL FUNCTION 'DYNP_VALUES_READ' ... TABLES dynpfields = lt_fields.
READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'P_CARRID'.

* after
lv_carrid = p_carrid.
```

<a id="select-short-form"></a>

## SELECT without INTO

**Why.** The short form reads into the work area of `TABLES dbtab`, which a class does not have.

**Rewrite.**

```abap
* before
TABLES sflight.
SELECT * FROM sflight WHERE carrid = p_carrid.
  WRITE: / sflight-connid.
ENDSELECT.

* after
SELECT * FROM sflight INTO @DATA(ls_flight) WHERE carrid = @p_carrid.
  WRITE: / ls_flight-connid.
ENDSELECT.
```

<a id="declarations"></a>

## TABLES and STATICS in the wrong place, a TABLES parameter without a type

**Why.** `TABLES` is a global declaration of the report, `STATICS` belongs into a FORM. A `TABLES` parameter used with its header line gets a work area of the method, which needs the line type.

**Rewrite.**

```abap
* before
FORM add TABLES tt_log USING iv_text.
  tt_log = iv_text.
  APPEND tt_log.
ENDFORM.

* after
FORM add TABLES tt_log TYPE ty_t_log USING iv_text TYPE string.
```

<a id="window"></a>

## WINDOW outside of AT LINE-SELECTION

**Why.** `window( )` shows the secondary list a line selection writes in a dialog box - there is no secondary list elsewhere.

**Rewrite.**

Move the `WINDOW` statement into `AT LINE-SELECTION`, before the `WRITE`s of the secondary list.

<a id="function-keys"></a>

## AT PFnn twice, or of a key that does not exist

**Why.** `AT PFnn` becomes a `WHEN` of `at_user_command( )` for the keys F1 to Ctrl+Shift+F12 (PF01 to PF48), one block per key.

**Rewrite.**

Merge the blocks of the same key; use a key from PF01 to PF48.

<a id="syntax"></a>

## A statement the parser does not understand, a block without its end

**Why.** The converter reads the report with abaplint. A syntax error, a statement of a newer release than the parser knows, or a FORM, MODULE or class without its end stop the conversion.

**Rewrite.**

Check the report in the ABAP editor (or with `abaplint`) and correct it, then convert again.
