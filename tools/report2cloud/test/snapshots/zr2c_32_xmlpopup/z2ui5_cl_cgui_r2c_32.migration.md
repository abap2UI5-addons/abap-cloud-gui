# report2cloud: ZR2C_32_XMLPOPUP → z2ui5_cl_cgui_r2c_32

| | |
|---|---|
| Source | `zr2c_32_xmlpopup.prog.abap` |
| Text pool | `zr2c_32_xmlpopup.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_32.clas.abap`, `z2ui5_cl_cgui_r2c_32.clas.xml` |
| Mapped | 5 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_32_xmlpopup` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 9 | `PARAMETERS p_order TYPE c LENGTH 10 DEFAULT '4711'` | attribute `p_order`, `screen->parameter( )` |
| 10 | `PARAMETERS p_qty TYPE i DEFAULT 3` | attribute `p_qty`, `screen->parameter( )` |
| 12 | `START-OF-SELECTION` | `start_of_selection( )` |
| 16 | `WRITE / \|Order { p_order } with { p_qty } item(s) shown as XML\|` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_32` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_32` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_32_XMLPOPUP` report = `Z2UI5_CL_CGUI_R2C_32` text = `ZR2C_32_XMLPOPUP` semantic_object = `Z2UI5_CL_CGUI_R2C_32` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_32`.
4. Pin the behaviour with ABAP Unit tests before the next change.
