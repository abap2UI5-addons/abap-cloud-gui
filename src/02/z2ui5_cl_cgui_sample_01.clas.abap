CLASS z2ui5_cl_cgui_sample_01 DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA p_text  TYPE string.
    DATA p_matnr TYPE c LENGTH 18.
    DATA p_date  TYPE d.
    DATA p_time  TYPE t.
    DATA p_count TYPE i.
    DATA p_flag  TYPE abap_bool.
    DATA p_rb_a  TYPE abap_bool.
    DATA p_rb_b  TYPE abap_bool.
    DATA p_from  TYPE i.
    DATA p_to    TYPE i.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_01 IMPLEMENTATION.

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

    DATA(screen) = z2ui5_cl_cgui_selscreen=>factory( client
        )->block_begin( `Parameters`
        )->parameter( val = p_text  text = `Text` obligatory = abap_true
        )->parameter( val = p_matnr text = `Material`
        )->parameter( val = p_date  text = `Date`
        )->parameter( val = p_time  text = `Time`
        )->parameter( val = p_count text = `Count`
        )->checkbox( val = p_flag text = `Flag`
        )->block_end(
        )->block_begin( `Radio buttons and lines`
        )->radiobutton( val = p_rb_a text = `Option A` group = `G1`
        )->radiobutton( val = p_rb_b text = `Option B` group = `G1`
        )->line_begin( `Interval`
        )->parameter( val = p_from text = `from`
        )->parameter( val = p_to   text = `to`
        )->line_end(
        )->block_end(
        )->comment( `Press the button to send the values to the backend.`
        )->button( text = `Show values` event = `SHOW` icon = `sap-icon://message-information` ).

    client->view_display( screen->stringify( `abap-cloud-gui - Selection Screen` ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get_event( ) = `SHOW`.
      client->message_box_display( |Text: { p_text }, material: { p_matnr }, date: { p_date }, time: { p_time }, | &&
                                   |count: { p_count }, flag: { p_flag }, A: { p_rb_a }, B: { p_rb_b }, | &&
                                   |interval: { p_from } - { p_to }| ).
    ENDIF.

  ENDMETHOD.

  METHOD model_init.

    p_text = `Hello`.
    p_date = `20260101`.
    p_time = `120000`.
    p_count = 10.
    p_rb_a = abap_true.
    p_from = 1.
    p_to = 100.

  ENDMETHOD.

ENDCLASS.
