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
    TYPES ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.
    " the fields of BAPIRET2 messages_from_bapiret( ) reads
    TYPES:
      BEGIN OF ty_s_return,
        type    TYPE c LENGTH 1,
        message TYPE c LENGTH 220,
      END OF ty_s_return.
    TYPES ty_t_return TYPE STANDARD TABLE OF ty_s_return WITH DEFAULT KEY.

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
    "! The name of the report SUBMIT starts, read from a typed reference - a
    "! namespace rename rewrites the reference, never a literal.
    METHODS sample_05
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_08 IMPLEMENTATION.

  METHOD initialization.
    DATA temp5 TYPE z2ui5_cl_cgui_selscreen=>ty_t_value.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 LIKE s_fldate.
    DATA temp8 LIKE LINE OF temp7.

    set_title( `abap-cloud-gui - Flight Cockpit` ).

    CLEAR temp5.

    temp6-key = `Y`.
    temp6-text = `Economy`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `C`.
    temp6-text = `Business`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `F`.
    temp6-text = `First`.
    INSERT temp6 INTO TABLE temp5.
    vrm_set_values(
 name   = `P_CLASS`
                    values = temp5 ).
    p_class = `Y`.

    CLEAR temp7.

    temp8-sign = `I`.
    temp8-option = `BT`.
    temp8-low = `20260101`.
    temp8-high = `20260630`.
    INSERT temp8 INTO TABLE temp7.
    s_fldate = temp7.
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
    DATA ls_flight LIKE LINE OF mt_flight.
      DATA temp9 TYPE z2ui5_cl_cgui_sample_08=>ty_s_flight-status.
    DATA temp10 TYPE string.

    CLEAR mt_result.

    LOOP AT mt_flight INTO ls_flight.
      IF z2ui5_cl_cgui_context=>range_check( val   = ls_flight-fldate
                                             range = s_fldate ) = abap_false
          OR z2ui5_cl_cgui_context=>range_check( val   = ls_flight-connid
                                                 range = s_connid ) = abap_false
          OR ( p_carrid IS NOT INITIAL AND ls_flight-carrid <> p_carrid )
          OR ( p_full = abap_true AND ls_flight-seatsocc < ls_flight-seatsmax ).
        CONTINUE.
      ENDIF.

      IF ls_flight-seatsocc >= ls_flight-seatsmax.
        temp9 = `sap-icon://status-negative`.
      ELSEIF ls_flight-seatsocc * 10 >= ls_flight-seatsmax * 8.
        temp9 = `sap-icon://status-critical`.
      ELSE.
        temp9 = `sap-icon://status-positive`.
      ENDIF.
      ls_flight-status = temp9.
      INSERT ls_flight INTO TABLE mt_result.
    ENDLOOP.

    IF mt_result IS INITIAL.
      RETURN.
    ENDIF.


    IF p_note IS NOT INITIAL.
      temp10 = |Flights - { p_note }|.
    ELSE.
      temp10 = `Flights`.
    ENDIF.
    alv( mt_result
        )->set_title( temp10
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
    DATA ls_clicked TYPE z2ui5_cl_cgui_sample_08=>ty_s_flight.
    DATA ls_flight LIKE LINE OF mt_result.
    READ TABLE mt_result INTO ls_clicked INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    p_carrid = ls_clicked-carrid.


    LOOP AT mt_result INTO ls_flight WHERE carrid = ls_clicked-carrid.
      write( val = ls_flight-connid pos = 1  len = 6
          )->write( val = ls_flight-fldate pos = 8  len = 12
          )->write( val = |{ ls_flight-seatsocc } / { ls_flight-seatsmax }| pos = 22 len = 12
          )->new_line( ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_user_command.

    DATA lt_values TYPE z2ui5_cl_cgui_variant=>ty_t_value.
        DATA lt_rows TYPE z2ui5_cl_cgui_alv=>ty_t_row.
        DATA lv_row LIKE LINE OF lt_rows.
          FIELD-SYMBOLS <temp11> LIKE LINE OF mt_result.
          DATA temp12 LIKE sy-tabix.
        DATA temp13 TYPE string_table.
            DATA temp15 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
            DATA temp16 LIKE LINE OF temp15.
        DATA lt_fields TYPE z2ui5_cl_cgui_popup=>ty_t_field.
        DATA temp17 TYPE ty_t_return.
        DATA temp18 LIKE LINE OF temp17.
        FIELD-SYMBOLS <temp1> LIKE LINE OF lt_fields.
        DATA temp2 LIKE sy-tabix.
          DATA temp19 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
          DATA temp20 LIKE LINE OF temp19.

    CASE ucomm.

      WHEN `BOOK`.

        lt_rows = get_selected_rows( ).
        IF lt_rows IS INITIAL.
          message( text = `Select the flights to book first`
                   type = `W` ).
          RETURN.
        ENDIF.
        CLEAR mt_booked.

        LOOP AT lt_rows INTO lv_row.


          temp12 = sy-tabix.
          READ TABLE mt_result INDEX lv_row ASSIGNING <temp11>.
          sy-tabix = temp12.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          INSERT <temp11> INTO TABLE mt_booked.
        ENDLOOP.

        CLEAR temp13.
        INSERT `Book now` INTO TABLE temp13.
        INSERT `Waiting list` INTO TABLE temp13.
        popup_to_decide( question = |Book { lines( mt_booked ) } flights?|
                         options  = temp13
                         ucomm    = `BOOK_DECIDED`
                         title    = `Booking` ).

      WHEN `BOOK_DECIDED`.
        CASE popup_answer( ).
          WHEN `1`.

            CLEAR temp15.

            CLEAR temp16.
            temp16-name = `NAME`.
            temp16-text = `Passenger`.
            temp16-required = abap_true.
            INSERT temp16 INTO TABLE temp15.
            CLEAR temp16.
            temp16-name = `DATE`.
            temp16-text = `Date of birth`.
            temp16-kind = z2ui5_cl_cgui_popup=>cs_kind-date.
            INSERT temp16 INTO TABLE temp15.
            CLEAR temp16.
            temp16-name = `MAIL`.
            temp16-text = `Confirmation by mail`.
            temp16-kind = z2ui5_cl_cgui_popup=>cs_kind-checkbox.
            INSERT temp16 INTO TABLE temp15.
            popup_get_values( fields = temp15
                              ucomm  = `BOOK_VALUES`
                              title  = `Passenger` ).
          WHEN `2`.
            message( |{ lines( mt_booked ) } flights on the waiting list| ).
          WHEN OTHERS.
            message( text = `Booking cancelled`
                     type = `W` ).
        ENDCASE.

      WHEN `BOOK_VALUES`.

        lt_fields = popup_values( ).
        IF popup_answer( ) = z2ui5_cl_cgui_popup=>cs_answer-cancel OR lt_fields IS INITIAL.
          RETURN.
        ENDIF.
        " the result as a BAPI returns it - one line of BAPIRET2

        CLEAR temp17.

        temp18-type = `I`.


        temp2 = sy-tabix.
        READ TABLE lt_fields WITH KEY name = `NAME` ASSIGNING <temp1>.
        sy-tabix = temp2.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        temp18-message = |{ lines( mt_booked ) } flights booked for | &&
|{ <temp1>-value }|.
        INSERT temp18 INTO TABLE temp17.
        messages_from_bapiret( temp17 ).

      WHEN `BOOK_POPUP`.
        call_selection_screen( dynnr = `0100`
                               title = `Booking` ).

      WHEN `REPORT`.
        " SUBMIT z2ui5_cl_cgui_sample_05 WITH p_carrid = ... AND RETURN
        IF p_carrid IS NOT INITIAL.

          CLEAR temp19.

          temp20-name = `P_CARRID`.
          temp20-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
          temp20-low = p_carrid.
          INSERT temp20 INTO TABLE temp19.
          lt_values = temp19.
        ENDIF.
        submit( report = sample_05( )
                values = lt_values ).

    ENDCASE.

  ENDMETHOD.

  METHOD mock_data.

    DATA temp21 TYPE z2ui5_cl_cgui_sample_08=>ty_t_flight.
    DATA temp22 LIKE LINE OF temp21.
    CLEAR temp21.

    temp22-carrid = `LH`.
    temp22-connid = `0400`.
    temp22-fldate = `20260115`.
    temp22-price = `666.00`.
    temp22-currency = `EUR`.
    temp22-seatsocc = 120.
    temp22-seatsmax = 280.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `LH`.
    temp22-connid = `0400`.
    temp22-fldate = `20260215`.
    temp22-price = `666.00`.
    temp22-currency = `EUR`.
    temp22-seatsocc = 270.
    temp22-seatsmax = 280.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `LH`.
    temp22-connid = `0402`.
    temp22-fldate = `20260310`.
    temp22-price = `720.50`.
    temp22-currency = `EUR`.
    temp22-seatsocc = 280.
    temp22-seatsmax = 280.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `AA`.
    temp22-connid = `0017`.
    temp22-fldate = `20260120`.
    temp22-price = `422.94`.
    temp22-currency = `USD`.
    temp22-seatsocc = 300.
    temp22-seatsmax = 385.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `AA`.
    temp22-connid = `0064`.
    temp22-fldate = `20260412`.
    temp22-price = `422.94`.
    temp22-currency = `USD`.
    temp22-seatsocc = 385.
    temp22-seatsmax = 385.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `UA`.
    temp22-connid = `0941`.
    temp22-fldate = `20260505`.
    temp22-price = `879.82`.
    temp22-currency = `USD`.
    temp22-seatsocc = 150.
    temp22-seatsmax = 330.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `JL`.
    temp22-connid = `0407`.
    temp22-fldate = `20260221`.
    temp22-price = `106136`.
    temp22-currency = `JPY`.
    temp22-seatsocc = 90.
    temp22-seatsmax = 320.
    INSERT temp22 INTO TABLE temp21.
    temp22-carrid = `SQ`.
    temp22-connid = `0002`.
    temp22-fldate = `20260601`.
    temp22-price = `1016.00`.
    temp22-currency = `SGD`.
    temp22-seatsocc = 320.
    temp22-seatsmax = 400.
    INSERT temp22 INTO TABLE temp21.
    mt_flight = temp21.

  ENDMETHOD.

  METHOD sample_05.

    DATA lo_report TYPE REF TO z2ui5_cl_cgui_sample_05.
    DATA temp23 TYPE REF TO cl_abap_refdescr.
    temp23 ?= cl_abap_typedescr=>describe_by_data( lo_report ).
    result = temp23->get_referenced_type( )->get_relative_name( ).

  ENDMETHOD.

ENDCLASS.
