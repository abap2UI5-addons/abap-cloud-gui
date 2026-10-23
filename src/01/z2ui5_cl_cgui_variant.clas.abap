"! Selection variants - the values of a selection screen under a name, the
"! classic variant of a report. A variant holds every field of the screen:
"! a parameter as one value, a select-option as its lines. The variants of
"! a report form its catalog, which z2ui5_cl_cgui_report keeps in the
"! browser's local storage - this class reads the fields out of the app,
"! writes them back, and turns the catalog into the string that is stored.
CLASS z2ui5_cl_cgui_variant DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF cs_kind,
        parameter     TYPE string VALUE `P`,
        select_option TYPE string VALUE `S`,
      END OF cs_kind.

    CONSTANTS:
      "! the dynamic dates of a variant - TODAY also with an offset in days,
      "! TODAY-1 or TODAY+7
      BEGIN OF cs_dynamic,
        today            TYPE string VALUE `TODAY`,
        month_start      TYPE string VALUE `MONTH_START`,
        month_end        TYPE string VALUE `MONTH_END`,
        prev_month_start TYPE string VALUE `PREV_MONTH_START`,
        prev_month_end   TYPE string VALUE `PREV_MONTH_END`,
        year_start       TYPE string VALUE `YEAR_START`,
        year_end         TYPE string VALUE `YEAR_END`,
      END OF cs_dynamic.

    "! the date a dynamic date stands for on date today (the system date
    "! when empty) - initial for an unknown one
    CLASS-METHODS dynamic_date
      IMPORTING
        dynamic       TYPE clike
        today         TYPE d OPTIONAL
      RETURNING
        VALUE(result) TYPE d.

    "! the dynamic dates with their texts - what a variant offers for a date
    CLASS-METHODS dynamic_values
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_selscreen=>ty_t_value.

    TYPES:
      "! one value of a variant: a parameter has one line with its value in
      "! low, a select-option one line per range line - and one line without
      "! sign when it is empty, so that loading the variant clears it
      BEGIN OF ty_s_value,
        name   TYPE string,
        kind   TYPE string,
        sign   TYPE string,
        option TYPE string,
        low    TYPE string,
        high   TYPE string,
        " a dynamic date - cs_dynamic, TODAY-3 / TODAY+7 - resolved into low
        " and high whenever the variant is loaded
        dynamic      TYPE string,
        dynamic_high TYPE string,
      END OF ty_s_value.
    TYPES ty_t_value TYPE STANDARD TABLE OF ty_s_value WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_variant,
        name      TYPE string,
        text      TYPE string,
        values    TYPE ty_t_value,
        " shared: other users see the variant, protected: only the owner
        " changes or deletes it - kept by a server store
        shared    TYPE abap_bool,
        protected TYPE abap_bool,
        owner     TYPE string,
        " the attributes of the fields: protect - shown but not ready for
        " input, hide - not shown (the classic variant attributes)
        protect   TYPE string_table,
        hide      TYPE string_table,
      END OF ty_s_variant.
    TYPES ty_t_variant TYPE STANDARD TABLE OF ty_s_variant WITH EMPTY KEY.

    "! the current values of the attributes names of app
    CLASS-METHODS values_get
      IMPORTING
        app           TYPE REF TO object
        names         TYPE string_table
      RETURNING
        VALUE(result) TYPE ty_t_value.

    "! write values into the attributes of app - a value whose attribute is
    "! gone or no longer fits is left out
    CLASS-METHODS values_set
      IMPORTING
        app    TYPE REF TO object
        values TYPE ty_t_value.

    "! the lines of a range as the values of the select-option name - one
    "! line per range line, one without sign when the range is empty (so
    "! that values_set( ) clears it); what SUBMIT ... WITH s IN range hands over
    CLASS-METHODS range_lines_get
      IMPORTING
        name          TYPE string
        range         TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE ty_t_value.

    "! the values of a selection table as SUBMIT ... WITH SELECTION-TABLE
    "! takes it - lines with selname, kind, sign, option, low and high
    "! (RSPARAMS); the lines without a selname are skipped
    CLASS-METHODS selection_table_get
      IMPORTING
        table         TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE ty_t_value.

    "! a one-line summary of the filled values - the text of a variant.
    "! fields gives the labels to show instead of the attribute names
    CLASS-METHODS values_to_text
      IMPORTING
        values        TYPE ty_t_value
        fields        TYPE z2ui5_cl_cgui_selscreen=>ty_t_field OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    "! the catalog as the string that is stored
    CLASS-METHODS catalog_to_string
      IMPORTING
        variants      TYPE ty_t_variant
      RETURNING
        VALUE(result) TYPE string.

    "! the catalog back from the stored string - empty when it cannot be read
    CLASS-METHODS catalog_from_string
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_variant.

    "! the argument of the STORE_DATA frontend action that writes val under
    "! prefix and key into the browser's local storage - composed as JSON:
    "! the action takes one argument and destructures it as TYPE, PREFIX,
    "! KEY and VALUE
    CLASS-METHODS storage_json
      IMPORTING
        prefix        TYPE clike
        key           TYPE clike
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS json_escape
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_variant IMPLEMENTATION.

  METHOD values_get.

    FIELD-SYMBOLS <attri> TYPE any.
    FIELD-SYMBOLS <range> TYPE ANY TABLE.

    LOOP AT names INTO DATA(lv_name).
      UNASSIGN <attri>.
      ASSIGN app->(lv_name) TO <attri>.
      IF <attri> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      IF cl_abap_typedescr=>describe_by_data( <attri> )->kind = cl_abap_typedescr=>kind_table.
        ASSIGN <attri> TO <range>.
        INSERT LINES OF range_lines_get( name  = lv_name
                                         range = <range> ) INTO TABLE result.
      ELSE.
        INSERT VALUE #( name = lv_name
                        kind = cs_kind-parameter
                        low  = <attri> ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD range_lines_get.

    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    DATA ls_value TYPE ty_s_value.

    LOOP AT range ASSIGNING <line>.
      CLEAR ls_value.
      ls_value-name = name.
      ls_value-kind = cs_kind-select_option.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-sign = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-option = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-low = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-high = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      INSERT ls_value INTO TABLE result.
    ENDLOOP.

    IF result IS INITIAL.
      INSERT VALUE #( name = name
                      kind = cs_kind-select_option ) INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD values_set.

    FIELD-SYMBOLS <attri> TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <comp>  TYPE any.
    DATA lr_line   TYPE REF TO data.
    DATA lv_last   TYPE string.

    DATA ls_value TYPE ty_s_value.

    LOOP AT values INTO ls_value.
      DATA(lr_value) = REF #( ls_value ).
      IF ls_value-dynamic IS NOT INITIAL.
        ls_value-low = dynamic_date( ls_value-dynamic ).
      ENDIF.
      IF ls_value-dynamic_high IS NOT INITIAL.
        ls_value-high = dynamic_date( ls_value-dynamic_high ).
      ENDIF.
      UNASSIGN <attri>.
      ASSIGN app->(lr_value->name) TO <attri>.
      IF <attri> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      TRY.
          " the attribute decides whether the value is a parameter or a
          " range line - SUBMIT ... WITH p = v names a select-option like a
          " parameter, and a caller does not know the called report
          IF cl_abap_typedescr=>describe_by_data( <attri> )->kind <> cl_abap_typedescr=>kind_table.
            IF lr_value->kind = cs_kind-parameter OR lr_value->sign IS NOT INITIAL.
              <attri> = lr_value->low.
            ENDIF.
            CONTINUE.
          ENDIF.

          ASSIGN <attri> TO <range>.
          " the first line of a select-option clears it
          IF lr_value->name <> lv_last.
            CLEAR <range>.
            lv_last = lr_value->name.
          ENDIF.
          IF lr_value->kind = cs_kind-parameter.
            IF lr_value->sign IS INITIAL.
              lr_value->sign = `I`.
            ENDIF.
            IF lr_value->option IS INITIAL.
              lr_value->option = `EQ`.
            ENDIF.
          ENDIF.
          IF lr_value->sign IS INITIAL.
            CONTINUE.
          ENDIF.

          CREATE DATA lr_line LIKE LINE OF <range>.
          ASSIGN lr_line->* TO <line>.
          ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
          <comp> = lr_value->sign.
          ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
          <comp> = lr_value->option.
          ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
          <comp> = lr_value->low.
          ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
          <comp> = lr_value->high.
          INSERT <line> INTO TABLE <range>.
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.

  METHOD selection_table_get.

    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    DATA ls_value TYPE ty_s_value.

    LOOP AT table ASSIGNING <line>.
      CLEAR ls_value.
      ASSIGN COMPONENT `SELNAME` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS NOT ASSIGNED OR <comp> IS INITIAL.
        UNASSIGN <comp>.
        CONTINUE.
      ENDIF.
      ls_value-name = to_upper( <comp> ).
      UNASSIGN <comp>.
      ASSIGN COMPONENT `KIND` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-kind = COND #( WHEN <comp> = cs_kind-parameter THEN cs_kind-parameter ELSE cs_kind-select_option ).
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-sign = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-option = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-low = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <comp>.
      IF <comp> IS ASSIGNED.
        ls_value-high = <comp>.
      ENDIF.
      UNASSIGN <comp>.
      INSERT ls_value INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD values_to_text.

    DATA lv_part TYPE string.
    DATA lv_name TYPE string.

    LOOP AT values REFERENCE INTO DATA(lr_value)
         WHERE low IS NOT INITIAL OR high IS NOT INITIAL.
      lv_name = lr_value->name.
      READ TABLE fields REFERENCE INTO DATA(lr_field) WITH KEY name = lr_value->name.
      IF sy-subrc = 0 AND lr_field->text IS NOT INITIAL.
        lv_name = lr_field->text.
      ENDIF.

      IF lr_value->high IS INITIAL.
        lv_part = |{ lv_name } { lr_value->option } { lr_value->low }|.
      ELSE.
        lv_part = |{ lv_name } { lr_value->option } { lr_value->low } - { lr_value->high }|.
      ENDIF.
      IF lr_value->kind = cs_kind-parameter.
        lv_part = |{ lv_name } = { lr_value->low }|.
      ELSEIF lr_value->sign = `E`.
        lv_part = |{ lv_part } (excl.)|.
      ENDIF.
      CONDENSE lv_part.

      IF result IS INITIAL.
        result = lv_part.
      ELSE.
        result = |{ result }, { lv_part }|.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD dynamic_date.

    DATA lv_offset TYPE i.

    DATA(lv_today) = today.
    IF lv_today IS INITIAL.
      lv_today = sy-datum.
    ENDIF.
    DATA(lv_dynamic) = to_upper( condense( dynamic ) ).

    IF lv_dynamic CP |{ cs_dynamic-today }*|.
      DATA(lv_rest) = substring( val = lv_dynamic
                                 off = strlen( cs_dynamic-today ) ).
      IF lv_rest IS INITIAL.
        result = lv_today.
        RETURN.
      ENDIF.
      TRY.
          lv_offset = condense( substring( val = lv_rest off = 1 ) ).
        CATCH cx_root.
          RETURN.
      ENDTRY.
      CASE lv_rest(1).
        WHEN `+`.
          result = lv_today + lv_offset.
        WHEN `-`.
          result = lv_today - lv_offset.
      ENDCASE.
      RETURN.
    ENDIF.

    CASE lv_dynamic.
      WHEN cs_dynamic-month_start.
        result = |{ lv_today(6) }01|.
      WHEN cs_dynamic-month_end.
        result = |{ lv_today(6) }01|.
        result = result + 31.
        result = |{ result(6) }01|.
        result = result - 1.
      WHEN cs_dynamic-prev_month_start.
        result = |{ lv_today(6) }01|.
        result = result - 1.
        result = |{ result(6) }01|.
      WHEN cs_dynamic-prev_month_end.
        result = |{ lv_today(6) }01|.
        result = result - 1.
      WHEN cs_dynamic-year_start.
        result = |{ lv_today(4) }0101|.
      WHEN cs_dynamic-year_end.
        result = |{ lv_today(4) }1231|.
    ENDCASE.

  ENDMETHOD.

  METHOD dynamic_values.

    result = VALUE #( ( key = cs_dynamic-today            text = CONV #( 'Today'(001) ) )
                      ( key = |{ cs_dynamic-today }-1|    text = CONV #( 'Yesterday'(002) ) )
                      ( key = cs_dynamic-month_start      text = CONV #( 'First day of the month'(003) ) )
                      ( key = cs_dynamic-month_end        text = CONV #( 'Last day of the month'(004) ) )
                      ( key = cs_dynamic-prev_month_start text = CONV #( 'First day of the previous month'(005) ) )
                      ( key = cs_dynamic-prev_month_end   text = CONV #( 'Last day of the previous month'(006) ) )
                      ( key = cs_dynamic-year_start       text = CONV #( 'First day of the year'(007) ) )
                      ( key = cs_dynamic-year_end         text = CONV #( 'Last day of the year'(008) ) ) ).

  ENDMETHOD.

  METHOD catalog_to_string.

    CALL TRANSFORMATION id SOURCE variants = variants RESULT XML result.

  ENDMETHOD.

  METHOD catalog_from_string.

    IF val IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        CALL TRANSFORMATION id SOURCE XML val RESULT variants = result.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD storage_json.

    result = |\{"TYPE":"local","PREFIX":"{ json_escape( |{ prefix }| ) }",| &&
             |"KEY":"{ json_escape( |{ key }| ) }","VALUE":"{ json_escape( val ) }"\}|.

  ENDMETHOD.

  METHOD json_escape.

    " the backslash first, or it would escape the escapes added after it
    result = replace( val = val    sub = `\`  with = `\\` occ = 0 ).
    result = replace( val = result sub = |\n| with = `\n`  occ = 0 ).
    result = replace( val = result sub = |\r| with = `\r`  occ = 0 ).
    result = replace( val = result sub = |\t| with = `\t`  occ = 0 ).
    result = replace( val = result sub = `"`  with = `\"`  occ = 0 ).

  ENDMETHOD.

ENDCLASS.
