*&---------------------------------------------------------------------*
*& Report ZR2C_48_TWOGRIDS
*&---------------------------------------------------------------------*
*& Two grids in a splitter of screen 0100: the airlines above, the
*& connections of the airline double-clicked below - the classic header
*& and items. The second grid starts empty and is refreshed with the
*& connections of the airline.
*&---------------------------------------------------------------------*
REPORT zr2c_48_twogrids.

CLASS lcl_view DEFINITION FINAL.
  PUBLIC SECTION.
    DATA airlines    TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY.
    DATA connections TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.
    METHODS display.
  PRIVATE SECTION.
    DATA split  TYPE REF TO cl_gui_splitter_container.
    DATA header TYPE REF TO cl_gui_alv_grid.
    DATA items  TYPE REF TO cl_gui_alv_grid.
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.
ENDCLASS.

DATA go_view TYPE REF TO lcl_view.
DATA ok_code TYPE sy-ucomm.

CLASS lcl_view IMPLEMENTATION.

  METHOD display.
    SELECT * FROM scarr INTO TABLE @airlines ORDER BY carrid.
    split = NEW cl_gui_splitter_container( parent  = NEW cl_gui_custom_container( container_name = 'CC' )
                                           rows    = 2
                                           columns = 1 ).
    header = NEW cl_gui_alv_grid( i_parent = split->get_container( row = 1 column = 1 ) ).
    items = NEW cl_gui_alv_grid( i_parent = split->get_container( row = 2 column = 1 ) ).
    SET HANDLER on_double_click FOR header.
    header->set_table_for_first_display(
      EXPORTING
        i_structure_name = 'SCARR'
        is_layout        = VALUE #( grid_title = 'Airlines' )
      CHANGING
        it_outtab        = airlines ).
    items->set_table_for_first_display(
      EXPORTING
        i_structure_name = 'SPFLI'
        is_layout        = VALUE #( grid_title = 'Connections' )
      CHANGING
        it_outtab        = connections ).
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE airlines INTO DATA(ls_airline) INDEX e_row-index.
    SELECT * FROM spfli INTO TABLE @connections
      WHERE carrid = @ls_airline-carrid
      ORDER BY connid.
    items->refresh_table_display( CHANGING it_outtab = connections ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_view IS INITIAL.
    go_view = NEW lcl_view( ).
    go_view->display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
