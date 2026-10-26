CLASS z2ui5_cl_cgui_r2c_43 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES ty_line TYPE x LENGTH 8.

    " global data of the report
    DATA go_edit   TYPE REF TO z2ui5_cl_cgui_gui_textedit.
    DATA lv_bytes  TYPE xstring.
    DATA lv_back   TYPE xstring.
    DATA lv_b64    TYPE string.
    DATA lv_length TYPE i.
    DATA lt_bin    TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.

    " selection screen
    DATA p_text TYPE string.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_43 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `A Base64 Message` ).
    p_text = 'See you at noon'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_text
                       text       = `Message`
                       lower_case = abap_true ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: go_edit,
           lv_bytes,
           lv_back,
           lv_b64,
           lv_length,
           lt_bin.

    z2ui5_cl_cgui_frontend=>scms_string_to_xstring( EXPORTING  text   = p_text
                                                    IMPORTING  buffer = lv_bytes
                                                    EXCEPTIONS failed = 1
                                                               OTHERS = 2 ).
    IF sy-subrc <> 0.
      message( text = 'The text has no bytes'
               type = `E` ).
      RETURN.
    ENDIF.

    z2ui5_cl_cgui_frontend=>scms_xstring_to_binary( EXPORTING  buffer        = lv_bytes
                                                    IMPORTING  output_length = lv_length
                                                    CHANGING   binary_tab    = lt_bin ).

    z2ui5_cl_cgui_frontend=>scms_binary_to_xstring( EXPORTING  input_length = lv_length
                                                               binary_tab   = lt_bin
                                                    IMPORTING  buffer       = lv_back
                                                    EXCEPTIONS failed       = 1
                                                               OTHERS       = 2 ).

    z2ui5_cl_cgui_frontend=>ssfc_base64_encode( EXPORTING  bindata = lv_back
                                                IMPORTING  b64data = lv_b64
                                                EXCEPTIONS OTHERS  = 1 ).

    go_edit = NEW #( parent = z2ui5_cl_cgui_gui_container=>default_screen ).
    go_edit->set_textstream( lv_b64 ).
    go_edit->set_readonly_mode( z2ui5_cl_cgui_gui_textedit=>true ).

    list( )->new_line(
        )->write( |{ lv_length } bytes in { lines( lt_bin ) } lines| ).
    IF lv_back = lv_bytes.
      list( )->new_line(
          )->write( 'The bytes came back unchanged' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
