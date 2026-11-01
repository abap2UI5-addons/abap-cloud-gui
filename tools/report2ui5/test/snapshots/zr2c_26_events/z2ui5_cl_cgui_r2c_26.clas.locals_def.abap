CLASS lcl_app DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    DATA mo_cont    TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA mo_split   TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA mo_toolbar TYPE REF TO z2ui5_cl_cgui_gui_toolbar.
    DATA mo_html    TYPE REF TO z2ui5_cl_cgui_gui_html_viewer.
    DATA mo_box     TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA mv_count   TYPE i.
    METHODS create.
    METHODS show_flights.
    METHODS on_function FOR EVENT function_selected OF z2ui5_cl_cgui_gui_toolbar
      IMPORTING fcode.
    METHODS on_sapevent FOR EVENT sapevent OF z2ui5_cl_cgui_gui_html_viewer
      IMPORTING action query_table.
    METHODS on_close FOR EVENT close OF z2ui5_cl_cgui_gui_container
      IMPORTING sender.
ENDCLASS.
