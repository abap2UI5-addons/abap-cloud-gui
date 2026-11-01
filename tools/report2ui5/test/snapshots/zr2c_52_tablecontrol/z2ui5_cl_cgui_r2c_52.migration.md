# report2UI5: ZR2C_52_TABLECONTROL → z2ui5_cl_cgui_r2c_52

| | |
|---|---|
| Source | `zr2c_52_tablecontrol.prog.abap` |
| Text pool | `zr2c_52_tablecontrol.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_52.clas.abap`, `z2ui5_cl_cgui_r2c_52.clas.xml` |
| Mapped | 12 construct(s) |
| TODO | 0 |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_52_tablecontrol` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 16 | `CONTROLS tc_seats TYPE TABLEVIEW USING SCREEN 100` | `TYPE z2ui5_cl_cgui_report=>ty_s_tableview` - `lines`, `current_line`, `top_line` as before; the browser shows every line, `cols` is not there |
| 21 | `START-OF-SELECTION` | `start_of_selection( )` |
| 25 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 26 | `LOOP AT gt_seat INTO gs_seat` | `after_call_screen( )` - WHEN `0100`: the statements after CALL SCREEN 0100 |
| 27 | `WRITE / gs_seat-connid` | `write( )` |
| 27 | `WRITE gs_seat-seats` | `write( )` |
| 30 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 34 | `MODULE fill_0100 OUTPUT` | private method `fill_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 38 | `MODULE read_0100 INPUT` | private method `read_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 42 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 45 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_52` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_52` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_52_TABLECONTROL` report = `Z2UI5_CL_CGUI_R2C_52` text = `ZR2C_52_TABLECONTROL` semantic_object = `Z2UI5_CL_CGUI_R2C_52` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_52`.
