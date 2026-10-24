CLASS z2ui5_cl_cgui_r2c_31 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA go_toolbar TYPE REF TO z2ui5_cl_cgui_gui_toolbar.
    DATA lt_event   TYPE z2ui5_cl_cgui_gui=>ty_t_simple_events.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_gui_event REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_31 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    set_title( `A Counter with a Toolbar` ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: go_toolbar,
           lt_event.

    go_toolbar = NEW z2ui5_cl_cgui_gui_toolbar( parent = z2ui5_cl_cgui_gui_container=>default_screen ).
    go_toolbar->add_button( fcode = 'UP'   icon = `sap-icon://add` butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button text = 'Up' ).
    go_toolbar->add_button( fcode = 'DOWN' icon = `sap-icon://less` butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button text = 'Down' ).

    APPEND VALUE #( eventid = z2ui5_cl_cgui_gui_toolbar=>m_id_function_selected appl_event = abap_true ) TO lt_event.
    go_toolbar->set_registered_events( lt_event ).
    go_toolbar->set_handler( handler = NEW lcl_counter( )
                             method  = `ON_FUNCTION`
                             event   = `FUNCTION_SELECTED` ).

    lcl_counter=>go_html = NEW z2ui5_cl_cgui_gui_html_viewer( parent = z2ui5_cl_cgui_gui_container=>default_screen ).
    lcl_counter=>show( ).
    write( space ).

  ENDMETHOD.

  METHOD at_gui_event.

    lcl_r2c=>app = me.

  ENDMETHOD.

ENDCLASS.
