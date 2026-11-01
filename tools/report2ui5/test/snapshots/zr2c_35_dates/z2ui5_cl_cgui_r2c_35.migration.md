# report2UI5: ZR2C_35_DATES → z2ui5_cl_cgui_r2c_35

| | |
|---|---|
| Source | `zr2c_35_dates.prog.abap` |
| Text pool | `zr2c_35_dates.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_35.clas.abap`, `z2ui5_cl_cgui_r2c_35.clas.xml` |
| Mapped | 20 construct(s) |
| TODO | 0 |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_35_dates` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `PARAMETERS p_start TYPE d DEFAULT '20260105'` | attribute `p_start`, `screen->parameter( )` |
| 11 | `PARAMETERS p_end TYPE d DEFAULT '20260320'` | attribute `p_end`, `screen->parameter( )` |
| 12 | `PARAMETERS p_days TYPE i DEFAULT 10` | attribute `p_days`, `screen->parameter( )` |
| 14 | `START-OF-SELECTION` | `start_of_selection( )` |
| 22 | `MESSAGE 'The end is before the start' TYPE 'E'` | `message( )` |
| 27 | `WRITE / 'Days between start and end:'` | `write( )` |
| 27 | `WRITE lv_between` | `write( )` |
| 37 | `WRITE / \|After { p_days } working days:\|` | `write( )` |
| 37 | `WRITE lv_day` | `write( )` |
| 48 | `ULINE` | `list( )->uline( )` |
| 49 | `WRITE / 'First of the month:'` | `write( )` |
| 49 | `WRITE lv_first` | `write( )` |
| 49 | `WRITE lt_weekday[ ( lv_first - lc_monday ) MOD 7 + 1 ]` | `write( )` |
| 50 | `WRITE / 'Last of the month:'` | `write( )` |
| 50 | `WRITE lv_last` | `write( )` |
| 50 | `WRITE lt_weekday[ ( lv_last - lc_monday ) MOD 7 + 1 ]` | `write( )` |
| 51 | `WRITE / 'Start:'` | `write( )` |
| 51 | `WRITE p_start` | `write( )` |
| 51 | `WRITE lt_weekday[ ( p_start - lc_monday ) MOD 7 + 1 ]` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_35` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_35` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_35_DATES` report = `Z2UI5_CL_CGUI_R2C_35` text = `ZR2C_35_DATES` semantic_object = `Z2UI5_CL_CGUI_R2C_35` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_35`.
