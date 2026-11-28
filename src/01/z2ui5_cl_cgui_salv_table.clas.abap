"! The stand-in of cl_salv_table and cl_salv_events_table - for a report
"! that keeps its SALV object and uses it after display( ): an attribute of
"! a local class, its event handlers, get_selections( ) of the rows the user
"! picked (report2UI5 writes alv( ) for a SALV a report only sets up and
"! shows). The table shows as a grid (z2ui5_cl_cgui_alv_grid) in
"! r_container, or on the screen itself: the columns with their texts,
"! hidden and technical columns and hotspots, the title, the striped rows,
"! the functions added as buttons. A button raises added_function, a double
"! click double_click, a hotspot link_click - for the handlers SET HANDLER
"! set for get_event( ), which is the table itself
CLASS z2ui5_cl_cgui_salv_table DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_function TYPE c LENGTH 30.
    TYPES ty_column TYPE c LENGTH 30.

    "! set_functions of set_screen_status( ) - the classic values; the
    "! functions of the grid do not depend on them here
    CONSTANTS c_functions_none TYPE i VALUE 0.
    CONSTANTS c_functions_default TYPE i VALUE 1.
    CONSTANTS c_functions_all TYPE i VALUE 2.

    EVENTS added_function
      EXPORTING
        VALUE(e_salv_function) TYPE ty_function OPTIONAL.

    EVENTS double_click
      EXPORTING
        VALUE(row)    TYPE i OPTIONAL
        VALUE(column) TYPE ty_column OPTIONAL.

    EVENTS link_click
      EXPORTING
        VALUE(row)    TYPE i OPTIONAL
        VALUE(column) TYPE ty_column OPTIONAL.

    CLASS-METHODS factory
      IMPORTING
        list_display   TYPE abap_bool DEFAULT abap_false
        r_container    TYPE REF TO z2ui5_cl_cgui_container OPTIONAL
        container_name TYPE clike OPTIONAL
      EXPORTING
        r_salv_table   TYPE REF TO z2ui5_cl_cgui_salv_table
      CHANGING
        t_table        TYPE STANDARD TABLE.

    METHODS constructor
      IMPORTING
        container TYPE REF TO z2ui5_cl_cgui_container OPTIONAL.

    "! the table shows - a grid with the columns, the settings and the
    "! functions as they are now
    METHODS display.

    "! the table again - t_table is the table to show (the classic grid reads
    "! the table it was given by reference; the conversion passes it here)
    METHODS refresh
      IMPORTING
        s_stable     TYPE any OPTIONAL
        refresh_mode TYPE any OPTIONAL
      CHANGING
        t_table      TYPE STANDARD TABLE OPTIONAL.

    METHODS set_data
      CHANGING
        t_table TYPE STANDARD TABLE.

    METHODS get_columns
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_cols.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_sorts
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_filters
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_print
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS get_functional_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_config.

    "! the events of the table - the table itself
    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_table.

    "! a popup of the SAP GUI - the grid shows on the screen
    METHODS set_screen_popup
      IMPORTING
        start_column TYPE i OPTIONAL
        end_column   TYPE i OPTIONAL
        start_line   TYPE i OPTIONAL
        end_line     TYPE i OPTIONAL.

    METHODS set_screen_status
      IMPORTING
        report        TYPE clike OPTIONAL
        pfstatus      TYPE clike OPTIONAL
        set_functions TYPE i     OPTIONAL.

    "! the events of the grid - passed on as the events of the table
    METHODS on_grid_command
      IMPORTING
        e_ucomm TYPE c OPTIONAL.

    METHODS on_grid_double_click
      IMPORTING
        e_row    TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_row OPTIONAL
        e_column TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_col OPTIONAL.

    METHODS on_grid_hotspot
      IMPORTING
        e_row_id    TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_row OPTIONAL
        e_column_id TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_col OPTIONAL.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the object is kept with the report between
    " the roundtrips, and the transpiled runtime restores PROTECTED
    " attributes of the draft but not PRIVATE ones
    DATA mr_table     TYPE REF TO data.
    " the attribute of the report the table is - a reference to it is a
    " copy once the draft has rebuilt it
    DATA mv_table     TYPE string.
    DATA mo_container TYPE REF TO z2ui5_cl_cgui_container.
    DATA mo_grid      TYPE REF TO z2ui5_cl_cgui_alv_grid.
    DATA mo_columns   TYPE REF TO z2ui5_cl_cgui_salv_cols.
    DATA mo_settings  TYPE REF TO z2ui5_cl_cgui_salv_config.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_fcat,
        fieldname TYPE string,
        scrtext_l TYPE string,
        no_out    TYPE abap_bool,
        tech      TYPE abap_bool,
        hotspot   TYPE abap_bool,
        key       TYPE abap_bool,
        outputlen TYPE i,
        do_sum    TYPE abap_bool,
        no_zero   TYPE abap_bool,
        col_pos   TYPE i,
        tooltip   TYPE string,
        just      TYPE c LENGTH 1,
      END OF ty_s_fcat.
    TYPES ty_t_fcat TYPE STANDARD TABLE OF ty_s_fcat WITH DEFAULT KEY.
    TYPES:
      "! LVC_S_SORT - what set_sort_classic( ) of the grid reads
      BEGIN OF ty_s_sort,
        spos      TYPE i,
        fieldname TYPE string,
        up        TYPE abap_bool,
        down      TYPE abap_bool,
        subtot    TYPE abap_bool,
      END OF ty_s_sort.
    TYPES ty_t_sort TYPE STANDARD TABLE OF ty_s_sort WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_layout,
        grid_title TYPE string,
        zebra      TYPE abap_bool,
        sel_mode   TYPE c LENGTH 1,
      END OF ty_s_layout.

    METHODS fieldcat
      RETURNING
        VALUE(result) TYPE ty_t_fcat.

    "! the table of the report: the attribute by its name, else the
    "! reference factory( ) or set_data( ) got
    METHODS table
      RETURNING
        VALUE(result) TYPE REF TO data.

    METHODS table_keep
      CHANGING
        t_table TYPE STANDARD TABLE.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_table IMPLEMENTATION.

  METHOD factory.

    DATA lr_line TYPE REF TO data.
    FIELD-SYMBOLS <line> TYPE data.

    CREATE OBJECT r_salv_table EXPORTING CONTAINER = r_container.
    r_salv_table->table_keep( CHANGING t_table = t_table ).
    CREATE DATA lr_line LIKE LINE OF t_table.

    ASSIGN lr_line->* TO <line>.
    CREATE OBJECT r_salv_table->mo_columns EXPORTING LINE = <line>.

  ENDMETHOD.

  METHOD constructor.
    DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_control.

    super->constructor( ).
    " no part of the screen of its own - the grid of display( ) is

    CLEAR temp1.
    temp1-kind = z2ui5_if_cgui_gui=>cs_kind-salv.
    temp1-hidden = abap_true.
    add( temp1 ).
    mo_container = container.
    CREATE OBJECT mo_settings.

  ENDMETHOD.

  METHOD display.

    DATA lt_button TYPE z2ui5_if_cgui_gui=>ty_t_button.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    DATA lr_table TYPE REF TO data.
    DATA temp2 TYPE ty_s_layout.
    DATA temp1 TYPE z2ui5_cl_cgui_salv_table=>ty_s_layout-sel_mode.
    DATA ls_layout LIKE temp2.
    DATA lt_fcat TYPE z2ui5_cl_cgui_salv_table=>ty_t_fcat.
    DATA temp3 TYPE ty_t_sort.
    DATA lt_sort LIKE temp3.
    DATA ls_sort LIKE LINE OF mo_settings->mt_sort.
      DATA temp4 TYPE z2ui5_cl_cgui_salv_table=>ty_s_sort.
      DATA temp7 TYPE xsdboolean.
    DATA ls_function LIKE LINE OF mo_settings->mt_function.
      DATA temp5 TYPE z2ui5_if_cgui_gui=>ty_s_button.
      DATA temp6 LIKE REF TO lt_button.
    lr_table = table( ).
    IF go_report IS NOT BOUND OR lr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_table->* TO <table>.
    IF mo_grid IS NOT BOUND.
      CREATE OBJECT mo_grid EXPORTING i_parent = mo_container.
      mo_grid->set_handler( event   = `USER_COMMAND`
                            method  = `ON_GRID_COMMAND`
                            handler = me ).
      mo_grid->set_handler( event   = `DOUBLE_CLICK`
                            method  = `ON_GRID_DOUBLE_CLICK`
                            handler = me ).
      mo_grid->set_handler( event   = `HOTSPOT_CLICK`
                            method  = `ON_GRID_HOTSPOT`
                            handler = me ).
    ENDIF.

    CLEAR temp2.
    temp2-grid_title = mo_settings->mv_title.
    temp2-zebra = mo_settings->mv_striped.

    CASE mo_settings->mv_selection_mode.
      WHEN z2ui5_if_cgui_salv_c=>selection_mode-none.
        temp1 = ``.
      WHEN z2ui5_if_cgui_salv_c=>selection_mode-single.
        temp1 = `B`.
      WHEN OTHERS.
        temp1 = `A`.
    ENDCASE.
    temp2-sel_mode = temp1.

    ls_layout = temp2.

    lt_fcat = fieldcat( ).
    " the sorts added - with them the subtotals

    CLEAR temp3.

    lt_sort = temp3.

    LOOP AT mo_settings->mt_sort INTO ls_sort.

      CLEAR temp4.
      temp4-spos = sy-tabix.
      temp4-fieldname = ls_sort-columnname.

      temp7 = boolc( ls_sort-descending = abap_false ).
      temp4-up = temp7.
      temp4-down = ls_sort-descending.
      temp4-subtot = ls_sort-subtotal.
      INSERT temp4 INTO TABLE lt_sort.
    ENDLOOP.
    IF lt_sort IS INITIAL.
      mo_grid->set_table_for_first_display( EXPORTING  is_layout       = ls_layout
                                            CHANGING   it_outtab       = <table>
                                                       it_fieldcatalog = lt_fcat
                                            EXCEPTIONS OTHERS          = 1 ).
    ELSE.
      mo_grid->set_table_for_first_display( EXPORTING  is_layout       = ls_layout
                                            CHANGING   it_outtab       = <table>
                                                       it_fieldcatalog = lt_fcat
                                                       it_sort         = lt_sort
                                            EXCEPTIONS OTHERS          = 1 ).
    ENDIF.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT mo_settings->mt_function INTO ls_function.

      CLEAR temp5.
      temp5-fcode = ls_function-name.
      temp5-icon = ls_function-icon.
      temp5-text = ls_function-text.
      temp5-quickinfo = ls_function-tooltip.
      INSERT temp5 INTO TABLE lt_button.
    ENDLOOP.
    IF lt_button IS NOT INITIAL.

      GET REFERENCE OF lt_button INTO temp6.
go_report->grid_display( id        = mo_grid->get_id( )
                               functions = temp6 ).
    ENDIF.
    mo_settings->set_grid( mo_grid ).

  ENDMETHOD.

  METHOD fieldcat.

    " the columns in the order of get( ) - set_column_position( ) moves them
    DATA temp7 TYPE z2ui5_cl_cgui_salv_cols=>ty_t_column_ref.
    DATA ls_ref LIKE LINE OF temp7.
      DATA lv_position LIKE sy-tabix.
      DATA lo_column LIKE ls_ref-r_column.
      DATA temp8 TYPE z2ui5_cl_cgui_salv_table=>ty_s_fcat.
      DATA temp2 LIKE sy-subrc.
      DATA temp3 LIKE sy-tabix.
      DATA temp9 TYPE xsdboolean.
    temp7 = mo_columns->get( ).

    LOOP AT temp7 INTO ls_ref.

      lv_position = sy-tabix.

      lo_column = ls_ref-r_column.

      CLEAR temp8.
      temp8-fieldname = lo_column->mv_name.
      temp8-scrtext_l = lo_column->get_text( ).
      temp8-no_out = lo_column->mv_hidden.
      temp8-tech = lo_column->mv_technical.
      temp8-hotspot = lo_column->mv_hotspot.
      temp8-key = lo_column->mv_key.
      temp8-outputlen = lo_column->mv_length.


      temp3 = sy-tabix.
      READ TABLE mo_settings->mt_aggregation WITH KEY table_line = lo_column->mv_name TRANSPORTING NO FIELDS.
      temp2 = sy-subrc.
      sy-tabix = temp3.

      temp9 = boolc( temp2 = 0 ).
      temp8-do_sum = temp9.
      temp8-no_zero = lo_column->mv_no_zero.
      temp8-col_pos = lv_position.
      temp8-tooltip = lo_column->mv_tooltip.
      temp8-just = lo_column->mv_just.
      INSERT temp8 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD refresh.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    DATA lr_table TYPE REF TO data.

    IF mo_grid IS NOT BOUND.
      RETURN.
    ENDIF.

    lr_table = table( ).
    IF t_table IS SUPPLIED.
      mo_grid->refresh_table_display( CHANGING it_outtab = t_table ).
    ELSEIF lr_table IS BOUND.
      ASSIGN lr_table->* TO <table>.
      mo_grid->refresh_table_display( CHANGING it_outtab = <table> ).
    ENDIF.

  ENDMETHOD.

  METHOD set_data.

    table_keep( CHANGING t_table = t_table ).

  ENDMETHOD.

  METHOD table_keep.

    GET REFERENCE OF t_table INTO mr_table.
    CLEAR mv_table.
    IF go_report IS BOUND.
      mv_table = z2ui5_cl_cgui_context=>attri_name_by_ref( app = go_report
                                                           val = t_table ).
    ENDIF.

  ENDMETHOD.

  METHOD table.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    DATA lo_report TYPE REF TO object.

    IF mv_table IS NOT INITIAL AND go_report IS BOUND.
      lo_report = go_report.
      ASSIGN lo_report->(mv_table) TO <table>.
      IF <table> IS ASSIGNED.
        GET REFERENCE OF <table> INTO result.
        RETURN.
      ENDIF.
    ENDIF.
    result = mr_table.

  ENDMETHOD.

  METHOD get_columns.

    value = mo_columns.

  ENDMETHOD.

  METHOD get_display_settings.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_functions.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_selections.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_sorts.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_aggregations.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_layout.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_filters.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_print.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_functional_settings.

    value = mo_settings.

  ENDMETHOD.

  METHOD get_event.

    value = me.

  ENDMETHOD.

  METHOD set_screen_popup ##NEEDED.
  ENDMETHOD.

  METHOD set_screen_status ##NEEDED.
  ENDMETHOD.

  METHOD on_grid_command.

    DATA temp9 TYPE ty_function.
    DATA lv_function LIKE temp9.
    DATA temp10 LIKE REF TO lv_function.
DATA temp4 TYPE abap_parmbind_tab.
DATA temp5 LIKE LINE OF temp4.
    temp9 = e_ucomm.

    lv_function = temp9.

    GET REFERENCE OF lv_function INTO temp10.

CLEAR temp4.

temp5-name = `E_SALV_FUNCTION`.
temp5-kind = cl_abap_objectdescr=>exporting.
temp5-value = temp10.
INSERT temp5 INTO TABLE temp4.
raise_event( event  = `ADDED_FUNCTION`
                 params = temp4 ).

  ENDMETHOD.

  METHOD on_grid_double_click.

    DATA lv_column TYPE ty_column.
    DATA lv_row LIKE e_row-index.
    DATA temp11 LIKE REF TO lv_column.
DATA temp6 LIKE REF TO lv_row.
DATA temp1 TYPE abap_parmbind_tab.
DATA temp2 LIKE LINE OF temp1.
    lv_row = e_row-index.
    lv_column = e_column-fieldname.

    GET REFERENCE OF lv_column INTO temp11.

GET REFERENCE OF lv_row INTO temp6.

CLEAR temp1.

temp2-name = `ROW`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp6.
INSERT temp2 INTO TABLE temp1.
temp2-name = `COLUMN`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp11.
INSERT temp2 INTO TABLE temp1.
raise_event( event  = `DOUBLE_CLICK`
                 params = temp1 ).

  ENDMETHOD.

  METHOD on_grid_hotspot.

    DATA lv_column TYPE ty_column.
    DATA lv_row LIKE e_row_id-index.
    DATA temp12 LIKE REF TO lv_column.
DATA temp7 LIKE REF TO lv_row.
DATA temp3 TYPE abap_parmbind_tab.
DATA temp4 LIKE LINE OF temp3.
    lv_row = e_row_id-index.
    lv_column = e_column_id-fieldname.

    GET REFERENCE OF lv_column INTO temp12.

GET REFERENCE OF lv_row INTO temp7.

CLEAR temp3.

temp4-name = `ROW`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp7.
INSERT temp4 INTO TABLE temp3.
temp4-name = `COLUMN`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp12.
INSERT temp4 INTO TABLE temp3.
raise_event( event  = `LINK_CLICK`
                 params = temp3 ).

  ENDMETHOD.

ENDCLASS.
