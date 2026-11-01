CLASS lcl_menu DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    METHODS on_sapevent FOR EVENT sapevent OF z2ui5_cl_cgui_gui_html_viewer
      IMPORTING action.
ENDCLASS.
