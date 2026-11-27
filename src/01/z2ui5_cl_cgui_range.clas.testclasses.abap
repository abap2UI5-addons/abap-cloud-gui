" the client as the popup sees it - events in, popup and navigation out
CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

    DATA mv_init  TYPE abap_bool.
    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.
    DATA mv_popup TYPE string.
    DATA mv_left  TYPE abap_bool.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.

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


CLASS ltcl_test DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_range DEFINITION LOCAL FRIENDS ltcl_test.

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
    METHODS numbers_in_user_format FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD numbers_in_user_format.

    DATA lv_amount TYPE p LENGTH 8 DECIMALS 2.

    " a German user types 1,5 and 1.234,50; a value without the decimal
    " character - an internal one such as 1.500 - is taken as it is
    cl_abap_unit_assert=>assert_equals( exp = `1.5`
                                        act = z2ui5_cl_cgui_range=>number_text( val     = `1,5`
                                                                                cell    = lv_amount
                                                                                decimal = `,`
                                                                                group   = `.` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1234.50`
                                        act = z2ui5_cl_cgui_range=>number_text( val     = `1.234,50`
                                                                                cell    = lv_amount
                                                                                decimal = `,`
                                                                                group   = `.` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1.500`
                                        act = z2ui5_cl_cgui_range=>number_text( val     = `1.500`
                                                                                cell    = lv_amount
                                                                                decimal = `,`
                                                                                group   = `.` ) ).
    " an English one 1,234.50; a text field keeps its commas
    cl_abap_unit_assert=>assert_equals( exp = `1234.50`
                                        act = z2ui5_cl_cgui_range=>number_text( val     = `1,234.50`
                                                                                cell    = lv_amount
                                                                                decimal = `.`
                                                                                group   = `,` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `a,b`
                                        act = z2ui5_cl_cgui_range=>number_text( val     = `a,b`
                                                                                cell    = `text`
                                                                                decimal = `,`
                                                                                group   = `.` ) ).

  ENDMETHOD.

  METHOD setup.

    mo_client = NEW #( ).

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

    lt_range = VALUE #( ( sign = `I` option = `BT` low = `A` high = `C` )
                        ( sign = `E` option = `EQ` low = `B` ) ).

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = z2ui5_cl_cgui_range=>rows_from_range( lt_range )
                                        IMPORTING error = DATA(lv_error)
                                        CHANGING  range = lt_back ).

    cl_abap_unit_assert=>assert_initial( lv_error ).
    cl_abap_unit_assert=>assert_equals( act = lt_back
                                        exp = lt_range ).

  ENDMETHOD.

  METHOD patterns_and_empty_lines.

    DATA lt_range TYPE RANGE OF ty_c4.

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = VALUE #( ( sign = `I` option = `EQ` low = `ab*` )
                                                                   ( sign = `E` option = `CP` low = `xy` )
                                                                   ( sign = `I` option = `EQ` )
                                                                   ( sign = `I` option = `BT` low = `k` ) )
                                                  upper = abap_true
                                        IMPORTING error = DATA(lv_error)
                                        CHANGING  range = lt_range ).

    cl_abap_unit_assert=>assert_initial( lv_error ).
    cl_abap_unit_assert=>assert_equals( act = lt_range
                                        exp = VALUE ty_r_c4( ( sign = `I` option = `CP` low = `AB*` )
                                                         ( sign = `E` option = `EQ` low = `XY` )
                                                         ( sign = `I` option = `EQ` low = `K` ) ) ).

  ENDMETHOD.

  METHOD invalid_value_keeps_range.

    DATA lt_range TYPE RANGE OF i.

    lt_range = VALUE #( ( sign = `I` option = `EQ` low = 7 ) ).
    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = VALUE #( ( sign = `I` option = `EQ` low = `5` )
                                                                   ( sign = `I` option = `EQ` low = `abc` ) )
                                        IMPORTING error = DATA(lv_error)
                                        CHANGING  range = lt_range ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_error
                                         exp = `*2*` ).
    cl_abap_unit_assert=>assert_equals( act = lt_range[ 1 ]-low
                                        exp = 7 ).

  ENDMETHOD.

  METHOD lower_above_upper.

    DATA lt_range TYPE RANGE OF i.

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = VALUE #( ( sign = `I` option = `BT` low = `9` high = `3` ) )
                                        IMPORTING error = DATA(lv_error)
                                        CHANGING  range = lt_range ).

    cl_abap_unit_assert=>assert_not_initial( lv_error ).
    cl_abap_unit_assert=>assert_initial( lt_range ).

  ENDMETHOD.

  METHOD initial_date_is_empty.

    DATA lt_range TYPE RANGE OF d.

    lt_range = VALUE #( ( sign = `I` option = `BT` low = `00000000` high = `20261231` ) ).
    DATA(lt_row) = z2ui5_cl_cgui_range=>rows_from_range( range   = lt_range
                                                         control = z2ui5_cl_cgui_range=>cs_control-date ).

    cl_abap_unit_assert=>assert_initial( lt_row[ 1 ]-low ).
    cl_abap_unit_assert=>assert_equals( act = lt_row[ 1 ]-high
                                        exp = `20261231` ).

  ENDMETHOD.

  METHOD paste_from_clipboard.

    DATA(lt_row) = z2ui5_cl_cgui_range=>rows_from_text( |A\r\n  B \tC;D*\n\n| ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_row )
                                        exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = lt_row[ 2 ]-low
                                        exp = `B` ).
    cl_abap_unit_assert=>assert_equals( act = lt_row[ 4 ]-option
                                        exp = `CP` ).

  ENDMETHOD.

  METHOD f4_values_into_rows.

    DATA(lt_row) = VALUE z2ui5_cl_cgui_range=>ty_t_row( ( key = `1` sign = `I` option = `BT` low = `A` )
                                                        ( key = `2` sign = `I` option = `EQ` ) ).

    z2ui5_cl_cgui_range=>row_set_value( EXPORTING row_key = `1`
                                                  part    = `high`
                                                  value   = `F`
                                        CHANGING  rows    = lt_row ).
    z2ui5_cl_cgui_range=>rows_add_values( EXPORTING values = VALUE #( ( `X` ) ( `Y` ) ( `X` ) )
                                          CHANGING  rows   = lt_row ).

    cl_abap_unit_assert=>assert_equals( act = lt_row[ 1 ]-high
                                        exp = `F` ).
    cl_abap_unit_assert=>assert_equals( act = lt_row[ 2 ]-low
                                        exp = `X` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_row )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD popup_view.

    DATA lt_range TYPE RANGE OF ty_c4.

    lt_range = VALUE #( ( sign = `E` option = `EQ` low = `B` ) ).
    DATA(lo_popup) = z2ui5_cl_cgui_range=>factory( range   = lt_range
                                                   setting = VALUE #( title      = `Code`
                                                                      value_help = abap_true ) ).
    run( popup = lo_popup
         init  = abap_true ).

    DATA(lv_popup) = mo_client->mv_popup.
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*title="Code"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*selectedKey="{SIGN}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*valueHelpRequest="EVENT:CGUI_RANGE_F4"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_popup
                                         exp = `*EVENT:CGUI_RANGE_F4_MULTI*` ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mt_row[ 1 ]-sign
                                        exp = `E` ).

  ENDMETHOD.

  METHOD popup_add_delete_ok.

    DATA(lo_popup) = z2ui5_cl_cgui_range=>factory( ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 1 ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-add ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 2 ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-delete
         args  = VALUE #( ( lo_popup->mt_row[ 1 ]-key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 1 ).

    lo_popup->mt_row[ 1 ]-sign = `E`.
    lo_popup->mt_row[ 1 ]-low  = `Z`.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-ok ).

    DATA(ls_result) = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_true( ls_result-confirmed ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-rows[ 1 ]-sign
                                        exp = `E` ).

  ENDMETHOD.

  METHOD popup_f4_leaves.

    DATA(lo_popup) = z2ui5_cl_cgui_range=>factory( setting = VALUE #( value_help = abap_true ) ).
    run( popup = lo_popup
         init  = abap_true ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_range=>cs_event-f4
         args  = VALUE #( ( `1` ) ( `low` ) ) ).

    DATA(ls_result) = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_false( ls_result-confirmed ).
    cl_abap_unit_assert=>assert_true( ls_result-f4 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-f4_key
                                        exp = `1` ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-f4_part
                                        exp = `LOW` ).

  ENDMETHOD.

  METHOD popup_paste.

    DATA(lo_popup) = z2ui5_cl_cgui_range=>factory( ).
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
