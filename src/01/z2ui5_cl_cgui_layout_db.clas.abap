"! ALV layouts on the server - kept in table Z2UI5_T_18, one namespace
"! per report and ALV handle as in the classic layout maintenance. A layout
"! belongs to the user who saved it first; shared it is seen by every user,
"! protected only its owner changes or deletes it, private nobody else
"! touches it. The default layout is personal: the flag of a layout counts
"! for its owner only. The report runtime uses this store unless
"! set_layout_store( ) names another one.
CLASS z2ui5_cl_cgui_layout_db DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_layouts.

    CLASS-METHODS factory
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_layout_db.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS user
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS protected_error
      IMPORTING
        name  TYPE clike
        owner TYPE clike
      RAISING
        z2ui5_cx_cgui_error.

ENDCLASS.


CLASS z2ui5_cl_cgui_layout_db IMPLEMENTATION.

  METHOD factory.

    CREATE OBJECT result.

  ENDMETHOD.

  METHOD user.

    " sy-uname - as abap2UI5 keeps the owner of a draft; on ABAP Cloud the
    " technical name of the user
    result = sy-uname.

  ENDMETHOD.

  METHOD protected_error.

    RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
      EXPORTING
        val = replace( val  = replace( val  = 'Layout &1 is protected by user &2'(001)
                                       sub  = `&1`
                                       with = name )
                       sub  = `&2`
                       with = owner ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~check_sharing.

    result = abap_true.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~load.

    DATA ls_saved TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
    DATA lt_other TYPE z2ui5_cl_cgui_layout=>ty_t_saved.

    DATA temp22 TYPE z2ui5_t_18-report.
    DATA lv_report LIKE temp22.
    DATA temp23 TYPE z2ui5_t_18-handle.
    DATA lv_handle LIKE temp23.
    DATA temp24 TYPE z2ui5_t_18-owner.
    DATA lv_user LIKE temp24.
TYPES BEGIN OF temp25.
TYPES layout TYPE z2ui5_t_18-layout.
TYPES owner TYPE z2ui5_t_18-owner.
TYPES shared TYPE z2ui5_t_18-shared.
TYPES protected TYPE z2ui5_t_18-protected.
TYPES is_default TYPE z2ui5_t_18-is_default.
TYPES data TYPE z2ui5_t_18-data.
TYPES END OF temp25.
    DATA lt_db TYPE STANDARD TABLE OF temp25 WITH DEFAULT KEY.
    DATA ls_db LIKE LINE OF lt_db.
    temp22 = to_upper( report ).

    lv_report = temp22.

    temp23 = to_upper( handle ).

    lv_handle = temp23.

    temp24 = user( ).

    lv_user = temp24.



    SELECT layout owner shared protected is_default data
      FROM z2ui5_t_18 INTO TABLE lt_db
      WHERE report = lv_report
        AND handle = lv_handle
        AND ( owner = lv_user OR shared = abap_true )
      ORDER BY layout
      .

    " his own layouts first, then the shared ones of the other users

    LOOP AT lt_db INTO ls_db.
      CLEAR ls_saved.
      TRY.
          CALL TRANSFORMATION id SOURCE XML ls_db-data
               RESULT layout = ls_saved-layout.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      ls_saved-name      = ls_db-layout.
      ls_saved-owner     = ls_db-owner.
      ls_saved-shared    = ls_db-shared.
      ls_saved-protected = ls_db-protected.
      IF ls_db-owner = lv_user.
        ls_saved-is_default = ls_db-is_default.
        INSERT ls_saved INTO TABLE result.
      ELSE.
        INSERT ls_saved INTO TABLE lt_other.
      ENDIF.
    ENDLOOP.
    INSERT LINES OF lt_other INTO TABLE result.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~save.

    DATA ls_db TYPE z2ui5_t_18.
    DATA temp26 TYPE z2ui5_t_18-owner.
    DATA lv_user LIKE temp26.
DATA BEGIN OF ls_old.
DATA owner TYPE z2ui5_t_18-owner.
DATA shared TYPE z2ui5_t_18-shared.
DATA protected TYPE z2ui5_t_18-protected.
DATA is_default TYPE z2ui5_t_18-is_default.
DATA END OF ls_old.

    ls_db-report = to_upper( report ).
    ls_db-handle = to_upper( handle ).
    ls_db-layout = layout-name.

    temp26 = user( ).

    lv_user = temp26.


    SELECT SINGLE owner shared protected is_default
      FROM z2ui5_t_18 INTO ls_old
      WHERE report = ls_db-report AND handle = ls_db-handle AND layout = ls_db-layout
      .
    IF sy-subrc = 0.
      " another user's private layout is not in this user's list - saved
      " over, it was lost and the new one went to its owner, out of sight
      IF ls_old-shared = abap_false AND ls_old-owner <> lv_user.
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val = replace( val  = replace( val  = 'Layout &1 is a private layout of user &2'(002)
                                           sub  = `&1`
                                           with = layout-name )
                           sub  = `&2`
                           with = ls_old-owner ).
      ENDIF.
      IF ls_old-protected = abap_true AND ls_old-owner <> lv_user.
        protected_error( name  = layout-name
                         owner = ls_old-owner ).
      ENDIF.
      ls_db-owner = ls_old-owner.
    ELSE.
      ls_db-owner = lv_user.
    ENDIF.

    " protection and default belong to the owner - another user keeps them
    ls_db-shared = layout-shared.
    IF ls_db-owner = lv_user.
      ls_db-protected  = layout-protected.
      ls_db-is_default = layout-is_default.
    ELSE.
      ls_db-protected  = ls_old-protected.
      ls_db-is_default = ls_old-is_default.
    ENDIF.
    GET TIME STAMP FIELD ls_db-changed_at.
    CALL TRANSFORMATION id SOURCE layout = layout-layout
                           RESULT XML ls_db-data.

    " one default layout per user
    IF ls_db-is_default = abap_true AND ls_db-owner = lv_user.
      UPDATE z2ui5_t_18 SET is_default = abap_false
        WHERE report = ls_db-report AND handle = ls_db-handle
          AND owner = lv_user AND is_default = abap_true
          AND layout <> ls_db-layout.
    ENDIF.

    MODIFY z2ui5_t_18 FROM ls_db.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~delete.

    DATA temp27 TYPE z2ui5_t_18-report.
    DATA lv_report LIKE temp27.
    DATA temp28 TYPE z2ui5_t_18-handle.
    DATA lv_handle LIKE temp28.
    DATA temp29 TYPE z2ui5_t_18-layout.
    DATA lv_name LIKE temp29.
DATA BEGIN OF ls_old.
DATA owner TYPE z2ui5_t_18-owner.
DATA shared TYPE z2ui5_t_18-shared.
DATA protected TYPE z2ui5_t_18-protected.
DATA END OF ls_old.
    temp27 = to_upper( report ).

    lv_report = temp27.

    temp28 = to_upper( handle ).

    lv_handle = temp28.

    temp29 = name.

    lv_name = temp29.


    SELECT SINGLE owner shared protected
      FROM z2ui5_t_18 INTO ls_old
      WHERE report = lv_report AND handle = lv_handle AND layout = lv_name
      .
    " another user's private layout is none of this user's business
    IF sy-subrc <> 0 OR ( ls_old-shared = abap_false AND ls_old-owner <> user( ) ).
      RETURN.
    ENDIF.
    IF ls_old-protected = abap_true AND ls_old-owner <> user( ).
      protected_error( name  = name
                       owner = ls_old-owner ).
    ENDIF.

    DELETE FROM z2ui5_t_18 WHERE report = lv_report AND handle = lv_handle AND layout = lv_name.

  ENDMETHOD.

ENDCLASS.
