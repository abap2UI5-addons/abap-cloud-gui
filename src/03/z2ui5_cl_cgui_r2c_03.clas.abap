CLASS z2ui5_cl_cgui_r2c_03 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_item,
        pos      TYPE i,
        product  TYPE c LENGTH 10,
        quantity TYPE i,
        price    TYPE p LENGTH 10 DECIMALS 2,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    CONSTANTS gc_vat TYPE p LENGTH 3 DECIMALS 2 VALUE '0.19'.

    " global data of the report
    DATA:
      gt_items    TYPE ty_items,
      gs_template TYPE ty_item,
      gv_net   TYPE p LENGTH 12 DECIMALS 2,
      gv_gross TYPE p LENGTH 12 DECIMALS 2.

    " selection screen
    DATA p_items TYPE i.
    DATA p_disc  TYPE p LENGTH 3 DECIMALS 2.
    DATA p_vat   TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen_on REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    TYPES ty_t_gs_template LIKE STANDARD TABLE OF gs_template WITH DEFAULT KEY.

    METHODS build_items
      IMPORTING
        VALUE(iv_count) TYPE i
      CHANGING
        ct_items TYPE ty_items.

    METHODS total
      IMPORTING
        iv_discount LIKE p_disc
      CHANGING
        it_items TYPE ty_t_gs_template
        cv_net   LIKE gv_net.

    METHODS output.

    METHODS write_item
      IMPORTING
        is_item TYPE ty_item.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_03 IMPLEMENTATION.

  METHOD initialization.

    p_items = 5.
    p_disc = '0.05'.
    p_vat = abap_true.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_items
                       obligatory = abap_true
        )->parameter( p_disc
        )->checkbox( p_vat ).

  ENDMETHOD.

  METHOD at_selection_screen_on.

    CASE field.
      WHEN `P_ITEMS`.
        IF p_items < 1 OR p_items > 50.
          message( text = 'Between 1 and 50 items'
                   type = `E` ).
          RETURN.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_items,
           gs_template,
           gv_net,
           gv_gross.

    build_items( EXPORTING
                   iv_count = p_items
                 CHANGING
                   ct_items = gt_items ).
    total( EXPORTING
             iv_discount = p_disc
           CHANGING
             it_items    = gt_items
             cv_net      = gv_net ).
    IF p_vat = abap_true.
      gv_gross = gv_net * ( 1 + gc_vat ).
    ELSE.
      gv_gross = gv_net.
    ENDIF.
    output( ).

  ENDMETHOD.

  METHOD build_items.

    DATA ls_item TYPE ty_item.
    CLEAR ct_items.
    DO iv_count TIMES.
      ls_item-pos      = sy-index.
      ls_item-product  = |PROD-{ sy-index }|.
      ls_item-quantity = sy-index * 2.
      ls_item-price    = 10 + sy-index.
      APPEND ls_item TO ct_items.
    ENDDO.

  ENDMETHOD.

  METHOD total.

    DATA:
      ls_item TYPE ty_item,
      lr_pos  TYPE RANGE OF i.
    DATA lr_big LIKE RANGE OF ls_item-quantity.

    lr_pos = VALUE #( ( sign = 'I' option = 'BT' low = 1 high = 1000 ) ).
    lr_big = VALUE #( ( sign = 'I' option = 'GE' low = 10 ) ).
    cv_net = 0.
    LOOP AT it_items INTO ls_item.
      IF z2ui5_cl_cgui_context=>range_check( val = ls_item-pos range = lr_pos ) = abap_false.
        CONTINUE.
      ENDIF.
      IF z2ui5_cl_cgui_context=>range_check( val = ls_item-quantity range = lr_big ) = abap_true.
        cv_net = cv_net + ls_item-quantity * ls_item-price * ( 1 - iv_discount ).
      ELSE.
        cv_net = cv_net + ls_item-quantity * ls_item-price.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD output.

    DATA ls_item TYPE ty_item.
    LOOP AT gt_items INTO ls_item.
      write_item( ls_item ).
    ENDLOOP.
    list( )->uline( ).
    list( )->new_line(
        )->write( 'Net:'
        )->write( gv_net
        )->new_line(
        )->write( 'Gross:'
        )->write( gv_gross ).

  ENDMETHOD.

  METHOD write_item.

    list( )->new_line(
        )->write( is_item-pos
        )->write( is_item-product
        )->write( is_item-quantity
        )->write( is_item-price ).

  ENDMETHOD.

ENDCLASS.
