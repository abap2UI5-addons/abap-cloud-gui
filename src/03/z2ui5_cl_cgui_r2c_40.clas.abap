CLASS z2ui5_cl_cgui_r2c_40 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES ty_line TYPE c LENGTH 255.

    " global data of the report
    DATA go_html  TYPE REF TO z2ui5_cl_cgui_gui_html_viewer.
    DATA lt_html  TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url   TYPE c LENGTH 255.
    DATA lt_event TYPE z2ui5_cl_cgui_gui=>ty_t_simple_events.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_gui_event REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_menu TYPE REF TO lcl_menu.

ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_40 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    set_title( `A Menu as HTML` ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: go_html,
           go_menu,
           lt_html,
           lv_url,
           lt_event.

    go_html = NEW z2ui5_cl_cgui_gui_html_viewer( parent = z2ui5_cl_cgui_gui_container=>default_screen ).
    APPEND VALUE #( eventid = z2ui5_cl_cgui_gui_html_viewer=>m_id_sapevent appl_event = abap_true ) TO lt_event.
    go_html->set_registered_events( lt_event ).
    go_menu = NEW lcl_menu( ).
    go_html->set_handler( handler = go_menu
                          method  = `ON_SAPEVENT`
                          event   = `SAPEVENT` ).

    lt_html = VALUE #( ( '<h2>Menu</h2>' )
                       ( '<a href="sapevent:SOUP">Soup of the day</a><br>' )
                       ( '<a href="sapevent:PASTA">Pasta</a>' ) ).
    go_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    go_html->show_url( lv_url ).
    write( space ).

  ENDMETHOD.

  METHOD at_gui_event.

    lcl_r2c=>app = me.

  ENDMETHOD.

ENDCLASS.
