" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_39.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_39 DEFINITION LOCAL FRIENDS lcl_note.


CLASS lcl_note IMPLEMENTATION.
  METHOD constructor.
    DATA lt_event TYPE z2ui5_cl_cgui_gui=>ty_t_simple_events.
    mo_tool = NEW z2ui5_cl_cgui_gui_toolbar( parent = z2ui5_cl_cgui_gui_container=>default_screen ).
    mo_tool->add_button( fcode = 'COUNT' icon = `sap-icon://accept` butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button text = 'Count' ).
    APPEND VALUE #( eventid = z2ui5_cl_cgui_gui_toolbar=>m_id_function_selected appl_event = abap_true ) TO lt_event.
    mo_tool->set_registered_events( lt_event ).
    mo_tool->set_handler( handler = me
                          method  = `ON_FUNCTION`
                          event   = `FUNCTION_SELECTED` ).
    mo_edit = NEW z2ui5_cl_cgui_gui_textedit( parent = z2ui5_cl_cgui_gui_container=>default_screen ).
    mo_edit->set_textstream( lcl_r2c=>app->p_text ).
  ENDMETHOD.

  METHOD on_function.
    DATA lv_text TYPE string.
    mo_edit->get_textstream( IMPORTING text = lv_text ).
    lcl_r2c=>app->message( |The note has { strlen( lv_text ) } characters| ).
  ENDMETHOD.
ENDCLASS.
