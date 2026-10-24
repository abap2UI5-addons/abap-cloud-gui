*&---------------------------------------------------------------------*
*& Report ZR2C_34_CONTROLLEVELS
*&---------------------------------------------------------------------*
*& Sales per region and month with the classic control levels: AT FIRST,
*& AT NEW, AT END OF and AT LAST over a sorted table - the totals are
*& added up in the loop (SUM is gone on ABAP Cloud)
*&---------------------------------------------------------------------*
REPORT zr2c_34_controllevels.

TYPES:
  BEGIN OF ty_sale,
    region TYPE c LENGTH 5,
    month  TYPE n LENGTH 2,
    amount TYPE p LENGTH 10 DECIMALS 2,
  END OF ty_sale.

DATA gt_sale TYPE STANDARD TABLE OF ty_sale WITH DEFAULT KEY.
DATA gv_region TYPE p LENGTH 10 DECIMALS 2.
DATA gv_all TYPE p LENGTH 10 DECIMALS 2.

START-OF-SELECTION.
  gt_sale = VALUE #( ( region = 'NORTH' month = '01' amount = '120.00' )
                     ( region = 'SOUTH' month = '01' amount = '80.50' )
                     ( region = 'NORTH' month = '02' amount = '99.90' )
                     ( region = 'SOUTH' month = '02' amount = '150.00' )
                     ( region = 'NORTH' month = '01' amount = '30.00' ) ).
  SORT gt_sale BY region month.

  LOOP AT gt_sale INTO DATA(ls_sale).
    AT FIRST.
      WRITE: / 'Sales per region'.
      ULINE.
    ENDAT.
    AT NEW region.
      FORMAT INTENSIFIED ON.
      WRITE: / ls_sale-region.
      FORMAT INTENSIFIED OFF.
    ENDAT.
    WRITE: /5 ls_sale-month, ls_sale-amount.
    gv_region = gv_region + ls_sale-amount.
    gv_all = gv_all + ls_sale-amount.
    AT END OF region.
      WRITE: /5 'Total', gv_region COLOR COL_TOTAL.
      SKIP.
      CLEAR gv_region.
    ENDAT.
    AT LAST.
      ULINE.
      WRITE: / 'All regions', gv_all COLOR COL_TOTAL.
    ENDAT.
  ENDLOOP.
