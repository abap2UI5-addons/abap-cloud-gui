*&---------------------------------------------------------------------*
*& Report ZR2C_09_LOCALCLASS
*&---------------------------------------------------------------------*
*& A report with local classes: a calculator the report creates and an
*& interface it is typed with - both move to the class's local types
*&---------------------------------------------------------------------*
REPORT zr2c_09_localclass.

INTERFACE lif_rounding.
  METHODS round
    IMPORTING iv_value        TYPE decfloat34
    RETURNING VALUE(rv_value) TYPE decfloat34.
ENDINTERFACE.

CLASS lcl_calculator DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_rounding.
    METHODS constructor IMPORTING iv_decimals TYPE i.
    METHODS add
      IMPORTING iv_a          TYPE decfloat34
                iv_b          TYPE decfloat34
      RETURNING VALUE(rv_sum) TYPE decfloat34.
  PRIVATE SECTION.
    DATA mv_decimals TYPE i.
ENDCLASS.

CLASS lcl_calculator IMPLEMENTATION.
  METHOD constructor.
    mv_decimals = iv_decimals.
  ENDMETHOD.

  METHOD add.
    rv_sum = lif_rounding~round( iv_a + iv_b ).
  ENDMETHOD.

  METHOD lif_rounding~round.
    rv_value = round( val = iv_value dec = mv_decimals ).
  ENDMETHOD.
ENDCLASS.

DATA go_calc TYPE REF TO lif_rounding.

PARAMETERS: p_a   TYPE decfloat34 DEFAULT '1.005',
            p_b   TYPE decfloat34 DEFAULT '2.5',
            p_dec TYPE i DEFAULT 2.

START-OF-SELECTION.
  DATA(lo_calc) = NEW lcl_calculator( p_dec ).
  go_calc = lo_calc.
  WRITE: / 'Sum:', lo_calc->add( iv_a = p_a iv_b = p_b ).
  WRITE: / 'Rounded A:', go_calc->round( p_a ).
