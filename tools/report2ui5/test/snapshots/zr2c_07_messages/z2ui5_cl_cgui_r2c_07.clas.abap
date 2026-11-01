CLASS z2ui5_cl_cgui_r2c_07 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA gv_text TYPE string.

    " selection screen
    DATA p_type TYPE c LENGTH 1.
    DATA p_num  TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_07 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    p_type = 'S'.
    p_num = 42.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_type
                       obligatory = abap_true
        )->parameter( p_num ).

  ENDMETHOD.

  METHOD at_selection_screen.

    IF p_type NA 'SIWE'.
      MESSAGE e010(zr2c) WITH p_type INTO DATA(lv_message).
      message( text = lv_message
               type = `E` ).
      RETURN.
    ENDIF.
    IF p_num < 0.
      MESSAGE ID 'ZR2C' TYPE 'E' NUMBER '011' WITH p_num 'is negative' INTO lv_message.
      message( text = lv_message
               type = `E` ).
      RETURN.
    ENDIF.

  ENDMETHOD.

  METHOD start_of_selection.

    CASE p_type.
      WHEN 'S'.
        message( 'A status message' ).
      WHEN 'I'.
        message( text = `TEXT-001`
                 type = `I` ).
      WHEN 'W'.
        MESSAGE w012(zr2c) WITH p_num INTO DATA(lv_message).
        message( text = lv_message
                 type = `W` ).
      WHEN 'E'.
        gv_text = |Number { p_num } is not allowed|.
        message( text = gv_text
                 type = `W` ).
    ENDCASE.
    MESSAGE s013(zr2c) WITH p_num INTO gv_text.
    list( )->new_line(
        )->write( `Last message:`
        )->write( gv_text ).
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_message.
    message( text = lv_message
             type = sy-msgty ).

  ENDMETHOD.

ENDCLASS.
