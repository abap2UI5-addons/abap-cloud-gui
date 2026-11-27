"! Popups of the report runtime - POPUP_TO_DECIDE and POPUP_GET_VALUES as an
"! abap2UI5 app of their own. The caller opens it with nav_app_call( ); on
"! an answer the popup leaves to the caller with the event it was given, and
"! the caller reads result( ) of client->get_app_prev( ):
"!   client->nav_app_call( z2ui5_cl_cgui_popup=>decide(
"!       question = `Save the changes?`
"!       options  = VALUE #( ( `Save` ) ( `Discard` ) )
"!       event    = `DECIDED` ) ).
"! decide( ) answers with the number of the button as answer (`1`, `2`, ...)
"! or cs_answer-cancel, the classic POPUP_TO_DECIDE. get_values( ) shows
"! fields - input, date, checkbox or listbox - checks the required ones and
"! returns them with the values the user entered, the classic
"! POPUP_GET_VALUES. confirm( ) asks a question with OK and Cancel and
"! leaves with event on OK and with event_cancel on Cancel, the classic
"! POPUP_TO_CONFIRM.
CLASS z2ui5_cl_cgui_popup DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS:
      BEGIN OF cs_kind,
        input    TYPE string VALUE `INPUT`,
        date     TYPE string VALUE `DATE`,
        checkbox TYPE string VALUE `CHECKBOX`,
        listbox  TYPE string VALUE `LISTBOX`,
        multi    TYPE string VALUE `MULTI`,
      END OF cs_kind.

    CONSTANTS:
      BEGIN OF cs_answer,
        cancel TYPE string VALUE `A`,
        ok     TYPE string VALUE `1`,
      END OF cs_answer.

    TYPES:
      "! a field of get_values( ): value is the text of an input, a date as
      "! yyyyMMdd, the key of a listbox; flag the value of a checkbox; keys the
      "! keys picked in a multi listbox (cs_kind-multi)
      BEGIN OF ty_s_field,
        name      TYPE string,
        text      TYPE string,
        kind      TYPE string,
        value     TYPE string,
        flag      TYPE abap_bool,
        keys      TYPE string_table,
        required  TYPE abap_bool,
        read_only TYPE abap_bool,
      END OF ty_s_field.
    TYPES ty_t_field TYPE STANDARD TABLE OF ty_s_field WITH EMPTY KEY.

    TYPES:
      "! the values of the listbox of field name
      BEGIN OF ty_s_listbox,
        name TYPE string,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_listbox.
    TYPES ty_t_listbox TYPE STANDARD TABLE OF ty_s_listbox WITH EMPTY KEY.

    TYPES:
      "! a line of POPUP_TO_DECIDE_LIST - SPOPLI of the classic; ABAP Cloud
      "! has not the DDIC type
      BEGIN OF ty_s_spopli,
        selflag   TYPE c LENGTH 1,
        varoption TYPE c LENGTH 65,
        inactive  TYPE c LENGTH 1,
        hide      TYPE c LENGTH 1,
      END OF ty_s_spopli.

    TYPES:
      BEGIN OF ty_s_result,
        confirmed TYPE abap_bool,
        answer    TYPE string,
        fields    TYPE ty_t_field,
      END OF ty_s_result.

    "! the fields of get_values( ) - PUBLIC, the inputs are bound to them
    DATA mt_field TYPE ty_t_field.

    CLASS-METHODS decide
      IMPORTING
        question      TYPE clike
        options       TYPE string_table
        title         TYPE clike     OPTIONAL
        event         TYPE clike     OPTIONAL
        cancel        TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_popup.

    CLASS-METHODS get_values
      IMPORTING
        fields        TYPE ty_t_field
        title         TYPE clike        OPTIONAL
        text          TYPE clike        OPTIONAL
        listbox       TYPE ty_t_listbox OPTIONAL
        event         TYPE clike        OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_popup.

    CLASS-METHODS confirm
      IMPORTING
        question      TYPE clike
        title         TYPE clike OPTIONAL
        event         TYPE clike OPTIONAL
        event_cancel  TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_popup.

    METHODS result
      RETURNING
        VALUE(result) TYPE ty_s_result.

    "! the value of field name of the result - the flag of a checkbox as
    "! `X` or empty
    METHODS result_value
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the keys picked in the multi listbox name of the result
    METHODS result_keys
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE string_table.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the popup travels in the draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA client      TYPE REF TO z2ui5_if_client.
    DATA mv_title    TYPE string.
    DATA mv_text     TYPE string.
    DATA mt_option   TYPE string_table.
    DATA mv_cancel   TYPE abap_bool.
    DATA mv_event    TYPE string.
    DATA mt_listbox  TYPE ty_t_listbox.
    DATA mv_error    TYPE string.
    DATA ms_result   TYPE ty_s_result.
    DATA mv_confirm  TYPE abap_bool.
    DATA mv_event_cancel TYPE string.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF cs_event,
        ok     TYPE string VALUE `CGUI_POP_OK`,
        cancel TYPE string VALUE `CGUI_POP_CANCEL`,
        option TYPE string VALUE `CGUI_POP_OPTION_`,
      END OF cs_event.

    METHODS view_display.

    METHODS render_fields
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    METHODS check_required
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS leave.

ENDCLASS.


CLASS z2ui5_cl_cgui_popup IMPLEMENTATION.

  METHOD decide.

    result = NEW #( ).
    result->mv_text   = question.
    result->mt_option = options.
    result->mv_title  = title.
    result->mv_event  = event.
    result->mv_cancel = cancel.
    IF result->mv_title IS INITIAL.
      result->mv_title = 'Decide'(001).
    ENDIF.

  ENDMETHOD.

  METHOD get_values.

    result = NEW #( ).
    result->mt_field  = fields.
    result->mv_text   = text.
    result->mv_title  = title.
    result->mv_event  = event.
    result->mv_cancel = abap_true.
    result->mt_listbox = listbox.
    LOOP AT result->mt_field REFERENCE INTO DATA(lr_field).
      lr_field->name = to_upper( lr_field->name ).
      IF lr_field->kind IS INITIAL.
        lr_field->kind = cs_kind-input.
      ENDIF.
    ENDLOOP.
    LOOP AT result->mt_listbox REFERENCE INTO DATA(lr_listbox).
      lr_listbox->name = to_upper( lr_listbox->name ).
    ENDLOOP.
    IF result->mv_title IS INITIAL.
      result->mv_title = 'Enter Values'(002).
    ENDIF.

  ENDMETHOD.

  METHOD confirm.

    result = NEW #( ).
    result->mv_text         = question.
    result->mv_title        = title.
    result->mv_event        = event.
    result->mv_event_cancel = event_cancel.
    result->mv_cancel       = abap_true.
    result->mv_confirm      = abap_true.
    IF result->mv_title IS INITIAL.
      result->mv_title = 'Confirm'(006).
    ENDIF.

  ENDMETHOD.

  METHOD result.

    result = ms_result.

  ENDMETHOD.

  METHOD result_value.

    DATA(lv_name) = to_upper( name ).
    READ TABLE ms_result-fields REFERENCE INTO DATA(lr_field) WITH KEY name = lv_name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF lr_field->kind = cs_kind-checkbox.
      result = COND #( WHEN lr_field->flag = abap_true THEN `X` ).
    ELSE.
      result = lr_field->value.
    ENDIF.

  ENDMETHOD.

  METHOD result_keys.

    DATA(lv_name) = to_upper( name ).
    READ TABLE ms_result-fields REFERENCE INTO DATA(lr_field) WITH KEY name = lv_name.
    IF sy-subrc = 0.
      result = lr_field->keys.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      view_display( ).
      RETURN.
    ENDIF.

    DATA(lv_event) = client->get_event( ).
    CLEAR mv_error.

    IF lv_event = cs_event-ok.
      IF check_required( ) = abap_false.
        view_display( ).
        RETURN.
      ENDIF.
      ms_result-confirmed = abap_true.
      ms_result-answer    = cs_answer-ok.
      ms_result-fields    = mt_field.
      leave( ).

    ELSEIF lv_event = cs_event-cancel.
      ms_result-confirmed = abap_false.
      ms_result-answer    = cs_answer-cancel.
      ms_result-fields    = mt_field.
      leave( ).

    ELSEIF strlen( lv_event ) > strlen( cs_event-option ) AND lv_event CP |{ cs_event-option }*|.
      ms_result-confirmed = abap_true.
      ms_result-answer    = substring( val = lv_event
                                       off = strlen( cs_event-option ) ).
      leave( ).
    ENDIF.

  ENDMETHOD.

  METHOD leave.

    " decide( ) and get_values( ) leave with their event either way - the
    " caller reads the answer; confirm( ) has an event of its own for Cancel
    DATA(lv_event) = mv_event.
    IF mv_confirm = abap_true AND ms_result-confirmed = abap_false.
      lv_event = mv_event_cancel.
    ENDIF.

    client->popup_destroy( ).
    IF lv_event IS INITIAL.
      client->nav_app_leave( client->get_app_prev( ) ).
    ELSE.
      client->nav_app_leave( app   = client->get_app_prev( )
                             event = lv_event ).
    ENDIF.

  ENDMETHOD.

  METHOD check_required.

    result = abap_true.
    LOOP AT mt_field REFERENCE INTO DATA(lr_field)
         WHERE required = abap_true AND kind <> cs_kind-checkbox AND value IS INITIAL.
      mv_error = replace( val  = 'Fill in the required field &1'(003)
                          sub  = `&1`
                          with = lr_field->text ).
      result = abap_false.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD view_display.

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`      t = mv_title
        )->a( n = `afterClose` v = client->_event( cs_event-cancel ) ).

    DATA(lo_content) = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    IF mv_error IS NOT INITIAL.
      lo_content->tag( `MessageStrip`
          )->a( n = `text`  t = mv_error
          )->a( n = `type`  v = `Error`
          )->a( n = `class` v = `sapUiSmallMarginBottom` ).
    ENDIF.
    IF mv_text IS NOT INITIAL.
      lo_content->tag( `Text`
          )->a( n = `text`  t = mv_text
          )->a( n = `class` v = `sapUiSmallMarginBottom` ).
    ENDIF.
    IF mt_field IS NOT INITIAL.
      render_fields( lo_content ).
    ENDIF.

    DATA(lo_buttons) = lo_dialog->ele( `buttons` ).
    IF mt_option IS NOT INITIAL.
      LOOP AT mt_option INTO DATA(lv_option).
        " sy-tabix is read once: every a( ) below appends and moves it
        DATA(lv_number) = sy-tabix.
        lo_buttons->tag( `Button`
            )->a( n = `text`  t = lv_option
            )->a( n = `type`  v = COND #( WHEN lv_number = 1 THEN `Emphasized` ELSE `Default` )
            )->a( n = `press` v = client->_event( |{ cs_event-option }{ lv_number }| ) ).
      ENDLOOP.
    ELSE.
      lo_buttons->tag( `Button`
          )->a( n = `text`  t = CONV #( 'OK'(004) )
          )->a( n = `type`  v = `Emphasized`
          )->a( n = `press` v = client->_event( cs_event-ok ) ).
    ENDIF.
    IF mv_cancel = abap_true.
      lo_buttons->tag( `Button`
          )->a( n = `text`  t = CONV #( 'Cancel'(005) )
          )->a( n = `press` v = client->_event( cs_event-cancel ) ).
    ENDIF.

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD render_fields.

    DATA(lo_form) = node->ele( n = `SimpleForm` ns = `form`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `editable`   b = abap_true
        )->a( n = `layout`     v = `ResponsiveGridLayout`
        )->a( n = `labelSpanM` v = `4`
        )->a( n = `labelSpanL` v = `4` ).

    LOOP AT mt_field REFERENCE INTO DATA(lr_field).
      DATA(lv_index) = sy-tabix.

      lo_form->tag( `Label`
          )->a( n = `text`     t = lr_field->text
          )->a( n = `required` b = lr_field->required ).

      CASE lr_field->kind.
        WHEN cs_kind-checkbox.
          lo_form->tag( `CheckBox`
              )->a( n = `selected` v = client->_bind( val       = lr_field->flag
                                                     tab       = mt_field
                                                     tab_index = lv_index )
              )->a( n = `editable` b = xsdbool( lr_field->read_only = abap_false ) ).

        WHEN cs_kind-date.
          lo_form->tag( `DatePicker`
              )->a( n = `value`       v = client->_bind( val       = lr_field->value
                                                        tab       = mt_field
                                                        tab_index = lv_index )
              )->a( n = `valueFormat` v = `yyyyMMdd`
              )->a( n = `editable`    b = xsdbool( lr_field->read_only = abap_false ) ).

        WHEN cs_kind-multi.
          DATA(lo_multi) = lo_form->ele( `MultiComboBox`
              )->a( n = `selectedKeys` v = client->_bind( val       = lr_field->keys
                                                         tab       = mt_field
                                                         tab_index = lv_index )
              )->a( n = `editable`     b = xsdbool( lr_field->read_only = abap_false )
              )->ele( `items` ).
          LOOP AT mt_listbox REFERENCE INTO DATA(lr_multi) WHERE name = lr_field->name.
            lo_multi->tag( n = `Item` ns = `core`
                )->a( n = `key`  t = lr_multi->key
                )->a( n = `text` t = lr_multi->text ).
          ENDLOOP.

        WHEN cs_kind-listbox.
          DATA(lo_items) = lo_form->ele( `Select`
              )->a( n = `selectedKey`    v = client->_bind( val       = lr_field->value
                                                           tab       = mt_field
                                                           tab_index = lv_index )
              )->a( n = `forceSelection` b = abap_false
              )->a( n = `editable`       b = xsdbool( lr_field->read_only = abap_false )
              )->ele( `items` ).
          lo_items->tag( n = `Item` ns = `core`
              )->a( n = `key`  v = ``
              )->a( n = `text` v = `` ).
          LOOP AT mt_listbox REFERENCE INTO DATA(lr_value) WHERE name = lr_field->name.
            lo_items->tag( n = `Item` ns = `core`
                )->a( n = `key`  t = lr_value->key
                )->a( n = `text` t = lr_value->text ).
          ENDLOOP.

        WHEN OTHERS.
          lo_form->tag( `Input`
              )->a( n = `value`    v = client->_bind( val       = lr_field->value
                                                     tab       = mt_field
                                                     tab_index = lv_index )
              )->a( n = `editable` b = xsdbool( lr_field->read_only = abap_false ) ).

      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
