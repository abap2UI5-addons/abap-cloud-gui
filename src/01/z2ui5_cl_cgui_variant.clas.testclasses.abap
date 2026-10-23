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

    result = VALUE #( ( `P_CARRID` ) ( `P_MAX` ) ( `P_DATE` ) ( `P_FLAG` ) ( `S_DATE` ) ( `S_TEXT` ) ).

  ENDMETHOD.

  METHOD values_roundtrip.

    DATA(lo_from) = NEW ltcl_app( ).
    lo_from->p_carrid = `LH`.
    lo_from->p_max = 50.
    lo_from->p_date = `20260105`.
    lo_from->p_flag = abap_true.
    lo_from->s_date = VALUE #( ( sign = `I` option = `BT` low = `20260101` high = `20260331` )
                               ( sign = `E` option = `EQ` low = `20260214` ) ).

    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = lo_from
                                                        names = names( ) ).

    DATA(lo_to) = NEW ltcl_app( ).
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

    DATA(lo_from) = NEW ltcl_app( ).
    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = lo_from
                                                        names = names( ) ).

    DATA(lo_to) = NEW ltcl_app( ).
    lo_to->s_text = VALUE #( ( sign = `I` option = `CP` low = `A*` ) ).
    z2ui5_cl_cgui_variant=>values_set( app    = lo_to
                                       values = lt_value ).

    cl_abap_unit_assert=>assert_initial( lo_to->s_text ).

  ENDMETHOD.

  METHOD kind_of_the_attribute.

    " SUBMIT ... WITH s_date = '20260101' WITH p_max NE 3: the caller names
    " a select-option like a parameter, and a parameter with an option
    DATA(lo_to) = NEW ltcl_app( ).
    z2ui5_cl_cgui_variant=>values_set(
        app    = lo_to
        values = VALUE #( ( name = `S_DATE` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = `20260101` )
                          ( name = `P_MAX` kind = z2ui5_cl_cgui_variant=>cs_kind-select_option sign = `I` option = `NE` low = `3` ) ) ).

    DATA lt_exp LIKE lo_to->s_date.
    lt_exp = VALUE #( ( sign = `I` option = `EQ` low = `20260101` ) ).
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

    lt_rspar = VALUE #( ( selname = 'P_CARRID' kind = 'P' sign = 'I' option = 'EQ' low = 'LH' )
                        ( selname = 'S_DATE' kind = 'S' sign = 'I' option = 'BT' low = '20260101' high = '20260131' )
                        ( selname = 's_date' kind = 'S' sign = 'E' option = 'EQ' low = '20260115' )
                        ( kind = 'P' low = 'skipped' ) ).

    DATA(lt_value) = z2ui5_cl_cgui_variant=>selection_table_get( lt_rspar ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_value ) ).

    DATA(lo_to) = NEW ltcl_app( ).
    z2ui5_cl_cgui_variant=>values_set( app    = lo_to
                                       values = lt_value ).
    cl_abap_unit_assert=>assert_equals( exp = `LH`
                                        act = lo_to->p_carrid ).
    DATA lt_exp LIKE lo_to->s_date.
    lt_exp = VALUE #( ( sign = `I` option = `BT` low = `20260101` high = `20260131` )
                      ( sign = `E` option = `EQ` low = `20260115` ) ).
    cl_abap_unit_assert=>assert_equals( exp = lt_exp
                                        act = lo_to->s_date ).

  ENDMETHOD.

  METHOD unknown_field_is_skipped.

    DATA(lo_to) = NEW ltcl_app( ).
    z2ui5_cl_cgui_variant=>values_set(
        app    = lo_to
        values = VALUE #( ( name = `P_GONE` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = `X` )
                          ( name = `P_MAX` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = `7` ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = lo_to->p_max ).

  ENDMETHOD.

  METHOD catalog_roundtrip.

    DATA(lt_variant) = VALUE z2ui5_cl_cgui_variant=>ty_t_variant(
        ( name   = `Q1 "LH"`
          text   = `P_CARRID = LH`
          values = VALUE #( ( name = `P_CARRID` kind = `P` low = `LH` )
                            ( name = `S_DATE` kind = `S` sign = `I` option = `BT` low = `20260101` high = `20260331` ) ) )
        ( name = `Empty` ) ).

    DATA(lv_string) = z2ui5_cl_cgui_variant=>catalog_to_string( lt_variant ).
    cl_abap_unit_assert=>assert_not_initial( lv_string ).

    cl_abap_unit_assert=>assert_equals( exp = lt_variant
                                        act = z2ui5_cl_cgui_variant=>catalog_from_string( lv_string ) ).

  ENDMETHOD.

  METHOD catalog_from_garbage.

    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_variant=>catalog_from_string( `not a catalog` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_variant=>catalog_from_string( `` ) ).

  ENDMETHOD.

  METHOD values_to_text.

    DATA(lv_text) = z2ui5_cl_cgui_variant=>values_to_text(
        values = VALUE #( ( name = `P_CARRID` kind = `P` low = `LH` )
                          ( name = `P_EMPTY` kind = `P` )
                          ( name = `S_DATE` kind = `S` sign = `I` option = `BT` low = `1` high = `2` )
                          ( name = `S_DATE` kind = `S` sign = `E` option = `EQ` low = `3` ) )
        fields = VALUE #( ( name = `P_CARRID` text = `Airline` ) ) ).

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

    DATA(lv_today) = CONV d( `20260215` ).

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `TODAY` today = lv_today )
                                        exp = lv_today ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `today-1` today = lv_today )
                                        exp = CONV d( `20260214` ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `TODAY+20` today = lv_today )
                                        exp = CONV d( `20260307` ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `MONTH_START` today = lv_today )
                                        exp = CONV d( `20260201` ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `MONTH_END` today = lv_today )
                                        exp = CONV d( `20260228` ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `PREV_MONTH_START` today = lv_today )
                                        exp = CONV d( `20260101` ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `PREV_MONTH_END` today = lv_today )
                                        exp = CONV d( `20260131` ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `YEAR_END` today = lv_today )
                                        exp = CONV d( `20261231` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_variant=>dynamic_date( dynamic = `NONSENSE` today = lv_today ) ).

  ENDMETHOD.

  METHOD dynamic_value_set.

    DATA(lo_app) = NEW ltcl_app( ).
    z2ui5_cl_cgui_variant=>values_set(
        app    = lo_app
        values = VALUE #( ( name = `P_DATE` kind = `P` low = `19990101` dynamic = `TODAY` )
                          ( name = `S_DATE` kind = `S` sign = `I` option = `BT`
                            dynamic = `MONTH_START` dynamic_high = `MONTH_END` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lo_app->p_date
                                        exp = sy-datum ).
    cl_abap_unit_assert=>assert_equals( act = lo_app->s_date[ 1 ]-low
                                        exp = z2ui5_cl_cgui_variant=>dynamic_date( `MONTH_START` ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_app->s_date[ 1 ]-high
                                        exp = z2ui5_cl_cgui_variant=>dynamic_date( `MONTH_END` ) ).

  ENDMETHOD.

ENDCLASS.
