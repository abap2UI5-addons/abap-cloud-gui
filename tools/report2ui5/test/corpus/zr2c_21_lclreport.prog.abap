*&---------------------------------------------------------------------*
*& Report ZR2C_21_LCLREPORT
*&---------------------------------------------------------------------*
*& A report written the modern way: the selection screen and the event
*& blocks in the report, the logic in a local class lcl_report that reads
*& the selection screen, writes the list, calls a FORM and keeps its data
*& in attributes; the instance created inline in INITIALIZATION
*&---------------------------------------------------------------------*
REPORT zr2c_21_lclreport.

TABLES scarr.

TYPES: BEGIN OF ty_s_flight,
         carrid   TYPE sflight-carrid,
         connid   TYPE sflight-connid,
         seatsocc TYPE sflight-seatsocc,
       END OF ty_s_flight,
       ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.

CONSTANTS gc_max TYPE i VALUE 3.

DATA gv_total TYPE i.

PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.
SELECT-OPTIONS s_connid FOR scarr-carrid NO-DISPLAY.

CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    METHODS constructor IMPORTING iv_title TYPE string.
    METHODS run.
  PRIVATE SECTION.
    DATA mv_title TYPE string.
    DATA mt_flight TYPE ty_t_flight.
    METHODS read.
    METHODS show.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD constructor.
    mv_title = iv_title.
  ENDMETHOD.

  METHOD run.
    read( ).
    IF mt_flight IS INITIAL.
      MESSAGE 'No flights' TYPE 'S'.
      RETURN.
    ENDIF.
    show( ).
    PERFORM total.
  ENDMETHOD.

  METHOD read.
    SELECT carrid, connid, seatsocc FROM sflight
      INTO TABLE @mt_flight
      WHERE carrid = @p_carrid
      ORDER BY carrid, connid, fldate.
  ENDMETHOD.

  METHOD show.
    WRITE: / mv_title COLOR COL_HEADING.
    LOOP AT mt_flight INTO DATA(ls_flight).
      IF sy-tabix > gc_max.
        EXIT.
      ENDIF.
      WRITE: / ls_flight-connid, ls_flight-seatsocc.
      gv_total = gv_total + ls_flight-seatsocc.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

INITIALIZATION.
  DATA(go_report) = NEW lcl_report( |Flights| ).

START-OF-SELECTION.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      text = 'Reading the flights'.
  SELECT SINGLE * FROM scarr WHERE carrid = p_carrid.
  IF sy-subrc <> 0.
    MESSAGE 'Unknown airline' TYPE 'S'.
    LEAVE PROGRAM.
  ENDIF.
  WRITE: / 'Airline:', scarr-carrname.
  go_report->run( ).

AT SELECTION-SCREEN OUTPUT.
  SET CURSOR FIELD 'P_CARRID'.

FORM total.
  WRITE: / 'Seats occupied in the first', gc_max, 'flights:', gv_total.
ENDFORM.
