CLASS z2ui5_cl_cgui_r2c_24 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_24 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Connections in a grid` ).

  ENDMETHOD.

  METHOD start_of_selection.

    SELECT * FROM spfli INTO TABLE @DATA(connections) ORDER BY carrid, connid.

    alv( connections
        )->set_column_text( name = `CARRID`
                            text = 'Airline'
        )->set_column_text( name = `CONNID`
                            text = 'Flight'
        )->set_column_text( name = `CITYFROM`
                            text = 'From'
        )->set_column_text( name = `CITYTO`
                            text = 'To'
        )->set_column_hidden( `MANDT` ).

  ENDMETHOD.

  METHOD at_user_command.

    " the PAI module of the screen - the OK code is ucomm
    CASE ucomm.
      WHEN 'BACK' OR 'EXIT' OR 'CANC'.
        leave_to_selection_screen( ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
