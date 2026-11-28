CLASS ltcl_test DEFINITION DEFERRED.
CLASS z2ui5_cl_cgui_report DEFINITION LOCAL FRIENDS ltcl_test.

" a variant store of a customer - in memory, plugged in with
" set_variant_store( ); it travels in the draft with the report
CLASS ltcl_variant_store DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_variants.
    DATA mt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
ENDCLASS.

" a layout store of a customer - in memory, plugged in with
" set_layout_store( ); the tests keep the default store, the table
" Z2UI5_T_18, out of the way with it
CLASS ltcl_layout_store DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_layouts.
    DATA mt_layout TYPE z2ui5_cl_cgui_layout=>ty_t_saved.
ENDCLASS.

CLASS ltcl_layout_store IMPLEMENTATION.
  METHOD z2ui5_if_cgui_layouts~load.
    result = mt_layout.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~save.
      DATA temp1 LIKE LINE OF mt_layout.
      DATA lr_layout LIKE REF TO temp1.
    IF layout-is_default = abap_true.


      LOOP AT mt_layout REFERENCE INTO lr_layout.
        lr_layout->is_default = abap_false.
      ENDLOOP.
    ENDIF.
    DELETE mt_layout WHERE name = layout-name.
    INSERT layout INTO TABLE mt_layout.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~delete.
    DELETE mt_layout WHERE name = name.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_layouts~check_sharing.
    result = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_variant_store IMPLEMENTATION.
  METHOD z2ui5_if_cgui_variants~load.
    result = mt_variant.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_variants~save.
    DELETE mt_variant WHERE name = variant-name.
    INSERT variant INTO TABLE mt_variant.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_variants~delete.
    DELETE mt_variant WHERE name = name.
  ENDMETHOD.

  METHOD z2ui5_if_cgui_variants~check_sharing.
    result = abap_false.
  ENDMETHOD.
ENDCLASS.

" a report as the tests drive it - every kind of field, a list or an ALV
CLASS ltcl_report DEFINITION INHERITING FROM z2ui5_cl_cgui_report FINAL.

  PUBLIC SECTION.
    TYPES ty_c4 TYPE c LENGTH 4.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_pick,
        value TYPE c LENGTH 4,
      END OF ty_s_pick.
    TYPES ty_t_pick TYPE STANDARD TABLE OF ty_s_pick WITH DEFAULT KEY.

    DATA p_carrid    TYPE c LENGTH 3.
    DATA p_text      TYPE c LENGTH 20.
    DATA p_hidden    TYPE c LENGTH 1.
    TYPES temp1_c962b04173 TYPE RANGE OF d.
DATA s_date      TYPE temp1_c962b04173.
    TYPES temp2_c962b04173 TYPE RANGE OF ty_c4.
DATA s_code      TYPE temp2_c962b04173.
    " NO-DISPLAY - a switch only SUBMIT sets
    TYPES temp3_c962b04173 TYPE RANGE OF ty_c4.
DATA s_hidden    TYPE temp3_c962b04173.
    DATA mt_row      TYPE ty_t_row.
    DATA mv_alv      TYPE abap_bool.
    " SET PF-STATUS in START-OF-SELECTION - the status of the list
    DATA mv_status   TYPE abap_bool.
    " START-OF-SELECTION writes nothing / asks first (POPUP_TO_CONFIRM, the
    " rest follows in at_user_command( 'ASK' ))
    DATA mv_empty    TYPE abap_bool.
    DATA mv_ask      TYPE abap_bool.
    " AT LINE-SELECTION: SET PF-STATUS, CALL SCREEN 100
    DATA mv_line_status TYPE abap_bool.
    DATA mv_line_dynpro TYPE abap_bool.
    " AT USER-COMMAND writes a list
    DATA mv_cmd_write TYPE abap_bool.
    DATA mv_starts   TYPE i.
    " a total of the runs - the classic report starts it at 100 every run
    DATA mv_total    TYPE i VALUE 100.
    DATA mv_inits    TYPE i.
    DATA mv_tree     TYPE abap_bool.

    DATA mv_end      TYPE abap_bool.
    DATA mv_secret   TYPE string.
    DATA mv_lsel_row TYPE i.
    DATA mv_ucomm    TYPE string.
    DATA p_check     TYPE xsdboolean.
    DATA mv_block    TYPE string.
    DATA mv_window   TYPE abap_bool.
    DATA mv_leave    TYPE abap_bool.
    DATA mv_dynpro   TYPE abap_bool.
    " call_screen( owner = ): the class whose dynpro 100 is called
    DATA mo_owner    TYPE REF TO ltcl_report.
    " a tabstrip on dynpro 0100: two tabs on one subscreen area
    DATA mv_tabs     TYPE abap_bool.
    DATA tabstr      TYPE z2ui5_cl_cgui_report=>ty_s_tabstrip.
    DATA mv_sub      TYPE c LENGTH 4.
    DATA mv_sub_text TYPE c LENGTH 10.
    " a table control on dynpro 0100: its lines, the work area of the loop
    DATA mv_tc       TYPE abap_bool.
    DATA tc          TYPE z2ui5_cl_cgui_report=>ty_s_tableview.
    DATA mt_seat     TYPE ty_t_row.
    DATA ms_seat     TYPE ty_s_row.
    DATA mv_seats    TYPE i.
    DATA mv_after    TYPE string.
    DATA mv_pai      TYPE string.
    " a text editor in the custom control area CC of screen 0100
    DATA mv_gui      TYPE abap_bool.
    DATA mo_edit     TYPE REF TO z2ui5_cl_cgui_textedit.
    DATA mv_note     TYPE string.
    " F1 in it: the line and position of the cursor
    DATA mv_f1       TYPE string.
    DATA mv_replace TYPE abap_bool.
    DATA mv_exit     TYPE string.
    DATA mv_exit_err TYPE abap_bool.
    DATA mv_then     TYPE string.
    " SPRO: may the user maintain the customizing parameters
    DATA mv_customizing TYPE abap_bool.
    " a field whose value help is an entity - the variant table stands in
    " for a CDS view entity
    DATA p_var TYPE c LENGTH 40.

    "! the callback of a popup with then = `ON_SURE`
    METHODS on_sure
      IMPORTING
        answer TYPE string.

    METHODS on_f1 FOR EVENT f1 OF z2ui5_cl_cgui_textedit
      IMPORTING
        sender.

  PROTECTED SECTION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS end_of_selection REDEFINITION.
    METHODS top_of_page REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_user_command REDEFINITION.
    METHODS at_roundtrip_start REDEFINITION.
    METHODS initialization REDEFINITION.
    METHODS at_selection_screen_on_block REDEFINITION.
    METHODS at_selection_screen_on REDEFINITION.
    METHODS end_of_page REDEFINITION.
    METHODS at_selection_screen_on_exit REDEFINITION.
    METHODS at_value_request REDEFINITION.
    METHODS at_alv_value_request REDEFINITION.
    METHODS at_tree_node REDEFINITION.
    METHODS dynpro_screen REDEFINITION.
    METHODS dynpro_pbo REDEFINITION.
    METHODS dynpro_pai REDEFINITION.
    METHODS after_call_screen REDEFINITION.
    METHODS authority_check_customizing REDEFINITION.
    METHODS selection_screen_dynnr REDEFINITION.

ENDCLASS.


CLASS ltcl_job DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_job.
    DATA mv_report TYPE string.
    DATA mt_values TYPE z2ui5_cl_cgui_variant=>ty_t_value.
ENDCLASS.

CLASS ltcl_job IMPLEMENTATION.
  METHOD z2ui5_if_cgui_job~schedule.
    CLEAR error.
    mv_report = report.
    mt_values = values.
    job = `4711`.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_catalog DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_catalog.
ENDCLASS.

CLASS ltcl_catalog IMPLEMENTATION.
  METHOD z2ui5_if_cgui_catalog~get.
    DATA temp2 TYPE z2ui5_if_cgui_catalog=>ty_t_transaction.
    DATA temp3 LIKE LINE OF temp2.
    CLEAR temp2.

    CLEAR temp3.
    temp3-code = `ZFLY`.
    temp3-report = `z2ui5_cl_cgui_sample_04`.
    temp3-text = `Flights`.
    temp3-variant = `MINE`.
    INSERT temp3 INTO TABLE temp2.
    CLEAR temp3.
    temp3-code = `ZGONE`.
    temp3-report = `ZCL_NOT_THERE`.
    temp3-text = `Gone`.
    INSERT temp3 INTO TABLE temp2.
    CLEAR temp3.
    temp3-code = `ZAIR`.
    temp3-report = `LTCL_REPORT`.
    temp3-text = `Airline`.
    temp3-semantic_object = `Airline`.
    temp3-action = `display`.
    INSERT temp3 INTO TABLE temp2.
    CLEAR temp3.
    temp3-code = `zlow`.
    temp3-report = `z2ui5_cl_cgui_sample_04`.
    temp3-text = `Lower case`.
    INSERT temp3 INTO TABLE temp2.
    result = temp2.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client .

    DATA mo_app       TYPE REF TO object.
    DATA mv_init      TYPE abap_bool.
    DATA mv_navigated TYPE abap_bool.
    DATA mv_event     TYPE string.
    DATA mt_arg       TYPE string_table.
    DATA ms_get       TYPE z2ui5_if_client=>ty_s_get.
    DATA mv_view      TYPE string.
    DATA mv_popup     TYPE string.
    DATA mt_action    TYPE string_table.
    DATA mo_called    TYPE REF TO z2ui5_if_app.
    DATA mo_prev      TYPE REF TO z2ui5_if_app.
    DATA mv_left      TYPE abap_bool.
    DATA mv_box       TYPE string.
    DATA mv_box_type  TYPE string.
    " window_bind_tab( ): the window asked for
    DATA mv_window TYPE i.

    " the name of the public attribute val is - or, as the framework's model
    " dissolves a reference, the attribute whose REF TO data points at val
    METHODS attri_name
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_report TYPE REF TO ltcl_report.
    DATA mo_cut    TYPE REF TO z2ui5_cl_cgui_report.
    DATA mo_client TYPE REF TO ltcl_client.

    METHODS setup.

    METHODS init.

    METHODS event
      IMPORTING
        name TYPE string
        args TYPE string_table OPTIONAL.

    METHODS obligatory_stops_run FOR TESTING.
    METHODS execute_shows_list FOR TESTING.
    METHODS upper_and_lower_case FOR TESTING.
    METHODS select_option_buffer FOR TESTING.
    METHODS select_option_complex FOR TESTING.
    METHODS secondary_list_and_back FOR TESTING.
    METHODS line_selection_calls_screen FOR TESTING.
    METHODS user_command_secondary_list FOR TESTING.
    METHODS empty_list_restarts FOR TESTING.
    METHODS screen_as_window_checks FOR TESTING.
    METHODS salv_sorts_and_totals FOR TESTING.
    METHODS controls_released FOR TESTING.
    METHODS popup_in_the_run FOR TESTING.
    METHODS leave_during_the_run FOR TESTING.
    METHODS file_upload_and_download FOR TESTING.
    METHODS current_screen_afresh FOR TESTING.
    METHODS dynpro_call_and_leave FOR TESTING.
    METHODS dynpro_of_another_class FOR TESTING.
    METHODS dynpro_text_editor FOR TESTING.
    METHODS dynpro_tabstrip FOR TESTING.
    METHODS dynpro_table_control FOR TESTING.
    METHODS alv_box_copy_selection FOR TESTING.
    METHODS url_values_screen_only FOR TESTING.
    METHODS url_skip_screen FOR TESTING.
    METHODS url_range FOR TESTING.
    METHODS variant_screen_only FOR TESTING.
    METHODS variant_names_refused FOR TESTING.
    METHODS events_screen_only FOR TESTING.
    METHODS submit_starts_report FOR TESTING.
    METHODS link_holds_values FOR TESTING.
    METHODS parameter_id FOR TESTING.
    METHODS shortcuts_registered FOR TESTING.
    METHODS f8_on_output_ignored FOR TESTING.
    METHODS run_in_background FOR TESTING.
    METHODS range_popup_keeps_exclude FOR TESTING.
    METHODS range_f4_returns_to_popup FOR TESTING.
    METHODS f4_keeps_other_lines FOR TESTING.
    METHODS popups_of_the_project FOR TESTING.
    METHODS short_api FOR TESTING.
    METHODS messages_after_popup FOR TESTING.
    METHODS input_history FOR TESTING.
    METHODS execute_in_background FOR TESTING.
    METHODS command_field FOR TESTING.
    METHODS user_parameters FOR TESTING.
    METHODS parameter_levels FOR TESTING.
    METHODS value_help_entity FOR TESTING.
    METHODS submit_using_screen FOR TESTING.
    METHODS draft FOR TESTING.
    METHODS application_log FOR TESTING.
    METHODS alv_chart FOR TESTING.
    METHODS transport_popup FOR TESTING.
    METHODS popup_then FOR TESTING.
    METHODS popup_decide_list FOR TESTING.
    METHODS call_transaction FOR TESTING.
    METHODS call_intent FOR TESTING.
    METHODS read_list_clicked FOR TESTING.
    METHODS roundtrip_start FOR TESTING.
    METHODS fresh_start FOR TESTING.
    METHODS popup_values_of_an_sval FOR TESTING.
    METHODS alv_layout_default FOR TESTING.
    METHODS alv_layout_without_store FOR TESTING.

    METHODS value_check_and_block FOR TESTING.
    METHODS footer_print_function_key FOR TESTING.
    METHODS alv_paging_maps_rows FOR TESTING.
    METHODS alv_paging_filtered_maps_rows FOR TESTING.
    METHODS alv_filter_by_popup FOR TESTING.
    METHODS window_shows_dialog FOR TESTING.
    METHODS exit_command FOR TESTING.
    METHODS write_takes_format FOR TESTING.
    METHODS cursor_and_lisel FOR TESTING.
    METHODS selscreen_status_and_cursor FOR TESTING.
    METHODS alv_search_and_details FOR TESTING.
    METHODS f4_on_high FOR TESTING.
    METHODS f4_in_alv_cell FOR TESTING.
    METHODS tree_expand_and_node FOR TESTING.
    METHODS draft_serializable FOR TESTING.
    METHODS draft_references FOR TESTING.
    METHODS demo_output_into_list FOR TESTING.
    METHODS serialize
      IMPORTING
        step TYPE string.

    " an app through the draft of abap2UI5 and back
    METHODS roundtrip
      IMPORTING
        app           TYPE REF TO z2ui5_if_app
        step          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_if_app.

    "! the select popup the report opened, left with the row at index
    METHODS select_popup_pick
      IMPORTING
        index TYPE i.

    TYPES:
      BEGIN OF ty_s_pick,
        value TYPE c LENGTH 4,
      END OF ty_s_pick.
    TYPES ty_t_pick TYPE STANDARD TABLE OF ty_s_pick WITH DEFAULT KEY.

    "! the multiple selection the report opened, left with event
    METHODS range_popup_leave
      IMPORTING
        event         TYPE string
        args          TYPE string_table OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_range.

ENDCLASS.


CLASS ltcl_report IMPLEMENTATION.

  METHOD selection_screen.

    screen->block_begin( title = `Airline`
                         name  = `B1`
        )->parameter( val        = p_carrid
                      text       = `Airline`
                      obligatory = abap_true
        )->block_end(
        )->parameter( val         = p_check
                      text        = `Check`
                      value_check = abap_true
        )->function_key( number = 1
                         text   = `Refresh`
        )->parameter( val        = p_text
                      text       = `Text`
                      lower_case = abap_true
        )->parameter( val        = p_hidden
                      no_display = abap_true
        )->select_option( val  = s_date
                          text = `Date`
        )->select_option( val  = s_code
                          text = `Code`
        )->select_option( val        = s_hidden
                          no_display = abap_true
        )->parameter( val                = p_var
                      text               = `Report of a variant`
                      value_help_entity  = `Z2UI5_T_19`
                      value_help_element = `REPORT` ).

  ENDMETHOD.

  METHOD dynpro_screen.
      DATA temp4 TYPE z2ui5_if_cgui_gui=>ty_t_tc_column.
      DATA temp5 LIKE LINE OF temp4.

    IF mv_tc = abap_true.

      CLEAR temp4.

      CLEAR temp5.
      temp5-text = `Airline`.
      INSERT temp5 INTO TABLE temp4.
      CLEAR temp5.
      temp5-text = `Seats`.
      temp5-input = abap_true.
      temp5-width = 5.
      INSERT temp5 INTO TABLE temp4.
      screen->table_control( name    = 'TC'
                             title   = `Seats`
                             columns = temp4 ).
      RETURN.
    ENDIF.
    IF mv_tabs = abap_true.
      CASE dynnr.
        WHEN `0100`.
          screen->tabbed_block_begin( 'TABSTR'
              )->tab( text  = `One`
                      fcode = 'TAB1'
                      area  = 'SUB'
              )->tab( text  = `Two`
                      fcode = 'TAB2'
                      area  = 'SUB'
              )->subscreen( 'SUB'
              )->tabbed_block_end( ).
        WHEN `0110`.
          screen->parameter( val  = mv_sub_text
                             text = `First` ).
        WHEN `0120`.
          screen->comment( `Second tab` ).
      ENDCASE.
      RETURN.
    ENDIF.
    IF dynnr = `0100` AND mv_gui = abap_true.
      screen->custom_control( 'CC' ).
      RETURN.
    ENDIF.
    IF dynnr = `0100`.
      screen->parameter( val       = p_carrid
                         text      = `Airline`
                         read_only = abap_true
          )->parameter( val        = mv_seats
                        text       = `Seats`
                        obligatory = abap_true
                        modif_id   = `SEA`
          )->button( text  = `Check`
                     event = `CHECK` ).
    ENDIF.

  ENDMETHOD.

  METHOD dynpro_pbo.
      DATA temp1 TYPE REF TO z2ui5_cl_cgui_container.
      DATA temp6 TYPE z2ui5_cl_cgui_gui=>ty_t_simple_events.
      DATA temp7 LIKE LINE OF temp6.
    DATA temp8 TYPE z2ui5_cl_cgui_alv=>ty_t_function.
    DATA temp9 LIKE LINE OF temp8.
    DATA temp10 TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA ls_screen LIKE LINE OF temp10.
        FIELD-SYMBOLS <temp11> LIKE LINE OF mt_seat.
        DATA temp12 LIKE sy-tabix.
        DATA temp13 TYPE string_table.
        DATA temp2 LIKE LINE OF temp13.
        DATA temp3 LIKE LINE OF temp13.

    " the classic PBO: the control once, in the container of the area
    IF mv_gui = abap_true AND mo_edit IS NOT BOUND.

      CREATE OBJECT temp1 TYPE z2ui5_cl_cgui_container EXPORTING container_name = 'CC'.
      CREATE OBJECT mo_edit EXPORTING parent = temp1.
      mo_edit->set_textstream( `first note` ).

      CLEAR temp6.

      temp7-eventid = z2ui5_cl_cgui_textedit=>event_f1.
      INSERT temp7 INTO TABLE temp6.
      mo_edit->set_registered_events( temp6 ).
      mo_edit->set_handler( event   = `F1`
                            method  = `ON_F1`
                            handler = me ).
    ENDIF.

    CLEAR temp8.

    temp9-name = `SAVE`.
    temp9-text = `Save`.
    INSERT temp9 INTO TABLE temp8.
    set_pf_status( temp8 ).

    temp10 = current_screen( )->loop_at_screen( ).

    LOOP AT temp10 INTO ls_screen WHERE group1 = `SEA`.
      ls_screen-intensified = abap_true.
      current_screen( )->modify_screen( ls_screen ).
    ENDLOOP.
    mv_pai = |{ mv_pai }PBO{ dynnr };|.
    " the classic PBO of a table control: a line of it at a time
    IF mv_tc = abap_true.
      tablecontrol_begin( 'TC' ).
      tc-lines = lines( mt_seat ).
      DO tc-lines TIMES.
        tc-current_line = sy-index.


        temp12 = sy-tabix.
        READ TABLE mt_seat INDEX tc-current_line ASSIGNING <temp11>.
        sy-tabix = temp12.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ms_seat = <temp11>.

        CLEAR temp13.

        temp2 = ms_seat-carrid.
        INSERT temp2 INTO TABLE temp13.

        temp3 = |{ ms_seat-seats }|.
        INSERT temp3 INTO TABLE temp13.
        tablecontrol_row( name   = 'TC'
                          values = temp13 ).
      ENDDO.
    ENDIF.
    " the classic PBO of a tabstrip: the tab and its subscreen
    IF mv_tabs = abap_true AND dynnr = `0100`.
      IF tabstr-activetab IS INITIAL.
        tabstr-activetab = 'TAB1'.
        mv_sub = '0110'.
      ENDIF.
      call_subscreen( area  = 'SUB'
                      dynnr = mv_sub ).
    ENDIF.

  ENDMETHOD.

  METHOD on_f1.

    DATA lv_line TYPE i.
    DATA lv_pos TYPE i.

    sender->get_selection_pos( IMPORTING from_line = lv_line
                                         from_pos  = lv_pos ).
    mv_f1 = |{ lv_line }:{ lv_pos }|.

  ENDMETHOD.

  METHOD dynpro_pai.
        FIELD-SYMBOLS <temp15> LIKE LINE OF mt_seat.
        DATA temp16 LIKE sy-tabix.

    IF mo_edit IS BOUND.
      mo_edit->get_textstream( IMPORTING text = mv_note ).
    ENDIF.
    mv_pai = |{ mv_pai }PAI{ dynnr }:{ ucomm };|.
    " the classic PAI of a table control: its line into the work area,
    " MODIFY at current_line
    IF mv_tc = abap_true.
      DO tablecontrol_count( 'TC' ) TIMES.
        tc-current_line = sy-index.


        temp16 = sy-tabix.
        READ TABLE mt_seat INDEX tc-current_line ASSIGNING <temp15>.
        sy-tabix = temp16.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ms_seat = <temp15>.
        ms_seat-seats = tablecontrol_cell( name = 'TC'
                                           row  = sy-index
                                           col  = 2 ).
        MODIFY mt_seat FROM ms_seat INDEX tc-current_line.
      ENDDO.
      RETURN.
    ENDIF.
    IF mv_tabs = abap_true AND dynnr = `0100`.
      call_subscreen_pai( area  = 'SUB'
                          ucomm = ucomm ).
      CASE ucomm.
        WHEN `TAB1`.
          tabstr-activetab = ucomm.
          mv_sub = '0110'.
        WHEN `TAB2`.
          tabstr-activetab = ucomm.
          mv_sub = '0120'.
      ENDCASE.
      RETURN.
    ENDIF.
    CASE ucomm.
      WHEN `SAVE`.
        leave_to_screen( `0` ).
      WHEN `NEXT`.
        set_screen( `0200` ).
      WHEN `BACK`.
        leave_to_screen( `0` ).
    ENDCASE.

  ENDMETHOD.

  METHOD after_call_screen.

    mv_after = dynnr.
    " the dynpro of another class: its fields as it left them
    IF mo_owner IS BOUND.
      mv_seats = mo_owner->mv_seats.
    ENDIF.
    list( )->new_line(
        )->write( |Seats { mv_seats }| ).

  ENDMETHOD.

  METHOD start_of_selection.
      DATA temp17 TYPE z2ui5_cl_cgui_alv=>ty_t_function.
      DATA temp18 LIKE LINE OF temp17.
      DATA temp4 TYPE z2ui5_cl_cgui_report=>ty_t_shortcut.
      DATA temp5 LIKE LINE OF temp4.
      DATA temp1 TYPE string_table.
      DATA lo_tree TYPE REF TO z2ui5_cl_cgui_tree.
      DATA temp19 TYPE ty_s_row.
      DATA lv_lh TYPE i.
      DATA temp20 TYPE ty_s_row.
      DATA temp21 TYPE ltcl_report=>ty_t_row.
      DATA temp22 LIKE LINE OF temp21.

    mv_total = mv_total + 1.

    IF mv_status = abap_true.

      CLEAR temp17.

      temp18-name = `SAVE`.
      temp18-text = `Save`.
      INSERT temp18 INTO TABLE temp17.
      temp18-name = `DELE`.
      temp18-text = `Delete`.
      INSERT temp18 INTO TABLE temp17.

      CLEAR temp4.

      temp5-key = `F5`.
      temp5-ucomm = `SAVE`.
      INSERT temp5 INTO TABLE temp4.
      temp5-key = `Shift+F2`.
      temp5-ucomm = `DELE`.
      INSERT temp5 INTO TABLE temp4.

      CLEAR temp1.
      INSERT `dele` INTO TABLE temp1.
      set_pf_status( functions = temp17
                     shortcuts = temp4
                     excluding = temp1 ).
    ENDIF.

    " CALL SCREEN - the rest comes in after_call_screen( )
    IF mo_owner IS BOUND.
      mo_owner->p_carrid = p_carrid.
      call_screen( dynnr = `100`
                   owner = mo_owner ).
      RETURN.
    ENDIF.
    IF mv_dynpro = abap_true.
      call_screen( `100` ).
      RETURN.
    ENDIF.

    IF mv_ask = abap_true.
      popup_to_confirm( question = `Go on?`
                        ucomm    = `ASK` ).
      RETURN.
    ENDIF.
    IF mv_empty = abap_true.
      RETURN.
    ENDIF.

    " LEAVE PROGRAM after a message - back on the selection screen
    IF mv_leave = abap_true.
      message( `Unknown airline` ).
      leave_to_selection_screen( ).
      RETURN.
    ENDIF.

    IF mv_tree = abap_true.

      lo_tree = tree( ).

      CLEAR temp19.
      temp19-carrid = `LH`.
      temp19-seats = 3.

      lv_lh = lo_tree->add_node( text  = `LH`
                                       data  = temp19
                                       value = `LH` ).

      CLEAR temp20.
      temp20-carrid = `LH`.
      temp20-seats = 1.
      lo_tree->add_node( parent = lv_lh
                         text   = `0400`
                         data   = temp20
                         value  = `LH-0400` ).
      RETURN.
    ENDIF.

    IF mv_alv = abap_true.

      CLEAR temp21.

      temp22-carrid = `LH`.
      temp22-seats = 1.
      INSERT temp22 INTO TABLE temp21.
      temp22-carrid = `AA`.
      temp22-seats = 2.
      INSERT temp22 INTO TABLE temp21.
      temp22-carrid = `UA`.
      temp22-seats = 3.
      INSERT temp22 INTO TABLE temp21.
      mt_row = temp21.
      alv( mt_row )->set_selection_mode( ).
      RETURN.
    ENDIF.

    write( val     = `row1`
           hotspot = abap_true
           hide    = `H1` )->new_line( ).

  ENDMETHOD.

  METHOD end_of_selection.

    mv_end = abap_true.

  ENDMETHOD.

  METHOD top_of_page.

    write( `HEADER` ).

  ENDMETHOD.

  METHOD at_line_selection.
      DATA temp23 TYPE z2ui5_cl_cgui_alv=>ty_t_function.
      DATA temp24 LIKE LINE OF temp23.

    mv_lsel_row = row.
    IF mv_line_status = abap_true.

      CLEAR temp23.

      temp24-name = `DETAIL`.
      temp24-text = `Detail`.
      INSERT temp24 INTO TABLE temp23.
      set_pf_status( temp23 ).
    ENDIF.
    IF mv_line_dynpro = abap_true.
      call_screen( `100` ).
      RETURN.
    ENDIF.
    " sy-lsind = sy-lsind - 1: the detail replaces the list it comes from
    IF mv_replace = abap_true.
      set_lsind( lsind( ) - 1 ).
    ENDIF.
    IF mv_window = abap_true.
      window( title   = `Detail`
              columns = 50
              lines   = 10 ).
    ENDIF.
    write( |Detail { hide }| ).

  ENDMETHOD.

  METHOD on_sure.

    mv_then = |{ mv_then }{ answer }|.

  ENDMETHOD.

  METHOD at_user_command.

    mv_ucomm = ucomm.
    " the rest of START-OF-SELECTION after the popup
    IF ucomm = `ASK`.
      write( `Answered` ).
      RETURN.
    ENDIF.
    IF mv_cmd_write = abap_true.
      " sy-lsind = sy-lsind - 1: the list written replaces the one shown
      IF mv_replace = abap_true.
        set_lsind( lsind( ) - 1 ).
      ENDIF.
      write( |Command { ucomm }| ).
    ENDIF.

  ENDMETHOD.

  METHOD initialization.

    mv_inits = mv_inits + 1.

  ENDMETHOD.

  METHOD authority_check_customizing.

    result = mv_customizing.

  ENDMETHOD.

  METHOD selection_screen_dynnr.

    " SELECTION-SCREEN BEGIN OF SCREEN 1100 - one field of its own
    IF dynnr = `1100`.
      screen->parameter( val  = p_text
                         text = `Note on 1100` ).
    ENDIF.

  ENDMETHOD.

  METHOD at_roundtrip_start.

    mv_starts = mv_starts + 1.

  ENDMETHOD.

  METHOD at_tree_node.

    write( |Node { value } { key }| ).

  ENDMETHOD.

  METHOD at_value_request.

    TYPES:
      BEGIN OF ty_s_file,
        filename TYPE c LENGTH 1024,
      END OF ty_s_file.
    TYPES temp4 TYPE STANDARD TABLE OF ty_s_file WITH DEFAULT KEY.
DATA lt_file   TYPE temp4.
    DATA lv_rc     TYPE i.
    DATA lv_action TYPE i.
        FIELD-SYMBOLS <temp25> LIKE LINE OF lt_file.
        DATA temp26 LIKE sy-tabix.
      DATA temp27 TYPE ty_t_pick.
      DATA temp28 LIKE LINE OF temp27.

    " F4 on the text - the file dialog of SAP GUI, converted
    IF field = `P_TEXT`.
      z2ui5_cl_cgui_frontend=>file_open_dialog( EXPORTING  file_filter = `Text (*.txt)|*.txt|`
                                                CHANGING   file_table  = lt_file
                                                           rc          = lv_rc
                                                           user_action = lv_action
                                                EXCEPTIONS OTHERS      = 1 ).
      IF sy-subrc = 0 AND lv_action = z2ui5_cl_cgui_frontend=>action_ok AND lv_rc = 1.


        temp26 = sy-tabix.
        READ TABLE lt_file INDEX 1 ASSIGNING <temp25>.
        sy-tabix = temp26.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        p_text = <temp25>-filename.
      ENDIF.
      RETURN.
    ENDIF.

    " F4 on the upper limit of the code - a hit list of its own
    IF field = `S_CODE` AND value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high.

      CLEAR temp27.

      temp28-value = `ZZ`.
      INSERT temp28 INTO TABLE temp27.
      value_help_popup( tab = temp27
                        col = `VALUE` ).
      RETURN.
    ENDIF.
    super->at_value_request( field ).

  ENDMETHOD.

  METHOD at_alv_value_request.
      DATA temp29 TYPE ty_t_pick.
      DATA temp30 LIKE LINE OF temp29.

    IF column = `CARRID`.

      CLEAR temp29.

      temp30-value = `QF`.
      INSERT temp30 INTO TABLE temp29.
      temp30-value = `SQ`.
      INSERT temp30 INTO TABLE temp29.
      value_help_popup( tab = temp29
                        col = `VALUE` ).
      RETURN.
    ENDIF.
    super->at_alv_value_request( row    = row
                                 column = column ).

  ENDMETHOD.

  METHOD at_selection_screen_on_exit.

    mv_exit = ucomm.
    IF mv_exit_err = abap_true.
      message( text = `Not now`
               type = `E` ).
    ENDIF.

  ENDMETHOD.

  METHOD at_selection_screen_on.

    IF field = `P_TEXT` AND p_text = `BAD`.
      message( text  = `Not this text`
               type  = `E`
               field = field ).
    ENDIF.

  ENDMETHOD.

  METHOD at_selection_screen_on_block.

    mv_block = block.

  ENDMETHOD.

  METHOD end_of_page.

    write( |FOOT { z2ui5_cl_cgui_list=>cv_page }| ).

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
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_path.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_client.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~get_start_param.
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
  METHOD z2ui5_if_client~view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_init.

    result = mv_init.

  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_navigated.

    result = mv_navigated.

  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_event.

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( mv_init = abap_false AND mv_navigated = abap_false ).
    result = temp1.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event.

    result = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_event_arg.

    READ TABLE mt_arg INTO result INDEX v.

  ENDMETHOD.

  METHOD z2ui5_if_client~get.

    result = ms_get.
    result-event = mv_event.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app.

    result ?= mo_app.

  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev.

    result = mo_prev.

  ENDMETHOD.

  METHOD attri_name.

    DATA lr_val   TYPE REF TO data.
    DATA lr_attri TYPE REF TO data.
    FIELD-SYMBOLS <ref>   TYPE REF TO data.
    FIELD-SYMBOLS <attri> TYPE any.
    DATA temp31 TYPE REF TO cl_abap_classdescr.
    DATA lo_class LIKE temp31.
    DATA temp32 LIKE LINE OF lo_class->attributes.
    DATA lr_descr LIKE REF TO temp32.

    result = z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                       val = val ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    GET REFERENCE OF val INTO lr_val.

    temp31 ?= cl_abap_typedescr=>describe_by_object_ref( mo_app ).

    lo_class = temp31.


    LOOP AT lo_class->attributes REFERENCE INTO lr_descr
         WHERE visibility = cl_abap_classdescr=>public
           AND is_constant = abap_false
           AND type_kind = cl_abap_typedescr=>typekind_dref.
      UNASSIGN <ref>.
      ASSIGN mo_app->(lr_descr->name) TO <ref>.
      IF <ref> IS NOT ASSIGNED OR <ref> IS NOT BOUND.
        CONTINUE.
      ENDIF.
      ASSIGN <ref>->* TO <attri>.
      GET REFERENCE OF <attri> INTO lr_attri.
      IF lr_attri = lr_val.
        result = lr_descr->name.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD z2ui5_if_client~window_bind_tab.

    mv_window = window.
    result = z2ui5_if_client~_bind( val ).

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.
      DATA lv_tab TYPE string.
      DATA temp2 TYPE xsdboolean.
      FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
      FIELD-SYMBOLS <row> TYPE any.
      DATA lr_val TYPE REF TO data.
      DATA lr_cell TYPE REF TO data.
      DATA temp33 TYPE REF TO cl_abap_structdescr.
      DATA lo_struct LIKE temp33.
      DATA temp34 LIKE LINE OF lo_struct->components.
      DATA lr_comp LIKE REF TO temp34.
        FIELD-SYMBOLS <cell> TYPE any.
    DATA lv_attri TYPE string.

    " the framework finds a binding by the reference of the value: a public
    " attribute of the app, or a component of the row tab_index of such a
    " table. A copy of the row binds nothing - BINDING_ERROR_TAB_CELL_LEVEL
    " on the real client, so the double fails the same way, in the unit test
    " instead of the runtime job
    IF tab IS SUPPLIED.

      lv_tab = attri_name( tab ).
      cl_abap_unit_assert=>assert_not_initial( act = lv_tab
                                               msg = `BINDING_ERROR - the bound table is no public attribute` ).

      temp2 = boolc( tab_index >= 1 AND tab_index <= lines( tab ) ).
      cl_abap_unit_assert=>assert_true( act = temp2
                                        msg = |BINDING_ERROR_TAB_CELL_LEVEL - row { tab_index } of { lv_tab } out of range| ).

      ASSIGN tab TO <tab>.

      READ TABLE <tab> INDEX tab_index ASSIGNING <row>.


      GET REFERENCE OF val INTO lr_val.

      temp33 ?= cl_abap_typedescr=>describe_by_data( <row> ).

      lo_struct = temp33.


      LOOP AT lo_struct->components REFERENCE INTO lr_comp.

        ASSIGN COMPONENT lr_comp->name OF STRUCTURE <row> TO <cell>.
        GET REFERENCE OF <cell> INTO lr_cell.
        IF lr_cell = lr_val.
          result = |\{/{ lv_tab }/{ tab_index - 1 }/{ lr_comp->name }\}|.
          RETURN.
        ENDIF.
      ENDLOOP.
      cl_abap_unit_assert=>fail( |BINDING_ERROR_TAB_CELL_LEVEL - the value is no cell of row { tab_index } of { lv_tab } - a copy of the row?| ).
    ENDIF.

    lv_attri = attri_name( val ).
    cl_abap_unit_assert=>assert_not_initial( act = lv_attri
                                             msg = `BINDING_ERROR - the bound value is no public attribute of the app` ).
    result = |\{/{ lv_attri }\}|.

  ENDMETHOD.

  METHOD z2ui5_if_client~_event.

    result = |EVENT:{ val }|.

  ENDMETHOD.

  METHOD z2ui5_if_client~view_display.

    mv_view = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.

    mv_popup = val.

  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.

    CLEAR mv_popup.

  ENDMETHOD.

  METHOD z2ui5_if_client~follow_up_action.

    DATA temp35 LIKE LINE OF mt_action.
    temp35 = |{ val }:{ concat_lines_of( table = t_arg sep = `|` ) }|.
    INSERT temp35 INTO TABLE mt_action.

  ENDMETHOD.

  METHOD z2ui5_if_client~message_toast_display ##NEEDED.
  ENDMETHOD.

  METHOD z2ui5_if_client~message_box_display.

    mv_box = text.
    mv_box_type = type.

  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_call.

    mo_called = app.

  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.

    mv_left = abap_true.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    CREATE OBJECT mo_report.
    mo_cut = mo_report.
    CREATE OBJECT mo_client.
    mo_client->mo_app = mo_report.

  ENDMETHOD.

  METHOD init.
      DATA temp36 TYPE REF TO ltcl_layout_store.

    IF mo_cut->mo_cgui_lay_store IS NOT BOUND AND mo_cut->mv_cgui_lay_none = abap_false.

      CREATE OBJECT temp36 TYPE ltcl_layout_store.
      mo_cut->set_layout_store( temp36 ).
    ENDIF.
    mo_client->mv_init = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

  ENDMETHOD.

  METHOD event.

    mo_client->mv_event = name.
    mo_client->mt_arg = args.
    mo_cut->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD obligatory_stops_run.
    DATA temp3 TYPE xsdboolean.
    DATA temp1 LIKE sy-subrc.

    init( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).


    READ TABLE mo_cut->mt_cgui_log WITH KEY type = `E` field = `P_CARRID` TRANSPORTING NO FIELDS.
    temp1 = sy-subrc.
    temp3 = boolc( temp1 = 0 ).
    cl_abap_unit_assert=>assert_true( temp3 ).
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).

  ENDMETHOD.

  METHOD execute_shows_list.
    DATA lt_item TYPE z2ui5_cl_cgui_list=>ty_t_item.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_item.
    DATA temp38 LIKE sy-tabix.
    FIELD-SYMBOLS <temp39> LIKE LINE OF lt_item.
    DATA temp40 LIKE sy-tabix.
    DATA temp4 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).

    lt_item = mo_cut->mo_cgui_list->get_items( ).


    temp38 = sy-tabix.
    READ TABLE lt_item INDEX 1 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp37>-text
                                        exp = `HEADER` ).


    temp40 = sy-tabix.
    READ TABLE lt_item INDEX 1 ASSIGNING <temp39>.
    sy-tabix = temp40.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp39>-header ).

    temp4 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp4 ).

  ENDMETHOD.

  METHOD upper_and_lower_case.

    init( ).
    mo_report->p_carrid = `lh`.
    mo_report->p_text = `Hello`.
    event( `SOME_COMMAND` ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_text
                                        exp = `Hello` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `SOME_COMMAND` ).

  ENDMETHOD.

  METHOD select_option_buffer.
    DATA temp5 TYPE xsdboolean.
    DATA temp2 LIKE sy-subrc.
    DATA temp3 LIKE sy-subrc.
    DATA temp4 LIKE sy-tabix.
    FIELD-SYMBOLS <temp41> LIKE LINE OF mo_report->mt_cgui_so.
    DATA temp42 LIKE sy-tabix.
    FIELD-SYMBOLS <temp43> LIKE LINE OF mo_report->mt_cgui_so.
    DATA temp44 LIKE sy-tabix.
    FIELD-SYMBOLS <temp45> LIKE LINE OF mo_report->mt_cgui_so.
    DATA temp46 LIKE sy-tabix.
    FIELD-SYMBOLS <temp47> LIKE LINE OF mo_report->s_date.
    DATA temp48 LIKE sy-tabix.
    DATA temp49 TYPE d.
    FIELD-SYMBOLS <temp6> LIKE LINE OF mo_report->s_date.
    DATA temp7 LIKE sy-tabix.
    FIELD-SYMBOLS <temp50> LIKE LINE OF mo_report->s_code.
    DATA temp51 LIKE sy-tabix.
    FIELD-SYMBOLS <temp52> LIKE LINE OF mo_report->s_code.
    DATA temp53 LIKE sy-tabix.
    DATA temp6 TYPE xsdboolean.

    init( ).




    temp3 = sy-subrc.
    temp4 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_DATE` TRANSPORTING NO FIELDS.
    temp2 = sy-subrc.
    sy-subrc = temp3.
    sy-tabix = temp4.
    temp5 = boolc( temp2 = 0 ).
    cl_abap_unit_assert=>assert_true( temp5 ).



    temp42 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_DATE` ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp41>-low  = `20260101`.


    temp44 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_DATE` ASSIGNING <temp43>.
    sy-tabix = temp44.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp43>-high = `20260131`.


    temp46 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_CODE` ASSIGNING <temp45>.
    sy-tabix = temp46.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp45>-low  = `ab*`.
    event( `SOME_COMMAND` ).

    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_date )
                                        exp = 1 ).


    temp48 = sy-tabix.
    READ TABLE mo_report->s_date INDEX 1 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp47>-option
                                        exp = `BT` ).

    temp49 = `20260131`.


    temp7 = sy-tabix.
    READ TABLE mo_report->s_date INDEX 1 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp6>-high
                                        exp = temp49 ).


    temp51 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp50>.
    sy-tabix = temp51.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp50>-option
                                        exp = `CP` ).


    temp53 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp52>.
    sy-tabix = temp53.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp52>-low
                                        exp = `AB*` ).
    " the inputs are bound to the buffer

    temp6 = boolc( mo_client->mv_view CS `{/MT_CGUI_SO/` ).
    cl_abap_unit_assert=>assert_true( temp6 ).

  ENDMETHOD.

  METHOD select_option_complex.

    DATA temp54 LIKE mo_report->s_code.
    DATA temp55 LIKE LINE OF temp54.
    DATA temp7 TYPE xsdboolean.
    DATA temp5 LIKE sy-subrc.
    CLEAR temp54.

    temp55-sign = `I`.
    temp55-option = `EQ`.
    temp55-low = `A`.
    INSERT temp55 INTO TABLE temp54.
    temp55-sign = `E`.
    temp55-option = `EQ`.
    temp55-low = `B`.
    INSERT temp55 INTO TABLE temp54.
    mo_report->s_code = temp54.
    init( ).



    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_CODE` TRANSPORTING NO FIELDS.
    temp5 = sy-subrc.
    temp7 = boolc( temp5 = 0 ).
    cl_abap_unit_assert=>assert_false( temp7 ).
    event( `SOME_COMMAND` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD leave_during_the_run.
    DATA temp8 TYPE xsdboolean.
    DATA temp6 LIKE sy-subrc.
    DATA temp9 TYPE xsdboolean.
    DATA temp7 LIKE sy-subrc.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_leave = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    " the message of the report, and not the one of an empty list


    READ TABLE mo_cut->mt_cgui_msg WITH KEY text = `Unknown airline` TRANSPORTING NO FIELDS.
    temp6 = sy-subrc.
    temp8 = boolc( temp6 = 0 ).
    cl_abap_unit_assert=>assert_true( temp8 ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY text = `List contains no data` TRANSPORTING NO FIELDS.
    temp7 = sy-subrc.
    temp9 = boolc( temp7 = 0 ).
    cl_abap_unit_assert=>assert_false( temp9 ).
    " the classic restart: the data as after INITIALIZATION, the input kept
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 100 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_inits
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).

  ENDMETHOD.

  METHOD controls_released.
    DATA lo_edit TYPE REF TO z2ui5_cl_cgui_textedit.
    DATA temp3 TYPE REF TO z2ui5_cl_cgui_container.
    DATA lv_id TYPE i.
    FIELD-SYMBOLS <temp56> LIKE LINE OF mo_cut->mt_cgui_gui_obj.
    DATA temp57 LIKE sy-tabix.
    FIELD-SYMBOLS <temp58> LIKE LINE OF mo_cut->mt_cgui_gui_obj.
    DATA temp59 LIKE sy-tabix.
    FIELD-SYMBOLS <temp60> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp61 LIKE sy-tabix.
    FIELD-SYMBOLS <temp62> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp63 LIKE sy-tabix.

    init( ).


    CREATE OBJECT temp3 TYPE z2ui5_cl_cgui_container EXPORTING container_name = 'CC'.
    CREATE OBJECT lo_edit TYPE z2ui5_cl_cgui_textedit EXPORTING parent = temp3.
    lo_edit->set_textstream( `a long note` ).

    lv_id = lo_edit->get_id( ).
    event( `NOTHING` ).


    temp57 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui_obj INDEX lv_id ASSIGNING <temp56>.
    sy-tabix = temp57.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_bound( <temp56> ).

    " FREE: the object and its text no longer travel with the draft
    lo_edit->free( ).
    event( `NOTHING` ).


    temp59 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui_obj INDEX lv_id ASSIGNING <temp58>.
    sy-tabix = temp59.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_not_bound( <temp58> ).


    temp61 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX lv_id ASSIGNING <temp60>.
    sy-tabix = temp61.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp60>-text ).


    temp63 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX lv_id ASSIGNING <temp62>.
    sy-tabix = temp63.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp62>-freed ).

  ENDMETHOD.

  METHOD salv_sorts_and_totals.

    DATA lo_salv TYPE REF TO z2ui5_cl_cgui_salv_table.
    DATA temp64 TYPE ltcl_report=>ty_t_row.
    DATA temp65 LIKE LINE OF temp64.
    DATA lt_layout TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    FIELD-SYMBOLS <temp66> LIKE LINE OF lt_layout.
    DATA temp67 LIKE sy-tabix.
    FIELD-SYMBOLS <temp68> LIKE LINE OF lt_layout.
    DATA temp69 LIKE sy-tabix.
    FIELD-SYMBOLS <temp70> LIKE LINE OF lt_layout.
    DATA temp71 LIKE sy-tabix.
    FIELD-SYMBOLS <temp72> LIKE LINE OF lt_layout.
    DATA temp73 LIKE sy-tabix.

    init( ).

    CLEAR temp64.

    temp65-carrid = `LH`.
    temp65-seats = 1.
    INSERT temp65 INTO TABLE temp64.
    temp65-carrid = `AA`.
    temp65-seats = 2.
    INSERT temp65 INTO TABLE temp64.
    temp65-carrid = `LH`.
    temp65-seats = 4.
    INSERT temp65 INTO TABLE temp64.
    mo_report->mt_row = temp64.
    " cl_salv_table: a total, a sort with subtotals, a column moved
    z2ui5_cl_cgui_salv_table=>factory( IMPORTING r_salv_table = lo_salv
                                       CHANGING  t_table      = mo_report->mt_row ).
    lo_salv->get_aggregations( )->add_aggregation( 'SEATS' ).
    lo_salv->get_sorts( )->add_sort( columnname = 'CARRID'
                                     subtotal   = abap_true ).
    lo_salv->get_columns( )->set_column_position( columnname = 'SEATS'
                                                  position   = 1 ).
    lo_salv->display( ).

    cl_abap_unit_assert=>assert_bound( mo_cut->mo_cgui_alv ).

    lt_layout = mo_cut->mo_cgui_alv->get_layout( mo_report->mt_row ).


    temp67 = sy-tabix.
    READ TABLE lt_layout INDEX 1 ASSIGNING <temp66>.
    sy-tabix = temp67.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp66>-name
                                        exp = `SEATS` ).


    temp69 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `SEATS` ASSIGNING <temp68>.
    sy-tabix = temp69.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp68>-sum ).


    temp71 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `CARRID` ASSIGNING <temp70>.
    sy-tabix = temp71.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_not_initial( <temp70>-sort ).


    temp73 = sy-tabix.
    READ TABLE lt_layout WITH KEY name = `CARRID` ASSIGNING <temp72>.
    sy-tabix = temp73.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp72>-subtotal ).

  ENDMETHOD.

  METHOD screen_as_window_checks.
    DATA temp10 TYPE xsdboolean.
    DATA temp11 TYPE xsdboolean.
    DATA temp8 LIKE sy-subrc.

    " CALL SELECTION-SCREEN 1100 AS WINDOW
    init( ).
    mo_cut->call_selection_screen( `1100` ).
    event( `NOTHING` ).

    temp10 = boolc( mo_client->mv_popup CS `Note on 1100` ).
    cl_abap_unit_assert=>assert_true( temp10 ).

    " the input as SAP GUI converts it, then AT SELECTION-SCREEN ON - an
    " error keeps the dialog
    mo_report->p_text = `bad`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-screen_ok ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_text
                                        exp = `BAD` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_dynnr
                                        exp = `1100` ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY text = `Not this text` TRANSPORTING NO FIELDS.
    temp8 = sy-subrc.
    temp11 = boolc( temp8 = 0 ).
    cl_abap_unit_assert=>assert_true( temp11 ).

    mo_report->p_text = `fine`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-screen_ok ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_text
                                        exp = `FINE` ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mv_cgui_dynnr ).

  ENDMETHOD.

  METHOD empty_list_restarts.
    DATA temp12 TYPE xsdboolean.
    DATA temp9 LIKE sy-subrc.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_empty = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY text = `List contains no data` TRANSPORTING NO FIELDS.
    temp9 = sy-subrc.
    temp12 = boolc( temp9 = 0 ).
    cl_abap_unit_assert=>assert_true( temp12 ).
    " the next Execute does not add to what this one collected
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 100 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 101 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD popup_in_the_run.
    DATA temp13 TYPE xsdboolean.
    DATA temp10 LIKE sy-subrc.
    DATA temp14 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_ask = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    " the run waits for the answer: no END-OF-SELECTION, no empty list yet
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY text = `List contains no data` TRANSPORTING NO FIELDS.
    temp10 = sy-subrc.
    temp13 = boolc( temp10 = 0 ).
    cl_abap_unit_assert=>assert_false( temp13 ).

    " the answer: the rest of START-OF-SELECTION, END-OF-SELECTION, the list
    event( `ASK` ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp14 = boolc( mo_client->mv_view CS `Answered` ).
    cl_abap_unit_assert=>assert_true( temp14 ).

    " Cancel ends the run on the selection screen - the report starts anew
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    mo_report->mv_ask = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 101 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-cancel ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 100 ).

  ENDMETHOD.

  METHOD demo_output_into_list.

    TYPES:
      BEGIN OF ty_s_air,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_air.
    TYPES temp5 TYPE STANDARD TABLE OF ty_s_air WITH DEFAULT KEY.
DATA lt_air TYPE temp5.
    DATA temp74 LIKE lt_air.
    DATA temp75 LIKE LINE OF temp74.
    DATA lt_text TYPE string_table.

    z2ui5_cl_cgui_gui=>set_report( mo_cut ).

    CLEAR temp74.

    temp75-carrid = `LH`.
    temp75-seats = 120.
    INSERT temp75 INTO TABLE temp74.
    temp75-carrid = `AA`.
    temp75-seats = 8.
    INSERT temp75 INTO TABLE temp74.
    lt_air = temp74.
    z2ui5_cl_cgui_demo_output=>begin_section( `Flights` ).
    z2ui5_cl_cgui_demo_output=>write_text( `Seats per airline` ).
    z2ui5_cl_cgui_demo_output=>write( data = lt_air
                                      name = `LT_AIR` ).
    z2ui5_cl_cgui_demo_output=>new( )->write_html( `<p>a <b>bold</b> end</p>` )->line( ).
    z2ui5_cl_cgui_demo_output=>display( 42 ).


    lt_text = mo_cut->list( )->to_text( ).
    DELETE lt_text WHERE table_line IS INITIAL.
    " a section is a heading, a table its columns under the component names,
    " html its text, line( ) a ULINE - after the page header of the report
    cl_abap_unit_assert=>assert_equals(
        act = concat_lines_of( table = lt_text sep = `|` )
        exp = |HEADER\|Flights\|Seats per airline\|LT_AIR\|CARRID SEATS\|LH     120  \|AA     8    \| a  bold  end\||
           && |{ repeat( val = `-` occ = 80 ) }\|42| ).

  ENDMETHOD.

  METHOD file_upload_and_download.

    TYPES:
      BEGIN OF ty_s_air,
        carrid TYPE c LENGTH 3,
        name   TYPE c LENGTH 20,
      END OF ty_s_air.
    TYPES temp6 TYPE STANDARD TABLE OF ty_s_air WITH DEFAULT KEY.
DATA lt_air TYPE temp6.
    DATA temp76 TYPE string_table.
    DATA temp78 TYPE REF TO z2ui5_cl_cgui_file.
    DATA lo_file LIKE temp78.
    DATA temp15 TYPE xsdboolean.
    DATA temp16 TYPE xsdboolean.
    FIELD-SYMBOLS <temp79> LIKE LINE OF lt_air.
    DATA temp80 LIKE sy-tabix.
    DATA temp81 TYPE REF TO z2ui5_cl_cgui_file.
    DATA temp17 TYPE xsdboolean.
    DATA temp82 LIKE lt_air.
    DATA temp83 LIKE LINE OF temp82.
    FIELD-SYMBOLS <temp84> LIKE LINE OF mo_client->mt_action.
    DATA temp85 LIKE sy-tabix.

    init( ).
    " F4 opens the upload - the dialog answers cancel the first time

    CLEAR temp76.
    INSERT `P_TEXT` INTO TABLE temp76.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp76 ).

    temp78 ?= mo_client->mo_called.

    lo_file = temp78.
    cl_abap_unit_assert=>assert_initial( mo_report->p_text ).

    " the user picks a file in the browser and confirms
    mo_client->mo_app = lo_file.
    mo_client->mv_init = abap_true.
    lo_file->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

    temp15 = boolc( mo_client->mv_popup CS `FileUploader` ).
    cl_abap_unit_assert=>assert_true( temp15 ).

    temp16 = boolc( mo_client->mv_popup CS `fileType="txt"` ).
    cl_abap_unit_assert=>assert_true( temp16 ).
    lo_file->mv_value = `data:text/plain;base64,` && z2ui5_cl_cgui_context=>conv_encode_x_base64(
        z2ui5_cl_cgui_context=>conv_get_xstring_by_string( |LH\tLufthansa\r\nAA\tAmerican\r\n| ) ).
    lo_file->mv_path = `C:\fakepath\airlines.txt`.
    mo_client->mv_event = `CGUI_FILE_UPLOAD`.
    lo_file->z2ui5_if_app~main( mo_client ).
    mo_client->mv_event = `CGUI_FILE_OK`.
    lo_file->z2ui5_if_app~main( mo_client ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).

    " back in the report: the F4 runs again, and the dialog answers the file
    mo_client->mo_app = mo_report.
    CLEAR: mo_client->mo_called, mo_client->mv_event.
    mo_client->mo_prev = lo_file.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_text
                                        exp = `airlines.txt` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " gui_upload( ) reads it by its name, whatever the folder and the case
    z2ui5_cl_cgui_frontend=>gui_upload( EXPORTING  filename            = `C:\any\AIRLINES.TXT`
                                                   has_field_separator = abap_true
                                        CHANGING   data_tab            = lt_air
                                        EXCEPTIONS file_open_error     = 1
                                                   OTHERS              = 2 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).


    temp80 = sy-tabix.
    READ TABLE lt_air INDEX 2 ASSIGNING <temp79>.
    sy-tabix = temp80.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp79>-name
                                        exp = `American` ).
    " a name the browser has no file of - a path of the PC: the upload
    " dialog opens for it, the run stops and Execute runs again with the file
    CLEAR mo_client->mo_called.
    TRY.
        z2ui5_cl_cgui_frontend=>gui_upload( EXPORTING  filename        = `C:\data\missing.txt`
                                            CHANGING   data_tab        = lt_air
                                            EXCEPTIONS file_open_error = 1
                                                       OTHERS          = 2 ).
        cl_abap_unit_assert=>fail( `the run goes on without the file` ).
      CATCH z2ui5_cx_cgui_stop ##NO_HANDLER.
    ENDTRY.
    cl_abap_unit_assert=>assert_initial( lt_air ).

    temp81 ?= mo_client->mo_called.
    lo_file = temp81.
    mo_client->mo_app = lo_file.
    mo_client->mv_init = abap_true.
    lo_file->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.
    mo_client->mo_app = mo_report.

    temp17 = boolc( mo_client->mv_popup CS `title="missing.txt"` ).
    cl_abap_unit_assert=>assert_true( temp17 ).

    " gui_download( ) hands the file to the browser

    CLEAR temp82.

    temp83-carrid = `LH`.
    temp83-name = `Lufthansa`.
    INSERT temp83 INTO TABLE temp82.
    lt_air = temp82.
    CLEAR mo_client->mt_action.
    z2ui5_cl_cgui_frontend=>gui_download( EXPORTING  filename              = `C:\out\list.csv`
                                                     write_field_separator = abap_true
                                          CHANGING   data_tab              = lt_air
                                          EXCEPTIONS OTHERS                = 1 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).


    temp85 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp84>.
    sy-tabix = temp85.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp84>
                                        exp = |{ mo_client->z2ui5_if_client~cs_event-download_b64_file }:data:text/csv;base64,| &&
                                              |{ z2ui5_cl_cgui_context=>conv_encode_x_base64(
                                                     z2ui5_cl_cgui_context=>conv_get_xstring_by_string( |LH\tLufthansa\r\n| ) ) }\|list.csv| ).

  ENDMETHOD.

  METHOD dynpro_call_and_leave.
    DATA temp18 TYPE xsdboolean.
    DATA temp19 TYPE xsdboolean.
    DATA temp20 TYPE xsdboolean.
    DATA temp11 LIKE sy-subrc.
    DATA temp21 TYPE xsdboolean.
    DATA temp22 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_dynpro = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the dynpro shows - its PBO ran, its fields and its status are on the page
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `DYNPRO` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_dynpro
                                        exp = `0100` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;` ).

    temp18 = boolc( mo_client->mv_view CS `Seats` AND mo_client->mv_view CS `EVENT:SAVE` ).
    cl_abap_unit_assert=>assert_true( temp18 ).

    temp19 = boolc( mo_client->mv_view CS `EVENT:CHECK` ).
    cl_abap_unit_assert=>assert_true( temp19 ).

    " a push button: the required seats are checked first, no PAI
    event( `CHECK` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0100;` ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY type = `E` TRANSPORTING NO FIELDS.
    temp11 = sy-subrc.
    temp20 = boolc( temp11 = 0 ).
    cl_abap_unit_assert=>assert_true( temp20 ).

    " with the seats: PAI, the dynpro stays and its PBO runs again
    mo_report->mv_seats = 2.
    event( `CHECK` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0100;PAI0100:CHECK;PBO0100;` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `DYNPRO` ).

    " SET SCREEN goes on to the next dynpro, on the same call
    event( `NEXT` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_dynpro
                                        exp = `0200` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_dynpro_stack )
                                        exp = 1 ).

    " SAVE leaves: what followed CALL SCREEN runs - for the screen it
    " called - then END-OF-SELECTION, and the list shows without the
    " status of the dynpro
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).
    event( `SAVE` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_after
                                        exp = `0100` ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp21 = boolc( mo_client->mv_view CS `Seats 2` ).
    cl_abap_unit_assert=>assert_true( temp21 ).

    temp22 = boolc( mo_client->mv_view CS `EVENT:SAVE` ).
    cl_abap_unit_assert=>assert_false( temp22 ).

    " Back on the list - the selection screen, the dynpro stack is empty
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_cgui_dynpro_stack ).

  ENDMETHOD.

  METHOD dynpro_of_another_class.
    DATA lo_owner TYPE REF TO ltcl_report.
    DATA temp23 TYPE xsdboolean.
    DATA lo_client TYPE REF TO ltcl_client.
    DATA temp24 TYPE xsdboolean.
    DATA temp25 TYPE xsdboolean.

    " CALL SCREEN of a dynpro of another class: it runs as its own app
    init( ).
    mo_report->p_carrid = `LH`.

    CREATE OBJECT lo_owner TYPE ltcl_report.
    mo_report->mo_owner = lo_owner.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    temp23 = boolc( mo_client->mo_called = lo_owner ).
    cl_abap_unit_assert=>assert_true( act = temp23
                                      msg = `not called` ).

    " started, it shows dynpro 100 with its PBO - no selection screen

    CREATE OBJECT lo_client TYPE ltcl_client.
    lo_client->mo_app = lo_owner.
    lo_client->mv_init = abap_true.
    lo_owner->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_owner->mv_cgui_screen
                                        exp = `DYNPRO` ).
    cl_abap_unit_assert=>assert_equals( act = lo_owner->mv_pai
                                        exp = `PBO0100;` ).

    temp24 = boolc( lo_client->mv_view CS `Seats` ).
    cl_abap_unit_assert=>assert_true( act = temp24
                                      msg = `the dynpro is not on the page` ).

    " its PAI leaves (SET SCREEN 0): back to the caller
    lo_client->mv_init = abap_false.
    lo_owner->mv_seats = 3.
    lo_client->mv_event = `SAVE`.
    lo_owner->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_true( act = lo_client->mv_left
                                      msg = `not left` ).

    " the caller goes on after CALL SCREEN, with the fields of the dynpro
    CLEAR: mo_client->mv_event, mo_client->mo_called.
    mo_client->mo_prev = lo_owner.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_after
                                        exp = `0100` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp25 = boolc( mo_client->mv_view CS `Seats 3` ).
    cl_abap_unit_assert=>assert_true( act = temp25
                                      msg = `no seats 3` ).

  ENDMETHOD.

  METHOD dynpro_table_control.
    DATA temp86 TYPE ltcl_report=>ty_t_row.
    DATA temp87 LIKE LINE OF temp86.
    FIELD-SYMBOLS <temp88> LIKE LINE OF mo_cut->mt_cgui_tc_row.
    DATA temp89 LIKE sy-tabix.
    DATA temp26 TYPE xsdboolean.
    DATA temp27 TYPE xsdboolean.
    FIELD-SYMBOLS <temp90> LIKE LINE OF mo_cut->mt_cgui_tc_view.
    DATA temp91 LIKE sy-tabix.
    FIELD-SYMBOLS <temp92> LIKE LINE OF mo_report->mt_seat.
    DATA temp93 LIKE sy-tabix.
    FIELD-SYMBOLS <temp94> LIKE LINE OF mo_cut->mt_cgui_tc_view.
    DATA temp95 LIKE sy-tabix.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_dynpro = abap_true.
    mo_report->mv_tc = abap_true.

    CLEAR temp86.

    temp87-carrid = 'LH'.
    temp87-seats = 10.
    INSERT temp87 INTO TABLE temp86.
    temp87-carrid = 'AA'.
    temp87-seats = 20.
    INSERT temp87 INTO TABLE temp86.
    mo_report->mt_seat = temp86.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the lines of the PBO loop, a table bound to them - the seats an input
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tc_row )
                                        exp = 2 ).


    temp89 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tc_row INDEX 2 ASSIGNING <temp88>.
    sy-tabix = temp89.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp88>-c01
                                        exp = `AA` ).

    temp26 = boolc( mo_client->mv_view CS `<Table` AND mo_client->mv_view CS `<Input value="{C02}"` ).
    cl_abap_unit_assert=>assert_true( temp26 ).

    temp27 = boolc( mo_client->mv_view CS `<Text text="{C01}"` AND mo_client->mv_view CS `Seats` ).
    cl_abap_unit_assert=>assert_true( temp27 ).
    " the browser holds the first window of the lines, bound with their total
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_tc_view
                                        exp = mo_cut->mt_cgui_tc_row ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_tc_total
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = z2ui5_cl_cgui_view=>cv_tc_window ).

    " the user changes a cell of the line the browser holds: the PAI loop
    " reads it into the work area and modifies its line; the PBO hands the
    " lines over anew


    temp91 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tc_view INDEX 2 ASSIGNING <temp90>.
    sy-tabix = temp91.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp90>-c02 = `25`.
    event( `CHECK` ).


    temp93 = sy-tabix.
    READ TABLE mo_report->mt_seat INDEX 2 ASSIGNING <temp92>.
    sy-tabix = temp93.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp92>-seats
                                        exp = 25 ).


    temp95 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tc_view INDEX 2 ASSIGNING <temp94>.
    sy-tabix = temp95.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp94>-c02
                                        exp = `25` ).

  ENDMETHOD.

  METHOD dynpro_tabstrip.
    DATA temp28 TYPE xsdboolean.
    DATA temp29 TYPE xsdboolean.
    DATA temp30 TYPE xsdboolean.
    DATA temp96 TYPE string_table.
    DATA temp31 TYPE xsdboolean.
    DATA temp32 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_dynpro = abap_true.
    mo_report->mv_tabs = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the tabstrip: its tabs by function code, the first selected, the
    " subscreen the PBO called on it - its PBO ran too
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0110;` ).

    temp28 = boolc( mo_client->mv_view CS `IconTabBar` AND mo_client->mv_view CS `selectedKey="TAB1"` ).
    cl_abap_unit_assert=>assert_true( temp28 ).

    temp29 = boolc( mo_client->mv_view CS `key="TAB2"` AND mo_client->mv_view CS `First` ).
    cl_abap_unit_assert=>assert_true( temp29 ).

    temp30 = boolc( mo_client->mv_view CS z2ui5_cl_cgui_selscreen=>cs_event-tab ).
    cl_abap_unit_assert=>assert_true( temp30 ).

    " the second tab: a function of the dynpro - its PAI (logged first)
    " calls that of the subscreen and switches the subscreen

    CLEAR temp96.
    INSERT `TAB2` INTO TABLE temp96.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-tab
           args = temp96 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0110;PAI0100:TAB2;PAI0110:TAB2;PBO0100;PBO0120;` ).

    temp31 = boolc( mo_client->mv_view CS `selectedKey="TAB2"` AND mo_client->mv_view CS `Second tab` ).
    cl_abap_unit_assert=>assert_true( temp31 ).

    temp32 = boolc( mo_client->mv_view CS `First` ).
    cl_abap_unit_assert=>assert_false( temp32 ).

  ENDMETHOD.

  METHOD dynpro_text_editor.
    DATA temp33 TYPE xsdboolean.
    FIELD-SYMBOLS <temp98> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp99 LIKE sy-tabix.
    FIELD-SYMBOLS <temp100> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp101 LIKE sy-tabix.
    FIELD-SYMBOLS <temp102> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp103 LIKE sy-tabix.
    DATA lv_f1_key TYPE string.
    DATA temp34 TYPE xsdboolean.
    DATA temp12 LIKE sy-subrc.
    DATA temp13 LIKE sy-subrc.
    DATA temp14 LIKE sy-tabix.
    DATA temp35 TYPE xsdboolean.
    FIELD-SYMBOLS <temp104> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp105 LIKE sy-tabix.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_dynpro = abap_true.
    mo_report->mv_gui = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the text editor of the PBO in the area CC, bound to its line
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `DYNPRO` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_gui )
                                        exp = 2 ).

    temp33 = boolc( mo_client->mv_view CS `<TextArea` ).
    cl_abap_unit_assert=>assert_true( temp33 ).


    temp99 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp98>.
    sy-tabix = temp99.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp98>-text
                                        exp = `first note` ).

    " what the user typed, on Save: the PAI reads it, the PBO does not set it again


    temp101 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp100>.
    sy-tabix = temp101.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp100>-text = `typed note`.
    event( `CHECK` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_note
                                        exp = `typed note` ).


    temp103 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp102>.
    sy-tabix = temp103.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp102>-text
                                        exp = `typed note` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_gui )
                                        exp = 2 ).

    " F1 registered: the key on the page, the text area with its id

    lv_f1_key = |KEYBOARD_SHORTCUT:F1\|CGUI_GUI_F1\|{ mo_client->z2ui5_if_client~cs_view-main }|.




    temp13 = sy-subrc.
    temp14 = sy-tabix.
    READ TABLE mo_client->mt_action WITH KEY table_line = lv_f1_key TRANSPORTING NO FIELDS.
    temp12 = sy-subrc.
    sy-subrc = temp13.
    sy-tabix = temp14.
    temp34 = boolc( temp12 = 0 ).
    cl_abap_unit_assert=>assert_true( temp34 ).

    temp35 = boolc( mo_client->mv_view CS `cgui_textedit_2` ).
    cl_abap_unit_assert=>assert_true( temp35 ).

    " F1 with the cursor in the second line: the handler, where it stood


    temp105 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp104>.
    sy-tabix = temp105.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp104>-text = |first\nsecond|.
    CLEAR mo_client->ms_get-s_focus.
    mo_client->ms_get-s_focus-id = `cgui_textedit_2`.
    mo_client->ms_get-s_focus-selection_start = 8.
    mo_client->ms_get-s_focus-selection_end = 8.
    event( z2ui5_cl_cgui_report=>cs_ucomm-gui_f1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_f1
                                        exp = `2:3` ).

  ENDMETHOD.

  METHOD current_screen_afresh.
    DATA lt_screen TYPE z2ui5_cl_cgui_selscreen=>ty_t_screen.
    DATA temp36 TYPE xsdboolean.
    DATA temp15 LIKE sy-subrc.

    init( ).
    " outside of at_selection_screen_output( ): a screen built afresh, with
    " the fields of selection_screen( ) - and none kept in the app

    lt_screen = mo_cut->current_screen( )->loop_at_screen( ).


    READ TABLE lt_screen WITH KEY name = `P_CARRID` TRANSPORTING NO FIELDS.
    temp15 = sy-subrc.
    temp36 = boolc( temp15 = 0 ).
    cl_abap_unit_assert=>assert_true( temp36 ).
    cl_abap_unit_assert=>assert_not_bound( mo_cut->mo_cgui_screen ).

  ENDMETHOD.

  METHOD secondary_list_and_back.
    DATA temp106 TYPE string_table.
    DATA temp37 TYPE xsdboolean.
    DATA temp38 TYPE xsdboolean.
    DATA temp108 TYPE string_table.
    DATA temp110 TYPE string_table.
    DATA temp39 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).


    CLEAR temp106.
    INSERT `2` INTO TABLE temp106.
    INSERT `H1` INTO TABLE temp106.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp106 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 2 ).

    temp37 = boolc( mo_client->mv_view CS `Detail H1` ).
    cl_abap_unit_assert=>assert_true( temp37 ).

    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).

    temp38 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp38 ).

    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).

    " sy-lsind = sy-lsind - 1: a second detail replaces the first, Back
    " returns to the basic list
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_report->mv_replace = abap_true.

    CLEAR temp108.
    INSERT `2` INTO TABLE temp108.
    INSERT `H1` INTO TABLE temp108.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp108 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).
    mo_report->mv_replace = abap_false.

    CLEAR temp110.
    INSERT `1` INTO TABLE temp110.
    INSERT `H2` INTO TABLE temp110.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp110 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    temp39 = boolc( mo_client->mv_view CS `Detail H1` ).
    cl_abap_unit_assert=>assert_true( temp39 ).

  ENDMETHOD.

  METHOD line_selection_calls_screen.
    DATA temp112 TYPE string_table.
    DATA temp40 TYPE xsdboolean.
    DATA temp41 TYPE xsdboolean.
    DATA temp42 TYPE xsdboolean.
    DATA temp43 TYPE xsdboolean.
    DATA temp44 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " AT LINE-SELECTION sets a status and calls a dynpro
    mo_report->mv_line_status = abap_true.
    mo_report->mv_line_dynpro = abap_true.

    CLEAR temp112.
    INSERT `2` INTO TABLE temp112.
    INSERT `H1` INTO TABLE temp112.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp112 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `DYNPRO` ).
    mo_report->mv_line_dynpro = abap_false.
    mo_report->mv_seats = 2.
    event( `SAVE` ).

    " back from the dynpro: what followed the call is the secondary list,
    " with the status of the line selection, not the dynpro's
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).

    temp40 = boolc( mo_client->mv_view CS `Seats 2` ).
    cl_abap_unit_assert=>assert_true( temp40 ).

    temp41 = boolc( mo_client->mv_view CS `EVENT:DETAIL` ).
    cl_abap_unit_assert=>assert_true( temp41 ).

    temp42 = boolc( mo_client->mv_view CS `EVENT:SAVE` ).
    cl_abap_unit_assert=>assert_false( temp42 ).

    " Back: the list clicked, with its own status
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).

    temp43 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp43 ).

    temp44 = boolc( mo_client->mv_view CS `EVENT:DETAIL` ).
    cl_abap_unit_assert=>assert_false( temp44 ).

  ENDMETHOD.

  METHOD user_command_secondary_list.
    DATA temp45 TYPE xsdboolean.
    DATA temp46 TYPE xsdboolean.
    DATA temp47 TYPE xsdboolean.
    DATA temp48 TYPE xsdboolean.
    DATA temp49 TYPE xsdboolean.
    DATA temp50 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " nothing written: the list stays
    event( `NOTHING` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `NOTHING` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).

    temp45 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp45 ).

    " written: a secondary list
    mo_report->mv_cmd_write = abap_true.
    event( `DETAIL` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).

    temp46 = boolc( mo_client->mv_view CS `Command DETAIL` ).
    cl_abap_unit_assert=>assert_true( temp46 ).

    temp47 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_false( temp47 ).

    " sy-lsind = sy-lsind - 1: the new list replaces it
    mo_report->mv_replace = abap_true.
    event( `AGAIN` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).

    temp48 = boolc( mo_client->mv_view CS `Command AGAIN` ).
    cl_abap_unit_assert=>assert_true( temp48 ).

    temp49 = boolc( mo_client->mv_view CS `Command DETAIL` ).
    cl_abap_unit_assert=>assert_false( temp49 ).

    " Back: the basic list
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp50 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp50 ).

  ENDMETHOD.

  METHOD alv_box_copy_selection.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <box> TYPE any.
    DATA temp114 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp116 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp118 TYPE z2ui5_cl_cgui_alv=>ty_t_row.

    mo_report->mv_alv = abap_true.
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_bound( mo_report->mr_cgui_alv_box ).
    ASSIGN mo_report->mr_cgui_alv_box->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = 3 ).
    READ TABLE <tab> INDEX 2 ASSIGNING <box>.
    <box> = abap_true.


    CLEAR temp114.
    INSERT 2 INTO TABLE temp114.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = temp114 ).

    " the selection survives the next render, select all marks every row
    event( `SOME_COMMAND` ).

    CLEAR temp116.
    INSERT 2 INTO TABLE temp116.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = temp116 ).
    " and a line selection that wrote nothing, or Back from a secondary list
    mo_cut->level_push( ).
    mo_cut->level_pop( ).

    CLEAR temp118.
    INSERT 2 INTO TABLE temp118.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = temp118 ).
    event( z2ui5_cl_cgui_alv=>cs_event-select_all ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->get_selected_rows( ) )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD url_values_screen_only.
    FIELD-SYMBOLS <temp120> LIKE LINE OF mo_report->s_date.
    DATA temp121 LIKE sy-tabix.

    mo_client->ms_get-s_config-search = `?app_start=x&p_carrid=AA&mv_secret=abc&p_hidden=Z&s_date=20260101..20260131`.
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `AA` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_secret ).
    cl_abap_unit_assert=>assert_initial( mo_report->p_hidden ).


    temp121 = sy-tabix.
    READ TABLE mo_report->s_date INDEX 1 ASSIGNING <temp120>.
    sy-tabix = temp121.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp120>-option
                                        exp = `BT` ).

  ENDMETHOD.

  METHOD url_skip_screen.

    mo_client->ms_get-s_config-search = `?p_carrid=LH&skip_screen=X`.
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD url_range.

    DATA lt_value TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    FIELD-SYMBOLS <temp122> LIKE LINE OF lt_value.
    DATA temp123 LIKE sy-tabix.
    FIELD-SYMBOLS <temp124> LIKE LINE OF lt_value.
    DATA temp125 LIKE sy-tabix.
    FIELD-SYMBOLS <temp126> LIKE LINE OF lt_value.
    DATA temp127 LIKE sy-tabix.
    FIELD-SYMBOLS <temp128> LIKE LINE OF lt_value.
    DATA temp129 LIKE sy-tabix.
    FIELD-SYMBOLS <temp130> LIKE LINE OF lt_value.
    DATA temp131 LIKE sy-tabix.
    DATA temp132 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp133 LIKE LINE OF temp132.
    lt_value = z2ui5_cl_cgui_command=>url_range( name = `S_CODE`
                                                      val  = `A,B..C,!D,>=E,F*` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_value )
                                        exp = 5 ).


    temp123 = sy-tabix.
    READ TABLE lt_value INDEX 2 ASSIGNING <temp122>.
    sy-tabix = temp123.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp122>-option
                                        exp = `BT` ).


    temp125 = sy-tabix.
    READ TABLE lt_value INDEX 2 ASSIGNING <temp124>.
    sy-tabix = temp125.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp124>-high
                                        exp = `C` ).


    temp127 = sy-tabix.
    READ TABLE lt_value INDEX 3 ASSIGNING <temp126>.
    sy-tabix = temp127.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp126>-sign
                                        exp = `E` ).


    temp129 = sy-tabix.
    READ TABLE lt_value INDEX 4 ASSIGNING <temp128>.
    sy-tabix = temp129.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp128>-option
                                        exp = `GE` ).


    temp131 = sy-tabix.
    READ TABLE lt_value INDEX 5 ASSIGNING <temp130>.
    sy-tabix = temp131.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp130>-option
                                        exp = `CP` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_command=>url_from_range( lt_value )
                                        exp = `A,B..C,!D,>=E,F*` ).

    " NB and NP have no form of their own - I NB is E BT, I NP is E CP

    CLEAR temp132.

    CLEAR temp133.
    temp133-sign = `I`.
    temp133-option = `NB`.
    temp133-low = `A`.
    temp133-high = `B`.
    INSERT temp133 INTO TABLE temp132.
    CLEAR temp133.
    temp133-sign = `I`.
    temp133-option = `NP`.
    temp133-low = `C*`.
    INSERT temp133 INTO TABLE temp132.
    CLEAR temp133.
    temp133-sign = `E`.
    temp133-option = `NB`.
    temp133-low = `D`.
    temp133-high = `E`.
    INSERT temp133 INTO TABLE temp132.
    cl_abap_unit_assert=>assert_equals(
        act = z2ui5_cl_cgui_command=>url_from_range( temp132 )
        exp = `!A..B,!C*,D..E` ).

  ENDMETHOD.

  METHOD variant_screen_only.

    " a variant names the fields of the screen - one from the browser's
    " storage may name anything, and sets no other attribute
    DATA lo_store TYPE REF TO ltcl_variant_store.
    DATA temp134 TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp135 LIKE LINE OF temp134.
    DATA temp8 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp9 LIKE LINE OF temp8.
    CREATE OBJECT lo_store TYPE ltcl_variant_store.

    CLEAR temp134.

    temp135-name = `V1`.

    CLEAR temp8.

    temp9-name = `P_CARRID`.
    temp9-kind = `P`.
    temp9-low = `LH`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `mv_secret`.
    temp9-kind = `P`.
    temp9-low = `abc`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `MV_UCOMM`.
    temp9-kind = `P`.
    temp9-low = `X`.
    INSERT temp9 INTO TABLE temp8.
    temp135-values = temp8.
    INSERT temp135 INTO TABLE temp134.
    lo_store->mt_variant = temp134.
    mo_cut->set_variant_store( lo_store ).
    mo_cut->set_variant( `V1` ).
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_secret ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_ucomm ).

  ENDMETHOD.

  METHOD variant_names_refused.

    DATA lo_store TYPE REF TO ltcl_variant_store.
    DATA temp136 TYPE string_table.
    DATA lt_name LIKE temp136.
    DATA lv_name LIKE LINE OF lt_name.
      DATA temp138 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
      DATA temp139 LIKE LINE OF temp138.
      DATA lo_popup TYPE REF TO z2ui5_cl_cgui_popup.
      DATA lo_client TYPE REF TO ltcl_client.
      FIELD-SYMBOLS <temp140> LIKE LINE OF mo_cut->mt_cgui_msg.
      DATA temp141 LIKE sy-tabix.
    DATA temp142 TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp143 LIKE LINE OF temp142.
    DATA temp10 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp11 LIKE LINE OF temp10.
    DATA lo_next TYPE REF TO ltcl_report.
    DATA lo_next_client TYPE REF TO ltcl_client.
    DATA temp144 TYPE REF TO ltcl_layout_store.
    CREATE OBJECT lo_store TYPE ltcl_variant_store.
    mo_cut->set_variant_store( lo_store ).
    init( ).

    " the name scheme of the drafts and a name longer than the stores keep
    " are no names of a variant

    CLEAR temp136.
    INSERT `%DRAFT_SOMEONE` INTO TABLE temp136.
    INSERT `A123456789B123456789C123456789D123456789E` INTO TABLE temp136.

    lt_name = temp136.

    LOOP AT lt_name INTO lv_name.

      CLEAR temp138.

      temp139-name = `NAME`.
      temp139-value = lv_name.
      INSERT temp139 INTO TABLE temp138.

      lo_popup = z2ui5_cl_cgui_popup=>get_values( temp138 ).

      CREATE OBJECT lo_client TYPE ltcl_client.
      lo_client->mo_app = lo_popup.
      lo_client->mv_event = `CGUI_POP_OK`.
      lo_popup->z2ui5_if_app~main( lo_client ).
      cl_abap_unit_assert=>assert_true( lo_popup->result( )-confirmed ).
      mo_cut->variant_save( lo_popup ).
      cl_abap_unit_assert=>assert_initial( lo_store->mt_variant ).


      temp141 = sy-tabix.
      READ TABLE mo_cut->mt_cgui_msg INDEX lines( mo_cut->mt_cgui_msg ) ASSIGNING <temp140>.
      sy-tabix = temp141.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      cl_abap_unit_assert=>assert_equals( act = <temp140>-type
                                          exp = `E` ).
    ENDLOOP.

    " a draft of another user's name, planted past the popup, is not
    " restored

    CLEAR temp142.

    temp143-name = z2ui5_cl_cgui_memory=>draft_name( ).
    temp143-owner = `ZZ_OTHER`.

    CLEAR temp10.

    temp11-name = `P_CARRID`.
    temp11-kind = `P`.
    temp11-low = `XX`.
    INSERT temp11 INTO TABLE temp10.
    temp143-values = temp10.
    INSERT temp143 INTO TABLE temp142.
    lo_store->mt_variant = temp142.

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp144 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp144 ).
    lo_next->set_variant_store( lo_store ).
    lo_next->set_draft( ).
    lo_next->z2ui5_if_app~main( lo_next_client ).
    cl_abap_unit_assert=>assert_differs( act = lo_next->p_carrid
                                         exp = `XX` ).

  ENDMETHOD.

  METHOD events_screen_only.
    DATA temp145 TYPE string_table.
    DATA temp147 TYPE string_table.
    DATA temp149 TYPE string_table.
    DATA temp151 TYPE string_table.
    DATA temp153 TYPE string_table.

    " F4 and the multiple selection name their field in the argument - an
    " attribute that is no field of the screen opens nothing
    init( ).

    CLEAR temp145.
    INSERT `MT_ROW` INTO TABLE temp145.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp145 ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    CLEAR temp147.
    INSERT `MV_SECRET` INTO TABLE temp147.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp147 ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " nor does a NO-DISPLAY field, or a parameter named as a select-option

    CLEAR temp149.
    INSERT `S_HIDDEN` INTO TABLE temp149.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp149 ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    CLEAR temp151.
    INSERT `P_CARRID` INTO TABLE temp151.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp151 ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " a field of the screen still does

    CLEAR temp153.
    INSERT `s_code` INTO TABLE temp153.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp153 ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD submit_starts_report.
    DATA temp155 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp156 LIKE LINE OF temp155.
    DATA temp157 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_called LIKE temp157.
    FIELD-SYMBOLS <temp158> LIKE LINE OF lo_called->mt_cgui_submit.
    DATA temp159 LIKE sy-tabix.
    DATA lo_client TYPE REF TO ltcl_client.
    DATA temp160 TYPE REF TO ltcl_report.

    init( ).

    CLEAR temp155.

    temp156-name = `P_CARRID`.
    temp156-kind = `P`.
    temp156-low = `UA`.
    INSERT temp156 INTO TABLE temp155.
    mo_cut->submit( report = `LTCL_REPORT`
                    values = temp155 ).


    temp157 ?= mo_client->mo_called.

    lo_called = temp157.
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_called ).
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_skip ).


    temp159 = sy-tabix.
    READ TABLE lo_called->mt_cgui_submit INDEX 1 ASSIGNING <temp158>.
    sy-tabix = temp159.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp158>-low
                                        exp = `UA` ).

    " started, it runs without its selection screen

    CREATE OBJECT lo_client TYPE ltcl_client.
    lo_client->mo_app = lo_called.
    lo_client->mv_init = abap_true.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_called->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp160 ?= lo_called.
    cl_abap_unit_assert=>assert_equals( act = temp160->p_carrid
                                        exp = `UA` ).

    " Back on its output returns to the caller
    lo_client->mv_init = abap_false.
    lo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-back.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_true( lo_client->mv_left ).

  ENDMETHOD.

  METHOD link_holds_values.
    DATA temp161 LIKE mo_report->s_date.
    DATA temp162 LIKE LINE OF temp161.
    DATA lv_link TYPE string.
    DATA temp51 TYPE xsdboolean.
    DATA temp52 TYPE xsdboolean.
    DATA temp53 TYPE xsdboolean.
    DATA temp54 TYPE xsdboolean.

    mo_client->ms_get-s_config-origin = `https://host`.
    mo_client->ms_get-s_config-pathname = `/sap/bc/z2ui5`.
    mo_client->ms_get-s_config-search = `?sap-client=100&app_start=ltcl_report`.
    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->p_hidden = `X`.

    CLEAR temp161.

    temp162-sign = `I`.
    temp162-option = `BT`.
    temp162-low = `20260101`.
    temp162-high = `20260131`.
    INSERT temp162 INTO TABLE temp161.
    mo_report->s_date = temp161.


    lv_link = mo_cut->get_link( abap_true ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_link
                                         exp = `https://host/sap/bc/z2ui5?sap-client=100&app_start=ltcl_report*` ).

    temp51 = boolc( lv_link CS `p_carrid=LH` ).
    cl_abap_unit_assert=>assert_true( temp51 ).

    temp52 = boolc( lv_link CS `s_date=20260101..20260131` ).
    cl_abap_unit_assert=>assert_true( temp52 ).

    temp53 = boolc( lv_link CS `skip_screen=X` ).
    cl_abap_unit_assert=>assert_true( temp53 ).

    temp54 = boolc( lv_link CS `p_hidden` ).
    cl_abap_unit_assert=>assert_false( temp54 ).

  ENDMETHOD.

  METHOD parameter_id.
    DATA temp55 TYPE xsdboolean.

    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_TEST`
                              value = `LH` ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `zcgui_test` )
                                        exp = `LH` ).

    temp55 = boolc( mo_report->mv_cgui_spa CS `ZCGUI_TEST=LH` ).
    cl_abap_unit_assert=>assert_true( temp55 ).

  ENDMETHOD.

  METHOD fresh_start.
    DATA lo_keep TYPE REF TO ltcl_report.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 101 ).
    " Back: the classic restart - the data as after INITIALIZATION, which
    " runs again; the selection screen keeps its input
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 100 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_inits
                                        exp = 2 ).
    " the output of the run is gone with it - it no longer travels with the
    " selection screen
    cl_abap_unit_assert=>assert_not_bound( mo_cut->mo_cgui_list ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_total
                                        exp = 101 ).

    " off: the data stays from one run to the next

    CREATE OBJECT lo_keep TYPE ltcl_report.
    lo_keep->set_fresh_start( abap_false ).
    mo_report = lo_keep.
    mo_cut = lo_keep.
    CREATE OBJECT mo_client.
    mo_client->mo_app = lo_keep.
    init( ).
    lo_keep->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = lo_keep->mv_total
                                        exp = 102 ).

  ENDMETHOD.

  METHOD roundtrip_start.
    DATA lo_job TYPE REF TO ltcl_report.
    DATA temp163 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp164 LIKE LINE OF temp163.

    " first in every roundtrip, before the event - and in the background run
    init( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_starts
                                        exp = 2 ).

    CREATE OBJECT lo_job TYPE ltcl_report.

    CLEAR temp163.

    temp164-name = `P_CARRID`.
    temp164-kind = `P`.
    temp164-low = `LH`.
    INSERT temp164 INTO TABLE temp163.
    lo_job->cgui_run_in_background( temp163 ).
    cl_abap_unit_assert=>assert_equals( act = lo_job->mv_starts
                                        exp = 1 ).

  ENDMETHOD.

  METHOD transport_popup.
    DATA temp165 TYPE REF TO z2ui5_cl_cgui_transport.
    DATA lo_popup LIKE temp165.

    init( ).
    mo_cut->_popup( )->transport( `TR` ).

    temp165 ?= mo_client->mo_called.

    lo_popup = temp165.
    " the transpiled runtime has no E070 - the list is empty
    lo_popup->z2ui5_if_app~main( mo_client ).

    " No Transport - the popup leaves with TR, at_user_command( ) runs
    mo_client->mv_event = z2ui5_cl_cgui_transport=>cs_event-local.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mo_prev = lo_popup.
    mo_client->mv_event = `TR`.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `TR` ).
    cl_abap_unit_assert=>assert_true( mo_cut->get_transport( )-local ).

  ENDMETHOD.

  METHOD read_list_clicked.
    DATA lo_list TYPE REF TO z2ui5_cl_cgui_list.
    DATA temp56 TYPE xsdboolean.
    DATA lo_next TYPE REF TO z2ui5_cl_cgui_list.
    DATA temp57 TYPE xsdboolean.
    DATA temp58 TYPE xsdboolean.

    init( ).
    " outside a line selection: the list of list( )

    lo_list = mo_cut->list( ).

    temp56 = boolc( mo_cut->read_list( ) = lo_list ).
    cl_abap_unit_assert=>assert_true( temp56 ).

    " in at_line_selection( ): the list clicked, not the next level
    mo_cut->level_push( ).
    mo_cut->mv_cgui_on_line = abap_true.

    lo_next = mo_cut->list( ).

    temp57 = boolc( mo_cut->read_list( ) = lo_list ).
    cl_abap_unit_assert=>assert_true( temp57 ).

    temp58 = boolc( lo_next = lo_list ).
    cl_abap_unit_assert=>assert_false( temp58 ).
    mo_cut->mv_cgui_on_line = abap_false.

  ENDMETHOD.

  METHOD call_transaction.
    DATA temp166 TYPE REF TO ltcl_catalog.
    DATA temp167 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_called LIKE temp167.
    DATA temp168 TYPE REF TO z2ui5_cl_cgui_report.

    init( ).
    " a transaction of the catalog: its class with its variant

    CREATE OBJECT temp166 TYPE ltcl_catalog.
    mo_cut->set_catalog( temp166 ).
    mo_cut->call_transaction( `zfly` ).

    temp167 ?= mo_client->mo_called.

    lo_called = temp167.
    cl_abap_unit_assert=>assert_equals( act = cl_abap_typedescr=>describe_by_object_ref( lo_called )->get_relative_name( )
                                        exp = `Z2UI5_CL_CGUI_SAMPLE_04` ).
    cl_abap_unit_assert=>assert_equals( act = lo_called->mv_cgui_variant_start
                                        exp = `MINE` ).
    cl_abap_unit_assert=>assert_false( lo_called->mv_cgui_skip ).

    " no transaction of the catalog: the class; AND SKIP FIRST SCREEN
    mo_cut->call_transaction( code       = `LTCL_REPORT`
                              skip_first = abap_true ).

    temp168 ?= mo_client->mo_called.
    lo_called = temp168.
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_called ).
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_skip ).

    " neither: an error, nothing starts
    CLEAR mo_client->mo_called.
    mo_cut->call_transaction( `ZGONE` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).
    cl_abap_unit_assert=>assert_true( mo_cut->mv_cgui_stop ).

  ENDMETHOD.

  METHOD call_intent.
    DATA temp169 TYPE REF TO ltcl_catalog.
    DATA temp170 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp171 LIKE LINE OF temp170.
    DATA lt_value LIKE temp170.
    DATA temp172 TYPE REF TO ltcl_report.
    DATA lo_called LIKE temp172.
    DATA lt_submit LIKE lo_called->mt_cgui_submit.
    FIELD-SYMBOLS <temp173> LIKE LINE OF lt_submit.
    DATA temp174 LIKE sy-tabix.
    FIELD-SYMBOLS <temp175> LIKE LINE OF mo_client->mt_action.
    DATA temp176 LIKE sy-tabix.
    FIELD-SYMBOLS <temp177> LIKE LINE OF mo_client->mt_action.
    DATA temp178 LIKE sy-tabix.
    DATA temp59 TYPE xsdboolean.
    DATA temp16 LIKE sy-subrc.

    init( ).

    CREATE OBJECT temp169 TYPE ltcl_catalog.
    mo_cut->set_catalog( temp169 ).

    CLEAR temp170.

    CLEAR temp171.
    temp171-name = `P_CARRID`.
    temp171-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
    temp171-low = `LH`.
    INSERT temp171 INTO TABLE temp170.
    CLEAR temp171.
    temp171-name = `S_CODE`.
    temp171-kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
    temp171-sign = `I`.
    temp171-option = `BT`.
    temp171-low = `A`.
    temp171-high = `B`.
    INSERT temp171 INTO TABLE temp170.

    lt_value = temp170.

    " outside the launchpad: the transaction of the catalog with the intent
    mo_cut->call_intent( semantic_object = `airline`
                         values          = lt_value ).

    temp172 ?= mo_client->mo_called.

    lo_called = temp172.

    lt_submit = lo_called->mt_cgui_submit.


    temp174 = sy-tabix.
    READ TABLE lt_submit INDEX 1 ASSIGNING <temp173>.
    sy-tabix = temp174.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp173>-low
                                        exp = `LH` ).

    " inside: the cross-app navigation of the shell, the single values as
    " the startup parameters - CALL TRANSACTION of the tile alike
    CLEAR: mo_client->mo_called, mo_client->mt_action.
    mo_client->ms_get-check_launchpad_active = abap_true.
    mo_cut->call_intent( semantic_object = `Airline`
                         values          = lt_value ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp176 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp175>.
    sy-tabix = temp176.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp175>
                                        exp = `CROSS_APP_NAV_TO_EXT:{"semanticObject":"Airline","action":"display"}|{"P_CARRID":"LH"}` ).
    CLEAR mo_client->mt_action.
    mo_cut->call_transaction( `ZAIR` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp178 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp177>.
    sy-tabix = temp178.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp177>
                                         exp = `CROSS_APP_NAV_TO_EXT:*Airline*` ).

    " the shell shows the title of the report
    mo_cut->set_title( `Flights` ).
    mo_cut->view_display( ).


    READ TABLE mo_client->mt_action WITH KEY table_line = `SET_TITLE_LAUNCHPAD:Flights` TRANSPORTING NO FIELDS.
    temp16 = sy-subrc.
    temp59 = boolc( temp16 = 0 ).
    cl_abap_unit_assert=>assert_true( temp59 ).

  ENDMETHOD.

  METHOD popup_decide_list.

    TYPES temp7 TYPE STANDARD TABLE OF z2ui5_cl_cgui_popup=>ty_s_spopli WITH DEFAULT KEY.
DATA lt_list TYPE temp7.
    DATA temp179 LIKE lt_list.
    DATA temp180 LIKE LINE OF temp179.
    DATA temp181 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp181.
    DATA temp60 TYPE xsdboolean.
    DATA temp182 LIKE lt_list.
    DATA temp183 LIKE LINE OF temp182.
    DATA temp184 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA temp61 TYPE xsdboolean.
    DATA temp62 TYPE xsdboolean.

    init( ).
    " POPUP_TO_DECIDE_LIST: each VAROPTION an option, the answer its line

    CLEAR temp179.

    temp180-varoption = 'Packages'.
    INSERT temp180 INTO TABLE temp179.
    temp180-varoption = 'Source code'.
    INSERT temp180 INTO TABLE temp179.
    lt_list = temp179.
    mo_cut->popup_to_decide_list( question = `Which objects?`
                                  list     = lt_list
                                  then     = `ON_SURE` ).

    temp181 ?= mo_client->mo_called.

    lo_popup = temp181.
    " the popup's first roundtrip draws it
    mo_client->mv_init = abap_true.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

    temp60 = boolc( mo_client->mv_popup CS `Source code` ).
    cl_abap_unit_assert=>assert_true( temp60 ).
    mo_client->mv_event = `CGUI_POP_OPTION_2`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mo_prev = lo_popup.
    mo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-popup_answer.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_then
                                        exp = `2` ).

    " HIDE and INACTIVE lines are no option - the answer is still the line

    CLEAR temp182.

    CLEAR temp183.
    temp183-varoption = 'Hidden'.
    temp183-hide = 'X'.
    INSERT temp183 INTO TABLE temp182.
    CLEAR temp183.
    temp183-varoption = 'Packages'.
    INSERT temp183 INTO TABLE temp182.
    CLEAR temp183.
    temp183-varoption = 'Locked'.
    temp183-inactive = 'X'.
    INSERT temp183 INTO TABLE temp182.
    CLEAR temp183.
    temp183-varoption = 'Source code'.
    INSERT temp183 INTO TABLE temp182.
    lt_list = temp182.
    CLEAR mo_report->mv_then.
    mo_cut->popup_to_decide_list( question = `Which objects?`
                                  list     = lt_list
                                  then     = `ON_SURE` ).

    temp184 ?= mo_client->mo_called.
    lo_popup = temp184.
    mo_client->mv_init = abap_true.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

    temp61 = boolc( mo_client->mv_popup CS `Hidden` ).
    cl_abap_unit_assert=>assert_false( temp61 ).

    temp62 = boolc( mo_client->mv_popup CS `Locked` ).
    cl_abap_unit_assert=>assert_false( temp62 ).
    mo_client->mv_event = `CGUI_POP_OPTION_2`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mo_prev = lo_popup.
    mo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-popup_answer.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_then
                                        exp = `4` ).

  ENDMETHOD.

  METHOD popup_then.
    DATA temp185 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp185.
    DATA temp186 TYPE string_table.
    DATA temp188 TYPE REF TO z2ui5_cl_cgui_popup.

    init( ).
    " then: on both answers on_sure( answer ) runs, not at_user_command( )
    mo_cut->_popup( )->confirm( question = `Sure?`
                                then     = `on_sure` ).

    temp185 ?= mo_client->mo_called.

    lo_popup = temp185.
    lo_popup->z2ui5_if_app~main( mo_client ).
    " the Cancel button of the popup (its events are private)
    mo_client->mv_event = `CGUI_POP_CANCEL`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mo_prev = lo_popup.
    mo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-popup_answer.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_then
                                        exp = `A` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_ucomm ).

    " decide: the number of the option

    CLEAR temp186.
    INSERT `First` INTO TABLE temp186.
    INSERT `Second` INTO TABLE temp186.
    mo_cut->popup_to_decide( question = `Which one?`
                             options  = temp186
                             then     = `ON_SURE` ).

    temp188 ?= mo_client->mo_called.
    lo_popup = temp188.
    mo_client->mv_event = `CGUI_POP_OPTION_2`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mo_prev = lo_popup.
    mo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-popup_answer.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_then
                                        exp = `A2` ).

  ENDMETHOD.

  METHOD alv_chart.
    DATA temp63 TYPE xsdboolean.
    DATA temp64 TYPE xsdboolean.
    DATA temp65 TYPE xsdboolean.
    DATA temp66 TYPE xsdboolean.
    DATA temp67 TYPE xsdboolean.
    DATA temp189 TYPE string_table.
    DATA temp68 TYPE xsdboolean.
    DATA temp191 TYPE string_table.
    DATA temp69 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    temp63 = boolc( mo_client->mv_view CS z2ui5_cl_cgui_alv=>cs_event-chart ).
    cl_abap_unit_assert=>assert_true( temp63 ).

    " the chart: the carriers, their seats - the first text, the first number
    event( z2ui5_cl_cgui_alv=>cs_event-chart ).

    temp64 = boolc( mo_client->mv_popup CS `&lt;svg` OR mo_client->mv_popup CS `<svg` ).
    cl_abap_unit_assert=>assert_true( temp64 ).

    temp65 = boolc( mo_client->mv_popup CS `selectedKey="SEATS"` ).
    cl_abap_unit_assert=>assert_true( temp65 ).

    temp66 = boolc( mo_client->mv_popup CS `UA` ).
    cl_abap_unit_assert=>assert_true( temp66 ).

    " the kinds of chart, a column - the pie

    temp67 = boolc( mo_client->mv_popup CS `SegmentedButton` ).
    cl_abap_unit_assert=>assert_true( temp67 ).

    CLEAR temp189.
    INSERT `KIND` INTO TABLE temp189.
    INSERT `PIE` INTO TABLE temp189.
    event( name = z2ui5_cl_cgui_alv=>cs_event-chart
           args = temp189 ).

    temp68 = boolc( mo_client->mv_popup CS `path d=` OR mo_client->mv_popup CS `circle cx=` ).
    cl_abap_unit_assert=>assert_true( temp68 ).

    " the rows counted instead

    CLEAR temp191.
    INSERT `VALUE` INTO TABLE temp191.
    INSERT `%COUNT` INTO TABLE temp191.
    event( name = z2ui5_cl_cgui_alv=>cs_event-chart
           args = temp191 ).

    temp69 = boolc( mo_client->mv_popup CS `selectedKey="SEATS"` ).
    cl_abap_unit_assert=>assert_false( temp69 ).

    event( z2ui5_cl_cgui_alv=>cs_event-chart_close ).

  ENDMETHOD.

  METHOD application_log.

    TYPES:
      BEGIN OF ty_s_bapiret,
        type    TYPE c LENGTH 1,
        message TYPE c LENGTH 220,
      END OF ty_s_bapiret.
    TYPES temp8 TYPE STANDARD TABLE OF ty_s_bapiret WITH DEFAULT KEY.
DATA lt_return TYPE temp8.

    " the messages of the report go into its log - the required field
    DATA lo_log TYPE REF TO z2ui5_cl_cgui_log.
    DATA lt_logged TYPE z2ui5_if_cgui_log=>ty_t_message.
    FIELD-SYMBOLS <temp193> LIKE LINE OF lt_logged.
    DATA temp194 LIKE sy-tabix.
    DATA temp195 LIKE lt_return.
    DATA temp196 LIKE LINE OF temp195.
    DATA lo_bapi TYPE REF TO z2ui5_cl_cgui_log.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    CREATE OBJECT lo_log TYPE z2ui5_cl_cgui_log.
    mo_cut->set_log( lo_log ).
    init( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    lt_logged = lo_log->z2ui5_if_cgui_log~get( ).


    temp194 = sy-tabix.
    READ TABLE lt_logged INDEX 1 ASSIGNING <temp193>.
    sy-tabix = temp194.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp193>-type
                                        exp = `E` ).

    " a log of another source - a BAPI's return table - in the popover

    CLEAR temp195.

    temp196-type = 'W'.
    temp196-message = 'Seats nearly gone'.
    INSERT temp196 INTO TABLE temp195.
    temp196-type = 'I'.
    temp196-message = 'Flight LH 400'.
    INSERT temp196 INTO TABLE temp195.
    lt_return = temp195.

    CREATE OBJECT lo_bapi TYPE z2ui5_cl_cgui_log.
    lo_bapi->add_table( lt_return ).
    CLEAR: mo_cut->mt_cgui_log, mo_cut->mv_cgui_stop.
    mo_cut->messages_from_log( lo_bapi ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_log )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_false( mo_cut->mv_cgui_stop ).

    " the log as a popup
    mo_cut->log_display( lo_bapi ).

    lo_popup ?= mo_client->mo_called.
    cl_abap_unit_assert=>assert_bound( lo_popup ).

  ENDMETHOD.

  METHOD user_parameters.
    DATA lo_next TYPE REF TO ltcl_report.
    DATA lo_next_client TYPE REF TO ltcl_client.
    DATA temp197 TYPE REF TO ltcl_layout_store.
    DATA temp70 TYPE xsdboolean.
    DATA temp198 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp198.
    DATA temp71 TYPE xsdboolean.
    DATA temp17 LIKE sy-subrc.
    DATA temp18 LIKE sy-subrc.
    DATA temp19 LIKE sy-tabix.
    FIELD-SYMBOLS <temp199> LIKE LINE OF lo_popup->mt_field.
    DATA temp200 LIKE sy-tabix.
    FIELD-SYMBOLS <temp201> LIKE LINE OF lo_popup->mt_field.
    DATA temp202 LIKE sy-tabix.
    FIELD-SYMBOLS <temp203> LIKE LINE OF lo_popup->mt_field.
    DATA temp204 LIKE sy-tabix.
    FIELD-SYMBOLS <temp205> LIKE LINE OF lo_popup->mt_field.
    DATA temp206 LIKE sy-tabix.

    " the server store - the table of the variants: a parameter ID set in
    " one report is there in the next one, in any browser
    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_SRV`
                              value = `UA` ).

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp197 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp197 ).
    lo_next->z2ui5_if_app~main( lo_next_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_SRV` )
                                        exp = `UA` ).
    " the browser's storage control for them is gone

    temp70 = boolc( lo_next_client->mv_view CS `z2ui5_cgui_spa` ).
    cl_abap_unit_assert=>assert_false( temp70 ).

    " SU3 in the command field: the parameters in a popup - one changed,
    " one added, an emptied one deleted
    mo_cut->set_parameter_id( id    = `ZCGUI_DEL`
                              value = `X1` ).
    mo_cut->okcode_execute( `/nSU3` ).

    temp198 ?= mo_client->mo_called.

    lo_popup = temp198.




    temp18 = sy-subrc.
    temp19 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `ZCGUI_SRV` value = `UA` TRANSPORTING NO FIELDS.
    temp17 = sy-subrc.
    sy-subrc = temp18.
    sy-tabix = temp19.
    temp71 = boolc( temp17 = 0 ).
    cl_abap_unit_assert=>assert_true( temp71 ).


    temp200 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `ZCGUI_SRV` ASSIGNING <temp199>.
    sy-tabix = temp200.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp199>-value = `LH`.


    temp202 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `ZCGUI_DEL` ASSIGNING <temp201>.
    sy-tabix = temp202.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp201>-value = ``.


    temp204 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_ID` ASSIGNING <temp203>.
    sy-tabix = temp204.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp203>-value = `zcgui_add`.


    temp206 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_VALUE` ASSIGNING <temp205>.
    sy-tabix = temp206.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp205>-value = `0017`.
    " OK of the popup - its event
    mo_client->mv_event = `CGUI_POP_OK`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event.
    mo_client->mo_prev = lo_popup.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_SRV` )
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_ADD` )
                                        exp = `0017` ).
    cl_abap_unit_assert=>assert_initial( mo_cut->get_parameter_id( `ZCGUI_DEL` ) ).
    " and on the server
    z2ui5_cl_cgui_memory=>spa_load( lo_next->memory_ctx( ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_ADD` )
                                        exp = `0017` ).

  ENDMETHOD.

  METHOD draft.
    DATA lt_variant TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp72 TYPE xsdboolean.
    DATA temp20 LIKE sy-subrc.
    DATA lo_next TYPE REF TO ltcl_report.
    DATA lo_next_client TYPE REF TO ltcl_client.
    DATA temp207 TYPE REF TO ltcl_layout_store.
    DATA temp73 TYPE xsdboolean.
    DATA temp21 LIKE sy-subrc.

    " set_draft( ): what is entered and not executed is kept with the
    " roundtrip
    mo_cut->set_draft( ).
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-enter ).

    lt_variant = mo_cut->mo_cgui_store->load( mo_cut->variant_key( ) ).


    READ TABLE lt_variant WITH KEY name = z2ui5_cl_cgui_memory=>draft_name( ) TRANSPORTING NO FIELDS.
    temp20 = sy-subrc.
    temp72 = boolc( temp20 = 0 ).
    cl_abap_unit_assert=>assert_true( temp72 ).

    " the next start brings it back, with Discard Draft

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp207 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp207 ).
    lo_next->set_draft( ).
    lo_next->z2ui5_if_app~main( lo_next_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_next->p_carrid
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_next_client->mv_view
                                         exp = `*Discard Draft*` ).
    " not in the variants to pick
    cl_abap_unit_assert=>assert_initial( lo_next->mv_cgui_variant ).

    " Execute uses it up
    lo_next_client->mv_init = abap_false.
    lo_next_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-execute.
    lo_next->z2ui5_if_app~main( lo_next_client ).
    lt_variant = mo_cut->mo_cgui_store->load( mo_cut->variant_key( ) ).


    READ TABLE lt_variant WITH KEY name = z2ui5_cl_cgui_memory=>draft_name( ) TRANSPORTING NO FIELDS.
    temp21 = sy-subrc.
    temp73 = boolc( temp21 = 0 ).
    cl_abap_unit_assert=>assert_false( temp73 ).

  ENDMETHOD.

  METHOD submit_using_screen.
    DATA temp208 TYPE REF TO ltcl_report.
    DATA lo_called LIKE temp208.
    DATA lo_client TYPE REF TO ltcl_client.
    DATA temp74 TYPE xsdboolean.
    DATA temp209 TYPE REF TO ltcl_report.

    " SUBMIT ... USING SELECTION-SCREEN 1100 VIA SELECTION-SCREEN: the
    " report shows screen 1100, not its selection screen
    init( ).
    mo_cut->submit( report                 = `LTCL_REPORT`
                    via_selection_screen   = abap_true
                    using_selection_screen = `1100` ).

    temp208 ?= mo_client->mo_called.

    lo_called = temp208.

    CREATE OBJECT lo_client TYPE ltcl_client.
    lo_client->mo_app = lo_called.
    lo_client->mv_init = abap_true.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_client->mv_view
                                         exp = `*Note on 1100*` ).

    temp74 = boolc( lo_client->mv_view CS `Report of a variant` ).
    cl_abap_unit_assert=>assert_false( temp74 ).

    " as a window: the selection screen as a dialog box over the caller -
    " no view of its own
    CLEAR mo_client->mo_called.
    mo_cut->submit( report    = `LTCL_REPORT`
                    as_window = abap_true ).

    temp209 ?= mo_client->mo_called.
    lo_called = temp209.
    CREATE OBJECT lo_client TYPE ltcl_client.
    lo_client->mo_app = lo_called.
    lo_client->mv_init = abap_true.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_initial( lo_client->mv_view ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_client->mv_popup
                                         exp = `*<Dialog*Report of a variant*Execute*` ).

    " Cancel closes it and returns to the caller
    lo_client->mv_init = abap_false.
    lo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-back.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_initial( lo_client->mv_popup ).
    cl_abap_unit_assert=>assert_true( lo_client->mv_left ).

  ENDMETHOD.

  METHOD value_help_entity.

    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.
    DATA temp210 TYPE string_table.
    DATA temp212 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp212.
    DATA temp75 TYPE xsdboolean.
    FIELD-SYMBOLS <temp213> LIKE LINE OF mo_cut->mt_cgui_field.
    DATA temp214 LIKE sy-tabix.

    " a row in the entity: the user parameters of the server store
    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_ENT`
                              value = `X` ).

    " F4 on the field: the rows of the entity, the element named the value

    CLEAR temp210.
    INSERT `P_VAR` INTO TABLE temp210.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp210 ).

    temp212 ?= mo_client->mo_called.

    lo_select = temp212.
    ASSIGN lo_select->mr_source->* TO <rows>.

    temp75 = boolc( lines( <rows> ) > 0 ).
    cl_abap_unit_assert=>assert_true( temp75 ).

    " an entity that does not exist: no popup, the message of no help
    CLEAR mo_client->mo_called.


    temp214 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_field WITH KEY name = `P_VAR` ASSIGNING <temp213>.
    sy-tabix = temp214.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp213>-entity = `ZZZ_NO_SUCH_ENTITY`.
    mo_cut->value_help_ddic( `P_VAR` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD parameter_levels.
    DATA temp215 TYPE z2ui5_if_client=>ty_t_name_value.
    DATA temp216 LIKE LINE OF temp215.
    DATA temp217 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp217.
    FIELD-SYMBOLS <temp218> LIKE LINE OF lo_popup->mt_field.
    DATA temp219 LIKE sy-tabix.
    FIELD-SYMBOLS <temp220> LIKE LINE OF lo_popup->mt_field.
    DATA temp221 LIKE sy-tabix.
    DATA lt_spa_store TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    FIELD-SYMBOLS <temp222> LIKE LINE OF lt_spa_store.
    DATA temp223 LIKE sy-tabix.
    DATA lo_next TYPE REF TO ltcl_report.
    DATA lo_next_client TYPE REF TO ltcl_client.
    DATA temp224 TYPE REF TO ltcl_layout_store.

    " GET PARAMETER ID: the user's parameter, else the customizing one, else
    " the system parameter given in code
    init( ).

    CLEAR temp215.

    temp216-n = `zcgui_lvl`.
    temp216-v = `SYS`.
    INSERT temp216 INTO TABLE temp215.
    temp216-n = `ZCGUI_SYS`.
    temp216-v = `S1`.
    INSERT temp216 INTO TABLE temp215.
    mo_cut->set_system_parameters( temp215 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `SYS` ).

    " SPRO without the authorization: refused, nothing opens
    mo_cut->okcode_execute( `/nSPRO` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " with it: the customizing parameters in a popup, one added
    mo_report->mv_customizing = abap_true.
    mo_cut->okcode_execute( `SPRO` ).

    temp217 ?= mo_client->mo_called.

    lo_popup = temp217.


    temp219 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_ID` ASSIGNING <temp218>.
    sy-tabix = temp219.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp218>-value = `zcgui_lvl`.


    temp221 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_VALUE` ASSIGNING <temp220>.
    sy-tabix = temp221.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp220>-value = `CUST`.
    mo_client->mv_event = `CGUI_POP_OK`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event.
    mo_client->mo_prev = lo_popup.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `CUST` ).
    " the system parameter where the customizing has none
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_SYS` )
                                        exp = `S1` ).

    " the user's own wins
    mo_cut->set_parameter_id( id    = `ZCGUI_LVL`
                              value = `USER` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `USER` ).

    " stored shared - the store gives other users only shared variants

    lt_spa_store = mo_cut->mo_cgui_store->load( `%SPA` ).


    temp223 = sy-tabix.
    READ TABLE lt_spa_store WITH KEY name = `%CUSTOMIZING` ASSIGNING <temp222>.
    sy-tabix = temp223.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp222>-shared ).

    " the customizing is on the server - the next report reads it, for a
    " user without a parameter of their own

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp224 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp224 ).
    lo_next->z2ui5_if_app~main( lo_next_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `USER` ).
    lo_next->mv_cgui_spa = ``.
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `CUST` ).

  ENDMETHOD.

  METHOD command_field.
    DATA temp225 TYPE REF TO ltcl_catalog.
    DATA temp76 TYPE xsdboolean.
    DATA lv_ctrl_k TYPE string.
    DATA temp77 TYPE xsdboolean.
    DATA temp22 LIKE sy-subrc.
    DATA temp23 LIKE sy-subrc.
    DATA temp24 LIKE sy-tabix.
    DATA lv_tab TYPE string.
    DATA temp78 TYPE xsdboolean.
    DATA temp25 LIKE sy-subrc.
    DATA temp26 LIKE sy-subrc.
    DATA temp27 LIKE sy-tabix.
    DATA lo_started TYPE REF TO z2ui5_cl_cgui_report.
    FIELD-SYMBOLS <temp226> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp227 LIKE sy-tabix.
    FIELD-SYMBOLS <temp228> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp229 LIKE sy-tabix.
    FIELD-SYMBOLS <temp230> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp231 LIKE sy-tabix.
    DATA lo_palette TYPE REF TO z2ui5_cl_cgui_select.
    DATA lt_rows TYPE z2ui5_cl_cgui_command=>ty_t_palette.
    DATA temp79 TYPE xsdboolean.
    DATA temp28 LIKE sy-subrc.
    DATA temp80 TYPE xsdboolean.
    DATA temp29 LIKE sy-subrc.

    mo_client->ms_get-s_config-origin = `https://host`.
    mo_client->ms_get-s_config-pathname = `/sap/bc/z2ui5`.
    mo_client->ms_get-s_config-search = `?sap-client=100&app_start=ltcl_report`.
    mo_cut->set_command_field( ).

    CREATE OBJECT temp225 TYPE ltcl_catalog.
    mo_cut->set_catalog( temp225 ).
    init( ).

    temp76 = boolc( mo_client->mv_view CS `CGUI_OKCODE` ).
    cl_abap_unit_assert=>assert_true( temp76 ).

    lv_ctrl_k = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:Ctrl+K\|CGUI_PALETTE\|MAIN|.




    temp23 = sy-subrc.
    temp24 = sy-tabix.
    READ TABLE mo_client->mt_action WITH KEY table_line = lv_ctrl_k TRANSPORTING NO FIELDS.
    temp22 = sy-subrc.
    sy-subrc = temp23.
    sy-tabix = temp24.
    temp77 = boolc( temp22 = 0 ).
    cl_abap_unit_assert=>assert_true( temp77 ).

    " an OK code of the screen - at_user_command( ), the field empty again
    mo_report->mv_cgui_okcode = ` mycmd `.
    event( z2ui5_cl_cgui_report=>cs_ucomm-okcode ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `MYCMD` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_cgui_okcode ).

    " /o and a transaction: a new tab with the report and its variant
    mo_cut->okcode_execute( `/oZFLY` ).

    lv_tab = |{ z2ui5_if_client=>cs_event-open_new_tab }:https://host/sap/bc/z2ui5?sap-client=100&app_start=z2ui5_cl_cgui_sample_04&variant=MINE|.




    temp26 = sy-subrc.
    temp27 = sy-tabix.
    READ TABLE mo_client->mt_action WITH KEY table_line = lv_tab TRANSPORTING NO FIELDS.
    temp25 = sy-subrc.
    sy-subrc = temp26.
    sy-tabix = temp27.
    temp78 = boolc( temp25 = 0 ).
    cl_abap_unit_assert=>assert_true( temp78 ).

    " the transaction in this window
    mo_cut->okcode_execute( `zfly` ).

    lo_started ?= mo_client->mo_called.
    cl_abap_unit_assert=>assert_bound( lo_started ).

    " what is no report and no command says so
    CLEAR mo_client->mo_called.
    mo_cut->okcode_execute( `/nZGONE` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp227 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX lines( mo_cut->mt_cgui_msg ) ASSIGNING <temp226>.
    sy-tabix = temp227.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp226>-text
                                         exp = `*ZGONE*` ).
    mo_cut->okcode_execute( `/x` ).


    temp229 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX lines( mo_cut->mt_cgui_msg ) ASSIGNING <temp228>.
    sy-tabix = temp229.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp228>-type
                                        exp = `E` ).

    " a class that is no report is not even created - its constructor wants
    " parameters
    mo_cut->okcode_execute( `/nZ2UI5_CL_CGUI_MSG` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp231 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX lines( mo_cut->mt_cgui_msg ) ASSIGNING <temp230>.
    sy-tabix = temp231.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp230>-text
                                         exp = `*Z2UI5_CL_CGUI_MSG*` ).
    cl_abap_unit_assert=>assert_not_bound( z2ui5_cl_cgui_command=>start_resolve( code    = `Z2UI5_CL_CGUI_LOG`
                                                                                 catalog = mo_cut->mo_cgui_catalog )-app ).
    cl_abap_unit_assert=>assert_bound( z2ui5_cl_cgui_command=>start_resolve( code    = `z2ui5_cl_cgui_sample_04`
                                                                             catalog = mo_cut->mo_cgui_catalog )-app ).

    " the code of the catalog in any case, as CALL TRANSACTION finds it
    mo_cut->okcode_execute( `ZLOW` ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    CLEAR mo_client->mo_called.

    " Ctrl+K: the palette - the transactions and Execute
    event( z2ui5_cl_cgui_report=>cs_ucomm-palette ).

    lo_palette ?= mo_client->mo_called.
    cl_abap_unit_assert=>assert_bound( lo_palette ).

    lt_rows = z2ui5_cl_cgui_command=>palette_rows( mo_cut->command_ctx( ) ).


    READ TABLE lt_rows WITH KEY command = `ZFLY` TRANSPORTING NO FIELDS.
    temp28 = sy-subrc.
    temp79 = boolc( temp28 = 0 ).
    cl_abap_unit_assert=>assert_true( temp79 ).


    READ TABLE lt_rows WITH KEY command = `ONLI` TRANSPORTING NO FIELDS.
    temp29 = sy-subrc.
    temp80 = boolc( temp29 = 0 ).
    cl_abap_unit_assert=>assert_true( temp80 ).

  ENDMETHOD.

  METHOD execute_in_background.

    DATA lo_job TYPE REF TO ltcl_job.
    DATA temp81 TYPE xsdboolean.
    DATA temp82 TYPE xsdboolean.
    DATA temp30 LIKE sy-subrc.
    DATA temp31 LIKE sy-subrc.
    DATA temp32 LIKE sy-tabix.
    FIELD-SYMBOLS <temp232> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp233 LIKE sy-tabix.
    DATA lo_run TYPE REF TO ltcl_report.
    DATA lv_pdf TYPE xstring.
    CREATE OBJECT lo_job TYPE ltcl_job.
    mo_cut->set_job( lo_job ).
    init( ).

    temp81 = boolc( mo_client->mv_view CS `CGUI_BACKGROUND` ).
    cl_abap_unit_assert=>assert_true( temp81 ).

    " the checks of Execute first - the required field is empty
    event( z2ui5_cl_cgui_report=>cs_ucomm-background ).
    cl_abap_unit_assert=>assert_initial( lo_job->mv_report ).

    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-background ).
    cl_abap_unit_assert=>assert_equals( act = lo_job->mv_report
                                        exp = `LTCL_REPORT` ).




    temp31 = sy-subrc.
    temp32 = sy-tabix.
    READ TABLE lo_job->mt_values WITH KEY name = `P_CARRID` low = `LH` TRANSPORTING NO FIELDS.
    temp30 = sy-subrc.
    sy-subrc = temp31.
    sy-tabix = temp32.
    temp82 = boolc( temp30 = 0 ).
    cl_abap_unit_assert=>assert_true( temp82 ).


    temp233 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX 1 ASSIGNING <temp232>.
    sy-tabix = temp233.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp232>-text
                                         exp = `*4711*` ).
    " the selection screen stays - the report did not run here
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).

    " the job's side: the run without a browser, its printout as a PDF

    CREATE OBJECT lo_run TYPE ltcl_report.

    lo_run->cgui_run_in_background( EXPORTING values = lo_job->mt_values
                                    IMPORTING pdf    = lv_pdf ).
    cl_abap_unit_assert=>assert_char_cp( act = z2ui5_cl_cgui_context=>conv_get_string_by_xstring( lv_pdf )
                                         exp = `%PDF-*(HEADER) Tj*` ).

  ENDMETHOD.

  METHOD input_history.

    DATA lv_tab LIKE cl_abap_char_utilities=>horizontal_tab.
    DATA temp83 TYPE xsdboolean.
    DATA temp84 TYPE xsdboolean.
    DATA lv_history LIKE mo_report->mv_cgui_history.
    lv_tab = cl_abap_char_utilities=>horizontal_tab.

    " two runs: the latest entry first, each once
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    mo_report->p_carrid = `UA`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).


    temp83 = boolc( mo_report->mv_cgui_history CS |P_CARRID{ lv_tab }LH{ lv_tab }UA| ).
    cl_abap_unit_assert=>assert_true( temp83 ).

    temp84 = boolc( mo_report->mv_cgui_history CS |UA{ lv_tab }LH| ).
    cl_abap_unit_assert=>assert_false( temp84 ).

    " a new start with set_prefill_last( ): the empty field takes LH

    lv_history = mo_report->mv_cgui_history.
    CREATE OBJECT mo_report.
    mo_cut = mo_report.
    CREATE OBJECT mo_client.
    mo_client->mo_app = mo_report.
    mo_cut->set_prefill_last( ).
    init( ).
    mo_report->mv_cgui_history = lv_history.
    event( z2ui5_cl_cgui_report=>cs_ucomm-variants_loaded ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).

  ENDMETHOD.

  METHOD shortcuts_registered.
    DATA lv_f8 TYPE string.
    DATA lv_f3 TYPE string.
    DATA temp85 TYPE xsdboolean.
    DATA temp33 LIKE sy-subrc.
    DATA temp86 TYPE xsdboolean.
    DATA temp34 LIKE sy-subrc.

    init( ).


    lv_f8 = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:F8\|CGUI_EXECUTE\|MAIN|.

    lv_f3 = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:F3\|CGUI_BACK\|MAIN|.


    READ TABLE mo_client->mt_action WITH KEY table_line = lv_f8 TRANSPORTING NO FIELDS.
    temp33 = sy-subrc.
    temp85 = boolc( temp33 = 0 ).
    cl_abap_unit_assert=>assert_true( temp85 ).


    READ TABLE mo_client->mt_action WITH KEY table_line = lv_f3 TRANSPORTING NO FIELDS.
    temp34 = sy-subrc.
    temp86 = boolc( temp34 = 0 ).
    cl_abap_unit_assert=>assert_true( temp86 ).

  ENDMETHOD.

  METHOD f8_on_output_ignored.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_report->mv_end = abap_false.

    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_false( mo_report->mv_end ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD run_in_background.

    " no client at all - the run of the background program
    DATA temp234 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp235 LIKE LINE OF temp234.
    DATA lo_list TYPE REF TO z2ui5_cl_cgui_list.
    DATA lt_msg TYPE z2ui5_cl_cgui_report=>ty_t_cgui_message.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp236> LIKE LINE OF lt_text.
    DATA temp237 LIKE sy-tabix.
    DATA lo_empty TYPE REF TO ltcl_report.
    DATA temp238 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lo_none TYPE REF TO z2ui5_cl_cgui_list.
    DATA lt_error TYPE z2ui5_cl_cgui_report=>ty_t_cgui_message.
    FIELD-SYMBOLS <temp239> LIKE LINE OF lt_error.
    DATA temp240 LIKE sy-tabix.
    CLEAR temp234.

    temp235-name = `P_CARRID`.
    temp235-kind = `P`.
    temp235-low = `LH`.
    INSERT temp235 INTO TABLE temp234.


    mo_report->cgui_run_in_background(
      EXPORTING values   = temp234
      IMPORTING list     = lo_list
                messages = lt_msg ).

    cl_abap_unit_assert=>assert_bound( lo_list ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).

    lt_text = lo_list->to_text( ).


    temp237 = sy-tabix.
    READ TABLE lt_text INDEX 1 ASSIGNING <temp236>.
    sy-tabix = temp237.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp236>
                                        exp = `HEADER` ).
    cl_abap_unit_assert=>assert_initial( lt_msg ).

    " a required field missing - no output, the error as message

    CREATE OBJECT lo_empty TYPE ltcl_report.

    CLEAR temp238.


    lo_empty->cgui_run_in_background( EXPORTING values   = temp238
                                      IMPORTING list     = lo_none
                                                messages = lt_error ).
    cl_abap_unit_assert=>assert_not_bound( lo_none ).


    temp240 = sy-tabix.
    READ TABLE lt_error INDEX 1 ASSIGNING <temp239>.
    sy-tabix = temp240.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp239>-type
                                        exp = `E` ).

  ENDMETHOD.

  METHOD range_popup_leave.

    result ?= mo_client->mo_called.
    mo_client->mv_event = event.
    mo_client->mt_arg = args.
    result->z2ui5_if_app~main( mo_client ).

    " back in the report
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = result.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD range_popup_keeps_exclude.

    DATA temp241 LIKE mo_report->s_code.
    DATA temp242 LIKE LINE OF temp241.
    DATA temp243 TYPE string_table.
    DATA temp245 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_popup LIKE temp245.
    FIELD-SYMBOLS <temp246> LIKE LINE OF lo_popup->mt_row.
    DATA temp247 LIKE sy-tabix.
    FIELD-SYMBOLS <temp248> LIKE LINE OF mo_report->s_code.
    DATA temp249 LIKE sy-tabix.
    FIELD-SYMBOLS <temp250> LIKE LINE OF mo_report->s_code.
    DATA temp251 LIKE sy-tabix.
    CLEAR temp241.

    temp242-sign = `I`.
    temp242-option = `EQ`.
    temp242-low = `A`.
    INSERT temp242 INTO TABLE temp241.
    temp242-sign = `E`.
    temp242-option = `EQ`.
    temp242-low = `B`.
    INSERT temp242 INTO TABLE temp241.
    mo_report->s_code = temp241.
    init( ).

    CLEAR temp243.
    INSERT `S_CODE` INTO TABLE temp243.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp243 ).


    temp245 ?= mo_client->mo_called.

    lo_popup = temp245.
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 2 ).


    temp247 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 2 ASSIGNING <temp246>.
    sy-tabix = temp247.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp246>-low = `c`.
    range_popup_leave( z2ui5_cl_cgui_range=>cs_event-ok ).

    " the excluding line stays one - and is in upper case like the field


    temp249 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 2 ASSIGNING <temp248>.
    sy-tabix = temp249.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp248>-sign
                                        exp = `E` ).


    temp251 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 2 ASSIGNING <temp250>.
    sy-tabix = temp251.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp250>-low
                                        exp = `C` ).

  ENDMETHOD.

  METHOD range_f4_returns_to_popup.

    DATA temp252 LIKE mo_report->s_code.
    DATA temp253 LIKE LINE OF temp252.
    DATA temp254 TYPE string_table.
    DATA temp256 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_first LIKE temp256.
    DATA temp257 TYPE string_table.
    FIELD-SYMBOLS <temp12> LIKE LINE OF lo_first->mt_row.
    DATA temp13 LIKE sy-tabix.
    DATA temp259 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_again LIKE temp259.
    DATA temp87 TYPE xsdboolean.
    FIELD-SYMBOLS <temp260> LIKE LINE OF lo_again->mt_row.
    DATA temp261 LIKE sy-tabix.
    CLEAR temp252.

    temp253-sign = `E`.
    temp253-option = `EQ`.
    temp253-low = `B`.
    INSERT temp253 INTO TABLE temp252.
    mo_report->s_code = temp252.
    init( ).

    CLEAR temp254.
    INSERT `S_CODE` INTO TABLE temp254.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp254 ).

    temp256 ?= mo_client->mo_called.

    lo_first = temp256.

    " F4 on line 1: the code has no value help - the report says so and
    " opens the popup again with the lines as they were

    CLEAR temp257.


    temp13 = sy-tabix.
    READ TABLE lo_first->mt_row INDEX 1 ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    INSERT <temp12>-key INTO TABLE temp257.
    INSERT `LOW` INTO TABLE temp257.
    range_popup_leave( event = z2ui5_cl_cgui_range=>cs_event-f4
                       args  = temp257 ).

    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

    temp259 ?= mo_client->mo_called.

    lo_again = temp259.

    temp87 = boolc( lo_again = lo_first ).
    cl_abap_unit_assert=>assert_false( temp87 ).


    temp261 = sy-tabix.
    READ TABLE lo_again->mt_row INDEX 1 ASSIGNING <temp260>.
    sy-tabix = temp261.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp260>-sign
                                        exp = `E` ).
    cl_abap_unit_assert=>assert_false( mo_cut->mv_cgui_range_f4 ).
    " the select-option itself is untouched until OK
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 1 ).

  ENDMETHOD.

  METHOD f4_keeps_other_lines.

    DATA lt_pick TYPE ty_t_pick.
    DATA temp262 LIKE mo_report->s_code.
    DATA temp263 LIKE LINE OF temp262.
    DATA temp264 TYPE ltcl_test=>ty_t_pick.
    DATA temp265 LIKE LINE OF temp264.
    DATA lo_select TYPE REF TO z2ui5_cl_cgui_select.
    DATA temp88 TYPE xsdboolean.
    DATA temp35 LIKE sy-subrc.
    DATA temp89 TYPE xsdboolean.
    DATA temp36 LIKE sy-subrc.
    DATA temp90 TYPE xsdboolean.
    DATA temp37 LIKE sy-subrc.

    init( ).

    CLEAR temp262.

    CLEAR temp263.
    temp263-sign = `I`.
    temp263-option = `BT`.
    temp263-low = `A`.
    temp263-high = `C`.
    INSERT temp263 INTO TABLE temp262.
    CLEAR temp263.
    temp263-sign = `I`.
    temp263-option = `EQ`.
    temp263-low = `Q`.
    INSERT temp263 INTO TABLE temp262.
    CLEAR temp263.
    temp263-sign = `E`.
    temp263-option = `EQ`.
    temp263-low = `B`.
    INSERT temp263 INTO TABLE temp262.
    mo_report->s_code = temp262.

    CLEAR temp264.

    temp265-value = `X`.
    INSERT temp265 INTO TABLE temp264.
    temp265-value = `Y`.
    INSERT temp265 INTO TABLE temp264.
    lt_pick = temp264.

    lo_select = z2ui5_cl_cgui_select=>factory( tab         = lt_pick
                                                     multiselect = abap_true ).
    lo_select->select_row( 1 ).
    lo_select->select_row( 2 ).
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR mo_client->mv_event.
    mo_client->mo_prev = lo_select.

    mo_cut->on_f4_result( field = `S_CODE`
                          col   = `VALUE` ).

    " Q gave way to X and Y - the interval and the exclusion stay
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 4 ).


    READ TABLE mo_report->s_code WITH KEY option = `BT` low = `A` TRANSPORTING NO FIELDS.
    temp35 = sy-subrc.
    temp88 = boolc( temp35 = 0 ).
    cl_abap_unit_assert=>assert_true( temp88 ).


    READ TABLE mo_report->s_code WITH KEY sign = `E` low = `B` TRANSPORTING NO FIELDS.
    temp36 = sy-subrc.
    temp89 = boolc( temp36 = 0 ).
    cl_abap_unit_assert=>assert_true( temp89 ).


    READ TABLE mo_report->s_code WITH KEY low = `Q` TRANSPORTING NO FIELDS.
    temp37 = sy-subrc.
    temp90 = boolc( temp37 = 0 ).
    cl_abap_unit_assert=>assert_false( temp90 ).

  ENDMETHOD.

  METHOD popup_values_of_an_sval.

    TYPES:
      BEGIN OF ty_s_sval,
        tabname   TYPE c LENGTH 30,
        fieldname TYPE c LENGTH 30,
        value     TYPE c LENGTH 132,
        fieldtext TYPE c LENGTH 60,
        field_obl TYPE c LENGTH 1,
      END OF ty_s_sval.
    TYPES temp9 TYPE STANDARD TABLE OF ty_s_sval WITH DEFAULT KEY.
DATA lt_sval TYPE temp9.
    DATA temp266 LIKE lt_sval.
    DATA temp267 LIKE LINE OF temp266.
    DATA temp268 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp268.
    FIELD-SYMBOLS <temp269> LIKE LINE OF lo_popup->mt_field.
    DATA temp270 LIKE sy-tabix.
    FIELD-SYMBOLS <temp271> LIKE LINE OF lo_popup->mt_field.
    DATA temp272 LIKE sy-tabix.
    FIELD-SYMBOLS <temp273> LIKE LINE OF lo_popup->mt_field.
    DATA temp274 LIKE sy-tabix.
    FIELD-SYMBOLS <temp275> LIKE LINE OF lo_popup->mt_field.
    DATA temp276 LIKE sy-tabix.
    FIELD-SYMBOLS <temp277> LIKE LINE OF lo_popup->mt_field.
    DATA temp278 LIKE sy-tabix.
    DATA temp279 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA temp280 LIKE LINE OF temp279.
    FIELD-SYMBOLS <temp281> LIKE LINE OF lt_sval.
    DATA temp282 LIKE sy-tabix.
    FIELD-SYMBOLS <temp283> LIKE LINE OF lt_sval.
    DATA temp284 LIKE sy-tabix.
    FIELD-SYMBOLS <temp285> LIKE LINE OF lt_sval.
    DATA temp286 LIKE sy-tabix.

    init( ).

    CLEAR temp266.

    CLEAR temp267.
    temp267-tabname = 'SFLIGHT'.
    temp267-fieldname = 'carrid'.
    temp267-fieldtext = 'Airline'.
    temp267-value = 'LH'.
    temp267-field_obl = 'X'.
    INSERT temp267 INTO TABLE temp266.
    CLEAR temp267.
    temp267-tabname = 'SFLIGHT'.
    temp267-fieldname = 'CONNID'.
    INSERT temp267 INTO TABLE temp266.
    lt_sval = temp266.
    mo_cut->popup_get_values_sval( sval  = lt_sval
                                   ucomm = `VALUES`
                                   title = `Flight` ).

    temp268 ?= mo_client->mo_called.

    lo_popup = temp268.


    temp270 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp269>.
    sy-tabix = temp270.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp269>-name
                                        exp = `CARRID` ).


    temp272 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp271>.
    sy-tabix = temp272.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp271>-text
                                        exp = `Airline` ).


    temp274 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp273>.
    sy-tabix = temp274.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp273>-value
                                        exp = `LH` ).


    temp276 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp275>.
    sy-tabix = temp276.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp275>-required ).


    temp278 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 2 ASSIGNING <temp277>.
    sy-tabix = temp278.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp277>-text
                                        exp = `CONNID` ).

    " what the user entered, back into the table - and into an empty one

    CLEAR temp279.

    temp280-name = `CARRID`.
    temp280-text = `Airline`.
    temp280-value = `AA`.
    INSERT temp280 INTO TABLE temp279.
    temp280-name = `CONNID`.
    temp280-text = `CONNID`.
    temp280-value = `0017`.
    INSERT temp280 INTO TABLE temp279.
    mo_cut->mt_cgui_popup_values = temp279.
    mo_cut->popup_values_sval( CHANGING sval = lt_sval ).


    temp282 = sy-tabix.
    READ TABLE lt_sval INDEX 2 ASSIGNING <temp281>.
    sy-tabix = temp282.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp281>-value
                                        exp = `0017` ).


    temp284 = sy-tabix.
    READ TABLE lt_sval INDEX 1 ASSIGNING <temp283>.
    sy-tabix = temp284.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp283>-tabname
                                        exp = `SFLIGHT` ).
    CLEAR lt_sval.
    mo_cut->popup_values_sval( CHANGING sval = lt_sval ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_sval )
                                        exp = 2 ).


    temp286 = sy-tabix.
    READ TABLE lt_sval INDEX 1 ASSIGNING <temp285>.
    sy-tabix = temp286.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp285>-fieldname
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD popups_of_the_project.
        DATA temp287 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA temp288 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA temp289 LIKE LINE OF temp288.
    DATA temp14 TYPE z2ui5_cl_cgui_popup=>ty_t_listbox.
    DATA temp15 LIKE LINE OF temp14.
    DATA lo_values TYPE REF TO z2ui5_cl_cgui_popup.
    FIELD-SYMBOLS <temp290> LIKE LINE OF lo_values->mt_field.
    DATA temp291 LIKE sy-tabix.
    DATA temp16 TYPE string_table.
    DATA temp292 LIKE mo_report->s_code.
    DATA temp293 LIKE LINE OF temp292.
    DATA temp294 TYPE ty_t_pick.
    DATA temp295 LIKE LINE OF temp294.
        DATA temp296 TYPE REF TO z2ui5_cl_cgui_select.

    " every popup of the runtime is a class of the project
    init( ).
    mo_cut->popup_to_confirm( question = `Sure?`
                              ucomm    = `DO_IT` ).
    TRY.

        temp287 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp287 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_popup` ).
    ENDTRY.

    " OK leaves with the user command
    mo_client->mv_event = `CGUI_POP_OK`.
    mo_client->mo_called->main( mo_client ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    CLEAR mo_client->mv_event.

    " a required multi listbox: what is picked counts, not the value

    CLEAR temp288.

    temp289-name = `CARRIERS`.
    temp289-text = `Carriers`.
    temp289-kind = z2ui5_cl_cgui_popup=>cs_kind-multi.
    temp289-required = abap_true.
    INSERT temp289 INTO TABLE temp288.

    CLEAR temp14.

    temp15-name = `CARRIERS`.
    temp15-key = `LH`.
    temp15-text = `Lufthansa`.
    INSERT temp15 INTO TABLE temp14.

    lo_values = z2ui5_cl_cgui_popup=>get_values(
        fields  = temp288
        listbox = temp14
        event   = `PICKED` ).
    " the popup binds its own attributes
    mo_client->mo_app = lo_values.
    mo_client->mv_left = abap_false.
    mo_client->mv_event = `CGUI_POP_OK`.
    lo_values->z2ui5_if_app~main( mo_client ).
    cl_abap_unit_assert=>assert_false( mo_client->mv_left ).


    temp291 = sy-tabix.
    READ TABLE lo_values->mt_field INDEX 1 ASSIGNING <temp290>.
    sy-tabix = temp291.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.

    CLEAR temp16.
    INSERT `LH` INTO TABLE temp16.
    <temp290>-keys = temp16.
    lo_values->z2ui5_if_app~main( mo_client ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    CLEAR mo_client->mv_event.
    mo_client->mo_app = mo_report.


    CLEAR temp292.

    temp293-sign = `I`.
    temp293-option = `EQ`.
    temp293-low = `A`.
    INSERT temp293 INTO TABLE temp292.
    mo_report->s_code = temp292.
    mo_cut->mv_cgui_value_field = `S_CODE`.

    CLEAR temp294.

    temp295-value = `A`.
    INSERT temp295 INTO TABLE temp294.
    temp295-value = `B`.
    INSERT temp295 INTO TABLE temp294.
    mo_cut->value_help_popup( tab = temp294
                              col = `VALUE` ).
    TRY.

        temp296 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp296 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.

  ENDMETHOD.

  METHOD messages_after_popup.

    DATA lv_open TYPE string.
    DATA lv_action LIKE LINE OF mo_client->mt_action.
      DATA temp91 TYPE xsdboolean.
    DATA temp92 TYPE xsdboolean.
    DATA temp38 LIKE sy-subrc.
    DATA lv_armed LIKE abap_false.
    lv_open = |*{ z2ui5_cl_cgui_report=>cs_ucomm-messages_open }*|.

    init( ).
    " a warning of the roundtrip that opened a popup - the popup covers the
    " screen, the popover waits for it
    mo_cut->message( text = `Careful`
                     type = `W` ).
    mo_cut->mv_cgui_nav = abap_true.
    mo_cut->messages_display( ).

    LOOP AT mo_client->mt_action INTO lv_action.

      temp91 = boolc( lv_action CP lv_open ).
      cl_abap_unit_assert=>assert_false( temp91 ).
    ENDLOOP.

    " back on the screen: the warning is still in the log, the popover opens
    CLEAR mo_client->mt_action.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.


    READ TABLE mo_cut->mt_cgui_log WITH KEY text = `Careful` TRANSPORTING NO FIELDS.
    temp38 = sy-subrc.
    temp92 = boolc( temp38 = 0 ).
    cl_abap_unit_assert=>assert_true( temp92 ).

    lv_armed = abap_false.
    LOOP AT mo_client->mt_action INTO lv_action.
      IF lv_action CP lv_open.
        lv_armed = abap_true.
      ENDIF.
    ENDLOOP.
    cl_abap_unit_assert=>assert_true( lv_armed ).

    " an I message and a box of _msg_box( ) - one box with both
    CLEAR: mo_cut->mt_cgui_msg, mo_cut->mt_cgui_box, mo_client->mv_box.
    mo_cut->mv_cgui_nav = abap_false.
    mo_cut->message( text = `Note`
                     type = `I` ).
    mo_cut->_msg_box( )->w( `Boxed` ).
    mo_cut->messages_display( ).
    cl_abap_unit_assert=>assert_char_cp( exp = `Note*Boxed`
                                         act = mo_client->mv_box ).
    cl_abap_unit_assert=>assert_equals( exp = `warning`
                                        act = mo_client->mv_box_type ).

  ENDMETHOD.

  METHOD short_api.
    FIELD-SYMBOLS <temp297> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp298 LIKE sy-tabix.
    DATA temp299 TYPE string_table.
        DATA temp301 TYPE REF TO z2ui5_cl_cgui_popup.

    init( ).
    " _msg( ): message( ), the methods chain - a warning and a toast
    mo_cut->_msg( )->w( `Careful` )->s( `Done` ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( mo_cut->mt_cgui_msg ) ).


    temp298 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX 1 ASSIGNING <temp297>.
    sy-tabix = temp298.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `W`
                                        act = <temp297>-type ).
    cl_abap_unit_assert=>assert_false( mo_cut->mv_cgui_stop ).
    " _msg_box( ): a box of its own - an error does not stop the run
    mo_cut->_msg_box( )->i( `Saved` )->e( `But the mail failed` ).
    cl_abap_unit_assert=>assert_false( mo_cut->mv_cgui_stop ).
    mo_cut->messages_display( ).
    cl_abap_unit_assert=>assert_equals( exp = `error`
                                        act = mo_client->mv_box_type ).
    cl_abap_unit_assert=>assert_char_cp( exp = `Saved*But the mail failed`
                                         act = mo_client->mv_box ).
    " _msg( )->e( ): as MESSAGE TYPE 'E' - the run stops
    mo_cut->_msg( )->e( `Wrong` ).
    cl_abap_unit_assert=>assert_true( mo_cut->mv_cgui_stop ).

    " _popup( ): the popups of the report

    CLEAR temp299.
    INSERT `First` INTO TABLE temp299.
    INSERT `Second` INTO TABLE temp299.
    mo_cut->_popup( )->decide( question = `Which one?`
                               options  = temp299
                               ucomm    = `PICK` ).
    TRY.

        temp301 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp301 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_popup` ).
    ENDTRY.
    CLEAR mo_client->mo_called.
    mo_cut->_popup( )->confirm( question = `Sure?`
                                ucomm    = `DO_IT` ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD alv_layout_default.
    DATA temp93 TYPE xsdboolean.
    DATA temp302 TYPE REF TO z2ui5_cl_cgui_layout.
    DATA lo_layout LIKE temp302.
    FIELD-SYMBOLS <temp303> LIKE LINE OF lo_layout->mt_row.
    DATA temp304 LIKE sy-tabix.
    DATA temp94 TYPE xsdboolean.
    DATA temp305 TYPE REF TO ltcl_layout_store.
    DATA lo_store LIKE temp305.
    FIELD-SYMBOLS <temp306> LIKE LINE OF lo_store->mt_layout.
    DATA temp307 LIKE sy-tabix.
    DATA lt_catalog TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp95 TYPE xsdboolean.
    DATA temp39 LIKE sy-subrc.
    DATA temp96 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    temp93 = boolc( mo_client->mv_view CS `sortProperty="SEATS"` ).
    cl_abap_unit_assert=>assert_true( temp93 ).

    " the layout button opens the dialog - SEATS hidden, saved as default
    event( z2ui5_cl_cgui_alv=>cs_event-layout ).

    temp302 ?= mo_client->mo_called.

    lo_layout = temp302.


    temp304 = sy-tabix.
    READ TABLE lo_layout->mt_row WITH KEY name = `SEATS` ASSIGNING <temp303>.
    sy-tabix = temp304.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp303>-visible = abap_false.
    lo_layout->mv_name = `MINE`.
    lo_layout->mv_default = abap_true.
    mo_client->mv_event = z2ui5_cl_cgui_layout=>cs_event-ok.
    lo_layout->z2ui5_if_app~main( mo_client ).
    CLEAR mo_client->mv_event.
    mo_client->mo_prev = lo_layout.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).

    temp94 = boolc( mo_client->mv_view CS `sortProperty="SEATS"` ).
    cl_abap_unit_assert=>assert_false( temp94 ).
    " kept in the layout store, under the attribute the ALV shows

    temp305 ?= mo_cut->mo_cgui_lay_store.

    lo_store = temp305.


    temp307 = sy-tabix.
    READ TABLE lo_store->mt_layout WITH KEY name = `MINE` ASSIGNING <temp306>.
    sy-tabix = temp307.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp306>-is_default ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->layout_handle( )
                                        exp = `MT_ROW` ).

    lt_catalog = z2ui5_cl_cgui_memory=>variant_catalog( mo_cut->memory_ctx( ) ).


    READ TABLE lt_catalog WITH KEY name = `#L#MINE` TRANSPORTING NO FIELDS.
    temp39 = sy-subrc.
    temp95 = boolc( temp39 = 0 ).
    cl_abap_unit_assert=>assert_false( temp95 ).

    " the next run starts with the default layout - the switch of the test
    " is no field of the screen, the restart after the list resets it
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    mo_report->mv_alv = abap_true.
    CLEAR mo_cut->mv_cgui_layout.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).

    temp96 = boolc( mo_client->mv_view CS `sortProperty="SEATS"` ).
    cl_abap_unit_assert=>assert_false( temp96 ).

  ENDMETHOD.

  METHOD alv_layout_without_store.
    DATA temp308 TYPE REF TO z2ui5_cl_cgui_layout.
    DATA lo_layout LIKE temp308.
    FIELD-SYMBOLS <temp309> LIKE LINE OF lo_layout->mt_row.
    DATA temp310 LIKE sy-tabix.
    DATA lt_catalog TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp97 TYPE xsdboolean.
    DATA temp40 LIKE sy-subrc.

    " no layout store - the layouts are kept with the selection variants
    mo_cut->set_layout_store( ).
    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    event( z2ui5_cl_cgui_alv=>cs_event-layout ).

    temp308 ?= mo_client->mo_called.

    lo_layout = temp308.



    temp310 = sy-tabix.
    READ TABLE lo_layout->mt_row WITH KEY name = `SEATS` ASSIGNING <temp309>.
    sy-tabix = temp310.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp309>-visible = abap_false.
    lo_layout->mv_name = `MINE`.
    lo_layout->mv_default = abap_true.
    mo_client->mv_event = z2ui5_cl_cgui_layout=>cs_event-ok.
    lo_layout->z2ui5_if_app~main( mo_client ).
    CLEAR mo_client->mv_event.
    mo_client->mo_prev = lo_layout.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).
    " kept as a variant - but none the variant popup offers

    lt_catalog = z2ui5_cl_cgui_memory=>variant_catalog( mo_cut->memory_ctx( ) ).


    READ TABLE lt_catalog WITH KEY name = `#L#MINE` TRANSPORTING NO FIELDS.
    temp40 = sy-subrc.
    temp97 = boolc( temp40 = 0 ).
    cl_abap_unit_assert=>assert_true( temp97 ).

  ENDMETHOD.

  METHOD value_check_and_block.
    DATA temp98 TYPE xsdboolean.
    DATA temp41 LIKE sy-subrc.
    DATA temp99 TYPE xsdboolean.
    DATA temp42 LIKE sy-subrc.


    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->p_check = `Q`.
    mo_report->p_text = `BAD`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " VALUE CHECK stops the run at the field - before ON BLOCK, and before
    " the ON field of the report, as the checks of the screen do
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).


    READ TABLE mo_cut->mt_cgui_log WITH KEY type = `E` field = `P_CHECK` TRANSPORTING NO FIELDS.
    temp41 = sy-subrc.
    temp98 = boolc( temp41 = 0 ).
    cl_abap_unit_assert=>assert_true( temp98 ).


    READ TABLE mo_cut->mt_cgui_log WITH KEY text = `Not this text` TRANSPORTING NO FIELDS.
    temp42 = sy-subrc.
    temp99 = boolc( temp42 = 0 ).
    cl_abap_unit_assert=>assert_false( temp99 ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_block ).

    mo_report->p_text = ``.
    mo_report->p_check = `X`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_block
                                        exp = `B1` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD footer_print_function_key.
    DATA temp100 TYPE xsdboolean.
    DATA temp311 TYPE z2ui5_cl_cgui_alv=>ty_t_function.
    DATA temp312 LIKE LINE OF temp311.
    DATA temp101 TYPE xsdboolean.
    DATA temp102 TYPE xsdboolean.
    DATA temp103 TYPE xsdboolean.
    DATA temp43 LIKE sy-subrc.
    DATA temp104 TYPE xsdboolean.
    DATA temp44 LIKE sy-subrc.
    DATA temp105 TYPE xsdboolean.
    DATA temp106 TYPE xsdboolean.
    DATA temp107 TYPE xsdboolean.
    DATA lt_print TYPE string_table.
    DATA temp108 TYPE xsdboolean.
    DATA temp45 LIKE sy-subrc.
    DATA temp109 TYPE xsdboolean.
    DATA temp46 LIKE sy-subrc.

    init( ).
    " the function key of the selection screen

    temp100 = boolc( mo_client->mv_view CS `EVENT:FC01` ).
    cl_abap_unit_assert=>assert_true( temp100 ).
    event( `FC01` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `FC01` ).

    mo_report->p_carrid = `LH`.
    " a status set before the run is the selection screen's - the list
    " has the one START-OF-SELECTION sets

    CLEAR temp311.

    temp312-name = `EARLY`.
    temp312-text = `Early`.
    INSERT temp312 INTO TABLE temp311.
    mo_cut->set_pf_status( temp311 ).
    mo_report->mv_status = abap_true.
    CLEAR mo_client->mt_action.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " EXCLUDING leaves out the button and the key of DELE

    temp101 = boolc( mo_client->mv_view CS `EVENT:DELE` ).
    cl_abap_unit_assert=>assert_false( temp101 ).

    temp102 = boolc( mo_client->mv_view CS `EVENT:EARLY` ).
    cl_abap_unit_assert=>assert_false( temp102 ).


    READ TABLE mo_client->mt_action WITH KEY table_line = `KEYBOARD_SHORTCUT:F5|SAVE|MAIN` TRANSPORTING NO FIELDS.
    temp43 = sy-subrc.
    temp103 = boolc( temp43 = 0 ).
    cl_abap_unit_assert=>assert_true( temp103 ).


    READ TABLE mo_client->mt_action WITH KEY table_line = `KEYBOARD_SHORTCUT:Shift+F2|DELE|MAIN` TRANSPORTING NO FIELDS.
    temp44 = sy-subrc.
    temp104 = boolc( temp44 = 0 ).
    cl_abap_unit_assert=>assert_false( temp104 ).

    " END-OF-PAGE with the page number, the PF-STATUS and print

    temp105 = boolc( mo_client->mv_view CS `FOOT 1` ).
    cl_abap_unit_assert=>assert_true( temp105 ).

    temp106 = boolc( mo_client->mv_view CS `EVENT:SAVE` ).
    cl_abap_unit_assert=>assert_true( temp106 ).

    temp107 = boolc( mo_client->mv_view CS `EVENT:CGUI_PRINT` ).
    cl_abap_unit_assert=>assert_true( temp107 ).

    lt_print = mo_cut->print_lines( ).


    READ TABLE lt_print WITH KEY table_line = `row1` TRANSPORTING NO FIELDS.
    temp45 = sy-subrc.
    temp108 = boolc( temp45 = 0 ).
    cl_abap_unit_assert=>assert_true( temp108 ).


    READ TABLE lt_print WITH KEY table_line = `FOOT 1` TRANSPORTING NO FIELDS.
    temp46 = sy-subrc.
    temp109 = boolc( temp46 = 0 ).
    cl_abap_unit_assert=>assert_true( temp109 ).

  ENDMETHOD.

  METHOD alv_paging_maps_rows.

    DATA ls_request TYPE z2ui5_if_client=>ty_s_window_request.
    DATA temp313 TYPE string_table.
    DATA temp315 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp110 TYPE xsdboolean.
    DATA temp317 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp18 TYPE z2ui5_if_client=>ty_t_bind_tab_sort.
    DATA temp19 LIKE LINE OF temp18.
    DATA temp319 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp321 TYPE string_table.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->mt_row )
                                        exp = 3 ).

    " one row a window: the grid binds a copy with the rows loaded with
    " window_bind_tab( ), the total and the title count all rows
    mo_cut->mo_cgui_alv->set_paging( 1 ).

    CLEAR temp313.
    INSERT `` INTO TABLE temp313.
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = temp313 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_bound( mo_cut->mr_cgui_alv_page ).

    CLEAR temp315.
    INSERT 1 INTO TABLE temp315.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_alv_index
                                        exp = temp315 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_alv_total
                                        exp = 3 ).

    temp110 = boolc( mo_client->mv_view CS `(3)` ).
    cl_abap_unit_assert=>assert_true( temp110 ).

    " the grid asks for more rows: the next one of the order follows, the
    " screen is not drawn again
    CLEAR mo_client->mv_view.
    CLEAR ls_request.
    ls_request-path = `/MR_CGUI_ALV_PAGE/*`.
    ls_request-reason = z2ui5_if_client=>cs_window_reason-more.
    ls_request-skip = 1.
    ls_request-top = 1.
    GET REFERENCE OF ls_request INTO mo_client->ms_get-r_event_data.
    event( z2ui5_cl_cgui_alv=>cs_event-rows ).

    CLEAR temp317.
    INSERT 1 INTO TABLE temp317.
    INSERT 2 INTO TABLE temp317.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_alv_index
                                        exp = temp317 ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_view ).

    " a sort of a column menu: the first rows anew, over all rows - the most
    " seats first. A line selection on the first row shown is the last row
    " of the table
    CLEAR ls_request.
    ls_request-path = `/MR_CGUI_ALV_PAGE/*`.
    ls_request-reason = z2ui5_if_client=>cs_window_reason-sort.
    ls_request-top = 1.

    CLEAR temp18.

    temp19-path = `SEATS`.
    temp19-descending = abap_true.
    INSERT temp19 INTO TABLE temp18.
    ls_request-t_sort = temp18.
    GET REFERENCE OF ls_request INTO mo_client->ms_get-r_event_data.
    event( z2ui5_cl_cgui_alv=>cs_event-rows ).

    CLEAR temp319.
    INSERT 3 INTO TABLE temp319.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_alv_index
                                        exp = temp319 ).

    CLEAR temp321.
    INSERT `/XX/MR_CGUI_ALV_PAGE/0` INTO TABLE temp321.
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = temp321 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 3 ).

  ENDMETHOD.

  METHOD alv_paging_filtered_maps_rows.

    DATA ls_request TYPE z2ui5_if_client=>ty_s_window_request.
    DATA temp323 TYPE string_table.
    DATA temp325 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp20 TYPE z2ui5_if_client=>ty_t_bind_tab_filter.
    DATA temp21 LIKE LINE OF temp20.
    DATA temp327 TYPE z2ui5_cl_cgui_alv=>ty_t_index.
    DATA temp329 TYPE string_table.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " searched and large: the copy holds the first of the rows the search
    " lets through, bound with window_bind_tab( ) - a row of the copy leads
    " to the table's
    mo_cut->mo_cgui_alv->set_paging( 1 ).

    CLEAR temp323.
    INSERT `A` INTO TABLE temp323.
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = temp323 ).
    cl_abap_unit_assert=>assert_bound( mo_cut->mr_cgui_alv_page ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 1 ).

    CLEAR temp325.
    INSERT 2 INTO TABLE temp325.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_alv_index
                                        exp = temp325 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_alv_total
                                        exp = 2 ).

    " a filter of a column menu on top of the search
    CLEAR ls_request.
    ls_request-path = `/MR_CGUI_ALV_PAGE/*`.
    ls_request-reason = z2ui5_if_client=>cs_window_reason-filter.
    ls_request-top = 1.

    CLEAR temp20.

    temp21-group = 1.
    temp21-path = `CARRID`.
    temp21-operator = `StartsWith`.
    temp21-value1 = `u`.
    INSERT temp21 INTO TABLE temp20.
    ls_request-t_filter = temp20.
    GET REFERENCE OF ls_request INTO mo_client->ms_get-r_event_data.
    event( z2ui5_cl_cgui_alv=>cs_event-rows ).

    CLEAR temp327.
    INSERT 3 INTO TABLE temp327.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mt_cgui_alv_index
                                        exp = temp327 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_alv_total
                                        exp = 1 ).


    CLEAR temp329.
    INSERT `/XX/MR_CGUI_ALV_PAGE/0` INTO TABLE temp329.
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = temp329 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 3 ).

  ENDMETHOD.

  METHOD alv_filter_by_popup.
    DATA temp331 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp331.
    DATA temp332 TYPE string_table.
    DATA temp334 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_range LIKE temp334.
    DATA temp335 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp336 LIKE LINE OF temp335.
    DATA temp111 TYPE xsdboolean.
    DATA temp337 TYPE string_table.
    DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp339 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp112 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the filter button lists the columns - pick the airline
    event( z2ui5_cl_cgui_alv=>cs_event-filter ).

    temp331 ?= mo_client->mo_called.

    lo_select = temp331.
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.

    CLEAR temp332.
    INSERT `/XX/MR_VIEW/0` INTO TABLE temp332.
    mo_client->mt_arg = temp332.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    " its multiple selection - UA only

    temp334 ?= mo_client->mo_called.

    lo_range = temp334.

    CLEAR temp335.

    temp336-key = `1`.
    temp336-sign = `I`.
    temp336-option = `EQ`.
    temp336-low = `UA`.
    INSERT temp336 INTO TABLE temp335.
    lo_range->mt_row = temp335.
    range_popup_leave( z2ui5_cl_cgui_range=>cs_event-ok ).

    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mo_cgui_alv->get_filter( ) )
                                        exp = 1 ).

    temp111 = boolc( mo_client->mv_view CS `(1 of 3)` ).
    cl_abap_unit_assert=>assert_true( temp111 ).

    " the one row shown is the third of the table

    CLEAR temp337.
    INSERT `/XX/MR_CGUI_ALV_PAGE/0` INTO TABLE temp337.
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = temp337 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 3 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " select all takes the rows that pass only
    event( z2ui5_cl_cgui_alv=>cs_event-select_all ).

    lt_selected = mo_cut->get_selected_rows( ).

    CLEAR temp339.
    INSERT 3 INTO TABLE temp339.
    cl_abap_unit_assert=>assert_equals( act = lt_selected
                                        exp = temp339 ).

    event( z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mo_cgui_alv->get_filter( ) ).

    temp112 = boolc( mo_client->mv_view CS `(3)` ).
    cl_abap_unit_assert=>assert_true( temp112 ).

  ENDMETHOD.

  METHOD window_shows_dialog.
    DATA temp341 TYPE string_table.
    DATA temp113 TYPE xsdboolean.
    DATA temp114 TYPE xsdboolean.
    DATA temp115 TYPE xsdboolean.
    DATA temp116 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_window = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the secondary list in a dialog box, the basic list below as text

    CLEAR temp341.
    INSERT `2` INTO TABLE temp341.
    INSERT `H1` INTO TABLE temp341.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp341 ).

    temp113 = boolc( mo_client->mv_popup CS `Detail H1` ).
    cl_abap_unit_assert=>assert_true( temp113 ).

    temp114 = boolc( mo_client->mv_popup CS `30rem` ).
    cl_abap_unit_assert=>assert_true( temp114 ).

    temp115 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp115 ).

    temp116 = boolc( mo_client->mv_view CS `Detail H1` ).
    cl_abap_unit_assert=>assert_false( temp116 ).

    " back closes the box
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).

  ENDMETHOD.

  METHOD exit_command.

    init( ).
    mo_report->mv_exit_err = abap_true.
    mo_cut->mv_cgui_called = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_exit
                                        exp = z2ui5_cl_cgui_report=>cs_ucomm-back ).
    " the error keeps the screen - nothing left
    cl_abap_unit_assert=>assert_false( mo_client->mv_left ).

    mo_report->mv_exit_err = abap_false.
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).

  ENDMETHOD.

  METHOD write_takes_format.
    DATA temp343 TYPE d.
    DATA lt_item TYPE z2ui5_cl_cgui_list=>ty_t_item.
    FIELD-SYMBOLS <temp344> LIKE LINE OF lt_item.
    DATA temp345 LIKE sy-tabix.
    FIELD-SYMBOLS <temp346> LIKE LINE OF lt_item.
    DATA temp347 LIKE sy-tabix.
    FIELD-SYMBOLS <temp348> LIKE LINE OF lt_item.
    DATA temp349 LIKE sy-tabix.

    init( ).
    mo_cut->format( color = z2ui5_cl_cgui_list=>cs_color-positive ).
    mo_cut->write( `a` ).
    mo_cut->write( val   = `b`
                   color = z2ui5_cl_cgui_list=>cs_color-negative ).

    temp343 = '20261002'.
    mo_cut->write( val       = temp343
                   date_format = z2ui5_cl_cgui_list=>cs_date_format-ddmmyy ).

    lt_item = mo_cut->mo_cgui_list->get_items( ).
    " the header line of TOP-OF-PAGE first
    DELETE lt_item WHERE header = abap_true.


    temp345 = sy-tabix.
    READ TABLE lt_item INDEX 1 ASSIGNING <temp344>.
    sy-tabix = temp345.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp344>-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-positive ).


    temp347 = sy-tabix.
    READ TABLE lt_item INDEX 2 ASSIGNING <temp346>.
    sy-tabix = temp347.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp346>-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-negative ).
    " as the classic WRITE ... DDMMYY: day, month, year without separators


    temp349 = sy-tabix.
    READ TABLE lt_item INDEX 3 ASSIGNING <temp348>.
    sy-tabix = temp349.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp348>-text
                                        exp = `021026` ).

  ENDMETHOD.

  METHOD cursor_and_lisel.
    DATA lt_item TYPE z2ui5_cl_cgui_list=>ty_t_item.
    DATA ls_row LIKE LINE OF lt_item.
    FIELD-SYMBOLS <temp22> LIKE LINE OF lt_item.
    DATA temp23 LIKE sy-tabix.
    DATA temp350 TYPE string_table.
    DATA temp24 LIKE LINE OF temp350.
    DATA temp25 LIKE LINE OF temp350.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    lt_item = mo_cut->mo_cgui_list->get_items( ).



    temp23 = sy-tabix.
    READ TABLE lt_item WITH KEY text = `row1` ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_row = <temp22>.


    CLEAR temp350.

    temp24 = |{ ls_row-line }|.
    INSERT temp24 INTO TABLE temp350.
    INSERT `H1` INTO TABLE temp350.

    temp25 = |{ ls_row-id }|.
    INSERT temp25 INTO TABLE temp350.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp350 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_cursor( )-value
                                        exp = `row1` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_cursor( )-line
                                        exp = ls_row-line ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lisel( )
                                        exp = `row1` ).

  ENDMETHOD.

  METHOD selscreen_status_and_cursor.
    DATA temp352 TYPE string_table.
    DATA temp117 TYPE xsdboolean.
    DATA temp118 TYPE xsdboolean.
    DATA temp119 TYPE xsdboolean.
    DATA temp120 TYPE xsdboolean.

    init( ).

    CLEAR temp352.
    INSERT z2ui5_cl_cgui_report=>cs_ucomm-variant_save INTO TABLE temp352.
    INSERT z2ui5_cl_cgui_report=>cs_ucomm-execute INTO TABLE temp352.
    mo_cut->set_selscreen_status( temp352 ).
    mo_cut->set_cursor_field( `p_text` ).
    event( `NOOP` ).

    temp117 = boolc( mo_client->mv_view CS `Save as Variant` ).
    cl_abap_unit_assert=>assert_false( temp117 ).

    temp118 = boolc( mo_client->mv_view CS `Get Variant` ).
    cl_abap_unit_assert=>assert_true( temp118 ).

    temp119 = boolc( mo_client->mv_view CS z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_false( temp119 ).

    temp120 = boolc( concat_lines_of( mo_client->mt_action ) CS `cgui_f_p_text` ).
    cl_abap_unit_assert=>assert_true( temp120 ).

    " F8 is switched off as well
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).

  ENDMETHOD.

  METHOD alv_search_and_details.

    FIELD-SYMBOLS <box> TYPE STANDARD TABLE.
    DATA temp354 TYPE string_table.
    DATA temp121 TYPE xsdboolean.
    DATA temp122 TYPE xsdboolean.
    DATA temp47 LIKE sy-subrc.
    DATA temp356 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp123 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the search field: UA in one of the columns

    CLEAR temp354.
    INSERT `ua` INTO TABLE temp354.
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = temp354 ).

    temp121 = boolc( mo_client->mv_view CS `(1 of 3)` ).
    cl_abap_unit_assert=>assert_true( temp121 ).

    " details without a row selected: a warning; with one: the dialog box
    event( z2ui5_cl_cgui_alv=>cs_event-details ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).


    READ TABLE mo_cut->mt_cgui_log WITH KEY type = `W` TRANSPORTING NO FIELDS.
    temp47 = sy-subrc.
    temp122 = boolc( temp47 = 0 ).
    cl_abap_unit_assert=>assert_true( temp122 ).
    event( z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    ASSIGN mo_cut->mr_cgui_alv_box->* TO <box>.

    CLEAR temp356.
    INSERT 3 INTO TABLE temp356.
    mo_cut->mo_cgui_alv->set_selected_rows( EXPORTING rows = temp356
                                            CHANGING  tab  = <box> ).
    event( z2ui5_cl_cgui_alv=>cs_event-details ).

    temp123 = boolc( mo_client->mv_popup CS `UA` ).
    cl_abap_unit_assert=>assert_true( temp123 ).
    event( z2ui5_cl_cgui_alv=>cs_event-details_close ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).

  ENDMETHOD.

  METHOD select_popup_pick.

    DATA temp358 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp358.
    DATA temp359 TYPE string_table.
    DATA temp26 LIKE LINE OF temp359.
    temp358 ?= mo_client->mo_called.

    lo_select = temp358.
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.

    CLEAR temp359.

    temp26 = |/XX/MR_VIEW/{ index - 1 }|.
    INSERT temp26 INTO TABLE temp359.
    mo_client->mt_arg = temp359.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD f4_on_high.

    DATA temp361 LIKE mo_report->s_code.
    DATA temp362 LIKE LINE OF temp361.
    DATA temp363 TYPE string_table.
    FIELD-SYMBOLS <temp365> LIKE LINE OF mo_report->s_code.
    DATA temp366 LIKE sy-tabix.
    FIELD-SYMBOLS <temp367> LIKE LINE OF mo_report->s_code.
    DATA temp368 LIKE sy-tabix.
    FIELD-SYMBOLS <temp369> LIKE LINE OF mo_report->s_code.
    DATA temp370 LIKE sy-tabix.
    CLEAR temp361.

    temp362-sign = `I`.
    temp362-option = `EQ`.
    temp362-low = `AA`.
    INSERT temp362 INTO TABLE temp361.
    mo_report->s_code = temp361.
    init( ).

    CLEAR temp363.
    INSERT `S_CODE` INTO TABLE temp363.
    INSERT `HIGH` INTO TABLE temp363.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp363 ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    select_popup_pick( 1 ).

    " the first line is an interval up to the value picked
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 1 ).


    temp366 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp365>.
    sy-tabix = temp366.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp365>-option
                                        exp = `BT` ).


    temp368 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp367>.
    sy-tabix = temp368.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp367>-low
                                        exp = `AA` ).


    temp370 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp369>.
    sy-tabix = temp370.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp369>-high
                                        exp = `ZZ` ).

  ENDMETHOD.

  METHOD f4_in_alv_cell.
    DATA temp371 TYPE string_table.
    FIELD-SYMBOLS <temp373> LIKE LINE OF mo_report->mt_row.
    DATA temp374 LIKE sy-tabix.
    FIELD-SYMBOLS <temp375> LIKE LINE OF mo_report->mt_row.
    DATA temp376 LIKE sy-tabix.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_cut->mo_cgui_alv->set_edit( )->set_column_f4( `CARRID` ).

    " F4 in the airline of the second row - the second value picked

    CLEAR temp371.
    INSERT `/XX/MR_CGUI_ALV_BOX/1` INTO TABLE temp371.
    INSERT `CARRID` INTO TABLE temp371.
    event( name = z2ui5_cl_cgui_alv=>cs_event-f4
           args = temp371 ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    select_popup_pick( 2 ).


    temp374 = sy-tabix.
    READ TABLE mo_report->mt_row INDEX 2 ASSIGNING <temp373>.
    sy-tabix = temp374.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp373>-carrid
                                        exp = `SQ` ).


    temp376 = sy-tabix.
    READ TABLE mo_report->mt_row INDEX 1 ASSIGNING <temp375>.
    sy-tabix = temp376.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp375>-carrid
                                        exp = `LH` ).

  ENDMETHOD.

  METHOD tree_expand_and_node.
    DATA temp124 TYPE xsdboolean.
    DATA temp377 TYPE string_table.
    FIELD-SYMBOLS <temp379> LIKE LINE OF mo_cut->mt_cgui_tree_view.
    DATA temp380 LIKE sy-tabix.
    FIELD-SYMBOLS <temp381> LIKE LINE OF mo_cut->mt_cgui_tree_view.
    DATA temp382 LIKE sy-tabix.
    DATA temp383 TYPE z2ui5_cl_cgui_tree=>ty_t_key.
    DATA temp385 TYPE string_table.
    DATA temp125 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_tree = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 1 ).

    temp124 = boolc( mo_client->mv_view CS `EVENT:CGUI_TREE_TOGGLE` ).
    cl_abap_unit_assert=>assert_true( temp124 ).

    " expand the airline - its connection is shown

    CLEAR temp377.
    INSERT `1` INTO TABLE temp377.
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = temp377 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 2 ).


    temp380 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tree_view INDEX 2 ASSIGNING <temp379>.
    sy-tabix = temp380.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp379>-text
                                        exp = `0400` ).

    " a tick in the browser reaches the node with the next event
    mo_cut->mo_cgui_tree->set_checkboxes( ).


    temp382 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tree_view INDEX 2 ASSIGNING <temp381>.
    sy-tabix = temp382.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp381>-checked = abap_true.
    event( z2ui5_cl_cgui_tree=>cs_event-expand_all ).

    CLEAR temp383.
    INSERT 2 INTO TABLE temp383.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mo_cgui_tree->get_checked( )
                                        exp = temp383 ).

    " a click on the connection - a secondary list, Back returns to the tree

    CLEAR temp385.
    INSERT `2` INTO TABLE temp385.
    event( name = z2ui5_cl_cgui_tree=>cs_event-node
           args = temp385 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).

    temp125 = boolc( mo_client->mv_view CS `Node LH-0400 2` ).
    cl_abap_unit_assert=>assert_true( temp125 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD serialize.

    " the roundtrip of abap2UI5 between two requests: the app in its
    " container to the draft and back - what is not serializable is dropped
    " there without a word
    DATA temp387 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_app LIKE temp387.
    DATA temp126 TYPE xsdboolean.
    DATA temp1 TYPE xsdboolean.
    DATA temp127 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
    DATA temp128 TYPE xsdboolean.
    DATA temp3 TYPE xsdboolean.
    temp387 ?= roundtrip( app = mo_cut step = step ).

    lo_app = temp387.

    cl_abap_unit_assert=>assert_equals( act = lo_app->mv_cgui_screen
                                        exp = mo_cut->mv_cgui_screen
                                        msg = |{ step }: screen| ).

    temp126 = boolc( lo_app->mo_cgui_list IS BOUND ).

    temp1 = boolc( mo_cut->mo_cgui_list IS BOUND ).
    cl_abap_unit_assert=>assert_equals( act = temp126
                                        exp = temp1
                                        msg = |{ step }: the list after the roundtrip| ).

    temp127 = boolc( lo_app->mo_cgui_alv IS BOUND ).

    temp2 = boolc( mo_cut->mo_cgui_alv IS BOUND ).
    cl_abap_unit_assert=>assert_equals( act = temp127
                                        exp = temp2
                                        msg = |{ step }: the ALV after the roundtrip| ).

    temp128 = boolc( lo_app->mo_cgui_tree IS BOUND ).

    temp3 = boolc( mo_cut->mo_cgui_tree IS BOUND ).
    cl_abap_unit_assert=>assert_equals( act = temp128
                                        exp = temp3
                                        msg = |{ step }: the tree after the roundtrip| ).
    IF mo_cut->mo_cgui_tree IS BOUND AND lo_app->mo_cgui_tree IS BOUND.
      cl_abap_unit_assert=>assert_equals( act = lines( lo_app->mo_cgui_tree->get_nodes( ) )
                                          exp = lines( mo_cut->mo_cgui_tree->get_nodes( ) )
                                          msg = |{ step }: the nodes of the tree| ).
    ENDIF.

  ENDMETHOD.

  METHOD draft_serializable.
    DATA temp388 TYPE string_table.

    " the list
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    serialize( `list` ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " the ALV
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    serialize( `ALV` ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " the tree, a node opened
    mo_report->mv_alv = abap_false.
    mo_report->mv_tree = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    CLEAR temp388.
    INSERT `1` INTO TABLE temp388.
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = temp388 ).
    serialize( `tree` ).

  ENDMETHOD.

  METHOD roundtrip.

    " the roundtrip of abap2UI5 between two requests: the app in its
    " container to the draft and back - what is not serializable is dropped
    " there without a word
    DATA lo_cont TYPE REF TO z2ui5_cl_ui5_app_cont.
        DATA lo_parsed TYPE REF TO z2ui5_cl_ui5_app_cont.
        DATA temp390 TYPE REF TO z2ui5_cl_ui5_srv_model.
        DATA lx_error TYPE REF TO cx_root.
    DATA temp391 TYPE REF TO z2ui5_if_app.
    CREATE OBJECT lo_cont TYPE z2ui5_cl_ui5_app_cont.
    lo_cont->mo_app = app.
    lo_cont->ms_draft-id = `CGUI_UNIT_TEST`.
    TRY.

        lo_parsed = z2ui5_cl_ui5_app_cont=>all_xml_parse( lo_cont->all_xml_stringify( ) ).
        " as db_load( ): the data references back from their S-RTTI payloads

        CREATE OBJECT temp390 TYPE z2ui5_cl_ui5_srv_model EXPORTING attri = lo_parsed->mt_attri app = lo_parsed->mo_app.
        temp390->main_attri_db_load( ).

      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>fail( |{ step }: the app cannot be saved - { lx_error->get_text( ) }| ).
    ENDTRY.

    temp391 ?= lo_parsed->mo_app.
    result = temp391.

  ENDMETHOD.

  METHOD draft_references.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA temp392 TYPE REF TO ltcl_variant_store.
    DATA temp393 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_app LIKE temp393.
    DATA lr_rows TYPE REF TO data.
    DATA temp394 TYPE ltcl_report=>ty_t_row.
    DATA temp395 LIKE LINE OF temp394.
    DATA temp396 TYPE REF TO z2ui5_cl_cgui_report.
    DATA temp397 TYPE ltcl_report=>ty_t_pick.
    DATA temp398 LIKE LINE OF temp397.
    DATA temp27 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp27.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    DATA temp399 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_range LIKE temp399.
    DATA temp400 TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp401 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA temp402 LIKE LINE OF temp401.

    " the rows of the ALV - an anonymous copy, its type rebuilt
    init( ).
    " a store of the customer's - it travels in the draft with the report

    CREATE OBJECT temp392 TYPE ltcl_variant_store.
    mo_cut->set_variant_store( temp392 ).

    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    " a public attribute: the ALV keeps its name

    temp393 ?= roundtrip( app = mo_cut step = `ALV of an attribute` ).

    lo_app = temp393.

    lr_rows = lo_app->alv_source( ).
    cl_abap_unit_assert=>assert_bound( act = lr_rows
                                       msg = `the rows of the ALV after the roundtrip` ).
    ASSIGN lr_rows->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = lines( mo_report->mt_row )
                                        msg = `the rows of the ALV after the roundtrip` ).

    " any other table: the ALV keeps a copy

    CLEAR temp394.

    temp395-carrid = `LH`.
    temp395-seats = 1.
    INSERT temp395 INTO TABLE temp394.
    temp395-carrid = `AA`.
    temp395-seats = 2.
    INSERT temp395 INTO TABLE temp394.
    temp395-carrid = `UA`.
    temp395-seats = 3.
    INSERT temp395 INTO TABLE temp394.
    mo_cut->alv( temp394 ).

    temp396 ?= roundtrip( app = mo_cut step = `ALV of a copy` ).
    lo_app = temp396.
    cl_abap_unit_assert=>assert_bound( act = lo_app->mr_cgui_alv
                                       msg = `the copy of the ALV after the roundtrip` ).
    ASSIGN lo_app->mr_cgui_alv->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = 3
                                        msg = `the copy of the ALV after the roundtrip` ).

    " the variant store on the server
    cl_abap_unit_assert=>assert_bound( act = lo_app->mo_cgui_store
                                       msg = `the variant store after the roundtrip` ).

    " the popups of the project with their tables of runtime types

    CLEAR temp397.

    temp398-value = `A`.
    INSERT temp398 INTO TABLE temp397.
    temp398-value = `B`.
    INSERT temp398 INTO TABLE temp397.

    temp27 ?= roundtrip( app = z2ui5_cl_cgui_select=>factory( tab = temp397 ) step = `select popup` ).

    lo_select = temp27.

    ls_result = lo_select->result( ).
    cl_abap_unit_assert=>assert_bound( act = ls_result-row
                                       msg = `select popup: the result row after the roundtrip` ).
    cl_abap_unit_assert=>assert_bound( act = ls_result-table
                                       msg = `select popup: the result table after the roundtrip` ).

    " the other dialogs - saved without an error, their state kept

    temp399 ?= roundtrip( app = z2ui5_cl_cgui_range=>factory( range = mo_report->s_code ) step = `range popup` ).

    lo_range = temp399.
    cl_abap_unit_assert=>assert_bound( lo_range ).

    CLEAR temp400.
    roundtrip( app  = z2ui5_cl_cgui_layout=>factory( layout = temp400 )
               step = `layout popup` ).
    roundtrip( app  = z2ui5_cl_cgui_popup=>confirm( question = `Sure?` )
               step = `confirm popup` ).

    CLEAR temp401.

    temp402-name = `A`.
    temp402-text = `A`.
    temp402-value = `1`.
    INSERT temp402 INTO TABLE temp401.
    roundtrip( app  = z2ui5_cl_cgui_popup=>get_values( fields = temp401 )
               step = `values popup` ).

  ENDMETHOD.

ENDCLASS.
