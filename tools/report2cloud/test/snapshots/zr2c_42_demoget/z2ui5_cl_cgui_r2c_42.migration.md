# report2cloud: ZR2C_42_DEMOGET → z2ui5_cl_cgui_r2c_42

| | |
|---|---|
| Source | `zr2c_42_demoget.prog.abap` |
| Text pool | `zr2c_42_demoget.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_42.clas.abap`, `z2ui5_cl_cgui_r2c_42.clas.xml` |
| Mapped | 5 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_42_demoget` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 18 | `PARAMETERS p_min TYPE i DEFAULT 6` | attribute `p_min`, `screen->parameter( )` |
| 20 | `START-OF-SELECTION` | `start_of_selection( )` |
| 24 | `global data - the report restarted after its list` | `CLEAR` of 1 global data object(s) at the start of `start_of_selection( )` |
| 36 | `WRITE / \|{ lv_total } bottles in the cellar\|` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_42`.
4. Pin the behaviour with ABAP Unit tests before the next change.
