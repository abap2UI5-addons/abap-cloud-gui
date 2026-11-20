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

    DATA mt_row   TYPE ty_t_row.
    DATA mt_plain TYPE ty_t_plain.

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
    DATA mv_window TYPE i.
    DATA mt_window_sort TYPE z2ui5_if_client=>ty_t_bind_tab_sort.

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
    METHODS filter_rows FOR TESTING.
    METHODS colors_and_header FOR TESTING.
    METHODS columns_and_cell_types FOR TESTING.
    METHODS aggregates_search_single FOR TESTING.
    METHODS f4_in_cells FOR TESTING.
    METHODS classic_fieldcat_layout_sort FOR TESTING.

ENDCLASS.


CLASS ltcl_app IMPLEMENTATION.

  METHOD z2ui5_if_app~main ##NEEDED.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
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
  METHOD z2ui5_if_client~window_get_row.
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
  METHOD z2ui5_if_client~nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
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

    mv_window      = window.
    mt_window_sort = t_sort.
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

  ENDMETHOD.

  METHOD xlsx_export.

    DATA lv_xlsx TYPE xstring.
    DATA lv_head TYPE x LENGTH 2.
    DATA lv_pk TYPE x LENGTH 2 VALUE '504B'.
    FIELD-SYMBOLS <temp43> LIKE LINE OF mo_client->mt_action.
    DATA temp44 LIKE sy-tabix.
    lv_xlsx = z2ui5_cl_cgui_alv=>factory( )->to_xlsx( mo_app->mt_row ).
    " an Office Open XML file is a zip archive - PK
    cl_abap_unit_assert=>assert_not_initial( lv_xlsx ).


    lv_head = lv_xlsx.
    cl_abap_unit_assert=>assert_equals( act = lv_head
                                        exp = lv_pk ).

    z2ui5_cl_cgui_alv=>factory( )->set_title( `Flights` )->export( client = mo_client
                                                                  tab    = mo_app->mt_row
                                                                  format = z2ui5_cl_cgui_alv=>cs_format-xlsx ).


    temp44 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 2 ASSIGNING <temp43>.
    sy-tabix = temp44.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp43>
                                        exp = `Flights.xlsx` ).

  ENDMETHOD.

  METHOD text_for_printing.

    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp45> LIKE LINE OF lt_text.
    DATA temp46 LIKE sy-tabix.
    FIELD-SYMBOLS <temp47> LIKE LINE OF lt_text.
    DATA temp48 LIKE sy-tabix.
    DATA temp33 TYPE xsdboolean.
    FIELD-SYMBOLS <temp49> LIKE LINE OF lt_text.
    DATA temp50 LIKE sy-tabix.
    DATA temp34 TYPE xsdboolean.
    lt_text = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hidden( `NOTE`
        )->set_column_sum( `PRICE`
        )->set_sort( name       = `CARRID`
                     descending = abap_true
        )->to_text( mo_app->mt_row ).

    " header, rule, three rows, rule, totals
    cl_abap_unit_assert=>assert_equals( act = lines( lt_text )
                                        exp = 7 ).


    temp46 = sy-tabix.
    READ TABLE lt_text INDEX 3 ASSIGNING <temp45>.
    sy-tabix = temp46.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp45>
                                         exp = `UA *` ).


    temp48 = sy-tabix.
    READ TABLE lt_text INDEX 3 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp33 = boolc( <temp47> CS `say` ).
    cl_abap_unit_assert=>assert_false( temp33 ).


    temp50 = sy-tabix.
    READ TABLE lt_text INDEX 7 ASSIGNING <temp49>.
    sy-tabix = temp50.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    temp34 = boolc( <temp49> CS `600` ).
    cl_abap_unit_assert=>assert_true( temp34 ).

  ENDMETHOD.

  METHOD paging.

    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp35 TYPE xsdboolean.
    DATA temp36 TYPE xsdboolean.
    DATA temp37 TYPE xsdboolean.
    DATA temp51 TYPE z2ui5_if_client=>ty_t_bind_tab_sort.
    DATA temp52 LIKE LINE OF temp51.
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

    " a large table is bound with window_bind_tab( ): the browser gets a window
    " of page_size rows, the title counts the whole table, no page buttons

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->set_title( `Flights` )->set_sort( name       = `PRICE`
                                              descending = abap_true ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row
                    total  = 5 ).

    lv_view = lo_view->stringify( ).

    temp35 = boolc( lv_view CS `Flights (5)` ).
    cl_abap_unit_assert=>assert_true( temp35 ).

    temp36 = boolc( lv_view CS `Page 3 of 3` ).
    cl_abap_unit_assert=>assert_false( temp36 ).

    temp37 = boolc( lv_view CS `rows="{/MT_ROW}"` ).
    cl_abap_unit_assert=>assert_true( temp37 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 2 ).
    " the sort of the layout is the order the server applies

    CLEAR temp51.

    temp52-path = `PRICE`.
    temp52-descending = abap_true.
    INSERT temp52 INTO TABLE temp51.
    cl_abap_unit_assert=>assert_equals( act = mo_client->mt_window_sort
                                        exp = temp51 ).

    lo_alv->page_turn( direction = z2ui5_cl_cgui_alv=>cs_page-first
                       lines     = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_page_offset( )
                                        exp = 0 ).

  ENDMETHOD.

  METHOD filter_rows.

    DATA temp53 TYPE ltcl_app=>ty_t_row.
    DATA temp54 LIKE LINE OF temp53.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp55 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp56 LIKE LINE OF temp55.
    DATA temp57 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp59 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp60 LIKE LINE OF temp59.
    DATA temp61 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp63 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp64 LIKE LINE OF temp63.
    DATA temp65 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp67 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp68 LIKE LINE OF temp67.
    DATA temp69 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp70 LIKE LINE OF temp69.
    DATA temp71 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp38 TYPE xsdboolean.
    DATA temp39 TYPE xsdboolean.
    CLEAR temp53.

    temp54-carrid = `LH`.
    temp54-connid = `0400`.
    temp54-price = 100.
    INSERT temp54 INTO TABLE temp53.
    temp54-carrid = `AA`.
    temp54-connid = `0017`.
    temp54-price = 200.
    INSERT temp54 INTO TABLE temp53.
    temp54-carrid = `LH`.
    temp54-connid = `2402`.
    temp54-price = 300.
    INSERT temp54 INTO TABLE temp53.
    temp54-carrid = `UA`.
    temp54-connid = `0941`.
    temp54-price = 400.
    INSERT temp54 INTO TABLE temp53.
    mo_app->mt_row = temp53.

    lo_alv = z2ui5_cl_cgui_alv=>factory( ).

    " no filter - every row
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->filter_index( mo_app->mt_row ) )
                                        exp = 4 ).

    " the semantics of a select-option, also across columns

    CLEAR temp55.

    temp56-sign = `I`.
    temp56-option = `EQ`.
    temp56-low = `LH`.
    INSERT temp56 INTO TABLE temp55.
    temp56-sign = `I`.
    temp56-option = `EQ`.
    temp56-low = `UA`.
    INSERT temp56 INTO TABLE temp55.
    lo_alv->set_filter( name = `carrid`
                        rows = temp55 ).

    CLEAR temp57.
    INSERT 1 INTO TABLE temp57.
    INSERT 3 INTO TABLE temp57.
    INSERT 4 INTO TABLE temp57.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp57 ).

    CLEAR temp59.

    temp60-sign = `I`.
    temp60-option = `BT`.
    temp60-low = `150`.
    temp60-high = `350`.
    INSERT temp60 INTO TABLE temp59.
    lo_alv->set_filter( name = `PRICE`
                        rows = temp59 ).

    CLEAR temp61.
    INSERT 3 INTO TABLE temp61.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp61 ).

    CLEAR temp63.

    temp64-sign = `E`.
    temp64-option = `EQ`.
    temp64-low = `100`.
    INSERT temp64 INTO TABLE temp63.
    lo_alv->set_filter( name = `PRICE`
                        rows = temp63 ).

    CLEAR temp65.
    INSERT 3 INTO TABLE temp65.
    INSERT 4 INTO TABLE temp65.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp65 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->get_filter( ) )
                                        exp = 2 ).

    " a value that does not fit the column

    CLEAR temp67.

    temp68-sign = `I`.
    temp68-option = `EQ`.
    temp68-low = `kein Datum`.
    INSERT temp68 INTO TABLE temp67.
    cl_abap_unit_assert=>assert_not_initial( lo_alv->check_filter(
        name = `FLDATE`
        rows = temp67
        tab  = mo_app->mt_row ) ).

    " a pattern
    lo_alv->clear_filter( ).

    CLEAR temp69.

    temp70-sign = `I`.
    temp70-option = `EQ`.
    temp70-low = `0*`.
    INSERT temp70 INTO TABLE temp69.
    lo_alv->set_filter( name = `CONNID`
                        rows = temp69 ).

    CLEAR temp71.
    INSERT 1 INTO TABLE temp71.
    INSERT 2 INTO TABLE temp71.
    INSERT 4 INTO TABLE temp71.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp71 ).

    " the toolbar counts the filters and shows the rows of all

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->set_title( `Flights` )->render( node   = lo_view
                                            client = mo_client
                                            tab    = mo_app->mt_row
                                            total  = 3
                                            all    = 4 ).

    lv_view = lo_view->stringify( ).

    temp38 = boolc( lv_view CS `Flights (3 of 4)` ).
    cl_abap_unit_assert=>assert_true( temp38 ).

    temp39 = boolc( lv_view CS z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    cl_abap_unit_assert=>assert_true( temp39 ).

  ENDMETHOD.

  METHOD colors_and_header.
    DATA temp73 TYPE ltcl_app=>ty_t_row.
    DATA temp74 LIKE LINE OF temp73.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp40 TYPE xsdboolean.
    DATA temp41 TYPE xsdboolean.
    DATA temp42 TYPE xsdboolean.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp43 TYPE xsdboolean.
    DATA temp1 LIKE sy-subrc.
    DATA temp2 LIKE sy-subrc.
    DATA temp3 LIKE sy-tabix.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp75> LIKE LINE OF lt_text.
    DATA temp76 LIKE sy-tabix.
    FIELD-SYMBOLS <temp77> LIKE LINE OF lt_text.
    DATA temp78 LIKE sy-tabix.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( z2ui5_cl_cgui_alv=>cs_color-positive )
                                        exp = `Success` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( `C610` )
                                        exp = `Error` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( `` )
                                        exp = `None` ).


    CLEAR temp73.

    temp74-carrid = `LH`.
    temp74-note = `C500`.
    temp74-price = 1.
    INSERT temp74 INTO TABLE temp73.
    mo_app->mt_row = temp73.

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

    temp40 = boolc( lv_view CS `RowSettings` ).
    cl_abap_unit_assert=>assert_true( temp40 ).

    temp41 = boolc( lv_view CS `ObjectStatus` ).
    cl_abap_unit_assert=>assert_true( temp41 ).

    temp42 = boolc( lv_view CS `Flight Report` ).
    cl_abap_unit_assert=>assert_true( temp42 ).
    " the color field is no column

    lt_layout = lo_alv->get_layout( mo_app->mt_row ).




    temp2 = sy-subrc.
    temp3 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `NOTE` TRANSPORTING NO FIELDS.
    temp1 = sy-subrc.
    sy-subrc = temp2.
    sy-tabix = temp3.
    temp43 = boolc( temp1 = 0 ).
    cl_abap_unit_assert=>assert_false( temp43 ).


    lt_text = lo_alv->to_text( mo_app->mt_row ).


    temp76 = sy-tabix.
    READ TABLE lt_text INDEX 1 ASSIGNING <temp75>.
    sy-tabix = temp76.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp75>
                                        exp = `Flight Report` ).


    temp78 = sy-tabix.
    READ TABLE lt_text INDEX 2 ASSIGNING <temp77>.
    sy-tabix = temp78.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp77>
                                        exp = `Airline: LH` ).

  ENDMETHOD.

  METHOD columns_and_cell_types.

    DATA temp79 TYPE ltcl_app=>ty_t_row.
    DATA temp80 LIKE LINE OF temp79.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_view TYPE string.
    DATA temp44 TYPE xsdboolean.
    DATA temp45 TYPE xsdboolean.
    DATA temp46 TYPE xsdboolean.
    DATA temp47 TYPE xsdboolean.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp48 TYPE xsdboolean.
    DATA temp4 LIKE sy-subrc.
    DATA temp49 TYPE xsdboolean.
    DATA temp50 TYPE xsdboolean.
    DATA temp81 TYPE z2ui5_cl_cgui_alv=>ty_t_value.
    DATA temp82 LIKE LINE OF temp81.
    DATA lo_edit TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp51 TYPE xsdboolean.
    DATA temp52 TYPE xsdboolean.
    CLEAR temp79.

    temp80-carrid = `LH`.
    temp80-connid = `0000`.
    temp80-price = 0.
    temp80-note = `A`.
    INSERT temp80 INTO TABLE temp79.
    temp80-carrid = `AA`.
    temp80-connid = `0017`.
    temp80-price = 5.
    temp80-note = `B`.
    INSERT temp80 INTO TABLE temp79.
    mo_app->mt_row = temp79.

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

    temp44 = boolc( lv_view CS `The airline` ).
    cl_abap_unit_assert=>assert_true( temp44 ).

    temp45 = boolc( lv_view CS `Number(${PRICE}) !== 0` ).
    cl_abap_unit_assert=>assert_true( temp45 ).

    temp46 = boolc( lv_view CS `FLDATE` ).
    cl_abap_unit_assert=>assert_false( temp46 ).

    temp47 = boolc( lv_view CS `hAlign="Center"` ).
    cl_abap_unit_assert=>assert_true( temp47 ).
    " the technical column is in no layout and no export

    lt_layout = lo_alv->get_layout( mo_app->mt_row ).


    READ TABLE lt_layout WITH KEY name = `FLDATE` TRANSPORTING NO FIELDS.
    temp4 = sy-subrc.
    temp48 = boolc( temp4 = 0 ).
    cl_abap_unit_assert=>assert_false( temp48 ).

    temp49 = boolc( lo_alv->to_csv( mo_app->mt_row ) CS `FLDATE` ).
    cl_abap_unit_assert=>assert_false( temp49 ).

    temp50 = boolc( lv_view CS `<Button text="{CONNID}"` ).
    cl_abap_unit_assert=>assert_true( temp50 ).
    " a button is no input - a clickable checkbox makes the grid hand its rows back
    cl_abap_unit_assert=>assert_false( lo_alv->is_editable( ) ).
    lo_alv->set_column_cell_type( name = `PRICE`
                                  type = z2ui5_cl_cgui_alv=>cs_cell_type-checkbox_hotspot ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_editable( ) ).

    " dropdown: the text shown, a Select in edit mode, editable per row

    CLEAR temp81.

    temp82-key = `LH`.
    temp82-text = `Lufthansa`.
    INSERT temp82 INTO TABLE temp81.
    temp82-key = `AA`.
    temp82-text = `American`.
    INSERT temp82 INTO TABLE temp81.

    lo_edit = z2ui5_cl_cgui_alv=>factory(
        )->set_column_dropdown( name   = `CARRID`
                                values = temp81 ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_edit->render( node   = lo_view
                     client = mo_client
                     tab    = mo_app->mt_row ).

    temp51 = boolc( lo_view->stringify( ) CS `'LH' ? 'Lufthansa'` ).
    cl_abap_unit_assert=>assert_true( temp51 ).
    lo_edit->set_edit( )->set_edit_field( `ZZSELKZ` ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_edit->render( node   = lo_view
                     client = mo_client
                     tab    = mo_app->mt_row ).
    lv_view = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Select *selectedKey="{CARRID}"*enabled="{= ${ZZSELKZ} === true*` ).

    temp52 = boolc( lv_view CS `editable="{= ${ZZSELKZ}` ).
    cl_abap_unit_assert=>assert_true( temp52 ).

  ENDMETHOD.

  METHOD aggregates_search_single.

    DATA temp83 TYPE ltcl_app=>ty_t_row.
    DATA temp84 LIKE LINE OF temp83.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lt_aggregate TYPE z2ui5_cl_cgui_alv=>ty_t_aggregate.
    FIELD-SYMBOLS <temp85> LIKE LINE OF lt_aggregate.
    DATA temp86 LIKE sy-tabix.
    FIELD-SYMBOLS <temp87> LIKE LINE OF lt_aggregate.
    DATA temp88 LIKE sy-tabix.
    FIELD-SYMBOLS <temp89> LIKE LINE OF lt_aggregate.
    DATA temp90 LIKE sy-tabix.
    DATA temp91 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp93 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    FIELD-SYMBOLS <temp95> LIKE LINE OF mo_app->mt_row.
    DATA temp96 LIKE sy-tabix.
    DATA temp97 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp53 TYPE xsdboolean.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp99> LIKE LINE OF lt_text.
    DATA temp100 LIKE sy-tabix.
    CLEAR temp83.

    CLEAR temp84.
    temp84-carrid = `LH`.
    temp84-price = 10.
    temp84-note = `x`.
    INSERT temp84 INTO TABLE temp83.
    CLEAR temp84.
    temp84-carrid = `AA`.
    temp84-price = 30.
    INSERT temp84 INTO TABLE temp83.
    CLEAR temp84.
    temp84-carrid = `LH`.
    temp84-price = 20.
    INSERT temp84 INTO TABLE temp83.
    mo_app->mt_row = temp83.

    lo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_column_aggregation( name        = `PRICE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-average
        )->set_column_aggregation( name        = `NOTE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-count ).

    lt_aggregate = lo_alv->get_aggregates( mo_app->mt_row ).


    temp86 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY column = `PRICE` ASSIGNING <temp85>.
    sy-tabix = temp86.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp85>-value
                                        exp = 20 ).


    temp88 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY column = `NOTE` ASSIGNING <temp87>.
    sy-tabix = temp88.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp87>-value
                                        exp = 1 ).
    lo_alv->set_column_aggregation( name        = `PRICE`
                                    aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-maximum ).
    lt_aggregate = lo_alv->get_aggregates( mo_app->mt_row ).


    temp90 = sy-tabix.
    READ TABLE lt_aggregate WITH KEY column = `PRICE` ASSIGNING <temp89>.
    sy-tabix = temp90.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp89>-value
                                        exp = 30 ).

    " the search finds the text in a column shown
    lo_alv->set_search( `aa` ).

    CLEAR temp91.
    INSERT 2 INTO TABLE temp91.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = temp91 ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_filtered( ) ).
    lo_alv->set_search( `` ).

    " single selection: the row selected last stays
    lo_alv->set_selection_mode( val = z2ui5_cl_cgui_alv=>cs_selection_mode-single ).

    CLEAR temp93.
    INSERT 1 INTO TABLE temp93.
    lo_alv->set_selected_rows( EXPORTING rows = temp93
                               CHANGING  tab  = mo_app->mt_row ).


    temp96 = sy-tabix.
    READ TABLE mo_app->mt_row INDEX 3 ASSIGNING <temp95>.
    sy-tabix = temp96.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp95>-zzselkz = abap_true.
    lo_alv->single_normalize( CHANGING tab = mo_app->mt_row ).

    CLEAR temp97.
    INSERT 3 INTO TABLE temp97.
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_selected_rows( mo_app->mt_row )
                                        exp = temp97 ).

    " details of the row selected, footer on the printout
    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-details.
    cl_abap_unit_assert=>assert_true( lo_alv->handle_event( EXPORTING client = mo_client
                                                            CHANGING  tab    = mo_app->mt_row ) ).

    temp53 = boolc( mo_client->mv_popup CS `Details` ).
    cl_abap_unit_assert=>assert_true( temp53 ).
    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-details_close.
    lo_alv->handle_event( EXPORTING client = mo_client
                          CHANGING  tab    = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).
    lo_alv->add_footer( label = `Created by`
                        value = `Nova` ).

    lt_text = lo_alv->to_text( mo_app->mt_row ).


    temp100 = sy-tabix.
    READ TABLE lt_text INDEX lines( lt_text ) ASSIGNING <temp99>.
    sy-tabix = temp100.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp99>
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

    DATA temp101 LIKE lt_flight.
    DATA temp102 LIKE LINE OF temp101.
    DATA temp103 LIKE lt_fcat.
    DATA temp104 LIKE LINE OF temp103.
    DATA temp105 LIKE lt_sort.
    DATA temp106 LIKE LINE OF temp105.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA lv_text TYPE string.
    DATA lv_aa TYPE i.
    DATA lv_lh TYPE i.
    DATA temp54 TYPE xsdboolean.
    CLEAR temp101.

    temp102-carrid = `LH`.
    temp102-seats = 10.
    temp102-price = `100.00`.
    INSERT temp102 INTO TABLE temp101.
    temp102-carrid = `AA`.
    temp102-seats = 20.
    temp102-price = `300.00`.
    INSERT temp102 INTO TABLE temp101.
    lt_flight = temp101.
    " the field catalog as the LVC functions take it

    CLEAR temp103.

    CLEAR temp104.
    temp104-fieldname = 'CARRID'.
    temp104-scrtext_l = 'Airline'.
    temp104-key = abap_true.
    INSERT temp104 INTO TABLE temp103.
    CLEAR temp104.
    temp104-fieldname = 'SEATS'.
    temp104-coltext = 'Seats'.
    temp104-do_sum = abap_true.
    INSERT temp104 INTO TABLE temp103.
    CLEAR temp104.
    temp104-fieldname = 'PRICE'.
    temp104-scrtext_m = 'Price'.
    temp104-outputlen = 12.
    INSERT temp104 INTO TABLE temp103.
    CLEAR temp104.
    temp104-fieldname = 'SEL'.
    temp104-tech = abap_true.
    INSERT temp104 INTO TABLE temp103.
    lt_fcat = temp103.
    CLEAR ls_layout.
    ls_layout-zebra = abap_true.
    ls_layout-cwidth_opt = abap_true.
    ls_layout-box_fname = 'SEL'.
    ls_layout-grid_title = 'Flights'.

    CLEAR temp105.

    temp106-fieldname = 'PRICE'.
    temp106-down = abap_true.
    INSERT temp106 INTO TABLE temp105.
    lt_sort = temp105.


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

    temp54 = boolc( lv_aa < lv_lh ).
    cl_abap_unit_assert=>assert_true( temp54 ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_text
                                         exp = `*30*` ).

  ENDMETHOD.

ENDCLASS.
