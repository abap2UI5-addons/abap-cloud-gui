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

    DATA temp1 TYPE ty_t_member.
    DATA temp2 LIKE LINE OF temp1.
    DATA lt_member LIKE temp1.
    DATA temp3 TYPE z2ui5_cl_cgui_r2c_37=>ty_t_member.
    DATA temp4 LIKE LINE OF lt_member.
    DATA lt_team LIKE temp3.
    DATA temp5 TYPE i.
    DATA sum TYPE i.
    DATA temp6 LIKE LINE OF lt_team.
    DATA lv_goals LIKE temp5.
    DATA temp7 TYPE string_table.
    DATA m LIKE LINE OF lt_member.
    DATA lt_names LIKE temp7.
    DATA ls_member LIKE LINE OF lt_team.
      DATA temp9 TYPE string.
      DATA lv_rating LIKE temp9.
      DATA temp10 TYPE string.
      DATA lv_team LIKE temp10.
      DATA temp11 TYPE ty_card.
      DATA ls_card LIKE temp11.
    CLEAR temp1.

    temp2-name = `Mia`.
    temp2-team = 'A'.
    temp2-goals = 7.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `Noah`.
    temp2-team = 'B'.
    temp2-goals = 2.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `Lea`.
    temp2-team = 'A'.
    temp2-goals = 0.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `Finn`.
    temp2-team = 'B'.
    temp2-goals = 11.
    INSERT temp2 INTO TABLE temp1.

    lt_member = temp1.



    LOOP AT lt_member INTO temp4 WHERE team = p_team.
      INSERT temp4 INTO TABLE temp3.
    ENDLOOP.

    lt_team = temp3.


    sum = 0.

    LOOP AT lt_team INTO temp6.
      sum = sum + temp6-goals.
    ENDLOOP.
    temp5 = sum.

    lv_goals = temp5.

    CLEAR temp7.

    LOOP AT lt_member INTO m WHERE goals > 5.
      INSERT m-name INTO TABLE temp7.
    ENDLOOP.

    lt_names = temp7.

    list( )->new_line(
        )->write( |Team { p_team }: { lines( lt_team ) } members, { lv_goals } goals| ).
    list( )->uline( ).

    LOOP AT lt_team INTO ls_member.

      IF ls_member-goals >= 10.
        temp9 = `star`.
      ELSEIF ls_member-goals > 0.
        temp9 = `scorer`.
      ELSE.
        temp9 = `defender`.
      ENDIF.

      lv_rating = temp9.

      CASE ls_member-team.
        WHEN 'A'.
          temp10 = `Alpha`.
        WHEN 'B'.
          temp10 = `Beta`.
        WHEN OTHERS.
          temp10 = `?`.
      ENDCASE.

      lv_team = temp10.

      CLEAR temp11.
      MOVE-CORRESPONDING ls_member TO temp11.

      ls_card = temp11.
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
