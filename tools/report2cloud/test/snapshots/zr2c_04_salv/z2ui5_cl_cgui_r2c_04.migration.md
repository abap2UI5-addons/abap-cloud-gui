# report2cloud: ZR2C_04_SALV → z2ui5_cl_cgui_r2c_04

| | |
|---|---|
| Source | `zr2c_04_salv.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_04.clas.abap`, `z2ui5_cl_cgui_r2c_04.clas.xml` |
| Mapped | 28 construct(s) |
| TODO | 1 |
| Release state to check | 1 object(s) |

## TODO

- no selection text in the text pool for S_CARRID, S_CITYFR, P_ROWS - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SPFLI` | database table | `z2ui5_cl_cgui_r2c_04.clas.abap:9:23` | /DMO/CONNECTION (ABAP Flight Reference Scenario) |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- CL_SALV_TABLE settings without a counterpart (optimized widths, toolbar functions, striped rows) - the grid sorts and filters by itself (2×)
- MESSAGE ... DISPLAY LIKE 'E' - a status or info message displayed as an error becomes a warning (shown in the popover, the run goes on)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_04_salv` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 11 | `DATA go_alv TYPE REF TO cl_salv_table` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 12 | `DATA go_columns TYPE REF TO cl_salv_columns_table` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 13 | `DATA go_column TYPE REF TO cl_salv_column_table` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 15 | `SELECT-OPTIONS s_carrid FOR gs_spfli-carrid OBLIGATORY DEFAULT 'LH'` | range attribute `s_carrid`, `screen->select_option( )` |
| 16 | `SELECT-OPTIONS s_cityfr FOR gs_spfli-cityfrom NO INTERVALS` | range attribute `s_cityfr`, `screen->select_option( )` |
| 17 | `PARAMETERS p_rows TYPE i DEFAULT 200` | attribute `p_rows`, `screen->parameter( )` |
| 19 | `START-OF-SELECTION` | `start_of_selection( )` |
| 20 | `PERFORM select_data` | `select_data( )` |
| 21 | `PERFORM display` | `display( )` |
| 23 | `FORM select_data` | private method `select_data( )` |
| 30 | `MESSAGE 'No connections found' TYPE 'S' DISPLAY LIKE 'E'` | `message( )` |
| 34 | `FORM display` | private method `display( )` |
| 35 | `DATA lx_msg TYPE REF TO cx_salv_msg` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 38 | `cl_salv_table=>factory( IMPORTING r_salv_table = go_alv CHANGING t_...` | dropped - cl_salv_table=>factory( ) - alv( ) at display( ) |
| 47 | `go_alv->get_functions( )->set_all( abap_true )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 48 | `go_alv->get_display_settings( )->set_list_header( 'Flight connectio...` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 50 | `go_columns = go_alv->get_columns( )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 51 | `go_columns->set_optimize( abap_true )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 54 | `go_column ?= go_columns->get_column( 'MANDT' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 55 | `go_column->set_technical( abap_true )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 56 | `go_column ?= go_columns->get_column( 'CITYFROM' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 57 | `go_column->set_short_text( 'From' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 58 | `go_column->set_medium_text( 'Departure' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 59 | `go_column->set_long_text( 'Departure city' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 60 | `go_column ?= go_columns->get_column( 'FLTIME' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 61 | `go_column->set_visible( abap_false )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 65 | `go_alv->display( )` | `alv( gt_spfli )` with the column settings |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_04` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_04` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_04_SALV` report = `Z2UI5_CL_CGUI_R2C_04` text = `ZR2C_04_SALV` semantic_object = `Z2UI5_CL_CGUI_R2C_04` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_04`.
4. Pin the behaviour with ABAP Unit tests before the next change.
