" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_48.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_48 DEFINITION LOCAL FRIENDS lcl_view.


CLASS lcl_view IMPLEMENTATION.

  METHOD display.
    SELECT * FROM scarr INTO TABLE @airlines ORDER BY carrid.
    split = NEW z2ui5_cl_cgui_gui_container( parent  = NEW z2ui5_cl_cgui_gui_container( container_name = 'CC' )
                                           rows    = 2
                                           columns = 1 ).
    header = NEW z2ui5_cl_cgui_gui_alv_grid( i_parent = split->get_container( row = 1 column = 1 ) ).
    items = NEW z2ui5_cl_cgui_gui_alv_grid( i_parent = split->get_container( row = 2 column = 1 ) ).
    header->set_handler( handler = me
                         method  = `ON_DOUBLE_CLICK`
                         event   = `DOUBLE_CLICK` ).
    header->set_table_for_first_display(
      EXPORTING
        i_structure_name = 'SCARR'
        is_layout        = VALUE lvc_s_layo( grid_title = 'Airlines' )
      CHANGING
        it_outtab        = airlines ).
    items->set_table_for_first_display(
      EXPORTING
        i_structure_name = 'SPFLI'
        is_layout        = VALUE lvc_s_layo( grid_title = 'Connections' )
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
