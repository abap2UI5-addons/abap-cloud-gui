CLASS ltcl_app DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA mv_text   TYPE string.
    DATA mv_date   TYPE d.
    DATA mv_flag   TYPE abap_bool.
    DATA mv_rb_a   TYPE abap_bool.
    DATA mv_rb_b   TYPE abap_bool.
    DATA mv_hidden TYPE string.
    DATA mv_char   TYPE c LENGTH 3.
    DATA mv_char2  TYPE c LENGTH 3.
    TYPES temp1_6e95141e6c TYPE RANGE OF xsdboolean.
DATA mt_flag   TYPE temp1_6e95141e6c.
    TYPES temp2_6e95141e6c TYPE RANGE OF string.
DATA mt_text   TYPE temp2_6e95141e6c.
    DATA mv_carrid TYPE land1.

ENDCLASS.


" the client the selection screen talks to: a binding names the attribute,
" an event names the event - enough to read the rendered view
CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mo_app TYPE REF TO ltcl_app.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_app    TYPE REF TO ltcl_app.
    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS screen
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_selscreen.

    METHODS loop_at_screen FOR TESTING.
    METHODS modify_hides_field FOR TESTING.
    METHODS hidden_block_leaves_no_frame FOR TESTING.
    METHODS read_only_and_invisible FOR TESTING.
    METHODS obligatory_follows_screen FOR TESTING.
    METHODS value_state FOR TESTING.
    METHODS radio_group_user_command FOR TESTING.
    METHODS checkbox_user_command FOR TESTING.
    METHODS value_help_auto FOR TESTING.
    METHODS select_option_without_help FOR TESTING.
    METHODS preview FOR TESTING.
    METHODS listbox_values FOR TESTING.
    METHODS tabbed_block FOR TESTING.
    METHODS skip_and_uline FOR TESTING.
    METHODS range_inputs FOR TESTING.
    METHODS upper_case_flag FOR TESTING.
    METHODS blocks_groups_function_keys FOR TESTING.
    METHODS help_button FOR TESTING.
    METHODS high_value_help FOR TESTING.
    METHODS screen_attributes_r10 FOR TESTING.
    METHODS block_no_intervals_matchcode FOR TESTING.

ENDCLASS.


CLASS ltcl_app IMPLEMENTATION.

  METHOD z2ui5_if_app~main ##NEEDED.
  ENDMETHOD.

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
  METHOD z2ui5_if_client~get_app_prev.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_navigated.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~check_on_init.
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
  METHOD z2ui5_if_client~nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_event_arg.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_event.
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
  METHOD z2ui5_if_client~popup_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popup_display.
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

  METHOD z2ui5_if_client~get_app.

    result = mo_app.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    DATA temp1 TYPE string.
    IF t_arg IS NOT INITIAL.
      temp1 = |:{ concat_lines_of( table = t_arg sep = `,` ) }|.
    ELSEIF arg IS NOT INITIAL.
      temp1 = |:{ arg }|.
    ELSE.
      CLEAR temp1.
    ENDIF.
    result = |EVENT:{ val }{ temp1 }|.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    CREATE OBJECT mo_app.
    CREATE OBJECT mo_client.
    mo_client->mo_app = mo_app.

  ENDMETHOD.

  METHOD screen.

    result = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    result->block_begin( `Main`
        )->parameter( val        = mo_app->mv_text
                      text       = `Text`
                      obligatory = abap_true
                      modif_id   = `G1`
        )->parameter( val = mo_app->mv_date
                      text = `Date`
        )->comment( text     = `A comment`
                    modif_id = `G1`
        )->button( text  = `Press`
                   event = `PRESS`
        )->parameter( val        = mo_app->mv_hidden
                      no_display = abap_true
        )->block_end( ).

  ENDMETHOD.

  METHOD loop_at_screen.

    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_screen.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp2> LIKE LINE OF lt_screen.
    DATA temp3 LIKE sy-tabix.
    lt_screen = screen( )->loop_at_screen( ).

    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( lt_screen ) ).




    temp2 = sy-tabix.
    READ TABLE lt_screen INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_screen = <temp1>.
    cl_abap_unit_assert=>assert_equals( exp = `MV_TEXT`
                                        act = ls_screen-name ).
    cl_abap_unit_assert=>assert_equals( exp = `G1`
                                        act = ls_screen-group1 ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = ls_screen-active ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = ls_screen-input ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = ls_screen-required ).



    temp3 = sy-tabix.
    READ TABLE lt_screen INDEX 3 ASSIGNING <temp2>.
    sy-tabix = temp3.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `G1`
                                        act = <temp2>-group1 ).

  ENDMETHOD.

  METHOD modify_hides_field.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
    DATA lv_view TYPE string.
    lo_screen = screen( ).

    lt_screen = lo_screen->loop_at_screen( ).


    LOOP AT lt_screen INTO ls_screen WHERE group1 = `G1`.
      ls_screen-active = abap_false.
      lo_screen->modify_screen( ls_screen ).
    ENDLOOP.


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*{/MV_TEXT}*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*A comment*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*{/MV_DATE}*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*{/MV_HIDDEN}*` ).

  ENDMETHOD.

  METHOD hidden_block_leaves_no_frame.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->block_begin( `Visible`
        )->parameter( mo_app->mv_text
        )->block_end(
        )->block_begin( `Hidden`
        )->parameter( val      = mo_app->mv_date
                      modif_id = `X`
        )->block_end( ).


    lt_screen = lo_screen->loop_at_screen( ).

    LOOP AT lt_screen INTO ls_screen WHERE group1 = `X`.
      ls_screen-active = abap_false.
      lo_screen->modify_screen( ls_screen ).
    ENDLOOP.


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*Visible*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*Hidden*` ).

  ENDMETHOD.

  METHOD read_only_and_invisible.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_screen.
    DATA temp4 LIKE sy-tabix.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_text ).


    lt_screen = lo_screen->loop_at_screen( ).



    temp4 = sy-tabix.
    READ TABLE lt_screen INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_screen = <temp3>.
    ls_screen-input = abap_false.
    ls_screen-invisible = abap_true.
    lo_screen->modify_screen( ls_screen ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*editable="false"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*type="Password"*` ).

  ENDMETHOD.

  METHOD obligatory_follows_screen.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_screen.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp4> LIKE LINE OF lt_screen.
    DATA temp5 LIKE sy-tabix.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp6> LIKE LINE OF lt_field.
    DATA temp7 LIKE sy-tabix.
    FIELD-SYMBOLS <temp8> LIKE LINE OF lt_field.
    DATA temp9 LIKE sy-tabix.
    FIELD-SYMBOLS <temp10> LIKE LINE OF lt_field.
    DATA temp11 LIKE sy-tabix.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lt_field.
    DATA temp13 LIKE sy-tabix.
    lo_screen = screen( ).

    lt_screen = lo_screen->loop_at_screen( ).

    " the date becomes required, the text read-only



    temp6 = sy-tabix.
    READ TABLE lt_screen INDEX 2 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_screen = <temp5>.
    ls_screen-required = abap_true.
    lo_screen->modify_screen( ls_screen ).


    temp5 = sy-tabix.
    READ TABLE lt_screen INDEX 1 ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_screen = <temp4>.
    ls_screen-input = abap_false.
    lo_screen->modify_screen( ls_screen ).


    lt_field = lo_screen->get_fields( ).


    temp7 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_TEXT` ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = <temp6>-obligatory ).


    temp9 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_DATE` ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = <temp8>-obligatory ).


    temp11 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_TEXT` ASSIGNING <temp10>.
    sy-tabix = temp11.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = <temp10>-shown ).


    temp13 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_HIDDEN` ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = <temp12>-shown ).

  ENDMETHOD.

  METHOD value_state.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = screen( ).
    lo_screen->set_value_state( name = `mv_date`
                                text = `Date in the past` ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*valueState="Error"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*valueStateText="Date in the past"*` ).

  ENDMETHOD.

  METHOD radio_group_user_command.
    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    DATA lv_count TYPE i.

    mo_app->mv_rb_a = abap_true.

    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->radiobutton( val          = mo_app->mv_rb_a
                            group        = `G`
                            user_command = `MODE`
        )->radiobutton( val   = mo_app->mv_rb_b
                        group = `G` ).


    lv_view = lo_screen->stringify( ).
    " declared at A, it applies to the whole group - but only B, the button
    " not selected, raises it

    FIND ALL OCCURRENCES OF `select="EVENT:MODE"` IN lv_view MATCH COUNT lv_count.
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lv_count ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*{/MV_RB_B}" editable="true" select="EVENT:MODE"*` ).

    " AT SELECTION-SCREEN OUTPUT switched the group after the declaration:
    " the wiring follows the attributes, A raises it now
    mo_app->mv_rb_a = abap_false.
    mo_app->mv_rb_b = abap_true.
    lv_view = lo_screen->stringify( ).
    FIND ALL OCCURRENCES OF `select="EVENT:MODE"` IN lv_view MATCH COUNT lv_count.
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lv_count ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*{/MV_RB_A}" editable="true" select="EVENT:MODE"*` ).

  ENDMETHOD.

  METHOD checkbox_user_command.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->checkbox( val          = mo_app->mv_flag
                         user_command = `FLAG` ).

    cl_abap_unit_assert=>assert_char_cp( act = lo_screen->stringify( )
                                         exp = `*select="EVENT:FLAG"*` ).

  ENDMETHOD.

  METHOD value_help_auto.

    " XSDBOOLEAN has fixed values: F4 picks values, a button of its own
    " opens the range popup
    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( client          = mo_client
                                                        value_help_auto = abap_true ).
    lo_screen->select_option( mo_app->mt_flag ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*valueHelpRequest="EVENT:CGUI_VALUE_REQUEST:MT_FLAG"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*tooltip="Multiple selection" enabled="true" class="sapUiTinyMarginBegin" press="EVENT:CGUI_SELECT_OPTION:MT_FLAG"*` ).

  ENDMETHOD.

  METHOD select_option_without_help.

    " no fixed values - and without value_help_auto none are looked up
    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lo_plain TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( client          = mo_client
                                                        value_help_auto = abap_true ).
    lo_screen->select_option( mo_app->mt_text ).

    lo_plain = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_plain->select_option( mo_app->mt_flag ).


    lv_view = lo_screen->stringify( ) && lo_plain->stringify( ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*CGUI_VALUE_REQUEST*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*Multiple selection*` ).

  ENDMETHOD.

  METHOD preview.

    " no attribute, nothing bound - a flag shows its value
    DATA lv_flag TYPE abap_bool VALUE abap_true.
    DATA lv_text TYPE c LENGTH 10.
    TYPES temp3 TYPE RANGE OF i.
DATA lt_range TYPE temp3.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( client  = mo_client
                                                        preview = abap_true ).
    lo_screen->radiobutton( lv_flag
        )->parameter( val  = lv_text
                      text = `Local`
        )->select_option( val  = lt_range
                          text = `Range` ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<RadioButton*selected="true"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Label text="Range"*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*{/*` ).

  ENDMETHOD.

  METHOD listbox_values.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA temp14 TYPE z2ui5_cl_cgui_selscreen=>ty_t_value.
    DATA temp15 LIKE LINE OF temp14.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( val          = mo_app->mv_text
                          as_listbox   = abap_true
                          user_command = `PICK` ).

    CLEAR temp14.

    temp15-key = `A`.
    temp15-text = `Alpha`.
    INSERT temp15 INTO TABLE temp14.
    temp15-key = `B`.
    temp15-text = `Beta`.
    INSERT temp15 INTO TABLE temp14.
    lo_screen->set_listbox_values( name   = `MV_TEXT`
                                   values = temp14 ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Select*selectedKey="{/MV_TEXT}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*key="B" text="Beta"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*change="EVENT:PICK"*` ).

  ENDMETHOD.

  METHOD tabbed_block.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->tabbed_block_begin(
        )->tab( `First`
        )->parameter( mo_app->mv_text
        )->tab( `Second`
        )->parameter( mo_app->mv_date
        )->tabbed_block_end( ).
    lo_screen->set_tabbed_block_binding( index = 1
                                         bind  = `{/TAB}` ).

    cl_abap_unit_assert=>assert_equals( act = lo_screen->get_tabbed_block_count( )
                                        exp = 1 ).

    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<IconTabBar*selectedKey="{/TAB}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<IconTabFilter text="First" key="TAB1"*{/MV_TEXT}*<IconTabFilter text="Second" key="TAB2"*{/MV_DATE}*` ).
    " tabs are no fields of LOOP AT SCREEN
    cl_abap_unit_assert=>assert_equals( act = lines( lo_screen->loop_at_screen( ) )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD skip_and_uline.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_text
        )->skip( 2
        )->uline(
        )->parameter( mo_app->mv_date ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Toolbar height="1px" design="Solid"*` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_screen->loop_at_screen( ) )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD range_inputs.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->select_option( val          = mo_app->mt_text
                              no_extension = abap_true ).
    lo_screen->set_select_option_input( name      = `MT_TEXT`
                                        low_bind  = `{/SO/0/LOW}`
                                        high_bind = `{/SO/0/HIGH}` ).


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*value="{/SO/0/LOW}"*value="{/SO/0/HIGH}"*` ).
    " NO-EXTENSION: no button of the multiple selection
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*EVENT:CGUI_SELECT_OPTION*` ).

  ENDMETHOD.

  METHOD upper_case_flag.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp16> LIKE LINE OF lt_field.
    DATA temp17 LIKE sy-tabix.
    FIELD-SYMBOLS <temp18> LIKE LINE OF lt_field.
    DATA temp19 LIKE sy-tabix.
    FIELD-SYMBOLS <temp20> LIKE LINE OF lt_field.
    DATA temp21 LIKE sy-tabix.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_char
        )->parameter( val        = mo_app->mv_char2
                      lower_case = abap_true
        )->parameter( mo_app->mv_text ).


    lt_field = lo_screen->get_fields( ).


    temp17 = sy-tabix.
    READ TABLE lt_field INDEX 1 ASSIGNING <temp16>.
    sy-tabix = temp17.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp16>-upper ).


    temp19 = sy-tabix.
    READ TABLE lt_field INDEX 2 ASSIGNING <temp18>.
    sy-tabix = temp19.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp18>-upper ).
    " a string is never converted - only character fields


    temp21 = sy-tabix.
    READ TABLE lt_field INDEX 3 ASSIGNING <temp20>.
    sy-tabix = temp21.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp20>-upper ).

  ENDMETHOD.

  METHOD blocks_groups_function_keys.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp22> LIKE LINE OF lt_field.
    DATA temp23 LIKE sy-tabix.
    FIELD-SYMBOLS <temp24> LIKE LINE OF lt_field.
    DATA temp25 LIKE sy-tabix.
    FIELD-SYMBOLS <temp26> LIKE LINE OF lt_field.
    DATA temp27 LIKE sy-tabix.
    FIELD-SYMBOLS <temp28> LIKE LINE OF lt_field.
    DATA temp29 LIKE sy-tabix.
    DATA lt_key TYPE z2ui5_cl_cgui_selscreen=>ty_t_function_key.
    FIELD-SYMBOLS <temp30> LIKE LINE OF lt_key.
    DATA temp31 LIKE sy-tabix.
    FIELD-SYMBOLS <temp32> LIKE LINE OF lt_field.
    DATA temp33 LIKE sy-tabix.
    DATA temp34 TYPE string_table.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_field.
    DATA temp8 LIKE sy-tabix.
    FIELD-SYMBOLS <temp36> LIKE LINE OF lt_field.
    DATA temp37 LIKE sy-tabix.
    DATA temp38 TYPE string_table.
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_field.
    DATA temp10 LIKE sy-tabix.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->block_begin( title = `Selection`
                            name  = `b1`
        )->parameter( val         = mo_app->mv_char
                      value_check = abap_true
        )->block_end(
        )->radiobutton( val   = mo_app->mv_rb_a
                        group = `G1`
        )->function_key( number = 2
                         text   = `Refresh`
                         icon   = `sap-icon://refresh`
        )->function_key( number = 9
                         text   = `Ignored` ).


    lt_field = lo_screen->get_fields( ).


    temp23 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp22>-block
                                        exp = `B1` ).


    temp25 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp24>.
    sy-tabix = temp25.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp24>-value_check ).


    temp27 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_RB_A` ASSIGNING <temp26>.
    sy-tabix = temp27.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp26>-group
                                        exp = `G1` ).


    temp29 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_RB_A` ASSIGNING <temp28>.
    sy-tabix = temp29.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp28>-block ).


    lt_key = lo_screen->get_function_keys( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_key )
                                        exp = 1 ).


    temp31 = sy-tabix.
    READ TABLE lt_key INDEX 1 ASSIGNING <temp30>.
    sy-tabix = temp31.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp30>-ucomm
                                        exp = `FC02` ).

    " a block in a block: the field after the inner one is in the outer one
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->block_begin( title = `Outer`
                            name  = `B1`
        )->block_begin( title = `Inner`
                        name  = `B2`
        )->parameter( mo_app->mv_char
        )->block_end(
        )->parameter( mo_app->mv_char2
        )->block_end( ).
    lt_field = lo_screen->get_fields( ).


    temp33 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp32>.
    sy-tabix = temp33.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp32>-block
                                        exp = `B2` ).

    CLEAR temp34.
    INSERT `B1` INTO TABLE temp34.
    INSERT `B2` INTO TABLE temp34.


    temp8 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp7>-blocks
                                        exp = temp34 ).


    temp37 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR2` ASSIGNING <temp36>.
    sy-tabix = temp37.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp36>-block
                                        exp = `B1` ).

    CLEAR temp38.
    INSERT `B1` INTO TABLE temp38.


    temp10 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR2` ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp9>-blocks
                                        exp = temp38 ).

  ENDMETHOD.

  METHOD help_button.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp40> LIKE LINE OF lt_field.
    DATA temp41 LIKE sy-tabix.
    FIELD-SYMBOLS <temp42> LIKE LINE OF lt_field.
    DATA temp43 LIKE sy-tabix.
    DATA lv_view TYPE string.
    FIELD-SYMBOLS <temp44> LIKE LINE OF lt_field.
    DATA temp45 LIKE sy-tabix.
      DATA temp1 TYPE xsdboolean.
      DATA temp2 TYPE xsdboolean.
    DATA lo_own TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_own TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp46> LIKE LINE OF lt_own.
    DATA temp47 LIKE sy-tabix.
    DATA temp3 TYPE xsdboolean.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_carrid
        )->parameter( mo_app->mv_char ).


    lt_field = lo_screen->get_fields( ).


    temp41 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CARRID` ASSIGNING <temp40>.
    sy-tabix = temp41.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp40>-dtel
                                        exp = `LAND1` ).


    temp43 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp42>.
    sy-tabix = temp43.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp42>-help ).

    lv_view = lo_screen->stringify( ).


    temp45 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CARRID` ASSIGNING <temp44>.
    sy-tabix = temp45.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF <temp44>-help = abap_true.

      temp1 = boolc( lv_view CS `EVENT:CGUI_HELP_REQUEST` ).
      cl_abap_unit_assert=>assert_true( temp1 ).
    ELSE.

      temp2 = boolc( lv_view CS `EVENT:CGUI_HELP_REQUEST` ).
      cl_abap_unit_assert=>assert_false( temp2 ).
    ENDIF.

    " AT SELECTION-SCREEN ON HELP-REQUEST: the report answers F1 - the
    " button is there without documentation of the data element

    lo_own = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_own->parameter( val          = mo_app->mv_char
                       help_request = abap_true ).

    lt_own = lo_own->get_fields( ).


    temp47 = sy-tabix.
    READ TABLE lt_own WITH KEY name = `MV_CHAR` ASSIGNING <temp46>.
    sy-tabix = temp47.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp46>-help ).

    temp3 = boolc( lo_own->stringify( ) CS `EVENT:CGUI_HELP_REQUEST` ).
    cl_abap_unit_assert=>assert_true( temp3 ).

  ENDMETHOD.

  METHOD screen_attributes_r10.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF lt_screen.
    DATA lv_view TYPE string.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp48> LIKE LINE OF lt_field.
    DATA temp49 LIKE sy-tabix.
    lo_screen = screen( ).
    lo_screen->comment( text      = `Label of text`
                        for_field = `MV_TEXT` ).

    lt_screen = lo_screen->loop_at_screen( ).

    LOOP AT lt_screen INTO ls_screen WHERE name = `MV_DATE`.
      " SCREEN-REQUIRED = 2 and SCREEN-INTENSIFIED
      ls_screen-recommended = abap_true.
      ls_screen-intensified = abap_true.
      ls_screen-length      = 12.
      lo_screen->modify_screen( ls_screen ).
    ENDLOOP.


    lv_view = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*text="Date"*required="true"*design="Bold"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*Label of text*labelFor="cgui_f_mv_text"*` ).
    " recommended is no required field

    lt_field = lo_screen->get_fields( ).


    temp49 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_DATE` ASSIGNING <temp48>.
    sy-tabix = temp49.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp48>-obligatory ).

  ENDMETHOD.

  METHOD block_no_intervals_matchcode.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lt_field TYPE z2ui5_cl_cgui_selscreen=>ty_t_field.
    FIELD-SYMBOLS <temp50> LIKE LINE OF lt_field.
    DATA temp51 LIKE sy-tabix.
    FIELD-SYMBOLS <temp52> LIKE LINE OF lt_field.
    DATA temp53 LIKE sy-tabix.
    FIELD-SYMBOLS <temp54> LIKE LINE OF lt_field.
    DATA temp55 LIKE sy-tabix.
    FIELD-SYMBOLS <temp56> LIKE LINE OF lt_field.
    DATA temp57 LIKE sy-tabix.
    FIELD-SYMBOLS <temp58> LIKE LINE OF lt_field.
    DATA temp59 LIKE sy-tabix.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->block_begin( title        = `Single values`
                            no_intervals = abap_true
        )->select_option( val            = mo_app->mt_text
                          visible_length = 8
                          memory_id      = `ZTX`
        )->block_end(
        )->select_option( mo_app->mt_flag
        )->parameter( val       = mo_app->mv_char
                      matchcode = `h_t001` ).


    lt_field = lo_screen->get_fields( ).


    temp51 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MT_TEXT` ASSIGNING <temp50>.
    sy-tabix = temp51.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp50>-no_intervals ).


    temp53 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MT_TEXT` ASSIGNING <temp52>.
    sy-tabix = temp53.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp52>-memory_id
                                        exp = `ZTX` ).


    temp55 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MT_FLAG` ASSIGNING <temp54>.
    sy-tabix = temp55.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_false( <temp54>-no_intervals ).


    temp57 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp56>.
    sy-tabix = temp57.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp56>-matchcode
                                        exp = `H_T001` ).


    temp59 = sy-tabix.
    READ TABLE lt_field WITH KEY name = `MV_CHAR` ASSIGNING <temp58>.
    sy-tabix = temp59.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp58>-value_help ).

  ENDMETHOD.

  METHOD high_value_help.

    DATA lo_screen TYPE REF TO z2ui5_cl_cgui_selscreen.
    DATA lv_view TYPE string.
    DATA temp4 TYPE xsdboolean.
    DATA temp5 TYPE xsdboolean.
    lo_screen = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->select_option( val        = mo_app->mt_text
                              value_help = abap_true ).
    lo_screen->set_select_option_input( name      = `MT_TEXT`
                                        low_bind  = `{/SO/0/LOW}`
                                        high_bind = `{/SO/0/HIGH}` ).

    lv_view = lo_screen->stringify( ).
    " F4 on from and on to - the second names the part

    temp4 = boolc( lv_view CS `EVENT:CGUI_VALUE_REQUEST:MT_TEXT"` ).
    cl_abap_unit_assert=>assert_true( temp4 ).

    temp5 = boolc( lv_view CS `EVENT:CGUI_VALUE_REQUEST:MT_TEXT,HIGH` ).
    cl_abap_unit_assert=>assert_true( temp5 ).

  ENDMETHOD.

ENDCLASS.
