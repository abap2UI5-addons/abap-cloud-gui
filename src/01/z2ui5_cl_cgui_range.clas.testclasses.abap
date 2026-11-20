" the client as the popup sees it - events in, popup and navigation out
CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mv_init  TYPE abap_bool.
    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.
    DATA mv_popup TYPE string.
    DATA mv_left  TYPE abap_bool.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
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
  METHOD z2ui5_if_client~message_toast_display.
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
  METHOD z2ui5_if_client~get.
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

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = `{/BOUND}`.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.

    mv_left = abap_true.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_c4 TYPE c LENGTH 4.
    TYPES ty_r_c4 TYPE RANGE OF ty_c4.

    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS run
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_range
        event TYPE string    OPTIONAL
        args  TYPE string_table OPTIONAL
        init  TYPE abap_bool DEFAULT abap_false.

    METHODS exclude_survives_roundtrip FOR TESTING.
    METHODS patterns_and_empty_lines FOR TESTING.
    METHODS invalid_value_keeps_range FOR TESTING.
    METHODS lower_above_upper FOR TESTING.
    METHODS initial_date_is_empty FOR TESTING.
    METHODS paste_from_clipboard FOR TESTING.
    METHODS f4_values_into_rows FOR TESTING.
    METHODS popup_view FOR TESTING.
    METHODS popup_add_delete_ok FOR TESTING.
    METHODS popup_f4_leaves FOR TESTING.
    METHODS popup_paste FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    CREATE OBJECT mo_client.

  ENDMETHOD.

  METHOD run.

    mo_client->mv_init  = init.
    mo_client->mv_event = event.
    mo_client->mt_arg   = args.
    popup->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD exclude_survives_roundtrip.

    DATA lt_range TYPE RANGE OF ty_c4.
    DATA lt_back  TYPE RANGE OF ty_c4.

    DATA temp1 LIKE lt_range.
    DATA temp2 LIKE LINE OF temp1.
    DATA lv_error TYPE string.
    CLEAR temp1.

    CLEAR temp2.
    temp2-sign = `I`.
    temp2-option = `BT`.
    temp2-low = `A`.
    temp2-high = `C`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-sign = `E`.
    temp2-option = `EQ`.
    temp2-low = `B`.
    INSERT temp2 INTO TABLE temp1.
    lt_range = temp1.


    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = z2ui5_cl_cgui_range=>rows_from_range( lt_range )
                                        IMPORTING error = lv_error
                                        CHANGING  range = lt_back ).

    cl_abap_unit_assert=>assert_initial( lv_error ).
    cl_abap_unit_assert=>assert_equals( act = lt_back
                                        exp = lt_range ).

  ENDMETHOD.

  METHOD patterns_and_empty_lines.

    DATA lt_range TYPE RANGE OF ty_c4.

    DATA temp3 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp4 LIKE LINE OF temp3.
    DATA lv_error TYPE string.
    DATA temp5 TYPE ty_r_c4.
    DATA temp6 LIKE LINE OF temp5.
    CLEAR temp3.

    CLEAR temp4.
    temp4-sign = `I`.
    temp4-option = `EQ`.
    temp4-low = `ab*`.
    INSERT temp4 INTO TABLE temp3.
    CLEAR temp4.
    temp4-sign = `E`.
    temp4-option = `CP`.
    temp4-low = `xy`.
    INSERT temp4 INTO TABLE temp3.
    CLEAR temp4.
    temp4-sign = `I`.
    temp4-option = `EQ`.
    INSERT temp4 INTO TABLE temp3.
    CLEAR temp4.
    temp4-sign = `I`.
    temp4-option = `BT`.
    temp4-low = `k`.
    INSERT temp4 INTO TABLE temp3.

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = temp3
                                                  upper = abap_true
                                        IMPORTING error = lv_error
                                        CHANGING  range = lt_range ).

    cl_abap_unit_assert=>assert_initial( lv_error ).

    CLEAR temp5.

    temp6-sign = `I`.
    temp6-option = `CP`.
    temp6-low = `AB*`.
    INSERT temp6 INTO TABLE temp5.
    temp6-sign = `E`.
    temp6-option = `EQ`.
    temp6-low = `XY`.
    INSERT temp6 INTO TABLE temp5.
    temp6-sign = `I`.
    temp6-option = `EQ`.
    temp6-low = `K`.
    INSERT temp6 INTO TABLE temp5.
    cl_abap_unit_assert=>assert_equals( act = lt_range
                                        exp = temp5 ).

  ENDMETHOD.

  METHOD invalid_value_keeps_range.

    DATA lt_range TYPE RANGE OF i.

    DATA temp7 LIKE lt_range.
    DATA temp8 LIKE LINE OF temp7.
    DATA temp9 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp10 LIKE LINE OF temp9.
    DATA lv_error TYPE string.
    FIELD-SYMBOLS <temp11> LIKE LINE OF lt_range.
    DATA temp12 LIKE sy-tabix.
    CLEAR temp7.

    temp8-sign = `I`.
    temp8-option = `EQ`.
    temp8-low = 7.
    INSERT temp8 INTO TABLE temp7.
    lt_range = temp7.

    CLEAR temp9.

    temp10-sign = `I`.
    temp10-option = `EQ`.
    temp10-low = `5`.
    INSERT temp10 INTO TABLE temp9.
    temp10-sign = `I`.
    temp10-option = `EQ`.
    temp10-low = `abc`.
    INSERT temp10 INTO TABLE temp9.

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = temp9
                                        IMPORTING error = lv_error
                                        CHANGING  range = lt_range ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_error
                                         exp = `*2*` ).


    temp12 = sy-tabix.
    READ TABLE lt_range INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp11>-low
                                        exp = 7 ).

  ENDMETHOD.

  METHOD lower_above_upper.

    DATA lt_range TYPE RANGE OF i.

    DATA temp13 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp14 LIKE LINE OF temp13.
    DATA lv_error TYPE string.
    CLEAR temp13.

    temp14-sign = `I`.
    temp14-option = `BT`.
    temp14-low = `9`.
    temp14-high = `3`.
    INSERT temp14 INTO TABLE temp13.

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = temp13
                                        IMPORTING error = lv_error
                                        CHANGING  range = lt_range ).

    cl_abap_unit_assert=>assert_not_initial( lv_error ).
    cl_abap_unit_assert=>assert_initial( lt_range ).

  ENDMETHOD.

  METHOD initial_date_is_empty.

    DATA lt_range TYPE RANGE OF d.

    DATA temp15 LIKE lt_range.
    DATA temp16 LIKE LINE OF temp15.
    DATA lt_row TYPE z2ui5_cl_cgui_range=>ty_t_row.
    FIELD-SYMBOLS <temp17> LIKE LINE OF lt_row.
    DATA temp18 LIKE sy-tabix.
    FIELD-SYMBOLS <temp19> LIKE LINE OF lt_row.
    DATA temp20 LIKE sy-tabix.
    CLEAR temp15.

    temp16-sign = `I`.
    temp16-option = `BT`.
    temp16-low = `00000000`.
    temp16-high = `20261231`.
    INSERT temp16 INTO TABLE temp15.
    lt_range = temp15.

    lt_row = z2ui5_cl_cgui_range=>rows_from_range( range   = lt_range
                                                         control = z2ui5_cl_cgui_range=>cs_control-date ).



    temp18 = sy-tabix.
    READ TABLE lt_row INDEX 1 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp17>-low ).


    temp20 = sy-tabix.
    READ TABLE lt_row INDEX 1 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp19>-high
                                        exp = `20261231` ).

  ENDMETHOD.

  METHOD paste_from_clipboard.

    DATA lt_row TYPE z2ui5_cl_cgui_range=>ty_t_row.
    FIELD-SYMBOLS <temp21> LIKE LINE OF lt_row.
    DATA temp22 LIKE sy-tabix.
    FIELD-SYMBOLS <temp23> LIKE LINE OF lt_row.
    DATA temp24 LIKE sy-tabix.
    lt_row = z2ui5_cl_cgui_range=>rows_from_text( |A\r\n  B \tC;D*\n\n| ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_row )
                                        exp = 4 ).


    temp22 = sy-tabix.
    READ TABLE lt_row INDEX 2 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp21>-low
                                        exp = `B` ).


    temp24 = sy-tabix.
    READ TABLE lt_row INDEX 4 ASSIGNING <temp23>.
    sy-tabix = temp24.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp23>-option
                                        exp = `CP` ).

  ENDMETHOD.

  METHOD f4_values_into_rows.

    DATA temp25 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp26 LIKE LINE OF temp25.
    DATA lt_row LIKE temp25.
    DATA temp27 TYPE string_table.
    FIELD-SYMBOLS <temp29> LIKE LINE OF lt_row.
    DATA temp30 LIKE sy-tabix.
    FIELD-SYMBOLS <temp31> LIKE LINE OF lt_row.
    DATA temp32 LIKE sy-tabix.
    CLEAR temp25.

    CLEAR temp26.
    temp26-key = `1`.
    temp26-sign = `I`.
    temp26-option = `BT`.
    temp26-low = `A`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-key = `2`.
    temp26-sign = `I`.
    temp26-option = `EQ`.
    INSERT temp26 INTO TABLE temp25.

    lt_row = temp25.

    z2ui5_cl_cgui_range=>row_set_value( EXPORTING row_key = `1`
                                                  part    = `high`
                                                  value   = `F`
                                        CHANGING  rows    = lt_row ).

    CLEAR temp27.
    INSERT `X` INTO TABLE temp27.
    INSERT `Y` INTO TABLE temp27.
    INSERT `X` INTO TABLE temp27.
    z2ui5_cl_cgui_range=>rows_add_values( EXPORTING values = temp27
                                          CHANGING  rows   = lt_row ).



    temp30 = sy-tabix.
    READ TABLE lt_row INDEX 1 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp29>-high
                                        exp = `F` ).


    temp32 = sy-tabix.
    READ TABLE lt_row INDEX 2 ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp31>-low
                                        exp = `X` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_row )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD popup_view.

    DATA lt_range TYPE RANGE OF ty_c4.

    DATA temp33 LIKE lt_range.
    DATA temp34 LIKE LINE OF temp33.
    DATA temp35 TYPE z2ui5_cl_cgui_range=>ty_s_setting.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.
    DATA lv_popup LIKE mo_client->mv_popup.
    FIELD-SYMBOLS <temp36> LIKE LINE OF lo_popup->mt_row.
    DATA temp37 LIKE sy-tabix.
    CLEAR temp33.

    temp34-sign = `E`.
    temp34-option = `EQ`.
    temp34-low = `B`.
    INSERT temp34 INTO TABLE temp33.
    lt_range = temp33.

    CLEAR temp35.
    temp35-title = `Code`.
    temp35-value_help = abap_true.

    lo_popup = z2ui5_cl_cgui_range=>factory( range   = lt_range
                                                   setting = temp35 ).
    run( popup = lo_popup
         init  = abap_true ).


    lv_popup = mo_client->mv_popup.
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*title="Code"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*selectedKey="{SIGN}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*valueHelpRequest="EVENT:CGUI_RANGE_F4"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*EVENT:CGUI_RANGE_F4_MULTI*` ).


    temp37 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 1 ASSIGNING <temp36>.
    sy-tabix = temp37.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp36>-sign
                                        exp = `E` ).

  ENDMETHOD.

  METHOD popup_add_delete_ok.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.
    DATA temp38 TYPE string_table.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lo_popup->mt_row.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp40> LIKE LINE OF lo_popup->mt_row.
    DATA temp41 LIKE sy-tabix.
    FIELD-SYMBOLS <temp42> LIKE LINE OF lo_popup->mt_row.
    DATA temp43 LIKE sy-tabix.
    DATA ls_result TYPE z2ui5_cl_cgui_range=>ty_s_result.
    FIELD-SYMBOLS <temp44> LIKE LINE OF ls_result-rows.
    DATA temp45 LIKE sy-tabix.
    lo_popup = z2ui5_cl_cgui_range=>factory( ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 1 ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-add ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 2 ).


    CLEAR temp38.


    temp2 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    INSERT <temp1>-key INTO TABLE temp38.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-delete
         args  = temp38 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 1 ).



    temp41 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 1 ASSIGNING <temp40>.
    sy-tabix = temp41.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp40>-sign = `E`.


    temp43 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 1 ASSIGNING <temp42>.
    sy-tabix = temp43.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp42>-low  = `Z`.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-ok ).


    ls_result = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_true( ls_result-confirmed ).


    temp45 = sy-tabix.
    READ TABLE ls_result-rows INDEX 1 ASSIGNING <temp44>.
    sy-tabix = temp45.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp44>-sign
                                        exp = `E` ).

  ENDMETHOD.

  METHOD popup_f4_leaves.

    DATA temp46 TYPE z2ui5_cl_cgui_range=>ty_s_setting.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.
    DATA temp47 TYPE string_table.
    DATA ls_result TYPE z2ui5_cl_cgui_range=>ty_s_result.
    CLEAR temp46.
    temp46-value_help = abap_true.

    lo_popup = z2ui5_cl_cgui_range=>factory( setting = temp46 ).
    run( popup = lo_popup
         init  = abap_true ).

    CLEAR temp47.
    INSERT `1` INTO TABLE temp47.
    INSERT `low` INTO TABLE temp47.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-f4
         args  = temp47 ).


    ls_result = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_false( ls_result-confirmed ).
    cl_abap_unit_assert=>assert_true( ls_result-f4 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-f4_key
                                        exp = `1` ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-f4_part
                                        exp = `LOW` ).

  ENDMETHOD.

  METHOD popup_paste.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.
    lo_popup = z2ui5_cl_cgui_range=>factory( ).
    run( popup = lo_popup
         init  = abap_true ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-paste ).
    cl_abap_unit_assert=>assert_true( lo_popup->mv_paste_open ).

    lo_popup->mv_paste = |LH\nAA\nUA|.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-paste_ok ).

    " the empty first line gave way to the three values
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_false( lo_popup->mv_paste_open ).
    cl_abap_unit_assert=>assert_initial( lo_popup->mv_paste ).

  ENDMETHOD.

ENDCLASS.
