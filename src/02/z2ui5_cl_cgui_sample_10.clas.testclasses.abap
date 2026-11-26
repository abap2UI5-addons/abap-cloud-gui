CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

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

  METHOD z2ui5_if_client~check_on_init.

    result = mv_init.

  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_navigated.

    result = mv_navigated.

  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_event.

    result = xsdbool( mv_init = abap_false AND mv_navigated = abap_false ).

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

    result = |EVENT:{ val }{ COND #( WHEN t_arg IS NOT INITIAL THEN |:{ concat_lines_of( table = t_arg sep = `,` ) }| ) }|.

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

    INSERT |{ val }:{ concat_lines_of( table = t_arg sep = `|` ) }| INTO TABLE mt_action.

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

    mo_app = NEW #( ).
    mo_client = NEW #( ).
    mo_client->mo_app = mo_app.

  ENDMETHOD.

  METHOD event.

    mo_client->mv_event = name.
    mo_client->mt_arg = args.
    mo_app->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD pick.

    DATA(lo_select) = CAST z2ui5_cl_cgui_select( mo_client->mo_called ).
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.
    mo_client->mt_arg = VALUE #( ( |/XX/MR_VIEW/{ index - 1 }| ) ).
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_app->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD network_flow.

    " the selection screen - F4 on from and to of the airline
    mo_app->s_carrid = VALUE #( ( sign = `I` option = `EQ` low = `AA` ) ).
    mo_client->mv_init = abap_true.
    mo_app->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_view
                                         exp = `*EVENT:CGUI_VALUE_REQUEST:S_CARRID,HIGH*` ).

    " F4 on the upper limit: the own hit list, LH (the third) picked
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = VALUE #( ( `S_CARRID` ) ( `HIGH` ) ) ).
    TRY.
        cl_abap_unit_assert=>assert_bound( CAST z2ui5_cl_cgui_select( mo_client->mo_called ) ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.
    pick( 3 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->s_carrid )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->s_carrid[ 1 ]-option
                                        exp = `BT` ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->s_carrid[ 1 ]-high
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
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = VALUE #( ( `2` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_cgui_tree_view )
                                        exp = 6 ).
    DATA(lv_flight) = mo_app->mt_cgui_tree_view[ 3 ]-key.

    " the tick sums up at once: 385 - 300 free
    mo_app->mt_cgui_tree_view[ 3 ]-checked = abap_true.
    event( name = z2ui5_cl_cgui_tree=>cs_event-checkbox
           args = VALUE #( ( |{ lv_flight }| ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->mv_free
                                        exp = 85 ).
    event( `FREE` ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->mv_free
                                        exp = 85 ).

    " a tick on the airline AA: the loaded flight of 0064 follows when it
    " is opened - 85 + 0
    mo_app->mt_cgui_tree_view[ 1 ]-checked = abap_true.
    event( name = z2ui5_cl_cgui_tree=>cs_event-checkbox
           args = VALUE #( ( `1` ) ) ).
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = VALUE #( ( `3` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_app->mt_cgui_tree_view )
                                        exp = 7 ).
    cl_abap_unit_assert=>assert_equals( act = REDUCE i( INIT n = 0
                                                        FOR ls_row IN mo_app->mt_cgui_tree_view
                                                        WHERE ( checked = abap_true )
                                                        NEXT n = n + 1 )
                                        exp = 5 ).

    " a click on the flight - its details, Back to the tree
    event( name = z2ui5_cl_cgui_tree=>cs_event-node
           args = VALUE #( ( |{ lv_flight }| ) ) ).
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
    event( name = z2ui5_cl_cgui_alv=>cs_event-f4
           args = VALUE #( ( `/XX/MT_PLAN/0` ) ( `CARRID` ) ) ).
    TRY.
        cl_abap_unit_assert=>assert_bound( CAST z2ui5_cl_cgui_select( mo_client->mo_called ) ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.
    pick( 5 ).
    cl_abap_unit_assert=>assert_equals( act = mo_app->mt_plan[ 1 ]-carrid
                                        exp = `UA` ).

  ENDMETHOD.

ENDCLASS.
