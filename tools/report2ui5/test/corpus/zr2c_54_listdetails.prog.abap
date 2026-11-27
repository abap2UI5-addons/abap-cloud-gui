*&---------------------------------------------------------------------*
*& Report ZR2C_54_LISTDETAILS
*&---------------------------------------------------------------------*
*& The details of the list the converter used to lose: HIDE of a header
*& line and in a local class (the value when HIDE runs), FORMAT before a
*& PERFORM, the format additions of WRITE, sy-lisel with an offset in a
*& FORM called from AT LINE-SELECTION, a message type in a variable, the
*& RETURN_TAB of an F4, checkbox and radio button defaults of abap_true
*& and a USING parameter written through a field symbol
*&---------------------------------------------------------------------*
REPORT zr2c_54_listdetails NO STANDARD PAGE HEADING.

TYPES: BEGIN OF ty_item,
         id     TYPE i,
         name   TYPE c LENGTH 20,
         amount TYPE p LENGTH 8 DECIMALS 2,
         curr   TYPE c LENGTH 5,
         due    TYPE d,
       END OF ty_item,
       ty_t_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

TYPES: BEGIN OF ty_value,
         id   TYPE c LENGTH 3,
         text TYPE c LENGTH 20,
       END OF ty_value.

DATA gt_item TYPE ty_item OCCURS 0 WITH HEADER LINE.
DATA: gt_value TYPE STANDARD TABLE OF ty_value WITH DEFAULT KEY,
      gt_ret   TYPE STANDARD TABLE OF ty_value WITH DEFAULT KEY,
      gv_key   TYPE c LENGTH 4,
      gv_type  TYPE c LENGTH 1 VALUE 'S'.

PARAMETERS: p_id    TYPE c LENGTH 3,
            p_cb    AS CHECKBOX DEFAULT abap_true,
            p_list  RADIOBUTTON GROUP out,
            p_total RADIOBUTTON GROUP out DEFAULT abap_true.

CLASS lcl_lines DEFINITION.
  PUBLIC SECTION.
    METHODS write_totals.
ENDCLASS.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_id.
  gt_value = VALUE #( ( id = 'A01' text = 'First' ) ( id = 'B02' text = 'Second' ) ).
  CLEAR gt_ret.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'ID'
      value_org   = 'S'
    TABLES
      value_tab   = gt_value
      return_tab  = gt_ret
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc = 0.
    READ TABLE gt_ret INTO DATA(ls_ret) INDEX 1.
    p_id = ls_ret-id.
  ENDIF.

START-OF-SELECTION.
  gt_item[] = VALUE ty_t_item( ( id = 1 name = 'Rent'  amount = '1200.50' curr = 'EUR' due = '20260105' )
                               ( id = 2 name = 'Train' amount = '89.00'   curr = 'JPY' due = '20260212' ) ).
  PERFORM mark_due USING gt_item[].

  FORMAT COLOR COL_HEADING.
  PERFORM header.
  FORMAT COLOR OFF.

  LOOP AT gt_item.
    WRITE: / gt_item-name,
             gt_item-amount CURRENCY gt_item-curr NO-ZERO RIGHT-JUSTIFIED,
             gt_item-due DD/MM/YYYY QUICKINFO 'Due date'.
    HIDE: gt_item-id, gt_item-name.
  ENDLOOP.

  IF p_total = abap_true.
    NEW lcl_lines( )->write_totals( ).
  ENDIF.

  MESSAGE 'List written' TYPE gv_type.

AT LINE-SELECTION.
  PERFORM detail.

FORM header.
  WRITE: / 'Name', 'Amount', 'Due'.
  ULINE.
ENDFORM.

FORM detail.
  gv_key = sy-lisel(4).
  WRITE: / 'Item', gt_item-id, gt_item-name, 'line', sy-lilli, 'starts with', gv_key.
ENDFORM.

FORM mark_due USING ut_item TYPE ty_t_item.
  FIELD-SYMBOLS <ls_item> TYPE ty_item.

  LOOP AT ut_item ASSIGNING <ls_item>.
    IF <ls_item>-due IS INITIAL.
      <ls_item>-due = sy-datum.
    ENDIF.
  ENDLOOP.
ENDFORM.

CLASS lcl_lines IMPLEMENTATION.
  METHOD write_totals.
    DATA lv_total TYPE p LENGTH 8 DECIMALS 2.

    LOOP AT gt_item.
      lv_total = lv_total + gt_item-amount.
    ENDLOOP.
    SKIP.
    gt_item-id = 0.
    gt_item-name = 'Total'.
    WRITE: / 'Total', lv_total INTENSIFIED.
    HIDE: gt_item-id, gt_item-name.
  ENDMETHOD.
ENDCLASS.
