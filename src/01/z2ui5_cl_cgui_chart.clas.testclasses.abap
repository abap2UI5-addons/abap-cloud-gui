CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
        booked TYPE i,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    METHODS summed_and_sorted FOR TESTING.
    METHODS the_rest_as_other FOR TESTING.
    METHODS svg_of_the_bars FOR TESTING.
    METHODS several_series FOR TESTING.
    METHODS kinds_of_chart FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD summed_and_sorted.

    DATA(lt_bar) = z2ui5_cl_cgui_chart=>bars( tab      = VALUE ty_t_row( ( carrid = 'LH' seats = 10 )
                                                                         ( carrid = 'AA' seats = 30 )
                                                                         ( carrid = 'LH' seats = 25 ) )
                                              category = `CARRID`
                                              value    = `SEATS` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_bar )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_bar[ 1 ]-label
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_equals( act = lt_bar[ 1 ]-value
                                        exp = 35 ).

    " no value column: the rows counted
    lt_bar = z2ui5_cl_cgui_chart=>bars( tab      = VALUE ty_t_row( ( carrid = 'LH' ) ( carrid = 'AA' ) ( carrid = 'LH' ) )
                                        category = `CARRID`
                                        value    = `` ).
    cl_abap_unit_assert=>assert_equals( act = lt_bar[ 1 ]-value
                                        exp = 2 ).

  ENDMETHOD.

  METHOD the_rest_as_other.

    DATA lt_row TYPE ty_t_row.

    DO 25 TIMES.
      INSERT VALUE #( carrid = |{ sy-index }| seats = 100 - sy-index ) INTO TABLE lt_row.
    ENDDO.
    DATA(lt_bar) = z2ui5_cl_cgui_chart=>bars( tab      = lt_row
                                              category = `CARRID`
                                              value    = `SEATS` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_bar )
                                        exp = z2ui5_cl_cgui_chart=>cv_max_bars + 1 ).
    " the five smallest: 79 + 78 + 77 + 76 + 75
    cl_abap_unit_assert=>assert_equals( act = lt_bar[ lines( lt_bar ) ]-value
                                        exp = 385 ).
    cl_abap_unit_assert=>assert_equals( act = lt_bar[ lines( lt_bar ) ]-label
                                        exp = `Other` ).

  ENDMETHOD.

  METHOD several_series.

    " two value columns: a value per series and category, sorted by the first
    DATA(lt_point) = z2ui5_cl_cgui_chart=>series( tab      = VALUE ty_t_row( ( carrid = 'LH' seats = 10 booked = 4 )
                                                                             ( carrid = 'AA' seats = 30 booked = 20 )
                                                                             ( carrid = 'LH' seats = 25 booked = 5 ) )
                                                  category = `CARRID`
                                                  values   = VALUE #( ( `seats` ) ( `BOOKED` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_point )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_point[ 1 ]-label
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_equals( act = lt_point[ 1 ]-values
                                        exp = VALUE z2ui5_cl_cgui_chart=>ty_t_value( ( 35 ) ( 9 ) ) ).

    " no value column: the rows counted, one series
    lt_point = z2ui5_cl_cgui_chart=>series( tab      = VALUE ty_t_row( ( carrid = 'LH' ) ( carrid = 'AA' ) ( carrid = 'LH' ) )
                                            category = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_point[ 1 ]-values
                                        exp = VALUE z2ui5_cl_cgui_chart=>ty_t_value( ( 2 ) ) ).

  ENDMETHOD.

  METHOD kinds_of_chart.

    DATA(lt_point) = VALUE z2ui5_cl_cgui_chart=>ty_t_point( ( label = `LH` values = VALUE #( ( 30 ) ( 10 ) ) sort = 30 )
                                                              ( label = `AA` values = VALUE #( ( 10 ) ( 20 ) ) sort = 10 ) ).
    DATA(lt_name) = VALUE string_table( ( `Seats` ) ( `Booked` ) ).

    " bars side by side - a legend for two series, both colours
    DATA(lv_svg) = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                                   names  = lt_name ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `>Booked</text>` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `#5899DA` AND lv_svg CS `#E8743B` ) ).

    " columns: a rect per value, the zero line
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                             names  = lt_name
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-column ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `<line ` ) ).
    FIND ALL OCCURRENCES OF `<rect ` IN lv_svg MATCH COUNT DATA(lv_rects).
    " four columns, two legend squares
    cl_abap_unit_assert=>assert_equals( act = lv_rects
                                        exp = 6 ).

    " lines: one polyline per series
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                             names  = lt_name
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-line ).
    FIND ALL OCCURRENCES OF `<polyline ` IN lv_svg MATCH COUNT DATA(lv_lines).
    cl_abap_unit_assert=>assert_equals( act = lv_lines
                                        exp = 2 ).

    " pie: the first series, a slice each with its share
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-pie ).
    FIND ALL OCCURRENCES OF `<path ` IN lv_svg MATCH COUNT DATA(lv_slices).
    cl_abap_unit_assert=>assert_equals( act = lv_slices
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `75.0 %` ) ).
    " one category is the whole circle
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = VALUE #( ( label = `LH` values = VALUE #( ( 5 ) ) ) )
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-pie ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `<circle ` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_svg CS `<script` ) ).

  ENDMETHOD.

  METHOD svg_of_the_bars.

    DATA(lv_svg) = z2ui5_cl_cgui_chart=>svg( VALUE #( ( label = `A&B` value = 20 ) ( label = `C` value = -10 ) ) ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_svg
                                         exp = `<svg *</svg>` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `A&amp;B` ) ).
    " the largest bar fills the room, the other one half of it
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `width="390"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `width="195"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_svg CS `#E8743B` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_svg CS `<script` ) ).

  ENDMETHOD.

ENDCLASS.
