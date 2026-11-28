"! The stand-in of cl_gui_alv_grid - the grid in its container, shown with
"! the ALV of the report (z2ui5_cl_cgui_alv). set_table_for_first_display( )
"! hands the report a copy of the table, the field catalog, the layout and
"! the sort; refresh_table_display( ) a copy of the table again - the grid
"! shows the table as it was then, as the frontend of SAP GUI does. The
"! events of the browser raise double_click, hotspot_click and
"! user_command; toolbar is raised before the grid shows, its buttons are
"! the functions of the grid. One grid of a report is shown at a time: the
"! first one displayed, then the one refreshed. Each grid keeps a copy of
"! what it was displayed with, the container of one not shown offers to
"! show it (show( ))
CLASS z2ui5_cl_cgui_alv_grid DEFINITION PUBLIC
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
        VALUE(e_object)      TYPE REF TO z2ui5_cl_cgui_alv_toolbar OPTIONAL
        VALUE(e_interactive) TYPE abap_bool OPTIONAL.

    METHODS constructor
      IMPORTING
        i_shellstyle    TYPE i     OPTIONAL
        i_lifetime      TYPE i     OPTIONAL
        i_parent        TYPE REF TO z2ui5_cl_cgui_container
        i_appl_events   TYPE clike OPTIONAL
        i_parentdbg     TYPE REF TO z2ui5_cl_cgui_container OPTIONAL
        i_applogparent  TYPE REF TO z2ui5_cl_cgui_container OPTIONAL
        i_graphicsparent TYPE REF TO z2ui5_cl_cgui_container OPTIONAL
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

    "! the grid shows again with the copies it keeps - the user switched to
    "! it from another grid
    METHODS show.

    "! the title of its layout and the number of rows, for the container
    "! while another grid shows
    METHODS caption
      RETURNING
        VALUE(result) TYPE string.

    METHODS dispatch REDEFINITION.

  PROTECTED SECTION.
    " copies of the table, the field catalog, the layout and the sort the
    " grid was displayed with - kept between roundtrips with the grid
    DATA mr_outtab   TYPE REF TO data.
    DATA mr_fieldcat TYPE REF TO data.
    DATA mr_layout   TYPE REF TO data.
    DATA mr_sort     TYPE REF TO data.

  PRIVATE SECTION.
    "! a copy of the data val refers to
    CLASS-METHODS copy
      IMPORTING
        val           TYPE REF TO data
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! raise toolbar and hand its buttons to the report
    METHODS toolbar_functions
      IMPORTING
        interactive TYPE abap_bool.
ENDCLASS.


CLASS z2ui5_cl_cgui_alv_grid IMPLEMENTATION.

  METHOD constructor.
    DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_control.

    super->constructor( ).

    CLEAR temp1.
    temp1-kind = z2ui5_if_cgui_gui=>cs_kind-grid.
    temp1-parent = id_of( i_parent ).
    IF add( temp1 ) = abap_false.
      RAISE error_cntl_create.
    ENDIF.

  ENDMETHOD.

  METHOD set_table_for_first_display.

    DATA lr_fieldcat TYPE REF TO data.
    DATA lr_layout   TYPE REF TO data.
    DATA lr_sort     TYPE REF TO data.
    DATA temp2 TYPE REF TO data.
    DATA temp3 TYPE REF TO data.

    IF go_report IS NOT BOUND.
      RAISE program_error.
    ENDIF.
    IF it_fieldcatalog IS SUPPLIED.
      GET REFERENCE OF it_fieldcatalog INTO lr_fieldcat.
      mr_fieldcat = copy( lr_fieldcat ).
    ENDIF.
    IF is_layout IS SUPPLIED.
      GET REFERENCE OF is_layout INTO lr_layout.
      mr_layout = copy( lr_layout ).
    ENDIF.
    IF it_sort IS SUPPLIED.
      GET REFERENCE OF it_sort INTO lr_sort.
      mr_sort = copy( lr_sort ).
    ENDIF.

    GET REFERENCE OF it_outtab INTO temp2.
mr_outtab = copy( temp2 ).

    GET REFERENCE OF it_outtab INTO temp3.
go_report->grid_display( id       = mv_id
                             tab      = temp3
                             fieldcat = lr_fieldcat
                             layout   = lr_layout
                             sort     = lr_sort
                             first    = abap_true ).
    toolbar_functions( abap_false ).

  ENDMETHOD.

  METHOD refresh_table_display.
      DATA temp4 TYPE REF TO data.
      DATA temp5 TYPE REF TO data.

    IF go_report IS BOUND AND it_outtab IS SUPPLIED.

      GET REFERENCE OF it_outtab INTO temp4.
mr_outtab = copy( temp4 ).
      IF go_report->grid_get( mv_id )-shown = abap_false.
        " it shows now, with its field catalog and layout
        show( ).
        RETURN.
      ENDIF.

      GET REFERENCE OF it_outtab INTO temp5.
go_report->grid_display( id  = mv_id
                               tab = temp5 ).
    ENDIF.

  ENDMETHOD.

  METHOD show.

    IF go_report IS NOT BOUND OR mr_outtab IS NOT BOUND.
      RETURN.
    ENDIF.
    go_report->grid_display( id       = mv_id
                             tab      = mr_outtab
                             fieldcat = mr_fieldcat
                             layout   = mr_layout
                             sort     = mr_sort ).
    toolbar_functions( abap_false ).

  ENDMETHOD.

  METHOD caption.

    FIELD-SYMBOLS <tab>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <title> TYPE any.
        DATA temp6 TYPE string.

    IF mr_outtab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_outtab->* TO <tab>.
    IF mr_layout IS BOUND.
      ASSIGN mr_layout->('GRID_TITLE') TO <title>.
      IF <title> IS ASSIGNED AND <title> IS NOT INITIAL.

        temp6 = <title>.
        result = |{ condense( temp6 ) } |.
      ENDIF.
    ENDIF.
    result = |{ result }({ lines( <tab> ) })|.

  ENDMETHOD.

  METHOD copy.

    FIELD-SYMBOLS <from> TYPE any.
    FIELD-SYMBOLS <to>   TYPE any.

    ASSIGN val->* TO <from>.
    CREATE DATA result LIKE <from>.
    ASSIGN result->* TO <to>.
    <to> = <from>.

  ENDMETHOD.

  METHOD set_frontend_fieldcatalog.

    DATA temp7 TYPE REF TO data.
      DATA temp8 TYPE REF TO data.
    GET REFERENCE OF it_fieldcatalog INTO temp7.
mr_fieldcat = copy( temp7 ).
    IF go_report IS BOUND.

      GET REFERENCE OF it_fieldcatalog INTO temp8.
go_report->grid_display( id       = mv_id
                               fieldcat = temp8 ).
    ENDIF.

  ENDMETHOD.

  METHOD get_frontend_fieldcatalog.

    FIELD-SYMBOLS <fieldcat> TYPE STANDARD TABLE.
    DATA ls_grid TYPE z2ui5_if_cgui_gui=>ty_s_grid.

    CLEAR et_fieldcatalog.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.

    ls_grid = go_report->grid_get( mv_id ).
    IF ls_grid-fieldcat IS BOUND.
      ASSIGN ls_grid-fieldcat->* TO <fieldcat>.
      et_fieldcatalog = <fieldcat>.
    ENDIF.

  ENDMETHOD.

  METHOD set_frontend_layout.

    DATA temp9 TYPE REF TO data.
      DATA temp10 TYPE REF TO data.
GET REFERENCE OF is_layout INTO temp9.
mr_layout = copy( temp9 ).
    IF go_report IS BOUND.

GET REFERENCE OF is_layout INTO temp10.
go_report->grid_display( id     = mv_id
                               layout = temp10 ).
    ENDIF.

  ENDMETHOD.

  METHOD get_frontend_layout.

    FIELD-SYMBOLS <layout> TYPE any.
    DATA ls_grid TYPE z2ui5_if_cgui_gui=>ty_s_grid.

    CLEAR es_layout.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.

    ls_grid = go_report->grid_get( mv_id ).
    IF ls_grid-layout IS BOUND.
      ASSIGN ls_grid-layout->* TO <layout>.
      MOVE-CORRESPONDING <layout> TO es_layout.
    ENDIF.

  ENDMETHOD.

  METHOD set_sort_criteria.

    DATA temp11 TYPE REF TO data.
      DATA temp12 TYPE REF TO data.
    GET REFERENCE OF it_sort INTO temp11.
mr_sort = copy( temp11 ).
    IF go_report IS BOUND.

      GET REFERENCE OF it_sort INTO temp12.
go_report->grid_display( id   = mv_id
                               sort = temp12 ).
    ENDIF.

  ENDMETHOD.

  METHOD get_selected_rows.

    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    DATA temp13 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA lv_row LIKE LINE OF temp13.

    CLEAR: et_index_rows, et_row_no.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.

    temp13 = go_report->grid_selected( ).

    LOOP AT temp13 INTO lv_row.
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

    DATA lo_toolbar TYPE REF TO z2ui5_cl_cgui_alv_toolbar.
    DATA lv_interactive LIKE interactive.
    DATA temp14 LIKE REF TO lv_interactive.
DATA temp1 LIKE REF TO lo_toolbar.
DATA temp2 TYPE abap_parmbind_tab.
DATA temp3 LIKE LINE OF temp2.
    DATA ls_button LIKE LINE OF lo_toolbar->mt_toolbar.
      DATA temp15 TYPE z2ui5_if_cgui_gui=>ty_s_button.
      DATA temp16 LIKE REF TO lt_function.
    CREATE OBJECT lo_toolbar TYPE z2ui5_cl_cgui_alv_toolbar.

    lv_interactive = interactive.

    GET REFERENCE OF lv_interactive INTO temp14.

GET REFERENCE OF lo_toolbar INTO temp1.

CLEAR temp2.

temp3-name = `E_OBJECT`.
temp3-kind = cl_abap_objectdescr=>exporting.
temp3-value = temp1.
INSERT temp3 INTO TABLE temp2.
temp3-name = `E_INTERACTIVE`.
temp3-kind = cl_abap_objectdescr=>exporting.
temp3-value = temp14.
INSERT temp3 INTO TABLE temp2.
raise_event( event  = `TOOLBAR`
                 params = temp2 ).
    " a separator (butn_type 3) is no function

    LOOP AT lo_toolbar->mt_toolbar INTO ls_button WHERE function IS NOT INITIAL AND butn_type <> 3.

      CLEAR temp15.
      temp15-fcode = to_upper( condense( ls_button-function ) ).
      temp15-icon = condense( ls_button-icon ).
      temp15-text = condense( ls_button-text ).
      temp15-quickinfo = condense( ls_button-quickinfo ).
      temp15-type = ls_button-butn_type.
      temp15-disabled = ls_button-disabled.
      temp15-checked = ls_button-checked.
      INSERT temp15 INTO TABLE lt_function.
    ENDLOOP.
    IF lt_function IS NOT INITIAL AND go_report IS BOUND.

      GET REFERENCE OF lt_function INTO temp16.
go_report->grid_display( id        = mv_id
                               functions = temp16 ).
    ENDIF.

  ENDMETHOD.

  METHOD dispatch.

    DATA lv_ucomm TYPE c LENGTH 70.

    DATA lv_event TYPE string.
        DATA lv_row TYPE string.
        DATA lv_column TYPE string.
        DATA temp17 TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_row.
        DATA temp2 TYPE i.
        DATA ls_row LIKE temp17.
        DATA temp18 TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_col.
        DATA ls_col LIKE temp18.
        DATA temp19 TYPE z2ui5_cl_cgui_alv=>ty_s_lvc_roid.
        DATA ls_roid LIKE temp19.
          DATA temp20 LIKE REF TO ls_roid.
DATA temp3 LIKE REF TO ls_col.
DATA temp7 LIKE REF TO ls_row.
DATA temp1 TYPE abap_parmbind_tab.
DATA temp9 LIKE LINE OF temp1.
          DATA temp21 LIKE REF TO ls_roid.
DATA temp4 LIKE REF TO ls_col.
DATA temp8 LIKE REF TO ls_row.
DATA temp10 TYPE abap_parmbind_tab.
DATA temp11 LIKE LINE OF temp10.
        DATA temp22 LIKE REF TO lv_ucomm.
DATA temp5 TYPE abap_parmbind_tab.
DATA temp6 LIKE LINE OF temp5.
    lv_event = to_upper( event ).
    CASE lv_event.
      WHEN `DOUBLE_CLICK` OR `HOTSPOT_CLICK`.
        " row, or row and column apart by a tab


        SPLIT value AT cl_abap_char_utilities=>horizontal_tab INTO lv_row lv_column.

        CLEAR temp17.

        temp2 = lv_row.
        temp17-index = temp2.

        ls_row = temp17.

        CLEAR temp18.
        temp18-fieldname = to_upper( lv_column ).

        ls_col = temp18.

        CLEAR temp19.
        temp19-row_id = ls_row-index.

        ls_roid = temp19.
        IF lv_event = `DOUBLE_CLICK`.

          GET REFERENCE OF ls_roid INTO temp20.

GET REFERENCE OF ls_col INTO temp3.

GET REFERENCE OF ls_row INTO temp7.

CLEAR temp1.

temp9-name = `E_ROW`.
temp9-kind = cl_abap_objectdescr=>exporting.
temp9-value = temp7.
INSERT temp9 INTO TABLE temp1.
temp9-name = `E_COLUMN`.
temp9-kind = cl_abap_objectdescr=>exporting.
temp9-value = temp3.
INSERT temp9 INTO TABLE temp1.
temp9-name = `ES_ROW_NO`.
temp9-kind = cl_abap_objectdescr=>exporting.
temp9-value = temp20.
INSERT temp9 INTO TABLE temp1.
raise_event( event  = lv_event
                       params = temp1 ).
        ELSE.

          GET REFERENCE OF ls_roid INTO temp21.

GET REFERENCE OF ls_col INTO temp4.

GET REFERENCE OF ls_row INTO temp8.

CLEAR temp10.

temp11-name = `E_ROW_ID`.
temp11-kind = cl_abap_objectdescr=>exporting.
temp11-value = temp8.
INSERT temp11 INTO TABLE temp10.
temp11-name = `E_COLUMN_ID`.
temp11-kind = cl_abap_objectdescr=>exporting.
temp11-value = temp4.
INSERT temp11 INTO TABLE temp10.
temp11-name = `ES_ROW_NO`.
temp11-kind = cl_abap_objectdescr=>exporting.
temp11-value = temp21.
INSERT temp11 INTO TABLE temp10.
raise_event( event  = lv_event
                       params = temp10 ).
        ENDIF.
      WHEN `USER_COMMAND`.
        lv_ucomm = value.

        GET REFERENCE OF lv_ucomm INTO temp22.

CLEAR temp5.

temp6-name = `E_UCOMM`.
temp6-kind = cl_abap_objectdescr=>exporting.
temp6-value = temp22.
INSERT temp6 INTO TABLE temp5.
raise_event( event  = lv_event
                     params = temp5 ).
      WHEN OTHERS.
        super->dispatch( event = event
                         value = value ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
