CLASS ltcl_app DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_row,
        zzselkz TYPE abap_bool,
        carrid  TYPE c LENGTH 3,
        connid  TYPE n LENGTH 4,
        fldate  TYPE d,
        price   TYPE p LENGTH 8 DECIMALS 2,
        note    TYPE string,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_plain,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_plain.
    TYPES ty_t_plain TYPE STANDARD TABLE OF ty_s_plain WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_amount,
        carrid TYPE c LENGTH 3,
        amount TYPE p LENGTH 8 DECIMALS 2,
        waers  TYPE c LENGTH 5,
      END OF ty_s_amount.
    TYPES ty_t_amount TYPE STANDARD TABLE OF ty_s_amount WITH DEFAULT KEY.

    DATA mt_row    TYPE ty_t_row.
    DATA mt_plain  TYPE ty_t_plain.
    DATA mt_amount TYPE ty_t_amount.

ENDCLASS.


CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mo_app    TYPE REF TO ltcl_app.
    DATA mv_event  TYPE string.
    DATA mt_arg    TYPE string_table.
    DATA mv_action TYPE string.
    DATA mt_action TYPE string_table.
    DATA mv_popup  TYPE string.
    " what the last window_bind_tab( ) was asked for
    DATA mv_window       TYPE i.
    DATA mv_window_total TYPE i.
    DATA mv_window_event TYPE string.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_app    TYPE REF TO ltcl_app.
    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS selected_rows FOR TESTING.
    METHODS select_all FOR TESTING.
    METHODS has_box_field FOR TESTING.
    METHODS csv_header_and_escape FOR TESTING.
    METHODS csv_hidden_column FOR TESTING.
    METHODS render_selection_column FOR TESTING.
    METHODS render_no_box_no_selection FOR TESTING.
    METHODS render_formats FOR TESTING.
    METHODS render_functions FOR TESTING.
    METHODS render_hotspot_and_icon FOR TESTING.
    METHODS handle_event_select_all FOR TESTING.
    METHODS export_downloads_csv FOR TESTING.
    METHODS row_by_path FOR TESTING.
    METHODS edit_renders_inputs FOR TESTING.
    METHODS layout_order_and_sort FOR TESTING.
    METHODS layout_roundtrip FOR TESTING.
    METHODS subtotals_per_group FOR TESTING.
    METHODS xlsx_export FOR TESTING.
    METHODS text_for_printing FOR TESTING.
    METHODS paging FOR TESTING.
    METHODS window_order FOR TESTING.
    METHODS window_filter_selects FOR TESTING.
    METHODS totals_per_currency FOR TESTING.
    METHODS filter_rows FOR TESTING.
    METHODS colors_and_header FOR TESTING.
    METHODS columns_and_cell_types FOR TESTING.
    METHODS aggregates_search_single FOR TESTING.
    METHODS f4_in_cells FOR TESTING.
    METHODS classic_fieldcat_layout_sort FOR TESTING.
    METHODS classic_fieldcat_again FOR TESTING.

ENDCLASS.


CLASS ltcl_app IMPLEMENTATION.

  METHOD z2ui5_if_app~main ##NEEDED.
  ENDMETHOD.

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
  METHOD z2ui5_if_client~get_app_prev.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_navigated.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_init.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_event.
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
  METHOD z2ui5_if_client~nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
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

  METHOD z2ui5_if_client~get_app.

    result = mo_app.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind_path.

    result = |/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                          val = val ) }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~window_bind_tab.

    mv_window       = window.
    mv_window_total = total.
    mv_window_event = event.
    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    DATA temp1 TYPE string.
    IF t_arg IS NOT INITIAL.
      temp1 = |:{ concat_lines_of( table = t_arg sep = `,` ) }|.
    ELSEIF arg IS NOT INITIAL.
      temp1 = |:{ arg }|.
    ELSE.
      CLEAR temp1.
    ENDIF.
    result = |EVENT:{ val }{ temp1 }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event.

    result = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~follow_up_action.

    mv_action = val.
    mt_action = t_arg.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    DATA temp2 TYPE ltcl_app=>ty_t_row.
    DATA temp3 LIKE LINE OF temp2.
    DATA temp4 TYPE ltcl_app=>ty_t_plain.
    DATA temp5 LIKE LINE OF temp4.

    CREATE OBJECT mo_app.
    CREATE OBJECT mo_client.
    mo_client->mo_app = mo_app.


    CLEAR temp2.

    temp3-carrid = `LH`.
    temp3-connid = `0400`.
    temp3-fldate = `20260105`.
    temp3-price = `100.50`.
    temp3-note = `a;b`.
    INSERT temp3 INTO TABLE temp2.
    temp3-carrid = `AA`.
    temp3-connid = `0017`.
    temp3-fldate = `20260106`.
    temp3-price = `200.00`.
    temp3-note = `plain`.
    INSERT temp3 INTO TABLE temp2.
    temp3-carrid = `UA`.
    temp3-connid = `0941`.
    temp3-fldate = `20260107`.
    temp3-price = `300.00`.
    temp3-note = `say "hi"`.
    INSERT temp3 INTO TABLE temp2.
    mo_app->mt_row = temp2.

    CLEAR temp4.

    temp5-carrid = `LH`.
    temp5-seats = 10.
    INSERT temp5 INTO TABLE temp4.
    mo_app->mt_plain = temp4.

  ENDMETHOD.

  METHOD selected_rows.

    FIELD-SYMBOLS <temp6> LIKE LINE OF mo_app->mt_row.
    DATA temp7 LIKE sy-tabix.
    FIELD-SYMBOLS <temp8> LIKE LINE OF mo_app->mt_row.
    DATA temp9 LIKE sy-tabix.
    DATA lt_rows TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp10 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    temp7 = sy-tabix.
    READ TABLE mo_app->mt_row INDEX 1 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp6>-zzselkz = abap_true.


    temp9 = sy-tabix.
    READ TABLE mo_app->mt_row INDEX 3 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp8>-zzselkz = abap_true.


    lt_rows = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( )->get_selected_rows( mo_app->mt_row ).


    CLEAR temp10.
    INSERT 1 INTO TABLE temp10.
    INSERT 3 INTO TABLE temp10.
    cl_abap_unit_assert=>assert_equals( act = lt_rows
                                        exp = temp10 ).

  ENDMETHOD.

  METHOD select_all.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( ).

    lo_alv->select_all( CHANGING tab = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->get_selected_rows( mo_app->mt_row ) )
                                        exp = 3 ).

    lo_alv->select_all( EXPORTING val = abap_false
                        CHANGING  tab = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_initial( lo_alv->get_selected_rows( mo_app->mt_row ) ).

  ENDMETHOD.

  METHOD has_box_field.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( ).

    cl_abap_unit_assert=>assert_true( lo_alv->has_box_field( mo_app->mt_row ) ).
    cl_abap_unit_assert=>assert_false( lo_alv->has_box_field( mo_app->mt_plain ) ).

  ENDMETHOD.

  METHOD csv_header_and_escape.

    DATA lv_csv TYPE string.
    DATA lt_line TYPE string_table.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lt_line.
    DATA temp13 LIKE sy-tabix.
    FIELD-SYMBOLS <temp14> LIKE LINE OF lt_line.
    DATA temp15 LIKE sy-tabix.
    DATA temp1 TYPE xsdboolean.
    FIELD-SYMBOLS <temp16> LIKE LINE OF lt_line.
    DATA temp17 LIKE sy-tabix.
    DATA temp2 TYPE xsdboolean.
    FIELD-SYMBOLS <temp18> LIKE LINE OF lt_line.
    DATA temp19 LIKE sy-tabix.
    DATA temp3 TYPE xsdboolean.
    FIELD-SYMBOLS <temp20> LIKE LINE OF lt_line.
    DATA temp21 LIKE sy-tabix.
    lv_csv = z2ui5_cl_cgui_alv=>factory(
        )->set_column_text( name = `CARRID` text = `Airline`
        )->to_csv( mo_app->mt_row ).


    SPLIT lv_csv AT |\r\n| INTO TABLE lt_line.

    cl_abap_unit_assert=>assert_equals( act = lines( lt_line )
                                        exp = 4 ).
    " the box field is no column of the export


    temp13 = sy-tabix.
    READ TABLE lt_line INDEX 1 ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp12>
                                         exp = `Airline;*` ).


    temp15 = sy-tabix.
    READ TABLE lt_line INDEX 1 ASSIGNING <temp14>.
    sy-tabix = temp15.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp1 = boolc( <temp14> CS `ZZSELKZ` ).
    cl_abap_unit_assert=>assert_false( temp1 ).
    " a value with the separator or a quote is quoted, its quotes doubled


    temp17 = sy-tabix.
    READ TABLE lt_line INDEX 2 ASSIGNING <temp16>.
    sy-tabix = temp17.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp2 = boolc( <temp16> CS `"a;b"` ).
    cl_abap_unit_assert=>assert_true( temp2 ).


    temp19 = sy-tabix.
    READ TABLE lt_line INDEX 4 ASSIGNING <temp18>.
    sy-tabix = temp19.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp3 = boolc( <temp18> CS `"say ""hi"""` ).
    cl_abap_unit_assert=>assert_true( temp3 ).


    temp21 = sy-tabix.
    READ TABLE lt_line INDEX 3 ASSIGNING <temp20>.
    sy-tabix = temp21.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp20>
                                         exp = `AA;0017;*` ).

  ENDMETHOD.

  METHOD csv_hidden_column.

    DATA lv_csv TYPE string.
    DATA temp4 TYPE xsdboolean.
    lv_csv = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hidden( `NOTE`
        )->set_column_text( name = `NOTE` text = `Note`
        )->to_csv( mo_app->mt_row ).


    temp4 = boolc( lv_csv CS `plain` ).
    cl_abap_unit_assert=>assert_false( temp4 ).

  ENDMETHOD.

  METHOD render_selection_column.

    DATA lv_view TYPE string.
    DATA temp5 TYPE xsdboolean.
    DATA temp6 TYPE xsdboolean.
    DATA temp7 TYPE xsdboolean.
    DATA temp8 TYPE xsdboolean.
    lv_view = z2ui5_cl_cgui_alv=>factory(
        )->set_selection_mode(
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).


    temp5 = boolc( lv_view CS `selected="{ZZSELKZ}"` ).
    cl_abap_unit_assert=>assert_true( temp5 ).

    temp6 = boolc( lv_view CS `EVENT:CGUI_ALV_SELECT_ALL` ).
    cl_abap_unit_assert=>assert_true( temp6 ).

    temp7 = boolc( lv_view CS `EVENT:CGUI_ALV_DESELECT_ALL` ).
    cl_abap_unit_assert=>assert_true( temp7 ).
    " the box field itself is no column with a label

    temp8 = boolc( lv_view CS `sortProperty="ZZSELKZ"` ).
    cl_abap_unit_assert=>assert_false( temp8 ).

  ENDMETHOD.

  METHOD render_no_box_no_selection.

    DATA lv_view TYPE string.
    DATA temp9 TYPE xsdboolean.
    DATA temp10 TYPE xsdboolean.
    lv_view = z2ui5_cl_cgui_alv=>factory(
        )->set_selection_mode(
        )->stringify( client = mo_client
                      tab    = mo_app->mt_plain ).


    temp9 = boolc( lv_view CS `EVENT:CGUI_ALV_SELECT_ALL` ).
    cl_abap_unit_assert=>assert_false( temp9 ).

    temp10 = boolc( lv_view CS `CheckBox` ).
    cl_abap_unit_assert=>assert_false( temp10 ).

  ENDMETHOD.

  METHOD render_formats.

    DATA lv_view TYPE string.
    DATA temp11 TYPE xsdboolean.
    DATA temp12 TYPE xsdboolean.
    DATA temp13 TYPE xsdboolean.
    DATA temp14 TYPE xsdboolean.
    DATA temp15 TYPE xsdboolean.
    lv_view = z2ui5_cl_cgui_alv=>factory(
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).


    temp11 = boolc( lv_view CS `core:require=` ).
    cl_abap_unit_assert=>assert_true( temp11 ).

    temp12 = boolc( lv_view CS `DateType` AND lv_view CS `FLDATE` ).
    cl_abap_unit_assert=>assert_true( temp12 ).

    temp13 = boolc( lv_view CS `FloatType` ).
    cl_abap_unit_assert=>assert_true( temp13 ).

    temp14 = boolc( lv_view CS `minFractionDigits: 2` ).
    cl_abap_unit_assert=>assert_true( temp14 ).

    temp15 = boolc( lv_view CS `EVENT:CGUI_ALV_EXPORT` ).
    cl_abap_unit_assert=>assert_true( temp15 ).

  ENDMETHOD.

  METHOD render_functions.

    DATA lv_view TYPE string.
    DATA temp16 TYPE xsdboolean.
    DATA temp17 TYPE xsdboolean.
    lv_view = z2ui5_cl_cgui_alv=>factory(
        )->add_function( name = `BOOK`
                         text = `Book`
                         icon = `sap-icon://cart`
        )->set_export( val = abap_false
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).


    temp16 = boolc( lv_view CS `EVENT:BOOK` ).
    cl_abap_unit_assert=>assert_true( temp16 ).

    temp17 = boolc( lv_view CS `EVENT:CGUI_ALV_EXPORT` ).
    cl_abap_unit_assert=>assert_false( temp17 ).

  ENDMETHOD.

  METHOD render_hotspot_and_icon.

    DATA lv_view TYPE string.
    DATA temp18 TYPE xsdboolean.
    DATA temp19 TYPE xsdboolean.
    DATA temp20 TYPE xsdboolean.
    lv_view = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hotspot( `CARRID`
        )->set_column_icon( `NOTE`
        )->set_column_width( name = `CONNID` width = `7rem`
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).


    temp18 = boolc( lv_view CS `EVENT:CGUI_ALV_HOTSPOT` ).
    cl_abap_unit_assert=>assert_true( temp18 ).

    temp19 = boolc( lv_view CS `<core:Icon src="{NOTE}"` ).
    cl_abap_unit_assert=>assert_true( temp19 ).

    temp20 = boolc( lv_view CS `width="7rem"` ).
    cl_abap_unit_assert=>assert_true( temp20 ).

  ENDMETHOD.

  METHOD handle_event_select_all.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( ).

    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-select_all.
    cl_abap_unit_assert=>assert_true( lo_alv->handle_event( EXPORTING client = mo_client
                                                            CHANGING  tab    = mo_app->mt_row ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->get_selected_rows( mo_app->mt_row ) )
                                        exp = 3 ).

    mo_client->mv_event = `OTHER`.
    cl_abap_unit_assert=>assert_false( lo_alv->handle_event( EXPORTING client = mo_client
                                                             CHANGING  tab    = mo_app->mt_row ) ).

  ENDMETHOD.

  METHOD export_downloads_csv.
    FIELD-SYMBOLS <temp22> LIKE LINE OF mo_client->mt_action.
    DATA temp23 LIKE sy-tabix.
    FIELD-SYMBOLS <temp24> LIKE LINE OF mo_client->mt_action.
    DATA temp25 LIKE sy-tabix.

    z2ui5_cl_cgui_alv=>factory( )->set_title( `Flights` )->export( client = mo_client
                                                                  tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_action
                                        exp = mo_client->z2ui5_if_client~cs_event-download_b64_file ).


    temp23 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp22>
                                         exp = `data:text/csv;charset=utf-8;base64,*` ).


    temp25 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 2 ASSIGNING <temp24>.
    sy-tabix = temp25.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp24>
                                        exp = `Flights.csv` ).

  ENDMETHOD.

  METHOD row_by_path.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>row_by_path( `/XX/MT_ROW/2` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>row_by_path( `` )
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>row_by_path( `/MT_ROW/x` )
                                        exp = 0 ).

  ENDMETHOD.

  METHOD edit_renders_inputs.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lv_view TYPE string.
    DATA temp21 TYPE xsdboolean.
    DATA temp22 TYPE xsdboolean.
    DATA temp23 TYPE xsdboolean.
    DATA temp24 TYPE xsdboolean.
    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_edit(
        )->set_column_edit( name = `CARRID`
                            val  = abap_false ).

    lv_view = lo_alv->stringify( client = mo_client
                                       tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_true( lo_alv->is_editable( ) ).

    temp21 = boolc( lv_view CS `change="EVENT:CGUI_ALV_DATA_CHANGED:` ).
    cl_abap_unit_assert=>assert_true( temp21 ).

    temp22 = boolc( lv_view CS `<DatePicker value="{FLDATE}"` ).
    cl_abap_unit_assert=>assert_true( temp22 ).

    temp23 = boolc( lv_view CS `<Input value="{NOTE}"` ).
    cl_abap_unit_assert=>assert_true( temp23 ).
    " the column set to no edit stays a text

    temp24 = boolc( lv_view CS `<Input value="{CARRID}"` ).
    cl_abap_unit_assert=>assert_false( temp24 ).
    cl_abap_unit_assert=>assert_false( z2ui5_cl_cgui_alv=>factory( )->is_editable( ) ).

  ENDMETHOD.

  METHOD layout_order_and_sort.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp26> LIKE LINE OF lt_layout.
    DATA temp27 LIKE sy-tabix.
    FIELD-SYMBOLS <temp28> LIKE LINE OF lt_layout.
    DATA temp29 LIKE sy-tabix.
    FIELD-SYMBOLS <temp30> LIKE LINE OF lt_layout.
    DATA temp31 LIKE sy-tabix.
    DATA lv_view TYPE string.
    DATA temp25 TYPE xsdboolean.
    DATA temp26 TYPE xsdboolean.
    DATA temp28 TYPE xsdboolean.
    DATA lv_note TYPE i.
    DATA lv_carrid TYPE i.
    DATA temp30 TYPE xsdboolean.
    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_column_position( name     = `NOTE`
                                position = 1
        )->set_sort( name       = `CARRID`
                     descending = abap_true ).


    lt_layout = lo_alv->get_layout( mo_app->mt_row ).


    temp27 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp26>.
    sy-tabix = temp27.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp26>-name
                                        exp = `NOTE` ).


    temp29 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp28>.
    sy-tabix = temp29.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp28>-position
                                        exp = 1 ).


    temp31 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `PRICE` ASSIGNING <temp30>.
    sy-tabix = temp31.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp30>-numeric ).


    lv_view = lo_alv->stringify( client = mo_client
                                       tab    = mo_app->mt_row ).

    temp25 = boolc( lv_view CS `sorter: [{path: 'CARRID', descending: true}]` ).
    cl_abap_unit_assert=>assert_true( temp25 ).

    temp26 = boolc( lv_view CS `sortOrder="Descending"` ).
    cl_abap_unit_assert=>assert_true( temp26 ).

    temp28 = boolc( lv_view CS `EVENT:CGUI_ALV_LAYOUT` ).
    cl_abap_unit_assert=>assert_true( temp28 ).
    " NOTE is the first column header

    lv_note = find( val = lv_view sub = `sortProperty="NOTE"` ).

    lv_carrid = find( val = lv_view sub = `sortProperty="CARRID"` ).

    temp30 = boolc( lv_note < lv_carrid ).
    cl_abap_unit_assert=>assert_true( temp30 ).

  ENDMETHOD.

  METHOD layout_roundtrip.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp32> LIKE LINE OF lt_layout.
    DATA temp33 LIKE sy-tabix.
    FIELD-SYMBOLS <temp34> LIKE LINE OF lt_layout.
    DATA temp35 LIKE sy-tabix.
    DATA lv_csv TYPE string.
    DATA temp31 TYPE xsdboolean.
    DATA lt_back TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp36> LIKE LINE OF lt_back.
    DATA temp37 LIKE sy-tabix.
    lo_alv = z2ui5_cl_cgui_alv=>factory( ).

    lt_layout = lo_alv->get_layout( mo_app->mt_row ).


    temp33 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `NOTE` ASSIGNING <temp32>.
    sy-tabix = temp33.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp32>-hidden = abap_true.


    temp35 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `PRICE` ASSIGNING <temp34>.
    sy-tabix = temp35.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp34>-sum = abap_true.


    lv_csv = lo_alv->set_layout( lt_layout )->to_csv( mo_app->mt_row ).

    temp31 = boolc( lv_csv CS `plain` ).
    cl_abap_unit_assert=>assert_false( temp31 ).

    lt_back = lo_alv->get_layout( mo_app->mt_row ).


    temp37 = sy-tabix.
    READ TABLE lt_back WITH KEY name = `PRICE` ASSIGNING <temp36>.
    sy-tabix = temp37.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp36>-sum ).

  ENDMETHOD.

  METHOD subtotals_per_group.

    FIELD-SYMBOLS <temp38> LIKE LINE OF mo_app->mt_row.
    DATA temp39 LIKE sy-tabix.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_subtotal TYPE z2ui5_cl_cgui_alv=>ty_t_subtotal.
    FIELD-SYMBOLS <temp40> LIKE LINE OF lt_subtotal.
    DATA temp41 LIKE sy-tabix.
    DATA temp42 TYPE decfloat34.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_subtotal.
    DATA temp2 LIKE sy-tabix.
    DATA lv_view TYPE string.
    DATA temp32 TYPE xsdboolean.
    DATA temp43 TYPE ltcl_app=>ty_t_plain.
    DATA temp44 LIKE LINE OF temp43.
    DATA temp45 TYPE decfloat34.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_subtotal.
    DATA temp4 LIKE sy-tabix.
    DATA temp46 TYPE decfloat34.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_subtotal.
    DATA temp6 LIKE sy-tabix.
    DATA lv_csv TYPE string.
    DATA lv_aa TYPE i.
    DATA lv_lh TYPE i.
    DATA temp33 TYPE xsdboolean.
    temp39 = sy-tabix.
    READ TABLE mo_app->mt_row INDEX 3 ASSIGNING <temp38>.
    sy-tabix = temp39.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp38>-carrid = `LH`.

    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_sort( name     = `CARRID`
                     subtotal = abap_true
        )->set_column_sum( `PRICE` ).


    lt_subtotal = lo_alv->get_subtotals( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_subtotal )
                                        exp = 2 ).


    temp41 = sy-tabix.
    READ TABLE lt_subtotal INDEX 1 ASSIGNING <temp40>.
    sy-tabix = temp41.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp40>-group
                                        exp = `AA` ).

    temp42 = `400.50`.


    temp2 = sy-tabix.
    READ TABLE lt_subtotal INDEX 2 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp1>-value
                                        exp = temp42 ).


    lv_view = lo_alv->stringify( client = mo_client
                                       tab    = mo_app->mt_row ).

    temp32 = boolc( lv_view CS `headerText="Subtotals"` ).
    cl_abap_unit_assert=>assert_true( temp32 ).

    " the groups in the order of the sorting, not of their texts: 9 before 10

    CLEAR temp43.

    temp44-carrid = `LH`.
    temp44-seats = 10.
    INSERT temp44 INTO TABLE temp43.
    temp44-carrid = `AA`.
    temp44-seats = 9.
    INSERT temp44 INTO TABLE temp43.
    temp44-carrid = `UA`.
    temp44-seats = 10.
    INSERT temp44 INTO TABLE temp43.
    mo_app->mt_plain = temp43.
    lt_subtotal = z2ui5_cl_cgui_alv=>factory(
        )->set_sort( name     = `SEATS`
                     subtotal = abap_true
        )->set_column_sum( `SEATS` )->get_subtotals( mo_app->mt_plain ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_subtotal )
                                        exp = 2 ).

    temp45 = 9.


    temp4 = sy-tabix.
    READ TABLE lt_subtotal INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp3>-value
                                        exp = temp45 ).

    temp46 = 20.


    temp6 = sy-tabix.
    READ TABLE lt_subtotal INDEX 2 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp5>-value
                                        exp = temp46 ).

    " the CSV export in the order of the layout as well

    lv_csv = z2ui5_cl_cgui_alv=>factory( )->set_sort( `CARRID` )->to_csv( mo_app->mt_row ).

    FIND `AA` IN lv_csv MATCH OFFSET lv_aa.

    FIND `LH` IN lv_csv MATCH OFFSET lv_lh.

    temp33 = boolc( lv_aa < lv_lh ).
    cl_abap_unit_assert=>assert_true( temp33 ).

  ENDMETHOD.

  METHOD xlsx_export.

    DATA lv_xlsx TYPE xstring.
    DATA lv_head TYPE x LENGTH 2.
    DATA lv_pk TYPE x LENGTH 2 VALUE '504B'.
    DATA lt_cell TYPE z2ui5_cl_cgui_xlsx=>ty_t_cell.
    DATA lt_visible TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    FIELD-SYMBOLS <temp47> LIKE LINE OF lt_cell.
    DATA temp48 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_visible.
    DATA temp8 LIKE sy-tabix.
    DATA lv_col TYPE i.
    DATA temp9 LIKE sy-subrc.
    DATA temp10 LIKE sy-subrc.
    DATA temp11 LIKE sy-tabix.
    DATA temp49 TYPE z2ui5_cl_cgui_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lt_cell.
    DATA temp13 LIKE sy-tabix.
    DATA temp50 LIKE sy-subrc.
    DATA temp51 TYPE z2ui5_cl_cgui_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp14> LIKE LINE OF lt_cell.
    DATA temp15 LIKE sy-tabix.
    DATA temp52 LIKE sy-subrc.
    DATA temp53 TYPE z2ui5_cl_cgui_xlsx=>ty_s_cell.
    FIELD-SYMBOLS <temp16> LIKE LINE OF lt_cell.
    DATA temp17 LIKE sy-tabix.
    FIELD-SYMBOLS <temp54> LIKE LINE OF lt_cell.
    DATA temp55 LIKE sy-tabix.
    FIELD-SYMBOLS <temp56> LIKE LINE OF mo_client->mt_action.
    DATA temp57 LIKE sy-tabix.
    lv_xlsx = z2ui5_cl_cgui_alv=>factory( )->to_xlsx( mo_app->mt_row ).
    " an Office Open XML file is a zip archive - PK
    cl_abap_unit_assert=>assert_not_initial( lv_xlsx ).


    lv_head = lv_xlsx.
    cl_abap_unit_assert=>assert_equals( act = lv_head
                                        exp = lv_pk ).

    " read back: the columns the ALV shows under their labels, a NUMC with
    " its zeros as text, a date as a date, a price as a number

    lt_cell = z2ui5_cl_cgui_xlsx=>factory_by_xlsx( lv_xlsx )->get_cells( ).

    lt_visible = z2ui5_cl_cgui_alv=>factory( )->get_columns( mo_app->mt_row ).


    temp48 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 1 col = 1 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.


    temp8 = sy-tabix.
    READ TABLE lt_visible INDEX 1 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp47>-value
                                        exp = <temp7>-label ).




    temp10 = sy-subrc.
    temp11 = sy-tabix.
    READ TABLE lt_visible WITH KEY name = `CONNID` TRANSPORTING NO FIELDS.
    temp9 = sy-tabix.
    sy-subrc = temp10.
    sy-tabix = temp11.
    lv_col = temp9.

    CLEAR temp49.
    temp49-row = 2.
    temp49-col = lv_col.
    temp49-kind = `S`.
    temp49-value = `0400`.


    temp13 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = lv_col ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        act = <temp12>
        exp = temp49 ).

    READ TABLE lt_visible WITH KEY name = `FLDATE` TRANSPORTING NO FIELDS.
    temp50 = sy-tabix.
    lv_col = temp50.

    CLEAR temp51.
    temp51-row = 2.
    temp51-col = lv_col.
    temp51-kind = `D`.
    temp51-value = `2026-01-05`.


    temp15 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = lv_col ASSIGNING <temp14>.
    sy-tabix = temp15.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        act = <temp14>
        exp = temp51 ).

    READ TABLE lt_visible WITH KEY name = `PRICE` TRANSPORTING NO FIELDS.
    temp52 = sy-tabix.
    lv_col = temp52.

    CLEAR temp53.
    temp53-row = 2.
    temp53-col = lv_col.
    temp53-kind = `N`.
    temp53-value = `100.5`.


    temp17 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 2 col = lv_col ASSIGNING <temp16>.
    sy-tabix = temp17.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals(
        act = <temp16>
        exp = temp53 ).


    temp55 = sy-tabix.
    READ TABLE lt_cell WITH KEY row = 4 col = lv_col ASSIGNING <temp54>.
    sy-tabix = temp55.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp54>-value
                                        exp = `300` ).

    z2ui5_cl_cgui_alv=>factory( )->set_title( `Flights` )->export( client = mo_client
                                                                  tab    = mo_app->mt_row
                                                                  format = z2ui5_cl_cgui_alv=>cs_format-xlsx ).


    temp57 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 2 ASSIGNING <temp56>.
    sy-tabix = temp57.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp56>
                                        exp = `Flights.xlsx` ).

  ENDMETHOD.

  METHOD text_for_printing.

    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp58> LIKE LINE OF lt_text.
    DATA temp59 LIKE sy-tabix.
    FIELD-SYMBOLS <temp60> LIKE LINE OF lt_text.
    DATA temp61 LIKE sy-tabix.
    DATA temp34 TYPE xsdboolean.
    FIELD-SYMBOLS <temp62> LIKE LINE OF lt_text.
    DATA temp63 LIKE sy-tabix.
    DATA temp35 TYPE xsdboolean.
    FIELD-SYMBOLS <temp64> LIKE LINE OF lt_text.
    DATA temp65 LIKE sy-tabix.
    DATA temp36 TYPE xsdboolean.
    FIELD-SYMBOLS <temp66> LIKE LINE OF lt_text.
    DATA temp67 LIKE sy-tabix.
    DATA temp37 TYPE xsdboolean.
    lt_text = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hidden( `NOTE`
        )->set_column_sum( `PRICE`
        )->set_sort( name       = `CARRID`
                     descending = abap_true
        )->to_text( mo_app->mt_row ).

    " header, rule, three rows, rule, totals
    cl_abap_unit_assert=>assert_equals( act = lines( lt_text )
                                        exp = 7 ).


    temp59 = sy-tabix.
    READ TABLE lt_text INDEX 3 ASSIGNING <temp58>.
    sy-tabix = temp59.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp58>
                                         exp = `UA *` ).


    temp61 = sy-tabix.
    READ TABLE lt_text INDEX 3 ASSIGNING <temp60>.
    sy-tabix = temp61.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp34 = boolc( <temp60> CS `say` ).
    cl_abap_unit_assert=>assert_false( temp34 ).


    temp63 = sy-tabix.
    READ TABLE lt_text INDEX 7 ASSIGNING <temp62>.
    sy-tabix = temp63.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp35 = boolc( <temp62> CS `600` ).
    cl_abap_unit_assert=>assert_true( temp35 ).

    " the aggregation of the column, not always a total: the maximum
    lt_text = z2ui5_cl_cgui_alv=>factory(
        )->set_column_aggregation( name        = `PRICE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-maximum
        )->to_text( mo_app->mt_row ).


    temp65 = sy-tabix.
    READ TABLE lt_text INDEX lines( lt_text ) ASSIGNING <temp64>.
    sy-tabix = temp65.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp36 = boolc( <temp64> CS `300` ).
    cl_abap_unit_assert=>assert_true( temp36 ).


    temp67 = sy-tabix.
    READ TABLE lt_text INDEX lines( lt_text ) ASSIGNING <temp66>.
    sy-tabix = temp67.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp37 = boolc( <temp66> CS `600` ).
    cl_abap_unit_assert=>assert_false( temp37 ).

  ENDMETHOD.

  METHOD paging.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp38 TYPE xsdboolean.
    DATA temp39 TYPE xsdboolean.
    DATA temp40 TYPE xsdboolean.
    DATA temp41 TYPE xsdboolean.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_paging( 2 ).

    lo_alv->page_turn( direction = z2ui5_cl_cgui_alv=>cs_page-next
                       lines     = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_page_offset( )
                                        exp = 2 ).
    lo_alv->page_turn( direction = z2ui5_cl_cgui_alv=>cs_page-last
                       lines     = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_page( )
                                        exp = 3 ).
    lo_alv->page_turn( direction = z2ui5_cl_cgui_alv=>cs_page-next
                       lines     = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_page( )
                                        exp = 3 ).

    " a large table is bound with window_bind_tab( ): the rows handed over are
    " the ones loaded, total the rows there are - the browser asks for the
    " next page_size rows with cs_event-rows; the title counts the whole
    " table, no page buttons

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->set_title( `Flights` )->set_sort( name       = `PRICE`
                                              descending = abap_true ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row
                    total  = 5 ).

    lv_view = lo_view->stringify( ).

    temp38 = boolc( lv_view CS `Flights (5)` ).
    cl_abap_unit_assert=>assert_true( temp38 ).

    temp39 = boolc( lv_view CS `Page 3 of 3` ).
    cl_abap_unit_assert=>assert_false( temp39 ).

    temp40 = boolc( lv_view CS `rows="{/MT_ROW}"` ).
    cl_abap_unit_assert=>assert_true( temp40 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window_total
                                        exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window_event
                                        exp = z2ui5_cl_cgui_alv=>cs_event-rows ).
    " no sorter in the binding: the rows come in the order the app loads

    temp41 = boolc( lv_view CS `sorter` ).
    cl_abap_unit_assert=>assert_false( temp41 ).

    lo_alv->page_turn( direction = z2ui5_cl_cgui_alv=>cs_page-first
                       lines     = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_page_offset( )
                                        exp = 0 ).

  ENDMETHOD.

  METHOD window_order.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp68 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp70 TYPE z2ui5_if_client=>ty_s_window_request.
    DATA temp18 TYPE z2ui5_if_client=>ty_t_bind_tab_sort.
    DATA temp19 LIKE LINE OF temp18.
    DATA temp20 TYPE z2ui5_if_client=>ty_t_bind_tab_filter.
    DATA temp21 LIKE LINE OF temp20.
    DATA temp71 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp73 TYPE z2ui5_if_client=>ty_s_window_request.
    DATA temp74 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_paging( 2 ).
    lo_alv->set_sort( name       = `PRICE`
                      descending = abap_true ).

    " the order of the paged grid: the sort of the layout

    CLEAR temp68.
    INSERT 3 INTO TABLE temp68.
    INSERT 2 INTO TABLE temp68.
    INSERT 1 INTO TABLE temp68.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->window_order( mo_app->mt_row )
                                        exp = temp68 ).

    " a sort of a column menu replaces it, a filter lets the rows through
    " its groups do - the conditions of one group ORed

    CLEAR temp70.
    temp70-reason = z2ui5_if_client=>cs_window_reason-filter.

    CLEAR temp18.

    temp19-path = `CARRID`.
    INSERT temp19 INTO TABLE temp18.
    temp70-t_sort = temp18.

    CLEAR temp20.

    temp21-group = 1.
    temp21-path = `CARRID`.
    temp21-operator = `Contains`.
    temp21-value1 = `a`.
    INSERT temp21 INTO TABLE temp20.
    temp21-group = 1.
    temp21-path = `CARRID`.
    temp21-operator = `EQ`.
    temp21-value1 = `LH`.
    INSERT temp21 INTO TABLE temp20.
    temp21-group = 2.
    temp21-path = `FLDATE`.
    temp21-operator = `LE`.
    temp21-value1 = `2026-01-06`.
    INSERT temp21 INTO TABLE temp20.
    temp70-t_filter = temp20.
    lo_alv->window_request( temp70 ).

    CLEAR temp71.
    INSERT 2 INTO TABLE temp71.
    INSERT 1 INTO TABLE temp71.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->window_order( mo_app->mt_row )
                                        exp = temp71 ).

    " more rows keep the order; a new sort of the layout ends what a
    " column menu asked for

    CLEAR temp73.
    temp73-reason = z2ui5_if_client=>cs_window_reason-more.
    lo_alv->window_request( temp73 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->window_order( mo_app->mt_row ) )
                                        exp = 2 ).
    lo_alv->set_sort( `CONNID` ).

    CLEAR temp74.
    INSERT 3 INTO TABLE temp74.
    INSERT 2 INTO TABLE temp74.
    INSERT 1 INTO TABLE temp74.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->window_order( mo_app->mt_row )
                                        exp = temp74 ).

  ENDMETHOD.

  METHOD window_filter_selects.

    FIELD-SYMBOLS <copy> TYPE ltcl_app=>ty_t_row.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp76 TYPE z2ui5_if_client=>ty_s_window_request.
    DATA temp22 TYPE z2ui5_if_client=>ty_t_bind_tab_filter.
    DATA temp23 LIKE LINE OF temp22.
    DATA temp77 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp79 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA lr_rows LIKE REF TO mo_app->mt_row.
    DATA lr_copy TYPE REF TO data.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp42 TYPE xsdboolean.
    DATA temp43 TYPE xsdboolean.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_paging( 2 )->set_selection_mode( ).

    " a filter of a column menu of the paged grid is a filter of the grid:
    " Select All, print and export take the rows it lets through
    cl_abap_unit_assert=>assert_false( lo_alv->is_filtered( ) ).

    CLEAR temp76.
    temp76-reason = z2ui5_if_client=>cs_window_reason-filter.

    CLEAR temp22.

    temp23-group = 1.
    temp23-path = `CARRID`.
    temp23-operator = `EQ`.
    temp23-value1 = `AA`.
    INSERT temp23 INTO TABLE temp22.
    temp76-t_filter = temp22.
    lo_alv->window_request( temp76 ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_filtered( ) ).

    CLEAR temp77.
    INSERT 2 INTO TABLE temp77.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp77 ).
    lo_alv->select_filtered( EXPORTING selected = abap_true
                             CHANGING  tab      = mo_app->mt_row ).

    CLEAR temp79.
    INSERT 2 INTO TABLE temp79.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_selected_rows( mo_app->mt_row )
                                        exp = temp79 ).

    GET REFERENCE OF mo_app->mt_row INTO lr_rows.

    lr_copy = lo_alv->filtered_copy( source = lr_rows
                                           shown  = lr_rows ).
    ASSIGN lr_copy->* TO <copy>.
    cl_abap_unit_assert=>assert_equals( act = lines( <copy> )
                                        exp = 1 ).

    " the column menus filter only where the backend hears of it - paged

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).

    temp42 = boolc( lo_view->stringify( ) CS `filterProperty` ).
    cl_abap_unit_assert=>assert_true( temp42 ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    z2ui5_cl_cgui_alv=>factory( )->render( node   = lo_view
                                           client = mo_client
                                           tab    = mo_app->mt_row ).

    temp43 = boolc( lo_view->stringify( ) CS `filterProperty` ).
    cl_abap_unit_assert=>assert_false( temp43 ).

    " Delete Filter ends it
    lo_alv->clear_filter( ).
    cl_abap_unit_assert=>assert_false( lo_alv->is_filtered( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->filter_index( mo_app->mt_row ) )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD totals_per_currency.

    DATA temp81 TYPE ltcl_app=>ty_t_amount.
    DATA temp82 LIKE LINE OF temp81.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_aggregate TYPE z2ui5_cl_cgui_alv=>ty_t_aggregate.
    DATA temp83 TYPE decfloat34.
    FIELD-SYMBOLS <temp24> LIKE LINE OF lt_aggregate.
    DATA temp25 LIKE sy-tabix.
    DATA temp84 TYPE decfloat34.
    FIELD-SYMBOLS <temp26> LIKE LINE OF lt_aggregate.
    DATA temp27 LIKE sy-tabix.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp85> LIKE LINE OF lt_text.
    DATA temp86 LIKE sy-tabix.
    DATA temp44 TYPE xsdboolean.
    FIELD-SYMBOLS <temp87> LIKE LINE OF lt_text.
    DATA temp88 LIKE sy-tabix.
    DATA temp45 TYPE xsdboolean.
    DATA lt_subtotal TYPE z2ui5_cl_cgui_alv=>ty_t_subtotal.
    DATA temp89 TYPE decfloat34.
    FIELD-SYMBOLS <temp28> LIKE LINE OF lt_subtotal.
    DATA temp29 LIKE sy-tabix.
    DATA temp90 TYPE ltcl_app=>ty_t_amount.
    FIELD-SYMBOLS <temp30> LIKE LINE OF mo_app->mt_amount.
    DATA temp31 LIKE sy-tabix.
    DATA lt_first LIKE temp90.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp92 LIKE REF TO mo_app->mt_amount.
    DATA temp46 TYPE xsdboolean.
    CLEAR temp81.

    temp82-carrid = `LH`.
    temp82-amount = 100.
    temp82-waers = `EUR`.
    INSERT temp82 INTO TABLE temp81.
    temp82-carrid = `LH`.
    temp82-amount = 200.
    temp82-waers = `USD`.
    INSERT temp82 INTO TABLE temp81.
    temp82-carrid = `AA`.
    temp82-amount = 50.
    temp82-waers = `EUR`.
    INSERT temp82 INTO TABLE temp81.
    mo_app->mt_amount = temp81.

    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_column_sum( `AMOUNT`
        )->set_column_currency( name           = `AMOUNT`
                                currency_field = `WAERS` ).

    " 100 EUR and 200 USD are no total of 300: one total per currency

    lt_aggregate = lo_alv->get_aggregates( mo_app->mt_amount ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_aggregate )
                                        exp = 2 ).

    temp83 = 150.


    temp25 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY unit = `EUR` ASSIGNING <temp24>.
    sy-tabix = temp25.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp24>-value
                                        exp = temp83 ).

    temp84 = 200.


    temp27 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY unit = `USD` ASSIGNING <temp26>.
    sy-tabix = temp27.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp26>-value
                                        exp = temp84 ).

    " the printout: a totals line per currency

    lt_text = lo_alv->to_text( mo_app->mt_amount ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_text )
                                        exp = 8 ).


    temp86 = sy-tabix.
    READ TABLE lt_text INDEX 7 ASSIGNING <temp85>.
    sy-tabix = temp86.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp44 = boolc( <temp85> CS `EUR` ).
    cl_abap_unit_assert=>assert_true( temp44 ).


    temp88 = sy-tabix.
    READ TABLE lt_text INDEX 8 ASSIGNING <temp87>.
    sy-tabix = temp88.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp45 = boolc( <temp87> CS `USD` ).
    cl_abap_unit_assert=>assert_true( temp45 ).

    " the subtotals per group and currency

    lt_subtotal = lo_alv->set_sort( name     = `CARRID`
                                          subtotal = abap_true )->get_subtotals( mo_app->mt_amount ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_subtotal )
                                        exp = 3 ).

    temp89 = 200.


    temp29 = sy-tabix.
    READ TABLE lt_subtotal WITH KEY group = `LH` unit = `USD` ASSIGNING <temp28>.
    sy-tabix = temp29.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp28>-value
                                        exp = temp89 ).

    " a paged grid holds the first rows - the totals are those of all rows

    CLEAR temp90.


    temp31 = sy-tabix.
    READ TABLE mo_app->mt_amount INDEX 1 ASSIGNING <temp30>.
    sy-tabix = temp31.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    INSERT <temp30> INTO TABLE temp90.

    lt_first = temp90.

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).

    GET REFERENCE OF mo_app->mt_amount INTO temp92.
z2ui5_cl_cgui_alv=>factory( )->set_column_sum( `AMOUNT` )->render( node   = lo_view
                                                                     client = mo_client
                                                                     tab    = lt_first
                                                                     sums   = temp92 ).

    temp46 = boolc( lo_view->stringify( ) CS `350` ).
    cl_abap_unit_assert=>assert_true( temp46 ).

  ENDMETHOD.

  METHOD filter_rows.

    DATA temp93 TYPE ltcl_app=>ty_t_row.
    DATA temp94 LIKE LINE OF temp93.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp95 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp96 LIKE LINE OF temp95.
    DATA temp97 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp99 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp100 LIKE LINE OF temp99.
    DATA temp101 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp103 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp104 LIKE LINE OF temp103.
    DATA temp105 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp107 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp108 LIKE LINE OF temp107.
    DATA temp109 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp110 LIKE LINE OF temp109.
    DATA temp111 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp47 TYPE xsdboolean.
    DATA temp48 TYPE xsdboolean.
    CLEAR temp93.

    temp94-carrid = `LH`.
    temp94-connid = `0400`.
    temp94-price = 100.
    INSERT temp94 INTO TABLE temp93.
    temp94-carrid = `AA`.
    temp94-connid = `0017`.
    temp94-price = 200.
    INSERT temp94 INTO TABLE temp93.
    temp94-carrid = `LH`.
    temp94-connid = `2402`.
    temp94-price = 300.
    INSERT temp94 INTO TABLE temp93.
    temp94-carrid = `UA`.
    temp94-connid = `0941`.
    temp94-price = 400.
    INSERT temp94 INTO TABLE temp93.
    mo_app->mt_row = temp93.

    lo_alv = z2ui5_cl_cgui_alv=>factory( ).

    " no filter - every row
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->filter_index( mo_app->mt_row ) )
                                        exp = 4 ).

    " the semantics of a select-option, also across columns

    CLEAR temp95.

    temp96-sign = `I`.
    temp96-option = `EQ`.
    temp96-low = `LH`.
    INSERT temp96 INTO TABLE temp95.
    temp96-sign = `I`.
    temp96-option = `EQ`.
    temp96-low = `UA`.
    INSERT temp96 INTO TABLE temp95.
    lo_alv->set_filter( name = `carrid`
                        rows = temp95 ).

    CLEAR temp97.
    INSERT 1 INTO TABLE temp97.
    INSERT 3 INTO TABLE temp97.
    INSERT 4 INTO TABLE temp97.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp97 ).

    CLEAR temp99.

    temp100-sign = `I`.
    temp100-option = `BT`.
    temp100-low = `150`.
    temp100-high = `350`.
    INSERT temp100 INTO TABLE temp99.
    lo_alv->set_filter( name = `PRICE`
                        rows = temp99 ).

    CLEAR temp101.
    INSERT 3 INTO TABLE temp101.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp101 ).

    CLEAR temp103.

    temp104-sign = `E`.
    temp104-option = `EQ`.
    temp104-low = `100`.
    INSERT temp104 INTO TABLE temp103.
    lo_alv->set_filter( name = `PRICE`
                        rows = temp103 ).

    CLEAR temp105.
    INSERT 3 INTO TABLE temp105.
    INSERT 4 INTO TABLE temp105.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp105 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->get_filter( ) )
                                        exp = 2 ).

    " a value that does not fit the column

    CLEAR temp107.

    temp108-sign = `I`.
    temp108-option = `EQ`.
    temp108-low = `kein Datum`.
    INSERT temp108 INTO TABLE temp107.
    cl_abap_unit_assert=>assert_not_initial( lo_alv->check_filter(
        name = `FLDATE`
        rows = temp107
        tab  = mo_app->mt_row ) ).

    " a pattern
    lo_alv->clear_filter( ).

    CLEAR temp109.

    temp110-sign = `I`.
    temp110-option = `EQ`.
    temp110-low = `0*`.
    INSERT temp110 INTO TABLE temp109.
    lo_alv->set_filter( name = `CONNID`
                        rows = temp109 ).

    CLEAR temp111.
    INSERT 1 INTO TABLE temp111.
    INSERT 2 INTO TABLE temp111.
    INSERT 4 INTO TABLE temp111.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp111 ).

    " the toolbar counts the filters and shows the rows of all

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->set_title( `Flights` )->render( node   = lo_view
                                            client = mo_client
                                            tab    = mo_app->mt_row
                                            total  = 3
                                            all    = 4 ).

    lv_view = lo_view->stringify( ).

    temp47 = boolc( lv_view CS `Flights (3 of 4)` ).
    cl_abap_unit_assert=>assert_true( temp47 ).

    temp48 = boolc( lv_view CS z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    cl_abap_unit_assert=>assert_true( temp48 ).

  ENDMETHOD.

  METHOD colors_and_header.
    DATA temp113 TYPE ltcl_app=>ty_t_row.
    DATA temp114 LIKE LINE OF temp113.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp49 TYPE xsdboolean.
    DATA temp50 TYPE xsdboolean.
    DATA temp51 TYPE xsdboolean.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp52 TYPE xsdboolean.
    DATA temp1 LIKE sy-subrc.
    DATA temp2 LIKE sy-subrc.
    DATA temp3 LIKE sy-tabix.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp115> LIKE LINE OF lt_text.
    DATA temp116 LIKE sy-tabix.
    FIELD-SYMBOLS <temp117> LIKE LINE OF lt_text.
    DATA temp118 LIKE sy-tabix.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( z2ui5_cl_cgui_alv=>cs_color-positive )
                                        exp = `Success` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( `C610` )
                                        exp = `Error` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( `` )
                                        exp = `None` ).


    CLEAR temp113.

    temp114-carrid = `LH`.
    temp114-note = `C500`.
    temp114-price = 1.
    INSERT temp114 INTO TABLE temp113.
    mo_app->mt_row = temp113.

    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_color_field( `NOTE`
        )->set_column_color( name  = `PRICE`
                             color = z2ui5_cl_cgui_alv=>cs_color-negative
        )->add_header( `Flight Report`
        )->add_header( label = `Airline`
                       value = `LH` ).

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).

    lv_view = lo_view->stringify( ).

    temp49 = boolc( lv_view CS `RowSettings` ).
    cl_abap_unit_assert=>assert_true( temp49 ).

    temp50 = boolc( lv_view CS `ObjectStatus` ).
    cl_abap_unit_assert=>assert_true( temp50 ).

    temp51 = boolc( lv_view CS `Flight Report` ).
    cl_abap_unit_assert=>assert_true( temp51 ).
    " the color field is no column

    lt_layout = lo_alv->get_layout( mo_app->mt_row ).




    temp2 = sy-subrc.
    temp3 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `NOTE` TRANSPORTING NO FIELDS.
    temp1 = sy-subrc.
    sy-subrc = temp2.
    sy-tabix = temp3.
    temp52 = boolc( temp1 = 0 ).
    cl_abap_unit_assert=>assert_false( temp52 ).


    lt_text = lo_alv->to_text( mo_app->mt_row ).


    temp116 = sy-tabix.
    READ TABLE lt_text INDEX 1 ASSIGNING <temp115>.
    sy-tabix = temp116.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp115>
                                        exp = `Flight Report` ).


    temp118 = sy-tabix.
    READ TABLE lt_text INDEX 2 ASSIGNING <temp117>.
    sy-tabix = temp118.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp117>
                                        exp = `Airline: LH` ).

  ENDMETHOD.

  METHOD columns_and_cell_types.

    DATA temp119 TYPE ltcl_app=>ty_t_row.
    DATA temp120 LIKE LINE OF temp119.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA lv_before TYPE string.
    DATA temp53 TYPE xsdboolean.
    DATA temp54 TYPE xsdboolean.
    DATA temp55 TYPE xsdboolean.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp56 TYPE xsdboolean.
    DATA temp4 LIKE sy-subrc.
    DATA temp57 TYPE xsdboolean.
    DATA temp58 TYPE xsdboolean.
    DATA temp121 TYPE z2ui5_cl_cgui_alv=>ty_t_value.
    DATA temp122 LIKE LINE OF temp121.
    DATA lo_edit TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp59 TYPE xsdboolean.
    DATA temp60 TYPE xsdboolean.
    DATA temp61 TYPE xsdboolean.
    CLEAR temp119.

    temp120-carrid = `LH`.
    temp120-connid = `0000`.
    temp120-price = 0.
    temp120-note = `A`.
    INSERT temp120 INTO TABLE temp119.
    temp120-carrid = `AA`.
    temp120-connid = `0017`.
    temp120-price = 5.
    temp120-note = `B`.
    INSERT temp120 INTO TABLE temp119.
    mo_app->mt_row = temp119.

    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_color_field( `NOTE`
        )->set_line_selection(
        )->set_column_key( `CARRID`
        )->set_column_tooltip( name = `CARRID`
                               text = `The airline`
        )->set_column_no_zero( `PRICE`
        )->set_column_technical( `FLDATE`
        )->set_column_alignment( name  = `CONNID`
                                 align = z2ui5_cl_cgui_alv=>cs_align-center
        )->set_column_cell_type( name = `CONNID`
                                 type = z2ui5_cl_cgui_alv=>cs_cell_type-button ).

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).

    lv_view = lo_view->stringify( ).

    " the event on the table, not on the row settings
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<table:Table *cellClick=*fixedColumnCount="1"*<table:rowSettingsTemplate*` ).
    " the tooltip on the column, not on its label

    lv_before = substring_before( val = lv_view
                                        sub = `tooltip="The airline"` ).
    cl_abap_unit_assert=>assert_char_cp( act = substring( val = lv_before
                                                          off = find( val = lv_before
                                                                      sub = `<`
                                                                      occ = -1 ) )
                                         exp = `<table:Column *` ).

    temp53 = boolc( lv_view CS `Number(${PRICE}) !== 0` ).
    cl_abap_unit_assert=>assert_true( temp53 ).

    temp54 = boolc( lv_view CS `FLDATE` ).
    cl_abap_unit_assert=>assert_false( temp54 ).

    temp55 = boolc( lv_view CS `hAlign="Center"` ).
    cl_abap_unit_assert=>assert_true( temp55 ).
    " the technical column is in no layout and no export

    lt_layout = lo_alv->get_layout( mo_app->mt_row ).


    READ TABLE lt_layout WITH KEY name = `FLDATE` TRANSPORTING NO FIELDS.
    temp4 = sy-subrc.
    temp56 = boolc( temp4 = 0 ).
    cl_abap_unit_assert=>assert_false( temp56 ).

    temp57 = boolc( lo_alv->to_csv( mo_app->mt_row ) CS `FLDATE` ).
    cl_abap_unit_assert=>assert_false( temp57 ).

    temp58 = boolc( lv_view CS `<Button text="{CONNID}"` ).
    cl_abap_unit_assert=>assert_true( temp58 ).
    " a button is no input - a clickable checkbox makes the grid hand its rows back
    cl_abap_unit_assert=>assert_false( lo_alv->is_editable( ) ).
    lo_alv->set_column_cell_type( name = `PRICE`
                                  type = z2ui5_cl_cgui_alv=>cs_cell_type-checkbox_hotspot ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_editable( ) ).

    " dropdown: the text shown, a Select in edit mode, editable per row

    CLEAR temp121.

    temp122-key = `LH`.
    temp122-text = `Lufthansa`.
    INSERT temp122 INTO TABLE temp121.
    temp122-key = `UA`.
    temp122-text = `United & Co`.
    INSERT temp122 INTO TABLE temp121.
    temp122-key = `AA`.
    temp122-text = `American`.
    INSERT temp122 INTO TABLE temp121.

    lo_edit = z2ui5_cl_cgui_alv=>factory(
        )->set_column_dropdown( name   = `CARRID`
                                values = temp121 ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_edit->render( node   = lo_view
                     client = mo_client
                     tab    = mo_app->mt_row ).

    temp59 = boolc( lo_view->stringify( ) CS `'LH' ? 'Lufthansa'` ).
    cl_abap_unit_assert=>assert_true( temp59 ).
    " escaped once, by the builder - the text shows A &amp; B, not A &amp;amp; B

    temp60 = boolc( lo_view->stringify( ) CS `'United &amp; Co'` ).
    cl_abap_unit_assert=>assert_true( temp60 ).
    lo_edit->set_edit( )->set_edit_field( `ZZSELKZ` ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_edit->render( node   = lo_view
                     client = mo_client
                     tab    = mo_app->mt_row ).
    lv_view = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Select *selectedKey="{CARRID}"*enabled="{= ${ZZSELKZ} === true*` ).

    temp61 = boolc( lv_view CS `editable="{= ${ZZSELKZ}` ).
    cl_abap_unit_assert=>assert_true( temp61 ).

  ENDMETHOD.

  METHOD aggregates_search_single.

    DATA temp123 TYPE ltcl_app=>ty_t_row.
    DATA temp124 LIKE LINE OF temp123.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_aggregate TYPE z2ui5_cl_cgui_alv=>ty_t_aggregate.
    FIELD-SYMBOLS <temp125> LIKE LINE OF lt_aggregate.
    DATA temp126 LIKE sy-tabix.
    FIELD-SYMBOLS <temp127> LIKE LINE OF lt_aggregate.
    DATA temp128 LIKE sy-tabix.
    FIELD-SYMBOLS <temp129> LIKE LINE OF lt_aggregate.
    DATA temp130 LIKE sy-tabix.
    DATA temp131 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp133 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    FIELD-SYMBOLS <temp135> LIKE LINE OF mo_app->mt_row.
    DATA temp136 LIKE sy-tabix.
    DATA temp137 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp62 TYPE xsdboolean.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp139> LIKE LINE OF lt_text.
    DATA temp140 LIKE sy-tabix.
    CLEAR temp123.

    CLEAR temp124.
    temp124-carrid = `LH`.
    temp124-price = 10.
    temp124-note = `x`.
    INSERT temp124 INTO TABLE temp123.
    CLEAR temp124.
    temp124-carrid = `AA`.
    temp124-price = 30.
    INSERT temp124 INTO TABLE temp123.
    CLEAR temp124.
    temp124-carrid = `LH`.
    temp124-price = 20.
    INSERT temp124 INTO TABLE temp123.
    mo_app->mt_row = temp123.

    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_column_aggregation( name        = `PRICE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-average
        )->set_column_aggregation( name        = `NOTE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-count ).

    lt_aggregate = lo_alv->get_aggregates( mo_app->mt_row ).


    temp126 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY column = `PRICE` ASSIGNING <temp125>.
    sy-tabix = temp126.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp125>-value
                                        exp = 20 ).


    temp128 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY column = `NOTE` ASSIGNING <temp127>.
    sy-tabix = temp128.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp127>-value
                                        exp = 1 ).
    lo_alv->set_column_aggregation( name        = `PRICE`
                                    aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-maximum ).
    lt_aggregate = lo_alv->get_aggregates( mo_app->mt_row ).


    temp130 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY column = `PRICE` ASSIGNING <temp129>.
    sy-tabix = temp130.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp129>-value
                                        exp = 30 ).

    " the search finds the text in a column shown
    lo_alv->set_search( `aa` ).

    CLEAR temp131.
    INSERT 2 INTO TABLE temp131.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp131 ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_filtered( ) ).
    lo_alv->set_search( `` ).

    " single selection: the row selected last stays
    lo_alv->set_selection_mode( val = z2ui5_cl_cgui_alv=>cs_selection_mode-single ).

    CLEAR temp133.
    INSERT 1 INTO TABLE temp133.
    lo_alv->set_selected_rows( EXPORTING rows = temp133
                               CHANGING  tab  = mo_app->mt_row ).


    temp136 = sy-tabix.
    READ TABLE mo_app->mt_row INDEX 3 ASSIGNING <temp135>.
    sy-tabix = temp136.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp135>-zzselkz = abap_true.
    lo_alv->single_normalize( CHANGING tab = mo_app->mt_row ).

    CLEAR temp137.
    INSERT 3 INTO TABLE temp137.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_selected_rows( mo_app->mt_row )
                                        exp = temp137 ).

    " details of the row selected, footer on the printout
    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-details.
    cl_abap_unit_assert=>assert_true( lo_alv->handle_event( EXPORTING client = mo_client
                                                            CHANGING  tab    = mo_app->mt_row ) ).

    temp62 = boolc( mo_client->mv_popup CS `Details` ).
    cl_abap_unit_assert=>assert_true( temp62 ).
    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-details_close.
    lo_alv->handle_event( EXPORTING client = mo_client
                          CHANGING  tab    = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).
    lo_alv->add_footer( label = `Created by`
                        value = `Nova` ).

    lt_text = lo_alv->to_text( mo_app->mt_row ).


    temp140 = sy-tabix.
    READ TABLE lt_text INDEX lines( lt_text ) ASSIGNING <temp139>.
    sy-tabix = temp140.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp139>
                                        exp = `Created by: Nova` ).

  ENDMETHOD.

  METHOD f4_in_cells.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_edit( )->set_column_f4( `CARRID` ).

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).

    lv_view = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*value="{CARRID}"*showValueHelp="true"*EVENT:CGUI_ALV_F4*` ).
    " only the column with F4
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*value="{NOTE}"*showValueHelp*` ).

  ENDMETHOD.

  METHOD classic_fieldcat_layout_sort.

    TYPES:
      BEGIN OF ty_s_flight,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
        price  TYPE p LENGTH 8 DECIMALS 2,
        sel    TYPE c LENGTH 1,
      END OF ty_s_flight.
    " LVC_T_FCAT, LVC_S_LAYO and LVC_T_SORT with the fields used here - the
    " ALV reads them by name, and ABAP Cloud has no LVC types
    TYPES:
      BEGIN OF ty_s_fcat,
        fieldname TYPE c LENGTH 30,
        scrtext_l TYPE c LENGTH 40,
        scrtext_m TYPE c LENGTH 20,
        coltext   TYPE c LENGTH 40,
        key       TYPE c LENGTH 1,
        do_sum    TYPE c LENGTH 1,
        outputlen TYPE n LENGTH 6,
        tech      TYPE c LENGTH 1,
      END OF ty_s_fcat.
    TYPES:
      BEGIN OF ty_s_layo,
        zebra      TYPE c LENGTH 1,
        cwidth_opt TYPE c LENGTH 1,
        box_fname  TYPE c LENGTH 30,
        grid_title TYPE c LENGTH 70,
      END OF ty_s_layo.
    TYPES:
      BEGIN OF ty_s_sort,
        fieldname TYPE c LENGTH 30,
        down      TYPE c LENGTH 1,
      END OF ty_s_sort.
    TYPES temp1 TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.
DATA lt_flight TYPE temp1.
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_fcat WITH DEFAULT KEY.
DATA lt_fcat   TYPE temp2.
    DATA ls_layout TYPE ty_s_layo.
    TYPES temp3 TYPE STANDARD TABLE OF ty_s_sort WITH DEFAULT KEY.
DATA lt_sort   TYPE temp3.

    DATA temp141 LIKE lt_flight.
    DATA temp142 LIKE LINE OF temp141.
    DATA temp143 LIKE lt_fcat.
    DATA temp144 LIKE LINE OF temp143.
    DATA temp145 LIKE lt_sort.
    DATA temp146 LIKE LINE OF temp145.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lv_text TYPE string.
    DATA lv_aa TYPE i.
    DATA lv_lh TYPE i.
    DATA temp63 TYPE xsdboolean.
    CLEAR temp141.

    temp142-carrid = `LH`.
    temp142-seats = 10.
    temp142-price = `100.00`.
    INSERT temp142 INTO TABLE temp141.
    temp142-carrid = `AA`.
    temp142-seats = 20.
    temp142-price = `300.00`.
    INSERT temp142 INTO TABLE temp141.
    lt_flight = temp141.
    " the field catalog as the LVC functions take it

    CLEAR temp143.

    CLEAR temp144.
    temp144-fieldname = 'CARRID'.
    temp144-scrtext_l = 'Airline'.
    temp144-key = abap_true.
    INSERT temp144 INTO TABLE temp143.
    CLEAR temp144.
    temp144-fieldname = 'SEATS'.
    temp144-coltext = 'Seats'.
    temp144-do_sum = abap_true.
    INSERT temp144 INTO TABLE temp143.
    CLEAR temp144.
    temp144-fieldname = 'PRICE'.
    temp144-scrtext_m = 'Price'.
    temp144-outputlen = 12.
    INSERT temp144 INTO TABLE temp143.
    CLEAR temp144.
    temp144-fieldname = 'SEL'.
    temp144-tech = abap_true.
    INSERT temp144 INTO TABLE temp143.
    lt_fcat = temp143.
    CLEAR ls_layout.
    ls_layout-zebra = abap_true.
    ls_layout-cwidth_opt = abap_true.
    ls_layout-box_fname = 'SEL'.
    ls_layout-grid_title = 'Flights'.

    CLEAR temp145.

    temp146-fieldname = 'PRICE'.
    temp146-down = abap_true.
    INSERT temp146 INTO TABLE temp145.
    lt_sort = temp145.


    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_fieldcat( lt_fcat
        )->set_layout_classic( ls_layout
        )->set_sort_classic( lt_sort ).

    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_selection_mode( )
                                        exp = z2ui5_cl_cgui_alv=>cs_selection_mode-multiple ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_box_field( )
                                        exp = `SEL` ).

    lv_text = concat_lines_of( table = lo_alv->to_text( lt_flight ) sep = `|` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_text
                                         exp = `*Airline*Seats*Price*` ).
    " the technical box field is not shown
    cl_abap_unit_assert=>assert_char_np( act = lv_text
                                         exp = `*SEL*` ).
    " sorted by the price downwards, the seats summed up

    FIND `AA` IN lv_text MATCH OFFSET lv_aa.

    FIND `LH` IN lv_text MATCH OFFSET lv_lh.

    temp63 = boolc( lv_aa < lv_lh ).
    cl_abap_unit_assert=>assert_true( temp63 ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_text
                                         exp = `*30*` ).

  ENDMETHOD.

  METHOD classic_fieldcat_again.

    TYPES:
      BEGIN OF ty_s_flight,
        carrid TYPE c LENGTH 3,
        price  TYPE p LENGTH 8 DECIMALS 2,
      END OF ty_s_flight.
    TYPES:
      BEGIN OF ty_s_fcat,
        fieldname TYPE c LENGTH 30,
        scrtext_l TYPE c LENGTH 40,
        coltext   TYPE c LENGTH 40,
        no_out    TYPE c LENGTH 1,
        edit      TYPE c LENGTH 1,
      END OF ty_s_fcat.
    TYPES:
      BEGIN OF ty_s_sort,
        fieldname TYPE c LENGTH 30,
        down      TYPE c LENGTH 1,
      END OF ty_s_sort.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.
DATA lt_flight TYPE temp4.
    TYPES temp5 TYPE STANDARD TABLE OF ty_s_fcat WITH DEFAULT KEY.
DATA lt_fcat   TYPE temp5.
    TYPES temp6 TYPE STANDARD TABLE OF ty_s_sort WITH DEFAULT KEY.
DATA lt_sort   TYPE temp6.

    " COLTEXT is the text the report gave the column - before the DDIC's;
    " EDIT of one column makes that column an input, not the grid
    DATA temp147 LIKE lt_fcat.
    DATA temp148 LIKE LINE OF temp147.
    DATA temp149 LIKE lt_sort.
    DATA temp150 LIKE LINE OF temp149.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp151> LIKE LINE OF lt_layout.
    DATA temp152 LIKE sy-tabix.
    FIELD-SYMBOLS <temp153> LIKE LINE OF lt_layout.
    DATA temp154 LIKE sy-tabix.
    DATA temp155 LIKE lt_fcat.
    DATA temp156 LIKE LINE OF temp155.
    DATA temp157 LIKE lt_sort.
    DATA temp158 LIKE LINE OF temp157.
    FIELD-SYMBOLS <temp159> LIKE LINE OF lt_layout.
    DATA temp160 LIKE sy-tabix.
    FIELD-SYMBOLS <temp161> LIKE LINE OF lt_layout.
    DATA temp162 LIKE sy-tabix.
    FIELD-SYMBOLS <temp163> LIKE LINE OF lt_layout.
    DATA temp164 LIKE sy-tabix.
    CLEAR temp147.

    CLEAR temp148.
    temp148-fieldname = 'CARRID'.
    temp148-no_out = abap_true.
    INSERT temp148 INTO TABLE temp147.
    CLEAR temp148.
    temp148-fieldname = 'PRICE'.
    temp148-scrtext_l = 'Price'.
    temp148-coltext = 'Fare'.
    temp148-edit = abap_true.
    INSERT temp148 INTO TABLE temp147.
    lt_fcat = temp147.

    CLEAR temp149.

    temp150-fieldname = 'PRICE'.
    temp150-down = abap_true.
    INSERT temp150 INTO TABLE temp149.
    lt_sort = temp149.

    lo_alv = z2ui5_cl_cgui_alv=>factory( )->set_fieldcat( lt_fcat
        )->set_sort_classic( lt_sort ).

    lt_layout = lo_alv->get_layout( lt_flight ).


    temp152 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `PRICE` ASSIGNING <temp151>.
    sy-tabix = temp152.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp151>-text
                                        exp = `Fare` ).


    temp154 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `CARRID` ASSIGNING <temp153>.
    sy-tabix = temp154.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp153>-hidden ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_editable( ) ).

    " the catalog and the sort set again on the grid that shows: what is
    " off now is off - the grid is no input grid -, the old sort is gone

    CLEAR temp155.

    temp156-fieldname = 'CARRID'.
    INSERT temp156 INTO TABLE temp155.
    temp156-fieldname = 'PRICE'.
    INSERT temp156 INTO TABLE temp155.
    lt_fcat = temp155.

    CLEAR temp157.

    temp158-fieldname = 'CARRID'.
    INSERT temp158 INTO TABLE temp157.
    lt_sort = temp157.
    lo_alv->set_fieldcat( lt_fcat )->set_sort_classic( lt_sort ).
    lt_layout = lo_alv->get_layout( lt_flight ).


    temp160 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `CARRID` ASSIGNING <temp159>.
    sy-tabix = temp160.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp159>-hidden ).
    cl_abap_unit_assert=>assert_false( lo_alv->is_editable( ) ).


    temp162 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `PRICE` ASSIGNING <temp161>.
    sy-tabix = temp162.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp161>-sort ).


    temp164 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `CARRID` ASSIGNING <temp163>.
    sy-tabix = temp164.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp163>-sort_seq
                                        exp = 1 ).

  ENDMETHOD.

ENDCLASS.
