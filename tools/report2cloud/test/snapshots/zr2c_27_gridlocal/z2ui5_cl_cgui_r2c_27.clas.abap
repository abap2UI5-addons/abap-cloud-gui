CLASS z2ui5_cl_cgui_r2c_27 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA ok_code TYPE sy-ucomm.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS at_gui_event REDEFINITION.

  PRIVATE SECTION.
    " global data of the report typed with its local classes - local types
    " can type the private section only
    DATA go_alv TYPE REF TO lcl_alv.

    METHODS status_0100.

    METHODS user_command_0100.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_27 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    set_title( `A grid in a local class` ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: go_alv,
           ok_code.

    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    lcl_r2c=>app = me.

    CASE dynnr.
      WHEN `0100`.
        screen->custom_control( `CC` ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pbo.

    lcl_r2c=>app = me.

    CASE dynnr.
      WHEN `0100`.
        status_0100( ).
    ENDCASE.

  ENDMETHOD.

  METHOD dynpro_pai.

    lcl_r2c=>app = me.

    CASE dynnr.
      WHEN `0100`.
        ok_code = ucomm.
        user_command_0100( ).
    ENDCASE.

  ENDMETHOD.

  METHOD at_gui_event.

    lcl_r2c=>app = me.

  ENDMETHOD.

  METHOD status_0100.

    IF go_alv IS INITIAL.
      go_alv = NEW lcl_alv( ).
      go_alv->select_connections( ).
      go_alv->display( ).
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
