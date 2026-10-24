"! Flight booking - a classic dynpro: the selection screen asks for the
"! airline, START-OF-SELECTION calls screen 0100, which shows the airline
"! as an output field, the connection and the seats as inputs, a checkbox
"! and a push button. PBO sets the status and keeps the seats closed until
"! the connection is checked (LOOP AT SCREEN on the group SEA); PAI answers
"! the push button CHECK, the function SAVE and Back. When the dynpro is
"! left, what followed CALL SCREEN runs and writes the list:
"!   START-OF-SELECTION.          start_of_selection( )
"!     CALL SCREEN 0100.            call_screen( `0100` )
"!     WRITE ...                  after_call_screen( dynnr )
"!   MODULE status_0100 OUTPUT.   dynpro_pbo( dynnr )
"!   MODULE user_command_0100.    dynpro_pai( dynnr ucomm )
"!     LEAVE TO SCREEN 0.           leave_to_screen( `0` )
"! Start it with ?app_start=z2ui5_cl_cgui_sample_11
CLASS z2ui5_cl_cgui_sample_11 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA p_carrid TYPE c LENGTH 3.
    " the fields of screen 0100
    DATA connid   TYPE n LENGTH 4.
    DATA seats    TYPE i.
    DATA window   TYPE abap_bool.
    DATA checked  TYPE abap_bool.
    DATA booked   TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS after_call_screen REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_11 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Flight Booking` ).
    p_carrid = `LH`.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_carrid
                       text       = `Airline`
                       obligatory = abap_true ).

  ENDMETHOD.

  METHOD start_of_selection.

    CLEAR: connid, seats, window, checked, booked.
    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    CASE dynnr.
      WHEN `0100`.
        screen->block_begin( `Booking`
            )->parameter( val       = p_carrid
                          text      = `Airline`
                          read_only = abap_true
            )->parameter( val        = connid
                          text       = `Connection`
                          obligatory = abap_true
            )->line_begin(
                )->parameter( val      = seats
                              text     = `Seats`
                              modif_id = `SEA`
                )->button( text  = `Check`
                           event = `CHECK`
                           icon  = `sap-icon://accept`
            )->line_end(
            )->checkbox( val      = window
                         text     = `Window seat`
                         modif_id = `SEA`
            )->block_end( ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.

    CASE dynnr.
      WHEN `0100`.
        set_title( |Flight Booking { p_carrid }| ).
        set_pf_status( VALUE #( ( name = `SAVE` text = `Book` icon = `sap-icon://save` ) ) ).
        LOOP AT current_screen( )->loop_at_screen( ) INTO DATA(ls_screen) WHERE group1 = `SEA`.
          ls_screen-input = checked.
          current_screen( )->modify_screen( ls_screen ).
        ENDLOOP.
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pai.

    CASE ucomm.
      WHEN `CHECK`.
        checked = abap_true.
        message( |Connection { p_carrid } { connid } has seats| ).
      WHEN `SAVE`.
        IF checked = abap_false OR seats <= 0.
          message( text = `Check the connection and enter the seats`
                   type = `E` ).
          RETURN.
        ENDIF.
        booked = abap_true.
        leave_to_screen( `0` ).
      WHEN `BACK`.
        leave_to_screen( `0` ).
    ENDCASE.
    IF screen_left( ) = abap_false.
      message( |Screen { dynnr }: { ucomm }| ).
    ENDIF.

  ENDMETHOD.

  METHOD after_call_screen.

    IF dynnr <> `0100`.
      RETURN.
    ENDIF.
    IF booked = abap_true.
      list( )->new_line(
          )->write( |Booked: { seats } seat(s) on { p_carrid } { connid }{ COND #( WHEN window = abap_true THEN ` (window)` ) }| ).
    ELSE.
      list( )->new_line(
          )->write( `Nothing booked` ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
