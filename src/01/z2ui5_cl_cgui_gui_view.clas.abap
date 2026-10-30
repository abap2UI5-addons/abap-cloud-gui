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
CLASS z2ui5_cl_cgui_gui_view DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_object TYPE STANDARD TABLE OF REF TO object WITH EMPTY KEY.
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
        tree    TYPE REF TO z2ui5_cl_cgui_gui_simple_tree
        key     TYPE i
        columns TYPE z2ui5_cl_cgui_gui_simple_tree=>ty_t_column
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


CLASS z2ui5_cl_cgui_gui_view IMPLEMENTATION.

  METHOD event.

    DATA lt_arg TYPE string_table.

    INSERT |{ id }| INTO TABLE lt_arg.
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

    result = COND #( WHEN val > 0 THEN |{ val * 2 / 3 }rem| ELSE `12rem` ).

  ENDMETHOD.

  METHOD render.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.

    ASSIGN ctx-gui->* TO <gui>.
    READ TABLE <gui> INTO DATA(ls_control) INDEX id.
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

    ASSIGN ctx-gui->* TO <gui>.
    READ TABLE <gui> INTO DATA(ls_control) INDEX id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    result = node->ele( `VBox`
        )->a( n = `width` v = `100%` ).
    IF ls_control-dialog = abap_true.
      " a dialog box container: its caption and Close (the event close)
      result->ele( `Toolbar`
          )->tag( `Title`
              )->a( n = `text` t = ls_control-caption
          )->tag( `ToolbarSpacer`
          )->tag( `Button`
              )->a( n = `icon`    v = `sap-icon://decline`
              )->a( n = `tooltip` t = CONV string( 'Close'(001) )
              )->a( n = `press`   v = event( ctx = ctx id = id name = `CLOSE` ) ).
    ELSEIF ls_control-caption IS NOT INITIAL.
      result->tag( `Title`
          )->a( n = `text` t = ls_control-caption ).
    ENDIF.

  ENDMETHOD.

  METHOD children.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.

    ASSIGN ctx-gui->* TO <gui>.
    LOOP AT <gui> INTO DATA(ls_child) WHERE parent = id.
      INSERT ls_child INTO TABLE result.
    ENDLOOP.
    SORT result BY row column id.

  ENDMETHOD.

  METHOD render_textedit.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.

    ASSIGN ctx-gui->* TO <gui>.
    " the row of the report's table itself - a binding is found by the
    " reference of the value, a copy of the row has none
    ASSIGN <gui>[ id ] TO FIELD-SYMBOL(<control>).
    node->tag( `TextArea`
        )->a( n = `id`       t = |{ z2ui5_cl_cgui_report=>cv_cgui_textedit_id }{ id }|
        )->a( n = `value`    v = ctx-client->_bind( val       = <control>-text
                                                    tab       = <gui>
                                                    tab_index = id )
        )->a( n = `editable` b = xsdbool( <control>-readonly = abap_false )
        )->a( n = `width`    v = `100%`
        )->a( n = `rows`     v = `12`
        )->a( n = `growing`  b = abap_true
        )->a( n = `class`    v = `sapUiTinyMarginTopBottom` ).

  ENDMETHOD.

  METHOD render_html.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.

    ASSIGN ctx-gui->* TO <gui>.
    " the row of the report's table itself - a binding is found by the
    " reference of the value, a copy of the row has none
    ASSIGN <gui>[ id ] TO FIELD-SYMBOL(<control>).
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
      DATA(lo_links) = node->ele( `HBox`
          )->a( n = `wrap`  v = `Wrap`
          )->a( n = `class` v = `sapUiTinyMarginTop` ).
      LOOP AT z2ui5_cl_cgui_gui_html_viewer=>sapevent_links( <control>-html ) INTO DATA(ls_link).
        lo_links->tag( `Link`
            )->a( n = `text`  t = COND #( WHEN ls_link-text IS NOT INITIAL THEN ls_link-text ELSE ls_link-action )
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

    ASSIGN ctx-gui->* TO <gui>.
    " the row of the report's table itself - a binding is found by the
    " reference of the value, a copy of the row has none
    ASSIGN <gui>[ id ] TO FIELD-SYMBOL(<control>).
    IF <control>-url CP `sap-icon://*`.
      node->tag( n = `Icon` ns = `core`
          )->a( n = `xmlns:core` v = `sap.ui.core`
          )->a( n = `src`        t = <control>-url
          )->a( n = `size`       v = `3rem`
          )->a( n = `press`      v = event( ctx = ctx id = id name = `PICTURE_CLICK` ) ).
    ELSEIF <control>-url IS NOT INITIAL.
      " stretch and fit fill the width of the container
      node->tag( `Image`
          )->a( n = `src`   v = ctx-client->_bind( val       = <control>-url
                                                   tab       = <gui>
                                                   tab_index = id )
          )->a( n = `width` v = COND #( WHEN <control>-mode = 1 OR <control>-mode = 2 OR <control>-mode = 4 THEN `100%` )
          )->a( n = `press` v = event( ctx = ctx id = id name = `PICTURE_CLICK` ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_simple_tree.

    " the rows of the expanded branches: expander, icon, the text a link
    DATA(lo_stree) = CAST z2ui5_cl_cgui_gui_simple_tree( ctx-objects[ id ] ).
    DATA(lo_nodes) = node->ele( `VBox`
        )->a( n = `class` v = `sapUiTinyMarginTopBottom` ).
    " a column tree: the headers, the tree in the first column of its
    " width, the cells of a node after it
    DATA(lt_tcol) = lo_stree->columns( ).
    IF lt_tcol IS NOT INITIAL.
      DATA(lo_head) = lo_nodes->ele( `HBox`
          )->a( n = `class` v = `sapUiTinyMarginBottom` ).
      LOOP AT lt_tcol INTO DATA(ls_tcol).
        lo_head->tag( `Label`
            )->a( n = `text`   t = ls_tcol-text
            )->a( n = `design` v = `Bold`
            )->a( n = `width`  v = width( ls_tcol-width ) ).
      ENDLOOP.
    ENDIF.
    LOOP AT lo_stree->view( ) INTO DATA(ls_row).
      DATA(lo_line) = lo_nodes->ele( `HBox`
          )->a( n = `alignItems` v = `Center` ).
      DATA(lo_row) = lo_line.
      IF lt_tcol IS NOT INITIAL.
        ls_tcol = lt_tcol[ 1 ].
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
      lo_row->tag( `Link`
          )->a( n = `text`       t = ls_row-text
          )->a( n = `emphasized` b = xsdbool( ls_row-key = lo_stree->selected( ) )
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

    LOOP AT tree->cells( key ) INTO DATA(ls_cell).
      DATA(ls_tcol) = VALUE #( columns[ name = ls_cell-name ] OPTIONAL ).
      IF ls_tcol-width = 0.
        ls_tcol-width = ls_cell-width.
      ENDIF.
      DATA(lv_cell_width) = width( ls_tcol-width ).
      DATA(lv_cell_arg) = |{ key } { ls_cell-name }|.
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
    DATA(lv_caption) = CAST z2ui5_cl_cgui_gui_alv_grid( ctx-objects[ id ] )->caption( ).
    IF lv_caption IS INITIAL.
      RETURN.
    ENDIF.
    node->ele( `Toolbar`
        )->tag( `Title`
        )->a( n = `text` t = lv_caption
        )->tag( `ToolbarSpacer`
        )->tag( `Button`
        )->a( n = `text`  t = CONV #( 'Show'(002) )
        )->a( n = `icon`  v = `sap-icon://table-view`
        )->a( n = `press` v = event( ctx = ctx id = id name = cv_show ) ).

  ENDMETHOD.

  METHOD render_toolbar.

    DATA(lo_bar) = node->ele( `OverflowToolbar` ).
    LOOP AT control-buttons INTO DATA(ls_button).
      IF ls_button-type = 3.
        lo_bar->tag( `ToolbarSeparator` ).
        CONTINUE.
      ENDIF.
      " a dropdown and a menu button raise dropdown_clicked, the others function_selected
      lo_bar->tag( `Button`
          )->a( n = `text`    t = ls_button-text
          )->a( n = `icon`    v = COND #( WHEN ls_button-icon CP `sap-icon://*` THEN ls_button-icon )
          )->a( n = `tooltip` t = ls_button-quickinfo
          )->a( n = `enabled` b = xsdbool( ls_button-disabled = abap_false )
          )->a( n = `type`    v = COND #( WHEN ls_button-checked = abap_true THEN `Emphasized` ELSE `Default` )
          )->a( n = `press`   v = event( ctx  = ctx
                                         id   = id
                                         name = COND #( WHEN ls_button-type = 1 OR ls_button-type = 2
                                                        THEN `DROPDOWN_CLICKED` ELSE `FUNCTION_SELECTED` )
                                         arg1 = ls_button-fcode ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD tablecontrol.

    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.

    IF to_upper( name ) <> ctx-tc OR ctx-tc_row IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ctx-tc_row->* TO <rows>.
    DATA(lo_table) = node->ele( `Table`
        )->a( n = `items`      v = ctx-client->_bind( <rows> )
        )->a( n = `growing`    b = abap_true
        )->a( n = `growingThreshold` v = `50`
        )->a( n = `class`      v = `sapUiSmallMarginBottom` ).
    IF title IS NOT INITIAL.
      lo_table->ele( `headerToolbar`
          )->ele( `Toolbar`
          )->tag( `Title`
          )->a( n = `text` t = title ).
    ENDIF.
    DATA(lo_columns) = lo_table->ele( `columns` ).
    LOOP AT columns INTO DATA(ls_column).
      IF sy-tabix > z2ui5_cl_cgui_report=>cv_cgui_tc_columns.
        EXIT.
      ENDIF.
      lo_columns->ele( `Column`
          )->a( n = `width` v = COND #( WHEN ls_column-width > 0 THEN |{ ls_column-width * 2 / 3 + 2 }rem| )
          )->tag( `Text`
          )->a( n = `text` t = ls_column-text ).
    ENDLOOP.
    DATA(lo_cells) = lo_table->ele( `items`
        )->ele( `ColumnListItem`
        )->ele( `cells` ).
    LOOP AT columns INTO ls_column.
      IF sy-tabix > z2ui5_cl_cgui_report=>cv_cgui_tc_columns.
        EXIT.
      ENDIF.
      DATA(lv_cell) = |\{C{ sy-tabix WIDTH = 2 ALIGN = RIGHT PAD = '0' }\}|.
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

    ASSIGN ctx-gui->* TO <gui>.
    " the editor with the focus, else the first that registered the key
    DATA(ls_focus) = ctx-client->get( )-s_focus.
    DATA(lv_id) = 0.
    IF ls_focus-id CP |{ z2ui5_cl_cgui_report=>cv_cgui_textedit_id }*|.
      lv_id = CONV i( substring( val = ls_focus-id
                                 off = strlen( z2ui5_cl_cgui_report=>cv_cgui_textedit_id ) ) ).
    ENDIF.
    LOOP AT <gui> ASSIGNING FIELD-SYMBOL(<control>)
         WHERE kind = z2ui5_if_cgui_gui=>cs_kind-textedit AND freed = abap_false.
      DATA(lv_index) = sy-tabix.
      IF NOT ( lv_id = 0 OR lv_index = lv_id ).
        CONTINUE.
      ENDIF.
      SPLIT <control>-keys AT `,` INTO TABLE DATA(lt_key).
      IF NOT line_exists( lt_key[ table_line = key ] ).
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

    IF ctx-html_frame->* IS INITIAL.
      cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = `Z2UI5_CL_UI5F_HTMLFRM_JS`
                                           EXCEPTIONS type_not_found = 1
                                                      OTHERS         = 2 ).
      ctx-html_frame->* = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE `-` ).
    ENDIF.
    result = xsdbool( ctx-html_frame->* = abap_true ).

  ENDMETHOD.

  METHOD screen.

    " during the run the controls are created for the list it writes
    result = COND #( WHEN ctx-screen = `DYNPRO` THEN ctx-dynpro
                     WHEN ctx-screen = `SELECTION` AND ctx-in_run = abap_false THEN `1000`
                     ELSE `LIST` ).

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
