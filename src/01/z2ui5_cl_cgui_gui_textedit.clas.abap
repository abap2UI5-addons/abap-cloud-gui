"! The stand-in of cl_gui_textedit - a text area in its container. The text
"! is a line of the report's controls, bound to the text area: what the
"! user types is there on the next roundtrip, get_textstream( ) and
"! get_text_as_r3table( ) read it at once (cl_gui_cfw=>flush( ) is not
"! needed). The text of a table is its lines with a line break between
"! them; word wrap, the toolbar and the status bar of SAP GUI have no
"! counterpart in the browser
CLASS z2ui5_cl_cgui_gui_textedit DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS wordwrap_off               TYPE i VALUE 0.
    CONSTANTS wordwrap_at_windowborder   TYPE i VALUE 1.
    CONSTANTS wordwrap_at_fixed_position TYPE i VALUE 2.
    CONSTANTS dropfile_event_off         TYPE i VALUE 0.
    CONSTANTS dropfile_event_single      TYPE i VALUE 1.
    CONSTANTS dropfile_event_multiple    TYPE i VALUE 2.

    METHODS constructor
      IMPORTING
        max_number_chars           TYPE i OPTIONAL
        style                      TYPE i OPTIONAL
        wordwrap_mode              TYPE i DEFAULT wordwrap_at_windowborder
        wordwrap_position          TYPE i DEFAULT -1
        wordwrap_to_linebreak_mode TYPE i DEFAULT z2ui5_cl_cgui_gui=>false
        filedrop_mode              TYPE i DEFAULT dropfile_event_off
        parent                     TYPE REF TO z2ui5_cl_cgui_gui_container
        lifetime                   TYPE i OPTIONAL
        name                       TYPE clike OPTIONAL
      EXCEPTIONS
        error_cntl_create
        error_cntl_init
        error_cntl_link
        error_dp_create
        gui_type_not_supported.

    METHODS set_textstream
      IMPORTING
        text TYPE clike
      EXCEPTIONS
        error_cntl_call_method
        not_supported_by_gui.

    METHODS get_textstream
      IMPORTING
        only_when_modified TYPE i DEFAULT z2ui5_cl_cgui_gui=>false
      EXPORTING
        text               TYPE clike
        is_modified        TYPE i
      EXCEPTIONS
        error_cntl_call_method
        not_supported_by_gui.

    METHODS set_text_as_r3table
      IMPORTING
        table TYPE STANDARD TABLE
      EXCEPTIONS
        error_dp
        error_dp_create.

    METHODS get_text_as_r3table
      IMPORTING
        only_when_modified TYPE i DEFAULT z2ui5_cl_cgui_gui=>false
      EXPORTING
        table              TYPE STANDARD TABLE
        is_modified        TYPE i
      EXCEPTIONS
        error_dp
        error_cntl_call_method
        error_dp_create
        potential_data_loss.

    "! the text as a table of lines - set_text_as_r3table( )
    METHODS set_text_as_stream
      IMPORTING
        text TYPE STANDARD TABLE
      EXCEPTIONS
        error_dp
        error_dp_create.

    METHODS get_text_as_stream
      IMPORTING
        only_when_modified TYPE i DEFAULT z2ui5_cl_cgui_gui=>false
      EXPORTING
        text               TYPE STANDARD TABLE
        is_modified        TYPE i
      EXCEPTIONS
        error_dp
        error_cntl_call_method.

    METHODS delete_text
      EXCEPTIONS
        error_cntl_call_method.

    METHODS set_readonly_mode
      IMPORTING
        readonly_mode TYPE i DEFAULT z2ui5_cl_cgui_gui=>true
      EXCEPTIONS
        error_cntl_call_method
        invalid_parameter.

    METHODS set_toolbar_mode
      IMPORTING
        toolbar_mode TYPE i DEFAULT z2ui5_cl_cgui_gui=>true
      EXCEPTIONS
        error_cntl_call_method
        invalid_parameter.

    METHODS set_statusbar_mode
      IMPORTING
        statusbar_mode TYPE i DEFAULT z2ui5_cl_cgui_gui=>true
      EXCEPTIONS
        error_cntl_call_method
        invalid_parameter.

    "! a fixed-width font - kept, the text area of the browser has none
    METHODS set_font_fixed
      IMPORTING
        mode TYPE i DEFAULT z2ui5_cl_cgui_gui=>true
      EXCEPTIONS
        error_cntl_call_method
        invalid_parameter.

    METHODS set_wordwrap_behavior
      IMPORTING
        wordwrap_mode              TYPE i OPTIONAL
        wordwrap_position          TYPE i OPTIONAL
        wordwrap_to_linebreak_mode TYPE i OPTIONAL
      EXCEPTIONS
        error_cntl_call_method.

    "! 1 when the user changed the text since it was set
    METHODS get_textmodified_status
      EXPORTING
        status TYPE i
      EXCEPTIONS
        error_cntl_call_method.

    METHODS set_textmodified_status
      IMPORTING
        status TYPE i DEFAULT 0
      EXCEPTIONS
        error_cntl_call_method.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! the text, and the user changed it after the program set it
    DATA mv_set TYPE string.

    METHODS text_put
      IMPORTING
        text TYPE string.

    METHODS lines_of
      IMPORTING
        text  TYPE string
      EXPORTING
        table TYPE STANDARD TABLE.

    METHODS text_of
      IMPORTING
        table         TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_textedit IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).
    IF add( VALUE #( kind    = z2ui5_if_cgui_gui=>cs_kind-textedit
                     parent  = id_of( parent )
                     toolbar = abap_true ) ) = abap_false.
      RAISE error_cntl_create.
    ENDIF.

  ENDMETHOD.

  METHOD set_textstream.

    text_put( CONV #( text ) ).

  ENDMETHOD.

  METHOD get_textstream.

    DATA(ls_control) = get( ).
    is_modified = COND #( WHEN ls_control-text <> mv_set THEN true ELSE false ).
    IF only_when_modified = true AND is_modified = false.
      RETURN.
    ENDIF.
    text = ls_control-text.

  ENDMETHOD.

  METHOD set_text_as_r3table.

    text_put( text_of( table ) ).

  ENDMETHOD.

  METHOD get_text_as_r3table.

    DATA(ls_control) = get( ).
    is_modified = COND #( WHEN ls_control-text <> mv_set THEN true ELSE false ).
    IF only_when_modified = true AND is_modified = false.
      RETURN.
    ENDIF.
    lines_of( EXPORTING text  = ls_control-text
              IMPORTING table = table ).

  ENDMETHOD.

  METHOD set_text_as_stream.

    text_put( text_of( text ) ).

  ENDMETHOD.

  METHOD get_text_as_stream.

    DATA(ls_control) = get( ).
    is_modified = COND #( WHEN ls_control-text <> mv_set THEN true ELSE false ).
    IF only_when_modified = true AND is_modified = false.
      RETURN.
    ENDIF.
    lines_of( EXPORTING text  = ls_control-text
              IMPORTING table = text ).

  ENDMETHOD.

  METHOD delete_text.

    text_put( `` ).

  ENDMETHOD.

  METHOD set_readonly_mode.

    DATA(ls_control) = get( ).
    ls_control-readonly = flag( readonly_mode ).
    put( ls_control ).

  ENDMETHOD.

  METHOD set_toolbar_mode.

    DATA(ls_control) = get( ).
    ls_control-toolbar = flag( toolbar_mode ).
    put( ls_control ).

  ENDMETHOD.

  METHOD set_statusbar_mode.

    DATA(ls_control) = get( ).
    ls_control-statusbar = flag( statusbar_mode ).
    put( ls_control ).

  ENDMETHOD.

  METHOD set_font_fixed.

    DATA(ls_control) = get( ).
    ls_control-fixed = flag( mode ).
    put( ls_control ).

  ENDMETHOD.

  METHOD set_wordwrap_behavior ##NEEDED.
  ENDMETHOD.

  METHOD get_textmodified_status.

    status = COND #( WHEN get( )-text <> mv_set THEN 1 ELSE 0 ).

  ENDMETHOD.

  METHOD set_textmodified_status.

    " status 0: the text as it is counts as not modified
    IF status = 0.
      mv_set = get( )-text.
    ELSE.
      CLEAR mv_set.
    ENDIF.

  ENDMETHOD.

  METHOD text_put.

    DATA(ls_control) = get( ).
    ls_control-text = text.
    put( ls_control ).
    mv_set = text.

  ENDMETHOD.

  METHOD lines_of.

    CLEAR table.
    IF text IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_text) = replace( val  = text
                             sub  = |\r\n|
                             with = |\n|
                             occ  = 0 ).
    SPLIT lv_text AT |\n| INTO TABLE DATA(lt_line).
    LOOP AT lt_line INTO DATA(lv_line).
      APPEND INITIAL LINE TO table ASSIGNING FIELD-SYMBOL(<line>).
      " a table of a structure (tline-tdline, a TEXT component) or of text
      ASSIGN COMPONENT `TDLINE` OF STRUCTURE <line> TO FIELD-SYMBOL(<text>).
      IF sy-subrc <> 0.
        ASSIGN COMPONENT `TEXT` OF STRUCTURE <line> TO <text>.
      ENDIF.
      IF sy-subrc <> 0.
        ASSIGN COMPONENT `LINE` OF STRUCTURE <line> TO <text>.
      ENDIF.
      IF sy-subrc = 0.
        <text> = lv_line.
      ELSE.
        <line> = lv_line.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD text_of.

    DATA lt_line TYPE string_table.

    LOOP AT table ASSIGNING FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT `TDLINE` OF STRUCTURE <line> TO FIELD-SYMBOL(<text>).
      IF sy-subrc <> 0.
        ASSIGN COMPONENT `TEXT` OF STRUCTURE <line> TO <text>.
      ENDIF.
      IF sy-subrc <> 0.
        ASSIGN COMPONENT `LINE` OF STRUCTURE <line> TO <text>.
      ENDIF.
      " a character field as string loses its trailing blanks, as the
      " classic editor showed the line
      IF sy-subrc = 0.
        INSERT CONV string( <text> ) INTO TABLE lt_line.
      ELSE.
        INSERT CONV string( <line> ) INTO TABLE lt_line.
      ENDIF.
    ENDLOOP.
    result = concat_lines_of( table = lt_line
                              sep   = |\n| ).

  ENDMETHOD.

ENDCLASS.
