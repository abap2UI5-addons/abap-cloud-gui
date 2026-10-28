# report2cloud: ZR2C_09_LOCALCLASS → z2ui5_cl_cgui_r2c_09

| | |
|---|---|
| Source | `zr2c_09_localclass.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_09.clas.abap`, `z2ui5_cl_cgui_r2c_09.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_09.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_09.clas.xml` |
| Mapped | 12 construct(s) |
| TODO | 1 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for P_A, P_B, P_DEC - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_09_localclass` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 9 | `INTERFACE lif_rounding` | locals_def |
| 15 | `CLASS lcl_calculator DEFINITION FINAL` | locals_def |
| 27 | `CLASS lcl_calculator IMPLEMENTATION` | locals_imp |
| 43 | `PARAMETERS p_a TYPE decfloat34 DEFAULT '1.005'` | attribute `p_a`, `screen->parameter( )` |
| 44 | `PARAMETERS p_b TYPE decfloat34 DEFAULT '2.5'` | attribute `p_b`, `screen->parameter( )` |
| 45 | `PARAMETERS p_dec TYPE i DEFAULT 2` | attribute `p_dec`, `screen->parameter( )` |
| 47 | `START-OF-SELECTION` | `start_of_selection( )` |
| 50 | `WRITE / 'Sum:'` | `write( )` |
| 50 | `WRITE lo_calc->add( iv_a = p_a iv_b = p_b )` | `write( )` |
| 51 | `WRITE / 'Rounded A:'` | `write( )` |
| 51 | `WRITE go_calc->round( p_a )` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_09`.
4. Pin the behaviour with ABAP Unit tests before the next change.
