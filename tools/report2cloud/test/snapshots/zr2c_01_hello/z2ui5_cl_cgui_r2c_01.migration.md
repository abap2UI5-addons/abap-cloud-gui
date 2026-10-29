# report2cloud: ZR2C_01_HELLO → z2ui5_cl_cgui_r2c_01

| | |
|---|---|
| Source | `zr2c_01_hello.prog.abap` |
| Text pool | `zr2c_01_hello.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_01.clas.abap`, `z2ui5_cl_cgui_r2c_01.clas.xml` |
| Mapped | 11 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 6 | `REPORT zr2c_01_hello` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 8 | `PARAMETERS p_name TYPE string LOWER CASE OBLIGATORY` | attribute `p_name`, `screen->parameter( )` |
| 9 | `PARAMETERS p_times TYPE i DEFAULT 3` | attribute `p_times`, `screen->parameter( )` |
| 11 | `START-OF-SELECTION` | `start_of_selection( )` |
| 12 | `WRITE / 'Hello'` | `write( )` |
| 12 | `WRITE p_name` | `write( )` |
| 13 | `ULINE` | `list( )->uline( )` |
| 15 | `WRITE / 'Line'` | `write( )` |
| 15 | `WRITE sy-index` | `write( )` |
| 17 | `SKIP` | `list( )->skip( )` |
| 18 | `WRITE / 'Done.'` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_01` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_01` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_01_HELLO` report = `Z2UI5_CL_CGUI_R2C_01` text = `ZR2C_01_HELLO` semantic_object = `Z2UI5_CL_CGUI_R2C_01` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_01`.
4. Pin the behaviour with ABAP Unit tests before the next change.
