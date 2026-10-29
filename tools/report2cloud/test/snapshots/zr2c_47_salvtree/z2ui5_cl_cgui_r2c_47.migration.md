# report2cloud: ZR2C_47_SALVTREE → z2ui5_cl_cgui_r2c_47

| | |
|---|---|
| Source | `zr2c_47_salvtree.prog.abap` |
| Text pool | `zr2c_47_salvtree.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_47.clas.abap`, `z2ui5_cl_cgui_r2c_47.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_47.clas.xml` |
| Mapped | 6 construct(s) |
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
| 7 | `REPORT zr2c_47_salvtree` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 19 | `CLASS lcl_handler DEFINITION` | locals_imp |
| 25 | `CLASS lcl_handler IMPLEMENTATION` | locals_imp |
| 28 | `MESSAGE \|{ lo_node->get_text( ) } picked\| TYPE 'S'` | `message( )` |
| 32 | `START-OF-SELECTION` | `start_of_selection( )` |
| 70 | `SET HANDLER lcl_handler=>on_double_click FOR lo_events` | `lo_events->set_handler( )` - the stand-in keeps the handler and calls it for the event of the browser |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_47` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_47` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_47_SALVTREE` report = `Z2UI5_CL_CGUI_R2C_47` text = `ZR2C_47_SALVTREE` semantic_object = `Z2UI5_CL_CGUI_R2C_47` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_47`.
4. Pin the behaviour with ABAP Unit tests before the next change.
