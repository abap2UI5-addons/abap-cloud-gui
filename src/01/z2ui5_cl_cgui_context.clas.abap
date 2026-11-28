CLASS z2ui5_cl_cgui_context DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_codepoint TYPE STANDARD TABLE OF i WITH EMPTY KEY.

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

    "! the rows of entity - a CDS view entity, or a table or view of the
    "! DDIC - as the value help of a field:
    "! what @Consumption.valueHelpDefinition names. On ABAP Cloud as on premise;
    "! unbound when it cannot be read. Sorted by column (else the first
    "! one), and restricted by pattern on it - what the user typed with a
    "! * or + - as the classic F4 does
    CLASS-METHODS entity_select
      IMPORTING
        entity        TYPE clike
        max           TYPE i DEFAULT 500
        column        TYPE clike OPTIONAL
        pattern       TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! the rows of value table table with the text of its text table in
    "! the logon language as last column - unbound when it cannot be read;
    "! sorted by its key field and restricted by pattern on it
    CLASS-METHODS value_table_select
      IMPORTING
        table         TYPE ty_s_value_table
        max           TYPE i DEFAULT 500
        pattern       TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! a condition column LIKE pattern for a dynamic WHERE: * and + of
    "! pattern are the wildcards, % _ # and quotes are escaped - empty
    "! without a * or + in pattern
    CLASS-METHODS sql_like
      IMPORTING
        column        TYPE clike
        pattern       TYPE clike
      RETURNING
        VALUE(result) TYPE string.

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

    "! the conversion exit ALPHA of the data element of val, as SAP GUI
    "! runs it on input: 4711 into a KUNNR is 0000004711 - else val stays
    CLASS-METHODS conv_alpha_in
      CHANGING
        val TYPE any.

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

    "! val in base64, for the data URI of a download - the kernel
    "! (CL_WEB_HTTP_UTILITY, CL_HTTP_UTILITY, named as strings as abap-util
    "! does it), plain ABAP where neither is there
    CLASS-METHODS conv_encode_x_base64
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    "! the bytes of base64 val, for the data URI of an upload - the kernel
    "! as conv_encode_x_base64( ), plain ABAP where neither is there (a
    "! character outside the alphabet ends it)
    CLASS-METHODS conv_decode_x_base64
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    "! the bytes of percent-encoded val - %XX is the byte XX, every other
    "! character its UTF-8, a + stays a + (the data of a data URI, RFC 2397;
    "! not a form field)
    CLASS-METHODS url_unescape_x
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    "! val escaped for the text or an attribute of XML: &, <, > and " as
    "! entities, LF, CR and TAB as character references, the control
    "! characters XML 1.0 forbids dropped - copied from abap-util
    "! (zabaputil_cl_util_context=>c_escape_xml)
    CLASS-METHODS c_escape_xml
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the MIME type of a file by the extension of its name - copied from
    "! abap-util (zabaputil_cl_util_context=>file_get_mimetype)
    CLASS-METHODS file_get_mimetype
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! val without the blanks and tabs at either end - copied from abap-util
    "! (zabaputil_cl_util_context=>c_trim)
    CLASS-METHODS c_trim
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

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

    TYPES:
      "! the DDIC reference field of an amount (CURR, referencing a CUKY)
      "! or a quantity (QUAN, referencing a UNIT): the component of the
      "! same structure that holds the currency or the unit
      BEGIN OF ty_s_ref_field,
        name     TYPE string,
        currency TYPE abap_bool,
      END OF ty_s_ref_field.

    "! the core:require of the types the ui5_binding_* methods name: the
    "! aliases DateType, TimeType, FloatType, IntType, CurrType and
    "! UnitType. Set it once on the View or on any control above the bound
    "! ones - the aliases work on UI5 1.71 and on 2.x, where the global
    "! names of the types are gone
    CLASS-METHODS ui5_get_type_require
      RETURNING
        VALUE(result) TYPE string.

    "! the type alias of ui5_get_type_require( ) for an ABAP type kind
    "! (cl_abap_typedescr=>typekind_*) - empty for a kind that is shown as
    "! it is (characters, NUMC, strings, ...). check_currency / check_unit
    "! choose CurrType / UnitType for an amount or a quantity whose
    "! currency or unit is bound beside it
    CLASS-METHODS ui5_get_model_type
      IMPORTING
        type_kind      TYPE clike
        check_currency TYPE abap_bool DEFAULT abap_false
        check_unit     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)  TYPE string.

    "! the formatOptions that go with ui5_get_model_type( ), as a binding
    "! object literal: the source pattern of a date or a time as the model
    "! carries it (yyyy-MM-dd, HH:mm:ss), the decimals of a packed number,
    "! the grouping of every number, no measure for an amount or a
    "! quantity. Empty when the kind has no type
    CLASS-METHODS ui5_get_format_options
      IMPORTING
        type_kind      TYPE clike
        decimals       TYPE i         DEFAULT 0
        check_currency TYPE abap_bool DEFAULT abap_false
        check_unit     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)  TYPE string.

    "! the binding of path with the type and the format options of an ABAP
    "! type kind - {path} when the kind has no type. currency_path /
    "! unit_path bind the currency or the unit as the second part of a
    "! Currency / Unit type. The types are the aliases of
    "! ui5_get_type_require( ), which the view has to carry
    CLASS-METHODS ui5_binding_by_kind
      IMPORTING
        path          TYPE clike
        type_kind     TYPE clike
        decimals      TYPE i     DEFAULT 0
        currency_path TYPE clike OPTIONAL
        unit_path     TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    "! the binding of path with the type of val - val is only described,
    "! never read: a field of the bound attribute, or of a row of the same
    "! type for a relative path in a table template. A TIMESTAMP or a
    "! TIMESTAMPL travels as an ISO text and stays {path}
    CLASS-METHODS ui5_binding_typed
      IMPORTING
        path          TYPE clike
        val           TYPE any
        currency_path TYPE clike OPTIONAL
        unit_path     TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    "! the binding of the component comp of struc with a path relative to
    "! the row (`PRICE`) - for a cell of a table template. An amount or a
    "! quantity whose reference field the DDIC names in the same structure
    "! is bound with it as Currency / Unit (rtti_get_ref_field)
    CLASS-METHODS ui5_binding_typed_comp
      IMPORTING
        struc         TYPE any
        comp          TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! the reference field of the component comp of struc as the DDIC has
    "! it - empty for a type that is no DDIC structure, a reference field
    "! outside struc, and always on ABAP Cloud and in the transpiled
    "! runtime (DDFIELDS is not released)
    CLASS-METHODS rtti_get_ref_field
      IMPORTING
        struc         TYPE any
        comp          TYPE clike
      RETURNING
        VALUE(result) TYPE ty_s_ref_field.

    " ---------- what z2ui5_cl_cgui_xlsx takes from the system: ZIP, the XML
    " reader, type kinds and a few conversions - copied from abap-util
    " (zabaputil_cl_util_context), so that the XLSX class names no SAP class
    " and its copy here differs from the one there by the names alone

    CLASS-DATA cv_char_util_newline          TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_char_util_cr_lf            TYPE c LENGTH 2 READ-ONLY.
    CLASS-DATA cv_char_util_horizontal_tab   TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_table   TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_dref    TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_oref    TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_struct1 TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_struct2 TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_date    TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_time    TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_char    TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_num     TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_string  TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_hex     TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_typekind_xstring TYPE c LENGTH 1 READ-ONLY.
    CLASS-DATA cv_typedescr_kind_elem        TYPE c LENGTH 1 READ-ONLY.

    CLASS-METHODS class_constructor.

    TYPES:
      BEGIN OF ty_s_zip_file,
        name    TYPE string,
        content TYPE xstring,
      END OF ty_s_zip_file.
    TYPES ty_t_zip_file TYPE STANDARD TABLE OF ty_s_zip_file WITH EMPTY KEY.

    "! the files as one ZIP archive
    CLASS-METHODS zip_pack
      IMPORTING
        files         TYPE ty_t_zip_file
      RETURNING
        VALUE(result) TYPE xstring.

    "! the files of a ZIP archive - z2ui5_cx_cgui_error for data that is none
    CLASS-METHODS zip_unpack
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE ty_t_zip_file.

    TYPES:
      BEGIN OF ty_s_xml_attribute,
        name  TYPE string,
        value TYPE string,
      END OF ty_s_xml_attribute.
    TYPES ty_t_xml_attribute TYPE STANDARD TABLE OF ty_s_xml_attribute WITH EMPTY KEY.

    CONSTANTS:
      "! the kinds of node xml_reader_next( ) hands out - `end` (initial) when
      "! the document is read to its end
      BEGIN OF cs_xml_node,
        open  TYPE string VALUE `O` ##NO_TEXT,
        close TYPE string VALUE `C` ##NO_TEXT,
        value TYPE string VALUE `V` ##NO_TEXT,
        end   TYPE string VALUE `` ##NO_TEXT,
      END OF cs_xml_node.

    "! A reader over an XML document, node by node and without building a
    "! tree. The handle goes to xml_reader_next( ); it is the sXML reader,
    "! which is there on every release down to 7.02 and released on ABAP
    "! Cloud. A text of blanks only arrives where it is all an element
    "! holds; the indentation between two elements is not reported
    CLASS-METHODS xml_reader_create
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO object.

    "! The next node of the document: an element opening (name, and its
    "! attributes when t_attribute is asked for), its text (value) or its
    "! end (name). Names come without their namespace prefix. kind is
    "! initial (cs_xml_node-end) behind the last node
    CLASS-METHODS xml_reader_next
      IMPORTING
        reader      TYPE REF TO object
      EXPORTING
        kind        TYPE string
        name        TYPE string
        value       TYPE string
        t_attribute TYPE ty_t_xml_attribute.

    CLASS-METHODS c_trim_upper
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS c_ends_with
      IMPORTING
        val           TYPE clike
        suffix        TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! a number out of a text in either notation (`1.234,56`, `1,234.56`) -
    "! 0 for a text that is none
    CLASS-METHODS conv_string_to_number
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE decfloat34.

    "! whether a type of that name is an ABAP boolean (ABAP_BOOL, XFELD, ...)
    CLASS-METHODS boolean_check_by_name
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! whether a type kind is a number: i, int1, int2, int8, p, f,
    "! decfloat16, decfloat34
    CLASS-METHODS rtti_check_typekind_number
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! the name of the type of an elementary field (its data element) -
    "! empty for a type without one
    CLASS-METHODS rtti_get_type_name
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! the components of a structure, or of the line of a table - an include
    "! as its fields
    CLASS-METHODS rtti_get_t_attri_by_any
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE abap_component_tab.

    "! a standard table whose line has one string component per name
    CLASS-METHODS rtti_create_tab_by_names
      IMPORTING
        val           TYPE string_table
      RETURNING
        VALUE(result) TYPE REF TO data.

    "! The current time stamp in whole seconds, as GET TIME STAMP fills a
    "! TIMESTAMP: truncated. time_get_timestampl assigned to a TIMESTAMP
    "! field rounds instead, and can land a second in the future.
    CLASS-METHODS time_get_timestamp
      RETURNING
        VALUE(result) TYPE timestamp.

    "! tz: an SAP time zone key (TTZZ, at most six characters: `UTC`,
    "! `CET`, `EST`) - not an IANA name like Europe/Berlin. A zone that is
    "! no key, or a conversion that fails, raises z2ui5_cx_cgui_error;
    "! it returned an empty or wrong date and time.
    CLASS-METHODS time_stampl_to_tz
      IMPORTING
        val  TYPE timestampl
        tz   TYPE clike DEFAULT `UTC`
      EXPORTING
        date TYPE d
        time TYPE t.

    "! The Unicode code points of a text, one row per character. A
    "! character outside the Basic Multilingual Plane, which a string
    "! holds as two UTF-16 code units, is one row
    CLASS-METHODS c_get_codepoints
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE ty_t_codepoint.

    "! Run a conversion exit: CONVERSION_EXIT_&lt;convexit&gt;_INPUT, or _OUTPUT.
    "!
    "!   conv_exit( EXPORTING convexit = `MATN1` CHANGING value = lv_matnr ).
    "!   conv_exit( EXPORTING convexit = `ALPHA` from = i_vbeln CHANGING value = lv_docno ).
    "!
    "! A value the exit refuses - a unit that does not exist, a material
    "! number too long - raises z2ui5_cx_cgui_error with the exit's own
    "! message; VALUE is then left as it was. A caller that can live with
    "! the unconverted value catches it and carries on.
    "!
    "! @parameter convexit | the exit's name: ALPHA, MATN1, CUNIT, HUID, ...
    "! @parameter output   | abap_true: the _OUTPUT direction
    "! @parameter from     | the value to convert, when it is not VALUE itself. The
    "!                       target's type decides the result - ALPHA pads to its length
    "! @parameter value    | converted in place, or the target of FROM
    "! @raising z2ui5_cx_cgui_error | the exit refused the value, or does not exist
    CLASS-METHODS conv_exit
      IMPORTING
        convexit TYPE clike
        output   TYPE abap_bool DEFAULT abap_false
        from     TYPE any       OPTIONAL
      CHANGING
        value    TYPE data
      RAISING
        z2ui5_cx_cgui_error.

    "! the fixed values of the domain of a data element, by its name - the
    "! form the XLSX class asks for (abap-util's rtti_get_t_ddic_fixed_values),
    "! answered by rtti_get_fixed_values
    CLASS-METHODS rtti_get_t_ddic_fixed_values
      IMPORTING
        rollname      TYPE clike
      RETURNING
        VALUE(result) TYPE ty_t_fix_val.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS rtti_expand_components
      IMPORTING
        val           TYPE abap_component_tab
        depth         TYPE i DEFAULT 0
      RETURNING
        VALUE(result) TYPE abap_component_tab.

    "! the values of fields of row, one text - a row of a value table and
    "! a row of its text table compared on the fields they share
    CLASS-METHODS row_key
      IMPORTING
        row           TYPE any
        fields        TYPE string_table
      RETURNING
        VALUE(result) TYPE string.

    " the character set c_escape_xml guards against, built on first use (a
    " class_constructor is the alternative, and a known trap)
    CLASS-DATA gv_xml_escape_specials TYPE string.
    CLASS-DATA gv_xml_escape_controls TYPE string.

    CLASS-METHODS conv_decode_x_base64_abap
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE xstring.

    CLASS-METHODS conv_encode_x_base64_abap
      IMPORTING
        val           TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

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

    " the zone trimmed - raises when it is longer than the six characters
    " of an SAP time zone key: `Europe/Berlin` was cut to `Europe`
    CLASS-METHODS time_check_zone
      IMPORTING
        tz            TYPE clike
      RETURNING
        VALUE(result) TYPE string.

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

    " the kernel first - copied from abap-util (zabaputil_cl_util_context=>
    " conv_decode_x_base64): CL_WEB_HTTP_UTILITY on ABAP Cloud, CL_HTTP_UTILITY
    " on premise, both named as strings. Where neither decodes, the plain
    " ABAP below instead of an exception
    DATA lv_web_http_name TYPE c LENGTH 19.
    DATA classname        TYPE c LENGTH 15.

    " the line breaks of a wrapped encoding are no characters of it
    DATA(lv_val) = val.
    REPLACE ALL OCCURRENCES OF |\n| IN lv_val WITH ``.
    REPLACE ALL OCCURRENCES OF |\r| IN lv_val WITH ``.
    REPLACE ALL OCCURRENCES OF ` ` IN lv_val WITH ``.

    TRY.
        lv_web_http_name = `CL_WEB_HTTP_UTILITY`.
        CALL METHOD (lv_web_http_name)=>(`DECODE_X_BASE64`)
          EXPORTING
            encoded = lv_val
          RECEIVING
            decoded = result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
        " not there - the classic class below
    ENDTRY.

    TRY.
        classname = `CL_HTTP_UTILITY`.
        CALL METHOD (classname)=>(`DECODE_X_BASE64`)
          EXPORTING
            encoded = lv_val
          RECEIVING
            decoded = result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
        " neither - plain ABAP
    ENDTRY.

    result = conv_decode_x_base64_abap( lv_val ).

  ENDMETHOD.

  METHOD conv_decode_x_base64_abap.

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

    " the kernel first, as conv_decode_x_base64( )
    DATA lv_web_http_name TYPE c LENGTH 19.
    DATA classname        TYPE c LENGTH 15.

    TRY.
        lv_web_http_name = `CL_WEB_HTTP_UTILITY`.
        CALL METHOD (lv_web_http_name)=>(`ENCODE_X_BASE64`)
          EXPORTING
            unencoded = val
          RECEIVING
            encoded   = result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
        " not there - the classic class below
    ENDTRY.

    TRY.
        classname = `CL_HTTP_UTILITY`.
        CALL METHOD (classname)=>(`ENCODE_X_BASE64`)
          EXPORTING
            unencoded = val
          RECEIVING
            encoded   = result.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
        " neither - plain ABAP
    ENDTRY.

    result = conv_encode_x_base64_abap( val ).

  ENDMETHOD.

  METHOD conv_encode_x_base64_abap.

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

  METHOD url_unescape_x.

    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_text TYPE string.
    DATA lv_utf8 TYPE xstring.

    DATA(lv_len) = strlen( val ).
    DATA(lv_off) = 0.
    WHILE lv_off < lv_len.
      DATA(lv_char) = substring( val = val off = lv_off len = 1 ).
      " only two hex digits make an escape - %ZZ stays as it is
      DATA(lv_hex) = ``.
      IF lv_char = `%` AND lv_off + 2 < lv_len.
        lv_hex = to_upper( substring( val = val off = lv_off + 1 len = 2 ) ).
      ENDIF.
      IF lv_hex IS NOT INITIAL AND lv_hex CO `0123456789ABCDEF`.
        " the characters before it as UTF-8, then the byte
        IF lv_text IS NOT INITIAL.
          lv_utf8 = conv_get_xstring_by_string( lv_text ).
          CONCATENATE result lv_utf8 INTO result IN BYTE MODE.
          CLEAR lv_text.
        ENDIF.
        lv_byte = lv_hex.
        CONCATENATE result lv_byte INTO result IN BYTE MODE.
        lv_off = lv_off + 3.
        CONTINUE.
      ENDIF.
      lv_text = lv_text && lv_char.
      lv_off = lv_off + 1.
    ENDWHILE.
    IF lv_text IS NOT INITIAL.
      lv_utf8 = conv_get_xstring_by_string( lv_text ).
      CONCATENATE result lv_utf8 INTO result IN BYTE MODE.
    ENDIF.

  ENDMETHOD.

  METHOD c_escape_xml.

    " copied from abap-util - the line break, carriage return and tab as
    " string templates instead of its cv_char_util_* constants (this class
    " has no class_constructor)
    "
    " one CA scan up front: replace( occ = 0 ) copies the whole string on
    " every call even when nothing matches, and a value without any special
    " character is the common case
    IF gv_xml_escape_specials IS INITIAL.
      " the XML-illegal control characters as one string, built from their
      " UTF-8 bytes; behind them the two non-characters U+FFFE and U+FFFF.
      " Without a codepage API the set stays empty - the controls are then
      " kept, everything else is escaped as before
      gv_xml_escape_controls = conv_get_string_by_xstring(
          CONV xstring( `000102030405060708` && `0B0C` && `0E0F101112131415161718191A1B1C1D1E1F`
                        && `EFBFBE` && `EFBFBF` ) ).
      gv_xml_escape_specials = `&<>"` && |\n| && |\r| && |\t| && gv_xml_escape_controls.
    ENDIF.
    result = val.
    IF result NA gv_xml_escape_specials.
      RETURN.
    ENDIF.

    result = replace( val  = result
                      sub  = `&`
                      with = `&amp;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = `<`
                      with = `&lt;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = `>`
                      with = `&gt;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = `"`
                      with = `&quot;`
                      occ  = 0 ).
    " whitespace as character references - attribute-value normalization
    " would turn a literal one into a blank
    result = replace( val  = result
                      sub  = |\n|
                      with = `&#xA;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = |\r|
                      with = `&#xD;`
                      occ  = 0 ).
    result = replace( val  = result
                      sub  = |\t|
                      with = `&#x9;`
                      occ  = 0 ).

    " what is left of the control range is illegal in XML 1.0 outright - it
    " cannot even be written as a character reference, and one such byte
    " makes the whole document invalid (Excel repairs the workbook, UI5
    " refuses the view). It carries no meaning in a text, so it is dropped
    IF result CA gv_xml_escape_controls.
      " one replace per character, no regex
      DATA(lv_off) = 0.
      DATA(lv_len) = strlen( gv_xml_escape_controls ).
      WHILE lv_off < lv_len.
        result = replace( val  = result
                          sub  = gv_xml_escape_controls+lv_off(1)
                          with = ``
                          occ  = 0 ).
        lv_off = lv_off + 1.
      ENDWHILE.
    ENDIF.

  ENDMETHOD.

  METHOD c_trim.

    result = val.
    " blanks and tabs alternate at either end - strip until nothing changes
    DO.
      DATA(lv_before) = result.
      result = shift_left( shift_right( result ) ).
      result = shift_right( val = result
                            sub = |\t| ).
      result = shift_left( val = result
                           sub = |\t| ).
      IF result = lv_before.
        EXIT.
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD file_get_mimetype.

    DATA(lv_name) = to_lower( c_trim( val ) ).
    SPLIT lv_name AT `.` INTO TABLE DATA(lt_parts).
    " no name, no extension - an empty name splits into no part at all
    IF lt_parts IS INITIAL.
      result = `application/octet-stream`.
      RETURN.
    ENDIF.
    DATA(lv_ext) = lt_parts[ lines( lt_parts ) ].

    CASE lv_ext.
      WHEN `txt` OR `text` OR `log` OR `md`.
        result = `text/plain`.
      WHEN `html` OR `htm`.
        result = `text/html`.
      WHEN `css`.
        result = `text/css`.
      WHEN `csv`.
        result = `text/csv`.
      WHEN `js` OR `mjs`.
        result = `text/javascript`.
      WHEN `json`.
        result = `application/json`.
      WHEN `xml`.
        result = `application/xml`.
      WHEN `pdf`.
        result = `application/pdf`.
      WHEN `zip`.
        result = `application/zip`.
      WHEN `png`.
        result = `image/png`.
      WHEN `jpg` OR `jpeg`.
        result = `image/jpeg`.
      WHEN `gif`.
        result = `image/gif`.
      WHEN `svg`.
        result = `image/svg+xml`.
      WHEN `webp`.
        result = `image/webp`.
      WHEN `ico`.
        result = `image/x-icon`.
      WHEN `mp3`.
        result = `audio/mpeg`.
      WHEN `mp4`.
        result = `video/mp4`.
      WHEN `woff`.
        result = `font/woff`.
      WHEN `woff2`.
        result = `font/woff2`.
      WHEN `ttf`.
        result = `font/ttf`.
      WHEN `otf`.
        result = `font/otf`.
      WHEN `xlsx`.
        result = `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`.
      WHEN `xls`.
        result = `application/vnd.ms-excel`.
      WHEN `docx`.
        result = `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
      WHEN `doc`.
        result = `application/msword`.
      WHEN `pptx`.
        result = `application/vnd.openxmlformats-officedocument.presentationml.presentation`.
      WHEN `ppt`.
        result = `application/vnd.ms-powerpoint`.
      WHEN OTHERS.
        result = `application/octet-stream`.
    ENDCASE.

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

    result = cl_abap_datadescr=>get_data_type_kind( val ).

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

  METHOD entity_select.

    DATA lv_entity TYPE c LENGTH 30.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.

    IF entity IS INITIAL.
      RETURN.
    ENDIF.
    lv_entity = to_upper( entity ).
    " an unknown name is a classic exception, no class-based one
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = lv_entity
                                         RECEIVING  p_descr_ref    = DATA(lo_type)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0 OR lo_type->kind <> cl_abap_typedescr=>kind_struct.
      RETURN.
    ENDIF.
    TRY.
        DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).
        DATA(lo_table) = cl_abap_tabledescr=>create( lo_struct ).
        CREATE DATA result TYPE HANDLE lo_table.
        ASSIGN result->* TO <tab>.
        " the first rows of the sort order, not any - and those the user
        " asked for with a pattern
        DATA(lv_order) = to_upper( column ).
        IF lv_order IS INITIAL.
          READ TABLE lo_struct->components INTO DATA(ls_first) INDEX 1.
          lv_order = ls_first-name.
        ENDIF.
        DATA(lv_where) = sql_like( column  = lv_order
                                   pattern = pattern ).
        SELECT * FROM (lv_entity) WHERE (lv_where) ORDER BY (lv_order) INTO TABLE @<tab> UP TO @max ROWS.
      CATCH cx_root.
        " no such entity, no structure, or no read access
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD value_table_select.

    TYPES:
      BEGIN OF ty_s_text,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_text.
    DATA lt_comp       TYPE cl_abap_structdescr=>component_table.
    DATA lt_text_comp  TYPE cl_abap_structdescr=>component_table.
    DATA lt_join       TYPE string_table.
    DATA lt_in         TYPE string_table.
    DATA lt_text_by_key TYPE HASHED TABLE OF ty_s_text WITH UNIQUE KEY key.
    DATA lr_text       TYPE REF TO data.
    DATA lr_tcomp      TYPE REF TO abap_componentdescr.
    DATA lo_text       TYPE REF TO cl_abap_structdescr.
    DATA lv_text_table TYPE c LENGTH 30.
    DATA lv_lang_field TYPE string.
    DATA lv_key_field  TYPE string.
    DATA lv_text_field TYPE string.
    DATA lv_where      TYPE string.
    FIELD-SYMBOLS <tab>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <texts> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <key>   TYPE any.
    FIELD-SYMBOLS <cell>  TYPE any.
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
              lo_text = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( lv_text_table ) ).
              LOOP AT lo_text->get_components( ) REFERENCE INTO lr_tcomp.
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
        " the first rows by the key, not any - and those the user asked
        " for with a pattern
        lv_where = sql_like( column  = table-field
                             pattern = pattern ).
        SELECT (table-fields) FROM (table-table) WHERE (lv_where) ORDER BY (table-field)
          INTO CORRESPONDING FIELDS OF TABLE @<tab> UP TO @max ROWS.

      CATCH cx_root.
        CLEAR result.
        RETURN.
    ENDTRY.

    IF lv_text_field IS INITIAL OR <tab> IS INITIAL.
      RETURN.
    ENDIF.

    " the texts of the values read - not the whole text table - matched on
    " every field the text table shares with the value table: a region's
    " text belongs to its country too. Without them the values stay
    TRY.
        LOOP AT lo_text->get_components( ) REFERENCE INTO lr_tcomp.
          IF lr_tcomp->name <> lv_lang_field AND lr_tcomp->name <> lv_text_field
              AND line_exists( lt_comp[ name = lr_tcomp->name ] ).
            INSERT CONV string( lr_tcomp->name ) INTO TABLE lt_join.
            INSERT VALUE #( name = lr_tcomp->name
                            type = CAST #( lr_tcomp->type ) ) INTO TABLE lt_text_comp.
          ENDIF.
        ENDLOOP.
        IF NOT line_exists( lt_join[ table_line = lv_key_field ] ).
          RETURN.
        ENDIF.
        INSERT VALUE #( name = lv_text_field
                        type = CAST #( lo_text->get_component_type( lv_text_field ) ) ) INTO TABLE lt_text_comp.
        DATA(lo_text_tab) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_text_comp ) ).
        CREATE DATA lr_text TYPE HANDLE lo_text_tab.
        ASSIGN lr_text->* TO <texts>.
        DATA(lt_fields) = lt_join.
        INSERT lv_text_field INTO TABLE lt_fields.

        " the key values as literals - a dynamic condition naming a host
        " variable is written differently on 7.02 and in strict mode
        LOOP AT <tab> ASSIGNING <row>.
          ASSIGN COMPONENT table-field OF STRUCTURE <row> TO <key>.
          DATA(lv_literal) = |'{ replace( val = |{ <key> }| sub = `'` with = `''` occ = 0 ) }'|.
          IF NOT line_exists( lt_in[ table_line = lv_literal ] ).
            INSERT lv_literal INTO TABLE lt_in.
          ENDIF.
        ENDLOOP.
        lv_where = |{ lv_lang_field } = '{ sy-langu }' AND { lv_key_field } IN ( { concat_lines_of( table = lt_in sep = `, ` ) } )|.

        SELECT (lt_fields) FROM (lv_text_table) WHERE (lv_where) INTO CORRESPONDING FIELDS OF TABLE @<texts>.

        LOOP AT <texts> ASSIGNING FIELD-SYMBOL(<text>).
          ASSIGN COMPONENT lv_text_field OF STRUCTURE <text> TO <ttext>.
          INSERT VALUE #( key  = row_key( row    = <text>
                                          fields = lt_join )
                          text = <ttext> ) INTO TABLE lt_text_by_key.
        ENDLOOP.
        LOOP AT <tab> ASSIGNING <row>.
          ASSIGN COMPONENT lv_text_field OF STRUCTURE <row> TO <cell>.
          DATA(lv_row_key) = row_key( row    = <row>
                                      fields = lt_join ).
          READ TABLE lt_text_by_key INTO DATA(ls_text) WITH TABLE KEY key = lv_row_key.
          IF sy-subrc = 0.
            <cell> = ls_text-text.
          ENDIF.
        ENDLOOP.
      CATCH cx_root ##NO_HANDLER.
        " no texts - the values all the same
    ENDTRY.

  ENDMETHOD.

  METHOD conv_alpha_in.

    FIELD-SYMBOLS <char> TYPE c.

    TRY.
        DATA(lo_elem) = CAST cl_abap_elemdescr( cl_abap_typedescr=>describe_by_data( val ) ).
        IF lo_elem->type_kind <> cl_abap_typedescr=>typekind_char OR lo_elem->is_ddic_type( ) = abap_false.
          RETURN.
        ENDIF.
        IF lo_elem->get_ddic_field( )-convexit <> `ALPHA`.
          RETURN.
        ENDIF.
        ASSIGN val TO <char>.
        <char> = |{ <char> ALPHA = IN }|.
      CATCH cx_root ##NO_HANDLER.
        " no DDIC (ABAP Cloud, a type of the program) - no conversion
    ENDTRY.

  ENDMETHOD.

  METHOD row_key.

    DATA lt_value TYPE string_table.
    FIELD-SYMBOLS <value> TYPE any.

    LOOP AT fields INTO DATA(lv_field).
      ASSIGN COMPONENT lv_field OF STRUCTURE row TO <value>.
      IF sy-subrc = 0.
        INSERT |{ <value> }| INTO TABLE lt_value.
      ENDIF.
    ENDLOOP.
    result = concat_lines_of( table = lt_value sep = cl_abap_char_utilities=>horizontal_tab ).

  ENDMETHOD.

  METHOD sql_like.

    DATA(lv_pattern) = condense( CONV string( pattern ) ).
    IF lv_pattern NA `*+` OR column IS INITIAL.
      RETURN.
    ENDIF.
    " the escape character first, then what LIKE reads as wildcards, then
    " the wildcards of SAP GUI
    lv_pattern = replace( val = lv_pattern sub = `#` with = `##` occ = 0 ).
    lv_pattern = replace( val = lv_pattern sub = `%` with = `#%` occ = 0 ).
    lv_pattern = replace( val = lv_pattern sub = `_` with = `#_` occ = 0 ).
    lv_pattern = replace( val = lv_pattern sub = `'` with = `''` occ = 0 ).
    lv_pattern = replace( val = lv_pattern sub = `*` with = `%` occ = 0 ).
    lv_pattern = replace( val = lv_pattern sub = `+` with = `_` occ = 0 ).
    result = |{ to_upper( column ) } LIKE '{ lv_pattern }' ESCAPE '#'|.

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
    " A dynamic call checks its actual parameters against the formal ones at
    " runtime and converts nothing, so both sides are typed exactly as XCO
    " declares them. The name is sxco_ad_object_name (CHAR30), passed by
    " reference - a string there raised CX_SY_DYN_CALL_ILLEGAL_TYPE. Each
    " label is if_xco_dtel_content=>ts_field_label, a text (CHAR60) and its
    " length (NUMC2) - received into a string, every one raised the same.
    " Both ended in the CATCH below, so on ABAP Cloud every data element came
    " back with empty texts (or its own name, as the caller's fallback). The
    " shapes are written out because the XCO types exist on cloud only
    DATA lv_name TYPE c LENGTH 30.
    DATA: BEGIN OF ls_label,
            text   TYPE c LENGTH 60,
            length TYPE n LENGTH 2,
          END OF ls_label.

    CLEAR texts.
    do_fallback = abap_false.

    TRY.
        lv_name = name.
        lv_xco_cp_abap_dictionary = `XCO_CP_ABAP_DICTIONARY`.
        CALL METHOD (lv_xco_cp_abap_dictionary)=>(`DATA_ELEMENT`)
          EXPORTING
            iv_name         = lv_name
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
            rs_heading_field_label = ls_label.
        texts-header = ls_label-text.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_SHORT_FIELD_LABEL`)
          RECEIVING
            rs_short_field_label = ls_label.
        texts-short = ls_label-text.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_MEDIUM_FIELD_LABEL`)
          RECEIVING
            rs_medium_field_label = ls_label.
        texts-medium = ls_label-text.

        CALL METHOD content->(`IF_XCO_DTEL_CONTENT~GET_LONG_FIELD_LABEL`)
          RECEIVING
            rs_long_field_label = ls_label.
        texts-long = ls_label-text.

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

  METHOD ui5_get_type_require.

    result = `{DateType: 'sap/ui/model/type/Date', TimeType: 'sap/ui/model/type/Time', `
          && `FloatType: 'sap/ui/model/type/Float', IntType: 'sap/ui/model/type/Integer', `
          && `CurrType: 'sap/ui/model/type/Currency', UnitType: 'sap/ui/model/type/Unit'}`.

  ENDMETHOD.

  METHOD ui5_get_model_type.

    IF check_currency = abap_true.
      result = `CurrType`.
      RETURN.
    ENDIF.
    IF check_unit = abap_true.
      result = `UnitType`.
      RETURN.
    ENDIF.

    CASE type_kind.
      WHEN cl_abap_typedescr=>typekind_date.
        result = `DateType`.
      WHEN cl_abap_typedescr=>typekind_time.
        result = `TimeType`.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR `8`.
        " `8`: typekind_int8, a constant lower releases do not have
        result = `IntType`.
      WHEN cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        result = `FloatType`.
    ENDCASE.

  ENDMETHOD.

  METHOD ui5_get_format_options.

    IF check_currency = abap_true OR check_unit = abap_true.
      " the digits come with the currency or the unit (CLDR), the code is
      " a column or a field of its own
      result = `{showMeasure: false}`.
      RETURN.
    ENDIF.

    CASE ui5_get_model_type( type_kind ).
      WHEN `DateType`.
        result = `{source: {pattern: 'yyyy-MM-dd'}}`.
      WHEN `TimeType`.
        result = `{source: {pattern: 'HH:mm:ss'}}`.
      WHEN `IntType`.
        result = `{groupingEnabled: true}`.
      WHEN `FloatType`.
        IF type_kind = cl_abap_typedescr=>typekind_packed.
          result = |\{minFractionDigits: { decimals }, maxFractionDigits: { decimals }, groupingEnabled: true\}|.
        ELSE.
          result = `{groupingEnabled: true}`.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD ui5_binding_by_kind.

    DATA(lv_currency) = xsdbool( currency_path IS NOT INITIAL ).
    DATA(lv_unit) = xsdbool( lv_currency = abap_false AND unit_path IS NOT INITIAL ).

    DATA(lv_type) = ui5_get_model_type( type_kind      = type_kind
                                        check_currency = lv_currency
                                        check_unit     = lv_unit ).
    IF lv_type IS INITIAL.
      result = |\{{ path }\}|.
      RETURN.
    ENDIF.

    DATA(lv_options) = ui5_get_format_options( type_kind      = type_kind
                                               decimals       = decimals
                                               check_currency = lv_currency
                                               check_unit     = lv_unit ).

    IF lv_currency = abap_true.
      result = |\{parts: [\{path: '{ path }'\}, \{path: '{ currency_path }'\}], type: '{ lv_type }', formatOptions: { lv_options }\}|.
    ELSEIF lv_unit = abap_true.
      result = |\{parts: [\{path: '{ path }'\}, \{path: '{ unit_path }'\}], type: '{ lv_type }', formatOptions: { lv_options }\}|.
    ELSE.
      result = |\{path: '{ path }', type: '{ lv_type }', formatOptions: { lv_options }\}|.
    ENDIF.

  ENDMETHOD.

  METHOD ui5_binding_typed.

    DATA(lo_descr) = cl_abap_typedescr=>describe_by_data( val ).
    " a TIMESTAMP / TIMESTAMPL is a packed number here and an ISO text in
    " the model - a FloatType would refuse to parse it
    IF lo_descr->kind <> cl_abap_typedescr=>kind_elem
        OR lo_descr->absolute_name = `\TYPE=TIMESTAMP`
        OR lo_descr->absolute_name = `\TYPE=TIMESTAMPL`.
      result = |\{{ path }\}|.
      RETURN.
    ENDIF.

    DATA(lo_elem) = CAST cl_abap_elemdescr( lo_descr ).
    result = ui5_binding_by_kind( path          = path
                                  type_kind     = lo_descr->type_kind
                                  decimals      = lo_elem->decimals
                                  currency_path = currency_path
                                  unit_path     = unit_path ).

  ENDMETHOD.

  METHOD ui5_binding_typed_comp.

    DATA lv_currency TYPE string.
    DATA lv_unit     TYPE string.
    FIELD-SYMBOLS <val> TYPE any.

    DATA(lv_comp) = to_upper( condense( comp ) ).
    ASSIGN COMPONENT lv_comp OF STRUCTURE struc TO <val>.
    IF sy-subrc <> 0.
      result = |\{{ lv_comp }\}|.
      RETURN.
    ENDIF.

    DATA(ls_ref) = rtti_get_ref_field( struc = struc
                                       comp  = lv_comp ).
    IF ls_ref-currency = abap_true.
      lv_currency = ls_ref-name.
    ELSE.
      lv_unit = ls_ref-name.
    ENDIF.

    result = ui5_binding_typed( path          = lv_comp
                                val           = <val>
                                currency_path = lv_currency
                                unit_path     = lv_unit ).

  ENDMETHOD.

  METHOD rtti_get_ref_field.

    DATA lr_fields TYPE REF TO data.
    DATA lo_type   TYPE REF TO cl_abap_datadescr.
    DATA lv_ref    TYPE string.
    FIELD-SYMBOLS <fields>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <field>    TYPE any.
    FIELD-SYMBOLS <name>     TYPE any.
    FIELD-SYMBOLS <reffield> TYPE any.
    FIELD-SYMBOLS <datatype> TYPE any.
    FIELD-SYMBOLS <ref>      TYPE any.

    DATA(lv_comp) = to_upper( condense( comp ) ).

    TRY.
        DATA(lo_descr) = cl_abap_typedescr=>describe_by_data( struc ).
        IF lo_descr->kind <> cl_abap_typedescr=>kind_struct OR lo_descr->is_ddic_type( ) = abap_false.
          RETURN.
        ENDIF.
        DATA(lo_struct) = CAST cl_abap_structdescr( lo_descr ).

        " DDFIELDS is not released on ABAP Cloud - there the lookup raises
        " and the field has no reference field
        lo_type ?= cl_abap_typedescr=>describe_by_name( `DDFIELDS` ).
        CREATE DATA lr_fields TYPE HANDLE lo_type.
        ASSIGN lr_fields->* TO <fields>.

        CALL METHOD lo_struct->(`GET_DDIC_FIELD_LIST`)
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
          UNASSIGN: <name>, <reffield>, <datatype>.
          ASSIGN COMPONENT `FIELDNAME` OF STRUCTURE <field> TO <name>.
          IF <name> IS NOT ASSIGNED.
            RETURN.
          ENDIF.
          IF to_upper( condense( CONV string( <name> ) ) ) <> lv_comp.
            CONTINUE.
          ENDIF.

          ASSIGN COMPONENT `REFFIELD` OF STRUCTURE <field> TO <reffield>.
          ASSIGN COMPONENT `DATATYPE` OF STRUCTURE <field> TO <datatype>.
          IF <reffield> IS NOT ASSIGNED OR <datatype> IS NOT ASSIGNED.
            RETURN.
          ENDIF.
          IF <datatype> <> `CURR` AND <datatype> <> `QUAN`.
            RETURN.
          ENDIF.
          lv_ref = to_upper( condense( CONV string( <reffield> ) ) ).
          IF lv_ref IS INITIAL.
            RETURN.
          ENDIF.
          " the DDIC may name a field of another table (T001-WAERS) - only
          " a field of the same row can be bound beside the amount
          ASSIGN COMPONENT lv_ref OF STRUCTURE struc TO <ref>.
          IF sy-subrc <> 0.
            RETURN.
          ENDIF.

          result-name     = lv_ref.
          result-currency = xsdbool( <datatype> = `CURR` ).
          RETURN.
        ENDLOOP.

      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.


  METHOD class_constructor.

    cv_char_util_newline          = cl_abap_char_utilities=>newline.
    cv_char_util_cr_lf            = cl_abap_char_utilities=>cr_lf.
    cv_char_util_horizontal_tab   = cl_abap_char_utilities=>horizontal_tab.
    cv_typedescr_typekind_table   = cl_abap_typedescr=>typekind_table.
    cv_typedescr_typekind_dref    = cl_abap_typedescr=>typekind_dref.
    cv_typedescr_typekind_oref    = cl_abap_typedescr=>typekind_oref.
    cv_typedescr_typekind_struct1 = cl_abap_typedescr=>typekind_struct1.
    cv_typedescr_typekind_struct2 = cl_abap_typedescr=>typekind_struct2.
    cv_typedescr_typekind_date    = cl_abap_typedescr=>typekind_date.
    cv_typedescr_typekind_time    = cl_abap_typedescr=>typekind_time.
    cv_typedescr_typekind_char    = cl_abap_typedescr=>typekind_char.
    cv_typedescr_typekind_num     = cl_abap_typedescr=>typekind_num.
    cv_typedescr_typekind_string  = cl_abap_typedescr=>typekind_string.
    cv_typedescr_typekind_hex     = cl_abap_typedescr=>typekind_hex.
    cv_typedescr_typekind_xstring = cl_abap_typedescr=>typekind_xstring.
    cv_typedescr_kind_elem        = cl_abap_typedescr=>kind_elem.

  ENDMETHOD.

  METHOD zip_pack.

    DATA lo_zip TYPE REF TO object.

    TRY.

        CREATE OBJECT lo_zip TYPE ('CL_ABAP_ZIP').
        LOOP AT files INTO DATA(ls_file).
          CALL METHOD lo_zip->('ADD')
            EXPORTING
              name    = ls_file-name
              content = ls_file-content.
        ENDLOOP.
        CALL METHOD lo_zip->('SAVE')
          RECEIVING
            zip = result.

      CATCH cx_root INTO DATA(x).
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val      = `ZIP_PACK_ERROR - the ZIP archive cannot be written`
            previous = x.
    ENDTRY.

  ENDMETHOD.

  METHOD zip_unpack.

    CONSTANTS lc_signature TYPE x LENGTH 2 VALUE '504B'.
    DATA lo_zip    TYPE REF TO object.
    DATA lv_name   TYPE string.
    DATA lv_error  TYPE string.
    DATA ls_result LIKE LINE OF result.

    FIELD-SYMBOLS <files> TYPE ANY TABLE.
    FIELD-SYMBOLS <file>  TYPE any.
    FIELD-SYMBOLS <name>  TYPE any.

    " every ZIP archive starts with PK. Checked here, for the same answer
    " on every runtime: what the ZIP class does with other bytes differs,
    " and the transpiled one takes them without a word
    IF xstrlen( val ) < 4 OR val(2) <> lc_signature.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = `ZIP_PARSE_ERROR - the data is no ZIP archive`.
    ENDIF.

    TRY.

        CREATE OBJECT lo_zip TYPE ('CL_ABAP_ZIP').
        " LOAD and GET report a broken archive with a classic exception -
        " not taken here, it ends the program with a dump, and a file a
        " user uploads is broken often enough (cut off, or damaged)
        CALL METHOD lo_zip->('LOAD')
          EXPORTING
            zip             = val
          EXCEPTIONS
            zip_parse_error = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          lv_error = `ZIP_PARSE_ERROR - the data is no ZIP archive`.
        ELSE.
          ASSIGN lo_zip->('FILES') TO <files>.
          LOOP AT <files> ASSIGNING <file>.
            ASSIGN COMPONENT `NAME` OF STRUCTURE <file> TO <name>.
            lv_name = <name>.

            ls_result = VALUE #( name = lv_name ).
            CALL METHOD lo_zip->('GET')
              EXPORTING
                name                    = lv_name
              IMPORTING
                content                 = ls_result-content
              EXCEPTIONS
                zip_index_error         = 1
                zip_decompression_error = 2
                OTHERS                  = 3.
            IF sy-subrc <> 0.
              lv_error = |ZIP_PARSE_ERROR - the file { lv_name } of the archive cannot be unpacked|.
              EXIT.
            ENDIF.
            INSERT ls_result INTO TABLE result.
          ENDLOOP.
        ENDIF.

      CATCH cx_root INTO DATA(x).
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val      = `ZIP_PARSE_ERROR - the ZIP archive cannot be read`
            previous = x.
    ENDTRY.

    " raised behind the TRY: in it, the handler above would wrap it again
    IF lv_error IS NOT INITIAL.
      CLEAR result.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = lv_error.
    ENDIF.

  ENDMETHOD.

  METHOD xml_reader_create.

    TRY.
        " no option set: as it comes, the reader reports a text of blanks
        " only where it is the whole content of an element and leaves out
        " the indentation between two elements - what a caller wants
        result = cl_sxml_string_reader=>create( val ).
      CATCH cx_root INTO DATA(x).
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val      = `XML_READER_ERROR - the document cannot be read`
            previous = x.
    ENDTRY.

  ENDMETHOD.

  METHOD xml_reader_next.

    DATA lo_reader TYPE REF TO if_sxml_reader.

    CLEAR kind.
    CLEAR name.
    CLEAR value.
    CLEAR t_attribute.

    TRY.
        lo_reader ?= reader.
        lo_reader->next_node( ).

        CASE lo_reader->node_type.
          WHEN if_sxml_node=>co_nt_element_open.
            kind = cs_xml_node-open.
            name = lo_reader->name.
            IF t_attribute IS SUPPLIED.
              " next_attribute( ) walks the attributes of the element the
              " reader stands on and leaves the attribute kind behind the
              " last one - the way that is there since 7.02
              DO.
                lo_reader->next_attribute( ).
                IF lo_reader->node_type <> if_sxml_node=>co_nt_attribute.
                  EXIT.
                ENDIF.
                INSERT VALUE #( name  = lo_reader->name
                                value = lo_reader->value ) INTO TABLE t_attribute.
              ENDDO.
            ENDIF.
          WHEN if_sxml_node=>co_nt_element_close.
            kind = cs_xml_node-close.
            name = lo_reader->name.
          WHEN if_sxml_node=>co_nt_value.
            kind = cs_xml_node-value.
            value = lo_reader->value.
          WHEN OTHERS.
            " co_nt_final, and whatever a later release may add
            kind = cs_xml_node-end.
        ENDCASE.

      CATCH cx_root INTO DATA(x).
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val      = `XML_READER_ERROR - the document is not well-formed XML`
            previous = x.
    ENDTRY.

  ENDMETHOD.

  METHOD c_ends_with.

    DATA(lv_val) = CONV string( val ).
    DATA(lv_suffix) = CONV string( suffix ).
    DATA(lv_len_suffix) = strlen( lv_suffix ).
    DATA(lv_len_val) = strlen( lv_val ).

    IF lv_len_val < lv_len_suffix.
      result = abap_false.
      RETURN.
    ENDIF.

    DATA(lv_off) = lv_len_val - lv_len_suffix.
    result = xsdbool( lv_val+lv_off(lv_len_suffix) = lv_suffix ).

  ENDMETHOD.

  METHOD conv_string_to_number.

    DATA(lv_val) = c_trim( CONV string( val ) ).

    " Which separator is the decimal one:
    " - both a dot and a comma occur: the one that occurs LAST
    "   (`1.234,56` and `1,234.56` are both 1234.56)
    " - only one kind, more than once: thousands separators, no decimals
    "   (`1.234.567`, `1,000,000`)
    " - only one kind, once: the decimal separator (`3,14`, `3.14`). So
    "   `1,000` is 1 (European convention) - a single separator cannot be
    "   told apart from a thousands separator, the decimal reading wins
    " Every other separator is a thousands separator and is skipped.
    DATA lv_dot_count   TYPE i.
    DATA lv_comma_count TYPE i.
    DATA lv_decimal     TYPE string.
    DATA(lv_i) = 0.
    DATA(lv_len) = strlen( lv_val ).
    DATA(lv_last) = lv_len - 1.
    WHILE lv_i < lv_len.
      CASE lv_val+lv_i(1).
        WHEN `.`.
          lv_dot_count = lv_dot_count + 1.
          lv_decimal = `.`.
        WHEN `,`.
          lv_comma_count = lv_comma_count + 1.
          lv_decimal = `,`.
      ENDCASE.
      lv_i = lv_i + 1.
    ENDWHILE.
    " lv_decimal holds the last separator - right when both kinds occur
    IF ( lv_dot_count = 0 OR lv_comma_count = 0 ) AND ( lv_dot_count > 1 OR lv_comma_count > 1 ).
      CLEAR lv_decimal.
    ENDIF.

    " Normalize: keep only digits, minus, and the decimal separator as `.`
    DATA(lv_clean) = ``.
    lv_i = 0.
    WHILE lv_i < lv_len.
      DATA(lv_c) = lv_val+lv_i(1).
      IF lv_c >= `0` AND lv_c <= `9`.
        lv_clean = lv_clean && lv_c.
      ELSEIF lv_c = `-` AND lv_i = 0.
        lv_clean = lv_clean && lv_c.
      ELSEIF lv_c = `-` AND lv_i = lv_last AND lv_val(1) <> `-`.
        " the sign behind the number, as a MOVE and WRITE put it
        lv_clean = `-` && lv_clean.
      ELSEIF lv_c = lv_decimal.
        lv_clean = lv_clean && `.`.
      ENDIF.
      " any other separator is a thousands separator - skipped
      lv_i = lv_i + 1.
    ENDWHILE.

    " Validate the normalized value explicitly: it needs at least one
    " digit and at most one decimal point (`1,234.5.6` keeps two). Return 0
    " for invalid input - the JS transpiler converts such strings leniently
    " instead of raising
    DATA(lv_point_count) = count( val = lv_clean
                                  sub = `.` ).
    IF lv_point_count > 1 OR lv_clean NA `0123456789`.
      result = 0.
      RETURN.
    ENDIF.

    TRY.
        result = lv_clean.
      CATCH cx_root.
        result = 0.
    ENDTRY.

  ENDMETHOD.

  METHOD boolean_check_by_name.

    CASE val.
      WHEN `ABAP_BOOL`
          OR `XSDBOOLEAN`
          OR `FLAG`
          OR `XFLAG`
          OR `XFELD`
          OR `ABAP_BOOLEAN`
          OR `WDY_BOOLEAN`
          OR `BOOLE_D`
          OR `OS_BOOLEAN`.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD rtti_check_typekind_number.

    CASE val.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34
          OR `8`.
        result = abap_true.
    ENDCASE.

  ENDMETHOD.

  METHOD rtti_get_type_name.
    TRY.

        DATA(lo_descr) = cl_abap_elemdescr=>describe_by_data( val ).
        DATA(lo_ele) = CAST cl_abap_elemdescr( lo_descr ).
        result = lo_ele->get_relative_name( ).

      CATCH cx_root ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD c_trim_upper.

    result = to_upper( c_trim( val ) ).

  ENDMETHOD.

  METHOD rtti_get_t_attri_by_any.

    DATA lo_struct TYPE REF TO cl_abap_structdescr.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( val ).
    IF lo_type->kind = cl_abap_typedescr=>kind_table.
      lo_type = CAST cl_abap_tabledescr( lo_type )->get_table_line_type( ).
    ENDIF.
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
      RETURN.
    ENDIF.
    lo_struct ?= lo_type.
    result = rtti_expand_components( lo_struct->get_components( ) ).

  ENDMETHOD.

  METHOD rtti_expand_components.

    DATA lo_include TYPE REF TO cl_abap_structdescr.

    " bounded, so that an include chain that reaches itself ends in an
    " error and not in a stack overflow
    IF depth > 16.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = `RTTI_INCLUDE_RECURSION - include expansion exceeded 16 levels`.
    ENDIF.

    LOOP AT val REFERENCE INTO DATA(lr_comp).
      IF lr_comp->as_include = abap_false.
        INSERT lr_comp->* INTO TABLE result.
        CONTINUE.
      ENDIF.
      " INCLUDE ... RENAMING WITH SUFFIX: the fields of the structure are
      " named <component><suffix>, at every level
      lo_include ?= lr_comp->type.
      DATA(lt_include) = rtti_expand_components( val   = lo_include->get_components( )
                                                 depth = depth + 1 ).
      IF lr_comp->suffix IS NOT INITIAL.
        LOOP AT lt_include REFERENCE INTO DATA(lr_include).
          lr_include->name = lr_include->name && lr_comp->suffix.
        ENDLOOP.
      ENDIF.
      INSERT LINES OF lt_include INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD rtti_create_tab_by_names.

    DATA lt_comp TYPE abap_component_tab.

    LOOP AT val INTO DATA(lv_name).
      " a string per column - a fixed length would cut every longer value
      INSERT VALUE #( name = lv_name
                      type = cl_abap_elemdescr=>get_string( ) ) INTO TABLE lt_comp.
    ENDLOOP.
    DATA(lo_struct) = cl_abap_structdescr=>create( lt_comp ).
    DATA(lo_table) = cl_abap_tabledescr=>create( p_line_type  = lo_struct
                                                 p_table_kind = cl_abap_tabledescr=>tablekind_std ).
    CREATE DATA result TYPE HANDLE lo_table.

  ENDMETHOD.

  METHOD time_get_timestamp.
    GET TIME STAMP FIELD result.
  ENDMETHOD.

  METHOD time_stampl_to_tz.

    DATA lv_tz TYPE c LENGTH 6.

    CLEAR date.
    CLEAR time.
    lv_tz = time_check_zone( tz ).

    " 8: the zone is not in TTZZ, 12: the time stamp is no valid one
    CONVERT TIME STAMP val TIME ZONE lv_tz INTO DATE date TIME time.
    IF sy-subrc >= 8.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = |TIME_STAMPL_TO_TZ: { val } cannot be converted to time zone { lv_tz } (sy-subrc { sy-subrc })|.
    ENDIF.

  ENDMETHOD.

  METHOD time_check_zone.

    result = c_trim( tz ).
    IF strlen( result ) > 6.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = |{ result } is no SAP time zone key (TTZZ, at most six characters)|.
    ENDIF.

  ENDMETHOD.

  METHOD c_get_codepoints.

    DATA lv_x     TYPE xstring.
    DATA lv_byte  TYPE i.
    DATA lv_cp    TYPE i.
    DATA lv_more  TYPE i.
    DATA lv_off   TYPE i.
    DATA lv_high  TYPE i.
    DATA lv_lines TYPE i.

    " the UTF-8 bytes, decoded by hand: the one conversion every release
    " and the transpiler have, and no character-code API is needed
    lv_x = conv_get_xstring_by_string( CONV string( val ) ).
    DATA(lv_len) = xstrlen( lv_x ).

    WHILE lv_off < lv_len.

      lv_byte = lv_x+lv_off(1).
      lv_off = lv_off + 1.
      IF lv_byte < 128.
        lv_cp = lv_byte.
        lv_more = 0.
      ELSEIF lv_byte < 224.
        lv_cp = lv_byte MOD 32.
        lv_more = 1.
      ELSEIF lv_byte < 240.
        lv_cp = lv_byte MOD 16.
        lv_more = 2.
      ELSE.
        lv_cp = lv_byte MOD 8.
        lv_more = 3.
      ENDIF.

      DO lv_more TIMES.
        IF lv_off >= lv_len.
          EXIT.
        ENDIF.
        lv_byte = lv_x+lv_off(1).
        lv_off = lv_off + 1.
        lv_cp = lv_cp * 64 + ( lv_byte MOD 64 ).
      ENDDO.

      " a converter that writes a surrogate pair as two three-byte
      " sequences (CESU-8): the low half joins the high half before it
      IF lv_cp >= 56320 AND lv_cp <= 57343 AND lv_high > 0.
        lv_cp = 65536 + ( lv_high - 55296 ) * 1024 + ( lv_cp - 56320 ).
        lv_lines = lines( result ).
        DELETE result INDEX lv_lines.
      ENDIF.
      IF lv_cp >= 55296 AND lv_cp <= 56319.
        lv_high = lv_cp.
      ELSE.
        lv_high = 0.
      ENDIF.

      INSERT lv_cp INTO TABLE result.

    ENDWHILE.

  ENDMETHOD.

  METHOD conv_exit.

    DATA lv_message TYPE string.
    DATA lx_error   TYPE REF TO cx_root.

    DATA(conex) = COND string( WHEN output = abap_true
                               THEN |CONVERSION_EXIT_{ convexit }_OUTPUT|
                               ELSE |CONVERSION_EXIT_{ convexit }_INPUT| ).

    TRY.
        " CUNIT reads the unit in a language; the others take no such parameter
        IF from IS SUPPLIED AND convexit = `CUNIT`.
          CALL FUNCTION conex
            EXPORTING
              input    = from
              language = sy-langu
            IMPORTING
              output   = value
            EXCEPTIONS
              " a plain MESSAGE TYPE E of the exit ends the request without it
              error_message = 98
              OTHERS        = 99.
        ELSEIF from IS SUPPLIED.
          CALL FUNCTION conex
            EXPORTING
              input  = from
            IMPORTING
              output = value
            EXCEPTIONS
              error_message = 98
              OTHERS        = 99.
        ELSEIF convexit = `CUNIT`.
          CALL FUNCTION conex
            EXPORTING
              input    = value
              language = sy-langu
            IMPORTING
              output   = value
            EXCEPTIONS
              error_message = 98
              OTHERS        = 99.
        ELSE.
          CALL FUNCTION conex
            EXPORTING
              input  = value
            IMPORTING
              output = value
            EXCEPTIONS
              error_message = 98
              OTHERS        = 99.
        ENDIF.

      CATCH cx_root INTO lx_error.
        " no such exit, or a parameter it does not accept
        RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
          EXPORTING
            val      = lx_error->get_text( )
            previous = lx_error.
    ENDTRY.

    IF sy-subrc <> 0.
      " the exit raised its exception with MESSAGE ... RAISING, or sent a
      " plain MESSAGE TYPE E (error_message) - both leave it in sy-msg*
      IF sy-msgid IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE `E` NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_message.
      ELSE.
        lv_message = |{ conex } failed|.
      ENDIF.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = lv_message.
    ENDIF.

  ENDMETHOD.

  METHOD rtti_get_t_ddic_fixed_values.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = rollname
                                         RECEIVING  p_descr_ref    = DATA(lo_descr)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc = 0.
      result = rtti_get_fixed_values( lo_descr ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
