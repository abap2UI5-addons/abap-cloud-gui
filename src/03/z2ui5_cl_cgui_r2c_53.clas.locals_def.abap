CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    METHODS on_user_command FOR EVENT added_function OF z2ui5_cl_cgui_salv_table
      IMPORTING e_salv_function.
    METHODS on_link_click FOR EVENT link_click OF z2ui5_cl_cgui_salv_table
      IMPORTING row column.
ENDCLASS.
