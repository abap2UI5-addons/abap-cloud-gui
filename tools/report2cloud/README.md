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
  --includes <dir> where the report's INCLUDEs are, as abapGit writes them: <include>.prog.abap
                   (default: beside the source; the includes are inlined before the conversion)
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

A grown report is a main program and its includes - the TOP include with the
globals and the selection screen, F01 with the FORMs - and abapGit writes each
include as a `.prog.abap` of its own. The converter reads them from beside the
source (or from `--includes`) and inlines them before the parse, recursively,
so the class holds the whole report; a position in a refusal, a TODO or the
mapping table names the include and its own line. `INCLUDE x IF FOUND.`
without a file is dropped, as the compiler drops it; a plain `INCLUDE` without
a file is refused, naming the file it looked for. Macros (`DEFINE`) are
expanded at every call, wherever they are defined.

### Measuring a code base

```
node tools/report2cloud/coverage.mjs <dir> [<dir> ...] [--includes dir] [--json file]
```

converts every report under the folders in memory - a `.prog.abap` with a
`REPORT` or `PROGRAM` statement; the rest are includes - and prints how many
convert, how many are refused and for which reasons, which objects the
migration reports name as unreleased on ABAP Cloud and what the TODOs are
about, each ranked by the number of reports it touches. Run it on an abapGit
export of the Z reports: the top line of the refusals is the next construct
to map, and the converted share is the number to move. `--json` writes a line
per report for a diff between two runs. A measurement, not a gate - the exit
code is 0 whatever the numbers.

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
| `INCLUDE x` | the include's source, inlined before the parse from `x.prog.abap` beside the report (or `--includes`), recursively; `IF FOUND` without a file is dropped |
| `DEFINE` ... `END-OF-DEFINITION`, a macro call | the statements of the macro at every call, with the spacing of its body; the definition and the call are not carried over |
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
| `DATA itab TYPE x OCCURS n [WITH HEADER LINE]`, `TYPE [STANDARD] TABLE OF x WITH HEADER LINE`, `TYPE ty_tab WITH HEADER LINE` | `DATA itab TYPE STANDARD TABLE OF x WITH DEFAULT KEY` and a work area `wa_itab LIKE LINE OF itab` after it - a global attribute, because the header line of a report is global (one FORM fills it, another appends it); `LIKE` a DDIC table becomes `TYPE` |
| `DATA: BEGIN OF itab OCCURS n, ... END OF itab` | the structure is the work area, `BEGIN OF wa_itab ... END OF wa_itab`, and the table is `DATA itab LIKE STANDARD TABLE OF wa_itab WITH DEFAULT KEY` after it |
| the header line in a statement: `itab-f`, `APPEND itab.`, `COLLECT itab.`, `INSERT itab [INDEX n].`, `MODIFY itab [INDEX n].`, `LOOP AT itab.`, `READ TABLE itab ...` without `INTO`, `CLEAR itab.`, `REFRESH itab.`, `itab[]` | `wa_itab-f`, `APPEND wa_itab TO itab`, `COLLECT wa_itab INTO itab`, `INSERT wa_itab INTO itab INDEX n` (`INDEX sy-tabix` for the short form in a LOOP), `MODIFY itab FROM wa_itab [INDEX n]`, `LOOP AT itab INTO wa_itab`, `READ TABLE itab ... INTO wa_itab`, `CLEAR wa_itab`, `CLEAR itab`, `itab` |
| the bare name where it is the header line: a `MOVE` / assignment, `MOVE-CORRESPONDING`, `SELECT ... INTO itab` (not `INTO TABLE`), `INSERT / UPDATE / MODIFY dbtab FROM itab`, `PERFORM ... USING / CHANGING itab`, `WRITE itab`, a condition, `LIKE itab` | the work area; everywhere else - `LOOP AT`, `READ TABLE`, `SORT`, `DESCRIBE TABLE`, `DELETE`, the `TABLES` of a `PERFORM` or a function, `lines( )`, `IN` - the name is the table, as in a class |
| a table with a header line declared in a FORM | the same, with a work area `ls_itab` declared right after the table |
| a `TABLES` parameter of a FORM used with its header line (`tt-f`, `LOOP AT tt.`, `APPEND tt.`) | a work area `ls_tt` of the method |
| `RANGES r FOR f` | `DATA r TYPE/LIKE RANGE OF f` |
| `SELECTION-SCREEN BEGIN OF BLOCK b [WITH FRAME [TITLE TEXT-001 / field]] [NO INTERVALS]`, `END OF BLOCK` | `screen->block_begin( title )`, `block_end( )`; `name = \`B\`` when an `AT SELECTION-SCREEN ON BLOCK b` names it, `no_intervals` |
| `SELECTION-SCREEN BEGIN OF LINE`, `END OF LINE` | `line_begin( )`, `line_end( )`; a `COMMENT ... FOR FIELD` that opens the line is its label |
| `SELECTION-SCREEN COMMENT ... TEXT-001 / field [MODIF ID m]` | `screen->comment( )` - a field name declares that field (`TYPE c LENGTH n`), set in `initialization( )` as before |
| `SELECTION-SCREEN PUSHBUTTON ... USER-COMMAND u` | `screen->button( text event = )` |
| `SELECTION-SCREEN FUNCTION KEY n` and `sscrfields-functxt_0n = ...` | `screen->function_key( number text icon )` - the text from the assignment (a text, or an `SMP_DYNTXT` with `icon_id`, `icon_text`, `text`), which goes with the `SMP_DYNTXT` variable; the button raises `FC0n`, which arrives in `at_user_command( )` and, when `AT SELECTION-SCREEN` reads `sscrfields-ucomm`, there. Without an assignment the button reads `FC0n` and a TODO says so |
| `SELECTION-SCREEN BEGIN OF TABBED BLOCK tb`, `TAB (n) t USER-COMMAND u DEFAULT SCREEN s`, `END OF BLOCK tb`, `BEGIN OF SCREEN s AS SUBSCREEN` | `screen->tabbed_block_begin( )`, `tab( t )` with the fields of subscreen `s` after it, `tabbed_block_end( )`; `t` is a field (`TYPE c LENGTH n`) set in `initialization( )` as before. The tabs switch in the browser: a click raises no `u`, and `tb-activetab` / `tb-dynnr` are dropped with a TODO |
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
| `AT SELECTION-SCREEN ON HELP-REQUEST FOR p` (or `s-low`/`s-high`) | `at_selection_screen_on_help( field )`, `WHEN OTHERS. super->at_selection_screen_on_help( field ).`; the field gets `help_request = abap_true`, so it has the F1 button whether its data element has documentation or not |
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
| `WRITE [AT] [/][pos][(len)] f [COLOR c] [HOTSPOT [ON/OFF]] [NO-GAP] [UNDER g]` | `write( val pos len no_gap under color hotspot )` on the list, `/` is `new_line( )`; a chained `WRITE:` is one call chain. `pos` and `len` may be fields; `(*)` and `(**)` are dropped with a note. `UNDER g` takes the column `g` was written at - the `WRITE` of `g` gets `name = \`G\`` (the text of a literal). In a line with a position every item stands in a box of its width in characters, so the columns line up whatever the font |
| `WRITE f AS CHECKBOX`, `WRITE i AS ICON` | `write_as_checkbox( )`, `write_as_icon( )`; `icon_okay`, `icon_red_light`, ... become the UI5 icon (`sap-icon://accept`, ...) |
| `COLOR COL_HEADING / COL_KEY / COL_TOTAL / COL_POSITIVE / COL_NEGATIVE ...` | `z2ui5_cl_cgui_list=>cs_color-key / total / positive / negative` |
| `FORMAT COLOR / RESET / HOTSPOT` | applied to the following writes of the method; a `FORMAT COLOR` inside an IF, CASE or loop keeps the color in `lv_color` at runtime and every write passes it |
| `NEW-LINE`, `SKIP [n]`, `ULINE`, `NEW-PAGE [NO-HEADING] [LINE-COUNT n]` | `list( )->new_line( )`, `skip( n )`, `uline( )`, `new_page( no_heading line_count )` - the runtime repeats the `TOP-OF-PAGE` header on the new page by itself |
| `POSITION n`, `SKIP TO LINE n`, `RESERVE n LINES` | `list( )->position( n )`, `skip_to_line( n )`, `reserve( n )` |
| `sy-colno`, `sy-linno`, `sy-lsind` | `list( )->current_column( )`, `list( )->current_line( )`, `lsind( )` |
| `sy-lsind = n` in `AT LINE-SELECTION` | `set_lsind( n )` - the list written becomes level `n`, the levels above `n - 1` are dropped, so Back returns to level `n - 1`; outside of `AT LINE-SELECTION` a TODO |
| `WINDOW STARTING AT x1 y1 [ENDING AT x2 y2]` in `AT LINE-SELECTION` | `window( columns = x2 - x1 lines = y2 - y1 )` - the secondary list in a dialog box; outside of `AT LINE-SELECTION` refused |
| `WRITE f TO g` | `g = \|{ f }\|.` and a TODO (user formats) |
| `cl_salv_table=>factory( IMPORTING r_salv_table = o CHANGING t_table = t )` ... `o->display( )` | `alv( t )` at the place of `display( )`, with `set_title( )` (`set_list_header`), `set_column_text( )` (`set_long/medium/short_text`, the longest wins), `set_column_hidden( )` (`set_visible( abap_false )`, `set_technical( )`), `set_line_selection( )` (`SET HANDLER ... get_event( )`, with a TODO for the handler's code). The `REF TO cl_salv_*` variables, `get_columns( )` / `get_column( )` assignments and `TRY ... CATCH cx_salv_*` are removed |
| `REUSE_ALV_GRID_DISPLAY` / `REUSE_ALV_LIST_DISPLAY` with `TABLES t_outtab = t` | `alv( t )`, `i_grid_title` is `set_title( )`, a field catalog built with `wa-fieldname`, `wa-seltext_*`, `wa-no_out`, `APPEND wa TO fcat` or `APPEND VALUE #( ) TO fcat` gives column texts and hidden columns; `REUSE_ALV_FIELDCATALOG_MERGE`, the layout and a FORM that only built them are dropped, as is the `IF sy-subrc` after the call |
| `cl_gui_alv_grid` in a container (`cl_gui_custom_container`, `cl_gui_docking_container`, `cl_gui_container=>default_screen`), `set_table_for_first_display( CHANGING it_outtab = t it_fieldcatalog = f EXPORTING is_layout = l )` | `alv( t )` with the LVC field catalog (`fieldname`, `coltext` / `scrtext_*`, `no_out`, `hotspot` as `set_column_hotspot( )`, `do_sum` as `set_column_sum( )`) and `grid_title` of the layout as `set_title( )`. The grid, the container and the handler object go, with their `CREATE OBJECT`, `SET HANDLER`, `refresh_table_display( )` and the other tuning calls; an `IF go_container IS INITIAL` keeps the branch that creates the grid |
| `CALL SCREEN n` with the grid, `MODULE ... OUTPUT`, `MODULE ... INPUT` | the PBO modules in place of `CALL SCREEN` - the grid shows when the event block is done; the PAI modules are `at_user_command( ucomm )` with the OK code field as `ucomm` (`CLEAR ok_code` and `save_ok = ok_code` go, `LEAVE TO SCREEN 0` / `SET SCREEN 0` are `leave_to_selection_screen( )`). One screen per report; statements after `CALL SCREEN` get a TODO |
| the handler class of the grid (`METHODS ... FOR EVENT ... OF cl_gui_alv_grid`) | its methods become methods of the report class: `DOUBLE_CLICK` `at_line_selection( )` (`e_row-index` is `row`, the chain gets `set_line_selection( )`), `HOTSPOT_CLICK` `at_link_click( row column )`, `USER_COMMAND` `at_user_command( )` (`e_ucomm` is `ucomm`), `TOOLBAR` the buttons appended to `e_object->mt_toolbar` as `add_function( )` in the chain. `get_selected_rows( IMPORTING et_index_rows = r )` is `get_selected_rows( )` of the runtime, the chain gets `set_selection_mode( )`; `LVC_T_ROW` / `LVC_T_ROID` become the row types of `z2ui5_cl_cgui_alv` |
| `i_callback_user_command = 'USER_COMMAND'` | `set_line_selection( )`, and the callback FORM is the body of `at_line_selection( )`: its ucomm is `&IC1`, `rs_selfield-tabindex` is `row` |
| `MESSAGE 'text' / TEXT-001 / v TYPE t` | `message( text type )`, `S` without type |
| `MESSAGE e001(cls) WITH ...`, `MESSAGE ID ... TYPE ... NUMBER ... WITH ...` | `MESSAGE ... INTO DATA(lv_message).` `message( text = lv_message type = )` - the message class stays the source of the text |
| `MESSAGE ... TYPE 'E' / 'A'` | followed by `RETURN` - the classic message ended the event block |
| `MESSAGE ... TYPE 'S'/'I' DISPLAY LIKE 'E'` | type `W` (in the popover, the run goes on) |
| `MESSAGE ... INTO` | copied; the short form `MESSAGE s013 ... INTO` gets the message class of `MESSAGE-ID` (`s013(zr2c)`) - a class has no `MESSAGE-ID` |
| `FORM f TABLES t STRUCTURE s USING [VALUE(]u[)] TYPE x CHANGING c TYPE y` | private method `f IMPORTING u CHANGING t c`: a `USING` parameter the FORM writes becomes `CHANGING`; `TABLES` gets a table type of its own (`ty_t_s`); an untyped parameter is `TYPE any` with a TODO |
| `PERFORM f TABLES ... USING ... CHANGING ...` | `f( a )`, `f( p1 = a p2 = b )` or `f( EXPORTING ... CHANGING ... )` with the parameter names of the FORM |
| `LEAVE LIST-PROCESSING` | `leave_to_selection_screen( )` |
| `SUBMIT report WITH p = v WITH s IN range WITH s op v [SIGN x] WITH SELECTION-TABLE t [VIA SELECTION-SCREEN] [USING SELECTION-SET v] AND RETURN` | `submit( report = the class values = VALUE #( ... ) via_selection_screen = using_variant = )` - the class of a report beside the input (or in the corpus), else the name report2cloud would give it and a TODO to convert it; `p = v` is a parameter value, every other comparison a range line, `IN range` the lines of `range_lines_get( )`, `WITH SELECTION-TABLE` those of `selection_table_get( )` - the runtime takes the kind from the attribute of the called class. Back returns to the caller; statements after the `SUBMIT` run before the called class starts (a TODO) |
| `SUBMIT report ...` without `AND RETURN` | `submit( )` and `RETURN` - the classic ended the caller |
| `SELECTION-SCREEN BEGIN OF SCREEN n [AS WINDOW] [TITLE t]` ... `END OF SCREEN n` | `selection_screen_dynnr( dynnr screen )`, `CASE dynnr. WHEN \`n\`.` with the fields' chain; the screen is a dialog either way |
| `CALL SELECTION-SCREEN n [STARTING AT x y]` | `call_selection_screen( dynnr title )`. The dialog opens when the method returns, so the statements after the call, in the same branch (also inside a `WHEN` or `IF`), go on in `after_call_selection_screen( dynnr subrc )` - `sy-subrc` of the `IF` right after the call is `subrc` (0 confirmed, 4 cancelled); a call inside a loop, in a FORM, or with statements after the block it stands in gets a TODO instead |
| `CALL FUNCTION 'POPUP_TO_CONFIRM'` (`TEXT_QUESTION`, `TEXT_BUTTON_1/2`, `TITLEBAR`, `ANSWER`), `POPUP_TO_CONFIRM_STEP` (`TEXTLINE1/2`, `TITEL`), `POPUP_TO_DECIDE` (`TEXTLINE1/2/3`, `TEXT_OPTION1/2`, `TITEL`) | `popup_to_decide( question options ucomm title )` - the two buttons are the options, the answers `1`, `2` and `A` the classic ones (`J`, `N`, `A` for `POPUP_TO_CONFIRM_STEP`, switched in the continuation). The popup opens when the method returns and its answer arrives in `at_user_command( )` with a ucomm of its own (`POPUP_1`, `POPUP_2`, ...), so the statements after the call in its branch are cut off and go on there, `answer = popup_answer( )` first; an `IF sy-subrc` right after the call, which checked the `EXCEPTIONS`, is dropped. Inside a loop, in a FORM, or with statements after the block the call stands in, nothing is cut: a TODO says where to go on. Local data the continuation reads is declared anew there, with a TODO (a value set before the popup is not there) |
| `CALL FUNCTION 'POPUP_GET_VALUES'` (`TABLES fields` of `SVAL`, `POPUP_TITLE`, `RETURNCODE`) | `popup_get_values_sval( sval ucomm title )` - `FIELDNAME` is the field, `FIELDTEXT` its label, `VALUE` the start value, `FIELD_OBL` required; the continuation in `at_user_command( )` starts with `returncode = SWITCH #( popup_answer( ) WHEN 'A' THEN 'A' ELSE space )` and `popup_values_sval( CHANGING sval = fields )`, which writes what the user entered back into the table (and fills an empty one) |
| `STOP` | `RETURN` - in `START-OF-SELECTION` the runtime goes on with `end_of_selection( )`, as after the classic `STOP`; in a FORM it only leaves the method (a TODO) |
| `sy-lisel` in `AT LINE-SELECTION` | `lisel( )` |
| `sy-pagno` | `z2ui5_cl_cgui_list=>cv_page` in `TOP-OF-PAGE` / `END-OF-PAGE`, `list( )->current_page( )` elsewhere |
| `sy-repid`, `sy-cprog` | the name of the report as a literal (`'ZR2C_06_DYNAMIC'`) - in a class they name the class pool, and the transpiled runtime has none |
| `x [NOT] IN range` in a condition (`IF`, `CHECK`, `WHILE`, `xsdbool( )`, ...) | `z2ui5_cl_cgui_context=>range_check( val = x range = range ) = abap_true` - the transpiled runtime's `IN` knows `I EQ`, `E EQ` and `I CP` only (AGENTS.md); ABAP SQL keeps its `IN`, a value list `IN ( a, b )` stays |
| `LOOP AT t INTO wa WHERE ... IN range ...` | `LOOP AT t INTO wa.` with `IF <the condition on wa> = abap_false. CONTINUE. ENDIF.` (also `ASSIGNING` and `REFERENCE INTO`) and a TODO about `sy-subrc` |
| a FORM parameter `TYPE p` (generic) | `LIKE` the data object every `PERFORM` passes, else kept with a TODO - the transpiled runtime has no generic packed type and fails to describe the class |
| `SET PF-STATUS 'S' [EXCLUDING f]` | `set_pf_status( functions shortcuts excluding )` - the buttons of the application toolbar of status `S` with their text, icon (the UI5 icon of the `ICON_` name, where the converter knows one) and tooltip, and the function keys of the status as keyboard shortcuts (`F5`, `Shift+F2`, ...), read from the GUI status abapGit writes into the `.prog.xml` (`<CUA>`); Back, Exit, Cancel, Choose, print and the page keys are the runtime's own. Every function arrives in `at_user_command( )` with its code. `EXCLUDING` leaves out a function (a literal or a table of codes); `SET PF-STATUS space` empties the toolbar. Without the `.prog.xml`, for a status named by a field or `OF PROGRAM`, a TODO |
| `SET TITLEBAR 'T' [WITH a b ...]` | `set_title( )` with the text of title `T` from the `.prog.xml`, `&1` ... `&9` (and a bare `&`, in turn) replaced by the values in a string template; without the `.prog.xml` a TODO |
| `AT PFnn` | a `WHEN \`PFnn\`` of `at_user_command( )`; without a `SET PF-STATUS` in the report `initialization( )` sets a toolbar with a button per key and the key (`F5`, `Shift+F1` for `PF13`, ...) as a shortcut, as the standard list status had them |
| local classes and interfaces | `.clas.locals_imp.abap`; their definitions go to `.clas.locals_def.abap` when the class is typed with them |
| ABAP SQL (`SELECT`, `INSERT`, `UPDATE`, `MODIFY`, `DELETE` on the database) | strict mode, as ABAP Cloud requires: host variables escaped with `@`, the field list, `ORDER BY` and `GROUP BY` separated by commas - syntax only, the parser tells a host variable from a column |
| everything else | copied as written, comments included (`*` comments become `"` comments) |

## Refused

Every refusal has its section in [docs/refusals.md](docs/refusals.md) - why it has no counterpart, and the rewrite in the classic report that unblocks it; the migration report links each refusal there. The page is written from `lib/refusals.mjs` (`npm run report2cloud:docs`).

Each of these stops the conversion with `file:row:col` and the reason; all of
them are collected, so one run lists everything there is to do.

| Construct | Why |
|---|---|
| `CALL SCREEN`, `MODULE`, `SET SCREEN`, `LEAVE TO SCREEN`, `CALL SUBSCREEN`, `CONTROLS` - but for the screen of one `cl_gui_alv_grid` | dynpros have no counterpart in a browser app |
| `SELECTION-SCREEN INCLUDE`, `SET CURSOR`, a `TAB` without `DEFAULT SCREEN` of this report | not converted; abap-cloud-gui has `set_cursor_field( )` - port them by hand. A tab whose subscreen the program sets at runtime (`tb-dynnr`) has no counterpart |
| `CALL SELECTION-SCREEN n` of a screen the report does not declare, a second call of the same screen with statements after it | the class calls the screens of `selection_screen_dynnr( )`, and `after_call_selection_screen( )` goes on after one call per screen |
| `SUBMIT ... EXPORTING LIST TO MEMORY`, `TO SAP-SPOOL`, `VIA JOB`, `WITH-FREE SELECTIONS`, `USING SELECTION-SCREEN n` / `SELECTION-SETS OF PROGRAM` | the list of the called report is not in memory, there is no spool and no job from a browser app; the class has its standard selection screen and its own variants only |
| `AT SELECTION-SCREEN ON BLOCK b` / `ON RADIOBUTTON GROUP g` / `ON END OF s` of a block, group or select-option the report does not declare | |
| `CALL TRANSACTION` (with or without `USING` - batch input) | no SAP GUI transaction can be started; call the released API instead |
| `EXEC SQL` | native SQL is not available on ABAP Cloud |
| `ASSIGN ('(PROG)FIELD')`, `LOOP AT SCREEN ASSIGNING` | field symbols to screen or foreign program fields |
| `LOOP AT SCREEN` / `MODIFY SCREEN` outside of `AT SELECTION-SCREEN OUTPUT`, `screen-group2`, `screen-intensified`, ... read in a condition | only the screen of `at_selection_screen_output( screen )` and its six fields exist (an assignment to another field is dropped with a TODO) |
| `TOP-OF-PAGE` / `TOP-OF-PAGE DURING LINE-SELECTION` / `END-OF-PAGE` with more than output | the runtime writes header and footer once and repeats them on every page; only a fixed one is converted |
| `GET CURSOR`, `READ LINE`, `MODIFY LINE` | not converted - abap-cloud-gui has `get_cursor( )`, `list( )->read_line( )` / `modify_line( )`; port them by hand |
| `SCROLL LIST`, `SET USER-COMMAND`, `NEW-PAGE PRINT ON`, `PRINT-CONTROL` | the list has no scroll position or print control |
| a global of the report named like a method or attribute of `z2ui5_cl_cgui_report` (`tree`, `format`, `window`, ...) | the global becomes an attribute of the class - rename it in the source first |
| `LEAVE TO LIST-PROCESSING`, `LEAVE PROGRAM`, `LEAVE TO TRANSACTION` | the list is shown after `start_of_selection( )`; there is nothing to leave |
| `NODES`, `GET`, `REJECT` | logical databases |
| `INCLUDE` without its file beside the report | the include was not found as `<include>.prog.abap` - put it there, or name its folder with `--includes` |
| `SELECT` without `INTO` | the short form reads into the `TABLES` work area, which classes do not have |
| a `TABLES` parameter without a type used with its header line | a work area needs a line type - give the parameter a `STRUCTURE` or a table `TYPE` |
| `MESSAGE` without message class, `MESSAGE ... RAISING` | |
| `PERFORM ... IN PROGRAM`, `PERFORM f(prog)`, `IF FOUND`, `ON COMMIT`, a `PERFORM` whose parameters do not match the FORM, a literal passed to a parameter the FORM changes | only FORMs of this report, called as methods |
| `POPUP_TO_CONFIRM_WITH_MESSAGE`, `POPUP_TO_DECIDE_WITH_MESSAGE`, `POPUP_TO_DECIDE_LIST`, `POPUP_GET_VALUES_DB_CHECKED` | the popups with a T100 message, a list or a DDIC check - `popup_to_decide( )` / `popup_get_values( )` and `at_user_command( )` by hand; the four plain ones are converted (see the mapping) |
| `GUI_DOWNLOAD`, `GUI_UPLOAD`, `cl_gui_frontend_services` and the SAP GUI controls but `cl_gui_alv_grid` | there is no SAP GUI frontend and no dynpro container |
| the `DATA_CHANGED` and other handlers of the grid but the four above, a method of `cl_gui_alv_grid` without a counterpart, a handler class with other methods, a handler that uses `me->` or `sender` | an edited cell arrives in `at_data_changed( row column )` - port these by hand |
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
| `coverage.mjs` | the measurement over a folder of reports |
| `lib/convert.mjs` | the converter |
| `lib/includes.mjs` | the INCLUDEs of a report, inlined from the files beside it, with where every line came from |
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
  events, the tables with a header line of a report of 2003 (`OCCURS`,
  `WITH HEADER LINE`, `BEGIN OF ... OCCURS`, the short forms, a `TABLES`
  parameter used with its header line, a FORM's own table), a report in three pieces (a TOP include with the globals, the
  selection screen and a macro, an F01 include with the FORMs, an `IF FOUND`
  include that is not there - the includes lie beside it the way abapGit
  writes them, a `.prog.abap` without a `REPORT` statement is no report of the
  corpus), reports that call reports (`SUBMIT ... WITH ... AND RETURN` of
  another report of the corpus, a selection screen of the report's own called
  as a dialog, `WITH SELECTION-TABLE`, a `SUBMIT` without `AND RETURN`), the
  synchronous popups of a report that posts something (`POPUP_TO_DECIDE` in
  `AT LINE-SELECTION`, `POPUP_TO_CONFIRM` with its `EXCEPTIONS` check inside
  a `WHEN`, `POPUP_GET_VALUES` in a FORM), the GUI status of a list (`SET
  PF-STATUS` with its buttons and function keys in the `.prog.xml`,
  `EXCLUDING` a table and a literal, `SET TITLEBAR ... WITH`), an evaluation
  that lives by the column (`WRITE AT pos(len)`, `UNDER`, `NO-GAP`,
  `POSITION`, `RESERVE`, `sy-linno` / `sy-colno`) with a drilldown over three
  levels (`WINDOW`, `sy-lsind` read and set), a `cl_gui_alv_grid` in a
  custom container on screen 100 with an LVC field catalog, a handler class
  for `DOUBLE_CLICK`, `HOTSPOT_CLICK`, `TOOLBAR` and `USER_COMMAND` and the
  PBO and PAI modules, the selection screen of a grown report (a tabbed
  block on two subscreens, two function keys - one with an icon - and an
  own F1) - and one with `CALL SCREEN`, batch input, native SQL and dynpro
  modules that must be refused. A report `zr2c_NN_name` becomes the class
  `z2ui5_cl_cgui_r2c_NN`, a name the repository's `object_naming` accepts.
- `test/convert.test.mjs` - the snapshots of every generated file and
  migration report (`test/snapshots/`), the abapGit format of the files, the
  determinism, and the mapping table and the refusals construct by construct.
- `test/cli.test.mjs` - the command line, its files and exit codes, `--includes`,
  and the coverage script over the corpus.
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
