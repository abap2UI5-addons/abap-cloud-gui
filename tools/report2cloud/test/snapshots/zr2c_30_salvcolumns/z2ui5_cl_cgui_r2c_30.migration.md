# report2cloud: ZR2C_30_SALVCOLUMNS → z2ui5_cl_cgui_r2c_30

| | |
|---|---|
| Source | `zr2c_30_salvcolumns.prog.abap` |
| Text pool | `zr2c_30_salvcolumns.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_30.clas.abap`, `z2ui5_cl_cgui_r2c_30.clas.xml` |
| Mapped | 13 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_30_salvcolumns` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `global data - the report restarted after its list` | `CLEAR` of 1 global data object(s) at the start of `start_of_selection( )` |
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

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_30`.
4. Pin the behaviour with ABAP Unit tests before the next change.
