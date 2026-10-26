"! The stand-in of cl_salv_table and cl_salv_events_table - for a report
"! that keeps its SALV object and uses it after display( ): an attribute of
"! a local class, its event handlers, get_selections( ) of the rows the user
"! picked (report2cloud writes alv( ) for a SALV a report only sets up and
"! shows). The table shows as a grid (z2ui5_cl_cgui_gui_alv_grid) in
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
        r_container    TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        container_name TYPE clike OPTIONAL
      EXPORTING
        r_salv_table   TYPE REF TO z2ui5_cl_cgui_salv_table
      CHANGING
        t_table        TYPE STANDARD TABLE.

    METHODS constructor
      IMPORTING
        container TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL.

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
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_columns.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_sorts
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_filters
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_print
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS get_functional_settings
      RETURNING
        VALUE(value) TYPE REF TO z2ui5_cl_cgui_salv_settings.

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
    TYPES ty_t_fcat TYPE STANDARD TABLE OF ty_s_fcat WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_layout,
        grid_title TYPE string,
        zebra      TYPE abap_bool,
        sel_mode   TYPE c LENGTH 1,
      END OF ty_s_layout.

    DATA mr_table     TYPE REF TO data.
    DATA mo_container TYPE REF TO z2ui5_cl_cgui_gui_container.
    DATA mo_grid      TYPE REF TO z2ui5_cl_cgui_gui_alv_grid.
    DATA mo_columns   TYPE REF TO z2ui5_cl_cgui_salv_columns.
    DATA mo_settings  TYPE REF TO z2ui5_cl_cgui_salv_settings.

    METHODS fieldcat
      RETURNING
        VALUE(result) TYPE ty_t_fcat.
ENDCLASS.


CLASS z2ui5_cl_cgui_salv_table IMPLEMENTATION.

  METHOD factory.

    DATA lr_line TYPE REF TO data.

    r_salv_table = NEW #( r_container ).
    r_salv_table->mr_table = REF #( t_table ).
    CREATE DATA lr_line LIKE LINE OF t_table.
    ASSIGN lr_line->* TO FIELD-SYMBOL(<line>).
    r_salv_table->mo_columns = NEW #( <line> ).

  ENDMETHOD.

  METHOD constructor.

    super->constructor( ).
    " no part of the screen of its own - the grid of display( ) is
    add( VALUE #( kind   = z2ui5_if_cgui_gui=>cs_kind-salv
                  hidden = abap_true ) ).
    mo_container = container.
    mo_settings = NEW #( ).

  ENDMETHOD.

  METHOD display.

    DATA lt_button TYPE z2ui5_if_cgui_gui=>ty_t_button.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    IF go_report IS NOT BOUND OR mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <table>.
    IF mo_grid IS NOT BOUND.
      mo_grid = NEW #( i_parent = mo_container ).
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
    DATA(ls_layout) = VALUE ty_s_layout(
        grid_title = mo_settings->mv_title
        zebra      = mo_settings->mv_striped
        sel_mode   = SWITCH #( mo_settings->mv_selection_mode
                               WHEN z2ui5_if_cgui_salv_c=>selection_mode-none THEN ``
                               WHEN z2ui5_if_cgui_salv_c=>selection_mode-single THEN `B`
                               ELSE `A` ) ).
    DATA(lt_fcat) = fieldcat( ).
    mo_grid->set_table_for_first_display( EXPORTING  is_layout       = ls_layout
                                          CHANGING   it_outtab       = <table>
                                                     it_fieldcatalog = lt_fcat
                                          EXCEPTIONS OTHERS          = 1 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT mo_settings->mt_function INTO DATA(ls_function).
      INSERT VALUE #( fcode     = ls_function-name
                      icon      = ls_function-icon
                      text      = ls_function-text
                      quickinfo = ls_function-tooltip ) INTO TABLE lt_button.
    ENDLOOP.
    IF lt_button IS NOT INITIAL.
      go_report->grid_display( id        = mo_grid->get_id( )
                               functions = REF #( lt_button ) ).
    ENDIF.
    mo_settings->set_grid( mo_grid ).

  ENDMETHOD.

  METHOD fieldcat.

    LOOP AT mo_columns->get( ) INTO DATA(ls_ref).
      DATA(lo_column) = ls_ref-r_column.
      INSERT VALUE #( fieldname = lo_column->mv_name
                      scrtext_l = COND #( WHEN lo_column->mv_long IS NOT INITIAL THEN lo_column->mv_long
                                          WHEN lo_column->mv_medium IS NOT INITIAL THEN lo_column->mv_medium
                                          ELSE lo_column->mv_short )
                      no_out    = lo_column->mv_hidden
                      tech      = lo_column->mv_technical
                      hotspot   = lo_column->mv_hotspot
                      key       = lo_column->mv_key
                      outputlen = lo_column->mv_length ) INTO TABLE result.
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

    mr_table = REF #( t_table ).

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

    DATA(lv_function) = CONV ty_function( e_ucomm ).
    raise_event( event  = `ADDED_FUNCTION`
                 params = VALUE #( ( name = `E_SALV_FUNCTION` kind = cl_abap_objectdescr=>exporting value = REF #( lv_function ) ) ) ).

  ENDMETHOD.

  METHOD on_grid_double_click.

    DATA lv_column TYPE ty_column.
    DATA(lv_row) = e_row-index.
    lv_column = e_column-fieldname.
    raise_event( event  = `DOUBLE_CLICK`
                 params = VALUE #( ( name = `ROW`    kind = cl_abap_objectdescr=>exporting value = REF #( lv_row ) )
                                   ( name = `COLUMN` kind = cl_abap_objectdescr=>exporting value = REF #( lv_column ) ) ) ).

  ENDMETHOD.

  METHOD on_grid_hotspot.

    DATA lv_column TYPE ty_column.
    DATA(lv_row) = e_row_id-index.
    lv_column = e_column_id-fieldname.
    raise_event( event  = `LINK_CLICK`
                 params = VALUE #( ( name = `ROW`    kind = cl_abap_objectdescr=>exporting value = REF #( lv_row ) )
                                   ( name = `COLUMN` kind = cl_abap_objectdescr=>exporting value = REF #( lv_column ) ) ) ).

  ENDMETHOD.

ENDCLASS.
