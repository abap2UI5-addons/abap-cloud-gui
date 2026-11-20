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
    DATA mo_app    TYPE REF TO z2ui5_cl_cgui_sample_10.
    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS event
      IMPORTING
        name TYPE string
        args TYPE string_table OPTIONAL.

    "! the hit list the report opened, left with the row at index
    METHODS pick
      IMPORTING
        index TYPE i.

    METHODS network_flow FOR TESTING.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
  METHOD z2ui5_if_client~check_app_prev_stack.
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

    DATA temp1 TYPE string.
    IF t_arg IS NOT INITIAL.
      temp1 = |:{ concat_lines_of( table = t_arg sep = `,` ) }|.
    ELSE.
      CLEAR temp1.
    ENDIF.
    result = |EVENT:{ val }{ temp1 }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~view_display.

    mv_view = val.

  ENDMETHOD.

  " the double keeps the rows in the order of the table
  METHOD z2ui5_if_client~window_get_row.

    result = row.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~follow_up_action.

    DATA temp2 LIKE LINE OF mt_action.
    temp2 = |{ val }:{ concat_lines_of( table = t_arg sep = `|` ) }|.
    INSERT temp2 INTO TABLE mt_action.

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

  METHOD pick.

    DATA temp3 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp3.
    DATA temp4 TYPE string_table.
    DATA temp1 LIKE LINE OF temp4.
    temp3 ?= mo_client->mo_called.

    lo_select = temp3.
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.

    CLEAR temp4.

    temp1 = |/XX/MR_VIEW/{ index - 1 }|.
    INSERT temp1 INTO TABLE temp4.
    mo_client->mt_arg = temp4.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_app->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD network_flow.

    " the selection screen - F4 on from and to of the airline
    DATA temp6 LIKE mo_app->s_carrid.
    DATA temp7 LIKE LINE OF temp6.
    DATA temp8 TYPE string_table.
        DATA temp10 TYPE REF TO z2ui5_cl_cgui_select.
    FIELD-SYMBOLS <temp11> LIKE LINE OF mo_app->s_carrid.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp13> LIKE LINE OF mo_app->s_carrid.
    DATA temp14 LIKE sy-tabix.
    DATA temp15 TYPE string_table.
    DATA lv_flight TYPE z2ui5_cl_cgui_tree=>ty_s_view-key.
    FIELD-SYMBOLS <temp2> LIKE LINE OF mo_app->mt_cgui_tree_view.
    DATA temp3 LIKE sy-tabix.
    FIELD-SYMBOLS <temp17> LIKE LINE OF mo_app->mt_cgui_tree_view.
    DATA temp18 LIKE sy-tabix.
    DATA temp19 TYPE string_table.
    DATA temp4 LIKE LINE OF temp19.
    FIELD-SYMBOLS <temp21> LIKE LINE OF mo_app->mt_cgui_tree_view.
    DATA temp22 LIKE sy-tabix.
    DATA temp23 TYPE string_table.
    DATA temp25 TYPE string_table.
    DATA temp27 TYPE i.
    DATA n TYPE i.
    DATA ls_row LIKE LINE OF mo_app->mt_cgui_tree_view.
    DATA temp28 TYPE string_table.
    DATA temp5 LIKE LINE OF temp28.
    DATA temp30 TYPE string_table.
        DATA temp32 TYPE REF TO z2ui5_cl_cgui_select.
    FIELD-SYMBOLS <temp33> LIKE LINE OF mo_app->mt_plan.
    DATA temp34 LIKE sy-tabix.
    CLEAR temp6.

    temp7-sign = `I`.
    temp7-option = `EQ`.
    temp7-low = `AA`.
    INSERT temp7 INTO TABLE temp6.
    mo_app->s_carrid = temp6.
    mo_client->mv_init = abap_true.
    mo_app->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*EVENT:CGUI_VALUE_REQUEST:S_CARRID,HIGH*` ).

    " F4 on the upper limit: the own hit list, LH (the third) picked

    CLEAR temp8.
    INSERT `S_CARRID` INTO TABLE temp8.
    INSERT `HIGH` INTO TABLE temp8.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp8 ).
    TRY.

        temp10 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp10 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.
    pick( 3 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->s_carrid )
                                        exp = 1 ).


    temp12 = sy-tabix.
    READ TABLE mo_app->s_carrid INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp11>-option
                                        exp = `BT` ).


    temp14 = sy-tabix.
    READ TABLE mo_app->s_carrid INDEX 1 ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp13>-high
                                        exp = `LH` ).

    " Execute - the tree of AA, JL and LH, AA open with its connections
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*EVENT:FREE*EVENT:CGUI_TREE_EXPAND_ALL*` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_cgui_tree_view )
                                        exp = 5 ).

    " Free seats without a tick warns
    event( `FREE` ).
    cl_abap_unit_assert=>assert_initial( mo_app->mv_free ).

    " open the connection 0017 - its flight is loaded now

    CLEAR temp15.
    INSERT `2` INTO TABLE temp15.
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = temp15 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_cgui_tree_view )
                                        exp = 6 ).



    temp3 = sy-tabix.
    READ TABLE mo_app->mt_cgui_tree_view INDEX 3 ASSIGNING <temp2>.
    sy-tabix = temp3.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_flight = <temp2>-key.

    " the tick sums up at once: 385 - 300 free


    temp18 = sy-tabix.
    READ TABLE mo_app->mt_cgui_tree_view INDEX 3 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp17>-checked = abap_true.

    CLEAR temp19.

    temp4 = |{ lv_flight }|.
    INSERT temp4 INTO TABLE temp19.
    event( name = z2ui5_cl_cgui_tree=>cs_event-checkbox
           args = temp19 ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->mv_free
                                        exp = 85 ).
    event( `FREE` ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->mv_free
                                        exp = 85 ).

    " a tick on the airline AA: the loaded flight of 0064 follows when it
    " is opened - 85 + 0


    temp22 = sy-tabix.
    READ TABLE mo_app->mt_cgui_tree_view INDEX 1 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp21>-checked = abap_true.

    CLEAR temp23.
    INSERT `1` INTO TABLE temp23.
    event( name = z2ui5_cl_cgui_tree=>cs_event-checkbox
           args = temp23 ).

    CLEAR temp25.
    INSERT `3` INTO TABLE temp25.
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = temp25 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_cgui_tree_view )
                                        exp = 7 ).


    n = 0.

    LOOP AT mo_app->mt_cgui_tree_view INTO ls_row WHERE checked = abap_true.
      n = n + 1.
    ENDLOOP.
    temp27 = n.
    cl_abap_unit_assert=>assert_equals( act = temp27
                                        exp = 5 ).

    " a click on the flight - its details, Back to the tree

    CLEAR temp28.

    temp5 = |{ lv_flight }|.
    INSERT temp5 INTO TABLE temp28.
    event( name = z2ui5_cl_cgui_tree=>cs_event-node
           args = temp28 ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*Flight AA 0017*` ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_cgui_tree_view )
                                        exp = 7 ).

    " the booking plan: F4 in the airline of the first row, UA picked
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    mo_app->p_tree = abap_false.
    mo_app->p_plan = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*showValueHelp="true"*EVENT:CGUI_ALV_F4*` ).

    CLEAR temp30.
    INSERT `/XX/MT_PLAN/0` INTO TABLE temp30.
    INSERT `CARRID` INTO TABLE temp30.
    event( name = z2ui5_cl_cgui_alv=>cs_event-f4
           args = temp30 ).
    TRY.

        temp32 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp32 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.
    pick( 5 ).


    temp34 = sy-tabix.
    READ TABLE mo_app->mt_plan INDEX 1 ASSIGNING <temp33>.
    sy-tabix = temp34.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp33>-carrid
                                        exp = `UA` ).

  ENDMETHOD.

ENDCLASS.
