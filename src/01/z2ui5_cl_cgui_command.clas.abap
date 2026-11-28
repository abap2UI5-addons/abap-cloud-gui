"! The URL and the command field of a report: the parameters of the URL
"! the report starts with (the values of the selection screen, a
"! select-option as A,B..C,!D), the link that starts the report again with
"! its values (get_link( )), the commands of the command field - /nTCODE,
"! /oTCODE, a transaction of the catalog, an OK code of the screen -, the
"! rows of the command palette and the keyboard shortcuts of a screen.
"! Stateless, as z2ui5_cl_cgui_memory: a call takes what it reads of the
"! report as ty_s_ctx, built by the report on the spot (command_ctx( )) and
"! kept by nobody. What navigates, opens a popup or shows a message stays
"! in the report: a method here answers what a command asks for, the report
"! does it.
CLASS z2ui5_cl_cgui_command DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      "! a keyboard shortcut of the screen - the key and the function
      BEGIN OF ty_s_shortcut,
        key   TYPE string,
        ucomm TYPE string,
      END OF ty_s_shortcut.
    TYPES ty_t_shortcut TYPE STANDARD TABLE OF ty_s_shortcut WITH DEFAULT KEY.

    TYPES:
      "! the state of the report a call reads: the client, the key of the
      "! report - the name of the class -, the catalog of the transactions
      "! (unbound: none), the screen that is shown, whether the command
      "! field is on, the fields of the selection screen, the values of the
      "! URL (written by url_values_get( )), the function keys of the
      "! screen, the GUI controls, the keys of SET PF-STATUS and the
      "! functions excluded on the output
      BEGIN OF ty_s_ctx,
        app       TYPE REF TO object,
        client    TYPE REF TO z2ui5_if_client,
        key       TYPE string,
        catalog   TYPE REF TO z2ui5_if_cgui_catalog,
        selection TYPE abap_bool,
        output    TYPE abap_bool,
        cmd_on    TYPE abap_bool,
        fields    TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_t_field,
        url       TYPE REF TO z2ui5_cl_cgui_variant=>ty_t_value,
        fkeys     TYPE z2ui5_cl_cgui_selscreen=>ty_t_function_key,
        gui       TYPE REF TO z2ui5_if_cgui_gui=>ty_t_control,
        pf_keys   TYPE ty_t_shortcut,
        excl_out  TYPE string_table,
      END OF ty_s_ctx.

    TYPES:
      "! a row of the command palette
      BEGIN OF ty_s_palette,
        command TYPE c LENGTH 40,
        text    TYPE c LENGTH 80,
      END OF ty_s_palette.
    TYPES ty_t_palette TYPE STANDARD TABLE OF ty_s_palette WITH DEFAULT KEY.

    CONSTANTS:
      "! what a command of the field asks for
      BEGIN OF cs_okcode,
        "! start a report here - target is the transaction or the class
        start     TYPE string VALUE `START`,
        "! start a report in a new browser tab
        start_new TYPE string VALUE `START_NEW`,
        "! /x - not a command
        unknown   TYPE string VALUE `UNKNOWN`,
        "! an OK code of the screen - code
        ucomm     TYPE string VALUE `UCOMM`,
      END OF cs_okcode.

    TYPES:
      "! a command of the field, read: kind of cs_okcode, code - the command
      "! in upper case -, target - the transaction or class to start
      BEGIN OF ty_s_okcode,
        kind   TYPE string,
        code   TYPE string,
        target TYPE string,
      END OF ty_s_okcode.

    TYPES:
      "! a report to start: the class and the variant the catalog names for
      "! the transaction, the instance when the class exists (unbound: the
      "! transaction does not exist)
      BEGIN OF ty_s_start,
        report  TYPE string,
        variant TYPE string,
        app     TYPE REF TO object,
      END OF ty_s_start.

    "! the parameters of the URL - the component parameters of the app and
    "! the query, the names in upper case, the query decoded
    CLASS-METHODS url_params
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

    CLASS-METHODS url_param
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS url_decode
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! a select-option of the URL - A,B (EQ), A..B (BT), A* (CP), !A (E),
    "! &gt;=A, &lt;=A, &gt;A, &lt;A, &lt;&gt;A - as values of a variant
    CLASS-METHODS url_range
      IMPORTING
        name          TYPE string
        val           TYPE string
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    CLASS-METHODS url_from_range
      IMPORTING
        values        TYPE z2ui5_cl_cgui_variant=>ty_t_value
      RETURNING
        VALUE(result) TYPE string.

    "! the values of the URL for the fields of the screen - into ctx-url
    CLASS-METHODS url_values_get
      IMPORTING
        ctx TYPE ty_s_ctx.

    "! the values of the URL into the fields of the report
    CLASS-METHODS url_values_apply
      IMPORTING
        ctx TYPE ty_s_ctx.

    "! the URL that starts the report with the values of the selection screen
    "! - run straight away with skip_screen
    CLASS-METHODS link
      IMPORTING
        ctx           TYPE ty_s_ctx
        skip_screen   TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string.

    "! a command of the field, read - /n and /o start a transaction here or
    "! in a new browser tab, alone this report again (key); a transaction
    "! of the catalog starts; the rest is an OK code of the screen
    CLASS-METHODS okcode_parse
      IMPORTING
        code          TYPE string
        key           TYPE string
        catalog       TYPE REF TO z2ui5_if_cgui_catalog
      RETURNING
        VALUE(result) TYPE ty_s_okcode.

    "! the report a transaction starts: resolved in the catalog, created
    "! when it is a class - what does not exist fails here, also for a new
    "! tab
    CLASS-METHODS start_resolve
      IMPORTING
        code          TYPE string
        catalog       TYPE REF TO z2ui5_if_cgui_catalog
      RETURNING
        VALUE(result) TYPE ty_s_start.

    "! the transaction of the catalog with this code, the code compared in
    "! upper case - initial when the catalog has none (or is unbound)
    CLASS-METHODS tcode_find
      IMPORTING
        code          TYPE string
        catalog       TYPE REF TO z2ui5_if_cgui_catalog
      RETURNING
        VALUE(result) TYPE z2ui5_if_cgui_catalog=>ty_s_transaction.

    "! the URL of this app with another report to start in a new tab - the
    "! client and the language stay
    CLASS-METHODS start_url
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
        report        TYPE string
        variant       TYPE string
      RETURNING
        VALUE(result) TYPE string.

    "! the rows of the command palette - the transactions of the catalog,
    "! the function keys of the screen, the standard commands
    CLASS-METHODS palette_rows
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE ty_t_palette.

    "! the keyboard shortcuts of the screen: F8 Execute and F3 Back as in
    "! the SAP GUI, F1 and F4 of a text editor that registered them, Ctrl+K
    "! for the palette, the function keys of SET PF-STATUS on the output
    CLASS-METHODS shortcuts
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE ty_t_shortcut.

  PROTECTED SECTION.

  PRIVATE SECTION.
    "! a report class, created by its name - unbound when no class of that
    "! name inherits from z2ui5_cl_cgui_report: another class is not even
    "! created, its constructor may want parameters or do anything
    CLASS-METHODS report_create
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO object.

    "! the query of the URL, parameter by parameter
    CLASS-METHODS url_search
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE string_table.

ENDCLASS.


CLASS z2ui5_cl_cgui_command IMPLEMENTATION.

  METHOD url_search.

    DATA lv_search TYPE z2ui5_if_client=>ty_s_get-s_config-search.
    lv_search = client->get( )-s_config-search.
    IF lv_search IS NOT INITIAL AND lv_search(1) = `?`.
      lv_search = lv_search+1.
    ENDIF.
    SPLIT lv_search AT `&` INTO TABLE result.
    DELETE result WHERE table_line IS INITIAL.

  ENDMETHOD.

  METHOD url_params.

    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.

    DATA temp1 TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_comp LIKE LINE OF temp1.
      DATA temp2 TYPE z2ui5_if_client=>ty_s_name_value.
    DATA temp3 TYPE string_table.
    DATA lv_param LIKE LINE OF temp3.
      DATA temp4 LIKE sy-subrc.
      DATA temp5 TYPE z2ui5_if_client=>ty_s_name_value.
    temp1 = client->get( )-t_comp_params.

    LOOP AT temp1 INTO ls_comp.

      CLEAR temp2.
      temp2-n = to_upper( ls_comp-n ).
      temp2-v = ls_comp-v.
      INSERT temp2 INTO TABLE result.
    ENDLOOP.


    temp3 = url_search( client ).

    LOOP AT temp3 INTO lv_param.
      CLEAR: lv_name, lv_value.
      SPLIT lv_param AT `=` INTO lv_name lv_value.
      lv_name = to_upper( url_decode( lv_name ) ).

      READ TABLE result WITH KEY n = lv_name TRANSPORTING NO FIELDS.
      temp4 = sy-subrc.
      IF temp4 = 0.
        CONTINUE.
      ENDIF.

      CLEAR temp5.
      temp5-n = lv_name.
      temp5-v = url_decode( lv_value ).
      INSERT temp5 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD url_param.

    DATA lt_param TYPE z2ui5_if_client=>ty_t_name_value.
    DATA lv_name TYPE string.
    DATA ls_param TYPE z2ui5_if_client=>ty_s_name_value.
    lt_param = url_params( client ).

    lv_name = to_upper( name ).

    READ TABLE lt_param INTO ls_param WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_param-v.
    ENDIF.

  ENDMETHOD.

  METHOD url_decode.

    DATA lv_hex  TYPE x LENGTH 1.
    DATA lv_xstr TYPE xstring.
    DATA lv_char TYPE xstring.
    DATA lv_in LIKE result.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
        DATA lv_digits TYPE string.
    DATA lv_text TYPE string.

    result = replace( val = val sub = `+` with = ` ` occ = 0 ).
    IF result NA `%`.
      RETURN.
    ENDIF.

    " %XX are the bytes of UTF-8

    lv_in = result.

    lv_len = strlen( lv_in ).

    lv_pos = 0.
    WHILE lv_pos < lv_len.
      IF lv_in+lv_pos(1) = `%` AND lv_pos + 3 <= lv_len.

        lv_digits = to_upper( substring( val = lv_in off = lv_pos + 1 len = 2 ) ).
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


    lv_text = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( lv_xstr ).
    IF lv_text IS NOT INITIAL.
      result = lv_text.
    ENDIF.

  ENDMETHOD.

  METHOD url_range.

    DATA lt_part TYPE string_table.
    DATA ls_value TYPE z2ui5_cl_cgui_variant=>ty_s_value.
    DATA lv_part LIKE LINE OF lt_part.
      DATA temp6 TYPE z2ui5_cl_cgui_variant=>ty_s_value.

    SPLIT val AT `,` INTO TABLE lt_part.

    LOOP AT lt_part INTO lv_part.
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

      CLEAR temp6.
      temp6-name = name.
      temp6-kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
      INSERT temp6 INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD url_from_range.

    DATA lv_part TYPE string.
    DATA lv_sign TYPE string.

    DATA temp7 LIKE LINE OF values.
    DATA lr_value LIKE REF TO temp7.
          DATA temp8 TYPE string.
          DATA temp9 TYPE string.
    LOOP AT values REFERENCE INTO lr_value WHERE sign IS NOT INITIAL.
      lv_sign = lr_value->sign.
      CASE lr_value->option.
        WHEN `BT`.
          lv_part = |{ lr_value->low }..{ lr_value->high }|.
        " the URL has no NB or NP - I NB is E BT, I NP is E CP
        WHEN `NB`.
          lv_part = |{ lr_value->low }..{ lr_value->high }|.

          IF lv_sign = `E`.
            temp8 = `I`.
          ELSE.
            temp8 = `E`.
          ENDIF.
          lv_sign = temp8.
        WHEN `NP`.
          lv_part = lr_value->low.

          IF lv_sign = `E`.
            temp9 = `I`.
          ELSE.
            temp9 = `E`.
          ENDIF.
          lv_sign = temp9.
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
      IF lv_sign = `E`.
        lv_part = |!{ lv_part }|.
      ENDIF.
      IF result IS INITIAL.
        result = lv_part.
      ELSE.
        result = |{ result },{ lv_part }|.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD url_values_get.

    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <url>    TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lt_param TYPE z2ui5_if_client=>ty_t_name_value.
    DATA temp10 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp10.
      DATA ls_param TYPE z2ui5_if_client=>ty_s_name_value.
        DATA temp11 TYPE z2ui5_cl_cgui_variant=>ty_s_value.

    ASSIGN ctx-fields->* TO <fields>.
    ASSIGN ctx-url->* TO <url>.

    " only fields of the screen the user could fill himself - no NO-DISPLAY
    " field and nothing else of the class is set from the URL
    CLEAR <url>.

    lt_param = url_params( ctx-client ).



    LOOP AT <fields> REFERENCE INTO lr_field WHERE no_display = abap_false.

      READ TABLE lt_param INTO ls_param WITH KEY n = lr_field->name.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        INSERT LINES OF url_range( name = lr_field->name
                                   val  = ls_param-v ) INTO TABLE <url>.
      ELSE.

        CLEAR temp11.
        temp11-name = lr_field->name.
        temp11-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
        temp11-low = ls_param-v.
        INSERT temp11 INTO TABLE <url>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD url_values_apply.

    FIELD-SYMBOLS <url> TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    ASSIGN ctx-url->* TO <url>.
    IF <url> IS NOT INITIAL.
      z2ui5_cl_cgui_variant=>values_set( app    = ctx-app
                                         values = <url> ).
    ENDIF.

  ENDMETHOD.

  METHOD link.

    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA lt_name  TYPE string_table.
    DATA lt_keep  TYPE string_table.
    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.
    DATA lv_search TYPE z2ui5_if_client=>ty_s_get-s_config-search.
    DATA temp12 TYPE string_table.
    DATA lv_param LIKE LINE OF temp12.
      DATA temp13 LIKE sy-subrc.
    DATA lv_app_start TYPE string.
    DATA temp14 LIKE sy-subrc.
    DATA temp15 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp15.
    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
      DATA temp16 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
      DATA ls_v LIKE LINE OF lt_value.
      DATA lt_field_value LIKE temp16.
        DATA temp18 TYPE string.
        DATA temp19 TYPE z2ui5_cl_cgui_variant=>ty_s_value.
      DATA temp20 LIKE LINE OF lt_keep.
      DATA temp21 LIKE LINE OF lt_keep.

    ASSIGN ctx-fields->* TO <fields>.

    " the parameters of the URL that are no field of the screen stay - the
    " app to start, the client, the language

    lv_search = ctx-client->get( )-s_config-search.

    temp12 = url_search( ctx-client ).

    LOOP AT temp12 INTO lv_param.
      CLEAR: lv_name, lv_value.
      SPLIT lv_param AT `=` INTO lv_name lv_value.
      lv_name = to_upper( url_decode( lv_name ) ).
      " ctx-fields->* rather than <fields>: transpiler 2.14.35 hands the
      " field symbol itself to the table expression (getRowType is not a
      " function) - the same table, read through the typed reference

      READ TABLE ctx-fields->* WITH KEY name = lv_name TRANSPORTING NO FIELDS.
      temp13 = sy-subrc.
      IF temp13 = 0 OR lv_name = z2ui5_cl_cgui_report=>cv_cgui_url_skip OR lv_name = `VARIANT`.
        CONTINUE.
      ENDIF.
      INSERT lv_param INTO TABLE lt_keep.
    ENDLOOP.
    " a variable, not the template - a WITH KEY operand on 7.02

    lv_app_start = |app_start={ to_lower( ctx-key ) }|.

    READ TABLE lt_keep WITH KEY table_line = lv_app_start TRANSPORTING NO FIELDS.
    temp14 = sy-subrc.
    IF NOT temp14 = 0
        AND lv_search NS `app_start`.
      INSERT lv_app_start INTO TABLE lt_keep.
    ENDIF.



    LOOP AT <fields> REFERENCE INTO lr_field WHERE no_display = abap_false.
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.

    lt_value = z2ui5_cl_cgui_variant=>values_get( app   = ctx-app
                                                        names = lt_name ).

    LOOP AT <fields> REFERENCE INTO lr_field WHERE no_display = abap_false.

      CLEAR temp16.

      LOOP AT lt_value INTO ls_v WHERE name = lr_field->name.
        INSERT ls_v INTO TABLE temp16.
      ENDLOOP.

      lt_field_value = temp16.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        lv_value = url_from_range( lt_field_value ).
      ELSE.

        CLEAR temp18.

        READ TABLE lt_field_value INTO temp19 INDEX 1.
        IF sy-subrc = 0.
          temp18 = temp19-low.
        ENDIF.
        lv_value = temp18.
      ENDIF.
      IF lv_value IS INITIAL.
        CONTINUE.
      ENDIF.

      temp20 = |{ to_lower( lr_field->name ) }={ z2ui5_cl_cgui_context=>url_escape( lv_value ) }|.
      INSERT temp20 INTO TABLE lt_keep.
    ENDLOOP.
    IF skip_screen = abap_true.

      temp21 = |{ to_lower( z2ui5_cl_cgui_report=>cv_cgui_url_skip ) }=X|.
      INSERT temp21 INTO TABLE lt_keep.
    ENDIF.

    result = |{ ctx-client->get( )-s_config-origin }{ ctx-client->get( )-s_config-pathname }?{ concat_lines_of( table = lt_keep sep = `&` ) }|.

  ENDMETHOD.

  METHOD okcode_parse.

    result-code = to_upper( code ).

    " /n and /o: a transaction here or in a new browser tab - alone, this
    " report again
    IF strlen( result-code ) >= 2 AND result-code(1) = `/`.
      result-target = condense( substring( val = result-code off = 2 ) ).
      IF result-target IS INITIAL.
        result-target = key.
      ENDIF.
      CASE result-code+1(1).
        WHEN `N`.
          result-kind = cs_okcode-start.
        WHEN `O`.
          result-kind = cs_okcode-start_new.
        WHEN OTHERS.
          result-kind = cs_okcode-unknown.
      ENDCASE.
      RETURN.
    ENDIF.

    " a transaction of the catalog
    IF tcode_find( code    = result-code
                   catalog = catalog ) IS NOT INITIAL.
      result-kind = cs_okcode-start.
      result-target = result-code.
      RETURN.
    ENDIF.

    " else an OK code of the screen
    result-kind = cs_okcode-ucomm.

  ENDMETHOD.

  METHOD start_resolve.
    DATA ls_tcode TYPE z2ui5_if_cgui_catalog=>ty_s_transaction.

    result-report = code.

    ls_tcode = tcode_find( code    = code
                                 catalog = catalog ).
    IF ls_tcode IS NOT INITIAL.
      result-report = to_upper( ls_tcode-report ).
      result-variant = ls_tcode-variant.
    ENDIF.

    " a report class - nothing else starts from the command field
    result-app = report_create( result-report ).

  ENDMETHOD.

  METHOD tcode_find.
    DATA lv_code TYPE string.
    DATA temp22 TYPE z2ui5_if_cgui_catalog=>ty_t_transaction.
    DATA ls_tcode LIKE LINE OF temp22.

    IF catalog IS NOT BOUND.
      RETURN.
    ENDIF.

    lv_code = to_upper( condense( code ) ).

    temp22 = catalog->get( ).

    LOOP AT temp22 INTO ls_tcode.
      IF to_upper( condense( ls_tcode-code ) ) = lv_code.
        result = ls_tcode.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD report_create.

    " unbound - only its type is read: the name of the report runtime is
    " this class's own with REPORT for COMMAND, as a namespace rename
    " rewrites a reference, never a literal naming a class
    DATA lo_me    TYPE REF TO z2ui5_cl_cgui_command.
    DATA lo_super TYPE REF TO cl_abap_classdescr.

    DATA lv_name TYPE string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA temp23 TYPE REF TO cl_abap_refdescr.
    DATA lv_me TYPE string.
    DATA lv_base TYPE string.
    DATA temp24 TYPE REF TO cl_abap_classdescr.
    DATA lo_class LIKE temp24.
    lv_name = to_upper( condense( name ) ).
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = lv_name
                                         RECEIVING  p_descr_ref    = lo_type
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0 OR lo_type IS NOT BOUND OR lo_type->kind <> cl_abap_typedescr=>kind_class.
      RETURN.
    ENDIF.

    " a subclass of the report runtime - checked before anything is created

    temp23 ?= cl_abap_typedescr=>describe_by_data( lo_me ).

    lv_me = temp23->get_referenced_type( )->get_relative_name( ).

    lv_base = |{ substring( val = lv_me
                                  len = strlen( lv_me ) - strlen( `COMMAND` ) ) }REPORT|.

    temp24 ?= lo_type.

    lo_class = temp24.
    WHILE lo_class->get_relative_name( ) <> lv_base.
      lo_class->get_super_class_type( RECEIVING  p_descr_ref           = lo_super
                                      EXCEPTIONS super_class_not_found = 1
                                                 OTHERS                = 2 ).
      IF sy-subrc <> 0 OR lo_super IS NOT BOUND.
        RETURN.
      ENDIF.
      lo_class = lo_super.
    ENDWHILE.

    TRY.
        CREATE OBJECT result TYPE (lv_name).
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD start_url.

    DATA lt_keep TYPE string_table.

    DATA temp25 TYPE string_table.
    DATA lv_param LIKE LINE OF temp25.
    DATA temp26 LIKE LINE OF lt_keep.
      DATA temp27 LIKE LINE OF lt_keep.
    temp25 = url_search( client ).

    LOOP AT temp25 INTO lv_param.
      IF to_upper( segment( val = lv_param index = 1 sep = `=` ) ) = `APP_START`
          OR to_upper( segment( val = lv_param index = 1 sep = `=` ) ) = `VARIANT`.
        CONTINUE.
      ENDIF.
      INSERT lv_param INTO TABLE lt_keep.
    ENDLOOP.

    temp26 = |app_start={ to_lower( report ) }|.
    INSERT temp26 INTO TABLE lt_keep.
    IF variant IS NOT INITIAL.

      temp27 = |variant={ z2ui5_cl_cgui_context=>url_escape( variant ) }|.
      INSERT temp27 INTO TABLE lt_keep.
    ENDIF.
    result = |{ client->get( )-s_config-origin }{ client->get( )-s_config-pathname }?| &&
             concat_lines_of( table = lt_keep sep = `&` ).

  ENDMETHOD.

  METHOD palette_rows.
      DATA temp28 TYPE z2ui5_if_cgui_catalog=>ty_t_transaction.
      DATA ls_tcode LIKE LINE OF temp28.
        DATA temp29 TYPE z2ui5_cl_cgui_command=>ty_s_palette.
    DATA ls_fkey LIKE LINE OF ctx-fkeys.
      DATA temp30 TYPE z2ui5_cl_cgui_command=>ty_s_palette.
      DATA temp31 TYPE z2ui5_cl_cgui_command=>ty_s_palette.
      DATA temp32 TYPE z2ui5_cl_cgui_command=>ty_s_palette.
    DATA temp33 TYPE z2ui5_cl_cgui_command=>ty_s_palette.
    DATA temp34 TYPE z2ui5_cl_cgui_command=>ty_s_palette.

    IF ctx-catalog IS BOUND.

      temp28 = ctx-catalog->get( ).

      LOOP AT temp28 INTO ls_tcode.

        CLEAR temp29.
        temp29-command = to_upper( ls_tcode-code ).
        temp29-text = ls_tcode-text.
        INSERT temp29 INTO TABLE result.
      ENDLOOP.
    ENDIF.
    " the function keys of the screen

    LOOP AT ctx-fkeys INTO ls_fkey.

      CLEAR temp30.
      temp30-command = to_upper( ls_fkey-ucomm ).
      temp30-text = ls_fkey-text.
      INSERT temp30 INTO TABLE result.
    ENDLOOP.
    IF ctx-selection = abap_true.

      CLEAR temp31.
      temp31-command = `ONLI`.
      temp31-text = 'Execute'(001).
      INSERT temp31 INTO TABLE result.
    ELSEIF ctx-output = abap_true.

      CLEAR temp32.
      temp32-command = `PRI`.
      temp32-text = 'Print'(002).
      INSERT temp32 INTO TABLE result.
    ENDIF.

    CLEAR temp33.
    temp33-command = `/O`.
    temp33-text = 'This report in a new window'(003).
    INSERT temp33 INTO TABLE result.

    CLEAR temp34.
    temp34-command = `SU3`.
    temp34-text = 'User parameters'(004).
    INSERT temp34 INTO TABLE result.

  ENDMETHOD.

  METHOD shortcuts.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA lt_gui_key TYPE string_table.
    DATA temp35 TYPE z2ui5_cl_cgui_command=>ty_s_shortcut.
    DATA temp36 TYPE z2ui5_cl_cgui_command=>ty_s_shortcut.
    DATA ls_editor LIKE LINE OF <gui>.
      DATA lt_editor_key TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
      DATA lv_editor_key LIKE LINE OF lt_editor_key.
    DATA lv_gui_key LIKE LINE OF lt_gui_key.
      DATA temp37 TYPE z2ui5_cl_cgui_command=>ty_s_shortcut.
      DATA temp1 TYPE z2ui5_cl_cgui_command=>ty_s_shortcut-ucomm.
      DATA temp38 TYPE z2ui5_cl_cgui_command=>ty_s_shortcut.
      DATA temp39 TYPE z2ui5_cl_cgui_command=>ty_s_shortcut.
    DATA ls_key LIKE LINE OF ctx-pf_keys.
      DATA temp40 TYPE string.
      DATA temp2 LIKE sy-subrc.

    ASSIGN ctx-gui->* TO <gui>.

    " F8 Execute and F3 Back, as in the SAP GUI

    CLEAR temp35.
    temp35-key = `F8`.
    temp35-ucomm = z2ui5_cl_cgui_report=>cs_ucomm-execute.
    INSERT temp35 INTO TABLE result.

    CLEAR temp36.
    temp36-key = `F3`.
    temp36-ucomm = z2ui5_cl_cgui_report=>cs_ucomm-back.
    INSERT temp36 INTO TABLE result.
    " F1 and F4 of a text editor that registered them

    LOOP AT <gui> INTO ls_editor
         WHERE kind = z2ui5_if_cgui_gui=>cs_kind-textedit AND freed = abap_false AND keys IS NOT INITIAL.

      SPLIT ls_editor-keys AT `,` INTO TABLE lt_editor_key.

      LOOP AT lt_editor_key INTO lv_editor_key.
        INSERT lv_editor_key INTO TABLE lt_gui_key.
      ENDLOOP.
    ENDLOOP.
    SORT lt_gui_key.
    DELETE ADJACENT DUPLICATES FROM lt_gui_key.

    LOOP AT lt_gui_key INTO lv_gui_key.

      CLEAR temp37.
      temp37-key = lv_gui_key.

      IF lv_gui_key = `F1`.
        temp1 = z2ui5_cl_cgui_report=>cs_ucomm-gui_f1.
      ELSE.
        temp1 = z2ui5_cl_cgui_report=>cs_ucomm-gui_f4.
      ENDIF.
      temp37-ucomm = temp1.
      INSERT temp37 INTO TABLE result.
    ENDLOOP.

    " the command palette - with a command field or a catalog to search
    IF ctx-cmd_on = abap_true OR ctx-catalog IS BOUND.

      CLEAR temp38.
      temp38-key = `Ctrl+K`.
      temp38-ucomm = z2ui5_cl_cgui_report=>cs_ucomm-palette.
      INSERT temp38 INTO TABLE result.

      CLEAR temp39.
      temp39-key = `Meta+K`.
      temp39-ucomm = z2ui5_cl_cgui_report=>cs_ucomm-palette.
      INSERT temp39 INTO TABLE result.
    ENDIF.

    " the function keys of SET PF-STATUS, on the output only
    IF ctx-selection = abap_true.
      RETURN.
    ENDIF.

    LOOP AT ctx-pf_keys INTO ls_key.

      temp40 = to_upper( ls_key-ucomm ).

      READ TABLE ctx-excl_out WITH KEY table_line = temp40 TRANSPORTING NO FIELDS.
      temp2 = sy-subrc.
      IF temp2 = 0.
        CONTINUE.
      ENDIF.
      INSERT ls_key INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
