" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_47.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS lcl_handler DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_r2c_47 DEFINITION LOCAL FRIENDS lcl_handler.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    CLASS-METHODS on_double_click FOR EVENT double_click OF z2ui5_cl_cgui_salv_tree
      IMPORTING node_key columnname.
ENDCLASS.


CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    DATA(lo_node) = lcl_r2c=>app->go_tree->get_nodes( )->get_node( node_key ).
    lcl_r2c=>app->message( |{ lo_node->get_text( ) } picked| ).
  ENDMETHOD.
ENDCLASS.
