"! CL_GUI_FRONTEND_SERVICES for a report in the browser - the methods a
"! report uses for its files, with their names, parameters and classic
"! exceptions, so that report2cloud writes z2ui5_cl_cgui_frontend=>gui_upload(
"! ... ) for cl_gui_frontend_services=>gui_upload( ... ) and the rest of the
"! statement - EXCEPTIONS and sy-subrc included - stays as it is.
"!
"! There is no file system of the user, there are files the user picks:
"! - file_open_dialog( ) opens the upload dialog of the runtime and answers
"!   action_cancel; when the user has picked the files, the runtime runs
"!   the F4 again (AT SELECTION-SCREEN ON VALUE-REQUEST) - or Execute, when
"!   the dialog was opened while the selection screen was processed - and
"!   this time file_open_dialog( ) answers action_ok with their names
"! - gui_upload( ) reads a picked file by its name (the folder of filename
"!   does not matter), ASC as lines of text - split at the tab with
"!   has_field_separator - and BIN as bytes; a name no file was picked
"!   for (a path of the PC) opens the upload dialog, and Execute runs
"!   again with the file the user picks for it
"! - gui_download( ) hands the file to the browser, named as filename
"!   without its folder
"! - file_save_dialog( ) and directory_browse( ) answer at once: the browser
"!   asks where a download goes. The folders are `.`, the separator `/`
"! - DP_CREATE_URL, SCMS_BINARY_TO_XSTRING, SCMS_XSTRING_TO_BINARY,
"!   SCMS_STRING_TO_XSTRING and SSFC_BASE64_ENCODE / _DECODE are methods of
"!   their names here: bytes, lines of bytes, text and base64 in plain ABAP
"! Outside of a report of the runtime (no report has run yet) every method
"! of the files raises its first exception.
CLASS z2ui5_cl_cgui_frontend DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES:
      "! FILE_TABLE and FILETABLE, the file_table of file_open_dialog( ) -
      "! without the DDIC types, which ABAP Cloud does not have
      BEGIN OF ty_s_file_table ##NEEDED,
        filename TYPE c LENGTH 1024,
      END OF ty_s_file_table.
    TYPES ty_t_file_table TYPE STANDARD TABLE OF ty_s_file_table WITH DEFAULT KEY ##NEEDED.

    CONSTANTS action_ok TYPE i VALUE 0.
    CONSTANTS action_cancel TYPE i VALUE 9.

    CONSTANTS filetype_all TYPE string VALUE `All Files (*.*)|*.*|`.
    CONSTANTS filetype_text TYPE string VALUE `Text Files (*.TXT)|*.TXT|`.
    CONSTANTS filetype_excel TYPE string VALUE `Excel Files (*.XLS)|*.XLS|`.
    CONSTANTS filetype_xml TYPE string VALUE `XML Files (*.XML)|*.XML|`.
    CONSTANTS filetype_html TYPE string VALUE `HTML Files (*.HTML)|*.HTML|`.

    CLASS-METHODS file_open_dialog
      IMPORTING
        window_title      TYPE csequence OPTIONAL
        default_extension TYPE csequence OPTIONAL
        default_filename  TYPE csequence OPTIONAL
        file_filter       TYPE csequence OPTIONAL
        with_encoding     TYPE abap_bool OPTIONAL
        initial_directory TYPE csequence OPTIONAL
        multiselection    TYPE abap_bool OPTIONAL
      CHANGING
        file_table    TYPE STANDARD TABLE
        rc            TYPE i
        user_action   TYPE i     OPTIONAL
        file_encoding TYPE clike OPTIONAL
      EXCEPTIONS
        file_open_dialog_failed
        cntl_error
        error_no_gui
        not_supported_by_gui.

    CLASS-METHODS file_save_dialog
      IMPORTING
        window_title        TYPE csequence OPTIONAL
        default_extension   TYPE csequence OPTIONAL
        default_file_name   TYPE csequence OPTIONAL
        with_encoding       TYPE abap_bool OPTIONAL
        file_filter         TYPE csequence OPTIONAL
        initial_directory   TYPE csequence OPTIONAL
        prompt_on_overwrite TYPE abap_bool DEFAULT abap_true
      CHANGING
        filename      TYPE string
        path          TYPE string
        fullpath      TYPE string
        user_action   TYPE i     OPTIONAL
        file_encoding TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        error_no_gui
        not_supported_by_gui
        invalid_default_file_name.

    CLASS-METHODS directory_browse
      IMPORTING
        window_title   TYPE csequence OPTIONAL
        initial_folder TYPE csequence OPTIONAL
      CHANGING
        selected_folder TYPE string
      EXCEPTIONS
        cntl_error
        error_no_gui
        not_supported_by_gui.

    CLASS-METHODS gui_upload
      IMPORTING
        filename            TYPE csequence
        filetype            TYPE clike     DEFAULT 'ASC'
        has_field_separator TYPE abap_bool DEFAULT abap_false
        header_length       TYPE i         DEFAULT 0
        read_by_line        TYPE abap_bool DEFAULT abap_true
        dat_mode            TYPE abap_bool DEFAULT abap_false
        codepage            TYPE clike     OPTIONAL
        ignore_cerr         TYPE abap_bool DEFAULT abap_true
        replacement         TYPE clike     DEFAULT '#'
        virus_scan_profile  TYPE clike     OPTIONAL
      EXPORTING
        filelength TYPE i
        header     TYPE xstring
      CHANGING
        data_tab        TYPE STANDARD TABLE
        isscanperformed TYPE abap_bool OPTIONAL
      EXCEPTIONS
        file_open_error
        file_read_error
        no_batch
        gui_refuse_filetransfer
        invalid_type
        no_authority
        unknown_error
        bad_data_format
        header_not_allowed
        separator_not_allowed
        header_too_long
        unknown_dp_error
        access_denied
        dp_out_of_memory
        disk_full
        dp_timeout
        not_supported_by_gui
        error_no_gui.

    CLASS-METHODS gui_download
      IMPORTING
        bin_filesize              TYPE i              OPTIONAL
        filename                  TYPE csequence
        filetype                  TYPE clike          DEFAULT 'ASC'
        append                    TYPE abap_bool      DEFAULT abap_false
        write_field_separator     TYPE abap_bool      DEFAULT abap_false
        header                    TYPE xstring        OPTIONAL
        trunc_trailing_blanks     TYPE abap_bool      DEFAULT abap_false
        write_lf                  TYPE abap_bool      DEFAULT abap_true
        col_select                TYPE abap_bool      DEFAULT abap_false
        col_select_mask           TYPE clike          OPTIONAL
        dat_mode                  TYPE abap_bool      DEFAULT abap_false
        confirm_overwrite         TYPE abap_bool      DEFAULT abap_false
        no_auth_check             TYPE abap_bool      DEFAULT abap_false
        codepage                  TYPE clike          OPTIONAL
        ignore_cerr               TYPE abap_bool      DEFAULT abap_true
        replacement               TYPE clike          DEFAULT '#'
        write_bom                 TYPE abap_bool      DEFAULT abap_false
        trunc_trailing_blanks_eol TYPE abap_bool      DEFAULT abap_true
        show_transfer_status      TYPE abap_bool      DEFAULT abap_true
        fieldnames                TYPE STANDARD TABLE OPTIONAL
        write_lf_after_last_line  TYPE abap_bool      DEFAULT abap_true
        virus_scan_profile        TYPE clike          OPTIONAL
      EXPORTING
        filelength TYPE i
      CHANGING
        data_tab TYPE STANDARD TABLE
      EXCEPTIONS
        file_write_error
        no_batch
        gui_refuse_filetransfer
        invalid_type
        no_authority
        unknown_error
        header_not_allowed
        separator_not_allowed
        filesize_not_allowed
        header_too_long
        dp_error_create
        dp_error_send
        dp_error_write
        unknown_dp_error
        access_denied
        dp_out_of_memory
        disk_full
        dp_timeout
        file_not_found
        dataprovider_exception
        control_flush_error
        not_supported_by_gui
        error_no_gui.

    "! `/` - the names of the browser's files have no folders of the user
    CLASS-METHODS get_file_separator
      CHANGING
        file_separator TYPE clike
      EXCEPTIONS
        not_supported_by_gui
        error_no_gui
        cntl_error.

    "! the folders of the user's PC - `.`, a download goes where the
    "! browser puts it
    CLASS-METHODS get_desktop_directory
      CHANGING
        desktop_directory TYPE string
      EXCEPTIONS
        cntl_error
        error_no_gui
        not_supported_by_gui.

    CLASS-METHODS get_temp_directory
      CHANGING
        temp_dir TYPE string
      EXCEPTIONS
        cntl_error
        error_no_gui
        not_supported_by_gui.

    CLASS-METHODS get_sapgui_workdir
      CHANGING
        sapworkdir TYPE string
      EXCEPTIONS
        get_sapworkdir_failed
        cntl_error
        error_no_gui
        not_supported_by_gui.

    CLASS-METHODS get_system_directory
      CHANGING
        system_directory TYPE string
      EXCEPTIONS
        cntl_error
        error_no_gui
        not_supported_by_gui.

    "! the files the user uploaded - the only folder there is; filter is a
    "! pattern of the name (*.csv), folders there are none
    CLASS-METHODS directory_list_files
      IMPORTING
        directory        TYPE csequence
        filter           TYPE csequence DEFAULT '*.*'
        files_only       TYPE abap_bool OPTIONAL
        directories_only TYPE abap_bool OPTIONAL
      CHANGING
        file_table       TYPE STANDARD TABLE
        count            TYPE i
      EXCEPTIONS
        cntl_error
        directory_list_files_failed
        wrong_parameter
        error_no_gui
        not_supported_by_gui.

    CLASS-METHODS directory_get_current
      CHANGING
        current_directory TYPE string
      EXCEPTIONS
        directory_get_current_failed
        cntl_error
        error_no_gui
        not_supported_by_gui.

    "! whether the user picked a file of that name
    CLASS-METHODS file_exist
      IMPORTING
        file TYPE csequence
      RETURNING
        VALUE(result) TYPE abap_bool
      EXCEPTIONS
        cntl_error
        error_no_gui
        wrong_parameter
        not_supported_by_gui.

    "! a folder always exists - downloads need none
    CLASS-METHODS directory_exist
      IMPORTING
        directory TYPE csequence
      RETURNING
        VALUE(result) TYPE abap_bool
      EXCEPTIONS
        cntl_error
        error_no_gui
        wrong_parameter
        not_supported_by_gui.

    CLASS-METHODS directory_create
      IMPORTING
        directory TYPE csequence
      CHANGING
        rc TYPE i
      EXCEPTIONS
        directory_create_failed
        cntl_error
        error_no_gui
        directory_access_denied
        directory_already_exists
        path_not_found
        unknown_error
        not_supported_by_gui
        wrong_parameter.

    "! a document that is a URL (http, https, mailto) opens in a new tab of
    "! the browser; a program of the PC cannot be started
    CLASS-METHODS execute
      IMPORTING
        document          TYPE csequence OPTIONAL
        application       TYPE csequence OPTIONAL
        parameter         TYPE csequence OPTIONAL
        default_directory TYPE csequence OPTIONAL
        maximized         TYPE csequence OPTIONAL
        minimized         TYPE csequence OPTIONAL
        synchronous       TYPE csequence OPTIONAL
        operation         TYPE csequence DEFAULT 'OPEN'
      EXCEPTIONS
        cntl_error
        error_no_gui
        bad_parameter
        file_not_found
        path_not_found
        file_extension_unknown
        error_execute_failed
        synchronous_failed
        not_supported_by_gui.

    "! the lines of data as text into the clipboard of the browser
    CLASS-METHODS clipboard_export
      IMPORTING
        no_auth_check TYPE abap_bool DEFAULT abap_false
      EXPORTING
        data TYPE STANDARD TABLE
      CHANGING
        rc TYPE i
      EXCEPTIONS
        cntl_error
        error_no_gui
        not_supported_by_gui
        no_authority.

    "! the lines of a file as text - ASC: split at the line ends; with
    "! separator a structured line is split at the tab into its components
    CLASS-METHODS text_to_table
      IMPORTING
        text      TYPE csequence
        separator TYPE abap_bool DEFAULT abap_false
      CHANGING
        data_tab  TYPE STANDARD TABLE.

    "! the lines of data_tab as a text with CRLF - the counterpart
    CLASS-METHODS table_to_text
      IMPORTING
        data_tab      TYPE STANDARD TABLE
        separator     TYPE abap_bool DEFAULT abap_false
        last_line_end TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE string.

    "! DP_CREATE_URL - a URL of the lines of data, for cl_gui_picture and
    "! cl_gui_html_viewer: a short name (z2ui5-cgui-url:n), which fits the
    "! CHAR field a report keeps it in, for the data URI url_content( )
    "! answers. type is the MIME type (image/png) or its first half (image)
    "! with subtype; lines of bytes are the bytes, size cuts them, lines of
    "! text a text
    CLASS-METHODS dp_create_url
      IMPORTING
        type                TYPE clike
        subtype             TYPE clike OPTIONAL
        size                TYPE i     OPTIONAL
        date                TYPE d     OPTIONAL
        time                TYPE t     OPTIONAL
        description         TYPE clike OPTIONAL
        lifetime            TYPE clike OPTIONAL
        cacheable           TYPE clike OPTIONAL
        send_data_as_string TYPE clike OPTIONAL
        data                TYPE STANDARD TABLE
      CHANGING
        url                 TYPE clike
      EXCEPTIONS
        dp_invalid_parameter
        dp_error_put_table
        dp_error_general.

    "! SCMS_BINARY_TO_XSTRING - the bytes of the lines of binary_tab, cut
    "! at input_length
    CLASS-METHODS scms_binary_to_xstring
      IMPORTING
        input_length TYPE i     OPTIONAL
        first_line   TYPE i     OPTIONAL
        last_line    TYPE i     OPTIONAL
        binary_tab   TYPE STANDARD TABLE
      EXPORTING
        buffer       TYPE xstring
      EXCEPTIONS
        failed.

    "! SCMS_XSTRING_TO_BINARY - buffer as lines of bytes of the line type of
    "! binary_tab; output_length is the number of bytes
    CLASS-METHODS scms_xstring_to_binary
      IMPORTING
        buffer          TYPE xstring
        append_to_table TYPE abap_bool DEFAULT abap_false
      EXPORTING
        output_length   TYPE i
      CHANGING
        binary_tab      TYPE STANDARD TABLE.

    "! SCMS_STRING_TO_XSTRING - text in UTF-8, whatever encoding names
    CLASS-METHODS scms_string_to_xstring
      IMPORTING
        text     TYPE string
        mimetype TYPE clike OPTIONAL
        encoding TYPE clike OPTIONAL
      EXPORTING
        buffer   TYPE xstring
      EXCEPTIONS
        failed.

    "! SSFC_BASE64_ENCODE - bindata, cut at binleng, in base64
    CLASS-METHODS ssfc_base64_encode
      IMPORTING
        bindata TYPE xsequence
        binleng TYPE i OPTIONAL
      EXPORTING
        b64data TYPE clike
      EXCEPTIONS
        ssf_krn_error
        ssf_krn_noop
        ssf_krn_nomemory
        ssf_krn_opinv
        ssf_krn_input_data_error
        ssf_krn_invalid_par
        ssf_krn_invalid_parlen.

    "! SSFC_BASE64_DECODE - the bytes of base64 b64data
    CLASS-METHODS ssfc_base64_decode
      IMPORTING
        b64data    TYPE clike
        b64leng    TYPE i         OPTIONAL
        b64_strict TYPE abap_bool OPTIONAL
      EXPORTING
        bindata    TYPE xstring
      EXCEPTIONS
        ssf_krn_error
        ssf_krn_noop
        ssf_krn_nomemory
        ssf_krn_opinv
        ssf_krn_input_data_error
        ssf_krn_invalid_par
        ssf_krn_invalid_parlen.

    "! the data URI of a URL of dp_create_url( ) - any other URL as it is
    CLASS-METHODS url_content
      IMPORTING
        url           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the report the methods work for - z2ui5_cl_cgui_report sets itself at
    "! the start of every roundtrip
    CLASS-METHODS set_files
      IMPORTING
        files TYPE REF TO z2ui5_if_cgui_files.

    "! the name of a file without its folder - C:\data\a.csv is a.csv
    CLASS-METHODS file_name
      IMPORTING
        path TYPE clike
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    " the report of the roundtrip - set by z2ui5_cl_cgui_report at its start
    CLASS-DATA go_report TYPE REF TO z2ui5_if_cgui_files.

    " the data URIs of dp_create_url( ) - for the roundtrip they are made in
    TYPES:
      BEGIN OF ty_s_url,
        url     TYPE string,
        content TYPE string,
      END OF ty_s_url.
    CLASS-DATA gt_url TYPE STANDARD TABLE OF ty_s_url WITH EMPTY KEY.

    " the run stops: z2ui5_cx_cgui_stop - raised here, a method with classic
    " EXCEPTIONS cannot RAISE EXCEPTION, it only lets a CX_NO_CHECK pass
    CLASS-METHODS stop_run.

    " the bytes of the lines of a table - a line, or its first component, as
    " bytes; size cuts them
    CLASS-METHODS bytes_of
      IMPORTING
        data          TYPE STANDARD TABLE
        size          TYPE i OPTIONAL
      RETURNING
        VALUE(result) TYPE xstring.

    CLASS-METHODS mime_type
      IMPORTING
        name TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_frontend IMPLEMENTATION.

  METHOD file_open_dialog.

    IF go_report IS NOT BOUND.
      RAISE file_open_dialog_failed.
    ENDIF.

    " the second run of the F4: the files the user picked
    DATA(lt_pick) = go_report->picked( ).
    IF lt_pick IS NOT INITIAL.
      CLEAR file_table.
      LOOP AT lt_pick INTO DATA(lv_name).
        APPEND INITIAL LINE TO file_table ASSIGNING FIELD-SYMBOL(<line>).
        ASSIGN COMPONENT 1 OF STRUCTURE <line> TO FIELD-SYMBOL(<name>).
        IF sy-subrc = 0.
          <name> = lv_name.
        ELSE.
          <line> = lv_name.
        ENDIF.
      ENDLOOP.
      rc = lines( lt_pick ).
      user_action = action_ok.
      RETURN.
    ENDIF.

    go_report->upload_popup( title    = CONV #( window_title )
                             multiple = multiselection
                             filter   = CONV #( file_filter ) ).
    rc = 0.
    user_action = action_cancel.

  ENDMETHOD.

  METHOD file_save_dialog.

    IF go_report IS NOT BOUND.
      RAISE cntl_error.
    ENDIF.

    filename = file_name( default_file_name ).
    IF filename IS INITIAL.
      filename = `download`.
    ENDIF.
    IF default_extension IS NOT INITIAL AND find( val = filename sub = `.` ) < 0.
      filename = |{ filename }.{ to_lower( default_extension ) }|.
    ENDIF.
    path = `./`.
    fullpath = filename.
    user_action = action_ok.

  ENDMETHOD.

  METHOD directory_browse.

    IF go_report IS NOT BOUND.
      RAISE cntl_error.
    ENDIF.

    selected_folder = `.`.

  ENDMETHOD.

  METHOD gui_upload.

    CONSTANTS lc_bom TYPE x LENGTH 3 VALUE 'EFBBBF'.
    DATA lv_line TYPE xstring.

    CLEAR: filelength, header, data_tab.
    IF go_report IS NOT BOUND.
      RAISE file_open_error.
    ENDIF.

    go_report->content( EXPORTING name    = CONV #( filename )
                             IMPORTING content = DATA(lv_content)
                                       found   = DATA(lv_found) ).
    IF lv_found = abap_false.
      " a name the browser has no file of - a path of the PC typed in or
      " fixed in the code: the file the user picks for it in the run again
      DATA(lt_pick) = go_report->picked( ).
      IF lines( lt_pick ) = 1.
        go_report->content( EXPORTING name    = lt_pick[ 1 ]
                            IMPORTING content = lv_content
                                      found   = lv_found ).
      ELSEIF go_report->upload_popup( title = file_name( filename ) ) = abap_true.
        " the run stops here - it starts again with the file
        stop_run( ).
      ENDIF.
    ENDIF.
    IF lv_found = abap_false.
      RAISE file_open_error.
    ENDIF.
    filelength = xstrlen( lv_content ).

    IF to_upper( filetype ) = `BIN`.
      " the bytes, in lines of the length of a line of data_tab
      DATA(lv_len) = 0.
      APPEND INITIAL LINE TO data_tab ASSIGNING FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT 1 OF STRUCTURE <line> TO FIELD-SYMBOL(<bytes>).
      IF sy-subrc <> 0.
        ASSIGN <line> TO <bytes>.
      ENDIF.
      " a line of type xstring takes the whole file
      DATA(lo_bytes) = cl_abap_typedescr=>describe_by_data( <bytes> ).
      IF lo_bytes->type_kind = cl_abap_typedescr=>typekind_xstring.
        <bytes> = lv_content.
        RETURN.
      ENDIF.
      lv_len = lo_bytes->length.
      CLEAR data_tab.
      IF lv_len <= 0.
        RAISE invalid_type.
      ENDIF.
      DATA(lv_off) = 0.
      WHILE lv_off < filelength.
        DATA(lv_part) = nmin( val1 = lv_len val2 = filelength - lv_off ).
        lv_line = lv_content+lv_off(lv_part).
        APPEND INITIAL LINE TO data_tab ASSIGNING <line>.
        ASSIGN COMPONENT 1 OF STRUCTURE <line> TO <bytes>.
        IF sy-subrc <> 0.
          ASSIGN <line> TO <bytes>.
        ENDIF.
        <bytes> = lv_line.
        lv_off = lv_off + lv_part.
      ENDWHILE.
      RETURN.
    ENDIF.

    " the byte order mark of a UTF-8 file is no character of its first line
    IF xstrlen( lv_content ) >= 3 AND lv_content(3) = lc_bom.
      lv_content = lv_content+3.
    ENDIF.
    DATA(lv_text) = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( lv_content ).
    text_to_table( EXPORTING text      = lv_text
                             separator = xsdbool( has_field_separator = abap_true OR to_upper( filetype ) = `DAT` )
                   CHANGING  data_tab  = data_tab ).

  ENDMETHOD.

  METHOD gui_download.

    CONSTANTS lc_bom TYPE x LENGTH 3 VALUE 'EFBBBF'.
    DATA lv_content TYPE xstring.

    CLEAR filelength.
    IF go_report IS NOT BOUND.
      RAISE file_write_error.
    ENDIF.

    IF to_upper( filetype ) = `BIN`.
      LOOP AT data_tab ASSIGNING FIELD-SYMBOL(<line>).
        ASSIGN COMPONENT 1 OF STRUCTURE <line> TO FIELD-SYMBOL(<bytes>).
        IF sy-subrc <> 0.
          ASSIGN <line> TO <bytes>.
        ENDIF.
        DATA(lv_bytes) = CONV xstring( <bytes> ).
        CONCATENATE lv_content lv_bytes INTO lv_content IN BYTE MODE.
      ENDLOOP.
      IF bin_filesize > 0 AND bin_filesize < xstrlen( lv_content ).
        lv_content = lv_content(bin_filesize).
      ENDIF.
    ELSE.
      DATA(lv_text) = table_to_text( data_tab      = data_tab
                                     separator     = xsdbool( write_field_separator = abap_true OR to_upper( filetype ) = `DAT` )
                                     last_line_end = write_lf_after_last_line ).
      lv_content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( lv_text ).
      IF write_bom = abap_true.
        CONCATENATE lc_bom lv_content INTO lv_content IN BYTE MODE.
      ENDIF.
    ENDIF.

    filelength = xstrlen( lv_content ).
    DATA(lv_name) = file_name( filename ).
    IF lv_name IS INITIAL.
      lv_name = `download.txt`.
    ENDIF.
    go_report->download( name    = lv_name
                              mime    = mime_type( lv_name )
                              content = lv_content ).

  ENDMETHOD.

  METHOD get_file_separator.

    file_separator = `/`.

  ENDMETHOD.

  METHOD get_desktop_directory.

    desktop_directory = `.`.

  ENDMETHOD.

  METHOD get_temp_directory.

    temp_dir = `.`.

  ENDMETHOD.

  METHOD get_sapgui_workdir.

    sapworkdir = `.`.

  ENDMETHOD.

  METHOD get_system_directory.

    system_directory = `.`.

  ENDMETHOD.

  METHOD directory_list_files.

    CLEAR: file_table, count.
    IF go_report IS NOT BOUND.
      RAISE cntl_error.
    ENDIF.
    IF directories_only = abap_true.
      RETURN.
    ENDIF.
    DATA(lv_pattern) = to_upper( condense( filter ) ).
    IF lv_pattern IS INITIAL OR lv_pattern = `*.*`.
      lv_pattern = `*`.
    ENDIF.
    LOOP AT go_report->names( ) INTO DATA(lv_name).
      IF to_upper( lv_name ) NP lv_pattern.
        CONTINUE.
      ENDIF.
      APPEND INITIAL LINE TO file_table ASSIGNING FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT 1 OF STRUCTURE <line> TO FIELD-SYMBOL(<name>).
      IF sy-subrc = 0.
        <name> = lv_name.
      ELSE.
        <line> = lv_name.
      ENDIF.
      count = count + 1.
    ENDLOOP.

  ENDMETHOD.

  METHOD directory_get_current.

    current_directory = `.`.

  ENDMETHOD.

  METHOD file_exist.

    IF go_report IS NOT BOUND.
      RAISE cntl_error.
    ENDIF.
    go_report->content( EXPORTING name  = CONV #( file )
                             IMPORTING found = result ).

  ENDMETHOD.

  METHOD directory_exist.

    result = abap_true.

  ENDMETHOD.

  METHOD directory_create.

    rc = 0.

  ENDMETHOD.

  METHOD execute.

    IF go_report IS NOT BOUND.
      RAISE cntl_error.
    ENDIF.
    DATA(lv_target) = COND string( WHEN document IS NOT INITIAL THEN document ELSE parameter ).
    DATA(lv_lower) = to_lower( lv_target ).
    IF strlen( lv_lower ) > 4 AND ( substring( val = lv_lower len = 5 ) = `http:`
        OR ( strlen( lv_lower ) > 5 AND substring( val = lv_lower len = 6 ) = `https:` )
        OR substring( val = lv_lower len = 5 ) = `mailt` ).
      go_report->open_url( lv_target ).
      RETURN.
    ENDIF.
    RAISE not_supported_by_gui.

  ENDMETHOD.

  METHOD clipboard_export.

    IF go_report IS NOT BOUND.
      RAISE cntl_error.
    ENDIF.
    go_report->clipboard( table_to_text( data_tab      = data
                                              last_line_end = abap_false ) ).
    rc = 0.

  ENDMETHOD.

  METHOD text_to_table.

    DATA lt_line TYPE string_table.
    DATA lt_cell TYPE string_table.

    DATA(lv_text) = replace( val  = text
                             sub  = |\r\n|
                             with = |\n|
                             occ  = 0 ).
    SPLIT lv_text AT |\n| INTO TABLE lt_line.
    " the line end of the last line opens no line of its own
    IF lt_line IS NOT INITIAL AND lt_line[ lines( lt_line ) ] IS INITIAL.
      DELETE lt_line INDEX lines( lt_line ).
    ENDIF.

    LOOP AT lt_line INTO DATA(lv_line).
      APPEND INITIAL LINE TO data_tab ASSIGNING FIELD-SYMBOL(<row>).
      DATA(lo_type) = cl_abap_typedescr=>describe_by_data( <row> ).
      IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
        <row> = lv_line.
        CONTINUE.
      ENDIF.
      IF separator = abap_true.
        SPLIT lv_line AT |\t| INTO TABLE lt_cell.
        LOOP AT lt_cell INTO DATA(lv_cell).
          ASSIGN COMPONENT sy-tabix OF STRUCTURE <row> TO FIELD-SYMBOL(<cell>).
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.
          TRY.
              <cell> = lv_cell.
            CATCH cx_root ##NO_HANDLER.
              " a value of another type stays initial, as bad_data_format would
          ENDTRY.
        ENDLOOP.
      ELSE.
        " a flat character line: the text into its columns, as a move does
        TRY.
            <row> = lv_line.
          CATCH cx_root.
            ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <cell>.
            IF sy-subrc = 0.
              <cell> = lv_line.
            ENDIF.
        ENDTRY.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD table_to_text.

    DATA lt_line TYPE string_table.
    DATA lt_cell TYPE string_table.

    LOOP AT data_tab ASSIGNING FIELD-SYMBOL(<row>).
      DATA(lo_type) = cl_abap_typedescr=>describe_by_data( <row> ).
      IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
        INSERT z2ui5_cl_cgui_context=>conv_to_text( <row> ) INTO TABLE lt_line.
        CONTINUE.
      ENDIF.
      CLEAR lt_cell.
      DO.
        ASSIGN COMPONENT sy-index OF STRUCTURE <row> TO FIELD-SYMBOL(<cell>).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        INSERT z2ui5_cl_cgui_context=>conv_to_text( <cell> ) INTO TABLE lt_cell.
      ENDDO.
      INSERT concat_lines_of( table = lt_cell
                              sep   = COND #( WHEN separator = abap_true THEN |\t| ELSE `` ) ) INTO TABLE lt_line.
    ENDLOOP.
    result = concat_lines_of( table = lt_line
                              sep   = |\r\n| ).
    IF last_line_end = abap_true AND lt_line IS NOT INITIAL.
      result = result && |\r\n|.
    ENDIF.

  ENDMETHOD.

  METHOD dp_create_url.

    DATA lv_content TYPE xstring.

    DATA(lv_type) = to_lower( condense( CONV string( type ) ) ).
    IF lv_type IS INITIAL.
      RAISE dp_invalid_parameter.
    ENDIF.
    IF find( val = lv_type sub = `/` ) < 0.
      lv_type = |{ lv_type }/{ to_lower( condense( CONV string( subtype ) ) ) }|.
    ENDIF.
    IF lv_type CP `text/*`.
      lv_content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( table_to_text( data_tab = data ) ).
      IF size > 0 AND size < xstrlen( lv_content ).
        lv_content = lv_content(size).
      ENDIF.
    ELSE.
      lv_content = bytes_of( data = data
                             size = size ).
    ENDIF.
    DATA(lv_url) = |z2ui5-cgui-url:{ lines( gt_url ) + 1 }|.
    INSERT VALUE #( url     = lv_url
                    content = |data:{ lv_type };base64,{ z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_content ) }| )
           INTO TABLE gt_url.
    url = lv_url.

  ENDMETHOD.

  METHOD bytes_of.

    LOOP AT data ASSIGNING FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT 1 OF STRUCTURE <line> TO FIELD-SYMBOL(<bytes>).
      IF sy-subrc <> 0.
        ASSIGN <line> TO <bytes>.
      ENDIF.
      DATA(lv_bytes) = CONV xstring( <bytes> ).
      CONCATENATE result lv_bytes INTO result IN BYTE MODE.
    ENDLOOP.
    IF size > 0 AND size < xstrlen( result ).
      result = result(size).
    ENDIF.

  ENDMETHOD.

  METHOD scms_binary_to_xstring.

    buffer = bytes_of( data = binary_tab
                       size = input_length ).

  ENDMETHOD.

  METHOD scms_xstring_to_binary.

    DATA lr_line TYPE REF TO data.
    DATA lv_width TYPE i.

    IF append_to_table = abap_false.
      CLEAR binary_tab.
    ENDIF.
    output_length = xstrlen( buffer ).
    CREATE DATA lr_line LIKE LINE OF binary_tab.
    ASSIGN lr_line->* TO FIELD-SYMBOL(<line>).
    ASSIGN COMPONENT 1 OF STRUCTURE <line> TO FIELD-SYMBOL(<bytes>).
    IF sy-subrc <> 0.
      ASSIGN <line> TO <bytes>.
    ENDIF.
    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( <bytes> ).
    lv_width = lo_type->length.
    " a line of type xstring takes it all
    IF lo_type->type_kind = cl_abap_typedescr=>typekind_xstring.
      lv_width = nmax( val1 = output_length
                       val2 = 1 ).
    ENDIF.
    DATA(lv_offset) = 0.
    WHILE lv_offset < output_length.
      CLEAR <line>.
      DATA(lv_length) = nmin( val1 = lv_width
                              val2 = output_length - lv_offset ).
      <bytes> = buffer+lv_offset(lv_length).
      APPEND <line> TO binary_tab.
      lv_offset = lv_offset + lv_width.
    ENDWHILE.

  ENDMETHOD.

  METHOD scms_string_to_xstring.

    buffer = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( text ).

  ENDMETHOD.

  METHOD ssfc_base64_encode.

    DATA(lv_bytes) = CONV xstring( bindata ).
    IF binleng > 0 AND binleng < xstrlen( lv_bytes ).
      lv_bytes = lv_bytes(binleng).
    ENDIF.
    b64data = z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_bytes ).

  ENDMETHOD.

  METHOD ssfc_base64_decode.

    DATA(lv_text) = condense( CONV string( b64data ) ).
    IF b64leng > 0 AND b64leng < strlen( lv_text ).
      lv_text = lv_text(b64leng).
    ENDIF.
    bindata = z2ui5_cl_cgui_context=>conv_decode_x_base64( lv_text ).

  ENDMETHOD.

  METHOD url_content.

    result = condense( CONV string( url ) ).
    READ TABLE gt_url INTO DATA(ls_url) WITH KEY url = result.
    IF sy-subrc = 0.
      result = ls_url-content.
    ENDIF.

  ENDMETHOD.

  METHOD set_files.

    go_report = files.

  ENDMETHOD.

  METHOD stop_run.

    RAISE EXCEPTION TYPE z2ui5_cx_cgui_stop.

  ENDMETHOD.

  METHOD file_name.

    result = path.
    REPLACE ALL OCCURRENCES OF `\` IN result WITH `/`.
    DATA(lv_slash) = find( val = result sub = `/` occ = -1 ).
    IF lv_slash >= 0.
      result = substring( val = result off = lv_slash + 1 ).
    ENDIF.

  ENDMETHOD.

  METHOD mime_type.

    DATA(lv_dot) = find( val = name sub = `.` occ = -1 ).
    DATA(lv_ext) = COND string( WHEN lv_dot >= 0 THEN to_lower( substring( val = name off = lv_dot + 1 ) ) ).
    result = SWITCH #( lv_ext
                       WHEN `csv` THEN `text/csv`
                       WHEN `txt` OR `log` OR `abap` THEN `text/plain`
                       WHEN `xml` THEN `application/xml`
                       WHEN `json` THEN `application/json`
                       WHEN `html` OR `htm` THEN `text/html`
                       WHEN `xlsx` THEN `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
                       WHEN `xls` THEN `application/vnd.ms-excel`
                       WHEN `pdf` THEN `application/pdf`
                       WHEN `zip` THEN `application/zip`
                       ELSE `application/octet-stream` ).

  ENDMETHOD.

ENDCLASS.
