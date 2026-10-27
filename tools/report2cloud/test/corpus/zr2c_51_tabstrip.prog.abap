*&---------------------------------------------------------------------*
*& Report ZR2C_51_TABSTRIP
*&---------------------------------------------------------------------*
*& A tabstrip on screen 0100: two tabs on one subscreen area, the
*& subscreen of the tab pressed called into it - the paging in the
*& program, as most tabstrips are written. The PAI of the subscreen runs
*& with the one of its screen.
*&---------------------------------------------------------------------*
REPORT zr2c_51_tabstrip.

CONTROLS tabstr TYPE TABSTRIP.
DATA gv_dynnr TYPE sy-dynnr.
DATA gv_carrid TYPE c LENGTH 3 VALUE 'LH'.
DATA gv_free TYPE c LENGTH 1.
DATA ok_code TYPE sy-ucomm.

START-OF-SELECTION.
  CALL SCREEN 100.
  WRITE: / 'Airline', gv_carrid.
  IF gv_free = abap_true.
    WRITE / 'Only free seats'.
  ENDIF.

MODULE status_0100 OUTPUT.
  IF tabstr-activetab IS INITIAL.
    tabstr-activetab = 'TAB1'.
    gv_dynnr = '0110'.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'TAB1'.
      tabstr-activetab = ok_code.
      gv_dynnr = '0110'.
    WHEN 'TAB2'.
      tabstr-activetab = ok_code.
      gv_dynnr = '0120'.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

MODULE check_0110 INPUT.
  TRANSLATE gv_carrid TO UPPER CASE.
ENDMODULE.
