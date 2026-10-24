"! The stand-in of cl_gui_picture - a picture in its container, as
"! sap.m.Image. load_picture_from_url( ) takes an address of the web, a
"! data URI or the URL DP_CREATE_URL answered for the bytes of a picture
"! (z2ui5_cl_cgui_frontend=>dp_create_url( )); load_picture_from_sap_icons( )
"! an icon (sap-icon://...). The display mode stretch or fit fills the width
"! of the container; a click on the picture raises picture_click
CLASS z2ui5_cl_cgui_gui_picture DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS display_mode_normal        TYPE i VALUE 0.
    CONSTANTS display_mode_stretch       TYPE i VALUE 1.
    CONSTANTS display_mode_fit           TYPE i VALUE 2.
    CONSTANTS display_mode_normal_center TYPE i VALUE 3.
    CONSTANTS display_mode_fit_center    TYPE i VALUE 4.
    CONSTANTS eventid_picture_click      TYPE i VALUE 1.

    "! a click on the picture - the browser has no position of it
    EVENTS picture_click
      EXPORTING
        VALUE(mouse_pos_x) TYPE i OPTIONAL
        VALUE(mouse_pos_y) TYPE i OPTIONAL.

    METHODS constructor
      IMPORTING
        parent     TYPE REF TO z2ui5_cl_cgui_gui_container
        lifetime   TYPE i     OPTIONAL
        shellstyle TYPE i     OPTIONAL
        name       TYPE clike OPTIONAL
      EXCEPTIONS
        error.

    METHODS load_picture_from_url
      IMPORTING
        url    TYPE clike
      EXPORTING
        result TYPE i
      EXCEPTIONS
        error.

    METHODS load_picture_from_url_async
      IMPORTING
        url TYPE clike
      EXCEPTIONS
        error.

    METHODS load_picture_from_sap_icons
      IMPORTING
        icon TYPE clike
      EXCEPTIONS
        error.

    METHODS set_display_mode
      IMPORTING
        display_mode TYPE i
      EXCEPTIONS
        error.

    METHODS clear_picture
      EXCEPTIONS
        error.

    METHODS set_registered_events
      IMPORTING
        events TYPE STANDARD TABLE
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    METHODS dispatch REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_picture IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).
    IF add( VALUE #( kind   = z2ui5_if_cgui_gui=>cs_kind-picture
                     parent = id_of( parent ) ) ) = abap_false.
      RAISE error.
    ENDIF.

  ENDMETHOD.

  METHOD load_picture_from_url.

    DATA(ls_control) = get( ).
    ls_control-url = z2ui5_cl_cgui_frontend=>url_content( condense( CONV string( url ) ) ).
    put( ls_control ).
    result = 1.

  ENDMETHOD.

  METHOD load_picture_from_url_async.

    load_picture_from_url( url ).

  ENDMETHOD.

  METHOD load_picture_from_sap_icons.

    DATA(ls_control) = get( ).
    ls_control-url = condense( CONV string( icon ) ).
    put( ls_control ).

  ENDMETHOD.

  METHOD set_display_mode.

    DATA(ls_control) = get( ).
    ls_control-mode = display_mode.
    put( ls_control ).

  ENDMETHOD.

  METHOD clear_picture.

    DATA(ls_control) = get( ).
    CLEAR ls_control-url.
    put( ls_control ).

  ENDMETHOD.

  METHOD set_registered_events ##NEEDED.
  ENDMETHOD.

  METHOD dispatch.

    IF to_upper( event ) <> `PICTURE_CLICK`.
      super->dispatch( event = event
                       value = value ).
      RETURN.
    ENDIF.
    raise_event( `PICTURE_CLICK` ).

  ENDMETHOD.

ENDCLASS.
