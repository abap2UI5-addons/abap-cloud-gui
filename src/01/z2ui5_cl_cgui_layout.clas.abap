"! Layout of an ALV grid - the classic "Change Layout" dialog as an abap2UI5
"! app of its own: which columns are shown and in which order, how the rows
"! are sorted, which columns are summed and which give subtotals. A layout
"! can be saved under a name, one of them as the default, shared with all
"! users and protected when the store keeps that; the caller keeps them -
"! in a layout store (z2ui5_if_cgui_layouts) or as selection variants
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
        " the rank among the sorted columns the row came with - kept when
        " the rows move, a column sorted in the dialog comes after them
        sort_seq TYPE i,
        sum      TYPE abap_bool,
        subtotal TYPE abap_bool,
        numeric  TYPE abap_bool,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

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

    TYPES ty_t_saved TYPE STANDARD TABLE OF ty_s_saved WITH DEFAULT KEY.

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

    "! the rows of the dialog as a layout - position in the order of the
    "! rows, the sort rank as the rows came (sort_seq), the columns sorted
    "! in the dialog after them in the order of the rows
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
    " the saved layout loaded as it came - OK without a change applies it,
    " it is not saved again
    DATA ms_loaded TYPE ty_s_result.
    DATA mt_loaded TYPE ty_t_row.

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
    DATA ls_saved TYPE z2ui5_cl_cgui_layout=>ty_s_saved.

    CREATE OBJECT result.
    result->mt_base  = layout.
    result->mt_saved = saved.
    result->mt_row   = layout_to_rows( layout ).
    result->mv_selected = current.
    result->mv_sharing = sharing.

    READ TABLE saved INTO ls_saved WITH KEY name = current.
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

    TYPES:
      BEGIN OF ty_s_rank,
        rank TYPE i,
        name TYPE string,
      END OF ty_s_rank.
    TYPES temp1 TYPE STANDARD TABLE OF ty_s_rank WITH DEFAULT KEY.
DATA lt_rank TYPE temp1.

    " the sort rank: the one a row came with first, then the rows sorted in
    " the dialog in their order
    DATA ls_row LIKE LINE OF rows.
      DATA temp95 TYPE ty_s_rank.
      DATA temp5 TYPE ty_s_rank-rank.
      DATA lv_index LIKE sy-tabix.
      DATA lv_seq TYPE i.
      DATA temp96 TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
      DATA temp2 TYPE xsdboolean.
      DATA temp3 TYPE xsdboolean.
      DATA temp4 TYPE xsdboolean.
    LOOP AT rows INTO ls_row WHERE sort IS NOT INITIAL.

      CLEAR temp95.

      IF ls_row-sort_seq > 0.
        temp5 = ls_row-sort_seq.
      ELSE.
        temp5 = 100000 + sy-tabix.
      ENDIF.
      temp95-rank = temp5.
      temp95-name = ls_row-name.
      INSERT temp95 INTO TABLE lt_rank.
    ENDLOOP.
    SORT lt_rank BY rank.

    LOOP AT rows INTO ls_row.

      lv_index = sy-tabix.

      lv_seq = 0.
      IF ls_row-sort IS NOT INITIAL.
        READ TABLE lt_rank TRANSPORTING NO FIELDS WITH KEY name = ls_row-name.
        lv_seq = sy-tabix.
      ENDIF.

      CLEAR temp96.
      temp96-name = ls_row-name.
      temp96-text = ls_row-text.

      temp2 = boolc( ls_row-visible = abap_false ).
      temp96-hidden = temp2.
      temp96-position = lv_index.
      temp96-sort = ls_row-sort.
      temp96-sort_seq = lv_seq.

      temp3 = boolc( ls_row-sum = abap_true AND ls_row-numeric = abap_true ).
      temp96-sum = temp3.

      temp4 = boolc( ls_row-subtotal = abap_true AND ls_row-sort IS NOT INITIAL ).
      temp96-subtotal = temp4.
      temp96-numeric = ls_row-numeric.
      INSERT temp96 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD layout_to_rows.

    DATA lt_layout LIKE layout.
    DATA ls_layout LIKE LINE OF lt_layout.
      DATA temp97 TYPE z2ui5_cl_cgui_layout=>ty_s_row.
      DATA temp5 TYPE xsdboolean.
      DATA temp6 TYPE z2ui5_cl_cgui_layout=>ty_s_row-sort_seq.
    lt_layout = layout.
    SORT lt_layout STABLE BY position.

    LOOP AT lt_layout INTO ls_layout.

      CLEAR temp97.
      temp97-name = ls_layout-name.
      temp97-text = ls_layout-text.

      temp5 = boolc( ls_layout-hidden = abap_false ).
      temp97-visible = temp5.
      temp97-sort = ls_layout-sort.

      IF ls_layout-sort IS NOT INITIAL.
        temp6 = ls_layout-sort_seq.
      ELSE.
        CLEAR temp6.
      ENDIF.
      temp97-sort_seq = temp6.
      temp97-sum = ls_layout-sum.
      temp97-subtotal = ls_layout-subtotal.
      temp97-numeric = ls_layout-numeric.
      INSERT temp97 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD layout_merge.

    DATA ls_base LIKE LINE OF base.
      DATA ls_layout LIKE ls_base.
      DATA ls_saved TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
        DATA temp6 TYPE xsdboolean.
    DATA temp98 LIKE LINE OF result.
    DATA lr_layout LIKE REF TO temp98.
    LOOP AT base INTO ls_base.

      ls_layout = ls_base.

      READ TABLE saved INTO ls_saved WITH KEY name = ls_base-name.
      IF sy-subrc = 0.
        ls_layout-hidden   = ls_saved-hidden.
        ls_layout-position = ls_saved-position.
        ls_layout-sort     = ls_saved-sort.
        ls_layout-sort_seq = ls_saved-sort_seq.

        temp6 = boolc( ls_saved-sum = abap_true AND ls_base-numeric = abap_true ).
        ls_layout-sum      = temp6.
        ls_layout-subtotal = ls_saved-subtotal.
      ELSE.
        ls_layout-position = 1000 + ls_base-position.
      ENDIF.
      INSERT ls_layout INTO TABLE result.
    ENDLOOP.

    SORT result STABLE BY position.


    LOOP AT result REFERENCE INTO lr_layout.
      lr_layout->position = sy-tabix.
    ENDLOOP.

  ENDMETHOD.

  METHOD to_variant.
    DATA temp99 TYPE z2ui5_cl_cgui_variant=>ty_s_variant-text.
    DATA ls_layout LIKE LINE OF layout.
      DATA temp100 TYPE z2ui5_cl_cgui_variant=>ty_s_value.
      DATA temp7 TYPE string.
      DATA temp1 TYPE string.
      DATA temp2 TYPE string.

    result-name = |{ cv_prefix }{ name }|.

    IF is_default = abap_true.
      temp99 = `DEFAULT`.
    ELSE.
      CLEAR temp99.
    ENDIF.
    result-text = temp99.
    " the flags in sign: H hidden, S summed, T subtotals - low the position,
    " high the sort rank, option the sort

    LOOP AT layout INTO ls_layout.

      CLEAR temp100.
      temp100-name = ls_layout-name.
      temp100-kind = `L`.

      IF ls_layout-hidden = abap_true.
        temp7 = `H`.
      ELSE.
        CLEAR temp7.
      ENDIF.

      IF ls_layout-sum = abap_true.
        temp1 = `S`.
      ELSE.
        CLEAR temp1.
      ENDIF.

      IF ls_layout-subtotal = abap_true.
        temp2 = `T`.
      ELSE.
        CLEAR temp2.
      ENDIF.
      temp100-sign = |{ temp7 }| && |{ temp1 }| && |{ temp2 }|.
      temp100-option = ls_layout-sort.
      temp100-low = |{ ls_layout-position }|.
      temp100-high = |{ ls_layout-sort_seq }|.
      INSERT temp100 INTO TABLE result-values.
    ENDLOOP.

  ENDMETHOD.

  METHOD from_variants.

    DATA ls_saved TYPE ty_s_saved.

    DATA lv_length TYPE i.
    DATA ls_variant LIKE LINE OF variants.
      DATA temp7 TYPE xsdboolean.
      DATA ls_value LIKE LINE OF ls_variant-values.
            DATA temp101 TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
            DATA temp10 TYPE xsdboolean.
            DATA temp11 TYPE xsdboolean.
            DATA temp12 TYPE xsdboolean.
            DATA temp8 TYPE i.
            DATA temp9 TYPE i.
    lv_length = strlen( cv_prefix ).

    LOOP AT variants INTO ls_variant.
      IF strlen( ls_variant-name ) <= lv_length OR substring( val = ls_variant-name len = lv_length ) <> cv_prefix.
        CONTINUE.
      ENDIF.
      CLEAR ls_saved.
      ls_saved-name    = substring( val = ls_variant-name off = lv_length ).

      temp7 = boolc( ls_variant-text = `DEFAULT` ).
      ls_saved-is_default = temp7.

      LOOP AT ls_variant-values INTO ls_value WHERE kind = `L`.
        TRY.

            CLEAR temp101.
            temp101-name = ls_value-name.

            temp10 = boolc( ls_value-sign CS `H` ).
            temp101-hidden = temp10.

            temp11 = boolc( ls_value-sign CS `S` ).
            temp101-sum = temp11.

            temp12 = boolc( ls_value-sign CS `T` ).
            temp101-subtotal = temp12.
            temp101-sort = ls_value-option.

            temp8 = ls_value-low.
            temp101-position = temp8.

            temp9 = ls_value-high.
            temp101-sort_seq = temp9.
            INSERT temp101 INTO TABLE ls_saved-layout.
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

    IF client->check_on_init( ) IS NOT INITIAL.
      view_display( ).
      RETURN.
    ENDIF.

    on_event( ).

  ENDMETHOD.

  METHOD on_event.
          DATA temp13 TYPE xsdboolean.
          DATA temp14 TYPE xsdboolean.
        DATA ls_saved TYPE z2ui5_cl_cgui_layout=>ty_s_saved.

    CASE client->get_event( ).

      WHEN cs_event-ok.
        ms_result-layout = rows_to_layout( mt_row ).
        ms_result-name = condense( mv_name ).
        IF ms_result-name IS NOT INITIAL AND ms_result-name = ms_loaded-name AND mt_row = mt_loaded
            AND mv_default = ms_loaded-is_default AND mv_shared = ms_loaded-shared
            AND mv_protected = ms_loaded-protected.
          " the saved layout as it was picked - applied, not saved again: a
          " protected one of another user would refuse, a shared one be
          " written anew
          ms_result-action = cs_action-apply.
        ELSEIF ms_result-name IS NOT INITIAL.
          ms_result-action     = cs_action-save.
          ms_result-is_default = mv_default.

          temp13 = boolc( mv_sharing = abap_true AND mv_shared = abap_true ).
          ms_result-shared     = temp13.

          temp14 = boolc( mv_sharing = abap_true AND mv_protected = abap_true ).
          ms_result-protected  = temp14.
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

        READ TABLE mt_saved INTO ls_saved WITH KEY name = mv_selected.
        IF sy-subrc = 0.
          mt_row = layout_to_rows( layout_merge( base  = mt_base
                                                 saved = ls_saved-layout ) ).
          mv_name      = ls_saved-name.
          mv_default   = ls_saved-is_default.
          mv_shared    = ls_saved-shared.
          mv_protected = ls_saved-protected.
          CLEAR ms_loaded.
          ms_loaded-name = mv_name.
          ms_loaded-is_default = mv_default.
          ms_loaded-shared = mv_shared.
          ms_loaded-protected = mv_protected.
          mt_loaded = mt_row.
        ELSE.
          mt_row = layout_to_rows( mt_base ).
          CLEAR: ms_loaded, mt_loaded.
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
    DATA lv_target TYPE i.
    DATA ls_row LIKE LINE OF mt_row.
    FIELD-SYMBOLS <temp10> LIKE LINE OF mt_row.
    DATA temp11 LIKE sy-tabix.

    LOOP AT mt_row TRANSPORTING NO FIELDS WHERE name = name.
      lv_index = sy-tabix.
      EXIT.
    ENDLOOP.

    lv_target = lv_index + delta.
    IF lv_index = 0 OR lv_target < 1 OR lv_target > lines( mt_row ).
      RETURN.
    ENDIF.




    temp11 = sy-tabix.
    READ TABLE mt_row INDEX lv_index ASSIGNING <temp10>.
    sy-tabix = temp11.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_row = <temp10>.
    DELETE mt_row INDEX lv_index.
    INSERT ls_row INTO mt_row INDEX lv_target.

  ENDMETHOD.

  METHOD leave.

    client->popup_destroy( ).
    client->nav_app_leave( client->get_app_prev( ) ).

  ENDMETHOD.

  METHOD view_display.

    DATA temp102 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_content TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lo_saved TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp103 TYPE string.
      DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp104 TYPE string.
      DATA ls_saved LIKE LINE OF mt_saved.
        DATA temp105 TYPE string.
        DATA temp12 TYPE string.
      DATA temp106 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp107 TYPE string.
    DATA temp108 TYPE string.
    DATA temp109 TYPE string.
    DATA temp110 TYPE string.
    DATA temp111 TYPE string.
    DATA lo_cells TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp112 TYPE string.
    DATA temp13 TYPE string.
    DATA temp2 TYPE string.
    DATA temp113 TYPE string.
    DATA temp14 TYPE string.
    DATA temp114 TYPE string.
    DATA temp15 TYPE string.
    DATA temp3 TYPE string.
    DATA temp4 TYPE string.
    DATA temp115 TYPE string.
    DATA temp16 TYPE string.
    temp102 = 'Change Layout'(001).

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp102
        )->a( n = `contentWidth` v = `46rem`
        )->a( n = `resizable`    b = abap_true
        )->a( n = `draggable`    b = abap_true
        )->a( n = `afterClose`   v = client->_event( cs_event-cancel ) ).


    lo_content = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " the saved layouts
    IF mt_saved IS NOT INITIAL.

      lo_saved = lo_content->ele( `HBox`
          )->a( n = `alignItems` v = `Center`
          )->a( n = `class`      v = `sapUiSmallMarginBottom` ).

      temp103 = 'Saved layout'(002).
      lo_saved->tag( `Label`
          )->a( n = `text`  t = temp103
          )->a( n = `class` v = `sapUiSmallMarginEnd` ).

      lo_items = lo_saved->ele( `Select`
          )->a( n = `selectedKey`    v = client->_bind( mv_selected )
          )->a( n = `forceSelection` b = abap_false
          )->a( n = `change`         v = client->_event( cs_event-load )
          )->ele( `items` ).

      temp104 = 'Current layout'(003).
      lo_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = ``
          )->a( n = `text` t = temp104 ).

      LOOP AT mt_saved INTO ls_saved.

        IF ls_saved-is_default = abap_true.
          temp105 = | ({ 'Default'(004) })|.
        ELSE.
          CLEAR temp105.
        ENDIF.

        IF ls_saved-shared = abap_true AND ls_saved-owner IS NOT INITIAL.
          temp12 = | - { ls_saved-owner }|.
        ELSE.
          CLEAR temp12.
        ENDIF.
        lo_items->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_saved-name
            )->a( n = `text` t = |{ ls_saved-name }|
                              && |{ temp105 }|
                              && |{ temp12 }| ).
      ENDLOOP.

      temp106 = 'Delete layout'(005).
      lo_saved->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://delete`
          )->a( n = `type`    v = `Transparent`
          )->a( n = `tooltip` t = temp106
          )->a( n = `press`   v = client->_event( cs_event-delete ) ).
    ENDIF.


    lo_table = lo_content->ele( `Table`
        )->a( n = `items` v = client->_bind( mt_row ) ).

    lo_columns = lo_table->ele( `columns` ).

    temp107 = 'Visible'(006).
    lo_columns->ele( `Column` )->a( n = `width` v = `5rem` )->tag( `Text` )->a( n = `text` t = temp107 ).

    temp108 = 'Column'(007).
    lo_columns->ele( `Column` )->tag( `Text` )->a( n = `text` t = temp108 ).

    temp109 = 'Sort'(008).
    lo_columns->ele( `Column` )->a( n = `width` v = `10rem` )->tag( `Text` )->a( n = `text` t = temp109 ).

    temp110 = 'Total'(009).
    lo_columns->ele( `Column` )->a( n = `width` v = `5rem` )->tag( `Text` )->a( n = `text` t = temp110 ).

    temp111 = 'Subtotals'(010).
    lo_columns->ele( `Column` )->a( n = `width` v = `6rem` )->tag( `Text` )->a( n = `text` t = temp111 ).
    lo_columns->ele( `Column` )->a( n = `width` v = `6rem` ).


    lo_cells = lo_table->ele( `items`
        )->ele( `ColumnListItem`
        )->ele( `cells` ).
    lo_cells->tag( `CheckBox`
        )->a( n = `selected` v = `{VISIBLE}`
        )->tag( `Text`
        )->a( n = `text` v = `{TEXT}` ).

    temp112 = 'not sorted'(011).

    temp13 = 'ascending'(012).

    temp2 = 'descending'(013).
    lo_cells->ele( `Select`
        )->a( n = `selectedKey` v = `{SORT}`
        )->a( n = `width`       v = `100%`
        )->ele( `items`
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` t = temp112
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = z2ui5_cl_cgui_alv=>cs_sort-ascending
        )->a( n = `text` t = temp13
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = z2ui5_cl_cgui_alv=>cs_sort-descending
        )->a( n = `text` t = temp2 ).
    lo_cells->tag( `CheckBox`
        )->a( n = `selected` v = `{SUM}`
        )->a( n = `enabled`  v = `{NUMERIC}`
        )->tag( `CheckBox`
        )->a( n = `selected` v = `{SUBTOTAL}`
        )->a( n = `enabled`  v = `{= ${SORT} !== '' }` ).

    temp113 = 'Up'(014).

    temp14 = 'Down'(015).
    lo_cells->ele( `HBox`
        )->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://navigation-up-arrow`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` t = temp113
        )->a( n = `press`   v = client->_event( val   = cs_event-up
                                                arg   = `${NAME}` )
        )->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://navigation-down-arrow`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` t = temp14
        )->a( n = `press`   v = client->_event( val   = cs_event-down
                                                arg   = `${NAME}` ) ).


    temp114 = 'Save as layout (name)'(016).

    temp15 = 'Default layout'(017).

    temp3 = 'Shared'(020).

    temp4 = 'Protected'(021).
    lo_content->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMarginTop`
        )->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_name )
        )->a( n = `maxLength`   v = `30`
        )->a( n = `width`       v = `16rem`
        )->a( n = `placeholder` t = temp114
        )->tag( `CheckBox`
        )->a( n = `selected` v = client->_bind( mv_default )
        )->a( n = `text`     t = temp15
        )->a( n = `class`    v = `sapUiSmallMarginBegin`
        )->tag( `CheckBox`
        )->a( n = `selected` v = client->_bind( mv_shared )
        )->a( n = `text`     t = temp3
        )->a( n = `visible`  b = mv_sharing
        )->a( n = `class`    v = `sapUiSmallMarginBegin`
        )->tag( `CheckBox`
        )->a( n = `selected` v = client->_bind( mv_protected )
        )->a( n = `text`     t = temp4
        )->a( n = `visible`  b = mv_sharing
        )->a( n = `class`    v = `sapUiSmallMarginBegin` ).


    temp115 = 'OK'(018).

    temp16 = 'Cancel'(019).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp115
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-ok )
        )->tag( `Button`
        )->a( n = `text`  t = temp16
        )->a( n = `press` v = client->_event( cs_event-cancel ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
