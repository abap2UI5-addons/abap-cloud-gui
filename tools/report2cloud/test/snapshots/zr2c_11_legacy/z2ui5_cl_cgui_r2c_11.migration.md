# report2cloud: ZR2C_11_LEGACY → z2ui5_cl_cgui_r2c_11

| | |
|---|---|
| Source | `zr2c_11_legacy.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_11.clas.abap`, `z2ui5_cl_cgui_r2c_11.clas.xml` |
| Mapped | 15 construct(s) |
| TODO | 4 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for S_RANGE, P_TITLE - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_11_legacy.prog.abap:21:3` - SET PF-STATUS 'LIST' dropped - the GUI status is in the .prog.xml (--texts), which was not passed; set_pf_status( functions = ... ) adds the functions to the toolbar of the output, each arrives in at_user_command( )
- `zr2c_11_legacy.prog.abap:28:3` - WRITE ... TO: converted to a string template - WRITE TO formats dates, times and numbers in the user's format; add DATE = USER / NUMBER = USER where it matters
- `zr2c_11_legacy.prog.abap:35:3` - WRITE ... TO: converted to a string template - WRITE TO formats dates, times and numbers in the user's format; add DATE = USER / NUMBER = USER where it matters

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_11_legacy` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 15 | `FIELD-SYMBOLS <gv_number> TYPE i` | declared in each method that uses it |
| 17 | `SELECT-OPTIONS s_range FOR gv_sum DEFAULT 1 TO 20` | range attribute `s_range`, `screen->select_option( )` |
| 18 | `PARAMETERS p_title TYPE c LENGTH 30 DEFAULT 'Numbers'` | attribute `p_title`, `screen->parameter( )` |
| 20 | `START-OF-SELECTION` | `start_of_selection( )` |
| 21 | `SET PF-STATUS 'LIST'` | dropped - SET PF-STATUS |
| 23 | `IF sy-index IN s_range` | `z2ui5_cl_cgui_context=>range_check( val range )` - IN outside ABAP SQL |
| 28 | `WRITE p_title TO gv_text` | string template |
| 29 | `WRITE / gv_text COLOR COL_HEADING` | `write( )`, color |
| 32 | `WRITE / <gv_number>` | `write( )` |
| 35 | `WRITE gv_sum TO gv_sum_txt LEFT-JUSTIFIED` | string template |
| 37 | `WRITE / gv_text` | `write( )` |
| 39 | `AT USER-COMMAND` | `at_user_command( ucomm )` - sy-ucomm becomes ucomm |
| 42 | `LEAVE LIST-PROCESSING` | `leave_to_selection_screen( )` |
| 44 | `MESSAGE 'Refreshed' TYPE 'S'` | `message( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_11` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_11` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_11_LEGACY` report = `Z2UI5_CL_CGUI_R2C_11` text = `ZR2C_11_LEGACY` semantic_object = `Z2UI5_CL_CGUI_R2C_11` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_11`.
4. Pin the behaviour with ABAP Unit tests before the next change.
