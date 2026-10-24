"! The run of a report stops here and starts again - raised where the run
"! needs what only the user can give, after the dialog for it is opened
"! (z2ui5_cl_cgui_frontend=>gui_upload( ) without the file); the report
"! catches it around the run and shows the dialog instead of the list
CLASS z2ui5_cx_cgui_stop DEFINITION
  PUBLIC
  INHERITING FROM cx_no_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cx_cgui_stop IMPLEMENTATION.
ENDCLASS.
