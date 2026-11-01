*&---------------------------------------------------------------------*
*& Report ZR2C_32_XMLPOPUP
*&---------------------------------------------------------------------*
*& An order as XML in a window of its own (cl_abap_browser=>show_xml
*& without a container), and a note on the list behind it
*&---------------------------------------------------------------------*
REPORT zr2c_32_xmlpopup.

PARAMETERS: p_order TYPE c LENGTH 10 DEFAULT '4711',
            p_qty   TYPE i DEFAULT 3.

START-OF-SELECTION.
  DATA(lv_xml) = |<order id="{ p_order }"><item qty="{ p_qty }">Paper</item></order>|.
  cl_abap_browser=>show_xml( xml_string = lv_xml
                             title      = |Order { p_order }| ).
  WRITE: / |Order { p_order } with { p_qty } item(s) shown as XML|.
