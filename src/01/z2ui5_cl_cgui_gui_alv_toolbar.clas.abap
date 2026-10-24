"! The stand-in of cl_alv_event_toolbar_set - e_object of the event toolbar
"! of the grid (z2ui5_cl_cgui_gui_alv_grid): the handler appends its buttons
"! to mt_toolbar, the grid shows them as functions of its toolbar, a press
"! raises user_command with the function
CLASS z2ui5_cl_cgui_gui_alv_toolbar DEFINITION PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES:
      "! a button of the toolbar - stb_button
      BEGIN OF ty_s_button,
        function  TYPE c LENGTH 70,
        icon      TYPE c LENGTH 40,
        quickinfo TYPE c LENGTH 132,
        butn_type TYPE i,
        disabled  TYPE abap_bool,
        text      TYPE c LENGTH 40,
        checked   TYPE abap_bool,
      END OF ty_s_button,
      ty_t_button TYPE STANDARD TABLE OF ty_s_button WITH DEFAULT KEY.

    DATA mt_toolbar TYPE ty_t_button.

ENDCLASS.


CLASS z2ui5_cl_cgui_gui_alv_toolbar IMPLEMENTATION.
ENDCLASS.
