"! The transport request popup - the modifiable requests of the user with a
"! task of the user, to pick one or to go on without a transport, as an
"! abap2UI5 app of its own. The caller opens it with nav_app_call( ); the
"! popup leaves with the event it was given, the caller reads result( ) of
"! client->get_app_prev( ):
"!   client->nav_app_call( z2ui5_cl_cgui_transport=>factory( `TRANSPORT` ) ).
"!   ...
"!   DATA(ls_tr) = CAST z2ui5_cl_cgui_transport( client->get_app_prev( ) )->result( ).
"! E070 and E07T are read by name: on ABAP Cloud they are not released, the
"! list stays empty and only "No Transport" is offered
CLASS z2ui5_cl_cgui_transport DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS:
      BEGIN OF cs_event,
        select TYPE string VALUE `CGUI_TR_SELECT`,
        local  TYPE string VALUE `CGUI_TR_LOCAL`,
        cancel TYPE string VALUE `CGUI_TR_CANCEL`,
      END OF cs_event.

    TYPES:
      BEGIN OF ty_s_row,
        transport   TYPE string,
        task        TYPE string,
        description TYPE string,
        " picked in the table - bound to the selection of the row
        selkz       TYPE abap_bool,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_result,
        " a request picked, or local - no transport wanted
        confirmed TYPE abap_bool,
        local     TYPE abap_bool,
        transport TYPE string,
        task      TYPE string,
      END OF ty_s_result.

    "! the rows the table shows - PUBLIC, the selection is bound to them
    DATA mt_row TYPE ty_t_row.

    "! event: what the popup leaves with to the caller; rows: the requests
    "! to offer instead of those of E070 (a test, an own source)
    CLASS-METHODS factory
      IMPORTING
        event         TYPE clike OPTIONAL
        title         TYPE clike OPTIONAL
        rows          TYPE ty_t_row OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_transport.

    METHODS result
      RETURNING
        VALUE(result) TYPE ty_s_result.

    "! the modifiable requests of the user with a task of the user - E070
    "! and E07T, empty where they are not there
    CLASS-METHODS requests_of_user
      RETURNING
        VALUE(result) TYPE ty_t_row.

  PROTECTED SECTION.
    " the state of the app - PROTECTED, the draft keeps it (a PRIVATE
    " attribute the transpiled runtime does not reach)
    DATA client     TYPE REF TO z2ui5_if_client.
    DATA mv_event   TYPE string.
    DATA mv_title   TYPE string.
    DATA mv_rows_in TYPE abap_bool.
    DATA ms_result  TYPE ty_s_result.

    METHODS view_display.
    METHODS leave.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_transport IMPLEMENTATION.

  METHOD factory.
    DATA temp6 TYPE string.

    CREATE OBJECT result.
    result->mv_event = event.

    IF title IS NOT INITIAL.
      temp6 = title.
    ELSE.
      temp6 = 'Transport Request'(001).
    ENDIF.
    result->mv_title = temp6.
    IF rows IS SUPPLIED.
      result->mt_row = rows.
      result->mv_rows_in = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD result.

    result = ms_result.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.
        DATA ls_row TYPE z2ui5_cl_cgui_transport=>ty_s_row.

    me->client = client.

    IF client->check_on_init( ) IS NOT INITIAL.
      IF mv_rows_in = abap_false.
        mt_row = requests_of_user( ).
      ENDIF.
      view_display( ).
      RETURN.
    ENDIF.

    CASE client->get_event( ).
      WHEN cs_event-select.

        READ TABLE mt_row INTO ls_row WITH KEY selkz = abap_true.
        IF sy-subrc <> 0.
          client->message_toast_display( 'Select a transport request'(002) ).
          RETURN.
        ENDIF.
        CLEAR ms_result.
        ms_result-confirmed = abap_true.
        ms_result-transport = ls_row-transport.
        ms_result-task = ls_row-task.
        leave( ).
      WHEN cs_event-local.
        CLEAR ms_result.
        ms_result-confirmed = abap_true.
        ms_result-local = abap_true.
        leave( ).
      WHEN cs_event-cancel.
        CLEAR ms_result.
        leave( ).
    ENDCASE.

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

    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp7 TYPE string.
    DATA temp1 TYPE string.
    DATA temp3 TYPE string.
    DATA temp5 TYPE string.
    DATA temp8 TYPE string.
    DATA temp2 TYPE string.
    DATA temp4 TYPE string.
    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = mv_title
        )->a( n = `contentWidth` v = `40rem`
        )->a( n = `afterClose`   v = client->_event( cs_event-cancel ) ).


    temp7 = 'No modifiable transport request of yours'(003).

    temp1 = 'Request'(004).

    temp3 = 'Task'(005).

    temp5 = 'Description'(006).
    lo_dialog->ele( `content`
        )->ele( `Table`
            )->a( n = `mode`       v = `SingleSelectLeft`
            )->a( n = `items`      v = client->_bind( mt_row )
            )->a( n = `noDataText` t = temp7
            )->ele( `columns`
                )->ele( `Column`
                    )->tag( `Text`
                    )->a( n = `text` t = temp1
                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                    )->a( n = `text` t = temp3
                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                    )->a( n = `text` t = temp5
                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `selected` v = `{SELKZ}`
                    )->ele( `cells`
                        )->tag( `Text`
                        )->a( n = `text` v = `{TRANSPORT}`
                        )->tag( `Text`
                        )->a( n = `text` v = `{TASK}`
                        )->tag( `Text`
                        )->a( n = `text` v = `{DESCRIPTION}` ).


    temp8 = 'No Transport'(007).

    temp2 = 'Cancel'(008).

    temp4 = 'Select'(009).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
            )->a( n = `text`  t = temp8
            )->a( n = `press` v = client->_event( cs_event-local )
        )->tag( `Button`
            )->a( n = `text`  t = temp2
            )->a( n = `press` v = client->_event( cs_event-cancel )
        )->tag( `Button`
            )->a( n = `text`  t = temp4
            )->a( n = `type`  v = `Emphasized`
            )->a( n = `press` v = client->_event( cs_event-select ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD requests_of_user.

    TYPES:
      BEGIN OF ty_s_e070,
        trkorr  TYPE c LENGTH 20,
        strkorr TYPE c LENGTH 20,
      END OF ty_s_e070.
    TYPES:
      BEGIN OF ty_s_e07t,
        trkorr  TYPE c LENGTH 20,
        as4text TYPE c LENGTH 60,
      END OF ty_s_e07t.
    DATA lt_task    TYPE STANDARD TABLE OF ty_s_e070 WITH DEFAULT KEY.
    DATA lt_request TYPE STANDARD TABLE OF ty_s_e070 WITH DEFAULT KEY.
    DATA lt_text    TYPE STANDARD TABLE OF ty_s_e07t WITH DEFAULT KEY.
    TYPES ty_t_range TYPE RANGE OF ty_s_e070-trkorr.

    " E070 and E07T by name - not released on ABAP Cloud, there the select
    " raises and the list stays empty
    DATA lv_e070 TYPE string.
    DATA lv_e07t TYPE string.
    DATA lv_user LIKE sy-uname.
        DATA temp9 TYPE ty_t_range.
        DATA ls_t LIKE LINE OF lt_task.
          DATA temp10 LIKE LINE OF temp9.
        DATA lt_range LIKE temp9.
    DATA ls_request LIKE LINE OF lt_request.
      DATA ls_task TYPE ty_s_e070.
      DATA ls_text TYPE ty_s_e07t.
      DATA temp11 TYPE z2ui5_cl_cgui_transport=>ty_s_row.
      DATA temp3 TYPE string.
      DATA temp4 TYPE string.
      DATA temp5 TYPE string.
    lv_e070 = `E070`.

    lv_e07t = `E07T`.

    lv_user = sy-uname.
    TRY.
        " the tasks of the user that are still open, below a request
        SELECT trkorr strkorr FROM (lv_e070) INTO TABLE lt_task
          WHERE as4user = lv_user AND trstatus = 'D' AND strkorr <> space
          .
        IF lt_task IS INITIAL.
          RETURN.
        ENDIF.
        " their requests, modifiable, and the texts

        CLEAR temp9.

        LOOP AT lt_task INTO ls_t.

          temp10-sign = `I`.
          temp10-option = `EQ`.
          temp10-low = ls_t-strkorr.
          INSERT temp10 INTO TABLE temp9.
        ENDLOOP.

        lt_range = temp9.
        SORT lt_range BY low.
        DELETE ADJACENT DUPLICATES FROM lt_range COMPARING low.
        SELECT trkorr strkorr FROM (lv_e070) INTO TABLE lt_request
          WHERE trkorr IN lt_range AND trstatus = 'D'
          .
        SELECT trkorr as4text FROM (lv_e07t) INTO TABLE lt_text
          WHERE trkorr IN lt_range
          .
      CATCH cx_root.
        CLEAR result.
        RETURN.
    ENDTRY.

    SORT lt_request BY trkorr.

    LOOP AT lt_request INTO ls_request.

      READ TABLE lt_task INTO ls_task WITH KEY strkorr = ls_request-trkorr.

      READ TABLE lt_text INTO ls_text WITH KEY trkorr = ls_request-trkorr.

      CLEAR temp11.

      temp3 = ls_request-trkorr.
      temp11-transport = condense( temp3 ).

      temp4 = ls_task-trkorr.
      temp11-task = condense( temp4 ).

      temp5 = ls_text-as4text.
      temp11-description = condense( temp5 ).
      INSERT temp11 INTO TABLE result.
      CLEAR: ls_task, ls_text.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
