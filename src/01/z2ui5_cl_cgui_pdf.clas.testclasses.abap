CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS literal_escapes FOR TESTING.
    METHODS document_parts FOR TESTING.
    METHODS pages_and_landscape FOR TESTING.

    METHODS text
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD text.

    result = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( val ).

  ENDMETHOD.

  METHOD literal_escapes.
    DATA temp1 TYPE xstring.
    DATA temp2 TYPE xstring.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_pdf=>literal( `a (b) \ c` )
                                        exp = `a \(b\) \\ c` ).
    " Latin-1 in the WinAnsi encoding of the font, the euro sign at 128

    temp1 = 'C3BC'.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_pdf=>literal( |M{ text( temp1 ) }ller| )
                                        exp = `M\374ller` ).

    temp2 = 'E282AC'.
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_pdf=>literal( text( temp2 ) )
                                        exp = `\200` ).

  ENDMETHOD.

  METHOD document_parts.

    DATA temp3 TYPE string_table.
    DATA lv_pdf TYPE string.
    DATA temp4 TYPE xsdboolean.
    DATA temp8 TYPE xsdboolean.
    DATA temp9 TYPE xsdboolean.
    DATA temp10 TYPE xsdboolean.
    DATA lv_start TYPE string.
    DATA lv_rest TYPE string.
    DATA temp5 TYPE i.
    DATA temp6 TYPE i.
    TYPES temp1 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_xref TYPE temp1.
    DATA lv_obj3 TYPE string.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_xref.
    DATA temp2 LIKE sy-tabix.
    DATA temp7 TYPE i.
    CLEAR temp3.
    INSERT `Flights` INTO TABLE temp3.
    INSERT `LH 0400` INTO TABLE temp3.

    lv_pdf = text( z2ui5_cl_cgui_pdf=>from_lines( lines = temp3
                                                         title = `Flight list` ) ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf
                                         exp = `%PDF-1.4*` ).

    temp4 = boolc( lv_pdf CS `(LH 0400) Tj` ).
    cl_abap_unit_assert=>assert_true( temp4 ).

    temp8 = boolc( lv_pdf CS `/Title (Flight list)` ).
    cl_abap_unit_assert=>assert_true( temp8 ).

    temp9 = boolc( lv_pdf CS `/MediaBox [0 0 595 842]` ).
    cl_abap_unit_assert=>assert_true( temp9 ).

    temp10 = boolc( lv_pdf CS `(1 / 1) Tj` ).
    cl_abap_unit_assert=>assert_true( temp10 ).

    " the offset after startxref is where the xref table starts


    SPLIT substring_after( val = lv_pdf sub = |startxref\n| ) AT |\n| INTO lv_start lv_rest.

    temp5 = lv_start.
    cl_abap_unit_assert=>assert_equals( act = substring( val = lv_pdf off = temp5 len = 4 )
                                        exp = `xref` ).
    " and the offset of object 3 in the table is where it starts

    temp6 = lv_start.


    SPLIT substring( val = lv_pdf off = temp6 ) AT |\n| INTO TABLE lt_xref.



    temp2 = sy-tabix.
    READ TABLE lt_xref INDEX 6 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_obj3 = substring( val = <temp1> len = 10 ).

    temp7 = lv_obj3.
    cl_abap_unit_assert=>assert_equals( act = substring( val = lv_pdf off = temp7 len = 7 )
                                        exp = `3 0 obj` ).
    cl_abap_unit_assert=>assert_not_initial( lv_rest ).

  ENDMETHOD.

  METHOD pages_and_landscape.

    DATA lt_line TYPE string_table.
      DATA temp8 LIKE LINE OF lt_line.
    DATA lv_pdf TYPE string.
    DATA temp11 TYPE xsdboolean.
    DATA temp12 TYPE xsdboolean.
    DATA temp13 TYPE xsdboolean.

    DO 150 TIMES.

      temp8 = |line { sy-index } { repeat( val = `x` occ = 140 ) }|.
      INSERT temp8 INTO TABLE lt_line.
    ENDDO.
    " 150 characters: landscape at 8.5 points, 49 lines a page

    lv_pdf = text( z2ui5_cl_cgui_pdf=>from_lines( lt_line ) ).


    temp11 = boolc( lv_pdf CS `/MediaBox [0 0 842 595]` ).
    cl_abap_unit_assert=>assert_true( temp11 ).

    temp12 = boolc( lv_pdf CS `/Count 4` ).
    cl_abap_unit_assert=>assert_true( temp12 ).

    temp13 = boolc( lv_pdf CS `(4 / 4) Tj` ).
    cl_abap_unit_assert=>assert_true( temp13 ).

  ENDMETHOD.

ENDCLASS.
