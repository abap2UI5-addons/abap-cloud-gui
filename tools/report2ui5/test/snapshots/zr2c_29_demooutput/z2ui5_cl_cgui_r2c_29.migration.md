# report2UI5: ZR2C_29_DEMOOUTPUT → z2ui5_cl_cgui_r2c_29

| | |
|---|---|
| Source | `zr2c_29_demooutput.prog.abap` |
| Text pool | `zr2c_29_demooutput.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_29.clas.abap`, `z2ui5_cl_cgui_r2c_29.clas.xml` |
| Mapped | 3 construct(s) |
| TODO | 0 |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_29_demooutput` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `PARAMETERS p_min TYPE i DEFAULT 5` | attribute `p_min`, `screen->parameter( )` |
| 20 | `START-OF-SELECTION` | `start_of_selection( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_29` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_29` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_29_DEMOOUTPUT` report = `Z2UI5_CL_CGUI_R2C_29` text = `ZR2C_29_DEMOOUTPUT` semantic_object = `Z2UI5_CL_CGUI_R2C_29` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_29`.
