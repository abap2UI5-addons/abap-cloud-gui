"! The stand-in of cl_gui_list_tree - the tree of the column tree without
"! its columns: the items of a node (MTREEITM) follow each other on its
"! line, the first one is the text of the node, the others a text, a link
"! (item_class_link, link_click) or a checkbox (item_class_checkbox,
"! checkbox_change) of their length. A click on a node raises
"! selection_changed, node_double_click and item_double_click of its first
"! item
CLASS z2ui5_cl_cgui_gui_list_tree DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui_column_tree
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        parent              TYPE REF TO z2ui5_cl_cgui_gui_container
        node_selection_mode TYPE i         DEFAULT node_sel_mode_single
        item_selection      TYPE abap_bool OPTIONAL
        with_headers        TYPE abap_bool OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        lifetime            TYPE i         OPTIONAL
        shellstyle          TYPE i         OPTIONAL
        name                TYPE clike     OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        illegal_node_selection_mode
        failed.

    METHODS add_nodes_and_items REDEFINITION.
    METHODS columns             REDEFINITION.
    METHODS cells               REDEFINITION.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_first,
        node_key  TYPE ty_node_key,
        item_name TYPE ty_item_name,
      END OF ty_s_first.
    " the name of the first item of each node - kept between roundtrips
    DATA mt_first TYPE STANDARD TABLE OF ty_s_first WITH EMPTY KEY.

    METHODS hierarchy_item REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_list_tree IMPLEMENTATION.

  METHOD constructor.

    " the first item of a node is its text - the hierarchy column of the
    " column tree
    super->constructor( EXPORTING  parent                = parent
                                   node_selection_mode   = node_selection_mode
                                   hierarchy_column_name = '%FIRST'
                        EXCEPTIONS failed                = 1
                                   OTHERS                = 2 ).
    IF sy-subrc <> 0.
      RAISE failed.
    ENDIF.

  ENDMETHOD.

  METHOD add_nodes_and_items.

    DATA lt_item TYPE ty_t_item.
    DATA ls_item TYPE ty_s_item.

    " the first item of each node new here is the text of the node
    LOOP AT item_table ASSIGNING FIELD-SYMBOL(<line>).
      CLEAR ls_item.
      MOVE-CORRESPONDING <line> TO ls_item.
      IF ls_item-node_key IS NOT INITIAL AND ls_item-hidden = abap_false
          AND NOT line_exists( lt_item[ node_key = ls_item-node_key item_name = mv_hierarchy ] ).
        DELETE mt_first WHERE node_key = ls_item-node_key.
        INSERT VALUE #( node_key  = ls_item-node_key
                        item_name = to_upper( ls_item-item_name ) ) INTO TABLE mt_first.
        ls_item-item_name = mv_hierarchy.
      ENDIF.
      INSERT ls_item INTO TABLE lt_item.
    ENDLOOP.
    super->add_nodes_and_items( node_table = node_table
                                item_table = lt_item ).

  ENDMETHOD.

  METHOD hierarchy_item.

    READ TABLE mt_first INTO DATA(ls_first) WITH KEY node_key = node_key.
    result = COND #( WHEN sy-subrc = 0 THEN ls_first-item_name ELSE mv_hierarchy ).

  ENDMETHOD.

  METHOD columns ##NEEDED.
  ENDMETHOD.

  METHOD cells.

    DATA(lv_node_key) = node_key_of( key ).
    LOOP AT mt_item INTO DATA(ls_item) WHERE node_key = lv_node_key.
      INSERT cell_of( ls_item ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
