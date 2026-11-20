CLASS z2ui5_cl_cgui_r2c_53 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_call,
        id        TYPE n LENGTH 4,
        interface TYPE c LENGTH 30,
        status    TYPE c LENGTH 1,
        message   TYPE c LENGTH 40,
      END OF ty_call.
    TYPES ty_t_call TYPE STANDARD TABLE OF ty_call WITH DEFAULT KEY.

    " global data of the report
    DATA gt_call TYPE ty_t_call.
    DATA gr_alv   TYPE REF TO z2ui5_cl_cgui_salv_table.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_roundtrip_start REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA gr_events TYPE REF TO lcl_events.

    METHODS get_data.

    METHODS display.

    METHODS handle_user_command
      IMPORTING
        i_ucomm TYPE z2ui5_cl_cgui_salv_table=>ty_function.

    METHODS process_selected_rows.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_53 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A SALV with a GUI status of its own` ).

  ENDMETHOD.

  METHOD start_of_selection.

    get_data( ).
    CREATE OBJECT gr_events TYPE lcl_events.
    display( ).

  ENDMETHOD.

  METHOD at_roundtrip_start.

    lcl_r2c=>app = me.

  ENDMETHOD.

  METHOD get_data.

    DATA temp1 TYPE z2ui5_cl_cgui_r2c_53=>ty_t_call.
    DATA temp2 LIKE LINE OF temp1.
    CLEAR temp1.

    temp2-id = '0001'.
    temp2-interface = 'ORDER_CREATE'.
    temp2-status = 'E'.
    temp2-message = 'Customer locked'.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = '0002'.
    temp2-interface = 'ORDER_CREATE'.
    temp2-status = 'S'.
    temp2-message = 'Order 4711 created'.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = '0003'.
    temp2-interface = 'INVOICE_POST'.
    temp2-status = 'E'.
    temp2-message = 'Period closed'.
    INSERT temp2 INTO TABLE temp1.
    gt_call = temp1.

  ENDMETHOD.

  METHOD display.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_salv_column.
    DATA lr_events TYPE REF TO z2ui5_cl_cgui_salv_table.

    TRY.
        z2ui5_cl_cgui_salv_table=>factory( IMPORTING r_salv_table = gr_alv
                                CHANGING  t_table      = gt_call ).
      CATCH z2ui5_cx_cgui_salv.
        RETURN.
    ENDTRY.

    gr_alv->set_screen_status( pfstatus      = 'SALV_STANDARD'
                               report        = 'ZR2C_53_SALVSTATUS'
                               set_functions = gr_alv->c_functions_all ).
    gr_alv->get_functions( )->add_function( name = `PROCESS` text = `Process` tooltip = `Process selected calls (Shift+F1)` ).
    gr_alv->get_functions( )->add_function( name = `REFRESH` icon = `sap-icon://refresh` tooltip = `Refresh (F5)` ).

    gr_alv->get_selections( )->set_selection_mode( z2ui5_if_cgui_salv_c=>selection_mode-row_column ).

    TRY.
        lr_column ?= gr_alv->get_columns( )->get_column( 'INTERFACE' ).
        lr_column->set_cell_type( z2ui5_if_cgui_salv_c=>cell_type-hotspot ).
      CATCH z2ui5_cx_cgui_salv.
        message( text = 'The column INTERFACE is missing'
                 type = `I` ).
    ENDTRY.


    lr_events = gr_alv->get_event( ).
    lr_events->set_handler( handler = gr_events
                            method  = `ON_USER_COMMAND`
                            event   = `ADDED_FUNCTION` ).
    lr_events->set_handler( handler = gr_events
                            method  = `ON_LINK_CLICK`
                            event   = `LINK_CLICK` ).

    gr_alv->display( ).

  ENDMETHOD.

  METHOD handle_user_command.

    CASE i_ucomm.
      WHEN 'PROCESS'.
        process_selected_rows( ).
      WHEN 'REFRESH'.
        get_data( ).
        gr_alv->refresh( ).
    ENDCASE.

  ENDMETHOD.

  METHOD process_selected_rows.

    DATA lt_rows TYPE z2ui5_cl_cgui_salv_config=>ty_t_row.
    DATA lv_row LIKE LINE OF lt_rows.
      FIELD-SYMBOLS <call> TYPE z2ui5_cl_cgui_r2c_53=>ty_call.
    lt_rows = gr_alv->get_selections( )->get_selected_rows( ).

    LOOP AT lt_rows INTO lv_row.

      READ TABLE gt_call INDEX lv_row ASSIGNING <call>.
      IF sy-subrc = 0.
        <call>-status = 'S'.
        <call>-message = 'Processed again'.
      ENDIF.
    ENDLOOP.
    gr_alv->refresh( ).
    message( |{ lines( lt_rows ) } call(s) processed| ).

  ENDMETHOD.

ENDCLASS.
