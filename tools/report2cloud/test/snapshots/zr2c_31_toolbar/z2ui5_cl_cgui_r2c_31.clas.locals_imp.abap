" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_31.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS lcl_counter DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_r2c_31 DEFINITION LOCAL FRIENDS lcl_counter.

CLASS lcl_counter DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    CLASS-DATA gv_count TYPE i.
    CLASS-DATA go_html  TYPE REF TO z2ui5_cl_cgui_gui_html_viewer.
    CLASS-METHODS on_function FOR EVENT function_selected OF z2ui5_cl_cgui_gui_toolbar
      IMPORTING fcode.
    CLASS-METHODS show.
ENDCLASS.


CLASS lcl_counter IMPLEMENTATION.
  METHOD on_function.
    CASE fcode.
      WHEN 'UP'.
        gv_count = gv_count + 1.
      WHEN 'DOWN'.
        gv_count = gv_count - 1.
    ENDCASE.
    show( ).
  ENDMETHOD.

  METHOD show.
    TYPES ty_line TYPE c LENGTH 255.
    DATA lt_html TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url  TYPE c LENGTH 255.
    APPEND |<h1>Count: { gv_count }</h1>| TO lt_html.
    go_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    go_html->show_url( lv_url ).
  ENDMETHOD.
ENDCLASS.
