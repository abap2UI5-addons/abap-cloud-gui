"! The stand-in of cl_abap_browser - an HTML document, a URL or an XML
"! document shown by the report it runs in. With container (often
"! cl_gui_container=>default_screen) the document is a control of that
"! container - on the screen itself it shows above the list of the run;
"! without one it shows in a dialog box of its own, title its caption,
"! Close its end. It is z2ui5_cl_cgui_gui_html_viewer underneath, so the
"! HTML is sanitized: no script, no event handler, the SAPEVENT links as
"! links below it. Size, position, format, printing, the context menu and
"! the buttons of the classic window have no counterpart
CLASS z2ui5_cl_cgui_abap_browser DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES html_line TYPE c LENGTH 255.
    TYPES html_table TYPE STANDARD TABLE OF html_line WITH DEFAULT KEY.

    " the sizes, formats and positions of the classic window
    CONSTANTS small       TYPE string VALUE `S`.
    CONSTANTS medium      TYPE string VALUE `M`.
    CONSTANTS large       TYPE string VALUE `L`.
    CONSTANTS xlarge      TYPE string VALUE `XL`.
    CONSTANTS landscape   TYPE string VALUE `LANDSCAPE`.
    CONSTANTS portrait    TYPE string VALUE `PORTRAIT`.
    CONSTANTS topleft     TYPE string VALUE `TOPLEFT`.
    CONSTANTS topright    TYPE string VALUE `TOPRIGHT`.
    CONSTANTS middle      TYPE string VALUE `MIDDLE`.
    CONSTANTS bottomleft  TYPE string VALUE `BOTTOMLEFT`.
    CONSTANTS bottomright TYPE string VALUE `BOTTOMRIGHT`.
    " the buttons of the window
    CONSTANTS navigate_off  TYPE string VALUE ``.
    CONSTANTS navigate_html TYPE string VALUE `X`.

    CLASS-METHODS show_html
      IMPORTING
        html         TYPE html_table OPTIONAL
        html_string  TYPE string OPTIONAL
        html_xstring TYPE xstring OPTIONAL
        title        TYPE clike OPTIONAL
        size         TYPE clike OPTIONAL
        modal        TYPE abap_bool OPTIONAL
        format       TYPE clike OPTIONAL
        position     TYPE clike OPTIONAL
        context_menu TYPE abap_bool OPTIONAL
        container    TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        check_html   TYPE abap_bool OPTIONAL
        printing     TYPE abap_bool OPTIONAL
        buttons      TYPE clike OPTIONAL
        dialog       TYPE abap_bool OPTIONAL
        data_table   TYPE STANDARD TABLE OPTIONAL
        anchor       TYPE clike OPTIONAL
        style        TYPE clike OPTIONAL
      EXPORTING
        html_errors  TYPE string_table.

    CLASS-METHODS show_url
      IMPORTING
        url          TYPE clike
        title        TYPE clike OPTIONAL
        size         TYPE clike OPTIONAL
        modal        TYPE abap_bool OPTIONAL
        format       TYPE clike OPTIONAL
        position     TYPE clike OPTIONAL
        context_menu TYPE abap_bool OPTIONAL
        container    TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        printing     TYPE abap_bool OPTIONAL
        buttons      TYPE clike OPTIONAL.

    "! the XML as text, in the lines it has
    CLASS-METHODS show_xml
      IMPORTING
        xml_string   TYPE string OPTIONAL
        xml_xstring  TYPE xstring OPTIONAL
        title        TYPE clike OPTIONAL
        size         TYPE clike OPTIONAL
        modal        TYPE abap_bool OPTIONAL
        format       TYPE clike OPTIONAL
        position     TYPE clike OPTIONAL
        context_menu TYPE abap_bool OPTIONAL
        container    TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        printing     TYPE abap_bool OPTIONAL
        buttons      TYPE clike OPTIONAL.

    "! the dialog box of the document shown last is gone
    CLASS-METHODS close_browser.

    "! Close of the window of its own - the dialog box is gone
    CLASS-METHODS on_close FOR EVENT close OF z2ui5_cl_cgui_gui_container
      IMPORTING
        sender.

    "! html as the lines a viewer loads - 255 characters each
    CLASS-METHODS lines_of
      IMPORTING
        html          TYPE string
      RETURNING
        VALUE(result) TYPE html_table.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-DATA go_box TYPE REF TO z2ui5_cl_cgui_gui_container.

    "! window: no container was passed - a dialog box of its own
    CLASS-METHODS viewer
      IMPORTING
        container     TYPE REF TO z2ui5_cl_cgui_gui_container
        window        TYPE abap_bool
        title         TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_gui_html_viewer.

ENDCLASS.


CLASS z2ui5_cl_cgui_abap_browser IMPLEMENTATION.

  METHOD show_html.

    CLEAR html_errors.
    DATA(lv_html) = html_string.
    IF lv_html IS INITIAL AND html_xstring IS NOT INITIAL.
      lv_html = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( html_xstring ).
    ENDIF.
    IF lv_html IS INITIAL.
      LOOP AT html INTO DATA(lv_line).
        lv_html = lv_html && lv_line.
      ENDLOOP.
    ENDIF.

    DATA(lt_line) = lines_of( lv_html ).
    DATA(lo_viewer) = viewer( container = container
                              window    = xsdbool( container IS NOT SUPPLIED )
                              title     = title ).
    lo_viewer->load_data( IMPORTING  assigned_url = DATA(lv_url)
                          CHANGING   data_table   = lt_line
                          EXCEPTIONS OTHERS       = 1 ).
    IF sy-subrc = 0.
      lo_viewer->show_url( EXPORTING  url    = lv_url
                           EXCEPTIONS OTHERS = 1 ).
    ENDIF.

  ENDMETHOD.

  METHOD show_url.

    viewer( container = container
            window    = xsdbool( container IS NOT SUPPLIED )
            title     = title )->show_url( EXPORTING  url    = url
                                           EXCEPTIONS OTHERS = 1 ).

  ENDMETHOD.

  METHOD show_xml.

    DATA(lv_xml) = xml_string.
    IF lv_xml IS INITIAL AND xml_xstring IS NOT INITIAL.
      lv_xml = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( xml_xstring ).
    ENDIF.
    DATA(lv_html) = |<pre>{ escape( val    = lv_xml
                                    format = cl_abap_format=>e_html_text ) }</pre>|.
    IF container IS SUPPLIED.
      show_html( html_string = lv_html
                 title       = title
                 container   = container ).
    ELSE.
      show_html( html_string = lv_html
                 title       = title ).
    ENDIF.

  ENDMETHOD.

  METHOD close_browser.

    IF go_box IS BOUND.
      go_box->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR go_box.
    ENDIF.

  ENDMETHOD.

  METHOD on_close.

    sender->free( EXCEPTIONS OTHERS = 1 ).

  ENDMETHOD.

  METHOD lines_of.

    DATA(lv_at) = 0.
    WHILE lv_at < strlen( html ).
      APPEND substring( val = html
                        off = lv_at
                        len = nmin( val1 = 255
                                    val2 = strlen( html ) - lv_at ) ) TO result.
      lv_at = lv_at + 255.
    ENDWHILE.

  ENDMETHOD.

  METHOD viewer.

    DATA(lo_parent) = container.
    IF window = abap_true.
      " the window of its own - a dialog box, title its caption
      close_browser( ).
      go_box = NEW z2ui5_cl_cgui_gui_container( caption = title
                                                width   = 800
                                                height  = 600 ).
      go_box->set_handler( class  = `Z2UI5_CL_CGUI_ABAP_BROWSER`
                           method = `ON_CLOSE`
                           event  = `CLOSE` ).
      lo_parent = go_box.
    ENDIF.
    result = NEW z2ui5_cl_cgui_gui_html_viewer( parent = lo_parent ).

  ENDMETHOD.

ENDCLASS.
