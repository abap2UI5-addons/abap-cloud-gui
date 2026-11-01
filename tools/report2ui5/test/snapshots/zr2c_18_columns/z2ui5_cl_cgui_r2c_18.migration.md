# report2UI5: ZR2C_18_COLUMNS → z2ui5_cl_cgui_r2c_18

| | |
|---|---|
| Source | `zr2c_18_columns.prog.abap` |
| Text pool | `zr2c_18_columns.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_18.clas.abap`, `z2ui5_cl_cgui_r2c_18.clas.xml` |
| Mapped | 32 construct(s) |
| TODO | 0 |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- REPORT ... LINE-COUNT n is set_line_count( n ) - a page holds n lines of the list besides its header and footer; the classic n counted them too

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_18_columns LINE-COUNT 30 NO STANDARD PAGE HEADING` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 15 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 17 | `START-OF-SELECTION` | `start_of_selection( )` |
| 22 | `WRITE /1 'Flight'` | `write( )` |
| 22 | `WRITE 10 'Date'` | `write( )` |
| 22 | `WRITE 25 'Occupied'` | `write( )` |
| 22 | `WRITE AT gv_col 'Free'` | `write( )` |
| 23 | `ULINE` | `list( )->uline( )` |
| 25 | `RESERVE 2 LINES` | `list( )->reserve( )` - a new page when fewer lines are left (LINE-COUNT) |
| 26 | `WRITE / gs_flight-connid UNDER 'Flight'` | `write( )` |
| 27 | `WRITE gs_flight-fldate UNDER 'Date'` | `write( )` |
| 28 | `WRITE AT 25(8) gs_flight-seatsocc` | `write( )` |
| 29 | `WRITE AT gv_col(6) gs_flight-seatsmax NO-GAP` | `write( )` |
| 29 | `WRITE '-'` | `write( )` |
| 30 | `HIDE gs_flight` | `hide = gs_flight` at the hotspot of the line, restored in `at_line_selection( )` |
| 33 | `ULINE` | `list( )->uline( )` |
| 34 | `POSITION 25` | `list( )->position( )` - the next write( ) starts at that column |
| 35 | `WRITE gv_total` | `write( )` |
| 36 | `WRITE / 'The list ends at line'` | `write( )` |
| 36 | `WRITE sy-linno` | `write( )` |
| 38 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 41 | `sy-lsind = 2` | `set_lsind( )` - the list written becomes that level, Back returns to the one below |
| 44 | `WINDOW STARTING AT 10 5 ENDING AT 70 15` | `window( )` - the secondary list in a dialog box, ENDING AT minus STARTING AT its size |
| 46 | `WRITE / 'Level'` | `write( )` |
| 46 | `WRITE sy-lsind` | `write( )` |
| 46 | `WRITE 'flight'` | `write( )` |
| 46 | `WRITE gs_flight-connid` | `write( )` |
| 47 | `WRITE /5 'Occupied:'` | `write( )` |
| 47 | `WRITE AT 20(8) gs_flight-seatsocc` | `write( )` |
| 48 | `WRITE /5 'Column after the value:'` | `write( )` |
| 48 | `WRITE sy-colno` | `write( )` |
| 49 | `HIDE gs_flight` | `hide = gs_flight` at the hotspot of the line, restored in `at_line_selection( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_18` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_18` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_18_COLUMNS` report = `Z2UI5_CL_CGUI_R2C_18` text = `ZR2C_18_COLUMNS` semantic_object = `Z2UI5_CL_CGUI_R2C_18` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_18`.
