CLASS z2ui5_cl_cgui_r2c_05 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA scarr TYPE scarr.
    DATA:
      gt_scarr    TYPE STANDARD TABLE OF scarr WITH DEFAULT KEY,
      gs_scarr    TYPE scarr.

    " selection screen
    DATA p_curr TYPE scarr-currcode.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_05 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( p_curr ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: scarr,
           gt_scarr,
           gs_scarr.

    IF p_curr IS INITIAL.
      SELECT * FROM scarr INTO TABLE @gt_scarr.
    ELSE.
      SELECT * FROM scarr INTO TABLE @gt_scarr WHERE currcode = @p_curr.
    ENDIF.

    alv( gt_scarr
        )->set_title( 'Airlines'
        )->set_column_text( name = `CARRID`
                            text = 'Airline'
        )->set_column_text( name = `CARRNAME`
                            text = 'Name'
        )->set_column_text( name = `CURRCODE`
                            text = 'Currency'
        )->set_column_text( name = `URL`
                            text = 'Website'
        )->set_column_hidden( `MANDT`
        )->set_line_selection( ).

  ENDMETHOD.

  METHOD at_line_selection.

    " the ALV double click - FORM user_command, the USER_COMMAND callback
    DATA(r_ucomm) = `&IC1`.
    CASE r_ucomm.
      WHEN '&IC1'.
        READ TABLE gt_scarr INTO gs_scarr INDEX row.
        IF sy-subrc = 0.
          MOVE-CORRESPONDING gs_scarr TO scarr.
          message( text = |{ scarr-carrname }: { scarr-url }|
                   type = `I` ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
