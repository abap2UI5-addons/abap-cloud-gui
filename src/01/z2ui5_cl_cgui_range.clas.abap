"! Multiple selection - the classic dialog behind the button beside a
"! select-option, as an abap2UI5 app of its own. It shows the lines of a
"! range table - include or exclude, the option, from and to - and lets
"! the user add, change and delete them, take over values pasted from the
"! clipboard (a column copied out of Excel) and ask for F4 on a line.
"! The caller opens it with nav_app_call( ) and reads result( ) of
"! client->get_app_prev( ) when it is back:
"!   client->nav_app_call( z2ui5_cl_cgui_range=>factory(
"!       range   = s_carrid
"!       setting = VALUE #( title = `Airline` value_help = abap_true ) ) ).
"!   ...
"!   DATA(ls_result) = CAST z2ui5_cl_cgui_range( client->get_app_prev( ) )->result( ).
"!   IF ls_result-confirmed = abap_true.
"!     z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = ls_result-rows
"!                                         IMPORTING error = lv_error
"!                                         CHANGING  range = s_carrid ).
"!   ENDIF.
"! F4 on a line - or the button that picks several values at once - leaves
"! the popup with result-f4 set, the key of the line and the part (LOW,
"! HIGH; empty for several values). The caller shows its value help, puts
"! the values in with row_set_value( ) / rows_add_values( ) and opens the
"! popup again with factory( rows = ... ). The sign of every line is
"! kept: an excluding line stays one.
CLASS z2ui5_cl_cgui_range DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS:
      BEGIN OF cs_event,
        ok         TYPE string VALUE `CGUI_RANGE_OK`,
        cancel     TYPE string VALUE `CGUI_RANGE_CANCEL`,
        add        TYPE string VALUE `CGUI_RANGE_ADD`,
        delete     TYPE string VALUE `CGUI_RANGE_DELETE`,
        delete_all TYPE string VALUE `CGUI_RANGE_DELETE_ALL`,
        f4         TYPE string VALUE `CGUI_RANGE_F4`,
        f4_multi   TYPE string VALUE `CGUI_RANGE_F4_MULTI`,
        paste      TYPE string VALUE `CGUI_RANGE_PASTE`,
        paste_ok   TYPE string VALUE `CGUI_RANGE_PASTE_OK`,
      END OF cs_event.

    CONSTANTS:
      BEGIN OF cs_control,
        input TYPE string VALUE `INPUT`,
        date  TYPE string VALUE `DATE`,
        time  TYPE string VALUE `TIME`,
      END OF cs_control.

    CONSTANTS:
      BEGIN OF cs_part,
        low  TYPE string VALUE `LOW`,
        high TYPE string VALUE `HIGH`,
      END OF cs_part.

    " a line of the range as text - a date as yyyyMMdd, a time as HHmmss
    TYPES:
      BEGIN OF ty_s_row,
        key    TYPE string,
        sign   TYPE string,
        option TYPE string,
        low    TYPE string,
        high   TYPE string,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    " title - the text of the select-option; control - cs_control, the
    " input of from and to; value_help - F4 on the lines; upper - the
    " input converted to upper case; no_intervals - the classic NO
    " INTERVALS, single values only; max_length - of the input
    TYPES:
      BEGIN OF ty_s_setting,
        title        TYPE string,
        control      TYPE string,
        value_help   TYPE abap_bool,
        upper        TYPE abap_bool,
        no_intervals TYPE abap_bool,
        max_length   TYPE i,
      END OF ty_s_setting.

    " confirmed - left with OK; f4 - F4 asked for: on line f4_key for its
    " f4_part (LOW / HIGH), or for several new lines when f4_key is empty.
    " rows - the lines as the user left them, also on F4 and cancel
    TYPES:
      BEGIN OF ty_s_result,
        confirmed TYPE abap_bool,
        f4        TYPE abap_bool,
        f4_key    TYPE string,
        f4_part   TYPE string,
        rows      TYPE ty_t_row,
      END OF ty_s_result.

    "! the lines - PUBLIC, the table of the popup is bound to them
    DATA mt_row        TYPE ty_t_row.
    "! the text pasted - bound to the text area
    DATA mv_paste      TYPE string.
    "! whether the text area for pasted values is shown
    DATA mv_paste_open TYPE abap_bool.

    "! the popup for the lines of range - or, back from F4, for rows
    CLASS-METHODS factory
      IMPORTING
        range         TYPE ANY TABLE    OPTIONAL
        rows          TYPE ty_t_row     OPTIONAL
        setting       TYPE ty_s_setting OPTIONAL
        error         TYPE clike        OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_range.

    "! the lines of a range table as text; an initial date is empty
    CLASS-METHODS rows_from_range
      IMPORTING
        range         TYPE ANY TABLE
        control       TYPE clike DEFAULT cs_control-input
      RETURNING
        VALUE(result) TYPE ty_t_row.

    "! the lines into a range table: empty lines are dropped, a pattern
    "! (* or +) turns EQ / NE into CP / NP, and CP / NP without one back
    "! into EQ / NE. error names the first line whose values do not fit the
    "! type of the range or whose lower limit is above the upper one - the
    "! range is then left as it was
    CLASS-METHODS rows_to_range
      IMPORTING
        rows  TYPE ty_t_row
        upper TYPE abap_bool DEFAULT abap_false
      EXPORTING
        error TYPE string
      CHANGING
        range TYPE STANDARD TABLE.

    "! a line SIGN, OPTION, LOW, HIGH appended to range, a table of a range
    "! type - low and high converted as its components take them, left
    "! initial when not supplied
    CLASS-METHODS line_append
      IMPORTING
        sign   TYPE clike DEFAULT `I`
        option TYPE clike DEFAULT `EQ`
        low    TYPE any   OPTIONAL
        high   TYPE any   OPTIONAL
      CHANGING
        range  TYPE STANDARD TABLE
      RAISING
        cx_sy_conversion_error.

    "! a text pasted from the clipboard as lines I EQ (I CP for a
    "! pattern) - the values separated by line breaks, tabs or semicolons
    CLASS-METHODS rows_from_text
      IMPORTING
        text          TYPE clike
      RETURNING
        VALUE(result) TYPE ty_t_row.

    "! the value picked with F4 into part (LOW / HIGH) of line row_key
    CLASS-METHODS row_set_value
      IMPORTING
        row_key TYPE clike
        part    TYPE clike
        value   TYPE clike
      CHANGING
        rows    TYPE ty_t_row.

    "! the values picked with F4 as lines I EQ - an empty line is filled
    "! first, a value already there as I EQ is not added twice
    CLASS-METHODS rows_add_values
      IMPORTING
        values TYPE string_table
      CHANGING
        rows   TYPE ty_t_row.

    METHODS result
      RETURNING
        VALUE(result) TYPE ty_s_result.

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the popup travels in the draft, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA client     TYPE REF TO z2ui5_if_client.
    DATA ms_setting TYPE ty_s_setting.
    DATA mv_error   TYPE string.
    DATA mv_next    TYPE i.
    DATA ms_result  TYPE ty_s_result.

  PRIVATE SECTION.

    "! val for a numeric cell as a move takes it: in the user's format
    "! (1.234,50 - with the decimal character typed, the grouping
    "! characters out and the decimal character a point); without the
    "! decimal character as it is (1.5 stays 1.5). decimal and group are
    "! the user's when not supplied
    CLASS-METHODS number_text
      IMPORTING
        val           TYPE string
        cell          TYPE any
        decimal       TYPE string OPTIONAL
        group         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    "! a value the cell - a date or a time - cannot take
    CLASS-METHODS value_invalid
      IMPORTING
        val           TYPE string
        cell          TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    TYPES:
      BEGIN OF ty_s_option,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_option.
    TYPES ty_t_option TYPE STANDARD TABLE OF ty_s_option WITH DEFAULT KEY.

    METHODS on_event.

    METHODS row_add
      IMPORTING
        row TYPE ty_s_row OPTIONAL.

    METHODS leave.

    METHODS options
      RETURNING
        VALUE(result) TYPE ty_t_option.

    METHODS view_display.

    METHODS render_value
      IMPORTING
        node TYPE REF TO z2ui5_cl_ui5_view_builder
        part TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_range IMPLEMENTATION.

  METHOD factory.

    DATA lt_row TYPE ty_t_row.
    DATA ls_row LIKE LINE OF lt_row.

    CREATE OBJECT result.
    result->ms_setting = setting.
    result->mv_error   = error.
    IF result->ms_setting-control IS INITIAL.
      result->ms_setting-control = cs_control-input.
    ENDIF.
    IF result->ms_setting-title IS INITIAL.
      result->ms_setting-title = 'Multiple Selection'(001).
    ENDIF.

    IF rows IS SUPPLIED.
      lt_row = rows.
    ELSEIF range IS SUPPLIED.
      lt_row = rows_from_range( range   = range
                                control = result->ms_setting-control ).
    ENDIF.


    LOOP AT lt_row INTO ls_row.
      result->row_add( ls_row ).
    ENDLOOP.
    IF result->mt_row IS INITIAL.
      result->row_add( ).
    ENDIF.

  ENDMETHOD.

  METHOD rows_from_range.

    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    DATA ls_row TYPE ty_s_row.

    LOOP AT range ASSIGNING <line>.
      CLEAR ls_row.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
      IF sy-subrc = 0.
        ls_row-sign = <comp>.
      ENDIF.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
      IF sy-subrc = 0.
        ls_row-option = <comp>.
      ENDIF.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
      IF sy-subrc = 0.
        ls_row-low = |{ <comp> }|.
      ENDIF.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
      IF sy-subrc = 0.
        ls_row-high = |{ <comp> }|.
      ENDIF.

      IF ls_row-option <> `BT` AND ls_row-option <> `NB`.
        CLEAR ls_row-high.
      ENDIF.
      IF control = cs_control-date.
        IF ls_row-low CO `0`.
          CLEAR ls_row-low.
        ENDIF.
        IF ls_row-high CO `0`.
          CLEAR ls_row-high.
        ENDIF.
      ENDIF.
      INSERT ls_row INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD line_append.

    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    DATA lr_line TYPE REF TO data.

    CREATE DATA lr_line LIKE LINE OF range.
    ASSIGN lr_line->* TO <line>.
    ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
    <comp> = sign.
    ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
    <comp> = option.
    " a value with the conversion exit ALPHA as SAP GUI stores it - not a
    " pattern
    IF low IS SUPPLIED.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
      <comp> = low.
      IF option <> `CP` AND option <> `NP`.
        z2ui5_cl_cgui_context=>conv_alpha_in( CHANGING val = <comp> ).
      ENDIF.
    ENDIF.
    IF high IS SUPPLIED.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
      <comp> = high.
      IF option <> `CP` AND option <> `NP`.
        z2ui5_cl_cgui_context=>conv_alpha_in( CHANGING val = <comp> ).
      ENDIF.
    ENDIF.
    INSERT <line> INTO TABLE range.

  ENDMETHOD.

  METHOD rows_to_range.

    FIELD-SYMBOLS <tab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    FIELD-SYMBOLS <low>  TYPE any.
    FIELD-SYMBOLS <high> TYPE any.
    DATA lr_tab   TYPE REF TO data.
    DATA lr_line  TYPE REF TO data.
    DATA lv_index TYPE i.
    DATA ls_row LIKE LINE OF rows.
        DATA temp49 TYPE z2ui5_cl_cgui_range=>ty_s_row-option.

    CLEAR error.
    CREATE DATA lr_tab LIKE range.
    ASSIGN lr_tab->* TO <tab>.
    " empty - the transpiled runtime copies the rows along with LIKE
    CLEAR <tab>.


    LOOP AT rows INTO ls_row.
      lv_index = sy-tabix.

      IF upper = abap_true.
        ls_row-low  = to_upper( ls_row-low ).
        ls_row-high = to_upper( ls_row-high ).
      ENDIF.
      IF ls_row-sign <> `E`.
        ls_row-sign = `I`.
      ENDIF.
      IF ls_row-option IS INITIAL.

        IF ls_row-high IS NOT INITIAL.
          temp49 = `BT`.
        ELSE.
          temp49 = `EQ`.
        ENDIF.
        ls_row-option = temp49.
      ENDIF.
      IF ls_row-option <> `BT` AND ls_row-option <> `NB`.
        CLEAR ls_row-high.
      ENDIF.
      IF ls_row-low IS INITIAL AND ls_row-high IS INITIAL.
        CONTINUE.
      ENDIF.

      CASE ls_row-option.
        WHEN `EQ`.
          IF ls_row-low CA `*+`.
            ls_row-option = `CP`.
          ENDIF.
        WHEN `NE`.
          IF ls_row-low CA `*+`.
            ls_row-option = `NP`.
          ENDIF.
        WHEN `CP`.
          IF ls_row-low NA `*+`.
            ls_row-option = `EQ`.
          ENDIF.
        WHEN `NP`.
          IF ls_row-low NA `*+`.
            ls_row-option = `NE`.
          ENDIF.
        WHEN `BT`.
          IF ls_row-high IS INITIAL.
            ls_row-option = `EQ`.
          ENDIF.
        WHEN `NB`.
          IF ls_row-high IS INITIAL.
            ls_row-option = `NE`.
          ENDIF.
      ENDCASE.

      CREATE DATA lr_line LIKE LINE OF <tab>.
      ASSIGN lr_line->* TO <line>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
      <comp> = ls_row-sign.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
      <comp> = ls_row-option.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <high>.
      " a number as the user writes it (1,5 or 1.234,50)
      IF ls_row-option <> `CP` AND ls_row-option <> `NP`.
        ls_row-low = number_text( val  = ls_row-low
                                  cell = <low> ).
        ls_row-high = number_text( val  = ls_row-high
                                   cell = <high> ).
      ENDIF.
      TRY.
          IF ls_row-low IS NOT INITIAL.
            <low> = ls_row-low.
          ENDIF.
          IF ls_row-high IS NOT INITIAL.
            <high> = ls_row-high.
          ENDIF.
        CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
          error = replace( val  = 'Line &1: enter a valid value'(017)
                           sub  = `&1`
                           with = |{ lv_index }| ).
          RETURN.
      ENDTRY.
      " 4711 into a KUNNR is 0000004711, as SAP GUI stores it
      IF ls_row-option <> `CP` AND ls_row-option <> `NP`.
        z2ui5_cl_cgui_context=>conv_alpha_in( CHANGING val = <low> ).
        z2ui5_cl_cgui_context=>conv_alpha_in( CHANGING val = <high> ).
      ENDIF.

      " a date or a time takes digits only - text would be taken over as it is
      IF ls_row-option <> `CP` AND ls_row-option <> `NP`
          AND ( value_invalid( val  = ls_row-low
                               cell = <low> ) = abap_true
             OR value_invalid( val  = ls_row-high
                               cell = <high> ) = abap_true ).
        error = replace( val  = 'Line &1: enter a valid value'(017)
                         sub  = `&1`
                         with = |{ lv_index }| ).
        RETURN.
      ENDIF.

      IF ( ls_row-option = `BT` OR ls_row-option = `NB` ) AND <low> > <high>.
        error = replace( val  = 'Line &1: the lower limit is greater than the upper limit'(018)
                         sub  = `&1`
                         with = |{ lv_index }| ).
        RETURN.
      ENDIF.

      INSERT <line> INTO TABLE <tab>.
    ENDLOOP.

    range = <tab>.

  ENDMETHOD.

  METHOD number_text.

    DATA lv_decimal TYPE string.
    DATA lv_group   TYPE string.
    DATA lv_kind TYPE string.
      DATA temp50 TYPE decfloat34.
      DATA lv_sample TYPE string.
      DATA lv_len TYPE i.

    result = val.

    lv_kind = z2ui5_cl_cgui_context=>rtti_get_type_kind( cell ).
    IF val IS INITIAL OR NOT ( lv_kind = cl_abap_typedescr=>typekind_packed
                            OR lv_kind = cl_abap_typedescr=>typekind_float
                            OR lv_kind = cl_abap_typedescr=>typekind_decfloat16
                            OR lv_kind = cl_abap_typedescr=>typekind_decfloat34
                            OR lv_kind = cl_abap_typedescr=>typekind_int
                            OR lv_kind = cl_abap_typedescr=>typekind_int1
                            OR lv_kind = cl_abap_typedescr=>typekind_int2
                            OR lv_kind = `8` ).
      " `8`: typekind_int8, a constant lower releases do not have
      RETURN.
    ENDIF.

    " the user's characters: 1.234,5 / 1,234.5 / 1 234,5
    IF decimal IS SUPPLIED.
      lv_decimal = decimal.
      lv_group = group.
    ELSE.

      temp50 = `1234.5`.

      lv_sample = |{ temp50 NUMBER = USER DECIMALS = 1 }|.

      lv_len = strlen( lv_sample ).
      IF lv_len >= 3.
        lv_decimal = substring( val = lv_sample off = lv_len - 2 len = 1 ).
      ENDIF.
      IF lv_len = 7.
        lv_group = substring( val = lv_sample off = 1 len = 1 ).
      ENDIF.
    ENDIF.

    result = replace( val = result sub = ` ` with = `` occ = 0 ).
    " without the decimal character the text is taken as it is - a value
    " in the internal format (1.500) comes back unchanged
    IF lv_decimal IS INITIAL OR lv_decimal = lv_group OR result NS lv_decimal.
      RETURN.
    ENDIF.
    IF lv_group IS NOT INITIAL AND lv_group <> ` `.
      result = replace( val = result sub = lv_group with = `` occ = 0 ).
    ENDIF.
    IF lv_decimal <> `.`.
      result = replace( val = result sub = lv_decimal with = `.` occ = 0 ).
    ENDIF.

  ENDMETHOD.

  METHOD value_invalid.
    DATA lv_kind TYPE string.
    DATA lv_value TYPE string.
      DATA lv_date TYPE d.
      DATA temp1 TYPE xsdboolean.
      DATA temp2 TYPE xsdboolean.

    IF val IS INITIAL.
      RETURN.
    ENDIF.

    lv_kind = z2ui5_cl_cgui_context=>rtti_get_type_kind( cell ).
    IF lv_kind <> cl_abap_typedescr=>typekind_date AND lv_kind <> cl_abap_typedescr=>typekind_time.
      RETURN.
    ENDIF.

    lv_value = condense( val ).
    IF lv_value CN `0123456789`.
      result = abap_true.
      RETURN.
    ENDIF.
    IF lv_kind = cl_abap_typedescr=>typekind_date.

      lv_date = lv_value.
      " an impossible date such as 20261340 falls back to 0 when added to

      temp1 = boolc( strlen( lv_value ) <> 8 OR lv_date + 0 = 0 ).
      result = temp1.
    ELSE.

      temp2 = boolc( strlen( lv_value ) <> 6 OR lv_value+0(2) > `23` OR lv_value+2(2) > `59` OR lv_value+4(2) > `59` ).
      result = temp2.
    ENDIF.

  ENDMETHOD.

  METHOD rows_from_text.

    DATA lt_value TYPE string_table.

    " tabs and semicolons separate as line breaks do - Excel copies a
    " column with CR LF, a block with tabs between its cells
    DATA temp51 TYPE string.
    DATA lv_text TYPE string.
    DATA lv_value LIKE LINE OF lt_value.
      DATA temp52 TYPE z2ui5_cl_cgui_range=>ty_s_row.
      DATA temp3 TYPE z2ui5_cl_cgui_range=>ty_s_row-option.
    temp51 = text.

    lv_text = translate( val  = temp51
                               from = |\t;\r|
                               to   = |\n\n\n| ).
    SPLIT lv_text AT |\n| INTO TABLE lt_value.


    LOOP AT lt_value INTO lv_value.
      lv_value = shift_right( val = shift_left( val = lv_value
                                                sub = ` ` )
                              sub = ` ` ).
      IF lv_value IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR temp52.
      temp52-sign = `I`.

      IF lv_value CA `*+`.
        temp3 = `CP`.
      ELSE.
        temp3 = `EQ`.
      ENDIF.
      temp52-option = temp3.
      temp52-low = lv_value.
      INSERT temp52 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD row_set_value.

    DATA temp53 TYPE string.
    DATA lv_key LIKE temp53.
    DATA lv_part TYPE string.
    DATA temp54 LIKE LINE OF rows.
    DATA lr_row LIKE REF TO temp54.
    temp53 = row_key.

    lv_key = temp53.

    lv_part = to_upper( part ).



    LOOP AT rows REFERENCE INTO lr_row WHERE key = lv_key.
      IF lv_part = cs_part-high.
        lr_row->high = value.
      ELSE.
        lr_row->low = value.
      ENDIF.
      EXIT.
    ENDLOOP.

  ENDMETHOD.

  METHOD rows_add_values.

    DATA lv_done TYPE abap_bool.

    DATA lv_value LIKE LINE OF values.
      DATA temp55 LIKE sy-subrc.
      DATA temp56 LIKE LINE OF rows.
      DATA lr_row LIKE REF TO temp56.
        DATA temp57 TYPE z2ui5_cl_cgui_range=>ty_s_row.
    LOOP AT values INTO lv_value.

      READ TABLE rows WITH KEY sign = `I` option = `EQ` low = lv_value TRANSPORTING NO FIELDS.
      temp55 = sy-subrc.
      IF temp55 = 0.
        CONTINUE.
      ENDIF.

      lv_done = abap_false.


      LOOP AT rows REFERENCE INTO lr_row WHERE low IS INITIAL AND high IS INITIAL.
        lr_row->sign   = `I`.
        lr_row->option = `EQ`.
        lr_row->low    = lv_value.
        lv_done = abap_true.
        EXIT.
      ENDLOOP.
      IF lv_done = abap_false.

        CLEAR temp57.
        temp57-sign = `I`.
        temp57-option = `EQ`.
        temp57-low = lv_value.
        INSERT temp57 INTO TABLE rows.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD result.

    result = ms_result.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ) IS NOT INITIAL.
      view_display( ).
      RETURN.
    ENDIF.

    on_event( ).

  ENDMETHOD.

  METHOD on_event.
        DATA lv_key TYPE string.
        DATA temp3 TYPE xsdboolean.
        DATA lt_new TYPE z2ui5_cl_cgui_range=>ty_t_row.
          DATA ls_new LIKE LINE OF lt_new.

    CASE client->get_event( ).

      WHEN cs_event-ok.
        ms_result-confirmed = abap_true.
        leave( ).

      WHEN cs_event-cancel.
        leave( ).

      WHEN cs_event-add.
        row_add( ).

      WHEN cs_event-delete.

        lv_key = client->get_event_arg( ).
        DELETE mt_row WHERE key = lv_key.

      WHEN cs_event-delete_all.
        CLEAR mt_row.
        row_add( ).

      WHEN cs_event-f4.
        ms_result-f4      = abap_true.
        ms_result-f4_key  = client->get_event_arg( ).
        ms_result-f4_part = to_upper( client->get_event_arg( 2 ) ).
        leave( ).

      WHEN cs_event-f4_multi.
        ms_result-f4 = abap_true.
        leave( ).

      WHEN cs_event-paste.

        temp3 = boolc( mv_paste_open = abap_false ).
        mv_paste_open = temp3.

      WHEN cs_event-paste_ok.

        lt_new = rows_from_text( mv_paste ).
        IF lt_new IS NOT INITIAL.
          " the empty lines give way to the values pasted
          DELETE mt_row WHERE low IS INITIAL AND high IS INITIAL.

          LOOP AT lt_new INTO ls_new.
            row_add( ls_new ).
          ENDLOOP.
        ENDIF.
        CLEAR mv_paste.
        mv_paste_open = abap_false.

    ENDCASE.

  ENDMETHOD.

  METHOD row_add.
    DATA ls_row LIKE row.
      DATA temp58 TYPE z2ui5_cl_cgui_range=>ty_s_row-option.

    mv_next = mv_next + 1.

    ls_row = row.
    ls_row-key = |{ mv_next }|.
    IF ls_row-sign IS INITIAL.
      ls_row-sign = `I`.
    ENDIF.
    IF ls_row-option IS INITIAL.

      IF ls_row-high IS NOT INITIAL AND ms_setting-no_intervals = abap_false.
        temp58 = `BT`.
      ELSE.
        temp58 = `EQ`.
      ENDIF.
      ls_row-option = temp58.
    ENDIF.
    INSERT ls_row INTO TABLE mt_row.

  ENDMETHOD.

  METHOD leave.

    ms_result-rows = mt_row.
    client->popup_destroy( ).
    client->nav_app_leave( client->get_app_prev( ) ).

  ENDMETHOD.

  METHOD options.

    DATA temp59 TYPE z2ui5_cl_cgui_range=>ty_t_option.
    DATA temp60 LIKE LINE OF temp59.
      DATA temp61 TYPE z2ui5_cl_cgui_range=>ty_s_option.
      DATA temp62 TYPE z2ui5_cl_cgui_range=>ty_s_option.
    DATA temp63 TYPE z2ui5_cl_cgui_range=>ty_s_option.
    DATA temp64 TYPE z2ui5_cl_cgui_range=>ty_s_option.
    CLEAR temp59.

    temp60-key = `EQ`.
    temp60-text = |=  { 'equal to'(020) }|.
    INSERT temp60 INTO TABLE temp59.
    temp60-key = `NE`.
    temp60-text = |<> { 'not equal to'(021) }|.
    INSERT temp60 INTO TABLE temp59.
    temp60-key = `GT`.
    temp60-text = |>  { 'greater than'(022) }|.
    INSERT temp60 INTO TABLE temp59.
    temp60-key = `GE`.
    temp60-text = |>= { 'greater than or equal to'(023) }|.
    INSERT temp60 INTO TABLE temp59.
    temp60-key = `LT`.
    temp60-text = |<  { 'less than'(024) }|.
    INSERT temp60 INTO TABLE temp59.
    temp60-key = `LE`.
    temp60-text = |<= { 'less than or equal to'(025) }|.
    INSERT temp60 INTO TABLE temp59.
    result = temp59.
    IF ms_setting-no_intervals = abap_false.

      CLEAR temp61.
      temp61-key = `BT`.
      temp61-text = |[] { 'between'(026) }|.
      INSERT temp61 INTO TABLE result.

      CLEAR temp62.
      temp62-key = `NB`.
      temp62-text = |][ { 'not between'(027) }|.
      INSERT temp62 INTO TABLE result.
    ENDIF.

    CLEAR temp63.
    temp63-key = `CP`.
    temp63-text = |*  { 'pattern'(028) }|.
    INSERT temp63 INTO TABLE result.

    CLEAR temp64.
    temp64-key = `NP`.
    temp64-text = |!* { 'not pattern'(029) }|.
    INSERT temp64 INTO TABLE result.

  ENDMETHOD.

  METHOD view_display.

    DATA temp65 TYPE string.
    DATA lo_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp66 TYPE string.
    DATA temp4 TYPE string.
    DATA temp67 TYPE string.
    DATA lo_table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lo_toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp68 TYPE string.
      DATA temp69 TYPE string.
    DATA temp70 TYPE string.
    DATA temp5 TYPE string.
    DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp71 TYPE string.
    DATA temp72 TYPE string.
    DATA temp73 TYPE string.
      DATA temp74 TYPE string.
    DATA lo_cells TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp75 TYPE string.
    DATA temp6 TYPE string.
    DATA lo_options TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp76 TYPE z2ui5_cl_cgui_range=>ty_t_option.
    DATA ls_option LIKE LINE OF temp76.
    DATA temp77 TYPE string.
    DATA temp78 TYPE string.
    DATA temp7 TYPE string.
    IF ms_setting-no_intervals = abap_true.
      temp65 = `36rem`.
    ELSE.
      temp65 = `52rem`.
    ENDIF.

    lo_dialog = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
        )->a( n = `title`        t = ms_setting-title
        )->a( n = `contentWidth` v = temp65
        )->a( n = `resizable`    b = abap_true
        )->a( n = `draggable`    b = abap_true
        )->a( n = `afterClose`   v = client->_event( cs_event-cancel ) ).


    lo_content = lo_dialog->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    IF mv_error IS NOT INITIAL.
      lo_content->tag( `MessageStrip`
          )->a( n = `text`     t = mv_error
          )->a( n = `type`     v = `Error`
          )->a( n = `showIcon` b = abap_true
          )->a( n = `class`    v = `sapUiSmallMarginBottom` ).
    ENDIF.

    " the values pasted from the clipboard - shown on demand

    temp66 = 'Paste values, one per line'(014).

    temp4 = 'Take over'(013).
    lo_content->ele( `VBox`
        )->a( n = `visible` v = client->_bind( mv_paste_open )
        )->a( n = `class`   v = `sapUiSmallMarginBottom`
        )->tag( `TextArea`
        )->a( n = `value`       v = client->_bind( mv_paste )
        )->a( n = `width`       v = `100%`
        )->a( n = `rows`        v = `6`
        )->a( n = `placeholder` t = temp66
        )->tag( `Button`
        )->a( n = `text`  t = temp4
        )->a( n = `icon`  v = `sap-icon://accept`
        )->a( n = `press` v = client->_event( cs_event-paste_ok ) ).


    temp67 = 'No conditions'(019).

    lo_table = lo_content->ele( `Table`
        )->a( n = `items`      v = client->_bind( mt_row )
        )->a( n = `noDataText` t = temp67 ).


    lo_toolbar = lo_table->ele( `headerToolbar`
        )->ele( `OverflowToolbar` ).

    temp68 = 'Add'(004).
    lo_toolbar->tag( `ToolbarSpacer`
        )->tag( `Button`
        )->a( n = `icon`  v = `sap-icon://add`
        )->a( n = `text`  t = temp68
        )->a( n = `press` v = client->_event( cs_event-add ) ).
    IF ms_setting-value_help = abap_true.

      temp69 = 'Pick values'(005).
      lo_toolbar->tag( `Button`
          )->a( n = `icon`  v = `sap-icon://value-help`
          )->a( n = `text`  t = temp69
          )->a( n = `press` v = client->_event( cs_event-f4_multi ) ).
    ENDIF.

    temp70 = 'Insert from clipboard'(006).

    temp5 = 'Delete all'(007).
    lo_toolbar->tag( `Button`
        )->a( n = `icon`  v = `sap-icon://paste`
        )->a( n = `text`  t = temp70
        )->a( n = `press` v = client->_event( cs_event-paste )
        )->tag( `Button`
        )->a( n = `icon`  v = `sap-icon://delete`
        )->a( n = `text`  t = temp5
        )->a( n = `press` v = client->_event( cs_event-delete_all ) ).


    lo_columns = lo_table->ele( `columns` ).

    temp71 = 'Selection'(009).
    lo_columns->ele( `Column`
        )->a( n = `width` v = `9rem`
        )->tag( `Text`
        )->a( n = `text` t = temp71 ).

    temp72 = 'Option'(010).
    lo_columns->ele( `Column`
        )->a( n = `width` v = `13rem`
        )->tag( `Text`
        )->a( n = `text` t = temp72 ).

    temp73 = 'From'(011).
    lo_columns->ele( `Column`
        )->tag( `Text`
        )->a( n = `text` t = temp73 ).
    IF ms_setting-no_intervals = abap_false.

      temp74 = 'To'(012).
      lo_columns->ele( `Column`
          )->tag( `Text`
          )->a( n = `text` t = temp74 ).
    ENDIF.
    lo_columns->ele( `Column`
        )->a( n = `width` v = `3rem` ).


    lo_cells = lo_table->ele( `items`
        )->ele( `ColumnListItem`
        )->ele( `cells` ).


    temp75 = 'Include'(002).

    temp6 = 'Exclude'(003).
    lo_cells->ele( `Select`
        )->a( n = `selectedKey` v = `{SIGN}`
        )->a( n = `width`       v = `100%`
        )->ele( `items`
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `I`
        )->a( n = `text` t = temp75
        )->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `E`
        )->a( n = `text` t = temp6 ).


    lo_options = lo_cells->ele( `Select`
        )->a( n = `selectedKey` v = `{OPTION}`
        )->a( n = `width`       v = `100%`
        )->ele( `items` ).

    temp76 = options( ).

    LOOP AT temp76 INTO ls_option.
      lo_options->tag( n = `Item` ns = `core`
          )->a( n = `key`  t = ls_option-key
          )->a( n = `text` t = ls_option-text ).
    ENDLOOP.

    render_value( node = lo_cells
                  part = cs_part-low ).
    IF ms_setting-no_intervals = abap_false.
      render_value( node = lo_cells
                    part = cs_part-high ).
    ENDIF.


    temp77 = 'Delete line'(008).
    lo_cells->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://decline`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` t = temp77
        )->a( n = `press`   v = client->_event( val   = cs_event-delete
                                                arg   = `${KEY}` ) ).


    temp78 = 'OK'(015).

    temp7 = 'Cancel'(016).
    lo_dialog->ele( `buttons`
        )->tag( `Button`
        )->a( n = `text`  t = temp78
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( cs_event-ok )
        )->tag( `Button`
        )->a( n = `text`  t = temp7
        )->a( n = `press` v = client->_event( cs_event-cancel ) ).

    client->popup_display( lo_dialog->stringify( ) ).

  ENDMETHOD.

  METHOD render_value.

    DATA lo_field TYPE REF TO z2ui5_cl_ui5_view_builder.

    " a box per cell - the table maps its cells to the columns by index,
    " and the box is one cell whichever field it holds
    DATA lo_cell TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA lv_bind TYPE string.
          DATA temp79 TYPE string.
          DATA temp80 TYPE string_table.
    lo_cell = node->ele( `VBox` ).
    IF part = cs_part-high.
      lo_cell->a( n = `visible` v = `{= ${OPTION} === 'BT' || ${OPTION} === 'NB' }` ).
    ENDIF.

    lv_bind = |\{{ part }\}|.

    CASE ms_setting-control.
      WHEN cs_control-date.
        lo_field = lo_cell->ele( `DatePicker`
            )->a( n = `value`         v = lv_bind
            )->a( n = `valueFormat`   v = `yyyyMMdd`
            )->a( n = `displayFormat` v = `medium` ).
      WHEN cs_control-time.
        lo_field = lo_cell->ele( `TimePicker`
            )->a( n = `value`         v = lv_bind
            )->a( n = `valueFormat`   v = `HHmmss`
            )->a( n = `displayFormat` v = `HH:mm:ss` ).
      WHEN OTHERS.
        lo_field = lo_cell->ele( `Input`
            )->a( n = `value` v = lv_bind ).
        IF ms_setting-max_length > 0.

          temp79 = ms_setting-max_length.
          lo_field->a( n = `maxLength` t = temp79 ).
        ENDIF.
        IF ms_setting-value_help = abap_true.

          CLEAR temp80.
          INSERT `${KEY}` INTO TABLE temp80.
          INSERT part INTO TABLE temp80.
          lo_field->a( n = `showValueHelp`    b = abap_true
              )->a( n = `valueHelpRequest` v = client->_event( val   = cs_event-f4
                                                               t_arg = temp80 ) ).
        ENDIF.
    ENDCASE.

    lo_field->a( n = `width` v = `100%` ).

  ENDMETHOD.

ENDCLASS.
