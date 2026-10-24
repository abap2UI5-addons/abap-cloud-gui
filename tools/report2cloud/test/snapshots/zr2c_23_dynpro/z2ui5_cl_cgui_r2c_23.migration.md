# report2cloud: ZR2C_23_DYNPRO → z2ui5_cl_cgui_r2c_23

| | |
|---|---|
| Source | `zr2c_23_dynpro.prog.abap` |
| Text pool | `zr2c_23_dynpro.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_23.clas.abap`, `z2ui5_cl_cgui_r2c_23.clas.xml` |
| Mapped | 31 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 12 | `REPORT zr2c_23_dynpro` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 14 | `PARAMETERS p_carrid TYPE c LENGTH 3 DEFAULT 'LH' OBLIGATORY` | attribute `p_carrid`, `screen->parameter( )` |
| 16 | `global data - the report restarted after its list` | `CLEAR` of 8 global data object(s) at the start of `start_of_selection( )` |
| 19 | `DATA gv_window TYPE c LENGTH 1` | `TYPE abap_bool` - a checkbox or radio button of the dynpro |
| 20 | `DATA gv_eco TYPE c LENGTH 1 VALUE 'X'` | `TYPE abap_bool` - a checkbox or radio button of the dynpro |
| 21 | `DATA gv_bus TYPE c LENGTH 1` | `TYPE abap_bool` - a checkbox or radio button of the dynpro |
| 25 | `START-OF-SELECTION` | `start_of_selection( )` |
| 27 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 28 | `IF gv_booked = 'X'` | `after_call_screen( )` - WHEN `0100`: the statements after CALL SCREEN 0100 |
| 29 | `WRITE / 'Booked:'` | `write( )` |
| 29 | `WRITE gv_seats` | `write( )` |
| 29 | `WRITE 'seat(s) on'` | `write( )` |
| 29 | `WRITE p_carrid` | `write( )` |
| 29 | `WRITE gv_connid` | `write( )` |
| 31 | `WRITE / 'Nothing booked'` | `write( )` |
| 37 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 38 | `SET PF-STATUS 'S0100'` | `set_pf_status( )` - 1 function(s) of status S0100 on the toolbar, 1 function key(s) as shortcuts; each arrives in `at_user_command( )` |
| 39 | `SET TITLEBAR 'T0100' WITH p_carrid` | `set_title( )` - the text of title T0100, the WITH values in a string template |
| 40 | `LOOP AT SCREEN` | `LOOP AT screen->loop_at_screen( ) INTO DATA(ls_screen)` - screen-* is ls_screen-*, '0'/'1' are abap_false/abap_true |
| 47 | `MODIFY SCREEN` | `screen->modify_screen( ls_screen )` |
| 52 | `MODULE exit_0100 INPUT` | private method `exit_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 53 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |
| 56 | `MODULE check_connid INPUT` | private method `check_connid( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 58 | `MESSAGE 'No such connection' TYPE 'E'` | `message( )` |
| 62 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 66 | `MESSAGE 'The connection has seats' TYPE 'S'` | `message( )` |
| 69 | `MESSAGE 'Check the connection and enter the seats' TYPE 'E'` | `message( )` |
| 71 | `SET SCREEN 200` | `set_screen( dynnr )` - the next screen when the PAI is done |
| 76 | `MODULE user_command_0200 INPUT` | private method `user_command_0200( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 80 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |
| 82 | `LEAVE TO SCREEN 100` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_23`.
4. Pin the behaviour with ABAP Unit tests before the next change.
