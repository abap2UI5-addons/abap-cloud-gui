# report2cloud: ZR2C_34_CONTROLLEVELS → z2ui5_cl_cgui_r2c_34

| | |
|---|---|
| Source | `zr2c_34_controllevels.prog.abap` |
| Text pool | `zr2c_34_controllevels.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_34.clas.abap`, `z2ui5_cl_cgui_r2c_34.clas.xml` |
| Mapped | 15 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- FORMAT INTENSIFIED / INVERSE / INPUT - the list knows only the color and hotspots (2×)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_34_controllevels` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 21 | `START-OF-SELECTION` | `start_of_selection( )` |
| 31 | `WRITE / 'Sales per region'` | `write( )` |
| 32 | `ULINE` | `list( )->uline( )` |
| 35 | `FORMAT INTENSIFIED ON` | applied to the following `write( )` calls of the method (color, hotspot) |
| 36 | `WRITE / ls_sale-region` | `write( )` |
| 37 | `FORMAT INTENSIFIED OFF` | applied to the following `write( )` calls of the method (color, hotspot) |
| 39 | `WRITE /5 ls_sale-month` | `write( )` |
| 39 | `WRITE ls_sale-amount` | `write( )` |
| 43 | `WRITE /5 'Total'` | `write( )` |
| 43 | `WRITE gv_region COLOR COL_TOTAL` | `write( )`, color |
| 44 | `SKIP` | `list( )->skip( )` |
| 48 | `ULINE` | `list( )->uline( )` |
| 49 | `WRITE / 'All regions'` | `write( )` |
| 49 | `WRITE gv_all COLOR COL_TOTAL` | `write( )`, color |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_34` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_34` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_34_CONTROLLEVELS` report = `Z2UI5_CL_CGUI_R2C_34` text = `ZR2C_34_CONTROLLEVELS` semantic_object = `Z2UI5_CL_CGUI_R2C_34` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_34`.
4. Pin the behaviour with ABAP Unit tests before the next change.
