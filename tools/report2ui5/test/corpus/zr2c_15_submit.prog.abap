*&---------------------------------------------------------------------*
*& Report ZR2C_15_SUBMIT
*&---------------------------------------------------------------------*
*& Reports call reports: SUBMIT ... WITH ... AND RETURN of another report
*& of the corpus, a selection screen of its own called as a dialog
*& (CALL SELECTION-SCREEN, sy-subrc), a SUBMIT with a variant and one
*& without AND RETURN
*&---------------------------------------------------------------------*
REPORT zr2c_15_submit.

TYPES: BEGIN OF ty_rspar,
         selname TYPE c LENGTH 8,
         kind    TYPE c LENGTH 1,
         sign    TYPE c LENGTH 1,
         option  TYPE c LENGTH 2,
         low     TYPE c LENGTH 45,
         high    TYPE c LENGTH 45,
       END OF ty_rspar.

DATA gv_seats TYPE i.
DATA gt_rspar TYPE STANDARD TABLE OF ty_rspar WITH DEFAULT KEY.

PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.
SELECT-OPTIONS s_fldate FOR sy-datum.
PARAMETERS p_max TYPE i DEFAULT 20.

SELECTION-SCREEN BEGIN OF SCREEN 100 AS WINDOW TITLE TEXT-T01.
PARAMETERS p_seats TYPE i OBLIGATORY.
SELECTION-SCREEN END OF SCREEN 100.

START-OF-SELECTION.
  WRITE: / 'Flights of', p_carrid.
  WRITE: / 'Double-click for the flight list, F2 for the booking'.

AT LINE-SELECTION.
  " the flight list of another report of the corpus, with our values
  SUBMIT zr2c_02_flights WITH p_carrid = p_carrid
                         WITH s_fldate IN s_fldate
                         WITH p_max NE p_max SIGN 'E'
                         AND RETURN.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'BOOK'.
      CALL SELECTION-SCREEN 100 STARTING AT 10 5.
      IF sy-subrc = 0.
        gv_seats = p_seats.
        WRITE: / 'Seats booked:', gv_seats.
      ELSE.
        WRITE: / 'Booking cancelled'.
      ENDIF.
    WHEN 'HELLO'.
      " the values as a selection table, the called report's own screen first
      gt_rspar = VALUE #( ( selname = 'P_NAME' kind = 'P' sign = 'I' option = 'EQ' low = 'World' ) ).
      SUBMIT zr2c_01_hello WITH SELECTION-TABLE gt_rspar
                           VIA SELECTION-SCREEN
                           USING SELECTION-SET 'DEFAULT'
                           AND RETURN.
    WHEN 'LEAVE'.
      SUBMIT zr2c_01_hello WITH p_name = 'Bye'.
  ENDCASE.
