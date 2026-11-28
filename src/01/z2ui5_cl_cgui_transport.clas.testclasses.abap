CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mv_init   TYPE abap_bool.
    DATA mv_event  TYPE string.
    DATA mv_popup  TYPE string.
    DATA mv_left   TYPE string.
    DATA mv_toast  TYPE string.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
  METHOD z2ui5_if_client~timer_stop.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~timer_set.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_nav_back.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_nav_tag.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_nav_pending.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_navigated.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_event.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~follow_up_action.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~window_bind_tab.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_path.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_client.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~message_box_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nav_app_call.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_app.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_event_arg.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_start_param.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~hash_replace.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~hash_set.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~app_state_get_href.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~app_state_set_active.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~set_session_stateful.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.

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
    DATA temp1 TYPE z2ui5_cl_cgui_transport=>ty_t_row.
    DATA temp2 LIKE LINE OF temp1.

    CREATE OBJECT mo_client.

    CLEAR temp1.

    temp2-transport = `A4HK900001`.
    temp2-task = `A4HK900002`.
    temp2-description = `Customizing`.
    INSERT temp2 INTO TABLE temp1.
    temp2-transport = `A4HK900003`.
    temp2-task = `A4HK900004`.
    temp2-description = `Workbench`.
    INSERT temp2 INTO TABLE temp1.
    result = z2ui5_cl_cgui_transport=>factory( event = `TRANSPORT`
                                               rows  = temp1 ).
    mo_client->mv_init = abap_true.
    result->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

  ENDMETHOD.

  METHOD pick_a_request.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_transport.
    DATA temp1 TYPE xsdboolean.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lo_popup->mt_row.
    DATA temp4 LIKE sy-tabix.
    DATA temp5 TYPE z2ui5_cl_cgui_transport=>ty_s_result.
    lo_popup = popup( ).

    temp1 = boolc( mo_client->mv_popup CS `{TRANSPORT}` ).
    cl_abap_unit_assert=>assert_true( temp1 ).



    temp4 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 2 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp3>-selkz = abap_true.
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-select.
    lo_popup->z2ui5_if_app~main( mo_client ).


    CLEAR temp5.
    temp5-confirmed = abap_true.
    temp5-transport = `A4HK900003`.
    temp5-task = `A4HK900004`.
    cl_abap_unit_assert=>assert_equals( act = lo_popup->result( )
                                        exp = temp5 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_left
                                        exp = `TRANSPORT` ).

  ENDMETHOD.

  METHOD no_transport.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_transport.
    lo_popup = popup( ).
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-local.
    lo_popup->z2ui5_if_app~main( mo_client ).

    cl_abap_unit_assert=>assert_true( lo_popup->result( )-local ).
    cl_abap_unit_assert=>assert_initial( lo_popup->result( )-transport ).

  ENDMETHOD.

  METHOD nothing_picked.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_transport.
    lo_popup = popup( ).
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-select.
    lo_popup->z2ui5_if_app~main( mo_client ).

    " the popup stays, a toast says why
    cl_abap_unit_assert=>assert_initial( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_not_initial( mo_client->mv_toast ).
    cl_abap_unit_assert=>assert_false( lo_popup->result( )-confirmed ).

  ENDMETHOD.

ENDCLASS.
