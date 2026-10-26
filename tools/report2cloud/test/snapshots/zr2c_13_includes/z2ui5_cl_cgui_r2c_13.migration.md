# report2cloud: ZR2C_13_INCLUDES → z2ui5_cl_cgui_r2c_13

| | |
|---|---|
| Source | `zr2c_13_includes.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Includes | inlined: `ZR2C_13_INCLUDES_TOP`, `ZR2C_13_INCLUDES_F01` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_13.clas.abap`, `z2ui5_cl_cgui_r2c_13.clas.xml` |
| Mapped | 11 construct(s) |
| TODO | 1 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for P_COUNT - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

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

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_13`.
4. Pin the behaviour with ABAP Unit tests before the next change.
