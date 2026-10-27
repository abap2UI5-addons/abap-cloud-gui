"! The stand-in of cl_gui_column_tree - the tree of z2ui5_cl_cgui_gui_simple_tree
"! with columns beside it. add_column( ) adds a column, add_nodes_and_items( )
"! takes the nodes (TREEV_NODE, read by the names of its fields) and their
"! items (MTREEITM: node_key, item_name, class, text, chosen, ...): the item
"! of the hierarchy column is the text of the node, the others are its
"! cells - a text, a link (item_class_link, link_click) or a checkbox
"! (item_class_checkbox, checkbox_change). A click on a node raises
"! selection_changed, node_double_click and item_double_click of the
"! hierarchy column
CLASS z2ui5_cl_cgui_gui_column_tree DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui_simple_tree
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS item_class_text      TYPE i VALUE 2.
    CONSTANTS item_class_checkbox  TYPE i VALUE 3.
    CONSTANTS item_class_button    TYPE i VALUE 4.
    CONSTANTS item_class_link      TYPE i VALUE 5.
    CONSTANTS item_font_default    TYPE i VALUE 0.
    CONSTANTS item_font_prop       TYPE i VALUE 1.
    CONSTANTS item_font_fixed      TYPE i VALUE 2.
    CONSTANTS align_left           TYPE i VALUE 1.
    CONSTANTS align_center         TYPE i VALUE 2.
    CONSTANTS align_right          TYPE i VALUE 4.
    CONSTANTS align_auto           TYPE i VALUE 8.
    CONSTANTS eventid_item_double_click TYPE i VALUE 23.
    CONSTANTS eventid_link_click   TYPE i VALUE 34.
    CONSTANTS eventid_checkbox_change TYPE i VALUE 36.

    TYPES ty_item_name TYPE c LENGTH 12.
    TYPES:
      "! the header of the hierarchy column - TREEV_HHDR of the classic
      BEGIN OF ty_s_hhdr,
        heading   TYPE c LENGTH 132,
        tooltip   TYPE c LENGTH 132,
        width     TYPE i,
        width_pix TYPE abap_bool,
        t_image   TYPE c LENGTH 132,
      END OF ty_s_hhdr.
    TYPES:
      "! an item of a node in a column - MTREEITM of the classic
      BEGIN OF ty_s_item,
        node_key   TYPE ty_node_key,
        item_name  TYPE ty_item_name,
        class      TYPE i,
        font       TYPE i,
        disabled   TYPE abap_bool,
        editable   TYPE abap_bool,
        hidden     TYPE abap_bool,
        alignment  TYPE i,
        t_image    TYPE c LENGTH 132,
        chosen     TYPE abap_bool,
        togg_right TYPE abap_bool,
        style      TYPE i,
        txtisqinfo TYPE abap_bool,
        length     TYPE i,
        ignoreimag TYPE abap_bool,
        usebgcolor TYPE abap_bool,
        text       TYPE c LENGTH 72,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.

    "! a click on a node - the item of the hierarchy column
    EVENTS item_double_click
      EXPORTING
        VALUE(node_key)  TYPE ty_node_key OPTIONAL
        VALUE(item_name) TYPE ty_item_name OPTIONAL.

    "! a click on an item of item_class_link
    EVENTS link_click
      EXPORTING
        VALUE(node_key)  TYPE ty_node_key OPTIONAL
        VALUE(item_name) TYPE ty_item_name OPTIONAL.

    "! a checkbox of item_class_checkbox ticked or cleared
    EVENTS checkbox_change
      EXPORTING
        VALUE(node_key)  TYPE ty_node_key OPTIONAL
        VALUE(item_name) TYPE ty_item_name OPTIONAL
        VALUE(checked)   TYPE abap_bool OPTIONAL.

    METHODS constructor
      IMPORTING
        parent                TYPE REF TO z2ui5_cl_cgui_gui_container
        node_selection_mode   TYPE i         DEFAULT node_sel_mode_single
        item_selection        TYPE abap_bool OPTIONAL
        hierarchy_column_name TYPE clike
        hierarchy_header      TYPE ty_s_hhdr OPTIONAL
        no_hierarchy_column   TYPE abap_bool OPTIONAL
        hide_selection        TYPE abap_bool OPTIONAL
        lifetime              TYPE i         OPTIONAL
        shellstyle            TYPE i         OPTIONAL
        name                  TYPE clike     OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        illegal_node_selection_mode
        failed
        illegal_column_name.

    "! a column after the ones added so far - width in characters
    METHODS add_column
      IMPORTING
        name                         TYPE clike
        width                        TYPE i         OPTIONAL
        alignment                    TYPE i         OPTIONAL
        header_text                  TYPE clike     OPTIONAL
        header_tooltip               TYPE clike     OPTIONAL
        header_image                 TYPE clike     OPTIONAL
        width_pix                    TYPE abap_bool OPTIONAL
        hidden                       TYPE abap_bool OPTIONAL
        disabled                     TYPE abap_bool OPTIONAL
        predecessor_column           TYPE clike     OPTIONAL
      EXCEPTIONS
        column_exists
        illegal_column_name
        too_many_columns
        illegal_alignment
        different_column_types
        cntl_system_error
        failed
        predecessor_column_not_found.

    "! the nodes of node_table as add_nodes( ), their items of item_table -
    "! the text of a node is its item of the hierarchy column
    METHODS add_nodes_and_items
      IMPORTING
        node_table                TYPE STANDARD TABLE
        item_table                TYPE STANDARD TABLE
        item_table_structure_name TYPE clike OPTIONAL
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_tables
        dp_error
        table_structure_name_not_found.

    METHODS item_set_text
      IMPORTING
        node_key  TYPE clike
        item_name TYPE clike
        text      TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error.

    "! the checkbox of the item ticked or cleared
    METHODS item_set_chosen
      IMPORTING
        node_key  TYPE clike
        item_name TYPE clike
        chosen    TYPE abap_bool
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error.

    METHODS get_hierarchy_column_name
      EXPORTING
        e_hierarchy_column_name TYPE clike.

    METHODS delete_all_nodes REDEFINITION.
    METHODS delete_node      REDEFINITION.
    METHODS columns          REDEFINITION.
    METHODS cells            REDEFINITION.
    METHODS dispatch         REDEFINITION.

  PROTECTED SECTION.
    " the hierarchy column, the columns after it and the items - kept with
    " the control between roundtrips
    DATA mv_hierarchy TYPE ty_item_name.
    DATA ms_header    TYPE ty_s_hhdr.
    DATA mt_column    TYPE ty_t_column.
    DATA mt_item      TYPE ty_t_item.

    "! the name of the item a click on the node is a click on
    METHODS hierarchy_item
      IMPORTING
        node_key      TYPE ty_node_key
      RETURNING
        VALUE(result) TYPE ty_item_name.

    "! the cell of an item
    METHODS cell_of
      IMPORTING
        item          TYPE ty_s_item
      RETURNING
        VALUE(result) TYPE ty_s_cell.

  PRIVATE SECTION.
    "! RAISE EVENT event EXPORTING node_key item_name - and checked
    METHODS raise_item_event
      IMPORTING
        event     TYPE string
        node_key  TYPE ty_node_key
        item_name TYPE ty_item_name
        checked   TYPE abap_bool OPTIONAL.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_column_tree IMPLEMENTATION.

  METHOD constructor.

    super->constructor( EXPORTING  parent              = parent
                                   node_selection_mode = node_selection_mode
                        EXCEPTIONS failed              = 1
                                   OTHERS              = 2 ).
    IF sy-subrc <> 0.
      RAISE failed.
    ENDIF.
    IF hierarchy_column_name IS INITIAL.
      RAISE illegal_column_name.
    ENDIF.
    mv_hierarchy = to_upper( hierarchy_column_name ).
    ms_header = hierarchy_header.

  ENDMETHOD.

  METHOD add_column.

    DATA(lv_name) = to_upper( condense( CONV string( name ) ) ).
    IF lv_name IS INITIAL.
      RAISE illegal_column_name.
    ENDIF.
    IF lv_name = mv_hierarchy OR line_exists( mt_column[ name = lv_name ] ).
      RAISE column_exists.
    ENDIF.
    IF hidden = abap_true.
      RETURN.
    ENDIF.
    INSERT VALUE #( name  = lv_name
                    text  = condense( CONV string( header_text ) )
                    width = COND #( WHEN width_pix = abap_true THEN width / 8 ELSE width ) ) INTO TABLE mt_column.

  ENDMETHOD.

  METHOD add_nodes_and_items.

    DATA lt_node TYPE ty_t_node.
    DATA ls_node TYPE ty_s_node.
    DATA ls_item TYPE ty_s_item.

    LOOP AT node_table ASSIGNING FIELD-SYMBOL(<node_line>).
      CLEAR ls_node.
      MOVE-CORRESPONDING <node_line> TO ls_node.
      INSERT ls_node INTO TABLE lt_node.
    ENDLOOP.
    LOOP AT item_table ASSIGNING FIELD-SYMBOL(<line>).
      CLEAR ls_item.
      MOVE-CORRESPONDING <line> TO ls_item.
      ls_item-item_name = to_upper( ls_item-item_name ).
      IF ls_item-node_key IS INITIAL OR ls_item-hidden = abap_true.
        CONTINUE.
      ENDIF.
      " the item of the hierarchy column is the text of its node
      IF ls_item-item_name = mv_hierarchy.
        READ TABLE lt_node ASSIGNING FIELD-SYMBOL(<node>) WITH KEY node_key = ls_item-node_key.
        IF sy-subrc = 0.
          <node>-text = ls_item-text.
          CONTINUE.
        ENDIF.
      ENDIF.
      DELETE mt_item WHERE node_key = ls_item-node_key AND item_name = ls_item-item_name.
      INSERT ls_item INTO TABLE mt_item.
    ENDLOOP.
    add_nodes( lt_node ).

  ENDMETHOD.

  METHOD item_set_text.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    DATA(lv_item) = CONV ty_item_name( to_upper( item_name ) ).
    IF lv_item = mv_hierarchy.
      node_set_text( node_key = node_key
                     text     = text ).
      RETURN.
    ENDIF.
    READ TABLE mt_item ASSIGNING FIELD-SYMBOL(<item>) WITH KEY node_key = node_key_of( lv_key ) item_name = lv_item.
    IF sy-subrc <> 0.
      RAISE item_not_found.
    ENDIF.
    <item>-text = text.

  ENDMETHOD.

  METHOD item_set_chosen.

    DATA(lv_key) = key_of( node_key ).
    IF lv_key = 0.
      RAISE node_not_found.
    ENDIF.
    READ TABLE mt_item ASSIGNING FIELD-SYMBOL(<item>)
         WITH KEY node_key = node_key_of( lv_key ) item_name = CONV ty_item_name( to_upper( item_name ) ).
    IF sy-subrc <> 0.
      RAISE item_not_found.
    ENDIF.
    <item>-chosen = chosen.

  ENDMETHOD.

  METHOD get_hierarchy_column_name.

    e_hierarchy_column_name = mv_hierarchy.

  ENDMETHOD.

  METHOD delete_all_nodes.

    super->delete_all_nodes( ).
    CLEAR mt_item.

  ENDMETHOD.

  METHOD delete_node.

    super->delete_node( EXPORTING  node_key       = node_key
                        EXCEPTIONS node_not_found = 1
                                   OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RAISE node_not_found.
    ENDIF.
    " the items of the nodes gone with the branch
    LOOP AT mt_item INTO DATA(ls_item).
      IF key_of( ls_item-node_key ) = 0.
        DELETE mt_item WHERE node_key = ls_item-node_key.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD columns.

    INSERT VALUE #( name  = mv_hierarchy
                    text  = condense( ms_header-heading )
                    width = COND #( WHEN ms_header-width_pix = abap_true THEN ms_header-width / 8
                                    ELSE ms_header-width ) ) INTO TABLE result.
    INSERT LINES OF mt_column INTO TABLE result.

  ENDMETHOD.

  METHOD cells.

    DATA(lv_node_key) = node_key_of( key ).
    LOOP AT mt_column INTO DATA(ls_column).
      DATA(ls_cell) = VALUE ty_s_cell( name = ls_column-name
                                       kind = `TEXT` ).
      READ TABLE mt_item INTO DATA(ls_item) WITH KEY node_key = lv_node_key item_name = CONV ty_item_name( ls_column-name ).
      IF sy-subrc = 0.
        ls_cell = cell_of( ls_item ).
        CLEAR ls_cell-width.
      ENDIF.
      INSERT ls_cell INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD dispatch.

    " a link or a checkbox: the key of the node and the item apart by a space
    DATA(lv_event) = to_upper( event ).
    IF lv_event = `LINK` OR lv_event = `CHECKBOX`.
      SPLIT condense( value ) AT ` ` INTO DATA(lv_key) DATA(lv_name).
      IF lv_key IS INITIAL OR lv_key CN `0123456789`.
        RETURN.
      ENDIF.
      DATA(lv_node_key) = node_key_of( CONV i( lv_key ) ).
      DATA(lv_item) = CONV ty_item_name( to_upper( lv_name ) ).
      IF lv_node_key IS INITIAL.
        RETURN.
      ENDIF.
      IF lv_event = `LINK`.
        raise_item_event( event     = `LINK_CLICK`
                          node_key  = lv_node_key
                          item_name = lv_item ).
        RETURN.
      ENDIF.
      READ TABLE mt_item ASSIGNING FIELD-SYMBOL(<item>) WITH KEY node_key = lv_node_key item_name = lv_item.
      IF sy-subrc = 0 AND <item>-editable = abap_true AND <item>-disabled = abap_false.
        <item>-chosen = xsdbool( <item>-chosen = abap_false ).
        raise_item_event( event     = `CHECKBOX_CHANGE`
                          node_key  = lv_node_key
                          item_name = lv_item
                          checked   = <item>-chosen ).
      ENDIF.
      RETURN.
    ENDIF.

    super->dispatch( event = event
                     value = value ).
    " a click on a node is a click on its item of the hierarchy column too
    IF lv_event = `CLICK` AND condense( value ) CO `0123456789`.
      lv_node_key = node_key_of( CONV i( condense( value ) ) ).
      IF lv_node_key IS NOT INITIAL.
        raise_item_event( event     = `ITEM_DOUBLE_CLICK`
                          node_key  = lv_node_key
                          item_name = hierarchy_item( lv_node_key ) ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD hierarchy_item.

    result = mv_hierarchy.

  ENDMETHOD.

  METHOD cell_of.

    result = VALUE #( name    = condense( CONV string( item-item_name ) )
                      text    = condense( item-text )
                      checked = item-chosen
                      width   = item-length
                      kind    = COND #( WHEN item-class = item_class_link THEN `LINK`
                                        WHEN item-class = item_class_checkbox THEN `CHECKBOX`
                                        ELSE `TEXT` ) ).

  ENDMETHOD.

  METHOD raise_item_event.

    DATA(lv_node_key) = node_key.
    DATA(lv_item_name) = item_name.
    DATA(lv_checked) = checked.
    raise_event( event  = event
                 params = VALUE #( ( name = `NODE_KEY`  kind = cl_abap_objectdescr=>exporting value = REF #( lv_node_key ) )
                                   ( name = `ITEM_NAME` kind = cl_abap_objectdescr=>exporting value = REF #( lv_item_name ) )
                                   ( name = `CHECKED`   kind = cl_abap_objectdescr=>exporting value = REF #( lv_checked ) ) ) ).

  ENDMETHOD.

ENDCLASS.
