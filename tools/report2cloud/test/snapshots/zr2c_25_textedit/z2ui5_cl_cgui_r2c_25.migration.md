# report2cloud: ZR2C_25_TEXTEDIT → z2ui5_cl_cgui_r2c_25

| | |
|---|---|
| Source | `zr2c_25_textedit.prog.abap` |
| Text pool | `zr2c_25_textedit.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_25.clas.abap`, `z2ui5_cl_cgui_r2c_25.clas.xml` |
| Mapped | 18 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 10 | `REPORT zr2c_25_textedit` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 14 | `PARAMETERS p_carrid TYPE c LENGTH 3 DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 24 | `START-OF-SELECTION` | `start_of_selection( )` |
| 27 | `CALL SCREEN 100` | `call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )` |
| 28 | `IF gv_saved = 'X'` | `after_call_screen( )` - WHEN `0100`: the statements after CALL SCREEN 0100 |
| 30 | `WRITE / lv_note` | `write( )` |
| 33 | `WRITE / 'Nothing saved'` | `write( )` |
| 36 | `MODULE status_0100 OUTPUT` | private method `status_0100( )` - the module, called by dynpro_pbo( ) as the flow logic of the screen did |
| 38 | `CREATE OBJECT go_notes EXPORTING container_name = 'NOTES'` | `go_notes = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_container |
| 41 | `CREATE OBJECT go_editor EXPORTING parent = go_notes wordwrap_mode =...` | `go_editor = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_textedit |
| 51 | `CREATE OBJECT go_preview EXPORTING container_name = 'PREVIEW'` | `go_preview = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_container |
| 54 | `CREATE OBJECT go_html EXPORTING parent = go_preview` | `go_html = NEW #( )` - the stand-in z2ui5_cl_cgui_gui_html_viewer |
| 57 | `PERFORM preview` | `preview( )` |
| 61 | `MODULE user_command_0100 INPUT` | private method `user_command_0100( )` - the module, called by dynpro_pai( ) as the flow logic of the screen did |
| 66 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |
| 69 | `PERFORM preview` | `preview( )` |
| 71 | `LEAVE TO SCREEN 0` | `leave_to_screen( dynnr )` and `RETURN` - the modules after it do not run; screen 0 goes back to where CALL SCREEN stood |
| 75 | `FORM preview` | private method `preview( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_25` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_25` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_25_TEXTEDIT` report = `Z2UI5_CL_CGUI_R2C_25` text = `ZR2C_25_TEXTEDIT` semantic_object = `Z2UI5_CL_CGUI_R2C_25` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_25`.
4. Pin the behaviour with ABAP Unit tests before the next change.
