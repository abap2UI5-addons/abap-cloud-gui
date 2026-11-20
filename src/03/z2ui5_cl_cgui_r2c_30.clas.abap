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
    TYPES temp1_9de9ae7a30 TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY.
DATA gt_result TYPE temp1_9de9ae7a30.

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

    DATA temp1 LIKE gt_result.
    DATA temp2 LIKE LINE OF temp1.
    FIELD-SYMBOLS <ls_result> LIKE LINE OF gt_result.
      DATA temp4 TYPE xsdboolean.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
    DATA temp3 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_column LIKE LINE OF temp3.
    CLEAR temp1.

    temp2-student = 'Anna'.
    temp2-subject = 'Maths'.
    temp2-points = 71.
    INSERT temp2 INTO TABLE temp1.
    temp2-student = 'Ben'.
    temp2-subject = 'Maths'.
    temp2-points = 44.
    INSERT temp2 INTO TABLE temp1.
    temp2-student = 'Clara'.
    temp2-subject = 'Physics'.
    temp2-points = 58.
    INSERT temp2 INTO TABLE temp1.
    gt_result = temp1.

    LOOP AT gt_result ASSIGNING <ls_result>.

      temp4 = boolc( <ls_result>-points >= p_pass ).
      <ls_result>-passed = temp4.
    ENDLOOP.


    lo_alv = alv( gt_result
        )->set_title( 'Exam results' ).

    temp3 = lo_alv->get_columns( gt_result ).

    LOOP AT temp3 INTO ls_column.
      lo_alv->set_column_text( name = ls_column-name
                               text = |{ ls_column-name } ({ ls_column-label })| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
