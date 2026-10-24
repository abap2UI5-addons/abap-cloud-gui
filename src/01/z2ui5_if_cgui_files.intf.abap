"! The files of a report - what z2ui5_cl_cgui_frontend asks the report it
"! runs in for: z2ui5_cl_cgui_report implements it, the frontend services
"! know the report through it (z2ui5_cl_cgui_frontend=>set_files( ))
INTERFACE z2ui5_if_cgui_files PUBLIC.

  "! the upload dialog - when the user picked the files, the F4 that
  "! opened it (or Execute) runs again and picked( ) answers with them;
  "! rerun: the run stops here and starts again with the files (Execute)
  METHODS upload_popup
    IMPORTING
      title        TYPE string    OPTIONAL
      multiple     TYPE abap_bool OPTIONAL
      filter       TYPE string    OPTIONAL
    RETURNING
      VALUE(rerun) TYPE abap_bool.

  "! the names of the files picked for the run of the dialog - once
  METHODS picked
    RETURNING
      VALUE(result) TYPE string_table.

  "! the names of the files the user uploaded
  METHODS names
    RETURNING
      VALUE(result) TYPE string_table.

  "! the content of the uploaded file of that name - the folder of name
  "! does not matter, nor the case
  METHODS content
    IMPORTING
      name    TYPE string
    EXPORTING
      content TYPE xstring
      found   TYPE abap_bool.

  "! the file to the browser, which saves it
  METHODS download
    IMPORTING
      name    TYPE string
      mime    TYPE string
      content TYPE xstring.

  METHODS open_url
    IMPORTING
      url TYPE string.

  METHODS clipboard
    IMPORTING
      text TYPE string.

ENDINTERFACE.
