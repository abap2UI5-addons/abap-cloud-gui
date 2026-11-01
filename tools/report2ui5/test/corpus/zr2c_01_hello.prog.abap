*&---------------------------------------------------------------------*
*& Report ZR2C_01_HELLO
*&---------------------------------------------------------------------*
*& The smallest report: two parameters and a list
*&---------------------------------------------------------------------*
REPORT zr2c_01_hello.

PARAMETERS: p_name  TYPE string LOWER CASE OBLIGATORY,
            p_times TYPE i DEFAULT 3.

START-OF-SELECTION.
  WRITE: / 'Hello', p_name.
  ULINE.
  DO p_times TIMES.
    WRITE: / 'Line', sy-index.
  ENDDO.
  SKIP.
  WRITE / 'Done.'.
