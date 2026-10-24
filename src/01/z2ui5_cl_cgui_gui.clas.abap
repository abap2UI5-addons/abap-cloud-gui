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

    " cl_gui_control - the metric and the window styles of the classic
    " controls; the browser lays the controls out itself, they are taken
    " and have no effect
    CONSTANTS metric_default TYPE i VALUE 0.
    CONSTANTS metric_pixel   TYPE i VALUE 1.
    CONSTANTS metric_mm      TYPE i VALUE 2.
    CONSTANTS ws_tabstop      TYPE i VALUE 65536.
    CONSTANTS ws_maximizebox  TYPE i VALUE 65536.
    CONSTANTS ws_group        TYPE i VALUE 131072.
    CONSTANTS ws_minimizebox  TYPE i VALUE 131072.
    CONSTANTS ws_thickframe   TYPE i VALUE 262144.
    CONSTANTS ws_sysmenu      TYPE i VALUE 524288.
    CONSTANTS ws_dlgframe     TYPE i VALUE 4194304.
    CONSTANTS ws_border       TYPE i VALUE 8388608.
    CONSTANTS ws_caption      TYPE i VALUE 12582912.
    CONSTANTS ws_maximize     TYPE i VALUE 16777216.
    CONSTANTS ws_clipchildren TYPE i VALUE 33554432.
    CONSTANTS ws_clipsiblings TYPE i VALUE 67108864.
    CONSTANTS ws_visible      TYPE i VALUE 268435456.
    CONSTANTS ws_child        TYPE i VALUE 1073741824.

    TYPES:
      "! CNTL_SIMPLE_EVENT(S) - the events set_registered_events( ) of a
      "! control takes; ABAP Cloud has not the DDIC types
      BEGIN OF ty_s_simple_event,
        eventid    TYPE i,
        appl_event TYPE abap_bool,
      END OF ty_s_simple_event.
    TYPES ty_t_simple_events TYPE STANDARD TABLE OF ty_s_simple_event WITH DEFAULT KEY.

    "! cl_gui_cfw=>compute_metric_from_dynp( ) - a size in characters of the
    "! screen in pixels or mm; the browser lays the controls out itself,
    "! the size is the one given
    CLASS-METHODS compute_metric_from_dynp
      IMPORTING
        metric TYPE i
        x_or_y TYPE c
        in     TYPE i
      RETURNING
        VALUE(out) TYPE i.

    "! the report the controls belong to - z2ui5_cl_cgui_report sets it at
    "! the start of every roundtrip
    CLASS-METHODS set_report
      IMPORTING
        report TYPE REF TO z2ui5_if_cgui_gui.

    "! the report of the roundtrip - for the stand-ins that are no control
    "! (z2ui5_cl_cgui_demo_output)
    CLASS-METHODS get_report
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_if_cgui_gui.

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

    "! SET HANDLER handler->method FOR control - the handler of event: an
    "! object, or the class of a static method (class); kept with the
    "! control, so it is there on the next roundtrip (a SET HANDLER is not)
    METHODS set_handler
      IMPORTING
        event      TYPE clike
        method     TYPE clike
        handler    TYPE REF TO object OPTIONAL
        class      TYPE clike         OPTIONAL
        activation TYPE abap_bool     DEFAULT abap_true.

    "! an event of the browser for this control - the report passes it on;
    "! value is what the browser sent with it (a function code, an action)
    METHODS dispatch
      IMPORTING
        event TYPE string
        value TYPE string OPTIONAL.

  PROTECTED SECTION.
    CLASS-DATA go_report TYPE REF TO z2ui5_if_cgui_gui.

    DATA mv_id TYPE i.

    "! RAISE EVENT event - the handlers set for it, each with the
    "! parameters its method has of params, and sender
    METHODS raise_event
      IMPORTING
        event  TYPE string
        params TYPE abap_parmbind_tab OPTIONAL.

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

  METHOD compute_metric_from_dynp.

    out = in.

  ENDMETHOD.

  METHOD set_report.

    go_report = report.

  ENDMETHOD.

  METHOD get_report.

    result = go_report.

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

  METHOD set_handler.

    DATA(lv_event) = to_upper( condense( event ) ).
    DATA(lv_method) = to_upper( condense( method ) ).
    DATA(lv_class) = to_upper( condense( class ) ).
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lt_handler) = go_report->handlers_get( ).
    DELETE lt_handler WHERE id = mv_id AND event = lv_event AND method = lv_method AND handler = handler AND class = lv_class.
    IF activation = abap_true.
      INSERT VALUE #( id      = mv_id
                      event   = lv_event
                      handler = handler
                      class   = lv_class
                      method  = lv_method ) INTO TABLE lt_handler.
    ENDIF.
    go_report->handlers_set( lt_handler ).

  ENDMETHOD.

  METHOD dispatch.

    raise_event( to_upper( event ) ).

  ENDMETHOD.

  METHOD raise_event.

    DATA lt_param TYPE abap_parmbind_tab.
    DATA lr_sender TYPE REF TO data.
    FIELD-SYMBOLS <sender> TYPE any.

    " sender typed as the class of the control - the handler's parameter is
    " typed with the class of the event (the stand-in or a parent of it)
    DATA(lv_class) = cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ).
    CREATE DATA lr_sender TYPE REF TO (lv_class).
    ASSIGN lr_sender->* TO <sender>.
    <sender> ?= me.
    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lt_handler) = go_report->handlers_get( ).
    LOOP AT lt_handler INTO DATA(ls_handler) WHERE id = mv_id AND event = event.
      " the parameters the handler method takes - an event handler names a
      " part of the event's parameters
      DATA(lo_type) = COND #( WHEN ls_handler-handler IS BOUND
                              THEN CAST cl_abap_objectdescr( cl_abap_typedescr=>describe_by_object_ref( ls_handler-handler ) )
                              ELSE CAST cl_abap_objectdescr( cl_abap_typedescr=>describe_by_name( ls_handler-class ) ) ).
      READ TABLE lo_type->methods INTO DATA(ls_method) WITH KEY name = ls_handler-method.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      CLEAR lt_param.
      LOOP AT ls_method-parameters INTO DATA(ls_parameter).
        IF ls_parameter-name = `SENDER`.
          INSERT VALUE #( name  = `SENDER`
                          kind  = cl_abap_objectdescr=>exporting
                          value = lr_sender ) INTO TABLE lt_param.
          CONTINUE.
        ENDIF.
        READ TABLE params INTO DATA(ls_param) WITH TABLE KEY name = ls_parameter-name.
        IF sy-subrc = 0.
          INSERT ls_param INTO TABLE lt_param.
        ENDIF.
      ENDLOOP.
      IF ls_handler-handler IS BOUND.
        CALL METHOD ls_handler-handler->(ls_handler-method)
          PARAMETER-TABLE lt_param.
      ELSE.
        CALL METHOD (ls_handler-class)=>(ls_handler-method)
          PARAMETER-TABLE lt_param.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD add.

    IF go_report IS NOT BOUND.
      RETURN.
    ENDIF.
    mv_id = go_report->control_add( control = control
                                    object  = me ).
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
