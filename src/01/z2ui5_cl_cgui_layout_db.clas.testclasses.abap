" the server store of the ALV layouts against its table - DANGEROUS, it
" writes Z2UI5_CGUI_LAY; every row of the test report goes in teardown
CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL DANGEROUS.

  PRIVATE SECTION.
    CONSTANTS cv_report TYPE string VALUE `ZZ_CGUI_TEST_LAYOUT_DB`.
    CONSTANTS cv_handle TYPE string VALUE `MT_ROW`.

    DATA mo_store TYPE REF TO z2ui5_if_cgui_layout_store.

    METHODS setup.
    METHODS teardown.
    "! every row of the test report - SETUP and TEARDOWN cannot call each other
    METHODS delete_test_rows.

    METHODS layout
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_alv=>ty_t_layout.

    "! a row of another user, written past the store
    METHODS other_user
      IMPORTING
        name         TYPE clike
        is_shared    TYPE abap_bool
        is_protected TYPE abap_bool.

    METHODS save_load_delete FOR TESTING RAISING z2ui5_cx_cgui_error.
    METHODS one_default_per_user FOR TESTING RAISING z2ui5_cx_cgui_error.
    METHODS other_users_layouts FOR TESTING.
    METHODS handles_apart FOR TESTING RAISING z2ui5_cx_cgui_error.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_store = z2ui5_cl_cgui_layout_db=>factory( ).
    delete_test_rows( ).

  ENDMETHOD.

  METHOD teardown.

    delete_test_rows( ).

  ENDMETHOD.

  METHOD delete_test_rows.

    DATA(lv_report) = CONV z2ui5_cgui_lay-report( cv_report ).
    DELETE FROM z2ui5_cgui_lay WHERE report = @lv_report.

  ENDMETHOD.

  METHOD layout.

    result = VALUE #( ( name = `CARRID` text = `Airline` hidden = abap_false position = 2 sort = z2ui5_cl_cgui_alv=>cs_sort-ascending
                        sort_seq = 1 sum = abap_false subtotal = abap_true numeric = abap_false )
                      ( name = `PRICE` text = `Price` hidden = abap_true position = 1 sort = ``
                        sort_seq = 0 sum = abap_true subtotal = abap_false numeric = abap_true ) ).

  ENDMETHOD.

  METHOD other_user.

    DATA ls_db TYPE z2ui5_cgui_lay.

    ls_db-report    = cv_report.
    ls_db-handle    = cv_handle.
    ls_db-layout    = name.
    ls_db-owner     = `ZZ_OTHER`.
    ls_db-shared    = is_shared.
    ls_db-protected = is_protected.
    ls_db-is_default = abap_true.
    DATA(lt_layout) = layout( ).
    CALL TRANSFORMATION id SOURCE layout = lt_layout
                           RESULT XML ls_db-data.
    MODIFY z2ui5_cgui_lay FROM @ls_db.

  ENDMETHOD.

  METHOD save_load_delete.

    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = VALUE #( name = `MINE` layout = layout( ) shared = abap_true ) ).

    DATA(lt_saved) = mo_store->load( report = cv_report
                                     handle = cv_handle ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_saved )
                                        exp = 1 ).
    DATA(ls_saved) = lt_saved[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = ls_saved-name
                                        exp = `MINE` ).
    cl_abap_unit_assert=>assert_equals( act = ls_saved-owner
                                        exp = CONV string( sy-uname ) ).
    cl_abap_unit_assert=>assert_true( ls_saved-shared ).
    " the columns as they were saved
    cl_abap_unit_assert=>assert_equals( act = ls_saved-layout
                                        exp = layout( ) ).
    cl_abap_unit_assert=>assert_true( mo_store->check_sharing( ) ).

    mo_store->delete( report = cv_report
                      handle = cv_handle
                      name   = `MINE` ).
    cl_abap_unit_assert=>assert_initial( mo_store->load( report = cv_report
                                                         handle = cv_handle ) ).

  ENDMETHOD.

  METHOD one_default_per_user.

    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = VALUE #( name = `FIRST` layout = layout( ) is_default = abap_true ) ).
    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = VALUE #( name = `SECOND` layout = layout( ) is_default = abap_true ) ).

    DATA(lt_saved) = mo_store->load( report = cv_report
                                     handle = cv_handle ).
    cl_abap_unit_assert=>assert_false( lt_saved[ name = `FIRST` ]-is_default ).
    cl_abap_unit_assert=>assert_true( lt_saved[ name = `SECOND` ]-is_default ).

  ENDMETHOD.

  METHOD other_users_layouts.

    other_user( name         = `THEIRS`
                is_shared    = abap_true
                is_protected = abap_true ).
    other_user( name         = `PRIVATE`
                is_shared    = abap_false
                is_protected = abap_false ).

    " the shared one only - and its default is its owner's
    DATA(lt_saved) = mo_store->load( report = cv_report
                                     handle = cv_handle ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_saved )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_saved[ 1 ]-name
                                        exp = `THEIRS` ).
    cl_abap_unit_assert=>assert_false( lt_saved[ 1 ]-is_default ).

    " protected - neither changed nor deleted by another user
    TRY.
        mo_store->save( report = cv_report
                        handle = cv_handle
                        layout = VALUE #( name = `THEIRS` layout = layout( ) ) ).
        cl_abap_unit_assert=>fail( `a protected layout of another user was changed` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused, as it should be
    ENDTRY.
    TRY.
        mo_store->delete( report = cv_report
                          handle = cv_handle
                          name   = `THEIRS` ).
        cl_abap_unit_assert=>fail( `a protected layout of another user was deleted` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused, as it should be
    ENDTRY.

  ENDMETHOD.

  METHOD handles_apart.

    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = VALUE #( name = `MINE` layout = layout( ) ) ).

    cl_abap_unit_assert=>assert_initial( mo_store->load( report = cv_report
                                                         handle = `MT_OTHER` ) ).

  ENDMETHOD.

ENDCLASS.
