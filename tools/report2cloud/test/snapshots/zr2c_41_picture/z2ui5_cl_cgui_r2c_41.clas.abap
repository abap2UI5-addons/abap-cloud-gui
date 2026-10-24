CLASS z2ui5_cl_cgui_r2c_41 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " selection screen
    DATA p_fit TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_gui_event REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_stamp TYPE REF TO lcl_stamp.

ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_41 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    set_title( `A Stamp` ).
    p_fit = abap_true.

  ENDMETHOD.

  METHOD selection_screen.

    lcl_r2c=>app = me.

    screen->checkbox( val  = p_fit
                      text = `Fit to width` ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR go_stamp.

    go_stamp = NEW lcl_stamp( ).
    list( )->new_line(
        )->write( 'Click the stamp' ).

  ENDMETHOD.

  METHOD at_gui_event.

    lcl_r2c=>app = me.

  ENDMETHOD.

ENDCLASS.
