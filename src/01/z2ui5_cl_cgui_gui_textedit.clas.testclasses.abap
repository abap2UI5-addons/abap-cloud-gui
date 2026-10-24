"! the controls of a report - the lines z2ui5_cl_cgui_report keeps
CLASS ltcl_gui DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_cgui_gui.
    DATA mt_control TYPE z2ui5_if_cgui_gui=>ty_t_control.
    DATA mt_object TYPE STANDARD TABLE OF REF TO object WITH EMPTY KEY.
    DATA mt_handler TYPE z2ui5_if_cgui_gui=>ty_t_handler.

ENDCLASS.


CLASS ltcl_gui IMPLEMENTATION.

  METHOD z2ui5_if_cgui_gui~control_add.

    DATA(ls_control) = control.
    ls_control-id = lines( mt_control ) + 1.
    INSERT ls_control INTO TABLE mt_control.
    INSERT object INTO TABLE mt_object.
    result = ls_control-id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_get.

    READ TABLE mt_control INTO result INDEX id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~control_set.

    MODIFY mt_control FROM control INDEX control-id.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~handlers_get.

    result = mt_handler.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~handlers_set.

    mt_handler = handlers.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_gui~custom_render ##NEEDED.
  ENDMETHOD.

ENDCLASS.


"! the handlers a report sets for the events of its controls
CLASS ltcl_handler DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    DATA mv_log TYPE string.

    METHODS on_close FOR EVENT close OF z2ui5_cl_cgui_gui_container
      IMPORTING sender.
    METHODS on_function FOR EVENT function_selected OF z2ui5_cl_cgui_gui_toolbar
      IMPORTING fcode.
    METHODS on_sapevent FOR EVENT sapevent OF z2ui5_cl_cgui_gui_html_viewer
      IMPORTING action query_table.

ENDCLASS.


CLASS ltcl_handler IMPLEMENTATION.

  METHOD on_close.

    mv_log = |{ mv_log }CLOSE { sender->get_id( ) };|.
    sender->free( ).

  ENDMETHOD.

  METHOD on_function.

    mv_log = |{ mv_log }FUNCTION { fcode };|.

  ENDMETHOD.

  METHOD on_sapevent.

    mv_log = |{ mv_log }SAPEVENT { action }|.
    LOOP AT query_table INTO DATA(ls_query).
      mv_log = |{ mv_log } { ls_query-name }={ ls_query-value }|.
    ENDLOOP.
    mv_log = |{ mv_log };|.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    TYPES ty_line TYPE c LENGTH 72.
    TYPES ty_t_line TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    DATA mo_gui TYPE REF TO ltcl_gui.
    DATA mo_cont TYPE REF TO z2ui5_cl_cgui_gui_container.

    METHODS setup.
    METHODS teardown.
    METHODS stream_and_table FOR TESTING.
    METHODS modified_and_modes FOR TESTING.
    METHODS splitter_cells FOR TESTING.
    METHODS html_document FOR TESTING.
    METHODS events FOR TESTING.
    METHODS toolbar_buttons FOR TESTING.
    METHODS sapevent_links FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_gui = NEW #( ).
    z2ui5_cl_cgui_gui=>set_report( mo_gui ).
    mo_cont = NEW #( container_name = 'cc' ).

  ENDMETHOD.

  METHOD teardown.

    z2ui5_cl_cgui_gui=>set_report( VALUE #( ) ).

  ENDMETHOD.

  METHOD stream_and_table.

    DATA lt_out TYPE ty_t_line.
    DATA lv_text TYPE string.

    DATA(lo_edit) = NEW z2ui5_cl_cgui_gui_textedit( parent = mo_cont ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 1 ]-name
                                        exp = `CC` ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 2 ]-parent
                                        exp = 1 ).

    lo_edit->set_text_as_r3table( VALUE ty_t_line( ( `first line` ) ( `  indented` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_gui->mt_control[ 2 ]-text
                                        exp = |first line\n  indented| ).

    " what the user typed is the bound line of the report
    mo_gui->mt_control[ 2 ]-text = |one\r\ntwo\nthree|.
    lo_edit->get_text_as_r3table( IMPORTING table = lt_out ).
    cl_abap_unit_assert=>assert_equals( act = lt_out
                                        exp = VALUE ty_t_line( ( `one` ) ( `two` ) ( `three` ) ) ).
    lo_edit->get_textstream( IMPORTING text = lv_text ).
    cl_abap_unit_assert=>assert_equals( act = lv_text
                                        exp = |one\r\ntwo\nthree| ).

    lo_edit->set_textstream( `plain` ).
    lo_edit->get_text_as_stream( IMPORTING text = lt_out ).
    cl_abap_unit_assert=>assert_equals( act = lt_out
                                        exp = VALUE ty_t_line( ( `plain` ) ) ).
    lo_edit->delete_text( ).
    lo_edit->get_text_as_r3table( IMPORTING table = lt_out ).
    cl_abap_unit_assert=>assert_initial( lt_out ).

  ENDMETHOD.

  METHOD modified_and_modes.

    DATA lv_status TYPE i.
    DATA lv_text TYPE string.

    DATA(lo_edit) = NEW z2ui5_cl_cgui_gui_textedit( parent = mo_cont ).
    lo_edit->set_textstream( `set` ).
    lo_edit->get_textmodified_status( IMPORTING status = lv_status ).
    cl_abap_unit_assert=>assert_equals( act = lv_status
                                        exp = 0 ).

    mo_gui->mt_control[ 2 ]-text = `typed`.
    lo_edit->get_textmodified_status( IMPORTING status = lv_status ).
    cl_abap_unit_assert=>assert_equals( act = lv_status
                                        exp = 1 ).
    lo_edit->set_textmodified_status( 0 ).
    lo_edit->get_textstream( EXPORTING only_when_modified = z2ui5_cl_cgui_gui=>true
                             IMPORTING text               = lv_text ).
    cl_abap_unit_assert=>assert_initial( lv_text ).

    " the classic modes: 1 / 0, as the constants and as numbers
    lo_edit->set_readonly_mode( 1 ).
    lo_edit->set_toolbar_mode( z2ui5_cl_cgui_gui_textedit=>false ).
    lo_edit->set_statusbar_mode( 0 ).
    lo_edit->set_font_fixed( ).
    DATA(ls_control) = mo_gui->mt_control[ 2 ].
    cl_abap_unit_assert=>assert_true( ls_control-readonly ).
    cl_abap_unit_assert=>assert_false( ls_control-toolbar ).
    cl_abap_unit_assert=>assert_false( ls_control-statusbar ).
    cl_abap_unit_assert=>assert_true( ls_control-fixed ).

    " cl_gui_control: visible as a flag or a number, free
    lo_edit->set_visible( abap_false ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ 2 ]-hidden ).
    lo_edit->set_visible( 1 ).
    cl_abap_unit_assert=>assert_false( mo_gui->mt_control[ 2 ]-hidden ).
    lo_edit->free( ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ 2 ]-freed ).

  ENDMETHOD.

  METHOD splitter_cells.

    DATA(lo_split) = NEW z2ui5_cl_cgui_gui_container( parent  = mo_cont
                                                      rows    = 2
                                                      columns = 1 ).
    DATA(lo_top) = lo_split->get_container( row    = 1
                                            column = 1 ).
    DATA(lo_bottom) = lo_split->get_container( row    = 2
                                               column = 1 ).
    cl_abap_unit_assert=>assert_true( xsdbool( lo_split->get_container( row = 1 column = 1 ) = lo_top ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lo_bottom = lo_top ) ).
    DATA(ls_bottom) = mo_gui->mt_control[ lo_bottom->get_id( ) ].
    cl_abap_unit_assert=>assert_equals( act = ls_bottom-parent
                                        exp = lo_split->get_id( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_bottom-row
                                        exp = 2 ).

    " an easy splitter: its two cells as attributes
    DATA(lo_easy) = NEW z2ui5_cl_cgui_gui_easy_split( parent      = mo_cont
                                                         orientation = z2ui5_cl_cgui_gui_container=>orientation_horizontal ).
    cl_abap_unit_assert=>assert_bound( lo_easy->top_left_container ).
    DATA(ls_right) = mo_gui->mt_control[ lo_easy->bottom_right_container->get_id( ) ].
    cl_abap_unit_assert=>assert_equals( act = ls_right-column
                                        exp = 2 ).

  ENDMETHOD.

  METHOD events.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_dialog) = NEW z2ui5_cl_cgui_gui_container( caption = 'Details'
                                                       width   = 400
                                                       height  = 300 ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ lo_dialog->get_id( ) ]-dialog ).
    lo_dialog->set_handler( handler = lo_handler
                            method  = 'ON_CLOSE'
                            event   = 'CLOSE' ).
    " the browser's event, passed on by the report: the handler with sender
    lo_dialog->dispatch( `CLOSE` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |CLOSE { lo_dialog->get_id( ) };| ).
    cl_abap_unit_assert=>assert_true( mo_gui->mt_control[ lo_dialog->get_id( ) ]-freed ).

    DATA(lo_html) = NEW z2ui5_cl_cgui_gui_html_viewer( parent = mo_cont ).
    lo_html->set_handler( handler = lo_handler
                          method  = 'on_sapevent'
                          event   = 'sapevent' ).
    lo_html->dispatch( event = `SAPEVENT`
                       value = `SHOW?carrid=LH&connid=0400` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = |CLOSE { lo_dialog->get_id( ) };SAPEVENT SHOW CARRID=LH CONNID=0400;| ).

    " ACTIVATION space: no handler any more
    CLEAR lo_handler->mv_log.
    lo_html->set_handler( handler    = lo_handler
                          method     = 'ON_SAPEVENT'
                          event      = 'SAPEVENT'
                          activation = abap_false ).
    lo_html->dispatch( event = `SAPEVENT`
                       value = `SHOW` ).
    cl_abap_unit_assert=>assert_initial( lo_handler->mv_log ).

  ENDMETHOD.

  METHOD toolbar_buttons.

    TYPES:
      BEGIN OF ty_s_button,
        function  TYPE c LENGTH 70,
        icon      TYPE c LENGTH 40,
        butn_type TYPE c LENGTH 1,
        text      TYPE c LENGTH 40,
        quickinfo TYPE c LENGTH 40,
        disabled  TYPE c LENGTH 1,
      END OF ty_s_button.
    DATA lt_group TYPE STANDARD TABLE OF ty_s_button WITH EMPTY KEY.

    DATA(lo_handler) = NEW ltcl_handler( ).
    DATA(lo_bar) = NEW z2ui5_cl_cgui_gui_toolbar( parent = mo_cont ).
    lo_bar->add_button( fcode     = 'refresh'
                        icon      = 'sap-icon://refresh'
                        butn_type = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_button
                        quickinfo = 'Read again' ).
    lt_group = VALUE #( ( butn_type = '3' )
                        ( function = 'SAVE' text = 'Save' disabled = 'X' ) ).
    lo_bar->add_button_group( lt_group ).
    DATA(lt_button) = mo_gui->mt_control[ lo_bar->get_id( ) ]-buttons.
    cl_abap_unit_assert=>assert_equals( act = lines( lt_button )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_button[ 1 ]-fcode
                                        exp = `REFRESH` ).
    cl_abap_unit_assert=>assert_equals( act = lt_button[ 2 ]-type
                                        exp = z2ui5_cl_cgui_gui_toolbar=>cntb_btype_sep ).
    cl_abap_unit_assert=>assert_true( lt_button[ 3 ]-disabled ).

    lo_bar->set_button_state( fcode   = 'SAVE'
                              enabled = abap_true ).
    cl_abap_unit_assert=>assert_false( mo_gui->mt_control[ lo_bar->get_id( ) ]-buttons[ 3 ]-disabled ).

    lo_bar->set_handler( handler = lo_handler
                         method  = 'ON_FUNCTION'
                         event   = 'FUNCTION_SELECTED' ).
    lo_bar->dispatch( event = `FUNCTION_SELECTED`
                      value = `REFRESH` ).
    cl_abap_unit_assert=>assert_equals( act = lo_handler->mv_log
                                        exp = `FUNCTION REFRESH;` ).

    lo_bar->delete_button( 'REFRESH' ).
    lo_bar->delete_all_buttons( ).
    cl_abap_unit_assert=>assert_initial( mo_gui->mt_control[ lo_bar->get_id( ) ]-buttons ).

  ENDMETHOD.

  METHOD html_document.

    TYPES ty_html TYPE c LENGTH 10.
    DATA lt_html TYPE STANDARD TABLE OF ty_html WITH EMPTY KEY.
    DATA lv_url TYPE c LENGTH 250.

    DATA(lo_html) = NEW z2ui5_cl_cgui_gui_html_viewer( parent = mo_cont ).
    " a line filled to its end goes on in the next one, a shorter one ends
    lt_html = VALUE #( ( `<p>Hello w` ) ( `orld</p>` ) ( `<p>Bye</p>` ) ).
    lo_html->load_data( IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html ).
    cl_abap_unit_assert=>assert_not_initial( lv_url ).
    lo_html->show_url( lv_url ).
    DATA(ls_control) = mo_gui->mt_control[ 2 ].
    cl_abap_unit_assert=>assert_equals( act = ls_control-html
                                        exp = |<p>Hello world</p>\n<p>Bye</p>| ).
    cl_abap_unit_assert=>assert_initial( ls_control-url ).

    " an address of the web: a link
    lo_html->show_url( 'https://www.sap.com' ).
    ls_control = mo_gui->mt_control[ 2 ].
    cl_abap_unit_assert=>assert_equals( act = ls_control-url
                                        exp = `https://www.sap.com` ).
    cl_abap_unit_assert=>assert_initial( ls_control-html ).

    lo_html->show_data( ).
    cl_abap_unit_assert=>assert_not_initial( mo_gui->mt_control[ 2 ]-html ).

  ENDMETHOD.

  METHOD sapevent_links.

    DATA(lt_link) = z2ui5_cl_cgui_gui_html_viewer=>sapevent_links(
      `<p>x</p><a href="SAPEVENT:SHOW?CONNID=0400">Flight 0400</a> <A HREF='sapevent:back'> Back </A><a href="sapevent:open` ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_link ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 1 ]-action exp = `SHOW?CONNID=0400` ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 1 ]-text exp = `Flight 0400` ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 2 ]-action exp = `back` ).
    cl_abap_unit_assert=>assert_equals( act = lt_link[ 2 ]-text exp = `Back` ).

  ENDMETHOD.

ENDCLASS.
