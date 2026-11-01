*&---------------------------------------------------------------------*
*& Report ZR2C_33_STRINGS
*&---------------------------------------------------------------------*
*& A name split into its parts and rebuilt: SPLIT, CONCATENATE, the
*& string functions to_upper, reverse, condense, substring, strlen,
*& REPLACE and TRANSLATE - each result a line of the list
*&---------------------------------------------------------------------*
REPORT zr2c_33_strings.

PARAMETERS p_name TYPE string LOWER CASE DEFAULT 'ada   augusta  lovelace'.

START-OF-SELECTION.
  DATA lt_part TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
  DATA lv_initials TYPE string.

  DATA(lv_clean) = condense( p_name ).
  SPLIT lv_clean AT space INTO TABLE lt_part.

  WRITE: / 'Input:', p_name.
  WRITE: / 'Condensed:', lv_clean.
  WRITE: / 'Parts:', lines( lt_part ).
  ULINE.

  LOOP AT lt_part INTO DATA(lv_part).
    DATA(lv_word) = to_upper( substring( val = lv_part len = 1 ) ) && substring( val = lv_part off = 1 ).
    WRITE: / sy-tabix, lv_word, strlen( lv_part ).
    CONCATENATE lv_initials lv_word(1) '.' INTO lv_initials.
  ENDLOOP.
  ULINE.

  DATA(lv_upper) = to_upper( lv_clean ).
  DATA(lv_dashed) = lv_clean.
  REPLACE ALL OCCURRENCES OF ` ` IN lv_dashed WITH `-`.
  DATA(lv_vowels) = lv_clean.
  TRANSLATE lv_vowels USING 'aAeEiIoOuU'.

  WRITE: / 'Initials:', lv_initials.
  WRITE: / 'Upper case:', lv_upper.
  WRITE: / 'With dashes:', lv_dashed.
  WRITE: / 'Vowels raised:', lv_vowels.
  WRITE: / 'Reversed:', reverse( lv_clean ).
