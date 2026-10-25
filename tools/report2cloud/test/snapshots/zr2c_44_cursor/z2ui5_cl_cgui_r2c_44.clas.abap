CLASS z2ui5_cl_cgui_r2c_44 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_peak,
        name   TYPE c LENGTH 20,
        height TYPE i,
      END OF ty_peak.

    " global data of the report
    DATA gs_peak  TYPE ty_peak.
    DATA gt_peak  TYPE STANDARD TABLE OF ty_peak WITH DEFAULT KEY.
    DATA lv_field TYPE c LENGTH 40.
    DATA lv_value TYPE c LENGTH 40.
    DATA lv_line  TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_44 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Peaks` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gs_peak,
           gt_peak,
           lv_field,
           lv_value,
           lv_line.

    gt_peak = VALUE #( ( name = 'Zugspitze'  height = 2962 )
                       ( name = 'Watzmann'   height = 2713 )
                       ( name = 'Feldberg'   height = 1493 ) ).
    LOOP AT gt_peak INTO gs_peak.
      list( )->new_line(
          )->write( val     = gs_peak-name
                    name    = `GS_PEAK-NAME`
                    hotspot = abap_true
          )->write( val     = gs_peak-height
                    name    = `GS_PEAK-HEIGHT`
                    hotspot = abap_true ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_line_selection.

    z2ui5_cl_cgui_gui=>get_cursor_field( IMPORTING  field = lv_field
                                                    value = lv_value
                                                    line  = lv_line
                                         EXCEPTIONS not_on_field = 4 ).
    IF sy-subrc = 0.
      list( )->new_line(
          )->write( |Line { lv_line }: { lv_field } = { condense( lv_value ) }| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
