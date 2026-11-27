CLASS z2ui5_cl_cgui_r2c_54 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_item,
        id     TYPE i,
        name   TYPE c LENGTH 20,
        amount TYPE p LENGTH 8 DECIMALS 2,
        curr   TYPE c LENGTH 5,
        due    TYPE d,
      END OF ty_item,
      ty_t_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_value,
        id   TYPE c LENGTH 3,
        text TYPE c LENGTH 20,
      END OF ty_value.

    " global data of the report
    DATA gt_item TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    DATA wa_gt_item LIKE LINE OF gt_item.
    DATA:
      gt_value TYPE STANDARD TABLE OF ty_value WITH DEFAULT KEY,
      gt_ret   TYPE STANDARD TABLE OF ty_value WITH DEFAULT KEY,
      gv_key   TYPE c LENGTH 4,
      gv_type  TYPE c LENGTH 1 VALUE 'S'.

    " selection screen
    DATA p_id    TYPE c LENGTH 3.
    DATA p_cb    TYPE abap_bool.
    DATA p_list  TYPE abap_bool.
    DATA p_total TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.
    METHODS at_value_request REDEFINITION.
    METHODS at_roundtrip_start REDEFINITION.

  PRIVATE SECTION.
    METHODS header.

    METHODS detail.

    METHODS mark_due
      CHANGING
        ut_item TYPE ty_t_item.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_54 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    p_cb = abap_true.
    p_total = abap_true.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val        = p_id
                       value_help = abap_true
        )->checkbox( p_cb
        )->radiobutton( val   = p_list
                        group = `OUT`
        )->radiobutton( val   = p_total
                        group = `OUT` ).

  ENDMETHOD.

  METHOD start_of_selection.

    gt_item = VALUE ty_t_item( ( id = 1 name = 'Rent'  amount = '1200.50' curr = 'EUR' due = '20260105' )
                                 ( id = 2 name = 'Train' amount = '89.00'   curr = 'JPY' due = '20260212' ) ).
    mark_due( CHANGING
                ut_item = gt_item ).

    list( )->format( color = z2ui5_cl_cgui_list=>cs_color-key ).
    header( ).
    list( )->format( reset = abap_true ).

    LOOP AT gt_item INTO wa_gt_item.
      list( )->new_line(
          )->write( wa_gt_item-name
          )->write( val      = wa_gt_item-amount
                    currency = wa_gt_item-curr
                    no_zero  = abap_true
                    justify  = z2ui5_cl_cgui_list=>cs_justify-right
          )->write( val         = wa_gt_item-due
                    date_format = z2ui5_cl_cgui_list=>cs_date_format-dd_mm_yyyy
                    quickinfo   = 'Due date' ).
      list( )->hide( |{ wa_gt_item-id }\t{ wa_gt_item-name }| ).
    ENDLOOP.

    IF p_total = abap_true.
      NEW lcl_lines( )->write_totals( ).
    ENDIF.

    message( text = 'List written'
             type = gv_type ).
    IF gv_type CA 'EA'.
      RETURN.
    ENDIF.

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the fields the clicked line was written with
    SPLIT hide AT |\t| INTO TABLE DATA(lt_hide).
    wa_gt_item-id = VALUE #( lt_hide[ 1 ] OPTIONAL ).
    wa_gt_item-name = VALUE #( lt_hide[ 2 ] OPTIONAL ).

    detail( ).

  ENDMETHOD.

  METHOD at_value_request.

    CASE field.
      WHEN `P_ID`.
        gt_value = VALUE #( ( id = 'A01' text = 'First' ) ( id = 'B02' text = 'Second' ) ).
        CLEAR gt_ret.
        value_help_popup( tab = gt_value
                          col = `ID` ).
      WHEN OTHERS.
        super->at_value_request( field ).
    ENDCASE.

  ENDMETHOD.

  METHOD at_roundtrip_start.

    lcl_r2c=>app = me.

  ENDMETHOD.

  METHOD header.

    list( )->new_line(
        )->write( 'Name'
        )->write( 'Amount'
        )->write( 'Due' ).
    list( )->uline( ).

  ENDMETHOD.

  METHOD detail.

    DATA lv_lisel TYPE c LENGTH 1023.

    lv_lisel = lisel( ).
    gv_key = lv_lisel(4).
    list( )->new_line(
        )->write( 'Item'
        )->write( wa_gt_item-id
        )->write( wa_gt_item-name
        )->write( 'line'
        )->write( get_cursor( )-line
        )->write( 'starts with'
        )->write( gv_key ).

  ENDMETHOD.

  METHOD mark_due.

    FIELD-SYMBOLS <ls_item> TYPE ty_item.

    LOOP AT ut_item ASSIGNING <ls_item>.
      IF <ls_item>-due IS INITIAL.
        <ls_item>-due = sy-datum.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
