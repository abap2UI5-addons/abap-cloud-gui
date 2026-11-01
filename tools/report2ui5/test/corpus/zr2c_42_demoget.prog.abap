*&---------------------------------------------------------------------*
*& Report ZR2C_42_DEMOGET
*&---------------------------------------------------------------------*
*& The shelves of a cellar as a page of their own: cl_demo_output
*& collects them, get( ) hands them over as HTML instead of showing them,
*& and cl_abap_browser shows the page - the list keeps the total only
*&---------------------------------------------------------------------*
REPORT zr2c_42_demoget.

TYPES:
  BEGIN OF ty_shelf,
    wine    TYPE c LENGTH 12,
    vintage TYPE n LENGTH 4,
    bottles TYPE i,
  END OF ty_shelf.
TYPES ty_t_shelf TYPE STANDARD TABLE OF ty_shelf WITH DEFAULT KEY.

PARAMETERS p_min TYPE i DEFAULT 6.

START-OF-SELECTION.
  DATA(lt_shelf) = VALUE ty_t_shelf( ( wine = 'Riesling' vintage = '2019' bottles = 12 )
                                     ( wine = 'Merlot'   vintage = '2016' bottles = 4 )
                                     ( wine = 'Rose'     vintage = '2021' bottles = 9 ) ).
  DATA lv_total TYPE i.
  LOOP AT lt_shelf INTO DATA(ls_shelf).
    lv_total = lv_total + ls_shelf-bottles.
  ENDLOOP.
  DELETE lt_shelf WHERE bottles < p_min.

  cl_demo_output=>begin_section( 'Cellar' ).
  cl_demo_output=>write( lt_shelf ).
  DATA(lv_page) = cl_demo_output=>get( ).
  cl_abap_browser=>show_html( title       = 'Cellar'
                              html_string = lv_page ).

  WRITE: / |{ lv_total } bottles in the cellar|.
