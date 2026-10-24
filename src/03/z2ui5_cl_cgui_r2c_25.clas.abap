CLASS z2ui5_cl_cgui_r2c_25 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES ty_line TYPE c LENGTH 72.

    " global data of the report
    DATA ok_code       TYPE sy-ucomm.
    DATA go_notes     TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA go_editor   TYPE REF TO z2ui5_cl_cgui_gui_textedit.
    DATA go_preview TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA go_html       TYPE REF TO z2ui5_cl_cgui_gui_html_viewer.
    DATA gt_notes     TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA gv_saved     TYPE c LENGTH 1.

    " selection screen
    DATA p_carrid TYPE c LENGTH 3.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS after_call_screen REDEFINITION.

  PRIVATE SECTION.
    METHODS preview.

    METHODS status_0100.

    METHODS user_command_0100.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_25 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Notes in a text editor` ).
    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_carrid
                       text = `Airline` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: ok_code,
           go_notes,
           go_editor,
           go_preview,
           go_html,
           gt_notes,
           gv_saved.

    CLEAR gv_saved.
    gt_notes = VALUE #( ( 'First line of the notes' ) ( 'Second line' ) ).
    call_screen( `0100` ).

  ENDMETHOD.

  METHOD dynpro_screen.

    CASE dynnr.
      WHEN `0100`.
        screen->parameter( val       = p_carrid
                           text      = `Airline`
                           read_only = abap_true
            )->line_begin(
            )->button( text  = `Check`
                       event = `CHECK`
            )->button( text  = `Save`
                       event = `SAVE`
            )->line_end(
            )->custom_control( `NOTES`
            )->custom_control( `PREVIEW` ).
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

  METHOD after_call_screen.

    CASE dynnr.
      WHEN `0100`.
        IF gv_saved = 'X'.
          LOOP AT gt_notes INTO DATA(lv_note).
            list( )->new_line(
                )->write( lv_note ).
          ENDLOOP.
        ELSE.
          list( )->new_line(
              )->write( 'Nothing saved' ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD preview.

    DATA lt_html TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url  TYPE c LENGTH 250.
    APPEND |<h3>Notes of { p_carrid }</h3>| TO lt_html.
    LOOP AT gt_notes INTO DATA(lv_line).
      APPEND |<p>{ lv_line }</p>| TO lt_html.
    ENDLOOP.
    go_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    go_html->show_url( lv_url ).

  ENDMETHOD.

  METHOD status_0100.

    IF go_editor IS INITIAL.
      go_notes = NEW #( container_name = 'NOTES' ).
      go_editor = NEW #( parent                     = go_notes
                         wordwrap_mode              = z2ui5_cl_cgui_gui_textedit=>wordwrap_at_fixed_position
                         wordwrap_position          = 72
                         wordwrap_to_linebreak_mode = z2ui5_cl_cgui_gui_textedit=>true ).
      go_editor->set_toolbar_mode( z2ui5_cl_cgui_gui_textedit=>false ).
      go_editor->set_statusbar_mode( z2ui5_cl_cgui_gui_textedit=>false ).
      go_editor->set_text_as_r3table( gt_notes ).

      go_preview = NEW #( container_name = 'PREVIEW' ).
      go_html = NEW #( parent = go_preview ).
      preview( ).
    ENDIF.

  ENDMETHOD.

  METHOD user_command_0100.

    CASE ok_code.
      WHEN 'SAVE'.
        go_editor->get_text_as_r3table( IMPORTING table = gt_notes ).
        gv_saved = 'X'.
        leave_to_screen( `0000` ).
        RETURN.
      WHEN 'CHECK'.
        go_editor->get_text_as_r3table( IMPORTING table = gt_notes ).
        preview( ).
      WHEN 'BACK'.
        leave_to_screen( `0000` ).
        RETURN.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
