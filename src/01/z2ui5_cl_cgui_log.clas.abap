"! An application log in memory - the messages of a report, kept with it
"! between the roundtrips:
"!   DATA(lo_log) = NEW z2ui5_cl_cgui_log( ).
"!   set_log( lo_log ).          " every message( ) goes into it as well
"!   ...
"!   log_display( lo_log ).      " the log as a popup, as SLG1 shows it
CLASS z2ui5_cl_cgui_log DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES z2ui5_if_cgui_log.

    "! the messages of a BAPIRET2-like table - components TYPE and MESSAGE
    METHODS add_table
      IMPORTING
        tab TYPE ANY TABLE.

    METHODS clear.

  PRIVATE SECTION.
    DATA mt_message TYPE z2ui5_if_cgui_log=>ty_t_message.

ENDCLASS.


CLASS z2ui5_cl_cgui_log IMPLEMENTATION.

  METHOD z2ui5_if_cgui_log~add.

    INSERT VALUE #( type = to_upper( type )
                    text = text ) INTO TABLE mt_message.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_log~get.

    result = mt_message.

  ENDMETHOD.

  METHOD add_table.

    FIELD-SYMBOLS <type> TYPE any.
    FIELD-SYMBOLS <text> TYPE any.

    LOOP AT tab ASSIGNING FIELD-SYMBOL(<row>).
      ASSIGN COMPONENT `TYPE` OF STRUCTURE <row> TO <type>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT `MESSAGE` OF STRUCTURE <row> TO <text>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      z2ui5_if_cgui_log~add( type = <type>
                             text = <text> ).
    ENDLOOP.

  ENDMETHOD.

  METHOD clear.

    CLEAR mt_message.

  ENDMETHOD.

ENDCLASS.
