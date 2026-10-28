CLASS z2ui5_cl_cgui_r2c_15 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_rspar,
        selname TYPE c LENGTH 8,
        kind    TYPE c LENGTH 1,
        sign    TYPE c LENGTH 1,
        option  TYPE c LENGTH 2,
        low     TYPE c LENGTH 45,
        high    TYPE c LENGTH 45,
      END OF ty_rspar.

    " global data of the report
    DATA gv_seats TYPE i.
    DATA gt_rspar TYPE STANDARD TABLE OF ty_rspar WITH DEFAULT KEY.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.
    DATA s_fldate TYPE RANGE OF sy-datum.
    DATA p_max    TYPE i.
    DATA p_seats  TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS selection_screen_dynnr REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.
    METHODS after_call_selection_screen REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_15 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Reports call reports` ).
    p_carrid = 'LH'.
    p_max = 20.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_carrid
                       text = `Airline`
        )->select_option( val  = s_fldate
                          text = `Flight date`
        )->parameter( val  = p_max
                      text = `Maximum lines` ).

  ENDMETHOD.

  METHOD selection_screen_dynnr.

    CASE dynnr.
      WHEN `0100`.
        screen->parameter( val        = p_seats
                           text       = `Seats`
                           obligatory = abap_true ).
    ENDCASE.

  ENDMETHOD.

  METHOD start_of_selection.

    list( )->new_line(
        )->write( 'Flights of'
        )->write( p_carrid ).
    list( )->new_line(
        )->write( 'Double-click for the flight list, F2 for the booking' ).

  ENDMETHOD.

  METHOD at_line_selection.

    " the flight list of another report of the corpus, with our values
    DATA lt_r2c_submit_1 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lt_r2c_lines_1 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    CLEAR lt_r2c_submit_1.
    INSERT VALUE #( name = `P_CARRID` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = p_carrid ) INTO TABLE lt_r2c_submit_1.
    lt_r2c_lines_1 = z2ui5_cl_cgui_variant=>range_lines_get( name = `S_FLDATE` range = s_fldate ).
    APPEND LINES OF lt_r2c_lines_1 TO lt_r2c_submit_1.
    INSERT VALUE #( name = `P_MAX` kind = z2ui5_cl_cgui_variant=>cs_kind-select_option sign = 'E' option = `NE` low = p_max ) INTO TABLE lt_r2c_submit_1.
    submit( report = `Z2UI5_CL_CGUI_R2C_02`
            values = lt_r2c_submit_1 ).

  ENDMETHOD.

  METHOD at_user_command.

    CASE ucomm.
      WHEN 'BOOK'.
        call_selection_screen( dynnr = `0100`
                               title = `Booking` ).
      WHEN 'HELLO'.
        " the values as a selection table, the called report's own screen first
        gt_rspar = VALUE #( ( selname = 'P_NAME' kind = 'P' sign = 'I' option = 'EQ' low = 'World' ) ).
        DATA lt_r2c_submit_2 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
        DATA lt_r2c_lines_2 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
        CLEAR lt_r2c_submit_2.
        lt_r2c_lines_2 = z2ui5_cl_cgui_variant=>selection_table_get( gt_rspar ).
        APPEND LINES OF lt_r2c_lines_2 TO lt_r2c_submit_2.
        submit( report               = `Z2UI5_CL_CGUI_R2C_01`
                values               = lt_r2c_submit_2
                via_selection_screen = abap_true
                using_variant        = 'DEFAULT' ).
      WHEN 'LEAVE'.
        submit( report = `Z2UI5_CL_CGUI_R2C_01`
                values = VALUE #( ( name = `P_NAME` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = 'Bye' ) ) ).
        RETURN.
    ENDCASE.

  ENDMETHOD.

  METHOD after_call_selection_screen.

    CASE dynnr.
      WHEN `0100`.
        IF subrc = 0.
          gv_seats = p_seats.
          list( )->new_line(
              )->write( 'Seats booked:'
              )->write( gv_seats ).
        ELSE.
          list( )->new_line(
              )->write( 'Booking cancelled' ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
