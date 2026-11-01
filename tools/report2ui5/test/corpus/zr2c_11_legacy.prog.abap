*&---------------------------------------------------------------------*
*& Report ZR2C_11_LEGACY
*&---------------------------------------------------------------------*
*& Older statements: WRITE TO, CONCATENATE, global field symbols,
*& SELECT-OPTIONS defaults, SET PF-STATUS, AT USER-COMMAND with
*& sy-ucomm, LEAVE LIST-PROCESSING
*&---------------------------------------------------------------------*
REPORT zr2c_11_legacy.

DATA: gt_numbers TYPE STANDARD TABLE OF i WITH DEFAULT KEY,
      gv_text    TYPE c LENGTH 40,
      gv_sum     TYPE i,
      gv_sum_txt TYPE c LENGTH 12.

FIELD-SYMBOLS <gv_number> TYPE i.

SELECT-OPTIONS s_range FOR gv_sum DEFAULT 1 TO 20.
PARAMETERS p_title TYPE c LENGTH 30 DEFAULT 'Numbers'.

START-OF-SELECTION.
  SET PF-STATUS 'LIST'.
  DO 20 TIMES.
    IF sy-index IN s_range.
      APPEND sy-index TO gt_numbers.
    ENDIF.
  ENDDO.

  WRITE p_title TO gv_text.
  WRITE / gv_text COLOR COL_HEADING.
  LOOP AT gt_numbers ASSIGNING <gv_number>.
    gv_sum = gv_sum + <gv_number>.
    WRITE: / <gv_number>.
  ENDLOOP.
  CLEAR gv_text.
  WRITE gv_sum TO gv_sum_txt LEFT-JUSTIFIED.
  CONCATENATE 'Sum:' gv_sum_txt INTO gv_text SEPARATED BY space.
  WRITE / gv_text.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'BACK'.
      LEAVE LIST-PROCESSING.
    WHEN 'REFRESH'.
      MESSAGE 'Refreshed' TYPE 'S'.
  ENDCASE.
