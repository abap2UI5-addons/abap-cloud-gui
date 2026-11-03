CLASS z2ui5_cl_cgui_sample_06 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA p_disp   TYPE abap_bool.
    DATA p_create TYPE abap_bool.
    DATA p_matnr  TYPE c LENGTH 18.
    DATA p_name   TYPE string.
    DATA p_qty    TYPE i.
    DATA p_expert TYPE abap_bool.
    DATA p_plant  TYPE c LENGTH 4.
    DATA p_token  TYPE string.
    " NO-DISPLAY - set by the report, never shown
    DATA p_source TYPE string.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen_output REDEFINITION.
    METHODS at_selection_screen_on REDEFINITION.
    METHODS at_selection_screen_on_radio REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_06 IMPLEMENTATION.

  METHOD initialization.

    set_title( `abap-cloud-gui - Dynamic Selection Screen` ).
    p_disp = abap_true.
    p_plant = `1000`.
    p_source = `SAMPLE_06`.

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Mode`
        )->radiobutton( val          = p_disp
                        text         = `Display material`
                        group        = `MODE`
                        user_command = `MODE`
        )->radiobutton( val   = p_create
                        text  = `Create material`
                        group = `MODE`
        )->block_end(
        )->block_begin( `Material`
        )->parameter( val      = p_matnr
                      text     = `Material`
                      modif_id = `DIS`
        )->parameter( val      = p_name
                      text     = `Description`
                      modif_id = `CRE`
        )->parameter( val      = p_qty
                      text     = `Quantity`
                      modif_id = `CRE`
        )->block_end(
        )->block_begin( `Settings`
        )->checkbox( val          = p_expert
                     text         = `Expert settings`
                     user_command = `EXPERT`
        )->parameter( val      = p_plant
                      text     = `Plant`
                      modif_id = `EXP`
        )->parameter( val      = p_token
                      text     = `Access token`
                      modif_id = `EXP`
        )->comment( text     = `New materials are always created in plant 1000.`
                    modif_id = `EXP`
        )->parameter( val        = p_source
                      no_display = abap_true
        )->block_end( ).

  ENDMETHOD.

  METHOD at_selection_screen_output.

    DATA(lt_screen) = screen->loop_at_screen( ).

    LOOP AT lt_screen INTO DATA(ls_screen).
      CASE ls_screen-group1.
        WHEN `DIS`.
          ls_screen-active = p_disp.
          ls_screen-required = p_disp.
        WHEN `CRE`.
          ls_screen-active = p_create.
          ls_screen-required = p_create.
        WHEN `EXP`.
          ls_screen-active = p_expert.
      ENDCASE.

      CASE ls_screen-name.
        WHEN `P_PLANT`.
          ls_screen-input = xsdbool( p_create = abap_false ).
        WHEN `P_TOKEN`.
          ls_screen-invisible = abap_true.
      ENDCASE.

      screen->modify_screen( ls_screen ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_user_command.

    IF ucomm = `MODE` AND p_create = abap_true.
      p_plant = `1000`.
    ENDIF.

  ENDMETHOD.

  METHOD at_selection_screen_on.

    CASE field.
      WHEN `P_MATNR`.
        " a string has no trailing blanks, which CN would count
        DATA(lv_matnr) = CONV string( p_matnr ).
        IF lv_matnr CN `0123456789`.
          message( text = `Enter the material number with digits only`
                   type = `E` ).
        ENDIF.
      WHEN `P_QTY`.
        IF p_qty > 9999.
          message( text = `At most 9999 pieces can be created at once`
                   type = `E` ).
        ENDIF.
      WHEN `P_PLANT`.
        IF p_plant <> `1000` AND p_plant <> `2000`.
          message( text = `Plant 1000 or 2000`
                   type = `W` ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen_on_radio.

    " AT SELECTION-SCREEN ON RADIOBUTTON GROUP - an error stops at the
    " first button of the group
    IF group = `MODE` AND p_create = abap_true AND p_plant <> `1000`.
      message( text = `New materials are created in plant 1000`
               type = `E` ).
    ENDIF.

  ENDMETHOD.

  METHOD start_of_selection.

    IF p_create = abap_true.
      write( val   = `Material created`
             color = z2ui5_cl_cgui_list=>cs_color-positive )->uline( ).
      write( |Description: { p_name }| )->new_line( ).
      write( |Quantity: { p_qty }| )->new_line( ).
    ELSE.
      write( val   = `Material displayed`
             color = z2ui5_cl_cgui_list=>cs_color-key )->uline( ).
      write( |Material: { p_matnr }| )->new_line( ).
    ENDIF.

    write( |Plant: { p_plant }| )->new_line( ).
    IF p_expert = abap_true AND p_token IS NOT INITIAL.
      write( `Access token: set` )->new_line( ).
    ENDIF.
    write( |Started by: { p_source }| ).

  ENDMETHOD.

ENDCLASS.
