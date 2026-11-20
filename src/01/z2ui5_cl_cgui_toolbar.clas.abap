"! The stand-in of cl_gui_toolbar - the buttons of a toolbar in its
"! container. A button pressed raises function_selected with its function
"! code; a dropdown or a menu button raises dropdown_clicked. The buttons
"! are a line of the report's controls, so they are there on the next
"! roundtrip
CLASS z2ui5_cl_cgui_toolbar DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_gui
  CREATE PUBLIC.

  PUBLIC SECTION.
    " cntb_btype_* of type pool CNTB
    CONSTANTS cntb_btype_button   TYPE i VALUE 0.
    CONSTANTS cntb_btype_dropdown TYPE i VALUE 1.
    CONSTANTS cntb_btype_menu     TYPE i VALUE 2.
    CONSTANTS cntb_btype_sep      TYPE i VALUE 3.
    CONSTANTS cntb_btype_group    TYPE i VALUE 4.
    CONSTANTS cntb_btype_check    TYPE i VALUE 5.
    " the display_mode of the constructor - a toolbar of the browser is
    " horizontal
    CONSTANTS m_mode_horizontal TYPE i VALUE 0.
    CONSTANTS m_mode_vertical   TYPE i VALUE 1.
    CONSTANTS m_id_function_selected TYPE i VALUE 1.
    CONSTANTS m_id_dropdown_clicked  TYPE i VALUE 2.

    EVENTS function_selected
      EXPORTING
        VALUE(fcode) TYPE c OPTIONAL.

    EVENTS dropdown_clicked
      EXPORTING
        VALUE(fcode) TYPE c OPTIONAL
        VALUE(posx)  TYPE i OPTIONAL
        VALUE(posy)  TYPE i OPTIONAL.

    METHODS constructor
      IMPORTING
        parent       TYPE REF TO z2ui5_cl_cgui_container
        shellstyle   TYPE i     OPTIONAL
        lifetime     TYPE i     OPTIONAL
        display_mode TYPE i     OPTIONAL
        align_right  TYPE i     OPTIONAL
        name         TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_install_error
        cntl_error
        cntb_wrong_version.

    METHODS add_button
      IMPORTING
        fcode       TYPE clike
        icon        TYPE clike
        is_disabled TYPE clike OPTIONAL
        butn_type   TYPE i     OPTIONAL
        text        TYPE clike OPTIONAL
        quickinfo   TYPE clike OPTIONAL
        is_checked  TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntb_btype_error
        cntb_error_fcode.

    "! the buttons of a table of stb_button - function, icon, butn_type,
    "! text, quickinfo, disabled, checked
    METHODS add_button_group
      IMPORTING
        data_table TYPE STANDARD TABLE
      EXCEPTIONS
        dp_error
        cntb_error_fcode.

    METHODS set_button_state
      IMPORTING
        enabled TYPE clike DEFAULT abap_true
        checked TYPE clike DEFAULT abap_false
        fcode   TYPE clike
      EXCEPTIONS
        cntl_error
        cntb_error_fcode.

    METHODS set_button_info
      IMPORTING
        fcode     TYPE clike
        icon      TYPE clike OPTIONAL
        text      TYPE clike OPTIONAL
        quickinfo TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntb_error_fcode.

    METHODS delete_button
      IMPORTING
        fcode TYPE clike
      EXCEPTIONS
        cntl_error
        cntb_error_fcode.

    METHODS delete_all_buttons
      EXCEPTIONS
        cntl_error.

    METHODS set_registered_events
      IMPORTING
        events TYPE STANDARD TABLE
      EXCEPTIONS
        cntl_error
        cntl_system_error
        illegal_event_combination.

    METHODS dispatch REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! a component of a row of a table of buttons, as text
    METHODS component
      IMPORTING
        row           TYPE any
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.


CLASS z2ui5_cl_cgui_toolbar IMPLEMENTATION.

  METHOD constructor.
    DATA temp1 TYPE z2ui5_if_cgui_gui=>ty_s_control.

    super->constructor( ).

    CLEAR temp1.
    temp1-kind = z2ui5_if_cgui_gui=>cs_kind-toolbar.
    temp1-parent = id_of( parent ).
    IF add( temp1 ) = abap_false.
      RAISE cntl_error.
    ENDIF.

  ENDMETHOD.

  METHOD add_button.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA temp2 TYPE z2ui5_if_cgui_gui=>ty_s_button.
    ls_control = get( ).

    CLEAR temp2.
    temp2-fcode = to_upper( condense( fcode ) ).
    temp2-icon = condense( icon ).
    temp2-text = text.
    temp2-quickinfo = quickinfo.
    temp2-type = butn_type.
    temp2-disabled = flag( is_disabled ).
    temp2-checked = flag( is_checked ).
    INSERT temp2 INTO TABLE ls_control-buttons.
    put( ls_control ).

  ENDMETHOD.

  METHOD add_button_group.

    FIELD-SYMBOLS <row> TYPE ANY.
      DATA lv_type TYPE string.
      DATA temp3 TYPE i.
      DATA temp1 TYPE i.
    LOOP AT data_table ASSIGNING <row>.

      lv_type = component( row  = <row>
                                 name = `BUTN_TYPE` ).

      temp3 = condense( lv_type ).

      IF lv_type CO ` 0123456789`.
        temp1 = temp3.
      ELSE.
        CLEAR temp1.
      ENDIF.
      add_button( fcode       = component( row = <row> name = `FUNCTION` )
                  icon        = component( row = <row> name = `ICON` )
                  butn_type   = temp1
                  text        = component( row = <row> name = `TEXT` )
                  quickinfo   = component( row = <row> name = `QUICKINFO` )
                  is_disabled = component( row = <row> name = `DISABLED` )
                  is_checked  = component( row = <row> name = `CHECKED` ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD set_button_state.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA lv_fcode TYPE string.
    FIELD-SYMBOLS <button> LIKE LINE OF ls_control-buttons.
      DATA temp1 TYPE xsdboolean.
    ls_control = get( ).

    lv_fcode = to_upper( condense( fcode ) ).

    LOOP AT ls_control-buttons ASSIGNING <button> WHERE fcode = lv_fcode.

      temp1 = boolc( flag( enabled ) = abap_false ).
      <button>-disabled = temp1.
      <button>-checked = flag( checked ).
    ENDLOOP.
    put( ls_control ).

  ENDMETHOD.

  METHOD set_button_info.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA lv_fcode TYPE string.
    FIELD-SYMBOLS <button> LIKE LINE OF ls_control-buttons.
    ls_control = get( ).

    lv_fcode = to_upper( condense( fcode ) ).

    LOOP AT ls_control-buttons ASSIGNING <button> WHERE fcode = lv_fcode.
      IF icon IS SUPPLIED.
        <button>-icon = icon.
      ENDIF.
      IF text IS SUPPLIED.
        <button>-text = text.
      ENDIF.
      IF quickinfo IS SUPPLIED.
        <button>-quickinfo = quickinfo.
      ENDIF.
    ENDLOOP.
    put( ls_control ).

  ENDMETHOD.

  METHOD delete_button.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    DATA lv_fcode TYPE string.
    ls_control = get( ).

    lv_fcode = to_upper( condense( fcode ) ).
    DELETE ls_control-buttons WHERE fcode = lv_fcode.
    put( ls_control ).

  ENDMETHOD.

  METHOD delete_all_buttons.

    DATA ls_control TYPE z2ui5_if_cgui_gui=>ty_s_control.
    ls_control = get( ).
    CLEAR ls_control-buttons.
    put( ls_control ).

  ENDMETHOD.

  METHOD set_registered_events ##NEEDED.
  ENDMETHOD.

  METHOD dispatch.

    DATA lv_fcode TYPE c LENGTH 70.
    DATA lv_event TYPE string.
        DATA temp4 LIKE REF TO lv_fcode.
DATA temp2 TYPE abap_parmbind_tab.
DATA temp3 LIKE LINE OF temp2.

    lv_fcode = value.

    lv_event = to_upper( event ).
    CASE lv_event.
      WHEN `FUNCTION_SELECTED` OR `DROPDOWN_CLICKED`.

        GET REFERENCE OF lv_fcode INTO temp4.

CLEAR temp2.

temp3-name = `FCODE`.
temp3-kind = cl_abap_objectdescr=>exporting.
temp3-value = temp4.
INSERT temp3 INTO TABLE temp2.
raise_event( event  = lv_event
                     params = temp2 ).
      WHEN OTHERS.
        super->dispatch( event = event
                         value = value ).
    ENDCASE.

  ENDMETHOD.

  METHOD component.

    FIELD-SYMBOLS <value> TYPE any.
      DATA temp5 TYPE string.
    ASSIGN COMPONENT name OF STRUCTURE row TO <value>.
    IF sy-subrc = 0.

      temp5 = <value>.
      result = condense( temp5 ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
