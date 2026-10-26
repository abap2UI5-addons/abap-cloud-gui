CLASS z2ui5_cl_cgui_r2c_46 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA gt_node TYPE STANDARD TABLE OF snodetext WITH DEFAULT KEY.
    DATA gs_node TYPE snodetext.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    METHODS add
      IMPORTING
        iv_level TYPE i
        iv_name  TYPE c
        iv_text  TYPE c.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_46 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Flights as a tree list` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_node,
           gs_node.

    add( iv_level = 1
         iv_name  = 'Airlines'
         iv_text  = '' ).
    add( iv_level = 2
         iv_name  = 'LH'
         iv_text  = 'Lufthansa' ).
    add( iv_level = 3
         iv_name  = '0400'
         iv_text  = 'Frankfurt - New York' ).
    add( iv_level = 3
         iv_name  = '0402'
         iv_text  = 'Frankfurt - New York' ).
    add( iv_level = 2
         iv_name  = 'AA'
         iv_text  = 'American Airlines' ).
    add( iv_level = 3
         iv_name  = '0017'
         iv_text  = 'New York - San Francisco' ).

    DATA(lo_r2c_tree1) = tree( ).
    DATA lt_r2c_tree_parent1 TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    LOOP AT gt_node ASSIGNING FIELD-SYMBOL(<ls_r2c_tree_node1>).
      DATA(lv_r2c_tree_row1) = sy-tabix.
      DATA(lv_r2c_tree_level1) = nmax( val1 = 1 val2 = CONV i( <ls_r2c_tree_node1>-tlevel ) ).
      WHILE lines( lt_r2c_tree_parent1 ) >= lv_r2c_tree_level1.
        DELETE lt_r2c_tree_parent1 INDEX lines( lt_r2c_tree_parent1 ).
      ENDWHILE.
      INSERT lo_r2c_tree1->add_node( parent   = COND #( WHEN lt_r2c_tree_parent1 IS NOT INITIAL THEN lt_r2c_tree_parent1[ lines( lt_r2c_tree_parent1 ) ] )
                                       text     = condense( |{ <ls_r2c_tree_node1>-name } { <ls_r2c_tree_node1>-text }| )
                                       expanded = abap_true
                                       value    = |{ lv_r2c_tree_row1 }| ) INTO TABLE lt_r2c_tree_parent1.
    ENDLOOP.

  ENDMETHOD.

  METHOD add.

    CLEAR gs_node.
    gs_node-tlevel = iv_level.
    gs_node-name   = iv_name.
    gs_node-text   = iv_text.
    APPEND gs_node TO gt_node.

  ENDMETHOD.

ENDCLASS.
