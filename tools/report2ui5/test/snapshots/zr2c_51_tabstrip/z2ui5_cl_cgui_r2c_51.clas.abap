CLASS z2ui5_cl_cgui_r2c_51 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA tabstr    TYPE z2ui5_cl_cgui_report=>ty_s_tabstrip.
    DATA gv_dynnr  TYPE sy-dynnr.
    DATA gv_carrid TYPE c LENGTH 3 VALUE 'LH'.
    DATA gv_free   TYPE abap_bool.
    DATA ok_code   TYPE sy-ucomm.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS after_call_screen REDEFINITION.

  PRIVATE SECTION.
    METHODS status_0100.

    METHODS user_command_0100.

    METHODS check_0110.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_51 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A tabstrip on a dynpro` ).

  ENDMETHOD.

  METHOD start_of_selection.

    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    CASE dynnr.
      WHEN `0100`.
        screen->comment( `Choose a tab`
            )->tabbed_block_begin( `TABSTR`
            )->tab( text  = `Airline`
                    fcode = `TAB1`
                    area  = `SUB`
            )->tab( text  = `Seats`
                    fcode = `TAB2`
                    area  = `SUB`
            )->subscreen( `SUB`
            )->tabbed_block_end( ).
      WHEN `0110`.
        screen->parameter( val  = gv_carrid
                           text = `Airline` ).
      WHEN `0120`.
        screen->checkbox( val  = gv_free
                          text = `Only free seats` ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.

    CASE dynnr.
      WHEN `0100`.
        status_0100( ).
        call_subscreen( area = `SUB` dynnr = gv_dynnr ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pai.

    CASE dynnr.
      WHEN `0100`.
        ok_code = ucomm.
        call_subscreen_pai( area = `SUB` ucomm = ucomm ).
        IF screen_left( ) = abap_true.
          RETURN.
        ENDIF.
        user_command_0100( ).
      WHEN `0110`.
        check_0110( ).
    ENDCASE.

  ENDMETHOD.

  METHOD after_call_screen.

    CASE dynnr.
      WHEN `0100`.
        list( )->new_line(
            )->write( 'Airline'
            )->write( gv_carrid ).
        IF gv_free = abap_true.
          list( )->new_line(
              )->write( 'Only free seats' ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD status_0100.

    IF tabstr-activetab IS INITIAL.
      tabstr-activetab = 'TAB1'.
      gv_dynnr = '0110'.
    ENDIF.

  ENDMETHOD.

  METHOD user_command_0100.

    CASE ok_code.
      WHEN 'TAB1'.
        tabstr-activetab = ok_code.
        gv_dynnr = '0110'.
      WHEN 'TAB2'.
        tabstr-activetab = ok_code.
        gv_dynnr = '0120'.
      WHEN 'BACK'.
        leave_to_screen( `0000` ).
        RETURN.
    ENDCASE.

  ENDMETHOD.

  METHOD check_0110.

    TRANSLATE gv_carrid TO UPPER CASE.

  ENDMETHOD.

ENDCLASS.
