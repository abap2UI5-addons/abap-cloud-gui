CLASS z2ui5_cl_cgui_r2c_29 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_stock,
        item     TYPE c LENGTH 10,
        quantity TYPE i,
        shelf    TYPE c LENGTH 3,
      END OF ty_stock.
    TYPES ty_t_stock TYPE STANDARD TABLE OF ty_stock WITH DEFAULT KEY.

    " selection screen
    DATA p_min TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_29 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Inventory with cl_demo_output` ).
    p_min = 5.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_min
                       text = `Minimum quantity` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA temp1 TYPE ty_t_stock.
    DATA temp2 LIKE LINE OF temp1.
    DATA lt_stock LIKE temp1.
    DATA temp3 TYPE ty_t_stock.
    DATA ls_row LIKE LINE OF lt_stock.
    DATA lt_low LIKE temp3.
    DATA temp5 TYPE i.
    DATA n TYPE i.
    DATA ls_line LIKE LINE OF lt_stock.
    DATA lv_total LIKE temp5.
    CLEAR temp1.

    temp2-item = 'BOLT'.
    temp2-quantity = 120.
    temp2-shelf = 'A1'.
    INSERT temp2 INTO TABLE temp1.
    temp2-item = 'NUT'.
    temp2-quantity = 3.
    temp2-shelf = 'A2'.
    INSERT temp2 INTO TABLE temp1.
    temp2-item = 'WASHER'.
    temp2-quantity = 48.
    temp2-shelf = 'B1'.
    INSERT temp2 INTO TABLE temp1.
    temp2-item = 'SCREW'.
    temp2-quantity = 2.
    temp2-shelf = 'B4'.
    INSERT temp2 INTO TABLE temp1.

    lt_stock = temp1.


    CLEAR temp3.

    LOOP AT lt_stock INTO ls_row WHERE quantity < p_min.
      INSERT ls_row INTO TABLE temp3.
    ENDLOOP.

    lt_low = temp3.


    n = 0.

    LOOP AT lt_stock INTO ls_line.
      n = n + ls_line-quantity.
    ENDLOOP.
    temp5 = n.

    lv_total = temp5.

    z2ui5_cl_cgui_demo_output=>begin_section( 'Inventory' ).
    z2ui5_cl_cgui_demo_output=>write_text( |{ lines( lt_stock ) } items, { lv_total } pieces in stock| ).
    z2ui5_cl_cgui_demo_output=>write( data = lt_stock name = 'Stock' ).
    z2ui5_cl_cgui_demo_output=>next_section( 'To reorder' ).
    IF lt_low IS INITIAL.
      z2ui5_cl_cgui_demo_output=>write_text( 'Nothing to reorder' ).
    ELSE.
      z2ui5_cl_cgui_demo_output=>write( data = lt_low name = 'Below the minimum' ).
    ENDIF.
    z2ui5_cl_cgui_demo_output=>end_section( ).
    z2ui5_cl_cgui_demo_output=>display( lv_total ).

  ENDMETHOD.

ENDCLASS.
