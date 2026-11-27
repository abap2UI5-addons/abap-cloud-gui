CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.

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

    result = |EVENT:{ val }{ COND #( WHEN t_arg IS NOT INITIAL THEN |:{ concat_lines_of( table = t_arg sep = `,` ) }| ) }|.

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

    mo_client = NEW #( ).
    mo_tree = z2ui5_cl_cgui_tree=>factory( )->set_title( `Flights` ).
    mv_root = mo_tree->add_node( text = `LH`
                                 data = VALUE ty_s_row( carrid = `LH` seats = 300 ) ).
    mv_child = mo_tree->add_node( parent = mv_root
                                  text   = `0400`
                                  data   = VALUE ty_s_row( carrid = `LH` seats = 120 )
                                  value  = `7` ).
    mo_tree->add_node( parent = mv_child
                       text   = `20261001`
                       data   = VALUE ty_s_row( carrid = `LH` seats = 60 ) ).
    mo_tree->add_node( `UA` ).

  ENDMETHOD.

  METHOD collapsed_shows_roots.

    DATA(lt_view) = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 1 ]-expander
                                        exp = `sap-icon://navigation-right-arrow` ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 1 ]-icon
                                        exp = `sap-icon://folder-blank` ).
    " a leaf: no expander, its text where the others start
    cl_abap_unit_assert=>assert_initial( lt_view[ 2 ]-expander ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 2 ]-indent
                                        exp = `32px` ).

  ENDMETHOD.

  METHOD expand_shows_children.

    mo_tree->expand( mv_root ).
    DATA(lt_view) = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_view )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 2 ]-text
                                        exp = `0400` ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 2 ]-level
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

    DATA(lt_column) = mo_tree->get_columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_column )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_column[ 2 ]-name
                                        exp = `SEATS` ).
    cl_abap_unit_assert=>assert_equals( act = lt_column[ 2 ]-align
                                        exp = `End` ).
    DATA(lt_view) = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 1 ]-c01
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 1 ]-c02
                                        exp = `300` ).
    " an initial date stays empty
    cl_abap_unit_assert=>assert_initial( lt_view[ 1 ]-c03 ).

  ENDMETHOD.

  METHOD toggle_by_event.

    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-toggle.
    mo_client->mt_arg = VALUE #( ( |{ mv_root }| ) ).
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

    mo_tree->set_column_hidden( `FLDATE` ).
    DATA(lt_view) = mo_tree->view( ).
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    mo_tree->render( node   = lo_view
                     client = mo_client
                     view   = lt_view ).
    DATA(lv_xml) = lo_view->stringify( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*rows="{/VIEW}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*EVENT:CGUI_TREE_TOGGLE:${KEY}*EVENT:CGUI_TREE_NODE:${KEY}*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*text="{C02}"*` ).
    " the hidden column is not shown
    cl_abap_unit_assert=>assert_char_np( act = lv_xml
                                         exp = `*{C03}*` ).

    DATA(lt_text) = mo_tree->to_text( ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 1 ]
                                        exp = `Flights` ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 2 ]
                                        exp = `+ LH | LH | 300` ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 3 ]
                                        exp = `  UA |  | ` ).

  ENDMETHOD.

  METHOD checkboxes_and_functions.

    mo_tree->set_checkboxes( )->add_function( name = `SUM`
                                             text = `Sum`
                                             icon = `sap-icon://sum` ).
    " the whole branch of LH
    mo_tree->set_checked( key = mv_root
                          all = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_tree->get_checked( ) )
                                        exp = 3 ).

    " the browser unticks the airline - the collapsed children keep theirs
    DATA(lt_view) = mo_tree->view( ).
    cl_abap_unit_assert=>assert_true( lt_view[ 1 ]-checked ).
    lt_view[ 1 ]-checked = abap_false.
    mo_tree->sync( lt_view ).
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_checked( )
                                        exp = VALUE z2ui5_cl_cgui_tree=>ty_t_key( ( mv_child ) ( mv_child + 1 ) ) ).

    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    mo_tree->render( node   = lo_view
                     client = mo_client
                     view   = lt_view ).
    DATA(lv_xml) = lo_view->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*text="Sum"*EVENT:SUM*EVENT:CGUI_TREE_EXPAND_ALL*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_xml
                                         exp = `*EVENT:CGUI_TREE_TOGGLE*selected="{CHECKED}"*EVENT:CGUI_TREE_NODE*` ).
    DATA(lt_text) = mo_tree->to_text( ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 2 ]
                                        exp = `+ [ ] LH | LH | 300 | ` ).

  ENDMETHOD.

  METHOD lazy_node_requests_children.

    DATA(lv_lazy) = mo_tree->add_node( text = `SQ`
                                       lazy = abap_true ).
    " expandable although empty
    DATA(lt_view) = mo_tree->view( ).
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 3 ]-expander
                                        exp = `sap-icon://navigation-right-arrow` ).

    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-toggle.
    mo_client->mt_arg = VALUE #( ( |{ lv_lazy }| ) ).
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
    cl_abap_unit_assert=>assert_equals( act = lt_view[ 3 ]-expander
                                        exp = `sap-icon://navigation-down-arrow` ).

    " collapse and open again - no second request
    mo_tree->handle_event( mo_client ).
    mo_tree->handle_event( mo_client ).
    cl_abap_unit_assert=>assert_initial( mo_tree->take_expand_request( ) ).

    " a run without browser finds the loaded node no more, a new one yes
    cl_abap_unit_assert=>assert_initial( mo_tree->get_lazy_nodes( ) ).
    DATA(lv_other) = mo_tree->add_node( text = `JL`
                                        lazy = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = mo_tree->get_lazy_nodes( )
                                        exp = VALUE z2ui5_cl_cgui_tree=>ty_t_key( ( lv_other ) ) ).
    mo_tree->set_loaded( lv_other ).
    cl_abap_unit_assert=>assert_initial( mo_tree->get_lazy_nodes( ) ).

  ENDMETHOD.

  METHOD checkbox_event_and_branch.

    mo_tree->set_checkboxes( event  = abap_true
                             branch = abap_true ).
    DATA(lo_view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( `VBox` ).
    DATA(lt_view) = mo_tree->view( ).
    mo_tree->render( node   = lo_view
                     client = mo_client
                     view   = lt_view ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_view->stringify( )
                                         exp = `*selected="{CHECKED}"*select="EVENT:CGUI_TREE_CHECKBOX:${KEY}"*` ).

    " the tick on LH arrives with the sync - the branch follows
    lt_view[ 1 ]-checked = abap_true.
    mo_tree->sync( lt_view ).
    mo_client->mv_event = z2ui5_cl_cgui_tree=>cs_event-checkbox.
    mo_client->mt_arg = VALUE #( ( |{ mv_root }| ) ).
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
    DATA(lo_salv) = NEW z2ui5_cl_cgui_salv_tree( ).
    DATA(lo_node) = lo_salv->get_nodes( )->add_node( text     = `Folder`
                                                     expander = abap_true ).
    DATA(lv_key) = CONV i( lo_node->get_key( ) ).
    DATA(lt_lazy) = lo_salv->get_tree( )->get_lazy_nodes( ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_lazy[ table_line = lv_key ] ) ) ).

  ENDMETHOD.

ENDCLASS.
