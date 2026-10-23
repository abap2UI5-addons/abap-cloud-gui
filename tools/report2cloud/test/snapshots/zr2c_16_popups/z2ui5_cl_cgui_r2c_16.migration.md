# report2cloud: ZR2C_16_POPUPS → z2ui5_cl_cgui_r2c_16

| | |
|---|---|
| Source | `zr2c_16_popups.prog.abap` |
| Text pool | `zr2c_16_popups.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_16.clas.abap`, `z2ui5_cl_cgui_r2c_16.clas.xml` |
| Mapped | 31 construct(s) |
| TODO | 1 |
| Release state to check | 1 object(s) |

## TODO

- `zr2c_16_popups.prog.abap:92:3` - CALL FUNCTION 'POPUP_GET_VALUES' in FORM passenger: the statements after it run before it shows - its answer arrives in at_user_command( ) with ucomm POPUP_3 (popup_answer( ) is the answer); go on there

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | database table | `z2ui5_cl_cgui_r2c_16.clas.abap:19:40` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- POPUP_TO_CONFIRM with DISPLAY_CANCEL_BUTTON / CANCEL_DISPLAY - the popup of the runtime has a Cancel button either way (answer A)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_16_popups` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 19 | `global data - the report restarted after its list` | `CLEAR` of 5 global data object(s) at the start of `start_of_selection( )` |
| 24 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 26 | `START-OF-SELECTION` | `start_of_selection( )` |
| 31 | `WRITE / gs_flight-carrid` | `write( )` |
| 31 | `WRITE gs_flight-connid` | `write( )` |
| 31 | `WRITE gs_flight-fldate` | `write( )` |
| 31 | `WRITE gs_flight-seatsocc` | `write( )` |
| 32 | `HIDE gs_flight` | `hide = gs_flight` at the hotspot of the line, restored in `at_line_selection( )` |
| 35 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 37 | `CALL FUNCTION 'POPUP_TO_DECIDE' EXPORTING textline1 = 'Book the fli...` | `popup_to_decide( )` - the answer arrives in `at_user_command( )` with ucomm `POPUP_1`, where the statements after the call go on |
| 46 | `CASE lv_answer` | `at_user_command( )` - WHEN `POPUP_1`: the statements after CALL FUNCTION 'POPUP_TO_DECIDE' |
| 48 | `PERFORM book USING gs_flight` | `book( )` |
| 50 | `WRITE / 'On the waiting list:'` | `write( )` |
| 50 | `WRITE gs_flight-connid` | `write( )` |
| 52 | `WRITE / 'Nothing booked'` | `write( )` |
| 55 | `AT USER-COMMAND` | `at_user_command( ucomm )` - sy-ucomm becomes ucomm |
| 58 | `CALL FUNCTION 'POPUP_TO_CONFIRM' EXPORTING titlebar = 'Cancel booki...` | `popup_to_decide( )` - the answer arrives in `at_user_command( )` with ucomm `POPUP_2`, where the statements after the call go on |
| 70 | `IF sy-subrc <> 0` | dropped - the IF sy-subrc after POPUP_TO_CONFIRM checked its EXCEPTIONS, popup_to_decide( ) raises none |
| 70 | `IF sy-subrc <> 0` | `at_user_command( )` - WHEN `POPUP_2`: the statements after CALL FUNCTION 'POPUP_TO_CONFIRM' |
| 75 | `WRITE / 'All bookings cancelled'` | `write( )` |
| 78 | `PERFORM passenger` | `passenger( )` |
| 81 | `FORM book USING is_flight TYPE sflight` | private method `book( )` |
| 83 | `WRITE / 'Booked:'` | `write( )` |
| 83 | `WRITE is_flight-connid` | `write( )` |
| 83 | `WRITE 'Bookings of this run:'` | `write( )` |
| 83 | `WRITE gv_booked` | `write( )` |
| 86 | `FORM passenger` | private method `passenger( )` |
| 92 | `CALL FUNCTION 'POPUP_GET_VALUES' EXPORTING popup_title = 'Passenger...` | `popup_get_values_sval( )` - the answer arrives in `at_user_command( )` with ucomm `POPUP_3`, where the statements after the call go on |
| 102 | `WRITE / 'Passenger:'` | `write( )` |
| 102 | `WRITE lt_fields[ 1 ]-value` | `write( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_16`.
4. Pin the behaviour with ABAP Unit tests before the next change.
