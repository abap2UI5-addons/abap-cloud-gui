*&---------------------------------------------------------------------*
*& Report ZR2C_02_FLIGHTS
*&---------------------------------------------------------------------*
*& Flights of an airline as a classic list: header, colors, hotspots
*& with HIDE and a drilldown on AT LINE-SELECTION
*&---------------------------------------------------------------------*
REPORT zr2c_02_flights NO STANDARD PAGE HEADING LINE-SIZE 120 MESSAGE-ID zr2c.

TABLES sflight.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE sflight-carrid,
         connid   TYPE sflight-connid,
         fldate   TYPE sflight-fldate,
         price    TYPE sflight-price,
         currency TYPE sflight-currency,
         seatsmax TYPE sflight-seatsmax,
         seatsocc TYPE sflight-seatsocc,
       END OF ty_flight.

DATA: gt_flight TYPE STANDARD TABLE OF ty_flight,
      gs_flight TYPE ty_flight,
      gv_total  TYPE i.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_carrid LIKE sflight-carrid OBLIGATORY DEFAULT 'LH'.
SELECT-OPTIONS: s_fldate FOR sflight-fldate.
PARAMETERS: p_max TYPE i DEFAULT 100.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  s_fldate-sign   = 'I'.
  s_fldate-option = 'BT'.
  s_fldate-low    = sy-datum.
  s_fldate-high   = sy-datum + 90.
  APPEND s_fldate.

AT SELECTION-SCREEN.
  IF p_max > 1000.
    MESSAGE e001 WITH p_max.
  ENDIF.

TOP-OF-PAGE.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Airline', 'No.', 'Date', 'Price', 'Occupied'.
  FORMAT RESET.
  ULINE.

START-OF-SELECTION.
  SELECT carrid connid fldate price currency seatsmax seatsocc
    FROM sflight
    INTO TABLE gt_flight
    UP TO p_max ROWS
    WHERE carrid = p_carrid
      AND fldate IN s_fldate.
  IF sy-subrc <> 0.
    MESSAGE s002 WITH p_carrid.
    RETURN.
  ENDIF.

  LOOP AT gt_flight INTO gs_flight.
    WRITE: / gs_flight-carrid HOTSPOT,
             gs_flight-connid,
             gs_flight-fldate,
             gs_flight-price CURRENCY gs_flight-currency,
             gs_flight-currency.
    IF gs_flight-seatsocc >= gs_flight-seatsmax.
      WRITE gs_flight-seatsocc COLOR COL_NEGATIVE.
    ELSE.
      WRITE gs_flight-seatsocc COLOR COL_POSITIVE.
    ENDIF.
    HIDE: gs_flight-carrid, gs_flight-connid, gs_flight-fldate.
    gv_total = gv_total + gs_flight-seatsocc.
  ENDLOOP.

END-OF-SELECTION.
  SKIP.
  WRITE: / 'Seats occupied in total:'(002), gv_total COLOR COL_TOTAL.

AT LINE-SELECTION.
  READ TABLE gt_flight INTO gs_flight
    WITH KEY carrid = gs_flight-carrid
             connid = gs_flight-connid
             fldate = gs_flight-fldate.
  IF sy-subrc = 0.
    MESSAGE i003 WITH gs_flight-carrid gs_flight-connid gs_flight-seatsocc.
  ENDIF.
