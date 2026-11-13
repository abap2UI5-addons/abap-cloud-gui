"! Value selection - a hit list to pick one value or several from, the
"! popup behind F4 and behind the variant catalog, as an abap2UI5 app of
"! its own. The columns come from the line type of the table (RTTI), their
"! headers from the DDIC labels, dates and times are shown in the user's
"! format; the search filters on the server across all columns and keeps
"! the rows already picked. A column ZZSELKZ of the table preselects its
"! rows and is not shown:
"!   client->nav_app_call( z2ui5_cl_cgui_select=>factory( tab         = lt_carrier
"!                                                        title       = `Airline`
"!                                                        multiselect = abap_true ) ).
"!   ...
"!   DATA(ls_result) = CAST z2ui5_cl_cgui_select( client->get_app_prev( ) )->result( ).
"!   IF ls_result-confirmed = abap_true.
"!     lr_picked = ls_result-table.
"! result-row is the first row picked, result-table all of them - both
"! typed like the table passed, in its order.
CLASS z2ui5_cl_cgui_select DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS:
      BEGIN OF cs_event,
        confirm TYPE string VALUE `CGUI_SEL_CONFIRM`,
        cancel  TYPE string VALUE `CGUI_SEL_CANCEL`,
        search  TYPE string VALUE `CGUI_SEL_SEARCH`,
      END OF cs_event.

    "! the column that marks a row as picked - in the table passed it
    "! preselects
    CONSTANTS cv_selkz TYPE string VALUE `ZZSELKZ`.
    "! the column of the rows shown that holds the index of the row passed
    CONSTANTS cv_row   TYPE string VALUE `ZZROW`.

    TYPES:
      BEGIN OF ty_s_result,
        confirmed TYPE abap_bool,
        row       TYPE REF TO data,
        table     TYPE REF TO data,
      END OF ty_s_result.

    TYPES:
      BEGIN OF ty_s_column,
        name  TYPE string,
        label TYPE string,
      END OF ty_s_column.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH EMPTY KEY.

    "! the rows shown - a text column per column of the table, ZZSELKZ and
    "! ZZROW. PUBLIC, the dialog is bound to it
    DATA mr_view TYPE REF TO data.

    " public for the draft of abap2UI5: it keeps a data reference between two
    " roundtrips only when it is a public attribute (its S-RTTI payload) -
    " a protected one stops the save. Not to be changed from outside.
    DATA mr_source TYPE REF TO data.
    DATA mr_all    TYPE REF TO data.
    " the rows picked - result( ) hands them over
    DATA mr_result_row   TYPE REF TO data.
    DATA mr_result_table TYPE REF TO data.

    "! event - left with it on a pick, event_cancel on cancel (both
    "! optional: the caller is back with no event)
    CLASS-METHODS factory
      IMPORTING
        tab           TYPE STANDARD TABLE
        title         TYPE clike     OPTIONAL
        multiselect   TYPE abap_bool DEFAULT abap_false
        event         TYPE clike     OPTIONAL
        event_cancel  TYPE clike     OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_select.

    METHODS result
      RETURNING
        VALUE(result) TYPE ty_s_result.

    "! the columns shown, in their order
    METHODS get_columns
      RETURNING
        VALUE(result) TYPE ty_t_column.

    "! mark row index of the table passed as picked - what a click does
    METHODS select_row
      IMPORTING
        index TYPE i.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the popup travels in the draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA client          TYPE REF TO z2ui5_if_client.
    DATA mv_confirmed    TYPE abap_bool.
    DATA mv_title        TYPE string.
    DATA mv_multi        TYPE abap_bool.
    DATA mv_event        TYPE string.
    DATA mv_event_cancel TYPE string.
    DATA mv_table_line   TYPE abap_bool.
    DATA mt_column       TYPE ty_t_column.

  PRIVATE SECTION.

    METHODS rows_build.

    "! the marks of the rows shown into all rows - before a search
    "! replaces the rows shown and before the pick is read
    METHODS marks_keep.

    METHODS on_search
      IMPORTING
        val TYPE string.

    METHODS on_confirm
      IMPORTING
        path TYPE string.

    METHODS leave
      IMPORTING
        event TYPE string.

    METHODS view_display.

ENDCLASS.


CLASS z2ui5_cl_cgui_select IMPLEMENTATION.

  METHOD factory.

    FIELD-SYMBOLS <source> TYPE STANDARD TABLE.

    result = NEW #( ).
    result->mv_multi        = multiselect.
    result->mv_event        = event.
    result->mv_event_cancel = event_cancel.
    result->mv_title        = title.
    IF result->mv_title IS INITIAL.
      result->mv_title = COND #( WHEN multiselect = abap_true
                                 THEN 'Select Values'(001)
                                 ELSE 'Select a Value'(002) ).
    ENDIF.

    CREATE DATA result->mr_source LIKE tab.
    ASSIGN result->mr_source->* TO <source>.
    <source> = tab.
    CREATE DATA result->mr_result_row LIKE LINE OF tab.
    CREATE DATA result->mr_result_table LIKE tab.
    " empty - the transpiled runtime copies the rows along with LIKE
    ASSIGN result->mr_result_table->* TO <source>.
    CLEAR <source>.

    " the columns: the elementary components, or the line itself
    DATA(lo_line) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( tab ) )->get_table_line_type( ).
    IF lo_line->kind = cl_abap_typedescr=>kind_struct.
      LOOP AT z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ) INTO DATA(ls_comp) WHERE name <> cv_selkz.
        INSERT VALUE #( name  = ls_comp-name
                        label = ls_comp-label ) INTO TABLE result->mt_column.
      ENDLOOP.
    ELSE.
      result->mv_table_line = abap_true.
      DATA(lv_label) = z2ui5_cl_cgui_context=>rtti_get_label_by_descr( lo_line ).
      INSERT VALUE #( name  = `TAB_LINE`
                      label = COND #( WHEN lv_label IS NOT INITIAL THEN lv_label ELSE 'Value'(003) ) )
             INTO TABLE result->mt_column.
    ENDIF.

    result->rows_build( ).

  ENDMETHOD.

  METHOD rows_build.

    DATA lt_comp  TYPE cl_abap_structdescr=>component_table.
    DATA lv_flag  TYPE abap_bool.
    DATA lr_row   TYPE REF TO data.
    DATA lv_index TYPE i.
    FIELD-SYMBOLS <source> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <all>    TYPE STANDARD TABLE.
    FIELD-SYMBOLS <view>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <src>    TYPE any.
    FIELD-SYMBOLS <row>    TYPE any.
    FIELD-SYMBOLS <value>  TYPE any.
    FIELD-SYMBOLS <text>   TYPE any.
    FIELD-SYMBOLS <mark>   TYPE any.

    " every column as text - the user's format and a search on all of them
    LOOP AT mt_column INTO DATA(ls_column).
      INSERT VALUE #( name = ls_column-name
                      type = cl_abap_elemdescr=>get_string( ) ) INTO TABLE lt_comp.
    ENDLOOP.
    INSERT VALUE #( name = cv_selkz
                    type = CAST #( cl_abap_typedescr=>describe_by_data( lv_flag ) ) ) INTO TABLE lt_comp.
    INSERT VALUE #( name = cv_row
                    type = cl_abap_elemdescr=>get_i( ) ) INTO TABLE lt_comp.
    DATA(lo_table) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).

    CREATE DATA mr_all TYPE HANDLE lo_table.
    CREATE DATA mr_view TYPE HANDLE lo_table.
    ASSIGN mr_all->* TO <all>.
    ASSIGN mr_source->* TO <source>.

    LOOP AT <source> ASSIGNING <src>.
      lv_index = sy-tabix.
      CREATE DATA lr_row LIKE LINE OF <all>.
      ASSIGN lr_row->* TO <row>.

      LOOP AT mt_column INTO ls_column.
        ASSIGN COMPONENT ls_column-name OF STRUCTURE <row> TO <text>.
        IF mv_table_line = abap_true.
          ASSIGN <src> TO <value>.
        ELSE.
          UNASSIGN <value>.
          ASSIGN COMPONENT ls_column-name OF STRUCTURE <src> TO <value>.
        ENDIF.
        IF <value> IS ASSIGNED.
          <text> = z2ui5_cl_cgui_context=>conv_to_text( <value> ).
        ENDIF.
        UNASSIGN <value>.
      ENDLOOP.

      IF mv_table_line = abap_false.
        ASSIGN COMPONENT cv_selkz OF STRUCTURE <src> TO <value>.
        IF sy-subrc = 0.
          ASSIGN COMPONENT cv_selkz OF STRUCTURE <row> TO <mark>.
          <mark> = <value>.
        ENDIF.
        UNASSIGN <value>.
      ENDIF.
      ASSIGN COMPONENT cv_row OF STRUCTURE <row> TO <mark>.
      <mark> = lv_index.

      INSERT <row> INTO TABLE <all>.
    ENDLOOP.

    ASSIGN mr_view->* TO <view>.
    <view> = <all>.

  ENDMETHOD.

  METHOD result.

    result = VALUE #( confirmed = mv_confirmed
                      row       = mr_result_row
                      table     = mr_result_table ).

  ENDMETHOD.

  METHOD get_columns.

    result = mt_column.

  ENDMETHOD.

  METHOD select_row.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.

    ASSIGN mr_view->* TO <tab>.
    LOOP AT <tab> ASSIGNING <row>.
      ASSIGN COMPONENT cv_row OF STRUCTURE <row> TO <comp>.
      IF <comp> = index.
        ASSIGN COMPONENT cv_selkz OF STRUCTURE <row> TO <comp>.
        <comp> = abap_true.
      ELSEIF mv_multi = abap_false.
        ASSIGN COMPONENT cv_selkz OF STRUCTURE <row> TO <comp>.
        <comp> = abap_false.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      view_display( ).
      RETURN.
    ENDIF.

    CASE client->get_event( ).
      WHEN cs_event-search.
        on_search( client->get_event_arg( ) ).
      WHEN cs_event-confirm.
        on_confirm( client->get_event_arg( ) ).
      WHEN cs_event-cancel.
        leave( mv_event_cancel ).
    ENDCASE.

  ENDMETHOD.

  METHOD marks_keep.

    FIELD-SYMBOLS <view>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <all>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <index> TYPE any.
    FIELD-SYMBOLS <mark>  TYPE any.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <keep>  TYPE any.

    ASSIGN mr_view->* TO <view>.
    ASSIGN mr_all->* TO <all>.

    LOOP AT <view> ASSIGNING <row>.
      ASSIGN COMPONENT cv_row OF STRUCTURE <row> TO <index>.
      ASSIGN COMPONENT cv_selkz OF STRUCTURE <row> TO <mark>.
      READ TABLE <all> ASSIGNING <line> INDEX <index>.
      IF sy-subrc = 0.
        ASSIGN COMPONENT cv_selkz OF STRUCTURE <line> TO <keep>.
        <keep> = <mark>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD on_search.

    FIELD-SYMBOLS <view> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <all>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <text> TYPE any.

    marks_keep( ).
    ASSIGN mr_view->* TO <view>.
    ASSIGN mr_all->* TO <all>.

    DATA(lv_search) = condense( val ).
    IF lv_search IS INITIAL.
      <view> = <all>.
      RETURN.
    ENDIF.

    " CS ignores the case
    CLEAR <view>.
    LOOP AT <all> ASSIGNING <row>.
      LOOP AT mt_column INTO DATA(ls_column).
        ASSIGN COMPONENT ls_column-name OF STRUCTURE <row> TO <text>.
        IF <text> CS lv_search.
          INSERT <row> INTO TABLE <view>.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD on_confirm.

    FIELD-SYMBOLS <view>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <all>    TYPE STANDARD TABLE.
    FIELD-SYMBOLS <source> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <picked> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <first>  TYPE any.
    FIELD-SYMBOLS <row>    TYPE any.
    FIELD-SYMBOLS <comp>   TYPE any.
    FIELD-SYMBOLS <src>    TYPE any.
    DATA lv_pick  TYPE i.
    DATA lv_index TYPE i.

    marks_keep( ).
    ASSIGN mr_view->* TO <view>.
    ASSIGN mr_all->* TO <all>.
    ASSIGN mr_source->* TO <source>.
    ASSIGN mr_result_table->* TO <picked>.
    ASSIGN mr_result_row->* TO <first>.
    CLEAR: <picked>, <first>.

    " a single pick comes as the path of the row clicked: /NAME/index
    IF mv_multi = abap_false AND path IS NOT INITIAL.
      DATA(lv_last) = segment( val   = path
                               sep   = `/`
                               index = -1 ).
      IF lv_last CO `0123456789`.
        " the position in the window's order - the row of the view behind it
        lv_index = client->window_get_row( val = <view>
                                          row = lv_last + 1 ).
        READ TABLE <view> ASSIGNING <row> INDEX lv_index.
        IF sy-subrc = 0.
          ASSIGN COMPONENT cv_row OF STRUCTURE <row> TO <comp>.
          lv_pick = <comp>.
        ENDIF.
      ENDIF.
    ENDIF.

    LOOP AT <all> ASSIGNING <row>.
      ASSIGN COMPONENT cv_row OF STRUCTURE <row> TO <comp>.
      lv_index = <comp>.
      IF lv_pick > 0.
        IF lv_index <> lv_pick.
          CONTINUE.
        ENDIF.
      ELSE.
        ASSIGN COMPONENT cv_selkz OF STRUCTURE <row> TO <comp>.
        IF <comp> = abap_false.
          CONTINUE.
        ENDIF.
      ENDIF.

      READ TABLE <source> ASSIGNING <src> INDEX lv_index.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF <picked> IS INITIAL.
        <first> = <src>.
      ENDIF.
      INSERT <src> INTO TABLE <picked>.
      IF mv_multi = abap_false.
        EXIT.
      ENDIF.
    ENDLOOP.

    mv_confirmed = abap_true.
    leave( mv_event ).

  ENDMETHOD.

  METHOD leave.

    client->popup_destroy( ).
    IF event IS INITIAL.
      client->nav_app_leave( client->get_app_prev( ) ).
    ELSE.
      client->nav_app_leave( app   = client->get_app_prev( )
                             event = event ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    FIELD-SYMBOLS <view> TYPE STANDARD TABLE.

    ASSIGN mr_view->* TO <view>.

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `TableSelectDialog`
        )->a( n = `title`            t = mv_title
        " a hit list can be long: the browser gets 100 rows at a time and the
        " next ones as the dialog grows (window_bind_tab( )); the search filters the
        " view table on the server and the response sends its first window
        )->a( n = `items`            v = client->window_bind_tab( val    = <view>
                                                            window = 100 )
        )->a( n = `multiSelect`      b = mv_multi
        )->a( n = `growing`          b = abap_true
        )->a( n = `contentWidth`     v = COND #( WHEN lines( mt_column ) > 3 THEN `60rem` ELSE `40rem` )
        )->a( n = `search`           v = client->_event( val   = cs_event-search
                                                         arg   = `${$parameters>/value}` )
        )->a( n = `confirm`          v = client->_event( val   = cs_event-confirm
                                                         arg   = `${$parameters>/selectedContexts[0]/sPath}` )
        )->a( n = `cancel`           v = client->_event( cs_event-cancel ) ).

    DATA(lo_cells) = lo_dialog->ele( `ColumnListItem`
        )->a( n = `vAlign`   v = `Top`
        )->a( n = `selected` v = |\{{ cv_selkz }\}|
        )->ele( `cells` ).
    LOOP AT mt_column INTO DATA(ls_column).
      lo_cells->tag( `Text`
          )->a( n = `text` v = |\{{ ls_column-name }\}| ).
    ENDLOOP.

    DATA(lo_columns) = lo_dialog->ele( `columns` ).
    LOOP AT mt_column INTO ls_column.
      lo_columns->ele( `Column`
          )->ele( `header`
          )->tag( `Text`
          )->a( n = `text` t = ls_column-label ).
    ENDLOOP.

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
