"! The constants of the SALV interfaces in one - report2cloud writes
"! z2ui5_if_cgui_salv_c=>selection_mode-row_column for
"! if_salv_c_selection_mode=>row_column, and the same for
"! if_salv_c_function_position, if_salv_c_cell_type, if_salv_c_alignment,
"! if_salv_c_sort, if_salv_c_aggregation, if_salv_c_node_relation and
"! if_salv_c_item_type
INTERFACE z2ui5_if_cgui_salv_c PUBLIC.

  CONSTANTS:
    BEGIN OF selection_mode,
      none       TYPE i VALUE 0,
      single     TYPE i VALUE 1,
      multiple   TYPE i VALUE 2,
      cell       TYPE i VALUE 3,
      row_column TYPE i VALUE 4,
    END OF selection_mode.

  CONSTANTS:
    BEGIN OF function_position,
      left_of_salv_functions  TYPE i VALUE 1,
      right_of_salv_functions TYPE i VALUE 2,
    END OF function_position.

  CONSTANTS:
    BEGIN OF cell_type,
      text             TYPE i VALUE 0,
      checkbox         TYPE i VALUE 1,
      button           TYPE i VALUE 2,
      dropdown         TYPE i VALUE 3,
      link             TYPE i VALUE 4,
      hotspot          TYPE i VALUE 5,
      checkbox_hotspot TYPE i VALUE 6,
    END OF cell_type.

  CONSTANTS:
    BEGIN OF alignment,
      left     TYPE i VALUE 1,
      right    TYPE i VALUE 2,
      centered TYPE i VALUE 3,
    END OF alignment.

  CONSTANTS:
    BEGIN OF sort,
      sort_none TYPE i VALUE 0,
      sort_up   TYPE i VALUE 1,
      sort_down TYPE i VALUE 2,
    END OF sort.

  CONSTANTS:
    BEGIN OF aggregation,
      none    TYPE i VALUE 0,
      total   TYPE i VALUE 1,
      minimum TYPE i VALUE 2,
      maximum TYPE i VALUE 3,
      average TYPE i VALUE 4,
    END OF aggregation.

  " if_salv_c_node_relation - and the relat_* of cl_gui_column_tree
  CONSTANTS:
    BEGIN OF node_relation,
      first_sibling TYPE i VALUE 1,
      last_sibling  TYPE i VALUE 2,
      prev_sibling  TYPE i VALUE 3,
      next_sibling  TYPE i VALUE 4,
      first_child   TYPE i VALUE 5,
      last_child    TYPE i VALUE 6,
    END OF node_relation.

  " if_salv_c_item_type
  CONSTANTS:
    BEGIN OF item_type,
      text     TYPE i VALUE 0,
      checkbox TYPE i VALUE 3,
      button   TYPE i VALUE 4,
      link     TYPE i VALUE 5,
    END OF item_type.

ENDINTERFACE.
