*&---------------------------------------------------------------------*
*& Report ZR2C_05_REUSE
*&---------------------------------------------------------------------*
*& Airlines with REUSE_ALV_GRID_DISPLAY: a field catalog built by hand
*& and a USER_COMMAND callback for the double click
*&---------------------------------------------------------------------*
REPORT zr2c_05_reuse.

TYPE-POOLS slis.

TABLES scarr.

DATA: gt_scarr    TYPE STANDARD TABLE OF scarr,
      gs_scarr    TYPE scarr,
      gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_fieldcat TYPE slis_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv.

PARAMETERS p_curr TYPE scarr-currcode.

START-OF-SELECTION.
  IF p_curr IS INITIAL.
    SELECT * FROM scarr INTO TABLE gt_scarr.
  ELSE.
    SELECT * FROM scarr INTO TABLE gt_scarr WHERE currcode = p_curr.
  ENDIF.

  PERFORM build_fieldcat.

  gs_layout-zebra = 'X'.
  gs_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_user_command = 'USER_COMMAND'
      i_grid_title            = 'Airlines'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat
    TABLES
      t_outtab                = gt_scarr
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
  IF sy-subrc <> 0.
    MESSAGE 'The grid could not be displayed' TYPE 'E'.
  ENDIF.

FORM build_fieldcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'MANDT'.
  gs_fieldcat-no_out    = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'CARRID'.
  gs_fieldcat-seltext_m = 'Airline'.
  gs_fieldcat-key       = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'CARRNAME'.
  gs_fieldcat-seltext_m = 'Name'.
  gs_fieldcat-outputlen = 25.
  APPEND gs_fieldcat TO gt_fieldcat.

  APPEND VALUE #( fieldname = 'CURRCODE' seltext_m = 'Currency' ) TO gt_fieldcat.
  APPEND VALUE #( fieldname = 'URL' seltext_m = 'Website' ) TO gt_fieldcat.
ENDFORM.

FORM user_command USING r_ucomm     LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.
  CASE r_ucomm.
    WHEN '&IC1'.
      READ TABLE gt_scarr INTO gs_scarr INDEX rs_selfield-tabindex.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gs_scarr TO scarr.
        MESSAGE |{ scarr-carrname }: { scarr-url }| TYPE 'I'.
      ENDIF.
  ENDCASE.
ENDFORM.
