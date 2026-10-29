"! The stand-in of cl_gui_textedit - a text area in its container. The text
"! is a line of the report's controls, bound to the text area: what the
"! user types is there on the next roundtrip, get_textstream( ) and
"! get_text_as_r3table( ) read it at once (cl_gui_cfw=>flush( ) is not
"! needed). The text of a table is its lines with a line break between
"! them; word wrap, the toolbar and the status bar of SAP GUI have no
"! counterpart in the browser. F1 and F4 in the text raise the events f1 and
"! f4 once set_registered_events( ) names them, the cursor of the text
"! area then the selection of get_selection_pos( ); a double click has no
"! event of the text area of the browser
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
    CONSTANTS event_double_click         TYPE i VALUE 1.
    CONSTANTS event_f1                   TYPE i VALUE 4.
    CONSTANTS event_f4                   TYPE i VALUE 5.

    "! F1 in the text - get_selection_pos( ) is where the cursor stood
    EVENTS f1.
    "! F4 in the text
    EVENTS f4.
    "! never raised - the text area of the browser has no double click
    EVENTS dblclick.

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

    "! the events of the control the report gets - event_f1, event_f4
    METHODS set_registered_events
      IMPORTING
        events TYPE STANDARD TABLE
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    "! the selection when F1 or F4 was pressed - line and position from 1,
    "! from = to for the cursor without a selection
    METHODS get_selection_pos
      EXPORTING
        from_line TYPE i
        from_pos  TYPE i
        to_line   TYPE i
        to_pos    TYPE i
      EXCEPTIONS
        error_cntl_call_method.

    "! kept for get_selection_pos( ) - the cursor of the browser is not set
    METHODS set_selection_pos
      IMPORTING
        from_line TYPE i
        from_pos  TYPE i
        to_line   TYPE i
        to_pos    TYPE i
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

    "! an offset into the text as line and position, from 1
    METHODS position_of
      IMPORTING
        text   TYPE string
        offset TYPE i
      EXPORTING
        line   TYPE i
        pos    TYPE i.

    METHODS offset_of
      IMPORTING
        text          TYPE string
        line          TYPE i
        pos           TYPE i
      RETURNING
        VALUE(result) TYPE i.
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

  METHOD set_registered_events.

    DATA lt_key TYPE string_table.

    LOOP AT events ASSIGNING FIELD-SYMBOL(<event>).
      ASSIGN COMPONENT `EVENTID` OF STRUCTURE <event> TO FIELD-SYMBOL(<id>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      CASE <id>.
        WHEN event_f1.
          INSERT `F1` INTO TABLE lt_key.
        WHEN event_f4.
          INSERT `F4` INTO TABLE lt_key.
      ENDCASE.
    ENDLOOP.
    DATA(ls_control) = get( ).
    ls_control-keys = concat_lines_of( table = lt_key
                                       sep   = `,` ).
    put( ls_control ).

  ENDMETHOD.

  METHOD get_selection_pos.

    DATA(ls_control) = get( ).
    position_of( EXPORTING text   = ls_control-text
                           offset = ls_control-sel_from
                 IMPORTING line   = from_line
                           pos    = from_pos ).
    position_of( EXPORTING text   = ls_control-text
                           offset = ls_control-sel_to
                 IMPORTING line   = to_line
                           pos    = to_pos ).

  ENDMETHOD.

  METHOD set_selection_pos.

    DATA(ls_control) = get( ).
    ls_control-sel_from = offset_of( text = ls_control-text
                                     line = from_line
                                     pos  = from_pos ).
    ls_control-sel_to = offset_of( text = ls_control-text
                                   line = to_line
                                   pos  = to_pos ).
    put( ls_control ).

  ENDMETHOD.

  METHOD position_of.

    line = 1.
    pos = 1.
    DATA(lv_index) = 0.
    DATA(lv_end) = nmin( val1 = offset
                         val2 = strlen( text ) ).
    WHILE lv_index < lv_end.
      IF text+lv_index(1) = |\n|.
        line = line + 1.
        pos = 1.
      ELSE.
        pos = pos + 1.
      ENDIF.
      lv_index = lv_index + 1.
    ENDWHILE.

  ENDMETHOD.

  METHOD offset_of.

    DATA(lv_line) = 1.
    DATA(lv_len) = strlen( text ).
    WHILE result < lv_len AND lv_line < line.
      IF text+result(1) = |\n|.
        lv_line = lv_line + 1.
      ENDIF.
      result = result + 1.
    ENDWHILE.
    result = nmin( val1 = result + nmax( val1 = pos - 1
                                         val2 = 0 )
                   val2 = lv_len ).

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
