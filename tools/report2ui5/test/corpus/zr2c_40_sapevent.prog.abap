*&---------------------------------------------------------------------*
*& Report ZR2C_40_SAPEVENT
*&---------------------------------------------------------------------*
*& A menu as an HTML page on the screen: its SAPEVENT links raise
*& sapevent of cl_gui_html_viewer, an instance method of a local class
*& reacts with a message
*&---------------------------------------------------------------------*
REPORT zr2c_40_sapevent.

CLASS lcl_menu DEFINITION.
  PUBLIC SECTION.
    METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action.
ENDCLASS.

CLASS lcl_menu IMPLEMENTATION.
  METHOD on_sapevent.
    MESSAGE |You picked { action }| TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

DATA go_html TYPE REF TO cl_gui_html_viewer.
DATA go_menu TYPE REF TO lcl_menu.

START-OF-SELECTION.
  TYPES ty_line TYPE c LENGTH 255.
  DATA lt_html TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
  DATA lv_url TYPE c LENGTH 255.
  DATA lt_event TYPE cntl_simple_events.

  go_html = NEW cl_gui_html_viewer( parent = cl_gui_container=>default_screen ).
  APPEND VALUE #( eventid = cl_gui_html_viewer=>m_id_sapevent appl_event = abap_true ) TO lt_event.
  go_html->set_registered_events( lt_event ).
  go_menu = NEW lcl_menu( ).
  SET HANDLER go_menu->on_sapevent FOR go_html.

  lt_html = VALUE #( ( '<h2>Menu</h2>' )
                     ( '<a href="sapevent:SOUP">Soup of the day</a><br>' )
                     ( '<a href="sapevent:PASTA">Pasta</a>' ) ).
  go_html->load_data( IMPORTING assigned_url = lv_url
                      CHANGING  data_table   = lt_html ).
  go_html->show_url( lv_url ).
  WRITE: space.
