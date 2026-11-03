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
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

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
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    client->view_display( mo_alv->stringify( client = client
                                             tab    = mt_row ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get_event( ) = z2ui5_cl_cgui_alv=>cs_event-line_selection.
      DATA(lv_row) = z2ui5_cl_cgui_alv=>get_row_by_event( client ).
      READ TABLE mt_row INTO DATA(ls_row) INDEX lv_row.
      IF sy-subrc = 0.
        client->message_toast_display( |{ ls_row-product } selected| ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD model_init.

    mt_row = VALUE #(
        ( id = 1 product = `Notebook`  category = `Hardware` created = `20260105` price = `956.00` currency = `EUR` )
        ( id = 2 product = `Monitor`   category = `Hardware` created = `20260112` price = `289.90` currency = `EUR` )
        ( id = 3 product = `Keyboard`  category = `Hardware` created = `20260203` price = `49.99`  currency = `EUR` )
        ( id = 4 product = `Office`    category = `Software` created = `20260217` price = `129.00` currency = `EUR` )
        ( id = 5 product = `IDE`       category = `Software` created = `20260301` price = `0.00`   currency = `EUR` )
        ( id = 6 product = `Mouse`     category = `Hardware` created = `20260310` price = `19.90`  currency = `EUR` )
        ( id = 7 product = `Headset`   category = `Hardware` created = `20260322` price = `79.00`  currency = `EUR` )
        ( id = 8 product = `Antivirus` category = `Software` created = `20260402` price = `39.95`  currency = `EUR` ) ).

    mo_alv = z2ui5_cl_cgui_alv=>factory(
        )->set_title( `abap-cloud-gui - ALV Grid`
        )->set_column_text( name = `ID`
                            text = `No.`
        )->set_column_hidden( `CURRENCY`
        )->set_line_selection( ).

  ENDMETHOD.

ENDCLASS.
