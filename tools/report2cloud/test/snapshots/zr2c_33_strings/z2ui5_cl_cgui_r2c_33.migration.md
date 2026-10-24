# report2cloud: ZR2C_33_STRINGS → z2ui5_cl_cgui_r2c_33

| | |
|---|---|
| Source | `zr2c_33_strings.prog.abap` |
| Text pool | `zr2c_33_strings.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_33.clas.abap`, `z2ui5_cl_cgui_r2c_33.clas.xml` |
| Mapped | 25 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_33_strings` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `PARAMETERS p_name TYPE string LOWER CASE DEFAULT 'ada augusta lovel...` | attribute `p_name`, `screen->parameter( )` |
| 12 | `START-OF-SELECTION` | `start_of_selection( )` |
| 13 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 19 | `WRITE / 'Input:'` | `write( )` |
| 19 | `WRITE p_name` | `write( )` |
| 20 | `WRITE / 'Condensed:'` | `write( )` |
| 20 | `WRITE lv_clean` | `write( )` |
| 21 | `WRITE / 'Parts:'` | `write( )` |
| 21 | `WRITE lines( lt_part )` | `write( )` |
| 22 | `ULINE` | `list( )->uline( )` |
| 26 | `WRITE / sy-tabix` | `write( )` |
| 26 | `WRITE lv_word` | `write( )` |
| 26 | `WRITE strlen( lv_part )` | `write( )` |
| 29 | `ULINE` | `list( )->uline( )` |
| 37 | `WRITE / 'Initials:'` | `write( )` |
| 37 | `WRITE lv_initials` | `write( )` |
| 38 | `WRITE / 'Upper case:'` | `write( )` |
| 38 | `WRITE lv_upper` | `write( )` |
| 39 | `WRITE / 'With dashes:'` | `write( )` |
| 39 | `WRITE lv_dashed` | `write( )` |
| 40 | `WRITE / 'Vowels raised:'` | `write( )` |
| 40 | `WRITE lv_vowels` | `write( )` |
| 41 | `WRITE / 'Reversed:'` | `write( )` |
| 41 | `WRITE reverse( lv_clean )` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_33`.
4. Pin the behaviour with ABAP Unit tests before the next change.
