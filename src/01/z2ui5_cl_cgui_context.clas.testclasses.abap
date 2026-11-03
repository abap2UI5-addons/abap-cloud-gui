CLASS ltcl_attri DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_text  TYPE string.
    DATA mt_range TYPE RANGE OF i.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_t_range_i TYPE RANGE OF i.

    METHODS range_empty_selects_all FOR TESTING.
    METHODS range_include_eq FOR TESTING.
    METHODS range_include_bt FOR TESTING.
    METHODS range_exclude FOR TESTING.
    METHODS range_only_exclude FOR TESTING.
    METHODS range_pattern FOR TESTING.
    METHODS range_to_text FOR TESTING.
    METHODS range_to_text_more_lines FOR TESTING.
    METHODS conv_to_text FOR TESTING.
    METHODS base64_round_trip FOR TESTING.
    METHODS check_boolean FOR TESTING.
    METHODS t_comp FOR TESTING.
    METHODS attri_name_by_ref FOR TESTING.
    METHODS fixed_values FOR TESTING.
    METHODS fixed_values_of_range FOR TESTING.
    METHODS no_value_help FOR TESTING.
    METHODS value_check_fixed_values FOR TESTING.
    METHODS dtel_name_and_docu FOR TESTING.
    METHODS binding_date_time FOR TESTING.
    METHODS binding_numbers FOR TESTING.
    METHODS binding_currency_unit FOR TESTING.
    METHODS binding_plain FOR TESTING.
    METHODS binding_comp FOR TESTING.

ENDCLASS.


CLASS ltcl_attri IMPLEMENTATION.
ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD range_empty_selects_all.

    DATA lt_range TYPE ty_t_range_i.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 5
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_include_eq.

    DATA(lt_range) = VALUE ty_t_range_i( ( sign = `I` option = `EQ` low = 5 ) ).

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 5
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 6
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_include_bt.

    DATA(lt_range) = VALUE ty_t_range_i( ( sign = `I` option = `BT` low = 10 high = 20 ) ).

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 10
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 20
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 21
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_exclude.

    DATA(lt_range) = VALUE ty_t_range_i( ( sign = `I` option = `BT` low = 10 high = 20 )
                                         ( sign = `E` option = `EQ` low = 15 ) ).

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 14
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 15
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_only_exclude.

    DATA(lt_range) = VALUE ty_t_range_i( ( sign = `E` option = `GT` low = 100 ) ).

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 50
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 150
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_pattern.

    TYPES ty_t_range_c TYPE RANGE OF string.
    DATA(lt_range) = VALUE ty_t_range_c( ( sign = `I` option = `CP` low = `L*` ) ).

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = `LH`
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = `AA`
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_to_text.

    DATA(lt_range) = VALUE ty_t_range_i( ( sign = `I` option = `EQ` low = 5 )
                                         ( sign = `I` option = `BT` low = 10 high = 20 )
                                         ( sign = `E` option = `EQ` low = 15 ) ).

    cl_abap_unit_assert=>assert_equals( exp = `5; 10...20; !15`
                                        act = z2ui5_cl_cgui_context=>range_to_text( lt_range ) ).

  ENDMETHOD.

  METHOD range_to_text_more_lines.

    DATA(lt_range) = VALUE ty_t_range_i( ( sign = `I` option = `EQ` low = 1 )
                                         ( sign = `I` option = `EQ` low = 2 )
                                         ( sign = `I` option = `EQ` low = 3 )
                                         ( sign = `I` option = `EQ` low = 4 )
                                         ( sign = `I` option = `EQ` low = 5 ) ).

    cl_abap_unit_assert=>assert_equals( exp = `1; 2; 3 (+2)`
                                        act = z2ui5_cl_cgui_context=>range_to_text( lt_range ) ).

  ENDMETHOD.

  METHOD conv_to_text.

    DATA lv_date TYPE d.

    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = z2ui5_cl_cgui_context=>conv_to_text( `text` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `42`
                                        act = z2ui5_cl_cgui_context=>conv_to_text( 42 ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>conv_to_text( lv_date ) ).

  ENDMETHOD.

  METHOD base64_round_trip.

    " one, two and three bytes of the last group - the padding of each
    DATA(lv_x) = CONV xstring( `48656C6C6F2C20E282AC21` ).
    DO 3 TIMES.
      DATA(lv_part) = lv_x(sy-index).
      DATA(lv_b64) = z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_part ).
      cl_abap_unit_assert=>assert_equals( exp = lv_part
                                          act = z2ui5_cl_cgui_context=>conv_decode_x_base64( lv_b64 ) ).
    ENDDO.
    cl_abap_unit_assert=>assert_equals( exp = `SGVsbG8sIOKCrCE=`
                                        act = z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_x ) ).
    cl_abap_unit_assert=>assert_equals( exp = lv_x
                                        act = z2ui5_cl_cgui_context=>conv_decode_x_base64( `SGVsbG8sIOKCrCE=` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Hello, €!`
                                        act = z2ui5_cl_cgui_context=>conv_get_string_by_xstring(
                                                  z2ui5_cl_cgui_context=>conv_decode_x_base64( `SGVsbG8s` && |\n| && `IOKCrCE=` ) ) ).

  ENDMETHOD.

  METHOD check_boolean.

    DATA lv_flag TYPE abap_bool.
    DATA lv_text TYPE string.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>rtti_check_boolean( lv_flag ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>rtti_check_boolean( lv_text ) ).

  ENDMETHOD.

  METHOD t_comp.

    TYPES:
      BEGIN OF ty_s_row,
        id   TYPE i,
        name TYPE string,
      END OF ty_s_row.
    DATA lt_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    DATA(lt_comp) = z2ui5_cl_cgui_context=>rtti_get_t_comp( lt_row ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_comp ) ).
    cl_abap_unit_assert=>assert_equals( exp = `ID`
                                        act = lt_comp[ 1 ]-name ).
    cl_abap_unit_assert=>assert_equals( exp = `NAME`
                                        act = lt_comp[ 2 ]-label ).

  ENDMETHOD.

  METHOD attri_name_by_ref.

    DATA(lo_app) = NEW ltcl_attri( ).
    DATA(lv_copy) = lo_app->mv_text.

    cl_abap_unit_assert=>assert_equals( exp = `MV_TEXT`
                                        act = z2ui5_cl_cgui_context=>attri_name_by_ref( app = lo_app
                                                                                        val = lo_app->mv_text ) ).
    cl_abap_unit_assert=>assert_equals( exp = `MT_RANGE`
                                        act = z2ui5_cl_cgui_context=>attri_name_by_ref( app = lo_app
                                                                                        val = lo_app->mt_range ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>attri_name_by_ref( app = lo_app
                                                                                   val = lv_copy ) ).

  ENDMETHOD.

  METHOD fixed_values.

    DATA lv_flag TYPE xsdboolean.

    DATA(lt_fix) = z2ui5_cl_cgui_context=>rtti_get_fixed_values( cl_abap_typedescr=>describe_by_data( lv_flag ) ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_fix ) ).
    READ TABLE lt_fix WITH KEY low = `X` TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).

  ENDMETHOD.

  METHOD fixed_values_of_range.

    DATA lt_range TYPE RANGE OF xsdboolean.

    DATA(lo_descr) = z2ui5_cl_cgui_context=>rtti_get_value_descr( lt_range ).

    cl_abap_unit_assert=>assert_equals( exp = cl_abap_typedescr=>kind_elem
                                        act = lo_descr->kind ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>rtti_check_value_help( lo_descr ) ).

  ENDMETHOD.

  METHOD no_value_help.

    DATA lv_text TYPE string.
    DATA lv_char TYPE c LENGTH 10.

    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>rtti_check_value_help( cl_abap_typedescr=>describe_by_data( lv_text ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>rtti_check_value_help( cl_abap_typedescr=>describe_by_data( lv_char ) ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>rtti_get_value_table( cl_abap_typedescr=>describe_by_data( lv_char ) ) ).

  ENDMETHOD.

  METHOD value_check_fixed_values.

    DATA lv_flag  TYPE xsdboolean.
    DATA lv_plain TYPE c LENGTH 1.

    lv_flag = `Q`.
    cl_abap_unit_assert=>assert_false( z2ui5_cl_cgui_context=>value_check( lv_flag ) ).
    lv_flag = `X`.
    cl_abap_unit_assert=>assert_true( z2ui5_cl_cgui_context=>value_check( lv_flag ) ).
    " nothing to check against - and an initial value is no error
    lv_plain = `Q`.
    cl_abap_unit_assert=>assert_true( z2ui5_cl_cgui_context=>value_check( lv_plain ) ).
    CLEAR lv_flag.
    cl_abap_unit_assert=>assert_true( z2ui5_cl_cgui_context=>value_check( lv_flag ) ).

  ENDMETHOD.

  METHOD dtel_name_and_docu.

    DATA lv_carrid TYPE land1.
    DATA lt_range  TYPE RANGE OF land1.
    DATA lv_local  TYPE c LENGTH 3.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_context=>rtti_get_dtel_name( lv_carrid )
                                        exp = `LAND1` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_context=>rtti_get_dtel_name( lt_range )
                                        exp = `LAND1` ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>rtti_get_dtel_name( lv_local ) ).
    " a data element with documentation has paragraphs, one without none
    IF z2ui5_cl_cgui_context=>dtel_docu_check( `LAND1` ) = abap_true.
      cl_abap_unit_assert=>assert_not_initial( z2ui5_cl_cgui_context=>dtel_docu_read( `LAND1` ) ).
    ENDIF.
    cl_abap_unit_assert=>assert_false( z2ui5_cl_cgui_context=>dtel_docu_check( `ZZ_NO_SUCH_DTEL_42` ) ).

  ENDMETHOD.

  METHOD binding_date_time.

    DATA lv_date TYPE d.
    DATA lv_time TYPE t.

    cl_abap_unit_assert=>assert_equals(
        exp = `{path: '/DATE', type: 'DateType', formatOptions: {source: {pattern: 'yyyy-MM-dd'}}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `/DATE`
                                                        val  = lv_date ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `{path: 'TIME', type: 'TimeType', formatOptions: {source: {pattern: 'HH:mm:ss'}}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `TIME`
                                                        val  = lv_time ) ).

  ENDMETHOD.

  METHOD binding_numbers.

    DATA lv_int    TYPE i.
    DATA lv_packed TYPE p LENGTH 10 DECIMALS 3.
    DATA lv_float  TYPE f.

    cl_abap_unit_assert=>assert_equals(
        exp = `{path: 'N', type: 'IntType', formatOptions: {groupingEnabled: true}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `N`
                                                        val  = lv_int ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `{path: 'P', type: 'FloatType', formatOptions: {minFractionDigits: 3, maxFractionDigits: 3, groupingEnabled: true}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `P`
                                                        val  = lv_packed ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `{path: 'F', type: 'FloatType', formatOptions: {groupingEnabled: true}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `F`
                                                        val  = lv_float ) ).

  ENDMETHOD.

  METHOD binding_currency_unit.

    DATA lv_amount TYPE p LENGTH 10 DECIMALS 2.

    cl_abap_unit_assert=>assert_equals(
        exp = `{parts: [{path: 'PRICE'}, {path: 'CURRENCY'}], type: 'CurrType', formatOptions: {showMeasure: false}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path          = `PRICE`
                                                        val           = lv_amount
                                                        currency_path = `CURRENCY` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `{parts: [{path: 'MENGE'}, {path: 'MEINS'}], type: 'UnitType', formatOptions: {showMeasure: false}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path      = `MENGE`
                                                        val       = lv_amount
                                                        unit_path = `MEINS` ) ).

  ENDMETHOD.

  METHOD binding_plain.

    DATA lv_text TYPE string.
    DATA lv_char TYPE c LENGTH 10.
    DATA lv_flag TYPE abap_bool.

    cl_abap_unit_assert=>assert_equals( exp = `{TEXT}`
                                        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `TEXT`
                                                                                        val  = lv_text ) ).
    cl_abap_unit_assert=>assert_equals( exp = `{/CHAR}`
                                        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `/CHAR`
                                                                                        val  = lv_char ) ).
    cl_abap_unit_assert=>assert_equals( exp = `{FLAG}`
                                        act = z2ui5_cl_cgui_context=>ui5_binding_typed( path = `FLAG`
                                                                                        val  = lv_flag ) ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*CurrType: 'sap/ui/model/type/Currency'*`
                                         act = z2ui5_cl_cgui_context=>ui5_get_type_require( ) ).

  ENDMETHOD.

  METHOD binding_comp.

    TYPES:
      BEGIN OF ty_s_row,
        fldate TYPE d,
        price  TYPE p LENGTH 8 DECIMALS 2,
        text   TYPE string,
      END OF ty_s_row.
    DATA ls_row TYPE ty_s_row.

    cl_abap_unit_assert=>assert_equals(
        exp = `{path: 'FLDATE', type: 'DateType', formatOptions: {source: {pattern: 'yyyy-MM-dd'}}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed_comp( struc = ls_row
                                                             comp  = `fldate` ) ).
    " a local type has no DDIC reference field - the amount is a number
    cl_abap_unit_assert=>assert_equals(
        exp = `{path: 'PRICE', type: 'FloatType', formatOptions: {minFractionDigits: 2, maxFractionDigits: 2, groupingEnabled: true}}`
        act = z2ui5_cl_cgui_context=>ui5_binding_typed_comp( struc = ls_row
                                                             comp  = `PRICE` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>rtti_get_ref_field( struc = ls_row
                                                                                   comp  = `PRICE` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `{TEXT}`
                                        act = z2ui5_cl_cgui_context=>ui5_binding_typed_comp( struc = ls_row
                                                                                             comp  = `TEXT` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `{MISSING}`
                                        act = z2ui5_cl_cgui_context=>ui5_binding_typed_comp( struc = ls_row
                                                                                             comp  = `MISSING` ) ).

  ENDMETHOD.

ENDCLASS.
