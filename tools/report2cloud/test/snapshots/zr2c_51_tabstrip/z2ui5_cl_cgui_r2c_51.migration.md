# report2cloud: ZR2C_51_TABSTRIP → z2ui5_cl_cgui_r2c_51

| | |
|---|---|
| Source | `zr2c_51_tabstrip.prog.abap` |
| Text pool | `zr2c_51_tabstrip.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_51.clas.abap`, `z2ui5_cl_cgui_r2c_51.clas.xml` |
| Mapped | 13 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_51_tabstrip` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 11 | `CONTROLS tabstr TYPE TABSTRIP` | `TYPE z2ui5_cl_cgui_report=>ty_s_tabstrip` - `activetab` is the function code of the selected tab, as before |
| 14 | `DATA gv_free TYPE c LENGTH 1` | `TYPE abap_bool` - a checkbox or radio button of the dynpro |
| 17 | `START-OF-SELECTION` | `start_of_selection( )` |
| 18 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 19 | `WRITE / 'Airline'` | `after_call_screen( )` - WHEN `0100`: the statements after CALL SCREEN 0100 |
| 19 | `WRITE / 'Airline'` | `write( )` |
| 19 | `WRITE gv_carrid` | `write( )` |
| 21 | `WRITE / 'Only free seats'` | `write( )` |
| 24 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 31 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 40 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |
| 44 | `MODULE check_0110 INPUT` | private method `check_0110( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_51` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_51` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_51_TABSTRIP` report = `Z2UI5_CL_CGUI_R2C_51` text = `ZR2C_51_TABSTRIP` semantic_object = `Z2UI5_CL_CGUI_R2C_51` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_51`.
4. Pin the behaviour with ABAP Unit tests before the next change.
