"! The messages and popups of a report - what the short API of
"! z2ui5_cl_cgui_report (_msg( ), _msg_box( ), _popup( ) with
"! z2ui5_cl_cgui_msg and z2ui5_cl_cgui_dialog) asks the report for.
"! z2ui5_cl_cgui_report implements it with its message( ) and its popups
INTERFACE z2ui5_if_cgui_dialogs PUBLIC.

  "! MESSAGE text TYPE type - as message( ) of the report
  METHODS message
    IMPORTING
      text  TYPE clike
      type  TYPE clike
      field TYPE clike OPTIONAL.

  "! a message box of its own, whatever the type - not in the popover,
  "! the run goes on
  METHODS message_box
    IMPORTING
      text TYPE clike
      type TYPE clike.

  METHODS popup_to_confirm
    IMPORTING
      question TYPE clike
      ucomm    TYPE clike OPTIONAL
      title    TYPE clike OPTIONAL
      then     TYPE clike OPTIONAL.

  METHODS popup_to_decide
    IMPORTING
      question TYPE clike
      options  TYPE string_table
      ucomm    TYPE clike OPTIONAL
      title    TYPE clike OPTIONAL
      then     TYPE clike OPTIONAL.

  METHODS popup_get_values
    IMPORTING
      fields TYPE z2ui5_cl_cgui_popup=>ty_t_field
      ucomm  TYPE clike OPTIONAL
      title  TYPE clike OPTIONAL
      text   TYPE clike OPTIONAL
      then   TYPE clike OPTIONAL.

  METHODS popup_transport
    IMPORTING
      ucomm TYPE clike OPTIONAL
      title TYPE clike OPTIONAL
      then  TYPE clike OPTIONAL.

ENDINTERFACE.
