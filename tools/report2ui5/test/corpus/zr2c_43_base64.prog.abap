*&---------------------------------------------------------------------*
*& Report ZR2C_43_BASE64
*&---------------------------------------------------------------------*
*& A message for the mail: the text as UTF-8 bytes, cut into lines of
*& eight bytes and back, in base64 and back again - the base64 in a text
*& editor on the screen, the check in the list
*&---------------------------------------------------------------------*
REPORT zr2c_43_base64.

TYPES ty_line TYPE x LENGTH 8.

DATA go_edit TYPE REF TO cl_gui_textedit.

PARAMETERS p_text TYPE string LOWER CASE DEFAULT 'See you at noon'.

START-OF-SELECTION.
  DATA lv_bytes TYPE xstring.
  DATA lv_back TYPE xstring.
  DATA lv_b64 TYPE string.
  DATA lv_length TYPE i.
  DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.

  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = p_text
    IMPORTING
      buffer = lv_bytes
    EXCEPTIONS
      failed = 1
      OTHERS = 2.
  IF sy-subrc <> 0.
    MESSAGE 'The text has no bytes' TYPE 'E'.
  ENDIF.

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = lv_bytes
    IMPORTING
      output_length = lv_length
    TABLES
      binary_tab    = lt_bin.

  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_length
    IMPORTING
      buffer       = lv_back
    TABLES
      binary_tab   = lt_bin
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.

  CALL FUNCTION 'SSFC_BASE64_ENCODE'
    EXPORTING
      bindata = lv_back
    IMPORTING
      b64data = lv_b64
    EXCEPTIONS
      OTHERS  = 1.

  go_edit = NEW #( parent = cl_gui_container=>default_screen ).
  go_edit->set_textstream( lv_b64 ).
  go_edit->set_readonly_mode( cl_gui_textedit=>true ).

  WRITE: / |{ lv_length } bytes in { lines( lt_bin ) } lines|.
  IF lv_back = lv_bytes.
    WRITE: / 'The bytes came back unchanged'.
  ENDIF.
