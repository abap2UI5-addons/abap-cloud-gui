"! A chart as SVG - the chart of an ALV (OpenUI5 has no sap.viz): bars,
"! columns, lines or a pie, one point per category, the values summed per
"! category, the largest first; beyond the 20th the rest is one point
"! "Other". Up to cv_max_series value columns are series beside each other
"! (a pie draws the first). SVG of attributes only - no script, no style -
"! so the page's CSP lets it in
CLASS z2ui5_cl_cgui_chart DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_value TYPE p LENGTH 16 DECIMALS 2.
    TYPES:
      BEGIN OF ty_s_bar,
        label TYPE string,
        value TYPE ty_value,
      END OF ty_s_bar.
    TYPES ty_t_bar TYPE STANDARD TABLE OF ty_s_bar WITH DEFAULT KEY.

    CONSTANTS cv_max_bars TYPE i VALUE 20.
    CONSTANTS cv_max_series TYPE i VALUE 3.

    CONSTANTS:
      BEGIN OF cs_kind,
        bar    TYPE string VALUE `BAR`,
        column TYPE string VALUE `COLUMN`,
        line   TYPE string VALUE `LINE`,
        pie    TYPE string VALUE `PIE`,
      END OF cs_kind.

    TYPES ty_t_value TYPE STANDARD TABLE OF ty_value WITH DEFAULT KEY.
    TYPES:
      "! a category and its value per series; sort is the first value -
      "! what the points are ordered by
      BEGIN OF ty_s_point,
        label  TYPE string,
        values TYPE ty_t_value,
        sort   TYPE ty_value,
      END OF ty_s_point.
    TYPES ty_t_point TYPE STANDARD TABLE OF ty_s_point WITH DEFAULT KEY.

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

    "! the points of a table: category a column of tab, values the columns
    "! summed per category (at most cv_max_series, in their order) - none:
    "! the rows of each category are counted; sorted by the first value, the
    "! rest beyond cv_max_bars as other
    CLASS-METHODS series
      IMPORTING
        tab           TYPE STANDARD TABLE
        category      TYPE clike
        values        TYPE string_table OPTIONAL
        other         TYPE clike DEFAULT `Other`
      RETURNING
        VALUE(result) TYPE ty_t_point.

    "! the points as SVG of kind (cs_kind), width points wide - names are
    "! the series, a legend when there is more than one; a line goes through
    "! the categories in the order of their labels
    CLASS-METHODS chart_svg
      IMPORTING
        points        TYPE ty_t_point
        names         TYPE string_table OPTIONAL
        kind          TYPE clike DEFAULT cs_kind-bar
        width         TYPE i DEFAULT 640
      RETURNING
        VALUE(result) TYPE string.

    "! the bars as SVG, width points wide
    CLASS-METHODS svg
      IMPORTING
        bars          TYPE ty_t_bar
        width         TYPE i DEFAULT 640
      RETURNING
        VALUE(result) TYPE string.

    "! val escaped for the text or an attribute of XML - &, <, > and ", the
    "! control characters XML forbids dropped (z2ui5_cl_cgui_context=>
    "! c_escape_xml( ))
    CLASS-METHODS xml_escape
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.

    "! the colour of series n
    CLASS-METHODS color
      IMPORTING
        index         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    "! value scaled into a room of size pixels between low and high
    CLASS-METHODS scale
      IMPORTING
        value         TYPE ty_value
        low           TYPE ty_value
        high          TYPE ty_value
        size          TYPE i
      RETURNING
        VALUE(result) TYPE i.

    "! the legend of the series at the top - empty for one series
    CLASS-METHODS legend
      IMPORTING
        names         TYPE string_table
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS grouped
      IMPORTING
        points        TYPE ty_t_point
        names         TYPE string_table
        width         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS columns
      IMPORTING
        points        TYPE ty_t_point
        names         TYPE string_table
        width         TYPE i
        line          TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS pie
      IMPORTING
        points        TYPE ty_t_point
        width         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS label
      IMPORTING
        val           TYPE clike
        len           TYPE i
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS z2ui5_cl_cgui_chart IMPLEMENTATION.

  METHOD bars.

    " one series - its value, or the count of the rows
    DATA temp34 TYPE string_table.
    DATA lt_value LIKE temp34.
      DATA temp35 LIKE LINE OF lt_value.
    DATA temp36 TYPE z2ui5_cl_cgui_chart=>ty_t_point.
    DATA ls_point LIKE LINE OF temp36.
      DATA temp37 TYPE z2ui5_cl_cgui_chart=>ty_s_bar.
      FIELD-SYMBOLS <temp13> LIKE LINE OF ls_point-values.
      DATA temp14 LIKE sy-tabix.
    CLEAR temp34.

    lt_value = temp34.
    IF value IS NOT INITIAL.

      temp35 = value.
      INSERT temp35 INTO TABLE lt_value.
    ENDIF.

    temp36 = series( tab = tab category = category values = lt_value other = other ).

    LOOP AT temp36 INTO ls_point.

      CLEAR temp37.
      temp37-label = ls_point-label.


      temp14 = sy-tabix.
      READ TABLE ls_point-values INDEX 1 ASSIGNING <temp13>.
      sy-tabix = temp14.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp37-value = <temp13>.
      INSERT temp37 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD svg.

    DATA lt_point TYPE ty_t_point.

    DATA ls_bar LIKE LINE OF bars.
      DATA temp38 TYPE z2ui5_cl_cgui_chart=>ty_s_point.
      DATA temp15 TYPE z2ui5_cl_cgui_chart=>ty_t_value.
    DATA temp39 TYPE string_table.
    LOOP AT bars INTO ls_bar.

      CLEAR temp38.
      temp38-label = ls_bar-label.

      CLEAR temp15.
      INSERT ls_bar-value INTO TABLE temp15.
      temp38-values = temp15.
      temp38-sort = ls_bar-value.
      INSERT temp38 INTO TABLE lt_point.
    ENDLOOP.

    CLEAR temp39.
    result = grouped( points = lt_point
                      names  = temp39
                      width  = width ).

  ENDMETHOD.

  METHOD series.

    FIELD-SYMBOLS <category> TYPE any.
    FIELD-SYMBOLS <value>    TYPE any.
    TYPES:
      BEGIN OF ty_s_label,
        label TYPE string,
        row   TYPE i,
      END OF ty_s_label.
    DATA lt_point TYPE ty_t_point.
    DATA lt_name  TYPE string_table.
    " the row of each category in lt_point - one lookup per row of tab, not
    " a scan of the categories
    DATA lt_label TYPE HASHED TABLE OF ty_s_label WITH UNIQUE KEY label.

    DATA lv_name LIKE LINE OF values.
        DATA temp1 TYPE string.
    DATA lv_count TYPE i.
    FIELD-SYMBOLS <row> TYPE ANY.
      DATA temp40 TYPE string.
      DATA lv_label TYPE string.
      DATA ls_label TYPE ty_s_label.
        FIELD-SYMBOLS <point> TYPE z2ui5_cl_cgui_chart=>ty_s_point.
        DATA temp41 TYPE z2ui5_cl_cgui_chart=>ty_s_point.
          DATA temp42 TYPE z2ui5_cl_cgui_chart=>ty_value.
        DATA temp43 TYPE ty_s_label.
        FIELD-SYMBOLS <temp44> LIKE LINE OF <point>-values.
        DATA temp45 LIKE sy-tabix.
        FIELD-SYMBOLS <temp17> LIKE LINE OF <point>-values.
        DATA temp18 LIKE sy-tabix.
        DATA lv_index LIKE sy-tabix.
            FIELD-SYMBOLS <temp46> LIKE LINE OF <point>-values.
            DATA temp47 LIKE sy-tabix.
            FIELD-SYMBOLS <temp19> LIKE LINE OF <point>-values.
            DATA temp20 LIKE sy-tabix.
      FIELD-SYMBOLS <temp48> LIKE LINE OF <point>-values.
      DATA temp49 LIKE sy-tabix.
    DATA ls_point LIKE LINE OF lt_point.
        DATA temp50 TYPE z2ui5_cl_cgui_chart=>ty_s_point.
          DATA temp51 TYPE z2ui5_cl_cgui_chart=>ty_value.
      DATA lv_value LIKE LINE OF ls_point-values.
        FIELD-SYMBOLS <temp52> LIKE LINE OF <point>-values.
        DATA temp53 LIKE sy-tabix.
        FIELD-SYMBOLS <temp21> LIKE LINE OF <point>-values.
        DATA temp22 LIKE sy-tabix.
      FIELD-SYMBOLS <temp54> LIKE LINE OF <point>-values.
      DATA temp55 LIKE sy-tabix.
    LOOP AT values INTO lv_name.
      IF lines( lt_name ) < cv_max_series.

        temp1 = to_upper( lv_name ).
        INSERT temp1 INTO TABLE lt_name.
      ENDIF.
    ENDLOOP.

    lv_count = nmax( val1 = 1 val2 = lines( lt_name ) ).


    LOOP AT tab ASSIGNING <row>.
      ASSIGN COMPONENT category OF STRUCTURE <row> TO <category>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.

      temp40 = <category>.

      lv_label = condense( temp40 ).

      READ TABLE lt_label INTO ls_label WITH TABLE KEY label = lv_label.
      IF sy-subrc = 0.

        READ TABLE lt_point ASSIGNING <point> INDEX ls_label-row.
      ELSE.

        CLEAR temp41.
        temp41-label = lv_label.
        INSERT temp41 INTO TABLE lt_point ASSIGNING <point>.
        DO lv_count TIMES.

          CLEAR temp42.
          INSERT temp42 INTO TABLE <point>-values.
        ENDDO.

        CLEAR temp43.
        temp43-label = lv_label.
        temp43-row = lines( lt_point ).
        INSERT temp43 INTO TABLE lt_label.
      ENDIF.
      IF lt_name IS INITIAL.


        temp45 = sy-tabix.
        READ TABLE <point>-values INDEX 1 ASSIGNING <temp44>.
        sy-tabix = temp45.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp18 = sy-tabix.
        READ TABLE <point>-values INDEX 1 ASSIGNING <temp17>.
        sy-tabix = temp18.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp44> = <temp17> + 1.
        CONTINUE.
      ENDIF.
      LOOP AT lt_name INTO lv_name.

        lv_index = sy-tabix.
        ASSIGN COMPONENT lv_name OF STRUCTURE <row> TO <value>.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        TRY.


            temp47 = sy-tabix.
            READ TABLE <point>-values INDEX lv_index ASSIGNING <temp46>.
            sy-tabix = temp47.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.


            temp20 = sy-tabix.
            READ TABLE <point>-values INDEX lv_index ASSIGNING <temp19>.
            sy-tabix = temp20.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp46> = <temp19> + <value>.
          CATCH cx_sy_conversion_error cx_sy_arithmetic_error ##NO_HANDLER.
        ENDTRY.
      ENDLOOP.
    ENDLOOP.

    LOOP AT lt_point ASSIGNING <point>.


      temp49 = sy-tabix.
      READ TABLE <point>-values INDEX 1 ASSIGNING <temp48>.
      sy-tabix = temp49.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      <point>-sort = <temp48>.
    ENDLOOP.
    SORT lt_point BY sort DESCENDING label ASCENDING.

    LOOP AT lt_point INTO ls_point.
      IF sy-tabix <= cv_max_bars.
        INSERT ls_point INTO TABLE result.
        CONTINUE.
      ENDIF.
      IF lines( result ) = cv_max_bars.

        CLEAR temp50.
        temp50-label = other.
        INSERT temp50 INTO TABLE result ASSIGNING <point>.
        DO lv_count TIMES.

          CLEAR temp51.
          INSERT temp51 INTO TABLE <point>-values.
        ENDDO.
      ENDIF.
      READ TABLE result INDEX lines( result ) ASSIGNING <point>.

      LOOP AT ls_point-values INTO lv_value.


        temp53 = sy-tabix.
        READ TABLE <point>-values INDEX sy-tabix ASSIGNING <temp52>.
        sy-tabix = temp53.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp22 = sy-tabix.
        READ TABLE <point>-values INDEX sy-tabix ASSIGNING <temp21>.
        sy-tabix = temp22.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp52> = <temp21> + lv_value.
      ENDLOOP.


      temp55 = sy-tabix.
      READ TABLE <point>-values INDEX 1 ASSIGNING <temp54>.
      sy-tabix = temp55.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      <point>-sort = <temp54>.
    ENDLOOP.

  ENDMETHOD.

  METHOD chart_svg.

    DATA lv_kind TYPE string.
    lv_kind = to_upper( kind ).
    CASE lv_kind.
      WHEN cs_kind-pie.
        result = pie( points = points
                      width  = width ).
      WHEN cs_kind-column.
        result = columns( points = points
                          names  = names
                          width  = width
                          line   = abap_false ).
      WHEN cs_kind-line.
        result = columns( points = points
                          names  = names
                          width  = width
                          line   = abap_true ).
      WHEN OTHERS.
        result = grouped( points = points
                          names  = names
                          width  = width ).
    ENDCASE.

  ENDMETHOD.

  METHOD color.

    DATA lv_slot TYPE i.
    lv_slot = ( index - 1 ) MOD 5.
    CASE lv_slot.
      WHEN 0.
        result = `#5899DA`.
      WHEN 1.
        result = `#E8743B`.
      WHEN 2.
        result = `#19A979`.
      WHEN 3.
        result = `#ED4A7B`.
      WHEN OTHERS.
        result = `#945ECF`.
    ENDCASE.

  ENDMETHOD.

  METHOD scale.

    IF high = low.
      RETURN.
    ENDIF.
    result = round( val = ( value - low ) * size / ( high - low ) dec = 0 ).

  ENDMETHOD.

  METHOD label.

    result = xml_escape( substring( val = val len = nmin( val1 = len val2 = strlen( val ) ) ) ).

  ENDMETHOD.

  METHOD legend.
    DATA lv_name LIKE LINE OF names.
      DATA lv_x TYPE i.

    IF lines( names ) < 2.
      RETURN.
    ENDIF.

    LOOP AT names INTO lv_name.

      lv_x = ( sy-tabix - 1 ) * 150 + 4.
      result = |{ result }<rect x="{ lv_x }" y="4" width="12" height="12" fill="{ color( sy-tabix ) }"/>| &&
               |<text x="{ lv_x + 16 }" y="15" fill="#32363A">{ label( val = lv_name len = 18 ) }</text>|.
    ENDLOOP.

  ENDMETHOD.

  METHOD grouped.

    " the bars of a category beside each other, one row per category
    CONSTANTS lc_bar   TYPE i VALUE 16.
    CONSTANTS lc_label TYPE i VALUE 160.
    CONSTANTS lc_text  TYPE i VALUE 90.

    DATA lv_max TYPE ty_value.

    DATA lv_series TYPE i.
    DATA ls_point LIKE LINE OF points.
      DATA lv_value LIKE LINE OF ls_point-values.
    DATA temp56 TYPE i.
    DATA lv_top LIKE temp56.
    DATA lv_row TYPE i.
    DATA lv_room TYPE i.
    DATA lv_height TYPE i.
      DATA lv_y TYPE i.
        DATA lv_index LIKE sy-tabix.
        DATA lv_len TYPE i.
        DATA lv_bar_y TYPE i.
        DATA temp57 TYPE string.
        DATA lv_fill LIKE temp57.
    lv_series = 1.

    LOOP AT points INTO ls_point.
      lv_series = nmax( val1 = lv_series val2 = lines( ls_point-values ) ).

      LOOP AT ls_point-values INTO lv_value.
        lv_max = nmax( val1 = lv_max val2 = abs( lv_value ) ).
      ENDLOOP.
    ENDLOOP.

    IF lines( names ) > 1.
      temp56 = 24.
    ELSE.
      temp56 = 4.
    ENDIF.

    lv_top = temp56.

    lv_row = lv_series * lc_bar + 8.

    lv_room = nmax( val1 = 40 val2 = width - lc_label - lc_text ).

    lv_height = lv_top + nmax( val1 = 1 val2 = lines( points ) ) * lv_row + 4.

    result = |<svg xmlns="http://www.w3.org/2000/svg" width="{ width }" height="{ lv_height }" | &&
             |viewBox="0 0 { width } { lv_height }" font-family="sans-serif" font-size="12">{ legend( names ) }|.
    LOOP AT points INTO ls_point.

      lv_y = lv_top + ( sy-tabix - 1 ) * lv_row.
      result = |{ result }<text x="{ lc_label - 6 }" y="{ lv_y + lv_row / 2 + 4 }" text-anchor="end" fill="#32363A">| &&
               |{ label( val = ls_point-label len = 24 ) }</text>|.
      LOOP AT ls_point-values INTO lv_value.

        lv_index = sy-tabix.

        lv_len = nmax( val1 = 1 val2 = scale( value = abs( lv_value ) low = 0 high = lv_max size = lv_room ) ).

        lv_bar_y = lv_y + 4 + ( lv_index - 1 ) * lc_bar.
        " a negative value in another colour, as the single series always had

        IF lv_series = 1 AND lv_value < 0.
          temp57 = `#E8743B`.
        ELSE.
          temp57 = color( lv_index ).
        ENDIF.

        lv_fill = temp57.
        result = |{ result }<rect x="{ lc_label }" y="{ lv_bar_y }" width="{ lv_len }" height="{ lc_bar - 2 }" | &&
                 |fill="{ lv_fill }"><title>{ xml_escape( ls_point-label ) }: { lv_value }</title></rect>| &&
                 |<text x="{ lc_label + lv_len + 6 }" y="{ lv_bar_y + lc_bar - 4 }" fill="#32363A">{ lv_value }</text>|.
      ENDLOOP.
    ENDLOOP.
    result = |{ result }</svg>|.

  ENDMETHOD.

  METHOD columns.

    " the categories along the x axis - columns beside each other, or a
    " line per series through them
    CONSTANTS lc_plot TYPE i VALUE 240.
    CONSTANTS lc_axis TYPE i VALUE 50.

    DATA lv_low  TYPE ty_value.
    DATA lv_high TYPE ty_value.
    DATA lt_point TYPE ty_t_point.
    DATA lv_series TYPE i.
    DATA ls_point LIKE LINE OF lt_point.
      DATA lv_value LIKE LINE OF ls_point-values.
    DATA temp58 TYPE i.
    DATA lv_top LIKE temp58.
    DATA lv_slot TYPE i.
    DATA lv_height TYPE i.
    DATA lv_zero TYPE i.
    DATA lv_bar TYPE i.
      DATA lv_index LIKE sy-index.
      DATA lv_path TYPE string.
        DATA lv_x TYPE i.
        DATA lv_y TYPE i.
          DATA lv_cx TYPE i.
          DATA temp59 TYPE string.

    lt_point = points.
    IF line = abap_true.
      SORT lt_point BY label ASCENDING.
    ENDIF.

    lv_series = 1.

    LOOP AT lt_point INTO ls_point.
      lv_series = nmax( val1 = lv_series val2 = lines( ls_point-values ) ).

      LOOP AT ls_point-values INTO lv_value.
        lv_low = nmin( val1 = lv_low val2 = lv_value ).
        lv_high = nmax( val1 = lv_high val2 = lv_value ).
      ENDLOOP.
    ENDLOOP.

    IF lines( names ) > 1.
      temp58 = 28.
    ELSE.
      temp58 = 8.
    ENDIF.

    lv_top = temp58.

    lv_slot = nmax( val1 = 1 val2 = ( width - lc_axis - 8 ) / nmax( val1 = 1 val2 = lines( lt_point ) ) ).

    lv_height = lv_top + lc_plot + 40.
    " the zero line

    lv_zero = lv_top + lc_plot - scale( value = 0 low = lv_low high = lv_high size = lc_plot ).

    result = |<svg xmlns="http://www.w3.org/2000/svg" width="{ width }" height="{ lv_height }" | &&
             |viewBox="0 0 { width } { lv_height }" font-family="sans-serif" font-size="12">{ legend( names ) }| &&
             |<line x1="{ lc_axis }" y1="{ lv_zero }" x2="{ width - 4 }" y2="{ lv_zero }" stroke="#89919A"/>| &&
             |<text x="{ lc_axis - 6 }" y="{ lv_top + 10 }" text-anchor="end" fill="#32363A">{ lv_high }</text>| &&
             |<text x="{ lc_axis - 6 }" y="{ lv_top + lc_plot }" text-anchor="end" fill="#32363A">{ lv_low }</text>|.


    lv_bar = nmax( val1 = 2 val2 = ( lv_slot - 8 ) / lv_series ).
    DO lv_series TIMES.

      lv_index = sy-index.

      lv_path = ``.
      LOOP AT lt_point INTO ls_point.

        lv_x = lc_axis + ( sy-tabix - 1 ) * lv_slot.
        IF lv_index = 1.
          result = |{ result }<text x="{ lv_x + lv_slot / 2 }" y="{ lv_top + lc_plot + 18 }" text-anchor="middle" | &&
                   |fill="#32363A">{ label( val = ls_point-label len = nmax( val1 = 1 val2 = lv_slot / 8 ) ) }</text>|.
        ENDIF.
        READ TABLE ls_point-values INTO lv_value INDEX lv_index.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        lv_y = lv_top + lc_plot - scale( value = lv_value low = lv_low high = lv_high size = lc_plot ).
        IF line = abap_true.

          lv_cx = lv_x + lv_slot / 2.

          IF lv_path IS INITIAL.
            temp59 = |{ lv_cx },{ lv_y }|.
          ELSE.
            temp59 = |{ lv_path } { lv_cx },{ lv_y }|.
          ENDIF.
          lv_path = temp59.
          result = |{ result }<circle cx="{ lv_cx }" cy="{ lv_y }" r="3" fill="{ color( lv_index ) }">| &&
                   |<title>{ xml_escape( ls_point-label ) }: { lv_value }</title></circle>|.
        ELSE.
          result = |{ result }<rect x="{ lv_x + 4 + ( lv_index - 1 ) * lv_bar }" y="{ nmin( val1 = lv_y val2 = lv_zero ) }" | &&
                   |width="{ lv_bar - 1 }" height="{ nmax( val1 = 1 val2 = abs( lv_zero - lv_y ) ) }" fill="{ color( lv_index ) }">| &&
                   |<title>{ xml_escape( ls_point-label ) }: { lv_value }</title></rect>|.
        ENDIF.
      ENDLOOP.
      IF line = abap_true AND lv_path IS NOT INITIAL.
        result = |{ result }<polyline points="{ lv_path }" fill="none" stroke="{ color( lv_index ) }" stroke-width="2"/>|.
      ENDIF.
    ENDDO.
    result = |{ result }</svg>|.

  ENDMETHOD.

  METHOD pie.

    " the first series, its positive values as slices - the legend beside
    " the pie with the share of each
    CONSTANTS lc_radius TYPE i VALUE 110.
    CONSTANTS lc_pi     TYPE f VALUE '3.14159265358979'.

    DATA lv_total TYPE ty_value.
    DATA lv_angle TYPE f.
    DATA lv_end   TYPE f.
    DATA lv_share TYPE ty_value.

    DATA ls_point LIKE LINE OF points.
      DATA lv_value TYPE z2ui5_cl_cgui_chart=>ty_value.
    DATA lv_height TYPE i.
    DATA lv_cx TYPE i.
    DATA lv_cy TYPE i.
      DATA lv_index LIKE sy-tabix.
      DATA lv_x1 TYPE i.
      DATA lv_y1 TYPE i.
      DATA lv_x2 TYPE i.
      DATA lv_y2 TYPE i.
      DATA temp60 TYPE i.
      DATA lv_large LIKE temp60.
      DATA lv_ly TYPE i.
    LOOP AT points INTO ls_point.

      READ TABLE ls_point-values INTO lv_value INDEX 1.
      IF sy-subrc = 0 AND lv_value > 0.
        lv_total = lv_total + lv_value.
      ENDIF.
    ENDLOOP.

    lv_height = nmax( val1 = 2 * lc_radius + 16 val2 = lines( points ) * 20 + 16 ).

    lv_cx = lc_radius + 8.

    lv_cy = lc_radius + 8.

    result = |<svg xmlns="http://www.w3.org/2000/svg" width="{ width }" height="{ lv_height }" | &&
             |viewBox="0 0 { width } { lv_height }" font-family="sans-serif" font-size="12">|.
    IF lv_total <= 0.
      result = |{ result }</svg>|.
      RETURN.
    ENDIF.
    LOOP AT points INTO ls_point.

      lv_index = sy-tabix.
      READ TABLE ls_point-values INTO lv_value INDEX 1.
      IF sy-subrc <> 0 OR lv_value <= 0.
        CONTINUE.
      ENDIF.
      lv_end = lv_angle + 2 * lc_pi * lv_value / lv_total.

      lv_x1 = lv_cx + round( val = lc_radius * sin( lv_angle ) dec = 0 ).

      lv_y1 = lv_cy - round( val = lc_radius * cos( lv_angle ) dec = 0 ).

      lv_x2 = lv_cx + round( val = lc_radius * sin( lv_end ) dec = 0 ).

      lv_y2 = lv_cy - round( val = lc_radius * cos( lv_end ) dec = 0 ).

      IF lv_end - lv_angle > lc_pi.
        temp60 = 1.
      ELSE.
        temp60 = 0.
      ENDIF.

      lv_large = temp60.
      lv_share = lv_value * 100 / lv_total.
      " one slice of all is the whole circle - an arc cannot end where it starts
      IF lv_value = lv_total.
        result = |{ result }<circle cx="{ lv_cx }" cy="{ lv_cy }" r="{ lc_radius }" fill="{ color( lv_index ) }">| &&
                 |<title>{ xml_escape( ls_point-label ) }: { lv_value }</title></circle>|.
      ELSE.
        result = |{ result }<path d="M { lv_cx } { lv_cy } L { lv_x1 } { lv_y1 } A { lc_radius } { lc_radius } 0 { lv_large } 1 { lv_x2 } { lv_y2 } Z" | &&
                 |fill="{ color( lv_index ) }"><title>{ xml_escape( ls_point-label ) }: { lv_value }</title></path>|.
      ENDIF.

      lv_ly = 8 + ( lv_index - 1 ) * 20.
      result = |{ result }<rect x="{ 2 * lc_radius + 32 }" y="{ lv_ly }" width="12" height="12" fill="{ color( lv_index ) }"/>| &&
               |<text x="{ 2 * lc_radius + 50 }" y="{ lv_ly + 11 }" fill="#32363A">| &&
               |{ label( val = ls_point-label len = 24 ) } { lv_share DECIMALS = 1 } %</text>|.
      lv_angle = lv_end.
    ENDLOOP.
    result = |{ result }</svg>|.

  ENDMETHOD.

  METHOD xml_escape.

    result = z2ui5_cl_cgui_context=>c_escape_xml( val ).

  ENDMETHOD.

ENDCLASS.
