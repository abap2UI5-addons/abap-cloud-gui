# report2cloud: ZR2C_28_BROWSER → z2ui5_cl_cgui_r2c_28

| | |
|---|---|
| Source | `zr2c_28_browser.prog.abap` |
| Text pool | `zr2c_28_browser.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_28.clas.abap`, `z2ui5_cl_cgui_r2c_28.clas.xml` |
| Mapped | 5 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_28_browser` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 17 | `PARAMETERS p_title TYPE string LOWER CASE DEFAULT 'Price list'` | attribute `p_title`, `screen->parameter( )` |
| 18 | `PARAMETERS p_disc TYPE i DEFAULT 10` | attribute `p_disc`, `screen->parameter( )` |
| 20 | `START-OF-SELECTION` | `start_of_selection( )` |
| 39 | `WRITE space` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_28`.
4. Pin the behaviour with ABAP Unit tests before the next change.
