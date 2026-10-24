*&---------------------------------------------------------------------*
*& Report ZR2C_23_DYNPRO
*&---------------------------------------------------------------------*
*& A dynpro of fields: the selection screen asks for the airline,
*& START-OF-SELECTION calls screen 0100 - a frame with the airline as an
*& output field, the connection and the seats as inputs, a checkbox,
*& two radio buttons and a push button. PBO sets the status and keeps
*& the seats closed until the connection is checked, PAI answers the
*& push button, Save and Back; Save goes on to screen 0200, which
*& confirms. What follows CALL SCREEN writes the list.
*&---------------------------------------------------------------------*
REPORT zr2c_23_dynpro.

PARAMETERS p_carrid TYPE c LENGTH 3 DEFAULT 'LH' OBLIGATORY.

DATA ok_code   TYPE sy-ucomm.
DATA gv_connid TYPE n LENGTH 4.
DATA gv_seats  TYPE i.
DATA gv_window TYPE c LENGTH 1.
DATA gv_eco    TYPE c LENGTH 1 VALUE 'X'.
DATA gv_bus    TYPE c LENGTH 1.
DATA gv_check  TYPE c LENGTH 1.
DATA gv_booked TYPE c LENGTH 1.

START-OF-SELECTION.
  CLEAR: gv_connid, gv_seats, gv_check, gv_booked.
  CALL SCREEN 100.
  IF gv_booked = 'X'.
    WRITE: / 'Booked:', gv_seats, 'seat(s) on', p_carrid, gv_connid.
  ELSE.
    WRITE / 'Nothing booked'.
  ENDIF.

*&---------------------------------------------------------------------*
*& The status of screen 0100 - the seats wait for the check
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100' WITH p_carrid.
  LOOP AT SCREEN.
    IF screen-group1 = 'SEA'.
      IF gv_check = 'X'.
        screen-input = '1'.
      ELSE.
        screen-input = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.

MODULE exit_0100 INPUT.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE check_connid INPUT.
  IF gv_connid > '9000'.
    MESSAGE 'No such connection' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'CHECK'.
      gv_check = 'X'.
      MESSAGE 'The connection has seats' TYPE 'S'.
    WHEN 'SAVE'.
      IF gv_check IS INITIAL OR gv_seats <= 0.
        MESSAGE 'Check the connection and enter the seats' TYPE 'E'.
      ENDIF.
      SET SCREEN 200.
  ENDCASE.
  CLEAR ok_code.
ENDMODULE.

MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN 'BOOK'.
      gv_booked = 'X'.
      LEAVE TO SCREEN 0.
    WHEN 'BACK'.
      LEAVE TO SCREEN 100.
  ENDCASE.
ENDMODULE.
