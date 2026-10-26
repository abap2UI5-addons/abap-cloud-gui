CLASS z2ui5_cl_cgui_r2c_45 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_item,
        item   TYPE n LENGTH 3,
        name   TYPE c LENGTH 20,
        weight TYPE i,
      END OF ty_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_gui_event REDEFINITION.
    METHODS cgui_statics_keep REDEFINITION.
    METHODS cgui_statics_restore REDEFINITION.

  PRIVATE SECTION.
    " the CLASS-DATA of the local classes between two roundtrips
    " lcl_pack=>gt_item
    DATA mr_cgui_static1 TYPE REF TO data.
    " lcl_pack=>go_salv
    DATA mr_cgui_static2 TYPE REF TO data.

ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_45 IMPLEMENTATION.

  METHOD initialization.

    lcl_r2c=>app = me.

    set_title( `Packing List` ).

  ENDMETHOD.

  METHOD start_of_selection.

    lcl_r2c=>app = me.

    lcl_pack=>show( ).
    write( space ).

  ENDMETHOD.

  METHOD at_gui_event.

    lcl_r2c=>app = me.

  ENDMETHOD.

  METHOD cgui_statics_keep.

    lcl_r2c=>app = me.

    " the CLASS-DATA of the local classes - kept with the app until the next roundtrip
    FIELD-SYMBOLS <lv_cgui_static> TYPE any.
    CREATE DATA mr_cgui_static1 LIKE lcl_pack=>gt_item.
    ASSIGN mr_cgui_static1->* TO <lv_cgui_static>.
    <lv_cgui_static> = lcl_pack=>gt_item.
    CREATE DATA mr_cgui_static2 LIKE lcl_pack=>go_salv.
    ASSIGN mr_cgui_static2->* TO <lv_cgui_static>.
    <lv_cgui_static> = lcl_pack=>go_salv.

  ENDMETHOD.

  METHOD cgui_statics_restore.

    lcl_r2c=>app = me.

    " the CLASS-DATA of the local classes - as the last roundtrip left them
    FIELD-SYMBOLS <lv_cgui_static> TYPE any.
    IF mr_cgui_static1 IS BOUND.
      ASSIGN mr_cgui_static1->* TO <lv_cgui_static>.
      lcl_pack=>gt_item = <lv_cgui_static>.
    ENDIF.
    IF mr_cgui_static2 IS BOUND.
      ASSIGN mr_cgui_static2->* TO <lv_cgui_static>.
      lcl_pack=>go_salv = <lv_cgui_static>.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
