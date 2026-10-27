*&---------------------------------------------------------------------*
*& Report ZR2C_50_LISTTREE
*&---------------------------------------------------------------------*
*& A list tree in the custom control area CC of screen 0100: the
*& airlines as folders with their web address on the line, the
*& connections below with the cities after them. A click on a node and
*& a click on the address go to the handlers.
*&---------------------------------------------------------------------*
REPORT zr2c_50_listtree.

CLASS lcl_tree DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS display.
  PRIVATE SECTION.
    DATA tree TYPE REF TO cl_gui_list_tree.
    METHODS on_item_double_click FOR EVENT item_double_click OF cl_gui_list_tree
      IMPORTING node_key item_name.
    METHODS on_link_click FOR EVENT link_click OF cl_gui_list_tree
      IMPORTING node_key item_name.
ENDCLASS.

DATA go_tree TYPE REF TO lcl_tree.
DATA ok_code TYPE sy-ucomm.

CLASS lcl_tree IMPLEMENTATION.

  METHOD display.
    DATA lt_node TYPE treev_ntab.
    DATA lt_item TYPE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY.
    DATA lt_carrier TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
    DATA lt_connection TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.

    CREATE OBJECT tree
      EXPORTING
        parent              = NEW cl_gui_custom_container( container_name = 'CC' )
        node_selection_mode = cl_gui_list_tree=>node_sel_mode_single
        item_selection      = abap_true
        with_headers        = abap_false.

    SELECT * FROM scarr INTO TABLE @lt_carrier ORDER BY carrid.
    SELECT * FROM spfli INTO TABLE @lt_connection ORDER BY carrid, connid.
    LOOP AT lt_carrier INTO DATA(ls_carrier).
      APPEND VALUE #( node_key = ls_carrier-carrid isfolder = abap_true ) TO lt_node.
      APPEND VALUE #( node_key = ls_carrier-carrid item_name = '1' class = cl_gui_list_tree=>item_class_text
                      length = 20 text = ls_carrier-carrname ) TO lt_item.
      APPEND VALUE #( node_key = ls_carrier-carrid item_name = '2' class = cl_gui_list_tree=>item_class_link
                      length = 30 text = ls_carrier-url ) TO lt_item.
      LOOP AT lt_connection INTO DATA(ls_connection) WHERE carrid = ls_carrier-carrid.
        DATA(lv_key) = CONV tv_nodekey( |{ ls_connection-carrid }{ ls_connection-connid }| ).
        APPEND VALUE #( node_key = lv_key relatkey = ls_carrier-carrid
                        relatship = cl_gui_list_tree=>relat_last_child ) TO lt_node.
        APPEND VALUE #( node_key = lv_key item_name = '1' class = cl_gui_list_tree=>item_class_text
                        length = 10 text = ls_connection-connid ) TO lt_item.
        APPEND VALUE #( node_key = lv_key item_name = '2' class = cl_gui_list_tree=>item_class_text
                        length = 20 text = ls_connection-cityfrom ) TO lt_item.
        APPEND VALUE #( node_key = lv_key item_name = '3' class = cl_gui_list_tree=>item_class_text
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
    SET HANDLER on_item_double_click FOR tree.
    SET HANDLER on_link_click FOR tree.
  ENDMETHOD.

  METHOD on_item_double_click.
    MESSAGE |{ node_key } { item_name }| TYPE 'S'.
  ENDMETHOD.

  METHOD on_link_click.
    MESSAGE |Open { node_key }| TYPE 'S'.
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
