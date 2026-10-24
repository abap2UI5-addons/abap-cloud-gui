*&---------------------------------------------------------------------*
*& Report ZR2C_30_SALVCOLUMNS
*&---------------------------------------------------------------------*
*& Exam results in a CL_SALV_TABLE grid whose column headers are the
*& technical names with the text behind them - a loop over every column
*& of the grid, then one column hidden and a title
*&---------------------------------------------------------------------*
REPORT zr2c_30_salvcolumns.

TYPES:
  BEGIN OF ty_result,
    student TYPE c LENGTH 20,
    subject TYPE c LENGTH 15,
    points  TYPE i,
    passed  TYPE abap_bool,
  END OF ty_result.

DATA gt_result TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY.

PARAMETERS p_pass TYPE i DEFAULT 50.

START-OF-SELECTION.
  gt_result = VALUE #( ( student = 'Anna'  subject = 'Maths'   points = 71 )
                       ( student = 'Ben'   subject = 'Maths'   points = 44 )
                       ( student = 'Clara' subject = 'Physics' points = 58 ) ).
  LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<ls_result>).
    <ls_result>-passed = xsdbool( <ls_result>-points >= p_pass ).
  ENDLOOP.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_salv)
                              CHANGING  t_table      = gt_result ).

      LOOP AT lo_salv->get_columns( )->get( ) ASSIGNING FIELD-SYMBOL(<ls_column>).
        DATA(lo_column) = <ls_column>-r_column.
        lo_column->set_short_text( || ).
        lo_column->set_medium_text( || ).
        lo_column->set_long_text( |{ lo_column->get_columnname( ) } ({ lo_column->get_long_text( ) })| ).
      ENDLOOP.

      lo_salv->get_display_settings( )->set_list_header( 'Exam results' ).
      lo_salv->display( ).
    CATCH cx_salv_msg.
      MESSAGE 'The grid cannot be shown' TYPE 'E'.
  ENDTRY.
