# report2cloud: ZR2C_26_EVENTS → z2ui5_cl_cgui_r2c_26

| | |
|---|---|
| Source | `zr2c_26_events.prog.abap` |
| Text pool | `zr2c_26_events.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_26.clas.abap`, `z2ui5_cl_cgui_r2c_26.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_26.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_26.clas.xml` |
| Mapped | 19 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- a local class whose instance the report keeps implements if_serializable_object - the app is serialized between two roundtrips, its attributes with it
- local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_26_events` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 13 | `CLASS lcl_app DEFINITION` | locals_def |
| 31 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 34 | `CLASS lcl_app IMPLEMENTATION` | locals_imp |
| 37 | `CREATE OBJECT mo_cont EXPORTING container_name = 'CC'` | `mo_cont = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_container |
| 40 | `CREATE OBJECT mo_split EXPORTING parent = mo_cont rows = 2 columns = 1` | `mo_split = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_container |
| 45 | `CREATE OBJECT mo_toolbar EXPORTING parent = mo_split->get_container...` | `mo_toolbar = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_toolbar |
| 59 | `SET HANDLER me->on_function FOR mo_toolbar` | `mo_toolbar->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 61 | `CREATE OBJECT mo_html EXPORTING parent = mo_split->get_container( r...` | `mo_html = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_html_viewer |
| 64 | `SET HANDLER me->on_sapevent FOR mo_html` | `mo_html->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 86 | `CREATE OBJECT mo_box EXPORTING caption = 'Details' width = 400 heig...` | `mo_box = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_container |
| 91 | `SET HANDLER me->on_close FOR mo_box` | `mo_box->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 98 | `MESSAGE \|{ action } { ls_query-value }\| TYPE 'S'` | `message( )` |
| 108 | `START-OF-SELECTION` | `start_of_selection( )` |
| 109 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 111 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 113 | `CREATE OBJECT go_app` | `go_app = NEW #( )` |
| 118 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 121 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_26`.
4. Pin the behaviour with ABAP Unit tests before the next change.
