CLASS z2ui5_cl_cgui_r2c_02 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_flight,
        carrid   TYPE sflight-carrid,
        connid   TYPE sflight-connid,
        fldate   TYPE sflight-fldate,
        price    TYPE sflight-price,
        currency TYPE sflight-currency,
        seatsmax TYPE sflight-seatsmax,
        seatsocc TYPE sflight-seatsocc,
      END OF ty_flight.

    " global data of the report
    DATA:
      gt_flight TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY,
      gs_flight TYPE ty_flight,
      gv_total  TYPE i.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.
    DATA s_fldate TYPE RANGE OF sflight-fldate.
    DATA p_max    TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS end_of_selection REDEFINITION.
    METHODS top_of_page REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_02 IMPLEMENTATION.

  METHOD initialization.

    DATA ls_s_fldate LIKE LINE OF s_fldate.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Flights of an Airline` ).
    p_carrid = 'LH'.
    p_max = 100.

    ls_s_fldate-sign   = 'I'.
    ls_s_fldate-option = 'BT'.
    ls_s_fldate-low    = sy-datum.
    ls_s_fldate-high   = sy-datum + 90.
    APPEND ls_s_fldate TO s_fldate.

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Flights`
        )->parameter( val        = p_carrid
                      obligatory = abap_true
        )->select_option( val  = s_fldate
                          text = `Flight date`
        )->parameter( val  = p_max
                      text = `Maximum rows`
        )->block_end( ).

  ENDMETHOD.

  METHOD at_selection_screen.

    IF p_max > 1000.
      MESSAGE e001(zr2c) WITH p_max INTO DATA(lv_message).
      message( text = lv_message
               type = `E` ).
      RETURN.
    ENDIF.

  ENDMETHOD.

  METHOD start_of_selection.

    SELECT carrid, connid, fldate, price, currency, seatsmax, seatsocc
      FROM sflight
      INTO TABLE @gt_flight
      UP TO @p_max ROWS
      WHERE carrid = @p_carrid
        AND fldate IN @s_fldate.
    IF sy-subrc <> 0.
      MESSAGE s002(zr2c) WITH p_carrid INTO DATA(lv_message).
      message( lv_message ).
      RETURN.
    ENDIF.

    LOOP AT gt_flight INTO gs_flight.
      list( )->new_line(
          )->write( val     = gs_flight-carrid
                    hotspot = abap_true
                    hide    = |{ gs_flight-carrid }\t{ gs_flight-connid }\t{ gs_flight-fldate }|
          )->write( gs_flight-connid
          )->write( gs_flight-fldate
          )->write( gs_flight-price
          )->write( gs_flight-currency ).
      IF gs_flight-seatsocc >= gs_flight-seatsmax.
        write( val   = gs_flight-seatsocc
               color = z2ui5_cl_cgui_list=>cs_color-negative ).
      ELSE.
        write( val   = gs_flight-seatsocc
               color = z2ui5_cl_cgui_list=>cs_color-positive ).
      ENDIF.
      gv_total = gv_total + gs_flight-seatsocc.
    ENDLOOP.

  ENDMETHOD.

  METHOD end_of_selection.

    list( )->skip( ).
    list( )->new_line(
        )->write( `Seats occupied in total:`
        )->write( val   = gv_total
                  color = z2ui5_cl_cgui_list=>cs_color-total ).

  ENDMETHOD.

  METHOD top_of_page.

    list( )->new_line(
        )->write( val   = 'Airline'
                  color = z2ui5_cl_cgui_list=>cs_color-key
        )->write( val   = 'No.'
                  color = z2ui5_cl_cgui_list=>cs_color-key
        )->write( val   = 'Date'
                  color = z2ui5_cl_cgui_list=>cs_color-key
        )->write( val   = 'Price'
                  color = z2ui5_cl_cgui_list=>cs_color-key
        )->write( val   = 'Occupied'
                  color = z2ui5_cl_cgui_list=>cs_color-key ).
    list( )->uline( ).

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the fields the clicked line was written with
    SPLIT hide AT |\t| INTO TABLE DATA(lt_hide).
    gs_flight-carrid = VALUE #( lt_hide[ 1 ] OPTIONAL ).
    gs_flight-connid = VALUE #( lt_hide[ 2 ] OPTIONAL ).
    gs_flight-fldate = VALUE #( lt_hide[ 3 ] OPTIONAL ).

    READ TABLE gt_flight INTO gs_flight
      WITH KEY carrid = gs_flight-carrid
               connid = gs_flight-connid
               fldate = gs_flight-fldate.
    IF sy-subrc = 0.
      MESSAGE i003(zr2c) WITH gs_flight-carrid gs_flight-connid gs_flight-seatsocc INTO DATA(lv_message).
      message( text = lv_message
               type = `I` ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
