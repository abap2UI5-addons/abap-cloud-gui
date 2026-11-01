*&---------------------------------------------------------------------*
*& Report ZR2C_26_EVENTS
*&---------------------------------------------------------------------*
*& The events of SAP GUI controls, handled by a local class: a toolbar
*& in the custom control area CC raises FUNCTION_SELECTED, the links of
*& an HTML viewer below it raise SAPEVENT, a dialog box container with
*& the details of a flight raises CLOSE.
*&---------------------------------------------------------------------*
REPORT zr2c_26_events.

TYPES ty_line TYPE c LENGTH 255.

CLASS lcl_app DEFINITION.
  PUBLIC SECTION.
    DATA mo_cont    TYPE REF TO cl_gui_custom_container.
    DATA mo_split   TYPE REF TO cl_gui_splitter_container.
    DATA mo_toolbar TYPE REF TO cl_gui_toolbar.
    DATA mo_html    TYPE REF TO cl_gui_html_viewer.
    DATA mo_box     TYPE REF TO cl_gui_dialogbox_container.
    DATA mv_count   TYPE i.
    METHODS create.
    METHODS show_flights.
    METHODS on_function FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.
    METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action query_table.
    METHODS on_close FOR EVENT close OF cl_gui_dialogbox_container
      IMPORTING sender.
ENDCLASS.

DATA go_app TYPE REF TO lcl_app.
DATA ok_code TYPE sy-ucomm.

CLASS lcl_app IMPLEMENTATION.

  METHOD create.
    CREATE OBJECT mo_cont
      EXPORTING
        container_name = 'CC'.
    CREATE OBJECT mo_split
      EXPORTING
        parent  = mo_cont
        rows    = 2
        columns = 1.
    CREATE OBJECT mo_toolbar
      EXPORTING
        parent = mo_split->get_container( row = 1 column = 1 ).
    mo_toolbar->add_button( fcode     = 'REFRESH'
                            icon      = icon_refresh
                            butn_type = cntb_btype_button
                            text      = 'Refresh' ).
    mo_toolbar->add_button( fcode     = 'SEP'
                            icon      = space
                            butn_type = cntb_btype_sep ).
    mo_toolbar->add_button( fcode     = 'DETAILS'
                            icon      = icon_detail
                            butn_type = cntb_btype_button
                            text      = 'Details' ).
    SET HANDLER me->on_function FOR mo_toolbar.

    CREATE OBJECT mo_html
      EXPORTING
        parent = mo_split->get_container( row = 2 column = 1 ).
    SET HANDLER me->on_sapevent FOR mo_html.
    show_flights( ).
  ENDMETHOD.

  METHOD show_flights.
    DATA lt_html TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url  TYPE c LENGTH 250.
    mv_count = mv_count + 1.
    APPEND |<p>Shown { mv_count } time(s)</p>| TO lt_html.
    APPEND '<a href="SAPEVENT:SHOW?CONNID=0400">Flight 0400</a>' TO lt_html.
    APPEND '<a href="SAPEVENT:SHOW?CONNID=0402">Flight 0402</a>' TO lt_html.
    mo_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    mo_html->show_url( lv_url ).
  ENDMETHOD.

  METHOD on_function.
    CASE fcode.
      WHEN 'REFRESH'.
        show_flights( ).
      WHEN 'DETAILS'.
        IF mo_box IS INITIAL.
          CREATE OBJECT mo_box
            EXPORTING
              caption = 'Details'
              width   = 400
              height  = 200.
          SET HANDLER me->on_close FOR mo_box.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD on_sapevent.
    READ TABLE query_table INTO DATA(ls_query) WITH KEY name = 'CONNID'.
    MESSAGE |{ action } { ls_query-value }| TYPE 'S'.
  ENDMETHOD.

  METHOD on_close.
    sender->free( ).
    CLEAR mo_box.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_app IS INITIAL.
    CREATE OBJECT go_app.
    go_app->create( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
