"! the controls of a report - the lines z2ui5_cl_cgui_report keeps
CLASS ltcl_gui DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_gui.
    DATA mt_control TYPE z2ui5_if_cgui_gui=>ty_t_control.
    TYPES temp1_afc79a9d3c TYPE STANDARD TABLE OF REF TO object WITH DEFAULT KEY.
DATA mt_object TYPE temp1_afc79a9d3c.
    DATA mt_handler TYPE z2ui5_if_cgui_gui=>ty_t_handler.
    DATA mt_grid TYPE z2ui5_if_cgui_gui=>ty_t_grid.
    DATA mr_grid_tab TYPE REF TO data.

ENDCLASS.


CLASS ltcl_gui IMPLEMENTATION.

  METHOD z2ui5_if_cgui_gui~control_add.

    DATA ls_control LIKE control.
    ls_control = control.
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

  METHOD z2ui5_if_cgui_gui~tablecontrol_render ##NEEDED.
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

    CLEAR result.
    result-field = `GS_PEAK-NAME`.
    result-value = `Watzmann`.
    result-line = 2.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_display.

    FIELD-SYMBOLS <from> TYPE any.
    FIELD-SYMBOLS <to>   TYPE any.

    FIELD-SYMBOLS <grid> TYPE z2ui5_if_cgui_gui=>ty_s_grid.
      DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_grid.
    READ TABLE mt_grid ASSIGNING <grid> WITH KEY id = id.
    IF sy-subrc <> 0.

      CLEAR temp1.
      temp1-id = id.
      INSERT temp1 INTO TABLE mt_grid ASSIGNING <grid>.
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

    DATA temp2 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    CLEAR temp2.
    INSERT 2 INTO TABLE temp2.
    result = temp2.

  ENDMETHOD.

ENDCLASS.


"! the handlers a report sets for the events of its controls
CLASS ltcl_handler DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    DATA mv_log TYPE string.

    METHODS on_close FOR EVENT close OF z2ui5_cl_cgui_container
      IMPORTING sender.
    METHODS on_function FOR EVENT function_selected OF z2ui5_cl_cgui_toolbar
      IMPORTING fcode.
    METHODS on_sapevent FOR EVENT sapevent OF z2ui5_cl_cgui_html_viewer
      IMPORTING action query_table.
    METHODS on_sapevent_post FOR EVENT sapevent OF z2ui5_cl_cgui_html_viewer
      IMPORTING action getdata postdata.
    METHODS on_toolbar FOR EVENT toolbar OF z2ui5_cl_cgui_alv_grid
      IMPORTING e_object e_interactive.
    METHODS on_double_click FOR EVENT double_click OF z2ui5_cl_cgui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_hotspot FOR EVENT hotspot_click OF z2ui5_cl_cgui_alv_grid
      IMPORTING e_row_id e_column_id es_row_no.
    METHODS on_user_command FOR EVENT user_command OF z2ui5_cl_cgui_alv_grid
      IMPORTING e_ucomm.
    METHODS on_node FOR EVENT node_double_click OF z2ui5_cl_cgui_simple_tree
      IMPORTING node_key.
    METHODS on_expand FOR EVENT expand_no_children OF z2ui5_cl_cgui_simple_tree
      IMPORTING node_key sender.
    METHODS on_item FOR EVENT item_double_click OF z2ui5_cl_cgui_column_tree
      IMPORTING node_key item_name.
    METHODS on_list_item FOR EVENT item_double_click OF z2ui5_cl_cgui_list_tree
      IMPORTING node_key item_name.
    METHODS on_link FOR EVENT link_click OF z2ui5_cl_cgui_column_tree
      IMPORTING node_key item_name.
    METHODS on_checkbox FOR EVENT checkbox_change OF z2ui5_cl_cgui_column_tree
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

    DATA lt_node TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA temp4 TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA temp5 LIKE LINE OF temp4.

    mv_log = |{ mv_log }EXPAND { node_key };|.

    CLEAR temp4.

    temp5-node_key = 'LH0400'.
    temp5-relatkey = node_key.
    temp5-relatship = z2ui5_cl_cgui_simple_tree=>relat_last_child.
    temp5-text = 'LH 0400'.
    INSERT temp5 INTO TABLE temp4.
    lt_node = temp4.
    sender->add_nodes( lt_node ).

  ENDMETHOD.

  METHOD on_function.

    mv_log = |{ mv_log }FUNCTION { fcode };|.

  ENDMETHOD.

  METHOD on_sapevent.
    DATA ls_query LIKE LINE OF query_table.

    mv_log = |{ mv_log }SAPEVENT { action }|.

    LOOP AT query_table INTO ls_query.
      mv_log = |{ mv_log } { ls_query-name }={ ls_query-value }|.
    ENDLOOP.
    mv_log = |{ mv_log };|.

  ENDMETHOD.

  METHOD on_sapevent_post.
    DATA lv_line LIKE LINE OF postdata.

    mv_log = |{ mv_log }SAPEVENT { action } { getdata } { lines( postdata ) }|.

    LOOP AT postdata INTO lv_line.
      mv_log = |{ mv_log } { strlen( lv_line ) }|.
    ENDLOOP.
    mv_log = |{ mv_log };|.

  ENDMETHOD.

  METHOD on_toolbar.

    DATA temp6 TYPE z2ui5_cl_cgui_alv_toolbar=>ty_s_button.
    DATA temp7 TYPE z2ui5_cl_cgui_alv_toolbar=>ty_s_button.
    CLEAR temp6.
    temp6-function = 'FULL'.
    temp6-icon = `sap-icon://accept`.
    temp6-text = 'Full'.
    APPEND temp6 TO e_object->mt_toolbar.

    CLEAR temp7.
    temp7-butn_type = 3.
    APPEND temp7 TO e_object->mt_toolbar.
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
    TYPES ty_t_line TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.

    DATA mo_gui TYPE REF TO ltcl_gui.
    DATA mo_cont TYPE REF TO z2ui5_cl_cgui_container.

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
    METHODS sapevent_form FOR TESTING.
    METHODS simple_tree FOR TESTING.
    METHODS column_tree FOR TESTING.
    METHODS list_tree FOR TESTING.
    METHODS cursor_field FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    CREATE OBJECT mo_gui.
    z2ui5_cl_cgui_gui=>set_report( mo_gui ).
    CREATE OBJECT mo_cont EXPORTING container_name = 'cc'.

  ENDMETHOD.

  METHOD teardown.

    DATA temp8 TYPE REF TO z2ui5_if_cgui_gui.
    CLEAR temp8.
    z2ui5_cl_cgui_gui=>set_report( temp8 ).

  ENDMETHOD.

  METHOD stream_and_table.

    DATA lt_out TYPE ty_t_line.
    DATA lv_text TYPE string.

    DATA lo_edit TYPE REF TO z2ui5_cl_cgui_textedit.
    FIELD-SYMBOLS <temp9> LIKE LINE OF mo_gui->mt_control.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp11> LIKE LINE OF mo_gui->mt_control.
    DATA temp12 LIKE sy-tabix.
    DATA temp13 TYPE ty_t_line.
    FIELD-SYMBOLS <temp15> LIKE LINE OF mo_gui->mt_control.
    DATA temp16 LIKE sy-tabix.
    FIELD-SYMBOLS <temp17> LIKE LINE OF mo_gui->mt_control.
    DATA temp18 LIKE sy-tabix.
    DATA temp19 TYPE ty_t_line.
    DATA temp21 TYPE ty_t_line.
    CREATE OBJECT lo_edit TYPE z2ui5_cl_cgui_textedit EXPORTING parent = mo_cont.


    temp10 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 1 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp9>-name
                                        exp = `CC` ).


    temp12 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp11>-parent
                                        exp = 1 ).


    CLEAR temp13.
    INSERT `first line` INTO TABLE temp13.
    INSERT `  indented` INTO TABLE temp13.
    lo_edit->set_text_as_r3table( temp13 ).


    temp16 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp15>.
    sy-tabix = temp16.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp15>-text
                                        exp = |first line\n  indented| ).

    " what the user typed is the bound line of the report


    temp18 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp17>-text = |one\r\ntwo\nthree|.
    lo_edit->get_text_as_r3table( IMPORTING table = lt_out ).

    CLEAR temp19.
    INSERT `one` INTO TABLE temp19.
    INSERT `two` INTO TABLE temp19.
    INSERT `three` INTO TABLE temp19.
    cl_abap_unit_assert=>assert_equals( act = lt_out
                                        exp = temp19 ).
    lo_edit->get_textstream( IMPORTING text = lv_text ).
    cl_abap_unit_assert=>assert_equals( act = lv_text
                                        exp = |one\r\ntwo\nthree| ).

    lo_edit->set_textstream( `plain` ).
    lo_edit->get_text_as_stream( IMPORTING text = lt_out ).

    CLEAR temp21.
    INSERT `plain` INTO TABLE temp21.
    cl_abap_unit_assert=>assert_equals( act = lt_out
                                        exp = temp21 ).
    lo_edit->delete_text( ).
    lo_edit->get_text_as_r3table( IMPORTING table = lt_out ).
    cl_abap_unit_assert=>assert_initial( lt_out ).

  ENDMETHOD.

  METHOD modified_and_modes.

    DATA lv_status TYPE i.
    DATA lv_text TYPE string.

    DATA lo_edit TYPE REF TO z2ui5_cl_cgui_textedit.
    FIELD-SYMBOLS <temp23> LIKE LINE OF mo_gui->mt_control.
    DATA temp24 LIKE sy-tabix.
    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    FIELD-SYMBOLS <temp1> LIKE LINE OF mo_gui->mt_control.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp25> LIKE LINE OF mo_gui->mt_control.
    DATA temp26 LIKE sy-tabix.
    FIELD-SYMBOLS <temp27> LIKE LINE OF mo_gui->mt_control.
    DATA temp28 LIKE sy-tabix.
    FIELD-SYMBOLS <temp29> LIKE LINE OF mo_gui->mt_control.
    DATA temp30 LIKE sy-tabix.
    CREATE OBJECT lo_edit TYPE z2ui5_cl_cgui_textedit EXPORTING parent = mo_cont.
    lo_edit->set_textstream( `set` ).
    lo_edit->get_textmodified_status( IMPORTING status = lv_status ).
    cl_abap_unit_assert=>assert_equals( act = lv_status
                                        exp = 0 ).



    temp24 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp23>.
    sy-tabix = temp24.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp23>-text = `typed`.
    lo_edit->get_textmodified_status( IMPORTING status = lv_status ).
    cl_abap_unit_assert=>assert_equals( act = lv_status
                                        exp = 1 ).
    lo_edit->set_textmodified_status( 0 ).
    lo_edit->get_textstream( EXPORTING only_when_modified = z2ui5_cl_cgui_gui=>true
                             IMPORTING text               = lv_text ).
    cl_abap_unit_assert=>assert_initial( lv_text ).

    " the classic modes: 1 / 0, as the constants and as numbers
    lo_edit->set_readonly_mode( 1 ).
    lo_edit->set_toolbar_mode( z2ui5_cl_cgui_textedit=>false ).
    lo_edit->set_statusbar_mode( 0 ).
    lo_edit->set_font_fixed( ).



    temp2 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_control = <temp1>.
    cl_abap_unit_assert=>assert_true( ls_control-readonly ).
    cl_abap_unit_assert=>assert_false( ls_control-toolbar ).
    cl_abap_unit_assert=>assert_false( ls_control-statusbar ).
    cl_abap_unit_assert=>assert_true( ls_control-fixed ).

    " cl_gui_control: visible as a flag or a number, free
    lo_edit->set_visible( abap_false ).


    temp26 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp25>.
    sy-tabix = temp26.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp25>-hidden ).
    lo_edit->set_visible( 1 ).


    temp28 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp27>.
    sy-tabix = temp28.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp27>-hidden ).
    lo_edit->free( ).


    temp30 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp29>-freed ).

  ENDMETHOD.

  METHOD splitter_cells.

    DATA lo_split TYPE REF TO z2ui5_cl_cgui_container.
    DATA lo_top TYPE REF TO z2ui5_cl_cgui_container.
    DATA lo_bottom TYPE REF TO z2ui5_cl_cgui_container.
    DATA temp1 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
    DATA ls_bottom TYPE z2ui5_if_cgui_gui=>ty_s_control.
    FIELD-SYMBOLS <temp3> LIKE LINE OF mo_gui->mt_control.
    DATA temp4 LIKE sy-tabix.
    DATA lo_easy TYPE REF TO z2ui5_cl_cgui_easy_split.
    DATA ls_right TYPE z2ui5_if_cgui_gui=>ty_s_control.
    FIELD-SYMBOLS <temp5> LIKE LINE OF mo_gui->mt_control.
    DATA temp6 LIKE sy-tabix.
    CREATE OBJECT lo_split TYPE z2ui5_cl_cgui_container EXPORTING parent = mo_cont rows = 2 columns = 1.

    lo_top = lo_split->get_container( row    = 1
                                            column = 1 ).

    lo_bottom = lo_split->get_container( row    = 2
                                               column = 1 ).

    temp1 = boolc( lo_split->get_container( row = 1 column = 1 ) = lo_top ).
    cl_abap_unit_assert=>assert_true( temp1 ).

    temp2 = boolc( lo_bottom = lo_top ).
    cl_abap_unit_assert=>assert_false( temp2 ).



    temp4 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_bottom->get_id( ) ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_bottom = <temp3>.
    cl_abap_unit_assert=>assert_equals( act = ls_bottom-parent
                                        exp = lo_split->get_id( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_bottom-row
                                        exp = 2 ).

    " an easy splitter: its two cells as attributes

    CREATE OBJECT lo_easy TYPE z2ui5_cl_cgui_easy_split EXPORTING parent = mo_cont orientation = z2ui5_cl_cgui_container=>orientation_horizontal.
    cl_abap_unit_assert=>assert_bound( lo_easy->top_left_container ).



    temp6 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_easy->bottom_right_container->get_id( ) ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_right = <temp5>.
    cl_abap_unit_assert=>assert_equals( act = ls_right-column
                                        exp = 2 ).

  ENDMETHOD.

  METHOD simple_tree.

    DATA lt_node TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA lv_selected TYPE c LENGTH 12.

    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA lo_tree TYPE REF TO z2ui5_cl_cgui_simple_tree.
    FIELD-SYMBOLS <temp31> LIKE LINE OF mo_gui->mt_control.
    DATA temp32 LIKE sy-tabix.
    DATA temp33 TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA temp34 LIKE LINE OF temp33.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_view.
    DATA temp36 LIKE sy-tabix.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_view.
    DATA temp38 LIKE sy-tabix.
    FIELD-SYMBOLS <temp39> LIKE LINE OF lt_view.
    DATA temp40 LIKE sy-tabix.
    FIELD-SYMBOLS <temp41> LIKE LINE OF lt_view.
    DATA temp42 LIKE sy-tabix.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CREATE OBJECT lo_tree TYPE z2ui5_cl_cgui_simple_tree EXPORTING parent = mo_cont.


    temp32 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_tree->get_id( ) ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp31>-kind
                                        exp = z2ui5_if_cgui_gui=>cs_kind-simple_tree ).
    " MTREESNODE: a root folder, a carrier below it, its flights on expand

    CLEAR temp33.

    CLEAR temp34.
    temp34-node_key = 'ROOT'.
    temp34-isfolder = abap_true.
    temp34-text = 'Carriers'.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-node_key = 'LH'.
    temp34-relatkey = 'ROOT'.
    temp34-relatship = z2ui5_cl_cgui_simple_tree=>relat_last_child.
    temp34-expander = abap_true.
    temp34-text = 'Lufthansa'.
    INSERT temp34 INTO TABLE temp33.
    lt_node = temp33.
    lo_tree->add_nodes( table_structure_name = 'MTREESNODE'
                        node_table           = lt_node ).
    lo_tree->expand_node( 'ROOT' ).

    lt_view = lo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 2 ).


    temp36 = sy-tabix.
    READ TABLE lt_view INDEX 2 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp35>-text
                                        exp = `Lufthansa` ).

    lo_tree->set_handler( handler = lo_handler
                          method  = 'ON_EXPAND'
                          event   = 'EXPAND_NO_CHILDREN' ).
    lo_tree->set_handler( handler = lo_handler
                          method  = 'ON_NODE'
                          event   = 'NODE_DOUBLE_CLICK' ).
    " the expander of LH - its children come from the handler


    temp38 = sy-tabix.
    READ TABLE lt_view INDEX 2 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lo_tree->dispatch( event = `EXPAND`
                       value = |{ <temp37>-key }| ).
    lt_view = lo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 3 ).


    temp40 = sy-tabix.
    READ TABLE lt_view INDEX 3 ASSIGNING <temp39>.
    sy-tabix = temp40.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp39>-text
                                        exp = `LH 0400` ).

    " a click: the node selected, node_double_click with its key


    temp42 = sy-tabix.
    READ TABLE lt_view INDEX 3 ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lo_tree->dispatch( event = `CLICK`
                       value = |{ <temp41>-key }| ).
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

    DATA lt_node TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA lt_item TYPE z2ui5_cl_cgui_column_tree=>ty_t_item.
    DATA lv_column TYPE c LENGTH 12.

    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA temp43 TYPE z2ui5_cl_cgui_column_tree=>ty_s_hhdr.
    DATA lo_tree TYPE REF TO z2ui5_cl_cgui_column_tree.
    DATA temp44 TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA temp45 LIKE LINE OF temp44.
    DATA temp46 TYPE z2ui5_cl_cgui_column_tree=>ty_t_item.
    DATA temp47 LIKE LINE OF temp46.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp48> LIKE LINE OF lt_view.
    DATA temp49 LIKE sy-tabix.
    DATA lt_column TYPE z2ui5_cl_cgui_simple_tree=>ty_t_column.
    FIELD-SYMBOLS <temp50> LIKE LINE OF lt_column.
    DATA temp51 LIKE sy-tabix.
    DATA lt_cell TYPE z2ui5_cl_cgui_simple_tree=>ty_t_cell.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_view.
    DATA temp8 LIKE sy-tabix.
    FIELD-SYMBOLS <temp52> LIKE LINE OF lt_cell.
    DATA temp53 LIKE sy-tabix.
    FIELD-SYMBOLS <temp54> LIKE LINE OF lt_cell.
    DATA temp55 LIKE sy-tabix.
    FIELD-SYMBOLS <temp56> LIKE LINE OF lt_cell.
    DATA temp57 LIKE sy-tabix.
    DATA lv_key TYPE string.
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_view.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp58> LIKE LINE OF lt_view.
    DATA temp59 LIKE sy-tabix.
    FIELD-SYMBOLS <temp60> LIKE LINE OF lt_cell.
    DATA temp61 LIKE sy-tabix.
    FIELD-SYMBOLS <temp62> LIKE LINE OF lt_view.
    DATA temp63 LIKE sy-tabix.
    FIELD-SYMBOLS <temp64> LIKE LINE OF lt_cell.
    DATA temp65 LIKE sy-tabix.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CLEAR temp43.
    temp43-heading = 'Airline'.
    temp43-width = 30.

    CREATE OBJECT lo_tree TYPE z2ui5_cl_cgui_column_tree EXPORTING parent = mo_cont hierarchy_column_name = 'Carrier' hierarchy_header = temp43.
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

    CLEAR temp44.

    temp45-node_key = 'LH'.
    temp45-isfolder = abap_true.
    INSERT temp45 INTO TABLE temp44.
    lt_node = temp44.

    CLEAR temp46.

    CLEAR temp47.
    temp47-node_key = 'LH'.
    temp47-item_name = 'CARRIER'.
    temp47-text = 'Lufthansa'.
    INSERT temp47 INTO TABLE temp46.
    CLEAR temp47.
    temp47-node_key = 'LH'.
    temp47-item_name = 'CITY'.
    temp47-class = z2ui5_cl_cgui_column_tree=>item_class_text.
    temp47-text = 'FRANKFURT'.
    INSERT temp47 INTO TABLE temp46.
    CLEAR temp47.
    temp47-node_key = 'LH'.
    temp47-item_name = 'WEB'.
    temp47-class = z2ui5_cl_cgui_column_tree=>item_class_link.
    temp47-text = 'lufthansa.com'.
    INSERT temp47 INTO TABLE temp46.
    CLEAR temp47.
    temp47-node_key = 'LH'.
    temp47-item_name = 'DONE'.
    temp47-class = z2ui5_cl_cgui_column_tree=>item_class_checkbox.
    temp47-editable = abap_true.
    INSERT temp47 INTO TABLE temp46.
    lt_item = temp46.
    lo_tree->add_nodes_and_items( node_table = lt_node
                                  item_table = lt_item ).

    lt_view = lo_tree->view( ).


    temp49 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp48>.
    sy-tabix = temp49.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp48>-text
                                        exp = `Lufthansa` ).

    lt_column = lo_tree->columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_column )
                                        exp = 4 ).


    temp51 = sy-tabix.
    READ TABLE lt_column INDEX 1 ASSIGNING <temp50>.
    sy-tabix = temp51.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp50>-text
                                        exp = `Airline` ).



    temp8 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_cell = lo_tree->cells( <temp7>-key ).


    temp53 = sy-tabix.
    READ TABLE lt_cell INDEX 1 ASSIGNING <temp52>.
    sy-tabix = temp53.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp52>-text
                                        exp = `FRANKFURT` ).


    temp55 = sy-tabix.
    READ TABLE lt_cell INDEX 2 ASSIGNING <temp54>.
    sy-tabix = temp55.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp54>-kind
                                        exp = `LINK` ).


    temp57 = sy-tabix.
    READ TABLE lt_cell INDEX 3 ASSIGNING <temp56>.
    sy-tabix = temp57.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp56>-kind
                                        exp = `CHECKBOX` ).

    lo_tree->set_handler( handler = lo_handler method = 'ON_ITEM' event = 'ITEM_DOUBLE_CLICK' ).
    lo_tree->set_handler( handler = lo_handler method = 'ON_LINK' event = 'LINK_CLICK' ).
    lo_tree->set_handler( handler = lo_handler method = 'ON_CHECKBOX' event = 'CHECKBOX_CHANGE' ).



    temp10 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_key = |{ <temp9>-key }|.
    lo_tree->dispatch( event = `CLICK`    value = lv_key ).
    lo_tree->dispatch( event = `LINK`     value = |{ lv_key } WEB| ).
    lo_tree->dispatch( event = `CHECKBOX` value = |{ lv_key } DONE| ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `ITEM LH CARRIER;LINK LH WEB;CHECKBOX LH DONE X;` ).


    temp59 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp58>.
    sy-tabix = temp59.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_cell = lo_tree->cells( <temp58>-key ).


    temp61 = sy-tabix.
    READ TABLE lt_cell INDEX 3 ASSIGNING <temp60>.
    sy-tabix = temp61.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp60>-checked ).

    lo_tree->item_set_text( node_key = 'LH' item_name = 'CITY' text = 'BERLIN' ).


    temp63 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp62>.
    sy-tabix = temp63.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_cell = lo_tree->cells( <temp62>-key ).


    temp65 = sy-tabix.
    READ TABLE lt_cell INDEX 1 ASSIGNING <temp64>.
    sy-tabix = temp65.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp64>-text
                                        exp = `BERLIN` ).
    lo_tree->delete_all_nodes( ).
    cl_abap_unit_assert=>assert_initial( lo_tree->view( ) ).

  ENDMETHOD.

  METHOD list_tree.

    DATA lt_node TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA lt_item TYPE z2ui5_cl_cgui_column_tree=>ty_t_item.

    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA lo_tree TYPE REF TO z2ui5_cl_cgui_list_tree.
    DATA temp66 TYPE z2ui5_cl_cgui_simple_tree=>ty_t_node.
    DATA temp67 LIKE LINE OF temp66.
    DATA temp68 TYPE z2ui5_cl_cgui_column_tree=>ty_t_item.
    DATA temp69 LIKE LINE OF temp68.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp70> LIKE LINE OF lt_view.
    DATA temp71 LIKE sy-tabix.
    DATA lt_cell TYPE z2ui5_cl_cgui_simple_tree=>ty_t_cell.
    FIELD-SYMBOLS <temp11> LIKE LINE OF lt_view.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp72> LIKE LINE OF lt_cell.
    DATA temp73 LIKE sy-tabix.
    FIELD-SYMBOLS <temp74> LIKE LINE OF lt_cell.
    DATA temp75 LIKE sy-tabix.
    FIELD-SYMBOLS <temp76> LIKE LINE OF lt_view.
    DATA temp77 LIKE sy-tabix.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CREATE OBJECT lo_tree TYPE z2ui5_cl_cgui_list_tree EXPORTING parent = mo_cont item_selection = abap_true.
    " the first item of a node is its text, the others follow on its line

    CLEAR temp66.

    temp67-node_key = 'LH'.
    temp67-isfolder = abap_true.
    INSERT temp67 INTO TABLE temp66.
    lt_node = temp66.

    CLEAR temp68.

    CLEAR temp69.
    temp69-node_key = 'LH'.
    temp69-item_name = '1'.
    temp69-text = 'Lufthansa'.
    INSERT temp69 INTO TABLE temp68.
    CLEAR temp69.
    temp69-node_key = 'LH'.
    temp69-item_name = '2'.
    temp69-length = 10.
    temp69-text = 'FRANKFURT'.
    INSERT temp69 INTO TABLE temp68.
    CLEAR temp69.
    temp69-node_key = 'LH'.
    temp69-item_name = '3'.
    temp69-class = z2ui5_cl_cgui_column_tree=>item_class_link.
    temp69-text = 'lufthansa.com'.
    INSERT temp69 INTO TABLE temp68.
    lt_item = temp68.
    lo_tree->add_nodes_and_items( node_table = lt_node
                                  item_table = lt_item ).

    lt_view = lo_tree->view( ).


    temp71 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp70>.
    sy-tabix = temp71.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp70>-text
                                        exp = `Lufthansa` ).
    cl_abap_unit_assert=>assert_initial( lo_tree->columns( ) ).



    temp12 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_cell = lo_tree->cells( <temp11>-key ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_cell )
                                        exp = 2 ).


    temp73 = sy-tabix.
    READ TABLE lt_cell INDEX 1 ASSIGNING <temp72>.
    sy-tabix = temp73.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp72>-width
                                        exp = 10 ).


    temp75 = sy-tabix.
    READ TABLE lt_cell INDEX 2 ASSIGNING <temp74>.
    sy-tabix = temp75.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp74>-kind
                                        exp = `LINK` ).

    " a click on the node is one on its first item - by its own name
    lo_tree->set_handler( handler = lo_handler method = 'ON_LIST_ITEM' event = 'ITEM_DOUBLE_CLICK' ).


    temp77 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp76>.
    sy-tabix = temp77.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lo_tree->dispatch( event = `CLICK` value = |{ <temp76>-key }| ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `ITEM LH 1;` ).

  ENDMETHOD.

  METHOD events.

    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA lo_dialog TYPE REF TO z2ui5_cl_cgui_container.
    FIELD-SYMBOLS <temp78> LIKE LINE OF mo_gui->mt_control.
    DATA temp79 LIKE sy-tabix.
    FIELD-SYMBOLS <temp80> LIKE LINE OF mo_gui->mt_control.
    DATA temp81 LIKE sy-tabix.
    DATA lo_html TYPE REF TO z2ui5_cl_cgui_html_viewer.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CREATE OBJECT lo_dialog TYPE z2ui5_cl_cgui_container EXPORTING caption = 'Details' width = 400 height = 300.


    temp79 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_dialog->get_id( ) ASSIGNING <temp78>.
    sy-tabix = temp79.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp78>-dialog ).
    lo_dialog->set_handler( handler = lo_handler
                            method  = 'ON_CLOSE'
                            event   = 'CLOSE' ).
    " the browser's event, passed on by the report: the handler with sender
    lo_dialog->dispatch( `CLOSE` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |CLOSE { lo_dialog->get_id( ) };| ).


    temp81 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_dialog->get_id( ) ASSIGNING <temp80>.
    sy-tabix = temp81.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp80>-freed ).


    CREATE OBJECT lo_html TYPE z2ui5_cl_cgui_html_viewer EXPORTING parent = mo_cont.
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
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_button WITH DEFAULT KEY.
DATA lt_group TYPE temp2.

    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA lo_bar TYPE REF TO z2ui5_cl_cgui_toolbar.
    DATA temp82 LIKE lt_group.
    DATA temp83 LIKE LINE OF temp82.
    DATA lt_button TYPE z2ui5_if_cgui_gui=>ty_t_button.
    FIELD-SYMBOLS <temp13> LIKE LINE OF mo_gui->mt_control.
    DATA temp14 LIKE sy-tabix.
    FIELD-SYMBOLS <temp84> LIKE LINE OF lt_button.
    DATA temp85 LIKE sy-tabix.
    FIELD-SYMBOLS <temp86> LIKE LINE OF lt_button.
    DATA temp87 LIKE sy-tabix.
    FIELD-SYMBOLS <temp88> LIKE LINE OF lt_button.
    DATA temp89 LIKE sy-tabix.
    FIELD-SYMBOLS <temp90> LIKE LINE OF mo_gui->mt_control.
    DATA temp91 LIKE sy-tabix.
    FIELD-SYMBOLS <temp15> LIKE LINE OF <temp90>-buttons.
    DATA temp16 LIKE sy-tabix.
    FIELD-SYMBOLS <temp92> LIKE LINE OF mo_gui->mt_control.
    DATA temp93 LIKE sy-tabix.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CREATE OBJECT lo_bar TYPE z2ui5_cl_cgui_toolbar EXPORTING parent = mo_cont.
    lo_bar->add_button( fcode     = 'refresh'
                        icon      = 'sap-icon://refresh'
                        butn_type = z2ui5_cl_cgui_toolbar=>cntb_btype_button
                        quickinfo = 'Read again' ).

    CLEAR temp82.

    CLEAR temp83.
    temp83-butn_type = '3'.
    INSERT temp83 INTO TABLE temp82.
    CLEAR temp83.
    temp83-function = 'SAVE'.
    temp83-text = 'Save'.
    temp83-disabled = 'X'.
    INSERT temp83 INTO TABLE temp82.
    lt_group = temp82.
    lo_bar->add_button_group( lt_group ).



    temp14 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_bar->get_id( ) ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_button = <temp13>-buttons.
    cl_abap_unit_assert=>assert_equals( act = lines( lt_button )
                                        exp = 3 ).


    temp85 = sy-tabix.
    READ TABLE lt_button INDEX 1 ASSIGNING <temp84>.
    sy-tabix = temp85.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp84>-fcode
                                        exp = `REFRESH` ).


    temp87 = sy-tabix.
    READ TABLE lt_button INDEX 2 ASSIGNING <temp86>.
    sy-tabix = temp87.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp86>-type
                                        exp = z2ui5_cl_cgui_toolbar=>cntb_btype_sep ).


    temp89 = sy-tabix.
    READ TABLE lt_button INDEX 3 ASSIGNING <temp88>.
    sy-tabix = temp89.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp88>-disabled ).

    lo_bar->set_button_state( fcode   = 'SAVE'
                              enabled = abap_true ).


    temp91 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_bar->get_id( ) ASSIGNING <temp90>.
    sy-tabix = temp91.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.


    temp16 = sy-tabix.
    READ TABLE <temp90>-buttons INDEX 3 ASSIGNING <temp15>.
    sy-tabix = temp16.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp15>-disabled ).

    lo_bar->set_handler( handler = lo_handler
                         method  = 'ON_FUNCTION'
                         event   = 'FUNCTION_SELECTED' ).
    lo_bar->dispatch( event = `FUNCTION_SELECTED`
                      value = `REFRESH` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `FUNCTION REFRESH;` ).

    lo_bar->delete_button( 'REFRESH' ).
    lo_bar->delete_all_buttons( ).


    temp93 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_bar->get_id( ) ASSIGNING <temp92>.
    sy-tabix = temp93.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp92>-buttons ).

  ENDMETHOD.

  METHOD html_document.

    TYPES ty_html TYPE c LENGTH 10.
    TYPES temp3 TYPE STANDARD TABLE OF ty_html WITH DEFAULT KEY.
DATA lt_html TYPE temp3.
    DATA lv_url TYPE c LENGTH 250.

    DATA lo_html TYPE REF TO z2ui5_cl_cgui_html_viewer.
    DATA temp94 LIKE lt_html.
    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    FIELD-SYMBOLS <temp17> LIKE LINE OF mo_gui->mt_control.
    DATA temp18 LIKE sy-tabix.
    FIELD-SYMBOLS <temp96> LIKE LINE OF mo_gui->mt_control.
    DATA temp97 LIKE sy-tabix.
    FIELD-SYMBOLS <temp98> LIKE LINE OF mo_gui->mt_control.
    DATA temp99 LIKE sy-tabix.
    FIELD-SYMBOLS <temp100> LIKE LINE OF mo_gui->mt_control.
    DATA temp101 LIKE sy-tabix.
    FIELD-SYMBOLS <temp102> LIKE LINE OF mo_gui->mt_control.
    DATA temp103 LIKE sy-tabix.
    FIELD-SYMBOLS <temp104> LIKE LINE OF mo_gui->mt_control.
    DATA temp105 LIKE sy-tabix.
    FIELD-SYMBOLS <temp106> LIKE LINE OF mo_gui->mt_control.
    DATA temp107 LIKE sy-tabix.
    FIELD-SYMBOLS <temp108> LIKE LINE OF mo_gui->mt_control.
    DATA temp109 LIKE sy-tabix.
    CREATE OBJECT lo_html TYPE z2ui5_cl_cgui_html_viewer EXPORTING parent = mo_cont.
    " a line filled to its end goes on in the next one, a shorter one ends

    CLEAR temp94.
    INSERT `<p>Hello w` INTO TABLE temp94.
    INSERT `orld</p>` INTO TABLE temp94.
    INSERT `<p>Bye</p>` INTO TABLE temp94.
    lt_html = temp94.
    lo_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    cl_abap_unit_assert=>assert_not_initial( lv_url ).
    lo_html->show_url( lv_url ).



    temp18 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_control = <temp17>.
    cl_abap_unit_assert=>assert_equals( act = ls_control-html
                                        exp = |<p>Hello world</p>\n<p>Bye</p>| ).
    cl_abap_unit_assert=>assert_initial( ls_control-url ).

    " an address of the web: a link
    lo_html->show_url( 'https://www.sap.com' ).


    temp97 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp96>.
    sy-tabix = temp97.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_control = <temp96>.
    cl_abap_unit_assert=>assert_equals( act = ls_control-url
                                        exp = `https://www.sap.com` ).
    cl_abap_unit_assert=>assert_initial( ls_control-html ).

    lo_html->show_data( ).


    temp99 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp98>.
    sy-tabix = temp99.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_not_initial( <temp98>-html ).

    " the history: back to the web address, forward to the document again
    lo_html->go_back( ).
    lo_html->get_current_url( IMPORTING url = lv_url ).
    cl_abap_unit_assert=>assert_equals( act = lv_url
                                        exp = `https://www.sap.com` ).


    temp101 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp100>.
    sy-tabix = temp101.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp100>-url
                                        exp = `https://www.sap.com` ).
    lo_html->go_forward( ).


    temp103 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp102>.
    sy-tabix = temp103.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_not_initial( <temp102>-html ).
    " the first page has none before it
    lo_html->go_back( ).
    lo_html->go_back( ).
    lo_html->go_back( ).


    temp105 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp104>.
    sy-tabix = temp105.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_not_initial( <temp104>-html ).

    " cl_gui_container=>visible_false hides the control
    lo_html->set_visible( z2ui5_cl_cgui_gui=>visible_false ).


    temp107 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp106>.
    sy-tabix = temp107.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp106>-hidden ).
    lo_html->set_visible( z2ui5_cl_cgui_gui=>visible_true ).


    temp109 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX 2 ASSIGNING <temp108>.
    sy-tabix = temp109.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp108>-hidden ).

  ENDMETHOD.

  METHOD sapevent_form.

    " a form of the document posted to SAPEVENT:save - its fields, urlencoded,
    " reach the handler as postdata in lines of 255 characters
    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA lo_html TYPE REF TO z2ui5_cl_cgui_html_viewer.
    DATA lv_post TYPE string.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CREATE OBJECT lo_html TYPE z2ui5_cl_cgui_html_viewer EXPORTING parent = mo_cont.
    lo_html->set_handler( handler = lo_handler
                          method  = 'ON_SAPEVENT_POST'
                          event   = 'SAPEVENT' ).

    lv_post = |name={ repeat( val = `x` occ = 300 ) }&ok=Save|.
    lo_html->dispatch( event = `SAPEVENT`
                       value = `save?mode=edit`
                       post  = lv_post ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |SAPEVENT save mode=edit 2 255 { strlen( lv_post ) - 255 };| ).

  ENDMETHOD.

  METHOD sapevent_links.

    DATA lt_link TYPE z2ui5_cl_cgui_html_viewer=>ty_t_link.
    FIELD-SYMBOLS <temp110> LIKE LINE OF lt_link.
    DATA temp111 LIKE sy-tabix.
    FIELD-SYMBOLS <temp112> LIKE LINE OF lt_link.
    DATA temp113 LIKE sy-tabix.
    FIELD-SYMBOLS <temp114> LIKE LINE OF lt_link.
    DATA temp115 LIKE sy-tabix.
    FIELD-SYMBOLS <temp116> LIKE LINE OF lt_link.
    DATA temp117 LIKE sy-tabix.
    lt_link = z2ui5_cl_cgui_html_viewer=>sapevent_links(
      `<p>x</p><a href="SAPEVENT:SHOW?CONNID=0400">Flight 0400</a> <A HREF='sapevent:back'> Back </A><a href="sapevent:open` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_link ) exp = 2 ).


    temp111 = sy-tabix.
    READ TABLE lt_link INDEX 1 ASSIGNING <temp110>.
    sy-tabix = temp111.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp110>-action exp = `SHOW?CONNID=0400` ).


    temp113 = sy-tabix.
    READ TABLE lt_link INDEX 1 ASSIGNING <temp112>.
    sy-tabix = temp113.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp112>-text exp = `Flight 0400` ).


    temp115 = sy-tabix.
    READ TABLE lt_link INDEX 2 ASSIGNING <temp114>.
    sy-tabix = temp115.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp114>-action exp = `back` ).


    temp117 = sy-tabix.
    READ TABLE lt_link INDEX 2 ASSIGNING <temp116>.
    sy-tabix = temp117.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp116>-text exp = `Back` ).

  ENDMETHOD.

  METHOD grid.

    TYPES:
      BEGIN OF ty_s_fcat,
        fieldname TYPE c LENGTH 30,
        coltext   TYPE c LENGTH 40,
        hotspot   TYPE abap_bool,
      END OF ty_s_fcat,
      ty_t_fcat TYPE STANDARD TABLE OF ty_s_fcat WITH DEFAULT KEY,
      BEGIN OF ty_s_line,
        carrid TYPE c LENGTH 3,
        connid TYPE n LENGTH 4,
      END OF ty_s_line,
      BEGIN OF ty_s_index,
        index   TYPE i,
        rowtype TYPE c LENGTH 30,
      END OF ty_s_index.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_line WITH DEFAULT KEY.
DATA lt_line TYPE temp4.
    TYPES temp5 TYPE STANDARD TABLE OF ty_s_index WITH DEFAULT KEY.
DATA lt_index TYPE temp5.
    DATA lt_fcat_back TYPE ty_t_fcat.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lo_handler TYPE REF TO ltcl_handler.
    DATA lo_grid TYPE REF TO z2ui5_cl_cgui_alv_grid.
    FIELD-SYMBOLS <temp118> LIKE LINE OF mo_gui->mt_control.
    DATA temp119 LIKE sy-tabix.
    DATA temp120 LIKE lt_line.
    DATA temp121 LIKE LINE OF temp120.
    DATA temp122 TYPE ty_t_fcat.
    DATA temp123 LIKE LINE OF temp122.
    DATA lt_fcat LIKE temp122.
    DATA ls_grid TYPE z2ui5_if_cgui_gui=>ty_s_grid.
    FIELD-SYMBOLS <temp19> LIKE LINE OF mo_gui->mt_grid.
    DATA temp20 LIKE sy-tabix.
    FIELD-SYMBOLS <temp124> LIKE LINE OF ls_grid-functions.
    DATA temp125 LIKE sy-tabix.
    DATA temp126 TYPE ty_s_line.
    FIELD-SYMBOLS <temp127> LIKE LINE OF lt_index.
    DATA temp128 LIKE sy-tabix.
    CREATE OBJECT lo_handler TYPE ltcl_handler.

    CREATE OBJECT lo_grid TYPE z2ui5_cl_cgui_alv_grid EXPORTING i_parent = mo_cont.


    temp119 = sy-tabix.
    READ TABLE mo_gui->mt_control INDEX lo_grid->get_id( ) ASSIGNING <temp118>.
    sy-tabix = temp119.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp118>-kind
                                        exp = z2ui5_if_cgui_gui=>cs_kind-grid ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_TOOLBAR' event = 'TOOLBAR' ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_DOUBLE_CLICK' event = 'DOUBLE_CLICK' ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_HOTSPOT' event = 'HOTSPOT_CLICK' ).
    lo_grid->set_handler( handler = lo_handler method = 'ON_USER_COMMAND' event = 'USER_COMMAND' ).


    CLEAR temp120.

    temp121-carrid = 'LH'.
    temp121-connid = '0400'.
    INSERT temp121 INTO TABLE temp120.
    temp121-carrid = 'LH'.
    temp121-connid = '0402'.
    INSERT temp121 INTO TABLE temp120.
    lt_line = temp120.

    CLEAR temp122.

    CLEAR temp123.
    temp123-fieldname = 'CARRID'.
    temp123-coltext = 'Airline'.
    INSERT temp123 INTO TABLE temp122.
    CLEAR temp123.
    temp123-fieldname = 'CONNID'.
    temp123-coltext = 'Flight'.
    temp123-hotspot = abap_true.
    INSERT temp123 INTO TABLE temp122.

    lt_fcat = temp122.
    lo_grid->set_table_for_first_display( CHANGING it_outtab       = lt_line
                                                   it_fieldcatalog = lt_fcat ).
    " the report has a copy of the table and of the field catalog, and the
    " functions the toolbar handler appended - no separator
    ASSIGN mo_gui->mr_grid_tab->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> ) exp = 2 ).



    temp20 = sy-tabix.
    READ TABLE mo_gui->mt_grid WITH KEY id = lo_grid->get_id( ) ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_grid = <temp19>.
    cl_abap_unit_assert=>assert_equals( act = lines( ls_grid-functions ) exp = 1 ).


    temp125 = sy-tabix.
    READ TABLE ls_grid-functions INDEX 1 ASSIGNING <temp124>.
    sy-tabix = temp125.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp124>-fcode exp = `FULL` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log exp = |TOOLBAR ;| ).
    lo_grid->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_fcat_back ).
    cl_abap_unit_assert=>assert_equals( act = lt_fcat_back exp = lt_fcat ).

    " refreshed: the table as it is now

    CLEAR temp126.
    temp126-carrid = 'AA'.
    temp126-connid = '0017'.
    APPEND temp126 TO lt_line.
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


    temp128 = sy-tabix.
    READ TABLE lt_index INDEX 1 ASSIGNING <temp127>.
    sy-tabix = temp128.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp127>-index exp = 2 ).

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
