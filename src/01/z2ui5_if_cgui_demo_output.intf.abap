"! The output object of z2ui5_cl_cgui_demo_output=>new( ) - the stand-in of
"! if_demo_output: every method writes into the list of the report it runs
"! in and returns the object, so the calls chain as they did
INTERFACE z2ui5_if_cgui_demo_output PUBLIC.

  "! data - an elementary value, a structure in a line, a table as columns
  "! under the names of its components; name heads it
  METHODS write
    IMPORTING
      data          TYPE any
      name          TYPE clike OPTIONAL
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  METHODS write_data
    IMPORTING
      value         TYPE any
      name          TYPE clike OPTIONAL
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  "! text - a line per line of it
  METHODS write_text
    IMPORTING
      text          TYPE clike
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  "! html - its text, without the tags
  METHODS write_html
    IMPORTING
      html          TYPE csequence
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  METHODS write_json
    IMPORTING
      json          TYPE simple
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  "! a heading - the sections below it are numbered one level deeper
  METHODS begin_section
    IMPORTING
      title         TYPE clike OPTIONAL
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  METHODS next_section
    IMPORTING
      title         TYPE clike OPTIONAL
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  METHODS end_section
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  "! a horizontal line
  METHODS line
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  "! data (when passed), then the output shows - it is part of the list of
  "! the run, which shows when the run ends
  METHODS display
    IMPORTING
      data TYPE any   OPTIONAL
      name TYPE clike OPTIONAL.

  "! what the output wrote since its last display( ), get( ) or clear( ) is
  "! taken out of the list again
  METHODS clear
    RETURNING
      VALUE(output) TYPE REF TO z2ui5_if_cgui_demo_output.

  "! data (when passed), then what the output wrote since its last
  "! display( ), get( ) or clear( ) as an HTML page - taken out of the list,
  "! for cl_abap_browser=>show_html( ) or an HTML viewer
  METHODS get
    IMPORTING
      data          TYPE any   OPTIONAL
      name          TYPE clike OPTIONAL
    RETURNING
      VALUE(output) TYPE string.

ENDINTERFACE.
