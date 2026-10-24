# report2cloud: ZR2C_27_GRIDLOCAL → z2ui5_cl_cgui_r2c_27

| | |
|---|---|
| Source | `zr2c_27_gridlocal.prog.abap` |
| Text pool | `zr2c_27_gridlocal.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_27.clas.abap`, `z2ui5_cl_cgui_r2c_27.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_27.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_27.clas.xml` |
| Mapped | 15 construct(s) |
| TODO | 0 |
| Release state to check | 3 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SPFLI` | database table | `z2ui5_cl_cgui_r2c_27.clas.locals_imp.abap:4:45` | /DMO/CONNECTION (ABAP Flight Reference Scenario) |
| `LVC_S_LAYO` | DDIC type | `z2ui5_cl_cgui_r2c_27.clas.locals_imp.abap:41:33` | - |
| `LVC_T_FCAT` | DDIC type | `z2ui5_cl_cgui_r2c_27.clas.locals_def.abap:9:20` | - |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- a local class whose instance the report keeps implements if_serializable_object - the app is serialized between two roundtrips, its attributes with it
- local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 10 | `REPORT zr2c_27_gridlocal` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 12 | `CLASS lcl_alv DEFINITION FINAL` | locals_def |
| 30 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 33 | `CLASS lcl_alv IMPLEMENTATION` | locals_imp |
| 45 | `SET HANDLER on_toolbar FOR grid` | `grid->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 46 | `SET HANDLER on_user_command FOR grid` | `grid->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 47 | `SET HANDLER on_double_click FOR grid` | `grid->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 48 | `SET HANDLER on_hotspot FOR grid` | `grid->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 71 | `MESSAGE \|{ ls_connection-carrid } { ls_connection-connid }\| TYPE 'S'` | `message( )` |
| 76 | `MESSAGE \|{ e_column_id-fieldname }: { ls_connection-cityfrom }\| TYP...` | `message( )` |
| 81 | `START-OF-SELECTION` | `start_of_selection( )` |
| 82 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 84 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 92 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 95 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_27`.
4. Pin the behaviour with ABAP Unit tests before the next change.
