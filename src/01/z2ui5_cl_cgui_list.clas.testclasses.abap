CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = |\{/INPUTS/{ tab_index - 1 }\}|.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS write_lines FOR TESTING.
    METHODS hide_keeps_tabix FOR TESTING.
    METHODS clear FOR TESTING.
    METHODS header_repeats FOR TESTING.
    METHODS write_at_position FOR TESTING.
    METHODS hide_of_a_structure FOR TESTING.
    METHODS write_formats FOR TESTING.
    METHODS input_read_modify FOR TESTING.
    METHODS fields_by_name FOR TESTING.
    METHODS line_count_and_footer FOR TESTING.
    METHODS format_and_columns FOR TESTING.
    METHODS write_options_r10 FOR TESTING.
    METHODS pages_and_lines FOR TESTING.
    METHODS cut_from_a_line FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD write_lines.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( `a`
        )->write( `b`
        )->new_line(
        )->write( val     = `c`
                  hotspot = abap_true
                  hide    = `K1` ).

    DATA(lt_item) = lo_list->get_items( ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_item ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lt_item[ 2 ]-line ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lt_item[ 3 ]-line ).

    DATA(ls_item) = lo_list->get_item_by_line( 2 ).
    cl_abap_unit_assert=>assert_equals( exp = `c`
                                        act = ls_item-text ).
    cl_abap_unit_assert=>assert_equals( exp = `K1`
                                        act = ls_item-hide ).

  ENDMETHOD.

  METHOD hide_keeps_tabix.

    DATA lt_text TYPE string_table.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lt_text = VALUE #( ( `x` ) ( `y` ) ( `z` ) ).

    LOOP AT lt_text INTO DATA(lv_text).
      lo_list->write( val     = lv_text
                      hotspot = abap_true
                      hide    = sy-tabix
          )->new_line( ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals( exp = `3`
                                        act = lo_list->get_item_by_line( 3 )-hide ).

  ENDMETHOD.

  METHOD clear.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( `a` )->uline( ).
    lo_list->clear( ).

    cl_abap_unit_assert=>assert_initial( lo_list->get_items( ) ).

  ENDMETHOD.

  METHOD header_repeats.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->header_begin( ).
    lo_list->write( `HEAD` ).
    lo_list->header_end( ).
    cl_abap_unit_assert=>assert_false( lo_list->has_content( ) ).

    lo_list->write( `one` )->new_page( `Page 2` )->write( `two` ).
    cl_abap_unit_assert=>assert_true( lo_list->has_content( ) ).

    DATA(lv_view) = lo_list->stringify( NEW ltcl_client( ) ).
    " the header above the list and again after the page break
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*HEAD*one*Page 2*HEAD*two*` ).

  ENDMETHOD.

  METHOD hide_of_a_structure.

    TYPES:
      BEGIN OF ty_s_flight,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
        price  TYPE p LENGTH 8 DECIMALS 2,
        fldate TYPE d,
      END OF ty_s_flight.
    DATA ls_flight TYPE ty_s_flight.
    DATA ls_back   TYPE ty_s_flight.
    DATA lv_number TYPE i.

    " a structure that is no character-like one: component by component
    ls_flight = VALUE #( carrid = 'LH' seats = 120 price = '420.50' fldate = '20260105' ).
    DATA(lv_text) = z2ui5_cl_cgui_list=>hide_text( ls_flight ).
    cl_abap_unit_assert=>assert_equals( act = lv_text
                                        exp = |LH\t120\t420.50\t20260105| ).
    z2ui5_cl_cgui_list=>hide_restore( EXPORTING hide = lv_text
                                      CHANGING  val  = ls_back ).
    cl_abap_unit_assert=>assert_equals( act = ls_back
                                        exp = ls_flight ).

    " a single value as it is
    z2ui5_cl_cgui_list=>hide_restore( EXPORTING hide = z2ui5_cl_cgui_list=>hide_text( 42 )
                                      CHANGING  val  = lv_number ).
    cl_abap_unit_assert=>assert_equals( act = lv_number
                                        exp = 42 ).

  ENDMETHOD.

  METHOD write_at_position.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( val = `AB` pos = 1 len = 5
        )->write( val = `CD` pos = 10 ).

    DATA(lt_text) = lo_list->to_text( ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 1 ]
                                        exp = `AB       CD` ).

    " the items of a line with a position stand in boxes of their width, so
    " the columns line up whatever the font; a line without one flows
    lo_list->new_line( )->write( `free` ).
    DATA(lv_view) = lo_list->stringify( NEW ltcl_client( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*width="3.0em"*AB*width="2.4em"*width="1.8em"*CD*` ).
    " the two boxes, the spacer and the width of AB itself - the free line
    " has none
    cl_abap_unit_assert=>assert_equals( act = count( val = lv_view
                                                     sub = `em"` )
                                        exp = 4 ).

  ENDMETHOD.

  METHOD write_formats.

    DATA lv_zero   TYPE n LENGTH 6 VALUE '000042'.
    DATA lv_amount TYPE p LENGTH 8 DECIMALS 2 VALUE '-12.50'.
    DATA lv_count  TYPE i.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( val     = lv_zero
                    no_zero = abap_true
        )->write( val     = lv_count
                  no_zero = abap_true
        )->write( val     = lv_amount
                  no_sign = abap_true
        )->write( val         = `bold`
                  intensified = abap_true
        )->write( val     = `inv`
                  inverse = abap_true
        )->write( val     = `R`
                  len     = 3
                  justify = z2ui5_cl_cgui_list=>cs_justify-right ).

    DATA(lt_item) = lo_list->get_items( ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 1 ]-text
                                        exp = `42` ).
    cl_abap_unit_assert=>assert_initial( lt_item[ 2 ]-text ).
    cl_abap_unit_assert=>assert_false( xsdbool( lt_item[ 3 ]-text CS `-` ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->to_text( )
                                        exp = VALUE string_table( ( |42  { lt_item[ 3 ]-text } bold inv   R| ) ) ).

    DATA(lv_view) = lo_list->stringify( NEW ltcl_client( ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `design="Bold"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `inverted="true"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `textAlign="End"` ) ).

  ENDMETHOD.

  METHOD fields_by_name.

    DATA lv_check TYPE c LENGTH 1.
    DATA lv_carrid TYPE c LENGTH 3 VALUE `XX`.

    " READ LINE n FIELD VALUE: the fields written with their names
    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write_as_checkbox( val   = abap_false
                                input = abap_true
                                name  = `gv_check`
        )->write( val  = `LH`
                  name = `GS-CARRID` ).
    DATA(lt_input) = lo_list->get_inputs( ).
    lt_input[ 1 ]-flag = abap_true.
    lo_list->set_inputs( lt_input ).

    lo_list->read_field( EXPORTING  line    = 1
                                    name    = `GV_CHECK`
                         CHANGING   value   = lv_check
                         EXCEPTIONS no_line = 4 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_check
                                        exp = `X` ).
    lo_list->read_field( EXPORTING  line    = 1
                                    name    = `gs-carrid`
                         CHANGING   value   = lv_carrid
                         EXCEPTIONS no_line = 4 ).
    cl_abap_unit_assert=>assert_equals( act = lv_carrid
                                        exp = `LH` ).

    " MODIFY LINE n FIELD VALUE ... FROM
    lo_list->modify_field( EXPORTING  line    = 1
                                      name    = `GS-CARRID`
                                      value   = `UA`
                           EXCEPTIONS no_line = 4 ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->read_value( line = 1 index = 2 )
                                        exp = `UA` ).

    " no such line: sy-subrc 4, the field unchanged
    lo_list->read_field( EXPORTING  line    = 2
                                    name    = `GS-CARRID`
                         CHANGING   value   = lv_carrid
                         EXCEPTIONS no_line = 4 ).
    cl_abap_unit_assert=>assert_subrc( exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = lv_carrid
                                        exp = `LH` ).

  ENDMETHOD.

  METHOD input_read_modify.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( `Qty`
        )->write( val   = `5`
                  input = abap_true
        )->write_as_checkbox( val   = abap_false
                              input = abap_true
        )->new_line(
        )->write( `fix` ).

    DATA(lt_input) = lo_list->get_inputs( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_input )
                                        exp = 2 ).
    lt_input[ 1 ]-value = `7`.
    lt_input[ 2 ]-flag = abap_true.
    lo_list->set_inputs( lt_input ).

    cl_abap_unit_assert=>assert_equals( act = lo_list->read_value( line = 1 index = 2 )
                                        exp = `7` ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->read_value( line = 1 index = 3 )
                                        exp = `X` ).

    lo_list->modify_line( line  = 2
                          value = `changed`
                          color = z2ui5_cl_cgui_list=>cs_color-positive ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->read_value( 2 )
                                        exp = `changed` ).

    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    lo_list->render( node   = lo_view
                     client = NEW ltcl_client( )
                     inputs = lt_input ).
    DATA(lv_view) = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `<Input value="{/INPUTS/0}"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `<CheckBox selected="{/INPUTS/1}"` ) ).

  ENDMETHOD.

  METHOD line_count_and_footer.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->set_line_count( 2 ).
    lo_list->header_begin( ).
    lo_list->write( `Head` ).
    lo_list->header_end( ).
    DO 5 TIMES.
      lo_list->write( |row{ sy-index }| )->new_line( ).
    ENDDO.
    lo_list->footer_begin( ).
    lo_list->write( |Page { z2ui5_cl_cgui_list=>cv_page }| ).
    lo_list->footer_end( ).

    cl_abap_unit_assert=>assert_equals( act = lo_list->get_page_count( )
                                        exp = 3 ).
    DATA(lt_text) = lo_list->to_text( ).
    DELETE lt_text WHERE table_line IS INITIAL.
    cl_abap_unit_assert=>assert_equals( act = lt_text
                                        exp = VALUE string_table( ( `Head` ) ( `row1` ) ( `row2` ) ( `Page 1` )
                                                                  ( `Head` ) ( `row3` ) ( `row4` ) ( `Page 2` )
                                                                  ( `Head` ) ( `row5` ) ( `Page 3` ) ) ).

  ENDMETHOD.

  METHOD format_and_columns.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).

    " FORMAT holds for the WRITEs after it, a WRITE option wins
    lo_list->format( color       = z2ui5_cl_cgui_list=>cs_color-positive
                     intensified = abap_true ).
    lo_list->write( val  = `Carrier`
                    name = `carrid` ).
    lo_list->write( val   = `x`
                    color = z2ui5_cl_cgui_list=>cs_color-negative ).
    lo_list->format( reset = abap_true ).
    lo_list->write( `plain` ).
    DATA(lt_item) = lo_list->get_items( ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 1 ]-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-positive ).
    cl_abap_unit_assert=>assert_true( lt_item[ 1 ]-intensified ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-negative ).
    cl_abap_unit_assert=>assert_initial( lt_item[ 3 ]-color ).

    " columns: Carrier at 1, x at 9, plain at 11 - SY-COLNO
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-col
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->current_column( )
                                        exp = 17 ).

    " WRITE UNDER and POSITION
    lo_list->new_line( ).
    lo_list->write( val   = `LH`
                    under = `CARRID` ).
    lo_list->position( 20 ).
    lo_list->write( `at20` ).
    lt_item = lo_list->get_items( ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 4 ]-pos
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 5 ]-col
                                        exp = 20 ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->line_text( 2 )
                                        exp = `LH                 at20` ).

  ENDMETHOD.

  METHOD write_options_r10.

    DATA lv_date TYPE d VALUE '20261002'.
    DATA lv_amount TYPE p LENGTH 10 DECIMALS 2 VALUE '1234567.89'.
    DATA lv_time TYPE t VALUE '134500'.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( val       = lv_time
                    edit_mask = `__:__`
        )->write( val         = lv_date
                  date_format = z2ui5_cl_cgui_list=>cs_date_format-yymmdd
        )->write( val         = lv_amount
                  no_grouping = abap_true
        )->write( val    = `A`
                  no_gap = abap_true
        )->write( `B`
        )->write( val   = 1234500
                  round = 3
        )->write( val       = `tip`
                  quickinfo = `the tip` ).
    DATA(lt_item) = lo_list->get_items( ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 1 ]-text
                                        exp = `13:45` ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-text
                                        exp = `261002` ).
    cl_abap_unit_assert=>assert_false( xsdbool( lt_item[ 3 ]-text CA ` ` ) ).
    cl_abap_unit_assert=>assert_equals( act = strlen( lt_item[ 3 ]-text )
                                        exp = 10 ).
    " ROUND 3: 1234500 / 1000, rounded to the decimals of the type - 1,235
    cl_abap_unit_assert=>assert_true( xsdbool( lt_item[ 6 ]-text CS `235` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( strlen( lt_item[ 6 ]-text ) < 7 ) ).

    DATA(lt_text) = lo_list->to_text( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lt_text[ 1 ] CS ` AB ` ) ).

    DATA(lv_view) = lo_list->stringify( NEW ltcl_client( ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `the tip` ) ).

  ENDMETHOD.

  METHOD pages_and_lines.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->set_line_size( 20 ).
    lo_list->header_begin( ).
    lo_list->write( `HEAD` ).
    lo_list->header_end( ).
    lo_list->set_line_count( 3 ).
    lo_list->write( `1` )->new_line( )->write( `2` )->new_line( ).
    " two lines left on the page - RESERVE 3 starts a new one
    lo_list->reserve( 3 ).
    lo_list->write( `3` ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->current_page( )
                                        exp = 2 ).
    lo_list->new_page( no_heading = abap_true ).
    lo_list->write( `4` ).
    lo_list->uline( pos = 3
                    len = 5 ).

    DATA(lt_text) = lo_list->to_text( ).
    DATA lv_heads TYPE i.
    LOOP AT lt_text TRANSPORTING NO FIELDS WHERE table_line = `HEAD`.
      lv_heads = lv_heads + 1.
    ENDLOOP.
    " page 1 and 2 with the header, page 3 NO-HEADING
    cl_abap_unit_assert=>assert_equals( act = lv_heads
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_text[ table_line = `  -----` ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_list->describe_lines( )
                                        exp = 7 ).

  ENDMETHOD.

  METHOD cut_from_a_line.

    DATA(lo_list) = z2ui5_cl_cgui_list=>factory( ).
    lo_list->write( `one` ).
    lo_list->new_line( ).
    DATA(lv_from) = lo_list->current_line( ).
    lo_list->write( `two` ).
    lo_list->new_line( ).
    lo_list->write( `three` ).

    cl_abap_unit_assert=>assert_equals( exp = VALUE string_table( ( `two` ) ( `three` ) )
                                        act = lo_list->cut( lv_from ) ).
    " the list goes on where the cut started
    lo_list->write( `four` ).
    cl_abap_unit_assert=>assert_equals( exp = VALUE string_table( ( `one` ) ( `four` ) )
                                        act = lo_list->to_text( ) ).

  ENDMETHOD.

ENDCLASS.
