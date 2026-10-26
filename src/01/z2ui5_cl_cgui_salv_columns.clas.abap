"! The stand-in of cl_salv_columns_table and cl_salv_columns_list - the
"! columns of z2ui5_cl_cgui_salv_table, one z2ui5_cl_cgui_salv_column for
"! each component of the line of its table
CLASS z2ui5_cl_cgui_salv_columns DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES:
      "! SALV_S_COLUMN_REF / SALV_T_COLUMN_REF
      BEGIN OF ty_s_column_ref,
        columnname TYPE c LENGTH 30,
        r_column   TYPE REF TO z2ui5_cl_cgui_salv_column,
      END OF ty_s_column_ref.
    TYPES ty_t_column_ref TYPE STANDARD TABLE OF ty_s_column_ref WITH DEFAULT KEY.

    "! the columns of the components of line
    METHODS constructor
      IMPORTING
        line TYPE any.

    METHODS get
      RETURNING
        VALUE(value) TYPE ty_t_column_ref.

    "! a column that is not there raises z2ui5_cx_cgui_salv - cx_salv_not_found
    METHODS get_column
      IMPORTING
        columnname   TYPE clike
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_column.

    METHODS set_optimize
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_key_fixation
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_color_column
      IMPORTING
        value TYPE clike.

    METHODS set_headers_visible
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_column_position
      IMPORTING
        columnname TYPE clike
        position   TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mt_column TYPE ty_t_column_ref.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_columns IMPLEMENTATION.

  METHOD constructor.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( line ).
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
      RETURN.
    ENDIF.
    LOOP AT CAST cl_abap_structdescr( lo_type )->get_components( ) INTO DATA(ls_component) WHERE name IS NOT INITIAL.
      INSERT VALUE #( columnname = ls_component-name
                      r_column   = NEW #( ls_component-name ) ) INTO TABLE mt_column.
    ENDLOOP.

  ENDMETHOD.

  METHOD get.

    value = mt_column.

  ENDMETHOD.

  METHOD get_column.

    DATA(lv_name) = to_upper( condense( columnname ) ).
    LOOP AT mt_column INTO DATA(ls_column) WHERE columnname = lv_name.
      value = ls_column-r_column.
      RETURN.
    ENDLOOP.
    RAISE EXCEPTION TYPE z2ui5_cx_cgui_salv
      EXPORTING
        val = |No column { lv_name }|.

  ENDMETHOD.

  METHOD set_optimize ##NEEDED.
  ENDMETHOD.

  METHOD set_key_fixation ##NEEDED.
  ENDMETHOD.

  METHOD set_color_column ##NEEDED.
  ENDMETHOD.

  METHOD set_headers_visible ##NEEDED.
  ENDMETHOD.

  METHOD set_column_position ##NEEDED.
  ENDMETHOD.

ENDCLASS.
