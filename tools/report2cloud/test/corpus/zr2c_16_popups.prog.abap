*&---------------------------------------------------------------------*
*& Report ZR2C_16_POPUPS
*&---------------------------------------------------------------------*
*& The synchronous popups of a report that posts something: a question
*& before the posting (POPUP_TO_CONFIRM), a choice (POPUP_TO_DECIDE),
*& a small input dialog (POPUP_GET_VALUES) - the event block goes on in
*& at_user_command( ) once the popup is answered
*&---------------------------------------------------------------------*
REPORT zr2c_16_popups.

TYPES: BEGIN OF ty_sval,
         tabname    TYPE c LENGTH 30,
         fieldname  TYPE c LENGTH 30,
         value      TYPE c LENGTH 132,
         fieldtext  TYPE c LENGTH 60,
         field_obl  TYPE c LENGTH 1,
       END OF ty_sval.

DATA: gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight TYPE sflight,
      gv_answer TYPE c LENGTH 1,
      gv_booked TYPE i.

PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.

START-OF-SELECTION.
  SELECT * FROM sflight INTO TABLE gt_flight
    WHERE carrid = p_carrid
    ORDER BY PRIMARY KEY.
  LOOP AT gt_flight INTO gs_flight.
    WRITE: / gs_flight-carrid, gs_flight-connid, gs_flight-fldate, gs_flight-seatsocc.
    HIDE gs_flight.
  ENDLOOP.

AT LINE-SELECTION.
  DATA lv_answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_DECIDE'
    EXPORTING
      textline1    = 'Book the flight'
      textline2    = gs_flight-connid
      text_option1 = 'Book now'
      text_option2 = 'Waiting list'
      titel        = 'Booking'
    IMPORTING
      answer       = lv_answer.
  CASE lv_answer.
    WHEN '1'.
      PERFORM book USING gs_flight.
    WHEN '2'.
      WRITE: / 'On the waiting list:', gs_flight-connid.
    WHEN OTHERS.
      WRITE: / 'Nothing booked'.
  ENDCASE.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Cancel bookings'
          text_question         = 'Cancel all bookings of this run?'
          text_button_1         = 'Cancel them'
          text_button_2         = 'Keep them'
          display_cancel_button = ' '
        IMPORTING
          answer                = gv_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE 'The question could not be shown' TYPE 'E'.
      ENDIF.
      IF gv_answer = '1'.
        gv_booked = 0.
        WRITE: / 'All bookings cancelled'.
      ENDIF.
    WHEN 'PASSENGER'.
      PERFORM passenger.
  ENDCASE.

FORM book USING is_flight TYPE sflight.
  gv_booked = gv_booked + 1.
  WRITE: / 'Booked:', is_flight-connid, 'Bookings of this run:', gv_booked.
ENDFORM.

FORM passenger.
  DATA lt_fields TYPE STANDARD TABLE OF ty_sval WITH DEFAULT KEY.
  DATA lv_rc TYPE c LENGTH 1.
  APPEND VALUE #( tabname = 'SCUSTOM' fieldname = 'NAME' fieldtext = 'Passenger' field_obl = 'X' ) TO lt_fields.
  APPEND VALUE #( tabname = 'SCUSTOM' fieldname = 'CITY' fieldtext = 'City' ) TO lt_fields.
  " in a FORM the block is not cut: a TODO says where to go on
  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title = 'Passenger'
    IMPORTING
      returncode  = lv_rc
    TABLES
      fields      = lt_fields.
  IF lv_rc = 'A'.
    RETURN.
  ENDIF.
  WRITE: / 'Passenger:', lt_fields[ 1 ]-value.
ENDFORM.
