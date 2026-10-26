"! An application log for a report - what its messages go into
"! (set_log( )) and what the message popover and log_display( ) show.
"! z2ui5_cl_cgui_log keeps the messages in memory; an adapter of the
"! installation writes them to the application log of the system - BAL on
"! premise, cl_bali_log on ABAP Cloud - or to the ABAP Logger. The object
"! is kept with the report between the roundtrips - it implements
"! if_serializable_object, or keeps nothing but its handle
INTERFACE z2ui5_if_cgui_log PUBLIC.

  TYPES:
    BEGIN OF ty_s_message,
      " E, W, I, S or A
      type TYPE string,
      text TYPE string,
    END OF ty_s_message.
  TYPES ty_t_message TYPE STANDARD TABLE OF ty_s_message WITH EMPTY KEY.

  "! a message into the log
  METHODS add
    IMPORTING
      type TYPE clike
      text TYPE clike.

  "! the messages of the log, in their order
  METHODS get
    RETURNING
      VALUE(result) TYPE ty_t_message.

ENDINTERFACE.
