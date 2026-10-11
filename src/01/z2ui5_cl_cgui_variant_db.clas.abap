"! Selection variants on the server - kept in table Z2UI5_CGUI_VAR, one
"! namespace per report as in the classic variant maintenance. A variant
"! belongs to the user who saved it first; shared it is seen by every user,
"! protected only its owner changes or deletes it, private nobody else
"! touches it. The default store of every report - set_variant_store( ) in
"! initialization( ) names another.
CLASS z2ui5_cl_cgui_variant_db DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_variant_store.

    CLASS-METHODS factory
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_variant_db.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS user
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_variant_db IMPLEMENTATION.

  METHOD factory.

    result = NEW #( ).

  ENDMETHOD.

  METHOD user.

    " sy-uname - as abap2UI5 keeps the owner of a draft; on ABAP Cloud the
    " technical name of the user
    result = sy-uname.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variant_store~check_sharing.

    result = abap_true.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variant_store~load.

    DATA ls_variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    DATA(lv_report) = CONV z2ui5_cgui_var-report( to_upper( report ) ).
    DATA(lv_user) = CONV z2ui5_cgui_var_owner( user( ) ).

    SELECT variant, owner, shared, protected, data
      FROM z2ui5_cgui_var
      WHERE report = @lv_report
        AND ( owner = @lv_user OR shared = @abap_true )
      ORDER BY variant
      INTO TABLE @DATA(lt_db).

    LOOP AT lt_db REFERENCE INTO DATA(lr_db).
      CLEAR ls_variant.
      TRY.
          CALL TRANSFORMATION id SOURCE XML lr_db->data
               RESULT text    = ls_variant-text
                      values  = ls_variant-values
                      protect = ls_variant-protect
                      hide    = ls_variant-hide.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      ls_variant-name      = lr_db->variant.
      ls_variant-owner     = lr_db->owner.
      ls_variant-shared    = lr_db->shared.
      ls_variant-protected = lr_db->protected.
      INSERT ls_variant INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variant_store~save.

    DATA ls_db TYPE z2ui5_cgui_var.

    ls_db-report  = to_upper( report ).
    ls_db-variant = variant-name.
    DATA(lv_user) = user( ).

    SELECT SINGLE owner, shared, protected
      FROM z2ui5_cgui_var
      WHERE report = @ls_db-report AND variant = @ls_db-variant
      INTO @DATA(ls_old).
    IF sy-subrc = 0.
      " another user's private variant is not in this user's list - saved
      " over, it was lost and the new one went to its owner, out of sight
      IF ls_old-shared = abap_false AND ls_old-owner <> lv_user.
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val = replace( val  = replace( val  = 'Variant &1 is a private variant of user &2'(002)
                                           sub  = `&1`
                                           with = variant-name )
                           sub  = `&2`
                           with = ls_old-owner ).
      ENDIF.
      IF ls_old-protected = abap_true AND ls_old-owner <> lv_user.
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val = replace( val  = replace( val  = 'Variant &1 is protected by user &2'(001)
                                           sub  = `&1`
                                           with = variant-name )
                           sub  = `&2`
                           with = ls_old-owner ).
      ENDIF.
      ls_db-owner = ls_old-owner.
    ELSE.
      ls_db-owner = lv_user.
    ENDIF.

    " the protection belongs to the owner - another user keeps it as it is
    ls_db-shared    = variant-shared.
    ls_db-protected = COND #( WHEN ls_db-owner = lv_user THEN variant-protected
                              ELSE ls_old-protected ).
    GET TIME STAMP FIELD ls_db-changed_at.
    CALL TRANSFORMATION id SOURCE text    = variant-text
                                  values  = variant-values
                                  protect = variant-protect
                                  hide    = variant-hide
                           RESULT XML ls_db-data.

    MODIFY z2ui5_cgui_var FROM @ls_db.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variant_store~delete.

    DATA(lv_report) = CONV z2ui5_cgui_var-report( to_upper( report ) ).
    DATA(lv_name) = CONV z2ui5_cgui_var_name( name ).

    SELECT SINGLE owner, shared, protected
      FROM z2ui5_cgui_var
      WHERE report = @lv_report AND variant = @lv_name
      INTO @DATA(ls_old).
    " another user's private variant is none of this user's business
    IF sy-subrc <> 0 OR ( ls_old-shared = abap_false AND ls_old-owner <> user( ) ).
      RETURN.
    ENDIF.
    IF ls_old-protected = abap_true AND ls_old-owner <> user( ).
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = replace( val  = replace( val  = 'Variant &1 is protected by user &2'(001)
                                         sub  = `&1`
                                         with = name )
                         sub  = `&2`
                         with = ls_old-owner ).
    ENDIF.

    DELETE FROM z2ui5_cgui_var WHERE report = @lv_report AND variant = @lv_name.

  ENDMETHOD.

ENDCLASS.
