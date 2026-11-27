"! The classic SAP demo report DEMO_SEL_SCREEN_WITH_TABSTRIP as a report
"! class: a selection screen with a tabbed block whose tabs show the
"! subscreens 100 and 200.
CLASS z2ui5_cl_cgui_sample_09 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA button1 TYPE c LENGTH 20.
    DATA button2 TYPE c LENGTH 20.
    DATA button3 TYPE c LENGTH 20.

    DATA p1 TYPE c LENGTH 10.
    DATA p2 TYPE c LENGTH 10.
    DATA p3 TYPE c LENGTH 10.
    DATA q1 TYPE c LENGTH 10.
    DATA q2 TYPE c LENGTH 10.
    DATA q3 TYPE c LENGTH 10.

  PROTECTED SECTION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen REDEFINITION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_09 IMPLEMENTATION.

  METHOD selection_screen.

    screen->tabbed_block_begin( ).
    screen->tab( button1 ).
    screen->block_begin( ).
    screen->parameter( p1 ).
    screen->parameter( p2 ).
    screen->parameter( p3 ).
    screen->block_end( ).
    screen->tab( button2 ).
    screen->block_begin( ).
    screen->parameter( val        = q1
                       obligatory = abap_true ).
    screen->parameter( val        = q2
                       obligatory = abap_true ).
    screen->parameter( val        = q3
                       obligatory = abap_true ).
    screen->block_end( ).
    screen->tab( button3 ).
    screen->tabbed_block_end( ).

  ENDMETHOD.

  METHOD at_selection_screen.

    " the classic report branches on sy-dynnr (the subscreens 100 and 200)
    " and sy-ucomm, which the runtime does not set: the tabs are one screen
    " here, checked as a whole - so the message of the demo comes once, for
    " the selection screen; a push button would arrive in at_user_command( )
    message_t100( id     = `SABAPDEMOS`
                  number = 888
                  type   = `S`
                  v1     = `Action on Selection Screen`
                  v2     = `1000` ).

  ENDMETHOD.

  METHOD initialization.

    button1 = `Selection Screen 1`.
    button2 = `Selection Screen 2`.
    button3 = `Dynpro`.

  ENDMETHOD.

  METHOD start_of_selection.

    list( )->new_line( ).
    write( `P1:` ).
    write( p1 ).
    write( `Q1:` ).
    write( q1 ).
    list( )->new_line( ).
    write( `P2:` ).
    write( p2 ).
    write( `Q2:` ).
    write( q2 ).
    list( )->new_line( ).
    write( `P3:` ).
    write( p3 ).
    write( `Q3:` ).
    write( q3 ).

  ENDMETHOD.

ENDCLASS.
