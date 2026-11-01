CLASS z2ui5_cl_cgui_r2c_20 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " selection screen
    DATA tab_main TYPE c LENGTH 20.
    DATA tab_opt  TYPE c LENGTH 20.
    DATA p_carrid TYPE sflight-carrid.
    DATA s_fldate TYPE RANGE OF sy-datum.
    DATA p_max    TYPE i.
    DATA p_full   TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen_on_help REDEFINITION.
    METHODS at_selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
    METHODS at_selection_screen_ucomm
      IMPORTING
        ucomm TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_20 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Tabs, function keys and F1` ).
    p_carrid = 'LH'.
    p_max = 50.

    tab_main = 'Flights'.
    tab_opt = 'Options'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->function_key( number = 1
                          text   = 'Today'
        )->function_key( number = 2
                         text   = 'Reset'
                         icon   = `sap-icon://refresh`
        )->tabbed_block_begin(
        )->tab( tab_main
        )->parameter( val  = p_carrid
                      text = `Airline`
        )->select_option( val  = s_fldate
                          text = `Flight date`
        )->tab( tab_opt
        )->parameter( val          = p_max
                      text         = `Maximum flights`
                      help_request = abap_true
        )->checkbox( val  = p_full
                     text = `Full flights only`
        )->tabbed_block_end( ).

  ENDMETHOD.

  METHOD at_selection_screen_on_help.

    CASE field.
      WHEN `P_MAX`.
        message( text = 'The list shows at most this many flights'
                 type = `I` ).
      WHEN OTHERS.
        super->at_selection_screen_on_help( field ).
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen.

    " F8 - the classic sy-ucomm of Execute
    at_selection_screen_ucomm( `ONLI` ).

  ENDMETHOD.

  METHOD start_of_selection.

    list( )->new_line(
        )->write( 'Airline'
        )->write( p_carrid
        )->write( 'at most'
        )->write( p_max ).

  ENDMETHOD.

  METHOD at_user_command.

    " a button or USER-COMMAND of the selection screen - the classic AT SELECTION-SCREEN
    at_selection_screen_ucomm( ucomm ).

  ENDMETHOD.

  METHOD at_selection_screen_ucomm.

    CASE ucomm.
      WHEN 'FC01'.
        s_fldate = VALUE #( ( sign = 'I' option = 'EQ' low = sy-datum ) ).
      WHEN 'FC02'.
        CLEAR s_fldate.
        CLEAR p_full.
        p_max = 50.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
