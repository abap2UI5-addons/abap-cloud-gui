CLASS z2ui5_cl_cgui_sample_07 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_carrier,
        carrid TYPE c LENGTH 3,
        name   TYPE c LENGTH 30,
      END OF ty_s_carrier.
    TYPES ty_t_carrier TYPE STANDARD TABLE OF ty_s_carrier WITH DEFAULT KEY.

    " standard F4 from the DDIC: domain fixed values, a value table
    DATA p_option TYPE ddoption.
    DATA p_sign   TYPE ddsign.
    DATA p_waers  TYPE waers.
    DATA s_option TYPE RANGE OF ddoption.
    " F4 answered by the report
    DATA p_carrid TYPE c LENGTH 3.
    DATA s_carrid TYPE RANGE OF ty_s_carrier-carrid.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_value_request REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_07 IMPLEMENTATION.

  METHOD initialization.

    set_title( `abap-cloud-gui - Value Helps` ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Standard F4 - from the DDIC`
        )->parameter( val  = p_option
                      text = `Option`
        )->parameter( val  = p_sign
                      text = `Sign`
        )->parameter( val  = p_waers
                      text = `Currency`
        )->select_option( val  = s_option
                          text = `Options`
        )->comment( `Fixed values of the domain, or its value table on premise - no code needed.`
        )->block_end(
        )->block_begin( `Own F4 - at_value_request( )`
        )->parameter( val        = p_carrid
                      text       = `Airline`
                      value_help = abap_true
        )->select_option( val        = s_carrid
                          text       = `Airlines`
                          value_help = abap_true
        )->block_end( ).

  ENDMETHOD.

  METHOD at_value_request.
        DATA temp1 TYPE ty_t_carrier.
        DATA temp2 LIKE LINE OF temp1.

    CASE field.
      WHEN `P_CARRID` OR `S_CARRID`.

        CLEAR temp1.

        temp2-carrid = `AA`.
        temp2-name = `American Airlines`.
        INSERT temp2 INTO TABLE temp1.
        temp2-carrid = `LH`.
        temp2-name = `Lufthansa`.
        INSERT temp2 INTO TABLE temp1.
        temp2-carrid = `SQ`.
        temp2-name = `Singapore Airlines`.
        INSERT temp2 INTO TABLE temp1.
        temp2-carrid = `UA`.
        temp2-name = `United Airlines`.
        INSERT temp2 INTO TABLE temp1.
        value_help_popup( tab   = temp1
                          col   = `CARRID`
                          title = `Airlines` ).
      WHEN OTHERS.
        super->at_value_request( field ).
    ENDCASE.

  ENDMETHOD.

  METHOD start_of_selection.

    write( val   = `Selection`
           color = z2ui5_cl_cgui_list=>cs_color-key )->uline( ).
    write( |Option: { p_option }| )->new_line( ).
    write( |Sign: { p_sign }| )->new_line( ).
    write( |Currency: { p_waers }| )->new_line( ).
    write( |Options: { z2ui5_cl_cgui_context=>range_to_text( s_option ) }| )->new_line( ).
    write( |Airline: { p_carrid }| )->new_line( ).
    write( |Airlines: { z2ui5_cl_cgui_context=>range_to_text( s_carrid ) }| ).

  ENDMETHOD.

ENDCLASS.
