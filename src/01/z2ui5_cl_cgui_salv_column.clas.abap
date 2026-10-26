"! The stand-in of cl_salv_column, cl_salv_column_table and
"! cl_salv_column_list - a column of z2ui5_cl_cgui_salv_table. What is set
"! here is the field catalog of the grid at display( ); the rest of the
"! settings of a classic column are taken without effect
CLASS z2ui5_cl_cgui_salv_column DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    DATA mv_name      TYPE string READ-ONLY.
    DATA mv_long      TYPE string READ-ONLY.
    DATA mv_medium    TYPE string READ-ONLY.
    DATA mv_short     TYPE string READ-ONLY.
    DATA mv_hidden    TYPE abap_bool READ-ONLY.
    DATA mv_technical TYPE abap_bool READ-ONLY.
    DATA mv_hotspot   TYPE abap_bool READ-ONLY.
    DATA mv_key       TYPE abap_bool READ-ONLY.
    DATA mv_length    TYPE i READ-ONLY.
    DATA mv_tooltip   TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        name TYPE clike.

    METHODS get_columnname
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_long_text
      IMPORTING
        value TYPE clike.

    METHODS set_medium_text
      IMPORTING
        value TYPE clike.

    METHODS set_short_text
      IMPORTING
        value TYPE clike.

    METHODS get_long_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS get_medium_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS get_short_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_visible
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_visible
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_technical
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_key
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_output_length
      IMPORTING
        value TYPE i.

    METHODS set_tooltip
      IMPORTING
        value TYPE clike.

    "! hotspot (5) and link (4) are a hotspot of the grid - link_click
    METHODS set_cell_type
      IMPORTING
        value TYPE i.

    METHODS set_alignment
      IMPORTING
        value TYPE i.

    METHODS set_optimized
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_zero
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_lowercase
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_specific_group
      IMPORTING
        id TYPE clike.

    METHODS set_color
      IMPORTING
        value TYPE any.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_column IMPLEMENTATION.

  METHOD constructor.

    mv_name = to_upper( condense( name ) ).

  ENDMETHOD.

  METHOD get_columnname.

    value = mv_name.

  ENDMETHOD.

  METHOD set_long_text.

    mv_long = value.

  ENDMETHOD.

  METHOD set_medium_text.

    mv_medium = value.

  ENDMETHOD.

  METHOD set_short_text.

    mv_short = value.

  ENDMETHOD.

  METHOD get_long_text.

    value = mv_long.

  ENDMETHOD.

  METHOD get_medium_text.

    value = mv_medium.

  ENDMETHOD.

  METHOD get_short_text.

    value = mv_short.

  ENDMETHOD.

  METHOD set_visible.

    mv_hidden = xsdbool( value = abap_false ).

  ENDMETHOD.

  METHOD is_visible.

    value = xsdbool( mv_hidden = abap_false AND mv_technical = abap_false ).

  ENDMETHOD.

  METHOD set_technical.

    mv_technical = value.

  ENDMETHOD.

  METHOD set_key.

    mv_key = value.

  ENDMETHOD.

  METHOD set_output_length.

    mv_length = value.

  ENDMETHOD.

  METHOD set_tooltip.

    mv_tooltip = value.

  ENDMETHOD.

  METHOD set_cell_type.

    mv_hotspot = xsdbool( value = z2ui5_if_cgui_salv_c=>cell_type-hotspot OR value = z2ui5_if_cgui_salv_c=>cell_type-link ).

  ENDMETHOD.

  METHOD set_alignment ##NEEDED.
  ENDMETHOD.

  METHOD set_optimized ##NEEDED.
  ENDMETHOD.

  METHOD set_zero ##NEEDED.
  ENDMETHOD.

  METHOD set_lowercase ##NEEDED.
  ENDMETHOD.

  METHOD set_specific_group ##NEEDED.
  ENDMETHOD.

  METHOD set_color ##NEEDED.
  ENDMETHOD.

ENDCLASS.
