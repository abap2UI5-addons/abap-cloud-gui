" the client as the popup sees it - events in, popup and navigation out
CLASS ltcl_client DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client PARTIALLY IMPLEMENTED.

    DATA mv_init  TYPE abap_bool.
    DATA mv_event TYPE string.
    DATA mt_arg   TYPE string_table.
    DATA mv_popup TYPE string.
    DATA mv_left  TYPE abap_bool.
    DATA mv_leave_event TYPE string.

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

    result = COND #( WHEN path = abap_true THEN `/MR_VIEW` ELSE `{/MR_VIEW}` ).

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
    mv_leave_event = event.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_row,
        carrid TYPE land1,
        text   TYPE string,
        fldate TYPE d,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_marked,
        value   TYPE c LENGTH 4,
        zzselkz TYPE abap_bool,
      END OF ty_s_marked.
    TYPES ty_t_marked TYPE STANDARD TABLE OF ty_s_marked WITH EMPTY KEY.

    DATA mo_client TYPE REF TO ltcl_client.
    DATA mt_row    TYPE ty_t_row.

    METHODS setup.

    METHODS run
      IMPORTING
        popup TYPE REF TO z2ui5_cl_cgui_select
        event TYPE string       OPTIONAL
        args  TYPE string_table OPTIONAL
        init  TYPE abap_bool    DEFAULT abap_false.

    METHODS columns_and_labels FOR TESTING.
    METHODS single_pick_by_path FOR TESTING.
    METHODS search_keeps_marks FOR TESTING.
    METHODS preselected_rows FOR TESTING.
    METHODS table_of_strings FOR TESTING.
    METHODS cancel_leaves FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.

    mo_client = NEW #( ).
    mt_row = VALUE #( ( carrid = `LH` text = `Lufthansa` fldate = `20261001` )
                      ( carrid = `AA` text = `American`  fldate = `20261002` )
                      ( carrid = `UA` text = `United`    fldate = `20261003` ) ).

  ENDMETHOD.

  METHOD run.

    mo_client->mv_init  = init.
    mo_client->mv_event = event.
    mo_client->mt_arg   = args.
    popup->z2ui5_if_app~main( mo_client ).

  ENDMETHOD.

  METHOD columns_and_labels.

    DATA(lo_popup) = z2ui5_cl_cgui_select=>factory( tab   = mt_row
                                                    title = `Airline` ).
    run( popup = lo_popup
         init  = abap_true ).

    DATA(lt_column) = lo_popup->get_columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_column )
                                        exp = 3 ).
    " the DDIC label of the data element - on a system the text of LAND1, in
    " the transpiled runtime, where it has none, the name; the name for a
    " local type
    cl_abap_unit_assert=>assert_not_initial( lt_column[ 1 ]-label ).
    cl_abap_unit_assert=>assert_equals( act = lt_column[ 2 ]-label
                                        exp = `TEXT` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*<TableSelectDialog*title="Airline"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_client->mv_popup
                                         exp = `*selected="{ZZSELKZ}"*` ).

  ENDMETHOD.

  METHOD single_pick_by_path.

    FIELD-SYMBOLS <row>  TYPE ty_s_row.
    FIELD-SYMBOLS <rows> TYPE ty_t_row.

    DATA(lo_popup) = z2ui5_cl_cgui_select=>factory( mt_row ).
    run( popup = lo_popup
         init  = abap_true ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm
         args  = VALUE #( ( `/MR_VIEW/1` ) ) ).

    DATA(ls_result) = lo_popup->result( ).
    cl_abap_unit_assert=>assert_true( ls_result-confirmed ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    ASSIGN ls_result-row->* TO <row>.
    cl_abap_unit_assert=>assert_equals( act = <row>-carrid
                                        exp = `AA` ).
    ASSIGN ls_result-table->* TO <rows>.
    cl_abap_unit_assert=>assert_equals( act = lines( <rows> )
                                        exp = 1 ).

  ENDMETHOD.

  METHOD search_keeps_marks.

    FIELD-SYMBOLS <rows> TYPE ty_t_row.
    FIELD-SYMBOLS <view> TYPE STANDARD TABLE.

    DATA(lo_popup) = z2ui5_cl_cgui_select=>factory( tab         = mt_row
                                                    multiselect = abap_true
                                                    event       = `PICKED` ).
    run( popup = lo_popup
         init  = abap_true ).
    lo_popup->select_row( 1 ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-search
         args  = VALUE #( ( `united` ) ) ).
    ASSIGN lo_popup->mr_view->* TO <view>.
    cl_abap_unit_assert=>assert_equals( act = lines( <view> )
                                        exp = 1 ).
    lo_popup->select_row( 3 ).

    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-search
         args  = VALUE #( ( `` ) ) ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm ).

    DATA(ls_result) = lo_popup->result( ).
    ASSIGN ls_result-table->* TO <rows>.
    cl_abap_unit_assert=>assert_equals( act = <rows>
                                        exp = VALUE ty_t_row( ( mt_row[ 1 ] ) ( mt_row[ 3 ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_leave_event
                                        exp = `PICKED` ).

  ENDMETHOD.

  METHOD preselected_rows.

    FIELD-SYMBOLS <rows> TYPE ty_t_marked.

    DATA(lt_marked) = VALUE ty_t_marked( ( value = `A` )
                                         ( value = `B` zzselkz = abap_true ) ).
    DATA(lo_popup) = z2ui5_cl_cgui_select=>factory( tab         = lt_marked
                                                    multiselect = abap_true ).
    run( popup = lo_popup
         init  = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_popup->get_columns( ) )
                                        exp = 1 ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm ).

    DATA(ls_result) = lo_popup->result( ).
    ASSIGN ls_result-table->* TO <rows>.
    cl_abap_unit_assert=>assert_equals( act = lines( <rows> )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = <rows>[ 1 ]-value
                                        exp = `B` ).

  ENDMETHOD.

  METHOD table_of_strings.

    FIELD-SYMBOLS <row> TYPE string.

    DATA(lo_popup) = z2ui5_cl_cgui_select=>factory( VALUE string_table( ( `one` ) ( `two` ) ) ).
    run( popup = lo_popup
         init  = abap_true ).
    DATA(lt_column) = lo_popup->get_columns( ).
    cl_abap_unit_assert=>assert_equals( act = lt_column[ 1 ]-name
                                        exp = `TAB_LINE` ).
    lo_popup->select_row( 2 ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-confirm ).

    DATA(ls_result) = lo_popup->result( ).
    ASSIGN ls_result-row->* TO <row>.
    cl_abap_unit_assert=>assert_equals( act = <row>
                                        exp = `two` ).

  ENDMETHOD.

  METHOD cancel_leaves.

    DATA(lo_popup) = z2ui5_cl_cgui_select=>factory( tab          = mt_row
                                                    event_cancel = `CANCELLED` ).
    run( popup = lo_popup
         init  = abap_true ).
    run( popup = lo_popup
         event = z2ui5_cl_cgui_select=>cs_event-cancel ).

    cl_abap_unit_assert=>assert_false( lo_popup->result( )-confirmed ).
    cl_abap_unit_assert=>assert_true( mo_client->mv_left ).
    cl_abap_unit_assert=>assert_equals( act = mo_client->mv_leave_event
                                        exp = `CANCELLED` ).

  ENDMETHOD.

ENDCLASS.
