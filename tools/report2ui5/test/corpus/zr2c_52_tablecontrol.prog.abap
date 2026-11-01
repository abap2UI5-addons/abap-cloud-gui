*&---------------------------------------------------------------------*
*& Report ZR2C_52_TABLECONTROL
*&---------------------------------------------------------------------*
*& A table control on screen 0100: the connections of an airline, the
*& seats ready for input. The PBO loop fills a line at a time from the
*& internal table, the PAI loop writes back what the user typed; the list
*& after the screen shows the table as it is then.
*&---------------------------------------------------------------------*
REPORT zr2c_52_tablecontrol.

TYPES: BEGIN OF ty_seat,
         connid TYPE n LENGTH 4,
         seats  TYPE i,
       END OF ty_seat.

CONTROLS tc_seats TYPE TABLEVIEW USING SCREEN 100.
DATA gt_seat TYPE STANDARD TABLE OF ty_seat WITH DEFAULT KEY.
DATA gs_seat TYPE ty_seat.
DATA ok_code TYPE sy-ucomm.

START-OF-SELECTION.
  gt_seat = VALUE #( ( connid = '0400' seats = 10 )
                     ( connid = '0402' seats = 20 )
                     ( connid = '2402' seats = 30 ) ).
  CALL SCREEN 100.
  LOOP AT gt_seat INTO gs_seat.
    WRITE: / gs_seat-connid, gs_seat-seats.
  ENDLOOP.

MODULE status_0100 OUTPUT.
  tc_seats-lines = lines( gt_seat ).
ENDMODULE.

MODULE fill_0100 OUTPUT.
  READ TABLE gt_seat INTO gs_seat INDEX tc_seats-current_line.
ENDMODULE.

MODULE read_0100 INPUT.
  MODIFY gt_seat FROM gs_seat INDEX tc_seats-current_line.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
