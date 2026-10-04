"! Layout of an ALV grid - the classic "Change Layout" dialog as an abap2UI5
"! app of its own: which columns are shown and in which order, how the rows
"! are sorted, which columns are summed and which give subtotals. A layout
"! can be saved under a name, one of them as the default, shared with all
"! users and protected when the store keeps that; the caller keeps them -
"! in a layout store (z2ui5_if_cgui_layout_store) or as selection variants
"! whose name starts with cv_prefix, see to_variant( ) / from_variants( ).
"! The popup leaves with result-action:
"!   apply  - take over result-layout
"!   save   - take it over and save it as result-name (result-is_default,
"!            result-shared, result-protected)
"!   delete - delete the saved layout result-name
"! and with no action on cancel.
CLASS z2ui5_cl_cgui_layout DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS:
      BEGIN OF cs_event,
        ok     TYPE string VALUE `CGUI_LAY_OK`,
        cancel TYPE string VALUE `CGUI_LAY_CANCEL`,
        up     TYPE string VALUE `CGUI_LAY_UP`,
        down   TYPE string VALUE `CGUI_LAY_DOWN`,
        load   TYPE string VALUE `CGUI_LAY_LOAD`,
        delete TYPE string VALUE `CGUI_LAY_DELETE`,
      END OF cs_event.

    CONSTANTS:
      BEGIN OF cs_action,
        apply  TYPE string VALUE `APPLY`,
        save   TYPE string VALUE `SAVE`,
        delete TYPE string VALUE `DELETE`,
      END OF cs_action.

    "! the prefix of the variants that hold layouts
    CONSTANTS cv_prefix TYPE string VALUE `#L#`.

    " a column as the dialog shows it
    TYPES:
      BEGIN OF ty_s_row,
        name     TYPE string,
        text     TYPE string,
        visible  TYPE abap_bool,
        sort     TYPE string,
        sum      TYPE abap_bool,
        subtotal TYPE abap_bool,
        numeric  TYPE abap_bool,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    TYPES:
      "! a saved layout - shared: every user sees it, protected: only its
      "! owner changes or deletes it (a layout store with sharing)
      BEGIN OF ty_s_saved,
        name       TYPE string,
        is_default TYPE abap_bool,
        layout     TYPE z2ui5_cl_cgui_alv=>ty_t_layout,
        shared     TYPE abap_bool,
        protected  TYPE abap_bool,
        owner      TYPE string,
      END OF ty_s_saved.

    TYPES ty_t_saved TYPE STANDARD TABLE OF ty_s_saved WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_result,
        action     TYPE string,
        layout     TYPE z2ui5_cl_cgui_alv=>ty_t_layout,
        name       TYPE string,
        is_default TYPE abap_bool,
        shared     TYPE abap_bool,
        protected  TYPE abap_bool,
      END OF ty_s_result.

    "! the columns - PUBLIC, the table of the dialog is bound to them
    DATA mt_row      TYPE ty_t_row.
    "! the name to save the layout under
    DATA mv_name     TYPE string.
    "! save it as the default layout
    DATA mv_default  TYPE abap_bool.
    "! the saved layout picked
    DATA mv_selected TYPE string.
    "! save it shared with all users / protected against changes of others
    "! - with a layout store that keeps them
    DATA mv_shared    TYPE abap_bool.
    DATA mv_protected TYPE abap_bool.

    "! layout - the current one, as z2ui5_cl_cgui_alv=>get_layout( )
    "! returns it; saved - the layouts saved; current - the name of the one
    "! in use; sharing - the store keeps shared and protected layouts
    CLASS-METHODS factory
      IMPORTING
        layout        TYPE z2ui5_cl_cgui_alv=>ty_t_layout
        saved         TYPE ty_t_saved OPTIONAL
        current       TYPE clike      OPTIONAL
        sharing       TYPE abap_bool  DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_layout.

    METHODS result
      RETURNING
        VALUE(result) TYPE ty_s_result.

    "! the rows of the dialog as a layout - position and sort rank in the
    "! order of the rows
    CLASS-METHODS rows_to_layout
      IMPORTING
        rows          TYPE ty_t_row
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_alv=>ty_t_layout.

    CLASS-METHODS layout_to_rows
      IMPORTING
        layout        TYPE z2ui5_cl_cgui_alv=>ty_t_layout
      RETURNING
        VALUE(result) TYPE ty_t_row.

    "! a saved layout over base - the columns of base it does not know
    "! keep their settings and come last
    CLASS-METHODS layout_merge
      IMPORTING
        base          TYPE z2ui5_cl_cgui_alv=>ty_t_layout
        saved         TYPE z2ui5_cl_cgui_alv=>ty_t_layout
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_alv=>ty_t_layout.

    "! a layout as a selection variant - name cv_prefix and the name of the
    "! layout, a value per column
    CLASS-METHODS to_variant
      IMPORTING
        name          TYPE clike
        is_default    TYPE abap_bool DEFAULT abap_false
        layout        TYPE z2ui5_cl_cgui_alv=>ty_t_layout
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    "! the layouts among variants
    CLASS-METHODS from_variants
      IMPORTING
        variants      TYPE z2ui5_cl_cgui_variant=>ty_t_variant
      RETURNING
        VALUE(result) TYPE ty_t_saved.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the popup travels in the draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA client    TYPE REF TO z2ui5_if_client.
    DATA mt_base   TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA mt_saved  TYPE ty_t_saved.
    DATA ms_result TYPE ty_s_result.
    DATA mv_sharing TYPE abap_bool.

  PRIVATE SECTION.

    METHODS on_event.

    METHODS move
      IMPORTING
        name  TYPE string
        delta TYPE i.

    METHODS leave.

    METHODS view_display.

ENDCLASS.


CLASS z2ui5_cl_cgui_layout IMPLEMENTATION.

  METHOD factory.

    result = NEW #( ).
    result->mt_base  = layout.
    result->mt_saved = saved.
    result->mt_row   = layout_to_rows( layout ).
    result->mv_selected = current.
    result->mv_sharing = sharing.
    READ TABLE saved INTO DATA(ls_saved) WITH KEY name = current.
    IF sy-subrc = 0.
      result->mv_default   = ls_saved-is_default.
      result->mv_shared    = ls_saved-shared.
      result->mv_protected = ls_saved-protected.
    ENDIF.

  ENDMETHOD.

  METHOD result.

    result = ms_result.

  ENDMETHOD.

  METHOD rows_to_layout.

    DATA lv_seq TYPE i.

    LOOP AT rows INTO DATA(ls_row).
      DATA(lv_index) = sy-tabix.
      IF ls_row-sort IS NOT INITIAL.
        lv_seq = lv_seq + 1.
      ENDIF.
      INSERT VALUE #( name     = ls_row-name
                      text     = ls_row-text
                      hidden   = xsdbool( ls_row-visible = abap_false )
                      position = lv_index
                      sort     = ls_row-sort
                      sort_seq = COND #( WHEN ls_row-sort IS NOT INITIAL THEN lv_seq )
                      sum      = xsdbool( ls_row-sum = abap_true AND ls_row-numeric = abap_true )
                      subtotal = xsdbool( ls_row-subtotal = abap_true AND ls_row-sort IS NOT INITIAL )
                      numeric  = ls_row-numeric ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD layout_to_rows.

    DATA(lt_layout) = layout.
    SORT lt_layout STABLE BY position.
    LOOP AT lt_layout INTO DATA(ls_layout).
      INSERT VALUE #( name     = ls_layout-name
                      text     = ls_layout-text
                      visible  = xsdbool( ls_layout-hidden = abap_false )
                      sort     = ls_layout-sort
                      sum      = ls_layout-sum
                      subtotal = ls_layout-subtotal
                      numeric  = ls_layout-numeric ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD layout_merge.

    LOOP AT base INTO DATA(ls_base).
      DATA(ls_layout) = ls_base.
      READ TABLE saved INTO DATA(ls_saved) WITH KEY name = ls_base-name.
      IF sy-subrc = 0.
        ls_layout-hidden   = ls_saved-hidden.
        ls_layout-position = ls_saved-position.
        ls_layout-sort     = ls_saved-sort.
        ls_layout-sort_seq = ls_saved-sort_seq.
        ls_layout-sum      = xsdbool( ls_saved-sum = abap_true AND ls_base-numeric = abap_true ).
        ls_layout-subtotal = ls_saved-subtotal.
      ELSE.
        ls_layout-position = 1000 + ls_base-position.
      ENDIF.
      INSERT ls_layout INTO TABLE result.
    ENDLOOP.

    SORT result STABLE BY position.
    LOOP AT result REFERENCE INTO DATA(lr_layout).
      lr_layout->position = sy-tabix.
    ENDLOOP.

  ENDMETHOD.

  METHOD to_variant.

    result-name = |{ cv_prefix }{ name }|.
    result-text = COND #( WHEN is_default = abap_true THEN `DEFAULT` ).
    " the flags in sign: H hidden, S summed, T subtotals - low the position,
    " high the sort rank, option the sort
    LOOP AT layout INTO DATA(ls_layout).
      INSERT VALUE #( name   = ls_layout-name
                      kind   = `L`
                      sign   = |{ COND #( WHEN ls_layout-hidden = abap_true THEN `H` ) }|
                            && |{ COND #( WHEN ls_layout-sum = abap_true THEN `S` ) }|
                            && |{ COND #( WHEN ls_layout-subtotal = abap_true THEN `T` ) }|
                      option = ls_layout-sort
                      low    = |{ ls_layout-position }|
                      high   = |{ ls_layout-sort_seq }| ) INTO TABLE result-values.
    ENDLOOP.

  ENDMETHOD.

  METHOD from_variants.

    DATA ls_saved TYPE ty_s_saved.

    DATA(lv_length) = strlen( cv_prefix ).
    LOOP AT variants INTO DATA(ls_variant).
      IF strlen( ls_variant-name ) <= lv_length OR substring( val = ls_variant-name len = lv_length ) <> cv_prefix.
        CONTINUE.
      ENDIF.
      CLEAR ls_saved.
      ls_saved-name    = substring( val = ls_variant-name off = lv_length ).
      ls_saved-is_default = xsdbool( ls_variant-text = `DEFAULT` ).
      LOOP AT ls_variant-values INTO DATA(ls_value) WHERE kind = `L`.
        TRY.
            INSERT VALUE #( name     = ls_value-name
                            hidden   = xsdbool( ls_value-sign CS `H` )
                            sum      = xsdbool( ls_value-sign CS `S` )
                            subtotal = xsdbool( ls_value-sign CS `T` )
                            sort     = ls_value-option
                            position = CONV i( ls_value-low )
                            sort_seq = CONV i( ls_value-high ) ) INTO TABLE ls_saved-layout.
          CATCH cx_sy_conversion_error.
            CONTINUE.
        ENDTRY.
      ENDLOOP.
      INSERT ls_saved INTO TABLE result.
    ENDLOOP.
    SORT result BY name.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      view_display( ).
      RETURN.
    ENDIF.

    on_event( ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get_event( ).

      WHEN cs_event-ok.
        ms_result-layout = rows_to_layout( mt_row ).
        ms_result-name = condense( mv_name ).
        IF ms_result-name IS NOT INITIAL.
          ms_result-action     = cs_action-save.
          ms_result-is_default = mv_default.
          ms_result-shared     = xsdbool( mv_sharing = abap_true AND mv_shared = abap_true ).
          ms_result-protected  = xsdbool( mv_sharing = abap_true AND mv_protected = abap_true ).
        ELSE.
          ms_result-action = cs_action-apply.
        ENDIF.
        leave( ).

      WHEN cs_event-cancel.
        CLEAR ms_result.
        leave( ).

      WHEN cs_event-up.
        move( name  = client->get_event_arg( )
              delta = -1 ).

      WHEN cs_event-down.
        move( name  = client->get_event_arg( )
              delta = 1 ).

      WHEN cs_event-load.
        READ TABLE mt_saved INTO DATA(ls_saved) WITH KEY name = mv_selected.
        IF sy-subrc = 0.
          mt_row = layout_to_rows( layout_merge( base  = mt_base
                                                 saved = ls_saved-layout ) ).
          mv_name      = ls_saved-name.
          mv_default   = ls_saved-is_default.
          mv_shared    = ls_saved-shared.
          mv_protected = ls_saved-protected.
        ELSE.
          mt_row = layout_to_rows( mt_base ).
        ENDIF.

      WHEN cs_event-delete.
        IF mv_selected IS NOT INITIAL.
          ms_result-action = cs_action-delete.
          ms_result-name   = mv_selected.
          leave( ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.

  METHOD move.

    DATA lv_index TYPE i.

    LOOP AT mt_row TRANSPORTING NO FIELDS WHERE name = name.
      lv_index = sy-tabix.
      EXIT.
    ENDLOOP.
    DATA(lv_target) = lv_index + delta.
    IF lv_index = 0 OR lv_target < 1 OR lv_target > lines( mt_row ).
      RETURN.
    ENDIF.

    DATA(ls_row) = mt_row[ lv_index ].
    DELETE mt_row INDEX lv_index.
    INSERT ls_row INTO mt_row INDEX lv_target.

  ENDMETHOD.

  METHOD leave.

    client->popup_destroy( ).
    client->nav_app_leave( client->get_app_prev( ) ).

  ENDMETHOD.

  METHOD view_display.

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = CONV #( 'Change Layout'(001) )
        )->a( n = `contentWidth` v = `46rem`
        )->a( n = `resizable`    b = abap_true
        )->a( n = `draggable`    b = abap_true
        )->a( n = `afterClose`   v = client->_event( cs_event-cancel ) ).

    DATA(lo_content) = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " the saved layouts
    IF mt_saved IS NOT INITIAL.
      DATA(lo_saved) = lo_content->ele( `HBox`
          )->a( n = `alignItems` v = `Center`
          )->a( n = `class`      v = `sapUiSmallMarginBottom` ).
      lo_saved->tag( `Label`
          )->a( n = `text`  t = CONV #( 'Saved layout'(002) )
          )->a( n = `class` v = `sapUiSmallMarginEnd` ).
      DATA(lo_items) = lo_saved->ele( `Select`
          )->a( n = `selectedKey`    v = client->_bind( mv_selected )
          )->a( n = `forceSelection` b = abap_false
          )->a( n = `change`         v = client->_event( cs_event-load )
          )->ele( `items` ).
      lo_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = ``
          )->a( n = `text` t = CONV #( 'Current layout'(003) ) ).
      LOOP AT mt_saved INTO DATA(ls_saved).
        lo_items->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_saved-name
            )->a( n = `text` t = |{ ls_saved-name }|
                              && |{ COND #( WHEN ls_saved-is_default = abap_true THEN | ({ 'Default'(004) })| ) }|
                              && |{ COND #( WHEN ls_saved-shared = abap_true AND ls_saved-owner IS NOT INITIAL
                                            THEN | - { ls_saved-owner }| ) }| ).
      ENDLOOP.
      lo_saved->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://delete`
          )->a( n = `type`    v = `Transparent`
          )->a( n = `tooltip` t = CONV #( 'Delete layout'(005) )
          )->a( n = `press`   v = client->_event( cs_event-delete ) ).
    ENDIF.

    DATA(lo_table) = lo_content->ele( `Table`
        )->a( n = `items` v = client->_bind( mt_row ) ).
    DATA(lo_columns) = lo_table->ele( `columns` ).
    lo_columns->ele( `Column` )->a( n = `width` v = `5rem` )->tag( `Text` )->a( n = `text` t = CONV #( 'Visible'(006) ) ).
    lo_columns->ele( `Column` )->tag( `Text` )->a( n = `text` t = CONV #( 'Column'(007) ) ).
    lo_columns->ele( `Column` )->a( n = `width` v = `10rem` )->tag( `Text` )->a( n = `text` t = CONV #( 'Sort'(008) ) ).
    lo_columns->ele( `Column` )->a( n = `width` v = `5rem` )->tag( `Text` )->a( n = `text` t = CONV #( 'Total'(009) ) ).
    lo_columns->ele( `Column` )->a( n = `width` v = `6rem` )->tag( `Text` )->a( n = `text` t = CONV #( 'Subtotals'(010) ) ).
    lo_columns->ele( `Column` )->a( n = `width` v = `6rem` ).

    DATA(lo_cells) = lo_table->ele( `items`
        )->ele( `ColumnListItem`
        )->ele( `cells` ).
    lo_cells->tag( `CheckBox`
        )->a( n = `selected` v = `{VISIBLE}`
        )->tag( `Text`
        )->a( n = `text` v = `{TEXT}` ).
    lo_cells->ele( `Select`
        )->a( n = `selectedKey` v = `{SORT}`
        )->a( n = `width`       v = `100%`
        )->ele( `items`
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` t = CONV #( 'not sorted'(011) )
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = z2ui5_cl_cgui_alv=>cs_sort-ascending
        )->a( n = `text` t = CONV #( 'ascending'(012) )
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = z2ui5_cl_cgui_alv=>cs_sort-descending
        )->a( n = `text` t = CONV #( 'descending'(013) ) ).
    lo_cells->tag( `CheckBox`
        )->a( n = `selected` v = `{SUM}`
        )->a( n = `enabled`  v = `{NUMERIC}`
        )->tag( `CheckBox`
        )->a( n = `selected` v = `{SUBTOTAL}`
        )->a( n = `enabled`  v = `{= ${SORT} !== '' }` ).
    lo_cells->ele( `HBox`
        )->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://navigation-up-arrow`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` t = CONV #( 'Up'(014) )
        )->a( n = `press`   v = client->_event( val   = cs_event-up
                                                arg   = `${NAME}` )
        )->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://navigation-down-arrow`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` t = CONV #( 'Down'(015) )
        )->a( n = `press`   v = client->_event( val   = cs_event-down
                                                arg   = `${NAME}` ) ).

    lo_content->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMarginTop`
        )->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_name )
        )->a( n = `maxLength`   v = `30`
        )->a( n = `width`       v = `16rem`
        )->a( n = `placeholder` t = CONV #( 'Save as layout (name)'(016) )
        )->tag( `CheckBox`
        )->a( n = `selected` v = client->_bind( mv_default )
        )->a( n = `text`     t = CONV #( 'Default layout'(017) )
        )->a( n = `class`    v = `sapUiSmallMarginBegin`
        )->tag( `CheckBox`
        )->a( n = `selected` v = client->_bind( mv_shared )
        )->a( n = `text`     t = CONV #( 'Shared'(020) )
        )->a( n = `visible`  b = mv_sharing
        )->a( n = `class`    v = `sapUiSmallMarginBegin`
        )->tag( `CheckBox`
        )->a( n = `selected` v = client->_bind( mv_protected )
        )->a( n = `text`     t = CONV #( 'Protected'(021) )
        )->a( n = `visible`  b = mv_sharing
        )->a( n = `class`    v = `sapUiSmallMarginBegin` ).

    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = CONV #( 'OK'(018) )
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-ok )
        )->tag( `Button`
        )->a( n = `text`  t = CONV #( 'Cancel'(019) )
        )->a( n = `press` v = client->_event( cs_event-cancel ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
