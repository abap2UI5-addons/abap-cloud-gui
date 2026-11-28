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
        store         TYPE REF TO z2ui5_if_cgui_variants,
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
    TYPES ty_t_history TYPE STANDARD TABLE OF ty_s_history WITH DEFAULT KEY.

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

    "! the lines of ID=value as name and value
    CLASS-METHODS spa_pairs
      IMPORTING
        lines         TYPE string
      RETURNING
        VALUE(result) TYPE z2ui5_if_client=>ty_t_name_value.

  PRIVATE SECTION.
    "! ID=value lines of the values of a variant
    CLASS-METHODS spa_lines
      IMPORTING
        values        TYPE z2ui5_cl_cgui_variant=>ty_t_value
      RETURNING
        VALUE(result) TYPE string.

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
    DATA temp1 TYPE string_table.

    IF ctx-client IS NOT BOUND OR ctx-batch = abap_true.
      RETURN.
    ENDIF.

    CLEAR temp1.
    INSERT z2ui5_cl_cgui_variant=>storage_json( prefix = prefix key = key val = val ) INTO TABLE temp1.
    ctx-client->follow_up_action( val   = ctx-client->cs_event-store_data
                                  t_arg = temp1 ).

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
    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.

    IF ctx-store IS BOUND.
      ctx-store->save( report  = ctx-key
                       variant = variant ).
      variant_load( ctx ).
      RETURN.
    ENDIF.

    lt_variant = variant_catalog( ctx ).
    DELETE lt_variant WHERE name = variant-name.
    INSERT variant INTO TABLE lt_variant.
    SORT lt_variant BY name.
    variant_store( ctx      = ctx
                   variants = lt_variant ).

  ENDMETHOD.

  METHOD variant_remove.
    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.

    IF ctx-store IS BOUND.
      ctx-store->delete( report = ctx-key
                         name   = name ).
      variant_load( ctx ).
      RETURN.
    ENDIF.

    lt_variant = variant_catalog( ctx ).
    DELETE lt_variant WHERE name = name.
    variant_store( ctx      = ctx
                   variants = lt_variant ).

  ENDMETHOD.

  METHOD variant_apply.

    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.

    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA lr_variant TYPE REF TO z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA temp3 LIKE LINE OF lr_variant->values.
    DATA lr_value LIKE REF TO temp3.
      DATA lv_field TYPE string.
      DATA temp4 LIKE sy-subrc.
    lt_variant = variant_catalog( ctx ).

    READ TABLE lt_variant REFERENCE INTO lr_variant WITH KEY name = name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " only the fields of the screen, as variant_save( ) collects them - a
    " catalog from the browser's local storage holds what the browser sent
    " and sets no other attribute of the class


    LOOP AT lr_variant->values REFERENCE INTO lr_value.

      lv_field = to_upper( lr_value->name ).

      READ TABLE fields WITH KEY name = lv_field TRANSPORTING NO FIELDS.
      temp4 = sy-subrc.
      IF temp4 = 0.
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
    DATA temp5 LIKE LINE OF values.
    DATA lr_value LIKE REF TO temp5.
      DATA lv_dynamic TYPE string.
      DATA lv_dynamic_high TYPE string.
    LOOP AT values REFERENCE INTO lr_value.

      lv_dynamic = popup->result_value( |DYN_{ lr_value->name }| ).
      IF lv_dynamic IS NOT INITIAL.
        lr_value->dynamic = lv_dynamic.
        IF lr_value->kind = z2ui5_cl_cgui_variant=>cs_kind-select_option AND lr_value->sign IS INITIAL.
          lr_value->sign = `I`.
          lr_value->option = `EQ`.
        ENDIF.
      ENDIF.

      lv_dynamic_high = popup->result_value( |DYNH_{ lr_value->name }| ).
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
    DATA lv_name TYPE string.
    DATA temp6 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp6.
    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp7 TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA temp1 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.

    ASSIGN ctx-fields->* TO <fields>.

    lv_name = condense( popup->result_value( `NAME` ) ).
    " ## are the layouts of the ALV, % the drafts - no names of a variant;
    " the stores keep 40 characters of a name
    IF lv_name IS INITIAL OR lv_name CP '##*' OR lv_name CP '%*' OR strlen( lv_name ) > 40.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = 'Enter a name for the variant'(001).
    ENDIF.



    LOOP AT <fields> REFERENCE INTO lr_field.
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.

    lt_value = z2ui5_cl_cgui_variant=>values_get( app   = ctx-app
                                                        names = lt_name ).
    variant_dynamic_dates( EXPORTING popup  = popup
                           CHANGING  values = lt_value ).


    CLEAR temp7.
    temp7-name = lv_name.
    temp7-text = z2ui5_cl_cgui_variant=>values_to_text( values = lt_value fields = <fields> ).
    temp7-values = lt_value.

    temp1 = boolc( popup->result_value( `SHARED` ) IS NOT INITIAL ).
    temp7-shared = temp1.

    temp2 = boolc( popup->result_value( `PROTECTED` ) IS NOT INITIAL ).
    temp7-protected = temp2.
    temp7-protect = popup->result_keys( `PROTECT` ).
    temp7-hide = popup->result_keys( `HIDE` ).
    variant_put( ctx     = ctx
                 variant = temp7 ).
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
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
      DATA temp8 LIKE sy-subrc.
      DATA temp1 LIKE sy-subrc.
      DATA temp2 LIKE sy-subrc.

    ASSIGN ctx-protect->* TO <protect>.
    ASSIGN ctx-hide->* TO <hide>.
    IF <protect> IS INITIAL AND <hide> IS INITIAL.
      RETURN.
    ENDIF.

    lt_screen = screen->loop_at_screen( ).

    LOOP AT lt_screen INTO ls_screen.

      READ TABLE <hide> WITH KEY table_line = ls_screen-name TRANSPORTING NO FIELDS.
      temp8 = sy-subrc.


      temp2 = sy-subrc.
      READ TABLE <protect> WITH KEY table_line = ls_screen-name TRANSPORTING NO FIELDS.
      temp1 = sy-subrc.
      sy-subrc = temp2.
      IF temp8 = 0.
        ls_screen-active = abap_false.
        screen->modify_screen( ls_screen ).
      ELSEIF temp1 = 0.
        ls_screen-input = abap_false.
        screen->modify_screen( ls_screen ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD spa_pairs.

    DATA lt_line TYPE string_table.
    DATA lv_id   TYPE string.
    DATA lv_val  TYPE string.
    DATA lv_line LIKE LINE OF lt_line.
      DATA temp10 TYPE z2ui5_if_client=>ty_s_name_value.

    SPLIT lines AT cl_abap_char_utilities=>newline INTO TABLE lt_line.

    LOOP AT lt_line INTO lv_line WHERE table_line IS NOT INITIAL.
      SPLIT lv_line AT `=` INTO lv_id lv_val.

      CLEAR temp10.
      temp10-n = to_upper( lv_id ).
      temp10-v = lv_val.
      INSERT temp10 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD spa_lines.

    DATA lt_line TYPE string_table.

    DATA ls_value LIKE LINE OF values.
      DATA temp11 LIKE LINE OF lt_line.
    LOOP AT values INTO ls_value.

      temp11 = |{ to_upper( ls_value-name ) }={ ls_value-low }|.
      INSERT temp11 INTO TABLE lt_line.
    ENDLOOP.
    result = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).

  ENDMETHOD.

  METHOD spa_get.

    result = spa_pairs( ctx-spa->* ).

  ENDMETHOD.

  METHOD spa_set.

    DATA lt_line TYPE string_table.

    DATA ls_value LIKE LINE OF values.
      DATA temp12 LIKE LINE OF lt_line.
      DATA temp13 TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
      DATA temp3 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
      DATA ls_spa LIKE LINE OF values.
        DATA temp4 LIKE LINE OF temp3.
    LOOP AT values INTO ls_value.

      temp12 = |{ ls_value-n }={ ls_value-v }|.
      INSERT temp12 INTO TABLE lt_line.
    ENDLOOP.
    ctx-spa->* = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).

    " a server store keeps them for the user - else the browser
    IF ctx-store IS BOUND.

      CLEAR temp13.
      temp13-name = to_upper( sy-uname ).
      temp13-text = 'User parameters'(002).

      CLEAR temp3.

      LOOP AT values INTO ls_spa.

        temp4-name = ls_spa-n.
        temp4-kind = `P`.
        temp4-low = ls_spa-v.
        INSERT temp4 INTO TABLE temp3.
      ENDLOOP.
      temp13-values = temp3.
      ctx-store->save( report  = z2ui5_cl_cgui_report=>cv_cgui_spa_report
                       variant = temp13 ).
      RETURN.
    ENDIF.
    browser_keep( ctx    = ctx
                  prefix = z2ui5_cl_cgui_report=>cv_cgui_spa_prefix
                  key    = z2ui5_cl_cgui_report=>cv_cgui_spa_key
                  val    = ctx-spa->* ).

  ENDMETHOD.

  METHOD spa_load.

    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA ls_cust TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA lv_key TYPE string.
    DATA ls_variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    lt_variant = ctx-store->load( z2ui5_cl_cgui_report=>cv_cgui_spa_report ).
    " the customizing of the installation, for every user

    READ TABLE lt_variant INTO ls_cust WITH KEY name = z2ui5_cl_cgui_report=>cv_cgui_spa_customizing.
    IF sy-subrc = 0.
      ctx-spa_cust->* = spa_lines( ls_cust-values ).
    ENDIF.
    " the key in a variable: a built-in function is no READ TABLE key operand before 7.40

    lv_key = to_upper( sy-uname ).

    READ TABLE lt_variant INTO ls_variant WITH KEY name = lv_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ctx-spa->* = spa_lines( ls_variant-values ).

  ENDMETHOD.

  METHOD param_get.

    FIELD-SYMBOLS <system> TYPE z2ui5_if_client=>ty_t_name_value.
    DATA lv_name TYPE string.
    DATA lt_spa TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_spa TYPE z2ui5_if_client=>ty_s_name_value.
    DATA lt_cust TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_cust TYPE z2ui5_if_client=>ty_s_name_value.
    DATA ls_system TYPE z2ui5_if_client=>ty_s_name_value.

    ASSIGN ctx-spa_system->* TO <system>.

    lv_name = to_upper( id ).

    lt_spa = spa_get( ctx ).

    READ TABLE lt_spa INTO ls_spa WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_spa-v.
      RETURN.
    ENDIF.

    " the customizing of the installation

    lt_cust = spa_pairs( ctx-spa_cust->* ).

    READ TABLE lt_cust INTO ls_cust WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_cust-v.
      RETURN.
    ENDIF.

    " the system parameters given in code

    READ TABLE <system> INTO ls_system WITH KEY n = lv_name.
    IF sy-subrc = 0.
      result = ls_system-v.
    ENDIF.

  ENDMETHOD.

  METHOD param_set.

    DATA lt_spa TYPE z2ui5_if_client=>ty_t_name_value.
    DATA lv_name TYPE string.
    DATA temp14 TYPE z2ui5_if_client=>ty_s_name_value.
    lt_spa = spa_get( ctx ).

    lv_name = to_upper( id ).
    DELETE lt_spa WHERE n = lv_name.

    CLEAR temp14.
    temp14-n = lv_name.
    temp14-v = |{ value }|.
    INSERT temp14 INTO TABLE lt_spa.
    spa_set( ctx    = ctx
             values = lt_spa ).

  ENDMETHOD.

  METHOD system_set.

    FIELD-SYMBOLS <system> TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_value LIKE LINE OF values.
      DATA temp15 TYPE z2ui5_if_client=>ty_s_name_value.

    ASSIGN ctx-spa_system->* TO <system>.
    CLEAR <system>.

    LOOP AT values INTO ls_value.

      CLEAR temp15.
      temp15-n = to_upper( ls_value-n ).
      temp15-v = ls_value-v.
      INSERT temp15 INTO TABLE <system>.
    ENDLOOP.

  ENDMETHOD.

  METHOD popup_values.

    DATA ls_result TYPE z2ui5_cl_cgui_popup=>ty_s_result.
    DATA ls_field LIKE LINE OF ls_result-fields.
      DATA temp16 TYPE z2ui5_if_client=>ty_s_name_value.
    DATA lv_new TYPE string.
    DATA lv_value TYPE string.
      DATA temp17 TYPE z2ui5_if_client=>ty_s_name_value.
    ls_result = popup->result( ).

    LOOP AT ls_result-fields INTO ls_field WHERE value IS NOT INITIAL AND name(1) <> `%`.

      CLEAR temp16.
      temp16-n = to_upper( ls_field-name ).
      temp16-v = ls_field-value.
      INSERT temp16 INTO TABLE result.
    ENDLOOP.

    lv_new = to_upper( condense( popup->result_value( `%NEW_ID` ) ) ).

    lv_value = popup->result_value( `%NEW_VALUE` ).
    IF lv_new IS NOT INITIAL AND lv_value IS NOT INITIAL.
      DELETE result WHERE n = lv_new.

      CLEAR temp17.
      temp17-n = lv_new.
      temp17-v = lv_value.
      INSERT temp17 INTO TABLE result.
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
    DATA temp18 TYPE z2ui5_if_client=>ty_t_name_value.
    DATA ls_value LIKE LINE OF temp18.
      DATA temp19 TYPE z2ui5_cl_cgui_variant=>ty_s_value.
    DATA temp20 TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    IF popup->result( )-confirmed = abap_false OR ctx-store IS NOT BOUND.
      RETURN.
    ENDIF.

    temp18 = popup_values( popup ).

    LOOP AT temp18 INTO ls_value.

      CLEAR temp19.
      temp19-name = ls_value-n.
      temp19-kind = `P`.
      temp19-low = ls_value-v.
      INSERT temp19 INTO TABLE lt_value.
    ENDLOOP.

    " shared: every user reads them, not only the one who saved them

    CLEAR temp20.
    temp20-name = z2ui5_cl_cgui_report=>cv_cgui_spa_customizing.
    temp20-text = 'Customizing parameters'(003).
    temp20-values = lt_value.
    temp20-shared = abap_true.
    ctx-store->save( report  = z2ui5_cl_cgui_report=>cv_cgui_spa_report
                     variant = temp20 ).
    ctx-spa_cust->* = spa_lines( lt_value ).
    result = abap_true.

  ENDMETHOD.

  METHOD field_fill.

    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <range>     TYPE STANDARD TABLE.

    DATA lr_val TYPE REF TO data.
      DATA temp21 TYPE z2ui5_cl_cgui_range=>ty_t_row.
      DATA temp22 LIKE LINE OF temp21.
      DATA lv_error TYPE string.
    lr_val = attri( app  = app
                          name = field-name ).
    IF lr_val IS NOT BOUND.
      RETURN.
    ENDIF.
    IF field-kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
      ASSIGN lr_val->* TO <range>.

      CLEAR temp21.

      temp22-sign = `I`.
      temp22-option = `EQ`.
      temp22-low = value.
      INSERT temp22 INTO TABLE temp21.

      z2ui5_cl_cgui_range=>rows_to_range( EXPORTING rows  = temp21
                                          IMPORTING error = lv_error
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
    FIELD-SYMBOLS <field_val> TYPE any.
    DATA temp23 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp23.
      DATA lr_val TYPE REF TO data.
      DATA lv_value TYPE string.

    ASSIGN ctx-fields->* TO <fields>.
    " MEMORY ID: an empty field takes the value of its parameter ID - a
    " select-option as its line I EQ




    LOOP AT <fields> REFERENCE INTO lr_field WHERE memory_id IS NOT INITIAL.

      lr_val = attri( app  = ctx-app
                            name = lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      lv_value = param_get( ctx = ctx
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
    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <range> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <low> TYPE any.
    DATA temp24 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp24.
      DATA lr_val TYPE REF TO data.
        FIELD-SYMBOLS <line> TYPE any.

    ASSIGN ctx-fields->* TO <fields>.
    " MEMORY ID: the run sets the parameter ID of every field with a value -
    " of a select-option the first value






    LOOP AT <fields> REFERENCE INTO lr_field WHERE memory_id IS NOT INITIAL.

      lr_val = attri( app  = ctx-app
                            name = lr_field->name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      IF lr_field->kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
        ASSIGN lr_val->* TO <range>.

        READ TABLE <range> ASSIGNING <line> INDEX 1.
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
    DATA lv_line LIKE LINE OF lt_line.
      TYPES temp1 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_part TYPE temp1.
      DATA temp25 TYPE ty_s_history.
      FIELD-SYMBOLS <temp5> LIKE LINE OF lt_part.
      DATA temp6 LIKE sy-tabix.
      DATA ls_history LIKE temp25.
      DATA lv_part LIKE LINE OF lt_part.

    SPLIT ctx-history->* AT cl_abap_char_utilities=>newline INTO TABLE lt_line.

    LOOP AT lt_line INTO lv_line WHERE table_line IS NOT INITIAL.


      SPLIT lv_line AT cl_abap_char_utilities=>horizontal_tab INTO TABLE lt_part.
      IF lines( lt_part ) < 2.
        CONTINUE.
      ENDIF.

      CLEAR temp25.


      temp6 = sy-tabix.
      READ TABLE lt_part INDEX 1 ASSIGNING <temp5>.
      sy-tabix = temp6.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp25-name = to_upper( <temp5> ).

      ls_history = temp25.

      LOOP AT lt_part INTO lv_part FROM 2 WHERE table_line IS NOT INITIAL.
        INSERT lv_part INTO TABLE ls_history-values.
      ENDLOOP.
      INSERT ls_history INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD history_value.

    FIELD-SYMBOLS <field_val> TYPE any.
    FIELD-SYMBOLS <range>     TYPE STANDARD TABLE.
    FIELD-SYMBOLS <low>       TYPE any.

    DATA lr_val TYPE REF TO data.
      FIELD-SYMBOLS <line> TYPE any.
        DATA temp26 TYPE string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
      DATA temp27 TYPE string.
    lr_val = attri( app  = app
                          name = field-name ).
    IF lr_val IS NOT BOUND.
      RETURN.
    ENDIF.
    IF field-kind = z2ui5_cl_cgui_selscreen=>cs_field_kind-select_option.
      ASSIGN lr_val->* TO <range>.

      READ TABLE <range> ASSIGNING <line> INDEX 1.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
      IF sy-subrc = 0 AND <low> IS NOT INITIAL.

        temp26 = <low>.
        result = condense( temp26 ).
      ENDIF.
      RETURN.
    ENDIF.
    ASSIGN lr_val->* TO <field_val>.
    " a checkbox - a field of one character - has no history

    lo_type = cl_abap_typedescr=>describe_by_data( <field_val> ).
    IF <field_val> IS NOT INITIAL
        AND NOT ( lo_type->type_kind = cl_abap_typedescr=>typekind_char
                  AND lo_type->length <= cl_abap_char_utilities=>charsize ).

      temp27 = <field_val>.
      result = condense( temp27 ).
    ENDIF.

  ENDMETHOD.

  METHOD history_store.

    DATA lt_line TYPE string_table.
    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA lt_history TYPE z2ui5_cl_cgui_memory=>ty_t_history.
    DATA temp28 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp28.
      DATA lv_value TYPE string.
      FIELD-SYMBOLS <history> TYPE z2ui5_cl_cgui_memory=>ty_s_history.
        DATA temp29 TYPE z2ui5_cl_cgui_memory=>ty_s_history.
    DATA ls_history LIKE LINE OF lt_history.
      DATA temp30 TYPE string_table.
      DATA lt_cells LIKE temp30.
      DATA temp1 TYPE string.
    DATA lv_history TYPE string.

    ASSIGN ctx-fields->* TO <fields>.

    lt_history = history_get( ctx ).
    " the fields a user types into - no radio button, no NO-DISPLAY


    LOOP AT <fields> REFERENCE INTO lr_field WHERE no_display = abap_false AND group IS INITIAL.

      lv_value = history_value( app   = ctx-app
                                      field = lr_field->* ).
      " a tab or a line end would break the history apart
      IF lv_value IS INITIAL OR lv_value CA |{ cl_abap_char_utilities=>horizontal_tab }{ cl_abap_char_utilities=>newline }|.
        CONTINUE.
      ENDIF.

      READ TABLE lt_history ASSIGNING <history> WITH KEY name = lr_field->name.
      IF sy-subrc <> 0.

        CLEAR temp29.
        temp29-name = lr_field->name.
        INSERT temp29 INTO TABLE lt_history ASSIGNING <history>.
      ENDIF.
      DELETE <history>-values WHERE table_line = lv_value.
      INSERT lv_value INTO <history>-values INDEX 1.
      WHILE lines( <history>-values ) > z2ui5_cl_cgui_report=>cv_cgui_history_size.
        DELETE <history>-values INDEX lines( <history>-values ).
      ENDWHILE.
    ENDLOOP.


    LOOP AT lt_history INTO ls_history.
      " the name, then its values - APPEND LINES OF rather than LINES OF in
      " VALUE, which the transpiler of the abap2UI5 playground does not take

      CLEAR temp30.
      INSERT ls_history-name INTO TABLE temp30.

      lt_cells = temp30.
      APPEND LINES OF ls_history-values TO lt_cells.

      temp1 = concat_lines_of( table = lt_cells sep = cl_abap_char_utilities=>horizontal_tab ).
      INSERT temp1 INTO TABLE lt_line.
    ENDLOOP.

    lv_history = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).
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
    DATA temp32 TYPE z2ui5_cl_cgui_memory=>ty_t_history.
    DATA ls_history LIKE LINE OF temp32.
      DATA ls_field TYPE z2ui5_cl_cgui_selscreen=>ty_s_field.
      DATA lr_val TYPE REF TO data.
      FIELD-SYMBOLS <temp33> LIKE LINE OF ls_history-values.
      DATA temp34 LIKE sy-tabix.

    ASSIGN ctx-fields->* TO <fields>.

    temp32 = history_get( ctx ).

    LOOP AT temp32 INTO ls_history.

      READ TABLE <fields> INTO ls_field WITH KEY name = ls_history-name.
      IF sy-subrc <> 0 OR ls_history-values IS INITIAL.
        CONTINUE.
      ENDIF.

      lr_val = attri( app  = ctx-app
                            name = ls_field-name ).
      IF lr_val IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN lr_val->* TO <field_val>.
      IF <field_val> IS NOT INITIAL.
        CONTINUE.
      ENDIF.


      temp34 = sy-tabix.
      READ TABLE ls_history-values INDEX 1 ASSIGNING <temp33>.
      sy-tabix = temp34.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      field_fill( app   = ctx-app
                  field = ls_field
                  value = <temp33> ).
    ENDLOOP.

  ENDMETHOD.

  METHOD draft_name.

    result = |%DRAFT_{ to_upper( sy-uname ) }|.

  ENDMETHOD.

  METHOD draft_keep.

    DATA lt_name TYPE string_table.
    FIELD-SYMBOLS <fields> TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    DATA temp35 LIKE LINE OF <fields>.
    DATA lr_field LIKE REF TO temp35.
    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lv_text TYPE string.
    DATA ls_value LIKE LINE OF lt_value.
    DATA temp36 TYPE z2ui5_cl_cgui_variant=>ty_s_variant.

    ASSIGN ctx-fields->* TO <fields>.


    LOOP AT <fields> REFERENCE INTO lr_field.
      INSERT lr_field->name INTO TABLE lt_name.
    ENDLOOP.

    lt_value = z2ui5_cl_cgui_variant=>values_get( app   = ctx-app
                                                        names = lt_name ).
    " every part of every value - a change anywhere is a new draft

    lv_text = ``.

    LOOP AT lt_value INTO ls_value.
      lv_text = |{ lv_text }{ ls_value-name }\|{ ls_value-sign }\|{ ls_value-option }\|{ ls_value-low }\|{ ls_value-high };|.
    ENDLOOP.
    IF lv_text = ctx-draft_last->*.
      RETURN.
    ENDIF.
    ctx-draft_last->* = lv_text.

    CLEAR temp36.
    temp36-name = draft_name( ).
    temp36-text = 'Draft'(004).
    temp36-values = lt_value.
    variant_put( ctx     = ctx
                 variant = temp36 ).

  ENDMETHOD.

  METHOD draft_restore.

    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA ls_draft TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    lt_variant = variant_catalog( ctx ).

    READ TABLE lt_variant INTO ls_draft WITH KEY name = draft_name( ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    " only a draft of this user - a server store names the owner, the
    " browser's storage none
    IF ls_draft-owner IS NOT INITIAL AND to_upper( ls_draft-owner ) <> to_upper( sy-uname ).
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
    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp37 LIKE sy-subrc.

    CLEAR: ctx-draft_last->*, ctx-draft_restore->*.

    lt_variant = variant_catalog( ctx ).

    READ TABLE lt_variant WITH KEY name = draft_name( ) TRANSPORTING NO FIELDS.
    temp37 = sy-subrc.
    IF temp37 = 0.
      variant_remove( ctx  = ctx
                      name = draft_name( ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
