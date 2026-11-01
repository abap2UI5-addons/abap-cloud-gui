*&---------------------------------------------------------------------*
*& Report ZR2C_08_LISTFORMAT
*&---------------------------------------------------------------------*
*& The list statements: FORMAT, COLOR, HOTSPOT, AS CHECKBOX, AS ICON,
*& positions and lengths, NEW-PAGE, SKIP, NEW-LINE
*&---------------------------------------------------------------------*
REPORT zr2c_08_listformat NO STANDARD PAGE HEADING LINE-SIZE 80.

TYPES: BEGIN OF ty_task,
         id    TYPE i,
         title TYPE c LENGTH 30,
         done  TYPE abap_bool,
         due   TYPE d,
       END OF ty_task.

DATA: gt_task TYPE STANDARD TABLE OF ty_task WITH DEFAULT KEY,
      gs_task TYPE ty_task,
      gv_open TYPE i.

PARAMETERS p_pages AS CHECKBOX DEFAULT 'X'.

START-OF-SELECTION.
  gt_task = VALUE #( ( id = 1 title = 'Write the report'   done = abap_true  due = '20260110' )
                     ( id = 2 title = 'Convert the report' done = abap_false due = '20260120' )
                     ( id = 3 title = 'Test the class'     done = abap_false due = '20260130' ) ).

  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: /1 'Tasks', 40 sy-datum DD/MM/YYYY.
  FORMAT RESET.
  ULINE AT /1(60).

  LOOP AT gt_task INTO gs_task.
    NEW-LINE.
    WRITE gs_task-done AS CHECKBOX.
    IF gs_task-done = abap_true.
      WRITE icon_okay AS ICON.
      FORMAT COLOR COL_POSITIVE.
    ELSE.
      WRITE icon_red_light AS ICON.
      FORMAT COLOR COL_NEGATIVE.
      gv_open = gv_open + 1.
    ENDIF.
    WRITE: 5(4) gs_task-id NO-GAP,
           12 gs_task-title HOTSPOT ON,
           45 gs_task-due.
    FORMAT COLOR OFF.
    HIDE gs_task-id.
  ENDLOOP.

  SKIP 2.
  FORMAT HOTSPOT OFF.
  WRITE: / 'Open tasks:', gv_open COLOR 3.

  IF p_pages = abap_true.
    NEW-PAGE.
    WRITE / 'Second page'.
  ENDIF.

AT LINE-SELECTION.
  READ TABLE gt_task INTO gs_task WITH KEY id = gs_task-id.
  IF sy-subrc = 0.
    MESSAGE |Task { gs_task-id }: { gs_task-title }| TYPE 'I'.
  ENDIF.
