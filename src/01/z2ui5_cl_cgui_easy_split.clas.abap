"! The stand-in of cl_gui_easy_splitter_container - a container of two
"! cells, top_left_container and bottom_right_container: one above the other
"! (orientation_vertical) or side by side (orientation_horizontal)
CLASS z2ui5_cl_cgui_easy_split DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_container
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        parent        TYPE REF TO z2ui5_cl_cgui_container
        orientation   TYPE i     DEFAULT z2ui5_cl_cgui_container=>orientation_vertical
        sash_position TYPE i     DEFAULT 50
        with_border   TYPE i     DEFAULT 1
        lifetime      TYPE i     OPTIONAL
        name          TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_easy_split IMPLEMENTATION.

  METHOD constructor.

    DATA lv_vertical TYPE abap_bool.
    DATA temp4 TYPE xsdboolean.
    DATA temp1 TYPE i.
    DATA temp3 TYPE i.
    DATA temp2 TYPE REF TO z2ui5_cl_cgui_container.
    temp4 = boolc( orientation = z2ui5_cl_cgui_container=>orientation_vertical ).
    lv_vertical = temp4.

    IF lv_vertical = abap_true.
      temp1 = 2.
    ELSE.
      temp1 = 1.
    ENDIF.

    IF lv_vertical = abap_true.
      temp3 = 1.
    ELSE.
      temp3 = 2.
    ENDIF.
    super->constructor( EXPORTING  parent     = parent
                                   rows       = temp1
                                   columns    = temp3
                        EXCEPTIONS cntl_error = 1
                                   OTHERS     = 2 ).
    IF sy-subrc <> 0.
      RAISE cntl_error.
    ENDIF.
    top_left_container = get_container( row    = 1
                                        column = 1 ).

    IF lv_vertical = abap_true.
      temp2 = get_container( row = 2 column = 1 ).
    ELSE.
      temp2 = get_container( row = 1 column = 2 ).
    ENDIF.
    bottom_right_container = temp2.

  ENDMETHOD.

ENDCLASS.
