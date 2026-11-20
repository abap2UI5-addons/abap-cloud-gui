CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mo_app       TYPE REF TO object.
    DATA mv_init      TYPE abap_bool.
    DATA mv_navigated TYPE abap_bool.
    DATA mv_event     TYPE string.
    DATA mt_arg       TYPE string_table.
    DATA ms_get       TYPE z2ui5_if_client=>ty_s_get.
    DATA mv_view      TYPE string.
    DATA mv_popup     TYPE string.
    DATA mt_action    TYPE string_table.
    DATA mo_called    TYPE REF TO z2ui5_if_app.
    DATA mo_prev      TYPE REF TO z2ui5_if_app.
    DATA mv_left      TYPE abap_bool.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_app    TYPE REF TO z2ui5_cl_cgui_sample_08.
    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS event
      IMPORTING
        name TYPE string
        args TYPE string_table OPTIONAL.

    METHODS cockpit_flow FOR TESTING.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~window_get_row.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~window_bind_tab.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_path.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_edit.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_client.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popup_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_model_update.
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
  METHOD z2ui5_if_client~view_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_init.

    result = mv_init.

  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_navigated.

    result = mv_navigated.

  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_event.

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( mv_init = abap_false AND mv_navigated = abap_false ).
    result = temp1.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event.

    result = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~get.

    result = ms_get.
    result-event = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app.

    result ?= mo_app.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev.

    result = mo_prev.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    IF tab IS SUPPLIED.
      result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                               val = tab ) }/{ tab_index - 1 }\}|.
      RETURN.
    ENDIF.
    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~view_display.

    mv_view = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~follow_up_action.

    DATA temp1 LIKE LINE OF mt_action.
    temp1 = |{ val }:{ concat_lines_of( table = t_arg sep = `|` ) }|.
    INSERT temp1 INTO TABLE mt_action.

  ENDMETHOD.

  METHOD z2ui5_if_client~message_toast_display ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~message_box_display ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_call.

    mo_called = app.

  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.

    mv_left = abap_true.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    CREATE OBJECT mo_app.
    CREATE OBJECT mo_client.
    mo_client->mo_app = mo_app.

  ENDMETHOD.

  METHOD event.

    mo_client->mv_event = name.
    mo_client->mt_arg = args.
    mo_app->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD cockpit_flow.
    DATA temp2 TYPE string_table.
        DATA temp4 TYPE REF TO z2ui5_cl_cgui_sample_05.

    " the selection screen with its tabs and the listbox
    mo_client->mv_init = abap_true.
    mo_app->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*<IconTabBar*Economy*` ).

    " Execute - the grid with selection, icons, currency and total (the
    " airline may come from the user's parameter CAR)
    mo_app->p_carrid = ``.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*CurrType*EVENT:BOOK*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*selected="{ZZSELKZ}"*` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_result )
                                        exp = 8 ).

    " a hotspot - the secondary list of the airline

    CLEAR temp2.
    INSERT `/XX/MT_RESULT/0` INTO TABLE temp2.
    INSERT `CARRID` INTO TABLE temp2.
    event( name = z2ui5_cl_cgui_alv=>cs_event-hotspot
           args = temp2 ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*Flights of LH*0402*` ).

    " Back to the grid, Book without a selection warns
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    event( `BOOK` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " SUBMIT of the flight report
    event( `REPORT` ).
    TRY.

        temp4 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp4 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_sample_05` ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
