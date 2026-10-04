" the server store of the selection variants against its table - DANGEROUS,
" it writes Z2UI5_CGUI_VAR; every row of the test report goes in teardown
CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL DANGEROUS.

  PRIVATE SECTION.
    CONSTANTS cv_report TYPE string VALUE `ZZ_CGUI_TEST_VARIANT_DB`.

    DATA mo_store TYPE REF TO z2ui5_if_cgui_variant_store.

    METHODS setup.
    METHODS teardown.
    "! every row of the test report - SETUP and TEARDOWN cannot call each other
    METHODS delete_test_rows.

    METHODS variant
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    METHODS save_load_delete FOR TESTING RAISING z2ui5_cx_cgui_error.
    METHODS other_users_variants FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_store = z2ui5_cl_cgui_variant_db=>factory( ).
    delete_test_rows( ).

  ENDMETHOD.

  METHOD teardown.

    delete_test_rows( ).

  ENDMETHOD.

  METHOD delete_test_rows.

    DATA(lv_report) = CONV z2ui5_cgui_var-report( cv_report ).
    DELETE FROM z2ui5_cgui_var WHERE report = @lv_report.

  ENDMETHOD.

  METHOD variant.

    result-name = name.
    result-text = `Lufthansa in the first quarter`.
    result-values = VALUE #( ( name = `P_CARRID` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter
                               sign = `I` option = `EQ` low = `LH` high = `` )
                             ( name = `S_DATE` kind = z2ui5_cl_cgui_variant=>cs_kind-select_option
                               sign = `I` option = `BT` low = `20260101` high = `20260331` ) ).
    result-protect = VALUE #( ( `P_CARRID` ) ).

  ENDMETHOD.

  METHOD save_load_delete.

    DATA(ls_variant) = variant( `Q1` ).
    ls_variant-shared = abap_true.
    mo_store->save( report  = cv_report
                    variant = ls_variant ).

    DATA(lt_variant) = mo_store->load( cv_report ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_variant )
                                        exp = 1 ).
    DATA(ls_loaded) = lt_variant[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-name
                                        exp = `Q1` ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-text
                                        exp = ls_variant-text ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-values
                                        exp = ls_variant-values ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-protect
                                        exp = ls_variant-protect ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-owner
                                        exp = CONV string( sy-uname ) ).
    cl_abap_unit_assert=>assert_true( ls_loaded-shared ).
    cl_abap_unit_assert=>assert_true( mo_store->check_sharing( ) ).

    mo_store->delete( report = cv_report
                      name   = `Q1` ).
    cl_abap_unit_assert=>assert_initial( mo_store->load( cv_report ) ).

  ENDMETHOD.

  METHOD other_users_variants.

    DATA ls_db TYPE z2ui5_cgui_var.

    " a protected, shared variant of another user and a private one,
    " written past the store
    DATA(ls_variant) = variant( `THEIRS` ).
    ls_db-report    = cv_report.
    ls_db-owner     = `ZZ_OTHER`.
    ls_db-shared    = abap_true.
    ls_db-protected = abap_true.
    ls_db-variant   = `THEIRS`.
    CALL TRANSFORMATION id SOURCE text    = ls_variant-text
                                  values  = ls_variant-values
                                  protect = ls_variant-protect
                                  hide    = ls_variant-hide
                           RESULT XML ls_db-data.
    MODIFY z2ui5_cgui_var FROM @ls_db.
    ls_db-variant   = `PRIVATE`.
    ls_db-shared    = abap_false.
    ls_db-protected = abap_false.
    MODIFY z2ui5_cgui_var FROM @ls_db.

    DATA(lt_variant) = mo_store->load( cv_report ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_variant )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_variant[ 1 ]-name
                                        exp = `THEIRS` ).

    TRY.
        mo_store->save( report  = cv_report
                        variant = ls_variant ).
        cl_abap_unit_assert=>fail( `a protected variant of another user was changed` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused, as it should be
    ENDTRY.
    TRY.
        mo_store->delete( report = cv_report
                          name   = `THEIRS` ).
        cl_abap_unit_assert=>fail( `a protected variant of another user was deleted` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused, as it should be
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
