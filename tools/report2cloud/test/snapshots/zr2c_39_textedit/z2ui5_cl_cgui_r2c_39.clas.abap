CLASS z2ui5_cl_cgui_r2c_39 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " selection screen
    DATA p_text TYPE string.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_gui_event REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_note TYPE REF TO lcl_note.

ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_39 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A Note Editor` ).
    p_text = 'Buy milk'.

  ENDMETHOD.

  METHOD selection_screen.

    lcl_r2c=>app = me.

    screen->parameter( val        = p_text
                       text       = `Note`
                       lower_case = abap_true ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR go_note.

    go_note = NEW lcl_note( ).
    write( space ).

  ENDMETHOD.

  METHOD at_gui_event.

    lcl_r2c=>app = me.

  ENDMETHOD.

ENDCLASS.
