# report2cloud

**A classic ABAP report, converted into an abap-cloud-gui report class.**

ABAP Cloud has no `REPORT`, no `PARAMETERS`, no `WRITE` and no ALV, and a
company with a few thousand Z reports cannot rewrite them by hand.
abap-cloud-gui keeps the programming model of a report:
`z2ui5_cl_cgui_report` has the event blocks as methods, and `write( )`,
`alv( )` and `message( )` as calls. That makes the step from a report to a
class mechanical, and this tool does it. The parser is
[`@abaplint/core`](https://github.com/abaplint/abaplint), the same parser the
ecosystem lints with.

```bash
npm run report2cloud -- zflights.prog.abap --out src/02
# or
node tools/report2cloud/cli.mjs zflights.prog.abap [--class zcl_flights] [--out dir]
```

The tool is **deterministic**: the same report gives the same class, byte for
byte. It **refuses rather than guesses**: a statement that has no counterpart
in a browser app (`CALL SCREEN`, a dynpro module, batch input, `SUBMIT`, native
SQL, ...) is reported with `file:row:col` and the reason, the way cap2UI5's
`abap2js` refuses, and no class is written. Everything else in the report -
its logic - is copied as it is written.

### The converter of this repository

report2cloud is THE converter of abap-cloud-gui: the repository has no ABAP
tooling of its own any more (no in-system converter, no selection screen
painter - everything under `src/` is ABAP Cloud ready, transpilable and
downportable, and a converter that reads reports from a system is not). It
runs in Node without an SAP system on the `.prog.abap` files of an abapGit
export, parses with abaplint, refuses what it cannot map with `file:row:col`
instead of passing it through, writes abapGit files and a migration report,
and its output is gated in CI (the abaplint gates, the abap2UI5 linter and
the runtime test) - for one report or a batch, in a pipeline or an AI loop.

## Usage

```
node tools/report2cloud/cli.mjs <report.prog.abap> [options]

  --class <name>   name of the generated class (default: zcl_ + the report name)
  --out <dir>      output folder (default: the current folder)
  --texts <file>   the report's .prog.xml with its text pool (default: beside the source)
  --report <file>  where to write the migration report (default: <out>/<class>.migration.md)
  --check          lint the class with abaplint - v750 and ABAP Cloud, in a scratch
                   copy of this repository (needs git and network for the dependencies)
  --ddic <dir>     abapGit DDIC objects to resolve on-premise tables during --check
  --partial        write the class even when statements are refused
```

| Exit code | |
|---|---|
| 0 | converted |
| 1 | wrong call - unknown option, missing file |
| 2 | refused - every refusal on stderr as `file:row:col - reason`, the migration report lists them, no class written (`--partial` writes the draft with the refused statements marked) |

It writes, in abapGit format (BOM in the XML, LF, no trailing blanks, at most
255 characters per line - the abap2UI5 skill `abap-check`):

| File | |
|---|---|
| `<class>.clas.abap` | the report class |
| `<class>.clas.xml` | its sidecar, described with the title of the report |
| `<class>.clas.locals_def.abap`, `.locals_imp.abap` | the local classes and interfaces of the report, if it has any |
| `<class>.migration.md` | the migration report: refusals, TODOs, the objects to check for ABAP Cloud, abaplint's findings (with `--check`), what was not carried over, and every mapped construct with its line |

The selection texts, text symbols and the title live in the text pool, not in
the source. abapGit serializes them into `<report>.prog.xml`; when that file
lies beside the source (or is given with `--texts`) the class gets the real
texts, otherwise placeholders and a TODO each.

## An example

```abap
REPORT zr2c_02_flights MESSAGE-ID zr2c.
TABLES sflight.
DATA: gt_flight TYPE STANDARD TABLE OF ty_flight, gs_flight TYPE ty_flight.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_carrid LIKE sflight-carrid OBLIGATORY DEFAULT 'LH'.
SELECT-OPTIONS: s_fldate FOR sflight-fldate.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  s_fldate-sign = 'I'. s_fldate-option = 'BT'.
  s_fldate-low = sy-datum. s_fldate-high = sy-datum + 90.
  APPEND s_fldate.

START-OF-SELECTION.
  SELECT carrid connid fldate FROM sflight INTO TABLE gt_flight
    WHERE carrid = p_carrid AND fldate IN s_fldate.
  LOOP AT gt_flight INTO gs_flight.
    WRITE: / gs_flight-carrid HOTSPOT, gs_flight-connid, gs_flight-fldate.
    HIDE: gs_flight-carrid, gs_flight-connid.
  ENDLOOP.

AT LINE-SELECTION.
  MESSAGE i003 WITH gs_flight-carrid gs_flight-connid.
```

becomes (abbreviated - the full class is
[test/snapshots/zr2c_02_flights](test/snapshots/zr2c_02_flights)):

```abap
CLASS z2ui5_cl_cgui_r2c_02 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gt_flight TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY,
      gs_flight TYPE ty_flight.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.
    DATA s_fldate TYPE RANGE OF sflight-fldate.
  ...
  METHOD initialization.

    DATA ls_s_fldate LIKE LINE OF s_fldate.

    set_title( `Flights of an Airline` ).
    p_carrid = 'LH'.

    ls_s_fldate-sign   = 'I'.
    ...
    APPEND ls_s_fldate TO s_fldate.

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Flights`
        )->parameter( val        = p_carrid
                      obligatory = abap_true
        )->select_option( val  = s_fldate
                          text = `Flight date`
        )->block_end( ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_flight,
           gs_flight.

    SELECT carrid, connid, fldate
      FROM sflight
      INTO TABLE @gt_flight
      WHERE carrid = @p_carrid
        AND fldate IN @s_fldate.
    LOOP AT gt_flight INTO gs_flight.
      list( )->new_line(
          )->write( val     = gs_flight-carrid
                    hotspot = abap_true
                    hide    = |{ gs_flight-carrid }\t{ gs_flight-connid }|
          )->write( gs_flight-connid
          )->write( gs_flight-fldate ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the fields the clicked line was written with
    SPLIT hide AT |\t| INTO TABLE DATA(lt_hide).
    gs_flight-carrid = VALUE #( lt_hide[ 1 ] OPTIONAL ).
    gs_flight-connid = VALUE #( lt_hide[ 2 ] OPTIONAL ).

    MESSAGE i003(zr2c) WITH gs_flight-carrid gs_flight-connid INTO DATA(lv_message).
    message( text = lv_message
             type = `I` ).

  ENDMETHOD.
```

and the migration report says what is left: `SFLIGHT` is not released on ABAP
Cloud (successor hint: `/DMO/FLIGHT` or a CDS view of your own), the message
class `ZR2C` must exist in the target system.

## The mapping

| Classic | abap-cloud-gui |
|---|---|
| `REPORT` / `PROGRAM` | the class, `INHERITING FROM z2ui5_cl_cgui_report`; `MESSAGE-ID` is the class of every short `MESSAGE e001`; the title of the text pool is `set_title( )`; `LINE-COUNT n` is `set_line_count( n )` in `initialization( )` - the runtime counts the lines of the list without header and footer, the classic `n` counted them too (noted) |
| `PARAMETERS p TYPE/LIKE ...` | a PUBLIC attribute and `screen->parameter( )`; `LIKE` a DDIC field becomes `TYPE`, `p(10)` / `TYPE c LENGTH 10` / `DECIMALS` are kept |
| `... DEFAULT v` | `p = v.` at the top of `initialization( )` |
| `... OBLIGATORY`, `MODIF ID m`, `NO-DISPLAY` | `obligatory`, `modif_id`, `no_display` |
| `... AS LISTBOX VISIBLE LENGTH n [USER-COMMAND u]`, `MEMORY ID pid`, `VALUE CHECK`, `MATCHCODE OBJECT h` | `as_listbox`, `visible_length`, `user_command`, `memory_id`, `value_check`, `matchcode` (a TODO for `MATCHCODE`: the runtime reads the search help from the DDIC, which ABAP Cloud does not have) |
| `... AS CHECKBOX [USER-COMMAND u]` | `TYPE abap_bool`, `screen->checkbox( user_command = )` |
| `... RADIOBUTTON GROUP g [USER-COMMAND u]` | `TYPE abap_bool`, `screen->radiobutton( group = user_command = )`; the first button of a group is selected unless one has `DEFAULT 'X'` |
| `... LOWER CASE` | `lower_case = abap_true` - without it the runtime converts the input of a character field to upper case, as the classic screen does |
| `SELECT-OPTIONS s FOR f` | `DATA s TYPE/LIKE RANGE OF f` and `screen->select_option( )`, with `OBLIGATORY`, `MODIF ID`, `NO-DISPLAY`, `NO INTERVALS`, `NO-EXTENSION`, `LOWER CASE`, `MEMORY ID`, `VISIBLE LENGTH`, `MATCHCODE OBJECT`; `DEFAULT a [TO b] [OPTION o] [SIGN s]` is a `VALUE #( )` in `initialization( )` |
| the header line of a select-option or `RANGES` (`s-low = ...`, `APPEND s.`, `LOOP AT s.`, `CLEAR s.`, `s[]`) | a work area `ls_s` of the method, `APPEND ls_s TO s`, `LOOP AT s INTO ls_s`, ... |
| `RANGES r FOR f` | `DATA r TYPE/LIKE RANGE OF f` |
| `SELECTION-SCREEN BEGIN OF BLOCK b [WITH FRAME [TITLE TEXT-001 / field]] [NO INTERVALS]`, `END OF BLOCK` | `screen->block_begin( title )`, `block_end( )`; `name = \`B\`` when an `AT SELECTION-SCREEN ON BLOCK b` names it, `no_intervals` |
| `SELECTION-SCREEN BEGIN OF LINE`, `END OF LINE` | `line_begin( )`, `line_end( )`; a `COMMENT ... FOR FIELD` that opens the line is its label |
| `SELECTION-SCREEN COMMENT ... TEXT-001 / field [MODIF ID m]` | `screen->comment( )` - a field name declares that field (`TYPE c LENGTH n`), set in `initialization( )` as before |
| `SELECTION-SCREEN PUSHBUTTON ... USER-COMMAND u` | `screen->button( text event = )` |
| `SELECTION-SCREEN SKIP / ULINE / POSITION` | dropped (the form lays out the fields) |
| text symbols `TEXT-001`, `'text'(001)` | the text of the text pool as a literal; a TODO when it is unknown |
| selection texts | `text =` of the field; none for a text taken from the DDIC (the screen shows the DDIC label as well) |
| `TABLES dbtab` | dropped when it only typed select-options and parameters; otherwise `DATA dbtab TYPE dbtab` and a TODO. `TABLES sscrfields` is dropped |
| global `DATA`, `TYPES`, `CONSTANTS` (also those inside event blocks, which are global in a report) | PUBLIC attributes, types and constants - PUBLIC because `alv( )` binds a PUBLIC table directly, and the draft persists no PRIVATE attributes (AGENTS.md). `DATA ... TYPE [STANDARD] TABLE OF x` without a key gets `WITH DEFAULT KEY` written out - the same table, said (the abap2UI5 linter's `default-key-table`) |
| the restart of the report after its list | `start_of_selection( )` begins with a `CLEAR` of the global data (its `VALUE` where it has one): the classic report started every run afresh, the class keeps its attributes from one Execute to the next. Left alone are the selection screen and what `INITIALIZATION`, `LOAD-OF-PROGRAM`, `AT SELECTION-SCREEN ...` and the FORMs they call use |
| global `FIELD-SYMBOLS` | declared in each method that uses them |
| `TYPE-POOLS` | dropped |
| `INITIALIZATION`, `LOAD-OF-PROGRAM` | `initialization( )` |
| `AT SELECTION-SCREEN OUTPUT` | `at_selection_screen_output( screen )` |
| `LOOP AT SCREEN` ... `MODIFY SCREEN` ... `ENDLOOP` | `DATA(lt_screen) = screen->loop_at_screen( ).` `LOOP AT lt_screen INTO DATA(ls_screen).` ... `screen->modify_screen( ls_screen ).` - `screen-name/group1/active/input/required/invisible` become `ls_screen-*`, `'0'`/`'1'` become `abap_false`/`abap_true`, `'S_X-LOW'` becomes `'S_X'` |
| `AT SELECTION-SCREEN ON p` | `at_selection_screen_on( field )`, `CASE field. WHEN \`P\`.` |
| `AT SELECTION-SCREEN ON BLOCK b` | `at_selection_screen_on_block( block )`, `CASE block. WHEN \`B\`.` - a TODO when the block holds another block (the runtime raises the event for the blocks that hold fields themselves) |
| `AT SELECTION-SCREEN ON RADIOBUTTON GROUP g` | `at_selection_screen_on_radio( group )`, `CASE group. WHEN \`G\`.` - an error marks the first button |
| `AT SELECTION-SCREEN ON END OF s` | `at_selection_screen_on_end_of( field )`, `CASE field. WHEN \`S\`.` - the multiple selection left with OK; an error opens it again |
| `AT SELECTION-SCREEN ON EXIT-COMMAND` | `at_selection_screen_on_exit( ucomm )`, `sy-ucomm` is `ucomm` - `CGUI_BACK`, not `BACK` / `%EX` / `RW` (a TODO when the block reads it) |
| `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p` (or `s-low`/`s-high`) | `at_value_request( field )`, `WHEN OTHERS. super->at_value_request( field ).`; the field gets `value_help = abap_true` |
| `F4IF_INT_TABLE_VALUE_REQUEST` with `retfield` and `value_tab` | `value_help_popup( tab = col = )` - the popup writes the picked value into the field |
| `AT SELECTION-SCREEN` | `at_selection_screen( )`. When it reads `sy-ucomm` / `sscrfields-ucomm`, its body becomes `at_selection_screen_ucomm( ucomm )`, called by `at_selection_screen( )` with `ONLI` and by `at_user_command( )` with the user command - a push button or `USER-COMMAND` runs it as in the classic report |
| `START-OF-SELECTION`, statements before the first event | `start_of_selection( )` |
| `END-OF-SELECTION` | `end_of_selection( )` - the runtime runs it after `start_of_selection( )`, also after its `RETURN` or `STOP`, and not after an error message, as the classic runtime did |
| `TOP-OF-PAGE` (only `WRITE`, `ULINE`, `SKIP`, `NEW-LINE`, `FORMAT`) | `top_of_page( )`: the runtime writes the header when the list gets its first line - a run that writes nothing else shows no list, as in the classic report - and repeats it on every page (`NEW-PAGE`, `LINE-COUNT`). It is written once: `sy-pagno` becomes `z2ui5_cl_cgui_list=>cv_page` (`&PAGE&`, the number of the page), any other field keeps the value of the first page (a TODO) |
| `TOP-OF-PAGE DURING LINE-SELECTION` (only output) | `top_of_page_line_selection( )` - the header of every secondary list |
| `END-OF-PAGE` (only output) | with `LINE-COUNT n(m)`: `end_of_page( )`, the footer the runtime writes at the end of every page - the last one too, a TODO (the classic event ran when a page was full). Without footer lines the classic event never ran: dropped with a TODO |
| `AT LINE-SELECTION` | `at_line_selection( row hide )`; `sy-lilli` / `sy-curow` become `row` |
| `HIDE f` | `hide = f` at the hotspot of the line it follows (the first write of the line becomes the hotspot if it has none); several fields are joined with a tab. `at_line_selection( )` restores them into their fields first, as the classic HIDE does |
| `AT USER-COMMAND` | `at_user_command( ucomm )`; `sy-ucomm` becomes `ucomm` |
| `WRITE [/] [pos(len)] f [COLOR c] [HOTSPOT [ON/OFF]]` | `write( val color hotspot )` on the list, `/` is `new_line( )`; a chained `WRITE:` is one call chain. Positions and lengths are dropped |
| `WRITE f AS CHECKBOX`, `WRITE i AS ICON` | `write_as_checkbox( )`, `write_as_icon( )`; `icon_okay`, `icon_red_light`, ... become the UI5 icon (`sap-icon://accept`, ...) |
| `COLOR COL_HEADING / COL_KEY / COL_TOTAL / COL_POSITIVE / COL_NEGATIVE ...` | `z2ui5_cl_cgui_list=>cs_color-key / total / positive / negative` |
| `FORMAT COLOR / RESET / HOTSPOT` | applied to the following writes of the method; a `FORMAT COLOR` inside an IF, CASE or loop keeps the color in `lv_color` at runtime and every write passes it |
| `NEW-LINE`, `SKIP [n]`, `ULINE`, `NEW-PAGE [NO-HEADING] [LINE-COUNT n]` | `list( )->new_line( )`, `skip( n )`, `uline( )`, `new_page( no_heading line_count )` - the runtime repeats the `TOP-OF-PAGE` header on the new page by itself |
| `WRITE f TO g` | `g = \|{ f }\|.` and a TODO (user formats) |
| `cl_salv_table=>factory( IMPORTING r_salv_table = o CHANGING t_table = t )` ... `o->display( )` | `alv( t )` at the place of `display( )`, with `set_title( )` (`set_list_header`), `set_column_text( )` (`set_long/medium/short_text`, the longest wins), `set_column_hidden( )` (`set_visible( abap_false )`, `set_technical( )`), `set_line_selection( )` (`SET HANDLER ... get_event( )`, with a TODO for the handler's code). The `REF TO cl_salv_*` variables, `get_columns( )` / `get_column( )` assignments and `TRY ... CATCH cx_salv_*` are removed |
| `REUSE_ALV_GRID_DISPLAY` / `REUSE_ALV_LIST_DISPLAY` with `TABLES t_outtab = t` | `alv( t )`, `i_grid_title` is `set_title( )`, a field catalog built with `wa-fieldname`, `wa-seltext_*`, `wa-no_out`, `APPEND wa TO fcat` or `APPEND VALUE #( ) TO fcat` gives column texts and hidden columns; `REUSE_ALV_FIELDCATALOG_MERGE`, the layout and a FORM that only built them are dropped, as is the `IF sy-subrc` after the call |
| `i_callback_user_command = 'USER_COMMAND'` | `set_line_selection( )`, and the callback FORM is the body of `at_line_selection( )`: its ucomm is `&IC1`, `rs_selfield-tabindex` is `row` |
| `MESSAGE 'text' / TEXT-001 / v TYPE t` | `message( text type )`, `S` without type |
| `MESSAGE e001(cls) WITH ...`, `MESSAGE ID ... TYPE ... NUMBER ... WITH ...` | `MESSAGE ... INTO DATA(lv_message).` `message( text = lv_message type = )` - the message class stays the source of the text |
| `MESSAGE ... TYPE 'E' / 'A'` | followed by `RETURN` - the classic message ended the event block |
| `MESSAGE ... TYPE 'S'/'I' DISPLAY LIKE 'E'` | type `W` (in the popover, the run goes on) |
| `MESSAGE ... INTO` | copied; the short form `MESSAGE s013 ... INTO` gets the message class of `MESSAGE-ID` (`s013(zr2c)`) - a class has no `MESSAGE-ID` |
| `FORM f TABLES t STRUCTURE s USING [VALUE(]u[)] TYPE x CHANGING c TYPE y` | private method `f IMPORTING u CHANGING t c`: a `USING` parameter the FORM writes becomes `CHANGING`; `TABLES` gets a table type of its own (`ty_t_s`); an untyped parameter is `TYPE any` with a TODO |
| `PERFORM f TABLES ... USING ... CHANGING ...` | `f( a )`, `f( p1 = a p2 = b )` or `f( EXPORTING ... CHANGING ... )` with the parameter names of the FORM |
| `LEAVE LIST-PROCESSING` | `leave_to_selection_screen( )` |
| `STOP` | `RETURN` - in `START-OF-SELECTION` the runtime goes on with `end_of_selection( )`, as after the classic `STOP`; in a FORM it only leaves the method (a TODO) |
| `sy-lisel` in `AT LINE-SELECTION` | `lisel( )` |
| `sy-pagno` | `z2ui5_cl_cgui_list=>cv_page` in `TOP-OF-PAGE` / `END-OF-PAGE`, `list( )->current_page( )` elsewhere |
| `sy-repid`, `sy-cprog` | the name of the report as a literal (`'ZR2C_06_DYNAMIC'`) - in a class they name the class pool, and the transpiled runtime has none |
| `x [NOT] IN range` in a condition (`IF`, `CHECK`, `WHILE`, `xsdbool( )`, ...) | `z2ui5_cl_cgui_context=>range_check( val = x range = range ) = abap_true` - the transpiled runtime's `IN` knows `I EQ`, `E EQ` and `I CP` only (AGENTS.md); ABAP SQL keeps its `IN`, a value list `IN ( a, b )` stays |
| `LOOP AT t INTO wa WHERE ... IN range ...` | `LOOP AT t INTO wa.` with `IF <the condition on wa> = abap_false. CONTINUE. ENDIF.` (also `ASSIGNING` and `REFERENCE INTO`) and a TODO about `sy-subrc` |
| a FORM parameter `TYPE p` (generic) | `LIKE` the data object every `PERFORM` passes, else kept with a TODO - the transpiled runtime has no generic packed type and fails to describe the class |
| `SET PF-STATUS`, `SET TITLEBAR` | dropped with a TODO - the GUI status is not part of the input; `set_pf_status( functions = )` and `set_title( )` take them by hand |
| local classes and interfaces | `.clas.locals_imp.abap`; their definitions go to `.clas.locals_def.abap` when the class is typed with them |
| ABAP SQL (`SELECT`, `INSERT`, `UPDATE`, `MODIFY`, `DELETE` on the database) | strict mode, as ABAP Cloud requires: host variables escaped with `@`, the field list, `ORDER BY` and `GROUP BY` separated by commas - syntax only, the parser tells a host variable from a column |
| everything else | copied as written, comments included (`*` comments become `"` comments) |

## Refused

Each of these stops the conversion with `file:row:col` and the reason; all of
them are collected, so one run lists everything there is to do.

| Construct | Why |
|---|---|
| `CALL SCREEN`, `MODULE`, `SET SCREEN`, `LEAVE TO SCREEN`, `CALL SUBSCREEN`, `CONTROLS` | dynpros have no counterpart in a browser app |
| `CALL SELECTION-SCREEN`, `SELECTION-SCREEN BEGIN OF SCREEN / TABBED BLOCK / INCLUDE / FUNCTION KEY`, `SET CURSOR` | only the standard selection screen is converted; abap-cloud-gui has `call_selection_screen( )` with `selection_screen_dynnr( )`, tabbed blocks, `function_key( )` and `set_cursor_field( )` - port them by hand |
| `AT SELECTION-SCREEN ON HELP-REQUEST` | `at_selection_screen_on_help( )` runs from the F1 button, which a field only has when its data element has documentation - the block would not run for the other fields |
| `AT SELECTION-SCREEN ON BLOCK b` / `ON RADIOBUTTON GROUP g` / `ON END OF s` of a block, group or select-option the report does not declare | |
| `CALL TRANSACTION` (with or without `USING` - batch input) | no SAP GUI transaction can be started; call the released API instead |
| `SUBMIT` (also `AND RETURN`) | the other report is not part of the input - convert it too and start its class with `submit( report = values = )` |
| `EXEC SQL` | native SQL is not available on ABAP Cloud |
| `ASSIGN ('(PROG)FIELD')`, `LOOP AT SCREEN ASSIGNING` | field symbols to screen or foreign program fields |
| `LOOP AT SCREEN` / `MODIFY SCREEN` outside of `AT SELECTION-SCREEN OUTPUT`, `screen-group2`, `screen-intensified`, ... read in a condition | only the screen of `at_selection_screen_output( screen )` and its six fields exist (an assignment to another field is dropped with a TODO) |
| `TOP-OF-PAGE` / `TOP-OF-PAGE DURING LINE-SELECTION` / `END-OF-PAGE` with more than output | the runtime writes header and footer once and repeats them on every page; only a fixed one is converted |
| `GET CURSOR`, `READ LINE`, `MODIFY LINE`, `WINDOW` | not converted - abap-cloud-gui has `get_cursor( )`, `list( )->read_line( )` / `modify_line( )` and `window( )`; port them by hand |
| `AT PFnn`, `SCROLL LIST`, `SET USER-COMMAND`, `NEW-PAGE PRINT ON`, `PRINT-CONTROL` | the list has no function keys, scroll position or print control |
| a global of the report named like a method or attribute of `z2ui5_cl_cgui_report` (`tree`, `format`, `window`, ...) | the global becomes an attribute of the class - rename it in the source first |
| `LEAVE TO LIST-PROCESSING`, `LEAVE PROGRAM`, `LEAVE TO TRANSACTION` | the list is shown after `start_of_selection( )`; there is nothing to leave |
| `NODES`, `GET`, `REJECT` | logical databases |
| `INCLUDE`, `DEFINE` / macro calls | the include is not part of the input, macros are not expanded - inline them first |
| a table with header line (`OCCURS`, `WITH HEADER LINE`), a `TABLES` parameter used as work area, `SELECT` without `INTO` | not allowed in classes |
| `MESSAGE` without message class, `MESSAGE ... RAISING` | |
| `PERFORM ... IN PROGRAM`, `PERFORM f(prog)`, `IF FOUND`, `ON COMMIT`, a `PERFORM` whose parameters do not match the FORM, a literal passed to a parameter the FORM changes | only FORMs of this report, called as methods |
| `CALL FUNCTION 'POPUP_TO_CONFIRM'` / `POPUP_TO_DECIDE` / `POPUP_GET_VALUES` | the popup waits for the answer; in abap2UI5 it is asynchronous - `popup_to_confirm( )` / `popup_to_decide( )` / `popup_get_values( )` and `at_user_command( )` |
| `GUI_DOWNLOAD`, `GUI_UPLOAD`, `cl_gui_frontend_services`, `cl_gui_alv_grid` and the other SAP GUI controls | there is no SAP GUI frontend and no dynpro container |
| other `REUSE_ALV_*` / `LVC_*` function modules, `F4IF_INT_TABLE_VALUE_REQUEST` outside of an F4, `DYNP_VALUES_READ` / `_UPDATE`, `BDC_*` | |
| a local class that reads a global of the report, or calls `PERFORM` or `WRITE` | a local class of the generated class cannot reach the report's attributes, FORMs or list |
| `GENERATE SUBROUTINE POOL`, `INSERT REPORT`, OLE, contexts, ... | not available |

## What is left for a person, or the AI step

A converted class compiles against abap-cloud-gui on premise - the tests
prove that for the corpus with the repository's own abaplint rules. What it
does not do by itself is run on **ABAP Cloud**, because the logic of the
report still reads the tables and calls the APIs it read and called before:

- **Unreleased tables and APIs.** The migration report lists every database
  table, DDIC type, function module, class and message class the class uses,
  with its first position in the generated class and, for the well-known
  ones, the released successor as a hint (`MARA` → `I_Product`, `KNA1` →
  `I_Customer`, `BKPF` → `I_JournalEntry`, `SFLIGHT` → `/DMO/FLIGHT`, ...).
  Replacing them is not a syntax transformation: a CDS view has other field
  names, other keys, sometimes another granularity. That is the job of a
  person, or of an AI model with the migration report as its work list.
- **TODOs.** Selection texts the source does not carry, ALV layout options
  without a counterpart, `WRITE TO` formats, `STOP` in a FORM, a
  `TOP-OF-PAGE` with fields that is written once instead of per page, ...
- **Behaviour.** Positions and formats of `WRITE`, the page length of
  `LINE-COUNT`, the validations of `AT SELECTION-SCREEN` on every user
  command - the migration report names what was not carried over.

### The AI loop

The conversion is deterministic so that the step after it can be iterative:

1. `report2cloud` writes the class and the migration report - the work list.
2. The model replaces one unreleased object (or works one TODO) at a time.
3. Three checkers answer, without an SAP system:
   - abaplint with the **ABAP Cloud** config (`--check`, or `npm run
     check:cloud` with the class in `src/`) - released APIs and strict syntax;
   - the **abap2UI5 linter** (`npx abap2ui5lint`) - the views against the
     UI5 1.71 floor;
   - the **transpiled abap2UI5 backend** - the behaviour, pinned before the
     change: ABAP Unit (as `unit.yaml` runs the tests of this repository), or
     the report operated through its screen the way
     `test/runtime/runtime.test.mjs` does it for the corpus.
4. Repeat until all three are clean and the work list is empty.

The refusals stay with a person: they are the places where the report does
something a browser app does not do, and the answer is a design decision.

## How it works

`lib/convert.mjs` parses the report with `@abaplint/core` - the version this
repository's abaplint CLI bundles, so the converter and the gates read ABAP
alike - and cuts it into units: the global declarations (wherever they stand),
the event blocks, the FORMs and the local classes. A first pass looks at the
whole report - the FORMs and their parameters, which `TABLES` work areas the
code uses, the ALV (settings are often made in another FORM than the one that
displays), the user commands of the screen. Then every unit is written
statement by statement: the statements of the mapping table are rewritten,
everything else is copied token by token with the spacing it had, and single
tokens rewritten (`TEXT-001`, `sy-ucomm`, `screen-active`, an icon). The class
is indented with abaplint's own pretty printer rules, the lines of a statement
kept relative to its first line, and its call chains follow the house layout
of the samples: one call per line, the parameters aligned.

| File | |
|---|---|
| `cli.mjs` | the command line |
| `lib/convert.mjs` | the converter |
| `lib/abap.mjs` | helpers over the syntax tree, the token renderer |
| `lib/textpool.mjs` | the text pool of a `.prog.xml` |
| `lib/abapgit.mjs` | the `.clas.xml` and the abapGit format of the source |
| `lib/report.mjs` | the migration report |
| `lib/gate.mjs` | abaplint over generated classes in a scratch copy of the repository |

## Tests

```bash
npm run test:report2cloud
UPDATE_SNAPSHOTS=1 node --test tools/report2cloud/test/convert.test.mjs   # after an intended change - review the diff
npm run test:report2cloud:runtime                                          # the classes run - opt-in, see below
```

- `test/corpus/` - classic reports written to exercise the mapping table: a
  hello world, a list with `TOP-OF-PAGE`, colors, `HIDE` and a drilldown, an
  order simulation in FORMs, a `CL_SALV_TABLE` grid, a `REUSE_ALV_GRID_DISPLAY`
  with a field catalog and a callback, a dynamic selection screen with `MODIF
  ID`, `USER-COMMAND`, `LOOP AT SCREEN`, a push button and an own F4, every
  form of `MESSAGE`, the list statements, local classes, legacy statements,
  pages (`LINE-COUNT`, `TOP-OF-PAGE` with `sy-pagno`, `END-OF-PAGE`,
  `NEW-PAGE NO-HEADING`, `TOP-OF-PAGE DURING LINE-SELECTION`) with the
  `AT SELECTION-SCREEN ON BLOCK / RADIOBUTTON GROUP / END OF / EXIT-COMMAND`
  events - and one with `CALL SCREEN`, batch input, `SUBMIT`, native SQL and dynpro
  modules that must be refused. A report `zr2c_NN_name` becomes the class
  `z2ui5_cl_cgui_r2c_NN`, a name the repository's `object_naming` accepts.
- `test/convert.test.mjs` - the snapshots of every generated file and
  migration report (`test/snapshots/`), the abapGit format of the files, the
  determinism, and the mapping table and the refusals construct by construct.
- `test/cli.test.mjs` - the command line, its files and exit codes.
- `test/abaplint.test.mjs` - **every generated class must compile**: the
  classes are linted in a scratch copy of this repository with its own
  configs. With `abaplint.jsonc` (v750, every rule the repository enforces)
  there must be no finding in a generated class - the flight tables of the corpus exist on
  premise, `test/ddic/` has stubs of them. With the ABAP Cloud config every
  finding must be about an object the migration report lists as not released,
  and the reports that use none must be clean. With the 7.02 gate
  (`.github/abaplint/abap_702.jsonc`, as `check-702.sh` runs it: the copy is
  downported with `abaplint --fix`, the popups beside it) and with the
  **abap2UI5 linter** (`abap2ui5lint.jsonc`, `--all-classes` - a report class
  builds no view of its own, the ABAP rules apply) there must be no finding
  in a generated class. Findings in `src/` itself are the business of the
  repository's own gates (`npm run check`); the test reports their number as
  a diagnostic. abaplint clones the dependencies of the configs, so the test
  needs git and network.
- `test/runtime/runtime.test.mjs` - **every generated class must run** - a
  golden master lite: the corpus is converted, the classes are transpiled
  with `src/01` (its tables and data elements included - the variant and
  layout stores) and the popups against `@abap2ui5/node-runtime` at the
  release `abaplint.jsonc` pins, and served on loopback. `test/ddic/` is
  transpiled with them; the boot creates the tables from the transpiler's own
  schema and inserts the rows of `test/runtime/seed.mjs` (the flight tables,
  dates relative to today, and the messages of `ZR2C` in `T100`). Every report
  is then operated as a user operates it - start, fill the selection screen,
  Execute, click a hotspot or a grid row, go back and run again - through the
  JSON protocol of the UI5 frontend, and the answers are read semantically:
  the agent snapshot (fields, actions, tables, messages) and the list line by
  line. The expectations are written by hand: what the classic report prints
  for the seeded rows. It reuses the abap2UI5 MCP server as a library - its
  npm backend (`lib/npm-backend.mjs`: the runtime install, open-abap-core,
  the import rewrite) and its app client (`lib/appclient.mjs`,
  `lib/snapshot.mjs`) - from a checkout at `MCP_SERVER_HOME` or
  `../mcp-server`; without one every test is skipped with the reason. The
  runtime is installed into `A2UI5_MCP_WORKSPACE` (default `~/.abap2ui5-mcp`,
  the MCP server's), the popups come from `POPUPS_HOME`, `.deps/popups`,
  `../popups` or a clone into `build/popups`. About 20 s on a warm workspace;
  `REPORT2CLOUD_RUNTIME_PORT` (default 4481) is the port,
  `REPORT2CLOUD_RUNTIME_KEEP=1` keeps the build (`<runtime>/.r2c-*`).

  What the runtime found that the lint did not: global data that grew from
  one Execute to the next, END-OF-SELECTION skipped after a RETURN, a
  TOP-OF-PAGE header shown as a list of its own, `MESSAGE s013 ... INTO`
  without its message class, `sy-repid`, a generic `TYPE p` parameter and
  `IN` on a select-option - each is a row of the mapping table now
  (END-OF-SELECTION and TOP-OF-PAGE are events of `z2ui5_cl_cgui_report`
  since). When the runtime began to convert the input of a character field
  to upper case, it found the `LOWER CASE` the converter had dropped. One gap
  is the runtime's own and stays a TODO test: `round( val dec = 2 )` is not
  implemented in `@abaplint/runtime`.

CI runs all of it in `.github/workflows/report2cloud.yaml` - the runtime test
as a job of its own, with mcp-server cloned beside the repository.
