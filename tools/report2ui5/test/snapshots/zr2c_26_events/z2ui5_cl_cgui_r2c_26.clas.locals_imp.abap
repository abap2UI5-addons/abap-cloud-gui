" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_26.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_26 DEFINITION LOCAL FRIENDS lcl_app.


CLASS lcl_app IMPLEMENTATION.

  METHOD create.
    mo_cont = NEW #( container_name = 'CC' ).
    mo_split = NEW #( parent  = mo_cont
                      rows    = 2
                      columns = 1 ).
    mo_toolbar = NEW #( parent = mo_split->get_container( row = 1 column = 1 ) ).
    mo_toolbar->add_button( fcode     = 'REFRESH'
                            icon      = `sap-icon://refresh`
                            butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button
                            text      = 'Refresh' ).
    mo_toolbar->add_button( fcode     = 'SEP'
                            icon      = space
                            butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_sep ).
    mo_toolbar->add_button( fcode     = 'DETAILS'
                            icon      = `sap-icon://detail-view`
                            butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button
                            text      = 'Details' ).
    mo_toolbar->set_handler( handler = me
                             method  = `ON_FUNCTION`
                             event   = `FUNCTION_SELECTED` ).

    mo_html = NEW #( parent = mo_split->get_container( row = 2 column = 1 ) ).
    mo_html->set_handler( handler = me
                          method  = `ON_SAPEVENT`
                          event   = `SAPEVENT` ).
    show_flights( ).
  ENDMETHOD.

  METHOD show_flights.
    DATA lt_html TYPE STANDARD TABLE OF z2ui5_cl_cgui_r2c_26=>ty_line WITH DEFAULT KEY.
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
          mo_box = NEW #( caption = 'Details'
                          width   = 400
                          height  = 200 ).
          mo_box->set_handler( handler = me
                               method  = `ON_CLOSE`
                               event   = `CLOSE` ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD on_sapevent.
    READ TABLE query_table INTO DATA(ls_query) WITH KEY name = 'CONNID'.
    lcl_r2c=>app->message( |{ action } { ls_query-value }| ).
  ENDMETHOD.

  METHOD on_close.
    sender->free( ).
    CLEAR mo_box.
  ENDMETHOD.

ENDCLASS.
