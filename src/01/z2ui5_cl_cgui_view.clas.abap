"! The view of the SAP GUI stand-ins of a report: the controls of
"! z2ui5_if_cgui_gui - a container with its caption, a text editor, an HTML
"! viewer, a picture, a simple or column tree, a toolbar, the caption of a
"! grid that does not show - and the table control of a dynpro, each into
"! the node of the view builder it sits in. Beside the view: which editor
"! a function key goes to, whether the frontend has the HTML frame, the
"! screen a control is created for.
"! Stateless, as z2ui5_cl_cgui_memory: a call takes what it reads of the
"! report as ty_s_ctx, built by the report on the spot (gui_ctx( )) and
"! kept by nobody. The report keeps the walk over the containers
"! (gui_render( )), the ALV in the grid that shows, the interface methods
"! of z2ui5_if_cgui_gui and the dispatch of an event into the control.
CLASS z2ui5_cl_cgui_view DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_object TYPE STANDARD TABLE OF REF TO object WITH DEFAULT KEY.
    TYPES ty_flag TYPE c LENGTH 1.

    TYPES:
      "! the state of the report a call reads: the client, the controls
      "! (bound - the text of an editor, the document of a viewer are
      "! attributes of the control line) and their objects, whether the
      "! frontend has the HTML frame (empty: not asked yet), the table
      "! control of the dynpro and its rows, the screen shown, the dynpro
      "! and whether the report is in its run
      BEGIN OF ty_s_ctx,
        client     TYPE REF TO z2ui5_if_client,
        gui        TYPE REF TO z2ui5_if_cgui_gui=>ty_t_control,
        objects    TYPE ty_t_object,
        html_frame TYPE REF TO ty_flag,
        tc         TYPE string,
        tc_row     TYPE REF TO data,
        screen     TYPE string,
        dynpro     TYPE string,
        in_run     TYPE abap_bool,
      END OF ty_s_ctx.

    "! the event of the button that shows a grid that does not show
    CONSTANTS cv_show TYPE string VALUE `CGUI_SHOW`.

    "! the control id into node - every kind but a container and the grid
    "! that shows, which the report renders itself
    CLASS-METHODS render
      IMPORTING
        ctx  TYPE ty_s_ctx
        id   TYPE i
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the box of the container id into node - its caption, Close of a
    "! dialog box container (the event close); the controls in it go into
    "! the box returned
    CLASS-METHODS container
      IMPORTING
        ctx           TYPE ty_s_ctx
        id            TYPE i
        node          TYPE REF TO z2ui5_cl_ui5_view_builder
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the controls in the container id - the cells of a splitter row by
    "! row, the controls in their order
    CLASS-METHODS children
      IMPORTING
        ctx           TYPE ty_s_ctx
        id            TYPE i
      RETURNING
        VALUE(result) TYPE z2ui5_if_cgui_gui=>ty_t_control.

    "! the table control name of the dynpro into node - the lines of the
    "! PBO, the cells of a column ready for input inputs
    CLASS-METHODS tablecontrol
      IMPORTING
        ctx     TYPE ty_s_ctx
        name    TYPE string
        title   TYPE string
        columns TYPE z2ui5_if_cgui_gui=>ty_t_tc_column
        node    TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! F1 or F4 in a text editor: the editor the key goes to - the one with
    "! the focus, else the first that registered the key; 0 when none. The
    "! selection of the editor with the focus is noted on its control
    CLASS-METHODS key_target
      IMPORTING
        ctx           TYPE ty_s_ctx
        key           TYPE string
      RETURNING
        VALUE(result) TYPE i.

    "! whether the frontend has the custom control z2ui5.cc.HTMLFrame - its
    "! mirror class is part of the same abap2UI5 release; asked once
    CLASS-METHODS html_frame
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the screen a docking container without dynnr sits on - the one shown
    CLASS-METHODS screen
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE string.

    "! a control on the list of the run (cl_gui_container=>default_screen,
    "! a docking container created during the run) - the list shows it
    CLASS-METHODS on_list
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE abap_bool.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CLASS-METHODS render_textedit
      IMPORTING
        ctx     TYPE ty_s_ctx
        id      TYPE i
        control TYPE z2ui5_if_cgui_gui=>ty_s_control
        node    TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS render_html
      IMPORTING
        ctx     TYPE ty_s_ctx
        id      TYPE i
        control TYPE z2ui5_if_cgui_gui=>ty_s_control
        node    TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS render_picture
      IMPORTING
        ctx     TYPE ty_s_ctx
        id      TYPE i
        control TYPE z2ui5_if_cgui_gui=>ty_s_control
        node    TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS render_simple_tree
      IMPORTING
        ctx  TYPE ty_s_ctx
        id   TYPE i
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the cells of a node of a column tree after its text
    CLASS-METHODS render_tree_cells
      IMPORTING
        ctx     TYPE ty_s_ctx
        id      TYPE i
        tree    TYPE REF TO z2ui5_cl_cgui_simple_tree
        key     TYPE i
        columns TYPE z2ui5_cl_cgui_simple_tree=>ty_t_column
        node    TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS render_grid
      IMPORTING
        ctx  TYPE ty_s_ctx
        id   TYPE i
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS render_toolbar
      IMPORTING
        ctx     TYPE ty_s_ctx
        id      TYPE i
        control TYPE z2ui5_if_cgui_gui=>ty_s_control
        node    TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the event of the control id - the event name and its arguments
    CLASS-METHODS event
      IMPORTING
        ctx           TYPE ty_s_ctx
        id            TYPE i
        name          TYPE string
        arg1          TYPE string OPTIONAL
        arg2          TYPE string OPTIONAL
        arg3          TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    "! a width of the classic GUI in rem - 2/3 of a character
    CLASS-METHODS width
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_view IMPLEMENTATION.

  METHOD event.

    DATA lt_arg TYPE string_table.

    DATA temp1 LIKE LINE OF lt_arg.
    temp1 = |{ id }|.
    INSERT temp1 INTO TABLE lt_arg.
    INSERT name INTO TABLE lt_arg.
    IF arg1 IS SUPPLIED.
      INSERT arg1 INTO TABLE lt_arg.
    ENDIF.
    IF arg2 IS SUPPLIED.
      INSERT arg2 INTO TABLE lt_arg.
    ENDIF.
    IF arg3 IS SUPPLIED.
      INSERT arg3 INTO TABLE lt_arg.
    ENDIF.
    result = ctx-client->_event( val   = z2ui5_cl_cgui_report=>cs_ucomm-gui
                                 t_arg = lt_arg ).

  ENDMETHOD.

  METHOD width.

    DATA temp2 TYPE string.
    IF val > 0.
      temp2 = |{ val * 2 / 3 }rem|.
    ELSE.
      temp2 = `12rem`.
    ENDIF.
    result = temp2.

  ENDMETHOD.

  METHOD render.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.

    ASSIGN ctx-gui->* TO <gui>.

    READ TABLE <gui> INTO ls_control INDEX id.
    IF sy-subrc <> 0 OR ls_control-freed = abap_true OR ls_control-hidden = abap_true.
      RETURN.
    ENDIF.

    CASE ls_control-kind.
      WHEN z2ui5_if_cgui_gui=>cs_kind-textedit.
        render_textedit( ctx = ctx id = id control = ls_control node = node ).
      WHEN z2ui5_if_cgui_gui=>cs_kind-html.
        render_html( ctx = ctx id = id control = ls_control node = node ).
      WHEN z2ui5_if_cgui_gui=>cs_kind-picture.
        render_picture( ctx = ctx id = id control = ls_control node = node ).
      WHEN z2ui5_if_cgui_gui=>cs_kind-simple_tree.
        render_simple_tree( ctx = ctx id = id node = node ).
      WHEN z2ui5_if_cgui_gui=>cs_kind-grid.
        render_grid( ctx = ctx id = id node = node ).
      WHEN z2ui5_if_cgui_gui=>cs_kind-toolbar.
        render_toolbar( ctx = ctx id = id control = ls_control node = node ).
    ENDCASE.

  ENDMETHOD.

  METHOD container.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
      DATA temp3 TYPE string.

    ASSIGN ctx-gui->* TO <gui>.

    READ TABLE <gui> INTO ls_control INDEX id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    result = node->ele( `VBox`
        )->a( n = `width` v = `100%` ).
    IF ls_control-dialog = abap_true.
      " a dialog box container: its caption and Close (the event close)

      temp3 = 'Close'(001).
      result->ele( `Toolbar`
          )->tag( `Title`
              )->a( n = `text` t = ls_control-caption
          )->tag( `ToolbarSpacer`
          )->tag( `Button`
              )->a( n = `icon`    v = `sap-icon://decline`
              )->a( n = `tooltip` t = temp3
              )->a( n = `press`   v = event( ctx = ctx id = id name = `CLOSE` ) ).
    ELSEIF ls_control-caption IS NOT INITIAL.
      result->tag( `Title`
          )->a( n = `text` t = ls_control-caption ).
    ENDIF.

  ENDMETHOD.

  METHOD children.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA ls_child LIKE LINE OF <gui>.

    ASSIGN ctx-gui->* TO <gui>.

    LOOP AT <gui> INTO ls_child WHERE parent = id.
      INSERT ls_child INTO TABLE result.
    ENDLOOP.
    SORT result BY row column id.

  ENDMETHOD.

  METHOD render_textedit.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    FIELD-SYMBOLS <control> TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA temp1 TYPE xsdboolean.

    ASSIGN ctx-gui->* TO <gui>.
    " the row of the report's table itself - a binding is found by the
    " reference of the value, a copy of the row has none

    READ TABLE <gui> INDEX id ASSIGNING <control>.

    temp1 = boolc( <control>-readonly = abap_false ).
    node->tag( `TextArea`
        )->a( n = `id`       t = |{ z2ui5_cl_cgui_report=>cv_cgui_textedit_id }{ id }|
        )->a( n = `value`    v = ctx-client->_bind( val       = <control>-text
                                                    tab       = <gui>
                                                    tab_index = id )
        )->a( n = `editable` b = temp1
        )->a( n = `width`    v = `100%`
        )->a( n = `rows`     v = `12`
        )->a( n = `growing`  b = abap_true
        )->a( n = `class`    v = `sapUiTinyMarginTopBottom` ).

  ENDMETHOD.

  METHOD render_html.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    FIELD-SYMBOLS <control> TYPE z2ui5_if_cgui_gui=>ty_s_control.
      DATA lo_links TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp4 TYPE z2ui5_cl_cgui_html_viewer=>ty_t_link.
      DATA ls_link LIKE LINE OF temp4.
        DATA temp5 TYPE string.

    ASSIGN ctx-gui->* TO <gui>.
    " the row of the report's table itself - a binding is found by the
    " reference of the value, a copy of the row has none

    READ TABLE <gui> INDEX id ASSIGNING <control>.
    IF <control>-html IS NOT INITIAL AND html_frame( ctx ) = abap_true.
      " the document as it is, in a frame under the page's policy: its
      " styles apply, no script of it runs; a SAPEVENT link or a form
      " posted to a SAPEVENT action is the event, its action, query and
      " fields the arguments. content is bound - the braces of its CSS
      " would be read as a binding in the view
      node->tag( n = `HTMLFrame` ns = `z2ui5`
          )->a( n = `xmlns:z2ui5` v = `z2ui5.cc`
          )->a( n = `content`     v = ctx-client->_bind( val       = <control>-html
                                                         tab       = <gui>
                                                         tab_index = id )
          )->a( n = `width`       v = `100%`
          )->a( n = `height`      v = `40rem`
          )->a( n = `sapevent`    v = event( ctx  = ctx
                                             id   = id
                                             name = `SAPEVENT`
                                             arg1 = `${$parameters>/action}`
                                             arg2 = `${$parameters>/getdata}`
                                             arg3 = `${$parameters>/postdata}` ) ).
    ELSEIF <control>-html IS NOT INITIAL.
      " sanitized: no script, no event handler of the document
      node->tag( n = `HTML` ns = `core`
          )->a( n = `xmlns:core`      v = `sap.ui.core`
          )->a( n = `content`         v = ctx-client->_bind( val       = <control>-html
                                                             tab       = <gui>
                                                             tab_index = id )
          )->a( n = `sanitizeContent` b = abap_true
          )->a( n = `preferDOM`       b = abap_false ).
      " the SAPEVENT links of the document - the sanitized HTML has none

      lo_links = node->ele( `HBox`
          )->a( n = `wrap`  v = `Wrap`
          )->a( n = `class` v = `sapUiTinyMarginTop` ).

      temp4 = z2ui5_cl_cgui_html_viewer=>sapevent_links( <control>-html ).

      LOOP AT temp4 INTO ls_link.

        IF ls_link-text IS NOT INITIAL.
          temp5 = ls_link-text.
        ELSE.
          temp5 = ls_link-action.
        ENDIF.
        lo_links->tag( `Link`
            )->a( n = `text`  t = temp5
            )->a( n = `class` v = `sapUiSmallMarginEnd`
            )->a( n = `press` v = event( ctx  = ctx
                                         id   = id
                                         name = `SAPEVENT`
                                         arg1 = ls_link-action ) ).
      ENDLOOP.
    ELSEIF <control>-url IS NOT INITIAL.
      node->tag( `Link`
          )->a( n = `text`   t = <control>-url
          )->a( n = `href`   t = <control>-url
          )->a( n = `target` v = `_blank` ).
    ENDIF.

  ENDMETHOD.

  METHOD render_picture.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    FIELD-SYMBOLS <control> TYPE z2ui5_if_cgui_gui=>ty_s_control.
      DATA temp6 TYPE string.

    ASSIGN ctx-gui->* TO <gui>.
    " the row of the report's table itself - a binding is found by the
    " reference of the value, a copy of the row has none

    READ TABLE <gui> INDEX id ASSIGNING <control>.
    IF <control>-url CP `sap-icon://*`.
      node->tag( n = `Icon` ns = `core`
          )->a( n = `xmlns:core` v = `sap.ui.core`
          )->a( n = `src`        t = <control>-url
          )->a( n = `size`       v = `3rem`
          )->a( n = `press`      v = event( ctx = ctx id = id name = `PICTURE_CLICK` ) ).
    ELSEIF <control>-url IS NOT INITIAL.
      " stretch and fit fill the width of the container

      IF <control>-mode = 1 OR <control>-mode = 2 OR <control>-mode = 4.
        temp6 = `100%`.
      ELSE.
        CLEAR temp6.
      ENDIF.
      node->tag( `Image`
          )->a( n = `src`   v = ctx-client->_bind( val       = <control>-url
                                                   tab       = <gui>
                                                   tab_index = id )
          )->a( n = `width` v = temp6
          )->a( n = `press` v = event( ctx = ctx id = id name = `PICTURE_CLICK` ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_simple_tree.

    " the rows of the expanded branches: expander, icon, the text a link
    DATA temp7 TYPE REF TO z2ui5_cl_cgui_simple_tree.
    FIELD-SYMBOLS <temp1> LIKE LINE OF ctx-objects.
    DATA temp2 LIKE sy-tabix.
    DATA lo_stree LIKE temp7.
    DATA lo_nodes TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lt_tcol TYPE z2ui5_cl_cgui_simple_tree=>ty_t_column.
      DATA lo_head TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA ls_tcol LIKE LINE OF lt_tcol.
    DATA temp8 TYPE z2ui5_cl_cgui_tree=>ty_t_view.
    DATA ls_row LIKE LINE OF temp8.
      DATA lo_line TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lo_row LIKE lo_line.
        FIELD-SYMBOLS <temp9> LIKE LINE OF lt_tcol.
        DATA temp10 LIKE sy-tabix.
      DATA temp3 TYPE xsdboolean.
    temp2 = sy-tabix.
    READ TABLE ctx-objects INDEX id ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    temp7 ?= <temp1>.

    lo_stree = temp7.

    lo_nodes = node->ele( `VBox`
        )->a( n = `class` v = `sapUiTinyMarginTopBottom` ).
    " a column tree: the headers, the tree in the first column of its
    " width, the cells of a node after it

    lt_tcol = lo_stree->columns( ).
    IF lt_tcol IS NOT INITIAL.

      lo_head = lo_nodes->ele( `HBox`
          )->a( n = `class` v = `sapUiTinyMarginBottom` ).

      LOOP AT lt_tcol INTO ls_tcol.
        lo_head->tag( `Label`
            )->a( n = `text`   t = ls_tcol-text
            )->a( n = `design` v = `Bold`
            )->a( n = `width`  v = width( ls_tcol-width ) ).
      ENDLOOP.
    ENDIF.

    temp8 = lo_stree->view( ).

    LOOP AT temp8 INTO ls_row.

      lo_line = lo_nodes->ele( `HBox`
          )->a( n = `alignItems` v = `Center` ).

      lo_row = lo_line.
      IF lt_tcol IS NOT INITIAL.


        temp10 = sy-tabix.
        READ TABLE lt_tcol INDEX 1 ASSIGNING <temp9>.
        sy-tabix = temp10.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ls_tcol = <temp9>.
        lo_row = lo_line->ele( `HBox`
            )->a( n = `alignItems` v = `Center`
            )->a( n = `width`      v = width( ls_tcol-width ) ).
      ENDIF.
      lo_row->tag( `Text`
          )->a( n = `text`  v = ``
          )->a( n = `width` v = ls_row-indent ).
      IF ls_row-expander IS NOT INITIAL.
        lo_row->tag( `Button`
            )->a( n = `icon`  v = ls_row-expander
            )->a( n = `type`  v = `Transparent`
            )->a( n = `press` v = event( ctx = ctx id = id name = `EXPAND` arg1 = |{ ls_row-key }| ) ).
      ENDIF.
      IF ls_row-icon IS NOT INITIAL.
        lo_row->tag( n = `Icon` ns = `core`
            )->a( n = `xmlns:core` v = `sap.ui.core`
            )->a( n = `src`        v = ls_row-icon
            )->a( n = `class`      v = `sapUiTinyMarginEnd` ).
      ENDIF.

      temp3 = boolc( ls_row-key = lo_stree->selected( ) ).
      lo_row->tag( `Link`
          )->a( n = `text`       t = ls_row-text
          )->a( n = `emphasized` b = temp3
          )->a( n = `press`      v = event( ctx = ctx id = id name = `CLICK` arg1 = |{ ls_row-key }| ) ).
      render_tree_cells( ctx     = ctx
                         id      = id
                         tree    = lo_stree
                         key     = ls_row-key
                         columns = lt_tcol
                         node    = lo_line ).
    ENDLOOP.

  ENDMETHOD.

  METHOD render_tree_cells.

    DATA temp11 TYPE z2ui5_cl_cgui_simple_tree=>ty_t_cell.
    DATA ls_cell LIKE LINE OF temp11.
      DATA temp12 TYPE z2ui5_cl_cgui_simple_tree=>ty_s_column.
      DATA temp13 TYPE z2ui5_cl_cgui_simple_tree=>ty_s_column.
      DATA ls_tcol LIKE temp12.
      DATA lv_cell_width TYPE string.
      DATA lv_cell_arg TYPE string.
    temp11 = tree->cells( key ).

    LOOP AT temp11 INTO ls_cell.

      CLEAR temp12.

      READ TABLE columns INTO temp13 WITH KEY name = ls_cell-name.
      IF sy-subrc = 0.
        temp12 = temp13.
      ENDIF.

      ls_tcol = temp12.
      IF ls_tcol-width = 0.
        ls_tcol-width = ls_cell-width.
      ENDIF.

      lv_cell_width = width( ls_tcol-width ).

      lv_cell_arg = |{ key } { ls_cell-name }|.
      CASE ls_cell-kind.
        WHEN `LINK`.
          node->tag( `Link`
              )->a( n = `text`  t = ls_cell-text
              )->a( n = `width` v = lv_cell_width
              )->a( n = `press` v = event( ctx = ctx id = id name = `LINK` arg1 = lv_cell_arg ) ).
        WHEN `CHECKBOX`.
          node->tag( `CheckBox`
              )->a( n = `text`     t = ls_cell-text
              )->a( n = `selected` b = ls_cell-checked
              )->a( n = `width`    v = lv_cell_width
              )->a( n = `select`   v = event( ctx = ctx id = id name = `CHECKBOX` arg1 = lv_cell_arg ) ).
        WHEN OTHERS.
          node->tag( `Text`
              )->a( n = `text`  t = ls_cell-text
              )->a( n = `width` v = lv_cell_width ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD render_grid.

    " a grid the ALV does not show - its caption offers to show it
    DATA temp14 TYPE REF TO z2ui5_cl_cgui_alv_grid.
    FIELD-SYMBOLS <temp3> LIKE LINE OF ctx-objects.
    DATA temp4 LIKE sy-tabix.
    DATA lv_caption TYPE string.
    DATA temp15 TYPE string.
    temp4 = sy-tabix.
    READ TABLE ctx-objects INDEX id ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    temp14 ?= <temp3>.

    lv_caption = temp14->caption( ).
    IF lv_caption IS INITIAL.
      RETURN.
    ENDIF.

    temp15 = 'Show'(002).
    node->ele( `Toolbar`
        )->tag( `Title`
        )->a( n = `text` t = lv_caption
        )->tag( `ToolbarSpacer`
        )->tag( `Button`
        )->a( n = `text`  t = temp15
        )->a( n = `icon`  v = `sap-icon://table-view`
        )->a( n = `press` v = event( ctx = ctx id = id name = cv_show ) ).

  ENDMETHOD.

  METHOD render_toolbar.

    DATA lo_bar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_button LIKE LINE OF control-buttons.
      DATA temp16 TYPE string.
      DATA temp5 TYPE string.
      DATA temp1 TYPE string.
      DATA temp4 TYPE xsdboolean.
    lo_bar = node->ele( `OverflowToolbar` ).

    LOOP AT control-buttons INTO ls_button.
      IF ls_button-type = 3.
        lo_bar->tag( `ToolbarSeparator` ).
        CONTINUE.
      ENDIF.
      " a dropdown and a menu button raise dropdown_clicked, the others function_selected

      IF ls_button-icon CP `sap-icon://*`.
        temp16 = ls_button-icon.
      ELSE.
        CLEAR temp16.
      ENDIF.

      IF ls_button-checked = abap_true.
        temp5 = `Emphasized`.
      ELSE.
        temp5 = `Default`.
      ENDIF.

      IF ls_button-type = 1 OR ls_button-type = 2.
        temp1 = `DROPDOWN_CLICKED`.
      ELSE.
        temp1 = `FUNCTION_SELECTED`.
      ENDIF.

      temp4 = boolc( ls_button-disabled = abap_false ).
      lo_bar->tag( `Button`
          )->a( n = `text`    t = ls_button-text
          )->a( n = `icon`    v = temp16
          )->a( n = `tooltip` t = ls_button-quickinfo
          )->a( n = `enabled` b = temp4
          )->a( n = `type`    v = temp5
          )->a( n = `press`   v = event( ctx  = ctx
                                         id   = id
                                         name = temp1
                                         arg1 = ls_button-fcode ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD tablecontrol.

    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_column LIKE LINE OF columns.
      DATA temp17 TYPE string.
    DATA lo_cells TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lv_cell TYPE string.

    IF to_upper( name ) <> ctx-tc OR ctx-tc_row IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ctx-tc_row->* TO <rows>.
    " the lines of a table control can be many: the browser gets 50 at a time
    " and the next ones as the table grows (window_bind_tab( )); an input lands in
    " the line it was made in

    lo_table = node->ele( `Table`
        )->a( n = `items`      v = ctx-client->window_bind_tab( val    = <rows>
                                                          window = 50 )
        )->a( n = `growing`    b = abap_true
        )->a( n = `class`      v = `sapUiSmallMarginBottom` ).
    IF title IS NOT INITIAL.
      lo_table->ele( `headerToolbar`
          )->ele( `Toolbar`
          )->tag( `Title`
          )->a( n = `text` t = title ).
    ENDIF.

    lo_columns = lo_table->ele( `columns` ).

    LOOP AT columns INTO ls_column.
      IF sy-tabix > z2ui5_cl_cgui_report=>cv_cgui_tc_columns.
        EXIT.
      ENDIF.

      IF ls_column-width > 0.
        temp17 = |{ ls_column-width * 2 / 3 + 2 }rem|.
      ELSE.
        CLEAR temp17.
      ENDIF.
      lo_columns->ele( `Column`
          )->a( n = `width` v = temp17
          )->tag( `Text`
          )->a( n = `text` t = ls_column-text ).
    ENDLOOP.

    lo_cells = lo_table->ele( `items`
        )->ele( `ColumnListItem`
        )->ele( `cells` ).
    LOOP AT columns INTO ls_column.
      IF sy-tabix > z2ui5_cl_cgui_report=>cv_cgui_tc_columns.
        EXIT.
      ENDIF.

      lv_cell = |\{C{ sy-tabix WIDTH = 2 ALIGN = RIGHT PAD = '0' }\}|.
      IF ls_column-input = abap_true.
        lo_cells->tag( `Input`
            )->a( n = `value` v = lv_cell ).
      ELSE.
        lo_cells->tag( `Text`
            )->a( n = `text` v = lv_cell ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD key_target.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA ls_focus TYPE z2ui5_if_client=>ty_s_get-s_focus.
    DATA lv_id TYPE i.
      DATA temp18 TYPE i.
    FIELD-SYMBOLS <control> LIKE LINE OF <gui>.
      DATA lv_index LIKE sy-tabix.
      TYPES temp1 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_key TYPE temp1.
      DATA temp19 LIKE sy-subrc.
      DATA temp20 LIKE sy-tabix.

    ASSIGN ctx-gui->* TO <gui>.
    " the editor with the focus, else the first that registered the key

    ls_focus = ctx-client->get( )-s_focus.

    lv_id = 0.
    IF ls_focus-id CP |{ z2ui5_cl_cgui_report=>cv_cgui_textedit_id }*|.

      temp18 = substring( val = ls_focus-id off = strlen( z2ui5_cl_cgui_report=>cv_cgui_textedit_id ) ).
      lv_id = temp18.
    ENDIF.

    LOOP AT <gui> ASSIGNING <control>
         WHERE kind = z2ui5_if_cgui_gui=>cs_kind-textedit AND freed = abap_false.

      lv_index = sy-tabix.
      IF NOT ( lv_id = 0 OR lv_index = lv_id ).
        CONTINUE.
      ENDIF.


      SPLIT <control>-keys AT `,` INTO TABLE lt_key.


      temp20 = sy-tabix.
      READ TABLE lt_key WITH KEY table_line = key TRANSPORTING NO FIELDS.
      temp19 = sy-subrc.
      sy-tabix = temp20.
      IF NOT temp19 = 0.
        CONTINUE.
      ENDIF.
      IF lv_index = lv_id.
        <control>-sel_from = ls_focus-selection_start.
        <control>-sel_to = ls_focus-selection_end.
      ENDIF.
      result = lv_index.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD html_frame.

    DATA lo_builder TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp21 TYPE REF TO cl_abap_refdescr.
      DATA lv_builder TYPE string.
      DATA temp22 TYPE z2ui5_cl_cgui_view=>ty_flag.
    DATA temp5 TYPE xsdboolean.

    IF ctx-html_frame->* IS INITIAL.
      " the mirror class is named like the view builder of the same release,
      " z2ui5_cl_ui5f_htmlfrm_js - its name is derived from the builder's, so
      " it follows the namespace rename (a literal would not)

      temp21 ?= cl_abap_typedescr=>describe_by_data( lo_builder ).

      lv_builder = temp21->get_referenced_type( )->get_relative_name( ).
      cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = replace( val  = lv_builder
                                                                                 sub  = `CL_UI5_VIEW_BUILDER`
                                                                                 with = `CL_UI5F_HTMLFRM_JS` )
                                           EXCEPTIONS type_not_found = 1
                                                      OTHERS         = 2 ).

      IF sy-subrc = 0.
        temp22 = abap_true.
      ELSE.
        temp22 = `-`.
      ENDIF.
      ctx-html_frame->* = temp22.
    ENDIF.

    temp5 = boolc( ctx-html_frame->* = abap_true ).
    result = temp5.

  ENDMETHOD.

  METHOD screen.

    " during the run the controls are created for the list it writes
    DATA temp23 TYPE string.
    IF ctx-screen = `DYNPRO`.
      temp23 = ctx-dynpro.
    ELSEIF ctx-screen = `SELECTION` AND ctx-in_run = abap_false.
      temp23 = `1000`.
    ELSE.
      temp23 = `LIST`.
    ENDIF.
    result = temp23.

  ENDMETHOD.

  METHOD on_list.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.

    ASSIGN ctx-gui->* TO <gui>.
    LOOP AT <gui> TRANSPORTING NO FIELDS WHERE parent = 0 AND dynnr = `LIST` AND freed = abap_false.
      result = abap_true.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
