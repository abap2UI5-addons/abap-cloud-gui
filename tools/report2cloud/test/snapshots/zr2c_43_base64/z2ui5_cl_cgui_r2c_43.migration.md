# report2cloud: ZR2C_43_BASE64 → z2ui5_cl_cgui_r2c_43

| | |
|---|---|
| Source | `zr2c_43_base64.prog.abap` |
| Text pool | `zr2c_43_base64.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_43.clas.abap`, `z2ui5_cl_cgui_r2c_43.clas.xml` |
| Mapped | 10 construct(s) |
| TODO | 0 |
| Release state to check | 0 object(s) |

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- SCMS_*_TO_* and SSFC_BASE64_* are methods of z2ui5_cl_cgui_frontend - bytes, lines of bytes, text and base64 converted in plain ABAP, the function modules are not released for ABAP Cloud (4×)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_43_base64` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 14 | `PARAMETERS p_text TYPE string LOWER CASE DEFAULT 'See you at noon'` | attribute `p_text`, `screen->parameter( )` |
| 16 | `START-OF-SELECTION` | `start_of_selection( )` |
| 23 | `CALL FUNCTION 'SCMS_STRING_TO_XSTRING' EXPORTING text = p_text IMPO...` | `z2ui5_cl_cgui_frontend=>scms_string_to_xstring( )` - the function module as the method of the frontend services, its EXCEPTIONS kept |
| 32 | `MESSAGE 'The text has no bytes' TYPE 'E'` | `message( )` |
| 35 | `CALL FUNCTION 'SCMS_XSTRING_TO_BINARY' EXPORTING buffer = lv_bytes ...` | `z2ui5_cl_cgui_frontend=>scms_xstring_to_binary( )` - the function module as the method of the frontend services, its EXCEPTIONS kept |
| 43 | `CALL FUNCTION 'SCMS_BINARY_TO_XSTRING' EXPORTING input_length = lv_...` | `z2ui5_cl_cgui_frontend=>scms_binary_to_xstring( )` - the function module as the method of the frontend services, its EXCEPTIONS kept |
| 54 | `CALL FUNCTION 'SSFC_BASE64_ENCODE' EXPORTING bindata = lv_back IMPO...` | `z2ui5_cl_cgui_frontend=>ssfc_base64_encode( )` - the function module as the method of the frontend services, its EXCEPTIONS kept |
| 66 | `WRITE / \|{ lv_length } bytes in { lines( lt_bin ) } lines\|` | `write( )` |
| 68 | `WRITE / 'The bytes came back unchanged'` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_43`.
4. Pin the behaviour with ABAP Unit tests before the next change.
