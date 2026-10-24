*&---------------------------------------------------------------------*
*& Report ZR2C_35_DATES
*&---------------------------------------------------------------------*
*& Dates of a project: the days between two dates, the end after a
*& number of working days without weekends, the first and last day of
*& the month and the week day of each - date arithmetic only
*&---------------------------------------------------------------------*
REPORT zr2c_35_dates.

PARAMETERS: p_start TYPE d DEFAULT '20260105',
            p_end   TYPE d DEFAULT '20260320',
            p_days  TYPE i DEFAULT 10.

START-OF-SELECTION.
  " 1970-01-05 was a Monday: the day number since then MOD 7 is the week day
  CONSTANTS lc_monday TYPE d VALUE '19700105'.
  DATA lt_weekday TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
  lt_weekday = VALUE #( ( `Monday` ) ( `Tuesday` ) ( `Wednesday` ) ( `Thursday` )
                        ( `Friday` ) ( `Saturday` ) ( `Sunday` ) ).

  IF p_end < p_start.
    MESSAGE 'The end is before the start' TYPE 'E'.
  ENDIF.

  DATA lv_between TYPE i.
  lv_between = p_end - p_start.
  WRITE: / 'Days between start and end:', lv_between.

  DATA(lv_day) = p_start.
  DATA(lv_left) = p_days.
  WHILE lv_left > 0.
    lv_day = lv_day + 1.
    IF ( lv_day - lc_monday ) MOD 7 < 5.
      lv_left = lv_left - 1.
    ENDIF.
  ENDWHILE.
  WRITE: / |After { p_days } working days:|, lv_day.

  " a date plus days is a number (the calculation type is i) - typed as a
  " date, the result is the date again
  DATA lv_next TYPE d.
  DATA lv_last TYPE d.
  DATA(lv_first) = p_start.
  lv_first+6(2) = '01'.
  lv_next = lv_first + 31.
  lv_next+6(2) = '01'.
  lv_last = lv_next - 1.
  ULINE.
  WRITE: / 'First of the month:', lv_first, lt_weekday[ ( lv_first - lc_monday ) MOD 7 + 1 ].
  WRITE: / 'Last of the month:', lv_last, lt_weekday[ ( lv_last - lc_monday ) MOD 7 + 1 ].
  WRITE: / 'Start:', p_start, lt_weekday[ ( p_start - lc_monday ) MOD 7 + 1 ].
