# report2UI5: ZR2C_13_INCLUDES → z2ui5_cl_cgui_r2c_13

| | |
|---|---|
| Source | `zr2c_13_includes.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Includes | inlined: `ZR2C_13_INCLUDES_TOP`, `ZR2C_13_INCLUDES_F01` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_13.clas.abap`, `z2ui5_cl_cgui_r2c_13.clas.xml` |
| Mapped | 11 construct(s) |
| TODO | 1 |

## TODO

- no selection text in the text pool for P_COUNT - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_13_includes` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| zr2c_13_includes_top.prog.abap:13 | `PARAMETERS p_count TYPE i DEFAULT 3` | attribute `p_count`, `screen->parameter( )` |
| zr2c_13_includes_top.prog.abap:16 | `DEFINE add_and_write` | nothing - the macro is expanded at every call |
| zr2c_13_includes_f01.prog.abap:4 | `FORM fill_lines` | private method `fill_lines( )` |
| 14 | `START-OF-SELECTION` | `start_of_selection( )` |
| 15 | `PERFORM fill_lines` | `fill_lines( )` |
| 17 | `add_and_write gs_line-qty gs_line-text` | the statements of the macro, expanded at the call |
| 17 | `WRITE / gs_line-text` | `write( )` |
| 17 | `WRITE gs_line-qty` | `write( )` |
| 19 | `WRITE / 'Total:'` | `write( )` |
| 19 | `WRITE gv_total` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_13` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_13` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_13_INCLUDES` report = `Z2UI5_CL_CGUI_R2C_13` text = `ZR2C_13_INCLUDES` semantic_object = `Z2UI5_CL_CGUI_R2C_13` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_13`.
