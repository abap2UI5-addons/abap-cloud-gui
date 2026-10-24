"! The stand-in of cl_demo_output - the output of a classic report or demo
"! program into the list of the report it runs in (z2ui5_if_cgui_gui~
"! list( )): an elementary value as a line, a structure as a line of columns,
"! a table as columns under the names of its components, a section as a
"! heading. The static methods write into one output of the run, new( )
"! creates another one (z2ui5_if_cgui_demo_output) whose calls chain.
"! display( ) shows nothing at once: the list of the run shows when the run
"! ends, with everything every output wrote into it
CLASS z2ui5_cl_cgui_demo_output DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_demo_output.

    CLASS-METHODS new
      RETURNING
        VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

    CLASS-METHODS write
      IMPORTING
        data TYPE any
        name TYPE clike OPTIONAL.

    CLASS-METHODS write_data
      IMPORTING
        value TYPE any
        name  TYPE clike OPTIONAL.

    CLASS-METHODS write_text
      IMPORTING
        text TYPE clike.

    CLASS-METHODS write_html
      IMPORTING
        html TYPE csequence.

    CLASS-METHODS write_json
      IMPORTING
        json TYPE simple.

    CLASS-METHODS begin_section
      IMPORTING
        title TYPE clike OPTIONAL.

    CLASS-METHODS next_section
      IMPORTING
        title TYPE clike OPTIONAL.

    CLASS-METHODS end_section.

    CLASS-METHODS line.

    CLASS-METHODS display
      IMPORTING
        data TYPE any   OPTIONAL
        name TYPE clike OPTIONAL
          PREFERRED PARAMETER data.

    CLASS-METHODS display_data
      IMPORTING
        value TYPE any
        name  TYPE clike OPTIONAL.

    CLASS-METHODS display_text
      IMPORTING
        text TYPE clike.

    CLASS-METHODS display_html
      IMPORTING
        html TYPE csequence.

    CLASS-METHODS display_json
      IMPORTING
        json TYPE simple.

    CLASS-METHODS clear.

    CLASS-METHODS get
      IMPORTING
        data          TYPE any   OPTIONAL
        name          TYPE clike OPTIONAL
          PREFERRED PARAMETER data
      RETURNING
        VALUE(output) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    " the widest a column of a table gets - the rest of a value is cut
    CONSTANTS cv_max_width TYPE i VALUE 40.

    TYPES ty_t_width TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    CLASS-DATA go_default TYPE REF TO z2ui5_cl_cgui_demo_output.

    DATA mv_level TYPE i.
    " the line of the list the output started at - 0 before its first
    " write and after display( ), get( ) and clear( )
    DATA mv_from TYPE i.

    CLASS-METHODS default
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_if_cgui_demo_output.

    METHODS list
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_list.

    METHODS heading
      IMPORTING
        text TYPE clike.

    METHODS write_table
      IMPORTING
        data TYPE ANY TABLE.

    METHODS write_header
      IMPORTING
        columns TYPE string_table
        widths  TYPE ty_t_width.

    METHODS write_columns
      IMPORTING
        line   TYPE any
        widths TYPE ty_t_width.

    "! the text of a value as a column shows it - a date and a time by
    "! their width in the list
    CLASS-METHODS text_of
      IMPORTING
        value         TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! the text of html - without its tags
    CLASS-METHODS text_of_html
      IMPORTING
        html          TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

    "! the names of the columns of a line: its components, or the line itself
    CLASS-METHODS columns_of
      IMPORTING
        line          TYPE any
      RETURNING
        VALUE(result) TYPE string_table.

ENDCLASS.


CLASS z2ui5_cl_cgui_demo_output IMPLEMENTATION.

  METHOD new.

    output = NEW z2ui5_cl_cgui_demo_output( ).

  ENDMETHOD.

  METHOD default.

    IF go_default IS NOT BOUND.
      go_default = NEW #( ).
    ENDIF.
    result = go_default.

  ENDMETHOD.

  METHOD write.

    default( )->write( data = data
                       name = name ).

  ENDMETHOD.

  METHOD write_data.

    default( )->write_data( value = value
                            name  = name ).

  ENDMETHOD.

  METHOD write_text.

    default( )->write_text( text ).

  ENDMETHOD.

  METHOD write_html.

    default( )->write_html( html ).

  ENDMETHOD.

  METHOD write_json.

    default( )->write_json( json ).

  ENDMETHOD.

  METHOD begin_section.

    default( )->begin_section( title ).

  ENDMETHOD.

  METHOD next_section.

    default( )->next_section( title ).

  ENDMETHOD.

  METHOD end_section.

    default( )->end_section( ).

  ENDMETHOD.

  METHOD line.

    default( )->line( ).

  ENDMETHOD.

  METHOD display.

    IF data IS SUPPLIED.
      default( )->display( data = data
                           name = name ).
    ELSE.
      default( )->display( ).
    ENDIF.

  ENDMETHOD.

  METHOD display_data.

    default( )->display( data = value
                         name = name ).

  ENDMETHOD.

  METHOD display_text.

    default( )->write_text( text ).

  ENDMETHOD.

  METHOD display_html.

    default( )->write_html( html ).

  ENDMETHOD.

  METHOD display_json.

    default( )->write_json( json ).

  ENDMETHOD.

  METHOD clear.

    default( )->clear( ).

  ENDMETHOD.

  METHOD get.

    IF data IS SUPPLIED.
      output = default( )->get( data = data
                                name = name ).
    ELSE.
      output = default( )->get( ).
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~write.

    output = me.
    IF name IS NOT INITIAL.
      list( )->write( val         = name
                      intensified = abap_true ).
      list( )->new_line( ).
    ENDIF.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( data ).
    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_table.
        write_table( data ).
      WHEN cl_abap_typedescr=>kind_struct.
        DATA(lt_width) = VALUE ty_t_width( ).
        LOOP AT columns_of( data ) INTO DATA(lv_column).
          ASSIGN COMPONENT sy-tabix OF STRUCTURE data TO FIELD-SYMBOL(<value>).
          APPEND nmin( val1 = cv_max_width
                       val2 = nmax( val1 = strlen( lv_column )
                                    val2 = strlen( text_of( <value> ) ) ) ) TO lt_width.
        ENDLOOP.
        write_header( columns = columns_of( data )
                      widths  = lt_width ).
        write_columns( line   = data
                       widths = lt_width ).
      WHEN cl_abap_typedescr=>kind_elem.
        list( )->write( data ).
        list( )->new_line( ).
      WHEN OTHERS.
        " a reference - what it points to is not written
        list( )->write( lo_type->absolute_name ).
        list( )->new_line( ).
    ENDCASE.
    list( )->skip( ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~write_data.

    output = z2ui5_if_cgui_demo_output~write( data = value
                                              name = name ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~write_text.

    output = me.
    SPLIT text AT cl_abap_char_utilities=>newline INTO TABLE DATA(lt_line).
    LOOP AT lt_line INTO DATA(lv_line).
      list( )->write( lv_line ).
      list( )->new_line( ).
    ENDLOOP.
    list( )->skip( ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~write_html.

    output = z2ui5_if_cgui_demo_output~write_text( text_of_html( html ) ).

  ENDMETHOD.

  METHOD text_of_html.

    " the text between the tags - a line ends at a break, the end of a
    " paragraph, a heading, a row or an item
    DATA(lv_html) = CONV string( html ).
    DATA(lv_at) = 0.
    WHILE lv_at < strlen( lv_html ).
      DATA(lv_open) = find( val = lv_html sub = `<` off = lv_at ).
      IF lv_open < 0.
        result = result && substring( val = lv_html off = lv_at ).
        EXIT.
      ENDIF.
      result = result && substring( val = lv_html off = lv_at len = lv_open - lv_at ).
      DATA(lv_close) = find( val = lv_html sub = `>` off = lv_open ).
      IF lv_close < 0.
        EXIT.
      ENDIF.
      DATA(lv_tag) = to_lower( substring( val = lv_html off = lv_open + 1 len = lv_close - lv_open - 1 ) ).
      SPLIT lv_tag AT ` ` INTO lv_tag DATA(lv_rest) ##NEEDED.
      CASE lv_tag.
        WHEN `br` OR `br/` OR `/p` OR `/div` OR `/tr` OR `/li` OR `/h1` OR `/h2` OR `/h3` OR `/h4` OR `/h5` OR `/h6`.
          result = result && cl_abap_char_utilities=>newline.
        WHEN OTHERS.
          result = result && ` `.
      ENDCASE.
      lv_at = lv_close + 1.
    ENDWHILE.
    result = replace( val  = result
                      sub  = `&nbsp;`
                      with = ` `
                      occ  = 0 ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~write_json.

    output = z2ui5_if_cgui_demo_output~write_text( |{ json }| ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~begin_section.

    output = me.
    mv_level = mv_level + 1.
    IF title IS NOT INITIAL.
      heading( title ).
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~next_section.

    output = me.
    IF mv_level = 0.
      mv_level = 1.
    ENDIF.
    IF title IS NOT INITIAL.
      heading( title ).
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~end_section.

    output = me.
    IF mv_level > 0.
      mv_level = mv_level - 1.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~line.

    output = me.
    list( )->uline( ).

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~display.

    IF data IS SUPPLIED.
      z2ui5_if_cgui_demo_output~write( data = data
                                       name = name ).
    ENDIF.
    mv_from = 0.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~get.

    IF data IS SUPPLIED.
      z2ui5_if_cgui_demo_output~write( data = data
                                       name = name ).
    ENDIF.
    DATA(lt_line) = COND #( WHEN mv_from > 0 THEN list( )->cut( mv_from ) ).
    mv_from = 0.
    output = |<html><body><pre>{ escape( val    = concat_lines_of( table = lt_line
                                                                   sep   = |\n| )
                                         format = cl_abap_format=>e_html_text ) }</pre></body></html>|.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_demo_output~clear.

    output = me.
    IF mv_from > 0.
      list( )->cut( mv_from ).
    ENDIF.
    mv_from = 0.

  ENDMETHOD.

  METHOD list.

    " the report of the roundtrip - the one the SAP GUI stand-ins know
    DATA(lo_report) = z2ui5_cl_cgui_gui=>get_report( ).
    IF lo_report IS NOT BOUND.
      RAISE EXCEPTION TYPE z2ui5_cx_cgui_error
        EXPORTING
          val = `cl_demo_output outside of a report`.
    ENDIF.
    result = lo_report->list( ).
    " where the output starts - get( ) and clear( ) take it from there on
    IF mv_from = 0.
      mv_from = result->current_line( ).
    ENDIF.

  ENDMETHOD.

  METHOD heading.

    " a section of the first level is a heading of the list, deeper ones
    " are its subheadings
    IF mv_level <= 1.
      list( )->write( val         = text
                      intensified = abap_true
                      color       = z2ui5_cl_cgui_list=>cs_color-key ).
    ELSE.
      list( )->write( val         = text
                      intensified = abap_true ).
    ENDIF.
    list( )->new_line( ).

  ENDMETHOD.

  METHOD write_table.

    FIELD-SYMBOLS <line> TYPE any.

    DATA(lo_table) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( data ) ).
    DATA lr_line TYPE REF TO data.
    DATA(lo_line) = lo_table->get_table_line_type( ).
    CREATE DATA lr_line TYPE HANDLE lo_line.
    ASSIGN lr_line->* TO <line>.
    DATA(lt_column) = columns_of( <line> ).

    " the width of a column: its name, its widest value
    DATA(lt_width) = VALUE ty_t_width( ).
    LOOP AT lt_column INTO DATA(lv_column).
      APPEND strlen( lv_column ) TO lt_width.
    ENDLOOP.
    LOOP AT data ASSIGNING <line>.
      LOOP AT lt_width ASSIGNING FIELD-SYMBOL(<width>).
        DATA(lv_index) = sy-tabix.
        IF lines( lt_column ) = 1 AND lt_column[ 1 ] = `TABLE_LINE`.
          ASSIGN <line> TO FIELD-SYMBOL(<value>).
        ELSE.
          ASSIGN COMPONENT lv_index OF STRUCTURE <line> TO <value>.
        ENDIF.
        <width> = nmin( val1 = cv_max_width
                        val2 = nmax( val1 = <width>
                                     val2 = strlen( text_of( <value> ) ) ) ).
      ENDLOOP.
    ENDLOOP.

    write_header( columns = lt_column
                  widths  = lt_width ).
    LOOP AT data ASSIGNING <line>.
      write_columns( line   = <line>
                     widths = lt_width ).
    ENDLOOP.

  ENDMETHOD.

  METHOD write_header.

    " the names over the columns - an index of its own, the WRITEs of the
    " list change sy-tabix
    DATA(lv_pos) = 1.
    DATA(lv_index) = 0.
    LOOP AT columns INTO DATA(lv_column).
      lv_index = lv_index + 1.
      DATA(lv_width) = widths[ lv_index ].
      list( )->write( val         = lv_column
                      pos         = lv_pos
                      len         = lv_width
                      intensified = abap_true ).
      lv_pos = lv_pos + lv_width + 1.
    ENDLOOP.
    list( )->new_line( ).

  ENDMETHOD.

  METHOD write_columns.

    DATA(lv_pos) = 1.
    DATA(lv_index) = 0.
    LOOP AT widths INTO DATA(lv_width).
      lv_index = lv_index + 1.
      IF lines( widths ) = 1 AND cl_abap_typedescr=>describe_by_data( line )->kind = cl_abap_typedescr=>kind_elem.
        ASSIGN line TO FIELD-SYMBOL(<value>).
      ELSE.
        ASSIGN COMPONENT lv_index OF STRUCTURE line TO <value>.
      ENDIF.
      DATA(lo_kind) = cl_abap_typedescr=>describe_by_data( <value> ).
      IF lo_kind->kind = cl_abap_typedescr=>kind_elem.
        list( )->write( val = <value>
                        pos = lv_pos
                        len = lv_width ).
      ELSE.
        list( )->write( val = text_of( <value> )
                        pos = lv_pos
                        len = lv_width ).
      ENDIF.
      lv_pos = lv_pos + lv_width + 1.
    ENDLOOP.
    list( )->new_line( ).

  ENDMETHOD.

  METHOD text_of.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( value ).
    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_elem.
        CASE lo_type->type_kind.
          WHEN cl_abap_typedescr=>typekind_date.
            result = `0000000000`.
          WHEN cl_abap_typedescr=>typekind_time.
            result = `00000000`.
          WHEN OTHERS.
            result = condense( |{ value }| ).
        ENDCASE.
      WHEN cl_abap_typedescr=>kind_table.
        result = `[table]`.
      WHEN cl_abap_typedescr=>kind_struct.
        result = `[structure]`.
      WHEN OTHERS.
        result = `[reference]`.
    ENDCASE.

  ENDMETHOD.

  METHOD columns_of.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( line ).
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
      INSERT `TABLE_LINE` INTO TABLE result.
      RETURN.
    ENDIF.
    " flat - the components of an include are columns of their own
    LOOP AT CAST cl_abap_structdescr( lo_type )->components INTO DATA(ls_component).
      INSERT CONV string( ls_component-name ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
