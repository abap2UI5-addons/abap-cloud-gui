*&---------------------------------------------------------------------*
*& Report ZR2C_41_PICTURE
*&---------------------------------------------------------------------*
*& A stamp on the screen: the bytes of a small GIF, made a URL with
*& DP_CREATE_URL and shown by cl_gui_picture in a docking container -
*& fitted to its width, a click on it counts the stamps
*&---------------------------------------------------------------------*
REPORT zr2c_41_picture.

CLASS lcl_stamp DEFINITION.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS on_click FOR EVENT picture_click OF cl_gui_picture.
    DATA mo_dock TYPE REF TO cl_gui_docking_container.
    DATA mo_picture TYPE REF TO cl_gui_picture.
    DATA mv_count TYPE i.
ENDCLASS.

PARAMETERS p_fit AS CHECKBOX DEFAULT 'X'.

DATA go_stamp TYPE REF TO lcl_stamp.

CLASS lcl_stamp IMPLEMENTATION.
  METHOD constructor.
    TYPES ty_line TYPE x LENGTH 64.
    DATA lt_bin TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    DATA lv_url TYPE c LENGTH 255.
    DATA lt_event TYPE cntl_simple_events.

    " a white GIF of one pixel - 43 bytes
    APPEND '47494638396101000100800000FFFFFF00000021F90401000000002C00000000010001000002024401003B' TO lt_bin.
    CALL FUNCTION 'DP_CREATE_URL'
      EXPORTING
        type    = 'image'
        subtype = 'gif'
        size    = 43
      TABLES
        data    = lt_bin
      CHANGING
        url     = lv_url
      EXCEPTIONS
        OTHERS  = 1.
    IF sy-subrc <> 0.
      MESSAGE 'No URL for the stamp' TYPE 'E'.
    ENDIF.

    mo_dock = NEW cl_gui_docking_container( side = cl_gui_docking_container=>dock_at_top ).
    mo_picture = NEW cl_gui_picture( parent = mo_dock ).
    IF p_fit = abap_true.
      mo_picture->set_display_mode( cl_gui_picture=>display_mode_fit ).
    ENDIF.
    mo_picture->load_picture_from_url_async( lv_url ).
    APPEND VALUE #( eventid = cl_gui_picture=>eventid_picture_click appl_event = abap_true ) TO lt_event.
    mo_picture->set_registered_events( lt_event ).
    SET HANDLER on_click FOR mo_picture.
  ENDMETHOD.

  METHOD on_click.
    mv_count = mv_count + 1.
    MESSAGE |{ mv_count } stamp(s)| TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  go_stamp = NEW lcl_stamp( ).
  WRITE: / 'Click the stamp'.
