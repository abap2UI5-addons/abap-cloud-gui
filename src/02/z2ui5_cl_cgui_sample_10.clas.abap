"! Flight network - the features of R11 in one report:
"!   selection screen  F4 on from AND to of a select-option - the upper
"!                     limit gets a hit list of its own (value_request_part)
"!   ALV tree          airline > connection > flight with checkboxes, an own
"!                     toolbar function and a secondary list on a click;
"!                     the flights of a connection are loaded when it is
"!                     opened (EXPAND_NO_CHILDREN), every tick sums up the
"!                     free seats at once (CHECKBOX_CHANGE)
"!   editable ALV      F4 in the airline cell (at_alv_value_request), the
"!                     check of a changed cell (at_data_changed)
"! Start it with ?app_start=z2ui5_cl_cgui_sample_10
CLASS z2ui5_cl_cgui_sample_10 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_flight,
        carrid   TYPE c LENGTH 3,
        connid   TYPE n LENGTH 4,
        fldate   TYPE d,
        price    TYPE p LENGTH 8 DECIMALS 2,
        currency TYPE c LENGTH 5,
        seatsocc TYPE i,
        seatsmax TYPE i,
      END OF ty_s_flight.
    TYPES ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_airline,
        carrid TYPE c LENGTH 3,
        name   TYPE string,
      END OF ty_s_airline.
    TYPES ty_t_airline TYPE STANDARD TABLE OF ty_s_airline WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_plan,
        carrid TYPE c LENGTH 3,
        connid TYPE n LENGTH 4,
        fldate TYPE d,
        seats  TYPE i,
        note   TYPE c LENGTH 40,
      END OF ty_s_plan.
    TYPES ty_t_plan TYPE STANDARD TABLE OF ty_s_plan WITH DEFAULT KEY.

    DATA s_carrid TYPE RANGE OF ty_s_flight-carrid.
    DATA p_tree   TYPE abap_bool.
    DATA p_plan   TYPE abap_bool.
    " the editable ALV - PUBLIC, so the grid binds it directly
    DATA mt_plan  TYPE ty_t_plan.
    " the free seats of the ticked flights - the last result of FREE
    DATA mv_free  TYPE i READ-ONLY.

  PROTECTED SECTION.
    DATA mt_flight  TYPE ty_t_flight.
    DATA mt_airline TYPE ty_t_airline.
    DATA mo_tree    TYPE REF TO z2ui5_cl_cgui_tree.

    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_value_request REDEFINITION.
    METHODS at_alv_value_request REDEFINITION.
    METHODS at_data_changed REDEFINITION.
    METHODS at_tree_node REDEFINITION.
    METHODS at_user_command REDEFINITION.
    METHODS at_tree_checkbox REDEFINITION.
    METHODS at_tree_expand_no_children REDEFINITION.

    METHODS mock_data.
    METHODS show_tree.
    METHODS show_plan.

    "! the free seats of the ticked flights into mv_free - their number
    METHODS free_seats
      RETURNING
        VALUE(result) TYPE i.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_sample_10 IMPLEMENTATION.

  METHOD initialization.

    set_title( `abap-cloud-gui - Flight Network` ).
    p_tree = abap_true.
    mock_data( ).

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Selection`
        )->select_option( val        = s_carrid
                          text       = `Airline`
                          value_help = abap_true
        )->block_end(
        )->block_begin( `Output`
        )->radiobutton( val   = p_tree
                        text  = `Flight network as tree`
                        group = `OUT`
        )->radiobutton( val   = p_plan
                        text  = `Booking plan (editable)`
                        group = `OUT`
        )->block_end( ).

  ENDMETHOD.

  METHOD at_value_request.
      DATA temp35 TYPE string.

    " AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_carrid-low / s_carrid-high
    IF field = `S_CARRID`.

      IF value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high.
        temp35 = `Airline - up to`.
      ELSE.
        temp35 = `Airline`.
      ENDIF.
      value_help_popup( tab   = mt_airline
                        col   = `CARRID`
                        title = temp35 ).
      RETURN.
    ENDIF.
    super->at_value_request( field ).

  ENDMETHOD.

  METHOD start_of_selection.
    DATA lt_all LIKE mt_flight.
    DATA ls_all LIKE LINE OF lt_all.

    " every run starts from all flights
    mock_data( ).
    " range_check( ) as IN - the transpiled runtime's IN knows I EQ, E EQ
    " and I CP only, and the selection can be an interval

    lt_all = mt_flight.
    CLEAR mt_flight.

    LOOP AT lt_all INTO ls_all.
      IF z2ui5_cl_cgui_context=>range_check( val   = ls_all-carrid
                                             range = s_carrid ) = abap_true.
        INSERT ls_all INTO TABLE mt_flight.
      ENDIF.
    ENDLOOP.

    IF mt_flight IS INITIAL.
      RETURN.
    ENDIF.

    IF p_plan = abap_true.
      show_plan( ).
    ELSE.
      show_tree( ).
    ENDIF.

  ENDMETHOD.

  METHOD show_tree.

    DATA ls_sum     TYPE ty_s_flight.
    DATA lv_carrid  TYPE ty_s_flight-carrid.
    DATA lv_connid  TYPE ty_s_flight-connid.
    DATA lv_airline TYPE i.
    DATA lv_first   TYPE i.
    DATA lt_flight LIKE mt_flight.
    DATA ls_flight LIKE LINE OF lt_flight.
        DATA ls_member LIKE LINE OF lt_flight.
        DATA temp36 TYPE z2ui5_cl_cgui_sample_10=>ty_s_airline-name.
        DATA temp37 TYPE z2ui5_cl_cgui_sample_10=>ty_s_airline.
        DATA lv_name LIKE temp36.

    mo_tree = tree( )->set_hierarchy_header( `Airline / Connection / Date`
        )->set_checkboxes( event  = abap_true
                           branch = abap_true
        )->add_function( name    = `FREE`
                         text    = `Free seats`
                         icon    = `sap-icon://sum`
                         tooltip = `Free seats of the ticked flights` ).


    lt_flight = mt_flight.
    SORT lt_flight BY carrid connid fldate.
    " sorted - a new airline or connection starts a node of its own

    LOOP AT lt_flight INTO ls_flight.
      IF lv_airline = 0 OR ls_flight-carrid <> lv_carrid.
        " the airline with the sums of its flights
        lv_carrid = ls_flight-carrid.
        CLEAR: lv_connid, ls_sum.

        LOOP AT lt_flight INTO ls_member WHERE carrid = lv_carrid.
          ls_sum-seatsocc = ls_sum-seatsocc + ls_member-seatsocc.
          ls_sum-seatsmax = ls_sum-seatsmax + ls_member-seatsmax.
        ENDLOOP.
        ls_sum-carrid = lv_carrid.

        CLEAR temp36.

        READ TABLE mt_airline INTO temp37 WITH KEY carrid = lv_carrid.
        IF sy-subrc = 0.
          temp36 = temp37-name.
        ENDIF.

        lv_name = temp36.
        lv_airline = mo_tree->add_node( text = |{ lv_carrid } { lv_name }|
                                        data = ls_sum ).
        IF lv_first = 0.
          lv_first = lv_airline.
        ENDIF.
      ENDIF.

      " the connections - their flights come when they are opened
      IF ls_flight-connid <> lv_connid.
        lv_connid = ls_flight-connid.
        mo_tree->add_node( parent = lv_airline
                           text   = |{ lv_connid }|
                           lazy   = abap_true
                           value  = |{ lv_carrid }{ lv_connid }| ).
      ENDIF.
    ENDLOOP.

    " the first airline is open
    IF lv_first <> 0.
      mo_tree->expand( lv_first ).
    ENDIF.

    mo_tree->set_column_text( name = `SEATSOCC` text = `Occupied`
        )->set_column_text( name = `SEATSMAX` text = `Capacity`
        )->set_column_hidden( `CARRID` ).

  ENDMETHOD.

  METHOD show_plan.

    DATA temp38 TYPE z2ui5_cl_cgui_sample_10=>ty_t_plan.
    DATA ls_flight LIKE LINE OF mt_flight.
      DATA temp39 LIKE LINE OF temp38.
    CLEAR temp38.

    LOOP AT mt_flight INTO ls_flight.

      temp39-carrid = ls_flight-carrid.
      temp39-connid = ls_flight-connid.
      temp39-fldate = ls_flight-fldate.
      INSERT temp39 INTO TABLE temp38.
    ENDLOOP.
    mt_plan = temp38.
    alv( mt_plan
        )->set_title( `Booking plan - F4 on the airline, seats are checked`
        )->set_edit(
        )->set_column_edit( name = `FLDATE`
                            val  = abap_false
        )->set_column_f4( `CARRID`
        )->set_column_text( name = `CARRID` text = `Airline`
        )->set_column_text( name = `CONNID` text = `Connection`
        )->set_column_text( name = `FLDATE` text = `Date`
        )->set_column_text( name = `SEATS`  text = `Seats to book`
        )->set_column_text( name = `NOTE`   text = `Note` ).

  ENDMETHOD.

  METHOD at_alv_value_request.

    " the classic ONF4 - an own hit list for the airline
    IF column = `CARRID`.
      value_help_popup( tab   = mt_airline
                        col   = `CARRID`
                        title = |Airline of row { row }| ).
      RETURN.
    ENDIF.
    super->at_alv_value_request( row    = row
                                 column = column ).

  ENDMETHOD.

  METHOD at_data_changed.

    DATA ls_plan TYPE z2ui5_cl_cgui_sample_10=>ty_s_plan.
        DATA temp40 LIKE sy-subrc.
        DATA temp41 LIKE sy-subrc.
        DATA ls_flight TYPE z2ui5_cl_cgui_sample_10=>ty_s_flight.
    READ TABLE mt_plan INTO ls_plan INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE column.
      WHEN `CARRID`.


        temp41 = sy-subrc.
        READ TABLE mt_airline WITH KEY carrid = ls_plan-carrid TRANSPORTING NO FIELDS.
        temp40 = sy-subrc.
        sy-subrc = temp41.
        IF NOT temp40 = 0.
          message( text  = |Airline { ls_plan-carrid } does not exist|
                   type  = `E`
                   field = column ).
        ENDIF.
      WHEN `SEATS`.

        READ TABLE mt_flight INTO ls_flight
             WITH KEY carrid = ls_plan-carrid connid = ls_plan-connid fldate = ls_plan-fldate.
        IF sy-subrc = 0 AND ls_plan-seats > ls_flight-seatsmax - ls_flight-seatsocc.
          message( text = |Only { ls_flight-seatsmax - ls_flight-seatsocc } seats free on { ls_plan-connid }|
                   type = `W` ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_tree_node ##NEEDED.
    DATA temp42 TYPE i.
    DATA ls_flight TYPE z2ui5_cl_cgui_sample_10=>ty_s_flight.

    " a flight: its details as secondary list - airline and connection
    " have no value, nothing is written and the tree stays
    IF value IS INITIAL OR value CN `0123456789`.
      RETURN.
    ENDIF.

    temp42 = value.

    READ TABLE mt_flight INTO ls_flight INDEX temp42.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    write( val   = |Flight { ls_flight-carrid } { ls_flight-connid }|
           color = z2ui5_cl_cgui_list=>cs_color-key )->new_line( )->uline( ).
    write( val = `Date`     len = 12 )->write( ls_flight-fldate )->new_line( ).
    write( val = `Price`    len = 12 )->write( val      = ls_flight-price
                                               currency = ls_flight-currency )->write( ls_flight-currency )->new_line( ).
    write( val = `Occupied` len = 12 )->write( |{ ls_flight-seatsocc } / { ls_flight-seatsmax }| )->new_line( ).

  ENDMETHOD.

  METHOD at_tree_expand_no_children.

    " EXPAND_NO_CHILDREN - the flights of the connection
    DATA lv_value TYPE z2ui5_cl_cgui_tree=>ty_s_node-value.
    DATA ls_flight LIKE LINE OF mt_flight.
      DATA lv_index LIKE sy-tabix.
      DATA temp43 TYPE string.
    lv_value = mo_tree->get_node( key )-value.

    LOOP AT mt_flight INTO ls_flight.

      lv_index = sy-tabix.
      IF |{ ls_flight-carrid }{ ls_flight-connid }| <> lv_value.
        CONTINUE.
      ENDIF.
      " the value leads back to the flight: its line in mt_flight

      IF ls_flight-seatsocc >= ls_flight-seatsmax.
        temp43 = `sap-icon://status-negative`.
      ELSE.
        temp43 = `sap-icon://flight`.
      ENDIF.
      mo_tree->add_node( parent  = key
                         text    = |{ ls_flight-fldate DATE = USER }|
                         data    = ls_flight
                         icon    = temp43
                         value   = |{ lv_index }| ).
    ENDLOOP.
    " a ticked connection passes its tick to the flights just loaded
    IF mo_tree->get_node( key )-checked = abap_true.
      mo_tree->set_checked( key = key
                            all = abap_true ).
    ENDIF.

  ENDMETHOD.

  METHOD at_tree_checkbox.

    " CHECKBOX_CHANGE - the node and the sum at once
    DATA lv_flights TYPE i.
    DATA temp44 TYPE string.
    lv_flights = free_seats( ).

    IF checked = abap_true.
      temp44 = `ticked`.
    ELSE.
      temp44 = `cleared`.
    ENDIF.
    message( |{ mo_tree->get_node( key )-text } { temp44 }: | &&
             |{ mv_free } free seats on { lv_flights } ticked flights| ).

  ENDMETHOD.

  METHOD free_seats.
    DATA temp45 TYPE z2ui5_cl_cgui_tree=>ty_t_key.
    DATA lv_key LIKE LINE OF temp45.
      DATA lv_value TYPE z2ui5_cl_cgui_tree=>ty_s_node-value.
      DATA temp46 TYPE i.
      DATA ls_flight TYPE z2ui5_cl_cgui_sample_10=>ty_s_flight.

    CLEAR mv_free.

    temp45 = mo_tree->get_checked( ).

    LOOP AT temp45 INTO lv_key.

      lv_value = mo_tree->get_node( lv_key )-value.
      " flights only - airlines and connections carry no line number
      IF lv_value IS INITIAL OR lv_value CN `0123456789`.
        CONTINUE.
      ENDIF.

      temp46 = lv_value.

      READ TABLE mt_flight INTO ls_flight INDEX temp46.
      IF sy-subrc = 0.
        mv_free = mv_free + ls_flight-seatsmax - ls_flight-seatsocc.
        result = result + 1.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD at_user_command.
      DATA lv_flights TYPE i.

    IF ucomm = `FREE`.

      lv_flights = free_seats( ).
      IF lv_flights = 0.
        message( text = `Tick the flights first`
                 type = `W` ).
        RETURN.
      ENDIF.
      message( |{ mv_free } free seats on { lv_flights } flights| ).
    ENDIF.

  ENDMETHOD.

  METHOD mock_data.

    DATA temp47 TYPE z2ui5_cl_cgui_sample_10=>ty_t_airline.
    DATA temp48 LIKE LINE OF temp47.
    DATA temp49 TYPE z2ui5_cl_cgui_sample_10=>ty_t_flight.
    DATA temp50 LIKE LINE OF temp49.
    CLEAR temp47.

    temp48-carrid = `AA`.
    temp48-name = `American Airlines`.
    INSERT temp48 INTO TABLE temp47.
    temp48-carrid = `JL`.
    temp48-name = `Japan Airlines`.
    INSERT temp48 INTO TABLE temp47.
    temp48-carrid = `LH`.
    temp48-name = `Lufthansa`.
    INSERT temp48 INTO TABLE temp47.
    temp48-carrid = `SQ`.
    temp48-name = `Singapore Airlines`.
    INSERT temp48 INTO TABLE temp47.
    temp48-carrid = `UA`.
    temp48-name = `United Airlines`.
    INSERT temp48 INTO TABLE temp47.
    mt_airline = temp47.


    CLEAR temp49.

    temp50-carrid = `LH`.
    temp50-connid = `0400`.
    temp50-fldate = `20260115`.
    temp50-price = `666.00`.
    temp50-currency = `EUR`.
    temp50-seatsocc = 120.
    temp50-seatsmax = 280.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `LH`.
    temp50-connid = `0400`.
    temp50-fldate = `20260215`.
    temp50-price = `666.00`.
    temp50-currency = `EUR`.
    temp50-seatsocc = 270.
    temp50-seatsmax = 280.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `LH`.
    temp50-connid = `0402`.
    temp50-fldate = `20260310`.
    temp50-price = `720.50`.
    temp50-currency = `EUR`.
    temp50-seatsocc = 280.
    temp50-seatsmax = 280.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `AA`.
    temp50-connid = `0017`.
    temp50-fldate = `20260120`.
    temp50-price = `422.94`.
    temp50-currency = `USD`.
    temp50-seatsocc = 300.
    temp50-seatsmax = 385.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `AA`.
    temp50-connid = `0064`.
    temp50-fldate = `20260412`.
    temp50-price = `422.94`.
    temp50-currency = `USD`.
    temp50-seatsocc = 385.
    temp50-seatsmax = 385.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `UA`.
    temp50-connid = `0941`.
    temp50-fldate = `20260505`.
    temp50-price = `879.82`.
    temp50-currency = `USD`.
    temp50-seatsocc = 150.
    temp50-seatsmax = 330.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `JL`.
    temp50-connid = `0407`.
    temp50-fldate = `20260221`.
    temp50-price = `106136`.
    temp50-currency = `JPY`.
    temp50-seatsocc = 90.
    temp50-seatsmax = 320.
    INSERT temp50 INTO TABLE temp49.
    temp50-carrid = `SQ`.
    temp50-connid = `0002`.
    temp50-fldate = `20260601`.
    temp50-price = `1016.00`.
    temp50-currency = `SGD`.
    temp50-seatsocc = 320.
    temp50-seatsmax = 400.
    INSERT temp50 INTO TABLE temp49.
    mt_flight = temp49.

  ENDMETHOD.

ENDCLASS.
