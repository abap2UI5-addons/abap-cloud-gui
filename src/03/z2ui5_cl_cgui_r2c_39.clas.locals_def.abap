CLASS lcl_note DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    METHODS constructor.
    METHODS on_function FOR EVENT function_selected OF z2ui5_cl_cgui_gui_toolbar
      IMPORTING fcode.
    DATA mo_edit TYPE REF TO z2ui5_cl_cgui_gui_textedit.
    DATA mo_tool TYPE REF TO z2ui5_cl_cgui_gui_toolbar.
ENDCLASS.
