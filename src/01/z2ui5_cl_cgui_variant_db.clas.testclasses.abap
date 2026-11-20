" the server store of the selection variants against its table - DANGEROUS,
" it writes Z2UI5_T_19; every row of the test report goes in teardown
CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL DANGEROUS.

  PRIVATE SECTION.
    CONSTANTS cv_report TYPE string VALUE `ZZ_CGUI_TEST_VARIANT_DB`.

    DATA mo_store TYPE REF TO z2ui5_if_cgui_variants.

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

    DATA temp1 TYPE z2ui5_t_19-report.
    DATA lv_report LIKE temp1.
    temp1 = cv_report.

    lv_report = temp1.
    DELETE FROM z2ui5_t_19 WHERE report = lv_report.

  ENDMETHOD.

  METHOD variant.
    DATA temp2 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp3 LIKE LINE OF temp2.
    DATA temp4 TYPE string_table.

    result-name = name.
    result-text = `Lufthansa in the first quarter`.

    CLEAR temp2.

    temp3-name = `P_CARRID`.
    temp3-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
    temp3-sign = `I`.
    temp3-option = `EQ`.
    temp3-low = `LH`.
    temp3-high = ``.
    INSERT temp3 INTO TABLE temp2.
    temp3-name = `S_DATE`.
    temp3-kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
    temp3-sign = `I`.
    temp3-option = `BT`.
    temp3-low = `20260101`.
    temp3-high = `20260331`.
    INSERT temp3 INTO TABLE temp2.
    result-values = temp2.

    CLEAR temp4.
    INSERT `P_CARRID` INTO TABLE temp4.
    result-protect = temp4.

  ENDMETHOD.

  METHOD save_load_delete.

    DATA ls_variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA ls_loaded LIKE LINE OF lt_variant.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_variant.
    DATA temp2 LIKE sy-tabix.
    DATA temp6 TYPE string.
    ls_variant = variant( `Q1` ).
    ls_variant-shared = abap_true.
    mo_store->save( report  = cv_report
                    variant = ls_variant ).


    lt_variant = mo_store->load( cv_report ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_variant )
                                        exp = 1 ).



    temp2 = sy-tabix.
    READ TABLE lt_variant INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_loaded = <temp1>.
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-name
                                        exp = `Q1` ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-text
                                        exp = ls_variant-text ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-values
                                        exp = ls_variant-values ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-protect
                                        exp = ls_variant-protect ).

    temp6 = sy-uname.
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-owner
                                        exp = temp6 ).
    cl_abap_unit_assert=>assert_true( ls_loaded-shared ).
    cl_abap_unit_assert=>assert_true( mo_store->check_sharing( ) ).

    mo_store->delete( report = cv_report
                      name   = `Q1` ).
    cl_abap_unit_assert=>assert_initial( mo_store->load( cv_report ) ).

  ENDMETHOD.

  METHOD other_users_variants.

    DATA ls_db TYPE z2ui5_t_19.

    " a protected, shared variant of another user and a private one,
    " written past the store
    DATA ls_variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_variant.
    DATA temp8 LIKE sy-tabix.
    DATA temp9 TYPE z2ui5_t_19-report.
    DATA lv_report LIKE temp9.
    DATA temp10 TYPE z2ui5_t_19-variant.
    DATA lv_private LIKE temp10.
    DATA lv_owner TYPE z2ui5_t_19-owner.
    ls_variant = variant( `THEIRS` ).
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
    MODIFY z2ui5_t_19 FROM ls_db.
    ls_db-variant   = `PRIVATE`.
    ls_db-shared    = abap_false.
    ls_db-protected = abap_false.
    MODIFY z2ui5_t_19 FROM ls_db.


    lt_variant = mo_store->load( cv_report ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_variant )
                                        exp = 1 ).


    temp8 = sy-tabix.
    READ TABLE lt_variant INDEX 1 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp7>-name
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

    " private - not saved over: it was lost, and the new one went to its owner
    TRY.
        mo_store->save( report  = cv_report
                        variant = variant( `PRIVATE` ) ).
        cl_abap_unit_assert=>fail( `a private variant of another user was saved over` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused, as it should be
    ENDTRY.
    TRY.
        mo_store->delete( report = cv_report
                          name   = `PRIVATE` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused is fine as well - the row must stay either way
    ENDTRY.

    temp9 = cv_report.

    lv_report = temp9.

    temp10 = `PRIVATE`.

    lv_private = temp10.

    SELECT SINGLE owner FROM z2ui5_t_19 INTO lv_owner
      WHERE report = lv_report AND variant = lv_private
      .
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_owner
                                        exp = `ZZ_OTHER` ).

  ENDMETHOD.

ENDCLASS.
