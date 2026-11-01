*&---------------------------------------------------------------------*
*& Report ZR2C_39_TEXTEDIT
*&---------------------------------------------------------------------*
*& A note editor on the screen itself: cl_gui_textedit in a docking
*& container of the list, filled from the selection screen, read back
*& with a button of a toolbar and counted
*&---------------------------------------------------------------------*
REPORT zr2c_39_textedit.

CLASS lcl_note DEFINITION.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS on_function FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.
    DATA mo_edit TYPE REF TO cl_gui_textedit.
    DATA mo_tool TYPE REF TO cl_gui_toolbar.
ENDCLASS.

PARAMETERS p_text TYPE string LOWER CASE DEFAULT 'Buy milk'.

DATA go_note TYPE REF TO lcl_note.

CLASS lcl_note IMPLEMENTATION.
  METHOD constructor.
    DATA lt_event TYPE cntl_simple_events.
    mo_tool = NEW cl_gui_toolbar( parent = cl_gui_container=>default_screen ).
    mo_tool->add_button( fcode = 'COUNT' icon = icon_okay butn_type = cntb_btype_button text = 'Count' ).
    APPEND VALUE #( eventid = cl_gui_toolbar=>m_id_function_selected appl_event = abap_true ) TO lt_event.
    mo_tool->set_registered_events( lt_event ).
    SET HANDLER on_function FOR mo_tool.
    mo_edit = NEW cl_gui_textedit( parent = cl_gui_container=>default_screen ).
    mo_edit->set_textstream( p_text ).
  ENDMETHOD.

  METHOD on_function.
    DATA lv_text TYPE string.
    mo_edit->get_textstream( IMPORTING text = lv_text ).
    cl_gui_cfw=>flush( ).
    MESSAGE |The note has { strlen( lv_text ) } characters| TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  go_note = NEW lcl_note( ).
  WRITE: space.
