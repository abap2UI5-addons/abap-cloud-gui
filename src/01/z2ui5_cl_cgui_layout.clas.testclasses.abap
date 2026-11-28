CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mv_init  TYPE abap_bool.
    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.
    DATA mv_popup TYPE string.
    DATA mv_left  TYPE abap_bool.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
  METHOD z2ui5_if_client~timer_stop.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~timer_set.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_nav_back.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_nav_tag.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_nav_pending.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_navigated.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_event.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~follow_up_action.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~window_bind_tab.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_path.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_client.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~message_toast_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~message_box_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nav_app_call.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_app.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_start_param.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~hash_replace.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~hash_set.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~app_state_get_href.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~app_state_set_active.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~set_session_stateful.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.

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
    DATA temp1 TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp2 LIKE LINE OF temp1.

    CREATE OBJECT mo_client.

    CLEAR temp1.

    CLEAR temp2.
    temp2-name = `CARRID`.
    temp2-text = `Airline`.
    temp2-position = 1.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-name = `FLDATE`.
    temp2-text = `Date`.
    temp2-position = 2.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-name = `PRICE`.
    temp2-text = `Price`.
    temp2-position = 3.
    temp2-numeric = abap_true.
    INSERT temp2 INTO TABLE temp1.
    mt_base = temp1.

  ENDMETHOD.

  METHOD run.

    mo_client->mv_init  = init.
    mo_client->mv_event = event.
    mo_client->mt_arg   = args.
    popup->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD rows_roundtrip.

    DATA lt_row TYPE z2ui5_cl_cgui_layout=>ty_t_row.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_row.
    DATA temp4 LIKE sy-tabix.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_row.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_row.
    DATA temp8 LIKE sy-tabix.
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_row.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp11> LIKE LINE OF lt_row.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp13> LIKE LINE OF lt_row.
    DATA temp14 LIKE sy-tabix.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp15> LIKE LINE OF lt_layout.
    DATA temp16 LIKE sy-tabix.
    FIELD-SYMBOLS <temp17> LIKE LINE OF lt_layout.
    DATA temp18 LIKE sy-tabix.
    FIELD-SYMBOLS <temp19> LIKE LINE OF lt_layout.
    DATA temp20 LIKE sy-tabix.
    FIELD-SYMBOLS <temp21> LIKE LINE OF lt_layout.
    DATA temp22 LIKE sy-tabix.
    FIELD-SYMBOLS <temp23> LIKE LINE OF lt_layout.
    DATA temp24 LIKE sy-tabix.
    FIELD-SYMBOLS <temp25> LIKE LINE OF lt_layout.
    DATA temp26 LIKE sy-tabix.
    DATA lt_sorted LIKE mt_base.
    FIELD-SYMBOLS <temp27> LIKE LINE OF lt_sorted.
    DATA temp28 LIKE sy-tabix.
    FIELD-SYMBOLS <temp29> LIKE LINE OF lt_sorted.
    DATA temp30 LIKE sy-tabix.
    FIELD-SYMBOLS <temp31> LIKE LINE OF lt_sorted.
    DATA temp32 LIKE sy-tabix.
    FIELD-SYMBOLS <temp33> LIKE LINE OF lt_sorted.
    DATA temp34 LIKE sy-tabix.
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_row.
    DATA temp36 LIKE sy-tabix.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_layout.
    DATA temp38 LIKE sy-tabix.
    FIELD-SYMBOLS <temp39> LIKE LINE OF lt_layout.
    DATA temp40 LIKE sy-tabix.
    FIELD-SYMBOLS <temp41> LIKE LINE OF lt_layout.
    DATA temp42 LIKE sy-tabix.
    lt_row = z2ui5_cl_cgui_layout=>layout_to_rows( mt_base ).


    temp4 = sy-tabix.
    READ TABLE lt_row INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp3>-sort = z2ui5_cl_cgui_alv=>cs_sort-descending.


    temp6 = sy-tabix.
    READ TABLE lt_row INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp5>-subtotal = abap_true.


    temp8 = sy-tabix.
    READ TABLE lt_row INDEX 2 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp7>-visible = abap_false.
    " a total on a column that is no number and a subtotal without a sort
    " are dropped


    temp10 = sy-tabix.
    READ TABLE lt_row INDEX 2 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp9>-sum = abap_true.


    temp12 = sy-tabix.
    READ TABLE lt_row INDEX 2 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp11>-subtotal = abap_true.


    temp14 = sy-tabix.
    READ TABLE lt_row INDEX 3 ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp13>-sum = abap_true.


    lt_layout = z2ui5_cl_cgui_layout=>rows_to_layout( lt_row ).


    temp16 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp15>.
    sy-tabix = temp16.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp15>-sort_seq
                                        exp = 1 ).


    temp18 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp17>-subtotal ).


    temp20 = sy-tabix.
    READ TABLE lt_layout INDEX 2 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp19>-hidden ).


    temp22 = sy-tabix.
    READ TABLE lt_layout INDEX 2 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp21>-sum ).


    temp24 = sy-tabix.
    READ TABLE lt_layout INDEX 2 ASSIGNING <temp23>.
    sy-tabix = temp24.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp23>-subtotal ).


    temp26 = sy-tabix.
    READ TABLE lt_layout INDEX 3 ASSIGNING <temp25>.
    sy-tabix = temp26.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp25>-sum ).

    " sorted by PRICE, then CARRID - the rows moved in the dialog keep that
    " rank; a column sorted in the dialog comes after

    lt_sorted = mt_base.


    temp28 = sy-tabix.
    READ TABLE lt_sorted INDEX 3 ASSIGNING <temp27>.
    sy-tabix = temp28.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp27>-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.


    temp30 = sy-tabix.
    READ TABLE lt_sorted INDEX 3 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp29>-sort_seq = 1.


    temp32 = sy-tabix.
    READ TABLE lt_sorted INDEX 1 ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp31>-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.


    temp34 = sy-tabix.
    READ TABLE lt_sorted INDEX 1 ASSIGNING <temp33>.
    sy-tabix = temp34.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp33>-sort_seq = 2.
    lt_row = z2ui5_cl_cgui_layout=>layout_to_rows( lt_sorted ).


    temp36 = sy-tabix.
    READ TABLE lt_row INDEX 2 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp35>-sort = z2ui5_cl_cgui_alv=>cs_sort-descending.
    lt_layout = z2ui5_cl_cgui_layout=>rows_to_layout( lt_row ).


    temp38 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `PRICE` ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp37>-sort_seq
                                        exp = 1 ).


    temp40 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `CARRID` ASSIGNING <temp39>.
    sy-tabix = temp40.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp39>-sort_seq
                                        exp = 2 ).


    temp42 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `FLDATE` ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp41>-sort_seq
                                        exp = 3 ).

  ENDMETHOD.

  METHOD variant_roundtrip.

    DATA lt_layout LIKE mt_base.
    FIELD-SYMBOLS <temp43> LIKE LINE OF lt_layout.
    DATA temp44 LIKE sy-tabix.
    FIELD-SYMBOLS <temp45> LIKE LINE OF lt_layout.
    DATA temp46 LIKE sy-tabix.
    FIELD-SYMBOLS <temp47> LIKE LINE OF lt_layout.
    DATA temp48 LIKE sy-tabix.
    FIELD-SYMBOLS <temp49> LIKE LINE OF lt_layout.
    DATA temp50 LIKE sy-tabix.
    FIELD-SYMBOLS <temp51> LIKE LINE OF lt_layout.
    DATA temp52 LIKE sy-tabix.
    DATA ls_variant TYPE z2ui5_cl_cgui_variant=>ty_s_variant.
    DATA temp53 TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp54 LIKE LINE OF temp53.
    DATA lt_saved TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
    FIELD-SYMBOLS <temp55> LIKE LINE OF lt_saved.
    DATA temp56 LIKE sy-tabix.
    FIELD-SYMBOLS <temp57> LIKE LINE OF lt_saved.
    DATA temp58 LIKE sy-tabix.
    DATA lt_back TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_saved.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp59> LIKE LINE OF lt_back.
    DATA temp60 LIKE sy-tabix.
    FIELD-SYMBOLS <temp61> LIKE LINE OF lt_back.
    DATA temp62 LIKE sy-tabix.
    FIELD-SYMBOLS <temp63> LIKE LINE OF lt_back.
    DATA temp64 LIKE sy-tabix.
    FIELD-SYMBOLS <temp65> LIKE LINE OF lt_back.
    DATA temp66 LIKE sy-tabix.
    lt_layout = mt_base.


    temp44 = sy-tabix.
    READ TABLE lt_layout INDEX 2 ASSIGNING <temp43>.
    sy-tabix = temp44.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp43>-hidden = abap_true.


    temp46 = sy-tabix.
    READ TABLE lt_layout INDEX 3 ASSIGNING <temp45>.
    sy-tabix = temp46.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp45>-sum = abap_true.


    temp48 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp47>-sort = z2ui5_cl_cgui_alv=>cs_sort-ascending.


    temp50 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp49>.
    sy-tabix = temp50.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp49>-sort_seq = 1.


    temp52 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp51>.
    sy-tabix = temp52.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp51>-subtotal = abap_true.


    ls_variant = z2ui5_cl_cgui_layout=>to_variant( name    = `MINE`
                                                         is_default = abap_true
                                                         layout     = lt_layout ).
    cl_abap_unit_assert=>assert_equals( act = ls_variant-name
                                        exp = `#L#MINE` ).


    CLEAR temp53.

    temp54-name = `SEL_VARIANT`.
    INSERT temp54 INTO TABLE temp53.
    INSERT ls_variant INTO TABLE temp53.

    lt_saved = z2ui5_cl_cgui_layout=>from_variants( temp53 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_saved )
                                        exp = 1 ).


    temp56 = sy-tabix.
    READ TABLE lt_saved INDEX 1 ASSIGNING <temp55>.
    sy-tabix = temp56.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp55>-name
                                        exp = `MINE` ).


    temp58 = sy-tabix.
    READ TABLE lt_saved INDEX 1 ASSIGNING <temp57>.
    sy-tabix = temp58.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp57>-is_default ).



    temp2 = sy-tabix.
    READ TABLE lt_saved INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lt_back = <temp1>-layout.


    temp60 = sy-tabix.
    READ TABLE lt_back WITH KEY name = `FLDATE` ASSIGNING <temp59>.
    sy-tabix = temp60.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp59>-hidden ).


    temp62 = sy-tabix.
    READ TABLE lt_back WITH KEY name = `PRICE` ASSIGNING <temp61>.
    sy-tabix = temp62.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp61>-sum ).


    temp64 = sy-tabix.
    READ TABLE lt_back WITH KEY name = `CARRID` ASSIGNING <temp63>.
    sy-tabix = temp64.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp63>-subtotal ).


    temp66 = sy-tabix.
    READ TABLE lt_back WITH KEY name = `CARRID` ASSIGNING <temp65>.
    sy-tabix = temp66.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp65>-sort
                                        exp = `ASC` ).

  ENDMETHOD.

  METHOD merge_unknown_columns_last.

    " the saved layout knows PRICE first and FLDATE - not CARRID
    DATA temp67 TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp68 LIKE LINE OF temp67.
    DATA lt_merged TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp69> LIKE LINE OF lt_merged.
    DATA temp70 LIKE sy-tabix.
    FIELD-SYMBOLS <temp71> LIKE LINE OF lt_merged.
    DATA temp72 LIKE sy-tabix.
    FIELD-SYMBOLS <temp73> LIKE LINE OF lt_merged.
    DATA temp74 LIKE sy-tabix.
    FIELD-SYMBOLS <temp75> LIKE LINE OF lt_merged.
    DATA temp76 LIKE sy-tabix.
    CLEAR temp67.

    CLEAR temp68.
    temp68-name = `PRICE`.
    temp68-position = 1.
    INSERT temp68 INTO TABLE temp67.
    CLEAR temp68.
    temp68-name = `FLDATE`.
    temp68-position = 2.
    temp68-hidden = abap_true.
    INSERT temp68 INTO TABLE temp67.

    lt_merged = z2ui5_cl_cgui_layout=>layout_merge(
        base  = mt_base
        saved = temp67 ).



    temp70 = sy-tabix.
    READ TABLE lt_merged INDEX 1 ASSIGNING <temp69>.
    sy-tabix = temp70.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp69>-name
                                        exp = `PRICE` ).


    temp72 = sy-tabix.
    READ TABLE lt_merged INDEX 3 ASSIGNING <temp71>.
    sy-tabix = temp72.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp71>-name
                                        exp = `CARRID` ).


    temp74 = sy-tabix.
    READ TABLE lt_merged INDEX 3 ASSIGNING <temp73>.
    sy-tabix = temp74.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp73>-text
                                        exp = `Airline` ).


    temp76 = sy-tabix.
    READ TABLE lt_merged INDEX 2 ASSIGNING <temp75>.
    sy-tabix = temp76.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp75>-hidden ).

  ENDMETHOD.

  METHOD move_and_apply.

    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_layout.
    DATA temp77 TYPE string_table.
    FIELD-SYMBOLS <temp79> LIKE LINE OF lo_popup->mt_row.
    DATA temp80 LIKE sy-tabix.
    DATA temp81 TYPE string_table.
    FIELD-SYMBOLS <temp83> LIKE LINE OF lo_popup->mt_row.
    DATA temp84 LIKE sy-tabix.
    DATA ls_result TYPE z2ui5_cl_cgui_layout=>ty_s_result.
    FIELD-SYMBOLS <temp85> LIKE LINE OF ls_result-layout.
    DATA temp86 LIKE sy-tabix.
    lo_popup = z2ui5_cl_cgui_layout=>factory( mt_base ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*selectedKey="{SORT}"*` ).


    CLEAR temp77.
    INSERT `PRICE` INTO TABLE temp77.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-up
         args  = temp77 ).


    temp80 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 2 ASSIGNING <temp79>.
    sy-tabix = temp80.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp79>-name
                                        exp = `PRICE` ).
    " the first row does not move up

    CLEAR temp81.
    INSERT `CARRID` INTO TABLE temp81.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-up
         args  = temp81 ).


    temp84 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 1 ASSIGNING <temp83>.
    sy-tabix = temp84.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp83>-name
                                        exp = `CARRID` ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-ok ).

    ls_result = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-action
                                        exp = z2ui5_cl_cgui_layout=>cs_action-apply ).


    temp86 = sy-tabix.
    READ TABLE ls_result-layout WITH KEY name = `PRICE` ASSIGNING <temp85>.
    sy-tabix = temp86.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp85>-position
                                        exp = 2 ).

  ENDMETHOD.

  METHOD save_and_load.

    DATA temp87 TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
    DATA temp88 LIKE LINE OF temp87.
    DATA temp3 TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp4 LIKE LINE OF temp3.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_layout.
    FIELD-SYMBOLS <temp89> LIKE LINE OF lo_popup->mt_row.
    DATA temp90 LIKE sy-tabix.
    FIELD-SYMBOLS <temp91> LIKE LINE OF lo_popup->mt_row.
    DATA temp92 LIKE sy-tabix.
    DATA ls_result TYPE z2ui5_cl_cgui_layout=>ty_s_result.
    FIELD-SYMBOLS <temp93> LIKE LINE OF lo_popup->mt_row.
    DATA temp94 LIKE sy-tabix.
    CLEAR temp87.

    temp88-name = `NARROW`.
    temp88-is_default = abap_true.

    CLEAR temp3.

    CLEAR temp4.
    temp4-name = `PRICE`.
    temp4-position = 1.
    INSERT temp4 INTO TABLE temp3.
    CLEAR temp4.
    temp4-name = `FLDATE`.
    temp4-position = 2.
    temp4-hidden = abap_true.
    INSERT temp4 INTO TABLE temp3.
    temp88-layout = temp3.
    INSERT temp88 INTO TABLE temp87.

    lo_popup = z2ui5_cl_cgui_layout=>factory(
        layout = mt_base
        saved  = temp87 ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*NARROW (Default)*` ).

    lo_popup->mv_selected = `NARROW`.
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-load ).


    temp90 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 1 ASSIGNING <temp89>.
    sy-tabix = temp90.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp89>-name
                                        exp = `PRICE` ).


    temp92 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 2 ASSIGNING <temp91>.
    sy-tabix = temp92.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp91>-visible ).
    cl_abap_unit_assert=>assert_equals( act = lo_popup->mv_name
                                        exp = `NARROW` ).

    " OK as it was loaded: applied, not saved again
    run( popup = lo_popup
         event = z2ui5_cl_cgui_layout=>cs_event-ok ).

    ls_result = lo_popup->result( ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-action
                                        exp = z2ui5_cl_cgui_layout=>cs_action-apply ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-name
                                        exp = `NARROW` ).

    " changed, it is saved under its name


    temp94 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 2 ASSIGNING <temp93>.
    sy-tabix = temp94.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp93>-visible = abap_true.
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
