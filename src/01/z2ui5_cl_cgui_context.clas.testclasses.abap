CLASS ltcl_attri DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_text  TYPE string.
    TYPES temp1_39e70a0e26 TYPE RANGE OF i.
DATA mt_range TYPE temp1_39e70a0e26.

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
    METHODS escape_xml FOR TESTING.
    METHODS url_unescape_x FOR TESTING.
    METHODS mimetype_by_name FOR TESTING.
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
    METHODS like_of_a_pattern FOR TESTING.

ENDCLASS.


CLASS ltcl_attri IMPLEMENTATION.
ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD like_of_a_pattern.

    " the wildcards of SAP GUI as those of LIKE, LIKE's own escaped
    cl_abap_unit_assert=>assert_equals(
        exp = `KUNNR LIKE '47%' ESCAPE '#'`
        act = z2ui5_cl_cgui_context=>sql_like( column  = `kunnr`
                                                pattern = `47*` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `NAME LIKE 'A#_B_#%''%' ESCAPE '#'`
        act = z2ui5_cl_cgui_context=>sql_like( column  = `NAME`
                                                pattern = `A_B+%'*` ) ).
    " no wildcard - no restriction
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>sql_like( column  = `KUNNR`
                                                                           pattern = `4711` ) ).

  ENDMETHOD.

  METHOD range_empty_selects_all.

    DATA lt_range TYPE ty_t_range_i.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 5
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_include_eq.

    DATA temp1 TYPE ty_t_range_i.
    DATA temp2 LIKE LINE OF temp1.
    DATA lt_range LIKE temp1.
    CLEAR temp1.

    temp2-sign = `I`.
    temp2-option = `EQ`.
    temp2-low = 5.
    INSERT temp2 INTO TABLE temp1.

    lt_range = temp1.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 5
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 6
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_include_bt.

    DATA temp3 TYPE ty_t_range_i.
    DATA temp4 LIKE LINE OF temp3.
    DATA lt_range LIKE temp3.
    CLEAR temp3.

    temp4-sign = `I`.
    temp4-option = `BT`.
    temp4-low = 10.
    temp4-high = 20.
    INSERT temp4 INTO TABLE temp3.

    lt_range = temp3.

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

    DATA temp5 TYPE ty_t_range_i.
    DATA temp6 LIKE LINE OF temp5.
    DATA lt_range LIKE temp5.
    CLEAR temp5.

    CLEAR temp6.
    temp6-sign = `I`.
    temp6-option = `BT`.
    temp6-low = 10.
    temp6-high = 20.
    INSERT temp6 INTO TABLE temp5.
    CLEAR temp6.
    temp6-sign = `E`.
    temp6-option = `EQ`.
    temp6-low = 15.
    INSERT temp6 INTO TABLE temp5.

    lt_range = temp5.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 14
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 15
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_only_exclude.

    DATA temp7 TYPE ty_t_range_i.
    DATA temp8 LIKE LINE OF temp7.
    DATA lt_range LIKE temp7.
    CLEAR temp7.

    temp8-sign = `E`.
    temp8-option = `GT`.
    temp8-low = 100.
    INSERT temp8 INTO TABLE temp7.

    lt_range = temp7.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 50
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = 150
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_pattern.

    TYPES ty_t_range_c TYPE RANGE OF string.
    DATA temp9 TYPE ty_t_range_c.
    DATA temp10 LIKE LINE OF temp9.
    DATA lt_range LIKE temp9.
    CLEAR temp9.

    temp10-sign = `I`.
    temp10-option = `CP`.
    temp10-low = `L*`.
    INSERT temp10 INTO TABLE temp9.

    lt_range = temp9.

    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = z2ui5_cl_cgui_context=>range_check( val   = `LH`
                                                                                  range = lt_range ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = z2ui5_cl_cgui_context=>range_check( val   = `AA`
                                                                                  range = lt_range ) ).

  ENDMETHOD.

  METHOD range_to_text.

    DATA temp11 TYPE ty_t_range_i.
    DATA temp12 LIKE LINE OF temp11.
    DATA lt_range LIKE temp11.
    CLEAR temp11.

    CLEAR temp12.
    temp12-sign = `I`.
    temp12-option = `EQ`.
    temp12-low = 5.
    INSERT temp12 INTO TABLE temp11.
    CLEAR temp12.
    temp12-sign = `I`.
    temp12-option = `BT`.
    temp12-low = 10.
    temp12-high = 20.
    INSERT temp12 INTO TABLE temp11.
    CLEAR temp12.
    temp12-sign = `E`.
    temp12-option = `EQ`.
    temp12-low = 15.
    INSERT temp12 INTO TABLE temp11.

    lt_range = temp11.

    cl_abap_unit_assert=>assert_equals( exp = `5; 10...20; !15`
                                        act = z2ui5_cl_cgui_context=>range_to_text( lt_range ) ).

  ENDMETHOD.

  METHOD range_to_text_more_lines.

    DATA temp13 TYPE ty_t_range_i.
    DATA temp14 LIKE LINE OF temp13.
    DATA lt_range LIKE temp13.
    CLEAR temp13.

    temp14-sign = `I`.
    temp14-option = `EQ`.
    temp14-low = 1.
    INSERT temp14 INTO TABLE temp13.
    temp14-sign = `I`.
    temp14-option = `EQ`.
    temp14-low = 2.
    INSERT temp14 INTO TABLE temp13.
    temp14-sign = `I`.
    temp14-option = `EQ`.
    temp14-low = 3.
    INSERT temp14 INTO TABLE temp13.
    temp14-sign = `I`.
    temp14-option = `EQ`.
    temp14-low = 4.
    INSERT temp14 INTO TABLE temp13.
    temp14-sign = `I`.
    temp14-option = `EQ`.
    temp14-low = 5.
    INSERT temp14 INTO TABLE temp13.

    lt_range = temp13.

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
    DATA temp15 TYPE xstring.
    DATA lv_x LIKE temp15.
      DATA lv_part TYPE xstring.
      DATA lv_b64 TYPE string.
    temp15 = `48656C6C6F2C20E282AC21`.

    lv_x = temp15.
    DO 3 TIMES.

      lv_part = lv_x(sy-index).

      lv_b64 = z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_part ).
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

  METHOD escape_xml.
    DATA temp16 TYPE xstring.

    cl_abap_unit_assert=>assert_equals( exp = `plain text`
                                        act = z2ui5_cl_cgui_context=>c_escape_xml( `plain text` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `a &amp; b &lt;c&gt; &quot;d&quot;`
                                        act = z2ui5_cl_cgui_context=>c_escape_xml( `a & b <c> "d"` ) ).
    " A, form feed, B, tab, C, line feed: the form feed is no character of
    " XML 1.0 and goes, tab and line feed are character references

    temp16 = `410C4209430A`.
    cl_abap_unit_assert=>assert_equals( exp = `AB&#x9;C&#xA;`
                                        act = z2ui5_cl_cgui_context=>c_escape_xml(
                                                  z2ui5_cl_cgui_context=>conv_get_string_by_xstring( temp16 ) ) ).

  ENDMETHOD.

  METHOD url_unescape_x.

    " %XX a byte, a + stays, the rest UTF-8
    DATA temp17 TYPE xstring.
    DATA temp18 TYPE xstring.
    temp17 = `6120622B63E282AC`.
    cl_abap_unit_assert=>assert_equals( exp = temp17
                                        act = z2ui5_cl_cgui_context=>url_unescape_x( `a%20b+c%e2%82%AC` ) ).
    " no escape without two hex digits

    temp18 = `255A5A2534`.
    cl_abap_unit_assert=>assert_equals( exp = temp18
                                        act = z2ui5_cl_cgui_context=>url_unescape_x( `%ZZ%4` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_context=>url_unescape_x( `` ) ).

  ENDMETHOD.

  METHOD mimetype_by_name.

    cl_abap_unit_assert=>assert_equals( exp = `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
                                        act = z2ui5_cl_cgui_context=>file_get_mimetype( `Report.XLSX` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text/plain`
                                        act = z2ui5_cl_cgui_context=>file_get_mimetype( ` notes.txt ` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `application/octet-stream`
                                        act = z2ui5_cl_cgui_context=>file_get_mimetype( `archive.tar.gz` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `application/octet-stream`
                                        act = z2ui5_cl_cgui_context=>file_get_mimetype( `` ) ).

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
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA lt_row TYPE temp2.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    FIELD-SYMBOLS <temp19> LIKE LINE OF lt_comp.
    DATA temp20 LIKE sy-tabix.
    FIELD-SYMBOLS <temp21> LIKE LINE OF lt_comp.
    DATA temp22 LIKE sy-tabix.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( lt_row ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_comp ) ).


    temp20 = sy-tabix.
    READ TABLE lt_comp INDEX 1 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `ID`
                                        act = <temp19>-name ).


    temp22 = sy-tabix.
    READ TABLE lt_comp INDEX 2 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `NAME`
                                        act = <temp21>-label ).

  ENDMETHOD.

  METHOD attri_name_by_ref.

    DATA lo_app TYPE REF TO ltcl_attri.
    DATA lv_copy LIKE lo_app->mv_text.
    CREATE OBJECT lo_app TYPE ltcl_attri.

    lv_copy = lo_app->mv_text.

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

    DATA lt_fix TYPE z2ui5_cl_cgui_context=>ty_t_fix_val.
    lt_fix = z2ui5_cl_cgui_context=>rtti_get_fixed_values( cl_abap_typedescr=>describe_by_data( lv_flag ) ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_fix ) ).
    READ TABLE lt_fix WITH KEY low = `X` TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_subrc( ).

  ENDMETHOD.

  METHOD fixed_values_of_range.

    TYPES temp3 TYPE RANGE OF xsdboolean.
DATA lt_range TYPE temp3.

    DATA lo_descr TYPE REF TO cl_abap_typedescr.
    lo_descr = z2ui5_cl_cgui_context=>rtti_get_value_descr( lt_range ).

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
    TYPES temp4 TYPE RANGE OF land1.
DATA lt_range  TYPE temp4.
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

"! ================================================================
"! what z2ui5_cl_cgui_xlsx takes from the system - the tests of abap-util
"! ================================================================
CLASS ltcl_xml_reader DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    METHODS read
      IMPORTING
        xml           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS nodes_in_order                 FOR TESTING.
    METHODS attributes                     FOR TESTING.
    METHODS entities_and_blanks            FOR TESTING.
    METHODS namespace_prefix               FOR TESTING.
    METHODS broken_document                FOR TESTING.

ENDCLASS.

CLASS ltcl_xml_reader IMPLEMENTATION.

  METHOD read.
    " every node as one token: +name[attr=value] for an opening, =value for
    " a text, -name for an end
    DATA lv_kind  TYPE string.
    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.
    DATA lt_attr  TYPE z2ui5_cl_cgui_context=>ty_t_xml_attribute.

    DATA lo_reader TYPE REF TO object.
          DATA ls_attr LIKE LINE OF lt_attr.
    lo_reader = z2ui5_cl_cgui_context=>xml_reader_create(
                          z2ui5_cl_cgui_context=>conv_get_xstring_by_string( xml ) ).
    DO.
      z2ui5_cl_cgui_context=>xml_reader_next( EXPORTING reader      = lo_reader
                                                  IMPORTING kind        = lv_kind
                                                            name        = lv_name
                                                            value       = lv_value
                                                            t_attribute = lt_attr ).
      CASE lv_kind.
        WHEN z2ui5_cl_cgui_context=>cs_xml_node-open.
          result = |{ result }+{ lv_name }|.

          LOOP AT lt_attr INTO ls_attr.
            result = |{ result }[{ ls_attr-name }={ ls_attr-value }]|.
          ENDLOOP.
        WHEN z2ui5_cl_cgui_context=>cs_xml_node-value.
          result = |{ result }={ lv_value }|.
        WHEN z2ui5_cl_cgui_context=>cs_xml_node-close.
          result = |{ result }-{ lv_name }|.
        WHEN OTHERS.
          EXIT.
      ENDCASE.
    ENDDO.
  ENDMETHOD.

  METHOD nodes_in_order.
    cl_abap_unit_assert=>assert_equals( exp = `+a+b=1-b+c-c-a`
                                        act = read( `<a><b>1</b><c/></a>` ) ).
  ENDMETHOD.

  METHOD attributes.
    cl_abap_unit_assert=>assert_equals(
        exp = `+row[r=2][spans=1:3]+c[r=A2][t=s]-c-row`
        act = read( `<?xml version="1.0" encoding="UTF-8"?><row r="2" spans="1:3"><c r="A2" t="s"/></row>` ) ).
  ENDMETHOD.

  METHOD entities_and_blanks.
    " an entity arrives decoded, and a text of blanks only is kept
    cl_abap_unit_assert=>assert_equals( exp = `+a+t=a&b<c-t+t=  -t-a`
                                        act = read( `<a><t>a&amp;b&lt;c</t><t>  </t></a>` ) ).
  ENDMETHOD.

  METHOD namespace_prefix.
    " the name without its prefix, on an element and on an attribute
    DATA lv_act TYPE string.
    DATA temp1 TYPE xsdboolean.
    lv_act = read( `<x:a xmlns:x="urn:x" xmlns:r="urn:r"><x:b r:id="rId1"/></x:a>` ).

    temp1 = boolc( lv_act CS `+b[id=rId1]-b-a` ).
    cl_abap_unit_assert=>assert_true( temp1 ).
    cl_abap_unit_assert=>assert_equals( exp = `+a`
                                        act = substring( val = lv_act
                                                         len = 2 ) ).
  ENDMETHOD.

  METHOD broken_document.
    TRY.
        read( `<a><b></a>` ).
        cl_abap_unit_assert=>fail( `a document that is not well-formed has to raise` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_tab_by_names DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    METHODS string_columns                 FOR TESTING.
    METHODS type_kinds                     FOR TESTING.

ENDCLASS.

CLASS ltcl_tab_by_names IMPLEMENTATION.

  METHOD string_columns.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA temp23 TYPE string_table.
    DATA lr_tab TYPE REF TO data.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <text> TYPE any.
    CLEAR temp23.
    INSERT `ORDER_ID` INTO TABLE temp23.
    INSERT `TEXT` INTO TABLE temp23.

    lr_tab = z2ui5_cl_cgui_context=>rtti_create_tab_by_names(
                       temp23 ).
    ASSIGN lr_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_initial( <tab> ).


    INSERT INITIAL LINE INTO TABLE <tab> ASSIGNING <row>.

    ASSIGN COMPONENT `TEXT` OF STRUCTURE <row> TO <text>.
    cl_abap_unit_assert=>assert_subrc( ).
    " a string: nothing of a long value is cut off
    <text> = repeat( val = `x`
                     occ = 500 ).
    cl_abap_unit_assert=>assert_equals( exp = 500
                                        act = strlen( <text> ) ).
    " two names, two components
    ASSIGN COMPONENT 3 OF STRUCTURE <row> TO <text>.
    cl_abap_unit_assert=>assert_subrc( exp = 4 ).
  ENDMETHOD.

  METHOD type_kinds.
    DATA lv_char   TYPE c LENGTH 3.
    DATA lv_numc   TYPE n LENGTH 3.
    DATA lv_string TYPE string.
    DATA lv_hex    TYPE x LENGTH 2.
    DATA lv_bytes  TYPE xstring.
    DATA lv_packed TYPE p LENGTH 8 DECIMALS 2.

    cl_abap_unit_assert=>assert_equals( exp = z2ui5_cl_cgui_context=>cv_typedescr_typekind_char
                                        act = z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_char ) ).
    cl_abap_unit_assert=>assert_equals( exp = z2ui5_cl_cgui_context=>cv_typedescr_typekind_num
                                        act = z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_numc ) ).
    cl_abap_unit_assert=>assert_equals( exp = z2ui5_cl_cgui_context=>cv_typedescr_typekind_string
                                        act = z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_string ) ).
    cl_abap_unit_assert=>assert_equals( exp = z2ui5_cl_cgui_context=>cv_typedescr_typekind_hex
                                        act = z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_hex ) ).
    cl_abap_unit_assert=>assert_equals( exp = z2ui5_cl_cgui_context=>cv_typedescr_typekind_xstring
                                        act = z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_bytes ) ).

    " a number by its type kind - a NUMC and a text are none
    cl_abap_unit_assert=>assert_true( z2ui5_cl_cgui_context=>rtti_check_typekind_number(
                                          z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_packed ) ) ).
    cl_abap_unit_assert=>assert_false( z2ui5_cl_cgui_context=>rtti_check_typekind_number(
                                           z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_numc ) ) ).
    cl_abap_unit_assert=>assert_false( z2ui5_cl_cgui_context=>rtti_check_typekind_number(
                                           z2ui5_cl_cgui_context=>rtti_get_type_kind( lv_string ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_zip DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    METHODS roundtrip                      FOR TESTING.
    METHODS unpack_no_archive              FOR TESTING.

ENDCLASS.

CLASS ltcl_zip IMPLEMENTATION.

  METHOD roundtrip.
    DATA temp25 TYPE z2ui5_cl_cgui_context=>ty_t_zip_file.
    DATA temp26 LIKE LINE OF temp25.
    DATA temp1 TYPE xstring.
    DATA temp2 TYPE xstring.
    DATA lt_in LIKE temp25.
    DATA lt_out TYPE z2ui5_cl_cgui_context=>ty_t_zip_file.
    CLEAR temp25.

    temp26-name = `a.txt`.

    temp1 = `414141`.
    temp26-content = temp1.
    INSERT temp26 INTO TABLE temp25.
    temp26-name = `b/c.txt`.

    temp2 = `424242`.
    temp26-content = temp2.
    INSERT temp26 INTO TABLE temp25.

    lt_in = temp25.


    lt_out = z2ui5_cl_cgui_context=>zip_unpack( z2ui5_cl_cgui_context=>zip_pack( lt_in ) ).
    cl_abap_unit_assert=>assert_equals( exp = lt_in
                                        act = lt_out ).
  ENDMETHOD.

  METHOD unpack_no_archive.
        DATA temp27 TYPE xstring.
    " bytes that are no archive raise the exception of this addon - the ZIP
    " class reports them with a classic exception, which ends in a dump
    TRY.

        temp27 = `48656C6C6F2C20776F726C6421`.
        z2ui5_cl_cgui_context=>zip_unpack( temp27 ).
        cl_abap_unit_assert=>fail( `data that is no archive has to raise` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
