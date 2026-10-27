# report2cloud: ZR2C_50_LISTTREE → z2ui5_cl_cgui_r2c_50

| | |
|---|---|
| Source | `zr2c_50_listtree.prog.abap` |
| Text pool | `zr2c_50_listtree.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_50.clas.abap`, `z2ui5_cl_cgui_r2c_50.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_50.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_50.clas.xml` |
| Mapped | 13 construct(s) |
| TODO | 0 |
| Release state to check | 2 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SCARR` | database table | `z2ui5_cl_cgui_r2c_50.clas.locals_imp.abap:20:44` | /DMO/CARRIER (ABAP Flight Reference Scenario) |
| `SPFLI` | database table | `z2ui5_cl_cgui_r2c_50.clas.locals_imp.abap:21:47` | /DMO/CONNECTION (ABAP Flight Reference Scenario) |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- a local class whose instance the report keeps implements if_serializable_object - the app is serialized between two roundtrips, its attributes with it
- local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_50_listtree` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 11 | `CLASS lcl_tree DEFINITION FINAL` | locals_def |
| 25 | `CLASS lcl_tree IMPLEMENTATION` | locals_imp |
| 33 | `CREATE OBJECT tree EXPORTING parent = NEW cl_gui_custom_container( ...` | `tree = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_list_tree |
| 68 | `SET HANDLER on_item_double_click FOR tree` | `tree->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 69 | `SET HANDLER on_link_click FOR tree` | `tree->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 73 | `MESSAGE \|{ node_key } { item_name }\| TYPE 'S'` | `message( )` |
| 77 | `MESSAGE \|Open { node_key }\| TYPE 'S'` | `message( )` |
| 82 | `START-OF-SELECTION` | `start_of_selection( )` |
| 83 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 85 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 92 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 95 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_50`.
4. Pin the behaviour with ABAP Unit tests before the next change.
