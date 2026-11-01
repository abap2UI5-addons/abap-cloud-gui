# report2UI5: ZR2C_37_EXPRESSIONS → z2ui5_cl_cgui_r2c_37

| | |
|---|---|
| Source | `zr2c_37_expressions.prog.abap` |
| Text pool | `zr2c_37_expressions.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_37.clas.abap`, `z2ui5_cl_cgui_r2c_37.clas.xml` |
| Mapped | 12 construct(s) |
| TODO | 0 |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_37_expressions` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 23 | `PARAMETERS p_team TYPE c LENGTH 1 DEFAULT 'A'` | attribute `p_team`, `screen->parameter( )` |
| 25 | `START-OF-SELECTION` | `start_of_selection( )` |
| 35 | `WRITE / \|Team { p_team }: { lines( lt_team ) } members, { lv_goals ...` | `write( )` |
| 36 | `ULINE` | `list( )->uline( )` |
| 43 | `WRITE / ls_card-name` | `write( )` |
| 43 | `WRITE ls_card-goals` | `write( )` |
| 43 | `WRITE lv_rating` | `write( )` |
| 43 | `WRITE lv_team` | `write( )` |
| 45 | `ULINE` | `list( )->uline( )` |
| 46 | `WRITE / 'More than five goals:'` | `write( )` |
| 46 | `WRITE concat_lines_of( table = lt_names sep = `, ` )` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_37` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_37` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_37_EXPRESSIONS` report = `Z2UI5_CL_CGUI_R2C_37` text = `ZR2C_37_EXPRESSIONS` semantic_object = `Z2UI5_CL_CGUI_R2C_37` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_37`.
