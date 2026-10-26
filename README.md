# abap-cloud-gui

[![abap2UI5-addons](https://img.shields.io/badge/abap2UI5--addons-library-1873b4)](https://github.com/abap2UI5-addons)
[![ABAP](https://img.shields.io/badge/ABAP-Cloud%20%7C%20Standard%20%E2%89%A5%207.50%20%7C%207.02-blue)](#installation)
[![abap2UI5](https://img.shields.io/badge/requires-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![License](https://img.shields.io/github/license/abap2UI5-addons/abap-cloud-gui)](LICENSE)
<br>
[![abaplint](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/abap-cloud-gui/abaplint.yaml?branch=main&label=abaplint)](https://github.com/abap2UI5-addons/abap-cloud-gui/actions/workflows/abaplint.yaml)
[![ABAP Unit](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/abap-cloud-gui/unit.yaml?branch=main&label=ABAP%20Unit)](https://github.com/abap2UI5-addons/abap-cloud-gui/actions/workflows/unit.yaml)
[![check-abap2UI5](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/abap-cloud-gui/check-abap2ui5.yaml?branch=main&label=check-abap2UI5)](https://github.com/abap2UI5-addons/abap-cloud-gui/actions/workflows/check-abap2ui5.yaml)
[![report2cloud](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/abap-cloud-gui/report2cloud.yaml?branch=main&label=report2cloud)](https://github.com/abap2UI5-addons/abap-cloud-gui/actions/workflows/report2cloud.yaml)

**[Try the report converter in the browser](https://abap2ui5-addons.github.io/abap-cloud-gui/#playground)**

**Write abap2UI5 apps the way you write a classic ABAP report.** Selection
screen, `WRITE` list, ALV grid, `START-OF-SELECTION`, `AT LINE-SELECTION`,
`MESSAGE` - the same concepts, running as a UI5 app in the browser. On ABAP
Cloud as well as on NetWeaver down to 7.02.

> Part of [abap2UI5-addons](https://github.com/abap2UI5-addons) - addons and apps for [abap2UI5](https://github.com/abap2UI5/abap2UI5), installed with [abapGit](https://abapgit.org).

## Why

ABAP Cloud has no SAP GUI: no selection screens, no `WRITE` lists, no
`CL_SALV_TABLE`. A quick report that took ten minutes on premise suddenly
needs RAP, CDS and a Fiori app. And writing UI5 views by hand means learning
a new UI model first.

abap-cloud-gui closes that gap. You write a class that looks and reads like a
report - parameters, event blocks, `write( )` - and get a UI5 app with a
selection screen, a result list or ALV grid, drilldown, value helps and
messages. No UI5 knowledge, no CDS, no RAP needed.

Good for:

- **ABAP developers on ABAP Cloud** who need a quick report or tool.
- **Moving reports to ABAP Cloud** - the event blocks and output statements
  map to methods with matching names, so a report keeps its structure.
- **Starting with abap2UI5** in familiar terms before building views yourself.

What it is not:

- **Not a way to run existing reports unchanged.** A report is rewritten as a
  class: event blocks become methods, `PARAMETERS` become attributes, `WRITE`
  becomes `write( )`. The structure stays, the syntax changes -
  [report2cloud](#converting-existing-reports-report2cloud) does most of it.
- **Not a SAP GUI clone.** It uses the classic *programming model*, the screens
  look like modern UI5. If you are looking for SE80, SE16N or SM37 in the
  browser, that is [abap2UI5-addons/sapgui](https://github.com/abap2UI5-addons/sapgui).

## Installation

**Requirements**

- ABAP Cloud (BTP ABAP Environment, S/4HANA Cloud) or Standard ABAP 7.50 or
  higher; NetWeaver 7.02 with a downported copy (see [Compatibility](#compatibility))
- [abap2UI5](https://github.com/abap2UI5/abap2UI5) - nothing else: the popups
  (value help, ranges, confirmation, values, transport request) are classes
  of this addon

**Steps** - with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5)
2. this repository (branch `main`) - classes, two interfaces and the two
   tables `Z2UI5_CGUI_VAR` / `Z2UI5_CGUI_LAY`; nothing else to set up

**Start** - run a sample like any abap2UI5 app, e.g.
`?app_start=z2ui5_cl_cgui_sample_05` for a complete report.

## Quick start

Write your first report:

```abap
CLASS zcl_hello DEFINITION PUBLIC INHERITING FROM z2ui5_cl_cgui_report FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    DATA p_name  TYPE string.
    DATA p_times TYPE i.
  PROTECTED SECTION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
ENDCLASS.

CLASS zcl_hello IMPLEMENTATION.

  METHOD selection_screen.
    screen->parameter( val = p_name text = `Your name` obligatory = abap_true
        )->parameter( val = p_times text = `Lines` ).
  ENDMETHOD.

  METHOD start_of_selection.
    write( |Hello { p_name }!| )->uline( ).
    DO p_times TIMES.
      write( |Line { sy-index }| )->new_line( ).
    ENDDO.
  ENDMETHOD.

ENDCLASS.
```

Start it like any abap2UI5 app (`?app_start=zcl_hello`): the selection screen
comes up, **Execute** runs the report and shows the list, **Back** returns to
the selection screen. For more, run the samples below — `z2ui5_cl_cgui_sample_05`
is a complete report.

## What is there

| Class | Classic counterpart |
|---|---|
| `z2ui5_cl_cgui_report` | the report itself — `INITIALIZATION`, `AT SELECTION-SCREEN OUTPUT`, `AT SELECTION-SCREEN ON field`, `AT SELECTION-SCREEN`, `START-OF-SELECTION`, `AT LINE-SELECTION`, `AT USER-COMMAND`, `AT SELECTION-SCREEN ON VALUE-REQUEST`, `MESSAGE`, `POPUP_TO_CONFIRM` |
| `z2ui5_cl_cgui_selscreen` | `PARAMETERS`, `SELECT-OPTIONS`, `SELECTION-SCREEN BEGIN OF BLOCK / LINE`, `COMMENT`, `PUSHBUTTON`, `AS CHECKBOX`, `RADIOBUTTON GROUP`, `OBLIGATORY`, `NO-DISPLAY`, `MODIF ID`, `USER-COMMAND`, `LOOP AT SCREEN` / `MODIFY SCREEN`, F4 and the multiple selection of a select-option |
| `z2ui5_cl_cgui_list` | `WRITE`, `NEW-LINE`, `SKIP`, `ULINE`, `NEW-PAGE`, `FORMAT COLOR`, `HOTSPOT`, `HIDE`, `AS CHECKBOX`, `AS ICON` |
| `z2ui5_cl_cgui_alv` | `CL_SALV_TABLE` — columns and headers from RTTI/DDIC, sort, filter, double click |
| `z2ui5_cl_cgui_tree` | `CL_SALV_TREE` — an ALV tree with lazy nodes and checkboxes |
| `z2ui5_cl_cgui_variant` | selection variants — get, save, delete, start with a variant |
| `z2ui5_cl_cgui_variant_db` | the server store of the selection variants — table `Z2UI5_CGUI_VAR`, shared and protected variants |
| `z2ui5_cl_cgui_layout`, `z2ui5_cl_cgui_layout_db` | the ALV layout dialog and the store of the layouts — table `Z2UI5_CGUI_LAY`, shared, protected and a default per user |
| `z2ui5_cl_cgui_context` | helpers — among them `range_check( )`, the `IN` of a select-option for internal tables |

Everything is ABAP Cloud ready, transpilable to Node and downportable to
7.02: classes, two interfaces, the two tables with their data elements -
no programs, no tooling on the stack. Reports are converted with
[report2cloud](#converting-existing-reports-report2cloud), which runs in Node.

All views are built with `z2ui5_cl_ui5_view_builder`. The selection screen,
the list and the ALV can also be used on their own inside any abap2UI5 app:
each has `render( )` to append itself to a view and `stringify( )` to return
a complete view.

### The report runtime

Inherit from `z2ui5_cl_cgui_report`, declare the selection screen fields as
**PUBLIC** attributes and redefine the event blocks you need:

| Method | When it runs |
|---|---|
| `initialization` | once, before the selection screen is shown — set defaults here |
| `selection_screen( screen )` | every time the selection screen is shown — the layout |
| `at_selection_screen_output( screen )` | right after `selection_screen` — hide fields, make them read-only or required |
| `at_selection_screen_on( field )` | after Execute, once per field shown — `message( type = 'E' )` marks the field and stops |
| `at_selection_screen` | after Execute — `message( type = 'E' )` keeps the user on the selection screen |
| `start_of_selection` | read the data, output it with `write( )` or `alv( )` |
| `top_of_page` | when the list of a run gets its first line, before it — the page header |
| `at_line_selection( row hide )` | a hotspot of the list or a row of the ALV was clicked |
| `at_user_command( ucomm )` | a button of the selection screen, a checkbox or radio button group with `user_command`, or a confirmed `popup_to_confirm( )` |
| `at_value_request( field )` | F4 on a field — the default is the standard F4 of its DDIC type; redefine it for your own and call `super->` for the rest |

Messages follow the classic semantics — `S` as a toast, `I` as a box, `E`
stops the run — and every message of a run but `S` is collected in the
**message popover**: a button at the left of the footer counts them, in red
for an error, and `W` and `E` open the popover by themselves. A message that
belongs to a field — raised in `at_selection_screen_on( )`, or with
`message( field = 'P_QTY' )` — marks that field with its text, names it in
the popover, and a click on it puts the cursor into the field. Fields
declared `obligatory` are checked before `at_selection_screen`, each empty
one with a message of its own.

The short API, in the style of abap2UI5, says the same in fewer words, and
its calls chain:

```abap
_msg( )->w( `Only the first 100 flights` )->s( `Flights read` ).
_msg( )->e( text = `Enter a carrier` field = `P_CARRID` ).      " MESSAGE ... TYPE 'E'
_msg_box( )->i( `Saved` ).                                    " a box of its own, the run goes on
_popup( )->confirm( question = `Post the document?` ucomm = `POST` ).
_popup( )->decide( question = `Which copy?` options = VALUE #( ( `Original` ) ( `Copy` ) ) ucomm = `PICK` ).
```

`_msg( )` is `message( )`, `_msg_box( )` a message box whatever the type -
not in the popover, an error does not stop the run - and `_popup( )` has the
popups of the report: the answer comes as `at_user_command( ucomm )`.

### The application log

`set_log( )` gives the report an application log: every message - `MESSAGE`,
`message( )`, `_msg( )` - goes into it as well. `z2ui5_cl_cgui_log` keeps the
messages in memory; an adapter of the installation implements
`z2ui5_if_cgui_log` (`add`, `get`) and writes them where the system keeps its
logs. `messages_from_log( )` puts the messages of a log into the message
popover - a BAPI's return table, read with `add_table( )`, or a log of the
system - and `log_display( )` shows a log as a popup, as SLG1 does.

```abap
" an adapter on ABAP Cloud - cl_bali_log
METHOD z2ui5_if_cgui_log~add.
  mo_log->add_item( cl_bali_free_text_setter=>create( severity = type text = CONV #( text ) ) ).
ENDMETHOD.

" an adapter for the ABAP Logger
METHOD z2ui5_if_cgui_log~add.
  CASE type.
    WHEN 'E'. mo_logger->e( text ).
    WHEN 'W'. mo_logger->w( text ).
    WHEN OTHERS. mo_logger->i( text ).
  ENDCASE.
ENDMETHOD.
```

### The command field

`set_command_field( )` in `initialization( )` puts the command field of the
SAP GUI into the page header - a converted report has it from the start:

| Typed | What happens |
|---|---|
| `ZFLIGHTS` | a transaction of the catalog starts, Back returns |
| `/nZFLIGHTS`, `/n` | the transaction, or this report anew |
| `/oZFLIGHTS`, `/o` | the same in a new browser tab |
| `ONLI`, `BACK`, `PRI` | Execute, Back, Print |
| any other code | `at_user_command( )`, as a function of the screen |

The transactions come from the installation: an object of
`z2ui5_if_cgui_catalog` (`set_catalog( )`) returns code, report class, text
and the variant to start with; a report class name works without a catalog.
`Ctrl+K` (`Cmd+K` on a Mac) opens the command palette - the transactions and
the functions of the screen in a popup to search.

### The last entries

Every field remembers what was run with it: the last ten values - of a
parameter, or the first line of a select-option - stay in the browser's local
storage, one history per report, and the field suggests them as the user
types. `set_prefill_last( )` in `initialization( )` goes one step further: an
empty field starts with its latest entry. A parameter ID fills a field first,
a start variant and the URL win over the history.

### A dynamic selection screen

`MODIF ID`, `USER-COMMAND` and `LOOP AT SCREEN` work as in a classic report:
a radio button group or a checkbox with `user_command` runs
`at_user_command( )` as soon as the user changes it, and the selection screen
is built anew — `at_selection_screen_output( )` included.

```abap
METHOD selection_screen.
  screen->radiobutton( val = p_disp   text = `Display` group = `MODE` user_command = `MODE`
      )->radiobutton( val = p_create text = `Create`  group = `MODE`
      )->parameter( val = p_matnr text = `Material`    modif_id = `DIS`
      )->parameter( val = p_name  text = `Description` modif_id = `CRE` ).
ENDMETHOD.

METHOD at_selection_screen_output.
  DATA(lt_screen) = screen->loop_at_screen( ).
  LOOP AT lt_screen INTO DATA(ls_screen).
    CASE ls_screen-group1.
      WHEN `DIS`. ls_screen-active = p_disp.
      WHEN `CRE`. ls_screen-active = p_create.
    ENDCASE.
    screen->modify_screen( ls_screen ).
  ENDLOOP.
ENDMETHOD.
```

A line of `loop_at_screen( )` has `name`, `group1`, `active`, `input`,
`required` and `invisible` — as `abap_bool`, not `'0'` / `'1'`. `active` hides
the field with its label (a block with no field left disappears), `input`
makes it read-only, `required` obligatory, `invisible` masks the input like a
password.

### Value helps

Every parameter and select-option whose DDIC type has a standard F4 gets it
without code: the **fixed values of the domain**, or — on premise — its
**value table**. Fields declared with `value_help = abap_true` get F4 too and
are answered in `at_value_request( )`, with any table:

```abap
METHOD at_value_request.
  CASE field.
    WHEN `P_CARRID` OR `S_CARRID`.
      value_help_popup( tab = lt_carrier col = `CARRID` title = `Airlines` ).
    WHEN OTHERS.
      super->at_value_request( field ).   " the standard F4
  ENDCASE.
ENDMETHOD.
```

On a select-option F4 picks any number of values, which become lines
`I EQ` — the ones already selected come up checked. A button beside the
field opens the range popup, the classic multiple selection, for every
other condition.

### Selection variants

The footer of every selection screen has **Get Variant**, **Save as
Variant** and **Delete Variant**: a variant keeps every field of the screen
— parameters, select-options with all their lines, hidden `NO-DISPLAY`
fields — under a name, and the list of variants shows what each one holds.
A report starts with a variant through the URL (`&variant=Q1`) or from
`initialization( )`:

```abap
METHOD initialization.
  set_variant( `DEFAULT` ).   " if the user saved one - silently skipped if not
ENDMETHOD.
```

The variants are kept in table `Z2UI5_CGUI_VAR`
(`z2ui5_cl_cgui_variant_db`), one namespace per report class — nothing to
set up, on ABAP Cloud as on premise: shared with all users, protected against
changes of others, one owner each. A store of your own - another table, a
RAP business object - implements `z2ui5_if_cgui_variant_store` (load, save,
delete, check_sharing) and is set with `set_variant_store( store )` in
`initialization( )`. `set_variant_store( )` without a store keeps the
variants in the browser's local storage instead - per browser and device,
another device starts without them:

```abap
METHOD initialization.
  set_variant_store( ).   " the browser's local storage, no table
ENDMETHOD.
```

The user parameters - `SET` / `GET PARAMETER ID`, `MEMORY ID` - live in the
same store: one entry per user, so every report of the user sees them, on
every device. `SU3` in the command field opens them in a popup to change, add
or delete (an empty value deletes the parameter). Without a server store
they stay in the browser's local storage.

### ALV layouts

The layout button of every ALV opens the classic "Change Layout": the
columns shown and their order, sort, totals and subtotals. A layout is saved
under a name, shared with all users or protected when wanted, and one of
them is the user's default - the report starts with it. They are kept in
table `Z2UI5_CGUI_LAY` (`z2ui5_cl_cgui_layout_db`), one namespace per report
class and ALV. A store of your own implements `z2ui5_if_cgui_layout_store`
and is set with `set_layout_store( store )` in `initialization( )`;
`set_layout_store( )` without a store keeps the layouts with the selection
variants.

### Output to keep

**Chart** shows the rows of the ALV - its filter and search applied - as a
bar chart in a dialog: the user picks the column of the categories and the
number to sum, or counts the rows; the 20 largest bars, the rest as one.
OpenUI5 has no sap.viz, so `z2ui5_cl_cgui_chart` draws it as SVG of plain
attributes, which the page's content security policy lets in.
`set_chart( abap_false )` takes the button off the toolbar.

**Export** writes the ALV as CSV or as an Excel file (Office Open XML, zipped
with `CL_ABAP_ZIP` - no `CL_SALV_TABLE`). **Print** hands the output to the
browser as a PDF - ABAP Cloud has no spool. The PDF is written in ABAP
(`z2ui5_cl_cgui_pdf`) in Courier, a font every PDF reader has, so nothing is
embedded; a wide list turns the page to landscape and shrinks the font.

**Execute in Background** shows on the selection screen once the report has
a job: `set_job( )` in `initialization( )` with an object of
`z2ui5_if_cgui_job`. The button runs the checks of Execute and hands the
report class and the values of the screen to `schedule( )`; how the job runs
is up to the installation - an application job on ABAP Cloud, a background
job on premise. The job creates the class and runs it without a browser:

```abap
" in the job - report and values as schedule( ) got them
DATA lo_report TYPE REF TO z2ui5_cl_cgui_report.
CREATE OBJECT lo_report TYPE (report).
lo_report->cgui_run_in_background( EXPORTING values   = values
                                   IMPORTING pdf      = DATA(lv_pdf)
                                             messages = DATA(lt_msg) ).
" lv_pdf as the attachment of a mail, or into a table of your own
```

## Samples

| Class | Shows |
|---|---|
| `z2ui5_cl_cgui_sample_01` | the selection screen on its own — every field type, blocks, a line, a button |
| `z2ui5_cl_cgui_sample_02` | the list on its own — colors, checkbox, icon, pages, hotspots with `HIDE` |
| `z2ui5_cl_cgui_sample_03` | the ALV on its own — column texts, a hidden column, row click |
| `z2ui5_cl_cgui_sample_04` | the smallest report — hello world |
| `z2ui5_cl_cgui_sample_05` | a complete report — select-option, F4 help, radio buttons for ALV or list, drilldown, reset with a confirmation popup, starts with the variant `DEFAULT` |
| `z2ui5_cl_cgui_sample_06` | a dynamic selection screen — `MODIF ID`, `USER-COMMAND`, `LOOP AT SCREEN`, read-only and password fields, `NO-DISPLAY`, `AT SELECTION-SCREEN ON field` |
| `z2ui5_cl_cgui_sample_07` | value helps — standard F4 from domain fixed values and value table, own F4 for a parameter and a select-option |
| `z2ui5_cl_cgui_sample_11` | a dynpro — `CALL SCREEN`, PBO with status and `LOOP AT SCREEN`, PAI with a push button, `LEAVE TO SCREEN 0` and the list after the screen |


### The converted reports: src/03

`src/03` holds report classes as report2cloud writes them - the reports of
its test corpus (`tools/report2cloud/test/corpus`) converted, not touched by
hand: the test set to pull onto a system and run, `?app_start=z2ui5_cl_cgui_r2c_01`
and so on. Only the reports that need nothing ABAP Cloud lacks are in it
(no SFLIGHT, SPFLI, SCARR - those convert too, see the snapshots), so the
repository installs on every target. The converter test keeps `src/03` equal
to the conversion; `UPDATE_SNAPSHOTS=1 npm run test:report2cloud` writes it
anew.

| Class | Report |
|---|---|
| `z2ui5_cl_cgui_r2c_01` | `zr2c_01_hello` - The smallest report |
| `z2ui5_cl_cgui_r2c_03` | `zr2c_03_forms` - An order simulation in FORMs |
| `z2ui5_cl_cgui_r2c_06` | `zr2c_06_dynamic` - A dynamic selection screen |
| `z2ui5_cl_cgui_r2c_08` | `zr2c_08_listformat` - The list statements |
| `z2ui5_cl_cgui_r2c_09` | `zr2c_09_localclass` - A report with local classes |
| `z2ui5_cl_cgui_r2c_11` | `zr2c_11_legacy` - Older statements |
| `z2ui5_cl_cgui_r2c_12` | `zr2c_12_pages` - Pages of a list - LINE-COUNT, TOP-OF-PAGE with the page number |
| `z2ui5_cl_cgui_r2c_13` | `zr2c_13_includes` - A report in three pieces, as a grown one is |
| `z2ui5_cl_cgui_r2c_22` | `zr2c_22_files` - The files of the user |
| `z2ui5_cl_cgui_r2c_23` | `zr2c_23_dynpro` - A dynpro of fields |
| `z2ui5_cl_cgui_r2c_25` | `zr2c_25_textedit` - Notes of an airline on a dynpro with two SAP GUI controls |
| `z2ui5_cl_cgui_r2c_26` | `zr2c_26_events` - The events of SAP GUI controls, handled by a local class |
| `z2ui5_cl_cgui_r2c_28` | `zr2c_28_browser` - A price list as an HTML page |
| `z2ui5_cl_cgui_r2c_29` | `zr2c_29_demooutput` - A small inventory written with cl_demo_output |
| `z2ui5_cl_cgui_r2c_30` | `zr2c_30_salvcolumns` - Exam results in a CL_SALV_TABLE grid, every column header its name and its text |
| `z2ui5_cl_cgui_r2c_31` | `zr2c_31_toolbar` - A toolbar and an HTML viewer on the screen itself |
| `z2ui5_cl_cgui_r2c_32` | `zr2c_32_xmlpopup` - An order as XML in a window of its own |
| `z2ui5_cl_cgui_r2c_33` | `zr2c_33_strings` - A name split into its parts and rebuilt |
| `z2ui5_cl_cgui_r2c_34` | `zr2c_34_controllevels` - Sales per region and month with the classic control levels |
| `z2ui5_cl_cgui_r2c_35` | `zr2c_35_dates` - Dates of a project |
| `z2ui5_cl_cgui_r2c_36` | `zr2c_36_ranges` - A product list filtered with select-options on local data |
| `z2ui5_cl_cgui_r2c_37` | `zr2c_37_expressions` - The constructor expressions of a team roster |
| `z2ui5_cl_cgui_r2c_38` | `zr2c_38_confirm` - Cleaning up a to-do list |
| `z2ui5_cl_cgui_r2c_39` | `zr2c_39_textedit` - A note editor on the screen itself |
| `z2ui5_cl_cgui_r2c_40` | `zr2c_40_sapevent` - A menu as an HTML page on the screen |

## Converting existing reports: report2cloud

A report that exists already does not have to be rewritten by hand.
[`tools/report2cloud`](tools/report2cloud/README.md) converts a classic
report into a report class of this addon - `PARAMETERS` and
`SELECT-OPTIONS` into attributes and `selection_screen( )`, the event blocks
into the methods of the same name, `WRITE` / `FORMAT` / `HIDE` into the list,
`CL_SALV_TABLE` and `REUSE_ALV_GRID_DISPLAY` into `alv( )`, `MESSAGE` into
`message( )`, FORMs into methods:

```bash
npm ci
npm run report2cloud -- zflights.prog.abap --out src/02
```

The includes of a report are read from beside it, as abapGit writes them,
and macros are expanded at their calls. It is deterministic and refuses
rather than guesses: what has no counterpart in a browser app (`CALL SCREEN`,
dynpro modules, batch input, `SUBMIT`, native SQL) is reported with file,
line and column. `npm run report2cloud:coverage -- <dir>` converts a whole
folder of reports in memory and says how many convert and what stops the
rest - the measurement the roadmap below is ordered by. Next to the class it writes a
migration report - the TODOs, and the tables and APIs that are not released on
ABAP Cloud, with their successors as hints: the work list for a person or an
AI model, checked with abaplint's ABAP Cloud rules, the abap2UI5 linter and
unit tests.

report2cloud is the generator of this repository: there is no converter or
painter on the stack any more, the conversion runs in Node, on the reports
of an abapGit export.

## Compatibility

- **ABAP Cloud** and **Standard ABAP**; **NW 7.02** through a downport — the
  source is written in 7.50 syntax and every release is checked in CI (see
  below).
- **UI5 1.71** is the floor, as for abap2UI5 itself.
- The views and the report flow have been driven end to end in the
  transpiled abap2UI5 backend (Node.js) in a headless browser.

Known limitations:

- ALV cells show dates and times as the model carries them (`2026-01-05`),
  not in the user's format yet.
- In the transpiled JavaScript runtime, `IN` only knows `I EQ`, `E EQ` and
  `I CP` — use `z2ui5_cl_cgui_context=>range_check( )` for internal tables if
  the report must also run there. On an SAP system `IN` and
  `SELECT ... WHERE ... IN` work as usual.
- `WRITE ... CURRENCY` takes the decimals of the currency from ISO 4217,
  `UNIT` formats the number as it is — `TCURX` and `T006` are not released on
  ABAP Cloud. Print is a PDF in the browser, not a spool request.
- Value tables are read on premise only — on ABAP Cloud the DDIC is not
  read, and the standard F4 is the domain's fixed values.
- `alv( )` binds a PUBLIC attribute directly; any other table is copied into
  a data reference, which the draft has to rebuild with RTTI on every
  roundtrip.

## Roadmap

**Done**

- [x] Phase 0 — cleanup: `z2ui5_cl_cgui` prefix, packages `01` core / `02`
      samples, CI for v750, ABAP Cloud and 7.02, abap2UI5-linter, unit tests
- [x] Phase 1 — report runtime: event blocks, selection screen ↔ output,
      Execute / Back
- [x] Phase 2 — selection screen: parameters by type, checkbox, radio button
      groups, blocks, lines, comments, push buttons, select-options with the
      range popup, `OBLIGATORY`, F4 through `at_value_request`; fields are
      found by reference, `select_option( )` needs no name
- [x] Phase 3 — output: ALV grid (RTTI/DDIC columns, sort, filter, row click),
      `WRITE` list (colors, icons, checkboxes, pages, hotspots, `HIDE`)
- [x] Phase 4 — messages with classic semantics, `POPUP_TO_CONFIRM`
- [x] Phase 5 — dynamic selection screen: `AT SELECTION-SCREEN OUTPUT` with
      `LOOP AT SCREEN` / `MODIFY SCREEN` (hide, read-only, required,
      invisible), `MODIF ID`, `USER-COMMAND` at checkboxes and radio button
      groups, `NO-DISPLAY`, `AT SELECTION-SCREEN ON field` and messages with
      the value state on their field; unit tests for the selection screen
- [x] Phase 6 — value helps: standard F4 from domain fixed values (ABAP
      Cloud and on premise) and value tables (on premise), automatic for
      every DDIC-typed field; F4 with multiple selection on select-options,
      preselected, the range popup on a button of its own
- [x] Phase 7 — selection variants: get, save as, delete, start with a
      variant from the URL or `set_variant( )`, kept in the browser's local
      storage
- [x] Phase 8 — selection screen painter (since replaced by report2cloud:
      reports and classes are generated in Node, not on the stack)
- [x] Phase 9 — message popover: the messages of a run in one place,
      counted in the footer, opened by W and E, each message of a field
      leading to the field; one message per empty required field

**Next**

The order is the measurement's: `report2cloud:coverage` over a corpus of
real reports says which construct stops the most of them, and that construct
is next. Every stage is a release of its own.

Stage 0 - release, and the number to move

- [ ] A release of this addon with report2cloud and the MCP server's
      `migrate_report`; the documentation's preview note goes
- [x] A corpus of real reports: the open-source ABAP of the web, converted
      weekly (`report2cloud:web`), the share that converts without a refusal
      and the refusals ranked in the job summary - the number every stage
      below is measured by
- [x] The share of the web corpus that starts in the transpiled runtime:
      `report2cloud:web --start` checks, builds and starts the converted
      reports weekly, the funnel and where they stopped in the job summary
      (first run: 74 of 596 converted reports start, 82 with the upload
      dialog of `GUI_UPLOAD` and `cl_demo_output`; most of the others read
      a class or table of their repository the sparse clone lacks)
- [x] A site with the converter in the browser - GitHub Pages, the
      playground converts a pasted report on the page (`npm run site`)
- [x] `report2cloud:coverage` - the measurement over a folder of reports
- [x] Includes inlined from beside the report, macros expanded

Stage 1 - the converter: the constructs that stop the most reports

- [x] Tables with a header line (`OCCURS`, `WITH HEADER LINE`) rewritten
      into a table and a work area - mechanical, and in every report older
      than 7.0
- [x] `SUBMIT ... AND RETURN` and `CALL SELECTION-SCREEN`: the called report
      converted with the caller and started with `submit( )`, its `WITH`
      values handed over; a screen of the report's own as a dialog, the
      statements after the call continued in `after_call_selection_screen( )`
      - reports call reports
- [x] The synchronous popups (`POPUP_TO_CONFIRM`, `POPUP_TO_CONFIRM_STEP`,
      `POPUP_TO_DECIDE`, `POPUP_GET_VALUES`): the event block cut at the
      call, the rest continued in `at_user_command( )` - the one
      transformation that changes a block's shape, and the one in every
      report that posts something
- [x] `SET PF-STATUS`, `SET TITLEBAR`, `AT PFnn` as `set_pf_status( )`,
      toolbar functions and the keyboard shortcuts of the runtime - the
      status read from the `<CUA>` of the `.prog.xml`
- [x] Secondary lists (`sy-lsind`) and `WRITE AT` positions, in a column
      mode of the list (every item of a line with a position in a box of
      its width in characters) - the evaluations that live by the column
- [x] `cl_gui_alv_grid` in a container with its simple handlers (hotspot,
      double click, toolbar, user command) as `alv( )`, the screen's PBO and
      PAI modules resolved - the ALV every report since 2005 is written with
- [x] `AT SELECTION-SCREEN ON HELP-REQUEST`, `SELECTION-SCREEN FUNCTION KEY`,
      `TABBED BLOCK` and `BEGIN OF SCREEN` (`AS WINDOW` and `AS SUBSCREEN`)
      on the runtime's own counterparts
- [x] A documentation page per refusal: why, and the rewrite that unblocks it
      ([tools/report2cloud/docs/refusals.md](tools/report2cloud/docs/refusals.md),
      linked from every refusal of the migration report)

Stage 2 - the runtime: what a report's user sees

Selection screen

- [ ] Value helps: CDS value helps (`@Consumption.valueHelpDefinition`),
      text tables beside value tables, search helps, F4 inside the range
      popup of a select-option
- [x] `AT SELECTION-SCREEN ON BLOCK`, `ON RADIOBUTTON GROUP`, `AS LISTBOX`
- [x] `MEMORY ID`
- [x] A phone layout of the selection screen: labels above the fields, a
      select-option's from and to and a line of fields wrap instead of
      squeezing (the browser test checks it at 390 px, themed)
- [x] Selection variants on the server (table `Z2UI5_CGUI_VAR`): shared
      and protected variants, a pluggable store beside the browser's local
      storage, dynamic date values

Output

- [x] ALV: Excel export (Office Open XML), layouts on the server (table
      `Z2UI5_CGUI_LAY`, shared, protected, a default per user)
- [x] ALV: formatted dates, times and amounts (the locale of the browser),
      totals and subtotals, hotspot per column, toolbar with own functions,
      editable cells
- [x] ALV: a chart over the grid - a bar chart of the rows shown, the filter
      and search applied, a column as the categories and a number summed
      (or the rows counted), drawn as SVG
- [ ] ALV chart: several columns as series, other kinds of chart
- [x] List: `WRITE AT` positions and `UNDER`, columns that line up
      (every item of a positioned line in a box of its width), secondary
      lists (`sy-lsind`, `set_lsind( )`)
- [x] Print as PDF; "Execute in background" hands report and values to a job
      of the installation (`set_job( )`), which gets the list and its PDF

Messages and logging

- [x] Short API in the style of abap2UI5: `_msg( )->e( )`, `_msg_box( )->e( )`,
      `_popup( )->decide( )` / `confirm( )` / `get_values( )`
- [x] Application log (BAL) and [ABAP Logger](https://github.com/ABAP-Logger/ABAP-Logger)
      as a source for the message popover and a log popup: `set_log( )`,
      `messages_from_log( )`, `log_display( )` over `z2ui5_if_cgui_log`

Dialogs and screens

- [x] Popups: transport request selection - `popup_transport( )` /
      `_popup( )->transport( )`, `z2ui5_cl_cgui_transport`, beside
      `POPUP_TO_DECIDE` and `POPUP_GET_VALUES`; no popup of another addon is
      needed any more
- [ ] `CALL SCREEN` of a screen in another class - `CALL SCREEN` of the
      report's own screens and back is there
- [ ] `CALL SELECTION-SCREEN` of another report, as a popup or by screen number

Navigation and transactions

- [ ] Launchpad tiles and intent navigation for a converted class
- [x] Command field instead of a plain input: transaction codes, `/n`, `/o`
      (`set_command_field( )`, `set_catalog( )`)
- [x] Command palette (`Cmd+K` / `Ctrl+K`) to search and start reports
- [x] Input history: the last ten entries of a field, in the browser's local
      storage, suggested as the user types
- [x] Keyboard shortcuts: F8 Execute, F3 Back, `AT PFnn` and the function
      keys of a GUI status (`set_pf_status( shortcuts = )`)
- [x] Transaction logic: start with a variant, prefill the last entries
      (`set_prefill_last( )`)
- [ ] Transaction logic: create a draft
- [x] `SET` / `GET PARAMETER ID` with user parameters on the server, `SU3` in
      the command field to maintain them
- [ ] System parameters and customizing parameters beside the user parameters

Stage 3 - clean core at the scale of a code base

- [x] A `SELECT` from a table with a known released successor rewritten,
      field names included, where the mapping is certain (`--successors`)
- [x] A wrapper stub for an unreleased function module, for a person to type
      and release (`--wrappers`: `<class>_fmw`, the call through its method)
- [ ] ATC findings in the migration report
- [x] A whole package converted in one run (`tools/report2cloud/package.mjs`):
      the dependency graph over `SUBMIT` and `PERFORM ... IN PROGRAM`, the
      order to migrate in, one coverage table for the estate, the refusals
      ranked across it

Stage 4 - in the browser, and with an agent

- [ ] The converter in the abap2UI5 playground: drop a `.prog.abap` into the
      AI Studio, the class runs on the stage, the refusals are the model's
      work list - nothing to install
- [x] `migrate_report` in the MCP server with the class deployed into the
      sandbox and its first screen answered
- [ ] An evaluation harness for the AI loop: a model works the migration
      reports of the corpus, and the share that ends clean is measured

Stage 5 - research

- [x] Simple dynpros: the screens of fields of the .prog.xml (texts,
      inputs, checkboxes, radio buttons, frames, push buttons) built with
      the selection-screen builder in `dynpro_screen( )`, the modules
      methods called by `dynpro_pbo( )` / `dynpro_pai( )`, `CALL SCREEN`,
      `SET SCREEN`, `LEAVE TO SCREEN` and the statements after the call in
      `after_call_screen( )`
- [x] The SAP GUI controls of a custom control area or a docking container:
      the containers, the text editor and the HTML viewer as stand-ins of the
      same methods (`z2ui5_cl_cgui_gui*`), in a local class too
- [x] Their events: the toolbar (`function_selected`, `dropdown_clicked`),
      the SAPEVENT links of the HTML viewer, the close of a dialog box -
      `SET HANDLER` as `set_handler( )` of the stand-in
- [x] The grid in a local class: the stand-in `z2ui5_cl_cgui_gui_alv_grid`,
      the ALV of the report in its container, with its toolbar, user
      command, double click and hotspot
- [x] Controls on the screen itself (`cl_gui_container=>default_screen`):
      toolbar, text editor and HTML viewer above the list of the run, no
      dynpro needed; `cl_abap_browser` as the stand-in
      `z2ui5_cl_cgui_abap_browser`; the loop over the columns of a SALV
      grid; static event handlers of a local class
- [x] `cl_demo_output` (in 72 reports of the web corpus): the stand-in
      `z2ui5_cl_cgui_demo_output` writes into the list - values, structures
      and tables as columns, sections as headings
- [ ] More than one grid, F1 of the editor, the tree and the picture; table
      controls, subscreens and tabstrips on a dynpro

Quality, through every stage

- [x] Tests for the report runtime and the ALV with a client test double
      (`ltcl_client` of the report, the ALV's own), beside the selection
      screen's
- [ ] Samples in the abap2UI5 playground, a documentation page
- [ ] Semantic tests: the classic report and its class driven against the
      same seeded rows in the transpiled runtime, their lists compared

Later

- [x] Tree lists: `RS_TREE_CONSTRUCT` / `RS_TREE_LIST_DISPLAY` as the ALV tree
      of the report
- [x] `CL_SALV_TREE` as a stand-in, as `CL_SALV_TABLE` is: the nodes, their
      relationships, the columns, the tree settings, `double_click` and
      `checkbox_change` to the handlers

## Development

```bash
npm ci
npm run lint            # abaplint, v750 syntax + downport rule
npm run check:cloud     # abaplint, ABAP Cloud
npm run check:702       # downport a scratch copy to 7.02 and check it
npm run check:abap2ui5  # abap2UI5-linter over apps and views
npm run check:regex     # no regular expressions in src/
npm run unit            # ABAP Unit in the transpiled backend (needs ../mcp-server)
npm run test:report2cloud  # the report converter: snapshots and abaplint over its output
npm run site            # the GitHub Pages site with the converter playground into build/site (-- --serve: on :8080)
```

The ABAP Unit tests run in CI in the transpiled abap2UI5 backend
(`.github/workflows/unit.yaml`, `scripts/unit.mjs` with
[abap2UI5/mcp-server](https://github.com/abap2UI5/mcp-server) as a library),
the tables of the two stores in SQLite.

## Contributing

Issues and pull requests are welcome. Read [AGENTS.md](AGENTS.md) first - it
holds the layout, the release targets and the rules of this repository.

## License

MIT - see [LICENSE](LICENSE).
