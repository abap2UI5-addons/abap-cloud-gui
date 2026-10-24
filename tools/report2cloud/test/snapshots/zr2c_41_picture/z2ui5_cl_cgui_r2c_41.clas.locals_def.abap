CLASS lcl_stamp DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    METHODS constructor.
    METHODS on_click FOR EVENT picture_click OF z2ui5_cl_cgui_gui_picture.
    DATA mo_dock TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA mo_picture TYPE REF TO z2ui5_cl_cgui_gui_picture.
    DATA mv_count TYPE i.
ENDCLASS.
