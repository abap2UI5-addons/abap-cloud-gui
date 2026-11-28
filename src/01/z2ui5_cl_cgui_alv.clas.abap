"! ALV grid - the abap2UI5 counterpart of CL_SALV_TABLE, built on
"! z2ui5_cl_ui5_view_builder. The columns come from the line type of the
"! table (RTTI), their headers from the DDIC labels; dates, times and
"! numbers are shown in the user's format, sorting, filtering and the
"! column menu run in the browser without a roundtrip.
"! The object only holds the settings - it binds nothing and is
"! serializable, so it can stay an attribute of the app. The table itself
"! is handed to render( ) / stringify( ) and must be a PUBLIC attribute of
"! the app (or the target of one of its data references):
"!   client->view_display( z2ui5_cl_cgui_alv=>factory(
"!       )->set_title( `Flights`
"!       )->set_column_hidden( `MANDT`
"!       )->set_selection_mode( )
"!       )->add_function( name = `BOOK` text = `Book` icon = `sap-icon://cart`
"!       )->stringify( client = client
"!                     tab    = mt_flight ) ).
"! A click on a row raises cs_event-line_selection when set_line_selection( )
"! is on; get_row_by_event( ) returns the index of that row in the table.
"! A hotspot column raises cs_event-hotspot, get_hotspot_by_event( ) returns
"! row and column. A function of the toolbar raises its name as event.
"! With set_selection_mode( ) the rows get a selection column, bound to the
"! box field of the line type (the classic BOX_FIELDNAME, an abap_bool) -
"! get_selected_rows( ) reads it. handle_event( ) answers the events of the
"! toolbar the grid brings along: select all, deselect all and export
"! (CSV or Excel).
"! set_edit( ) / set_column_edit( ) make cells input fields - a change
"! raises cs_event-data_changed, get_hotspot_by_event( ) returns its row and
"! column. The layout - order, visibility, sorting, totals and subtotals of
"! the columns - is set with set_layout( ) / set_sort( ) and read with
"! get_layout( ); the layout button raises cs_event-layout.
CLASS z2ui5_cl_cgui_alv DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    CONSTANTS:
      BEGIN OF cs_event,
        line_selection TYPE string VALUE `CGUI_ALV_LINE_SELECTION`,
        hotspot        TYPE string VALUE `CGUI_ALV_HOTSPOT`,
        select_all     TYPE string VALUE `CGUI_ALV_SELECT_ALL`,
        deselect_all   TYPE string VALUE `CGUI_ALV_DESELECT_ALL`,
        export         TYPE string VALUE `CGUI_ALV_EXPORT`,
        export_xlsx    TYPE string VALUE `CGUI_ALV_EXPORT_XLSX`,
        layout         TYPE string VALUE `CGUI_ALV_LAYOUT`,
        data_changed   TYPE string VALUE `CGUI_ALV_DATA_CHANGED`,
        page           TYPE string VALUE `CGUI_ALV_PAGE`,
        filter         TYPE string VALUE `CGUI_ALV_FILTER`,
        filter_clear   TYPE string VALUE `CGUI_ALV_FILTER_CLEAR`,
        details        TYPE string VALUE `CGUI_ALV_DETAILS`,
        details_close  TYPE string VALUE `CGUI_ALV_DETAILS_CLOSE`,
        search         TYPE string VALUE `CGUI_ALV_SEARCH`,
        f4             TYPE string VALUE `CGUI_ALV_F4`,
        chart          TYPE string VALUE `CGUI_ALV_CHART`,
        chart_close    TYPE string VALUE `CGUI_ALV_CHART_CLOSE`,
        "! a large table (set_paging) asks for rows - the request is in
        "! client->get( )-r_event_data (z2ui5_if_client=>ty_s_window_request)
        rows           TYPE string VALUE `CGUI_ALV_ROWS`,
      END OF cs_event.

    CONSTANTS:
      "! the aggregation of a column - the classic AGGREGATION of CL_SALV
      BEGIN OF cs_aggregation,
        none    TYPE string VALUE ``,
        sum     TYPE string VALUE `SUM`,
        average TYPE string VALUE `AVG`,
        minimum TYPE string VALUE `MIN`,
        maximum TYPE string VALUE `MAX`,
        count   TYPE string VALUE `COUNT`,
      END OF cs_aggregation.

    CONSTANTS:
      "! the cell type of a column - the classic CELL_TYPE of CL_SALV
      BEGIN OF cs_cell_type,
        text             TYPE string VALUE ``,
        checkbox_hotspot TYPE string VALUE `CHECKBOX_HOTSPOT`,
        button           TYPE string VALUE `BUTTON`,
        dropdown         TYPE string VALUE `DROPDOWN`,
      END OF cs_cell_type.

    CONSTANTS:
      BEGIN OF cs_align,
        left   TYPE string VALUE `Begin`,
        center TYPE string VALUE `Center`,
        right  TYPE string VALUE `End`,
      END OF cs_align.

    CONSTANTS:
      "! the classic colors Cxyz as UI5 highlights / states - x is the color
      BEGIN OF cs_color,
        heading  TYPE string VALUE `C100`,
        normal   TYPE string VALUE `C200`,
        total    TYPE string VALUE `C300`,
        key      TYPE string VALUE `C400`,
        positive TYPE string VALUE `C500`,
        negative TYPE string VALUE `C600`,
        group    TYPE string VALUE `C700`,
      END OF cs_color.

    CONSTANTS:
      "! deprecated - the page buttons are gone: set_paging( ) binds a window
      "! of rows the grid scrolls through; kept for callers, removed with the
      "! next major release, as get_page( ), get_page_offset( ), page_turn( )
      "! and cs_event-page
      BEGIN OF cs_page,
        first    TYPE string VALUE `FIRST`,
        previous TYPE string VALUE `PREVIOUS`,
        next     TYPE string VALUE `NEXT`,
        last     TYPE string VALUE `LAST`,
      END OF cs_page.

    CONSTANTS:
      BEGIN OF cs_sort,
        ascending  TYPE string VALUE `ASC`,
        descending TYPE string VALUE `DESC`,
      END OF cs_sort.

    CONSTANTS:
      BEGIN OF cs_format,
        csv  TYPE string VALUE `CSV`,
        xlsx TYPE string VALUE `XLSX`,
      END OF cs_format.

    CONSTANTS:
      BEGIN OF cs_selection_mode,
        none     TYPE string VALUE `NONE`,
        single   TYPE string VALUE `SINGLE`,
        multiple TYPE string VALUE `MULTIPLE`,
      END OF cs_selection_mode.

    "! the box field the report adds to a table that has none of its own
    CONSTANTS cv_box_field TYPE string VALUE `ZZSELKZ`.

    TYPES:
      BEGIN OF ty_s_column,
        name     TYPE string,
        text     TYPE string,
        hidden   TYPE abap_bool,
        width    TYPE string,
        icon     TYPE abap_bool,
        hotspot  TYPE abap_bool,
        currency TYPE string,
        sum      TYPE abap_bool,
        edit     TYPE abap_bool,
        no_edit  TYPE abap_bool,
        position TYPE i,
        sort     TYPE string,
        sort_seq TYPE i,
        subtotal TYPE abap_bool,
        color       TYPE string,
        color_field TYPE string,
        tooltip     TYPE string,
        key         TYPE abap_bool,
        technical   TYPE abap_bool,
        no_zero     TYPE abap_bool,
        quantity    TYPE string,
        align       TYPE string,
        aggregation TYPE string,
        cell_type   TYPE string,
        f4          TYPE abap_bool,
      END OF ty_s_column.

    " a value of a dropdown column
    TYPES:
      BEGIN OF ty_s_value,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_value.
    TYPES ty_t_value TYPE STANDARD TABLE OF ty_s_value WITH DEFAULT KEY.

    " the aggregate of column over the rows - of the rows of one currency
    " or unit (unit) where the column has one: amounts of different
    " currencies are not added up
    TYPES:
      BEGIN OF ty_s_aggregate,
        column      TYPE string,
        label       TYPE string,
        aggregation TYPE string,
        value       TYPE decfloat34,
        unit        TYPE string,
      END OF ty_s_aggregate.
    TYPES ty_t_aggregate TYPE STANDARD TABLE OF ty_s_aggregate WITH DEFAULT KEY.

    " a filter of the grid: the column and the lines of its multiple
    " selection - sign, option, low, high as text
    TYPES:
      BEGIN OF ty_s_filter,
        name TYPE string,
        rows TYPE z2ui5_cl_cgui_range=>ty_t_row,
      END OF ty_s_filter.
    TYPES ty_t_filter TYPE STANDARD TABLE OF ty_s_filter WITH DEFAULT KEY.

    "! row numbers of a table
    TYPES ty_t_index TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    " a line of the header above the grid - without label a heading
    TYPES:
      BEGIN OF ty_s_header,
        label TYPE string,
        value TYPE string,
      END OF ty_s_header.
    TYPES ty_t_header TYPE STANDARD TABLE OF ty_s_header WITH DEFAULT KEY.

    " a column of the layout: position from 1, sort cs_sort and sort_seq
    " its rank among the sorted columns, numeric whether it can be summed
    TYPES:
      BEGIN OF ty_s_layout,
        name     TYPE string,
        text     TYPE string,
        hidden   TYPE abap_bool,
        position TYPE i,
        sort     TYPE string,
        sort_seq TYPE i,
        sum      TYPE abap_bool,
        subtotal TYPE abap_bool,
        numeric  TYPE abap_bool,
      END OF ty_s_layout.
    TYPES ty_t_layout TYPE STANDARD TABLE OF ty_s_layout WITH DEFAULT KEY.

    " the subtotal of column for the rows whose subtotal columns hold group
    " - and, where the column has a currency or unit, that one (unit)
    TYPES:
      BEGIN OF ty_s_subtotal,
        group  TYPE string,
        column TYPE string,
        value  TYPE decfloat34,
        unit   TYPE string,
      END OF ty_s_subtotal.
    TYPES ty_t_subtotal TYPE STANDARD TABLE OF ty_s_subtotal WITH DEFAULT KEY.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_function,
        name    TYPE string,
        text    TYPE string,
        icon    TYPE string,
        tooltip TYPE string,
      END OF ty_s_function.
    TYPES ty_t_function TYPE STANDARD TABLE OF ty_s_function WITH DEFAULT KEY.

    TYPES ty_t_row TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    TYPES:
      "! a line of LVC_T_ROW, the rows of the classic grid (cl_gui_alv_grid,
      "! get_selected_rows( ) et_index_rows) - without the DDIC type, which
      "! ABAP Cloud does not have
      BEGIN OF ty_s_lvc_row,
        index   TYPE i,
        rowtype TYPE c LENGTH 30,
      END OF ty_s_lvc_row.
    TYPES ty_t_lvc_row TYPE STANDARD TABLE OF ty_s_lvc_row WITH DEFAULT KEY ##NEEDED.

    TYPES:
      "! a line of LVC_T_ROID - et_row_no of get_selected_rows( )
      BEGIN OF ty_s_lvc_roid,
        row_id     TYPE i,
        sub_row_id TYPE i,
      END OF ty_s_lvc_roid.
    TYPES ty_t_lvc_roid TYPE STANDARD TABLE OF ty_s_lvc_roid WITH DEFAULT KEY ##NEEDED.

    TYPES:
      "! LVC_S_COL - e_column_id of the HOTSPOT_CLICK handler of the grid
      BEGIN OF ty_s_lvc_col ##NEEDED,
        fieldname TYPE c LENGTH 30,
      END OF ty_s_lvc_col.

    TYPES:
      BEGIN OF ty_s_hotspot,
        row    TYPE i,
        column TYPE string,
      END OF ty_s_hotspot.

    CLASS-METHODS factory
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the index (1-based) of the row a line selection event was raised on,
    "! 0 when the event carries none
    CLASS-METHODS get_row_by_event
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE i.

    "! row (1-based) and column of a cs_event-hotspot event
    CLASS-METHODS get_hotspot_by_event
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE ty_s_hotspot.

    "! the row index (1-based) at the end of a binding path - 0 when the
    "! path carries none
    CLASS-METHODS row_by_path
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE i.

    METHODS set_title
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS set_column_text
      IMPORTING
        name          TYPE clike
        text          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the columns tab shows, in their order, each with its name and its text
    "! (set_column_text( ), else the DDIC label) - the loop over
    "! get_columns( )->get( ) of CL_SALV_TABLE
    METHODS get_columns
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_context=>ty_t_comp.

    METHODS set_column_hidden
      IMPORTING
        name          TYPE clike
        hidden        TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! a fixed width, any CSS size - `8rem`, `120px`
    METHODS set_column_width
      IMPORTING
        name          TYPE clike
        width         TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the cells hold UI5 icons (`sap-icon://accept`) - a traffic light or
    "! status column, the classic ICON = 'X'
    METHODS set_column_icon
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the cells are links raising cs_event-hotspot - the classic HOTSPOT
    METHODS set_column_hotspot
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! an amount whose currency key is in the column currency_field: shown
    "! with the decimals of its currency - the classic CFIELDNAME
    METHODS set_column_currency
      IMPORTING
        name           TYPE clike
        currency_field TYPE clike
      RETURNING
        VALUE(result)  TYPE REF TO z2ui5_cl_cgui_alv.

    "! the total of the column is shown below the grid - the classic DO_SUM
    METHODS set_column_sum
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! rows are clickable and raise cs_event-line_selection (double click)
    METHODS set_line_selection
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the number of rows visible without scrolling
    METHODS set_visible_rows
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! cs_selection_mode-multiple: a selection column, bound to box_field
    "! of the line type - an abap_bool. Without one of its own the report
    "! runtime shows a copy of the table with the field cv_box_field
    METHODS set_selection_mode
      IMPORTING
        val           TYPE clike DEFAULT cs_selection_mode-multiple
        box_field     TYPE clike DEFAULT cv_box_field
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS get_selection_mode
      RETURNING
        VALUE(result) TYPE string.

    METHODS get_box_field
      RETURNING
        VALUE(result) TYPE string.

    "! a button in the toolbar of the grid raising name as event - in the
    "! report runtime it arrives in at_user_command( )
    METHODS add_function
      IMPORTING
        name          TYPE clike
        text          TYPE clike OPTIONAL
        icon          TYPE clike OPTIONAL
        tooltip       TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the export button of the toolbar - on by default
    METHODS set_export
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
        separator     TYPE clike     DEFAULT `;`
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the column widths follow the content - on by default, the classic
    "! CWIDTH_OPT; off, the columns share the width of the grid
    METHODS set_optimize
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! all cells are input fields - but icons, hotspots and columns set
    "! with set_column_edit( val = abap_false ); the classic EDIT = 'X'
    METHODS set_edit
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the cells of the column are input fields - the classic EDIT of the
    "! field catalog. A change raises cs_event-data_changed
    METHODS set_column_edit
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! has the grid input fields
    METHODS is_editable
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! sort by the column - after the columns sorted before; subtotal
    "! shows the subtotals of the summed columns per value of it
    METHODS set_sort
      IMPORTING
        name          TYPE clike
        descending    TYPE abap_bool DEFAULT abap_false
        subtotal      TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the position of the column, from 1 - the classic COL_POS
    METHODS set_column_position
      IMPORTING
        name          TYPE clike
        position      TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! large tables: the browser gets page_size rows at a time and the next
    "! ones as the grid scrolls - the table handed to render( ) is bound with
    "! window_bind_tab( ) as the rows loaded so far, total as the rows there
    "! are, and the grid asks for more rows, a sort or a filter of a column
    "! menu with the event cs_event-rows. The report runtime answers it over
    "! all rows (window_request( ), window_order( )); selection, input and
    "! events land in the rows they were made in. 0 switches it off
    METHODS set_paging
      IMPORTING
        page_size     TYPE i DEFAULT 500
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the rows a page holds - 0 without paging
    METHODS get_page_size
      RETURNING
        VALUE(result) TYPE i.

    "! deprecated - the page shown, from 1; the grid shows no pages, it
    "! scrolls through a window of rows (set_paging( ))
    METHODS get_page
      RETURNING
        VALUE(result) TYPE i.

    "! deprecated - the rows before the page shown - add it to a row of the
    "! page to get the row of the table
    METHODS get_page_offset
      RETURNING
        VALUE(result) TYPE i.

    "! deprecated - turn the page - cs_page - for a table of lines rows;
    "! no control of the grid raises cs_event-page any more
    METHODS page_turn
      IMPORTING
        direction TYPE clike
        lines     TYPE i.

    "! the row color: the field of the line type holding a classic color
    "! code Cxyz (cs_color) - the classic INFO_FIELDNAME. The field is not
    "! shown; the row gets the color as highlight at its start
    METHODS set_color_field
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the color of a column - fixed (cs_color) or per row out of the field
    "! of the line type holding the code: the classic EMPHASIZE and the
    "! cell colors of CTAB_FNAME. The text is shown in the color
    METHODS set_column_color
      IMPORTING
        name          TYPE clike
        color         TYPE clike OPTIONAL
        field         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the UI5 highlight / value state of a classic color code - None when
    "! it is none
    CLASS-METHODS color_state
      IMPORTING
        code          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! filter the rows by the multiple selection rows of column name -
    "! initial rows remove the filter of the column. The filter keeps the
    "! table as it is: filter_index( ) names the rows that pass, the report
    "! runtime shows them only. check_filter( ) tells whether the rows fit
    "! the type of the column
    METHODS set_filter
      IMPORTING
        name          TYPE clike
        rows          TYPE z2ui5_cl_cgui_range=>ty_t_row
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS get_filter
      RETURNING
        VALUE(result) TYPE ty_t_filter.

    "! remove the filter of column name - of all columns without name
    METHODS clear_filter
      IMPORTING
        name TYPE clike OPTIONAL.

    "! empty when rows fit the type of column name of tab, otherwise the
    "! line that does not
    METHODS check_filter
      IMPORTING
        name          TYPE clike
        rows          TYPE z2ui5_cl_cgui_range=>ty_t_row
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.

    "! the numbers of the rows of tab that pass the filters, the search
    "! and (paged) the filter of the column menus - all rows without filter
    METHODS filter_index
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_index.

    "! the filter button of the toolbar - on by default
    METHODS set_filter_change
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! a line of the header above the grid, also on the printout - the
    "! classic TOP_OF_LIST of CL_SALV_TABLE. Without label it is a heading
    METHODS add_header
      IMPORTING
        label         TYPE clike OPTIONAL
        value         TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS get_header
      RETURNING
        VALUE(result) TYPE ty_t_header.

    METHODS clear_header.

    "! the tooltip of the column header
    METHODS set_column_tooltip
      IMPORTING
        name          TYPE clike
        text          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! a key column - the classic KEY: bold header, the leading key columns
    "! stay fixed when the grid scrolls sideways
    METHODS set_column_key
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! a technical column - the classic TECHNICAL: never shown, not in the
    "! layout, the export or the printout
    METHODS set_column_technical
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! zero is shown as an empty cell - the classic NO_ZERO
    METHODS set_column_no_zero
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! a quantity whose unit is in the column unit_field - the classic
    "! QFIELDNAME
    METHODS set_column_quantity
      IMPORTING
        name          TYPE clike
        unit_field    TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the alignment of the column - cs_align
    METHODS set_column_alignment
      IMPORTING
        name          TYPE clike
        align         TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the aggregation of the column - cs_aggregation; sum is
    "! set_column_sum( )
    METHODS set_column_aggregation
      IMPORTING
        name          TYPE clike
        aggregation   TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the cell type - cs_cell_type: a checkbox that can be clicked, a
    "! button (both raise cs_event-hotspot) or a dropdown in edit mode
    METHODS set_column_cell_type
      IMPORTING
        name          TYPE clike
        type          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the values of a dropdown column - the classic DROP_DOWN_HANDLE
    METHODS set_column_dropdown
      IMPORTING
        name          TYPE clike
        values        TYPE ty_t_value
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! F4 in the cells of an editable column - the classic F4AVAILABL /
    "! REGISTER_F4_FOR_FIELDS: raises cs_event-f4, get_hotspot_by_event( )
    "! returns row and column. The report runtime asks
    "! at_alv_value_request( ) - by default the value help of the DDIC
    METHODS set_column_f4
      IMPORTING
        name          TYPE clike
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the field of the line type that tells per row whether its cells
    "! can be edited - the classic style per cell, by row. Not shown
    METHODS set_edit_field
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the columns from the left that stay when the grid scrolls sideways
    METHODS set_fixed_columns
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the classic field catalog - SLIS_T_FIELDCAT_ALV of REUSE_ALV_* or
    "! LVC_T_FCAT of the LVC functions and CL_GUI_ALV_GRID, read by the names
    "! of its fields: texts, NO_OUT, TECH, DO_SUM, HOTSPOT, KEY, EDIT,
    "! OUTPUTLEN, COL_POS, ICON, CFIELDNAME, QFIELDNAME, NO_ZERO, JUST, TOOLTIP
    METHODS set_fieldcat
      IMPORTING
        fieldcat      TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the classic layout - SLIS_LAYOUT_ALV or LVC_S_LAYO: ZEBRA,
    "! COLWIDTH_OPTIMIZE / CWIDTH_OPT, BOX_FIELDNAME / BOX_FNAME, EDIT,
    "! INFO_FIELDNAME / INFO_FNAME, GRID_TITLE, SEL_MODE
    METHODS set_layout_classic
      IMPORTING
        layout        TYPE any
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the classic sort - SLIS_T_SORTINFO_ALV or LVC_T_SORT: FIELDNAME, UP,
    "! DOWN, SUBTOT
    METHODS set_sort_classic
      IMPORTING
        sort          TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! rows striped - on by default, the classic ZEBRA
    METHODS set_striped
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the chart button of the toolbar - a bar chart of the rows shown, a
    "! column as the categories, a numeric one summed as the values; on by
    "! default
    METHODS set_chart
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the chart of the rows of tab in a dialog box - the columns as the
    "! user picked them last, else the first text and the first number
    "! a Select of the number columns for one more series of the chart -
    "! its first item is none
    METHODS chart_value_select
      IMPORTING
        node    TYPE REF TO z2ui5_cl_ui5_view_builder
        comps   TYPE z2ui5_cl_cgui_context=>ty_t_comp
        which   TYPE string
        current TYPE string
        client  TYPE REF TO z2ui5_if_client.

    METHODS chart_popup
      IMPORTING
        client TYPE REF TO z2ui5_if_client
        tab    TYPE STANDARD TABLE.

    "! the details button of the toolbar - the fields of the row selected
    "! in a dialog box; on by default with a selection column
    METHODS set_details
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the search field of the toolbar - on by default. It finds the rows
    "! holding the text in one of their columns shown, like a filter
    METHODS set_search_field
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS set_search
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS get_search
      RETURNING
        VALUE(result) TYPE string.

    "! a filter, a search or (paged) the filter of a column menu is set -
    "! not all rows are shown
    METHODS is_filtered
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! a line below the grid, also on the printout - the classic
    "! END_OF_LIST. Without label it is a heading
    METHODS add_footer
      IMPORTING
        label         TYPE clike OPTIONAL
        value         TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS get_footer
      RETURNING
        VALUE(result) TYPE ty_t_header.

    "! a selection column - single or multiple
    METHODS has_selection
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! select rows - the classic SET_SELECTED_ROWS; the others are deselected
    METHODS set_selected_rows
      IMPORTING
        rows TYPE ty_t_row
      CHANGING
        tab  TYPE STANDARD TABLE.

    "! single selection: one row stays selected - the one selected last
    METHODS single_normalize
      CHANGING
        tab TYPE STANDARD TABLE.

    "! the aggregates of the columns - total, average, minimum, maximum and
    "! count over the rows of tab, per currency or unit of a column that
    "! has one (set_column_currency( ), set_column_quantity( ))
    METHODS get_aggregates
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_aggregate.

    "! the fields of row of tab in a dialog box - the classic details
    METHODS details_popup
      IMPORTING
        client TYPE REF TO z2ui5_if_client
        tab    TYPE STANDARD TABLE
        row    TYPE i.

    "! the layout button of the toolbar - on by default
    METHODS set_layout_change
      IMPORTING
        val           TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS get_layout_change
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! every column of tab with its layout, in the order shown
    METHODS get_layout
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_layout.

    "! take over a layout - the columns not in it keep their settings
    METHODS set_layout
      IMPORTING
        layout        TYPE ty_t_layout
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the subtotals of the summed columns per group of the subtotal
    "! columns, in the order of the sorting - per currency or unit too
    METHODS get_subtotals
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_subtotal.

    "! the functions added to a toolbar - a button each, its name the event
    "! of the press
    CLASS-METHODS render_functions
      IMPORTING
        bar       TYPE REF TO z2ui5_cl_ui5_view_builder
        client    TYPE REF TO z2ui5_if_client
        functions TYPE ty_t_function.

    "! a type kind of a number - an integer, packed, float or decfloat
    CLASS-METHODS is_numeric
      IMPORTING
        type_kind     TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the visible columns of tab as Excel file (Office Open XML), every
    "! value in its own cell type - see z2ui5_cl_cgui_xlsx
    METHODS to_xlsx
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE xstring.

    "! does the line type of tab have the box field
    METHODS has_box_field
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the indices (1-based) of the rows whose box field is set
    METHODS get_selected_rows
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_row.

    "! set or clear the box field of every row
    METHODS select_all
      IMPORTING
        val TYPE abap_bool DEFAULT abap_true
      CHANGING
        tab TYPE STANDARD TABLE.

    "! the visible columns of tab as CSV, headed by their texts - dates,
    "! times and numbers in the user's format
    METHODS to_csv
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.

    "! the visible columns of tab as text lines with fixed widths - the
    "! printout of the grid, sorted as shown, totals in the last line
    METHODS to_text
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string_table.

    "! download tab as CSV file - or as Excel file with cs_format-xlsx,
    "! CSV when that cannot be built
    METHODS export
      IMPORTING
        client TYPE REF TO z2ui5_if_client
        tab    TYPE STANDARD TABLE
        format TYPE clike DEFAULT cs_format-csv.

    "! answer the events of the grid's own toolbar - select all, deselect
    "! all and export. abap_true when the event was one of them
    METHODS handle_event
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      CHANGING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! append the grid to node, a container of an existing view whose
    "! default namespace is sap.m; sums, a table like tab, holds the rows
    "! the totals and subtotals add up where tab holds only some of them
    "! (the first rows of a paged grid) - tab without it
    METHODS render
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        tab    TYPE STANDARD TABLE
        total  TYPE i DEFAULT -1
        all    TYPE i DEFAULT -1
        sums   TYPE REF TO data OPTIONAL.

    "! the grid as a complete view
    METHODS stringify
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.

    TYPES:
      "! a column of the grid for the filter popup - character types, the
      "! popup heads its columns with their names
      BEGIN OF ty_s_filter_col,
        column TYPE c LENGTH 30,
        text   TYPE c LENGTH 60,
        filter TYPE c LENGTH 60,
      END OF ty_s_filter_col.
    TYPES ty_t_filter_col TYPE STANDARD TABLE OF ty_s_filter_col WITH DEFAULT KEY.

    "! an event of the grid the report runtime handles - the toolbar, the
    "! selection, the filter, the paging, F4 of a cell
    CLASS-METHODS is_grid_event
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! a copy of source with the box field - the selection of old, the
    "! previous copy, is kept as long as the table keeps its number of rows
    METHODS box_copy
      IMPORTING
        source        TYPE REF TO data
        old           TYPE REF TO data OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the input of an editable grid shown as copy (box) back into source,
    "! row by row - nothing when the tables differ in their number of rows
    METHODS box_write_back
      IMPORTING
        source TYPE REF TO data
        box    TYPE REF TO data.

    "! the rows of source that pass the filter, as a copy - shown is the
    "! table the grid shows, with the rows of source one to one
    METHODS filtered_copy
      IMPORTING
        source        TYPE REF TO data
        shown         TYPE REF TO data
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the rows the grid shows (page) - filtered or paged - back into the
    "! rows of full they are cut from; index names per row of page the row
    "! of full
    METHODS page_write_back
      IMPORTING
        full  TYPE REF TO data
        page  TYPE REF TO data
        index TYPE ty_t_index.

    "! select all or deselect all on a filtered grid - the rows that pass,
    "! as the classic ALV does
    METHODS select_filtered
      IMPORTING
        selected TYPE abap_bool
      CHANGING
        tab      TYPE STANDARD TABLE.

    "! the columns of the grid for the filter popup, each with the filter
    "! set on it as text
    METHODS filter_columns
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_filter_col.

    "! the multiple selection for the filter of column name - an input, or a
    "! date or time picker by the type of the column
    METHODS filter_setting
      IMPORTING
        tab           TYPE STANDARD TABLE
        name          TYPE string
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_range=>ty_s_setting.

    "! a request of the paged grid (cs_event-rows): a SORT or a FILTER of a
    "! column menu is kept - the order window_order( ) gives from now on, as
    "! long as the layout keeps its sort
    METHODS window_request
      IMPORTING
        request TYPE z2ui5_if_client=>ty_s_window_request.

    "! the rows of tab the paged grid shows, in its order: those the filter
    "! of the grid, the search and the filter of a column menu let through,
    "! sorted as a column menu asked or else as the layout sorts
    METHODS window_order
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_index.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the settings travel in the app's draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA mv_title          TYPE string.
    DATA mv_line_selection TYPE abap_bool.
    DATA mv_visible_rows   TYPE i.
    DATA mt_column         TYPE ty_t_column.
    DATA mt_function       TYPE ty_t_function.
    DATA mv_selection_mode TYPE string.
    DATA mv_box_field      TYPE string.
    DATA mv_no_export      TYPE abap_bool.
    DATA mv_separator      TYPE string VALUE `;`.
    DATA mv_no_optimize    TYPE abap_bool.
    DATA mv_edit           TYPE abap_bool.
    DATA mv_no_layout      TYPE abap_bool.
    DATA mv_page_size      TYPE i.
    DATA mv_page           TYPE i VALUE 1.
    DATA mv_color_field    TYPE string.
    DATA mt_filter         TYPE ty_t_filter.
    DATA mv_no_filter      TYPE abap_bool.
    DATA mt_header         TYPE ty_t_header.
    DATA mt_footer         TYPE ty_t_header.
    DATA mv_edit_field     TYPE string.
    DATA mv_fixed_columns  TYPE i.
    DATA mv_no_stripes     TYPE abap_bool.
    DATA mv_no_details     TYPE abap_bool.
    DATA mv_no_chart       TYPE abap_bool.
    DATA mv_chart_category TYPE string.
    DATA mv_chart_value    TYPE string.
    " the second and third series, and the kind of the chart
    DATA mv_chart_value2   TYPE string.
    DATA mv_chart_value3   TYPE string.
    DATA mv_chart_kind     TYPE string.
    DATA mv_no_search      TYPE abap_bool.
    DATA mv_search         TYPE string.
    DATA mv_single_row     TYPE i.
    TYPES temp1_6defa0496a TYPE STANDARD TABLE OF ty_s_value WITH DEFAULT KEY.
DATA mt_dropdown       TYPE temp1_6defa0496a.
    DATA mt_dropdown_col   TYPE string_table.
    " the sort and the filter a column menu of the paged grid asked for, and
    " the sort of the layout then
    DATA mt_window_sort    TYPE z2ui5_if_client=>ty_t_bind_tab_sort.
    DATA mt_window_filter  TYPE z2ui5_if_client=>ty_t_bind_tab_filter.
    DATA mt_window_layout  TYPE abap_sortorder_tab.

  PRIVATE SECTION.

    " a field of a classic structure by its name - empty when it has none
    CLASS-METHODS classic_value
      IMPORTING
        row           TYPE any
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    TYPES:
      BEGIN OF ty_s_ordered,
        position TYPE i,
        seq      TYPE i,
        comp     TYPE z2ui5_cl_cgui_context=>ty_s_comp,
      END OF ty_s_ordered.
    TYPES ty_t_ordered TYPE STANDARD TABLE OF ty_s_ordered WITH DEFAULT KEY.

    "! the range of column name of tab typed like the column - with pattern
    "! a range of strings, for CP / NP on the text of the cell - filled with
    "! rows; not bound when the column is not there or not elementary
    METHODS filter_range
      IMPORTING
        name          TYPE clike
        rows          TYPE z2ui5_cl_cgui_range=>ty_t_row
        tab           TYPE STANDARD TABLE
        pattern       TYPE abap_bool DEFAULT abap_false
      EXPORTING
        error         TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the lines of a filter apart: typed - checked against the cell, and
    "! pattern - CP / NP against its text
    METHODS filter_split
      IMPORTING
        rows    TYPE z2ui5_cl_cgui_range=>ty_t_row
      EXPORTING
        typed   TYPE z2ui5_cl_cgui_range=>ty_t_row
        pattern TYPE z2ui5_cl_cgui_range=>ty_t_row.

    "! whether val matches one line of range - the target of a data ref,
    "! its lines signed I (filter_include( ))
    METHODS filter_match
      IMPORTING
        val           TYPE any
        range         TYPE REF TO data
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! every line of range signed I - an E line of a filter is asked as I,
    "! the exclusion is filter_index( )'s
    CLASS-METHODS filter_include
      IMPORTING
        range TYPE REF TO data.

    "! the expression binding of the color code in field
    CLASS-METHODS color_binding
      IMPORTING
        field         TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_header
      IMPORTING
        node  TYPE REF TO z2ui5_cl_ui5_view_builder
        items TYPE ty_t_header OPTIONAL.

    "! the values of dropdown column name
    METHODS dropdown_values
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_value.

    "! the binding of editable from the edit field - empty without one
    METHODS edit_binding
      RETURNING
        VALUE(result) TYPE string.

    "! a text for an expression binding: quotes and markup escaped
    CLASS-METHODS expr_escape
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! a column of the line type that is no data shown - box, color, edit
    "! field or technical
    METHODS column_skipped
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the sorter of the rows binding - empty when nothing is sorted
    METHODS sorter
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.

    "! the sort order - the columns with their direction
    METHODS sort_order
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE abap_sortorder_tab.

    "! the sort the layout sets - the columns with their direction, whether
    "! a table has them or not
    METHODS sort_layout
      RETURNING
        VALUE(result) TYPE abap_sortorder_tab.

    "! tab in the sort order of the columns
    METHODS sort_rows
      CHANGING
        tab TYPE STANDARD TABLE.

    "! the row numbers of tab in index in order - a merge sort, stable
    CLASS-METHODS index_sort
      IMPORTING
        tab   TYPE STANDARD TABLE
        order TYPE abap_sortorder_tab
      CHANGING
        index TYPE ty_t_index.

    "! the filter of a column menu as filters of the grid: a group of
    "! conditions on one column is its multiple selection
    METHODS window_filter
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_filter.

    "! is row a of tab before row b in order
    CLASS-METHODS rows_less
      IMPORTING
        tab           TYPE STANDARD TABLE
        order         TYPE abap_sortorder_tab
        a             TYPE i
        b             TYPE i
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS column_editable
      IMPORTING
        column        TYPE ty_s_column
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS render_edit
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        comp   TYPE z2ui5_cl_cgui_context=>ty_s_comp
        column TYPE ty_s_column.

    METHODS render_subtotals
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        tab  TYPE STANDARD TABLE.

    " the types of the cell formats, loaded with core:require on the grid
    CLASS-METHODS type_require
      RETURNING
        VALUE(result) TYPE string.

    METHODS column_get
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO ty_s_column.

    "! the columns shown, with their texts and settings
    METHODS columns_visible
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_context=>ty_t_comp.

    METHODS column_setting
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE ty_s_column.

    "! the column that holds the currency or the unit of column - empty
    "! when it has none or tab has no such column
    METHODS unit_column
      IMPORTING
        column        TYPE ty_s_column
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_toolbar
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        multi  TYPE abap_bool
        total  TYPE i
        all    TYPE i.

    METHODS render_columns
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        tab    TYPE STANDARD TABLE
        multi  TYPE abap_bool.

    METHODS render_template
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        comp   TYPE z2ui5_cl_cgui_context=>ty_s_comp
        column TYPE ty_s_column.

    METHODS render_sums
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        tab  TYPE STANDARD TABLE.

    "! the binding of a cell in the user's format
    METHODS cell_binding
      IMPORTING
        comp          TYPE z2ui5_cl_cgui_context=>ty_s_comp
        column        TYPE ty_s_column
      RETURNING
        VALUE(result) TYPE string.

    "! a width for the column that fits its label and content
    METHODS column_width
      IMPORTING
        comp          TYPE z2ui5_cl_cgui_context=>ty_s_comp
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE string.

    "! an aggregate as text - a count without decimals, an average with two
    CLASS-METHODS aggregate_text
      IMPORTING
        aggregate     TYPE ty_s_aggregate
      RETURNING
        VALUE(result) TYPE string.

    METHODS cell_to_text
      IMPORTING
        val           TYPE any
        comp          TYPE z2ui5_cl_cgui_context=>ty_s_comp
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS csv_escape
      IMPORTING
        val           TYPE string
        separator     TYPE string
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_alv IMPLEMENTATION.

  METHOD factory.

    CREATE OBJECT result.

  ENDMETHOD.

  METHOD get_row_by_event.

    result = row_by_path( client->get_event_arg( ) ).

  ENDMETHOD.

  METHOD get_hotspot_by_event.

    result-row    = row_by_path( client->get_event_arg( ) ).
    result-column = client->get_event_arg( 2 ).

  ENDMETHOD.

  METHOD row_by_path.

    DATA lt_path TYPE string_table.
    DATA lv_last LIKE LINE OF lt_path.
    FIELD-SYMBOLS <temp32> LIKE LINE OF lt_path.
    DATA temp33 LIKE sy-tabix.

    SPLIT val AT `/` INTO TABLE lt_path.
    IF lt_path IS INITIAL.
      RETURN.
    ENDIF.




    temp33 = sy-tabix.
    READ TABLE lt_path INDEX lines( lt_path ) ASSIGNING <temp32>.
    sy-tabix = temp33.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_last = <temp32>.
    IF lv_last IS INITIAL OR lv_last CN `0123456789`.
      RETURN.
    ENDIF.
    result = lv_last + 1.

  ENDMETHOD.

  METHOD set_title.

    mv_title = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_text.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->text = text.
    result = me.

  ENDMETHOD.

  METHOD set_column_hidden.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->hidden = hidden.
    result = me.

  ENDMETHOD.

  METHOD set_column_width.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->width = width.
    result = me.

  ENDMETHOD.

  METHOD set_column_icon.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->icon = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_hotspot.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->hotspot = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_currency.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->currency = to_upper( currency_field ).
    result = me.

  ENDMETHOD.

  METHOD set_column_sum.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->sum = val.
    result = me.

  ENDMETHOD.

  METHOD set_line_selection.

    mv_line_selection = val.
    result = me.

  ENDMETHOD.

  METHOD set_visible_rows.

    mv_visible_rows = val.
    result = me.

  ENDMETHOD.

  METHOD set_selection_mode.

    mv_selection_mode = to_upper( val ).
    mv_box_field = to_upper( box_field ).
    IF mv_box_field IS INITIAL.
      mv_box_field = cv_box_field.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD get_selection_mode.

    result = mv_selection_mode.
    IF result IS INITIAL.
      result = cs_selection_mode-none.
    ENDIF.

  ENDMETHOD.

  METHOD get_box_field.

    result = mv_box_field.
    IF result IS INITIAL.
      result = cv_box_field.
    ENDIF.

  ENDMETHOD.

  METHOD add_function.

    DATA temp165 TYPE z2ui5_cl_cgui_alv=>ty_s_function.
    CLEAR temp165.
    temp165-name = name.
    temp165-text = text.
    temp165-icon = icon.
    temp165-tooltip = tooltip.
    INSERT temp165 INTO TABLE mt_function.
    result = me.

  ENDMETHOD.

  METHOD set_export.

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( val = abap_false ).
    mv_no_export = temp1.
    mv_separator = separator.
    result = me.

  ENDMETHOD.

  METHOD set_optimize.

    DATA temp2 TYPE xsdboolean.
    temp2 = boolc( val = abap_false ).
    mv_no_optimize = temp2.
    result = me.

  ENDMETHOD.

  METHOD set_edit.

    mv_edit = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_edit.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    DATA temp3 TYPE xsdboolean.
    lr_column = column_get( name ).
    lr_column->edit = val.

    temp3 = boolc( val = abap_false ).
    lr_column->no_edit = temp3.
    result = me.

  ENDMETHOD.

  METHOD is_editable.

    DATA temp166 LIKE sy-subrc.
    DATA temp34 LIKE sy-subrc.
    DATA temp4 TYPE xsdboolean.
    READ TABLE mt_column WITH KEY edit = abap_true TRANSPORTING NO FIELDS.
    temp166 = sy-subrc.

    READ TABLE mt_column WITH KEY cell_type = cs_cell_type-checkbox_hotspot TRANSPORTING NO FIELDS.
    temp34 = sy-subrc.

    temp4 = boolc( mv_edit = abap_true OR temp166 = 0 OR temp34 = 0 ).
    result = temp4.

  ENDMETHOD.

  METHOD column_editable.
    DATA temp5 TYPE xsdboolean.

    IF column-icon = abap_true OR column-hotspot = abap_true OR column-no_edit = abap_true
        OR column-cell_type = cs_cell_type-button OR column-cell_type = cs_cell_type-checkbox_hotspot.
      RETURN.
    ENDIF.

    temp5 = boolc( column-edit = abap_true OR mv_edit = abap_true ).
    result = temp5.

  ENDMETHOD.

  METHOD set_sort.

    DATA lv_seq TYPE i.

    DATA ls_column LIKE LINE OF mt_column.
    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    DATA temp167 TYPE z2ui5_cl_cgui_alv=>ty_s_column-sort.
    LOOP AT mt_column INTO ls_column WHERE sort IS NOT INITIAL.
      lv_seq = nmax( val1 = lv_seq val2 = ls_column-sort_seq ).
    ENDLOOP.

    lr_column = column_get( name ).
    IF lr_column->sort IS INITIAL.
      lr_column->sort_seq = lv_seq + 1.
    ENDIF.

    IF descending = abap_true.
      temp167 = cs_sort-descending.
    ELSE.
      temp167 = cs_sort-ascending.
    ENDIF.
    lr_column->sort = temp167.
    lr_column->subtotal = subtotal.
    result = me.

  ENDMETHOD.

  METHOD set_column_position.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->position = position.
    result = me.

  ENDMETHOD.

  METHOD set_paging.

    mv_page_size = nmax( val1 = 0 val2 = page_size ).
    mv_page = 1.
    result = me.

  ENDMETHOD.

  METHOD get_page_size.

    result = mv_page_size.

  ENDMETHOD.

  METHOD get_page.

    result = nmax( val1 = 1 val2 = mv_page ).

  ENDMETHOD.

  METHOD get_page_offset.

    IF mv_page_size > 0.
      result = ( get_page( ) - 1 ) * mv_page_size.
    ENDIF.

  ENDMETHOD.

  METHOD page_turn.
    DATA lv_pages TYPE i.
    DATA lv_direction TYPE string.

    IF mv_page_size <= 0.
      RETURN.
    ENDIF.

    lv_pages = nmax( val1 = 1 val2 = ( lines + mv_page_size - 1 ) DIV mv_page_size ).

    lv_direction = to_upper( direction ).
    CASE lv_direction.
      WHEN cs_page-first.
        mv_page = 1.
      WHEN cs_page-previous.
        mv_page = nmax( val1 = 1 val2 = mv_page - 1 ).
      WHEN cs_page-next.
        mv_page = nmin( val1 = lv_pages val2 = mv_page + 1 ).
      WHEN cs_page-last.
        mv_page = lv_pages.
    ENDCASE.
    mv_page = nmin( val1 = lv_pages val2 = mv_page ).

  ENDMETHOD.

  METHOD set_column_tooltip.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->tooltip = text.
    result = me.

  ENDMETHOD.

  METHOD set_column_key.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->key = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_technical.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->technical = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_no_zero.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->no_zero = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_quantity.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->quantity = to_upper( unit_field ).
    result = me.

  ENDMETHOD.

  METHOD set_column_alignment.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->align = align.
    result = me.

  ENDMETHOD.

  METHOD set_column_aggregation.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    DATA temp6 TYPE xsdboolean.
    lr_column = column_get( name ).
    lr_column->aggregation = to_upper( aggregation ).
    " totals and subtotals stay the sum

    temp6 = boolc( lr_column->aggregation = cs_aggregation-sum ).
    lr_column->sum = temp6.
    result = me.

  ENDMETHOD.

  METHOD set_column_cell_type.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->cell_type = to_upper( type ).
    result = me.

  ENDMETHOD.

  METHOD set_column_dropdown.

    DATA lv_name TYPE string.
    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    DATA ls_value LIKE LINE OF values.
      DATA temp168 TYPE z2ui5_cl_cgui_alv=>ty_s_value.
    DATA temp169 LIKE sy-subrc.
    lv_name = to_upper( name ).

    lr_column = column_get( lv_name ).
    lr_column->cell_type = cs_cell_type-dropdown.
    " the values per column: name in mt_dropdown_col, values in mt_dropdown
    " with the column as prefix of the key
    DELETE mt_dropdown WHERE key CP |{ lv_name }~*|.

    LOOP AT values INTO ls_value.

      CLEAR temp168.
      temp168-key = |{ lv_name }~{ ls_value-key }|.
      temp168-text = ls_value-text.
      INSERT temp168 INTO TABLE mt_dropdown.
    ENDLOOP.

    READ TABLE mt_dropdown_col WITH KEY table_line = lv_name TRANSPORTING NO FIELDS.
    temp169 = sy-subrc.
    IF NOT temp169 = 0.
      INSERT lv_name INTO TABLE mt_dropdown_col.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD dropdown_values.

    DATA lv_prefix TYPE string.
    DATA lv_len TYPE i.
    DATA ls_value LIKE LINE OF mt_dropdown.
        DATA temp170 TYPE z2ui5_cl_cgui_alv=>ty_s_value.
    lv_prefix = |{ name }~|.

    lv_len = strlen( lv_prefix ).

    LOOP AT mt_dropdown INTO ls_value.
      IF strlen( ls_value-key ) >= lv_len AND substring( val = ls_value-key len = lv_len ) = lv_prefix.

        CLEAR temp170.
        temp170-key = substring( val = ls_value-key off = lv_len ).
        temp170-text = ls_value-text.
        INSERT temp170 INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_column_f4.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->f4 = val.
    result = me.

  ENDMETHOD.

  METHOD set_edit_field.

    mv_edit_field = to_upper( name ).
    result = me.

  ENDMETHOD.

  METHOD edit_binding.
      DATA lv_path TYPE string.

    IF mv_edit_field IS NOT INITIAL.

      lv_path = z2ui5_cl_ui5_view_builder=>component_path( mv_edit_field ).
      result = |\{= $\{{ lv_path }\} === true \|\| $\{{ lv_path }\} === 'X' \}|.
    ENDIF.

  ENDMETHOD.

  METHOD expr_escape.

    " a literal of the expression binding - the XML escapes are the
    " builder's, it writes every attribute value escaped
    result = replace( val = val sub = `\` with = `\\` occ = 0 ).
    result = replace( val = result sub = `'` with = `\'` occ = 0 ).
    result = replace( val = result sub = `{` with = `(` occ = 0 ).
    result = replace( val = result sub = `}` with = `)` occ = 0 ).

  ENDMETHOD.

  METHOD set_fixed_columns.

    mv_fixed_columns = val.
    result = me.

  ENDMETHOD.

  METHOD set_fieldcat.

    FIELD-SYMBOLS <fcat> TYPE ANY.
      DATA lv_name TYPE string.
      DATA temp35 TYPE string_table.
      DATA temp171 LIKE temp35.
      DATA lv_text_field LIKE LINE OF temp171.
        DATA lv_text TYPE string.
      DATA temp7 TYPE xsdboolean.
      DATA temp8 TYPE xsdboolean.
      DATA temp9 TYPE xsdboolean.
      DATA temp10 TYPE xsdboolean.
      DATA temp11 TYPE xsdboolean.
      DATA temp12 TYPE xsdboolean.
      DATA temp13 TYPE xsdboolean.
      DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp14 TYPE xsdboolean.
      DATA lv_length TYPE string.
      DATA temp172 TYPE i.
        DATA temp173 TYPE i.
      DATA lv_position TYPE string.
      DATA temp174 TYPE i.
        DATA temp175 TYPE i.
      DATA lv_field TYPE string.
      DATA lv_just TYPE string.
      DATA lv_tooltip TYPE string.
    LOOP AT fieldcat ASSIGNING <fcat>.

      lv_name = to_upper( classic_value( row  = <fcat>
                                               name = `FIELDNAME` ) ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      " the text the report gave the column first - COLTEXT of the LVC
      " catalog, SELTEXT_* of the SLIS one -, then the texts of the DDIC,
      " the longest first

      CLEAR temp35.
      INSERT `COLTEXT` INTO TABLE temp35.
      INSERT `SELTEXT_L` INTO TABLE temp35.
      INSERT `SELTEXT_M` INTO TABLE temp35.
      INSERT `SELTEXT_S` INTO TABLE temp35.
      INSERT `SCRTEXT_L` INTO TABLE temp35.
      INSERT `REPTEXT` INTO TABLE temp35.
      INSERT `REPTEXT_DDIC` INTO TABLE temp35.
      INSERT `SCRTEXT_M` INTO TABLE temp35.
      INSERT `SCRTEXT_S` INTO TABLE temp35.

      temp171 = temp35.

      LOOP AT temp171 INTO lv_text_field.

        lv_text = classic_value( row  = <fcat>
                                       name = lv_text_field ).
        IF lv_text IS NOT INITIAL.
          set_column_text( name = lv_name
                           text = lv_text ).
          EXIT.
        ENDIF.
      ENDLOOP.

      " the flags as the field catalog has them - a catalog set again on
      " the grid that shows switches them off as well

      temp7 = boolc( classic_value( row = <fcat> name = `NO_OUT` ) = abap_true ).
      set_column_hidden( name   = lv_name
                         hidden = temp7 ).

      temp8 = boolc( classic_value( row = <fcat> name = `TECH` ) = abap_true ).
      set_column_technical( name = lv_name
                            val  = temp8 ).

      temp9 = boolc( classic_value( row = <fcat> name = `DO_SUM` ) = abap_true ).
      set_column_sum( name = lv_name
                      val  = temp9 ).

      temp10 = boolc( classic_value( row = <fcat> name = `HOTSPOT` ) = abap_true ).
      set_column_hotspot( name = lv_name
                          val  = temp10 ).

      temp11 = boolc( classic_value( row = <fcat> name = `KEY` ) = abap_true ).
      set_column_key( name = lv_name
                      val  = temp11 ).

      temp12 = boolc( classic_value( row = <fcat> name = `ICON` ) = abap_true ).
      set_column_icon( name = lv_name
                       val  = temp12 ).

      temp13 = boolc( classic_value( row = <fcat> name = `NO_ZERO` ) = abap_true ).
      set_column_no_zero( name = lv_name
                          val  = temp13 ).
      " EDIT makes this column an input column - not the whole grid, and
      " without it the column still follows the EDIT of the layout

      lr_column = column_get( lv_name ).

      temp14 = boolc( classic_value( row = <fcat> name = `EDIT` ) = abap_true ).
      lr_column->edit = temp14.


      lv_length = classic_value( row  = <fcat>
                                       name = `OUTPUTLEN` ).

      temp172 = lv_length.
      IF lv_length CO ` 0123456789` AND lv_length IS NOT INITIAL AND temp172 > 0.
        " a character is about 0.6 rem wide

        temp173 = lv_length.
        set_column_width( name  = lv_name
                          width = |{ temp173 * 6 / 10 + 1 }rem| ).
      ENDIF.

      lv_position = classic_value( row  = <fcat>
                                         name = `COL_POS` ).

      temp174 = lv_position.
      IF lv_position CO ` 0123456789` AND lv_position IS NOT INITIAL AND temp174 > 0.

        temp175 = lv_position.
        set_column_position( name     = lv_name
                             position = temp175 ).
      ENDIF.


      lv_field = to_upper( classic_value( row  = <fcat>
                                                name = `CFIELDNAME` ) ).
      IF lv_field IS NOT INITIAL.
        set_column_currency( name           = lv_name
                             currency_field = lv_field ).
      ENDIF.
      lv_field = to_upper( classic_value( row  = <fcat>
                                          name = `QFIELDNAME` ) ).
      IF lv_field IS NOT INITIAL.
        set_column_quantity( name       = lv_name
                             unit_field = lv_field ).
      ENDIF.


      lv_just = to_upper( classic_value( row  = <fcat>
                                               name = `JUST` ) ).
      CASE lv_just.

        WHEN `R`.
          set_column_alignment( name  = lv_name
                                align = cs_align-right ).
        WHEN `C`.
          set_column_alignment( name  = lv_name
                                align = cs_align-center ).
        WHEN `L`.
          set_column_alignment( name  = lv_name
                                align = cs_align-left ).
      ENDCASE.


      lv_tooltip = classic_value( row  = <fcat>
                                        name = `TOOLTIP` ).
      IF lv_tooltip IS NOT INITIAL.
        set_column_tooltip( name = lv_name
                            text = lv_tooltip ).
      ENDIF.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD set_layout_classic.

    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lt_comp TYPE abap_component_view_tab.
    DATA temp176 LIKE sy-subrc.
      DATA temp15 TYPE xsdboolean.
    DATA lv_box TYPE string.
    DATA lv_info TYPE string.
    DATA lv_title TYPE string.

    TRY.
        lo_struct ?= cl_abap_typedescr=>describe_by_data( layout ).
      CATCH cx_sy_move_cast_error.
        result = me.
        RETURN.
    ENDTRY.
    " ZEBRA off is the classic default - the grid follows it

    lt_comp = lo_struct->get_included_view( ).

    READ TABLE lt_comp WITH KEY name = `ZEBRA` TRANSPORTING NO FIELDS.
    temp176 = sy-subrc.
    IF temp176 = 0.

      temp15 = boolc( classic_value( row = layout name = `ZEBRA` ) = abap_true ).
      set_striped( temp15 ).
    ENDIF.
    IF classic_value( row = layout name = `COLWIDTH_OPTIMIZE` ) = abap_true
        OR classic_value( row = layout name = `CWIDTH_OPT` ) = abap_true.
      set_optimize( ).
    ENDIF.
    IF classic_value( row = layout name = `EDIT` ) = abap_true.
      set_edit( ).
    ENDIF.


    lv_box = to_upper( classic_value( row = layout name = `BOX_FIELDNAME` ) ).
    IF lv_box IS INITIAL.
      lv_box = to_upper( classic_value( row = layout name = `BOX_FNAME` ) ).
    ENDIF.
    IF lv_box IS NOT INITIAL.
      set_selection_mode( val       = cs_selection_mode-multiple
                          box_field = lv_box ).
    ELSE.
      " SEL_MODE of LVC: A, D multiple - B single
      CASE classic_value( row = layout name = `SEL_MODE` ).
        WHEN `A` OR `C` OR `D`.
          set_selection_mode( val = cs_selection_mode-multiple ).
        WHEN `B`.
          set_selection_mode( val = cs_selection_mode-single ).
      ENDCASE.
    ENDIF.


    lv_info = to_upper( classic_value( row = layout name = `INFO_FIELDNAME` ) ).
    IF lv_info IS INITIAL.
      lv_info = to_upper( classic_value( row = layout name = `INFO_FNAME` ) ).
    ENDIF.
    IF lv_info IS NOT INITIAL.
      set_color_field( lv_info ).
    ENDIF.


    lv_title = classic_value( row = layout name = `GRID_TITLE` ).
    IF lv_title IS NOT INITIAL.
      set_title( lv_title ).
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD set_sort_classic.

    " the sort table is the whole sort - one set again replaces the last
    DATA temp177 LIKE LINE OF mt_column.
    DATA lr_column LIKE REF TO temp177.
    FIELD-SYMBOLS <sort> TYPE ANY.
      DATA lv_name TYPE string.
      DATA temp16 TYPE xsdboolean.
      DATA temp1 TYPE xsdboolean.
    LOOP AT mt_column REFERENCE INTO lr_column WHERE sort IS NOT INITIAL OR subtotal = abap_true.
      CLEAR: lr_column->sort, lr_column->sort_seq, lr_column->subtotal.
    ENDLOOP.

    LOOP AT sort ASSIGNING <sort>.

      lv_name = to_upper( classic_value( row  = <sort>
                                               name = `FIELDNAME` ) ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      temp16 = boolc( classic_value( row = <sort> name = `DOWN` ) = abap_true ).

      temp1 = boolc( classic_value( row = <sort> name = `SUBTOT` ) = abap_true ).
      set_sort( name       = lv_name
                descending = temp16
                subtotal   = temp1 ).
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD classic_value.

    FIELD-SYMBOLS <value> TYPE any.
      DATA temp178 TYPE string.

    ASSIGN COMPONENT name OF STRUCTURE row TO <value>.
    IF sy-subrc = 0 AND <value> IS NOT INITIAL.

      temp178 = <value>.
      result = condense( temp178 ).
    ENDIF.

  ENDMETHOD.

  METHOD set_striped.

    DATA temp17 TYPE xsdboolean.
    temp17 = boolc( val = abap_false ).
    mv_no_stripes = temp17.
    result = me.

  ENDMETHOD.

  METHOD set_chart.

    DATA temp18 TYPE xsdboolean.
    temp18 = boolc( val = abap_false ).
    mv_no_chart = temp18.
    result = me.

  ENDMETHOD.

  METHOD chart_value_select.

    DATA temp179 TYPE string_table.
    DATA lo_select TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp181 TYPE string.
    DATA ls_comp LIKE LINE OF comps.
    CLEAR temp179.
    INSERT which INTO TABLE temp179.
    INSERT `${$source>/selectedKey}` INTO TABLE temp179.

    lo_select = node->ele( `Select`
        )->a( n = `selectedKey` t = current
        )->a( n = `change`      v = client->_event( val   = cs_event-chart
                                                    t_arg = temp179 )
        )->a( n = `class`       v = `sapUiTinyMarginBegin` ).

    temp181 = '(none)'(028).
    lo_select->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` t = temp181 ).

    LOOP AT comps INTO ls_comp.
      IF is_numeric( ls_comp-type_kind ) = abap_true.
        lo_select->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_comp-name
            )->a( n = `text` t = ls_comp-label ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD chart_popup.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA temp182 LIKE sy-subrc.
    DATA temp183 LIKE sy-subrc.
      DATA ls_comp LIKE LINE OF lt_comp.
    DATA temp184 LIKE sy-subrc.
    DATA temp185 LIKE sy-subrc.
    DATA lt_value TYPE string_table.
    DATA lt_name TYPE string_table.
      DATA temp186 LIKE LINE OF lt_name.
      DATA temp187 TYPE string_table.
      DATA lt_series LIKE temp187.
      DATA lv_series LIKE LINE OF lt_series.
        DATA temp189 LIKE sy-subrc.
        DATA temp190 LIKE sy-subrc.
    DATA lt_point TYPE z2ui5_cl_cgui_chart=>ty_t_point.
    DATA temp191 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_pick TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp192 TYPE string_table.
    DATA lo_cat TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp194 TYPE string_table.
    DATA lo_val TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp196 TYPE string.
    DATA temp197 TYPE string_table.
    DATA lo_kind TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp199 TYPE string.
    DATA temp200 TYPE string.
    DATA temp201 TYPE string.
    DATA temp202 TYPE string.
    DATA lv_svg TYPE string.
    DATA temp203 TYPE string.
    lt_comp = columns_visible( tab ).
    " the columns picked - else the first text and the first number; no
    " number: the rows are counted
    " the first text column with more than one value - a column of one
    " value is one bar


    temp183 = sy-subrc.
    READ TABLE lt_comp WITH KEY name = mv_chart_category TRANSPORTING NO FIELDS.
    temp182 = sy-subrc.
    sy-subrc = temp183.
    IF NOT temp182 = 0.
      CLEAR mv_chart_category.

      LOOP AT lt_comp INTO ls_comp WHERE boolean = abap_false.
        IF is_numeric( ls_comp-type_kind ) = abap_true.
          CONTINUE.
        ENDIF.
        IF mv_chart_category IS INITIAL.
          mv_chart_category = ls_comp-name.
        ENDIF.
        IF lines( z2ui5_cl_cgui_chart=>bars( tab      = tab
                                             category = ls_comp-name
                                             value    = `` ) ) > 1.
          mv_chart_category = ls_comp-name.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
    " %COUNT: the rows counted


    temp185 = sy-subrc.
    READ TABLE lt_comp WITH KEY name = mv_chart_value TRANSPORTING NO FIELDS.
    temp184 = sy-subrc.
    sy-subrc = temp185.
    IF mv_chart_value IS NOT INITIAL AND mv_chart_value <> `%COUNT` AND NOT temp184 = 0.
      CLEAR mv_chart_value.
    ENDIF.
    IF mv_chart_value IS INITIAL.
      mv_chart_value = `%COUNT`.
      LOOP AT lt_comp INTO ls_comp.
        IF is_numeric( ls_comp-type_kind ) = abap_true.
          mv_chart_value = ls_comp-name.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " the series: the value column and up to two more - the rows counted
    " are one series of their own


    IF mv_chart_value = `%COUNT`.

      temp186 = 'Number of rows'(023).
      INSERT temp186 INTO TABLE lt_name.
    ELSE.

      CLEAR temp187.
      INSERT mv_chart_value INTO TABLE temp187.
      INSERT mv_chart_value2 INTO TABLE temp187.
      INSERT mv_chart_value3 INTO TABLE temp187.

      lt_series = temp187.

      LOOP AT lt_series INTO lv_series.
        READ TABLE lt_comp INTO ls_comp WITH KEY name = lv_series.


        temp190 = sy-subrc.
        READ TABLE lt_value WITH KEY table_line = lv_series TRANSPORTING NO FIELDS.
        temp189 = sy-subrc.
        sy-subrc = temp190.
        IF sy-subrc = 0 AND is_numeric( ls_comp-type_kind ) = abap_true AND NOT temp189 = 0.
          INSERT lv_series INTO TABLE lt_value.
          INSERT ls_comp-label INTO TABLE lt_name.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF mv_chart_kind IS INITIAL.
      mv_chart_kind = z2ui5_cl_cgui_chart=>cs_kind-bar.
    ENDIF.

    lt_point = z2ui5_cl_cgui_chart=>series( tab      = tab
                                                  category = mv_chart_category
                                                  values   = lt_value
                                                  other    = 'Other'(020) ).


    IF mv_title IS NOT INITIAL.
      temp191 = mv_title.
    ELSE.
      temp191 = 'Chart'(019).
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp191
        )->a( n = `contentWidth` v = `44rem`
        )->a( n = `resizable`    b = abap_true ).

    lo_box = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " the two columns to pick - every change draws the chart anew

    lo_pick = lo_box->ele( `HBox`
        )->a( n = `wrap`       v = `Wrap`
        )->a( n = `alignItems` v = `Center` ).

    CLEAR temp192.
    INSERT `CATEGORY` INTO TABLE temp192.
    INSERT `${$source>/selectedKey}` INTO TABLE temp192.

    lo_cat = lo_pick->tag( `Label`
        )->a( n = `text`  t = |{ 'Categories'(021) }:|
        )->a( n = `class` v = `sapUiTinyMarginEnd`
        )->ele( `Select`
        )->a( n = `selectedKey` t = mv_chart_category
        )->a( n = `change`      v = client->_event( val   = cs_event-chart
                                                    t_arg = temp192 )
        )->a( n = `class`       v = `sapUiSmallMarginEnd` ).
    LOOP AT lt_comp INTO ls_comp.
      lo_cat->tag( n = `Item` ns = `core`
          )->a( n = `key`  t = ls_comp-name
          )->a( n = `text` t = ls_comp-label ).
    ENDLOOP.

    CLEAR temp194.
    INSERT `VALUE` INTO TABLE temp194.
    INSERT `${$source>/selectedKey}` INTO TABLE temp194.

    lo_val = lo_pick->tag( `Label`
        )->a( n = `text`  t = |{ 'Values'(022) }:|
        )->a( n = `class` v = `sapUiTinyMarginEnd`
        )->ele( `Select`
        )->a( n = `selectedKey` t = mv_chart_value
        )->a( n = `change`      v = client->_event( val   = cs_event-chart
                                                    t_arg = temp194 ) ).

    temp196 = 'Number of rows'(023).
    lo_val->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `%COUNT`
        )->a( n = `text` t = temp196 ).
    LOOP AT lt_comp INTO ls_comp.
      IF is_numeric( ls_comp-type_kind ) = abap_true.
        lo_val->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_comp-name
            )->a( n = `text` t = ls_comp-label ).
      ENDIF.
    ENDLOOP.

    " two more series beside the first - a pie draws the first only
    IF mv_chart_value <> `%COUNT`.
      chart_value_select( node    = lo_pick
                          comps   = lt_comp
                          which   = `VALUE2`
                          current = mv_chart_value2
                          client  = client ).
      chart_value_select( node    = lo_pick
                          comps   = lt_comp
                          which   = `VALUE3`
                          current = mv_chart_value3
                          client  = client ).
    ENDIF.

    " the kind of the chart

    CLEAR temp197.
    INSERT `KIND` INTO TABLE temp197.
    INSERT `${$source>/selectedKey}` INTO TABLE temp197.

    lo_kind = lo_pick->tag( `Label`
        )->a( n = `text`  t = |{ 'Chart'(019) }:|
        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiTinyMarginEnd`
        )->ele( `SegmentedButton`
        )->a( n = `selectedKey`     t = mv_chart_kind
        )->a( n = `selectionChange` v = client->_event( val   = cs_event-chart
                                                        t_arg = temp197 )
        )->ele( `items` ).

    temp199 = 'Bars'(024).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-bar
        )->a( n = `icon`    v = `sap-icon://horizontal-bar-chart`
        )->a( n = `tooltip` t = temp199 ).

    temp200 = 'Columns'(025).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-column
        )->a( n = `icon`    v = `sap-icon://vertical-bar-chart`
        )->a( n = `tooltip` t = temp200 ).

    temp201 = 'Lines'(026).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-line
        )->a( n = `icon`    v = `sap-icon://line-chart`
        )->a( n = `tooltip` t = temp201 ).

    temp202 = 'Pie'(027).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-pie
        )->a( n = `icon`    v = `sap-icon://pie-chart`
        )->a( n = `tooltip` t = temp202 ).


    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                                   names  = lt_name
                                                   kind   = mv_chart_kind ).
    lo_box->tag( n = `HTML` ns = `core`
        )->a( n = `content` t = |<div>{ lv_svg }</div>| ).


    temp203 = 'Close'(013).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp203
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-chart_close ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD set_details.

    DATA temp19 TYPE xsdboolean.
    temp19 = boolc( val = abap_false ).
    mv_no_details = temp19.
    result = me.

  ENDMETHOD.

  METHOD set_search_field.

    DATA temp20 TYPE xsdboolean.
    temp20 = boolc( val = abap_false ).
    mv_no_search = temp20.
    result = me.

  ENDMETHOD.

  METHOD set_search.

    mv_search = condense( val ).
    mv_page = 1.
    result = me.

  ENDMETHOD.

  METHOD get_search.

    result = mv_search.

  ENDMETHOD.

  METHOD is_filtered.

    DATA temp21 TYPE xsdboolean.
    temp21 = boolc( mt_filter IS NOT INITIAL OR mv_search IS NOT INITIAL OR ( mv_page_size > 0 AND mt_window_filter IS NOT INITIAL ) ).
    result = temp21.

  ENDMETHOD.

  METHOD add_footer.

    DATA temp204 TYPE z2ui5_cl_cgui_alv=>ty_s_header.
    CLEAR temp204.
    temp204-label = label.
    temp204-value = value.
    INSERT temp204 INTO TABLE mt_footer.
    result = me.

  ENDMETHOD.

  METHOD get_footer.

    result = mt_footer.

  ENDMETHOD.

  METHOD has_selection.

    DATA temp22 TYPE xsdboolean.
    temp22 = boolc( mv_selection_mode = cs_selection_mode-multiple OR mv_selection_mode = cs_selection_mode-single ).
    result = temp22.

  ENDMETHOD.

  METHOD column_skipped.

    DATA lv_box TYPE string.
    lv_box = get_box_field( ).
    IF name = lv_box AND ( has_selection( ) = abap_true OR lv_box = cv_box_field ).
      result = abap_true.
    ELSEIF mv_color_field IS NOT INITIAL AND name = mv_color_field.
      result = abap_true.
    ELSEIF mv_edit_field IS NOT INITIAL AND name = mv_edit_field.
      result = abap_true.
    ELSE.
      result = column_setting( name )-technical.
    ENDIF.

  ENDMETHOD.

  METHOD set_selected_rows.

    FIELD-SYMBOLS <box> TYPE any.

    DATA lv_box TYPE string.
    FIELD-SYMBOLS <row> TYPE ANY.
      DATA lv_index LIKE sy-tabix.
      DATA temp205 LIKE sy-subrc.
      DATA temp206 LIKE sy-subrc.
      DATA temp207 LIKE sy-tabix.
      DATA temp23 TYPE xsdboolean.
    lv_box = get_box_field( ).

    LOOP AT tab ASSIGNING <row>.

      lv_index = sy-tabix.
      ASSIGN COMPONENT lv_box OF STRUCTURE <row> TO <box>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.



      temp206 = sy-subrc.
      temp207 = sy-tabix.
      READ TABLE rows WITH KEY table_line = lv_index TRANSPORTING NO FIELDS.
      temp205 = sy-subrc.
      sy-subrc = temp206.
      sy-tabix = temp207.

      temp23 = boolc( temp205 = 0 ).
      <box> = temp23.
    ENDLOOP.
    IF mv_selection_mode = cs_selection_mode-single.
      single_normalize( CHANGING tab = tab ).
    ENDIF.

  ENDMETHOD.

  METHOD single_normalize.

    FIELD-SYMBOLS <box> TYPE any.
    DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
      DATA lv_keep LIKE LINE OF lt_selected.
      FIELD-SYMBOLS <temp37> LIKE LINE OF lt_selected.
      DATA temp38 LIKE sy-tabix.
      DATA lv_row LIKE LINE OF lt_selected.
      DATA lv_box TYPE string.
        FIELD-SYMBOLS <line> TYPE any.
      FIELD-SYMBOLS <temp208> LIKE LINE OF lt_selected.
      DATA temp209 LIKE sy-tabix.

    IF mv_selection_mode <> cs_selection_mode-single.
      RETURN.
    ENDIF.
    " the radio buttons of rows scrolled out of view are not reset by the
    " browser - the row that is new wins

    lt_selected = get_selected_rows( tab ).
    IF lines( lt_selected ) > 1.



      temp38 = sy-tabix.
      READ TABLE lt_selected INDEX 1 ASSIGNING <temp37>.
      sy-tabix = temp38.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_keep = <temp37>.

      LOOP AT lt_selected INTO lv_row WHERE table_line <> mv_single_row.
        lv_keep = lv_row.
        EXIT.
      ENDLOOP.

      lv_box = get_box_field( ).
      LOOP AT lt_selected INTO lv_row WHERE table_line <> lv_keep.

        READ TABLE tab ASSIGNING <line> INDEX lv_row.
        ASSIGN COMPONENT lv_box OF STRUCTURE <line> TO <box>.
        IF sy-subrc = 0.
          <box> = abap_false.
        ENDIF.
      ENDLOOP.
      mv_single_row = lv_keep.
    ELSEIF lines( lt_selected ) = 1.


      temp209 = sy-tabix.
      READ TABLE lt_selected INDEX 1 ASSIGNING <temp208>.
      sy-tabix = temp209.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      mv_single_row = <temp208>.
    ELSE.
      CLEAR mv_single_row.
    ENDIF.

  ENDMETHOD.

  METHOD get_aggregates.

    " per currency or unit: 100 USD and 200 EUR are not a total of 300 -
    " the classic ALV totals per currency, and so does this one
    TYPES:
      BEGIN OF ty_s_part,
        unit  TYPE string,
        value TYPE decfloat34,
        count TYPE i,
      END OF ty_s_part.
    TYPES temp2 TYPE SORTED TABLE OF ty_s_part WITH UNIQUE KEY unit.
DATA lt_part      TYPE temp2.
    DATA ls_part      TYPE ty_s_part.
    DATA ls_aggregate TYPE ty_s_aggregate.
    DATA lv_value     TYPE decfloat34.
    DATA lv_unit      TYPE string.
    DATA lv_unit_col  TYPE string.
    FIELD-SYMBOLS <cell> TYPE any.
    FIELD-SYMBOLS <unit> TYPE any.
    FIELD-SYMBOLS <part> TYPE ty_s_part.

    DATA temp210 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp210.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp211 TYPE string.
      DATA lv_kind LIKE temp211.
      FIELD-SYMBOLS <row> TYPE ANY.
    temp210 = columns_visible( tab ).

    LOOP AT temp210 INTO ls_comp.

      ls_column = column_setting( ls_comp-name ).

      IF ls_column-aggregation IS NOT INITIAL.
        temp211 = ls_column-aggregation.
      ELSEIF ls_column-sum = abap_true.
        temp211 = cs_aggregation-sum.
      ELSE.
        CLEAR temp211.
      ENDIF.

      lv_kind = temp211.
      IF lv_kind IS INITIAL.
        CONTINUE.
      ENDIF.
      " a count counts cells, whatever their currency
      CLEAR lv_unit_col.
      IF lv_kind <> cs_aggregation-count.
        lv_unit_col = unit_column( column = ls_column
                                   tab    = tab ).
      ENDIF.
      CLEAR lt_part.

      LOOP AT tab ASSIGNING <row>.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        IF lv_kind = cs_aggregation-count.
          IF <cell> IS INITIAL.
            CONTINUE.
          ENDIF.
        ELSE.
          TRY.
              lv_value = <cell>.
            CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
              CONTINUE.
          ENDTRY.
        ENDIF.
        CLEAR lv_unit.
        IF lv_unit_col IS NOT INITIAL.
          ASSIGN COMPONENT lv_unit_col OF STRUCTURE <row> TO <unit>.
          lv_unit = <unit>.
        ENDIF.
        READ TABLE lt_part ASSIGNING <part> WITH TABLE KEY unit = lv_unit.
        IF sy-subrc <> 0.
          CLEAR ls_part.
          ls_part-unit = lv_unit.
          INSERT ls_part INTO TABLE lt_part ASSIGNING <part>.
        ENDIF.
        <part>-count = <part>-count + 1.
        CASE lv_kind.
          WHEN cs_aggregation-count.
          WHEN cs_aggregation-minimum.
            IF <part>-count = 1 OR lv_value < <part>-value.
              <part>-value = lv_value.
            ENDIF.
          WHEN cs_aggregation-maximum.
            IF <part>-count = 1 OR lv_value > <part>-value.
              <part>-value = lv_value.
            ENDIF.
          WHEN OTHERS.
            <part>-value = <part>-value + lv_value.
        ENDCASE.
      ENDLOOP.
      " no row: the aggregate of nothing, as a total of 0
      IF lt_part IS INITIAL.
        CLEAR ls_part.
        INSERT ls_part INTO TABLE lt_part.
      ENDIF.
      LOOP AT lt_part INTO ls_part.
        CLEAR ls_aggregate.
        ls_aggregate-column = ls_comp-name.
        ls_aggregate-label = ls_comp-label.
        ls_aggregate-aggregation = lv_kind.
        ls_aggregate-value = ls_part-value.
        ls_aggregate-unit = ls_part-unit.
        IF lv_kind = cs_aggregation-count.
          ls_aggregate-value = ls_part-count.
        ELSEIF lv_kind = cs_aggregation-average AND ls_part-count > 0.
          ls_aggregate-value = ls_part-value / ls_part-count.
        ENDIF.
        INSERT ls_aggregate INTO TABLE result.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD unit_column.

    DATA temp212 TYPE string.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA temp213 LIKE sy-subrc.
    IF column-currency IS NOT INITIAL.
      temp212 = column-currency.
    ELSE.
      temp212 = column-quantity.
    ENDIF.
    result = temp212.
    IF result IS INITIAL.
      RETURN.
    ENDIF.

    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    READ TABLE lt_comp WITH KEY name = result TRANSPORTING NO FIELDS.
    temp213 = sy-subrc.
    IF NOT temp213 = 0.
      CLEAR result.
    ENDIF.

  ENDMETHOD.

  METHOD details_popup.

    FIELD-SYMBOLS <cell> TYPE any.

    FIELD-SYMBOLS <row> TYPE any.
    DATA temp214 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp215 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp215.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp216 TYPE string.
    DATA temp217 TYPE string.
    READ TABLE tab ASSIGNING <row> INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.


    IF mv_title IS NOT INITIAL.
      temp214 = mv_title.
    ELSE.
      temp214 = 'Details'(012).
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp214
        )->a( n = `contentWidth` v = `32rem`
        )->a( n = `resizable`    b = abap_true ).

    " every column of the row - hidden ones too, technical ones not

    lo_box = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    temp215 = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT temp215 INTO ls_comp.
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      ls_column = column_setting( ls_comp-name ).

      IF ls_column-text IS NOT INITIAL.
        temp216 = ls_column-text.
      ELSE.
        temp216 = ls_comp-label.
      ENDIF.
      lo_box->ele( `HBox`
          )->tag( `Label`
          )->a( n = `text`  t = |{ temp216 }:|
          )->a( n = `width` v = `12rem`
          )->tag( `Text`
          )->a( n = `text` t = cell_to_text( val  = <cell>
                                             comp = ls_comp ) ).
    ENDLOOP.


    temp217 = 'Close'(013).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp217
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-details_close ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD set_color_field.

    mv_color_field = to_upper( name ).
    result = me.

  ENDMETHOD.

  METHOD set_column_color.

    DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
    lr_column = column_get( name ).
    lr_column->color = to_upper( color ).
    lr_column->color_field = to_upper( field ).
    result = me.

  ENDMETHOD.

  METHOD color_state.

    DATA lv_code TYPE string.
    lv_code = to_upper( condense( code ) ).
    IF strlen( lv_code ) < 2 OR lv_code(1) <> `C`.
      result = `None`.
      RETURN.
    ENDIF.
    CASE lv_code+1(1).
      WHEN `1`.
        result = `Indication05`.
      WHEN `3`.
        result = `Warning`.
      WHEN `4`.
        result = `Indication06`.
      WHEN `5`.
        result = `Success`.
      WHEN `6`.
        result = `Error`.
      WHEN `7`.
        result = `Indication03`.
      WHEN OTHERS.
        result = `None`.
    ENDCASE.

  ENDMETHOD.

  METHOD color_binding.

    " the same as color_state( ), in the browser
    DATA lv_code TYPE string.
    lv_code = |(String($\{{ z2ui5_cl_ui5_view_builder=>component_path( to_upper( field ) ) }\} \|\| '')).substring(1,2)|.
    result = |\{= { lv_code } === '1' ? 'Indication05' : { lv_code } === '3' ? 'Warning' : |
          && |{ lv_code } === '4' ? 'Indication06' : { lv_code } === '5' ? 'Success' : |
          && |{ lv_code } === '6' ? 'Error' : { lv_code } === '7' ? 'Indication03' : 'None' \}|.

  ENDMETHOD.

  METHOD set_filter.

    DATA lv_name TYPE string.
    DATA lt_rows LIKE rows.
      DATA temp218 TYPE z2ui5_cl_cgui_alv=>ty_s_filter.
    lv_name = to_upper( name ).
    DELETE mt_filter WHERE name = lv_name.

    lt_rows = rows.
    DELETE lt_rows WHERE low IS INITIAL AND high IS INITIAL.
    IF lt_rows IS NOT INITIAL.

      CLEAR temp218.
      temp218-name = lv_name.
      temp218-rows = lt_rows.
      INSERT temp218 INTO TABLE mt_filter.
    ENDIF.
    mv_page = 1.
    result = me.

  ENDMETHOD.

  METHOD get_filter.

    result = mt_filter.

  ENDMETHOD.

  METHOD clear_filter.
      DATA lv_name TYPE string.

    " the filter of a column menu of the paged grid with it
    IF name IS INITIAL.
      CLEAR: mt_filter, mt_window_filter.
    ELSE.

      lv_name = to_upper( name ).
      DELETE mt_filter WHERE name = lv_name.
      DELETE mt_window_filter WHERE path = lv_name.
    ENDIF.
    mv_page = 1.

  ENDMETHOD.

  METHOD check_filter.

    DATA lt_typed   TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_pattern TYPE z2ui5_cl_cgui_range=>ty_t_row.

    filter_split( EXPORTING rows    = rows
                  IMPORTING typed   = lt_typed
                            pattern = lt_pattern ).
    filter_range( EXPORTING name  = name
                            rows  = lt_typed
                            tab   = tab
                  IMPORTING error = result ).

  ENDMETHOD.

  METHOD filter_split.
    DATA ls_row LIKE LINE OF rows.

    " a pattern needs the text of the cell - a number or a NUMC would lose
    " the * of it
    CLEAR: typed, pattern.

    LOOP AT rows INTO ls_row.
      IF ls_row-option = `CP` OR ls_row-option = `NP`
          OR ( ( ls_row-option = `EQ` OR ls_row-option = `NE` OR ls_row-option IS INITIAL ) AND ls_row-low CA `*+` ).
        INSERT ls_row INTO TABLE pattern.
      ELSE.
        INSERT ls_row INTO TABLE typed.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD filter_range.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    DATA temp219 TYPE REF TO cl_abap_tabledescr.
    DATA lo_table LIKE temp219.
    DATA temp220 TYPE REF TO cl_abap_structdescr.
    DATA lo_struct LIKE temp220.
    DATA lv_name TYPE string.
    DATA lt_comp TYPE abap_component_tab.
    DATA ls_comp TYPE abap_componentdescr.
        DATA temp221 TYPE REF TO cl_abap_datadescr.
        DATA temp39 TYPE REF TO cl_abap_datadescr.
        DATA lo_value LIKE temp39.
        DATA temp222 TYPE abap_component_tab.
        DATA temp223 LIKE LINE OF temp222.
        DATA lo_line TYPE REF TO cl_abap_structdescr.
        DATA lo_range TYPE REF TO cl_abap_tabledescr.

    CLEAR error.

    temp219 ?= cl_abap_typedescr=>describe_by_data( tab ).

    lo_table = temp219.

    temp220 ?= lo_table->get_table_line_type( ).

    lo_struct = temp220.

    lv_name = to_upper( name ).

    lt_comp = lo_struct->get_components( ).

    READ TABLE lt_comp INTO ls_comp WITH KEY name = lv_name.
    IF sy-subrc <> 0 OR ls_comp-type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    TRY.

        temp221 ?= cl_abap_elemdescr=>get_string( ).

        IF pattern = abap_true.
          temp39 = temp221.
        ELSE.
          temp39 = ls_comp-type.
        ENDIF.

        lo_value = temp39.
        " create( ), not get( ) - get( ) is a stub in the transpiled runtime

        CLEAR temp222.

        temp223-name = `SIGN`.
        temp223-type = cl_abap_elemdescr=>get_c( 1 ).
        INSERT temp223 INTO TABLE temp222.
        temp223-name = `OPTION`.
        temp223-type = cl_abap_elemdescr=>get_c( 2 ).
        INSERT temp223 INTO TABLE temp222.
        temp223-name = `LOW`.
        temp223-type = lo_value.
        INSERT temp223 INTO TABLE temp222.
        temp223-name = `HIGH`.
        temp223-type = lo_value.
        INSERT temp223 INTO TABLE temp222.

        lo_line = cl_abap_structdescr=>create(
            temp222 ).

        lo_range = cl_abap_tabledescr=>create( lo_line ).

        CREATE DATA result TYPE HANDLE lo_range.
      CATCH cx_root.
        CLEAR result.
        RETURN.
    ENDTRY.
    ASSIGN result->* TO <range>.
    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = rows
                                        IMPORTING error = error
                                        CHANGING  range = <range> ).

  ENDMETHOD.

  METHOD filter_index.

    " per filter the include and the exclude lines, typed and as patterns:
    " a row passes when one include line matches (or there is none) and no
    " exclude line does - the semantics of a select-option
    TYPES:
      BEGIN OF ty_s_check,
        name         TYPE string,
        has_incl     TYPE abap_bool,
        has_pattern  TYPE abap_bool,
        incl_typed   TYPE REF TO data,
        incl_pattern TYPE REF TO data,
        excl_typed   TYPE REF TO data,
        excl_pattern TYPE REF TO data,
      END OF ty_s_check.
    TYPES temp3 TYPE STANDARD TABLE OF ty_s_check WITH DEFAULT KEY.
DATA lt_check   TYPE temp3.
    DATA ls_check   TYPE ty_s_check.
    DATA lt_typed   TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_pattern TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_incl    TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_excl    TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lv_error   TYPE string.
    DATA lv_text    TYPE string.
    FIELD-SYMBOLS <cell> TYPE any.

    " the filter of the grid and, paged, the one of the column menus - the
    " browser holds only some of the rows there and filters none of them
    DATA lt_filter LIKE mt_filter.
    DATA ls_filter LIKE LINE OF lt_filter.
      DATA temp224 LIKE sy-subrc.
      DATA temp225 LIKE sy-subrc.
      DATA temp226 LIKE sy-tabix.
      DATA temp40 LIKE sy-subrc.
      DATA temp41 LIKE sy-subrc.
      DATA temp42 LIKE sy-tabix.
      DATA temp24 TYPE xsdboolean.
      DATA temp25 TYPE xsdboolean.
    DATA lt_visible TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    FIELD-SYMBOLS <row> TYPE ANY.
      DATA lv_index LIKE sy-tabix.
      DATA lv_pass LIKE abap_true.
        DATA ls_visible LIKE LINE OF lt_visible.
        DATA lv_incl TYPE abap_bool.
        DATA temp26 TYPE xsdboolean.
    lt_filter = mt_filter.
    IF mv_page_size > 0.
      INSERT LINES OF window_filter( tab ) INTO TABLE lt_filter.
    ENDIF.


    LOOP AT lt_filter INTO ls_filter.
      IF check_filter( name = ls_filter-name
                       rows = ls_filter-rows
                       tab  = tab ) IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR ls_check.
      ls_check-name = ls_filter-name.
      filter_split( EXPORTING rows    = ls_filter-rows
                    IMPORTING typed   = lt_typed
                              pattern = lt_pattern ).



      temp225 = sy-subrc.
      temp226 = sy-tabix.
      READ TABLE ls_filter-rows WITH KEY sign = `I` TRANSPORTING NO FIELDS.
      temp224 = sy-subrc.
      sy-subrc = temp225.
      sy-tabix = temp226.



      temp41 = sy-subrc.
      temp42 = sy-tabix.
      READ TABLE ls_filter-rows WITH KEY sign = `` TRANSPORTING NO FIELDS.
      temp40 = sy-subrc.
      sy-subrc = temp41.
      sy-tabix = temp42.

      temp24 = boolc( temp224 = 0 OR temp40 = 0 ).
      ls_check-has_incl = temp24.
      lt_incl = lt_typed.
      DELETE lt_incl WHERE sign = `E`.
      lt_excl = lt_typed.
      DELETE lt_excl WHERE sign <> `E`.
      ls_check-incl_typed = filter_range( EXPORTING name  = ls_filter-name
                                                    rows  = lt_incl
                                                    tab   = tab
                                          IMPORTING error = lv_error ).
      ls_check-excl_typed = filter_range( EXPORTING name  = ls_filter-name
                                                    rows  = lt_excl
                                                    tab   = tab
                                          IMPORTING error = lv_error ).
      lt_incl = lt_pattern.
      DELETE lt_incl WHERE sign = `E`.
      lt_excl = lt_pattern.
      DELETE lt_excl WHERE sign <> `E`.
      ls_check-incl_pattern = filter_range( EXPORTING name    = ls_filter-name
                                                      rows    = lt_incl
                                                      tab     = tab
                                                      pattern = abap_true
                                            IMPORTING error   = lv_error ).
      ls_check-excl_pattern = filter_range( EXPORTING name    = ls_filter-name
                                                      rows    = lt_excl
                                                      tab     = tab
                                                      pattern = abap_true
                                            IMPORTING error   = lv_error ).
      " the signs once per filter, not per row
      filter_include( ls_check-incl_typed ).
      filter_include( ls_check-excl_typed ).
      filter_include( ls_check-incl_pattern ).
      filter_include( ls_check-excl_pattern ).

      temp25 = boolc( lt_pattern IS NOT INITIAL ).
      ls_check-has_pattern = temp25.
      IF ls_check-incl_typed IS BOUND.
        INSERT ls_check INTO TABLE lt_check.
      ENDIF.
    ENDLOOP.


    lt_visible = columns_visible( tab ).

    LOOP AT tab ASSIGNING <row>.

      lv_index = sy-tabix.

      lv_pass = abap_true.
      " the search: the text in one of the columns shown, case ignored (CS)
      IF mv_search IS NOT INITIAL.
        lv_pass = abap_false.

        LOOP AT lt_visible INTO ls_visible.
          ASSIGN COMPONENT ls_visible-name OF STRUCTURE <row> TO <cell>.
          IF sy-subrc = 0 AND cell_to_text( val  = <cell>
                                            comp = ls_visible ) CS mv_search.
            lv_pass = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lv_pass = abap_false.
          CONTINUE.
        ENDIF.
      ENDIF.
      LOOP AT lt_check INTO ls_check.
        ASSIGN COMPONENT ls_check-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        " the cell as text only for a pattern
        CLEAR lv_text.
        IF ls_check-has_pattern = abap_true.
          lv_text = |{ <cell> }|.
        ENDIF.


        temp26 = boolc( ls_check-has_incl = abap_false OR filter_match( val = <cell> range = ls_check-incl_typed ) = abap_true OR filter_match( val = lv_text range = ls_check-incl_pattern ) = abap_true ).
        lv_incl = temp26.
        IF lv_incl = abap_false
            OR filter_match( val   = <cell>
                             range = ls_check-excl_typed ) = abap_true
            OR filter_match( val   = lv_text
                             range = ls_check-excl_pattern ) = abap_true.
          lv_pass = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_pass = abap_true.
        INSERT lv_index INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD filter_match.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.

    " whether one line of the range matches val - an empty range matches
    " nothing
    IF range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN range->* TO <range>.
    IF <range> IS INITIAL.
      RETURN.
    ENDIF.
    result = z2ui5_cl_cgui_context=>range_check( val   = val
                                                 range = <range> ).

  ENDMETHOD.

  METHOD filter_include.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <sign>  TYPE any.

    IF range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN range->* TO <range>.
    LOOP AT <range> ASSIGNING <line>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <sign>.
      IF sy-subrc = 0.
        <sign> = `I`.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_filter_change.

    DATA temp27 TYPE xsdboolean.
    temp27 = boolc( val = abap_false ).
    mv_no_filter = temp27.
    result = me.

  ENDMETHOD.

  METHOD add_header.

    DATA temp227 TYPE z2ui5_cl_cgui_alv=>ty_s_header.
    CLEAR temp227.
    temp227-label = label.
    temp227-value = value.
    INSERT temp227 INTO TABLE mt_header.
    result = me.

  ENDMETHOD.

  METHOD get_header.

    result = mt_header.

  ENDMETHOD.

  METHOD clear_header.

    CLEAR mt_header.

  ENDMETHOD.

  METHOD render_header.

    DATA temp228 TYPE ty_t_header.
    DATA lt_line LIKE temp228.
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_header LIKE LINE OF lt_line.
    IF items IS SUPPLIED.
      temp228 = items.
    ELSE.
      temp228 = mt_header.
    ENDIF.

    lt_line = temp228.
    IF lt_line IS INITIAL.
      RETURN.
    ENDIF.

    lo_box = node->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMarginBeginEnd sapUiSmallMarginTop` ).

    LOOP AT lt_line INTO ls_header.
      IF ls_header-label IS INITIAL.
        lo_box->tag( `Title`
            )->a( n = `text`  t = ls_header-value
            )->a( n = `level` v = `H3` ).
        CONTINUE.
      ENDIF.
      lo_box->ele( `HBox`
          )->tag( `Label`
          )->a( n = `text`   t = |{ ls_header-label }:|
          )->a( n = `design` v = `Bold`
          )->a( n = `class`  v = `sapUiTinyMarginEnd`
          )->tag( `Text`
          )->a( n = `text` t = ls_header-value ).
    ENDLOOP.

  ENDMETHOD.

  METHOD set_layout_change.

    DATA temp28 TYPE xsdboolean.
    temp28 = boolc( val = abap_false ).
    mv_no_layout = temp28.
    result = me.

  ENDMETHOD.

  METHOD get_layout_change.

    DATA temp29 TYPE xsdboolean.
    temp29 = boolc( mv_no_layout = abap_false ).
    result = temp29.

  ENDMETHOD.

  METHOD get_layout.

    DATA lv_seq TYPE i.

    DATA temp229 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp229.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp230 TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
      DATA temp43 TYPE z2ui5_cl_cgui_alv=>ty_s_layout-text.
      DATA temp44 TYPE z2ui5_cl_cgui_alv=>ty_s_layout-position.
    DATA temp231 LIKE LINE OF result.
    DATA lr_layout LIKE REF TO temp231.
    temp229 = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT temp229 INTO ls_comp.
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      lv_seq = lv_seq + 1.

      ls_column = column_setting( ls_comp-name ).

      CLEAR temp230.
      temp230-name = ls_comp-name.

      IF ls_column-text IS NOT INITIAL.
        temp43 = ls_column-text.
      ELSE.
        temp43 = ls_comp-label.
      ENDIF.
      temp230-text = temp43.
      temp230-hidden = ls_column-hidden.

      IF ls_column-position > 0.
        temp44 = ls_column-position.
      ELSE.
        temp44 = 1000 + lv_seq.
      ENDIF.
      temp230-position = temp44.
      temp230-sort = ls_column-sort.
      temp230-sort_seq = ls_column-sort_seq.
      temp230-sum = ls_column-sum.
      temp230-subtotal = ls_column-subtotal.
      temp230-numeric = is_numeric( ls_comp-type_kind ).
      INSERT temp230 INTO TABLE result.
    ENDLOOP.

    SORT result STABLE BY position.


    LOOP AT result REFERENCE INTO lr_layout.
      lr_layout->position = sy-tabix.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_layout.

    DATA ls_layout LIKE LINE OF layout.
      DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp232 TYPE z2ui5_cl_cgui_alv=>ty_s_column-sort_seq.
    LOOP AT layout INTO ls_layout.

      lr_column = column_get( ls_layout-name ).
      lr_column->hidden   = ls_layout-hidden.
      lr_column->position = ls_layout-position.
      lr_column->sort     = to_upper( ls_layout-sort ).

      IF ls_layout-sort IS NOT INITIAL.
        temp232 = ls_layout-sort_seq.
      ELSE.
        CLEAR temp232.
      ENDIF.
      lr_column->sort_seq = temp232.
      lr_column->sum      = ls_layout-sum.
      lr_column->subtotal = ls_layout-subtotal.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD render_functions.

    DATA temp233 LIKE LINE OF functions.
    DATA lr_function LIKE REF TO temp233.
    LOOP AT functions REFERENCE INTO lr_function.
      bar->tag( `Button`
          )->a( n = `text`    t = lr_function->text
          )->a( n = `icon`    v = lr_function->icon
          )->a( n = `tooltip` t = lr_function->tooltip
          )->a( n = `press`   v = client->_event( lr_function->name ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD is_numeric.

    CASE type_kind.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR `8`
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        " `8`: typekind_int8, a constant lower releases do not have
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD sort_rows.

    DATA lt_index  TYPE ty_t_index.
    DATA lv_number TYPE i.
    DATA lr_copy   TYPE REF TO data.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.

    DATA lt_order TYPE abap_sortorder_tab.
    DATA lv_lines TYPE i.
    DATA lv_row LIKE LINE OF lt_index.
    lt_order = sort_order( tab ).

    lv_lines = lines( tab ).
    IF lt_order IS INITIAL OR lv_lines < 2.
      RETURN.
    ENDIF.
    DO lv_lines TIMES.
      lv_number = sy-index.
      INSERT lv_number INTO TABLE lt_index.
    ENDDO.
    index_sort( EXPORTING tab   = tab
                          order = lt_order
                CHANGING  index = lt_index ).

    " the rows anew in that order
    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    CLEAR tab.

    LOOP AT lt_index INTO lv_row.
      READ TABLE <copy> INDEX lv_row ASSIGNING <row>.
      INSERT <row> INTO TABLE tab.
    ENDLOOP.

  ENDMETHOD.

  METHOD index_sort.

    " a merge sort of the row numbers, bottom up - stable, and by the
    " components the columns name at run time: SORT ... BY (otab) and
    " SORT ... BY (name) sort nothing in the transpiled runtime
    DATA lt_merged TYPE ty_t_index.
    DATA lv_right  TYPE abap_bool.
    DATA lv_a      TYPE i.
    DATA lv_b      TYPE i.
    DATA lv_number TYPE i.

    DATA lv_lines TYPE i.
    DATA lv_width TYPE i.
      DATA lv_left TYPE i.
        DATA lv_mid TYPE i.
        DATA lv_end TYPE i.
        DATA lv_i LIKE lv_left.
        DATA lv_j LIKE lv_mid.
    lv_lines = lines( index ).
    IF order IS INITIAL OR lv_lines < 2.
      RETURN.
    ENDIF.


    lv_width = 1.
    WHILE lv_width < lv_lines.
      CLEAR lt_merged.

      lv_left = 1.
      WHILE lv_left <= lv_lines.
        " the runs [left, mid) and [mid, end) into one

        lv_mid = nmin( val1 = lv_left + lv_width
                             val2 = lv_lines + 1 ).

        lv_end = nmin( val1 = lv_left + 2 * lv_width
                             val2 = lv_lines + 1 ).

        lv_i = lv_left.

        lv_j = lv_mid.
        WHILE lv_i < lv_mid OR lv_j < lv_end.
          IF lv_j >= lv_end.
            lv_right = abap_false.
          ELSEIF lv_i >= lv_mid.
            lv_right = abap_true.
          ELSE.
            " the right one only when it is really before - stable
            READ TABLE index INDEX lv_j INTO lv_a.
            READ TABLE index INDEX lv_i INTO lv_b.
            lv_right = rows_less( tab   = tab
                                  order = order
                                  a     = lv_a
                                  b     = lv_b ).
          ENDIF.
          IF lv_right = abap_true.
            READ TABLE index INDEX lv_j INTO lv_number.
            lv_j = lv_j + 1.
          ELSE.
            READ TABLE index INDEX lv_i INTO lv_number.
            lv_i = lv_i + 1.
          ENDIF.
          INSERT lv_number INTO TABLE lt_merged.
        ENDWHILE.
        lv_left = lv_end.
      ENDWHILE.
      index = lt_merged.
      lv_width = lv_width * 2.
    ENDWHILE.

  ENDMETHOD.

  METHOD rows_less.

    FIELD-SYMBOLS <row_a> TYPE any.
    FIELD-SYMBOLS <row_b> TYPE any.
    FIELD-SYMBOLS <val_a> TYPE any.
    FIELD-SYMBOLS <val_b> TYPE any.
    DATA ls_order LIKE LINE OF order.
      DATA lv_name TYPE string.
        DATA temp30 TYPE xsdboolean.
        DATA temp31 TYPE xsdboolean.

    READ TABLE tab INDEX a ASSIGNING <row_a>.
    READ TABLE tab INDEX b ASSIGNING <row_b>.

    LOOP AT order INTO ls_order.

      lv_name = condense( ls_order-name ).
      UNASSIGN: <val_a>, <val_b>.
      ASSIGN COMPONENT lv_name OF STRUCTURE <row_a> TO <val_a>.
      ASSIGN COMPONENT lv_name OF STRUCTURE <row_b> TO <val_b>.
      IF <val_a> IS NOT ASSIGNED OR <val_b> IS NOT ASSIGNED OR <val_a> = <val_b>.
        CONTINUE.
      ENDIF.
      IF ls_order-descending = abap_true.

        temp30 = boolc( <val_a> > <val_b> ).
        result = temp30.
      ELSE.

        temp31 = boolc( <val_a> < <val_b> ).
        result = temp31.
      ENDIF.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD sort_order.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA temp234 TYPE abap_sortorder_tab.
    DATA ls_order LIKE LINE OF temp234.
      DATA temp235 LIKE sy-subrc.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    temp234 = sort_layout( ).

    LOOP AT temp234 INTO ls_order.

      READ TABLE lt_comp WITH KEY name = ls_order-name TRANSPORTING NO FIELDS.
      temp235 = sy-subrc.
      IF temp235 = 0.
        INSERT ls_order INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD sort_layout.

    DATA lt_sorted LIKE mt_column.
    DATA ls_column LIKE LINE OF lt_sorted.
      DATA temp236 TYPE abap_sortorder.
      DATA temp32 TYPE xsdboolean.
    lt_sorted = mt_column.
    DELETE lt_sorted WHERE sort IS INITIAL.
    SORT lt_sorted BY sort_seq name.

    LOOP AT lt_sorted INTO ls_column.

      CLEAR temp236.
      temp236-name = ls_column-name.

      temp32 = boolc( ls_column-sort = cs_sort-descending ).
      temp236-descending = temp32.
      INSERT temp236 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD window_request.

    " MORE goes on in the order there is
    IF request-reason = z2ui5_if_client=>cs_window_reason-more.
      RETURN.
    ENDIF.
    mt_window_sort   = request-t_sort.
    mt_window_filter = request-t_filter.
    mt_window_layout = sort_layout( ).

  ENDMETHOD.

  METHOD window_order.

    DATA lt_order TYPE abap_sortorder_tab.

    " what a column menu asked for holds until the layout sorts anew
    DATA lt_layout TYPE abap_sortorder_tab.
    DATA ls_sort LIKE LINE OF mt_window_sort.
      DATA temp237 TYPE abap_sortorder.
    lt_layout = sort_layout( ).
    IF mt_window_layout <> lt_layout.
      CLEAR: mt_window_sort, mt_window_filter, mt_window_layout.
    ENDIF.

    " the filter of the grid and the one of the column menus together
    result = filter_index( tab ).


    LOOP AT mt_window_sort INTO ls_sort.

      CLEAR temp237.
      temp237-name = ls_sort-path.
      temp237-descending = ls_sort-descending.
      INSERT temp237 INTO TABLE lt_order.
    ENDLOOP.
    IF lt_order IS INITIAL.
      lt_order = sort_order( tab ).
    ENDIF.
    index_sort( EXPORTING tab   = tab
                          order = lt_order
                CHANGING  index = result ).

  ENDMETHOD.

  METHOD window_filter.

    " the conditions of a group are ORed, the groups ANDed - as the lines of
    " a multiple selection and the filters of the grid. A group that ORs
    " conditions on two columns has no multiple selection and is left out
    TYPES:
      BEGIN OF ty_s_group,
        group TYPE i,
        name  TYPE string,
        mixed TYPE abap_bool,
        rows  TYPE z2ui5_cl_cgui_range=>ty_t_row,
      END OF ty_s_group.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_group WITH DEFAULT KEY.
DATA lt_group TYPE temp4.
    DATA ls_row   TYPE z2ui5_cl_cgui_range=>ty_s_row.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_cond LIKE LINE OF mt_window_filter.
      FIELD-SYMBOLS <group> TYPE ty_s_group.
        DATA temp238 TYPE ty_s_group.
      DATA lv_low LIKE ls_cond-value1.
      DATA lv_high LIKE ls_cond-value2.
      DATA ls_comp TYPE z2ui5_cl_cgui_context=>ty_s_comp.
    DATA ls_group LIKE LINE OF lt_group.
      DATA temp239 TYPE z2ui5_cl_cgui_alv=>ty_s_filter.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT mt_window_filter INTO ls_cond.

      READ TABLE lt_group ASSIGNING <group> WITH KEY group = ls_cond-group.
      IF sy-subrc <> 0.

        CLEAR temp238.
        temp238-group = ls_cond-group.
        temp238-name = ls_cond-path.
        INSERT temp238 INTO TABLE lt_group ASSIGNING <group>.
      ELSEIF <group>-name <> ls_cond-path.
        <group>-mixed = abap_true.
      ENDIF.

      " a date or a time comes as the browser writes it, the cell has digits

      lv_low = ls_cond-value1.

      lv_high = ls_cond-value2.

      READ TABLE lt_comp INTO ls_comp WITH KEY name = ls_cond-path.
      IF sy-subrc = 0 AND ls_comp-type_kind = cl_abap_typedescr=>typekind_date.
        lv_low = replace( val = lv_low sub = `-` with = `` occ = 0 ).
        lv_high = replace( val = lv_high sub = `-` with = `` occ = 0 ).
      ELSEIF sy-subrc = 0 AND ls_comp-type_kind = cl_abap_typedescr=>typekind_time.
        lv_low = replace( val = lv_low sub = `:` with = `` occ = 0 ).
        lv_high = replace( val = lv_high sub = `:` with = `` occ = 0 ).
      ENDIF.

      " a sap.ui.model.FilterOperator as a line of a multiple selection
      CLEAR ls_row.
      ls_row-sign = `I`.
      ls_row-low = lv_low.
      CASE ls_cond-operator.
        WHEN `EQ` OR `NE` OR `LT` OR `LE` OR `GT` OR `GE`.
          ls_row-option = ls_cond-operator.
        WHEN `BT` OR `NB`.
          ls_row-option = ls_cond-operator.
          ls_row-high = lv_high.
        WHEN `Contains`.
          ls_row-option = `CP`.
          ls_row-low = |*{ lv_low }*|.
        WHEN `NotContains`.
          ls_row-option = `NP`.
          ls_row-low = |*{ lv_low }*|.
        WHEN `StartsWith`.
          ls_row-option = `CP`.
          ls_row-low = |{ lv_low }*|.
        WHEN `NotStartsWith`.
          ls_row-option = `NP`.
          ls_row-low = |{ lv_low }*|.
        WHEN `EndsWith`.
          ls_row-option = `CP`.
          ls_row-low = |*{ lv_low }|.
        WHEN `NotEndsWith`.
          ls_row-option = `NP`.
          ls_row-low = |*{ lv_low }|.
        WHEN OTHERS.
          " an operator a multiple selection does not know - the group
          " cannot be applied
          <group>-mixed = abap_true.
          CONTINUE.
      ENDCASE.
      INSERT ls_row INTO TABLE <group>-rows.
    ENDLOOP.


    LOOP AT lt_group INTO ls_group WHERE mixed = abap_false.

      CLEAR temp239.
      temp239-name = ls_group-name.
      temp239-rows = ls_group-rows.
      INSERT temp239 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD sorter.

    DATA lt_part TYPE string_table.

    DATA temp240 TYPE abap_sortorder_tab.
    DATA ls_order LIKE LINE OF temp240.
      DATA temp241 TYPE string.
      DATA temp45 LIKE LINE OF lt_part.
    temp240 = sort_order( tab ).

    LOOP AT temp240 INTO ls_order.

      IF ls_order-descending = abap_true.
        temp241 = `true`.
      ELSE.
        temp241 = `false`.
      ENDIF.

      temp45 = |\{path: '{ ls_order-name }', descending: { temp241 }\}|.
      INSERT temp45 INTO TABLE lt_part.
    ENDLOOP.
    IF lt_part IS NOT INITIAL.
      result = |[{ concat_lines_of( table = lt_part sep = `, ` ) }]|.
    ENDIF.

  ENDMETHOD.

  METHOD get_subtotals.

    TYPES:
      BEGIN OF ty_s_seen,
        group  TYPE string,
        column TYPE string,
        unit   TYPE string,
        pos    TYPE i,
      END OF ty_s_seen.
    TYPES:
      BEGIN OF ty_s_unit_col,
        column TYPE string,
        unit   TYPE string,
      END OF ty_s_unit_col.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    FIELD-SYMBOLS <unit> TYPE any.
    DATA lt_part     TYPE string_table.
    TYPES temp5 TYPE SORTED TABLE OF ty_s_seen WITH UNIQUE KEY group column unit.
DATA lt_seen     TYPE temp5.
    TYPES temp6 TYPE STANDARD TABLE OF ty_s_unit_col WITH DEFAULT KEY.
DATA lt_unit_col TYPE temp6.
    DATA lt_index    TYPE ty_t_index.
    DATA lv_value    TYPE decfloat34.
    DATA lv_number   TYPE i.
    DATA lv_unit     TYPE string.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA lt_group LIKE mt_column.
    DATA lt_summed LIKE mt_column.
    DATA ls_with_unit LIKE LINE OF lt_summed.
      DATA temp242 TYPE ty_s_unit_col.
    DATA lv_row LIKE LINE OF lt_index.
      DATA ls_group LIKE LINE OF lt_group.
        DATA ls_comp TYPE z2ui5_cl_cgui_context=>ty_s_comp.
      DATA lv_group TYPE string.
      DATA ls_summed LIKE LINE OF lt_summed.
        DATA ls_unit_col TYPE ty_s_unit_col.
        DATA ls_seen TYPE ty_s_seen.
          FIELD-SYMBOLS <sum> TYPE z2ui5_cl_cgui_alv=>ty_s_subtotal.
          DATA temp243 TYPE z2ui5_cl_cgui_alv=>ty_s_subtotal.
          DATA temp244 TYPE ty_s_seen.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    lt_group = mt_column.
    DELETE lt_group WHERE subtotal = abap_false OR sort IS INITIAL.
    SORT lt_group BY sort_seq name.

    lt_summed = mt_column.
    DELETE lt_summed WHERE sum = abap_false OR hidden = abap_true.
    IF lt_group IS INITIAL OR lt_summed IS INITIAL.
      RETURN.
    ENDIF.
    " a subtotal per currency or unit as well - amounts of two currencies
    " are not added up

    LOOP AT lt_summed INTO ls_with_unit.

      CLEAR temp242.
      temp242-column = ls_with_unit-name.
      temp242-unit = unit_column( column = ls_with_unit tab = tab ).
      INSERT temp242 INTO TABLE lt_unit_col.
    ENDLOOP.

    " the rows in the order of the sorting - the groups follow it, not the
    " order of their texts: 9 before 10, and descending where it sorts so
    DO lines( tab ) TIMES.
      lv_number = sy-index.
      INSERT lv_number INTO TABLE lt_index.
    ENDDO.
    index_sort( EXPORTING tab   = tab
                          order = sort_order( tab )
                CHANGING  index = lt_index ).


    LOOP AT lt_index INTO lv_row.
      READ TABLE tab ASSIGNING <row> INDEX lv_row.
      CLEAR lt_part.

      LOOP AT lt_group INTO ls_group.

        READ TABLE lt_comp INTO ls_comp WITH KEY name = ls_group-name.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT ls_group-name OF STRUCTURE <row> TO <cell>.
        INSERT cell_to_text( val  = <cell>
                             comp = ls_comp ) INTO TABLE lt_part.
      ENDLOOP.

      lv_group = concat_lines_of( table = lt_part sep = ` / ` ).


      LOOP AT lt_summed INTO ls_summed.
        ASSIGN COMPONENT ls_summed-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        TRY.
            lv_value = <cell>.
          CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
            CONTINUE.
        ENDTRY.
        CLEAR lv_unit.

        READ TABLE lt_unit_col INTO ls_unit_col WITH KEY column = ls_summed-name.
        IF sy-subrc = 0 AND ls_unit_col-unit IS NOT INITIAL.
          ASSIGN COMPONENT ls_unit_col-unit OF STRUCTURE <row> TO <unit>.
          lv_unit = <unit>.
        ENDIF.

        READ TABLE lt_seen INTO ls_seen WITH TABLE KEY group  = lv_group
                                                             column = ls_summed-name
                                                             unit   = lv_unit.
        IF sy-subrc = 0.

          READ TABLE result ASSIGNING <sum> INDEX ls_seen-pos.
          <sum>-value = <sum>-value + lv_value.
        ELSE.

          CLEAR temp243.
          temp243-group = lv_group.
          temp243-column = ls_summed-name.
          temp243-value = lv_value.
          temp243-unit = lv_unit.
          INSERT temp243 INTO TABLE result.

          CLEAR temp244.
          temp244-group = lv_group.
          temp244-column = ls_summed-name.
          temp244-unit = lv_unit.
          temp244-pos = lines( result ).
          INSERT temp244 INTO TABLE lt_seen.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD to_text.

    TYPES:
      BEGIN OF ty_s_width,
        name  TYPE string,
        width TYPE i,
        right TYPE abap_bool,
      END OF ty_s_width.
    TYPES temp7 TYPE STANDARD TABLE OF ty_s_width WITH DEFAULT KEY.
DATA lt_width TYPE temp7.
    TYPES temp8 TYPE STANDARD TABLE OF string_table WITH DEFAULT KEY.
DATA lt_cells TYPE temp8.
    DATA lt_cell  TYPE string_table.
    DATA lv_line  TYPE string.
    DATA lv_text  TYPE string.
    DATA lv_index TYPE i.
    DATA lv_total TYPE abap_bool.
    DATA lv_rank  TYPE i.
    DATA lv_count TYPE i.
    DATA lv_found TYPE abap_bool.
    DATA lr_copy  TYPE REF TO data.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF lt_comp.
      DATA temp245 TYPE ty_s_width.
        FIELD-SYMBOLS <temp246> LIKE LINE OF lt_width.
        DATA temp247 LIKE sy-tabix.
        FIELD-SYMBOLS <temp46> LIKE LINE OF lt_width.
        DATA temp47 LIKE sy-tabix.
    DATA lv_rows TYPE i.
    DATA lt_aggregate TYPE z2ui5_cl_cgui_alv=>ty_t_aggregate.
        DATA ls_aggregate LIKE LINE OF lt_aggregate.
        FIELD-SYMBOLS <temp248> LIKE LINE OF lt_width.
        DATA temp249 LIKE sy-tabix.
        FIELD-SYMBOLS <temp48> LIKE LINE OF lt_width.
        DATA temp49 LIKE sy-tabix.
      DATA lv_width TYPE ty_s_width-width.
      FIELD-SYMBOLS <temp50> LIKE LINE OF lt_width.
      DATA temp51 LIKE sy-tabix.
    DATA ls_header LIKE LINE OF mt_header.
      DATA temp250 TYPE string.
    DATA lv_rule TYPE string.
    DATA lt_values LIKE LINE OF lt_cells.
        DATA ls_width LIKE LINE OF lt_width.
        FIELD-SYMBOLS <temp52> LIKE LINE OF lt_width.
        DATA temp53 LIKE sy-tabix.
    DATA ls_footer LIKE LINE OF mt_footer.
      DATA temp251 TYPE string.

    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).


    lt_comp = columns_visible( tab ).

    LOOP AT lt_comp INTO ls_comp.

      CLEAR temp245.
      temp245-name = ls_comp-name.
      temp245-width = strlen( ls_comp-label ).
      temp245-right = is_numeric( ls_comp-type_kind ).
      INSERT temp245 INTO TABLE lt_width.
    ENDLOOP.

    LOOP AT <copy> ASSIGNING <row>.
      CLEAR lt_cell.
      LOOP AT lt_comp INTO ls_comp.
        lv_index = sy-tabix.
        CLEAR lv_text.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc = 0.
          lv_text = cell_to_text( val  = <cell>
                                  comp = ls_comp ).
        ENDIF.
        INSERT lv_text INTO TABLE lt_cell.


        temp247 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp246>.
        sy-tabix = temp247.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp47 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp46>.
        sy-tabix = temp47.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp246>-width = nmin( val1 = 40
                                           val2 = nmax( val1 = <temp46>-width
                                                        val2 = strlen( lv_text ) ) ).
      ENDLOOP.
      INSERT lt_cell INTO TABLE lt_cells.
    ENDLOOP.

    " the aggregates of the columns - a total, an average, a minimum, a
    " maximum or a count, as the grid shows them: a line per currency or
    " unit, the n-th line the n-th aggregate of each column

    lv_rows = lines( lt_cells ).

    lt_aggregate = get_aggregates( <copy> ).
    DO.
      lv_rank = sy-index.
      CLEAR: lt_cell, lv_found.
      LOOP AT lt_comp INTO ls_comp.
        lv_index = sy-tabix.
        CLEAR: lv_text, lv_count.

        LOOP AT lt_aggregate INTO ls_aggregate WHERE column = ls_comp-name.
          lv_count = lv_count + 1.
          IF lv_count = lv_rank.
            lv_text = aggregate_text( ls_aggregate ).
            lv_found = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
        INSERT lv_text INTO TABLE lt_cell.


        temp249 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp248>.
        sy-tabix = temp249.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp49 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp48>.
        sy-tabix = temp49.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp248>-width = nmax( val1 = <temp48>-width
                                           val2 = strlen( lv_text ) ).
      ENDLOOP.
      IF lv_found = abap_false.
        EXIT.
      ENDIF.
      lv_total = abap_true.
      INSERT lt_cell INTO TABLE lt_cells.
    ENDDO.

    " header, rule, rows, rule and totals
    LOOP AT lt_comp INTO ls_comp.
      lv_index = sy-tabix.



      temp51 = sy-tabix.
      READ TABLE lt_width INDEX lv_index ASSIGNING <temp50>.
      sy-tabix = temp51.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_width = <temp50>-width.
      lv_text = ls_comp-label.
      IF strlen( lv_text ) > lv_width.
        lv_text = substring( val = lv_text len = lv_width ).
      ENDIF.
      lv_line = |{ lv_line }{ lv_text WIDTH = lv_width } |.
    ENDLOOP.

    LOOP AT mt_header INTO ls_header.

      IF ls_header-label IS INITIAL.
        temp250 = ls_header-value.
      ELSE.
        temp250 = |{ ls_header-label }: { ls_header-value }|.
      ENDIF.
      INSERT temp250 INTO TABLE result.
    ENDLOOP.
    IF mt_header IS NOT INITIAL.
      INSERT `` INTO TABLE result.
    ENDIF.
    INSERT lv_line INTO TABLE result.

    lv_rule = repeat( val = `-` occ = strlen( lv_line ) ).
    INSERT lv_rule INTO TABLE result.


    LOOP AT lt_cells INTO lt_values.
      IF lv_total = abap_true AND sy-tabix = lv_rows + 1.
        INSERT lv_rule INTO TABLE result.
      ENDIF.
      CLEAR lv_line.
      LOOP AT lt_values INTO lv_text.
        lv_index = sy-tabix.



        temp53 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp52>.
        sy-tabix = temp53.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ls_width = <temp52>.
        IF strlen( lv_text ) > ls_width-width.
          lv_text = substring( val = lv_text len = ls_width-width ).
        ENDIF.
        IF ls_width-right = abap_true.
          lv_line = |{ lv_line }{ z2ui5_cl_cgui_context=>text_align( val   = lv_text
                                                                       width = ls_width-width
                                                                       align = `RIGHT` ) } |.
        ELSE.
          lv_line = |{ lv_line }{ lv_text WIDTH = ls_width-width } |.
        ENDIF.
      ENDLOOP.
      INSERT lv_line INTO TABLE result.
    ENDLOOP.

    IF mt_footer IS NOT INITIAL.
      INSERT `` INTO TABLE result.
    ENDIF.

    LOOP AT mt_footer INTO ls_footer.

      IF ls_footer-label IS INITIAL.
        temp251 = ls_footer-value.
      ELSE.
        temp251 = |{ ls_footer-label }: { ls_footer-value }|.
      ENDIF.
      INSERT temp251 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD to_xlsx.

    " The visible columns in the order of the layout, under their labels,
    " and the rows as the ALV sorts them - written by z2ui5_cl_cgui_xlsx: a
    " number is a number cell, a date a date, a time a time, a flag a
    " boolean, everything else text
    DATA lr_copy   TYPE REF TO data.
    DATA lt_column TYPE z2ui5_cl_cgui_xlsx=>ty_t_column.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    DATA temp252 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_visible LIKE LINE OF temp252.
      DATA lv_format TYPE string.
      DATA temp253 TYPE z2ui5_cl_cgui_xlsx=>ty_s_column.
    DATA temp254 TYPE z2ui5_cl_cgui_xlsx=>ty_s_layout.

    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).


    temp252 = columns_visible( tab ).

    LOOP AT temp252 INTO ls_visible.

      lv_format = ``.
      IF ls_visible-type_kind = cl_abap_typedescr=>typekind_packed AND ls_visible-decimals > 0.
        " the decimals the list shows, grouped and separated the way the
        " user's Excel is set up
        lv_format = |#,##0.{ repeat( val = `0`
                                     occ = ls_visible-decimals ) }|.
      ENDIF.

      CLEAR temp253.
      temp253-name = ls_visible-name.
      temp253-header = ls_visible-label.
      temp253-format = lv_format.
      INSERT temp253 INTO TABLE lt_column.
    ENDLOOP.
    IF lt_column IS INITIAL.
      " no column is shown: a sheet without a cell - an empty column list
      " would mean every field to the XLSX class
      result = z2ui5_cl_cgui_xlsx=>factory( )->get_xlsx( ).
      RETURN.
    ENDIF.


    CLEAR temp254.
    temp254-t_column = lt_column.
    result = z2ui5_cl_cgui_xlsx=>xlsx_by_itab( val    = <copy>
                                               layout = temp254 ).

  ENDMETHOD.

  METHOD column_get.

    DATA lv_name TYPE string.
      DATA temp255 TYPE z2ui5_cl_cgui_alv=>ty_s_column.
    lv_name = to_upper( name ).
    READ TABLE mt_column REFERENCE INTO result WITH KEY name = lv_name.
    IF sy-subrc <> 0.

      CLEAR temp255.
      temp255-name = lv_name.
      INSERT temp255 INTO TABLE mt_column REFERENCE INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD column_setting.

    READ TABLE mt_column INTO result WITH KEY name = name.

  ENDMETHOD.

  METHOD has_box_field.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA lv_box TYPE string.
    DATA temp256 LIKE sy-subrc.
    DATA temp33 TYPE xsdboolean.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    lv_box = get_box_field( ).

    READ TABLE lt_comp WITH KEY name = lv_box TRANSPORTING NO FIELDS.
    temp256 = sy-subrc.

    temp33 = boolc( temp256 = 0 ).
    result = temp33.

  ENDMETHOD.

  METHOD get_selected_rows.

    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <box> TYPE any.

    DATA lv_box TYPE string.
      DATA lv_index LIKE sy-tabix.
    lv_box = get_box_field( ).
    LOOP AT tab ASSIGNING <row>.

      lv_index = sy-tabix.
      ASSIGN COMPONENT lv_box OF STRUCTURE <row> TO <box>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF <box> IS NOT INITIAL.
        INSERT lv_index INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD select_all.

    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <box> TYPE any.

    DATA lv_box TYPE string.
    lv_box = get_box_field( ).
    LOOP AT tab ASSIGNING <row>.
      ASSIGN COMPONENT lv_box OF STRUCTURE <row> TO <box>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      <box> = val.
    ENDLOOP.

  ENDMETHOD.

  METHOD handle_event.
        DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
          FIELD-SYMBOLS <temp257> LIKE LINE OF lt_selected.
          DATA temp258 LIKE sy-tabix.

    result = abap_true.
    CASE client->get_event( ).
      WHEN cs_event-select_all.
        select_all( CHANGING tab = tab ).
      WHEN cs_event-deselect_all.
        select_all( EXPORTING val = abap_false
                    CHANGING  tab = tab ).
      WHEN cs_event-export.
        export( client = client
                tab    = tab ).
      WHEN cs_event-export_xlsx.
        export( client = client
                tab    = tab
                format = cs_format-xlsx ).
      WHEN cs_event-details.

        lt_selected = get_selected_rows( tab ).
        IF lt_selected IS NOT INITIAL.


          temp258 = sy-tabix.
          READ TABLE lt_selected INDEX 1 ASSIGNING <temp257>.
          sy-tabix = temp258.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          details_popup( client = client
                         tab    = tab
                         row    = <temp257> ).
        ENDIF.
      WHEN cs_event-details_close OR cs_event-chart_close.
        client->popup_destroy( ).
      WHEN cs_event-chart.
        CASE client->get_event_arg( 1 ).
          WHEN `CATEGORY`.
            mv_chart_category = to_upper( client->get_event_arg( 2 ) ).
          WHEN `VALUE`.
            mv_chart_value = to_upper( client->get_event_arg( 2 ) ).
          WHEN `VALUE2`.
            mv_chart_value2 = to_upper( client->get_event_arg( 2 ) ).
          WHEN `VALUE3`.
            mv_chart_value3 = to_upper( client->get_event_arg( 2 ) ).
          WHEN `KIND`.
            mv_chart_kind = to_upper( client->get_event_arg( 2 ) ).
        ENDCASE.
        chart_popup( client = client
                     tab    = tab ).
      WHEN cs_event-search.
        set_search( client->get_event_arg( ) ).
      WHEN OTHERS.
        result = abap_false.
    ENDCASE.

  ENDMETHOD.

  METHOD get_columns.

    result = columns_visible( tab ).

  ENDMETHOD.

  METHOD columns_visible.

    DATA lt_ordered TYPE ty_t_ordered.
    DATA lv_seq     TYPE i.

    " in the order of the components - a position set comes first
    DATA temp259 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp259.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp260 TYPE z2ui5_cl_cgui_alv=>ty_s_ordered.
      DATA temp54 TYPE z2ui5_cl_cgui_alv=>ty_s_ordered-position.
    DATA ls_ordered LIKE LINE OF lt_ordered.
    temp259 = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT temp259 INTO ls_comp.
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      lv_seq = lv_seq + 1.

      ls_column = column_setting( ls_comp-name ).
      IF ls_column-hidden = abap_true.
        CONTINUE.
      ENDIF.
      IF ls_column-text IS NOT INITIAL.
        ls_comp-label = ls_column-text.
      ENDIF.

      CLEAR temp260.

      IF ls_column-position > 0.
        temp54 = ls_column-position.
      ELSE.
        temp54 = 1000 + lv_seq.
      ENDIF.
      temp260-position = temp54.
      temp260-seq = lv_seq.
      temp260-comp = ls_comp.
      INSERT temp260 INTO TABLE lt_ordered.
    ENDLOOP.

    SORT lt_ordered BY position seq.

    LOOP AT lt_ordered INTO ls_ordered.
      INSERT ls_ordered-comp INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD render.

    FIELD-SYMBOLS <sums> TYPE STANDARD TABLE.

    DATA lv_rows LIKE mv_visible_rows.
    DATA lv_multi TYPE abap_bool.
    DATA temp34 TYPE xsdboolean.
    DATA lv_sorter TYPE string.
    DATA temp261 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp35 TYPE xsdboolean.
    DATA lv_fixed LIKE mv_fixed_columns.
      DATA temp262 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
      DATA ls_visible LIKE LINE OF temp262.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA temp263 LIKE sy-subrc.
    DATA temp264 TYPE i.
    lv_rows = mv_visible_rows.
    IF lv_rows <= 0.
      lv_rows = lines( tab ).
      IF lv_rows > 15.
        lv_rows = 15.
      ELSEIF lv_rows < 3.
        lv_rows = 3.
      ENDIF.
    ENDIF.



    temp34 = boolc( has_selection( ) = abap_true AND has_box_field( tab ) = abap_true ).
    lv_multi = temp34.

    lv_sorter = sorter( tab ).
    " a large table (set_paging) is bound with window_bind_tab( ): tab holds
    " the rows loaded so far in the order the app loaded them (window_order( )),
    " total the rows there are - a sorter in the binding would order the
    " loaded rows alone. More rows, and a sort or a filter of a column menu,
    " come back as cs_event-rows. total is passed on as it is: an attribute
    " of the app is read anew with every response

    render_header( node ).


    IF mv_page_size > 0 AND total >= 0.
      temp261 = client->window_bind_tab( val = tab total = total event = cs_event-rows window = mv_page_size ).
    ELSEIF mv_page_size > 0.
      temp261 = client->window_bind_tab( val = tab total = lines( tab ) event = cs_event-rows window = mv_page_size ).
    ELSEIF lv_sorter IS INITIAL.
      temp261 = client->_bind( tab ).
    ELSE.
      temp261 = |\{path: '{ client->_bind_path( tab ) }', sorter: { lv_sorter }\}|.
    ENDIF.


    temp35 = boolc( mv_no_stripes = abap_false ).
    lo_table = node->ele( n = `Table` ns = `table`
        )->a( n = `xmlns:table`        v = `sap.ui.table`
        )->a( n = `xmlns:core`         v = `sap.ui.core`
        )->a( n = `core:require`       v = type_require( )
        )->a( n = `rows`               v = temp261
        )->a( n = `selectionMode`      v = `None`
        )->a( n = `alternateRowColors` b = temp35
        )->a( n = `visibleRowCount`    v = |{ lv_rows }|
        )->a( n = `class`              v = `sapUiSmallMargin` ).

    " the attributes of the table before its first child: a( ) lands on the
    " child added last
    IF mv_line_selection = abap_true.
      lo_table->a( n = `cellClick` v = client->_event( val = cs_event-line_selection
                                                       arg = `${$parameters>/rowBindingContext}.getPath()` ) ).
    ENDIF.

    " fixed: as set, or the key columns from the left

    lv_fixed = mv_fixed_columns.
    IF lv_fixed = 0.

      temp262 = columns_visible( tab ).

      LOOP AT temp262 INTO ls_visible.
        IF column_setting( ls_visible-name )-key = abap_false.
          EXIT.
        ENDIF.
        lv_fixed = lv_fixed + 1.
      ENDLOOP.
      IF lv_fixed > 0 AND lv_multi = abap_true.
        lv_fixed = lv_fixed + 1.
      ENDIF.
    ENDIF.
    IF lv_fixed > 0.
      lo_table->a( n = `fixedColumnCount` v = |{ lv_fixed }| ).
    ENDIF.


    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    READ TABLE lt_comp WITH KEY name = mv_color_field TRANSPORTING NO FIELDS.
    temp263 = sy-subrc.
    IF mv_color_field IS NOT INITIAL AND temp263 = 0.
      lo_table->ele( n = `rowSettingsTemplate` ns = `table`
          )->tag( n = `RowSettings` ns = `table`
          )->a( n = `highlight` v = color_binding( mv_color_field ) ).
    ENDIF.


    IF total >= 0.
      temp264 = total.
    ELSE.
      temp264 = lines( tab ).
    ENDIF.
    render_toolbar( node   = lo_table->ele( n = `extension` ns = `table` )
                    client = client
                    multi  = lv_multi
                    total  = temp264
                    all    = all ).

    render_columns( node   = lo_table->ele( n = `columns` ns = `table` )
                    client = client
                    tab    = tab
                    multi  = lv_multi ).

    " the totals of all rows - a paged grid holds the first ones only
    IF sums IS BOUND.
      ASSIGN sums->* TO <sums>.
    ELSE.
      ASSIGN tab TO <sums>.
    ENDIF.
    render_sums( node = node
                 tab  = <sums> ).

    render_subtotals( node = node
                      tab  = <sums> ).

    render_header( node  = node
                   items = mt_footer ).

  ENDMETHOD.

  METHOD render_toolbar.

    DATA lo_bar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_count TYPE string.
      DATA temp265 TYPE string.
      DATA temp55 TYPE string.
      DATA temp266 TYPE string.
      DATA temp267 TYPE string.
      DATA temp268 TYPE string.
      DATA temp56 TYPE string.
      DATA temp1 TYPE string.
        DATA temp269 TYPE string.
      DATA temp270 TYPE string.
      DATA temp271 TYPE string.
      DATA temp272 TYPE string.
      DATA temp57 TYPE string.
    lo_bar = node->ele( `OverflowToolbar` ).

    lv_count = |{ total }|.
    IF all >= 0 AND all <> total.
      lv_count = replace( val  = replace( val  = '&1 of &2'(009)
                                          sub  = `&1`
                                          with = |{ total }| )
                          sub  = `&2`
                          with = |{ all }| ).
    ENDIF.
    lo_bar->tag( `Title`
        )->a( n = `text` t = |{ mv_title } ({ lv_count })|
        )->tag( `ToolbarSpacer` ).


    IF multi = abap_true.

      temp265 = 'Select All'(001).

      temp55 = 'Deselect All'(002).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://multiselect-all`
          )->a( n = `tooltip` t = temp265
          )->a( n = `press`   v = client->_event( cs_event-select_all )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://multiselect-none`
          )->a( n = `tooltip` t = temp55
          )->a( n = `press`   v = client->_event( cs_event-deselect_all ) ).
    ENDIF.

    render_functions( bar       = lo_bar
                      client    = client
                      functions = mt_function ).

    IF mv_no_search = abap_false.

      temp266 = 'Search'(014).
      lo_bar->tag( `SearchField`
          )->a( n = `value`       t = mv_search
          )->a( n = `width`       v = `14rem`
          )->a( n = `placeholder` t = temp266
          )->a( n = `search`      v = client->_event( val = cs_event-search
                                                      arg = `${$parameters>/query}` ) ).
    ENDIF.

    IF multi = abap_true AND mv_no_details = abap_false.

      temp267 = 'Details'(012).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://detail-view`
          )->a( n = `tooltip` t = temp267
          )->a( n = `press`   v = client->_event( cs_event-details ) ).
    ENDIF.

    IF mv_no_filter = abap_false.

      temp268 = 'Filter'(010).

      IF mt_filter IS NOT INITIAL.
        temp56 = |{ lines( mt_filter ) }|.
      ELSE.
        CLEAR temp56.
      ENDIF.

      IF mt_filter IS NOT INITIAL.
        temp1 = `Emphasized`.
      ELSE.
        temp1 = `Default`.
      ENDIF.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://filter`
          )->a( n = `text`    v = temp56
          )->a( n = `type`    v = temp1
          )->a( n = `tooltip` t = temp268
          )->a( n = `press`   v = client->_event( cs_event-filter ) ).
      IF is_filtered( ) = abap_true.

        temp269 = 'Delete Filter'(011).
        lo_bar->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://clear-filter`
            )->a( n = `tooltip` t = temp269
            )->a( n = `press`   v = client->_event( cs_event-filter_clear ) ).
      ENDIF.
    ENDIF.

    IF mv_no_layout = abap_false.

      temp270 = 'Change Layout'(005).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://action-settings`
          )->a( n = `tooltip` t = temp270
          )->a( n = `press`   v = client->_event( cs_event-layout ) ).
    ENDIF.

    IF mv_no_chart = abap_false.

      temp271 = 'Chart'(019).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://bar-chart`
          )->a( n = `tooltip` t = temp271
          )->a( n = `press`   v = client->_event( cs_event-chart ) ).
    ENDIF.

    IF mv_no_export = abap_false.

      temp272 = 'Export to Excel'(006).

      temp57 = 'Export'(003).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://excel-attachment`
          )->a( n = `tooltip` t = temp272
          )->a( n = `press`   v = client->_event( cs_event-export_xlsx )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://document-text`
          )->a( n = `tooltip` t = temp57
          )->a( n = `press`   v = client->_event( cs_event-export ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_columns.
    DATA temp273 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp273.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp274 TYPE string.
      DATA lv_align LIKE temp274.
      DATA lv_width LIKE ls_column-width.
      DATA lo_column TYPE REF TO z2ui5_cl_ui5_view_builder.
        DATA temp275 TYPE string.
      DATA temp276 TYPE string.

    IF multi = abap_true AND mv_selection_mode = cs_selection_mode-single.
      node->ele( n = `Column` ns = `table`
          )->a( n = `width`  v = `3rem`
          )->a( n = `hAlign` v = `Center`
          )->ele( n = `template` ns = `table`
              )->tag( `RadioButton`
              )->a( n = `groupName` v = `cgui_alv_single`
              )->a( n = `selected`  v = |\{{ z2ui5_cl_ui5_view_builder=>component_path( get_box_field( ) ) }\}| ).
    ELSEIF multi = abap_true.
      node->ele( n = `Column` ns = `table`
          )->a( n = `width`  v = `3rem`
          )->a( n = `hAlign` v = `Center`
          )->ele( n = `template` ns = `table`
              )->tag( `CheckBox`
              )->a( n = `selected` v = |\{{ z2ui5_cl_ui5_view_builder=>component_path( get_box_field( ) ) }\}| ).
    ENDIF.


    temp273 = columns_visible( tab ).

    LOOP AT temp273 INTO ls_comp.


      ls_column = column_setting( ls_comp-name ).


      IF is_numeric( ls_comp-type_kind ) = abap_true.
        temp274 = `End`.
      ELSE.
        temp274 = `Begin`.
      ENDIF.

      lv_align = temp274.
      IF ls_column-icon = abap_true OR ls_comp-boolean = abap_true.
        lv_align = `Center`.
      ENDIF.
      IF ls_column-align IS NOT INITIAL.
        lv_align = ls_column-align.
      ENDIF.


      lv_width = ls_column-width.
      IF lv_width IS INITIAL AND mv_no_optimize = abap_false.
        lv_width = column_width( comp = ls_comp
                                 tab  = tab ).
      ENDIF.


      lo_column = node->ele( n = `Column` ns = `table`
          )->a( n = `sortProperty` t = z2ui5_cl_ui5_view_builder=>component_path( ls_comp-name )
          )->a( n = `hAlign`       v = lv_align ).
      " the filter of a column menu reaches the backend through the paged
      " binding only (window_request( )) - without paging it filtered the
      " rows of the browser alone, and Select All, print, export and the
      " totals ran on rows the user did not see: there the filter of the
      " grid (the toolbar) is the one
      IF mv_page_size > 0.
        lo_column->a( n = `filterProperty` t = z2ui5_cl_ui5_view_builder=>component_path( ls_comp-name ) ).
      ENDIF.
      IF lv_width IS NOT INITIAL.
        lo_column->a( n = `width` t = lv_width ).
      ENDIF.
      IF ls_column-sort IS NOT INITIAL.

        IF ls_column-sort = cs_sort-descending.
          temp275 = `Descending`.
        ELSE.
          temp275 = `Ascending`.
        ENDIF.
        lo_column->a( n = `sorted`    b = abap_true
            )->a( n = `sortOrder` v = temp275 ).
      ENDIF.
      " the tooltip of the column - before its label: a( ) goes to the last
      " child of a node that has one
      IF ls_column-tooltip IS NOT INITIAL.
        lo_column->a( n = `tooltip` t = ls_column-tooltip ).
      ENDIF.


      IF ls_column-key = abap_true.
        temp276 = `Bold`.
      ELSE.
        temp276 = `Standard`.
      ENDIF.
      lo_column->ele( n = `label` ns = `table`
          )->tag( `Label`
              )->a( n = `text`   t = ls_comp-label
              )->a( n = `design` v = temp276 ).

      render_template( node   = lo_column->ele( n = `template` ns = `table` )
                       client = client
                       comp   = ls_comp
                       column = ls_column ).

    ENDLOOP.

  ENDMETHOD.

  METHOD render_template.

    " the binding path of the column - a namespace's leading slash dropped:
    " /ABC/FIELD is the member FIELD of ABC, not an absolute path
    DATA lv_path TYPE string.
        DATA temp277 TYPE string_table.
        DATA temp279 TYPE string_table.
        DATA lt_value TYPE z2ui5_cl_cgui_alv=>ty_t_value.
        DATA lv_expr TYPE string.
        DATA ls_value LIKE LINE OF lt_value.
      DATA temp281 TYPE string_table.
      DATA temp283 TYPE string.
    lv_path = z2ui5_cl_ui5_view_builder=>component_path( comp-name ).

    IF column_editable( column ) = abap_true.
      render_edit( node   = node
                   client = client
                   comp   = comp
                   column = column ).
      RETURN.
    ENDIF.

    CASE column-cell_type.
      WHEN cs_cell_type-checkbox_hotspot.
        " a checkbox that can be clicked - the value changes, the event follows

        CLEAR temp277.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp277.
        INSERT comp-name INTO TABLE temp277.
        node->tag( `CheckBox`
            )->a( n = `selected` v = |\{{ lv_path }\}|
            )->a( n = `select`   v = client->_event( val   = cs_event-hotspot
                                                     t_arg = temp277 ) ).
        RETURN.
      WHEN cs_cell_type-button.

        CLEAR temp279.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp279.
        INSERT comp-name INTO TABLE temp279.
        node->tag( `Button`
            )->a( n = `text`  v = cell_binding( comp   = comp
                                                column = column )
            )->a( n = `press` v = client->_event( val   = cs_event-hotspot
                                                  t_arg = temp279 ) ).
        RETURN.
      WHEN cs_cell_type-dropdown.
        " shown: the text of the key

        lt_value = dropdown_values( comp-name ).

        lv_expr = |$\{{ lv_path }\}|.

        LOOP AT lt_value INTO ls_value.
          lv_expr = |$\{{ lv_path }\} === '{ expr_escape( ls_value-key ) }' ? '{ expr_escape( ls_value-text ) }' : { lv_expr }|.
        ENDLOOP.
        node->tag( `Text`
            )->a( n = `text`     v = |\{= { lv_expr } \}|
            )->a( n = `wrapping` b = abap_false ).
        RETURN.
    ENDCASE.

    IF column-icon = abap_true.
      node->tag( n = `Icon` ns = `core`
          )->a( n = `src` v = |\{{ lv_path }\}| ).
      RETURN.
    ENDIF.

    IF comp-boolean = abap_true.
      node->tag( `CheckBox`
          )->a( n = `selected` v = |\{= $\{{ lv_path }\} === true \|\| $\{{ lv_path }\} === 'X' \}|
          )->a( n = `editable` b = abap_false ).
      RETURN.
    ENDIF.

    IF column-hotspot = abap_true.

      CLEAR temp281.
      INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp281.
      INSERT comp-name INTO TABLE temp281.
      node->tag( `Link`
          )->a( n = `text`  v = cell_binding( comp   = comp
                                              column = column )
          )->a( n = `press` v = client->_event( val   = cs_event-hotspot
                                                t_arg = temp281 ) ).
      RETURN.
    ENDIF.

    IF column-color IS NOT INITIAL OR column-color_field IS NOT INITIAL.

      IF column-color_field IS NOT INITIAL.
        temp283 = color_binding( column-color_field ).
      ELSE.
        temp283 = color_state( column-color ).
      ENDIF.
      node->tag( `ObjectStatus`
          )->a( n = `text`  v = cell_binding( comp   = comp
                                              column = column )
          )->a( n = `state` v = temp283 ).
      RETURN.
    ENDIF.

    node->tag( `Text`
        )->a( n = `text`     v = cell_binding( comp   = comp
                                               column = column )
        )->a( n = `wrapping` b = abap_false ).
    " NO_ZERO: a zero is not shown
    IF column-no_zero = abap_true AND is_numeric( comp-type_kind ) = abap_true.
      node->a( n = `visible` v = |\{= Number($\{{ lv_path }\}) !== 0 \}| ).
    ELSEIF column-no_zero = abap_true AND comp-type_kind = cl_abap_typedescr=>typekind_num.
      node->a( n = `visible` v = |\{= !/^0*$/.test($\{{ lv_path }\}) \}| ).
    ENDIF.

  ENDMETHOD.

  METHOD render_edit.

    " the binding path of the column - a namespace's leading slash dropped:
    " /ABC/FIELD is the member FIELD of ABC, not an absolute path
    DATA lv_path TYPE string.
    DATA lv_editable TYPE string.
      DATA temp284 TYPE string_table.
      DATA lo_select TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp286 TYPE z2ui5_cl_cgui_alv=>ty_t_value.
      DATA ls_value LIKE LINE OF temp286.
      DATA temp287 TYPE string_table.
        DATA temp289 TYPE string_table.
        DATA temp291 TYPE string_table.
          DATA temp293 TYPE string_table.
            DATA temp295 TYPE string_table.
          DATA temp297 TYPE string_table.
            DATA temp299 TYPE string_table.
    lv_path = z2ui5_cl_ui5_view_builder=>component_path( comp-name ).


    lv_editable = edit_binding( ).

    IF column-cell_type = cs_cell_type-dropdown.

      CLEAR temp284.
      INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp284.
      INSERT comp-name INTO TABLE temp284.

      lo_select = node->ele( `Select`
          )->a( n = `selectedKey`    v = |\{{ lv_path }\}|
          )->a( n = `forceSelection` b = abap_false
          )->a( n = `change`         v = client->_event( val   = cs_event-data_changed
                                                         t_arg = temp284 ) ).
      IF lv_editable IS NOT INITIAL.
        lo_select->a( n = `enabled` v = lv_editable ).
      ENDIF.

      lo_items = lo_select->ele( `items` ).
      lo_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = ``
          )->a( n = `text` v = `` ).

      temp286 = dropdown_values( comp-name ).

      LOOP AT temp286 INTO ls_value.
        lo_items->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_value-key
            )->a( n = `text` t = ls_value-text ).
      ENDLOOP.
      RETURN.
    ENDIF.

    IF comp-boolean = abap_true.

      CLEAR temp287.
      INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp287.
      INSERT comp-name INTO TABLE temp287.
      node->tag( `CheckBox`
          )->a( n = `selected` v = |\{{ lv_path }\}|
          )->a( n = `select`   v = client->_event( val   = cs_event-data_changed
                                                   t_arg = temp287 ) ).
      IF lv_editable IS NOT INITIAL.
        node->a( n = `editable` v = lv_editable ).
      ENDIF.
      RETURN.
    ENDIF.

    CASE comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.

        CLEAR temp289.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp289.
        INSERT comp-name INTO TABLE temp289.
        node->tag( `DatePicker`
            )->a( n = `value`         v = |\{{ lv_path }\}|
            )->a( n = `valueFormat`   v = `yyyy-MM-dd`
            )->a( n = `displayFormat` v = `medium`
            )->a( n = `change`        v = client->_event( val   = cs_event-data_changed
                                                          t_arg = temp289 ) ).
        IF lv_editable IS NOT INITIAL.
          node->a( n = `editable` v = lv_editable ).
        ENDIF.
      WHEN cl_abap_typedescr=>typekind_time.

        CLEAR temp291.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp291.
        INSERT comp-name INTO TABLE temp291.
        node->tag( `TimePicker`
            )->a( n = `value`         v = |\{{ lv_path }\}|
            )->a( n = `valueFormat`   v = `HH:mm:ss`
            )->a( n = `displayFormat` v = `HH:mm:ss`
            )->a( n = `change`        v = client->_event( val   = cs_event-data_changed
                                                          t_arg = temp291 ) ).
        IF lv_editable IS NOT INITIAL.
          node->a( n = `editable` v = lv_editable ).
        ENDIF.
      WHEN OTHERS.
        IF is_numeric( comp-type_kind ) = abap_true.

          CLEAR temp293.
          INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp293.
          INSERT comp-name INTO TABLE temp293.
          node->tag( `Input`
              )->a( n = `value`     v = cell_binding( comp   = comp
                                                      column = column )
              )->a( n = `textAlign` v = `End`
              )->a( n = `change`    v = client->_event( val   = cs_event-data_changed
                                                        t_arg = temp293 ) ).
          IF column-f4 = abap_true.

            CLEAR temp295.
            INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp295.
            INSERT comp-name INTO TABLE temp295.
            node->a( n = `showValueHelp`    b = abap_true
                )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                                 t_arg = temp295 ) ).
          ENDIF.
          IF lv_editable IS NOT INITIAL.
            node->a( n = `editable` v = lv_editable ).
          ENDIF.
        ELSE.

          CLEAR temp297.
          INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp297.
          INSERT comp-name INTO TABLE temp297.
          node->tag( `Input`
              )->a( n = `value`  v = |\{{ lv_path }\}|
              )->a( n = `change` v = client->_event( val   = cs_event-data_changed
                                                     t_arg = temp297 ) ).
          IF column-f4 = abap_true.

            CLEAR temp299.
            INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp299.
            INSERT comp-name INTO TABLE temp299.
            node->a( n = `showValueHelp`    b = abap_true
                )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                                 t_arg = temp299 ) ).
          ENDIF.
          IF lv_editable IS NOT INITIAL.
            node->a( n = `editable` v = lv_editable ).
          ENDIF.
          IF comp-type_kind = cl_abap_typedescr=>typekind_char AND comp-length > 0.
            node->a( n = `maxLength` v = |{ comp-length }| ).
          ENDIF.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD render_subtotals.

    DATA lt_subtotal TYPE z2ui5_cl_cgui_alv=>ty_t_subtotal.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA lt_group LIKE lt_layout.
    DATA lt_text TYPE string_table.
    DATA ls_group LIKE LINE OF lt_group.
    DATA lt_summed LIKE lt_layout.
    DATA temp301 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_summed LIKE LINE OF lt_summed.
    DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_group TYPE string.
    DATA lv_number TYPE string.
    DATA lo_cells TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_numbers TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lt_value TYPE ty_t_subtotal.
    DATA ls_subtotal LIKE LINE OF lt_subtotal.
          DATA ls_value LIKE LINE OF lt_subtotal.
            DATA temp302 TYPE z2ui5_cl_cgui_alv=>ty_s_subtotal.
            DATA temp303 TYPE string.
    lt_subtotal = get_subtotals( tab ).
    IF lt_subtotal IS INITIAL.
      RETURN.
    ENDIF.


    lt_layout = get_layout( tab ).

    lt_group = lt_layout.
    DELETE lt_group WHERE subtotal = abap_false OR sort IS INITIAL.
    SORT lt_group BY sort_seq name.


    LOOP AT lt_group INTO ls_group.
      INSERT ls_group-text INTO TABLE lt_text.
    ENDLOOP.

    lt_summed = lt_layout.
    DELETE lt_summed WHERE sum = abap_false OR hidden = abap_true.


    temp301 = 'Subtotals'(007).

    lo_table = node->ele( `Table`
        )->a( n = `headerText` t = temp301
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    lo_columns = lo_table->ele( `columns` ).
    lo_columns->ele( `Column`
        )->tag( `Text`
        )->a( n = `text` t = concat_lines_of( table = lt_text sep = ` / ` ) ).

    LOOP AT lt_summed INTO ls_summed.
      lo_columns->ele( `Column`
          )->a( n = `hAlign` v = `End`
          )->tag( `Text`
          )->a( n = `text` t = ls_summed-text ).
    ENDLOOP.


    lo_items = lo_table->ele( `items` ).






    LOOP AT lt_subtotal INTO ls_subtotal.
      IF lo_cells IS NOT BOUND OR ls_subtotal-group <> lv_group.
        lv_group = ls_subtotal-group.
        lo_cells = lo_items->ele( `ColumnListItem` )->ele( `cells` ).
        lo_cells->tag( `Text`
            )->a( n = `text` t = lv_group ).
        LOOP AT lt_summed INTO ls_summed.
          " one number per currency or unit of the group - stacked where
          " the group has several
          CLEAR lt_value.

          LOOP AT lt_subtotal INTO ls_value WHERE group = lv_group AND column = ls_summed-name.
            INSERT ls_value INTO TABLE lt_value.
          ENDLOOP.
          IF lines( lt_value ) > 1.
            lo_numbers = lo_cells->ele( `VBox` )->a( n = `alignItems` v = `End` ).
          ELSE.
            lo_numbers = lo_cells.
          ENDIF.
          IF lt_value IS INITIAL.

            CLEAR temp302.
            INSERT temp302 INTO TABLE lt_value.
          ENDIF.
          LOOP AT lt_value INTO ls_value.

            IF ls_value-column IS NOT INITIAL.
              temp303 = |{ ls_value-value NUMBER = USER }|.
            ELSE.
              CLEAR temp303.
            ENDIF.
            lv_number = temp303.
            lo_numbers->tag( `ObjectNumber`
                )->a( n = `number`     t = lv_number
                )->a( n = `emphasized` b = abap_true ).
            IF ls_value-unit IS NOT INITIAL.
              lo_numbers->a( n = `unit` t = ls_value-unit ).
            ENDIF.
          ENDLOOP.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD cell_binding.

    result = z2ui5_cl_cgui_context=>ui5_binding_by_kind(
                 path          = z2ui5_cl_ui5_view_builder=>component_path( comp-name )
                 type_kind     = comp-type_kind
                 decimals      = comp-decimals
                 currency_path = z2ui5_cl_ui5_view_builder=>component_path( column-currency )
                 unit_path     = z2ui5_cl_ui5_view_builder=>component_path( column-quantity ) ).

  ENDMETHOD.

  METHOD column_width.

    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    DATA lv_len TYPE i.

    IF comp-boolean = abap_true.
      result = `5rem`.
      RETURN.
    ENDIF.


    lv_len = strlen( comp-label ).
    CASE comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        lv_len = nmax( val1 = lv_len val2 = 12 ).
      WHEN cl_abap_typedescr=>typekind_time.
        lv_len = nmax( val1 = lv_len val2 = 9 ).
      WHEN OTHERS.
        LOOP AT tab ASSIGNING <row> TO 200.
          ASSIGN COMPONENT comp-name OF STRUCTURE <row> TO <cell>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.
          lv_len = nmax( val1 = lv_len val2 = strlen( cell_to_text( val  = <cell>
                                                                     comp = comp ) ) ).
        ENDLOOP.
    ENDCASE.

    IF lv_len > 50.
      lv_len = 50.
    ENDIF.
    " a character of the theme font is about half a rem wide, plus the
    " padding of the cell and room for the sort indicator
    result = |{ lv_len * 6 / 10 + 2 }rem|.

  ENDMETHOD.

  METHOD aggregate_text.

    DATA temp304 TYPE i.
    DATA temp58 TYPE string.
    temp304 = aggregate-value.

    IF aggregate-aggregation = cs_aggregation-count.
      temp58 = |{ temp304 NUMBER = USER }|.
    ELSEIF aggregate-aggregation = cs_aggregation-average.
      temp58 = |{ aggregate-value NUMBER = USER DECIMALS = 2 }|.
    ELSE.
      temp58 = |{ aggregate-value NUMBER = USER }|.
    ENDIF.
    result = temp58.
    IF aggregate-unit IS NOT INITIAL.
      result = |{ result } { aggregate-unit }|.
    ENDIF.

  ENDMETHOD.

  METHOD cell_to_text.

    DATA lv_date   TYPE d.
    DATA lv_time   TYPE t.
    DATA lv_number TYPE decfloat34.
          DATA temp305 TYPE string.

    CASE comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        lv_date = val.
        IF lv_date IS NOT INITIAL.
          result = |{ lv_date DATE = USER }|.
        ENDIF.
      WHEN cl_abap_typedescr=>typekind_time.
        lv_time = val.
        result = |{ lv_time TIME = USER }|.
      WHEN cl_abap_typedescr=>typekind_packed.
        lv_number = val.
        result = |{ lv_number NUMBER = USER DECIMALS = comp-decimals }|.
      WHEN OTHERS.
        IF is_numeric( comp-type_kind ) = abap_true.
          lv_number = val.
          result = |{ lv_number NUMBER = USER }|.
        ELSEIF comp-boolean = abap_true.

          IF val IS NOT INITIAL.
            temp305 = `X`.
          ELSE.
            CLEAR temp305.
          ENDIF.
          result = temp305.
        ELSE.
          result = |{ val }|.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD render_sums.

    DATA lo_sums TYPE REF TO z2ui5_cl_ui5_view_builder.

    DATA temp306 TYPE z2ui5_cl_cgui_alv=>ty_t_aggregate.
    DATA ls_aggregate LIKE LINE OF temp306.
      DATA temp307 TYPE string.
      DATA lv_title LIKE temp307.
      DATA lv_value TYPE string.
    temp306 = get_aggregates( tab ).

    LOOP AT temp306 INTO ls_aggregate.
      IF lo_sums IS NOT BOUND.
        lo_sums = node->ele( `HBox`
            )->a( n = `justifyContent` v = `End`
            )->a( n = `wrap`           v = `Wrap`
            )->a( n = `class`          v = `sapUiSmallMarginEnd` ).
      ENDIF.

      CASE ls_aggregate-aggregation.
        WHEN cs_aggregation-average.
          temp307 = 'Average'(015).
        WHEN cs_aggregation-minimum.
          temp307 = 'Minimum'(016).
        WHEN cs_aggregation-maximum.
          temp307 = 'Maximum'(017).
        WHEN cs_aggregation-count.
          temp307 = 'Count'(018).
        WHEN OTHERS.
          temp307 = 'Total'(004).
      ENDCASE.

      lv_title = temp307.

      lv_value = aggregate_text( ls_aggregate ).
      lo_sums->tag( `ObjectStatus`
          )->a( n = `title` t = |{ lv_title } { ls_aggregate-label }|
          )->a( n = `text`  t = lv_value
          )->a( n = `state` v = `Information`
          )->a( n = `class` v = `sapUiSmallMarginBegin` ).
    ENDLOOP.

  ENDMETHOD.

  METHOD to_csv.

    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    DATA lt_line TYPE string_table.
    DATA lt_cell TYPE string_table.
    DATA lr_copy TYPE REF TO data.
    DATA lv_sep LIKE mv_separator.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF lt_comp.
    DATA temp1 TYPE string.
      DATA temp2 TYPE string.

    " in the order of the layout, as to_text( ) and to_xlsx( ) have it
    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).


    lv_sep = mv_separator.
    IF lv_sep IS INITIAL.
      lv_sep = `;`.
    ENDIF.

    lt_comp = columns_visible( tab ).


    LOOP AT lt_comp INTO ls_comp.
      INSERT csv_escape( val       = ls_comp-label
                         separator = lv_sep ) INTO TABLE lt_cell.
    ENDLOOP.

    temp1 = concat_lines_of( table = lt_cell sep = lv_sep ).
    INSERT temp1 INTO TABLE lt_line.

    LOOP AT <copy> ASSIGNING <row>.
      CLEAR lt_cell.
      LOOP AT lt_comp INTO ls_comp.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          INSERT `` INTO TABLE lt_cell.
          CONTINUE.
        ENDIF.
        INSERT csv_escape( val       = cell_to_text( val  = <cell>
                                                     comp = ls_comp )
                           separator = lv_sep ) INTO TABLE lt_cell.
      ENDLOOP.

      temp2 = concat_lines_of( table = lt_cell sep = lv_sep ).
      INSERT temp2 INTO TABLE lt_line.
    ENDLOOP.

    result = concat_lines_of( table = lt_line sep = |\r\n| ).

  ENDMETHOD.

  METHOD csv_escape.

    result = val.
    IF result CA |"\r\n| OR result CS separator.
      result = |"{ replace( val = result sub = `"` with = `""` occ = 0 ) }"|.
    ENDIF.

  ENDMETHOD.

  METHOD export.

    DATA lv_name LIKE mv_title.
      DATA lv_xlsx TYPE xstring.
        DATA temp308 TYPE string_table.
        DATA temp59 LIKE LINE OF temp308.
        DATA temp60 LIKE LINE OF temp308.
    DATA lv_csv TYPE xstring.
    DATA temp310 TYPE xstring.
    DATA lv_bom LIKE temp310.
    DATA temp311 TYPE string_table.
    DATA temp61 LIKE LINE OF temp311.
    DATA temp62 LIKE LINE OF temp311.
    lv_name = mv_title.
    IF lv_name IS INITIAL.
      lv_name = `export`.
    ENDIF.

    IF to_upper( format ) = cs_format-xlsx.

      lv_xlsx = to_xlsx( tab ).
      IF lv_xlsx IS NOT INITIAL.

        CLEAR temp308.

        temp59 = |data:{ z2ui5_cl_cgui_xlsx=>mime_type };base64,| && z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_xlsx ).
        INSERT temp59 INTO TABLE temp308.

        temp60 = |{ lv_name }.xlsx|.
        INSERT temp60 INTO TABLE temp308.
        client->follow_up_action( val   = client->cs_event-download_b64_file
                                  t_arg = temp308 ).
        RETURN.
      ENDIF.
    ENDIF.

    " UTF-8 with a byte order mark - Excel reads the umlauts right then

    lv_csv = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( to_csv( tab ) ).

    temp310 = `EFBBBF`.

    lv_bom = temp310.
    CONCATENATE lv_bom lv_csv INTO lv_csv IN BYTE MODE.


    CLEAR temp311.

    temp61 = |data:text/csv;charset=utf-8;base64,{ z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_csv ) }|.
    INSERT temp61 INTO TABLE temp311.

    temp62 = |{ lv_name }.csv|.
    INSERT temp62 INTO TABLE temp311.
    client->follow_up_action( val   = client->cs_event-download_b64_file
                              t_arg = temp311 ).

  ENDMETHOD.

  METHOD type_require.

    result = z2ui5_cl_cgui_context=>ui5_get_type_require( ).

  ENDMETHOD.

  METHOD stringify.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height`       v = `100%` ).


    page = view->ele( `Page`
        )->a( n = `title` t = mv_title ).

    render( node   = page
            client = client
            tab    = tab ).

    result = view->stringify( ).

  ENDMETHOD.

  METHOD is_grid_event.

    " a CASE, not xsdbool( a OR b OR ... ): the 7.02 downport writes that
    " expression on one line - 449 characters here - and a 7.02 system cuts
    " a line of more than 255 on import
    CASE event.
      WHEN cs_event-select_all
          OR cs_event-deselect_all
          OR cs_event-export
          OR cs_event-export_xlsx
          OR cs_event-layout
          OR cs_event-page
          OR cs_event-filter
          OR cs_event-filter_clear
          OR cs_event-details
          OR cs_event-details_close
          OR cs_event-chart
          OR cs_event-chart_close
          OR cs_event-search
          OR cs_event-f4
          OR cs_event-rows.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD box_copy.

    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA lv_flag TYPE abap_bool.
    DATA lr_row  TYPE REF TO data.
    DATA lt_selected TYPE ty_t_row.
    FIELD-SYMBOLS <src> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <old> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <box> TYPE any.
    DATA temp313 TYPE REF TO cl_abap_structdescr.
    DATA temp63 TYPE REF TO cl_abap_tabledescr.
    DATA lo_line LIKE temp313.
    DATA temp314 TYPE abap_componentdescr.
    DATA temp64 TYPE REF TO cl_abap_datadescr.
    DATA lo_type TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <line> TYPE ANY.
      DATA lv_index LIKE sy-tabix.
      DATA temp315 LIKE sy-subrc.
      DATA temp316 LIKE sy-tabix.

    ASSIGN source->* TO <src>.
    IF old IS BOUND.
      ASSIGN old->* TO <old>.
      IF lines( <old> ) = lines( <src> ).
        lt_selected = get_selected_rows( <old> ).
      ENDIF.
    ENDIF.



    temp63 ?= cl_abap_typedescr=>describe_by_data( <src> ).
    temp313 ?= temp63->get_table_line_type( ).

    lo_line = temp313.
    lt_comp = lo_line->get_components( ).

    CLEAR temp314.
    temp314-name = cv_box_field.

    temp64 ?= cl_abap_typedescr=>describe_by_data( lv_flag ).
    temp314-type = temp64.
    INSERT temp314 INTO TABLE lt_comp.

    lo_type = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
    CREATE DATA result TYPE HANDLE lo_type.
    ASSIGN result->* TO <copy>.


    LOOP AT <src> ASSIGNING <line>.

      lv_index = sy-tabix.
      CREATE DATA lr_row LIKE LINE OF <copy>.
      ASSIGN lr_row->* TO <row>.
      MOVE-CORRESPONDING <line> TO <row>.


      temp316 = sy-tabix.
      READ TABLE lt_selected WITH KEY table_line = lv_index TRANSPORTING NO FIELDS.
      temp315 = sy-subrc.
      sy-tabix = temp316.
      IF temp315 = 0.
        ASSIGN COMPONENT cv_box_field OF STRUCTURE <row> TO <box>.
        <box> = abap_true.
      ENDIF.
      INSERT <row> INTO TABLE <copy>.
    ENDLOOP.

  ENDMETHOD.

  METHOD box_write_back.

    FIELD-SYMBOLS <src>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <box>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <line> TYPE any.

    ASSIGN source->* TO <src>.
    ASSIGN box->* TO <box>.
    IF lines( <src> ) <> lines( <box> ).
      RETURN.
    ENDIF.

    LOOP AT <box> ASSIGNING <row>.
      READ TABLE <src> ASSIGNING <line> INDEX sy-tabix.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING <row> TO <line>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD filtered_copy.

    FIELD-SYMBOLS <src>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <shown> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <copy>  TYPE STANDARD TABLE.
    DATA lt_index TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA lv_row LIKE LINE OF lt_index.
      FIELD-SYMBOLS <line> TYPE any.

    ASSIGN source->* TO <src>.
    ASSIGN shown->* TO <shown>.

    lt_index = filter_index( <shown> ).
    CREATE DATA result LIKE <src>.
    ASSIGN result->* TO <copy>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <copy>.

    LOOP AT lt_index INTO lv_row.

      READ TABLE <src> ASSIGNING <line> INDEX lv_row.
      IF sy-subrc = 0.
        INSERT <line> INTO TABLE <copy>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD page_write_back.

    FIELD-SYMBOLS <full> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <page> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row> TYPE ANY.
      DATA lv_shown LIKE sy-tabix.
      DATA lv_row TYPE i.
      FIELD-SYMBOLS <line> TYPE any.

    ASSIGN full->* TO <full>.
    ASSIGN page->* TO <page>.

    LOOP AT <page> ASSIGNING <row>.

      lv_shown = sy-tabix.

      READ TABLE index INTO lv_row INDEX lv_shown.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      READ TABLE <full> ASSIGNING <line> INDEX lv_row.
      IF sy-subrc = 0.
        <line> = <row>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD select_filtered.

    FIELD-SYMBOLS <box> TYPE any.

    DATA lt_index TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA lv_box TYPE string.
    DATA lv_row LIKE LINE OF lt_index.
      FIELD-SYMBOLS <line> TYPE any.
    lt_index = filter_index( tab ).

    lv_box = get_box_field( ).

    LOOP AT lt_index INTO lv_row.

      READ TABLE tab ASSIGNING <line> INDEX lv_row.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT lv_box OF STRUCTURE <line> TO <box>.
      IF sy-subrc = 0.
        <box> = selected.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD filter_columns.

    DATA lt_low TYPE string_table.

    DATA lt_filter TYPE z2ui5_cl_cgui_alv=>ty_t_filter.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA ls_layout LIKE LINE OF lt_layout.
      DATA ls_filter TYPE z2ui5_cl_cgui_alv=>ty_s_filter.
        DATA ls_row LIKE LINE OF ls_filter-rows.
          DATA temp317 TYPE string.
      DATA temp318 TYPE z2ui5_cl_cgui_alv=>ty_s_filter_col.
    lt_filter = get_filter( ).

    lt_layout = get_layout( tab ).
    SORT lt_layout BY position.

    LOOP AT lt_layout INTO ls_layout.
      CLEAR lt_low.

      READ TABLE lt_filter INTO ls_filter WITH KEY name = ls_layout-name.
      IF sy-subrc = 0.

        LOOP AT ls_filter-rows INTO ls_row.

          IF ls_row-sign = `E`.
            temp317 = |≠{ ls_row-low }|.
          ELSEIF ls_row-high IS NOT INITIAL.
            temp317 = |{ ls_row-low }…{ ls_row-high }|.
          ELSE.
            temp317 = ls_row-low.
          ENDIF.
          INSERT temp317 INTO TABLE lt_low.
        ENDLOOP.
      ENDIF.

      CLEAR temp318.
      temp318-column = ls_layout-name.
      temp318-text = ls_layout-text.
      temp318-filter = concat_lines_of( table = lt_low sep = `, ` ).
      INSERT temp318 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD filter_setting.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA ls_layout TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
    DATA temp319 TYPE z2ui5_cl_cgui_range=>ty_s_setting-title.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp TYPE z2ui5_cl_cgui_context=>ty_s_comp.

    result-control = z2ui5_cl_cgui_range=>cs_control-input.

    lt_layout = get_layout( tab ).

    READ TABLE lt_layout INTO ls_layout WITH KEY name = name.

    IF ls_layout-text IS NOT INITIAL.
      temp319 = ls_layout-text.
    ELSE.
      temp319 = name.
    ENDIF.
    result-title = temp319.

    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    READ TABLE lt_comp INTO ls_comp WITH KEY name = name.
    CASE ls_comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        result-control = z2ui5_cl_cgui_range=>cs_control-date.
      WHEN cl_abap_typedescr=>typekind_time.
        result-control = z2ui5_cl_cgui_range=>cs_control-time.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
