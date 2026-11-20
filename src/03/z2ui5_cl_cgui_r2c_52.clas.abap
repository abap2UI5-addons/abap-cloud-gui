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

    DATA temp1 LIKE gt_seat.
    DATA temp2 LIKE LINE OF temp1.
    CLEAR temp1.

    temp2-connid = '0400'.
    temp2-seats = 10.
    INSERT temp2 INTO TABLE temp1.
    temp2-connid = '0402'.
    temp2-seats = 20.
    INSERT temp2 INTO TABLE temp1.
    temp2-connid = '2402'.
    temp2-seats = 30.
    INSERT temp2 INTO TABLE temp1.
    gt_seat = temp1.
    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.
        DATA temp3 TYPE z2ui5_if_cgui_gui=>ty_t_tc_column.
        DATA temp4 LIKE LINE OF temp3.

    CASE dynnr.
      WHEN `0100`.

        CLEAR temp3.

        CLEAR temp4.
        temp4-text = `Flight`.
        temp4-width = 4.
        INSERT temp4 INTO TABLE temp3.
        CLEAR temp4.
        temp4-text = `Seats`.
        temp4-input = abap_true.
        temp4-width = 10.
        INSERT temp4 INTO TABLE temp3.
        screen->table_control( name    = `TC_SEATS`
                               title   = `Seats per connection`
                               columns = temp3 ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.
          DATA temp5 TYPE string_table.
          DATA temp1 LIKE LINE OF temp5.
          DATA temp2 LIKE LINE OF temp5.

    CASE dynnr.
      WHEN `0100`.
        status_0100( ).
        " LOOP WITH CONTROL tc_seats - a line of the table control at a time
        tablecontrol_begin( `TC_SEATS` ).
        DO tc_seats-lines TIMES.
          tc_seats-current_line = sy-index.
          fill_0100( ).

          CLEAR temp5.

          temp1 = |{ gs_seat-connid }|.
          INSERT temp1 INTO TABLE temp5.

          temp2 = |{ gs_seat-seats }|.
          INSERT temp2 INTO TABLE temp5.
          tablecontrol_row( name   = `TC_SEATS`
                            values = temp5 ).
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
