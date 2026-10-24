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

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_38 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Clean up a To-Do List` ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->checkbox( val  = p_keep
                      text = `Keep everything` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_todo,
           lv_answer.

    gt_todo = VALUE #( ( task = `Write the report` done = abap_true )
                       ( task = `Test it`          done = abap_false )
                       ( task = `Ship it`          done = abap_true ) ).

    popup_to_decide( question = 'Delete the tasks that are done?'
                     options  = VALUE #( ( `Delete` ) ( `Keep` ) )
                     ucomm    = `POPUP_1`
                     title    = 'Clean up' ).

  ENDMETHOD.

  METHOD at_user_command.

    " the answers of the popups - the statements after the CALL FUNCTION
    CASE ucomm.
      WHEN `POPUP_1`.
        lv_answer = popup_answer( ).
        IF lv_answer = '1' AND p_keep = abap_false.
          DELETE gt_todo WHERE done = abap_true.
          list( )->new_line(
              )->write( 'The tasks that are done were deleted.' ).
        ELSE.
          list( )->new_line(
              )->write( 'Nothing was deleted.' ).
        ENDIF.
        list( )->uline( ).
        LOOP AT gt_todo INTO DATA(ls_todo).
          list( )->new_line(
              )->write_as_checkbox( ls_todo-done
              )->write( ls_todo-task ).
        ENDLOOP.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
