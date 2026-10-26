CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    METHODS summed_and_sorted FOR TESTING.
    METHODS the_rest_as_other FOR TESTING.
    METHODS svg_of_the_bars FOR TESTING.

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
