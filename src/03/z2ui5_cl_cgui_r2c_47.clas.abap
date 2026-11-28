CLASS z2ui5_cl_cgui_r2c_47 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_row,
        carrid TYPE c LENGTH 3,
        connid TYPE n LENGTH 4,
        seats  TYPE i,
      END OF ty_row.

    " global data of the report
    DATA gt_empty TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA go_tree  TYPE REF TO z2ui5_cl_cgui_salv_tree.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_roundtrip_start REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_47 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Flights in a SALV tree` ).

  ENDMETHOD.

  METHOD start_of_selection.
    DATA lo_settings TYPE REF TO z2ui5_cl_cgui_salv_config.
    DATA lo_nodes TYPE REF TO z2ui5_cl_cgui_salv_nodes.
    DATA lo_lh TYPE REF TO z2ui5_cl_cgui_salv_node.
    DATA temp1 TYPE ty_row.
    DATA temp2 TYPE ty_row.
    DATA lo_aa TYPE REF TO z2ui5_cl_cgui_salv_node.
    DATA temp3 TYPE ty_row.
    DATA lo_events TYPE REF TO z2ui5_cl_cgui_salv_tree.
    DATA temp4 TYPE REF TO lcl_handler.

    TRY.
        z2ui5_cl_cgui_salv_tree=>factory( IMPORTING r_salv_tree = go_tree
                               CHANGING  t_table     = gt_empty ).
      CATCH z2ui5_cx_cgui_salv.
        RETURN.
    ENDTRY.


    lo_settings = go_tree->get_tree_settings( ).
    lo_settings->set_hierarchy_header( 'Airline' ).
    lo_settings->set_header( 'Seats per flight' ).
    go_tree->get_columns( )->get_column( 'SEATS' )->set_long_text( 'Free seats' ).
    go_tree->get_columns( )->get_column( 'CARRID' )->set_visible( abap_false ).


    lo_nodes = go_tree->get_nodes( ).

    lo_lh = lo_nodes->add_node( related_node = ''
                                      relationship = z2ui5_if_cgui_salv_c=>node_relation-last_child
                                      text         = 'Lufthansa'
                                      folder       = abap_true ).

    CLEAR temp1.
    temp1-carrid = 'LH'.
    temp1-connid = '0400'.
    temp1-seats = 12.
    lo_nodes->add_node( related_node = lo_lh->get_key( )
                        relationship = z2ui5_if_cgui_salv_c=>node_relation-last_child
                        data_row     = temp1
                        text         = '0400' ).

    CLEAR temp2.
    temp2-carrid = 'LH'.
    temp2-connid = '0402'.
    temp2-seats = 3.
    lo_nodes->add_node( related_node = lo_lh->get_key( )
                        relationship = z2ui5_if_cgui_salv_c=>node_relation-last_child
                        data_row     = temp2
                        text         = '0402' ).

    lo_aa = lo_nodes->add_node( related_node = lo_lh->get_key( )
                                      relationship = z2ui5_if_cgui_salv_c=>node_relation-next_sibling
                                      text         = 'American Airlines'
                                      folder       = abap_true ).

    CLEAR temp3.
    temp3-carrid = 'AA'.
    temp3-connid = '0017'.
    temp3-seats = 40.
    lo_nodes->add_node( related_node = lo_aa->get_key( )
                        relationship = z2ui5_if_cgui_salv_c=>node_relation-last_child
                        data_row     = temp3
                        text         = '0017' ).
    lo_nodes->expand_all( ).


    lo_events = go_tree->get_event( ).

    CREATE OBJECT temp4 TYPE lcl_handler.
    lo_events->set_handler( handler = temp4
                            method  = `ON_DOUBLE_CLICK`
                            event   = `DOUBLE_CLICK` ).

    go_tree->display( ).

  ENDMETHOD.

  METHOD at_roundtrip_start.

    lcl_r2c=>app = me.

  ENDMETHOD.

ENDCLASS.
