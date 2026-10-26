"! The short API of the messages of a report, in the style of abap2UI5:
"! _msg( )->e( `No flights found` ) is MESSAGE ... TYPE 'E',
"! _msg_box( )->i( `Saved` ) a message box of its own. Every method returns
"! the object, so messages chain: _msg( )->w( `a` )->s( `b` )
CLASS z2ui5_cl_cgui_msg DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    "! box: every message a message box of its own (_msg_box( ))
    METHODS constructor
      IMPORTING
        report TYPE REF TO z2ui5_if_cgui_dialogs
        box    TYPE abap_bool DEFAULT abap_false.

    "! an error - the run stops, as MESSAGE TYPE 'E'
    METHODS e
      IMPORTING
        text          TYPE clike
        field         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

    METHODS w
      IMPORTING
        text          TYPE clike
        field         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

    METHODS i
      IMPORTING
        text          TYPE clike
        field         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

    METHODS s
      IMPORTING
        text          TYPE clike
        field         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

    "! an abort - as MESSAGE TYPE 'A'
    METHODS a
      IMPORTING
        text          TYPE clike
        field         TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_msg.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_report TYPE REF TO z2ui5_if_cgui_dialogs.
    DATA mv_box TYPE abap_bool.

    METHODS send
      IMPORTING
        text  TYPE clike
        type  TYPE clike
        field TYPE clike OPTIONAL.
ENDCLASS.


CLASS z2ui5_cl_cgui_msg IMPLEMENTATION.

  METHOD constructor.

    mo_report = report.
    mv_box = box.

  ENDMETHOD.

  METHOD e.

    send( text  = text
          type  = `E`
          field = field ).
    result = me.

  ENDMETHOD.

  METHOD w.

    send( text  = text
          type  = `W`
          field = field ).
    result = me.

  ENDMETHOD.

  METHOD i.

    send( text  = text
          type  = `I`
          field = field ).
    result = me.

  ENDMETHOD.

  METHOD s.

    send( text  = text
          type  = `S`
          field = field ).
    result = me.

  ENDMETHOD.

  METHOD a.

    send( text  = text
          type  = `A`
          field = field ).
    result = me.

  ENDMETHOD.

  METHOD send.

    IF mo_report IS NOT BOUND.
      RETURN.
    ENDIF.
    IF mv_box = abap_true.
      mo_report->message_box( text = text
                              type = type ).
    ELSE.
      mo_report->message( text  = text
                          type  = type
                          field = field ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
