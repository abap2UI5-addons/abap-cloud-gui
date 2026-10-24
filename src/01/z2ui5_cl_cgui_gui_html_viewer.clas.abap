"! The stand-in of cl_gui_html_viewer - HTML in its container.
"! load_data( ) keeps the lines of data_table as a document of its own and
"! answers with its URL, show_url( ) of that URL (or show_data( )) shows the
"! document - as sap.ui.core.HTML with sanitized content: no script, no
"! event handler. show_url( ) of an address on the web is a link that opens
"! it. The events of the viewer (SAPEVENT) have no counterpart yet
CLASS z2ui5_cl_cgui_gui_html_viewer DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS m_id_sapevent TYPE i VALUE 1.

    METHODS constructor
      IMPORTING
        shellstyle               TYPE i OPTIONAL
        parent                   TYPE REF TO z2ui5_cl_cgui_gui_container
        lifetime                 TYPE i OPTIONAL
        saphtmlp                 TYPE clike OPTIONAL
        uiflag                   TYPE i OPTIONAL
        end_session_with_browser TYPE i OPTIONAL
        name                     TYPE clike OPTIONAL
        saphttp                  TYPE clike OPTIONAL
        query_table_disabled     TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_install_error
        dp_install_error
        dp_error.

    METHODS load_data
      IMPORTING
        url          TYPE clike OPTIONAL
        type         TYPE clike DEFAULT 'text'
        subtype      TYPE clike DEFAULT 'html'
        size         TYPE i OPTIONAL
        encoding     TYPE clike OPTIONAL
        charset      TYPE clike OPTIONAL
        needfiltering TYPE i OPTIONAL
        language     TYPE clike OPTIONAL
        i_tidyt      TYPE clike OPTIONAL
      EXPORTING
        assigned_url TYPE clike
      CHANGING
        data_table   TYPE STANDARD TABLE
      EXCEPTIONS
        dp_invalid_parameter
        dp_error_general
        cntl_error
        html_syntax_notcorrect.

    METHODS show_url
      IMPORTING
        url      TYPE clike
        frame    TYPE clike OPTIONAL
        in_place TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cnht_error_not_allowed
        cnht_error_parameter
        dp_error_general.

    "! the document loaded last, or the one of url
    METHODS show_data
      IMPORTING
        url      TYPE clike OPTIONAL
        frame    TYPE clike OPTIONAL
        in_place TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cnht_error_not_allowed
        cnht_error_parameter
        dp_error_general.

    METHODS set_registered_events
      IMPORTING
        events TYPE STANDARD TABLE
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    METHODS close_document
      EXCEPTIONS
        cntl_error.

    "! single sign-on - the browser sends its own credentials
    METHODS enable_sapsso
      IMPORTING
        enabled TYPE clike DEFAULT abap_true
      EXCEPTIONS
        cntl_error.

    "! the URL in a browser of its own - a link that opens it
    METHODS show_url_in_browser
      IMPORTING
        url TYPE clike
      EXCEPTIONS
        cntl_error.

    "! the document shown in a browser of its own - a link that opens it
    METHODS detach_url_in_browser
      IMPORTING
        url TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_document,
        url  TYPE string,
        html TYPE string,
      END OF ty_s_document.

    DATA mt_document TYPE STANDARD TABLE OF ty_s_document WITH EMPTY KEY.

    METHODS text_of
      IMPORTING
        table         TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_html_viewer IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).
    IF add( VALUE #( kind   = z2ui5_if_cgui_gui=>cs_kind-html
                     parent = id_of( parent ) ) ) = abap_false.
      RAISE cntl_error.
    ENDIF.

  ENDMETHOD.

  METHOD load_data.

    DATA(lv_url) = condense( CONV string( url ) ).
    IF lv_url IS INITIAL.
      lv_url = |z2ui5-cgui:{ get_id( ) }-{ lines( mt_document ) + 1 }.{ condense( subtype ) }|.
    ENDIF.
    DELETE mt_document WHERE url = lv_url.
    INSERT VALUE #( url  = lv_url
                    html = text_of( data_table ) ) INTO TABLE mt_document.
    assigned_url = lv_url.

  ENDMETHOD.

  METHOD show_url.

    DATA(ls_control) = get( ).
    DATA(lv_url) = condense( CONV string( url ) ).
    READ TABLE mt_document INTO DATA(ls_document) WITH KEY url = lv_url.
    IF sy-subrc = 0.
      ls_control-html = ls_document-html.
      CLEAR ls_control-url.
    ELSE.
      CLEAR ls_control-html.
      ls_control-url = lv_url.
    ENDIF.
    put( ls_control ).

  ENDMETHOD.

  METHOD show_data.

    DATA(lv_url) = condense( CONV string( url ) ).
    IF lv_url IS INITIAL AND mt_document IS NOT INITIAL.
      lv_url = mt_document[ lines( mt_document ) ]-url.
    ENDIF.
    show_url( lv_url ).

  ENDMETHOD.

  METHOD set_registered_events ##NEEDED.
  ENDMETHOD.

  METHOD close_document.

    DATA(ls_control) = get( ).
    CLEAR: ls_control-html, ls_control-url.
    put( ls_control ).

  ENDMETHOD.

  METHOD enable_sapsso ##NEEDED.
  ENDMETHOD.

  METHOD show_url_in_browser.

    DATA(ls_control) = get( ).
    CLEAR ls_control-html.
    ls_control-url = condense( CONV string( url ) ).
    put( ls_control ).

  ENDMETHOD.

  METHOD detach_url_in_browser.

    IF url IS NOT INITIAL.
      show_url_in_browser( url ).
    ENDIF.

  ENDMETHOD.

  METHOD text_of.

    " the lines one after another - a line filled to its last character
    " goes on in the next one (a document cut into lines of 255), a
    " shorter one ends where the program ended it
    LOOP AT table ASSIGNING FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT `LINE` OF STRUCTURE <line> TO FIELD-SYMBOL(<text>).
      IF sy-subrc <> 0.
        ASSIGN <line> TO <text>.
      ENDIF.
      DATA(lv_text) = CONV string( <text> ).
      DATA(lo_type) = cl_abap_typedescr=>describe_by_data( <text> ).
      DATA(lv_full) = xsdbool( lo_type->type_kind = cl_abap_typedescr=>typekind_char
                               AND strlen( lv_text ) * cl_abap_char_utilities=>charsize >= lo_type->length ).
      result = COND #( WHEN lv_full = abap_true OR lo_type->type_kind <> cl_abap_typedescr=>typekind_char
                       THEN result && lv_text
                       ELSE |{ result }{ lv_text }\n| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
