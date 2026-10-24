"! The stand-in of the SAP GUI containers - cl_gui_container,
"! cl_gui_custom_container, cl_gui_docking_container,
"! cl_gui_splitter_container, cl_gui_easy_splitter_container and
"! cl_gui_dialogbox_container in one class, with the parameters of all of
"! their constructors. A custom container is the custom control area
"! container_name of its screen (custom_control( ) of the screen builder),
"! a docking container sits on the screen dynnr (the screen it was created
"! for), a splitter shows its cells one after another. Sizes, sashes and
"! the side of a docking container have no counterpart: the controls fill
"! the width of the page
CLASS z2ui5_cl_cgui_gui_container DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    " cl_gui_docking_container
    CONSTANTS dock_at_left   TYPE i VALUE 1.
    CONSTANTS dock_at_top    TYPE i VALUE 2.
    CONSTANTS dock_at_right  TYPE i VALUE 4.
    CONSTANTS dock_at_bottom TYPE i VALUE 8.
    " cl_gui_splitter_container
    CONSTANTS mode_absolute    TYPE i VALUE 0.
    CONSTANTS mode_relative    TYPE i VALUE 1.
    CONSTANTS type_movable     TYPE i VALUE 0.
    CONSTANTS type_sashvisible TYPE i VALUE 1.
    " cl_gui_easy_splitter_container
    CONSTANTS orientation_vertical   TYPE i VALUE 0.
    CONSTANTS orientation_horizontal TYPE i VALUE 1.
    " cl_gui_container
    CONSTANTS lifetime_imode   TYPE i VALUE 0.
    CONSTANTS lifetime_dynpro  TYPE i VALUE 1.
    CONSTANTS lifetime_default TYPE i VALUE 0.

    "! the Close button of a dialog box container
    EVENTS close.

    "! cl_gui_container=>default_screen and screen0 - the screen itself
    CLASS-DATA default_screen TYPE REF TO z2ui5_cl_cgui_gui_container READ-ONLY.
    CLASS-DATA screen0 TYPE REF TO z2ui5_cl_cgui_gui_container READ-ONLY.

    "! the two cells of an easy splitter
    DATA top_left_container     TYPE REF TO z2ui5_cl_cgui_gui_container READ-ONLY.
    DATA bottom_right_container TYPE REF TO z2ui5_cl_cgui_gui_container READ-ONLY.

    METHODS constructor
      IMPORTING
        parent                  TYPE REF TO z2ui5_cl_cgui_gui_container OPTIONAL
        container_name          TYPE clike OPTIONAL
        style                   TYPE i     OPTIONAL
        lifetime                TYPE i     OPTIONAL
        repid                   TYPE clike OPTIONAL
        dynnr                   TYPE clike OPTIONAL
        no_autodef_progid_dynnr TYPE clike OPTIONAL
        side                    TYPE i     OPTIONAL
        extension               TYPE i     OPTIONAL
        ratio                   TYPE i     OPTIONAL
        metric                  TYPE i     OPTIONAL
        caption                 TYPE clike OPTIONAL
        name                    TYPE clike OPTIONAL
        rows                    TYPE i     OPTIONAL
        columns                 TYPE i     OPTIONAL
        align                   TYPE i     OPTIONAL
        link_dynnr              TYPE clike OPTIONAL
        link_repid              TYPE clike OPTIONAL
        orientation             TYPE i     OPTIONAL
        sash_position           TYPE i     OPTIONAL
        with_border             TYPE i     OPTIONAL
        width                   TYPE i     OPTIONAL
        height                  TYPE i     OPTIONAL
        top                     TYPE i     OPTIONAL
        left                    TYPE i     OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error
        lifetime_dynpro_dynpro_link
        cntl_install_error
        illegal_event_combination.

    "! the cell row / column of a splitter - a container of its own
    METHODS get_container
      IMPORTING
        row           TYPE i
        column        TYPE i
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_gui_container.

    METHODS set_row_height
      IMPORTING
        id     TYPE i
        height TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_column_width
      IMPORTING
        id    TYPE i
        width TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_row_mode
      IMPORTING
        mode TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_column_mode
      IMPORTING
        mode TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_row_sash
      IMPORTING
        id    TYPE i
        type  TYPE i
        value TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_column_sash
      IMPORTING
        id    TYPE i
        type  TYPE i
        value TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_extension
      IMPORTING
        extension TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_caption
      IMPORTING
        caption TYPE clike
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    "! a docking container is linked to another screen
    METHODS link
      IMPORTING
        repid     TYPE clike OPTIONAL
        dynnr     TYPE clike OPTIONAL
        container TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        lifetime_dynpro_dynpro_link.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mt_cell TYPE STANDARD TABLE OF REF TO z2ui5_cl_cgui_gui_container WITH EMPTY KEY.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui_container IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).
    IF add( VALUE #( kind    = z2ui5_if_cgui_gui=>cs_kind-container
                     parent  = id_of( parent )
                     name    = to_upper( condense( container_name ) )
                     dynnr   = condense( dynnr )
                     side    = side
                     rows    = rows
                     columns = columns
                     caption = caption
                     " cl_gui_dialogbox_container: a box of its own on the screen
                     dialog  = xsdbool( width IS SUPPLIED OR height IS SUPPLIED OR top IS SUPPLIED
                                     OR left IS SUPPLIED ) ) ) = abap_false.
      RAISE cntl_error.
    ENDIF.

  ENDMETHOD.

  METHOD get_container.

    " the same cell is the same container
    LOOP AT mt_cell INTO DATA(lo_cell).
      DATA(ls_cell) = lo_cell->get( ).
      IF ls_cell-row = row AND ls_cell-column = column.
        result = lo_cell.
        RETURN.
      ENDIF.
    ENDLOOP.
    result = NEW #( parent = me ).
    DATA(ls_control) = result->get( ).
    ls_control-row = row.
    ls_control-column = column.
    result->put( ls_control ).
    INSERT result INTO TABLE mt_cell.

  ENDMETHOD.

  METHOD set_row_height ##NEEDED.
  ENDMETHOD.

  METHOD set_column_width ##NEEDED.
  ENDMETHOD.

  METHOD set_row_mode ##NEEDED.
  ENDMETHOD.

  METHOD set_column_mode ##NEEDED.
  ENDMETHOD.

  METHOD set_row_sash ##NEEDED.
  ENDMETHOD.

  METHOD set_column_sash ##NEEDED.
  ENDMETHOD.

  METHOD set_extension ##NEEDED.
  ENDMETHOD.

  METHOD set_caption.

    DATA(ls_control) = get( ).
    ls_control-caption = caption.
    put( ls_control ).

  ENDMETHOD.

  METHOD link.

    DATA(ls_control) = get( ).
    IF dynnr IS SUPPLIED.
      ls_control-dynnr = condense( dynnr ).
    ENDIF.
    IF container IS SUPPLIED.
      ls_control-name = to_upper( condense( container ) ).
    ENDIF.
    put( ls_control ).

  ENDMETHOD.

ENDCLASS.
