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
    TYPES BEGIN OF ty_s_order.
    INCLUDE TYPE ty_s_item.
    TYPES   amount TYPE i.
    TYPES END OF ty_s_order.

    METHODS columns_of_the_line FOR TESTING.
    METHODS columns_of_an_include FOR TESTING.
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
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_column.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_column.
    DATA temp8 LIKE sy-tabix.
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

    " set_column_position( ) moves the column - the order of the grid
    lo_columns->set_column_position( columnname = 'weight'
                                     position   = 1 ).
    lt_column = lo_columns->get( ).


    temp6 = sy-tabix.
    READ TABLE lt_column INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 'WEIGHT'
                                        act = <temp5>-columnname ).


    temp8 = sy-tabix.
    READ TABLE lt_column INDEX 3 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = 'NAME'
                                        act = <temp7>-columnname ).

  ENDMETHOD.

  METHOD columns_of_an_include.

    DATA ls_order TYPE ty_s_order.

    DATA lo_columns TYPE REF TO z2ui5_cl_cgui_salv_cols.
    CREATE OBJECT lo_columns TYPE z2ui5_cl_cgui_salv_cols EXPORTING LINE = ls_order.
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( lo_columns->get( ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `NAME`
                                        act = lo_columns->get_column( 'NAME' )->get_columnname( ) ).

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
    lo_column->set_zero( abap_false ).
    lo_column->set_alignment( z2ui5_if_cgui_salv_c=>alignment-right ).
    cl_abap_unit_assert=>assert_true( lo_column->mv_no_zero ).
    cl_abap_unit_assert=>assert_equals( exp = `R`
                                        act = lo_column->mv_just ).

  ENDMETHOD.

  METHOD no_such_column.

    DATA ls_item TYPE ty_s_item.
        DATA temp9 TYPE REF TO z2ui5_cl_cgui_salv_cols.
        DATA lx_salv TYPE REF TO z2ui5_cx_cgui_salv.

    TRY.

        CREATE OBJECT temp9 TYPE z2ui5_cl_cgui_salv_cols EXPORTING LINE = ls_item.
        temp9->get_column( 'PRICE' ).
        cl_abap_unit_assert=>fail( `a column that is not there - cx_salv_not_found` ).

      CATCH z2ui5_cx_cgui_salv INTO lx_salv.
        cl_abap_unit_assert=>assert_equals( exp = `No column PRICE`
                                            act = lx_salv->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD settings_of_the_table.

    DATA lo_settings TYPE REF TO z2ui5_cl_cgui_salv_config.
    FIELD-SYMBOLS <temp10> LIKE LINE OF lo_settings->mt_function.
    DATA temp11 LIKE sy-tabix.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lo_settings->mt_sort.
    DATA temp13 LIKE sy-tabix.
    FIELD-SYMBOLS <temp14> LIKE LINE OF lo_settings->mt_sort.
    DATA temp15 LIKE sy-tabix.
    FIELD-SYMBOLS <temp16> LIKE LINE OF lo_settings->mt_sort.
    DATA temp17 LIKE sy-tabix.
    DATA temp18 TYPE string_table.
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


    temp11 = sy-tabix.
    READ TABLE lo_settings->mt_function INDEX 1 ASSIGNING <temp10>.
    sy-tabix = temp11.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `Weigh again`
                                        act = <temp10>-text ).
    " sorts in their order, totals - a minimum has no counterpart
    lo_settings->add_sort( 'name' ).
    lo_settings->add_sort( columnname = 'item'
                           position   = 1
                           sequence   = z2ui5_if_cgui_salv_c=>sort-sort_down
                           subtotal   = abap_true ).


    temp13 = sy-tabix.
    READ TABLE lo_settings->mt_sort INDEX 1 ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `ITEM`
                                        act = <temp12>-columnname ).


    temp15 = sy-tabix.
    READ TABLE lo_settings->mt_sort INDEX 1 ASSIGNING <temp14>.
    sy-tabix = temp15.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp14>-descending ).


    temp17 = sy-tabix.
    READ TABLE lo_settings->mt_sort INDEX 1 ASSIGNING <temp16>.
    sy-tabix = temp17.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp16>-subtotal ).
    lo_settings->add_aggregation( 'weight' ).
    lo_settings->add_aggregation( columnname  = 'item'
                                  aggregation = z2ui5_if_cgui_salv_c=>aggregation-minimum ).

    CLEAR temp18.
    INSERT `WEIGHT` INTO TABLE temp18.
    cl_abap_unit_assert=>assert_equals( exp = temp18
                                        act = lo_settings->mt_aggregation ).
    " no grid shown yet - no rows selected
    cl_abap_unit_assert=>assert_initial( lo_settings->get_selected_rows( ) ).

  ENDMETHOD.

ENDCLASS.
