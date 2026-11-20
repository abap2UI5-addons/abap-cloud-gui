CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_item,
        item   TYPE n LENGTH 3,
        name   TYPE c LENGTH 20,
        weight TYPE i,
      END OF ty_s_item.

    METHODS columns_of_the_line FOR TESTING.
    METHODS column_settings FOR TESTING.
    METHODS no_such_column FOR TESTING.
    METHODS settings_of_the_table FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD columns_of_the_line.

    DATA ls_item TYPE ty_s_item.

    DATA lo_columns TYPE REF TO z2ui5_cl_cgui_salv_cols.
    DATA lt_column TYPE z2ui5_cl_cgui_salv_cols=>ty_t_column_ref.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_column.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_column.
    DATA temp4 LIKE sy-tabix.
    CREATE OBJECT lo_columns TYPE z2ui5_cl_cgui_salv_cols EXPORTING LINE = ls_item.

    lt_column = lo_columns->get( ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_column ) ).


    temp2 = sy-tabix.
    READ TABLE lt_column INDEX 3 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 'WEIGHT'
                                        act = <temp1>-columnname ).


    temp4 = sy-tabix.
    READ TABLE lt_column INDEX 2 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `NAME`
                                        act = <temp3>-r_column->get_columnname( ) ).

  ENDMETHOD.

  METHOD column_settings.

    DATA ls_item TYPE ty_s_item.

    DATA lo_column TYPE REF TO z2ui5_cl_cgui_salv_column.
    DATA temp1 TYPE REF TO z2ui5_cl_cgui_salv_cols.
    CREATE OBJECT temp1 TYPE z2ui5_cl_cgui_salv_cols EXPORTING LINE = ls_item.
    lo_column = temp1->get_column( 'weight' ).
    lo_column->set_long_text( 'Weight (g)' ).
    lo_column->set_cell_type( z2ui5_if_cgui_salv_c=>cell_type-hotspot ).
    lo_column->set_visible( abap_false ).
    cl_abap_unit_assert=>assert_equals( exp = `Weight (g)`
                                        act = lo_column->get_long_text( ) ).
    cl_abap_unit_assert=>assert_true( lo_column->mv_hotspot ).
    cl_abap_unit_assert=>assert_false( lo_column->is_visible( ) ).

  ENDMETHOD.

  METHOD no_such_column.

    DATA ls_item TYPE ty_s_item.
        DATA temp5 TYPE REF TO z2ui5_cl_cgui_salv_cols.
        DATA lx_salv TYPE REF TO z2ui5_cx_cgui_salv.

    TRY.

        CREATE OBJECT temp5 TYPE z2ui5_cl_cgui_salv_cols EXPORTING LINE = ls_item.
        temp5->get_column( 'PRICE' ).
        cl_abap_unit_assert=>fail( `a column that is not there - cx_salv_not_found` ).

      CATCH z2ui5_cx_cgui_salv INTO lx_salv.
        cl_abap_unit_assert=>assert_equals( exp = `No column PRICE`
                                            act = lx_salv->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD settings_of_the_table.

    DATA lo_settings TYPE REF TO z2ui5_cl_cgui_salv_config.
    FIELD-SYMBOLS <temp6> LIKE LINE OF lo_settings->mt_function.
    DATA temp7 LIKE sy-tabix.
    CREATE OBJECT lo_settings TYPE z2ui5_cl_cgui_salv_config.
    lo_settings->set_list_header( 'Packing list' ).
    lo_settings->add_function( name = 'weigh'
                               text = 'Weigh' ).
    lo_settings->add_function( name = 'WEIGH'
                               text = 'Weigh again' ).
    lo_settings->set_selection_mode( z2ui5_if_cgui_salv_c=>selection_mode-multiple ).
    cl_abap_unit_assert=>assert_equals( exp = `Packing list`
                                        act = lo_settings->get_list_header( ) ).
    " a function added twice is there once, as added the last time
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lo_settings->mt_function ) ).


    temp7 = sy-tabix.
    READ TABLE lo_settings->mt_function INDEX 1 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Weigh again`
                                        act = <temp6>-text ).
    " no grid shown yet - no rows selected
    cl_abap_unit_assert=>assert_initial( lo_settings->get_selected_rows( ) ).

  ENDMETHOD.

ENDCLASS.
