CLASS z2ui5_cl_cgui_r2c_13 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_line,
        text TYPE c LENGTH 20,
        qty  TYPE i,
      END OF ty_line.

    " global data of the report
    DATA:
      gt_lines TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY,
      gs_line  TYPE ty_line,
      gv_total TYPE i.

    " selection screen
    DATA p_count TYPE i.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
    METHODS fill_lines.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_13 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    p_count = 3.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( p_count ).

  ENDMETHOD.

  METHOD start_of_selection.

    fill_lines( ).
    LOOP AT gt_lines INTO gs_line.
      gv_total = gv_total + gs_line-qty.
      list( )->new_line(
          )->write( gs_line-text ).
      write( gs_line-qty ).
    ENDLOOP.
    list( )->new_line(
        )->write( 'Total:'
        )->write( gv_total ).

  ENDMETHOD.

  METHOD fill_lines.

    DATA lv_i TYPE i.
    DO p_count TIMES.
      lv_i = lv_i + 1.
      gs_line-text = |Line { lv_i }|.
      gs_line-qty = lv_i * 10.
      APPEND gs_line TO gt_lines.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
