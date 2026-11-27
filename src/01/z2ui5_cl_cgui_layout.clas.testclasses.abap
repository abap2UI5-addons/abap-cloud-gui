CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

    DATA mv_init  TYPE abap_bool.
    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.
    DATA mv_popup TYPE string.
    DATA mv_left  TYPE abap_bool.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.

  METHOD z2ui5_if_client~check_on_init.

    result = mv_init.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event.

    result = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = `{/BOUND}`.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.

    mv_left = abap_true.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_client TYPE REF TO ltcl_client.
    DATA mt_base   TYPE z2ui5_cl_cgui_alv=>ty_t_layout.

    METHODS setup.

    METHODS run
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_layout
        event TYPE string       OPTIONAL
        args  TYPE string_table OPTIONAL
        init  TYPE abap_bool    DEFAULT abap_false.

    METHODS rows_roundtrip FOR TESTING.
    METHODS variant_roundtrip FOR TESTING.
    METHODS merge_unknown_columns_last FOR TESTING.
    METHODS move_and_apply FOR TESTING.
    METHODS save_and_load FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_client = NEW #( ).
    mt_base = VALUE #( ( name = `CARRID` text = `Airline` position = 1 )
                       ( name = `FLDATE` text = `Date`    position = 2 )
                       ( name = `PRICE`  text = `Price`   position = 3 numeric = abap_true ) ).

  ENDMETHOD.

  METHOD run.

    mo_client->mv_init  = init.
    mo_client->mv_event = event.
    mo_client->mt_arg   = args.
    popup->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD rows_roundtrip.

    DATA(lt_row) = z2ui5_cl_cgui_layout=>layout_to_rows( mt_base ).
    lt_row[ 1 ]-sort = z2ui5_cl_cgui_alv=>cs_sort-descending.
    lt_row[ 1 ]-subtotal = abap_true.
    lt_row[ 2 ]-visible = abap_false.
    " a total on a column that is no number and a subtotal without a sort
    " are dropped
    lt_row[ 2 ]-sum = abap_true.
    lt_row[ 2 ]-subtotal = abap_true.
    lt_row[ 3 ]-sum = abap_true.

    DATA(lt_layout) = z2ui5_cl_cgui_layout=>rows_to_layout( lt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_layout[ 1 ]-sort_seq
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_true( lt_layout[ 1 ]-subtotal ).
    cl_abap_unit_assert=>assert_true( lt_layout[ 2 ]-hidden ).
    cl_abap_unit_assert=>assert_false( lt_layout[ 2 ]-sum ).
    cl_abap_unit_assert=>assert_false( lt_layout[ 2 ]-subtotal ).
    cl_abap_unit_assert=>assert_true( lt_layout[ 3 ]-sum ).

    " sorted by PRICE, then CARRID - the rows moved in the dialog keep that
    " rank; a column sorted in the dialog comes after
    DATA(lt_sorted) = mt_base.
    lt_sorted[ 3 ]-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.
    lt_sorted[ 3 ]-sort_seq = 1.
    lt_sorted[ 1 ]-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.
    lt_sorted[ 1 ]-sort_seq = 2.
    lt_row = z2ui5_cl_cgui_layout=>layout_to_rows( lt_sorted ).
    lt_row[ 2 ]-sort = z2ui5_cl_cgui_alv=>cs_sort-descending.
    lt_layout = z2ui5_cl_cgui_layout=>rows_to_layout( lt_row ).
    cl_abap_unit_assert=>assert_equals( act = lt_layout[ name = `PRICE` ]-sort_seq
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_layout[ name = `CARRID` ]-sort_seq
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_layout[ name = `FLDATE` ]-sort_seq
                                        exp = 3 ).

  ENDMETHOD.

  METHOD variant_roundtrip.

    DATA(lt_layout) = mt_base.
    lt_layout[ 2 ]-hidden = abap_true.
    lt_layout[ 3 ]-sum = abap_true.
    lt_layout[ 1 ]-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.
    lt_layout[ 1 ]-sort_seq = 1.
    lt_layout[ 1 ]-subtotal = abap_true.

    DATA(ls_variant) = z2ui5_cl_cgui_layout=>to_variant( name    = `MINE`
                                                         is_default = abap_true
                                                         layout     = lt_layout ).
    cl_abap_unit_assert=>assert_equals( act = ls_variant-name
                                        exp = `#L#MINE` ).

    DATA(lt_saved) = z2ui5_cl_cgui_layout=>from_variants( VALUE #( ( name = `SEL_VARIANT` )
                                                                   ( ls_variant ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_saved )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_saved[ 1 ]-name
                                        exp = `MINE` ).
    cl_abap_unit_assert=>assert_true( lt_saved[ 1 ]-is_default ).
    DATA(lt_back) = lt_saved[ 1 ]-layout.
    cl_abap_unit_assert=>assert_true( lt_back[ name = `FLDATE` ]-hidden ).
    cl_abap_unit_assert=>assert_true( lt_back[ name = `PRICE` ]-sum ).
    cl_abap_unit_assert=>assert_true( lt_back[ name = `CARRID` ]-subtotal ).
    cl_abap_unit_assert=>assert_equals( act = lt_back[ name = `CARRID` ]-sort
                                        exp = `ASC` ).

  ENDMETHOD.

  METHOD merge_unknown_columns_last.

    " the saved layout knows PRICE first and FLDATE - not CARRID
    DATA(lt_merged) = z2ui5_cl_cgui_layout=>layout_merge(
        base  = mt_base
        saved = VALUE #( ( name = `PRICE`  position = 1 )
                         ( name = `FLDATE` position = 2 hidden = abap_true ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lt_merged[ 1 ]-name
                                        exp = `PRICE` ).
    cl_abap_unit_assert=>assert_equals( act = lt_merged[ 3 ]-name
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_merged[ 3 ]-text
                                        exp = `Airline` ).
    cl_abap_unit_assert=>assert_true( lt_merged[ 2 ]-hidden ).

  ENDMETHOD.

  METHOD move_and_apply.

    DATA(lo_popup) = z2ui5_cl_cgui_layout=>factory( mt_base ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*selectedKey="{SORT}"*` ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-up
         args  = VALUE #( ( `PRICE` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mt_row[ 2 ]-name
                                        exp = `PRICE` ).
    " the first row does not move up
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-up
         args  = VALUE #( ( `CARRID` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mt_row[ 1 ]-name
                                        exp = `CARRID` ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-ok ).
    DATA(ls_result) = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-action
                                        exp = z2ui5_cl_cgui_layout=>cs_action-apply ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-layout[ name = `PRICE` ]-position
                                        exp = 2 ).

  ENDMETHOD.

  METHOD save_and_load.

    DATA(lo_popup) = z2ui5_cl_cgui_layout=>factory(
        layout = mt_base
        saved  = VALUE #( ( name       = `NARROW`
                            is_default = abap_true
                            layout  = VALUE #( ( name = `PRICE` position = 1 )
                                               ( name = `FLDATE` position = 2 hidden = abap_true ) ) ) ) ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*NARROW (Default)*` ).

    lo_popup->mv_selected = `NARROW`.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-load ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mt_row[ 1 ]-name
                                        exp = `PRICE` ).
    cl_abap_unit_assert=>assert_false( lo_popup->mt_row[ 2 ]-visible ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mv_name
                                        exp = `NARROW` ).

    " OK as it was loaded: applied, not saved again
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-ok ).
    DATA(ls_result) = lo_popup->result( ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-action
                                        exp = z2ui5_cl_cgui_layout=>cs_action-apply ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-name
                                        exp = `NARROW` ).

    " changed, it is saved under its name
    lo_popup->mt_row[ 2 ]-visible = abap_true.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-ok ).
    ls_result = lo_popup->result( ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-action
                                        exp = z2ui5_cl_cgui_layout=>cs_action-save ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-name
                                        exp = `NARROW` ).
    cl_abap_unit_assert=>assert_true( ls_result-is_default ).

  ENDMETHOD.

ENDCLASS.
