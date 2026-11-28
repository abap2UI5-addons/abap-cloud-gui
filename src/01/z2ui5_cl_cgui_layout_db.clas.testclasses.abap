" the server store of the ALV layouts against its table - DANGEROUS, it
" writes Z2UI5_T_18; every row of the test report goes in teardown
CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL DANGEROUS.

  PRIVATE SECTION.
    CONSTANTS cv_report TYPE string VALUE `ZZ_CGUI_TEST_LAYOUT_DB`.
    CONSTANTS cv_handle TYPE string VALUE `MT_ROW`.

    DATA mo_store TYPE REF TO z2ui5_if_cgui_layouts.

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

    DATA temp1 TYPE z2ui5_t_18-report.
    DATA lv_report LIKE temp1.
    temp1 = cv_report.

    lv_report = temp1.
    DELETE FROM z2ui5_t_18 WHERE report = lv_report.
    " the store commits its writes, so the cleanup commits too
    COMMIT WORK.

  ENDMETHOD.

  METHOD layout.

    DATA temp2 TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp3 LIKE LINE OF temp2.
    CLEAR temp2.

    temp3-name = `CARRID`.
    temp3-text = `Airline`.
    temp3-hidden = abap_false.
    temp3-position = 2.
    temp3-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.
    temp3-sort_seq = 1.
    temp3-sum = abap_false.
    temp3-subtotal = abap_true.
    temp3-numeric = abap_false.
    INSERT temp3 INTO TABLE temp2.
    temp3-name = `PRICE`.
    temp3-text = `Price`.
    temp3-hidden = abap_true.
    temp3-position = 1.
    temp3-sort = ``.
    temp3-sort_seq = 0.
    temp3-sum = abap_true.
    temp3-subtotal = abap_false.
    temp3-numeric = abap_true.
    INSERT temp3 INTO TABLE temp2.
    result = temp2.

  ENDMETHOD.

  METHOD other_user.

    DATA ls_db TYPE z2ui5_t_18.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.

    ls_db-report    = cv_report.
    ls_db-handle    = cv_handle.
    ls_db-layout    = name.
    ls_db-owner     = `ZZ_OTHER`.
    ls_db-shared    = is_shared.
    ls_db-protected = is_protected.
    ls_db-is_default = abap_true.

    lt_layout = layout( ).
    CALL TRANSFORMATION id SOURCE layout = lt_layout
                           RESULT XML ls_db-data.
    MODIFY z2ui5_t_18 FROM ls_db.

  ENDMETHOD.

  METHOD save_load_delete.

    DATA temp4 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
    DATA lt_saved TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
    DATA ls_saved LIKE LINE OF lt_saved.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_saved.
    DATA temp2 LIKE sy-tabix.
    DATA temp5 TYPE string.
    CLEAR temp4.
    temp4-name = `MINE`.
    temp4-layout = layout( ).
    temp4-shared = abap_true.
    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = temp4 ).


    lt_saved = mo_store->load( report = cv_report
                                     handle = cv_handle ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_saved )
                                        exp = 1 ).



    temp2 = sy-tabix.
    READ TABLE lt_saved INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_saved = <temp1>.
    cl_abap_unit_assert=>assert_equals( act = ls_saved-name
                                        exp = `MINE` ).

    temp5 = sy-uname.
    cl_abap_unit_assert=>assert_equals( act = ls_saved-owner
                                        exp = temp5 ).
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

    DATA temp6 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
    DATA temp7 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
    DATA lt_saved TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
    FIELD-SYMBOLS <temp8> LIKE LINE OF lt_saved.
    DATA temp9 LIKE sy-tabix.
    FIELD-SYMBOLS <temp10> LIKE LINE OF lt_saved.
    DATA temp11 LIKE sy-tabix.
    CLEAR temp6.
    temp6-name = `FIRST`.
    temp6-layout = layout( ).
    temp6-is_default = abap_true.
    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = temp6 ).

    CLEAR temp7.
    temp7-name = `SECOND`.
    temp7-layout = layout( ).
    temp7-is_default = abap_true.
    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = temp7 ).


    lt_saved = mo_store->load( report = cv_report
                                     handle = cv_handle ).


    temp9 = sy-tabix.
    READ TABLE lt_saved WITH KEY name = `FIRST` ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp8>-is_default ).


    temp11 = sy-tabix.
    READ TABLE lt_saved WITH KEY name = `SECOND` ASSIGNING <temp10>.
    sy-tabix = temp11.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp10>-is_default ).

  ENDMETHOD.

  METHOD other_users_layouts.
    DATA lt_saved TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lt_saved.
    DATA temp13 LIKE sy-tabix.
    FIELD-SYMBOLS <temp14> LIKE LINE OF lt_saved.
    DATA temp15 LIKE sy-tabix.
        DATA temp16 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
        DATA temp17 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
    DATA temp18 TYPE z2ui5_t_18-report.
    DATA lv_report LIKE temp18.
    DATA temp19 TYPE z2ui5_t_18-handle.
    DATA lv_handle LIKE temp19.
    DATA temp20 TYPE z2ui5_t_18-layout.
    DATA lv_private LIKE temp20.
    DATA lv_owner TYPE z2ui5_t_18-owner.

    other_user( name         = `THEIRS`
                is_shared    = abap_true
                is_protected = abap_true ).
    other_user( name         = `PRIVATE`
                is_shared    = abap_false
                is_protected = abap_false ).

    " the shared one only - and its default is its owner's

    lt_saved = mo_store->load( report = cv_report
                                     handle = cv_handle ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_saved )
                                        exp = 1 ).


    temp13 = sy-tabix.
    READ TABLE lt_saved INDEX 1 ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp12>-name
                                        exp = `THEIRS` ).


    temp15 = sy-tabix.
    READ TABLE lt_saved INDEX 1 ASSIGNING <temp14>.
    sy-tabix = temp15.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp14>-is_default ).

    " protected - neither changed nor deleted by another user
    TRY.

        CLEAR temp16.
        temp16-name = `THEIRS`.
        temp16-layout = layout( ).
        mo_store->save( report = cv_report
                        handle = cv_handle
                        layout = temp16 ).
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

    " private - not saved over: it was lost, and the new one went to its owner
    TRY.

        CLEAR temp17.
        temp17-name = `PRIVATE`.
        temp17-layout = layout( ).
        mo_store->save( report = cv_report
                        handle = cv_handle
                        layout = temp17 ).
        cl_abap_unit_assert=>fail( `a private layout of another user was saved over` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused, as it should be
    ENDTRY.
    TRY.
        mo_store->delete( report = cv_report
                          handle = cv_handle
                          name   = `PRIVATE` ).
      CATCH z2ui5_cx_cgui_error ##NO_HANDLER.
        " refused is fine as well - the row must stay either way
    ENDTRY.

    temp18 = cv_report.

    lv_report = temp18.

    temp19 = cv_handle.

    lv_handle = temp19.

    temp20 = `PRIVATE`.

    lv_private = temp20.

    SELECT SINGLE owner FROM z2ui5_t_18 INTO lv_owner
      WHERE report = lv_report AND handle = lv_handle AND layout = lv_private
      .
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_owner
                                        exp = `ZZ_OTHER` ).

  ENDMETHOD.

  METHOD handles_apart.

    DATA temp21 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
    CLEAR temp21.
    temp21-name = `MINE`.
    temp21-layout = layout( ).
    mo_store->save( report = cv_report
                    handle = cv_handle
                    layout = temp21 ).

    cl_abap_unit_assert=>assert_initial( mo_store->load( report = cv_report
                                                         handle = `MT_OTHER` ) ).

  ENDMETHOD.

ENDCLASS.
