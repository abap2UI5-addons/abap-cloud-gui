CLASS lcl_view DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    DATA airlines    TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
    DATA connections TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.
    METHODS display.
  PRIVATE SECTION.
    DATA split  TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA header TYPE REF TO z2ui5_cl_cgui_gui_alv_grid.
    DATA items  TYPE REF TO z2ui5_cl_cgui_gui_alv_grid.
    METHODS on_double_click FOR EVENT double_click OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_row.
ENDCLASS.
