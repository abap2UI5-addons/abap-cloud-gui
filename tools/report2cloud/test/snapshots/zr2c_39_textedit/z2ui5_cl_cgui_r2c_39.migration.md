# report2cloud: ZR2C_39_TEXTEDIT → z2ui5_cl_cgui_r2c_39

| | |
|---|---|
| Source | `zr2c_39_textedit.prog.abap` |
| Text pool | `zr2c_39_textedit.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_39.clas.abap`, `z2ui5_cl_cgui_r2c_39.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_39.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_39.clas.xml` |
| Mapped | 9 construct(s) |
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
| 8 | `REPORT zr2c_39_textedit` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `CLASS lcl_note DEFINITION` | locals_def |
| 19 | `PARAMETERS p_text TYPE string LOWER CASE DEFAULT 'Buy milk'` | attribute `p_text`, `screen->parameter( )` |
| 23 | `CLASS lcl_note IMPLEMENTATION` | locals_imp |
| 30 | `SET HANDLER on_function FOR mo_tool` | `mo_tool->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |
| 38 | `cl_gui_cfw=>flush( )` | dropped - cl_gui_cfw=>flush( ): the controls of SAP GUI, nothing to flush in the browser |
| 39 | `MESSAGE \|The note has { strlen( lv_text ) } characters\| TYPE 'S'` | `message( )` |
| 43 | `START-OF-SELECTION` | `start_of_selection( )` |
| 45 | `WRITE space` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_39` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_39` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_39_TEXTEDIT` report = `Z2UI5_CL_CGUI_R2C_39` text = `ZR2C_39_TEXTEDIT` semantic_object = `Z2UI5_CL_CGUI_R2C_39` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_39`.
4. Pin the behaviour with ABAP Unit tests before the next change.
