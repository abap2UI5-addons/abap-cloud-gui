" the client as the popup sees it - events in, popup and navigation out
CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mv_init  TYPE abap_bool.
    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.
    DATA mv_popup TYPE string.
    DATA mv_left  TYPE abap_bool.
    DATA mv_leave_event TYPE string.
    " the request of a window event (get( )-r_event_data)
    DATA mr_event_data TYPE REF TO data.

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
  METHOD z2ui5_if_client~_bind_path.
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
  METHOD z2ui5_if_client~get_start_param.
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

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    DATA temp1 TYPE string.
    IF path = abap_true.
      temp1 = `/MR_VIEW`.
    ELSE.
      temp1 = `{/MR_VIEW}`.
    ENDIF.
    result = temp1.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~window_bind_tab.

    result = `{/MR_VIEW}`.

  ENDMETHOD.

  METHOD z2ui5_if_client~get.

    result-event = mv_event.
    result-r_event_data = mr_event_data.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.

    mv_left = abap_true.
    mv_leave_event = event.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE land1,
        text   TYPE string,
        fldate TYPE d,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_marked,
        value   TYPE c LENGTH 4,
        zzselkz TYPE abap_bool,
      END OF ty_s_marked.
    TYPES ty_t_marked TYPE STANDARD TABLE OF ty_s_marked WITH DEFAULT KEY.

    DATA mo_client TYPE REF TO ltcl_client.
    DATA mt_row    TYPE ty_t_row.

    METHODS setup.

    METHODS run
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_select
        event TYPE string       OPTIONAL
        args  TYPE string_table OPTIONAL
        init  TYPE abap_bool    DEFAULT abap_false.

    METHODS columns_and_labels FOR TESTING.
    METHODS single_pick_by_path FOR TESTING.
    METHODS search_keeps_marks FOR TESTING.
    METHODS preselected_rows FOR TESTING.
    METHODS table_of_strings FOR TESTING.
    METHODS cancel_leaves FOR TESTING.
    METHODS window_more_rows FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    DATA temp2 TYPE ltcl_test=>ty_t_row.
    DATA temp3 LIKE LINE OF temp2.

    CREATE OBJECT mo_client.

    CLEAR temp2.

    temp3-carrid = `LH`.
    temp3-text = `Lufthansa`.
    temp3-fldate = `20261001`.
    INSERT temp3 INTO TABLE temp2.
    temp3-carrid = `AA`.
    temp3-text = `American`.
    temp3-fldate = `20261002`.
    INSERT temp3 INTO TABLE temp2.
    temp3-carrid = `UA`.
    temp3-text = `United`.
    temp3-fldate = `20261003`.
    INSERT temp3 INTO TABLE temp2.
    mt_row = temp2.

  ENDMETHOD.

  METHOD run.

    mo_client->mv_init  = init.
    mo_client->mv_event = event.
    mo_client->mt_arg   = args.
    popup->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD columns_and_labels.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA lt_column TYPE z2ui5_cl_cgui_select=>ty_t_column.
    FIELD-SYMBOLS <temp4> LIKE LINE OF lt_column.
    DATA temp5 LIKE sy-tabix.
    FIELD-SYMBOLS <temp6> LIKE LINE OF lt_column.
    DATA temp7 LIKE sy-tabix.
    lo_popup = z2ui5_cl_cgui_select=>factory( tab   = mt_row
                                                    title = `Airline` ).
    run( popup = lo_popup
         init  = abap_true ).


    lt_column = lo_popup->get_columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_column )
                                        exp = 3 ).
    " the DDIC label of the data element - on a system the text of LAND1, in
    " the transpiled runtime, where it has none, the name; the name for a
    " local type


    temp5 = sy-tabix.
    READ TABLE lt_column INDEX 1 ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_not_initial( <temp4>-label ).


    temp7 = sy-tabix.
    READ TABLE lt_column INDEX 2 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp6>-label
                                        exp = `TEXT` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*<TableSelectDialog*title="Airline"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*selected="{ZZSELKZ}"*` ).

  ENDMETHOD.

  METHOD single_pick_by_path.

    FIELD-SYMBOLS <row>  TYPE ty_s_row.
    FIELD-SYMBOLS <rows> TYPE ty_t_row.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA temp8 TYPE string_table.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    lo_popup = z2ui5_cl_cgui_select=>factory( mt_row ).
    run( popup = lo_popup
         init  = abap_true ).

    CLEAR temp8.
    INSERT `/MR_VIEW/1` INTO TABLE temp8.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm
         args  = temp8 ).


    ls_result = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( ls_result-confirmed ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    ASSIGN ls_result-row->* TO <row>.
    cl_abap_unit_assert=>assert_equals( act = <row>-carrid
                                        exp = `AA` ).
    ASSIGN ls_result-table->* TO <rows>.
    cl_abap_unit_assert=>assert_equals( act = lines( <rows> )
                                        exp = 1 ).

  ENDMETHOD.

  METHOD search_keeps_marks.

    FIELD-SYMBOLS <rows> TYPE ty_t_row.
    FIELD-SYMBOLS <view> TYPE STANDARD TABLE.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA temp10 TYPE string_table.
    DATA temp12 TYPE string_table.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    DATA temp14 TYPE ty_t_row.
    FIELD-SYMBOLS <temp1> LIKE LINE OF mt_row.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp3> LIKE LINE OF mt_row.
    DATA temp4 LIKE sy-tabix.
    lo_popup = z2ui5_cl_cgui_select=>factory( tab         = mt_row
                                                    multiselect = abap_true
                                                    event       = `PICKED` ).
    run( popup = lo_popup
         init  = abap_true ).
    lo_popup->select_row( 1 ).


    CLEAR temp10.
    INSERT `united` INTO TABLE temp10.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-search
         args  = temp10 ).
    ASSIGN lo_popup->mr_view->* TO <view>.
    cl_abap_unit_assert=>assert_equals( act = lines( <view> )
                                        exp = 1 ).
    lo_popup->select_row( 3 ).


    CLEAR temp12.
    INSERT `` INTO TABLE temp12.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-search
         args  = temp12 ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm ).


    ls_result = lo_popup->result( ).
    ASSIGN ls_result-table->* TO <rows>.

    CLEAR temp14.


    temp2 = sy-tabix.
    READ TABLE mt_row INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    INSERT <temp1> INTO TABLE temp14.


    temp4 = sy-tabix.
    READ TABLE mt_row INDEX 3 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    INSERT <temp3> INTO TABLE temp14.
    cl_abap_unit_assert=>assert_equals( act = <rows>
                                        exp = temp14 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_leave_event
                                        exp = `PICKED` ).

  ENDMETHOD.

  METHOD preselected_rows.

    FIELD-SYMBOLS <rows> TYPE ty_t_marked.

    DATA temp16 TYPE ty_t_marked.
    DATA temp17 LIKE LINE OF temp16.
    DATA lt_marked LIKE temp16.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    FIELD-SYMBOLS <temp18> LIKE LINE OF <rows>.
    DATA temp19 LIKE sy-tabix.
    CLEAR temp16.

    CLEAR temp17.
    temp17-value = `A`.
    INSERT temp17 INTO TABLE temp16.
    CLEAR temp17.
    temp17-value = `B`.
    temp17-zzselkz = abap_true.
    INSERT temp17 INTO TABLE temp16.

    lt_marked = temp16.

    lo_popup = z2ui5_cl_cgui_select=>factory( tab         = lt_marked
                                                    multiselect = abap_true ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->get_columns( ) )
                                        exp = 1 ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm ).


    ls_result = lo_popup->result( ).
    ASSIGN ls_result-table->* TO <rows>.
    cl_abap_unit_assert=>assert_equals( act = lines( <rows> )
                                        exp = 1 ).


    temp19 = sy-tabix.
    READ TABLE <rows> INDEX 1 ASSIGNING <temp18>.
    sy-tabix = temp19.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp18>-value
                                        exp = `B` ).

  ENDMETHOD.

  METHOD table_of_strings.

    FIELD-SYMBOLS <row> TYPE string.

    DATA temp20 TYPE string_table.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA lt_column TYPE z2ui5_cl_cgui_select=>ty_t_column.
    FIELD-SYMBOLS <temp22> LIKE LINE OF lt_column.
    DATA temp23 LIKE sy-tabix.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    CLEAR temp20.
    INSERT `one` INTO TABLE temp20.
    INSERT `two` INTO TABLE temp20.

    lo_popup = z2ui5_cl_cgui_select=>factory( temp20 ).
    run( popup = lo_popup
         init  = abap_true ).

    lt_column = lo_popup->get_columns( ).


    temp23 = sy-tabix.
    READ TABLE lt_column INDEX 1 ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp22>-name
                                        exp = `TAB_LINE` ).
    lo_popup->select_row( 2 ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm ).


    ls_result = lo_popup->result( ).
    ASSIGN ls_result-row->* TO <row>.
    cl_abap_unit_assert=>assert_equals( act = <row>
                                        exp = `two` ).

  ENDMETHOD.

  METHOD cancel_leaves.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    lo_popup = z2ui5_cl_cgui_select=>factory( tab          = mt_row
                                                    event_cancel = `CANCELLED` ).
    run( popup = lo_popup
         init  = abap_true ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-cancel ).

    cl_abap_unit_assert=>assert_false( lo_popup->result( )-confirmed ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_leave_event
                                        exp = `CANCELLED` ).

  ENDMETHOD.

  METHOD window_more_rows.

    FIELD-SYMBOLS <view> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE string.
    DATA lt_value   TYPE string_table.
    DATA ls_request TYPE z2ui5_if_client=>ty_s_window_request.
      DATA temp24 LIKE LINE OF lt_value.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA temp25 TYPE string_table.
    DATA temp5 LIKE LINE OF temp25.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.

    DO z2ui5_cl_cgui_select=>cv_window + 50 TIMES.

      temp24 = |V{ sy-index }|.
      INSERT temp24 INTO TABLE lt_value.
    ENDDO.

    lo_popup = z2ui5_cl_cgui_select=>factory( lt_value ).
    run( popup = lo_popup
         init  = abap_true ).

    " the first window, and the length of the whole list
    ASSIGN lo_popup->mr_view->* TO <view>.
    cl_abap_unit_assert=>assert_equals( act = lines( <view> )
                                        exp = z2ui5_cl_cgui_select=>cv_window ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mv_total
                                        exp = z2ui5_cl_cgui_select=>cv_window + 50 ).

    " the dialog grows: the next rows are appended to the ones it holds
    CLEAR ls_request.
    ls_request-path = `/MR_VIEW/*`.
    ls_request-reason = z2ui5_if_client=>cs_window_reason-more.
    ls_request-skip = z2ui5_cl_cgui_select=>cv_window.
    ls_request-top = z2ui5_cl_cgui_select=>cv_window.
    GET REFERENCE OF ls_request INTO mo_client->mr_event_data.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-rows ).
    cl_abap_unit_assert=>assert_equals( act = lines( <view> )
                                        exp = z2ui5_cl_cgui_select=>cv_window + 50 ).

    " a row of the second window is the row the dialog shows

    CLEAR temp25.

    temp5 = |/MR_VIEW/*/{ z2ui5_cl_cgui_select=>cv_window + 9 }|.
    INSERT temp5 INTO TABLE temp25.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm
         args  = temp25 ).

    ls_result = lo_popup->result( ).
    ASSIGN ls_result-row->* TO <row>.
    cl_abap_unit_assert=>assert_equals( act = <row>
                                        exp = |V{ z2ui5_cl_cgui_select=>cv_window + 10 }| ).

  ENDMETHOD.

ENDCLASS.
