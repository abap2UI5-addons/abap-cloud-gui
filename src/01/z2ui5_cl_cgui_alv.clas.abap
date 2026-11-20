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

    " the aggregate of column over the rows
    TYPES:
      BEGIN OF ty_s_aggregate,
        column      TYPE string,
        label       TYPE string,
        aggregation TYPE string,
        value       TYPE decfloat34,
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
    TYPES:
      BEGIN OF ty_s_subtotal,
        group  TYPE string,
        column TYPE string,
        value  TYPE decfloat34,
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
    "! ones as the grid scrolls - the rows are bound with window_bind_tab( ), so a
    "! sort or a filter in a column menu runs on the server over all rows,
    "! and selection, input and events land in the rows they were made in.
    "! 0 switches it off
    METHODS set_paging
      IMPORTING
        page_size     TYPE i DEFAULT 500
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! the rows a page holds - 0 without paging
    METHODS get_page_size
      RETURNING
        VALUE(result) TYPE i.

    "! the page shown, from 1
    METHODS get_page
      RETURNING
        VALUE(result) TYPE i.

    "! the rows before the page shown - add it to a row of the page to get
    "! the row of the table
    METHODS get_page_offset
      RETURNING
        VALUE(result) TYPE i.

    "! turn the page - cs_page - for a table of lines rows
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

    "! the numbers of the rows of tab that pass the filters - all rows
    "! without filter
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
    "! OUTPUTLEN, COL_POS, ICON, CFIELDNAME, QFIELDNAME, NO_ZERO, JUST
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

    "! a filter or a search is set - not all rows are shown
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
    "! count over the rows of tab
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
    "! columns, in the order of the sorting
    METHODS get_subtotals
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE ty_t_subtotal.

    "! the visible columns of tab as Excel file (Office Open XML)
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
    "! default namespace is sap.m
    METHODS render
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        tab    TYPE STANDARD TABLE
        total  TYPE i DEFAULT -1
        all    TYPE i DEFAULT -1.

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

    "! whether val matches one line of range - the target of a data ref
    METHODS filter_match
      IMPORTING
        val           TYPE any
        range         TYPE REF TO data
      RETURNING
        VALUE(result) TYPE abap_bool.

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

    "! tab in the sort order of the columns
    METHODS sort_rows
      CHANGING
        tab TYPE STANDARD TABLE.

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

    CLASS-METHODS is_numeric
      IMPORTING
        type_kind     TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

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

    METHODS cell_to_text
      IMPORTING
        val           TYPE any
        comp          TYPE z2ui5_cl_cgui_context=>ty_s_comp
      RETURNING
        VALUE(result) TYPE string.

    "! val as text of an XML element
    CLASS-METHODS xlsx_escape
      IMPORTING
        val           TYPE string
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
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_path.
    DATA temp4 LIKE sy-tabix.

    SPLIT val AT `/` INTO TABLE lt_path.
    IF lt_path IS INITIAL.
      RETURN.
    ENDIF.




    temp4 = sy-tabix.
    READ TABLE lt_path INDEX lines( lt_path ) ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_last = <temp3>.
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

    DATA temp107 TYPE z2ui5_cl_cgui_alv=>ty_s_function.
    CLEAR temp107.
    temp107-name = name.
    temp107-text = text.
    temp107-icon = icon.
    temp107-tooltip = tooltip.
    INSERT temp107 INTO TABLE mt_function.
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

    DATA temp108 LIKE sy-subrc.
    DATA temp5 LIKE sy-subrc.
    DATA temp4 TYPE xsdboolean.
    READ TABLE mt_column WITH KEY edit = abap_true TRANSPORTING NO FIELDS.
    temp108 = sy-subrc.

    READ TABLE mt_column WITH KEY cell_type = cs_cell_type-checkbox_hotspot TRANSPORTING NO FIELDS.
    temp5 = sy-subrc.

    temp4 = boolc( mv_edit = abap_true OR temp108 = 0 OR temp5 = 0 ).
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
    DATA temp109 TYPE z2ui5_cl_cgui_alv=>ty_s_column-sort.
    LOOP AT mt_column INTO ls_column WHERE sort IS NOT INITIAL.
      lv_seq = nmax( val1 = lv_seq val2 = ls_column-sort_seq ).
    ENDLOOP.

    lr_column = column_get( name ).
    IF lr_column->sort IS INITIAL.
      lr_column->sort_seq = lv_seq + 1.
    ENDIF.

    IF descending = abap_true.
      temp109 = cs_sort-descending.
    ELSE.
      temp109 = cs_sort-ascending.
    ENDIF.
    lr_column->sort = temp109.
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
      DATA temp110 TYPE z2ui5_cl_cgui_alv=>ty_s_value.
    DATA temp111 LIKE sy-subrc.
    lv_name = to_upper( name ).

    lr_column = column_get( lv_name ).
    lr_column->cell_type = cs_cell_type-dropdown.
    " the values per column: name in mt_dropdown_col, values in mt_dropdown
    " with the column as prefix of the key
    DELETE mt_dropdown WHERE key CP |{ lv_name }~*|.

    LOOP AT values INTO ls_value.

      CLEAR temp110.
      temp110-key = |{ lv_name }~{ ls_value-key }|.
      temp110-text = ls_value-text.
      INSERT temp110 INTO TABLE mt_dropdown.
    ENDLOOP.

    READ TABLE mt_dropdown_col WITH KEY table_line = lv_name TRANSPORTING NO FIELDS.
    temp111 = sy-subrc.
    IF NOT temp111 = 0.
      INSERT lv_name INTO TABLE mt_dropdown_col.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD dropdown_values.

    DATA lv_prefix TYPE string.
    DATA lv_len TYPE i.
    DATA ls_value LIKE LINE OF mt_dropdown.
        DATA temp112 TYPE z2ui5_cl_cgui_alv=>ty_s_value.
    lv_prefix = |{ name }~|.

    lv_len = strlen( lv_prefix ).

    LOOP AT mt_dropdown INTO ls_value.
      IF strlen( ls_value-key ) >= lv_len AND substring( val = ls_value-key len = lv_len ) = lv_prefix.

        CLEAR temp112.
        temp112-key = substring( val = ls_value-key off = lv_len ).
        temp112-text = ls_value-text.
        INSERT temp112 INTO TABLE result.
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

    IF mv_edit_field IS NOT INITIAL.
      result = |\{= $\{{ mv_edit_field }\} === true \|\| $\{{ mv_edit_field }\} === 'X' \}|.
    ENDIF.

  ENDMETHOD.

  METHOD expr_escape.

    result = replace( val = val sub = `\` with = `\\` occ = 0 ).
    result = replace( val = result sub = `'` with = `\'` occ = 0 ).
    result = replace( val = result sub = `&` with = `&amp;` occ = 0 ).
    result = replace( val = result sub = `"` with = `&quot;` occ = 0 ).
    result = replace( val = result sub = `<` with = `&lt;` occ = 0 ).
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
      DATA temp6 TYPE string_table.
      DATA temp113 LIKE temp6.
      DATA lv_text_field LIKE LINE OF temp113.
        DATA lv_text TYPE string.
      DATA lv_length TYPE string.
      DATA temp114 TYPE i.
        DATA temp115 TYPE i.
      DATA lv_position TYPE string.
      DATA temp116 TYPE i.
        DATA temp117 TYPE i.
      DATA lv_field TYPE string.
      DATA lv_just TYPE string.
    LOOP AT fieldcat ASSIGNING <fcat>.

      lv_name = to_upper( classic_value( row  = <fcat>
                                               name = `FIELDNAME` ) ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      " the longest text there is

      CLEAR temp6.
      INSERT `SCRTEXT_L` INTO TABLE temp6.
      INSERT `SELTEXT_L` INTO TABLE temp6.
      INSERT `COLTEXT` INTO TABLE temp6.
      INSERT `REPTEXT` INTO TABLE temp6.
      INSERT `REPTEXT_DDIC` INTO TABLE temp6.
      INSERT `SCRTEXT_M` INTO TABLE temp6.
      INSERT `SELTEXT_M` INTO TABLE temp6.
      INSERT `SCRTEXT_S` INTO TABLE temp6.
      INSERT `SELTEXT_S` INTO TABLE temp6.

      temp113 = temp6.

      LOOP AT temp113 INTO lv_text_field.

        lv_text = classic_value( row  = <fcat>
                                       name = lv_text_field ).
        IF lv_text IS NOT INITIAL.
          set_column_text( name = lv_name
                           text = lv_text ).
          EXIT.
        ENDIF.
      ENDLOOP.

      IF classic_value( row = <fcat> name = `NO_OUT` ) = abap_true.
        set_column_hidden( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `TECH` ) = abap_true.
        set_column_technical( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `DO_SUM` ) = abap_true.
        set_column_sum( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `HOTSPOT` ) = abap_true.
        set_column_hotspot( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `KEY` ) = abap_true.
        set_column_key( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `ICON` ) = abap_true.
        set_column_icon( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `NO_ZERO` ) = abap_true.
        set_column_no_zero( lv_name ).
      ENDIF.
      IF classic_value( row = <fcat> name = `EDIT` ) = abap_true.
        set_edit( ).
        set_column_edit( lv_name ).
      ENDIF.


      lv_length = classic_value( row  = <fcat>
                                       name = `OUTPUTLEN` ).

      temp114 = lv_length.
      IF lv_length CO ` 0123456789` AND lv_length IS NOT INITIAL AND temp114 > 0.
        " a character is about 0.6 rem wide

        temp115 = lv_length.
        set_column_width( name  = lv_name
                          width = |{ temp115 * 6 / 10 + 1 }rem| ).
      ENDIF.

      lv_position = classic_value( row  = <fcat>
                                         name = `COL_POS` ).

      temp116 = lv_position.
      IF lv_position CO ` 0123456789` AND lv_position IS NOT INITIAL AND temp116 > 0.

        temp117 = lv_position.
        set_column_position( name     = lv_name
                             position = temp117 ).
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
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD set_layout_classic.

    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lt_comp TYPE abap_component_view_tab.
    DATA temp118 LIKE sy-subrc.
      DATA temp7 TYPE xsdboolean.
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
    temp118 = sy-subrc.
    IF temp118 = 0.

      temp7 = boolc( classic_value( row = layout name = `ZEBRA` ) = abap_true ).
      set_striped( temp7 ).
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

    FIELD-SYMBOLS <sort> TYPE ANY.
      DATA lv_name TYPE string.
      DATA temp8 TYPE xsdboolean.
      DATA temp1 TYPE xsdboolean.
    LOOP AT sort ASSIGNING <sort>.

      lv_name = to_upper( classic_value( row  = <sort>
                                               name = `FIELDNAME` ) ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      temp8 = boolc( classic_value( row = <sort> name = `DOWN` ) = abap_true ).

      temp1 = boolc( classic_value( row = <sort> name = `SUBTOT` ) = abap_true ).
      set_sort( name       = lv_name
                descending = temp8
                subtotal   = temp1 ).
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD classic_value.

    FIELD-SYMBOLS <value> TYPE any.
      DATA temp119 TYPE string.

    ASSIGN COMPONENT name OF STRUCTURE row TO <value>.
    IF sy-subrc = 0 AND <value> IS NOT INITIAL.

      temp119 = <value>.
      result = condense( temp119 ).
    ENDIF.

  ENDMETHOD.

  METHOD set_striped.

    DATA temp9 TYPE xsdboolean.
    temp9 = boolc( val = abap_false ).
    mv_no_stripes = temp9.
    result = me.

  ENDMETHOD.

  METHOD set_chart.

    DATA temp10 TYPE xsdboolean.
    temp10 = boolc( val = abap_false ).
    mv_no_chart = temp10.
    result = me.

  ENDMETHOD.

  METHOD chart_value_select.

    DATA temp120 TYPE string_table.
    DATA lo_select TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp122 TYPE string.
    DATA ls_comp LIKE LINE OF comps.
    CLEAR temp120.
    INSERT which INTO TABLE temp120.
    INSERT `${$source>/selectedKey}` INTO TABLE temp120.

    lo_select = node->ele( `Select`
        )->a( n = `selectedKey` t = current
        )->a( n = `change`      v = client->_event( val   = cs_event-chart
                                                    t_arg = temp120 )
        )->a( n = `class`       v = `sapUiTinyMarginBegin` ).

    temp122 = '(none)'(028).
    lo_select->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` t = temp122 ).

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
    DATA temp123 LIKE sy-subrc.
    DATA temp124 LIKE sy-subrc.
      DATA ls_comp LIKE LINE OF lt_comp.
    DATA temp125 LIKE sy-subrc.
    DATA temp126 LIKE sy-subrc.
    DATA lt_value TYPE string_table.
    DATA lt_name TYPE string_table.
      DATA temp127 LIKE LINE OF lt_name.
      DATA temp128 TYPE string_table.
      DATA lt_series LIKE temp128.
      DATA lv_series LIKE LINE OF lt_series.
        DATA temp130 LIKE sy-subrc.
        DATA temp131 LIKE sy-subrc.
    DATA lt_point TYPE z2ui5_cl_cgui_chart=>ty_t_point.
    DATA temp132 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_pick TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp133 TYPE string_table.
    DATA lo_cat TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp135 TYPE string_table.
    DATA lo_val TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp137 TYPE string.
    DATA temp138 TYPE string_table.
    DATA lo_kind TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp140 TYPE string.
    DATA temp141 TYPE string.
    DATA temp142 TYPE string.
    DATA temp143 TYPE string.
    DATA lv_svg TYPE string.
    DATA temp144 TYPE string.
    lt_comp = columns_visible( tab ).
    " the columns picked - else the first text and the first number; no
    " number: the rows are counted
    " the first text column with more than one value - a column of one
    " value is one bar


    temp124 = sy-subrc.
    READ TABLE lt_comp WITH KEY name = mv_chart_category TRANSPORTING NO FIELDS.
    temp123 = sy-subrc.
    sy-subrc = temp124.
    IF NOT temp123 = 0.
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


    temp126 = sy-subrc.
    READ TABLE lt_comp WITH KEY name = mv_chart_value TRANSPORTING NO FIELDS.
    temp125 = sy-subrc.
    sy-subrc = temp126.
    IF mv_chart_value IS NOT INITIAL AND mv_chart_value <> `%COUNT` AND NOT temp125 = 0.
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

      temp127 = 'Number of rows'(023).
      INSERT temp127 INTO TABLE lt_name.
    ELSE.

      CLEAR temp128.
      INSERT mv_chart_value INTO TABLE temp128.
      INSERT mv_chart_value2 INTO TABLE temp128.
      INSERT mv_chart_value3 INTO TABLE temp128.

      lt_series = temp128.

      LOOP AT lt_series INTO lv_series.
        READ TABLE lt_comp INTO ls_comp WITH KEY name = lv_series.


        temp131 = sy-subrc.
        READ TABLE lt_value WITH KEY table_line = lv_series TRANSPORTING NO FIELDS.
        temp130 = sy-subrc.
        sy-subrc = temp131.
        IF sy-subrc = 0 AND is_numeric( ls_comp-type_kind ) = abap_true AND NOT temp130 = 0.
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
      temp132 = mv_title.
    ELSE.
      temp132 = 'Chart'(019).
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp132
        )->a( n = `contentWidth` v = `44rem`
        )->a( n = `resizable`    b = abap_true ).

    lo_box = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " the two columns to pick - every change draws the chart anew

    lo_pick = lo_box->ele( `HBox`
        )->a( n = `wrap`       v = `Wrap`
        )->a( n = `alignItems` v = `Center` ).

    CLEAR temp133.
    INSERT `CATEGORY` INTO TABLE temp133.
    INSERT `${$source>/selectedKey}` INTO TABLE temp133.

    lo_cat = lo_pick->tag( `Label`
        )->a( n = `text`  t = |{ 'Categories'(021) }:|
        )->a( n = `class` v = `sapUiTinyMarginEnd`
        )->ele( `Select`
        )->a( n = `selectedKey` t = mv_chart_category
        )->a( n = `change`      v = client->_event( val   = cs_event-chart
                                                    t_arg = temp133 )
        )->a( n = `class`       v = `sapUiSmallMarginEnd` ).
    LOOP AT lt_comp INTO ls_comp.
      lo_cat->tag( n = `Item` ns = `core`
          )->a( n = `key`  t = ls_comp-name
          )->a( n = `text` t = ls_comp-label ).
    ENDLOOP.

    CLEAR temp135.
    INSERT `VALUE` INTO TABLE temp135.
    INSERT `${$source>/selectedKey}` INTO TABLE temp135.

    lo_val = lo_pick->tag( `Label`
        )->a( n = `text`  t = |{ 'Values'(022) }:|
        )->a( n = `class` v = `sapUiTinyMarginEnd`
        )->ele( `Select`
        )->a( n = `selectedKey` t = mv_chart_value
        )->a( n = `change`      v = client->_event( val   = cs_event-chart
                                                    t_arg = temp135 ) ).

    temp137 = 'Number of rows'(023).
    lo_val->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `%COUNT`
        )->a( n = `text` t = temp137 ).
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

    CLEAR temp138.
    INSERT `KIND` INTO TABLE temp138.
    INSERT `${$source>/selectedKey}` INTO TABLE temp138.

    lo_kind = lo_pick->tag( `Label`
        )->a( n = `text`  t = |{ 'Chart'(019) }:|
        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiTinyMarginEnd`
        )->ele( `SegmentedButton`
        )->a( n = `selectedKey`     t = mv_chart_kind
        )->a( n = `selectionChange` v = client->_event( val   = cs_event-chart
                                                        t_arg = temp138 )
        )->ele( `items` ).

    temp140 = 'Bars'(024).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-bar
        )->a( n = `icon`    v = `sap-icon://horizontal-bar-chart`
        )->a( n = `tooltip` t = temp140 ).

    temp141 = 'Columns'(025).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-column
        )->a( n = `icon`    v = `sap-icon://vertical-bar-chart`
        )->a( n = `tooltip` t = temp141 ).

    temp142 = 'Lines'(026).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-line
        )->a( n = `icon`    v = `sap-icon://line-chart`
        )->a( n = `tooltip` t = temp142 ).

    temp143 = 'Pie'(027).
    lo_kind->tag( `SegmentedButtonItem`
        )->a( n = `key`     v = z2ui5_cl_cgui_chart=>cs_kind-pie
        )->a( n = `icon`    v = `sap-icon://pie-chart`
        )->a( n = `tooltip` t = temp143 ).


    lv_svg = z2ui5_cl_cgui_chart=>chart_svg( points = lt_point
                                                   names  = lt_name
                                                   kind   = mv_chart_kind ).
    lo_box->tag( n = `HTML` ns = `core`
        )->a( n = `content` t = |<div>{ lv_svg }</div>| ).


    temp144 = 'Close'(013).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp144
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-chart_close ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD set_details.

    DATA temp11 TYPE xsdboolean.
    temp11 = boolc( val = abap_false ).
    mv_no_details = temp11.
    result = me.

  ENDMETHOD.

  METHOD set_search_field.

    DATA temp12 TYPE xsdboolean.
    temp12 = boolc( val = abap_false ).
    mv_no_search = temp12.
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

    DATA temp13 TYPE xsdboolean.
    temp13 = boolc( mt_filter IS NOT INITIAL OR mv_search IS NOT INITIAL ).
    result = temp13.

  ENDMETHOD.

  METHOD add_footer.

    DATA temp145 TYPE z2ui5_cl_cgui_alv=>ty_s_header.
    CLEAR temp145.
    temp145-label = label.
    temp145-value = value.
    INSERT temp145 INTO TABLE mt_footer.
    result = me.

  ENDMETHOD.

  METHOD get_footer.

    result = mt_footer.

  ENDMETHOD.

  METHOD has_selection.

    DATA temp14 TYPE xsdboolean.
    temp14 = boolc( mv_selection_mode = cs_selection_mode-multiple OR mv_selection_mode = cs_selection_mode-single ).
    result = temp14.

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
      DATA temp146 LIKE sy-subrc.
      DATA temp147 LIKE sy-subrc.
      DATA temp148 LIKE sy-tabix.
      DATA temp15 TYPE xsdboolean.
    lv_box = get_box_field( ).

    LOOP AT tab ASSIGNING <row>.

      lv_index = sy-tabix.
      ASSIGN COMPONENT lv_box OF STRUCTURE <row> TO <box>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.



      temp147 = sy-subrc.
      temp148 = sy-tabix.
      READ TABLE rows WITH KEY table_line = lv_index TRANSPORTING NO FIELDS.
      temp146 = sy-subrc.
      sy-subrc = temp147.
      sy-tabix = temp148.

      temp15 = boolc( temp146 = 0 ).
      <box> = temp15.
    ENDLOOP.
    IF mv_selection_mode = cs_selection_mode-single.
      single_normalize( CHANGING tab = tab ).
    ENDIF.

  ENDMETHOD.

  METHOD single_normalize.

    FIELD-SYMBOLS <box> TYPE any.
    DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
      DATA lv_keep LIKE LINE OF lt_selected.
      FIELD-SYMBOLS <temp8> LIKE LINE OF lt_selected.
      DATA temp9 LIKE sy-tabix.
      DATA lv_row LIKE LINE OF lt_selected.
      DATA lv_box TYPE string.
        FIELD-SYMBOLS <line> TYPE any.
      FIELD-SYMBOLS <temp149> LIKE LINE OF lt_selected.
      DATA temp150 LIKE sy-tabix.

    IF mv_selection_mode <> cs_selection_mode-single.
      RETURN.
    ENDIF.
    " the radio buttons of rows scrolled out of view are not reset by the
    " browser - the row that is new wins

    lt_selected = get_selected_rows( tab ).
    IF lines( lt_selected ) > 1.



      temp9 = sy-tabix.
      READ TABLE lt_selected INDEX 1 ASSIGNING <temp8>.
      sy-tabix = temp9.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_keep = <temp8>.

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


      temp150 = sy-tabix.
      READ TABLE lt_selected INDEX 1 ASSIGNING <temp149>.
      sy-tabix = temp150.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      mv_single_row = <temp149>.
    ELSE.
      CLEAR mv_single_row.
    ENDIF.

  ENDMETHOD.

  METHOD get_aggregates.

    FIELD-SYMBOLS <cell> TYPE any.
    DATA lv_value TYPE decfloat34.
    DATA lv_count TYPE i.

    DATA temp151 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp151.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp152 TYPE string.
      DATA lv_kind LIKE temp152.
      DATA temp153 TYPE ty_s_aggregate.
      DATA ls_aggregate LIKE temp153.
      FIELD-SYMBOLS <row> TYPE ANY.
    temp151 = columns_visible( tab ).

    LOOP AT temp151 INTO ls_comp.

      ls_column = column_setting( ls_comp-name ).

      IF ls_column-aggregation IS NOT INITIAL.
        temp152 = ls_column-aggregation.
      ELSEIF ls_column-sum = abap_true.
        temp152 = cs_aggregation-sum.
      ELSE.
        CLEAR temp152.
      ENDIF.

      lv_kind = temp152.
      IF lv_kind IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR temp153.
      temp153-column = ls_comp-name.
      temp153-label = ls_comp-label.
      temp153-aggregation = lv_kind.

      ls_aggregate = temp153.
      CLEAR lv_count.

      LOOP AT tab ASSIGNING <row>.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        IF lv_kind = cs_aggregation-count.
          IF <cell> IS NOT INITIAL.
            lv_count = lv_count + 1.
          ENDIF.
          CONTINUE.
        ENDIF.
        TRY.
            lv_value = <cell>.
          CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
            CONTINUE.
        ENDTRY.
        lv_count = lv_count + 1.
        CASE lv_kind.
          WHEN cs_aggregation-minimum.
            IF lv_count = 1 OR lv_value < ls_aggregate-value.
              ls_aggregate-value = lv_value.
            ENDIF.
          WHEN cs_aggregation-maximum.
            IF lv_count = 1 OR lv_value > ls_aggregate-value.
              ls_aggregate-value = lv_value.
            ENDIF.
          WHEN OTHERS.
            ls_aggregate-value = ls_aggregate-value + lv_value.
        ENDCASE.
      ENDLOOP.
      IF lv_kind = cs_aggregation-count.
        ls_aggregate-value = lv_count.
      ELSEIF lv_kind = cs_aggregation-average AND lv_count > 0.
        ls_aggregate-value = ls_aggregate-value / lv_count.
      ENDIF.
      INSERT ls_aggregate INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD details_popup.

    FIELD-SYMBOLS <cell> TYPE any.

    FIELD-SYMBOLS <row> TYPE any.
    DATA temp154 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp155 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp155.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp156 TYPE string.
    DATA temp157 TYPE string.
    READ TABLE tab ASSIGNING <row> INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.


    IF mv_title IS NOT INITIAL.
      temp154 = mv_title.
    ELSE.
      temp154 = 'Details'(012).
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp154
        )->a( n = `contentWidth` v = `32rem`
        )->a( n = `resizable`    b = abap_true ).

    " every column of the row - hidden ones too, technical ones not

    lo_box = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    temp155 = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT temp155 INTO ls_comp.
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      ls_column = column_setting( ls_comp-name ).

      IF ls_column-text IS NOT INITIAL.
        temp156 = ls_column-text.
      ELSE.
        temp156 = ls_comp-label.
      ENDIF.
      lo_box->ele( `HBox`
          )->tag( `Label`
          )->a( n = `text`  t = |{ temp156 }:|
          )->a( n = `width` v = `12rem`
          )->tag( `Text`
          )->a( n = `text` t = cell_to_text( val  = <cell>
                                             comp = ls_comp ) ).
    ENDLOOP.


    temp157 = 'Close'(013).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp157
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
    lv_code = |(String($\{{ to_upper( field ) }\} \|\| '')).substring(1,2)|.
    result = |\{= { lv_code } === '1' ? 'Indication05' : { lv_code } === '3' ? 'Warning' : |
          && |{ lv_code } === '4' ? 'Indication06' : { lv_code } === '5' ? 'Success' : |
          && |{ lv_code } === '6' ? 'Error' : { lv_code } === '7' ? 'Indication03' : 'None' \}|.

  ENDMETHOD.

  METHOD set_filter.

    DATA lv_name TYPE string.
    DATA lt_rows LIKE rows.
      DATA temp158 TYPE z2ui5_cl_cgui_alv=>ty_s_filter.
    lv_name = to_upper( name ).
    DELETE mt_filter WHERE name = lv_name.

    lt_rows = rows.
    DELETE lt_rows WHERE low IS INITIAL AND high IS INITIAL.
    IF lt_rows IS NOT INITIAL.

      CLEAR temp158.
      temp158-name = lv_name.
      temp158-rows = lt_rows.
      INSERT temp158 INTO TABLE mt_filter.
    ENDIF.
    mv_page = 1.
    result = me.

  ENDMETHOD.

  METHOD get_filter.

    result = mt_filter.

  ENDMETHOD.

  METHOD clear_filter.
      DATA lv_name TYPE string.

    IF name IS INITIAL.
      CLEAR mt_filter.
    ELSE.

      lv_name = to_upper( name ).
      DELETE mt_filter WHERE name = lv_name.
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
    DATA temp159 TYPE REF TO cl_abap_tabledescr.
    DATA lo_table LIKE temp159.
    DATA temp160 TYPE REF TO cl_abap_structdescr.
    DATA lo_struct LIKE temp160.
    DATA lv_name TYPE string.
    DATA lt_comp TYPE abap_component_tab.
    DATA ls_comp TYPE abap_componentdescr.
        DATA temp161 TYPE REF TO cl_abap_datadescr.
        DATA temp10 TYPE REF TO cl_abap_datadescr.
        DATA lo_value LIKE temp10.
        DATA temp162 TYPE abap_component_tab.
        DATA temp163 LIKE LINE OF temp162.
        DATA lo_line TYPE REF TO cl_abap_structdescr.
        DATA lo_range TYPE REF TO cl_abap_tabledescr.

    CLEAR error.

    temp159 ?= cl_abap_typedescr=>describe_by_data( tab ).

    lo_table = temp159.

    temp160 ?= lo_table->get_table_line_type( ).

    lo_struct = temp160.

    lv_name = to_upper( name ).

    lt_comp = lo_struct->get_components( ).

    READ TABLE lt_comp INTO ls_comp WITH KEY name = lv_name.
    IF sy-subrc <> 0 OR ls_comp-type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    TRY.

        temp161 ?= cl_abap_elemdescr=>get_string( ).

        IF pattern = abap_true.
          temp10 = temp161.
        ELSE.
          temp10 = ls_comp-type.
        ENDIF.

        lo_value = temp10.
        " create( ), not get( ) - get( ) is a stub in the transpiled runtime

        CLEAR temp162.

        temp163-name = `SIGN`.
        temp163-type = cl_abap_elemdescr=>get_c( 1 ).
        INSERT temp163 INTO TABLE temp162.
        temp163-name = `OPTION`.
        temp163-type = cl_abap_elemdescr=>get_c( 2 ).
        INSERT temp163 INTO TABLE temp162.
        temp163-name = `LOW`.
        temp163-type = lo_value.
        INSERT temp163 INTO TABLE temp162.
        temp163-name = `HIGH`.
        temp163-type = lo_value.
        INSERT temp163 INTO TABLE temp162.

        lo_line = cl_abap_structdescr=>create(
            temp162 ).

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
        incl_typed   TYPE REF TO data,
        incl_pattern TYPE REF TO data,
        excl_typed   TYPE REF TO data,
        excl_pattern TYPE REF TO data,
      END OF ty_s_check.
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_check WITH DEFAULT KEY.
DATA lt_check   TYPE temp2.
    DATA ls_check   TYPE ty_s_check.
    DATA lt_typed   TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_pattern TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_incl    TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_excl    TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lv_error   TYPE string.
    FIELD-SYMBOLS <cell> TYPE any.

    DATA ls_filter LIKE LINE OF mt_filter.
      DATA temp164 LIKE sy-subrc.
      DATA temp165 LIKE sy-subrc.
      DATA temp166 LIKE sy-tabix.
      DATA temp11 LIKE sy-subrc.
      DATA temp12 LIKE sy-subrc.
      DATA temp13 LIKE sy-tabix.
      DATA temp16 TYPE xsdboolean.
    DATA lt_visible TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    FIELD-SYMBOLS <row> TYPE ANY.
      DATA lv_index LIKE sy-tabix.
      DATA lv_pass LIKE abap_true.
        DATA ls_visible LIKE LINE OF lt_visible.
        DATA lv_text TYPE string.
        DATA lv_incl TYPE abap_bool.
        DATA temp17 TYPE xsdboolean.
    LOOP AT mt_filter INTO ls_filter.
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



      temp165 = sy-subrc.
      temp166 = sy-tabix.
      READ TABLE ls_filter-rows WITH KEY sign = `I` TRANSPORTING NO FIELDS.
      temp164 = sy-subrc.
      sy-subrc = temp165.
      sy-tabix = temp166.



      temp12 = sy-subrc.
      temp13 = sy-tabix.
      READ TABLE ls_filter-rows WITH KEY sign = `` TRANSPORTING NO FIELDS.
      temp11 = sy-subrc.
      sy-subrc = temp12.
      sy-tabix = temp13.

      temp16 = boolc( temp164 = 0 OR temp11 = 0 ).
      ls_check-has_incl = temp16.
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

        lv_text = |{ <cell> }|.


        temp17 = boolc( ls_check-has_incl = abap_false OR filter_match( val = <cell> range = ls_check-incl_typed ) = abap_true OR filter_match( val = lv_text range = ls_check-incl_pattern ) = abap_true ).
        lv_incl = temp17.
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
    FIELD-SYMBOLS <incl>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <sign>  TYPE any.
    DATA lr_incl TYPE REF TO data.
      FIELD-SYMBOLS <new> TYPE any.

    " whether one line of the range matches val - an empty range matches
    " nothing; the lines are all I or all E, an E line is asked as I
    IF range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN range->* TO <range>.
    IF <range> IS INITIAL.
      RETURN.
    ENDIF.
    CREATE DATA lr_incl LIKE <range>.
    ASSIGN lr_incl->* TO <incl>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <incl>.
    LOOP AT <range> ASSIGNING <line>.

      INSERT <line> INTO TABLE <incl> ASSIGNING <new>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <new> TO <sign>.
      <sign> = `I`.
    ENDLOOP.
    result = z2ui5_cl_cgui_context=>range_check( val   = val
                                                 range = <incl> ).

  ENDMETHOD.

  METHOD set_filter_change.

    DATA temp18 TYPE xsdboolean.
    temp18 = boolc( val = abap_false ).
    mv_no_filter = temp18.
    result = me.

  ENDMETHOD.

  METHOD add_header.

    DATA temp167 TYPE z2ui5_cl_cgui_alv=>ty_s_header.
    CLEAR temp167.
    temp167-label = label.
    temp167-value = value.
    INSERT temp167 INTO TABLE mt_header.
    result = me.

  ENDMETHOD.

  METHOD get_header.

    result = mt_header.

  ENDMETHOD.

  METHOD clear_header.

    CLEAR mt_header.

  ENDMETHOD.

  METHOD render_header.

    DATA temp168 TYPE ty_t_header.
    DATA lt_line LIKE temp168.
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_header LIKE LINE OF lt_line.
    IF items IS SUPPLIED.
      temp168 = items.
    ELSE.
      temp168 = mt_header.
    ENDIF.

    lt_line = temp168.
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

    DATA temp19 TYPE xsdboolean.
    temp19 = boolc( val = abap_false ).
    mv_no_layout = temp19.
    result = me.

  ENDMETHOD.

  METHOD get_layout_change.

    DATA temp20 TYPE xsdboolean.
    temp20 = boolc( mv_no_layout = abap_false ).
    result = temp20.

  ENDMETHOD.

  METHOD get_layout.

    DATA lv_seq TYPE i.

    DATA temp169 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp169.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp170 TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
      DATA temp14 TYPE z2ui5_cl_cgui_alv=>ty_s_layout-text.
      DATA temp15 TYPE z2ui5_cl_cgui_alv=>ty_s_layout-position.
    DATA temp171 LIKE LINE OF result.
    DATA lr_layout LIKE REF TO temp171.
    temp169 = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT temp169 INTO ls_comp.
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      lv_seq = lv_seq + 1.

      ls_column = column_setting( ls_comp-name ).

      CLEAR temp170.
      temp170-name = ls_comp-name.

      IF ls_column-text IS NOT INITIAL.
        temp14 = ls_column-text.
      ELSE.
        temp14 = ls_comp-label.
      ENDIF.
      temp170-text = temp14.
      temp170-hidden = ls_column-hidden.

      IF ls_column-position > 0.
        temp15 = ls_column-position.
      ELSE.
        temp15 = 1000 + lv_seq.
      ENDIF.
      temp170-position = temp15.
      temp170-sort = ls_column-sort.
      temp170-sort_seq = ls_column-sort_seq.
      temp170-sum = ls_column-sum.
      temp170-subtotal = ls_column-subtotal.
      temp170-numeric = is_numeric( ls_comp-type_kind ).
      INSERT temp170 INTO TABLE result.
    ENDLOOP.

    SORT result STABLE BY position.


    LOOP AT result REFERENCE INTO lr_layout.
      lr_layout->position = sy-tabix.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_layout.

    DATA ls_layout LIKE LINE OF layout.
      DATA lr_column TYPE REF TO z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp172 TYPE z2ui5_cl_cgui_alv=>ty_s_column-sort_seq.
    LOOP AT layout INTO ls_layout.

      lr_column = column_get( ls_layout-name ).
      lr_column->hidden   = ls_layout-hidden.
      lr_column->position = ls_layout-position.
      lr_column->sort     = to_upper( ls_layout-sort ).

      IF ls_layout-sort IS NOT INITIAL.
        temp172 = ls_layout-sort_seq.
      ELSE.
        CLEAR temp172.
      ENDIF.
      lr_column->sort_seq = temp172.
      lr_column->sum      = ls_layout-sum.
      lr_column->subtotal = ls_layout-subtotal.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD is_numeric.

    CASE type_kind.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD sort_rows.

    " a merge sort of the row numbers, bottom up - stable, and by the
    " components the columns name at run time: SORT ... BY (otab) and
    " SORT ... BY (name) sort nothing in the transpiled runtime
    TYPES temp3 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA lt_index  TYPE temp3.
    TYPES temp4 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA lt_merged TYPE temp4.
    DATA lv_right  TYPE abap_bool.
    DATA lv_a      TYPE i.
    DATA lv_b      TYPE i.
    DATA lv_number TYPE i.
    DATA lr_copy   TYPE REF TO data.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.

    DATA lt_order TYPE abap_sortorder_tab.
    DATA lv_lines TYPE i.
    DATA lv_width TYPE i.
      DATA lv_left TYPE i.
        DATA lv_mid TYPE i.
        DATA lv_end TYPE i.
        DATA lv_i LIKE lv_left.
        DATA lv_j LIKE lv_mid.
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
            READ TABLE lt_index INDEX lv_j INTO lv_a.
            READ TABLE lt_index INDEX lv_i INTO lv_b.
            lv_right = rows_less( tab   = tab
                                  order = lt_order
                                  a     = lv_a
                                  b     = lv_b ).
          ENDIF.
          IF lv_right = abap_true.
            READ TABLE lt_index INDEX lv_j INTO lv_number.
            lv_j = lv_j + 1.
          ELSE.
            READ TABLE lt_index INDEX lv_i INTO lv_number.
            lv_i = lv_i + 1.
          ENDIF.
          INSERT lv_number INTO TABLE lt_merged.
        ENDWHILE.
        lv_left = lv_end.
      ENDWHILE.
      lt_index = lt_merged.
      lv_width = lv_width * 2.
    ENDWHILE.

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

  METHOD rows_less.

    FIELD-SYMBOLS <row_a> TYPE any.
    FIELD-SYMBOLS <row_b> TYPE any.
    FIELD-SYMBOLS <val_a> TYPE any.
    FIELD-SYMBOLS <val_b> TYPE any.
    DATA ls_order LIKE LINE OF order.
      DATA lv_name TYPE string.
        DATA temp21 TYPE xsdboolean.
        DATA temp22 TYPE xsdboolean.

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

        temp21 = boolc( <val_a> > <val_b> ).
        result = temp21.
      ELSE.

        temp22 = boolc( <val_a> < <val_b> ).
        result = temp22.
      ENDIF.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD sort_order.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA lt_sorted LIKE mt_column.
    DATA ls_column LIKE LINE OF lt_sorted.
      DATA temp173 LIKE sy-subrc.
      DATA temp174 TYPE abap_sortorder.
      DATA temp23 TYPE xsdboolean.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    lt_sorted = mt_column.
    DELETE lt_sorted WHERE sort IS INITIAL.
    SORT lt_sorted BY sort_seq name.

    LOOP AT lt_sorted INTO ls_column.

      READ TABLE lt_comp WITH KEY name = ls_column-name TRANSPORTING NO FIELDS.
      temp173 = sy-subrc.
      IF NOT temp173 = 0.
        CONTINUE.
      ENDIF.

      CLEAR temp174.
      temp174-name = ls_column-name.

      temp23 = boolc( ls_column-sort = cs_sort-descending ).
      temp174-descending = temp23.
      INSERT temp174 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD sorter.

    DATA lt_part TYPE string_table.

    DATA temp175 TYPE abap_sortorder_tab.
    DATA ls_order LIKE LINE OF temp175.
      DATA temp176 TYPE string.
      DATA temp16 LIKE LINE OF lt_part.
    temp175 = sort_order( tab ).

    LOOP AT temp175 INTO ls_order.

      IF ls_order-descending = abap_true.
        temp176 = `true`.
      ELSE.
        temp176 = `false`.
      ENDIF.

      temp16 = |\{path: '{ ls_order-name }', descending: { temp176 }\}|.
      INSERT temp16 INTO TABLE lt_part.
    ENDLOOP.
    IF lt_part IS NOT INITIAL.
      result = |[{ concat_lines_of( table = lt_part sep = `, ` ) }]|.
    ENDIF.

  ENDMETHOD.

  METHOD get_subtotals.

    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    DATA lt_part TYPE string_table.
    TYPES temp5 TYPE SORTED TABLE OF ty_s_subtotal WITH UNIQUE KEY group column.
DATA lt_sum  TYPE temp5.
    DATA lv_value TYPE decfloat34.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA lt_group LIKE mt_column.
    DATA lt_summed LIKE mt_column.
      DATA ls_group LIKE LINE OF lt_group.
        DATA ls_comp TYPE z2ui5_cl_cgui_context=>ty_s_comp.
      DATA lv_group TYPE string.
      DATA ls_summed LIKE LINE OF lt_summed.
        FIELD-SYMBOLS <sum> TYPE z2ui5_cl_cgui_alv=>ty_s_subtotal.
          DATA temp177 TYPE z2ui5_cl_cgui_alv=>ty_s_subtotal.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    lt_group = mt_column.
    DELETE lt_group WHERE subtotal = abap_false OR sort IS INITIAL.
    SORT lt_group BY sort_seq name.

    lt_summed = mt_column.
    DELETE lt_summed WHERE sum = abap_false OR hidden = abap_true.
    IF lt_group IS INITIAL OR lt_summed IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT tab ASSIGNING <row>.
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

        READ TABLE lt_sum ASSIGNING <sum> WITH TABLE KEY group  = lv_group
                                                                       column = ls_summed-name.
        IF sy-subrc = 0.
          <sum>-value = <sum>-value + lv_value.
        ELSE.

          CLEAR temp177.
          temp177-group = lv_group.
          temp177-column = ls_summed-name.
          temp177-value = lv_value.
          INSERT temp177 INTO TABLE lt_sum.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    result = lt_sum.
    READ TABLE lt_group INTO ls_group INDEX 1.
    IF ls_group-sort = cs_sort-descending.
      SORT result BY group DESCENDING column ASCENDING.
    ENDIF.

  ENDMETHOD.

  METHOD to_text.

    TYPES:
      BEGIN OF ty_s_width,
        name  TYPE string,
        width TYPE i,
        right TYPE abap_bool,
      END OF ty_s_width.
    TYPES temp6 TYPE STANDARD TABLE OF ty_s_width WITH DEFAULT KEY.
DATA lt_width TYPE temp6.
    TYPES temp7 TYPE STANDARD TABLE OF string_table WITH DEFAULT KEY.
DATA lt_cells TYPE temp7.
    DATA lt_cell  TYPE string_table.
    DATA lv_line  TYPE string.
    DATA lv_text  TYPE string.
    DATA lv_index TYPE i.
    DATA lv_sum   TYPE decfloat34.
    DATA lv_total TYPE abap_bool.
    DATA lr_copy  TYPE REF TO data.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF lt_comp.
      DATA temp178 TYPE ty_s_width.
        FIELD-SYMBOLS <temp179> LIKE LINE OF lt_width.
        DATA temp180 LIKE sy-tabix.
        FIELD-SYMBOLS <temp17> LIKE LINE OF lt_width.
        DATA temp18 LIKE sy-tabix.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      FIELD-SYMBOLS <temp181> LIKE LINE OF lt_width.
      DATA temp182 LIKE sy-tabix.
      FIELD-SYMBOLS <temp19> LIKE LINE OF lt_width.
      DATA temp20 LIKE sy-tabix.
      DATA lv_width TYPE ty_s_width-width.
      FIELD-SYMBOLS <temp21> LIKE LINE OF lt_width.
      DATA temp22 LIKE sy-tabix.
    DATA ls_header LIKE LINE OF mt_header.
      DATA temp183 TYPE string.
    DATA lv_rule TYPE string.
    DATA lv_rows TYPE i.
    DATA lt_values LIKE LINE OF lt_cells.
        DATA ls_width LIKE LINE OF lt_width.
        FIELD-SYMBOLS <temp23> LIKE LINE OF lt_width.
        DATA temp24 LIKE sy-tabix.
    DATA ls_footer LIKE LINE OF mt_footer.
      DATA temp184 TYPE string.

    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).


    lt_comp = columns_visible( tab ).

    LOOP AT lt_comp INTO ls_comp.

      CLEAR temp178.
      temp178-name = ls_comp-name.
      temp178-width = strlen( ls_comp-label ).
      temp178-right = is_numeric( ls_comp-type_kind ).
      INSERT temp178 INTO TABLE lt_width.
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


        temp180 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp179>.
        sy-tabix = temp180.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp18 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp17>.
        sy-tabix = temp18.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp179>-width = nmin( val1 = 40
                                           val2 = nmax( val1 = <temp17>-width
                                                        val2 = strlen( lv_text ) ) ).
      ENDLOOP.
      INSERT lt_cell INTO TABLE lt_cells.
    ENDLOOP.

    " the totals of the summed columns
    CLEAR lt_cell.
    LOOP AT lt_comp INTO ls_comp.
      lv_index = sy-tabix.

      ls_column = column_setting( ls_comp-name ).
      IF ls_column-sum = abap_false.
        INSERT `` INTO TABLE lt_cell.
        CONTINUE.
      ENDIF.
      lv_total = abap_true.
      CLEAR lv_sum.
      LOOP AT <copy> ASSIGNING <row>.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
        TRY.
            lv_sum = lv_sum + <cell>.
          CATCH cx_sy_conversion_error cx_sy_arithmetic_error ##NO_HANDLER.
        ENDTRY.
      ENDLOOP.
      lv_text = |{ lv_sum NUMBER = USER }|.
      INSERT lv_text INTO TABLE lt_cell.


      temp182 = sy-tabix.
      READ TABLE lt_width INDEX lv_index ASSIGNING <temp181>.
      sy-tabix = temp182.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.


      temp20 = sy-tabix.
      READ TABLE lt_width INDEX lv_index ASSIGNING <temp19>.
      sy-tabix = temp20.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      <temp181>-width = nmax( val1 = <temp19>-width
                                         val2 = strlen( lv_text ) ).
    ENDLOOP.

    " header, rule, rows, rule and totals
    LOOP AT lt_comp INTO ls_comp.
      lv_index = sy-tabix.



      temp22 = sy-tabix.
      READ TABLE lt_width INDEX lv_index ASSIGNING <temp21>.
      sy-tabix = temp22.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_width = <temp21>-width.
      lv_text = ls_comp-label.
      IF strlen( lv_text ) > lv_width.
        lv_text = substring( val = lv_text len = lv_width ).
      ENDIF.
      lv_line = |{ lv_line }{ lv_text WIDTH = lv_width } |.
    ENDLOOP.

    LOOP AT mt_header INTO ls_header.

      IF ls_header-label IS INITIAL.
        temp183 = ls_header-value.
      ELSE.
        temp183 = |{ ls_header-label }: { ls_header-value }|.
      ENDIF.
      INSERT temp183 INTO TABLE result.
    ENDLOOP.
    IF mt_header IS NOT INITIAL.
      INSERT `` INTO TABLE result.
    ENDIF.
    INSERT lv_line INTO TABLE result.

    lv_rule = repeat( val = `-` occ = strlen( lv_line ) ).
    INSERT lv_rule INTO TABLE result.

    IF lv_total = abap_true.
      INSERT lt_cell INTO TABLE lt_cells.
    ENDIF.

    lv_rows = lines( lt_cells ).

    LOOP AT lt_cells INTO lt_values.
      IF lv_total = abap_true AND sy-tabix = lv_rows.
        INSERT lv_rule INTO TABLE result.
      ENDIF.
      CLEAR lv_line.
      LOOP AT lt_values INTO lv_text.
        lv_index = sy-tabix.



        temp24 = sy-tabix.
        READ TABLE lt_width INDEX lv_index ASSIGNING <temp23>.
        sy-tabix = temp24.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ls_width = <temp23>.
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
        temp184 = ls_footer-value.
      ELSE.
        temp184 = |{ ls_footer-label }: { ls_footer-value }|.
      ENDIF.
      INSERT temp184 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD to_xlsx.

    " an Office Open XML workbook of one sheet, written as XML and zipped
    " with CL_ABAP_ZIP - released on ABAP Cloud and on every release down
    " to 7.02, no CL_SALV_TABLE. Numbers are cells with a value, everything
    " else inline text as the list shows it
    CONSTANTS lc_xml TYPE string VALUE `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`.
    CONSTANTS lc_rel TYPE string VALUE `http://schemas.openxmlformats.org/officeDocument/2006/relationships`.
    DATA lr_copy  TYPE REF TO data.
    DATA lt_xml   TYPE string_table.
    DATA lt_cell  TYPE string_table.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    DATA lt_visible TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA temp185 LIKE LINE OF lt_xml.
    DATA ls_visible LIKE LINE OF lt_visible.
      DATA temp186 LIKE LINE OF lt_cell.
    DATA temp187 LIKE LINE OF lt_xml.
            DATA temp188 LIKE LINE OF lt_cell.
            DATA lv_cell TYPE string.
            DATA temp189 LIKE LINE OF lt_cell.
      DATA temp190 LIKE LINE OF lt_xml.
    DATA lo_zip TYPE REF TO cl_abap_zip.

    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).

    lt_visible = columns_visible( tab ).


    temp185 = |{ lc_xml }<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>|.
    INSERT temp185
           INTO TABLE lt_xml.

    LOOP AT lt_visible INTO ls_visible.

      temp186 = |<c t="inlineStr"><is><t>{ xlsx_escape( ls_visible-label ) }</t></is></c>|.
      INSERT temp186 INTO TABLE lt_cell.
    ENDLOOP.

    temp187 = |<row>{ concat_lines_of( lt_cell ) }</row>|.
    INSERT temp187 INTO TABLE lt_xml.

    LOOP AT <copy> ASSIGNING <row>.
      CLEAR lt_cell.
      LOOP AT lt_visible INTO ls_visible.
        ASSIGN COMPONENT ls_visible-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          INSERT `<c/>` INTO TABLE lt_cell.
          CONTINUE.
        ENDIF.
        CASE ls_visible-type_kind.
          WHEN cl_abap_typedescr=>typekind_int OR cl_abap_typedescr=>typekind_int1
              OR cl_abap_typedescr=>typekind_int2 OR cl_abap_typedescr=>typekind_int8
              OR cl_abap_typedescr=>typekind_packed OR cl_abap_typedescr=>typekind_float
              OR cl_abap_typedescr=>typekind_decfloat16 OR cl_abap_typedescr=>typekind_decfloat34.

            temp188 = |<c><v>{ <cell> }</v></c>|.
            INSERT temp188 INTO TABLE lt_cell.
          WHEN OTHERS.

            lv_cell = xlsx_escape( cell_to_text( val  = <cell>
                                                       comp = ls_visible ) ).

            temp189 = |<c t="inlineStr"><is><t>{ lv_cell }</t></is></c>|.
            INSERT temp189 INTO TABLE lt_cell.
        ENDCASE.
      ENDLOOP.

      temp190 = |<row>{ concat_lines_of( lt_cell ) }</row>|.
      INSERT temp190 INTO TABLE lt_xml.
    ENDLOOP.
    INSERT `</sheetData></worksheet>` INTO TABLE lt_xml.


    CREATE OBJECT lo_zip TYPE cl_abap_zip.
    lo_zip->add( name    = `[Content_Types].xml`
                 content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string(
                     |{ lc_xml }<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">|
                  && |<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>|
                  && |<Default Extension="xml" ContentType="application/xml"/>|
                  && |<Override PartName="/xl/workbook.xml" |
                  && |ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>|
                  && |<Override PartName="/xl/worksheets/sheet1.xml" |
                  && |ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>|
                  && |</Types>| ) ).
    lo_zip->add( name    = `_rels/.rels`
                 content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string(
                     |{ lc_xml }<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">|
                  && |<Relationship Id="rId1" Type="{ lc_rel }/officeDocument" Target="xl/workbook.xml"/>|
                  && |</Relationships>| ) ).
    lo_zip->add( name    = `xl/workbook.xml`
                 content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string(
                     |{ lc_xml }<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" |
                  && |xmlns:r="{ lc_rel }"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>| ) ).
    lo_zip->add( name    = `xl/_rels/workbook.xml.rels`
                 content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string(
                     |{ lc_xml }<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">|
                  && |<Relationship Id="rId1" Type="{ lc_rel }/worksheet" Target="worksheets/sheet1.xml"/>|
                  && |</Relationships>| ) ).
    lo_zip->add( name    = `xl/worksheets/sheet1.xml`
                 content = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( concat_lines_of( lt_xml ) ) ).
    result = lo_zip->save( ).

  ENDMETHOD.

  METHOD xlsx_escape.

    result = replace( val = val sub = `&` with = `&amp;` occ = 0 ).
    result = replace( val = result sub = `<` with = `&lt;` occ = 0 ).
    result = replace( val = result sub = `>` with = `&gt;` occ = 0 ).
    result = replace( val = result sub = `"` with = `&quot;` occ = 0 ).

  ENDMETHOD.

  METHOD column_get.

    DATA lv_name TYPE string.
      DATA temp191 TYPE z2ui5_cl_cgui_alv=>ty_s_column.
    lv_name = to_upper( name ).
    READ TABLE mt_column REFERENCE INTO result WITH KEY name = lv_name.
    IF sy-subrc <> 0.

      CLEAR temp191.
      temp191-name = lv_name.
      INSERT temp191 INTO TABLE mt_column REFERENCE INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD column_setting.

    READ TABLE mt_column INTO result WITH KEY name = name.

  ENDMETHOD.

  METHOD has_box_field.

    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA lv_box TYPE string.
    DATA temp192 LIKE sy-subrc.
    DATA temp24 TYPE xsdboolean.
    lt_comp = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    lv_box = get_box_field( ).

    READ TABLE lt_comp WITH KEY name = lv_box TRANSPORTING NO FIELDS.
    temp192 = sy-subrc.

    temp24 = boolc( temp192 = 0 ).
    result = temp24.

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
          FIELD-SYMBOLS <temp193> LIKE LINE OF lt_selected.
          DATA temp194 LIKE sy-tabix.

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


          temp194 = sy-tabix.
          READ TABLE lt_selected INDEX 1 ASSIGNING <temp193>.
          sy-tabix = temp194.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          details_popup( client = client
                         tab    = tab
                         row    = <temp193> ).
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
    DATA temp195 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp195.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA temp196 TYPE z2ui5_cl_cgui_alv=>ty_s_ordered.
      DATA temp25 TYPE z2ui5_cl_cgui_alv=>ty_s_ordered-position.
    DATA ls_ordered LIKE LINE OF lt_ordered.
    temp195 = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).

    LOOP AT temp195 INTO ls_comp.
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

      CLEAR temp196.

      IF ls_column-position > 0.
        temp25 = ls_column-position.
      ELSE.
        temp25 = 1000 + lv_seq.
      ENDIF.
      temp196-position = temp25.
      temp196-seq = lv_seq.
      temp196-comp = ls_comp.
      INSERT temp196 INTO TABLE lt_ordered.
    ENDLOOP.

    SORT lt_ordered BY position seq.

    LOOP AT lt_ordered INTO ls_ordered.
      INSERT ls_ordered-comp INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD render.

    DATA lv_rows LIKE mv_visible_rows.
    DATA lv_multi TYPE abap_bool.
    DATA temp25 TYPE xsdboolean.
    DATA lv_sorter TYPE string.
    DATA temp197 TYPE z2ui5_if_client=>ty_t_bind_tab_sort.
    DATA temp26 TYPE abap_sortorder_tab.
    DATA ls_order LIKE LINE OF temp26.
      DATA temp198 LIKE LINE OF temp197.
    DATA lt_window_sort LIKE temp197.
    DATA temp199 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp27 TYPE xsdboolean.
    DATA lv_fixed LIKE mv_fixed_columns.
      DATA temp200 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
      DATA ls_visible LIKE LINE OF temp200.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA temp201 LIKE sy-subrc.
    DATA temp202 TYPE i.
    lv_rows = mv_visible_rows.
    IF lv_rows <= 0.
      lv_rows = lines( tab ).
      IF lv_rows > 15.
        lv_rows = 15.
      ELSEIF lv_rows < 3.
        lv_rows = 3.
      ENDIF.
    ENDIF.



    temp25 = boolc( has_selection( ) = abap_true AND has_box_field( tab ) = abap_true ).
    lv_multi = temp25.

    lv_sorter = sorter( tab ).
    " a large table (set_paging) is bound with window_bind_tab( ): the browser
    " holds a window of the rows and the server sorts and filters them - a
    " sorter in the binding would order the window alone. The sort of the
    " layout is the order the app passes; a click in a column menu sorts
    " anew on the server, and a render with the same layout keeps that

    CLEAR temp197.

    temp26 = sort_order( tab ).

    LOOP AT temp26 INTO ls_order.

      temp198-path = ls_order-name.
      temp198-descending = ls_order-descending.
      INSERT temp198 INTO TABLE temp197.
    ENDLOOP.

    lt_window_sort = temp197.

    render_header( node ).


    IF mv_page_size > 0.
      temp199 = client->window_bind_tab( val = tab window = mv_page_size t_sort = lt_window_sort ).
    ELSEIF lv_sorter IS INITIAL.
      temp199 = client->_bind( tab ).
    ELSE.
      temp199 = |\{path: '{ client->_bind_path( tab ) }', sorter: { lv_sorter }\}|.
    ENDIF.


    temp27 = boolc( mv_no_stripes = abap_false ).
    lo_table = node->ele( n = `Table` ns = `table`
        )->a( n = `xmlns:table`        v = `sap.ui.table`
        )->a( n = `xmlns:core`         v = `sap.ui.core`
        )->a( n = `core:require`       v = type_require( )
        )->a( n = `rows`               v = temp199
        )->a( n = `selectionMode`      v = `None`
        )->a( n = `alternateRowColors` b = temp27
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

      temp200 = columns_visible( tab ).

      LOOP AT temp200 INTO ls_visible.
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
    temp201 = sy-subrc.
    IF mv_color_field IS NOT INITIAL AND temp201 = 0.
      lo_table->ele( n = `rowSettingsTemplate` ns = `table`
          )->tag( n = `RowSettings` ns = `table`
          )->a( n = `highlight` v = color_binding( mv_color_field ) ).
    ENDIF.


    IF total >= 0.
      temp202 = total.
    ELSE.
      temp202 = lines( tab ).
    ENDIF.
    render_toolbar( node   = lo_table->ele( n = `extension` ns = `table` )
                    client = client
                    multi  = lv_multi
                    total  = temp202
                    all    = all ).

    render_columns( node   = lo_table->ele( n = `columns` ns = `table` )
                    client = client
                    tab    = tab
                    multi  = lv_multi ).

    render_sums( node = node
                 tab  = tab ).

    render_subtotals( node = node
                      tab  = tab ).

    render_header( node  = node
                   items = mt_footer ).

  ENDMETHOD.

  METHOD render_toolbar.

    DATA lo_bar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_count TYPE string.
      DATA temp203 TYPE string.
      DATA temp27 TYPE string.
    DATA temp204 LIKE LINE OF mt_function.
    DATA lr_function LIKE REF TO temp204.
      DATA temp205 TYPE string.
      DATA temp206 TYPE string.
      DATA temp207 TYPE string.
      DATA temp28 TYPE string.
      DATA temp4 TYPE string.
        DATA temp208 TYPE string.
      DATA temp209 TYPE string.
      DATA temp210 TYPE string.
      DATA temp211 TYPE string.
      DATA temp29 TYPE string.
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

      temp203 = 'Select All'(001).

      temp27 = 'Deselect All'(002).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://multiselect-all`
          )->a( n = `tooltip` t = temp203
          )->a( n = `press`   v = client->_event( cs_event-select_all )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://multiselect-none`
          )->a( n = `tooltip` t = temp27
          )->a( n = `press`   v = client->_event( cs_event-deselect_all ) ).
    ENDIF.



    LOOP AT mt_function REFERENCE INTO lr_function.
      lo_bar->tag( `Button`
          )->a( n = `text`    t = lr_function->text
          )->a( n = `icon`    v = lr_function->icon
          )->a( n = `tooltip` t = lr_function->tooltip
          )->a( n = `press`   v = client->_event( lr_function->name ) ).
    ENDLOOP.

    IF mv_no_search = abap_false.

      temp205 = 'Search'(014).
      lo_bar->tag( `SearchField`
          )->a( n = `value`       t = mv_search
          )->a( n = `width`       v = `14rem`
          )->a( n = `placeholder` t = temp205
          )->a( n = `search`      v = client->_event( val = cs_event-search
                                                      arg = `${$parameters>/query}` ) ).
    ENDIF.

    IF multi = abap_true AND mv_no_details = abap_false.

      temp206 = 'Details'(012).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://detail-view`
          )->a( n = `tooltip` t = temp206
          )->a( n = `press`   v = client->_event( cs_event-details ) ).
    ENDIF.

    IF mv_no_filter = abap_false.

      temp207 = 'Filter'(010).

      IF mt_filter IS NOT INITIAL.
        temp28 = |{ lines( mt_filter ) }|.
      ELSE.
        CLEAR temp28.
      ENDIF.

      IF mt_filter IS NOT INITIAL.
        temp4 = `Emphasized`.
      ELSE.
        temp4 = `Default`.
      ENDIF.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://filter`
          )->a( n = `text`    v = temp28
          )->a( n = `type`    v = temp4
          )->a( n = `tooltip` t = temp207
          )->a( n = `press`   v = client->_event( cs_event-filter ) ).
      IF is_filtered( ) = abap_true.

        temp208 = 'Delete Filter'(011).
        lo_bar->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://clear-filter`
            )->a( n = `tooltip` t = temp208
            )->a( n = `press`   v = client->_event( cs_event-filter_clear ) ).
      ENDIF.
    ENDIF.

    IF mv_no_layout = abap_false.

      temp209 = 'Change Layout'(005).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://action-settings`
          )->a( n = `tooltip` t = temp209
          )->a( n = `press`   v = client->_event( cs_event-layout ) ).
    ENDIF.

    IF mv_no_chart = abap_false.

      temp210 = 'Chart'(019).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://bar-chart`
          )->a( n = `tooltip` t = temp210
          )->a( n = `press`   v = client->_event( cs_event-chart ) ).
    ENDIF.

    IF mv_no_export = abap_false.

      temp211 = 'Export to Excel'(006).

      temp29 = 'Export'(003).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://excel-attachment`
          )->a( n = `tooltip` t = temp211
          )->a( n = `press`   v = client->_event( cs_event-export_xlsx )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://document-text`
          )->a( n = `tooltip` t = temp29
          )->a( n = `press`   v = client->_event( cs_event-export ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_columns.
    DATA temp212 TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF temp212.
      DATA ls_column TYPE z2ui5_cl_cgui_alv=>ty_s_column.
      DATA lv_align TYPE string.
      DATA lv_width LIKE ls_column-width.
      DATA lo_column TYPE REF TO z2ui5_cl_ui5_view_builder.
        DATA temp213 TYPE string.
      DATA temp214 TYPE string.

    IF multi = abap_true AND mv_selection_mode = cs_selection_mode-single.
      node->ele( n = `Column` ns = `table`
          )->a( n = `width`  v = `3rem`
          )->a( n = `hAlign` v = `Center`
          )->ele( n = `template` ns = `table`
              )->tag( `RadioButton`
              )->a( n = `groupName` v = `cgui_alv_single`
              )->a( n = `selected`  v = |\{{ get_box_field( ) }\}| ).
    ELSEIF multi = abap_true.
      node->ele( n = `Column` ns = `table`
          )->a( n = `width`  v = `3rem`
          )->a( n = `hAlign` v = `Center`
          )->ele( n = `template` ns = `table`
              )->tag( `CheckBox`
              )->a( n = `selected` v = |\{{ get_box_field( ) }\}| ).
    ENDIF.


    temp212 = columns_visible( tab ).

    LOOP AT temp212 INTO ls_comp.


      ls_column = column_setting( ls_comp-name ).


      lv_align = `Begin`.
      CASE ls_comp-type_kind.
        WHEN cl_abap_typedescr=>typekind_int
            OR cl_abap_typedescr=>typekind_int1
            OR cl_abap_typedescr=>typekind_int2
            OR cl_abap_typedescr=>typekind_int8
            OR cl_abap_typedescr=>typekind_packed
            OR cl_abap_typedescr=>typekind_float
            OR cl_abap_typedescr=>typekind_decfloat16
            OR cl_abap_typedescr=>typekind_decfloat34.
          lv_align = `End`.
      ENDCASE.
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
          )->a( n = `sortProperty`   t = ls_comp-name
          )->a( n = `filterProperty` t = ls_comp-name
          )->a( n = `hAlign`         v = lv_align ).
      IF lv_width IS NOT INITIAL.
        lo_column->a( n = `width` t = lv_width ).
      ENDIF.
      IF ls_column-sort IS NOT INITIAL.

        IF ls_column-sort = cs_sort-descending.
          temp213 = `Descending`.
        ELSE.
          temp213 = `Ascending`.
        ENDIF.
        lo_column->a( n = `sorted`    b = abap_true
            )->a( n = `sortOrder` v = temp213 ).
      ENDIF.


      IF ls_column-key = abap_true.
        temp214 = `Bold`.
      ELSE.
        temp214 = `Standard`.
      ENDIF.
      lo_column->ele( n = `label` ns = `table`
          )->tag( `Label`
              )->a( n = `text`   t = ls_comp-label
              )->a( n = `design` v = temp214 ).
      IF ls_column-tooltip IS NOT INITIAL.
        lo_column->a( n = `tooltip` t = ls_column-tooltip ).
      ENDIF.

      render_template( node   = lo_column->ele( n = `template` ns = `table` )
                       client = client
                       comp   = ls_comp
                       column = ls_column ).

    ENDLOOP.

  ENDMETHOD.

  METHOD render_template.
        DATA temp215 TYPE string_table.
        DATA temp217 TYPE string_table.
        DATA lt_value TYPE z2ui5_cl_cgui_alv=>ty_t_value.
        DATA lv_expr TYPE string.
        DATA ls_value LIKE LINE OF lt_value.
      DATA temp219 TYPE string_table.
      DATA temp221 TYPE string.

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

        CLEAR temp215.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp215.
        INSERT comp-name INTO TABLE temp215.
        node->tag( `CheckBox`
            )->a( n = `selected` v = |\{{ comp-name }\}|
            )->a( n = `select`   v = client->_event( val   = cs_event-hotspot
                                                     t_arg = temp215 ) ).
        RETURN.
      WHEN cs_cell_type-button.

        CLEAR temp217.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp217.
        INSERT comp-name INTO TABLE temp217.
        node->tag( `Button`
            )->a( n = `text`  v = cell_binding( comp   = comp
                                                column = column )
            )->a( n = `press` v = client->_event( val   = cs_event-hotspot
                                                  t_arg = temp217 ) ).
        RETURN.
      WHEN cs_cell_type-dropdown.
        " shown: the text of the key

        lt_value = dropdown_values( comp-name ).

        lv_expr = |$\{{ comp-name }\}|.

        LOOP AT lt_value INTO ls_value.
          lv_expr = |$\{{ comp-name }\} === '{ expr_escape( ls_value-key ) }' ? '{ expr_escape( ls_value-text ) }' : { lv_expr }|.
        ENDLOOP.
        node->tag( `Text`
            )->a( n = `text`     v = |\{= { lv_expr } \}|
            )->a( n = `wrapping` b = abap_false ).
        RETURN.
    ENDCASE.

    IF column-icon = abap_true.
      node->tag( n = `Icon` ns = `core`
          )->a( n = `src` v = |\{{ comp-name }\}| ).
      RETURN.
    ENDIF.

    IF comp-boolean = abap_true.
      node->tag( `CheckBox`
          )->a( n = `selected` v = |\{= $\{{ comp-name }\} === true \|\| $\{{ comp-name }\} === 'X' \}|
          )->a( n = `editable` b = abap_false ).
      RETURN.
    ENDIF.

    IF column-hotspot = abap_true.

      CLEAR temp219.
      INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp219.
      INSERT comp-name INTO TABLE temp219.
      node->tag( `Link`
          )->a( n = `text`  v = cell_binding( comp   = comp
                                              column = column )
          )->a( n = `press` v = client->_event( val   = cs_event-hotspot
                                                t_arg = temp219 ) ).
      RETURN.
    ENDIF.

    IF column-color IS NOT INITIAL OR column-color_field IS NOT INITIAL.

      IF column-color_field IS NOT INITIAL.
        temp221 = color_binding( column-color_field ).
      ELSE.
        temp221 = color_state( column-color ).
      ENDIF.
      node->tag( `ObjectStatus`
          )->a( n = `text`  v = cell_binding( comp   = comp
                                              column = column )
          )->a( n = `state` v = temp221 ).
      RETURN.
    ENDIF.

    node->tag( `Text`
        )->a( n = `text`     v = cell_binding( comp   = comp
                                               column = column )
        )->a( n = `wrapping` b = abap_false ).
    " NO_ZERO: a zero is not shown
    IF column-no_zero = abap_true AND is_numeric( comp-type_kind ) = abap_true.
      node->a( n = `visible` v = |\{= Number($\{{ comp-name }\}) !== 0 \}| ).
    ELSEIF column-no_zero = abap_true AND comp-type_kind = cl_abap_typedescr=>typekind_num.
      node->a( n = `visible` v = |\{= !/^0*$/.test($\{{ comp-name }\}) \}| ).
    ENDIF.

  ENDMETHOD.

  METHOD render_edit.


    DATA lv_editable TYPE string.
      DATA temp222 TYPE string_table.
      DATA lo_select TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp224 TYPE z2ui5_cl_cgui_alv=>ty_t_value.
      DATA ls_value LIKE LINE OF temp224.
      DATA temp225 TYPE string_table.
        DATA temp227 TYPE string_table.
        DATA temp229 TYPE string_table.
          DATA temp231 TYPE string_table.
            DATA temp233 TYPE string_table.
          DATA temp235 TYPE string_table.
            DATA temp237 TYPE string_table.
    lv_editable = edit_binding( ).

    IF column-cell_type = cs_cell_type-dropdown.

      CLEAR temp222.
      INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp222.
      INSERT comp-name INTO TABLE temp222.

      lo_select = node->ele( `Select`
          )->a( n = `selectedKey`    v = |\{{ comp-name }\}|
          )->a( n = `forceSelection` b = abap_false
          )->a( n = `change`         v = client->_event( val   = cs_event-data_changed
                                                         t_arg = temp222 ) ).
      IF lv_editable IS NOT INITIAL.
        lo_select->a( n = `enabled` v = lv_editable ).
      ENDIF.

      lo_items = lo_select->ele( `items` ).
      lo_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = ``
          )->a( n = `text` v = `` ).

      temp224 = dropdown_values( comp-name ).

      LOOP AT temp224 INTO ls_value.
        lo_items->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_value-key
            )->a( n = `text` t = ls_value-text ).
      ENDLOOP.
      RETURN.
    ENDIF.

    IF comp-boolean = abap_true.

      CLEAR temp225.
      INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp225.
      INSERT comp-name INTO TABLE temp225.
      node->tag( `CheckBox`
          )->a( n = `selected` v = |\{{ comp-name }\}|
          )->a( n = `select`   v = client->_event( val   = cs_event-data_changed
                                                   t_arg = temp225 ) ).
      IF lv_editable IS NOT INITIAL.
        node->a( n = `editable` v = lv_editable ).
      ENDIF.
      RETURN.
    ENDIF.

    CASE comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.

        CLEAR temp227.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp227.
        INSERT comp-name INTO TABLE temp227.
        node->tag( `DatePicker`
            )->a( n = `value`         v = |\{{ comp-name }\}|
            )->a( n = `valueFormat`   v = `yyyy-MM-dd`
            )->a( n = `displayFormat` v = `medium`
            )->a( n = `change`        v = client->_event( val   = cs_event-data_changed
                                                          t_arg = temp227 ) ).
        IF lv_editable IS NOT INITIAL.
          node->a( n = `editable` v = lv_editable ).
        ENDIF.
      WHEN cl_abap_typedescr=>typekind_time.

        CLEAR temp229.
        INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp229.
        INSERT comp-name INTO TABLE temp229.
        node->tag( `TimePicker`
            )->a( n = `value`         v = |\{{ comp-name }\}|
            )->a( n = `valueFormat`   v = `HH:mm:ss`
            )->a( n = `displayFormat` v = `HH:mm:ss`
            )->a( n = `change`        v = client->_event( val   = cs_event-data_changed
                                                          t_arg = temp229 ) ).
        IF lv_editable IS NOT INITIAL.
          node->a( n = `editable` v = lv_editable ).
        ENDIF.
      WHEN OTHERS.
        IF is_numeric( comp-type_kind ) = abap_true.

          CLEAR temp231.
          INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp231.
          INSERT comp-name INTO TABLE temp231.
          node->tag( `Input`
              )->a( n = `value`     v = cell_binding( comp   = comp
                                                      column = column )
              )->a( n = `textAlign` v = `End`
              )->a( n = `change`    v = client->_event( val   = cs_event-data_changed
                                                        t_arg = temp231 ) ).
          IF column-f4 = abap_true.

            CLEAR temp233.
            INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp233.
            INSERT comp-name INTO TABLE temp233.
            node->a( n = `showValueHelp`    b = abap_true
                )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                                 t_arg = temp233 ) ).
          ENDIF.
          IF lv_editable IS NOT INITIAL.
            node->a( n = `editable` v = lv_editable ).
          ENDIF.
        ELSE.

          CLEAR temp235.
          INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp235.
          INSERT comp-name INTO TABLE temp235.
          node->tag( `Input`
              )->a( n = `value`  v = |\{{ comp-name }\}|
              )->a( n = `change` v = client->_event( val   = cs_event-data_changed
                                                     t_arg = temp235 ) ).
          IF column-f4 = abap_true.

            CLEAR temp237.
            INSERT `$event.getSource().getBindingContext().getPath()` INTO TABLE temp237.
            INSERT comp-name INTO TABLE temp237.
            node->a( n = `showValueHelp`    b = abap_true
                )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                                 t_arg = temp237 ) ).
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
    DATA temp239 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_summed LIKE LINE OF lt_summed.
    DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_group TYPE string.
    DATA lv_number TYPE string.
    DATA lo_cells TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_subtotal LIKE LINE OF lt_subtotal.
          DATA ls_value TYPE z2ui5_cl_cgui_alv=>ty_s_subtotal.
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


    temp239 = 'Subtotals'(007).

    lo_table = node->ele( `Table`
        )->a( n = `headerText` t = temp239
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
          CLEAR lv_number.

          READ TABLE lt_subtotal INTO ls_value WITH KEY group  = lv_group
                                                             column = ls_summed-name.
          IF sy-subrc = 0.
            lv_number = |{ ls_value-value NUMBER = USER }|.
          ENDIF.
          lo_cells->tag( `ObjectNumber`
              )->a( n = `number`     t = lv_number
              )->a( n = `emphasized` b = abap_true ).
        ENDLOOP.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD cell_binding.

    result = z2ui5_cl_cgui_context=>ui5_binding_by_kind( path          = comp-name
                                                        type_kind     = comp-type_kind
                                                        decimals      = comp-decimals
                                                        currency_path = column-currency
                                                        unit_path     = column-quantity ).

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

  METHOD cell_to_text.

    DATA lv_date   TYPE d.
    DATA lv_time   TYPE t.
    DATA lv_number TYPE decfloat34.
          DATA temp240 TYPE string.

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
      WHEN cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        lv_number = val.
        result = |{ lv_number NUMBER = USER }|.
      WHEN OTHERS.
        IF comp-boolean = abap_true.

          IF val IS NOT INITIAL.
            temp240 = `X`.
          ELSE.
            CLEAR temp240.
          ENDIF.
          result = temp240.
        ELSE.
          result = |{ val }|.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD render_sums.

    DATA lo_sums TYPE REF TO z2ui5_cl_ui5_view_builder.

    DATA temp241 TYPE z2ui5_cl_cgui_alv=>ty_t_aggregate.
    DATA ls_aggregate LIKE LINE OF temp241.
      DATA temp242 TYPE string.
      DATA lv_title LIKE temp242.
      DATA temp243 TYPE i.
      DATA temp30 TYPE string.
      DATA lv_value LIKE temp30.
    temp241 = get_aggregates( tab ).

    LOOP AT temp241 INTO ls_aggregate.
      IF lo_sums IS NOT BOUND.
        lo_sums = node->ele( `HBox`
            )->a( n = `justifyContent` v = `End`
            )->a( n = `wrap`           v = `Wrap`
            )->a( n = `class`          v = `sapUiSmallMarginEnd` ).
      ENDIF.

      CASE ls_aggregate-aggregation.
        WHEN cs_aggregation-average.
          temp242 = 'Average'(015).
        WHEN cs_aggregation-minimum.
          temp242 = 'Minimum'(016).
        WHEN cs_aggregation-maximum.
          temp242 = 'Maximum'(017).
        WHEN cs_aggregation-count.
          temp242 = 'Count'(018).
        WHEN OTHERS.
          temp242 = 'Total'(004).
      ENDCASE.

      lv_title = temp242.

      temp243 = ls_aggregate-value.

      IF ls_aggregate-aggregation = cs_aggregation-count.
        temp30 = |{ temp243 NUMBER = USER }|.
      ELSEIF ls_aggregate-aggregation = cs_aggregation-average.
        temp30 = |{ ls_aggregate-value NUMBER = USER DECIMALS = 2 }|.
      ELSE.
        temp30 = |{ ls_aggregate-value NUMBER = USER }|.
      ENDIF.

      lv_value = temp30.
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
    DATA lt_line TYPE string_table.
    DATA lt_cell TYPE string_table.

    DATA lv_sep LIKE mv_separator.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp LIKE LINE OF lt_comp.
    DATA temp1 TYPE string.
      DATA temp2 TYPE string.
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

    LOOP AT tab ASSIGNING <row>.
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
        DATA temp244 TYPE string_table.
        DATA temp31 LIKE LINE OF temp244.
        DATA temp32 LIKE LINE OF temp244.
    DATA lv_csv TYPE xstring.
    DATA temp246 TYPE xstring.
    DATA lv_bom LIKE temp246.
    DATA temp247 TYPE string_table.
    DATA temp33 LIKE LINE OF temp247.
    DATA temp34 LIKE LINE OF temp247.
    lv_name = mv_title.
    IF lv_name IS INITIAL.
      lv_name = `export`.
    ENDIF.

    IF to_upper( format ) = cs_format-xlsx.

      lv_xlsx = to_xlsx( tab ).
      IF lv_xlsx IS NOT INITIAL.

        CLEAR temp244.

        temp31 = |data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,| && z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_xlsx ).
        INSERT temp31 INTO TABLE temp244.

        temp32 = |{ lv_name }.xlsx|.
        INSERT temp32 INTO TABLE temp244.
        client->follow_up_action( val   = client->cs_event-download_b64_file
                                  t_arg = temp244 ).
        RETURN.
      ENDIF.
    ENDIF.

    " UTF-8 with a byte order mark - Excel reads the umlauts right then

    lv_csv = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( to_csv( tab ) ).

    temp246 = `EFBBBF`.

    lv_bom = temp246.
    CONCATENATE lv_bom lv_csv INTO lv_csv IN BYTE MODE.


    CLEAR temp247.

    temp33 = |data:text/csv;charset=utf-8;base64,{ z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_csv ) }|.
    INSERT temp33 INTO TABLE temp247.

    temp34 = |{ lv_name }.csv|.
    INSERT temp34 INTO TABLE temp247.
    client->follow_up_action( val   = client->cs_event-download_b64_file
                              t_arg = temp247 ).

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

    DATA temp28 TYPE xsdboolean.
    temp28 = boolc( event = cs_event-select_all OR event = cs_event-deselect_all OR event = cs_event-export OR event = cs_event-export_xlsx OR event = cs_event-layout OR event = cs_event-page OR event = cs_event-filter OR event = cs_event-filter_clear OR event = cs_event-details OR event = cs_event-details_close OR event = cs_event-chart OR event = cs_event-chart_close OR event = cs_event-search OR event = cs_event-f4 ).
    result = temp28.

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
    DATA temp249 TYPE REF TO cl_abap_structdescr.
    DATA temp35 TYPE REF TO cl_abap_tabledescr.
    DATA lo_line LIKE temp249.
    DATA temp250 TYPE abap_componentdescr.
    DATA temp36 TYPE REF TO cl_abap_datadescr.
    DATA lo_type TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <line> TYPE ANY.
      DATA lv_index LIKE sy-tabix.
      DATA temp251 LIKE sy-subrc.
      DATA temp252 LIKE sy-tabix.

    ASSIGN source->* TO <src>.
    IF old IS BOUND.
      ASSIGN old->* TO <old>.
      IF lines( <old> ) = lines( <src> ).
        lt_selected = get_selected_rows( <old> ).
      ENDIF.
    ENDIF.



    temp35 ?= cl_abap_typedescr=>describe_by_data( <src> ).
    temp249 ?= temp35->get_table_line_type( ).

    lo_line = temp249.
    lt_comp = lo_line->get_components( ).

    CLEAR temp250.
    temp250-name = cv_box_field.

    temp36 ?= cl_abap_typedescr=>describe_by_data( lv_flag ).
    temp250-type = temp36.
    INSERT temp250 INTO TABLE lt_comp.

    lo_type = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
    CREATE DATA result TYPE HANDLE lo_type.
    ASSIGN result->* TO <copy>.


    LOOP AT <src> ASSIGNING <line>.

      lv_index = sy-tabix.
      CREATE DATA lr_row LIKE LINE OF <copy>.
      ASSIGN lr_row->* TO <row>.
      MOVE-CORRESPONDING <line> TO <row>.


      temp252 = sy-tabix.
      READ TABLE lt_selected WITH KEY table_line = lv_index TRANSPORTING NO FIELDS.
      temp251 = sy-subrc.
      sy-tabix = temp252.
      IF temp251 = 0.
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
          DATA temp253 TYPE string.
      DATA temp254 TYPE z2ui5_cl_cgui_alv=>ty_s_filter_col.
    lt_filter = get_filter( ).

    lt_layout = get_layout( tab ).
    SORT lt_layout BY position.

    LOOP AT lt_layout INTO ls_layout.
      CLEAR lt_low.

      READ TABLE lt_filter INTO ls_filter WITH KEY name = ls_layout-name.
      IF sy-subrc = 0.

        LOOP AT ls_filter-rows INTO ls_row.

          IF ls_row-sign = `E`.
            temp253 = |≠{ ls_row-low }|.
          ELSEIF ls_row-high IS NOT INITIAL.
            temp253 = |{ ls_row-low }…{ ls_row-high }|.
          ELSE.
            temp253 = ls_row-low.
          ENDIF.
          INSERT temp253 INTO TABLE lt_low.
        ENDLOOP.
      ENDIF.

      CLEAR temp254.
      temp254-column = ls_layout-name.
      temp254-text = ls_layout-text.
      temp254-filter = concat_lines_of( table = lt_low sep = `, ` ).
      INSERT temp254 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD filter_setting.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA ls_layout TYPE z2ui5_cl_cgui_alv=>ty_s_layout.
    DATA temp255 TYPE z2ui5_cl_cgui_range=>ty_s_setting-title.
    DATA lt_comp TYPE z2ui5_cl_cgui_context=>ty_t_comp.
    DATA ls_comp TYPE z2ui5_cl_cgui_context=>ty_s_comp.

    result-control = z2ui5_cl_cgui_range=>cs_control-input.

    lt_layout = get_layout( tab ).

    READ TABLE lt_layout INTO ls_layout WITH KEY name = name.

    IF ls_layout-text IS NOT INITIAL.
      temp255 = ls_layout-text.
    ELSE.
      temp255 = name.
    ENDIF.
    result-title = temp255.

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
