"! The stand-in of the settings of a SALV table - cl_salv_display_settings,
"! cl_salv_functions(_list), cl_salv_selections, cl_salv_sorts,
"! cl_salv_aggregations, cl_salv_layout, cl_salv_filters, cl_salv_print and
"! cl_salv_functional_settings in one, and cl_salv_tree_settings:
"! get_display_settings( ),
"! get_functions( ), get_selections( ), ... of z2ui5_cl_cgui_salv_table
"! answer it. The title, the striped rows, the functions added, the
"! selection mode, the sorts (with their subtotals) and the totals of the
"! aggregations go to the grid at display( ); get_selected_rows( ) are the
"! rows the user picked in it. The rest is taken without effect - an
"! aggregation other than the total among them
CLASS z2ui5_cl_cgui_salv_config DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES ty_t_row TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    TYPES:
      "! SALV_S_CELL
      BEGIN OF ty_s_cell,
        columnname TYPE c LENGTH 30,
        row        TYPE i,
        value      TYPE string,
      END OF ty_s_cell.
    TYPES:
      "! a function added - a button of the grid
      BEGIN OF ty_s_function,
        name    TYPE string,
        icon    TYPE string,
        text    TYPE string,
        tooltip TYPE string,
      END OF ty_s_function.
    TYPES ty_t_function TYPE STANDARD TABLE OF ty_s_function WITH EMPTY KEY.
    TYPES:
      "! a sort added - the initial sort of the grid, in this order
      BEGIN OF ty_s_sort,
        columnname TYPE string,
        descending TYPE abap_bool,
        subtotal   TYPE abap_bool,
      END OF ty_s_sort.
    TYPES ty_t_sort TYPE STANDARD TABLE OF ty_s_sort WITH EMPTY KEY.

    DATA mv_title          TYPE string READ-ONLY.
    DATA mv_striped        TYPE abap_bool READ-ONLY.
    DATA mv_selection_mode TYPE i READ-ONLY.
    DATA mt_function       TYPE ty_t_function READ-ONLY.
    DATA mt_sort           TYPE ty_t_sort READ-ONLY.
    "! the columns totalled - add_aggregation( ) with the total
    DATA mt_aggregation    TYPE string_table READ-ONLY.

    "! the grid of the table - z2ui5_cl_cgui_salv_table sets it at display( )
    METHODS set_grid
      IMPORTING
        grid TYPE REF TO z2ui5_cl_cgui_alv_grid.

    " cl_salv_display_settings
    METHODS set_list_header
      IMPORTING
        value TYPE clike.

    METHODS get_list_header
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_striped_pattern
      IMPORTING
        value TYPE abap_bool.

    METHODS set_horizontal_lines
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_vertical_lines
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_fit_column_to_table_size
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_list_header_size
      IMPORTING
        value TYPE any.

    " cl_salv_functions
    METHODS set_all
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_default
      IMPORTING
        value TYPE any DEFAULT abap_true.

    "! a button of the grid - a click raises added_function of the table
    METHODS add_function
      IMPORTING
        name     TYPE clike
        icon     TYPE clike OPTIONAL
        text     TYPE clike OPTIONAL
        tooltip  TYPE clike OPTIONAL
        position TYPE i     OPTIONAL.

    METHODS set_function
      IMPORTING
        name    TYPE clike
        boolean TYPE abap_bool DEFAULT abap_true.

    " cl_salv_selections
    METHODS set_selection_mode
      IMPORTING
        value TYPE i.

    METHODS get_selection_mode
      RETURNING
        VALUE(value) TYPE i.

    "! the rows the user picked in the grid - their index in the table
    METHODS get_selected_rows
      RETURNING
        VALUE(value) TYPE ty_t_row.

    METHODS set_selected_rows
      IMPORTING
        value TYPE ty_t_row.

    METHODS get_current_cell
      RETURNING
        VALUE(value) TYPE ty_s_cell.

    " cl_salv_sorts, cl_salv_aggregations, cl_salv_layout, cl_salv_print,
    " cl_salv_functional_settings
    METHODS add_sort
      IMPORTING
        columnname TYPE clike
        position   TYPE i         OPTIONAL
        sequence   TYPE i         OPTIONAL
        subtotal   TYPE abap_bool OPTIONAL
        group      TYPE any       OPTIONAL
        obligatory TYPE abap_bool OPTIONAL.

    METHODS add_aggregation
      IMPORTING
        columnname  TYPE clike
        aggregation TYPE i OPTIONAL.

    METHODS set_key
      IMPORTING
        value TYPE any.

    METHODS set_save_restriction
      IMPORTING
        value TYPE any OPTIONAL.

    METHODS set_initial_layout
      IMPORTING
        value TYPE clike.

    " cl_salv_tree_settings - the tree of z2ui5_cl_cgui_salv_tree
    DATA mv_header           TYPE string READ-ONLY.
    DATA mv_hierarchy_header TYPE string READ-ONLY.

    METHODS set_header
      IMPORTING
        value TYPE clike.

    METHODS set_hierarchy_header
      IMPORTING
        value TYPE clike.

    METHODS set_hierarchy_tooltip
      IMPORTING
        value TYPE clike.

    METHODS set_hierarchy_size
      IMPORTING
        value TYPE any.

    METHODS set_hierarchy_icon
      IMPORTING
        value TYPE any.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the object is kept with the report between
    " the roundtrips, and the transpiled runtime restores PROTECTED
    " attributes of the draft but not PRIVATE ones
    DATA mo_grid TYPE REF TO z2ui5_cl_cgui_alv_grid.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_config IMPLEMENTATION.

  METHOD set_grid.

    mo_grid = grid.

  ENDMETHOD.

  METHOD set_list_header.

    mv_title = value.

  ENDMETHOD.

  METHOD get_list_header.

    value = mv_title.

  ENDMETHOD.

  METHOD set_striped_pattern.

    mv_striped = value.

  ENDMETHOD.

  METHOD set_horizontal_lines ##NEEDED.
  ENDMETHOD.

  METHOD set_vertical_lines ##NEEDED.
  ENDMETHOD.

  METHOD set_fit_column_to_table_size ##NEEDED.
  ENDMETHOD.

  METHOD set_list_header_size ##NEEDED.
  ENDMETHOD.

  METHOD set_all ##NEEDED.
  ENDMETHOD.

  METHOD set_default ##NEEDED.
  ENDMETHOD.

  METHOD add_function.

    DATA(lv_name) = to_upper( condense( name ) ).
    DELETE mt_function WHERE name = lv_name.
    INSERT VALUE #( name    = lv_name
                    icon    = condense( icon )
                    text    = condense( text )
                    tooltip = condense( tooltip ) ) INTO TABLE mt_function.

  ENDMETHOD.

  METHOD set_function ##NEEDED.
  ENDMETHOD.

  METHOD set_selection_mode.

    mv_selection_mode = value.

  ENDMETHOD.

  METHOD get_selection_mode.

    value = mv_selection_mode.

  ENDMETHOD.

  METHOD get_selected_rows.

    DATA lt_index TYPE z2ui5_cl_cgui_alv=>ty_t_lvc_row.
    DATA lt_row_no TYPE z2ui5_cl_cgui_alv=>ty_t_lvc_roid.

    IF mo_grid IS NOT BOUND.
      RETURN.
    ENDIF.
    mo_grid->get_selected_rows( IMPORTING et_index_rows = lt_index
                                          et_row_no     = lt_row_no ).
    LOOP AT lt_index INTO DATA(ls_index).
      INSERT ls_index-index INTO TABLE value.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_selected_rows ##NEEDED.
  ENDMETHOD.

  METHOD get_current_cell ##NEEDED.
  ENDMETHOD.

  METHOD add_sort.

    DATA(lv_name) = to_upper( condense( columnname ) ).
    DELETE mt_sort WHERE columnname = lv_name.
    DATA(ls_sort) = VALUE ty_s_sort( columnname = lv_name
                                     descending = xsdbool( sequence = z2ui5_if_cgui_salv_c=>sort-sort_down )
                                     subtotal   = subtotal ).
    IF position > 0 AND position <= lines( mt_sort ).
      INSERT ls_sort INTO mt_sort INDEX position.
    ELSE.
      INSERT ls_sort INTO TABLE mt_sort.
    ENDIF.

  ENDMETHOD.

  METHOD add_aggregation.

    " the grid totals - a minimum, maximum or average has no counterpart
    IF aggregation IS NOT INITIAL AND aggregation <> z2ui5_if_cgui_salv_c=>aggregation-total.
      RETURN.
    ENDIF.
    DATA(lv_name) = to_upper( condense( columnname ) ).
    IF NOT line_exists( mt_aggregation[ table_line = lv_name ] ).
      INSERT lv_name INTO TABLE mt_aggregation.
    ENDIF.

  ENDMETHOD.

  METHOD set_key ##NEEDED.
  ENDMETHOD.

  METHOD set_save_restriction ##NEEDED.
  ENDMETHOD.

  METHOD set_initial_layout ##NEEDED.
  ENDMETHOD.

  METHOD set_header.

    mv_header = value.

  ENDMETHOD.

  METHOD set_hierarchy_header.

    mv_hierarchy_header = value.

  ENDMETHOD.

  METHOD set_hierarchy_tooltip ##NEEDED.
  ENDMETHOD.

  METHOD set_hierarchy_size ##NEEDED.
  ENDMETHOD.

  METHOD set_hierarchy_icon ##NEEDED.
  ENDMETHOD.

ENDCLASS.
