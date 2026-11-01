*&---------------------------------------------------------------------*
*& Report ZR2C_06_DYNAMIC
*&---------------------------------------------------------------------*
*& A dynamic selection screen: radio buttons with USER-COMMAND switch
*& between two groups of fields (MODIF ID), a checkbox shows expert
*& fields, a push button resets the screen, an own F4 for the plant
*&---------------------------------------------------------------------*
REPORT zr2c_06_dynamic.

TABLES sscrfields.

TYPES: BEGIN OF ty_plant,
         werks TYPE c LENGTH 4,
         name  TYPE c LENGTH 30,
       END OF ty_plant.

DATA gt_plant TYPE STANDARD TABLE OF ty_plant WITH DEFAULT KEY.

SELECTION-SCREEN BEGIN OF BLOCK mode WITH FRAME TITLE TEXT-m01.
PARAMETERS: p_disp RADIOBUTTON GROUP mode DEFAULT 'X' USER-COMMAND mode,
            p_crea RADIOBUTTON GROUP mode.
SELECTION-SCREEN END OF BLOCK mode.

SELECTION-SCREEN BEGIN OF BLOCK data WITH FRAME TITLE TEXT-d01.
PARAMETERS: p_matnr TYPE c LENGTH 18 MODIF ID dis,
            p_name  TYPE c LENGTH 40 LOWER CASE MODIF ID cre,
            p_qty   TYPE i MODIF ID cre.
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) TEXT-l01 FOR FIELD p_unit.
PARAMETERS p_unit TYPE c LENGTH 3 DEFAULT 'PC'.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN COMMENT /1(60) TEXT-c01 MODIF ID cre.
PARAMETERS p_source TYPE string NO-DISPLAY.
SELECTION-SCREEN END OF BLOCK data.

SELECTION-SCREEN BEGIN OF BLOCK expert WITH FRAME TITLE TEXT-e01.
PARAMETERS: p_expert AS CHECKBOX USER-COMMAND expert,
            p_plant  TYPE c LENGTH 4 MODIF ID exp,
            p_token  TYPE c LENGTH 32 LOWER CASE MODIF ID exp.
SELECTION-SCREEN ULINE.
SELECTION-SCREEN PUSHBUTTON /1(20) b_reset USER-COMMAND reset.
SELECTION-SCREEN END OF BLOCK expert.

INITIALIZATION.
  b_reset = 'Reset'.
  p_source = sy-repid.
  gt_plant = VALUE #( ( werks = '1000' name = 'Hamburg' )
                      ( werks = '2000' name = 'Walldorf' )
                      ( werks = '3000' name = 'Berlin' ) ).

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'DIS'.
        IF p_disp = abap_true.
          screen-active = '1'.
        ELSE.
          screen-active = '0'.
        ENDIF.
      WHEN 'CRE'.
        IF p_crea = abap_true.
          screen-active = 1.
          screen-required = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
      WHEN 'EXP'.
        IF p_expert = abap_true.
          screen-active = '1'.
        ELSE.
          screen-active = '0'.
        ENDIF.
    ENDCASE.
    IF screen-name = 'P_TOKEN'.
      screen-invisible = '1'.
    ENDIF.
    IF screen-name = 'P_PLANT' AND p_crea = abap_true.
      screen-input = '0'.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN ON p_qty.
  IF p_crea = abap_true AND p_qty > 9999.
    MESSAGE 'At most 9999 pieces' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_plant.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'WERKS'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_PLANT'
      value_org   = 'S'
    TABLES
      value_tab   = gt_plant
    EXCEPTIONS
      OTHERS      = 1.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'RESET'.
      CLEAR: p_matnr, p_name, p_qty, p_plant, p_token.
      MESSAGE 'Selection screen reset' TYPE 'S'.
    WHEN 'MODE'.
      IF p_crea = abap_true.
        p_plant = '1000'.
      ENDIF.
  ENDCASE.

START-OF-SELECTION.
  IF p_crea = abap_true.
    WRITE: / 'Material created:', p_name, p_qty.
  ELSE.
    WRITE: / 'Material displayed:', p_matnr.
  ENDIF.
  WRITE: / 'Plant:', p_plant, p_unit.
  WRITE: / 'Started by:', p_source.
