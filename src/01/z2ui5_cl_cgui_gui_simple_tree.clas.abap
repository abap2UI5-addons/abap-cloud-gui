"! The stand-in of cl_gui_simple_tree - a tree of nodes in its container.
"! add_nodes( ) takes the node table of the classic (MTREESNODE: node_key,
"! relatkey, relatship, isfolder, expander, n_image, text, ...), read by
"! the names of its fields; a node with expander gets its children with
"! the first expand - the event expand_no_children. A click on a node
"! selects it and raises selection_changed and node_double_click (the
"! browser has no double click on a link); get_selected_node( ) answers
"! with it. The nodes are kept with the control from one roundtrip to the
"! next, the report shows the branches that are expanded
CLASS z2ui5_cl_cgui_gui_simple_tree DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS node_sel_mode_single        TYPE i VALUE 0.
    CONSTANTS node_sel_mode_multiple      TYPE i VALUE 1.
    CONSTANTS relat_first_sibling         TYPE i VALUE 1.
    CONSTANTS relat_last_sibling          TYPE i VALUE 2.
    CONSTANTS relat_prev_sibling          TYPE i VALUE 3.
    CONSTANTS relat_next_sibling          TYPE i VALUE 4.
    CONSTANTS relat_first_child           TYPE i VALUE 5.
    CONSTANTS relat_last_child            TYPE i VALUE 6.
    CONSTANTS eventid_node_double_click   TYPE i VALUE 25.
    CONSTANTS eventid_expand_no_children  TYPE i VALUE 24.
    CONSTANTS eventid_selection_changed   TYPE i VALUE 26.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 27.

    TYPES ty_node_key TYPE c LENGTH 12.
    TYPES:
      "! a node - MTREESNODE of the classic; ABAP Cloud has not the DDIC type
      BEGIN OF ty_s_node,
        node_key   TYPE ty_node_key,
        relatkey   TYPE ty_node_key,
        relatship  TYPE i,
        hidden     TYPE abap_bool,
        disabled   TYPE abap_bool,
        isfolder   TYPE abap_bool,
        n_image    TYPE string,
        exp_image  TYPE string,
        style      TYPE i,
        last_hitem TYPE c LENGTH 12,
        no_branch  TYPE abap_bool,
        expander   TYPE abap_bool,
        dragdropid TYPE i,
        text       TYPE c LENGTH 72,
      END OF ty_s_node.
    TYPES ty_t_node TYPE STANDARD TABLE OF ty_s_node WITH DEFAULT KEY.
    TYPES:
      "! a column beside the tree - of the column tree; width in characters
      BEGIN OF ty_s_column,
        name  TYPE string,
        text  TYPE string,
        width TYPE i,
      END OF ty_s_column,
      ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH EMPTY KEY,
      "! what a node shows in a column - kind is text, link or checkbox;
      "! width in characters where no column gives it
      BEGIN OF ty_s_cell,
        name    TYPE string,
        text    TYPE string,
        kind    TYPE string,
        checked TYPE abap_bool,
        width   TYPE i,
      END OF ty_s_cell,
      ty_t_cell TYPE STANDARD TABLE OF ty_s_cell WITH EMPTY KEY.

    "! a click on a node
    EVENTS node_double_click
      EXPORTING
        VALUE(node_key) TYPE ty_node_key OPTIONAL.

    "! the first expand of a node with expander - add_nodes( ) its children
    EVENTS expand_no_children
      EXPORTING
        VALUE(node_key) TYPE ty_node_key OPTIONAL.

    "! a click on a node - the node selected
    EVENTS selection_changed
      EXPORTING
        VALUE(node_key) TYPE ty_node_key OPTIONAL.

    METHODS constructor
      IMPORTING
        parent              TYPE REF TO z2ui5_cl_cgui_gui_container
        node_selection_mode TYPE i         DEFAULT node_sel_mode_single
        hide_selection      TYPE abap_bool OPTIONAL
        lifetime            TYPE i         OPTIONAL
        shellstyle          TYPE i         OPTIONAL
        name                TYPE clike     OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        failed
        illegal_node_selection_mode.

    "! the nodes of node_table below their relatkey - a child (relatship
    "! first or last child) below it, a sibling beside it; the order of the
    "! siblings is the order they are added in
    METHODS add_nodes
      IMPORTING
        table_structure_name TYPE clike OPTIONAL
        node_table           TYPE STANDARD TABLE
      EXCEPTIONS
        failed
        error_in_node_table
        dp_error
        table_structure_name_not_found.

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS delete_node
      IMPORTING
        node_key TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    "! expand a node - expand_subtree its whole branch, expand_predecessors
    "! the nodes above it too
    METHODS expand_node
      IMPORTING
        node_key            TYPE clike
        level_count         TYPE i         OPTIONAL
        expand_predecessors TYPE abap_bool OPTIONAL
        expand_subtree      TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error
        node_not_found
        cannot_expand_leaf.

    METHODS expand_root_nodes
      IMPORTING
        level_count    TYPE i         OPTIONAL
        expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error.

    METHODS collapse_node
      IMPORTING
        node_key         TYPE clike
        collapse_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    METHODS collapse_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    "! the node selected - initial when none is
    METHODS get_selected_node
      CHANGING
        node_key TYPE any
      EXCEPTIONS
        failed
        single_node_selection_only
        cntl_system_error.

    METHODS set_selected_node
      IMPORTING
        node_key TYPE clike
      EXCEPTIONS
        failed
        single_node_selection_only
        node_not_found
        cntl_system_error.

    METHODS node_set_text
      IMPORTING
        node_key TYPE clike
        text     TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    METHODS set_registered_events
      IMPORTING
        events TYPE STANDARD TABLE
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    "! the rows the report shows - the root nodes, the children of an
    "! expanded node
    METHODS view
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_tree=>ty_t_view.

    "! the key of the row selected - the one of view( )
    METHODS selected
      RETURNING
        VALUE(result) TYPE i.

    "! the columns beside the tree, the first the one of the tree itself -
    "! none for the simple tree
    METHODS columns
      RETURNING
        VALUE(result) TYPE ty_t_column.

    "! what the node key of view( ) shows in the columns after the first
    METHODS cells
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE ty_t_cell.

    METHODS dispatch REDEFINITION.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_key,
        key      TYPE i,
        node_key TYPE ty_node_key,
      END OF ty_s_key.

    DATA mo_tree     TYPE REF TO z2ui5_cl_cgui_tree.
    DATA mt_key      TYPE STANDARD TABLE OF ty_s_key WITH EMPTY KEY.
    DATA mv_selected TYPE i.

    "! the key in the tree of a node key - 0 when there is none
    METHODS key_of
      IMPORTING
        node_key      TYPE clike
      RETURNING
        VALUE(result) TYPE i.

    METHODS node_key_of
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE ty_node_key.

    "! RAISE EVENT event EXPORTING node_key
    METHODS raise_node_event
      IMPORTING
        event TYPE string
        key   TYPE i.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_simple_tree IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).
    mo_tree = z2ui5_cl_cgui_tree=>factory( ).
    IF add( VALUE #( kind   = z2ui5_if_cgui_gui=>cs_kind-simple_tree
                     parent = id_of( parent ) ) ) = abap_false.
      RAISE failed.
    ENDIF.

  ENDMETHOD.

  METHOD add_nodes.

    DATA ls_node TYPE ty_s_node.

    LOOP AT node_table ASSIGNING FIELD-SYMBOL(<line>).
      MOVE-CORRESPONDING <line> TO ls_node.
      IF ls_node-node_key IS INITIAL OR ls_node-hidden = abap_true.
        CONTINUE.
      ENDIF.
      " a child below its relatkey, a sibling beside it
      DATA(lv_parent) = key_of( ls_node-relatkey ).
      IF lv_parent <> 0 AND ls_node-relatship <> relat_first_child AND ls_node-relatship <> relat_last_child
          AND ls_node-relatship <> 0.
        lv_parent = mo_tree->get_parent( lv_parent ).
      ENDIF.
      IF lv_parent <> 0 AND mo_tree->get_node( lv_parent )-lazy = abap_true.
        mo_tree->set_loaded( lv_parent ).
      ENDIF.
      DATA(lv_key) = mo_tree->add_node( parent = lv_parent
                                        text   = condense( ls_node-text )
                                        icon   = COND #( WHEN ls_node-n_image CP `sap-icon://*` THEN ls_node-n_image )
                                        folder = xsdbool( ls_node-isfolder = abap_true OR ls_node-expander = abap_true )
                                        lazy   = ls_node-expander ).
      DELETE mt_key WHERE node_key = ls_node-node_key.
      INSERT VALUE #( key      = lv_key
                      node_key = ls_node-node_key ) INTO TABLE mt_key.
    ENDLOOP.

  ENDMETHOD.

  METHOD delete_all_nodes.

    mo_tree = z2ui5_cl_cgui_tree=>factory( ).
    CLEAR: mt_key, mv_selected.

  ENDMETHOD.

  METHOD delete_node.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    mo_tree->delete_node( lv_key ).
    IF mv_selected = lv_key OR mo_tree->get_node( mv_selected ) IS INITIAL.
      CLEAR mv_selected.
    ENDIF.
    " the keys of the nodes gone with the branch
    LOOP AT mt_key INTO DATA(ls_key).
      IF mo_tree->get_node( ls_key-key ) IS INITIAL.
        DELETE mt_key WHERE key = ls_key-key.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD expand_node.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    mo_tree->expand( key = lv_key
                     all = expand_subtree ).
    IF expand_predecessors = abap_true.
      DATA(lv_parent) = mo_tree->get_parent( lv_key ).
      WHILE lv_parent <> 0.
        mo_tree->expand( lv_parent ).
        lv_parent = mo_tree->get_parent( lv_parent ).
      ENDWHILE.
    ENDIF.

  ENDMETHOD.

  METHOD expand_root_nodes.

    LOOP AT mo_tree->get_children( 0 ) INTO DATA(ls_root).
      mo_tree->expand( key = ls_root-key
                       all = expand_subtree ).
    ENDLOOP.

  ENDMETHOD.

  METHOD collapse_node.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    mo_tree->collapse( lv_key ).

  ENDMETHOD.

  METHOD collapse_all_nodes.

    mo_tree->collapse_all( ).

  ENDMETHOD.

  METHOD get_selected_node.

    CLEAR node_key.
    IF mv_selected <> 0.
      node_key = node_key_of( mv_selected ).
    ENDIF.

  ENDMETHOD.

  METHOD set_selected_node.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    mv_selected = lv_key.

  ENDMETHOD.

  METHOD node_set_text.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    mo_tree->set_node_text( key  = lv_key
                            text = text ).

  ENDMETHOD.

  METHOD set_registered_events ##NEEDED.
  ENDMETHOD.

  METHOD view.

    result = mo_tree->view( ).

  ENDMETHOD.

  METHOD selected.

    result = mv_selected.

  ENDMETHOD.

  METHOD columns ##NEEDED.
  ENDMETHOD.

  METHOD cells ##NEEDED.
  ENDMETHOD.

  METHOD dispatch.

    DATA(lv_value) = condense( value ).
    IF lv_value IS INITIAL OR lv_value CN `0123456789`.
      super->dispatch( event = event
                       value = value ).
      RETURN.
    ENDIF.
    DATA(lv_key) = CONV i( lv_value ).
    DATA(lv_event) = to_upper( event ).

    CASE lv_event.
      WHEN `EXPAND`.
        DATA(ls_node) = mo_tree->get_node( lv_key ).
        IF ls_node-expanded = abap_true AND mo_tree->has_children( lv_key ) = abap_true.
          mo_tree->collapse( lv_key ).
        ELSE.
          mo_tree->expand( lv_key ).
          " a node with expander: the handler adds its children now
          IF ls_node-lazy = abap_true AND mo_tree->has_children( lv_key ) = abap_false.
            mo_tree->set_loaded( lv_key ).
            raise_node_event( event = `EXPAND_NO_CHILDREN`
                              key   = lv_key ).
          ENDIF.
        ENDIF.
      WHEN `CLICK`.
        mv_selected = lv_key.
        raise_node_event( event = `SELECTION_CHANGED`
                          key   = lv_key ).
        raise_node_event( event = `NODE_DOUBLE_CLICK`
                          key   = lv_key ).
      WHEN OTHERS.
        super->dispatch( event = event
                         value = value ).
    ENDCASE.

  ENDMETHOD.

  METHOD key_of.

    DATA lv_node_key TYPE ty_node_key.

    lv_node_key = node_key.
    READ TABLE mt_key INTO DATA(ls_key) WITH KEY node_key = lv_node_key.
    IF sy-subrc = 0.
      result = ls_key-key.
    ENDIF.

  ENDMETHOD.

  METHOD node_key_of.

    READ TABLE mt_key INTO DATA(ls_key) WITH KEY key = key.
    IF sy-subrc = 0.
      result = ls_key-node_key.
    ENDIF.

  ENDMETHOD.

  METHOD raise_node_event.

    DATA(lv_node_key) = node_key_of( key ).
    raise_event( event  = event
                 params = VALUE #( ( name  = `NODE_KEY`
                                     kind  = cl_abap_objectdescr=>exporting
                                     value = REF #( lv_node_key ) ) ) ).

  ENDMETHOD.

ENDCLASS.
