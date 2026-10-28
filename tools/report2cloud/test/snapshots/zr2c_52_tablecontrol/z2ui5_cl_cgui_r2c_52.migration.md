# report2cloud: ZR2C_52_TABLECONTROL → z2ui5_cl_cgui_r2c_52

| | |
|---|---|
| Source | `zr2c_52_tablecontrol.prog.abap` |
| Text pool | `zr2c_52_tablecontrol.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_52.clas.abap`, `z2ui5_cl_cgui_r2c_52.clas.xml` |
| Mapped | 12 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_52_tablecontrol` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 16 | `CONTROLS tc_seats TYPE TABLEVIEW USING SCREEN 100` | `TYPE z2ui5_cl_cgui_report=>ty_s_tableview` - `lines`, `current_line`, `top_line` as before; the browser shows every line, `cols` is not there |
| 21 | `START-OF-SELECTION` | `start_of_selection( )` |
| 25 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 26 | `LOOP AT gt_seat INTO gs_seat` | `after_call_screen( )` - WHEN `0100`: the statements after CALL SCREEN 0100 |
| 27 | `WRITE / gs_seat-connid` | `write( )` |
| 27 | `WRITE gs_seat-seats` | `write( )` |
| 30 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 34 | `MODULE fill_0100 OUTPUT` | private method `fill_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 38 | `MODULE read_0100 INPUT` | private method `read_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 42 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 45 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_52`.
4. Pin the behaviour with ABAP Unit tests before the next change.
