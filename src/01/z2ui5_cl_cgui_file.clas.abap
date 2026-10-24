"! The file upload of the report runtime - the dialog behind
"! z2ui5_cl_cgui_frontend=>file_open_dialog( ), an abap2UI5 app of its own
"! like z2ui5_cl_cgui_popup. The browser reads every picked file (the
"! z2ui5.cc.FileUploader of abap2UI5, as a data URI) and hands it over in a
"! roundtrip of its own; OK leaves to the caller with the files:
"!   client->nav_app_call( z2ui5_cl_cgui_file=>factory( title    = `Upload`
"!                                                      multiple = abap_true ) ).
"!   ...
"!   DATA(lt_file) = CAST z2ui5_cl_cgui_file( client->get_app_prev( ) )->result( )-files.
"! filter is the file filter of SAP GUI - `CSV (*.csv)|*.csv|` - and limits
"! the picker to those extensions.
CLASS z2ui5_cl_cgui_file DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_file,
        name    TYPE string,
        content TYPE xstring,
      END OF ty_s_file.
    TYPES ty_t_file TYPE STANDARD TABLE OF ty_s_file WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_result,
        confirmed TYPE abap_bool,
        files     TYPE ty_t_file,
      END OF ty_s_result.

    "! the picked file as a data URI and its name - PUBLIC, the uploader is
    "! bound to them
    DATA mv_value TYPE string.
    DATA mv_path  TYPE string.

    CLASS-METHODS factory
      IMPORTING
        title         TYPE clike     OPTIONAL
        multiple      TYPE abap_bool DEFAULT abap_false
        filter        TYPE clike     OPTIONAL
        event         TYPE clike     OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_file.

    "! the extensions of a file filter of SAP GUI, as the picker takes
    "! them: `Text (*.txt)|*.txt|CSV|*.csv;*.tsv|` is `txt,csv,tsv`, *.* none
    CLASS-METHODS file_types
      IMPORTING
        filter        TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the bytes of a data URI - data:text/csv;base64,...
    CLASS-METHODS content_of_data_uri
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    METHODS result
      RETURNING
        VALUE(result) TYPE ty_s_result.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the popup travels in the draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA client      TYPE REF TO z2ui5_if_client.
    DATA mv_title    TYPE string.
    DATA mv_multiple TYPE abap_bool.
    DATA mv_types    TYPE string.
    DATA mv_event    TYPE string.
    DATA ms_result   TYPE ty_s_result.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF cs_event,
        upload TYPE string VALUE `CGUI_FILE_UPLOAD`,
        ok     TYPE string VALUE `CGUI_FILE_OK`,
        cancel TYPE string VALUE `CGUI_FILE_CANCEL`,
      END OF cs_event.

    METHODS view_display.

    METHODS on_upload.

    METHODS leave.

ENDCLASS.


CLASS z2ui5_cl_cgui_file IMPLEMENTATION.

  METHOD factory.

    result = NEW #( ).
    result->mv_title    = title.
    result->mv_multiple = multiple.
    result->mv_types    = file_types( filter ).
    result->mv_event    = event.
    IF result->mv_title IS INITIAL.
      result->mv_title = 'Upload File'(001).
    ENDIF.

  ENDMETHOD.

  METHOD file_types.

    DATA lt_part TYPE string_table.
    DATA lt_type TYPE string_table.

    SPLIT filter AT `|` INTO TABLE lt_part.
    " the filter alternates text and patterns - the patterns are every
    " second part, separated by ;
    LOOP AT lt_part INTO DATA(lv_part).
      IF sy-tabix MOD 2 = 1.
        CONTINUE.
      ENDIF.
      SPLIT lv_part AT `;` INTO TABLE DATA(lt_pattern).
      LOOP AT lt_pattern INTO DATA(lv_pattern).
        lv_pattern = to_lower( condense( lv_pattern ) ).
        IF lv_pattern = `*.*` OR lv_pattern = `*`.
          RETURN.
        ENDIF.
        IF strlen( lv_pattern ) > 2 AND substring( val = lv_pattern len = 2 ) = `*.`.
          lv_pattern = substring( val = lv_pattern off = 2 ).
          IF NOT line_exists( lt_type[ table_line = lv_pattern ] ).
            INSERT lv_pattern INTO TABLE lt_type.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    result = concat_lines_of( table = lt_type
                              sep   = `,` ).

  ENDMETHOD.

  METHOD content_of_data_uri.

    DATA(lv_at) = find( val = val sub = `,` ).
    IF lv_at < 0.
      RETURN.
    ENDIF.
    DATA(lv_head) = substring( val = val len = lv_at ).
    DATA(lv_data) = substring( val = val off = lv_at + 1 ).
    IF find( val = lv_head sub = `;base64` ) >= 0.
      result = z2ui5_cl_cgui_context=>conv_decode_x_base64( lv_data ).
    ELSE.
      result = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( lv_data ).
    ENDIF.

  ENDMETHOD.

  METHOD result.

    result = ms_result.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      view_display( ).
      RETURN.
    ENDIF.

    CASE client->get_event( ).
      WHEN cs_event-upload.
        on_upload( ).
        view_display( ).

      WHEN cs_event-ok.
        ms_result-confirmed = xsdbool( ms_result-files IS NOT INITIAL ).
        leave( ).

      WHEN cs_event-cancel.
        CLEAR ms_result.
        leave( ).
    ENDCASE.

  ENDMETHOD.

  METHOD on_upload.

    DATA ls_file TYPE ty_s_file.

    IF mv_value IS INITIAL.
      RETURN.
    ENDIF.
    " the name without the folder - the browser hands C:\fakepath\name over
    ls_file-name = mv_path.
    REPLACE ALL OCCURRENCES OF `\` IN ls_file-name WITH `/`.
    DATA(lv_slash) = find( val = ls_file-name sub = `/` occ = -1 ).
    IF lv_slash >= 0.
      ls_file-name = substring( val = ls_file-name off = lv_slash + 1 ).
    ENDIF.
    IF ls_file-name IS INITIAL.
      ls_file-name = `upload`.
    ENDIF.
    ls_file-content = content_of_data_uri( mv_value ).
    CLEAR: mv_value, mv_path.

    IF mv_multiple = abap_false.
      CLEAR ms_result-files.
    ENDIF.
    DELETE ms_result-files WHERE name = ls_file-name.
    INSERT ls_file INTO TABLE ms_result-files.

  ENDMETHOD.

  METHOD leave.

    client->popup_destroy( ).
    IF mv_event IS INITIAL.
      client->nav_app_leave( client->get_app_prev( ) ).
    ELSE.
      client->nav_app_leave( app   = client->get_app_prev( )
                             event = mv_event ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`       v = `sap.m`
        )->a( n = `xmlns:core`  v = `sap.ui.core`
        )->a( n = `xmlns:z2ui5` v = `z2ui5.cc`
        )->ele( `Dialog`
        )->a( n = `title`      t = mv_title
        )->a( n = `afterClose` v = client->_event( cs_event-cancel ) ).

    DATA(lo_content) = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    lo_content->tag( n = `FileUploader` ns = `z2ui5`
        )->a( n = `value`             v = client->_bind( mv_value )
        )->a( n = `path`              v = client->_bind( mv_path )
        )->a( n = `fileType`          t = mv_types
        )->a( n = `multiple`          b = mv_multiple
        )->a( n = `checkDirectUpload` b = abap_true
        )->a( n = `placeholder`       t = CONV #( 'Choose a file'(002) )
        )->a( n = `upload`            v = client->_event( cs_event-upload ) ).

    LOOP AT ms_result-files INTO DATA(ls_file).
      lo_content->tag( `ObjectStatus`
          )->a( n = `text`  t = |{ ls_file-name } ({ xstrlen( ls_file-content ) } B)|
          )->a( n = `icon`  v = `sap-icon://document`
          )->a( n = `class` v = `sapUiTinyMarginTop` ).
    ENDLOOP.

    lo_dialog->ele( `buttons`
        )->tag( `Button`
            )->a( n = `text`    t = CONV #( 'OK'(003) )
            )->a( n = `type`    v = `Emphasized`
            )->a( n = `enabled` b = xsdbool( ms_result-files IS NOT INITIAL )
            )->a( n = `press`   v = client->_event( cs_event-ok )
        )->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Cancel'(004) )
            )->a( n = `press` v = client->_event( cs_event-cancel ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
