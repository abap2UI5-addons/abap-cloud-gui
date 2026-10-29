# report2cloud: ZR2C_05_REUSE → z2ui5_cl_cgui_r2c_05

| | |
|---|---|
| Source | `zr2c_05_reuse.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_05.clas.abap`, `z2ui5_cl_cgui_r2c_05.clas.xml` |
| Mapped | 31 construct(s) |
| TODO | 5 |
| Release state to check | 1 object(s) |

## TODO

- no selection text in the text pool for P_CURR - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_05_reuse.prog.abap:11:1` - TABLES scarr is now a work area of type SCARR - on ABAP Cloud the table must be replaced by a released CDS view (see the release TODOs)
- `zr2c_05_reuse.prog.abap:33:3` - REUSE_ALV_GRID_DISPLAY: IS_LAYOUT has no counterpart in the alv( ) chain and is dropped
- `zr2c_05_reuse.prog.abap:33:3` - REUSE_ALV_GRID_DISPLAY: the IF sy-subrc after the call checked its EXCEPTIONS - alv( ) raises none, the check is dropped
- `zr2c_05_reuse.prog.abap:33:3` - REUSE_ALV_GRID_DISPLAY: the USER_COMMAND callback is the row click now - its FORM is converted into at_line_selection( )

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SCARR` | database table | `z2ui5_cl_cgui_r2c_05.clas.abap:8:21` | /DMO/CARRIER (ABAP Flight Reference Scenario) |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- ALV layout: zebra stripes and optimized column widths - the grid of the runtime lays itself out (2×)
- field catalog settings without a counterpart (output length, key, sums, column position) - the grid takes columns and widths from the table (2×)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_05_reuse` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 9 | `TYPE-POOLS slis` | dropped - type pools load by themselves |
| 11 | `TABLES scarr` | typed work area `DATA scarr TYPE scarr` |
| 15 | `DATA gt_fieldcat TYPE slis_t_fieldcat_alv` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 16 | `DATA gs_fieldcat TYPE slis_fieldcat_alv` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 17 | `DATA gs_layout TYPE slis_layout_alv` | dropped - the ALV object, field catalog or layout is the alv( ) chain now |
| 19 | `PARAMETERS p_curr TYPE scarr-currcode` | attribute `p_curr`, `screen->parameter( )` |
| 21 | `START-OF-SELECTION` | `start_of_selection( )` |
| 28 | `PERFORM build_fieldcat` | dropped - FORM build_fieldcat only set up the ALV |
| 30 | `gs_layout-zebra = 'X'` | dropped - ALV layout - the grid lays itself out |
| 31 | `gs_layout-colwidth_optimize = 'X'` | dropped - ALV layout - the grid lays itself out |
| 33 | `CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY' EXPORTING i_callback_program...` | `alv( gt_scarr )` |
| 49 | `FORM build_fieldcat` | dropped - the FORM only set up the ALV, which the alv( ) chain does now |
| 50 | `CLEAR gs_fieldcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 51 | `gs_fieldcat-fieldname = 'MANDT'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 52 | `gs_fieldcat-no_out = 'X'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 53 | `APPEND gs_fieldcat TO gt_fieldcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 55 | `CLEAR gs_fieldcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 56 | `gs_fieldcat-fieldname = 'CARRID'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 57 | `gs_fieldcat-seltext_m = 'Airline'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 58 | `gs_fieldcat-key = 'X'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 59 | `APPEND gs_fieldcat TO gt_fieldcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 61 | `CLEAR gs_fieldcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 62 | `gs_fieldcat-fieldname = 'CARRNAME'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 63 | `gs_fieldcat-seltext_m = 'Name'` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 64 | `gs_fieldcat-outputlen = 25` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 65 | `APPEND gs_fieldcat TO gt_fieldcat` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 67 | `APPEND VALUE #( fieldname = 'CURRCODE' seltext_m = 'Currency' ) TO ...` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 68 | `APPEND VALUE #( fieldname = 'URL' seltext_m = 'Website' ) TO gt_fie...` | dropped - field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain |
| 71 | `FORM user_command USING r_ucomm LIKE sy-ucomm rs_selfield TYPE slis...` | the ALV USER_COMMAND callback - its body is `at_line_selection( )`, rs_selfield-tabindex is row |
| 78 | `MESSAGE \|{ scarr-carrname }: { scarr-url }\| TYPE 'I'` | `message( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_05` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_05` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_05_REUSE` report = `Z2UI5_CL_CGUI_R2C_05` text = `ZR2C_05_REUSE` semantic_object = `Z2UI5_CL_CGUI_R2C_05` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_05`.
4. Pin the behaviour with ABAP Unit tests before the next change.
