*&---------------------------------------------------------------------*
*& Report ZR2C_38_CONFIRM
*&---------------------------------------------------------------------*
*& Cleaning up a to-do list: the user confirms the deletion with
*& POPUP_TO_CONFIRM, the answer decides what the list shows - the run
*& goes on after the popup with its answer
*&---------------------------------------------------------------------*
REPORT zr2c_38_confirm.

TYPES:
  BEGIN OF ty_todo,
    task TYPE string,
    done TYPE abap_bool,
  END OF ty_todo.

DATA gt_todo TYPE STANDARD TABLE OF ty_todo WITH DEFAULT KEY.

PARAMETERS p_keep AS CHECKBOX.

START-OF-SELECTION.
  gt_todo = VALUE #( ( task = `Write the report` done = abap_true )
                     ( task = `Test it`          done = abap_false )
                     ( task = `Ship it`          done = abap_true ) ).

  DATA lv_answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = 'Clean up'
      text_question  = 'Delete the tasks that are done?'
      text_button_1  = 'Delete'
      text_button_2  = 'Keep'
    IMPORTING
      answer         = lv_answer
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.

  IF lv_answer = '1' AND p_keep = abap_false.
    DELETE gt_todo WHERE done = abap_true.
    WRITE: / 'The tasks that are done were deleted.'.
  ELSE.
    WRITE: / 'Nothing was deleted.'.
  ENDIF.
  ULINE.
  LOOP AT gt_todo INTO DATA(ls_todo).
    WRITE: / ls_todo-done AS CHECKBOX, ls_todo-task.
  ENDLOOP.
