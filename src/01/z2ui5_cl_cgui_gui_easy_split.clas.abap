"! The stand-in of cl_gui_easy_splitter_container - a container of two
"! cells, top_left_container and bottom_right_container: one above the other
"! (orientation_vertical) or side by side (orientation_horizontal)
CLASS z2ui5_cl_cgui_gui_easy_split DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui_container
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        parent        TYPE REF TO z2ui5_cl_cgui_gui_container
        orientation   TYPE i     DEFAULT z2ui5_cl_cgui_gui_container=>orientation_vertical
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


CLASS z2ui5_cl_cgui_gui_easy_split IMPLEMENTATION.

  METHOD constructor.

    DATA(lv_vertical) = xsdbool( orientation = z2ui5_cl_cgui_gui_container=>orientation_vertical ).
    super->constructor( EXPORTING  parent     = parent
                                   rows       = COND #( WHEN lv_vertical = abap_true THEN 2 ELSE 1 )
                                   columns    = COND #( WHEN lv_vertical = abap_true THEN 1 ELSE 2 )
                        EXCEPTIONS cntl_error = 1
                                   OTHERS     = 2 ).
    IF sy-subrc <> 0.
      RAISE cntl_error.
    ENDIF.
    top_left_container = get_container( row    = 1
                                        column = 1 ).
    bottom_right_container = COND #( WHEN lv_vertical = abap_true
                                     THEN get_container( row = 2 column = 1 )
                                     ELSE get_container( row = 1 column = 2 ) ).

  ENDMETHOD.

ENDCLASS.
