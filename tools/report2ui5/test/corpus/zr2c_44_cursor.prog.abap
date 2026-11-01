*&---------------------------------------------------------------------*
*& Report ZR2C_44_CURSOR
*&---------------------------------------------------------------------*
*& Peaks and their height: a click on a name or a height tells which
*& field of which line was clicked - GET CURSOR in AT LINE-SELECTION
*&---------------------------------------------------------------------*
REPORT zr2c_44_cursor.

TYPES:
  BEGIN OF ty_peak,
    name   TYPE c LENGTH 20,
    height TYPE i,
  END OF ty_peak.

DATA gs_peak TYPE ty_peak.
DATA gt_peak TYPE STANDARD TABLE OF ty_peak WITH DEFAULT KEY.

START-OF-SELECTION.
  gt_peak = VALUE #( ( name = 'Zugspitze'  height = 2962 )
                     ( name = 'Watzmann'   height = 2713 )
                     ( name = 'Feldberg'   height = 1493 ) ).
  LOOP AT gt_peak INTO gs_peak.
    WRITE: / gs_peak-name HOTSPOT, gs_peak-height HOTSPOT.
  ENDLOOP.

AT LINE-SELECTION.
  DATA lv_field TYPE c LENGTH 40.
  DATA lv_value TYPE c LENGTH 40.
  DATA lv_line TYPE i.
  GET CURSOR FIELD lv_field VALUE lv_value LINE lv_line.
  IF sy-subrc = 0.
    WRITE: / |Line { lv_line }: { lv_field } = { condense( lv_value ) }|.
  ENDIF.
