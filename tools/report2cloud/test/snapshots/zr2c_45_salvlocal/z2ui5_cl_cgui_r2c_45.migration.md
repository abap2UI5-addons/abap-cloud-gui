# report2cloud: ZR2C_45_SALVLOCAL → z2ui5_cl_cgui_r2c_45

| | |
|---|---|
| Source | `zr2c_45_salvlocal.prog.abap` |
| Text pool | `zr2c_45_salvlocal.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_45.clas.abap`, `z2ui5_cl_cgui_r2c_45.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_45.clas.xml` |
| Mapped | 13 construct(s) |
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
| 8 | `REPORT zr2c_45_salvlocal` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `CLASS lcl_pack DEFINITION FINAL` | locals_imp |
| 20 | `CLASS-DATA gt_item TYPE ty_t_item` | `cgui_statics_keep( )` / `cgui_statics_restore( )` - the CLASS-DATA of the local classes kept with the app between two roundtrips |
| 31 | `CLASS lcl_pack IMPLEMENTATION` | locals_imp |
| 50 | `SET HANDLER on_function FOR go_salv->get_event( )` | `go_salv->get_event( )->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 51 | `SET HANDLER on_double_click FOR go_salv->get_event( )` | `go_salv->get_event( )->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 52 | `SET HANDLER on_link FOR go_salv->get_event( )` | `go_salv->get_event( )->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 55 | `MESSAGE lx_salv->get_text( ) TYPE 'I'` | `message( )` |
| 67 | `MESSAGE \|{ lines( lt_row ) } item(s), { lv_total } g\| TYPE 'S'` | `message( )` |
| 72 | `MESSAGE \|{ gt_item[ row ]-name } in row { row }\| TYPE 'S'` | `message( )` |
| 76 | `MESSAGE \|Item { gt_item[ row ]-item } ({ column })\| TYPE 'S'` | `message( )` |
| 80 | `START-OF-SELECTION` | `start_of_selection( )` |
| 82 | `WRITE space` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_45`.
4. Pin the behaviour with ABAP Unit tests before the next change.
