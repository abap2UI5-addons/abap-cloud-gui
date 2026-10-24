CLASS lcl_alv DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    DATA connections TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.
    METHODS select_connections.
    METHODS display.
  PRIVATE SECTION.
    DATA grid TYPE REF TO z2ui5_cl_cgui_gui_alv_grid.
    DATA fcat TYPE lvc_t_fcat.
    METHODS on_toolbar FOR EVENT toolbar OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_object.
    METHODS on_user_command FOR EVENT user_command OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_ucomm.
    METHODS on_double_click FOR EVENT double_click OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_row.
    METHODS on_hotspot FOR EVENT hotspot_click OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.
