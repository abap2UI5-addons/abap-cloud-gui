"! the controls of a report - the lines z2ui5_cl_cgui_report keeps
CLASS ltcl_gui DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_gui.
    DATA mt_control TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA mt_object TYPE STANDARD TABLE OF REF TO object WITH EMPTY KEY.
    DATA mt_handler TYPE z2ui5_if_cgui_gui=>ty_t_handler.
    DATA mt_grid TYPE z2ui5_if_cgui_gui=>ty_t_grid.
    DATA mr_grid_tab TYPE REF TO data.

ENDCLASS.


CLASS ltcl_gui IMPLEMENTATION.

  METHOD z2ui5_if_cgui_gui~control_add.

    DATA(ls_control) = control.
    ls_control-id = lines( mt_control ) + 1.
    INSERT ls_control INTO TABLE mt_control.
    INSERT object INTO TABLE mt_object.
    result = ls_control-id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_get.

    READ TABLE mt_control INTO result INDEX id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_set.

    MODIFY mt_control FROM control INDEX control-id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~handlers_get.

    result = mt_handler.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~handlers_set.

    mt_handler = handlers.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~subscreen_render ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tabstrip_active ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~custom_render ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~list ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tree ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tree_handler ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~cursor.

    result = VALUE #( field = `GS_PEAK-NAME`
                      value = `Watzmann`
                      line  = 2 ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_display.

    FIELD-SYMBOLS <from> TYPE any.
    FIELD-SYMBOLS <to>   TYPE any.

    READ TABLE mt_grid ASSIGNING FIELD-SYMBOL(<grid>) WITH KEY id = id.
    IF sy-subrc <> 0.
      INSERT VALUE #( id = id ) INTO TABLE mt_grid ASSIGNING <grid>.
    ENDIF.
    IF tab IS BOUND.
      ASSIGN tab->* TO <from>.
      CREATE DATA mr_grid_tab LIKE <from>.
      ASSIGN mr_grid_tab->* TO <to>.
      <to> = <from>.
    ENDIF.
    IF fieldcat IS BOUND.
      ASSIGN fieldcat->* TO <from>.
      CREATE DATA <grid>-fieldcat LIKE <from>.
      ASSIGN <grid>-fieldcat->* TO <to>.
      <to> = <from>.
    ENDIF.
    IF functions IS BOUND.
      ASSIGN functions->* TO <from>.
      <grid>-functions = <from>.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_get.

    READ TABLE mt_grid INTO result WITH KEY id = id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_selected.

    result = VALUE #( ( 2 ) ).

  ENDMETHOD.

ENDCLASS.


"! the handlers a report sets for the events of its controls
CLASS ltcl_handler DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    DATA mv_log TYPE string.

    METHODS on_close FOR EVENT close OF z2ui5_cl_cgui_gui_container
      IMPORTING sender.
    METHODS on_function FOR EVENT function_selected OF z2ui5_cl_cgui_gui_toolbar
      IMPORTING fcode.
    METHODS on_sapevent FOR EVENT sapevent OF z2ui5_cl_cgui_gui_html_viewer
      IMPORTING action query_table.
    METHODS on_toolbar FOR EVENT toolbar OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_object e_interactive.
    METHODS on_double_click FOR EVENT double_click OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_hotspot FOR EVENT hotspot_click OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_row_id e_column_id es_row_no.
    METHODS on_user_command FOR EVENT user_command OF z2ui5_cl_cgui_gui_alv_grid
      IMPORTING e_ucomm.
    METHODS on_node FOR EVENT node_double_click OF z2ui5_cl_cgui_gui_simple_tree
      IMPORTING node_key.
    METHODS on_expand FOR EVENT expand_no_children OF z2ui5_cl_cgui_gui_simple_tree
      IMPORTING node_key sender.
    METHODS on_item FOR EVENT item_double_click OF z2ui5_cl_cgui_gui_column_tree
      IMPORTING node_key item_name.
    METHODS on_list_item FOR EVENT item_double_click OF z2ui5_cl_cgui_gui_list_tree
      IMPORTING node_key item_name.
    METHODS on_link FOR EVENT link_click OF z2ui5_cl_cgui_gui_column_tree
      IMPORTING node_key item_name.
    METHODS on_checkbox FOR EVENT checkbox_change OF z2ui5_cl_cgui_gui_column_tree
      IMPORTING node_key item_name checked.

ENDCLASS.


CLASS ltcl_handler IMPLEMENTATION.

  METHOD on_close.

    mv_log = |{ mv_log }CLOSE { sender->get_id( ) };|.
    sender->free( ).

  ENDMETHOD.

  METHOD on_node.

    mv_log = |{ mv_log }NODE { node_key };|.

  ENDMETHOD.

  METHOD on_item.

    mv_log = |{ mv_log }ITEM { node_key } { item_name };|.

  ENDMETHOD.

  METHOD on_list_item.

    mv_log = |{ mv_log }ITEM { node_key } { item_name };|.

  ENDMETHOD.

  METHOD on_link.

    mv_log = |{ mv_log }LINK { node_key } { item_name };|.

  ENDMETHOD.

  METHOD on_checkbox.

    mv_log = |{ mv_log }CHECKBOX { node_key } { item_name } { checked };|.

  ENDMETHOD.

  METHOD on_expand.

    DATA lt_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_node.

    mv_log = |{ mv_log }EXPAND { node_key };|.
    lt_node = VALUE #( ( node_key = 'LH0400' relatkey = node_key relatship = z2ui5_cl_cgui_gui_simple_tree=>relat_last_child
                         text = 'LH 0400' ) ).
    sender->add_nodes( lt_node ).

  ENDMETHOD.

  METHOD on_function.

    mv_log = |{ mv_log }FUNCTION { fcode };|.

  ENDMETHOD.

  METHOD on_sapevent.

    mv_log = |{ mv_log }SAPEVENT { action }|.
    LOOP AT query_table INTO DATA(ls_query).
      mv_log = |{ mv_log } { ls_query-name }={ ls_query-value }|.
    ENDLOOP.
    mv_log = |{ mv_log };|.

  ENDMETHOD.

  METHOD on_toolbar.

    APPEND VALUE #( function = 'FULL' icon = `sap-icon://accept` text = 'Full' ) TO e_object->mt_toolbar.
    APPEND VALUE #( butn_type = 3 ) TO e_object->mt_toolbar.
    mv_log = |{ mv_log }TOOLBAR { e_interactive };|.

  ENDMETHOD.

  METHOD on_double_click.

    mv_log = |{ mv_log }DOUBLE_CLICK { e_row-index } { e_column-fieldname };|.

  ENDMETHOD.

  METHOD on_hotspot.

    mv_log = |{ mv_log }HOTSPOT { e_row_id-index } { e_column_id-fieldname } { es_row_no-row_id };|.

  ENDMETHOD.

  METHOD on_user_command.

    mv_log = |{ mv_log }UCOMM { e_ucomm };|.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    TYPES ty_line TYPE c LENGTH 72.
    TYPES ty_t_line TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    DATA mo_gui TYPE REF TO ltcl_gui.
    DATA mo_cont TYPE REF TO z2ui5_cl_cgui_gui_container.

    METHODS setup.
    METHODS teardown.
    METHODS stream_and_table FOR TESTING.
    METHODS modified_and_modes FOR TESTING.
    METHODS splitter_cells FOR TESTING.
    METHODS html_document FOR TESTING.
    METHODS events FOR TESTING.
    METHODS toolbar_buttons FOR TESTING.
    METHODS grid FOR TESTING.
    METHODS sapevent_links FOR TESTING.
    METHODS simple_tree FOR TESTING.
    METHODS column_tree FOR TESTING.
    METHODS list_tree FOR TESTING.
    METHODS cursor_field FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_gui = NEW #( ).
    z2ui5_cl_cgui_gui=>set_report( mo_gui ).
    mo_cont = NEW #( container_name = 'cc' ).

  ENDMETHOD.

  METHOD teardown.

    z2ui5_cl_cgui_gui=>set_report( VALUE #( ) ).

  ENDMETHOD.

  METHOD stream_and_table.

    DATA lt_out TYPE ty_t_line.
    DATA lv_text TYPE string.

    DATA(lo_edit) = NEW z2ui5_cl_cgui_gui_textedit( parent = mo_cont ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 1 ]-name
                                        exp = `CC` ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 2 ]-parent
                                        exp = 1 ).

    lo_edit->set_text_as_r3table( VALUE ty_t_line( ( `first line` ) ( `  indented` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 2 ]-text
                                        exp = |first line\n  indented| ).

    " what the user typed is the bound line of the report
    mo_gui->mt_control[ 2 ]-text = |one\r\ntwo\nthree|.
    lo_edit->get_text_as_r3table( IMPORTING table = lt_out ).
    cl_abap_unit_assert=>assert_equals( act = lt_out
                                        exp = VALUE ty_t_line( ( `one` ) ( `two` ) ( `three` ) ) ).
    lo_edit->get_textstream( IMPORTING text = lv_text ).
    cl_abap_unit_assert=>assert_equals( act = lv_text
                                        exp = |one\r\ntwo\nthree| ).

    lo_edit->set_textstream( `plain` ).
    lo_edit->get_text_as_stream( IMPORTING text = lt_out ).
    cl_abap_unit_assert=>assert_equals( act = lt_out
                                        exp = VALUE ty_t_line( ( `plain` ) ) ).
    lo_edit->delete_text( ).
    lo_edit->get_text_as_r3table( IMPORTING table = lt_out ).
    cl_abap_unit_assert=>assert_initial( lt_out ).

  ENDMETHOD.

  METHOD modified_and_modes.

    DATA lv_status TYPE i.
    DATA lv_text TYPE string.

    DATA(lo_edit) = NEW z2ui5_cl_cgui_gui_textedit( parent = mo_cont ).
    lo_edit->set_textstream( `set` ).
    lo_edit->get_textmodified_status( IMPORTING status = lv_status ).
    cl_abap_unit_assert=>assert_equals( act = lv_status
                                        exp = 0 ).

    mo_gui->mt_control[ 2 ]-text = `typed`.
    lo_edit->get_textmodified_status( IMPORTING status = lv_status ).
    cl_abap_unit_assert=>assert_equals( act = lv_status
                                        exp = 1 ).
    lo_edit->set_textmodified_status( 0 ).
    lo_edit->get_textstream( EXPORTING only_when_modified = z2ui5_cl_cgui_gui=>true
                             IMPORTING text               = lv_text ).
    cl_abap_unit_assert=>assert_initial( lv_text ).

    " the classic modes: 1 / 0, as the constants and as numbers
    lo_edit->set_readonly_mode( 1 ).
    lo_edit->set_toolbar_mode( z2ui5_cl_cgui_gui_textedit=>false ).
    lo_edit->set_statusbar_mode( 0 ).
    lo_edit->set_font_fixed( ).
    DATA(ls_control) = mo_gui->mt_control[ 2 ].
    cl_abap_unit_assert=>assert_true( ls_control-readonly ).
    cl_abap_unit_assert=>assert_false( ls_control-toolbar ).
    cl_abap_unit_assert=>assert_false( ls_control-statusbar ).
    cl_abap_unit_assert=>assert_true( ls_control-fixed ).

    " cl_gui_control: visible as a flag or a number, free
    lo_edit->set_visible( abap_false ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ 2 ]-hidden ).
    lo_edit->set_visible( 1 ).
    cl_abap_unit_assert=>assert_false( mo_gui->mt_control[ 2 ]-hidden ).
    lo_edit->free( ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ 2 ]-freed ).

  ENDMETHOD.

  METHOD splitter_cells.

    DATA(lo_split) = NEW z2ui5_cl_cgui_gui_container( parent  = mo_cont
                                                      rows    = 2
                                                      columns = 1 ).
    DATA(lo_top) = lo_split->get_container( row    = 1
                                            column = 1 ).
    DATA(lo_bottom) = lo_split->get_container( row    = 2
                                               column = 1 ).
    cl_abap_unit_assert=>assert_true( xsdbool( lo_split->get_container( row = 1 column = 1 ) = lo_top ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lo_bottom = lo_top ) ).
    DATA(ls_bottom) = mo_gui->mt_control[ lo_bottom->get_id( ) ].
    cl_abap_unit_assert=>assert_equals( act = ls_bottom-parent
                                        exp = lo_split->get_id( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_bottom-row
                                        exp = 2 ).

    " an easy splitter: its two cells as attributes
    DATA(lo_easy) = NEW z2ui5_cl_cgui_gui_easy_split( parent      = mo_cont
                                                         orientation = z2ui5_cl_cgui_gui_container=>orientation_horizontal ).
    cl_abap_unit_assert=>assert_bound( lo_easy->top_left_container ).
    DATA(ls_right) = mo_gui->mt_control[ lo_easy->bottom_right_container->get_id( ) ].
    cl_abap_unit_assert=>assert_equals( act = ls_right-column
                                        exp = 2 ).

  ENDMETHOD.

  METHOD simple_tree.

    DATA lt_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_node.
    DATA lv_selected TYPE c LENGTH 12.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_tree) = NEW z2ui5_cl_cgui_gui_simple_tree( parent = mo_cont ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ lo_tree->get_id( ) ]-kind
                                        exp = z2ui5_if_cgui_gui=>cs_kind-simple_tree ).
    " MTREESNODE: a root folder, a carrier below it, its flights on expand
    lt_node = VALUE #( ( node_key = 'ROOT' isfolder = abap_true text = 'Carriers' )
                       ( node_key = 'LH' relatkey = 'ROOT' relatship = z2ui5_cl_cgui_gui_simple_tree=>relat_last_child
                         expander = abap_true text = 'Lufthansa' ) ).
    lo_tree->add_nodes( table_structure_name = 'MTREESNODE'
                        node_table           = lt_node ).
    lo_tree->expand_node( 'ROOT' ).
    DATA(lt_view) = lo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 2 ]-text
                                        exp = `Lufthansa` ).

    lo_tree->set_handler( handler = lo_handler
                          method  = 'ON_EXPAND'
                          event   = 'EXPAND_NO_CHILDREN' ).
    lo_tree->set_handler( handler = lo_handler
                          method  = 'ON_NODE'
                          event   = 'NODE_DOUBLE_CLICK' ).
    " the expander of LH - its children come from the handler
    lo_tree->dispatch( event = `EXPAND`
                       value = |{ lt_view[ 2 ]-key }| ).
    lt_view = lo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 3 ]-text
                                        exp = `LH 0400` ).

    " a click: the node selected, node_double_click with its key
    lo_tree->dispatch( event = `CLICK`
                       value = |{ lt_view[ 3 ]-key }| ).
    lo_tree->get_selected_node( CHANGING node_key = lv_selected ).
    cl_abap_unit_assert=>assert_equals( act = lv_selected
                                        exp = 'LH0400' ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `EXPAND LH;NODE LH0400;` ).

    lo_tree->delete_node( 'LH' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_tree->view( ) )
                                        exp = 1 ).
    lo_tree->get_selected_node( CHANGING node_key = lv_selected ).
    cl_abap_unit_assert=>assert_initial( lv_selected ).

  ENDMETHOD.

  METHOD column_tree.

    DATA lt_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_node.
    DATA lt_item TYPE z2ui5_cl_cgui_gui_column_tree=>ty_t_item.
    DATA lv_column TYPE c LENGTH 12.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_tree) = NEW z2ui5_cl_cgui_gui_column_tree( parent                = mo_cont
                                                        hierarchy_column_name = 'Carrier'
                                                        hierarchy_header      = VALUE #( heading = 'Airline' width = 30 ) ).
    lo_tree->get_hierarchy_column_name( IMPORTING e_hierarchy_column_name = lv_column ).
    cl_abap_unit_assert=>assert_equals( act = lv_column
                                        exp = 'CARRIER' ).
    lo_tree->add_column( name = 'CITY' width = 20 header_text = 'From' ).
    lo_tree->add_column( name = 'WEB' width = 20 header_text = 'Web' ).
    lo_tree->add_column( name = 'DONE' width = 10 header_text = 'Done' ).
    lo_tree->add_column( EXPORTING  name          = 'CITY'
                         EXCEPTIONS column_exists = 4 ).
    cl_abap_unit_assert=>assert_subrc( exp = 4 ).

    " TREEV_NODE has no text - the item of the hierarchy column is it
    lt_node = VALUE #( ( node_key = 'LH' isfolder = abap_true ) ).
    lt_item = VALUE #( ( node_key = 'LH' item_name = 'CARRIER' text = 'Lufthansa' )
                       ( node_key = 'LH' item_name = 'CITY' class = z2ui5_cl_cgui_gui_column_tree=>item_class_text text = 'FRANKFURT' )
                       ( node_key = 'LH' item_name = 'WEB' class = z2ui5_cl_cgui_gui_column_tree=>item_class_link text = 'lufthansa.com' )
                       ( node_key = 'LH' item_name = 'DONE' class = z2ui5_cl_cgui_gui_column_tree=>item_class_checkbox editable = abap_true ) ).
    lo_tree->add_nodes_and_items( node_table = lt_node
                                  item_table = lt_item ).
    DATA(lt_view) = lo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 1 ]-text
                                        exp = `Lufthansa` ).
    DATA(lt_column) = lo_tree->columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_column )
                                        exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = lt_column[ 1 ]-text
                                        exp = `Airline` ).
    DATA(lt_cell) = lo_tree->cells( lt_view[ 1 ]-key ).
    cl_abap_unit_assert=>assert_equals( act = lt_cell[ 1 ]-text
                                        exp = `FRANKFURT` ).
    cl_abap_unit_assert=>assert_equals( act = lt_cell[ 2 ]-kind
                                        exp = `LINK` ).
    cl_abap_unit_assert=>assert_equals( act = lt_cell[ 3 ]-kind
                                        exp = `CHECKBOX` ).

    lo_tree->set_handler( handler = lo_handler method = 'ON_ITEM' event = 'ITEM_DOUBLE_CLICK' ).
    lo_tree->set_handler( handler = lo_handler method = 'ON_LINK' event = 'LINK_CLICK' ).
    lo_tree->set_handler( handler = lo_handler method = 'ON_CHECKBOX' event = 'CHECKBOX_CHANGE' ).
    DATA(lv_key) = |{ lt_view[ 1 ]-key }|.
    lo_tree->dispatch( event = `CLICK`    value = lv_key ).
    lo_tree->dispatch( event = `LINK`     value = |{ lv_key } WEB| ).
    lo_tree->dispatch( event = `CHECKBOX` value = |{ lv_key } DONE| ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `ITEM LH CARRIER;LINK LH WEB;CHECKBOX LH DONE X;` ).
    lt_cell = lo_tree->cells( lt_view[ 1 ]-key ).
    cl_abap_unit_assert=>assert_true( lt_cell[ 3 ]-checked ).

    lo_tree->item_set_text( node_key = 'LH' item_name = 'CITY' text = 'BERLIN' ).
    lt_cell = lo_tree->cells( lt_view[ 1 ]-key ).
    cl_abap_unit_assert=>assert_equals( act = lt_cell[ 1 ]-text
                                        exp = `BERLIN` ).
    lo_tree->delete_all_nodes( ).
    cl_abap_unit_assert=>assert_initial( lo_tree->view( ) ).

  ENDMETHOD.

  METHOD list_tree.

    DATA lt_node TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_node.
    DATA lt_item TYPE z2ui5_cl_cgui_gui_column_tree=>ty_t_item.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_tree) = NEW z2ui5_cl_cgui_gui_list_tree( parent         = mo_cont
                                                      item_selection = abap_true ).
    " the first item of a node is its text, the others follow on its line
    lt_node = VALUE #( ( node_key = 'LH' isfolder = abap_true ) ).
    lt_item = VALUE #( ( node_key = 'LH' item_name = '1' text = 'Lufthansa' )
                       ( node_key = 'LH' item_name = '2' length = 10 text = 'FRANKFURT' )
                       ( node_key = 'LH' item_name = '3' class = z2ui5_cl_cgui_gui_column_tree=>item_class_link text = 'lufthansa.com' ) ).
    lo_tree->add_nodes_and_items( node_table = lt_node
                                  item_table = lt_item ).
    DATA(lt_view) = lo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 1 ]-text
                                        exp = `Lufthansa` ).
    cl_abap_unit_assert=>assert_initial( lo_tree->columns( ) ).
    DATA(lt_cell) = lo_tree->cells( lt_view[ 1 ]-key ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_cell )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_cell[ 1 ]-width
                                        exp = 10 ).
    cl_abap_unit_assert=>assert_equals( act = lt_cell[ 2 ]-kind
                                        exp = `LINK` ).

    " a click on the node is one on its first item - by its own name
    lo_tree->set_handler( handler = lo_handler method = 'ON_LIST_ITEM' event = 'ITEM_DOUBLE_CLICK' ).
    lo_tree->dispatch( event = `CLICK` value = |{ lt_view[ 1 ]-key }| ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `ITEM LH 1;` ).

  ENDMETHOD.

  METHOD events.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_dialog) = NEW z2ui5_cl_cgui_gui_container( caption = 'Details'
                                                       width   = 400
                                                       height  = 300 ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ lo_dialog->get_id( ) ]-dialog ).
    lo_dialog->set_handler( handler = lo_handler
                            method  = 'ON_CLOSE'
                            event   = 'CLOSE' ).
    " the browser's event, passed on by the report: the handler with sender
    lo_dialog->dispatch( `CLOSE` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |CLOSE { lo_dialog->get_id( ) };| ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ lo_dialog->get_id( ) ]-freed ).

    DATA(lo_html) = NEW z2ui5_cl_cgui_gui_html_viewer( parent = mo_cont ).
    lo_html->set_handler( handler = lo_handler
                          method  = 'on_sapevent'
                          event   = 'sapevent' ).
    lo_html->dispatch( event = `SAPEVENT`
                       value = `SHOW?carrid=LH&connid=0400` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |CLOSE { lo_dialog->get_id( ) };SAPEVENT SHOW CARRID=LH CONNID=0400;| ).

    " ACTIVATION space: no handler any more
    CLEAR lo_handler->mv_log.
    lo_html->set_handler( handler    = lo_handler
                          method     = 'ON_SAPEVENT'
                          event      = 'SAPEVENT'
                          activation = abap_false ).
    lo_html->dispatch( event = `SAPEVENT`
                       value = `SHOW` ).
    cl_abap_unit_assert=>assert_initial( lo_handler->mv_log ).

  ENDMETHOD.

  METHOD toolbar_buttons.

    TYPES:
      BEGIN OF ty_s_button,
        function  TYPE c LENGTH 70,
        icon      TYPE c LENGTH 40,
        butn_type TYPE c LENGTH 1,
        text      TYPE c LENGTH 40,
        quickinfo TYPE c LENGTH 40,
        disabled  TYPE c LENGTH 1,
      END OF ty_s_button.
    DATA lt_group TYPE STANDARD TABLE OF ty_s_button WITH EMPTY KEY.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_bar) = NEW z2ui5_cl_cgui_gui_toolbar( parent = mo_cont ).
    lo_bar->add_button( fcode     = 'refresh'
                        icon      = 'sap-icon://refresh'
                        butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button
                        quickinfo = 'Read again' ).
    lt_group = VALUE #( ( butn_type = '3' )
                        ( function = 'SAVE' text = 'Save' disabled = 'X' ) ).
    lo_bar->add_button_group( lt_group ).
    DATA(lt_button) = mo_gui->mt_control[ lo_bar->get_id( ) ]-buttons.
    cl_abap_unit_assert=>assert_equals( act = lines( lt_button )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_button[ 1 ]-fcode
                                        exp = `REFRESH` ).
    cl_abap_unit_assert=>assert_equals( act = lt_button[ 2 ]-type
                                        exp = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_sep ).
    cl_abap_unit_assert=>assert_true( lt_button[ 3 ]-disabled ).

    lo_bar->set_button_state( fcode   = 'SAVE'
                              enabled = abap_true ).
    cl_abap_unit_assert=>assert_false( mo_gui->mt_control[ lo_bar->get_id( ) ]-buttons[ 3 ]-disabled ).

    lo_bar->set_handler( handler = lo_handler
                         method  = 'ON_FUNCTION'
                         event   = 'FUNCTION_SELECTED' ).
    lo_bar->dispatch( event = `FUNCTION_SELECTED`
                      value = `REFRESH` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `FUNCTION REFRESH;` ).

    lo_bar->delete_button( 'REFRESH' ).
    lo_bar->delete_all_buttons( ).
    cl_abap_unit_assert=>assert_initial( mo_gui->mt_control[ lo_bar->get_id( ) ]-buttons ).

  ENDMETHOD.

  METHOD html_document.

    TYPES ty_html TYPE c LENGTH 10.
    DATA lt_html TYPE STANDARD TABLE OF ty_html WITH EMPTY KEY.
    DATA lv_url TYPE c LENGTH 250.

    DATA(lo_html) = NEW z2ui5_cl_cgui_gui_html_viewer( parent = mo_cont ).
    " a line filled to its end goes on in the next one, a shorter one ends
    lt_html = VALUE #( ( `<p>Hello w` ) ( `orld</p>` ) ( `<p>Bye</p>` ) ).
    lo_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    cl_abap_unit_assert=>assert_not_initial( lv_url ).
    lo_html->show_url( lv_url ).
    DATA(ls_control) = mo_gui->mt_control[ 2 ].
    cl_abap_unit_assert=>assert_equals( act = ls_control-html
                                        exp = |<p>Hello world</p>\n<p>Bye</p>| ).
    cl_abap_unit_assert=>assert_initial( ls_control-url ).

    " an address of the web: a link
    lo_html->show_url( 'https://www.sap.com' ).
    ls_control = mo_gui->mt_control[ 2 ].
    cl_abap_unit_assert=>assert_equals( act = ls_control-url
                                        exp = `https://www.sap.com` ).
    cl_abap_unit_assert=>assert_initial( ls_control-html ).

    lo_html->show_data( ).
    cl_abap_unit_assert=>assert_not_initial( mo_gui->mt_control[ 2 ]-html ).

    " the history: back to the web address, forward to the document again
    lo_html->go_back( ).
    lo_html->get_current_url( IMPORTING url = lv_url ).
    cl_abap_unit_assert=>assert_equals( act = lv_url
                                        exp = `https://www.sap.com` ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 2 ]-url
                                        exp = `https://www.sap.com` ).
    lo_html->go_forward( ).
    cl_abap_unit_assert=>assert_not_initial( mo_gui->mt_control[ 2 ]-html ).
    " the first page has none before it
    lo_html->go_back( ).
    lo_html->go_back( ).
    lo_html->go_back( ).
    cl_abap_unit_assert=>assert_not_initial( mo_gui->mt_control[ 2 ]-html ).

    " cl_gui_container=>visible_false hides the control
    lo_html->set_visible( z2ui5_cl_cgui_gui=>visible_false ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ 2 ]-hidden ).
    lo_html->set_visible( z2ui5_cl_cgui_gui=>visible_true ).
    cl_abap_unit_assert=>assert_false( mo_gui->mt_control[ 2 ]-hidden ).

  ENDMETHOD.

  METHOD sapevent_links.

    DATA(lt_link) = z2ui5_cl_cgui_gui_html_viewer=>sapevent_links(
      `<p>x</p><a href="SAPEVENT:SHOW?CONNID=0400">Flight 0400</a> <A HREF='sapevent:back'> Back </A><a href="sapevent:open` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_link ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 1 ]-action exp = `SHOW?CONNID=0400` ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 1 ]-text exp = `Flight 0400` ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 2 ]-action exp = `back` ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 2 ]-text exp = `Back` ).

  ENDMETHOD.

  METHOD grid.

    TYPES:
      BEGIN OF ty_s_fcat,
        fieldname TYPE c LENGTH 30,
        coltext   TYPE c LENGTH 40,
        hotspot   TYPE abap_bool,
      END OF ty_s_fcat,
      ty_t_fcat TYPE STANDARD TABLE OF ty_s_fcat WITH EMPTY KEY,
      BEGIN OF ty_s_line,
        carrid TYPE c LENGTH 3,
        connid TYPE n LENGTH 4,
      END OF ty_s_line,
      BEGIN OF ty_s_index,
        index   TYPE i,
        rowtype TYPE c LENGTH 30,
      END OF ty_s_index.
    DATA lt_line TYPE STANDARD TABLE OF ty_s_line WITH EMPTY KEY.
    DATA lt_index TYPE STANDARD TABLE OF ty_s_index WITH EMPTY KEY.
    DATA lt_fcat_back TYPE ty_t_fcat.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_grid) = NEW z2ui5_cl_cgui_gui_alv_grid( i_parent = mo_cont ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ lo_grid->get_id( ) ]-kind
                                        exp = z2ui5_if_cgui_gui=>cs_kind-grid ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_TOOLBAR' event = 'TOOLBAR' ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_DOUBLE_CLICK' event = 'DOUBLE_CLICK' ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_HOTSPOT' event = 'HOTSPOT_CLICK' ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_USER_COMMAND' event = 'USER_COMMAND' ).

    lt_line = VALUE #( ( carrid = 'LH' connid = '0400' ) ( carrid = 'LH' connid = '0402' ) ).
    DATA(lt_fcat) = VALUE ty_t_fcat( ( fieldname = 'CARRID' coltext = 'Airline' )
                                     ( fieldname = 'CONNID' coltext = 'Flight' hotspot = abap_true ) ).
    lo_grid->set_table_for_first_display( CHANGING it_outtab       = lt_line
                                                   it_fieldcatalog = lt_fcat ).
    " the report has a copy of the table and of the field catalog, and the
    " functions the toolbar handler appended - no separator
    ASSIGN mo_gui->mr_grid_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> ) exp = 2 ).
    DATA(ls_grid) = mo_gui->mt_grid[ id = lo_grid->get_id( ) ].
    cl_abap_unit_assert=>assert_equals( act = lines( ls_grid-functions ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_grid-functions[ 1 ]-fcode exp = `FULL` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log exp = |TOOLBAR ;| ).
    lo_grid->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_fcat_back ).
    cl_abap_unit_assert=>assert_equals( act = lt_fcat_back exp = lt_fcat ).

    " refreshed: the table as it is now
    APPEND VALUE #( carrid = 'AA' connid = '0017' ) TO lt_line.
    lo_grid->refresh_table_display( CHANGING it_outtab = lt_line ).
    ASSIGN mo_gui->mr_grid_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> ) exp = 3 ).

    " the events of the browser
    CLEAR lo_handler->mv_log.
    lo_grid->dispatch( event = `DOUBLE_CLICK` value = `2` ).
    lo_grid->dispatch( event = `HOTSPOT_CLICK` value = |1{ cl_abap_char_utilities=>horizontal_tab }connid| ).
    lo_grid->dispatch( event = `USER_COMMAND` value = `FULL` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |DOUBLE_CLICK 2 ;HOTSPOT 1 CONNID 1;UCOMM FULL;| ).

    lo_grid->get_selected_rows( IMPORTING et_index_rows = lt_index ).
    cl_abap_unit_assert=>assert_equals( act = lt_index[ 1 ]-index exp = 2 ).

  ENDMETHOD.

  METHOD cursor_field.

    DATA lv_field TYPE c LENGTH 30.
    DATA lv_value TYPE c LENGTH 30.
    DATA lv_line TYPE i.

    " GET CURSOR FIELD f VALUE v LINE l - the click the report answers
    z2ui5_cl_cgui_gui=>get_cursor_field( IMPORTING  field        = lv_field
                                                    value        = lv_value
                                                    line         = lv_line
                                         EXCEPTIONS not_on_field = 4 ).
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = 'GS_PEAK-NAME'
                                        act = lv_field ).
    cl_abap_unit_assert=>assert_equals( exp = 'Watzmann'
                                        act = lv_value ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lv_line ).

  ENDMETHOD.

ENDCLASS.
