*&---------------------------------------------------------------------*
*& Report ZR2C_17_STATUS
*&---------------------------------------------------------------------*
*& The GUI status and the title of a list: SET PF-STATUS with the buttons
*& and function keys of its status (read from the .prog.xml), EXCLUDING,
*& SET TITLEBAR WITH, AT USER-COMMAND on the functions
*&---------------------------------------------------------------------*
REPORT zr2c_17_status.

DATA: gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight TYPE sflight,
      gt_excl   TYPE STANDARD TABLE OF sy-ucomm WITH DEFAULT KEY.

PARAMETERS: p_carrid TYPE sflight-carrid DEFAULT 'LH',
            p_edit   AS CHECKBOX.

START-OF-SELECTION.
  " without the right to change, the list has no Delete
  IF p_edit IS INITIAL.
    APPEND 'DELE' TO gt_excl.
  ENDIF.
  SET PF-STATUS 'LIST' EXCLUDING gt_excl.
  SET TITLEBAR 'T01' WITH p_carrid.
  PERFORM show.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'REFRESH'.
      PERFORM show.
    WHEN 'DELE'.
      DELETE gt_flight WHERE seatsocc = 0.
      SET PF-STATUS 'LIST' EXCLUDING 'DELE'.
      WRITE: / 'Flights without bookings deleted'.
  ENDCASE.

FORM show.
  SELECT * FROM sflight INTO TABLE gt_flight
    WHERE carrid = p_carrid
    ORDER BY PRIMARY KEY.
  LOOP AT gt_flight INTO gs_flight.
    WRITE: / gs_flight-connid, gs_flight-fldate, gs_flight-seatsocc.
  ENDLOOP.
ENDFORM.
