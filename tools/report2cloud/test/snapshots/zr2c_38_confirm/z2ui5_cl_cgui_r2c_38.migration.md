# report2cloud: ZR2C_38_CONFIRM → z2ui5_cl_cgui_r2c_38

| | |
|---|---|
| Source | `zr2c_38_confirm.prog.abap` |
| Text pool | `zr2c_38_confirm.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_38.clas.abap`, `z2ui5_cl_cgui_r2c_38.clas.xml` |
| Mapped | 10 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_38_confirm` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `PARAMETERS p_keep AS CHECKBOX` | attribute `p_keep`, `screen->checkbox( )` |
| 20 | `START-OF-SELECTION` | `start_of_selection( )` |
| 26 | `CALL FUNCTION 'POPUP_TO_CONFIRM' EXPORTING titlebar = 'Clean up' te...` | `popup_to_decide( )` - the answer arrives in `on_popup_1( answer )`, where the statements after the call go on |
| 38 | `IF lv_answer = '1' AND p_keep = abap_false` | `on_popup_1( answer )` - the statements after CALL FUNCTION 'POPUP_TO_CONFIRM' |
| 40 | `WRITE / 'The tasks that are done were deleted.'` | `write( )` |
| 42 | `WRITE / 'Nothing was deleted.'` | `write( )` |
| 44 | `ULINE` | `list( )->uline( )` |
| 46 | `WRITE / ls_todo-done AS CHECKBOX` | `list( )->write_as_checkbox( )` |
| 46 | `WRITE ls_todo-task` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_38` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_38` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_38_CONFIRM` report = `Z2UI5_CL_CGUI_R2C_38` text = `ZR2C_38_CONFIRM` semantic_object = `Z2UI5_CL_CGUI_R2C_38` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_38`.
4. Pin the behaviour with ABAP Unit tests before the next change.
