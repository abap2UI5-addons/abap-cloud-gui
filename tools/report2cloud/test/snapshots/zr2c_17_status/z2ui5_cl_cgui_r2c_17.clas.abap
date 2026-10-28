CLASS z2ui5_cl_cgui_r2c_17 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight TYPE sflight,
      gt_excl   TYPE STANDARD TABLE OF sy-ucomm WITH DEFAULT KEY.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.
    DATA p_edit   TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
    METHODS show.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_17 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `The GUI status of a list` ).
    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_carrid
                       text = `Airline`
        )->checkbox( val  = p_edit
                     text = `Allow changes` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " without the right to change, the list has no Delete
    IF p_edit IS INITIAL.
      APPEND 'DELE' TO gt_excl.
    ENDIF.
    set_pf_status( functions = VALUE #( ( name = `REFRESH` icon = `sap-icon://refresh` tooltip = `Read the flights again (F5)` )
                                        ( name = `DELE` text = `Delete` icon = `sap-icon://delete` tooltip = `Delete empty flights (Shift+F2)` ) )
                   shortcuts = VALUE #( ( key = `F5` ucomm = `REFRESH` )
                                        ( key = `Shift+F2` ucomm = `DELE` ) )
                   excluding = gt_excl ).
    set_title( |Flights of airline { p_carrid }| ).
    show( ).

  ENDMETHOD.

  METHOD at_user_command.

    CASE ucomm.
      WHEN 'REFRESH'.
        show( ).
      WHEN 'DELE'.
        DELETE gt_flight WHERE seatsocc = 0.
        set_pf_status( functions = VALUE #( ( name = `REFRESH` icon = `sap-icon://refresh` tooltip = `Read the flights again (F5)` )
                                            ( name = `DELE` text = `Delete` icon = `sap-icon://delete` tooltip = `Delete empty flights (Shift+F2)` ) )
                       shortcuts = VALUE #( ( key = `F5` ucomm = `REFRESH` )
                                            ( key = `Shift+F2` ucomm = `DELE` ) )
                       excluding = VALUE string_table( ( `DELE` ) ) ).
        list( )->new_line(
            )->write( 'Flights without bookings deleted' ).
    ENDCASE.

  ENDMETHOD.

  METHOD show.

    SELECT * FROM sflight INTO TABLE @gt_flight
      WHERE carrid = @p_carrid
      ORDER BY PRIMARY KEY.
    LOOP AT gt_flight INTO gs_flight.
      list( )->new_line(
          )->write( gs_flight-connid
          )->write( gs_flight-fldate
          )->write( gs_flight-seatsocc ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
