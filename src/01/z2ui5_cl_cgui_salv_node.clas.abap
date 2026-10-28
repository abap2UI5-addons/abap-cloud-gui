"! The stand-in of cl_salv_node and cl_salv_item - a node of
"! z2ui5_cl_cgui_salv_tree. get_item( ) answers the node itself: a
"! checkbox item ticks the node (the checkboxes of the tree switch on)
CLASS z2ui5_cl_cgui_salv_node DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    "! SALV_DE_NODE_KEY / LVC_NKEY
    TYPES ty_node_key TYPE c LENGTH 12.
    TYPES:
      "! SALV_S_NODES / SALV_T_NODES
      BEGIN OF ty_s_node_ref,
        key  TYPE ty_node_key,
        node TYPE REF TO z2ui5_cl_cgui_salv_node,
      END OF ty_s_node_ref.
    TYPES ty_t_node_ref TYPE STANDARD TABLE OF ty_s_node_ref WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        tree TYPE REF TO z2ui5_cl_cgui_tree
        key  TYPE i.

    CLASS-METHODS to_key
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE ty_node_key.

    METHODS get_key
      RETURNING
        VALUE(value) TYPE ty_node_key.

    METHODS get_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS set_text
      IMPORTING
        value TYPE clike.

    METHODS get_parent
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.

    METHODS get_first_child
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.

    METHODS get_next_sibling
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.

    METHODS get_children
      RETURNING
        VALUE(value) TYPE ty_t_node_ref.

    METHODS expand
      IMPORTING
        complete_subtree TYPE abap_bool OPTIONAL
        level            TYPE i OPTIONAL.

    METHODS collapse.

    METHODS delete.

    METHODS set_folder
      IMPORTING
        folder TYPE abap_bool DEFAULT abap_true.

    METHODS set_expander
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_collapsed_icon
      IMPORTING
        value TYPE clike.

    METHODS set_expanded_icon
      IMPORTING
        value TYPE clike.

    METHODS set_row_style
      IMPORTING
        value TYPE any.

    " cl_salv_item - the node itself
    METHODS get_item
      IMPORTING
        columnname   TYPE clike OPTIONAL
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.

    METHODS get_hierarchy_item
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.

    "! a checkbox item - the checkboxes of the tree, a tick raises
    "! checkbox_change
    METHODS set_type
      IMPORTING
        value TYPE i.

    METHODS set_checked
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_checked
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_editable
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_enabled
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_icon
      IMPORTING
        value TYPE clike.

    METHODS set_value
      IMPORTING
        value TYPE any.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_tree TYPE REF TO z2ui5_cl_cgui_tree.
    DATA mv_key  TYPE i.

    METHODS node_of
      IMPORTING
        key          TYPE i
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_node.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_node IMPLEMENTATION.

  METHOD constructor.

    mo_tree = tree.
    mv_key = key.

  ENDMETHOD.

  METHOD to_key.

    result = condense( CONV string( key ) ).

  ENDMETHOD.

  METHOD node_of.

    IF key IS NOT INITIAL.
      value = NEW #( tree = mo_tree
                     key  = key ).
    ENDIF.

  ENDMETHOD.

  METHOD get_key.

    value = to_key( mv_key ).

  ENDMETHOD.

  METHOD get_text.

    value = mo_tree->get_node( mv_key )-text.

  ENDMETHOD.

  METHOD set_text.

    mo_tree->set_node_text( key  = mv_key
                                              text = value ).

  ENDMETHOD.

  METHOD get_parent.

    value = node_of( mo_tree->get_parent( mv_key ) ).

  ENDMETHOD.

  METHOD get_first_child.

    DATA(lt_child) = mo_tree->get_children( mv_key ).
    IF lt_child IS NOT INITIAL.
      value = node_of( lt_child[ 1 ]-key ).
    ENDIF.

  ENDMETHOD.

  METHOD get_next_sibling.

    DATA(lo_tree) = mo_tree.
    DATA(lt_sibling) = lo_tree->get_children( lo_tree->get_parent( mv_key ) ).
    READ TABLE lt_sibling TRANSPORTING NO FIELDS WITH KEY key = mv_key.
    IF sy-subrc = 0 AND sy-tabix < lines( lt_sibling ).
      value = node_of( lt_sibling[ sy-tabix + 1 ]-key ).
    ENDIF.

  ENDMETHOD.

  METHOD get_children.

    LOOP AT mo_tree->get_children( mv_key ) INTO DATA(ls_node).
      INSERT VALUE #( key  = to_key( ls_node-key )
                      node = node_of( ls_node-key ) ) INTO TABLE value.
    ENDLOOP.

  ENDMETHOD.

  METHOD expand.

    mo_tree->expand( key = mv_key
                                       all = complete_subtree ).

  ENDMETHOD.

  METHOD collapse.

    mo_tree->collapse( mv_key ).

  ENDMETHOD.

  METHOD delete.

    mo_tree->delete_node( mv_key ).

  ENDMETHOD.

  METHOD set_folder ##NEEDED.
  ENDMETHOD.

  METHOD set_expander ##NEEDED.
  ENDMETHOD.

  METHOD set_collapsed_icon.

    IF value CP `sap-icon://*`.
      mo_tree->set_node_icon( key  = mv_key
                                                icon = value ).
    ENDIF.

  ENDMETHOD.

  METHOD set_expanded_icon.

    set_collapsed_icon( value ).

  ENDMETHOD.

  METHOD set_row_style ##NEEDED.
  ENDMETHOD.

  METHOD get_item.

    value = me.

  ENDMETHOD.

  METHOD get_hierarchy_item.

    value = me.

  ENDMETHOD.

  METHOD set_type.

    IF value = z2ui5_if_cgui_salv_c=>item_type-checkbox.
      mo_tree->set_checkboxes( event = abap_true ).
    ENDIF.

  ENDMETHOD.

  METHOD set_checked.

    mo_tree->set_checked( key = mv_key
                                            val = value ).

  ENDMETHOD.

  METHOD is_checked.

    value = mo_tree->get_node( mv_key )-checked.

  ENDMETHOD.

  METHOD set_editable ##NEEDED.
  ENDMETHOD.

  METHOD set_enabled ##NEEDED.
  ENDMETHOD.

  METHOD set_icon.

    set_collapsed_icon( value ).

  ENDMETHOD.

  METHOD set_value ##NEEDED.
  ENDMETHOD.

ENDCLASS.
