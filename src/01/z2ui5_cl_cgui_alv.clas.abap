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
    TYPES ty_t_value TYPE STANDARD TABLE OF ty_s_value WITH EMPTY KEY.

    " the aggregate of column over the rows
    TYPES:
      BEGIN OF ty_s_aggregate,
        column      TYPE string,
        label       TYPE string,
        aggregation TYPE string,
        value       TYPE decfloat34,
      END OF ty_s_aggregate.
    TYPES ty_t_aggregate TYPE STANDARD TABLE OF ty_s_aggregate WITH EMPTY KEY.

    " a filter of the grid: the column and the lines of its multiple
    " selection - sign, option, low, high as text
    TYPES:
      BEGIN OF ty_s_filter,
        name TYPE string,
        rows TYPE z2ui5_cl_cgui_range=>ty_t_row,
      END OF ty_s_filter.
    TYPES ty_t_filter TYPE STANDARD TABLE OF ty_s_filter WITH EMPTY KEY.

    "! row numbers of a table
    TYPES ty_t_index TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    " a line of the header above the grid - without label a heading
    TYPES:
      BEGIN OF ty_s_header,
        label TYPE string,
        value TYPE string,
      END OF ty_s_header.
    TYPES ty_t_header TYPE STANDARD TABLE OF ty_s_header WITH EMPTY KEY.

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
    TYPES ty_t_layout TYPE STANDARD TABLE OF ty_s_layout WITH EMPTY KEY.

    " the subtotal of column for the rows whose subtotal columns hold group
    TYPES:
      BEGIN OF ty_s_subtotal,
        group  TYPE string,
        column TYPE string,
        value  TYPE decfloat34,
      END OF ty_s_subtotal.
    TYPES ty_t_subtotal TYPE STANDARD TABLE OF ty_s_subtotal WITH EMPTY KEY.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_function,
        name    TYPE string,
        text    TYPE string,
        icon    TYPE string,
        tooltip TYPE string,
      END OF ty_s_function.
    TYPES ty_t_function TYPE STANDARD TABLE OF ty_s_function WITH EMPTY KEY.

    TYPES ty_t_row TYPE STANDARD TABLE OF i WITH EMPTY KEY.

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

    "! large tables: the browser gets page_size rows at a time, the toolbar
    "! pages through them (cs_event-page). The report runtime shows a copy
    "! of the page and maps rows, selection and input back; sorting and
    "! filtering in the browser apply to the page shown. 0 switches it off
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
    DATA mv_no_search      TYPE abap_bool.
    DATA mv_search         TYPE string.
    DATA mv_single_row     TYPE i.
    DATA mt_dropdown       TYPE STANDARD TABLE OF ty_s_value WITH EMPTY KEY.
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
    TYPES ty_t_ordered TYPE STANDARD TABLE OF ty_s_ordered WITH EMPTY KEY.

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

    result = NEW #( ).

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

    SPLIT val AT `/` INTO TABLE lt_path.
    IF lt_path IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_last) = lt_path[ lines( lt_path ) ].
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

    DATA(lr_column) = column_get( name ).
    lr_column->text = text.
    result = me.

  ENDMETHOD.

  METHOD set_column_hidden.

    DATA(lr_column) = column_get( name ).
    lr_column->hidden = hidden.
    result = me.

  ENDMETHOD.

  METHOD set_column_width.

    DATA(lr_column) = column_get( name ).
    lr_column->width = width.
    result = me.

  ENDMETHOD.

  METHOD set_column_icon.

    DATA(lr_column) = column_get( name ).
    lr_column->icon = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_hotspot.

    DATA(lr_column) = column_get( name ).
    lr_column->hotspot = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_currency.

    DATA(lr_column) = column_get( name ).
    lr_column->currency = to_upper( currency_field ).
    result = me.

  ENDMETHOD.

  METHOD set_column_sum.

    DATA(lr_column) = column_get( name ).
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

    INSERT VALUE #( name    = name
                    text    = text
                    icon    = icon
                    tooltip = tooltip ) INTO TABLE mt_function.
    result = me.

  ENDMETHOD.

  METHOD set_export.

    mv_no_export = xsdbool( val = abap_false ).
    mv_separator = separator.
    result = me.

  ENDMETHOD.

  METHOD set_optimize.

    mv_no_optimize = xsdbool( val = abap_false ).
    result = me.

  ENDMETHOD.

  METHOD set_edit.

    mv_edit = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_edit.

    DATA(lr_column) = column_get( name ).
    lr_column->edit = val.
    lr_column->no_edit = xsdbool( val = abap_false ).
    result = me.

  ENDMETHOD.

  METHOD is_editable.

    result = xsdbool( mv_edit = abap_true
                   OR line_exists( mt_column[ edit = abap_true ] )
                   OR line_exists( mt_column[ cell_type = cs_cell_type-checkbox_hotspot ] ) ).

  ENDMETHOD.

  METHOD column_editable.

    IF column-icon = abap_true OR column-hotspot = abap_true OR column-no_edit = abap_true
        OR column-cell_type = cs_cell_type-button OR column-cell_type = cs_cell_type-checkbox_hotspot.
      RETURN.
    ENDIF.
    result = xsdbool( column-edit = abap_true OR mv_edit = abap_true ).

  ENDMETHOD.

  METHOD set_sort.

    DATA lv_seq TYPE i.

    LOOP AT mt_column INTO DATA(ls_column) WHERE sort IS NOT INITIAL.
      lv_seq = nmax( val1 = lv_seq val2 = ls_column-sort_seq ).
    ENDLOOP.
    DATA(lr_column) = column_get( name ).
    IF lr_column->sort IS INITIAL.
      lr_column->sort_seq = lv_seq + 1.
    ENDIF.
    lr_column->sort = COND #( WHEN descending = abap_true THEN cs_sort-descending ELSE cs_sort-ascending ).
    lr_column->subtotal = subtotal.
    result = me.

  ENDMETHOD.

  METHOD set_column_position.

    DATA(lr_column) = column_get( name ).
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

    IF mv_page_size <= 0.
      RETURN.
    ENDIF.
    DATA(lv_pages) = nmax( val1 = 1 val2 = ( lines + mv_page_size - 1 ) DIV mv_page_size ).
    DATA(lv_direction) = to_upper( direction ).
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

    DATA(lr_column) = column_get( name ).
    lr_column->tooltip = text.
    result = me.

  ENDMETHOD.

  METHOD set_column_key.

    DATA(lr_column) = column_get( name ).
    lr_column->key = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_technical.

    DATA(lr_column) = column_get( name ).
    lr_column->technical = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_no_zero.

    DATA(lr_column) = column_get( name ).
    lr_column->no_zero = val.
    result = me.

  ENDMETHOD.

  METHOD set_column_quantity.

    DATA(lr_column) = column_get( name ).
    lr_column->quantity = to_upper( unit_field ).
    result = me.

  ENDMETHOD.

  METHOD set_column_alignment.

    DATA(lr_column) = column_get( name ).
    lr_column->align = align.
    result = me.

  ENDMETHOD.

  METHOD set_column_aggregation.

    DATA(lr_column) = column_get( name ).
    lr_column->aggregation = to_upper( aggregation ).
    " totals and subtotals stay the sum
    lr_column->sum = xsdbool( lr_column->aggregation = cs_aggregation-sum ).
    result = me.

  ENDMETHOD.

  METHOD set_column_cell_type.

    DATA(lr_column) = column_get( name ).
    lr_column->cell_type = to_upper( type ).
    result = me.

  ENDMETHOD.

  METHOD set_column_dropdown.

    DATA(lv_name) = to_upper( name ).
    DATA(lr_column) = column_get( lv_name ).
    lr_column->cell_type = cs_cell_type-dropdown.
    " the values per column: name in mt_dropdown_col, values in mt_dropdown
    " with the column as prefix of the key
    DELETE mt_dropdown WHERE key CP |{ lv_name }~*|.
    LOOP AT values INTO DATA(ls_value).
      INSERT VALUE #( key  = |{ lv_name }~{ ls_value-key }|
                      text = ls_value-text ) INTO TABLE mt_dropdown.
    ENDLOOP.
    IF NOT line_exists( mt_dropdown_col[ table_line = lv_name ] ).
      INSERT lv_name INTO TABLE mt_dropdown_col.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD dropdown_values.

    DATA(lv_prefix) = |{ name }~|.
    DATA(lv_len) = strlen( lv_prefix ).
    LOOP AT mt_dropdown INTO DATA(ls_value).
      IF strlen( ls_value-key ) >= lv_len AND substring( val = ls_value-key len = lv_len ) = lv_prefix.
        INSERT VALUE #( key  = substring( val = ls_value-key off = lv_len )
                        text = ls_value-text ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_column_f4.

    DATA(lr_column) = column_get( name ).
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

    LOOP AT fieldcat ASSIGNING FIELD-SYMBOL(<fcat>).
      DATA(lv_name) = to_upper( classic_value( row  = <fcat>
                                               name = `FIELDNAME` ) ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      " the longest text there is
      LOOP AT VALUE string_table( ( `SCRTEXT_L` ) ( `SELTEXT_L` ) ( `COLTEXT` ) ( `REPTEXT` ) ( `REPTEXT_DDIC` )
                                  ( `SCRTEXT_M` ) ( `SELTEXT_M` ) ( `SCRTEXT_S` ) ( `SELTEXT_S` ) ) INTO DATA(lv_text_field).
        DATA(lv_text) = classic_value( row  = <fcat>
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

      DATA(lv_length) = classic_value( row  = <fcat>
                                       name = `OUTPUTLEN` ).
      IF lv_length CO ` 0123456789` AND lv_length IS NOT INITIAL AND CONV i( lv_length ) > 0.
        " a character is about 0.6 rem wide
        set_column_width( name  = lv_name
                          width = |{ CONV i( lv_length ) * 6 / 10 + 1 }rem| ).
      ENDIF.
      DATA(lv_position) = classic_value( row  = <fcat>
                                         name = `COL_POS` ).
      IF lv_position CO ` 0123456789` AND lv_position IS NOT INITIAL AND CONV i( lv_position ) > 0.
        set_column_position( name     = lv_name
                             position = CONV i( lv_position ) ).
      ENDIF.

      DATA(lv_field) = to_upper( classic_value( row  = <fcat>
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

      DATA(lv_just) = to_upper( classic_value( row  = <fcat>
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

    TRY.
        lo_struct ?= cl_abap_typedescr=>describe_by_data( layout ).
      CATCH cx_sy_move_cast_error.
        result = me.
        RETURN.
    ENDTRY.
    " ZEBRA off is the classic default - the grid follows it
    DATA(lt_comp) = lo_struct->get_included_view( ).
    IF line_exists( lt_comp[ name = `ZEBRA` ] ).
      set_striped( xsdbool( classic_value( row = layout name = `ZEBRA` ) = abap_true ) ).
    ENDIF.
    IF classic_value( row = layout name = `COLWIDTH_OPTIMIZE` ) = abap_true
        OR classic_value( row = layout name = `CWIDTH_OPT` ) = abap_true.
      set_optimize( ).
    ENDIF.
    IF classic_value( row = layout name = `EDIT` ) = abap_true.
      set_edit( ).
    ENDIF.

    DATA(lv_box) = to_upper( classic_value( row = layout name = `BOX_FIELDNAME` ) ).
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

    DATA(lv_info) = to_upper( classic_value( row = layout name = `INFO_FIELDNAME` ) ).
    IF lv_info IS INITIAL.
      lv_info = to_upper( classic_value( row = layout name = `INFO_FNAME` ) ).
    ENDIF.
    IF lv_info IS NOT INITIAL.
      set_color_field( lv_info ).
    ENDIF.

    DATA(lv_title) = classic_value( row = layout name = `GRID_TITLE` ).
    IF lv_title IS NOT INITIAL.
      set_title( lv_title ).
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD set_sort_classic.

    LOOP AT sort ASSIGNING FIELD-SYMBOL(<sort>).
      DATA(lv_name) = to_upper( classic_value( row  = <sort>
                                               name = `FIELDNAME` ) ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.
      set_sort( name       = lv_name
                descending = xsdbool( classic_value( row = <sort> name = `DOWN` ) = abap_true )
                subtotal   = xsdbool( classic_value( row = <sort> name = `SUBTOT` ) = abap_true ) ).
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD classic_value.

    FIELD-SYMBOLS <value> TYPE any.

    ASSIGN COMPONENT name OF STRUCTURE row TO <value>.
    IF sy-subrc = 0 AND <value> IS NOT INITIAL.
      result = condense( CONV string( <value> ) ).
    ENDIF.

  ENDMETHOD.

  METHOD set_striped.

    mv_no_stripes = xsdbool( val = abap_false ).
    result = me.

  ENDMETHOD.

  METHOD set_details.

    mv_no_details = xsdbool( val = abap_false ).
    result = me.

  ENDMETHOD.

  METHOD set_search_field.

    mv_no_search = xsdbool( val = abap_false ).
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

    result = xsdbool( mt_filter IS NOT INITIAL OR mv_search IS NOT INITIAL ).

  ENDMETHOD.

  METHOD add_footer.

    INSERT VALUE #( label = label
                    value = value ) INTO TABLE mt_footer.
    result = me.

  ENDMETHOD.

  METHOD get_footer.

    result = mt_footer.

  ENDMETHOD.

  METHOD has_selection.

    result = xsdbool( mv_selection_mode = cs_selection_mode-multiple
                   OR mv_selection_mode = cs_selection_mode-single ).

  ENDMETHOD.

  METHOD column_skipped.

    DATA(lv_box) = get_box_field( ).
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

    DATA(lv_box) = get_box_field( ).
    LOOP AT tab ASSIGNING FIELD-SYMBOL(<row>).
      DATA(lv_index) = sy-tabix.
      ASSIGN COMPONENT lv_box OF STRUCTURE <row> TO <box>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      <box> = xsdbool( line_exists( rows[ table_line = lv_index ] ) ).
    ENDLOOP.
    IF mv_selection_mode = cs_selection_mode-single.
      single_normalize( CHANGING tab = tab ).
    ENDIF.

  ENDMETHOD.

  METHOD single_normalize.

    FIELD-SYMBOLS <box> TYPE any.

    IF mv_selection_mode <> cs_selection_mode-single.
      RETURN.
    ENDIF.
    " the radio buttons of rows scrolled out of view are not reset by the
    " browser - the row that is new wins
    DATA(lt_selected) = get_selected_rows( tab ).
    IF lines( lt_selected ) > 1.
      DATA(lv_keep) = lt_selected[ 1 ].
      LOOP AT lt_selected INTO DATA(lv_row) WHERE table_line <> mv_single_row.
        lv_keep = lv_row.
        EXIT.
      ENDLOOP.
      DATA(lv_box) = get_box_field( ).
      LOOP AT lt_selected INTO lv_row WHERE table_line <> lv_keep.
        READ TABLE tab ASSIGNING FIELD-SYMBOL(<line>) INDEX lv_row.
        ASSIGN COMPONENT lv_box OF STRUCTURE <line> TO <box>.
        IF sy-subrc = 0.
          <box> = abap_false.
        ENDIF.
      ENDLOOP.
      mv_single_row = lv_keep.
    ELSEIF lines( lt_selected ) = 1.
      mv_single_row = lt_selected[ 1 ].
    ELSE.
      CLEAR mv_single_row.
    ENDIF.

  ENDMETHOD.

  METHOD get_aggregates.

    FIELD-SYMBOLS <cell> TYPE any.
    DATA lv_value TYPE decfloat34.
    DATA lv_count TYPE i.

    LOOP AT columns_visible( tab ) INTO DATA(ls_comp).
      DATA(ls_column) = column_setting( ls_comp-name ).
      DATA(lv_kind) = COND string( WHEN ls_column-aggregation IS NOT INITIAL THEN ls_column-aggregation
                                   WHEN ls_column-sum = abap_true THEN cs_aggregation-sum ).
      IF lv_kind IS INITIAL.
        CONTINUE.
      ENDIF.
      DATA(ls_aggregate) = VALUE ty_s_aggregate( column      = ls_comp-name
                                                 label       = ls_comp-label
                                                 aggregation = lv_kind ).
      CLEAR lv_count.
      LOOP AT tab ASSIGNING FIELD-SYMBOL(<row>).
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

    READ TABLE tab ASSIGNING FIELD-SYMBOL(<row>) INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = COND #( WHEN mv_title IS NOT INITIAL THEN mv_title ELSE 'Details'(012) )
        )->a( n = `contentWidth` v = `32rem`
        )->a( n = `resizable`    b = abap_true ).

    " every column of the row - hidden ones too, technical ones not
    DATA(lo_box) = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).
    LOOP AT z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ) INTO DATA(ls_comp).
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE <row> TO <cell>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(ls_column) = column_setting( ls_comp-name ).
      lo_box->ele( `HBox`
          )->tag( `Label`
          )->a( n = `text`  t = |{ COND #( WHEN ls_column-text IS NOT INITIAL THEN ls_column-text ELSE ls_comp-label ) }:|
          )->a( n = `width` v = `12rem`
          )->tag( `Text`
          )->a( n = `text` t = cell_to_text( val  = <cell>
                                             comp = ls_comp ) ).
    ENDLOOP.

    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = CONV #( 'Close'(013) )
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-details_close ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD set_color_field.

    mv_color_field = to_upper( name ).
    result = me.

  ENDMETHOD.

  METHOD set_column_color.

    DATA(lr_column) = column_get( name ).
    lr_column->color = to_upper( color ).
    lr_column->color_field = to_upper( field ).
    result = me.

  ENDMETHOD.

  METHOD color_state.

    DATA(lv_code) = to_upper( condense( code ) ).
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
    DATA(lv_code) = |(String($\{{ to_upper( field ) }\} \|\| '')).substring(1,2)|.
    result = |\{= { lv_code } === '1' ? 'Indication05' : { lv_code } === '3' ? 'Warning' : |
          && |{ lv_code } === '4' ? 'Indication06' : { lv_code } === '5' ? 'Success' : |
          && |{ lv_code } === '6' ? 'Error' : { lv_code } === '7' ? 'Indication03' : 'None' \}|.

  ENDMETHOD.

  METHOD set_filter.

    DATA(lv_name) = to_upper( name ).
    DELETE mt_filter WHERE name = lv_name.
    DATA(lt_rows) = rows.
    DELETE lt_rows WHERE low IS INITIAL AND high IS INITIAL.
    IF lt_rows IS NOT INITIAL.
      INSERT VALUE #( name = lv_name
                      rows = lt_rows ) INTO TABLE mt_filter.
    ENDIF.
    mv_page = 1.
    result = me.

  ENDMETHOD.

  METHOD get_filter.

    result = mt_filter.

  ENDMETHOD.

  METHOD clear_filter.

    IF name IS INITIAL.
      CLEAR mt_filter.
    ELSE.
      DATA(lv_name) = to_upper( name ).
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

    " a pattern needs the text of the cell - a number or a NUMC would lose
    " the * of it
    CLEAR: typed, pattern.
    LOOP AT rows INTO DATA(ls_row).
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

    CLEAR error.
    DATA(lo_table) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( tab ) ).
    DATA(lo_struct) = CAST cl_abap_structdescr( lo_table->get_table_line_type( ) ).
    DATA(lv_name) = to_upper( name ).
    DATA(lt_comp) = lo_struct->get_components( ).
    READ TABLE lt_comp INTO DATA(ls_comp) WITH KEY name = lv_name.
    IF sy-subrc <> 0 OR ls_comp-type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_value) = COND #( WHEN pattern = abap_true
                                 THEN CAST cl_abap_datadescr( cl_abap_elemdescr=>get_string( ) )
                                 ELSE ls_comp-type ).
        " create( ), not get( ) - get( ) is a stub in the transpiled runtime
        DATA(lo_line) = cl_abap_structdescr=>create(
            VALUE #( ( name = `SIGN`   type = cl_abap_elemdescr=>get_c( 1 ) )
                     ( name = `OPTION` type = cl_abap_elemdescr=>get_c( 2 ) )
                     ( name = `LOW`    type = lo_value )
                     ( name = `HIGH`   type = lo_value ) ) ).
        DATA(lo_range) = cl_abap_tabledescr=>create( lo_line ).

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
    DATA lt_check   TYPE STANDARD TABLE OF ty_s_check WITH EMPTY KEY.
    DATA ls_check   TYPE ty_s_check.
    DATA lt_typed   TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_pattern TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_incl    TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lt_excl    TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA lv_error   TYPE string.
    FIELD-SYMBOLS <cell> TYPE any.

    LOOP AT mt_filter INTO DATA(ls_filter).
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
      ls_check-has_incl = xsdbool( line_exists( ls_filter-rows[ sign = `I` ] )
                                   OR line_exists( ls_filter-rows[ sign = `` ] ) ).
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

    DATA(lt_visible) = columns_visible( tab ).
    LOOP AT tab ASSIGNING FIELD-SYMBOL(<row>).
      DATA(lv_index) = sy-tabix.
      DATA(lv_pass) = abap_true.
      " the search: the text in one of the columns shown, case ignored (CS)
      IF mv_search IS NOT INITIAL.
        lv_pass = abap_false.
        LOOP AT lt_visible INTO DATA(ls_visible).
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
        DATA(lv_text) = |{ <cell> }|.
        DATA(lv_incl) = xsdbool( ls_check-has_incl = abap_false
                                 OR filter_match( val   = <cell>
                                                  range = ls_check-incl_typed ) = abap_true
                                 OR filter_match( val   = lv_text
                                                  range = ls_check-incl_pattern ) = abap_true ).
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
      INSERT <line> INTO TABLE <incl> ASSIGNING FIELD-SYMBOL(<new>).
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <new> TO <sign>.
      <sign> = `I`.
    ENDLOOP.
    result = z2ui5_cl_cgui_context=>range_check( val   = val
                                                 range = <incl> ).

  ENDMETHOD.

  METHOD set_filter_change.

    mv_no_filter = xsdbool( val = abap_false ).
    result = me.

  ENDMETHOD.

  METHOD add_header.

    INSERT VALUE #( label = label
                    value = value ) INTO TABLE mt_header.
    result = me.

  ENDMETHOD.

  METHOD get_header.

    result = mt_header.

  ENDMETHOD.

  METHOD clear_header.

    CLEAR mt_header.

  ENDMETHOD.

  METHOD render_header.

    DATA(lt_line) = COND ty_t_header( WHEN items IS SUPPLIED THEN items ELSE mt_header ).
    IF lt_line IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lo_box) = node->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMarginBeginEnd sapUiSmallMarginTop` ).
    LOOP AT lt_line INTO DATA(ls_header).
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

    mv_no_layout = xsdbool( val = abap_false ).
    result = me.

  ENDMETHOD.

  METHOD get_layout_change.

    result = xsdbool( mv_no_layout = abap_false ).

  ENDMETHOD.

  METHOD get_layout.

    DATA lv_seq TYPE i.

    LOOP AT z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ) INTO DATA(ls_comp).
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      lv_seq = lv_seq + 1.
      DATA(ls_column) = column_setting( ls_comp-name ).
      INSERT VALUE #( name     = ls_comp-name
                      text     = COND #( WHEN ls_column-text IS NOT INITIAL THEN ls_column-text ELSE ls_comp-label )
                      hidden   = ls_column-hidden
                      position = COND #( WHEN ls_column-position > 0 THEN ls_column-position ELSE 1000 + lv_seq )
                      sort     = ls_column-sort
                      sort_seq = ls_column-sort_seq
                      sum      = ls_column-sum
                      subtotal = ls_column-subtotal
                      numeric  = is_numeric( ls_comp-type_kind ) ) INTO TABLE result.
    ENDLOOP.

    SORT result STABLE BY position.
    LOOP AT result REFERENCE INTO DATA(lr_layout).
      lr_layout->position = sy-tabix.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_layout.

    LOOP AT layout INTO DATA(ls_layout).
      DATA(lr_column) = column_get( ls_layout-name ).
      lr_column->hidden   = ls_layout-hidden.
      lr_column->position = ls_layout-position.
      lr_column->sort     = to_upper( ls_layout-sort ).
      lr_column->sort_seq = COND #( WHEN ls_layout-sort IS NOT INITIAL THEN ls_layout-sort_seq ).
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
    DATA lt_index  TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lt_merged TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lv_right  TYPE abap_bool.
    DATA lv_a      TYPE i.
    DATA lv_b      TYPE i.
    DATA lv_number TYPE i.
    DATA lr_copy   TYPE REF TO data.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.

    DATA(lt_order) = sort_order( tab ).
    DATA(lv_lines) = lines( tab ).
    IF lt_order IS INITIAL OR lv_lines < 2.
      RETURN.
    ENDIF.
    DO lv_lines TIMES.
      lv_number = sy-index.
      INSERT lv_number INTO TABLE lt_index.
    ENDDO.

    DATA(lv_width) = 1.
    WHILE lv_width < lv_lines.
      CLEAR lt_merged.
      DATA(lv_left) = 1.
      WHILE lv_left <= lv_lines.
        " the runs [left, mid) and [mid, end) into one
        DATA(lv_mid) = nmin( val1 = lv_left + lv_width
                             val2 = lv_lines + 1 ).
        DATA(lv_end) = nmin( val1 = lv_left + 2 * lv_width
                             val2 = lv_lines + 1 ).
        DATA(lv_i) = lv_left.
        DATA(lv_j) = lv_mid.
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
    LOOP AT lt_index INTO DATA(lv_row).
      READ TABLE <copy> INDEX lv_row ASSIGNING <row>.
      INSERT <row> INTO TABLE tab.
    ENDLOOP.

  ENDMETHOD.

  METHOD rows_less.

    FIELD-SYMBOLS <row_a> TYPE any.
    FIELD-SYMBOLS <row_b> TYPE any.
    FIELD-SYMBOLS <val_a> TYPE any.
    FIELD-SYMBOLS <val_b> TYPE any.

    READ TABLE tab INDEX a ASSIGNING <row_a>.
    READ TABLE tab INDEX b ASSIGNING <row_b>.
    LOOP AT order INTO DATA(ls_order).
      DATA(lv_name) = condense( ls_order-name ).
      UNASSIGN: <val_a>, <val_b>.
      ASSIGN COMPONENT lv_name OF STRUCTURE <row_a> TO <val_a>.
      ASSIGN COMPONENT lv_name OF STRUCTURE <row_b> TO <val_b>.
      IF <val_a> IS NOT ASSIGNED OR <val_b> IS NOT ASSIGNED OR <val_a> = <val_b>.
        CONTINUE.
      ENDIF.
      IF ls_order-descending = abap_true.
        result = xsdbool( <val_a> > <val_b> ).
      ELSE.
        result = xsdbool( <val_a> < <val_b> ).
      ENDIF.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD sort_order.

    DATA(lt_comp) = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).
    DATA(lt_sorted) = mt_column.
    DELETE lt_sorted WHERE sort IS INITIAL.
    SORT lt_sorted BY sort_seq name.
    LOOP AT lt_sorted INTO DATA(ls_column).
      IF NOT line_exists( lt_comp[ name = ls_column-name ] ).
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name       = ls_column-name
                      descending = xsdbool( ls_column-sort = cs_sort-descending ) ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD sorter.

    DATA lt_part TYPE string_table.

    LOOP AT sort_order( tab ) INTO DATA(ls_order).
      INSERT |\{path: '{ ls_order-name }', descending: { COND #( WHEN ls_order-descending = abap_true THEN `true` ELSE `false` ) }\}| INTO TABLE lt_part.
    ENDLOOP.
    IF lt_part IS NOT INITIAL.
      result = |[{ concat_lines_of( table = lt_part sep = `, ` ) }]|.
    ENDIF.

  ENDMETHOD.

  METHOD get_subtotals.

    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.
    DATA lt_part TYPE string_table.
    DATA lt_sum  TYPE SORTED TABLE OF ty_s_subtotal WITH UNIQUE KEY group column.
    DATA lv_value TYPE decfloat34.

    DATA(lt_comp) = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).
    DATA(lt_group) = mt_column.
    DELETE lt_group WHERE subtotal = abap_false OR sort IS INITIAL.
    SORT lt_group BY sort_seq name.
    DATA(lt_summed) = mt_column.
    DELETE lt_summed WHERE sum = abap_false OR hidden = abap_true.
    IF lt_group IS INITIAL OR lt_summed IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT tab ASSIGNING <row>.
      CLEAR lt_part.
      LOOP AT lt_group INTO DATA(ls_group).
        READ TABLE lt_comp INTO DATA(ls_comp) WITH KEY name = ls_group-name.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT ls_group-name OF STRUCTURE <row> TO <cell>.
        INSERT cell_to_text( val  = <cell>
                             comp = ls_comp ) INTO TABLE lt_part.
      ENDLOOP.
      DATA(lv_group) = concat_lines_of( table = lt_part sep = ` / ` ).

      LOOP AT lt_summed INTO DATA(ls_summed).
        ASSIGN COMPONENT ls_summed-name OF STRUCTURE <row> TO <cell>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        TRY.
            lv_value = <cell>.
          CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
            CONTINUE.
        ENDTRY.
        READ TABLE lt_sum ASSIGNING FIELD-SYMBOL(<sum>) WITH TABLE KEY group  = lv_group
                                                                       column = ls_summed-name.
        IF sy-subrc = 0.
          <sum>-value = <sum>-value + lv_value.
        ELSE.
          INSERT VALUE #( group  = lv_group
                          column = ls_summed-name
                          value  = lv_value ) INTO TABLE lt_sum.
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
    DATA lt_width TYPE STANDARD TABLE OF ty_s_width WITH EMPTY KEY.
    DATA lt_cells TYPE STANDARD TABLE OF string_table WITH EMPTY KEY.
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

    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).

    DATA(lt_comp) = columns_visible( tab ).
    LOOP AT lt_comp INTO DATA(ls_comp).
      INSERT VALUE #( name  = ls_comp-name
                      width = strlen( ls_comp-label )
                      right = is_numeric( ls_comp-type_kind ) ) INTO TABLE lt_width.
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
        lt_width[ lv_index ]-width = nmin( val1 = 40
                                           val2 = nmax( val1 = lt_width[ lv_index ]-width
                                                        val2 = strlen( lv_text ) ) ).
      ENDLOOP.
      INSERT lt_cell INTO TABLE lt_cells.
    ENDLOOP.

    " the totals of the summed columns
    CLEAR lt_cell.
    LOOP AT lt_comp INTO ls_comp.
      lv_index = sy-tabix.
      DATA(ls_column) = column_setting( ls_comp-name ).
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
      lt_width[ lv_index ]-width = nmax( val1 = lt_width[ lv_index ]-width
                                         val2 = strlen( lv_text ) ).
    ENDLOOP.

    " header, rule, rows, rule and totals
    CLEAR lv_line.
    LOOP AT lt_comp INTO ls_comp.
      lv_index = sy-tabix.
      DATA(lv_width) = lt_width[ lv_index ]-width.
      lv_text = ls_comp-label.
      IF strlen( lv_text ) > lv_width.
        lv_text = substring( val = lv_text len = lv_width ).
      ENDIF.
      lv_line = |{ lv_line }{ lv_text WIDTH = lv_width } |.
    ENDLOOP.
    LOOP AT mt_header INTO DATA(ls_header).
      INSERT COND string( WHEN ls_header-label IS INITIAL THEN ls_header-value
                          ELSE |{ ls_header-label }: { ls_header-value }| ) INTO TABLE result.
    ENDLOOP.
    IF mt_header IS NOT INITIAL.
      INSERT `` INTO TABLE result.
    ENDIF.
    INSERT lv_line INTO TABLE result.
    DATA(lv_rule) = repeat( val = `-` occ = strlen( lv_line ) ).
    INSERT lv_rule INTO TABLE result.

    IF lv_total = abap_true.
      INSERT lt_cell INTO TABLE lt_cells.
    ENDIF.
    DATA(lv_rows) = lines( lt_cells ).
    LOOP AT lt_cells INTO DATA(lt_values).
      IF lv_total = abap_true AND sy-tabix = lv_rows.
        INSERT lv_rule INTO TABLE result.
      ENDIF.
      CLEAR lv_line.
      LOOP AT lt_values INTO lv_text.
        lv_index = sy-tabix.
        DATA(ls_width) = lt_width[ lv_index ].
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
    LOOP AT mt_footer INTO DATA(ls_footer).
      INSERT COND string( WHEN ls_footer-label IS INITIAL THEN ls_footer-value
                          ELSE |{ ls_footer-label }: { ls_footer-value }| ) INTO TABLE result.
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

    CREATE DATA lr_copy LIKE tab.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = tab.
    sort_rows( CHANGING tab = <copy> ).
    DATA(lt_visible) = columns_visible( tab ).

    INSERT |{ lc_xml }<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>|
           INTO TABLE lt_xml.
    LOOP AT lt_visible INTO DATA(ls_visible).
      INSERT |<c t="inlineStr"><is><t>{ xlsx_escape( ls_visible-label ) }</t></is></c>| INTO TABLE lt_cell.
    ENDLOOP.
    INSERT |<row>{ concat_lines_of( lt_cell ) }</row>| INTO TABLE lt_xml.

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
            INSERT |<c><v>{ <cell> }</v></c>| INTO TABLE lt_cell.
          WHEN OTHERS.
            INSERT |<c t="inlineStr"><is><t>{ xlsx_escape( cell_to_text( val  = <cell>
                                                                       comp = ls_visible ) ) }</t></is></c>|
                   INTO TABLE lt_cell.
        ENDCASE.
      ENDLOOP.
      INSERT |<row>{ concat_lines_of( lt_cell ) }</row>| INTO TABLE lt_xml.
    ENDLOOP.
    INSERT `</sheetData></worksheet>` INTO TABLE lt_xml.

    DATA(lo_zip) = NEW cl_abap_zip( ).
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

    DATA(lv_name) = to_upper( name ).
    READ TABLE mt_column REFERENCE INTO result WITH KEY name = lv_name.
    IF sy-subrc <> 0.
      INSERT VALUE #( name = lv_name ) INTO TABLE mt_column REFERENCE INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD column_setting.

    READ TABLE mt_column INTO result WITH KEY name = name.

  ENDMETHOD.

  METHOD has_box_field.

    DATA(lt_comp) = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).
    DATA(lv_box) = get_box_field( ).
    result = xsdbool( line_exists( lt_comp[ name = lv_box ] ) ).

  ENDMETHOD.

  METHOD get_selected_rows.

    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <box> TYPE any.

    DATA(lv_box) = get_box_field( ).
    LOOP AT tab ASSIGNING <row>.
      DATA(lv_index) = sy-tabix.
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

    DATA(lv_box) = get_box_field( ).
    LOOP AT tab ASSIGNING <row>.
      ASSIGN COMPONENT lv_box OF STRUCTURE <row> TO <box>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      <box> = val.
    ENDLOOP.

  ENDMETHOD.

  METHOD handle_event.

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
        DATA(lt_selected) = get_selected_rows( tab ).
        IF lt_selected IS NOT INITIAL.
          details_popup( client = client
                         tab    = tab
                         row    = lt_selected[ 1 ] ).
        ENDIF.
      WHEN cs_event-details_close.
        client->popup_destroy( ).
      WHEN cs_event-search.
        set_search( client->get_event_arg( ) ).
      WHEN OTHERS.
        result = abap_false.
    ENDCASE.

  ENDMETHOD.

  METHOD columns_visible.

    DATA lt_ordered TYPE ty_t_ordered.
    DATA lv_seq     TYPE i.

    " in the order of the components - a position set comes first
    LOOP AT z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ) INTO DATA(ls_comp).
      IF column_skipped( ls_comp-name ) = abap_true.
        CONTINUE.
      ENDIF.
      lv_seq = lv_seq + 1.
      DATA(ls_column) = column_setting( ls_comp-name ).
      IF ls_column-hidden = abap_true.
        CONTINUE.
      ENDIF.
      IF ls_column-text IS NOT INITIAL.
        ls_comp-label = ls_column-text.
      ENDIF.
      INSERT VALUE #( position = COND #( WHEN ls_column-position > 0 THEN ls_column-position ELSE 1000 + lv_seq )
                      seq      = lv_seq
                      comp     = ls_comp ) INTO TABLE lt_ordered.
    ENDLOOP.

    SORT lt_ordered BY position seq.
    LOOP AT lt_ordered INTO DATA(ls_ordered).
      INSERT ls_ordered-comp INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD render.

    DATA(lv_rows) = mv_visible_rows.
    IF lv_rows <= 0.
      lv_rows = lines( tab ).
      IF lv_rows > 15.
        lv_rows = 15.
      ELSEIF lv_rows < 3.
        lv_rows = 3.
      ENDIF.
    ENDIF.

    DATA(lv_multi) = xsdbool( has_selection( ) = abap_true AND has_box_field( tab ) = abap_true ).
    DATA(lv_sorter) = sorter( tab ).

    render_header( node ).

    DATA(lo_table) = node->ele( n = `Table` ns = `table`
        )->a( n = `xmlns:table`        v = `sap.ui.table`
        )->a( n = `xmlns:core`         v = `sap.ui.core`
        )->a( n = `core:require`       v = type_require( )
        )->a( n = `rows`               v = COND #( WHEN lv_sorter IS INITIAL
                                                   THEN client->_bind( tab )
                                                   ELSE |\{path: '{ client->_bind( val  = tab
                                                                                   path = abap_true ) }', sorter: { lv_sorter }\}| )
        )->a( n = `selectionMode`      v = `None`
        )->a( n = `alternateRowColors` b = xsdbool( mv_no_stripes = abap_false )
        )->a( n = `visibleRowCount`    v = |{ lv_rows }|
        )->a( n = `class`              v = `sapUiSmallMargin` ).

    " the attributes of the table before its first child: a( ) lands on the
    " child added last
    IF mv_line_selection = abap_true.
      lo_table->a( n = `cellClick` v = client->_event( val = cs_event-line_selection
                                                       arg = `${$parameters>/rowBindingContext}.getPath()` ) ).
    ENDIF.

    " fixed: as set, or the key columns from the left
    DATA(lv_fixed) = mv_fixed_columns.
    IF lv_fixed = 0.
      LOOP AT columns_visible( tab ) INTO DATA(ls_visible).
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

    DATA(lt_comp) = z2ui5_cl_cgui_context=>rtti_get_t_comp( tab ).
    IF mv_color_field IS NOT INITIAL AND line_exists( lt_comp[ name = mv_color_field ] ).
      lo_table->ele( n = `rowSettingsTemplate` ns = `table`
          )->tag( n = `RowSettings` ns = `table`
          )->a( n = `highlight` v = color_binding( mv_color_field ) ).
    ENDIF.

    render_toolbar( node   = lo_table->ele( n = `extension` ns = `table` )
                    client = client
                    multi  = lv_multi
                    total  = COND #( WHEN total >= 0 THEN total ELSE lines( tab ) )
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

    DATA(lo_bar) = node->ele( `OverflowToolbar` ).
    DATA(lv_count) = |{ total }|.
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

    " the pages of a large table
    IF mv_page_size > 0 AND total > mv_page_size.
      DATA(lv_pages) = ( total + mv_page_size - 1 ) DIV mv_page_size.
      DATA(lv_page) = get_page( ).
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://close-command-field`
          )->a( n = `enabled` b = xsdbool( lv_page > 1 )
          )->a( n = `press`   v = client->_event( val = cs_event-page arg = cs_page-first )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://navigation-left-arrow`
          )->a( n = `enabled` b = xsdbool( lv_page > 1 )
          )->a( n = `press`   v = client->_event( val = cs_event-page arg = cs_page-previous )
          )->tag( `Text`
          )->a( n = `text` t = replace( val  = replace( val  = 'Page &1 of &2'(008)
                                                        sub  = `&1`
                                                        with = |{ lv_page }| )
                                        sub  = `&2`
                                        with = |{ lv_pages }| )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://navigation-right-arrow`
          )->a( n = `enabled` b = xsdbool( lv_page < lv_pages )
          )->a( n = `press`   v = client->_event( val = cs_event-page arg = cs_page-next )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://open-command-field`
          )->a( n = `enabled` b = xsdbool( lv_page < lv_pages )
          )->a( n = `press`   v = client->_event( val = cs_event-page arg = cs_page-last ) ).
    ENDIF.

    IF multi = abap_true.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://multiselect-all`
          )->a( n = `tooltip` t = CONV #( 'Select All'(001) )
          )->a( n = `press`   v = client->_event( cs_event-select_all )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://multiselect-none`
          )->a( n = `tooltip` t = CONV #( 'Deselect All'(002) )
          )->a( n = `press`   v = client->_event( cs_event-deselect_all ) ).
    ENDIF.

    LOOP AT mt_function REFERENCE INTO DATA(lr_function).
      lo_bar->tag( `Button`
          )->a( n = `text`    t = lr_function->text
          )->a( n = `icon`    v = lr_function->icon
          )->a( n = `tooltip` t = lr_function->tooltip
          )->a( n = `press`   v = client->_event( lr_function->name ) ).
    ENDLOOP.

    IF mv_no_search = abap_false.
      lo_bar->tag( `SearchField`
          )->a( n = `value`       t = mv_search
          )->a( n = `width`       v = `14rem`
          )->a( n = `placeholder` t = CONV #( 'Search'(014) )
          )->a( n = `search`      v = client->_event( val = cs_event-search
                                                      arg = `${$parameters>/query}` ) ).
    ENDIF.

    IF multi = abap_true AND mv_no_details = abap_false.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://detail-view`
          )->a( n = `tooltip` t = CONV #( 'Details'(012) )
          )->a( n = `press`   v = client->_event( cs_event-details ) ).
    ENDIF.

    IF mv_no_filter = abap_false.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://filter`
          )->a( n = `text`    v = COND #( WHEN mt_filter IS NOT INITIAL THEN |{ lines( mt_filter ) }| )
          )->a( n = `type`    v = COND #( WHEN mt_filter IS NOT INITIAL THEN `Emphasized` ELSE `Default` )
          )->a( n = `tooltip` t = CONV #( 'Filter'(010) )
          )->a( n = `press`   v = client->_event( cs_event-filter ) ).
      IF is_filtered( ) = abap_true.
        lo_bar->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://clear-filter`
            )->a( n = `tooltip` t = CONV #( 'Delete Filter'(011) )
            )->a( n = `press`   v = client->_event( cs_event-filter_clear ) ).
      ENDIF.
    ENDIF.

    IF mv_no_layout = abap_false.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://action-settings`
          )->a( n = `tooltip` t = CONV #( 'Change Layout'(005) )
          )->a( n = `press`   v = client->_event( cs_event-layout ) ).
    ENDIF.

    IF mv_no_export = abap_false.
      lo_bar->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://excel-attachment`
          )->a( n = `tooltip` t = CONV #( 'Export to Excel'(006) )
          )->a( n = `press`   v = client->_event( cs_event-export_xlsx )
          )->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://document-text`
          )->a( n = `tooltip` t = CONV #( 'Export'(003) )
          )->a( n = `press`   v = client->_event( cs_event-export ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_columns.

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

    LOOP AT columns_visible( tab ) INTO DATA(ls_comp).

      DATA(ls_column) = column_setting( ls_comp-name ).

      DATA(lv_align) = `Begin`.
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

      DATA(lv_width) = ls_column-width.
      IF lv_width IS INITIAL AND mv_no_optimize = abap_false.
        lv_width = column_width( comp = ls_comp
                                 tab  = tab ).
      ENDIF.

      DATA(lo_column) = node->ele( n = `Column` ns = `table`
          )->a( n = `sortProperty`   t = ls_comp-name
          )->a( n = `filterProperty` t = ls_comp-name
          )->a( n = `hAlign`         v = lv_align ).
      IF lv_width IS NOT INITIAL.
        lo_column->a( n = `width` t = lv_width ).
      ENDIF.
      IF ls_column-sort IS NOT INITIAL.
        lo_column->a( n = `sorted`    b = abap_true
            )->a( n = `sortOrder` v = COND #( WHEN ls_column-sort = cs_sort-descending THEN `Descending` ELSE `Ascending` ) ).
      ENDIF.

      lo_column->ele( n = `label` ns = `table`
          )->tag( `Label`
              )->a( n = `text`   t = ls_comp-label
              )->a( n = `design` v = COND #( WHEN ls_column-key = abap_true THEN `Bold` ELSE `Standard` ) ).
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
        node->tag( `CheckBox`
            )->a( n = `selected` v = |\{{ comp-name }\}|
            )->a( n = `select`   v = client->_event( val   = cs_event-hotspot
                                                     t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                      ( comp-name ) ) ) ).
        RETURN.
      WHEN cs_cell_type-button.
        node->tag( `Button`
            )->a( n = `text`  v = cell_binding( comp   = comp
                                                column = column )
            )->a( n = `press` v = client->_event( val   = cs_event-hotspot
                                                  t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                   ( comp-name ) ) ) ).
        RETURN.
      WHEN cs_cell_type-dropdown.
        " shown: the text of the key
        DATA(lt_value) = dropdown_values( comp-name ).
        DATA(lv_expr) = |$\{{ comp-name }\}|.
        LOOP AT lt_value INTO DATA(ls_value).
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
      node->tag( `Link`
          )->a( n = `text`  v = cell_binding( comp   = comp
                                              column = column )
          )->a( n = `press` v = client->_event( val   = cs_event-hotspot
                                                t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                 ( comp-name ) ) ) ).
      RETURN.
    ENDIF.

    IF column-color IS NOT INITIAL OR column-color_field IS NOT INITIAL.
      node->tag( `ObjectStatus`
          )->a( n = `text`  v = cell_binding( comp   = comp
                                              column = column )
          )->a( n = `state` v = COND #( WHEN column-color_field IS NOT INITIAL
                                        THEN color_binding( column-color_field )
                                        ELSE color_state( column-color ) ) ).
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


    DATA(lv_editable) = edit_binding( ).

    IF column-cell_type = cs_cell_type-dropdown.
      DATA(lo_select) = node->ele( `Select`
          )->a( n = `selectedKey`    v = |\{{ comp-name }\}|
          )->a( n = `forceSelection` b = abap_false
          )->a( n = `change`         v = client->_event( val   = cs_event-data_changed
                                                         t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                          ( comp-name ) ) ) ).
      IF lv_editable IS NOT INITIAL.
        lo_select->a( n = `enabled` v = lv_editable ).
      ENDIF.
      DATA(lo_items) = lo_select->ele( `items` ).
      lo_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = ``
          )->a( n = `text` v = `` ).
      LOOP AT dropdown_values( comp-name ) INTO DATA(ls_value).
        lo_items->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = ls_value-key
            )->a( n = `text` t = ls_value-text ).
      ENDLOOP.
      RETURN.
    ENDIF.

    IF comp-boolean = abap_true.
      node->tag( `CheckBox`
          )->a( n = `selected` v = |\{{ comp-name }\}|
          )->a( n = `select`   v = client->_event( val   = cs_event-data_changed
                                                   t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                    ( comp-name ) ) ) ).
      IF lv_editable IS NOT INITIAL.
        node->a( n = `editable` v = lv_editable ).
      ENDIF.
      RETURN.
    ENDIF.

    CASE comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        node->tag( `DatePicker`
            )->a( n = `value`         v = |\{{ comp-name }\}|
            )->a( n = `valueFormat`   v = `yyyy-MM-dd`
            )->a( n = `displayFormat` v = `medium`
            )->a( n = `change`        v = client->_event( val   = cs_event-data_changed
                                                          t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                           ( comp-name ) ) ) ).
        IF lv_editable IS NOT INITIAL.
          node->a( n = `editable` v = lv_editable ).
        ENDIF.
      WHEN cl_abap_typedescr=>typekind_time.
        node->tag( `TimePicker`
            )->a( n = `value`         v = |\{{ comp-name }\}|
            )->a( n = `valueFormat`   v = `HH:mm:ss`
            )->a( n = `displayFormat` v = `HH:mm:ss`
            )->a( n = `change`        v = client->_event( val   = cs_event-data_changed
                                                          t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                           ( comp-name ) ) ) ).
        IF lv_editable IS NOT INITIAL.
          node->a( n = `editable` v = lv_editable ).
        ENDIF.
      WHEN OTHERS.
        IF is_numeric( comp-type_kind ) = abap_true.
          node->tag( `Input`
              )->a( n = `value`     v = cell_binding( comp   = comp
                                                      column = column )
              )->a( n = `textAlign` v = `End`
              )->a( n = `change`    v = client->_event( val   = cs_event-data_changed
                                                        t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                         ( comp-name ) ) ) ).
          IF column-f4 = abap_true.
            node->a( n = `showValueHelp`    b = abap_true
                )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                                 t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                                  ( comp-name ) ) ) ).
          ENDIF.
          IF lv_editable IS NOT INITIAL.
            node->a( n = `editable` v = lv_editable ).
          ENDIF.
        ELSE.
          node->tag( `Input`
              )->a( n = `value`  v = |\{{ comp-name }\}|
              )->a( n = `change` v = client->_event( val   = cs_event-data_changed
                                                     t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                      ( comp-name ) ) ) ).
          IF column-f4 = abap_true.
            node->a( n = `showValueHelp`    b = abap_true
                )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                                 t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                                  ( comp-name ) ) ) ).
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

    DATA(lt_subtotal) = get_subtotals( tab ).
    IF lt_subtotal IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_layout) = get_layout( tab ).
    DATA(lt_group) = lt_layout.
    DELETE lt_group WHERE subtotal = abap_false OR sort IS INITIAL.
    SORT lt_group BY sort_seq name.
    DATA lt_text TYPE string_table.
    LOOP AT lt_group INTO DATA(ls_group).
      INSERT ls_group-text INTO TABLE lt_text.
    ENDLOOP.
    DATA(lt_summed) = lt_layout.
    DELETE lt_summed WHERE sum = abap_false OR hidden = abap_true.

    DATA(lo_table) = node->ele( `Table`
        )->a( n = `headerText` t = CONV #( 'Subtotals'(007) )
        )->a( n = `class`      v = `sapUiSmallMargin` ).
    DATA(lo_columns) = lo_table->ele( `columns` ).
    lo_columns->ele( `Column`
        )->tag( `Text`
        )->a( n = `text` t = concat_lines_of( table = lt_text sep = ` / ` ) ).
    LOOP AT lt_summed INTO DATA(ls_summed).
      lo_columns->ele( `Column`
          )->a( n = `hAlign` v = `End`
          )->tag( `Text`
          )->a( n = `text` t = ls_summed-text ).
    ENDLOOP.

    DATA(lo_items) = lo_table->ele( `items` ).
    DATA lv_group  TYPE string.
    DATA lv_number TYPE string.
    DATA lo_cells  TYPE REF TO z2ui5_cl_ui5_view_builder.
    LOOP AT lt_subtotal INTO DATA(ls_subtotal).
      IF lo_cells IS NOT BOUND OR ls_subtotal-group <> lv_group.
        lv_group = ls_subtotal-group.
        lo_cells = lo_items->ele( `ColumnListItem` )->ele( `cells` ).
        lo_cells->tag( `Text`
            )->a( n = `text` t = lv_group ).
        LOOP AT lt_summed INTO ls_summed.
          CLEAR lv_number.
          READ TABLE lt_subtotal INTO DATA(ls_value) WITH KEY group  = lv_group
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

    IF column-currency IS NOT INITIAL.
      result = |\{parts: [\{path: '{ comp-name }'\}, \{path: '{ column-currency }'\}], type: 'CurrType', formatOptions: \{showMeasure: false\}\}|.
      RETURN.
    ENDIF.
    IF column-quantity IS NOT INITIAL.
      result = |\{parts: [\{path: '{ comp-name }'\}, \{path: '{ column-quantity }'\}], type: 'UnitType', formatOptions: \{showMeasure: false\}\}|.
      RETURN.
    ENDIF.

    CASE comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        result = |\{path: '{ comp-name }', type: 'DateType', formatOptions: \{source: \{pattern: 'yyyy-MM-dd'\}\}\}|.
      WHEN cl_abap_typedescr=>typekind_time.
        result = |\{path: '{ comp-name }', type: 'TimeType', formatOptions: \{source: \{pattern: 'HH:mm:ss'\}\}\}|.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8.
        result = |\{path: '{ comp-name }', type: 'IntType', formatOptions: \{groupingEnabled: true\}\}|.
      WHEN cl_abap_typedescr=>typekind_packed.
        result = |\{path: '{ comp-name }', type: 'FloatType', formatOptions: \{minFractionDigits: { comp-decimals }, maxFractionDigits: { comp-decimals }, groupingEnabled: true\}\}|.
      WHEN cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        result = |\{path: '{ comp-name }', type: 'FloatType', formatOptions: \{groupingEnabled: true\}\}|.
      WHEN OTHERS.
        result = |\{{ comp-name }\}|.
    ENDCASE.

  ENDMETHOD.

  METHOD column_width.

    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.

    IF comp-boolean = abap_true.
      result = `5rem`.
      RETURN.
    ENDIF.

    DATA(lv_len) = strlen( comp-label ).
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
          result = COND #( WHEN val IS NOT INITIAL THEN `X` ).
        ELSE.
          result = |{ val }|.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD render_sums.

    DATA lo_sums TYPE REF TO z2ui5_cl_ui5_view_builder.

    LOOP AT get_aggregates( tab ) INTO DATA(ls_aggregate).
      IF lo_sums IS NOT BOUND.
        lo_sums = node->ele( `HBox`
            )->a( n = `justifyContent` v = `End`
            )->a( n = `wrap`           v = `Wrap`
            )->a( n = `class`          v = `sapUiSmallMarginEnd` ).
      ENDIF.
      DATA(lv_title) = SWITCH string( ls_aggregate-aggregation
                                      WHEN cs_aggregation-average THEN 'Average'(015)
                                      WHEN cs_aggregation-minimum THEN 'Minimum'(016)
                                      WHEN cs_aggregation-maximum THEN 'Maximum'(017)
                                      WHEN cs_aggregation-count   THEN 'Count'(018)
                                      ELSE 'Total'(004) ).
      DATA(lv_value) = COND string( WHEN ls_aggregate-aggregation = cs_aggregation-count
                                    THEN |{ CONV i( ls_aggregate-value ) NUMBER = USER }|
                                    WHEN ls_aggregate-aggregation = cs_aggregation-average
                                    THEN |{ ls_aggregate-value NUMBER = USER DECIMALS = 2 }|
                                    ELSE |{ ls_aggregate-value NUMBER = USER }| ).
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

    DATA(lv_sep) = mv_separator.
    IF lv_sep IS INITIAL.
      lv_sep = `;`.
    ENDIF.
    DATA(lt_comp) = columns_visible( tab ).

    LOOP AT lt_comp INTO DATA(ls_comp).
      INSERT csv_escape( val       = ls_comp-label
                         separator = lv_sep ) INTO TABLE lt_cell.
    ENDLOOP.
    INSERT concat_lines_of( table = lt_cell sep = lv_sep ) INTO TABLE lt_line.

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
      INSERT concat_lines_of( table = lt_cell sep = lv_sep ) INTO TABLE lt_line.
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

    DATA(lv_name) = mv_title.
    IF lv_name IS INITIAL.
      lv_name = `export`.
    ENDIF.

    IF to_upper( format ) = cs_format-xlsx.
      DATA(lv_xlsx) = to_xlsx( tab ).
      IF lv_xlsx IS NOT INITIAL.
        client->follow_up_action( val   = client->cs_event-download_b64_file
                                  t_arg = VALUE #( ( |data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,|
                                                  && z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_xlsx ) )
                                                   ( |{ lv_name }.xlsx| ) ) ).
        RETURN.
      ENDIF.
    ENDIF.

    " UTF-8 with a byte order mark - Excel reads the umlauts right then
    DATA(lv_csv) = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( to_csv( tab ) ).
    DATA(lv_bom) = CONV xstring( `EFBBBF` ).
    CONCATENATE lv_bom lv_csv INTO lv_csv IN BYTE MODE.

    client->follow_up_action( val   = client->cs_event-download_b64_file
                              t_arg = VALUE #( ( |data:text/csv;charset=utf-8;base64,{ z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_csv ) }| )
                                               ( |{ lv_name }.csv| ) ) ).

  ENDMETHOD.

  METHOD type_require.

    result = `{DateType: 'sap/ui/model/type/Date', TimeType: 'sap/ui/model/type/Time', `
          && `FloatType: 'sap/ui/model/type/Float', IntType: 'sap/ui/model/type/Integer', `
          && `CurrType: 'sap/ui/model/type/Currency', UnitType: 'sap/ui/model/type/Unit'}`.

  ENDMETHOD.

  METHOD stringify.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height`       v = `100%` ).

    DATA(page) = view->ele( `Page`
        )->a( n = `title` t = mv_title ).

    render( node   = page
            client = client
            tab    = tab ).

    result = view->stringify( ).

  ENDMETHOD.

ENDCLASS.
