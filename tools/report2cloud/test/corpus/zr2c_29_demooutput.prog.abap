*&---------------------------------------------------------------------*
*& Report ZR2C_29_DEMOOUTPUT
*&---------------------------------------------------------------------*
*& A small inventory written with cl_demo_output: sections, a text, a
*& structure, a table and a value, then display( ) - the classic
*& output window of demo programs
*&---------------------------------------------------------------------*
REPORT zr2c_29_demooutput.

TYPES:
  BEGIN OF ty_stock,
    item     TYPE c LENGTH 10,
    quantity TYPE i,
    shelf    TYPE c LENGTH 3,
  END OF ty_stock.
TYPES ty_t_stock TYPE STANDARD TABLE OF ty_stock WITH DEFAULT KEY.

PARAMETERS p_min TYPE i DEFAULT 5.

START-OF-SELECTION.
  DATA(lt_stock) = VALUE ty_t_stock( ( item = 'BOLT'   quantity = 120 shelf = 'A1' )
                                     ( item = 'NUT'    quantity = 3   shelf = 'A2' )
                                     ( item = 'WASHER' quantity = 48  shelf = 'B1' )
                                     ( item = 'SCREW'  quantity = 2   shelf = 'B4' ) ).

  DATA(lt_low) = VALUE ty_t_stock( FOR ls_row IN lt_stock WHERE ( quantity < p_min ) ( ls_row ) ).
  DATA(lv_total) = REDUCE i( INIT n = 0 FOR ls_line IN lt_stock NEXT n = n + ls_line-quantity ).

  cl_demo_output=>begin_section( 'Inventory' ).
  cl_demo_output=>write_text( |{ lines( lt_stock ) } items, { lv_total } pieces in stock| ).
  cl_demo_output=>write( data = lt_stock name = 'Stock' ).
  cl_demo_output=>next_section( 'To reorder' ).
  IF lt_low IS INITIAL.
    cl_demo_output=>write_text( 'Nothing to reorder' ).
  ELSE.
    cl_demo_output=>write( data = lt_low name = 'Below the minimum' ).
  ENDIF.
  cl_demo_output=>end_section( ).
  cl_demo_output=>display( lv_total ).
