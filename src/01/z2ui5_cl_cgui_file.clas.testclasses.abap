CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS types_of_a_filter FOR TESTING.
    METHODS content_of_a_data_uri FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD types_of_a_filter.

    cl_abap_unit_assert=>assert_equals( exp = `txt,csv,tsv`
                                        act = z2ui5_cl_cgui_file=>file_types( `Text (*.TXT)|*.TXT|CSV|*.csv;*.tsv|` ) ).
    " all files: no limit
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_file=>file_types( `CSV|*.csv|All Files (*.*)|*.*|` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_file=>file_types( `` ) ).

  ENDMETHOD.

  METHOD content_of_a_data_uri.

    cl_abap_unit_assert=>assert_equals( exp = CONV xstring( `48656C6C6F` )
                                        act = z2ui5_cl_cgui_file=>content_of_data_uri( `data:text/plain;base64,SGVsbG8=` ) ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_cgui_file=>content_of_data_uri( `no uri` ) ).

  ENDMETHOD.

ENDCLASS.
