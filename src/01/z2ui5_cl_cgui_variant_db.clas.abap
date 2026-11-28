"! Selection variants on the server - kept in table Z2UI5_T_19, one
"! namespace per report as in the classic variant maintenance. A variant
"! belongs to the user who saved it first; shared it is seen by every user,
"! protected only its owner changes or deletes it, private nobody else
"! touches it. The default store of every report - set_variant_store( ) in
"! initialization( ) names another.
CLASS z2ui5_cl_cgui_variant_db DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_variants.

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

    CREATE OBJECT result.

  ENDMETHOD.

  METHOD user.

    " sy-uname - as abap2UI5 keeps the owner of a draft; on ABAP Cloud the
    " technical name of the user
    result = sy-uname.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variants~check_sharing.

    result = abap_true.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variants~load.

    DATA ls_variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    DATA temp12 TYPE z2ui5_t_19-report.
    DATA lv_report LIKE temp12.
    DATA temp13 TYPE z2ui5_cgui_var_owner.
    DATA lv_user LIKE temp13.
TYPES BEGIN OF temp14.
TYPES variant TYPE z2ui5_t_19-variant.
TYPES owner TYPE z2ui5_t_19-owner.
TYPES shared TYPE z2ui5_t_19-shared.
TYPES protected TYPE z2ui5_t_19-protected.
TYPES data TYPE z2ui5_t_19-data.
TYPES END OF temp14.
    DATA lt_db TYPE STANDARD TABLE OF temp14 WITH DEFAULT KEY.
    DATA temp15 LIKE LINE OF lt_db.
    DATA lr_db LIKE REF TO temp15.
    temp12 = to_upper( report ).

    lv_report = temp12.

    temp13 = user( ).

    lv_user = temp13.



    SELECT variant owner shared protected data
      FROM z2ui5_t_19 INTO TABLE lt_db
      WHERE report = lv_report
        AND ( owner = lv_user OR shared = abap_true )
      ORDER BY variant
      .



    LOOP AT lt_db REFERENCE INTO lr_db.
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

  METHOD z2ui5_if_cgui_variants~save.

    DATA ls_db TYPE z2ui5_t_19.
    DATA lv_user TYPE string.
DATA BEGIN OF ls_old.
DATA owner TYPE z2ui5_t_19-owner.
DATA shared TYPE z2ui5_t_19-shared.
DATA protected TYPE z2ui5_t_19-protected.
DATA END OF ls_old.
    DATA temp16 TYPE z2ui5_cgui_var_shared.
    DATA temp17 TYPE z2ui5_cgui_var_protected.

    ls_db-report  = to_upper( report ).
    ls_db-variant = variant-name.

    lv_user = user( ).


    SELECT SINGLE owner shared protected
      FROM z2ui5_t_19 INTO ls_old
      WHERE report = ls_db-report AND variant = ls_db-variant
      .
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

    " sharing and protection belong to the owner - another user keeps them
    " as they are: a shared variant saved over stays in everyone's list

    IF ls_db-owner = lv_user.
      temp16 = variant-shared.
    ELSE.
      temp16 = ls_old-shared.
    ENDIF.
    ls_db-shared    = temp16.

    IF ls_db-owner = lv_user.
      temp17 = variant-protected.
    ELSE.
      temp17 = ls_old-protected.
    ENDIF.
    ls_db-protected = temp17.
    GET TIME STAMP FIELD ls_db-changed_at.
    CALL TRANSFORMATION id SOURCE text    = variant-text
                                  values  = variant-values
                                  protect = variant-protect
                                  hide    = variant-hide
                           RESULT XML ls_db-data.

    MODIFY z2ui5_t_19 FROM ls_db.
    " abap2UI5 rolls back what an app leaves open after its main( )
    COMMIT WORK.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_variants~delete.

    DATA temp18 TYPE z2ui5_t_19-report.
    DATA lv_report LIKE temp18.
    DATA temp19 TYPE z2ui5_cgui_var_name.
    DATA lv_name LIKE temp19.
DATA BEGIN OF ls_old.
DATA owner TYPE z2ui5_t_19-owner.
DATA shared TYPE z2ui5_t_19-shared.
DATA protected TYPE z2ui5_t_19-protected.
DATA END OF ls_old.
    temp18 = to_upper( report ).

    lv_report = temp18.

    temp19 = name.

    lv_name = temp19.


    SELECT SINGLE owner shared protected
      FROM z2ui5_t_19 INTO ls_old
      WHERE report = lv_report AND variant = lv_name
      .
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

    DELETE FROM z2ui5_t_19 WHERE report = lv_report AND variant = lv_name.
    COMMIT WORK.

  ENDMETHOD.

ENDCLASS.
