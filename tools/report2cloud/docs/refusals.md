# What report2cloud refuses - and the rewrite that unblocks it

<!-- written by `npm run report2cloud:docs` from tools/report2cloud/lib/refusals.mjs - edit the catalogue, not this file -->

A refused statement has no counterpart in an abap-cloud-gui report. The converter writes no class then (`--partial` writes the draft with a mark at each refusal), and the migration report links each refusal here. Rewrite the statement in the classic report and convert again - the rewrites keep the report a classic report, so it still runs where it ran.

| Refusal | |
|---|---|
| [Dynpros: CALL SCREEN, MODULE, SET SCREEN, CONTROLS](#dynpro) | `dynpro` |
| [CALL TRANSACTION and batch input](#call-transaction) | `call-transaction` |
| [Native SQL: EXEC SQL](#native-sql) | `native-sql` |
| [INCLUDE without its file](#include-missing) | `include-missing` |
| [Logical databases: NODES, GET, REJECT, dynamic and free selections](#logical-database) | `logical-database` |
| [Fields of another program: ASSIGN ('(PROG)FIELD')](#foreign-field) | `foreign-field` |
| [The SAP GUI frontend: controls, frontend services, GUI_DOWNLOAD / GUI_UPLOAD](#sap-gui) | `sap-gui` |
| [Desktop integration and system calls: OLE, CALL 'C-function', EDITOR-CALL, GENERATE](#desktop) | `desktop` |
| [Reading the list back: GET CURSOR, READ LINE, MODIFY LINE](#list-read) | `list-read` |
| [List control without a counterpart: SCROLL LIST, SET USER-COMMAND, print control](#list-control) | `list-control` |
| [LEAVE PROGRAM, LEAVE TO TRANSACTION, LEAVE TO SCREEN](#leave) | `leave` |
| [PERFORM of another program, dynamic or ON COMMIT](#perform-foreign) | `perform-foreign` |
| [PERFORM that does not fit its FORM](#perform-mismatch) | `perform-mismatch` |
| [A name of the runtime: a global named like a component of z2ui5_cl_cgui_report](#reserved-name) | `reserved-name` |
| [A local class that writes the list or uses the report's globals](#local-class) | `local-class` |
| [HIDE that cannot be restored](#hide) | `hide` |
| [MESSAGE without a message class, MESSAGE ... RAISING](#message) | `message` |
| [LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT, or with a field symbol](#screen-loop) | `screen-loop` |
| [TOP-OF-PAGE and END-OF-PAGE with logic, or twice](#page-events) | `page-events` |
| [AT SELECTION-SCREEN ON ... of a field, block or group that does not exist](#selscreen-event-field) | `selscreen-event-field` |
| [An inline declaration of an event block, used in another one, of a type that cannot be told](#inline-global) | `inline-global` |
| [A field of the selection screen typed at runtime: TYPE (name), FOR (name)](#dynamic-screen-type) | `dynamic-screen-type` |
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

**Why.** A dynpro is a screen of the SAP GUI with its own flow logic. A browser app has no screens of that kind: abap-cloud-gui has the selection screen, the list, the ALV and popups. The screen of one `cl_gui_alv_grid` is converted - its PBO modules go where `CALL SCREEN` stood, its PAI modules become `at_user_command( )`; any other screen is refused.

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

A module pool with a single screen of fields is on the roadmap (Stage 5).

<a id="call-transaction"></a>

## CALL TRANSACTION and batch input

**Why.** No SAP GUI transaction can be started from a browser app, and batch input (`CALL TRANSACTION ... USING`, `BDC_*` sessions) plays a dynpro - there is none, and on ABAP Cloud batch input is no API at all.

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

To open another app, a converted report can `submit( )` its class.

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

## The SAP GUI frontend: controls, frontend services, GUI_DOWNLOAD / GUI_UPLOAD

**Why.** There is no SAP GUI on the other side: no custom container to put a control in, no frontend to read or write a file on. A `cl_gui_alv_grid` is converted to `alv( )`; the other controls are refused.

**Rewrite.**

Remove the frontend call from the report. A download becomes the export of `alv( )` (CSV or Excel) or an abap2UI5 download in the class, an upload an abap2UI5 file uploader; a control becomes `alv( )` or an abap2UI5 view. A progress indicator is simply dropped.

<a id="desktop"></a>

## Desktop integration and system calls: OLE, CALL 'C-function', EDITOR-CALL, GENERATE

**Why.** OLE automation of desktop programs, kernel calls, the ABAP editor and generated programs belong to the SAP GUI and the classic application server. None of it exists for a browser app or on ABAP Cloud.

**Rewrite.**

Remove the statement, or replace it by what it was used for: a file export for Excel automation, a released API for a kernel call, a class instead of a generated subroutine pool.

<a id="list-read"></a>

## Reading the list back: GET CURSOR, READ LINE, MODIFY LINE

**Why.** These statements work on the list as the SAP GUI shows it. The runtime has counterparts - `get_cursor( )` in `at_line_selection( )`, `list( )->read_line( )`, `read_value( )`, `modify_line( )` - but the converter does not map them yet.

**Rewrite.**

```abap
* before
AT LINE-SELECTION.
  GET CURSOR FIELD lv_field VALUE lv_value.

* after - in at_line_selection( row hide ) of the class
DATA(ls_cursor) = get_cursor( ).
lv_field = ls_cursor-field.
lv_value = ls_cursor-value.
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

## A name of the runtime: a global named like a component of z2ui5_cl_cgui_report

**Why.** Every global of the report becomes an attribute of the class, which inherits from `z2ui5_cl_cgui_report`. A global with the name of one of its methods or attributes (`list`, `message`, `alv`, `client`, ...) would collide.

**Rewrite.**

Rename the global in the report, then convert again - for example `list` to `gt_list`.

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

## LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT, or with a field symbol

**Why.** `LOOP AT SCREEN` becomes `screen->loop_at_screen( )` in `at_selection_screen_output( screen )`, the only place the runtime offers the screen. It knows `name`, `group1`, `input`, `invisible`, `active`, `required`, `intensified` and `length`.

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

**Why.** The events of the selection screen are methods with a `CASE` on the field, block or group. One that names nothing on the screen has no `WHEN`; a select-option has one F4 and one F1 for LOW and HIGH together.

**Rewrite.**

Correct the name, or merge the two blocks of `-LOW` and `-HIGH` into one.

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

## A field of the selection screen typed at runtime: TYPE (name), FOR (name)

**Why.** Every field of the selection screen becomes an attribute of the class - typed when the class is written. A type taken from a variable at runtime has nothing to type it with.

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

**Why.** `REUSE_ALV_GRID_DISPLAY` / `REUSE_ALV_LIST_DISPLAY` with `TABLES t_outtab` and `CL_SALV_TABLE` become `alv( )`. A hierarchical list, the ALV popup, the other `REUSE_ALV_*` and `LVC_*` modules and a USER_COMMAND callback that reads more than the row (`rs_selfield-tabindex`) have no counterpart.

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

**Why.** On the selection screen of the runtime the fields are the attributes of the class: they hold what the user entered on every roundtrip, so there is nothing to read from the screen.

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
