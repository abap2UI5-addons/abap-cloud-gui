# report2cloud: ZR2C_44_CURSOR → z2ui5_cl_cgui_r2c_44

| | |
|---|---|
| Source | `zr2c_44_cursor.prog.abap` |
| Text pool | `zr2c_44_cursor.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_44.clas.abap`, `z2ui5_cl_cgui_r2c_44.clas.xml` |
| Mapped | 7 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_44_cursor` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `START-OF-SELECTION` | `start_of_selection( )` |
| 23 | `WRITE / gs_peak-name HOTSPOT` | `write( )`, hotspot |
| 23 | `WRITE gs_peak-height HOTSPOT` | `write( )`, hotspot |
| 26 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 30 | `GET CURSOR FIELD lv_field VALUE lv_value LINE lv_line` | `z2ui5_cl_cgui_gui=>get_cursor_field( )` - the field, value, line and offset of the click of the line selection, sy-subrc 4 off a field |
| 32 | `WRITE / \|Line { lv_line }: { lv_field } = { condense( lv_value ) }\|` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_44`.
4. Pin the behaviour with ABAP Unit tests before the next change.
