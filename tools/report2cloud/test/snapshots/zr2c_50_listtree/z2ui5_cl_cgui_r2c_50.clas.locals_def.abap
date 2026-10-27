CLASS lcl_tree DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    METHODS display.
  PRIVATE SECTION.
    DATA tree TYPE REF TO z2ui5_cl_cgui_gui_list_tree.
    METHODS on_item_double_click FOR EVENT item_double_click OF z2ui5_cl_cgui_gui_list_tree
      IMPORTING node_key item_name.
    METHODS on_link_click FOR EVENT link_click OF z2ui5_cl_cgui_gui_list_tree
      IMPORTING node_key item_name.
ENDCLASS.
