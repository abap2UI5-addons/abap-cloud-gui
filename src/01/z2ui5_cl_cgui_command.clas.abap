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
    TYPES ty_t_shortcut TYPE STANDARD TABLE OF ty_s_shortcut WITH EMPTY KEY.

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
    TYPES ty_t_palette TYPE STANDARD TABLE OF ty_s_palette WITH EMPTY KEY.

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
    "! the query of the URL, parameter by parameter
    CLASS-METHODS url_search
      IMPORTING
        client        TYPE REF TO z2ui5_if_client
      RETURNING
        VALUE(result) TYPE string_table.

ENDCLASS.


CLASS z2ui5_cl_cgui_command IMPLEMENTATION.

  METHOD url_search.

    DATA(lv_search) = client->get( )-s_config-search.
    IF lv_search IS NOT INITIAL AND lv_search(1) = `?`.
      lv_search = lv_search+1.
    ENDIF.
    SPLIT lv_search AT `&` INTO TABLE result.
    DELETE result WHERE table_line IS INITIAL.

  ENDMETHOD.

  METHOD url_params.

    DATA lv_name  TYPE string.
    DATA lv_value TYPE string.

    LOOP AT client->get( )-t_comp_params INTO DATA(ls_comp).
      INSERT VALUE #( n = to_upper( ls_comp-n )
                      v = ls_comp-v ) INTO TABLE result.
    ENDLOOP.

    LOOP AT url_search( client ) INTO DATA(lv_param).
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

    DATA(lt_param) = url_params( client ).
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

  METHOD url_values_get.

    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <url>    TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    ASSIGN ctx-fields->* TO <fields>.
    ASSIGN ctx-url->* TO <url>.

    " only fields of the screen the user could fill himself - no NO-DISPLAY
    " field and nothing else of the class is set from the URL
    CLEAR <url>.
    DATA(lt_param) = url_params( ctx-client ).

    LOOP AT <fields> REFERENCE INTO DATA(lr_field) WHERE no_display = abap_false.
      READ TABLE lt_param INTO DATA(ls_param) WITH KEY n = lr_field->name.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        INSERT LINES OF url_range( name = lr_field->name
                                   val  = ls_param-v ) INTO TABLE <url>.
      ELSE.
        INSERT VALUE #( name = lr_field->name
                        kind = z2ui5_cl_cgui_variant=>cs_kind-parameter
                        low  = ls_param-v ) INTO TABLE <url>.
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

    ASSIGN ctx-fields->* TO <fields>.

    " the parameters of the URL that are no field of the screen stay - the
    " app to start, the client, the language
    DATA(lv_search) = ctx-client->get( )-s_config-search.
    LOOP AT url_search( ctx-client ) INTO DATA(lv_param).
      CLEAR: lv_name, lv_value.
      SPLIT lv_param AT `=` INTO lv_name lv_value.
      lv_name = to_upper( url_decode( lv_name ) ).
      IF line_exists( <fields>[ name = lv_name ] ) OR lv_name = z2ui5_cl_cgui_report=>cv_cgui_url_skip OR lv_name = `VARIANT`.
        CONTINUE.
      ENDIF.
      INSERT lv_param INTO TABLE lt_keep.
    ENDLOOP.
    " a variable, not the template - a WITH KEY operand on 7.02
    DATA(lv_app_start) = |app_start={ to_lower( ctx-key ) }|.
    IF NOT line_exists( lt_keep[ table_line = lv_app_start ] )
        AND NOT lv_search CS `app_start`.
      INSERT lv_app_start INTO TABLE lt_keep.
    ENDIF.

    LOOP AT <fields> REFERENCE INTO DATA(lr_field) WHERE no_display = abap_false.
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.
    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = ctx-app
                                                        names = lt_name ).

    LOOP AT <fields> REFERENCE INTO lr_field WHERE no_display = abap_false.
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
      INSERT |{ to_lower( z2ui5_cl_cgui_report=>cv_cgui_url_skip ) }=X| INTO TABLE lt_keep.
    ENDIF.

    result = |{ ctx-client->get( )-s_config-origin }{ ctx-client->get( )-s_config-pathname }?{ concat_lines_of( table = lt_keep sep = `&` ) }|.

  ENDMETHOD.

  METHOD okcode_parse.

    DATA lt_tcode TYPE z2ui5_if_cgui_catalog=>ty_t_transaction.

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
    IF catalog IS BOUND.
      lt_tcode = catalog->get( ).
    ENDIF.
    IF line_exists( lt_tcode[ code = result-code ] ).
      result-kind = cs_okcode-start.
      result-target = result-code.
      RETURN.
    ENDIF.

    " else an OK code of the screen
    result-kind = cs_okcode-ucomm.

  ENDMETHOD.

  METHOD start_resolve.

    result-report = code.
    IF catalog IS BOUND.
      DATA(lt_tcode) = catalog->get( ).
      READ TABLE lt_tcode INTO DATA(ls_tcode) WITH KEY code = code.
      IF sy-subrc = 0.
        result-report = to_upper( ls_tcode-report ).
        result-variant = ls_tcode-variant.
      ENDIF.
    ENDIF.

    " a class - nothing else starts from the command field
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = result-report
                                         RECEIVING  p_descr_ref    = DATA(lo_type)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0 OR lo_type->kind <> cl_abap_typedescr=>kind_class.
      RETURN.
    ENDIF.
    TRY.
        CREATE OBJECT result-app TYPE (result-report).
      CATCH cx_sy_create_object_error.
        CLEAR result-app.
    ENDTRY.

  ENDMETHOD.

  METHOD start_url.

    DATA lt_keep TYPE string_table.

    LOOP AT url_search( client ) INTO DATA(lv_param).
      IF to_upper( segment( val = lv_param index = 1 sep = `=` ) ) = `APP_START`
          OR to_upper( segment( val = lv_param index = 1 sep = `=` ) ) = `VARIANT`.
        CONTINUE.
      ENDIF.
      INSERT lv_param INTO TABLE lt_keep.
    ENDLOOP.
    INSERT |app_start={ to_lower( report ) }| INTO TABLE lt_keep.
    IF variant IS NOT INITIAL.
      INSERT |variant={ z2ui5_cl_cgui_context=>url_escape( variant ) }| INTO TABLE lt_keep.
    ENDIF.
    result = |{ client->get( )-s_config-origin }{ client->get( )-s_config-pathname }?| &&
             concat_lines_of( table = lt_keep sep = `&` ).

  ENDMETHOD.

  METHOD palette_rows.

    IF ctx-catalog IS BOUND.
      LOOP AT ctx-catalog->get( ) INTO DATA(ls_tcode).
        INSERT VALUE #( command = to_upper( ls_tcode-code ) text = ls_tcode-text ) INTO TABLE result.
      ENDLOOP.
    ENDIF.
    " the function keys of the screen
    LOOP AT ctx-fkeys INTO DATA(ls_fkey).
      INSERT VALUE #( command = to_upper( ls_fkey-ucomm ) text = ls_fkey-text ) INTO TABLE result.
    ENDLOOP.
    IF ctx-selection = abap_true.
      INSERT VALUE #( command = `ONLI` text = 'Execute'(001) ) INTO TABLE result.
    ELSEIF ctx-output = abap_true.
      INSERT VALUE #( command = `PRI` text = 'Print'(002) ) INTO TABLE result.
    ENDIF.
    INSERT VALUE #( command = `/O` text = 'This report in a new window'(003) ) INTO TABLE result.
    INSERT VALUE #( command = `SU3` text = 'User parameters'(004) ) INTO TABLE result.

  ENDMETHOD.

  METHOD shortcuts.

    FIELD-SYMBOLS <gui> TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA lt_gui_key TYPE string_table.

    ASSIGN ctx-gui->* TO <gui>.

    " F8 Execute and F3 Back, as in the SAP GUI
    INSERT VALUE #( key = `F8` ucomm = z2ui5_cl_cgui_report=>cs_ucomm-execute ) INTO TABLE result.
    INSERT VALUE #( key = `F3` ucomm = z2ui5_cl_cgui_report=>cs_ucomm-back ) INTO TABLE result.
    " F1 and F4 of a text editor that registered them
    LOOP AT <gui> INTO DATA(ls_editor)
         WHERE kind = z2ui5_if_cgui_gui=>cs_kind-textedit AND freed = abap_false AND keys IS NOT INITIAL.
      SPLIT ls_editor-keys AT `,` INTO TABLE DATA(lt_editor_key).
      LOOP AT lt_editor_key INTO DATA(lv_editor_key).
        INSERT lv_editor_key INTO TABLE lt_gui_key.
      ENDLOOP.
    ENDLOOP.
    SORT lt_gui_key.
    DELETE ADJACENT DUPLICATES FROM lt_gui_key.
    LOOP AT lt_gui_key INTO DATA(lv_gui_key).
      INSERT VALUE #( key   = lv_gui_key
                      ucomm = COND #( WHEN lv_gui_key = `F1`
                                      THEN z2ui5_cl_cgui_report=>cs_ucomm-gui_f1
                                      ELSE z2ui5_cl_cgui_report=>cs_ucomm-gui_f4 ) ) INTO TABLE result.
    ENDLOOP.

    " the command palette - with a command field or a catalog to search
    IF ctx-cmd_on = abap_true OR ctx-catalog IS BOUND.
      INSERT VALUE #( key = `Ctrl+K` ucomm = z2ui5_cl_cgui_report=>cs_ucomm-palette ) INTO TABLE result.
      INSERT VALUE #( key = `Meta+K` ucomm = z2ui5_cl_cgui_report=>cs_ucomm-palette ) INTO TABLE result.
    ENDIF.

    " the function keys of SET PF-STATUS, on the output only
    IF ctx-selection = abap_true.
      RETURN.
    ENDIF.
    LOOP AT ctx-pf_keys INTO DATA(ls_key).
      IF line_exists( ctx-excl_out[ table_line = to_upper( ls_key-ucomm ) ] ).
        CONTINUE.
      ENDIF.
      INSERT ls_key INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
