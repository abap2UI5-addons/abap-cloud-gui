" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_41.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_41 DEFINITION LOCAL FRIENDS lcl_stamp.


CLASS lcl_stamp IMPLEMENTATION.
  METHOD constructor.
    TYPES ty_line TYPE x LENGTH 64.
    DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url TYPE c LENGTH 255.
    DATA lt_event TYPE z2ui5_cl_cgui_gui=>ty_t_simple_events.
    DATA temp1 TYPE z2ui5_cl_cgui_gui=>ty_s_simple_event.

    " a white GIF of one pixel - 43 bytes
    APPEND '47494638396101000100800000FFFFFF00000021F90401000000002C00000000010001000002024401003B' TO lt_bin.
    z2ui5_cl_cgui_frontend=>dp_create_url( EXPORTING  type    = 'image'
                                                      subtype = 'gif'
                                                      size    = 43
                                                      data    = lt_bin
                                           CHANGING   url     = lv_url
                                           EXCEPTIONS OTHERS  = 1 ).
    IF sy-subrc <> 0.
      lcl_r2c=>app->message( text = 'No URL for the stamp'
               type = `E` ).
      RETURN.
    ENDIF.

    CREATE OBJECT mo_dock TYPE z2ui5_cl_cgui_container EXPORTING side = z2ui5_cl_cgui_container=>dock_at_top.
    CREATE OBJECT mo_picture TYPE z2ui5_cl_cgui_picture EXPORTING parent = mo_dock.
    IF lcl_r2c=>app->p_fit = abap_true.
      mo_picture->set_display_mode( z2ui5_cl_cgui_picture=>display_mode_fit ).
    ENDIF.
    mo_picture->load_picture_from_url_async( lv_url ).

    CLEAR temp1.
    temp1-eventid = z2ui5_cl_cgui_picture=>eventid_picture_click.
    temp1-appl_event = abap_true.
    APPEND temp1 TO lt_event.
    mo_picture->set_registered_events( lt_event ).
    mo_picture->set_handler( handler = me
                             method  = `ON_CLICK`
                             event   = `PICTURE_CLICK` ).
  ENDMETHOD.

  METHOD on_click.
    mv_count = mv_count + 1.
    lcl_r2c=>app->message( |{ mv_count } stamp(s)| ).
  ENDMETHOD.
ENDCLASS.
