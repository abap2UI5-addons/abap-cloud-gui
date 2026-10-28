*&---------------------------------------------------------------------*
*& Report ZR2C_49_COLTREE
*&---------------------------------------------------------------------*
*& A column tree in the custom control area CC of screen 0100: the
*& airlines as folders, their connections below, the cities and the web
*& address of an airline in columns beside the tree. A click on a node
*& and a click on the address go to the handlers.
*&---------------------------------------------------------------------*
REPORT zr2c_49_coltree.

CLASS lcl_tree DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS display.
  PRIVATE SECTION.
    DATA tree TYPE REF TO cl_gui_column_tree.
    METHODS on_item_double_click FOR EVENT item_double_click OF cl_gui_column_tree
      IMPORTING node_key item_name.
    METHODS on_link_click FOR EVENT link_click OF cl_gui_column_tree
      IMPORTING node_key item_name.
ENDCLASS.

DATA go_tree TYPE REF TO lcl_tree.
DATA ok_code TYPE sy-ucomm.

CLASS lcl_tree IMPLEMENTATION.

  METHOD display.
    DATA lt_node TYPE treev_ntab.
    DATA ls_node TYPE treev_node.
    DATA lt_item TYPE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY.
    DATA ls_item TYPE mtreeitm.
    DATA ls_header TYPE treev_hhdr.
    DATA lt_carrier TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
    DATA lt_connection TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.

    ls_header-heading = 'Airline'.
    ls_header-width = 30.
    CREATE OBJECT tree
      EXPORTING
        parent                = NEW cl_gui_custom_container( container_name = 'CC' )
        node_selection_mode   = cl_gui_column_tree=>node_sel_mode_single
        item_selection        = abap_true
        hierarchy_column_name = 'TREE'
        hierarchy_header      = ls_header.
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
      ls_item-class = cl_gui_column_tree=>item_class_text.
      ls_item-text = ls_carrier-carrname.
      APPEND ls_item TO lt_item.
      ls_item-item_name = 'FROM'.
      ls_item-class = cl_gui_column_tree=>item_class_link.
      ls_item-text = ls_carrier-url.
      APPEND ls_item TO lt_item.
      LOOP AT lt_connection INTO DATA(ls_connection) WHERE carrid = ls_carrier-carrid.
        CLEAR ls_node.
        ls_node-node_key = |{ ls_connection-carrid }{ ls_connection-connid }|.
        ls_node-relatkey = ls_carrier-carrid.
        ls_node-relatship = cl_gui_column_tree=>relat_last_child.
        APPEND ls_node TO lt_node.
        CLEAR ls_item.
        ls_item-node_key = ls_node-node_key.
        ls_item-item_name = 'TREE'.
        ls_item-class = cl_gui_column_tree=>item_class_text.
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
      MESSAGE 'The tree could not be built' TYPE 'E'.
    ENDIF.
    tree->expand_node( 'LH' ).
    SET HANDLER on_item_double_click FOR tree.
    SET HANDLER on_link_click FOR tree.
  ENDMETHOD.

  METHOD on_item_double_click.
    MESSAGE |{ node_key } { item_name }| TYPE 'S'.
  ENDMETHOD.

  METHOD on_link_click.
    MESSAGE |Open { node_key } { item_name }| TYPE 'S'.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_tree IS INITIAL.
    go_tree = NEW lcl_tree( ).
    go_tree->display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
