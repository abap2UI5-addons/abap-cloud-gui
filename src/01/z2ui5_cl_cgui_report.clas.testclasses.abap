CLASS ltcl_test DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_report DEFINITION LOCAL FRIENDS ltcl_test.

" a variant store of a customer - in memory, plugged in with
" set_variant_store( ); it travels in the draft with the report
CLASS ltcl_variant_store DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_variant_store.
    DATA mt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
ENDCLASS.

" a layout store of a customer - in memory, plugged in with
" set_layout_store( ); the tests keep the default store, the table
" Z2UI5_CGUI_LAY, out of the way with it
CLASS ltcl_layout_store DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_layout_store.
    DATA mt_layout TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
ENDCLASS.

CLASS ltcl_layout_store IMPLEMENTATION.
  METHOD z2ui5_if_cgui_layout_store~load.
    result = mt_layout.
  ENDMETHOD.
  METHOD z2ui5_if_cgui_layout_store~save.
    IF layout-is_default = abap_true.
      LOOP AT mt_layout REFERENCE INTO DATA(lr_layout).
        lr_layout->is_default = abap_false.
      ENDLOOP.
    ENDIF.
    DELETE mt_layout WHERE name = layout-name.
    INSERT layout INTO TABLE mt_layout.
  ENDMETHOD.
  METHOD z2ui5_if_cgui_layout_store~delete.
    DELETE mt_layout WHERE name = name.
  ENDMETHOD.
  METHOD z2ui5_if_cgui_layout_store~check_sharing.
    result = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_variant_store IMPLEMENTATION.
  METHOD z2ui5_if_cgui_variant_store~load.
    result = mt_variant.
  ENDMETHOD.
  METHOD z2ui5_if_cgui_variant_store~save.
    DELETE mt_variant WHERE name = variant-name.
    INSERT variant INTO TABLE mt_variant.
  ENDMETHOD.
  METHOD z2ui5_if_cgui_variant_store~delete.
    DELETE mt_variant WHERE name = name.
  ENDMETHOD.
  METHOD z2ui5_if_cgui_variant_store~check_sharing.
    result = abap_false.
  ENDMETHOD.
ENDCLASS.

" a report as the tests drive it - every kind of field, a list or an ALV
CLASS ltcl_report DEFINITION INHERITING FROM z2ui5_cl_cgui_report FINAL.

  PUBLIC SECTION.
    TYPES ty_c4 TYPE c LENGTH 4.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_pick,
        value TYPE c LENGTH 4,
      END OF ty_s_pick.
    TYPES ty_t_pick TYPE STANDARD TABLE OF ty_s_pick WITH EMPTY KEY.

    DATA p_carrid    TYPE c LENGTH 3.
    DATA p_text      TYPE c LENGTH 20.
    DATA p_hidden    TYPE c LENGTH 1.
    DATA s_date      TYPE RANGE OF d.
    DATA s_code      TYPE RANGE OF ty_c4.
    DATA mt_row      TYPE ty_t_row.
    DATA mv_alv      TYPE abap_bool.
    DATA mv_tree     TYPE abap_bool.

    DATA mv_end      TYPE abap_bool.
    DATA mv_secret   TYPE string.
    DATA mv_lsel_row TYPE i.
    DATA mv_ucomm    TYPE string.
    DATA p_check     TYPE xsdboolean.
    DATA mv_block    TYPE string.
    DATA mv_window   TYPE abap_bool.
    DATA mv_exit     TYPE string.
    DATA mv_exit_err TYPE abap_bool.

  PROTECTED SECTION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS end_of_selection REDEFINITION.
    METHODS top_of_page REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.
    METHODS at_selection_screen_on_block REDEFINITION.
    METHODS end_of_page REDEFINITION.
    METHODS at_selection_screen_on_exit REDEFINITION.
    METHODS at_value_request REDEFINITION.
    METHODS at_alv_value_request REDEFINITION.
    METHODS at_tree_node REDEFINITION.

ENDCLASS.


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
    DATA mo_report TYPE REF TO ltcl_report.
    DATA mo_cut    TYPE REF TO z2ui5_cl_cgui_report.
    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS init.

    METHODS event
      IMPORTING
        name TYPE string
        args TYPE string_table OPTIONAL.

    METHODS obligatory_stops_run FOR TESTING.
    METHODS execute_shows_list FOR TESTING.
    METHODS upper_and_lower_case FOR TESTING.
    METHODS select_option_buffer FOR TESTING.
    METHODS select_option_complex FOR TESTING.
    METHODS secondary_list_and_back FOR TESTING.
    METHODS alv_box_copy_selection FOR TESTING.
    METHODS url_values_screen_only FOR TESTING.
    METHODS url_skip_screen FOR TESTING.
    METHODS url_range FOR TESTING.
    METHODS variant_screen_only FOR TESTING.
    METHODS events_screen_only FOR TESTING.
    METHODS submit_starts_report FOR TESTING.
    METHODS link_holds_values FOR TESTING.
    METHODS parameter_id FOR TESTING.
    METHODS shortcuts_registered FOR TESTING.
    METHODS f8_on_output_ignored FOR TESTING.
    METHODS run_in_background FOR TESTING.
    METHODS range_popup_keeps_exclude FOR TESTING.
    METHODS range_f4_returns_to_popup FOR TESTING.
    METHODS f4_keeps_other_lines FOR TESTING.
    METHODS popups_of_the_project FOR TESTING.
    METHODS alv_layout_default FOR TESTING.
    METHODS alv_layout_without_store FOR TESTING.

    METHODS value_check_and_block FOR TESTING.
    METHODS footer_print_function_key FOR TESTING.
    METHODS alv_paging_maps_rows FOR TESTING.
    METHODS alv_filter_by_popup FOR TESTING.
    METHODS window_shows_dialog FOR TESTING.
    METHODS exit_command FOR TESTING.
    METHODS write_takes_format FOR TESTING.
    METHODS cursor_and_lisel FOR TESTING.
    METHODS selscreen_status_and_cursor FOR TESTING.
    METHODS alv_search_and_details FOR TESTING.
    METHODS f4_on_high FOR TESTING.
    METHODS f4_in_alv_cell FOR TESTING.
    METHODS tree_expand_and_node FOR TESTING.
    METHODS draft_serializable FOR TESTING.
    METHODS draft_references FOR TESTING.
    METHODS serialize
      IMPORTING
        step TYPE string.

    " an app through the draft of abap2UI5 and back
    METHODS roundtrip
      IMPORTING
        app           TYPE REF TO z2ui5_if_app
        step          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_if_app.

    "! the select popup the report opened, left with the row at index
    METHODS select_popup_pick
      IMPORTING
        index TYPE i.

    TYPES:
      BEGIN OF ty_s_pick,
        value TYPE c LENGTH 4,
      END OF ty_s_pick.
    TYPES ty_t_pick TYPE STANDARD TABLE OF ty_s_pick WITH EMPTY KEY.

    "! the multiple selection the report opened, left with event
    METHODS range_popup_leave
      IMPORTING
        event         TYPE string
        args          TYPE string_table OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_range.

ENDCLASS.


CLASS ltcl_report IMPLEMENTATION.

  METHOD selection_screen.

    screen->block_begin( title = `Airline`
                         name  = `B1`
        )->parameter( val        = p_carrid
                      text       = `Airline`
                      obligatory = abap_true
        )->block_end(
        )->parameter( val         = p_check
                      text        = `Check`
                      value_check = abap_true
        )->function_key( number = 1
                         text   = `Refresh`
        )->parameter( val        = p_text
                      text       = `Text`
                      lower_case = abap_true
        )->parameter( val        = p_hidden
                      no_display = abap_true
        )->select_option( val  = s_date
                          text = `Date`
        )->select_option( val  = s_code
                          text = `Code` ).

  ENDMETHOD.

  METHOD start_of_selection.

    IF mv_tree = abap_true.
      DATA(lo_tree) = tree( ).
      DATA(lv_lh) = lo_tree->add_node( text  = `LH`
                                       data  = VALUE ty_s_row( carrid = `LH` seats = 3 )
                                       value = `LH` ).
      lo_tree->add_node( parent = lv_lh
                         text   = `0400`
                         data   = VALUE ty_s_row( carrid = `LH` seats = 1 )
                         value  = `LH-0400` ).
      RETURN.
    ENDIF.

    IF mv_alv = abap_true.
      mt_row = VALUE #( ( carrid = `LH` seats = 1 )
                        ( carrid = `AA` seats = 2 )
                        ( carrid = `UA` seats = 3 ) ).
      alv( mt_row )->set_selection_mode( ).
      RETURN.
    ENDIF.

    write( val     = `row1`
           hotspot = abap_true
           hide    = `H1` )->new_line( ).

  ENDMETHOD.

  METHOD end_of_selection.

    mv_end = abap_true.

  ENDMETHOD.

  METHOD top_of_page.

    write( `HEADER` ).

  ENDMETHOD.

  METHOD at_line_selection.

    mv_lsel_row = row.
    IF mv_window = abap_true.
      window( title   = `Detail`
              columns = 50
              lines   = 10 ).
    ENDIF.
    write( |Detail { hide }| ).

  ENDMETHOD.

  METHOD at_user_command.

    mv_ucomm = ucomm.

  ENDMETHOD.

  METHOD at_tree_node.

    write( |Node { value } { key }| ).

  ENDMETHOD.

  METHOD at_value_request.

    " F4 on the upper limit of the code - a hit list of its own
    IF field = `S_CODE` AND value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high.
      value_help_popup( tab = VALUE ty_t_pick( ( value = `ZZ` ) )
                        col = `VALUE` ).
      RETURN.
    ENDIF.
    super->at_value_request( field ).

  ENDMETHOD.

  METHOD at_alv_value_request.

    IF column = `CARRID`.
      value_help_popup( tab = VALUE ty_t_pick( ( value = `QF` ) ( value = `SQ` ) )
                        col = `VALUE` ).
      RETURN.
    ENDIF.
    super->at_alv_value_request( row    = row
                                 column = column ).

  ENDMETHOD.

  METHOD at_selection_screen_on_exit.

    mv_exit = ucomm.
    IF mv_exit_err = abap_true.
      message( text = `Not now`
               type = `E` ).
    ENDIF.

  ENDMETHOD.

  METHOD at_selection_screen_on_block.

    mv_block = block.

  ENDMETHOD.

  METHOD end_of_page.

    write( |FOOT { z2ui5_cl_cgui_list=>cv_page }| ).

  ENDMETHOD.

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

    mo_report = NEW #( ).
    mo_cut = mo_report.
    mo_client = NEW #( ).
    mo_client->mo_app = mo_report.

  ENDMETHOD.

  METHOD init.

    IF mo_cut->mo_cgui_lay_store IS NOT BOUND AND mo_cut->mv_cgui_lay_none = abap_false.
      mo_cut->set_layout_store( NEW ltcl_layout_store( ) ).
    ENDIF.
    mo_client->mv_init = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

  ENDMETHOD.

  METHOD event.

    mo_client->mv_event = name.
    mo_client->mt_arg = args.
    mo_cut->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD obligatory_stops_run.

    init( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_cut->mt_cgui_log[ type = `E` field = `P_CARRID` ] ) ) ).
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).

  ENDMETHOD.

  METHOD execute_shows_list.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).
    DATA(lt_item) = mo_cut->mo_cgui_list->get_items( ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 1 ]-text
                                        exp = `HEADER` ).
    cl_abap_unit_assert=>assert_true( lt_item[ 1 ]-header ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `row1` ) ).

  ENDMETHOD.

  METHOD upper_and_lower_case.

    init( ).
    mo_report->p_carrid = `lh`.
    mo_report->p_text = `Hello`.
    event( `SOME_COMMAND` ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_text
                                        exp = `Hello` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `SOME_COMMAND` ).

  ENDMETHOD.

  METHOD select_option_buffer.

    init( ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_report->mt_cgui_so[ name = `S_DATE` ] ) ) ).

    mo_report->mt_cgui_so[ name = `S_DATE` ]-low  = `20260101`.
    mo_report->mt_cgui_so[ name = `S_DATE` ]-high = `20260131`.
    mo_report->mt_cgui_so[ name = `S_CODE` ]-low  = `ab*`.
    event( `SOME_COMMAND` ).

    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_date )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_date[ 1 ]-option
                                        exp = `BT` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_date[ 1 ]-high
                                        exp = CONV d( `20260131` ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 1 ]-option
                                        exp = `CP` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 1 ]-low
                                        exp = `AB*` ).
    " the inputs are bound to the buffer
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `{/MT_CGUI_SO/` ) ).

  ENDMETHOD.

  METHOD select_option_complex.

    mo_report->s_code = VALUE #( ( sign = `I` option = `EQ` low = `A` )
                                 ( sign = `E` option = `EQ` low = `B` ) ).
    init( ).

    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( mo_report->mt_cgui_so[ name = `S_CODE` ] ) ) ).
    event( `SOME_COMMAND` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD secondary_list_and_back.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = VALUE #( ( `2` ) ( `H1` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `Detail H1` ) ).

    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `row1` ) ).

    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).

  ENDMETHOD.

  METHOD alv_box_copy_selection.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <box> TYPE any.

    mo_report->mv_alv = abap_true.
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_bound( mo_report->mr_cgui_alv_box ).
    ASSIGN mo_report->mr_cgui_alv_box->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = 3 ).
    ASSIGN COMPONENT z2ui5_cl_cgui_alv=>cv_box_field OF STRUCTURE <tab>[ 2 ] TO <box>.
    <box> = abap_true.

    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_row( ( 2 ) ) ).

    " the selection survives the next render, select all marks every row
    event( `SOME_COMMAND` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_row( ( 2 ) ) ).
    event( z2ui5_cl_cgui_alv=>cs_event-select_all ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->get_selected_rows( ) )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD url_values_screen_only.

    mo_client->ms_get-s_config-search = `?app_start=x&p_carrid=AA&mv_secret=abc&p_hidden=Z&s_date=20260101..20260131`.
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `AA` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_secret ).
    cl_abap_unit_assert=>assert_initial( mo_report->p_hidden ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_date[ 1 ]-option
                                        exp = `BT` ).

  ENDMETHOD.

  METHOD url_skip_screen.

    mo_client->ms_get-s_config-search = `?p_carrid=LH&skip_screen=X`.
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD url_range.

    DATA(lt_value) = mo_cut->url_range( name = `S_CODE`
                                        val  = `A,B..C,!D,>=E,F*` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_value )
                                        exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lt_value[ 2 ]-option
                                        exp = `BT` ).
    cl_abap_unit_assert=>assert_equals( act = lt_value[ 2 ]-high
                                        exp = `C` ).
    cl_abap_unit_assert=>assert_equals( act = lt_value[ 3 ]-sign
                                        exp = `E` ).
    cl_abap_unit_assert=>assert_equals( act = lt_value[ 4 ]-option
                                        exp = `GE` ).
    cl_abap_unit_assert=>assert_equals( act = lt_value[ 5 ]-option
                                        exp = `CP` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->url_from_range( lt_value )
                                        exp = `A,B..C,!D,>=E,F*` ).

  ENDMETHOD.

  METHOD variant_screen_only.

    " a variant names the fields of the screen - one from the browser's
    " storage may name anything, and sets no other attribute
    DATA(lo_store) = NEW ltcl_variant_store( ).
    lo_store->mt_variant = VALUE #( ( name   = `V1`
                                      values = VALUE #( ( name = `P_CARRID`  kind = `P` low = `LH` )
                                                        ( name = `mv_secret` kind = `P` low = `abc` )
                                                        ( name = `MV_UCOMM`  kind = `P` low = `X` ) ) ) ).
    mo_cut->set_variant_store( lo_store ).
    mo_cut->set_variant( `V1` ).
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_secret ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_ucomm ).

  ENDMETHOD.

  METHOD events_screen_only.

    " F4 and the multiple selection name their field in the argument - an
    " attribute that is no field of the screen opens nothing
    init( ).
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = VALUE #( ( `MT_ROW` ) ) ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = VALUE #( ( `MV_SECRET` ) ) ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " a field of the screen still does
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = VALUE #( ( `s_code` ) ) ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD submit_starts_report.

    init( ).
    mo_cut->submit( report = `LTCL_REPORT`
                    values = VALUE #( ( name = `P_CARRID` kind = `P` low = `UA` ) ) ).

    DATA(lo_called) = CAST z2ui5_cl_cgui_report( mo_client->mo_called ).
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_called ).
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_skip ).
    cl_abap_unit_assert=>assert_equals( act = lo_called->mt_cgui_submit[ 1 ]-low
                                        exp = `UA` ).

    " started, it runs without its selection screen
    DATA(lo_client) = NEW ltcl_client( ).
    lo_client->mo_app = lo_called.
    lo_client->mv_init = abap_true.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_called->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_equals( act = CAST ltcl_report( lo_called )->p_carrid
                                        exp = `UA` ).

    " Back on its output returns to the caller
    lo_client->mv_init = abap_false.
    lo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-back.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_true( lo_client->mv_left ).

  ENDMETHOD.

  METHOD link_holds_values.

    mo_client->ms_get-s_config-origin = `https://host`.
    mo_client->ms_get-s_config-pathname = `/sap/bc/z2ui5`.
    mo_client->ms_get-s_config-search = `?sap-client=100&app_start=ltcl_report`.
    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->p_hidden = `X`.
    mo_report->s_date = VALUE #( ( sign = `I` option = `BT` low = `20260101` high = `20260131` ) ).

    DATA(lv_link) = mo_cut->get_link( abap_true ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_link
                                         exp = `https://host/sap/bc/z2ui5?sap-client=100&app_start=ltcl_report*` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_link CS `p_carrid=LH` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_link CS `s_date=20260101..20260131` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_link CS `skip_screen=X` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_link CS `p_hidden` ) ).

  ENDMETHOD.

  METHOD parameter_id.

    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_TEST`
                              value = `LH` ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `zcgui_test` )
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_report->mv_cgui_spa CS `ZCGUI_TEST=LH` ) ).

  ENDMETHOD.

  METHOD shortcuts_registered.

    init( ).

    DATA(lv_f8) = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:F8\|CGUI_EXECUTE\|MAIN|.
    DATA(lv_f3) = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:F3\|CGUI_BACK\|MAIN|.
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_client->mt_action[ table_line = lv_f8 ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_client->mt_action[ table_line = lv_f3 ] ) ) ).

  ENDMETHOD.

  METHOD f8_on_output_ignored.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_report->mv_end = abap_false.

    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD run_in_background.

    " no client at all - the run of the background program
    mo_report->cgui_run_in_background(
      EXPORTING values   = VALUE #( ( name = `P_CARRID` kind = `P` low = `LH` ) )
      IMPORTING list     = DATA(lo_list)
                messages = DATA(lt_msg) ).

    cl_abap_unit_assert=>assert_bound( lo_list ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).
    DATA(lt_text) = lo_list->to_text( ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 1 ]
                                        exp = `HEADER` ).
    cl_abap_unit_assert=>assert_initial( lt_msg ).

    " a required field missing - no output, the error as message
    DATA(lo_empty) = NEW ltcl_report( ).
    lo_empty->cgui_run_in_background( EXPORTING values   = VALUE #( )
                                      IMPORTING list     = DATA(lo_none)
                                                messages = DATA(lt_error) ).
    cl_abap_unit_assert=>assert_not_bound( lo_none ).
    cl_abap_unit_assert=>assert_equals( act = lt_error[ 1 ]-type
                                        exp = `E` ).

  ENDMETHOD.

  METHOD range_popup_leave.

    result ?= mo_client->mo_called.
    mo_client->mv_event = event.
    mo_client->mt_arg = args.
    result->z2ui5_if_app~main( mo_client ).

    " back in the report
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = result.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD range_popup_keeps_exclude.

    mo_report->s_code = VALUE #( ( sign = `I` option = `EQ` low = `A` )
                                 ( sign = `E` option = `EQ` low = `B` ) ).
    init( ).
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = VALUE #( ( `S_CODE` ) ) ).

    DATA(lo_popup) = CAST z2ui5_cl_cgui_range( mo_client->mo_called ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 2 ).
    lo_popup->mt_row[ 2 ]-low = `c`.
    range_popup_leave( z2ui5_cl_cgui_range=>cs_event-ok ).

    " the excluding line stays one - and is in upper case like the field
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 2 ]-sign
                                        exp = `E` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 2 ]-low
                                        exp = `C` ).

  ENDMETHOD.

  METHOD range_f4_returns_to_popup.

    mo_report->s_code = VALUE #( ( sign = `E` option = `EQ` low = `B` ) ).
    init( ).
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = VALUE #( ( `S_CODE` ) ) ).
    DATA(lo_first) = CAST z2ui5_cl_cgui_range( mo_client->mo_called ).

    " F4 on line 1: the code has no value help - the report says so and
    " opens the popup again with the lines as they were
    range_popup_leave( event = z2ui5_cl_cgui_range=>cs_event-f4
                       args  = VALUE #( ( lo_first->mt_row[ 1 ]-key ) ( `LOW` ) ) ).

    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    DATA(lo_again) = CAST z2ui5_cl_cgui_range( mo_client->mo_called ).
    cl_abap_unit_assert=>assert_false( xsdbool( lo_again = lo_first ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_again->mt_row[ 1 ]-sign
                                        exp = `E` ).
    cl_abap_unit_assert=>assert_false( mo_cut->mv_cgui_range_f4 ).
    " the select-option itself is untouched until OK
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 1 ).

  ENDMETHOD.

  METHOD f4_keeps_other_lines.

    DATA lt_pick TYPE ty_t_pick.

    init( ).
    mo_report->s_code = VALUE #( ( sign = `I` option = `BT` low = `A` high = `C` )
                                 ( sign = `I` option = `EQ` low = `Q` )
                                 ( sign = `E` option = `EQ` low = `B` ) ).
    lt_pick = VALUE #( ( value = `X` ) ( value = `Y` ) ).
    DATA(lo_select) = z2ui5_cl_cgui_select=>factory( tab         = lt_pick
                                                     multiselect = abap_true ).
    lo_select->select_row( 1 ).
    lo_select->select_row( 2 ).
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR mo_client->mv_event.
    mo_client->mo_prev = lo_select.

    mo_cut->on_f4_result( field = `S_CODE`
                          col   = `VALUE` ).

    " Q gave way to X and Y - the interval and the exclusion stay
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 4 ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_report->s_code[ option = `BT` low = `A` ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_report->s_code[ sign = `E` low = `B` ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( mo_report->s_code[ low = `Q` ] ) ) ).

  ENDMETHOD.

  METHOD popups_of_the_project.

    " every popup of the runtime is a class of the project
    init( ).
    mo_cut->popup_to_confirm( question = `Sure?`
                              ucomm    = `DO_IT` ).
    TRY.
        cl_abap_unit_assert=>assert_bound( CAST z2ui5_cl_cgui_popup( mo_client->mo_called ) ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_popup` ).
    ENDTRY.

    " OK leaves with the user command
    mo_client->mv_event = `CGUI_POP_OK`.
    mo_client->mo_called->main( mo_client ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    CLEAR mo_client->mv_event.

    mo_report->s_code = VALUE #( ( sign = `I` option = `EQ` low = `A` ) ).
    mo_cut->mv_cgui_value_field = `S_CODE`.
    mo_cut->value_help_popup( tab = VALUE ty_t_pick( ( value = `A` ) ( value = `B` ) )
                              col = `VALUE` ).
    TRY.
        cl_abap_unit_assert=>assert_bound( CAST z2ui5_cl_cgui_select( mo_client->mo_called ) ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.

  ENDMETHOD.

  METHOD alv_layout_default.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `sortProperty="SEATS"` ) ).

    " the layout button opens the dialog - SEATS hidden, saved as default
    event( z2ui5_cl_cgui_alv=>cs_event-layout ).
    DATA(lo_layout) = CAST z2ui5_cl_cgui_layout( mo_client->mo_called ).
    lo_layout->mt_row[ name = `SEATS` ]-visible = abap_false.
    lo_layout->mv_name = `MINE`.
    lo_layout->mv_default = abap_true.
    mo_client->mv_event = z2ui5_cl_cgui_layout=>cs_event-ok.
    lo_layout->z2ui5_if_app~main( mo_client ).
    CLEAR mo_client->mv_event.
    mo_client->mo_prev = lo_layout.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).
    cl_abap_unit_assert=>assert_false( xsdbool( mo_client->mv_view CS `sortProperty="SEATS"` ) ).
    " kept in the layout store, under the attribute the ALV shows
    DATA(lo_store) = CAST ltcl_layout_store( mo_cut->mo_cgui_lay_store ).
    cl_abap_unit_assert=>assert_true( lo_store->mt_layout[ name = `MINE` ]-is_default ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->layout_handle( )
                                        exp = `MT_ROW` ).
    DATA(lt_catalog) = mo_cut->variant_catalog( ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( lt_catalog[ name = `#L#MINE` ] ) ) ).

    " the next run starts with the default layout
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    CLEAR mo_cut->mv_cgui_layout.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).
    cl_abap_unit_assert=>assert_false( xsdbool( mo_client->mv_view CS `sortProperty="SEATS"` ) ).

  ENDMETHOD.

  METHOD alv_layout_without_store.

    " no layout store - the layouts are kept with the selection variants
    mo_cut->set_layout_store( ).
    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    event( z2ui5_cl_cgui_alv=>cs_event-layout ).
    DATA(lo_layout) = CAST z2ui5_cl_cgui_layout( mo_client->mo_called ).

    lo_layout->mt_row[ name = `SEATS` ]-visible = abap_false.
    lo_layout->mv_name = `MINE`.
    lo_layout->mv_default = abap_true.
    mo_client->mv_event = z2ui5_cl_cgui_layout=>cs_event-ok.
    lo_layout->z2ui5_if_app~main( mo_client ).
    CLEAR mo_client->mv_event.
    mo_client->mo_prev = lo_layout.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).
    " kept as a variant - but none the variant popup offers
    DATA(lt_catalog) = mo_cut->variant_catalog( ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_catalog[ name = `#L#MINE` ] ) ) ).

  ENDMETHOD.

  METHOD value_check_and_block.


    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->p_check = `Q`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " VALUE CHECK stops the run at the field - before ON BLOCK
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_cut->mt_cgui_log[ type = `E` field = `P_CHECK` ] ) ) ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_block ).

    mo_report->p_check = `X`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_block
                                        exp = `B1` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD footer_print_function_key.

    init( ).
    " the function key of the selection screen
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `EVENT:FC01` ) ).
    event( `FC01` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `FC01` ).

    mo_report->p_carrid = `LH`.
    mo_cut->set_pf_status( VALUE #( ( name = `SAVE` text = `Save` ) ) ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " END-OF-PAGE with the page number, the PF-STATUS and print
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `FOOT 1` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `EVENT:SAVE` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `EVENT:CGUI_PRINT` ) ).
    DATA(lt_print) = mo_cut->print_lines( ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_print[ table_line = `row1` ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_print[ table_line = `FOOT 1` ] ) ) ).

  ENDMETHOD.

  METHOD alv_paging_maps_rows.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    DATA(lv_rows) = lines( mo_report->mt_row ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_rows >= 2 ) ).

    " one row a page - the page shown is a copy, the title counts all rows
    mo_cut->mo_cgui_alv->set_paging( 1 ).
    event( z2ui5_cl_cgui_alv=>cs_event-page ).
    event( name = z2ui5_cl_cgui_alv=>cs_event-page
           args = VALUE #( ( z2ui5_cl_cgui_alv=>cs_page-next ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mo_cgui_alv->get_page( )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_bound( mo_cut->mr_cgui_alv_page ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS |({ lv_rows })| ) ).

    " a line selection on the page is the second row of the table
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = VALUE #( ( `/XX/MR_CGUI_ALV_PAGE/0` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 2 ).

  ENDMETHOD.

  METHOD alv_filter_by_popup.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the filter button lists the columns - pick the airline
    event( z2ui5_cl_cgui_alv=>cs_event-filter ).
    DATA(lo_select) = CAST z2ui5_cl_cgui_select( mo_client->mo_called ).
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.
    mo_client->mt_arg = VALUE #( ( `/XX/MR_VIEW/0` ) ).
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    " its multiple selection - UA only
    DATA(lo_range) = CAST z2ui5_cl_cgui_range( mo_client->mo_called ).
    lo_range->mt_row = VALUE #( ( key = `1` sign = `I` option = `EQ` low = `UA` ) ).
    range_popup_leave( z2ui5_cl_cgui_range=>cs_event-ok ).

    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mo_cgui_alv->get_filter( ) )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `(1 of 3)` ) ).

    " the one row shown is the third of the table
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = VALUE #( ( `/XX/MR_CGUI_ALV_PAGE/0` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 3 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " select all takes the rows that pass only
    event( z2ui5_cl_cgui_alv=>cs_event-select_all ).
    DATA(lt_selected) = mo_cut->get_selected_rows( ).
    cl_abap_unit_assert=>assert_equals( act = lt_selected
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_row( ( 3 ) ) ).

    event( z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mo_cgui_alv->get_filter( ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `(3)` ) ).

  ENDMETHOD.

  METHOD window_shows_dialog.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_window = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the secondary list in a dialog box, the basic list below as text
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = VALUE #( ( `2` ) ( `H1` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_popup CS `Detail H1` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_popup CS `30rem` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `row1` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( mo_client->mv_view CS `Detail H1` ) ).

    " back closes the box
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).

  ENDMETHOD.

  METHOD exit_command.

    init( ).
    mo_report->mv_exit_err = abap_true.
    mo_cut->mv_cgui_called = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_exit
                                        exp = z2ui5_cl_cgui_report=>cs_ucomm-back ).
    " the error keeps the screen - nothing left
    cl_abap_unit_assert=>assert_false( mo_client->mv_left ).

    mo_report->mv_exit_err = abap_false.
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).

  ENDMETHOD.

  METHOD write_takes_format.

    init( ).
    mo_cut->format( color = z2ui5_cl_cgui_list=>cs_color-positive ).
    mo_cut->write( `a` ).
    mo_cut->write( val   = `b`
                   color = z2ui5_cl_cgui_list=>cs_color-negative ).
    mo_cut->write( val       = CONV d( '20261002' )
                   date_format = z2ui5_cl_cgui_list=>cs_date_format-ddmmyy ).
    DATA(lt_item) = mo_cut->mo_cgui_list->get_items( ).
    " the header line of TOP-OF-PAGE first
    DELETE lt_item WHERE header = abap_true.
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 1 ]-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-positive ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-negative ).
    " as the classic WRITE ... DDMMYY: day, month, year without separators
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 3 ]-text
                                        exp = `021026` ).

  ENDMETHOD.

  METHOD cursor_and_lisel.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    DATA(lt_item) = mo_cut->mo_cgui_list->get_items( ).
    DATA(ls_row) = lt_item[ text = `row1` ].

    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = VALUE #( ( |{ ls_row-line }| ) ( `H1` ) ( |{ ls_row-id }| ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_cursor( )-value
                                        exp = `row1` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_cursor( )-line
                                        exp = ls_row-line ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lisel( )
                                        exp = `row1` ).

  ENDMETHOD.

  METHOD selscreen_status_and_cursor.

    init( ).
    mo_cut->set_selscreen_status( VALUE #( ( z2ui5_cl_cgui_report=>cs_ucomm-variant_save )
                                           ( z2ui5_cl_cgui_report=>cs_ucomm-execute ) ) ).
    mo_cut->set_cursor_field( `p_text` ).
    event( `NOOP` ).
    cl_abap_unit_assert=>assert_false( xsdbool( mo_client->mv_view CS `Save as Variant` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `Get Variant` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( mo_client->mv_view CS z2ui5_cl_cgui_report=>cs_ucomm-execute ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( concat_lines_of( mo_client->mt_action ) CS `cgui_f_p_text` ) ).

    " F8 is switched off as well
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).

  ENDMETHOD.

  METHOD alv_search_and_details.

    FIELD-SYMBOLS <box> TYPE STANDARD TABLE.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the search field: UA in one of the columns
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = VALUE #( ( `ua` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `(1 of 3)` ) ).

    " details without a row selected: a warning; with one: the dialog box
    event( z2ui5_cl_cgui_alv=>cs_event-details ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_cut->mt_cgui_log[ type = `W` ] ) ) ).
    event( z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    ASSIGN mo_cut->mr_cgui_alv_box->* TO <box>.
    mo_cut->mo_cgui_alv->set_selected_rows( EXPORTING rows = VALUE #( ( 3 ) )
                                            CHANGING  tab  = <box> ).
    event( z2ui5_cl_cgui_alv=>cs_event-details ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_popup CS `UA` ) ).
    event( z2ui5_cl_cgui_alv=>cs_event-details_close ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).

  ENDMETHOD.

  METHOD select_popup_pick.

    DATA(lo_select) = CAST z2ui5_cl_cgui_select( mo_client->mo_called ).
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.
    mo_client->mt_arg = VALUE #( ( |/XX/MR_VIEW/{ index - 1 }| ) ).
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD f4_on_high.

    mo_report->s_code = VALUE #( ( sign = `I` option = `EQ` low = `AA` ) ).
    init( ).
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = VALUE #( ( `S_CODE` ) ( `HIGH` ) ) ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    select_popup_pick( 1 ).

    " the first line is an interval up to the value picked
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 1 ]-option
                                        exp = `BT` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 1 ]-low
                                        exp = `AA` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->s_code[ 1 ]-high
                                        exp = `ZZ` ).

  ENDMETHOD.

  METHOD f4_in_alv_cell.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_cut->mo_cgui_alv->set_edit( )->set_column_f4( `CARRID` ).

    " F4 in the airline of the second row - the second value picked
    event( name = z2ui5_cl_cgui_alv=>cs_event-f4
           args = VALUE #( ( `/XX/MR_CGUI_ALV_BOX/1` ) ( `CARRID` ) ) ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    select_popup_pick( 2 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mt_row[ 2 ]-carrid
                                        exp = `SQ` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mt_row[ 1 ]-carrid
                                        exp = `LH` ).

  ENDMETHOD.

  METHOD tree_expand_and_node.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_tree = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `EVENT:CGUI_TREE_TOGGLE` ) ).

    " expand the airline - its connection is shown
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = VALUE #( ( `1` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_tree_view[ 2 ]-text
                                        exp = `0400` ).

    " a tick in the browser reaches the node with the next event
    mo_cut->mo_cgui_tree->set_checkboxes( ).
    mo_cut->mt_cgui_tree_view[ 2 ]-checked = abap_true.
    event( z2ui5_cl_cgui_tree=>cs_event-expand_all ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mo_cgui_tree->get_checked( )
                                        exp = VALUE z2ui5_cl_cgui_tree=>ty_t_key( ( 2 ) ) ).

    " a click on the connection - a secondary list, Back returns to the tree
    event( name = z2ui5_cl_cgui_tree=>cs_event-node
           args = VALUE #( ( `2` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_view CS `Node LH-0400 2` ) ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD serialize.

    " the roundtrip of abap2UI5 between two requests: the app in its
    " container to the draft and back - what is not serializable is dropped
    " there without a word
    DATA(lo_app) = CAST z2ui5_cl_cgui_report( roundtrip( app  = mo_cut
                                                         step = step ) ).

    cl_abap_unit_assert=>assert_equals( act = lo_app->mv_cgui_screen
                                        exp = mo_cut->mv_cgui_screen
                                        msg = |{ step }: screen| ).
    cl_abap_unit_assert=>assert_equals( act = xsdbool( lo_app->mo_cgui_list IS BOUND )
                                        exp = xsdbool( mo_cut->mo_cgui_list IS BOUND )
                                        msg = |{ step }: the list after the roundtrip| ).
    cl_abap_unit_assert=>assert_equals( act = xsdbool( lo_app->mo_cgui_alv IS BOUND )
                                        exp = xsdbool( mo_cut->mo_cgui_alv IS BOUND )
                                        msg = |{ step }: the ALV after the roundtrip| ).
    cl_abap_unit_assert=>assert_equals( act = xsdbool( lo_app->mo_cgui_tree IS BOUND )
                                        exp = xsdbool( mo_cut->mo_cgui_tree IS BOUND )
                                        msg = |{ step }: the tree after the roundtrip| ).
    IF mo_cut->mo_cgui_tree IS BOUND AND lo_app->mo_cgui_tree IS BOUND.
      cl_abap_unit_assert=>assert_equals( act = lines( lo_app->mo_cgui_tree->get_nodes( ) )
                                          exp = lines( mo_cut->mo_cgui_tree->get_nodes( ) )
                                          msg = |{ step }: the nodes of the tree| ).
    ENDIF.

  ENDMETHOD.

  METHOD draft_serializable.

    " the list
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    serialize( `list` ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " the ALV
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    serialize( `ALV` ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " the tree, a node opened
    mo_report->mv_alv = abap_false.
    mo_report->mv_tree = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = VALUE #( ( `1` ) ) ).
    serialize( `tree` ).

  ENDMETHOD.

  METHOD roundtrip.

    " the roundtrip of abap2UI5 between two requests: the app in its
    " container to the draft and back - what is not serializable is dropped
    " there without a word
    DATA(lo_cont) = NEW z2ui5_cl_ui5_app_cont( ).
    lo_cont->mo_app = app.
    lo_cont->ms_draft-id = `CGUI_UNIT_TEST`.
    TRY.
        DATA(lo_parsed) = z2ui5_cl_ui5_app_cont=>all_xml_parse( lo_cont->all_xml_stringify( ) ).
        " as db_load( ): the data references back from their S-RTTI payloads
        NEW z2ui5_cl_ui5_srv_model( attri = lo_parsed->mt_attri
                                    app   = lo_parsed->mo_app )->main_attri_db_load( ).
      CATCH cx_root INTO DATA(lx_error).
        cl_abap_unit_assert=>fail( |{ step }: the app cannot be saved - { lx_error->get_text( ) }| ).
    ENDTRY.
    result = CAST #( lo_parsed->mo_app ).

  ENDMETHOD.

  METHOD draft_references.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    " the rows of the ALV - an anonymous copy, its type rebuilt
    init( ).
    " a store of the customer's - it travels in the draft with the report
    mo_cut->set_variant_store( NEW ltcl_variant_store( ) ).

    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    " a public attribute: the ALV keeps its name
    DATA(lo_app) = CAST z2ui5_cl_cgui_report( roundtrip( app  = mo_cut
                                                         step = `ALV of an attribute` ) ).
    DATA(lr_rows) = lo_app->alv_source( ).
    cl_abap_unit_assert=>assert_bound( act = lr_rows
                                       msg = `the rows of the ALV after the roundtrip` ).
    ASSIGN lr_rows->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = lines( mo_report->mt_row )
                                        msg = `the rows of the ALV after the roundtrip` ).

    " any other table: the ALV keeps a copy
    mo_cut->alv( VALUE ltcl_report=>ty_t_row( ( carrid = `LH` seats = 1 )
                                              ( carrid = `AA` seats = 2 )
                                              ( carrid = `UA` seats = 3 ) ) ).
    lo_app = CAST z2ui5_cl_cgui_report( roundtrip( app  = mo_cut
                                                   step = `ALV of a copy` ) ).
    cl_abap_unit_assert=>assert_bound( act = lo_app->mr_cgui_alv
                                       msg = `the copy of the ALV after the roundtrip` ).
    ASSIGN lo_app->mr_cgui_alv->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = 3
                                        msg = `the copy of the ALV after the roundtrip` ).

    " the variant store on the server
    cl_abap_unit_assert=>assert_bound( act = lo_app->mo_cgui_store
                                       msg = `the variant store after the roundtrip` ).

    " the popups of the project with their tables of runtime types
    DATA(lo_select) = CAST z2ui5_cl_cgui_select( roundtrip(
        app  = z2ui5_cl_cgui_select=>factory( tab = VALUE ltcl_report=>ty_t_pick( ( value = `A` ) ( value = `B` ) ) )
        step = `select popup` ) ).
    DATA(ls_result) = lo_select->result( ).
    cl_abap_unit_assert=>assert_bound( act = ls_result-row
                                       msg = `select popup: the result row after the roundtrip` ).
    cl_abap_unit_assert=>assert_bound( act = ls_result-table
                                       msg = `select popup: the result table after the roundtrip` ).

    " the other dialogs - saved without an error, their state kept
    DATA(lo_range) = CAST z2ui5_cl_cgui_range( roundtrip(
        app  = z2ui5_cl_cgui_range=>factory( range = mo_report->s_code )
        step = `range popup` ) ).
    cl_abap_unit_assert=>assert_bound( lo_range ).
    roundtrip( app  = z2ui5_cl_cgui_layout=>factory( layout = VALUE #( ) )
               step = `layout popup` ).
    roundtrip( app  = z2ui5_cl_cgui_popup=>confirm( question = `Sure?` )
               step = `confirm popup` ).
    roundtrip( app  = z2ui5_cl_cgui_popup=>get_values( fields = VALUE #( ( name = `A` text = `A` value = `1` ) ) )
               step = `values popup` ).

  ENDMETHOD.

ENDCLASS.
