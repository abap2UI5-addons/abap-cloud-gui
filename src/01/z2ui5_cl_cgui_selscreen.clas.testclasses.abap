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
    DATA mt_flag   TYPE RANGE OF xsdboolean.
    DATA mt_text   TYPE RANGE OF string.
    DATA mv_carrid TYPE land1.

ENDCLASS.


" the client the selection screen talks to: a binding names the attribute,
" an event names the event - enough to read the rendered view
CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

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

  METHOD z2ui5_if_client~get_app.

    result = mo_app.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.

    result = |\{/{ z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                             val = val ) }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }{ COND #( WHEN t_arg IS NOT INITIAL THEN |:{ concat_lines_of( table = t_arg sep = `,` ) }| WHEN arg IS NOT INITIAL THEN |:{ arg }| ) }|.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_app = NEW #( ).
    mo_client = NEW #( ).
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

    DATA(lt_screen) = screen( )->loop_at_screen( ).

    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( lt_screen ) ).

    DATA(ls_screen) = lt_screen[ 1 ].
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

    cl_abap_unit_assert=>assert_equals( exp = `G1`
                                        act = lt_screen[ 3 ]-group1 ).

  ENDMETHOD.

  METHOD modify_hides_field.

    DATA(lo_screen) = screen( ).
    DATA(lt_screen) = lo_screen->loop_at_screen( ).

    LOOP AT lt_screen INTO DATA(ls_screen) WHERE group1 = `G1`.
      ls_screen-active = abap_false.
      lo_screen->modify_screen( ls_screen ).
    ENDLOOP.

    DATA(lv_view) = lo_screen->stringify( ).
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

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->block_begin( `Visible`
        )->parameter( mo_app->mv_text
        )->block_end(
        )->block_begin( `Hidden`
        )->parameter( val      = mo_app->mv_date
                      modif_id = `X`
        )->block_end( ).

    DATA(lt_screen) = lo_screen->loop_at_screen( ).
    LOOP AT lt_screen INTO DATA(ls_screen) WHERE group1 = `X`.
      ls_screen-active = abap_false.
      lo_screen->modify_screen( ls_screen ).
    ENDLOOP.

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*Visible*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*Hidden*` ).

  ENDMETHOD.

  METHOD read_only_and_invisible.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_text ).

    DATA(lt_screen) = lo_screen->loop_at_screen( ).
    DATA(ls_screen) = lt_screen[ 1 ].
    ls_screen-input = abap_false.
    ls_screen-invisible = abap_true.
    lo_screen->modify_screen( ls_screen ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*editable="false"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*type="Password"*` ).

  ENDMETHOD.

  METHOD obligatory_follows_screen.

    DATA(lo_screen) = screen( ).
    DATA(lt_screen) = lo_screen->loop_at_screen( ).

    " the date becomes required, the text read-only
    DATA(ls_screen) = lt_screen[ 2 ].
    ls_screen-required = abap_true.
    lo_screen->modify_screen( ls_screen ).
    ls_screen = lt_screen[ 1 ].
    ls_screen-input = abap_false.
    lo_screen->modify_screen( ls_screen ).

    DATA(lt_field) = lo_screen->get_fields( ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = lt_field[ name = `MV_TEXT` ]-obligatory ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = lt_field[ name = `MV_DATE` ]-obligatory ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = lt_field[ name = `MV_TEXT` ]-shown ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = lt_field[ name = `MV_HIDDEN` ]-shown ).

  ENDMETHOD.

  METHOD value_state.

    DATA(lo_screen) = screen( ).
    lo_screen->set_value_state( name = `mv_date`
                                text = `Date in the past` ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*valueState="Error"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*valueStateText="Date in the past"*` ).

  ENDMETHOD.

  METHOD radio_group_user_command.

    mo_app->mv_rb_a = abap_true.
    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->radiobutton( val          = mo_app->mv_rb_a
                            group        = `G`
                            user_command = `MODE`
        )->radiobutton( val   = mo_app->mv_rb_b
                        group = `G` ).

    DATA(lv_view) = lo_screen->stringify( ).
    " declared at A, it applies to the whole group - but only B, the button
    " not selected, raises it
    FIND ALL OCCURRENCES OF `select="EVENT:MODE"` IN lv_view MATCH COUNT DATA(lv_count).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lv_count ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*{/MV_RB_B}" editable="true" select="EVENT:MODE"*` ).

  ENDMETHOD.

  METHOD checkbox_user_command.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->checkbox( val          = mo_app->mv_flag
                         user_command = `FLAG` ).

    cl_abap_unit_assert=>assert_char_cp( act = lo_screen->stringify( )
                                         exp = `*select="EVENT:FLAG"*` ).

  ENDMETHOD.

  METHOD value_help_auto.

    " XSDBOOLEAN has fixed values: F4 picks values, a button of its own
    " opens the range popup
    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( client          = mo_client
                                                        value_help_auto = abap_true ).
    lo_screen->select_option( mo_app->mt_flag ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*valueHelpRequest="EVENT:CGUI_VALUE_REQUEST:MT_FLAG"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*tooltip="Multiple selection" enabled="true" class="sapUiTinyMarginBegin" press="EVENT:CGUI_SELECT_OPTION:MT_FLAG"*` ).

  ENDMETHOD.

  METHOD select_option_without_help.

    " no fixed values - and without value_help_auto none are looked up
    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( client          = mo_client
                                                        value_help_auto = abap_true ).
    lo_screen->select_option( mo_app->mt_text ).
    DATA(lo_plain) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_plain->select_option( mo_app->mt_flag ).

    DATA(lv_view) = lo_screen->stringify( ) && lo_plain->stringify( ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*CGUI_VALUE_REQUEST*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*Multiple selection*` ).

  ENDMETHOD.

  METHOD preview.

    " no attribute, nothing bound - a flag shows its value
    DATA lv_flag TYPE abap_bool VALUE abap_true.
    DATA lv_text TYPE c LENGTH 10.
    DATA lt_range TYPE RANGE OF i.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( client  = mo_client
                                                        preview = abap_true ).
    lo_screen->radiobutton( lv_flag
        )->parameter( val  = lv_text
                      text = `Local`
        )->select_option( val  = lt_range
                          text = `Range` ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<RadioButton*selected="true"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Label text="Range"*` ).
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*{/*` ).

  ENDMETHOD.

  METHOD listbox_values.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( val          = mo_app->mv_text
                          as_listbox   = abap_true
                          user_command = `PICK` ).
    lo_screen->set_listbox_values( name   = `MV_TEXT`
                                   values = VALUE #( ( key = `A` text = `Alpha` )
                                                     ( key = `B` text = `Beta` ) ) ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Select*selectedKey="{/MV_TEXT}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*key="B" text="Beta"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*change="EVENT:PICK"*` ).

  ENDMETHOD.

  METHOD tabbed_block.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
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
    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<IconTabBar*selectedKey="{/TAB}"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<IconTabFilter text="First" key="TAB1"*{/MV_TEXT}*<IconTabFilter text="Second" key="TAB2"*{/MV_DATE}*` ).
    " tabs are no fields of LOOP AT SCREEN
    cl_abap_unit_assert=>assert_equals( act = lines( lo_screen->loop_at_screen( ) )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD skip_and_uline.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_text
        )->skip( 2
        )->uline(
        )->parameter( mo_app->mv_date ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*<Toolbar height="1px" design="Solid"*` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_screen->loop_at_screen( ) )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD range_inputs.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->select_option( val          = mo_app->mt_text
                              no_extension = abap_true ).
    lo_screen->set_select_option_input( name      = `MT_TEXT`
                                        low_bind  = `{/SO/0/LOW}`
                                        high_bind = `{/SO/0/HIGH}` ).

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*value="{/SO/0/LOW}"*value="{/SO/0/HIGH}"*` ).
    " NO-EXTENSION: no button of the multiple selection
    cl_abap_unit_assert=>assert_char_np( act = lv_view
                                         exp = `*EVENT:CGUI_SELECT_OPTION*` ).

  ENDMETHOD.

  METHOD upper_case_flag.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_char
        )->parameter( val        = mo_app->mv_char2
                      lower_case = abap_true
        )->parameter( mo_app->mv_text ).

    DATA(lt_field) = lo_screen->get_fields( ).
    cl_abap_unit_assert=>assert_true( lt_field[ 1 ]-upper ).
    cl_abap_unit_assert=>assert_false( lt_field[ 2 ]-upper ).
    " a string is never converted - only character fields
    cl_abap_unit_assert=>assert_false( lt_field[ 3 ]-upper ).

  ENDMETHOD.

  METHOD blocks_groups_function_keys.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
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

    DATA(lt_field) = lo_screen->get_fields( ).
    cl_abap_unit_assert=>assert_equals( act = lt_field[ name = `MV_CHAR` ]-block
                                        exp = `B1` ).
    cl_abap_unit_assert=>assert_true( lt_field[ name = `MV_CHAR` ]-value_check ).
    cl_abap_unit_assert=>assert_equals( act = lt_field[ name = `MV_RB_A` ]-group
                                        exp = `G1` ).
    cl_abap_unit_assert=>assert_initial( lt_field[ name = `MV_RB_A` ]-block ).

    DATA(lt_key) = lo_screen->get_function_keys( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_key )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_key[ 1 ]-ucomm
                                        exp = `FC02` ).

  ENDMETHOD.

  METHOD help_button.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->parameter( mo_app->mv_carrid
        )->parameter( mo_app->mv_char ).

    DATA(lt_field) = lo_screen->get_fields( ).
    cl_abap_unit_assert=>assert_equals( act = lt_field[ name = `MV_CARRID` ]-dtel
                                        exp = `LAND1` ).
    cl_abap_unit_assert=>assert_false( lt_field[ name = `MV_CHAR` ]-help ).
    DATA(lv_view) = lo_screen->stringify( ).
    IF lt_field[ name = `MV_CARRID` ]-help = abap_true.
      cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_HELP_REQUEST` ) ).
    ELSE.
      cl_abap_unit_assert=>assert_false( xsdbool( lv_view CS `EVENT:CGUI_HELP_REQUEST` ) ).
    ENDIF.

    " AT SELECTION-SCREEN ON HELP-REQUEST: the report answers F1 - the
    " button is there without documentation of the data element
    DATA(lo_own) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_own->parameter( val          = mo_app->mv_char
                       help_request = abap_true ).
    DATA(lt_own) = lo_own->get_fields( ).
    cl_abap_unit_assert=>assert_true( lt_own[ name = `MV_CHAR` ]-help ).
    cl_abap_unit_assert=>assert_true( xsdbool( lo_own->stringify( ) CS `EVENT:CGUI_HELP_REQUEST` ) ).

  ENDMETHOD.

  METHOD screen_attributes_r10.

    DATA(lo_screen) = screen( ).
    lo_screen->comment( text      = `Label of text`
                        for_field = `MV_TEXT` ).
    DATA(lt_screen) = lo_screen->loop_at_screen( ).
    LOOP AT lt_screen INTO DATA(ls_screen) WHERE name = `MV_DATE`.
      " SCREEN-REQUIRED = 2 and SCREEN-INTENSIFIED
      ls_screen-recommended = abap_true.
      ls_screen-intensified = abap_true.
      ls_screen-length      = 12.
      lo_screen->modify_screen( ls_screen ).
    ENDLOOP.

    DATA(lv_view) = lo_screen->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*text="Date"*required="true"*design="Bold"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_view
                                         exp = `*Label of text*labelFor="cgui_f_mv_text"*` ).
    " recommended is no required field
    DATA(lt_field) = lo_screen->get_fields( ).
    cl_abap_unit_assert=>assert_false( lt_field[ name = `MV_DATE` ]-obligatory ).

  ENDMETHOD.

  METHOD block_no_intervals_matchcode.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->block_begin( title        = `Single values`
                            no_intervals = abap_true
        )->select_option( val            = mo_app->mt_text
                          visible_length = 8
                          memory_id      = `ZTX`
        )->block_end(
        )->select_option( mo_app->mt_flag
        )->parameter( val       = mo_app->mv_char
                      matchcode = `h_t001` ).

    DATA(lt_field) = lo_screen->get_fields( ).
    cl_abap_unit_assert=>assert_true( lt_field[ name = `MT_TEXT` ]-no_intervals ).
    cl_abap_unit_assert=>assert_equals( act = lt_field[ name = `MT_TEXT` ]-memory_id
                                        exp = `ZTX` ).
    cl_abap_unit_assert=>assert_false( lt_field[ name = `MT_FLAG` ]-no_intervals ).
    cl_abap_unit_assert=>assert_equals( act = lt_field[ name = `MV_CHAR` ]-matchcode
                                        exp = `H_T001` ).
    cl_abap_unit_assert=>assert_true( lt_field[ name = `MV_CHAR` ]-value_help ).

  ENDMETHOD.

  METHOD high_value_help.

    DATA(lo_screen) = z2ui5_cl_cgui_selscreen=>factory( mo_client ).
    lo_screen->select_option( val        = mo_app->mt_text
                              value_help = abap_true ).
    lo_screen->set_select_option_input( name      = `MT_TEXT`
                                        low_bind  = `{/SO/0/LOW}`
                                        high_bind = `{/SO/0/HIGH}` ).
    DATA(lv_view) = lo_screen->stringify( ).
    " F4 on from and on to - the second names the part
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_VALUE_REQUEST:MT_TEXT"` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_view CS `EVENT:CGUI_VALUE_REQUEST:MT_TEXT,HIGH` ) ).

  ENDMETHOD.

ENDCLASS.
