# report2cloud: ZR2C_41_PICTURE → z2ui5_cl_cgui_r2c_41

| | |
|---|---|
| Source | `zr2c_41_picture.prog.abap` |
| Text pool | `zr2c_41_picture.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_41.clas.abap`, `z2ui5_cl_cgui_r2c_41.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_41.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_41.clas.xml` |
| Mapped | 11 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- a local class whose instance the report keeps implements if_serializable_object - the app is serialized between two roundtrips, its attributes with it
- DP_CREATE_URL is z2ui5_cl_cgui_frontend=>dp_create_url( ) - the URL names a data URI of the bytes, which the picture and the HTML viewer of the browser show
- local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_41_picture` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `CLASS lcl_stamp DEFINITION` | locals_def |
| 19 | `PARAMETERS p_fit AS CHECKBOX DEFAULT 'X'` | attribute `p_fit`, `screen->checkbox( )` |
| 21 | `global data - the report restarted after its list` | `CLEAR` of 1 global data object(s) at the start of `start_of_selection( )` |
| 23 | `CLASS lcl_stamp IMPLEMENTATION` | locals_imp |
| 32 | `CALL FUNCTION 'DP_CREATE_URL' EXPORTING type = 'image' subtype = 'g...` | `z2ui5_cl_cgui_frontend=>dp_create_url( )` - the function module as the method of the frontend services, its EXCEPTIONS kept |
| 44 | `MESSAGE 'No URL for the stamp' TYPE 'E'` | `message( )` |
| 55 | `SET HANDLER on_click FOR mo_picture` | `mo_picture->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 60 | `MESSAGE \|{ mv_count } stamp(s)\| TYPE 'S'` | `message( )` |
| 64 | `START-OF-SELECTION` | `start_of_selection( )` |
| 66 | `WRITE / 'Click the stamp'` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_41`.
4. Pin the behaviour with ABAP Unit tests before the next change.
