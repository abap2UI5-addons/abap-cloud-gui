CLASS z2ui5_cl_cgui_r2c_52 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_seat,
        connid TYPE n LENGTH 4,
        seats  TYPE i,
      END OF ty_seat.

    " global data of the report
    DATA tc_seats TYPE z2ui5_cl_cgui_report=>ty_s_tableview.
    DATA gt_seat  TYPE STANDARD TABLE OF ty_seat WITH DEFAULT KEY.
    DATA gs_seat  TYPE ty_seat.
    DATA ok_code  TYPE sy-ucomm.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS after_call_screen REDEFINITION.

  PRIVATE SECTION.
    METHODS status_0100.

    METHODS fill_0100.

    METHODS read_0100.

    METHODS user_command_0100.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_52 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A table control on a dynpro` ).

  ENDMETHOD.

  METHOD start_of_selection.

    gt_seat = VALUE #( ( connid = '0400' seats = 10 )
                       ( connid = '0402' seats = 20 )
                       ( connid = '2402' seats = 30 ) ).
    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    CASE dynnr.
      WHEN `0100`.
        screen->table_control( name    = `TC_SEATS`
                               title   = `Seats per connection`
                               columns = VALUE #( ( text = `Flight` width = 4 )
                                                  ( text = `Seats` input = abap_true width = 10 ) ) ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.

    CASE dynnr.
      WHEN `0100`.
        status_0100( ).
        " LOOP WITH CONTROL tc_seats - a line of the table control at a time
        tablecontrol_begin( `TC_SEATS` ).
        DO tc_seats-lines TIMES.
          tc_seats-current_line = sy-index.
          fill_0100( ).
          tablecontrol_row( name   = `TC_SEATS`
                            values = VALUE #( ( |{ gs_seat-connid }| ) ( |{ gs_seat-seats }| ) ) ).
        ENDDO.
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pai.

    CASE dynnr.
      WHEN `0100`.
        ok_code = ucomm.
        " LOOP WITH CONTROL tc_seats - the lines the table control showed, as the user left them
        DO tablecontrol_count( `TC_SEATS` ) TIMES.
          tc_seats-current_line = sy-index.
          gs_seat-connid = tablecontrol_cell( name = `TC_SEATS` row = sy-index col = 1 ).
          gs_seat-seats = tablecontrol_cell( name = `TC_SEATS` row = sy-index col = 2 ).
          read_0100( ).
        ENDDO.
        IF screen_left( ) = abap_true.
          RETURN.
        ENDIF.
        user_command_0100( ).
    ENDCASE.

  ENDMETHOD.

  METHOD after_call_screen.

    CASE dynnr.
      WHEN `0100`.
        LOOP AT gt_seat INTO gs_seat.
          list( )->new_line(
              )->write( gs_seat-connid
              )->write( gs_seat-seats ).
        ENDLOOP.
    ENDCASE.

  ENDMETHOD.

  METHOD status_0100.

    tc_seats-lines = lines( gt_seat ).

  ENDMETHOD.

  METHOD fill_0100.

    READ TABLE gt_seat INTO gs_seat INDEX tc_seats-current_line.

  ENDMETHOD.

  METHOD read_0100.

    MODIFY gt_seat FROM gs_seat INDEX tc_seats-current_line.

  ENDMETHOD.

  METHOD user_command_0100.

    CASE ok_code.
      WHEN 'BACK'.
        leave_to_screen( `0000` ).
        RETURN.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
