CLASS z2ui5_cl_cgui_r2c_08 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
    TYPES:
      BEGIN OF ty_task,
        id    TYPE i,
        title TYPE c LENGTH 30,
        done  TYPE abap_bool,
        due   TYPE d,
      END OF ty_task.

    " global data of the report
    DATA:
      gt_task TYPE STANDARD TABLE OF ty_task WITH DEFAULT KEY,
      gs_task TYPE ty_task,
      gv_open TYPE i.

    " selection screen
    DATA p_pages TYPE abap_bool.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_08 IMPLEMENTATION.

  METHOD initialization.

    p_pages = abap_true.

  ENDMETHOD.

  METHOD selection_screen.

    screen->checkbox( p_pages ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA lv_color TYPE string.

    " every run starts with the global data of a fresh start - the classic report restarted after its list
    CLEAR: gt_task,
           gs_task,
           gv_open.

    gt_task = VALUE #( ( id = 1 title = 'Write the report'   done = abap_true  due = '20260110' )
                       ( id = 2 title = 'Convert the report' done = abap_false due = '20260120' )
                       ( id = 3 title = 'Test the class'     done = abap_false due = '20260130' ) ).

    lv_color = z2ui5_cl_cgui_list=>cs_color-key.
    list( )->new_line(
        )->write( val   = 'Tasks'
                  pos   = 1
                  color = lv_color
        )->write( val   = sy-datum
                  pos   = 40
                  color = lv_color ).
    CLEAR lv_color.
    list( )->uline( ).

    LOOP AT gt_task INTO gs_task.
      list( )->new_line( ).
      list( )->write_as_checkbox( gs_task-done ).
      IF gs_task-done = abap_true.
        list( )->write_as_icon( `sap-icon://accept` ).
        lv_color = z2ui5_cl_cgui_list=>cs_color-positive.
      ELSE.
        list( )->write_as_icon( `sap-icon://status-negative` ).
        lv_color = z2ui5_cl_cgui_list=>cs_color-negative.
        gv_open = gv_open + 1.
      ENDIF.
      write( val    = gs_task-id
             pos    = 5
             len    = 4
             no_gap = abap_true
             color  = lv_color
          )->write( val     = gs_task-title
                    pos     = 12
                    color   = lv_color
                    hotspot = abap_true
                    hide    = gs_task-id
          )->write( val   = gs_task-due
                    pos   = 45
                    color = lv_color ).
      CLEAR lv_color.
    ENDLOOP.

    list( )->skip( 2 ).
    list( )->new_line(
        )->write( val   = 'Open tasks:'
                  color = lv_color
        )->write( val   = gv_open
                  color = z2ui5_cl_cgui_list=>cs_color-total ).

    IF p_pages = abap_true.
      list( )->new_page( ).
      list( )->new_line(
          )->write( val   = 'Second page'
                    color = lv_color ).
    ENDIF.

  ENDMETHOD.

  METHOD at_line_selection.

    " HIDE - the field the clicked line was written with
    gs_task-id = hide.

    READ TABLE gt_task INTO gs_task WITH KEY id = gs_task-id.
    IF sy-subrc = 0.
      message( text = |Task { gs_task-id }: { gs_task-title }|
               type = `I` ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
