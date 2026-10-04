"! Report runtime - write an abap2UI5 app the way a classic ABAP report is
"! written. Inherit from this class, declare the fields of the selection
"! screen as PUBLIC attributes and redefine the event blocks you need:
"!   initialization        once, before the selection screen is shown
"!   selection_screen      the layout: parameter( ), select_option( ), ...
"!   at_selection_screen_output
"!                         before the selection screen is shown - change
"!                         it with loop_at_screen( ) / modify_screen( )
"!   at_selection_screen_on
"!                         after F8, once per field - a message( ) of type E
"!                         marks the field and keeps the user on the screen
"!   at_selection_screen   after F8, before the run - message( type = `E` )
"!                         keeps the user on the selection screen
"!   start_of_selection    read the data, output it with write( ) or alv( )
"!   end_of_selection      after start_of_selection
"!   top_of_page           the page header of the list, written first and
"!                         repeated after every new_page( ); in a secondary
"!                         list top_of_page_line_selection
"!   at_line_selection     a hotspot of the list or a row of the ALV clicked;
"!                         what it writes is a secondary list (lsind( ))
"!   at_link_click         a hotspot column of the ALV clicked
"!   at_user_command       a button of the selection screen or the ALV, a
"!                         checkbox or radio button with user_command, or a
"!                         confirmed popup
"!   at_value_request      F4 on a field - the default shows the standard F4
"!                         of its DDIC type: domain fixed values, search help
"!                         or value table with its texts
"!   authority_check       before anything else and before every run - no
"!                         authorization, no report
"! The runtime shows the selection screen, runs the blocks on Execute (F8),
"! shows the output and goes back on Back (F3). The values of the selection
"! screen can be saved as variants, kept in table Z2UI5_CGUI_VAR per report,
"! in a store of your own or in the browser's local storage
"! (set_variant_store( )) - start with one by
"! set_variant( ) in initialization( ) or with the URL parameter
"! variant=NAME. The fields can be filled from the URL as well
"! (&P_CARRID=LH&S_DATE=20260101..20260331&skip_screen=X), and submit( )
"! starts another report with values. Messages follow the classic
"! semantics - S as a toast, I as a box, E stops the run - and are collected
"! in the message popover of the run: a button in the footer counts them,
"! W and E open it, and a message of a field leads to the field.
CLASS z2ui5_cl_cgui_report DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS:
      BEGIN OF cs_ucomm,
        execute           TYPE string VALUE `CGUI_EXECUTE`,
        back              TYPE string VALUE `CGUI_BACK`,
        cancel            TYPE string VALUE `CGUI_CANCEL`,
        variant_get       TYPE string VALUE `CGUI_VARIANT_GET`,
        variant_save      TYPE string VALUE `CGUI_VARIANT_SAVE`,
        variant_delete    TYPE string VALUE `CGUI_VARIANT_DELETE`,
        variant_delete_ok TYPE string VALUE `CGUI_VARIANT_DELETE_OK`,
        variants_loaded   TYPE string VALUE `CGUI_VARIANTS_LOADED`,
        message_focus     TYPE string VALUE `CGUI_MESSAGE_FOCUS`,
        messages_open     TYPE string VALUE `CGUI_MESSAGES_OPEN`,
        link_copy         TYPE string VALUE `CGUI_LINK_COPY`,
        auto_execute      TYPE string VALUE `CGUI_AUTO_EXECUTE`,
        screen_ok         TYPE string VALUE `CGUI_SCREEN_OK`,
        screen_cancel     TYPE string VALUE `CGUI_SCREEN_CANCEL`,
        popup_answer      TYPE string VALUE `CGUI_POPUP_ANSWER`,
        variant_saved     TYPE string VALUE `CGUI_VARIANT_SAVED`,
        print             TYPE string VALUE `CGUI_PRINT`,
      END OF cs_ucomm.

    "! the prefix of the browser's local storage the variants are kept
    "! under, the key is the name of the report class
    CONSTANTS cv_cgui_variant_prefix TYPE string VALUE `z2ui5_cgui_variants`.

    "! the browser's local storage of SET / GET PARAMETER ID - one entry for
    "! every report of the browser, the SAP memory of this addon
    CONSTANTS cv_cgui_spa_prefix TYPE string VALUE `z2ui5_cgui_spa`.
    CONSTANTS cv_cgui_spa_key    TYPE string VALUE `PARAMETERS`.

    "! the id of the footer button the message popover opens on, and of the
    "! popover itself
    CONSTANTS cv_cgui_messages_id TYPE string VALUE `cgui_messages`.
    CONSTANTS cv_cgui_popover_id  TYPE string VALUE `cgui_message_popover`.

    "! the URL parameter that runs the report without its selection screen
    CONSTANTS cv_cgui_url_skip TYPE string VALUE `SKIP_SCREEN`.

    TYPES:
      "! the inputs from and to of the select-options - the buffer the screen
      "! binds to, turned into the ranges on every roundtrip
      BEGIN OF ty_s_cgui_so,
        name TYPE string,
        low  TYPE string,
        high TYPE string,
      END OF ty_s_cgui_so.
    TYPES ty_t_cgui_so TYPE STANDARD TABLE OF ty_s_cgui_so WITH EMPTY KEY.

    TYPES:
      "! the selected tab of each tabbed block
      BEGIN OF ty_s_cgui_tab,
        key TYPE string,
      END OF ty_s_cgui_tab.
    TYPES ty_t_cgui_tab TYPE STANDARD TABLE OF ty_s_cgui_tab WITH EMPTY KEY.

    TYPES:
      "! a message of a run - the result of cgui_run_in_background( )
      BEGIN OF ty_s_cgui_message,
        type TYPE string,
        text TYPE string,
      END OF ty_s_cgui_message.
    TYPES ty_t_cgui_message TYPE STANDARD TABLE OF ty_s_cgui_message WITH EMPTY KEY.

    "! the output of alv( ) when the table passed is no attribute of the
    "! report - a copy, bound to the grid
    DATA mr_cgui_alv TYPE REF TO data.

    "! the table the grid shows when it has a selection column and the table
    "! of the report no box field: a copy with the field ZZSELKZ
    DATA mr_cgui_alv_box TYPE REF TO data.
    " the rows the grid shows when it is filtered or paged - a copy; per row
    " the row of the table it comes from is mt_cgui_alv_index
    DATA mr_cgui_alv_page TYPE REF TO data.

    "! the variants of the report as the browser's local storage holds them
    "! (z2ui5_cl_cgui_variant=>catalog_to_string( )) - bound to the storage
    "! control that reads them, hence PUBLIC
    DATA mv_cgui_variants TYPE string.

    "! the parameter IDs of the browser - ID=value lines, bound to the
    "! storage control that reads them
    DATA mv_cgui_spa TYPE string.

    DATA mt_cgui_so  TYPE ty_t_cgui_so.
    DATA mt_cgui_tab TYPE ty_t_cgui_tab.

    "! the input fields of the list (WRITE ... INPUT) - every field is bound
    "! to its line
    DATA mt_cgui_list_input TYPE z2ui5_cl_cgui_list=>ty_t_input.
    "! the rows of the ALV tree the browser shows - bound to the tree table
    DATA mt_cgui_tree_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.


    "! the report without a browser - e.g. in an application job of your
    "! own: the values are set, the events of the selection screen,
    "! START-OF-SELECTION and END-OF-SELECTION run; list and alv return the
    "! output, messages what the run reported. A run stopped by an error
    "! returns no output
    METHODS cgui_run_in_background
      IMPORTING
        values   TYPE z2ui5_cl_cgui_variant=>ty_t_value
      EXPORTING
        list     TYPE REF TO z2ui5_cl_cgui_list
        alv      TYPE REF TO z2ui5_cl_cgui_alv
        alv_data TYPE REF TO data
        messages TYPE ty_t_cgui_message.

  PROTECTED SECTION.

    TYPES:
      BEGIN OF ty_s_cgui_msg,
        type  TYPE string,
        text  TYPE string,
        field TYPE string,
      END OF ty_s_cgui_msg.
    TYPES ty_t_cgui_msg TYPE STANDARD TABLE OF ty_s_cgui_msg WITH EMPTY KEY.

    TYPES:
      " character types: the popup heads a column with the DDIC label of its
      " type, the component name when it has none - and STRING for a string
      BEGIN OF ty_s_cgui_value,
        value TYPE c LENGTH 10,
        text  TYPE c LENGTH 60,
      END OF ty_s_cgui_value.
    TYPES ty_t_cgui_value TYPE STANDARD TABLE OF ty_s_cgui_value WITH EMPTY KEY.

    TYPES:
      "! a level of the output - the basic list and every secondary list
      BEGIN OF ty_s_cgui_level,
        list     TYPE REF TO z2ui5_cl_cgui_list,
        alv      TYPE REF TO z2ui5_cl_cgui_alv,
        tree     TYPE REF TO z2ui5_cl_cgui_tree,
        alv_name TYPE string,
        alv_data TYPE REF TO data,
        window   TYPE abap_bool,
        w_title  TYPE string,
        w_cols   TYPE i,
        w_lines  TYPE i,
      END OF ty_s_cgui_level.
    TYPES ty_t_cgui_level TYPE STANDARD TABLE OF ty_s_cgui_level WITH EMPTY KEY.

    " GET CURSOR FIELD f VALUE v LINE l OFFSET o - what was clicked
    TYPES:
      BEGIN OF ty_s_cgui_cursor,
        field  TYPE string,
        value  TYPE string,
        line   TYPE i,
        offset TYPE i,
      END OF ty_s_cgui_cursor.

    TYPES:
      BEGIN OF ty_s_cgui_vrm,
        name   TYPE string,
        values TYPE z2ui5_cl_cgui_selscreen=>ty_t_value,
      END OF ty_s_cgui_vrm.
    TYPES ty_t_cgui_vrm TYPE STANDARD TABLE OF ty_s_cgui_vrm WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS initialization.

    METHODS selection_screen
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! AT SELECTION-SCREEN OUTPUT - runs every time the selection screen is
    "! shown, after selection_screen( ): change it with
    "! screen->loop_at_screen( ) and screen->modify_screen( )
    METHODS at_selection_screen_output
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! AT SELECTION-SCREEN ON field - runs after Execute once for every field
    "! shown on the screen, field is its attribute name. A message( ) of
    "! type E belongs to the field: it is marked and the run stops
    METHODS at_selection_screen_on
      IMPORTING
        field TYPE string.

    METHODS at_selection_screen.

    METHODS start_of_selection.

    "! END-OF-SELECTION - after start_of_selection( ), unless it stopped
    METHODS end_of_selection.

    "! END-OF-PAGE - the page footer of the list: what is written here ends
    "! every page, &PAGE& in it is the page number. With set_line_count( )
    "! the pages break after so many lines
    METHODS end_of_page.

    "! AT SELECTION-SCREEN ON BLOCK - after Execute, once for every block
    "! named in block_begin( ); a message( ) of type E stops the run
    METHODS at_selection_screen_on_block
      IMPORTING
        block TYPE string.

    "! AT SELECTION-SCREEN ON RADIOBUTTON GROUP - after Execute, once for
    "! every group; a message( ) of type E stops at its first button
    METHODS at_selection_screen_on_radio
      IMPORTING
        group TYPE string.

    "! AT SELECTION-SCREEN ON END OF - the multiple selection of a
    "! select-option was left with OK; a message( ) of type E opens it again
    METHODS at_selection_screen_on_end_of
      IMPORTING
        field TYPE string.

    "! AT SELECTION-SCREEN ON HELP-REQUEST - F1 on a field. The default
    "! shows the documentation of its data element
    METHODS at_selection_screen_on_help
      IMPORTING
        field TYPE string.

    "! AT SELECTION-SCREEN ON EXIT-COMMAND - Back on the selection screen or
    "! Cancel on a popup screen, before it is left. Nothing is checked; an
    "! error message keeps the screen
    METHODS at_selection_screen_on_exit
      IMPORTING
        ucomm TYPE string.

    "! TOP-OF-PAGE - the page header of the basic list: what is written here
    "! stands above the list and again after every new_page( )
    METHODS top_of_page.

    "! TOP-OF-PAGE DURING LINE-SELECTION - the header of a secondary list
    METHODS top_of_page_line_selection.

    "! row is the line number of the list or the row index of the ALV table,
    "! hide the value the list hotspot was written with. What is written or
    "! shown with alv( ) here is a secondary list - Back returns to the list
    "! it was called from
    METHODS at_line_selection
      IMPORTING
        row  TYPE i
        hide TYPE string.

    "! a hotspot column of the ALV - row index and column name. The default
    "! runs at_line_selection( ) with the column as hide
    METHODS at_link_click
      IMPORTING
        row    TYPE i
        column TYPE string.

    "! the text of a node of the ALV tree was clicked - its key and the value
    "! passed to add_node( ). The classic DOUBLE_CLICK / NODE_DOUBLE_CLICK;
    "! what is written or shown here is a secondary list
    METHODS at_tree_node
      IMPORTING
        key   TYPE i
        value TYPE string.

    "! a checkbox of the tree was ticked or cleared - CHECKBOX_CHANGE. Only
    "! with tree( )->set_checkboxes( event = abap_true ); the tick is in the
    "! node already
    METHODS at_tree_checkbox
      IMPORTING
        key     TYPE i
        checked TYPE abap_bool.

    "! a node added with lazy = abap_true was opened the first time - add
    "! its children here (EXPAND_NO_CHILDREN)
    METHODS at_tree_expand_no_children
      IMPORTING
        key TYPE i.

    "! a cell of an editable ALV changed - row index and column name, the
    "! table already holds the new value. The classic DATA_CHANGED; a
    "! message( ) of type E reports a wrong value
    METHODS at_data_changed
      IMPORTING
        row    TYPE i
        column TYPE string.

    METHODS at_user_command
      IMPORTING
        ucomm TYPE string.

    "! AT SELECTION-SCREEN ON VALUE-REQUEST - F4 on a field, field is its
    "! attribute name. Answer with value_help_popup( ) or by setting the
    "! attribute directly. This implementation is the standard F4: the
    "! fixed values of the domain, the search help of the data element or
    "! the value table with its texts (on premise) - call
    "! super->at_value_request( field ) for the fields you do not answer
    METHODS at_value_request
      IMPORTING
        field TYPE string.

    "! in at_value_request( ): the part of a select-option F4 is asked for -
    "! cs_part-high for ON VALUE-REQUEST FOR s-high, LOW otherwise
    METHODS value_request_part
      RETURNING
        VALUE(result) TYPE string.

    "! F4 in a cell of the ALV - row of the table and the column; the classic
    "! ONF4 of CL_GUI_ALV_GRID. The default shows the value help of the
    "! DDIC for the column, its pick lands in the cell and raises
    "! at_data_changed( )
    METHODS at_alv_value_request
      IMPORTING
        row    TYPE i
        column TYPE string.

    "! the authorization to run the report - checked at the start and before
    "! every run; abap_false shows nothing but the message. Redefine it with
    "! the AUTHORITY-CHECK of the report
    METHODS authority_check
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the layout of selection screen dynnr, called by
    "! call_selection_screen( ) - the counterpart of SELECTION-SCREEN BEGIN
    "! OF SCREEN dynnr AS WINDOW
    METHODS selection_screen_dynnr
      IMPORTING
        dynnr  TYPE string
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! after call_selection_screen( ) - subrc 0 when the user confirmed,
    "! 4 when he cancelled, as sy-subrc after CALL SELECTION-SCREEN
    METHODS after_call_selection_screen
      IMPORTING
        dynnr TYPE string
        subrc TYPE i.

    "! WRITE - returns the list for further WRITEs, NEW-LINE, ULINE, ...
    "! pos and len are WRITE AT pos(len)
    "! the options are those of z2ui5_cl_cgui_list=>write( ) - what is not
    "! passed takes FORMAT
    METHODS write
      IMPORTING
        VALUE(val)    TYPE any
        color         TYPE clike     DEFAULT z2ui5_cl_cgui_list=>cs_color-none
        hotspot       TYPE abap_bool DEFAULT abap_false
        VALUE(hide)   TYPE any       OPTIONAL
        pos           TYPE i         DEFAULT 0
        len           TYPE i         DEFAULT 0
        intensified   TYPE abap_bool OPTIONAL
        inverse       TYPE abap_bool OPTIONAL
        input         TYPE abap_bool OPTIONAL
        no_zero       TYPE abap_bool OPTIONAL
        no_sign       TYPE abap_bool OPTIONAL
        currency      TYPE clike     OPTIONAL
        unit          TYPE clike     OPTIONAL
        decimals      TYPE i         OPTIONAL
        justify       TYPE clike     OPTIONAL
        no_gap        TYPE abap_bool OPTIONAL
        edit_mask     TYPE clike     OPTIONAL
        no_grouping   TYPE abap_bool OPTIONAL
        round         TYPE i         OPTIONAL
        date_format   TYPE clike     OPTIONAL
        time_zone     TYPE clike     OPTIONAL
        quickinfo     TYPE clike     OPTIONAL
        name          TYPE clike     OPTIONAL
        under         TYPE clike     OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! FORMAT - the defaults of the WRITEs that follow, see
    "! z2ui5_cl_cgui_list=>format( )
    METHODS format
      IMPORTING
        color         TYPE clike     OPTIONAL
        intensified   TYPE abap_bool OPTIONAL
        inverse       TYPE abap_bool OPTIONAL
        hotspot       TYPE abap_bool OPTIONAL
        input         TYPE abap_bool OPTIONAL
        reset         TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! GET CURSOR FIELD ... VALUE ... LINE ... OFFSET - in
    "! at_line_selection( ): the field clicked (its name( ) of the WRITE, the
    "! column of the ALV), its value, line and column
    METHODS get_cursor
      RETURNING
        VALUE(result) TYPE ty_s_cgui_cursor.

    "! SY-LISEL - in at_line_selection( ): the line clicked, as text
    METHODS lisel
      RETURNING
        VALUE(result) TYPE string.

    "! SET CURSOR FIELD - the selection screen opens with the cursor in
    "! field name (in at_selection_screen_output( ) or before)
    METHODS set_cursor_field
      IMPORTING
        name TYPE clike.

    "! RS_SET_SELSCREEN_STATUS - switch off standard functions of the
    "! selection screen: cs_ucomm-execute, variant_get, variant_save,
    "! variant_delete, link_copy
    METHODS set_selscreen_status
      IMPORTING
        excluding TYPE string_table.

    "! the list output of this run
    METHODS list
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! show tab as ALV grid - returns the ALV for its settings. Pass a PUBLIC
    "! attribute of the report: the grid binds it directly. Anything else is
    "! copied into mr_cgui_alv, whose type the draft has to rebuild with RTTI
    "! on every roundtrip
    METHODS alv
      IMPORTING
        tab           TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_alv.

    "! show an ALV tree - CL_SALV_TREE: add its nodes with add_node( ). A
    "! click on the text of a node raises at_tree_node( )
    METHODS tree
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_tree.

    "! the rows selected in the ALV (set_selection_mode( )) - indices of the
    "! table passed to alv( )
    METHODS get_selected_rows
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_alv=>ty_t_row.

    "! SY-LSIND - 0 for the basic list, 1 for the first secondary list, ...
    METHODS lsind
      RETURNING
        VALUE(result) TYPE i.

    "! MESSAGE text TYPE type - S, I, W, E or A. field, the attribute name of
    "! a field of the selection screen, marks that field with the message;
    "! inside at_selection_screen_on( ) it is that method's field by default
    METHODS message
      IMPORTING
        text  TYPE clike
        type  TYPE clike DEFAULT `S`
        field TYPE clike OPTIONAL.

    "! MESSAGE ID id TYPE type NUMBER number WITH v1 ... v4 - the text of the
    "! message class in the logon language
    METHODS message_t100
      IMPORTING
        id     TYPE clike
        number TYPE numeric
        type   TYPE clike DEFAULT `S`
        v1     TYPE any   OPTIONAL
        v2     TYPE any   OPTIONAL
        v3     TYPE any   OPTIONAL
        v4     TYPE any   OPTIONAL
        field  TYPE clike OPTIONAL.

    "! every message of a BAPIRET2 table - what a BAPI returned
    METHODS messages_from_bapiret
      IMPORTING
        tab TYPE STANDARD TABLE.

    "! POPUP_TO_CONFIRM - on Yes, at_user_command( ) runs with ucomm
    METHODS popup_to_confirm
      IMPORTING
        question TYPE clike
        ucomm    TYPE clike
        title    TYPE clike DEFAULT `Confirm`.

    "! POPUP_TO_DECIDE - on an answer at_user_command( ) runs with ucomm,
    "! popup_answer( ) returns `1`, `2`, ... for the option or `A` for cancel
    METHODS popup_to_decide
      IMPORTING
        question TYPE clike
        options  TYPE string_table
        ucomm    TYPE clike
        title    TYPE clike OPTIONAL.

    "! POPUP_GET_VALUES - on OK at_user_command( ) runs with ucomm and
    "! popup_values( ) returns the fields with what the user entered
    METHODS popup_get_values
      IMPORTING
        fields  TYPE z2ui5_cl_cgui_popup=>ty_t_field
        ucomm   TYPE clike
        title   TYPE clike                         OPTIONAL
        text    TYPE clike                         OPTIONAL
        listbox TYPE z2ui5_cl_cgui_popup=>ty_t_listbox OPTIONAL.

    "! the answer of the last popup_to_decide( )
    METHODS popup_answer
      RETURNING
        VALUE(result) TYPE string.

    "! the fields of the last popup_get_values( )
    METHODS popup_values
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_popup=>ty_t_field.

    "! F4 help for the field of at_value_request( ): the user picks a row of
    "! tab, and its component col (the first one when empty) is written
    "! into the field. For a select-option the user picks any number of
    "! rows, which replace its lines as I EQ
    METHODS value_help_popup
      IMPORTING
        tab   TYPE STANDARD TABLE
        col   TYPE clike OPTIONAL
        title TYPE clike OPTIONAL.

    "! VRM_SET_VALUES - the values of the listbox of field name
    METHODS vrm_set_values
      IMPORTING
        name   TYPE clike
        values TYPE z2ui5_cl_cgui_selscreen=>ty_t_value.

    "! LEAVE TO LIST-PROCESSING's way back - show the selection screen again
    METHODS leave_to_selection_screen.

    "! WINDOW STARTING AT x1 y1 ENDING AT x2 y2 - in at_line_selection( ):
    "! the secondary list is shown in a dialog box above the list it comes
    "! from. columns and lines - ENDING AT minus STARTING AT - size the box,
    "! 0 lines fits it to the content
    METHODS window
      IMPORTING
        title   TYPE clike OPTIONAL
        columns TYPE i DEFAULT 80
        lines   TYPE i DEFAULT 0.

    "! CALL SELECTION-SCREEN dynnr AS WINDOW - the fields of
    "! selection_screen_dynnr( ) in a popup; after_call_selection_screen( )
    "! follows
    METHODS call_selection_screen
      IMPORTING
        dynnr TYPE clike
        title TYPE clike OPTIONAL.

    "! SUBMIT report WITH ... AND RETURN - starts the report class report
    "! with values; Back returns here. Without via_selection_screen it runs
    "! straight away, as SUBMIT does without VIA SELECTION-SCREEN
    METHODS submit
      IMPORTING
        report               TYPE clike
        values               TYPE z2ui5_cl_cgui_variant=>ty_t_value OPTIONAL
        via_selection_screen TYPE abap_bool DEFAULT abap_false
        using_variant        TYPE clike     OPTIONAL.

    "! SET PARAMETER ID - kept in the browser's local storage for every
    "! report (there is no SAP memory on ABAP Cloud)
    METHODS set_parameter_id
      IMPORTING
        id    TYPE clike
        value TYPE any.

    "! GET PARAMETER ID - from the browser's local storage
    METHODS get_parameter_id
      IMPORTING
        id            TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! REPORT ... LINE-COUNT n - the list breaks into pages of n lines
    METHODS set_line_count
      IMPORTING
        val TYPE i.

    "! SET PF-STATUS - the functions of the toolbar of the output; each
    "! arrives in at_user_command( ) with its name
    METHODS set_pf_status
      IMPORTING
        functions TYPE z2ui5_cl_cgui_alv=>ty_t_function
        excluding TYPE string_table OPTIONAL.

    "! the title of the report, the class name when not set
    METHODS set_title
      IMPORTING
        val TYPE clike.

    "! load the selection variant name - in initialization( ) the report
    "! starts with it, as soon as the variants are read. A variant that does
    "! not exist is passed over without a message, so a report can start
    "! with a variant DEFAULT whenever the user saved one
    METHODS set_variant
      IMPORTING
        name TYPE clike.

    "! keep the selection variants in store instead of table Z2UI5_CGUI_VAR
    "! (z2ui5_cl_cgui_variant_db, the default) - set it in initialization( ).
    "! Without a store the variants are kept in the browser's local storage
    METHODS set_variant_store
      IMPORTING
        store TYPE REF TO z2ui5_if_cgui_variant_store OPTIONAL.

    "! keep the ALV layouts in store instead of table Z2UI5_CGUI_LAY
    "! (z2ui5_cl_cgui_layout_db, the default) - set it in initialization( ).
    "! Without a store the layouts are kept with the selection variants
    METHODS set_layout_store
      IMPORTING
        store TYPE REF TO z2ui5_if_cgui_layout_store OPTIONAL.

    "! the URL that starts the report with the values of the selection screen
    "! - run straight away with skip_screen
    METHODS get_link
      IMPORTING
        skip_screen   TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE string.

    " the runtime's own state - PROTECTED, not PRIVATE: the draft persists
    " the app with CALL TRANSFORMATION id, and the transpiled runtime reaches
    " PROTECTED attributes but not PRIVATE ones. The cgui prefix keeps them
    " apart from the attributes of the report that inherits
    DATA mv_cgui_screen        TYPE string.
    DATA mv_cgui_title         TYPE string.
    DATA mo_cgui_list          TYPE REF TO z2ui5_cl_cgui_list.
    DATA mo_cgui_alv           TYPE REF TO z2ui5_cl_cgui_alv.
    DATA mo_cgui_tree          TYPE REF TO z2ui5_cl_cgui_tree.
    " per row of mr_cgui_alv_page the row of the table it comes from
    DATA mt_cgui_alv_index     TYPE z2ui5_cl_cgui_alv=>ty_t_index.

    DATA mv_cgui_alv_name      TYPE string.
    DATA mt_cgui_level         TYPE ty_t_cgui_level.
    DATA mt_cgui_field         TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA mt_cgui_msg           TYPE ty_t_cgui_msg.
    " the messages of the run, I, W, E and A - what the message popover
    " lists; kept while the user picks one of them
    DATA mt_cgui_log           TYPE ty_t_cgui_msg.
    " every message of the run, S included - what cgui_run_in_background( )
    " returns
    DATA mt_cgui_run_msg       TYPE ty_t_cgui_msg.
    DATA mv_cgui_stop          TYPE abap_bool.
    DATA mv_cgui_nav           TYPE abap_bool.
    DATA mv_cgui_value_field   TYPE string.
    " F4 on the upper limit of a select-option (HIGH) - and in a cell of
    " the ALV: its row of the table shown and its column
    DATA mv_cgui_value_part    TYPE string.
    DATA mv_cgui_pending_part  TYPE string.
    DATA mv_cgui_alv_f4_row    TYPE i.
    DATA mv_cgui_alv_f4_col    TYPE string.
    DATA mv_cgui_pending_field TYPE string.
    DATA mv_cgui_pending_kind  TYPE string.
    DATA mv_cgui_pending_col   TYPE string.
    DATA mv_cgui_pending_ucomm TYPE string.
    DATA mv_cgui_on_field      TYPE string.
    DATA mv_cgui_variant       TYPE string.
    DATA mv_cgui_variant_start TYPE string.
    DATA mv_cgui_variant_url   TYPE abap_bool.
    " the store of the selection variants - z2ui5_cl_cgui_variant_db unless
    " set_variant_store( ) named another one or none (mv_cgui_store_none:
    " the browser's local storage)
    DATA mo_cgui_store         TYPE REF TO z2ui5_if_cgui_variant_store.
    DATA mv_cgui_store_none    TYPE abap_bool.
    " the store of the ALV layouts - z2ui5_cl_cgui_layout_db unless
    " set_layout_store( ) named another one or none (mv_cgui_lay_none)
    DATA mo_cgui_lay_store     TYPE REF TO z2ui5_if_cgui_layout_store.
    DATA mv_cgui_lay_none      TYPE abap_bool.
    DATA mt_cgui_vrm           TYPE ty_t_cgui_vrm.
    DATA mt_cgui_url           TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA mt_cgui_submit        TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA mv_cgui_called        TYPE abap_bool.
    DATA mv_cgui_skip          TYPE abap_bool.
    DATA mv_cgui_skipped       TYPE abap_bool.
    DATA mv_cgui_auto_exec     TYPE abap_bool.
    DATA mv_cgui_denied        TYPE abap_bool.

    DATA mv_cgui_batch         TYPE abap_bool.
    DATA mv_cgui_answer        TYPE string.
    DATA mt_cgui_popup_values  TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA mv_cgui_dynnr         TYPE string.
    DATA mv_cgui_dynnr_title   TYPE string.
    DATA mt_cgui_dynnr_field   TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    " the multiple selection while F4 on one of its lines runs: the lines,
    " the select-option, the line and part F4 is for (no line - several
    " new values) and whether value_help_popup( ) answers the popup
    DATA mt_cgui_range_row     TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA mv_cgui_range_field   TYPE string.
    DATA mv_cgui_range_key     TYPE string.
    DATA mv_cgui_range_part    TYPE string.
    DATA mv_cgui_range_f4      TYPE abap_bool.
    " the ALV layout in use and whether the default one was looked for
    DATA mv_cgui_layout        TYPE string.
    DATA mv_cgui_layout_done   TYPE abap_bool.
    " WINDOW STARTING AT - the current list in a dialog box
    DATA mv_cgui_window        TYPE abap_bool.
    DATA mv_cgui_window_title  TYPE string.
    DATA mv_cgui_window_cols   TYPE i.
    DATA mv_cgui_window_lines  TYPE i.
    DATA mv_cgui_window_shown  TYPE abap_bool.
    " the column the filter dialog is open for
    DATA mv_cgui_filter_col    TYPE string.
    " GET CURSOR and SY-LISEL of the last line selection
    DATA ms_cgui_cursor        TYPE ty_s_cgui_cursor.
    DATA mv_cgui_lisel         TYPE string.
    " SET CURSOR FIELD on the selection screen
    DATA mv_cgui_cursor_field  TYPE string.
    " the standard functions switched off - selection screen and output
    DATA mt_cgui_excl_sel      TYPE string_table.
    DATA mt_cgui_excl_out      TYPE string_table.
    DATA mv_cgui_line_count    TYPE i.
    DATA mt_cgui_pf            TYPE z2ui5_cl_cgui_alv=>ty_t_function.
    DATA mt_cgui_fkey          TYPE z2ui5_cl_cgui_selscreen=>ty_t_function_key.
    " the variant attributes of the fields shown: not ready for input, hidden
    DATA mt_cgui_var_protect   TYPE string_table.
    DATA mt_cgui_var_hide      TYPE string_table.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF cs_screen,
        selection TYPE string VALUE `SELECTION`,
        output    TYPE string VALUE `OUTPUT`,
      END OF cs_screen.

    CONSTANTS:
      BEGIN OF cs_pending,
        range          TYPE string VALUE `RANGE`,
        f4             TYPE string VALUE `F4`,
        variant_get    TYPE string VALUE `VARIANT_GET`,
        variant_save   TYPE string VALUE `VARIANT_SAVE`,
        variant_delete TYPE string VALUE `VARIANT_DELETE`,
        decide         TYPE string VALUE `DECIDE`,
        values         TYPE string VALUE `VALUES`,
        layout         TYPE string VALUE `LAYOUT`,
        filter_col     TYPE string VALUE `FILTER_COL`,
        filter         TYPE string VALUE `FILTER`,
        alv_f4         TYPE string VALUE `ALV_F4`,
      END OF cs_pending.

    TYPES:
      " character types - the popup heads its columns with their names
      BEGIN OF ty_s_cgui_filter_col,
        column TYPE c LENGTH 30,
        text   TYPE c LENGTH 60,
        filter TYPE c LENGTH 60,
      END OF ty_s_cgui_filter_col.
    TYPES ty_t_cgui_filter_col TYPE STANDARD TABLE OF ty_s_cgui_filter_col WITH EMPTY KEY.

    TYPES:
      " character types - the popup heads its columns with their names
      BEGIN OF ty_s_variant_row,
        variant TYPE c LENGTH 40,
        values  TYPE c LENGTH 255,
      END OF ty_s_variant_row.
    TYPES ty_t_variant_row TYPE STANDARD TABLE OF ty_s_variant_row WITH EMPTY KEY.

    METHODS on_init.

    METHODS on_event.

    METHODS on_navigated.

    METHODS on_back.

    METHODS on_line_selection
      IMPORTING
        row    TYPE i
        hide   TYPE string
        column TYPE string OPTIONAL
        link   TYPE abap_bool DEFAULT abap_false.

    METHODS level_push.

    METHODS level_pop.

    METHODS screen_fields
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    "! the inputs of the roundtrip: the select-option buffer into the ranges,
    "! character fields to upper case
    METHODS input_sync.

    METHODS so_buffer_prepare
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS tab_binding_prepare
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS url_values_get.

    METHODS url_values_apply.

    METHODS url_param
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS url_params
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

    METHODS url_decode
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! a select-option of the URL - A,B (EQ), A..B (BT), A* (CP), !A (E),
    "! &gt;=A, &lt;=A, &gt;A, &lt;A, &lt;&gt;A - as values of a variant
    METHODS url_range
      IMPORTING
        name          TYPE string
        val           TYPE string
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    METHODS url_from_range
      IMPORTING
        values        TYPE z2ui5_cl_cgui_variant=>ty_t_value
      RETURNING
        VALUE(result) TYPE string.

    METHODS memory_id_apply.

    METHODS memory_id_store.

    METHODS spa_get
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

    METHODS spa_set
      IMPORTING
        values TYPE z2ui5_if_client=>ty_t_name_value.

    METHODS on_storage_loaded.

    METHODS auto_execute.

    METHODS variant_popup
      IMPORTING
        kind TYPE string.

    METHODS variant_selected
      RETURNING
        VALUE(result) TYPE string.

    METHODS variant_apply
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS variant_save
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_popup.

    METHODS variant_delete
      IMPORTING
        name TYPE string.

    METHODS variant_store
      IMPORTING
        variants TYPE z2ui5_cl_cgui_variant=>ty_t_variant.

    METHODS variant_catalog
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_variant=>ty_t_variant.

    METHODS variant_key
      RETURNING
        VALUE(result) TYPE string.

    METHODS variant_from_url
      RETURNING
        VALUE(result) TYPE string.

    METHODS on_execute.

    METHODS run
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS check_screen
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS check_obligatory
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS on_range_popup
      IMPORTING
        field TYPE string.

    METHODS on_range_result
      IMPORTING
        field TYPE string.

    "! the multiple selection of mv_cgui_range_field with rows
    METHODS range_popup_open
      IMPORTING
        rows  TYPE z2ui5_cl_cgui_range=>ty_t_row
        error TYPE string OPTIONAL.

    METHODS range_setting
      IMPORTING
        field         TYPE string
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_range=>ty_s_setting.

    "! F4 asked for in the multiple selection - at_value_request( ) of the
    "! select-option, answered into mt_cgui_range_row
    METHODS range_value_request.

    "! the values picked in the value help into mt_cgui_range_row
    METHODS range_f4_values
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_select
        col   TYPE string.

    METHODS on_f4_result
      IMPORTING
        field TYPE string
        col   TYPE string.

    METHODS value_help_ddic
      IMPORTING
        field TYPE string.

    "! tab with a column ZZSELKZ, set for every row whose col is a line
    "! I EQ of range - the selection the popup starts with
    METHODS value_help_preselect
      IMPORTING
        tab           TYPE STANDARD TABLE
        col           TYPE string
        range         TYPE STANDARD TABLE
      RETURNING
        VALUE(result) TYPE REF TO data.

    METHODS value_help_title
      IMPORTING
        field         TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS attri_assign
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the table of alv( ) and the one the grid shows - the copy with the
    "! box field when the grid has a selection column the table lacks
    METHODS alv_source
      RETURNING
        VALUE(result) TYPE REF TO data.

    METHODS alv_shown
      RETURNING
        VALUE(result) TYPE REF TO data.

    METHODS alv_box_refresh
      IMPORTING
        source TYPE REF TO data.

    "! the layouts of the ALV saved for the report
    METHODS layouts
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_layout=>ty_t_saved.

    "! the store of the ALV layouts - unbound when they are kept with the
    "! selection variants
    METHODS layout_store
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_if_cgui_layout_store.

    "! the ALV the layouts belong to - the attribute alv( ) shows
    METHODS layout_handle
      RETURNING
        VALUE(result) TYPE string.

    "! save or delete a layout in the layout store - abap_false and an
    "! error message when the store refused
    METHODS layout_store_change
      IMPORTING
        layout        TYPE z2ui5_cl_cgui_layout=>ty_s_saved
        delete        TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS layout_popup.

    METHODS layout_result.

    "! the default layout - once for a grid, before it is shown first
    METHODS layout_default_apply
      IMPORTING
        tab TYPE STANDARD TABLE.

    "! save variant in the store of the report - selection variants and
    "! layouts alike
    METHODS variant_put
      IMPORTING
        variant       TYPE z2ui5_cl_cgui_variant=>ty_s_variant
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS variant_remove
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the input of an editable grid shown as copy into the report's table
    METHODS alv_edit_sync.

    "! the rows the grid shows - filtered or paged - back into the table
    "! they are cut from
    METHODS alv_page_sync.

    "! single selection: one row stays selected
    METHODS alv_single_sync.

    "! what F4 fills: the cell of the ALV asked for, or the field
    METHODS value_help_target
      IMPORTING
        field         TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! a click on a node of the tree - a secondary list as for a line
    METHODS on_tree_node
      IMPORTING
        key TYPE i.

    "! back from the value help of an ALV cell
    METHODS alv_f4_result
      IMPORTING
        col TYPE string.

    "! GET CURSOR and SY-LISEL of a click into the list
    METHODS cursor_from_list
      IMPORTING
        line TYPE i
        id   TYPE i.

    "! the first output parameter of search help name
    METHODS matchcode_field
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! the row of the table behind row of the grid
    METHODS alv_row
      IMPORTING
        row           TYPE i
      RETURNING
        VALUE(result) TYPE i.

    "! the table of the report as the grid shows it - only the rows that
    "! pass the filter; export and printout take it
    METHODS alv_visible_source
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the filter button: the columns to pick one from
    METHODS alv_filter_popup.

    "! back from the columns - the multiple selection of the column picked
    METHODS alv_filter_column_result.

    "! the multiple selection for the filter of column mv_cgui_filter_col
    METHODS alv_filter_open
      IMPORTING
        rows  TYPE z2ui5_cl_cgui_range=>ty_t_row
        error TYPE string OPTIONAL.

    "! back from the multiple selection - the filter is set
    METHODS alv_filter_result.

    "! the list below the dialog box of WINDOW, as text
    METHODS view_display_window_base
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the dialog box of WINDOW with the current list
    METHODS view_display_window.

    "! the printout of the output - a text file to the browser
    METHODS on_print.

    METHODS print_lines
      RETURNING
        VALUE(result) TYPE string_table.

    "! the variant attributes onto the screen
    METHODS variant_attributes_apply
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! VALUE CHECK, ON BLOCK and ON RADIOBUTTON GROUP
    METHODS check_values
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS on_alv_event
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS view_display.

    METHODS view_display_output
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.

    METHODS view_display_dynnr.

    METHODS on_screen_ok.

    METHODS shortcuts_register.

    METHODS messages_display.

    METHODS messages_render
      IMPORTING
        page    TYPE REF TO z2ui5_cl_ui5_view_builder
        toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.

    METHODS message_focus
      IMPORTING
        arg TYPE string.

    METHODS message_field_text
      IMPORTING
        field         TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS value_state_set
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

ENDCLASS.


CLASS z2ui5_cl_cgui_report IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    CLEAR mt_cgui_msg.
    mv_cgui_nav = abap_false.
    " the messages of the run stay while the popover opens and the user
    " picks one of them
    IF client->get_event( ) <> cs_ucomm-message_focus AND client->get_event( ) <> cs_ucomm-messages_open.
      CLEAR mt_cgui_log.
    ENDIF.

    IF client->check_on_init( ).
      on_init( ).
    ELSEIF client->check_on_navigated( ).
      " back from a popup or a called report - a popup that confirms returns
      " with its ucomm as event, handled like any other user command
      on_navigated( ).
      IF client->get_event( ) IS NOT INITIAL.
        on_event( ).
      ENDIF.
      IF mv_cgui_nav = abap_false.
        view_display( ).
      ENDIF.
    ELSEIF client->check_on_event( ).
      input_sync( ).
      on_event( ).
      IF mv_cgui_nav = abap_false.
        view_display( ).
      ENDIF.
    ENDIF.

    messages_display( ).

  ENDMETHOD.

  METHOD on_init.

    mv_cgui_screen = cs_screen-selection.
    mv_cgui_title = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).

    IF authority_check( ) = abap_false.
      mv_cgui_denied = abap_true.
      message( text = 'You are not authorized to run this report'(001)
               type = `E` ).
      view_display( ).
      RETURN.
    ENDIF.

    initialization( ).

    " SUBMIT ... WITH: the values of the caller after INITIALIZATION
    IF mt_cgui_submit IS NOT INITIAL.
      z2ui5_cl_cgui_variant=>values_set( app    = me
                                         values = mt_cgui_submit ).
    ENDIF.

    " the default store is the table, unless initialization( ) chose another
    " one or the browser's local storage
    IF mo_cgui_store IS NOT BOUND AND mv_cgui_store_none = abap_false.
      mo_cgui_store = z2ui5_cl_cgui_variant_db=>factory( ).
    ENDIF.

    " a server store reads the variants now, the browser once it rendered
    IF mo_cgui_store IS BOUND.
      variant_store( mo_cgui_store->load( variant_key( ) ) ).
    ENDIF.

    " a variant in the URL wins over the one initialization( ) set
    DATA(lv_variant) = variant_from_url( ).
    IF lv_variant IS NOT INITIAL.
      mv_cgui_variant_start = lv_variant.
      mv_cgui_variant_url = abap_true.
    ENDIF.
    IF mv_cgui_variant_start IS NOT INITIAL AND mo_cgui_store IS BOUND.
      DATA(lv_start) = mv_cgui_variant_start.
      CLEAR mv_cgui_variant_start.
      IF variant_apply( lv_start ) = abap_false AND mv_cgui_variant_url = abap_true.
        message( text = replace( val  = 'Variant &1 does not exist'(002)
                                 sub  = `&1`
                                 with = lv_start )
                 type = `W` ).
      ENDIF.
    ENDIF.

    " the fields of the screen - what the URL and MEMORY ID may fill
    mt_cgui_field = screen_fields( ).
    memory_id_apply( ).
    url_values_get( ).
    url_values_apply( ).

    IF mv_cgui_skip = abap_true OR to_upper( url_param( cv_cgui_url_skip ) ) = abap_true.
      IF mv_cgui_variant_start IS NOT INITIAL.
        " the variant arrives with the browser's storage - the run waits for
        " it, and a timer runs it when nothing is stored
        mv_cgui_auto_exec = abap_true.
        client->follow_up_action( val   = client->cs_event-start_timer
                                  t_arg = VALUE #( ( cs_ucomm-auto_execute ) ( `700` ) ) ).
      ELSE.
        mv_cgui_skipped = abap_true.
        on_execute( ).
      ENDIF.
    ENDIF.

    view_display( ).

  ENDMETHOD.

  METHOD initialization ##NEEDED.
  ENDMETHOD.

  METHOD selection_screen ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen_output ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen_on ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen ##NEEDED.
  ENDMETHOD.

  METHOD start_of_selection ##NEEDED.
  ENDMETHOD.

  METHOD end_of_selection ##NEEDED.
  ENDMETHOD.

  METHOD end_of_page ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen_on_block ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen_on_radio ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen_on_end_of ##NEEDED.
  ENDMETHOD.

  METHOD at_selection_screen_on_help.

    READ TABLE mt_cgui_field INTO DATA(ls_field) WITH KEY name = field.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DATA(lt_text) = z2ui5_cl_cgui_context=>dtel_docu_read( ls_field-dtel ).
    IF lt_text IS INITIAL.
      message( 'No documentation is available'(040) ).
      RETURN.
    ENDIF.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>decide(
        question = concat_lines_of( table = lt_text sep = |\n\n| )
        options  = VALUE #( ( CONV #( 'OK'(041) ) ) )
        title    = COND #( WHEN ls_field-text IS NOT INITIAL THEN ls_field-text ELSE 'Help'(042) )
        cancel   = abap_false ) ).

  ENDMETHOD.

  METHOD set_line_count.

    mv_cgui_line_count = val.
    IF mo_cgui_list IS BOUND.
      mo_cgui_list->set_line_count( val ).
    ENDIF.

  ENDMETHOD.

  METHOD set_pf_status.

    mt_cgui_pf = functions.

    mt_cgui_excl_out = excluding.

  ENDMETHOD.

  METHOD top_of_page ##NEEDED.
  ENDMETHOD.

  METHOD top_of_page_line_selection ##NEEDED.
  ENDMETHOD.

  METHOD at_line_selection ##NEEDED.
  ENDMETHOD.

  METHOD at_data_changed ##NEEDED.
  ENDMETHOD.

  METHOD at_link_click.

    at_line_selection( row  = row
                       hide = column ).

  ENDMETHOD.

  METHOD at_user_command ##NEEDED.
  ENDMETHOD.

  METHOD selection_screen_dynnr ##NEEDED.
  ENDMETHOD.

  METHOD after_call_selection_screen ##NEEDED.
  ENDMETHOD.

  METHOD authority_check.

    result = abap_true.

  ENDMETHOD.

  METHOD value_request_part.

    result = COND #( WHEN mv_cgui_value_part IS NOT INITIAL THEN mv_cgui_value_part
                     ELSE z2ui5_cl_cgui_selscreen=>cs_part-low ).

  ENDMETHOD.

  METHOD at_alv_value_request ##NEEDED.

    " the value help of the DDIC for the type of the column
    value_help_ddic( column ).

  ENDMETHOD.

  METHOD value_help_target.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    IF mv_cgui_alv_f4_col IS INITIAL OR to_upper( field ) <> mv_cgui_alv_f4_col.
      result = attri_assign( field ).
      RETURN.
    ENDIF.
    " the cell of the ALV
    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    READ TABLE <tab> ASSIGNING FIELD-SYMBOL(<row>) INDEX mv_cgui_alv_f4_row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT mv_cgui_alv_f4_col OF STRUCTURE <row> TO FIELD-SYMBOL(<cell>).
    IF sy-subrc = 0.
      GET REFERENCE OF <cell> INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD alv_f4_result.

    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <cell>  TYPE any.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.

    DATA(lv_row) = mv_cgui_alv_f4_row.
    DATA(lv_col) = mv_cgui_alv_f4_col.
    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        CLEAR lo_popup.
    ENDTRY.
    IF lo_popup IS BOUND AND lo_popup->result( )-confirmed = abap_true AND lo_popup->result( )-row IS BOUND.
      DATA(lr_cell) = value_help_target( lv_col ).
      DATA(lr_row) = lo_popup->result( )-row.
      ASSIGN lr_row->* TO <row>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF lr_cell IS BOUND AND <value> IS ASSIGNED.
        ASSIGN lr_cell->* TO <cell>.
        <cell> = <value>.
        " the copy with the box field into the table, then DATA_CHANGED
        alv_edit_sync( ).
        at_data_changed( row    = lv_row
                         column = lv_col ).
      ENDIF.
    ENDIF.
    CLEAR: mv_cgui_alv_f4_row, mv_cgui_alv_f4_col.

  ENDMETHOD.

  METHOD at_value_request.

    value_help_ddic( field ).

  ENDMETHOD.

  METHOD value_help_ddic.

    DATA lt_value TYPE ty_t_cgui_value.
    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA(lr_val) = value_help_target( field ).
    IF lr_val IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_val->* TO <field_val>.
    DATA(lo_descr) = z2ui5_cl_cgui_context=>rtti_get_value_descr( <field_val> ).

    " MATCHCODE OBJECT - the search help named at the field comes first
    DATA(lv_field_name) = to_upper( field ).
    READ TABLE mt_cgui_field REFERENCE INTO DATA(lr_mc) WITH KEY name = lv_field_name.
    IF sy-subrc = 0 AND lr_mc->matchcode IS NOT INITIAL.
      DATA(ls_mc) = VALUE z2ui5_cl_cgui_context=>ty_s_search_help( name  = lr_mc->matchcode
                                                                  field = matchcode_field( lr_mc->matchcode ) ).
      IF ls_mc-field IS NOT INITIAL.
        DATA(lr_mc_hits) = z2ui5_cl_cgui_context=>search_help_select( ls_mc ).
        IF lr_mc_hits IS BOUND.
          ASSIGN lr_mc_hits->* TO <tab>.
          IF <tab> IS NOT INITIAL.
            value_help_popup( tab   = <tab>
                              col   = ls_mc-field
                              title = value_help_title( field ) ).
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    DATA(lt_fix) = z2ui5_cl_cgui_context=>rtti_get_fixed_values( lo_descr ).
    IF lt_fix IS NOT INITIAL.
      LOOP AT lt_fix REFERENCE INTO DATA(lr_fix).
        INSERT VALUE #( value = lr_fix->low
                        text  = lr_fix->text ) INTO TABLE lt_value.
      ENDLOOP.
      value_help_popup( tab   = lt_value
                        col   = `VALUE`
                        title = value_help_title( field ) ).
      RETURN.
    ENDIF.

    " the search help of the data element - its hit list without a dialog
    DATA(ls_help) = z2ui5_cl_cgui_context=>rtti_get_search_help( lo_descr ).
    IF ls_help-name IS NOT INITIAL.
      DATA(lr_hits) = z2ui5_cl_cgui_context=>search_help_select( ls_help ).
      IF lr_hits IS BOUND.
        ASSIGN lr_hits->* TO <tab>.
        IF <tab> IS NOT INITIAL.
          value_help_popup( tab   = <tab>
                            col   = ls_help-field
                            title = value_help_title( field ) ).
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    " the value table with the texts of its text table
    DATA(ls_table) = z2ui5_cl_cgui_context=>rtti_get_value_table( lo_descr ).
    IF ls_table-table IS NOT INITIAL.
      DATA(lr_rows) = z2ui5_cl_cgui_context=>value_table_select( ls_table ).
      IF lr_rows IS BOUND.
        ASSIGN lr_rows->* TO <tab>.
        IF <tab> IS NOT INITIAL.
          value_help_popup( tab   = <tab>
                            col   = ls_table-field
                            title = value_help_title( field ) ).
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    message( 'No input help is available'(003) ).

  ENDMETHOD.

  METHOD value_help_preselect.

    DATA lt_comp  TYPE cl_abap_structdescr=>component_table.
    DATA lv_flag  TYPE abap_bool.
    DATA lr_row   TYPE REF TO data.
    FIELD-SYMBOLS <tab>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <src>   TYPE any.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <selkz> TYPE any.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <comp>  TYPE any.

    TRY.
        DATA(lo_table) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( tab ) ).
        DATA(lo_line) = CAST cl_abap_structdescr( lo_table->get_table_line_type( ) ).
        lt_comp = lo_line->get_components( ).
        READ TABLE lt_comp WITH KEY name = `ZZSELKZ` TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          RETURN.
        ENDIF.
        INSERT VALUE #( name = `ZZSELKZ`
                        type = CAST #( cl_abap_typedescr=>describe_by_data( lv_flag ) ) ) INTO TABLE lt_comp.

        DATA(lo_new) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
        CREATE DATA result TYPE HANDLE lo_new.
        ASSIGN result->* TO <tab>.
      CATCH cx_root.
        CLEAR result.
        RETURN.
    ENDTRY.

    LOOP AT tab ASSIGNING <src>.
      CREATE DATA lr_row LIKE LINE OF <tab>.
      ASSIGN lr_row->* TO <row>.
      MOVE-CORRESPONDING <src> TO <row>.

      UNASSIGN <value>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF <value> IS ASSIGNED.
        LOOP AT range ASSIGNING <line>.
          ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
          IF <comp> <> `I`.
            CONTINUE.
          ENDIF.
          ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
          IF <comp> <> `EQ`.
            CONTINUE.
          ENDIF.
          ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
          IF <comp> = <value>.
            ASSIGN COMPONENT `ZZSELKZ` OF STRUCTURE <row> TO <selkz>.
            <selkz> = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.

      INSERT <row> INTO TABLE <tab>.
    ENDLOOP.

  ENDMETHOD.

  METHOD value_help_title.

    READ TABLE mt_cgui_field REFERENCE INTO DATA(lr_field) WITH KEY name = field.
    IF sy-subrc = 0.
      result = lr_field->text.
    ENDIF.

  ENDMETHOD.

  METHOD on_event.

    DATA(lv_event) = client->get_event( ).

    alv_page_sync( ).
    alv_single_sync( ).
    alv_edit_sync( ).
    " the ticks of the tree, before the event reads them
    IF mo_cgui_tree IS BOUND.
      mo_cgui_tree->sync( mt_cgui_tree_view ).
    ENDIF.
    IF mo_cgui_list IS BOUND AND mt_cgui_list_input IS NOT INITIAL.
      mo_cgui_list->set_inputs( mt_cgui_list_input ).
    ENDIF.
    IF on_alv_event( ) = abap_true.
      RETURN.
    ENDIF.
    IF mo_cgui_tree IS BOUND.
      IF lv_event = z2ui5_cl_cgui_tree=>cs_event-node.
        on_tree_node( z2ui5_cl_cgui_tree=>get_node_by_event( client ) ).
        RETURN.
      ELSEIF mo_cgui_tree->handle_event( client ) = abap_true.
        DATA(lv_lazy) = mo_cgui_tree->take_expand_request( ).
        IF lv_lazy IS NOT INITIAL.
          at_tree_expand_no_children( lv_lazy ).
        ENDIF.
        RETURN.
      ELSEIF lv_event = z2ui5_cl_cgui_tree=>cs_event-checkbox.
        DATA(lv_tick) = z2ui5_cl_cgui_tree=>get_node_by_event( client ).
        at_tree_checkbox( key     = lv_tick
                          checked = mo_cgui_tree->get_node( lv_tick )-checked ).
        RETURN.
      ENDIF.
    ENDIF.

    CASE lv_event.

      WHEN cs_ucomm-execute.
        " F8 is registered for the whole app - on the output it does nothing
        IF mv_cgui_screen = cs_screen-selection AND mv_cgui_denied = abap_false
            AND NOT line_exists( mt_cgui_excl_sel[ table_line = cs_ucomm-execute ] ).
          on_execute( ).
        ENDIF.

      WHEN cs_ucomm-back.
        on_back( ).

      WHEN cs_ucomm-cancel.
        CLEAR: mv_cgui_pending_field, mv_cgui_pending_kind.

      WHEN cs_ucomm-variants_loaded.
        on_storage_loaded( ).

      WHEN cs_ucomm-auto_execute.
        auto_execute( ).

      WHEN cs_ucomm-messages_open.
        " the screen stays as it is - the popover opens on it
        mv_cgui_nav = abap_true.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( cv_cgui_popover_id ) ( `openBy` ) ( cv_cgui_messages_id ) ) ).

      WHEN cs_ucomm-message_focus.
        mv_cgui_nav = abap_true.
        message_focus( client->get_event_arg( ) ).

      WHEN cs_ucomm-variant_get.
        variant_popup( cs_pending-variant_get ).

      WHEN cs_ucomm-variant_save.
        variant_popup( cs_pending-variant_save ).

      WHEN cs_ucomm-variant_delete.
        variant_popup( cs_pending-variant_delete ).

      WHEN cs_ucomm-variant_delete_ok.
        variant_delete( mv_cgui_pending_field ).
        CLEAR mv_cgui_pending_field.

      WHEN cs_ucomm-variant_saved.
        " handled in on_navigated( ), which read the popup
        CLEAR mv_cgui_pending_ucomm.

      WHEN cs_ucomm-link_copy.
        client->follow_up_action( val   = client->cs_event-clipboard_copy
                                  t_arg = VALUE #( ( get_link( ) ) ) ).
        message( 'Link copied to the clipboard'(004) ).

      WHEN cs_ucomm-screen_ok.
        on_screen_ok( ).

      WHEN cs_ucomm-screen_cancel.
        " ON EXIT-COMMAND - an error keeps the popup screen
        mv_cgui_stop = abap_false.
        at_selection_screen_on_exit( cs_ucomm-cancel ).
        IF mv_cgui_stop = abap_true.
          mv_cgui_stop = abap_false.
          RETURN.
        ENDIF.
        DATA(lv_dynnr) = mv_cgui_dynnr.
        CLEAR mv_cgui_dynnr.
        client->popup_destroy( ).
        after_call_selection_screen( dynnr = lv_dynnr
                                     subrc = 4 ).

      WHEN z2ui5_cl_cgui_selscreen=>cs_event-select_option.
        on_range_popup( client->get_event_arg( ) ).

      WHEN z2ui5_cl_cgui_selscreen=>cs_event-help_request.
        at_selection_screen_on_help( client->get_event_arg( ) ).

      WHEN cs_ucomm-print.
        on_print( ).

      WHEN z2ui5_cl_cgui_selscreen=>cs_event-value_request.
        mv_cgui_value_field = client->get_event_arg( ).
        mv_cgui_value_part = to_upper( client->get_event_arg( 2 ) ).
        at_value_request( mv_cgui_value_field ).
        CLEAR: mv_cgui_value_field, mv_cgui_value_part.

      WHEN z2ui5_cl_cgui_list=>cs_event-line_selection.
        cursor_from_list( line = CONV i( client->get_event_arg( ) )
                          id   = CONV i( client->get_event_arg( 3 ) ) ).
        on_line_selection( row  = CONV i( client->get_event_arg( ) )
                           hide = client->get_event_arg( 2 ) ).

      WHEN z2ui5_cl_cgui_alv=>cs_event-data_changed.
        DATA(ls_change) = z2ui5_cl_cgui_alv=>get_hotspot_by_event( client ).
        at_data_changed( row    = alv_row( ls_change-row )
                         column = ls_change-column ).

      WHEN z2ui5_cl_cgui_alv=>cs_event-line_selection.
        DATA(lv_alv_row) = alv_row( z2ui5_cl_cgui_alv=>get_row_by_event( client ) ).
        ms_cgui_cursor = VALUE #( line = lv_alv_row ).
        CLEAR mv_cgui_lisel.
        on_line_selection( row  = lv_alv_row
                           hide = `` ).

      WHEN z2ui5_cl_cgui_alv=>cs_event-hotspot.
        DATA(ls_hotspot) = z2ui5_cl_cgui_alv=>get_hotspot_by_event( client ).
        ms_cgui_cursor = VALUE #( field = ls_hotspot-column
                                  line  = alv_row( ls_hotspot-row ) ).
        CLEAR mv_cgui_lisel.
        on_line_selection( row    = alv_row( ls_hotspot-row )
                           hide   = ls_hotspot-column
                           column = ls_hotspot-column
                           link   = abap_true ).

      WHEN OTHERS.
        IF mv_cgui_pending_ucomm IS NOT INITIAL AND lv_event = mv_cgui_pending_ucomm.
          CLEAR mv_cgui_pending_ucomm.
        ENDIF.

        at_user_command( lv_event ).

    ENDCASE.

  ENDMETHOD.

  METHOD on_alv_event.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA(lv_event) = client->get_event( ).
    IF mo_cgui_alv IS NOT BOUND
        OR ( lv_event <> z2ui5_cl_cgui_alv=>cs_event-select_all
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-deselect_all
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-export
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-export_xlsx
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-layout
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-page
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-filter
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-filter_clear
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-details
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-details_close
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-search
         AND lv_event <> z2ui5_cl_cgui_alv=>cs_event-f4 ).
      RETURN.
    ENDIF.

    result = abap_true.
    DATA(lr_full) = alv_shown( ).
    CASE lv_event.
      WHEN z2ui5_cl_cgui_alv=>cs_event-page.
        IF lr_full IS BOUND.
          ASSIGN lr_full->* TO <tab>.
          mo_cgui_alv->page_turn( direction = client->get_event_arg( )
                                  lines     = lines( mo_cgui_alv->filter_index( <tab> ) ) ).
        ENDIF.
        RETURN.
      WHEN z2ui5_cl_cgui_alv=>cs_event-filter.
        alv_filter_popup( ).
        RETURN.
      WHEN z2ui5_cl_cgui_alv=>cs_event-filter_clear.
        mo_cgui_alv->clear_filter( ).
        mo_cgui_alv->set_search( `` ).
        RETURN.
      WHEN z2ui5_cl_cgui_alv=>cs_event-search.
        mo_cgui_alv->set_search( client->get_event_arg( ) ).
        RETURN.
      WHEN z2ui5_cl_cgui_alv=>cs_event-f4.
        DATA(ls_f4) = z2ui5_cl_cgui_alv=>get_hotspot_by_event( client ).
        mv_cgui_alv_f4_row = alv_row( ls_f4-row ).
        mv_cgui_alv_f4_col = to_upper( ls_f4-column ).
        mv_cgui_value_field = mv_cgui_alv_f4_col.
        at_alv_value_request( row    = mv_cgui_alv_f4_row
                              column = mv_cgui_alv_f4_col ).
        CLEAR mv_cgui_value_field.
        IF mv_cgui_nav = abap_false.
          CLEAR: mv_cgui_alv_f4_row, mv_cgui_alv_f4_col.
        ENDIF.
        RETURN.
      WHEN z2ui5_cl_cgui_alv=>cs_event-details.
        IF lr_full IS BOUND.
          ASSIGN lr_full->* TO <tab>.
          DATA(lt_selected) = mo_cgui_alv->get_selected_rows( <tab> ).
          IF lt_selected IS INITIAL.
            message( text = 'Select a row'(044)
                     type = `W` ).
          ELSE.
            mo_cgui_alv->details_popup( client = client
                                        tab    = <tab>
                                        row    = lt_selected[ 1 ] ).
          ENDIF.
        ENDIF.
        RETURN.
      WHEN z2ui5_cl_cgui_alv=>cs_event-select_all OR z2ui5_cl_cgui_alv=>cs_event-deselect_all.
        " filtered: the rows that pass, as the classic ALV does
        IF lr_full IS BOUND AND mo_cgui_alv->is_filtered( ) = abap_true.
          ASSIGN lr_full->* TO <tab>.
          DATA(lt_index) = mo_cgui_alv->filter_index( <tab> ).
          DATA(lv_box) = mo_cgui_alv->get_box_field( ).
          FIELD-SYMBOLS <box> TYPE any.
          LOOP AT lt_index INTO DATA(lv_row).
            READ TABLE <tab> ASSIGNING FIELD-SYMBOL(<line>) INDEX lv_row.
            IF sy-subrc <> 0.
              CONTINUE.
            ENDIF.
            ASSIGN COMPONENT lv_box OF STRUCTURE <line> TO <box>.
            IF sy-subrc = 0.
              <box> = xsdbool( lv_event = z2ui5_cl_cgui_alv=>cs_event-select_all ).
            ENDIF.
          ENDLOOP.
          RETURN.
        ENDIF.
    ENDCASE.
    IF lv_event = z2ui5_cl_cgui_alv=>cs_event-layout.
      layout_popup( ).
      RETURN.
    ENDIF.
    " the export takes the table of the report, the selection the table the
    " grid shows
    DATA lr_tab TYPE REF TO data.
    IF lv_event = z2ui5_cl_cgui_alv=>cs_event-export OR lv_event = z2ui5_cl_cgui_alv=>cs_event-export_xlsx.
      lr_tab = alv_visible_source( ).
    ELSE.
      lr_tab = alv_shown( ).
    ENDIF.
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    mo_cgui_alv->handle_event( EXPORTING client = client
                               CHANGING  tab    = <tab> ).

  ENDMETHOD.

  METHOD on_back.

    " ON EXIT-COMMAND - an error keeps the selection screen
    IF mv_cgui_screen = cs_screen-selection.
      mv_cgui_stop = abap_false.
      at_selection_screen_on_exit( cs_ucomm-back ).
      IF mv_cgui_stop = abap_true.
        mv_cgui_stop = abap_false.
        RETURN.
      ENDIF.
    ENDIF.

    IF mv_cgui_screen = cs_screen-output AND mt_cgui_level IS NOT INITIAL.
      level_pop( ).
      RETURN.
    ENDIF.

    " a called report returns to its caller: from the selection screen, or
    " from the output when it ran without one
    IF mv_cgui_called = abap_true
        AND ( mv_cgui_screen = cs_screen-selection OR mv_cgui_skipped = abap_true ).
      mv_cgui_nav = abap_true.
      client->nav_app_leave( client->get_app_prev( ) ).
      RETURN.
    ENDIF.

    IF mv_cgui_screen = cs_screen-output.
      leave_to_selection_screen( ).
    ENDIF.

  ENDMETHOD.

  METHOD on_line_selection.

    " what the event block writes is a secondary list; nothing written, the
    " list stays as it is
    level_push( ).
    IF link = abap_true.
      at_link_click( row    = row
                     column = column ).
    ELSE.
      at_line_selection( row  = row
                         hide = hide ).
    ENDIF.

    IF mv_cgui_screen <> cs_screen-output.
      " leave_to_selection_screen( ) - the levels are gone
      CLEAR mt_cgui_level.
      RETURN.
    ENDIF.
    IF mo_cgui_alv IS NOT BOUND AND mo_cgui_tree IS NOT BOUND
        AND ( mo_cgui_list IS NOT BOUND OR mo_cgui_list->has_content( ) = abap_false ).
      level_pop( ).
    ENDIF.

  ENDMETHOD.

  METHOD level_push.

    INSERT VALUE #( list     = mo_cgui_list
                    alv      = mo_cgui_alv
                    tree     = mo_cgui_tree
                    alv_name = mv_cgui_alv_name
                    alv_data = mr_cgui_alv
                    window   = mv_cgui_window
                    w_title  = mv_cgui_window_title
                    w_cols   = mv_cgui_window_cols
                    w_lines  = mv_cgui_window_lines ) INTO TABLE mt_cgui_level.
    CLEAR: mo_cgui_list, mo_cgui_alv, mv_cgui_alv_name, mr_cgui_alv, mr_cgui_alv_box,
           mr_cgui_alv_page, mt_cgui_alv_index, mo_cgui_tree, mt_cgui_tree_view,
           mv_cgui_window, mv_cgui_window_title, mv_cgui_window_cols, mv_cgui_window_lines.

  ENDMETHOD.

  METHOD level_pop.

    DATA(lv_lines) = lines( mt_cgui_level ).
    IF lv_lines = 0.
      RETURN.
    ENDIF.
    DATA(ls_level) = mt_cgui_level[ lv_lines ].
    DELETE mt_cgui_level INDEX lv_lines.

    mo_cgui_list     = ls_level-list.
    mo_cgui_alv      = ls_level-alv.
    mo_cgui_tree     = ls_level-tree.
    mv_cgui_alv_name = ls_level-alv_name.
    mr_cgui_alv      = ls_level-alv_data.
    mv_cgui_window       = ls_level-window.
    mv_cgui_window_title = ls_level-w_title.
    mv_cgui_window_cols  = ls_level-w_cols.
    mv_cgui_window_lines = ls_level-w_lines.
    CLEAR: mr_cgui_alv_box, mr_cgui_alv_page, mt_cgui_alv_index.

  ENDMETHOD.

  METHOD lsind.

    result = lines( mt_cgui_level ).

  ENDMETHOD.

  METHOD on_navigated.

    " at_value_request( ) of the multiple selection opened another popup
    IF mv_cgui_pending_kind <> cs_pending-f4.
      mv_cgui_range_f4 = abap_false.
    ENDIF.

    IF mv_cgui_pending_kind IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_field) = mv_cgui_pending_field.
    DATA(lv_kind) = mv_cgui_pending_kind.
    DATA(lv_col) = mv_cgui_pending_col.
    CLEAR: mv_cgui_pending_field, mv_cgui_pending_kind, mv_cgui_pending_col.

    CASE lv_kind.
      WHEN cs_pending-range.
        on_range_result( lv_field ).

      WHEN cs_pending-f4.
        on_f4_result( field = lv_field
                      col   = lv_col ).

      WHEN cs_pending-variant_get.
        DATA(lv_name) = variant_selected( ).
        IF lv_name IS NOT INITIAL AND variant_apply( lv_name ) = abap_true.
          message( replace( val  = 'Variant &1 loaded'(005)
                            sub  = `&1`
                            with = lv_name ) ).
        ENDIF.

      WHEN cs_pending-variant_save.
        TRY.
            DATA(lo_popup) = CAST z2ui5_cl_cgui_popup( client->get_app_prev( ) ).
          CATCH cx_root.
            RETURN.
        ENDTRY.
        IF lo_popup->result( )-confirmed = abap_true.
          variant_save( lo_popup ).
        ENDIF.

      WHEN cs_pending-variant_delete.
        lv_name = variant_selected( ).
        IF lv_name IS NOT INITIAL.
          " the name waits in mv_cgui_pending_field for the confirmation
          mv_cgui_pending_field = lv_name.
          popup_to_confirm( question = replace( val  = 'Delete the variant &1?'(006)
                                                sub  = `&1`
                                                with = lv_name )
                            ucomm    = cs_ucomm-variant_delete_ok
                            title    = 'Delete Variant'(007) ).
        ENDIF.

      WHEN cs_pending-layout.
        layout_result( ).

      WHEN cs_pending-filter_col.
        alv_filter_column_result( ).

      WHEN cs_pending-filter.
        alv_filter_result( ).

      WHEN cs_pending-alv_f4.
        alv_f4_result( lv_col ).

      WHEN cs_pending-decide OR cs_pending-values.
        TRY.
            lo_popup = CAST z2ui5_cl_cgui_popup( client->get_app_prev( ) ).
          CATCH cx_root.
            RETURN.
        ENDTRY.
        mv_cgui_answer = lo_popup->result( )-answer.
        mt_cgui_popup_values = lo_popup->result( )-fields.

    ENDCASE.

  ENDMETHOD.

  METHOD screen_fields.

    " the layout without rendering - which fields the report has
    DATA(screen) = z2ui5_cl_cgui_selscreen=>factory( client = client
                                                     app    = me ).
    selection_screen( screen ).
    result = screen->get_fields( ).

  ENDMETHOD.

  METHOD input_sync.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <comp>  TYPE any.
    FIELD-SYMBOLS <field_val>   TYPE clike.
    DATA lr_line TYPE REF TO data.

    IF mv_cgui_screen <> cs_screen-selection.
      RETURN.
    ENDIF.

    " the inputs from and to - the first line of a range, as the classic
    " select-option shows it. A pattern (* or +) is CP
    LOOP AT mt_cgui_so REFERENCE INTO DATA(lr_so).
      DATA(lr_range) = attri_assign( lr_so->name ).
      IF lr_range IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_range->* TO <range>.

      READ TABLE mt_cgui_field REFERENCE INTO DATA(lr_field) WITH KEY name = lr_so->name.
      IF sy-subrc = 0 AND lr_field->upper = abap_true.
        lr_so->low  = to_upper( lr_so->low ).
        lr_so->high = to_upper( lr_so->high ).
      ENDIF.

      CLEAR <range>.
      IF lr_so->low IS INITIAL AND lr_so->high IS INITIAL.
        CONTINUE.
      ENDIF.
      CREATE DATA lr_line LIKE LINE OF <range>.
      ASSIGN lr_line->* TO <line>.
      TRY.
          ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
          <comp> = `I`.
          ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
          IF lr_so->high IS NOT INITIAL.
            <comp> = `BT`.
          ELSEIF lr_so->low CA `*+`.
            <comp> = `CP`.
          ELSE.
            <comp> = `EQ`.
          ENDIF.
          ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
          <comp> = lr_so->low.
          ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
          <comp> = lr_so->high.
          INSERT <line> INTO TABLE <range>.
        CATCH cx_sy_conversion_error.
          message( text  = replace( val  = 'Enter a valid value for &1'(008)
                                    sub  = `&1`
                                    with = message_field_text( lr_so->name ) )
                   type  = `E`
                   field = lr_so->name ).
      ENDTRY.
    ENDLOOP.

    " PARAMETERS without LOWER CASE
    LOOP AT mt_cgui_field REFERENCE INTO lr_field
         WHERE upper = abap_true AND kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-parameter.
      DATA(lr_val) = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      TRANSLATE <field_val> TO UPPER CASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD so_buffer_prepare.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <sign>  TYPE any.
    FIELD-SYMBOLS <opt>   TYPE any.
    FIELD-SYMBOLS <low>   TYPE any.
    FIELD-SYMBOLS <high>  TYPE any.
    FIELD-SYMBOLS <so>    TYPE ty_s_cgui_so.

    CLEAR mt_cgui_so.

    " a range of no line or one simple line shows it in from and to; any
    " other range is shown as text, changed with the multiple selection
    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field)
         WHERE kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option AND no_display = abap_false.
      DATA(lr_range) = attri_assign( lr_field->name ).
      IF lr_range IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_range->* TO <range>.

      DATA(ls_so) = VALUE ty_s_cgui_so( name = lr_field->name ).
      IF lines( <range> ) > 1.
        CONTINUE.
      ELSEIF lines( <range> ) = 1.
        READ TABLE <range> ASSIGNING <line> INDEX 1.
        ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <sign>.
        ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <opt>.
        ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
        ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <high>.
        IF <sign> <> `I` OR ( <opt> <> `EQ` AND <opt> <> `BT` AND <opt> <> `CP` )
            OR ( <low> IS INITIAL AND <high> IS INITIAL )
            OR ( <opt> = `CP` AND NOT |{ <low> }| CA `*+` )
            OR ( <opt> = `EQ` AND |{ <low> }| CA `*+` ).
          CONTINUE.
        ENDIF.
        ls_so-low = |{ <low> }|.
        IF <opt> = `BT`.
          ls_so-high = |{ <high> }|.
        ENDIF.
        IF z2ui5_cl_cgui_context=>rtti_get_type_kind( <low> ) = cl_abap_typedescr=>typekind_date AND <low> IS INITIAL.
          CLEAR ls_so-low.
        ENDIF.
      ENDIF.

      INSERT ls_so INTO TABLE mt_cgui_so.
      DATA(lv_index) = lines( mt_cgui_so ).
      ASSIGN mt_cgui_so[ lv_index ] TO <so>.
      screen->set_select_option_input( name      = lr_field->name
                                       low_bind  = client->_bind( val       = <so>-low
                                                                  tab       = mt_cgui_so
                                                                  tab_index = lv_index )
                                       high_bind = client->_bind( val       = <so>-high
                                                                  tab       = mt_cgui_so
                                                                  tab_index = lv_index ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD tab_binding_prepare.

    FIELD-SYMBOLS <tab> TYPE ty_s_cgui_tab.

    DATA(lv_count) = screen->get_tabbed_block_count( ).
    WHILE lines( mt_cgui_tab ) < lv_count.
      INSERT VALUE #( key = `TAB1` ) INTO TABLE mt_cgui_tab.
    ENDWHILE.

    DO lv_count TIMES.
      DATA(lv_index) = sy-index.
      ASSIGN mt_cgui_tab[ lv_index ] TO <tab>.
      screen->set_tabbed_block_binding( index = lv_index
                                        bind  = client->_bind( val       = <tab>-key
                                                               tab       = mt_cgui_tab
                                                               tab_index = lv_index ) ).
    ENDDO.

  ENDMETHOD.

  METHOD url_params.

    DATA lt_param TYPE string_table.
    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.

    LOOP AT client->get( )-t_comp_params INTO DATA(ls_comp).
      INSERT VALUE #( n = to_upper( ls_comp-n )
                      v = ls_comp-v ) INTO TABLE result.
    ENDLOOP.

    DATA(lv_search) = client->get( )-s_config-search.
    IF lv_search IS INITIAL.
      RETURN.
    ENDIF.
    IF lv_search(1) = `?`.
      lv_search = lv_search+1.
    ENDIF.

    SPLIT lv_search AT `&` INTO TABLE lt_param.
    LOOP AT lt_param INTO DATA(lv_param).
      CLEAR: lv_name, lv_value.
      SPLIT lv_param AT `=` INTO lv_name lv_value.
      lv_name = to_upper( url_decode( lv_name ) ).
      IF line_exists( result[ n = lv_name ] ).
        CONTINUE.
      ENDIF.
      INSERT VALUE #( n = lv_name
                      v = url_decode( lv_value ) ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD url_param.

    DATA(lt_param) = url_params( ).
    DATA(lv_name) = to_upper( name ).
    READ TABLE lt_param INTO DATA(ls_param) WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_param-v.
    ENDIF.

  ENDMETHOD.

  METHOD url_decode.

    DATA lv_hex  TYPE x LENGTH 1.
    DATA lv_xstr TYPE xstring.
    DATA lv_char TYPE xstring.

    result = replace( val = val sub = `+` with = ` ` occ = 0 ).
    IF result NA `%`.
      RETURN.
    ENDIF.

    " %XX are the bytes of UTF-8
    DATA(lv_in) = result.
    DATA(lv_len) = strlen( lv_in ).
    DATA(lv_pos) = 0.
    WHILE lv_pos < lv_len.
      IF lv_in+lv_pos(1) = `%` AND lv_pos + 3 <= lv_len.
        DATA(lv_digits) = to_upper( substring( val = lv_in off = lv_pos + 1 len = 2 ) ).
        IF lv_digits CO `0123456789ABCDEF`.
          lv_hex = lv_digits.
          CONCATENATE lv_xstr lv_hex INTO lv_xstr IN BYTE MODE.
          lv_pos = lv_pos + 3.
          CONTINUE.
        ENDIF.
      ENDIF.
      lv_char = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( substring( val = lv_in off = lv_pos len = 1 ) ).
      CONCATENATE lv_xstr lv_char INTO lv_xstr IN BYTE MODE.
      lv_pos = lv_pos + 1.
    ENDWHILE.

    DATA(lv_text) = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( lv_xstr ).
    IF lv_text IS NOT INITIAL.
      result = lv_text.
    ENDIF.

  ENDMETHOD.

  METHOD url_values_get.

    " only fields of the screen the user could fill himself - no NO-DISPLAY
    " field and nothing else of the class is set from the URL
    CLEAR mt_cgui_url.
    DATA(lt_param) = url_params( ).

    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE no_display = abap_false.
      READ TABLE lt_param INTO DATA(ls_param) WITH KEY n = lr_field->name.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        INSERT LINES OF url_range( name = lr_field->name
                                   val  = ls_param-v ) INTO TABLE mt_cgui_url.
      ELSE.
        INSERT VALUE #( name = lr_field->name
                        kind = z2ui5_cl_cgui_variant=>cs_kind-parameter
                        low  = ls_param-v ) INTO TABLE mt_cgui_url.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD url_values_apply.

    IF mt_cgui_url IS NOT INITIAL.
      z2ui5_cl_cgui_variant=>values_set( app    = me
                                         values = mt_cgui_url ).
    ENDIF.

  ENDMETHOD.

  METHOD url_range.

    DATA lt_part TYPE string_table.
    DATA ls_value TYPE z2ui5_cl_cgui_variant=>ty_s_value.

    SPLIT val AT `,` INTO TABLE lt_part.
    LOOP AT lt_part INTO DATA(lv_part).
      CLEAR ls_value.
      ls_value-name = name.
      ls_value-kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
      ls_value-sign = `I`.
      IF lv_part IS NOT INITIAL AND lv_part(1) = `!`.
        ls_value-sign = `E`.
        lv_part = lv_part+1.
      ENDIF.
      IF lv_part CS `..`.
        SPLIT lv_part AT `..` INTO ls_value-low ls_value-high.
        ls_value-option = `BT`.
      ELSEIF lv_part CP `>=*`.
        ls_value-option = `GE`.
        ls_value-low = substring( val = lv_part off = 2 ).
      ELSEIF lv_part CP `<=*`.
        ls_value-option = `LE`.
        ls_value-low = substring( val = lv_part off = 2 ).
      ELSEIF lv_part CP `<>*`.
        ls_value-option = `NE`.
        ls_value-low = substring( val = lv_part off = 2 ).
      ELSEIF lv_part CP `>*`.
        ls_value-option = `GT`.
        ls_value-low = substring( val = lv_part off = 1 ).
      ELSEIF lv_part CP `<*`.
        ls_value-option = `LT`.
        ls_value-low = substring( val = lv_part off = 1 ).
      ELSEIF lv_part CA `*+`.
        ls_value-option = `CP`.
        ls_value-low = lv_part.
      ELSE.
        ls_value-option = `EQ`.
        ls_value-low = lv_part.
      ENDIF.
      INSERT ls_value INTO TABLE result.
    ENDLOOP.

    IF result IS INITIAL.
      INSERT VALUE #( name = name
                      kind = z2ui5_cl_cgui_variant=>cs_kind-select_option ) INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD url_from_range.

    DATA lv_part TYPE string.

    LOOP AT values REFERENCE INTO DATA(lr_value) WHERE sign IS NOT INITIAL.
      CASE lr_value->option.
        WHEN `BT`.
          lv_part = |{ lr_value->low }..{ lr_value->high }|.
        WHEN `GE`.
          lv_part = |>={ lr_value->low }|.
        WHEN `LE`.
          lv_part = |<={ lr_value->low }|.
        WHEN `NE`.
          lv_part = |<>{ lr_value->low }|.
        WHEN `GT`.
          lv_part = |>{ lr_value->low }|.
        WHEN `LT`.
          lv_part = |<{ lr_value->low }|.
        WHEN OTHERS.
          lv_part = lr_value->low.
      ENDCASE.
      IF lr_value->sign = `E`.
        lv_part = |!{ lv_part }|.
      ENDIF.
      IF result IS INITIAL.
        result = lv_part.
      ELSE.
        result = |{ result },{ lv_part }|.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_link.

    DATA lt_name TYPE string_table.
    DATA lt_query TYPE string_table.
    DATA lt_keep  TYPE string_table.
    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.

    " the parameters of the URL that are no field of the screen stay - the
    " app to start, the client, the language
    DATA(lv_search) = client->get( )-s_config-search.
    IF lv_search IS NOT INITIAL AND lv_search(1) = `?`.
      lv_search = lv_search+1.
    ENDIF.
    SPLIT lv_search AT `&` INTO TABLE lt_query.
    LOOP AT lt_query INTO DATA(lv_param) WHERE table_line IS NOT INITIAL.
      CLEAR: lv_name, lv_value.
      SPLIT lv_param AT `=` INTO lv_name lv_value.
      lv_name = to_upper( url_decode( lv_name ) ).
      IF line_exists( mt_cgui_field[ name = lv_name ] ) OR lv_name = cv_cgui_url_skip OR lv_name = `VARIANT`.
        CONTINUE.
      ENDIF.
      INSERT lv_param INTO TABLE lt_keep.
    ENDLOOP.
    " a variable, not the template - a WITH KEY operand on 7.02
    DATA(lv_app_start) = |app_start={ to_lower( variant_key( ) ) }|.
    IF NOT line_exists( lt_keep[ table_line = lv_app_start ] )
        AND NOT lv_search CS `app_start`.
      INSERT lv_app_start INTO TABLE lt_keep.
    ENDIF.

    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE no_display = abap_false.
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.
    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = me
                                                        names = lt_name ).

    LOOP AT mt_cgui_field REFERENCE INTO lr_field WHERE no_display = abap_false.
      DATA(lt_field_value) = VALUE z2ui5_cl_cgui_variant=>ty_t_value(
          FOR ls_v IN lt_value WHERE ( name = lr_field->name ) ( ls_v ) ).
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        lv_value = url_from_range( lt_field_value ).
      ELSE.
        lv_value = VALUE #( lt_field_value[ 1 ]-low OPTIONAL ).
      ENDIF.
      IF lv_value IS INITIAL.
        CONTINUE.
      ENDIF.
      INSERT |{ to_lower( lr_field->name ) }={ z2ui5_cl_cgui_context=>url_escape( lv_value ) }| INTO TABLE lt_keep.
    ENDLOOP.
    IF skip_screen = abap_true.
      INSERT |{ to_lower( cv_cgui_url_skip ) }=X| INTO TABLE lt_keep.
    ENDIF.

    result = |{ client->get( )-s_config-origin }{ client->get( )-s_config-pathname }?{ concat_lines_of( table = lt_keep sep = `&` ) }|.

  ENDMETHOD.

  METHOD memory_id_apply.

    " MEMORY ID: an empty field takes the value of its parameter ID - a
    " select-option as its line I EQ
    FIELD-SYMBOLS <field_val>   TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.

    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE memory_id IS NOT INITIAL.
      DATA(lr_val) = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      DATA(lv_value) = get_parameter_id( lr_field->memory_id ).
      IF lv_value IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        ASSIGN lr_val->* TO <range>.
        z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = VALUE #( ( sign = `I` option = `EQ` low = lv_value ) )
                                            IMPORTING error = DATA(lv_error)
                                            CHANGING  range = <range> ).
        IF lv_error IS NOT INITIAL.
          CLEAR <range>.
        ENDIF.
        CONTINUE.
      ENDIF.
      TRY.
          <field_val> = lv_value.
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.

  METHOD memory_id_store.

    " MEMORY ID: the run sets the parameter ID of every field with a value -
    " of a select-option the first value
    FIELD-SYMBOLS <field_val>   TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <low>   TYPE any.

    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE memory_id IS NOT INITIAL.
      DATA(lr_val) = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        ASSIGN lr_val->* TO <range>.
        READ TABLE <range> ASSIGNING FIELD-SYMBOL(<line>) INDEX 1.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
        IF sy-subrc = 0 AND <low> IS NOT INITIAL.
          set_parameter_id( id    = lr_field->memory_id
                            value = <low> ).
        ENDIF.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        set_parameter_id( id    = lr_field->memory_id
                          value = <field_val> ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD spa_get.

    DATA lt_line TYPE string_table.
    DATA lv_id   TYPE string.
    DATA lv_val  TYPE string.

    SPLIT mv_cgui_spa AT cl_abap_char_utilities=>newline INTO TABLE lt_line.
    LOOP AT lt_line INTO DATA(lv_line) WHERE table_line IS NOT INITIAL.
      SPLIT lv_line AT `=` INTO lv_id lv_val.
      INSERT VALUE #( n = to_upper( lv_id )
                      v = lv_val ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD spa_set.

    DATA lt_line TYPE string_table.

    LOOP AT values INTO DATA(ls_value).
      INSERT |{ ls_value-n }={ ls_value-v }| INTO TABLE lt_line.
    ENDLOOP.
    mv_cgui_spa = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).

    IF client IS BOUND AND mv_cgui_batch = abap_false.
      client->follow_up_action( val   = client->cs_event-store_data
                                t_arg = VALUE #( ( z2ui5_cl_cgui_variant=>storage_json( prefix = cv_cgui_spa_prefix
                                                                                        key    = cv_cgui_spa_key
                                                                                        val    = mv_cgui_spa ) ) ) ).
    ENDIF.

  ENDMETHOD.

  METHOD set_parameter_id.

    DATA(lt_spa) = spa_get( ).
    DATA(lv_name) = to_upper( id ).
    DELETE lt_spa WHERE n = lv_name.
    INSERT VALUE #( n = lv_name
                    v = |{ value }| ) INTO TABLE lt_spa.
    spa_set( lt_spa ).

  ENDMETHOD.

  METHOD get_parameter_id.

    DATA(lv_name) = to_upper( id ).
    DATA(lt_spa) = spa_get( ).
    READ TABLE lt_spa INTO DATA(ls_spa) WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_spa-v.
    ENDIF.

  ENDMETHOD.

  METHOD on_storage_loaded.

    " the storage controls have put what the browser holds into
    " mv_cgui_variants and mv_cgui_spa: the parameter IDs fill empty fields,
    " the start variant overwrites them, the URL wins over both
    memory_id_apply( ).

    IF mv_cgui_variant_start IS NOT INITIAL.
      DATA(lv_start) = mv_cgui_variant_start.
      CLEAR mv_cgui_variant_start.
      IF variant_apply( lv_start ) = abap_false AND mv_cgui_variant_url = abap_true.
        message( text = replace( val  = 'Variant &1 does not exist'(002)
                                 sub  = `&1`
                                 with = lv_start )
                 type = `W` ).
      ENDIF.
      url_values_apply( ).
    ENDIF.

    auto_execute( ).

  ENDMETHOD.

  METHOD auto_execute.

    IF mv_cgui_auto_exec = abap_false.
      RETURN.
    ENDIF.
    CLEAR: mv_cgui_auto_exec, mv_cgui_variant_start.
    mv_cgui_skipped = abap_true.
    on_execute( ).

  ENDMETHOD.

  METHOD variant_catalog.

    result = z2ui5_cl_cgui_variant=>catalog_from_string( mv_cgui_variants ).

  ENDMETHOD.

  METHOD variant_popup.

    DATA lt_row TYPE ty_t_variant_row.
    DATA lt_field TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA lt_listbox TYPE z2ui5_cl_cgui_popup=>ty_t_listbox.
    FIELD-SYMBOLS <field_val> TYPE any.

    DATA(lt_variant) = variant_catalog( ).

    IF kind = cs_pending-variant_save.
      " the name, the sharing of a server store, and a dynamic date for
      " every date of the screen
      DATA ls_current TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
      DATA ls_old     TYPE z2ui5_cl_cgui_variant=>ty_s_value.
      ls_current = VALUE #( lt_variant[ name = mv_cgui_variant ] OPTIONAL ).
      INSERT VALUE #( name     = `NAME`
                      text     = CONV #( 'Variant name'(009) )
                      value    = mv_cgui_variant
                      required = abap_true ) INTO TABLE lt_field.
      IF mo_cgui_store IS BOUND AND mo_cgui_store->check_sharing( ) = abap_true.
        INSERT VALUE #( name = `SHARED`
                        text = CONV #( 'Shared with all users'(010) )
                        kind = z2ui5_cl_cgui_popup=>cs_kind-checkbox
                        flag = ls_current-shared ) INTO TABLE lt_field.
        INSERT VALUE #( name = `PROTECTED`
                        text = CONV #( 'Protected - only I change it'(011) )
                        kind = z2ui5_cl_cgui_popup=>cs_kind-checkbox
                        flag = ls_current-protected ) INTO TABLE lt_field.
      ENDIF.
      " the variant attributes: fields protected or hidden
      INSERT VALUE #( name = `PROTECT`
                      text = CONV #( 'Protected fields'(038) )
                      kind = z2ui5_cl_cgui_popup=>cs_kind-multi
                      keys = ls_current-protect ) INTO TABLE lt_field.
      INSERT VALUE #( name = `HIDE`
                      text = CONV #( 'Hidden fields'(039) )
                      kind = z2ui5_cl_cgui_popup=>cs_kind-multi
                      keys = ls_current-hide ) INTO TABLE lt_field.
      LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_attr) WHERE no_display = abap_false AND name IS NOT INITIAL.
        INSERT VALUE #( name = `PROTECT`
                        key  = lr_attr->name
                        text = COND #( WHEN lr_attr->text IS NOT INITIAL THEN lr_attr->text ELSE lr_attr->name ) ) INTO TABLE lt_listbox.
        INSERT VALUE #( name = `HIDE`
                        key  = lr_attr->name
                        text = COND #( WHEN lr_attr->text IS NOT INITIAL THEN lr_attr->text ELSE lr_attr->name ) ) INTO TABLE lt_listbox.
      ENDLOOP.
      DATA(lt_dynamic) = z2ui5_cl_cgui_variant=>dynamic_values( ).
      LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE no_display = abap_false.
        DATA(lr_val) = attri_assign( lr_field->name ).
        IF lr_val IS NOT BOUND.
          CONTINUE.
        ENDIF.
        ASSIGN lr_val->* TO <field_val>.
        DATA(lo_descr) = z2ui5_cl_cgui_context=>rtti_get_value_descr( <field_val> ).
        IF lo_descr IS NOT BOUND OR lo_descr->type_kind <> cl_abap_typedescr=>typekind_date.
          CONTINUE.
        ENDIF.
        ls_old = VALUE #( ls_current-values[ name = lr_field->name ] OPTIONAL ).
        INSERT VALUE #( name  = |DYN_{ lr_field->name }|
                        text  = replace( val  = 'Dynamic date &1'(012)
                                         sub  = `&1`
                                         with = lr_field->text )
                        kind  = z2ui5_cl_cgui_popup=>cs_kind-listbox
                        value = ls_old-dynamic ) INTO TABLE lt_field.
        IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
          INSERT VALUE #( name  = |DYNH_{ lr_field->name }|
                          text  = replace( val  = 'Dynamic date &1 (to)'(013)
                                           sub  = `&1`
                                           with = lr_field->text )
                          kind  = z2ui5_cl_cgui_popup=>cs_kind-listbox
                          value = ls_old-dynamic_high ) INTO TABLE lt_field.
        ENDIF.
        LOOP AT lt_dynamic INTO DATA(ls_dynamic).
          INSERT VALUE #( name = |DYN_{ lr_field->name }|
                          key  = ls_dynamic-key
                          text = ls_dynamic-text ) INTO TABLE lt_listbox.
          INSERT VALUE #( name = |DYNH_{ lr_field->name }|
                          key  = ls_dynamic-key
                          text = ls_dynamic-text ) INTO TABLE lt_listbox.
        ENDLOOP.
      ENDLOOP.

      mv_cgui_pending_kind = kind.
      mv_cgui_nav = abap_true.
      client->nav_app_call( z2ui5_cl_cgui_popup=>get_values( fields  = lt_field
                                                             listbox = lt_listbox
                                                             title   = CONV string( 'Save as Variant'(014) )
                                                             event   = cs_ucomm-variant_saved ) ).
      RETURN.
    ENDIF.

    " the layouts of the ALV are kept as variants too - they are none
    DELETE lt_variant WHERE name CP '##*'.
    IF lt_variant IS INITIAL.
      message( text = 'No variants saved for this report yet'(015)
               type = `I` ).
      RETURN.
    ENDIF.

    LOOP AT lt_variant REFERENCE INTO DATA(lr_variant).
      INSERT VALUE #( variant = lr_variant->name
                      values  = COND #( WHEN lr_variant->owner IS NOT INITIAL
                                        THEN |{ lr_variant->text } ({ lr_variant->owner })|
                                        ELSE lr_variant->text ) ) INTO TABLE lt_row.
    ENDLOOP.

    mv_cgui_pending_kind = kind.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_select=>factory(
        tab   = lt_row
        title = COND string( WHEN kind = cs_pending-variant_delete THEN 'Delete Variant'(007) ELSE 'Get Variant'(016) ) ) ).

  ENDMETHOD.

  METHOD variant_selected.

    FIELD-SYMBOLS <row> TYPE ty_s_variant_row.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    DATA(ls_result) = lo_popup->result( ).
    IF ls_result-confirmed = abap_false OR ls_result-row IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ls_result-row->* TO <row>.
    result = condense( <row>-variant ).

  ENDMETHOD.

  METHOD variant_apply.

    DATA(lt_variant) = variant_catalog( ).

    READ TABLE lt_variant REFERENCE INTO DATA(lr_variant) WITH KEY name = name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    z2ui5_cl_cgui_variant=>values_set( app    = me
                                       values = lr_variant->values ).
    mv_cgui_variant = name.
    mt_cgui_var_protect = lr_variant->protect.
    mt_cgui_var_hide = lr_variant->hide.
    result = abap_true.

  ENDMETHOD.

  METHOD variant_save.

    DATA lt_name TYPE string_table.

    DATA(lv_name) = condense( popup->result_value( `NAME` ) ).
    IF lv_name IS INITIAL OR lv_name CP '##*'.
      message( text = 'Enter a name for the variant'(017)
               type = `E` ).
      RETURN.
    ENDIF.

    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field).
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.
    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = me
                                                        names = lt_name ).

    " the dynamic dates replace the values they stand for
    LOOP AT lt_value REFERENCE INTO DATA(lr_value).
      DATA(lv_dynamic) = popup->result_value( |DYN_{ lr_value->name }| ).
      IF lv_dynamic IS NOT INITIAL.
        lr_value->dynamic = lv_dynamic.
        IF lr_value->kind = z2ui5_cl_cgui_variant=>cs_kind-select_option AND lr_value->sign IS INITIAL.
          lr_value->sign = `I`.
          lr_value->option = `EQ`.
        ENDIF.
      ENDIF.
      DATA(lv_dynamic_high) = popup->result_value( |DYNH_{ lr_value->name }| ).
      IF lv_dynamic_high IS NOT INITIAL AND lr_value->kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
        lr_value->dynamic_high = lv_dynamic_high.
        lr_value->sign = `I`.
        lr_value->option = `BT`.
      ENDIF.
    ENDLOOP.

    DATA(ls_variant) = VALUE z2ui5_cl_cgui_variant=>ty_s_variant(
        name      = lv_name
        text      = z2ui5_cl_cgui_variant=>values_to_text( values = lt_value
                                                           fields = mt_cgui_field )
        values    = lt_value
        shared    = xsdbool( popup->result_value( `SHARED` ) IS NOT INITIAL )
        protected = xsdbool( popup->result_value( `PROTECTED` ) IS NOT INITIAL )
        protect   = popup->result_keys( `PROTECT` )
        hide      = popup->result_keys( `HIDE` ) ).

    IF mo_cgui_store IS BOUND.
      TRY.
          mo_cgui_store->save( report  = variant_key( )
                               variant = ls_variant ).
        CATCH z2ui5_cx_cgui_error INTO DATA(lx_error).
          message( text = lx_error->get_text( )
                   type = `E` ).
          RETURN.
      ENDTRY.
      variant_store( mo_cgui_store->load( variant_key( ) ) ).
    ELSE.
      DATA(lt_variant) = variant_catalog( ).
      DELETE lt_variant WHERE name = lv_name.
      INSERT ls_variant INTO TABLE lt_variant.
      SORT lt_variant BY name.
      variant_store( lt_variant ).
    ENDIF.

    mv_cgui_variant = lv_name.
    message( replace( val  = 'Variant &1 saved'(018)
                      sub  = `&1`
                      with = lv_name ) ).

  ENDMETHOD.

  METHOD variant_delete.

    IF mo_cgui_store IS BOUND.
      TRY.
          mo_cgui_store->delete( report = variant_key( )
                                 name   = name ).
        CATCH z2ui5_cx_cgui_error INTO DATA(lx_error).
          message( text = lx_error->get_text( )
                   type = `E` ).
          RETURN.
      ENDTRY.
      variant_store( mo_cgui_store->load( variant_key( ) ) ).
    ELSE.
      DATA(lt_variant) = variant_catalog( ).
      DELETE lt_variant WHERE name = name.
      variant_store( lt_variant ).
    ENDIF.

    IF mv_cgui_variant = name.
      CLEAR mv_cgui_variant.
    ENDIF.
    message( replace( val  = 'Variant &1 deleted'(019)
                      sub  = `&1`
                      with = name ) ).

  ENDMETHOD.

  METHOD variant_store.

    " the bound value and the stored one stay the same, so the storage
    " control has nothing to report on the next render. An empty catalog
    " removes the key. A server store keeps the catalog only in memory
    CLEAR mv_cgui_variants.
    IF variants IS NOT INITIAL.
      mv_cgui_variants = z2ui5_cl_cgui_variant=>catalog_to_string( variants ).
    ENDIF.

    IF mo_cgui_store IS BOUND OR client IS NOT BOUND OR mv_cgui_batch = abap_true.
      RETURN.
    ENDIF.
    client->follow_up_action( val   = client->cs_event-store_data
                              t_arg = VALUE #( ( z2ui5_cl_cgui_variant=>storage_json( prefix = cv_cgui_variant_prefix
                                                                                      key    = variant_key( )
                                                                                      val    = mv_cgui_variants ) ) ) ).

  ENDMETHOD.

  METHOD variant_key.

    result = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).

  ENDMETHOD.

  METHOD variant_from_url.

    result = url_param( `VARIANT` ).

  ENDMETHOD.

  METHOD set_variant.

    DATA lv_name TYPE string.

    lv_name = name.
    mv_cgui_variant_url = abap_false.
    IF mv_cgui_variants IS INITIAL OR variant_apply( lv_name ) = abap_false.
      mv_cgui_variant_start = lv_name.
    ENDIF.

  ENDMETHOD.

  METHOD set_variant_store.

    mo_cgui_store = store.
    mv_cgui_store_none = xsdbool( store IS NOT BOUND ).

  ENDMETHOD.

  METHOD set_layout_store.

    mo_cgui_lay_store = store.
    mv_cgui_lay_none = xsdbool( store IS NOT BOUND ).

  ENDMETHOD.

  METHOD layout_store.

    IF mo_cgui_lay_store IS NOT BOUND AND mv_cgui_lay_none = abap_false.
      mo_cgui_lay_store = z2ui5_cl_cgui_layout_db=>factory( ).
    ENDIF.
    result = mo_cgui_lay_store.

  ENDMETHOD.

  METHOD layout_handle.

    result = COND #( WHEN mv_cgui_alv_name IS NOT INITIAL THEN to_upper( mv_cgui_alv_name ) ELSE `ALV` ).

  ENDMETHOD.

  METHOD layout_store_change.

    TRY.
        IF delete = abap_true.
          layout_store( )->delete( report = variant_key( )
                                   handle = layout_handle( )
                                   name   = layout-name ).
        ELSE.
          layout_store( )->save( report = variant_key( )
                                 handle = layout_handle( )
                                 layout = layout ).
        ENDIF.
        result = abap_true.
      CATCH z2ui5_cx_cgui_error INTO DATA(lx_error).
        message( text = lx_error->get_text( )
                 type = `E` ).
    ENDTRY.

  ENDMETHOD.

  METHOD on_execute.

    IF run( ) = abap_true.
      mv_cgui_screen = cs_screen-output.
    ELSEIF mv_cgui_skipped = abap_true.
      " a run without selection screen that stopped shows the screen
      mv_cgui_skipped = abap_false.
    ENDIF.

  ENDMETHOD.

  METHOD check_screen.

    " the checks of the selection screen after Execute: required fields,
    " AT SELECTION-SCREEN ON field, AT SELECTION-SCREEN
    mv_cgui_stop = abap_false.

    IF authority_check( ) = abap_false.
      message( text = 'You are not authorized to run this report'(001)
               type = `E` ).
      RETURN.
    ENDIF.

    IF check_obligatory( ) = abap_false.
      RETURN.
    ENDIF.

    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE shown = abap_true.
      mv_cgui_on_field = lr_field->name.
      at_selection_screen_on( lr_field->name ).
      CLEAR mv_cgui_on_field.
      IF mv_cgui_stop = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

    IF check_values( ) = abap_false.
      RETURN.
    ENDIF.

    at_selection_screen( ).
    result = xsdbool( mv_cgui_stop = abap_false ).

  ENDMETHOD.

  METHOD run.

    CLEAR mt_cgui_run_msg.
    IF check_screen( ) = abap_false.
      RETURN.
    ENDIF.

    memory_id_store( ).

    CLEAR: mo_cgui_list, mo_cgui_alv, mr_cgui_alv, mr_cgui_alv_box, mv_cgui_alv_name, mt_cgui_level,
           mr_cgui_alv_page, mt_cgui_alv_index, mo_cgui_tree, mt_cgui_tree_view,
           mv_cgui_window, mv_cgui_window_title, mv_cgui_window_cols, mv_cgui_window_lines.
    start_of_selection( ).
    IF mv_cgui_stop = abap_true.
      RETURN.
    ENDIF.
    end_of_selection( ).
    IF mv_cgui_stop = abap_true.
      RETURN.
    ENDIF.
    IF mo_cgui_list IS BOUND.
      mo_cgui_list->footer_begin( ).
      end_of_page( ).
      mo_cgui_list->footer_end( ).
    ENDIF.

    IF mo_cgui_alv IS NOT BOUND AND mo_cgui_tree IS NOT BOUND
        AND ( mo_cgui_list IS NOT BOUND OR mo_cgui_list->has_content( ) = abap_false ).
      message( 'List contains no data'(020) ).
      RETURN.
    ENDIF.

    result = abap_true.

  ENDMETHOD.

  METHOD cgui_run_in_background.

    FIELD-SYMBOLS <src> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    CLEAR: list, alv, alv_data, messages.
    mv_cgui_batch = abap_true.
    mv_cgui_screen = cs_screen-selection.
    mv_cgui_title = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).

    initialization( ).
    z2ui5_cl_cgui_variant=>values_set( app    = me
                                       values = values ).
    mt_cgui_field = screen_fields( ).
    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field).
      lr_field->shown = xsdbool( lr_field->no_display = abap_false ).
    ENDLOOP.

    DATA(lv_ok) = run( ).

    LOOP AT mt_cgui_run_msg REFERENCE INTO DATA(lr_msg).
      INSERT VALUE #( type = lr_msg->type
                      text = lr_msg->text ) INTO TABLE messages.
    ENDLOOP.
    IF lv_ok = abap_false.
      RETURN.
    ENDIF.

    " the tree as text in front of the list - the spool has no hierarchy
    IF mo_cgui_tree IS BOUND.
      " nobody opens a node in the background: the lazy ones are loaded
      " here, level by level - at most 50 levels deep
      DO 50 TIMES.
        DATA(lt_lazy) = mo_cgui_tree->get_lazy_nodes( ).
        IF lt_lazy IS INITIAL.
          EXIT.
        ENDIF.
        LOOP AT lt_lazy INTO DATA(lv_lazy).
          mo_cgui_tree->set_loaded( lv_lazy ).
          at_tree_expand_no_children( lv_lazy ).
        ENDLOOP.
      ENDDO.
      mo_cgui_tree->expand_all( ).
      DATA(lo_tree_list) = z2ui5_cl_cgui_list=>factory( ).
      LOOP AT mo_cgui_tree->to_text( ) INTO DATA(lv_tree_line).
        lo_tree_list->write( lv_tree_line )->new_line( ).
      ENDLOOP.
      IF mo_cgui_list IS BOUND.
        LOOP AT mo_cgui_list->to_text( ) INTO DATA(lv_list_line).
          lo_tree_list->write( lv_list_line )->new_line( ).
        ENDLOOP.
      ENDIF.
      mo_cgui_list = lo_tree_list.
    ENDIF.
    list = mo_cgui_list.
    alv = mo_cgui_alv.
    DATA(lr_src) = alv_source( ).
    IF alv IS BOUND AND lr_src IS BOUND.
      ASSIGN lr_src->* TO <src>.
      CREATE DATA alv_data LIKE <src>.
      ASSIGN alv_data->* TO <tab>.
      <tab> = <src>.
    ENDIF.

  ENDMETHOD.

  METHOD check_values.

    FIELD-SYMBOLS <field_val> TYPE any.
    DATA lt_done TYPE string_table.

    result = abap_true.

    " VALUE CHECK - one message per field with a value that is not allowed
    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE value_check = abap_true AND shown = abap_true.
      DATA(lr_val) = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF z2ui5_cl_cgui_context=>value_check( <field_val> ) = abap_false.
        message( text  = replace( val  = 'Enter an allowed value for &1'(035)
                                  sub  = `&1`
                                  with = lr_field->text )
                 type  = `E`
                 field = lr_field->name ).
        result = abap_false.
      ENDIF.
    ENDLOOP.
    IF result = abap_false.
      RETURN.
    ENDIF.

    " ON BLOCK - a message belongs to the first field of the block
    LOOP AT mt_cgui_field REFERENCE INTO lr_field WHERE block IS NOT INITIAL AND shown = abap_true.
      IF line_exists( lt_done[ table_line = lr_field->block ] ).
        CONTINUE.
      ENDIF.
      INSERT lr_field->block INTO TABLE lt_done.
      mv_cgui_on_field = lr_field->name.
      at_selection_screen_on_block( lr_field->block ).
      CLEAR mv_cgui_on_field.
      IF mv_cgui_stop = abap_true.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.

    " ON RADIOBUTTON GROUP - a message belongs to the first button
    CLEAR lt_done.
    LOOP AT mt_cgui_field REFERENCE INTO lr_field WHERE group IS NOT INITIAL AND shown = abap_true.
      IF line_exists( lt_done[ table_line = lr_field->group ] ).
        CONTINUE.
      ENDIF.
      INSERT lr_field->group INTO TABLE lt_done.
      mv_cgui_on_field = lr_field->name.
      at_selection_screen_on_radio( lr_field->group ).
      CLEAR mv_cgui_on_field.
      IF mv_cgui_stop = abap_true.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD check_obligatory.

    " one message per empty required field, each at its field
    FIELD-SYMBOLS <field_val> TYPE any.

    result = abap_true.
    LOOP AT mt_cgui_field REFERENCE INTO DATA(lr_field) WHERE obligatory = abap_true.
      DATA(lr_val) = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      message( text  = replace( val  = 'Fill in the required field &1'(023)
                                sub  = `&1`
                                with = lr_field->text )
               type  = `E`
               field = lr_field->name ).
      result = abap_false.
    ENDLOOP.

  ENDMETHOD.

  METHOD on_range_popup.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.

    DATA(lr_range) = attri_assign( field ).
    IF lr_range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_range->* TO <range>.

    mv_cgui_range_field = field.
    range_popup_open( z2ui5_cl_cgui_range=>rows_from_range( range   = <range>
                                                             control = range_setting( field )-control ) ).

  ENDMETHOD.

  METHOD range_popup_open.

    mv_cgui_pending_field = mv_cgui_range_field.
    mv_cgui_pending_kind = cs_pending-range.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_range=>factory( rows    = rows
                                                         setting = range_setting( mv_cgui_range_field )
                                                         error   = error ) ).

  ENDMETHOD.

  METHOD range_setting.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <low>   TYPE any.
    DATA lr_line TYPE REF TO data.

    result-control = z2ui5_cl_cgui_range=>cs_control-input.
    READ TABLE mt_cgui_field REFERENCE INTO DATA(lr_field) WITH KEY name = field.
    IF sy-subrc = 0.
      result-title        = lr_field->text.
      result-value_help   = lr_field->value_help.
      result-upper        = lr_field->upper.
      result-no_intervals = lr_field->no_intervals.
      result-max_length   = lr_field->max_length.
    ENDIF.

    " a date or a time gets its picker, as on the selection screen
    DATA(lr_range) = attri_assign( field ).
    IF lr_range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_range->* TO <range>.
    CREATE DATA lr_line LIKE LINE OF <range>.
    ASSIGN lr_line->* TO <line>.
    ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CASE z2ui5_cl_cgui_context=>rtti_get_type_kind( <low> ).
      WHEN cl_abap_typedescr=>typekind_date.
        result-control = z2ui5_cl_cgui_range=>cs_control-date.
      WHEN cl_abap_typedescr=>typekind_time.
        result-control = z2ui5_cl_cgui_range=>cs_control-time.
    ENDCASE.

  ENDMETHOD.

  METHOD on_range_result.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    DATA(ls_result) = lo_popup->result( ).
    mv_cgui_range_field = field.

    IF ls_result-f4 = abap_true.
      mt_cgui_range_row  = ls_result-rows.
      mv_cgui_range_key  = ls_result-f4_key.
      mv_cgui_range_part = ls_result-f4_part.
      range_value_request( ).
      RETURN.
    ENDIF.

    IF ls_result-confirmed = abap_false.
      RETURN.
    ENDIF.

    DATA(lr_range) = attri_assign( field ).
    IF lr_range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_range->* TO <range>.

    DATA lr_before TYPE REF TO data.
    FIELD-SYMBOLS <before> TYPE STANDARD TABLE.
    CREATE DATA lr_before LIKE <range>.
    ASSIGN lr_before->* TO <before>.
    <before> = <range>.

    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = ls_result-rows
                                                  upper = range_setting( field )-upper
                                        IMPORTING error = DATA(lv_error)
                                        CHANGING  range = <range> ).
    IF lv_error IS NOT INITIAL.
      " the user stays in the popup with what was entered
      range_popup_open( rows  = ls_result-rows
                        error = lv_error ).
      RETURN.
    ENDIF.

    " AT SELECTION-SCREEN ON END OF - an error opens the popup again
    mv_cgui_stop = abap_false.
    mv_cgui_on_field = field.
    at_selection_screen_on_end_of( field ).
    CLEAR mv_cgui_on_field.
    IF mv_cgui_stop = abap_true.
      mv_cgui_stop = abap_false.
      <range> = <before>.
      LOOP AT mt_cgui_msg INTO DATA(ls_msg) WHERE type = `E` OR type = `A`.
        lv_error = ls_msg-text.
      ENDLOOP.
      range_popup_open( rows  = ls_result-rows
                        error = lv_error ).
    ENDIF.

  ENDMETHOD.

  METHOD range_value_request.

    FIELD-SYMBOLS <range>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <before> TYPE STANDARD TABLE.
    DATA lr_before TYPE REF TO data.

    DATA(lr_range) = attri_assign( mv_cgui_range_field ).
    IF lr_range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_range->* TO <range>.
    CREATE DATA lr_before LIKE <range>.
    ASSIGN lr_before->* TO <before>.
    <before> = <range>.

    mv_cgui_range_f4 = abap_true.
    mv_cgui_value_field = mv_cgui_range_field.
    at_value_request( mv_cgui_range_field ).
    CLEAR mv_cgui_value_field.
    IF mv_cgui_nav = abap_true.
      " the value help is open - on_f4_result( ) goes on when it is back
      RETURN.
    ENDIF.
    mv_cgui_range_f4 = abap_false.

    " an at_value_request( ) that set the select-option itself: its new
    " lines become lines of the popup, the select-option stays as it was
    IF <range> <> <before>.
      DATA(lt_old) = z2ui5_cl_cgui_range=>rows_from_range( <before> ).
      LOOP AT z2ui5_cl_cgui_range=>rows_from_range( <range> ) INTO DATA(ls_row).
        IF NOT line_exists( lt_old[ sign   = ls_row-sign
                                    option = ls_row-option
                                    low    = ls_row-low
                                    high   = ls_row-high ] ).
          INSERT ls_row INTO TABLE mt_cgui_range_row.
        ENDIF.
      ENDLOOP.
      <range> = <before>.
    ENDIF.

    range_popup_open( mt_cgui_range_row ).

  ENDMETHOD.

  METHOD range_f4_values.

    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <rows>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <value> TYPE any.
    DATA lt_value TYPE string_table.

    DATA(ls_result) = popup->result( ).

    IF mv_cgui_range_key IS NOT INITIAL.
      IF ls_result-row IS NOT BOUND.
        RETURN.
      ENDIF.
      ASSIGN ls_result-row->* TO <row>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF <value> IS ASSIGNED.
        z2ui5_cl_cgui_range=>row_set_value( EXPORTING row_key = mv_cgui_range_key
                                                      part    = mv_cgui_range_part
                                                      value   = |{ <value> }|
                                            CHANGING  rows    = mt_cgui_range_row ).
      ENDIF.
      RETURN.
    ENDIF.

    IF ls_result-table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ls_result-table->* TO <rows>.
    LOOP AT <rows> ASSIGNING <row>.
      UNASSIGN <value>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF <value> IS ASSIGNED.
        INSERT |{ <value> }| INTO TABLE lt_value.
      ENDIF.
    ENDLOOP.
    z2ui5_cl_cgui_range=>rows_add_values( EXPORTING values = lt_value
                                          CHANGING  rows   = mt_cgui_range_row ).

  ENDMETHOD.

  METHOD on_f4_result.

    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <rows>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <field> TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <comp>  TYPE any.
    FIELD-SYMBOLS <keep>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <sign>  TYPE any.
    FIELD-SYMBOLS <opt>   TYPE any.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA lr_line  TYPE REF TO data.
    DATA lr_keep  TYPE REF TO data.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        CLEAR lo_popup.
    ENDTRY.

    " F4 of the multiple selection - back into the popup, picked or not
    IF mv_cgui_range_f4 = abap_true.
      mv_cgui_range_f4 = abap_false.
      IF lo_popup IS BOUND AND lo_popup->result( )-confirmed = abap_true.
        range_f4_values( popup = lo_popup
                         col   = col ).
      ENDIF.
      range_popup_open( mt_cgui_range_row ).
      RETURN.
    ENDIF.

    IF lo_popup IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(ls_result) = lo_popup->result( ).
    IF ls_result-confirmed = abap_false.
      RETURN.
    ENDIF.

    DATA(lr_field) = attri_assign( field ).
    IF lr_field IS NOT BOUND.
      RETURN.
    ENDIF.

    IF cl_abap_typedescr=>describe_by_data_ref( lr_field )->kind <> cl_abap_typedescr=>kind_table.
      IF ls_result-row IS NOT BOUND.
        RETURN.
      ENDIF.
      ASSIGN ls_result-row->* TO <row>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF <value> IS NOT ASSIGNED.
        RETURN.
      ENDIF.
      ASSIGN lr_field->* TO <field>.
      <field> = <value>.
      RETURN.
    ENDIF.

    " the upper limit: the first line becomes an interval up to the value
    IF mv_cgui_pending_part = z2ui5_cl_cgui_selscreen=>cs_part-high.
      CLEAR mv_cgui_pending_part.
      IF ls_result-row IS NOT BOUND.
        RETURN.
      ENDIF.
      ASSIGN ls_result-row->* TO <row>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF <value> IS NOT ASSIGNED.
        RETURN.
      ENDIF.
      ASSIGN lr_field->* TO <range>.
      READ TABLE <range> ASSIGNING <line> INDEX 1.
      IF sy-subrc <> 0.
        CREATE DATA lr_line LIKE LINE OF <range>.
        ASSIGN lr_line->* TO <line>.
        ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
        <comp> = `I`.
        INSERT <line> INTO TABLE <range> ASSIGNING <line>.
      ENDIF.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
      <comp> = `BT`.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
      <comp> = <value>.
      RETURN.
    ENDIF.

    " a select-option - every row picked becomes a line I EQ. The value
    " help showed the lines I EQ as picked, so only they are replaced:
    " intervals, patterns and excluding lines stay
    IF ls_result-table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ls_result-table->* TO <rows>.
    ASSIGN lr_field->* TO <range>.
    CREATE DATA lr_keep LIKE <range>.
    ASSIGN lr_keep->* TO <keep>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <keep>.
    LOOP AT <range> ASSIGNING <line>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <sign>.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <opt>.
      IF <sign> IS ASSIGNED AND <opt> IS ASSIGNED AND <sign> = `I` AND <opt> = `EQ`.
        CONTINUE.
      ENDIF.
      INSERT <line> INTO TABLE <keep>.
    ENDLOOP.
    <range> = <keep>.

    LOOP AT <rows> ASSIGNING <row>.
      UNASSIGN <value>.
      IF col IS INITIAL.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
      ELSE.
        ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
      ENDIF.
      IF <value> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      CREATE DATA lr_line LIKE LINE OF <range>.
      ASSIGN lr_line->* TO <line>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
      <comp> = `I`.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
      <comp> = `EQ`.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
      <comp> = <value>.
      INSERT <line> INTO TABLE <range>.
    ENDLOOP.

  ENDMETHOD.

  METHOD attri_assign.

    DATA lo_me TYPE REF TO object.
    FIELD-SYMBOLS <attri> TYPE any.

    lo_me = me.
    ASSIGN lo_me->(name) TO <attri>.
    IF <attri> IS ASSIGNED.
      GET REFERENCE OF <attri> INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD write.

    " only what is passed goes on - the list takes FORMAT for the rest
    DATA lt_param TYPE abap_parmbind_tab.

    INSERT VALUE #( name  = `VAL`
                    kind  = cl_abap_objectdescr=>exporting
                    value = REF #( val ) ) INTO TABLE lt_param.
    IF hide IS SUPPLIED.
      INSERT VALUE #( name = `HIDE` kind = cl_abap_objectdescr=>exporting value = REF #( hide ) ) INTO TABLE lt_param.
    ENDIF.
    IF color IS SUPPLIED.
      INSERT VALUE #( name = `COLOR` kind = cl_abap_objectdescr=>exporting value = REF #( color ) ) INTO TABLE lt_param.
    ENDIF.
    IF hotspot IS SUPPLIED.
      INSERT VALUE #( name = `HOTSPOT` kind = cl_abap_objectdescr=>exporting value = REF #( hotspot ) ) INTO TABLE lt_param.
    ENDIF.
    IF pos IS SUPPLIED.
      INSERT VALUE #( name = `POS` kind = cl_abap_objectdescr=>exporting value = REF #( pos ) ) INTO TABLE lt_param.
    ENDIF.
    IF len IS SUPPLIED.
      INSERT VALUE #( name = `LEN` kind = cl_abap_objectdescr=>exporting value = REF #( len ) ) INTO TABLE lt_param.
    ENDIF.
    IF intensified IS SUPPLIED.
      INSERT VALUE #( name = `INTENSIFIED` kind = cl_abap_objectdescr=>exporting value = REF #( intensified ) ) INTO TABLE lt_param.
    ENDIF.
    IF inverse IS SUPPLIED.
      INSERT VALUE #( name = `INVERSE` kind = cl_abap_objectdescr=>exporting value = REF #( inverse ) ) INTO TABLE lt_param.
    ENDIF.
    IF input IS SUPPLIED.
      INSERT VALUE #( name = `INPUT` kind = cl_abap_objectdescr=>exporting value = REF #( input ) ) INTO TABLE lt_param.
    ENDIF.
    IF no_zero IS SUPPLIED.
      INSERT VALUE #( name = `NO_ZERO` kind = cl_abap_objectdescr=>exporting value = REF #( no_zero ) ) INTO TABLE lt_param.
    ENDIF.
    IF no_sign IS SUPPLIED.
      INSERT VALUE #( name = `NO_SIGN` kind = cl_abap_objectdescr=>exporting value = REF #( no_sign ) ) INTO TABLE lt_param.
    ENDIF.
    IF currency IS SUPPLIED.
      INSERT VALUE #( name = `CURRENCY` kind = cl_abap_objectdescr=>exporting value = REF #( currency ) ) INTO TABLE lt_param.
    ENDIF.
    IF unit IS SUPPLIED.
      INSERT VALUE #( name = `UNIT` kind = cl_abap_objectdescr=>exporting value = REF #( unit ) ) INTO TABLE lt_param.
    ENDIF.
    IF decimals IS SUPPLIED.
      INSERT VALUE #( name = `DECIMALS` kind = cl_abap_objectdescr=>exporting value = REF #( decimals ) ) INTO TABLE lt_param.
    ENDIF.
    IF justify IS SUPPLIED.
      INSERT VALUE #( name = `JUSTIFY` kind = cl_abap_objectdescr=>exporting value = REF #( justify ) ) INTO TABLE lt_param.
    ENDIF.
    IF no_gap IS SUPPLIED.
      INSERT VALUE #( name = `NO_GAP` kind = cl_abap_objectdescr=>exporting value = REF #( no_gap ) ) INTO TABLE lt_param.
    ENDIF.
    IF edit_mask IS SUPPLIED.
      INSERT VALUE #( name = `EDIT_MASK` kind = cl_abap_objectdescr=>exporting value = REF #( edit_mask ) ) INTO TABLE lt_param.
    ENDIF.
    IF no_grouping IS SUPPLIED.
      INSERT VALUE #( name = `NO_GROUPING` kind = cl_abap_objectdescr=>exporting value = REF #( no_grouping ) ) INTO TABLE lt_param.
    ENDIF.
    IF round IS SUPPLIED.
      INSERT VALUE #( name = `ROUND` kind = cl_abap_objectdescr=>exporting value = REF #( round ) ) INTO TABLE lt_param.
    ENDIF.
    IF date_format IS SUPPLIED.
      INSERT VALUE #( name = `DATE_FORMAT` kind = cl_abap_objectdescr=>exporting value = REF #( date_format ) ) INTO TABLE lt_param.
    ENDIF.
    IF time_zone IS SUPPLIED.
      INSERT VALUE #( name = `TIME_ZONE` kind = cl_abap_objectdescr=>exporting value = REF #( time_zone ) ) INTO TABLE lt_param.
    ENDIF.
    IF quickinfo IS SUPPLIED.
      INSERT VALUE #( name = `QUICKINFO` kind = cl_abap_objectdescr=>exporting value = REF #( quickinfo ) ) INTO TABLE lt_param.
    ENDIF.
    IF name IS SUPPLIED.
      INSERT VALUE #( name = `NAME` kind = cl_abap_objectdescr=>exporting value = REF #( name ) ) INTO TABLE lt_param.
    ENDIF.
    IF under IS SUPPLIED.
      INSERT VALUE #( name = `UNDER` kind = cl_abap_objectdescr=>exporting value = REF #( under ) ) INTO TABLE lt_param.
    ENDIF.
    INSERT VALUE #( name  = `RESULT`
                    kind  = cl_abap_objectdescr=>receiving
                    value = REF #( result ) ) INTO TABLE lt_param.

    DATA(lo_list) = list( ).
    CALL METHOD lo_list->(`WRITE`)
      PARAMETER-TABLE lt_param.

  ENDMETHOD.

  METHOD format.

    DATA lt_param TYPE abap_parmbind_tab.

    IF color IS SUPPLIED.
      INSERT VALUE #( name = `COLOR` kind = cl_abap_objectdescr=>exporting value = REF #( color ) ) INTO TABLE lt_param.
    ENDIF.
    IF intensified IS SUPPLIED.
      INSERT VALUE #( name = `INTENSIFIED` kind = cl_abap_objectdescr=>exporting value = REF #( intensified ) ) INTO TABLE lt_param.
    ENDIF.
    IF inverse IS SUPPLIED.
      INSERT VALUE #( name = `INVERSE` kind = cl_abap_objectdescr=>exporting value = REF #( inverse ) ) INTO TABLE lt_param.
    ENDIF.
    IF hotspot IS SUPPLIED.
      INSERT VALUE #( name = `HOTSPOT` kind = cl_abap_objectdescr=>exporting value = REF #( hotspot ) ) INTO TABLE lt_param.
    ENDIF.
    IF input IS SUPPLIED.
      INSERT VALUE #( name = `INPUT` kind = cl_abap_objectdescr=>exporting value = REF #( input ) ) INTO TABLE lt_param.
    ENDIF.
    INSERT VALUE #( name = `RESET` kind = cl_abap_objectdescr=>exporting value = REF #( reset ) ) INTO TABLE lt_param.
    INSERT VALUE #( name  = `RESULT`
                    kind  = cl_abap_objectdescr=>receiving
                    value = REF #( result ) ) INTO TABLE lt_param.

    DATA(lo_list) = list( ).
    CALL METHOD lo_list->(`FORMAT`)
      PARAMETER-TABLE lt_param.

  ENDMETHOD.

  METHOD get_cursor.

    result = ms_cgui_cursor.

  ENDMETHOD.

  METHOD lisel.

    result = mv_cgui_lisel.

  ENDMETHOD.

  METHOD cursor_from_list.

    CLEAR: ms_cgui_cursor, mv_cgui_lisel.
    IF mo_cgui_list IS NOT BOUND.
      RETURN.
    ENDIF.
    mv_cgui_lisel = mo_cgui_list->line_text( line ).
    DATA(ls_item) = mo_cgui_list->get_item_by_id( id ).
    ms_cgui_cursor = VALUE #( field  = ls_item-name
                              value  = ls_item-text
                              line   = line
                              offset = COND #( WHEN ls_item-col > 0 THEN ls_item-col - 1 ) ).

  ENDMETHOD.

  METHOD set_cursor_field.

    mv_cgui_cursor_field = to_upper( name ).

  ENDMETHOD.

  METHOD set_selscreen_status.

    mt_cgui_excl_sel = excluding.

  ENDMETHOD.

  METHOD matchcode_field.

    DATA lv_shlp  TYPE c LENGTH 30.
    DATA lv_field TYPE c LENGTH 30.

    " DD32S is named as a string - not released on ABAP Cloud, there the
    " select raises and the field keeps its other F4
    lv_shlp = name.
    TRY.
        DATA(lv_table) = `DD32S`.
        SELECT fieldname FROM (lv_table)
          WHERE shlpname = @lv_shlp AND as4local = 'A' AND shlpoutput = 'X'
          ORDER BY flposition
          INTO @lv_field
          UP TO 1 ROWS.
        ENDSELECT.
        result = lv_field.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD list.

    " a new list starts with its page header - TOP-OF-PAGE
    IF mo_cgui_list IS NOT BOUND.
      mo_cgui_list = z2ui5_cl_cgui_list=>factory( ).
      mo_cgui_list->set_line_count( mv_cgui_line_count ).
      mo_cgui_list->header_begin( ).
      IF lsind( ) = 0.
        top_of_page( ).
      ELSE.
        top_of_page_line_selection( ).
      ENDIF.
      mo_cgui_list->header_end( ).
    ENDIF.
    result = mo_cgui_list.

  ENDMETHOD.

  METHOD alv.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    CLEAR: mr_cgui_alv, mr_cgui_alv_box, mr_cgui_alv_page, mt_cgui_alv_index.
    mv_cgui_alv_name = z2ui5_cl_cgui_context=>attri_name_by_ref( app = me
                                                                 val = tab ).
    IF mv_cgui_alv_name IS INITIAL.
      CREATE DATA mr_cgui_alv LIKE tab.
      ASSIGN mr_cgui_alv->* TO <tab>.
      <tab> = tab.
    ENDIF.

    mo_cgui_alv = z2ui5_cl_cgui_alv=>factory( )->set_title( mv_cgui_title ).
    CLEAR mv_cgui_layout_done.
    result = mo_cgui_alv.

  ENDMETHOD.

  METHOD tree.

    mo_cgui_tree = z2ui5_cl_cgui_tree=>factory( )->set_title( mv_cgui_title ).
    CLEAR mt_cgui_tree_view.
    result = mo_cgui_tree.

  ENDMETHOD.

  METHOD at_tree_node ##NEEDED.
  ENDMETHOD.

  METHOD at_tree_checkbox ##NEEDED.
  ENDMETHOD.

  METHOD at_tree_expand_no_children ##NEEDED.
  ENDMETHOD.

  METHOD on_tree_node.

    IF key IS INITIAL.
      RETURN.
    ENDIF.
    " the tree stays as it is - what the event block shows is a new level
    DATA(lo_tree) = mo_cgui_tree.
    DATA(ls_node) = lo_tree->get_node( key ).
    level_push( ).
    at_tree_node( key   = key
                  value = ls_node-value ).
    IF mv_cgui_screen <> cs_screen-output.
      CLEAR mt_cgui_level.
      RETURN.
    ENDIF.
    IF mo_cgui_alv IS NOT BOUND AND mo_cgui_tree IS NOT BOUND
        AND ( mo_cgui_list IS NOT BOUND OR mo_cgui_list->has_content( ) = abap_false ).
      level_pop( ).
    ENDIF.

  ENDMETHOD.

  METHOD alv_source.

    IF mv_cgui_alv_name IS NOT INITIAL.
      result = attri_assign( mv_cgui_alv_name ).
    ELSE.
      result = mr_cgui_alv.
    ENDIF.

  ENDMETHOD.

  METHOD alv_shown.

    FIELD-SYMBOLS <src> TYPE STANDARD TABLE.

    result = alv_source( ).
    IF result IS NOT BOUND OR mo_cgui_alv IS NOT BOUND
        OR mo_cgui_alv->has_selection( ) = abap_false.
      RETURN.
    ENDIF.
    ASSIGN result->* TO <src>.
    IF mo_cgui_alv->has_box_field( <src> ) = abap_true.
      RETURN.
    ENDIF.
    IF mr_cgui_alv_box IS NOT BOUND.
      alv_box_refresh( result ).
    ENDIF.
    result = mr_cgui_alv_box.

  ENDMETHOD.

  METHOD alv_box_refresh.

    " a copy of the table with the box field - the selection is kept as
    " long as the table keeps its number of rows
    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA lv_flag TYPE abap_bool.
    DATA lr_row  TYPE REF TO data.
    DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    FIELD-SYMBOLS <src> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <old> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <box> TYPE any.

    ASSIGN source->* TO <src>.
    IF mr_cgui_alv_box IS BOUND.
      ASSIGN mr_cgui_alv_box->* TO <old>.
      IF lines( <old> ) = lines( <src> ).
        lt_selected = mo_cgui_alv->get_selected_rows( <old> ).
      ENDIF.
    ENDIF.

    DATA(lo_line) = CAST cl_abap_structdescr( CAST cl_abap_tabledescr(
        cl_abap_typedescr=>describe_by_data( <src> ) )->get_table_line_type( ) ).
    lt_comp = lo_line->get_components( ).
    INSERT VALUE #( name = z2ui5_cl_cgui_alv=>cv_box_field
                    type = CAST #( cl_abap_typedescr=>describe_by_data( lv_flag ) ) ) INTO TABLE lt_comp.
    DATA(lo_tab) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
    CREATE DATA mr_cgui_alv_box TYPE HANDLE lo_tab.
    ASSIGN mr_cgui_alv_box->* TO <tab>.

    LOOP AT <src> ASSIGNING FIELD-SYMBOL(<line>).
      DATA(lv_index) = sy-tabix.
      CREATE DATA lr_row LIKE LINE OF <tab>.
      ASSIGN lr_row->* TO <row>.
      MOVE-CORRESPONDING <line> TO <row>.
      IF line_exists( lt_selected[ table_line = lv_index ] ).
        ASSIGN COMPONENT z2ui5_cl_cgui_alv=>cv_box_field OF STRUCTURE <row> TO <box>.
        <box> = abap_true.
      ENDIF.
      INSERT <row> INTO TABLE <tab>.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_selected_rows.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    IF mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    result = mo_cgui_alv->get_selected_rows( <tab> ).

  ENDMETHOD.

  METHOD message.

    DATA lv_field TYPE string.

    lv_field = to_upper( field ).
    IF lv_field IS INITIAL.
      lv_field = mv_cgui_on_field.
    ENDIF.

    DATA(ls_msg) = VALUE ty_s_cgui_msg( type  = to_upper( type )
                                        text  = text
                                        field = lv_field ).
    INSERT ls_msg INTO TABLE mt_cgui_msg.
    INSERT ls_msg INTO TABLE mt_cgui_run_msg.
    IF ls_msg-type <> `S`.
      INSERT ls_msg INTO TABLE mt_cgui_log.
    ENDIF.
    IF ls_msg-type = `E` OR ls_msg-type = `A`.
      mv_cgui_stop = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD message_t100.

    DATA lv_id     TYPE c LENGTH 20.
    DATA lv_number TYPE n LENGTH 3.
    DATA lv_v1     TYPE c LENGTH 50.
    DATA lv_v2     TYPE c LENGTH 50.
    DATA lv_v3     TYPE c LENGTH 50.
    DATA lv_v4     TYPE c LENGTH 50.
    DATA lv_text   TYPE string.

    lv_id = to_upper( id ).
    lv_number = number.
    lv_v1 = v1.
    lv_v2 = v2.
    lv_v3 = v3.
    lv_v4 = v4.
    MESSAGE ID lv_id TYPE 'S' NUMBER lv_number WITH lv_v1 lv_v2 lv_v3 lv_v4 INTO lv_text.

    message( text  = lv_text
             type  = type
             field = field ).

  ENDMETHOD.

  METHOD messages_from_bapiret.

    FIELD-SYMBOLS <ret>  TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.

    LOOP AT tab ASSIGNING <ret>.
      ASSIGN COMPONENT `MESSAGE` OF STRUCTURE <ret> TO <comp>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(lv_text) = CONV string( <comp> ).
      ASSIGN COMPONENT `TYPE` OF STRUCTURE <ret> TO <comp>.
      DATA(lv_type) = COND string( WHEN sy-subrc = 0 AND <comp> IS NOT INITIAL THEN <comp> ELSE `I` ).
      ASSIGN COMPONENT `FIELD` OF STRUCTURE <ret> TO <comp>.
      DATA(lv_field) = COND string( WHEN sy-subrc = 0 THEN <comp> ).
      IF lv_field IS NOT INITIAL AND NOT line_exists( mt_cgui_field[ name = to_upper( lv_field ) ] ).
        CLEAR lv_field.
      ENDIF.
      message( text  = lv_text
               type  = lv_type
               field = lv_field ).
    ENDLOOP.

  ENDMETHOD.

  METHOD popup_to_confirm.

    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>confirm( question     = question
                                                        title        = title
                                                        event        = ucomm
                                                        event_cancel = cs_ucomm-cancel ) ).

  ENDMETHOD.

  METHOD popup_to_decide.

    CLEAR mv_cgui_answer.
    mv_cgui_pending_kind = cs_pending-decide.
    mv_cgui_pending_ucomm = ucomm.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>decide( question = question
                                                       options  = options
                                                       title    = title
                                                       event    = ucomm ) ).

  ENDMETHOD.

  METHOD popup_get_values.

    CLEAR mt_cgui_popup_values.
    mv_cgui_pending_kind = cs_pending-values.
    mv_cgui_pending_ucomm = ucomm.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>get_values( fields  = fields
                                                           title   = title
                                                           text    = text
                                                           listbox = listbox
                                                           event   = ucomm ) ).

  ENDMETHOD.

  METHOD popup_answer.

    result = mv_cgui_answer.

  ENDMETHOD.

  METHOD popup_values.

    result = mt_cgui_popup_values.

  ENDMETHOD.

  METHOD value_help_popup.

    IF mv_cgui_value_field IS INITIAL.
      RETURN.
    ENDIF.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab>   TYPE STANDARD TABLE.
    DATA lr_tab TYPE REF TO data.

    DATA(lr_field) = value_help_target( mv_cgui_value_field ).
    IF lr_field IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lv_multi) = xsdbool( cl_abap_typedescr=>describe_by_data_ref( lr_field )->kind = cl_abap_typedescr=>kind_table ).
    " in the multiple selection: one value for a line, several for new ones
    IF mv_cgui_range_f4 = abap_true.
      lv_multi = xsdbool( mv_cgui_range_key IS INITIAL ).
    ENDIF.
    " the upper limit takes one value
    IF mv_cgui_value_part = z2ui5_cl_cgui_selscreen=>cs_part-high.
      lv_multi = abap_false.
    ENDIF.

    mv_cgui_pending_field = mv_cgui_value_field.
    mv_cgui_pending_kind = COND #( WHEN mv_cgui_alv_f4_col IS NOT INITIAL THEN cs_pending-alv_f4 ELSE cs_pending-f4 ).
    mv_cgui_pending_part = mv_cgui_value_part.
    mv_cgui_pending_col = to_upper( col ).
    mv_cgui_nav = abap_true.

    IF lv_multi = abap_true AND mv_cgui_range_f4 = abap_false.
      ASSIGN lr_field->* TO <range>.
      lr_tab = value_help_preselect( tab   = tab
                                     col   = mv_cgui_pending_col
                                     range = <range> ).
    ENDIF.
    IF lr_tab IS BOUND.
      ASSIGN lr_tab->* TO <tab>.
    ELSE.
      ASSIGN tab TO <tab>.
    ENDIF.

    client->nav_app_call( z2ui5_cl_cgui_select=>factory( tab         = <tab>
                                                         title       = title
                                                         multiselect = lv_multi ) ).

  ENDMETHOD.

  METHOD vrm_set_values.

    DATA(lv_name) = to_upper( name ).
    DELETE mt_cgui_vrm WHERE name = lv_name.
    INSERT VALUE #( name   = lv_name
                    values = values ) INTO TABLE mt_cgui_vrm.

  ENDMETHOD.

  METHOD leave_to_selection_screen.

    mv_cgui_screen = cs_screen-selection.
    CLEAR: mt_cgui_level, mv_cgui_window.

  ENDMETHOD.

  METHOD call_selection_screen.

    mv_cgui_dynnr = dynnr.
    mv_cgui_dynnr_title = title.

  ENDMETHOD.

  METHOD on_screen_ok.

    " the required fields of the popup screen, then the report decides
    FIELD-SYMBOLS <field_val> TYPE any.

    LOOP AT mt_cgui_dynnr_field REFERENCE INTO DATA(lr_field) WHERE obligatory = abap_true.
      DATA(lr_val) = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS INITIAL.
        message( text = replace( val  = 'Fill in the required field &1'(023)
                                 sub  = `&1`
                                 with = lr_field->text )
                 type = `E` ).
        RETURN.
      ENDIF.
    ENDLOOP.

    DATA(lv_dynnr) = mv_cgui_dynnr.
    CLEAR mv_cgui_dynnr.
    client->popup_destroy( ).
    after_call_selection_screen( dynnr = lv_dynnr
                                 subrc = 0 ).

  ENDMETHOD.

  METHOD submit.

    DATA lo_app TYPE REF TO z2ui5_cl_cgui_report.

    TRY.
        CREATE OBJECT lo_app TYPE (report).
      CATCH cx_sy_create_object_error cx_sy_move_cast_error.
        message( text = replace( val  = 'Report &1 cannot be started'(024)
                                 sub  = `&1`
                                 with = report )
                 type = `E` ).
        RETURN.
    ENDTRY.

    lo_app->mt_cgui_submit = values.
    lo_app->mv_cgui_called = abap_true.
    lo_app->mv_cgui_skip = xsdbool( via_selection_screen = abap_false ).
    IF using_variant IS NOT INITIAL.
      lo_app->mv_cgui_variant_start = using_variant.
    ENDIF.

    mv_cgui_nav = abap_true.
    client->nav_app_call( lo_app ).

  ENDMETHOD.

  METHOD set_title.

    mv_cgui_title = val.

  ENDMETHOD.

  METHOD shortcuts_register.

    " F8 Execute and F3 Back, as in the SAP GUI - registered with every
    " view, the frontend binds them to the controller of the view
    client->follow_up_action( val   = client->cs_event-keyboard_shortcut
                              t_arg = VALUE #( ( `F8` ) ( cs_ucomm-execute ) ( client->cs_view-main ) ) ).
    client->follow_up_action( val   = client->cs_event-keyboard_shortcut
                              t_arg = VALUE #( ( `F3` ) ( cs_ucomm-back ) ( client->cs_view-main ) ) ).

  ENDMETHOD.

  METHOD variant_attributes_apply.

    IF mt_cgui_var_protect IS INITIAL AND mt_cgui_var_hide IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lt_screen) = screen->loop_at_screen( ).
    LOOP AT lt_screen INTO DATA(ls_screen).
      IF line_exists( mt_cgui_var_hide[ table_line = ls_screen-name ] ).
        ls_screen-active = abap_false.
        screen->modify_screen( ls_screen ).
      ELSEIF line_exists( mt_cgui_var_protect[ table_line = ls_screen-name ] ).
        ls_screen-input = abap_false.
        screen->modify_screen( ls_screen ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD print_lines.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    INSERT mv_cgui_title INTO TABLE result.
    INSERT `` INTO TABLE result.
    IF mo_cgui_alv IS BOUND.
      DATA(lr_tab) = alv_visible_source( ).
      IF lr_tab IS BOUND.
        ASSIGN lr_tab->* TO <tab>.
        INSERT LINES OF mo_cgui_alv->to_text( <tab> ) INTO TABLE result.
      ENDIF.
    ENDIF.
    IF mo_cgui_tree IS BOUND.
      INSERT LINES OF mo_cgui_tree->to_text( ) INTO TABLE result.
    ENDIF.
    IF mo_cgui_list IS BOUND.
      INSERT LINES OF mo_cgui_list->to_text( ) INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD on_print.

    " the printout as a text file for the browser to print or keep - ABAP
    " Cloud has no spool, and a spool request is no paper next to the user
    DATA(lv_text) = concat_lines_of( table = print_lines( )
                                     sep   = |\r\n| ).
    DATA(lv_file) = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( lv_text ).
    IF lv_file IS INITIAL.
      message( text = 'The output could not be printed'(037)
               type = `E` ).
      RETURN.
    ENDIF.

    client->follow_up_action( val   = client->cs_event-download_b64_file
                              t_arg = VALUE #( ( |data:text/plain;charset=utf-8;base64,| &&
                                                 z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_file ) )
                                               ( |{ mv_cgui_title }.txt| ) ) ).

  ENDMETHOD.

  METHOD layouts.

    DATA(lo_store) = layout_store( ).
    IF lo_store IS BOUND.
      result = lo_store->load( report = variant_key( )
                               handle = layout_handle( ) ).
    ELSE.
      result = z2ui5_cl_cgui_layout=>from_variants( variant_catalog( ) ).
    ENDIF.

  ENDMETHOD.

  METHOD layout_popup.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.

    mv_cgui_pending_kind = cs_pending-layout.
    mv_cgui_nav = abap_true.
    DATA(lo_store) = layout_store( ).
    client->nav_app_call( z2ui5_cl_cgui_layout=>factory( layout  = mo_cgui_alv->get_layout( <tab> )
                                                         saved   = layouts( )
                                                         current = mv_cgui_layout
                                                         sharing = xsdbool( lo_store IS BOUND
                                                                        AND lo_store->check_sharing( ) = abap_true ) ) ).

  ENDMETHOD.

  METHOD layout_result.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_layout.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(ls_result) = lo_popup->result( ).

    CASE ls_result-action.

      WHEN z2ui5_cl_cgui_layout=>cs_action-apply.
        mo_cgui_alv->set_layout( ls_result-layout ).

      WHEN z2ui5_cl_cgui_layout=>cs_action-save.
        mo_cgui_alv->set_layout( ls_result-layout ).
        DATA(lv_saved) = abap_false.
        IF layout_store( ) IS BOUND.
          " the store keeps one default layout per user
          lv_saved = layout_store_change( VALUE #( name       = ls_result-name
                                                   is_default = ls_result-is_default
                                                   layout     = ls_result-layout
                                                   shared     = ls_result-shared
                                                   protected  = ls_result-protected ) ).
        ELSE.
          " one default layout - the one saved as default takes the flag
          IF ls_result-is_default = abap_true.
            LOOP AT layouts( ) INTO DATA(ls_saved) WHERE is_default = abap_true AND name <> ls_result-name.
              variant_put( z2ui5_cl_cgui_layout=>to_variant( name   = ls_saved-name
                                                             layout = ls_saved-layout ) ).
            ENDLOOP.
          ENDIF.
          lv_saved = variant_put( z2ui5_cl_cgui_layout=>to_variant( name       = ls_result-name
                                                                    is_default = ls_result-is_default
                                                                    layout     = ls_result-layout ) ).
        ENDIF.
        IF lv_saved = abap_true.
          mv_cgui_layout = ls_result-name.
          message( replace( val  = 'Layout &1 saved'(032)
                            sub  = `&1`
                            with = ls_result-name ) ).
        ENDIF.

      WHEN z2ui5_cl_cgui_layout=>cs_action-delete.
        IF layout_store( ) IS BOUND.
          DATA(lv_deleted) = layout_store_change( layout = VALUE #( name = ls_result-name )
                                                  delete = abap_true ).
        ELSE.
          lv_deleted = variant_remove( |{ z2ui5_cl_cgui_layout=>cv_prefix }{ ls_result-name }| ).
        ENDIF.
        IF lv_deleted = abap_true.

          IF mv_cgui_layout = ls_result-name.
            CLEAR mv_cgui_layout.
          ENDIF.
          message( replace( val  = 'Layout &1 deleted'(033)
                            sub  = `&1`
                            with = ls_result-name ) ).
        ENDIF.
        layout_popup( ).

    ENDCASE.

  ENDMETHOD.

  METHOD layout_default_apply.

    mv_cgui_layout_done = abap_true.
    LOOP AT layouts( ) INTO DATA(ls_saved) WHERE is_default = abap_true.
      mo_cgui_alv->set_layout( z2ui5_cl_cgui_layout=>layout_merge( base  = mo_cgui_alv->get_layout( tab )
                                                                   saved = ls_saved-layout ) ).
      mv_cgui_layout = ls_saved-name.
      EXIT.
    ENDLOOP.

  ENDMETHOD.

  METHOD variant_put.

    IF mo_cgui_store IS BOUND.
      TRY.
          mo_cgui_store->save( report  = variant_key( )
                               variant = variant ).
        CATCH z2ui5_cx_cgui_error INTO DATA(lx_error).
          message( text = lx_error->get_text( )
                   type = `E` ).
          RETURN.
      ENDTRY.
      variant_store( mo_cgui_store->load( variant_key( ) ) ).
    ELSE.
      DATA(lt_variant) = variant_catalog( ).
      DELETE lt_variant WHERE name = variant-name.
      INSERT variant INTO TABLE lt_variant.
      SORT lt_variant BY name.
      variant_store( lt_variant ).
    ENDIF.
    result = abap_true.

  ENDMETHOD.

  METHOD variant_remove.

    IF mo_cgui_store IS BOUND.
      TRY.
          mo_cgui_store->delete( report = variant_key( )
                                 name   = name ).
        CATCH z2ui5_cx_cgui_error INTO DATA(lx_error).
          message( text = lx_error->get_text( )
                   type = `E` ).
          RETURN.
      ENDTRY.
      variant_store( mo_cgui_store->load( variant_key( ) ) ).
    ELSE.
      DATA(lt_variant) = variant_catalog( ).
      DELETE lt_variant WHERE name = name.
      variant_store( lt_variant ).
    ENDIF.
    result = abap_true.

  ENDMETHOD.

  METHOD alv_single_sync.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    IF mo_cgui_alv IS NOT BOUND
        OR mo_cgui_alv->get_selection_mode( ) <> z2ui5_cl_cgui_alv=>cs_selection_mode-single.
      RETURN.
    ENDIF.
    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS BOUND.
      ASSIGN lr_tab->* TO <tab>.
      mo_cgui_alv->single_normalize( CHANGING tab = <tab> ).
    ENDIF.

  ENDMETHOD.

  METHOD alv_row.

    result = row.
    IF mr_cgui_alv_page IS BOUND AND row > 0.
      READ TABLE mt_cgui_alv_index INTO result INDEX row.
      IF sy-subrc <> 0.
        result = row.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD alv_visible_source.

    FIELD-SYMBOLS <src>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <shown> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <copy>  TYPE STANDARD TABLE.

    result = alv_source( ).
    IF result IS NOT BOUND OR mo_cgui_alv IS NOT BOUND OR mo_cgui_alv->is_filtered( ) = abap_false.
      RETURN.
    ENDIF.
    " the copy with the box field has the rows of the table, one to one
    DATA(lr_shown) = alv_shown( ).
    ASSIGN result->* TO <src>.
    ASSIGN lr_shown->* TO <shown>.
    DATA(lt_index) = mo_cgui_alv->filter_index( <shown> ).
    DATA lr_copy TYPE REF TO data.
    CREATE DATA lr_copy LIKE <src>.
    ASSIGN lr_copy->* TO <copy>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <copy>.
    LOOP AT lt_index INTO DATA(lv_row).
      READ TABLE <src> ASSIGNING FIELD-SYMBOL(<line>) INDEX lv_row.
      IF sy-subrc = 0.
        INSERT <line> INTO TABLE <copy>.
      ENDIF.
    ENDLOOP.
    result = lr_copy.

  ENDMETHOD.

  METHOD alv_filter_popup.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lt_col TYPE ty_t_cgui_filter_col.
    DATA lt_low TYPE string_table.

    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    DATA(lt_filter) = mo_cgui_alv->get_filter( ).
    DATA(lt_layout) = mo_cgui_alv->get_layout( <tab> ).
    SORT lt_layout BY position.
    LOOP AT lt_layout INTO DATA(ls_layout).
      CLEAR lt_low.
      READ TABLE lt_filter INTO DATA(ls_filter) WITH KEY name = ls_layout-name.
      IF sy-subrc = 0.
        LOOP AT ls_filter-rows INTO DATA(ls_row).
          INSERT COND string( WHEN ls_row-sign = `E` THEN |≠{ ls_row-low }|
                              WHEN ls_row-high IS NOT INITIAL THEN |{ ls_row-low }…{ ls_row-high }|
                              ELSE ls_row-low ) INTO TABLE lt_low.
        ENDLOOP.
      ENDIF.
      INSERT VALUE #( column = ls_layout-name
                      text   = ls_layout-text
                      filter = concat_lines_of( table = lt_low sep = `, ` ) ) INTO TABLE lt_col.
    ENDLOOP.

    mv_cgui_pending_kind = cs_pending-filter_col.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_select=>factory( tab   = lt_col
                                                         title = 'Filter'(043) ) ).

  ENDMETHOD.

  METHOD alv_filter_column_result.

    FIELD-SYMBOLS <col> TYPE ty_s_cgui_filter_col.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    DATA(ls_result) = lo_popup->result( ).
    IF ls_result-confirmed = abap_false OR ls_result-row IS NOT BOUND OR mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ls_result-row->* TO <col>.
    mv_cgui_filter_col = condense( <col>-column ).
    DATA(lt_filter) = mo_cgui_alv->get_filter( ).
    READ TABLE lt_filter INTO DATA(ls_filter) WITH KEY name = mv_cgui_filter_col.
    alv_filter_open( ls_filter-rows ).

  ENDMETHOD.

  METHOD alv_filter_open.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    DATA(ls_setting) = VALUE z2ui5_cl_cgui_range=>ty_s_setting( control = z2ui5_cl_cgui_range=>cs_control-input ).
    DATA(lt_layout) = mo_cgui_alv->get_layout( <tab> ).
    READ TABLE lt_layout INTO DATA(ls_layout) WITH KEY name = mv_cgui_filter_col.
    ls_setting-title = COND #( WHEN ls_layout-text IS NOT INITIAL THEN ls_layout-text ELSE mv_cgui_filter_col ).
    DATA(lt_comp) = z2ui5_cl_cgui_context=>rtti_get_t_comp( <tab> ).
    READ TABLE lt_comp INTO DATA(ls_comp) WITH KEY name = mv_cgui_filter_col.
    CASE ls_comp-type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        ls_setting-control = z2ui5_cl_cgui_range=>cs_control-date.
      WHEN cl_abap_typedescr=>typekind_time.
        ls_setting-control = z2ui5_cl_cgui_range=>cs_control-time.
    ENDCASE.

    mv_cgui_pending_kind = cs_pending-filter.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_range=>factory( rows    = rows
                                                         setting = ls_setting
                                                         error   = error ) ).

  ENDMETHOD.

  METHOD alv_filter_result.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    DATA(ls_result) = lo_popup->result( ).
    IF ls_result-confirmed = abap_false OR mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lr_tab) = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.

    DATA(lv_error) = mo_cgui_alv->check_filter( name = mv_cgui_filter_col
                                                rows = ls_result-rows
                                                tab  = <tab> ).
    IF lv_error IS NOT INITIAL.
      " the user stays in the popup with what was entered
      alv_filter_open( rows  = ls_result-rows
                       error = lv_error ).
      RETURN.
    ENDIF.
    mo_cgui_alv->set_filter( name = mv_cgui_filter_col
                             rows = ls_result-rows ).

  ENDMETHOD.

  METHOD window.

    mv_cgui_window       = abap_true.
    mv_cgui_window_title = title.
    mv_cgui_window_cols  = columns.
    mv_cgui_window_lines = lines.

  ENDMETHOD.

  METHOD at_selection_screen_on_exit ##NEEDED.
  ENDMETHOD.

  METHOD view_display_window_base.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lt_text TYPE string_table.
    DATA lr_tab  TYPE REF TO data.

    " the list the dialog box stands on cannot be used while it is open -
    " it is shown as the text it prints as
    DATA(ls_level) = mt_cgui_level[ lines( mt_cgui_level ) ].
    IF ls_level-alv IS BOUND.
      IF ls_level-alv_name IS NOT INITIAL.
        lr_tab = attri_assign( ls_level-alv_name ).
      ELSE.
        lr_tab = ls_level-alv_data.
      ENDIF.
      IF lr_tab IS BOUND.
        ASSIGN lr_tab->* TO <tab>.
        INSERT LINES OF ls_level-alv->to_text( <tab> ) INTO TABLE lt_text.
      ENDIF.
    ENDIF.
    IF ls_level-tree IS BOUND.
      INSERT LINES OF ls_level-tree->to_text( ) INTO TABLE lt_text.
    ENDIF.
    IF ls_level-list IS BOUND.
      INSERT LINES OF ls_level-list->to_text( ) INTO TABLE lt_text.
    ENDIF.

    page->ele( `ScrollContainer`
        )->a( n = `horizontal` b = abap_true
        )->a( n = `vertical`   b = abap_true
        )->a( n = `height`     v = `100%`
        )->tag( `Text`
        )->a( n = `text`             t = concat_lines_of( table = lt_text sep = |\n| )
        )->a( n = `renderWhitespace` b = abap_true
        )->a( n = `wrapping`         b = abap_false
        )->a( n = `class`            v = `sapUiSmallMargin` ).

  ENDMETHOD.

  METHOD view_display_window.

    " WINDOW STARTING AT ... ENDING AT - a column is about 0.6rem wide, a
    " line about 1.5rem high
    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = COND #( WHEN mv_cgui_window_title IS NOT INITIAL
                                             THEN mv_cgui_window_title
                                             ELSE mv_cgui_title )
        )->a( n = `contentWidth` v = |{ nmax( val1 = 20 val2 = mv_cgui_window_cols * 6 / 10 ) }rem|
        )->a( n = `resizable`    b = abap_true
        )->a( n = `draggable`    b = abap_true ).
    IF mv_cgui_window_lines > 0.
      lo_dialog->a( n = `contentHeight` v = |{ nmax( val1 = 6 val2 = mv_cgui_window_lines * 3 / 2 ) }rem| ).
    ENDIF.

    view_display_output( lo_dialog->ele( `content` ) ).

    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`    t = CONV #( 'Back'(025) )
        )->a( n = `icon`    v = `sap-icon://nav-back`
        )->a( n = `type`    v = `Emphasized`
        )->a( n = `tooltip` v = `F3`
        )->a( n = `press`   v = client->_event( cs_ucomm-back ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD alv_page_sync.

    FIELD-SYMBOLS <full> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <page> TYPE STANDARD TABLE.

    " selection and input of the rows shown go back to the rows they are
    " cut from
    IF mo_cgui_alv IS NOT BOUND OR mr_cgui_alv_page IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lr_full) = alv_shown( ).
    IF lr_full IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_full->* TO <full>.
    ASSIGN mr_cgui_alv_page->* TO <page>.
    LOOP AT <page> ASSIGNING FIELD-SYMBOL(<row>).
      DATA(lv_shown) = sy-tabix.
      READ TABLE mt_cgui_alv_index INTO DATA(lv_row) INDEX lv_shown.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      READ TABLE <full> ASSIGNING FIELD-SYMBOL(<line>) INDEX lv_row.
      IF sy-subrc = 0.
        <line> = <row>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD alv_edit_sync.

    FIELD-SYMBOLS <src>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <box>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>  TYPE any.
    FIELD-SYMBOLS <line> TYPE any.

    IF mo_cgui_alv IS NOT BOUND OR mr_cgui_alv_box IS NOT BOUND OR mo_cgui_alv->is_editable( ) = abap_false.
      RETURN.
    ENDIF.
    DATA(lr_src) = alv_source( ).
    IF lr_src IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_src->* TO <src>.
    ASSIGN mr_cgui_alv_box->* TO <box>.
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

  METHOD view_display.

    DATA lv_button_text  TYPE string.
    DATA lv_button_icon  TYPE string.
    DATA lv_button_ucomm TYPE string.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `xmlns:z2ui5`  v = `z2ui5.cc`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height`       v = `100%` ).

    DATA(page) = view->ele( `Page`
        )->a( n = `title`          t = mv_cgui_title
        )->a( n = `showNavButton`  b = xsdbool( mv_cgui_screen = cs_screen-output OR mv_cgui_called = abap_true )
        )->a( n = `navButtonPress` v = client->_event( cs_ucomm-back ) ).

    " the storage controls read the variants and the parameter IDs out of
    " the browser's local storage into mv_cgui_variants and mv_cgui_spa and
    " report them when they differ from what the backend has - fired while
    " the first view still renders, so the event is queued instead of
    " dropped (check_queue_last); both report the same event, which handles
    " what arrived
    IF mo_cgui_store IS NOT BOUND.
      page->tag( n = `Storage` ns = `z2ui5`
          )->a( n = `type`     v = `local`
          )->a( n = `prefix`   v = cv_cgui_variant_prefix
          )->a( n = `key`      t = variant_key( )
          )->a( n = `value`    v = client->_bind( mv_cgui_variants )
          )->a( n = `finished` v = client->_event( val    = cs_ucomm-variants_loaded
                                                   s_ctrl = VALUE #( check_queue_last = abap_true ) ) ).
    ENDIF.
    page->tag( n = `Storage` ns = `z2ui5`
        )->a( n = `type`     v = `local`
        )->a( n = `prefix`   v = cv_cgui_spa_prefix
        )->a( n = `key`      v = cv_cgui_spa_key
        )->a( n = `value`    v = client->_bind( mv_cgui_spa )
        )->a( n = `finished` v = client->_event( val    = cs_ucomm-variants_loaded
                                                 s_ctrl = VALUE #( check_queue_last = abap_true ) ) ).

    DATA(lv_window) = xsdbool( mv_cgui_screen = cs_screen-output
                               AND mv_cgui_window = abap_true
                               AND mt_cgui_level IS NOT INITIAL ).
    " no authorization: nothing but the messages
    IF mv_cgui_denied = abap_true.
      CLEAR lv_window.
    ELSEIF mv_cgui_screen = cs_screen-output.
      IF lv_window = abap_true.
        view_display_window_base( page ).
      ELSE.
        view_display_output( page ).
      ENDIF.
      lv_button_text = 'Back'(025).
      lv_button_icon = `sap-icon://nav-back`.
      lv_button_ucomm = cs_ucomm-back.
    ELSE.
      DATA(screen) = z2ui5_cl_cgui_selscreen=>factory( client          = client
                                                       value_help_auto = abap_true ).
      selection_screen( screen ).
      LOOP AT mt_cgui_vrm REFERENCE INTO DATA(lr_vrm).
        screen->set_listbox_values( name   = lr_vrm->name
                                    values = lr_vrm->values ).
      ENDLOOP.
      at_selection_screen_output( screen ).
      variant_attributes_apply( screen ).
      value_state_set( screen ).
      mt_cgui_field = screen->get_fields( ).
      mt_cgui_fkey = screen->get_function_keys( ).
      so_buffer_prepare( screen ).
      tab_binding_prepare( screen ).
      screen->render( page ).
      lv_button_text = 'Execute'(026).
      lv_button_icon = `sap-icon://begin`.
      lv_button_ucomm = cs_ucomm-execute.
    ENDIF.

    DATA(toolbar) = page->ele( `footer`
        )->ele( `OverflowToolbar` ).

    messages_render( page    = page
                     toolbar = toolbar ).

    IF mv_cgui_denied = abap_true.
      client->view_display( view->stringify( ) ).
      RETURN.
    ENDIF.

    IF mv_cgui_screen = cs_screen-selection AND mt_cgui_field IS NOT INITIAL.
      " RS_SET_SELSCREEN_STATUS switches standard functions off
      IF NOT line_exists( mt_cgui_excl_sel[ table_line = cs_ucomm-variant_get ] ).
        toolbar->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Get Variant'(016) )
            )->a( n = `icon`  v = `sap-icon://open-folder`
            )->a( n = `press` v = client->_event( cs_ucomm-variant_get ) ).
      ENDIF.
      IF NOT line_exists( mt_cgui_excl_sel[ table_line = cs_ucomm-variant_save ] ).
        toolbar->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Save as Variant'(014) )
            )->a( n = `icon`  v = `sap-icon://save`
            )->a( n = `press` v = client->_event( cs_ucomm-variant_save ) ).
      ENDIF.
      IF NOT line_exists( mt_cgui_excl_sel[ table_line = cs_ucomm-variant_delete ] ).
        toolbar->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Delete Variant'(007) )
            )->a( n = `icon`  v = `sap-icon://delete`
            )->a( n = `press` v = client->_event( cs_ucomm-variant_delete ) ).
      ENDIF.
      IF NOT line_exists( mt_cgui_excl_sel[ table_line = cs_ucomm-link_copy ] ).
        toolbar->tag( `Button`
            )->a( n = `text`    t = CONV #( 'Copy Link'(027) )
            )->a( n = `icon`    v = `sap-icon://chain-link`
            )->a( n = `press`   v = client->_event( cs_ucomm-link_copy ) ).
      ENDIF.

    ENDIF.

    " SELECTION-SCREEN FUNCTION KEY - and SET PF-STATUS on the output
    IF mv_cgui_screen = cs_screen-selection.
      LOOP AT mt_cgui_fkey INTO DATA(ls_fkey).
        toolbar->tag( `Button`
            )->a( n = `text`  t = ls_fkey-text
            )->a( n = `icon`  v = ls_fkey-icon
            )->a( n = `press` v = client->_event( ls_fkey-ucomm ) ).
      ENDLOOP.
    ELSE.
      LOOP AT mt_cgui_pf INTO DATA(ls_pf).
        toolbar->tag( `Button`
            )->a( n = `text`    t = ls_pf-text
            )->a( n = `icon`    v = ls_pf-icon
            )->a( n = `tooltip` t = ls_pf-tooltip
            )->a( n = `press`   v = client->_event( ls_pf-name ) ).
      ENDLOOP.
      IF NOT line_exists( mt_cgui_excl_out[ table_line = cs_ucomm-print ] ).
        toolbar->tag( `Button`
            )->a( n = `text`  t = CONV #( 'Print'(034) )
            )->a( n = `icon`  v = `sap-icon://print`
            )->a( n = `press` v = client->_event( cs_ucomm-print ) ).
      ENDIF.
    ENDIF.

    toolbar->tag( `ToolbarSpacer` ).
    IF NOT ( lv_button_ucomm = cs_ucomm-execute AND line_exists( mt_cgui_excl_sel[ table_line = cs_ucomm-execute ] ) ).
      toolbar->tag( `Button`
          )->a( n = `text`    t = lv_button_text
          )->a( n = `icon`    v = lv_button_icon
          )->a( n = `type`    v = `Emphasized`
          )->a( n = `tooltip` v = COND #( WHEN lv_button_ucomm = cs_ucomm-execute THEN `F8` ELSE `F3` )
          )->a( n = `press`   v = client->_event( lv_button_ucomm ) ).
    ENDIF.

    client->view_display( view->stringify( ) ).
    shortcuts_register( ).

    " SET CURSOR FIELD
    IF mv_cgui_screen = cs_screen-selection AND mv_cgui_cursor_field IS NOT INITIAL.
      client->follow_up_action( val   = client->cs_event-set_focus
                                t_arg = VALUE #( ( z2ui5_cl_cgui_selscreen=>field_id( mv_cgui_cursor_field ) ) ) ).
      CLEAR mv_cgui_cursor_field.
    ENDIF.

    IF lv_window = abap_true.
      view_display_window( ).
    ELSEIF mv_cgui_window_shown = abap_true.
      client->popup_destroy( ).
    ENDIF.
    mv_cgui_window_shown = lv_window.

    IF mv_cgui_dynnr IS NOT INITIAL.
      view_display_dynnr( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display_dynnr.

    " CALL SELECTION-SCREEN ... AS WINDOW - bound to the attributes of the
    " report like the selection screen itself
    DATA(screen) = z2ui5_cl_cgui_selscreen=>factory( client ).
    selection_screen_dynnr( dynnr  = mv_cgui_dynnr
                            screen = screen ).
    mt_cgui_dynnr_field = screen->get_fields( ).

    DATA(lo_dialog) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = COND #( WHEN mv_cgui_dynnr_title IS NOT INITIAL THEN mv_cgui_dynnr_title ELSE mv_cgui_title )
        )->a( n = `contentWidth` v = `40rem`
        )->a( n = `afterClose`   v = client->_event( cs_ucomm-screen_cancel ) ).

    DATA(lo_content) = lo_dialog->ele( `content` ).
    LOOP AT mt_cgui_log REFERENCE INTO DATA(lr_msg) WHERE type = `E`.
      lo_content->tag( `MessageStrip`
          )->a( n = `text`  t = lr_msg->text
          )->a( n = `type`  v = `Error`
          )->a( n = `class` v = `sapUiSmallMargin` ).
    ENDLOOP.
    screen->render( lo_content ).

    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = CONV #( 'OK'(029) )
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_ucomm-screen_ok )
        )->tag( `Button`
        )->a( n = `text`  t = CONV #( 'Cancel'(030) )
        )->a( n = `press` v = client->_event( cs_ucomm-screen_cancel ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD view_display_output.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <page> TYPE STANDARD TABLE.

    IF mo_cgui_alv IS BOUND.
      DATA(lr_src) = alv_source( ).
      IF lr_src IS BOUND.
        " the copy with the box field follows the table of the report
        ASSIGN lr_src->* TO <tab>.
        IF mo_cgui_alv->has_selection( ) = abap_true
            AND mo_cgui_alv->has_box_field( <tab> ) = abap_false.
          alv_box_refresh( lr_src ).
        ENDIF.
        DATA(lr_tab) = alv_shown( ).
        ASSIGN lr_tab->* TO <tab>.
        IF mv_cgui_layout_done = abap_false.
          layout_default_apply( <tab> ).
        ENDIF.
        " filtered or large: the browser gets a copy of the rows it shows,
        " mt_cgui_alv_index leads back to the rows of the table
        DATA(lv_all) = lines( <tab> ).
        DATA(lt_index) = mo_cgui_alv->filter_index( <tab> ).
        DATA(lv_total) = lines( lt_index ).
        DATA(lv_size) = mo_cgui_alv->get_page_size( ).
        DATA(lv_paged) = xsdbool( lv_size > 0 AND lv_total > lv_size ).
        CLEAR: mr_cgui_alv_page, mt_cgui_alv_index.
        IF lv_paged = abap_true OR mo_cgui_alv->is_filtered( ) = abap_true.
          DATA(lv_from) = 1.
          DATA(lv_to) = lv_total.
          IF lv_paged = abap_true.
            mo_cgui_alv->page_turn( direction = ``
                                    lines     = lv_total ).
            lv_from = mo_cgui_alv->get_page_offset( ) + 1.
            lv_to = lv_from + lv_size - 1.
          ENDIF.
          CREATE DATA mr_cgui_alv_page LIKE <tab>.
          ASSIGN mr_cgui_alv_page->* TO <page>.
          " empty - the transpiled runtime copies the rows along with LIKE
          CLEAR <page>.
          LOOP AT lt_index INTO DATA(lv_row) FROM lv_from TO lv_to.
            READ TABLE <tab> ASSIGNING FIELD-SYMBOL(<page_row>) INDEX lv_row.
            IF sy-subrc = 0.
              INSERT <page_row> INTO TABLE <page>.
              INSERT lv_row INTO TABLE mt_cgui_alv_index.
            ENDIF.
          ENDLOOP.
          ASSIGN mr_cgui_alv_page->* TO <tab>.
        ENDIF.
        mo_cgui_alv->render( node   = page
                             client = client
                             tab    = <tab>
                             total  = lv_total
                             all    = lv_all ).
      ENDIF.
    ENDIF.

    IF mo_cgui_tree IS BOUND.
      mt_cgui_tree_view = mo_cgui_tree->view( ).
      mo_cgui_tree->render( node      = page
                            client    = client
                            view      = mt_cgui_tree_view
                            rows_bind = client->_bind( mt_cgui_tree_view ) ).
    ENDIF.

    IF mo_cgui_list IS BOUND.
      " the input fields bound to their lines of mt_cgui_list_input
      mt_cgui_list_input = mo_cgui_list->get_inputs( ).
      DATA lt_input_bind TYPE z2ui5_cl_cgui_list=>ty_t_input_bind.
      LOOP AT mt_cgui_list_input ASSIGNING FIELD-SYMBOL(<input>).
        DATA(lv_input) = sy-tabix.
        INSERT VALUE #( id    = <input>-id
                        value = client->_bind( val       = <input>-value
                                               tab       = mt_cgui_list_input
                                               tab_index = lv_input )
                        flag  = client->_bind( val       = <input>-flag
                                               tab       = mt_cgui_list_input
                                               tab_index = lv_input ) ) INTO TABLE lt_input_bind.
      ENDLOOP.
      mo_cgui_list->set_input_binds( lt_input_bind ).
      mo_cgui_list->render( node   = page
                            client = client
                            inputs = mt_cgui_list_input ).
    ENDIF.

  ENDMETHOD.

  METHOD value_state_set.

    DATA lv_state TYPE string.

    LOOP AT mt_cgui_log REFERENCE INTO DATA(lr_msg) WHERE field IS NOT INITIAL.
      CASE lr_msg->type.
        WHEN `E` OR `A`.
          lv_state = `Error`.
        WHEN `W`.
          lv_state = `Warning`.
        WHEN `S`.
          lv_state = `Success`.
        WHEN OTHERS.
          lv_state = `Information`.
      ENDCASE.
      screen->set_value_state( name  = lr_msg->field
                               text  = lr_msg->text
                               state = lv_state ).
    ENDLOOP.

  ENDMETHOD.

  METHOD messages_display.

    " S as a toast, I as a box - and W, E, A open the message popover,
    " which lists the I messages of the run as well
    DATA lv_text    TYPE string.
    DATA lv_popover TYPE abap_bool.

    LOOP AT mt_cgui_msg REFERENCE INTO DATA(lr_msg).
      CASE lr_msg->type.
        WHEN `S`.
          client->message_toast_display( lr_msg->text ).
        WHEN `I`.
          IF lv_text IS NOT INITIAL.
            lv_text = lv_text && cl_abap_char_utilities=>newline.
          ENDIF.
          lv_text = lv_text && lr_msg->text.
        WHEN OTHERS.
          lv_popover = abap_true.
      ENDCASE.
    ENDLOOP.

    IF lv_popover = abap_true AND mv_cgui_nav = abap_false AND mv_cgui_dynnr IS INITIAL.
      " the popover is part of the screen, and opened in a roundtrip of its
      " own: opened by the response that builds the screen, it stayed open
      " without ever being rendered (the frontend holds the rendering back
      " while it swaps the view). A timer of no time raises that roundtrip
      client->follow_up_action( val   = client->cs_event-start_timer
                                t_arg = VALUE #( ( cs_ucomm-messages_open ) ( `0` ) ( `X` ) ) ).
    ELSEIF lv_text IS NOT INITIAL.
      client->message_box_display( text = lv_text
                                   type = `information` ).
    ENDIF.

  ENDMETHOD.

  METHOD messages_render.

    " the button counts the messages of the run - icon and type follow the
    " worst of them - and opens the popover in the browser, no roundtrip.
    " The popover is a dependent of the page, not a popover of its own: it
    " comes and goes with the screen it belongs to
    DATA lv_index TYPE i.

    IF mt_cgui_log IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_icon) = `sap-icon://message-information`.
    DATA(lv_type) = `Transparent`.
    READ TABLE mt_cgui_log WITH KEY type = `W` TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      lv_icon = `sap-icon://message-warning`.
      lv_type = `Default`.
    ENDIF.
    LOOP AT mt_cgui_log TRANSPORTING NO FIELDS WHERE type = `E` OR type = `A`.
      lv_icon = `sap-icon://message-error`.
      lv_type = `Reject`.
      EXIT.
    ENDLOOP.

    toolbar->tag( `Button`
        )->a( n = `id`      v = cv_cgui_messages_id
        )->a( n = `icon`    v = lv_icon
        )->a( n = `type`    v = lv_type
        )->a( n = `text`    t = |{ lines( mt_cgui_log ) }|
        )->a( n = `tooltip` t = CONV #( 'Messages'(031) )
        )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                          t_arg = VALUE #( ( cv_cgui_popover_id ) ( `toggleBy` ) ( cv_cgui_messages_id ) ) ) ).

    DATA(items) = page->ele( `dependents`
        )->ele( `MessagePopover`
            )->a( n = `id`               v = cv_cgui_popover_id
            )->a( n = `placement`        v = `Top`
            )->a( n = `activeTitlePress` v = client->_event( val = cs_ucomm-message_focus
                                                             arg = `${$parameters>/item}` )
        )->ele( `items` ).

    " the id carries the index into the log: the event hands the item over
    " as its properties and its id, and the id leads back to the field
    LOOP AT mt_cgui_log REFERENCE INTO DATA(lr_msg).
      lv_index = sy-tabix.
      items->tag( `MessageItem`
          )->a( n = `id`          t = |cgui_msg_{ lv_index }|
          )->a( n = `type`        v = SWITCH #( lr_msg->type
                                                  WHEN `E` OR `A` THEN `Error`
                                                  WHEN `W` THEN `Warning`
                                                  ELSE `Information` )
          )->a( n = `title`       t = lr_msg->text
          )->a( n = `subtitle`    t = message_field_text( lr_msg->field )
          )->a( n = `activeTitle` b = xsdbool( lr_msg->field IS NOT INITIAL AND mv_cgui_screen = cs_screen-selection ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD message_focus.

    DATA lv_index TYPE string.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( cv_cgui_popover_id ) ( `close` ) ) ).

    " the id of the item, cgui_msg_<n> - n is the index into the log
    lv_index = substring_after( val = arg
                                sub = `cgui_msg_` ).
    IF lv_index IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_length) = strlen( lv_index ).
    DATA(lv_digits) = 0.
    WHILE lv_digits < lv_length.
      DATA(lv_digit) = substring( val = lv_index off = lv_digits len = 1 ).
      IF lv_digit CN `0123456789`.
        EXIT.
      ENDIF.
      lv_digits = lv_digits + 1.
    ENDWHILE.
    IF lv_digits = 0.
      RETURN.
    ENDIF.
    lv_index = substring( val = lv_index len = lv_digits ).

    READ TABLE mt_cgui_log REFERENCE INTO DATA(lr_msg) INDEX CONV i( lv_index ).
    IF sy-subrc <> 0 OR lr_msg->field IS INITIAL OR mv_cgui_screen <> cs_screen-selection.
      RETURN.
    ENDIF.

    client->follow_up_action( val   = client->cs_event-set_focus
                              t_arg = VALUE #( ( z2ui5_cl_cgui_selscreen=>field_id( lr_msg->field ) ) ) ).

  ENDMETHOD.

  METHOD message_field_text.

    IF field IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_cgui_field REFERENCE INTO DATA(lr_field) WITH KEY name = field.
    IF sy-subrc = 0.
      result = lr_field->text.
    ELSE.
      result = field.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
