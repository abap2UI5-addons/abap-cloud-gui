"! Classic list output - WRITE, NEW-LINE, SKIP, ULINE, NEW-PAGE - rendered
"! with z2ui5_cl_ui5_view_builder. The list only collects what was written;
"! it binds nothing, so it can be kept as an attribute of the app between
"! roundtrips (it is serializable) and rendered again at any time:
"!   DATA(list) = z2ui5_cl_cgui_list=>factory( ).
"!   list->write( `Flights` )->new_line( )->uline( ).
"!   LOOP AT mt_flight INTO DATA(ls_flight).
"!     list->write( val = ls_flight-carrid hotspot = abap_true hide = ls_flight-connid
"!         )->write( ls_flight-fldate
"!         )->new_line( ).
"!   ENDLOOP.
"! A hotspot raises cs_event-line_selection with the line number as first
"! and the HIDE value as second event argument - AT LINE-SELECTION.
"! write( input = abap_true ) and write_as_checkbox( input = abap_true ) are
"! input fields: get_inputs( ) / set_inputs( ) carry their values through a
"! table the app binds, read_value( ) and modify_line( ) are READ LINE and
"! MODIFY LINE. footer_begin( ) / footer_end( ) frame END-OF-PAGE, shown at
"! the end of every page; set_line_count( ) is LINE-COUNT - a new page after
"! so many lines. &PAGE& in a header or footer is the page number.
CLASS z2ui5_cl_cgui_list DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    CONSTANTS:
      BEGIN OF cs_event,
        line_selection TYPE string VALUE `CGUI_LINE_SELECTION`,
      END OF cs_event.

    CONSTANTS:
      "! the colors of FORMAT COLOR, as UI5 value states
      BEGIN OF cs_color,
        none     TYPE string VALUE ``,
        positive TYPE string VALUE `Success`,
        negative TYPE string VALUE `Error`,
        total    TYPE string VALUE `Warning`,
        key      TYPE string VALUE `Information`,
      END OF cs_color.

    CONSTANTS:
      BEGIN OF cs_justify,
        left   TYPE string VALUE `LEFT`,
        right  TYPE string VALUE `RIGHT`,
        center TYPE string VALUE `CENTER`,
      END OF cs_justify.

    "! the page number in a header or footer
    CONSTANTS cv_page TYPE string VALUE `&PAGE&`.

    CONSTANTS:
      "! the date formats of WRITE ... DD/MM/YYYY etc. - as the classic
      "! additions: day and month in the order of the user's date format, the
      "! year with 2 or 4 digits, DDMMYY / MMDDYY without separators
      BEGIN OF cs_date_format,
        dd_mm_yy   TYPE string VALUE `DD/MM/YY`,
        mm_dd_yy   TYPE string VALUE `MM/DD/YY`,
        dd_mm_yyyy TYPE string VALUE `DD/MM/YYYY`,
        mm_dd_yyyy TYPE string VALUE `MM/DD/YYYY`,
        ddmmyy     TYPE string VALUE `DDMMYY`,
        mmddyy     TYPE string VALUE `MMDDYY`,
        yymmdd     TYPE string VALUE `YYMMDD`,
      END OF cs_date_format.

    TYPES:
      "! FORMAT - what WRITE takes when it is not told otherwise
      BEGIN OF ty_s_format,
        color       TYPE string,
        intensified TYPE abap_bool,
        inverse     TYPE abap_bool,
        hotspot     TYPE abap_bool,
        input       TYPE abap_bool,
      END OF ty_s_format.

    TYPES:
      BEGIN OF ty_s_item,
        line        TYPE i,
        kind        TYPE string,
        text        TYPE string,
        flag        TYPE abap_bool,
        color       TYPE string,
        hotspot     TYPE abap_bool,
        hide        TYPE string,
        pos         TYPE i,
        len         TYPE i,
        header      TYPE abap_bool,
        footer      TYPE abap_bool,
        intensified TYPE abap_bool,
        inverse     TYPE abap_bool,
        justify     TYPE string,
        input       TYPE abap_bool,
        id          TYPE i,
        no_gap      TYPE abap_bool,
        quickinfo   TYPE string,
        name        TYPE string,
        col         TYPE i,
        no_heading  TYPE abap_bool,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

    TYPES:
      "! the value of an input field of the list - bound by the app
      BEGIN OF ty_s_input,
        id    TYPE i,
        line  TYPE i,
        value TYPE string,
        flag  TYPE abap_bool,
      END OF ty_s_input.
    TYPES ty_t_input TYPE STANDARD TABLE OF ty_s_input WITH EMPTY KEY.

    TYPES:
      "! the bindings of an input field - its value and its flag, as the app
      "! binds its line of get_inputs( )
      BEGIN OF ty_s_input_bind,
        id    TYPE i,
        value TYPE string,
        flag  TYPE string,
      END OF ty_s_input_bind.
    TYPES ty_t_input_bind TYPE STANDARD TABLE OF ty_s_input_bind WITH EMPTY KEY.

    "! the width of chars characters of a list or screen - in em, 0.6 em a character
    "! (a CSSSize of UI5 has no unit ch)
    "! HIDE val as the text a line keeps - a structure component by
    "! component, separated by a tab (a string template takes no structure)
    CLASS-METHODS hide_text
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! the field of HIDE from the text of the clicked line - a structure
    "! component by component, as hide_text( ) wrote it
    CLASS-METHODS hide_restore
      IMPORTING
        hide TYPE string
      CHANGING
        val  TYPE any.

    CLASS-METHODS width_of
      IMPORTING
        chars         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS factory
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! WRITE val - dates and times in the user's format. val and hide are
    "! passed by value: `hide = sy-tabix` must keep the row it was written
    "! in, not whatever a later LOOP left in sy-tabix. pos and len are
    "! WRITE AT pos(len): the column (1-based) the value starts in and the
    "! characters it takes - columns line up over the lines of the list.
    "! The options of WRITE and FORMAT: intensified, inverse, no_zero,
    "! no_sign, currency (the decimals of the currency), unit, decimals,
    "! justify (cs_justify, within len) and input (INPUT ON)
    METHODS write
      IMPORTING
        VALUE(val)    TYPE any
        color         TYPE clike     DEFAULT cs_color-none
        hotspot       TYPE abap_bool DEFAULT abap_false
        VALUE(hide)   TYPE any       OPTIONAL
        pos           TYPE i         DEFAULT 0
        len           TYPE i         DEFAULT 0
        intensified   TYPE abap_bool DEFAULT abap_false
        inverse       TYPE abap_bool DEFAULT abap_false
        no_zero       TYPE abap_bool DEFAULT abap_false
        no_sign       TYPE abap_bool DEFAULT abap_false
        currency      TYPE clike     OPTIONAL
        unit          TYPE clike     OPTIONAL
        decimals      TYPE i         DEFAULT -1
        justify       TYPE clike     OPTIONAL
        input         TYPE abap_bool DEFAULT abap_false
        no_gap        TYPE abap_bool DEFAULT abap_false
        edit_mask     TYPE clike     OPTIONAL
        no_grouping   TYPE abap_bool DEFAULT abap_false
        round         TYPE i         DEFAULT 0
        date_format   TYPE clike     OPTIONAL
        time_zone     TYPE clike     OPTIONAL
        quickinfo     TYPE clike     OPTIONAL
        name          TYPE clike     OPTIONAL
        under         TYPE clike     OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! FORMAT COLOR / INTENSIFIED / INVERSE / HOTSPOT / INPUT - the defaults
    "! of the WRITEs that follow; what is not passed stays. reset is FORMAT
    "! RESET
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

    METHODS get_format
      RETURNING
        VALUE(result) TYPE ty_s_format.

    "! POSITION col - the next WRITE starts at column col
    METHODS position
      IMPORTING
        col           TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! RESERVE n LINES - a new page when fewer lines are left on this one
    "! (with LINE-COUNT)
    METHODS reserve
      IMPORTING
        lines         TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! SKIP TO LINE n - empty lines up to line n of the page
    METHODS skip_to_line
      IMPORTING
        line          TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! LINE-SIZE - the width of a ULINE and of the printout lines
    METHODS set_line_size
      IMPORTING
        val TYPE i.

    METHODS get_line_size
      RETURNING
        VALUE(result) TYPE i.

    "! SY-LINNO - the line written to now
    METHODS current_line
      RETURNING
        VALUE(result) TYPE i.

    "! SY-COLNO - the column the next WRITE starts at
    METHODS current_column
      RETURNING
        VALUE(result) TYPE i.

    "! SY-PAGNO - the page written to now
    METHODS current_page
      RETURNING
        VALUE(result) TYPE i.

    "! DESCRIBE LIST NUMBER OF LINES - the lines of the list
    METHODS describe_lines
      RETURNING
        VALUE(result) TYPE i.

    "! SY-LISEL - line as text, as it prints
    METHODS line_text
      IMPORTING
        line          TYPE i
      RETURNING
        VALUE(result) TYPE string.

    "! the item with id - the one clicked: GET CURSOR FIELD
    METHODS get_item_by_id
      IMPORTING
        id            TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_item.

    "! END-OF-PAGE: what is written up to footer_end( ) is the page footer,
    "! shown at the end of every page
    METHODS footer_begin.

    METHODS footer_end.

    "! LINE-COUNT - a new page after val lines of the list, 0 for none
    METHODS set_line_count
      IMPORTING
        val TYPE i.

    "! the number of pages of the list
    METHODS get_page_count
      RETURNING
        VALUE(result) TYPE i.

    "! the values of the input fields, for the app to bind
    METHODS get_inputs
      RETURNING
        VALUE(result) TYPE ty_t_input.

    "! take over what the user entered into the input fields
    METHODS set_inputs
      IMPORTING
        val TYPE ty_t_input.

    "! the bindings of the input fields when the app binds its lines of
    "! get_inputs( ) itself - render( ) takes them instead of binding inputs
    METHODS set_input_binds
      IMPORTING
        val TYPE ty_t_input_bind.

    "! READ LINE line FIELD VALUE - the value of the index-th field of the
    "! line, `X` or empty for a checkbox
    METHODS read_value
      IMPORTING
        line          TYPE i
        index         TYPE i DEFAULT 1
      RETURNING
        VALUE(result) TYPE string.

    "! the fields of a line - READ LINE
    METHODS read_line
      IMPORTING
        line          TYPE i
      RETURNING
        VALUE(result) TYPE ty_t_item.

    "! MODIFY LINE line FIELD VALUE - the value of the index-th field of the
    "! line, and its color when passed
    METHODS modify_line
      IMPORTING
        line  TYPE i
        index TYPE i     DEFAULT 1
        value TYPE any
        color TYPE clike OPTIONAL.

    "! TOP-OF-PAGE: what is written up to header_end( ) is the page header,
    "! shown above the list and again after every NEW-PAGE
    METHODS header_begin.

    METHODS header_end.

    "! does the list hold more than its page header
    METHODS has_content
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the lines from line from on as plain text, taken out of the list - the
    "! list goes on at from (cl_demo_output=>get( ) and clear( ))
    METHODS cut
      IMPORTING
        from          TYPE i
      RETURNING
        VALUE(result) TYPE string_table.

    "! the list as plain text lines - the spool output of a background run
    METHODS to_text
      RETURNING
        VALUE(result) TYPE string_table.

    "! HIDE val - the value travels with the current line: every text of the
    "! line is a hotspot raising cs_event-line_selection with val as hide
    METHODS hide
      IMPORTING
        VALUE(val)    TYPE any
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! WRITE val AS CHECKBOX - with input the user can change it
    METHODS write_as_checkbox
      IMPORTING
        val           TYPE abap_bool
        input         TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! WRITE val AS ICON - val is a UI5 icon, e.g. `sap-icon://accept`
    METHODS write_as_icon
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    METHODS new_line
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    METHODS skip
      IMPORTING
        val           TYPE i DEFAULT 1
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! ULINE - ULINE AT pos(len) with pos and len
    METHODS uline
      IMPORTING
        pos           TYPE i DEFAULT 0
        len           TYPE i DEFAULT 0
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! NEW-PAGE - with title, NO-HEADING (no TOP-OF-PAGE on the new page)
    "! and LINE-COUNT for the pages from here on
    METHODS new_page
      IMPORTING
        title         TYPE clike     OPTIONAL
        no_heading    TYPE abap_bool DEFAULT abap_false
        line_count    TYPE i         OPTIONAL
          PREFERRED PARAMETER title
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    "! drop everything written so far
    METHODS clear.

    METHODS get_items
      RETURNING
        VALUE(result) TYPE ty_t_item.

    "! the item behind line number val of a line selection event, the first
    "! hotspot of that line
    METHODS get_item_by_line
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_item.

    "! append the list to node, a container of an existing view whose
    "! default namespace is sap.m. inputs - the table of get_inputs( ) the
    "! input fields are bound to, a PUBLIC attribute of the app
    METHODS render
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        inputs TYPE ty_t_input OPTIONAL.

    "! the list as a complete view
    METHODS stringify
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
        title         TYPE clike DEFAULT `List`
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the list travels in the app's draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA mt_item TYPE ty_t_item.
    DATA mt_input_bind TYPE ty_t_input_bind.
    DATA mv_line TYPE i VALUE 1.
    DATA mv_header TYPE abap_bool.
    DATA mv_footer TYPE abap_bool.
    DATA mv_id TYPE i.
    DATA mv_line_count TYPE i.
    DATA mv_page_lines TYPE i.
    DATA mv_body_line TYPE i.
    DATA ms_format TYPE ty_s_format.
    DATA mv_col TYPE i.
    DATA mv_col_line TYPE i.
    DATA mv_next_pos TYPE i.
    DATA mv_line_size TYPE i.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF cs_kind,
        text     TYPE string VALUE `TEXT`,
        checkbox TYPE string VALUE `CHECKBOX`,
        icon     TYPE string VALUE `ICON`,
        skip     TYPE string VALUE `SKIP`,
        uline    TYPE string VALUE `ULINE`,
        page     TYPE string VALUE `PAGE`,
      END OF cs_kind.

    METHODS item_add
      IMPORTING
        val TYPE ty_s_item.

    METHODS render_item
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        item   TYPE ty_s_item
        inputs TYPE ty_t_input OPTIONAL.

    "! a text with QUICKINFO: the text in a box carrying the tooltip
    METHODS render_text_tooltip
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        item   TYPE ty_s_item
        inputs TYPE ty_t_input OPTIONAL.

    METHODS render_items
      IMPORTING
        node   TYPE REF TO z2ui5_cl_ui5_view_builder
        client TYPE REF TO z2ui5_if_client
        items  TYPE ty_t_item
        inputs TYPE ty_t_input OPTIONAL.

    "! the items in the order shown: header, body and footer per page, the
    "! page numbers filled in
    METHODS sequence
      RETURNING
        VALUE(result) TYPE ty_t_item.

    CLASS-METHODS page_copy
      IMPORTING
        items         TYPE ty_t_item
        page          TYPE i
      RETURNING
        VALUE(result) TYPE ty_t_item.

    CLASS-METHODS text_format
      IMPORTING
        val           TYPE any
        currency      TYPE clike
        unit          TYPE clike
        decimals      TYPE i
        no_zero       TYPE abap_bool
        no_sign       TYPE abap_bool
        edit_mask     TYPE clike     OPTIONAL
        no_grouping   TYPE abap_bool DEFAULT abap_false
        round         TYPE i         DEFAULT 0
        date_format   TYPE clike     OPTIONAL
        time_zone     TYPE clike     OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    "! the thousands separator of the user's number format
    CLASS-METHODS grouping_char
      RETURNING
        VALUE(result) TYPE string.

    "! the decimals of a currency as ISO 4217 has them - 2 for every
    "! currency but the ones with 0 or 3
    CLASS-METHODS currency_decimals
      IMPORTING
        currency      TYPE clike
      RETURNING
        VALUE(result) TYPE i.

    "! USING EDIT MASK mask - every _ takes the next character of the value,
    "! from the right after RR; ==ALPHA drops the leading zeros, the other
    "! conversion exits leave the value as it is
    CLASS-METHODS edit_mask_apply
      IMPORTING
        val           TYPE any
        mask          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the date val in format (cs_date_format) - day, month and year in
    "! that order, with the separator of the user's date format
    CLASS-METHODS date_text
      IMPORTING
        val           TYPE d
        format        TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the items as the lines they print as
    METHODS items_to_text
      IMPORTING
        items         TYPE ty_t_item
      RETURNING
        VALUE(result) TYPE string_table.

ENDCLASS.


CLASS z2ui5_cl_cgui_list IMPLEMENTATION.

  METHOD factory.

    result = NEW #( ).

  ENDMETHOD.

  METHOD write.

    DATA ls_item TYPE ty_s_item.

    " hide first: `hide = sy-tabix` is read before anything else can run a
    " LOOP - the transpiled runtime passes even a VALUE( ) of type any by
    " reference, and its RTTI is ABAP code that loops
    IF hide IS SUPPLIED.
      ls_item-hide = hide_text( hide ).
    ENDIF.
    ls_item-kind        = cs_kind-text.
    ls_item-text        = text_format( val         = val
                                       currency    = currency
                                       unit        = unit
                                       decimals    = decimals
                                       no_zero     = no_zero
                                       no_sign     = no_sign
                                       edit_mask   = edit_mask
                                       no_grouping = no_grouping
                                       round       = round
                                       date_format = date_format
                                       time_zone   = time_zone ).
    " FORMAT gives what is not passed
    ls_item-color       = COND #( WHEN color IS SUPPLIED THEN color ELSE ms_format-color ).
    ls_item-hotspot     = COND #( WHEN hotspot IS SUPPLIED THEN hotspot ELSE ms_format-hotspot ).
    ls_item-intensified = COND #( WHEN intensified IS SUPPLIED THEN intensified ELSE ms_format-intensified ).
    ls_item-inverse     = COND #( WHEN inverse IS SUPPLIED THEN inverse ELSE ms_format-inverse ).
    ls_item-input       = COND #( WHEN input IS SUPPLIED THEN input ELSE ms_format-input ).
    ls_item-pos         = pos.
    ls_item-len         = len.
    ls_item-justify     = to_upper( justify ).
    ls_item-no_gap      = no_gap.
    ls_item-quickinfo   = quickinfo.
    ls_item-name        = to_upper( name ).

    " WRITE UNDER g - the column g was written at
    IF under IS NOT INITIAL.
      DATA(lv_under) = to_upper( under ).
      LOOP AT mt_item INTO DATA(ls_under) WHERE name = lv_under.
        ls_item-pos = ls_under-col.
      ENDLOOP.
    ENDIF.

    item_add( ls_item ).

    result = me.

  ENDMETHOD.

  METHOD format.

    IF reset = abap_true.
      CLEAR ms_format.
    ENDIF.
    IF color IS SUPPLIED.
      ms_format-color = color.
    ENDIF.
    IF intensified IS SUPPLIED.
      ms_format-intensified = intensified.
    ENDIF.
    IF inverse IS SUPPLIED.
      ms_format-inverse = inverse.
    ENDIF.
    IF hotspot IS SUPPLIED.
      ms_format-hotspot = hotspot.
    ENDIF.
    IF input IS SUPPLIED.
      ms_format-input = input.
    ENDIF.
    result = me.

  ENDMETHOD.

  METHOD get_format.

    result = ms_format.

  ENDMETHOD.

  METHOD position.

    mv_next_pos = nmax( val1 = 1 val2 = col ).
    result = me.

  ENDMETHOD.

  METHOD reserve.

    result = me.
    IF mv_line_count <= 0 OR lines <= 0.
      RETURN.
    ENDIF.
    " the lines the page holds already - the current one counts when it has
    " content
    IF mv_line_count - mv_page_lines < lines.
      new_page( ).
    ENDIF.

  ENDMETHOD.

  METHOD skip_to_line.

    result = me.
    IF line_exists( mt_item[ line = mv_line ] ).
      new_line( ).
    ENDIF.
    DATA(lv_gap) = line - 1 - mv_page_lines.
    IF lv_gap > 0.
      skip( lv_gap ).
    ENDIF.

  ENDMETHOD.

  METHOD set_line_size.

    mv_line_size = val.

  ENDMETHOD.

  METHOD get_line_size.

    result = mv_line_size.

  ENDMETHOD.

  METHOD current_line.

    result = mv_line.

  ENDMETHOD.

  METHOD current_column.

    result = COND #( WHEN mv_next_pos > 0 THEN mv_next_pos
                     WHEN mv_col_line = mv_line THEN mv_col + 1
                     ELSE 1 ).

  ENDMETHOD.

  METHOD current_page.

    result = get_page_count( ).

  ENDMETHOD.

  METHOD describe_lines.

    DATA lv_last TYPE i.

    LOOP AT mt_item INTO DATA(ls_item) WHERE header = abap_false AND footer = abap_false.
      IF ls_item-line <> lv_last.
        lv_last = ls_item-line.
        result = result + 1.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD line_text.

    DATA lt_item TYPE ty_t_item.

    LOOP AT mt_item INTO DATA(ls_item) WHERE line = line.
      INSERT ls_item INTO TABLE lt_item.
    ENDLOOP.
    DATA(lt_text) = items_to_text( lt_item ).
    READ TABLE lt_text INTO result INDEX 1.

  ENDMETHOD.

  METHOD get_item_by_id.

    READ TABLE mt_item INTO result WITH KEY id = id.

  ENDMETHOD.

  METHOD hide.

    DATA(lv_hide) = hide_text( val ).
    LOOP AT mt_item REFERENCE INTO DATA(lr_item) WHERE line = mv_line AND kind = cs_kind-text.
      lr_item->hide    = lv_hide.
      lr_item->hotspot = abap_true.
    ENDLOOP.
    result = me.

  ENDMETHOD.

  METHOD write_as_checkbox.

    item_add( VALUE #( kind  = cs_kind-checkbox
                       flag  = val
                       input = input ) ).
    result = me.

  ENDMETHOD.

  METHOD write_as_icon.

    item_add( VALUE #( kind = cs_kind-icon
                       text = val ) ).
    result = me.

  ENDMETHOD.

  METHOD new_line.

    mv_line = mv_line + 1.
    result = me.

  ENDMETHOD.

  METHOD skip.

    new_line( ).
    item_add( VALUE #( kind = cs_kind-skip
                       text = |{ val }| ) ).
    new_line( ).
    result = me.

  ENDMETHOD.

  METHOD uline.

    new_line( ).
    item_add( VALUE #( kind = cs_kind-uline
                       pos  = pos
                       len  = len ) ).
    new_line( ).
    result = me.

  ENDMETHOD.

  METHOD new_page.

    IF line_count IS SUPPLIED.
      mv_line_count = line_count.
    ENDIF.
    new_line( ).
    item_add( VALUE #( kind       = cs_kind-page
                       text       = title
                       no_heading = no_heading ) ).
    new_line( ).
    result = me.

  ENDMETHOD.

  METHOD clear.

    CLEAR: mt_item, mv_page_lines, mv_body_line, mv_id, ms_format, mv_col, mv_col_line, mv_next_pos.
    mv_line = 1.

  ENDMETHOD.

  METHOD get_items.

    result = mt_item.

  ENDMETHOD.

  METHOD get_item_by_line.

    LOOP AT mt_item INTO result WHERE line = val AND hotspot = abap_true.
      RETURN.
    ENDLOOP.
    CLEAR result.

  ENDMETHOD.

  METHOD item_add.

    DATA(ls_item) = val.
    ls_item-line   = mv_line.
    ls_item-header = mv_header.
    ls_item-footer = mv_footer.

    " LINE-COUNT: the line after the last one of a page starts a new page
    IF ls_item-header = abap_false AND ls_item-footer = abap_false.
      IF ls_item-kind = cs_kind-page.
        mv_page_lines = 0.
        mv_body_line = ls_item-line.
      ELSEIF ls_item-line <> mv_body_line.
        mv_body_line = ls_item-line.
        mv_page_lines = mv_page_lines + 1.
        IF mv_line_count > 0 AND mv_page_lines > mv_line_count.
          mv_id = mv_id + 1.
          INSERT VALUE #( line = mv_line
                          kind = cs_kind-page
                          id   = mv_id ) INTO TABLE mt_item.
          mv_line = mv_line + 1.
          ls_item-line = mv_line.
          mv_body_line = mv_line.
          mv_page_lines = 1.
        ENDIF.
      ENDIF.
    ENDIF.

    " the column of the item - SY-COLNO, WRITE UNDER and POSITION
    IF ls_item-kind = cs_kind-text OR ls_item-kind = cs_kind-checkbox OR ls_item-kind = cs_kind-icon.
      IF mv_col_line <> ls_item-line.
        mv_col_line = ls_item-line.
        mv_col = 0.
      ENDIF.
      IF ls_item-pos = 0 AND mv_next_pos > 0.
        ls_item-pos = mv_next_pos.
      ENDIF.
      CLEAR mv_next_pos.
      IF ls_item-pos > 0.
        mv_col = ls_item-pos - 1.
      ENDIF.
      ls_item-col = mv_col + 1.
      DATA(lv_width) = COND i( WHEN ls_item-len > 0 THEN ls_item-len
                               WHEN ls_item-kind = cs_kind-checkbox THEN 3
                               WHEN ls_item-kind = cs_kind-icon THEN 2
                               ELSE strlen( ls_item-text ) ).
      mv_col = mv_col + lv_width + COND i( WHEN ls_item-no_gap = abap_true THEN 0 ELSE 1 ).
    ENDIF.

    mv_id = mv_id + 1.
    ls_item-id = mv_id.
    INSERT ls_item INTO TABLE mt_item.

  ENDMETHOD.

  METHOD header_begin.

    mv_header = abap_true.

  ENDMETHOD.

  METHOD header_end.

    " the header ends with its line - the list starts on a line of its own
    IF mv_header = abap_true AND line_exists( mt_item[ line = mv_line ] ).
      new_line( ).
    ENDIF.
    mv_header = abap_false.

  ENDMETHOD.

  METHOD footer_begin.

    IF line_exists( mt_item[ line = mv_line ] ).
      new_line( ).
    ENDIF.
    mv_footer = abap_true.

  ENDMETHOD.

  METHOD footer_end.

    IF mv_footer = abap_true AND line_exists( mt_item[ line = mv_line ] ).
      new_line( ).
    ENDIF.
    mv_footer = abap_false.

  ENDMETHOD.

  METHOD set_line_count.

    mv_line_count = val.

  ENDMETHOD.

  METHOD get_page_count.

    result = 1.
    LOOP AT mt_item TRANSPORTING NO FIELDS WHERE kind = cs_kind-page AND header = abap_false AND footer = abap_false.
      result = result + 1.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_inputs.

    LOOP AT mt_item INTO DATA(ls_item) WHERE input = abap_true.
      INSERT VALUE #( id    = ls_item-id
                      line  = ls_item-line
                      value = ls_item-text
                      flag  = ls_item-flag ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD set_input_binds.

    mt_input_bind = val.

  ENDMETHOD.

  METHOD set_inputs.

    LOOP AT val INTO DATA(ls_input).
      LOOP AT mt_item REFERENCE INTO DATA(lr_item) WHERE id = ls_input-id AND input = abap_true.
        lr_item->text = ls_input-value.
        lr_item->flag = ls_input-flag.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD read_line.

    LOOP AT mt_item INTO DATA(ls_item) WHERE line = line
         AND ( kind = cs_kind-text OR kind = cs_kind-checkbox OR kind = cs_kind-icon ).
      INSERT ls_item INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD read_value.

    DATA(lt_item) = read_line( line ).
    READ TABLE lt_item INTO DATA(ls_item) INDEX index.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF ls_item-kind = cs_kind-checkbox.
      result = COND #( WHEN ls_item-flag = abap_true THEN `X` ).
    ELSE.
      result = ls_item-text.
    ENDIF.

  ENDMETHOD.

  METHOD modify_line.

    DATA lv_count TYPE i.

    LOOP AT mt_item REFERENCE INTO DATA(lr_item) WHERE line = line
         AND ( kind = cs_kind-text OR kind = cs_kind-checkbox OR kind = cs_kind-icon ).
      lv_count = lv_count + 1.
      IF lv_count <> index.
        CONTINUE.
      ENDIF.
      IF lr_item->kind = cs_kind-checkbox.
        lr_item->flag = xsdbool( value IS NOT INITIAL ).
      ELSE.
        lr_item->text = z2ui5_cl_cgui_context=>conv_to_text( value ).
      ENDIF.
      IF color IS SUPPLIED.
        lr_item->color = color.
      ENDIF.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD text_format.

    DATA lv_number  TYPE decfloat34.
    DATA lv_amount0 TYPE p LENGTH 16 DECIMALS 0.
    DATA lv_amount2 TYPE p LENGTH 16 DECIMALS 2.
    DATA lv_amount3 TYPE p LENGTH 16 DECIMALS 3.
    DATA lv_date   TYPE d.
    DATA lv_ts     TYPE timestamp.
    DATA lv_tsl    TYPE timestampl.

    DATA(lo_descr) = cl_abap_typedescr=>describe_by_data( val ).
    DATA(lv_kind) = lo_descr->type_kind.
    DATA(lv_numeric) = xsdbool( lv_kind = cl_abap_typedescr=>typekind_int
                             OR lv_kind = cl_abap_typedescr=>typekind_int1
                             OR lv_kind = cl_abap_typedescr=>typekind_int2
                             OR lv_kind = cl_abap_typedescr=>typekind_int8
                             OR lv_kind = cl_abap_typedescr=>typekind_packed
                             OR lv_kind = cl_abap_typedescr=>typekind_float
                             OR lv_kind = cl_abap_typedescr=>typekind_decfloat16
                             OR lv_kind = cl_abap_typedescr=>typekind_decfloat34 ).

    IF no_zero = abap_true AND val IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        " the options of WRITE ... TO as string templates - WRITE TO is not
        " part of ABAP Cloud
        IF edit_mask IS NOT INITIAL.
          result = edit_mask_apply( val  = val
                                    mask = edit_mask ).
        ELSEIF date_format IS NOT INITIAL AND lv_kind = cl_abap_typedescr=>typekind_date.
          lv_date = val.
          result = date_text( val    = lv_date
                              format = date_format ).
        ELSEIF time_zone IS NOT INITIAL AND lv_kind = cl_abap_typedescr=>typekind_packed
            AND ( ( lo_descr->length = 8 AND CAST cl_abap_elemdescr( lo_descr )->decimals = 0 )
               OR ( lo_descr->length = 11 AND CAST cl_abap_elemdescr( lo_descr )->decimals = 7 ) ).
          " a time stamp in the time zone given
          DATA(lv_zone) = CONV tznzone( time_zone ).
          IF lo_descr->length = 8.
            lv_ts = val.
            result = |{ lv_ts TIMESTAMP = USER TIMEZONE = lv_zone }|.
          ELSE.
            lv_tsl = val.
            result = |{ lv_tsl TIMESTAMP = USER TIMEZONE = lv_zone }|.
          ENDIF.
        ELSEIF lv_numeric = abap_true AND currency IS NOT INITIAL.
          " WRITE ... CURRENCY: the decimals of the currency, a packed amount
          " shifted as the classic WRITE shifts it - its own decimals do not
          " count. The decimals as ISO 4217 has them: TCURX is not released
          " on ABAP Cloud, and the CURRENCY of a string template is not in
          " the transpiled runtime
          DATA(lv_cur_decimals) = currency_decimals( currency ).
          DATA(lv_own_decimals) = COND i( WHEN lv_kind = cl_abap_typedescr=>typekind_packed
                                          THEN CAST cl_abap_elemdescr( lo_descr )->decimals
                                          ELSE 0 ).
          lv_number = val.
          lv_number = lv_number * ( CONV decfloat34( 10 ) ** ( lv_own_decimals - lv_cur_decimals ) ).
          CASE lv_cur_decimals.
            WHEN 0.
              lv_amount0 = lv_number.
              result = |{ lv_amount0 NUMBER = USER }|.
            WHEN 3.
              lv_amount3 = lv_number.
              result = |{ lv_amount3 NUMBER = USER }|.
            WHEN OTHERS.
              lv_amount2 = lv_number.
              result = |{ lv_amount2 NUMBER = USER }|.
          ENDCASE.
        ELSEIF lv_numeric = abap_true AND unit IS NOT INITIAL.
          " the decimals of a unit are in T006, which ABAP Cloud does not
          " release - the number as it is
          lv_number = val.
          result = |{ lv_number NUMBER = USER }|.
        ELSEIF lv_numeric = abap_true AND ( decimals >= 0 OR round <> 0 ).
          " ROUND r: the value times 10 ** -r
          lv_number = val.
          IF round <> 0.
            lv_number = lv_number / ( CONV decfloat34( 10 ) ** round ).
          ENDIF.
          DATA(lv_decimals) = COND i( WHEN decimals >= 0 THEN decimals
                                      WHEN lv_kind = cl_abap_typedescr=>typekind_packed
                                      THEN CAST cl_abap_elemdescr( lo_descr )->decimals
                                      ELSE 0 ).
          " a whole number rounded first - the same on a system, and the
          " transpiled runtime does not round for DECIMALS = 0
          IF lv_decimals = 0.
            lv_number = round( val = lv_number
                               dec = 0 ).
          ENDIF.
          result = |{ lv_number NUMBER = USER DECIMALS = lv_decimals }|.

        ELSEIF lv_numeric = abap_true AND no_grouping = abap_true.
          lv_number = val.
          result = |{ lv_number NUMBER = USER }|.
        ELSE.
          result = z2ui5_cl_cgui_context=>conv_to_text( val ).
        ENDIF.
      CATCH cx_root.
        result = z2ui5_cl_cgui_context=>conv_to_text( val ).
    ENDTRY.

    " NO-GROUPING: without the thousands separator
    IF no_grouping = abap_true AND lv_numeric = abap_true.
      DATA(lv_group) = grouping_char( ).
      IF lv_group IS NOT INITIAL.
        result = replace( val = result sub = lv_group with = `` occ = 0 ).
      ENDIF.
    ENDIF.
    " NO-ZERO: the leading zeros of a numeric text go
    IF no_zero = abap_true AND ( lv_kind = cl_abap_typedescr=>typekind_num OR lv_kind = cl_abap_typedescr=>typekind_char ).
      result = shift_left( val = result sub = `0` ).
    ENDIF.
    IF no_sign = abap_true AND lv_numeric = abap_true.
      result = replace( val = result sub = `-` with = `` occ = 0 ).
    ENDIF.

  ENDMETHOD.

  METHOD currency_decimals.

    DATA(lv_currency) = to_upper( condense( currency ) ).
    CASE lv_currency.
      WHEN `BIF` OR `CLP` OR `DJF` OR `GNF` OR `ISK` OR `JPY` OR `KMF` OR `KRW` OR `PYG`
          OR `RWF` OR `UGX` OR `UYI` OR `VND` OR `VUV` OR `XAF` OR `XOF` OR `XPF`.
        result = 0.
      WHEN `BHD` OR `IQD` OR `JOD` OR `KWD` OR `LYD` OR `OMR` OR `TND`.
        result = 3.
      WHEN OTHERS.
        result = 2.
    ENDCASE.

  ENDMETHOD.

  METHOD edit_mask_apply.

    DATA lt_char TYPE string_table.
    DATA lv_pos  TYPE i.

    DATA(lv_value) = |{ val }|.
    DATA(lv_mask) = |{ mask }|.

    IF strlen( lv_mask ) > 2 AND substring( val = lv_mask len = 2 ) = `==`.
      IF to_upper( substring( val = lv_mask off = 2 ) ) = `ALPHA`.
        result = |{ lv_value ALPHA = OUT }|.
      ELSE.
        result = lv_value.
      ENDIF.
      RETURN.
    ENDIF.

    DATA(lv_right) = abap_false.
    IF strlen( lv_mask ) >= 2.
      DATA(lv_prefix) = to_upper( substring( val = lv_mask len = 2 ) ).
      IF lv_prefix = `LL` OR lv_prefix = `RR`.
        lv_right = xsdbool( lv_prefix = `RR` ).
        lv_mask = substring( val = lv_mask off = 2 ).
      ENDIF.
    ENDIF.

    DATA(lv_mask_len) = strlen( lv_mask ).
    DATA(lv_value_len) = strlen( lv_value ).
    IF lv_right = abap_false.
      lv_pos = 0.
      DO lv_mask_len TIMES.
        DATA(lv_index) = sy-index - 1.
        DATA(lv_char) = substring( val = lv_mask off = lv_index len = 1 ).
        IF lv_char = `_`.
          IF lv_pos < lv_value_len.
            lv_char = substring( val = lv_value off = lv_pos len = 1 ).
          ELSE.
            lv_char = ` `.
          ENDIF.
          lv_pos = lv_pos + 1.
        ENDIF.
        INSERT lv_char INTO TABLE lt_char.
      ENDDO.
    ELSE.
      lv_pos = lv_value_len.
      DO lv_mask_len TIMES.
        lv_index = lv_mask_len - sy-index.
        lv_char = substring( val = lv_mask off = lv_index len = 1 ).
        IF lv_char = `_`.
          lv_pos = lv_pos - 1.
          IF lv_pos >= 0.
            lv_char = substring( val = lv_value off = lv_pos len = 1 ).
          ELSE.
            lv_char = ` `.
          ENDIF.
        ENDIF.
        INSERT lv_char INTO lt_char INDEX 1.
      ENDDO.
    ENDIF.
    result = shift_right( val = shift_left( val = concat_lines_of( lt_char ) sub = ` ` ) sub = ` ` ).

  ENDMETHOD.

  METHOD date_text.

    DATA lv_sep TYPE string VALUE `.`.

    " the separator of the user's date format: the first character of the
    " formatted date that is no digit
    DATA(lv_user) = |{ val DATE = USER }|.
    DATA(lv_len) = strlen( lv_user ).
    DO lv_len TIMES.
      DATA(lv_index) = sy-index - 1.
      DATA(lv_char) = substring( val = lv_user off = lv_index len = 1 ).
      IF lv_char CN `0123456789`.
        lv_sep = lv_char.
        EXIT.
      ENDIF.
    ENDDO.

    DATA(lv_year) = |{ val+0(4) }|.
    DATA(lv_yy) = |{ val+2(2) }|.
    DATA(lv_month) = |{ val+4(2) }|.
    DATA(lv_day) = |{ val+6(2) }|.
    DATA(lv_format) = to_upper( format ).
    CASE lv_format.
      WHEN cs_date_format-dd_mm_yy.
        result = |{ lv_day }{ lv_sep }{ lv_month }{ lv_sep }{ lv_yy }|.
      WHEN cs_date_format-mm_dd_yy.
        result = |{ lv_month }{ lv_sep }{ lv_day }{ lv_sep }{ lv_yy }|.
      WHEN cs_date_format-dd_mm_yyyy.
        result = |{ lv_day }{ lv_sep }{ lv_month }{ lv_sep }{ lv_year }|.
      WHEN cs_date_format-mm_dd_yyyy.
        result = |{ lv_month }{ lv_sep }{ lv_day }{ lv_sep }{ lv_year }|.
      WHEN cs_date_format-ddmmyy.
        result = |{ lv_day }{ lv_month }{ lv_yy }|.
      WHEN cs_date_format-mmddyy.
        result = |{ lv_month }{ lv_day }{ lv_yy }|.
      WHEN cs_date_format-yymmdd.
        result = |{ lv_yy }{ lv_month }{ lv_day }|.
      WHEN OTHERS.
        result = lv_user.
    ENDCASE.

  ENDMETHOD.

  METHOD grouping_char.

    DATA(lv_sample) = |{ CONV decfloat34( 1000 ) NUMBER = USER DECIMALS = 0 }|.
    IF strlen( lv_sample ) = 5.
      result = lv_sample+1(1).
    ENDIF.

  ENDMETHOD.

  METHOD page_copy.

    result = items.
    LOOP AT result REFERENCE INTO DATA(lr_item) WHERE text CS cv_page.
      lr_item->text = replace( val = lr_item->text sub = cv_page with = |{ page }| occ = 0 ).
    ENDLOOP.

  ENDMETHOD.

  METHOD sequence.

    DATA lt_header TYPE ty_t_item.
    DATA lt_footer TYPE ty_t_item.
    DATA lv_page   TYPE i VALUE 1.

    LOOP AT mt_item INTO DATA(ls_item).
      IF ls_item-header = abap_true.
        INSERT ls_item INTO TABLE lt_header.
      ELSEIF ls_item-footer = abap_true.
        INSERT ls_item INTO TABLE lt_footer.
      ENDIF.
    ENDLOOP.

    INSERT LINES OF page_copy( items = lt_header
                               page  = lv_page ) INTO TABLE result.
    LOOP AT mt_item INTO ls_item WHERE header = abap_false AND footer = abap_false.
      IF ls_item-kind = cs_kind-page.
        INSERT LINES OF page_copy( items = lt_footer
                                   page  = lv_page ) INTO TABLE result.
        INSERT ls_item INTO TABLE result.
        lv_page = lv_page + 1.
        IF ls_item-no_heading = abap_false.
          INSERT LINES OF page_copy( items = lt_header
                                     page  = lv_page ) INTO TABLE result.
        ENDIF.
      ELSE.
        INSERT ls_item INTO TABLE result.
      ENDIF.
    ENDLOOP.
    INSERT LINES OF page_copy( items = lt_footer
                               page  = lv_page ) INTO TABLE result.

  ENDMETHOD.

  METHOD has_content.

    LOOP AT mt_item TRANSPORTING NO FIELDS WHERE header = abap_false AND footer = abap_false.
      result = abap_true.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD cut.

    DATA lt_cut TYPE ty_t_item.

    LOOP AT mt_item INTO DATA(ls_item) WHERE line >= from AND header = abap_false AND footer = abap_false.
      INSERT ls_item INTO TABLE lt_cut.
    ENDLOOP.
    result = items_to_text( lt_cut ).
    DELETE mt_item WHERE line >= from AND header = abap_false AND footer = abap_false.
    mv_line = nmax( val1 = from
                    val2 = 1 ).
    CLEAR: mv_col, mv_col_line, mv_next_pos, mv_body_line.

  ENDMETHOD.

  METHOD to_text.

    result = items_to_text( sequence( ) ).

  ENDMETHOD.

  METHOD items_to_text.

    DATA lv_text TYPE string.
    DATA lv_line TYPE i.
    DATA lv_gap  TYPE abap_bool.

    LOOP AT items REFERENCE INTO DATA(lr_item).
      IF lr_item->line <> lv_line AND lv_line > 0.
        INSERT lv_text INTO TABLE result.
        CLEAR: lv_text, lv_gap.
      ENDIF.
      lv_line = lr_item->line.
      CASE lr_item->kind.
        WHEN cs_kind-uline.
          IF lr_item->pos > 1.
            lv_text = repeat( val = ` ` occ = lr_item->pos - 1 ).
          ENDIF.
          lv_text = lv_text && repeat( val = `-`
                                       occ = COND i( WHEN lr_item->len > 0 THEN lr_item->len
                                                     WHEN mv_line_size > 0 THEN mv_line_size
                                                     ELSE 80 ) ).
        WHEN cs_kind-page OR cs_kind-text OR cs_kind-icon OR cs_kind-checkbox.
          IF lr_item->pos > 0 AND strlen( lv_text ) < lr_item->pos - 1.
            lv_text = lv_text && repeat( val = ` ` occ = lr_item->pos - 1 - strlen( lv_text ) ).
          ELSEIF lv_text IS NOT INITIAL AND lv_gap = abap_false.
            lv_text = lv_text && ` `.
          ENDIF.
          lv_gap = lr_item->no_gap.
          IF lr_item->kind = cs_kind-checkbox.
            lv_text = lv_text && COND string( WHEN lr_item->flag = abap_true THEN `[X]` ELSE `[ ]` ).
          ELSEIF lr_item->len > 0 AND lr_item->justify = cs_justify-right.
            lv_text = lv_text && substring( val = z2ui5_cl_cgui_context=>text_align( val   = lr_item->text
                                                                                     width = lr_item->len
                                                                                     align = `RIGHT` )
                                            len = lr_item->len ).
          ELSEIF lr_item->len > 0 AND lr_item->justify = cs_justify-center.
            lv_text = lv_text && substring( val = z2ui5_cl_cgui_context=>text_align( val   = lr_item->text
                                                                                     width = lr_item->len
                                                                                     align = `CENTER` )
                                            len = lr_item->len ).
          ELSEIF lr_item->len > 0.
            lv_text = lv_text && substring( val = |{ lr_item->text WIDTH = lr_item->len }|
                                            len = lr_item->len ).
          ELSE.
            lv_text = lv_text && lr_item->text.
          ENDIF.
      ENDCASE.
    ENDLOOP.
    IF lv_line > 0.
      INSERT lv_text INTO TABLE result.
    ENDIF.

    " LINE-SIZE cuts the lines
    IF mv_line_size > 0.
      LOOP AT result REFERENCE INTO DATA(lr_text) WHERE table_line IS NOT INITIAL.
        IF strlen( lr_text->* ) > mv_line_size.
          lr_text->* = substring( val = lr_text->* len = mv_line_size ).
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD render.

    " TOP-OF-PAGE and END-OF-PAGE: header and footer around every page
    DATA(lo_list) = node->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    render_items( node   = lo_list
                  client = client
                  items  = sequence( )
                  inputs = inputs ).

  ENDMETHOD.

  METHOD render_text_tooltip.

    " the box takes the tooltip, the text inside is rendered as without
    DATA(ls_item) = item.
    CLEAR ls_item-quickinfo.
    DATA(lo_box) = node->ele( `HBox`
        )->a( n = `tooltip` t = item-quickinfo ).
    render_item( node   = lo_box
                 client = client
                 item   = ls_item
                 inputs = inputs ).

  ENDMETHOD.

  METHOD hide_text.

    FIELD-SYMBOLS <copy> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    DATA lr_copy TYPE REF TO data.

    " a copy first: the transpiled runtime passes val by reference, and its
    " RTTI is ABAP code that loops - `hide = sy-tabix` would change on the way
    CREATE DATA lr_copy LIKE val.
    ASSIGN lr_copy->* TO <copy>.
    <copy> = val.
    IF cl_abap_typedescr=>describe_by_data( <copy> )->kind <> cl_abap_typedescr=>kind_struct.
      result = |{ <copy> }|.
      RETURN.
    ENDIF.
    DATA(lv_index) = 0.
    DO.
      lv_index = lv_index + 1.
      ASSIGN COMPONENT lv_index OF STRUCTURE <copy> TO <comp>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      DATA(lv_text) = COND string( WHEN cl_abap_typedescr=>describe_by_data( <comp> )->kind = cl_abap_typedescr=>kind_elem
                                   THEN |{ <comp> }| ).
      result = COND #( WHEN lv_index = 1 THEN lv_text ELSE |{ result }\t{ lv_text }| ).
    ENDDO.

  ENDMETHOD.

  METHOD hide_restore.

    FIELD-SYMBOLS <comp> TYPE any.

    IF cl_abap_typedescr=>describe_by_data( val )->kind <> cl_abap_typedescr=>kind_struct.
      val = hide.
      RETURN.
    ENDIF.
    CLEAR val.
    SPLIT hide AT |\t| INTO TABLE DATA(lt_part).
    LOOP AT lt_part INTO DATA(lv_part).
      ASSIGN COMPONENT sy-tabix OF STRUCTURE val TO <comp>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      IF cl_abap_typedescr=>describe_by_data( <comp> )->kind = cl_abap_typedescr=>kind_elem.
        <comp> = lv_part.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD width_of.

    DATA(lv_tenths) = nmax( val1 = chars
                            val2 = 0 ) * 6.
    result = |{ lv_tenths DIV 10 }.{ lv_tenths MOD 10 }em|.

  ENDMETHOD.

  METHOD render_items.

    " WRITE AT pos(len): a spacer fills up to the column, the value takes
    " its width - both in characters, so the columns line up line by line.
    " In a line with a position every item stands in a box of its width in
    " characters (len, else its text and the gap): the font is not
    " monospaced, so a spacer counted from the text alone would drift
    DATA lo_line TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_line TYPE i.
    DATA lv_col  TYPE i.
    DATA lt_columned TYPE SORTED TABLE OF i WITH UNIQUE KEY table_line.

    LOOP AT items REFERENCE INTO DATA(lr_pos) WHERE pos > 0.
      INSERT lr_pos->line INTO TABLE lt_columned.
    ENDLOOP.

    LOOP AT items REFERENCE INTO DATA(lr_item).

      IF lr_item->kind = cs_kind-skip OR lr_item->kind = cs_kind-uline OR lr_item->kind = cs_kind-page.
        render_item( node   = node
                     client = client
                     item   = lr_item->*
                     inputs = inputs ).
        CLEAR lo_line.
        CONTINUE.
      ENDIF.

      IF lo_line IS NOT BOUND OR lv_line <> lr_item->line.
        lv_line = lr_item->line.
        lv_col = 0.
        lo_line = node->ele( `HBox`
            )->a( n = `alignItems` v = `Center` ).
      ENDIF.

      IF lr_item->pos > 0.
        IF lr_item->pos - 1 > lv_col.
          lo_line->tag( `HBox`
              )->a( n = `width` v = width_of( lr_item->pos - 1 - lv_col ) ).
        ENDIF.
        lv_col = lr_item->pos - 1.
      ENDIF.

      DATA(lv_width) = COND i( WHEN lr_item->len > 0 THEN lr_item->len
                               WHEN lr_item->no_gap = abap_true THEN strlen( lr_item->text )
                               ELSE strlen( lr_item->text ) + 1 ).
      IF line_exists( lt_columned[ table_line = lr_item->line ] ) AND lv_width > 0.
        render_item( node   = lo_line->ele( `HBox`
                                  )->a( n = `width` v = width_of( lv_width ) )
                     client = client
                     item   = lr_item->*
                     inputs = inputs ).
      ELSE.
        render_item( node   = lo_line
                     client = client
                     item   = lr_item->*
                     inputs = inputs ).
      ENDIF.
      lv_col = lv_col + lv_width.
    ENDLOOP.

  ENDMETHOD.

  METHOD render_item.

    FIELD-SYMBOLS <input> TYPE ty_s_input.

    " NO-GAP: no space to the next item
    DATA(lv_class) = COND string( WHEN item-no_gap = abap_true THEN `` ELSE `sapUiTinyMarginEnd` ).

    " an input field is bound to its line of inputs - by the app
    " (set_input_binds( )), or here
    IF item-input = abap_true.
      READ TABLE mt_input_bind INTO DATA(ls_bind) WITH KEY id = item-id.
      DATA(lv_bound) = xsdbool( sy-subrc = 0 ).
      READ TABLE inputs TRANSPORTING NO FIELDS WITH KEY id = item-id.
      DATA(lv_index) = COND i( WHEN sy-subrc = 0 THEN sy-tabix ).
      IF lv_bound = abap_true OR lv_index > 0.
        IF lv_index > 0.
          ASSIGN inputs[ lv_index ] TO <input>.
        ENDIF.
        IF item-kind = cs_kind-checkbox.
          DATA(lv_flag_bind) = COND string( WHEN lv_bound = abap_true THEN ls_bind-flag
                                            ELSE client->_bind( val       = <input>-flag
                                                                tab       = inputs
                                                                tab_index = lv_index ) ).
          node->tag( `CheckBox`
              )->a( n = `selected` v = lv_flag_bind ).
        ELSE.
          DATA(lv_value_bind) = COND string( WHEN lv_bound = abap_true THEN ls_bind-value
                                             ELSE client->_bind( val       = <input>-value
                                                                 tab       = inputs
                                                                 tab_index = lv_index ) ).
          node->tag( `Input`
              )->a( n = `value` v = lv_value_bind
              )->a( n = `width` v = width_of( COND i( WHEN item-len > 0 THEN item-len ELSE nmax( val1 = strlen( item-text ) val2 = 10 ) ) + 2 )
              )->a( n = `class` t = lv_class ).
        ENDIF.
        RETURN.
      ENDIF.
    ENDIF.

    IF item-kind = cs_kind-text AND item-quickinfo IS NOT INITIAL.
      render_text_tooltip( node   = node
                           client = client
                           item   = item
                           inputs = inputs ).
      RETURN.
    ENDIF.

    CASE item-kind.

      WHEN cs_kind-text.
        IF item-hotspot = abap_false AND ( item-inverse = abap_true OR ( item-intensified = abap_true AND item-color IS NOT INITIAL ) ).
          node->tag( `ObjectStatus`
              )->a( n = `text`     t = item-text
              )->a( n = `state`    t = COND #( WHEN item-color IS NOT INITIAL THEN item-color ELSE `Information` )
              )->a( n = `inverted` b = item-inverse
              )->a( n = `class`    t = lv_class ).
          RETURN.
        ENDIF.
        IF item-hotspot = abap_false AND item-intensified = abap_true AND item-color IS INITIAL.
          node->tag( `Label`
              )->a( n = `text`   t = item-text
              )->a( n = `design` v = `Bold`
              )->a( n = `class`  t = lv_class ).
          IF item-len > 0.
            node->a( n = `width` v = width_of( item-len ) ).
          ENDIF.
          RETURN.
        ENDIF.
        IF item-hotspot = abap_true.
          node->tag( `Link`
              )->a( n = `text`  t = item-text
              )->a( n = `class` t = lv_class
              )->a( n = `press` v = client->_event( val   = cs_event-line_selection
                                                    t_arg = VALUE #( ( |{ item-line }| )
                                                                     ( item-hide )
                                                                     ( |{ item-id }| ) )
                                                    s_ctrl = VALUE #( check_arg_literal = abap_true ) ) ).
        ELSEIF item-color IS NOT INITIAL.
          node->tag( `ObjectStatus`
              )->a( n = `text`  t = item-text
              )->a( n = `state` t = item-color
              )->a( n = `class` t = lv_class ).
        ELSE.
          node->tag( `Text`
              )->a( n = `text`             t = item-text
              )->a( n = `renderWhitespace` b = abap_true
              )->a( n = `wrapping`         b = abap_false
              )->a( n = `class`            t = lv_class ).
          IF item-len > 0.
            node->a( n = `width`     v = width_of( item-len )
               )->a( n = `textAlign` v = SWITCH #( item-justify
                                                   WHEN cs_justify-right THEN `End`
                                                   WHEN cs_justify-center THEN `Center`
                                                   ELSE `Begin` ) ).
          ENDIF.
        ENDIF.

      WHEN cs_kind-checkbox.
        node->tag( `CheckBox`
            )->a( n = `selected` b = item-flag
            )->a( n = `editable` b = abap_false ).
        IF item-quickinfo IS NOT INITIAL.
          node->a( n = `tooltip` t = item-quickinfo ).
        ENDIF.

      WHEN cs_kind-icon.
        node->tag( n = `Icon` ns = `core`
            )->a( n = `xmlns:core` v = `sap.ui.core`
            )->a( n = `src`        v = item-text
            )->a( n = `class`      t = lv_class ).
        IF item-quickinfo IS NOT INITIAL.
          node->a( n = `tooltip` t = item-quickinfo ).
        ENDIF.

      WHEN cs_kind-skip.
        node->tag( `HBox`
            )->a( n = `height` v = |{ item-text }rem| ).

      WHEN cs_kind-uline.
        IF item-pos > 1 OR item-len > 0.
          " ULINE AT pos(len)
          DATA(lo_rule) = node->ele( `HBox` ).
          IF item-pos > 1.
            lo_rule->tag( `HBox`
                )->a( n = `width` v = width_of( item-pos - 1 ) ).
          ENDIF.
          lo_rule->tag( `Toolbar`
              )->a( n = `height` v = `2px`
              )->a( n = `width`  v = COND #( WHEN item-len > 0 THEN width_of( item-len ) ELSE `100%` )
              )->a( n = `design` v = `Solid` ).
        ELSE.
          node->tag( `Toolbar`
              )->a( n = `height` v = `2px`
              )->a( n = `design` v = `Solid` ).
        ENDIF.

      WHEN cs_kind-page.
        node->tag( `Title`
            )->a( n = `text`  t = item-text
            )->a( n = `level` v = `H3`
            )->a( n = `class` v = `sapUiSmallMarginTop` ).

    ENDCASE.

  ENDMETHOD.

  METHOD stringify.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height`       v = `100%` ).

    DATA(page) = view->ele( `Page`
        )->a( n = `title` t = title ).

    render( node   = page
            client = client ).

    result = view->stringify( ).

  ENDMETHOD.

ENDCLASS.
