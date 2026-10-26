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
    METHODS at_roundtrip_start REDEFINITION.
    METHODS cgui_statics_keep REDEFINITION.
    METHODS cgui_statics_restore REDEFINITION.

  PRIVATE SECTION.
    " the CLASS-DATA of the local classes between two roundtrips
    " lcl_counter=>gv_count
    DATA mr_cgui_static1 TYPE REF TO data.
    " lcl_counter=>go_html
    DATA mr_cgui_static2 TYPE REF TO data.

ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_31 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A Counter with a Toolbar` ).

  ENDMETHOD.

  METHOD start_of_selection.

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

  METHOD at_roundtrip_start.

    lcl_r2c=>app = me.

  ENDMETHOD.

  METHOD cgui_statics_keep.

    " the CLASS-DATA of the local classes - kept with the app until the next roundtrip
    FIELD-SYMBOLS <lv_cgui_static> TYPE any.
    CREATE DATA mr_cgui_static1 LIKE lcl_counter=>gv_count.
    ASSIGN mr_cgui_static1->* TO <lv_cgui_static>.
    <lv_cgui_static> = lcl_counter=>gv_count.
    CREATE DATA mr_cgui_static2 LIKE lcl_counter=>go_html.
    ASSIGN mr_cgui_static2->* TO <lv_cgui_static>.
    <lv_cgui_static> = lcl_counter=>go_html.

  ENDMETHOD.

  METHOD cgui_statics_restore.

    " the CLASS-DATA of the local classes - as the last roundtrip left them
    FIELD-SYMBOLS <lv_cgui_static> TYPE any.
    IF mr_cgui_static1 IS BOUND.
      ASSIGN mr_cgui_static1->* TO <lv_cgui_static>.
      lcl_counter=>gv_count = <lv_cgui_static>.
    ENDIF.
    IF mr_cgui_static2 IS BOUND.
      ASSIGN mr_cgui_static2->* TO <lv_cgui_static>.
      lcl_counter=>go_html = <lv_cgui_static>.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
