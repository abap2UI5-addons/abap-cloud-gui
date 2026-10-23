*&---------------------------------------------------------------------*
*& Report ZR2C_14_HEADERLINE
*&---------------------------------------------------------------------*
*& Tables with a header line, the way a report of 2003 keeps them: OCCURS,
*& WITH HEADER LINE, BEGIN OF ... OCCURS, the short forms of APPEND,
*& COLLECT, MODIFY, READ TABLE and LOOP, a TABLES parameter used with its
*& header line, and a FORM with a table of its own
*&---------------------------------------------------------------------*
REPORT zr2c_14_headerline.

TABLES sflight.

DATA: BEGIN OF gt_sum OCCURS 0,
        carrid TYPE sflight-carrid,
        count  TYPE i,
        seats  TYPE i,
      END OF gt_sum.

DATA gt_flight TYPE sflight OCCURS 0 WITH HEADER LINE.
TYPES ty_t_log TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA gt_log TYPE TABLE OF string WITH HEADER LINE.

PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.
SELECT-OPTIONS s_fldate FOR sflight-fldate.

START-OF-SELECTION.
  REFRESH: gt_flight, gt_sum.
  SELECT * FROM sflight INTO TABLE gt_flight
    WHERE carrid = p_carrid AND fldate IN s_fldate.

  LOOP AT gt_flight.
    CLEAR gt_sum.
    gt_sum-carrid = gt_flight-carrid.
    gt_sum-count = 1.
    gt_sum-seats = gt_flight-seatsmax - gt_flight-seatsocc.
    COLLECT gt_sum.
  ENDLOOP.

  PERFORM add_log TABLES gt_log USING 'Flights read'.
  PERFORM show_sum TABLES gt_sum.

  LOOP AT gt_log.
    WRITE: / gt_log.
  ENDLOOP.

FORM add_log TABLES tt_log TYPE ty_t_log USING iv_text TYPE string.
  tt_log = iv_text.
  APPEND tt_log.
ENDFORM.

FORM show_sum TABLES tt_sum STRUCTURE gt_sum.
  DATA lt_seen TYPE sflight-carrid OCCURS 0.

  SORT tt_sum BY carrid.
  LOOP AT tt_sum.
    READ TABLE lt_seen WITH KEY table_line = tt_sum-carrid.
    IF sy-subrc <> 0.
      lt_seen = tt_sum-carrid.
      APPEND lt_seen.
    ENDIF.
    WRITE: / tt_sum-carrid, tt_sum-count, tt_sum-seats.
  ENDLOOP.
  DATA(lv_n) = lines( lt_seen ).
  WRITE: / 'Airlines:', lv_n.
ENDFORM.
