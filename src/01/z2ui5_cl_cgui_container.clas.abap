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
CLASS z2ui5_cl_cgui_container DEFINITION PUBLIC
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
    CLASS-DATA default_screen TYPE REF TO z2ui5_cl_cgui_container READ-ONLY.
    CLASS-DATA screen0 TYPE REF TO z2ui5_cl_cgui_container READ-ONLY.

    "! the two cells of an easy splitter
    DATA top_left_container     TYPE REF TO z2ui5_cl_cgui_container READ-ONLY.
    DATA bottom_right_container TYPE REF TO z2ui5_cl_cgui_container READ-ONLY.

    "! container_name the preferred parameter - NEW cl_gui_custom_container( 'CC' )
    "! names the area
    METHODS constructor
      IMPORTING
        parent                  TYPE REF TO z2ui5_cl_cgui_container OPTIONAL
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
      PREFERRED PARAMETER container_name
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
        VALUE(result) TYPE REF TO z2ui5_cl_cgui_container.

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

    "! the position, size and metric of a dialog box or a docking container
    "! - the browser lays the controls out itself: taken, without effect
    METHODS set_top
      IMPORTING
        top TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_left
      IMPORTING
        left TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_width
      IMPORTING
        width TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_height
      IMPORTING
        height TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_metric
      IMPORTING
        metric TYPE i
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
    TYPES temp1_c481432a78 TYPE STANDARD TABLE OF REF TO z2ui5_cl_cgui_container WITH DEFAULT KEY.
DATA mt_cell TYPE temp1_c481432a78.
ENDCLASS.


CLASS z2ui5_cl_cgui_container IMPLEMENTATION.

  METHOD constructor.
    DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA temp2 TYPE xsdboolean.

    super->constructor( ).

    CLEAR temp1.
    temp1-kind = z2ui5_if_cgui_gui=>cs_kind-container.
    temp1-parent = id_of( parent ).
    temp1-name = to_upper( condense( container_name ) ).
    temp1-dynnr = condense( dynnr ).
    temp1-side = side.
    temp1-rows = rows.
    temp1-columns = columns.
    temp1-caption = caption.

    temp2 = boolc( width IS SUPPLIED OR height IS SUPPLIED OR top IS SUPPLIED OR left IS SUPPLIED ).
    temp1-dialog = temp2.
    IF add( temp1 ) = abap_false.
      RAISE cntl_error.
    ENDIF.

  ENDMETHOD.

  METHOD get_container.

    " the same cell is the same container
    DATA lo_cell LIKE LINE OF mt_cell.
      DATA ls_cell TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    LOOP AT mt_cell INTO lo_cell.

      ls_cell = lo_cell->get( ).
      IF ls_cell-row = row AND ls_cell-column = column.
        result = lo_cell.
        RETURN.
      ENDIF.
    ENDLOOP.
    CREATE OBJECT result EXPORTING parent = me.

    ls_control = result->get( ).
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

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    ls_control = get( ).
    ls_control-caption = caption.
    put( ls_control ).

  ENDMETHOD.

  METHOD set_top.
  ENDMETHOD.

  METHOD set_left.
  ENDMETHOD.

  METHOD set_width.
  ENDMETHOD.

  METHOD set_height.
  ENDMETHOD.

  METHOD set_metric.
  ENDMETHOD.

  METHOD link.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    ls_control = get( ).
    IF dynnr IS SUPPLIED.
      ls_control-dynnr = condense( dynnr ).
    ENDIF.
    IF container IS SUPPLIED.
      ls_control-name = to_upper( condense( container ) ).
    ENDIF.
    put( ls_control ).

  ENDMETHOD.

ENDCLASS.
