CLASS z2ui5_cl_cgui_context DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_s_data_element_text,
        header TYPE string,
        short  TYPE string,
        medium TYPE string,
        long   TYPE string,
      END OF ty_s_data_element_text.

    TYPES:
      BEGIN OF ty_s_comp,
        name      TYPE string,
        label     TYPE string,
        type_kind TYPE string,
        " the decimals of a packed number, the output length of the type
        " and whether it is an ABAP boolean - what the ALV formats a
        " column with
        decimals  TYPE i,
        length    TYPE i,
        boolean   TYPE abap_bool,
      END OF ty_s_comp.
    TYPES ty_t_comp TYPE STANDARD TABLE OF ty_s_comp WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_fix_val,
        low  TYPE string,
        high TYPE string,
        text TYPE string,
      END OF ty_s_fix_val.
    TYPES ty_t_fix_val TYPE STANDARD TABLE OF ty_s_fix_val WITH EMPTY KEY.

    TYPES:
      "! the value table of a domain: the table, its key field with the
      "! domain, and the fields worth showing - every field but the client
      BEGIN OF ty_s_value_table,
        table  TYPE string,
        field  TYPE string,
        fields TYPE string_table,
      END OF ty_s_value_table.

    " the name of the PUBLIC attribute of app that val is - compared by
    " reference, so val must be the attribute itself (passed by reference),
    " not a copy of it. Empty when val is no attribute of app
    CLASS-METHODS attri_name_by_ref
      IMPORTING
        app           TYPE REF TO object
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    " the medium field label of the data element val is typed with, empty
    " for a built-in or local type
    CLASS-METHODS rtti_get_label
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! is the type an ABAP boolean (ABAP_BOOL, XSDBOOLEAN, BOOLE_D, ...)
    CLASS-METHODS rtti_check_boolean
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    TYPES:
      "! the elementary search help of a data element - name and the field
      "! of the search help the value is taken from; empty when there is
      "! none (and always on ABAP Cloud)
      BEGIN OF ty_s_search_help,
        name  TYPE string,
        field TYPE string,
      END OF ty_s_search_help.

    CLASS-METHODS rtti_get_search_help
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE ty_s_search_help.

    "! the hit list of search help help, its list fields as columns - read
    "! without a dialog by F4IF_SELECT_VALUES; unbound when it cannot be
    "! read
    CLASS-METHODS search_help_select
      IMPORTING
        help          TYPE ty_s_search_help
        max           TYPE i DEFAULT 500
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the rows of value table table with the text of its text table in
    "! the logon language as last column - unbound when it cannot be read
    CLASS-METHODS value_table_select
      IMPORTING
        table         TYPE ty_s_value_table
        max           TYPE i DEFAULT 500
      RETURNING
        VALUE(result) TYPE REF TO data.

    CLASS-METHODS rtti_check_boolean_descr
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS rtti_get_type_kind
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    " the elementary components of the line type of a table of structures,
    " with their DDIC label (or the component name) - the ALV field catalog
    CLASS-METHODS rtti_get_t_comp
      IMPORTING
        val           TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE ty_t_comp.

    " a value as WRITE would put it on a list - dates and times in the
    " user's format, everything else as its plain text
    CLASS-METHODS conv_to_text
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    " a range table as the one-line summary a select-option shows
    CLASS-METHODS range_to_text
      IMPORTING
        val           TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE string.

    " val IN range - the semantics of a select-option (an empty range
    " matches everything, E lines exclude), written out so it also runs where
    " IN is not complete: the transpiled JavaScript runtime only knows I/EQ,
    " E/EQ and I/CP. On an SAP system IN and SELECT ... WHERE IN do the same
    CLASS-METHODS range_check
      IMPORTING
        val           TYPE any
        range         TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS rtti_get_data_element_texts
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE ty_s_data_element_text.

    CLASS-METHODS rtti_get_label_by_descr
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE string.

    "! the type a value help is looked up for: val itself, or the LOW
    "! component of a range table
    CLASS-METHODS rtti_get_value_descr
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE REF TO cl_abap_typedescr.

    "! the fixed values of the domain of a DDIC type - empty for any other
    "! type. On ABAP Cloud as on premise, and in the transpiled runtime
    CLASS-METHODS rtti_get_fixed_values
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE ty_t_fix_val.

    "! the value table of the domain of a DDIC type - on premise only, empty
    "! on ABAP Cloud, where the DDIC is not read
    CLASS-METHODS rtti_get_value_table
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE ty_s_value_table.

    "! does the type have a standard F4 - fixed values or a value table
    CLASS-METHODS rtti_check_value_help
      IMPORTING
        descr         TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the data element a value (or the LOW of a range) is typed with -
    "! empty for a built-in or local type
    CLASS-METHODS rtti_get_dtel_name
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! has the data element documentation (F1) - on premise
    CLASS-METHODS dtel_docu_check
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the documentation of the data element as paragraphs of plain text -
    "! the SAPscript formatting dropped; in the logon language, else English
    CLASS-METHODS dtel_docu_read
      IMPORTING
        name          TYPE clike
      RETURNING
        VALUE(result) TYPE string_table.

    "! VALUE CHECK - is val one of the fixed values of its domain or a key
    "! of its value table. abap_true too when there is nothing to check
    "! against, or val is initial
    CLASS-METHODS value_check
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! val as UTF-8 - through CL_ABAP_CONV_CODEPAGE where it exists (ABAP
    "! Cloud, 7.5x) and CL_ABAP_CONV_OUT_CE below, both named as strings
    "! as abap2UI5 does it; empty when neither converts
    CLASS-METHODS conv_get_xstring_by_string
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    "! UTF-8 val as text - the counterpart of conv_get_xstring_by_string( )
    CLASS-METHODS conv_get_string_by_xstring
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    "! val in base64 - plain ABAP, for the data URI of a download
    CLASS-METHODS conv_encode_x_base64
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    "! the bytes of base64 val - plain ABAP, for the data URI of an upload;
    "! a character outside the alphabet ends it
    CLASS-METHODS conv_decode_x_base64
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    "! val in width characters, aligned LEFT, RIGHT or CENTER with blanks -
    "! a string template's WIDTH and ALIGN, which the transpiled runtime
    "! aligns left only. A longer val stays as it is
    CLASS-METHODS text_align
      IMPORTING
        val           TYPE string
        width         TYPE i
        align         TYPE string DEFAULT `LEFT`
      RETURNING
        VALUE(result) TYPE string.

    "! val for a URL: every byte of its UTF-8 but the unreserved characters
    "! A-Z a-z 0-9 - _ . ~ as %XX
    CLASS-METHODS url_escape
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS rtti_get_dtel_texts_by_ddic
      IMPORTING
        name        TYPE string
      EXPORTING
        texts       TYPE ty_s_data_element_text
        do_fallback TYPE abap_bool.

    CLASS-METHODS rtti_get_dtel_texts_by_xco
      IMPORTING
        name        TYPE string
      EXPORTING
        texts       TYPE ty_s_data_element_text
        do_fallback TYPE abap_bool.

    "! a line of a SAPscript text without its tags <..> and its symbols
    "! &NAME& - by hand, there are no regular expressions here
    CLASS-METHODS docu_strip
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS range_line_to_text
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS range_line_check
      IMPORTING
        val           TYPE any
        option        TYPE any
        low           TYPE any
        high          TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS z2ui5_cl_cgui_context IMPLEMENTATION.

  METHOD docu_strip.

    DATA lt_part TYPE string_table.
    DATA lv_off  TYPE i.

    DATA(lv_len) = strlen( val ).
    WHILE lv_off < lv_len.
      DATA(lv_char) = substring( val = val off = lv_off len = 1 ).
      IF lv_char = `<` OR lv_char = `&`.
        DATA(lv_rest) = substring( val = val off = lv_off + 1 ).
        DATA(lv_close) = COND string( WHEN lv_char = `<` THEN `>` ELSE `&` ).
        DATA(lv_end) = find( val = lv_rest sub = lv_close ).
        IF lv_end >= 0.
          DATA(lv_inner) = substring( val = lv_rest len = lv_end ).
          " a tag is anything up to >, a symbol a name of A-Z, 0-9 and _
          IF lv_char = `<` OR ( lv_end > 0 AND lv_inner CO `ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789` ).
            lv_off = lv_off + lv_end + 2.
            CONTINUE.
          ENDIF.
        ENDIF.
      ENDIF.
      INSERT lv_char INTO TABLE lt_part.
      lv_off = lv_off + 1.
    ENDWHILE.
    result = concat_lines_of( lt_part ).

  ENDMETHOD.

  METHOD conv_get_xstring_by_string.

    DATA lo_conv  TYPE REF TO object.
    DATA lv_class TYPE c LENGTH 30.

    TRY.
        lv_class = `CL_ABAP_CONV_CODEPAGE`.
        CALL METHOD (lv_class)=>create_out
          RECEIVING
            instance = lo_conv.
        CALL METHOD lo_conv->(`IF_ABAP_CONV_OUT~CONVERT`)
          EXPORTING
            source = val
          RECEIVING
            result = result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
        " not there - the classic class below
    ENDTRY.

    TRY.
        lv_class = `CL_ABAP_CONV_OUT_CE`.
        CALL METHOD (lv_class)=>create
          EXPORTING
            encoding = `UTF-8`
          RECEIVING
            conv     = lo_conv.
        CALL METHOD lo_conv->(`CONVERT`)
          EXPORTING
            data   = val
          IMPORTING
            buffer = result.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD conv_get_string_by_xstring.

    DATA lo_conv  TYPE REF TO object.
    DATA lv_class TYPE c LENGTH 30.

    TRY.
        lv_class = `CL_ABAP_CONV_CODEPAGE`.
        CALL METHOD (lv_class)=>create_in
          RECEIVING
            instance = lo_conv.
        CALL METHOD lo_conv->(`IF_ABAP_CONV_IN~CONVERT`)
          EXPORTING
            source = val
          RECEIVING
            result = result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
        " not there - the classic class below
    ENDTRY.

    TRY.
        lv_class = `CL_ABAP_CONV_IN_CE`.
        CALL METHOD (lv_class)=>create
          EXPORTING
            encoding = `UTF-8`
          RECEIVING
            conv     = lo_conv.
        CALL METHOD lo_conv->(`CONVERT`)
          EXPORTING
            input = val
          IMPORTING
            data  = result.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD conv_decode_x_base64.

    CONSTANTS lc_alphabet TYPE string VALUE `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/`.
    DATA lv_byte  TYPE x LENGTH 1.
    DATA lv_bits  TYPE i.
    DATA lv_count TYPE i.
    DATA lv_power TYPE i.
    DATA lv_char  TYPE string.

    DATA(lv_len) = strlen( val ).
    DATA(lv_off) = 0.
    WHILE lv_off < lv_len.
      lv_char = substring( val = val off = lv_off len = 1 ).
      lv_off = lv_off + 1.
      IF lv_char = `=`.
        EXIT.
      ENDIF.
      DATA(lv_value) = find( val = lc_alphabet sub = lv_char ).
      IF lv_value < 0.
        " a line break of a wrapped encoding is no character of it
        IF lv_char = |\n| OR lv_char = |\r| OR lv_char = ` `.
          CONTINUE.
        ENDIF.
        EXIT.
      ENDIF.
      lv_bits = lv_bits * 64 + lv_value.
      lv_count = lv_count + 6.
      IF lv_count >= 8.
        lv_count = lv_count - 8.
        lv_power = 1.
        DO lv_count TIMES.
          lv_power = lv_power * 2.
        ENDDO.
        lv_byte = lv_bits DIV lv_power.
        lv_bits = lv_bits MOD lv_power.
        CONCATENATE result lv_byte INTO result IN BYTE MODE.
      ENDIF.
    ENDWHILE.

  ENDMETHOD.

  METHOD conv_encode_x_base64.

    CONSTANTS lc_alphabet TYPE string VALUE `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/`.
    DATA lt_part   TYPE string_table.
    DATA lv_byte   TYPE x LENGTH 1.
    DATA lv_off    TYPE i.
    DATA lv_rest   TYPE i.
    DATA lv_value  TYPE i.
    DATA lv_triple TYPE i.
    DATA lv_part   TYPE string.

    DATA(lv_len) = xstrlen( val ).
    WHILE lv_off < lv_len.
      lv_rest = lv_len - lv_off.
      lv_triple = 0.
      DO 3 TIMES.
        lv_triple = lv_triple * 256.
        IF sy-index <= lv_rest.
          lv_byte = val+lv_off(1).
          lv_value = lv_byte.
          lv_triple = lv_triple + lv_value.
          lv_off = lv_off + 1.
        ENDIF.
      ENDDO.
      lv_part = substring( val = lc_alphabet off = lv_triple DIV 262144 len = 1 )
             && substring( val = lc_alphabet off = ( lv_triple DIV 4096 ) MOD 64 len = 1 ).
      IF lv_rest > 1.
        lv_part = lv_part && substring( val = lc_alphabet off = ( lv_triple DIV 64 ) MOD 64 len = 1 ).
      ELSE.
        lv_part = lv_part && `=`.
      ENDIF.
      IF lv_rest > 2.
        lv_part = lv_part && substring( val = lc_alphabet off = lv_triple MOD 64 len = 1 ).
      ELSE.
        lv_part = lv_part && `=`.
      ENDIF.
      INSERT lv_part INTO TABLE lt_part.
    ENDWHILE.
    result = concat_lines_of( lt_part ).

  ENDMETHOD.

  METHOD text_align.

    DATA(lv_fill) = width - strlen( val ).
    IF lv_fill <= 0.
      result = val.
      RETURN.
    ENDIF.
    CASE align.
      WHEN `RIGHT`.
        result = repeat( val = ` `
                         occ = lv_fill ) && val.
      WHEN `CENTER`.
        DATA(lv_left) = lv_fill DIV 2.
        result = repeat( val = ` `
                         occ = lv_left ) && val && repeat( val = ` `
                                                           occ = lv_fill - lv_left ).
      WHEN OTHERS.
        result = val && repeat( val = ` `
                                occ = lv_fill ).
    ENDCASE.

  ENDMETHOD.

  METHOD url_escape.

    " the printable ASCII characters from 32 on, the byte is the position
    CONSTANTS lc_ascii TYPE string
      VALUE ` !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_``abcdefghijklmnopqrstuvwxyz{|}~`.
    CONSTANTS lc_keep  TYPE string VALUE `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~`.
    DATA lt_part  TYPE string_table.
    DATA lv_byte  TYPE x LENGTH 1.
    DATA lv_hex   TYPE c LENGTH 2.
    DATA lv_value TYPE i.
    DATA lv_off   TYPE i.
    DATA lv_char  TYPE string.

    DATA(lv_utf8) = conv_get_xstring_by_string( val ).
    DATA(lv_len) = xstrlen( lv_utf8 ).
    WHILE lv_off < lv_len.
      lv_byte = lv_utf8+lv_off(1).
      lv_value = lv_byte.
      lv_off = lv_off + 1.
      IF lv_value >= 32 AND lv_value < 127.
        lv_char = substring( val = lc_ascii off = lv_value - 32 len = 1 ).
        IF lv_char CO lc_keep.
          INSERT lv_char INTO TABLE lt_part.
          CONTINUE.
        ENDIF.
      ENDIF.
      lv_hex = lv_byte.
      INSERT |%{ lv_hex }| INTO TABLE lt_part.
    ENDWHILE.
    result = concat_lines_of( lt_part ).

  ENDMETHOD.


  METHOD attri_name_by_ref.

    DATA lr_val   TYPE REF TO data.
    DATA lr_attri TYPE REF TO data.
    FIELD-SYMBOLS <attri> TYPE any.

    IF app IS NOT BOUND.
      RETURN.
    ENDIF.

    GET REFERENCE OF val INTO lr_val.
    DATA(lo_class) = CAST cl_abap_classdescr( cl_abap_typedescr=>describe_by_object_ref( app ) ).

    LOOP AT lo_class->attributes REFERENCE INTO DATA(lr_attri_descr)
         WHERE visibility = cl_abap_classdescr=>public
           AND is_constant = abap_false.

      UNASSIGN <attri>.
      ASSIGN app->(lr_attri_descr->name) TO <attri>.
      IF <attri> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      GET REFERENCE OF <attri> INTO lr_attri.
      IF lr_attri = lr_val.
        result = lr_attri_descr->name.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD rtti_get_label.

    result = rtti_get_label_by_descr( cl_abap_typedescr=>describe_by_data( val ) ).

  ENDMETHOD.

  METHOD rtti_get_label_by_descr.

    IF descr->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.
    IF descr->is_ddic_type( ) = abap_false.
      RETURN.
    ENDIF.
    IF descr->absolute_name CS `\TYPE-POOL=`.
      RETURN.
    ENDIF.

    DATA(lv_name) = substring_after( val = descr->absolute_name
                                     sub = `\TYPE=` ).
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_texts) = rtti_get_data_element_texts( lv_name ).
    result = ls_texts-medium.
    IF result IS INITIAL.
      result = ls_texts-long.
    ENDIF.
    IF result = lv_name.
      CLEAR result.
    ENDIF.

  ENDMETHOD.

  METHOD rtti_check_boolean.

    result = rtti_check_boolean_descr( cl_abap_typedescr=>describe_by_data( val ) ).

  ENDMETHOD.

  METHOD rtti_check_boolean_descr.

    IF descr IS NOT BOUND OR descr->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    CASE descr->absolute_name.
      WHEN `\TYPE-POOL=ABAP\TYPE=ABAP_BOOL`
          OR `\TYPE=ABAP_BOOL`
          OR `\TYPE=ABAP_BOOLEAN`
          OR `\TYPE=XSDBOOLEAN`
          OR `\TYPE=BOOLEAN`
          OR `\TYPE=BOOLE_D`.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD rtti_get_type_kind.

    result = cl_abap_typedescr=>describe_by_data( val )->type_kind.

  ENDMETHOD.

  METHOD rtti_get_t_comp.

    DATA lo_struct TYPE REF TO cl_abap_structdescr.

    DATA(lo_table) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( val ) ).
    DATA(lo_line) = lo_table->get_table_line_type( ).
    IF lo_line->kind <> cl_abap_typedescr=>kind_struct.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = `ALV_TABLE_LINE_NO_STRUCTURE - use a table of structures`.
    ENDIF.
    lo_struct ?= lo_line.

    LOOP AT lo_struct->components REFERENCE INTO DATA(lr_comp).
      DATA(lv_name) = CONV string( lr_comp->name ).
      DATA(lo_comp) = lo_struct->get_component_type( lv_name ).
      IF lo_comp->kind <> cl_abap_typedescr=>kind_elem.
        CONTINUE.
      ENDIF.

      DATA(lv_label) = rtti_get_label_by_descr( lo_comp ).
      IF lv_label IS INITIAL.
        lv_label = lv_name.
      ENDIF.

      DATA(lo_elem) = CAST cl_abap_elemdescr( lo_comp ).
      INSERT VALUE #( name      = lv_name
                      label     = lv_label
                      type_kind = lr_comp->type_kind
                      decimals  = lo_elem->decimals
                      length    = lo_elem->output_length
                      boolean   = rtti_check_boolean_descr( lo_comp ) ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD conv_to_text.

    DATA lv_date TYPE d.
    DATA lv_time TYPE t.

    CASE cl_abap_typedescr=>describe_by_data( val )->type_kind.

      WHEN cl_abap_typedescr=>typekind_date.
        lv_date = val.
        IF lv_date IS NOT INITIAL.
          result = |{ lv_date DATE = USER }|.
        ENDIF.

      WHEN cl_abap_typedescr=>typekind_time.
        lv_time = val.
        result = |{ lv_time TIME = USER }|.

      WHEN OTHERS.
        result = |{ val }|.

    ENDCASE.

  ENDMETHOD.

  METHOD range_to_text.

    FIELD-SYMBOLS <line> TYPE any.
    DATA lv_count TYPE i.

    LOOP AT val ASSIGNING <line>.
      lv_count = lv_count + 1.
      IF lv_count > 3.
        CONTINUE.
      ENDIF.
      IF result IS NOT INITIAL.
        result = |{ result }; |.
      ENDIF.
      result = result && range_line_to_text( <line> ).
    ENDLOOP.

    IF lv_count > 3.
      result = |{ result } (+{ lv_count - 3 })|.
    ENDIF.

  ENDMETHOD.

  METHOD range_line_to_text.

    FIELD-SYMBOLS <sign>   TYPE any.
    FIELD-SYMBOLS <option> TYPE any.
    FIELD-SYMBOLS <low>    TYPE any.
    FIELD-SYMBOLS <high>   TYPE any.

    ASSIGN COMPONENT `SIGN` OF STRUCTURE val TO <sign>.
    ASSIGN COMPONENT `OPTION` OF STRUCTURE val TO <option>.
    ASSIGN COMPONENT `LOW` OF STRUCTURE val TO <low>.
    ASSIGN COMPONENT `HIGH` OF STRUCTURE val TO <high>.
    IF <sign> IS NOT ASSIGNED OR <option> IS NOT ASSIGNED
        OR <low> IS NOT ASSIGNED OR <high> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    DATA(lv_low) = conv_to_text( <low> ).
    DATA(lv_high) = conv_to_text( <high> ).

    CASE <option>.
      WHEN `EQ` OR ``.
        result = lv_low.
      WHEN `BT`.
        result = |{ lv_low }...{ lv_high }|.
      WHEN `NB`.
        result = |!({ lv_low }...{ lv_high })|.
      WHEN `CP`.
        result = lv_low.
      WHEN OTHERS.
        result = |{ <option> } { lv_low }|.
    ENDCASE.

    IF <sign> = `E`.
      result = |!{ result }|.
    ENDIF.

  ENDMETHOD.

  METHOD range_check.

    FIELD-SYMBOLS <line>   TYPE any.
    FIELD-SYMBOLS <sign>   TYPE any.
    FIELD-SYMBOLS <option> TYPE any.
    FIELD-SYMBOLS <low>    TYPE any.
    FIELD-SYMBOLS <high>   TYPE any.
    DATA lv_has_include TYPE abap_bool.
    DATA lv_included    TYPE abap_bool.
    DATA lv_match       TYPE abap_bool.

    LOOP AT range ASSIGNING <line>.
      UNASSIGN: <sign>, <option>, <low>, <high>.
      ASSIGN COMPONENT `SIGN` OF STRUCTURE <line> TO <sign>.
      ASSIGN COMPONENT `OPTION` OF STRUCTURE <line> TO <option>.
      ASSIGN COMPONENT `LOW` OF STRUCTURE <line> TO <low>.
      ASSIGN COMPONENT `HIGH` OF STRUCTURE <line> TO <high>.
      IF <sign> IS NOT ASSIGNED OR <option> IS NOT ASSIGNED
          OR <low> IS NOT ASSIGNED OR <high> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      lv_match = range_line_check( val    = val
                                   option = <option>
                                   low    = <low>
                                   high   = <high> ).
      IF <sign> = `E`.
        IF lv_match = abap_true.
          RETURN.
        ENDIF.
      ELSE.
        lv_has_include = abap_true.
        IF lv_match = abap_true.
          lv_included = abap_true.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " no include line at all selects everything the excludes left over
    result = xsdbool( lv_has_include = abap_false OR lv_included = abap_true ).

  ENDMETHOD.

  METHOD range_line_check.

    CASE option.
      WHEN `EQ` OR ``.
        result = xsdbool( val = low ).
      WHEN `NE`.
        result = xsdbool( val <> low ).
      WHEN `GT`.
        result = xsdbool( val > low ).
      WHEN `GE`.
        result = xsdbool( val >= low ).
      WHEN `LT`.
        result = xsdbool( val < low ).
      WHEN `LE`.
        result = xsdbool( val <= low ).
      WHEN `BT`.
        result = xsdbool( val >= low AND val <= high ).
      WHEN `NB`.
        result = xsdbool( val < low OR val > high ).
      WHEN `CP`.
        result = xsdbool( val CP low ).
      WHEN `NP`.
        result = xsdbool( val NP low ).
    ENDCASE.

  ENDMETHOD.

  METHOD rtti_get_value_descr.

    DATA lo_line TYPE REF TO cl_abap_structdescr.

    TRY.
        result = cl_abap_typedescr=>describe_by_data( val ).
        IF result->kind <> cl_abap_typedescr=>kind_table.
          RETURN.
        ENDIF.
        lo_line ?= CAST cl_abap_tabledescr( result )->get_table_line_type( ).
        result = lo_line->get_component_type( `LOW` ).
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD rtti_get_fixed_values.

    " DDFIXVALUE, declared here: the structure is not released on ABAP Cloud,
    " the method is - so it is called dynamically, as abap2UI5 itself does
    TYPES:
      BEGIN OF ty_s_fixvalue,
        low        TYPE c LENGTH 10,
        high       TYPE c LENGTH 10,
        option     TYPE c LENGTH 2,
        ddlanguage TYPE c LENGTH 1,
        ddtext     TYPE c LENGTH 60,
      END OF ty_s_fixvalue.
    TYPES ty_t_fixvalue TYPE STANDARD TABLE OF ty_s_fixvalue WITH DEFAULT KEY.
    DATA lt_values TYPE ty_t_fixvalue.
    DATA lo_elem   TYPE REF TO cl_abap_elemdescr.
    DATA lv_langu  TYPE c LENGTH 1.

    IF descr IS NOT BOUND OR descr->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    TRY.
        IF descr->is_ddic_type( ) = abap_false.
          RETURN.
        ENDIF.
        lo_elem ?= descr.
        lv_langu = sy-langu.

        CALL METHOD lo_elem->(`GET_DDIC_FIXED_VALUES`)
          EXPORTING
            p_langu        = lv_langu
          RECEIVING
            p_fixed_values = lt_values
          EXCEPTIONS
            not_found      = 1
            no_ddic_type   = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
      CATCH cx_root.
        RETURN.
    ENDTRY.

    LOOP AT lt_values REFERENCE INTO DATA(lr_value).
      INSERT VALUE #( low  = lr_value->low
                      high = lr_value->high
                      text = lr_value->ddtext ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD rtti_get_value_table.

    DATA lr_dfies  TYPE REF TO data.
    DATA lr_fields TYPE REF TO data.
    DATA lo_type   TYPE REF TO cl_abap_datadescr.
    DATA lo_table  TYPE REF TO cl_abap_structdescr.
    DATA lv_table  TYPE string.
    DATA lv_domain TYPE string.
    FIELD-SYMBOLS <dfies>  TYPE any.
    FIELD-SYMBOLS <fields> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <field>  TYPE any.
    FIELD-SYMBOLS <comp>   TYPE any.
    FIELD-SYMBOLS <key>    TYPE any.
    FIELD-SYMBOLS <dom>    TYPE any.
    FIELD-SYMBOLS <type>   TYPE any.

    IF descr IS NOT BOUND OR descr->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    TRY.
        IF descr->is_ddic_type( ) = abap_false.
          RETURN.
        ENDIF.

        " DFIES and DDFIELDS are not released on ABAP Cloud - there the
        " lookup raises and the field has no value table
        lo_type ?= cl_abap_typedescr=>describe_by_name( `DFIES` ).
        CREATE DATA lr_dfies TYPE HANDLE lo_type.
        ASSIGN lr_dfies->* TO <dfies>.

        CALL METHOD descr->(`GET_DDIC_FIELD`)
          RECEIVING
            p_flddescr   = <dfies>
          EXCEPTIONS
            not_found    = 1
            no_ddic_type = 2
            OTHERS       = 3.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        ASSIGN COMPONENT `ENTITYTAB` OF STRUCTURE <dfies> TO <comp>.
        IF <comp> IS NOT ASSIGNED.
          RETURN.
        ENDIF.
        lv_table = <comp>.
        UNASSIGN <comp>.
        ASSIGN COMPONENT `DOMNAME` OF STRUCTURE <dfies> TO <comp>.
        IF lv_table IS INITIAL OR <comp> IS NOT ASSIGNED.
          RETURN.
        ENDIF.
        lv_domain = <comp>.

        lo_table ?= cl_abap_typedescr=>describe_by_name( lv_table ).
        lo_type ?= cl_abap_typedescr=>describe_by_name( `DDFIELDS` ).
        CREATE DATA lr_fields TYPE HANDLE lo_type.
        ASSIGN lr_fields->* TO <fields>.

        CALL METHOD lo_table->(`GET_DDIC_FIELD_LIST`)
          RECEIVING
            p_field_list = <fields>
          EXCEPTIONS
            not_found    = 1
            no_ddic_type = 2
            OTHERS       = 3.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        LOOP AT <fields> ASSIGNING <field>.
          UNASSIGN: <comp>, <key>, <dom>, <type>.
          ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <field> TO <comp>.
          ASSIGN COMPONENT `KEYFLAG` OF STRUCTURE <field> TO <key>.
          ASSIGN COMPONENT `DOMNAME` OF STRUCTURE <field> TO <dom>.
          ASSIGN COMPONENT `DATATYPE` OF STRUCTURE <field> TO <type>.
          IF <comp> IS NOT ASSIGNED OR <key> IS NOT ASSIGNED OR <dom> IS NOT ASSIGNED OR <type> IS NOT ASSIGNED.
            RETURN.
          ENDIF.
          IF <type> = `CLNT`.
            CONTINUE.
          ENDIF.
          INSERT CONV string( <comp> ) INTO TABLE result-fields.
          IF result-field IS INITIAL AND <key> = abap_true AND <dom> = lv_domain.
            result-field = <comp>.
          ENDIF.
        ENDLOOP.

        IF result-field IS INITIAL.
          CLEAR result.
          RETURN.
        ENDIF.
        result-table = lv_table.

      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD rtti_get_search_help.

    DATA lv_name  TYPE c LENGTH 30.
    DATA lv_shlp  TYPE c LENGTH 30.
    DATA lv_field TYPE c LENGTH 30.

    IF descr IS NOT BOUND OR descr->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    TRY.
        IF descr->is_ddic_type( ) = abap_false.
          RETURN.
        ENDIF.
        lv_name = descr->get_relative_name( ).
        " DD04L is not released on ABAP Cloud - there the select raises and
        " the field has no search help
        DATA(lv_dd04l) = `DD04L`.
        SELECT SINGLE shlpname, shlpfield FROM (lv_dd04l)
          WHERE rollname = @lv_name AND as4local = 'A'
          INTO (@lv_shlp, @lv_field).
        IF sy-subrc = 0 AND lv_shlp IS NOT INITIAL AND lv_field IS NOT INITIAL.
          result-name  = lv_shlp.
          result-field = lv_field.
        ENDIF.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD search_help_select.

    " F4IF_GET_SHLP_DESCR, F4IF_EXPAND_SEARCHHELP and F4IF_SELECT_VALUES and
    " their types are named as strings: on ABAP Cloud they do not exist,
    " the select ends in the CATCH and the field keeps its other F4
    DATA lv_function TYPE c LENGTH 30.
    DATA lr_shlp   TYPE REF TO data.
    DATA lr_shlps  TYPE REF TO data.
    DATA lr_return TYPE REF TO data.
    DATA lt_comp   TYPE cl_abap_structdescr=>component_table.
    DATA lt_field  TYPE string_table.
    DATA lr_row    TYPE REF TO data.
    DATA lv_pos    TYPE i.
    DATA lv_last   TYPE i.
    DATA lo_type   TYPE REF TO cl_abap_datadescr.
    FIELD-SYMBOLS <shlp>   TYPE any.
    FIELD-SYMBOLS <shlps>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <return> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <props>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <descrs> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <comp>   TYPE any.
    FIELD-SYMBOLS <tab>    TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>    TYPE any.
    FIELD-SYMBOLS <cell>   TYPE any.

    IF help-name IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_shlp) = CAST cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( `SHLP_DESCR` ) ).
        CREATE DATA lr_shlp TYPE HANDLE lo_shlp.
        ASSIGN lr_shlp->* TO <shlp>.
        DATA(lo_shlps) = CAST cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( `SHLP_DESCT` ) ).
        CREATE DATA lr_shlps TYPE HANDLE lo_shlps.
        ASSIGN lr_shlps->* TO <shlps>.
        DATA(lo_return) = cl_abap_tabledescr=>create(
            CAST cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( `DDSHRETVAL` ) ) ).
        CREATE DATA lr_return TYPE HANDLE lo_return.
        ASSIGN lr_return->* TO <return>.

        DATA(lv_name) = CONV char30( help-name ).
        lv_function = `F4IF_GET_SHLP_DESCR`.
        CALL FUNCTION lv_function
          EXPORTING
            shlpname = lv_name
          IMPORTING
            shlp     = <shlp>.

        " a collective search help: its first elementary one
        ASSIGN COMPONENT `SHLPTYPE` OF STRUCTURE <shlp> TO <comp>.
        IF sy-subrc = 0 AND <comp> = 'SC'.
          lv_function = `F4IF_EXPAND_SEARCHHELP`.
          CALL FUNCTION lv_function
            EXPORTING
              shlp_top = <shlp>
            IMPORTING
              shlp_tab = <shlps>.
          IF <shlps> IS INITIAL.
            RETURN.
          ENDIF.
          READ TABLE <shlps> ASSIGNING FIELD-SYMBOL(<first>) INDEX 1.
          <shlp> = <first>.
        ENDIF.

        " every list field - and the field the value is taken from - is an
        " output field, so that the hit list returns it
        ASSIGN COMPONENT `FIELDPROP` OF STRUCTURE <shlp> TO <props>.
        ASSIGN COMPONENT `FIELDDESCR` OF STRUCTURE <shlp> TO <descrs>.
        LOOP AT <props> ASSIGNING FIELD-SYMBOL(<prop>).
          ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <prop> TO <comp>.
          DATA(lv_field) = CONV string( <comp> ).
          ASSIGN COMPONENT `SHLPLISPOS` OF STRUCTURE <prop> TO <comp>.
          lv_pos = <comp>.
          IF lv_pos = 0 AND lv_field <> help-field.
            CONTINUE.
          ENDIF.
          ASSIGN COMPONENT `SHLPOUTPUT` OF STRUCTURE <prop> TO <comp>.
          <comp> = abap_true.
          IF lv_field = help-field.
            INSERT lv_field INTO lt_field INDEX 1.
          ELSE.
            INSERT lv_field INTO TABLE lt_field.
          ENDIF.
        ENDLOOP.
        IF lt_field IS INITIAL.
          RETURN.
        ENDIF.

        lv_function = `F4IF_SELECT_VALUES`.
        CALL FUNCTION lv_function
          EXPORTING
            shlp           = <shlp>
            maxrows        = max
            sort           = abap_true
            call_shlp_exit = abap_true
          TABLES
            return_tab     = <return>.

        " the columns typed by the data elements of the search help
        LOOP AT lt_field INTO lv_field.
          CLEAR lo_type.
          LOOP AT <descrs> ASSIGNING FIELD-SYMBOL(<fd>).
            ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <fd> TO <comp>.
            IF <comp> <> lv_field.
              CONTINUE.
            ENDIF.
            ASSIGN COMPONENT `ROLLNAME` OF STRUCTURE <fd> TO <comp>.
            TRY.
                lo_type ?= cl_abap_typedescr=>describe_by_name( <comp> ).
                IF lo_type->kind <> cl_abap_typedescr=>kind_elem.
                  CLEAR lo_type.
                ENDIF.
              CATCH cx_root.
                CLEAR lo_type.
            ENDTRY.
            EXIT.
          ENDLOOP.
          IF lo_type IS NOT BOUND.
            lo_type = cl_abap_elemdescr=>get_string( ).
          ENDIF.
          INSERT VALUE #( name = lv_field
                          type = lo_type ) INTO TABLE lt_comp.
        ENDLOOP.

        DATA(lo_tab) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
        CREATE DATA result TYPE HANDLE lo_tab.
        ASSIGN result->* TO <tab>.

        " one line of DDSHRETVAL per field and hit, the hit is RECORDPOS
        LOOP AT <return> ASSIGNING FIELD-SYMBOL(<ret>).
          ASSIGN COMPONENT `RECORDPOS` OF STRUCTURE <ret> TO <comp>.
          lv_pos = <comp>.
          IF lv_pos <> lv_last.
            IF <row> IS ASSIGNED.
              INSERT <row> INTO TABLE <tab>.
            ENDIF.
            CREATE DATA lr_row LIKE LINE OF <tab>.
            ASSIGN lr_row->* TO <row>.
            lv_last = lv_pos.
          ENDIF.
          ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <ret> TO <comp>.
          ASSIGN COMPONENT <comp> OF STRUCTURE <row> TO <cell>.
          IF sy-subrc = 0.
            ASSIGN COMPONENT `FIELDVAL` OF STRUCTURE <ret> TO <comp>.
            TRY.
                <cell> = <comp>.
              CATCH cx_root ##NO_HANDLER.
            ENDTRY.
          ENDIF.
        ENDLOOP.
        IF <row> IS ASSIGNED.
          INSERT <row> INTO TABLE <tab>.
        ENDIF.

      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD value_table_select.

    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA lr_text TYPE REF TO data.
    DATA lv_text_table TYPE c LENGTH 30.
    DATA lv_lang_field TYPE string.
    DATA lv_key_field  TYPE string.
    DATA lv_text_field TYPE string.
    FIELD-SYMBOLS <tab>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <texts> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <key>   TYPE any.
    FIELD-SYMBOLS <cell>  TYPE any.
    FIELD-SYMBOLS <tkey>  TYPE any.
    FIELD-SYMBOLS <ttext> TYPE any.

    IF table-table IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( table-table ) ).
        LOOP AT lo_struct->get_components( ) REFERENCE INTO DATA(lr_comp).
          IF line_exists( table-fields[ table_line = lr_comp->name ] ).
            INSERT lr_comp->* INTO TABLE lt_comp.
          ENDIF.
        ENDLOOP.

        " the text table: DD08L knows it as the table with a TEXT foreign
        " key to the value table - not released on ABAP Cloud
        TRY.
            DATA(lv_dd08l) = `DD08L`.
            DATA(lv_check) = CONV char30( table-table ).
            SELECT SINGLE tabname FROM (lv_dd08l)
              WHERE checktable = @lv_check AND frkart = 'TEXT' AND as4local = 'A'
              INTO @lv_text_table.
            IF sy-subrc = 0.
              DATA(lo_text) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( lv_text_table ) ).
              LOOP AT lo_text->get_components( ) REFERENCE INTO DATA(lr_tcomp).
                DATA(lo_tcomp) = lr_tcomp->type.
                IF lo_tcomp->type_kind = cl_abap_typedescr=>typekind_char
                    AND CAST cl_abap_elemdescr( lo_tcomp )->get_relative_name( ) = `SPRAS`.
                  lv_lang_field = lr_tcomp->name.
                ELSEIF lr_tcomp->name = table-field.
                  lv_key_field = lr_tcomp->name.
                ELSEIF lv_text_field IS INITIAL AND lv_lang_field IS NOT INITIAL AND lv_key_field IS NOT INITIAL
                    AND lo_tcomp->type_kind = cl_abap_typedescr=>typekind_char
                    AND CAST cl_abap_elemdescr( lo_tcomp )->output_length >= 10
                    AND NOT line_exists( lt_comp[ name = lr_tcomp->name ] ).
                  lv_text_field = lr_tcomp->name.
                  INSERT VALUE #( name = lr_tcomp->name
                                  type = lr_tcomp->type ) INTO TABLE lt_comp.
                ENDIF.
              ENDLOOP.
            ENDIF.
          CATCH cx_root.
            CLEAR: lv_text_field, lv_lang_field, lv_key_field.
        ENDTRY.

        DATA(lo_tab) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
        CREATE DATA result TYPE HANDLE lo_tab.
        ASSIGN result->* TO <tab>.
        SELECT (table-fields) FROM (table-table) INTO CORRESPONDING FIELDS OF TABLE @<tab> UP TO @max ROWS.

        IF lv_text_field IS INITIAL OR <tab> IS INITIAL.
          RETURN.
        ENDIF.

        DATA(lo_text_tab) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create(
            VALUE #( ( name = lv_key_field  type = CAST #( lo_text->get_component_type( lv_key_field ) ) )
                     ( name = lv_text_field type = CAST #( lo_text->get_component_type( lv_text_field ) ) ) ) ) ).
        CREATE DATA lr_text TYPE HANDLE lo_text_tab.
        ASSIGN lr_text->* TO <texts>.
        DATA(lt_fields) = VALUE string_table( ( lv_key_field ) ( lv_text_field ) ).
        DATA(lv_where) = |{ lv_lang_field } = '{ sy-langu }'|.

        SELECT (lt_fields) FROM (lv_text_table) WHERE (lv_where) INTO CORRESPONDING FIELDS OF TABLE @<texts>.

        LOOP AT <tab> ASSIGNING <row>.
          ASSIGN COMPONENT table-field OF STRUCTURE <row> TO <key>.
          ASSIGN COMPONENT lv_text_field OF STRUCTURE <row> TO <cell>.
          LOOP AT <texts> ASSIGNING FIELD-SYMBOL(<text>).
            ASSIGN COMPONENT lv_key_field OF STRUCTURE <text> TO <tkey>.
            IF <tkey> = <key>.
              ASSIGN COMPONENT lv_text_field OF STRUCTURE <text> TO <ttext>.
              <cell> = <ttext>.
              EXIT.
            ENDIF.
          ENDLOOP.
        ENDLOOP.

      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD rtti_check_value_help.

    IF rtti_get_fixed_values( descr ) IS NOT INITIAL.
      result = abap_true.
      RETURN.
    ENDIF.

    IF rtti_get_search_help( descr )-name IS NOT INITIAL.
      result = abap_true.
      RETURN.
    ENDIF.

    result = xsdbool( rtti_get_value_table( descr )-table IS NOT INITIAL ).

  ENDMETHOD.

  METHOD rtti_get_data_element_texts.

    DATA data_element_name TYPE string.
    DATA lv_do_fallback    TYPE abap_bool.

    data_element_name = val.

    TRY.
        rtti_get_dtel_texts_by_ddic( EXPORTING name        = data_element_name
                                     IMPORTING texts       = result
                                               do_fallback = lv_do_fallback ).
      CATCH cx_root.
        rtti_get_dtel_texts_by_xco( EXPORTING name        = data_element_name
                                    IMPORTING texts       = result
                                              do_fallback = lv_do_fallback ).
    ENDTRY.

    IF lv_do_fallback = abap_true AND result IS INITIAL.
      result-header = val.
      result-long   = val.
      result-medium = val.
      result-short  = val.
    ENDIF.

  ENDMETHOD.

  METHOD rtti_get_dtel_texts_by_ddic.

    DATA ddic_ref TYPE REF TO data.
    DATA: BEGIN OF ddic,
            reptext   TYPE string,
            scrtext_s TYPE string,
            scrtext_m TYPE string,
            scrtext_l TYPE string,
          END OF ddic.
    DATA struct_descr TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS <ddic> TYPE data.
    DATA lo_typedescr TYPE REF TO cl_abap_typedescr.

    CLEAR texts.
    do_fallback = abap_false.

    " raises on ABAP Cloud, where the caller falls back to XCO
    cl_abap_typedescr=>describe_by_name( `T100` ).

    struct_descr ?= cl_abap_structdescr=>describe_by_name( `DFIES` ).

    CREATE DATA ddic_ref TYPE HANDLE struct_descr.

    ASSIGN ddic_ref->* TO <ddic>.
    IF <ddic> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    cl_abap_elemdescr=>describe_by_name( EXPORTING  p_name     = name
                                         RECEIVING p_descr_ref = lo_typedescr
                                         EXCEPTIONS OTHERS     = 1 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CALL METHOD lo_typedescr->(`GET_DDIC_FIELD`)
      RECEIVING
        p_flddescr   = <ddic>
      EXCEPTIONS
        not_found    = 1
        no_ddic_type = 2
        OTHERS       = 3.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    MOVE-CORRESPONDING <ddic> TO ddic.
    texts-header = ddic-reptext.
    texts-short  = ddic-scrtext_s.
    texts-medium = ddic-scrtext_m.
    texts-long   = ddic-scrtext_l.
    do_fallback  = abap_true.

  ENDMETHOD.

  METHOD rtti_get_dtel_texts_by_xco.

    DATA data_element TYPE REF TO object.
    DATA content      TYPE REF TO object.
    DATA exists       TYPE abap_bool.
    DATA lv_xco_cp_abap_dictionary TYPE string.

    CLEAR texts.
    do_fallback = abap_false.

    TRY.
        lv_xco_cp_abap_dictionary = `XCO_CP_ABAP_DICTIONARY`.
        CALL METHOD (lv_xco_cp_abap_dictionary)=>(`DATA_ELEMENT`)
          EXPORTING
            iv_name         = name
          RECEIVING
            ro_data_element = data_element.

        CALL METHOD data_element->(`IF_XCO_AD_DATA_ELEMENT~EXISTS`)
          RECEIVING
            rv_exists = exists.

        IF exists = abap_false.
          RETURN.
        ENDIF.

        CALL METHOD data_element->(`IF_XCO_AD_DATA_ELEMENT~CONTENT`)
          RECEIVING
            ro_content = content.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_HEADING_FIELD_LABEL`)
          RECEIVING
            rs_heading_field_label = texts-header.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_SHORT_FIELD_LABEL`)
          RECEIVING
            rs_short_field_label = texts-short.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_MEDIUM_FIELD_LABEL`)
          RECEIVING
            rs_medium_field_label = texts-medium.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_LONG_FIELD_LABEL`)
          RECEIVING
            rs_long_field_label = texts-long.

        do_fallback = abap_true.

      CATCH cx_root.
        do_fallback = abap_true.
    ENDTRY.

  ENDMETHOD.

  METHOD rtti_get_dtel_name.

    DATA(lo_descr) = rtti_get_value_descr( val ).
    IF lo_descr IS NOT BOUND OR lo_descr->kind <> cl_abap_typedescr=>kind_elem
        OR lo_descr->is_ddic_type( ) = abap_false OR lo_descr->absolute_name CS `\TYPE-POOL=`.
      RETURN.
    ENDIF.
    result = substring_after( val = lo_descr->absolute_name
                              sub = `\TYPE=` ).

  ENDMETHOD.

  METHOD dtel_docu_check.

    DATA lv_object TYPE c LENGTH 60.
    DATA lv_found  TYPE c LENGTH 60.

    IF name IS INITIAL.
      RETURN.
    ENDIF.
    lv_object = to_upper( name ).
    TRY.
        DATA(lv_table) = `DOKIL`.
        SELECT SINGLE object FROM (lv_table)
          WHERE id = 'DE' AND object = @lv_object AND typ = 'E'
          INTO @lv_found.
        result = xsdbool( sy-subrc = 0 ).

      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD dtel_docu_read.

    TYPES:
      BEGIN OF ty_s_line,
        tdformat TYPE c LENGTH 2,
        tdline   TYPE c LENGTH 132,
      END OF ty_s_line.
    DATA lt_line   TYPE STANDARD TABLE OF ty_s_line WITH EMPTY KEY.
    DATA lv_object TYPE c LENGTH 60.
    DATA lv_text   TYPE string.

    IF name IS INITIAL.
      RETURN.
    ENDIF.
    lv_object = to_upper( name ).

    DATA(lv_function) = `DOCU_GET`.
    DO 2 TIMES.
      DATA(lv_langu) = COND sy-langu( WHEN sy-index = 1 THEN sy-langu ELSE 'E' ).
      CLEAR lt_line.
      TRY.
          CALL FUNCTION lv_function
            EXPORTING
              id     = 'DE'
              langu  = lv_langu
              object = lv_object
            TABLES
              line   = lt_line
            EXCEPTIONS
              OTHERS = 1.
          IF sy-subrc = 0 AND lt_line IS NOT INITIAL.
            EXIT.
          ENDIF.
        CATCH cx_root.
          RETURN.
      ENDTRY.
    ENDDO.

    " a paragraph format (anything but the continuation '=' or ' ') starts
    " a new paragraph; tags <..>, symbols &..& and the headings of the
    " standard template go
    LOOP AT lt_line INTO DATA(ls_line).
      DATA(lv_part) = docu_strip( CONV string( ls_line-tdline ) ).
      lv_part = replace( val = lv_part sub = `,,` with = ` ` occ = 0 ).
      IF ls_line-tdformat <> `=` AND ls_line-tdformat <> ` ` AND ls_line-tdformat <> `/=` AND lv_text IS NOT INITIAL.
        INSERT condense( lv_text ) INTO TABLE result.
        CLEAR lv_text.
      ENDIF.
      IF ls_line-tdformat = `/:` OR ls_line-tdformat = `/*`.
        CONTINUE.
      ENDIF.
      lv_text = |{ lv_text } { lv_part }|.
    ENDLOOP.
    lv_text = condense( lv_text ).
    IF lv_text <> ``.
      INSERT lv_text INTO TABLE result.
    ENDIF.
    DELETE result WHERE table_line IS INITIAL.

  ENDMETHOD.

  METHOD value_check.

    DATA lv_where TYPE string.
    DATA lr_found TYPE REF TO data.
    FIELD-SYMBOLS <found> TYPE any.

    result = abap_true.
    IF val IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lo_descr) = rtti_get_value_descr( val ).

    DATA(lt_fix) = rtti_get_fixed_values( lo_descr ).
    IF lt_fix IS NOT INITIAL.
      DATA(lv_value) = |{ val }|.
      result = abap_false.
      LOOP AT lt_fix INTO DATA(ls_fix).
        IF ( ls_fix-high IS INITIAL AND lv_value = ls_fix-low )
            OR ( ls_fix-high IS NOT INITIAL AND lv_value >= ls_fix-low AND lv_value <= ls_fix-high ).
          result = abap_true.
          RETURN.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    DATA(ls_table) = rtti_get_value_table( lo_descr ).
    IF ls_table-table IS INITIAL OR ls_table-field IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        " the value as a literal - a dynamic WHERE names no variable the
        " same way on every release
        lv_where = |{ ls_table-field } = '{ replace( val = |{ val }| sub = `'` with = `''` occ = 0 ) }'|.
        CREATE DATA lr_found LIKE val.
        ASSIGN lr_found->* TO <found>.
        SELECT SINGLE (ls_table-field) FROM (ls_table-table) WHERE (lv_where) INTO @<found>.
        result = xsdbool( sy-subrc = 0 ).
      CATCH cx_root.
        result = abap_true.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
