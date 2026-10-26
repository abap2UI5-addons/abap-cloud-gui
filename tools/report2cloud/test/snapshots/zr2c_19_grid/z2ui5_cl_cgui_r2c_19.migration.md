# report2cloud: ZR2C_19_GRID → z2ui5_cl_cgui_r2c_19

| | |
|---|---|
| Source | `zr2c_19_grid.prog.abap` |
| Text pool | `zr2c_19_grid.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_19.clas.abap`, `z2ui5_cl_cgui_r2c_19.clas.xml` |
| Mapped | 52 construct(s) |
| TODO | 0 |
| Release state to check | 1 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | database table | `z2ui5_cl_cgui_r2c_19.clas.abap:9:41` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- ALV layout: zebra stripes and optimized column widths - the grid of the runtime lays itself out

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 10 | `REPORT zr2c_19_grid` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 12 | `CLASS lcl_handler DEFINITION` | dropped - the handlers of the grid are methods of the report class |
| 14 | `METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid I...` | `at_line_selection( row hide )` - the DOUBLE_CLICK handler of the grid, e_row-index is row |
| 16 | `METHODS on_hotspot FOR EVENT hotspot_click OF cl_gui_alv_grid IMPOR...` | `at_link_click( row column )` - the HOTSPOT_CLICK handler of the grid, e_row_id-index is row, e_column_id-fieldname column |
| 18 | `METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid IMPORTING e...` | `add_function( )` in the alv( ) chain - the buttons of the TOOLBAR handler; they arrive in `at_user_command( )` |
| 20 | `METHODS on_user_command FOR EVENT user_command OF cl_gui_alv_grid I...` | `at_user_command( ucomm )` - the USER_COMMAND handler of the grid, e_ucomm is ucomm |
| 26 | `DATA gt_fcat TYPE lvc_t_fcat` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 27 | `DATA gs_fcat TYPE lvc_s_fcat` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 28 | `DATA gs_layout TYPE lvc_s_layo` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 29 | `DATA go_cont TYPE REF TO cl_gui_custom_container` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 30 | `DATA go_grid TYPE REF TO cl_gui_alv_grid` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 31 | `DATA go_handler TYPE REF TO lcl_handler` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 32 | `DATA ok_code TYPE sy-ucomm` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 33 | `DATA gv_save_ok TYPE sy-ucomm` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 35 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 37 | `CLASS lcl_handler IMPLEMENTATION` | dropped - the handlers of the grid are methods of the report class |
| 40 | `MESSAGE \|Flight { gs_flight-connid } on { gs_flight-fldate DATE = U...` | `message( )` |
| 45 | `MESSAGE \|Connection { gs_flight-connid }\| TYPE 'S'` | `message( )` |
| 70 | `MESSAGE \|{ lv_full } full flights\| TYPE 'S'` | `message( )` |
| 72 | `MESSAGE \|{ lines( gt_flight ) } flights\| TYPE 'S'` | `message( )` |
| 77 | `START-OF-SELECTION` | `start_of_selection( )` |
| 81 | `CALL SCREEN 100` | the PBO module of the screen, in its place - the grid shows when the event block is done |
| 83 | `FORM build_fieldcat` | dropped - the FORM only set up the ALV, which the alv( ) chain does now |
| 84 | `CLEAR gs_fcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 85 | `gs_fcat-fieldname = 'CONNID'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 86 | `gs_fcat-coltext = 'Flight'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 87 | `gs_fcat-hotspot = 'X'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 88 | `APPEND gs_fcat TO gt_fcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 89 | `CLEAR gs_fcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 90 | `gs_fcat-fieldname = 'SEATSOCC'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 91 | `gs_fcat-coltext = 'Occupied'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 92 | `gs_fcat-do_sum = 'X'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 93 | `APPEND gs_fcat TO gt_fcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 94 | `CLEAR gs_fcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 95 | `gs_fcat-fieldname = 'MANDT'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 96 | `gs_fcat-no_out = 'X'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 97 | `APPEND gs_fcat TO gt_fcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 100 | `MODULE status_0100 OUTPUT` | inlined at CALL SCREEN - the PBO module status_0100, once (the grid is not created anew on every roundtrip) |
| 101 | `SET PF-STATUS 'MAIN'` | `set_pf_status( )` - 1 function(s) of status MAIN on the toolbar, 1 function key(s) as shortcuts; each arrives in `at_user_command( )` |
| 102 | `IF go_cont IS INITIAL` | dropped - IF on the grid object - the grid is created once, the branch that creates it stays |
| 103 | `CREATE OBJECT go_cont EXPORTING container_name = 'CONTAINER'` | dropped - the grid, its container or the handler object - alv( ) needs none |
| 106 | `CREATE OBJECT go_grid EXPORTING i_parent = go_cont` | dropped - the grid, its container or the handler object - alv( ) needs none |
| 109 | `PERFORM build_fieldcat` | dropped - FORM build_fieldcat only set up the ALV |
| 110 | `gs_layout-grid_title = 'Flights'` | dropped - the title of the grid - set_title( ) in the alv( ) chain |
| 111 | `gs_layout-zebra = 'X'` | dropped - ALV layout - the grid lays itself out |
| 112 | `CREATE OBJECT go_handler` | dropped - the grid, its container or the handler object - alv( ) needs none |
| 113 | `SET HANDLER go_handler->on_double_click go_handler->on_hotspot go_h...` | dropped - SET HANDLER of the grid - its handlers are methods of the class |
| 117 | `CALL METHOD go_grid->set_table_for_first_display EXPORTING is_layou...` | `alv( gt_flight )` - set_table_for_first_display( ) of the grid, the field catalog, the title and the toolbar in the chain |
| 128 | `MODULE user_command_0100 INPUT` | `at_user_command( ucomm )` - the PAI module user_command_0100, the OK code is ucomm; Back, Exit and Cancel are the runtime's |
| 129 | `gv_save_ok = ok_code` | dropped - the OK code is ucomm, a parameter |
| 130 | `CLEAR ok_code` | dropped - the OK code is ucomm, a parameter |
| 133 | `LEAVE TO SCREEN 0` | `leave_to_selection_screen( )` - the screen of the grid is left |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_19`.
4. Pin the behaviour with ABAP Unit tests before the next change.
