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
    DATA mt_row      TYPE ty_t_row.
    DATA mv_alv      TYPE abap_bool.
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
    " window_bind_tab( ): the window asked for, and the order the server would
    " show the rows in - window_get_row( ) answers from it (the position
    " itself when it is empty)
    DATA mv_window       TYPE i.
    TYPES temp3_da05c520ca TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA mt_window_order TYPE temp3_da05c520ca.

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
      DATA lo_tree TYPE REF TO z2ui5_cl_cgui_tree.
      DATA temp17 TYPE ty_s_row.
      DATA lv_lh TYPE i.
      DATA temp18 TYPE ty_s_row.
      DATA temp19 TYPE ltcl_report=>ty_t_row.
      DATA temp20 LIKE LINE OF temp19.

    mv_total = mv_total + 1.

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

    " LEAVE PROGRAM after a message - back on the selection screen
    IF mv_leave = abap_true.
      message( `Unknown airline` ).
      leave_to_selection_screen( ).
      RETURN.
    ENDIF.

    IF mv_tree = abap_true.

      lo_tree = tree( ).

      CLEAR temp17.
      temp17-carrid = `LH`.
      temp17-seats = 3.

      lv_lh = lo_tree->add_node( text  = `LH`
                                       data  = temp17
                                       value = `LH` ).

      CLEAR temp18.
      temp18-carrid = `LH`.
      temp18-seats = 1.
      lo_tree->add_node( parent = lv_lh
                         text   = `0400`
                         data   = temp18
                         value  = `LH-0400` ).
      RETURN.
    ENDIF.

    IF mv_alv = abap_true.

      CLEAR temp19.

      temp20-carrid = `LH`.
      temp20-seats = 1.
      INSERT temp20 INTO TABLE temp19.
      temp20-carrid = `AA`.
      temp20-seats = 2.
      INSERT temp20 INTO TABLE temp19.
      temp20-carrid = `UA`.
      temp20-seats = 3.
      INSERT temp20 INTO TABLE temp19.
      mt_row = temp19.
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

    mv_lsel_row = row.
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
        FIELD-SYMBOLS <temp21> LIKE LINE OF lt_file.
        DATA temp22 LIKE sy-tabix.
      DATA temp23 TYPE ty_t_pick.
      DATA temp24 LIKE LINE OF temp23.

    " F4 on the text - the file dialog of SAP GUI, converted
    IF field = `P_TEXT`.
      z2ui5_cl_cgui_frontend=>file_open_dialog( EXPORTING  file_filter = `Text (*.txt)|*.txt|`
                                                CHANGING   file_table  = lt_file
                                                           rc          = lv_rc
                                                           user_action = lv_action
                                                EXCEPTIONS OTHERS      = 1 ).
      IF sy-subrc = 0 AND lv_action = z2ui5_cl_cgui_frontend=>action_ok AND lv_rc = 1.


        temp22 = sy-tabix.
        READ TABLE lt_file INDEX 1 ASSIGNING <temp21>.
        sy-tabix = temp22.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        p_text = <temp21>-filename.
      ENDIF.
      RETURN.
    ENDIF.

    " F4 on the upper limit of the code - a hit list of its own
    IF field = `S_CODE` AND value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high.

      CLEAR temp23.

      temp24-value = `ZZ`.
      INSERT temp24 INTO TABLE temp23.
      value_help_popup( tab = temp23
                        col = `VALUE` ).
      RETURN.
    ENDIF.
    super->at_value_request( field ).

  ENDMETHOD.

  METHOD at_alv_value_request.
      DATA temp25 TYPE ty_t_pick.
      DATA temp26 LIKE LINE OF temp25.

    IF column = `CARRID`.

      CLEAR temp25.

      temp26-value = `QF`.
      INSERT temp26 INTO TABLE temp25.
      temp26-value = `SQ`.
      INSERT temp26 INTO TABLE temp25.
      value_help_popup( tab = temp25
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

  METHOD at_selection_screen_on_block.

    mv_block = block.

  ENDMETHOD.

  METHOD end_of_page.

    write( |FOOT { z2ui5_cl_cgui_list=>cv_page }| ).

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_client IMPLEMENTATION.
  METHOD z2ui5_if_client~check_app_prev_stack.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_path.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_bind_edit.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_client.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~_event_nav_app_leave.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popover_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~popup_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_model_update.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_destroy.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest2_view_display.
    RETURN. " todo, implement method
  ENDMETHOD.
  METHOD z2ui5_if_client~nest_view_model_update.
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
  METHOD z2ui5_if_client~view_model_update.
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
    DATA temp27 TYPE REF TO cl_abap_classdescr.
    DATA lo_class LIKE temp27.
    DATA temp28 LIKE LINE OF lo_class->attributes.
    DATA lr_descr LIKE REF TO temp28.

    result = z2ui5_cl_cgui_context=>attri_name_by_ref( app = mo_app
                                                       val = val ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    GET REFERENCE OF val INTO lr_val.

    temp27 ?= cl_abap_typedescr=>describe_by_object_ref( mo_app ).

    lo_class = temp27.


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

  METHOD z2ui5_if_client~window_get_row.
      DATA temp29 TYPE i.
      DATA temp30 TYPE i.

    result = row.
    IF mt_window_order IS NOT INITIAL.

      CLEAR temp29.

      READ TABLE mt_window_order INTO temp30 INDEX row.
      IF sy-subrc = 0.
        temp29 = temp30.
      ENDIF.
      result = temp29.
    ENDIF.

  ENDMETHOD.

  METHOD z2ui5_if_client~_bind.
      DATA lv_tab TYPE string.
      DATA temp2 TYPE xsdboolean.
      FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
      FIELD-SYMBOLS <row> TYPE any.
      DATA lr_val TYPE REF TO data.
      DATA lr_cell TYPE REF TO data.
      DATA temp31 TYPE REF TO cl_abap_structdescr.
      DATA lo_struct LIKE temp31.
      DATA temp32 LIKE LINE OF lo_struct->components.
      DATA lr_comp LIKE REF TO temp32.
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

      temp31 ?= cl_abap_typedescr=>describe_by_data( <row> ).

      lo_struct = temp31.


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

    DATA temp33 LIKE LINE OF mt_action.
    temp33 = |{ val }:{ concat_lines_of( table = t_arg sep = `|` ) }|.
    INSERT temp33 INTO TABLE mt_action.

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
      DATA temp34 TYPE REF TO ltcl_layout_store.

    IF mo_cut->mo_cgui_lay_store IS NOT BOUND AND mo_cut->mv_cgui_lay_none = abap_false.

      CREATE OBJECT temp34 TYPE ltcl_layout_store.
      mo_cut->set_layout_store( temp34 ).
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
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_item.
    DATA temp36 LIKE sy-tabix.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_item.
    DATA temp38 LIKE sy-tabix.
    DATA temp4 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).

    lt_item = mo_cut->mo_cgui_list->get_items( ).


    temp36 = sy-tabix.
    READ TABLE lt_item INDEX 1 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp35>-text
                                        exp = `HEADER` ).


    temp38 = sy-tabix.
    READ TABLE lt_item INDEX 1 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp37>-header ).

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
    DATA temp6 TYPE xsdboolean.
    DATA temp2 LIKE sy-subrc.
    DATA temp3 LIKE sy-subrc.
    DATA temp4 LIKE sy-tabix.
    FIELD-SYMBOLS <temp39> LIKE LINE OF mo_report->mt_cgui_so.
    DATA temp40 LIKE sy-tabix.
    FIELD-SYMBOLS <temp41> LIKE LINE OF mo_report->mt_cgui_so.
    DATA temp42 LIKE sy-tabix.
    FIELD-SYMBOLS <temp43> LIKE LINE OF mo_report->mt_cgui_so.
    DATA temp44 LIKE sy-tabix.
    FIELD-SYMBOLS <temp45> LIKE LINE OF mo_report->s_date.
    DATA temp46 LIKE sy-tabix.
    DATA temp47 TYPE d.
    FIELD-SYMBOLS <temp4> LIKE LINE OF mo_report->s_date.
    DATA temp5 LIKE sy-tabix.
    FIELD-SYMBOLS <temp48> LIKE LINE OF mo_report->s_code.
    DATA temp49 LIKE sy-tabix.
    FIELD-SYMBOLS <temp50> LIKE LINE OF mo_report->s_code.
    DATA temp51 LIKE sy-tabix.
    DATA temp7 TYPE xsdboolean.

    init( ).




    temp3 = sy-subrc.
    temp4 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_DATE` TRANSPORTING NO FIELDS.
    temp2 = sy-subrc.
    sy-subrc = temp3.
    sy-tabix = temp4.
    temp6 = boolc( temp2 = 0 ).
    cl_abap_unit_assert=>assert_true( temp6 ).



    temp40 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_DATE` ASSIGNING <temp39>.
    sy-tabix = temp40.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp39>-low  = `20260101`.


    temp42 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_DATE` ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp41>-high = `20260131`.


    temp44 = sy-tabix.
    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_CODE` ASSIGNING <temp43>.
    sy-tabix = temp44.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp43>-low  = `ab*`.
    event( `SOME_COMMAND` ).

    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_date )
                                        exp = 1 ).


    temp46 = sy-tabix.
    READ TABLE mo_report->s_date INDEX 1 ASSIGNING <temp45>.
    sy-tabix = temp46.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp45>-option
                                        exp = `BT` ).

    temp47 = `20260131`.


    temp5 = sy-tabix.
    READ TABLE mo_report->s_date INDEX 1 ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp4>-high
                                        exp = temp47 ).


    temp49 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp48>.
    sy-tabix = temp49.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp48>-option
                                        exp = `CP` ).


    temp51 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp50>.
    sy-tabix = temp51.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp50>-low
                                        exp = `AB*` ).
    " the inputs are bound to the buffer

    temp7 = boolc( mo_client->mv_view CS `{/MT_CGUI_SO/` ).
    cl_abap_unit_assert=>assert_true( temp7 ).

  ENDMETHOD.

  METHOD select_option_complex.

    DATA temp52 LIKE mo_report->s_code.
    DATA temp53 LIKE LINE OF temp52.
    DATA temp8 TYPE xsdboolean.
    DATA temp5 LIKE sy-subrc.
    CLEAR temp52.

    temp53-sign = `I`.
    temp53-option = `EQ`.
    temp53-low = `A`.
    INSERT temp53 INTO TABLE temp52.
    temp53-sign = `E`.
    temp53-option = `EQ`.
    temp53-low = `B`.
    INSERT temp53 INTO TABLE temp52.
    mo_report->s_code = temp52.
    init( ).



    READ TABLE mo_report->mt_cgui_so WITH KEY name = `S_CODE` TRANSPORTING NO FIELDS.
    temp5 = sy-subrc.
    temp8 = boolc( temp5 = 0 ).
    cl_abap_unit_assert=>assert_false( temp8 ).
    event( `SOME_COMMAND` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 2 ).

  ENDMETHOD.

  METHOD leave_during_the_run.
    DATA temp9 TYPE xsdboolean.
    DATA temp6 LIKE sy-subrc.
    DATA temp10 TYPE xsdboolean.
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
    temp9 = boolc( temp6 = 0 ).
    cl_abap_unit_assert=>assert_true( temp9 ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY text = `List contains no data` TRANSPORTING NO FIELDS.
    temp7 = sy-subrc.
    temp10 = boolc( temp7 = 0 ).
    cl_abap_unit_assert=>assert_false( temp10 ).

  ENDMETHOD.

  METHOD demo_output_into_list.

    TYPES:
      BEGIN OF ty_s_air,
        carrid TYPE c LENGTH 3,
        seats  TYPE i,
      END OF ty_s_air.
    TYPES temp5 TYPE STANDARD TABLE OF ty_s_air WITH DEFAULT KEY.
DATA lt_air TYPE temp5.
    DATA temp54 LIKE lt_air.
    DATA temp55 LIKE LINE OF temp54.
    DATA lt_text TYPE string_table.

    z2ui5_cl_cgui_gui=>set_report( mo_cut ).

    CLEAR temp54.

    temp55-carrid = `LH`.
    temp55-seats = 120.
    INSERT temp55 INTO TABLE temp54.
    temp55-carrid = `AA`.
    temp55-seats = 8.
    INSERT temp55 INTO TABLE temp54.
    lt_air = temp54.
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
    DATA temp56 TYPE string_table.
    DATA temp58 TYPE REF TO z2ui5_cl_cgui_file.
    DATA lo_file LIKE temp58.
    DATA temp11 TYPE xsdboolean.
    DATA temp12 TYPE xsdboolean.
    FIELD-SYMBOLS <temp59> LIKE LINE OF lt_air.
    DATA temp60 LIKE sy-tabix.
    DATA temp61 TYPE REF TO z2ui5_cl_cgui_file.
    DATA temp13 TYPE xsdboolean.
    DATA temp62 LIKE lt_air.
    DATA temp63 LIKE LINE OF temp62.
    FIELD-SYMBOLS <temp64> LIKE LINE OF mo_client->mt_action.
    DATA temp65 LIKE sy-tabix.

    init( ).
    " F4 opens the upload - the dialog answers cancel the first time

    CLEAR temp56.
    INSERT `P_TEXT` INTO TABLE temp56.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp56 ).

    temp58 ?= mo_client->mo_called.

    lo_file = temp58.
    cl_abap_unit_assert=>assert_initial( mo_report->p_text ).

    " the user picks a file in the browser and confirms
    mo_client->mo_app = lo_file.
    mo_client->mv_init = abap_true.
    lo_file->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

    temp11 = boolc( mo_client->mv_popup CS `FileUploader` ).
    cl_abap_unit_assert=>assert_true( temp11 ).

    temp12 = boolc( mo_client->mv_popup CS `fileType="txt"` ).
    cl_abap_unit_assert=>assert_true( temp12 ).
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


    temp60 = sy-tabix.
    READ TABLE lt_air INDEX 2 ASSIGNING <temp59>.
    sy-tabix = temp60.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp59>-name
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

    temp61 ?= mo_client->mo_called.
    lo_file = temp61.
    mo_client->mo_app = lo_file.
    mo_client->mv_init = abap_true.
    lo_file->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.
    mo_client->mo_app = mo_report.

    temp13 = boolc( mo_client->mv_popup CS `title="missing.txt"` ).
    cl_abap_unit_assert=>assert_true( temp13 ).

    " gui_download( ) hands the file to the browser

    CLEAR temp62.

    temp63-carrid = `LH`.
    temp63-name = `Lufthansa`.
    INSERT temp63 INTO TABLE temp62.
    lt_air = temp62.
    CLEAR mo_client->mt_action.
    z2ui5_cl_cgui_frontend=>gui_download( EXPORTING  filename              = `C:\out\list.csv`
                                                     write_field_separator = abap_true
                                          CHANGING   data_tab              = lt_air
                                          EXCEPTIONS OTHERS                = 1 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).


    temp65 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp64>.
    sy-tabix = temp65.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp64>
                                        exp = |{ mo_client->z2ui5_if_client~cs_event-download_b64_file }:data:text/csv;base64,| &&
                                              |{ z2ui5_cl_cgui_context=>conv_encode_x_base64(
                                                     z2ui5_cl_cgui_context=>conv_get_xstring_by_string( |LH\tLufthansa\r\n| ) ) }\|list.csv| ).

  ENDMETHOD.

  METHOD dynpro_call_and_leave.
    DATA temp14 TYPE xsdboolean.
    DATA temp15 TYPE xsdboolean.
    DATA temp16 TYPE xsdboolean.
    DATA temp8 LIKE sy-subrc.
    DATA temp17 TYPE xsdboolean.

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

    temp14 = boolc( mo_client->mv_view CS `Seats` AND mo_client->mv_view CS `EVENT:SAVE` ).
    cl_abap_unit_assert=>assert_true( temp14 ).

    temp15 = boolc( mo_client->mv_view CS `EVENT:CHECK` ).
    cl_abap_unit_assert=>assert_true( temp15 ).

    " a push button: the required seats are checked first, no PAI
    event( `CHECK` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0100;` ).


    READ TABLE mo_cut->mt_cgui_msg WITH KEY type = `E` TRANSPORTING NO FIELDS.
    temp8 = sy-subrc.
    temp16 = boolc( temp8 = 0 ).
    cl_abap_unit_assert=>assert_true( temp16 ).

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
    " called - and the list shows
    event( `SAVE` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_after
                                        exp = `0100` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp17 = boolc( mo_client->mv_view CS `Seats 2` ).
    cl_abap_unit_assert=>assert_true( temp17 ).

    " Back on the list - the selection screen, the dynpro stack is empty
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_cgui_dynpro_stack ).

  ENDMETHOD.

  METHOD dynpro_of_another_class.
    DATA lo_owner TYPE REF TO ltcl_report.
    DATA temp18 TYPE xsdboolean.
    DATA lo_client TYPE REF TO ltcl_client.
    DATA temp19 TYPE xsdboolean.
    DATA temp20 TYPE xsdboolean.

    " CALL SCREEN of a dynpro of another class: it runs as its own app
    init( ).
    mo_report->p_carrid = `LH`.

    CREATE OBJECT lo_owner TYPE ltcl_report.
    mo_report->mo_owner = lo_owner.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    temp18 = boolc( mo_client->mo_called = lo_owner ).
    cl_abap_unit_assert=>assert_true( act = temp18
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

    temp19 = boolc( lo_client->mv_view CS `Seats` ).
    cl_abap_unit_assert=>assert_true( act = temp19
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

    temp20 = boolc( mo_client->mv_view CS `Seats 3` ).
    cl_abap_unit_assert=>assert_true( act = temp20
                                      msg = `no seats 3` ).

  ENDMETHOD.

  METHOD dynpro_table_control.
    DATA temp66 TYPE ltcl_report=>ty_t_row.
    DATA temp67 LIKE LINE OF temp66.
    FIELD-SYMBOLS <temp68> LIKE LINE OF mo_cut->mt_cgui_tc_row.
    DATA temp69 LIKE sy-tabix.
    DATA temp21 TYPE xsdboolean.
    DATA temp22 TYPE xsdboolean.
    FIELD-SYMBOLS <temp70> LIKE LINE OF mo_cut->mt_cgui_tc_row.
    DATA temp71 LIKE sy-tabix.
    FIELD-SYMBOLS <temp72> LIKE LINE OF mo_report->mt_seat.
    DATA temp73 LIKE sy-tabix.
    FIELD-SYMBOLS <temp74> LIKE LINE OF mo_cut->mt_cgui_tc_row.
    DATA temp75 LIKE sy-tabix.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_dynpro = abap_true.
    mo_report->mv_tc = abap_true.

    CLEAR temp66.

    temp67-carrid = 'LH'.
    temp67-seats = 10.
    INSERT temp67 INTO TABLE temp66.
    temp67-carrid = 'AA'.
    temp67-seats = 20.
    INSERT temp67 INTO TABLE temp66.
    mo_report->mt_seat = temp66.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the lines of the PBO loop, a table bound to them - the seats an input
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tc_row )
                                        exp = 2 ).


    temp69 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tc_row INDEX 2 ASSIGNING <temp68>.
    sy-tabix = temp69.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp68>-c01
                                        exp = `AA` ).

    temp21 = boolc( mo_client->mv_view CS `<Table` AND mo_client->mv_view CS `<Input value="{C02}"` ).
    cl_abap_unit_assert=>assert_true( temp21 ).

    temp22 = boolc( mo_client->mv_view CS `<Text text="{C01}"` AND mo_client->mv_view CS `Seats` ).
    cl_abap_unit_assert=>assert_true( temp22 ).

    " the user changes a cell: the PAI loop reads it into the work area and
    " modifies its line; the PBO hands the lines over anew


    temp71 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tc_row INDEX 2 ASSIGNING <temp70>.
    sy-tabix = temp71.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp70>-c02 = `25`.
    event( `CHECK` ).


    temp73 = sy-tabix.
    READ TABLE mo_report->mt_seat INDEX 2 ASSIGNING <temp72>.
    sy-tabix = temp73.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp72>-seats
                                        exp = 25 ).


    temp75 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tc_row INDEX 2 ASSIGNING <temp74>.
    sy-tabix = temp75.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp74>-c02
                                        exp = `25` ).

  ENDMETHOD.

  METHOD dynpro_tabstrip.
    DATA temp23 TYPE xsdboolean.
    DATA temp24 TYPE xsdboolean.
    DATA temp25 TYPE xsdboolean.
    DATA temp76 TYPE string_table.
    DATA temp26 TYPE xsdboolean.
    DATA temp27 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_dynpro = abap_true.
    mo_report->mv_tabs = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the tabstrip: its tabs by function code, the first selected, the
    " subscreen the PBO called on it - its PBO ran too
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0110;` ).

    temp23 = boolc( mo_client->mv_view CS `IconTabBar` AND mo_client->mv_view CS `selectedKey="TAB1"` ).
    cl_abap_unit_assert=>assert_true( temp23 ).

    temp24 = boolc( mo_client->mv_view CS `key="TAB2"` AND mo_client->mv_view CS `First` ).
    cl_abap_unit_assert=>assert_true( temp24 ).

    temp25 = boolc( mo_client->mv_view CS z2ui5_cl_cgui_selscreen=>cs_event-tab ).
    cl_abap_unit_assert=>assert_true( temp25 ).

    " the second tab: a function of the dynpro - its PAI (logged first)
    " calls that of the subscreen and switches the subscreen

    CLEAR temp76.
    INSERT `TAB2` INTO TABLE temp76.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-tab
           args = temp76 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_pai
                                        exp = `PBO0100;PBO0110;PAI0100:TAB2;PAI0110:TAB2;PBO0100;PBO0120;` ).

    temp26 = boolc( mo_client->mv_view CS `selectedKey="TAB2"` AND mo_client->mv_view CS `Second tab` ).
    cl_abap_unit_assert=>assert_true( temp26 ).

    temp27 = boolc( mo_client->mv_view CS `First` ).
    cl_abap_unit_assert=>assert_false( temp27 ).

  ENDMETHOD.

  METHOD dynpro_text_editor.
    DATA temp28 TYPE xsdboolean.
    FIELD-SYMBOLS <temp78> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp79 LIKE sy-tabix.
    FIELD-SYMBOLS <temp80> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp81 LIKE sy-tabix.
    FIELD-SYMBOLS <temp82> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp83 LIKE sy-tabix.
    DATA lv_f1_key TYPE string.
    DATA temp29 TYPE xsdboolean.
    DATA temp9 LIKE sy-subrc.
    DATA temp10 LIKE sy-subrc.
    DATA temp11 LIKE sy-tabix.
    DATA temp30 TYPE xsdboolean.
    FIELD-SYMBOLS <temp84> LIKE LINE OF mo_cut->mt_cgui_gui.
    DATA temp85 LIKE sy-tabix.

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

    temp28 = boolc( mo_client->mv_view CS `<TextArea` ).
    cl_abap_unit_assert=>assert_true( temp28 ).


    temp79 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp78>.
    sy-tabix = temp79.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp78>-text
                                        exp = `first note` ).

    " what the user typed, on Save: the PAI reads it, the PBO does not set it again


    temp81 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp80>.
    sy-tabix = temp81.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp80>-text = `typed note`.
    event( `CHECK` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_note
                                        exp = `typed note` ).


    temp83 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp82>.
    sy-tabix = temp83.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp82>-text
                                        exp = `typed note` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_gui )
                                        exp = 2 ).

    " F1 registered: the key on the page, the text area with its id

    lv_f1_key = |KEYBOARD_SHORTCUT:F1\|CGUI_GUI_F1\|{ mo_client->z2ui5_if_client~cs_view-main }|.




    temp10 = sy-subrc.
    temp11 = sy-tabix.
    READ TABLE mo_client->mt_action WITH KEY table_line = lv_f1_key TRANSPORTING NO FIELDS.
    temp9 = sy-subrc.
    sy-subrc = temp10.
    sy-tabix = temp11.
    temp29 = boolc( temp9 = 0 ).
    cl_abap_unit_assert=>assert_true( temp29 ).

    temp30 = boolc( mo_client->mv_view CS `cgui_textedit_2` ).
    cl_abap_unit_assert=>assert_true( temp30 ).

    " F1 with the cursor in the second line: the handler, where it stood


    temp85 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_gui INDEX 2 ASSIGNING <temp84>.
    sy-tabix = temp85.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp84>-text = |first\nsecond|.
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
    DATA temp31 TYPE xsdboolean.
    DATA temp12 LIKE sy-subrc.

    init( ).
    " outside of at_selection_screen_output( ): a screen built afresh, with
    " the fields of selection_screen( ) - and none kept in the app

    lt_screen = mo_cut->current_screen( )->loop_at_screen( ).


    READ TABLE lt_screen WITH KEY name = `P_CARRID` TRANSPORTING NO FIELDS.
    temp12 = sy-subrc.
    temp31 = boolc( temp12 = 0 ).
    cl_abap_unit_assert=>assert_true( temp31 ).
    cl_abap_unit_assert=>assert_not_bound( mo_cut->mo_cgui_screen ).

  ENDMETHOD.

  METHOD secondary_list_and_back.
    DATA temp86 TYPE string_table.
    DATA temp32 TYPE xsdboolean.
    DATA temp33 TYPE xsdboolean.
    DATA temp88 TYPE string_table.
    DATA temp90 TYPE string_table.
    DATA temp34 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).


    CLEAR temp86.
    INSERT `2` INTO TABLE temp86.
    INSERT `H1` INTO TABLE temp86.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp86 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 2 ).

    temp32 = boolc( mo_client->mv_view CS `Detail H1` ).
    cl_abap_unit_assert=>assert_true( temp32 ).

    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).

    temp33 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp33 ).

    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).

    " sy-lsind = sy-lsind - 1: a second detail replaces the first, Back
    " returns to the basic list
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_report->mv_replace = abap_true.

    CLEAR temp88.
    INSERT `2` INTO TABLE temp88.
    INSERT `H1` INTO TABLE temp88.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp88 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 0 ).
    mo_report->mv_replace = abap_false.

    CLEAR temp90.
    INSERT `1` INTO TABLE temp90.
    INSERT `H2` INTO TABLE temp90.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp90 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    temp34 = boolc( mo_client->mv_view CS `Detail H1` ).
    cl_abap_unit_assert=>assert_true( temp34 ).

  ENDMETHOD.

  METHOD alv_box_copy_selection.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <box> TYPE any.
    DATA temp92 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp94 TYPE z2ui5_cl_cgui_alv=>ty_t_row.

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


    CLEAR temp92.
    INSERT 2 INTO TABLE temp92.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = temp92 ).

    " the selection survives the next render, select all marks every row
    event( `SOME_COMMAND` ).

    CLEAR temp94.
    INSERT 2 INTO TABLE temp94.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_selected_rows( )
                                        exp = temp94 ).
    event( z2ui5_cl_cgui_alv=>cs_event-select_all ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->get_selected_rows( ) )
                                        exp = 3 ).

  ENDMETHOD.

  METHOD url_values_screen_only.
    FIELD-SYMBOLS <temp96> LIKE LINE OF mo_report->s_date.
    DATA temp97 LIKE sy-tabix.

    mo_client->ms_get-s_config-search = `?app_start=x&p_carrid=AA&mv_secret=abc&p_hidden=Z&s_date=20260101..20260131`.
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `AA` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_secret ).
    cl_abap_unit_assert=>assert_initial( mo_report->p_hidden ).


    temp97 = sy-tabix.
    READ TABLE mo_report->s_date INDEX 1 ASSIGNING <temp96>.
    sy-tabix = temp97.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp96>-option
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
    FIELD-SYMBOLS <temp98> LIKE LINE OF lt_value.
    DATA temp99 LIKE sy-tabix.
    FIELD-SYMBOLS <temp100> LIKE LINE OF lt_value.
    DATA temp101 LIKE sy-tabix.
    FIELD-SYMBOLS <temp102> LIKE LINE OF lt_value.
    DATA temp103 LIKE sy-tabix.
    FIELD-SYMBOLS <temp104> LIKE LINE OF lt_value.
    DATA temp105 LIKE sy-tabix.
    FIELD-SYMBOLS <temp106> LIKE LINE OF lt_value.
    DATA temp107 LIKE sy-tabix.
    DATA temp108 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp109 LIKE LINE OF temp108.
    lt_value = z2ui5_cl_cgui_command=>url_range( name = `S_CODE`
                                                      val  = `A,B..C,!D,>=E,F*` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_value )
                                        exp = 5 ).


    temp99 = sy-tabix.
    READ TABLE lt_value INDEX 2 ASSIGNING <temp98>.
    sy-tabix = temp99.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp98>-option
                                        exp = `BT` ).


    temp101 = sy-tabix.
    READ TABLE lt_value INDEX 2 ASSIGNING <temp100>.
    sy-tabix = temp101.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp100>-high
                                        exp = `C` ).


    temp103 = sy-tabix.
    READ TABLE lt_value INDEX 3 ASSIGNING <temp102>.
    sy-tabix = temp103.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp102>-sign
                                        exp = `E` ).


    temp105 = sy-tabix.
    READ TABLE lt_value INDEX 4 ASSIGNING <temp104>.
    sy-tabix = temp105.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp104>-option
                                        exp = `GE` ).


    temp107 = sy-tabix.
    READ TABLE lt_value INDEX 5 ASSIGNING <temp106>.
    sy-tabix = temp107.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp106>-option
                                        exp = `CP` ).
    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_cgui_command=>url_from_range( lt_value )
                                        exp = `A,B..C,!D,>=E,F*` ).

    " NB and NP have no form of their own - I NB is E BT, I NP is E CP

    CLEAR temp108.

    CLEAR temp109.
    temp109-sign = `I`.
    temp109-option = `NB`.
    temp109-low = `A`.
    temp109-high = `B`.
    INSERT temp109 INTO TABLE temp108.
    CLEAR temp109.
    temp109-sign = `I`.
    temp109-option = `NP`.
    temp109-low = `C*`.
    INSERT temp109 INTO TABLE temp108.
    CLEAR temp109.
    temp109-sign = `E`.
    temp109-option = `NB`.
    temp109-low = `D`.
    temp109-high = `E`.
    INSERT temp109 INTO TABLE temp108.
    cl_abap_unit_assert=>assert_equals(
        act = z2ui5_cl_cgui_command=>url_from_range( temp108 )
        exp = `!A..B,!C*,D..E` ).

  ENDMETHOD.

  METHOD variant_screen_only.

    " a variant names the fields of the screen - one from the browser's
    " storage may name anything, and sets no other attribute
    DATA lo_store TYPE REF TO ltcl_variant_store.
    DATA temp110 TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp111 LIKE LINE OF temp110.
    DATA temp6 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp7 LIKE LINE OF temp6.
    CREATE OBJECT lo_store TYPE ltcl_variant_store.

    CLEAR temp110.

    temp111-name = `V1`.

    CLEAR temp6.

    temp7-name = `P_CARRID`.
    temp7-kind = `P`.
    temp7-low = `LH`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `mv_secret`.
    temp7-kind = `P`.
    temp7-low = `abc`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `MV_UCOMM`.
    temp7-kind = `P`.
    temp7-low = `X`.
    INSERT temp7 INTO TABLE temp6.
    temp111-values = temp6.
    INSERT temp111 INTO TABLE temp110.
    lo_store->mt_variant = temp110.
    mo_cut->set_variant_store( lo_store ).
    mo_cut->set_variant( `V1` ).
    init( ).

    cl_abap_unit_assert=>assert_equals( act = mo_report->p_carrid
                                        exp = `LH` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_secret ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_ucomm ).

  ENDMETHOD.

  METHOD events_screen_only.
    DATA temp112 TYPE string_table.
    DATA temp114 TYPE string_table.
    DATA temp116 TYPE string_table.

    " F4 and the multiple selection name their field in the argument - an
    " attribute that is no field of the screen opens nothing
    init( ).

    CLEAR temp112.
    INSERT `MT_ROW` INTO TABLE temp112.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp112 ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    CLEAR temp114.
    INSERT `MV_SECRET` INTO TABLE temp114.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp114 ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " a field of the screen still does

    CLEAR temp116.
    INSERT `s_code` INTO TABLE temp116.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp116 ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD submit_starts_report.
    DATA temp118 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp119 LIKE LINE OF temp118.
    DATA temp120 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_called LIKE temp120.
    FIELD-SYMBOLS <temp121> LIKE LINE OF lo_called->mt_cgui_submit.
    DATA temp122 LIKE sy-tabix.
    DATA lo_client TYPE REF TO ltcl_client.
    DATA temp123 TYPE REF TO ltcl_report.

    init( ).

    CLEAR temp118.

    temp119-name = `P_CARRID`.
    temp119-kind = `P`.
    temp119-low = `UA`.
    INSERT temp119 INTO TABLE temp118.
    mo_cut->submit( report = `LTCL_REPORT`
                    values = temp118 ).


    temp120 ?= mo_client->mo_called.

    lo_called = temp120.
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_called ).
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_skip ).


    temp122 = sy-tabix.
    READ TABLE lo_called->mt_cgui_submit INDEX 1 ASSIGNING <temp121>.
    sy-tabix = temp122.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp121>-low
                                        exp = `UA` ).

    " started, it runs without its selection screen

    CREATE OBJECT lo_client TYPE ltcl_client.
    lo_client->mo_app = lo_called.
    lo_client->mv_init = abap_true.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_called->mv_cgui_screen
                                        exp = `OUTPUT` ).

    temp123 ?= lo_called.
    cl_abap_unit_assert=>assert_equals( act = temp123->p_carrid
                                        exp = `UA` ).

    " Back on its output returns to the caller
    lo_client->mv_init = abap_false.
    lo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-back.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_true( lo_client->mv_left ).

  ENDMETHOD.

  METHOD link_holds_values.
    DATA temp124 LIKE mo_report->s_date.
    DATA temp125 LIKE LINE OF temp124.
    DATA lv_link TYPE string.
    DATA temp35 TYPE xsdboolean.
    DATA temp36 TYPE xsdboolean.
    DATA temp37 TYPE xsdboolean.
    DATA temp38 TYPE xsdboolean.

    mo_client->ms_get-s_config-origin = `https://host`.
    mo_client->ms_get-s_config-pathname = `/sap/bc/z2ui5`.
    mo_client->ms_get-s_config-search = `?sap-client=100&app_start=ltcl_report`.
    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->p_hidden = `X`.

    CLEAR temp124.

    temp125-sign = `I`.
    temp125-option = `BT`.
    temp125-low = `20260101`.
    temp125-high = `20260131`.
    INSERT temp125 INTO TABLE temp124.
    mo_report->s_date = temp124.


    lv_link = mo_cut->get_link( abap_true ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_link
                                         exp = `https://host/sap/bc/z2ui5?sap-client=100&app_start=ltcl_report*` ).

    temp35 = boolc( lv_link CS `p_carrid=LH` ).
    cl_abap_unit_assert=>assert_true( temp35 ).

    temp36 = boolc( lv_link CS `s_date=20260101..20260131` ).
    cl_abap_unit_assert=>assert_true( temp36 ).

    temp37 = boolc( lv_link CS `skip_screen=X` ).
    cl_abap_unit_assert=>assert_true( temp37 ).

    temp38 = boolc( lv_link CS `p_hidden` ).
    cl_abap_unit_assert=>assert_false( temp38 ).

  ENDMETHOD.

  METHOD parameter_id.
    DATA temp39 TYPE xsdboolean.

    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_TEST`
                              value = `LH` ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `zcgui_test` )
                                        exp = `LH` ).

    temp39 = boolc( mo_report->mv_cgui_spa CS `ZCGUI_TEST=LH` ).
    cl_abap_unit_assert=>assert_true( temp39 ).

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
    DATA temp126 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp127 LIKE LINE OF temp126.

    " first in every roundtrip, before the event - and in the background run
    init( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_starts
                                        exp = 2 ).

    CREATE OBJECT lo_job TYPE ltcl_report.

    CLEAR temp126.

    temp127-name = `P_CARRID`.
    temp127-kind = `P`.
    temp127-low = `LH`.
    INSERT temp127 INTO TABLE temp126.
    lo_job->cgui_run_in_background( temp126 ).
    cl_abap_unit_assert=>assert_equals( act = lo_job->mv_starts
                                        exp = 1 ).

  ENDMETHOD.

  METHOD transport_popup.
    DATA temp128 TYPE REF TO z2ui5_cl_cgui_transport.
    DATA lo_popup LIKE temp128.

    init( ).
    mo_cut->_popup( )->transport( `TR` ).

    temp128 ?= mo_client->mo_called.

    lo_popup = temp128.
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
    DATA temp40 TYPE xsdboolean.
    DATA lo_next TYPE REF TO z2ui5_cl_cgui_list.
    DATA temp41 TYPE xsdboolean.
    DATA temp42 TYPE xsdboolean.

    init( ).
    " outside a line selection: the list of list( )

    lo_list = mo_cut->list( ).

    temp40 = boolc( mo_cut->read_list( ) = lo_list ).
    cl_abap_unit_assert=>assert_true( temp40 ).

    " in at_line_selection( ): the list clicked, not the next level
    mo_cut->level_push( ).
    mo_cut->mv_cgui_on_line = abap_true.

    lo_next = mo_cut->list( ).

    temp41 = boolc( mo_cut->read_list( ) = lo_list ).
    cl_abap_unit_assert=>assert_true( temp41 ).

    temp42 = boolc( lo_next = lo_list ).
    cl_abap_unit_assert=>assert_false( temp42 ).
    mo_cut->mv_cgui_on_line = abap_false.

  ENDMETHOD.

  METHOD call_transaction.
    DATA temp129 TYPE REF TO ltcl_catalog.
    DATA temp130 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_called LIKE temp130.
    DATA temp131 TYPE REF TO z2ui5_cl_cgui_report.

    init( ).
    " a transaction of the catalog: its class with its variant

    CREATE OBJECT temp129 TYPE ltcl_catalog.
    mo_cut->set_catalog( temp129 ).
    mo_cut->call_transaction( `zfly` ).

    temp130 ?= mo_client->mo_called.

    lo_called = temp130.
    cl_abap_unit_assert=>assert_equals( act = cl_abap_typedescr=>describe_by_object_ref( lo_called )->get_relative_name( )
                                        exp = `Z2UI5_CL_CGUI_SAMPLE_04` ).
    cl_abap_unit_assert=>assert_equals( act = lo_called->mv_cgui_variant_start
                                        exp = `MINE` ).
    cl_abap_unit_assert=>assert_false( lo_called->mv_cgui_skip ).

    " no transaction of the catalog: the class; AND SKIP FIRST SCREEN
    mo_cut->call_transaction( code       = `LTCL_REPORT`
                              skip_first = abap_true ).

    temp131 ?= mo_client->mo_called.
    lo_called = temp131.
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_called ).
    cl_abap_unit_assert=>assert_true( lo_called->mv_cgui_skip ).

    " neither: an error, nothing starts
    CLEAR mo_client->mo_called.
    mo_cut->call_transaction( `ZGONE` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).
    cl_abap_unit_assert=>assert_true( mo_cut->mv_cgui_stop ).

  ENDMETHOD.

  METHOD call_intent.
    DATA temp132 TYPE REF TO ltcl_catalog.
    DATA temp133 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp134 LIKE LINE OF temp133.
    DATA lt_value LIKE temp133.
    DATA temp135 TYPE REF TO ltcl_report.
    DATA lo_called LIKE temp135.
    DATA lt_submit LIKE lo_called->mt_cgui_submit.
    FIELD-SYMBOLS <temp136> LIKE LINE OF lt_submit.
    DATA temp137 LIKE sy-tabix.
    FIELD-SYMBOLS <temp138> LIKE LINE OF mo_client->mt_action.
    DATA temp139 LIKE sy-tabix.
    FIELD-SYMBOLS <temp140> LIKE LINE OF mo_client->mt_action.
    DATA temp141 LIKE sy-tabix.
    DATA temp43 TYPE xsdboolean.
    DATA temp13 LIKE sy-subrc.

    init( ).

    CREATE OBJECT temp132 TYPE ltcl_catalog.
    mo_cut->set_catalog( temp132 ).

    CLEAR temp133.

    CLEAR temp134.
    temp134-name = `P_CARRID`.
    temp134-kind = z2ui5_cl_cgui_variant=>cs_kind-parameter.
    temp134-low = `LH`.
    INSERT temp134 INTO TABLE temp133.
    CLEAR temp134.
    temp134-name = `S_CODE`.
    temp134-kind = z2ui5_cl_cgui_variant=>cs_kind-select_option.
    temp134-sign = `I`.
    temp134-option = `BT`.
    temp134-low = `A`.
    temp134-high = `B`.
    INSERT temp134 INTO TABLE temp133.

    lt_value = temp133.

    " outside the launchpad: the transaction of the catalog with the intent
    mo_cut->call_intent( semantic_object = `airline`
                         values          = lt_value ).

    temp135 ?= mo_client->mo_called.

    lo_called = temp135.

    lt_submit = lo_called->mt_cgui_submit.


    temp137 = sy-tabix.
    READ TABLE lt_submit INDEX 1 ASSIGNING <temp136>.
    sy-tabix = temp137.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp136>-low
                                        exp = `LH` ).

    " inside: the cross-app navigation of the shell, the single values as
    " the startup parameters - CALL TRANSACTION of the tile alike
    CLEAR: mo_client->mo_called, mo_client->mt_action.
    mo_client->ms_get-check_launchpad_active = abap_true.
    mo_cut->call_intent( semantic_object = `Airline`
                         values          = lt_value ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp139 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp138>.
    sy-tabix = temp139.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp138>
                                        exp = `CROSS_APP_NAV_TO_EXT:{"semanticObject":"Airline","action":"display"}|{"P_CARRID":"LH"}` ).
    CLEAR mo_client->mt_action.
    mo_cut->call_transaction( `ZAIR` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp141 = sy-tabix.
    READ TABLE mo_client->mt_action INDEX 1 ASSIGNING <temp140>.
    sy-tabix = temp141.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp140>
                                         exp = `CROSS_APP_NAV_TO_EXT:*Airline*` ).

    " the shell shows the title of the report
    mo_cut->set_title( `Flights` ).
    mo_cut->view_display( ).


    READ TABLE mo_client->mt_action WITH KEY table_line = `SET_TITLE_LAUNCHPAD:Flights` TRANSPORTING NO FIELDS.
    temp13 = sy-subrc.
    temp43 = boolc( temp13 = 0 ).
    cl_abap_unit_assert=>assert_true( temp43 ).

  ENDMETHOD.

  METHOD popup_decide_list.

    TYPES temp7 TYPE STANDARD TABLE OF z2ui5_cl_cgui_popup=>ty_s_spopli WITH DEFAULT KEY.
DATA lt_list TYPE temp7.
    DATA temp142 LIKE lt_list.
    DATA temp143 LIKE LINE OF temp142.
    DATA temp144 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp144.
    DATA temp44 TYPE xsdboolean.

    init( ).
    " POPUP_TO_DECIDE_LIST: each VAROPTION an option, the answer its line

    CLEAR temp142.

    temp143-varoption = 'Packages'.
    INSERT temp143 INTO TABLE temp142.
    temp143-varoption = 'Source code'.
    INSERT temp143 INTO TABLE temp142.
    lt_list = temp142.
    mo_cut->popup_to_decide_list( question = `Which objects?`
                                  list     = lt_list
                                  then     = `ON_SURE` ).

    temp144 ?= mo_client->mo_called.

    lo_popup = temp144.
    " the popup's first roundtrip draws it
    mo_client->mv_init = abap_true.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mv_init = abap_false.

    temp44 = boolc( mo_client->mv_popup CS `Source code` ).
    cl_abap_unit_assert=>assert_true( temp44 ).
    mo_client->mv_event = `CGUI_POP_OPTION_2`.
    lo_popup->z2ui5_if_app~main( mo_client ).
    mo_client->mo_prev = lo_popup.
    mo_client->mv_event = z2ui5_cl_cgui_report=>cs_ucomm-popup_answer.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_then
                                        exp = `2` ).

  ENDMETHOD.

  METHOD popup_then.
    DATA temp145 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp145.
    DATA temp146 TYPE string_table.
    DATA temp148 TYPE REF TO z2ui5_cl_cgui_popup.

    init( ).
    " then: on both answers on_sure( answer ) runs, not at_user_command( )
    mo_cut->_popup( )->confirm( question = `Sure?`
                                then     = `on_sure` ).

    temp145 ?= mo_client->mo_called.

    lo_popup = temp145.
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

    CLEAR temp146.
    INSERT `First` INTO TABLE temp146.
    INSERT `Second` INTO TABLE temp146.
    mo_cut->popup_to_decide( question = `Which one?`
                             options  = temp146
                             then     = `ON_SURE` ).

    temp148 ?= mo_client->mo_called.
    lo_popup = temp148.
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
    DATA temp45 TYPE xsdboolean.
    DATA temp46 TYPE xsdboolean.
    DATA temp47 TYPE xsdboolean.
    DATA temp48 TYPE xsdboolean.
    DATA temp49 TYPE xsdboolean.
    DATA temp149 TYPE string_table.
    DATA temp50 TYPE xsdboolean.
    DATA temp151 TYPE string_table.
    DATA temp51 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    temp45 = boolc( mo_client->mv_view CS z2ui5_cl_cgui_alv=>cs_event-chart ).
    cl_abap_unit_assert=>assert_true( temp45 ).

    " the chart: the carriers, their seats - the first text, the first number
    event( z2ui5_cl_cgui_alv=>cs_event-chart ).

    temp46 = boolc( mo_client->mv_popup CS `&lt;svg` OR mo_client->mv_popup CS `<svg` ).
    cl_abap_unit_assert=>assert_true( temp46 ).

    temp47 = boolc( mo_client->mv_popup CS `selectedKey="SEATS"` ).
    cl_abap_unit_assert=>assert_true( temp47 ).

    temp48 = boolc( mo_client->mv_popup CS `UA` ).
    cl_abap_unit_assert=>assert_true( temp48 ).

    " the kinds of chart, a column - the pie

    temp49 = boolc( mo_client->mv_popup CS `SegmentedButton` ).
    cl_abap_unit_assert=>assert_true( temp49 ).

    CLEAR temp149.
    INSERT `KIND` INTO TABLE temp149.
    INSERT `PIE` INTO TABLE temp149.
    event( name = z2ui5_cl_cgui_alv=>cs_event-chart
           args = temp149 ).

    temp50 = boolc( mo_client->mv_popup CS `path d=` OR mo_client->mv_popup CS `circle cx=` ).
    cl_abap_unit_assert=>assert_true( temp50 ).

    " the rows counted instead

    CLEAR temp151.
    INSERT `VALUE` INTO TABLE temp151.
    INSERT `%COUNT` INTO TABLE temp151.
    event( name = z2ui5_cl_cgui_alv=>cs_event-chart
           args = temp151 ).

    temp51 = boolc( mo_client->mv_popup CS `selectedKey="SEATS"` ).
    cl_abap_unit_assert=>assert_false( temp51 ).

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
    FIELD-SYMBOLS <temp153> LIKE LINE OF lt_logged.
    DATA temp154 LIKE sy-tabix.
    DATA temp155 LIKE lt_return.
    DATA temp156 LIKE LINE OF temp155.
    DATA lo_bapi TYPE REF TO z2ui5_cl_cgui_log.
    DATA lo_popup TYPE REF TO z2ui5_cl_cgui_select.
    CREATE OBJECT lo_log TYPE z2ui5_cl_cgui_log.
    mo_cut->set_log( lo_log ).
    init( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    lt_logged = lo_log->z2ui5_if_cgui_log~get( ).


    temp154 = sy-tabix.
    READ TABLE lt_logged INDEX 1 ASSIGNING <temp153>.
    sy-tabix = temp154.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp153>-type
                                        exp = `E` ).

    " a log of another source - a BAPI's return table - in the popover

    CLEAR temp155.

    temp156-type = 'W'.
    temp156-message = 'Seats nearly gone'.
    INSERT temp156 INTO TABLE temp155.
    temp156-type = 'I'.
    temp156-message = 'Flight LH 400'.
    INSERT temp156 INTO TABLE temp155.
    lt_return = temp155.

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
    DATA temp157 TYPE REF TO ltcl_layout_store.
    DATA temp52 TYPE xsdboolean.
    DATA temp158 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp158.
    DATA temp53 TYPE xsdboolean.
    DATA temp14 LIKE sy-subrc.
    DATA temp15 LIKE sy-subrc.
    DATA temp16 LIKE sy-tabix.
    FIELD-SYMBOLS <temp159> LIKE LINE OF lo_popup->mt_field.
    DATA temp160 LIKE sy-tabix.
    FIELD-SYMBOLS <temp161> LIKE LINE OF lo_popup->mt_field.
    DATA temp162 LIKE sy-tabix.
    FIELD-SYMBOLS <temp163> LIKE LINE OF lo_popup->mt_field.
    DATA temp164 LIKE sy-tabix.
    FIELD-SYMBOLS <temp165> LIKE LINE OF lo_popup->mt_field.
    DATA temp166 LIKE sy-tabix.

    " the server store - the table of the variants: a parameter ID set in
    " one report is there in the next one, in any browser
    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_SRV`
                              value = `UA` ).

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp157 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp157 ).
    lo_next->z2ui5_if_app~main( lo_next_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_SRV` )
                                        exp = `UA` ).
    " the browser's storage control for them is gone

    temp52 = boolc( lo_next_client->mv_view CS `z2ui5_cgui_spa` ).
    cl_abap_unit_assert=>assert_false( temp52 ).

    " SU3 in the command field: the parameters in a popup - one changed,
    " one added, an emptied one deleted
    mo_cut->set_parameter_id( id    = `ZCGUI_DEL`
                              value = `X1` ).
    mo_cut->okcode_execute( `/nSU3` ).

    temp158 ?= mo_client->mo_called.

    lo_popup = temp158.




    temp15 = sy-subrc.
    temp16 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `ZCGUI_SRV` value = `UA` TRANSPORTING NO FIELDS.
    temp14 = sy-subrc.
    sy-subrc = temp15.
    sy-tabix = temp16.
    temp53 = boolc( temp14 = 0 ).
    cl_abap_unit_assert=>assert_true( temp53 ).


    temp160 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `ZCGUI_SRV` ASSIGNING <temp159>.
    sy-tabix = temp160.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp159>-value = `LH`.


    temp162 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `ZCGUI_DEL` ASSIGNING <temp161>.
    sy-tabix = temp162.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp161>-value = ``.


    temp164 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_ID` ASSIGNING <temp163>.
    sy-tabix = temp164.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp163>-value = `zcgui_add`.


    temp166 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_VALUE` ASSIGNING <temp165>.
    sy-tabix = temp166.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp165>-value = `0017`.
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
    DATA temp54 TYPE xsdboolean.
    DATA temp17 LIKE sy-subrc.
    DATA lo_next TYPE REF TO ltcl_report.
    DATA lo_next_client TYPE REF TO ltcl_client.
    DATA temp167 TYPE REF TO ltcl_layout_store.
    DATA temp55 TYPE xsdboolean.
    DATA temp18 LIKE sy-subrc.

    " set_draft( ): what is entered and not executed is kept with the
    " roundtrip
    mo_cut->set_draft( ).
    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-enter ).

    lt_variant = mo_cut->mo_cgui_store->load( mo_cut->variant_key( ) ).


    READ TABLE lt_variant WITH KEY name = z2ui5_cl_cgui_memory=>draft_name( ) TRANSPORTING NO FIELDS.
    temp17 = sy-subrc.
    temp54 = boolc( temp17 = 0 ).
    cl_abap_unit_assert=>assert_true( temp54 ).

    " the next start brings it back, with Discard Draft

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp167 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp167 ).
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
    temp18 = sy-subrc.
    temp55 = boolc( temp18 = 0 ).
    cl_abap_unit_assert=>assert_false( temp55 ).

  ENDMETHOD.

  METHOD submit_using_screen.
    DATA temp168 TYPE REF TO ltcl_report.
    DATA lo_called LIKE temp168.
    DATA lo_client TYPE REF TO ltcl_client.
    DATA temp56 TYPE xsdboolean.
    DATA temp169 TYPE REF TO ltcl_report.

    " SUBMIT ... USING SELECTION-SCREEN 1100 VIA SELECTION-SCREEN: the
    " report shows screen 1100, not its selection screen
    init( ).
    mo_cut->submit( report                 = `LTCL_REPORT`
                    via_selection_screen   = abap_true
                    using_selection_screen = `1100` ).

    temp168 ?= mo_client->mo_called.

    lo_called = temp168.

    CREATE OBJECT lo_client TYPE ltcl_client.
    lo_client->mo_app = lo_called.
    lo_client->mv_init = abap_true.
    lo_called->z2ui5_if_app~main( lo_client ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_client->mv_view
                                         exp = `*Note on 1100*` ).

    temp56 = boolc( lo_client->mv_view CS `Report of a variant` ).
    cl_abap_unit_assert=>assert_false( temp56 ).

    " as a window: the selection screen as a dialog box over the caller -
    " no view of its own
    CLEAR mo_client->mo_called.
    mo_cut->submit( report    = `LTCL_REPORT`
                    as_window = abap_true ).

    temp169 ?= mo_client->mo_called.
    lo_called = temp169.
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
    DATA temp170 TYPE string_table.
    DATA temp172 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp172.
    DATA temp57 TYPE xsdboolean.
    FIELD-SYMBOLS <temp173> LIKE LINE OF mo_cut->mt_cgui_field.
    DATA temp174 LIKE sy-tabix.

    " a row in the entity: the user parameters of the server store
    init( ).
    mo_cut->set_parameter_id( id    = `ZCGUI_ENT`
                              value = `X` ).

    " F4 on the field: the rows of the entity, the element named the value

    CLEAR temp170.
    INSERT `P_VAR` INTO TABLE temp170.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp170 ).

    temp172 ?= mo_client->mo_called.

    lo_select = temp172.
    ASSIGN lo_select->mr_source->* TO <rows>.

    temp57 = boolc( lines( <rows> ) > 0 ).
    cl_abap_unit_assert=>assert_true( temp57 ).

    " an entity that does not exist: no popup, the message of no help
    CLEAR mo_client->mo_called.


    temp174 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_field WITH KEY name = `P_VAR` ASSIGNING <temp173>.
    sy-tabix = temp174.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp173>-entity = `ZZZ_NO_SUCH_ENTITY`.
    mo_cut->value_help_ddic( `P_VAR` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD parameter_levels.
    DATA temp175 TYPE z2ui5_if_client=>ty_t_name_value.
    DATA temp176 LIKE LINE OF temp175.
    DATA temp177 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp177.
    FIELD-SYMBOLS <temp178> LIKE LINE OF lo_popup->mt_field.
    DATA temp179 LIKE sy-tabix.
    FIELD-SYMBOLS <temp180> LIKE LINE OF lo_popup->mt_field.
    DATA temp181 LIKE sy-tabix.
    DATA lt_spa_store TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    FIELD-SYMBOLS <temp182> LIKE LINE OF lt_spa_store.
    DATA temp183 LIKE sy-tabix.
    DATA lo_next TYPE REF TO ltcl_report.
    DATA lo_next_client TYPE REF TO ltcl_client.
    DATA temp184 TYPE REF TO ltcl_layout_store.

    " GET PARAMETER ID: the user's parameter, else the customizing one, else
    " the system parameter given in code
    init( ).

    CLEAR temp175.

    temp176-n = `zcgui_lvl`.
    temp176-v = `SYS`.
    INSERT temp176 INTO TABLE temp175.
    temp176-n = `ZCGUI_SYS`.
    temp176-v = `S1`.
    INSERT temp176 INTO TABLE temp175.
    mo_cut->set_system_parameters( temp175 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `SYS` ).

    " SPRO without the authorization: refused, nothing opens
    mo_cut->okcode_execute( `/nSPRO` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).

    " with it: the customizing parameters in a popup, one added
    mo_report->mv_customizing = abap_true.
    mo_cut->okcode_execute( `SPRO` ).

    temp177 ?= mo_client->mo_called.

    lo_popup = temp177.


    temp179 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_ID` ASSIGNING <temp178>.
    sy-tabix = temp179.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp178>-value = `zcgui_lvl`.


    temp181 = sy-tabix.
    READ TABLE lo_popup->mt_field WITH KEY name = `%NEW_VALUE` ASSIGNING <temp180>.
    sy-tabix = temp181.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp180>-value = `CUST`.
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


    temp183 = sy-tabix.
    READ TABLE lt_spa_store WITH KEY name = `%CUSTOMIZING` ASSIGNING <temp182>.
    sy-tabix = temp183.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp182>-shared ).

    " the customizing is on the server - the next report reads it, for a
    " user without a parameter of their own

    CREATE OBJECT lo_next TYPE ltcl_report.

    CREATE OBJECT lo_next_client TYPE ltcl_client.
    lo_next_client->mo_app = lo_next.
    lo_next_client->mv_init = abap_true.

    CREATE OBJECT temp184 TYPE ltcl_layout_store.
    lo_next->set_layout_store( temp184 ).
    lo_next->z2ui5_if_app~main( lo_next_client ).
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `USER` ).
    lo_next->mv_cgui_spa = ``.
    cl_abap_unit_assert=>assert_equals( act = lo_next->get_parameter_id( `ZCGUI_LVL` )
                                        exp = `CUST` ).

  ENDMETHOD.

  METHOD command_field.
    DATA temp185 TYPE REF TO ltcl_catalog.
    DATA temp58 TYPE xsdboolean.
    DATA lv_ctrl_k TYPE string.
    DATA temp59 TYPE xsdboolean.
    DATA temp19 LIKE sy-subrc.
    DATA temp20 LIKE sy-subrc.
    DATA temp21 LIKE sy-tabix.
    DATA lv_tab TYPE string.
    DATA temp60 TYPE xsdboolean.
    DATA temp22 LIKE sy-subrc.
    DATA temp23 LIKE sy-subrc.
    DATA temp24 LIKE sy-tabix.
    DATA lo_started TYPE REF TO z2ui5_cl_cgui_report.
    FIELD-SYMBOLS <temp186> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp187 LIKE sy-tabix.
    FIELD-SYMBOLS <temp188> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp189 LIKE sy-tabix.
    DATA lo_palette TYPE REF TO z2ui5_cl_cgui_select.
    DATA lt_rows TYPE z2ui5_cl_cgui_command=>ty_t_palette.
    DATA temp61 TYPE xsdboolean.
    DATA temp25 LIKE sy-subrc.
    DATA temp62 TYPE xsdboolean.
    DATA temp26 LIKE sy-subrc.

    mo_client->ms_get-s_config-origin = `https://host`.
    mo_client->ms_get-s_config-pathname = `/sap/bc/z2ui5`.
    mo_client->ms_get-s_config-search = `?sap-client=100&app_start=ltcl_report`.
    mo_cut->set_command_field( ).

    CREATE OBJECT temp185 TYPE ltcl_catalog.
    mo_cut->set_catalog( temp185 ).
    init( ).

    temp58 = boolc( mo_client->mv_view CS `CGUI_OKCODE` ).
    cl_abap_unit_assert=>assert_true( temp58 ).

    lv_ctrl_k = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:Ctrl+K\|CGUI_PALETTE\|MAIN|.




    temp20 = sy-subrc.
    temp21 = sy-tabix.
    READ TABLE mo_client->mt_action WITH KEY table_line = lv_ctrl_k TRANSPORTING NO FIELDS.
    temp19 = sy-subrc.
    sy-subrc = temp20.
    sy-tabix = temp21.
    temp59 = boolc( temp19 = 0 ).
    cl_abap_unit_assert=>assert_true( temp59 ).

    " an OK code of the screen - at_user_command( ), the field empty again
    mo_report->mv_cgui_okcode = ` mycmd `.
    event( z2ui5_cl_cgui_report=>cs_ucomm-okcode ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `MYCMD` ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_cgui_okcode ).

    " /o and a transaction: a new tab with the report and its variant
    mo_cut->okcode_execute( `/oZFLY` ).

    lv_tab = |{ z2ui5_if_client=>cs_event-open_new_tab }:https://host/sap/bc/z2ui5?sap-client=100&app_start=z2ui5_cl_cgui_sample_04&variant=MINE|.




    temp23 = sy-subrc.
    temp24 = sy-tabix.
    READ TABLE mo_client->mt_action WITH KEY table_line = lv_tab TRANSPORTING NO FIELDS.
    temp22 = sy-subrc.
    sy-subrc = temp23.
    sy-tabix = temp24.
    temp60 = boolc( temp22 = 0 ).
    cl_abap_unit_assert=>assert_true( temp60 ).

    " the transaction in this window
    mo_cut->okcode_execute( `zfly` ).

    lo_started ?= mo_client->mo_called.
    cl_abap_unit_assert=>assert_bound( lo_started ).

    " what is no report and no command says so
    CLEAR mo_client->mo_called.
    mo_cut->okcode_execute( `/nZGONE` ).
    cl_abap_unit_assert=>assert_not_bound( mo_client->mo_called ).


    temp187 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX lines( mo_cut->mt_cgui_msg ) ASSIGNING <temp186>.
    sy-tabix = temp187.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp186>-text
                                         exp = `*ZGONE*` ).
    mo_cut->okcode_execute( `/x` ).


    temp189 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX lines( mo_cut->mt_cgui_msg ) ASSIGNING <temp188>.
    sy-tabix = temp189.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp188>-type
                                        exp = `E` ).

    " Ctrl+K: the palette - the transactions and Execute
    event( z2ui5_cl_cgui_report=>cs_ucomm-palette ).

    lo_palette ?= mo_client->mo_called.
    cl_abap_unit_assert=>assert_bound( lo_palette ).

    lt_rows = z2ui5_cl_cgui_command=>palette_rows( mo_cut->command_ctx( ) ).


    READ TABLE lt_rows WITH KEY command = `ZFLY` TRANSPORTING NO FIELDS.
    temp25 = sy-subrc.
    temp61 = boolc( temp25 = 0 ).
    cl_abap_unit_assert=>assert_true( temp61 ).


    READ TABLE lt_rows WITH KEY command = `ONLI` TRANSPORTING NO FIELDS.
    temp26 = sy-subrc.
    temp62 = boolc( temp26 = 0 ).
    cl_abap_unit_assert=>assert_true( temp62 ).

  ENDMETHOD.

  METHOD execute_in_background.

    DATA lo_job TYPE REF TO ltcl_job.
    DATA temp63 TYPE xsdboolean.
    DATA temp64 TYPE xsdboolean.
    DATA temp27 LIKE sy-subrc.
    DATA temp28 LIKE sy-subrc.
    DATA temp29 LIKE sy-tabix.
    FIELD-SYMBOLS <temp190> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp191 LIKE sy-tabix.
    DATA lo_run TYPE REF TO ltcl_report.
    DATA lv_pdf TYPE xstring.
    CREATE OBJECT lo_job TYPE ltcl_job.
    mo_cut->set_job( lo_job ).
    init( ).

    temp63 = boolc( mo_client->mv_view CS `CGUI_BACKGROUND` ).
    cl_abap_unit_assert=>assert_true( temp63 ).

    " the checks of Execute first - the required field is empty
    event( z2ui5_cl_cgui_report=>cs_ucomm-background ).
    cl_abap_unit_assert=>assert_initial( lo_job->mv_report ).

    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-background ).
    cl_abap_unit_assert=>assert_equals( act = lo_job->mv_report
                                        exp = `LTCL_REPORT` ).




    temp28 = sy-subrc.
    temp29 = sy-tabix.
    READ TABLE lo_job->mt_values WITH KEY name = `P_CARRID` low = `LH` TRANSPORTING NO FIELDS.
    temp27 = sy-subrc.
    sy-subrc = temp28.
    sy-tabix = temp29.
    temp64 = boolc( temp27 = 0 ).
    cl_abap_unit_assert=>assert_true( temp64 ).


    temp191 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX 1 ASSIGNING <temp190>.
    sy-tabix = temp191.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = <temp190>-text
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
    DATA temp65 TYPE xsdboolean.
    DATA temp66 TYPE xsdboolean.
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


    temp65 = boolc( mo_report->mv_cgui_history CS |P_CARRID{ lv_tab }LH{ lv_tab }UA| ).
    cl_abap_unit_assert=>assert_true( temp65 ).

    temp66 = boolc( mo_report->mv_cgui_history CS |UA{ lv_tab }LH| ).
    cl_abap_unit_assert=>assert_false( temp66 ).

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
    DATA temp67 TYPE xsdboolean.
    DATA temp30 LIKE sy-subrc.
    DATA temp68 TYPE xsdboolean.
    DATA temp31 LIKE sy-subrc.

    init( ).


    lv_f8 = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:F8\|CGUI_EXECUTE\|MAIN|.

    lv_f3 = |{ z2ui5_if_client=>cs_event-keyboard_shortcut }:F3\|CGUI_BACK\|MAIN|.


    READ TABLE mo_client->mt_action WITH KEY table_line = lv_f8 TRANSPORTING NO FIELDS.
    temp30 = sy-subrc.
    temp67 = boolc( temp30 = 0 ).
    cl_abap_unit_assert=>assert_true( temp67 ).


    READ TABLE mo_client->mt_action WITH KEY table_line = lv_f3 TRANSPORTING NO FIELDS.
    temp31 = sy-subrc.
    temp68 = boolc( temp31 = 0 ).
    cl_abap_unit_assert=>assert_true( temp68 ).

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
    DATA temp192 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA temp193 LIKE LINE OF temp192.
    DATA lo_list TYPE REF TO z2ui5_cl_cgui_list.
    DATA lt_msg TYPE z2ui5_cl_cgui_report=>ty_t_cgui_message.
    DATA lt_text TYPE string_table.
    FIELD-SYMBOLS <temp194> LIKE LINE OF lt_text.
    DATA temp195 LIKE sy-tabix.
    DATA lo_empty TYPE REF TO ltcl_report.
    DATA temp196 TYPE z2ui5_cl_cgui_variant=>ty_t_value.
    DATA lo_none TYPE REF TO z2ui5_cl_cgui_list.
    DATA lt_error TYPE z2ui5_cl_cgui_report=>ty_t_cgui_message.
    FIELD-SYMBOLS <temp197> LIKE LINE OF lt_error.
    DATA temp198 LIKE sy-tabix.
    CLEAR temp192.

    temp193-name = `P_CARRID`.
    temp193-kind = `P`.
    temp193-low = `LH`.
    INSERT temp193 INTO TABLE temp192.


    mo_report->cgui_run_in_background(
      EXPORTING values   = temp192
      IMPORTING list     = lo_list
                messages = lt_msg ).

    cl_abap_unit_assert=>assert_bound( lo_list ).
    cl_abap_unit_assert=>assert_true( mo_report->mv_end ).

    lt_text = lo_list->to_text( ).


    temp195 = sy-tabix.
    READ TABLE lt_text INDEX 1 ASSIGNING <temp194>.
    sy-tabix = temp195.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp194>
                                        exp = `HEADER` ).
    cl_abap_unit_assert=>assert_initial( lt_msg ).

    " a required field missing - no output, the error as message

    CREATE OBJECT lo_empty TYPE ltcl_report.

    CLEAR temp196.


    lo_empty->cgui_run_in_background( EXPORTING values   = temp196
                                      IMPORTING list     = lo_none
                                                messages = lt_error ).
    cl_abap_unit_assert=>assert_not_bound( lo_none ).


    temp198 = sy-tabix.
    READ TABLE lt_error INDEX 1 ASSIGNING <temp197>.
    sy-tabix = temp198.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp197>-type
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

    DATA temp199 LIKE mo_report->s_code.
    DATA temp200 LIKE LINE OF temp199.
    DATA temp201 TYPE string_table.
    DATA temp203 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_popup LIKE temp203.
    FIELD-SYMBOLS <temp204> LIKE LINE OF lo_popup->mt_row.
    DATA temp205 LIKE sy-tabix.
    FIELD-SYMBOLS <temp206> LIKE LINE OF mo_report->s_code.
    DATA temp207 LIKE sy-tabix.
    FIELD-SYMBOLS <temp208> LIKE LINE OF mo_report->s_code.
    DATA temp209 LIKE sy-tabix.
    CLEAR temp199.

    temp200-sign = `I`.
    temp200-option = `EQ`.
    temp200-low = `A`.
    INSERT temp200 INTO TABLE temp199.
    temp200-sign = `E`.
    temp200-option = `EQ`.
    temp200-low = `B`.
    INSERT temp200 INTO TABLE temp199.
    mo_report->s_code = temp199.
    init( ).

    CLEAR temp201.
    INSERT `S_CODE` INTO TABLE temp201.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp201 ).


    temp203 ?= mo_client->mo_called.

    lo_popup = temp203.
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->mt_row )
                                        exp = 2 ).


    temp205 = sy-tabix.
    READ TABLE lo_popup->mt_row INDEX 2 ASSIGNING <temp204>.
    sy-tabix = temp205.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp204>-low = `c`.
    range_popup_leave( z2ui5_cl_cgui_range=>cs_event-ok ).

    " the excluding line stays one - and is in upper case like the field


    temp207 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 2 ASSIGNING <temp206>.
    sy-tabix = temp207.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp206>-sign
                                        exp = `E` ).


    temp209 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 2 ASSIGNING <temp208>.
    sy-tabix = temp209.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp208>-low
                                        exp = `C` ).

  ENDMETHOD.

  METHOD range_f4_returns_to_popup.

    DATA temp210 LIKE mo_report->s_code.
    DATA temp211 LIKE LINE OF temp210.
    DATA temp212 TYPE string_table.
    DATA temp214 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_first LIKE temp214.
    DATA temp215 TYPE string_table.
    FIELD-SYMBOLS <temp8> LIKE LINE OF lo_first->mt_row.
    DATA temp9 LIKE sy-tabix.
    DATA temp217 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_again LIKE temp217.
    DATA temp69 TYPE xsdboolean.
    FIELD-SYMBOLS <temp218> LIKE LINE OF lo_again->mt_row.
    DATA temp219 LIKE sy-tabix.
    CLEAR temp210.

    temp211-sign = `E`.
    temp211-option = `EQ`.
    temp211-low = `B`.
    INSERT temp211 INTO TABLE temp210.
    mo_report->s_code = temp210.
    init( ).

    CLEAR temp212.
    INSERT `S_CODE` INTO TABLE temp212.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-select_option
           args = temp212 ).

    temp214 ?= mo_client->mo_called.

    lo_first = temp214.

    " F4 on line 1: the code has no value help - the report says so and
    " opens the popup again with the lines as they were

    CLEAR temp215.


    temp9 = sy-tabix.
    READ TABLE lo_first->mt_row INDEX 1 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    INSERT <temp8>-key INTO TABLE temp215.
    INSERT `LOW` INTO TABLE temp215.
    range_popup_leave( event = z2ui5_cl_cgui_range=>cs_event-f4
                       args  = temp215 ).

    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

    temp217 ?= mo_client->mo_called.

    lo_again = temp217.

    temp69 = boolc( lo_again = lo_first ).
    cl_abap_unit_assert=>assert_false( temp69 ).


    temp219 = sy-tabix.
    READ TABLE lo_again->mt_row INDEX 1 ASSIGNING <temp218>.
    sy-tabix = temp219.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp218>-sign
                                        exp = `E` ).
    cl_abap_unit_assert=>assert_false( mo_cut->mv_cgui_range_f4 ).
    " the select-option itself is untouched until OK
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 1 ).

  ENDMETHOD.

  METHOD f4_keeps_other_lines.

    DATA lt_pick TYPE ty_t_pick.
    DATA temp220 LIKE mo_report->s_code.
    DATA temp221 LIKE LINE OF temp220.
    DATA temp222 TYPE ltcl_test=>ty_t_pick.
    DATA temp223 LIKE LINE OF temp222.
    DATA lo_select TYPE REF TO z2ui5_cl_cgui_select.
    DATA temp70 TYPE xsdboolean.
    DATA temp32 LIKE sy-subrc.
    DATA temp71 TYPE xsdboolean.
    DATA temp33 LIKE sy-subrc.
    DATA temp72 TYPE xsdboolean.
    DATA temp34 LIKE sy-subrc.

    init( ).

    CLEAR temp220.

    CLEAR temp221.
    temp221-sign = `I`.
    temp221-option = `BT`.
    temp221-low = `A`.
    temp221-high = `C`.
    INSERT temp221 INTO TABLE temp220.
    CLEAR temp221.
    temp221-sign = `I`.
    temp221-option = `EQ`.
    temp221-low = `Q`.
    INSERT temp221 INTO TABLE temp220.
    CLEAR temp221.
    temp221-sign = `E`.
    temp221-option = `EQ`.
    temp221-low = `B`.
    INSERT temp221 INTO TABLE temp220.
    mo_report->s_code = temp220.

    CLEAR temp222.

    temp223-value = `X`.
    INSERT temp223 INTO TABLE temp222.
    temp223-value = `Y`.
    INSERT temp223 INTO TABLE temp222.
    lt_pick = temp222.

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
    temp32 = sy-subrc.
    temp70 = boolc( temp32 = 0 ).
    cl_abap_unit_assert=>assert_true( temp70 ).


    READ TABLE mo_report->s_code WITH KEY sign = `E` low = `B` TRANSPORTING NO FIELDS.
    temp33 = sy-subrc.
    temp71 = boolc( temp33 = 0 ).
    cl_abap_unit_assert=>assert_true( temp71 ).


    READ TABLE mo_report->s_code WITH KEY low = `Q` TRANSPORTING NO FIELDS.
    temp34 = sy-subrc.
    temp72 = boolc( temp34 = 0 ).
    cl_abap_unit_assert=>assert_false( temp72 ).

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
    DATA temp224 LIKE lt_sval.
    DATA temp225 LIKE LINE OF temp224.
    DATA temp226 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA lo_popup LIKE temp226.
    FIELD-SYMBOLS <temp227> LIKE LINE OF lo_popup->mt_field.
    DATA temp228 LIKE sy-tabix.
    FIELD-SYMBOLS <temp229> LIKE LINE OF lo_popup->mt_field.
    DATA temp230 LIKE sy-tabix.
    FIELD-SYMBOLS <temp231> LIKE LINE OF lo_popup->mt_field.
    DATA temp232 LIKE sy-tabix.
    FIELD-SYMBOLS <temp233> LIKE LINE OF lo_popup->mt_field.
    DATA temp234 LIKE sy-tabix.
    FIELD-SYMBOLS <temp235> LIKE LINE OF lo_popup->mt_field.
    DATA temp236 LIKE sy-tabix.
    DATA temp237 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA temp238 LIKE LINE OF temp237.
    FIELD-SYMBOLS <temp239> LIKE LINE OF lt_sval.
    DATA temp240 LIKE sy-tabix.
    FIELD-SYMBOLS <temp241> LIKE LINE OF lt_sval.
    DATA temp242 LIKE sy-tabix.
    FIELD-SYMBOLS <temp243> LIKE LINE OF lt_sval.
    DATA temp244 LIKE sy-tabix.

    init( ).

    CLEAR temp224.

    CLEAR temp225.
    temp225-tabname = 'SFLIGHT'.
    temp225-fieldname = 'carrid'.
    temp225-fieldtext = 'Airline'.
    temp225-value = 'LH'.
    temp225-field_obl = 'X'.
    INSERT temp225 INTO TABLE temp224.
    CLEAR temp225.
    temp225-tabname = 'SFLIGHT'.
    temp225-fieldname = 'CONNID'.
    INSERT temp225 INTO TABLE temp224.
    lt_sval = temp224.
    mo_cut->popup_get_values_sval( sval  = lt_sval
                                   ucomm = `VALUES`
                                   title = `Flight` ).

    temp226 ?= mo_client->mo_called.

    lo_popup = temp226.


    temp228 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp227>.
    sy-tabix = temp228.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp227>-name
                                        exp = `CARRID` ).


    temp230 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp229>.
    sy-tabix = temp230.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp229>-text
                                        exp = `Airline` ).


    temp232 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp231>.
    sy-tabix = temp232.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp231>-value
                                        exp = `LH` ).


    temp234 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 1 ASSIGNING <temp233>.
    sy-tabix = temp234.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp233>-required ).


    temp236 = sy-tabix.
    READ TABLE lo_popup->mt_field INDEX 2 ASSIGNING <temp235>.
    sy-tabix = temp236.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp235>-text
                                        exp = `CONNID` ).

    " what the user entered, back into the table - and into an empty one

    CLEAR temp237.

    temp238-name = `CARRID`.
    temp238-text = `Airline`.
    temp238-value = `AA`.
    INSERT temp238 INTO TABLE temp237.
    temp238-name = `CONNID`.
    temp238-text = `CONNID`.
    temp238-value = `0017`.
    INSERT temp238 INTO TABLE temp237.
    mo_cut->mt_cgui_popup_values = temp237.
    mo_cut->popup_values_sval( CHANGING sval = lt_sval ).


    temp240 = sy-tabix.
    READ TABLE lt_sval INDEX 2 ASSIGNING <temp239>.
    sy-tabix = temp240.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp239>-value
                                        exp = `0017` ).


    temp242 = sy-tabix.
    READ TABLE lt_sval INDEX 1 ASSIGNING <temp241>.
    sy-tabix = temp242.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp241>-tabname
                                        exp = `SFLIGHT` ).
    CLEAR lt_sval.
    mo_cut->popup_values_sval( CHANGING sval = lt_sval ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_sval )
                                        exp = 2 ).


    temp244 = sy-tabix.
    READ TABLE lt_sval INDEX 1 ASSIGNING <temp243>.
    sy-tabix = temp244.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp243>-fieldname
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD popups_of_the_project.
        DATA temp245 TYPE REF TO z2ui5_cl_cgui_popup.
    DATA temp246 LIKE mo_report->s_code.
    DATA temp247 LIKE LINE OF temp246.
    DATA temp248 TYPE ty_t_pick.
    DATA temp249 LIKE LINE OF temp248.
        DATA temp250 TYPE REF TO z2ui5_cl_cgui_select.

    " every popup of the runtime is a class of the project
    init( ).
    mo_cut->popup_to_confirm( question = `Sure?`
                              ucomm    = `DO_IT` ).
    TRY.

        temp245 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp245 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_popup` ).
    ENDTRY.

    " OK leaves with the user command
    mo_client->mv_event = `CGUI_POP_OK`.
    mo_client->mo_called->main( mo_client ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    CLEAR mo_client->mv_event.


    CLEAR temp246.

    temp247-sign = `I`.
    temp247-option = `EQ`.
    temp247-low = `A`.
    INSERT temp247 INTO TABLE temp246.
    mo_report->s_code = temp246.
    mo_cut->mv_cgui_value_field = `S_CODE`.

    CLEAR temp248.

    temp249-value = `A`.
    INSERT temp249 INTO TABLE temp248.
    temp249-value = `B`.
    INSERT temp249 INTO TABLE temp248.
    mo_cut->value_help_popup( tab = temp248
                              col = `VALUE` ).
    TRY.

        temp250 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp250 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_select` ).
    ENDTRY.

  ENDMETHOD.

  METHOD short_api.
    FIELD-SYMBOLS <temp251> LIKE LINE OF mo_cut->mt_cgui_msg.
    DATA temp252 LIKE sy-tabix.
    DATA temp253 TYPE string_table.
        DATA temp255 TYPE REF TO z2ui5_cl_cgui_popup.

    init( ).
    " _msg( ): message( ), the methods chain - a warning and a toast
    mo_cut->_msg( )->w( `Careful` )->s( `Done` ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( mo_cut->mt_cgui_msg ) ).


    temp252 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_msg INDEX 1 ASSIGNING <temp251>.
    sy-tabix = temp252.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `W`
                                        act = <temp251>-type ).
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

    CLEAR temp253.
    INSERT `First` INTO TABLE temp253.
    INSERT `Second` INTO TABLE temp253.
    mo_cut->_popup( )->decide( question = `Which one?`
                               options  = temp253
                               ucomm    = `PICK` ).
    TRY.

        temp255 ?= mo_client->mo_called.
        cl_abap_unit_assert=>assert_bound( temp255 ).
      CATCH cx_sy_move_cast_error.
        cl_abap_unit_assert=>fail( `not a z2ui5_cl_cgui_popup` ).
    ENDTRY.
    CLEAR mo_client->mo_called.
    mo_cut->_popup( )->confirm( question = `Sure?`
                                ucomm    = `DO_IT` ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).

  ENDMETHOD.

  METHOD alv_layout_default.
    DATA temp73 TYPE xsdboolean.
    DATA temp256 TYPE REF TO z2ui5_cl_cgui_layout.
    DATA lo_layout LIKE temp256.
    FIELD-SYMBOLS <temp257> LIKE LINE OF lo_layout->mt_row.
    DATA temp258 LIKE sy-tabix.
    DATA temp74 TYPE xsdboolean.
    DATA temp259 TYPE REF TO ltcl_layout_store.
    DATA lo_store LIKE temp259.
    FIELD-SYMBOLS <temp260> LIKE LINE OF lo_store->mt_layout.
    DATA temp261 LIKE sy-tabix.
    DATA lt_catalog TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp75 TYPE xsdboolean.
    DATA temp35 LIKE sy-subrc.
    DATA temp76 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    temp73 = boolc( mo_client->mv_view CS `sortProperty="SEATS"` ).
    cl_abap_unit_assert=>assert_true( temp73 ).

    " the layout button opens the dialog - SEATS hidden, saved as default
    event( z2ui5_cl_cgui_alv=>cs_event-layout ).

    temp256 ?= mo_client->mo_called.

    lo_layout = temp256.


    temp258 = sy-tabix.
    READ TABLE lo_layout->mt_row WITH KEY name = `SEATS` ASSIGNING <temp257>.
    sy-tabix = temp258.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp257>-visible = abap_false.
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

    temp74 = boolc( mo_client->mv_view CS `sortProperty="SEATS"` ).
    cl_abap_unit_assert=>assert_false( temp74 ).
    " kept in the layout store, under the attribute the ALV shows

    temp259 ?= mo_cut->mo_cgui_lay_store.

    lo_store = temp259.


    temp261 = sy-tabix.
    READ TABLE lo_store->mt_layout WITH KEY name = `MINE` ASSIGNING <temp260>.
    sy-tabix = temp261.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_true( <temp260>-is_default ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->layout_handle( )
                                        exp = `MT_ROW` ).

    lt_catalog = z2ui5_cl_cgui_memory=>variant_catalog( mo_cut->memory_ctx( ) ).


    READ TABLE lt_catalog WITH KEY name = `#L#MINE` TRANSPORTING NO FIELDS.
    temp35 = sy-subrc.
    temp75 = boolc( temp35 = 0 ).
    cl_abap_unit_assert=>assert_false( temp75 ).

    " the next run starts with the default layout - the switch of the test
    " is no field of the screen, the restart after the list resets it
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).
    mo_report->mv_alv = abap_true.
    CLEAR mo_cut->mv_cgui_layout.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_layout
                                        exp = `MINE` ).

    temp76 = boolc( mo_client->mv_view CS `sortProperty="SEATS"` ).
    cl_abap_unit_assert=>assert_false( temp76 ).

  ENDMETHOD.

  METHOD alv_layout_without_store.
    DATA temp262 TYPE REF TO z2ui5_cl_cgui_layout.
    DATA lo_layout LIKE temp262.
    FIELD-SYMBOLS <temp263> LIKE LINE OF lo_layout->mt_row.
    DATA temp264 LIKE sy-tabix.
    DATA lt_catalog TYPE z2ui5_cl_cgui_variant=>ty_t_variant.
    DATA temp77 TYPE xsdboolean.
    DATA temp36 LIKE sy-subrc.

    " no layout store - the layouts are kept with the selection variants
    mo_cut->set_layout_store( ).
    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    event( z2ui5_cl_cgui_alv=>cs_event-layout ).

    temp262 ?= mo_client->mo_called.

    lo_layout = temp262.



    temp264 = sy-tabix.
    READ TABLE lo_layout->mt_row WITH KEY name = `SEATS` ASSIGNING <temp263>.
    sy-tabix = temp264.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp263>-visible = abap_false.
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
    temp36 = sy-subrc.
    temp77 = boolc( temp36 = 0 ).
    cl_abap_unit_assert=>assert_true( temp77 ).

  ENDMETHOD.

  METHOD value_check_and_block.
    DATA temp78 TYPE xsdboolean.
    DATA temp37 LIKE sy-subrc.


    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->p_check = `Q`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " VALUE CHECK stops the run at the field - before ON BLOCK
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).


    READ TABLE mo_cut->mt_cgui_log WITH KEY type = `E` field = `P_CHECK` TRANSPORTING NO FIELDS.
    temp37 = sy-subrc.
    temp78 = boolc( temp37 = 0 ).
    cl_abap_unit_assert=>assert_true( temp78 ).
    cl_abap_unit_assert=>assert_initial( mo_report->mv_block ).

    mo_report->p_check = `X`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_block
                                        exp = `B1` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).

  ENDMETHOD.

  METHOD footer_print_function_key.
    DATA temp79 TYPE xsdboolean.
    DATA temp265 TYPE z2ui5_cl_cgui_alv=>ty_t_function.
    DATA temp266 LIKE LINE OF temp265.
    DATA temp10 TYPE z2ui5_cl_cgui_report=>ty_t_shortcut.
    DATA temp11 LIKE LINE OF temp10.
    DATA temp1 TYPE string_table.
    DATA temp80 TYPE xsdboolean.
    DATA temp81 TYPE xsdboolean.
    DATA temp38 LIKE sy-subrc.
    DATA temp82 TYPE xsdboolean.
    DATA temp39 LIKE sy-subrc.
    DATA temp83 TYPE xsdboolean.
    DATA temp84 TYPE xsdboolean.
    DATA temp85 TYPE xsdboolean.
    DATA lt_print TYPE string_table.
    DATA temp86 TYPE xsdboolean.
    DATA temp40 LIKE sy-subrc.
    DATA temp87 TYPE xsdboolean.
    DATA temp41 LIKE sy-subrc.

    init( ).
    " the function key of the selection screen

    temp79 = boolc( mo_client->mv_view CS `EVENT:FC01` ).
    cl_abap_unit_assert=>assert_true( temp79 ).
    event( `FC01` ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_ucomm
                                        exp = `FC01` ).

    mo_report->p_carrid = `LH`.

    CLEAR temp265.

    temp266-name = `SAVE`.
    temp266-text = `Save`.
    INSERT temp266 INTO TABLE temp265.
    temp266-name = `DELE`.
    temp266-text = `Delete`.
    INSERT temp266 INTO TABLE temp265.

    CLEAR temp10.

    temp11-key = `F5`.
    temp11-ucomm = `SAVE`.
    INSERT temp11 INTO TABLE temp10.
    temp11-key = `Shift+F2`.
    temp11-ucomm = `DELE`.
    INSERT temp11 INTO TABLE temp10.

    CLEAR temp1.
    INSERT `dele` INTO TABLE temp1.
    mo_cut->set_pf_status( functions = temp265
                           shortcuts = temp10
                           excluding = temp1 ).
    CLEAR mo_client->mt_action.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " EXCLUDING leaves out the button and the key of DELE

    temp80 = boolc( mo_client->mv_view CS `EVENT:DELE` ).
    cl_abap_unit_assert=>assert_false( temp80 ).


    READ TABLE mo_client->mt_action WITH KEY table_line = `KEYBOARD_SHORTCUT:F5|SAVE|MAIN` TRANSPORTING NO FIELDS.
    temp38 = sy-subrc.
    temp81 = boolc( temp38 = 0 ).
    cl_abap_unit_assert=>assert_true( temp81 ).


    READ TABLE mo_client->mt_action WITH KEY table_line = `KEYBOARD_SHORTCUT:Shift+F2|DELE|MAIN` TRANSPORTING NO FIELDS.
    temp39 = sy-subrc.
    temp82 = boolc( temp39 = 0 ).
    cl_abap_unit_assert=>assert_false( temp82 ).

    " END-OF-PAGE with the page number, the PF-STATUS and print

    temp83 = boolc( mo_client->mv_view CS `FOOT 1` ).
    cl_abap_unit_assert=>assert_true( temp83 ).

    temp84 = boolc( mo_client->mv_view CS `EVENT:SAVE` ).
    cl_abap_unit_assert=>assert_true( temp84 ).

    temp85 = boolc( mo_client->mv_view CS `EVENT:CGUI_PRINT` ).
    cl_abap_unit_assert=>assert_true( temp85 ).

    lt_print = mo_cut->print_lines( ).


    READ TABLE lt_print WITH KEY table_line = `row1` TRANSPORTING NO FIELDS.
    temp40 = sy-subrc.
    temp86 = boolc( temp40 = 0 ).
    cl_abap_unit_assert=>assert_true( temp86 ).


    READ TABLE lt_print WITH KEY table_line = `FOOT 1` TRANSPORTING NO FIELDS.
    temp41 = sy-subrc.
    temp87 = boolc( temp41 = 0 ).
    cl_abap_unit_assert=>assert_true( temp87 ).

  ENDMETHOD.

  METHOD alv_paging_maps_rows.
    DATA lv_rows TYPE i.
    DATA temp88 TYPE xsdboolean.
    DATA temp267 TYPE string_table.
    DATA temp89 TYPE xsdboolean.
    DATA temp269 LIKE mo_client->mt_window_order.
    DATA temp271 TYPE string_table.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    lv_rows = lines( mo_report->mt_row ).

    temp88 = boolc( lv_rows >= 2 ).
    cl_abap_unit_assert=>assert_true( temp88 ).

    " one row a window: the grid binds the table itself with window_bind_tab( ) -
    " no copy of a page, the title counts all rows
    mo_cut->mo_cgui_alv->set_paging( 1 ).

    CLEAR temp267.
    INSERT `` INTO TABLE temp267.
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = temp267 ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_not_bound( mo_cut->mr_cgui_alv_page ).

    temp89 = boolc( mo_client->mv_view CS |({ lv_rows })| ).
    cl_abap_unit_assert=>assert_true( temp89 ).

    " the server shows the rows in its own order - the last row first: a
    " line selection on the first row shown is the last row of the table

    CLEAR temp269.
    INSERT lv_rows INTO TABLE temp269.
    mo_client->mt_window_order = temp269.
    DO lv_rows - 1 TIMES.
      INSERT sy-index INTO TABLE mo_client->mt_window_order.
    ENDDO.

    CLEAR temp271.
    INSERT `/XX/MT_ROW/0` INTO TABLE temp271.
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = temp271 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = lv_rows ).

  ENDMETHOD.

  METHOD alv_paging_filtered_maps_rows.
    DATA temp273 TYPE string_table.
    DATA lv_copy TYPE i.
    DATA temp90 TYPE xsdboolean.
    DATA lv_row TYPE i.
    FIELD-SYMBOLS <temp12> LIKE LINE OF mo_cut->mt_cgui_alv_index.
    DATA temp13 LIKE sy-tabix.
    DATA temp275 LIKE mo_client->mt_window_order.
    DATA temp277 TYPE string_table.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " filtered and large: the copy of the rows the filter lets through is
    " bound with window_bind_tab( ) - a position leads to the copy's row first,
    " the copy's row to the table's
    mo_cut->mo_cgui_alv->set_paging( 1 ).

    CLEAR temp273.
    INSERT `UA` INTO TABLE temp273.
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = temp273 ).
    cl_abap_unit_assert=>assert_bound( mo_cut->mr_cgui_alv_page ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_window
                                        exp = 1 ).

    lv_copy = lines( mo_cut->mt_cgui_alv_index ).

    temp90 = boolc( lv_copy >= 1 ).
    cl_abap_unit_assert=>assert_true( temp90 ).

    " read before the event: the line selection leaves the grid, which
    " clears the copy and its index



    temp13 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_alv_index INDEX lv_copy ASSIGNING <temp12>.
    sy-tabix = temp13.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_row = <temp12>.

    CLEAR temp275.
    INSERT lv_copy INTO TABLE temp275.
    mo_client->mt_window_order = temp275.

    CLEAR temp277.
    INSERT `/XX/MR_CGUI_ALV_PAGE/0` INTO TABLE temp277.
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = temp277 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = lv_row ).

  ENDMETHOD.

  METHOD alv_filter_by_popup.
    DATA temp279 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp279.
    DATA temp280 TYPE string_table.
    DATA temp282 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_range LIKE temp282.
    DATA temp283 TYPE z2ui5_cl_cgui_range=>ty_t_row.
    DATA temp284 LIKE LINE OF temp283.
    DATA temp91 TYPE xsdboolean.
    DATA temp285 TYPE string_table.
    DATA lt_selected TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp287 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp92 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the filter button lists the columns - pick the airline
    event( z2ui5_cl_cgui_alv=>cs_event-filter ).

    temp279 ?= mo_client->mo_called.

    lo_select = temp279.
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.

    CLEAR temp280.
    INSERT `/XX/MR_VIEW/0` INTO TABLE temp280.
    mo_client->mt_arg = temp280.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

    " its multiple selection - UA only

    temp282 ?= mo_client->mo_called.

    lo_range = temp282.

    CLEAR temp283.

    temp284-key = `1`.
    temp284-sign = `I`.
    temp284-option = `EQ`.
    temp284-low = `UA`.
    INSERT temp284 INTO TABLE temp283.
    lo_range->mt_row = temp283.
    range_popup_leave( z2ui5_cl_cgui_range=>cs_event-ok ).

    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mo_cgui_alv->get_filter( ) )
                                        exp = 1 ).

    temp91 = boolc( mo_client->mv_view CS `(1 of 3)` ).
    cl_abap_unit_assert=>assert_true( temp91 ).

    " the one row shown is the third of the table

    CLEAR temp285.
    INSERT `/XX/MR_CGUI_ALV_PAGE/0` INTO TABLE temp285.
    event( name = z2ui5_cl_cgui_alv=>cs_event-line_selection
           args = temp285 ).
    cl_abap_unit_assert=>assert_equals( act = mo_report->mv_lsel_row
                                        exp = 3 ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    " select all takes the rows that pass only
    event( z2ui5_cl_cgui_alv=>cs_event-select_all ).

    lt_selected = mo_cut->get_selected_rows( ).

    CLEAR temp287.
    INSERT 3 INTO TABLE temp287.
    cl_abap_unit_assert=>assert_equals( act = lt_selected
                                        exp = temp287 ).

    event( z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mo_cgui_alv->get_filter( ) ).

    temp92 = boolc( mo_client->mv_view CS `(3)` ).
    cl_abap_unit_assert=>assert_true( temp92 ).

  ENDMETHOD.

  METHOD window_shows_dialog.
    DATA temp289 TYPE string_table.
    DATA temp93 TYPE xsdboolean.
    DATA temp94 TYPE xsdboolean.
    DATA temp95 TYPE xsdboolean.
    DATA temp96 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_window = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the secondary list in a dialog box, the basic list below as text

    CLEAR temp289.
    INSERT `2` INTO TABLE temp289.
    INSERT `H1` INTO TABLE temp289.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp289 ).

    temp93 = boolc( mo_client->mv_popup CS `Detail H1` ).
    cl_abap_unit_assert=>assert_true( temp93 ).

    temp94 = boolc( mo_client->mv_popup CS `30rem` ).
    cl_abap_unit_assert=>assert_true( temp94 ).

    temp95 = boolc( mo_client->mv_view CS `row1` ).
    cl_abap_unit_assert=>assert_true( temp95 ).

    temp96 = boolc( mo_client->mv_view CS `Detail H1` ).
    cl_abap_unit_assert=>assert_false( temp96 ).

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
    DATA temp291 TYPE d.
    DATA lt_item TYPE z2ui5_cl_cgui_list=>ty_t_item.
    FIELD-SYMBOLS <temp292> LIKE LINE OF lt_item.
    DATA temp293 LIKE sy-tabix.
    FIELD-SYMBOLS <temp294> LIKE LINE OF lt_item.
    DATA temp295 LIKE sy-tabix.
    FIELD-SYMBOLS <temp296> LIKE LINE OF lt_item.
    DATA temp297 LIKE sy-tabix.

    init( ).
    mo_cut->format( color = z2ui5_cl_cgui_list=>cs_color-positive ).
    mo_cut->write( `a` ).
    mo_cut->write( val   = `b`
                   color = z2ui5_cl_cgui_list=>cs_color-negative ).

    temp291 = '20261002'.
    mo_cut->write( val       = temp291
                   date_format = z2ui5_cl_cgui_list=>cs_date_format-ddmmyy ).

    lt_item = mo_cut->mo_cgui_list->get_items( ).
    " the header line of TOP-OF-PAGE first
    DELETE lt_item WHERE header = abap_true.


    temp293 = sy-tabix.
    READ TABLE lt_item INDEX 1 ASSIGNING <temp292>.
    sy-tabix = temp293.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp292>-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-positive ).


    temp295 = sy-tabix.
    READ TABLE lt_item INDEX 2 ASSIGNING <temp294>.
    sy-tabix = temp295.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp294>-color
                                        exp = z2ui5_cl_cgui_list=>cs_color-negative ).
    " as the classic WRITE ... DDMMYY: day, month, year without separators


    temp297 = sy-tabix.
    READ TABLE lt_item INDEX 3 ASSIGNING <temp296>.
    sy-tabix = temp297.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp296>-text
                                        exp = `021026` ).

  ENDMETHOD.

  METHOD cursor_and_lisel.
    DATA lt_item TYPE z2ui5_cl_cgui_list=>ty_t_item.
    DATA ls_row LIKE LINE OF lt_item.
    FIELD-SYMBOLS <temp14> LIKE LINE OF lt_item.
    DATA temp15 LIKE sy-tabix.
    DATA temp298 TYPE string_table.
    DATA temp16 LIKE LINE OF temp298.
    DATA temp17 LIKE LINE OF temp298.

    init( ).
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    lt_item = mo_cut->mo_cgui_list->get_items( ).



    temp15 = sy-tabix.
    READ TABLE lt_item WITH KEY text = `row1` ASSIGNING <temp14>.
    sy-tabix = temp15.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_row = <temp14>.


    CLEAR temp298.

    temp16 = |{ ls_row-line }|.
    INSERT temp16 INTO TABLE temp298.
    INSERT `H1` INTO TABLE temp298.

    temp17 = |{ ls_row-id }|.
    INSERT temp17 INTO TABLE temp298.
    event( name = z2ui5_cl_cgui_list=>cs_event-line_selection
           args = temp298 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_cursor( )-value
                                        exp = `row1` ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->get_cursor( )-line
                                        exp = ls_row-line ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lisel( )
                                        exp = `row1` ).

  ENDMETHOD.

  METHOD selscreen_status_and_cursor.
    DATA temp300 TYPE string_table.
    DATA temp97 TYPE xsdboolean.
    DATA temp98 TYPE xsdboolean.
    DATA temp99 TYPE xsdboolean.
    DATA temp100 TYPE xsdboolean.

    init( ).

    CLEAR temp300.
    INSERT z2ui5_cl_cgui_report=>cs_ucomm-variant_save INTO TABLE temp300.
    INSERT z2ui5_cl_cgui_report=>cs_ucomm-execute INTO TABLE temp300.
    mo_cut->set_selscreen_status( temp300 ).
    mo_cut->set_cursor_field( `p_text` ).
    event( `NOOP` ).

    temp97 = boolc( mo_client->mv_view CS `Save as Variant` ).
    cl_abap_unit_assert=>assert_false( temp97 ).

    temp98 = boolc( mo_client->mv_view CS `Get Variant` ).
    cl_abap_unit_assert=>assert_true( temp98 ).

    temp99 = boolc( mo_client->mv_view CS z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_false( temp99 ).

    temp100 = boolc( concat_lines_of( mo_client->mt_action ) CS `cgui_f_p_text` ).
    cl_abap_unit_assert=>assert_true( temp100 ).

    " F8 is switched off as well
    mo_report->p_carrid = `LH`.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `SELECTION` ).

  ENDMETHOD.

  METHOD alv_search_and_details.

    FIELD-SYMBOLS <box> TYPE STANDARD TABLE.
    DATA temp302 TYPE string_table.
    DATA temp101 TYPE xsdboolean.
    DATA temp102 TYPE xsdboolean.
    DATA temp42 LIKE sy-subrc.
    DATA temp304 TYPE z2ui5_cl_cgui_alv=>ty_t_row.
    DATA temp103 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    " the search field: UA in one of the columns

    CLEAR temp302.
    INSERT `ua` INTO TABLE temp302.
    event( name = z2ui5_cl_cgui_alv=>cs_event-search
           args = temp302 ).

    temp101 = boolc( mo_client->mv_view CS `(1 of 3)` ).
    cl_abap_unit_assert=>assert_true( temp101 ).

    " details without a row selected: a warning; with one: the dialog box
    event( z2ui5_cl_cgui_alv=>cs_event-details ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).


    READ TABLE mo_cut->mt_cgui_log WITH KEY type = `W` TRANSPORTING NO FIELDS.
    temp42 = sy-subrc.
    temp102 = boolc( temp42 = 0 ).
    cl_abap_unit_assert=>assert_true( temp102 ).
    event( z2ui5_cl_cgui_alv=>cs_event-filter_clear ).
    ASSIGN mo_cut->mr_cgui_alv_box->* TO <box>.

    CLEAR temp304.
    INSERT 3 INTO TABLE temp304.
    mo_cut->mo_cgui_alv->set_selected_rows( EXPORTING rows = temp304
                                            CHANGING  tab  = <box> ).
    event( z2ui5_cl_cgui_alv=>cs_event-details ).

    temp103 = boolc( mo_client->mv_popup CS `UA` ).
    cl_abap_unit_assert=>assert_true( temp103 ).
    event( z2ui5_cl_cgui_alv=>cs_event-details_close ).
    cl_abap_unit_assert=>assert_initial( mo_client->mv_popup ).

  ENDMETHOD.

  METHOD select_popup_pick.

    DATA temp306 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp306.
    DATA temp307 TYPE string_table.
    DATA temp18 LIKE LINE OF temp307.
    temp306 ?= mo_client->mo_called.

    lo_select = temp306.
    mo_client->mv_event = z2ui5_cl_cgui_select=>cs_event-confirm.

    CLEAR temp307.

    temp18 = |/XX/MR_VIEW/{ index - 1 }|.
    INSERT temp18 INTO TABLE temp307.
    mo_client->mt_arg = temp307.
    lo_select->z2ui5_if_app~main( mo_client ).
    CLEAR: mo_client->mo_called, mo_client->mv_event, mo_client->mt_arg.
    mo_client->mo_prev = lo_select.
    mo_client->mv_navigated = abap_true.
    mo_cut->z2ui5_if_app~main( mo_client ).
    mo_client->mv_navigated = abap_false.

  ENDMETHOD.

  METHOD f4_on_high.

    DATA temp309 LIKE mo_report->s_code.
    DATA temp310 LIKE LINE OF temp309.
    DATA temp311 TYPE string_table.
    FIELD-SYMBOLS <temp313> LIKE LINE OF mo_report->s_code.
    DATA temp314 LIKE sy-tabix.
    FIELD-SYMBOLS <temp315> LIKE LINE OF mo_report->s_code.
    DATA temp316 LIKE sy-tabix.
    FIELD-SYMBOLS <temp317> LIKE LINE OF mo_report->s_code.
    DATA temp318 LIKE sy-tabix.
    CLEAR temp309.

    temp310-sign = `I`.
    temp310-option = `EQ`.
    temp310-low = `AA`.
    INSERT temp310 INTO TABLE temp309.
    mo_report->s_code = temp309.
    init( ).

    CLEAR temp311.
    INSERT `S_CODE` INTO TABLE temp311.
    INSERT `HIGH` INTO TABLE temp311.
    event( name = z2ui5_cl_cgui_selscreen=>cs_event-value_request
           args = temp311 ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    select_popup_pick( 1 ).

    " the first line is an interval up to the value picked
    cl_abap_unit_assert=>assert_equals( act = lines( mo_report->s_code )
                                        exp = 1 ).


    temp314 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp313>.
    sy-tabix = temp314.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp313>-option
                                        exp = `BT` ).


    temp316 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp315>.
    sy-tabix = temp316.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp315>-low
                                        exp = `AA` ).


    temp318 = sy-tabix.
    READ TABLE mo_report->s_code INDEX 1 ASSIGNING <temp317>.
    sy-tabix = temp318.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp317>-high
                                        exp = `ZZ` ).

  ENDMETHOD.

  METHOD f4_in_alv_cell.
    DATA temp319 TYPE string_table.
    FIELD-SYMBOLS <temp321> LIKE LINE OF mo_report->mt_row.
    DATA temp322 LIKE sy-tabix.
    FIELD-SYMBOLS <temp323> LIKE LINE OF mo_report->mt_row.
    DATA temp324 LIKE sy-tabix.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    mo_cut->mo_cgui_alv->set_edit( )->set_column_f4( `CARRID` ).

    " F4 in the airline of the second row - the second value picked

    CLEAR temp319.
    INSERT `/XX/MR_CGUI_ALV_BOX/1` INTO TABLE temp319.
    INSERT `CARRID` INTO TABLE temp319.
    event( name = z2ui5_cl_cgui_alv=>cs_event-f4
           args = temp319 ).
    cl_abap_unit_assert=>assert_bound( mo_client->mo_called ).
    select_popup_pick( 2 ).


    temp322 = sy-tabix.
    READ TABLE mo_report->mt_row INDEX 2 ASSIGNING <temp321>.
    sy-tabix = temp322.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp321>-carrid
                                        exp = `SQ` ).


    temp324 = sy-tabix.
    READ TABLE mo_report->mt_row INDEX 1 ASSIGNING <temp323>.
    sy-tabix = temp324.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp323>-carrid
                                        exp = `LH` ).

  ENDMETHOD.

  METHOD tree_expand_and_node.
    DATA temp104 TYPE xsdboolean.
    DATA temp325 TYPE string_table.
    FIELD-SYMBOLS <temp327> LIKE LINE OF mo_cut->mt_cgui_tree_view.
    DATA temp328 LIKE sy-tabix.
    FIELD-SYMBOLS <temp329> LIKE LINE OF mo_cut->mt_cgui_tree_view.
    DATA temp330 LIKE sy-tabix.
    DATA temp331 TYPE z2ui5_cl_cgui_tree=>ty_t_key.
    DATA temp333 TYPE string_table.
    DATA temp105 TYPE xsdboolean.

    init( ).
    mo_report->p_carrid = `LH`.
    mo_report->mv_tree = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_cgui_screen
                                        exp = `OUTPUT` ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 1 ).

    temp104 = boolc( mo_client->mv_view CS `EVENT:CGUI_TREE_TOGGLE` ).
    cl_abap_unit_assert=>assert_true( temp104 ).

    " expand the airline - its connection is shown

    CLEAR temp325.
    INSERT `1` INTO TABLE temp325.
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = temp325 ).
    cl_abap_unit_assert=>assert_equals( act = lines( mo_cut->mt_cgui_tree_view )
                                        exp = 2 ).


    temp328 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tree_view INDEX 2 ASSIGNING <temp327>.
    sy-tabix = temp328.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp327>-text
                                        exp = `0400` ).

    " a tick in the browser reaches the node with the next event
    mo_cut->mo_cgui_tree->set_checkboxes( ).


    temp330 = sy-tabix.
    READ TABLE mo_cut->mt_cgui_tree_view INDEX 2 ASSIGNING <temp329>.
    sy-tabix = temp330.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    <temp329>-checked = abap_true.
    event( z2ui5_cl_cgui_tree=>cs_event-expand_all ).

    CLEAR temp331.
    INSERT 2 INTO TABLE temp331.
    cl_abap_unit_assert=>assert_equals( act = mo_cut->mo_cgui_tree->get_checked( )
                                        exp = temp331 ).

    " a click on the connection - a secondary list, Back returns to the tree

    CLEAR temp333.
    INSERT `2` INTO TABLE temp333.
    event( name = z2ui5_cl_cgui_tree=>cs_event-node
           args = temp333 ).
    cl_abap_unit_assert=>assert_equals( act = mo_cut->lsind( )
                                        exp = 1 ).

    temp105 = boolc( mo_client->mv_view CS `Node LH-0400 2` ).
    cl_abap_unit_assert=>assert_true( temp105 ).
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
    DATA temp335 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_app LIKE temp335.
    DATA temp106 TYPE xsdboolean.
    DATA temp1 TYPE xsdboolean.
    DATA temp107 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
    DATA temp108 TYPE xsdboolean.
    DATA temp3 TYPE xsdboolean.
    temp335 ?= roundtrip( app = mo_cut step = step ).

    lo_app = temp335.

    cl_abap_unit_assert=>assert_equals( act = lo_app->mv_cgui_screen
                                        exp = mo_cut->mv_cgui_screen
                                        msg = |{ step }: screen| ).

    temp106 = boolc( lo_app->mo_cgui_list IS BOUND ).

    temp1 = boolc( mo_cut->mo_cgui_list IS BOUND ).
    cl_abap_unit_assert=>assert_equals( act = temp106
                                        exp = temp1
                                        msg = |{ step }: the list after the roundtrip| ).

    temp107 = boolc( lo_app->mo_cgui_alv IS BOUND ).

    temp2 = boolc( mo_cut->mo_cgui_alv IS BOUND ).
    cl_abap_unit_assert=>assert_equals( act = temp107
                                        exp = temp2
                                        msg = |{ step }: the ALV after the roundtrip| ).

    temp108 = boolc( lo_app->mo_cgui_tree IS BOUND ).

    temp3 = boolc( mo_cut->mo_cgui_tree IS BOUND ).
    cl_abap_unit_assert=>assert_equals( act = temp108
                                        exp = temp3
                                        msg = |{ step }: the tree after the roundtrip| ).
    IF mo_cut->mo_cgui_tree IS BOUND AND lo_app->mo_cgui_tree IS BOUND.
      cl_abap_unit_assert=>assert_equals( act = lines( lo_app->mo_cgui_tree->get_nodes( ) )
                                          exp = lines( mo_cut->mo_cgui_tree->get_nodes( ) )
                                          msg = |{ step }: the nodes of the tree| ).
    ENDIF.

  ENDMETHOD.

  METHOD draft_serializable.
    DATA temp336 TYPE string_table.

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

    CLEAR temp336.
    INSERT `1` INTO TABLE temp336.
    event( name = z2ui5_cl_cgui_tree=>cs_event-toggle
           args = temp336 ).
    serialize( `tree` ).

  ENDMETHOD.

  METHOD roundtrip.

    " the roundtrip of abap2UI5 between two requests: the app in its
    " container to the draft and back - what is not serializable is dropped
    " there without a word
    DATA lo_cont TYPE REF TO z2ui5_cl_ui5_app_cont.
        DATA lo_parsed TYPE REF TO z2ui5_cl_ui5_app_cont.
        DATA temp338 TYPE REF TO z2ui5_cl_ui5_srv_model.
        DATA lx_error TYPE REF TO cx_root.
    DATA temp339 TYPE REF TO z2ui5_if_app.
    CREATE OBJECT lo_cont TYPE z2ui5_cl_ui5_app_cont.
    lo_cont->mo_app = app.
    lo_cont->ms_draft-id = `CGUI_UNIT_TEST`.
    TRY.

        lo_parsed = z2ui5_cl_ui5_app_cont=>all_xml_parse( lo_cont->all_xml_stringify( ) ).
        " as db_load( ): the data references back from their S-RTTI payloads

        CREATE OBJECT temp338 TYPE z2ui5_cl_ui5_srv_model EXPORTING attri = lo_parsed->mt_attri app = lo_parsed->mo_app.
        temp338->main_attri_db_load( ).

      CATCH cx_root INTO lx_error.
        cl_abap_unit_assert=>fail( |{ step }: the app cannot be saved - { lx_error->get_text( ) }| ).
    ENDTRY.

    temp339 ?= lo_parsed->mo_app.
    result = temp339.

  ENDMETHOD.

  METHOD draft_references.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA temp340 TYPE REF TO ltcl_variant_store.
    DATA temp341 TYPE REF TO z2ui5_cl_cgui_report.
    DATA lo_app LIKE temp341.
    DATA lr_rows TYPE REF TO data.
    DATA temp342 TYPE ltcl_report=>ty_t_row.
    DATA temp343 LIKE LINE OF temp342.
    DATA temp344 TYPE REF TO z2ui5_cl_cgui_report.
    DATA temp345 TYPE ltcl_report=>ty_t_pick.
    DATA temp346 LIKE LINE OF temp345.
    DATA temp19 TYPE REF TO z2ui5_cl_cgui_select.
    DATA lo_select LIKE temp19.
    DATA ls_result TYPE z2ui5_cl_cgui_select=>ty_s_result.
    DATA temp347 TYPE REF TO z2ui5_cl_cgui_range.
    DATA lo_range LIKE temp347.
    DATA temp348 TYPE z2ui5_cl_cgui_alv=>ty_t_layout.
    DATA temp349 TYPE z2ui5_cl_cgui_popup=>ty_t_field.
    DATA temp350 LIKE LINE OF temp349.

    " the rows of the ALV - an anonymous copy, its type rebuilt
    init( ).
    " a store of the customer's - it travels in the draft with the report

    CREATE OBJECT temp340 TYPE ltcl_variant_store.
    mo_cut->set_variant_store( temp340 ).

    mo_report->p_carrid = `LH`.
    mo_report->mv_alv = abap_true.
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    " a public attribute: the ALV keeps its name

    temp341 ?= roundtrip( app = mo_cut step = `ALV of an attribute` ).

    lo_app = temp341.

    lr_rows = lo_app->alv_source( ).
    cl_abap_unit_assert=>assert_bound( act = lr_rows
                                       msg = `the rows of the ALV after the roundtrip` ).
    ASSIGN lr_rows->* TO <tab>.
    cl_abap_unit_assert=>assert_equals( act = lines( <tab> )
                                        exp = lines( mo_report->mt_row )
                                        msg = `the rows of the ALV after the roundtrip` ).

    " any other table: the ALV keeps a copy

    CLEAR temp342.

    temp343-carrid = `LH`.
    temp343-seats = 1.
    INSERT temp343 INTO TABLE temp342.
    temp343-carrid = `AA`.
    temp343-seats = 2.
    INSERT temp343 INTO TABLE temp342.
    temp343-carrid = `UA`.
    temp343-seats = 3.
    INSERT temp343 INTO TABLE temp342.
    mo_cut->alv( temp342 ).

    temp344 ?= roundtrip( app = mo_cut step = `ALV of a copy` ).
    lo_app = temp344.
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

    CLEAR temp345.

    temp346-value = `A`.
    INSERT temp346 INTO TABLE temp345.
    temp346-value = `B`.
    INSERT temp346 INTO TABLE temp345.

    temp19 ?= roundtrip( app = z2ui5_cl_cgui_select=>factory( tab = temp345 ) step = `select popup` ).

    lo_select = temp19.

    ls_result = lo_select->result( ).
    cl_abap_unit_assert=>assert_bound( act = ls_result-row
                                       msg = `select popup: the result row after the roundtrip` ).
    cl_abap_unit_assert=>assert_bound( act = ls_result-table
                                       msg = `select popup: the result table after the roundtrip` ).

    " the other dialogs - saved without an error, their state kept

    temp347 ?= roundtrip( app = z2ui5_cl_cgui_range=>factory( range = mo_report->s_code ) step = `range popup` ).

    lo_range = temp347.
    cl_abap_unit_assert=>assert_bound( lo_range ).

    CLEAR temp348.
    roundtrip( app  = z2ui5_cl_cgui_layout=>factory( layout = temp348 )
               step = `layout popup` ).
    roundtrip( app  = z2ui5_cl_cgui_popup=>confirm( question = `Sure?` )
               step = `confirm popup` ).

    CLEAR temp349.

    temp350-name = `A`.
    temp350-text = `A`.
    temp350-value = `1`.
    INSERT temp350 INTO TABLE temp349.
    roundtrip( app  = z2ui5_cl_cgui_popup=>get_values( fields = temp349 )
               step = `values popup` ).

  ENDMETHOD.

ENDCLASS.
