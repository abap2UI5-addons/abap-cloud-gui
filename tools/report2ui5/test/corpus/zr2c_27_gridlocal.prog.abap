*&---------------------------------------------------------------------*
*& Report ZR2C_27_GRIDLOCAL
*&---------------------------------------------------------------------*
*& A grid in a local class: created in the custom control area CC of
*& screen 0100 with a field catalog, a hotspot on the city, a function of
*& its own on the toolbar. The handlers are methods of the same class: a
*& double click and the hotspot send a message, the function adds a
*& connection and shows the table again.
*&---------------------------------------------------------------------*
REPORT zr2c_27_gridlocal.

CLASS lcl_alv DEFINITION FINAL.
  PUBLIC SECTION.
    DATA connections TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.
    METHODS select_connections.
    METHODS display.
  PRIVATE SECTION.
    DATA grid TYPE REF TO cl_gui_alv_grid.
    DATA fcat TYPE lvc_t_fcat.
    METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object.
    METHODS on_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.
    METHODS on_hotspot FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.

DATA go_alv TYPE REF TO lcl_alv.
DATA ok_code TYPE sy-ucomm.

CLASS lcl_alv IMPLEMENTATION.

  METHOD select_connections.
    SELECT * FROM spfli INTO TABLE @connections ORDER BY carrid, connid.
  ENDMETHOD.

  METHOD display.
    grid = NEW cl_gui_alv_grid( i_parent = NEW cl_gui_custom_container( container_name = 'CC' ) ).
    fcat = VALUE #( ( fieldname = 'CARRID'   coltext = 'Airline' )
                    ( fieldname = 'CONNID'   coltext = 'Flight' )
                    ( fieldname = 'CITYFROM' coltext = 'From' hotspot = abap_true )
                    ( fieldname = 'CITYTO'   coltext = 'To' ) ).
    SET HANDLER on_toolbar FOR grid.
    SET HANDLER on_user_command FOR grid.
    SET HANDLER on_double_click FOR grid.
    SET HANDLER on_hotspot FOR grid.
    grid->set_table_for_first_display(
      EXPORTING
        is_layout       = VALUE #( grid_title = 'Connections' )
      CHANGING
        it_fieldcatalog = fcat
        it_outtab       = connections ).
  ENDMETHOD.

  METHOD on_toolbar.
    APPEND VALUE #( function = 'ADD' icon = icon_create text = 'Add' ) TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_ucomm.
      WHEN 'ADD'.
        APPEND VALUE #( carrid = 'UA' connid = '0941' cityfrom = 'FRANKFURT' cityto = 'SAN FRANCISCO' ) TO connections.
        grid->refresh_table_display( ).
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE connections INTO DATA(ls_connection) INDEX e_row-index.
    MESSAGE |{ ls_connection-carrid } { ls_connection-connid }| TYPE 'S'.
  ENDMETHOD.

  METHOD on_hotspot.
    READ TABLE connections INTO DATA(ls_connection) INDEX e_row_id-index.
    MESSAGE |{ e_column_id-fieldname }: { ls_connection-cityfrom }| TYPE 'S'.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_alv IS INITIAL.
    go_alv = NEW lcl_alv( ).
    go_alv->select_connections( ).
    go_alv->display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
