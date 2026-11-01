*&---------------------------------------------------------------------*
*& Report ZR2C_03_FORMS
*&---------------------------------------------------------------------*
*& An order simulation in FORMs: USING, CHANGING, TABLES, VALUE( ),
*& RANGES and a local work area - no database access
*&---------------------------------------------------------------------*
REPORT zr2c_03_forms.

TYPES: BEGIN OF ty_item,
         pos      TYPE i,
         product  TYPE c LENGTH 10,
         quantity TYPE i,
         price    TYPE p LENGTH 10 DECIMALS 2,
       END OF ty_item,
       ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

CONSTANTS gc_vat TYPE p LENGTH 3 DECIMALS 2 VALUE '0.19'.

DATA: gt_items    TYPE ty_items,
      gs_template TYPE ty_item,
      gv_net   TYPE p LENGTH 12 DECIMALS 2,
      gv_gross TYPE p LENGTH 12 DECIMALS 2.

PARAMETERS: p_items TYPE i DEFAULT 5 OBLIGATORY,
            p_disc  TYPE p LENGTH 3 DECIMALS 2 DEFAULT '0.05',
            p_vat   AS CHECKBOX DEFAULT 'X'.

AT SELECTION-SCREEN ON p_items.
  IF p_items < 1 OR p_items > 50.
    MESSAGE 'Between 1 and 50 items' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM build_items USING p_items CHANGING gt_items.
  PERFORM total TABLES gt_items USING p_disc CHANGING gv_net.
  IF p_vat = abap_true.
    gv_gross = gv_net * ( 1 + gc_vat ).
  ELSE.
    gv_gross = gv_net.
  ENDIF.
  PERFORM output.

*&---------------------------------------------------------------------*
*& Form build_items
*&---------------------------------------------------------------------*
FORM build_items USING VALUE(iv_count) TYPE i
                 CHANGING ct_items TYPE ty_items.
  DATA ls_item TYPE ty_item.
  CLEAR ct_items.
  DO iv_count TIMES.
    ls_item-pos      = sy-index.
    ls_item-product  = |PROD-{ sy-index }|.
    ls_item-quantity = sy-index * 2.
    ls_item-price    = 10 + sy-index.
    APPEND ls_item TO ct_items.
  ENDDO.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form total
*&---------------------------------------------------------------------*
FORM total TABLES it_items STRUCTURE gs_template
           USING iv_discount TYPE p
           CHANGING cv_net TYPE p.
  DATA: ls_item TYPE ty_item,
        lr_pos  TYPE RANGE OF i.
  RANGES lr_big FOR ls_item-quantity.

  lr_pos = VALUE #( ( sign = 'I' option = 'BT' low = 1 high = 1000 ) ).
  lr_big = VALUE #( ( sign = 'I' option = 'GE' low = 10 ) ).
  cv_net = 0.
  LOOP AT it_items INTO ls_item WHERE pos IN lr_pos.
    IF ls_item-quantity IN lr_big.
      cv_net = cv_net + ls_item-quantity * ls_item-price * ( 1 - iv_discount ).
    ELSE.
      cv_net = cv_net + ls_item-quantity * ls_item-price.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form output
*&---------------------------------------------------------------------*
FORM output.
  DATA ls_item TYPE ty_item.
  LOOP AT gt_items INTO ls_item.
    PERFORM write_item USING ls_item.
  ENDLOOP.
  ULINE.
  WRITE: / 'Net:', gv_net,
         / 'Gross:', gv_gross.
ENDFORM.

FORM write_item USING is_item TYPE ty_item.
  WRITE: / is_item-pos, is_item-product, is_item-quantity, is_item-price.
ENDFORM.
