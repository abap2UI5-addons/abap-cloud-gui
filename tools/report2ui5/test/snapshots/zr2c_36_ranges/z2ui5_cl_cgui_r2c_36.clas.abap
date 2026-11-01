CLASS z2ui5_cl_cgui_r2c_36 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_product,
        name  TYPE c LENGTH 12,
        group TYPE c LENGTH 4,
        price TYPE i,
      END OF ty_product.

    " global data of the report
    DATA gs_product TYPE ty_product.
    DATA gt_product TYPE STANDARD TABLE OF ty_product WITH DEFAULT KEY.

    " selection screen
    DATA s_name  LIKE RANGE OF gs_product-name.
    DATA s_price LIKE RANGE OF gs_product-price.
    DATA p_uniq  TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_36 IMPLEMENTATION.

  METHOD initialization.

    DATA ls_s_price LIKE LINE OF s_price.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Products in a Selection` ).
    p_uniq = abap_true.

    ls_s_price-sign = 'I'.
    ls_s_price-option = 'BT'.
    ls_s_price-low = 10.
    ls_s_price-high = 500.
    APPEND ls_s_price TO s_price.

  ENDMETHOD.

  METHOD selection_screen.

    screen->select_option( val  = s_name
                           text = `Product`
        )->select_option( val  = s_price
                          text = `Price`
        )->checkbox( val  = p_uniq
                     text = `Without duplicates` ).

  ENDMETHOD.

  METHOD start_of_selection.

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

    list( )->new_line(
        )->write( |{ lines( gt_product ) } product(s) in the selection| ).
    list( )->uline( ).
    LOOP AT gt_product INTO gs_product.
      list( )->new_line(
          )->write( gs_product-group
          )->write( gs_product-name
          )->write( gs_product-price ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
