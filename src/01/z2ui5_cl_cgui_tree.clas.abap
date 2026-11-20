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
  PRIVATE SECTION.

    " the number of a cell column, C01 ... C99
    TYPES ty_cell_no TYPE n LENGTH 2.

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

    METHODS columns_from
      IMPORTING
        data TYPE any.

    METHODS cells_of
      IMPORTING
        data          TYPE any
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS view_add
      IMPORTING
        parent TYPE i
        level  TYPE i
      CHANGING
        rows   TYPE ty_t_view.

    METHODS expand_branch
      IMPORTING
        key TYPE i
        val TYPE abap_bool.

    METHODS check_branch
      IMPORTING
        key TYPE i
        val TYPE abap_bool.

    METHODS expandable
      IMPORTING
        node          TYPE ty_s_node
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.



CLASS z2ui5_cl_cgui_tree IMPLEMENTATION.

  METHOD factory.

    CREATE OBJECT result.

  ENDMETHOD.

  METHOD add_node.
    DATA temp55 TYPE ty_s_node.
    DATA ls_node LIKE temp55.

    mv_next = mv_next + 1.

    CLEAR temp55.
    temp55-key = mv_next.
    temp55-parent = parent.
    temp55-text = text.
    temp55-icon = icon.
    temp55-folder = folder.
    temp55-expanded = expanded.
    temp55-value = value.
    temp55-lazy = lazy.

    ls_node = temp55.
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

    DATA temp56 TYPE i.
    DATA temp57 TYPE z2ui5_cl_cgui_tree=>ty_s_node.
    CLEAR temp56.

    READ TABLE mt_node INTO temp57 WITH KEY key = key.
    IF sy-subrc = 0.
      temp56 = temp57-parent.
    ENDIF.
    result = temp56.

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

  METHOD expandable.

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( has_children( node-key ) = abap_true OR node-lazy = abap_true ).
    result = temp1.

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

    DATA temp58 LIKE sy-subrc.
    DATA temp2 TYPE xsdboolean.
    READ TABLE mt_node WITH KEY parent = key TRANSPORTING NO FIELDS.
    temp58 = sy-subrc.

    temp2 = boolc( temp58 = 0 ).
    result = temp2.

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

    DATA temp59 LIKE LINE OF mt_node.
    DATA lr_node LIKE REF TO temp59.
    LOOP AT mt_node REFERENCE INTO lr_node.
      lr_node->expanded = abap_true.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD collapse_all.

    DATA temp60 LIKE LINE OF mt_node.
    DATA lr_node LIKE REF TO temp60.
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

    DATA temp61 TYPE z2ui5_cl_cgui_alv=>ty_s_function.
    CLEAR temp61.
    temp61-name = name.
    temp61-text = text.
    temp61-icon = icon.
    temp61-tooltip = tooltip.
    INSERT temp61 INTO TABLE mt_function.
    result = me.

  ENDMETHOD.

  METHOD sync.
    DATA ls_row LIKE LINE OF view.
      DATA lr_node TYPE REF TO z2ui5_cl_cgui_tree=>ty_s_node.

    IF mv_checkbox = abap_false.
      RETURN.
    ENDIF.
    " only the nodes shown - a collapsed branch keeps its ticks

    LOOP AT view INTO ls_row.

      READ TABLE mt_node REFERENCE INTO lr_node WITH KEY key = ls_row-key.
      IF sy-subrc = 0.
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
        DATA temp62 TYPE z2ui5_cl_cgui_tree=>ty_s_column.
    DATA temp63 TYPE abap_component_view_tab.
    DATA ls_comp LIKE LINE OF temp63.
      DATA lv_text TYPE string.
      DATA temp64 TYPE z2ui5_cl_cgui_tree=>ty_s_column.
      DATA temp5 TYPE z2ui5_cl_cgui_tree=>ty_s_column-text.
      DATA temp6 TYPE z2ui5_cl_cgui_tree=>ty_s_column-align.

    TRY.
        lo_struct ?= cl_abap_typedescr=>describe_by_data( data ).
      CATCH cx_sy_move_cast_error.
        " a single value - one column

        CLEAR temp62.
        temp62-name = `VALUE`.
        temp62-text = z2ui5_cl_cgui_context=>rtti_get_label( data ).
        INSERT temp62 INTO TABLE mt_column.
        RETURN.
    ENDTRY.

    " the components of includes as fields of their own

    temp63 = lo_struct->get_included_view( ).

    LOOP AT temp63 INTO ls_comp.
      IF lines( mt_column ) >= cv_max_columns.
        EXIT.
      ENDIF.
      IF ls_comp-type->kind <> cl_abap_typedescr=>kind_elem.
        CONTINUE.
      ENDIF.

      lv_text = z2ui5_cl_cgui_context=>rtti_get_label_by_descr( ls_comp-type ).

      CLEAR temp64.
      temp64-name = ls_comp-name.

      IF lv_text IS NOT INITIAL.
        temp5 = lv_text.
      ELSE.
        temp5 = ls_comp-name.
      ENDIF.
      temp64-text = temp5.

      CASE ls_comp-type->type_kind.
        WHEN cl_abap_typedescr=>typekind_int OR cl_abap_typedescr=>typekind_int1 OR cl_abap_typedescr=>typekind_int2 OR cl_abap_typedescr=>typekind_int8 OR cl_abap_typedescr=>typekind_packed OR cl_abap_typedescr=>typekind_float OR cl_abap_typedescr=>typekind_decfloat16 OR cl_abap_typedescr=>typekind_decfloat34.
          temp6 = `End`.
        WHEN OTHERS.
          temp6 = `Begin`.
      ENDCASE.
      temp64-align = temp6.
      INSERT temp64 INTO TABLE mt_column.
    ENDLOOP.

  ENDMETHOD.

  METHOD cells_of.

    FIELD-SYMBOLS <value> TYPE any.

    DATA ls_column LIKE LINE OF mt_column.
      DATA temp65 TYPE string.
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
        temp65 = z2ui5_cl_cgui_context=>conv_to_text( <value> ).
      ELSE.
        CLEAR temp65.
      ENDIF.
      INSERT temp65
             INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD view.

    view_add( EXPORTING parent = 0
                        level  = 0
              CHANGING  rows   = result ).

  ENDMETHOD.

  METHOD view_add.

    DATA lv_cell_no TYPE ty_cell_no.
    FIELD-SYMBOLS <cell> TYPE string.

    DATA ls_node LIKE LINE OF mt_node.
      DATA lv_children TYPE abap_bool.
      DATA lv_expandable TYPE abap_bool.
      DATA lv_open TYPE abap_bool.
      DATA temp3 TYPE xsdboolean.
      DATA temp66 TYPE ty_s_view.
      DATA temp7 TYPE i.
      DATA temp8 TYPE z2ui5_cl_cgui_tree=>ty_s_view-expander.
      DATA temp9 TYPE z2ui5_cl_cgui_tree=>ty_s_view-icon.
      DATA ls_row LIKE temp66.
      DATA lv_cell LIKE LINE OF ls_node-cells.
        DATA temp67 TYPE string.
    LOOP AT mt_node INTO ls_node WHERE parent = parent.

      lv_children = has_children( ls_node-key ).

      lv_expandable = expandable( ls_node ).
      " open: expanded with children - a lazy node waits for its first expand


      temp3 = boolc( lv_children = abap_true AND ls_node-expanded = abap_true ).
      lv_open = temp3.

      CLEAR temp66.
      temp66-key = ls_node-key.
      temp66-level = level.

      IF lv_expandable = abap_true.
        temp7 = 0.
      ELSE.
        temp7 = 32.
      ENDIF.
      temp66-indent = |{ level * 24 + temp7 }px|.

      IF lv_expandable = abap_false.
        temp8 = ``.
      ELSEIF lv_open = abap_true.
        temp8 = `sap-icon://navigation-down-arrow`.
      ELSE.
        temp8 = `sap-icon://navigation-right-arrow`.
      ENDIF.
      temp66-expander = temp8.
      temp66-text = ls_node-text.
      temp66-checked = ls_node-checked.

      IF ls_node-icon IS NOT INITIAL.
        temp9 = ls_node-icon.
      ELSEIF lv_open = abap_true.
        temp9 = `sap-icon://open-folder`.
      ELSEIF lv_expandable = abap_true OR ls_node-folder = abap_true.
        temp9 = `sap-icon://folder-blank`.
      ELSE.
        temp9 = ``.
      ENDIF.
      temp66-icon = temp9.

      ls_row = temp66.

      LOOP AT ls_node-cells INTO lv_cell.
        " C01, C02, ... - NUMC rather than ALIGN and PAD, which the
        " transpiled runtime does not apply
        lv_cell_no = sy-tabix.

        temp67 = |C{ lv_cell_no }|.
ASSIGN COMPONENT temp67 OF STRUCTURE ls_row TO <cell>.
        IF sy-subrc = 0.
          <cell> = lv_cell.
        ENDIF.
      ENDLOOP.
      INSERT ls_row INTO TABLE rows.

      IF lv_children = abap_true AND ls_node-expanded = abap_true.
        view_add( EXPORTING parent = ls_node-key
                            level  = level + 1
                  CHANGING  rows   = rows ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD render.

    DATA lv_rows TYPE i.
    DATA temp68 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_bar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp69 LIKE LINE OF mt_function.
    DATA lr_function LIKE REF TO temp69.
    DATA temp70 TYPE string.
    DATA temp71 TYPE string.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_hier TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp72 TYPE string.
    DATA temp10 TYPE string.
    DATA lo_cell TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp73 TYPE string_table.
        DATA temp75 TYPE string_table.
    DATA temp77 TYPE string_table.
    DATA ls_column LIKE LINE OF mt_column.
      DATA lv_index LIKE sy-tabix.
      DATA lo_column TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp79 TYPE ty_cell_no.
    lv_rows = lines( view ).
    IF lv_rows > 20.
      lv_rows = 20.
    ELSEIF lv_rows < 3.
      lv_rows = 3.
    ENDIF.


    IF rows_bind IS NOT INITIAL.
      temp68 = rows_bind.
    ELSE.
      temp68 = client->_bind( view ).
    ENDIF.

    lo_table = node->ele( n = `Table` ns = `table`
        )->a( n = `xmlns:table`        v = `sap.ui.table`
        )->a( n = `xmlns:core`         v = `sap.ui.core`
        )->a( n = `rows`               v = temp68
        )->a( n = `selectionMode`      v = `None`
        )->a( n = `visibleRowCount`    v = |{ lv_rows }|
        )->a( n = `class`              v = `sapUiSmallMargin` ).


    lo_bar = lo_table->ele( n = `extension` ns = `table`
        )->ele( `OverflowToolbar` ).
    lo_bar->tag( `Title`
        )->a( n = `text` t = mv_title ).
    lo_bar->tag( `ToolbarSpacer` ).


    LOOP AT mt_function REFERENCE INTO lr_function.
      lo_bar->tag( `Button`
          )->a( n = `text`    t = lr_function->text
          )->a( n = `icon`    v = lr_function->icon
          )->a( n = `tooltip` t = lr_function->tooltip
          )->a( n = `press`   v = client->_event( lr_function->name ) ).
    ENDLOOP.

    temp70 = 'Expand all'(001).
    lo_bar->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://expand-group`
        )->a( n = `tooltip` t = temp70
        )->a( n = `press`   v = client->_event( cs_event-expand_all ) ).

    temp71 = 'Collapse all'(002).
    lo_bar->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://collapse-group`
        )->a( n = `tooltip` t = temp71
        )->a( n = `press`   v = client->_event( cs_event-collapse_all ) ).


    lo_columns = lo_table->ele( n = `columns` ns = `table` ).

    " the hierarchy: indentation, expander, icon and the text of the node

    lo_hier = lo_columns->ele( n = `Column` ns = `table`
        )->a( n = `width` v = `22rem` ).

    temp72 = 'Hierarchy'(003).

    IF mv_header IS NOT INITIAL.
      temp10 = mv_header.
    ELSE.
      temp10 = temp72.
    ENDIF.
    lo_hier->ele( n = `label` ns = `table`
        )->tag( `Label`
        )->a( n = `text`   t = temp10
        )->a( n = `design` v = `Bold` ).

    lo_cell = lo_hier->ele( n = `template` ns = `table`
        )->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    lo_cell->tag( `Text`
        )->a( n = `text`  v = ``
        )->a( n = `width` v = `{INDENT}` ).

    CLEAR temp73.
    INSERT `${KEY}` INTO TABLE temp73.
    lo_cell->tag( `Button`
        )->a( n = `icon`    v = `{EXPANDER}`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `visible` v = `{= ${EXPANDER} !== '' }`
        )->a( n = `press`   v = client->_event( val   = cs_event-toggle
                                                t_arg = temp73 ) ).
    IF mv_checkbox = abap_true.
      lo_cell->tag( `CheckBox`
          )->a( n = `selected` v = `{CHECKED}` ).
      IF mv_check_event = abap_true OR mv_check_branch = abap_true.

        CLEAR temp75.
        INSERT `${KEY}` INTO TABLE temp75.
        lo_cell->a( n = `select` v = client->_event( val   = cs_event-checkbox
                                                     t_arg = temp75 ) ).
      ENDIF.
    ENDIF.

    CLEAR temp77.
    INSERT `${KEY}` INTO TABLE temp77.
    lo_cell->tag( n = `Icon` ns = `core`
            )->a( n = `src`     v = `{ICON}`
            )->a( n = `visible` v = `{= ${ICON} !== '' }`
            )->a( n = `class`   v = `sapUiTinyMarginEnd`
            )->tag( `Link`
            )->a( n = `text`  v = `{TEXT}`
            )->a( n = `press` v = client->_event( val   = cs_event-node
                                                  t_arg = temp77 ) ).


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

      temp79 = lv_index.
      lo_column->ele( n = `template` ns = `table`
          )->tag( `Text`
          )->a( n = `text`     v = |\{C{ temp79 }\}|
          )->a( n = `wrapping` b = abap_false ).
    ENDLOOP.

  ENDMETHOD.

  METHOD handle_event.
        DATA lv_key TYPE i.
        DATA ls_node TYPE z2ui5_cl_cgui_tree=>ty_s_node.

    result = abap_true.
    CASE client->get_event( ).
      WHEN cs_event-toggle.

        lv_key = get_node_by_event( client ).

        ls_node = get_node( lv_key ).
        IF ls_node-expanded = abap_true AND has_children( lv_key ) = abap_true.
          collapse( lv_key ).
        ELSE.
          expand( lv_key ).
          IF ls_node-lazy = abap_true AND has_children( lv_key ) = abap_false.
            " loaded once - empty afterwards, it is a folder without children
            set_loaded( lv_key ).
            mv_expand_request = lv_key.
          ENDIF.
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
    DATA temp80 TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    DATA ls_row LIKE LINE OF temp80.
      DATA temp81 TYPE string.
      DATA temp11 TYPE string.
      DATA lv_line TYPE string.
      DATA ls_column LIKE LINE OF mt_column.
        DATA temp82 TYPE string.

    IF mv_title IS NOT INITIAL.
      INSERT mv_title INTO TABLE result.
    ENDIF.

    temp80 = view( ).

    LOOP AT temp80 INTO ls_row.

      CASE ls_row-expander.
        WHEN ``.
          temp81 = `  `.
        WHEN `sap-icon://navigation-down-arrow`.
          temp81 = `- `.
        WHEN OTHERS.
          temp81 = `+ `.
      ENDCASE.

      IF mv_checkbox = abap_true AND ls_row-checked = abap_true.
        temp11 = `[x] `.
      ELSEIF mv_checkbox = abap_true.
        temp11 = `[ ] `.
      ELSE.
        CLEAR temp11.
      ENDIF.

      lv_line = |{ repeat( val = `  ` occ = ls_row-level ) }{ temp81 }{ temp11 }{ ls_row-text }|.

      LOOP AT mt_column INTO ls_column WHERE hidden = abap_false.

        temp82 = |C{ sy-tabix WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
ASSIGN COMPONENT temp82 OF STRUCTURE ls_row TO <cell>.
        IF sy-subrc = 0 AND ls_column-name IS NOT INITIAL.
          lv_line = |{ lv_line } \| { <cell> }|.
        ENDIF.
      ENDLOOP.
      INSERT lv_line INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
