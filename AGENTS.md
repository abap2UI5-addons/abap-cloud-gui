# AGENTS.md — abap-cloud-gui

Single source of truth for agents working on this repository.

## What it is

An addon for [abap2UI5](https://github.com/abap2UI5/abap2UI5) that lets an app
be written like a classic ABAP report: selection screen, event blocks, `WRITE`
list, ALV grid, messages. Language of code, comments, commits and docs:
**English**.

## Layout

| Path | Content |
|---|---|
| `src/01` | the framework: `z2ui5_cl_cgui_report` (report runtime), `_selscreen`, `_list`, `_alv`, `_tree`, `_layout` (the layout dialog of the ALV), `_popup`, `_range`, `_select`, `_variant` (selection variants), `_context` (RTTI and conversion helpers), `z2ui5_cx_cgui_error`; the two stores: `z2ui5_if_cgui_variant_store` with `z2ui5_cl_cgui_variant_db` (table `Z2UI5_CGUI_VAR`, data elements `Z2UI5_CGUI_VAR_*`) and `z2ui5_if_cgui_layout_store` with `z2ui5_cl_cgui_layout_db` (table `Z2UI5_CGUI_LAY`) |
| `src/02` | samples `z2ui5_cl_cgui_sample_01` … `_11` |
| `src/03` | the test set: the corpus reports of report2cloud as converted (`z2ui5_cl_cgui_r2c_NN`), generated - never edit by hand, `UPDATE_SNAPSHOTS=1 npm run test:report2cloud` writes it. Only the reports whose migration report names nothing for the release, so the package activates on ABAP Cloud too; the gate test's scratch copy leaves it out and lints the conversion of now under `src/r2c` |
| `tools/report2cloud` | `report2cloud`, a Node CLI (no ABAP object) that converts a classic report into a report class of this addon - THE generator of this repository, see below |
| `scripts/unit.mjs` | `npm run unit` - the ABAP Unit tests in the transpiled backend, tables included |
| `site/`, `scripts/build-site.mjs` | `npm run site` - the GitHub Pages site: the page about the addon and the report2cloud playground, the converter bundled for the browser with esbuild (`.github/workflows/pages.yaml` deploys `build/site` from main). The converter stays browser-safe: no `node:` import in `tools/report2cloud/lib/convert.mjs` and what it imports (`report.mjs`, `refusals.mjs`, `abap.mjs`, `abapgit.mjs`, `textpool.mjs`) - file access belongs to the CLI |
| `site/playground/`, `scripts/build-playground.mjs` | `npm run site:playground` - the site's own copy of the abap2UI5 playground (`build/site/playground`), where a converted report runs: the playground at a pin with `site/playground/report2cloud.patch` applied, built with this checkout's addon. The abap2UI5 playground itself carries nothing of reports - keep it that way; a pin bump or a patch that no longer applies: `site/playground/README.md` |
| `.github/abaplint` | the Cloud and 7.02 gate configs; `abaplint.jsonc` at the root is the v750 inner loop |

Naming: every class is `Z2UI5_CL_CGUI_*` / `Z2UI5_CX_CGUI_*`, every interface
`Z2UI5_IF_CGUI_*` (abaplint `object_naming`). Only `CLAS`, `INTF`, `DEVC`,
`TABL` and `DTEL` objects (`allowed_object_types`) - no programs, no
function groups, no tooling that runs on the stack: everything under `src/`
is ABAP Cloud ready, transpilable to Node and downportable to 7.02. The
tables and data elements use built-in types (`CHAR`, `STRG`) or data
elements that are released on ABAP Cloud and exist on 7.02 (`MANDT`,
`TIMESTAMPL`, `TZNTSTMPL`, `CHAR40`) - never an on-premise one such as
`SEOCLSNAME` or `XUBNAME`. Report and class generation runs in Node only
(`tools/report2cloud`).

## Dependencies

- abap2UI5 — only its public API: `z2ui5_if_app`, `z2ui5_if_client`,
  `z2ui5_cl_ui5_view_builder`. Never the frozen `z2ui5_cl_xml_view` or
  anything under its `src/99`, never core internals such as
  `z2ui5_cl_ui5_util_context` (copy a helper into `z2ui5_cl_cgui_context`
  instead).
Nothing else. The popups (value help, ranges, confirmation, decisions,
values, files, the transport request) are classes of this addon
(`z2ui5_cl_cgui_popup`, `_select`, `_range`, `_file`, `_transport`), in its
style - do not bring a dependency on abap2UI5-addons/popups back; copy what
is needed and adapt it.

abaplint resolves abap2UI5 as a git dependency. The core is **pinned to a
release tag** (the `"branch"` key of the abap2UI5 dependency, abap2UI5
CONVENTIONS §9): users install a release next to this addon, so the gates
run against that release and not against the framework's `main`. Three
configs carry the pin (`abaplint.jsonc`, `.github/abaplint/abap_cloud.jsonc`,
and the downported `<tag>-702` form in `.github/abaplint/abap_702.jsonc`);
read and move them only with `scripts/core-pin.mjs` (`get` fails when they
disagree). `bump-core.yaml` moves the pin weekly to the newest release after
the three abaplint gates passed on it, and the scheduled `abaplint` run lints
once against the core's `main` as the canary (`core-pin.mjs set main`, never
committed). Do not drop the key: abaplint then clones `main` silently.

## Targets

Three release targets and one runtime, every one a CI gate with no excludes:

- **ABAP Cloud** - released APIs only, `npm run check:cloud`;
- **Standard ABAP** - 7.50 syntax that downports, `npm run lint` (its
  API set is the intersection of ABAP Cloud and 7.02);
- **NW 7.02** - a downported copy, `npm run check:702`;
- **the transpiled Node runtime** - `npm run unit` runs every ABAP Unit test
  there, the DANGEROUS ones of the two stores against SQLite.

No regular expressions (`npm run check:regex`). UI5 1.71 is the floor -
`npm run check:abap2ui5` (the abap2UI5-linter). `npm run check` runs the
static gates.

## Releases

A release is an annotated tag `vX.Y.Z` on `main` - RELEASING.md has the
steps, CHANGELOG.md a section per release (`## Unreleased` collects what a
pull request adds). `.github/workflows/release.yaml` refuses a tag that
package.json or the CHANGELOG disagree with, runs `npm run check` on it and
publishes the GitHub release with the abapGit zip and the 7.02 zip. From
1.0.0 on the public API of `src/01` follows semantic versioning - a change
that removes or retypes something public is a major release.

## Frozen stand-ins

`z2ui5_cl_cgui_gui_picture`, `_simple_tree`, `_column_tree` and
`_list_tree` are frozen since 1.0.0: kept, tested, bugs fixed, no new
members. Each stands in for a control one or two reports of the web corpus
use; a report that needs more of `cl_gui_picture` or the trees ports that
control by hand. The containers, the text editor, the HTML viewer, the
toolbar and the grid are not frozen.

## Rules learned the hard way

- **No PRIVATE instance attributes on an app class or on an object an app
  keeps.** The draft persists the app with `CALL TRANSFORMATION id`, and the
  transpiled runtime reaches PROTECTED attributes but not PRIVATE ones. The
  report runtime keeps its state PROTECTED with a `cgui` infix so it cannot
  collide with the attributes of the report that inherits.
- **Bound data is found by reference.** A field method of the selection
  screen gets the attribute itself (pass by reference) and hands it to
  `client->_bind( )`; `z2ui5_cl_cgui_context=>attri_name_by_ref( )` finds its
  name the same way. A copy (a `VALUE( )` parameter, a local variable) binds
  nothing.
- **Prefer an attribute name over a data reference** for state that
  survives a roundtrip: a `REF TO data` with an anonymous type is rebuilt with
  RTTI when the draft loads (`cl_abap_elemdescr=>get_p` is a stub in the
  transpiled runtime). `alv( )` stores the attribute name when it can.
- **Read `sy-tabix` / `sy-index` arguments first.** `write( hide = sy-tabix )`
  is read before anything else in the method: the transpiled runtime passes
  even a `VALUE( )` of type `any` by reference, and its RTTI loops.
- **Dates and times reach the model formatted**: `2026-01-05`, `12:00:00`, an
  initial one as empty. DatePicker and TimePicker use `valueFormat`
  `yyyy-MM-dd` and `HH:mm:ss`.
- **`IN` in the transpiled runtime** only knows `I EQ`, `E EQ`, `I CP`; the
  samples use `z2ui5_cl_cgui_context=>range_check( )`.
- **A radio button's `select` fires at the button it deselects too** — before
  that button's `false` reaches the model, so a roundtrip from there carries
  two selected buttons. The user command of a group is wired only to the
  buttons not selected at render time; the screen is rendered anew after
  every roundtrip, so the wiring follows the selection.
- **The standard F4 reads the DDIC dynamically.** `GET_DDIC_FIXED_VALUES`
  is called with a local copy of `DDFIXVALUE` (as abap2UI5 core does), and
  the value table goes through `DFIES` / `DDFIELDS`, which raise on ABAP
  Cloud - every lookup sits in a `TRY` and an error means "no F4". In tests
  use `XSDBOOLEAN`: it is the one data element with fixed values that both
  the abaplint API set and the transpiled runtime know.
- **`z2ui5_cl_popup_to_select` preselects through `ZZSELKZ`.** It copies the
  rows with `MOVE-CORRESPONDING` into its own table, whose `ZZSELKZ` is bound
  to `selected` - so a table that brings a `ZZSELKZ` comes up checked. The
  popup heads a column with the DDIC label of its type, and with `STRING`
  for a string: give value lists character types.
- **Variants live in table `Z2UI5_CGUI_VAR` by default**
  (`z2ui5_cl_cgui_variant_db`: shared and protected variants, one owner each,
  set after `initialization( )` unless it chose otherwise);
  `set_variant_store( store )` plugs in another `z2ui5_if_cgui_variant_store`,
  `set_variant_store( )` without one keeps them in the browser's local
  storage. For the browser's storage, the invisible `z2ui5:Storage` control reads the catalog
  into the PUBLIC `mv_cgui_variants` and fires `finished` while the first
  view still renders - the wire needs `check_queue_last`, or the event is
  dropped. `STORE_DATA` is called from a handler with a payload composed as
  JSON (`z2ui5_cl_cgui_variant=>storage_json( )`), never with
  `${ _bind( ) }`: a handler's binding argument arrives as text, and an
  empty VALUE deletes the key. Keep bound and stored value equal after a
  write, or the control reports again on the next render. A variant in the
  URL is read after `initialization( )`, so it wins over `set_variant( )`.
- **ALV layouts live in table `Z2UI5_CGUI_LAY` by default**
  (`z2ui5_cl_cgui_layout_db`, one namespace per report class and ALV handle -
  the attribute `alv( )` shows): shared and protected like the variants, and
  the default layout is personal - the store keeps one per user and counts
  the flag for its owner only. `set_layout_store( store )` plugs in another
  `z2ui5_if_cgui_layout_store`; `set_layout_store( )` without one keeps the
  layouts with the selection variants (`#L#` names). The report tests plug in
  an in-memory store, so only the store's own DANGEROUS test writes the table.
- **ABAP Cloud has no `WRITE ... TO`, no spool, no SAP memory, no background
  job API that is also on 7.02.** The list formats with string templates
  (an edit mask by hand, the date formats from the user's separator, a
  currency's decimals from ISO 4217 - TCURX is not released); Print hands the
  output to the browser as a text file; SET / GET PARAMETER ID live in the
  browser's local storage; `cgui_run_in_background( )` runs a report without
  a browser, from an application job of the customer's. UTF-8, base64 and
  URL escaping are `z2ui5_cl_cgui_context=>conv_*( )` / `url_escape( )` -
  the codepage classes named as strings, as abap2UI5 does it.
- **The transpiled runtime differs - write what runs on both.** `CREATE DATA
  r LIKE tab` copies the rows along (`CLEAR` the new table); `SORT ... BY
  (otab)` and `SORT ... BY (name)` sort nothing (the ALV sorts with a merge
  sort of its own); `WIDTH`/`ALIGN`/`PAD` and `CURRENCY` of a string template
  are ignored or not implemented (`z2ui5_cl_cgui_context=>text_align( )`, a
  NUMC); `cl_abap_structdescr=>get( )` and `cl_abap_tabledescr=>get( )` are
  stubs (`create( )`); a parameter named like a reserved JavaScript word
  (`protected`) breaks the module; `round( )` takes `dec = 0` only. A data
  element with fixed values in a test is `XSDBOOLEAN` (see above), a typed
  test field one of the data elements both the API set and the runtime know
  (`LAND1`).
- **The message popover is part of the screen and opens in a roundtrip of
  its own.** It is a dependent of the page; the footer button toggles it in
  the browser (`control_by_id` `toggleBy`, no roundtrip). Opened by the
  response that builds the screen - `openBy` as a follow-up action, or a
  popover through `popover_display( )` - it stayed open without ever being
  rendered after the first time, because the frontend holds the rendering
  back while it swaps the view. So a run with W or E arms `start_timer`
  with 0 ms and `CGUI_MESSAGES_OPEN` opens it without drawing the screen
  again. The click on a message reaches the backend with the item as its
  argument (`${$parameters>/item}` arrives as JSON with the item's id),
  whose `cgui_msg_<n>` is the index into the log; the field control has the
  id `z2ui5_cl_cgui_selscreen=>field_id( )` for `SET_FOCUS`.
- **ABAP Doc goes after the colon of a chained declaration.** `"!` in
  front of `TYPES:` / `CONSTANTS:` is "in the wrong position" for the
  extended check; write `TYPES:` and the `"!` lines below it, in front of
  `BEGIN OF`. abaplint `wrong_abapdoc_position` checks it in all three gates.
- **No regular expressions.** POSIX (`FIND REGEX`, `matches( regex = )`,
  `cl_abap_regex`) is deprecated from 7.55 on and warns in the extended
  check; PCRE (`FIND PCRE`, `pcre =`) does not exist on 7.02. Use `FIND`,
  `CS` / `CN` / `CA` / `NA` and `substring( )`. abaplint has no rule for it:
  `npm run check:regex` (`scripts/check-regex.mjs`) fails on any regex in
  `src`.
- **The report dispatcher is one IF/ELSEIF chain** over `check_on_init`,
  `check_on_navigated`, `check_on_event`, and every branch that shows the
  screen calls `view_display( )` — unless a popup app was called in the same
  roundtrip (`mv_cgui_nav`).

## report2cloud

`tools/report2cloud` converts a classic report (`.prog.abap`, its text pool
from the `.prog.xml`, its includes from the `.prog.abap` files beside it)
into a class inheriting from `z2ui5_cl_cgui_report`:
`npm run report2cloud -- zreport.prog.abap [--class zcl_x] [--out dir]`. It
inlines the includes before the parse (`lib/includes.mjs` - no `node:fs`
in it, the site bundles it; the reader over folders is `lib/includes-fs.mjs`
- every line of the
result knows its file and row), parses with `@abaplint/core` at the version
of `@abaplint/cli` - which expands the macros at their calls - writes the
class in abapGit format plus a migration report, and refuses with
`file:row:col` what has no counterpart (dynpros, batch input, `SUBMIT`,
native SQL, ...). The mapping table and the refusals are in its README.
It is the only converter and the only generator of this repository - there
is no ABAP tooling on the stack. `npm run report2cloud:coverage -- <dir>`
(`coverage.mjs`) is the measurement over a folder of reports: converted,
refused and why, ranked - the README's roadmap is ordered by it, so run it
on a real corpus before picking the next construct to map. `npm run
report2cloud:web` (`web.mjs`) is that corpus: the reports of the
open-source ABAP repositories of the dotabap list, cloned sparse into
`build/web-corpus` (read, never run, never committed - a test case taken
from it is rewritten by hand), measured weekly by
`.github/workflows/report2cloud-web.yaml`. `npm run report2cloud:eval`
(`eval.mjs`) measures the AI loop of the site (`site/assistant.mjs`) on
the reports of that corpus the converter refuses - accepted, clean, per
kind of refusal; with `--dry` it needs no key. A change to the prompt or
the model is compared on the same `--limit` before and after.

- **It writes against the API of `src/01` as it is.** A change to a
  signature of `z2ui5_cl_cgui_report`, `_selscreen`, `_list` or `_alv`
  (a parameter renamed, a method dropped) breaks the generated classes:
  `npm run test:report2cloud` lints every class of its corpus in a scratch
  copy of this repository - v750 with every rule of `abaplint.jsonc` (no
  finding in a generated class; `test/ddic` has stubs of the flight
  tables), ABAP Cloud with `.github/abaplint/abap_cloud.jsonc` (only the
  unreleased tables the migration report lists), the 7.02 gate and the
  abap2UI5 linter (no finding). Findings in `src/` itself are `npm run
  check`'s business and only counted. A new PUBLIC or PROTECTED method of
  `z2ui5_cl_cgui_report` goes into `BASE_METHODS` of `lib/convert.mjs` (a
  test compares them). Change the converter with the API, then
  `UPDATE_SNAPSHOTS=1 node --test tools/report2cloud/test/convert.test.mjs`
  and review the snapshot diff.
- **A class that lints is not a class that runs.**
  `npm run test:report2cloud:runtime` (opt-in; needs an mcp-server checkout
  at `MCP_SERVER_HOME` or `../mcp-server`, git and network) transpiles the
  corpus classes with `src/01` (its tables and data elements included)
  and the seeded flight table stubs
  against `@abap2ui5/node-runtime` and operates every report through the
  JSON protocol of the frontend (mcp-server's app client): fields, Execute,
  hotspots, grid rows, the F4 popup (a table of the agent snapshot, picked
  with `app_act({ event, row })`), the message popover (`snapshot.messages`,
  source `popover`), Back and a second run, each against expectations
  written by hand from what the classic report prints. It found, past a
  green lint: report globals that grew from one Execute to the next (the
  classic report restarts after its list - `start_of_selection( )` now
  clears them), END-OF-SELECTION skipped after a RETURN, a TOP-OF-PAGE
  header shown as a list of its own (both are events of
  `z2ui5_cl_cgui_report` now - the class redefines `end_of_selection( )`
  and `top_of_page( )` and never calls them), the `LOWER CASE` the converter
  dropped (the runtime converts a character field to upper case without
  `lower_case`), `MESSAGE s013 ... INTO` without the class of
  MESSAGE-ID, `sy-repid` (undefined in the runtime, the class pool on a
  system), a generic `TYPE p` parameter (the transpiler cannot describe it -
  the class fails before its first screen) and `IN` on a select-option
  (the runtime's `IN` knows `I EQ`, `E EQ`, `I CP` - `range_check( )`, the
  rule above). Run it after a change to the converter or to `src/01`.
  `npm run test:report2cloud:browser` runs the same classes as the real app
  in headless Chromium (UI5 from the `@openui5` devDependencies): boot,
  render, Execute, no page error - what the JSON protocol cannot see (a
  property value UI5 rejects ends the app before its first screen).
  Both clear the `CLASS-DATA` of the reports' local classes before every
  request, as a system does - the Node process would keep it.
- **It follows the rules above**: report globals become PUBLIC attributes
  (never PRIVATE), the selection screen binds them by reference, ABAP SQL is
  written in strict mode, chains follow the house layout of the samples.
- **The generated files are abapGit's format** - BOM in the sidecar, LF,
  no trailing blanks, no line over 255 characters; the tests check every
  generated file.
- **A corpus include is a `.prog.abap` without a `REPORT` statement**, lying
  beside the report that names it (`corpus.mjs` tells the two apart that
  way); a token of an expanded macro stands at the call's position and
  keeps its body position as `vrow` / `vcol`, which `renderTokens( )` reads
  the spacing from.
- CI: `.github/workflows/report2cloud.yaml`; the weekly web corpus
  `.github/workflows/report2cloud-web.yaml`; the AI loop, by hand,
  `.github/workflows/report2cloud-eval.yaml`.

## Verifying at runtime

The views can be driven without an SAP system: transpile `src` against
`@abap2ui5/node-runtime` (the mcp-server's
`lib/npm-backend.mjs` `buildNpm`), start `lib/npm-host.mjs`, and drive the
app with Playwright. The unit tests run the same way, in CI
(`.github/workflows/unit.yaml`) and locally: `npm run unit`
(`scripts/unit.mjs`, the build of the report2cloud runtime test with the test
includes; mcp-server at `MCP_SERVER_HOME` or `../mcp-server`). The MCP server's own unit action deploys classes and
interfaces only - no tables - hence the script.
Where the UI5 CDN (`sdk.openui5.org`) is not reachable, serve the
`@openui5/*/src` packages the linter installs in `node_modules` through a
Playwright `page.route( )`, with `bypassCSP: true` for the source bootstrap.
