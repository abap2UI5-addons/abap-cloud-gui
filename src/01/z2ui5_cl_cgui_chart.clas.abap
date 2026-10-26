"! A bar chart as SVG - the chart of an ALV (OpenUI5 has no sap.viz):
"! one bar per category, the values summed per category, the largest
"! first; beyond the 20th the rest is one bar "Other". SVG of attributes
"! only - no script, no style - so the page's CSP lets it in
CLASS z2ui5_cl_cgui_chart DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_value TYPE p LENGTH 16 DECIMALS 2.
    TYPES:
      BEGIN OF ty_s_bar,
        label TYPE string,
        value TYPE ty_value,
      END OF ty_s_bar.
    TYPES ty_t_bar TYPE STANDARD TABLE OF ty_s_bar WITH EMPTY KEY.

    CONSTANTS cv_max_bars TYPE i VALUE 20.

    "! the bars of a table: category and value are columns of tab - the
    "! values summed per category, sorted, the rest as "Other"; without a
    "! value the rows of each category are counted
    CLASS-METHODS bars
      IMPORTING
        tab           TYPE STANDARD TABLE
        category      TYPE clike
        value         TYPE clike
        other         TYPE clike DEFAULT `Other`
      RETURNING
        VALUE(result) TYPE ty_t_bar.

    "! the bars as SVG, width points wide
    CLASS-METHODS svg
      IMPORTING
        bars          TYPE ty_t_bar
        width         TYPE i DEFAULT 640
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.

    CLASS-METHODS xml
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_chart IMPLEMENTATION.

  METHOD bars.

    FIELD-SYMBOLS <category> TYPE any.
    FIELD-SYMBOLS <value>    TYPE any.
    DATA lt_bar TYPE ty_t_bar.

    LOOP AT tab ASSIGNING FIELD-SYMBOL(<row>).
      ASSIGN COMPONENT category OF STRUCTURE <row> TO <category>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      DATA(lv_label) = condense( CONV string( <category> ) ).
      READ TABLE lt_bar ASSIGNING FIELD-SYMBOL(<bar>) WITH KEY label = lv_label.
      IF sy-subrc <> 0.
        INSERT VALUE #( label = lv_label ) INTO TABLE lt_bar ASSIGNING <bar>.
      ENDIF.
      IF value IS INITIAL.
        <bar>-value = <bar>-value + 1.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT value OF STRUCTURE <row> TO <value>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      TRY.
          <bar>-value = <bar>-value + <value>.
        CATCH cx_sy_conversion_error cx_sy_arithmetic_error ##NO_HANDLER.
      ENDTRY.
    ENDLOOP.

    SORT lt_bar BY value DESCENDING label ASCENDING.
    LOOP AT lt_bar INTO DATA(ls_bar).
      IF sy-tabix <= cv_max_bars.
        INSERT ls_bar INTO TABLE result.
        CONTINUE.
      ENDIF.
      IF lines( result ) = cv_max_bars.
        INSERT VALUE #( label = other ) INTO TABLE result.
      ENDIF.
      result[ lines( result ) ]-value = result[ lines( result ) ]-value + ls_bar-value.
    ENDLOOP.

  ENDMETHOD.

  METHOD svg.

    CONSTANTS lc_row   TYPE i VALUE 24.
    CONSTANTS lc_label TYPE i VALUE 160.
    CONSTANTS lc_text  TYPE i VALUE 90.

    DATA lv_max TYPE ty_value.

    LOOP AT bars INTO DATA(ls_bar).
      lv_max = nmax( val1 = lv_max val2 = abs( ls_bar-value ) ).
    ENDLOOP.
    DATA(lv_room) = nmax( val1 = 40 val2 = width - lc_label - lc_text ).
    DATA(lv_height) = nmax( val1 = 1 val2 = lines( bars ) ) * lc_row + 8.

    result = |<svg xmlns="http://www.w3.org/2000/svg" width="{ width }" height="{ lv_height }" | &&
             |viewBox="0 0 { width } { lv_height }" font-family="sans-serif" font-size="12">|.
    LOOP AT bars INTO ls_bar.
      DATA(lv_y) = ( sy-tabix - 1 ) * lc_row + 4.
      DATA(lv_len) = COND i( WHEN lv_max = 0 THEN 0
                             ELSE round( val = abs( ls_bar-value ) * lv_room / lv_max dec = 0 ) ).
      " a negative value in another colour
      DATA(lv_fill) = COND string( WHEN ls_bar-value < 0 THEN `#E8743B` ELSE `#5899DA` ).
      result = |{ result }<text x="{ lc_label - 6 }" y="{ lv_y + 15 }" text-anchor="end" fill="#32363A">| &&
               |{ xml( substring( val = ls_bar-label len = nmin( val1 = 24 val2 = strlen( ls_bar-label ) ) ) ) }</text>| &&
               |<rect x="{ lc_label }" y="{ lv_y + 3 }" width="{ nmax( val1 = 1 val2 = lv_len ) }" height="{ lc_row - 8 }" | &&
               |fill="{ lv_fill }"><title>{ xml( ls_bar-label ) }: { ls_bar-value }</title></rect>| &&
               |<text x="{ lc_label + nmax( val1 = 1 val2 = lv_len ) + 6 }" y="{ lv_y + 15 }" fill="#32363A">{ ls_bar-value }</text>|.
    ENDLOOP.
    result = |{ result }</svg>|.

  ENDMETHOD.

  METHOD xml.

    result = replace( val = val    sub = `&` with = `&amp;` occ = 0 ).
    result = replace( val = result sub = `<` with = `&lt;`  occ = 0 ).
    result = replace( val = result sub = `>` with = `&gt;`  occ = 0 ).
    result = replace( val = result sub = `"` with = `&quot;` occ = 0 ).

  ENDMETHOD.

ENDCLASS.
