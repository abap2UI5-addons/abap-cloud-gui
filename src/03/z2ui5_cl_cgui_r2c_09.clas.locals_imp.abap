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
