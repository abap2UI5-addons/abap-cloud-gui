*&---------------------------------------------------------------------*
*& Report ZR2C_45_SALVLOCAL
*&---------------------------------------------------------------------*
*& A packing list kept by a local class: the SALV object and its table
*& are static attributes, a button of its own weighs the rows selected,
*& a double click names the item, the item number is a link
*&---------------------------------------------------------------------*
REPORT zr2c_45_salvlocal.

TYPES:
  BEGIN OF ty_item,
    item   TYPE n LENGTH 3,
    name   TYPE c LENGTH 20,
    weight TYPE i,
  END OF ty_item.
TYPES ty_t_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

CLASS lcl_pack DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA gt_item TYPE ty_t_item.
    CLASS-DATA go_salv TYPE REF TO cl_salv_table.
    CLASS-METHODS show.
    CLASS-METHODS on_function FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
    CLASS-METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row.
    CLASS-METHODS on_link FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_pack IMPLEMENTATION.
  METHOD show.
    DATA lo_column TYPE REF TO cl_salv_column_table.
    gt_item = VALUE #( ( item = '001' name = 'Tent'          weight = 2400 )
                       ( item = '002' name = 'Sleeping bag'  weight = 1100 )
                       ( item = '003' name = 'Stove'         weight = 350 ) ).
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = go_salv
                                CHANGING  t_table      = gt_item ).
        go_salv->get_display_settings( )->set_list_header( 'Packing list' ).
        go_salv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).
        go_salv->get_functions( )->add_function( name     = 'WEIGH'
                                                 text     = 'Weigh'
                                                 tooltip  = 'Weigh the rows selected'
                                                 position = if_salv_c_function_position=>right_of_salv_functions ).
        lo_column ?= go_salv->get_columns( )->get_column( 'WEIGHT' ).
        lo_column->set_long_text( 'Weight (g)' ).
        lo_column ?= go_salv->get_columns( )->get_column( 'ITEM' ).
        lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        SET HANDLER on_function FOR go_salv->get_event( ).
        SET HANDLER on_double_click FOR go_salv->get_event( ).
        SET HANDLER on_link FOR go_salv->get_event( ).
        go_salv->display( ).
      CATCH cx_salv_msg cx_salv_not_found cx_salv_existing cx_salv_wrong_call INTO DATA(lx_salv).
        MESSAGE lx_salv->get_text( ) TYPE 'I'.
    ENDTRY.
  ENDMETHOD.

  METHOD on_function.
    DATA lv_total TYPE i.
    CASE e_salv_function.
      WHEN 'WEIGH'.
        DATA(lt_row) = go_salv->get_selections( )->get_selected_rows( ).
        LOOP AT lt_row INTO DATA(lv_row).
          lv_total = lv_total + gt_item[ lv_row ]-weight.
        ENDLOOP.
        MESSAGE |{ lines( lt_row ) } item(s), { lv_total } g| TYPE 'S'.
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    MESSAGE |{ gt_item[ row ]-name } in row { row }| TYPE 'S'.
  ENDMETHOD.

  METHOD on_link.
    MESSAGE |Item { gt_item[ row ]-item } ({ column })| TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  lcl_pack=>show( ).
  WRITE: space.
