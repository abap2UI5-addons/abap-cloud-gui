*&---------------------------------------------------------------------*
*& Report ZR2C_46_TREELIST
*&---------------------------------------------------------------------*
*& A tree list: the nodes with their levels, RS_TREE_CONSTRUCT and
*& RS_TREE_LIST_DISPLAY
*&---------------------------------------------------------------------*
REPORT zr2c_46_treelist.

DATA gt_node TYPE STANDARD TABLE OF snodetext.
DATA gs_node TYPE snodetext.

START-OF-SELECTION.
  PERFORM add USING 1 'Airlines' ''.
  PERFORM add USING 2 'LH' 'Lufthansa'.
  PERFORM add USING 3 '0400' 'Frankfurt - New York'.
  PERFORM add USING 3 '0402' 'Frankfurt - New York'.
  PERFORM add USING 2 'AA' 'American Airlines'.
  PERFORM add USING 3 '0017' 'New York - San Francisco'.

  CALL FUNCTION 'RS_TREE_CONSTRUCT'
    TABLES
      nodetab = gt_node.

  CALL FUNCTION 'RS_TREE_LIST_DISPLAY'
    EXPORTING
      callback_program = sy-repid.

FORM add USING iv_level TYPE i
               iv_name  TYPE c
               iv_text  TYPE c.
  CLEAR gs_node.
  gs_node-tlevel = iv_level.
  gs_node-name   = iv_name.
  gs_node-text   = iv_text.
  APPEND gs_node TO gt_node.
ENDFORM.
