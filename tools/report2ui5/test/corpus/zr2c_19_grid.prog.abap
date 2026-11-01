*&---------------------------------------------------------------------*
*& Report ZR2C_19_GRID
*&---------------------------------------------------------------------*
*& The ALV every report since 2005 is written with: cl_gui_alv_grid in a
*& custom container on screen 100, an LVC field catalog with a hotspot
*& column and a total, the layout's title, a handler class with
*& DOUBLE_CLICK, HOTSPOT_CLICK, TOOLBAR and USER_COMMAND, the PBO and PAI
*& modules of the screen
*&---------------------------------------------------------------------*
REPORT zr2c_19_grid.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_hotspot FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive.
    METHODS on_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
ENDCLASS.

DATA: gt_flight  TYPE STANDARD TABLE OF sflight WITH DEFAULT KEY,
      gs_flight  TYPE sflight,
      gt_fcat    TYPE lvc_t_fcat,
      gs_fcat    TYPE lvc_s_fcat,
      gs_layout  TYPE lvc_s_layo,
      go_cont    TYPE REF TO cl_gui_custom_container,
      go_grid    TYPE REF TO cl_gui_alv_grid,
      go_handler TYPE REF TO lcl_handler,
      ok_code    TYPE sy-ucomm,
      gv_save_ok TYPE sy-ucomm.

PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    READ TABLE gt_flight INDEX e_row-index INTO gs_flight.
    MESSAGE |Flight { gs_flight-connid } on { gs_flight-fldate DATE = USER }| TYPE 'I'.
  ENDMETHOD.
  METHOD on_hotspot.
    READ TABLE gt_flight INDEX e_row_id-index INTO gs_flight.
    IF e_column_id-fieldname = 'CONNID'.
      MESSAGE |Connection { gs_flight-connid }| TYPE 'S'.
    ENDIF.
  ENDMETHOD.
  METHOD on_toolbar.
    DATA ls_button TYPE stb_button.
    CLEAR ls_button.
    ls_button-butn_type = 3.
    APPEND ls_button TO e_object->mt_toolbar.
    CLEAR ls_button.
    ls_button-function = 'FULL'.
    ls_button-icon = icon_okay.
    ls_button-text = 'Full flights'.
    ls_button-quickinfo = 'Count the full flights'.
    APPEND ls_button TO e_object->mt_toolbar.
    APPEND VALUE #( function = 'ALL' text = 'All flights' ) TO e_object->mt_toolbar.
  ENDMETHOD.
  METHOD on_user_command.
    DATA lv_full TYPE i.
    CASE e_ucomm.
      WHEN 'FULL'.
        LOOP AT gt_flight INTO gs_flight.
          IF gs_flight-seatsocc >= gs_flight-seatsmax.
            lv_full = lv_full + 1.
          ENDIF.
        ENDLOOP.
        MESSAGE |{ lv_full } full flights| TYPE 'S'.
      WHEN 'ALL'.
        MESSAGE |{ lines( gt_flight ) } flights| TYPE 'S'.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  SELECT * FROM sflight INTO TABLE gt_flight
    WHERE carrid = p_carrid
    ORDER BY PRIMARY KEY.
  CALL SCREEN 100.

FORM build_fieldcat.
  CLEAR gs_fcat.
  gs_fcat-fieldname = 'CONNID'.
  gs_fcat-coltext = 'Flight'.
  gs_fcat-hotspot = 'X'.
  APPEND gs_fcat TO gt_fcat.
  CLEAR gs_fcat.
  gs_fcat-fieldname = 'SEATSOCC'.
  gs_fcat-coltext = 'Occupied'.
  gs_fcat-do_sum = 'X'.
  APPEND gs_fcat TO gt_fcat.
  CLEAR gs_fcat.
  gs_fcat-fieldname = 'MANDT'.
  gs_fcat-no_out = 'X'.
  APPEND gs_fcat TO gt_fcat.
ENDFORM.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  IF go_cont IS INITIAL.
    CREATE OBJECT go_cont
      EXPORTING
        container_name = 'CONTAINER'.
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cont.
    PERFORM build_fieldcat.
    gs_layout-grid_title = 'Flights'.
    gs_layout-zebra = 'X'.
    CREATE OBJECT go_handler.
    SET HANDLER go_handler->on_double_click
                go_handler->on_hotspot
                go_handler->on_toolbar
                go_handler->on_user_command FOR go_grid.
    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_flight
        it_fieldcatalog = gt_fcat.
  ELSE.
    go_grid->refresh_table_display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_save_ok = ok_code.
  CLEAR ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
    WHEN 'REFRESH'.
      SELECT * FROM sflight INTO TABLE gt_flight
        WHERE carrid = p_carrid
        ORDER BY PRIMARY KEY.
  ENDCASE.
ENDMODULE.
