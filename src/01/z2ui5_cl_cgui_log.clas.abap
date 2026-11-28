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

  PROTECTED SECTION.
    " PROTECTED, not PRIVATE: the log is kept with the report, and the
    " transpiled runtime reaches PROTECTED attributes but not PRIVATE ones
    DATA mt_message TYPE z2ui5_if_cgui_log=>ty_t_message.

  PRIVATE SECTION.

ENDCLASS.


CLASS z2ui5_cl_cgui_log IMPLEMENTATION.

  METHOD z2ui5_if_cgui_log~add.

    DATA temp1 TYPE z2ui5_if_cgui_log=>ty_s_message.
    CLEAR temp1.
    temp1-type = to_upper( type ).
    temp1-text = text.
    INSERT temp1 INTO TABLE mt_message.

  ENDMETHOD.

  METHOD z2ui5_if_cgui_log~get.

    result = mt_message.

  ENDMETHOD.

  METHOD add_table.

    FIELD-SYMBOLS <type> TYPE any.
    FIELD-SYMBOLS <text> TYPE any.

    FIELD-SYMBOLS <row> TYPE ANY.
    LOOP AT tab ASSIGNING <row>.
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
