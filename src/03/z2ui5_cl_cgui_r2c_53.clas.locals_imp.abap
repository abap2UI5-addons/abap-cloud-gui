" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_53.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_53 DEFINITION LOCAL FRIENDS lcl_events.


CLASS lcl_events IMPLEMENTATION.
  METHOD on_user_command.
    lcl_r2c=>app->handle_user_command( e_salv_function ).
  ENDMETHOD.

  METHOD on_link_click.
    READ TABLE lcl_r2c=>app->gt_call INDEX row INTO DATA(ls_call).
    IF sy-subrc = 0.
      lcl_r2c=>app->message( |{ ls_call-interface } ({ column }): { ls_call-message }| ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
