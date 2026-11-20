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

    DATA lo_tree LIKE mo_tree.
    DATA temp1 TYPE string.
    DATA temp5 TYPE i.
    DATA temp7 TYPE i.
    DATA lv_related LIKE temp7.
    DATA temp2 TYPE i.
        DATA temp6 TYPE i.
    DATA lv_parent LIKE temp2.
    DATA temp3 TYPE string.
    DATA lv_icon LIKE temp3.
    DATA lv_folder TYPE abap_bool.
    DATA temp8 TYPE xsdboolean.
    DATA temp4 TYPE string.
    DATA lv_icon_ui5 LIKE temp4.
    DATA lv_key TYPE i.
    lo_tree = mo_tree.

    temp1 = related_node.

    temp5 = related_node.

    IF condense( temp1 ) CO `0123456789` AND related_node IS NOT INITIAL.
      temp7 = temp5.
    ELSE.
      CLEAR temp7.
    ENDIF.

    lv_related = temp7.
    " a child below the related node, a sibling below its parent

    CASE relationship.
      WHEN z2ui5_if_cgui_salv_c=>node_relation-first_child OR z2ui5_if_cgui_salv_c=>node_relation-last_child.
        temp2 = lv_related.
      WHEN OTHERS.

        IF lv_related IS NOT INITIAL.
          temp6 = lo_tree->get_parent( lv_related ).
        ELSE.
          CLEAR temp6.
        ENDIF.
        temp2 = temp6.
    ENDCASE.

    lv_parent = temp2.

    IF expanded_icon IS NOT INITIAL.
      temp3 = expanded_icon.
    ELSE.
      temp3 = collapsed_icon.
    ENDIF.

    lv_icon = temp3.


    temp8 = boolc( folder = abap_true OR expander = abap_true ).
    lv_folder = temp8.

    IF lv_icon CP `sap-icon://*`.
      temp4 = lv_icon.
    ELSE.
      CLEAR temp4.
    ENDIF.

    lv_icon_ui5 = temp4.
    " a folder has no data row - passed only when there is one

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
    CREATE OBJECT value EXPORTING tree = mo_tree key = lv_key.

  ENDMETHOD.

  METHOD get_node.

    DATA temp5 TYPE string.
    DATA lv_key TYPE string.
    DATA temp6 TYPE i.
    DATA temp7 TYPE i.
    temp5 = node_key.

    lv_key = condense( temp5 ).
    IF lv_key IS INITIAL OR lv_key CN `0123456789`.
      RETURN.
    ENDIF.

    temp6 = lv_key.
    IF mo_tree->get_node( temp6 )-key IS INITIAL.
      RETURN.
    ENDIF.

    temp7 = lv_key.
    CREATE OBJECT value EXPORTING tree = mo_tree key = temp7.

  ENDMETHOD.

  METHOD get_all_nodes.

    DATA temp8 TYPE z2ui5_cl_cgui_tree=>ty_t_node.
    DATA ls_node LIKE LINE OF temp8.
      DATA temp9 TYPE z2ui5_cl_cgui_salv_node=>ty_s_node_ref.
    temp8 = mo_tree->get_nodes( ).

    LOOP AT temp8 INTO ls_node.

      CLEAR temp9.
      temp9-key = z2ui5_cl_cgui_salv_node=>to_key( ls_node-key ).
      CREATE OBJECT temp9-node EXPORTING tree = mo_tree key = ls_node-key.
      INSERT temp9 INTO TABLE value.
    ENDLOOP.

  ENDMETHOD.

  METHOD expand_all.

    mo_tree->expand_all( ).

  ENDMETHOD.

  METHOD collapse_all.

    mo_tree->collapse_all( ).

  ENDMETHOD.

  METHOD delete_all.

    DATA temp10 TYPE z2ui5_cl_cgui_tree=>ty_t_node.
    DATA ls_node LIKE LINE OF temp10.
    temp10 = mo_tree->get_children( 0 ).

    LOOP AT temp10 INTO ls_node.
      mo_tree->delete_node( ls_node-key ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
