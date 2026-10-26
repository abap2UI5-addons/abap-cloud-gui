CLASS z2ui5_cl_cgui_r2c_37 DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " types and constants of the report
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

    " selection screen
    DATA p_team TYPE c LENGTH 1.

  PROTECTED SECTION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cgui_r2c_37 IMPLEMENTATION.

  METHOD initialization.

    " the command field of the SAP GUI: transactions, /n, /o and OK codes
    set_command_field( ).

    set_title( `Team Roster` ).
    p_team = 'A'.

  ENDMETHOD.

  METHOD selection_screen.

    screen->parameter( val  = p_team
                       text = `Team` ).

  ENDMETHOD.

  METHOD start_of_selection.

    DATA(lt_member) = VALUE ty_t_member( ( name = `Mia`  team = 'A' goals = 7 )
                                         ( name = `Noah` team = 'B' goals = 2 )
                                         ( name = `Lea`  team = 'A' goals = 0 )
                                         ( name = `Finn` team = 'B' goals = 11 ) ).

    DATA(lt_team) = FILTER #( lt_member WHERE team = p_team ).
    DATA(lv_goals) = REDUCE i( INIT sum = 0 FOR m IN lt_team NEXT sum = sum + m-goals ).
    DATA(lt_names) = VALUE string_table( FOR m IN lt_member WHERE ( goals > 5 ) ( m-name ) ).

    list( )->new_line(
        )->write( |Team { p_team }: { lines( lt_team ) } members, { lv_goals } goals| ).
    list( )->uline( ).
    LOOP AT lt_team INTO DATA(ls_member).
      DATA(lv_rating) = COND string( WHEN ls_member-goals >= 10 THEN `star`
                                     WHEN ls_member-goals > 0 THEN `scorer`
                                     ELSE `defender` ).
      DATA(lv_team) = SWITCH string( ls_member-team WHEN 'A' THEN `Alpha` WHEN 'B' THEN `Beta` ELSE `?` ).
      DATA(ls_card) = CORRESPONDING ty_card( ls_member ).
      list( )->new_line(
          )->write( ls_card-name
          )->write( ls_card-goals
          )->write( lv_rating
          )->write( lv_team ).
    ENDLOOP.
    list( )->uline( ).
    list( )->new_line(
        )->write( 'More than five goals:'
        )->write( concat_lines_of( table = lt_names sep = `, ` ) ).

  ENDMETHOD.

ENDCLASS.
