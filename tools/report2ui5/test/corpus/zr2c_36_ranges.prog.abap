*&---------------------------------------------------------------------*
*& Report ZR2C_36_RANGES
*&---------------------------------------------------------------------*
*& A product list filtered with select-options on local data: IN on a
*& range of names and of prices, then sorted, the duplicates removed
*& and the hits counted
*&---------------------------------------------------------------------*
REPORT zr2c_36_ranges.

TYPES:
  BEGIN OF ty_product,
    name  TYPE c LENGTH 12,
    group TYPE c LENGTH 4,
    price TYPE i,
  END OF ty_product.

DATA gs_product TYPE ty_product.
DATA gt_product TYPE STANDARD TABLE OF ty_product WITH DEFAULT KEY.

SELECT-OPTIONS: s_name  FOR gs_product-name,
                s_price FOR gs_product-price.
PARAMETERS p_uniq AS CHECKBOX DEFAULT 'X'.

INITIALIZATION.
  s_price-sign = 'I'. s_price-option = 'BT'. s_price-low = 10. s_price-high = 500.
  APPEND s_price.

START-OF-SELECTION.
  gt_product = VALUE #( ( name = 'LAMP'  group = 'HOME' price = 45 )
                        ( name = 'CHAIR' group = 'HOME' price = 120 )
                        ( name = 'LAMP'  group = 'HOME' price = 45 )
                        ( name = 'BIKE'  group = 'OUT'  price = 640 )
                        ( name = 'TENT'  group = 'OUT'  price = 210 ) ).

  DELETE gt_product WHERE NOT ( name IN s_name AND price IN s_price ).
  SORT gt_product BY group name.
  IF p_uniq = abap_true.
    DELETE ADJACENT DUPLICATES FROM gt_product COMPARING name.
  ENDIF.

  WRITE: / |{ lines( gt_product ) } product(s) in the selection|.
  ULINE.
  LOOP AT gt_product INTO gs_product.
    WRITE: / gs_product-group, gs_product-name, gs_product-price.
  ENDLOOP.
