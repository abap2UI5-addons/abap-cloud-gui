*&---------------------------------------------------------------------*
*& Report ZR2C_53_SALVSTATUS
*&---------------------------------------------------------------------*
*& A log of interface calls in a SALV with a GUI status of its own: the
*& status copies the SALV standard and adds Process and Refresh, set with
*& set_screen_status( ) and all SALV functions; the user command goes to a
*& handler of added_function OF cl_salv_events (the class that declares
*& the event), the name of the interface is a link
*&---------------------------------------------------------------------*
REPORT zr2c_53_salvstatus.

TYPES:
  BEGIN OF ty_call,
    id        TYPE n LENGTH 4,
    interface TYPE c LENGTH 30,
    status    TYPE c LENGTH 1,
    message   TYPE c LENGTH 40,
  END OF ty_call.
TYPES ty_t_call TYPE STANDARD TABLE OF ty_call WITH DEFAULT KEY.

DATA gt_call TYPE ty_t_call.
DATA gr_alv  TYPE REF TO cl_salv_table.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_user_command FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.
    METHODS on_link_click FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

DATA gr_events TYPE REF TO lcl_events.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_user_command.
    PERFORM handle_user_command USING e_salv_function.
  ENDMETHOD.

  METHOD on_link_click.
    READ TABLE gt_call INDEX row INTO DATA(ls_call).
    IF sy-subrc = 0.
      MESSAGE |{ ls_call-interface } ({ column }): { ls_call-message }| TYPE 'S'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  PERFORM get_data.
  gr_events = NEW lcl_events( ).
  PERFORM display.

FORM get_data.
  gt_call = VALUE #( ( id = '0001' interface = 'ORDER_CREATE'   status = 'E' message = 'Customer locked' )
                     ( id = '0002' interface = 'ORDER_CREATE'   status = 'S' message = 'Order 4711 created' )
                     ( id = '0003' interface = 'INVOICE_POST'   status = 'E' message = 'Period closed' ) ).
ENDFORM.

FORM display.
  DATA lr_column TYPE REF TO cl_salv_column_table.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = gr_alv
                              CHANGING  t_table      = gt_call ).
    CATCH cx_salv_msg.
      RETURN.
  ENDTRY.

  gr_alv->set_screen_status( pfstatus      = 'SALV_STANDARD'
                             report        = sy-repid
                             set_functions = gr_alv->c_functions_all ).

  gr_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  TRY.
      lr_column ?= gr_alv->get_columns( )->get_column( 'INTERFACE' ).
      lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CATCH cx_salv_not_found.
      MESSAGE 'The column INTERFACE is missing' TYPE 'I'.
  ENDTRY.

  DATA(lr_events) = gr_alv->get_event( ).
  SET HANDLER gr_events->on_user_command FOR lr_events.
  SET HANDLER gr_events->on_link_click FOR lr_events.

  gr_alv->display( ).
ENDFORM.

FORM handle_user_command USING i_ucomm TYPE salv_de_function.
  CASE i_ucomm.
    WHEN 'PROCESS'.
      PERFORM process_selected_rows.
    WHEN 'REFRESH'.
      PERFORM get_data.
      gr_alv->refresh( ).
  ENDCASE.
ENDFORM.

FORM process_selected_rows.
  DATA(lt_rows) = gr_alv->get_selections( )->get_selected_rows( ).
  LOOP AT lt_rows INTO DATA(lv_row).
    READ TABLE gt_call INDEX lv_row ASSIGNING FIELD-SYMBOL(<call>).
    IF sy-subrc = 0.
      <call>-status = 'S'.
      <call>-message = 'Processed again'.
    ENDIF.
  ENDLOOP.
  gr_alv->refresh( ).
  MESSAGE |{ lines( lt_rows ) } call(s) processed| TYPE 'S'.
ENDFORM.
