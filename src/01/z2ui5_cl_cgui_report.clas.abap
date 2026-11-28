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
"! screen can be saved as variants, kept in table Z2UI5_T_19 per report,
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
    "! the files of cl_gui_frontend_services - z2ui5_cl_cgui_frontend
    INTERFACES z2ui5_if_cgui_files.
    "! the SAP GUI controls - z2ui5_cl_cgui_gui and its subclasses
    INTERFACES z2ui5_if_cgui_gui.
    "! the messages and popups of the short API - _msg( ), _msg_box( ), _popup( )
    INTERFACES z2ui5_if_cgui_dialogs.

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
        background        TYPE string VALUE `CGUI_BACKGROUND`,
        okcode            TYPE string VALUE `CGUI_OKCODE`,
        palette           TYPE string VALUE `CGUI_PALETTE`,
        enter             TYPE string VALUE `CGUI_ENTER`,
        gui               TYPE string VALUE `CGUI_GUI`,
        " F1 and F4 in a text editor that registered them
        gui_f1            TYPE string VALUE `CGUI_GUI_F1`,
        gui_f4            TYPE string VALUE `CGUI_GUI_F4`,
        draft_discard     TYPE string VALUE `CGUI_DRAFT_DISCARD`,
      END OF cs_ucomm.

    "! the prefix of the browser's local storage the variants are kept
    "! under, the key is the name of the report class
    CONSTANTS cv_cgui_variant_prefix TYPE string VALUE `z2ui5_cgui_variants`.

    "! the browser's local storage of SET / GET PARAMETER ID - one entry for
    "! every report of the browser, the SAP memory of this addon
    CONSTANTS cv_cgui_spa_prefix TYPE string VALUE `z2ui5_cgui_spa`.
    "! the user parameters in a server store: the "report" of the variants
    "! that hold them, one variant per user, named by the user
    CONSTANTS cv_cgui_spa_report TYPE string VALUE `%SPA`.
    CONSTANTS cv_cgui_spa_key    TYPE string VALUE `PARAMETERS`.
    " the customizing parameters - a variant of the store's report %SPA,
    " beside the user's own
    CONSTANTS cv_cgui_spa_customizing TYPE string VALUE `%CUSTOMIZING`.

    "! the browser's local storage of the input history - the last entries
    "! of every field, the key is the name of the report class
    CONSTANTS cv_cgui_history_prefix TYPE string VALUE `z2ui5_cgui_history`.
    "! how many entries of a field the history keeps
    CONSTANTS cv_cgui_history_size   TYPE i VALUE 10.

    "! the id of the footer button the message popover opens on, and of the
    "! popover itself
    CONSTANTS cv_cgui_messages_id TYPE string VALUE `cgui_messages`.
    CONSTANTS cv_cgui_popover_id  TYPE string VALUE `cgui_message_popover`.

    "! the URL parameter that runs the report without its selection screen
    CONSTANTS cv_cgui_url_skip TYPE string VALUE `SKIP_SCREEN`.
    "! the id of the text area of text editor n - prefix and n
    CONSTANTS cv_cgui_textedit_id TYPE string VALUE `cgui_textedit_`.

    TYPES:
      "! the inputs from and to of the select-options - the buffer the screen
      "! binds to, turned into the ranges on every roundtrip
      BEGIN OF ty_s_cgui_so,
        name TYPE string,
        low  TYPE string,
        high TYPE string,
      END OF ty_s_cgui_so.
    TYPES ty_t_cgui_so TYPE STANDARD TABLE OF ty_s_cgui_so WITH DEFAULT KEY.

    TYPES:
      "! a handler of mt_cgui_handler - its object a line of
      "! mt_cgui_handler_obj, each object there once
      BEGIN OF ty_s_cgui_handler,
        id      TYPE i,
        event   TYPE string,
        object  TYPE i,
        class   TYPE string,
        method  TYPE string,
      END OF ty_s_cgui_handler.
    TYPES ty_t_cgui_handler TYPE STANDARD TABLE OF ty_s_cgui_handler WITH DEFAULT KEY.

    TYPES:
      "! CONTROLS name TYPE TABSTRIP - the function code of the selected tab
      "! of the tabstrip of a dynpro; empty, its first tab is selected
      BEGIN OF ty_s_tabstrip,
        activetab TYPE c LENGTH 132,
      END OF ty_s_tabstrip.

    TYPES:
      "! CONTROLS name TYPE TABLEVIEW - the table control of a dynpro: its
      "! lines, the line the loop is at, the first line shown
      BEGIN OF ty_s_tableview,
        fixed_cols    TYPE i,
        lines         TYPE i,
        top_line      TYPE i,
        current_line  TYPE i,
        left_col      TYPE i,
        line_sel_mode TYPE i,
        col_sel_mode  TYPE i,
        line_selector TYPE c LENGTH 1,
        h_grid        TYPE c LENGTH 1,
        v_grid        TYPE c LENGTH 1,
        invisible     TYPE c LENGTH 1,
      END OF ty_s_tableview.

    TYPES:
      "! a line of the table control the browser shows - its cells as text,
      "! the columns in their order
      BEGIN OF ty_s_cgui_tc_row,
        c01 TYPE string,
        c02 TYPE string,
        c03 TYPE string,
        c04 TYPE string,
        c05 TYPE string,
        c06 TYPE string,
        c07 TYPE string,
        c08 TYPE string,
        c09 TYPE string,
        c10 TYPE string,
        c11 TYPE string,
        c12 TYPE string,
        c13 TYPE string,
        c14 TYPE string,
        c15 TYPE string,
        c16 TYPE string,
      END OF ty_s_cgui_tc_row.
    TYPES ty_t_cgui_tc_row TYPE STANDARD TABLE OF ty_s_cgui_tc_row WITH DEFAULT KEY.

    "! the most columns a table control shows
    CONSTANTS cv_cgui_tc_columns TYPE i VALUE 16.

    TYPES:
      "! the subscreen called into an area of a dynpro (CALL SUBSCREEN)
      BEGIN OF ty_s_cgui_subscreen,
        area  TYPE string,
        dynnr TYPE string,
      END OF ty_s_cgui_subscreen.
    TYPES ty_t_cgui_subscreen TYPE STANDARD TABLE OF ty_s_cgui_subscreen WITH DEFAULT KEY.

    TYPES:
      "! the selected tab of each tabbed block
      BEGIN OF ty_s_cgui_tab,
        key TYPE string,
      END OF ty_s_cgui_tab.
    TYPES ty_t_cgui_tab TYPE STANDARD TABLE OF ty_s_cgui_tab WITH DEFAULT KEY.

    TYPES:
      "! a keyboard shortcut of set_pf_status( ) - key as the frontend
      "! spells it (F5, Shift+F2, Ctrl+F1), ucomm the function it raises
      BEGIN OF ty_s_shortcut,
        key   TYPE string,
        ucomm TYPE string,
      END OF ty_s_shortcut.
    TYPES ty_t_shortcut TYPE STANDARD TABLE OF ty_s_shortcut WITH DEFAULT KEY.

    TYPES:
      "! a message of a run - the result of cgui_run_in_background( )
      BEGIN OF ty_s_cgui_message,
        type TYPE string,
        text TYPE string,
      END OF ty_s_cgui_message.
    TYPES ty_t_cgui_message TYPE STANDARD TABLE OF ty_s_cgui_message WITH DEFAULT KEY.

    "! the output of alv( ) when the table passed is no attribute of the
    "! report - a copy, bound to the grid
    DATA mr_cgui_alv TYPE REF TO data.

    "! the table the grid shows when it has a selection column and the table
    "! of the report no box field: a copy with the field ZZSELKZ
    DATA mr_cgui_alv_box TYPE REF TO data.
    " the rows the grid shows when it is filtered or paged - a copy; per row
    " the row of the table it comes from is mt_cgui_alv_index. Paged, the
    " rows loaded so far of mt_cgui_alv_order
    DATA mr_cgui_alv_page TYPE REF TO data.
    "! the rows the grid shows in all - its length when it is paged, bound
    "! with mr_cgui_alv_page
    DATA mv_cgui_alv_total TYPE i.

    "! the variants of the report as the browser's local storage holds them
    "! (z2ui5_cl_cgui_variant=>catalog_to_string( )) - bound to the storage
    "! control that reads them, hence PUBLIC
    DATA mv_cgui_variants TYPE string.

    "! the parameter IDs of the browser - ID=value lines, bound to the
    "! storage control that reads them
    DATA mv_cgui_spa TYPE string.
    "! the command field of the page header
    DATA mv_cgui_okcode TYPE string.
    "! the input history in the browser - a line per field: NAME, a tab,
    "! the entries apart by tabs, the latest first
    DATA mv_cgui_history TYPE string.

    DATA mt_cgui_so  TYPE ty_t_cgui_so.
    DATA mt_cgui_tab TYPE ty_t_cgui_tab.

    "! the input fields of the list (WRITE ... INPUT) - every field is bound
    "! to its line
    DATA mt_cgui_list_input TYPE z2ui5_cl_cgui_list=>ty_t_input.
    "! the lines of the table control of the dynpro (LOOP WITH CONTROL)
    DATA mt_cgui_tc_row TYPE ty_t_cgui_tc_row.
    "! the lines of the table control the browser holds - the first ones of
    "! mt_cgui_tc_row, a window at a time; bound to its inputs
    DATA mt_cgui_tc_view TYPE ty_t_cgui_tc_row.
    "! the lines of the table control in all - bound with mt_cgui_tc_view
    DATA mv_cgui_tc_total TYPE i.
    "! the SAP GUI controls of the report (z2ui5_if_cgui_gui) - a text
    "! editor is bound to its line
    DATA mt_cgui_gui TYPE z2ui5_if_cgui_gui=>ty_t_control.
    "! the rows of the ALV tree the browser shows - bound to the tree table
    DATA mt_cgui_tree_view TYPE z2ui5_cl_cgui_tree=>ty_t_view.


    "! the report without a browser - e.g. in an application job of your
    "! own: the values are set, the events of the selection screen,
    "! START-OF-SELECTION and END-OF-SELECTION run; list and alv return the
    "! output, pdf its printout, messages what the run reported. A run
    "! stopped by an error returns no output
    METHODS cgui_run_in_background
      IMPORTING
        values   TYPE z2ui5_cl_cgui_variant=>ty_t_value
      EXPORTING
        list     TYPE REF TO z2ui5_cl_cgui_list
        alv      TYPE REF TO z2ui5_cl_cgui_alv
        alv_data TYPE REF TO data
        pdf      TYPE xstring
        messages TYPE ty_t_cgui_message.

  PROTECTED SECTION.
    "! the controls themselves, line by line of mt_cgui_gui - the events of
    "! the browser go to them
    TYPES temp1_dc62f61289 TYPE STANDARD TABLE OF REF TO object WITH DEFAULT KEY.
DATA mt_cgui_gui_obj TYPE temp1_dc62f61289.
    "! the handlers SET HANDLER set for the events of the controls, and
    "! their objects - once each: the handler of two events stays one object
    "! wherever the app is restored from its serialized form
    DATA mt_cgui_handler TYPE ty_t_cgui_handler.
    TYPES temp2_dc62f61289 TYPE STANDARD TABLE OF REF TO object WITH DEFAULT KEY.
DATA mt_cgui_handler_obj TYPE temp2_dc62f61289.
    "! the grids (z2ui5_cl_cgui_alv_grid) and the one the ALV shows
    DATA mt_cgui_grid TYPE z2ui5_if_cgui_gui=>ty_t_grid.
    DATA mv_cgui_grid TYPE i.
    "! the field catalog and the layout of the grid shown - attributes of
    "! their own: a data reference in a line of a table does not come back
    "! from the serialized app of the transpiled runtime
    DATA mr_cgui_grid_fieldcat TYPE REF TO data.
    DATA mr_cgui_grid_layout TYPE REF TO data.

    TYPES:
      BEGIN OF ty_s_cgui_msg,
        type  TYPE string,
        text  TYPE string,
        field TYPE string,
      END OF ty_s_cgui_msg.
    TYPES ty_t_cgui_msg TYPE STANDARD TABLE OF ty_s_cgui_msg WITH DEFAULT KEY.

    TYPES:
      " character types: the popup heads a column with the DDIC label of its
      " type, the component name when it has none - and STRING for a string
      BEGIN OF ty_s_cgui_value,
        value TYPE c LENGTH 10,
        text  TYPE c LENGTH 60,
      END OF ty_s_cgui_value.
    TYPES ty_t_cgui_value TYPE STANDARD TABLE OF ty_s_cgui_value WITH DEFAULT KEY.

    TYPES:
      "! a level of the output - the basic list and every secondary list
      BEGIN OF ty_s_cgui_level,
        list     TYPE REF TO z2ui5_cl_cgui_list,
        alv      TYPE REF TO z2ui5_cl_cgui_alv,
        tree     TYPE REF TO z2ui5_cl_cgui_tree,
        alv_name TYPE string,
        alv_data TYPE REF TO data,
        " the copy with the box field - the rows selected in the ALV
        alv_box  TYPE REF TO data,
        window   TYPE abap_bool,
        w_title  TYPE string,
        w_cols   TYPE i,
        w_lines  TYPE i,
        " the grid the ALV of the level shows, and its field catalog and layout
        grid     TYPE i,
        grid_cat TYPE REF TO data,
        grid_lay TYPE REF TO data,
        " the controls there were - those created after belong to the next level
        gui      TYPE i,
        " SET PF-STATUS of the level
        pf       TYPE z2ui5_cl_cgui_alv=>ty_t_function,
        pf_keys  TYPE ty_t_shortcut,
        pf_excl  TYPE string_table,
      END OF ty_s_cgui_level.
    TYPES ty_t_cgui_level TYPE STANDARD TABLE OF ty_s_cgui_level WITH DEFAULT KEY.

    TYPES:
      "! a screen CALL SCREEN returns to - the selection screen, the output
      "! or a dynpro (dynnr)
      " the screen and the dynpro CALL SCREEN came from, and the dynpro it called
      " and the status it showed
      BEGIN OF ty_s_cgui_call,
        screen  TYPE string,
        dynnr   TYPE string,
        called  TYPE string,
        pf      TYPE z2ui5_cl_cgui_alv=>ty_t_function,
        pf_keys TYPE ty_t_shortcut,
        pf_excl TYPE string_table,
      END OF ty_s_cgui_call.
    TYPES ty_t_cgui_call TYPE STANDARD TABLE OF ty_s_cgui_call WITH DEFAULT KEY.

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
    TYPES ty_t_cgui_vrm TYPE STANDARD TABLE OF ty_s_cgui_vrm WITH DEFAULT KEY.

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

    "! LOOP WITH CONTROL name in the PBO of a dynpro, before its first line:
    "! the table control shows the lines handed over by tablecontrol_row( )
    METHODS tablecontrol_begin
      IMPORTING
        name TYPE clike.

    "! a line of the table control name in the PBO loop - the values of its
    "! columns in their order, after the modules of the loop ran
    METHODS tablecontrol_row
      IMPORTING
        name   TYPE clike
        values TYPE string_table.

    "! LOOP WITH CONTROL name in the PAI: the lines the table control
    "! showed
    METHODS tablecontrol_count
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE i.

    "! the value of column col of line row of the table control name as
    "! the user left it - into its field before the modules of the PAI loop
    METHODS tablecontrol_cell
      IMPORTING
        name          TYPE clike
        row           TYPE i
        col           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    "! CALL SUBSCREEN area INCLUDING sy-repid dynnr in the PBO of a dynpro -
    "! the subscreen dynnr shows in area (z2ui5_cl_cgui_selscreen=>
    "! subscreen( )), its PBO runs now
    METHODS call_subscreen
      IMPORTING
        area  TYPE clike
        dynnr TYPE clike.

    "! CALL SUBSCREEN area in the PAI of a dynpro - the PAI of the subscreen
    "! the PBO called into area
    METHODS call_subscreen_pai
      IMPORTING
        area  TYPE clike
        ucomm TYPE string.

    "! the fields of dynpro dynnr, written onto screen like the selection
    "! screen - report2UI5 writes it from the screen of the .prog.xml
    METHODS dynpro_screen
      IMPORTING
        dynnr  TYPE string
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! PROCESS BEFORE OUTPUT of dynpro dynnr - before it shows, every time;
    "! current_screen( ) is its screen (LOOP AT SCREEN)
    METHODS dynpro_pbo
      IMPORTING
        dynnr TYPE string.

    "! PROCESS AFTER INPUT of dynpro dynnr - for every function: a push
    "! button, a function of the status, Back (`BACK`), Enter (empty)
    METHODS dynpro_pai
      IMPORTING
        dynnr TYPE string
        ucomm TYPE string.

    "! an event of a SAP GUI control, before its handlers run (SET HANDLER)
    METHODS at_gui_event.

    "! the start of every roundtrip, before any event - where the report
    "! hands itself to its local classes (lcl_r2c=>app = me), once instead
    "! of in every event method
    METHODS at_roundtrip_start.

    "! the CLASS-DATA of the local classes of the report into attributes of
    "! the report - at the end of every roundtrip. A roundtrip is a session
    "! of its own on a system: the static attributes of a class start
    "! initial, only the app is kept (serialized) from one to the next
    METHODS cgui_statics_keep.

    "! and back into the CLASS-DATA - at the start of every roundtrip
    METHODS cgui_statics_restore.

    "! after call_screen( ) - when the dynpro was left with
    "! leave_to_screen( `0` ): what followed CALL SCREEN in the report;
    "! dynnr is the screen call_screen( ) called, whichever screen SET
    "! SCREEN went on to after it
    METHODS after_call_screen
      IMPORTING
        dynnr TYPE string.

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

    "! the list READ LINE and MODIFY LINE work on - in at_line_selection( )
    "! the one clicked (what list( ) writes there is the next level), else
    "! the list of list( )
    METHODS read_list
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

    "! sy-lsind = n in at_line_selection( ) - the list it writes becomes
    "! level n: the levels above n - 1 are dropped, so Back returns to level
    "! n - 1 (0 replaces the basic list). n above the current level is ignored
    METHODS set_lsind
      IMPORTING
        val TYPE i.

    "! MESSAGE text TYPE type - S, I, W, E or A. field, the attribute name of
    "! a field of the selection screen, marks that field with the message;
    "! inside at_selection_screen_on( ) it is that method's field by default
    METHODS message
      IMPORTING
        text  TYPE clike
        type  TYPE clike DEFAULT `S`
        field TYPE clike OPTIONAL.

    "! the classic restart after the list: Back from the output gives the
    "! global data of the report - its own public attributes - the values
    "! they had after initialization( ), which runs again; the fields of the
    "! selection screen keep their input. On by default - off for a report
    "! that keeps its data from one run to the next
    METHODS set_fresh_start
      IMPORTING
        val TYPE abap_bool DEFAULT abap_true.

    "! the selection screen starts with the last entries of the fields:
    "! an empty field takes the latest entry of its input history (a
    "! variant to start with and the URL still win) - in initialization( )
    "! Execute in Background on the selection screen: the button hands the
    "! report and its values to the job - in initialization( )
    METHODS set_job
      IMPORTING
        val TYPE REF TO z2ui5_if_cgui_job.

    "! the command field in the page header, as in the SAP GUI: a
    "! transaction of the catalog, /nCODE and /oCODE (a new browser tab),
    "! /n and /o alone for this report, else an OK code - in
    "! initialization( )
    METHODS set_command_field
      IMPORTING
        val TYPE abap_bool DEFAULT abap_true.

    "! the transactions the command field and the palette (Ctrl+K) start
    METHODS set_catalog
      IMPORTING
        val TYPE REF TO z2ui5_if_cgui_catalog.

    "! what the command field does with a command - the event of the field
    METHODS okcode_execute
      IMPORTING
        val TYPE clike.

    "! the application log of the report: every message( ) - MESSAGE,
    "! _msg( ) - goes into it as well; the installation's adapter writes it
    "! to BAL, cl_bali_log or the ABAP Logger
    METHODS set_log
      IMPORTING
        val TYPE REF TO z2ui5_if_cgui_log.

    "! the messages of a log into the message popover of this roundtrip -
    "! an application log as its source; they do not stop the run
    METHODS messages_from_log
      IMPORTING
        log TYPE REF TO z2ui5_if_cgui_log.

    "! a log as a popup to read - the type and the text of every message,
    "! as SLG1 shows it
    METHODS log_display
      IMPORTING
        log   TYPE REF TO z2ui5_if_cgui_log
        title TYPE clike OPTIONAL.

    "! keep a draft: what the user enters on the selection screen and does
    "! not execute is kept - with every roundtrip of the screen, as a variant
    "! of the user's own (in the store of the variants) - and comes back at
    "! the next start, with Discard Draft beside it. Execute uses it up
    METHODS set_draft
      IMPORTING
        val TYPE abap_bool DEFAULT abap_true.

    METHODS set_prefill_last
      IMPORTING
        val TYPE abap_bool DEFAULT abap_true.

    "! the short API of the messages, in the style of abap2UI5:
    "! _msg( )->e( `No flights found` ) is message( text = ... type = `E` );
    "! the methods chain
    METHODS _msg
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

    "! _msg_box( )->i( `Saved` ) - a message box of its own, whatever the
    "! type; not in the message popover, the run goes on
    METHODS _msg_box
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

    "! the short API of the popups: _popup( )->confirm( ), decide( ),
    "! get_values( ) - popup_to_confirm( ), popup_to_decide( ),
    "! popup_get_values( )
    METHODS _popup
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_dialog.

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

    "! the transport request popup - the modifiable requests of the user;
    "! on a pick or "No Transport" at_user_command( ) runs with ucomm,
    "! get_transport( ) returns the answer (with then: `1` picked, `A` not)
    "! then names a PUBLIC method of the report with IMPORTING answer TYPE
    "! string - it runs instead of at_user_command( ) with the answer
    METHODS popup_transport
      IMPORTING
        ucomm TYPE clike OPTIONAL
        title TYPE clike OPTIONAL
        then  TYPE clike OPTIONAL.

    "! the answer of popup_transport( ) - confirmed, local (no transport),
    "! the request and the task of the user
    METHODS get_transport
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_transport=>ty_s_result.

    "! POPUP_TO_CONFIRM - on Yes, at_user_command( ) runs with ucomm; with
    "! then the method runs on both answers, answer `1` for Yes, `A` for No
    "! then names a PUBLIC method of the report with IMPORTING answer TYPE
    "! string - it runs instead of at_user_command( ) with the answer
    METHODS popup_to_confirm
      IMPORTING
        question TYPE clike
        ucomm    TYPE clike OPTIONAL
        title    TYPE clike DEFAULT `Confirm`
        then     TYPE clike OPTIONAL.

    "! POPUP_TO_DECIDE - on an answer at_user_command( ) runs with ucomm,
    "! popup_answer( ) returns `1`, `2`, ... for the option or `A` for cancel
    "! then names a PUBLIC method of the report with IMPORTING answer TYPE
    "! string - it runs instead of at_user_command( ) with the answer
    METHODS popup_to_decide
      IMPORTING
        question TYPE clike
        options  TYPE string_table
        ucomm    TYPE clike OPTIONAL
        title    TYPE clike OPTIONAL
        then     TYPE clike OPTIONAL.

    "! POPUP_GET_VALUES - on OK at_user_command( ) runs with ucomm and
    "! popup_values( ) returns the fields with what the user entered
    "! then names a PUBLIC method of the report with IMPORTING answer TYPE
    "! string - it runs instead of at_user_command( ) with the answer
    METHODS popup_get_values
      IMPORTING
        fields  TYPE z2ui5_cl_cgui_popup=>ty_t_field
        ucomm   TYPE clike                         OPTIONAL
        title   TYPE clike                         OPTIONAL
        text    TYPE clike                         OPTIONAL
        listbox TYPE z2ui5_cl_cgui_popup=>ty_t_listbox OPTIONAL
        then    TYPE clike                         OPTIONAL.

    "! POPUP_TO_DECIDE_LIST with its SPOPLI table: every VAROPTION one option
    "! of popup_to_decide( ) - the answer is the number of the line, `A` for
    "! cancel, as the classic one; a line with HIDE or INACTIVE is no option
    METHODS popup_to_decide_list
      IMPORTING
        question TYPE clike
        list     TYPE STANDARD TABLE
        ucomm    TYPE clike OPTIONAL
        title    TYPE clike OPTIONAL
        then     TYPE clike OPTIONAL.

    "! POPUP_GET_VALUES with its SVAL table: fieldname is the name, fieldtext
    "! the label (the field name when empty), value the start value,
    "! field_obl marks a required field - popup_get_values( ) with them
    METHODS popup_get_values_sval
      IMPORTING
        sval  TYPE STANDARD TABLE
        ucomm TYPE clike OPTIONAL
        title TYPE clike OPTIONAL
        text  TYPE clike OPTIONAL
        then  TYPE clike OPTIONAL.

    "! what the user entered in the last popup_get_values_sval( ), written
    "! back into the SVAL table by fieldname - an empty table is filled
    "! with one line per field (fieldname, fieldtext, value)
    METHODS popup_values_sval
      CHANGING
        sval TYPE STANDARD TABLE.

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

    "! CALL SCREEN dynnr - the dynpro of dynpro_screen( ) shows, its PBO
    "! before, its PAI for every function; the statements after CALL SCREEN
    "! belong into after_call_screen( ), which runs when it is left
    "! owner is another report class whose dynpro it is - the screen of a
    "! function group or another program: it shows with the PBO and PAI of
    "! owner, and when its last dynpro is left (SET SCREEN 0) the caller
    "! goes on in after_call_screen( ), the attributes of owner as the
    "! dynpro left them
    METHODS call_screen
      IMPORTING
        dynnr TYPE clike
        owner TYPE REF TO z2ui5_cl_cgui_report OPTIONAL.

    "! SET SCREEN dynnr - the next screen after the PAI; `0` returns to the
    "! screen of CALL SCREEN
    METHODS set_screen
      IMPORTING
        dynnr TYPE clike.

    "! LEAVE TO SCREEN dynnr - SET SCREEN and LEAVE SCREEN at once
    METHODS leave_to_screen
      IMPORTING
        dynnr TYPE clike.

    "! LEAVE SCREEN - the PAI ends, the next screen shows
    METHODS leave_screen.

    "! whether the PAI left the dynpro, or an error message stopped it -
    "! its modules after that do not run
    METHODS screen_left
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the selection screen LOOP AT SCREEN changes outside of
    "! at_selection_screen_output( screen ) - in a FORM or a method of a
    "! local class called from there it is that screen; elsewhere (AT
    "! SELECTION-SCREEN, START-OF-SELECTION) a screen built afresh, whose
    "! changes are not shown - as MODIFY SCREEN outside of PBO is not
    METHODS current_screen
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! the screen of at_selection_screen_output( ) while it runs - cleared
    "! after it, so no roundtrip carries it
    DATA mo_cgui_screen TYPE REF TO z2ui5_cl_cgui_selscreen.

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
    "! USING SELECTION-SCREEN dynnr - the report shows its screen dynnr
    "! (selection_screen_dynnr( )) instead of its selection screen; as_window
    "! - its screen as a dialog box over this one, VIA SELECTION-SCREEN
    "! STARTING AT: Execute shows its output, Back returns here
    METHODS submit
      IMPORTING
        report                 TYPE clike
        values                 TYPE z2ui5_cl_cgui_variant=>ty_t_value OPTIONAL
        via_selection_screen   TYPE abap_bool DEFAULT abap_false
        using_variant          TYPE clike     OPTIONAL
        using_selection_screen TYPE clike     OPTIONAL
        as_window              TYPE abap_bool DEFAULT abap_false.

    "! CALL TRANSACTION code [AND SKIP FIRST SCREEN] - the transaction of
    "! the catalog (set_catalog( )) starts its report class with its
    "! variant, else code is taken as the class; Back returns here.
    "! skip_first runs it straight away with the values - SET PARAMETER ID
    "! fills the fields with a MEMORY ID as before
    "! Inside the Fiori launchpad a transaction of the catalog with an intent
    "! (semantic_object, action) navigates there, the values as its startup
    "! parameters - the shell's history and Back keep working
    METHODS call_transaction
      IMPORTING
        code       TYPE clike
        skip_first TYPE abap_bool DEFAULT abap_false
        values     TYPE z2ui5_cl_cgui_variant=>ty_t_value OPTIONAL.

    "! the intent semantic_object-action of the Fiori launchpad, the values
    "! as its startup parameters (each parameter, the first single value of
    "! each select-option); outside the launchpad the transaction of the
    "! catalog with this intent starts
    METHODS call_intent
      IMPORTING
        semantic_object TYPE clike
        action          TYPE clike DEFAULT `display`
        values          TYPE z2ui5_cl_cgui_variant=>ty_t_value OPTIONAL.

    "! SET PARAMETER ID - kept in the browser's local storage for every
    "! report (there is no SAP memory on ABAP Cloud)
    METHODS set_parameter_id
      IMPORTING
        id    TYPE clike
        value TYPE any.

    "! GET PARAMETER ID - the user's parameter (SU3), else the customizing
    "! parameter of the installation (SPRO), else its system parameter
    "! (set_system_parameters( ))
    METHODS get_parameter_id
      IMPORTING
        id            TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the system parameters of the installation - what GET PARAMETER ID
    "! answers for an ID that neither the user nor the customizing sets.
    "! Given in code, the same for every user: set them in initialization( )
    "! (or in a common superclass of the installation's reports)
    METHODS set_system_parameters
      IMPORTING
        values TYPE z2ui5_if_client=>ty_t_name_value.

    "! may the user maintain the customizing parameters - SPRO in the
    "! command field. abap_false unless redefined: redefine it with the
    "! AUTHORITY-CHECK the installation asks for its customizing
    METHODS authority_check_customizing
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! REPORT ... LINE-COUNT n - the list breaks into pages of n lines
    METHODS set_line_count
      IMPORTING
        val TYPE i.

    "! SET PF-STATUS - the functions of the toolbar of the output; each
    "! arrives in at_user_command( ) with its name. shortcuts are the
    "! function keys of the status, excluding the functions left out
    "! (SET PF-STATUS ... EXCLUDING) - a table of names of any character type
    METHODS set_pf_status
      IMPORTING
        functions TYPE z2ui5_cl_cgui_alv=>ty_t_function
        excluding TYPE ANY TABLE   OPTIONAL
        shortcuts TYPE ty_t_shortcut OPTIONAL.

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

    "! keep the selection variants in store instead of table Z2UI5_T_19
    "! (z2ui5_cl_cgui_variant_db, the default) - set it in initialization( ).
    "! Without a store the variants are kept in the browser's local storage
    METHODS set_variant_store
      IMPORTING
        store TYPE REF TO z2ui5_if_cgui_variants OPTIONAL.

    "! keep the ALV layouts in store instead of table Z2UI5_T_18
    "! (z2ui5_cl_cgui_layout_db, the default) - set it in initialization( ).
    "! Without a store the layouts are kept with the selection variants
    METHODS set_layout_store
      IMPORTING
        store TYPE REF TO z2ui5_if_cgui_layouts OPTIONAL.

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
    " the title the launchpad shell shows - set again when it changed
    DATA mv_cgui_title_shell   TYPE string.
    DATA mo_cgui_list          TYPE REF TO z2ui5_cl_cgui_list.
    DATA mo_cgui_alv           TYPE REF TO z2ui5_cl_cgui_alv.
    DATA mo_cgui_tree          TYPE REF TO z2ui5_cl_cgui_tree.
    " per row of mr_cgui_alv_page the row of the table it comes from
    DATA mt_cgui_alv_index     TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    " paged: the rows of the table the grid shows, in its order - its
    " windows are loaded from it (alv_window_load( ))
    DATA mt_cgui_alv_order     TYPE z2ui5_cl_cgui_alv=>ty_t_index.

    DATA mv_cgui_alv_name      TYPE string.
    DATA mt_cgui_level         TYPE ty_t_cgui_level.
    DATA mt_cgui_field         TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA mt_cgui_msg           TYPE ty_t_cgui_msg.
    DATA mv_cgui_prefill TYPE abap_bool.
    " set_draft( ): on, what was kept last, and a draft restored at the start
    DATA mv_cgui_draft          TYPE abap_bool.
    DATA mv_cgui_draft_last     TYPE string.
    DATA mv_cgui_draft_restored TYPE abap_bool.
    DATA mo_cgui_job     TYPE REF TO z2ui5_if_cgui_job.
    DATA mo_cgui_catalog TYPE REF TO z2ui5_if_cgui_catalog.
    " the customizing parameters (spa_load( ), SPRO) and the system ones
    " (set_system_parameters( )) - ID=value lines and a table
    DATA mv_cgui_spa_cust   TYPE string.
    DATA mt_cgui_spa_system TYPE z2ui5_if_client=>ty_t_name_value.
    DATA mo_cgui_app_log TYPE REF TO z2ui5_if_cgui_log.
    DATA mo_cgui_tree_handler TYPE REF TO z2ui5_if_cgui_tree_events.
    DATA mv_cgui_fresh_off TYPE abap_bool.
    TYPES:
      BEGIN OF ty_s_cgui_fresh,
        name  TYPE string,
        kind  TYPE abap_typekind,
        " a copy of the value - an object or data reference as the reference
        value TYPE REF TO data,
        obj   TYPE REF TO object,
        dref  TYPE REF TO data,
      END OF ty_s_cgui_fresh.
    TYPES ty_t_cgui_fresh TYPE STANDARD TABLE OF ty_s_cgui_fresh WITH DEFAULT KEY.
    "! the global data of the report after initialization( ) - set_fresh_start( )
    DATA mt_cgui_fresh TYPE ty_t_cgui_fresh.
    DATA ms_cgui_transport TYPE z2ui5_cl_cgui_transport=>ty_s_result.
    DATA mv_cgui_cmd_on  TYPE abap_bool.
    " the message boxes of _msg_box( ) - shown at the end of the roundtrip
    DATA mt_cgui_box           TYPE ty_t_cgui_msg.
    " the messages of the run, I, W, E and A - what the message popover
    " lists; kept while the user picks one of them
    DATA mt_cgui_log           TYPE ty_t_cgui_msg.
    " W, E or A came in a roundtrip that opened a popup - the popover opens
    " when the screen shows again, the log stays until then
    DATA mv_cgui_log_later     TYPE abap_bool.
    " every message of the run, S included - what cgui_run_in_background( )
    " returns
    DATA mt_cgui_run_msg       TYPE ty_t_cgui_msg.
    DATA mv_cgui_stop          TYPE abap_bool.
    " the run is on: a control created now is on the list it writes
    DATA mv_cgui_in_run        TYPE abap_bool.
    " leave_to_selection_screen( ) during the run - LEAVE PROGRAM, LEAVE TO
    " SCREEN 0: no END-OF-SELECTION, no list
    DATA mv_cgui_left          TYPE abap_bool.
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
    " at_line_selection( ) / at_link_click( ) runs - read_list( ) is the
    " list clicked
    DATA mv_cgui_on_line       TYPE abap_bool.
    " at_user_command( ) runs on the output: what it writes, the ALV or the
    " tree it shows is the next level - opened by the first of them
    " (mv_cgui_level_new), so that up to there the event works on the list
    " shown
    DATA mv_cgui_on_command    TYPE abap_bool.
    DATA mv_cgui_level_new     TYPE abap_bool.
    " the run ended on the selection screen: the classic report restarts
    " after the event (restart_pending( ))
    DATA mv_cgui_restart       TYPE abap_bool.
    " START-OF-SELECTION called a dynpro or opened a popup that answers
    " with a user command: END-OF-SELECTION and the list follow when the
    " dynpro returns or the answer comes (run_answer_output( ))
    DATA mv_cgui_run_wait      TYPE abap_bool.
    " the method a popup with then calls back with its answer
    DATA mv_cgui_then          TYPE string.
    DATA mv_cgui_on_field      TYPE string.
    DATA mv_cgui_variant       TYPE string.
    DATA mv_cgui_variant_start TYPE string.
    DATA mv_cgui_variant_url   TYPE abap_bool.
    " the store of the selection variants - z2ui5_cl_cgui_variant_db unless
    " set_variant_store( ) named another one or none (mv_cgui_store_none:
    " the browser's local storage)
    DATA mo_cgui_store         TYPE REF TO z2ui5_if_cgui_variants.
    DATA mv_cgui_store_none    TYPE abap_bool.
    " the store of the ALV layouts - z2ui5_cl_cgui_layout_db unless
    " set_layout_store( ) named another one or none (mv_cgui_lay_none)
    DATA mo_cgui_lay_store     TYPE REF TO z2ui5_if_cgui_layouts.
    DATA mv_cgui_lay_none      TYPE abap_bool.
    DATA mt_cgui_vrm           TYPE ty_t_cgui_vrm.
    DATA mt_cgui_url           TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA mt_cgui_submit        TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA mv_cgui_called        TYPE abap_bool.
    " SUBMIT ... USING SELECTION-SCREEN dynnr, and the dialog box of
    " submit( as_window ) - shown or not
    DATA mv_cgui_using_dynnr   TYPE string.
    DATA mv_cgui_as_window     TYPE abap_bool.
    DATA mv_cgui_as_window_on  TYPE abap_bool.
    DATA mv_cgui_skip          TYPE abap_bool.
    DATA mv_cgui_skipped       TYPE abap_bool.
    DATA mv_cgui_auto_exec     TYPE abap_bool.
    DATA mv_cgui_denied        TYPE abap_bool.

    DATA mv_cgui_batch         TYPE abap_bool.
    DATA mv_cgui_answer        TYPE string.
    " popup_to_decide_list( ): the line of the table each option stands for -
    " lines with HIDE or INACTIVE are no option
    TYPES temp3_dc62f61289 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA mt_cgui_decide_line   TYPE temp3_dc62f61289.
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
    DATA mt_cgui_pf_keys       TYPE ty_t_shortcut.
    DATA mv_cgui_line_count    TYPE i.
    DATA mt_cgui_pf            TYPE z2ui5_cl_cgui_alv=>ty_t_function.
    DATA mt_cgui_fkey          TYPE z2ui5_cl_cgui_selscreen=>ty_t_function_key.
    " the variant attributes of the fields shown: not ready for input, hidden
    DATA mt_cgui_var_protect   TYPE string_table.
    DATA mt_cgui_var_hide      TYPE string_table.
    " the files the user uploaded (z2ui5_cl_cgui_frontend=>gui_upload( )
    " reads them), the names file_open_dialog( ) answers on its second run
    " and what runs again after the upload: the F4 of mv_cgui_pending_field
    " or Execute
    DATA mt_cgui_file          TYPE z2ui5_cl_cgui_file=>ty_t_file.
    " the dynpro shown (CALL SCREEN), the screens it returns to, the next
    " screen of the PAI and whether the PAI left it
    DATA mv_cgui_dynpro        TYPE string.
    " the subscreens the PBO called into the areas of the dynpro
    DATA mt_cgui_subscreen     TYPE ty_t_cgui_subscreen.
    " the table control whose lines mt_cgui_tc_row holds
    DATA mv_cgui_tc            TYPE string.
    " HTMLFrame of the frontend: initial not yet asked, X there, - not there
    DATA mv_cgui_html_frame    TYPE c LENGTH 1.
    DATA mt_cgui_dynpro_stack  TYPE ty_t_cgui_call.
    " call_screen( owner = ) of another class: the dynpro the caller called -
    " when it is left, the owner returns to the caller
    DATA mv_cgui_owner_dynnr   TYPE string.
    DATA mv_cgui_dynpro_next   TYPE string.
    DATA mv_cgui_dynpro_left   TYPE abap_bool.
    DATA mt_cgui_file_pick     TYPE string_table.
    DATA mv_cgui_file_rerun    TYPE string.

  PRIVATE SECTION.
    "! the controls of a container (or the control) id into node
    METHODS gui_render
      IMPORTING
        id   TYPE i
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! an event of the browser for the control id
    METHODS gui_event
      IMPORTING
        id    TYPE i
        event TYPE string
        value TYPE string
        post  TYPE string OPTIONAL.

    "! the grid id shows in place of the one that shows
    METHODS grid_show
      IMPORTING
        id TYPE i.

    "! whether the control id and its containers are still there
    METHODS gui_alive
      IMPORTING
        id            TYPE i
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! a copy of the data val refers to
    CLASS-METHODS grid_copy
      IMPORTING
        val           TYPE REF TO data
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the ALV into node - on the page of the output, or in the container of
    "! the grid that shows it
    METHODS alv_render
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the docking containers of the screen dynnr
    METHODS gui_docked
      IMPORTING
        dynnr TYPE string
        node  TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! what the view of the controls reads of the report, by reference
    METHODS gui_ctx
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_view=>ty_s_ctx.


    CONSTANTS:
      BEGIN OF cs_screen,
        selection TYPE string VALUE `SELECTION`,
        output    TYPE string VALUE `OUTPUT`,
        dynpro    TYPE string VALUE `DYNPRO`,
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
        file           TYPE string VALUE `FILE`,
        palette        TYPE string VALUE `PALETTE`,
        su3            TYPE string VALUE `SU3`,
        spro           TYPE string VALUE `SPRO`,
        transport      TYPE string VALUE `TRANSPORT`,
        screen         TYPE string VALUE `SCREEN`,
      END OF cs_pending.

    TYPES:
      " character types - the popup heads its columns with their names
      BEGIN OF ty_s_variant_row,
        variant TYPE c LENGTH 40,
        values  TYPE c LENGTH 255,
      END OF ty_s_variant_row.
    TYPES ty_t_variant_row TYPE STANDARD TABLE OF ty_s_variant_row WITH DEFAULT KEY.

    METHODS on_init.

    "! the memory of the report at the start: the store of the variants,
    "! the parameter IDs, the variant of the URL or of initialization( ),
    "! the draft
    METHODS on_init_memory.

    METHODS on_event.

    "! before an event: the input and the selection of the grid, the ticks
    "! of the tree and the inputs of the list back into their tables
    METHODS on_event_sync.

    "! an event of the tree - handled when it was one
    METHODS on_event_tree
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the events of the selection screen and the popup screen: Execute,
    "! Back, the storage, a select-option, F4, F1, the background job
    METHODS on_event_selection
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the events that open a popup or come back from one: the messages,
    "! the variants
    METHODS on_event_popup
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the events of the output: Print, the command field, the palette, a
    "! line of the list, a row or cell of the ALV
    METHODS on_event_output
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the events of the SAP GUI controls and of a dynpro
    METHODS on_event_gui
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS on_navigated.

    "! back from a popup of the variants: the one picked is loaded, saved
    "! or deleted after a confirmation
    METHODS on_navigated_variant
      IMPORTING
        kind TYPE string.

    "! back from a popup to decide or a popup of values: its answer and
    "! its fields
    METHODS popup_answer_take.

    METHODS on_back.

    METHODS on_line_selection
      IMPORTING
        row    TYPE i
        hide   TYPE string
        column TYPE string OPTIONAL
        link   TYPE abap_bool DEFAULT abap_false.

    METHODS level_push.

    METHODS level_pop.

    "! the next level, when an event on the output opens one now
    "! (mv_cgui_level_new)
    METHODS level_open.

    "! after an event that may have started a level: a level that shows
    "! nothing is dropped, the list shows again; CALL SCREEN keeps it for
    "! the return; the selection screen has no levels
    METHODS level_settle.

    "! the current level shows nothing - no list content, ALV, tree or
    "! control of its own
    METHODS level_empty
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the controls on the list created at the level shown and after it
    "! (from: the controls there were) are gone
    METHODS level_free
      IMPORTING
        from TYPE i.

    "! the controls freed are gone for good: their objects, texts, HTML,
    "! buttons, handlers and grids no longer travel with the draft and the
    "! response - the line of mt_cgui_gui stays, its index is the id
    METHODS gui_release.

    "! the run ended on the selection screen (mv_cgui_restart): the classic
    "! report restarts - its data as after INITIALIZATION, no output
    METHODS restart_pending.

    "! the output of the last run is gone
    METHODS output_clear.

    "! the layout of the selection screen the report shows: its own, or the
    "! screen of SUBMIT ... USING SELECTION-SCREEN
    METHODS selection_screen_layout
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! the name of the user's draft - a variant of the report
    METHODS intent_navigate
      IMPORTING
        semantic_object TYPE clike
        action          TYPE clike
        values          TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    "! the values of the selection screen kept as the draft, when they
    "! changed since it was kept last
    METHODS draft_keep.

    "! the draft restored at the start - before the start variant
    METHODS draft_restore.

    "! the draft gone - used up by Execute, or discarded
    METHODS draft_drop.

    "! Discard Draft: the draft gone, the fields as initialization( ) sets them
    METHODS draft_discard.

    "! the selection screen prepared for rendering - its values, listboxes,
    "! AT SELECTION-SCREEN OUTPUT, the history
    METHODS selection_screen_prepare
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! submit( as_window ): the selection screen as a dialog box over the
    "! report that called this one
    METHODS view_display_submit_window.

    METHODS screen_fields
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    "! abap_true when selection_screen( ) declares nothing - no field, no
    "! comment, no button: a classic report without a selection screen goes
    "! on with START-OF-SELECTION right after INITIALIZATION
    METHODS screen_empty
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! abap_true when field is a field of the selection screen or of the
    "! popup screen - the attribute name an event argument carries
    "! a field of the screen the user sees and may change - of kind
    "! (z2ui5_cl_cgui_selscreen=>cs_field_kind) when given
    METHODS screen_field_check
      IMPORTING
        field         TYPE string
        kind          TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! upper case and ALPHA of the parameters among fields, as SAP GUI
    "! converts the input
    METHODS input_convert
      IMPORTING
        fields TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    "! the inputs of the roundtrip: the select-option buffer into the ranges,
    "! character fields to upper case
    METHODS input_sync.

    METHODS so_buffer_prepare
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS tab_binding_prepare
      IMPORTING
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS memory_id_store.

    METHODS on_storage_loaded.

    "! SU3 in the command field: the user's parameters in a popup to change
    METHODS su3_open.
    METHODS su3_result.

    "! SPRO in the command field: the customizing parameters in a popup to
    "! change - with authority_check_customizing( ) and a server store only
    METHODS spro_open.
    METHODS spro_result.

    METHODS auto_execute.

    METHODS variant_popup
      IMPORTING
        kind TYPE string.

    "! Save as Variant: the name, the sharing, the protected and hidden
    "! fields, the dynamic dates - current is the variant of that name
    METHODS variant_popup_save
      IMPORTING
        current TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    "! a dynamic date for every date of the screen - the fields of the
    "! popup and the values of their listboxes
    METHODS variant_popup_dynamic
      IMPORTING
        current TYPE z2ui5_cl_cgui_variant=>ty_s_variant
      CHANGING
        fields  TYPE z2ui5_cl_cgui_popup=>ty_t_field
        listbox TYPE z2ui5_cl_cgui_popup=>ty_t_listbox.

    METHODS variant_selected
      RETURNING
        VALUE(result) TYPE string.

    METHODS variant_save
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_popup.

    METHODS variant_delete
      IMPORTING
        name TYPE string.

    "! the state of the memory of the report (z2ui5_cl_cgui_memory) for one
    "! call: references to the attributes it reads and writes, built now
    "! and kept by nobody
    METHODS command_ctx
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_command=>ty_s_ctx.

    METHODS memory_ctx
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_memory=>ty_s_ctx.

    METHODS variant_key
      RETURNING
        VALUE(result) TYPE string.

    METHODS variant_from_url
      RETURNING
        VALUE(result) TYPE string.

    METHODS on_execute.

    "! the run - or, with end, its end after a dynpro or a popup of
    "! START-OF-SELECTION
    METHODS run
      IMPORTING
        end           TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS run_steps
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the run after START-OF-SELECTION: END-OF-SELECTION, the page footer
    "! and whether there is a list
    METHODS run_end
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the run waits: for a dynpro it called, a dynpro of another class, a
    "! popup that answers with a user command
    METHODS run_waits
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! what follows a run: the output, or the restart on the selection
    "! screen
    METHODS run_done
      IMPORTING
        ok TYPE abap_bool.

    METHODS check_screen
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! every required field of fields filled - one message at each empty
    "! one; without fields the ones of the selection screen
    METHODS check_obligatory
      IMPORTING
        fields        TYPE z2ui5_cl_cgui_selscreen=>ty_t_field OPTIONAL
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

    "! the value picked in the value help: column col of its row, else the
    "! first column - unbound when there is none
    METHODS f4_row_value
      IMPORTING
        row           TYPE REF TO data
        col           TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! a parameter: the value picked into the field
    METHODS f4_result_value
      IMPORTING
        field TYPE REF TO data
        row   TYPE REF TO data
        col   TYPE string.

    "! the upper limit of a select-option: the first line becomes an
    "! interval up to the value picked
    METHODS f4_result_high
      IMPORTING
        range TYPE REF TO data
        row   TYPE REF TO data
        col   TYPE string.

    "! a select-option: every row picked becomes a line I EQ
    METHODS f4_result_rows
      IMPORTING
        range TYPE REF TO data
        rows  TYPE REF TO data
        col   TYPE string.

    METHODS value_help_ddic
      IMPORTING
        field TYPE string.

    "! the value help of a CDS entity named at the field - shown when it
    "! has rows
    METHODS value_help_entity
      IMPORTING
        field         TYPE string
        pattern       TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! MATCHCODE OBJECT - the search help named at the field
    METHODS value_help_matchcode
      IMPORTING
        field         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! what the type of the field knows: its fixed values, the search help
    "! of its data element, its value table with the texts
    METHODS value_help_descr
      IMPORTING
        field         TYPE string
        descr         TYPE REF TO cl_abap_typedescr
        pattern       TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE abap_bool.

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
        VALUE(result) TYPE REF TO z2ui5_if_cgui_layouts.

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

    "! a function on the dynpro: its PAI, then the next screen
    METHODS on_dynpro_command
      IMPORTING
        ucomm TYPE string.

    "! a screen number as four digits - 100 is 0100
    METHODS dynnr_norm
      IMPORTING
        dynnr         TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! back from the dynpro to the screen of CALL SCREEN
    METHODS dynpro_return
      IMPORTING
        dynnr TYPE string.

    "! the dynpro shown - dynpro_screen( ) and its PBO, before the page is
    "! built: SET TITLEBAR and SET PF-STATUS of the PBO are its title and
    "! its toolbar
    METHODS view_display_dynpro
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! the files the user picked in the upload dialog of upload_popup( ) -
    "! stored, and the F4 or Execute that opened it run again
    METHODS file_result
      IMPORTING
        field TYPE string.

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

    "! the request of the paged grid (cs_event-rows): the next rows after
    "! the ones the browser holds, or the first ones of a new sort or filter
    METHODS alv_window.

    "! rows skip + 1 to skip + top of mt_cgui_alv_order into the copy the
    "! paged grid shows - the ones before stay
    METHODS alv_window_load
      IMPORTING
        skip TYPE i
        top  TYPE i.

    "! the rows of tab the order of the paged grid holds (mt_cgui_alv_order)
    "! - tab itself when no filter leaves one out; a copy of this
    "! roundtrip, not kept in the draft
    METHODS alv_order_rows
      IMPORTING
        tab           TYPE REF TO data
      RETURNING
        VALUE(result) TYPE REF TO data.

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

    "! the printout of the output - a PDF to the browser
    METHODS on_print.

    "! Execute in Background: the checks of Execute, then the job
    METHODS on_background.

    "! the global data of the report after initialization( ) - a copy of
    "! each public attribute the report declares, not the runtime's
    METHODS fresh_keep.

    "! Back from the output: the copies back, initialization( ) again, the
    "! fields of the selection screen with the input they had
    METHODS fresh_restart.

    "! a function of the screen, as a button or an OK code would run it
    METHODS user_command
      IMPORTING
        ucomm TYPE string.

    "! the event a popup leaves with - ucomm, or with then the one of the
    "! callback (kept in mv_cgui_then)
    METHODS popup_event
      IMPORTING
        ucomm         TYPE clike
        then          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the rest of a run on the selection screen wrote something: the
    "! output shows - unless it opened the next popup
    METHODS run_answer_output.

    "! start a report: code - a transaction of the catalog or a report
    "! class; new_window - in a new browser tab
    METHODS okcode_start
      IMPORTING
        code       TYPE string
        new_window TYPE abap_bool.

    "! the command palette - the transactions and the functions of the
    "! screen in a popup to search
    METHODS palette_open.
    METHODS palette_result.

    METHODS print_lines
      RETURNING
        VALUE(result) TYPE string_table.

    "! VALUE CHECK - with OBLIGATORY the checks of the screen itself, before
    "! any event of the report
    METHODS check_values
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! AT SELECTION-SCREEN ON field, field by field in the order of the
    "! screen; ON BLOCK after the last field of the block (an inner block
    "! before the outer one), ON RADIOBUTTON GROUP after the last button
    "! of the group - the order of the PAI of the classic selection screen
    METHODS check_events
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS on_alv_event
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! F4 of a cell of the grid - the value help of the report for it
    METHODS alv_event_f4.

    "! the details of the selected row of the grid in a popup
    METHODS alv_event_details
      IMPORTING
        full TYPE REF TO data.

    "! an event of the grid the ALV handles itself - the export takes the
    "! table of the report, the selection the table the grid shows
    METHODS alv_event_forward
      IMPORTING
        event TYPE string.

    METHODS view_display.

    TYPES:
      "! the main button of the footer - Execute, Back or Continue
      BEGIN OF ty_s_cgui_button,
        text  TYPE string,
        icon  TYPE string,
        ucomm TYPE string,
      END OF ty_s_cgui_button.

    "! the command field and the storage controls of the page
    METHODS view_display_header
      IMPORTING
        page TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the screen shown into the page - the dynpro, the output or the
    "! selection screen - and the main button that goes with it
    METHODS view_display_body
      IMPORTING
        page          TYPE REF TO z2ui5_cl_ui5_view_builder
        dynpro        TYPE REF TO z2ui5_cl_cgui_selscreen
        window        TYPE abap_bool
      RETURNING
        VALUE(result) TYPE ty_s_cgui_button.

    "! the buttons of the footer: the standard functions of the selection
    "! screen, then the function keys and the main button
    METHODS view_display_toolbar
      IMPORTING
        toolbar TYPE REF TO z2ui5_cl_ui5_view_builder
        button  TYPE ty_s_cgui_button.

    "! SELECTION-SCREEN FUNCTION KEY, SET PF-STATUS on the output, Print,
    "! and the main button
    METHODS view_display_toolbar_keys
      IMPORTING
        toolbar TYPE REF TO z2ui5_cl_ui5_view_builder
        button  TYPE ty_s_cgui_button.

    "! after the view: the title of the launchpad shell, SET CURSOR, the
    "! dialog box of WINDOW and the popup screen
    METHODS view_display_after
      IMPORTING
        window TYPE abap_bool.

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

    "! the start variant (set_variant( ), the URL, a transaction) onto the
    "! screen - once; one of the URL that does not exist is a warning
    METHODS variant_start_apply.

    "! a lazy node opened the first time: at_tree_expand_no_children( ),
    "! and EXPAND_EMPTY_FOLDER of the stand-in of cl_salv_tree
    METHODS tree_expand
      IMPORTING
        key TYPE i.

ENDCLASS.


CLASS z2ui5_cl_cgui_report IMPLEMENTATION.

  METHOD z2ui5_if_app~main.
    DATA temp403 LIKE sy-subrc.
    DATA temp28 LIKE sy-subrc.

    me->client = client.
    " cl_gui_frontend_services of the report - its files are the report's
    z2ui5_cl_cgui_frontend=>set_files( me ).
    z2ui5_cl_cgui_gui=>set_report( me ).
    cgui_statics_restore( ).
    at_roundtrip_start( ).
    CLEAR: mt_cgui_msg, mt_cgui_box.
    mv_cgui_nav = abap_false.
    " the messages of the run stay while the popover opens and the user
    " picks one of them
    IF client->get_event( ) <> cs_ucomm-message_focus AND client->get_event( ) <> cs_ucomm-messages_open
        AND mv_cgui_log_later = abap_false.
      CLEAR mt_cgui_log.
    ENDIF.

    IF client->check_on_init( ) IS NOT INITIAL.
      on_init( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      " back from a popup or a called report - a popup that confirms returns
      " with its ucomm as event, handled like any other user command
      on_navigated( ).
      IF client->get_event( ) IS NOT INITIAL.
        on_event( ).
      ENDIF.
      restart_pending( ).
      IF mv_cgui_nav = abap_false.
        view_display( ).
      ENDIF.
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      input_sync( ).
      on_event( ).
      restart_pending( ).
      IF mv_cgui_nav = abap_false.
        view_display( ).
      ENDIF.
    ENDIF.

    " set_draft( ): what is on the selection screen now is the draft
    IF mv_cgui_draft = abap_true AND mv_cgui_screen = cs_screen-selection
        AND client->check_on_event( ) IS NOT INITIAL AND mt_cgui_field IS NOT INITIAL.
      draft_keep( ).
    ENDIF.

    gui_release( ).
    messages_display( ).
    cgui_statics_keep( ).

    " the end of the dialog step: a classic report's database changes are
    " committed here implicitly, and abap2UI5 rolls back what an app that is
    " not stateful leaves open after main( ) - so the report commits, unless
    " a termination message (A, X) rolled the step back as it does in SAP GUI.
    " An exception never gets here: abap2UI5 rolls the LUW back

    READ TABLE mt_cgui_msg WITH KEY type = `A` TRANSPORTING NO FIELDS.
    temp403 = sy-subrc.

    READ TABLE mt_cgui_msg WITH KEY type = `X` TRANSPORTING NO FIELDS.
    temp28 = sy-subrc.
    IF NOT temp403 = 0 AND NOT temp28 = 0.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~list.

    result = list( ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~cursor.

    MOVE-CORRESPONDING get_cursor( ) TO result.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tree.

    result = tree( ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tree_handler.

    mo_cgui_tree_handler = handler.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_add.

    DATA ls_control LIKE control.
      FIELD-SYMBOLS <old> LIKE LINE OF mt_cgui_gui.
    ls_control = control.
    ls_control-id = lines( mt_cgui_gui ) + 1.
    " a docking container sits on the screen it is created for, and so
    " does a control on the screen itself (cl_gui_container=>default_screen)
    IF ls_control-parent IS INITIAL AND ls_control-name IS INITIAL AND ls_control-dynnr IS INITIAL.
      ls_control-dynnr = z2ui5_cl_cgui_view=>screen( gui_ctx( ) ).
    ELSEIF ls_control-dynnr IS NOT INITIAL AND ls_control-dynnr CO `0123456789`.
      ls_control-dynnr = dynnr_norm( ls_control-dynnr ).
    ENDIF.
    " a custom control area holds one container - a new one (the PBO of a
    " run that starts afresh) replaces the one before
    IF ls_control-kind = z2ui5_if_cgui_gui=>cs_kind-container AND ls_control-parent IS INITIAL
        AND ls_control-name IS NOT INITIAL.

      LOOP AT mt_cgui_gui ASSIGNING <old>
           WHERE kind = z2ui5_if_cgui_gui=>cs_kind-container AND parent = 0 AND name = ls_control-name.
        <old>-freed = abap_true.
      ENDLOOP.
    ENDIF.
    INSERT ls_control INTO TABLE mt_cgui_gui.
    INSERT object INTO TABLE mt_cgui_gui_obj.
    result = ls_control-id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_get.

    READ TABLE mt_cgui_gui INTO result INDEX id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_set.

    MODIFY mt_cgui_gui FROM control INDEX control-id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~handlers_get.

    DATA ls_handler LIKE LINE OF mt_cgui_handler.
      DATA temp404 TYPE z2ui5_if_cgui_gui=>ty_s_handler.
      DATA ls_result LIKE temp404.
    LOOP AT mt_cgui_handler INTO ls_handler.

      CLEAR temp404.
      temp404-id = ls_handler-id.
      temp404-event = ls_handler-event.
      temp404-class = ls_handler-class.
      temp404-method = ls_handler-method.

      ls_result = temp404.
      IF ls_handler-object IS NOT INITIAL.
        READ TABLE mt_cgui_handler_obj INTO ls_result-handler INDEX ls_handler-object.
      ENDIF.
      INSERT ls_result INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~handlers_set.
    DATA ls_handler LIKE LINE OF handlers.
      DATA temp405 TYPE ty_s_cgui_handler.
      DATA ls_line LIKE temp405.

    CLEAR mt_cgui_handler.
    CLEAR mt_cgui_handler_obj.

    LOOP AT handlers INTO ls_handler.

      CLEAR temp405.
      temp405-id = ls_handler-id.
      temp405-event = ls_handler-event.
      temp405-class = ls_handler-class.
      temp405-method = ls_handler-method.

      ls_line = temp405.
      IF ls_handler-handler IS BOUND.
        READ TABLE mt_cgui_handler_obj TRANSPORTING NO FIELDS WITH KEY table_line = ls_handler-handler.
        IF sy-subrc = 0.
          ls_line-object = sy-tabix.
        ELSE.
          INSERT ls_handler-handler INTO TABLE mt_cgui_handler_obj.
          ls_line-object = lines( mt_cgui_handler_obj ).
        ENDIF.
      ENDIF.
      INSERT ls_line INTO TABLE mt_cgui_handler.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_display.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <copy> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <part> TYPE any.
    FIELD-SYMBOLS <grid> TYPE z2ui5_if_cgui_gui=>ty_s_grid.
      DATA temp406 TYPE z2ui5_if_cgui_gui=>ty_s_grid.
    DATA lo_alv TYPE REF TO z2ui5_cl_cgui_alv.
      DATA lt_function TYPE z2ui5_if_cgui_gui=>ty_t_button.
      DATA ls_function LIKE LINE OF lt_function.
        DATA temp407 LIKE sy-subrc.
        DATA temp408 TYPE z2ui5_if_cgui_gui=>ty_s_button-icon.

    " a grid that does not show: it keeps what it is displayed with itself,
    " its container offers to show it - so does the first display of a
    " grid while another one shows
    IF mv_cgui_grid <> id AND mv_cgui_grid IS NOT INITIAL AND gui_alive( mv_cgui_grid ) = abap_true
        AND ( tab IS NOT BOUND OR first = abap_true ).
      RETURN.
    ENDIF.


    READ TABLE mt_cgui_grid ASSIGNING <grid> WITH KEY id = id.
    IF sy-subrc <> 0.

      CLEAR temp406.
      temp406-id = id.
      INSERT temp406 INTO TABLE mt_cgui_grid ASSIGNING <grid>.
    ENDIF.
    " another grid shows now - the field catalog and the layout are its
    IF mv_cgui_grid <> id.
      CLEAR: mr_cgui_grid_fieldcat, mr_cgui_grid_layout.
    ENDIF.
    " a copy of the field catalog and the layout - for get_frontend_*( )
    IF fieldcat IS BOUND.
      mr_cgui_grid_fieldcat = grid_copy( fieldcat ).
    ENDIF.
    IF layout IS BOUND.
      mr_cgui_grid_layout = grid_copy( layout ).
    ENDIF.


    IF mv_cgui_grid = id AND mo_cgui_alv IS BOUND.
      " the grid shows: its table anew, the ALV keeps what it has
      lo_alv = mo_cgui_alv.
      IF tab IS BOUND.
        ASSIGN tab->* TO <tab>.
        CREATE DATA mr_cgui_alv LIKE <tab>.
        ASSIGN mr_cgui_alv->* TO <copy>.
        <copy> = <tab>.
        CLEAR: mr_cgui_alv_box, mr_cgui_alv_page, mt_cgui_alv_index, mt_cgui_alv_order.
      ENDIF.
    ELSEIF tab IS BOUND.
      ASSIGN tab->* TO <tab>.
      lo_alv = alv( <tab> )->set_line_selection( ).
      " a new ALV - the functions of the toolbar are added to it anew
      CLEAR <grid>-functions.
    ELSE.
      RETURN.
    ENDIF.
    IF fieldcat IS BOUND.
      ASSIGN fieldcat->* TO <part>.
      lo_alv->set_fieldcat( <part> ).
    ENDIF.
    IF layout IS BOUND.
      ASSIGN layout->* TO <part>.
      lo_alv->set_layout_classic( <part> ).
    ENDIF.
    IF sort IS BOUND.
      ASSIGN sort->* TO <part>.
      lo_alv->set_sort_classic( <part> ).
    ENDIF.
    " the functions of the toolbar - each one once
    IF functions IS BOUND.

      ASSIGN functions->* TO <part>.
      lt_function = <part>.

      LOOP AT lt_function INTO ls_function WHERE fcode IS NOT INITIAL AND type <> 3.

        READ TABLE <grid>-functions WITH KEY fcode = ls_function-fcode TRANSPORTING NO FIELDS.
        temp407 = sy-subrc.
        IF temp407 = 0.
          CONTINUE.
        ENDIF.

        IF ls_function-icon CP `sap-icon://*`.
          temp408 = ls_function-icon.
        ELSE.
          CLEAR temp408.
        ENDIF.
        lo_alv->add_function( name    = ls_function-fcode
                              text    = ls_function-text
                              icon    = temp408
                              tooltip = ls_function-quickinfo ).
        INSERT ls_function INTO TABLE <grid>-functions.
      ENDLOOP.
    ENDIF.
    mv_cgui_grid = id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_get.

    READ TABLE mt_cgui_grid INTO result WITH KEY id = id.
    IF id = mv_cgui_grid.
      result-fieldcat = mr_cgui_grid_fieldcat.
      result-layout = mr_cgui_grid_layout.
      result-shown = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~grid_selected.

    result = get_selected_rows( ).

  ENDMETHOD.

  METHOD grid_show.

    DATA lo_object TYPE REF TO object.
    DATA temp409 TYPE REF TO z2ui5_cl_cgui_alv_grid.
    DATA lo_grid LIKE temp409.
    READ TABLE mt_cgui_gui_obj INTO lo_object INDEX id.
    IF sy-subrc <> 0 OR gui_alive( id ) = abap_false.
      RETURN.
    ENDIF.

    temp409 ?= lo_object.

    lo_grid = temp409.
    " the grid shown so far no longer is - this one takes its place
    CLEAR mv_cgui_grid.
    lo_grid->show( ).

  ENDMETHOD.

  METHOD gui_alive.

    DATA lv_id LIKE id.
      DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    lv_id = id.
    WHILE lv_id IS NOT INITIAL.

      READ TABLE mt_cgui_gui INTO ls_control INDEX lv_id.
      IF sy-subrc <> 0 OR ls_control-freed = abap_true.
        RETURN.
      ENDIF.
      lv_id = ls_control-parent.
    ENDWHILE.
    result = abap_true.

  ENDMETHOD.

  METHOD grid_copy.

    FIELD-SYMBOLS <from> TYPE any.
    FIELD-SYMBOLS <to>   TYPE any.

    ASSIGN val->* TO <from>.
    CREATE DATA result LIKE <from>.
    ASSIGN result->* TO <to>.
    <to> = <from>.

  ENDMETHOD.

  METHOD call_subscreen.

    DATA temp410 TYPE string.
    DATA lv_area TYPE string.
    DATA temp411 TYPE string.
    DATA lv_dynnr TYPE string.
    DATA temp412 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_subscreen.
    temp410 = area.

    lv_area = to_upper( condense( temp410 ) ).

    temp411 = dynnr.

    lv_dynnr = dynnr_norm( condense( temp411 ) ).
    DELETE mt_cgui_subscreen WHERE area = lv_area.
    IF lv_dynnr IS INITIAL OR lv_dynnr = `0000`.
      RETURN.
    ENDIF.

    CLEAR temp412.
    temp412-area = lv_area.
    temp412-dynnr = lv_dynnr.
    INSERT temp412 INTO TABLE mt_cgui_subscreen.
    dynpro_pbo( lv_dynnr ).

  ENDMETHOD.

  METHOD call_subscreen_pai.

    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40
    DATA temp413 TYPE string.
    DATA lv_key TYPE string.
    DATA ls_sub TYPE z2ui5_cl_cgui_report=>ty_s_cgui_subscreen.
    temp413 = area.

    lv_key = to_upper( condense( temp413 ) ).

    READ TABLE mt_cgui_subscreen INTO ls_sub WITH KEY area = lv_key.
    IF sy-subrc = 0.
      dynpro_pai( dynnr = ls_sub-dynnr
                  ucomm = ucomm ).
    ENDIF.

  ENDMETHOD.

  METHOD tablecontrol_begin.

    DATA temp414 TYPE string.
    temp414 = name.
    mv_cgui_tc = to_upper( condense( temp414 ) ).
    CLEAR mt_cgui_tc_row.

  ENDMETHOD.

  METHOD tablecontrol_row.

    DATA ls_row TYPE ty_s_cgui_tc_row.

    DATA temp415 TYPE string.
    DATA lv_value LIKE LINE OF values.
      FIELD-SYMBOLS <cell> TYPE any.
    temp415 = name.
    IF to_upper( condense( temp415 ) ) <> mv_cgui_tc.
      RETURN.
    ENDIF.

    LOOP AT values INTO lv_value.
      IF sy-tabix > cv_cgui_tc_columns.
        EXIT.
      ENDIF.

      ASSIGN COMPONENT sy-tabix OF STRUCTURE ls_row TO <cell>.
      <cell> = lv_value.
    ENDLOOP.
    INSERT ls_row INTO TABLE mt_cgui_tc_row.

  ENDMETHOD.

  METHOD tablecontrol_count.

    DATA temp416 TYPE string.
    temp416 = name.
    IF to_upper( condense( temp416 ) ) = mv_cgui_tc.
      result = lines( mt_cgui_tc_row ).
    ENDIF.

  ENDMETHOD.

  METHOD tablecontrol_cell.

    DATA temp417 TYPE string.
    FIELD-SYMBOLS <row> TYPE z2ui5_cl_cgui_report=>ty_s_cgui_tc_row.
      FIELD-SYMBOLS <cell> TYPE any.
    temp417 = name.
    IF to_upper( condense( temp417 ) ) <> mv_cgui_tc OR col < 1 OR col > cv_cgui_tc_columns.
      RETURN.
    ENDIF.

    READ TABLE mt_cgui_tc_row ASSIGNING <row> INDEX row.
    IF sy-subrc = 0.

      ASSIGN COMPONENT col OF STRUCTURE <row> TO <cell>.
      result = <cell>.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tablecontrol_render.

    z2ui5_cl_cgui_view=>tablecontrol( ctx     = gui_ctx( )
                                          name    = name
                                          title   = title
                                          columns = columns
                                          node    = node ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~subscreen_render.

    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40
    DATA lv_key TYPE string.
    DATA ls_sub TYPE z2ui5_cl_cgui_report=>ty_s_cgui_subscreen.
    DATA lo_sub TYPE REF TO z2ui5_cl_cgui_selscreen.
    lv_key = to_upper( area ).

    READ TABLE mt_cgui_subscreen INTO ls_sub WITH KEY area = lv_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    " the fields of the subscreen, built as those of its dynpro

    lo_sub = z2ui5_cl_cgui_selscreen=>factory( client          = client
                                                     value_help_auto = abap_true ).
    lo_sub->set_gui( me ).
    dynpro_screen( dynnr  = ls_sub-dynnr
                   screen = lo_sub ).
    lo_sub->render( node ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~tabstrip_active.

    FIELD-SYMBOLS <strip> TYPE any.

    DATA lr_strip TYPE REF TO data.
    FIELD-SYMBOLS <tab> TYPE any.
      DATA temp418 TYPE string.
    lr_strip = attri_assign( to_upper( name ) ).
    IF lr_strip IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_strip->* TO <strip>.

    ASSIGN COMPONENT `ACTIVETAB` OF STRUCTURE <strip> TO <tab>.
    IF sy-subrc = 0.

      temp418 = <tab>.
      result = condense( temp418 ).
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~custom_render.

    DATA ls_control LIKE LINE OF mt_cgui_gui.
    LOOP AT mt_cgui_gui INTO ls_control
         WHERE kind = z2ui5_if_cgui_gui=>cs_kind-container AND parent = 0 AND name = name AND freed = abap_false.
      gui_render( id   = ls_control-id
                  node = node ).
    ENDLOOP.

  ENDMETHOD.

  METHOD gui_event.

    DATA lo_object TYPE REF TO object.
    FIELD-SYMBOLS <temp419> LIKE LINE OF mt_cgui_gui.
    DATA temp420 LIKE sy-tabix.
    DATA temp421 TYPE REF TO z2ui5_cl_cgui_gui.
    READ TABLE mt_cgui_gui_obj INTO lo_object INDEX id.


    IF NOT ( sy-subrc <> 0 ) AND NOT ( lo_object IS NOT BOUND ).
      temp420 = sy-tabix.
      READ TABLE mt_cgui_gui INDEX id ASSIGNING <temp419>.
      sy-tabix = temp420.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
    ENDIF.
    IF sy-subrc <> 0 OR lo_object IS NOT BOUND OR <temp419>-freed = abap_true.
      RETURN.
    ENDIF.
    at_gui_event( ).

    temp421 ?= lo_object.
    temp421->dispatch( event = event
                                                   value = value
                                                   post  = post ).

  ENDMETHOD.

  METHOD gui_docked.

    DATA ls_control LIKE LINE OF mt_cgui_gui.
    LOOP AT mt_cgui_gui INTO ls_control
         WHERE parent = 0 AND name IS INITIAL AND dynnr = dynnr AND freed = abap_false.
      gui_render( id   = ls_control-id
                  node = node ).
    ENDLOOP.

  ENDMETHOD.

  METHOD gui_render.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
        DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
        DATA lt_child TYPE z2ui5_if_cgui_gui=>ty_t_control.
        DATA ls_child LIKE LINE OF lt_child.
    READ TABLE mt_cgui_gui INTO ls_control INDEX id.
    IF sy-subrc <> 0 OR ls_control-freed = abap_true OR ls_control-hidden = abap_true.
      RETURN.
    ENDIF.

    CASE ls_control-kind.
      WHEN z2ui5_if_cgui_gui=>cs_kind-container.

        lo_box = z2ui5_cl_cgui_view=>container( ctx  = gui_ctx( )
                                                          id   = id
                                                          node = node ).

        lt_child = z2ui5_cl_cgui_view=>children( ctx = gui_ctx( )
                                                           id  = id ).

        LOOP AT lt_child INTO ls_child.
          gui_render( id   = ls_child-id
                      node = lo_box ).
        ENDLOOP.
      WHEN z2ui5_if_cgui_gui=>cs_kind-grid.
        " the grid the ALV shows - another one offers to show it
        IF mv_cgui_grid = id AND mo_cgui_alv IS BOUND.
          alv_render( node ).
        ELSE.
          z2ui5_cl_cgui_view=>render( ctx  = gui_ctx( )
                                          id   = id
                                          node = node ).
        ENDIF.
      WHEN OTHERS.
        z2ui5_cl_cgui_view=>render( ctx  = gui_ctx( )
                                        id   = id
                                        node = node ).
    ENDCASE.

  ENDMETHOD.

  METHOD gui_ctx.

    CLEAR result.
    result-client = client.
    GET REFERENCE OF mt_cgui_gui INTO result-gui.
    result-objects = mt_cgui_gui_obj.
    GET REFERENCE OF mv_cgui_html_frame INTO result-html_frame.
    result-tc = mv_cgui_tc.
    GET REFERENCE OF mt_cgui_tc_row INTO result-tc_row.
    GET REFERENCE OF mt_cgui_tc_view INTO result-tc_view.
    GET REFERENCE OF mv_cgui_tc_total INTO result-tc_total.
    result-screen = mv_cgui_screen.
    result-dynpro = mv_cgui_dynpro.
    result-in_run = mv_cgui_in_run.

  ENDMETHOD.

  METHOD on_init.
        DATA temp422 TYPE string_table.

    mv_cgui_screen = cs_screen-selection.
    mv_cgui_title = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).

    IF authority_check( ) = abap_false.
      mv_cgui_denied = abap_true.
      message( text = 'You are not authorized to run this report'(001)
               type = `E` ).
      view_display( ).
      RETURN.
    ENDIF.

    " a dynpro another class called: no selection screen, its PBO now
    IF mv_cgui_owner_dynnr IS NOT INITIAL.
      mv_cgui_dynpro = mv_cgui_owner_dynnr.
      mv_cgui_screen = cs_screen-dynpro.
      view_display( ).
      RETURN.
    ENDIF.

    initialization( ).
    fresh_keep( ).

    " SUBMIT ... WITH: the values of the caller after INITIALIZATION
    IF mt_cgui_submit IS NOT INITIAL.
      z2ui5_cl_cgui_variant=>values_set( app    = me
                                         values = mt_cgui_submit ).
    ENDIF.

    on_init_memory( ).

    " the fields of the screen - what the URL and MEMORY ID may fill
    mt_cgui_field = screen_fields( ).
    z2ui5_cl_cgui_memory=>memory_id_apply( memory_ctx( ) ).
    z2ui5_cl_cgui_command=>url_values_get( command_ctx( ) ).
    z2ui5_cl_cgui_command=>url_values_apply( command_ctx( ) ).

    IF mv_cgui_skip = abap_true OR to_upper( z2ui5_cl_cgui_command=>url_param( client = client
                                                                                            name   = cv_cgui_url_skip ) ) = abap_true OR screen_empty( ) = abap_true.
      IF mv_cgui_variant_start IS NOT INITIAL.
        " the variant arrives with the browser's storage - the run waits for
        " it, and a timer runs it when nothing is stored
        mv_cgui_auto_exec = abap_true.

        CLEAR temp422.
        INSERT cs_ucomm-auto_execute INTO TABLE temp422.
        INSERT `700` INTO TABLE temp422.
        client->follow_up_action( val   = client->cs_event-start_timer
                                  t_arg = temp422 ).
      ELSE.
        mv_cgui_skipped = abap_true.
        on_execute( ).
      ENDIF.
    ENDIF.

    view_display( ).

  ENDMETHOD.

  METHOD on_init_memory.
    DATA lv_variant TYPE string.

    " the default store is the table, unless initialization( ) chose another
    " one or the browser's local storage
    IF mo_cgui_store IS NOT BOUND AND mv_cgui_store_none = abap_false.
      mo_cgui_store = z2ui5_cl_cgui_variant_db=>factory( ).
    ENDIF.

    " a server store reads the variants now, the browser once it rendered
    IF mo_cgui_store IS BOUND.
      z2ui5_cl_cgui_memory=>variant_load( memory_ctx( ) ).
      z2ui5_cl_cgui_memory=>spa_load( memory_ctx( ) ).
    ENDIF.

    " a variant in the URL wins over the one initialization( ) set

    lv_variant = variant_from_url( ).
    IF lv_variant IS NOT INITIAL.
      mv_cgui_variant_start = lv_variant.
      mv_cgui_variant_url = abap_true.
    ENDIF.
    " the draft of a server store - a start variant wins over it
    IF mo_cgui_store IS BOUND AND mv_cgui_draft = abap_true AND mv_cgui_variant_start IS INITIAL.
      draft_restore( ).
    ENDIF.
    IF mv_cgui_variant_start IS NOT INITIAL AND mo_cgui_store IS BOUND.
      variant_start_apply( ).
    ENDIF.

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

    DATA ls_field TYPE z2ui5_cl_cgui_selscreen=>ty_s_field.
    DATA lt_text TYPE string_table.
    DATA temp424 TYPE string_table.
    DATA temp29 LIKE LINE OF temp424.
    DATA temp30 TYPE z2ui5_cl_cgui_selscreen=>ty_s_field-text.
    READ TABLE mt_cgui_field INTO ls_field WITH KEY name = field.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lt_text = z2ui5_cl_cgui_context=>dtel_docu_read( ls_field-dtel ).
    IF lt_text IS INITIAL.
      message( 'No documentation is available'(040) ).
      RETURN.
    ENDIF.
    mv_cgui_nav = abap_true.

    CLEAR temp424.

    temp29 = 'OK'(041).
    INSERT temp29 INTO TABLE temp424.

    IF ls_field-text IS NOT INITIAL.
      temp30 = ls_field-text.
    ELSE.
      temp30 = 'Help'(042).
    ENDIF.
    client->nav_app_call( z2ui5_cl_cgui_popup=>decide(
        question = concat_lines_of( table = lt_text sep = |\n\n| )
        options  = temp424
        title    = temp30
        cancel   = abap_false ) ).

  ENDMETHOD.

  METHOD set_line_count.

    mv_cgui_line_count = val.
    IF mo_cgui_list IS BOUND.
      mo_cgui_list->set_line_count( val ).
    ENDIF.

  ENDMETHOD.

  METHOD set_pf_status.

    FIELD-SYMBOLS <excl> TYPE any.
      DATA temp426 TYPE string.
      DATA temp1 TYPE string.

    mt_cgui_pf = functions.
    mt_cgui_pf_keys = shortcuts.
    CLEAR mt_cgui_excl_out.
    LOOP AT excluding ASSIGNING <excl>.

      temp426 = <excl>.

      temp1 = condense( to_upper( temp426 ) ).
      INSERT temp1 INTO TABLE mt_cgui_excl_out.
    ENDLOOP.

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

  METHOD dynpro_screen ##NEEDED.
  ENDMETHOD.

  METHOD dynpro_pbo ##NEEDED.
  ENDMETHOD.

  METHOD dynpro_pai ##NEEDED.
  ENDMETHOD.

  METHOD at_gui_event ##NEEDED.
  ENDMETHOD.

  METHOD at_roundtrip_start ##NEEDED.
  ENDMETHOD.

  METHOD cgui_statics_keep ##NEEDED.
  ENDMETHOD.

  METHOD cgui_statics_restore ##NEEDED.
  ENDMETHOD.

  METHOD after_call_screen ##NEEDED.
  ENDMETHOD.

  METHOD call_screen.
    DATA temp427 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_call.

    " the dynpro of another class runs as an app of its own
    IF owner IS BOUND AND owner <> me.
      owner->mv_cgui_owner_dynnr = dynnr_norm( dynnr ).
      mv_cgui_pending_kind = cs_pending-screen.
      mv_cgui_pending_field = dynnr_norm( dynnr ).
      mv_cgui_nav = abap_true.
      client->nav_app_call( owner ).
      RETURN.
    ENDIF.


    CLEAR temp427.
    temp427-screen = mv_cgui_screen.
    temp427-dynnr = mv_cgui_dynpro.
    temp427-called = dynnr_norm( dynnr ).
    temp427-pf = mt_cgui_pf.
    temp427-pf_keys = mt_cgui_pf_keys.
    temp427-pf_excl = mt_cgui_excl_out.
    INSERT temp427 INTO TABLE mt_cgui_dynpro_stack.
    mv_cgui_dynpro = dynnr_norm( dynnr ).
    mv_cgui_screen = cs_screen-dynpro.
    CLEAR: mv_cgui_dynpro_next, mv_cgui_dynpro_left.

  ENDMETHOD.

  METHOD set_screen.

    mv_cgui_dynpro_next = dynnr_norm( dynnr ).

  ENDMETHOD.

  METHOD leave_to_screen.

    set_screen( dynnr ).
    leave_screen( ).

  ENDMETHOD.

  METHOD leave_screen.

    mv_cgui_dynpro_left = abap_true.

  ENDMETHOD.

  METHOD screen_left.

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( mv_cgui_dynpro_left = abap_true OR mv_cgui_stop = abap_true ).
    result = temp1.

  ENDMETHOD.

  METHOD on_dynpro_command.

    DATA lv_dynnr LIKE mv_cgui_dynpro.
    DATA lv_next LIKE mv_cgui_dynpro_next.
    lv_dynnr = mv_cgui_dynpro.
    CLEAR: mv_cgui_dynpro_next, mv_cgui_dynpro_left.
    mv_cgui_stop = abap_false.
    " the required fields, but for the functions that leave
    IF ucomm <> `BACK` AND ucomm <> `EXIT` AND ucomm <> `CANC` AND ucomm <> `CANCEL`
        AND check_obligatory( ) = abap_false.
      RETURN.
    ENDIF.
    dynpro_pai( dynnr = lv_dynnr
                ucomm = ucomm ).
    " an error message keeps the dynpro, as on a classic screen
    IF mv_cgui_stop = abap_true OR mv_cgui_screen <> cs_screen-dynpro.
      mv_cgui_stop = abap_false.
      RETURN.
    ENDIF.


    lv_next = mv_cgui_dynpro_next.
    IF lv_next IS INITIAL AND mt_cgui_pf IS INITIAL AND ( ucomm = `BACK` OR ucomm = `EXIT` OR ucomm = `CANC` ).
      " no status of the report's own: Back of the runtime leaves
      lv_next = `0000`.
    ENDIF.
    IF lv_next = `0000`.
      dynpro_return( lv_dynnr ).
    ELSEIF lv_next IS NOT INITIAL.
      mv_cgui_dynpro = lv_next.
    ENDIF.
    CLEAR: mv_cgui_dynpro_next, mv_cgui_dynpro_left.

  ENDMETHOD.

  METHOD dynnr_norm.

    DATA lv_dynnr TYPE n LENGTH 4.

    lv_dynnr = condense( dynnr ).
    result = lv_dynnr.

  ENDMETHOD.

  METHOD dynpro_return.

    DATA lv_called LIKE dynnr.
    DATA lv_top TYPE i.
      DATA ls_call LIKE LINE OF mt_cgui_dynpro_stack.
      FIELD-SYMBOLS <temp31> LIKE LINE OF mt_cgui_dynpro_stack.
      DATA temp32 LIKE sy-tabix.
    lv_called = dynnr.

    lv_top = lines( mt_cgui_dynpro_stack ).
    " the dynpro another class called - back to the caller
    IF lv_top = 0 AND mv_cgui_owner_dynnr IS NOT INITIAL.
      mv_cgui_nav = abap_true.
      client->nav_app_leave( client->get_app_prev( ) ).
      RETURN.
    ENDIF.
    IF lv_top = 0.
      mv_cgui_screen = cs_screen-selection.
      CLEAR mv_cgui_dynpro.
    ELSE.



      temp32 = sy-tabix.
      READ TABLE mt_cgui_dynpro_stack INDEX lv_top ASSIGNING <temp31>.
      sy-tabix = temp32.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      ls_call = <temp31>.
      DELETE mt_cgui_dynpro_stack INDEX lv_top.
      mv_cgui_screen = ls_call-screen.
      mv_cgui_dynpro = ls_call-dynnr.
      lv_called = ls_call-called.
      " the status of the screen it returns to
      mt_cgui_pf = ls_call-pf.
      mt_cgui_pf_keys = ls_call-pf_keys.
      mt_cgui_excl_out = ls_call-pf_excl.
    ENDIF.
    after_call_screen( lv_called ).
    CASE mv_cgui_screen.
      WHEN cs_screen-selection.
        " CALL SCREEN in START-OF-SELECTION: END-OF-SELECTION and the list
        " follow - elsewhere the list written after it shows
        IF mv_cgui_run_wait = abap_true.
          run_answer_output( ).
        ELSEIF mo_cgui_list IS BOUND OR mo_cgui_alv IS BOUND.
          mv_cgui_screen = cs_screen-output.
        ENDIF.
      WHEN cs_screen-output.
        " CALL SCREEN in AT LINE-SELECTION: the level it opened, or the
        " list it came from when nothing was written
        level_settle( ).
    ENDCASE.

  ENDMETHOD.

  METHOD view_display_dynpro.

    result = z2ui5_cl_cgui_selscreen=>factory( client          = client
                                               value_help_auto = abap_true ).
    result->set_gui( me ).
    dynpro_screen( dynnr  = mv_cgui_dynpro
                   screen = result ).
    mo_cgui_screen = result.
    dynpro_pbo( mv_cgui_dynpro ).
    CLEAR mo_cgui_screen.
    value_state_set( result ).
    mt_cgui_field = result->get_fields( ).

  ENDMETHOD.

  METHOD authority_check.

    result = abap_true.

  ENDMETHOD.

  METHOD value_request_part.

    DATA temp428 TYPE string.
    IF mv_cgui_value_part IS NOT INITIAL.
      temp428 = mv_cgui_value_part.
    ELSE.
      temp428 = z2ui5_cl_cgui_selscreen=>cs_part-low.
    ENDIF.
    result = temp428.

  ENDMETHOD.

  METHOD at_alv_value_request ##NEEDED.

    " the value help of the DDIC for the type of the column
    value_help_ddic( column ).

  ENDMETHOD.

  METHOD value_help_target.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lr_tab TYPE REF TO data.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <cell> TYPE any.

    IF mv_cgui_alv_f4_col IS INITIAL OR to_upper( field ) <> mv_cgui_alv_f4_col.
      result = attri_assign( field ).
      RETURN.
    ENDIF.
    " the cell of the ALV

    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.

    READ TABLE <tab> ASSIGNING <row> INDEX mv_cgui_alv_f4_row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    ASSIGN COMPONENT mv_cgui_alv_f4_col OF STRUCTURE <row> TO <cell>.
    IF sy-subrc = 0.
      GET REFERENCE OF <cell> INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~upload_popup.

    " the F4 that opened the dialog runs again - or Execute, while the
    " selection screen is processed; elsewhere the files wait for the user
    " to repeat what needs them
    DATA temp429 TYPE string.
    IF mv_cgui_value_field IS NOT INITIAL.
      temp429 = cs_pending-f4.
    ELSEIF mv_cgui_screen = cs_screen-selection.
      temp429 = cs_ucomm-execute.
    ELSE.
      CLEAR temp429.
    ENDIF.
    mv_cgui_file_rerun = temp429.
    IF mv_cgui_file_rerun = cs_ucomm-execute.
      " the run stops here - it starts again with the files
      mv_cgui_stop = abap_true.
      rerun = abap_true.
    ENDIF.
    mv_cgui_pending_field = mv_cgui_value_field.
    mv_cgui_pending_part = mv_cgui_value_part.
    mv_cgui_pending_kind = cs_pending-file.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_file=>factory( title    = title
                                                       multiple = multiple
                                                       filter   = filter ) ).

  ENDMETHOD.

  METHOD file_result.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_file.
        DATA temp430 TYPE REF TO z2ui5_cl_cgui_file.
    DATA ls_result TYPE z2ui5_cl_cgui_file=>ty_s_result.
    DATA ls_file LIKE LINE OF ls_result-files.
    DATA lv_rerun LIKE mv_cgui_file_rerun.

    TRY.

        temp430 ?= client->get_app_prev( ).
        lo_popup = temp430.
      CATCH cx_root.
        RETURN.
    ENDTRY.

    ls_result = lo_popup->result( ).
    IF ls_result-confirmed = abap_false.
      CLEAR mv_cgui_file_rerun.
      RETURN.
    ENDIF.

    CLEAR mt_cgui_file_pick.

    LOOP AT ls_result-files INTO ls_file.
      DELETE mt_cgui_file WHERE name = ls_file-name.
      INSERT ls_file INTO TABLE mt_cgui_file.
      INSERT ls_file-name INTO TABLE mt_cgui_file_pick.
    ENDLOOP.


    lv_rerun = mv_cgui_file_rerun.
    CLEAR mv_cgui_file_rerun.
    CASE lv_rerun.
      WHEN cs_pending-f4.
        mv_cgui_value_field = field.
        mv_cgui_value_part = mv_cgui_pending_part.
        CLEAR mv_cgui_pending_part.
        at_value_request( field ).
        CLEAR: mv_cgui_value_field, mv_cgui_value_part.
      WHEN cs_ucomm-execute.
        on_execute( ).
      WHEN OTHERS.
        message( replace( val  = 'File &1 uploaded'(045)
                          sub  = `&1`
                          with = concat_lines_of( table = mt_cgui_file_pick
                                                  sep   = `, ` ) ) ).
    ENDCASE.
    " a second dialog of the same run opens the upload again
    CLEAR mt_cgui_file_pick.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~picked.

    result = mt_cgui_file_pick.
    CLEAR mt_cgui_file_pick.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~names.

    DATA ls_file LIKE LINE OF mt_cgui_file.
    LOOP AT mt_cgui_file INTO ls_file.
      INSERT ls_file-name INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~content.
    DATA lv_name TYPE string.
    DATA ls_file LIKE LINE OF mt_cgui_file.

    CLEAR: content, found.

    lv_name = to_upper( z2ui5_cl_cgui_frontend=>file_name( name ) ).

    LOOP AT mt_cgui_file INTO ls_file.
      IF to_upper( ls_file-name ) = lv_name.
        content = ls_file-content.
        found = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~download.

    DATA temp431 TYPE string_table.
    DATA temp33 LIKE LINE OF temp431.
    CLEAR temp431.

    temp33 = |data:{ mime };base64,{ z2ui5_cl_cgui_context=>conv_encode_x_base64( content ) }|.
    INSERT temp33 INTO TABLE temp431.
    INSERT name INTO TABLE temp431.
    client->follow_up_action( val   = client->cs_event-download_b64_file
                              t_arg = temp431 ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~open_url.

    DATA temp433 TYPE string_table.
    CLEAR temp433.
    INSERT url INTO TABLE temp433.
    client->follow_up_action( val   = client->cs_event-open_new_tab
                              t_arg = temp433 ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_files~clipboard.

    DATA temp435 TYPE string_table.
    CLEAR temp435.
    INSERT text INTO TABLE temp435.
    client->follow_up_action( val   = client->cs_event-clipboard_copy
                              t_arg = temp435 ).

  ENDMETHOD.

  METHOD alv_f4_result.

    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <cell>  TYPE any.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.

    DATA lv_row LIKE mv_cgui_alv_f4_row.
    DATA lv_col LIKE mv_cgui_alv_f4_col.
      DATA lr_cell TYPE REF TO data.
      DATA lr_row TYPE REF TO data.
    lv_row = mv_cgui_alv_f4_row.

    lv_col = mv_cgui_alv_f4_col.
    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        CLEAR lo_popup.
    ENDTRY.
    IF lo_popup IS BOUND AND lo_popup->result( )-confirmed = abap_true AND lo_popup->result( )-row IS BOUND.

      lr_cell = value_help_target( lv_col ).

      lr_row = lo_popup->result( )-row.
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

    FIELD-SYMBOLS <field_val> TYPE any.

    DATA lr_val TYPE REF TO data.
    DATA lo_descr TYPE REF TO cl_abap_typedescr.
    DATA lv_pattern TYPE string.
    lr_val = value_help_target( field ).
    IF lr_val IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_val->* TO <field_val>.

    lo_descr = z2ui5_cl_cgui_context=>rtti_get_value_descr( <field_val> ).
    " what the user typed with a * or + restricts the hit list, as in SAP GUI

    lv_pattern = ``.
    IF cl_abap_typedescr=>describe_by_data( <field_val> )->kind = cl_abap_typedescr=>kind_elem.
      lv_pattern = |{ <field_val> }|.
    ENDIF.

    " a CDS entity named as the value help comes first, then MATCHCODE
    " OBJECT, then what the type of the field knows
    IF value_help_entity( field   = field
                          pattern = lv_pattern ) = abap_true.
      RETURN.
    ENDIF.
    IF value_help_matchcode( field ) = abap_true.
      RETURN.
    ENDIF.
    IF value_help_descr( field   = field
                         descr   = lo_descr
                         pattern = lv_pattern ) = abap_true.
      RETURN.
    ENDIF.

    message( 'No input help is available'(003) ).

  ENDMETHOD.

  METHOD value_help_entity.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40
    DATA lv_key TYPE string.
    DATA lr_mc TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_field.
    DATA lr_entity TYPE REF TO data.
    DATA lv_elem LIKE lr_mc->entity_elem.
      DATA temp437 TYPE REF TO cl_abap_structdescr.
      DATA temp34 TYPE REF TO cl_abap_tabledescr.
      DATA lo_row LIKE temp437.
      DATA ls_first TYPE abap_compdescr.
    lv_key = to_upper( field ).

    READ TABLE mt_cgui_field REFERENCE INTO lr_mc WITH KEY name = lv_key.
    " a CDS entity named as the value help comes first - its rows, the
    " element named the value (else its first column)
    IF sy-subrc <> 0 OR lr_mc->entity IS INITIAL.
      RETURN.
    ENDIF.

    lr_entity = z2ui5_cl_cgui_context=>entity_select( entity  = lr_mc->entity
                                                            column  = lr_mc->entity_elem
                                                            pattern = pattern ).
    IF lr_entity IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_entity->* TO <tab>.
    IF <tab> IS INITIAL.
      RETURN.
    ENDIF.

    lv_elem = lr_mc->entity_elem.
    IF lv_elem IS INITIAL.


      temp34 ?= cl_abap_typedescr=>describe_by_data( <tab> ).
      temp437 ?= temp34->get_table_line_type( ).

      lo_row = temp437.

      READ TABLE lo_row->components INTO ls_first INDEX 1.
      lv_elem = ls_first-name.
    ENDIF.
    value_help_popup( tab   = <tab>
                      col   = lv_elem
                      title = value_help_title( field ) ).
    result = abap_true.


  ENDMETHOD.

  METHOD value_help_matchcode.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    " MATCHCODE OBJECT - the search help named at the field
    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40
    DATA lv_key TYPE string.
    DATA lr_mc TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_field.
      DATA temp438 TYPE z2ui5_cl_cgui_context=>ty_s_search_help.
      DATA ls_mc LIKE temp438.
        DATA lr_mc_hits TYPE REF TO data.
    lv_key = to_upper( field ).

    READ TABLE mt_cgui_field REFERENCE INTO lr_mc WITH KEY name = lv_key.
    IF sy-subrc = 0 AND lr_mc->matchcode IS NOT INITIAL.

      CLEAR temp438.
      temp438-name = lr_mc->matchcode.
      temp438-field = matchcode_field( lr_mc->matchcode ).

      ls_mc = temp438.
      IF ls_mc-field IS NOT INITIAL.

        lr_mc_hits = z2ui5_cl_cgui_context=>search_help_select( ls_mc ).
        IF lr_mc_hits IS BOUND.
          ASSIGN lr_mc_hits->* TO <tab>.
          IF <tab> IS NOT INITIAL.
            value_help_popup( tab   = <tab>
                              col   = ls_mc-field
                              title = value_help_title( field ) ).
            result = abap_true.
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.


  ENDMETHOD.

  METHOD value_help_descr.

    DATA lt_value TYPE ty_t_cgui_value.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lt_fix TYPE z2ui5_cl_cgui_context=>ty_t_fix_val.
      DATA temp439 LIKE LINE OF lt_fix.
      DATA lr_fix LIKE REF TO temp439.
        DATA temp440 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_value.
    DATA ls_help TYPE z2ui5_cl_cgui_context=>ty_s_search_help.
      DATA lr_hits TYPE REF TO data.
    DATA ls_table TYPE z2ui5_cl_cgui_context=>ty_s_value_table.
      DATA lr_rows TYPE REF TO data.
    lt_fix = z2ui5_cl_cgui_context=>rtti_get_fixed_values( descr ).
    IF lt_fix IS NOT INITIAL.


      LOOP AT lt_fix REFERENCE INTO lr_fix.

        CLEAR temp440.
        temp440-value = lr_fix->low.
        temp440-text = lr_fix->text.
        INSERT temp440 INTO TABLE lt_value.
      ENDLOOP.
      value_help_popup( tab   = lt_value
                        col   = `VALUE`
                        title = value_help_title( field ) ).
      result = abap_true.
      RETURN.
    ENDIF.

    " the search help of the data element - its hit list without a dialog

    ls_help = z2ui5_cl_cgui_context=>rtti_get_search_help( descr ).
    IF ls_help-name IS NOT INITIAL.

      lr_hits = z2ui5_cl_cgui_context=>search_help_select( ls_help ).
      IF lr_hits IS BOUND.
        ASSIGN lr_hits->* TO <tab>.
        IF <tab> IS NOT INITIAL.
          value_help_popup( tab   = <tab>
                            col   = ls_help-field
                            title = value_help_title( field ) ).
          result = abap_true.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    " the value table with the texts of its text table

    ls_table = z2ui5_cl_cgui_context=>rtti_get_value_table( descr ).
    IF ls_table-table IS NOT INITIAL.

      lr_rows = z2ui5_cl_cgui_context=>value_table_select( table   = ls_table
                                                                 pattern = pattern ).
      IF lr_rows IS BOUND.
        ASSIGN lr_rows->* TO <tab>.
        IF <tab> IS NOT INITIAL.
          value_help_popup( tab   = <tab>
                            col   = ls_table-field
                            title = value_help_title( field ) ).
          result = abap_true.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.


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
        DATA temp441 TYPE REF TO cl_abap_tabledescr.
        DATA lo_table LIKE temp441.
        DATA temp442 TYPE REF TO cl_abap_structdescr.
        DATA lo_line LIKE temp442.
        DATA temp443 LIKE sy-subrc.
        DATA temp444 TYPE abap_componentdescr.
        DATA temp35 TYPE REF TO cl_abap_datadescr.
        DATA lo_new TYPE REF TO cl_abap_tabledescr.

    TRY.

        temp441 ?= cl_abap_typedescr=>describe_by_data( tab ).

        lo_table = temp441.

        temp442 ?= lo_table->get_table_line_type( ).

        lo_line = temp442.
        lt_comp = lo_line->get_components( ).

        READ TABLE lt_comp WITH KEY name = `ZZSELKZ` TRANSPORTING NO FIELDS.
        temp443 = sy-subrc.
        IF temp443 = 0.
          RETURN.
        ENDIF.

        CLEAR temp444.
        temp444-name = `ZZSELKZ`.

        temp35 ?= cl_abap_typedescr=>describe_by_data( lv_flag ).
        temp444-type = temp35.
        INSERT temp444 INTO TABLE lt_comp.


        lo_new = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
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

    DATA lr_field TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_field.
    READ TABLE mt_cgui_field REFERENCE INTO lr_field WITH KEY name = field.
    IF sy-subrc = 0.
      result = lr_field->text.
    ENDIF.

  ENDMETHOD.

  METHOD on_event.

    DATA lv_event TYPE string.
    lv_event = client->get_event( ).
    " a tab of the tabstrip of a dynpro: its function code, as a push button
    IF lv_event = z2ui5_cl_cgui_selscreen=>cs_event-tab.
      lv_event = to_upper( client->get_event_arg( ) ).
    ENDIF.

    on_event_sync( ).
    IF on_alv_event( ) = abap_true.
      RETURN.
    ENDIF.
    IF on_event_tree( lv_event ) = abap_true.
      RETURN.
    ENDIF.
    IF on_event_selection( lv_event ) = abap_true.
      RETURN.
    ENDIF.
    IF on_event_popup( lv_event ) = abap_true.
      RETURN.
    ENDIF.
    IF on_event_output( lv_event ) = abap_true.
      RETURN.
    ENDIF.
    IF on_event_gui( lv_event ) = abap_true.
      RETURN.
    ENDIF.
    user_command( lv_event ).

  ENDMETHOD.

  METHOD on_event_sync.

    alv_page_sync( ).
    alv_single_sync( ).
    alv_edit_sync( ).
    " the input in the lines of the table control the browser holds
    IF mv_cgui_tc IS NOT INITIAL.
      z2ui5_cl_cgui_view=>tablecontrol_sync( gui_ctx( ) ).
    ENDIF.
    " the ticks of the tree, before the event reads them
    IF mo_cgui_tree IS BOUND.
      mo_cgui_tree->sync( mt_cgui_tree_view ).
    ENDIF.
    IF mo_cgui_list IS BOUND AND mt_cgui_list_input IS NOT INITIAL.
      mo_cgui_list->set_inputs( mt_cgui_list_input ).
    ENDIF.
  ENDMETHOD.

  METHOD tree_expand.
        DATA temp445 TYPE REF TO z2ui5_cl_cgui_salv_tree.
        DATA lo_salv LIKE temp445.

    at_tree_expand_no_children( key ).
    IF mo_cgui_tree_handler IS NOT BOUND.
      RETURN.
    ENDIF.
    TRY.

        temp445 ?= mo_cgui_tree_handler.

        lo_salv = temp445.
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.
    " the handlers of the stand-in of cl_salv_tree - an event of a control
    at_gui_event( ).
    lo_salv->on_expand( key ).

  ENDMETHOD.

  METHOD on_event_tree.
        DATA lv_lazy TYPE i.
        DATA lv_tick TYPE i.

    IF mo_cgui_tree IS BOUND.
      IF event = z2ui5_cl_cgui_tree=>cs_event-node.
        on_tree_node( z2ui5_cl_cgui_tree=>get_node_by_event( client ) ).
        result = abap_true.
        RETURN.
      ELSEIF mo_cgui_tree->handle_event( client ) = abap_true.

        lv_lazy = mo_cgui_tree->take_expand_request( ).
        IF lv_lazy IS NOT INITIAL.
          tree_expand( lv_lazy ).
        ENDIF.
        result = abap_true.
        RETURN.
      ELSEIF event = z2ui5_cl_cgui_tree=>cs_event-checkbox.

        lv_tick = z2ui5_cl_cgui_tree=>get_node_by_event( client ).
        at_tree_checkbox( key     = lv_tick
                          checked = mo_cgui_tree->get_node( lv_tick )-checked ).
        IF mo_cgui_tree_handler IS BOUND.
          at_gui_event( ).
          mo_cgui_tree_handler->on_checkbox( key     = lv_tick
                                             checked = mo_cgui_tree->get_node( lv_tick )-checked ).
        ENDIF.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD on_event_selection.
        DATA temp446 LIKE sy-subrc.
        DATA temp447 TYPE string_table.
        DATA lv_dynnr LIKE mv_cgui_dynnr.

    result = abap_true.
    CASE event.

      WHEN cs_ucomm-execute.
        " F8 is registered for the whole app - on the output it does nothing

        READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-execute TRANSPORTING NO FIELDS.
        temp446 = sy-subrc.
        IF mv_cgui_screen = cs_screen-selection AND mv_cgui_denied = abap_false
            AND NOT temp446 = 0.
          on_execute( ).
        ENDIF.

      WHEN cs_ucomm-back.
        on_back( ).

      WHEN cs_ucomm-draft_discard.
        draft_discard( ).

      WHEN cs_ucomm-cancel.
        CLEAR: mv_cgui_pending_field, mv_cgui_pending_kind.
        " the popup the run waited for is cancelled - the run ends there
        IF mv_cgui_run_wait = abap_true AND mv_cgui_screen = cs_screen-selection.
          CLEAR: mv_cgui_pending_ucomm, mv_cgui_run_wait.
          mv_cgui_restart = abap_true.
        ENDIF.

      WHEN cs_ucomm-variants_loaded.
        on_storage_loaded( ).

      WHEN cs_ucomm-auto_execute.
        auto_execute( ).

      WHEN cs_ucomm-link_copy.

        CLEAR temp447.
        INSERT get_link( ) INTO TABLE temp447.
        client->follow_up_action( val   = client->cs_event-clipboard_copy
                                  t_arg = temp447 ).
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

        lv_dynnr = mv_cgui_dynnr.
        CLEAR mv_cgui_dynnr.
        client->popup_destroy( ).
        after_call_selection_screen( dynnr = lv_dynnr
                                     subrc = 4 ).

      " the argument names the attribute - from the browser, so only a field
      " of the screen, never another attribute of the class
      WHEN z2ui5_cl_cgui_selscreen=>cs_event-select_option.
        IF screen_field_check( field = client->get_event_arg( )
                               kind  = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option ) = abap_true.
          on_range_popup( client->get_event_arg( ) ).
        ENDIF.

      WHEN z2ui5_cl_cgui_selscreen=>cs_event-help_request.
        at_selection_screen_on_help( client->get_event_arg( ) ).

      WHEN cs_ucomm-background.
        IF mv_cgui_screen = cs_screen-selection AND mo_cgui_job IS BOUND.
          on_background( ).
        ENDIF.

      WHEN z2ui5_cl_cgui_selscreen=>cs_event-value_request.
        IF screen_field_check( client->get_event_arg( ) ) = abap_true.
          mv_cgui_value_field = client->get_event_arg( ).
          mv_cgui_value_part = to_upper( client->get_event_arg( 2 ) ).
          at_value_request( mv_cgui_value_field ).
          CLEAR: mv_cgui_value_field, mv_cgui_value_part.
        ENDIF.

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.

  METHOD on_event_popup.
        DATA temp449 TYPE string_table.

    result = abap_true.
    CASE event.

      WHEN cs_ucomm-messages_open.
        " the screen stays as it is - the popover opens on it
        mv_cgui_nav = abap_true.

        CLEAR temp449.
        INSERT cv_cgui_popover_id INTO TABLE temp449.
        INSERT `openBy` INTO TABLE temp449.
        INSERT cv_cgui_messages_id INTO TABLE temp449.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp449 ).

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

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.

  METHOD on_event_output.
        DATA temp451 TYPE i.
        DATA temp36 TYPE i.
        DATA temp452 TYPE i.
        DATA ls_change TYPE z2ui5_cl_cgui_alv=>ty_s_hotspot.
        DATA lv_alv_row TYPE i.
        DATA ls_hotspot TYPE z2ui5_cl_cgui_alv=>ty_s_hotspot.

    result = abap_true.
    CASE event.

      WHEN cs_ucomm-print.
        on_print( ).

      WHEN cs_ucomm-okcode.
        okcode_execute( mv_cgui_okcode ).

      WHEN cs_ucomm-palette.
        palette_open( ).

      WHEN z2ui5_cl_cgui_list=>cs_event-line_selection.

        temp451 = client->get_event_arg( ).

        temp36 = client->get_event_arg( 3 ).
        cursor_from_list( line = temp451
                          id   = temp36 ).

        temp452 = client->get_event_arg( ).
        on_line_selection( row  = temp452
                           hide = client->get_event_arg( 2 ) ).

      WHEN z2ui5_cl_cgui_alv=>cs_event-data_changed.

        ls_change = z2ui5_cl_cgui_alv=>get_hotspot_by_event( client ).
        at_data_changed( row    = alv_row( ls_change-row )
                         column = ls_change-column ).

      WHEN z2ui5_cl_cgui_alv=>cs_event-line_selection.

        lv_alv_row = alv_row( z2ui5_cl_cgui_alv=>get_row_by_event( client ) ).
        CLEAR ms_cgui_cursor.
        ms_cgui_cursor-line = lv_alv_row.
        CLEAR mv_cgui_lisel.
        " the ALV of a grid: its event double_click
        IF mv_cgui_grid IS NOT INITIAL.
          gui_event( id    = mv_cgui_grid
                     event = `DOUBLE_CLICK`
                     value = |{ lv_alv_row }| ).
        ELSE.
          on_line_selection( row  = lv_alv_row
                             hide = `` ).
        ENDIF.

      WHEN z2ui5_cl_cgui_alv=>cs_event-hotspot.

        ls_hotspot = z2ui5_cl_cgui_alv=>get_hotspot_by_event( client ).
        CLEAR ms_cgui_cursor.
        ms_cgui_cursor-field = ls_hotspot-column.
        ms_cgui_cursor-line = alv_row( ls_hotspot-row ).
        CLEAR mv_cgui_lisel.
        IF mv_cgui_grid IS NOT INITIAL.
          gui_event( id    = mv_cgui_grid
                     event = `HOTSPOT_CLICK`
                     value = |{ alv_row( ls_hotspot-row ) }{ cl_abap_char_utilities=>horizontal_tab }{ ls_hotspot-column }| ).
        ELSE.
          on_line_selection( row    = alv_row( ls_hotspot-row )
                             hide   = ls_hotspot-column
                             column = ls_hotspot-column
                             link   = abap_true ).
        ENDIF.

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.

  METHOD on_event_gui.
        DATA temp453 TYPE string.
        DATA lv_key LIKE temp453.
        DATA lv_editor TYPE i.
          DATA temp454 TYPE i.
          DATA lv_value TYPE string.
          DATA temp455 TYPE i.

    result = abap_true.
    CASE event.

      WHEN cs_ucomm-gui_f1 OR cs_ucomm-gui_f4.

        IF event = cs_ucomm-gui_f1.
          temp453 = `F1`.
        ELSE.
          temp453 = `F4`.
        ENDIF.

        lv_key = temp453.

        lv_editor = z2ui5_cl_cgui_view=>key_target( ctx = gui_ctx( )
                                                              key = lv_key ).
        IF lv_editor > 0.
          gui_event( id    = lv_editor
                     event = lv_key
                     value = `` ).
        ENDIF.

      WHEN cs_ucomm-gui.
        " an event of a SAP GUI control: id, event, value - or the switch to
        " a grid that does not show
        IF client->get_event_arg( 2 ) = z2ui5_cl_cgui_view=>cv_show.

          temp454 = client->get_event_arg( 1 ).
          grid_show( temp454 ).
        ELSE.
          " the SAPEVENT of an HTMLFrame: action, query and posted fields
          " apart - the value is action?query, as a link of the document has it

          lv_value = client->get_event_arg( 3 ).
          IF client->get_event_arg( 4 ) IS NOT INITIAL.
            lv_value = |{ lv_value }?{ client->get_event_arg( 4 ) }|.
          ENDIF.

          temp455 = client->get_event_arg( 1 ).
          gui_event( id    = temp455
                     event = client->get_event_arg( 2 )
                     value = lv_value
                     post  = client->get_event_arg( 5 ) ).
        ENDIF.

      WHEN cs_ucomm-enter.
        IF mv_cgui_screen = cs_screen-dynpro.
          on_dynpro_command( `` ).
        ENDIF.

      WHEN z2ui5_cl_cgui_view=>cv_tc_rows.
        " the table control asks for lines - the screen stays as it is
        mv_cgui_nav = abap_true.
        z2ui5_cl_cgui_view=>tablecontrol_rows( gui_ctx( ) ).

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.

  METHOD on_alv_event.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lv_event TYPE string.
    DATA lr_full TYPE REF TO data.
          DATA temp2 TYPE xsdboolean.
    lv_event = client->get_event( ).
    IF mo_cgui_alv IS NOT BOUND OR z2ui5_cl_cgui_alv=>is_grid_event( lv_event ) = abap_false.
      RETURN.
    ENDIF.

    result = abap_true.

    lr_full = alv_shown( ).
    CASE lv_event.
      WHEN z2ui5_cl_cgui_alv=>cs_event-filter.
        alv_filter_popup( ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-filter_clear.
        mo_cgui_alv->clear_filter( ).
        mo_cgui_alv->set_search( `` ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-search.
        mo_cgui_alv->set_search( client->get_event_arg( ) ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-f4.
        alv_event_f4( ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-rows.
        " the grid asks for rows - the screen stays as it is
        mv_cgui_nav = abap_true.
        alv_window( ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-details.
        alv_event_details( lr_full ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-layout.
        layout_popup( ).
      WHEN z2ui5_cl_cgui_alv=>cs_event-select_all OR z2ui5_cl_cgui_alv=>cs_event-deselect_all.
        " filtered: the rows that pass, as the classic ALV does
        IF lr_full IS BOUND AND mo_cgui_alv->is_filtered( ) = abap_true.
          ASSIGN lr_full->* TO <tab>.

          temp2 = boolc( lv_event = z2ui5_cl_cgui_alv=>cs_event-select_all ).
          mo_cgui_alv->select_filtered( EXPORTING selected = temp2
                                        CHANGING  tab      = <tab> ).
        ELSE.
          alv_event_forward( lv_event ).
        ENDIF.
      WHEN OTHERS.
        alv_event_forward( lv_event ).
    ENDCASE.

  ENDMETHOD.

  METHOD alv_event_f4.

    DATA ls_f4 TYPE z2ui5_cl_cgui_alv=>ty_s_hotspot.
    ls_f4 = z2ui5_cl_cgui_alv=>get_hotspot_by_event( client ).
    mv_cgui_alv_f4_row = alv_row( ls_f4-row ).
    mv_cgui_alv_f4_col = to_upper( ls_f4-column ).
    mv_cgui_value_field = mv_cgui_alv_f4_col.
    at_alv_value_request( row    = mv_cgui_alv_f4_row
                          column = mv_cgui_alv_f4_col ).
    CLEAR mv_cgui_value_field.
    IF mv_cgui_nav = abap_false.
      CLEAR: mv_cgui_alv_f4_row, mv_cgui_alv_f4_col.
    ENDIF.

  ENDMETHOD.

  METHOD alv_event_details.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
      FIELD-SYMBOLS <temp456> LIKE LINE OF lt_selected.
      DATA temp457 LIKE sy-tabix.

    IF full IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN full->* TO <tab>.

    lt_selected = mo_cgui_alv->get_selected_rows( <tab> ).
    IF lt_selected IS INITIAL.
      message( text = 'Select a row'(044)
               type = `W` ).
    ELSE.


      temp457 = sy-tabix.
      READ TABLE lt_selected INDEX 1 ASSIGNING <temp456>.
      sy-tabix = temp457.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      mo_cgui_alv->details_popup( client = client
                                  tab    = <tab>
                                  row    = <temp456> ).
    ENDIF.

  ENDMETHOD.

  METHOD alv_event_forward.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lr_tab TYPE REF TO data.

    IF event = z2ui5_cl_cgui_alv=>cs_event-export OR event = z2ui5_cl_cgui_alv=>cs_event-export_xlsx
        OR event = z2ui5_cl_cgui_alv=>cs_event-chart.
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

    " Back on a dynpro is the function BACK of its PAI
    IF mv_cgui_screen = cs_screen-dynpro.
      on_dynpro_command( `BACK` ).
      RETURN.
    ENDIF.

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
      IF mv_cgui_as_window_on = abap_true.
        client->popup_destroy( ).
        mv_cgui_as_window_on = abap_false.
      ENDIF.
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
    mv_cgui_on_line = abap_true.
    IF link = abap_true.
      at_link_click( row    = row
                     column = column ).
    ELSE.
      at_line_selection( row  = row
                         hide = hide ).
    ENDIF.
    mv_cgui_on_line = abap_false.
    level_settle( ).

  ENDMETHOD.

  METHOD level_push.

    DATA temp458 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_level.
    CLEAR temp458.
    temp458-list = mo_cgui_list.
    temp458-alv = mo_cgui_alv.
    temp458-tree = mo_cgui_tree.
    temp458-alv_name = mv_cgui_alv_name.
    temp458-alv_data = mr_cgui_alv.
    temp458-alv_box = mr_cgui_alv_box.
    temp458-window = mv_cgui_window.
    temp458-w_title = mv_cgui_window_title.
    temp458-w_cols = mv_cgui_window_cols.
    temp458-w_lines = mv_cgui_window_lines.
    temp458-grid = mv_cgui_grid.
    temp458-grid_cat = mr_cgui_grid_fieldcat.
    temp458-grid_lay = mr_cgui_grid_layout.
    temp458-gui = lines( mt_cgui_gui ).
    temp458-pf = mt_cgui_pf.
    temp458-pf_keys = mt_cgui_pf_keys.
    temp458-pf_excl = mt_cgui_excl_out.
    INSERT temp458 INTO TABLE mt_cgui_level.
    " the status stays until the level sets its own, as in SAP GUI
    CLEAR: mo_cgui_list, mo_cgui_alv, mv_cgui_alv_name, mr_cgui_alv, mr_cgui_alv_box,
           mr_cgui_alv_page, mt_cgui_alv_index, mt_cgui_alv_order, mo_cgui_tree, mt_cgui_tree_view,
           mv_cgui_window, mv_cgui_window_title, mv_cgui_window_cols, mv_cgui_window_lines,
           mv_cgui_grid, mr_cgui_grid_fieldcat, mr_cgui_grid_layout.

  ENDMETHOD.

  METHOD level_pop.

    DATA lv_lines TYPE i.
    DATA ls_level LIKE LINE OF mt_cgui_level.
    FIELD-SYMBOLS <temp37> LIKE LINE OF mt_cgui_level.
    DATA temp38 LIKE sy-tabix.
    lv_lines = lines( mt_cgui_level ).
    IF lv_lines = 0.
      RETURN.
    ENDIF.



    temp38 = sy-tabix.
    READ TABLE mt_cgui_level INDEX lv_lines ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_level = <temp37>.
    DELETE mt_cgui_level INDEX lv_lines.

    " the controls of the level dropped - a grid of it no longer takes the
    " events of the list below
    level_free( ls_level-gui ).
    mo_cgui_list     = ls_level-list.
    mo_cgui_alv      = ls_level-alv.
    mo_cgui_tree     = ls_level-tree.
    mv_cgui_alv_name = ls_level-alv_name.
    mr_cgui_alv      = ls_level-alv_data.
    " the selection of the ALV stays as it was before the line selection
    mr_cgui_alv_box  = ls_level-alv_box.
    mv_cgui_window       = ls_level-window.
    mv_cgui_window_title = ls_level-w_title.
    mv_cgui_window_cols  = ls_level-w_cols.
    mv_cgui_window_lines = ls_level-w_lines.
    mv_cgui_grid           = ls_level-grid.
    mr_cgui_grid_fieldcat  = ls_level-grid_cat.
    mr_cgui_grid_layout    = ls_level-grid_lay.
    mt_cgui_pf       = ls_level-pf.
    mt_cgui_pf_keys  = ls_level-pf_keys.
    mt_cgui_excl_out = ls_level-pf_excl.
    CLEAR: mr_cgui_alv_page, mt_cgui_alv_index, mt_cgui_alv_order, mt_cgui_tree_view.

  ENDMETHOD.

  METHOD level_open.

    IF mv_cgui_level_new = abap_false.
      RETURN.
    ENDIF.
    mv_cgui_level_new = abap_false.
    level_push( ).

  ENDMETHOD.

  METHOD level_settle.
          DATA lt_pf LIKE mt_cgui_pf.
          DATA lt_pf_keys LIKE mt_cgui_pf_keys.
          DATA lt_pf_excl LIKE mt_cgui_excl_out.

    CASE mv_cgui_screen.
      WHEN cs_screen-output.
        IF mt_cgui_level IS NOT INITIAL AND level_empty( ) = abap_true.
          " SET PF-STATUS without a list: the status of the list that shows

          lt_pf = mt_cgui_pf.

          lt_pf_keys = mt_cgui_pf_keys.

          lt_pf_excl = mt_cgui_excl_out.
          level_pop( ).
          mt_cgui_pf = lt_pf.
          mt_cgui_pf_keys = lt_pf_keys.
          mt_cgui_excl_out = lt_pf_excl.
        ENDIF.
      WHEN cs_screen-dynpro.
        " CALL SCREEN: the level stays - what follows the call writes into
        " it, dynpro_return( ) drops it when it stays empty
        RETURN.
      WHEN OTHERS.
        " leave_to_selection_screen( ) - the levels are gone
        CLEAR mt_cgui_level.
    ENDCASE.

  ENDMETHOD.

  METHOD level_empty.
    DATA temp459 TYPE i.
      FIELD-SYMBOLS <temp39> LIKE LINE OF mt_cgui_level.
      DATA temp40 LIKE sy-tabix.
    DATA lv_from LIKE temp459.

    IF mo_cgui_alv IS BOUND OR mo_cgui_tree IS BOUND
        OR ( mo_cgui_list IS BOUND AND mo_cgui_list->has_content( ) = abap_true ).
      RETURN.
    ENDIF.
    " a control the level put on the list, a grid on cl_gui_container=>default_screen

    IF mt_cgui_level IS NOT INITIAL.


      temp40 = sy-tabix.
      READ TABLE mt_cgui_level INDEX lines( mt_cgui_level ) ASSIGNING <temp39>.
      sy-tabix = temp40.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp459 = <temp39>-gui.
    ELSE.
      CLEAR temp459.
    ENDIF.

    lv_from = temp459.
    LOOP AT mt_cgui_gui TRANSPORTING NO FIELDS FROM lv_from + 1
         WHERE parent = 0 AND dynnr = `LIST` AND freed = abap_false.
      RETURN.
    ENDLOOP.
    result = abap_true.

  ENDMETHOD.

  METHOD level_free.

    FIELD-SYMBOLS <control> LIKE LINE OF mt_cgui_gui.
    LOOP AT mt_cgui_gui ASSIGNING <control> FROM from + 1 WHERE parent = 0 AND dynnr = `LIST`.
      <control>-freed = abap_true.
    ENDLOOP.

  ENDMETHOD.

  METHOD lsind.

    " at_user_command( ): the list it writes, as sy-lsind - before it wrote
    DATA temp460 TYPE i.
    IF mv_cgui_level_new = abap_true.
      temp460 = 1.
    ELSE.
      CLEAR temp460.
    ENDIF.
    result = lines( mt_cgui_level ) + temp460.

  ENDMETHOD.

  METHOD set_lsind.

    " sy-lsind = sy-lsind - 1 in at_user_command( ): its list replaces the
    " one shown
    level_open( ).
    WHILE lines( mt_cgui_level ) > nmax( val1 = 0 val2 = val ).
      DELETE mt_cgui_level INDEX lines( mt_cgui_level ).
    ENDWHILE.

  ENDMETHOD.

  METHOD on_navigated.
    DATA lv_field LIKE mv_cgui_pending_field.
    DATA lv_kind LIKE mv_cgui_pending_kind.
    DATA lv_col LIKE mv_cgui_pending_col.
            DATA temp461 TYPE REF TO z2ui5_cl_cgui_transport.
        DATA temp462 TYPE string.

    " at_value_request( ) of the multiple selection opened another popup
    IF mv_cgui_pending_kind <> cs_pending-f4.
      mv_cgui_range_f4 = abap_false.
    ENDIF.

    IF mv_cgui_pending_kind IS INITIAL.
      RETURN.
    ENDIF.


    lv_field = mv_cgui_pending_field.

    lv_kind = mv_cgui_pending_kind.

    lv_col = mv_cgui_pending_col.
    CLEAR: mv_cgui_pending_field, mv_cgui_pending_kind, mv_cgui_pending_col.

    CASE lv_kind.
      WHEN cs_pending-palette.
        palette_result( ).

      WHEN cs_pending-su3.
        su3_result( ).
      WHEN cs_pending-spro.
        spro_result( ).

      WHEN cs_pending-screen.
        " what followed CALL SCREEN in the caller
        after_call_screen( lv_field ).
        IF mv_cgui_run_wait = abap_true.
          run_answer_output( ).
        ELSEIF mv_cgui_screen = cs_screen-selection AND ( mo_cgui_list IS BOUND OR mo_cgui_alv IS BOUND ).
          mv_cgui_screen = cs_screen-output.
        ENDIF.

      WHEN cs_pending-transport.
        TRY.

            temp461 ?= client->get_app_prev( ).
            ms_cgui_transport = temp461->result( ).
          CATCH cx_root.
            CLEAR ms_cgui_transport.
        ENDTRY.

        IF ms_cgui_transport-confirmed = abap_true.
          temp462 = z2ui5_cl_cgui_popup=>cs_answer-ok.
        ELSE.
          temp462 = z2ui5_cl_cgui_popup=>cs_answer-cancel.
        ENDIF.
        mv_cgui_answer = temp462.

      WHEN cs_pending-range.
        on_range_result( lv_field ).

      WHEN cs_pending-f4.
        on_f4_result( field = lv_field
                      col   = lv_col ).

      WHEN cs_pending-variant_get OR cs_pending-variant_save OR cs_pending-variant_delete.
        on_navigated_variant( lv_kind ).

      WHEN cs_pending-layout.
        layout_result( ).

      WHEN cs_pending-filter_col.
        alv_filter_column_result( ).

      WHEN cs_pending-filter.
        alv_filter_result( ).

      WHEN cs_pending-alv_f4.
        alv_f4_result( lv_col ).

      WHEN cs_pending-file.
        file_result( lv_field ).

      WHEN cs_pending-decide OR cs_pending-values.
        popup_answer_take( ).

    ENDCASE.

  ENDMETHOD.

  METHOD on_navigated_variant.
        DATA lv_name TYPE string.
            DATA temp463 TYPE REF TO z2ui5_cl_cgui_popup.
            DATA lo_popup LIKE temp463.

    CASE kind.
      WHEN cs_pending-variant_get.

        lv_name = variant_selected( ).
        IF lv_name IS NOT INITIAL AND z2ui5_cl_cgui_memory=>variant_apply( ctx    = memory_ctx( )
                                                                            fields = screen_fields( )
                                                                            name   = lv_name ) = abap_true.
          message( replace( val  = 'Variant &1 loaded'(005)
                            sub  = `&1`
                            with = lv_name ) ).
        ENDIF.

      WHEN cs_pending-variant_save.
        TRY.

            temp463 ?= client->get_app_prev( ).

            lo_popup = temp463.
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

    ENDCASE.

  ENDMETHOD.

  METHOD popup_answer_take.
        DATA temp464 TYPE REF TO z2ui5_cl_cgui_popup.
        DATA lo_popup LIKE temp464.
      DATA temp465 TYPE i.
      DATA lv_line TYPE i.

    TRY.

        temp464 ?= client->get_app_prev( ).

        lo_popup = temp464.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    mv_cgui_answer = lo_popup->result( )-answer.
    mt_cgui_popup_values = lo_popup->result( )-fields.
    " POPUP_TO_DECIDE_LIST answers the line of its table
    IF mt_cgui_decide_line IS NOT INITIAL AND mv_cgui_answer CO `0123456789` AND mv_cgui_answer IS NOT INITIAL.

      temp465 = mv_cgui_answer.

      READ TABLE mt_cgui_decide_line INTO lv_line INDEX temp465.
      IF sy-subrc = 0.
        mv_cgui_answer = |{ lv_line }|.
      ENDIF.
    ENDIF.
    CLEAR mt_cgui_decide_line.


  ENDMETHOD.

  METHOD screen_fields.

    " the layout without rendering - which fields the report has
    DATA screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    screen = z2ui5_cl_cgui_selscreen=>factory( client = client
                                                     app    = me ).
    selection_screen_layout( screen ).
    result = screen->get_fields( ).

  ENDMETHOD.

  METHOD screen_empty.

    DATA screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA temp3 TYPE xsdboolean.
    screen = z2ui5_cl_cgui_selscreen=>factory( client = client
                                                     app    = me ).
    selection_screen_layout( screen ).

    temp3 = boolc( screen->loop_at_screen( ) IS INITIAL ).
    result = temp3.

  ENDMETHOD.

  METHOD screen_field_check.

    " a NO-DISPLAY field (a switch SUBMIT sets), a field not ready for input
    " or a parameter named as a select-option is no target of the browser
    DATA lv_name TYPE string.
    DATA ls_field TYPE z2ui5_cl_cgui_selscreen=>ty_s_field.
    DATA temp4 TYPE xsdboolean.
    lv_name = to_upper( field ).
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE mt_cgui_field INTO ls_field WITH KEY name = lv_name.
    IF sy-subrc <> 0.
      READ TABLE mt_cgui_dynnr_field INTO ls_field WITH KEY name = lv_name.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
    ENDIF.

    temp4 = boolc( ls_field-shown = abap_true AND ls_field-no_display = abap_false AND ls_field-read_only = abap_false AND ( kind IS INITIAL OR ls_field-kind = kind ) ).
    result = temp4.

  ENDMETHOD.

  METHOD input_sync.

    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    DATA temp466 LIKE LINE OF mt_cgui_so.
    DATA lr_so LIKE REF TO temp466.
      DATA lr_range TYPE REF TO data.
      DATA lr_field TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_field.
          DATA temp467 TYPE string.

    IF mv_cgui_screen <> cs_screen-selection.
      RETURN.
    ENDIF.

    " the inputs from and to - the first line of a range, as the classic
    " select-option shows it. A pattern (* or +) is CP


    LOOP AT mt_cgui_so REFERENCE INTO lr_so.

      lr_range = attri_assign( lr_so->name ).
      IF lr_range IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_range->* TO <range>.


      READ TABLE mt_cgui_field REFERENCE INTO lr_field WITH KEY name = lr_so->name.
      IF sy-subrc = 0 AND lr_field->upper = abap_true.
        lr_so->low  = to_upper( lr_so->low ).
        lr_so->high = to_upper( lr_so->high ).
      ENDIF.

      CLEAR <range>.
      IF lr_so->low IS INITIAL AND lr_so->high IS INITIAL.
        CONTINUE.
      ENDIF.
      TRY.

          IF lr_so->high IS NOT INITIAL.
            temp467 = `BT`.
          ELSEIF lr_so->low CA `*+`.
            temp467 = `CP`.
          ELSE.
            temp467 = `EQ`.
          ENDIF.
          z2ui5_cl_cgui_range=>line_append( EXPORTING option = temp467
                                                      low    = lr_so->low
                                                      high   = lr_so->high
                                            CHANGING  range  = <range> ).
        CATCH cx_sy_conversion_error.
          message( text  = replace( val  = 'Enter a valid value for &1'(008)
                                    sub  = `&1`
                                    with = message_field_text( lr_so->name ) )
                   type  = `E`
                   field = lr_so->name ).
      ENDTRY.
    ENDLOOP.

    input_convert( mt_cgui_field ).

  ENDMETHOD.

  METHOD input_convert.

    FIELD-SYMBOLS <field_val> TYPE clike.
    FIELD-SYMBOLS <alpha_val> TYPE any.
    DATA lr_val TYPE REF TO data.

    " PARAMETERS without LOWER CASE
    DATA temp468 LIKE LINE OF fields.
    DATA lr_field LIKE REF TO temp468.
    LOOP AT fields REFERENCE INTO lr_field
         WHERE upper = abap_true AND kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-parameter.
      lr_val = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      <field_val> = to_upper( <field_val> ).
    ENDLOOP.

    " the conversion exit ALPHA of a parameter's data element - 4711 into a
    " KUNNR is 0000004711, as SAP GUI stores it
    LOOP AT fields REFERENCE INTO lr_field
         WHERE kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-parameter.
      lr_val = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <alpha_val>.
      z2ui5_cl_cgui_context=>conv_alpha_in( CHANGING val = <alpha_val> ).
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
    DATA temp469 LIKE LINE OF mt_cgui_field.
    DATA lr_field LIKE REF TO temp469.
      DATA lr_range TYPE REF TO data.
      DATA temp470 TYPE ty_s_cgui_so.
      DATA ls_so LIKE temp470.
      DATA lv_index TYPE i.

    CLEAR mt_cgui_so.

    " a range of no line or one simple line shows it in from and to; any
    " other range is shown as text, changed with the multiple selection


    LOOP AT mt_cgui_field REFERENCE INTO lr_field
         WHERE kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option AND no_display = abap_false.

      lr_range = attri_assign( lr_field->name ).
      IF lr_range IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_range->* TO <range>.


      CLEAR temp470.
      temp470-name = lr_field->name.

      ls_so = temp470.
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
            OR ( <opt> = `CP` AND |{ <low> }| NA `*+` )
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

      lv_index = lines( mt_cgui_so ).
      READ TABLE mt_cgui_so INDEX lv_index ASSIGNING <so>.
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

    DATA lv_count TYPE i.
      DATA temp471 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_tab.
      DATA lv_index LIKE sy-index.
    lv_count = screen->get_tabbed_block_count( ).
    WHILE lines( mt_cgui_tab ) < lv_count.

      CLEAR temp471.
      temp471-key = `TAB1`.
      INSERT temp471 INTO TABLE mt_cgui_tab.
    ENDWHILE.

    DO lv_count TIMES.

      lv_index = sy-index.
      READ TABLE mt_cgui_tab INDEX lv_index ASSIGNING <tab>.
      screen->set_tabbed_block_binding( index = lv_index
                                        bind  = client->_bind( val       = <tab>-key
                                                               tab       = mt_cgui_tab
                                                               tab_index = lv_index ) ).
    ENDDO.

  ENDMETHOD.

  METHOD get_link.

    result = z2ui5_cl_cgui_command=>link( ctx         = command_ctx( )
                                          skip_screen = skip_screen ).

  ENDMETHOD.

  METHOD memory_id_store.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>memory_id_store( memory_ctx( ) ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `W` ).
    ENDTRY.

  ENDMETHOD.

  METHOD su3_open.

    DATA lt_field TYPE z2ui5_cl_cgui_popup=>ty_t_field.

    DATA temp472 TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_spa LIKE LINE OF temp472.
      DATA temp473 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp474 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp475 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    temp472 = z2ui5_cl_cgui_memory=>spa_get( memory_ctx( ) ).

    LOOP AT temp472 INTO ls_spa.

      CLEAR temp473.
      temp473-name = ls_spa-n.
      temp473-text = ls_spa-n.
      temp473-value = ls_spa-v.
      INSERT temp473 INTO TABLE lt_field.
    ENDLOOP.
    " a parameter of its own - the ID and the value

    CLEAR temp474.
    temp474-name = `%NEW_ID`.
    temp474-text = 'New parameter ID'(056).
    INSERT temp474 INTO TABLE lt_field.

    CLEAR temp475.
    temp475-name = `%NEW_VALUE`.
    temp475-text = 'Value'(057).
    INSERT temp475 INTO TABLE lt_field.

    mv_cgui_pending_kind = cs_pending-su3.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>get_values(
        fields = lt_field
        title  = 'User parameters'(055)
        text   = 'An empty value deletes the parameter'(058) ) ).

  ENDMETHOD.

  METHOD su3_result.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_popup.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    TRY.
        IF z2ui5_cl_cgui_memory=>su3_result( ctx   = memory_ctx( )
                                             popup = lo_popup ) = abap_true.
          message( text = 'User parameters saved'(059)
                   type = `S` ).
        ENDIF.

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `W` ).
    ENDTRY.

  ENDMETHOD.

  METHOD set_parameter_id.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>param_set( ctx   = memory_ctx( )
                                         id    = id
                                         value = value ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `W` ).
    ENDTRY.

  ENDMETHOD.

  METHOD get_parameter_id.

    result = z2ui5_cl_cgui_memory=>param_get( ctx = memory_ctx( )
                                              id  = id ).

  ENDMETHOD.

  METHOD set_system_parameters.

    z2ui5_cl_cgui_memory=>system_set( ctx    = memory_ctx( )
                                      values = values ).

  ENDMETHOD.

  METHOD authority_check_customizing.

    result = abap_false.

  ENDMETHOD.

  METHOD spro_open.

    DATA lt_field TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA temp476 TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_pair LIKE LINE OF temp476.
      DATA temp477 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp478 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp479 TYPE z2ui5_cl_cgui_popup=>ty_s_field.

    IF authority_check_customizing( ) = abap_false.
      message( text = 'You are not authorized to maintain the customizing'(063)
               type = `E` ).
      RETURN.
    ENDIF.
    " customizing is the installation's, not a browser's
    IF mo_cgui_store IS NOT BOUND.
      message( text = 'The customizing parameters need the variant table on the server'(064)
               type = `E` ).
      RETURN.
    ENDIF.


    temp476 = z2ui5_cl_cgui_memory=>spa_pairs( mv_cgui_spa_cust ).

    LOOP AT temp476 INTO ls_pair.

      CLEAR temp477.
      temp477-name = ls_pair-n.
      temp477-text = ls_pair-n.
      temp477-value = ls_pair-v.
      INSERT temp477 INTO TABLE lt_field.
    ENDLOOP.

    CLEAR temp478.
    temp478-name = `%NEW_ID`.
    temp478-text = 'New parameter ID'(056).
    INSERT temp478 INTO TABLE lt_field.

    CLEAR temp479.
    temp479-name = `%NEW_VALUE`.
    temp479-text = 'Value'(057).
    INSERT temp479 INTO TABLE lt_field.

    mv_cgui_pending_kind = cs_pending-spro.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>get_values(
        fields = lt_field
        title  = 'Customizing parameters'(065)
        text   = 'For every user without a parameter of their own; an empty value deletes it'(066) ) ).

  ENDMETHOD.

  METHOD spro_result.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_popup.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF authority_check_customizing( ) = abap_false.
      RETURN.
    ENDIF.
    TRY.
        IF z2ui5_cl_cgui_memory=>spro_result( ctx   = memory_ctx( )
                                              popup = lo_popup ) = abap_true.
          message( text = 'Customizing parameters saved'(067)
                   type = `S` ).
        ENDIF.

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
    ENDTRY.

  ENDMETHOD.

  METHOD user_command.

    " the answer of a popup the run opened on the selection screen: the
    " rest of START-OF-SELECTION follows in at_user_command( )
    DATA lv_run_answer TYPE abap_bool.
    DATA temp5 TYPE xsdboolean.
      DATA lv_then LIKE mv_cgui_then.
    DATA ls_grid TYPE z2ui5_if_cgui_gui=>ty_s_grid.
    DATA temp480 LIKE sy-subrc.
    DATA temp481 LIKE sy-subrc.
      DATA lv_opened TYPE abap_bool.
      DATA temp6 TYPE xsdboolean.
    temp5 = boolc( mv_cgui_pending_ucomm IS NOT INITIAL AND ucomm = mv_cgui_pending_ucomm AND mv_cgui_screen = cs_screen-selection ).
    lv_run_answer = temp5.
    IF mv_cgui_pending_ucomm IS NOT INITIAL AND ucomm = mv_cgui_pending_ucomm.
      CLEAR mv_cgui_pending_ucomm.
    ENDIF.

    " the answer of a popup with then: its method, not at_user_command( )
    IF ucomm = cs_ucomm-popup_answer AND mv_cgui_then IS NOT INITIAL.

      lv_then = mv_cgui_then.
      CLEAR mv_cgui_then.
      TRY.
          CALL METHOD (lv_then)
            EXPORTING
              answer = popup_answer( ).
        CATCH cx_sy_dyn_call_error.
          message( text = replace( val  = 'No public method &1( answer ) for the popup'(061)
                                   sub  = `&1`
                                   with = lv_then )
                   type = `E` ).
          RETURN.
      ENDTRY.
      IF lv_run_answer = abap_true.
        run_answer_output( ).
      ENDIF.
      RETURN.
    ENDIF.

    " a function of the toolbar of a grid: its event user_command

    READ TABLE mt_cgui_grid INTO ls_grid WITH KEY id = mv_cgui_grid.


    temp481 = sy-subrc.
    READ TABLE ls_grid-functions WITH KEY fcode = ucomm TRANSPORTING NO FIELDS.
    temp480 = sy-subrc.
    sy-subrc = temp481.
    IF sy-subrc = 0 AND temp480 = 0.
      gui_event( id    = mv_cgui_grid
                 event = `USER_COMMAND`
                 value = ucomm ).
    " a function on a dynpro is its PAI
    ELSEIF mv_cgui_screen = cs_screen-dynpro.
      on_dynpro_command( ucomm ).
    " AT USER-COMMAND on a list: what it writes is the next list level,
    " opened by its first output - Back returns to the list shown now
    ELSEIF mv_cgui_screen = cs_screen-output.
      mv_cgui_level_new = abap_true.
      mv_cgui_on_command = abap_true.
      at_user_command( ucomm ).
      mv_cgui_on_command = abap_false.


      temp6 = boolc( mv_cgui_level_new = abap_false ).
      lv_opened = temp6.
      mv_cgui_level_new = abap_false.
      IF lv_opened = abap_true OR mv_cgui_screen <> cs_screen-output.
        level_settle( ).
      ENDIF.
    ELSE.
      at_user_command( ucomm ).
      IF lv_run_answer = abap_true.
        run_answer_output( ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD run_answer_output.

    " the rest of START-OF-SELECTION ran after the answer or the dynpro:
    " END-OF-SELECTION and the list - unless it waits for the next one
    IF mv_cgui_run_wait = abap_true.
      IF mv_cgui_screen <> cs_screen-selection OR run_waits( ) = abap_true.
        RETURN.
      ENDIF.
      mv_cgui_run_wait = abap_false.
      run_done( run( end = abap_true ) ).
      RETURN.
    ENDIF.

    IF mv_cgui_nav = abap_false
        AND ( mo_cgui_alv IS BOUND OR mo_cgui_tree IS BOUND OR z2ui5_cl_cgui_view=>on_list( gui_ctx( ) ) = abap_true
           OR ( mo_cgui_list IS BOUND AND mo_cgui_list->has_content( ) = abap_true ) ).
      mv_cgui_screen = cs_screen-output.
    ENDIF.

  ENDMETHOD.

  METHOD popup_event.
    DATA temp482 TYPE string.

    CLEAR mv_cgui_then.
    IF then IS INITIAL.
      result = ucomm.
      RETURN.
    ENDIF.

    temp482 = then.
    mv_cgui_then = to_upper( condense( temp482 ) ).
    result = cs_ucomm-popup_answer.

  ENDMETHOD.

  METHOD set_command_field.

    mv_cgui_cmd_on = val.

  ENDMETHOD.

  METHOD set_catalog.

    mo_cgui_catalog = val.

  ENDMETHOD.

  METHOD okcode_execute.

    DATA temp483 TYPE string.
    DATA lv_code TYPE string.
    DATA ls_okcode TYPE z2ui5_cl_cgui_command=>ty_s_okcode.
    temp483 = val.

    lv_code = condense( temp483 ).
    CLEAR mv_cgui_okcode.
    IF lv_code IS INITIAL.
      RETURN.
    ENDIF.

    ls_okcode = z2ui5_cl_cgui_command=>okcode_parse( code    = lv_code
                                                           key     = variant_key( )
                                                           catalog = mo_cgui_catalog ).

    CASE ls_okcode-kind.
      WHEN z2ui5_cl_cgui_command=>cs_okcode-start.
        " /nSU3 and /nSPRO are popups of this report
        IF ls_okcode-code(1) = `/` AND ls_okcode-target = `SU3`.
          su3_open( ).
        ELSEIF ls_okcode-code(1) = `/` AND ls_okcode-target = `SPRO`.
          spro_open( ).
        ELSE.
          okcode_start( code       = ls_okcode-target
                        new_window = abap_false ).
        ENDIF.
        RETURN.
      WHEN z2ui5_cl_cgui_command=>cs_okcode-start_new.
        okcode_start( code       = ls_okcode-target
                      new_window = abap_true ).
        RETURN.
      WHEN z2ui5_cl_cgui_command=>cs_okcode-unknown.
        message( text = replace( val  = 'Command &1 is not supported'(050)
                                 sub  = `&1`
                                 with = lv_code )
                 type = `E` ).
        RETURN.
    ENDCASE.

    " an OK code of the screen - the standard ones of the SAP GUI first
    CASE ls_okcode-code.
      WHEN `ONLI` OR `F8`.
        IF mv_cgui_screen = cs_screen-selection.
          on_execute( ).
        ENDIF.
      WHEN `BACK` OR `%EX` OR `RW` OR `F3`.
        on_back( ).
      WHEN `PRI`.
        IF mv_cgui_screen = cs_screen-output.
          on_print( ).
        ENDIF.
      WHEN `SU3`.
        su3_open( ).
      WHEN `SPRO`.
        spro_open( ).
      WHEN OTHERS.
        user_command( ls_okcode-code ).
    ENDCASE.

  ENDMETHOD.

  METHOD okcode_start.

    DATA lo_app TYPE REF TO z2ui5_cl_cgui_report.

    " a report class - nothing else starts from the command field; created
    " also for a new tab: what is no report fails here, not there
    DATA ls_start TYPE z2ui5_cl_cgui_command=>ty_s_start.
    DATA temp484 TYPE string_table.
    ls_start = z2ui5_cl_cgui_command=>start_resolve( code    = code
                                                           catalog = mo_cgui_catalog ).
    lo_app ?= ls_start-app.
    IF lo_app IS NOT BOUND.
      message( text = replace( val  = 'Transaction &1 does not exist'(051)
                               sub  = `&1`
                               with = code )
               type = `E` ).
      RETURN.
    ENDIF.

    IF new_window = abap_false.
      IF ls_start-variant IS NOT INITIAL.
        lo_app->mv_cgui_variant_start = ls_start-variant.
      ENDIF.
      lo_app->mv_cgui_called = abap_true.
      mv_cgui_nav = abap_true.
      client->nav_app_call( lo_app ).
      RETURN.
    ENDIF.

    " a new browser tab: the URL of this one with the other app to start

    CLEAR temp484.
    INSERT z2ui5_cl_cgui_command=>start_url( client = client report = ls_start-report variant = ls_start-variant ) INTO TABLE temp484.
    client->follow_up_action( val   = client->cs_event-open_new_tab
                              t_arg = temp484 ).

  ENDMETHOD.

  METHOD palette_open.

    DATA lt_row TYPE z2ui5_cl_cgui_command=>ty_t_palette.
    lt_row = z2ui5_cl_cgui_command=>palette_rows( command_ctx( ) ).
    mv_cgui_pending_kind = cs_pending-palette.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_select=>factory( tab   = lt_row
                                                         title = 'Commands'(053) ) ).

  ENDMETHOD.

  METHOD palette_result.

    FIELD-SYMBOLS <row> TYPE z2ui5_cl_cgui_command=>ty_s_palette.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA lr_row TYPE REF TO data.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lo_popup->result( )-confirmed = abap_false OR lo_popup->result( )-row IS NOT BOUND.
      RETURN.
    ENDIF.

    lr_row = lo_popup->result( )-row.
    ASSIGN lr_row->* TO <row>.
    okcode_execute( <row>-command ).

  ENDMETHOD.

  METHOD set_job.

    mo_cgui_job = val.

  ENDMETHOD.

  METHOD on_background.

    DATA lt_name TYPE string_table.
    DATA temp486 LIKE LINE OF mt_cgui_field.
    DATA lr_field LIKE REF TO temp486.
    DATA lv_job TYPE string.
    DATA lv_error TYPE string.

    CLEAR mt_cgui_run_msg.
    IF check_screen( ) = abap_false.
      RETURN.
    ENDIF.
    memory_id_store( ).
    z2ui5_cl_cgui_memory=>history_store( memory_ctx( ) ).



    LOOP AT mt_cgui_field REFERENCE INTO lr_field.
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.


    mo_cgui_job->schedule( EXPORTING report = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( )
                                     title  = mv_cgui_title
                                     values = z2ui5_cl_cgui_variant=>values_get( app   = me
                                                                                 names = lt_name )
                           IMPORTING job    = lv_job
                                     error  = lv_error ).
    IF lv_error IS NOT INITIAL.
      message( text = lv_error
               type = `E` ).
      RETURN.
    ENDIF.
    message( text = replace( val  = 'Background job &1 scheduled'(048)
                             sub  = `&1`
                             with = lv_job )
             type = `S` ).

  ENDMETHOD.

  METHOD set_log.

    mo_cgui_app_log = val.

  ENDMETHOD.

  METHOD messages_from_log.
    DATA temp487 TYPE z2ui5_if_cgui_log=>ty_t_message.
    DATA ls_message LIKE LINE OF temp487.
      DATA temp488 TYPE ty_s_cgui_msg.
      DATA ls_msg LIKE temp488.

    IF log IS NOT BOUND.
      RETURN.
    ENDIF.

    temp487 = log->get( ).

    LOOP AT temp487 INTO ls_message.

      CLEAR temp488.
      temp488-type = to_upper( ls_message-type ).
      temp488-text = ls_message-text.

      ls_msg = temp488.
      IF ls_msg-type = `S`.
        INSERT ls_msg INTO TABLE mt_cgui_msg.
      ELSE.
        INSERT ls_msg INTO TABLE mt_cgui_log.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD log_display.

    TYPES:
      BEGIN OF ty_s_row,
        type TYPE c LENGTH 1,
        text TYPE c LENGTH 220,
      END OF ty_s_row.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA lt_row TYPE temp4.
    DATA temp489 TYPE z2ui5_if_cgui_log=>ty_t_message.
    DATA ls_message LIKE LINE OF temp489.
      DATA temp490 TYPE ty_s_row.
    DATA temp491 TYPE string.

    IF log IS NOT BOUND OR client IS NOT BOUND.
      RETURN.
    ENDIF.

    temp489 = log->get( ).

    LOOP AT temp489 INTO ls_message.

      CLEAR temp490.
      temp490-type = ls_message-type.
      temp490-text = ls_message-text.
      INSERT temp490 INTO TABLE lt_row.
    ENDLOOP.
    mv_cgui_nav = abap_true.

    IF title IS INITIAL.
      temp491 = 'Application Log'(060).
    ELSE.
      temp491 = title.
    ENDIF.
    client->nav_app_call( z2ui5_cl_cgui_select=>factory(
        tab   = lt_row
        title = temp491 ) ).

  ENDMETHOD.

  METHOD set_fresh_start.

    DATA temp7 TYPE xsdboolean.
    temp7 = boolc( val = abap_false ).
    mv_cgui_fresh_off = temp7.

  ENDMETHOD.

  METHOD fresh_keep.

    DATA lr_copy TYPE REF TO data.
    DATA lo_me   TYPE REF TO object.
    " unbound - only its type is read: a namespace rename rewrites the
    " reference, never a literal naming the class
    DATA lo_report TYPE REF TO z2ui5_cl_cgui_report.
    FIELD-SYMBOLS <attri> TYPE any.
    FIELD-SYMBOLS <copy>  TYPE any.
    DATA temp492 TYPE REF TO cl_abap_classdescr.
    DATA temp41 TYPE REF TO cl_abap_refdescr.
    DATA lo_base LIKE temp492.
    DATA temp493 TYPE REF TO cl_abap_classdescr.
    DATA lo_class LIKE temp493.
    DATA temp494 LIKE LINE OF lo_class->attributes.
    DATA lr_attri LIKE REF TO temp494.
      DATA temp495 LIKE sy-subrc.
      DATA temp496 TYPE ty_s_cgui_fresh.
      DATA ls_fresh LIKE temp496.

    CLEAR mt_cgui_fresh.
    IF mv_cgui_fresh_off = abap_true.
      RETURN.
    ENDIF.
    " the attributes of the runtime are not the report's data


    temp41 ?= cl_abap_typedescr=>describe_by_data( lo_report ).
    temp492 ?= temp41->get_referenced_type( ).

    lo_base = temp492.

    temp493 ?= cl_abap_typedescr=>describe_by_object_ref( me ).

    lo_class = temp493.
    lo_me = me.


    LOOP AT lo_class->attributes REFERENCE INTO lr_attri
         WHERE visibility = cl_abap_classdescr=>public AND is_constant = abap_false AND is_class = abap_false.

      READ TABLE lo_base->attributes WITH KEY name = lr_attri->name TRANSPORTING NO FIELDS.
      temp495 = sy-subrc.
      IF temp495 = 0.
        CONTINUE.
      ENDIF.
      UNASSIGN <attri>.
      ASSIGN lo_me->(lr_attri->name) TO <attri>.
      IF <attri> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      " a reference as the reference it is - an object of the report stays
      " that object; CREATE DATA LIKE does not take a bound one everywhere

      CLEAR temp496.
      temp496-name = lr_attri->name.
      temp496-kind = lr_attri->type_kind.

      ls_fresh = temp496.
      CASE lr_attri->type_kind.
        WHEN cl_abap_typedescr=>typekind_oref.
          ls_fresh-obj = <attri>.
        WHEN cl_abap_typedescr=>typekind_dref.
          ls_fresh-dref = <attri>.
        WHEN OTHERS.
          CREATE DATA lr_copy LIKE <attri>.
          ASSIGN lr_copy->* TO <copy>.
          <copy> = <attri>.
          ls_fresh-value = lr_copy.
      ENDCASE.
      INSERT ls_fresh INTO TABLE mt_cgui_fresh.
    ENDLOOP.

  ENDMETHOD.

  METHOD fresh_restart.

    DATA lt_screen TYPE ty_t_cgui_fresh.
    DATA lr_copy   TYPE REF TO data.
    DATA lo_me     TYPE REF TO object.
    FIELD-SYMBOLS <attri> TYPE any.
    FIELD-SYMBOLS <copy>  TYPE any.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA temp497 LIKE LINE OF lt_field.
    DATA lr_field LIKE REF TO temp497.
      DATA temp498 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_fresh.
    DATA ls_fresh LIKE LINE OF mt_cgui_fresh.
    DATA ls_screen LIKE LINE OF lt_screen.

    IF mv_cgui_fresh_off = abap_true OR mt_cgui_fresh IS INITIAL.
      RETURN.
    ENDIF.
    lo_me = me.
    " the input of the selection screen survives the restart - its fields,
    " not those of a dynpro shown last

    lt_field = screen_fields( ).


    LOOP AT lt_field REFERENCE INTO lr_field.
      UNASSIGN <attri>.
      ASSIGN lo_me->(lr_field->name) TO <attri>.
      IF <attri> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      CREATE DATA lr_copy LIKE <attri>.
      ASSIGN lr_copy->* TO <copy>.
      <copy> = <attri>.

      CLEAR temp498.
      temp498-name = lr_field->name.
      temp498-value = lr_copy.
      INSERT temp498 INTO TABLE lt_screen.
    ENDLOOP.
    " the data as initialization( ) left it, then initialization( ) again

    LOOP AT mt_cgui_fresh INTO ls_fresh.
      UNASSIGN <attri>.
      ASSIGN lo_me->(ls_fresh-name) TO <attri>.
      IF <attri> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      CASE ls_fresh-kind.
        WHEN cl_abap_typedescr=>typekind_oref.
          <attri> ?= ls_fresh-obj.
        WHEN cl_abap_typedescr=>typekind_dref.
          <attri> = ls_fresh-dref.
        WHEN OTHERS.
          ASSIGN ls_fresh-value->* TO <copy>.
          <attri> = <copy>.
      ENDCASE.
    ENDLOOP.
    initialization( ).

    LOOP AT lt_screen INTO ls_screen.
      ASSIGN lo_me->(ls_screen-name) TO <attri>.
      ASSIGN ls_screen-value->* TO <copy>.
      <attri> = <copy>.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_draft.

    mv_cgui_draft = val.

  ENDMETHOD.

  METHOD draft_keep.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>draft_keep( memory_ctx( ) ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
    ENDTRY.

  ENDMETHOD.

  METHOD draft_restore.

    IF z2ui5_cl_cgui_memory=>draft_restore( ctx    = memory_ctx( )
                                            fields = screen_fields( ) ) = abap_true.
      message( 'Your entries that were not executed are back as a draft'(070) ).
    ENDIF.

  ENDMETHOD.

  METHOD draft_drop.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>draft_drop( memory_ctx( ) ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
    ENDTRY.

  ENDMETHOD.

  METHOD draft_discard.

    FIELD-SYMBOLS <field_val> TYPE any.
    DATA temp499 LIKE LINE OF mt_cgui_field.
    DATA lr_field LIKE REF TO temp499.
      DATA lr_val TYPE REF TO data.

    draft_drop( ).


    LOOP AT mt_cgui_field REFERENCE INTO lr_field.

      lr_val = attri_assign( lr_field->name ).
      IF lr_val IS BOUND.
        ASSIGN lr_val->* TO <field_val>.
        CLEAR <field_val>.
      ENDIF.
    ENDLOOP.
    initialization( ).
    " what initialization( ) set is no draft
    draft_keep( ).
    draft_drop( ).

  ENDMETHOD.

  METHOD set_prefill_last.

    mv_cgui_prefill = val.

  ENDMETHOD.

  METHOD on_storage_loaded.

    " the storage controls have put what the browser holds into
    " mv_cgui_variants and mv_cgui_spa: the parameter IDs fill empty fields,
    " then the last entries (set_prefill_last( )), the start variant
    " overwrites them, the URL wins over both
    z2ui5_cl_cgui_memory=>memory_id_apply( memory_ctx( ) ).
    IF mv_cgui_prefill = abap_true.
      z2ui5_cl_cgui_memory=>history_apply( memory_ctx( ) ).
    ENDIF.
    " a draft wins over the last entries, the start variant over the draft
    " (a server store has it from on_init( ))
    IF mv_cgui_draft = abap_true AND mo_cgui_store IS NOT BOUND AND mv_cgui_variant_start IS INITIAL.
      draft_restore( ).
    ENDIF.

    IF mv_cgui_variant_start IS NOT INITIAL.
      variant_start_apply( ).
      z2ui5_cl_cgui_command=>url_values_apply( command_ctx( ) ).
    ENDIF.

    auto_execute( ).

  ENDMETHOD.

  METHOD variant_start_apply.

    DATA lv_start LIKE mv_cgui_variant_start.
    lv_start = mv_cgui_variant_start.
    CLEAR mv_cgui_variant_start.
    IF z2ui5_cl_cgui_memory=>variant_apply( ctx    = memory_ctx( )
                                            fields = screen_fields( )
                                            name   = lv_start ) = abap_false AND mv_cgui_variant_url = abap_true.
      message( text = replace( val  = 'Variant &1 does not exist'(002)
                               sub  = `&1`
                               with = lv_start )
               type = `W` ).
    ENDIF.

  ENDMETHOD.

  METHOD auto_execute.

    IF mv_cgui_auto_exec = abap_false.
      RETURN.
    ENDIF.
    CLEAR: mv_cgui_auto_exec, mv_cgui_variant_start.
    mv_cgui_skipped = abap_true.
    on_execute( ).

  ENDMETHOD.

  METHOD variant_popup.

    DATA lt_row TYPE ty_t_variant_row.

    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
      DATA temp500 TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
      DATA temp501 TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA temp502 LIKE LINE OF lt_variant.
    DATA lr_variant LIKE REF TO temp502.
      DATA temp503 TYPE z2ui5_cl_cgui_report=>ty_s_variant_row.
      DATA temp42 TYPE z2ui5_cl_cgui_report=>ty_s_variant_row-values.
    DATA temp504 TYPE string.
    lt_variant = z2ui5_cl_cgui_memory=>variant_catalog( memory_ctx( ) ).
    " a draft is no variant to pick or save over
    DELETE lt_variant WHERE name CP `%DRAFT_*`.

    IF kind = cs_pending-variant_save.

      CLEAR temp500.

      READ TABLE lt_variant INTO temp501 WITH KEY name = mv_cgui_variant.
      IF sy-subrc = 0.
        temp500 = temp501.
      ENDIF.
      variant_popup_save( temp500 ).
      RETURN.
    ENDIF.

    " the layouts of the ALV are kept as variants too - they are none
    DELETE lt_variant WHERE name CP '##*'.
    IF lt_variant IS INITIAL.
      message( text = 'No variants saved for this report yet'(015)
               type = `I` ).
      RETURN.
    ENDIF.



    LOOP AT lt_variant REFERENCE INTO lr_variant.

      CLEAR temp503.
      temp503-variant = lr_variant->name.

      IF lr_variant->owner IS NOT INITIAL.
        temp42 = |{ lr_variant->text } ({ lr_variant->owner })|.
      ELSE.
        temp42 = lr_variant->text.
      ENDIF.
      temp503-values = temp42.
      INSERT temp503 INTO TABLE lt_row.
    ENDLOOP.

    mv_cgui_pending_kind = kind.
    mv_cgui_nav = abap_true.

    IF kind = cs_pending-variant_delete.
      temp504 = 'Delete Variant'(007).
    ELSE.
      temp504 = 'Get Variant'(016).
    ENDIF.
    client->nav_app_call( z2ui5_cl_cgui_select=>factory(
        tab   = lt_row
        title = temp504 ) ).

  ENDMETHOD.

  METHOD variant_popup_save.

    DATA lt_field TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA lt_listbox TYPE z2ui5_cl_cgui_popup=>ty_t_listbox.

    " the name, the sharing of a server store, and a dynamic date for
    " every date of the screen
    DATA temp505 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp43 TYPE z2ui5_cl_cgui_popup=>ty_s_field-text.
      DATA temp506 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
      DATA temp44 TYPE z2ui5_cl_cgui_popup=>ty_s_field-text.
      DATA temp507 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
      DATA temp45 TYPE z2ui5_cl_cgui_popup=>ty_s_field-text.
    DATA temp508 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp46 TYPE z2ui5_cl_cgui_popup=>ty_s_field-text.
    DATA temp509 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
    DATA temp47 TYPE z2ui5_cl_cgui_popup=>ty_s_field-text.
    DATA temp510 LIKE LINE OF mt_cgui_field.
    DATA lr_attr LIKE REF TO temp510.
      DATA temp511 TYPE z2ui5_cl_cgui_popup=>ty_s_listbox.
      DATA temp48 TYPE z2ui5_cl_cgui_popup=>ty_s_listbox-text.
      DATA temp512 TYPE z2ui5_cl_cgui_popup=>ty_s_listbox.
      DATA temp49 TYPE z2ui5_cl_cgui_popup=>ty_s_listbox-text.
    DATA temp513 TYPE string.
    CLEAR temp505.
    temp505-name = `NAME`.

    temp43 = 'Variant name'(009).
    temp505-text = temp43.
    temp505-value = mv_cgui_variant.
    temp505-required = abap_true.
    INSERT temp505 INTO TABLE lt_field.
    IF mo_cgui_store IS BOUND AND mo_cgui_store->check_sharing( ) = abap_true.

      CLEAR temp506.
      temp506-name = `SHARED`.

      temp44 = 'Shared with all users'(010).
      temp506-text = temp44.
      temp506-kind = z2ui5_cl_cgui_popup=>cs_kind-checkbox.
      temp506-flag = current-shared.
      INSERT temp506 INTO TABLE lt_field.

      CLEAR temp507.
      temp507-name = `PROTECTED`.

      temp45 = 'Protected - only I change it'(011).
      temp507-text = temp45.
      temp507-kind = z2ui5_cl_cgui_popup=>cs_kind-checkbox.
      temp507-flag = current-protected.
      INSERT temp507 INTO TABLE lt_field.
    ENDIF.
    " the variant attributes: fields protected or hidden

    CLEAR temp508.
    temp508-name = `PROTECT`.

    temp46 = 'Protected fields'(038).
    temp508-text = temp46.
    temp508-kind = z2ui5_cl_cgui_popup=>cs_kind-multi.
    temp508-keys = current-protect.
    INSERT temp508 INTO TABLE lt_field.

    CLEAR temp509.
    temp509-name = `HIDE`.

    temp47 = 'Hidden fields'(039).
    temp509-text = temp47.
    temp509-kind = z2ui5_cl_cgui_popup=>cs_kind-multi.
    temp509-keys = current-hide.
    INSERT temp509 INTO TABLE lt_field.


    LOOP AT mt_cgui_field REFERENCE INTO lr_attr WHERE no_display = abap_false AND name IS NOT INITIAL.

      CLEAR temp511.
      temp511-name = `PROTECT`.
      temp511-key = lr_attr->name.

      IF lr_attr->text IS NOT INITIAL.
        temp48 = lr_attr->text.
      ELSE.
        temp48 = lr_attr->name.
      ENDIF.
      temp511-text = temp48.
      INSERT temp511 INTO TABLE lt_listbox.

      CLEAR temp512.
      temp512-name = `HIDE`.
      temp512-key = lr_attr->name.

      IF lr_attr->text IS NOT INITIAL.
        temp49 = lr_attr->text.
      ELSE.
        temp49 = lr_attr->name.
      ENDIF.
      temp512-text = temp49.
      INSERT temp512 INTO TABLE lt_listbox.
    ENDLOOP.
    variant_popup_dynamic( EXPORTING current = current
                           CHANGING  fields  = lt_field
                                     listbox = lt_listbox ).

    mv_cgui_pending_kind = cs_pending-variant_save.
    mv_cgui_nav = abap_true.

    temp513 = 'Save as Variant'(014).
    client->nav_app_call( z2ui5_cl_cgui_popup=>get_values( fields  = lt_field
                                                           listbox = lt_listbox
                                                           title   = temp513
                                                           event   = cs_ucomm-variant_saved ) ).

  ENDMETHOD.

  METHOD variant_popup_dynamic.

    DATA ls_old TYPE z2ui5_cl_cgui_variant=>ty_s_value.
    FIELD-SYMBOLS <field_val> TYPE any.

    DATA lt_dynamic TYPE z2ui5_cl_cgui_selscreen=>ty_t_value.
    DATA temp514 LIKE LINE OF mt_cgui_field.
    DATA lr_field LIKE REF TO temp514.
      DATA lr_val TYPE REF TO data.
      DATA lo_descr TYPE REF TO cl_abap_typedescr.
      DATA temp515 TYPE z2ui5_cl_cgui_variant=>ty_s_value.
      DATA temp516 TYPE z2ui5_cl_cgui_variant=>ty_s_value.
      DATA temp517 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
        DATA temp518 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
      DATA ls_dynamic LIKE LINE OF lt_dynamic.
        DATA temp519 TYPE z2ui5_cl_cgui_popup=>ty_s_listbox.
        DATA temp520 TYPE z2ui5_cl_cgui_popup=>ty_s_listbox.
    lt_dynamic = z2ui5_cl_cgui_variant=>dynamic_values( ).


    LOOP AT mt_cgui_field REFERENCE INTO lr_field WHERE no_display = abap_false.

      lr_val = attri_assign( lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.

      lo_descr = z2ui5_cl_cgui_context=>rtti_get_value_descr( <field_val> ).
      IF lo_descr IS NOT BOUND OR lo_descr->type_kind <> cl_abap_typedescr=>typekind_date.
        CONTINUE.
      ENDIF.

      CLEAR temp515.

      READ TABLE current-values INTO temp516 WITH KEY name = lr_field->name.
      IF sy-subrc = 0.
        temp515 = temp516.
      ENDIF.
      ls_old = temp515.

      CLEAR temp517.
      temp517-name = |DYN_{ lr_field->name }|.
      temp517-text = replace( val = 'Dynamic date &1'(012) sub = `&1` with = lr_field->text ).
      temp517-kind = z2ui5_cl_cgui_popup=>cs_kind-listbox.
      temp517-value = ls_old-dynamic.
      INSERT temp517 INTO TABLE fields.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.

        CLEAR temp518.
        temp518-name = |DYNH_{ lr_field->name }|.
        temp518-text = replace( val = 'Dynamic date &1 (to)'(013) sub = `&1` with = lr_field->text ).
        temp518-kind = z2ui5_cl_cgui_popup=>cs_kind-listbox.
        temp518-value = ls_old-dynamic_high.
        INSERT temp518 INTO TABLE fields.
      ENDIF.

      LOOP AT lt_dynamic INTO ls_dynamic.

        CLEAR temp519.
        temp519-name = |DYN_{ lr_field->name }|.
        temp519-key = ls_dynamic-key.
        temp519-text = ls_dynamic-text.
        INSERT temp519 INTO TABLE listbox.

        CLEAR temp520.
        temp520-name = |DYNH_{ lr_field->name }|.
        temp520-key = ls_dynamic-key.
        temp520-text = ls_dynamic-text.
        INSERT temp520 INTO TABLE listbox.
      ENDLOOP.
    ENDLOOP.


  ENDMETHOD.

  METHOD variant_selected.

    FIELD-SYMBOLS <row> TYPE ty_s_variant_row.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.


    ls_result = lo_popup->result( ).
    IF ls_result-confirmed = abap_false OR ls_result-row IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ls_result-row->* TO <row>.
    result = condense( <row>-variant ).

  ENDMETHOD.

  METHOD variant_save.
        DATA lv_name TYPE string.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.

        lv_name = z2ui5_cl_cgui_memory=>variant_save( ctx   = memory_ctx( )
                                                            popup = popup ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
        RETURN.
    ENDTRY.
    message( replace( val  = 'Variant &1 saved'(018)
                      sub  = `&1`
                      with = lv_name ) ).

  ENDMETHOD.

  METHOD variant_delete.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>variant_delete( ctx  = memory_ctx( )
                                              name = name ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
        RETURN.
    ENDTRY.
    message( replace( val  = 'Variant &1 deleted'(019)
                      sub  = `&1`
                      with = name ) ).

  ENDMETHOD.

  METHOD variant_key.

    result = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).

  ENDMETHOD.

  METHOD memory_ctx.

    CLEAR result.
    result-app = me.
    result-client = client.
    result-store = mo_cgui_store.
    result-key = variant_key( ).
    result-batch = mv_cgui_batch.
    GET REFERENCE OF mt_cgui_field INTO result-fields.
    GET REFERENCE OF mv_cgui_variants INTO result-variants.
    GET REFERENCE OF mv_cgui_variant INTO result-variant.
    GET REFERENCE OF mv_cgui_variant_start INTO result-variant_start.
    GET REFERENCE OF mv_cgui_variant_url INTO result-variant_url.
    GET REFERENCE OF mt_cgui_var_protect INTO result-protect.
    GET REFERENCE OF mt_cgui_var_hide INTO result-hide.
    GET REFERENCE OF mv_cgui_spa INTO result-spa.
    GET REFERENCE OF mv_cgui_spa_cust INTO result-spa_cust.
    GET REFERENCE OF mt_cgui_spa_system INTO result-spa_system.
    GET REFERENCE OF mv_cgui_history INTO result-history.
    GET REFERENCE OF mv_cgui_draft_last INTO result-draft_last.
    GET REFERENCE OF mv_cgui_draft_restored INTO result-draft_restore.

  ENDMETHOD.

  METHOD command_ctx.
    DATA temp8 TYPE xsdboolean.
    DATA temp9 TYPE xsdboolean.

    CLEAR result.
    result-app = me.
    result-client = client.
    result-key = variant_key( ).
    result-catalog = mo_cgui_catalog.

    temp8 = boolc( mv_cgui_screen = cs_screen-selection ).
    result-selection = temp8.

    temp9 = boolc( mv_cgui_screen = cs_screen-output ).
    result-output = temp9.
    result-cmd_on = mv_cgui_cmd_on.
    GET REFERENCE OF mt_cgui_field INTO result-fields.
    GET REFERENCE OF mt_cgui_url INTO result-url.
    result-fkeys = mt_cgui_fkey.
    GET REFERENCE OF mt_cgui_gui INTO result-gui.
    result-pf_keys = mt_cgui_pf_keys.
    result-excl_out = mt_cgui_excl_out.

  ENDMETHOD.

  METHOD variant_from_url.

    result = z2ui5_cl_cgui_command=>url_param( client = client
                                               name   = `VARIANT` ).

  ENDMETHOD.

  METHOD set_variant.

    DATA lv_name TYPE string.

    lv_name = name.
    mv_cgui_variant_url = abap_false.
    IF mv_cgui_variants IS INITIAL OR z2ui5_cl_cgui_memory=>variant_apply( ctx    = memory_ctx( )
                                                                           fields = screen_fields( )
                                                                           name   = lv_name ) = abap_false.
      mv_cgui_variant_start = lv_name.
    ENDIF.

  ENDMETHOD.

  METHOD set_variant_store.
    DATA temp10 TYPE xsdboolean.

    mo_cgui_store = store.

    temp10 = boolc( store IS NOT BOUND ).
    mv_cgui_store_none = temp10.

  ENDMETHOD.

  METHOD set_layout_store.
    DATA temp11 TYPE xsdboolean.

    mo_cgui_lay_store = store.

    temp11 = boolc( store IS NOT BOUND ).
    mv_cgui_lay_none = temp11.

  ENDMETHOD.

  METHOD layout_store.

    IF mo_cgui_lay_store IS NOT BOUND AND mv_cgui_lay_none = abap_false.
      mo_cgui_lay_store = z2ui5_cl_cgui_layout_db=>factory( ).
    ENDIF.
    result = mo_cgui_lay_store.

  ENDMETHOD.

  METHOD layout_handle.

    DATA temp521 TYPE string.
    IF mv_cgui_alv_name IS NOT INITIAL.
      temp521 = to_upper( mv_cgui_alv_name ).
    ELSE.
      temp521 = `ALV`.
    ENDIF.
    result = temp521.

  ENDMETHOD.

  METHOD layout_store_change.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

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

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
    ENDTRY.

  ENDMETHOD.

  METHOD on_execute.

    run_done( run( ) ).

  ENDMETHOD.

  METHOD run_waits.

    DATA temp12 TYPE xsdboolean.
    temp12 = boolc( mv_cgui_screen = cs_screen-dynpro OR ( mv_cgui_nav = abap_true AND ( mv_cgui_pending_ucomm IS NOT INITIAL OR mv_cgui_pending_kind = cs_pending-screen ) ) ).
    result = temp12.

  ENDMETHOD.

  METHOD run_done.

    IF ok = abap_true.
      CLEAR mv_cgui_restart.
      mv_cgui_screen = cs_screen-output.
      IF mv_cgui_draft = abap_true.
        draft_drop( ).
      ENDIF.
    ELSEIF mv_cgui_skipped = abap_true.
      " a run without selection screen that stopped shows the screen
      mv_cgui_skipped = abap_false.
    ENDIF.
    restart_pending( ).

  ENDMETHOD.

  METHOD gui_release.

    TYPES temp5 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA lt_dead TYPE temp5.

    FIELD-SYMBOLS <control> LIKE LINE OF mt_cgui_gui.
      DATA lv_id LIKE sy-tabix.
      FIELD-SYMBOLS <object> TYPE REF TO object.
    DATA lt_handler TYPE z2ui5_if_cgui_gui=>ty_t_handler.
    DATA lv_before TYPE i.
    LOOP AT mt_cgui_gui ASSIGNING <control>.

      lv_id = sy-tabix.
      IF gui_alive( lv_id ) = abap_true.
        CONTINUE.
      ENDIF.

      READ TABLE mt_cgui_gui_obj ASSIGNING <object> INDEX lv_id.
      IF sy-subrc = 0 AND <object> IS BOUND.
        CLEAR <object>.
        INSERT lv_id INTO TABLE lt_dead.
      ENDIF.
      CLEAR: <control>-text, <control>-html, <control>-url, <control>-buttons.
    ENDLOOP.
    IF lt_dead IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_dead INTO lv_id.
      DELETE mt_cgui_grid WHERE id = lv_id.
    ENDLOOP.
    " the handlers of the controls left - their objects once each again

    lt_handler = z2ui5_if_cgui_gui~handlers_get( ).

    lv_before = lines( lt_handler ).
    LOOP AT lt_dead INTO lv_id.
      DELETE lt_handler WHERE id = lv_id.
    ENDLOOP.
    IF lines( lt_handler ) < lv_before.
      z2ui5_if_cgui_gui~handlers_set( lt_handler ).
    ENDIF.

  ENDMETHOD.

  METHOD restart_pending.

    IF mv_cgui_restart = abap_false.
      RETURN.
    ENDIF.
    CLEAR: mv_cgui_restart, mv_cgui_run_wait.
    IF mv_cgui_screen <> cs_screen-selection.
      RETURN.
    ENDIF.
    " the classic report starts anew after its run: an E message, LEAVE
    " LIST-PROCESSING, an empty list, Back - what the run collected is gone
    output_clear( ).
    fresh_restart( ).

  ENDMETHOD.

  METHOD output_clear.
    FIELD-SYMBOLS <control> LIKE LINE OF mt_cgui_gui.

    CLEAR: mo_cgui_list, mo_cgui_tree, mt_cgui_tree_view, mt_cgui_list_input, mt_cgui_level,
           mr_cgui_alv_page, mt_cgui_alv_index, mt_cgui_alv_order,
           mv_cgui_window, mv_cgui_window_title, mv_cgui_window_cols, mv_cgui_window_lines,
           mt_cgui_pf, mt_cgui_pf_keys, mt_cgui_excl_out.
    " the controls of the list of the run before - the run creates its own

    LOOP AT mt_cgui_gui ASSIGNING <control> WHERE parent = 0 AND dynnr = `LIST`.
      <control>-freed = abap_true.
    ENDLOOP.
    " the ALV - unless a grid on a screen of the report shows it
    IF mv_cgui_grid IS INITIAL OR gui_alive( mv_cgui_grid ) = abap_false.
      CLEAR: mo_cgui_alv, mr_cgui_alv, mr_cgui_alv_box, mv_cgui_alv_name,
             mv_cgui_grid, mr_cgui_grid_fieldcat, mr_cgui_grid_layout.
    ENDIF.

  ENDMETHOD.

  METHOD check_screen.
    DATA temp13 TYPE xsdboolean.

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

    IF check_values( ) = abap_false.
      RETURN.
    ENDIF.

    IF check_events( ) = abap_false.
      RETURN.
    ENDIF.

    at_selection_screen( ).

    temp13 = boolc( mv_cgui_stop = abap_false ).
    result = temp13.

  ENDMETHOD.

  METHOD run.

    " a run that stops for a dialog (z2ui5_cx_cgui_stop) starts again from it
    mv_cgui_in_run = abap_true.
    TRY.
        IF end = abap_true.
          result = run_end( ).
        ELSE.
          result = run_steps( ).
        ENDIF.
      CATCH z2ui5_cx_cgui_stop.
        mv_cgui_stop = abap_true.
    ENDTRY.
    mv_cgui_in_run = abap_false.

  ENDMETHOD.

  METHOD run_steps.

    CLEAR mt_cgui_run_msg.
    IF check_screen( ) = abap_false.
      RETURN.
    ENDIF.

    memory_id_store( ).
    z2ui5_cl_cgui_memory=>history_store( memory_ctx( ) ).

    output_clear( ).
    CLEAR: mo_cgui_alv, mr_cgui_alv, mr_cgui_alv_box, mv_cgui_alv_name,
           mt_cgui_grid, mv_cgui_grid, mr_cgui_grid_fieldcat, mr_cgui_grid_layout,
           mv_cgui_pending_ucomm, mv_cgui_run_wait.
    mv_cgui_left = abap_false.
    " from here on a run that ends on the selection screen restarts the report
    mv_cgui_restart = abap_true.
    start_of_selection( ).
    " CALL SCREEN, a popup that answers with a user command: the dynpro or
    " the popup shows, the rest of the run follows when it returns
    IF mv_cgui_stop = abap_false AND mv_cgui_left = abap_false AND run_waits( ) = abap_true.
      mv_cgui_run_wait = abap_true.
      mv_cgui_restart = abap_false.
      RETURN.
    ENDIF.
    result = run_end( ).

  ENDMETHOD.

  METHOD run_end.

    mv_cgui_restart = abap_true.
    IF mv_cgui_stop = abap_true OR mv_cgui_left = abap_true.
      RETURN.
    ENDIF.
    end_of_selection( ).
    IF mv_cgui_stop = abap_true OR mv_cgui_left = abap_true.
      RETURN.
    ENDIF.
    IF mo_cgui_list IS BOUND.
      mo_cgui_list->footer_begin( ).
      end_of_page( ).
      mo_cgui_list->footer_end( ).
    ENDIF.

    IF mo_cgui_alv IS NOT BOUND AND mo_cgui_tree IS NOT BOUND AND z2ui5_cl_cgui_view=>on_list( gui_ctx( ) ) = abap_false
        AND ( mo_cgui_list IS NOT BOUND OR mo_cgui_list->has_content( ) = abap_false ).
      message( 'List contains no data'(020) ).
      RETURN.
    ENDIF.

    result = abap_true.

  ENDMETHOD.

  METHOD cgui_run_in_background.

    FIELD-SYMBOLS <src> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA temp522 LIKE LINE OF mt_cgui_field.
    DATA lr_field LIKE REF TO temp522.
      DATA temp14 TYPE xsdboolean.
    DATA lv_ok TYPE abap_bool.
    DATA temp523 LIKE LINE OF mt_cgui_run_msg.
    DATA lr_msg LIKE REF TO temp523.
      DATA temp524 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_message.
        DATA lt_lazy TYPE z2ui5_cl_cgui_tree=>ty_t_key.
        DATA lv_lazy LIKE LINE OF lt_lazy.
      DATA lo_tree_list TYPE REF TO z2ui5_cl_cgui_list.
      DATA temp525 TYPE string_table.
      DATA lv_tree_line LIKE LINE OF temp525.
        DATA temp526 TYPE string_table.
        DATA lv_list_line LIKE LINE OF temp526.
    DATA lr_src TYPE REF TO data.

    CLEAR: list, alv, alv_data, pdf, messages.
    at_roundtrip_start( ).
    mv_cgui_batch = abap_true.
    mv_cgui_screen = cs_screen-selection.
    mv_cgui_title = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).

    initialization( ).
    z2ui5_cl_cgui_variant=>values_set( app    = me
                                       values = values ).
    mt_cgui_field = screen_fields( ).


    LOOP AT mt_cgui_field REFERENCE INTO lr_field.

      temp14 = boolc( lr_field->no_display = abap_false ).
      lr_field->shown = temp14.
    ENDLOOP.


    lv_ok = run( ).



    LOOP AT mt_cgui_run_msg REFERENCE INTO lr_msg.

      CLEAR temp524.
      temp524-type = lr_msg->type.
      temp524-text = lr_msg->text.
      INSERT temp524 INTO TABLE messages.
    ENDLOOP.
    IF lv_ok = abap_false.
      RETURN.
    ENDIF.

    " the tree as text in front of the list - the spool has no hierarchy
    IF mo_cgui_tree IS BOUND.
      " nobody opens a node in the background: the lazy ones are loaded
      " here, level by level - at most 50 levels deep
      DO 50 TIMES.

        lt_lazy = mo_cgui_tree->get_lazy_nodes( ).
        IF lt_lazy IS INITIAL.
          EXIT.
        ENDIF.

        LOOP AT lt_lazy INTO lv_lazy.
          mo_cgui_tree->set_loaded( lv_lazy ).
          tree_expand( lv_lazy ).
        ENDLOOP.
      ENDDO.
      mo_cgui_tree->expand_all( ).

      lo_tree_list = z2ui5_cl_cgui_list=>factory( ).

      temp525 = mo_cgui_tree->to_text( ).

      LOOP AT temp525 INTO lv_tree_line.
        lo_tree_list->write( lv_tree_line )->new_line( ).
      ENDLOOP.
      IF mo_cgui_list IS BOUND.

        temp526 = mo_cgui_list->to_text( ).

        LOOP AT temp526 INTO lv_list_line.
          lo_tree_list->write( lv_list_line )->new_line( ).
        ENDLOOP.
      ENDIF.
      mo_cgui_list = lo_tree_list.
    ENDIF.
    list = mo_cgui_list.
    alv = mo_cgui_alv.
    pdf = z2ui5_cl_cgui_pdf=>from_lines( lines = print_lines( )
                                         title = mv_cgui_title ).

    lr_src = alv_source( ).
    IF alv IS BOUND AND lr_src IS BOUND.
      ASSIGN lr_src->* TO <src>.
      CREATE DATA alv_data LIKE <src>.
      ASSIGN alv_data->* TO <tab>.
      <tab> = <src>.
    ENDIF.

  ENDMETHOD.

  METHOD check_values.

    FIELD-SYMBOLS <field_val> TYPE any.
    DATA temp527 LIKE LINE OF mt_cgui_field.
    DATA lr_field LIKE REF TO temp527.
      DATA lr_val TYPE REF TO data.

    result = abap_true.

    " VALUE CHECK - one message per field with a value that is not allowed


    LOOP AT mt_cgui_field REFERENCE INTO lr_field WHERE value_check = abap_true AND shown = abap_true.

      lr_val = attri_assign( lr_field->name ).
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

  ENDMETHOD.

  METHOD check_events.

    DATA lt_shown TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA ls_next  TYPE z2ui5_cl_cgui_selscreen=>ty_s_field.

    DATA ls_shown LIKE LINE OF mt_cgui_field.
    DATA ls_field LIKE LINE OF lt_shown.
      DATA lv_index LIKE sy-tabix.
      DATA lv_block TYPE i.
        DATA lv_name TYPE string.
        FIELD-SYMBOLS <temp50> LIKE LINE OF ls_field-blocks.
        DATA temp51 LIKE sy-tabix.
        DATA temp528 LIKE sy-subrc.
        DATA temp529 LIKE sy-tabix.
        DATA ls_first LIKE LINE OF lt_shown.
          DATA temp530 LIKE sy-subrc.
          DATA temp531 LIKE sy-tabix.
    LOOP AT mt_cgui_field INTO ls_shown WHERE shown = abap_true.
      INSERT ls_shown INTO TABLE lt_shown.
    ENDLOOP.


    LOOP AT lt_shown INTO ls_field.

      lv_index = sy-tabix.
      mv_cgui_on_field = ls_field-name.
      at_selection_screen_on( ls_field-name ).
      CLEAR mv_cgui_on_field.
      IF mv_cgui_stop = abap_true.
        RETURN.
      ENDIF.

      CLEAR ls_next.
      READ TABLE lt_shown INTO ls_next INDEX lv_index + 1.

      " the blocks the field closes, the inner one first - a message belongs
      " to the first field of the block

      lv_block = lines( ls_field-blocks ).
      WHILE lv_block > 0.



        temp51 = sy-tabix.
        READ TABLE ls_field-blocks INDEX lv_block ASSIGNING <temp50>.
        sy-tabix = temp51.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        lv_name = <temp50>.
        lv_block = lv_block - 1.


        temp529 = sy-tabix.
        READ TABLE ls_next-blocks WITH KEY table_line = lv_name TRANSPORTING NO FIELDS.
        temp528 = sy-subrc.
        sy-tabix = temp529.
        IF temp528 = 0.
          CONTINUE.
        ENDIF.

        LOOP AT lt_shown INTO ls_first.


          temp531 = sy-tabix.
          READ TABLE ls_first-blocks WITH KEY table_line = lv_name TRANSPORTING NO FIELDS.
          temp530 = sy-subrc.
          sy-tabix = temp531.
          IF temp530 = 0.
            EXIT.
          ENDIF.
        ENDLOOP.
        mv_cgui_on_field = ls_first-name.
        at_selection_screen_on_block( lv_name ).
        CLEAR mv_cgui_on_field.
        IF mv_cgui_stop = abap_true.
          RETURN.
        ENDIF.
      ENDWHILE.

      " the group the button closes - a message belongs to its first button
      IF ls_field-group IS NOT INITIAL AND ls_next-group <> ls_field-group.
        READ TABLE lt_shown INTO ls_first WITH KEY group = ls_field-group.
        mv_cgui_on_field = ls_first-name.
        at_selection_screen_on_radio( ls_field-group ).
        CLEAR mv_cgui_on_field.
        IF mv_cgui_stop = abap_true.
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.

    result = abap_true.

  ENDMETHOD.

  METHOD check_obligatory.

    " one message per empty required field, each at its field
    FIELD-SYMBOLS <field_val> TYPE any.
    DATA temp532 TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA lt_field LIKE temp532.
    DATA temp533 LIKE LINE OF lt_field.
    DATA lr_field LIKE REF TO temp533.
      DATA lr_val TYPE REF TO data.

    result = abap_true.

    IF fields IS SUPPLIED.
      temp532 = fields.
    ELSE.
      temp532 = mt_cgui_field.
    ENDIF.

    lt_field = temp532.


    LOOP AT lt_field REFERENCE INTO lr_field WHERE obligatory = abap_true.

      lr_val = attri_assign( lr_field->name ).
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

    DATA lr_range TYPE REF TO data.
    lr_range = attri_assign( field ).
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
    DATA lr_field TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_field.
    DATA lr_range TYPE REF TO data.

    result-control = z2ui5_cl_cgui_range=>cs_control-input.

    READ TABLE mt_cgui_field REFERENCE INTO lr_field WITH KEY name = field.
    IF sy-subrc = 0.
      result-title        = lr_field->text.
      result-value_help   = lr_field->value_help.
      result-upper        = lr_field->upper.
      result-no_intervals = lr_field->no_intervals.
      result-max_length   = lr_field->max_length.
    ENDIF.

    " a date or a time gets its picker, as on the selection screen

    lr_range = attri_assign( field ).
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
    DATA ls_result TYPE z2ui5_cl_cgui_range=>ty_s_result.
    DATA lr_range TYPE REF TO data.
    DATA lr_before TYPE REF TO data.
    FIELD-SYMBOLS <before> TYPE STANDARD TABLE.
    DATA lv_error TYPE string.
      DATA ls_msg LIKE LINE OF mt_cgui_msg.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.


    ls_result = lo_popup->result( ).
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


    lr_range = attri_assign( field ).
    IF lr_range IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_range->* TO <range>.



    CREATE DATA lr_before LIKE <range>.
    ASSIGN lr_before->* TO <before>.
    <before> = <range>.


    z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = ls_result-rows
                                                  upper = range_setting( field )-upper
                                        IMPORTING error = lv_error
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

      LOOP AT mt_cgui_msg INTO ls_msg WHERE type = `E` OR type = `A`.
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

    DATA lr_range TYPE REF TO data.
      DATA lt_old TYPE z2ui5_cl_cgui_range=>ty_t_row.
      DATA temp534 TYPE z2ui5_cl_cgui_range=>ty_t_row.
      DATA ls_row LIKE LINE OF temp534.
        DATA temp535 LIKE sy-subrc.
    lr_range = attri_assign( mv_cgui_range_field ).
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

      lt_old = z2ui5_cl_cgui_range=>rows_from_range( <before> ).

      temp534 = z2ui5_cl_cgui_range=>rows_from_range( <range> ).

      LOOP AT temp534 INTO ls_row.

        READ TABLE lt_old WITH KEY sign = ls_row-sign option = ls_row-option low = ls_row-low high = ls_row-high TRANSPORTING NO FIELDS.
        temp535 = sy-subrc.
        IF NOT temp535 = 0.
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

    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
        DATA temp536 LIKE LINE OF lt_value.
    ls_result = popup->result( ).

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

        temp536 = |{ <value> }|.
        INSERT temp536 INTO TABLE lt_value.
      ENDIF.
    ENDLOOP.
    z2ui5_cl_cgui_range=>rows_add_values( EXPORTING values = lt_value
                                          CHANGING  rows   = mt_cgui_range_row ).

  ENDMETHOD.

  METHOD on_f4_result.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    DATA lr_field TYPE REF TO data.

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

    ls_result = lo_popup->result( ).
    IF ls_result-confirmed = abap_false.
      RETURN.
    ENDIF.


    lr_field = attri_assign( field ).
    IF lr_field IS NOT BOUND.
      RETURN.
    ENDIF.

    IF cl_abap_typedescr=>describe_by_data_ref( lr_field )->kind <> cl_abap_typedescr=>kind_table.
      f4_result_value( field = lr_field
                       row   = ls_result-row
                       col   = col ).
    ELSEIF mv_cgui_pending_part = z2ui5_cl_cgui_selscreen=>cs_part-high.
      " the upper limit: the first line becomes an interval up to the value
      CLEAR mv_cgui_pending_part.
      f4_result_high( range = lr_field
                      row   = ls_result-row
                      col   = col ).
    ELSE.
      f4_result_rows( range = lr_field
                      rows  = ls_result-table
                      col   = col ).
    ENDIF.

  ENDMETHOD.

  METHOD f4_row_value.

    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <value> TYPE any.

    IF row IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN row->* TO <row>.
    IF col IS INITIAL.
      ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <value>.
    ELSE.
      ASSIGN COMPONENT col OF STRUCTURE <row> TO <value>.
    ENDIF.
    IF <value> IS ASSIGNED.
      GET REFERENCE OF <value> INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD f4_result_value.

    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <field> TYPE any.

    DATA lr_value TYPE REF TO data.
    lr_value = f4_row_value( row = row
                                   col = col ).
    IF lr_value IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_value->* TO <value>.
    ASSIGN field->* TO <field>.
    <field> = <value>.

  ENDMETHOD.

  METHOD f4_result_high.

    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <comp>  TYPE any.
    DATA lr_line TYPE REF TO data.

    DATA lr_value TYPE REF TO data.
    lr_value = f4_row_value( row = row
                                   col = col ).
    IF lr_value IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_value->* TO <value>.
    ASSIGN range->* TO <range>.
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

  ENDMETHOD.

  METHOD f4_result_rows.

    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <rows>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <keep>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <sign>  TYPE any.
    FIELD-SYMBOLS <opt>   TYPE any.
    DATA lr_keep TYPE REF TO data.
    DATA lr_row  TYPE REF TO data.
      DATA lr_value TYPE REF TO data.

    " a select-option - every row picked becomes a line I EQ. The value
    " help showed the lines I EQ as picked, so only they are replaced:
    " intervals, patterns and excluding lines stay
    IF rows IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN rows->* TO <rows>.
    ASSIGN range->* TO <range>.
    CREATE DATA lr_keep LIKE <range>.
    ASSIGN lr_keep->* TO <keep>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <keep>.
    LOOP AT <range> ASSIGNING <line>.
      UNASSIGN <sign>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <sign>.
      UNASSIGN <opt>.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <opt>.
      IF <sign> IS ASSIGNED AND <opt> IS ASSIGNED AND <sign> = `I` AND <opt> = `EQ`.
        CONTINUE.
      ENDIF.
      INSERT <line> INTO TABLE <keep>.
    ENDLOOP.
    <range> = <keep>.

    LOOP AT <rows> ASSIGNING <row>.
      GET REFERENCE OF <row> INTO lr_row.

      lr_value = f4_row_value( row = lr_row
                                     col = col ).
      IF lr_value IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_value->* TO <value>.
      z2ui5_cl_cgui_range=>line_append( EXPORTING low   = <value>
                                        CHANGING  range = <range> ).
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

    DATA temp537 TYPE REF TO data.
DATA temp52 TYPE abap_parmbind.
      DATA temp538 TYPE REF TO data.
DATA temp53 TYPE abap_parmbind.
      DATA temp539 TYPE REF TO data.
DATA temp54 TYPE abap_parmbind.
      DATA temp540 LIKE REF TO hotspot.
DATA temp55 TYPE abap_parmbind.
      DATA temp541 LIKE REF TO pos.
DATA temp56 TYPE abap_parmbind.
      DATA temp542 LIKE REF TO len.
DATA temp57 TYPE abap_parmbind.
      DATA temp543 LIKE REF TO intensified.
DATA temp58 TYPE abap_parmbind.
      DATA temp544 LIKE REF TO inverse.
DATA temp59 TYPE abap_parmbind.
      DATA temp545 LIKE REF TO input.
DATA temp60 TYPE abap_parmbind.
      DATA temp546 LIKE REF TO no_zero.
DATA temp61 TYPE abap_parmbind.
      DATA temp547 LIKE REF TO no_sign.
DATA temp62 TYPE abap_parmbind.
      DATA temp548 TYPE REF TO data.
DATA temp63 TYPE abap_parmbind.
      DATA temp549 TYPE REF TO data.
DATA temp64 TYPE abap_parmbind.
      DATA temp550 LIKE REF TO decimals.
DATA temp65 TYPE abap_parmbind.
      DATA temp551 TYPE REF TO data.
DATA temp66 TYPE abap_parmbind.
      DATA temp552 LIKE REF TO no_gap.
DATA temp67 TYPE abap_parmbind.
      DATA temp553 TYPE REF TO data.
DATA temp68 TYPE abap_parmbind.
      DATA temp554 LIKE REF TO no_grouping.
DATA temp69 TYPE abap_parmbind.
      DATA temp555 LIKE REF TO round.
DATA temp70 TYPE abap_parmbind.
      DATA temp556 TYPE REF TO data.
DATA temp71 TYPE abap_parmbind.
      DATA temp557 TYPE REF TO data.
DATA temp72 TYPE abap_parmbind.
      DATA temp558 TYPE REF TO data.
DATA temp73 TYPE abap_parmbind.
      DATA temp559 TYPE REF TO data.
DATA temp74 TYPE abap_parmbind.
      DATA temp560 TYPE REF TO data.
DATA temp75 TYPE abap_parmbind.
    DATA temp561 LIKE REF TO result.
DATA temp76 TYPE abap_parmbind.
    DATA lo_list TYPE REF TO z2ui5_cl_cgui_list.
GET REFERENCE OF val INTO temp537.

CLEAR temp52.
temp52-name = `VAL`.
temp52-kind = cl_abap_objectdescr=>exporting.
temp52-value = temp537.
INSERT temp52 INTO TABLE lt_param.
    IF hide IS SUPPLIED.

GET REFERENCE OF hide INTO temp538.

CLEAR temp53.
temp53-name = `HIDE`.
temp53-kind = cl_abap_objectdescr=>exporting.
temp53-value = temp538.
INSERT temp53 INTO TABLE lt_param.
    ENDIF.
    IF color IS SUPPLIED.

      GET REFERENCE OF color INTO temp539.

CLEAR temp54.
temp54-name = `COLOR`.
temp54-kind = cl_abap_objectdescr=>exporting.
temp54-value = temp539.
INSERT temp54 INTO TABLE lt_param.
    ENDIF.
    IF hotspot IS SUPPLIED.

      GET REFERENCE OF hotspot INTO temp540.

CLEAR temp55.
temp55-name = `HOTSPOT`.
temp55-kind = cl_abap_objectdescr=>exporting.
temp55-value = temp540.
INSERT temp55 INTO TABLE lt_param.
    ENDIF.
    IF pos IS SUPPLIED.

      GET REFERENCE OF pos INTO temp541.

CLEAR temp56.
temp56-name = `POS`.
temp56-kind = cl_abap_objectdescr=>exporting.
temp56-value = temp541.
INSERT temp56 INTO TABLE lt_param.
    ENDIF.
    IF len IS SUPPLIED.

      GET REFERENCE OF len INTO temp542.

CLEAR temp57.
temp57-name = `LEN`.
temp57-kind = cl_abap_objectdescr=>exporting.
temp57-value = temp542.
INSERT temp57 INTO TABLE lt_param.
    ENDIF.
    IF intensified IS SUPPLIED.

      GET REFERENCE OF intensified INTO temp543.

CLEAR temp58.
temp58-name = `INTENSIFIED`.
temp58-kind = cl_abap_objectdescr=>exporting.
temp58-value = temp543.
INSERT temp58 INTO TABLE lt_param.
    ENDIF.
    IF inverse IS SUPPLIED.

      GET REFERENCE OF inverse INTO temp544.

CLEAR temp59.
temp59-name = `INVERSE`.
temp59-kind = cl_abap_objectdescr=>exporting.
temp59-value = temp544.
INSERT temp59 INTO TABLE lt_param.
    ENDIF.
    IF input IS SUPPLIED.

      GET REFERENCE OF input INTO temp545.

CLEAR temp60.
temp60-name = `INPUT`.
temp60-kind = cl_abap_objectdescr=>exporting.
temp60-value = temp545.
INSERT temp60 INTO TABLE lt_param.
    ENDIF.
    IF no_zero IS SUPPLIED.

      GET REFERENCE OF no_zero INTO temp546.

CLEAR temp61.
temp61-name = `NO_ZERO`.
temp61-kind = cl_abap_objectdescr=>exporting.
temp61-value = temp546.
INSERT temp61 INTO TABLE lt_param.
    ENDIF.
    IF no_sign IS SUPPLIED.

      GET REFERENCE OF no_sign INTO temp547.

CLEAR temp62.
temp62-name = `NO_SIGN`.
temp62-kind = cl_abap_objectdescr=>exporting.
temp62-value = temp547.
INSERT temp62 INTO TABLE lt_param.
    ENDIF.
    IF currency IS SUPPLIED.

      GET REFERENCE OF currency INTO temp548.

CLEAR temp63.
temp63-name = `CURRENCY`.
temp63-kind = cl_abap_objectdescr=>exporting.
temp63-value = temp548.
INSERT temp63 INTO TABLE lt_param.
    ENDIF.
    IF unit IS SUPPLIED.

      GET REFERENCE OF unit INTO temp549.

CLEAR temp64.
temp64-name = `UNIT`.
temp64-kind = cl_abap_objectdescr=>exporting.
temp64-value = temp549.
INSERT temp64 INTO TABLE lt_param.
    ENDIF.
    IF decimals IS SUPPLIED.

      GET REFERENCE OF decimals INTO temp550.

CLEAR temp65.
temp65-name = `DECIMALS`.
temp65-kind = cl_abap_objectdescr=>exporting.
temp65-value = temp550.
INSERT temp65 INTO TABLE lt_param.
    ENDIF.
    IF justify IS SUPPLIED.

      GET REFERENCE OF justify INTO temp551.

CLEAR temp66.
temp66-name = `JUSTIFY`.
temp66-kind = cl_abap_objectdescr=>exporting.
temp66-value = temp551.
INSERT temp66 INTO TABLE lt_param.
    ENDIF.
    IF no_gap IS SUPPLIED.

      GET REFERENCE OF no_gap INTO temp552.

CLEAR temp67.
temp67-name = `NO_GAP`.
temp67-kind = cl_abap_objectdescr=>exporting.
temp67-value = temp552.
INSERT temp67 INTO TABLE lt_param.
    ENDIF.
    IF edit_mask IS SUPPLIED.

      GET REFERENCE OF edit_mask INTO temp553.

CLEAR temp68.
temp68-name = `EDIT_MASK`.
temp68-kind = cl_abap_objectdescr=>exporting.
temp68-value = temp553.
INSERT temp68 INTO TABLE lt_param.
    ENDIF.
    IF no_grouping IS SUPPLIED.

      GET REFERENCE OF no_grouping INTO temp554.

CLEAR temp69.
temp69-name = `NO_GROUPING`.
temp69-kind = cl_abap_objectdescr=>exporting.
temp69-value = temp554.
INSERT temp69 INTO TABLE lt_param.
    ENDIF.
    IF round IS SUPPLIED.

      GET REFERENCE OF round INTO temp555.

CLEAR temp70.
temp70-name = `ROUND`.
temp70-kind = cl_abap_objectdescr=>exporting.
temp70-value = temp555.
INSERT temp70 INTO TABLE lt_param.
    ENDIF.
    IF date_format IS SUPPLIED.

      GET REFERENCE OF date_format INTO temp556.

CLEAR temp71.
temp71-name = `DATE_FORMAT`.
temp71-kind = cl_abap_objectdescr=>exporting.
temp71-value = temp556.
INSERT temp71 INTO TABLE lt_param.
    ENDIF.
    IF time_zone IS SUPPLIED.

      GET REFERENCE OF time_zone INTO temp557.

CLEAR temp72.
temp72-name = `TIME_ZONE`.
temp72-kind = cl_abap_objectdescr=>exporting.
temp72-value = temp557.
INSERT temp72 INTO TABLE lt_param.
    ENDIF.
    IF quickinfo IS SUPPLIED.

      GET REFERENCE OF quickinfo INTO temp558.

CLEAR temp73.
temp73-name = `QUICKINFO`.
temp73-kind = cl_abap_objectdescr=>exporting.
temp73-value = temp558.
INSERT temp73 INTO TABLE lt_param.
    ENDIF.
    IF name IS SUPPLIED.

      GET REFERENCE OF name INTO temp559.

CLEAR temp74.
temp74-name = `NAME`.
temp74-kind = cl_abap_objectdescr=>exporting.
temp74-value = temp559.
INSERT temp74 INTO TABLE lt_param.
    ENDIF.
    IF under IS SUPPLIED.

      GET REFERENCE OF under INTO temp560.

CLEAR temp75.
temp75-name = `UNDER`.
temp75-kind = cl_abap_objectdescr=>exporting.
temp75-value = temp560.
INSERT temp75 INTO TABLE lt_param.
    ENDIF.

    GET REFERENCE OF result INTO temp561.

CLEAR temp76.
temp76-name = `RESULT`.
temp76-kind = cl_abap_objectdescr=>receiving.
temp76-value = temp561.
INSERT temp76 INTO TABLE lt_param.


    lo_list = list( ).
    CALL METHOD lo_list->(`WRITE`)
      PARAMETER-TABLE lt_param.

  ENDMETHOD.

  METHOD format.

    DATA lt_param TYPE abap_parmbind_tab.
      DATA temp562 TYPE REF TO data.
DATA temp77 TYPE abap_parmbind.
      DATA temp563 LIKE REF TO intensified.
DATA temp78 TYPE abap_parmbind.
      DATA temp564 LIKE REF TO inverse.
DATA temp79 TYPE abap_parmbind.
      DATA temp565 LIKE REF TO hotspot.
DATA temp80 TYPE abap_parmbind.
      DATA temp566 LIKE REF TO input.
DATA temp81 TYPE abap_parmbind.
    DATA temp567 LIKE REF TO reset.
DATA temp82 TYPE abap_parmbind.
    DATA temp568 LIKE REF TO result.
DATA temp83 TYPE abap_parmbind.
    DATA lo_list TYPE REF TO z2ui5_cl_cgui_list.

    IF color IS SUPPLIED.

      GET REFERENCE OF color INTO temp562.

CLEAR temp77.
temp77-name = `COLOR`.
temp77-kind = cl_abap_objectdescr=>exporting.
temp77-value = temp562.
INSERT temp77 INTO TABLE lt_param.
    ENDIF.
    IF intensified IS SUPPLIED.

      GET REFERENCE OF intensified INTO temp563.

CLEAR temp78.
temp78-name = `INTENSIFIED`.
temp78-kind = cl_abap_objectdescr=>exporting.
temp78-value = temp563.
INSERT temp78 INTO TABLE lt_param.
    ENDIF.
    IF inverse IS SUPPLIED.

      GET REFERENCE OF inverse INTO temp564.

CLEAR temp79.
temp79-name = `INVERSE`.
temp79-kind = cl_abap_objectdescr=>exporting.
temp79-value = temp564.
INSERT temp79 INTO TABLE lt_param.
    ENDIF.
    IF hotspot IS SUPPLIED.

      GET REFERENCE OF hotspot INTO temp565.

CLEAR temp80.
temp80-name = `HOTSPOT`.
temp80-kind = cl_abap_objectdescr=>exporting.
temp80-value = temp565.
INSERT temp80 INTO TABLE lt_param.
    ENDIF.
    IF input IS SUPPLIED.

      GET REFERENCE OF input INTO temp566.

CLEAR temp81.
temp81-name = `INPUT`.
temp81-kind = cl_abap_objectdescr=>exporting.
temp81-value = temp566.
INSERT temp81 INTO TABLE lt_param.
    ENDIF.

    GET REFERENCE OF reset INTO temp567.

CLEAR temp82.
temp82-name = `RESET`.
temp82-kind = cl_abap_objectdescr=>exporting.
temp82-value = temp567.
INSERT temp82 INTO TABLE lt_param.

    GET REFERENCE OF result INTO temp568.

CLEAR temp83.
temp83-name = `RESULT`.
temp83-kind = cl_abap_objectdescr=>receiving.
temp83-value = temp568.
INSERT temp83 INTO TABLE lt_param.


    lo_list = list( ).
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
    DATA ls_item TYPE z2ui5_cl_cgui_list=>ty_s_item.
    DATA temp84 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_cursor-offset.

    CLEAR: ms_cgui_cursor, mv_cgui_lisel.
    IF mo_cgui_list IS NOT BOUND.
      RETURN.
    ENDIF.
    mv_cgui_lisel = mo_cgui_list->line_text( line ).

    ls_item = mo_cgui_list->get_item_by_id( id ).
    CLEAR ms_cgui_cursor.
    ms_cgui_cursor-field = ls_item-name.
    ms_cgui_cursor-value = ls_item-text.
    ms_cgui_cursor-line = line.

    IF ls_item-col > 0.
      temp84 = ls_item-col - 1.
    ELSE.
      CLEAR temp84.
    ENDIF.
    ms_cgui_cursor-offset = temp84.

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
        DATA lv_table TYPE string.

    " DD32S is named as a string - not released on ABAP Cloud, there the
    " select raises and the field keeps its other F4
    lv_shlp = name.
    TRY.

        lv_table = `DD32S`.
        SELECT fieldname FROM (lv_table) UP TO 1 ROWS INTO lv_field
          WHERE shlpname = lv_shlp AND as4local = 'A' AND shlpoutput = 'X'
          ORDER BY flposition

          .
        ENDSELECT.
        result = lv_field.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD list.

    " the first output of at_user_command( ) is a secondary list
    level_open( ).
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

  METHOD read_list.
      DATA temp569 TYPE REF TO z2ui5_cl_cgui_list.
      FIELD-SYMBOLS <temp570> LIKE LINE OF mt_cgui_level.
      DATA temp571 LIKE sy-tabix.

    " at_user_command( ) before it wrote: the list shown - an ALV or a
    " tree has none, an empty one reads no line
    IF mv_cgui_level_new = abap_true.

      IF mo_cgui_list IS BOUND.
        temp569 = mo_cgui_list.
      ELSE.
        temp569 = z2ui5_cl_cgui_list=>factory( ).
      ENDIF.
      result = temp569.
      RETURN.
    ENDIF.
    IF ( mv_cgui_on_line = abap_true OR mv_cgui_on_command = abap_true ) AND mt_cgui_level IS NOT INITIAL.


      temp571 = sy-tabix.
      READ TABLE mt_cgui_level INDEX lines( mt_cgui_level ) ASSIGNING <temp570>.
      sy-tabix = temp571.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      result = <temp570>-list.
    ENDIF.
    IF result IS NOT BOUND.
      result = list( ).
    ENDIF.

  ENDMETHOD.

  METHOD alv.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    level_open( ).
    CLEAR: mr_cgui_alv, mr_cgui_alv_box, mr_cgui_alv_page, mt_cgui_alv_index, mt_cgui_alv_order.
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

    level_open( ).
    mo_cgui_tree = z2ui5_cl_cgui_tree=>factory( )->set_title( mv_cgui_title ).
    CLEAR: mt_cgui_tree_view, mo_cgui_tree_handler.
    result = mo_cgui_tree.

  ENDMETHOD.

  METHOD at_tree_node ##NEEDED.
  ENDMETHOD.

  METHOD at_tree_checkbox ##NEEDED.
  ENDMETHOD.

  METHOD at_tree_expand_no_children ##NEEDED.
  ENDMETHOD.

  METHOD on_tree_node.
    DATA lo_tree LIKE mo_cgui_tree.
    DATA ls_node TYPE z2ui5_cl_cgui_tree=>ty_s_node.

    IF key IS INITIAL.
      RETURN.
    ENDIF.
    " the tree stays as it is - what the event block shows is a new level

    lo_tree = mo_cgui_tree.

    ls_node = lo_tree->get_node( key ).
    level_push( ).
    at_tree_node( key   = key
                  value = ls_node-value ).
    IF mo_cgui_tree_handler IS BOUND.
      " the handlers of the stand-in of cl_salv_tree - an event of a control
      at_gui_event( ).
      mo_cgui_tree_handler->on_node( key ).
    ENDIF.
    level_settle( ).

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
    mr_cgui_alv_box = mo_cgui_alv->box_copy( source = source
                                             old    = mr_cgui_alv_box ).

  ENDMETHOD.

  METHOD get_selected_rows.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lr_tab TYPE REF TO data.

    IF mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.

    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    result = mo_cgui_alv->get_selected_rows( <tab> ).

  ENDMETHOD.

  METHOD _msg.

    CREATE OBJECT result EXPORTING REPORT = me.

  ENDMETHOD.

  METHOD _msg_box.

    CREATE OBJECT result EXPORTING report = me box = abap_true.

  ENDMETHOD.

  METHOD _popup.

    CREATE OBJECT result EXPORTING REPORT = me.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_dialogs~message.

    message( text  = text
             type  = type
             field = field ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_dialogs~message_box.

    DATA temp572 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_msg.
    CLEAR temp572.
    temp572-type = to_upper( type ).
    temp572-text = text.
    INSERT temp572 INTO TABLE mt_cgui_box.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_dialogs~popup_to_confirm.

    DATA temp573 TYPE string.
    IF title IS INITIAL.
      temp573 = `Confirm`.
    ELSE.
      temp573 = title.
    ENDIF.
    popup_to_confirm( question = question
                      ucomm    = ucomm
                      title    = temp573
                      then     = then ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_dialogs~popup_to_decide.

    popup_to_decide( question = question
                     options  = options
                     ucomm    = ucomm
                     title    = title
                     then     = then ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_dialogs~popup_transport.

    popup_transport( ucomm = ucomm
                     title = title
                     then  = then ).

  ENDMETHOD.

  METHOD popup_transport.
    DATA lv_event TYPE string.

    CLEAR: ms_cgui_transport, mv_cgui_answer.

    lv_event = popup_event( ucomm = ucomm
                                  then  = then ).
    mv_cgui_pending_kind = cs_pending-transport.
    mv_cgui_pending_ucomm = lv_event.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_transport=>factory( event = lv_event
                                                            title = title ) ).

  ENDMETHOD.

  METHOD get_transport.

    result = ms_cgui_transport.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_dialogs~popup_get_values.

    popup_get_values( fields = fields
                      ucomm  = ucomm
                      title  = title
                      text   = text
                      then   = then ).

  ENDMETHOD.

  METHOD message.

    DATA lv_field TYPE string.
    DATA temp574 TYPE ty_s_cgui_msg.
    DATA ls_msg LIKE temp574.

    lv_field = to_upper( field ).
    IF lv_field IS INITIAL.
      lv_field = mv_cgui_on_field.
    ENDIF.


    CLEAR temp574.
    temp574-type = to_upper( type ).
    temp574-text = text.
    temp574-field = lv_field.

    ls_msg = temp574.
    INSERT ls_msg INTO TABLE mt_cgui_msg.
    INSERT ls_msg INTO TABLE mt_cgui_run_msg.
    IF mo_cgui_app_log IS BOUND.
      mo_cgui_app_log->add( type = ls_msg-type
                            text = ls_msg-text ).
    ENDIF.
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
      DATA temp575 TYPE string.
      DATA lv_text LIKE temp575.
      DATA temp576 TYPE string.
      DATA lv_type LIKE temp576.
      DATA temp577 TYPE string.
      DATA lv_field LIKE temp577.
      DATA temp578 TYPE string.
      DATA temp85 LIKE sy-subrc.
      DATA temp86 LIKE sy-subrc.

    LOOP AT tab ASSIGNING <ret>.
      ASSIGN COMPONENT `MESSAGE` OF STRUCTURE <ret> TO <comp>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      temp575 = <comp>.

      lv_text = temp575.
      ASSIGN COMPONENT `TYPE` OF STRUCTURE <ret> TO <comp>.

      IF sy-subrc = 0 AND <comp> IS NOT INITIAL.
        temp576 = <comp>.
      ELSE.
        temp576 = `I`.
      ENDIF.

      lv_type = temp576.
      ASSIGN COMPONENT `FIELD` OF STRUCTURE <ret> TO <comp>.

      IF sy-subrc = 0.
        temp577 = <comp>.
      ELSE.
        CLEAR temp577.
      ENDIF.

      lv_field = temp577.

      temp578 = to_upper( lv_field ).


      temp86 = sy-subrc.
      READ TABLE mt_cgui_field WITH KEY name = temp578 TRANSPORTING NO FIELDS.
      temp85 = sy-subrc.
      sy-subrc = temp86.
      IF lv_field IS NOT INITIAL AND NOT temp85 = 0.
        CLEAR lv_field.
      ENDIF.
      message( text  = lv_text
               type  = lv_type
               field = lv_field ).
    ENDLOOP.

  ENDMETHOD.

  METHOD popup_to_confirm.

    DATA lv_event TYPE string.
    DATA lv_cancel LIKE cs_ucomm-cancel.
    lv_event = popup_event( ucomm = ucomm
                                  then  = then ).

    lv_cancel = cs_ucomm-cancel.
    " the user command the answer arrives with - a run waits for it
    mv_cgui_pending_ucomm = lv_event.
    " with then both answers go to the method - the answer as of decide
    IF then IS NOT INITIAL.
      CLEAR mv_cgui_answer.
      mv_cgui_pending_kind = cs_pending-decide.
      lv_cancel = lv_event.
    ENDIF.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>confirm( question     = question
                                                        title        = title
                                                        event        = lv_event
                                                        event_cancel = lv_cancel ) ).

  ENDMETHOD.

  METHOD popup_to_decide.
    DATA lv_event TYPE string.

    CLEAR: mv_cgui_answer, mt_cgui_decide_line.

    lv_event = popup_event( ucomm = ucomm
                                  then  = then ).
    mv_cgui_pending_kind = cs_pending-decide.
    mv_cgui_pending_ucomm = lv_event.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>decide( question = question
                                                       options  = options
                                                       title    = title
                                                       event    = lv_event ) ).

  ENDMETHOD.

  METHOD popup_get_values.
    DATA lv_event TYPE string.

    CLEAR: mt_cgui_popup_values, mv_cgui_answer.

    lv_event = popup_event( ucomm = ucomm
                                  then  = then ).
    mv_cgui_pending_kind = cs_pending-values.
    mv_cgui_pending_ucomm = lv_event.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_popup=>get_values( fields  = fields
                                                           title   = title
                                                           text    = text
                                                           listbox = listbox
                                                           event   = lv_event ) ).

  ENDMETHOD.

  METHOD popup_to_decide_list.

    DATA lt_option TYPE string_table.
    DATA lt_line   LIKE mt_cgui_decide_line.
    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    FIELD-SYMBOLS <flag> TYPE any.
      DATA lv_index LIKE sy-tabix.
      DATA temp579 TYPE string.
      DATA temp1 TYPE string.

    LOOP AT list ASSIGNING <line>.

      lv_index = sy-tabix.
      " HIDE: not offered; INACTIVE: not to be picked - left out as well
      UNASSIGN <flag>.
      ASSIGN COMPONENT `HIDE` OF STRUCTURE <line> TO <flag>.
      IF <flag> IS ASSIGNED AND <flag> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      UNASSIGN <flag>.
      ASSIGN COMPONENT `INACTIVE` OF STRUCTURE <line> TO <flag>.
      IF <flag> IS ASSIGNED AND <flag> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `VAROPTION` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS NOT ASSIGNED.
        ASSIGN <line> TO <comp>.
      ENDIF.

      temp579 = <comp>.

      temp1 = condense( temp579 ).
      INSERT temp1 INTO TABLE lt_option.
      INSERT lv_index INTO TABLE lt_line.
      UNASSIGN <comp>.
    ENDLOOP.

    popup_to_decide( question = question
                     options  = lt_option
                     ucomm    = ucomm
                     title    = title
                     then     = then ).
    " the answer is the line of the table, not the number of the option
    mt_cgui_decide_line = lt_line.

  ENDMETHOD.

  METHOD popup_get_values_sval.

    DATA lt_field TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
      DATA temp580 TYPE z2ui5_cl_cgui_popup=>ty_s_field.
      DATA ls_field LIKE temp580.
        DATA temp15 TYPE xsdboolean.

    LOOP AT sval ASSIGNING <line>.

      CLEAR temp580.

      ls_field = temp580.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_field-name = to_upper( <comp> ).
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `FIELDTEXT` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_field-text = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      IF ls_field-text IS INITIAL.
        ls_field-text = ls_field-name.
      ENDIF.
      ASSIGN COMPONENT `VALUE` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_field-value = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `FIELD_OBL` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.

        temp15 = boolc( <comp> IS NOT INITIAL ).
        ls_field-required = temp15.
      ENDIF.
      UNASSIGN <comp>.
      INSERT ls_field INTO TABLE lt_field.
    ENDLOOP.

    popup_get_values( fields = lt_field
                      ucomm  = ucomm
                      title  = title
                      text   = text
                      then   = then ).

  ENDMETHOD.

  METHOD popup_values_sval.

    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    DATA lr_line TYPE REF TO data.
      DATA temp581 LIKE LINE OF mt_cgui_popup_values.
      DATA lr_field LIKE REF TO temp581.
      DATA lv_name TYPE string.

    IF sval IS INITIAL.


      LOOP AT mt_cgui_popup_values REFERENCE INTO lr_field.
        CREATE DATA lr_line LIKE LINE OF sval.
        ASSIGN lr_line->* TO <line>.
        UNASSIGN <comp>.
        ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <line> TO <comp>.
        IF <comp> IS ASSIGNED.
          <comp> = lr_field->name.
        ENDIF.
        UNASSIGN <comp>.
        ASSIGN COMPONENT `FIELDTEXT` OF STRUCTURE <line> TO <comp>.
        IF <comp> IS ASSIGNED.
          <comp> = lr_field->text.
        ENDIF.
        UNASSIGN <comp>.
        ASSIGN COMPONENT `VALUE` OF STRUCTURE <line> TO <comp>.
        IF <comp> IS ASSIGNED.
          <comp> = lr_field->value.
        ENDIF.
        UNASSIGN <comp>.
        INSERT <line> INTO TABLE sval.
      ENDLOOP.
      RETURN.
    ENDIF.

    LOOP AT sval ASSIGNING <line>.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS NOT ASSIGNED.
        RETURN.
      ENDIF.

      lv_name = to_upper( <comp> ).
      UNASSIGN <comp>.
      READ TABLE mt_cgui_popup_values REFERENCE INTO lr_field WITH KEY name = lv_name.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT `VALUE` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        <comp> = lr_field->value.
      ENDIF.
      UNASSIGN <comp>.
    ENDLOOP.

  ENDMETHOD.

  METHOD popup_answer.

    result = mv_cgui_answer.

  ENDMETHOD.

  METHOD popup_values.

    result = mt_cgui_popup_values.

  ENDMETHOD.

  METHOD value_help_popup.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lr_tab TYPE REF TO data.
    DATA lr_field TYPE REF TO data.
    DATA lv_multi TYPE abap_bool.
    DATA temp16 TYPE xsdboolean.
      DATA temp17 TYPE xsdboolean.
    DATA temp582 TYPE string.

    IF mv_cgui_value_field IS INITIAL.
      RETURN.
    ENDIF.






    lr_field = value_help_target( mv_cgui_value_field ).
    IF lr_field IS NOT BOUND.
      RETURN.
    ENDIF.


    temp16 = boolc( cl_abap_typedescr=>describe_by_data_ref( lr_field )->kind = cl_abap_typedescr=>kind_table ).
    lv_multi = temp16.
    " in the multiple selection: one value for a line, several for new ones
    IF mv_cgui_range_f4 = abap_true.

      temp17 = boolc( mv_cgui_range_key IS INITIAL ).
      lv_multi = temp17.
    ENDIF.
    " the upper limit takes one value
    IF mv_cgui_value_part = z2ui5_cl_cgui_selscreen=>cs_part-high.
      lv_multi = abap_false.
    ENDIF.

    mv_cgui_pending_field = mv_cgui_value_field.

    IF mv_cgui_alv_f4_col IS NOT INITIAL.
      temp582 = cs_pending-alv_f4.
    ELSE.
      temp582 = cs_pending-f4.
    ENDIF.
    mv_cgui_pending_kind = temp582.
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

    DATA lv_name TYPE string.
    DATA temp583 TYPE z2ui5_cl_cgui_report=>ty_s_cgui_vrm.
    lv_name = to_upper( name ).
    DELETE mt_cgui_vrm WHERE name = lv_name.

    CLEAR temp583.
    temp583-name = lv_name.
    temp583-values = values.
    INSERT temp583 INTO TABLE mt_cgui_vrm.

  ENDMETHOD.

  METHOD leave_to_selection_screen.

    mv_cgui_screen = cs_screen-selection.
    mv_cgui_left = abap_true.
    " the report starts anew when the event is over (restart_pending( ))
    mv_cgui_restart = abap_true.
    mv_cgui_run_wait = abap_false.
    " LEAVE PROGRAM on a dynpro - the screens called are gone as well
    CLEAR: mt_cgui_level, mv_cgui_window, mt_cgui_dynpro_stack, mv_cgui_dynpro, mv_cgui_dynpro_next.

  ENDMETHOD.

  METHOD current_screen.

    IF mo_cgui_screen IS BOUND.
      result = mo_cgui_screen.
      RETURN.
    ENDIF.
    result = z2ui5_cl_cgui_selscreen=>factory( client ).
    selection_screen_layout( result ).

  ENDMETHOD.

  METHOD call_selection_screen.

    mv_cgui_dynnr = dynnr.
    mv_cgui_dynnr_title = title.

  ENDMETHOD.

  METHOD on_screen_ok.
    DATA temp584 LIKE LINE OF mt_cgui_dynnr_field.
    DATA lr_field LIKE REF TO temp584.
    DATA lv_dynnr LIKE mv_cgui_dynnr.

    " the input as on the selection screen, the required fields of the
    " popup screen, then AT SELECTION-SCREEN ON field and AT SELECTION-SCREEN
    " as for every selection screen - an error keeps the dialog
    input_convert( mt_cgui_dynnr_field ).
    IF check_obligatory( mt_cgui_dynnr_field ) = abap_false.
      RETURN.
    ENDIF.
    mv_cgui_stop = abap_false.


    LOOP AT mt_cgui_dynnr_field REFERENCE INTO lr_field WHERE shown = abap_true.
      mv_cgui_on_field = lr_field->name.
      at_selection_screen_on( lr_field->name ).
      CLEAR mv_cgui_on_field.
      IF mv_cgui_stop = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF mv_cgui_stop = abap_false.
      at_selection_screen( ).
    ENDIF.
    IF mv_cgui_stop = abap_true.
      mv_cgui_stop = abap_false.
      RETURN.
    ENDIF.


    lv_dynnr = mv_cgui_dynnr.
    CLEAR mv_cgui_dynnr.
    client->popup_destroy( ).
    after_call_selection_screen( dynnr = lv_dynnr
                                 subrc = 0 ).

  ENDMETHOD.

  METHOD submit.

    DATA lo_app TYPE REF TO z2ui5_cl_cgui_report.
    DATA temp18 TYPE xsdboolean.

    " typed: a class that is no report fails before it is created
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
    " a dialog box is the selection screen - it is shown

    temp18 = boolc( via_selection_screen = abap_false AND as_window = abap_false ).
    lo_app->mv_cgui_skip = temp18.
    lo_app->mv_cgui_using_dynnr = using_selection_screen.
    lo_app->mv_cgui_as_window = as_window.
    IF using_variant IS NOT INITIAL.
      lo_app->mv_cgui_variant_start = using_variant.
    ENDIF.

    mv_cgui_nav = abap_true.
    client->nav_app_call( lo_app ).

  ENDMETHOD.

  METHOD call_transaction.

    DATA lo_app TYPE REF TO z2ui5_cl_cgui_report.

    DATA temp585 TYPE string.
    DATA lv_code TYPE string.
    DATA ls_tcode TYPE z2ui5_if_cgui_catalog=>ty_s_transaction.
    DATA temp586 TYPE string.
    DATA lv_report LIKE temp586.
    DATA lv_variant LIKE ls_tcode-variant.
    temp585 = code.

    lv_code = to_upper( condense( temp585 ) ).

    ls_tcode = z2ui5_cl_cgui_command=>tcode_find( code    = lv_code
                                                        catalog = mo_cgui_catalog ).
    " the tile of the launchpad - its intent instead of the class
    IF ls_tcode-semantic_object IS NOT INITIAL AND client->get( )-check_launchpad_active = abap_true.
      intent_navigate( semantic_object = ls_tcode-semantic_object
                       action          = ls_tcode-action
                       values          = values ).
      RETURN.
    ENDIF.

    IF ls_tcode IS INITIAL.
      temp586 = lv_code.
    ELSE.
      temp586 = to_upper( ls_tcode-report ).
    ENDIF.

    lv_report = temp586.

    lv_variant = ls_tcode-variant.

    " typed: a class that is no report fails before it is created
    TRY.
        CREATE OBJECT lo_app TYPE (lv_report).
      CATCH cx_sy_create_object_error cx_sy_move_cast_error.
        message( text = replace( val  = 'Transaction &1 does not exist'(051)
                                 sub  = `&1`
                                 with = lv_code )
                 type = `E` ).
        RETURN.
    ENDTRY.

    lo_app->mt_cgui_submit = values.
    lo_app->mv_cgui_called = abap_true.
    lo_app->mv_cgui_skip = skip_first.
    IF lv_variant IS NOT INITIAL.
      lo_app->mv_cgui_variant_start = lv_variant.
    ENDIF.

    mv_cgui_nav = abap_true.
    client->nav_app_call( lo_app ).

  ENDMETHOD.

  METHOD call_intent.
      DATA temp587 TYPE z2ui5_if_cgui_catalog=>ty_t_transaction.
      DATA ls_tcode LIKE LINE OF temp587.
        DATA temp588 TYPE string.

    IF client->get( )-check_launchpad_active = abap_true.
      intent_navigate( semantic_object = semantic_object
                       action          = action
                       values          = values ).
      RETURN.
    ENDIF.

    " outside the launchpad: the transaction of the catalog with the intent
    IF mo_cgui_catalog IS BOUND.

      temp587 = mo_cgui_catalog->get( ).

      LOOP AT temp587 INTO ls_tcode
          WHERE semantic_object IS NOT INITIAL.

        IF ls_tcode-action IS INITIAL.
          temp588 = `display`.
        ELSE.
          temp588 = ls_tcode-action.
        ENDIF.
        IF to_upper( ls_tcode-semantic_object ) = to_upper( semantic_object )
            AND to_upper( temp588 )
              = to_upper( action ).
          call_transaction( code   = ls_tcode-code
                            values = values ).
          RETURN.
        ENDIF.
      ENDLOOP.
    ENDIF.
    message( text = replace( val  = 'Intent &1 needs the Fiori launchpad'(072)
                             sub  = `&1`
                             with = |{ semantic_object }-{ action }| )
             type = `E` ).

  ENDMETHOD.

  METHOD intent_navigate.

    DATA lt_name TYPE string_table.

    DATA lv_params TYPE string.
    DATA ls_value LIKE LINE OF values.
      DATA temp589 LIKE sy-subrc.
      DATA temp590 TYPE string.
    DATA temp591 TYPE string_table.
    DATA temp87 TYPE string.
    DATA temp4 TYPE string.
    DATA temp10 LIKE LINE OF temp591.
    DATA temp88 LIKE LINE OF temp591.
    lv_params = ``.

    LOOP AT values INTO ls_value.

      READ TABLE lt_name WITH KEY table_line = ls_value-name TRANSPORTING NO FIELDS.
      temp589 = sy-subrc.
      IF temp589 = 0.
        CONTINUE.
      ENDIF.
      IF ls_value-kind <> z2ui5_cl_cgui_variant=>cs_kind-parameter
          AND NOT ( ( ls_value-sign = `I` OR ls_value-sign IS INITIAL )
                    AND ( ls_value-option = `EQ` OR ls_value-option IS INITIAL ) ).
        CONTINUE.
      ENDIF.
      INSERT ls_value-name INTO TABLE lt_name.

      IF lv_params IS NOT INITIAL.
        temp590 = `,`.
      ELSE.
        CLEAR temp590.
      ENDIF.
      lv_params = |{ lv_params }{ temp590 }| &&
                  |"{ z2ui5_cl_cgui_variant=>json_escape( ls_value-name ) }":"{ z2ui5_cl_cgui_variant=>json_escape( ls_value-low ) }"|.
    ENDLOOP.

    mv_cgui_nav = abap_true.

    CLEAR temp591.

    temp87 = semantic_object.

    IF action IS INITIAL.
      temp4 = `display`.
    ELSE.
      temp4 = action.
    ENDIF.

    temp10 = |\{"semanticObject":"{ z2ui5_cl_cgui_variant=>json_escape( temp87 ) }",| && |"action":"{ z2ui5_cl_cgui_variant=>json_escape( temp4 ) }"\}|.
    INSERT temp10 INTO TABLE temp591.

    temp88 = |\{{ lv_params }\}|.
    INSERT temp88 INTO TABLE temp591.
    client->follow_up_action(
        val   = client->cs_event-cross_app_nav_to_ext
        t_arg = temp591 ).

  ENDMETHOD.

  METHOD set_title.

    mv_cgui_title = val.

  ENDMETHOD.

  METHOD shortcuts_register.

    " registered with every view, the frontend binds them to the controller
    " of the view
    DATA lt_shortcut TYPE z2ui5_cl_cgui_command=>ty_t_shortcut.
    DATA ls_shortcut LIKE LINE OF lt_shortcut.
      DATA temp593 TYPE string_table.
    lt_shortcut = z2ui5_cl_cgui_command=>shortcuts( command_ctx( ) ).

    LOOP AT lt_shortcut INTO ls_shortcut.

      CLEAR temp593.
      INSERT ls_shortcut-key INTO TABLE temp593.
      INSERT ls_shortcut-ucomm INTO TABLE temp593.
      INSERT client->cs_view-main INTO TABLE temp593.
      client->follow_up_action( val   = client->cs_event-keyboard_shortcut
                                t_arg = temp593 ).
    ENDLOOP.

  ENDMETHOD.

  METHOD print_lines.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
      DATA lr_tab TYPE REF TO data.

    INSERT mv_cgui_title INTO TABLE result.
    INSERT `` INTO TABLE result.
    IF mo_cgui_alv IS BOUND.

      lr_tab = alv_visible_source( ).
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

    " the printout as a PDF for the browser to print or keep - ABAP Cloud
    " has no spool, and a spool request is no paper next to the user
    DATA lv_file TYPE xstring.
    DATA temp595 TYPE string_table.
    DATA temp89 LIKE LINE OF temp595.
    DATA temp90 LIKE LINE OF temp595.
    lv_file = z2ui5_cl_cgui_pdf=>from_lines( lines = print_lines( )
                                                   title = mv_cgui_title ).
    IF lv_file IS INITIAL.
      message( text = 'The output could not be printed'(037)
               type = `E` ).
      RETURN.
    ENDIF.


    CLEAR temp595.

    temp89 = |data:application/pdf;base64,| && z2ui5_cl_cgui_context=>conv_encode_x_base64( lv_file ).
    INSERT temp89 INTO TABLE temp595.

    temp90 = |{ mv_cgui_title }.pdf|.
    INSERT temp90 INTO TABLE temp595.
    client->follow_up_action( val   = client->cs_event-download_b64_file
                              t_arg = temp595 ).

  ENDMETHOD.

  METHOD layouts.

    DATA lo_store TYPE REF TO z2ui5_if_cgui_layouts.
    lo_store = layout_store( ).
    IF lo_store IS BOUND.
      result = lo_store->load( report = variant_key( )
                               handle = layout_handle( ) ).
    ELSE.
      result = z2ui5_cl_cgui_layout=>from_variants( z2ui5_cl_cgui_memory=>variant_catalog( memory_ctx( ) ) ).
    ENDIF.

  ENDMETHOD.

  METHOD layout_popup.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lr_tab TYPE REF TO data.
    DATA lo_store TYPE REF TO z2ui5_if_cgui_layouts.
    DATA temp19 TYPE xsdboolean.
    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.

    mv_cgui_pending_kind = cs_pending-layout.
    mv_cgui_nav = abap_true.

    lo_store = layout_store( ).

    temp19 = boolc( lo_store IS BOUND AND lo_store->check_sharing( ) = abap_true ).
    client->nav_app_call( z2ui5_cl_cgui_layout=>factory( layout  = mo_cgui_alv->get_layout( <tab> )
                                                         saved   = layouts( )
                                                         current = mv_cgui_layout
                                                         sharing = temp19 ) ).

  ENDMETHOD.

  METHOD layout_result.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_layout.
    DATA ls_result TYPE z2ui5_cl_cgui_layout=>ty_s_result.
        DATA lv_saved LIKE abap_false.
          DATA temp597 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
            DATA temp598 TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
            DATA ls_saved LIKE LINE OF temp598.
          DATA temp599 TYPE z2ui5_cl_cgui_layout=>ty_s_saved.
          DATA lv_deleted TYPE abap_bool.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.

    ls_result = lo_popup->result( ).

    CASE ls_result-action.

      WHEN z2ui5_cl_cgui_layout=>cs_action-apply.
        mo_cgui_alv->set_layout( ls_result-layout ).
        " a saved layout picked and taken as it is - the one in use now
        IF ls_result-name IS NOT INITIAL.
          mv_cgui_layout = ls_result-name.
        ENDIF.

      WHEN z2ui5_cl_cgui_layout=>cs_action-save.
        mo_cgui_alv->set_layout( ls_result-layout ).

        lv_saved = abap_false.
        IF layout_store( ) IS BOUND.
          " the store keeps one default layout per user

          CLEAR temp597.
          temp597-name = ls_result-name.
          temp597-is_default = ls_result-is_default.
          temp597-layout = ls_result-layout.
          temp597-shared = ls_result-shared.
          temp597-protected = ls_result-protected.
          lv_saved = layout_store_change( temp597 ).
        ELSE.
          " one default layout - the one saved as default takes the flag
          IF ls_result-is_default = abap_true.

            temp598 = layouts( ).

            LOOP AT temp598 INTO ls_saved WHERE is_default = abap_true AND name <> ls_result-name.
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

          CLEAR temp599.
          temp599-name = ls_result-name.

          lv_deleted = layout_store_change( layout = temp599
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
    DATA temp600 TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
    DATA ls_saved LIKE LINE OF temp600.

    mv_cgui_layout_done = abap_true.

    temp600 = layouts( ).

    LOOP AT temp600 INTO ls_saved WHERE is_default = abap_true.
      mo_cgui_alv->set_layout( z2ui5_cl_cgui_layout=>layout_merge( base  = mo_cgui_alv->get_layout( tab )
                                                                   saved = ls_saved-layout ) ).
      mv_cgui_layout = ls_saved-name.
      EXIT.
    ENDLOOP.

  ENDMETHOD.

  METHOD variant_put.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>variant_put( ctx     = memory_ctx( )
                                           variant = variant ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
        RETURN.
    ENDTRY.
    result = abap_true.

  ENDMETHOD.

  METHOD variant_remove.
        DATA lx_error TYPE REF TO z2ui5_cx_cgui_error.

    TRY.
        z2ui5_cl_cgui_memory=>variant_remove( ctx  = memory_ctx( )
                                              name = name ).

      CATCH z2ui5_cx_cgui_error INTO lx_error.
        message( text = lx_error->get_text( )
                 type = `E` ).
        RETURN.
    ENDTRY.
    result = abap_true.

  ENDMETHOD.

  METHOD alv_single_sync.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lr_tab TYPE REF TO data.

    IF mo_cgui_alv IS NOT BOUND
        OR mo_cgui_alv->get_selection_mode( ) <> z2ui5_cl_cgui_alv=>cs_selection_mode-single.
      RETURN.
    ENDIF.

    lr_tab = alv_shown( ).
    IF lr_tab IS BOUND.
      ASSIGN lr_tab->* TO <tab>.
      mo_cgui_alv->single_normalize( CHANGING tab = <tab> ).
    ENDIF.

  ENDMETHOD.

  METHOD alv_row.

    result = row.
    IF row <= 0 OR mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.

    " filtered or paged: the bound table is the copy, the browser shows its
    " rows as they are - a row of it leads back to the table
    IF mr_cgui_alv_page IS BOUND.
      READ TABLE mt_cgui_alv_index INTO result INDEX row.
      IF sy-subrc <> 0.
        result = row.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD alv_window.

    FIELD-SYMBOLS <request> TYPE z2ui5_if_client=>ty_s_window_request.
    FIELD-SYMBOLS <tab>     TYPE STANDARD TABLE.
    FIELD-SYMBOLS <page>    TYPE STANDARD TABLE.

    DATA lr_request TYPE REF TO data.
    DATA lr_tab TYPE REF TO data.
    lr_request = client->get( )-r_event_data.

    lr_tab = alv_shown( ).
    IF lr_request IS NOT BOUND OR lr_tab IS NOT BOUND OR mr_cgui_alv_page IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_request->* TO <request>.
    ASSIGN mr_cgui_alv_page->* TO <page>.

    " more rows: the next ones of the order there is - the input in the rows
    " the browser holds went back into the table before (alv_page_sync( ))
    IF <request>-reason = z2ui5_if_client=>cs_window_reason-more.
      alv_window_load( skip = lines( <page> )
                       top  = <request>-top ).
      RETURN.
    ENDIF.

    " a sort or a filter of a column menu: the order anew, over all rows,
    " and its first rows
    ASSIGN lr_tab->* TO <tab>.
    mo_cgui_alv->window_request( <request> ).
    mt_cgui_alv_order = mo_cgui_alv->window_order( <tab> ).
    alv_window_load( skip = 0
                     top  = <request>-top ).

  ENDMETHOD.

  METHOD alv_window_load.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <page> TYPE STANDARD TABLE.

    DATA lr_tab TYPE REF TO data.
    DATA lv_row LIKE LINE OF mt_cgui_alv_order.
      FIELD-SYMBOLS <row> TYPE any.
    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND OR mr_cgui_alv_page IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.
    ASSIGN mr_cgui_alv_page->* TO <page>.
    IF skip = 0.
      CLEAR: <page>, mt_cgui_alv_index.
    ENDIF.

    LOOP AT mt_cgui_alv_order INTO lv_row FROM lines( <page> ) + 1.
      IF lines( <page> ) >= skip + top.
        EXIT.
      ENDIF.

      READ TABLE <tab> ASSIGNING <row> INDEX lv_row.
      IF sy-subrc = 0.
        INSERT <row> INTO TABLE <page>.
        INSERT lv_row INTO TABLE mt_cgui_alv_index.
      ENDIF.
    ENDLOOP.
    mv_cgui_alv_total = lines( mt_cgui_alv_order ).

  ENDMETHOD.

  METHOD alv_order_rows.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.
    DATA lv_row LIKE LINE OF mt_cgui_alv_order.
      FIELD-SYMBOLS <row> TYPE any.

    ASSIGN tab->* TO <tab>.
    IF mo_cgui_alv->is_filtered( ) = abap_false.
      result = tab.
      RETURN.
    ENDIF.
    CREATE DATA result LIKE <tab>.
    ASSIGN result->* TO <rows>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <rows>.

    LOOP AT mt_cgui_alv_order INTO lv_row.

      READ TABLE <tab> ASSIGNING <row> INDEX lv_row.
      IF sy-subrc = 0.
        INSERT <row> INTO TABLE <rows>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD alv_visible_source.

    result = alv_source( ).
    IF result IS NOT BOUND OR mo_cgui_alv IS NOT BOUND OR mo_cgui_alv->is_filtered( ) = abap_false.
      RETURN.
    ENDIF.
    " the copy with the box field has the rows of the table, one to one
    result = mo_cgui_alv->filtered_copy( source = result
                                         shown  = alv_shown( ) ).

  ENDMETHOD.

  METHOD alv_filter_popup.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lr_tab TYPE REF TO data.
    DATA lt_col TYPE z2ui5_cl_cgui_alv=>ty_t_filter_col.
    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.

    lt_col = mo_cgui_alv->filter_columns( <tab> ).

    mv_cgui_pending_kind = cs_pending-filter_col.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_select=>factory( tab   = lt_col
                                                         title = 'Filter'(043) ) ).

  ENDMETHOD.

  METHOD alv_filter_column_result.

    FIELD-SYMBOLS <col> TYPE z2ui5_cl_cgui_alv=>ty_s_filter_col.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    DATA lt_filter TYPE z2ui5_cl_cgui_alv=>ty_t_filter.
    DATA ls_filter TYPE z2ui5_cl_cgui_alv=>ty_s_filter.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    ls_result = lo_popup->result( ).
    IF ls_result-confirmed = abap_false OR ls_result-row IS NOT BOUND OR mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ls_result-row->* TO <col>.
    mv_cgui_filter_col = condense( <col>-column ).

    lt_filter = mo_cgui_alv->get_filter( ).

    READ TABLE lt_filter INTO ls_filter WITH KEY name = mv_cgui_filter_col.
    alv_filter_open( ls_filter-rows ).

  ENDMETHOD.

  METHOD alv_filter_open.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    DATA lr_tab TYPE REF TO data.
    DATA ls_setting TYPE z2ui5_cl_cgui_range=>ty_s_setting.
    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.

    ls_setting = mo_cgui_alv->filter_setting( tab  = <tab>
                                                    name = mv_cgui_filter_col ).

    mv_cgui_pending_kind = cs_pending-filter.
    mv_cgui_nav = abap_true.
    client->nav_app_call( z2ui5_cl_cgui_range=>factory( rows    = rows
                                                         setting = ls_setting
                                                         error   = error ) ).

  ENDMETHOD.

  METHOD alv_filter_result.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_range.
    DATA ls_result TYPE z2ui5_cl_cgui_range=>ty_s_result.
    DATA lr_tab TYPE REF TO data.
    DATA lv_error TYPE string.

    TRY.
        lo_popup ?= client->get_app_prev( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    ls_result = lo_popup->result( ).
    IF ls_result-confirmed = abap_false OR mo_cgui_alv IS NOT BOUND.
      RETURN.
    ENDIF.

    lr_tab = alv_shown( ).
    IF lr_tab IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_tab->* TO <tab>.


    lv_error = mo_cgui_alv->check_filter( name = mv_cgui_filter_col
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

    level_open( ).
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
    DATA ls_level LIKE LINE OF mt_cgui_level.
    FIELD-SYMBOLS <temp91> LIKE LINE OF mt_cgui_level.
    DATA temp92 LIKE sy-tabix.
    temp92 = sy-tabix.
    READ TABLE mt_cgui_level INDEX lines( mt_cgui_level ) ASSIGNING <temp91>.
    sy-tabix = temp92.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_level = <temp91>.
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
    DATA temp601 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp602 TYPE string.
    IF mv_cgui_window_title IS NOT INITIAL.
      temp601 = mv_cgui_window_title.
    ELSE.
      temp601 = mv_cgui_title.
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp601
        )->a( n = `contentWidth` v = |{ nmax( val1 = 20 val2 = mv_cgui_window_cols * 6 / 10 ) }rem|
        )->a( n = `resizable`    b = abap_true
        )->a( n = `draggable`    b = abap_true ).
    IF mv_cgui_window_lines > 0.
      lo_dialog->a( n = `contentHeight` v = |{ nmax( val1 = 6 val2 = mv_cgui_window_lines * 3 / 2 ) }rem| ).
    ENDIF.

    view_display_output( lo_dialog->ele( `content` ) ).


    temp602 = 'Back'(025).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`    t = temp602
        )->a( n = `icon`    v = `sap-icon://nav-back`
        )->a( n = `type`    v = `Emphasized`
        )->a( n = `tooltip` v = `F3`
        )->a( n = `press`   v = client->_event( cs_ucomm-back ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD alv_page_sync.
    DATA lr_full TYPE REF TO data.

    " selection and input of the rows shown go back to the rows they are
    " cut from
    IF mo_cgui_alv IS NOT BOUND OR mr_cgui_alv_page IS NOT BOUND.
      RETURN.
    ENDIF.

    lr_full = alv_shown( ).
    IF lr_full IS NOT BOUND.
      RETURN.
    ENDIF.
    mo_cgui_alv->page_write_back( full  = lr_full
                                  page  = mr_cgui_alv_page
                                  index = mt_cgui_alv_index ).

  ENDMETHOD.

  METHOD alv_edit_sync.
    DATA lr_src TYPE REF TO data.

    IF mo_cgui_alv IS NOT BOUND OR mr_cgui_alv_box IS NOT BOUND OR mo_cgui_alv->is_editable( ) = abap_false.
      RETURN.
    ENDIF.

    lr_src = alv_source( ).
    IF lr_src IS NOT BOUND.
      RETURN.
    ENDIF.
    mo_cgui_alv->box_write_back( source = lr_src
                                 box    = mr_cgui_alv_box ).

  ENDMETHOD.

  METHOD view_display.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp603 TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lo_dynpro LIKE temp603.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp20 TYPE xsdboolean.
    DATA lv_window TYPE abap_bool.
    DATA temp21 TYPE xsdboolean.
    DATA ls_button TYPE z2ui5_cl_cgui_report=>ty_s_cgui_button.
    DATA toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.

    " submit( as_window ): the selection screen over the caller's view
    IF mv_cgui_as_window = abap_true AND mv_cgui_screen = cs_screen-selection AND mv_cgui_denied = abap_false.
      view_display_submit_window( ).
      RETURN.
    ENDIF.
    IF mv_cgui_as_window_on = abap_true.
      client->popup_destroy( ).
      mv_cgui_as_window_on = abap_false.
    ENDIF.


    view = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `xmlns:z2ui5`  v = `z2ui5.cc`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height`       v = `100%` ).

    " the PBO of a dynpro runs first - its title is the title of the page

    IF mv_cgui_screen = cs_screen-dynpro AND mv_cgui_denied = abap_false.
      temp603 = view_display_dynpro( ).
    ELSE.
      CLEAR temp603.
    ENDIF.

    lo_dynpro = temp603.



    temp20 = boolc( mv_cgui_screen = cs_screen-output OR mv_cgui_screen = cs_screen-dynpro OR mv_cgui_called = abap_true ).
    page = view->ele( `Page`
        )->a( n = `title`          t = mv_cgui_title
        )->a( n = `showNavButton`  b = temp20
        )->a( n = `navButtonPress` v = client->_event( cs_ucomm-back ) ).
    view_display_header( page ).



    temp21 = boolc( mv_cgui_screen = cs_screen-output AND mv_cgui_window = abap_true AND mt_cgui_level IS NOT INITIAL ).
    lv_window = temp21.
    " no authorization: nothing but the messages
    IF mv_cgui_denied = abap_true.
      CLEAR lv_window.
    ENDIF.

    ls_button = view_display_body( page   = page
                                         dynpro = lo_dynpro
                                         window = lv_window ).


    toolbar = page->ele( `footer`
        )->ele( `OverflowToolbar` ).

    messages_render( page    = page
                     toolbar = toolbar ).

    IF mv_cgui_denied = abap_true.
      client->view_display( view->stringify( ) ).
      RETURN.
    ENDIF.

    view_display_toolbar( toolbar = toolbar
                          button  = ls_button ).

    client->view_display( view->stringify( ) ).
    shortcuts_register( ).
    view_display_after( lv_window ).

  ENDMETHOD.

  METHOD view_display_header.
      DATA temp604 TYPE string.
      DATA temp605 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp606 TYPE z2ui5_if_client=>ty_s_event_control.
      DATA temp607 TYPE z2ui5_if_client=>ty_s_event_control.

    IF mv_cgui_cmd_on = abap_true AND mv_cgui_denied = abap_false.

      temp604 = 'Command'(054).
      page->ele( `headerContent`
          )->tag( `Input`
              )->a( n = `value`       v = client->_bind( mv_cgui_okcode )
              )->a( n = `placeholder` t = temp604
              )->a( n = `width`       v = `12rem`
              )->a( n = `submit`      v = client->_event( cs_ucomm-okcode ) ).
    ENDIF.

    " the storage controls read the variants and the parameter IDs out of
    " the browser's local storage into mv_cgui_variants and mv_cgui_spa and
    " report them when they differ from what the backend has - fired while
    " the first view still renders, so the event is queued instead of
    " dropped (check_queue_last); both report the same event, which handles
    " what arrived
    IF mo_cgui_store IS NOT BOUND.

      CLEAR temp605.
      temp605-check_queue_last = abap_true.
      page->tag( n = `Storage` ns = `z2ui5`
          )->a( n = `type`     v = `local`
          )->a( n = `prefix`   v = cv_cgui_variant_prefix
          )->a( n = `key`      t = variant_key( )
          )->a( n = `value`    v = client->_bind( mv_cgui_variants )
          )->a( n = `finished` v = client->_event( val    = cs_ucomm-variants_loaded
                                                   s_ctrl = temp605 ) ).
    ENDIF.
    " the input history of this report - read once, written by history_store( )

    CLEAR temp606.
    temp606-check_queue_last = abap_true.
    page->tag( n = `Storage` ns = `z2ui5`
        )->a( n = `type`     v = `local`
        )->a( n = `prefix`   v = cv_cgui_history_prefix
        )->a( n = `key`      t = variant_key( )
        )->a( n = `value`    v = client->_bind( mv_cgui_history )
        )->a( n = `finished` v = client->_event( val    = cs_ucomm-variants_loaded
                                                 s_ctrl = temp606 ) ).
    " the parameter IDs - a server store has them already (spa_load( ))
    IF mo_cgui_store IS NOT BOUND.

      CLEAR temp607.
      temp607-check_queue_last = abap_true.
      page->tag( n = `Storage` ns = `z2ui5`
          )->a( n = `type`     v = `local`
          )->a( n = `prefix`   v = cv_cgui_spa_prefix
          )->a( n = `key`      v = cv_cgui_spa_key
          )->a( n = `value`    v = client->_bind( mv_cgui_spa )
          )->a( n = `finished` v = client->_event( val    = cs_ucomm-variants_loaded
                                                   s_ctrl = temp607 ) ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display_body.
      DATA screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    " no authorization: nothing but the messages
    IF mv_cgui_denied = abap_true.
      RETURN.
    ENDIF.
    IF dynpro IS BOUND.
      dynpro->render( page ).
      gui_docked( dynnr = mv_cgui_dynpro
                  node  = page ).
      CLEAR result.
      result-text = 'Continue'(046).
      result-icon = `sap-icon://accept`.
      result-ucomm = cs_ucomm-enter.
    ELSEIF mv_cgui_screen = cs_screen-output.
      IF window = abap_true.
        view_display_window_base( page ).
      ELSE.
        view_display_output( page ).
      ENDIF.
      CLEAR result.
      result-text = 'Back'(025).
      result-icon = `sap-icon://nav-back`.
      result-ucomm = cs_ucomm-back.
    ELSE.

      screen = selection_screen_prepare( ).
      screen->render( page ).
      gui_docked( dynnr = `1000`
                  node  = page ).
      CLEAR result.
      result-text = 'Execute'(026).
      result-icon = `sap-icon://begin`.
      result-ucomm = cs_ucomm-execute.
    ENDIF.


  ENDMETHOD.

  METHOD view_display_toolbar.
      DATA temp608 LIKE sy-subrc.
        DATA temp609 TYPE string.
      DATA temp610 LIKE sy-subrc.
        DATA temp611 TYPE string.
      DATA temp612 LIKE sy-subrc.
        DATA temp613 TYPE string.
      DATA temp614 LIKE sy-subrc.
        DATA temp615 TYPE string.
        DATA temp616 TYPE string.
      DATA temp617 LIKE sy-subrc.
        DATA temp618 TYPE string.

    IF mv_cgui_screen = cs_screen-selection AND mt_cgui_field IS NOT INITIAL.
      " RS_SET_SELSCREEN_STATUS switches standard functions off

      READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-background TRANSPORTING NO FIELDS.
      temp608 = sy-subrc.
      IF mo_cgui_job IS BOUND AND NOT temp608 = 0.

        temp609 = 'Execute in Background'(049).
        toolbar->tag( `Button`
            )->a( n = `text`  t = temp609
            )->a( n = `icon`  v = `sap-icon://history`
            )->a( n = `press` v = client->_event( cs_ucomm-background ) ).
      ENDIF.

      READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-variant_get TRANSPORTING NO FIELDS.
      temp610 = sy-subrc.
      IF NOT temp610 = 0.

        temp611 = 'Get Variant'(016).
        toolbar->tag( `Button`
            )->a( n = `text`  t = temp611
            )->a( n = `icon`  v = `sap-icon://open-folder`
            )->a( n = `press` v = client->_event( cs_ucomm-variant_get ) ).
      ENDIF.

      READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-variant_save TRANSPORTING NO FIELDS.
      temp612 = sy-subrc.
      IF NOT temp612 = 0.

        temp613 = 'Save as Variant'(014).
        toolbar->tag( `Button`
            )->a( n = `text`  t = temp613
            )->a( n = `icon`  v = `sap-icon://save`
            )->a( n = `press` v = client->_event( cs_ucomm-variant_save ) ).
      ENDIF.

      READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-variant_delete TRANSPORTING NO FIELDS.
      temp614 = sy-subrc.
      IF NOT temp614 = 0.

        temp615 = 'Delete Variant'(007).
        toolbar->tag( `Button`
            )->a( n = `text`  t = temp615
            )->a( n = `icon`  v = `sap-icon://delete`
            )->a( n = `press` v = client->_event( cs_ucomm-variant_delete ) ).
      ENDIF.
      IF mv_cgui_draft_restored = abap_true.

        temp616 = 'Discard Draft'(071).
        toolbar->tag( `Button`
            )->a( n = `text`  t = temp616
            )->a( n = `icon`  v = `sap-icon://delete`
            )->a( n = `press` v = client->_event( cs_ucomm-draft_discard ) ).
      ENDIF.

      READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-link_copy TRANSPORTING NO FIELDS.
      temp617 = sy-subrc.
      IF NOT temp617 = 0.

        temp618 = 'Copy Link'(027).
        toolbar->tag( `Button`
            )->a( n = `text`    t = temp618
            )->a( n = `icon`    v = `sap-icon://chain-link`
            )->a( n = `press`   v = client->_event( cs_ucomm-link_copy ) ).
      ENDIF.

    ENDIF.

    view_display_toolbar_keys( toolbar = toolbar
                               button  = button ).

  ENDMETHOD.

  METHOD view_display_toolbar_keys.
      DATA ls_fkey LIKE LINE OF mt_cgui_fkey.
      DATA ls_pf LIKE LINE OF mt_cgui_pf.
        DATA temp619 TYPE string.
        DATA temp93 LIKE sy-subrc.
        DATA temp94 LIKE sy-subrc.
      DATA temp620 LIKE sy-subrc.
        DATA temp621 TYPE string.
    DATA temp622 LIKE sy-subrc.
      DATA temp623 TYPE string.

    " SELECTION-SCREEN FUNCTION KEY - and SET PF-STATUS on the output
    IF mv_cgui_screen = cs_screen-selection.

      LOOP AT mt_cgui_fkey INTO ls_fkey.
        toolbar->tag( `Button`
            )->a( n = `text`  t = ls_fkey-text
            )->a( n = `icon`  v = ls_fkey-icon
            )->a( n = `press` v = client->_event( ls_fkey-ucomm ) ).
      ENDLOOP.
    ELSE.

      LOOP AT mt_cgui_pf INTO ls_pf.

        temp619 = to_upper( ls_pf-name ).


        temp94 = sy-subrc.
        READ TABLE mt_cgui_excl_out WITH KEY table_line = temp619 TRANSPORTING NO FIELDS.
        temp93 = sy-subrc.
        sy-subrc = temp94.
        IF temp93 = 0.
          CONTINUE.
        ENDIF.
        toolbar->tag( `Button`
            )->a( n = `text`    t = ls_pf-text
            )->a( n = `icon`    v = ls_pf-icon
            )->a( n = `tooltip` t = ls_pf-tooltip
            )->a( n = `press`   v = client->_event( ls_pf-name ) ).
      ENDLOOP.

      READ TABLE mt_cgui_excl_out WITH KEY table_line = cs_ucomm-print TRANSPORTING NO FIELDS.
      temp620 = sy-subrc.
      IF mv_cgui_screen <> cs_screen-dynpro AND NOT temp620 = 0.

        temp621 = 'Print'(034).
        toolbar->tag( `Button`
            )->a( n = `text`  t = temp621
            )->a( n = `icon`  v = `sap-icon://print`
            )->a( n = `press` v = client->_event( cs_ucomm-print ) ).
      ENDIF.
    ENDIF.

    toolbar->tag( `ToolbarSpacer` ).

    READ TABLE mt_cgui_excl_sel WITH KEY table_line = cs_ucomm-execute TRANSPORTING NO FIELDS.
    temp622 = sy-subrc.
    IF NOT ( button-ucomm = cs_ucomm-execute AND temp622 = 0 ).

      IF button-ucomm = cs_ucomm-execute.
        temp623 = `F8`.
      ELSEIF button-ucomm = cs_ucomm-enter.
        temp623 = `Enter`.
      ELSE.
        temp623 = `F3`.
      ENDIF.
      toolbar->tag( `Button`
          )->a( n = `text`    t = button-text
          )->a( n = `icon`    v = button-icon
          )->a( n = `type`    v = `Emphasized`
          )->a( n = `tooltip` v = temp623
          )->a( n = `press`   v = client->_event( button-ucomm ) ).
    ENDIF.


  ENDMETHOD.

  METHOD view_display_after.
      DATA temp624 TYPE string_table.
      DATA temp626 TYPE string_table.

    " inside the Fiori launchpad the shell shows the title of the report
    IF client->get( )-check_launchpad_active = abap_true AND mv_cgui_title <> mv_cgui_title_shell.
      mv_cgui_title_shell = mv_cgui_title.

      CLEAR temp624.
      INSERT mv_cgui_title INTO TABLE temp624.
      client->follow_up_action( val   = client->cs_event-set_title_launchpad
                                t_arg = temp624 ).
    ENDIF.

    " SET CURSOR FIELD
    IF mv_cgui_screen = cs_screen-selection AND mv_cgui_cursor_field IS NOT INITIAL.

      CLEAR temp626.
      INSERT z2ui5_cl_cgui_selscreen=>field_id( mv_cgui_cursor_field ) INTO TABLE temp626.
      client->follow_up_action( val   = client->cs_event-set_focus
                                t_arg = temp626 ).
      CLEAR mv_cgui_cursor_field.
    ENDIF.

    IF window = abap_true.
      view_display_window( ).
    ELSEIF mv_cgui_window_shown = abap_true.
      client->popup_destroy( ).
    ENDIF.
    mv_cgui_window_shown = window.

    IF mv_cgui_dynnr IS NOT INITIAL.
      view_display_dynnr( ).
    ENDIF.

  ENDMETHOD.

  METHOD selection_screen_layout.

    IF mv_cgui_using_dynnr IS NOT INITIAL.
      selection_screen_dynnr( dynnr  = mv_cgui_using_dynnr
                              screen = screen ).
      RETURN.
    ENDIF.
    selection_screen( screen ).

  ENDMETHOD.

  METHOD selection_screen_prepare.
    DATA temp628 LIKE LINE OF mt_cgui_vrm.
    DATA lr_vrm LIKE REF TO temp628.
    DATA temp629 TYPE z2ui5_cl_cgui_memory=>ty_t_history.
    DATA ls_history LIKE LINE OF temp629.

    result = z2ui5_cl_cgui_selscreen=>factory( client          = client
                                               value_help_auto = abap_true ).
    selection_screen_layout( result ).


    LOOP AT mt_cgui_vrm REFERENCE INTO lr_vrm.
      result->set_listbox_values( name   = lr_vrm->name
                                  values = lr_vrm->values ).
    ENDLOOP.
    mo_cgui_screen = result.
    at_selection_screen_output( result ).
    CLEAR mo_cgui_screen.
    z2ui5_cl_cgui_memory=>variant_attributes_apply( ctx    = memory_ctx( )
                                                    screen = result ).
    value_state_set( result ).
    mt_cgui_field = result->get_fields( ).
    mt_cgui_fkey = result->get_function_keys( ).
    so_buffer_prepare( result ).
    tab_binding_prepare( result ).

    temp629 = z2ui5_cl_cgui_memory=>history_get( memory_ctx( ) ).

    LOOP AT temp629 INTO ls_history.
      result->set_history( name   = ls_history-name
                           values = ls_history-values ).
    ENDLOOP.

  ENDMETHOD.

  METHOD view_display_submit_window.

    DATA screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp630 TYPE string.
    DATA temp95 TYPE string.
    screen = selection_screen_prepare( ).


    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = mv_cgui_title
        )->a( n = `contentWidth` v = `40rem`
        )->a( n = `resizable`    b = abap_true
        )->a( n = `draggable`    b = abap_true ).

    screen->render( lo_dialog->ele( `content` ) ).
    " the messages of the checks - a bar of their own only when there are any
    IF mt_cgui_log IS NOT INITIAL.
      messages_render( page    = lo_dialog
                       toolbar = lo_dialog->ele( `subHeader` )->ele( `OverflowToolbar` ) ).
    ENDIF.


    temp630 = 'Execute'(026).

    temp95 = 'Cancel'(068).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`    t = temp630
        )->a( n = `icon`    v = `sap-icon://begin`
        )->a( n = `type`    v = `Emphasized`
        )->a( n = `tooltip` v = `F8`
        )->a( n = `press`   v = client->_event( cs_ucomm-execute )
        )->tag( `Button`
        )->a( n = `text`    t = temp95
        )->a( n = `icon`    v = `sap-icon://decline`
        )->a( n = `press`   v = client->_event( cs_ucomm-back ) ).

    client->popup_display( lo_dialog->stringify( ) ).
    mv_cgui_as_window_on = abap_true.

  ENDMETHOD.

  METHOD view_display_dynnr.

    " CALL SELECTION-SCREEN ... AS WINDOW - bound to the attributes of the
    " report like the selection screen itself
    DATA screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA temp631 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp632 LIKE LINE OF mt_cgui_log.
    DATA lr_msg LIKE REF TO temp632.
    DATA temp633 TYPE string.
    DATA temp96 TYPE string.
    screen = z2ui5_cl_cgui_selscreen=>factory( client ).
    selection_screen_dynnr( dynnr  = mv_cgui_dynnr
                            screen = screen ).
    " its PBO: AT SELECTION-SCREEN OUTPUT, as for every selection screen
    mo_cgui_screen = screen.
    at_selection_screen_output( screen ).
    CLEAR mo_cgui_screen.
    mt_cgui_dynnr_field = screen->get_fields( ).


    IF mv_cgui_dynnr_title IS NOT INITIAL.
      temp631 = mv_cgui_dynnr_title.
    ELSE.
      temp631 = mv_cgui_title.
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = temp631
        )->a( n = `contentWidth` v = `40rem`
        )->a( n = `afterClose`   v = client->_event( cs_ucomm-screen_cancel ) ).


    lo_content = lo_dialog->ele( `content` ).


    LOOP AT mt_cgui_log REFERENCE INTO lr_msg WHERE type = `E`.
      lo_content->tag( `MessageStrip`
          )->a( n = `text`  t = lr_msg->text
          )->a( n = `type`  v = `Error`
          )->a( n = `class` v = `sapUiSmallMargin` ).
    ENDLOOP.
    screen->render( lo_content ).


    temp633 = 'OK'(029).

    temp96 = 'Cancel'(030).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp633
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_ucomm-screen_ok )
        )->tag( `Button`
        )->a( n = `text`  t = temp96
        )->a( n = `press` v = client->_event( cs_ucomm-screen_cancel ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD alv_render.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <page> TYPE STANDARD TABLE.
      DATA lr_src TYPE REF TO data.
        DATA lr_tab TYPE REF TO data.
        DATA lv_all TYPE i.
          DATA lr_sums TYPE REF TO data.
        DATA lt_index TYPE z2ui5_cl_cgui_alv=>ty_t_index.
        DATA lv_total TYPE i.
          DATA lv_row LIKE LINE OF lt_index.
            FIELD-SYMBOLS <page_row> TYPE any.

    IF mo_cgui_alv IS BOUND.

      lr_src = alv_source( ).
      IF lr_src IS BOUND.
        " the copy with the box field follows the table of the report
        ASSIGN lr_src->* TO <tab>.
        IF mo_cgui_alv->has_selection( ) = abap_true
            AND mo_cgui_alv->has_box_field( <tab> ) = abap_false.
          alv_box_refresh( lr_src ).
        ENDIF.

        lr_tab = alv_shown( ).
        ASSIGN lr_tab->* TO <tab>.
        IF mv_cgui_layout_done = abap_false.
          layout_default_apply( <tab> ).
        ENDIF.
        " filtered: the browser gets a copy of the rows the filter lets
        " through, mt_cgui_alv_index leads back to the rows of the table.
        " Paged (set_paging): the copy holds the first rows of the order the
        " grid shows, the grid binds it with window_bind_tab( ) and asks for
        " the next ones (alv_window( ))

        lv_all = lines( <tab> ).
        CLEAR: mr_cgui_alv_page, mt_cgui_alv_index, mt_cgui_alv_order.
        IF mo_cgui_alv->get_page_size( ) > 0.
          mt_cgui_alv_order = mo_cgui_alv->window_order( <tab> ).
          " the totals add up every row of the order, not the first ones
          " the page holds

          lr_sums = alv_order_rows( lr_tab ).
          CREATE DATA mr_cgui_alv_page LIKE <tab>.
          alv_window_load( skip = 0
                           top  = mo_cgui_alv->get_page_size( ) ).
          ASSIGN mr_cgui_alv_page->* TO <tab>.
          mo_cgui_alv->render( node   = node
                               client = client
                               tab    = <tab>
                               total  = mv_cgui_alv_total
                               all    = lv_all
                               sums   = lr_sums ).
          RETURN.
        ENDIF.

        lt_index = mo_cgui_alv->filter_index( <tab> ).

        lv_total = lines( lt_index ).
        IF mo_cgui_alv->is_filtered( ) = abap_true.
          CREATE DATA mr_cgui_alv_page LIKE <tab>.
          ASSIGN mr_cgui_alv_page->* TO <page>.
          " empty - the transpiled runtime copies the rows along with LIKE
          CLEAR <page>.

          LOOP AT lt_index INTO lv_row.

            READ TABLE <tab> ASSIGNING <page_row> INDEX lv_row.
            IF sy-subrc = 0.
              INSERT <page_row> INTO TABLE <page>.
              INSERT lv_row INTO TABLE mt_cgui_alv_index.
            ENDIF.
          ENDLOOP.
          ASSIGN mr_cgui_alv_page->* TO <tab>.
        ENDIF.
        mo_cgui_alv->render( node   = node
                             client = client
                             tab    = <tab>
                             total  = lv_total
                             all    = lv_all ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD view_display_output.
      DATA lt_input_bind TYPE z2ui5_cl_cgui_list=>ty_t_input_bind.
      FIELD-SYMBOLS <input> LIKE LINE OF mt_cgui_list_input.
        DATA lv_input LIKE sy-tabix.
        DATA temp634 TYPE z2ui5_cl_cgui_list=>ty_s_input_bind.

    " the controls on the list - cl_gui_container=>default_screen, a
    " docking container of the run - above what it writes
    gui_docked( dynnr = `LIST`
                node  = page ).

    " a grid of the report shows the ALV in its container
    IF mo_cgui_alv IS BOUND AND mv_cgui_grid IS INITIAL.
      alv_render( page ).
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


      LOOP AT mt_cgui_list_input ASSIGNING <input>.

        lv_input = sy-tabix.

        CLEAR temp634.
        temp634-id = <input>-id.
        temp634-value = client->_bind( val = <input>-value tab = mt_cgui_list_input tab_index = lv_input ).
        temp634-flag = client->_bind( val = <input>-flag tab = mt_cgui_list_input tab_index = lv_input ).
        INSERT temp634 INTO TABLE lt_input_bind.
      ENDLOOP.
      mo_cgui_list->set_input_binds( lt_input_bind ).
      mo_cgui_list->render( node   = page
                            client = client
                            inputs = mt_cgui_list_input ).
    ENDIF.

  ENDMETHOD.

  METHOD value_state_set.

    DATA lv_state TYPE string.

    DATA temp635 LIKE LINE OF mt_cgui_log.
    DATA lr_msg LIKE REF TO temp635.
    LOOP AT mt_cgui_log REFERENCE INTO lr_msg WHERE field IS NOT INITIAL.
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

    DATA temp636 LIKE LINE OF mt_cgui_msg.
    DATA lr_msg LIKE REF TO temp636.
    DATA lv_listed LIKE abap_false.
        DATA temp637 TYPE string_table.
    DATA lv_box TYPE string.
    DATA ls_box LIKE LINE OF mt_cgui_box.
      DATA temp639 TYPE string.
      DATA temp640 TYPE string.
          DATA temp97 TYPE string.
          DATA temp98 TYPE string.
    LOOP AT mt_cgui_msg REFERENCE INTO lr_msg.
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

    " a popup opened in this roundtrip covers the screen - the popover waits
    " for the screen to show again

    lv_listed = abap_false.
    IF lv_popover = abap_true AND mv_cgui_nav = abap_true.
      mv_cgui_log_later = abap_true.
      lv_listed = abap_true.
    ELSEIF mv_cgui_nav = abap_false AND mv_cgui_dynnr IS INITIAL.
      IF mv_cgui_log_later = abap_true AND mt_cgui_log IS NOT INITIAL.
        lv_popover = abap_true.
      ENDIF.
      mv_cgui_log_later = abap_false.
      IF lv_popover = abap_true.
        lv_listed = abap_true.
        " the popover is part of the screen, and opened in a roundtrip of its
        " own: opened by the response that builds the screen, it stayed open
        " without ever being rendered (the frontend holds the rendering back
        " while it swaps the view). A timer of no time raises that roundtrip

        CLEAR temp637.
        INSERT cs_ucomm-messages_open INTO TABLE temp637.
        INSERT `0` INTO TABLE temp637.
        INSERT `X` INTO TABLE temp637.
        client->follow_up_action( val   = client->cs_event-start_timer
                                  t_arg = temp637 ).
      ENDIF.
    ENDIF.
    " the I messages - in the popover when it opens, else in a box
    IF lv_listed = abap_true.
      CLEAR lv_text.
    ENDIF.

    " _msg_box( ): one box, its type the worst of the messages - the I
    " messages of the run in it as well, a second box would replace the first
    IF mt_cgui_box IS INITIAL.
      IF lv_text IS NOT INITIAL.
        client->message_box_display( text = lv_text
                                     type = `information` ).
      ENDIF.
      RETURN.
    ENDIF.

    lv_box = `information`.

    LOOP AT mt_cgui_box INTO ls_box.

      IF lv_text IS INITIAL.
        temp639 = ls_box-text.
      ELSE.
        temp639 = lv_text && cl_abap_char_utilities=>newline && ls_box-text.
      ENDIF.
      lv_text = temp639.

      CASE ls_box-type.
        WHEN `E` OR `A`.
          temp640 = `error`.
        WHEN `W`.

          IF lv_box = `error`.
            temp97 = lv_box.
          ELSE.
            temp97 = `warning`.
          ENDIF.
          temp640 = temp97.
        WHEN `S`.

          IF lv_box = `information`.
            temp98 = `success`.
          ELSE.
            temp98 = lv_box.
          ENDIF.
          temp640 = temp98.
        WHEN OTHERS.
          temp640 = lv_box.
      ENDCASE.
      lv_box = temp640.
    ENDLOOP.
    client->message_box_display( text = lv_text
                                 type = lv_box ).

  ENDMETHOD.

  METHOD messages_render.

    " the button counts the messages of the run - icon and type follow the
    " worst of them - and opens the popover in the browser, no roundtrip.
    " The popover is a dependent of the page, not a popover of its own: it
    " comes and goes with the screen it belongs to
    DATA lv_index TYPE i.
    DATA lv_icon TYPE string.
    DATA lv_type TYPE string.
    DATA temp641 LIKE sy-subrc.
    DATA temp642 LIKE sy-tabix.
    DATA temp643 TYPE string_table.
    DATA temp99 TYPE string.
    DATA items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp645 LIKE LINE OF mt_cgui_log.
    DATA lr_msg LIKE REF TO temp645.
      DATA temp646 TYPE string.
      DATA temp22 TYPE xsdboolean.

    IF mt_cgui_log IS INITIAL.
      RETURN.
    ENDIF.


    lv_icon = `sap-icon://message-information`.

    lv_type = `Transparent`.


    temp642 = sy-tabix.
    READ TABLE mt_cgui_log WITH KEY type = `W` TRANSPORTING NO FIELDS.
    temp641 = sy-subrc.
    sy-tabix = temp642.
    IF temp641 = 0.
      lv_icon = `sap-icon://message-warning`.
      lv_type = `Default`.
    ENDIF.
    LOOP AT mt_cgui_log TRANSPORTING NO FIELDS WHERE type = `E` OR type = `A`.
      lv_icon = `sap-icon://message-error`.
      lv_type = `Reject`.
      EXIT.
    ENDLOOP.


    CLEAR temp643.
    INSERT cv_cgui_popover_id INTO TABLE temp643.
    INSERT `toggleBy` INTO TABLE temp643.
    INSERT cv_cgui_messages_id INTO TABLE temp643.

    temp99 = 'Messages'(031).
    toolbar->tag( `Button`
        )->a( n = `id`      v = cv_cgui_messages_id
        )->a( n = `icon`    v = lv_icon
        )->a( n = `type`    v = lv_type
        )->a( n = `text`    t = |{ lines( mt_cgui_log ) }|
        )->a( n = `tooltip` t = temp99
        )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                          t_arg = temp643 ) ).


    items = page->ele( `dependents`
        )->ele( `MessagePopover`
            )->a( n = `id`               v = cv_cgui_popover_id
            )->a( n = `placement`        v = `Top`
            )->a( n = `activeTitlePress` v = client->_event( val = cs_ucomm-message_focus
                                                             arg = `${$parameters>/item}` )
        )->ele( `items` ).

    " the id carries the index into the log: the event hands the item over
    " as its properties and its id, and the id leads back to the field


    LOOP AT mt_cgui_log REFERENCE INTO lr_msg.
      lv_index = sy-tabix.

      CASE lr_msg->type.
        WHEN `E` OR `A`.
          temp646 = `Error`.
        WHEN `W`.
          temp646 = `Warning`.
        WHEN OTHERS.
          temp646 = `Information`.
      ENDCASE.

      temp22 = boolc( lr_msg->field IS NOT INITIAL AND mv_cgui_screen = cs_screen-selection ).
      items->tag( `MessageItem`
          )->a( n = `id`          t = |cgui_msg_{ lv_index }|
          )->a( n = `type`        v = temp646
          )->a( n = `title`       t = lr_msg->text
          )->a( n = `subtitle`    t = message_field_text( lr_msg->field )
          )->a( n = `activeTitle` b = temp22 ).
    ENDLOOP.

  ENDMETHOD.

  METHOD message_focus.

    DATA lv_index TYPE string.

    DATA temp647 TYPE string_table.
    DATA lv_length TYPE i.
    DATA lv_digits TYPE i.
      DATA lv_digit TYPE string.
    DATA temp649 TYPE i.
    DATA lr_msg TYPE REF TO z2ui5_cl_cgui_report=>ty_s_cgui_msg.
    DATA temp650 TYPE string_table.
    CLEAR temp647.
    INSERT cv_cgui_popover_id INTO TABLE temp647.
    INSERT `close` INTO TABLE temp647.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp647 ).

    " the id of the item, cgui_msg_<n> - n is the index into the log
    lv_index = substring_after( val = arg
                                sub = `cgui_msg_` ).
    IF lv_index IS INITIAL.
      RETURN.
    ENDIF.

    lv_length = strlen( lv_index ).

    lv_digits = 0.
    WHILE lv_digits < lv_length.

      lv_digit = substring( val = lv_index off = lv_digits len = 1 ).
      IF lv_digit CN `0123456789`.
        EXIT.
      ENDIF.
      lv_digits = lv_digits + 1.
    ENDWHILE.
    IF lv_digits = 0.
      RETURN.
    ENDIF.
    lv_index = substring( val = lv_index len = lv_digits ).


    temp649 = lv_index.

    READ TABLE mt_cgui_log REFERENCE INTO lr_msg INDEX temp649.
    IF sy-subrc <> 0 OR lr_msg->field IS INITIAL OR mv_cgui_screen <> cs_screen-selection.
      RETURN.
    ENDIF.


    CLEAR temp650.
    INSERT z2ui5_cl_cgui_selscreen=>field_id( lr_msg->field ) INTO TABLE temp650.
    client->follow_up_action( val   = client->cs_event-set_focus
                              t_arg = temp650 ).

  ENDMETHOD.

  METHOD message_field_text.
    DATA lr_field TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_field.

    IF field IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE mt_cgui_field REFERENCE INTO lr_field WITH KEY name = field.
    IF sy-subrc = 0.
      result = lr_field->text.
    ELSE.
      result = field.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
