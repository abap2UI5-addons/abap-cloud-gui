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

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_pdf=>literal( `a (b) \ c` )
                                        exp = `a \(b\) \\ c` ).
    " Latin-1 in the WinAnsi encoding of the font, the euro sign at 128
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_pdf=>literal( |M{ text( CONV xstring( 'C3BC' ) ) }ller| )
                                        exp = `M\374ller` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_pdf=>literal( text( CONV xstring( 'E282AC' ) ) )
                                        exp = `\200` ).

  ENDMETHOD.

  METHOD document_parts.

    DATA(lv_pdf) = text( z2ui5_cl_cgui_pdf=>from_lines( lines = VALUE #( ( `Flights` ) ( `LH 0400` ) )
                                                         title = `Flight list` ) ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf
                                         exp = `%PDF-1.4*` ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `(LH 0400) Tj` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `/Title (Flight list)` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `/MediaBox [0 0 595 842]` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `(1 / 1) Tj` ) ).

    " the offset after startxref is where the xref table starts
    SPLIT substring_after( val = lv_pdf sub = |startxref\n| ) AT |\n| INTO DATA(lv_start) DATA(lv_rest).
    cl_abap_unit_assert=>assert_equals( act = substring( val = lv_pdf off = CONV i( lv_start ) len = 4 )
                                        exp = `xref` ).
    " and the offset of object 3 in the table is where it starts
    SPLIT substring( val = lv_pdf off = CONV i( lv_start ) ) AT |\n| INTO TABLE DATA(lt_xref).
    DATA(lv_obj3) = substring( val = lt_xref[ 6 ] len = 10 ).
    cl_abap_unit_assert=>assert_equals( act = substring( val = lv_pdf off = CONV i( lv_obj3 ) len = 7 )
                                        exp = `3 0 obj` ).
    cl_abap_unit_assert=>assert_not_initial( lv_rest ).

  ENDMETHOD.

  METHOD pages_and_landscape.

    DATA lt_line TYPE string_table.

    DO 150 TIMES.
      INSERT |line { sy-index } { repeat( val = `x` occ = 140 ) }| INTO TABLE lt_line.
    ENDDO.
    " 150 characters: landscape at 8.5 points, 49 lines a page
    DATA(lv_pdf) = text( z2ui5_cl_cgui_pdf=>from_lines( lt_line ) ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `/MediaBox [0 0 842 595]` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `/Count 4` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_pdf CS `(4 / 4) Tj` ) ).

  ENDMETHOD.

ENDCLASS.
