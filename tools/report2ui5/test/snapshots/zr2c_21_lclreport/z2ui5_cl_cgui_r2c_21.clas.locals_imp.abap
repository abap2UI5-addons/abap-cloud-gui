" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_21.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS z2ui5_cl_cgui_r2c_21 DEFINITION LOCAL FRIENDS lcl_report.


CLASS lcl_report IMPLEMENTATION.
  METHOD constructor.
    mv_title = iv_title.
  ENDMETHOD.

  METHOD run.
    read( ).
    IF mt_flight IS INITIAL.
      lcl_r2c=>app->message( 'No flights' ).
      RETURN.
    ENDIF.
    show( ).
    lcl_r2c=>app->total( ).
  ENDMETHOD.

  METHOD read.
    SELECT carrid, connid, seatsocc FROM sflight
      INTO TABLE @mt_flight
      WHERE carrid = @lcl_r2c=>app->p_carrid
      ORDER BY carrid, connid, fldate.
  ENDMETHOD.

  METHOD show.
    lcl_r2c=>app->list( )->new_line(
        )->write( val   = mv_title
                  color = z2ui5_cl_cgui_list=>cs_color-key ).
    LOOP AT mt_flight INTO DATA(ls_flight).
      IF sy-tabix > z2ui5_cl_cgui_r2c_21=>gc_max.
        EXIT.
      ENDIF.
      lcl_r2c=>app->list( )->new_line(
          )->write( ls_flight-connid
          )->write( ls_flight-seatsocc ).
      lcl_r2c=>app->gv_total = lcl_r2c=>app->gv_total + ls_flight-seatsocc.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
