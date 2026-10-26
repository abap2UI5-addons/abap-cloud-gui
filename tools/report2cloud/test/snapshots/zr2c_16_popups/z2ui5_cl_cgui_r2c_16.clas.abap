CLASS z2ui5_cl_cgui_r2c_16 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_sval,
        tabname    TYPE c LENGTH 30,
        fieldname  TYPE c LENGTH 30,
        value      TYPE c LENGTH 132,
        fieldtext  TYPE c LENGTH 60,
        field_obl  TYPE c LENGTH 1,
      END OF ty_sval.

    " global data of the report
    DATA:
      gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight TYPE sflight,
      gv_answer TYPE c LENGTH 1,
      gv_booked TYPE i.
    DATA lv_answer TYPE c LENGTH 1.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
    METHODS book
      IMPORTING
        is_flight TYPE sflight.

    METHODS passenger.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_16 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `The synchronous popups` ).
    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_carrid
                       text = `Airline` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_flight,
           gs_flight,
           gv_answer,
           gv_booked,
           lv_answer.

    SELECT * FROM sflight INTO TABLE @gt_flight
      WHERE carrid = @p_carrid
      ORDER BY PRIMARY KEY.
    LOOP AT gt_flight INTO gs_flight.
      list( )->new_line(
          )->write( val     = gs_flight-carrid
                    hotspot = abap_true
                    hide    = gs_flight
          )->write( gs_flight-connid
          )->write( gs_flight-fldate
          )->write( gs_flight-seatsocc ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the field the clicked line was written with
    z2ui5_cl_cgui_list=>hide_restore( EXPORTING hide = hide
                                      CHANGING  val  = gs_flight ).

    popup_to_decide( question = 'Book the flight' && ` ` && gs_flight-connid
                     options  = VALUE #( ( `Book now` ) ( `Waiting list` ) )
                     ucomm    = `POPUP_1`
                     title    = 'Booking' ).

  ENDMETHOD.

  METHOD at_user_command.

    CASE ucomm.
      WHEN 'CANCEL'.
        popup_to_decide( question = 'Cancel all bookings of this run?'
                         options  = VALUE #( ( `Cancel them` ) ( `Keep them` ) )
                         ucomm    = `POPUP_2`
                         title    = 'Cancel bookings' ).
      WHEN 'PASSENGER'.
        passenger( ).
    ENDCASE.

    " the answers of the popups - the statements after the CALL FUNCTION
    CASE ucomm.
      WHEN `POPUP_1`.
        lv_answer = popup_answer( ).
        CASE lv_answer.
          WHEN '1'.
            book( gs_flight ).
          WHEN '2'.
            list( )->new_line(
                )->write( 'On the waiting list:'
                )->write( gs_flight-connid ).
          WHEN OTHERS.
            list( )->new_line(
                )->write( 'Nothing booked' ).
        ENDCASE.
      WHEN `POPUP_2`.
        gv_answer = popup_answer( ).
        IF gv_answer = '1'.
          gv_booked = 0.
          list( )->new_line(
              )->write( 'All bookings cancelled' ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD book.

    gv_booked = gv_booked + 1.
    list( )->new_line(
        )->write( 'Booked:'
        )->write( is_flight-connid
        )->write( 'Bookings of this run:'
        )->write( gv_booked ).

  ENDMETHOD.

  METHOD passenger.

    DATA lt_fields TYPE STANDARD TABLE OF ty_sval WITH DEFAULT KEY.
    DATA lv_rc TYPE c LENGTH 1.
    APPEND VALUE #( tabname = 'SCUSTOM' fieldname = 'NAME' fieldtext = 'Passenger' field_obl = 'X' ) TO lt_fields.
    APPEND VALUE #( tabname = 'SCUSTOM' fieldname = 'CITY' fieldtext = 'City' ) TO lt_fields.
    " in a FORM the block is not cut: a TODO says where to go on
    popup_get_values_sval( sval  = lt_fields
                           ucomm = `POPUP_3`
                           title = 'Passenger' ).
    IF lv_rc = 'A'.
      RETURN.
    ENDIF.
    list( )->new_line(
        )->write( 'Passenger:'
        )->write( lt_fields[ 1 ]-value ).

  ENDMETHOD.

ENDCLASS.
