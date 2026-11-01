*&---------------------------------------------------------------------*
*& Report ZR2C_07_MESSAGES
*&---------------------------------------------------------------------*
*& Every form of MESSAGE: literal, text symbol, message class with
*& short and long form, WITH, DISPLAY LIKE, and the types S I W E
*&---------------------------------------------------------------------*
REPORT zr2c_07_messages MESSAGE-ID zr2c.

DATA gv_text TYPE string.

PARAMETERS: p_type TYPE c LENGTH 1 DEFAULT 'S' OBLIGATORY,
            p_num  TYPE i DEFAULT 42.

AT SELECTION-SCREEN.
  IF p_type NA 'SIWE'.
    MESSAGE e010 WITH p_type.
  ENDIF.
  IF p_num < 0.
    MESSAGE ID 'ZR2C' TYPE 'E' NUMBER '011' WITH p_num 'is negative'.
  ENDIF.

START-OF-SELECTION.
  CASE p_type.
    WHEN 'S'.
      MESSAGE 'A status message' TYPE 'S'.
    WHEN 'I'.
      MESSAGE TEXT-001 TYPE 'I'.
    WHEN 'W'.
      MESSAGE w012(zr2c) WITH p_num.
    WHEN 'E'.
      gv_text = |Number { p_num } is not allowed|.
      MESSAGE gv_text TYPE 'S' DISPLAY LIKE 'E'.
  ENDCASE.
  MESSAGE s013 WITH p_num INTO gv_text.
  WRITE: / 'Last message:'(002), gv_text.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
