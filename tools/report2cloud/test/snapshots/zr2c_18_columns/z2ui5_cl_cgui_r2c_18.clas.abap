CLASS z2ui5_cl_cgui_r2c_18 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gt_flight TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight TYPE sflight,
      gv_total  TYPE i,
      gv_col    TYPE i VALUE 40.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_18 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `An evaluation by the column` ).
    set_line_count( 30 ).
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

    list( )->new_line(
        )->write( val  = 'Flight'
                  pos  = 1
                  name = `Flight`
        )->write( val  = 'Date'
                  pos  = 10
                  name = `Date`
        )->write( val = 'Occupied'
                  pos = 25
        )->write( val = 'Free'
                  pos = gv_col ).
    list( )->uline( ).
    LOOP AT gt_flight INTO gs_flight.
      list( )->reserve( 2 ).
      list( )->new_line(
          )->write( val     = gs_flight-connid
                    under   = `Flight`
                    hotspot = abap_true
                    hide    = gs_flight
          )->write( val   = gs_flight-fldate
                    under = `Date`
          )->write( val = gs_flight-seatsocc
                    pos = 25
                    len = 8
          )->write( val    = gs_flight-seatsmax
                    pos    = gv_col
                    len    = 6
                    no_gap = abap_true
          )->write( '-' ).
      gv_total = gv_total + gs_flight-seatsocc.
    ENDLOOP.
    list( )->uline( ).
    list( )->position( 25 ).
    write( gv_total ).
    list( )->new_line(
        )->write( 'The list ends at line'
        )->write( list( )->current_line( ) ).

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the field the clicked line was written with
    z2ui5_cl_cgui_list=>hide_restore( EXPORTING hide = hide
                                      CHANGING  val  = gs_flight ).

    " the third level replaces the second: Back returns to the flight list
    IF lsind( ) > 2.
      set_lsind( 2 ).
    ENDIF.
    IF lsind( ) = 1.
      window( columns = 60
              lines   = 10 ).
    ENDIF.
    list( )->new_line(
        )->write( 'Level'
        )->write( lsind( )
        )->write( 'flight'
        )->write( gs_flight-connid ).
    list( )->new_line(
        )->write( val = 'Occupied:'
                  pos = 5
        )->write( val = gs_flight-seatsocc
                  pos = 20
                  len = 8 ).
    list( )->new_line(
        )->write( val     = 'Column after the value:'
                  pos     = 5
                  hotspot = abap_true
                  hide    = gs_flight
        )->write( list( )->current_column( ) ).

  ENDMETHOD.

ENDCLASS.
