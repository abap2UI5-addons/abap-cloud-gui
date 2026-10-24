" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_40.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_40 DEFINITION LOCAL FRIENDS lcl_menu.


CLASS lcl_menu IMPLEMENTATION.
  METHOD on_sapevent.
    lcl_r2c=>app->message( |You picked { action }| ).
  ENDMETHOD.
ENDCLASS.
