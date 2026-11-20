CLASS z2ui5_cl_cgui_r2c_25 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES ty_line TYPE c LENGTH 72.

    " global data of the report
    DATA ok_code       TYPE sy-ucomm.
    DATA go_notes     TYPE REF TO z2ui5_cl_cgui_container.
    DATA go_editor   TYPE REF TO z2ui5_cl_cgui_textedit.
    DATA go_preview TYPE REF TO z2ui5_cl_cgui_container.
    DATA go_html       TYPE REF TO z2ui5_cl_cgui_html_viewer.
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

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Notes in a text editor` ).
    p_carrid = 'LH'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_carrid
                       text = `Airline` ).

  ENDMETHOD.

  METHOD start_of_selection.
    DATA temp1 LIKE gt_notes.

    CLEAR gv_saved.

    CLEAR temp1.
    INSERT 'First line of the notes' INTO TABLE temp1.
    INSERT 'Second line' INTO TABLE temp1.
    gt_notes = temp1.
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
          DATA lv_note LIKE LINE OF gt_notes.

    CASE dynnr.
      WHEN `0100`.
        IF gv_saved = 'X'.

          LOOP AT gt_notes INTO lv_note.
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
    DATA temp3 LIKE LINE OF lt_html.
    DATA lv_line LIKE LINE OF gt_notes.
      DATA temp4 LIKE LINE OF lt_html.
    temp3 = |<h3>Notes of { p_carrid }</h3>|.
    APPEND temp3 TO lt_html.

    LOOP AT gt_notes INTO lv_line.

      temp4 = |<p>{ lv_line }</p>|.
      APPEND temp4 TO lt_html.
    ENDLOOP.
    go_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    go_html->show_url( lv_url ).

  ENDMETHOD.

  METHOD status_0100.

    IF go_editor IS INITIAL.
      CREATE OBJECT go_notes EXPORTING container_name = 'NOTES'.
      CREATE OBJECT go_editor EXPORTING parent = go_notes wordwrap_mode = z2ui5_cl_cgui_textedit=>wordwrap_at_fixed_position wordwrap_position = 72 wordwrap_to_linebreak_mode = z2ui5_cl_cgui_textedit=>true.
      go_editor->set_toolbar_mode( z2ui5_cl_cgui_textedit=>false ).
      go_editor->set_statusbar_mode( z2ui5_cl_cgui_textedit=>false ).
      go_editor->set_text_as_r3table( gt_notes ).

      CREATE OBJECT go_preview EXPORTING container_name = 'PREVIEW'.
      CREATE OBJECT go_html EXPORTING parent = go_preview.
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
