*&---------------------------------------------------------------------*
*& Report ZR2C_37_EXPRESSIONS
*&---------------------------------------------------------------------*
*& The constructor expressions of a team roster: VALUE with FOR and
*& WHERE, REDUCE for a total, COND and SWITCH for a rating, FILTER on a
*& sorted key, CORRESPONDING into another structure - written as a list
*&---------------------------------------------------------------------*
REPORT zr2c_37_expressions.

TYPES:
  BEGIN OF ty_member,
    name  TYPE string,
    team  TYPE c LENGTH 1,
    goals TYPE i,
  END OF ty_member.
TYPES ty_t_member TYPE SORTED TABLE OF ty_member WITH NON-UNIQUE KEY team.
TYPES:
  BEGIN OF ty_card,
    name  TYPE string,
    goals TYPE i,
  END OF ty_card.

PARAMETERS p_team TYPE c LENGTH 1 DEFAULT 'A'.

START-OF-SELECTION.
  DATA(lt_member) = VALUE ty_t_member( ( name = `Mia`  team = 'A' goals = 7 )
                                       ( name = `Noah` team = 'B' goals = 2 )
                                       ( name = `Lea`  team = 'A' goals = 0 )
                                       ( name = `Finn` team = 'B' goals = 11 ) ).

  DATA(lt_team) = FILTER #( lt_member WHERE team = p_team ).
  DATA(lv_goals) = REDUCE i( INIT sum = 0 FOR m IN lt_team NEXT sum = sum + m-goals ).
  DATA(lt_names) = VALUE string_table( FOR m IN lt_member WHERE ( goals > 5 ) ( m-name ) ).

  WRITE: / |Team { p_team }: { lines( lt_team ) } members, { lv_goals } goals|.
  ULINE.
  LOOP AT lt_team INTO DATA(ls_member).
    DATA(lv_rating) = COND string( WHEN ls_member-goals >= 10 THEN `star`
                                   WHEN ls_member-goals > 0 THEN `scorer`
                                   ELSE `defender` ).
    DATA(lv_team) = SWITCH string( ls_member-team WHEN 'A' THEN `Alpha` WHEN 'B' THEN `Beta` ELSE `?` ).
    DATA(ls_card) = CORRESPONDING ty_card( ls_member ).
    WRITE: / ls_card-name, ls_card-goals, lv_rating, lv_team.
  ENDLOOP.
  ULINE.
  WRITE: / 'More than five goals:', concat_lines_of( table = lt_names sep = `, ` ).
