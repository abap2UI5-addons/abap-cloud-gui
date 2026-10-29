# report2cloud: ZR2C_15_SUBMIT → z2ui5_cl_cgui_r2c_15

| | |
|---|---|
| Source | `zr2c_15_submit.prog.abap` |
| Text pool | `zr2c_15_submit.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_15.clas.abap`, `z2ui5_cl_cgui_r2c_15.clas.xml` |
| Mapped | 21 construct(s) |
| TODO | 0 |
| Release state to check | 1 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | DDIC type | `z2ui5_cl_cgui_r2c_15.clas.abap:23:24` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- CALL SELECTION-SCREEN ... STARTING AT - the dialog is centred, the position is dropped
- SUBMIT ... WITH SELECTION-TABLE: selection_table_get( ) reads selname, kind, sign, option, low and high of the lines, as RSPARAMS has them

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_15_submit` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 23 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 24 | `SELECT-OPTIONS s_fldate FOR sy-datum` | range attribute `s_fldate`, `screen->select_option( )` |
| 25 | `PARAMETERS p_max TYPE i DEFAULT 20` | attribute `p_max`, `screen->parameter( )` |
| 27 | `SELECTION-SCREEN BEGIN OF SCREEN 100 AS WINDOW TITLE TEXT-T01` | `selection_screen_dynnr( dynnr screen )` - WHEN `0100` |
| 28 | `PARAMETERS p_seats TYPE i OBLIGATORY` | attribute `p_seats`, `screen->parameter( )` |
| 29 | `SELECTION-SCREEN END OF SCREEN 100` | `selection_screen_dynnr( )` |
| 31 | `START-OF-SELECTION` | `start_of_selection( )` |
| 32 | `WRITE / 'Flights of'` | `write( )` |
| 32 | `WRITE p_carrid` | `write( )` |
| 33 | `WRITE / 'Double-click for the flight list, F2 for the booking'` | `write( )` |
| 35 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 37 | `SUBMIT zr2c_02_flights WITH p_carrid = p_carrid WITH s_fldate IN s_...` | `submit( report values )` - the class of the called report starts with the values, Back returns here |
| 42 | `AT USER-COMMAND` | `at_user_command( ucomm )` - sy-ucomm becomes ucomm |
| 45 | `CALL SELECTION-SCREEN 100 STARTING AT 10 5` | `call_selection_screen( dynnr )` - the screen as a dialog; sy-subrc arrives in `after_call_selection_screen( dynnr subrc )` |
| 46 | `IF sy-subrc = 0` | `after_call_selection_screen( dynnr subrc )` - WHEN `0100`: the statements after CALL SELECTION-SCREEN, sy-subrc is subrc |
| 48 | `WRITE / 'Seats booked:'` | `write( )` |
| 48 | `WRITE gv_seats` | `write( )` |
| 50 | `WRITE / 'Booking cancelled'` | `write( )` |
| 55 | `SUBMIT zr2c_01_hello WITH SELECTION-TABLE gt_rspar VIA SELECTION-SC...` | `submit( report values )` - the class of the called report starts with the values, Back returns here |
| 60 | `SUBMIT zr2c_01_hello WITH p_name = 'Bye'` | `submit( report values )` and `RETURN` - the classic SUBMIT without AND RETURN ended this report |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_15` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_15` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_15_SUBMIT` report = `Z2UI5_CL_CGUI_R2C_15` text = `ZR2C_15_SUBMIT` semantic_object = `Z2UI5_CL_CGUI_R2C_15` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_15`.
4. Pin the behaviour with ABAP Unit tests before the next change.
