"! A PDF of lines of text - the printout of a list on ABAP Cloud, which has no
"! spool. Courier, one of the fonts every PDF reader has, so nothing is
"! embedded; the page turns to landscape and the font shrinks for a wide
"! list, a page number at the foot of every page
CLASS z2ui5_cl_cgui_pdf DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    "! the lines as a PDF document - title: the title of the document
    CLASS-METHODS from_lines
      IMPORTING
        lines         TYPE string_table
        title         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE xstring.

    "! a text as a PDF string literal: ( ) and \ escaped, a character
    "! beyond ASCII in the WinAnsi encoding of the font, else a ?
    CLASS-METHODS literal
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.

    "! a number in tenths as a PDF number: 905 is 90.5
    CLASS-METHODS dec
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.

    "! the WinAnsi code of a character beyond ASCII - 0 when it has none
    CLASS-METHODS win_ansi
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE i.

ENDCLASS.


CLASS z2ui5_cl_cgui_pdf IMPLEMENTATION.

  METHOD from_lines.

    CONSTANTS lc_margin TYPE i VALUE 36.
    DATA lt_obj    TYPE string_table.
    DATA lt_kids   TYPE string_table.
    DATA lv_width  TYPE i.
    DATA lv_height TYPE i.
    DATA lv_fs10   TYPE i.

    " the longest line decides the page: A4 portrait at 9 points, else
    " landscape with the font as small as it has to be (4 points at least)
    DATA(lv_max) = 1.
    LOOP AT lines INTO DATA(lv_line).
      lv_max = nmax( val1 = lv_max val2 = strlen( lv_line ) ).
    ENDLOOP.
    " a character of Courier is 0.6 of its size wide
    IF 100 * ( 595 - 2 * lc_margin ) DIV ( 6 * lv_max ) >= 90.
      lv_width = 595.
      lv_height = 842.
      lv_fs10 = 90.
    ELSE.
      lv_width = 842.
      lv_height = 595.
      lv_fs10 = nmax( val1 = 40
                      val2 = nmin( val1 = 90 val2 = 100 * ( 842 - 2 * lc_margin ) DIV ( 6 * lv_max ) ) ).
    ENDIF.
    DATA(lv_lead10) = lv_fs10 * 12 DIV 10.
    " the lines of a page: the height without the margins and the foot
    DATA(lv_per_page) = nmax( val1 = 1
                              val2 = ( lv_height - 2 * lc_margin - 20 ) * 10 DIV lv_lead10 ).
    DATA(lv_pages) = nmax( val1 = 1
                           val2 = ( lines( lines ) + lv_per_page - 1 ) DIV lv_per_page ).

    " 1 the catalog, 2 the pages, 3 the font, 4 the info - then a page and
    " its content for every page
    INSERT `<< /Type /Catalog /Pages 2 0 R >>` INTO TABLE lt_obj.
    INSERT `` INTO TABLE lt_obj.
    INSERT `<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>` INTO TABLE lt_obj.
    INSERT |<< /Title ({ literal( title ) }) /Producer (abap-cloud-gui) >>| INTO TABLE lt_obj.

    DO lv_pages TIMES.
      DATA(lv_page) = sy-index.
      DATA(lv_content) = |BT /F1 { dec( lv_fs10 ) } Tf { dec( lv_lead10 ) } TL | &&
                         |{ lc_margin } { dec( ( lv_height - lc_margin ) * 10 - lv_fs10 ) } Td|.
      DATA(lv_from) = ( lv_page - 1 ) * lv_per_page + 1.
      LOOP AT lines INTO lv_line FROM lv_from TO lv_from + lv_per_page - 1.
        lv_content = |{ lv_content }\n({ literal( lv_line ) }) Tj T*|.
      ENDLOOP.
      lv_content = |{ lv_content } ET\nBT /F1 8 Tf { lv_width - lc_margin - 60 } { lc_margin - 12 } Td | &&
                   |({ lv_page } / { lv_pages }) Tj ET|.
      DATA(lv_no) = lines( lt_obj ) + 1.
      INSERT |<< /Type /Page /Parent 2 0 R /MediaBox [0 0 { lv_width } { lv_height }] | &&
             |/Resources << /Font << /F1 3 0 R >> >> /Contents { lv_no + 1 } 0 R >>| INTO TABLE lt_obj.
      INSERT |<< /Length { strlen( lv_content ) } >>\nstream\n{ lv_content }\nendstream| INTO TABLE lt_obj.
      INSERT |{ lv_no } 0 R| INTO TABLE lt_kids.
    ENDDO.
    lt_obj[ 2 ] = |<< /Type /Pages /Kids [{ concat_lines_of( table = lt_kids sep = ` ` ) }] /Count { lv_pages } >>|.

    " every byte is ASCII - the length of the text is its offset in bytes
    DATA(lv_pdf) = |%PDF-1.4\n|.
    DATA(lv_xref) = |xref\n0 { lines( lt_obj ) + 1 }\n0000000000 65535 f \n|.
    LOOP AT lt_obj INTO DATA(lv_obj).
      lv_xref = |{ lv_xref }{ strlen( lv_pdf ) WIDTH = 10 ALIGN = RIGHT PAD = `0` } 00000 n \n|.
      lv_pdf = |{ lv_pdf }{ sy-tabix } 0 obj\n{ lv_obj }\nendobj\n|.
    ENDLOOP.
    lv_pdf = |{ lv_pdf }{ lv_xref }trailer\n<< /Size { lines( lt_obj ) + 1 } /Root 1 0 R /Info 4 0 R >>\n| &&
             |startxref\n{ strlen( lv_pdf ) }\n%%EOF\n|.
    result = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( lv_pdf ).

  ENDMETHOD.

  METHOD literal.

    CONSTANTS lc_ascii TYPE string VALUE ` !"#$%&'*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~`.
    DATA(lv_text) = CONV string( val ).
    DATA(lv_len) = strlen( lv_text ).
    DATA(lv_off) = 0.

    WHILE lv_off < lv_len.
      DATA(lv_char) = substring( val = lv_text off = lv_off len = 1 ).
      lv_off = lv_off + 1.
      IF lv_char = `(` OR lv_char = `)` OR lv_char = `\`.
        result = |{ result }\\{ lv_char }|.
      ELSEIF lv_char = `` OR lv_char = cl_abap_char_utilities=>horizontal_tab.
        " a string keeps its blank, the tab of a list is one
        result = |{ result } |.
      ELSEIF lv_char CO lc_ascii OR lv_char = '`'.
        result = result && lv_char.
      ELSE.
        DATA(lv_code) = win_ansi( lv_char ).
        IF lv_code = 0.
          result = |{ result }?|.
        ELSE.
          result = |{ result }\\{ lv_code DIV 64 }{ ( lv_code DIV 8 ) MOD 8 }{ lv_code MOD 8 }|.
        ENDIF.
      ENDIF.
    ENDWHILE.

  ENDMETHOD.

  METHOD win_ansi.

    DATA lv_b1 TYPE x LENGTH 1.
    DATA lv_b2 TYPE x LENGTH 1.

    DATA(lv_utf8) = z2ui5_cl_cgui_context=>conv_get_xstring_by_string( val ).
    IF xstrlen( lv_utf8 ) = 3 AND lv_utf8 = 'E282AC'.
      " the euro sign
      result = 128.
      RETURN.
    ENDIF.
    IF xstrlen( lv_utf8 ) <> 2.
      RETURN.
    ENDIF.
    lv_b1 = lv_utf8(1).
    lv_b2 = lv_utf8+1(1).
    " U+00A0 to U+00FF: Latin-1, the same codes in WinAnsi
    DATA(lv_code) = ( CONV i( lv_b1 ) - 192 ) * 64 + CONV i( lv_b2 ) - 128.
    IF lv_code >= 160 AND lv_code <= 255.
      result = lv_code.
    ENDIF.

  ENDMETHOD.

  METHOD dec.

    result = |{ val DIV 10 }|.
    IF val MOD 10 <> 0.
      result = |{ result }.{ val MOD 10 }|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
