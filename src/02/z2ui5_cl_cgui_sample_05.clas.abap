CLASS z2ui5_cl_cgui_sample_05 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_flight,
        carrid   TYPE c LENGTH 3,
        connid   TYPE n LENGTH 4,
        fldate   TYPE d,
        price    TYPE p LENGTH 8 DECIMALS 2,
        currency TYPE c LENGTH 5,
        seatsocc TYPE i,
      END OF ty_s_flight.
    TYPES ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_carrier,
        carrid TYPE c LENGTH 3,
        name   TYPE string,
      END OF ty_s_carrier.
    TYPES ty_t_carrier TYPE STANDARD TABLE OF ty_s_carrier WITH EMPTY KEY.

    DATA p_carrid TYPE c LENGTH 3.
    DATA s_fldate TYPE RANGE OF d.
    DATA p_max    TYPE i.
    DATA p_alv    TYPE abap_bool.
    DATA p_list   TYPE abap_bool.
    " the ALV output - PUBLIC, so the grid binds it directly
    DATA mt_result TYPE ty_t_flight.

  PROTECTED SECTION.
    DATA mt_flight TYPE ty_t_flight.

    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.
    METHODS at_value_request REDEFINITION.

    METHODS output_alv.
    METHODS output_list.
    METHODS mock_data.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_05 IMPLEMENTATION.

  METHOD initialization.

    set_title( `abap-cloud-gui - Flight Report` ).
    p_max = 50.
    p_alv = abap_true.
    s_fldate = VALUE #( ( sign = `I` option = `BT` low = `20260101` high = `20260331` ) ).
    mock_data( ).
    " save a variant named DEFAULT and the report starts with it
    set_variant( `DEFAULT` ).
    " entries not executed come back at the next start
    set_draft( ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Flights`
        )->parameter( val        = p_carrid
                      text       = `Airline`
                      value_help = abap_true
        )->select_option( val  = s_fldate
                          text = `Flight date`
        )->parameter( val        = p_max
                      text       = `Maximum rows`
                      obligatory = abap_true
        )->block_end(
        )->block_begin( `Output`
        )->radiobutton( val   = p_alv
                        text  = `ALV grid`
                        group = `OUT`
        )->radiobutton( val   = p_list
                        text  = `Classic list`
                        group = `OUT`
        )->block_end(
        )->button( text  = `Reset`
                   event = `RESET_ASK`
                   icon  = `sap-icon://reset` ).

  ENDMETHOD.

  METHOD at_selection_screen.

    IF p_max > 1000.
      message( text = `At most 1000 rows can be displayed`
               type = `E` ).
    ENDIF.

  ENDMETHOD.

  METHOD start_of_selection.

    CLEAR mt_result.
    " on an SAP system: SELECT ... WHERE fldate IN @s_fldate - range_check( )
    " is the same test for an internal table, and runs everywhere
    LOOP AT mt_flight INTO DATA(ls_flight).
      IF z2ui5_cl_cgui_context=>range_check( val   = ls_flight-fldate
                                             range = s_fldate ) = abap_false.
        CONTINUE.
      ENDIF.
      IF p_carrid IS NOT INITIAL AND ls_flight-carrid <> p_carrid.
        CONTINUE.
      ENDIF.
      INSERT ls_flight INTO TABLE mt_result.
      IF lines( mt_result ) >= p_max.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF mt_result IS INITIAL.
      RETURN.
    ENDIF.

    IF p_alv = abap_true.
      output_alv( ).
    ELSE.
      output_list( ).
    ENDIF.
    message( |{ lines( mt_result ) } flights selected| ).

  ENDMETHOD.

  METHOD output_alv.

    alv( mt_result
        )->set_title( `Flights`
        )->set_column_text( name = `CARRID`
                            text = `Airline`
        )->set_column_text( name = `CONNID`
                            text = `Connection`
        )->set_column_text( name = `FLDATE`
                            text = `Date`
        )->set_column_text( name = `PRICE`
                            text = `Price`
        )->set_column_text( name = `CURRENCY`
                            text = `Currency`
        )->set_column_text( name = `SEATSOCC`
                            text = `Occupied`
        )->set_line_selection( ).

  ENDMETHOD.

  METHOD output_list.

    " REPORT ... LINE-COUNT 30 - a new page after 30 lines
    set_line_count( 30 ).
    write( val   = `Airline Connection Date Price`

           color = z2ui5_cl_cgui_list=>cs_color-key )->uline( ).

    LOOP AT mt_result INTO DATA(ls_flight).
      DATA(lv_color) = COND string( WHEN ls_flight-seatsocc > 200 THEN z2ui5_cl_cgui_list=>cs_color-negative
                                    ELSE z2ui5_cl_cgui_list=>cs_color-positive ).
      write( val     = ls_flight-carrid
             hotspot = abap_true
             hide    = sy-tabix
          )->write( ls_flight-connid
          )->write( ls_flight-fldate
          )->write( ls_flight-price
          )->write( ls_flight-currency
          )->write( val   = |{ ls_flight-seatsocc } seats|
                    color = lv_color
          )->new_line( ).
    ENDLOOP.

  ENDMETHOD.

  METHOD at_line_selection.

    DATA lv_index TYPE i.

    lv_index = row.
    IF hide IS NOT INITIAL.
      lv_index = hide.
    ENDIF.

    READ TABLE mt_result INTO DATA(ls_flight) INDEX lv_index.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    message( text = |Flight { ls_flight-carrid } { ls_flight-connid } on { ls_flight-fldate DATE = USER }: | &&
                    |{ ls_flight-seatsocc } seats occupied, price { ls_flight-price } { ls_flight-currency }|
             type = `I` ).

  ENDMETHOD.

  METHOD at_user_command.

    CASE ucomm.
      WHEN `RESET_ASK`.
        popup_to_confirm( question = `Reset all fields of the selection screen?`
                          ucomm    = `RESET` ).
      WHEN `RESET`.
        CLEAR: p_carrid, s_fldate.
        p_max = 50.
        p_alv = abap_true.
        p_list = abap_false.
        message( `Selection screen reset` ).
    ENDCASE.

  ENDMETHOD.

  METHOD at_value_request.

    CASE field.
      WHEN `P_CARRID`.
        value_help_popup( tab   = VALUE ty_t_carrier( ( carrid = `AA` name = `American Airlines` )
                                                      ( carrid = `LH` name = `Lufthansa` )
                                                      ( carrid = `SQ` name = `Singapore Airlines` )
                                                      ( carrid = `UA` name = `United Airlines` ) )
                          col   = `CARRID`
                          title = `Airlines` ).
    ENDCASE.

  ENDMETHOD.

  METHOD mock_data.

    DATA lv_date TYPE d VALUE `20260101`.
    DATA lt_carrid TYPE string_table.

    lt_carrid = VALUE #( ( `AA` ) ( `LH` ) ( `SQ` ) ( `UA` ) ).

    DO 60 TIMES.
      DATA(lv_carrid) = lt_carrid[ ( sy-index MOD 4 ) + 1 ].
      INSERT VALUE #( carrid   = lv_carrid
                      connid   = 400 + sy-index MOD 7
                      fldate   = lv_date + sy-index * 3
                      price    = 250 + ( sy-index MOD 9 ) * 45
                      currency = `EUR`
                      seatsocc = 90 + ( sy-index * 37 ) MOD 250 ) INTO TABLE mt_flight.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
