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
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    METHODS summed_and_sorted FOR TESTING.
    METHODS the_rest_as_other FOR TESTING.
    METHODS svg_of_the_bars FOR TESTING.
    METHODS several_series FOR TESTING.
    METHODS kinds_of_chart FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD summed_and_sorted.

    DATA temp1 TYPE ty_t_row.
    DATA temp2 LIKE LINE OF temp1.
    DATA lt_bar TYPE z2ui5_cl_cgui_chart=>ty_t_bar.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_bar.
    DATA temp4 LIKE sy-tabix.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_bar.
    DATA temp6 LIKE sy-tabix.
    DATA temp7 TYPE ty_t_row.
    DATA temp8 LIKE LINE OF temp7.
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_bar.
    DATA temp10 LIKE sy-tabix.
    CLEAR temp1.

    temp2-carrid = 'LH'.
    temp2-seats = 10.
    INSERT temp2 INTO TABLE temp1.
    temp2-carrid = 'AA'.
    temp2-seats = 30.
    INSERT temp2 INTO TABLE temp1.
    temp2-carrid = 'LH'.
    temp2-seats = 25.
    INSERT temp2 INTO TABLE temp1.

    lt_bar = z2ui5_cl_cgui_chart=>bars( tab      = temp1
                                              category = `CARRID`
                                              value    = `SEATS` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_bar )
                                        exp = 2 ).


    temp4 = sy-tabix.
    READ TABLE lt_bar INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp3>-label
                                        exp = `LH` ).


    temp6 = sy-tabix.
    READ TABLE lt_bar INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp5>-value
                                        exp = 35 ).

    " no value column: the rows counted

    CLEAR temp7.

    temp8-carrid = 'LH'.
    INSERT temp8 INTO TABLE temp7.
    temp8-carrid = 'AA'.
    INSERT temp8 INTO TABLE temp7.
    temp8-carrid = 'LH'.
    INSERT temp8 INTO TABLE temp7.
    lt_bar = z2ui5_cl_cgui_chart=>bars( tab      = temp7
                                        category = `CARRID`
                                        value    = `` ).


    temp10 = sy-tabix.
    READ TABLE lt_bar INDEX 1 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp9>-value
                                        exp = 2 ).

  ENDMETHOD.

  METHOD the_rest_as_other.

    DATA lt_row TYPE ty_t_row.
      DATA temp11 TYPE ltcl_test=>ty_s_row.
    DATA lt_bar TYPE z2ui5_cl_cgui_chart=>ty_t_bar.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lt_bar.
    DATA temp13 LIKE sy-tabix.
    FIELD-SYMBOLS <temp14> LIKE LINE OF lt_bar.
    DATA temp15 LIKE sy-tabix.

    DO 25 TIMES.

      CLEAR temp11.
      temp11-carrid = |{ sy-index }|.
      temp11-seats = 100 - sy-index.
      INSERT temp11 INTO TABLE lt_row.
    ENDDO.

    lt_bar = z2ui5_cl_cgui_chart=>bars( tab      = lt_row
                                              category = `CARRID`
                                              value    = `SEATS` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_bar )
                                        exp = z2ui5_cl_cgui_chart=>cv_max_bars + 1 ).
    " the five smallest: 79 + 78 + 77 + 76 + 75


    temp13 = sy-tabix.
    READ TABLE lt_bar INDEX lines( lt_bar ) ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp12>-value
                                        exp = 385 ).


    temp15 = sy-tabix.
    READ TABLE lt_bar INDEX lines( lt_bar ) ASSIGNING <temp14>.
    sy-tabix = temp15.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp14>-label
                                        exp = `Other` ).

  ENDMETHOD.

  METHOD several_series.

    " two value columns: a value per series and category, sorted by the first
    DATA temp16 TYPE ty_t_row.
    DATA temp17 LIKE LINE OF temp16.
    DATA temp1 TYPE string_table.
    DATA lt_point TYPE z2ui5_cl_cgui_chart=>ty_t_point.
    FIELD-SYMBOLS <temp18> LIKE LINE OF lt_point.
    DATA temp19 LIKE sy-tabix.
    DATA temp20 TYPE z2ui5_cl_cgui_chart=>ty_t_value.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_point.
    DATA temp4 LIKE sy-tabix.
    DATA temp22 TYPE ty_t_row.
    DATA temp23 LIKE LINE OF temp22.
    DATA temp24 TYPE z2ui5_cl_cgui_chart=>ty_t_value.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_point.
    DATA temp6 LIKE sy-tabix.
    CLEAR temp16.

    temp17-carrid = 'LH'.
    temp17-seats = 10.
    temp17-booked = 4.
    INSERT temp17 INTO TABLE temp16.
    temp17-carrid = 'AA'.
    temp17-seats = 30.
    temp17-booked = 20.
    INSERT temp17 INTO TABLE temp16.
    temp17-carrid = 'LH'.
    temp17-seats = 25.
    temp17-booked = 5.
    INSERT temp17 INTO TABLE temp16.

    CLEAR temp1.
    INSERT `seats` INTO TABLE temp1.
    INSERT `BOOKED` INTO TABLE temp1.

    lt_point = z2ui5_cl_cgui_chart=>series( tab      = temp16
                                                  category = `CARRID`
                                                  values   = temp1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_point )
                                        exp = 2 ).


    temp19 = sy-tabix.
    READ TABLE lt_point INDEX 1 ASSIGNING <temp18>.
    sy-tabix = temp19.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp18>-label
                                        exp = `LH` ).

    CLEAR temp20.
    INSERT 35 INTO TABLE temp20.
    INSERT 9 INTO TABLE temp20.


    temp4 = sy-tabix.
    READ TABLE lt_point INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp3>-values
                                        exp = temp20 ).

    " no value column: the rows counted, one series

    CLEAR temp22.

    temp23-carrid = 'LH'.
    INSERT temp23 INTO TABLE temp22.
    temp23-carrid = 'AA'.
    INSERT temp23 INTO TABLE temp22.
    temp23-carrid = 'LH'.
    INSERT temp23 INTO TABLE temp22.
    lt_point = z2ui5_cl_cgui_chart=>series( tab      = temp22
                                            category = `CARRID` ).

    CLEAR temp24.
    INSERT 2 INTO TABLE temp24.


    temp6 = sy-tabix.
    READ TABLE lt_point INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp5>-values
                                        exp = temp24 ).

  ENDMETHOD.

  METHOD kinds_of_chart.

    DATA temp26 TYPE z2ui5_cl_cgui_chart=>ty_t_point.
    DATA temp27 LIKE LINE OF temp26.
    DATA temp7 TYPE z2ui5_cl_cgui_chart=>ty_t_value.
    DATA temp9 TYPE z2ui5_cl_cgui_chart=>ty_t_value.
    DATA lt_point LIKE temp26.
    DATA temp28 TYPE string_table.
    DATA lt_name LIKE temp28.
    DATA lv_svg TYPE string.
    DATA temp1 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
    DATA temp3 TYPE xsdboolean.
    DATA lv_rects TYPE i.
    DATA lv_lines TYPE i.
    DATA lv_slices TYPE i.
    DATA temp4 TYPE xsdboolean.
    DATA temp30 TYPE z2ui5_cl_cgui_chart=>ty_t_point.
    DATA temp31 LIKE LINE OF temp30.
    DATA temp11 TYPE z2ui5_cl_cgui_chart=>ty_t_value.
    DATA temp5 TYPE xsdboolean.
    DATA temp6 TYPE xsdboolean.
    CLEAR temp26.

    temp27-label = `LH`.

    CLEAR temp7.
    INSERT 30 INTO TABLE temp7.
    INSERT 10 INTO TABLE temp7.
    temp27-values = temp7.
    temp27-sort = 30.
    INSERT temp27 INTO TABLE temp26.
    temp27-label = `AA`.

    CLEAR temp9.
    INSERT 10 INTO TABLE temp9.
    INSERT 20 INTO TABLE temp9.
    temp27-values = temp9.
    temp27-sort = 10.
    INSERT temp27 INTO TABLE temp26.

    lt_point = temp26.

    CLEAR temp28.
    INSERT `Seats` INTO TABLE temp28.
    INSERT `Booked` INTO TABLE temp28.

    lt_name = temp28.

    " bars side by side - a legend for two series, both colours

    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                                   names  = lt_name ).

    temp1 = boolc( lv_svg CS `>Booked</text>` ).
    cl_abap_unit_assert=>assert_true( temp1 ).

    temp2 = boolc( lv_svg CS `#5899DA` AND lv_svg CS `#E8743B` ).
    cl_abap_unit_assert=>assert_true( temp2 ).

    " columns: a rect per value, the zero line
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                             names  = lt_name
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-column ).

    temp3 = boolc( lv_svg CS `<line ` ).
    cl_abap_unit_assert=>assert_true( temp3 ).

    FIND ALL OCCURRENCES OF `<rect ` IN lv_svg MATCH COUNT lv_rects.
    " four columns, two legend squares
    cl_abap_unit_assert=>assert_equals( act = lv_rects
                                        exp = 6 ).

    " lines: one polyline per series
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                             names  = lt_name
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-line ).

    FIND ALL OCCURRENCES OF `<polyline ` IN lv_svg MATCH COUNT lv_lines.
    cl_abap_unit_assert=>assert_equals( act = lv_lines
                                        exp = 2 ).

    " pie: the first series, a slice each with its share
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-pie ).

    FIND ALL OCCURRENCES OF `<path ` IN lv_svg MATCH COUNT lv_slices.
    cl_abap_unit_assert=>assert_equals( act = lv_slices
                                        exp = 2 ).

    temp4 = boolc( lv_svg CS `75.0 %` ).
    cl_abap_unit_assert=>assert_true( temp4 ).
    " one category is the whole circle

    CLEAR temp30.

    temp31-label = `LH`.

    CLEAR temp11.
    INSERT 5 INTO TABLE temp11.
    temp31-values = temp11.
    INSERT temp31 INTO TABLE temp30.
    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = temp30
                                             kind   = z2ui5_cl_cgui_chart=>cs_kind-pie ).

    temp5 = boolc( lv_svg CS `<circle ` ).
    cl_abap_unit_assert=>assert_true( temp5 ).

    temp6 = boolc( lv_svg CS `<script` ).
    cl_abap_unit_assert=>assert_false( temp6 ).

  ENDMETHOD.

  METHOD svg_of_the_bars.

    DATA temp32 TYPE z2ui5_cl_cgui_chart=>ty_t_bar.
    DATA temp33 LIKE LINE OF temp32.
    DATA lv_svg TYPE string.
    DATA temp7 TYPE xsdboolean.
    DATA temp8 TYPE xsdboolean.
    DATA temp9 TYPE xsdboolean.
    DATA temp10 TYPE xsdboolean.
    DATA temp11 TYPE xsdboolean.
    CLEAR temp32.

    temp33-label = `A&B`.
    temp33-value = 20.
    INSERT temp33 INTO TABLE temp32.
    temp33-label = `C`.
    temp33-value = -10.
    INSERT temp33 INTO TABLE temp32.

    lv_svg = z2ui5_cl_cgui_chart=>svg( temp32 ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_svg
                                         exp = `<svg *</svg>` ).

    temp7 = boolc( lv_svg CS `A&amp;B` ).
    cl_abap_unit_assert=>assert_true( temp7 ).
    " the largest bar fills the room, the other one half of it

    temp8 = boolc( lv_svg CS `width="390"` ).
    cl_abap_unit_assert=>assert_true( temp8 ).

    temp9 = boolc( lv_svg CS `width="195"` ).
    cl_abap_unit_assert=>assert_true( temp9 ).

    temp10 = boolc( lv_svg CS `#E8743B` ).
    cl_abap_unit_assert=>assert_true( temp10 ).

    temp11 = boolc( lv_svg CS `<script` ).
    cl_abap_unit_assert=>assert_false( temp11 ).

  ENDMETHOD.

ENDCLASS.
