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
    INTERFACES if_serializable_object.
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
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

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
  PRIVATE SECTION.
    DATA client     TYPE REF TO z2ui5_if_client.
    DATA mv_event   TYPE string.
    DATA mv_title   TYPE string.
    DATA mv_rows_in TYPE abap_bool.
    DATA ms_result  TYPE ty_s_result.

    METHODS view_display.
    METHODS leave.

ENDCLASS.


CLASS z2ui5_cl_cgui_transport IMPLEMENTATION.

  METHOD factory.

    result = NEW #( ).
    result->mv_event = event.
    result->mv_title = COND #( WHEN title IS NOT INITIAL THEN title ELSE 'Transport Request'(001) ).
    IF rows IS SUPPLIED.
      result->mt_row = rows.
      result->mv_rows_in = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD result.

    result = ms_result.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      IF mv_rows_in = abap_false.
        mt_row = requests_of_user( ).
      ENDIF.
      view_display( ).
      RETURN.
    ENDIF.

    CASE client->get_event( ).
      WHEN cs_event-select.
        READ TABLE mt_row INTO DATA(ls_row) WITH KEY selkz = abap_true.
        IF sy-subrc <> 0.
          client->message_toast_display( 'Select a transport request'(002) ).
          RETURN.
        ENDIF.
        ms_result = VALUE #( confirmed = abap_true
                             transport = ls_row-transport
                             task      = ls_row-task ).
        leave( ).
      WHEN cs_event-local.
        ms_result = VALUE #( confirmed = abap_true
                             local     = abap_true ).
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

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = mv_title
        )->a( n = `contentWidth` v = `40rem`
        )->a( n = `afterClose`   v = client->_event( cs_event-cancel ) ).

    lo_dialog->ele( `content`
        )->ele( `Table`
            )->a( n = `mode`       v = `SingleSelectLeft`
            )->a( n = `items`      v = client->_bind_edit( mt_row )
            )->a( n = `noDataText` t = CONV #( 'No modifiable transport request of yours'(003) )
            )->ele( `columns`
                )->ele( `Column`
                    )->tag( `Text`
                    )->a( n = `text` t = CONV #( 'Request'(004) )
                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                    )->a( n = `text` t = CONV #( 'Task'(005) )
                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                    )->a( n = `text` t = CONV #( 'Description'(006) )
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

    lo_dialog->ele( `buttons`
        )->tag( `Button`
            )->a( n = `text`  t = CONV #( 'No Transport'(007) )
            )->a( n = `press` v = client->_event( cs_event-local )
        )->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Cancel'(008) )
            )->a( n = `press` v = client->_event( cs_event-cancel )
        )->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Select'(009) )
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
    DATA lt_task    TYPE STANDARD TABLE OF ty_s_e070 WITH EMPTY KEY.
    DATA lt_request TYPE STANDARD TABLE OF ty_s_e070 WITH EMPTY KEY.
    DATA lt_text    TYPE STANDARD TABLE OF ty_s_e07t WITH EMPTY KEY.
    TYPES ty_t_range TYPE RANGE OF ty_s_e070-trkorr.

    " E070 and E07T by name - not released on ABAP Cloud, there the select
    " raises and the list stays empty
    DATA(lv_e070) = `E070`.
    DATA(lv_e07t) = `E07T`.
    DATA(lv_user) = sy-uname.
    TRY.
        " the tasks of the user that are still open, below a request
        SELECT trkorr, strkorr FROM (lv_e070)
          WHERE as4user = @lv_user AND trstatus = 'D' AND strkorr <> @space
          INTO TABLE @lt_task.
        IF lt_task IS INITIAL.
          RETURN.
        ENDIF.
        " their requests, modifiable, and the texts
        DATA(lt_range) = VALUE ty_t_range( FOR ls_t IN lt_task ( sign = `I` option = `EQ` low = ls_t-strkorr ) ).
        SORT lt_range BY low.
        DELETE ADJACENT DUPLICATES FROM lt_range COMPARING low.
        SELECT trkorr, strkorr FROM (lv_e070)
          WHERE trkorr IN @lt_range AND trstatus = 'D'
          INTO TABLE @lt_request.
        SELECT trkorr, as4text FROM (lv_e07t)
          WHERE trkorr IN @lt_range
          INTO TABLE @lt_text.
      CATCH cx_root.
        CLEAR result.
        RETURN.
    ENDTRY.

    SORT lt_request BY trkorr.
    LOOP AT lt_request INTO DATA(ls_request).
      READ TABLE lt_task INTO DATA(ls_task) WITH KEY strkorr = ls_request-trkorr.
      READ TABLE lt_text INTO DATA(ls_text) WITH KEY trkorr = ls_request-trkorr.
      INSERT VALUE #( transport   = condense( CONV string( ls_request-trkorr ) )
                      task        = condense( CONV string( ls_task-trkorr ) )
                      description = condense( CONV string( ls_text-as4text ) ) ) INTO TABLE result.
      CLEAR: ls_task, ls_text.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
