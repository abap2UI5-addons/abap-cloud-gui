" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_27.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_27 DEFINITION LOCAL FRIENDS lcl_alv.


CLASS lcl_alv IMPLEMENTATION.

  METHOD select_connections.
    SELECT * FROM spfli INTO TABLE @connections ORDER BY carrid, connid.
  ENDMETHOD.

  METHOD display.
    grid = NEW z2ui5_cl_cgui_gui_alv_grid( i_parent = NEW z2ui5_cl_cgui_gui_container( container_name = 'CC' ) ).
    fcat = VALUE #( ( fieldname = 'CARRID'   coltext = 'Airline' )
                    ( fieldname = 'CONNID'   coltext = 'Flight' )
                    ( fieldname = 'CITYFROM' coltext = 'From' hotspot = abap_true )
                    ( fieldname = 'CITYTO'   coltext = 'To' ) ).
    grid->set_handler( handler = me
                       method  = `ON_TOOLBAR`
                       event   = `TOOLBAR` ).
    grid->set_handler( handler = me
                       method  = `ON_USER_COMMAND`
                       event   = `USER_COMMAND` ).
    grid->set_handler( handler = me
                       method  = `ON_DOUBLE_CLICK`
                       event   = `DOUBLE_CLICK` ).
    grid->set_handler( handler = me
                       method  = `ON_HOTSPOT`
                       event   = `HOTSPOT_CLICK` ).
    grid->set_table_for_first_display(
      EXPORTING
        is_layout       = VALUE lvc_s_layo( grid_title = 'Connections' )
      CHANGING
        it_fieldcatalog = fcat
        it_outtab       = connections ).
  ENDMETHOD.

  METHOD on_toolbar.
    APPEND VALUE #( function = 'ADD' icon = `sap-icon://create` text = 'Add' ) TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_ucomm.
      WHEN 'ADD'.
        APPEND VALUE #( carrid = 'UA' connid = '0941' cityfrom = 'FRANKFURT' cityto = 'SAN FRANCISCO' ) TO connections.
        grid->refresh_table_display( CHANGING it_outtab = connections ).
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE connections INTO DATA(ls_connection) INDEX e_row-index.
    lcl_r2c=>app->message( |{ ls_connection-carrid } { ls_connection-connid }| ).
  ENDMETHOD.

  METHOD on_hotspot.
    READ TABLE connections INTO DATA(ls_connection) INDEX e_row_id-index.
    lcl_r2c=>app->message( |{ e_column_id-fieldname }: { ls_connection-cityfrom }| ).
  ENDMETHOD.

ENDCLASS.
