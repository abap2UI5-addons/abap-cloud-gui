# report2cloud: ZR2C_02_FLIGHTS → z2ui5_cl_cgui_r2c_02

| | |
|---|---|
| Source | `zr2c_02_flights.prog.abap` |
| Text pool | `zr2c_02_flights.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_02.clas.abap`, `z2ui5_cl_cgui_r2c_02.clas.xml` |
| Mapped | 38 construct(s) |
| TODO | 0 |
| Release state to check | 2 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | database table | `z2ui5_cl_cgui_r2c_02.clas.abap:10:23` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |
| `ZR2C` | message class | - | - |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- WRITE ... CURRENCY - the list writes the value in its default format

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_02_flights NO STANDARD PAGE HEADING LINE-SIZE 120 MESSA...` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 9 | `TABLES sflight` | dropped - it only typed the select-options and parameters, which now refer to the DDIC type |
| 25 | `SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001` | `screen->block_begin( )` |
| 26 | `PARAMETERS p_carrid LIKE sflight-carrid OBLIGATORY DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 27 | `SELECT-OPTIONS s_fldate FOR sflight-fldate` | range attribute `s_fldate`, `screen->select_option( )` |
| 28 | `PARAMETERS p_max TYPE i DEFAULT 100` | attribute `p_max`, `screen->parameter( )` |
| 29 | `SELECTION-SCREEN END OF BLOCK b1` | `screen->block_end( )` |
| 31 | `INITIALIZATION` | `initialization( )` |
| 36 | `APPEND s_fldate` | `APPEND ls_s_fldate TO s_fldate` - the header line is a work area |
| 38 | `AT SELECTION-SCREEN` | `at_selection_screen( )` |
| 40 | `MESSAGE e001 WITH p_max` | `MESSAGE ... INTO` + `message( )` |
| 43 | `TOP-OF-PAGE` | `top_of_page( )` - the header the runtime writes above the list and repeats on every page |
| 44 | `FORMAT COLOR COL_HEADING` | applied to the following `write( )` calls of the method (color, hotspot) |
| 45 | `WRITE / 'Airline'` | `write( )`, color |
| 45 | `WRITE 'No.'` | `write( )`, color |
| 45 | `WRITE 'Date'` | `write( )`, color |
| 45 | `WRITE 'Price'` | `write( )`, color |
| 45 | `WRITE 'Occupied'` | `write( )`, color |
| 46 | `FORMAT RESET` | applied to the following `write( )` calls of the method (color, hotspot) |
| 47 | `ULINE` | `list( )->uline( )` |
| 49 | `START-OF-SELECTION` | `start_of_selection( )` |
| 57 | `MESSAGE s002 WITH p_carrid` | `MESSAGE ... INTO` + `message( )` |
| 62 | `WRITE / gs_flight-carrid HOTSPOT` | `write( )`, hotspot |
| 63 | `WRITE gs_flight-connid` | `write( )` |
| 64 | `WRITE gs_flight-fldate` | `write( )` |
| 65 | `WRITE gs_flight-price CURRENCY gs_flight-currency` | `write( )` |
| 66 | `WRITE gs_flight-currency` | `write( )` |
| 68 | `WRITE gs_flight-seatsocc COLOR COL_NEGATIVE` | `write( )`, color |
| 70 | `WRITE gs_flight-seatsocc COLOR COL_POSITIVE` | `write( )`, color |
| 72 | `HIDE gs_flight-carrid` | `hide = gs_flight-carrid` at the hotspot of the line, restored in `at_line_selection( )` |
| 72 | `HIDE gs_flight-connid` | `hide = gs_flight-carrid gs_flight-connid` at the hotspot of the line, restored in `at_line_selection( )` |
| 72 | `HIDE gs_flight-fldate` | `hide = gs_flight-carrid gs_flight-connid gs_flight-fldate` at the hotspot of the line, restored in `at_line_selection( )` |
| 76 | `END-OF-SELECTION` | `end_of_selection( )` - the runtime runs it after `start_of_selection( )`, after its RETURN too |
| 77 | `SKIP` | `list( )->skip( )` |
| 78 | `WRITE / 'Seats occupied in total:'(002)` | `write( )` |
| 78 | `WRITE gv_total COLOR COL_TOTAL` | `write( )`, color |
| 80 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 86 | `MESSAGE i003 WITH gs_flight-carrid gs_flight-connid gs_flight-seatsocc` | `MESSAGE ... INTO` + `message( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_02` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_02` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_02_FLIGHTS` report = `Z2UI5_CL_CGUI_R2C_02` text = `ZR2C_02_FLIGHTS` semantic_object = `Z2UI5_CL_CGUI_R2C_02` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_02`.
4. Pin the behaviour with ABAP Unit tests before the next change.
