CLASS z2ui5_cl_cgui_sample_03 DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_row,
        id       TYPE i,
        product  TYPE string,
        category TYPE string,
        created  TYPE d,
        price    TYPE p LENGTH 8 DECIMALS 2,
        currency TYPE string,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    DATA mt_row TYPE ty_t_row.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA mo_alv TYPE REF TO z2ui5_cl_cgui_alv.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_03 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    client->view_display( mo_alv->stringify( client = client
                                             tab    = mt_row ) ).

  ENDMETHOD.

  METHOD on_event.
      DATA lv_row TYPE i.
      DATA ls_row TYPE z2ui5_cl_cgui_sample_03=>ty_s_row.

    IF client->get_event( ) = z2ui5_cl_cgui_alv=>cs_event-line_selection.

      lv_row = z2ui5_cl_cgui_alv=>get_row_by_event( client ).

      READ TABLE mt_row INTO ls_row INDEX lv_row.
      IF sy-subrc = 0.
        client->message_toast_display( |{ ls_row-product } selected| ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD model_init.

    DATA temp1 TYPE z2ui5_cl_cgui_sample_03=>ty_t_row.
    DATA temp2 LIKE LINE OF temp1.
    CLEAR temp1.

    temp2-id = 1.
    temp2-product = `Notebook`.
    temp2-category = `Hardware`.
    temp2-created = `20260105`.
    temp2-price = `956.00`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 2.
    temp2-product = `Monitor`.
    temp2-category = `Hardware`.
    temp2-created = `20260112`.
    temp2-price = `289.90`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 3.
    temp2-product = `Keyboard`.
    temp2-category = `Hardware`.
    temp2-created = `20260203`.
    temp2-price = `49.99`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 4.
    temp2-product = `Office`.
    temp2-category = `Software`.
    temp2-created = `20260217`.
    temp2-price = `129.00`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 5.
    temp2-product = `IDE`.
    temp2-category = `Software`.
    temp2-created = `20260301`.
    temp2-price = `0.00`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 6.
    temp2-product = `Mouse`.
    temp2-category = `Hardware`.
    temp2-created = `20260310`.
    temp2-price = `19.90`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 7.
    temp2-product = `Headset`.
    temp2-category = `Hardware`.
    temp2-created = `20260322`.
    temp2-price = `79.00`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    temp2-id = 8.
    temp2-product = `Antivirus`.
    temp2-category = `Software`.
    temp2-created = `20260402`.
    temp2-price = `39.95`.
    temp2-currency = `EUR`.
    INSERT temp2 INTO TABLE temp1.
    mt_row = temp1.

    mo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_title( `abap-cloud-gui - ALV Grid`
        )->set_column_text( name = `ID`
                            text = `No.`
        )->set_column_hidden( `CURRENCY`
        )->set_line_selection( ).

  ENDMETHOD.

ENDCLASS.
