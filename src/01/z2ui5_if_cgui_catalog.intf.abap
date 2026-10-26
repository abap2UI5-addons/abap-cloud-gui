"! The transactions of an installation - what the command field and the
"! command palette (Ctrl+K) of a report start: a code, the report class,
"! a text and the variant to start with. One class of the installation
"! serves every report (set_catalog( ) in initialization( )); it is kept
"! with the report between the roundtrips - it implements
"! if_serializable_object, or keeps nothing but its settings
INTERFACE z2ui5_if_cgui_catalog PUBLIC.

  TYPES:
    BEGIN OF ty_s_transaction,
      code    TYPE string,
      report  TYPE string,
      text    TYPE string,
      variant TYPE string,
    END OF ty_s_transaction.
  TYPES ty_t_transaction TYPE STANDARD TABLE OF ty_s_transaction WITH EMPTY KEY.

  METHODS get
    RETURNING
      VALUE(result) TYPE ty_t_transaction.

ENDINTERFACE.
