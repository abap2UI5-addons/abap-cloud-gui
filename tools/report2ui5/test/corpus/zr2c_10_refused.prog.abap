*&---------------------------------------------------------------------*
*& Report ZR2C_10_REFUSED
*&---------------------------------------------------------------------*
*& What report2UI5 refuses: a dynpro, batch input, SUBMIT, native SQL
*& and field symbols on another program's fields
*&---------------------------------------------------------------------*
REPORT zr2c_10_refused.

TYPES: BEGIN OF ty_bdc,
         program  TYPE c LENGTH 40,
         dynpro   TYPE n LENGTH 4,
         dynbegin TYPE c LENGTH 1,
         fnam     TYPE c LENGTH 132,
         fval     TYPE c LENGTH 132,
       END OF ty_bdc.

DATA: gt_bdc   TYPE STANDARD TABLE OF ty_bdc,
      gv_okcode TYPE c LENGTH 20,
      gv_count TYPE i.

FIELD-SYMBOLS <gv_vbeln> TYPE any.

PARAMETERS p_vbeln TYPE c LENGTH 10.

START-OF-SELECTION.
  ASSIGN ('(SAPMV45A)VBAK-VBELN') TO <gv_vbeln>.

  CALL TRANSACTION 'VA02' USING gt_bdc MODE 'N'.

  SUBMIT zr2c_01_hello AND RETURN.

  EXEC SQL.
    SELECT COUNT(*) INTO :gv_count FROM vbak
  ENDEXEC.

  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_okcode.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
