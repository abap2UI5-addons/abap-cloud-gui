"! The stand-in of cl_gui_html_viewer - HTML in its container.
"! load_data( ) keeps the lines of data_table as a document of its own and
"! answers with its URL, show_url( ) of that URL (or show_data( )) shows the
"! document. Where the frontend has the custom control z2ui5.cc.HTMLFrame
"! (abap2UI5 after 1.148), the document is shown as it is, its styles
"! included, in a frame under the page's policy - no script of it runs - and
"! its SAPEVENT links and the forms posted to a SAPEVENT action raise the
"! event sapevent with getdata and postdata, as in the SAP GUI. On an older
"! frontend it is sap.ui.core.HTML with sanitized content, its SAPEVENT links
"! as links below it. show_url( ) of an address on the web is a link that
"! opens it.
CLASS z2ui5_cl_cgui_html_viewer DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS m_id_sapevent TYPE i VALUE 1.

    TYPES ty_c255 TYPE c LENGTH 255.
    TYPES ty_t_post TYPE STANDARD TABLE OF ty_c255 WITH DEFAULT KEY.
    TYPES:
      "! a parameter of the query of a SAPEVENT link - as w3query
      BEGIN OF ty_s_query,
        name  TYPE c LENGTH 30,
        value TYPE c LENGTH 255,
      END OF ty_s_query,
      ty_t_query TYPE STANDARD TABLE OF ty_s_query WITH DEFAULT KEY,
      BEGIN OF ty_s_link,
        action TYPE string,
        text   TYPE string,
      END OF ty_s_link,
      ty_t_link TYPE STANDARD TABLE OF ty_s_link WITH DEFAULT KEY.

    "! a link SAPEVENT:action?query of the document, or a form posted to
    "! SAPEVENT:action - postdata the fields of the form, urlencoded, in
    "! lines of 255 characters
    EVENTS sapevent
      EXPORTING
        VALUE(action)      TYPE c OPTIONAL
        VALUE(frame)       TYPE c OPTIONAL
        VALUE(getdata)     TYPE c OPTIONAL
        VALUE(postdata)    TYPE ty_t_post OPTIONAL
        VALUE(query_table) TYPE ty_t_query OPTIONAL.

    METHODS constructor
      IMPORTING
        shellstyle               TYPE i OPTIONAL
        parent                   TYPE REF TO z2ui5_cl_cgui_container
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

    "! the document shown before - the history is the one of show_url( )
    METHODS go_back
      EXCEPTIONS
        cntl_error.

    METHODS go_forward
      EXCEPTIONS
        cntl_error.

    "! the URL of the document shown - the one show_url( ) or load_data( )
    "! named
    METHODS get_current_url
      EXPORTING
        url TYPE clike
      EXCEPTIONS
        cntl_error.

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

    METHODS dispatch REDEFINITION.

    "! the SAPEVENT links of a document - href="sapevent:action">text&lt;/a&gt;,
    "! found with string operations
    CLASS-METHODS sapevent_links
      IMPORTING
        html          TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_link.

  PROTECTED SECTION.
    " the URLs shown, oldest first, and the one shown now - kept with the
    " control from one roundtrip to the next, as the history of the browser
    DATA mt_history  TYPE string_table.
    DATA mv_position TYPE i.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_document,
        url  TYPE string,
        html TYPE string,
      END OF ty_s_document.

    TYPES temp1_cb11e940f2 TYPE STANDARD TABLE OF ty_s_document WITH DEFAULT KEY.
DATA mt_document TYPE temp1_cb11e940f2.

    "! the document of url into the control - from load_data( ), else a link
    METHODS display
      IMPORTING
        url TYPE string.

    METHODS text_of
      IMPORTING
        table         TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_html_viewer IMPLEMENTATION.

  METHOD constructor.
    DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_control.

    super->constructor( ).

    CLEAR temp1.
    temp1-kind = z2ui5_if_cgui_gui=>cs_kind-html.
    temp1-parent = id_of( parent ).
    IF add( temp1 ) = abap_false.
      RAISE cntl_error.
    ENDIF.

  ENDMETHOD.

  METHOD load_data.

    DATA temp2 TYPE string.
    DATA lv_url TYPE string.
    DATA temp3 TYPE z2ui5_cl_cgui_html_viewer=>ty_s_document.
    temp2 = url.

    lv_url = condense( temp2 ).
    IF lv_url IS INITIAL.
      lv_url = |z2ui5-cgui:{ get_id( ) }-{ lines( mt_document ) + 1 }.{ condense( subtype ) }|.
    ENDIF.
    DELETE mt_document WHERE url = lv_url.

    CLEAR temp3.
    temp3-url = lv_url.
    temp3-html = text_of( data_table ).
    INSERT temp3 INTO TABLE mt_document.
    assigned_url = lv_url.

  ENDMETHOD.

  METHOD show_url.

    DATA temp4 TYPE string.
    DATA lv_url TYPE string.
    temp4 = url.

    lv_url = condense( temp4 ).
    " a new page: what lay ahead of the one shown is gone
    WHILE lines( mt_history ) > mv_position.
      DELETE mt_history INDEX lines( mt_history ).
    ENDWHILE.
    INSERT lv_url INTO TABLE mt_history.
    mv_position = lines( mt_history ).
    display( lv_url ).

  ENDMETHOD.

  METHOD display.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA lv_url LIKE url.
    DATA ls_document TYPE z2ui5_cl_cgui_html_viewer=>ty_s_document.
    ls_control = get( ).

    lv_url = url.

    READ TABLE mt_document INTO ls_document WITH KEY url = lv_url.
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

    DATA temp5 TYPE string.
    DATA lv_url TYPE string.
      FIELD-SYMBOLS <temp6> LIKE LINE OF mt_document.
      DATA temp7 LIKE sy-tabix.
    temp5 = url.

    lv_url = condense( temp5 ).
    IF lv_url IS INITIAL AND mt_document IS NOT INITIAL.


      temp7 = sy-tabix.
      READ TABLE mt_document INDEX lines( mt_document ) ASSIGNING <temp6>.
      sy-tabix = temp7.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_url = <temp6>-url.
    ENDIF.
    show_url( lv_url ).

  ENDMETHOD.

  METHOD go_back.
      FIELD-SYMBOLS <temp8> LIKE LINE OF mt_history.
      DATA temp9 LIKE sy-tabix.

    IF mv_position > 1.
      mv_position = mv_position - 1.


      temp9 = sy-tabix.
      READ TABLE mt_history INDEX mv_position ASSIGNING <temp8>.
      sy-tabix = temp9.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      display( <temp8> ).
    ENDIF.

  ENDMETHOD.

  METHOD go_forward.
      FIELD-SYMBOLS <temp10> LIKE LINE OF mt_history.
      DATA temp11 LIKE sy-tabix.

    IF mv_position < lines( mt_history ).
      mv_position = mv_position + 1.


      temp11 = sy-tabix.
      READ TABLE mt_history INDEX mv_position ASSIGNING <temp10>.
      sy-tabix = temp11.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      display( <temp10> ).
    ENDIF.

  ENDMETHOD.

  METHOD get_current_url.
      FIELD-SYMBOLS <temp12> LIKE LINE OF mt_history.
      DATA temp13 LIKE sy-tabix.

    CLEAR url.
    IF mv_position > 0.


      temp13 = sy-tabix.
      READ TABLE mt_history INDEX mv_position ASSIGNING <temp12>.
      sy-tabix = temp13.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      url = <temp12>.
    ENDIF.

  ENDMETHOD.

  METHOD set_registered_events ##NEEDED.
  ENDMETHOD.

  METHOD close_document.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    ls_control = get( ).
    CLEAR: ls_control-html, ls_control-url.
    put( ls_control ).

  ENDMETHOD.

  METHOD dispatch.

    DATA lv_action TYPE c LENGTH 255.
    DATA lv_getdata TYPE c LENGTH 1024.
    DATA lt_query TYPE ty_t_query.
    DATA lv_head TYPE string.
    DATA lv_query TYPE string.
    TYPES temp6 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_pair TYPE temp6.
    DATA lv_pair LIKE LINE OF lt_pair.
      DATA lv_name TYPE string.
      DATA lv_value TYPE string.
      DATA temp14 TYPE z2ui5_cl_cgui_html_viewer=>ty_s_query.
    DATA lt_post TYPE ty_t_post.
    DATA lv_post LIKE post.
        DATA temp15 LIKE LINE OF lt_post.
        DATA temp16 LIKE LINE OF lt_post.
    DATA temp17 LIKE REF TO lt_query.
DATA temp1 LIKE REF TO lt_post.
DATA temp2 LIKE REF TO lv_getdata.
DATA temp3 LIKE REF TO lv_action.
DATA temp4 TYPE abap_parmbind_tab.
DATA temp5 LIKE LINE OF temp4.

    IF to_upper( event ) <> `SAPEVENT`.
      super->dispatch( event = event
                       value = value ).
      RETURN.
    ENDIF.
    " action?name=value&name=value


    SPLIT value AT `?` INTO lv_head lv_query.
    lv_action = lv_head.
    lv_getdata = lv_query.


    SPLIT lv_query AT `&` INTO TABLE lt_pair.

    LOOP AT lt_pair INTO lv_pair WHERE table_line IS NOT INITIAL.


      SPLIT lv_pair AT `=` INTO lv_name lv_value.

      CLEAR temp14.
      temp14-name = to_upper( lv_name ).
      temp14-value = lv_value.
      INSERT temp14 INTO TABLE lt_query.
    ENDLOOP.
    " the fields of a posted form, urlencoded, in lines of 255 characters


    lv_post = post.
    WHILE lv_post IS NOT INITIAL.
      IF strlen( lv_post ) > 255.

        temp15 = lv_post(255).
        INSERT temp15 INTO TABLE lt_post.
        lv_post = lv_post+255.
      ELSE.

        temp16 = lv_post.
        INSERT temp16 INTO TABLE lt_post.
        CLEAR lv_post.
      ENDIF.
    ENDWHILE.

    GET REFERENCE OF lt_query INTO temp17.

GET REFERENCE OF lt_post INTO temp1.

GET REFERENCE OF lv_getdata INTO temp2.

GET REFERENCE OF lv_action INTO temp3.

CLEAR temp4.

temp5-name = `ACTION`.
temp5-kind = cl_abap_objectdescr=>exporting.
temp5-value = temp3.
INSERT temp5 INTO TABLE temp4.
temp5-name = `GETDATA`.
temp5-kind = cl_abap_objectdescr=>exporting.
temp5-value = temp2.
INSERT temp5 INTO TABLE temp4.
temp5-name = `POSTDATA`.
temp5-kind = cl_abap_objectdescr=>exporting.
temp5-value = temp1.
INSERT temp5 INTO TABLE temp4.
temp5-name = `QUERY_TABLE`.
temp5-kind = cl_abap_objectdescr=>exporting.
temp5-value = temp17.
INSERT temp5 INTO TABLE temp4.
raise_event( event  = `SAPEVENT`
                 params = temp4 ).

  ENDMETHOD.

  METHOD enable_sapsso ##NEEDED.
  ENDMETHOD.

  METHOD show_url_in_browser.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA temp18 TYPE string.
    ls_control = get( ).
    CLEAR ls_control-html.

    temp18 = url.
    ls_control-url = condense( temp18 ).
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
    FIELD-SYMBOLS <line> TYPE ANY.
      FIELD-SYMBOLS <text> TYPE any.
      DATA temp19 TYPE string.
      DATA lv_text LIKE temp19.
      DATA lo_type TYPE REF TO cl_abap_typedescr.
      DATA lv_full TYPE abap_bool.
      DATA temp1 TYPE xsdboolean.
      DATA temp20 TYPE string.
    LOOP AT table ASSIGNING <line>.

      ASSIGN COMPONENT `LINE` OF STRUCTURE <line> TO <text>.
      IF sy-subrc <> 0.
        ASSIGN <line> TO <text>.
      ENDIF.

      temp19 = <text>.

      lv_text = temp19.

      lo_type = cl_abap_typedescr=>describe_by_data( <text> ).


      temp1 = boolc( lo_type->type_kind = cl_abap_typedescr=>typekind_char AND strlen( lv_text ) * cl_abap_char_utilities=>charsize >= lo_type->length ).
      lv_full = temp1.

      IF lv_full = abap_true OR lo_type->type_kind <> cl_abap_typedescr=>typekind_char.
        temp20 = result && lv_text.
      ELSE.
        temp20 = |{ result }{ lv_text }\n|.
      ENDIF.
      result = temp20.
    ENDLOOP.

  ENDMETHOD.

  METHOD sapevent_links.

    DATA lv_from TYPE i.
    DATA lv_pos  TYPE i.
    DATA lv_end  TYPE i.
    DATA lv_gt   TYPE i.
    DATA lv_lt   TYPE i.

    DATA lv_lower TYPE string.
      DATA lv_dq TYPE i.
      DATA lv_sq TYPE i.
      DATA temp21 TYPE ty_s_link.
      DATA ls_link LIKE temp21.
    lv_lower = to_lower( html ).
    DO.
      lv_pos = find( val = lv_lower sub = `sapevent:` off = lv_from ).
      IF lv_pos < 0.
        EXIT.
      ENDIF.
      lv_pos = lv_pos + 9.
      " the action ends at the quote of the attribute

      lv_dq = find( val = html sub = `"` off = lv_pos ).

      lv_sq = find( val = html sub = `'` off = lv_pos ).
      IF lv_sq < 0 OR ( lv_dq >= 0 AND lv_dq < lv_sq ).
        lv_end = lv_dq.
      ELSE.
        lv_end = lv_sq.
      ENDIF.
      IF lv_end < 0.
        EXIT.
      ENDIF.

      CLEAR temp21.
      temp21-action = substring( val = html off = lv_pos len = lv_end - lv_pos ).

      ls_link = temp21.
      lv_gt = find( val = html sub = `>` off = lv_end ).
      IF lv_gt >= 0.
        lv_lt = find( val = html sub = `<` off = lv_gt ).
        IF lv_lt > lv_gt.
          ls_link-text = condense( substring( val = html off = lv_gt + 1 len = lv_lt - lv_gt - 1 ) ).
        ENDIF.
      ENDIF.
      INSERT ls_link INTO TABLE result.
      lv_from = lv_end + 1.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
