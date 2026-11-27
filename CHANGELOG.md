# Changelog

A release is a tag `vX.Y.Z` on `main` (RELEASING.md). Each one has a section
here; `.github/workflows/release.yaml` takes it as the text of the GitHub
release.

## Unreleased

**Fixes**

- report2UI5 no longer writes wrong code where it used to: `HIDE` is
  `list( )->hide( )` at the statement - the value when `HIDE` runs, not at
  the `WRITE` before it - and works for a table with a header line and in a
  method of a local class (both did not compile); the one set of hidden
  fields is compared field by field (`gv_id2` was taken for `gv_id`). A
  `FORMAT` before a `PERFORM` is the FORM's too, and one left on at the end
  of a FORM is a TODO. `WRITE` passes `CURRENCY`, `UNIT`, `DECIMALS`,
  `ROUND`, `NO-ZERO`, `NO-SIGN`, `NO-GROUPING`, the justification, the
  edit mask, the date formats, `TIME ZONE`, `QUICKINFO`, `INTENSIFIED`,
  `INVERSE` and `INPUT` to `write( )` instead of dropping them.
  `DEFAULT abap_true` (or a constant) of a checkbox or radio button is
  kept; a `USING` parameter written through a field symbol or a reference
  is `CHANGING`; `sy-lisel` / `sy-lilli` in a FORM called from `AT
  LINE-SELECTION` read the clicked line, `sy-lisel(n)` compiles; `MESSAGE
  ... TYPE <variable>` returns on E and A; the `IF sy-subrc` after
  `F4IF_INT_TABLE_VALUE_REQUEST` that read `RETURN_TAB` (and cleared the
  field) is dropped; the SLIS / LVC line types are dropped with their
  tables. Sorts, aggregations, keys, widths, `set_optimize` and the stripes
  of `CL_SALV_TABLE`, and `IT_SORT`, `KEY`, `OUTPUTLEN`, `COL_POS` of
  `REUSE_ALV_*` are mapped. ABAP SQL puts `INTO` behind `WHERE` and `ORDER
  BY`, as strict mode wants; a dynamic `WHERE` is a TODO. The corpus report
  `zr2c_54_listdetails` (test set `src/03`) covers them.
- The XLSX export drops the control characters XML forbids (Excel
  repaired the workbook) and keeps the leading and trailing blanks of a
  cell; the SVG chart escapes the same way (`z2ui5_cl_cgui_context=>
  c_escape_xml( )`, copied from abap-util). Base64 goes through the kernel
  (`CL_WEB_HTTP_UTILITY`, `CL_HTTP_UTILITY`), the ABAP loop is the last
  resort; a data URI without `;base64` is percent-decoded; the MIME type of
  a download comes from abap-util's catalog (`file_get_mimetype( )`).
- Sample 05 built its flights anew on top of the old ones after Back and
  Execute; sample 09 branched on `sy-dynnr` and `sy-ucomm`, which the
  runtime does not set.
- The command field (`/nCLASS`, a transaction of the catalog) creates a
  class only when it inherits from `z2ui5_cl_cgui_report` - a class whose
  constructor wants parameters ended the app. The command field, the
  palette and `call_transaction( )` find a code of the catalog in any case,
  by one resolver (`z2ui5_cl_cgui_command=>tcode_find( )`).
- Variants and layouts: a user who saves over a shared variant or layout
  of another user keeps its sharing (it vanished for everyone with his
  unchecked box); Save as Variant refuses names of the draft scheme
  (`%...`) and names over 40 characters, and a draft is restored only for
  its owner; a saved layout picked in Change Layout and taken unchanged is
  applied, not saved again; OK in Change Layout keeps the sort order.
- Messages: W, E and A of a roundtrip that opened a popup open the
  message popover when the screen shows again; I messages and a box of
  `_msg_box( )` share the one box.
- The list counts and prints `SKIP n` as n lines; the ALV selection stays
  through a line selection and Back; the text of a transport request is
  read in the logon language; the intent navigation escapes control
  characters.
- ALV: `EDIT` of one column of a classic field catalog no longer makes
  the whole grid editable; a field catalog or sort table set again on the
  shown grid replaces the old one (flags switched off, old sort gone);
  `COLTEXT` heads a column before the DDIC texts; the tooltip of a column
  is on the column; namespaced columns (`/ABC/FIELD`) are bound relative to
  the row; dropdown texts are escaped once; subtotals follow the sort
  order; the CSV export is sorted as the layout; `to_text( )` prints the
  aggregation of a column, not always its total. The page buttons
  (`cs_page`, `get_page( )`, `get_page_offset( )`, `page_turn( )`) are
  deprecated - the grid scrolls through a window of rows.
- SAP GUI stand-ins: the SALV columns list the columns of an `.INCLUDE`;
  an expander of the SALV tree raises `EXPAND_EMPTY_FOLDER`; the SALV table
  finds its table by the attribute name after the draft; the text editor
  wraps a line longer than the field of the table instead of cutting it;
  the state of the tree, the SALV stand-ins, the text editor, the HTML
  viewer, the container, the demo output and the application log is
  PROTECTED, so the transpiled runtime restores it from the draft.
- The helpers of `z2ui5_cl_cgui_context` copied from abap-util follow
  its fixes: on ABAP Cloud the labels of a data element are read again
  (the XCO call failed on its parameter types, so every column and field
  fell back to its name), and an `INT8` is typed for the model without
  the typekind constant 7.02 lacks.

- The value help (`z2ui5_cl_cgui_select`) shows a column with a namespace
  (`/SCWM/...`) again: its cell bound `{/SCWM/...}`, an absolute path read
  from the model root, and stayed empty. The column name now goes through
  `z2ui5_cl_ui5_view_builder=>component_path( )`; every other name is
  unchanged. abaplint is 2.120.120.
- An obligatory list box (`AS LISTBOX` of the selection screen) no longer
  sets `required` on its `sap.m.Select`: the property exists from UI5 1.74
  on, and the floor is 1.71. The label still marks the field, and the
  obligatory check of the backend is unchanged.
- The abap2UI5-linter is 0.12.0 (`@abap2ui5/linter`). Its new warnings on
  `z2ui5_cl_cgui_report` are waived in `abap2ui5lint.jsonc` with the
  reason: `nonpublic-data-reference` for the protected copies of the grid's
  field catalog and layout, `nonserializable-attribute` for
  `mo_cgui_screen`, which no roundtrip carries.
- The abap2UI5-linter is 0.11.2 (`@abap2ui5/linter`,
  `@abap2ui5/linter-render`). It fixed the false positives 0.11.0 was
  written around, so the workarounds are gone: two string templates with a
  line-breaking expression are inline again (the right-aligned list text of
  the ALV, the owner of a saved layout), the input type of a parameter is
  an IF/ELSEIF again, and the selection screen is rendered by the gate
  again (no longer excluded from `render-error`). The tab bar of the
  selection screen hands its key over with `arg` instead of a one-row
  `t_arg`.
- The value help (`z2ui5_cl_cgui_select`) picked nothing in the browser on
  abap2UI5 1.149.0: its confirm read `selectedContexts[0]/sPath`, which a UI5
  event parameter cannot index, and the selection mark it fell back on never
  reached the backend for a windowed table. The confirm now hands over the
  path of the item picked.
- The HTML viewer asked for abap2UI5's HTMLFrame by a literal class name,
  which the namespace rename does not rewrite - the name is derived from the
  view builder's now (`npm run rename` was red).
- Tests: the unit tests, the runtime and the browser test of report2UI5
  build again on the 1.149.0 runtime (transpiler 2.14 - the host's
  `_ddic.mjs` and a program's `$main`), the HTML viewer tests follow the
  HTMLFrame that 1.149.0 brings, and a browser test picks a row of the value
  help.

- A link to the selection screen (`z2ui5_cl_cgui_command=>url_from_range( )`)
  wrote a select-option line with NB or NP as its low value only, and the
  link read it back as EQ or CP - the opposite selection. NB is written as
  the negated interval (`!A..B`), NP as the negated pattern (`!A*`).
- A tabstrip of a dynpro without an active tab selected the first tab
  found from a stale `sy-tabix` (the builder's last append), not the first
  tab of that tabstrip.
- The site showed the `.clas.xml` of a conversion with broken markup: the
  attribute highlighting matched the class of the tag highlighting.
- The pages workflow builds the site for a pull request that changes the
  corpus of report2UI5, whose reports are the site's examples.
- The gates run against abap2UI5 1.151.0 (`1.151.0-702` for 7.02), whose
  windowed table the addon needs - pinned to the tag again now that it is
  cut; the core pin moved from 1.149.0 over 1.150.0. The lint takes
  abap2UI5's packages `src/00` to `src/02` only: `src/03` is its
  installation package (the ICF handler and the BSP), which nothing here
  uses.

**The value help and table controls in windows too**

- The hit list of `z2ui5_cl_cgui_select` (F4, the variant catalog) and the
  table control of a dynpro bind with `window_bind_tab( )` like a large ALV: the
  browser gets 100 hits / 50 lines at a time and the next ones as the list
  grows, instead of every row at once. The addon loads them itself: the list
  asks with an event of its own (`z2ui5_cl_cgui_select=>cs_event-rows`,
  `z2ui5_cl_cgui_view=>cv_tc_rows`), the rows bound are the ones loaded
  (`mr_view` and `mv_total` of the popup, `mt_cgui_tc_view` and
  `mv_cgui_tc_total` of the report), so a single pick is the row the browser
  shows; the search still filters on the server, and a mark or an input
  lands in its own row. Needs abap2UI5 1.151.0 (the app-driven
  `window_bind_tab( val total event window )`), as the ALV does.

**Breaking: object names of at most 25 characters**

- Fifteen public classes and interfaces were longer than 25 characters, the
  limit a namespace rename of up to 10 characters needs (30 minus the 5 it
  adds). For one naming scheme all twelve `z2ui5_cl_cgui_gui_*` lose the
  `gui_`: `z2ui5_cl_cgui_gui_alv_grid` is `z2ui5_cl_cgui_alv_grid`, and the
  same for `_alv_toolbar`, `_column_tree`, `_container`, `_easy_split`,
  `_html_viewer`, `_list_tree`, `_picture`, `_simple_tree`, `_textedit`,
  `_toolbar` and `_view`. Further: `z2ui5_cl_cgui_salv_columns` ->
  `z2ui5_cl_cgui_salv_cols`, `z2ui5_cl_cgui_salv_settings` ->
  `z2ui5_cl_cgui_salv_config`, `z2ui5_cl_cgui_abap_browser` ->
  `z2ui5_cl_cgui_browser`, `z2ui5_if_cgui_tree_handler` ->
  `z2ui5_if_cgui_tree_events`, `z2ui5_if_cgui_variant_store` ->
  `z2ui5_if_cgui_variants`, `z2ui5_if_cgui_layout_store` ->
  `z2ui5_if_cgui_layouts`. Members are unchanged. report2UI5 writes the new
  names; a class converted before needs the names replaced (or converting
  again). Delete the old objects after the pull. A major release.
- `npm run rename` and the manual workflow `build-rename`: abap2UI5's
  namespace rename for this addon, references to abap2UI5 renamed along.
**A large ALV in windows instead of pages**

- `set_paging( n )` binds the table with abap2UI5's `window_bind_tab( )`
  instead of cutting a page out of it: the browser gets n rows and the next
  ones as the grid scrolls, a sort or a filter from a column menu runs on
  the server over all rows instead of over the page shown, and the sort of
  the layout is the order the grid starts from. The report runtime answers
  the grid's requests (`z2ui5_cl_cgui_alv=>cs_event-rows`, abap2UI5 1.151.0
  hands them to the app): the grid is bound to a copy of the rows loaded so
  far (`mr_cgui_alv_page`, its length `mv_cgui_alv_total`), more rows are
  the next ones of the order, a sort or a filter of a column menu orders and
  filters all rows anew (`window_request( )`, `window_order( )` of the ALV -
  a group of conditions on one column is a multiple selection of it) and
  holds until the layout sorts anew, and no request draws the screen again.
  The page buttons are gone; hotspots, line selection, cell clicks and F4
  lead from the row the browser shows to the table's row through the copy.
  `get_page( )`, `get_page_offset( )` and `page_turn( )` stay and do
  nothing the grid shows. An app that renders a paged ALV of its own binds
  the rows it loaded as `tab` with `total` and answers `cs_event-rows`
  itself.

**report2UI5: a SALV with a GUI status of its own**

- `x->set_screen_status( pfstatus = 'S' ... )` of a SALV the stand-ins
  take over adds the report's functions of status S (from the `.prog.xml`)
  as buttons of the grid - each raises `added_function` as the classic
  toolbar did; the SALV functions of the status (`&ALL`, `&ILT`, ...) stay
  the grid's. Before, the call was kept and did nothing: the buttons were
  gone.
- A handler `FOR EVENT added_function OF cl_salv_events` - the class that
  declares the event - is taken over like one of `cl_salv_events_table`
  (refused for a SALV tree); `c_functions_none` / `_default` / `_all` are
  constants of `z2ui5_cl_cgui_salv_table`; a `FORM` parameter typed with a
  SALV type (`salv_de_function`, ...) gets the type of the stand-ins.
- The corpus report `zr2c_53_salvstatus` (test set `src/03`) covers the
  three. Found on `ZAFL_VIEWER` of abap-fm-logger, which converts now.

**Typed UI5 bindings from the ABAP type (`z2ui5_cl_cgui_context`)**

- `ui5_binding_typed( path val )` writes the binding of a field with the
  UI5 type of its ABAP type - Date and Time with the source pattern the
  model carries, Integer and Float with grouping and the decimals of a
  packed number, Currency / Unit with `currency_path` / `unit_path`;
  `ui5_binding_typed_comp( struc comp )` does the same for a cell of a
  table template and takes the reference field of an amount or a quantity
  from the DDIC (`rtti_get_ref_field`, on-premise only).
  `ui5_get_type_require( )` is the `core:require` the types need.
  `ui5_binding_by_kind`, `ui5_get_model_type` and `ui5_get_format_options`
  are the parts. The ALV's cell bindings use them now - unchanged output
  (abap2UI5/abap2UI5#2964).

**The site is VitePress**

- <https://abap2ui5-addons.github.io/abap-cloud-gui/> is built with VitePress
  (`site/.vitepress`): a home page, a guide (`/guide`) and the report2UI5
  playground on a page of its own (`/playground`), with search and a dark
  mode. The playground keeps its code (`site/playground.mjs`, bundled with
  esbuild as before) and is mounted by a Vue component; links to the old
  sections (`#samples`, `#playground`, `#package`) lead to it.
- Two pages for report2UI5: **Samples** (`/samples`) - the converted
  reports of the corpus, the report, its class and the running app; and
  **Playground** (`/playground`) - your own report, the package, and an
  **import from GitHub**: a link to a `.prog.abap` opens it in the editor
  with its text pool, a link to a repository or a folder converts its
  reports as a package (each one opens in the editor from the table).
  `?github=<link>` imports at once.
- The playground reads top to bottom: where to start from (your own
  source, a GitHub link, an abapGit zip - as tabs), the class report2UI5
  writes, the preview, and the conversion in detail in tabs (what
  happened, refused, to do, mapped, the migration report, the summary of
  a package). Run in the preview of your own report starts the app again
  - it did not start since the move to VitePress, whose root element has
  the id the frame had.
- `/playground#package` (and `#zip`) opens the zip tab, `#github` the
  GitHub tab - the old link `…/abap-cloud-gui/#package` lands there too.
  `npm run site` builds into `build/site` as before, `npm run site:dev`
  starts the dev server.

**report2cloud is report2UI5, and converts the user interface only**

- Renamed: `tools/report2ui5`, `npm run report2ui5` (and `report2ui5:coverage`,
  `:package`, `:web`, `:docs`, `test:report2ui5`), the workflows
  `report2ui5.yaml` and `report2ui5-web.yaml`. The ABAP objects keep their
  names (`z2ui5_cl_cgui_r2c_*` in `src/03`).
- It converts the selection screen, the event blocks, the list, the ALV,
  the messages and the popups. The logic of a report is copied as it is
  written, and whether it runs on the target system is the user's to check.
- Removed: the release check of tables and APIs for ABAP Cloud (the
  migration report no longer lists them), `--successors`, `--wrappers`,
  `--atc`, the ABAP Cloud lint of `--check` (v750 only), the call graph and
  migration order of a package (`estate.md` is now `summary.md`), the AI
  assistant of the site and `report2cloud:eval` with its workflow.
- `tools/report2cloud/lib/{convert,textpool,report}.mjs` stay as a
  re-export of the new path, and `convert( )` still answers `release` -
  always empty - for the consumers of 1.0.0 (abap2UI5/mcp-server's
  `migrate_report`).
- No longer refused, copied as written: `EXEC SQL`, `CALL TRANSACTION ...
  USING` and the `BDC_*` function modules, `GENERATE REPORT` /
  `SUBROUTINE POOL`, `INSERT REPORT`, `SUBMIT ... VIA JOB`.

## 1.0.0 - 2026-10-30

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
- Selection variants on the server (`Z2UI5_T_19`) or in the browser,
  shared and protected, dynamic dates; the last entries; a draft of a
  selection screen left without executing (`set_draft( )`).
- Parameters on three levels: the user's (`SU3`), the installation's
  customizing (`SPRO`) and the system's (`set_system_parameters( )`).
- The list: `WRITE` with positions, `UNDER`, colours, hotspots, `HIDE`,
  checkboxes and icons, `ULINE`, `NEW-PAGE`, secondary lists, `READ LINE` /
  `MODIFY LINE`; print as PDF, execute in background.
- The ALV (`CL_SALV_TABLE`): columns from RTTI and the DDIC, sort, filter,
  totals and subtotals, layouts on the server (`Z2UI5_T_18`), Excel
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
