CLASS z2ui5_cl_cgui_r2c_09 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " selection screen
    DATA p_a   TYPE decfloat34.
    DATA p_b   TYPE decfloat34.
    DATA p_dec TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_calc TYPE REF TO lif_rounding.

ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_09 IMPLEMENTATION.

  METHOD initialization.

    p_a = '1.005'.
    p_b = '2.5'.
    p_dec = 2.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( p_a
        )->parameter( p_b
        )->parameter( p_dec ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR go_calc.

    DATA(lo_calc) = NEW lcl_calculator( p_dec ).
    go_calc = lo_calc.
    list( )->new_line(
        )->write( 'Sum:'
        )->write( lo_calc->add( iv_a = p_a iv_b = p_b ) ).
    list( )->new_line(
        )->write( 'Rounded A:'
        )->write( go_calc->round( p_a ) ).

  ENDMETHOD.

ENDCLASS.
