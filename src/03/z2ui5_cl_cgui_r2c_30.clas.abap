CLASS z2ui5_cl_cgui_r2c_30 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_result,
        student TYPE c LENGTH 20,
        subject TYPE c LENGTH 15,
        points  TYPE i,
        passed  TYPE abap_bool,
      END OF ty_result.

    " global data of the report
    DATA gt_result TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY.

    " selection screen
    DATA p_pass TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_30 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Exam Results with Column Names` ).
    p_pass = 50.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_pass
                       text = `Points to pass` ).

  ENDMETHOD.

  METHOD start_of_selection.

    gt_result = VALUE #( ( student = 'Anna'  subject = 'Maths'   points = 71 )
                         ( student = 'Ben'   subject = 'Maths'   points = 44 )
                         ( student = 'Clara' subject = 'Physics' points = 58 ) ).
    LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-passed = xsdbool( <ls_result>-points >= p_pass ).
    ENDLOOP.

    DATA(lo_alv) = alv( gt_result
        )->set_title( 'Exam results' ).
    LOOP AT lo_alv->get_columns( gt_result ) INTO DATA(ls_column).
      lo_alv->set_column_text( name = ls_column-name
                               text = |{ ls_column-name } ({ ls_column-label })| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
