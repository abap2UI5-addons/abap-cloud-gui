" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_45.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS lcl_pack DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_r2c_45 DEFINITION LOCAL FRIENDS lcl_pack.

CLASS lcl_pack DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    CLASS-DATA gt_item TYPE z2ui5_cl_cgui_r2c_45=>ty_t_item.
    CLASS-DATA go_salv TYPE REF TO z2ui5_cl_cgui_salv_table.
    CLASS-METHODS show.
    CLASS-METHODS on_function FOR EVENT added_function OF z2ui5_cl_cgui_salv_table
      IMPORTING e_salv_function.
    CLASS-METHODS on_double_click FOR EVENT double_click OF z2ui5_cl_cgui_salv_table
      IMPORTING row.
    CLASS-METHODS on_link FOR EVENT link_click OF z2ui5_cl_cgui_salv_table
      IMPORTING row column.
ENDCLASS.


CLASS lcl_pack IMPLEMENTATION.
  METHOD show.
    DATA lo_column TYPE REF TO z2ui5_cl_cgui_salv_column.
    gt_item = VALUE #( ( item = '001' name = 'Tent'          weight = 2400 )
                       ( item = '002' name = 'Sleeping bag'  weight = 1100 )
                       ( item = '003' name = 'Stove'         weight = 350 ) ).
    TRY.
        z2ui5_cl_cgui_salv_table=>factory( IMPORTING r_salv_table = go_salv
                                CHANGING  t_table      = gt_item ).
        go_salv->get_display_settings( )->set_list_header( 'Packing list' ).
        go_salv->get_selections( )->set_selection_mode( z2ui5_if_cgui_salv_c=>selection_mode-multiple ).
        go_salv->get_functions( )->add_function( name     = 'WEIGH'
                                                 text     = 'Weigh'
                                                 tooltip  = 'Weigh the rows selected'
                                                 position = z2ui5_if_cgui_salv_c=>function_position-right_of_salv_functions ).
        lo_column ?= go_salv->get_columns( )->get_column( 'WEIGHT' ).
        lo_column->set_long_text( 'Weight (g)' ).
        lo_column ?= go_salv->get_columns( )->get_column( 'ITEM' ).
        lo_column->set_cell_type( z2ui5_if_cgui_salv_c=>cell_type-hotspot ).
        go_salv->get_event( )->set_handler( handler = NEW lcl_pack( )
                                            method  = `ON_FUNCTION`
                                            event   = `ADDED_FUNCTION` ).
        go_salv->get_event( )->set_handler( handler = NEW lcl_pack( )
                                            method  = `ON_DOUBLE_CLICK`
                                            event   = `DOUBLE_CLICK` ).
        go_salv->get_event( )->set_handler( handler = NEW lcl_pack( )
                                            method  = `ON_LINK`
                                            event   = `LINK_CLICK` ).
        go_salv->display( ).
      CATCH z2ui5_cx_cgui_salv INTO DATA(lx_salv).
        lcl_r2c=>app->message( text = lx_salv->get_text( )
                 type = `I` ).
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
        lcl_r2c=>app->message( |{ lines( lt_row ) } item(s), { lv_total } g| ).
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    lcl_r2c=>app->message( |{ gt_item[ row ]-name } in row { row }| ).
  ENDMETHOD.

  METHOD on_link.
    lcl_r2c=>app->message( |Item { gt_item[ row ]-item } ({ column })| ).
  ENDMETHOD.
ENDCLASS.
