"! The SAP GUI controls of a report - what the stand-ins of
"! cl_gui_custom_container, cl_gui_textedit and cl_gui_html_viewer
"! (z2ui5_cl_cgui_gui and its subclasses) ask the report they run in for.
"! z2ui5_cl_cgui_report implements it and keeps the state of every control
"! in a table of its own: a control object holds its id only, its text is
"! bound to the report's table and survives the roundtrip with it
INTERFACE z2ui5_if_cgui_gui PUBLIC.

  CONSTANTS:
    BEGIN OF cs_kind,
      container TYPE string VALUE `CONTAINER`,
      textedit  TYPE string VALUE `TEXTEDIT`,
      html      TYPE string VALUE `HTML`,
    END OF cs_kind.

  TYPES:
    "! one control: a container (custom, docking, splitter - name is the
    "! custom control area of the screen, row and column the cell of the
    "! parent splitter) or a control in its parent container
    BEGIN OF ty_s_control,
      id        TYPE i,
      kind      TYPE string,
      parent    TYPE i,
      name      TYPE string,
      dynnr     TYPE string,
      side      TYPE i,
      rows      TYPE i,
      columns   TYPE i,
      row       TYPE i,
      column    TYPE i,
      caption   TYPE string,
      text      TYPE string,
      html      TYPE string,
      url       TYPE string,
      readonly  TYPE abap_bool,
      toolbar   TYPE abap_bool,
      statusbar TYPE abap_bool,
      fixed     TYPE abap_bool,
      hidden    TYPE abap_bool,
      modified  TYPE abap_bool,
      freed     TYPE abap_bool,
    END OF ty_s_control,
    ty_t_control TYPE STANDARD TABLE OF ty_s_control WITH EMPTY KEY.

  "! a new control - its id
  METHODS control_add
    IMPORTING
      control       TYPE ty_s_control
    RETURNING
      VALUE(result) TYPE i.

  METHODS control_get
    IMPORTING
      id            TYPE i
    RETURNING
      VALUE(result) TYPE ty_s_control.

  METHODS control_set
    IMPORTING
      control TYPE ty_s_control.

  "! the controls of the custom control area name, into node - called by
  "! the screen when it renders z2ui5_cl_cgui_selscreen=>custom_control( )
  METHODS custom_render
    IMPORTING
      name TYPE string
      node TYPE REF TO z2ui5_cl_ui5_view_builder.

ENDINTERFACE.
