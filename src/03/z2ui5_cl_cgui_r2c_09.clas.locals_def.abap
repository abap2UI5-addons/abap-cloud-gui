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
