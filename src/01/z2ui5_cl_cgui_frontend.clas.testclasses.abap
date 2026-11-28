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
    TYPES:
      BEGIN OF ty_s_flight,
        carrid TYPE c LENGTH 3,
        fldate TYPE d,
        deptime TYPE t,
      END OF ty_s_flight.
    TYPES ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.

    METHODS file_name_without_folder FOR TESTING.
    METHODS text_into_columns FOR TESTING.
    METHODS text_into_lines FOR TESTING.
    METHODS table_as_text FOR TESTING.
    METHODS url_of_bytes FOR TESTING.
    METHODS bytes_lines_base64 FOR TESTING.
    METHODS no_gui_version FOR TESTING.
    METHODS dates_and_times_round_trip FOR TESTING.

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

  METHOD dates_and_times_round_trip.

    DATA lt_back TYPE ty_t_flight.

    " a file written with GUI_DOWNLOAD and read back: the date and the time
    " in the user's format come back as they were, not cut to 8 characters
    DATA temp1 TYPE ty_t_flight.
    DATA temp2 LIKE LINE OF temp1.
    DATA lt_flight LIKE temp1.
    DATA temp3 TYPE d.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_back.
    DATA temp5 LIKE sy-tabix.
    DATA temp4 TYPE t.
    FIELD-SYMBOLS <temp6> LIKE LINE OF lt_back.
    DATA temp7 LIKE sy-tabix.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_back.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_back.
    DATA temp8 LIKE sy-tabix.
    CLEAR temp1.

    CLEAR temp2.
    temp2-carrid = `LH`.
    temp2-fldate = `20260105`.
    temp2-deptime = `123000`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-carrid = `AA`.
    INSERT temp2 INTO TABLE temp1.

    lt_flight = temp1.
    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text      = z2ui5_cl_cgui_frontend=>table_to_text( data_tab  = lt_flight
                                                                                                         separator = abap_true )
                                                     separator = abap_true
                                           CHANGING  data_tab  = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = lt_flight
                                        act = lt_back ).

    " the internal format, a 12-hour time; no date stays initial
    CLEAR lt_back.
    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text      = |LH\t20261231\t01:15:00 PM\r\nAA\tno date\t25:00:00|
                                                     separator = abap_true
                                           CHANGING  data_tab  = lt_back ).

    temp3 = `20261231`.


    temp5 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = temp3
                                        act = <temp1>-fldate ).

    temp4 = `131500`.


    temp7 = sy-tabix.
    READ TABLE lt_back INDEX 1 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = temp4
                                        act = <temp6>-deptime ).


    temp6 = sy-tabix.
    READ TABLE lt_back INDEX 2 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp5>-fldate ).


    temp8 = sy-tabix.
    READ TABLE lt_back INDEX 2 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp7>-deptime ).

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
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_air.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp11> LIKE LINE OF lt_air.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp13> LIKE LINE OF lt_air.
    DATA temp14 LIKE sy-tabix.

    " the tab splits a line into its columns; the line end of the last line
    " opens none, a value of another type stays initial
    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text      = |LH\tLufthansa\t300\r\nAA\tAmerican\tmany\r\n|
                                                     separator = abap_true
                                           CHANGING  data_tab  = lt_air ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_air ) ).


    temp10 = sy-tabix.
    READ TABLE lt_air INDEX 1 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Lufthansa`
                                        act = <temp9>-name ).


    temp12 = sy-tabix.
    READ TABLE lt_air INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 300
                                        act = <temp11>-seats ).


    temp14 = sy-tabix.
    READ TABLE lt_air INDEX 2 ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `AA`
                                        act = <temp13>-carrid ).

  ENDMETHOD.

  METHOD text_into_lines.

    DATA lt_line TYPE string_table.
    DATA temp15 TYPE string_table.

    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text     = |first\nsecond\n\nfourth|
                                           CHANGING  data_tab = lt_line ).

    CLEAR temp15.
    INSERT `first` INTO TABLE temp15.
    INSERT `second` INTO TABLE temp15.
    INSERT `` INTO TABLE temp15.
    INSERT `fourth` INTO TABLE temp15.
    cl_abap_unit_assert=>assert_equals( exp = temp15
                                        act = lt_line ).

  ENDMETHOD.

  METHOD table_as_text.

    DATA temp17 TYPE ty_t_air.
    DATA temp18 LIKE LINE OF temp17.
    DATA lt_air LIKE temp17.
    DATA temp19 TYPE string_table.
    CLEAR temp17.

    temp18-carrid = `LH`.
    temp18-name = `Lufthansa`.
    temp18-seats = 300.
    INSERT temp18 INTO TABLE temp17.
    temp18-carrid = `AA`.
    temp18-name = `American`.
    temp18-seats = 120.
    INSERT temp18 INTO TABLE temp17.

    lt_air = temp17.
    cl_abap_unit_assert=>assert_equals( exp = |LH\tLufthansa\t300\r\nAA\tAmerican\t120\r\n|
                                        act = z2ui5_cl_cgui_frontend=>table_to_text( data_tab  = lt_air
                                                                                     separator = abap_true ) ).

    CLEAR temp19.
    INSERT `a` INTO TABLE temp19.
    INSERT `b` INTO TABLE temp19.
    cl_abap_unit_assert=>assert_equals( exp = |a\r\nb|
                                        act = z2ui5_cl_cgui_frontend=>table_to_text( data_tab      = temp19
                                                                                     last_line_end = abap_false ) ).

  ENDMETHOD.

  METHOD url_of_bytes.

    TYPES ty_line TYPE x LENGTH 4.
    DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url TYPE c LENGTH 255.

    " two lines of four bytes, size cuts the last one: 4D 61 6E 21 4D 61
    DATA temp21 LIKE lt_bin.
    DATA temp8 LIKE LINE OF temp21.
    DATA temp9 LIKE LINE OF temp21.
    CLEAR temp21.

    temp8 = '4D616E21'.
    INSERT temp8 INTO TABLE temp21.

    temp9 = '4D61FFFF'.
    INSERT temp9 INTO TABLE temp21.
    lt_bin = temp21.
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
    DATA temp23 TYPE xstring.
    DATA temp24 TYPE xstring.
    DATA temp25 TYPE xstring.
    temp23 = '4D616E214D61'.
    z2ui5_cl_cgui_frontend=>scms_xstring_to_binary( EXPORTING buffer        = temp23
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

    temp24 = '4D616E214D61'.
    cl_abap_unit_assert=>assert_equals( exp = temp24
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

    temp25 = '4D616E214D61'.
    cl_abap_unit_assert=>assert_equals( exp = temp25
                                        act = lv_back ).

  ENDMETHOD.

ENDCLASS.
