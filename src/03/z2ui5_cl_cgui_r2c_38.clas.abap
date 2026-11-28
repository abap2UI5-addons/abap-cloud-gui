CLASS z2ui5_cl_cgui_r2c_38 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_todo,
        task TYPE string,
        done TYPE abap_bool,
      END OF ty_todo.

    " global data of the report
    DATA gt_todo   TYPE STANDARD TABLE OF ty_todo WITH DEFAULT KEY.
    DATA lv_answer TYPE c LENGTH 1.

    " selection screen
    DATA p_keep TYPE abap_bool.

    " the answers of the popups - the statements after the CALL FUNCTION
    METHODS on_popup_1
      IMPORTING
        answer TYPE string.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_38 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Clean up a To-Do List` ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->checkbox( val  = p_keep
                      text = `Keep everything` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA temp1 LIKE gt_todo.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE string_table.
    CLEAR temp1.

    temp2-task = `Write the report`.
    temp2-done = abap_true.
    INSERT temp2 INTO TABLE temp1.
    temp2-task = `Test it`.
    temp2-done = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-task = `Ship it`.
    temp2-done = abap_true.
    INSERT temp2 INTO TABLE temp1.
    gt_todo = temp1.


    CLEAR temp3.
    INSERT `Delete` INTO TABLE temp3.
    INSERT `Keep` INTO TABLE temp3.
    popup_to_decide( question = 'Delete the tasks that are done?'
                     options  = temp3
                     then     = `ON_POPUP_1`
                     title    = 'Clean up' ).

  ENDMETHOD.

  METHOD on_popup_1.
    DATA ls_todo LIKE LINE OF gt_todo.

    lv_answer = answer.
    IF lv_answer = '1' AND p_keep = abap_false.
      DELETE gt_todo WHERE done = abap_true.
      list( )->new_line(
          )->write( 'The tasks that are done were deleted.' ).
    ELSE.
      list( )->new_line(
          )->write( 'Nothing was deleted.' ).
    ENDIF.
    list( )->uline( ).

    LOOP AT gt_todo INTO ls_todo.
      list( )->new_line(
          )->write_as_checkbox( ls_todo-done
          )->write( ls_todo-task ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
