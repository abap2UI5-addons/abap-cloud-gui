" the instance of the report for its local classes - set at the start of
" every event method; the local classes reach the report's data through it
CLASS lcl_r2c DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA app TYPE REF TO z2ui5_cl_cgui_r2c_54.
ENDCLASS.


CLASS lcl_r2c IMPLEMENTATION.
ENDCLASS.

CLASS lcl_lines DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_r2c_54 DEFINITION LOCAL FRIENDS lcl_lines.

CLASS lcl_lines DEFINITION.
  PUBLIC SECTION.
    METHODS write_totals.
ENDCLASS.


CLASS lcl_lines IMPLEMENTATION.
  METHOD write_totals.
    DATA lv_total TYPE p LENGTH 8 DECIMALS 2.

    LOOP AT lcl_r2c=>app->gt_item INTO lcl_r2c=>app->wa_gt_item.
      lv_total = lv_total + lcl_r2c=>app->wa_gt_item-amount.
    ENDLOOP.
    lcl_r2c=>app->list( )->skip( ).
    lcl_r2c=>app->wa_gt_item-id = 0.
    lcl_r2c=>app->wa_gt_item-name = 'Total'.
    lcl_r2c=>app->list( )->new_line(
        )->write( 'Total'
        )->write( val         = lv_total
                  intensified = abap_true ).
    lcl_r2c=>app->list( )->hide( |{ lcl_r2c=>app->wa_gt_item-id }\t{ lcl_r2c=>app->wa_gt_item-name }| ).
  ENDMETHOD.
ENDCLASS.
