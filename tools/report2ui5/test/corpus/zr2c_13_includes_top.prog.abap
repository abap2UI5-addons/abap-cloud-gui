*&---------------------------------------------------------------------*
*& Include ZR2C_13_INCLUDES_TOP
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_line,
         text TYPE c LENGTH 20,
         qty  TYPE i,
       END OF ty_line.

DATA: gt_lines TYPE STANDARD TABLE OF ty_line,
      gs_line  TYPE ty_line,
      gv_total TYPE i.

PARAMETERS p_count TYPE i DEFAULT 3.

* a macro of the TOP include - the parser expands it at every call
DEFINE add_and_write.
  gv_total = gv_total + &1.
  WRITE: / &2, &1.
END-OF-DEFINITION.
