CLASS z2ui5_cl_cgui_r2c_22 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_seats,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_seats.
    TYPES ty_t_seats TYPE STANDARD TABLE OF ty_seats WITH DEFAULT KEY.

    " global data of the report
    DATA gt_seats TYPE ty_t_seats.
    DATA gv_total TYPE i.

    " selection screen
    DATA p_file TYPE string.
    DATA p_save TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_value_request REDEFINITION.

  PRIVATE SECTION.
    METHODS pick_file
      CHANGING
        cv_file TYPE string.

    METHODS save_total.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_22 IMPLEMENTATION.

  METHOD initialization.

    set_title( `Upload and download` ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_file
                       text       = `File`
                       obligatory = abap_true
                       value_help = abap_true
                       lower_case = abap_true
        )->checkbox( val  = p_save
                     text = `Download the total` ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_seats,
           gv_total.

    z2ui5_cl_cgui_frontend=>gui_upload( EXPORTING  filename            = p_file
                                                   filetype            = 'ASC'
                                                   has_field_separator = 'X'
                                        CHANGING   data_tab            = gt_seats
                                        EXCEPTIONS file_open_error     = 1
                                                   OTHERS              = 2 ).
    IF sy-subrc <> 0.
      message( text = |File { p_file } cannot be read|
               type = `W` ).
      RETURN.
    ENDIF.

    list( )->new_line(
        )->write( 'Seats per airline' ).
    list( )->uline( ).
    LOOP AT gt_seats INTO DATA(ls_seats).
      list( )->new_line(
          )->write( ls_seats-carrid
          )->write( ls_seats-seats ).
      gv_total = gv_total + ls_seats-seats.
    ENDLOOP.
    list( )->uline( ).
    list( )->new_line(
        )->write( 'Total'
        )->write( gv_total ).

    IF p_save = abap_true.
      save_total( ).
    ENDIF.

  ENDMETHOD.

  METHOD at_value_request.

    CASE field.
      WHEN `P_FILE`.
        pick_file( CHANGING
                     cv_file = p_file ).
      WHEN OTHERS.
        super->at_value_request( field ).
    ENDCASE.

  ENDMETHOD.

  METHOD pick_file.

    DATA:
      lt_files  TYPE z2ui5_cl_cgui_frontend=>ty_t_file_table,
      lv_rc     TYPE i,
      lv_action TYPE i.

    z2ui5_cl_cgui_frontend=>file_open_dialog(
      EXPORTING
        window_title = 'Seats per airline'
        file_filter  = 'Text (*.txt)|*.txt|'
      CHANGING
        file_table   = lt_files
        rc           = lv_rc
        user_action  = lv_action
      EXCEPTIONS
        OTHERS       = 1 ).
    IF sy-subrc = 0 AND lv_action = z2ui5_cl_cgui_frontend=>action_ok AND lv_rc = 1.
      READ TABLE lt_files INDEX 1 INTO DATA(ls_file).
      cv_file = ls_file-filename.
    ENDIF.

  ENDMETHOD.

  METHOD save_total.

    DATA:
      lt_out      TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      lv_name     TYPE string,
      lv_path     TYPE string,
      lv_fullpath TYPE string,
      lv_action   TYPE i.

    z2ui5_cl_cgui_frontend=>file_save_dialog(
      EXPORTING
        default_file_name = 'total.txt'
      CHANGING
        filename          = lv_name
        path              = lv_path
        fullpath          = lv_fullpath
        user_action       = lv_action ).
    IF lv_action <> z2ui5_cl_cgui_frontend=>action_ok.
      RETURN.
    ENDIF.
    APPEND |Total seats: { gv_total }| TO lt_out.
    z2ui5_cl_cgui_frontend=>gui_download(
      EXPORTING
        filename = lv_fullpath
      CHANGING
        data_tab = lt_out
      EXCEPTIONS
        OTHERS   = 1 ).
    IF sy-subrc = 0.
      message( |Saved as { lv_name }| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
