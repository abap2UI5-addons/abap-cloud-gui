"! The stand-in of cl_gui_control - the SAP GUI controls of a classic report
"! as parts of its screen in the browser: z2ui5_cl_cgui_gui_container for
"! the containers, z2ui5_cl_cgui_gui_textedit, z2ui5_cl_cgui_gui_html_viewer.
"! The methods keep the classic signatures and EXCEPTIONS, so a converted
"! call passes what the classic one did. A control holds its id only - its
"! state is a line of the report it runs in (z2ui5_if_cgui_gui), which the
"! report runtime renders and keeps from one roundtrip to the next
CLASS z2ui5_cl_cgui_gui DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    CONSTANTS true  TYPE i VALUE 1.
    CONSTANTS false TYPE i VALUE 0.

    "! the report the controls belong to - z2ui5_cl_cgui_report sets it at
    "! the start of every roundtrip
    CLASS-METHODS set_report
      IMPORTING
        report TYPE REF TO z2ui5_if_cgui_gui.

    "! the focus goes into the control - the browser keeps it where the user is
    CLASS-METHODS set_focus
      IMPORTING
        control TYPE REF TO z2ui5_cl_cgui_gui
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_visible
      IMPORTING
        visible TYPE simple
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    "! the control is gone from its screen
    METHODS free
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    "! the id of the control in its report
    METHODS get_id
      RETURNING
        VALUE(result) TYPE i.

  PROTECTED SECTION.
    CLASS-DATA go_report TYPE REF TO z2ui5_if_cgui_gui.

    DATA mv_id TYPE i.

    "! the control in the report - abap_false when there is no report
    METHODS add
      IMPORTING
        control       TYPE z2ui5_if_cgui_gui=>ty_s_control
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS get
      RETURNING
        VALUE(result) TYPE z2ui5_if_cgui_gui=>ty_s_control.

    METHODS put
      IMPORTING
        control TYPE z2ui5_if_cgui_gui=>ty_s_control.

    "! the id of a parent container, 0 for none
    CLASS-METHODS id_of
      IMPORTING
        control       TYPE REF TO z2ui5_cl_cgui_gui
      RETURNING
        VALUE(result) TYPE i.

    "! the classic flag of a mode: 1 or 'X' - true, 0 or space - false
    CLASS-METHODS flag
      IMPORTING
        mode          TYPE simple
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_gui IMPLEMENTATION.

  METHOD set_report.

    go_report = report.

  ENDMETHOD.

  METHOD set_focus ##NEEDED.
  ENDMETHOD.

  METHOD set_visible.

    DATA(ls_control) = get( ).
    IF ls_control-id IS INITIAL.
      RAISE cntl_error.
    ENDIF.
    ls_control-hidden = xsdbool( flag( visible ) = abap_false ).
    put( ls_control ).

  ENDMETHOD.

  METHOD free.

    DATA(ls_control) = get( ).
    IF ls_control-id IS INITIAL.
      RETURN.
    ENDIF.
    ls_control-freed = abap_true.
    put( ls_control ).

  ENDMETHOD.

  METHOD get_id.

    result = mv_id.

  ENDMETHOD.

  METHOD add.

    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    mv_id = go_report->control_add( control ).
    result = abap_true.

  ENDMETHOD.

  METHOD get.

    IF go_report IS BOUND AND mv_id IS NOT INITIAL.
      result = go_report->control_get( mv_id ).
    ENDIF.

  ENDMETHOD.

  METHOD put.

    IF go_report IS BOUND AND mv_id IS NOT INITIAL.
      go_report->control_set( control ).
    ENDIF.

  ENDMETHOD.

  METHOD id_of.

    IF control IS BOUND.
      result = control->mv_id.
    ENDIF.

  ENDMETHOD.

  METHOD flag.

    " as text: 'X' compared with the number 1 is no number
    DATA(lv_mode) = condense( CONV string( mode ) ).
    result = xsdbool( lv_mode = `1` OR lv_mode = `X` OR lv_mode = `x` ).

  ENDMETHOD.

ENDCLASS.
