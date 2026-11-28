CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
  METHOD z2ui5_if_client~timer_stop.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~timer_set.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_nav_back.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_nav_tag.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_nav_pending.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_app_prev.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_navigated.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_init.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_event.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~follow_up_action.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~window_bind_tab.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_path.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_client.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~message_toast_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~message_box_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nav_app_call.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_app.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_start_param.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popup_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popup_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~hash_replace.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~hash_set.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~app_state_get_href.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~app_state_set_active.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~set_session_stateful.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD z2ui5_if_client~get_event.

    result = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = `{/VIEW}`.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    DATA temp1 TYPE string.
    IF t_arg IS NOT INITIAL.
      temp1 = |:{ concat_lines_of( table = t_arg sep = `,` ) }|.
    ELSE.
      CLEAR temp1.
    ENDIF.
    result = |EVENT:{ val }{ temp1 }|.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
        fldate TYPE d,
      END OF ty_s_row.

    DATA mo_client TYPE REF TO ltcl_client.
    DATA mo_tree   TYPE REF TO z2ui5_cl_cgui_tree.
    DATA mv_root   TYPE i.
    DATA mv_child  TYPE i.

    METHODS setup.
    METHODS collapsed_shows_roots FOR TESTING.
    METHODS expand_shows_children FOR TESTING.
    METHODS columns_and_cells FOR TESTING.
    METHODS toggle_by_event FOR TESTING.
    METHODS render_and_text FOR TESTING.
    METHODS checkboxes_and_functions FOR TESTING.
    METHODS lazy_node_requests_children FOR TESTING.
    METHODS checkbox_event_and_branch FOR TESTING.
    METHODS delete_and_change FOR TESTING.
    METHODS salv_expander_is_lazy FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    DATA temp2 TYPE ty_s_row.
    DATA temp3 TYPE ty_s_row.
    DATA temp4 TYPE ty_s_row.

    CREATE OBJECT mo_client.
    mo_tree = z2ui5_cl_cgui_tree=>factory( )->set_title( `Flights` ).

    CLEAR temp2.
    temp2-carrid = `LH`.
    temp2-seats = 300.
    mv_root = mo_tree->add_node( text = `LH`
                                 data = temp2 ).

    CLEAR temp3.
    temp3-carrid = `LH`.
    temp3-seats = 120.
    mv_child = mo_tree->add_node( parent = mv_root
                                  text   = `0400`
                                  data   = temp3
                                  value  = `7` ).

    CLEAR temp4.
    temp4-carrid = `LH`.
    temp4-seats = 60.
    mo_tree->add_node( parent = mv_child
                       text   = `20261001`
                       data   = temp4 ).
    mo_tree->add_node( `UA` ).

  ENDMETHOD.

  METHOD collapsed_shows_roots.

    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_view.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_view.
    DATA temp8 LIKE sy-tabix.
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_view.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp11> LIKE LINE OF lt_view.
    DATA temp12 LIKE sy-tabix.
    lt_view = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 2 ).


    temp6 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp5>-expander
                                        exp = `sap-icon://navigation-right-arrow` ).


    temp8 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp7>-icon
                                        exp = `sap-icon://folder-blank` ).
    " a leaf: no expander, its text where the others start


    temp10 = sy-tabix.
    READ TABLE lt_view INDEX 2 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp9>-expander ).


    temp12 = sy-tabix.
    READ TABLE lt_view INDEX 2 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp11>-indent
                                        exp = `32px` ).

  ENDMETHOD.

  METHOD expand_shows_children.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp13> LIKE LINE OF lt_view.
    DATA temp14 LIKE sy-tabix.
    FIELD-SYMBOLS <temp15> LIKE LINE OF lt_view.
    DATA temp16 LIKE sy-tabix.

    mo_tree->expand( mv_root ).

    lt_view = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 3 ).


    temp14 = sy-tabix.
    READ TABLE lt_view INDEX 2 ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp13>-text
                                        exp = `0400` ).


    temp16 = sy-tabix.
    READ TABLE lt_view INDEX 2 ASSIGNING <temp15>.
    sy-tabix = temp16.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp15>-level
                                        exp = 1 ).

    " the whole branch
    mo_tree->expand( key = mv_root
                     all = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->view( ) )
                                        exp = 4 ).
    mo_tree->collapse_all( ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->view( ) )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->get_children( mv_root ) )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_node( mv_child )-value
                                        exp = `7` ).

  ENDMETHOD.

  METHOD columns_and_cells.

    DATA lt_column TYPE z2ui5_cl_cgui_tree=>ty_t_column.
    FIELD-SYMBOLS <temp17> LIKE LINE OF lt_column.
    DATA temp18 LIKE sy-tabix.
    FIELD-SYMBOLS <temp19> LIKE LINE OF lt_column.
    DATA temp20 LIKE sy-tabix.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp21> LIKE LINE OF lt_view.
    DATA temp22 LIKE sy-tabix.
    FIELD-SYMBOLS <temp23> LIKE LINE OF lt_view.
    DATA temp24 LIKE sy-tabix.
    FIELD-SYMBOLS <temp25> LIKE LINE OF lt_view.
    DATA temp26 LIKE sy-tabix.
    lt_column = mo_tree->get_columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_column )
                                        exp = 3 ).


    temp18 = sy-tabix.
    READ TABLE lt_column INDEX 2 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp17>-name
                                        exp = `SEATS` ).


    temp20 = sy-tabix.
    READ TABLE lt_column INDEX 2 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp19>-align
                                        exp = `End` ).

    lt_view = mo_tree->view( ).


    temp22 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp21>-c01
                                        exp = `LH` ).


    temp24 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp23>.
    sy-tabix = temp24.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp23>-c02
                                        exp = `300` ).
    " an initial date stays empty


    temp26 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp25>.
    sy-tabix = temp26.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp25>-c03 ).

  ENDMETHOD.

  METHOD toggle_by_event.
    DATA temp27 TYPE string_table.
    DATA temp1 LIKE LINE OF temp27.

    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-toggle.

    CLEAR temp27.

    temp1 = |{ mv_root }|.
    INSERT temp1 INTO TABLE temp27.
    mo_client->mt_arg = temp27.
    cl_abap_unit_assert=>assert_true( mo_tree->handle_event( mo_client ) ).
    cl_abap_unit_assert=>assert_true( mo_tree->get_node( mv_root )-expanded ).
    cl_abap_unit_assert=>assert_true( mo_tree->handle_event( mo_client ) ).
    cl_abap_unit_assert=>assert_false( mo_tree->get_node( mv_root )-expanded ).

    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-expand_all.
    mo_tree->handle_event( mo_client ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->view( ) )
                                        exp = 4 ).

    " the click on a node is left to the report
    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-node.
    cl_abap_unit_assert=>assert_false( mo_tree->handle_event( mo_client ) ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_tree=>get_node_by_event( mo_client )
                                        exp = mv_root ).

  ENDMETHOD.

  METHOD render_and_text.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_xml TYPE string.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp29> LIKE LINE OF lt_text.
    DATA temp30 LIKE sy-tabix.
    FIELD-SYMBOLS <temp31> LIKE LINE OF lt_text.
    DATA temp32 LIKE sy-tabix.
    FIELD-SYMBOLS <temp33> LIKE LINE OF lt_text.
    DATA temp34 LIKE sy-tabix.

    mo_tree->set_column_hidden( `FLDATE` ).

    lt_view = mo_tree->view( ).

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    mo_tree->render( node   = lo_view
                     client = mo_client
                     view   = lt_view ).

    lv_xml = lo_view->stringify( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*rows="{/VIEW}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*EVENT:CGUI_TREE_TOGGLE:${KEY}*EVENT:CGUI_TREE_NODE:${KEY}*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*text="{C02}"*` ).
    " the hidden column is not shown
    cl_abap_unit_assert=>assert_char_np( act = lv_xml
                                         exp = `*{C03}*` ).


    lt_text = mo_tree->to_text( ).


    temp30 = sy-tabix.
    READ TABLE lt_text INDEX 1 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp29>
                                        exp = `Flights` ).


    temp32 = sy-tabix.
    READ TABLE lt_text INDEX 2 ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp31>
                                        exp = `+ LH | LH | 300` ).


    temp34 = sy-tabix.
    READ TABLE lt_text INDEX 3 ASSIGNING <temp33>.
    sy-tabix = temp34.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp33>
                                        exp = `  UA |  | ` ).

  ENDMETHOD.

  METHOD checkboxes_and_functions.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_view.
    DATA temp36 LIKE sy-tabix.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_view.
    DATA temp38 LIKE sy-tabix.
    DATA temp39 TYPE z2ui5_cl_cgui_tree=>ty_t_key.
    DATA temp2 LIKE LINE OF temp39.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_xml TYPE string.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp41> LIKE LINE OF lt_text.
    DATA temp42 LIKE sy-tabix.

    mo_tree->set_checkboxes( )->add_function( name = `SUM`
                                             text = `Sum`
                                             icon = `sap-icon://sum` ).
    " the whole branch of LH
    mo_tree->set_checked( key = mv_root
                          all = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->get_checked( ) )
                                        exp = 3 ).

    " the browser unticks the airline - the collapsed children keep theirs

    lt_view = mo_tree->view( ).


    temp36 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp35>-checked ).


    temp38 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp37>-checked = abap_false.
    mo_tree->sync( lt_view ).

    CLEAR temp39.
    INSERT mv_child INTO TABLE temp39.

    temp2 = mv_child + 1.
    INSERT temp2 INTO TABLE temp39.
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_checked( )
                                        exp = temp39 ).


    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    mo_tree->render( node   = lo_view
                     client = mo_client
                     view   = lt_view ).

    lv_xml = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*text="Sum"*EVENT:SUM*EVENT:CGUI_TREE_EXPAND_ALL*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*EVENT:CGUI_TREE_TOGGLE*selected="{CHECKED}"*EVENT:CGUI_TREE_NODE*` ).

    lt_text = mo_tree->to_text( ).


    temp42 = sy-tabix.
    READ TABLE lt_text INDEX 2 ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp41>
                                        exp = `+ [ ] LH | LH | 300 | ` ).

  ENDMETHOD.

  METHOD lazy_node_requests_children.

    DATA lv_lazy TYPE i.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp43> LIKE LINE OF lt_view.
    DATA temp44 LIKE sy-tabix.
    DATA temp45 TYPE string_table.
    DATA temp3 LIKE LINE OF temp45.
    FIELD-SYMBOLS <temp47> LIKE LINE OF lt_view.
    DATA temp48 LIKE sy-tabix.
    DATA lv_other TYPE i.
    DATA temp49 TYPE z2ui5_cl_cgui_tree=>ty_t_key.
    lv_lazy = mo_tree->add_node( text = `SQ`
                                       lazy = abap_true ).
    " expandable although empty

    lt_view = mo_tree->view( ).


    temp44 = sy-tabix.
    READ TABLE lt_view INDEX 3 ASSIGNING <temp43>.
    sy-tabix = temp44.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp43>-expander
                                        exp = `sap-icon://navigation-right-arrow` ).

    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-toggle.

    CLEAR temp45.

    temp3 = |{ lv_lazy }|.
    INSERT temp3 INTO TABLE temp45.
    mo_client->mt_arg = temp45.
    mo_tree->handle_event( mo_client ).
    cl_abap_unit_assert=>assert_equals( act = mo_tree->take_expand_request( )
                                        exp = lv_lazy ).
    " once
    cl_abap_unit_assert=>assert_initial( mo_tree->take_expand_request( ) ).

    " the report loads the children - the node is open
    mo_tree->add_node( parent = lv_lazy
                       text   = `0002` ).
    lt_view = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 4 ).


    temp48 = sy-tabix.
    READ TABLE lt_view INDEX 3 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp47>-expander
                                        exp = `sap-icon://navigation-down-arrow` ).

    " collapse and open again - no second request
    mo_tree->handle_event( mo_client ).
    mo_tree->handle_event( mo_client ).
    cl_abap_unit_assert=>assert_initial( mo_tree->take_expand_request( ) ).

    " a run without browser finds the loaded node no more, a new one yes
    cl_abap_unit_assert=>assert_initial( mo_tree->get_lazy_nodes( ) ).

    lv_other = mo_tree->add_node( text = `JL`
                                        lazy = abap_true ).

    CLEAR temp49.
    INSERT lv_other INTO TABLE temp49.
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_lazy_nodes( )
                                        exp = temp49 ).
    mo_tree->set_loaded( lv_other ).
    cl_abap_unit_assert=>assert_initial( mo_tree->get_lazy_nodes( ) ).

  ENDMETHOD.

  METHOD checkbox_event_and_branch.
    DATA lo_view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lt_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    FIELD-SYMBOLS <temp51> LIKE LINE OF lt_view.
    DATA temp52 LIKE sy-tabix.
    DATA temp53 TYPE string_table.
    DATA temp4 LIKE LINE OF temp53.

    mo_tree->set_checkboxes( event  = abap_true
                             branch = abap_true ).

    lo_view = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).

    lt_view = mo_tree->view( ).
    mo_tree->render( node   = lo_view
                     client = mo_client
                     view   = lt_view ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_view->stringify( )
                                         exp = `*selected="{CHECKED}"*select="EVENT:CGUI_TREE_CHECKBOX:${KEY}"*` ).

    " the tick on LH arrives with the sync - the branch follows


    temp52 = sy-tabix.
    READ TABLE lt_view INDEX 1 ASSIGNING <temp51>.
    sy-tabix = temp52.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp51>-checked = abap_true.
    mo_tree->sync( lt_view ).
    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-checkbox.

    CLEAR temp53.

    temp4 = |{ mv_root }|.
    INSERT temp4 INTO TABLE temp53.
    mo_client->mt_arg = temp53.
    " left to the report: at_tree_checkbox( )
    cl_abap_unit_assert=>assert_false( mo_tree->handle_event( mo_client ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->get_checked( ) )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD delete_and_change.

    mo_tree->set_node_text( key  = mv_child
                            text = `0401`
        )->set_node_icon( key  = mv_child
                          icon = `sap-icon://flight` ).
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_node( mv_child )-text
                                        exp = `0401` ).
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_parent( mv_child )
                                        exp = mv_root ).

    " the airline with its whole branch
    mo_tree->delete_node( mv_root ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->get_nodes( ) )
                                        exp = 1 ).

  ENDMETHOD.

  METHOD salv_expander_is_lazy.

    " an expander of the stand-in of cl_salv_tree opens without children -
    " the first expand asks for them (EXPAND_EMPTY_FOLDER)
    DATA lo_salv TYPE REF TO z2ui5_cl_cgui_salv_tree.
    DATA lo_node TYPE REF TO z2ui5_cl_cgui_salv_node.
    DATA temp55 TYPE i.
    DATA lv_key LIKE temp55.
    DATA lt_lazy TYPE z2ui5_cl_cgui_tree=>ty_t_key.
    DATA temp1 TYPE xsdboolean.
    DATA temp2 LIKE sy-subrc.
    CREATE OBJECT lo_salv TYPE z2ui5_cl_cgui_salv_tree.

    lo_node = lo_salv->get_nodes( )->add_node( text     = `Folder`
                                                     expander = abap_true ).

    temp55 = lo_node->get_key( ).

    lv_key = temp55.

    lt_lazy = lo_salv->get_tree( )->get_lazy_nodes( ).


    READ TABLE lt_lazy WITH KEY table_line = lv_key TRANSPORTING NO FIELDS.
    temp2 = sy-subrc.
    temp1 = boolc( temp2 = 0 ).
    cl_abap_unit_assert=>assert_true( temp1 ).

  ENDMETHOD.

ENDCLASS.
