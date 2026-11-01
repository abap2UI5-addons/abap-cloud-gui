*&---------------------------------------------------------------------*
*& Report ZR2C_12_PAGES
*&---------------------------------------------------------------------*
*& Pages of a list - LINE-COUNT, TOP-OF-PAGE with the page number,
*& END-OF-PAGE, NEW-PAGE NO-HEADING, TOP-OF-PAGE DURING LINE-SELECTION -
*& and the checks of the selection screen per block, radio button group
*& and multiple selection
*&---------------------------------------------------------------------*
REPORT zr2c_12_pages NO STANDARD PAGE HEADING LINE-COUNT 6(1).

DATA: gv_num   TYPE i,
      gv_count TYPE i.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
PARAMETERS p_lines TYPE i DEFAULT 7.
SELECT-OPTIONS s_skip FOR gv_num NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

PARAMETERS: p_list RADIOBUTTON GROUP mode DEFAULT 'X',
            p_last RADIOBUTTON GROUP mode.

AT SELECTION-SCREEN ON BLOCK b1.
  IF p_lines > 20.
    MESSAGE 'At most 20 lines' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON RADIOBUTTON GROUP mode.
  IF p_last = abap_true AND p_lines < 2.
    MESSAGE 'A last page needs two lines' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON END OF s_skip.
  IF lines( s_skip ) > 3.
    MESSAGE 'Skip at most 3 numbers' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON EXIT-COMMAND.
  MESSAGE 'Selection left' TYPE 'S'.

TOP-OF-PAGE.
  WRITE: / 'Numbers - page', sy-pagno.
  ULINE.

TOP-OF-PAGE DURING LINE-SELECTION.
  WRITE / 'Detail'.
  ULINE.

END-OF-PAGE.
  WRITE / 'continued'.

START-OF-SELECTION.
  DO p_lines TIMES.
    gv_num = sy-index.
    IF s_skip IS NOT INITIAL AND gv_num IN s_skip.
      CONTINUE.
    ENDIF.
    WRITE / gv_num HOTSPOT.
    HIDE gv_num.
    gv_count = gv_count + 1.
  ENDDO.
  IF p_last = abap_true.
    NEW-PAGE NO-HEADING.
    WRITE / 'Last page'.
  ENDIF.

END-OF-SELECTION.
  WRITE: / 'Count:', gv_count.

AT LINE-SELECTION.
  WRITE: / 'Number', gv_num.
