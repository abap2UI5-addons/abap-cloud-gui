CLASS z2ui5_cl_cgui_r2c_14 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES ty_t_log TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    " global data of the report
    DATA sflight TYPE sflight.
    DATA:
      BEGIN OF wa_gt_sum,
        carrid TYPE sflight-carrid,
        count  TYPE i,
        seats  TYPE i,
      END OF wa_gt_sum.
    DATA gt_sum LIKE STANDARD TABLE OF wa_gt_sum WITH DEFAULT KEY.
    DATA gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY.
    DATA wa_gt_flight LIKE LINE OF gt_flight.
    DATA gt_log TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA wa_gt_log LIKE LINE OF gt_log.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.
    DATA s_fldate LIKE RANGE OF sflight-fldate.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    TYPES ty_t_wa_gt_sum LIKE STANDARD TABLE OF wa_gt_sum WITH DEFAULT KEY.

    METHODS add_log
      IMPORTING
        iv_text TYPE string
      CHANGING
        tt_log TYPE ty_t_log.

    METHODS show_sum
      CHANGING
        tt_sum TYPE ty_t_wa_gt_sum.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_14 IMPLEMENTATION.

  METHOD initialization.

    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( p_carrid
        )->select_option( s_fldate ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: sflight,
           gt_sum,
           wa_gt_sum,
           gt_flight,
           wa_gt_flight,
           gt_log,
           wa_gt_log.

    CLEAR gt_flight.
    CLEAR gt_sum.
    SELECT * FROM sflight INTO TABLE @gt_flight
      WHERE carrid = @p_carrid AND fldate IN @s_fldate.

    LOOP AT gt_flight INTO wa_gt_flight.
      CLEAR wa_gt_sum.
      wa_gt_sum-carrid = wa_gt_flight-carrid.
      wa_gt_sum-count = 1.
      wa_gt_sum-seats = wa_gt_flight-seatsmax - wa_gt_flight-seatsocc.
      COLLECT wa_gt_sum INTO gt_sum.
    ENDLOOP.

    add_log( EXPORTING
               iv_text = 'Flights read'
             CHANGING
               tt_log  = gt_log ).
    show_sum( CHANGING
                tt_sum = gt_sum ).

    LOOP AT gt_log INTO wa_gt_log.
      list( )->new_line(
          )->write( wa_gt_log ).
    ENDLOOP.

  ENDMETHOD.

  METHOD add_log.

    DATA ls_tt_log LIKE LINE OF tt_log.

    ls_tt_log = iv_text.
    APPEND ls_tt_log TO tt_log.

  ENDMETHOD.

  METHOD show_sum.

    DATA ls_tt_sum LIKE LINE OF tt_sum.

    DATA lt_seen TYPE STANDARD TABLE OF sflight-carrid WITH DEFAULT KEY.
    DATA ls_lt_seen LIKE LINE OF lt_seen.

    SORT tt_sum BY carrid.
    LOOP AT tt_sum INTO ls_tt_sum.
      READ TABLE lt_seen WITH KEY table_line = ls_tt_sum-carrid INTO ls_lt_seen.
      IF sy-subrc <> 0.
        ls_lt_seen = ls_tt_sum-carrid.
        APPEND ls_lt_seen TO lt_seen.
      ENDIF.
      list( )->new_line(
          )->write( ls_tt_sum-carrid
          )->write( ls_tt_sum-count
          )->write( ls_tt_sum-seats ).
    ENDLOOP.
    DATA(lv_n) = lines( lt_seen ).
    list( )->new_line(
        )->write( 'Airlines:'
        )->write( lv_n ).

  ENDMETHOD.

ENDCLASS.
