*&---------------------------------------------------------------------*
*& Report ZR2C_25_TEXTEDIT
*&---------------------------------------------------------------------*
*& Notes of an airline on a dynpro with two SAP GUI controls: the text
*& editor in the custom control area NOTES, an HTML viewer in PREVIEW.
*& PBO creates them once and fills them, PAI reads the text on Save,
*& refreshes the preview on Check and leaves with Back; after the screen
*& the notes are the list.
*&---------------------------------------------------------------------*
REPORT zr2c_25_textedit.

TYPES ty_line TYPE c LENGTH 72.

PARAMETERS p_carrid TYPE c LENGTH 3 DEFAULT 'LH'.

DATA ok_code    TYPE sy-ucomm.
DATA go_notes   TYPE REF TO cl_gui_custom_container.
DATA go_editor  TYPE REF TO cl_gui_textedit.
DATA go_preview TYPE REF TO cl_gui_custom_container.
DATA go_html    TYPE REF TO cl_gui_html_viewer.
DATA gt_notes   TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
DATA gv_saved   TYPE c LENGTH 1.

START-OF-SELECTION.
  CLEAR gv_saved.
  gt_notes = VALUE #( ( 'First line of the notes' ) ( 'Second line' ) ).
  CALL SCREEN 100.
  IF gv_saved = 'X'.
    LOOP AT gt_notes INTO DATA(lv_note).
      WRITE / lv_note.
    ENDLOOP.
  ELSE.
    WRITE / 'Nothing saved'.
  ENDIF.

MODULE status_0100 OUTPUT.
  IF go_editor IS INITIAL.
    CREATE OBJECT go_notes
      EXPORTING
        container_name = 'NOTES'.
    CREATE OBJECT go_editor
      EXPORTING
        parent                     = go_notes
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = 72
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true.
    go_editor->set_toolbar_mode( cl_gui_textedit=>false ).
    go_editor->set_statusbar_mode( cl_gui_textedit=>false ).
    go_editor->set_text_as_r3table( gt_notes ).

    CREATE OBJECT go_preview
      EXPORTING
        container_name = 'PREVIEW'.
    CREATE OBJECT go_html
      EXPORTING
        parent = go_preview.
    PERFORM preview.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'SAVE'.
      go_editor->get_text_as_r3table( IMPORTING table = gt_notes ).
      gv_saved = 'X'.
      LEAVE TO SCREEN 0.
    WHEN 'CHECK'.
      go_editor->get_text_as_r3table( IMPORTING table = gt_notes ).
      PERFORM preview.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

FORM preview.
  DATA lt_html TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
  DATA lv_url  TYPE c LENGTH 250.
  APPEND |<h3>Notes of { p_carrid }</h3>| TO lt_html.
  LOOP AT gt_notes INTO DATA(lv_line).
    APPEND |<p>{ lv_line }</p>| TO lt_html.
  ENDLOOP.
  go_html->load_data( IMPORTING assigned_url = lv_url
                      CHANGING  data_table   = lt_html ).
  go_html->show_url( lv_url ).
ENDFORM.
