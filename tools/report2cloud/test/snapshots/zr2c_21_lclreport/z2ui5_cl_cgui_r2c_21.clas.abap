CLASS z2ui5_cl_cgui_r2c_21 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    CONSTANTS gc_max TYPE i VALUE 3.

    " global data of the report
    DATA scarr    TYPE scarr.
    DATA gv_total TYPE i.

    " selection screen
    DATA p_carrid TYPE sflight-carrid.
    DATA s_connid LIKE RANGE OF scarr-carrid.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen_output REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_report TYPE REF TO lcl_report.

    METHODS total.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_21 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    p_carrid = 'LH'.

    go_report = NEW lcl_report( |Flights| ).

  ENDMETHOD.

  METHOD selection_screen.

    lcl_r2c=>app = me.

    screen->parameter( p_carrid
        )->select_option( val        = s_connid
                          no_display = abap_true ).

  ENDMETHOD.

  METHOD at_selection_screen_output.

    lcl_r2c=>app = me.

    set_cursor_field( 'P_CARRID' ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: scarr,
           gv_total.

    SELECT SINGLE * FROM scarr INTO @scarr WHERE carrid = @p_carrid.
    IF sy-subrc <> 0.
      message( 'Unknown airline' ).
      leave_to_selection_screen( ).
      RETURN.
    ENDIF.
    list( )->new_line(
        )->write( 'Airline:'
        )->write( scarr-carrname ).
    go_report->run( ).

  ENDMETHOD.

  METHOD total.

    list( )->new_line(
        )->write( 'Seats occupied in the first'
        )->write( gc_max
        )->write( 'flights:'
        )->write( gv_total ).

  ENDMETHOD.

ENDCLASS.
