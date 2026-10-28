"! Who hears the clicks of the ALV tree of a report besides at_tree_node( )
"! and at_tree_checkbox( ) - the stand-in of cl_salv_tree, which passes
"! them on as its events double_click and checkbox_change
INTERFACE z2ui5_if_cgui_tree_handler PUBLIC.

  METHODS on_node
    IMPORTING
      key TYPE i.

  METHODS on_checkbox
    IMPORTING
      key     TYPE i
      checked TYPE abap_bool.

ENDINTERFACE.
