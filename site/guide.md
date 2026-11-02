---
title: Guide
description: Write an abap2UI5 app like a classic ABAP report, install abap-cloud-gui and convert the reports you have with report2UI5.
---

# Guide

abap-cloud-gui is an addon of [abap2UI5](https://github.com/abap2UI5/abap2UI5).
A report is a class that inherits from `z2ui5_cl_cgui_report`: the event blocks
are methods of the same name, `PARAMETERS` and `SELECT-OPTIONS` are attributes,
`write( )` writes the list, `alv( )` shows a grid. The full reference is the
[README](https://github.com/abap2UI5-addons/abap-cloud-gui#readme).

## A report as a class

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
comes up, **Execute** runs the report and shows the list, **Back** returns.

## Into your system

Install with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5) - the only dependency.
2. abap-cloud-gui - pull a release tag, or import the zip of its
   [GitHub release](https://github.com/abap2UI5-addons/abap-cloud-gui/releases).
   `abap-cloud-gui-X.Y.Z-702.zip` is the copy downported to NW 7.02.

Then run a sample like any abap2UI5 app, e.g.
`?app_start=z2ui5_cl_cgui_sample_05` for a complete report.

A class converted in the [playground](/playground) comes into the system the
same way: **abapGit zip** under the class gives you its files - in abapGit,
*New Offline* repository, *Import zip*, pull.

## Converting reports

A report that exists already does not have to be rewritten by hand.
**report2UI5** converts a classic report into a report class of this addon -
`PARAMETERS` and `SELECT-OPTIONS` into attributes and `selection_screen( )`,
the event blocks into the methods of the same name, `WRITE` / `FORMAT` /
`HIDE` into the list, `CL_SALV_TABLE` and `REUSE_ALV_GRID_DISPLAY` into
`alv( )`, `MESSAGE` into `message( )`, FORMs into methods.

- **In the browser** - the [samples](/samples) show the reports of the
  converter's corpus converted; the [playground](/playground) converts your
  own report - pasted, imported from GitHub, or the abapGit zip of a whole
  package. The class starts right there as an abap2UI5 app.
- **On the command line** - for a folder of reports:

  ```bash
  npm ci
  npm run report2ui5 -- zflights.prog.abap --out src/02
  ```

It is deterministic and refuses rather than guesses: a part of the user
interface that has no counterpart in a browser app (`CALL SCREEN` without its
screen, dynpro modules, reading the list back by index) is reported with file,
line and column. The logic of the report - its tables, function modules,
native SQL - is copied as it is. The mapping and the refusals are in the
[report2UI5 README](https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2ui5/README.md).

## How it is checked

| Target | Gate |
|---|---|
| ABAP Cloud | abaplint with released APIs only |
| Standard ABAP 7.50 | abaplint, every rule |
| NW 7.02 | abaplint on a downported copy |
| UI5 1.71 | the abap2UI5 linter |
| Transpiled Node runtime | every ABAP Unit test, and every converted sample report driven through the UI5 protocol |

Every week the converter also runs over the open-source ABAP of the web - the
share that converts, the refusals ranked, and how many of the converted
reports start in the transpiled runtime.
