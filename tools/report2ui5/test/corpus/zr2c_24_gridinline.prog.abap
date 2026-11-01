*&---------------------------------------------------------------------*
*& Report ZR2C_24_GRIDINLINE
*&---------------------------------------------------------------------*
*& The grid of a report without a selection screen, written the way of
*& 7.40: INITIALIZATION reads the connections, creates the grid and its
*& custom container inline, builds the field catalog with VALUE and
*& calls screen 100 when the first display went through. The PAI module
*& leaves the screen with Back.
*&---------------------------------------------------------------------*
REPORT zr2c_24_gridinline.

INITIALIZATION.
  SELECT * FROM spfli INTO TABLE @DATA(connections) ORDER BY carrid, connid.

  DATA(grid) = NEW cl_gui_alv_grid(
    i_parent = NEW cl_gui_custom_container( container_name = 'CC' ) ).

  DATA(fcat) = VALUE lvc_t_fcat(
    ( fieldname = 'CARRID'   coltext = 'Airline' )
    ( fieldname = 'CONNID'   coltext = 'Flight' )
    ( fieldname = 'CITYFROM' coltext = 'From' )
    ( fieldname = 'CITYTO'   coltext = 'To' )
    ( fieldname = 'MANDT'    no_out = abap_true ) ).

  grid->set_table_for_first_display(
    EXPORTING
      i_structure_name              = 'SPFLI'
    CHANGING
      it_fieldcatalog               = fcat
      it_outtab                     = connections
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4 ).
  IF sy-subrc = 0.
    CALL SCREEN 100.
  ENDIF.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
