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
      END OF ty_s_fcat.
    TYPES ty_t_fcat TYPE STANDARD TABLE OF ty_s_fcat WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_layout,
        grid_title TYPE string,
        zebra      TYPE abap_bool,
        sel_mode   TYPE c LENGTH 1,
      END OF ty_s_layout.

    DATA mr_table     TYPE REF TO data.
    DATA mo_container TYPE REF TO z2ui5_cl_cgui_container.
    DATA mo_grid      TYPE REF TO z2ui5_cl_cgui_alv_grid.
    DATA mo_columns   TYPE REF TO z2ui5_cl_cgui_salv_cols.
    DATA mo_settings  TYPE REF TO z2ui5_cl_cgui_salv_config.

    METHODS fieldcat
      RETURNING
        VALUE(result) TYPE ty_t_fcat.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_table IMPLEMENTATION.

  METHOD factory.

    DATA lr_line TYPE REF TO data.
    FIELD-SYMBOLS <line> TYPE data.

    CREATE OBJECT r_salv_table EXPORTING CONTAINER = r_container.
    GET REFERENCE OF t_table INTO r_salv_table->mr_table.
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
    DATA temp2 TYPE ty_s_layout.
    DATA temp1 TYPE z2ui5_cl_cgui_salv_table=>ty_s_layout-sel_mode.
    DATA ls_layout LIKE temp2.
    DATA lt_fcat TYPE z2ui5_cl_cgui_salv_table=>ty_t_fcat.
    DATA ls_function LIKE LINE OF mo_settings->mt_function.
      DATA temp3 TYPE z2ui5_if_cgui_gui=>ty_s_button.
      DATA temp4 LIKE REF TO lt_button.

    IF go_report IS NOT BOUND OR mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <table>.
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
    mo_grid->set_table_for_first_display( EXPORTING  is_layout       = ls_layout
                                          CHANGING   it_outtab       = <table>
                                                     it_fieldcatalog = lt_fcat
                                          EXCEPTIONS OTHERS          = 1 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT mo_settings->mt_function INTO ls_function.

      CLEAR temp3.
      temp3-fcode = ls_function-name.
      temp3-icon = ls_function-icon.
      temp3-text = ls_function-text.
      temp3-quickinfo = ls_function-tooltip.
      INSERT temp3 INTO TABLE lt_button.
    ENDLOOP.
    IF lt_button IS NOT INITIAL.

      GET REFERENCE OF lt_button INTO temp4.
go_report->grid_display( id        = mo_grid->get_id( )
                               functions = temp4 ).
    ENDIF.
    mo_settings->set_grid( mo_grid ).

  ENDMETHOD.

  METHOD fieldcat.

    DATA temp5 TYPE z2ui5_cl_cgui_salv_cols=>ty_t_column_ref.
    DATA ls_ref LIKE LINE OF temp5.
      DATA lo_column LIKE ls_ref-r_column.
      DATA temp6 TYPE z2ui5_cl_cgui_salv_table=>ty_s_fcat.
      DATA temp2 TYPE z2ui5_cl_cgui_salv_table=>ty_s_fcat-scrtext_l.
    temp5 = mo_columns->get( ).

    LOOP AT temp5 INTO ls_ref.

      lo_column = ls_ref-r_column.

      CLEAR temp6.
      temp6-fieldname = lo_column->mv_name.

      IF lo_column->mv_long IS NOT INITIAL.
        temp2 = lo_column->mv_long.
      ELSEIF lo_column->mv_medium IS NOT INITIAL.
        temp2 = lo_column->mv_medium.
      ELSE.
        temp2 = lo_column->mv_short.
      ENDIF.
      temp6-scrtext_l = temp2.
      temp6-no_out = lo_column->mv_hidden.
      temp6-tech = lo_column->mv_technical.
      temp6-hotspot = lo_column->mv_hotspot.
      temp6-key = lo_column->mv_key.
      temp6-outputlen = lo_column->mv_length.
      INSERT temp6 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD refresh.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    IF mo_grid IS NOT BOUND.
      RETURN.
    ENDIF.
    IF t_table IS SUPPLIED.
      mo_grid->refresh_table_display( CHANGING it_outtab = t_table ).
    ELSEIF mr_table IS BOUND.
      ASSIGN mr_table->* TO <table>.
      mo_grid->refresh_table_display( CHANGING it_outtab = <table> ).
    ENDIF.

  ENDMETHOD.

  METHOD set_data.

    GET REFERENCE OF t_table INTO mr_table.

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

    DATA temp7 TYPE ty_function.
    DATA lv_function LIKE temp7.
    DATA temp8 LIKE REF TO lv_function.
DATA temp3 TYPE abap_parmbind_tab.
DATA temp4 LIKE LINE OF temp3.
    temp7 = e_ucomm.

    lv_function = temp7.

    GET REFERENCE OF lv_function INTO temp8.

CLEAR temp3.

temp4-name = `E_SALV_FUNCTION`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp8.
INSERT temp4 INTO TABLE temp3.
raise_event( event  = `ADDED_FUNCTION`
                 params = temp3 ).

  ENDMETHOD.

  METHOD on_grid_double_click.

    DATA lv_column TYPE ty_column.
    DATA lv_row LIKE e_row-index.
    DATA temp9 LIKE REF TO lv_column.
DATA temp5 LIKE REF TO lv_row.
DATA temp1 TYPE abap_parmbind_tab.
DATA temp2 LIKE LINE OF temp1.
    lv_row = e_row-index.
    lv_column = e_column-fieldname.

    GET REFERENCE OF lv_column INTO temp9.

GET REFERENCE OF lv_row INTO temp5.

CLEAR temp1.

temp2-name = `ROW`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp5.
INSERT temp2 INTO TABLE temp1.
temp2-name = `COLUMN`.
temp2-kind = cl_abap_objectdescr=>exporting.
temp2-value = temp9.
INSERT temp2 INTO TABLE temp1.
raise_event( event  = `DOUBLE_CLICK`
                 params = temp1 ).

  ENDMETHOD.

  METHOD on_grid_hotspot.

    DATA lv_column TYPE ty_column.
    DATA lv_row LIKE e_row_id-index.
    DATA temp10 LIKE REF TO lv_column.
DATA temp6 LIKE REF TO lv_row.
DATA temp3 TYPE abap_parmbind_tab.
DATA temp4 LIKE LINE OF temp3.
    lv_row = e_row_id-index.
    lv_column = e_column_id-fieldname.

    GET REFERENCE OF lv_column INTO temp10.

GET REFERENCE OF lv_row INTO temp6.

CLEAR temp3.

temp4-name = `ROW`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp6.
INSERT temp4 INTO TABLE temp3.
temp4-name = `COLUMN`.
temp4-kind = cl_abap_objectdescr=>exporting.
temp4-value = temp10.
INSERT temp4 INTO TABLE temp3.
raise_event( event  = `LINK_CLICK`
                 params = temp3 ).

  ENDMETHOD.

ENDCLASS.
