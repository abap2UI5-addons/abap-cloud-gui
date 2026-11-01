" the types and constants of the report the local classes are typed with
TYPES:
  BEGIN OF ty_s_flight,
    carrid   TYPE sflight-carrid,
    connid   TYPE sflight-connid,
    seatsocc TYPE sflight-seatsocc,
  END OF ty_s_flight,
  ty_t_flight TYPE STANDARD TABLE OF ty_s_flight WITH DEFAULT KEY.

CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    METHODS constructor IMPORTING iv_title TYPE string.
    METHODS run.
  PRIVATE SECTION.
    DATA mv_title TYPE string.
    DATA mt_flight TYPE ty_t_flight.
    METHODS read.
    METHODS show.
ENDCLASS.
