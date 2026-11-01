*&---------------------------------------------------------------------*
*& Include ZR2C_13_INCLUDES_F01
*&---------------------------------------------------------------------*
FORM fill_lines.
  DATA lv_i TYPE i.
  DO p_count TIMES.
    lv_i = lv_i + 1.
    gs_line-text = |Line { lv_i }|.
    gs_line-qty = lv_i * 10.
    APPEND gs_line TO gt_lines.
  ENDDO.
ENDFORM.
