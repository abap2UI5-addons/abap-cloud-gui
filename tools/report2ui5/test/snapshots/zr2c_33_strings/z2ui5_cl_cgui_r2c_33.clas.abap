CLASS z2ui5_cl_cgui_r2c_33 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA lt_part     TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_initials TYPE string.

    " selection screen
    DATA p_name TYPE string.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_33 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Working with Strings` ).
    p_name = 'ada   augusta  lovelace'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_name
                       text       = `Name`
                       lower_case = abap_true ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA(lv_clean) = condense( p_name ).
    SPLIT lv_clean AT space INTO TABLE lt_part.

    list( )->new_line(
        )->write( 'Input:'
        )->write( p_name ).
    list( )->new_line(
        )->write( 'Condensed:'
        )->write( lv_clean ).
    list( )->new_line(
        )->write( 'Parts:'
        )->write( lines( lt_part ) ).
    list( )->uline( ).

    LOOP AT lt_part INTO DATA(lv_part).
      DATA(lv_word) = to_upper( substring( val = lv_part len = 1 ) ) && substring( val = lv_part off = 1 ).
      list( )->new_line(
          )->write( sy-tabix
          )->write( lv_word
          )->write( strlen( lv_part ) ).
      CONCATENATE lv_initials lv_word(1) '.' INTO lv_initials.
    ENDLOOP.
    list( )->uline( ).

    DATA(lv_upper) = to_upper( lv_clean ).
    DATA(lv_dashed) = lv_clean.
    REPLACE ALL OCCURRENCES OF ` ` IN lv_dashed WITH `-`.
    DATA(lv_vowels) = lv_clean.
    TRANSLATE lv_vowels USING 'aAeEiIoOuU'.

    list( )->new_line(
        )->write( 'Initials:'
        )->write( lv_initials ).
    list( )->new_line(
        )->write( 'Upper case:'
        )->write( lv_upper ).
    list( )->new_line(
        )->write( 'With dashes:'
        )->write( lv_dashed ).
    list( )->new_line(
        )->write( 'Vowels raised:'
        )->write( lv_vowels ).
    list( )->new_line(
        )->write( 'Reversed:'
        )->write( reverse( lv_clean ) ).

  ENDMETHOD.

ENDCLASS.
