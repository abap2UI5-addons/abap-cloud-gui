CLASS z2ui5_cl_cgui_r2c_04 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gs_spfli   TYPE spfli,
      gt_spfli   TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.

    " selection screen
    DATA s_carrid LIKE RANGE OF gs_spfli-carrid.
    DATA s_cityfr LIKE RANGE OF gs_spfli-cityfrom.
    DATA p_rows   TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    METHODS select_data.

    METHODS display.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_04 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    s_carrid = VALUE #( ( sign = `I` option = `EQ` low = 'LH' ) ).
    p_rows = 200.

  ENDMETHOD.

  METHOD selection_screen.

    screen->select_option( val        = s_carrid
                           obligatory = abap_true
        )->select_option( val          = s_cityfr
                          no_intervals = abap_true
        )->parameter( p_rows ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gs_spfli,
           gt_spfli.

    select_data( ).
    display( ).

  ENDMETHOD.

  METHOD select_data.

    SELECT * FROM spfli INTO TABLE @gt_spfli
      UP TO @p_rows ROWS
      WHERE carrid   IN @s_carrid
        AND cityfrom IN @s_cityfr
      ORDER BY carrid, connid.
    IF gt_spfli IS INITIAL.
      message( text = 'No connections found'
               type = `W` ).
    ENDIF.

  ENDMETHOD.

  METHOD display.

    alv( gt_spfli
        )->set_title( 'Flight connections'
        )->set_column_text( name = `CITYFROM`
                            text = 'Departure city'
        )->set_column_hidden( `MANDT`
        )->set_column_hidden( `FLTIME` ).

  ENDMETHOD.

ENDCLASS.
