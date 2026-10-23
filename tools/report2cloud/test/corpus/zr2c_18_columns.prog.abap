*&---------------------------------------------------------------------*
*& Report ZR2C_18_COLUMNS
*&---------------------------------------------------------------------*
*& An evaluation that lives by the column: WRITE AT pos(len), UNDER,
*& NO-GAP, POSITION, RESERVE, sy-colno / sy-linno, and a drilldown over
*& three list levels - WINDOW, sy-lsind read and set
*&---------------------------------------------------------------------*
REPORT zr2c_18_columns LINE-COUNT 30 NO STANDARD PAGE HEADING.

DATA: gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight TYPE sflight,
      gv_total  TYPE i,
      gv_col    TYPE i VALUE 40.

PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.

START-OF-SELECTION.
  SELECT * FROM sflight INTO TABLE gt_flight
    WHERE carrid = p_carrid
    ORDER BY PRIMARY KEY.

  WRITE: /1 'Flight', 10 'Date', 25 'Occupied', AT gv_col 'Free'.
  ULINE.
  LOOP AT gt_flight INTO gs_flight.
    RESERVE 2 LINES.
    WRITE: / gs_flight-connid UNDER 'Flight',
             gs_flight-fldate UNDER 'Date',
             AT 25(8) gs_flight-seatsocc,
             AT gv_col(6) gs_flight-seatsmax NO-GAP, '-'.
    HIDE gs_flight.
    gv_total = gv_total + gs_flight-seatsocc.
  ENDLOOP.
  ULINE.
  POSITION 25.
  WRITE gv_total.
  WRITE: / 'The list ends at line', sy-linno.

AT LINE-SELECTION.
  " the third level replaces the second: Back returns to the flight list
  IF sy-lsind > 2.
    sy-lsind = 2.
  ENDIF.
  IF sy-lsind = 1.
    WINDOW STARTING AT 10 5 ENDING AT 70 15.
  ENDIF.
  WRITE: / 'Level', sy-lsind, 'flight', gs_flight-connid.
  WRITE: /5 'Occupied:', AT 20(8) gs_flight-seatsocc.
  WRITE: /5 'Column after the value:', sy-colno.
  HIDE gs_flight.
