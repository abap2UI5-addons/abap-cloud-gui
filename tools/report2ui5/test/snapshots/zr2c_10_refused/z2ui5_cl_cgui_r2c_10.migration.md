# report2UI5: ZR2C_10_REFUSED → z2ui5_cl_cgui_r2c_10

| | |
|---|---|
| Source | `zr2c_10_refused.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **refused** - 4 statement(s) cannot be mapped, no class written |
| Mapped | 5 construct(s) |
| TODO | 2 |

## Refused

These statements have no counterpart in an abap-cloud-gui report. Rewrite them in the report (or delete them) and convert again.

- `zr2c_10_refused.prog.abap:26:3` - ASSIGN of a field of another program ('(PROG)FIELD') - field symbols to screen or foreign program fields are not available in a class or on ABAP Cloud ([why, and the rewrite](https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2ui5/docs/refusals.md#foreign-field))
- `zr2c_10_refused.prog.abap:36:3` - CALL SCREEN - the dynpro is not converted (a dynpro of fields is, from the .prog.xml - see the MODULE refusals); else build the screen as an abap2UI5 view or a popup ([why, and the rewrite](https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2ui5/docs/refusals.md#dynpro))
- `zr2c_10_refused.prog.abap:38:1` - MODULE - the screens are in the .prog.xml (--texts), which was not passed; with it a dynpro of fields is converted ([why, and the rewrite](https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2ui5/docs/refusals.md#dynpro))
- `zr2c_10_refused.prog.abap:42:1` - MODULE - the screens are in the .prog.xml (--texts), which was not passed; with it a dynpro of fields is converted ([why, and the rewrite](https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2ui5/docs/refusals.md#dynpro))

## TODO

- no selection text in the text pool for P_VBELN - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_10_refused.prog.abap:30:3` - the statements after SUBMIT ... AND RETURN ran when the called report came back - here they run before it starts (submit( ) navigates when the method returns); move them to where they belong

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_10_refused` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 21 | `FIELD-SYMBOLS <gv_vbeln> TYPE any` | declared in each method that uses it |
| 23 | `PARAMETERS p_vbeln TYPE c LENGTH 10` | attribute `p_vbeln`, `screen->parameter( )` |
| 25 | `START-OF-SELECTION` | `start_of_selection( )` |
| 30 | `SUBMIT zr2c_01_hello AND RETURN` | `submit( report values )` - the class of the called report starts with the values, Back returns here |

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_10`.
