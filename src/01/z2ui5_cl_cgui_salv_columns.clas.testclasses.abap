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

    DATA(lo_columns) = NEW z2ui5_cl_cgui_salv_columns( ls_item ).
    DATA(lt_column) = lo_columns->get( ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_column ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'WEIGHT'
                                        act = lt_column[ 3 ]-columnname ).
    cl_abap_unit_assert=>assert_equals( exp = `NAME`
                                        act = lt_column[ 2 ]-r_column->get_columnname( ) ).

  ENDMETHOD.

  METHOD column_settings.

    DATA ls_item TYPE ty_s_item.

    DATA(lo_column) = NEW z2ui5_cl_cgui_salv_columns( ls_item )->get_column( 'weight' ).
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

    TRY.
        NEW z2ui5_cl_cgui_salv_columns( ls_item )->get_column( 'PRICE' ).
        cl_abap_unit_assert=>fail( `a column that is not there - cx_salv_not_found` ).
      CATCH z2ui5_cx_cgui_salv INTO DATA(lx_salv).
        cl_abap_unit_assert=>assert_equals( exp = `No column PRICE`
                                            act = lx_salv->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD settings_of_the_table.

    DATA(lo_settings) = NEW z2ui5_cl_cgui_salv_settings( ).
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
    cl_abap_unit_assert=>assert_equals( exp = `Weigh again`
                                        act = lo_settings->mt_function[ 1 ]-text ).
    " no grid shown yet - no rows selected
    cl_abap_unit_assert=>assert_initial( lo_settings->get_selected_rows( ) ).

  ENDMETHOD.

ENDCLASS.
