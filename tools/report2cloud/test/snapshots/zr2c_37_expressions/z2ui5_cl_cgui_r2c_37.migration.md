# report2cloud: ZR2C_37_EXPRESSIONS → z2ui5_cl_cgui_r2c_37

| | |
|---|---|
| Source | `zr2c_37_expressions.prog.abap` |
| Text pool | `zr2c_37_expressions.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_37.clas.abap`, `z2ui5_cl_cgui_r2c_37.clas.xml` |
| Mapped | 12 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_37_expressions` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 23 | `PARAMETERS p_team TYPE c LENGTH 1 DEFAULT 'A'` | attribute `p_team`, `screen->parameter( )` |
| 25 | `START-OF-SELECTION` | `start_of_selection( )` |
| 35 | `WRITE / \|Team { p_team }: { lines( lt_team ) } members, { lv_goals ...` | `write( )` |
| 36 | `ULINE` | `list( )->uline( )` |
| 43 | `WRITE / ls_card-name` | `write( )` |
| 43 | `WRITE ls_card-goals` | `write( )` |
| 43 | `WRITE lv_rating` | `write( )` |
| 43 | `WRITE lv_team` | `write( )` |
| 45 | `ULINE` | `list( )->uline( )` |
| 46 | `WRITE / 'More than five goals:'` | `write( )` |
| 46 | `WRITE concat_lines_of( table = lt_names sep = `, ` )` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_37`.
4. Pin the behaviour with ABAP Unit tests before the next change.
