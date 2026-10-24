# report2cloud: ZR2C_21_LCLREPORT → z2ui5_cl_cgui_r2c_21

| | |
|---|---|
| Source | `zr2c_21_lclreport.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_21.clas.abap`, `z2ui5_cl_cgui_r2c_21.clas.locals_def.abap`, `z2ui5_cl_cgui_r2c_21.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_21.clas.xml` |
| Mapped | 28 construct(s) |
| TODO | 2 |
| Release state to check | 2 object(s) |

## TODO

- no selection text in the text pool for P_CARRID, S_CONNID - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_21_lclreport.prog.abap:11:1` - TABLES scarr is now a work area of type SCARR - on ABAP Cloud the table must be replaced by a released CDS view (see the release TODOs)

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SCARR` | database table | `z2ui5_cl_cgui_r2c_21.clas.abap:11:24` | /DMO/CARRIER (ABAP Flight Reference Scenario) |
| `SFLIGHT` | database table | `z2ui5_cl_cgui_r2c_21.clas.locals_imp.abap:15:24` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- SAPGUI_PROGRESS_INDICATOR / cl_progress_indicator - dropped, the browser shows a busy indicator while the server works
- a local class whose instance the report keeps implements if_serializable_object - the app is serialized between two roundtrips, its attributes with it
- local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_21_lclreport` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 11 | `TABLES scarr` | typed work area `DATA scarr TYPE scarr` |
| 11 | `global data - the report restarted after its list` | `CLEAR` of 2 global data object(s) at the start of `start_of_selection( )` |
| 24 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 25 | `SELECT-OPTIONS s_connid FOR scarr-carrid NO-DISPLAY` | range attribute `s_connid`, `screen->select_option( )` |
| 27 | `CLASS lcl_report DEFINITION` | locals_def |
| 38 | `CLASS lcl_report IMPLEMENTATION` | locals_imp |
| 46 | `MESSAGE 'No flights' TYPE 'S'` | `message( )` |
| 50 | `PERFORM total` | `total( )` |
| 61 | `WRITE / mv_title COLOR COL_HEADING` | `write( )`, color |
| 66 | `WRITE / ls_flight-connid` | `write( )` |
| 66 | `WRITE ls_flight-seatsocc` | `write( )` |
| 72 | `INITIALIZATION` | `initialization( )` |
| 73 | `DATA(go_report) = NEW lcl_report( \|Flights\| )` | the inline declaration of go_report - an attribute of the class (event blocks open no scope), assigned here |
| 75 | `START-OF-SELECTION` | `start_of_selection( )` |
| 76 | `CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR' EXPORTING text = 'Reading...` | dropped - the progress indicator of SAP GUI |
| 79 | `SELECT SINGLE * FROM scarr WHERE carrid = p_carrid` | `SELECT ... INTO @scarr` - the short form read into the TABLES work area, an attribute of the class now |
| 81 | `MESSAGE 'Unknown airline' TYPE 'S'` | `message( )` |
| 82 | `LEAVE PROGRAM` | `leave_to_selection_screen( )` and `RETURN` - the user is back on the selection screen |
| 84 | `WRITE / 'Airline:'` | `write( )` |
| 84 | `WRITE scarr-carrname` | `write( )` |
| 87 | `AT SELECTION-SCREEN OUTPUT` | `at_selection_screen_output( screen )` |
| 88 | `SET CURSOR FIELD 'P_CARRID'` | `set_cursor_field( )` - the selection screen opens with the cursor in that field |
| 90 | `FORM total` | private method `total( )` |
| 91 | `WRITE / 'Seats occupied in the first'` | `write( )` |
| 91 | `WRITE gc_max` | `write( )` |
| 91 | `WRITE 'flights:'` | `write( )` |
| 91 | `WRITE gv_total` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_21`.
4. Pin the behaviour with ABAP Unit tests before the next change.
