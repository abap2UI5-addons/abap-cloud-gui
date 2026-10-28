CLASS z2ui5_cl_cgui_r2c_19 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gt_flight  TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight  TYPE sflight.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_link_click REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_19 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `The flights in a grid` ).
    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_carrid
                       text = `Airline` ).

  ENDMETHOD.

  METHOD start_of_selection.

    SELECT * FROM sflight INTO TABLE @gt_flight
      WHERE carrid = @p_carrid
      ORDER BY PRIMARY KEY.

    set_pf_status( functions = VALUE #( ( name = `REFRESH` icon = `sap-icon://refresh` tooltip = `Read the flights again (F5)` ) )
                   shortcuts = VALUE #( ( key = `F5` ucomm = `REFRESH` ) ) ).
    alv( gt_flight
        )->set_title( 'Flights'
        )->set_column_text( name = `CONNID`
                            text = 'Flight'
        )->set_column_text( name = `SEATSOCC`
                            text = 'Occupied'
        )->set_column_hidden( `MANDT`
        )->set_column_hotspot( `CONNID`
        )->set_column_sum( `SEATSOCC`
        )->add_function( name    = `FULL`
                         text    = 'Full flights'
                         icon    = `sap-icon://accept`
                         tooltip = 'Count the full flights'
        )->add_function( name = `ALL`
                         text = 'All flights'
        )->set_line_selection( ).

  ENDMETHOD.

  METHOD at_line_selection.

    " the DOUBLE_CLICK handler of the grid - lcl_handler->on_double_click
    READ TABLE gt_flight INDEX row INTO gs_flight.
    message( text = |Flight { gs_flight-connid } on { gs_flight-fldate DATE = USER }|
             type = `I` ).

  ENDMETHOD.

  METHOD at_link_click.

    " the HOTSPOT_CLICK handler of the grid - lcl_handler->on_hotspot
    READ TABLE gt_flight INDEX row INTO gs_flight.
    IF column = 'CONNID'.
      message( |Connection { gs_flight-connid }| ).
    ENDIF.

  ENDMETHOD.

  METHOD at_user_command.

    " the PAI module of the screen - the OK code is ucomm
    CASE ucomm.
      WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
        leave_to_selection_screen( ).
      WHEN 'REFRESH'.
        SELECT * FROM sflight INTO TABLE @gt_flight
          WHERE carrid = @p_carrid
          ORDER BY PRIMARY KEY.
    ENDCASE.

    " the USER_COMMAND handler of the grid - lcl_handler->on_user_command
    DATA lv_full TYPE i.
    CASE ucomm.
      WHEN 'FULL'.
        LOOP AT gt_flight INTO gs_flight.
          IF gs_flight-seatsocc >= gs_flight-seatsmax.
            lv_full = lv_full + 1.
          ENDIF.
        ENDLOOP.
        message( |{ lv_full } full flights| ).
      WHEN 'ALL'.
        message( |{ lines( gt_flight ) } flights| ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
