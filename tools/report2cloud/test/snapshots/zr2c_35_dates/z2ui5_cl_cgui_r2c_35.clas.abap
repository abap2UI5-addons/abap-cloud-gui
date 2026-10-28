CLASS z2ui5_cl_cgui_r2c_35 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    CONSTANTS lc_monday TYPE d VALUE '19700105'.

    " global data of the report
    DATA lt_weekday TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_between TYPE i.
    DATA lv_next    TYPE d.
    DATA lv_last    TYPE d.

    " selection screen
    DATA p_start TYPE d.
    DATA p_end   TYPE d.
    DATA p_days  TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_35 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Project Dates` ).
    p_start = '20260105'.
    p_end = '20260320'.
    p_days = 10.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_start
                       text = `Start`
        )->parameter( val  = p_end
                      text = `End`
        )->parameter( val  = p_days
                      text = `Working days` ).

  ENDMETHOD.

  METHOD start_of_selection.

    lt_weekday = VALUE #( ( `Monday` ) ( `Tuesday` ) ( `Wednesday` ) ( `Thursday` )
                          ( `Friday` ) ( `Saturday` ) ( `Sunday` ) ).

    IF p_end < p_start.
      message( text = 'The end is before the start'
               type = `E` ).
      RETURN.
    ENDIF.

    lv_between = p_end - p_start.
    list( )->new_line(
        )->write( 'Days between start and end:'
        )->write( lv_between ).

    DATA(lv_day) = p_start.
    DATA(lv_left) = p_days.
    WHILE lv_left > 0.
      lv_day = lv_day + 1.
      IF ( lv_day - lc_monday ) MOD 7 < 5.
        lv_left = lv_left - 1.
      ENDIF.
    ENDWHILE.
    list( )->new_line(
        )->write( |After { p_days } working days:|
        )->write( lv_day ).

    DATA(lv_first) = p_start.
    lv_first+6(2) = '01'.
    lv_next = lv_first + 31.
    lv_next+6(2) = '01'.
    lv_last = lv_next - 1.
    list( )->uline( ).
    list( )->new_line(
        )->write( 'First of the month:'
        )->write( lv_first
        )->write( lt_weekday[ ( lv_first - lc_monday ) MOD 7 + 1 ] ).
    list( )->new_line(
        )->write( 'Last of the month:'
        )->write( lv_last
        )->write( lt_weekday[ ( lv_last - lc_monday ) MOD 7 + 1 ] ).
    list( )->new_line(
        )->write( 'Start:'
        )->write( p_start
        )->write( lt_weekday[ ( p_start - lc_monday ) MOD 7 + 1 ] ).

  ENDMETHOD.

ENDCLASS.
