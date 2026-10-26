"! The stand-in of the SALV exceptions - cx_salv_msg, cx_salv_not_found,
"! cx_salv_existing, cx_salv_data_error, cx_salv_wrong_call. A CATCH of
"! them stays as the report wrote it; the stand-ins of the SALV raise them
"! where the classic does: a column that is not there
CLASS z2ui5_cx_cgui_salv DEFINITION
  PUBLIC
  INHERITING FROM cx_no_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    DATA mv_text TYPE string.

    METHODS constructor
      IMPORTING
        val       TYPE clike          OPTIONAL
        !previous TYPE REF TO cx_root OPTIONAL
          PREFERRED PARAMETER val.

    METHODS if_message~get_text REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cx_cgui_salv IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor( previous = previous ).
    CLEAR textid.
    mv_text = val.

  ENDMETHOD.

  METHOD if_message~get_text.

    result = mv_text.
    IF result IS INITIAL.
      result = `CGUI_SALV_ERROR`.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
