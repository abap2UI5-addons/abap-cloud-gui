CLASS z2ui5_cl_cgui_r2c_28 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_item,
        name  TYPE string,
        price TYPE p LENGTH 8 DECIMALS 2,
      END OF ty_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    " selection screen
    DATA p_title TYPE string.
    DATA p_disc  TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_28 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Price List as HTML` ).
    p_title = 'Price list'.
    p_disc = 10.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_title
                       text       = `Title`
                       lower_case = abap_true
        )->parameter( val  = p_disc
                      text = `Discount in %` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA(lt_item) = VALUE ty_t_item( ( name = 'Coffee' price = '2.50' )
                                     ( name = 'Tea'    price = '1.80' )
                                     ( name = 'Cake'   price = '3.20' ) ).

    DATA(lv_rows) = ``.
    LOOP AT lt_item INTO DATA(ls_item).
      DATA(lv_net) = ls_item-price * ( 100 - p_disc ) / 100.
      lv_rows = lv_rows && |<tr><td>{ ls_item-name }</td><td>{ ls_item-price }</td><td>{ lv_net }</td></tr>|.
    ENDLOOP.

    DATA(lv_html) = |<html><body><h2>{ p_title }</h2>| &&
                    |<p>{ p_disc } % off for members</p>| &&
                    |<table><tr><th>Item</th><th>Price</th><th>Members</th></tr>{ lv_rows }</table>| &&
                    |</body></html>|.

    z2ui5_cl_cgui_abap_browser=>show_html( title       = p_title
                                html_string = lv_html
                                container   = z2ui5_cl_cgui_gui_container=>default_screen ).
    write( space ).

  ENDMETHOD.

ENDCLASS.
