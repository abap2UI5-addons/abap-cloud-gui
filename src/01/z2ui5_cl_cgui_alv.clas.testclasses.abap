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
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_plain,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_plain.
    TYPES ty_t_plain TYPE STANDARD TABLE OF ty_s_plain WITH EMPTY KEY.

    DATA mt_row   TYPE ty_t_row.
    DATA mt_plain TYPE ty_t_plain.

ENDCLASS.


CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

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

  METHOD z2ui5_if_client~get_app.

    result = mo_app.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~window_bind_tab.

    mv_window      = window.
    mt_window_sort = t_sort.
    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }{ COND #( WHEN t_arg IS NOT INITIAL THEN |:{ concat_lines_of( table = t_arg sep = `,` ) }| WHEN arg IS NOT INITIAL THEN |:{ arg }| ) }|.

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

    mo_app = NEW #( ).
    mo_client = NEW #( ).
    mo_client->mo_app = mo_app.

    mo_app->mt_row = VALUE #( ( carrid = `LH` connid = `0400` fldate = `20260105` price = `100.50` note = `a;b` )
                              ( carrid = `AA` connid = `0017` fldate = `20260106` price = `200.00` note = `plain` )
                              ( carrid = `UA` connid = `0941` fldate = `20260107` price = `300.00` note = `say "hi"` ) ).
    mo_app->mt_plain = VALUE #( ( carrid = `LH` seats = 10 ) ).

  ENDMETHOD.

  METHOD selected_rows.

    mo_app->mt_row[ 1 ]-zzselkz = abap_true.
    mo_app->mt_row[ 3 ]-zzselkz = abap_true.

    DATA(lt_rows) = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( )->get_selected_rows( mo_app->mt_row ).

    cl_abap_unit_assert=>assert_equals( act = lt_rows
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_row( ( 1 ) ( 3 ) ) ).

  ENDMETHOD.

  METHOD select_all.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( ).

    lo_alv->select_all( CHANGING tab = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->get_selected_rows( mo_app->mt_row ) )
                                        exp = 3 ).

    lo_alv->select_all( EXPORTING val = abap_false
                        CHANGING  tab = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_initial( lo_alv->get_selected_rows( mo_app->mt_row ) ).

  ENDMETHOD.

  METHOD has_box_field.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( ).

    cl_abap_unit_assert=>assert_true( lo_alv->has_box_field( mo_app->mt_row ) ).
    cl_abap_unit_assert=>assert_false( lo_alv->has_box_field( mo_app->mt_plain ) ).

  ENDMETHOD.

  METHOD csv_header_and_escape.

    DATA(lv_csv) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_text( name = `CARRID` text = `Airline`
        )->to_csv( mo_app->mt_row ).

    DATA lt_line TYPE string_table.
    SPLIT lv_csv AT |\r\n| INTO TABLE lt_line.

    cl_abap_unit_assert=>assert_equals( act = lines( lt_line )
                                        exp = 4 ).
    " the box field is no column of the export
    cl_abap_unit_assert=>assert_char_cp( act = lt_line[ 1 ]
                                         exp = `Airline;*` ).
    cl_abap_unit_assert=>assert_false( xsdbool( lt_line[ 1 ] CS `ZZSELKZ` ) ).
    " a value with the separator or a quote is quoted, its quotes doubled
    cl_abap_unit_assert=>assert_true( xsdbool( lt_line[ 2 ] CS `"a;b"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lt_line[ 4 ] CS `"say ""hi"""` ) ).
    cl_abap_unit_assert=>assert_char_cp( act = lt_line[ 3 ]
                                         exp = `AA;0017;*` ).

  ENDMETHOD.

  METHOD csv_hidden_column.

    DATA(lv_csv) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hidden( `NOTE`
        )->set_column_text( name = `NOTE` text = `Note`
        )->to_csv( mo_app->mt_row ).

    cl_abap_unit_assert=>assert_false( xsdbool( lv_csv CS `plain` ) ).

  ENDMETHOD.

  METHOD render_selection_column.

    DATA(lv_view) = z2ui5_cl_cgui_alv=>factory(
        )->set_selection_mode(
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `selected="{ZZSELKZ}"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_ALV_SELECT_ALL` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_ALV_DESELECT_ALL` ) ).
    " the box field itself is no column with a label
    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `sortProperty="ZZSELKZ"` ) ).

  ENDMETHOD.

  METHOD render_no_box_no_selection.

    DATA(lv_view) = z2ui5_cl_cgui_alv=>factory(
        )->set_selection_mode(
        )->stringify( client = mo_client
                      tab    = mo_app->mt_plain ).

    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `EVENT:CGUI_ALV_SELECT_ALL` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `CheckBox` ) ).

  ENDMETHOD.

  METHOD render_formats.

    DATA(lv_view) = z2ui5_cl_cgui_alv=>factory(
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `core:require=` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `DateType` AND lv_view CS `FLDATE` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `FloatType` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `minFractionDigits: 2` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_ALV_EXPORT` ) ).

  ENDMETHOD.

  METHOD render_functions.

    DATA(lv_view) = z2ui5_cl_cgui_alv=>factory(
        )->add_function( name = `BOOK`
                         text = `Book`
                         icon = `sap-icon://cart`
        )->set_export( val = abap_false
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:BOOK` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `EVENT:CGUI_ALV_EXPORT` ) ).

  ENDMETHOD.

  METHOD render_hotspot_and_icon.

    DATA(lv_view) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hotspot( `CARRID`
        )->set_column_icon( `NOTE`
        )->set_column_width( name = `CONNID` width = `7rem`
        )->stringify( client = mo_client
                      tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_ALV_HOTSPOT` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `<core:Icon src="{NOTE}"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `width="7rem"` ) ).

  ENDMETHOD.

  METHOD handle_event_select_all.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( )->set_selection_mode( ).

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

    z2ui5_cl_cgui_alv=>factory( )->set_title( `Flights` )->export( client = mo_client
                                                                  tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_action
                                        exp = mo_client->z2ui5_if_client~cs_event-download_b64_file ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mt_action[ 1 ]
                                         exp = `data:text/csv;charset=utf-8;base64,*` ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mt_action[ 2 ]
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

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory(
        )->set_edit(
        )->set_column_edit( name = `CARRID`
                            val  = abap_false ).
    DATA(lv_view) = lo_alv->stringify( client = mo_client
                                       tab    = mo_app->mt_row ).

    cl_abap_unit_assert=>assert_true( lo_alv->is_editable( ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `change="EVENT:CGUI_ALV_DATA_CHANGED:` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `<DatePicker value="{FLDATE}"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `<Input value="{NOTE}"` ) ).
    " the column set to no edit stays a text
    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `<Input value="{CARRID}"` ) ).
    cl_abap_unit_assert=>assert_false( z2ui5_cl_cgui_alv=>factory( )->is_editable( ) ).

  ENDMETHOD.

  METHOD layout_order_and_sort.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_position( name     = `NOTE`
                                position = 1
        )->set_sort( name       = `CARRID`
                     descending = abap_true ).

    DATA(lt_layout) = lo_alv->get_layout( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_layout[ 1 ]-name
                                        exp = `NOTE` ).
    cl_abap_unit_assert=>assert_equals( act = lt_layout[ 1 ]-position
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_true( lt_layout[ name = `PRICE` ]-numeric ).

    DATA(lv_view) = lo_alv->stringify( client = mo_client
                                       tab    = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `sorter: [{path: 'CARRID', descending: true}]` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `sortOrder="Descending"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_ALV_LAYOUT` ) ).
    " NOTE is the first column header
    DATA(lv_note) = find( val = lv_view sub = `sortProperty="NOTE"` ).
    DATA(lv_carrid) = find( val = lv_view sub = `sortProperty="CARRID"` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_note < lv_carrid ) ).

  ENDMETHOD.

  METHOD layout_roundtrip.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( ).
    DATA(lt_layout) = lo_alv->get_layout( mo_app->mt_row ).
    lt_layout[ name = `NOTE` ]-hidden = abap_true.
    lt_layout[ name = `PRICE` ]-sum = abap_true.

    DATA(lv_csv) = lo_alv->set_layout( lt_layout )->to_csv( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_csv CS `plain` ) ).
    DATA(lt_back) = lo_alv->get_layout( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_true( lt_back[ name = `PRICE` ]-sum ).

  ENDMETHOD.

  METHOD subtotals_per_group.

    mo_app->mt_row[ 3 ]-carrid = `LH`.
    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory(
        )->set_sort( name     = `CARRID`
                     subtotal = abap_true
        )->set_column_sum( `PRICE` ).

    DATA(lt_subtotal) = lo_alv->get_subtotals( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_subtotal )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_subtotal[ 1 ]-group
                                        exp = `AA` ).
    cl_abap_unit_assert=>assert_equals( act = lt_subtotal[ 2 ]-value
                                        exp = CONV decfloat34( `400.50` ) ).

    DATA(lv_view) = lo_alv->stringify( client = mo_client
                                       tab    = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `headerText="Subtotals"` ) ).

  ENDMETHOD.

  METHOD xlsx_export.

    DATA(lv_xlsx) = z2ui5_cl_cgui_alv=>factory( )->to_xlsx( mo_app->mt_row ).
    " an Office Open XML file is a zip archive - PK
    cl_abap_unit_assert=>assert_not_initial( lv_xlsx ).
    DATA lv_head TYPE x LENGTH 2.
    DATA lv_pk   TYPE x LENGTH 2 VALUE '504B'.
    lv_head = lv_xlsx.
    cl_abap_unit_assert=>assert_equals( act = lv_head
                                        exp = lv_pk ).

    z2ui5_cl_cgui_alv=>factory( )->set_title( `Flights` )->export( client = mo_client
                                                                  tab    = mo_app->mt_row
                                                                  format = z2ui5_cl_cgui_alv=>cs_format-xlsx ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mt_action[ 2 ]
                                        exp = `Flights.xlsx` ).

  ENDMETHOD.

  METHOD text_for_printing.

    DATA(lt_text) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_hidden( `NOTE`
        )->set_column_sum( `PRICE`
        )->set_sort( name       = `CARRID`
                     descending = abap_true
        )->to_text( mo_app->mt_row ).

    " header, rule, three rows, rule, totals
    cl_abap_unit_assert=>assert_equals( act = lines( lt_text )
                                        exp = 7 ).
    cl_abap_unit_assert=>assert_char_cp( act = lt_text[ 3 ]
                                         exp = `UA *` ).
    cl_abap_unit_assert=>assert_false( xsdbool( lt_text[ 3 ] CS `say` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lt_text[ 7 ] CS `600` ) ).

  ENDMETHOD.

  METHOD paging.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( )->set_paging( 2 ).

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
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->set_title( `Flights` )->set_sort( name       = `PRICE`
                                              descending = abap_true ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row
                    total  = 5 ).
    DATA(lv_view) = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `Flights (5)` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `Page 3 of 3` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `rows="{/MT_ROW}"` ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 2 ).
    " the sort of the layout is the order the server applies
    cl_abap_unit_assert=>assert_equals( act = mo_client->mt_window_sort
                                        exp = VALUE z2ui5_if_client=>ty_t_bind_tab_sort( ( path = `PRICE` descending = abap_true ) ) ).

    lo_alv->page_turn( direction = z2ui5_cl_cgui_alv=>cs_page-first
                       lines     = 5 ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_page_offset( )
                                        exp = 0 ).

  ENDMETHOD.

  METHOD filter_rows.

    mo_app->mt_row = VALUE #( ( carrid = `LH` connid = `0400` price = 100 )
                              ( carrid = `AA` connid = `0017` price = 200 )
                              ( carrid = `LH` connid = `2402` price = 300 )
                              ( carrid = `UA` connid = `0941` price = 400 ) ).
    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( ).

    " no filter - every row
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->filter_index( mo_app->mt_row ) )
                                        exp = 4 ).

    " the semantics of a select-option, also across columns
    lo_alv->set_filter( name = `carrid`
                        rows = VALUE #( ( sign = `I` option = `EQ` low = `LH` )
                                        ( sign = `I` option = `EQ` low = `UA` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_index( ( 1 ) ( 3 ) ( 4 ) ) ).
    lo_alv->set_filter( name = `PRICE`
                        rows = VALUE #( ( sign = `I` option = `BT` low = `150` high = `350` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_index( ( 3 ) ) ).
    lo_alv->set_filter( name = `PRICE`
                        rows = VALUE #( ( sign = `E` option = `EQ` low = `100` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_index( ( 3 ) ( 4 ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_alv->get_filter( ) )
                                        exp = 2 ).

    " a value that does not fit the column
    cl_abap_unit_assert=>assert_not_initial( lo_alv->check_filter(
        name = `FLDATE`
        rows = VALUE #( ( sign = `I` option = `EQ` low = `kein Datum` ) )
        tab  = mo_app->mt_row ) ).

    " a pattern
    lo_alv->clear_filter( ).
    lo_alv->set_filter( name = `CONNID`
                        rows = VALUE #( ( sign = `I` option = `EQ` low = `0*` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_index( ( 1 ) ( 2 ) ( 4 ) ) ).

    " the toolbar counts the filters and shows the rows of all
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->set_title( `Flights` )->render( node   = lo_view
                                            client = mo_client
                                            tab    = mo_app->mt_row
                                            total  = 3
                                            all    = 4 ).
    DATA(lv_view) = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `Flights (3 of 4)` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS z2ui5_cl_cgui_alv=>cs_event-filter_clear ) ).

  ENDMETHOD.

  METHOD colors_and_header.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( z2ui5_cl_cgui_alv=>cs_color-positive )
                                        exp = `Success` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( `C610` )
                                        exp = `Error` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_alv=>color_state( `` )
                                        exp = `None` ).

    mo_app->mt_row = VALUE #( ( carrid = `LH` note = `C500` price = 1 ) ).
    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory(
        )->set_color_field( `NOTE`
        )->set_column_color( name  = `PRICE`
                             color = z2ui5_cl_cgui_alv=>cs_color-negative
        )->add_header( `Flight Report`
        )->add_header( label = `Airline`
                       value = `LH` ).
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).
    DATA(lv_view) = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `RowSettings` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `ObjectStatus` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `Flight Report` ) ).
    " the color field is no column
    DATA(lt_layout) = lo_alv->get_layout( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( lt_layout[ name = `NOTE` ] ) ) ).

    DATA(lt_text) = lo_alv->to_text( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 1 ]
                                        exp = `Flight Report` ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 2 ]
                                        exp = `Airline: LH` ).

  ENDMETHOD.

  METHOD columns_and_cell_types.

    mo_app->mt_row = VALUE #( ( carrid = `LH` connid = `0000` price = 0 note = `A` )
                              ( carrid = `AA` connid = `0017` price = 5 note = `B` ) ).
    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory(
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
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).
    DATA(lv_view) = lo_view->stringify( ).

    " the event on the table, not on the row settings
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<table:Table *cellClick=*fixedColumnCount="1"*<table:rowSettingsTemplate*` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `The airline` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `Number(${PRICE}) !== 0` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `FLDATE` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `hAlign="Center"` ) ).
    " the technical column is in no layout and no export
    DATA(lt_layout) = lo_alv->get_layout( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( lt_layout[ name = `FLDATE` ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lo_alv->to_csv( mo_app->mt_row ) CS `FLDATE` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `<Button text="{CONNID}"` ) ).
    " a button is no input - a clickable checkbox makes the grid hand its rows back
    cl_abap_unit_assert=>assert_false( lo_alv->is_editable( ) ).
    lo_alv->set_column_cell_type( name = `PRICE`
                                  type = z2ui5_cl_cgui_alv=>cs_cell_type-checkbox_hotspot ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_editable( ) ).

    " dropdown: the text shown, a Select in edit mode, editable per row
    DATA(lo_edit) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_dropdown( name   = `CARRID`
                                values = VALUE #( ( key = `LH` text = `Lufthansa` )
                                                  ( key = `AA` text = `American` ) ) ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_edit->render( node   = lo_view
                     client = mo_client
                     tab    = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_true( xsdbool( lo_view->stringify( ) CS `'LH' ? 'Lufthansa'` ) ).
    lo_edit->set_edit( )->set_edit_field( `ZZSELKZ` ).
    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_edit->render( node   = lo_view
                     client = mo_client
                     tab    = mo_app->mt_row ).
    lv_view = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Select *selectedKey="{CARRID}"*enabled="{= ${ZZSELKZ} === true*` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `editable="{= ${ZZSELKZ}` ) ).

  ENDMETHOD.

  METHOD aggregates_search_single.

    mo_app->mt_row = VALUE #( ( carrid = `LH` price = 10 note = `x` )
                              ( carrid = `AA` price = 30 )
                              ( carrid = `LH` price = 20 ) ).
    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory(
        )->set_column_aggregation( name        = `PRICE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-average
        )->set_column_aggregation( name        = `NOTE`
                                   aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-count ).
    DATA(lt_aggregate) = lo_alv->get_aggregates( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_aggregate[ column = `PRICE` ]-value
                                        exp = 20 ).
    cl_abap_unit_assert=>assert_equals( act = lt_aggregate[ column = `NOTE` ]-value
                                        exp = 1 ).
    lo_alv->set_column_aggregation( name        = `PRICE`
                                    aggregation = z2ui5_cl_cgui_alv=>cs_aggregation-maximum ).
    lt_aggregate = lo_alv->get_aggregates( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_aggregate[ column = `PRICE` ]-value
                                        exp = 30 ).

    " the search finds the text in a column shown
    lo_alv->set_search( `aa` ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->filter_index( mo_app->mt_row )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_index( ( 2 ) ) ).
    cl_abap_unit_assert=>assert_true( lo_alv->is_filtered( ) ).
    lo_alv->set_search( `` ).

    " single selection: the row selected last stays
    lo_alv->set_selection_mode( val = z2ui5_cl_cgui_alv=>cs_selection_mode-single ).
    lo_alv->set_selected_rows( EXPORTING rows = VALUE #( ( 1 ) )
                               CHANGING  tab  = mo_app->mt_row ).
    mo_app->mt_row[ 3 ]-zzselkz = abap_true.
    lo_alv->single_normalize( CHANGING tab = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_selected_rows( mo_app->mt_row )
                                        exp = VALUE z2ui5_cl_cgui_alv=>ty_t_row( ( 3 ) ) ).

    " details of the row selected, footer on the printout
    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-details.
    cl_abap_unit_assert=>assert_true( lo_alv->handle_event( EXPORTING client = mo_client
                                                            CHANGING  tab    = mo_app->mt_row ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_client->mv_popup CS `Details` ) ).
    mo_client->mv_event = z2ui5_cl_cgui_alv=>cs_event-details_close.
    lo_alv->handle_event( EXPORTING client = mo_client
                          CHANGING  tab    = mo_app->mt_row ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).
    lo_alv->add_footer( label = `Created by`
                        value = `Nova` ).
    DATA(lt_text) = lo_alv->to_text( mo_app->mt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ lines( lt_text ) ]
                                        exp = `Created by: Nova` ).

  ENDMETHOD.

  METHOD f4_in_cells.

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( )->set_edit( )->set_column_f4( `CARRID` ).
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_alv->render( node   = lo_view
                    client = mo_client
                    tab    = mo_app->mt_row ).
    DATA(lv_view) = lo_view->stringify( ).
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
    DATA lt_flight TYPE STANDARD TABLE OF ty_s_flight WITH EMPTY KEY.
    DATA lt_fcat   TYPE STANDARD TABLE OF ty_s_fcat WITH EMPTY KEY.
    DATA ls_layout TYPE ty_s_layo.
    DATA lt_sort   TYPE STANDARD TABLE OF ty_s_sort WITH EMPTY KEY.

    lt_flight = VALUE #( ( carrid = `LH` seats = 10 price = `100.00` )
                         ( carrid = `AA` seats = 20 price = `300.00` ) ).
    " the field catalog as the LVC functions take it
    lt_fcat = VALUE #( ( fieldname = 'CARRID' scrtext_l = 'Airline' key = abap_true )
                       ( fieldname = 'SEATS'  coltext = 'Seats' do_sum = abap_true )
                       ( fieldname = 'PRICE'  scrtext_m = 'Price' outputlen = 12 )
                       ( fieldname = 'SEL'    tech = abap_true ) ).
    ls_layout = VALUE #( zebra = abap_true cwidth_opt = abap_true box_fname = 'SEL' grid_title = 'Flights' ).
    lt_sort = VALUE #( ( fieldname = 'PRICE' down = abap_true ) ).

    DATA(lo_alv) = z2ui5_cl_cgui_alv=>factory( )->set_fieldcat( lt_fcat
        )->set_layout_classic( ls_layout
        )->set_sort_classic( lt_sort ).

    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_selection_mode( )
                                        exp = z2ui5_cl_cgui_alv=>cs_selection_mode-multiple ).
    cl_abap_unit_assert=>assert_equals( act = lo_alv->get_box_field( )
                                        exp = `SEL` ).
    DATA(lv_text) = concat_lines_of( table = lo_alv->to_text( lt_flight ) sep = `|` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_text
                                         exp = `*Airline*Seats*Price*` ).
    " the technical box field is not shown
    cl_abap_unit_assert=>assert_char_np( act = lv_text
                                         exp = `*SEL*` ).
    " sorted by the price downwards, the seats summed up
    FIND `AA` IN lv_text MATCH OFFSET DATA(lv_aa).
    FIND `LH` IN lv_text MATCH OFFSET DATA(lv_lh).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_aa < lv_lh ) ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_text
                                         exp = `*30*` ).

  ENDMETHOD.

ENDCLASS.
