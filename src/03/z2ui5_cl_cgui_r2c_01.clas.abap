CLASS z2ui5_cl_cgui_r2c_01 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " selection screen
    DATA p_name  TYPE string.
    DATA p_times TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_01 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Hello World` ).
    p_times = 3.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_name
                       text       = `Your name`
                       obligatory = abap_true
                       lower_case = abap_true
        )->parameter( val  = p_times
                      text = `Lines` ).

  ENDMETHOD.

  METHOD start_of_selection.

    list( )->new_line(
        )->write( 'Hello'
        )->write( p_name ).
    list( )->uline( ).
    DO p_times TIMES.
      list( )->new_line(
          )->write( 'Line'
          )->write( sy-index ).
    ENDDO.
    list( )->skip( ).
    list( )->new_line(
        )->write( 'Done.' ).

  ENDMETHOD.

ENDCLASS.
