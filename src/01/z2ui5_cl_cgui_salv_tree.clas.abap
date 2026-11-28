"! The stand-in of cl_salv_tree and cl_salv_events_tree - the tree of a
"! report that builds it with get_nodes( )->add_node( ) and shows it with
"! display( ): the nodes go into the ALV tree of the report (tree( )), the
"! columns of the table passed with their texts and hidden ones, the
"! header and the hierarchy header of get_tree_settings( ). A click on a
"! node raises double_click, a tick of a checkbox checkbox_change - for the
"! handlers SET HANDLER set for get_event( ), which is the tree itself
CLASS z2ui5_cl_cgui_salv_tree DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_tree_events.

    TYPES ty_node_key TYPE z2ui5_cl_cgui_salv_node=>ty_node_key.
    TYPES ty_column TYPE c LENGTH 30.
    TYPES ty_function TYPE c LENGTH 30.

    EVENTS double_click
      EXPORTING
        VALUE(node_key)   TYPE ty_node_key OPTIONAL
        VALUE(columnname) TYPE ty_column OPTIONAL.

    EVENTS link_click
      EXPORTING
        VALUE(node_key)   TYPE ty_node_key OPTIONAL
        VALUE(columnname) TYPE ty_column OPTIONAL.

    EVENTS checkbox_change
      EXPORTING
        VALUE(node_key)   TYPE ty_node_key OPTIONAL
        VALUE(columnname) TYPE ty_column OPTIONAL
        VALUE(checked)    TYPE abap_bool OPTIONAL.

    EVENTS added_function
      EXPORTING
        VALUE(e_salv_function) TYPE ty_function OPTIONAL.

    EVENTS expand_empty_folder
      EXPORTING
        VALUE(node_key) TYPE ty_node_key OPTIONAL.

    "! t_table: the line type decides the columns, the table stays empty -
    "! the rows are the data_row of add_node( )
    CLASS-METHODS factory
      IMPORTING
        r_container           TYPE REF TO z2ui5_cl_cgui_container OPTIONAL
        hide_selection_column TYPE abap_bool OPTIONAL
      EXPORTING
        r_salv_tree           TYPE REF TO z2ui5_cl_cgui_salv_tree
      CHANGING
        t_table               TYPE STANDARD TABLE.

    METHODS constructor.

    "! the tree shows - with the columns and the settings as they are now
    METHODS display.

    METHODS get_nodes
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_nodes.

    METHODS get_columns
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_cols.

    METHODS get_tree_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    "! the events of the tree - the tree itself
    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_tree.

    "! the ALV tree of the report the nodes go into
    METHODS get_tree
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! an expander node was opened the first time, without children - the
    "! report passes it on as EXPAND_EMPTY_FOLDER
    METHODS on_expand
      IMPORTING
        key TYPE i.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the object is kept with the report between
    " the roundtrips, and the transpiled runtime restores PROTECTED
    " attributes of the draft but not PRIVATE ones
    DATA mo_tree     TYPE REF TO z2ui5_cl_cgui_tree.
    DATA mo_nodes    TYPE REF TO z2ui5_cl_cgui_salv_nodes.
    DATA mo_columns  TYPE REF TO z2ui5_cl_cgui_salv_cols.
    DATA mo_settings TYPE REF TO z2ui5_cl_cgui_salv_config.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_tree IMPLEMENTATION.

  METHOD factory.

    DATA lr_line TYPE REF TO data.
    FIELD-SYMBOLS <line> TYPE data.

    CREATE OBJECT r_salv_tree.
    CREATE DATA lr_line LIKE LINE OF t_table.

    ASSIGN lr_line->* TO <line>.
    CREATE OBJECT r_salv_tree->mo_columns EXPORTING LINE = <line>.

  ENDMETHOD.

  METHOD constructor.
    DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA lo_report TYPE REF TO z2ui5_if_cgui_gui.

    super->constructor( ).
    " no part of the screen of its own - the tree of the report is

    CLEAR temp1.
    temp1-kind = z2ui5_if_cgui_gui=>cs_kind-salv.
    temp1-hidden = abap_true.
    add( temp1 ).
    CREATE OBJECT mo_settings.

    lo_report = z2ui5_cl_cgui_gui=>get_report( ).
    IF lo_report IS BOUND.
      mo_tree = lo_report->tree( ).
    ELSE.
      mo_tree = z2ui5_cl_cgui_tree=>factory( ).
    ENDIF.
    CREATE OBJECT mo_nodes EXPORTING TREE = mo_tree.

  ENDMETHOD.

  METHOD display.
    DATA temp2 TYPE z2ui5_cl_cgui_salv_cols=>ty_t_column_ref.
    DATA ls_ref LIKE LINE OF temp2.
      DATA lo_column LIKE ls_ref-r_column.
      DATA lv_text TYPE string.
    DATA ls_function LIKE LINE OF mo_settings->mt_function.
    DATA lo_report TYPE REF TO z2ui5_if_cgui_gui.

    IF mo_settings->mv_header IS NOT INITIAL.
      mo_tree->set_title( mo_settings->mv_header ).
    ENDIF.
    IF mo_settings->mv_hierarchy_header IS NOT INITIAL.
      mo_tree->set_hierarchy_header( mo_settings->mv_hierarchy_header ).
    ENDIF.

    temp2 = mo_columns->get( ).

    LOOP AT temp2 INTO ls_ref.

      lo_column = ls_ref-r_column.

      lv_text = lo_column->get_text( ).
      IF lv_text IS NOT INITIAL.
        mo_tree->set_column_text( name = lo_column->mv_name
                                  text = lv_text ).
      ENDIF.
      IF lo_column->mv_hidden = abap_true OR lo_column->mv_technical = abap_true.
        mo_tree->set_column_hidden( lo_column->mv_name ).
      ENDIF.
    ENDLOOP.

    LOOP AT mo_settings->mt_function INTO ls_function.
      mo_tree->add_function( name    = ls_function-name
                             text    = ls_function-text
                             icon    = ls_function-icon
                             tooltip = ls_function-tooltip ).
    ENDLOOP.

    lo_report = z2ui5_cl_cgui_gui=>get_report( ).
    IF lo_report IS BOUND.
      lo_report->tree_handler( me ).
    ENDIF.

  ENDMETHOD.

  METHOD get_nodes.

    value = mo_nodes.

  ENDMETHOD.

  METHOD get_columns.

    value = mo_columns.

  ENDMETHOD.

  METHOD get_tree_settings.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_functions.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_display_settings.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_aggregations.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_layout.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_selections.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_event.

    value = me.

  ENDMETHOD.

  METHOD get_tree.

    result = mo_tree.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_tree_events~on_node.

    DATA lv_column TYPE ty_column.
    DATA lv_key TYPE z2ui5_cl_cgui_salv_node=>ty_node_key.
    DATA temp3 LIKE REF TO lv_column.
DATA temp1 LIKE REF TO lv_key.
DATA temp2 TYPE abap_parmbind_tab.
DATA temp4 LIKE LINE OF temp2.
    lv_key = z2ui5_cl_cgui_salv_node=>to_key( key ).

    GET REFERENCE OF lv_column INTO temp3.

GET REFERENCE OF lv_key INTO temp1.

CLEAR temp2.

temp4-name = `NODE_KEY`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp1.
INSERT temp4 INTO TABLE temp2.
temp4-name = `COLUMNNAME`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp3.
INSERT temp4 INTO TABLE temp2.
raise_event( event  = `DOUBLE_CLICK`
                 params = temp2 ).

  ENDMETHOD.

  METHOD on_expand.

    DATA lv_key TYPE z2ui5_cl_cgui_salv_node=>ty_node_key.
    DATA temp4 LIKE REF TO lv_key.
DATA temp2 TYPE abap_parmbind_tab.
DATA temp3 LIKE LINE OF temp2.
    lv_key = z2ui5_cl_cgui_salv_node=>to_key( key ).

    GET REFERENCE OF lv_key INTO temp4.

CLEAR temp2.

temp3-name = `NODE_KEY`.
temp3-kind = cl_abap_objectdescr=>exporting.
temp3-value = temp4.
INSERT temp3 INTO TABLE temp2.
raise_event( event  = `EXPAND_EMPTY_FOLDER`
                 params = temp2 ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_tree_events~on_checkbox.

    DATA lv_column TYPE ty_column.
    DATA lv_key TYPE z2ui5_cl_cgui_salv_node=>ty_node_key.
    DATA lv_checked LIKE checked.
    DATA temp5 LIKE REF TO lv_checked.
DATA temp4 LIKE REF TO lv_column.
DATA temp6 LIKE REF TO lv_key.
DATA temp1 TYPE abap_parmbind_tab.
DATA temp2 LIKE LINE OF temp1.
    lv_key = z2ui5_cl_cgui_salv_node=>to_key( key ).

    lv_checked = checked.

    GET REFERENCE OF lv_checked INTO temp5.

GET REFERENCE OF lv_column INTO temp4.

GET REFERENCE OF lv_key INTO temp6.

CLEAR temp1.

temp2-name = `NODE_KEY`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp6.
INSERT temp2 INTO TABLE temp1.
temp2-name = `COLUMNNAME`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp4.
INSERT temp2 INTO TABLE temp1.
temp2-name = `CHECKED`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp5.
INSERT temp2 INTO TABLE temp1.
raise_event( event  = `CHECKBOX_CHANGE`
                 params = temp1 ).

  ENDMETHOD.

ENDCLASS.
