"! The short API of the popups of a report, in the style of abap2UI5:
"! _popup( )->confirm( question = `Post the document?` ucomm = `POST` ) is
"! POPUP_TO_CONFIRM, decide( ) POPUP_TO_DECIDE, get_values( )
"! POPUP_GET_VALUES - the answer comes as at_user_command( ucomm ), as the
"! popup methods of z2ui5_cl_cgui_report have it
CLASS z2ui5_cl_cgui_dialog DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    METHODS constructor
      IMPORTING
        report TYPE REF TO z2ui5_if_cgui_dialogs.

    METHODS confirm
      IMPORTING
        question TYPE clike
        ucomm    TYPE clike
        title    TYPE clike OPTIONAL.

    "! the transport request popup - at_user_command( ucomm ) when the
    "! user picked one or chose no transport, get_transport( ) the answer
    METHODS transport
      IMPORTING
        ucomm TYPE clike
        title TYPE clike OPTIONAL.

    METHODS decide
      IMPORTING
        question TYPE clike
        options  TYPE string_table
        ucomm    TYPE clike
        title    TYPE clike OPTIONAL.

    METHODS get_values
      IMPORTING
        fields TYPE z2ui5_cl_cgui_popup=>ty_t_field
        ucomm  TYPE clike
        title  TYPE clike OPTIONAL
        text   TYPE clike OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_report TYPE REF TO z2ui5_if_cgui_dialogs.
ENDCLASS.


CLASS z2ui5_cl_cgui_dialog IMPLEMENTATION.

  METHOD constructor.

    mo_report = report.

  ENDMETHOD.

  METHOD confirm.

    mo_report->popup_to_confirm( question = question
                                 ucomm    = ucomm
                                 title    = title ).

  ENDMETHOD.

  METHOD transport.

    mo_report->popup_transport( ucomm = ucomm
                                title = title ).

  ENDMETHOD.

  METHOD decide.

    mo_report->popup_to_decide( question = question
                                options  = options
                                ucomm    = ucomm
                                title    = title ).

  ENDMETHOD.

  METHOD get_values.

    mo_report->popup_get_values( fields = fields
                                 ucomm  = ucomm
                                 title  = title
                                 text   = text ).

  ENDMETHOD.

ENDCLASS.
