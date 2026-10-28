"! The stand-in of cl_salv_nodes - the nodes of z2ui5_cl_cgui_salv_tree in
"! the ALV tree of the report. relationship is that of
"! if_salv_c_node_relation / cl_gui_column_tree: a child below related_node,
"! a sibling beside it (a new node comes last among its siblings)
CLASS z2ui5_cl_cgui_salv_nodes DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    METHODS constructor
      IMPORTING
        tree TYPE REF TO z2ui5_cl_cgui_tree.

    "! the new node - data_row the cells of its columns, text the text of
    "! the hierarchy column
    METHODS add_node
      IMPORTING
        related_node   TYPE clike OPTIONAL
        relationship   TYPE i DEFAULT z2ui5_if_cgui_salv_c=>node_relation-last_child
        data_row       TYPE any OPTIONAL
        collapsed_icon TYPE clike OPTIONAL
        expanded_icon  TYPE clike OPTIONAL
        row_style      TYPE any OPTIONAL
        text           TYPE clike OPTIONAL
        visible        TYPE abap_bool DEFAULT abap_true
        expander       TYPE abap_bool OPTIONAL
        enabled        TYPE abap_bool DEFAULT abap_true
        folder         TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(value)   TYPE REF TO z2ui5_cl_cgui_salv_node.

    METHODS get_node
      IMPORTING
        node_key     TYPE clike
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.

    "! the nodes, in the order of the tree
    METHODS get_all_nodes
      RETURNING
        VALUE(value) TYPE z2ui5_cl_cgui_salv_node=>ty_t_node_ref.

    METHODS expand_all.

    METHODS collapse_all.

    METHODS delete_all.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_tree TYPE REF TO z2ui5_cl_cgui_tree.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_nodes IMPLEMENTATION.

  METHOD constructor.

    mo_tree = tree.

  ENDMETHOD.

  METHOD add_node.

    DATA(lo_tree) = mo_tree.
    DATA(lv_related) = COND i( WHEN condense( CONV string( related_node ) ) CO `0123456789` AND related_node IS NOT INITIAL
                               THEN CONV i( related_node ) ).
    " a child below the related node, a sibling below its parent
    DATA(lv_parent) = SWITCH i( relationship
                                WHEN z2ui5_if_cgui_salv_c=>node_relation-first_child
                                  OR z2ui5_if_cgui_salv_c=>node_relation-last_child THEN lv_related
                                ELSE COND #( WHEN lv_related IS NOT INITIAL THEN lo_tree->get_parent( lv_related ) ) ).
    DATA(lv_icon) = COND string( WHEN expanded_icon IS NOT INITIAL THEN expanded_icon ELSE collapsed_icon ).
    DATA(lv_folder) = xsdbool( folder = abap_true OR expander = abap_true ).
    DATA(lv_icon_ui5) = COND string( WHEN lv_icon CP `sap-icon://*` THEN lv_icon ).
    " a folder has no data row - passed only when there is one
    DATA lv_key TYPE i.
    IF data_row IS SUPPLIED.
      lv_key = lo_tree->add_node( parent = lv_parent
                                  text   = text
                                  data   = data_row
                                  icon   = lv_icon_ui5
                                  folder = lv_folder ).
    ELSE.
      lv_key = lo_tree->add_node( parent = lv_parent
                                  text   = text
                                  icon   = lv_icon_ui5
                                  folder = lv_folder ).
    ENDIF.
    value = NEW #( tree = mo_tree
                   key  = lv_key ).

  ENDMETHOD.

  METHOD get_node.

    DATA(lv_key) = condense( CONV string( node_key ) ).
    IF lv_key IS INITIAL OR lv_key CN `0123456789`.
      RETURN.
    ENDIF.
    IF mo_tree->get_node( CONV i( lv_key ) )-key IS INITIAL.
      RETURN.
    ENDIF.
    value = NEW #( tree = mo_tree
                   key  = CONV i( lv_key ) ).

  ENDMETHOD.

  METHOD get_all_nodes.

    LOOP AT mo_tree->get_nodes( ) INTO DATA(ls_node).
      INSERT VALUE #( key  = z2ui5_cl_cgui_salv_node=>to_key( ls_node-key )
                      node = NEW #( tree = mo_tree
                                    key  = ls_node-key ) ) INTO TABLE value.
    ENDLOOP.

  ENDMETHOD.

  METHOD expand_all.

    mo_tree->expand_all( ).

  ENDMETHOD.

  METHOD collapse_all.

    mo_tree->collapse_all( ).

  ENDMETHOD.

  METHOD delete_all.

    LOOP AT mo_tree->get_children( 0 ) INTO DATA(ls_node).
      mo_tree->delete_node( ls_node-key ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
