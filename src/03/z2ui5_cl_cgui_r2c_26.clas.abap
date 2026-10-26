CLASS z2ui5_cl_cgui_r2c_26 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES ty_line TYPE c LENGTH 255.

    " global data of the report
    DATA ok_code TYPE sy-ucomm.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS at_roundtrip_start REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_app TYPE REF TO lcl_app.

    METHODS status_0100.

    METHODS user_command_0100.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_26 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Events of SAP GUI controls` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: go_app,
           ok_code.

    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    CASE dynnr.
      WHEN `0100`.
        screen->custom_control( `CC` ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.

    CASE dynnr.
      WHEN `0100`.
        status_0100( ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pai.

    CASE dynnr.
      WHEN `0100`.
        ok_code = ucomm.
        user_command_0100( ).
    ENDCASE.

  ENDMETHOD.

  METHOD at_roundtrip_start.

    lcl_r2c=>app = me.

  ENDMETHOD.

  METHOD status_0100.

    IF go_app IS INITIAL.
      go_app = NEW #( ).
      go_app->create( ).
    ENDIF.

  ENDMETHOD.

  METHOD user_command_0100.

    CASE ok_code.
      WHEN 'BACK'.
        leave_to_screen( `0000` ).
        RETURN.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
