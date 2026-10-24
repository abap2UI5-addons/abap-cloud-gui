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
    TYPES ty_t_air TYPE STANDARD TABLE OF ty_s_air WITH EMPTY KEY.

    METHODS file_name_without_folder FOR TESTING.
    METHODS text_into_columns FOR TESTING.
    METHODS text_into_lines FOR TESTING.
    METHODS table_as_text FOR TESTING.
    METHODS url_of_bytes FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

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

    " the tab splits a line into its columns; the line end of the last line
    " opens none, a value of another type stays initial
    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text      = |LH\tLufthansa\t300\r\nAA\tAmerican\tmany\r\n|
                                                     separator = abap_true
                                           CHANGING  data_tab  = lt_air ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_air ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Lufthansa`
                                        act = lt_air[ 1 ]-name ).
    cl_abap_unit_assert=>assert_equals( exp = 300
                                        act = lt_air[ 1 ]-seats ).
    cl_abap_unit_assert=>assert_equals( exp = `AA`
                                        act = lt_air[ 2 ]-carrid ).

  ENDMETHOD.

  METHOD text_into_lines.

    DATA lt_line TYPE string_table.

    z2ui5_cl_cgui_frontend=>text_to_table( EXPORTING text     = |first\nsecond\n\nfourth|
                                           CHANGING  data_tab = lt_line ).
    cl_abap_unit_assert=>assert_equals( exp = VALUE string_table( ( `first` ) ( `second` ) ( `` ) ( `fourth` ) )
                                        act = lt_line ).

  ENDMETHOD.

  METHOD table_as_text.

    DATA(lt_air) = VALUE ty_t_air( ( carrid = `LH` name = `Lufthansa` seats = 300 )
                                   ( carrid = `AA` name = `American` seats = 120 ) ).
    cl_abap_unit_assert=>assert_equals( exp = |LH\tLufthansa\t300\r\nAA\tAmerican\t120\r\n|
                                        act = z2ui5_cl_cgui_frontend=>table_to_text( data_tab  = lt_air
                                                                                     separator = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( exp = |a\r\nb|
                                        act = z2ui5_cl_cgui_frontend=>table_to_text( data_tab      = VALUE string_table( ( `a` ) ( `b` ) )
                                                                                     last_line_end = abap_false ) ).

  ENDMETHOD.

  METHOD url_of_bytes.

    TYPES ty_line TYPE x LENGTH 4.
    DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.
    DATA lv_url TYPE c LENGTH 255.

    " two lines of four bytes, size cuts the last one: 4D 61 6E 21 4D 61
    lt_bin = VALUE #( ( CONV ty_line( '4D616E21' ) ) ( CONV ty_line( '4D61FFFF' ) ) ).
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

ENDCLASS.
