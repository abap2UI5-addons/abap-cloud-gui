CLASS ltcl_app DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    DATA p_carrid TYPE c LENGTH 3.
    DATA p_max    TYPE i.
    DATA p_date   TYPE d.
    DATA p_flag   TYPE abap_bool.
    DATA s_date   TYPE RANGE OF d.
    DATA s_text   TYPE RANGE OF string.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS names
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS values_roundtrip FOR TESTING.
    METHODS empty_range_is_cleared FOR TESTING.
    METHODS unknown_field_is_skipped FOR TESTING.
    METHODS catalog_roundtrip FOR TESTING.
    METHODS catalog_from_garbage FOR TESTING.
    METHODS values_to_text FOR TESTING.
    METHODS storage_json FOR TESTING.
    METHODS dynamic_dates FOR TESTING.
    METHODS dynamic_value_set FOR TESTING.
    METHODS kind_of_the_attribute FOR TESTING.
    METHODS selection_table FOR TESTING.

ENDCLASS.


CLASS ltcl_app IMPLEMENTATION.
ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD names.

    DATA temp1 TYPE string_table.
    CLEAR temp1.
    INSERT `P_CARRID` INTO TABLE temp1.
    INSERT `P_MAX` INTO TABLE temp1.
    INSERT `P_DATE` INTO TABLE temp1.
    INSERT `P_FLAG` INTO TABLE temp1.
    INSERT `S_DATE` INTO TABLE temp1.
    INSERT `S_TEXT` INTO TABLE temp1.
    result = temp1.

  ENDMETHOD.

  METHOD values_roundtrip.

    DATA lo_from TYPE REF TO ltcl_app.
    DATA temp3 LIKE lo_from->s_date.
    DATA temp4 LIKE LINE OF temp3.
    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lo_to TYPE REF TO ltcl_app.
    CREATE OBJECT lo_from TYPE ltcl_app.
    lo_from->p_carrid = `LH`.
    lo_from->p_max = 50.
    lo_from->p_date = `20260105`.
    lo_from->p_flag = abap_true.

    CLEAR temp3.

    CLEAR temp4.
    temp4-sign = `I`.
    temp4-option = `BT`.
    temp4-low = `20260101`.
    temp4-high = `20260331`.
    INSERT temp4 INTO TABLE temp3.
    CLEAR temp4.
    temp4-sign = `E`.
    temp4-option = `EQ`.
    temp4-low = `20260214`.
    INSERT temp4 INTO TABLE temp3.
    lo_from->s_date = temp3.


    lt_value = z2ui5_cl_cgui_variant=>values_get( app   = lo_from
                                                        names = names( ) ).


    CREATE OBJECT lo_to TYPE ltcl_app.
    z2ui5_cl_cgui_variant=>values_set( app    = lo_to
                                       values = lt_value ).

    cl_abap_unit_assert=>assert_equals( exp = lo_from->p_carrid
                                        act = lo_to->p_carrid ).
    cl_abap_unit_assert=>assert_equals( exp = lo_from->p_max
                                        act = lo_to->p_max ).
    cl_abap_unit_assert=>assert_equals( exp = lo_from->p_date
                                        act = lo_to->p_date ).
    cl_abap_unit_assert=>assert_equals( exp = lo_from->p_flag
                                        act = lo_to->p_flag ).
    cl_abap_unit_assert=>assert_equals( exp = lo_from->s_date
                                        act = lo_to->s_date ).

  ENDMETHOD.

  METHOD empty_range_is_cleared.

    DATA lo_from TYPE REF TO ltcl_app.
    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lo_to TYPE REF TO ltcl_app.
    DATA temp5 LIKE lo_to->s_text.
    DATA temp6 LIKE LINE OF temp5.
    CREATE OBJECT lo_from TYPE ltcl_app.

    lt_value = z2ui5_cl_cgui_variant=>values_get( app   = lo_from
                                                        names = names( ) ).


    CREATE OBJECT lo_to TYPE ltcl_app.

    CLEAR temp5.

    temp6-sign = `I`.
    temp6-option = `CP`.
    temp6-low = `A*`.
    INSERT temp6 INTO TABLE temp5.
    lo_to->s_text = temp5.
    z2ui5_cl_cgui_variant=>values_set( app    = lo_to
                                       values = lt_value ).

    cl_abap_unit_assert=>assert_initial( lo_to->s_text ).

  ENDMETHOD.

  METHOD kind_of_the_attribute.

    " SUBMIT ... WITH s_date = '20260101' WITH p_max NE 3: the caller names
    " a select-option like a parameter, and a parameter with an option
    DATA lo_to TYPE REF TO ltcl_app.
    DATA temp7 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp8 LIKE LINE OF temp7.
    DATA lt_exp LIKE lo_to->s_date.
    DATA temp9 LIKE lt_exp.
    DATA temp10 LIKE LINE OF temp9.
    CREATE OBJECT lo_to TYPE ltcl_app.

    CLEAR temp7.

    CLEAR temp8.
    temp8-name = `S_DATE`.
    temp8-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
    temp8-low = `20260101`.
    INSERT temp8 INTO TABLE temp7.
    CLEAR temp8.
    temp8-name = `P_MAX`.
    temp8-kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
    temp8-sign = `I`.
    temp8-option = `NE`.
    temp8-low = `3`.
    INSERT temp8 INTO TABLE temp7.
    z2ui5_cl_cgui_variant=>values_set(
        app    = lo_to
        values = temp7 ).



    CLEAR temp9.

    temp10-sign = `I`.
    temp10-option = `EQ`.
    temp10-low = `20260101`.
    INSERT temp10 INTO TABLE temp9.
    lt_exp = temp9.
    cl_abap_unit_assert=>assert_equals( exp = lt_exp
                                        act = lo_to->s_date ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_to->p_max ).

  ENDMETHOD.

  METHOD selection_table.

    TYPES:
      BEGIN OF ty_s_rspar,
        selname TYPE c LENGTH 8,
        kind    TYPE c LENGTH 1,
        sign    TYPE c LENGTH 1,
        option  TYPE c LENGTH 2,
        low     TYPE c LENGTH 45,
        high    TYPE c LENGTH 45,
      END OF ty_s_rspar.
    DATA lt_rspar TYPE STANDARD TABLE OF ty_s_rspar WITH DEFAULT KEY.

    DATA temp11 LIKE lt_rspar.
    DATA temp12 LIKE LINE OF temp11.
    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lo_to TYPE REF TO ltcl_app.
    DATA lt_exp LIKE lo_to->s_date.
    DATA temp13 LIKE lt_exp.
    DATA temp14 LIKE LINE OF temp13.
    CLEAR temp11.

    CLEAR temp12.
    temp12-selname = 'P_CARRID'.
    temp12-kind = 'P'.
    temp12-sign = 'I'.
    temp12-option = 'EQ'.
    temp12-low = 'LH'.
    INSERT temp12 INTO TABLE temp11.
    CLEAR temp12.
    temp12-selname = 'S_DATE'.
    temp12-kind = 'S'.
    temp12-sign = 'I'.
    temp12-option = 'BT'.
    temp12-low = '20260101'.
    temp12-high = '20260131'.
    INSERT temp12 INTO TABLE temp11.
    CLEAR temp12.
    temp12-selname = 's_date'.
    temp12-kind = 'S'.
    temp12-sign = 'E'.
    temp12-option = 'EQ'.
    temp12-low = '20260115'.
    INSERT temp12 INTO TABLE temp11.
    CLEAR temp12.
    temp12-kind = 'P'.
    temp12-low = 'skipped'.
    INSERT temp12 INTO TABLE temp11.
    lt_rspar = temp11.


    lt_value = z2ui5_cl_cgui_variant=>selection_table_get( lt_rspar ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_value ) ).


    CREATE OBJECT lo_to TYPE ltcl_app.
    z2ui5_cl_cgui_variant=>values_set( app    = lo_to
                                       values = lt_value ).
    cl_abap_unit_assert=>assert_equals( exp = `LH`
                                        act = lo_to->p_carrid ).


    CLEAR temp13.

    CLEAR temp14.
    temp14-sign = `I`.
    temp14-option = `BT`.
    temp14-low = `20260101`.
    temp14-high = `20260131`.
    INSERT temp14 INTO TABLE temp13.
    CLEAR temp14.
    temp14-sign = `E`.
    temp14-option = `EQ`.
    temp14-low = `20260115`.
    INSERT temp14 INTO TABLE temp13.
    lt_exp = temp13.
    cl_abap_unit_assert=>assert_equals( exp = lt_exp
                                        act = lo_to->s_date ).

  ENDMETHOD.

  METHOD unknown_field_is_skipped.

    DATA lo_to TYPE REF TO ltcl_app.
    DATA temp15 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp16 LIKE LINE OF temp15.
    CREATE OBJECT lo_to TYPE ltcl_app.

    CLEAR temp15.

    temp16-name = `P_GONE`.
    temp16-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
    temp16-low = `X`.
    INSERT temp16 INTO TABLE temp15.
    temp16-name = `P_MAX`.
    temp16-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
    temp16-low = `7`.
    INSERT temp16 INTO TABLE temp15.
    z2ui5_cl_cgui_variant=>values_set(
        app    = lo_to
        values = temp15 ).

    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = lo_to->p_max ).

  ENDMETHOD.

  METHOD catalog_roundtrip.

    DATA temp17 TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp18 LIKE LINE OF temp17.
    DATA temp1 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp2 LIKE LINE OF temp1.
    DATA lt_variant LIKE temp17.
    DATA lv_string TYPE string.
    CLEAR temp17.

    CLEAR temp18.
    temp18-name = `Q1 "LH"`.
    temp18-text = `P_CARRID = LH`.

    CLEAR temp1.

    CLEAR temp2.
    temp2-name = `P_CARRID`.
    temp2-kind = `P`.
    temp2-low = `LH`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-name = `S_DATE`.
    temp2-kind = `S`.
    temp2-sign = `I`.
    temp2-option = `BT`.
    temp2-low = `20260101`.
    temp2-high = `20260331`.
    INSERT temp2 INTO TABLE temp1.
    temp18-values = temp1.
    INSERT temp18 INTO TABLE temp17.
    CLEAR temp18.
    temp18-name = `Empty`.
    INSERT temp18 INTO TABLE temp17.

    lt_variant = temp17.


    lv_string = z2ui5_cl_cgui_variant=>catalog_to_string( lt_variant ).
    cl_abap_unit_assert=>assert_not_initial( lv_string ).

    cl_abap_unit_assert=>assert_equals( exp = lt_variant
                                        act = z2ui5_cl_cgui_variant=>catalog_from_string( lv_string ) ).

  ENDMETHOD.

  METHOD catalog_from_garbage.

    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_variant=>catalog_from_string( `not a catalog` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_variant=>catalog_from_string( `` ) ).

  ENDMETHOD.

  METHOD values_to_text.

    DATA temp19 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp20 LIKE LINE OF temp19.
    DATA temp3 TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA temp4 LIKE LINE OF temp3.
    DATA lv_text TYPE string.
    CLEAR temp19.

    CLEAR temp20.
    temp20-name = `P_CARRID`.
    temp20-kind = `P`.
    temp20-low = `LH`.
    INSERT temp20 INTO TABLE temp19.
    CLEAR temp20.
    temp20-name = `P_EMPTY`.
    temp20-kind = `P`.
    INSERT temp20 INTO TABLE temp19.
    CLEAR temp20.
    temp20-name = `S_DATE`.
    temp20-kind = `S`.
    temp20-sign = `I`.
    temp20-option = `BT`.
    temp20-low = `1`.
    temp20-high = `2`.
    INSERT temp20 INTO TABLE temp19.
    CLEAR temp20.
    temp20-name = `S_DATE`.
    temp20-kind = `S`.
    temp20-sign = `E`.
    temp20-option = `EQ`.
    temp20-low = `3`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp3.

    temp4-name = `P_CARRID`.
    temp4-text = `Airline`.
    INSERT temp4 INTO TABLE temp3.

    lv_text = z2ui5_cl_cgui_variant=>values_to_text(
        values = temp19
        fields = temp3 ).

    cl_abap_unit_assert=>assert_equals( exp = `Airline = LH, S_DATE BT 1 - 2, S_DATE EQ 3 (excl.)`
                                        act = lv_text ).

  ENDMETHOD.

  METHOD storage_json.

    cl_abap_unit_assert=>assert_equals(
        exp = `{"TYPE":"local","PREFIX":"p","KEY":"K","VALUE":"a\"b\\c\nd"}`
        act = z2ui5_cl_cgui_variant=>storage_json( prefix = `p`
                                                   key    = `K`
                                                   val    = |a"b\\c\nd| ) ).

  ENDMETHOD.

  METHOD dynamic_dates.

    DATA temp21 TYPE d.
    DATA lv_today LIKE temp21.
    DATA temp22 TYPE d.
    DATA temp23 TYPE d.
    DATA temp24 TYPE d.
    DATA temp25 TYPE d.
    DATA temp26 TYPE d.
    DATA temp27 TYPE d.
    DATA temp28 TYPE d.
    temp21 = `20260215`.

    lv_today = temp21.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `TODAY` today = lv_today )
                                        exp = lv_today ).

    temp22 = `20260214`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `today-1` today = lv_today )
                                        exp = temp22 ).

    temp23 = `20260307`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `TODAY+20` today = lv_today )
                                        exp = temp23 ).

    temp24 = `20260201`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `MONTH_START` today = lv_today )
                                        exp = temp24 ).

    temp25 = `20260228`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `MONTH_END` today = lv_today )
                                        exp = temp25 ).

    temp26 = `20260101`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `PREV_MONTH_START` today = lv_today )
                                        exp = temp26 ).

    temp27 = `20260131`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `PREV_MONTH_END` today = lv_today )
                                        exp = temp27 ).

    temp28 = `20261231`.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `YEAR_END` today = lv_today )
                                        exp = temp28 ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `NONSENSE` today = lv_today ) ).

  ENDMETHOD.

  METHOD dynamic_value_set.

    DATA lo_app TYPE REF TO ltcl_app.
    DATA temp29 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp30 LIKE LINE OF temp29.
    FIELD-SYMBOLS <temp31> LIKE LINE OF lo_app->s_date.
    DATA temp32 LIKE sy-tabix.
    FIELD-SYMBOLS <temp33> LIKE LINE OF lo_app->s_date.
    DATA temp34 LIKE sy-tabix.
    CREATE OBJECT lo_app TYPE ltcl_app.

    CLEAR temp29.

    CLEAR temp30.
    temp30-name = `P_DATE`.
    temp30-kind = `P`.
    temp30-low = `19990101`.
    temp30-dynamic = `TODAY`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-name = `S_DATE`.
    temp30-kind = `S`.
    temp30-sign = `I`.
    temp30-option = `BT`.
    temp30-dynamic = `MONTH_START`.
    temp30-dynamic_high = `MONTH_END`.
    INSERT temp30 INTO TABLE temp29.
    z2ui5_cl_cgui_variant=>values_set(
        app    = lo_app
        values = temp29 ).

    cl_abap_unit_assert=>assert_equals( act = lo_app->p_date
                                        exp = sy-datum ).


    temp32 = sy-tabix.
    READ TABLE lo_app->s_date INDEX 1 ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp31>-low
                                        exp = z2ui5_cl_cgui_variant=>dynamic_date( `MONTH_START` ) ).


    temp34 = sy-tabix.
    READ TABLE lo_app->s_date INDEX 1 ASSIGNING <temp33>.
    sy-tabix = temp34.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp33>-high
                                        exp = z2ui5_cl_cgui_variant=>dynamic_date( `MONTH_END` ) ).

  ENDMETHOD.

ENDCLASS.
