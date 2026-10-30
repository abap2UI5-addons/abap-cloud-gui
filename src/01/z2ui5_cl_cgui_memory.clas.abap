"! The memory of a report - what it keeps for its user beyond one run: the
"! selection variants and the store they live in (a table on the server, or
"! the browser's local storage), the user parameters of SET / GET PARAMETER
"! ID with the customizing and the system parameters beside them, the last
"! entries of every field (the input history, set_prefill_last( )) and the
"! draft of a selection screen left without executing (set_draft( )).
"! The state stays with the report - its attributes are the API of its
"! subclasses and the bindings of its storage controls; this class is the
"! logic over them, stateless. A call takes the state as ty_s_ctx: data
"! references to the attributes it reads and writes, built by the report
"! on the spot (memory_ctx( )) and kept by nobody, and the report itself as
"! app - the fields of the selection screen are its public attributes. What
"! opens a popup stays in the report (variant_popup( ), su3_open( ),
"! spro_open( )), and so do the messages: a method here answers what it
"! did, an error of the store is a z2ui5_cx_cgui_error.
CLASS z2ui5_cl_cgui_memory DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      "! the state of the report a call works on, by reference: the client
      "! (unbound before the first roundtrip), the store (unbound: the
      "! browser), the key the variants are kept under - the name of the
      "! class -, batch - a background run, which writes nothing into a
      "! browser -, the fields of the screen, and the attributes
      BEGIN OF ty_s_ctx,
        app           TYPE REF TO object,
        client        TYPE REF TO z2ui5_if_client,
        store         TYPE REF TO z2ui5_if_cgui_variant_store,
        key           TYPE string,
        batch         TYPE abap_bool,
        fields        TYPE REF TO z2ui5_cl_cgui_selscreen=>ty_t_field,
        variants      TYPE REF TO string,
        variant       TYPE REF TO string,
        variant_start TYPE REF TO string,
        variant_url   TYPE REF TO abap_bool,
        protect       TYPE REF TO string_table,
        hide          TYPE REF TO string_table,
        spa           TYPE REF TO string,
        spa_cust      TYPE REF TO string,
        spa_system    TYPE REF TO z2ui5_if_client=>ty_t_name_value,
        history       TYPE REF TO string,
        draft_last    TYPE REF TO string,
        draft_restore TYPE REF TO abap_bool,
      END OF ty_s_ctx.

    TYPES:
      BEGIN OF ty_s_history,
        name   TYPE string,
        values TYPE string_table,
      END OF ty_s_history.
    TYPES ty_t_history TYPE STANDARD TABLE OF ty_s_history WITH EMPTY KEY.

    " ---- the variants
    CLASS-METHODS variant_catalog
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE z2ui5_cl_cgui_variant=>ty_t_variant.

    "! the catalog as loaded - from the store, or from the browser
    CLASS-METHODS variant_store
      IMPORTING
        ctx      TYPE ty_s_ctx
        variants TYPE z2ui5_cl_cgui_variant=>ty_t_variant.

    "! the catalog from the server store
    CLASS-METHODS variant_load
      IMPORTING
        ctx TYPE ty_s_ctx.

    "! a variant into the store, or into the catalog of the browser
    CLASS-METHODS variant_put
      IMPORTING
        ctx     TYPE ty_s_ctx
        variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant
      RAISING
        z2ui5_cx_cgui_error.

    CLASS-METHODS variant_remove
      IMPORTING
        ctx  TYPE ty_s_ctx
        name TYPE string
      RAISING
        z2ui5_cx_cgui_error.

    "! the values of the variant into the fields of the screen - only
    "! those; abap_false when there is no such variant
    CLASS-METHODS variant_apply
      IMPORTING
        ctx           TYPE ty_s_ctx
        fields        TYPE z2ui5_cl_cgui_selscreen=>ty_t_field
        name          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! Save as Variant answered: the fields of the screen under the name of
    "! the popup, with its sharing, its protected and hidden fields and the
    "! dynamic dates - the name saved, an error when there is none
    CLASS-METHODS variant_save
      IMPORTING
        ctx           TYPE ty_s_ctx
        popup         TYPE REF TO z2ui5_cl_cgui_popup
      RETURNING
        VALUE(result) TYPE string
      RAISING
        z2ui5_cx_cgui_error.

    CLASS-METHODS variant_delete
      IMPORTING
        ctx  TYPE ty_s_ctx
        name TYPE string
      RAISING
        z2ui5_cx_cgui_error.

    "! the attributes of the variant loaded: its protected fields read-only,
    "! its hidden fields off the screen
    CLASS-METHODS variant_attributes_apply
      IMPORTING
        ctx    TYPE ty_s_ctx
        screen TYPE REF TO z2ui5_cl_cgui_selscreen.

    " ---- SET / GET PARAMETER ID
    "! the user parameters as name and value
    CLASS-METHODS spa_get
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

    "! the user parameters set - into the store for the user, or the browser
    CLASS-METHODS spa_set
      IMPORTING
        ctx    TYPE ty_s_ctx
        values TYPE z2ui5_if_client=>ty_t_name_value
      RAISING
        z2ui5_cx_cgui_error.

    "! the user's and the customizing parameters from the server store
    CLASS-METHODS spa_load
      IMPORTING
        ctx TYPE ty_s_ctx.

    "! GET PARAMETER ID: the user's parameter, else the customizing one,
    "! else the system parameter
    CLASS-METHODS param_get
      IMPORTING
        ctx           TYPE ty_s_ctx
        id            TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS param_set
      IMPORTING
        ctx   TYPE ty_s_ctx
        id    TYPE clike
        value TYPE simple
      RAISING
        z2ui5_cx_cgui_error.

    CLASS-METHODS system_set
      IMPORTING
        ctx    TYPE ty_s_ctx
        values TYPE z2ui5_if_client=>ty_t_name_value.

    "! SU3 answered: the parameters of the popup, a new one added -
    "! abap_true when they were saved
    CLASS-METHODS su3_result
      IMPORTING
        ctx           TYPE ty_s_ctx
        popup         TYPE REF TO z2ui5_cl_cgui_popup
      RETURNING
        VALUE(result) TYPE abap_bool
      RAISING
        z2ui5_cx_cgui_error.

    "! SPRO answered: the customizing parameters of the popup saved, shared
    "! - every user reads them
    CLASS-METHODS spro_result
      IMPORTING
        ctx           TYPE ty_s_ctx
        popup         TYPE REF TO z2ui5_cl_cgui_popup
      RETURNING
        VALUE(result) TYPE abap_bool
      RAISING
        z2ui5_cx_cgui_error.

    "! MEMORY ID: an empty field takes the value of its parameter ID
    CLASS-METHODS memory_id_apply
      IMPORTING
        ctx TYPE ty_s_ctx.

    "! MEMORY ID: the run sets the parameter ID of every field with a value
    CLASS-METHODS memory_id_store
      IMPORTING
        ctx TYPE ty_s_ctx
      RAISING
        z2ui5_cx_cgui_error.

    " ---- the last entries
    CLASS-METHODS history_get
      IMPORTING
        ctx           TYPE ty_s_ctx
      RETURNING
        VALUE(result) TYPE ty_t_history.

    "! the entries of the fields of this run into the history - the latest
    "! first, at most cv_cgui_history_size per field
    CLASS-METHODS history_store
      IMPORTING
        ctx TYPE ty_s_ctx.

    "! set_prefill_last( ): the last entry of every empty field
    CLASS-METHODS history_apply
      IMPORTING
        ctx TYPE ty_s_ctx.

    " ---- the draft
    CLASS-METHODS draft_name
      RETURNING
        VALUE(result) TYPE string.

    "! the entries of the selection screen as the draft - when they changed
    CLASS-METHODS draft_keep
      IMPORTING
        ctx TYPE ty_s_ctx
      RAISING
        z2ui5_cx_cgui_error.

    "! the draft back into the fields - abap_true when there was one
    CLASS-METHODS draft_restore
      IMPORTING
        ctx           TYPE ty_s_ctx
        fields        TYPE z2ui5_cl_cgui_selscreen=>ty_t_field
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS draft_drop
      IMPORTING
        ctx TYPE ty_s_ctx
      RAISING
        z2ui5_cx_cgui_error.

  PRIVATE SECTION.
    "! ID=value lines of the values of a variant
    CLASS-METHODS spa_lines
      IMPORTING
        values        TYPE z2ui5_cl_cgui_variant=>ty_t_value
      RETURNING
        VALUE(result) TYPE string.

    "! the lines of ID=value as name and value
    CLASS-METHODS spa_pairs
      IMPORTING
        lines         TYPE string
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

    "! what the browser is told to keep - nothing before the first
    "! roundtrip, nothing in a batch run
    CLASS-METHODS browser_keep
      IMPORTING
        ctx    TYPE ty_s_ctx
        prefix TYPE clike
        key    TYPE clike
        val    TYPE string.

    "! the dynamic dates of the popup into the values of a variant
    CLASS-METHODS variant_dynamic_dates
      IMPORTING
        popup  TYPE REF TO z2ui5_cl_cgui_popup
      CHANGING
        values TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    "! the parameters of the popup of SU3 and SPRO: every field with a
    "! value, the new ID and its value added
    CLASS-METHODS popup_values
      IMPORTING
        popup         TYPE REF TO z2ui5_cl_cgui_popup
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

    "! a reference to the attribute name of app - the field of the screen
    CLASS-METHODS attri
      IMPORTING
        app           TYPE REF TO object
        name          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the value of a field a user typed - the first of a select-option,
    "! none of a checkbox - as the history keeps it
    CLASS-METHODS history_value
      IMPORTING
        app           TYPE REF TO object
        field         TYPE z2ui5_cl_cgui_selscreen=>ty_s_field
      RETURNING
        VALUE(result) TYPE string.

    "! a value into a field of the screen - a select-option as its line I EQ
    CLASS-METHODS field_fill
      IMPORTING
        app   TYPE REF TO object
        field TYPE z2ui5_cl_cgui_selscreen=>ty_s_field
        value TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_memory IMPLEMENTATION.

  METHOD attri.

    FIELD-SYMBOLS <attri> TYPE any.

    ASSIGN app->(name) TO <attri>.
    IF <attri> IS ASSIGNED.
      GET REFERENCE OF <attri> INTO result.
    ENDIF.

  ENDMETHOD.

  METHOD browser_keep.

    IF ctx-client IS NOT BOUND OR ctx-batch = abap_true.
      RETURN.
    ENDIF.
    ctx-client->follow_up_action( val   = ctx-client->cs_event-store_data
                                  t_arg = VALUE #( ( z2ui5_cl_cgui_variant=>storage_json( prefix = prefix
                                                                                          key    = key
                                                                                          val    = val ) ) ) ).

  ENDMETHOD.

  METHOD variant_catalog.

    result = z2ui5_cl_cgui_variant=>catalog_from_string( ctx-variants->* ).

  ENDMETHOD.

  METHOD variant_store.

    " the bound value and the stored one stay the same, so the storage
    " control has nothing to report on the next render. An empty catalog
    " removes the key. A server store keeps the catalog only in memory
    CLEAR ctx-variants->*.
    IF variants IS NOT INITIAL.
      ctx-variants->* = z2ui5_cl_cgui_variant=>catalog_to_string( variants ).
    ENDIF.
    IF ctx-store IS BOUND.
      RETURN.
    ENDIF.
    browser_keep( ctx    = ctx
                  prefix = z2ui5_cl_cgui_report=>cv_cgui_variant_prefix
                  key    = ctx-key
                  val    = ctx-variants->* ).

  ENDMETHOD.

  METHOD variant_load.

    variant_store( ctx      = ctx
                   variants = ctx-store->load( ctx-key ) ).

  ENDMETHOD.

  METHOD variant_put.

    IF ctx-store IS BOUND.
      ctx-store->save( report  = ctx-key
                       variant = variant ).
      variant_load( ctx ).
      RETURN.
    ENDIF.
    DATA(lt_variant) = variant_catalog( ctx ).
    DELETE lt_variant WHERE name = variant-name.
    INSERT variant INTO TABLE lt_variant.
    SORT lt_variant BY name.
    variant_store( ctx      = ctx
                   variants = lt_variant ).

  ENDMETHOD.

  METHOD variant_remove.

    IF ctx-store IS BOUND.
      ctx-store->delete( report = ctx-key
                         name   = name ).
      variant_load( ctx ).
      RETURN.
    ENDIF.
    DATA(lt_variant) = variant_catalog( ctx ).
    DELETE lt_variant WHERE name = name.
    variant_store( ctx      = ctx
                   variants = lt_variant ).

  ENDMETHOD.

  METHOD variant_apply.

    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    DATA(lt_variant) = variant_catalog( ctx ).
    READ TABLE lt_variant REFERENCE INTO DATA(lr_variant) WITH KEY name = name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " only the fields of the screen, as variant_save( ) collects them - a
    " catalog from the browser's local storage holds what the browser sent
    " and sets no other attribute of the class
    LOOP AT lr_variant->values REFERENCE INTO DATA(lr_value).
      DATA(lv_field) = to_upper( lr_value->name ).
      IF line_exists( fields[ name = lv_field ] ).
        INSERT lr_value->* INTO TABLE lt_value.
      ENDIF.
    ENDLOOP.

    z2ui5_cl_cgui_variant=>values_set( app    = ctx-app
                                       values = lt_value ).
    ctx-variant->* = name.
    ctx-protect->* = lr_variant->protect.
    ctx-hide->* = lr_variant->hide.
    result = abap_true.

  ENDMETHOD.

  METHOD variant_dynamic_dates.

    " the dynamic dates replace the values they stand for
    LOOP AT values REFERENCE INTO DATA(lr_value).
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

  ENDMETHOD.

  METHOD variant_save.

    DATA lt_name TYPE string_table.
    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    ASSIGN ctx-fields->* TO <fields>.
    DATA(lv_name) = condense( popup->result_value( `NAME` ) ).
    IF lv_name IS INITIAL OR lv_name CP '##*'.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = 'Enter a name for the variant'(001).
    ENDIF.

    LOOP AT <fields> REFERENCE INTO DATA(lr_field).
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.
    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = ctx-app
                                                        names = lt_name ).
    variant_dynamic_dates( EXPORTING popup  = popup
                           CHANGING  values = lt_value ).

    variant_put( ctx     = ctx
                 variant = VALUE #( name      = lv_name
                                    text      = z2ui5_cl_cgui_variant=>values_to_text( values = lt_value
                                                                                       fields = <fields> )
                                    values    = lt_value
                                    shared    = xsdbool( popup->result_value( `SHARED` ) IS NOT INITIAL )
                                    protected = xsdbool( popup->result_value( `PROTECTED` ) IS NOT INITIAL )
                                    protect   = popup->result_keys( `PROTECT` )
                                    hide      = popup->result_keys( `HIDE` ) ) ).
    ctx-variant->* = lv_name.
    result = lv_name.

  ENDMETHOD.

  METHOD variant_delete.

    variant_remove( ctx  = ctx
                    name = name ).
    IF ctx-variant->* = name.
      CLEAR ctx-variant->*.
    ENDIF.

  ENDMETHOD.

  METHOD variant_attributes_apply.

    FIELD-SYMBOLS <protect> TYPE string_table.
    FIELD-SYMBOLS <hide>    TYPE string_table.

    ASSIGN ctx-protect->* TO <protect>.
    ASSIGN ctx-hide->* TO <hide>.
    IF <protect> IS INITIAL AND <hide> IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lt_screen) = screen->loop_at_screen( ).
    LOOP AT lt_screen INTO DATA(ls_screen).
      IF line_exists( <hide>[ table_line = ls_screen-name ] ).
        ls_screen-active = abap_false.
        screen->modify_screen( ls_screen ).
      ELSEIF line_exists( <protect>[ table_line = ls_screen-name ] ).
        ls_screen-input = abap_false.
        screen->modify_screen( ls_screen ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD spa_pairs.

    DATA lt_line TYPE string_table.
    DATA lv_id   TYPE string.
    DATA lv_val  TYPE string.

    SPLIT lines AT cl_abap_char_utilities=>newline INTO TABLE lt_line.
    LOOP AT lt_line INTO DATA(lv_line) WHERE table_line IS NOT INITIAL.
      SPLIT lv_line AT `=` INTO lv_id lv_val.
      INSERT VALUE #( n = to_upper( lv_id )
                      v = lv_val ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD spa_lines.

    DATA lt_line TYPE string_table.

    LOOP AT values INTO DATA(ls_value).
      INSERT |{ to_upper( ls_value-name ) }={ ls_value-low }| INTO TABLE lt_line.
    ENDLOOP.
    result = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).

  ENDMETHOD.

  METHOD spa_get.

    result = spa_pairs( ctx-spa->* ).

  ENDMETHOD.

  METHOD spa_set.

    DATA lt_line TYPE string_table.

    LOOP AT values INTO DATA(ls_value).
      INSERT |{ ls_value-n }={ ls_value-v }| INTO TABLE lt_line.
    ENDLOOP.
    ctx-spa->* = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).

    " a server store keeps them for the user - else the browser
    IF ctx-store IS BOUND.
      ctx-store->save( report  = z2ui5_cl_cgui_report=>cv_cgui_spa_report
                       variant = VALUE #( name   = to_upper( sy-uname )
                                          text   = 'User parameters'(002)
                                          values = VALUE #( FOR ls_spa IN values
                                                            ( name = ls_spa-n kind = `P` low = ls_spa-v ) ) ) ).
      RETURN.
    ENDIF.
    browser_keep( ctx    = ctx
                  prefix = z2ui5_cl_cgui_report=>cv_cgui_spa_prefix
                  key    = z2ui5_cl_cgui_report=>cv_cgui_spa_key
                  val    = ctx-spa->* ).

  ENDMETHOD.

  METHOD spa_load.

    DATA(lt_variant) = ctx-store->load( z2ui5_cl_cgui_report=>cv_cgui_spa_report ).
    " the customizing of the installation, for every user
    READ TABLE lt_variant INTO DATA(ls_cust) WITH KEY name = z2ui5_cl_cgui_report=>cv_cgui_spa_customizing.
    IF sy-subrc = 0.
      ctx-spa_cust->* = spa_lines( ls_cust-values ).
    ENDIF.
    READ TABLE lt_variant INTO DATA(ls_variant) WITH KEY name = to_upper( sy-uname ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ctx-spa->* = spa_lines( ls_variant-values ).

  ENDMETHOD.

  METHOD param_get.

    FIELD-SYMBOLS <system> TYPE z2ui5_if_client=>ty_t_name_value.

    ASSIGN ctx-spa_system->* TO <system>.
    DATA(lv_name) = to_upper( id ).
    DATA(lt_spa) = spa_get( ctx ).
    READ TABLE lt_spa INTO DATA(ls_spa) WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_spa-v.
      RETURN.
    ENDIF.

    " the customizing of the installation
    DATA(lt_cust) = spa_pairs( ctx-spa_cust->* ).
    READ TABLE lt_cust INTO DATA(ls_cust) WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_cust-v.
      RETURN.
    ENDIF.

    " the system parameters given in code
    READ TABLE <system> INTO DATA(ls_system) WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_system-v.
    ENDIF.

  ENDMETHOD.

  METHOD param_set.

    DATA(lt_spa) = spa_get( ctx ).
    DATA(lv_name) = to_upper( id ).
    DELETE lt_spa WHERE n = lv_name.
    INSERT VALUE #( n = lv_name
                    v = |{ value }| ) INTO TABLE lt_spa.
    spa_set( ctx    = ctx
             values = lt_spa ).

  ENDMETHOD.

  METHOD system_set.

    FIELD-SYMBOLS <system> TYPE z2ui5_if_client=>ty_t_name_value.

    ASSIGN ctx-spa_system->* TO <system>.
    CLEAR <system>.
    LOOP AT values INTO DATA(ls_value).
      INSERT VALUE #( n = to_upper( ls_value-n )
                      v = ls_value-v ) INTO TABLE <system>.
    ENDLOOP.

  ENDMETHOD.

  METHOD popup_values.

    DATA(ls_result) = popup->result( ).
    LOOP AT ls_result-fields INTO DATA(ls_field) WHERE value IS NOT INITIAL AND name(1) <> `%`.
      INSERT VALUE #( n = to_upper( ls_field-name ) v = ls_field-value ) INTO TABLE result.
    ENDLOOP.
    DATA(lv_new) = to_upper( condense( popup->result_value( `%NEW_ID` ) ) ).
    DATA(lv_value) = popup->result_value( `%NEW_VALUE` ).
    IF lv_new IS NOT INITIAL AND lv_value IS NOT INITIAL.
      DELETE result WHERE n = lv_new.
      INSERT VALUE #( n = lv_new v = lv_value ) INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD su3_result.

    IF popup->result( )-confirmed = abap_false.
      RETURN.
    ENDIF.
    spa_set( ctx    = ctx
             values = popup_values( popup ) ).
    result = abap_true.

  ENDMETHOD.

  METHOD spro_result.

    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    IF popup->result( )-confirmed = abap_false OR ctx-store IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT popup_values( popup ) INTO DATA(ls_value).
      INSERT VALUE #( name = ls_value-n kind = `P` low = ls_value-v ) INTO TABLE lt_value.
    ENDLOOP.

    " shared: every user reads them, not only the one who saved them
    ctx-store->save( report  = z2ui5_cl_cgui_report=>cv_cgui_spa_report
                     variant = VALUE #( name   = z2ui5_cl_cgui_report=>cv_cgui_spa_customizing
                                        text   = 'Customizing parameters'(003)
                                        values = lt_value
                                        shared = abap_true ) ).
    ctx-spa_cust->* = spa_lines( lt_value ).
    result = abap_true.

  ENDMETHOD.

  METHOD field_fill.

    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <range>     TYPE STANDARD TABLE.

    DATA(lr_val) = attri( app  = app
                          name = field-name ).
    IF lr_val IS NOT BOUND.
      RETURN.
    ENDIF.
    IF field-kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
      ASSIGN lr_val->* TO <range>.
      z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = VALUE #( ( sign = `I` option = `EQ` low = value ) )
                                          IMPORTING error = DATA(lv_error)
                                          CHANGING  range = <range> ).
      IF lv_error IS NOT INITIAL.
        CLEAR <range>.
      ENDIF.
      RETURN.
    ENDIF.
    ASSIGN lr_val->* TO <field_val>.
    TRY.
        <field_val> = value.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD memory_id_apply.

    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    ASSIGN ctx-fields->* TO <fields>.
    " MEMORY ID: an empty field takes the value of its parameter ID - a
    " select-option as its line I EQ
    FIELD-SYMBOLS <field_val> TYPE any.

    LOOP AT <fields> REFERENCE INTO DATA(lr_field) WHERE memory_id IS NOT INITIAL.
      DATA(lr_val) = attri( app  = ctx-app
                            name = lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      DATA(lv_value) = param_get( ctx = ctx
                                  id  = lr_field->memory_id ).
      IF lv_value IS INITIAL.
        CONTINUE.
      ENDIF.
      field_fill( app   = ctx-app
                  field = lr_field->*
                  value = lv_value ).
    ENDLOOP.

  ENDMETHOD.

  METHOD memory_id_store.

    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    ASSIGN ctx-fields->* TO <fields>.
    " MEMORY ID: the run sets the parameter ID of every field with a value -
    " of a select-option the first value
    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <range>     TYPE STANDARD TABLE.
    FIELD-SYMBOLS <low>       TYPE any.

    LOOP AT <fields> REFERENCE INTO DATA(lr_field) WHERE memory_id IS NOT INITIAL.
      DATA(lr_val) = attri( app  = ctx-app
                            name = lr_field->name ).
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
          param_set( ctx   = ctx
                     id    = lr_field->memory_id
                     value = <low> ).
        ENDIF.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        param_set( ctx   = ctx
                   id    = lr_field->memory_id
                   value = <field_val> ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD history_get.

    DATA lt_line TYPE string_table.

    SPLIT ctx-history->* AT cl_abap_char_utilities=>newline INTO TABLE lt_line.
    LOOP AT lt_line INTO DATA(lv_line) WHERE table_line IS NOT INITIAL.
      SPLIT lv_line AT cl_abap_char_utilities=>horizontal_tab INTO TABLE DATA(lt_part).
      IF lines( lt_part ) < 2.
        CONTINUE.
      ENDIF.
      DATA(ls_history) = VALUE ty_s_history( name = to_upper( lt_part[ 1 ] ) ).
      LOOP AT lt_part INTO DATA(lv_part) FROM 2 WHERE table_line IS NOT INITIAL.
        INSERT lv_part INTO TABLE ls_history-values.
      ENDLOOP.
      INSERT ls_history INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD history_value.

    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <range>     TYPE STANDARD TABLE.
    FIELD-SYMBOLS <low>       TYPE any.

    DATA(lr_val) = attri( app  = app
                          name = field-name ).
    IF lr_val IS NOT BOUND.
      RETURN.
    ENDIF.
    IF field-kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
      ASSIGN lr_val->* TO <range>.
      READ TABLE <range> ASSIGNING FIELD-SYMBOL(<line>) INDEX 1.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
      IF sy-subrc = 0 AND <low> IS NOT INITIAL.
        result = condense( CONV string( <low> ) ).
      ENDIF.
      RETURN.
    ENDIF.
    ASSIGN lr_val->* TO <field_val>.
    " a checkbox - a field of one character - has no history
    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( <field_val> ).
    IF <field_val> IS NOT INITIAL
        AND NOT ( lo_type->type_kind = cl_abap_typedescr=>typekind_char
                  AND lo_type->length <= cl_abap_char_utilities=>charsize ).
      result = condense( CONV string( <field_val> ) ).
    ENDIF.

  ENDMETHOD.

  METHOD history_store.

    DATA lt_line TYPE string_table.
    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    ASSIGN ctx-fields->* TO <fields>.
    DATA(lt_history) = history_get( ctx ).
    " the fields a user types into - no radio button, no NO-DISPLAY
    LOOP AT <fields> REFERENCE INTO DATA(lr_field) WHERE no_display = abap_false AND group IS INITIAL.
      DATA(lv_value) = history_value( app   = ctx-app
                                      field = lr_field->* ).
      " a tab or a line end would break the history apart
      IF lv_value IS INITIAL OR lv_value CA |{ cl_abap_char_utilities=>horizontal_tab }{ cl_abap_char_utilities=>newline }|.
        CONTINUE.
      ENDIF.
      READ TABLE lt_history ASSIGNING FIELD-SYMBOL(<history>) WITH KEY name = lr_field->name.
      IF sy-subrc <> 0.
        INSERT VALUE #( name = lr_field->name ) INTO TABLE lt_history ASSIGNING <history>.
      ENDIF.
      DELETE <history>-values WHERE table_line = lv_value.
      INSERT lv_value INTO <history>-values INDEX 1.
      WHILE lines( <history>-values ) > z2ui5_cl_cgui_report=>cv_cgui_history_size.
        DELETE <history>-values INDEX lines( <history>-values ).
      ENDWHILE.
    ENDLOOP.

    LOOP AT lt_history INTO DATA(ls_history).
      " the name, then its values - APPEND LINES OF rather than LINES OF in
      " VALUE, which the transpiler of the abap2UI5 playground does not take
      DATA(lt_cells) = VALUE string_table( ( ls_history-name ) ).
      APPEND LINES OF ls_history-values TO lt_cells.
      INSERT concat_lines_of( table = lt_cells
                              sep   = cl_abap_char_utilities=>horizontal_tab ) INTO TABLE lt_line.
    ENDLOOP.
    DATA(lv_history) = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).
    IF lv_history = ctx-history->*.
      RETURN.
    ENDIF.
    ctx-history->* = lv_history.
    " the history lives in the browser, with a server store too
    browser_keep( ctx    = ctx
                  prefix = z2ui5_cl_cgui_report=>cv_cgui_history_prefix
                  key    = ctx-key
                  val    = ctx-history->* ).

  ENDMETHOD.

  METHOD history_apply.

    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    ASSIGN ctx-fields->* TO <fields>.
    LOOP AT history_get( ctx ) INTO DATA(ls_history).
      READ TABLE <fields> INTO DATA(ls_field) WITH KEY name = ls_history-name.
      IF sy-subrc <> 0 OR ls_history-values IS INITIAL.
        CONTINUE.
      ENDIF.
      DATA(lr_val) = attri( app  = ctx-app
                            name = ls_field-name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      field_fill( app   = ctx-app
                  field = ls_field
                  value = ls_history-values[ 1 ] ).
    ENDLOOP.

  ENDMETHOD.

  METHOD draft_name.

    result = |%DRAFT_{ to_upper( sy-uname ) }|.

  ENDMETHOD.

  METHOD draft_keep.

    DATA lt_name TYPE string_table.
    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.

    ASSIGN ctx-fields->* TO <fields>.
    LOOP AT <fields> REFERENCE INTO DATA(lr_field).
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.
    DATA(lt_value) = z2ui5_cl_cgui_variant=>values_get( app   = ctx-app
                                                        names = lt_name ).
    " every part of every value - a change anywhere is a new draft
    DATA(lv_text) = ``.
    LOOP AT lt_value INTO DATA(ls_value).
      lv_text = |{ lv_text }{ ls_value-name }\|{ ls_value-sign }\|{ ls_value-option }\|{ ls_value-low }\|{ ls_value-high };|.
    ENDLOOP.
    IF lv_text = ctx-draft_last->*.
      RETURN.
    ENDIF.
    ctx-draft_last->* = lv_text.
    variant_put( ctx     = ctx
                 variant = VALUE #( name   = draft_name( )
                                    text   = 'Draft'(004)
                                    values = lt_value ) ).

  ENDMETHOD.

  METHOD draft_restore.

    DATA(lt_variant) = variant_catalog( ctx ).
    IF NOT line_exists( lt_variant[ name = draft_name( ) ] ).
      RETURN.
    ENDIF.
    IF variant_apply( ctx    = ctx
                      fields = fields
                      name   = draft_name( ) ) = abap_false.
      RETURN.
    ENDIF.
    " a draft is no variant the user picked
    CLEAR ctx-variant->*.
    ctx-draft_restore->* = abap_true.
    result = abap_true.

  ENDMETHOD.

  METHOD draft_drop.

    CLEAR: ctx-draft_last->*, ctx-draft_restore->*.
    DATA(lt_variant) = variant_catalog( ctx ).
    IF line_exists( lt_variant[ name = draft_name( ) ] ).
      variant_remove( ctx  = ctx
                      name = draft_name( ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
