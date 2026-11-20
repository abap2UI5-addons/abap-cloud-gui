CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_air,
        carrid TYPE c LENGTH 3,
        name   TYPE c LENGTH 20,
        seats  TYPE i,
      END OF ty_s_air.
    TYPES ty_t_air TYPE STANDARD TABLE OF ty_s_air WITH DEFAULT KEY.

    METHODS file_name_without_folder FOR TESTING.
    METHODS text_into_columns FOR TESTING.
    METHODS text_into_lines FOR TESTING.
    METHODS table_as_text FOR TESTING.
    METHODS url_of_bytes FOR TESTING.
    METHODS bytes_lines_base64 FOR TESTING.
    METHODS no_gui_version FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD no_gui_version.

    DATA lt_version TYPE string_table.
    DATA lv_rc TYPE i.

    " a browser runs the app: the answer of the classic where no SAP GUI is
    z2ui5_cl_cgui_frontend=>get_gui_version( CHANGING   version_table  = lt_version
                                                        rc             = lv_rc
                                             EXCEPTIONS gui_no_version = 3
                                                        OTHERS         = 9 ).
    cl_abap_unit_assert=>assert_subrc( exp = 3 ).
    cl_abap_unit_assert=>assert_initial( lt_version ).

  ENDMETHOD.

  METHOD file_name_without_folder.

    cl_abap_unit_assert=>assert_equals( exp = `a.csv`
                                        act = z2ui5_cl_cgui_frontend=>file_name( `C:\data\in\a.csv` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `b.txt`
                                        act = z2ui5_cl_cgui_frontend=>file_name( `/usr/sap/b.txt` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `c`
                                        act = z2ui5_cl_cgui_frontend=>file_name( `c` ) ).

  ENDMETHOD.

  METHOD text_into_columns.

    DATA lt_air TYPE ty_t_air.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_air.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_air.
    DATA temp4 LIKE sy-tabix.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_air.
    DATA temp6 LIKE sy-tabix.

    " the tab splits a line into its columns; the line end of the last line
    " opens none, a value of another type stays initial
    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text      = |LH\tLufthansa\t300\r\nAA\tAmerican\tmany\r\n|
                                                     separator = abap_true
                                           CHANGING  data_tab  = lt_air ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_air ) ).


    temp2 = sy-tabix.
    READ TABLE lt_air INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Lufthansa`
                                        act = <temp1>-name ).


    temp4 = sy-tabix.
    READ TABLE lt_air INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 300
                                        act = <temp3>-seats ).


    temp6 = sy-tabix.
    READ TABLE lt_air INDEX 2 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `AA`
                                        act = <temp5>-carrid ).

  ENDMETHOD.

  METHOD text_into_lines.

    DATA lt_line TYPE string_table.
    DATA temp7 TYPE string_table.

    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text     = |first\nsecond\n\nfourth|
                                           CHANGING  data_tab = lt_line ).

    CLEAR temp7.
    INSERT `first` INTO TABLE temp7.
    INSERT `second` INTO TABLE temp7.
    INSERT `` INTO TABLE temp7.
    INSERT `fourth` INTO TABLE temp7.
    cl_abap_unit_assert=>assert_equals( exp = temp7
                                        act = lt_line ).

  ENDMETHOD.

  METHOD table_as_text.

    DATA temp9 TYPE ty_t_air.
    DATA temp10 LIKE LINE OF temp9.
    DATA lt_air LIKE temp9.
    DATA temp11 TYPE string_table.
    CLEAR temp9.

    temp10-carrid = `LH`.
    temp10-name = `Lufthansa`.
    temp10-seats = 300.
    INSERT temp10 INTO TABLE temp9.
    temp10-carrid = `AA`.
    temp10-name = `American`.
    temp10-seats = 120.
    INSERT temp10 INTO TABLE temp9.

    lt_air = temp9.
    cl_abap_unit_assert=>assert_equals( exp = |LH\tLufthansa\t300\r\nAA\tAmerican\t120\r\n|
                                        act = z2ui5_cl_cgui_frontend=>table_to_text( data_tab  = lt_air
                                                                                     separator = abap_true ) ).

    CLEAR temp11.
    INSERT `a` INTO TABLE temp11.
    INSERT `b` INTO TABLE temp11.
    cl_abap_unit_assert=>assert_equals( exp = |a\r\nb|
                                        act = z2ui5_cl_cgui_frontend=>table_to_text( data_tab      = temp11
                                                                                     last_line_end = abap_false ) ).

  ENDMETHOD.

  METHOD url_of_bytes.

    TYPES ty_line TYPE x LENGTH 4.
    DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url TYPE c LENGTH 255.

    " two lines of four bytes, size cuts the last one: 4D 61 6E 21 4D 61
    DATA temp13 LIKE lt_bin.
    DATA temp1 LIKE LINE OF temp13.
    DATA temp2 LIKE LINE OF temp13.
    CLEAR temp13.

    temp1 = '4D616E21'.
    INSERT temp1 INTO TABLE temp13.

    temp2 = '4D61FFFF'.
    INSERT temp2 INTO TABLE temp13.
    lt_bin = temp13.
    z2ui5_cl_cgui_frontend=>dp_create_url( EXPORTING  type    = 'image'
                                                      subtype = 'gif'
                                                      size    = 6
                                                      data    = lt_bin
                                           CHANGING   url     = lv_url
                                           EXCEPTIONS OTHERS  = 1 ).
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = `data:image/gif;base64,TWFuIU1h`
                                        act = z2ui5_cl_cgui_frontend=>url_content( lv_url ) ).
    " another URL is as it is
    cl_abap_unit_assert=>assert_equals( exp = `https://example.org/a.png`
                                        act = z2ui5_cl_cgui_frontend=>url_content( `https://example.org/a.png` ) ).
    " no type is no URL
    z2ui5_cl_cgui_frontend=>dp_create_url( EXPORTING  type = ''
                                                      data = lt_bin
                                           CHANGING   url  = lv_url
                                           EXCEPTIONS dp_invalid_parameter = 1
                                                      OTHERS               = 2 ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = sy-subrc ).

  ENDMETHOD.

  METHOD bytes_lines_base64.

    TYPES ty_line TYPE x LENGTH 4.
    DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_length TYPE i.
    DATA lv_back TYPE xstring.
    DATA lv_b64 TYPE string.

    " six bytes are two lines of four, the last one filled up
    DATA temp15 TYPE xstring.
    DATA temp16 TYPE xstring.
    DATA temp17 TYPE xstring.
    temp15 = '4D616E214D61'.
    z2ui5_cl_cgui_frontend=>scms_xstring_to_binary( EXPORTING buffer        = temp15
                                                    IMPORTING output_length = lv_length
                                                    CHANGING  binary_tab    = lt_bin ).
    cl_abap_unit_assert=>assert_equals( exp = 6
                                        act = lv_length ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_bin ) ).
    " and back, cut at the length
    z2ui5_cl_cgui_frontend=>scms_binary_to_xstring( EXPORTING  input_length = lv_length
                                                               binary_tab   = lt_bin
                                                    IMPORTING  buffer       = lv_back
                                                    EXCEPTIONS OTHERS       = 1 ).

    temp16 = '4D616E214D61'.
    cl_abap_unit_assert=>assert_equals( exp = temp16
                                        act = lv_back ).

    z2ui5_cl_cgui_frontend=>ssfc_base64_encode( EXPORTING  bindata = lv_back
                                                IMPORTING  b64data = lv_b64
                                                EXCEPTIONS OTHERS  = 1 ).
    cl_abap_unit_assert=>assert_equals( exp = `TWFuIU1h`
                                        act = lv_b64 ).
    CLEAR lv_back.
    z2ui5_cl_cgui_frontend=>ssfc_base64_decode( EXPORTING  b64data = lv_b64
                                                IMPORTING  bindata = lv_back
                                                EXCEPTIONS OTHERS  = 1 ).

    temp17 = '4D616E214D61'.
    cl_abap_unit_assert=>assert_equals( exp = temp17
                                        act = lv_back ).

  ENDMETHOD.

ENDCLASS.
