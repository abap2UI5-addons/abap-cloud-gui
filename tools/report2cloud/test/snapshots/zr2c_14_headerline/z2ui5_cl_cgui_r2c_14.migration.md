# report2cloud: ZR2C_14_HEADERLINE → z2ui5_cl_cgui_r2c_14

| | |
|---|---|
| Source | `zr2c_14_headerline.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_14.clas.abap`, `z2ui5_cl_cgui_r2c_14.clas.xml` |
| Mapped | 29 construct(s) |
| TODO | 2 |
| Release state to check | 1 object(s) |

## TODO

- no selection text in the text pool for P_CARRID, S_FLDATE - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_14_headerline.prog.abap:11:1` - TABLES sflight is now a work area of type SFLIGHT - on ABAP Cloud the table must be replaced by a released CDS view (see the release TODOs)

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | database table | `z2ui5_cl_cgui_r2c_14.clas.abap:11:23` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_14_headerline` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 11 | `TABLES sflight` | typed work area `DATA sflight TYPE sflight` |
| 13 | `DATA BEGIN OF gt_sum OCCURS 0` | `BEGIN OF wa_gt_sum` - the structure is the work area; the table `gt_sum` is declared LIKE a table of it |
| 19 | `DATA gt_flight TYPE sflight OCCURS 0 WITH HEADER LINE` | `DATA gt_flight ... STANDARD TABLE OF` and the work area `wa_gt_flight` - the header line is a work area |
| 21 | `DATA gt_log TYPE TABLE OF string WITH HEADER LINE` | `DATA gt_log ... STANDARD TABLE OF` and the work area `wa_gt_log` - the header line is a work area |
| 23 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 24 | `SELECT-OPTIONS s_fldate FOR sflight-fldate` | range attribute `s_fldate`, `screen->select_option( )` |
| 26 | `START-OF-SELECTION` | `start_of_selection( )` |
| 31 | `LOOP AT gt_flight` | `INTO wa_gt_flight` - the header line is a work area |
| 32 | `CLEAR gt_sum` | `CLEAR wa_gt_sum` - the header line is a work area |
| 36 | `COLLECT gt_sum` | `COLLECT wa_gt_sum INTO gt_sum` - the header line is a work area |
| 39 | `PERFORM add_log TABLES gt_log USING 'Flights read'` | `add_log( )` |
| 40 | `PERFORM show_sum TABLES gt_sum` | `show_sum( )` |
| 42 | `LOOP AT gt_log` | `INTO wa_gt_log` - the header line is a work area |
| 43 | `WRITE / gt_log` | `write( )` |
| 46 | `FORM add_log TABLES tt_log TYPE ty_t_log USING iv_text TYPE string` | the TABLES parameter tt_log is used with its header line - a work area ls_tt_log of the method |
| 46 | `FORM add_log TABLES tt_log TYPE ty_t_log USING iv_text TYPE string` | private method `add_log( )` |
| 48 | `APPEND tt_log` | `APPEND ls_tt_log TO tt_log` - the header line is a work area |
| 51 | `FORM show_sum TABLES tt_sum STRUCTURE gt_sum` | the TABLES parameter tt_sum is used with its header line - a work area ls_tt_sum of the method |
| 51 | `FORM show_sum TABLES tt_sum STRUCTURE gt_sum` | private method `show_sum( )` |
| 52 | `DATA lt_seen TYPE sflight-carrid OCCURS 0` | `DATA lt_seen ... STANDARD TABLE OF` and the work area `ls_lt_seen` - the header line is a work area |
| 55 | `LOOP AT tt_sum` | `INTO ls_tt_sum` - the header line is a work area |
| 56 | `READ TABLE lt_seen WITH KEY table_line = tt_sum-carrid` | `INTO ls_lt_seen` - the header line is a work area |
| 59 | `APPEND lt_seen` | `APPEND ls_lt_seen TO lt_seen` - the header line is a work area |
| 61 | `WRITE / tt_sum-carrid` | `write( )` |
| 61 | `WRITE tt_sum-count` | `write( )` |
| 61 | `WRITE tt_sum-seats` | `write( )` |
| 64 | `WRITE / 'Airlines:'` | `write( )` |
| 64 | `WRITE lv_n` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_14` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_14` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_14_HEADERLINE` report = `Z2UI5_CL_CGUI_R2C_14` text = `ZR2C_14_HEADERLINE` semantic_object = `Z2UI5_CL_CGUI_R2C_14` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_14`.
4. Pin the behaviour with ABAP Unit tests before the next change.
