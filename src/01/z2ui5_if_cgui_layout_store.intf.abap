"! The store of the ALV layouts of a report - the classic "Save Layout".
"! The report runtime keeps them in table Z2UI5_CGUI_LAY by default
"! (z2ui5_cl_cgui_layout_db): a layout belongs to the user who saved it
"! first, shared every user sees it, protected only its owner changes or
"! deletes it, and every user has a default layout of his own. A store of
"! your own implements this interface and is set in initialization( ) with
"! set_layout_store( ); without a store the layouts are kept with the
"! selection variants. The store travels in the draft of the app - it must
"! be serializable.
INTERFACE z2ui5_if_cgui_layout_store PUBLIC.

  INTERFACES if_serializable_object.

  "! the layouts of the ALV handle of report the current user sees - his
  "! own ones first, then the shared ones of the other users
  METHODS load
    IMPORTING
      report        TYPE clike
      handle        TYPE clike
    RETURNING
      VALUE(result) TYPE z2ui5_cl_cgui_layout=>ty_t_saved.

  "! save layout - refused when another user owns it and protected it or
  "! kept it private. A default layout takes the flag from the other
  "! layouts of the user
  METHODS save
    IMPORTING
      report TYPE clike
      handle TYPE clike
      layout TYPE z2ui5_cl_cgui_layout=>ty_s_saved
    RAISING
      z2ui5_cx_cgui_error.

  "! delete the layout name - refused when another user owns it and
  "! protected it
  METHODS delete
    IMPORTING
      report TYPE clike
      handle TYPE clike
      name   TYPE clike
    RAISING
      z2ui5_cx_cgui_error.

  "! does the store keep shared and protected layouts
  METHODS check_sharing
    RETURNING
      VALUE(result) TYPE abap_bool.

ENDINTERFACE.
