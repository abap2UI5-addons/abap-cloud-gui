"! cloud gui - ALV tree: a hierarchy of nodes with columns, as CL_SALV_TREE
"! and CL_GUI_ALV_TREE. A report shows it with tree( ) in
"! start_of_selection( ), a click on the text of a node raises
"! at_tree_node( ). Every node carries the cells of its data row; the first
"! data row passed decides the columns (at most cv_max_columns)
CLASS z2ui5_cl_cgui_tree DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    " kept in the draft of abap2UI5 between two roundtrips
    INTERFACES if_serializable_object.

    CONSTANTS:
      BEGIN OF cs_event,
        toggle       TYPE string VALUE `CGUI_TREE_TOGGLE`,
        node         TYPE string VALUE `CGUI_TREE_NODE`,
        expand_all   TYPE string VALUE `CGUI_TREE_EXPAND_ALL`,
        collapse_all TYPE string VALUE `CGUI_TREE_COLLAPSE_ALL`,
        checkbox     TYPE string VALUE `CGUI_TREE_CHECKBOX`,
      END OF cs_event.

    CONSTANTS cv_max_columns TYPE i VALUE 12.

    TYPES:
      BEGIN OF ty_s_node,
        key      TYPE i,
        parent   TYPE i,
        text     TYPE string,
        icon     TYPE string,
        folder   TYPE abap_bool,
        expanded TYPE abap_bool,
        checked  TYPE abap_bool,
        " children come with the first expand - EXPAND_NO_CHILDREN
        lazy     TYPE abap_bool,
        " what the report keeps for the node - a key of its own data
        value    TYPE string,
        cells    TYPE string_table,
      END OF ty_s_node.
    TYPES ty_t_node TYPE STANDARD TABLE OF ty_s_node WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_column,
        name   TYPE string,
        text   TYPE string,
        align  TYPE string,
        hidden TYPE abap_bool,
      END OF ty_s_column.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH DEFAULT KEY.

    TYPES:
      "! a row the browser shows - the nodes of the expanded branches
      BEGIN OF ty_s_view,
        key      TYPE i,
        level    TYPE i,
        indent   TYPE string,
        expander TYPE string,
        text     TYPE string,
        icon     TYPE string,
        checked  TYPE abap_bool,
        c01      TYPE string,
        c02      TYPE string,
        c03      TYPE string,
        c04      TYPE string,
        c05      TYPE string,
        c06      TYPE string,
        c07      TYPE string,
        c08      TYPE string,
        c09      TYPE string,
        c10      TYPE string,
        c11      TYPE string,
        c12      TYPE string,
      END OF ty_s_view.
    TYPES ty_t_view TYPE STANDARD TABLE OF ty_s_view WITH DEFAULT KEY.

    TYPES ty_t_key TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    CLASS-METHODS factory
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! a node below parent (0: a root node) - the key of the new node. data:
    "! the data row of its columns; folder: a node shown as folder although
    "! it has no children (yet)
    METHODS add_node
      IMPORTING
        parent        TYPE i DEFAULT 0
        text          TYPE clike
        data          TYPE any OPTIONAL
        icon          TYPE clike OPTIONAL
        folder        TYPE abap_bool DEFAULT abap_false
        expanded      TYPE abap_bool DEFAULT abap_false
        value         TYPE clike OPTIONAL
        lazy          TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE i.

    "! a node and its whole branch
    METHODS delete_node
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS set_node_text
      IMPORTING
        key           TYPE i
        text          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS set_node_icon
      IMPORTING
        key           TYPE i
        icon          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! the parent of a node - 0 for a root node
    METHODS get_parent
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE i.

    "! the parent of a node added related to the node related -
    "! relationship as z2ui5_if_cgui_salv_c=>node_relation (the relat_* of
    "! the classic trees): a child below it, a sibling beside it; 0 without
    "! a related node
    METHODS parent_of_related
      IMPORTING
        related       TYPE i
        relationship  TYPE i
      RETURNING
        VALUE(result) TYPE i.

    "! open a closed node, close an open one with children - abap_true when
    "! it was a lazy node opened the first time, without children: it counts
    "! as loaded now, its children are the caller's to add
    METHODS toggle
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! a lazy node was opened and has no children yet - its key, once: the
    "! report loads the children (at_tree_expand_no_children)
    METHODS take_expand_request
      RETURNING
        VALUE(result) TYPE i.

    "! the lazy nodes still without children - for a run without browser,
    "! which loads them all (background, print)
    METHODS get_lazy_nodes
      RETURNING
        VALUE(result) TYPE ty_t_key.

    "! a lazy node got its children - it is a normal node now
    METHODS set_loaded
      IMPORTING
        key TYPE i.

    METHODS get_node
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_node.

    METHODS get_nodes
      RETURNING
        VALUE(result) TYPE ty_t_node.

    "! the children of a node - of 0 the root nodes
    METHODS get_children
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE ty_t_node.

    METHODS has_children
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! expand a node - with all = abap_true its whole branch
    METHODS expand
      IMPORTING
        key           TYPE i
        all           TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS collapse
      IMPORTING
        key           TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS expand_all
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS collapse_all
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS set_title
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! the heading of the column with the hierarchy
    METHODS set_hierarchy_header
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS set_column_text
      IMPORTING
        name          TYPE clike
        text          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS set_column_hidden
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS get_columns
      RETURNING
        VALUE(result) TYPE ty_t_column.

    "! a checkbox in front of every node - the classic item checkbox of
    "! CL_SALV_TREE. What is ticked arrives with the next roundtrip
    METHODS set_checkboxes
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
        " a tick raises a roundtrip - at_tree_checkbox( ) of the report
        event         TYPE abap_bool DEFAULT abap_false
        " a tick on a node ticks its whole branch
        branch        TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! tick a node - with all = abap_true its whole branch
    METHODS set_checked
      IMPORTING
        key           TYPE i
        val           TYPE abap_bool DEFAULT abap_true
        all           TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! the keys of the ticked nodes, in the order they were added
    METHODS get_checked
      RETURNING
        VALUE(result) TYPE ty_t_key.

    "! a button of its own in the toolbar - its name arrives as ucomm in
    "! at_user_command( ), as the functions of the ALV
    METHODS add_function
      IMPORTING
        name          TYPE clike
        text          TYPE clike OPTIONAL
        icon          TYPE clike OPTIONAL
        tooltip       TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! what the browser changed in the rows shown - the ticks - back into
    "! the nodes
    METHODS sync
      IMPORTING
        view TYPE ty_t_view.

    "! the rows shown: every root node, the children of an expanded node
    METHODS view
      RETURNING
        VALUE(result) TYPE ty_t_view.

    "! the tree into node - view is the result of view( ), an attribute of
    "! the app so the table can bind it
    "! view - the rows of view( ), an attribute of the app (bound by
    "! reference); rows_bind - its binding, when the app binds it itself
    METHODS render
      IMPORTING
        node      TYPE REF TO z2ui5_cl_ui5_view_builder
        client    TYPE REF TO z2ui5_if_client
        view      TYPE ty_t_view
        rows_bind TYPE string OPTIONAL.

    "! expand / collapse - abap_true when the event was one of the tree;
    "! cs_event-node is left to the report
    METHODS handle_event
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the key of the node an event of the tree came from
    CLASS-METHODS get_node_by_event
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE i.

    "! the rows shown as text - for printing and the background
    METHODS to_text
      RETURNING
        VALUE(result) TYPE string_table.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the object is kept with the report between
    " the roundtrips, and the transpiled runtime restores PROTECTED
    " attributes of the draft but not PRIVATE ones
    DATA mt_node   TYPE ty_t_node.
    DATA mt_column TYPE ty_t_column.
    DATA mv_title  TYPE string.
    DATA mv_header TYPE string.
    DATA mv_next   TYPE i.
    DATA mv_checkbox TYPE abap_bool.
    DATA mv_check_event  TYPE abap_bool.
    DATA mv_check_branch TYPE abap_bool.
    DATA mv_expand_request TYPE i.
    DATA mt_function TYPE z2ui5_cl_cgui_alv=>ty_t_function.

  PRIVATE SECTION.

    " the number of a cell column, C01 ... C99
    TYPES ty_cell_no TYPE n LENGTH 2.

    METHODS columns_from
      IMPORTING
        data TYPE any.

    METHODS cells_of
      IMPORTING
        data          TYPE any
      RETURNING
        VALUE(result) TYPE string_table.

    " the children of every node, by the row of mt_node - built once per
    " view( ): a scan of all nodes per node grew with the square of a large
    " tree
    TYPES:
      BEGIN OF ty_s_child,
        parent TYPE i,
        row    TYPE i,
      END OF ty_s_child.
    TYPES ty_t_child TYPE SORTED TABLE OF ty_s_child WITH NON-UNIQUE KEY parent row.
    TYPES:
      BEGIN OF ty_s_key_row,
        key TYPE i,
        row TYPE i,
      END OF ty_s_key_row.

    METHODS view_add
      IMPORTING
        parent   TYPE i
        level    TYPE i
        children TYPE ty_t_child
      CHANGING
        rows     TYPE ty_t_view.

    METHODS expand_branch
      IMPORTING
        key TYPE i
        val TYPE abap_bool.

    METHODS check_branch
      IMPORTING
        key TYPE i
        val TYPE abap_bool.

ENDCLASS.



CLASS z2ui5_cl_cgui_tree IMPLEMENTATION.

  METHOD factory.

    CREATE OBJECT result.

  ENDMETHOD.

  METHOD add_node.
    DATA temp56 TYPE ty_s_node.
    DATA ls_node LIKE temp56.

    mv_next = mv_next + 1.

    CLEAR temp56.
    temp56-key = mv_next.
    temp56-parent = parent.
    temp56-text = text.
    temp56-icon = icon.
    temp56-folder = folder.
    temp56-expanded = expanded.
    temp56-value = value.
    temp56-lazy = lazy.

    ls_node = temp56.
    IF data IS SUPPLIED.
      IF mt_column IS INITIAL.
        columns_from( data ).
      ENDIF.
      ls_node-cells = cells_of( data ).
    ENDIF.
    INSERT ls_node INTO TABLE mt_node.
    result = mv_next.

  ENDMETHOD.

  METHOD delete_node.

    " the children first - collected, the table changes while they go
    DATA lt_child TYPE z2ui5_cl_cgui_tree=>ty_t_node.
    DATA ls_child LIKE LINE OF lt_child.
    lt_child = get_children( key ).

    LOOP AT lt_child INTO ls_child.
      delete_node( ls_child-key ).
    ENDLOOP.
    DELETE mt_node WHERE key = key.
    result = me.

  ENDMETHOD.

  METHOD set_node_text.

    DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.
    READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
    IF sy-subrc = 0.
      lr_node->text = text.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD set_node_icon.

    DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.
    READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
    IF sy-subrc = 0.
      lr_node->icon = icon.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD get_parent.

    DATA temp57 TYPE i.
    DATA temp58 TYPE z2ui5_cl_cgui_tree=>ty_s_node.
    CLEAR temp57.

    READ TABLE mt_node INTO temp58 WITH KEY key = key.
    IF sy-subrc = 0.
      temp57 = temp58-parent.
    ENDIF.
    result = temp57.

  ENDMETHOD.

  METHOD take_expand_request.

    result = mv_expand_request.
    CLEAR mv_expand_request.

  ENDMETHOD.

  METHOD get_lazy_nodes.

    DATA ls_node LIKE LINE OF mt_node.
    LOOP AT mt_node INTO ls_node WHERE lazy = abap_true.
      IF has_children( ls_node-key ) = abap_false.
        INSERT ls_node-key INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_loaded.

    DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.
    READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
    IF sy-subrc = 0.
      lr_node->lazy = abap_false.
      lr_node->folder = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD get_node.

    READ TABLE mt_node INTO result WITH KEY key = key.

  ENDMETHOD.

  METHOD get_nodes.

    result = mt_node.

  ENDMETHOD.

  METHOD get_children.

    DATA ls_node LIKE LINE OF mt_node.
    LOOP AT mt_node INTO ls_node WHERE parent = key.
      INSERT ls_node INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD has_children.

    DATA temp59 LIKE sy-subrc.
    DATA temp1 TYPE xsdboolean.
    READ TABLE mt_node WITH KEY parent = key TRANSPORTING NO FIELDS.
    temp59 = sy-subrc.

    temp1 = boolc( temp59 = 0 ).
    result = temp1.

  ENDMETHOD.

  METHOD expand.
      DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.

    IF all = abap_true.
      expand_branch( key = key
                     val = abap_true ).
    ELSE.

      READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
      IF sy-subrc = 0.
        lr_node->expanded = abap_true.
      ENDIF.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD collapse.

    DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.
    READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
    IF sy-subrc = 0.
      lr_node->expanded = abap_false.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD expand_all.

    DATA temp60 LIKE LINE OF mt_node.
    DATA lr_node LIKE REF TO temp60.
    LOOP AT mt_node REFERENCE INTO lr_node.
      lr_node->expanded = abap_true.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD collapse_all.

    DATA temp61 LIKE LINE OF mt_node.
    DATA lr_node LIKE REF TO temp61.
    LOOP AT mt_node REFERENCE INTO lr_node.
      lr_node->expanded = abap_false.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD expand_branch.

    DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.
    DATA ls_child LIKE LINE OF mt_node.
    READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
    IF sy-subrc = 0.
      lr_node->expanded = val.
    ENDIF.

    LOOP AT mt_node INTO ls_child WHERE parent = key.
      expand_branch( key = ls_child-key
                     val = val ).
    ENDLOOP.

  ENDMETHOD.

  METHOD set_checkboxes.

    mv_checkbox = val.
    mv_check_event = event.
    mv_check_branch = branch.
    result = me.

  ENDMETHOD.

  METHOD set_checked.
      DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.

    IF all = abap_true.
      check_branch( key = key
                    val = val ).
    ELSE.

      READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
      IF sy-subrc = 0.
        lr_node->checked = val.
      ENDIF.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD check_branch.

    DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.
    DATA ls_child LIKE LINE OF mt_node.
    READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = key.
    IF sy-subrc = 0.
      lr_node->checked = val.
    ENDIF.

    LOOP AT mt_node INTO ls_child WHERE parent = key.
      check_branch( key = ls_child-key
                    val = val ).
    ENDLOOP.

  ENDMETHOD.

  METHOD get_checked.

    DATA ls_node LIKE LINE OF mt_node.
    LOOP AT mt_node INTO ls_node WHERE checked = abap_true.
      INSERT ls_node-key INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD add_function.

    DATA temp62 TYPE z2ui5_cl_cgui_alv=>ty_s_function.
    CLEAR temp62.
    temp62-name = name.
    temp62-text = text.
    temp62-icon = icon.
    temp62-tooltip = tooltip.
    INSERT temp62 INTO TABLE mt_function.
    result = me.

  ENDMETHOD.

  METHOD sync.

    TYPES temp1 TYPE HASHED TABLE OF ty_s_key_row WITH UNIQUE KEY key.
DATA lt_row TYPE temp1.
    DATA ls_node LIKE LINE OF mt_node.
      DATA lv_row LIKE sy-tabix.
      DATA temp63 TYPE z2ui5_cl_cgui_tree=>ty_s_key_row.
    DATA ls_row LIKE LINE OF view.
      DATA ls_key TYPE z2ui5_cl_cgui_tree=>ty_s_key_row.
        DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.

    IF mv_checkbox = abap_false.
      RETURN.
    ENDIF.
    " only the nodes shown - a collapsed branch keeps its ticks; the rows of
    " the keys once, not a scan of the nodes per row

    LOOP AT mt_node INTO ls_node.

      lv_row = sy-tabix.
      " the first node of a key, as READ TABLE finds it

      CLEAR temp63.
      temp63-key = ls_node-key.
      temp63-row = lv_row.
      INSERT temp63 INTO TABLE lt_row.
    ENDLOOP.

    LOOP AT view INTO ls_row.

      READ TABLE lt_row INTO ls_key WITH TABLE KEY key = ls_row-key.
      IF sy-subrc = 0.

        READ TABLE mt_node REFERENCE INTO lr_node INDEX ls_key-row.
        lr_node->checked = ls_row-checked.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_title.

    mv_title = val.
    result = me.

  ENDMETHOD.

  METHOD set_hierarchy_header.

    mv_header = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_text.

    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40
    DATA lv_key TYPE string.
    DATA lr_column TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_column.
    lv_key = to_upper( name ).

    READ TABLE mt_column REFERENCE INTO lr_column WITH KEY name = lv_key.
    IF sy-subrc = 0.
      lr_column->text = text.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD set_column_hidden.

    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40
    DATA lv_key TYPE string.
    DATA lr_column TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_column.
    lv_key = to_upper( name ).

    READ TABLE mt_column REFERENCE INTO lr_column WITH KEY name = lv_key.
    IF sy-subrc = 0.
      lr_column->hidden = val.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD get_columns.

    result = mt_column.

  ENDMETHOD.

  METHOD columns_from.

    DATA lo_struct TYPE REF TO cl_abap_structdescr.
        DATA temp64 TYPE z2ui5_cl_cgui_tree=>ty_s_column.
    DATA temp65 TYPE abap_component_view_tab.
    DATA ls_comp LIKE LINE OF temp65.
      DATA lv_text TYPE string.
      DATA temp66 TYPE z2ui5_cl_cgui_tree=>ty_s_column.
      DATA temp5 TYPE z2ui5_cl_cgui_tree=>ty_s_column-text.
      DATA temp6 TYPE z2ui5_cl_cgui_tree=>ty_s_column-align.

    TRY.
        lo_struct ?= cl_abap_typedescr=>describe_by_data( data ).
      CATCH cx_sy_move_cast_error.
        " a single value - one column

        CLEAR temp64.
        temp64-name = `VALUE`.
        temp64-text = z2ui5_cl_cgui_context=>rtti_get_label( data ).
        INSERT temp64 INTO TABLE mt_column.
        RETURN.
    ENDTRY.

    " the components of includes as fields of their own

    temp65 = lo_struct->get_included_view( ).

    LOOP AT temp65 INTO ls_comp.
      IF lines( mt_column ) >= cv_max_columns.
        EXIT.
      ENDIF.
      IF ls_comp-type->kind <> cl_abap_typedescr=>kind_elem.
        CONTINUE.
      ENDIF.

      lv_text = z2ui5_cl_cgui_context=>rtti_get_label_by_descr( ls_comp-type ).

      CLEAR temp66.
      temp66-name = ls_comp-name.

      IF lv_text IS NOT INITIAL.
        temp5 = lv_text.
      ELSE.
        temp5 = ls_comp-name.
      ENDIF.
      temp66-text = temp5.

      IF z2ui5_cl_cgui_alv=>is_numeric( ls_comp-type->type_kind ) = abap_true.
        temp6 = `End`.
      ELSE.
        temp6 = `Begin`.
      ENDIF.
      temp66-align = temp6.
      INSERT temp66 INTO TABLE mt_column.
    ENDLOOP.

  ENDMETHOD.

  METHOD cells_of.

    FIELD-SYMBOLS <value> TYPE any.

    DATA ls_column LIKE LINE OF mt_column.
      DATA temp67 TYPE string.
    LOOP AT mt_column INTO ls_column.
      UNASSIGN <value>.
      IF ls_column-name = `VALUE`.
        ASSIGN COMPONENT `VALUE` OF STRUCTURE data TO <value>.
        IF sy-subrc <> 0.
          ASSIGN data TO <value>.
        ENDIF.
      ELSE.
        ASSIGN COMPONENT ls_column-name OF STRUCTURE data TO <value>.
      ENDIF.
      " an initial value stays empty - the sums of a parent leave the fields
      " of the leaves blank instead of 0000 and 0.00

      IF <value> IS ASSIGNED AND <value> IS NOT INITIAL.
        temp67 = z2ui5_cl_cgui_context=>conv_to_text( <value> ).
      ELSE.
        CLEAR temp67.
      ENDIF.
      INSERT temp67
             INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD view.

    DATA lt_child TYPE ty_t_child.

    DATA ls_node LIKE LINE OF mt_node.
      DATA lv_row LIKE sy-tabix.
      DATA temp68 TYPE z2ui5_cl_cgui_tree=>ty_s_child.
    LOOP AT mt_node INTO ls_node.

      lv_row = sy-tabix.

      CLEAR temp68.
      temp68-parent = ls_node-parent.
      temp68-row = lv_row.
      INSERT temp68 INTO TABLE lt_child.
    ENDLOOP.
    view_add( EXPORTING parent   = 0
                        level    = 0
                        children = lt_child
              CHANGING  rows     = result ).

  ENDMETHOD.

  METHOD view_add.

    DATA lv_cell_no TYPE ty_cell_no.
    FIELD-SYMBOLS <cell> TYPE string.

    DATA ls_child LIKE LINE OF children.
      DATA ls_node TYPE z2ui5_cl_cgui_tree=>ty_s_node.
      DATA lv_children TYPE abap_bool.
      DATA temp7 LIKE sy-subrc.
      DATA temp8 LIKE sy-subrc.
      DATA temp9 LIKE sy-tabix.
      DATA temp2 TYPE xsdboolean.
      DATA lv_expandable TYPE abap_bool.
      DATA temp3 TYPE xsdboolean.
      DATA lv_open TYPE abap_bool.
      DATA temp4 TYPE xsdboolean.
      DATA temp69 TYPE ty_s_view.
      DATA temp10 TYPE i.
      DATA temp11 TYPE z2ui5_cl_cgui_tree=>ty_s_view-expander.
      DATA temp12 TYPE z2ui5_cl_cgui_tree=>ty_s_view-icon.
      DATA ls_row LIKE temp69.
      DATA lv_cell LIKE LINE OF ls_node-cells.
        DATA temp70 TYPE string.
    LOOP AT children INTO ls_child WHERE parent = parent.

      READ TABLE mt_node INTO ls_node INDEX ls_child-row.




      temp8 = sy-subrc.
      temp9 = sy-tabix.
      READ TABLE children WITH KEY parent = ls_node-key TRANSPORTING NO FIELDS.
      temp7 = sy-subrc.
      sy-subrc = temp8.
      sy-tabix = temp9.

      temp2 = boolc( temp7 = 0 ).
      lv_children = temp2.


      temp3 = boolc( lv_children = abap_true OR ls_node-lazy = abap_true ).
      lv_expandable = temp3.
      " open: expanded with children - a lazy node waits for its first expand


      temp4 = boolc( lv_children = abap_true AND ls_node-expanded = abap_true ).
      lv_open = temp4.

      CLEAR temp69.
      temp69-key = ls_node-key.
      temp69-level = level.

      IF lv_expandable = abap_true.
        temp10 = 0.
      ELSE.
        temp10 = 32.
      ENDIF.
      temp69-indent = |{ level * 24 + temp10 }px|.

      IF lv_expandable = abap_false.
        temp11 = ``.
      ELSEIF lv_open = abap_true.
        temp11 = `sap-icon://navigation-down-arrow`.
      ELSE.
        temp11 = `sap-icon://navigation-right-arrow`.
      ENDIF.
      temp69-expander = temp11.
      temp69-text = ls_node-text.
      temp69-checked = ls_node-checked.

      IF ls_node-icon IS NOT INITIAL.
        temp12 = ls_node-icon.
      ELSEIF lv_open = abap_true.
        temp12 = `sap-icon://open-folder`.
      ELSEIF lv_expandable = abap_true OR ls_node-folder = abap_true.
        temp12 = `sap-icon://folder-blank`.
      ELSE.
        temp12 = ``.
      ENDIF.
      temp69-icon = temp12.

      ls_row = temp69.

      LOOP AT ls_node-cells INTO lv_cell.
        " C01, C02, ... - NUMC rather than ALIGN and PAD, which the
        " transpiled runtime does not apply
        lv_cell_no = sy-tabix.

        temp70 = |C{ lv_cell_no }|.
ASSIGN COMPONENT temp70 OF STRUCTURE ls_row TO <cell>.
        IF sy-subrc = 0.
          <cell> = lv_cell.
        ENDIF.
      ENDLOOP.
      INSERT ls_row INTO TABLE rows.

      IF lv_children = abap_true AND ls_node-expanded = abap_true.
        view_add( EXPORTING parent   = ls_node-key
                            level    = level + 1
                            children = children
                  CHANGING  rows     = rows ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD render.

    DATA lv_rows TYPE i.
    DATA temp71 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_bar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp72 TYPE string.
    DATA temp73 TYPE string.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_hier TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp74 TYPE string.
    DATA temp13 TYPE string.
    DATA lo_cell TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp75 TYPE string_table.
        DATA temp77 TYPE string_table.
    DATA temp79 TYPE string_table.
    DATA ls_column LIKE LINE OF mt_column.
      DATA lv_index LIKE sy-tabix.
      DATA lo_column TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp81 TYPE ty_cell_no.
    lv_rows = lines( view ).
    IF lv_rows > 20.
      lv_rows = 20.
    ELSEIF lv_rows < 3.
      lv_rows = 3.
    ENDIF.


    IF rows_bind IS NOT INITIAL.
      temp71 = rows_bind.
    ELSE.
      temp71 = client->_bind( view ).
    ENDIF.

    lo_table = node->ele( n = `Table` ns = `table`
        )->a( n = `xmlns:table`        v = `sap.ui.table`
        )->a( n = `xmlns:core`         v = `sap.ui.core`
        )->a( n = `rows`               v = temp71
        )->a( n = `selectionMode`      v = `None`
        )->a( n = `visibleRowCount`    v = |{ lv_rows }|
        )->a( n = `class`              v = `sapUiSmallMargin` ).


    lo_bar = lo_table->ele( n = `extension` ns = `table`
        )->ele( `OverflowToolbar` ).
    lo_bar->tag( `Title`
        )->a( n = `text` t = mv_title ).
    lo_bar->tag( `ToolbarSpacer` ).
    z2ui5_cl_cgui_alv=>render_functions( bar       = lo_bar
                                         client    = client
                                         functions = mt_function ).

    temp72 = 'Expand all'(001).
    lo_bar->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://expand-group`
        )->a( n = `tooltip` t = temp72
        )->a( n = `press`   v = client->_event( cs_event-expand_all ) ).

    temp73 = 'Collapse all'(002).
    lo_bar->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://collapse-group`
        )->a( n = `tooltip` t = temp73
        )->a( n = `press`   v = client->_event( cs_event-collapse_all ) ).


    lo_columns = lo_table->ele( n = `columns` ns = `table` ).

    " the hierarchy: indentation, expander, icon and the text of the node

    lo_hier = lo_columns->ele( n = `Column` ns = `table`
        )->a( n = `width` v = `22rem` ).

    temp74 = 'Hierarchy'(003).

    IF mv_header IS NOT INITIAL.
      temp13 = mv_header.
    ELSE.
      temp13 = temp74.
    ENDIF.
    lo_hier->ele( n = `label` ns = `table`
        )->tag( `Label`
        )->a( n = `text`   t = temp13
        )->a( n = `design` v = `Bold` ).

    lo_cell = lo_hier->ele( n = `template` ns = `table`
        )->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    lo_cell->tag( `Text`
        )->a( n = `text`  v = ``
        )->a( n = `width` v = `{INDENT}` ).

    CLEAR temp75.
    INSERT `${KEY}` INTO TABLE temp75.
    lo_cell->tag( `Button`
        )->a( n = `icon`    v = `{EXPANDER}`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `visible` v = `{= ${EXPANDER} !== '' }`
        )->a( n = `press`   v = client->_event( val   = cs_event-toggle
                                                t_arg = temp75 ) ).
    IF mv_checkbox = abap_true.
      lo_cell->tag( `CheckBox`
          )->a( n = `selected` v = `{CHECKED}` ).
      IF mv_check_event = abap_true OR mv_check_branch = abap_true.

        CLEAR temp77.
        INSERT `${KEY}` INTO TABLE temp77.
        lo_cell->a( n = `select` v = client->_event( val   = cs_event-checkbox
                                                     t_arg = temp77 ) ).
      ENDIF.
    ENDIF.

    CLEAR temp79.
    INSERT `${KEY}` INTO TABLE temp79.
    lo_cell->tag( n = `Icon` ns = `core`
            )->a( n = `src`     v = `{ICON}`
            )->a( n = `visible` v = `{= ${ICON} !== '' }`
            )->a( n = `class`   v = `sapUiTinyMarginEnd`
            )->tag( `Link`
            )->a( n = `text`  v = `{TEXT}`
            )->a( n = `press` v = client->_event( val   = cs_event-node
                                                  t_arg = temp79 ) ).


    LOOP AT mt_column INTO ls_column.

      lv_index = sy-tabix.
      IF ls_column-hidden = abap_true.
        CONTINUE.
      ENDIF.

      lo_column = lo_columns->ele( n = `Column` ns = `table`
          )->a( n = `hAlign` v = ls_column-align ).
      lo_column->ele( n = `label` ns = `table`
          )->tag( `Label`
          )->a( n = `text` t = ls_column-text ).

      temp81 = lv_index.
      lo_column->ele( n = `template` ns = `table`
          )->tag( `Text`
          )->a( n = `text`     v = |\{C{ temp81 }\}|
          )->a( n = `wrapping` b = abap_false ).
    ENDLOOP.

  ENDMETHOD.

  METHOD parent_of_related.

    IF related = 0.
      RETURN.
    ENDIF.
    IF relationship = z2ui5_if_cgui_salv_c=>node_relation-first_child
        OR relationship = z2ui5_if_cgui_salv_c=>node_relation-last_child.
      result = related.
    ELSE.
      result = get_parent( related ).
    ENDIF.

  ENDMETHOD.

  METHOD toggle.

    DATA ls_node TYPE z2ui5_cl_cgui_tree=>ty_s_node.
    ls_node = get_node( key ).
    IF ls_node-expanded = abap_true AND has_children( key ) = abap_true.
      collapse( key ).
      RETURN.
    ENDIF.
    expand( key ).
    IF ls_node-lazy = abap_true AND has_children( key ) = abap_false.
      " loaded once - empty afterwards, it is a folder without children
      set_loaded( key ).
      result = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD handle_event.
        DATA lv_key TYPE i.

    result = abap_true.
    CASE client->get_event( ).
      WHEN cs_event-toggle.

        lv_key = get_node_by_event( client ).
        IF toggle( lv_key ) = abap_true.
          mv_expand_request = lv_key.
        ENDIF.
      WHEN cs_event-checkbox.
        " the tick is in the node already (sync) - the branch follows it
        lv_key = get_node_by_event( client ).
        IF mv_check_branch = abap_true.
          set_checked( key = lv_key
                       val = get_node( lv_key )-checked
                       all = abap_true ).
        ENDIF.
        " at_tree_checkbox( ) of the report follows
        result = abap_false.
      WHEN cs_event-expand_all.
        expand_all( ).
      WHEN cs_event-collapse_all.
        collapse_all( ).
      WHEN OTHERS.
        result = abap_false.
    ENDCASE.

  ENDMETHOD.

  METHOD get_node_by_event.

    DATA lv_arg TYPE string.
    lv_arg = condense( client->get_event_arg( ) ).
    IF lv_arg IS NOT INITIAL AND lv_arg CO `0123456789`.
      result = lv_arg.
    ENDIF.

  ENDMETHOD.

  METHOD to_text.

    FIELD-SYMBOLS <cell> TYPE string.
    DATA temp82 TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    DATA ls_row LIKE LINE OF temp82.
      DATA temp83 TYPE string.
      DATA temp14 TYPE string.
      DATA lv_line TYPE string.
      DATA ls_column LIKE LINE OF mt_column.
        DATA temp84 TYPE string.

    IF mv_title IS NOT INITIAL.
      INSERT mv_title INTO TABLE result.
    ENDIF.

    temp82 = view( ).

    LOOP AT temp82 INTO ls_row.

      CASE ls_row-expander.
        WHEN ``.
          temp83 = `  `.
        WHEN `sap-icon://navigation-down-arrow`.
          temp83 = `- `.
        WHEN OTHERS.
          temp83 = `+ `.
      ENDCASE.

      IF mv_checkbox = abap_true AND ls_row-checked = abap_true.
        temp14 = `[x] `.
      ELSEIF mv_checkbox = abap_true.
        temp14 = `[ ] `.
      ELSE.
        CLEAR temp14.
      ENDIF.

      lv_line = |{ repeat( val = `  ` occ = ls_row-level ) }{ temp83 }{ temp14 }{ ls_row-text }|.

      LOOP AT mt_column INTO ls_column WHERE hidden = abap_false.

        temp84 = |C{ sy-tabix WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
ASSIGN COMPONENT temp84 OF STRUCTURE ls_row TO <cell>.
        IF sy-subrc = 0 AND ls_column-name IS NOT INITIAL.
          lv_line = |{ lv_line } \| { <cell> }|.
        ENDIF.
      ENDLOOP.
      INSERT lv_line INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
