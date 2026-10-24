"! The stand-in of cl_gui_alv_grid - the grid in its container, shown with
"! the ALV of the report (z2ui5_cl_cgui_alv). set_table_for_first_display( )
"! hands the report a copy of the table, the field catalog, the layout and
"! the sort; refresh_table_display( ) a copy of the table again - the grid
"! shows the table as it was then, as the frontend of SAP GUI does. The
"! events of the browser raise double_click, hotspot_click and
"! user_command; toolbar is raised before the grid shows, its buttons are
"! the functions of the grid. One grid of a report is shown at a time
CLASS z2ui5_cl_cgui_gui_alv_grid DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    " the functions of the standard toolbar - for it_toolbar_excluding;
    " the toolbar of the ALV has its own functions
    CONSTANTS mc_fc_excl_all     TYPE c LENGTH 70 VALUE '&EXCLALLFC'.
    CONSTANTS mc_fc_detail       TYPE c LENGTH 70 VALUE '&DETAIL'.
    CONSTANTS mc_fc_print        TYPE c LENGTH 70 VALUE '&PRINT_BACK'.
    CONSTANTS mc_fc_refresh      TYPE c LENGTH 70 VALUE '&REFRESH'.
    CONSTANTS mc_fc_loc_cut      TYPE c LENGTH 70 VALUE '&LOCAL&CUT'.
    CONSTANTS mc_fc_loc_copy     TYPE c LENGTH 70 VALUE '&LOCAL&COPY'.
    CONSTANTS mc_fc_loc_paste    TYPE c LENGTH 70 VALUE '&LOCAL&PASTE'.
    CONSTANTS mc_fc_loc_undo     TYPE c LENGTH 70 VALUE '&LOCAL&UNDO'.
    CONSTANTS mc_fc_loc_append_row TYPE c LENGTH 70 VALUE '&LOCAL&APPEND'.
    CONSTANTS mc_fc_loc_insert_row TYPE c LENGTH 70 VALUE '&LOCAL&INSERT_ROW'.
    CONSTANTS mc_fc_loc_delete_row TYPE c LENGTH 70 VALUE '&LOCAL&DELETE_ROW'.
    CONSTANTS mc_fc_loc_copy_row TYPE c LENGTH 70 VALUE '&LOCAL&COPY_ROW'.
    CONSTANTS mc_fc_sort_asc     TYPE c LENGTH 70 VALUE '&SORT_ASC'.
    CONSTANTS mc_fc_sort_dsc     TYPE c LENGTH 70 VALUE '&SORT_DSC'.
    CONSTANTS mc_fc_find         TYPE c LENGTH 70 VALUE '&FIND'.
    CONSTANTS mc_fc_filter       TYPE c LENGTH 70 VALUE '&MB_FILTER'.
    CONSTANTS mc_fc_sum          TYPE c LENGTH 70 VALUE '&MB_SUM'.
    CONSTANTS mc_fc_views        TYPE c LENGTH 70 VALUE '&VIEW'.
    CONSTANTS mc_fc_info         TYPE c LENGTH 70 VALUE '&INFO'.
    CONSTANTS mc_fc_graph        TYPE c LENGTH 70 VALUE '&GRAPH'.
    CONSTANTS mc_mb_export       TYPE c LENGTH 70 VALUE '&MB_EXPORT'.
    CONSTANTS mc_mb_variant      TYPE c LENGTH 70 VALUE '&MB_VARIANT'.
    CONSTANTS mc_evt_enter       TYPE i VALUE 19.
    CONSTANTS mc_evt_modified    TYPE i VALUE 18.
    CONSTANTS mc_style_enabled   TYPE i VALUE 0.
    CONSTANTS mc_style_disabled  TYPE i VALUE 1048576.
    CONSTANTS mc_style_hotspot   TYPE i VALUE 2097152.

    " the rows and columns of the events - the LVC types of the ALV
    EVENTS double_click
      EXPORTING
        VALUE(e_row)    TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_row OPTIONAL
        VALUE(e_column) TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_col OPTIONAL
        VALUE(es_row_no) TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_roid OPTIONAL.

    EVENTS hotspot_click
      EXPORTING
        VALUE(e_row_id)    TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_row OPTIONAL
        VALUE(e_column_id) TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_col OPTIONAL
        VALUE(es_row_no)   TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_roid OPTIONAL.

    EVENTS user_command
      EXPORTING
        VALUE(e_ucomm) TYPE c OPTIONAL.

    EVENTS toolbar
      EXPORTING
        VALUE(e_object)      TYPE REF TO z2ui5_cl_cgui_gui_alv_toolbar OPTIONAL
        VALUE(e_interactive) TYPE abap_bool OPTIONAL.

    METHODS constructor
      IMPORTING
        i_shellstyle    TYPE i     OPTIONAL
        i_lifetime      TYPE i     OPTIONAL
        i_parent        TYPE REF TO z2ui5_cl_cgui_gui_container
        i_appl_events   TYPE clike OPTIONAL
        i_parentdbg     TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        i_applogparent  TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        i_graphicsparent TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        i_name          TYPE clike OPTIONAL
        i_fcat_complete TYPE clike OPTIONAL
      EXCEPTIONS
        error_cntl_create
        error_cntl_init
        error_cntl_link
        error_dp_create.

    METHODS set_table_for_first_display
      IMPORTING
        i_buffer_active      TYPE any OPTIONAL
        i_bypassing_buffer   TYPE clike OPTIONAL
        i_consistency_check  TYPE clike OPTIONAL
        i_structure_name     TYPE clike OPTIONAL
        is_variant           TYPE any OPTIONAL
        i_save               TYPE clike OPTIONAL
        i_default            TYPE clike DEFAULT abap_true
        is_layout            TYPE any OPTIONAL
        is_print             TYPE any OPTIONAL
        it_special_groups    TYPE STANDARD TABLE OPTIONAL
        it_toolbar_excluding TYPE STANDARD TABLE OPTIONAL
        it_hyperlink         TYPE STANDARD TABLE OPTIONAL
        it_alv_graphics      TYPE STANDARD TABLE OPTIONAL
        it_except_qinfo      TYPE STANDARD TABLE OPTIONAL
      CHANGING
        it_outtab            TYPE STANDARD TABLE
        it_fieldcatalog      TYPE STANDARD TABLE OPTIONAL
        it_sort              TYPE STANDARD TABLE OPTIONAL
        it_filter            TYPE STANDARD TABLE OPTIONAL
      EXCEPTIONS
        invalid_parameter_combination
        program_error
        too_many_lines.

    "! it_outtab is the table to show again - the classic grid reads the
    "! table it was given by reference; the conversion passes it here
    METHODS refresh_table_display
      IMPORTING
        is_stable      TYPE any OPTIONAL
        i_soft_refresh TYPE clike OPTIONAL
      CHANGING
        it_outtab      TYPE STANDARD TABLE OPTIONAL
      EXCEPTIONS
        finished.

    METHODS set_frontend_fieldcatalog
      IMPORTING
        it_fieldcatalog TYPE STANDARD TABLE.

    METHODS get_frontend_fieldcatalog
      EXPORTING
        et_fieldcatalog TYPE STANDARD TABLE.

    METHODS set_frontend_layout
      IMPORTING
        is_layout TYPE any.

    METHODS get_frontend_layout
      EXPORTING
        es_layout TYPE any.

    METHODS set_sort_criteria
      IMPORTING
        it_sort TYPE STANDARD TABLE
      EXCEPTIONS
        no_fieldcatalog_available.

    "! the rows the user selected - lvc_t_row (INDEX) and lvc_t_roid (ROW_ID)
    METHODS get_selected_rows
      EXPORTING
        et_index_rows TYPE STANDARD TABLE
        et_row_no     TYPE STANDARD TABLE.

    "! the toolbar again: raises toolbar, its buttons are the functions
    METHODS set_toolbar_interactive.

    "! the grid takes what the user types with the next roundtrip - valid
    METHODS check_changed_data
      EXPORTING
        e_valid   TYPE c
      CHANGING
        c_refresh TYPE c OPTIONAL.

    METHODS register_edit_event
      IMPORTING
        i_event_id TYPE i
      EXCEPTIONS
        error.

    METHODS set_ready_for_input
      IMPORTING
        i_ready_for_input TYPE i DEFAULT 1.

    METHODS dispatch REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! raise toolbar and hand its buttons to the report
    METHODS toolbar_functions
      IMPORTING
        interactive TYPE abap_bool.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_alv_grid IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).
    IF add( VALUE #( kind   = z2ui5_if_cgui_gui=>cs_kind-grid
                     parent = id_of( i_parent ) ) ) = abap_false.
      RAISE error_cntl_create.
    ENDIF.

  ENDMETHOD.

  METHOD set_table_for_first_display.

    DATA lr_fieldcat TYPE REF TO data.
    DATA lr_layout   TYPE REF TO data.
    DATA lr_sort     TYPE REF TO data.

    IF go_report IS NOT BOUND.
      RAISE program_error.
    ENDIF.
    IF it_fieldcatalog IS SUPPLIED.
      lr_fieldcat = REF #( it_fieldcatalog ).
    ENDIF.
    IF is_layout IS SUPPLIED.
      lr_layout = REF #( is_layout ).
    ENDIF.
    IF it_sort IS SUPPLIED.
      lr_sort = REF #( it_sort ).
    ENDIF.
    go_report->grid_display( id       = mv_id
                             tab      = REF #( it_outtab )
                             fieldcat = lr_fieldcat
                             layout   = lr_layout
                             sort     = lr_sort ).
    toolbar_functions( abap_false ).

  ENDMETHOD.

  METHOD refresh_table_display.

    IF go_report IS BOUND AND it_outtab IS SUPPLIED.
      go_report->grid_display( id  = mv_id
                               tab = REF #( it_outtab ) ).
    ENDIF.

  ENDMETHOD.

  METHOD set_frontend_fieldcatalog.

    IF go_report IS BOUND.
      go_report->grid_display( id       = mv_id
                               fieldcat = REF #( it_fieldcatalog ) ).
    ENDIF.

  ENDMETHOD.

  METHOD get_frontend_fieldcatalog.

    FIELD-SYMBOLS <fieldcat> TYPE STANDARD TABLE.

    CLEAR et_fieldcatalog.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(ls_grid) = go_report->grid_get( mv_id ).
    IF ls_grid-fieldcat IS BOUND.
      ASSIGN ls_grid-fieldcat->* TO <fieldcat>.
      et_fieldcatalog = <fieldcat>.
    ENDIF.

  ENDMETHOD.

  METHOD set_frontend_layout.

    IF go_report IS BOUND.
      go_report->grid_display( id     = mv_id
                               layout = REF #( is_layout ) ).
    ENDIF.

  ENDMETHOD.

  METHOD get_frontend_layout.

    FIELD-SYMBOLS <layout> TYPE any.

    CLEAR es_layout.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(ls_grid) = go_report->grid_get( mv_id ).
    IF ls_grid-layout IS BOUND.
      ASSIGN ls_grid-layout->* TO <layout>.
      MOVE-CORRESPONDING <layout> TO es_layout.
    ENDIF.

  ENDMETHOD.

  METHOD set_sort_criteria.

    IF go_report IS BOUND.
      go_report->grid_display( id   = mv_id
                               sort = REF #( it_sort ) ).
    ENDIF.

  ENDMETHOD.

  METHOD get_selected_rows.

    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <value> TYPE any.

    CLEAR: et_index_rows, et_row_no.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT go_report->grid_selected( ) INTO DATA(lv_row).
      APPEND INITIAL LINE TO et_index_rows ASSIGNING <line>.
      ASSIGN COMPONENT `INDEX` OF STRUCTURE <line> TO <value>.
      IF sy-subrc = 0.
        <value> = lv_row.
      ENDIF.
      APPEND INITIAL LINE TO et_row_no ASSIGNING <line>.
      ASSIGN COMPONENT `ROW_ID` OF STRUCTURE <line> TO <value>.
      IF sy-subrc = 0.
        <value> = lv_row.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_toolbar_interactive.

    toolbar_functions( abap_true ).

  ENDMETHOD.

  METHOD check_changed_data.

    e_valid = abap_true.

  ENDMETHOD.

  METHOD register_edit_event ##NEEDED.
  ENDMETHOD.

  METHOD set_ready_for_input ##NEEDED.
  ENDMETHOD.

  METHOD toolbar_functions.

    DATA lt_function TYPE z2ui5_if_cgui_gui=>ty_t_button.

    DATA(lo_toolbar) = NEW z2ui5_cl_cgui_gui_alv_toolbar( ).
    DATA(lv_interactive) = interactive.
    raise_event( event  = `TOOLBAR`
                 params = VALUE #( ( name = `E_OBJECT`      kind = cl_abap_objectdescr=>exporting value = REF #( lo_toolbar ) )
                                   ( name = `E_INTERACTIVE` kind = cl_abap_objectdescr=>exporting value = REF #( lv_interactive ) ) ) ).
    " a separator (butn_type 3) is no function
    LOOP AT lo_toolbar->mt_toolbar INTO DATA(ls_button) WHERE function IS NOT INITIAL AND butn_type <> 3.
      INSERT VALUE #( fcode     = to_upper( condense( ls_button-function ) )
                      icon      = condense( ls_button-icon )
                      text      = condense( ls_button-text )
                      quickinfo = condense( ls_button-quickinfo )
                      type      = ls_button-butn_type
                      disabled  = ls_button-disabled
                      checked   = ls_button-checked ) INTO TABLE lt_function.
    ENDLOOP.
    IF lt_function IS NOT INITIAL AND go_report IS BOUND.
      go_report->grid_display( id        = mv_id
                               functions = REF #( lt_function ) ).
    ENDIF.

  ENDMETHOD.

  METHOD dispatch.

    DATA lv_ucomm TYPE c LENGTH 70.

    DATA(lv_event) = to_upper( event ).
    CASE lv_event.
      WHEN `DOUBLE_CLICK` OR `HOTSPOT_CLICK`.
        " row, or row and column apart by a tab
        SPLIT value AT cl_abap_char_utilities=>horizontal_tab INTO DATA(lv_row) DATA(lv_column).
        DATA(ls_row) = VALUE z2ui5_cl_cgui_alv=>ty_s_lvc_row( index = CONV i( lv_row ) ).
        DATA(ls_col) = VALUE z2ui5_cl_cgui_alv=>ty_s_lvc_col( fieldname = to_upper( lv_column ) ).
        DATA(ls_roid) = VALUE z2ui5_cl_cgui_alv=>ty_s_lvc_roid( row_id = ls_row-index ).
        IF lv_event = `DOUBLE_CLICK`.
          raise_event( event  = lv_event
                       params = VALUE #( ( name = `E_ROW`    kind = cl_abap_objectdescr=>exporting value = REF #( ls_row ) )
                                         ( name = `E_COLUMN` kind = cl_abap_objectdescr=>exporting value = REF #( ls_col ) )
                                         ( name = `ES_ROW_NO` kind = cl_abap_objectdescr=>exporting value = REF #( ls_roid ) ) ) ).
        ELSE.
          raise_event( event  = lv_event
                       params = VALUE #( ( name = `E_ROW_ID`    kind = cl_abap_objectdescr=>exporting value = REF #( ls_row ) )
                                         ( name = `E_COLUMN_ID` kind = cl_abap_objectdescr=>exporting value = REF #( ls_col ) )
                                         ( name = `ES_ROW_NO`   kind = cl_abap_objectdescr=>exporting value = REF #( ls_roid ) ) ) ).
        ENDIF.
      WHEN `USER_COMMAND`.
        lv_ucomm = value.
        raise_event( event  = lv_event
                     params = VALUE #( ( name = `E_UCOMM` kind = cl_abap_objectdescr=>exporting value = REF #( lv_ucomm ) ) ) ).
      WHEN OTHERS.
        super->dispatch( event = event
                         value = value ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
