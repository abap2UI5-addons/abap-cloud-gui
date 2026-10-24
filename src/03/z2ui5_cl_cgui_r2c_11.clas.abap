CLASS z2ui5_cl_cgui_r2c_11 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gt_numbers TYPE STANDARD TABLE OF i WITH DEFAULT KEY,
      gv_text    TYPE c LENGTH 40,
      gv_sum     TYPE i,
      gv_sum_txt TYPE c LENGTH 12.

    " selection screen
    DATA s_range LIKE RANGE OF gv_sum.
    DATA p_title TYPE c LENGTH 30.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_11 IMPLEMENTATION.

  METHOD initialization.

    s_range = VALUE #( ( sign = `I` option = `BT` low = 1 high = 20 ) ).
    p_title = 'Numbers'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->select_option( s_range
        )->parameter( p_title ).

  ENDMETHOD.

  METHOD start_of_selection.

    FIELD-SYMBOLS <gv_number> TYPE i.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_numbers,
           gv_text,
           gv_sum,
           gv_sum_txt.

    DO 20 TIMES.
      IF z2ui5_cl_cgui_context=>range_check( val = sy-index range = s_range ) = abap_true.
        APPEND sy-index TO gt_numbers.
      ENDIF.
    ENDDO.

    gv_text = |{ p_title }|.
    list( )->new_line(
        )->write( val   = gv_text
                  color = z2ui5_cl_cgui_list=>cs_color-key ).
    LOOP AT gt_numbers ASSIGNING <gv_number>.
      gv_sum = gv_sum + <gv_number>.
      list( )->new_line(
          )->write( <gv_number> ).
    ENDLOOP.
    CLEAR gv_text.
    gv_sum_txt = |{ gv_sum }|.
    CONCATENATE 'Sum:' gv_sum_txt INTO gv_text SEPARATED BY space.
    list( )->new_line(
        )->write( gv_text ).

  ENDMETHOD.

  METHOD at_user_command.

    CASE ucomm.
      WHEN 'BACK'.
        leave_to_selection_screen( ).
      WHEN 'REFRESH'.
        message( 'Refreshed' ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
