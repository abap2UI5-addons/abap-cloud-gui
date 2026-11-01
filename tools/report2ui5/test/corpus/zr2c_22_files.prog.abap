*&---------------------------------------------------------------------*
*& Report ZR2C_22_FILES
*&---------------------------------------------------------------------*
*& The files of the user: F4 on the file name opens the file dialog of
*& SAP GUI in a FORM, GUI_UPLOAD reads the seats per airline from it -
*& tab separated - the list shows them, and with the checkbox the file
*& save dialog names a download of the sums (cl_gui_frontend_services)
*&---------------------------------------------------------------------*
REPORT zr2c_22_files.

TYPES:
  BEGIN OF ty_seats,
    carrid TYPE c LENGTH 3,
    seats  TYPE i,
  END OF ty_seats.
TYPES ty_t_seats TYPE STANDARD TABLE OF ty_seats WITH DEFAULT KEY.

DATA gt_seats TYPE ty_t_seats.
DATA gv_total TYPE i.

PARAMETERS: p_file TYPE string LOWER CASE OBLIGATORY,
            p_save AS CHECKBOX.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM pick_file CHANGING p_file.

START-OF-SELECTION.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename            = p_file
      filetype            = 'ASC'
      has_field_separator = 'X'
    TABLES
      data_tab            = gt_seats
    EXCEPTIONS
      file_open_error     = 1
      OTHERS              = 2.
  IF sy-subrc <> 0.
    MESSAGE |File { p_file } cannot be read| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  WRITE: / 'Seats per airline'.
  ULINE.
  LOOP AT gt_seats INTO DATA(ls_seats).
    WRITE: / ls_seats-carrid, ls_seats-seats.
    gv_total = gv_total + ls_seats-seats.
  ENDLOOP.
  ULINE.
  WRITE: / 'Total', gv_total.

  IF p_save = abap_true.
    PERFORM save_total.
  ENDIF.

FORM pick_file CHANGING cv_file TYPE string.
  DATA: lt_files  TYPE filetable,
        lv_rc     TYPE i,
        lv_action TYPE i.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title = 'Seats per airline'
      file_filter  = 'Text (*.txt)|*.txt|'
    CHANGING
      file_table   = lt_files
      rc           = lv_rc
      user_action  = lv_action
    EXCEPTIONS
      OTHERS       = 1.
  IF sy-subrc = 0 AND lv_action = cl_gui_frontend_services=>action_ok AND lv_rc = 1.
    READ TABLE lt_files INDEX 1 INTO DATA(ls_file).
    cv_file = ls_file-filename.
  ENDIF.
ENDFORM.

FORM save_total.
  DATA: lt_out      TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
        lv_name     TYPE string,
        lv_path     TYPE string,
        lv_fullpath TYPE string,
        lv_action   TYPE i.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_file_name = 'total.txt'
    CHANGING
      filename          = lv_name
      path              = lv_path
      fullpath          = lv_fullpath
      user_action       = lv_action ).
  IF lv_action <> cl_gui_frontend_services=>action_ok.
    RETURN.
  ENDIF.
  APPEND |Total seats: { gv_total }| TO lt_out.
  cl_gui_frontend_services=>gui_download(
    EXPORTING
      filename = lv_fullpath
    CHANGING
      data_tab = lt_out
    EXCEPTIONS
      OTHERS   = 1 ).
  IF sy-subrc = 0.
    MESSAGE |Saved as { lv_name }| TYPE 'S'.
  ENDIF.
ENDFORM.
