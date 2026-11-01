CLASS z2ui5_cl_cgui_r2c_32 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " selection screen
    DATA p_order TYPE c LENGTH 10.
    DATA p_qty   TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_32 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `An Order as XML` ).
    p_order = '4711'.
    p_qty = 3.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_order
                       text = `Order`
        )->parameter( val  = p_qty
                      text = `Quantity` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA(lv_xml) = |<order id="{ p_order }"><item qty="{ p_qty }">Paper</item></order>|.
    z2ui5_cl_cgui_abap_browser=>show_xml( xml_string = lv_xml
                               title      = |Order { p_order }| ).
    list( )->new_line(
        )->write( |Order { p_order } with { p_qty } item(s) shown as XML| ).

  ENDMETHOD.

ENDCLASS.
