"! Execute in Background - the job of a report, scheduled by the
"! installation: an application job on ABAP Cloud, a background job on
"! premise. The report hands over its class and the values of the
"! selection screen; the job creates the class and runs it with
"! cgui_run_in_background( ), which returns the list and its PDF.
"! The object is kept with the report between the roundtrips - it
"! implements if_serializable_object, or keeps nothing but its settings
INTERFACE z2ui5_if_cgui_job PUBLIC.

  "! job: the name or number of the job, the user is told - error: why
  "! the job was not scheduled
  METHODS schedule
    IMPORTING
      report TYPE string
      title  TYPE string
      values TYPE z2ui5_cl_cgui_variant=>ty_t_value
    EXPORTING
      job    TYPE string
      error  TYPE string.

ENDINTERFACE.
