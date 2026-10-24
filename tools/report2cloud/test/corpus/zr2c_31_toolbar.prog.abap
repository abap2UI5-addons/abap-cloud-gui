*&---------------------------------------------------------------------*
*& Report ZR2C_31_TOOLBAR
*&---------------------------------------------------------------------*
*& A toolbar and an HTML viewer on the screen itself: the buttons count
*& up and down, a static method of a local class handles the event and
*& shows the count in the viewer
*&---------------------------------------------------------------------*
REPORT zr2c_31_toolbar.

CLASS lcl_counter DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA gv_count TYPE i.
    CLASS-DATA go_html  TYPE REF TO cl_gui_html_viewer.
    CLASS-METHODS on_function FOR EVENT function_selected OF cl_gui_toolbar
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

DATA go_toolbar TYPE REF TO cl_gui_toolbar.

START-OF-SELECTION.
  go_toolbar = NEW cl_gui_toolbar( parent = cl_gui_container=>default_screen ).
  go_toolbar->add_button( fcode = 'UP'   icon = icon_increase butn_type = cntb_btype_button text = 'Up' ).
  go_toolbar->add_button( fcode = 'DOWN' icon = icon_decrease butn_type = cntb_btype_button text = 'Down' ).

  DATA lt_event TYPE cntl_simple_events.
  APPEND VALUE #( eventid = cl_gui_toolbar=>m_id_function_selected appl_event = abap_true ) TO lt_event.
  go_toolbar->set_registered_events( lt_event ).
  SET HANDLER lcl_counter=>on_function FOR go_toolbar.

  lcl_counter=>go_html = NEW cl_gui_html_viewer( parent = cl_gui_container=>default_screen ).
  lcl_counter=>show( ).
  WRITE: space.
