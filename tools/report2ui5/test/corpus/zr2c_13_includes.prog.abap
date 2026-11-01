*&---------------------------------------------------------------------*
*& Report ZR2C_13_INCLUDES
*&---------------------------------------------------------------------*
*& A report in three pieces, as a grown one is: the TOP include with the
*& globals, the selection screen and a macro, F01 with the FORMs, and an
*& include that is not there
*&---------------------------------------------------------------------*
REPORT zr2c_13_includes.

INCLUDE zr2c_13_includes_top.
INCLUDE zr2c_13_includes_f01.
INCLUDE zr2c_13_includes_nix IF FOUND.

START-OF-SELECTION.
  PERFORM fill_lines.
  LOOP AT gt_lines INTO gs_line.
    add_and_write gs_line-qty gs_line-text.
  ENDLOOP.
  WRITE: / 'Total:', gv_total.
