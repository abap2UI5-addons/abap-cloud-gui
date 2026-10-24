# report2cloud: ZR2C_24_GRIDINLINE → z2ui5_cl_cgui_r2c_24

| | |
|---|---|
| Source | `zr2c_24_gridinline.prog.abap` |
| Text pool | `zr2c_24_gridinline.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_24.clas.abap`, `z2ui5_cl_cgui_r2c_24.clas.xml` |
| Mapped | 8 construct(s) |
| TODO | 1 |
| Release state to check | 1 object(s) |

## TODO

- `zr2c_24_gridinline.prog.abap:25:3` - alv( connections ): the table is no attribute of the class - alv( ) copies it into a data reference, which the draft rebuilds with RTTI on every roundtrip; make it a global DATA of the report

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SPFLI` | database table | `z2ui5_cl_cgui_r2c_24.clas.abap:27:19` | /DMO/CONNECTION (ABAP Flight Reference Scenario) |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 10 | `REPORT zr2c_24_gridinline` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 12 | `INITIALIZATION` | `start_of_selection( )` - the report has no selection screen: INITIALIZATION went straight on with START-OF-SELECTION |
| 15 | `DATA(grid) = NEW cl_gui_alv_grid( i_parent = NEW cl_gui_custom_cont...` | dropped - the grid, its container or the handler object - alv( ) needs none |
| 18 | `DATA(fcat) = VALUE lvc_t_fcat( ( fieldname = 'CARRID' coltext = 'Ai...` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 25 | `grid->set_table_for_first_display( EXPORTING i_structure_name = 'SP...` | `alv( connections )` - set_table_for_first_display( ) of the grid, the field catalog, the title and the toolbar in the chain |
| 37 | `CALL SCREEN 100` | the PBO modules of the screen, in its place - the grid shows when the event block is done |
| 40 | `MODULE user_command_0100 INPUT` | `at_user_command( ucomm )` - the PAI module user_command_0100, the OK code is ucomm; Back, Exit and Cancel are the runtime's |
| 43 | `LEAVE TO SCREEN 0` | `leave_to_selection_screen( )` - the screen of the grid is left |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_24`.
4. Pin the behaviour with ABAP Unit tests before the next change.
