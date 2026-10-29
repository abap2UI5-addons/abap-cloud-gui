# report2cloud: ZR2C_20_TABS → z2ui5_cl_cgui_r2c_20

| | |
|---|---|
| Source | `zr2c_20_tabs.prog.abap` |
| Text pool | `zr2c_20_tabs.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_20.clas.abap`, `z2ui5_cl_cgui_r2c_20.clas.xml` |
| Mapped | 33 construct(s) |
| TODO | 1 |
| Release state to check | 1 object(s) |

## TODO

- `zr2c_20_tabs.prog.abap:40:3` - tabs-activetab / -dynnr: the program selects the tab of the tabbed block tabs - the user selects it here; dropped

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | DDIC type | `z2ui5_cl_cgui_r2c_20.clas.abap:10:24` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- SELECTION-SCREEN TAB ... USER-COMMAND - a click on a tab raises no user command here; the tabs switch in the browser (2×)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_20_tabs` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `TABLES sscrfields` | dropped - sscrfields-ucomm is the ucomm of at_selection_screen_ucomm( ) |
| 12 | `SELECTION-SCREEN FUNCTION KEY 1` | `screen->function_key( )` - a button of the toolbar raising FC01, which arrives in `at_user_command( )` (and AT SELECTION-SCREEN as sscrfields-ucomm) |
| 13 | `SELECTION-SCREEN FUNCTION KEY 2` | `screen->function_key( )` - a button of the toolbar raising FC02, which arrives in `at_user_command( )` (and AT SELECTION-SCREEN as sscrfields-ucomm) |
| 15 | `SELECTION-SCREEN BEGIN OF TABBED BLOCK tabs FOR 6 LINES` | `screen->tabbed_block_begin( )` - the tabs that follow |
| 16 | `SELECTION-SCREEN TAB (20) tab_main USER-COMMAND main DEFAULT SCREEN...` | `screen->tab( tab_main )` - its text is the field tab_main, set in initialization( ); the fields of its subscreen follow |
| 17 | `SELECTION-SCREEN TAB (20) tab_opt USER-COMMAND opt DEFAULT SCREEN 102` | `screen->tab( tab_opt )` - its text is the field tab_opt, set in initialization( ); the fields of its subscreen follow |
| 18 | `SELECTION-SCREEN END OF BLOCK tabs` | `screen->tabbed_block_end( )` |
| 20 | `SELECTION-SCREEN BEGIN OF SCREEN 101 AS SUBSCREEN` | the fields of subscreen 0101 - on the tab that names it as DEFAULT SCREEN |
| 21 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 22 | `SELECT-OPTIONS s_fldate FOR sy-datum` | range attribute `s_fldate`, `screen->select_option( )` |
| 23 | `SELECTION-SCREEN END OF SCREEN 101` | `selection_screen_dynnr( )` |
| 25 | `SELECTION-SCREEN BEGIN OF SCREEN 102 AS SUBSCREEN` | the fields of subscreen 0102 - on the tab that names it as DEFAULT SCREEN |
| 26 | `PARAMETERS p_max TYPE i DEFAULT 50` | attribute `p_max`, `screen->parameter( )` |
| 27 | `PARAMETERS p_full AS CHECKBOX` | attribute `p_full`, `screen->checkbox( )` |
| 28 | `SELECTION-SCREEN END OF SCREEN 102` | `selection_screen_dynnr( )` |
| 30 | `INITIALIZATION` | `initialization( )` |
| 31 | `DATA ls_text TYPE smp_dyntxt` | dropped - the text of a function key is function_key( ) in selection_screen( ) |
| 34 | `sscrfields-functxt_01 = 'Today'` | dropped - the text of FUNCTION KEY 1 - function_key( ) in selection_screen( ) |
| 35 | `CLEAR ls_text` | dropped - the text of a function key - function_key( ) in selection_screen( ) |
| 36 | `ls_text-icon_id = icon_refresh` | dropped - the text of a function key - function_key( ) in selection_screen( ) |
| 37 | `ls_text-icon_text = 'Reset'` | dropped - the text of a function key - function_key( ) in selection_screen( ) |
| 38 | `ls_text-quickinfo = 'Reset the selection'` | dropped - the text of a function key - function_key( ) in selection_screen( ) |
| 39 | `sscrfields-functxt_02 = ls_text` | dropped - the text of FUNCTION KEY 2 - function_key( ) in selection_screen( ) |
| 40 | `tabs-activetab = 'OPT'` | dropped - the tab of a tabbed block is the user's |
| 42 | `AT SELECTION-SCREEN ON HELP-REQUEST FOR p_max` | `at_selection_screen_on_help( field )` - WHEN `P_MAX`, the field declared with help_request (an F1 button either way) |
| 43 | `MESSAGE 'The list shows at most this many flights' TYPE 'I'` | `message( )` |
| 45 | `AT SELECTION-SCREEN` | `at_selection_screen( )` and `at_user_command( )` - both call `at_selection_screen_ucomm( ucomm )`, sy-ucomm becomes ucomm |
| 54 | `START-OF-SELECTION` | `start_of_selection( )` |
| 55 | `WRITE / 'Airline'` | `write( )` |
| 55 | `WRITE p_carrid` | `write( )` |
| 55 | `WRITE 'at most'` | `write( )` |
| 55 | `WRITE p_max` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_20` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_20` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_20_TABS` report = `Z2UI5_CL_CGUI_R2C_20` text = `ZR2C_20_TABS` semantic_object = `Z2UI5_CL_CGUI_R2C_20` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_20`.
4. Pin the behaviour with ABAP Unit tests before the next change.
