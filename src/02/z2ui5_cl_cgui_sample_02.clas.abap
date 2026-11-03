CLASS z2ui5_cl_cgui_sample_02 DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA mo_list TYPE REF TO z2ui5_cl_cgui_list.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_02 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    client->view_display( mo_list->stringify( client = client
                                              title  = `abap-cloud-gui - List Output` ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get_event( ) = z2ui5_cl_cgui_list=>cs_event-line_selection.
      client->message_toast_display( |Line { client->get_event_arg( ) } selected, HIDE value { client->get_event_arg( 2 ) }| ).
    ENDIF.

  ENDMETHOD.

  METHOD model_init.

    DATA lv_date TYPE d VALUE `20260101`.

    mo_list = z2ui5_cl_cgui_list=>factory( ).

    mo_list->write( val   = `This is a list output`
                    color = z2ui5_cl_cgui_list=>cs_color-key
        )->uline(
        )->write( `Plain text`
        )->write( `next to plain text`
        )->new_line(
        )->write( `A date:`
        )->write( lv_date
        )->new_line(
        )->write( `Checkbox:`
        )->write_as_checkbox( abap_true
        )->write( `Icon:`
        )->write_as_icon( `sap-icon://accept`
        )->skip( 2
        )->write( val   = `Positive`
                  color = z2ui5_cl_cgui_list=>cs_color-positive
        )->write( val   = `Negative`
                  color = z2ui5_cl_cgui_list=>cs_color-negative
        )->write( val   = `Total`
                  color = z2ui5_cl_cgui_list=>cs_color-total
        )->new_page( `Second page` ).

    DO 5 TIMES.
      mo_list->write( val     = |Hotspot { sy-index }|
                      hotspot = abap_true
                      hide    = sy-index * 100
          )->write( `- click it for AT LINE-SELECTION`
          )->new_line( ).
    ENDDO.

  ENDMETHOD.

ENDCLASS.
