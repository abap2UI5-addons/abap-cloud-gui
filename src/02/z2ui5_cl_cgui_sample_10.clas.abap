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
    TYPES ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_airline,
        carrid TYPE c LENGTH 3,
        name   TYPE string,
      END OF ty_s_airline.
    TYPES ty_t_airline TYPE STANDARD TABLE OF ty_s_airline WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_plan,
        carrid TYPE c LENGTH 3,
        connid TYPE n LENGTH 4,
        fldate TYPE d,
        seats  TYPE i,
        note   TYPE c LENGTH 40,
      END OF ty_s_plan.
    TYPES ty_t_plan TYPE STANDARD TABLE OF ty_s_plan WITH EMPTY KEY.

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

    " AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_carrid-low / s_carrid-high
    IF field = `S_CARRID`.
      value_help_popup( tab   = mt_airline
                        col   = `CARRID`
                        title = COND #( WHEN value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high
                                        THEN `Airline - up to`
                                        ELSE `Airline` ) ).
      RETURN.
    ENDIF.
    super->at_value_request( field ).

  ENDMETHOD.

  METHOD start_of_selection.

    " every run starts from all flights
    mock_data( ).
    " range_check( ) as IN - the transpiled runtime's IN knows I EQ, E EQ
    " and I CP only, and the selection can be an interval
    DATA(lt_all) = mt_flight.
    CLEAR mt_flight.
    LOOP AT lt_all INTO DATA(ls_all).
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

    mo_tree = tree( )->set_hierarchy_header( `Airline / Connection / Date`
        )->set_checkboxes( event  = abap_true
                           branch = abap_true
        )->add_function( name    = `FREE`
                         text    = `Free seats`
                         icon    = `sap-icon://sum`
                         tooltip = `Free seats of the ticked flights` ).

    DATA(lt_flight) = mt_flight.
    SORT lt_flight BY carrid connid fldate.
    " sorted - a new airline or connection starts a node of its own
    LOOP AT lt_flight INTO DATA(ls_flight).
      IF lv_airline = 0 OR ls_flight-carrid <> lv_carrid.
        " the airline with the sums of its flights
        lv_carrid = ls_flight-carrid.
        CLEAR: lv_connid, ls_sum.
        LOOP AT lt_flight INTO DATA(ls_member) WHERE carrid = lv_carrid.
          ls_sum-seatsocc = ls_sum-seatsocc + ls_member-seatsocc.
          ls_sum-seatsmax = ls_sum-seatsmax + ls_member-seatsmax.
        ENDLOOP.
        ls_sum-carrid = lv_carrid.
        DATA(lv_name) = VALUE #( mt_airline[ carrid = lv_carrid ]-name OPTIONAL ).
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

    mt_plan = VALUE #( FOR ls_flight IN mt_flight ( carrid = ls_flight-carrid
                                                    connid = ls_flight-connid
                                                    fldate = ls_flight-fldate ) ).
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

    READ TABLE mt_plan INTO DATA(ls_plan) INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE column.
      WHEN `CARRID`.
        IF NOT line_exists( mt_airline[ carrid = ls_plan-carrid ] ).
          message( text  = |Airline { ls_plan-carrid } does not exist|
                   type  = `E`
                   field = column ).
        ENDIF.
      WHEN `SEATS`.
        READ TABLE mt_flight INTO DATA(ls_flight)
             WITH KEY carrid = ls_plan-carrid connid = ls_plan-connid fldate = ls_plan-fldate.
        IF sy-subrc = 0 AND ls_plan-seats > ls_flight-seatsmax - ls_flight-seatsocc.
          message( text = |Only { ls_flight-seatsmax - ls_flight-seatsocc } seats free on { ls_plan-connid }|
                   type = `W` ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

  METHOD at_tree_node ##NEEDED.

    " a flight: its details as secondary list - airline and connection
    " have no value, nothing is written and the tree stays
    IF value IS INITIAL OR value CN `0123456789`.
      RETURN.
    ENDIF.
    READ TABLE mt_flight INTO DATA(ls_flight) INDEX CONV i( value ).
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
    DATA(lv_value) = mo_tree->get_node( key )-value.
    LOOP AT mt_flight INTO DATA(ls_flight).
      DATA(lv_index) = sy-tabix.
      IF |{ ls_flight-carrid }{ ls_flight-connid }| <> lv_value.
        CONTINUE.
      ENDIF.
      " the value leads back to the flight: its line in mt_flight
      mo_tree->add_node( parent  = key
                         text    = |{ ls_flight-fldate DATE = USER }|
                         data    = ls_flight
                         icon    = COND #( WHEN ls_flight-seatsocc >= ls_flight-seatsmax
                                           THEN `sap-icon://status-negative`
                                           ELSE `sap-icon://flight` )
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
    DATA(lv_flights) = free_seats( ).
    message( |{ mo_tree->get_node( key )-text } { COND #( WHEN checked = abap_true THEN `ticked` ELSE `cleared` ) }: | &&
             |{ mv_free } free seats on { lv_flights } ticked flights| ).

  ENDMETHOD.

  METHOD free_seats.

    CLEAR mv_free.
    LOOP AT mo_tree->get_checked( ) INTO DATA(lv_key).
      DATA(lv_value) = mo_tree->get_node( lv_key )-value.
      " flights only - airlines and connections carry no line number
      IF lv_value IS INITIAL OR lv_value CN `0123456789`.
        CONTINUE.
      ENDIF.
      READ TABLE mt_flight INTO DATA(ls_flight) INDEX CONV i( lv_value ).
      IF sy-subrc = 0.
        mv_free = mv_free + ls_flight-seatsmax - ls_flight-seatsocc.
        result = result + 1.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD at_user_command.

    IF ucomm = `FREE`.
      DATA(lv_flights) = free_seats( ).
      IF lv_flights = 0.
        message( text = `Tick the flights first`
                 type = `W` ).
        RETURN.
      ENDIF.
      message( |{ mv_free } free seats on { lv_flights } flights| ).
    ENDIF.

  ENDMETHOD.

  METHOD mock_data.

    mt_airline = VALUE #( ( carrid = `AA` name = `American Airlines` )
                          ( carrid = `JL` name = `Japan Airlines` )
                          ( carrid = `LH` name = `Lufthansa` )
                          ( carrid = `SQ` name = `Singapore Airlines` )
                          ( carrid = `UA` name = `United Airlines` ) ).

    mt_flight = VALUE #(
        ( carrid = `LH` connid = `0400` fldate = `20260115` price = `666.00`  currency = `EUR` seatsocc = 120 seatsmax = 280 )
        ( carrid = `LH` connid = `0400` fldate = `20260215` price = `666.00`  currency = `EUR` seatsocc = 270 seatsmax = 280 )
        ( carrid = `LH` connid = `0402` fldate = `20260310` price = `720.50`  currency = `EUR` seatsocc = 280 seatsmax = 280 )
        ( carrid = `AA` connid = `0017` fldate = `20260120` price = `422.94`  currency = `USD` seatsocc = 300 seatsmax = 385 )
        ( carrid = `AA` connid = `0064` fldate = `20260412` price = `422.94`  currency = `USD` seatsocc = 385 seatsmax = 385 )
        ( carrid = `UA` connid = `0941` fldate = `20260505` price = `879.82`  currency = `USD` seatsocc = 150 seatsmax = 330 )
        ( carrid = `JL` connid = `0407` fldate = `20260221` price = `106136`  currency = `JPY` seatsocc = 90  seatsmax = 320 )
        ( carrid = `SQ` connid = `0002` fldate = `20260601` price = `1016.00` currency = `SGD` seatsocc = 320 seatsmax = 400 ) ).

  ENDMETHOD.

ENDCLASS.
