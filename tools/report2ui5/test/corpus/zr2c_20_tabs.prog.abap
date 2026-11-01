*&---------------------------------------------------------------------*
*& Report ZR2C_20_TABS
*&---------------------------------------------------------------------*
*& The selection screen of a grown report: a tabbed block whose tabs are
*& subscreens, two function keys in the toolbar (one with an icon), and
*& an own F1 help for a field
*&---------------------------------------------------------------------*
REPORT zr2c_20_tabs.

TABLES sscrfields.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.

SELECTION-SCREEN BEGIN OF TABBED BLOCK tabs FOR 6 LINES.
SELECTION-SCREEN TAB (20) tab_main USER-COMMAND main DEFAULT SCREEN 101.
SELECTION-SCREEN TAB (20) tab_opt USER-COMMAND opt DEFAULT SCREEN 102.
SELECTION-SCREEN END OF BLOCK tabs.

SELECTION-SCREEN BEGIN OF SCREEN 101 AS SUBSCREEN.
PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.
SELECT-OPTIONS s_fldate FOR sy-datum.
SELECTION-SCREEN END OF SCREEN 101.

SELECTION-SCREEN BEGIN OF SCREEN 102 AS SUBSCREEN.
PARAMETERS: p_max  TYPE i DEFAULT 50,
            p_full AS CHECKBOX.
SELECTION-SCREEN END OF SCREEN 102.

INITIALIZATION.
  DATA ls_text TYPE smp_dyntxt.
  tab_main = 'Flights'.
  tab_opt = 'Options'.
  sscrfields-functxt_01 = 'Today'.
  CLEAR ls_text.
  ls_text-icon_id = icon_refresh.
  ls_text-icon_text = 'Reset'.
  ls_text-quickinfo = 'Reset the selection'.
  sscrfields-functxt_02 = ls_text.
  tabs-activetab = 'OPT'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR p_max.
  MESSAGE 'The list shows at most this many flights' TYPE 'I'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      s_fldate[] = VALUE #( ( sign = 'I' option = 'EQ' low = sy-datum ) ).
    WHEN 'FC02'.
      CLEAR: s_fldate[], p_full.
      p_max = 50.
  ENDCASE.

START-OF-SELECTION.
  WRITE: / 'Airline', p_carrid, 'at most', p_max.
