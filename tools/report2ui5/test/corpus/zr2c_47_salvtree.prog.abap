*&---------------------------------------------------------------------*
*& Report ZR2C_47_SALVTREE
*&---------------------------------------------------------------------*
*& CL_SALV_TREE: the nodes with get_nodes( )->add_node( ), the tree
*& settings, a column text, a handler of double_click
*&---------------------------------------------------------------------*
REPORT zr2c_47_salvtree.

TYPES:
  BEGIN OF ty_row,
    carrid TYPE c LENGTH 3,
    connid TYPE n LENGTH 4,
    seats  TYPE i,
  END OF ty_row.

DATA gt_empty TYPE STANDARD TABLE OF ty_row.
DATA go_tree TYPE REF TO cl_salv_tree.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click FOR EVENT double_click OF cl_salv_events_tree
      IMPORTING node_key columnname.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    DATA(lo_node) = go_tree->get_nodes( )->get_node( node_key ).
    MESSAGE |{ lo_node->get_text( ) } picked| TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  TRY.
      cl_salv_tree=>factory( IMPORTING r_salv_tree = go_tree
                             CHANGING  t_table     = gt_empty ).
    CATCH cx_salv_error.
      RETURN.
  ENDTRY.

  DATA(lo_settings) = go_tree->get_tree_settings( ).
  lo_settings->set_hierarchy_header( 'Airline' ).
  lo_settings->set_header( 'Seats per flight' ).
  go_tree->get_columns( )->get_column( 'SEATS' )->set_long_text( 'Free seats' ).
  go_tree->get_columns( )->get_column( 'CARRID' )->set_visible( abap_false ).

  DATA(lo_nodes) = go_tree->get_nodes( ).
  DATA(lo_lh) = lo_nodes->add_node( related_node = ''
                                    relationship = cl_gui_column_tree=>relat_last_child
                                    text         = 'Lufthansa'
                                    folder       = abap_true ).
  lo_nodes->add_node( related_node = lo_lh->get_key( )
                      relationship = cl_gui_column_tree=>relat_last_child
                      data_row     = VALUE ty_row( carrid = 'LH' connid = '0400' seats = 12 )
                      text         = '0400' ).
  lo_nodes->add_node( related_node = lo_lh->get_key( )
                      relationship = cl_gui_column_tree=>relat_last_child
                      data_row     = VALUE ty_row( carrid = 'LH' connid = '0402' seats = 3 )
                      text         = '0402' ).
  DATA(lo_aa) = lo_nodes->add_node( related_node = lo_lh->get_key( )
                                    relationship = cl_gui_column_tree=>relat_next_sibling
                                    text         = 'American Airlines'
                                    folder       = abap_true ).
  lo_nodes->add_node( related_node = lo_aa->get_key( )
                      relationship = cl_gui_column_tree=>relat_last_child
                      data_row     = VALUE ty_row( carrid = 'AA' connid = '0017' seats = 40 )
                      text         = '0017' ).
  lo_nodes->expand_all( ).

  DATA(lo_events) = go_tree->get_event( ).
  SET HANDLER lcl_handler=>on_double_click FOR lo_events.

  go_tree->display( ).
