# report2cloud: ZR2C_30_SALVCOLUMNS → z2ui5_cl_cgui_r2c_30

| | |
|---|---|
| Source | `zr2c_30_salvcolumns.prog.abap` |
| Text pool | `zr2c_30_salvcolumns.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_30.clas.abap`, `z2ui5_cl_cgui_r2c_30.clas.xml` |
| Mapped | 12 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_30_salvcolumns` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 20 | `PARAMETERS p_pass TYPE i DEFAULT 50` | attribute `p_pass`, `screen->parameter( )` |
| 22 | `START-OF-SELECTION` | `start_of_selection( )` |
| 31 | `cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_salv) CHAN...` | dropped - cl_salv_table=>factory( ) - alv( ) at display( ) |
| 34 | `LOOP AT lo_salv->get_columns( )->get( ) ASSIGNING FIELD-SYMBOL(<ls_...` | dropped - the texts of every column - a LOOP over get_columns( ) of the grid after alv( ) |
| 35 | `DATA(lo_column) = <ls_column>-r_column` | dropped - the texts of every column - a LOOP over get_columns( ) of the grid after alv( ) |
| 36 | `lo_column->set_short_text( \|\| )` | dropped - the texts of every column - a LOOP over get_columns( ) of the grid after alv( ) |
| 37 | `lo_column->set_medium_text( \|\| )` | dropped - the texts of every column - a LOOP over get_columns( ) of the grid after alv( ) |
| 38 | `lo_column->set_long_text( \|{ lo_column->get_columnname( ) } ({ lo_c...` | dropped - the texts of every column - a LOOP over get_columns( ) of the grid after alv( ) |
| 39 | `ENDLOOP` | dropped - the texts of every column - a LOOP over get_columns( ) of the grid after alv( ) |
| 41 | `lo_salv->get_display_settings( )->set_list_header( 'Exam results' )` | dropped - CL_SALV_TABLE setting - in the alv( ) chain |
| 42 | `lo_salv->display( )` | `alv( gt_result )` with the column settings |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_30` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_30` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_30_SALVCOLUMNS` report = `Z2UI5_CL_CGUI_R2C_30` text = `ZR2C_30_SALVCOLUMNS` semantic_object = `Z2UI5_CL_CGUI_R2C_30` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_30`.
4. Pin the behaviour with ABAP Unit tests before the next change.
