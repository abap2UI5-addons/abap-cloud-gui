CLASS z2ui5_cl_cgui_r2c_34 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_sale,
        region TYPE c LENGTH 5,
        month  TYPE n LENGTH 2,
        amount TYPE p LENGTH 10 DECIMALS 2,
      END OF ty_sale.

    " global data of the report
    DATA gt_sale   TYPE STANDARD TABLE OF ty_sale WITH DEFAULT KEY.
    DATA gv_region TYPE p LENGTH 10 DECIMALS 2.
    DATA gv_all    TYPE p LENGTH 10 DECIMALS 2.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_34 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Sales per Region` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA temp1 LIKE gt_sale.
    DATA temp2 LIKE LINE OF temp1.
    DATA ls_sale LIKE LINE OF gt_sale.
    CLEAR temp1.

    temp2-region = 'NORTH'.
    temp2-month = '01'.
    temp2-amount = '120.00'.
    INSERT temp2 INTO TABLE temp1.
    temp2-region = 'SOUTH'.
    temp2-month = '01'.
    temp2-amount = '80.50'.
    INSERT temp2 INTO TABLE temp1.
    temp2-region = 'NORTH'.
    temp2-month = '02'.
    temp2-amount = '99.90'.
    INSERT temp2 INTO TABLE temp1.
    temp2-region = 'SOUTH'.
    temp2-month = '02'.
    temp2-amount = '150.00'.
    INSERT temp2 INTO TABLE temp1.
    temp2-region = 'NORTH'.
    temp2-month = '01'.
    temp2-amount = '30.00'.
    INSERT temp2 INTO TABLE temp1.
    gt_sale = temp1.
    SORT gt_sale BY region month.


    LOOP AT gt_sale INTO ls_sale.
      AT FIRST.
        list( )->new_line(
            )->write( 'Sales per region' ).
        list( )->uline( ).
      ENDAT.
      AT NEW region.
        list( )->new_line(
            )->write( ls_sale-region ).
      ENDAT.
      list( )->new_line(
          )->write( val = ls_sale-month
                    pos = 5
          )->write( ls_sale-amount ).
      gv_region = gv_region + ls_sale-amount.
      gv_all = gv_all + ls_sale-amount.
      AT END OF region.
        list( )->new_line(
            )->write( val = 'Total'
                      pos = 5
            )->write( val   = gv_region
                      color = z2ui5_cl_cgui_list=>cs_color-total ).
        list( )->skip( ).
        CLEAR gv_region.
      ENDAT.
      AT LAST.
        list( )->uline( ).
        list( )->new_line(
            )->write( 'All regions'
            )->write( val   = gv_all
                      color = z2ui5_cl_cgui_list=>cs_color-total ).
      ENDAT.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
