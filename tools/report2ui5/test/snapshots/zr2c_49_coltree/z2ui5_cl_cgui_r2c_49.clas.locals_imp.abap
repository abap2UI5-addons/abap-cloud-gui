" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_49.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_49 DEFINITION LOCAL FRIENDS lcl_tree.


CLASS lcl_tree IMPLEMENTATION.

  METHOD display.
    DATA lt_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_node.
    DATA ls_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_s_node.
    DATA lt_item TYPE STANDARD TABLE OF z2ui5_cl_cgui_gui_column_tree=>ty_s_item WITH DEFAULT KEY.
    DATA ls_item TYPE z2ui5_cl_cgui_gui_column_tree=>ty_s_item.
    DATA ls_header TYPE z2ui5_cl_cgui_gui_column_tree=>ty_s_hhdr.
    DATA lt_carrier TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
    DATA lt_connection TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.

    ls_header-heading = 'Airline'.
    ls_header-width = 30.
    tree = NEW #( parent                = NEW z2ui5_cl_cgui_gui_container( container_name = 'CC' )
                  node_selection_mode   = z2ui5_cl_cgui_gui_column_tree=>node_sel_mode_single
                  item_selection        = abap_true
                  hierarchy_column_name = 'TREE'
                  hierarchy_header      = ls_header ).
    tree->add_column( name = 'FROM' width = 20 header_text = 'From' ).
    tree->add_column( name = 'TO' width = 20 header_text = 'To' ).

    SELECT * FROM scarr INTO TABLE @lt_carrier ORDER BY carrid.
    SELECT * FROM spfli INTO TABLE @lt_connection ORDER BY carrid, connid.
    LOOP AT lt_carrier INTO DATA(ls_carrier).
      CLEAR ls_node.
      ls_node-node_key = ls_carrier-carrid.
      ls_node-isfolder = abap_true.
      APPEND ls_node TO lt_node.
      CLEAR ls_item.
      ls_item-node_key = ls_carrier-carrid.
      ls_item-item_name = 'TREE'.
      ls_item-class = z2ui5_cl_cgui_gui_column_tree=>item_class_text.
      ls_item-text = ls_carrier-carrname.
      APPEND ls_item TO lt_item.
      ls_item-item_name = 'FROM'.
      ls_item-class = z2ui5_cl_cgui_gui_column_tree=>item_class_link.
      ls_item-text = ls_carrier-url.
      APPEND ls_item TO lt_item.
      LOOP AT lt_connection INTO DATA(ls_connection) WHERE carrid = ls_carrier-carrid.
        CLEAR ls_node.
        ls_node-node_key = |{ ls_connection-carrid }{ ls_connection-connid }|.
        ls_node-relatkey = ls_carrier-carrid.
        ls_node-relatship = z2ui5_cl_cgui_gui_column_tree=>relat_last_child.
        APPEND ls_node TO lt_node.
        CLEAR ls_item.
        ls_item-node_key = ls_node-node_key.
        ls_item-item_name = 'TREE'.
        ls_item-class = z2ui5_cl_cgui_gui_column_tree=>item_class_text.
        ls_item-text = |{ ls_connection-carrid } { ls_connection-connid }|.
        APPEND ls_item TO lt_item.
        ls_item-item_name = 'FROM'.
        ls_item-text = ls_connection-cityfrom.
        APPEND ls_item TO lt_item.
        ls_item-item_name = 'TO'.
        ls_item-text = ls_connection-cityto.
        APPEND ls_item TO lt_item.
      ENDLOOP.
    ENDLOOP.
    tree->add_nodes_and_items(
      EXPORTING
        node_table                = lt_node
        item_table                = lt_item
        item_table_structure_name = 'MTREEITM'
      EXCEPTIONS
        failed                    = 1
        OTHERS                    = 2 ).
    IF sy-subrc <> 0.
      lcl_r2c=>app->message( text = 'The tree could not be built'
               type = `E` ).
      RETURN.
    ENDIF.
    tree->expand_node( 'LH' ).
    tree->set_handler( handler = me
                       method  = `ON_ITEM_DOUBLE_CLICK`
                       event   = `ITEM_DOUBLE_CLICK` ).
    tree->set_handler( handler = me
                       method  = `ON_LINK_CLICK`
                       event   = `LINK_CLICK` ).
  ENDMETHOD.

  METHOD on_item_double_click.
    lcl_r2c=>app->message( |{ node_key } { item_name }| ).
  ENDMETHOD.

  METHOD on_link_click.
    lcl_r2c=>app->message( |Open { node_key } { item_name }| ).
  ENDMETHOD.

ENDCLASS.
