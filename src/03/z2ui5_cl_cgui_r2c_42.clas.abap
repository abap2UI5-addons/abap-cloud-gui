CLASS z2ui5_cl_cgui_r2c_42 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_shelf,
        wine    TYPE c LENGTH 12,
        vintage TYPE n LENGTH 4,
        bottles TYPE i,
      END OF ty_shelf.
    TYPES ty_t_shelf TYPE STANDARD TABLE OF ty_shelf WITH DEFAULT KEY.

    " global data of the report
    DATA lv_total TYPE i.

    " selection screen
    DATA p_min TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_42 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A Cellar` ).
    p_min = 6.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_min
                       text = `Bottles at least` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA(lt_shelf) = VALUE ty_t_shelf( ( wine = 'Riesling' vintage = '2019' bottles = 12 )
                                       ( wine = 'Merlot'   vintage = '2016' bottles = 4 )
                                       ( wine = 'Rose'     vintage = '2021' bottles = 9 ) ).

    LOOP AT lt_shelf INTO DATA(ls_shelf).
      lv_total = lv_total + ls_shelf-bottles.
    ENDLOOP.
    DELETE lt_shelf WHERE bottles < p_min.

    z2ui5_cl_cgui_demo_output=>begin_section( 'Cellar' ).
    z2ui5_cl_cgui_demo_output=>write( lt_shelf ).
    DATA(lv_page) = z2ui5_cl_cgui_demo_output=>get( ).
    z2ui5_cl_cgui_abap_browser=>show_html( title       = 'Cellar'
                                html_string = lv_page ).

    list( )->new_line(
        )->write( |{ lv_total } bottles in the cellar| ).

  ENDMETHOD.

ENDCLASS.
