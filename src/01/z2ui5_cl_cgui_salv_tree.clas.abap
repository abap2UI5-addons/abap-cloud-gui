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
    INTERFACES z2ui5_if_cgui_tree_handler.

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
        r_container           TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
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
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_columns.

    METHODS get_tree_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    "! the events of the tree - the tree itself
    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_tree.

    "! the ALV tree of the report the nodes go into
    METHODS get_tree
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_tree     TYPE REF TO z2ui5_cl_cgui_tree.
    DATA mo_nodes    TYPE REF TO z2ui5_cl_cgui_salv_nodes.
    DATA mo_columns  TYPE REF TO z2ui5_cl_cgui_salv_columns.
    DATA mo_settings TYPE REF TO z2ui5_cl_cgui_salv_settings.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_tree IMPLEMENTATION.

  METHOD factory.

    DATA lr_line TYPE REF TO data.

    r_salv_tree = NEW #( ).
    CREATE DATA lr_line LIKE LINE OF t_table.
    ASSIGN lr_line->* TO FIELD-SYMBOL(<line>).
    r_salv_tree->mo_columns = NEW #( <line> ).

  ENDMETHOD.

  METHOD constructor.

    super->constructor( ).
    " no part of the screen of its own - the tree of the report is
    add( VALUE #( kind   = z2ui5_if_cgui_gui=>cs_kind-salv
                  hidden = abap_true ) ).
    mo_settings = NEW #( ).
    DATA(lo_report) = z2ui5_cl_cgui_gui=>get_report( ).
    IF lo_report IS BOUND.
      mo_tree = lo_report->tree( ).
    ELSE.
      mo_tree = z2ui5_cl_cgui_tree=>factory( ).
    ENDIF.
    mo_nodes = NEW #( mo_tree ).

  ENDMETHOD.

  METHOD display.

    IF mo_settings->mv_header IS NOT INITIAL.
      mo_tree->set_title( mo_settings->mv_header ).
    ENDIF.
    IF mo_settings->mv_hierarchy_header IS NOT INITIAL.
      mo_tree->set_hierarchy_header( mo_settings->mv_hierarchy_header ).
    ENDIF.
    LOOP AT mo_columns->get( ) INTO DATA(ls_ref).
      DATA(lo_column) = ls_ref-r_column.
      DATA(lv_text) = COND string( WHEN lo_column->mv_long IS NOT INITIAL THEN lo_column->mv_long
                                   WHEN lo_column->mv_medium IS NOT INITIAL THEN lo_column->mv_medium
                                   ELSE lo_column->mv_short ).
      IF lv_text IS NOT INITIAL.
        mo_tree->set_column_text( name = lo_column->mv_name
                                  text = lv_text ).
      ENDIF.
      IF lo_column->mv_hidden = abap_true OR lo_column->mv_technical = abap_true.
        mo_tree->set_column_hidden( lo_column->mv_name ).
      ENDIF.
    ENDLOOP.
    LOOP AT mo_settings->mt_function INTO DATA(ls_function).
      mo_tree->add_function( name    = ls_function-name
                             text    = ls_function-text
                             icon    = ls_function-icon
                             tooltip = ls_function-tooltip ).
    ENDLOOP.
    DATA(lo_report) = z2ui5_cl_cgui_gui=>get_report( ).
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

  METHOD z2ui5_if_cgui_tree_handler~on_node.

    DATA lv_column TYPE ty_column.
    DATA(lv_key) = z2ui5_cl_cgui_salv_node=>to_key( key ).
    raise_event( event  = `DOUBLE_CLICK`
                 params = VALUE #( ( name = `NODE_KEY`   kind = cl_abap_objectdescr=>exporting value = REF #( lv_key ) )
                                   ( name = `COLUMNNAME` kind = cl_abap_objectdescr=>exporting value = REF #( lv_column ) ) ) ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_tree_handler~on_checkbox.

    DATA lv_column TYPE ty_column.
    DATA(lv_key) = z2ui5_cl_cgui_salv_node=>to_key( key ).
    DATA(lv_checked) = checked.
    raise_event( event  = `CHECKBOX_CHANGE`
                 params = VALUE #( ( name = `NODE_KEY`   kind = cl_abap_objectdescr=>exporting value = REF #( lv_key ) )
                                   ( name = `COLUMNNAME` kind = cl_abap_objectdescr=>exporting value = REF #( lv_column ) )
                                   ( name = `CHECKED`    kind = cl_abap_objectdescr=>exporting value = REF #( lv_checked ) ) ) ).

  ENDMETHOD.

ENDCLASS.
