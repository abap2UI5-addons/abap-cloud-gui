"! Selection screen - the abap2UI5 counterpart of PARAMETERS,
"! SELECT-OPTIONS and SELECTION-SCREEN, built on z2ui5_cl_ui5_view_builder.
"! Every field method takes the variable itself - a PUBLIC attribute of the
"! running app - and binds it two-way, so the user's input is in the
"! attribute when the next event arrives:
"!   z2ui5_cl_cgui_selscreen=>factory( client
"!       )->block_begin( `Selection`
"!       )->parameter( val = p_carrid obligatory = abap_true
"!       )->select_option( s_date
"!       )->checkbox( val = p_test text = `Test run`
"!       )->block_end( ).
"! render( ) appends the screen to a node of an existing view, stringify( )
"! returns it as a complete view of its own. With preview the fields are
"! shown but not bound - any data object will do, which is how the
"! selection screen painter shows a screen before its report exists.
"! Two controls raise events the app answers: a select-option opens its
"! range popup with cs_event-select_option, F4 on a field declared with
"! value_help raises cs_event-value_request - both carry the attribute name
"! as first event argument. A select-option with value_help gets a button
"! of its own for the range popup. z2ui5_cl_cgui_report handles both for
"! you, and declares value_help_auto: every field whose DDIC type has fixed
"! values or a value table gets F4 without asking.
"! A checkbox or a radio button group declared with user_command raises
"! that event as soon as the user changes it - the classic USER-COMMAND.
"! The screen can be changed before it is rendered, the classic
"! AT SELECTION-SCREEN OUTPUT:
"!   LOOP AT screen->loop_at_screen( ) INTO DATA(ls_screen).
"!     IF ls_screen-group1 = `EXP`.
"!       ls_screen-active = abap_false.
"!       screen->modify_screen( ls_screen ).
"!     ENDIF.
"!   ENDLOOP.
CLASS z2ui5_cl_cgui_selscreen DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF cs_event,
        select_option TYPE string VALUE `CGUI_SELECT_OPTION`,
        value_request TYPE string VALUE `CGUI_VALUE_REQUEST`,
        "! a tab of a tabstrip of a dynpro pressed - its function code the
        "! first argument
        tab           TYPE string VALUE `CGUI_TAB`,
        help_request  TYPE string VALUE `CGUI_HELP_REQUEST`,
      END OF cs_event.

    CONSTANTS:
      "! the part of a select-option F4 is asked for - the second argument of
      "! cs_event-value_request
      BEGIN OF cs_part,
        low  TYPE string VALUE `LOW`,
        high TYPE string VALUE `HIGH`,
      END OF cs_part.

    CONSTANTS:
      BEGIN OF cs_field_kind,
        parameter     TYPE string VALUE `P`,
        select_option TYPE string VALUE `S`,
      END OF cs_field_kind.

    TYPES:
      "! kind is cs_field_kind, upper whether the input is converted to upper
      "! case (a character field without LOWER CASE), no_display the classic
      "! NO-DISPLAY, value_help whether the field has F4, no_intervals the
      "! classic NO INTERVALS of a select-option, max_length its input length,
      "! value_check the classic VALUE CHECK, help whether F1 has a text, dtel
      "! the data element, block the name of the block it is in, group the
      "! group of a radio button
      BEGIN OF ty_s_field,
        name       TYPE string,
        text       TYPE string,
        obligatory TYPE abap_bool,
        shown      TYPE abap_bool,
        kind       TYPE string,
        upper      TYPE abap_bool,
        no_display   TYPE abap_bool,
        memory_id    TYPE string,
        value_help   TYPE abap_bool,
        no_intervals TYPE abap_bool,
        max_length   TYPE i,
        value_check  TYPE abap_bool,
        help         TYPE abap_bool,
        dtel         TYPE string,
        block        TYPE string,
        group        TYPE string,
        matchcode    TYPE string,
        entity       TYPE string,
        entity_elem  TYPE string,
      END OF ty_s_field.

    TYPES:
      "! SELECTION-SCREEN FUNCTION KEY n - a button of the toolbar raising
      "! FC0n as user command
      BEGIN OF ty_s_function_key,
        number TYPE i,
        ucomm  TYPE string,
        text   TYPE string,
        icon   TYPE string,
      END OF ty_s_function_key.
    TYPES ty_t_function_key TYPE STANDARD TABLE OF ty_s_function_key WITH DEFAULT KEY.
    TYPES ty_t_field TYPE STANDARD TABLE OF ty_s_field WITH DEFAULT KEY.

    TYPES:
      "! a value of a listbox - the classic VRM_VALUES
      BEGIN OF ty_s_value,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_value.
    TYPES ty_t_value TYPE STANDARD TABLE OF ty_s_value WITH DEFAULT KEY.

    TYPES:
      "! a line of loop_at_screen( ) - the classic SCREEN structure, with
      "! abap_bool flags instead of '0' / '1'. id is the position of the field
      "! on the screen, modify_screen( ) finds it by that - leave it unchanged
      BEGIN OF ty_s_screen,
        id        TYPE i,
        name      TYPE string,
        group1    TYPE string,
        active    TYPE abap_bool,
        input     TYPE abap_bool,
        required  TYPE abap_bool,
        invisible TYPE abap_bool,
        intensified TYPE abap_bool,
        recommended TYPE abap_bool,
        length      TYPE i,
      END OF ty_s_screen.
    TYPES ty_t_screen TYPE STANDARD TABLE OF ty_s_screen WITH DEFAULT KEY.

    "! value_help_auto - F4 for every field whose DDIC type has a standard
    "! F4 (domain fixed values, value table); the caller answers
    "! cs_event-value_request for them
    "! app - the app whose attributes the fields are; without one the app
    "! of client. A screen without client binds nothing: it only collects
    "! its fields, what a background run needs
    CLASS-METHODS factory
      IMPORTING
        client          TYPE REF TO z2ui5_if_client OPTIONAL
        value_help_auto TYPE abap_bool DEFAULT abap_false
        preview         TYPE abap_bool DEFAULT abap_false
        app             TYPE REF TO object OPTIONAL
          PREFERRED PARAMETER client
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECTION-SCREEN BEGIN OF BLOCK ... WITH FRAME TITLE
    "! name - the classic block name, for AT SELECTION-SCREEN ON BLOCK
    METHODS block_begin
      IMPORTING
        title         TYPE clike     OPTIONAL
        name          TYPE clike     OPTIONAL
        no_intervals  TYPE abap_bool DEFAULT abap_false
          PREFERRED PARAMETER title
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS block_end
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECTION-SCREEN BEGIN OF LINE - the following fields share one row
    METHODS line_begin
      IMPORTING
        text          TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS line_end
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! PARAMETERS - the control follows the type: DatePicker for a date,
    "! TimePicker for a time, CheckBox for an abap_bool, Input otherwise.
    "! modif_id is MODIF ID (group1 of loop_at_screen( )), no_display is
    "! NO-DISPLAY: the field keeps its value but is not shown.
    "! A character field is converted to upper case as in a classic report,
    "! unless lower_case is set or its domain allows lower case.
    "! as_listbox shows a dropdown - the values of set_listbox_values( ),
    "! the fixed values of the domain otherwise; user_command is raised when
    "! the user picks one. visible_length is VISIBLE LENGTH in characters,
    "! memory_id MEMORY ID: the report runtime fills an empty field with the
    "! value of the parameter ID and sets it on Execute. value_check is VALUE
    "! CHECK: on Execute the value must be a fixed value of the domain or a
    "! key of its value table. help - F1 (on by default): a help button
    "! beside the field when its data element has documentation, raising
    "! cs_event-help_request; help_request - the report answers F1 itself
    "! (AT SELECTION-SCREEN ON HELP-REQUEST), the button is there either way.
    "! read_only - an output field of a dynpro: shown, not ready for input
    METHODS parameter
      IMPORTING
        val            TYPE any
        text           TYPE clike     OPTIONAL
        obligatory     TYPE abap_bool DEFAULT abap_false
        value_help     TYPE abap_bool DEFAULT abap_false
        modif_id       TYPE clike     OPTIONAL
        no_display     TYPE abap_bool DEFAULT abap_false
        lower_case     TYPE abap_bool DEFAULT abap_false
        as_listbox     TYPE abap_bool DEFAULT abap_false
        user_command   TYPE clike     OPTIONAL
        visible_length TYPE i         DEFAULT 0
        memory_id      TYPE clike     OPTIONAL
        value_check    TYPE abap_bool DEFAULT abap_false
        help           TYPE abap_bool DEFAULT abap_true
        help_request   TYPE abap_bool DEFAULT abap_false
        matchcode      TYPE clike     OPTIONAL
        value_help_entity  TYPE clike     OPTIONAL
        value_help_element TYPE clike     OPTIONAL
        read_only      TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)  TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! PARAMETERS ... AS CHECKBOX [USER-COMMAND] - user_command is raised
    "! as event when the user changes the checkbox
    METHODS checkbox
      IMPORTING
        val           TYPE abap_bool
        text          TYPE clike OPTIONAL
        modif_id      TYPE clike OPTIONAL
        user_command  TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! PARAMETERS ... RADIOBUTTON GROUP [USER-COMMAND] - as in the classic
    "! statement, a user_command at one button of the group applies to all
    "! of them. Render the screen anew after each roundtrip: the event is
    "! wired to the buttons that are not selected at render time
    METHODS radiobutton
      IMPORTING
        val           TYPE abap_bool
        text          TYPE clike OPTIONAL
        group         TYPE clike DEFAULT `RB1`
        modif_id      TYPE clike OPTIONAL
        user_command  TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECT-OPTIONS - val is a range table (TYPE RANGE OF ...). In the
    "! report runtime the field shows its first line as inputs from and to,
    "! the classic look; no_intervals leaves out the to field (NO INTERVALS),
    "! no_extension the button of the multiple selection (NO-EXTENSION)
    METHODS select_option
      IMPORTING
        val           TYPE STANDARD TABLE
        text          TYPE clike     OPTIONAL
        obligatory    TYPE abap_bool DEFAULT abap_false
        value_help    TYPE abap_bool DEFAULT abap_false
        modif_id      TYPE clike     OPTIONAL
        no_display    TYPE abap_bool DEFAULT abap_false
        no_intervals  TYPE abap_bool DEFAULT abap_false
        no_extension  TYPE abap_bool DEFAULT abap_false
        lower_case    TYPE abap_bool DEFAULT abap_false
        help          TYPE abap_bool DEFAULT abap_true
        help_request  TYPE abap_bool DEFAULT abap_false
        memory_id      TYPE clike    OPTIONAL
        visible_length TYPE i        DEFAULT 0
        matchcode      TYPE clike    OPTIONAL
        value_help_entity  TYPE clike     OPTIONAL
        value_help_element TYPE clike     OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECTION-SCREEN FUNCTION KEY n (1-5) - a button of the toolbar of
    "! the screen raising FC0n, the classic SSCRFIELDS-FUNCTXT_0n
    METHODS function_key
      IMPORTING
        number        TYPE i
        text          TYPE clike
        icon          TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS get_function_keys
      RETURNING
        VALUE(result) TYPE ty_t_function_key.

    "! SELECTION-SCREEN SKIP n - empty lines
    METHODS skip
      IMPORTING
        val           TYPE i DEFAULT 1
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECTION-SCREEN ULINE - a horizontal line
    METHODS uline
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECTION-SCREEN BEGIN OF TABBED BLOCK - the tabs that follow, each
    "! opened by tab( ), up to tabbed_block_end( ). name: the tabstrip of a
    "! dynpro (CONTROLS name TYPE TABSTRIP) - its tabs have function codes,
    "! the one of name-activetab is selected and a press raises
    "! cs_event-tab with the function code of the tab
    METHODS tabbed_block_begin
      IMPORTING
        name          TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! SELECTION-SCREEN TAB - a tab; the fields and blocks that follow are
    "! on it, up to the next tab( ) or tabbed_block_end( ). fcode: the
    "! function code of a tab of a dynpro's tabstrip, area: the subscreen
    "! area it shows (its reference field)
    METHODS tab
      IMPORTING
        text          TYPE clike
        fcode         TYPE clike OPTIONAL
        area          TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! a table control of a dynpro (CONTROLS name TYPE TABLEVIEW) - the
    "! report renders the lines its PBO handed over in the columns
    METHODS table_control
      IMPORTING
        name          TYPE clike
        title         TYPE clike OPTIONAL
        columns       TYPE z2ui5_if_cgui_gui=>ty_t_tc_column
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! a subscreen area of a dynpro - the report renders the subscreen
    "! called into it (CALL SUBSCREEN); in a tabstrip on the tab that shows
    "! the area, the selected one where tabs share it
    METHODS subscreen
      IMPORTING
        area          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS tabbed_block_end
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! the last entries of field name, the latest first - offered as
    "! suggestions of its input (the input history of the SAP GUI)
    METHODS set_history
      IMPORTING
        name   TYPE clike
        values TYPE string_table.

    "! VRM_SET_VALUES - the values of the listbox of field name
    METHODS set_listbox_values
      IMPORTING
        name   TYPE clike
        values TYPE ty_t_value.

    "! the bindings of the inputs from and to of select-option name - the
    "! report runtime binds them to a buffer it turns into the range; a
    "! select-option without them shows its lines as text
    METHODS set_select_option_input
      IMPORTING
        name      TYPE clike
        low_bind  TYPE clike
        high_bind TYPE clike.

    "! the number of tabbed blocks on the screen
    METHODS get_tabbed_block_count
      RETURNING
        VALUE(result) TYPE i.

    "! the binding of the key of the selected tab of tabbed block index -
    "! keeps the tab selected over the roundtrips
    METHODS set_tabbed_block_binding
      IMPORTING
        index TYPE i
        bind  TYPE clike.

    "! SELECTION-SCREEN COMMENT
    METHODS comment
      IMPORTING
        text          TYPE clike
        modif_id      TYPE clike OPTIONAL
        for_field     TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! the custom control area name of a dynpro - the SAP GUI controls of
    "! its container (z2ui5_cl_cgui_container with container_name),
    "! rendered by the report set with set_gui( )
    METHODS custom_control
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! the report that renders the custom control areas
    METHODS set_gui
      IMPORTING
        gui TYPE REF TO z2ui5_if_cgui_gui.

    "! SELECTION-SCREEN PUSHBUTTON ... USER-COMMAND
    METHODS button
      IMPORTING
        text          TYPE clike
        event         TYPE clike
        icon          TYPE clike OPTIONAL
        modif_id      TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    "! LOOP AT SCREEN - one line per field, comment and button declared so
    "! far, NO-DISPLAY fields left out
    METHODS loop_at_screen
      RETURNING
        VALUE(result) TYPE ty_t_screen.

    "! MODIFY SCREEN - active = abap_false hides the field and its label,
    "! input = abap_false makes it read-only, required makes it obligatory,
    "! invisible masks the input as a password field
    METHODS modify_screen
      IMPORTING
        screen TYPE ty_s_screen.

    "! show a message at the field - name is the attribute name, state one
    "! of the UI5 value states Error, Warning, Success, Information
    METHODS set_value_state
      IMPORTING
        name  TYPE clike
        text  TYPE clike OPTIONAL
        state TYPE clike DEFAULT `Error`.

    "! the id of the control of a field on the screen - name is the
    "! attribute name; what SET_FOCUS needs to move the cursor there
    CLASS-METHODS field_id
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the input fields with their name and label - what a caller needs to
    "! check OBLIGATORY fields before it runs the report. A field counts as
    "! obligatory only while it is shown and ready for input; shown is set
    "! for every field that is not hidden
    METHODS get_fields
      RETURNING
        VALUE(result) TYPE ty_t_field.

    "! append the selection screen to node, a container of an existing view
    "! whose default namespace is sap.m
    METHODS render
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the selection screen as a complete view
    METHODS stringify
      IMPORTING
        title         TYPE clike DEFAULT `Selection Screen`
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF cs_kind,
        block_begin TYPE string VALUE `BLOCK_BEGIN`,
        block_end   TYPE string VALUE `BLOCK_END`,
        line_begin  TYPE string VALUE `LINE_BEGIN`,
        line_end    TYPE string VALUE `LINE_END`,
        parameter   TYPE string VALUE `PARAMETER`,
        radiobutton TYPE string VALUE `RADIOBUTTON`,
        select      TYPE string VALUE `SELECT_OPTION`,
        comment     TYPE string VALUE `COMMENT`,
        button      TYPE string VALUE `BUTTON`,
        skip        TYPE string VALUE `SKIP`,
        uline       TYPE string VALUE `ULINE`,
        tabbed      TYPE string VALUE `TABBED_BEGIN`,
        tab         TYPE string VALUE `TAB`,
        tabbed_end  TYPE string VALUE `TABBED_END`,
        custom      TYPE string VALUE `CUSTOM`,
        subscreen   TYPE string VALUE `SUBSCREEN`,
        table       TYPE string VALUE `TABLE_CONTROL`,
      END OF cs_kind.

    CONSTANTS:
      BEGIN OF cs_control,
        input    TYPE string VALUE `INPUT`,
        number   TYPE string VALUE `NUMBER`,
        date     TYPE string VALUE `DATE`,
        time     TYPE string VALUE `TIME`,
        checkbox TYPE string VALUE `CHECKBOX`,
        listbox  TYPE string VALUE `LISTBOX`,
      END OF cs_control.

    " the screen flags are kept negated (inactive, read_only), so that an
    " item created with VALUE #( ) is shown and ready for input
    TYPES:
      BEGIN OF ty_s_item,
        kind         TYPE string,
        control      TYPE string,
        name         TYPE string,
        text         TYPE string,
        bind         TYPE string,
        value        TYPE string,
        group        TYPE string,
        event        TYPE string,
        icon         TYPE string,
        required     TYPE abap_bool,
        value_help   TYPE abap_bool,
        max_length   TYPE i,
        modif_id     TYPE string,
        user_command TYPE string,
        no_display   TYPE abap_bool,
        inactive     TYPE abap_bool,
        read_only    TYPE abap_bool,
        invisible    TYPE abap_bool,
        state        TYPE string,
        state_text   TYPE string,
        selected     TYPE abap_bool,
        upper        TYPE abap_bool,
        visible_len  TYPE i,
        no_intervals TYPE abap_bool,
        no_extension TYPE abap_bool,
        value_check  TYPE abap_bool,
        help         TYPE abap_bool,
        dtel         TYPE string,
        low_bind     TYPE string,
        high_bind    TYPE string,
        lines        TYPE i,
        memory_id    TYPE string,
        matchcode    TYPE string,
        entity       TYPE string,
        entity_elem  TYPE string,
        intensified  TYPE abap_bool,
        recommended  TYPE abap_bool,
        for_field    TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_listbox,
        name   TYPE string,
        values TYPE ty_t_value,
      END OF ty_s_listbox.
    TYPES ty_t_listbox TYPE STANDARD TABLE OF ty_s_listbox WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_tab_bind,
        index TYPE i,
        bind  TYPE string,
      END OF ty_s_tab_bind.
    TYPES ty_t_tab_bind TYPE STANDARD TABLE OF ty_s_tab_bind WITH DEFAULT KEY.

    DATA client  TYPE REF TO z2ui5_if_client.
    DATA mo_app  TYPE REF TO object.
    DATA mt_item TYPE ty_t_item.
    DATA mi_gui TYPE REF TO z2ui5_if_cgui_gui.
    DATA mv_value_help_auto TYPE abap_bool.
    DATA mv_preview         TYPE abap_bool.
    DATA mt_listbox         TYPE ty_t_listbox.
    TYPES:
      BEGIN OF ty_s_history,
        name   TYPE string,
        values TYPE string_table,
      END OF ty_s_history.
    TYPES temp1_ce960d2d7e TYPE STANDARD TABLE OF ty_s_history WITH DEFAULT KEY.
DATA mt_history         TYPE temp1_ce960d2d7e.
    DATA mt_tab_bind        TYPE ty_t_tab_bind.
    " the columns of the table controls, by name
    TYPES:
      BEGIN OF ty_s_tc,
        name    TYPE string,
        columns TYPE z2ui5_if_cgui_gui=>ty_t_tc_column,
      END OF ty_s_tc.
    TYPES temp2_ce960d2d7e TYPE STANDARD TABLE OF ty_s_tc WITH DEFAULT KEY.
DATA mt_tc              TYPE temp2_ce960d2d7e.
    DATA mt_function_key    TYPE ty_t_function_key.
    " BEGIN OF BLOCK ... NO INTERVALS - the blocks open that have it
    DATA mv_block_depth     TYPE i.
    DATA mv_block_no_int    TYPE i.

    "! F1 of a field - its data element and whether it has documentation;
    "! own: the report answers F1 itself (AT SELECTION-SCREEN ON
    "! HELP-REQUEST), so the field has the button either way
    METHODS help_check
      IMPORTING
        val  TYPE any
        help TYPE abap_bool
        own  TYPE abap_bool DEFAULT abap_false
      CHANGING
        item TYPE ty_s_item.

    METHODS render_help
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    "! should input into a field of this type be converted to upper case -
    "! a character field whose domain does not allow lower case
    METHODS upper_check
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
        lower_case    TYPE abap_bool
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS listbox_values
      IMPORTING
        item          TYPE ty_s_item
      RETURNING
        VALUE(result) TYPE ty_t_value.

    METHODS render_listbox
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    METHODS render_range_input
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    METHODS render_range_field
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item
        bind TYPE string
        id   TYPE string
        help TYPE abap_bool
        part TYPE string OPTIONAL.

    METHODS item_create
      IMPORTING
        val           TYPE any
        kind          TYPE string
        text          TYPE clike
      RETURNING
        VALUE(result) TYPE ty_s_item.

    METHODS name_get
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    METHODS value_help_check
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS control_by_type
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    METHODS form_open
      IMPORTING
        node          TYPE REF TO z2ui5_cl_ui5_view_builder
        title         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! the user command of a radio button group - the first one declared at
    "! any of its buttons
    METHODS group_user_command
      IMPORTING
        group         TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_state
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    METHODS render_id
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    METHODS render_label
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    METHODS render_control
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        item   TYPE ty_s_item
        inline TYPE abap_bool DEFAULT abap_false.

    METHODS render_parameter
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

    METHODS render_select_option
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        item TYPE ty_s_item.

ENDCLASS.


CLASS z2ui5_cl_cgui_selscreen IMPLEMENTATION.

  METHOD factory.

    CREATE OBJECT result.
    result->client = client.
    result->mo_app = app.
    IF result->mo_app IS NOT BOUND AND client IS BOUND.
      result->mo_app = client->get_app( ).
    ENDIF.
    result->mv_value_help_auto = value_help_auto.
    result->mv_preview = preview.

  ENDMETHOD.

  METHOD block_begin.

    DATA temp52 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp52.
    temp52-kind = cs_kind-block_begin.
    temp52-text = title.
    temp52-group = to_upper( name ).
    temp52-no_intervals = no_intervals.
    INSERT temp52 INTO TABLE mt_item.
    mv_block_depth = mv_block_depth + 1.
    IF no_intervals = abap_true AND mv_block_no_int = 0.
      mv_block_no_int = mv_block_depth.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD block_end.

    DATA temp53 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp53.
    temp53-kind = cs_kind-block_end.
    INSERT temp53 INTO TABLE mt_item.
    IF mv_block_no_int = mv_block_depth.
      mv_block_no_int = 0.
    ENDIF.
    mv_block_depth = nmax( val1 = 0 val2 = mv_block_depth - 1 ).
    result = me.

  ENDMETHOD.

  METHOD line_begin.

    DATA temp54 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp54.
    temp54-kind = cs_kind-line_begin.
    temp54-text = text.
    INSERT temp54 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD line_end.

    DATA temp55 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp55.
    temp55-kind = cs_kind-line_end.
    INSERT temp55 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD parameter.

    DATA ls_item TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    DATA lo_descr TYPE REF TO cl_abap_typedescr.
      DATA temp56 TYPE REF TO cl_abap_elemdescr.
    ls_item = item_create( val  = val
                                 kind = cs_kind-parameter
                                 text = text ).
    ls_item-control    = control_by_type( val ).
    ls_item-required   = obligatory.
    ls_item-value_help = value_help.
    IF ls_item-value_help = abap_false
        AND ( ls_item-control = cs_control-input OR ls_item-control = cs_control-number ).
      ls_item-value_help = value_help_check( val ).
    ENDIF.
    ls_item-modif_id     = modif_id.
    ls_item-no_display   = no_display.
    ls_item-read_only    = read_only.
    ls_item-visible_len  = visible_length.
    ls_item-user_command = user_command.
    ls_item-memory_id    = to_upper( memory_id ).
    ls_item-value_check  = value_check.
    " MATCHCODE OBJECT - the search help named; a CDS entity (or a table)
    " as the value help, its element the value - what
    " @Consumption.valueHelpDefinition names
    ls_item-matchcode    = to_upper( matchcode ).
    ls_item-entity       = to_upper( value_help_entity ).
    ls_item-entity_elem  = to_upper( value_help_element ).
    IF ( ls_item-matchcode IS NOT INITIAL OR ls_item-entity IS NOT INITIAL )
        AND ( ls_item-control = cs_control-input OR ls_item-control = cs_control-number ).
      ls_item-value_help = abap_true.
    ENDIF.
    help_check( EXPORTING val  = val
                          help = help
                          own  = help_request
                CHANGING  item = ls_item ).


    lo_descr = cl_abap_typedescr=>describe_by_data( val ).
    IF lo_descr->type_kind = cl_abap_typedescr=>typekind_char
        OR lo_descr->type_kind = cl_abap_typedescr=>typekind_num.

      temp56 ?= lo_descr.
      ls_item-max_length = temp56->output_length.
    ENDIF.
    IF ls_item-control = cs_control-input.
      ls_item-upper = upper_check( descr      = lo_descr
                                   lower_case = lower_case ).
      IF as_listbox = abap_true.
        ls_item-control = cs_control-listbox.
        ls_item-value_help = abap_false.
      ENDIF.
    ENDIF.

    INSERT ls_item INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD upper_check.
        DATA temp57 TYPE REF TO cl_abap_elemdescr.
        DATA lo_elem LIKE temp57.

    IF lower_case = abap_true OR descr->type_kind <> cl_abap_typedescr=>typekind_char.
      RETURN.
    ENDIF.

    result = abap_true.
    TRY.

        temp57 ?= descr.

        lo_elem = temp57.
        IF lo_elem->is_ddic_type( ) = abap_true AND lo_elem->get_ddic_field( )-lowercase = abap_true.
          result = abap_false.
        ENDIF.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD skip.

    DATA temp58 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp58.
    temp58-kind = cs_kind-skip.
    temp58-lines = nmax( val1 = val val2 = 1 ).
    INSERT temp58 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD uline.

    DATA temp59 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp59.
    temp59-kind = cs_kind-uline.
    INSERT temp59 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD tabbed_block_begin.

    DATA temp60 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp60.
    temp60-kind = cs_kind-tabbed.
    temp60-name = to_upper( name ).
    INSERT temp60 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD tab.

    DATA temp61 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp61.
    temp61-kind = cs_kind-tab.
    temp61-text = text.
    temp61-event = to_upper( fcode ).
    temp61-group = to_upper( area ).
    INSERT temp61 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD table_control.

    DATA temp62 TYPE string.
    DATA lv_name TYPE string.
    DATA temp63 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    DATA temp64 TYPE z2ui5_cl_cgui_selscreen=>ty_s_tc.
    temp62 = name.

    lv_name = to_upper( condense( temp62 ) ).

    CLEAR temp63.
    temp63-kind = cs_kind-table.
    temp63-name = lv_name.
    temp63-text = title.
    INSERT temp63 INTO TABLE mt_item.
    DELETE mt_tc WHERE name = lv_name.

    CLEAR temp64.
    temp64-name = lv_name.
    temp64-columns = columns.
    INSERT temp64 INTO TABLE mt_tc.
    result = me.

  ENDMETHOD.

  METHOD subscreen.

    DATA temp65 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp65.
    temp65-kind = cs_kind-subscreen.
    temp65-name = to_upper( area ).
    INSERT temp65 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD tabbed_block_end.

    DATA temp66 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp66.
    temp66-kind = cs_kind-tabbed_end.
    INSERT temp66 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD set_history.

    DATA lv_name TYPE string.
      DATA temp67 TYPE z2ui5_cl_cgui_selscreen=>ty_s_history.
    lv_name = to_upper( name ).
    DELETE mt_history WHERE name = lv_name.
    IF values IS NOT INITIAL.

      CLEAR temp67.
      temp67-name = lv_name.
      temp67-values = values.
      INSERT temp67 INTO TABLE mt_history.
    ENDIF.

  ENDMETHOD.

  METHOD set_listbox_values.

    DATA lv_name TYPE string.
    DATA temp68 TYPE z2ui5_cl_cgui_selscreen=>ty_s_listbox.
    lv_name = to_upper( name ).
    DELETE mt_listbox WHERE name = lv_name.

    CLEAR temp68.
    temp68-name = lv_name.
    temp68-values = values.
    INSERT temp68 INTO TABLE mt_listbox.

  ENDMETHOD.

  METHOD listbox_values.

    FIELD-SYMBOLS <field_val> TYPE any.

    DATA lr_listbox TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_listbox.
    DATA temp69 TYPE z2ui5_cl_cgui_context=>ty_t_fix_val.
    DATA temp7 LIKE LINE OF temp69.
    DATA lr_fix LIKE REF TO temp7.
      DATA temp70 TYPE z2ui5_cl_cgui_selscreen=>ty_s_value.
    READ TABLE mt_listbox REFERENCE INTO lr_listbox WITH KEY name = item-name.
    IF sy-subrc = 0.
      result = lr_listbox->values.
      RETURN.
    ENDIF.

    " the fixed values of the domain - read over the attribute of the app
    IF item-name IS INITIAL OR mv_preview = abap_true.
      RETURN.
    ENDIF.
    IF mo_app IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mo_app->(item-name) TO <field_val>.
    IF <field_val> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    temp69 = z2ui5_cl_cgui_context=>rtti_get_fixed_values( cl_abap_typedescr=>describe_by_data( <field_val> ) ).


    LOOP AT temp69 REFERENCE INTO lr_fix.

      CLEAR temp70.
      temp70-key = lr_fix->low.
      temp70-text = lr_fix->text.
      INSERT temp70 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_select_option_input.

    DATA lv_name TYPE string.
    DATA temp71 LIKE LINE OF mt_item.
    DATA lr_item LIKE REF TO temp71.
    lv_name = to_upper( name ).


    LOOP AT mt_item REFERENCE INTO lr_item WHERE kind = cs_kind-select AND name = lv_name.
      lr_item->low_bind  = low_bind.
      lr_item->high_bind = high_bind.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_tabbed_block_count.

    LOOP AT mt_item TRANSPORTING NO FIELDS WHERE kind = cs_kind-tabbed.
      result = result + 1.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_tabbed_block_binding.
    DATA temp72 TYPE z2ui5_cl_cgui_selscreen=>ty_s_tab_bind.

    DELETE mt_tab_bind WHERE index = index.

    CLEAR temp72.
    temp72-index = index.
    temp72-bind = bind.
    INSERT temp72 INTO TABLE mt_tab_bind.

  ENDMETHOD.

  METHOD checkbox.

    DATA ls_item TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    ls_item = item_create( val  = val
                                 kind = cs_kind-parameter
                                 text = text ).
    ls_item-control      = cs_control-checkbox.
    ls_item-modif_id     = modif_id.
    ls_item-user_command = user_command.

    INSERT ls_item INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD radiobutton.

    DATA ls_item TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    ls_item = item_create( val  = val
                                 kind = cs_kind-radiobutton
                                 text = text ).
    ls_item-group        = group.
    ls_item-modif_id     = modif_id.
    ls_item-user_command = user_command.
    ls_item-selected     = val.

    INSERT ls_item INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD select_option.

    DATA ls_item TYPE ty_s_item.
    DATA temp1 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
        DATA temp73 TYPE REF TO cl_abap_structdescr.
        DATA temp8 TYPE REF TO cl_abap_tabledescr.
        DATA lo_low TYPE REF TO cl_abap_datadescr.
            DATA temp74 TYPE REF TO cl_abap_elemdescr.
          DATA temp75 TYPE REF TO cl_abap_tabledescr.
          DATA lo_table LIKE temp75.
          DATA temp76 TYPE REF TO cl_abap_structdescr.
          DATA lo_line LIKE temp76.

    ls_item-kind       = cs_kind-select.
    IF mv_preview = abap_false.
      ls_item-name = name_get( val ).
    ENDIF.
    ls_item-required     = obligatory.
    ls_item-modif_id     = modif_id.
    ls_item-no_display   = no_display.

    temp1 = boolc( no_intervals = abap_true OR mv_block_no_int > 0 ).
    ls_item-no_intervals = temp1.
    ls_item-no_extension = no_extension.
    ls_item-memory_id    = to_upper( memory_id ).
    ls_item-visible_len  = visible_length.
    ls_item-matchcode    = to_upper( matchcode ).
    ls_item-entity       = to_upper( value_help_entity ).
    ls_item-entity_elem  = to_upper( value_help_element ).
    ls_item-lines        = lines( val ).
    ls_item-value        = z2ui5_cl_cgui_context=>range_to_text( val ).

    temp2 = boolc( value_help = abap_true OR ls_item-matchcode IS NOT INITIAL OR ls_item-entity IS NOT INITIAL ).
    ls_item-value_help   = temp2.
    IF ls_item-value_help = abap_false.
      ls_item-value_help = value_help_check( val ).
    ENDIF.
    ls_item-control = cs_control-input.
    TRY.


        temp8 ?= cl_abap_typedescr=>describe_by_data( val ).
        temp73 ?= temp8->get_table_line_type( ).

        lo_low = temp73->get_component_type( `LOW` ).
        CASE lo_low->type_kind.
          WHEN cl_abap_typedescr=>typekind_date.
            ls_item-control = cs_control-date.
          WHEN cl_abap_typedescr=>typekind_time.
            ls_item-control = cs_control-time.
          WHEN cl_abap_typedescr=>typekind_char OR cl_abap_typedescr=>typekind_num.

            temp74 ?= lo_low.
            ls_item-max_length = temp74->output_length.
        ENDCASE.
        ls_item-upper = upper_check( descr      = lo_low
                                     lower_case = lower_case ).
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

    IF ls_item-name IS INITIAL AND mv_preview = abap_false.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = `SELECT_OPTION_NOT_AN_ATTRIBUTE - pass a PUBLIC attribute of the app`.
    ENDIF.
    help_check( EXPORTING val  = val
                          help = help
                          own  = help_request
                CHANGING  item = ls_item ).

    ls_item-text = text.
    IF ls_item-text IS INITIAL.
      TRY.

          temp75 ?= cl_abap_typedescr=>describe_by_data( val ).

          lo_table = temp75.

          temp76 ?= lo_table->get_table_line_type( ).

          lo_line = temp76.
          ls_item-text = z2ui5_cl_cgui_context=>rtti_get_label_by_descr( lo_line->get_component_type( `LOW` ) ).
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDIF.
    IF ls_item-text IS INITIAL.
      ls_item-text = ls_item-name.
    ENDIF.

    INSERT ls_item INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD comment.

    DATA temp77 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp77.
    temp77-kind = cs_kind-comment.
    temp77-text = text.
    temp77-modif_id = modif_id.
    temp77-for_field = to_upper( for_field ).
    INSERT temp77 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD custom_control.

    DATA temp78 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp78.
    temp78-kind = cs_kind-custom.
    temp78-name = to_upper( condense( name ) ).
    INSERT temp78 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD set_gui.

    mi_gui = gui.

  ENDMETHOD.

  METHOD button.

    DATA temp79 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item.
    CLEAR temp79.
    temp79-kind = cs_kind-button.
    temp79-text = text.
    temp79-event = event.
    temp79-icon = icon.
    temp79-modif_id = modif_id.
    INSERT temp79 INTO TABLE mt_item.
    result = me.

  ENDMETHOD.

  METHOD loop_at_screen.

    DATA temp80 LIKE LINE OF mt_item.
    DATA lr_item LIKE REF TO temp80.
      DATA temp81 TYPE z2ui5_cl_cgui_selscreen=>ty_s_screen.
      DATA temp3 TYPE xsdboolean.
      DATA temp4 TYPE xsdboolean.
    LOOP AT mt_item REFERENCE INTO lr_item
         WHERE kind <> cs_kind-block_begin
           AND kind <> cs_kind-block_end
           AND kind <> cs_kind-line_begin
           AND kind <> cs_kind-line_end
           AND kind <> cs_kind-skip
           AND kind <> cs_kind-uline
           AND kind <> cs_kind-tabbed
           AND kind <> cs_kind-tab
           AND kind <> cs_kind-tabbed_end
           AND no_display = abap_false.

      CLEAR temp81.
      temp81-id = sy-tabix.
      temp81-name = lr_item->name.
      temp81-group1 = lr_item->modif_id.

      temp3 = boolc( lr_item->inactive = abap_false ).
      temp81-active = temp3.

      temp4 = boolc( lr_item->read_only = abap_false ).
      temp81-input = temp4.
      temp81-required = lr_item->required.
      temp81-invisible = lr_item->invisible.
      temp81-intensified = lr_item->intensified.
      temp81-recommended = lr_item->recommended.
      temp81-length = lr_item->visible_len.
      INSERT temp81 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD modify_screen.

    DATA lr_item TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_item.
    DATA temp5 TYPE xsdboolean.
    DATA temp6 TYPE xsdboolean.
    READ TABLE mt_item REFERENCE INTO lr_item INDEX screen-id.
    IF sy-subrc <> 0 OR lr_item->no_display = abap_true.
      RETURN.
    ENDIF.


    temp5 = boolc( screen-active = abap_false ).
    lr_item->inactive  = temp5.

    temp6 = boolc( screen-input = abap_false ).
    lr_item->read_only = temp6.
    lr_item->required  = screen-required.
    lr_item->invisible = screen-invisible.
    " SCREEN-REQUIRED = 2: marked as required, not checked
    lr_item->recommended = screen-recommended.
    lr_item->intensified = screen-intensified.
    lr_item->visible_len = screen-length.

  ENDMETHOD.

  METHOD set_value_state.

    DATA lv_name TYPE string.
    DATA temp82 LIKE LINE OF mt_item.
    DATA lr_item LIKE REF TO temp82.
    lv_name = to_upper( name ).



    LOOP AT mt_item REFERENCE INTO lr_item WHERE name = lv_name.
      lr_item->state      = state.
      lr_item->state_text = text.
    ENDLOOP.

  ENDMETHOD.

  METHOD field_id.

    result = |cgui_f_{ to_lower( name ) }|.

  ENDMETHOD.

  METHOD get_fields.

    DATA lv_block TYPE string.

    DATA temp83 LIKE LINE OF mt_item.
    DATA lr_item LIKE REF TO temp83.
      DATA temp84 TYPE z2ui5_cl_cgui_selscreen=>ty_s_field.
      DATA temp7 TYPE xsdboolean.
      DATA temp8 TYPE xsdboolean.
      DATA temp9 TYPE z2ui5_cl_cgui_selscreen=>ty_s_field-kind.
      DATA temp10 TYPE z2ui5_cl_cgui_selscreen=>ty_s_field-group.
    LOOP AT mt_item REFERENCE INTO lr_item.
      CASE lr_item->kind.
        WHEN cs_kind-block_begin.
          lv_block = lr_item->group.
          CONTINUE.
        WHEN cs_kind-block_end.
          CLEAR lv_block.
          CONTINUE.
      ENDCASE.
      IF lr_item->name IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR temp84.
      temp84-name = lr_item->name.
      temp84-text = lr_item->text.

      temp7 = boolc( lr_item->required = abap_true AND lr_item->inactive = abap_false AND lr_item->read_only = abap_false AND lr_item->no_display = abap_false ).
      temp84-obligatory = temp7.

      temp8 = boolc( lr_item->inactive = abap_false AND lr_item->no_display = abap_false ).
      temp84-shown = temp8.

      IF lr_item->kind = cs_kind-select.
        temp9 = cs_field_kind-select_option.
      ELSE.
        temp9 = cs_field_kind-parameter.
      ENDIF.
      temp84-kind = temp9.
      temp84-upper = lr_item->upper.
      temp84-no_display = lr_item->no_display.
      temp84-memory_id = lr_item->memory_id.
      temp84-value_help = lr_item->value_help.
      temp84-no_intervals = lr_item->no_intervals.
      temp84-max_length = lr_item->max_length.
      temp84-value_check = lr_item->value_check.
      temp84-help = lr_item->help.
      temp84-dtel = lr_item->dtel.
      temp84-block = lv_block.

      IF lr_item->kind = cs_kind-radiobutton.
        temp10 = lr_item->group.
      ELSE.
        CLEAR temp10.
      ENDIF.
      temp84-group = temp10.
      temp84-matchcode = lr_item->matchcode.
      temp84-entity = lr_item->entity.
      temp84-entity_elem = lr_item->entity_elem.
      INSERT temp84 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD item_create.
      DATA temp85 TYPE string.
      DATA bind LIKE temp85.
      DATA temp86 TYPE z2ui5_cl_cgui_selscreen=>ty_s_item-bind.

    result-kind = kind.
    IF mv_preview = abap_false.
      result-name = name_get( val ).
      " the binding of the attribute - none without a client

      IF client IS BOUND.
        temp85 = client->_bind( val ).
      ELSE.
        CLEAR temp85.
      ENDIF.

      bind = temp85.
      result-bind = bind.
    ELSEIF z2ui5_cl_cgui_context=>rtti_check_boolean( val ) = abap_true.
      " a preview shows a flag as it is - every other field empty

      IF val = abap_true.
        temp86 = `true`.
      ELSE.
        temp86 = `false`.
      ENDIF.
      result-bind = temp86.
    ENDIF.

    result-text = text.
    IF result-text IS INITIAL.
      result-text = z2ui5_cl_cgui_context=>rtti_get_label( val ).
    ENDIF.
    IF result-text IS INITIAL.
      result-text = result-name.
    ENDIF.

  ENDMETHOD.

  METHOD value_help_check.

    IF mv_value_help_auto = abap_false.
      RETURN.
    ENDIF.

    result = z2ui5_cl_cgui_context=>rtti_check_value_help( z2ui5_cl_cgui_context=>rtti_get_value_descr( val ) ).

  ENDMETHOD.

  METHOD name_get.

    IF mo_app IS NOT BOUND.
      RETURN.
    ENDIF.
    result = z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                       val = val ).

  ENDMETHOD.

  METHOD control_by_type.

    IF z2ui5_cl_cgui_context=>rtti_check_boolean( val ) = abap_true.
      result = cs_control-checkbox.
      RETURN.
    ENDIF.

    CASE z2ui5_cl_cgui_context=>rtti_get_type_kind( val ).
      WHEN cl_abap_typedescr=>typekind_date.
        result = cs_control-date.
      WHEN cl_abap_typedescr=>typekind_time.
        result = cs_control-time.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float.
        result = cs_control-number.
      WHEN OTHERS.
        result = cs_control-input.
    ENDCASE.

  ENDMETHOD.

  METHOD render.

    " blocks and lines are opened with their first visible field, so that
    " a block whose fields are all hidden leaves no empty frame behind
    " tabs: the fields of a tab are rendered into its IconTabFilter, the
    " container the forms are opened in
    DATA lo_form TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_line TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_in_block TYPE abap_bool.
    DATA lv_block_title TYPE string.
    DATA lv_in_line TYPE abap_bool.
    DATA lv_line_text TYPE string.
    DATA lo_container TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_tab_items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_tabbed TYPE i.
    DATA lv_tab TYPE i.
    " the tabs of the tabstrip of a dynpro: function code, area, its filter
    TYPES:
      BEGIN OF ty_s_strip,
        fcode TYPE string,
        area  TYPE string,
        node  TYPE REF TO z2ui5_cl_ui5_view_builder,
      END OF ty_s_strip.
    TYPES temp3 TYPE STANDARD TABLE OF ty_s_strip WITH DEFAULT KEY.
DATA lt_strip TYPE temp3.
    DATA lv_active TYPE string.
    DATA temp87 LIKE LINE OF mt_item.
    DATA lr_item LIKE REF TO temp87.
      DATA lv_item_index LIKE sy-tabix.
          DATA lo_bar TYPE REF TO z2ui5_cl_ui5_view_builder.
              DATA ls_first LIKE LINE OF mt_item.
            DATA lr_tab_bind TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_s_tab_bind.
          DATA temp88 TYPE string.
          DATA temp89 TYPE ty_s_strip.
          DATA lo_area LIKE lo_container.
          DATA ls_strip TYPE ty_s_strip.
          DATA ls_tc TYPE z2ui5_cl_cgui_selscreen=>ty_s_tc.

    lo_container = node.



    LOOP AT mt_item REFERENCE INTO lr_item.
      " read first - every ele( ) of the builder below appends and moves sy-tabix

      lv_item_index = sy-tabix.
      CASE lr_item->kind.

        WHEN cs_kind-block_begin.
          CLEAR: lo_form, lo_line, lv_in_line.
          lv_in_block = abap_true.
          lv_block_title = lr_item->text.

        WHEN cs_kind-block_end.
          CLEAR: lo_form, lo_line, lv_in_line, lv_in_block, lv_block_title.

        WHEN cs_kind-line_begin.
          CLEAR lo_line.
          lv_in_line = abap_true.
          lv_line_text = lr_item->text.

        WHEN cs_kind-line_end.
          CLEAR: lo_line, lv_in_line.

        WHEN cs_kind-tabbed.
          CLEAR: lo_form, lo_line, lv_in_line, lv_tab, lt_strip, lv_active.
          lv_tabbed = lv_tabbed + 1.

          lo_bar = node->ele( `IconTabBar`
              )->a( n = `expandable` b = abap_false
              )->a( n = `class`      v = `sapUiResponsiveContentPadding` ).
          IF lr_item->name IS NOT INITIAL.
            " the tabstrip of a dynpro: name-activetab, else its first tab;
            " a press is a function of the dynpro
            IF mi_gui IS BOUND.
              lv_active = to_upper( mi_gui->tabstrip_active( lr_item->name ) ).
            ENDIF.
            IF lv_active IS INITIAL.

              LOOP AT mt_item INTO ls_first FROM lv_item_index WHERE kind = cs_kind-tab.
                lv_active = ls_first-event.
                EXIT.
              ENDLOOP.
            ENDIF.
            lo_bar->a( n = `selectedKey` t = lv_active
                )->a( n = `select`      v = client->_event( val = cs_event-tab
                                                            arg = `${$source>/selectedKey}` ) ).
          ELSE.

            READ TABLE mt_tab_bind REFERENCE INTO lr_tab_bind WITH KEY index = lv_tabbed.
            IF sy-subrc = 0.
              lo_bar->a( n = `selectedKey` v = lr_tab_bind->bind ).
            ENDIF.
          ENDIF.
          lo_tab_items = lo_bar->ele( `items` ).
          lo_container = lo_tab_items.

        WHEN cs_kind-tab.
          CLEAR: lo_form, lo_line, lv_in_line.
          IF lo_tab_items IS NOT BOUND.
            CONTINUE.
          ENDIF.
          lv_tab = lv_tab + 1.

          IF lr_item->event IS NOT INITIAL.
            temp88 = lr_item->event.
          ELSE.
            temp88 = |TAB{ lv_tab }|.
          ENDIF.
          lo_container = lo_tab_items->ele( `IconTabFilter`
              )->a( n = `text` t = lr_item->text
              )->a( n = `key`  t = temp88 ).

          CLEAR temp89.
          temp89-fcode = lr_item->event.
          temp89-area = lr_item->group.
          temp89-node = lo_container.
          INSERT temp89 INTO TABLE lt_strip.

        WHEN cs_kind-subscreen.
          CLEAR: lo_form, lo_line, lv_in_line.
          " on the tab that shows the area - the selected one where tabs
          " share it, as the classic pages in the program

          lo_area = lo_container.

          READ TABLE lt_strip INTO ls_strip WITH KEY area = lr_item->name fcode = lv_active.
          IF sy-subrc <> 0.
            READ TABLE lt_strip INTO ls_strip WITH KEY area = lr_item->name.
          ENDIF.
          IF sy-subrc = 0.
            lo_area = ls_strip-node.
          ENDIF.
          IF mi_gui IS BOUND.
            mi_gui->subscreen_render( area = lr_item->name
                                      node = lo_area ).
          ENDIF.

        WHEN cs_kind-tabbed_end.
          CLEAR: lo_form, lo_line, lv_in_line, lo_tab_items.
          lo_container = node.

        WHEN cs_kind-custom.
          CLEAR: lo_form, lo_line, lv_in_line.
          IF mi_gui IS BOUND.
            mi_gui->custom_render( name = lr_item->name
                                   node = lo_container ).
          ENDIF.

        WHEN cs_kind-table.
          CLEAR: lo_form, lo_line, lv_in_line.

          READ TABLE mt_tc INTO ls_tc WITH KEY name = lr_item->name.
          IF mi_gui IS BOUND AND sy-subrc = 0.
            mi_gui->tablecontrol_render( name    = lr_item->name
                                         title   = lr_item->text
                                         columns = ls_tc-columns
                                         node    = lo_container ).
          ENDIF.

        WHEN cs_kind-uline.
          CLEAR: lo_form, lo_line, lv_in_line.
          lo_container->tag( `Toolbar`
              )->a( n = `height` v = `1px`
              )->a( n = `design` v = `Solid`
              )->a( n = `class`  v = `sapUiSmallMarginTopBottom` ).

        WHEN OTHERS.
          IF lr_item->inactive = abap_true OR lr_item->no_display = abap_true.
            CONTINUE.
          ENDIF.
          IF lo_form IS NOT BOUND.
            IF lv_in_block = abap_true AND lv_block_title IS NOT INITIAL.
              lo_form = form_open( node  = lo_container
                                   title = lv_block_title ).
              CLEAR lv_block_title.
            ELSE.
              lo_form = form_open( lo_container ).
            ENDIF.
          ENDIF.
          IF lr_item->kind = cs_kind-skip.
            DO lr_item->lines TIMES.
              lo_form->tag( `Label`
                  )->tag( `Text` ).
            ENDDO.
            CONTINUE.
          ENDIF.
          IF lv_in_line = abap_true AND lo_line IS NOT BOUND.
            lo_form->tag( `Label`
                )->a( n = `text` t = lv_line_text ).
            " the fields of one line - on a phone they wrap
            lo_line = lo_form->ele( `HBox`
                )->a( n = `wrap`       v = `Wrap`
                )->a( n = `alignItems` v = `Center` ).
          ENDIF.
          IF lo_line IS BOUND.
            render_control( node   = lo_line
                            item   = lr_item->*
                            inline = abap_true ).
            render_help( node = lo_line
                         item = lr_item->* ).
          ELSE.
            render_label( node = lo_form
                          item = lr_item->* ).
            render_control( node = lo_form
                            item = lr_item->* ).
            render_help( node = lo_form
                         item = lr_item->* ).
          ENDIF.

      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD help_check.
    DATA temp9 TYPE xsdboolean.

    IF help = abap_false OR mv_preview = abap_true OR client IS NOT BOUND.
      RETURN.
    ENDIF.
    item-dtel = z2ui5_cl_cgui_context=>rtti_get_dtel_name( val ).

    temp9 = boolc( own = abap_true OR z2ui5_cl_cgui_context=>dtel_docu_check( item-dtel ) = abap_true ).
    item-help = temp9.

  ENDMETHOD.

  METHOD render_help.
    DATA temp90 TYPE string.

    IF item-help = abap_false OR item-name IS INITIAL.
      RETURN.
    ENDIF.

    temp90 = 'Help (F1)'(003).
    node->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://sys-help`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` t = temp90
        )->a( n = `press`   v = client->_event( val = cs_event-help_request
                                                arg = item-name ) ).

  ENDMETHOD.

  METHOD function_key.
    DATA temp91 TYPE z2ui5_cl_cgui_selscreen=>ty_s_function_key.

    IF number < 1 OR number > 5.
      result = me.
      RETURN.
    ENDIF.
    DELETE mt_function_key WHERE number = number.

    CLEAR temp91.
    temp91-number = number.
    temp91-ucomm = |FC0{ number }|.
    temp91-text = text.
    temp91-icon = icon.
    INSERT temp91 INTO TABLE mt_function_key.
    SORT mt_function_key BY number.
    result = me.

  ENDMETHOD.

  METHOD get_function_keys.

    result = mt_function_key.

  ENDMETHOD.

  METHOD form_open.

    result = node->ele( n = `SimpleForm` ns = `form`
        )->a( n = `xmlns:form`   v = `sap.ui.layout.form`
        )->a( n = `editable`     v = `true`
        )->a( n = `layout`       v = `ResponsiveGridLayout`
        )->a( n = `labelSpanXL`  v = `3`
        )->a( n = `labelSpanL`   v = `3`
        )->a( n = `labelSpanM`   v = `3`
        )->a( n = `emptySpanXL`  v = `4`
        )->a( n = `emptySpanL`   v = `4`
        )->a( n = `emptySpanM`   v = `2`
        )->a( n = `columnsXL`    v = `1`
        )->a( n = `columnsL`     v = `1`
        )->a( n = `columnsM`     v = `1` ).

    IF title IS NOT INITIAL.
      result->a( n = `title` t = title ).
    ENDIF.

  ENDMETHOD.

  METHOD render_label.

    DATA lv_text TYPE string.
    DATA temp10 TYPE xsdboolean.

    CASE item-kind.
      WHEN cs_kind-parameter.
        IF item-control <> cs_control-checkbox.
          lv_text = item-text.
        ENDIF.
      WHEN cs_kind-select.
        lv_text = item-text.
    ENDCASE.


    temp10 = boolc( item-required = abap_true OR item-recommended = abap_true ).
    node->tag( `Label`
        )->a( n = `text`     t = lv_text
        )->a( n = `required` b = temp10 ).
    IF item-intensified = abap_true.
      node->a( n = `design` v = `Bold` ).
    ENDIF.

  ENDMETHOD.

  METHOD render_control.
      DATA temp92 TYPE string.
      DATA temp11 TYPE xsdboolean.
        DATA temp12 TYPE xsdboolean.
        DATA lv_ucomm TYPE string.
          DATA temp93 TYPE string.
        DATA temp13 TYPE xsdboolean.

    IF inline = abap_true AND ( item-kind = cs_kind-select
        OR ( item-kind = cs_kind-parameter AND item-control <> cs_control-checkbox ) ).

      IF item-intensified = abap_true.
        temp92 = `Bold`.
      ELSE.
        temp92 = `Standard`.
      ENDIF.

      temp11 = boolc( item-required = abap_true OR item-recommended = abap_true ).
      node->tag( `Label`
          )->a( n = `text`     t = item-text
          )->a( n = `required` b = temp11
          )->a( n = `design`   v = temp92
          )->a( n = `class`    v = `sapUiSmallMarginBegin sapUiTinyMarginEnd` ).
    ENDIF.

    CASE item-kind.

      WHEN cs_kind-parameter.
        render_parameter( node = node
                          item = item ).

      WHEN cs_kind-select.
        render_select_option( node = node
                              item = item ).

      WHEN cs_kind-radiobutton.

        temp12 = boolc( item-read_only = abap_false ).
        node->tag( `RadioButton`
            )->a( n = `text`      t = item-text
            )->a( n = `groupName` t = item-group
            )->a( n = `selected`  v = item-bind
            )->a( n = `editable`  b = temp12 ).
        " only the buttons not selected now raise the user command: UI5 fires
        " select at the button it deselects before that button's value has
        " reached the model, and that roundtrip would carry two selected
        " buttons. The view is rendered anew after every roundtrip, so the
        " wiring follows the selection

        lv_ucomm = group_user_command( item-group ).
        IF lv_ucomm IS NOT INITIAL AND item-selected = abap_false.
          node->a( n = `select` v = client->_event( lv_ucomm ) ).
        ENDIF.

      WHEN cs_kind-comment.
        " COMMENT ... FOR FIELD - the label of the field
        IF item-for_field IS NOT INITIAL OR item-intensified = abap_true.

          IF item-intensified = abap_true.
            temp93 = `Bold`.
          ELSE.
            temp93 = `Standard`.
          ENDIF.
          node->tag( `Label`
              )->a( n = `text`   t = item-text
              )->a( n = `design` v = temp93 ).
          IF item-for_field IS NOT INITIAL.
            node->a( n = `labelFor` v = field_id( item-for_field ) ).
          ENDIF.
        ELSE.
          node->tag( `Text`
              )->a( n = `text` t = item-text ).
        ENDIF.

      WHEN cs_kind-button.

        temp13 = boolc( item-read_only = abap_false ).
        node->tag( `Button`
            )->a( n = `text`    t = item-text
            )->a( n = `icon`    v = item-icon
            )->a( n = `enabled` b = temp13
            )->a( n = `press`   v = client->_event( item-event ) ).

    ENDCASE.

  ENDMETHOD.

  METHOD render_parameter.
        DATA temp14 TYPE xsdboolean.
        DATA temp15 TYPE xsdboolean.
        DATA temp16 TYPE xsdboolean.
        DATA lo_input TYPE REF TO z2ui5_cl_ui5_view_builder.
        DATA temp17 TYPE xsdboolean.
        DATA ls_history TYPE z2ui5_cl_cgui_selscreen=>ty_s_history.
          DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
          DATA lv_value LIKE LINE OF ls_history-values.

    CASE item-control.

      WHEN cs_control-checkbox.

        temp14 = boolc( item-read_only = abap_false ).
        node->tag( `CheckBox`
            )->a( n = `text`     t = item-text
            )->a( n = `selected` v = item-bind
            )->a( n = `editable` b = temp14 ).
        render_id( node = node
                   item = item ).
        IF item-user_command IS NOT INITIAL.
          node->a( n = `select` v = client->_event( item-user_command ) ).
        ENDIF.

      WHEN cs_control-date.

        temp15 = boolc( item-read_only = abap_false ).
        node->tag( `DatePicker`
            )->a( n = `value`         v = item-bind
            )->a( n = `valueFormat`   v = `yyyy-MM-dd`
            )->a( n = `displayFormat` v = `medium`
            )->a( n = `required`      b = item-required
            )->a( n = `editable`      b = temp15 ).
        render_id( node = node
                   item = item ).
        render_state( node = node
                      item = item ).

      WHEN cs_control-time.

        temp16 = boolc( item-read_only = abap_false ).
        node->tag( `TimePicker`
            )->a( n = `value`         v = item-bind
            )->a( n = `valueFormat`   v = `HH:mm:ss`
            )->a( n = `displayFormat` v = `HH:mm:ss`
            )->a( n = `required`      b = item-required
            )->a( n = `editable`      b = temp16 ).
        render_id( node = node
                   item = item ).
        render_state( node = node
                      item = item ).

      WHEN cs_control-listbox.
        render_listbox( node = node
                        item = item ).

      WHEN OTHERS.
        " ele( ): the input itself - its suggestions are children of it


        temp17 = boolc( item-read_only = abap_false ).
        lo_input = node->ele( `Input`
            )->a( n = `value`    v = item-bind
            )->a( n = `required` b = item-required
            )->a( n = `editable` b = temp17 ).
        render_id( node = node
                   item = item ).
        render_state( node = node
                      item = item ).
        IF item-control = cs_control-number.
          node->a( n = `type` v = `Number` ).
        ELSEIF item-invisible = abap_true.
          node->a( n = `type` v = `Password` ).
        ENDIF.
        IF item-max_length > 0.
          node->a( n = `maxLength` v = |{ item-max_length }| ).
        ENDIF.
        IF item-visible_len > 0.
          node->a( n = `width` v = z2ui5_cl_cgui_list=>width_of( item-visible_len + 4 ) ).
        ENDIF.
        IF item-value_help = abap_true.
          node->a( n = `showValueHelp`    b = abap_true
              )->a( n = `valueHelpRequest` v = client->_event( val = cs_event-value_request
                                                               arg = item-name ) ).
        ENDIF.
        " the last entries of the field - suggested from its first character

        READ TABLE mt_history INTO ls_history WITH KEY name = item-name.
        IF sy-subrc = 0 AND item-invisible = abap_false AND item-read_only = abap_false.
          node->a( n = `xmlns:core`     v = `sap.ui.core` ).
          node->a( n = `showSuggestion` b = abap_true ).

          lo_items = lo_input->ele( `suggestionItems` ).

          LOOP AT ls_history-values INTO lv_value.
            lo_items->tag( n = `Item` ns = `core`
                )->a( n = `key`  t = lv_value
                )->a( n = `text` t = lv_value ).
          ENDLOOP.
        ENDIF.

    ENDCASE.

  ENDMETHOD.

  METHOD render_listbox.

    " every attribute before the first item: a( ) reaches the Select only
    " while it has no children
    DATA lo_select TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp18 TYPE xsdboolean.
    DATA lo_items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp94 TYPE z2ui5_cl_cgui_selscreen=>ty_t_value.
    DATA temp11 LIKE LINE OF temp94.
    DATA lr_value LIKE REF TO temp11.
    temp18 = boolc( item-read_only = abap_false ).
    lo_select = node->ele( `Select`
        )->a( n = `xmlns:core`     v = `sap.ui.core`
        )->a( n = `selectedKey`    v = item-bind
        )->a( n = `forceSelection` b = abap_false
        )->a( n = `editable`       b = temp18 ).
    " no required: Select has it from UI5 1.74 on, the floor is 1.71 - the
    " label marks an obligatory list box, the backend checks it
    render_id( node = lo_select
               item = item ).
    render_state( node = lo_select
                  item = item ).
    IF item-visible_len > 0.
      lo_select->a( n = `width` v = z2ui5_cl_cgui_list=>width_of( item-visible_len + 6 ) ).
    ENDIF.
    IF item-user_command IS NOT INITIAL.
      lo_select->a( n = `change` v = client->_event( item-user_command ) ).
    ENDIF.

    " a blank entry first, as the classic listbox has one

    lo_items = lo_select->ele( `items` ).
    lo_items->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` v = `` ).

    temp94 = listbox_values( item ).


    LOOP AT temp94 REFERENCE INTO lr_value.
      lo_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  t = lr_value->key
          )->a( n = `text` t = lr_value->text ).
    ENDLOOP.

  ENDMETHOD.

  METHOD render_select_option.

    " without a value help F4 is the range popup; with one, F4 picks values
    " and the button beside the field - the classic multiple selection -
    " opens the range popup
    DATA lv_event TYPE string VALUE cs_event-select_option.
    DATA lo_box   TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_input TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp19 TYPE xsdboolean.
    DATA temp20 TYPE xsdboolean.

    IF item-low_bind IS NOT INITIAL.
      render_range_input( node = node
                          item = item ).
      RETURN.
    ENDIF.

    IF item-value_help = abap_true.
      lv_event = cs_event-value_request.
      " field and button share the row the form gives the field
      lo_box = node->ele( `HBox`
          )->a( n = `width`      v = `100%`
          )->a( n = `alignItems` v = `Center` ).
      lo_input = lo_box->ele( `Input` ).
    ELSE.
      " tag( ) stays on node - the a( ) below lands on the Input all the same
      lo_input = node->tag( `Input` ).
    ENDIF.


    temp19 = boolc( item-read_only = abap_false ).
    lo_input->a( n = `value`            t = item-value
        )->a( n = `required`         b = item-required
        )->a( n = `editable`         b = temp19
        )->a( n = `showValueHelp`    b = abap_true
        )->a( n = `valueHelpOnly`    b = abap_true
        )->a( n = `valueHelpRequest` v = client->_event( val = lv_event
                                                         arg = item-name ) ).
    render_id( node = lo_input
               item = item ).
    render_state( node = lo_input
                  item = item ).

    IF item-value_help = abap_false.
      RETURN.
    ENDIF.

    lo_input->ele( `layoutData`
        )->tag( `FlexItemData`
        )->a( n = `growFactor` v = `1` ).


    temp20 = boolc( item-read_only = abap_false ).
    lo_box->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://filter`
        )->a( n = `tooltip` v = `Multiple selection`
        )->a( n = `enabled` b = temp20
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `press`   v = client->_event( val = cs_event-select_option
                                                arg = item-name ) ).

  ENDMETHOD.

  METHOD render_range_input.

    " the classic select-option: from, to and the button of the multiple
    " selection - emphasized while the range holds more than its first line
    " on a phone from and to wrap onto lines of their own
    DATA lo_box TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp95 TYPE string.
      DATA temp96 TYPE string.
      DATA temp12 TYPE string.
      DATA temp21 TYPE xsdboolean.
    lo_box = node->ele( `HBox`
        )->a( n = `width`      v = `100%`
        )->a( n = `wrap`       v = `Wrap`
        )->a( n = `alignItems` v = `Center` ).

    render_range_field( node = lo_box
                        item = item
                        bind = item-low_bind
                        id   = field_id( item-name )
                        help = item-value_help ).

    IF item-no_intervals = abap_false.

      temp95 = 'to'(001).
      lo_box->tag( `Text`
          )->a( n = `text`  t = temp95
          )->a( n = `class` v = `sapUiTinyMarginBeginEnd` ).
      render_range_field( node = lo_box
                          item = item
                          bind = item-high_bind
                          id   = |{ field_id( item-name ) }_high|
                          help = item-value_help
                          part = cs_part-high ).
    ENDIF.

    IF item-no_extension = abap_false.

      temp96 = 'Multiple selection'(002).

      IF item-lines > 1.
        temp12 = `Emphasized`.
      ELSE.
        temp12 = `Default`.
      ENDIF.

      temp21 = boolc( item-read_only = abap_false ).
      lo_box->tag( `Button`
          )->a( n = `icon`    v = `sap-icon://filter`
          )->a( n = `type`    v = temp12
          )->a( n = `tooltip` t = temp96
          )->a( n = `enabled` b = temp21
          )->a( n = `class`   v = `sapUiTinyMarginBegin`
          )->a( n = `press`   v = client->_event( val = cs_event-select_option
                                                  arg = item-name ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_range_field.

    DATA lo_field TYPE REF TO z2ui5_cl_ui5_view_builder.
          DATA temp97 TYPE string_table.
          DATA temp13 TYPE string_table.
          DATA temp4 TYPE string_table.
    DATA temp22 TYPE xsdboolean.
    DATA temp1 TYPE xsdboolean.

    " the buffer holds the values as the range does, as text - yyyyMMdd
    " for a date and HHmmss for a time
    CASE item-control.
      WHEN cs_control-date.
        lo_field = node->ele( `DatePicker`
            )->a( n = `value`         v = bind
            )->a( n = `valueFormat`   v = `yyyyMMdd`
            )->a( n = `displayFormat` v = `medium` ).
      WHEN cs_control-time.
        lo_field = node->ele( `TimePicker`
            )->a( n = `value`         v = bind
            )->a( n = `valueFormat`   v = `HHmmss`
            )->a( n = `displayFormat` v = `HH:mm:ss` ).
      WHEN OTHERS.
        lo_field = node->ele( `Input`
            )->a( n = `value` v = bind ).
        IF item-max_length > 0.
          lo_field->a( n = `maxLength` v = |{ item-max_length }| ).
        ENDIF.
        IF help = abap_true.
          " the event names the field - and HIGH for the upper limit

          CLEAR temp97.
          INSERT item-name INTO TABLE temp97.

          CLEAR temp13.
          INSERT item-name INTO TABLE temp13.
          INSERT part INTO TABLE temp13.

          IF part IS INITIAL.
            temp4 = temp97.
          ELSE.
            temp4 = temp13.
          ENDIF.
          lo_field->a( n = `showValueHelp`    b = abap_true
              )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-value_request
                                                               t_arg = temp4 ) ).
        ENDIF.
    ENDCASE.


    temp22 = boolc( item-required = abap_true AND id = field_id( item-name ) ).

    temp1 = boolc( item-read_only = abap_false ).
    lo_field->a( n = `id`       t = id
        )->a( n = `required` b = temp22
        )->a( n = `editable` b = temp1 ).
    IF id = field_id( item-name ).
      render_state( node = lo_field
                    item = item ).
    ENDIF.

    " VISIBLE LENGTH: the field keeps its width
    IF item-visible_len > 0.
      lo_field->a( n = `width` v = z2ui5_cl_cgui_list=>width_of( item-visible_len + 4 ) ).
      RETURN.
    ENDIF.
    lo_field->ele( `layoutData`
        )->tag( `FlexItemData`
        )->a( n = `growFactor` v = `1`
        )->a( n = `baseSize`   v = `8rem` ).

  ENDMETHOD.

  METHOD render_id.

    IF item-name IS NOT INITIAL.
      node->a( n = `id` v = field_id( item-name ) ).
    ENDIF.

  ENDMETHOD.

  METHOD render_state.

    IF item-state IS INITIAL.
      RETURN.
    ENDIF.

    node->a( n = `valueState` t = item-state ).
    IF item-state_text IS NOT INITIAL.
      node->a( n = `valueStateText` t = item-state_text ).
    ENDIF.

  ENDMETHOD.

  METHOD group_user_command.

    DATA temp99 LIKE LINE OF mt_item.
    DATA lr_item LIKE REF TO temp99.
    LOOP AT mt_item REFERENCE INTO lr_item
         WHERE kind = cs_kind-radiobutton
           AND group = group
           AND user_command IS NOT INITIAL.
      result = lr_item->user_command.
      RETURN.
    ENDLOOP.

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
        )->a( n = `title` t = title ).

    render( page ).

    result = view->stringify( ).

  ENDMETHOD.

ENDCLASS.
