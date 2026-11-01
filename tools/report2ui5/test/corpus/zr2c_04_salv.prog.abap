*&---------------------------------------------------------------------*
*& Report ZR2C_04_SALV
*&---------------------------------------------------------------------*
*& Connections in a CL_SALV_TABLE grid with column texts, a hidden
*& column and a list header
*&---------------------------------------------------------------------*
REPORT zr2c_04_salv.

DATA: gs_spfli   TYPE spfli,
      gt_spfli   TYPE STANDARD TABLE OF spfli,
      go_alv     TYPE REF TO cl_salv_table,
      go_columns TYPE REF TO cl_salv_columns_table,
      go_column  TYPE REF TO cl_salv_column_table.

SELECT-OPTIONS: s_carrid FOR gs_spfli-carrid OBLIGATORY DEFAULT 'LH',
                s_cityfr FOR gs_spfli-cityfrom NO INTERVALS.
PARAMETERS p_rows TYPE i DEFAULT 200.

START-OF-SELECTION.
  PERFORM select_data.
  PERFORM display.

FORM select_data.
  SELECT * FROM spfli INTO TABLE gt_spfli
    UP TO p_rows ROWS
    WHERE carrid   IN s_carrid
      AND cityfrom IN s_cityfr
    ORDER BY carrid connid.
  IF gt_spfli IS INITIAL.
    MESSAGE 'No connections found' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM display.
  DATA lx_msg TYPE REF TO cx_salv_msg.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_spfli ).
    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE lx_msg TYPE 'E'.
  ENDTRY.

  go_alv->get_functions( )->set_all( abap_true ).
  go_alv->get_display_settings( )->set_list_header( 'Flight connections' ).

  go_columns = go_alv->get_columns( ).
  go_columns->set_optimize( abap_true ).

  TRY.
      go_column ?= go_columns->get_column( 'MANDT' ).
      go_column->set_technical( abap_true ).
      go_column ?= go_columns->get_column( 'CITYFROM' ).
      go_column->set_short_text( 'From' ).
      go_column->set_medium_text( 'Departure' ).
      go_column->set_long_text( 'Departure city' ).
      go_column ?= go_columns->get_column( 'FLTIME' ).
      go_column->set_visible( abap_false ).
    CATCH cx_salv_not_found.
  ENDTRY.

  go_alv->display( ).
ENDFORM.
