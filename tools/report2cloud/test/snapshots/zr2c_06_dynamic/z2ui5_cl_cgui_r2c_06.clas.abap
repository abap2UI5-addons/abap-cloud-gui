CLASS z2ui5_cl_cgui_r2c_06 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_plant,
        werks TYPE c LENGTH 4,
        name  TYPE c LENGTH 30,
      END OF ty_plant.

    " global data of the report
    DATA gt_plant TYPE STANDARD TABLE OF ty_plant WITH DEFAULT KEY.

    " selection screen
    DATA p_disp   TYPE abap_bool.
    DATA p_crea   TYPE abap_bool.
    DATA p_matnr  TYPE c LENGTH 18.
    DATA p_name   TYPE c LENGTH 40.
    DATA p_qty    TYPE i.
    DATA p_unit   TYPE c LENGTH 3.
    DATA p_source TYPE string.
    DATA p_expert TYPE abap_bool.
    DATA p_plant  TYPE c LENGTH 4.
    DATA p_token  TYPE c LENGTH 32.
    DATA b_reset  TYPE c LENGTH 83.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen_output REDEFINITION.
    METHODS at_selection_screen_on REDEFINITION.
    METHODS at_selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.
    METHODS at_value_request REDEFINITION.

  PRIVATE SECTION.
    METHODS at_selection_screen_ucomm
      IMPORTING
        ucomm TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_06 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Dynamic Selection Screen` ).
    p_disp = abap_true.
    p_unit = 'PC'.

    b_reset = 'Reset'.
    p_source = 'ZR2C_06_DYNAMIC'.
    gt_plant = VALUE #( ( werks = '1000' name = 'Hamburg' )
                        ( werks = '2000' name = 'Walldorf' )
                        ( werks = '3000' name = 'Berlin' ) ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Mode`
        )->radiobutton( val          = p_disp
                        text         = `Display material`
                        group        = `MODE`
                        user_command = `MODE`
        )->radiobutton( val   = p_crea
                        text  = `Create material`
                        group = `MODE`
        )->block_end(
        )->block_begin( `Material`
        )->parameter( val      = p_matnr
                      text     = `Material`
                      modif_id = `DIS`
        )->parameter( val        = p_name
                      text       = `Description`
                      modif_id   = `CRE`
                      lower_case = abap_true
        )->parameter( val      = p_qty
                      text     = `Quantity`
                      modif_id = `CRE`
        )->line_begin( `Unit of measure`
        )->parameter( p_unit
        )->line_end(
        )->comment( text     = `New materials are always created in plant 1000.`
                    modif_id = `CRE`
        )->parameter( val        = p_source
                      no_display = abap_true
        )->block_end(
        )->block_begin( `Expert settings`
        )->checkbox( val          = p_expert
                     text         = `Expert settings`
                     user_command = `EXPERT`
        )->parameter( val        = p_plant
                      text       = `Plant`
                      value_help = abap_true
                      modif_id   = `EXP`
        )->parameter( val        = p_token
                      text       = `Access token`
                      modif_id   = `EXP`
                      lower_case = abap_true
        )->button( text  = b_reset
                   event = `RESET`
        )->block_end( ).

  ENDMETHOD.

  METHOD at_selection_screen_output.

    DATA(lt_screen) = screen->loop_at_screen( ).
    LOOP AT lt_screen INTO DATA(ls_screen).
      CASE ls_screen-group1.
        WHEN 'DIS'.
          IF p_disp = abap_true.
            ls_screen-active = abap_true.
          ELSE.
            ls_screen-active = abap_false.
          ENDIF.
        WHEN 'CRE'.
          IF p_crea = abap_true.
            ls_screen-active = abap_true.
            ls_screen-required = abap_true.
          ELSE.
            ls_screen-active = abap_false.
          ENDIF.
        WHEN 'EXP'.
          IF p_expert = abap_true.
            ls_screen-active = abap_true.
          ELSE.
            ls_screen-active = abap_false.
          ENDIF.
      ENDCASE.
      IF ls_screen-name = 'P_TOKEN'.
        ls_screen-invisible = abap_true.
      ENDIF.
      IF ls_screen-name = 'P_PLANT' AND p_crea = abap_true.
        ls_screen-input = abap_false.
      ENDIF.
      screen->modify_screen( ls_screen ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_selection_screen_on.

    CASE field.
      WHEN `P_QTY`.
        IF p_crea = abap_true AND p_qty > 9999.
          message( text = 'At most 9999 pieces'
                   type = `E` ).
          RETURN.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen.

    " F8 - the classic sy-ucomm of Execute
    at_selection_screen_ucomm( `ONLI` ).

  ENDMETHOD.

  METHOD start_of_selection.

    IF p_crea = abap_true.
      list( )->new_line(
          )->write( 'Material created:'
          )->write( p_name
          )->write( p_qty ).
    ELSE.
      list( )->new_line(
          )->write( 'Material displayed:'
          )->write( p_matnr ).
    ENDIF.
    list( )->new_line(
        )->write( 'Plant:'
        )->write( p_plant
        )->write( p_unit ).
    list( )->new_line(
        )->write( 'Started by:'
        )->write( p_source ).

  ENDMETHOD.

  METHOD at_user_command.

    " a button or USER-COMMAND of the selection screen - the classic AT SELECTION-SCREEN
    at_selection_screen_ucomm( ucomm ).

  ENDMETHOD.

  METHOD at_value_request.

    CASE field.
      WHEN `P_PLANT`.
        value_help_popup( tab = gt_plant
                          col = `WERKS` ).
      WHEN OTHERS.
        super->at_value_request( field ).
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen_ucomm.

    CASE ucomm.
      WHEN 'RESET'.
        CLEAR: p_matnr, p_name, p_qty, p_plant, p_token.
        message( 'Selection screen reset' ).
      WHEN 'MODE'.
        IF p_crea = abap_true.
          p_plant = '1000'.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
