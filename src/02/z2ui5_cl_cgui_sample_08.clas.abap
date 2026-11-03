"! Flight cockpit - the features of the roadmap in one report:
"!   selection screen  tabs, listbox with VRM values, MEMORY ID, LOWER CASE,
"!                     select-option with NO INTERVALS, SKIP and ULINE
"!   ALV               selection column, own toolbar function, hotspot,
"!                     icon column, currency, total, export
"!   lists             a secondary list with TOP-OF-PAGE DURING
"!                     LINE-SELECTION, Back returns to the grid
"!   popups            POPUP_TO_DECIDE, POPUP_GET_VALUES and a selection
"!                     screen as popup (CALL SELECTION-SCREEN)
"!   SUBMIT            the flight report sample 05, with the airline
"!   variants          on the server (table Z2UI5_T_19): shared,
"!                     protected, dynamic dates
"! Start it with ?app_start=z2ui5_cl_cgui_sample_08 - or with values and
"! without selection screen: &p_carrid=LH&skip_screen=X
CLASS z2ui5_cl_cgui_sample_08 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_flight,
        status   TYPE string,
        carrid   TYPE c LENGTH 3,
        connid   TYPE n LENGTH 4,
        fldate   TYPE d,
        price    TYPE p LENGTH 8 DECIMALS 2,
        currency TYPE c LENGTH 5,
        seatsocc TYPE i,
        seatsmax TYPE i,
      END OF ty_s_flight.
    TYPES ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH EMPTY KEY.
    " the fields of BAPIRET2 messages_from_bapiret( ) reads
    TYPES:
      BEGIN OF ty_s_return,
        type    TYPE c LENGTH 1,
        message TYPE c LENGTH 220,
      END OF ty_s_return.
    TYPES ty_t_return TYPE STANDARD TABLE OF ty_s_return WITH EMPTY KEY.

    DATA p_carrid TYPE c LENGTH 3.
    DATA s_fldate TYPE RANGE OF d.
    DATA s_connid TYPE RANGE OF ty_s_flight-connid.
    DATA p_class  TYPE c LENGTH 1.
    DATA p_note   TYPE c LENGTH 40.
    DATA p_full   TYPE abap_bool.
    DATA p_seats  TYPE i.
    DATA p_name   TYPE c LENGTH 30.
    " the ALV output - PUBLIC, so the grid binds it directly
    DATA mt_result TYPE ty_t_flight.

  PROTECTED SECTION.
    DATA mt_flight TYPE ty_t_flight.
    DATA mt_booked TYPE ty_t_flight.

    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS selection_screen_dynnr REDEFINITION.
    METHODS after_call_selection_screen REDEFINITION.
    METHODS at_selection_screen_on_end_of REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS top_of_page_line_selection REDEFINITION.
    METHODS at_link_click REDEFINITION.
    METHODS at_user_command REDEFINITION.

    METHODS mock_data.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_08 IMPLEMENTATION.

  METHOD initialization.

    set_title( `abap-cloud-gui - Flight Cockpit` ).
    vrm_set_values(
 name   = `P_CLASS`
                    values = VALUE #( ( key = `Y` text = `Economy` )
                                      ( key = `C` text = `Business` )
                                      ( key = `F` text = `First` ) ) ).
    p_class = `Y`.
    s_fldate = VALUE #( ( sign = `I` option = `BT` low = `20260101` high = `20260630` ) ).
    mock_data( ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->tabbed_block_begin(
        )->tab( `Flights`
        )->block_begin( `Selection`
        )->parameter( val        = p_carrid
                      text       = `Airline`
                      memory_id  = `CAR`
                      value_help = abap_true
        )->select_option( val  = s_fldate
                          text = `Flight date`
        )->select_option( val          = s_connid
                          text         = `Connection`
                          no_intervals = abap_true
        )->block_end(
        )->tab( `Options`
        )->parameter( val        = p_class
                      text       = `Class`
                      as_listbox = abap_true
        )->checkbox( val  = p_full
                     text = `Show full flights only`
        )->skip(
        )->uline(
        )->parameter( val            = p_note
                      text           = `Note on the list`
                      lower_case     = abap_true
                      visible_length = 20
        )->tabbed_block_end(
        )->button( text  = `Booking popup`
                   event = `BOOK_POPUP`
                   icon  = `sap-icon://cart` ).

  ENDMETHOD.

  METHOD selection_screen_dynnr.

    " SELECTION-SCREEN BEGIN OF SCREEN 100 AS WINDOW
    IF dynnr = `0100`.
      screen->block_begin( `Booking`
          )->parameter( val        = p_name
                        text       = `Passenger`
                        obligatory = abap_true
          )->parameter( val  = p_seats
                        text = `Seats`
          )->block_end( ).
    ENDIF.

  ENDMETHOD.

  METHOD after_call_selection_screen.

    IF dynnr = `0100`.
      IF subrc = 0.
        message( |Booking for { p_name } with { p_seats } seats noted| ).
      ELSE.
        message( text = `Booking cancelled`
                 type = `W` ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD at_selection_screen_on_end_of.

    " AT SELECTION-SCREEN ON END OF s_fldate - the multiple selection left
    " with OK; an error opens it again
    IF field = `S_FLDATE` AND lines( s_fldate ) > 10.
      message( text = `At most 10 date ranges`
               type = `E` ).
    ENDIF.

  ENDMETHOD.

  METHOD start_of_selection.

    CLEAR mt_result.
    LOOP AT mt_flight INTO DATA(ls_flight).
      IF z2ui5_cl_cgui_context=>range_check( val   = ls_flight-fldate
                                             range = s_fldate ) = abap_false
          OR z2ui5_cl_cgui_context=>range_check( val   = ls_flight-connid
                                                 range = s_connid ) = abap_false
          OR ( p_carrid IS NOT INITIAL AND ls_flight-carrid <> p_carrid )
          OR ( p_full = abap_true AND ls_flight-seatsocc < ls_flight-seatsmax ).
        CONTINUE.
      ENDIF.
      ls_flight-status = COND #( WHEN ls_flight-seatsocc >= ls_flight-seatsmax THEN `sap-icon://status-negative`
                                 WHEN ls_flight-seatsocc * 10 >= ls_flight-seatsmax * 8 THEN `sap-icon://status-critical`
                                 ELSE `sap-icon://status-positive` ).
      INSERT ls_flight INTO TABLE mt_result.
    ENDLOOP.

    IF mt_result IS INITIAL.
      RETURN.
    ENDIF.

    alv( mt_result
        )->set_title( COND #( WHEN p_note IS NOT INITIAL THEN |Flights - { p_note }| ELSE `Flights` )
        )->set_selection_mode(
        )->add_function( name = `BOOK`
                         text = `Book`
                         icon = `sap-icon://cart-3`
        )->add_function( name    = `REPORT`
                         text    = `Flight Report`
                         icon    = `sap-icon://action`
                         tooltip = `SUBMIT the flight report with the airline`
        )->set_column_text( name = `STATUS`   text = `Status`
        )->set_column_icon( `STATUS`
        )->set_column_text( name = `CARRID`   text = `Airline`
        )->set_column_hotspot( `CARRID`
        )->set_column_text( name = `CONNID`   text = `Connection`
        )->set_column_text( name = `FLDATE`   text = `Date`
        )->set_column_text( name = `PRICE`    text = `Price`
        )->set_column_currency( name           = `PRICE`
                                currency_field = `CURRENCY`
        )->set_column_text( name = `CURRENCY` text = `Currency`
        )->set_column_text( name = `SEATSOCC` text = `Occupied`
        )->set_column_sum( `SEATSOCC`
        )->set_column_text( name = `SEATSMAX` text = `Capacity` ).

    message( |{ lines( mt_result ) } flights selected| ).

  ENDMETHOD.

  METHOD top_of_page_line_selection.

    write( val   = |Flights of { p_carrid }|
           color = z2ui5_cl_cgui_list=>cs_color-key )->new_line( )->uline( ).

  ENDMETHOD.

  METHOD at_link_click.

    " a click on the airline - a secondary list of its flights
    READ TABLE mt_result INTO DATA(ls_clicked) INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    p_carrid = ls_clicked-carrid.

    LOOP AT mt_result INTO DATA(ls_flight) WHERE carrid = ls_clicked-carrid.
      write( val = ls_flight-connid pos = 1  len = 6
          )->write( val = ls_flight-fldate pos = 8  len = 12
          )->write( val = |{ ls_flight-seatsocc } / { ls_flight-seatsmax }| pos = 22 len = 12
          )->new_line( ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_user_command.

    DATA lt_values TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    CASE ucomm.

      WHEN `BOOK`.
        DATA(lt_rows) = get_selected_rows( ).
        IF lt_rows IS INITIAL.
          message( text = `Select the flights to book first`
                   type = `W` ).
          RETURN.
        ENDIF.
        CLEAR mt_booked.
        LOOP AT lt_rows INTO DATA(lv_row).
          INSERT mt_result[ lv_row ] INTO TABLE mt_booked.
        ENDLOOP.
        popup_to_decide( question = |Book { lines( mt_booked ) } flights?|
                         options  = VALUE #( ( `Book now` ) ( `Waiting list` ) )
                         ucomm    = `BOOK_DECIDED`
                         title    = `Booking` ).

      WHEN `BOOK_DECIDED`.
        CASE popup_answer( ).
          WHEN `1`.
            popup_get_values( fields = VALUE #( ( name = `NAME` text = `Passenger` required = abap_true )
                                                ( name = `DATE` text = `Date of birth` kind = z2ui5_cl_cgui_popup=>cs_kind-date )
                                                ( name = `MAIL` text = `Confirmation by mail` kind = z2ui5_cl_cgui_popup=>cs_kind-checkbox ) )
                              ucomm  = `BOOK_VALUES`
                              title  = `Passenger` ).
          WHEN `2`.
            message( |{ lines( mt_booked ) } flights on the waiting list| ).
          WHEN OTHERS.
            message( text = `Booking cancelled`
                     type = `W` ).
        ENDCASE.

      WHEN `BOOK_VALUES`.
        DATA(lt_fields) = popup_values( ).
        IF popup_answer( ) = z2ui5_cl_cgui_popup=>cs_answer-cancel OR lt_fields IS INITIAL.
          RETURN.
        ENDIF.
        " the result as a BAPI returns it - one line of BAPIRET2
        messages_from_bapiret( VALUE ty_t_return( ( type    = `I`
                                                    message = |{ lines( mt_booked ) } flights booked for | &&
                                                              |{ lt_fields[ name = `NAME` ]-value }| ) ) ).

      WHEN `BOOK_POPUP`.
        call_selection_screen( dynnr = `0100`
                               title = `Booking` ).

      WHEN `REPORT`.
        " SUBMIT z2ui5_cl_cgui_sample_05 WITH p_carrid = ... AND RETURN
        IF p_carrid IS NOT INITIAL.
          lt_values = VALUE #( ( name = `P_CARRID` kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = p_carrid ) ).
        ENDIF.
        submit( report = `Z2UI5_CL_CGUI_SAMPLE_05`
                values = lt_values ).

    ENDCASE.

  ENDMETHOD.

  METHOD mock_data.

    mt_flight = VALUE #(
        ( carrid = `LH` connid = `0400` fldate = `20260115` price = `666.00`  currency = `EUR` seatsocc = 120 seatsmax = 280 )
        ( carrid = `LH` connid = `0400` fldate = `20260215` price = `666.00`  currency = `EUR` seatsocc = 270 seatsmax = 280 )
        ( carrid = `LH` connid = `0402` fldate = `20260310` price = `720.50`  currency = `EUR` seatsocc = 280 seatsmax = 280 )
        ( carrid = `AA` connid = `0017` fldate = `20260120` price = `422.94`  currency = `USD` seatsocc = 300 seatsmax = 385 )
        ( carrid = `AA` connid = `0064` fldate = `20260412` price = `422.94`  currency = `USD` seatsocc = 385 seatsmax = 385 )
        ( carrid = `UA` connid = `0941` fldate = `20260505` price = `879.82`  currency = `USD` seatsocc = 150 seatsmax = 330 )
        ( carrid = `JL` connid = `0407` fldate = `20260221` price = `106136`  currency = `JPY` seatsocc = 90  seatsmax = 320 )
        ( carrid = `SQ` connid = `0002` fldate = `20260601` price = `1016.00` currency = `SGD` seatsocc = 320 seatsmax = 400 ) ).

  ENDMETHOD.

ENDCLASS.
