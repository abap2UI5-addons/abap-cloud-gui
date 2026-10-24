CLASS z2ui5_cl_cgui_r2c_12 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " global data of the report
    DATA:
      gv_num   TYPE i,
      gv_count TYPE i.

    " selection screen
    DATA p_lines TYPE i.
    DATA s_skip  LIKE RANGE OF gv_num.
    DATA p_list  TYPE abap_bool.
    DATA p_last  TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS at_selection_screen_on_block REDEFINITION.
    METHODS at_selection_screen_on_radio REDEFINITION.
    METHODS at_selection_screen_on_end_of REDEFINITION.
    METHODS at_selection_screen_on_exit REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS end_of_selection REDEFINITION.
    METHODS top_of_page REDEFINITION.
    METHODS top_of_page_line_selection REDEFINITION.
    METHODS end_of_page REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_12 IMPLEMENTATION.

  METHOD initialization.

    set_line_count( 6 ).
    p_lines = 7.
    p_list = abap_true.

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( name = `B1`
        )->parameter( p_lines
        )->select_option( val          = s_skip
                          no_intervals = abap_true
        )->block_end(
        )->radiobutton( val   = p_list
                        group = `MODE`
        )->radiobutton( val   = p_last
                        group = `MODE` ).

  ENDMETHOD.

  METHOD at_selection_screen_on_block.

    CASE block.
      WHEN `B1`.
        IF p_lines > 20.
          message( text = 'At most 20 lines'
                   type = `E` ).
          RETURN.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen_on_radio.

    CASE group.
      WHEN `MODE`.
        IF p_last = abap_true AND p_lines < 2.
          message( text = 'A last page needs two lines'
                   type = `E` ).
          RETURN.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen_on_end_of.

    CASE field.
      WHEN `S_SKIP`.
        IF lines( s_skip ) > 3.
          message( text = 'Skip at most 3 numbers'
                   type = `E` ).
          RETURN.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_selection_screen_on_exit.

    message( 'Selection left' ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gv_num,
           gv_count.

    DO p_lines TIMES.
      gv_num = sy-index.
      IF s_skip IS NOT INITIAL AND z2ui5_cl_cgui_context=>range_check( val = gv_num range = s_skip ) = abap_true.
        CONTINUE.
      ENDIF.
      list( )->new_line(
          )->write( val     = gv_num
                    hotspot = abap_true
                    hide    = gv_num ).
      gv_count = gv_count + 1.
    ENDDO.
    IF p_last = abap_true.
      list( )->new_page( no_heading = abap_true ).
      list( )->new_line(
          )->write( 'Last page' ).
    ENDIF.

  ENDMETHOD.

  METHOD end_of_selection.

    list( )->new_line(
        )->write( 'Count:'
        )->write( gv_count ).

  ENDMETHOD.

  METHOD top_of_page.

    list( )->new_line(
        )->write( 'Numbers - page'
        )->write( z2ui5_cl_cgui_list=>cv_page ).
    list( )->uline( ).

  ENDMETHOD.

  METHOD top_of_page_line_selection.

    list( )->new_line(
        )->write( 'Detail' ).
    list( )->uline( ).

  ENDMETHOD.

  METHOD end_of_page.

    list( )->new_line(
        )->write( 'continued' ).

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the field the clicked line was written with
    gv_num = hide.

    list( )->new_line(
        )->write( 'Number'
        )->write( gv_num ).

  ENDMETHOD.

ENDCLASS.
