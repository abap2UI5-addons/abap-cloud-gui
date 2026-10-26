CLASS z2ui5_cl_cgui_r2c_23 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA ok_code     TYPE sy-ucomm.
    DATA gv_connid TYPE n LENGTH 4.
    DATA gv_seats   TYPE i.
    DATA gv_window TYPE abap_bool.
    DATA gv_eco    TYPE abap_bool VALUE abap_true.
    DATA gv_bus    TYPE abap_bool.
    DATA gv_check   TYPE c LENGTH 1.
    DATA gv_booked TYPE c LENGTH 1.

    " selection screen
    DATA p_carrid TYPE c LENGTH 3.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS after_call_screen REDEFINITION.

  PRIVATE SECTION.
    METHODS status_0100
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS exit_0100.

    METHODS check_connid.

    METHODS user_command_0100.

    METHODS user_command_0200.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_23 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A dynpro of fields` ).
    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_carrid
                       text       = `Airline`
                       obligatory = abap_true ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: ok_code,
           gv_connid,
           gv_seats,
           gv_window,
           gv_bus,
           gv_check,
           gv_booked.
    gv_eco = abap_true.

    CLEAR: gv_connid, gv_seats, gv_check, gv_booked.
    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    CASE dynnr.
      WHEN `0100`.
        screen->block_begin( `Booking`
            )->parameter( val       = p_carrid
                          text      = `Airline`
                          read_only = abap_true
            )->parameter( val        = gv_connid
                          text       = `Connection`
                          obligatory = abap_true
            )->line_begin(
            )->parameter( val      = gv_seats
                          text     = `Seats`
                          modif_id = `SEA`
            )->button( text  = `Check`
                       event = `CHECK`
            )->line_end(
            )->checkbox( val      = gv_window
                         text     = `Window seat`
                         modif_id = `SEA`
            )->radiobutton( val   = gv_eco
                            text  = `Economy`
                            group = `RB_GV_ECO`
            )->radiobutton( val   = gv_bus
                            text  = `Business`
                            group = `RB_GV_ECO`
            )->block_end( ).
      WHEN `0200`.
        screen->comment( `Book the seats now?`
            )->button( text  = `Book`
                       event = `BOOK` ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.

    CASE dynnr.
      WHEN `0100`.
        status_0100( current_screen( ) ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pai.

    CASE dynnr.
      WHEN `0100`.
        ok_code = ucomm.
        " AT EXIT-COMMAND - the functions that leave
        IF ucomm = `BACK` OR ucomm = `EXIT` OR ucomm = `CANC` OR ucomm = `CANCEL`.
          exit_0100( ).
          IF screen_left( ) = abap_true.
            RETURN.
          ENDIF.
        ENDIF.
        IF gv_connid IS NOT INITIAL.
          check_connid( ).
        ENDIF.
        IF screen_left( ) = abap_true.
          RETURN.
        ENDIF.
        user_command_0100( ).
      WHEN `0200`.
        ok_code = ucomm.
        user_command_0200( ).
    ENDCASE.

  ENDMETHOD.

  METHOD after_call_screen.

    CASE dynnr.
      WHEN `0100`.
        IF gv_booked = 'X'.
          list( )->new_line(
              )->write( 'Booked:'
              )->write( gv_seats
              )->write( 'seat(s) on'
              )->write( p_carrid
              )->write( gv_connid ).
        ELSE.
          list( )->new_line(
              )->write( 'Nothing booked' ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD status_0100.

    set_pf_status( functions = VALUE #( ( name = `SAVE` text = `Save` icon = `sap-icon://save` tooltip = `Save (F11)` ) )
                   shortcuts = VALUE #( ( key = `F11` ucomm = `SAVE` ) ) ).
    set_title( |Booking on airline { p_carrid }| ).
    DATA(lt_screen) = screen->loop_at_screen( ).
    LOOP AT lt_screen INTO DATA(ls_screen).
      IF ls_screen-group1 = 'SEA'.
        IF gv_check = 'X'.
          ls_screen-input = abap_true.
        ELSE.
          ls_screen-input = abap_false.
        ENDIF.
        screen->modify_screen( ls_screen ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD exit_0100.

    leave_to_screen( `0000` ).
    RETURN.

  ENDMETHOD.

  METHOD check_connid.

    IF gv_connid > '9000'.
      message( text = 'No such connection'
               type = `E` ).
      RETURN.
    ENDIF.

  ENDMETHOD.

  METHOD user_command_0100.

    CASE ok_code.
      WHEN 'CHECK'.
        gv_check = 'X'.
        message( 'The connection has seats' ).
      WHEN 'SAVE'.
        IF gv_check IS INITIAL OR gv_seats <= 0.
          message( text = 'Check the connection and enter the seats'
                   type = `E` ).
          RETURN.
        ENDIF.
        set_screen( `0200` ).
    ENDCASE.
    CLEAR ok_code.

  ENDMETHOD.

  METHOD user_command_0200.

    CASE ok_code.
      WHEN 'BOOK'.
        gv_booked = 'X'.
        leave_to_screen( `0000` ).
        RETURN.
      WHEN 'BACK'.
        leave_to_screen( `0100` ).
        RETURN.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
