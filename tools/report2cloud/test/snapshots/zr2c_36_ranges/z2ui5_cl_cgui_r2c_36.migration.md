# report2cloud: ZR2C_36_RANGES → z2ui5_cl_cgui_r2c_36

| | |
|---|---|
| Source | `zr2c_36_ranges.prog.abap` |
| Text pool | `zr2c_36_ranges.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_36.clas.abap`, `z2ui5_cl_cgui_r2c_36.clas.xml` |
| Mapped | 13 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_36_ranges` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 17 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 20 | `SELECT-OPTIONS s_name FOR gs_product-name` | range attribute `s_name`, `screen->select_option( )` |
| 21 | `SELECT-OPTIONS s_price FOR gs_product-price` | range attribute `s_price`, `screen->select_option( )` |
| 22 | `PARAMETERS p_uniq AS CHECKBOX DEFAULT 'X'` | attribute `p_uniq`, `screen->checkbox( )` |
| 24 | `INITIALIZATION` | `initialization( )` |
| 26 | `APPEND s_price` | `APPEND ls_s_price TO s_price` - the header line is a work area |
| 28 | `START-OF-SELECTION` | `start_of_selection( )` |
| 41 | `WRITE / \|{ lines( gt_product ) } product(s) in the selection\|` | `write( )` |
| 42 | `ULINE` | `list( )->uline( )` |
| 44 | `WRITE / gs_product-group` | `write( )` |
| 44 | `WRITE gs_product-name` | `write( )` |
| 44 | `WRITE gs_product-price` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_36`.
4. Pin the behaviour with ABAP Unit tests before the next change.
