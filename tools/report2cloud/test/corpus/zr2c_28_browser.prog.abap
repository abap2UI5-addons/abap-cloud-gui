*&---------------------------------------------------------------------*
*& Report ZR2C_28_BROWSER
*&---------------------------------------------------------------------*
*& A price list as an HTML page: cl_abap_browser shows it on the screen
*& itself (cl_gui_container=>default_screen), WRITE: space makes the
*& list screen come up under it
*&---------------------------------------------------------------------*
REPORT zr2c_28_browser.

TYPES:
  BEGIN OF ty_item,
    name  TYPE string,
    price TYPE p LENGTH 8 DECIMALS 2,
  END OF ty_item.
TYPES ty_t_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

PARAMETERS: p_title TYPE string LOWER CASE DEFAULT 'Price list',
            p_disc  TYPE i DEFAULT 10.

START-OF-SELECTION.
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

  cl_abap_browser=>show_html( title       = p_title
                              html_string = lv_html
                              container   = cl_gui_container=>default_screen ).
  WRITE: space.
