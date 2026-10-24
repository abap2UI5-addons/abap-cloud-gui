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

    set_title( `Inventory with cl_demo_output` ).
    p_min = 5.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_min
                       text = `Minimum quantity` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA(lt_stock) = VALUE ty_t_stock( ( item = 'BOLT'   quantity = 120 shelf = 'A1' )
                                       ( item = 'NUT'    quantity = 3   shelf = 'A2' )
                                       ( item = 'WASHER' quantity = 48  shelf = 'B1' )
                                       ( item = 'SCREW'  quantity = 2   shelf = 'B4' ) ).

    DATA(lt_low) = VALUE ty_t_stock( FOR ls_row IN lt_stock WHERE ( quantity < p_min ) ( ls_row ) ).
    DATA(lv_total) = REDUCE i( INIT n = 0 FOR ls_line IN lt_stock NEXT n = n + ls_line-quantity ).

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
