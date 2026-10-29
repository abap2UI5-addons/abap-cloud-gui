# Changelog

A release is a tag `vX.Y.Z` on `main` (RELEASING.md). Each one has a section
here; `.github/workflows/release.yaml` takes it as the text of the GitHub
release.

## Unreleased

## 1.0.0 - unreleased

The first release: the report runtime, report2cloud and the tools around
them. Install it with abapGit - the repository at the tag, or the zip of the
GitHub release (`abap-cloud-gui-1.0.0.zip`, and `abap-cloud-gui-1.0.0-702.zip`
downported for NetWeaver 7.02). It needs abap2UI5 and nothing else.

From 1.0.0 on the public API of the classes in `src/01` follows semantic
versioning: a method, parameter, attribute, constant or type removed,
renamed or retyped is a major release; something added is a minor one;
a fix a patch. The views it renders and the texts it shows are not part of
it.

**The report runtime** (`z2ui5_cl_cgui_report` and its classes)

- The event blocks as methods: `INITIALIZATION`, `AT SELECTION-SCREEN`
  with `OUTPUT`, `ON field`, `ON BLOCK`, `ON RADIOBUTTON GROUP`,
  `ON VALUE-REQUEST` and `ON HELP-REQUEST`, `START-OF-SELECTION`,
  `END-OF-SELECTION`, `AT LINE-SELECTION`, `AT USER-COMMAND`, `AT PFnn`.
- The selection screen: `PARAMETERS`, `SELECT-OPTIONS` with the multiple
  selection, blocks, lines, comments, push buttons, checkboxes, radio
  buttons, listboxes, tabbed blocks, `LOOP AT SCREEN`, `MEMORY ID`, the
  screens of `BEGIN OF SCREEN` as a window or a subscreen; a phone layout.
- Value helps: fixed values, value and text tables, search helps,
  `MATCHCODE OBJECT`, CDS value helps (`value_help_entity`), F4 inside the
  range popup.
- Selection variants on the server (`Z2UI5_CGUI_VAR`) or in the browser,
  shared and protected, dynamic dates; the last entries; a draft of a
  selection screen left without executing (`set_draft( )`).
- Parameters on three levels: the user's (`SU3`), the installation's
  customizing (`SPRO`) and the system's (`set_system_parameters( )`).
- The list: `WRITE` with positions, `UNDER`, colours, hotspots, `HIDE`,
  checkboxes and icons, `ULINE`, `NEW-PAGE`, secondary lists, `READ LINE` /
  `MODIFY LINE`; print as PDF, execute in background.
- The ALV (`CL_SALV_TABLE`): columns from RTTI and the DDIC, sort, filter,
  totals and subtotals, layouts on the server (`Z2UI5_CGUI_LAY`), Excel
  export, editable cells, a toolbar of the report's own, a chart; the ALV
  tree (`CL_SALV_TREE`) and the tree lists of `RS_TREE_LIST_DISPLAY`.
- Messages in a status bar and a popover, the application log as their
  source, the popups of `POPUP_TO_CONFIRM`, `POPUP_TO_DECIDE`,
  `POPUP_GET_VALUES` and the transport request.
- `SUBMIT` with its values, a variant, another selection screen or as a
  window; `CALL SELECTION-SCREEN`; `CALL TRANSACTION` through a catalog of
  the installation; the command field and the command palette.
- Dynpros of fields: `CALL SCREEN` (of another class too), PBO and PAI,
  `SET SCREEN`, tabstrips, subscreens, table controls.
- Stand-ins of the SAP GUI controls (`z2ui5_cl_cgui_gui*`): the containers,
  the text editor with F1 and F4, the HTML viewer with SAPEVENT, the
  toolbar, the picture, the simple, column and list trees, `cl_gui_alv_grid`;
  `cl_demo_output` and `cl_abap_browser`.
- The Fiori launchpad: the shell title, the startup parameters on the
  selection screen, intent navigation (`call_intent( )`, the catalog).
- ABAP Cloud, Standard ABAP from 7.50 and, downported, NetWeaver 7.02; UI5
  from 1.71.

**report2cloud** (`tools/report2cloud`, Node.js, not part of the ABAP
package)

- A classic report into a class of the runtime - deterministic, and it
  refuses with `file:row:col` what has no counterpart, each refusal with a
  page of why and the rewrite. Includes inlined, macros expanded, header
  lines rewritten, the text pool and the GUI status of the `.prog.xml`.
- The migration report: the TODOs, the objects not released on ABAP Cloud
  with their successors, the ATC findings of the report (`--atc`), the
  target mapping of the launchpad tile.
- A whole package in one run, with the order to migrate in; the
  measurement over a folder (`report2cloud:coverage`) and over the
  open-source reports of the web (`report2cloud:web`).
- The AI loop of the site measured on the refused reports
  (`report2cloud:eval`).
- The site (<https://abap2ui5-addons.github.io/abap-cloud-gui/>): the
  converter in the browser, the samples running beside it, an AI assistant
  for the refused statements and for polishing the class.
- `migrate_report` of the abap2UI5 MCP server (since its 1.0.0) runs it
  for an agent.
