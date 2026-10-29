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
  --deps <dir>     the classes, interfaces and DDIC objects of a repository the report reads, as
                   abapGit writes them - they type what the report reads of them; once per
                   repository, e.g. a library the report's repository is installed beside
                   (always: the abapGit repository the report is in: STARTING_FOLDER of its
                   .abapgit.xml, or its git repository)
  --report <file>  where to write the migration report (default: <out>/<class>.migration.md)
  --check          lint the class with abaplint - v750 and ABAP Cloud, in a scratch
                   copy of this repository (needs git and network for the dependencies)
  --ddic <dir>     abapGit DDIC objects to resolve on-premise tables during --check
  --atc <file>     the ATC findings of the report as the system found them (the worklist XML
                   ADT exports, or a CSV with line;priority;check;message): the migration
                   report says for each what the conversion did on its line
  --partial        write the class even when statements are refused
  --wrappers       a CALL FUNCTION the converter has no counterpart for calls a method of a
                   wrapper class, written beside the class: <class>_fmw, to type and release
  --successors     a SELECT of a table with a released successor whose columns map one to one
                   reads the successor, the columns under their old names
```

With `--atc`, the migration report takes the findings of the ABAP Test
Cockpit of the classic report, as a system found them. That is typically the
cloud readiness check variant, exported from ADT as the worklist XML; a CSV
with a header of line, priority, check and message is read too
(`lib/atc.mjs`). Each finding is set against what the conversion did on its
line:
- **converted**: the statement is mapped, and the class has its counterpart.
- **refused**: rewrite the statement first.
- **TODO**: the class has the statement, to finish by hand.
- **to check**: the line went over as it was. The finding stands, unless the
  object it names is in the table of the release state.

A finding in an include goes to its line in the inlined source; one in an
include the conversion did not inline is "to check". The ATC of the system
on the class is the final word. The report puts the findings to do first:
refused, then to check.

With `--successors`, a `SELECT` of a table whose released successor has the
same columns under other names (`lib/successors.mjs`: SCARR, SPFLI, SFLIGHT,
SBOOK and SCUSTOM onto the ABAP Flight Reference Scenario, T001, T005T and
MAKT onto I_CompanyCode, I_CountryText and I_ProductDescription) reads the
successor: the table, the columns of the field list under their old names
(`carrier_id AS carrid`), those of `WHERE`, `ORDER BY` and `GROUP BY`. The
target of `INTO` stays as it is. Only when every column the statement names
has its counterpart, from one table without a join; `SELECT *` and a column
without one keep the table, with a TODO. The types of the targets stay
those of the old table - type them with the successor.

With `--wrappers`, a function module the converter does not map - a Z one,
or one of SAP that is not released - is called through a wrapper class, as
the clean core model has it: `<class>_fmw` gets one static method per
function module, with the parameters as the report passes them (EXPORTING
becomes IMPORTING, TABLES CHANGING) and its EXCEPTIONS, and calls the
function module as it is; the report class calls the method, `sy-subrc`
stays. The wrapper stays in a classic package. Its parameters are generic -
a person types them as the function module does (SE37) and releases the
class for ABAP Cloud; the migration report still names the function module,
in the wrapper.

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
| `<class>.migration.md` | the migration report: refusals, TODOs, the objects to check for ABAP Cloud, abaplint's findings (with `--check`), the ATC findings of the report and what became of them (with `--atc`), what was not carried over, and every mapped construct with its line |

The selection texts, text symbols and the title live in the text pool, not in
the source. abapGit serializes them into `<report>.prog.xml`; when that file
lies beside the source (or is given with `--texts`) the class gets the real
texts, otherwise placeholders and a TODO each.

A grown report is a main program and its includes - the TOP include with the
globals and the selection screen, F01 with the FORMs - and abapGit writes each
include as a `.prog.abap` of its own. The converter reads them from beside the
source (or from `--includes`) and inlines them before the parse, recursively,
so the class holds the whole report; a position in a refusal, a TODO or the
mapping table names the include and its own line. The chained
`INCLUDE: a, b, c.` is inlined include by include. `INCLUDE x IF FOUND.`
without a file is dropped, as the compiler drops it; a plain `INCLUDE` without
a file is refused, naming the file it looked for. The classes, interfaces and DDIC
objects of the report's repository (`--deps`) are parsed beside it, never
converted: they tell the types of what the report reads of them - a
`DATA(lo_log) = zcl_app_factory=>create_logger( )` in INITIALIZATION, read in
START-OF-SELECTION, is an attribute `TYPE REF TO zcl_app_log` of the class,
where without them its type cannot be told and the statement is refused. A
library the repository is installed beside is one more `--deps`; an object of
the report's own repository hides one of the same name in a library. Only
the objects the report names go in, and what they name in turn. A constant or
a static attribute of a class, `DATA(side) = cl_gui_docking_container=>dock_at_left`,
needs no dependency: the attribute is `LIKE` it - of the stand-in, for a
SAP GUI class. A name that a local class declares itself, as an attribute or
a parameter of a method, is no read of the inline declaration. Macros (`DEFINE`) are
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

### A whole package in one run

```
node tools/report2cloud/package.mjs <dir> [<dir> ...] --out <dir> [--includes dir] [--wrappers]
```

converts every report under the folders as `coverage.mjs` does and writes the
classes of the converted ones into `--out`, with `estate.md` beside them:

- the reports in the order to migrate them - a report after the reports it
  calls with `SUBMIT`, `PERFORM ... IN PROGRAM` and `PERFORM f(prog)`, a
  cycle kept in the order of the names;
- the calls as a Mermaid graph, refused reports and calls out of the estate
  marked;
- what the estate calls outside of it - reports and transactions of SAP or
  of another package, to check by hand;
- the coverage of the estate, the refusals ranked across it.

A `SUBMIT` of a report of the estate starts its class.

### The web corpus

```
npm run report2cloud:web -- [--lint] [--start] [--limit n] [--json file] [--summary file] [--offline]
```

measures the converter on the open-source ABAP of the web: the repositories
of the community list of ABAP projects (`--list`, default the `list.json` of
dotabap-list), cloned shallow and sparse into `build/web-corpus` - only
the programs and the classes, interfaces and DDIC objects that type them,
read and never run, and none of it part of this repository. Every report is
converted with the includes of its own repository and the dependencies of
it and of the other repositories of the same owner in the list - a library
and its demos are often two repositories, installed side by side; `--lint` lints the converted classes together (v750), where the
parser errors and redefinitions are the converter's and most other findings
name a dependency the sparse clone does not have. `--start` takes the
converted classes into the transpiled runtime, the way the runtime test runs
its own corpus (an mcp-server checkout beside this repository and the
popups): the syntax check of the transpile with the dependencies of each
report, one build, and every app started through the JSON protocol of the
frontend - the funnel converted / checked / built / started and the first
errors, ranked (`lib/start.mjs`). A clone in the cache is
kept, `--offline` uses the cache alone. The workflow
`.github/workflows/report2cloud-web.yaml` runs it weekly and writes the
summary into the job summary; it fails when a report crashes the converter.

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
| `INCLUDE x`, `INCLUDE: x, y` | the include's source, inlined before the parse from `x.prog.abap` beside the report (or `--includes`), recursively, a chain include by include; `IF FOUND` without a file is dropped |
| `DEFINE` ... `END-OF-DEFINITION`, a macro call | the statements of the macro at every call, with the spacing of its body; the definition and the call are not carried over |
| `REPORT` / `PROGRAM` | the class, `INHERITING FROM z2ui5_cl_cgui_report`; `MESSAGE-ID` is the class of every short `MESSAGE e001`; the title of the text pool is `set_title( )`; `LINE-COUNT n` is `set_line_count( n )` in `initialization( )` - the runtime counts the lines of the list without header and footer, the classic `n` counted them too (noted) |
| `PARAMETERS p TYPE/LIKE ...` | a PUBLIC attribute and `screen->parameter( )`; `LIKE` a DDIC field becomes `TYPE`, `p(10)` / `TYPE c LENGTH 10` / `DECIMALS` are kept; `TYPE (name)` / `FOR (name)` of a fixed name - a literal, or a DATA with a literal VALUE nothing else names - is typed with it (`FOR` through a `DATA s_type TYPE name`) |
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
| the restart of the report after its list | nothing is written - the runtime does it (`set_fresh_start( )`, on by default): Back from the list gives the global data the values it had after `initialization( )` (its `VALUE` and what `INITIALIZATION` set) and runs `initialization( )` again, the selection screen keeps its input - as the classic report started every run afresh |
| global `FIELD-SYMBOLS` | declared in each method that uses them |
| `TYPE-POOLS` | dropped |
| `INITIALIZATION`, `LOAD-OF-PROGRAM` | `initialization( )` |
| `INITIALIZATION` of a report without a selection screen (no `PARAMETERS`, `SELECT-OPTIONS` or `SELECTION-SCREEN`) | the start of `start_of_selection( )`: the classic report went straight on with START-OF-SELECTION, and the runtime runs a report whose `selection_screen( )` declares nothing at once - what INITIALIZATION builds (a grid, a list) is the first page |
| `AT SELECTION-SCREEN OUTPUT` | `at_selection_screen_output( screen )` |
| `LOOP AT SCREEN` ... `MODIFY SCREEN` ... `ENDLOOP` | `DATA(lt_screen) = screen->loop_at_screen( ).` `LOOP AT lt_screen INTO DATA(ls_screen).` ... `screen->modify_screen( ls_screen ).` - `screen-name/group1/active/input/required/invisible` become `ls_screen-*`, `'0'`/`'1'` become `abap_false`/`abap_true`, `'S_X-LOW'` becomes `'S_X'` |
| `LOOP AT SCREEN` in a FORM `AT SELECTION-SCREEN OUTPUT` performs | the FORM method gets `IMPORTING screen TYPE REF TO z2ui5_cl_cgui_selscreen`, the PERFORM passes it - also through FORMs in between |
| `LOOP AT SCREEN` in a method of a local class, in another event block | `current_screen( )->loop_at_screen( )` - the screen of `at_selection_screen_output( )` while it runs; elsewhere one built afresh, whose changes are not shown (a TODO), as `MODIFY SCREEN` outside of PBO is not |
| `CALL FUNCTION 'DYNP_VALUES_READ'` / `'DYNP_VALUES_UPDATE'` with `TABLES dynpfields = lt` | `LOOP AT lt ASSIGNING ...` `ASSIGN (<ls>-fieldname) TO ...` - the fields are attributes, every event brings their values along |
| a global `DATA message` / `list` / ... - a name of the runtime | renamed in the source first, to `gv_message` (a note of the migration report) |
| `AT SELECTION-SCREEN ON p` | `at_selection_screen_on( field )`, `CASE field. WHEN \`P\`.` |
| `AT SELECTION-SCREEN ON BLOCK b` | `at_selection_screen_on_block( block )`, `CASE block. WHEN \`B\`.` - a TODO when the block holds another block (the runtime raises the event for the blocks that hold fields themselves) |
| `AT SELECTION-SCREEN ON RADIOBUTTON GROUP g` | `at_selection_screen_on_radio( group )`, `CASE group. WHEN \`G\`.` - an error marks the first button |
| `AT SELECTION-SCREEN ON END OF s` | `at_selection_screen_on_end_of( field )`, `CASE field. WHEN \`S\`.` - the multiple selection left with OK; an error opens it again |
| `AT SELECTION-SCREEN ON EXIT-COMMAND` | `at_selection_screen_on_exit( ucomm )`, `sy-ucomm` is `ucomm` - `CGUI_BACK`, not `BACK` / `%EX` / `RW` (a TODO when the block reads it) |
| `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p` (or `s-low`/`s-high`) | `at_value_request( field )`, `WHEN OTHERS. super->at_value_request( field ).`; the field gets `value_help = abap_true`. A block for `s-low` and one for `s-high`: one `WHEN`, `IF value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high` |
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
| `cl_salv_table=>factory( IMPORTING r_salv_table = o CHANGING t_table = t )` ... `o->display( )` | `alv( t )` at the place of `display( )`, with `set_title( )` (`set_list_header`), `set_column_text( )` (`set_long/medium/short_text`, the longest wins), `set_column_hidden( )` (`set_visible( abap_false )`, `set_technical( )`), `set_line_selection( )` (`SET HANDLER ... get_event( )`, with a TODO for the handler's code). A `LOOP AT o->get_columns( )->get( )` that only sets the texts of every column - from `get_columnname( )` and `get_long_text( )` of the column - is a loop over `get_columns( t )` of the ALV after `alv( t )`, each column `set_column_text( )` with its name and its text. The `REF TO cl_salv_*` variables, `get_columns( )` / `get_column( )` assignments and `TRY ... CATCH cx_salv_*` are removed |
| `REUSE_ALV_GRID_DISPLAY` / `REUSE_ALV_LIST_DISPLAY` with `TABLES t_outtab = t` | `alv( t )`, `i_grid_title` is `set_title( )`, a field catalog built with `wa-fieldname`, `wa-seltext_*`, `wa-no_out`, `APPEND wa TO fcat` or `APPEND VALUE #( ) TO fcat` gives column texts and hidden columns; `REUSE_ALV_FIELDCATALOG_MERGE`, the layout and a FORM that only built them are dropped, as is the `IF sy-subrc` after the call |
| `cl_gui_alv_grid` in a container (`cl_gui_custom_container`, `cl_gui_docking_container`, `cl_gui_container=>default_screen`), `set_table_for_first_display( CHANGING it_outtab = t it_fieldcatalog = f EXPORTING is_layout = l )` | `alv( t )` with the LVC field catalog (`fieldname`, `coltext` / `scrtext_*`, `no_out`, `hotspot` as `set_column_hotspot( )`, `do_sum` as `set_column_sum( )`) and `grid_title` of the layout as `set_title( )`. The grid, the container and the handler object go, with their `CREATE OBJECT`, `SET HANDLER`, `refresh_table_display( )` and the other tuning calls; an `IF go_container IS INITIAL` keeps the branch that creates the grid |
| `CALL SCREEN n` with the grid, `MODULE ... OUTPUT`, `MODULE ... INPUT` | the PBO modules in place of `CALL SCREEN` - the grid shows when the event block is done; the PAI modules are `at_user_command( ucomm )` with the OK code field as `ucomm` (`CLEAR ok_code` and `save_ok = ok_code` go, `LEAVE TO SCREEN 0` / `SET SCREEN 0` are `leave_to_selection_screen( )`). One screen per report; statements after `CALL SCREEN` get a TODO |
| the grid and its container created inline - `DATA(grid) = NEW cl_gui_alv_grid( i_parent = NEW cl_gui_custom_container( ... ) )`; a field catalog filled with `VALUE lvc_t_fcat( ( fieldname = ... coltext = ... no_out = ... ) )` | as the declared grid: dropped, `set_table_for_first_display( )` is `alv( )`; the rows of the VALUE are its columns (`set_column_text( )`, `set_column_hidden( )`); an `IF sy-subrc` around `CALL SCREEN` that is left without statements goes |
| a dynpro of fields - `CALL SCREEN n`, `MODULE ... OUTPUT / INPUT`, the screens of the .prog.xml | `call_screen( dynnr )`; the statements after it go on in `after_call_screen( dynnr )`. The fields of the screen are `dynpro_screen( )` - a text before an input is its label, a frame a block, an output field `read_only`, a required field `obligatory`, GROUP1 `modif_id`, a push button `button( )` with its function code. The modules are private methods: `dynpro_pbo( )` calls the PBO modules, `dynpro_pai( )` sets the OK code field to ucomm and calls the PAI modules in their order - `AT EXIT-COMMAND` for Back, Exit and Cancel, `FIELD f MODULE m ON INPUT` when f is not initial - and stops after a module that left the screen or sent an error message. `SET SCREEN`, `LEAVE SCREEN`, `LEAVE TO SCREEN` are `set_screen( )`, `leave_screen( )`, `leave_to_screen( )`; sy-ucomm in a PAI module is the OK code field. `PROCESS ON VALUE-REQUEST` / `ON HELP-REQUEST` are dropped. A tabstrip (`CONTROLS ts TYPE TABSTRIP` is `DATA ts TYPE z2ui5_cl_cgui_report=>ty_s_tabstrip`) is `tabbed_block_begin( 'TS' )` with a `tab( text fcode area )` per tab title (its function code, its reference field the area): the tab of `ts-activetab` is selected, a press is its function code in the PAI. A subscreen area is `subscreen( area )`; `CALL SUBSCREEN area INCLUDING sy-repid dynnr` in the PBO is `call_subscreen( area dynnr )` where the flow logic has it - the subscreen of the number in the variable shows in the area, on the selected tab when tabs share it, and its PBO runs; `CALL SUBSCREEN area` in the PAI is `call_subscreen_pai( area ucomm )`, the PAI of that subscreen. The subscreens of the report (type I) are screens of `dynpro_screen( )` like the others. A table control (`CONTROLS tc TYPE TABLEVIEW USING SCREEN n` is `DATA tc TYPE z2ui5_cl_cgui_report=>ty_s_tableview` - `lines`, `current_line`, `top_line`, no `cols`) is `table_control( name title columns )`: its columns in their order with the heading of each, those ready for input inputs, every line shown. `LOOP [AT itab INTO wa] WITH CONTROL tc` keeps the loop of the classic, a line at a time: in the PBO `tc-current_line` set, the modules of the loop run, then `tablecontrol_row( )` hands the fields of the line to the browser (`tc-lines` lines, or those of `itab`); in the PAI the line read into `wa` for `LOOP AT`, every field of the line set from what the user left (`tablecontrol_cell( )`), then the modules - the `MODIFY itab FROM wa INDEX tc-current_line` of the classic |
| the SAP GUI controls of a report without a grid of its global data - `cl_gui_custom_container`, `cl_gui_docking_container`, `cl_gui_splitter_container`, `cl_gui_easy_splitter_container`, `cl_gui_dialogbox_container`, `cl_gui_textedit`, `cl_gui_html_viewer`, `cl_gui_toolbar`, `cl_gui_picture`, `cl_gui_simple_tree`, `cl_gui_column_tree`, `cl_gui_list_tree`, `cl_gui_alv_grid` in a local class, `DP_CREATE_URL` | their stand-ins `z2ui5_cl_cgui_gui_container`, `z2ui5_cl_cgui_gui_easy_split`, `z2ui5_cl_cgui_gui_textedit`, `z2ui5_cl_cgui_gui_html_viewer`, `z2ui5_cl_cgui_gui_toolbar`, `z2ui5_cl_cgui_gui_picture`, `z2ui5_cl_cgui_gui_simple_tree`, `z2ui5_cl_cgui_gui_column_tree`, `z2ui5_cl_cgui_gui_list_tree`, `z2ui5_cl_cgui_gui_alv_grid` - the same methods, parameters, constants and EXCEPTIONS; `CREATE OBJECT go_x EXPORTING ...` is `go_x = NEW #( ... )`. A custom control area of the dynpro is `custom_control( name )` in `dynpro_screen( )`, a docking container shows on the screen it is created for; a control on `cl_gui_container=>default_screen` (or `screen0`) needs no dynpro - created in the run, it shows above the list of the run (`WRITE: space.` keeps its blank line), on the selection screen beside it. `CNTL_SIMPLE_EVENTS` is `z2ui5_cl_cgui_gui=>ty_t_simple_events`. The text editor is a text area bound to the report - what the user types is there in the PAI, `get_textstream( )` needs no `cl_gui_cfw=>flush( )`; the HTML viewer shows its document as it is, its styles and forms included, in a frame where no script of it runs (abap2UI5's `z2ui5.cc.HTMLFrame`; on a frontend before it, sanitized with its `SAPEVENT` links below), an address of the web as a link, and keeps the history of what `show_url( )` showed (`go_back( )`, `go_forward( )`, `get_current_url( )`); `visible_true` / `visible_false` are the flags `set_visible( )` takes. `cl_gui_frontend_services=>get_gui_version( )` raises `gui_no_version`, the answer of the classic where no SAP GUI runs. The picture is an image (`set_display_mode( )` stretch and fit fill the width, an icon of `load_picture_from_sap_icons( )` an icon, a click `picture_click`); `CALL FUNCTION 'DP_CREATE_URL'` is `z2ui5_cl_cgui_frontend=>dp_create_url( )` - the URL it answers (short enough for a `CHAR` field) names a data URI of the bytes, which the picture shows. `SCMS_BINARY_TO_XSTRING`, `SCMS_XSTRING_TO_BINARY`, `SCMS_STRING_TO_XSTRING` and `SSFC_BASE64_ENCODE` / `_DECODE` are methods of the same names of `z2ui5_cl_cgui_frontend` (`TABLES` read are `EXPORTING`, `binary_tab` filled is `CHANGING`). `cl_gui_gos_container` is a container like the others, `go_x = NEW #( ... )` of a control the constructor of its stand-in, `cl_gui_cfw=>compute_metric_from_dynp( )` answers the size it is given. The geometry of a container (`set_top( )`, `set_width( )`, ..., `metric_pixel`, the `ws_*` styles) is taken without effect. The toolbar is a row of buttons (`cntb_btype_*` qualified), a dialog box has a title bar with Close. The simple tree shows its nodes (`MTREESNODE` is `z2ui5_cl_cgui_gui_simple_tree=>ty_s_node`, read by the names of its fields) with the branches expanded; a node with `expander` raises `expand_no_children` on its first expand, a click `selection_changed` and `node_double_click` (the browser has no double click on a link), `get_selected_node( )` answers with it. The column tree is that tree with columns beside it: `add_column( )` adds one with its header, `add_nodes_and_items( )` takes `TREEV_NTAB` and the items of `MTREEITM` (`z2ui5_cl_cgui_gui_simple_tree=>ty_t_node`, `z2ui5_cl_cgui_gui_column_tree=>ty_s_item`) - the item of the hierarchy column is the text of its node, the others its cells: a text, a link (`link_click`) or a checkbox (`checkbox_change`); a click on a node raises `item_double_click` of the hierarchy column too. The list tree is the column tree without columns: the first item of a node is its text, the others follow on its line in their `length`, a click on a node is `item_double_click` of its first item. The grid of a local class is the ALV of the report in its container: `set_table_for_first_display( )` hands it a copy of the table with the field catalog, the layout and the sort (`VALUE #( )` of these generic parameters is written with the classic type, `VALUE lvc_s_layo( )`), `refresh_table_display( )` is passed the table again (`CHANGING it_outtab = ...`, the table `set_table_for_first_display( )` was given in the same class - else refused); the buttons the `toolbar` handler appends to `e_object->mt_toolbar` are functions of the ALV and raise `user_command`, a click `double_click`, a hotspot `hotspot_click`; one grid at a time - the first displayed, then the one refreshed, the cell of another one names it and shows it at a click. `SET HANDLER h->m FOR go_x` of a handler `FOR EVENT` in a local class is `go_x->set_handler( handler = h method = `M` event = `E` )`: the stand-in calls the method for the event of the browser - `function_selected` and `dropdown_clicked` of the toolbar, `sapevent` of a `SAPEVENT:` link of the HTML viewer or a form posted to a `SAPEVENT:` action (action, getdata, postdata, query_table), `close` of a dialog box, `node_double_click`, `selection_changed` and `expand_no_children` of the simple tree, `toolbar`, `user_command`, `double_click` and `hotspot_click` of the grid - with the parameters it declares and `sender`; the handler class gets `if_serializable_object`. A static handler `SET HANDLER lcl=>m` is called through an object, `handler = NEW lcl( )`, or - its class has a constructor that takes parameters - by the absolute name of its class (a system resolves it, the transpiled runtime does not). A control handed to a class of the report's repository that uses SAP GUI controls itself (`zcl_view=>show( go_container )`, `go_app->set_container( go_container )`, through a local class that inherits from it or an interface it implements) converts that class too, as a local class of the report would be: its `cl_gui_*` the stand-ins, `SET HANDLER` `set_handler( )`, its header as it was - written beside the report's class under its own name (`--deps` names the repository), so the report calls it as it did; a class whose methods would need the report (`WRITE`, a `FORM`, a global of the report) is refused at its file. A member, a parameter or an exception the stand-ins do not have, `SET HANDLER ... FOR ALL INSTANCES`, an event a stand-in does not raise and the other controls (the calendar, the ABAP editor) are refused |
| the handler class of the grid (`METHODS ... FOR EVENT ... OF cl_gui_alv_grid`) | its methods become methods of the report class: `DOUBLE_CLICK` `at_line_selection( )` (`e_row-index` is `row`, the chain gets `set_line_selection( )`), `HOTSPOT_CLICK` `at_link_click( row column )`, `USER_COMMAND` `at_user_command( )` (`e_ucomm` is `ucomm`), `TOOLBAR` the buttons appended to `e_object->mt_toolbar` as `add_function( )` in the chain. `get_selected_rows( IMPORTING et_index_rows = r )` is `get_selected_rows( )` of the runtime, the chain gets `set_selection_mode( )`; `LVC_T_ROW` / `LVC_T_ROID` / `LVC_S_COL` become the types of `z2ui5_cl_cgui_alv`; `e_row_id`, `e_column_id`, `es_row_no` used as a whole (passed to a FORM, `CASE e_column_id`) are declared from `row` and `column`. `MOVE ... TO ls_button-function` in the toolbar handler is an assignment like `=` |
| the `USER_COMMAND` callback of `REUSE_ALV_GRID_DISPLAY` | `at_line_selection( )`: `rs_selfield-tabindex` is `row`, `-fieldname` the column of a hotspot (`hide`), `-value` that cell of the output table; `-refresh`, `-row_stable`, `-col_stable` are dropped (the ALV is drawn anew on every roundtrip), `-exit = 'X'` is `leave_to_selection_screen( )` |
| `cl_abap_browser=>show_html( )`, `show_url( )`, `show_xml( )`, `close_browser( )` | `z2ui5_cl_cgui_abap_browser=>...( )` - the document in an HTML viewer: in `container` (`cl_gui_container=>default_screen` - above the list of the run), else in a dialog box of its own with `title` as its caption and Close; the XML as escaped text. Size, position, format, printing, the context menu and the buttons of the window are taken and not shown |
| a `CL_SALV_TABLE` the report keeps and uses after `display( )` - an attribute of a local class, `SET HANDLER ... FOR o->get_event( )`, `get_selections( )->get_selected_rows( )` | the SALV stand-ins `z2ui5_cl_cgui_salv_table` (`cl_salv_table` and `cl_salv_events_table`), `_columns`, `_column` and `_settings` (display settings, functions, selections, sorts, layout, ...) with the classic methods; `if_salv_c_*=>x` is `z2ui5_if_cgui_salv_c=>group-x`, `cx_salv_*` is `z2ui5_cx_cgui_salv`, `salv_t_row` and the other SALV types those of the stand-ins. The table shows as a grid in its container or on the screen: the column texts, hidden and technical columns, hotspots (`set_cell_type( hotspot )`), the title, the striped rows and the functions added - a button raises `added_function`, a double click `double_click`, a hotspot `link_click`, for the handlers `set_handler( )` keeps. A SALV the report only sets up and shows stays `alv( )` (the row above); the stand-ins are used when that is refused or a SALV would be left in a local class |
| `cl_salv_tree=>factory( IMPORTING r_salv_tree = o CHANGING t_table = t )`, `o->get_nodes( )->add_node( )` ... `o->display( )` | the stand-ins `z2ui5_cl_cgui_salv_tree` (`cl_salv_tree`, `cl_salv_events_tree`), `_nodes` and `_node` (`cl_salv_node`, `cl_salv_item`): the nodes go into the ALV tree of the report - below `related_node` for `relat_last_child` / `relat_first_child`, beside it for a sibling (`cl_gui_column_tree=>relat_*` and `if_salv_c_node_relation=>x` are `z2ui5_if_cgui_salv_c=>node_relation-x`), `data_row` the cells of the columns of `t`; the column texts and hidden columns, the header and the hierarchy header of `get_tree_settings( )`, the functions added; a click on a node raises `double_click` with its `node_key`, a checkbox item (`set_type( checkbox )`) `checkbox_change` - for the handlers `set_handler( )` keeps, also through `DATA(e) = o->get_event( )` |
| `CLASS-DATA` of a local class | kept with the app: `cgui_statics_keep( )` at the end of every roundtrip copies it into an attribute of the report, `cgui_statics_restore( )` at the start copies it back - a roundtrip is a session of its own on a system, the static attributes start initial. A static attribute that is not PUBLIC or READ-ONLY gets a TODO |
| `cl_demo_output=>...`, `if_demo_output` | `z2ui5_cl_cgui_demo_output=>...( )`, `z2ui5_if_cgui_demo_output` - the output goes into the list of the report: a value as a line, a structure and a table as columns under the names of their components, a section as a heading, html as its text; `display( )` shows nothing at once, the list shows when the run ends; `get( )` takes what the output wrote since its last `display( )` out of the list and answers it as an HTML page (for `cl_abap_browser=>show_html( )`), `clear( )` drops it. A method it does not have (`write_xml`) stays and is named for the release |
| `cl_gui_frontend_services=>...` (also `CALL METHOD`) | `z2ui5_cl_cgui_frontend=>...( )` - the same methods, parameters and classic exceptions, for the files in the browser: `file_open_dialog` in an F4 opens an upload and the F4 runs again with the picked file (Execute, when the dialog opened during the run), `gui_upload` reads it by its name (ASC split at the line ends and with `has_field_separator` at the tab, BIN in the lines' length) - a name no file was picked for, a path of the PC typed in or fixed in the code, opens the upload dialog and the run starts again with the file the user picks, `gui_download` is a download of the browser, the save and folder dialogs answer at once, `execute` opens a URL, `clipboard_export` the clipboard; `FILETABLE` is `z2ui5_cl_cgui_frontend=>ty_t_file_table`, `cl_gui_cfw=>flush( )` is dropped |
| `CALL FUNCTION 'GUI_UPLOAD'` / `'GUI_DOWNLOAD'` | `z2ui5_cl_cgui_frontend=>gui_upload( )` / `gui_download( )`: `EXPORTING` and `IMPORTING` as they were, `TABLES data_tab` as `CHANGING`, the `EXCEPTIONS` kept - `sy-subrc` after the call is the classic one |
| `SELECT COUNT(*) FROM t WHERE ...` without `INTO` | copied with the host variables escaped - it sets `sy-dbcnt`, no work area involved |
| `i_callback_user_command = 'USER_COMMAND'` | `set_line_selection( )`, and the callback FORM is the body of `at_line_selection( )`: its ucomm is `&IC1`, `rs_selfield-tabindex` is `row` |
| `MESSAGE 'text' / TEXT-001 / v TYPE t` | `message( text type )`, `S` without type |
| `MESSAGE e001(cls) WITH ...`, `MESSAGE ID ... TYPE ... NUMBER ... WITH ...` | `MESSAGE ... INTO DATA(lv_message).` `message( text = lv_message type = )` - the message class stays the source of the text |
| `MESSAGE ... TYPE 'E' / 'A'` | followed by `RETURN` - the classic message ended the event block |
| `MESSAGE ... TYPE 'S'/'I' DISPLAY LIKE 'E'` | type `W` (in the popover, the run goes on) |
| `MESSAGE ... INTO` | copied; the short form `MESSAGE s013 ... INTO` gets the message class of `MESSAGE-ID` (`s013(zr2c)`) - a class has no `MESSAGE-ID` |
| `FORM f TABLES t STRUCTURE s USING [VALUE(]u[)] TYPE x CHANGING c TYPE y` | private method `f IMPORTING u CHANGING t c`: a `USING` parameter the FORM writes becomes `CHANGING`; `TABLES` gets a table type of its own (`ty_t_s`); an untyped parameter is `TYPE any` with a TODO |
| `PERFORM f TABLES ... USING ... CHANGING ...` | `f( a )`, `f( p1 = a p2 = b )` or `f( EXPORTING ... CHANGING ... )` with the parameter names of the FORM |
| `LEAVE LIST-PROCESSING`, `LEAVE PROGRAM`, `LEAVE TO SCREEN 0` | `leave_to_selection_screen( )` (and `RETURN` for the two that end the report) - the run ends there, without `END-OF-SELECTION` and without the message of an empty list; `LEAVE SCREEN` is dropped |
| `SET CURSOR FIELD f` | `set_cursor_field( f )`; `OFFSET`, `LINE` and a cursor on the list are dropped with a note |
| `CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'`, `cl_progress_indicator=>progress_indicate( )` | dropped - the browser shows a busy indicator while the server works |
| `RS_TREE_CONSTRUCT` with `TABLES nodetab`, `RS_TREE_LIST_DISPLAY` | the tree list as the ALV tree of the report: `tree( )->add_node( )` per row of the node table, `TLEVEL` the hierarchy, `NAME` and `TEXT` the text of the node, every node open; `RS_TREE_LIST_DISPLAY` is dropped - a callback FORM is a TODO, a click on a node raises `at_tree_node( )` with the index of its row |
| `SELECT ... FROM dbtab` without `INTO`, with `TABLES dbtab` | `SELECT ... FROM dbtab INTO @dbtab` (a field list `INTO CORRESPONDING FIELDS OF @dbtab`) - the `TABLES` work area is an attribute of the class |
| `DATA(x) = ...` in an event block, read by another block, a FORM or a local class | an attribute `x` of the class, assigned where the report declared it (event blocks open no scope); the type from the constructor expression (`NEW`, `VALUE`, `CONV`, `CAST`), from a `SELECT` of one table (its row for `*`, a structure of the columns read, `i` for `COUNT( * )`) or from abaplint's syntax check - refused when none tells it |
| `F4IF_INT_TABLE_VALUE_REQUEST` in a FORM | `value_help_popup( )` as in `AT SELECTION-SCREEN ON VALUE-REQUEST`, with a TODO: the picked value goes into the field of the value request the FORM is called from |
| `SUBMIT report WITH p = v WITH s IN range WITH s op v [SIGN x] WITH SELECTION-TABLE t [VIA SELECTION-SCREEN] [USING SELECTION-SET v] AND RETURN` | `submit( report = the class values = VALUE #( ... ) via_selection_screen = using_variant = )` - the class of a report beside the input (or in the corpus), else the name report2cloud would give it and a TODO to convert it; `p = v` is a parameter value, every other comparison a range line, `IN range` the lines of `range_lines_get( )`, `WITH SELECTION-TABLE` those of `selection_table_get( )` - the runtime takes the kind from the attribute of the called class. Back returns to the caller; statements after the `SUBMIT` run before the called class starts (a TODO) |
| `SUBMIT report ...` without `AND RETURN` | `submit( )` and `RETURN` - the classic ended the caller |
| `CALL TRANSACTION code [AND SKIP FIRST SCREEN] [WITH/WITHOUT AUTHORITY-CHECK]` | `call_transaction( code skip_first )` - the runtime starts the report class the catalog of the installation (`set_catalog( )`) names for the code, with its variant, else the code is taken as the class (a TODO to put it in the catalog); `AND SKIP FIRST SCREEN` runs it straight away, `SET PARAMETER ID` fills the fields with a `MEMORY ID` as before. Back returns here; statements after the call run before it starts (a TODO) |
| `SELECTION-SCREEN BEGIN OF SCREEN n [AS WINDOW] [TITLE t]` ... `END OF SCREEN n` | `selection_screen_dynnr( dynnr screen )`, `CASE dynnr. WHEN \`n\`.` with the fields' chain; the screen is a dialog either way |
| `CALL SELECTION-SCREEN n [STARTING AT x y]` | `call_selection_screen( dynnr title )`. The dialog opens when the method returns, so the statements after the call, in the same branch (also inside a `WHEN` or `IF`), go on in `after_call_selection_screen( dynnr subrc )` - `sy-subrc` of the `IF` right after the call is `subrc` (0 confirmed, 4 cancelled); a call inside a loop, in a FORM, or with statements after the block it stands in gets a TODO instead |
| `CALL FUNCTION 'POPUP_TO_CONFIRM'` (`TEXT_QUESTION`, `TEXT_BUTTON_1/2`, `TITLEBAR`, `ANSWER`), `POPUP_TO_CONFIRM_STEP` (`TEXTLINE1/2`, `TITEL`), `POPUP_TO_DECIDE` (`TEXTLINE1/2/3`, `TEXT_OPTION1/2`, `TITEL`) | `popup_to_decide( question options then title )` - the two buttons are the options, the answers `1`, `2` and `A` the classic ones (`J`, `N`, `A` for `POPUP_TO_CONFIRM_STEP`, switched in the continuation). The popup opens when the method returns and its answer arrives in a public method of its own, `on_popup_1( answer )`, `on_popup_2( answer )`, ... (`then = 'ON_POPUP_1'`), so the statements after the call in its branch are cut off and go on there, the `ANSWER` of the call set from `answer` first; an `IF sy-subrc` right after the call, which checked the `EXCEPTIONS`, is dropped - one that also asks the answer (`IF sy-subrc <> 0 OR lv_answer = 'A'`) stays, `sy-subrc` is 0 in the callback. Inside a loop, in a FORM, or with statements after the block the call stands in, nothing is cut: the popup gets a ucomm of its own for `at_user_command( )` (`POPUP_1`, ...) and a TODO says where to go on, the answer lines as TODO comments. Local data the continuation reads is declared anew there, with a TODO (a value set before the popup is not there) |
| `CALL FUNCTION 'POPUP_TO_DECIDE_LIST'` (`TEXTLINE1/2/3`, `TITEL`, `TABLES t_spopli` of `SPOPLI`, `ANSWER`) | `popup_to_decide_list( question list then title )` - every `VAROPTION` of the table an option, the answer the number of its line or `A`, as the classic one; `SPOPLI` is `z2ui5_cl_cgui_popup=>ty_s_spopli`; `START_COL`, `START_ROW`, `CURSORLINE` and `MARK_FLAG` are dropped (a note), the popup is centred and takes one choice |
| `CALL FUNCTION 'POPUP_GET_VALUES'` (`TABLES fields` of `SVAL`, `POPUP_TITLE`, `RETURNCODE`) | `popup_get_values_sval( sval then title )` - `FIELDNAME` is the field, `FIELDTEXT` its label, `VALUE` the start value, `FIELD_OBL` required; the callback `on_popup_n( answer )` starts with `returncode = SWITCH #( answer WHEN 'A' THEN 'A' ELSE space )` and `popup_values_sval( CHANGING sval = fields )`, which writes what the user entered back into the table (and fills an empty one) |
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
| local classes and interfaces | `.clas.locals_imp.abap`; their definitions go to `.clas.locals_def.abap` when the class is typed with them, with the types and constants of the report they are typed with. A method that writes the list, calls a FORM or uses a global of the report is converted like an event block: the report's data through the instance (`lcl_r2c=>app->gv`, set once in `at_roundtrip_start( )`, which the runtime calls first in every roundtrip), its types and constants through the class, `list( )`, `message( )` and the FORMs through the instance - the class declares the local class a `LOCAL FRIEND`. A global typed with a local class is a private attribute (local types can type the private section only); a local class whose instance the report keeps implements `if_serializable_object` |
| ABAP SQL (`SELECT`, `INSERT`, `UPDATE`, `MODIFY`, `DELETE` on the database) | strict mode, as ABAP Cloud requires: host variables escaped with `@`, the field list, `ORDER BY` and `GROUP BY` separated by commas - syntax only, the parser tells a host variable from a column |
| everything else | copied as written, comments included (`*` comments become `"` comments) |

## Refused

Every refusal has its section in [docs/refusals.md](docs/refusals.md) - why it has no counterpart, and the rewrite in the classic report that unblocks it; the migration report links each refusal there. The page is written from `lib/refusals.mjs` (`npm run report2cloud:docs`).

Each of these stops the conversion with `file:row:col` and the reason; all of
them are collected, so one run lists everything there is to do.

| Construct | Why |
|---|---|
| `CALL SCREEN`, `MODULE`, `SET SCREEN`, `LEAVE TO SCREEN`, `CALL SUBSCREEN`, `CONTROLS` - but for a dynpro of fields, its tabstrips and subscreens, and the screen of one `cl_gui_alv_grid`; a screen with a custom control (but for the stand-ins), a table control with a field other than an input/output field or of more than 16 columns, `LOOP AT itab WITH CONTROL` of a table with a header line, other `LOOP`s of the flow logic, a subscreen of another program, a screen number in a variable | dynpros of that kind have no counterpart in a browser app yet |
| `SELECTION-SCREEN INCLUDE`, `SET CURSOR`, a `TAB` without `DEFAULT SCREEN` of this report | not converted; abap-cloud-gui has `set_cursor_field( )` - port them by hand. A tab whose subscreen the program sets at runtime (`tb-dynnr`) has no counterpart |
| `CALL SELECTION-SCREEN n` of a screen the report does not declare, a second call of the same screen with statements after it | the class calls the screens of `selection_screen_dynnr( )`, and `after_call_selection_screen( )` goes on after one call per screen |
| `SUBMIT ... EXPORTING LIST TO MEMORY`, `TO SAP-SPOOL`, `VIA JOB`, `WITH-FREE SELECTIONS`, `USING SELECTION-SCREEN n` / `SELECTION-SETS OF PROGRAM` | the list of the called report is not in memory, there is no spool and no job from a browser app; the class has its standard selection screen and its own variants only |
| `AT SELECTION-SCREEN ON BLOCK b` / `ON RADIOBUTTON GROUP g` / `ON END OF s` of a block, group or select-option the report does not declare | |
| `CALL TRANSACTION ... USING` (batch input), `OPTIONS FROM`, `MESSAGES INTO` | batch input plays the screens of a transaction - there are none, and it is no API on ABAP Cloud; call the released API instead |
| `EXEC SQL` | native SQL is not available on ABAP Cloud |
| `ASSIGN ('(PROG)FIELD')`, `LOOP AT SCREEN ASSIGNING` | field symbols to screen or foreign program fields |
| a `LOOP AT SCREEN` inside another, `screen-group2`, `screen-group3`, ... read in a condition | the screen has one loop at a time and the fields `name`, `group1`, `active`, `input`, `required`, `invisible`, `intensified` and `length` (an assignment to another field is dropped with a TODO) |
| `TOP-OF-PAGE` / `TOP-OF-PAGE DURING LINE-SELECTION` / `END-OF-PAGE` with more than output | the runtime writes header and footer once and repeats them on every page; only a fixed one is converted |
| `GET CURSOR FIELD f VALUE v LINE l OFFSET o` in `AT LINE-SELECTION` | `z2ui5_cl_cgui_gui=>get_cursor_field( IMPORTING ... EXCEPTIONS not_on_field = 4 )` - the field of the `WRITE` clicked (a report with `GET CURSOR FIELD` writes every data object with its name), its value, line and offset, `sy-subrc` 4 off a field; elsewhere not converted |
| `READ LINE n FIELD VALUE f [INTO g] ... [LINE VALUE INTO wa]`, `MODIFY LINE n FIELD VALUE f [FROM g] ...`, `READ` / `MODIFY CURRENT LINE` in `AT LINE-SELECTION` | `read_list( )->read_field( EXPORTING line name CHANGING value EXCEPTIONS no_line = 4 )` and `modify_field( )` per field - the field the `WRITE` wrote with its name (a report that reads its list back writes the fields it reads with their names, a checkbox ready for input), `sy-subrc` 4 without such a line; `read_list( )` is the list clicked in `at_line_selection( )`, else the current one; `CURRENT LINE` is `row`, `LINE VALUE INTO` `line_text( )`. `LINE FORMAT` / `FIELD FORMAT` are dropped (a note); `INDEX` (another list level), `OF PAGE` and `LINE VALUE FROM` stay refused |
| `SCROLL LIST`, `SET USER-COMMAND`, `NEW-PAGE PRINT ON`, `PRINT-CONTROL` | the list has no scroll position or print control |
| a global of the report named like a method or attribute of `z2ui5_cl_cgui_report` (`tree`, `format`, `window`, ...) | the global becomes an attribute of the class - rename it in the source first |
| `LEAVE TO LIST-PROCESSING`, `LEAVE TO TRANSACTION`, `LEAVE TO SCREEN n` | the list is shown after `start_of_selection( )`; there are no screens or transactions to go to |
| `NODES`, `GET`, `REJECT` | logical databases |
| `INCLUDE` without its file beside the report | the include was not found as `<include>.prog.abap` - put it there, or name its folder with `--includes` |
| `SELECT` without `INTO` of a table without `TABLES`, or with a join | the short form reads into the `TABLES` work area - add `INTO` |
| a `TABLES` parameter without a type used with its header line | a work area needs a line type - give the parameter a `STRUCTURE` or a table `TYPE` |
| `MESSAGE` without message class, `MESSAGE ... RAISING` | |
| `PERFORM ... IN PROGRAM`, `PERFORM f(prog)`, `IF FOUND`, `ON COMMIT`, a `PERFORM` whose parameters do not match the FORM, a literal passed to a parameter the FORM changes | only FORMs of this report, called as methods |
| `POPUP_TO_CONFIRM_WITH_MESSAGE`, `POPUP_TO_DECIDE_WITH_MESSAGE`, `POPUP_GET_VALUES_DB_CHECKED` | the popups with a T100 message or a DDIC check - `popup_to_decide( )` / `popup_get_values( )` and `at_user_command( )` by hand; the five plain ones are converted (see the mapping) |
| the SAP GUI controls but `cl_gui_alv_grid`, the containers, `cl_gui_textedit`, `cl_gui_html_viewer`, `cl_gui_toolbar`, `cl_gui_picture`, `cl_gui_simple_tree`, `cl_gui_column_tree` and `cl_gui_list_tree` (the calendar, the ABAP editor); the events those do not raise, a handler for all instances or a static one; `refresh_table_display( )` of a grid whose table is not in reach; of `cl_gui_frontend_services` what the browser has no counterpart for (the registry, an option `z2ui5_cl_cgui_frontend` does not take) | there is no SAP GUI frontend and no dynpro container |
| the `DATA_CHANGED` and other handlers of the grid but the four above, a method of `cl_gui_alv_grid` without a counterpart, a handler class with other methods, a handler that uses `me->` or `sender` | an edited cell arrives in `at_data_changed( row column )` - port these by hand |
| other `REUSE_ALV_*` / `LVC_*` function modules, `F4IF_INT_TABLE_VALUE_REQUEST` outside of an F4, `DYNP_VALUES_READ` / `_UPDATE` without `TABLES dynpfields`, `BDC_*` | |
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
| `package.mjs` | a whole package in one run: the classes and `estate.md` |
| `lib/estate.mjs` | the calls between the reports of a package, the order to migrate them in |
| `web.mjs` | the measurement over the open-source reports of the web (`report2cloud:web`) |
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
npm run test:report2cloud:browser                                          # the classes in a real browser - opt-in, see below
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
  the MCP server's). About 20 s on a warm workspace;
  `REPORT2CLOUD_RUNTIME_PORT` (default 4481) is the port,
  `REPORT2CLOUD_RUNTIME_KEEP=1` keeps the build (`<runtime>/.r2c-*`). The backend clears the
  `CLASS-DATA` of the local classes of the reports before every request
  (`freshStatics` of `startBackend( )`): a roundtrip is a session of its own
  on a system, the process of the test would keep them - it hid that a
  report's static attributes were lost between two roundtrips, until
  `cgui_statics_keep( )` / `cgui_statics_restore( )`.
- **The semantic test** (`test/runtime/semantic.test.mjs`, run with the
  runtime test): the expectations are not written by hand here. The
  classic report itself is transpiled as a program with the classes and run
  in a process of its own (`test/runtime/program.mjs`) against the same
  seeded rows. Its class runs in the backend with the same values on the
  selection screen. The two lists must say the same, line by line.
  - The transpiler takes a part of the classic only, so the report is
    prepared first (`test/runtime/program-source.mjs`):
    - its selection screen is data, filled where the run starts: the
      defaults, then INITIALIZATION, then the values of the user;
    - FORMAT is dropped, since it changes no text;
    - `WRITE /5` is `WRITE /`, because the transpiler misses the new line
      of a position;
    - the statements of START-OF-SELECTION and END-OF-SELECTION are FORMs,
      because the transpiler declares an inline `DATA( )` in a FORM only.
  - The comparison drops the blanks inside a line and the separator between
    two digits, and reads a date as YYYYMMDD. The transpiled WRITE pads
    nothing and writes the format of its locale. The text, the order and
    the line breaks must be the same.
  - Six list reports of the corpus are compared. A report the transpiler
    does not run as a program is left out: a header line (`zr2c_14`,
    `zr2c_36`) or a FORM with TABLES (`zr2c_03`).

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

- `test/browser/browser.test.mjs` - the same backend, the real app: every
  corpus class in headless Chromium (Playwright, `lib/browser.mjs`), the UI5
  frontend of abap2UI5 against the transpiled backend. It passes when UI5
  boots, the view renders, Execute of a selection screen runs, and no page
  error, no failed roundtrip and no error popup show on the way. UI5 comes
  from the `@openui5` devDependencies (the page's requests for
  `sdk.openui5.org` are answered from them, so it runs offline), the way
  abap2UI5/samples-controls runs its e2e smoke. It found what the JSON
  protocol could not: a width in `ch` that UI5 rejects (the app ended before
  its first screen) and `HIDE` of a structure. Chromium is Playwright's own
  (`npx playwright install chromium`), else `REPORT2CLOUD_CHROMIUM`;
  `REPORT2CLOUD_BROWSER_PORT` (default 4482) is the port. `startAll( {
  browser: true } )` of `lib/start.mjs` (`web.mjs --browser`) adds it as the
  last stage of a measurement.

CI runs all of it in `.github/workflows/report2cloud.yaml` - the runtime test
and the browser test as jobs of their own, with mcp-server cloned beside the
repository.
