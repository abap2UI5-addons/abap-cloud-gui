# report2cloud: ZR2C_22_FILES → z2ui5_cl_cgui_r2c_22

| | |
|---|---|
| Source | `zr2c_22_files.prog.abap` |
| Text pool | `zr2c_22_files.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_22.clas.abap`, `z2ui5_cl_cgui_r2c_22.clas.xml` |
| Mapped | 23 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- cl_gui_frontend_services is z2ui5_cl_cgui_frontend - a file the user picks is uploaded in the browser (file_open_dialog( ) in an F4 opens the upload, the F4 runs again with the file), gui_download( ) is a download of the browser (4×)
- MESSAGE ... DISPLAY LIKE 'E' - a status or info message displayed as an error becomes a warning (shown in the popover, the run goes on)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_22_files` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 21 | `PARAMETERS p_file TYPE string LOWER CASE OBLIGATORY` | attribute `p_file`, `screen->parameter( )` |
| 22 | `PARAMETERS p_save AS CHECKBOX` | attribute `p_save`, `screen->checkbox( )` |
| 24 | `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file` | `at_value_request( field )` - WHEN `P_FILE`, the field declared with value_help |
| 25 | `PERFORM pick_file CHANGING p_file` | `pick_file( )` |
| 27 | `START-OF-SELECTION` | `start_of_selection( )` |
| 28 | `CALL FUNCTION 'GUI_UPLOAD' EXPORTING filename = p_file filetype = '...` | `z2ui5_cl_cgui_frontend=>gui_upload( )` - the function module as the method of the frontend services, its EXCEPTIONS kept |
| 39 | `MESSAGE \|File { p_file } cannot be read\| TYPE 'S' DISPLAY LIKE 'E'` | `message( )` |
| 43 | `WRITE / 'Seats per airline'` | `write( )` |
| 44 | `ULINE` | `list( )->uline( )` |
| 46 | `WRITE / ls_seats-carrid` | `write( )` |
| 46 | `WRITE ls_seats-seats` | `write( )` |
| 49 | `ULINE` | `list( )->uline( )` |
| 50 | `WRITE / 'Total'` | `write( )` |
| 50 | `WRITE gv_total` | `write( )` |
| 53 | `PERFORM save_total` | `save_total( )` |
| 56 | `FORM pick_file CHANGING cv_file TYPE string` | private method `pick_file( )` |
| 61 | `CALL METHOD cl_gui_frontend_services=>file_open_dialog EXPORTING wi...` | `z2ui5_cl_cgui_frontend=>...` - the same method, parameters and exceptions, for the files in the browser |
| 77 | `FORM save_total` | private method `save_total( )` |
| 84 | `cl_gui_frontend_services=>file_save_dialog( EXPORTING default_file_...` | `z2ui5_cl_cgui_frontend=>...` - the same method, parameters and exceptions, for the files in the browser |
| 96 | `cl_gui_frontend_services=>gui_download( EXPORTING filename = lv_ful...` | `z2ui5_cl_cgui_frontend=>...` - the same method, parameters and exceptions, for the files in the browser |
| 104 | `MESSAGE \|Saved as { lv_name }\| TYPE 'S'` | `message( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_22`.
4. Pin the behaviour with ABAP Unit tests before the next change.
