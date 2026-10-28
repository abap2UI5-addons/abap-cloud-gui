" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_50.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_50 DEFINITION LOCAL FRIENDS lcl_tree.


CLASS lcl_tree IMPLEMENTATION.

  METHOD display.
    DATA lt_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_node.
    DATA lt_item TYPE STANDARD TABLE OF z2ui5_cl_cgui_gui_column_tree=>ty_s_item WITH DEFAULT KEY.
    DATA lt_carrier TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
    DATA lt_connection TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.

    tree = NEW #( parent              = NEW z2ui5_cl_cgui_gui_container( container_name = 'CC' )
                  node_selection_mode = z2ui5_cl_cgui_gui_list_tree=>node_sel_mode_single
                  item_selection      = abap_true
                  with_headers        = abap_false ).

    SELECT * FROM scarr INTO TABLE @lt_carrier ORDER BY carrid.
    SELECT * FROM spfli INTO TABLE @lt_connection ORDER BY carrid, connid.
    LOOP AT lt_carrier INTO DATA(ls_carrier).
      APPEND VALUE #( node_key = ls_carrier-carrid isfolder = abap_true ) TO lt_node.
      APPEND VALUE #( node_key = ls_carrier-carrid item_name = '1' class = z2ui5_cl_cgui_gui_list_tree=>item_class_text
                      length = 20 text = ls_carrier-carrname ) TO lt_item.
      APPEND VALUE #( node_key = ls_carrier-carrid item_name = '2' class = z2ui5_cl_cgui_gui_list_tree=>item_class_link
                      length = 30 text = ls_carrier-url ) TO lt_item.
      LOOP AT lt_connection INTO DATA(ls_connection) WHERE carrid = ls_carrier-carrid.
        DATA(lv_key) = CONV z2ui5_cl_cgui_gui_simple_tree=>ty_node_key( |{ ls_connection-carrid }{ ls_connection-connid }| ).
        APPEND VALUE #( node_key = lv_key relatkey = ls_carrier-carrid
                        relatship = z2ui5_cl_cgui_gui_list_tree=>relat_last_child ) TO lt_node.
        APPEND VALUE #( node_key = lv_key item_name = '1' class = z2ui5_cl_cgui_gui_list_tree=>item_class_text
                        length = 10 text = ls_connection-connid ) TO lt_item.
        APPEND VALUE #( node_key = lv_key item_name = '2' class = z2ui5_cl_cgui_gui_list_tree=>item_class_text
                        length = 20 text = ls_connection-cityfrom ) TO lt_item.
        APPEND VALUE #( node_key = lv_key item_name = '3' class = z2ui5_cl_cgui_gui_list_tree=>item_class_text
                        length = 20 text = ls_connection-cityto ) TO lt_item.
      ENDLOOP.
    ENDLOOP.
    tree->add_nodes_and_items(
      EXPORTING
        node_table                = lt_node
        item_table                = lt_item
        item_table_structure_name = 'MTREEITM'
      EXCEPTIONS
        OTHERS                    = 1 ).
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
    lcl_r2c=>app->message( |Open { node_key }| ).
  ENDMETHOD.

ENDCLASS.
