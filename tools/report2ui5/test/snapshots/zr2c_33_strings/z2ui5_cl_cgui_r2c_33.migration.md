# report2UI5: ZR2C_33_STRINGS → z2ui5_cl_cgui_r2c_33

| | |
|---|---|
| Source | `zr2c_33_strings.prog.abap` |
| Text pool | `zr2c_33_strings.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_33.clas.abap`, `z2ui5_cl_cgui_r2c_33.clas.xml` |
| Mapped | 24 construct(s) |
| TODO | 0 |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_33_strings` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `PARAMETERS p_name TYPE string LOWER CASE DEFAULT 'ada augusta lovel...` | attribute `p_name`, `screen->parameter( )` |
| 12 | `START-OF-SELECTION` | `start_of_selection( )` |
| 19 | `WRITE / 'Input:'` | `write( )` |
| 19 | `WRITE p_name` | `write( )` |
| 20 | `WRITE / 'Condensed:'` | `write( )` |
| 20 | `WRITE lv_clean` | `write( )` |
| 21 | `WRITE / 'Parts:'` | `write( )` |
| 21 | `WRITE lines( lt_part )` | `write( )` |
| 22 | `ULINE` | `list( )->uline( )` |
| 26 | `WRITE / sy-tabix` | `write( )` |
| 26 | `WRITE lv_word` | `write( )` |
| 26 | `WRITE strlen( lv_part )` | `write( )` |
| 29 | `ULINE` | `list( )->uline( )` |
| 37 | `WRITE / 'Initials:'` | `write( )` |
| 37 | `WRITE lv_initials` | `write( )` |
| 38 | `WRITE / 'Upper case:'` | `write( )` |
| 38 | `WRITE lv_upper` | `write( )` |
| 39 | `WRITE / 'With dashes:'` | `write( )` |
| 39 | `WRITE lv_dashed` | `write( )` |
| 40 | `WRITE / 'Vowels raised:'` | `write( )` |
| 40 | `WRITE lv_vowels` | `write( )` |
| 41 | `WRITE / 'Reversed:'` | `write( )` |
| 41 | `WRITE reverse( lv_clean )` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_33` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_33` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_33_STRINGS` report = `Z2UI5_CL_CGUI_R2C_33` text = `ZR2C_33_STRINGS` semantic_object = `Z2UI5_CL_CGUI_R2C_33` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_33`.
