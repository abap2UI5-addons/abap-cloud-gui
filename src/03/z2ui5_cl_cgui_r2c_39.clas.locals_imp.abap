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
    DATA temp1 TYPE z2ui5_cl_cgui_gui=>ty_s_simple_event.
    CREATE OBJECT mo_tool TYPE z2ui5_cl_cgui_toolbar EXPORTING parent = z2ui5_cl_cgui_container=>default_screen.
    mo_tool->add_button( fcode = 'COUNT' icon = `sap-icon://accept` butn_type = z2ui5_cl_cgui_toolbar=>cntb_btype_button text = 'Count' ).

    CLEAR temp1.
    temp1-eventid = z2ui5_cl_cgui_toolbar=>m_id_function_selected.
    temp1-appl_event = abap_true.
    APPEND temp1 TO lt_event.
    mo_tool->set_registered_events( lt_event ).
    mo_tool->set_handler( handler = me
                          method  = `ON_FUNCTION`
                          event   = `FUNCTION_SELECTED` ).
    CREATE OBJECT mo_edit TYPE z2ui5_cl_cgui_textedit EXPORTING parent = z2ui5_cl_cgui_container=>default_screen.
    mo_edit->set_textstream( lcl_r2c=>app->p_text ).
  ENDMETHOD.

  METHOD on_function.
    DATA lv_text TYPE string.
    mo_edit->get_textstream( IMPORTING text = lv_text ).
    lcl_r2c=>app->message( |The note has { strlen( lv_text ) } characters| ).
  ENDMETHOD.
ENDCLASS.
