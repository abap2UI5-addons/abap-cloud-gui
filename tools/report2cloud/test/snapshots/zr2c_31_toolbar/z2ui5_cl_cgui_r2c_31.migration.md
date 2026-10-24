# report2cloud: ZR2C_31_TOOLBAR → z2ui5_cl_cgui_r2c_31

| | |
|---|---|
| Source | `zr2c_31_toolbar.prog.abap` |
| Text pool | `zr2c_31_toolbar.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_31.clas.abap`, `z2ui5_cl_cgui_r2c_31.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_31.clas.xml` |
| Mapped | 7 construct(s) |
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
| 8 | `REPORT zr2c_31_toolbar` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `CLASS lcl_counter DEFINITION` | locals_imp |
| 19 | `CLASS lcl_counter IMPLEMENTATION` | locals_imp |
| 41 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 43 | `START-OF-SELECTION` | `start_of_selection( )` |
| 51 | `SET HANDLER lcl_counter=>on_function FOR go_toolbar` | `go_toolbar->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 55 | `WRITE space` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_31`.
4. Pin the behaviour with ABAP Unit tests before the next change.
