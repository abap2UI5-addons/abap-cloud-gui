CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

    DATA mv_init   TYPE abap_bool.
    DATA mv_event  TYPE string.
    DATA mv_popup  TYPE string.
    DATA mv_left   TYPE string.
    DATA mv_toast  TYPE string.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.

  METHOD z2ui5_if_client~check_on_init.

    result = mv_init.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event.

    result = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.

    mv_left = event.

  ENDMETHOD.

  METHOD z2ui5_if_client~message_toast_display.

    mv_toast = text.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = `{/MT_ROW}`.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = val.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS pick_a_request FOR TESTING.
    METHODS no_transport FOR TESTING.
    METHODS nothing_picked FOR TESTING.

    METHODS popup
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_transport.

    DATA mo_client TYPE REF TO ltcl_client.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD popup.

    mo_client = NEW #( ).
    result = z2ui5_cl_cgui_transport=>factory( event = `TRANSPORT`
                                               rows  = VALUE #( ( transport = `A4HK900001` task = `A4HK900002` description = `Customizing` )
                                                                ( transport = `A4HK900003` task = `A4HK900004` description = `Workbench` ) ) ).
    mo_client->mv_init = abap_true.
    result->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

  ENDMETHOD.

  METHOD pick_a_request.

    DATA(lo_popup) = popup( ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_popup CS `{TRANSPORT}` ) ).

    lo_popup->mt_row[ 2 ]-selkz = abap_true.
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-select.
    lo_popup->z2ui5_if_app~main( mo_client ).

    cl_abap_unit_assert=>assert_equals( act = lo_popup->result( )
                                        exp = VALUE z2ui5_cl_cgui_transport=>ty_s_result( confirmed = abap_true
                                                                                          transport = `A4HK900003`
                                                                                          task      = `A4HK900004` ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_left
                                        exp = `TRANSPORT` ).

  ENDMETHOD.

  METHOD no_transport.

    DATA(lo_popup) = popup( ).
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-local.
    lo_popup->z2ui5_if_app~main( mo_client ).

    cl_abap_unit_assert=>assert_true( lo_popup->result( )-local ).
    cl_abap_unit_assert=>assert_initial( lo_popup->result( )-transport ).

  ENDMETHOD.

  METHOD nothing_picked.

    DATA(lo_popup) = popup( ).
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-select.
    lo_popup->z2ui5_if_app~main( mo_client ).

    " the popup stays, a toast says why
    cl_abap_unit_assert=>assert_initial( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_not_initial( mo_client->mv_toast ).
    cl_abap_unit_assert=>assert_false( lo_popup->result( )-confirmed ).

  ENDMETHOD.

ENDCLASS.
