# report2cloud: ZR2C_12_PAGES → z2ui5_cl_cgui_r2c_12

| | |
|---|---|
| Source | `zr2c_12_pages.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_12.clas.abap`, `z2ui5_cl_cgui_r2c_12.clas.xml` |
| Mapped | 36 construct(s) |
| TODO | 2 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for P_LINES, S_SKIP, P_LIST, P_LAST - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_12_pages.prog.abap:48:1` - END-OF-PAGE: the runtime ends every page with the footer, the last one too - the classic event ran only when a page was full

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- REPORT ... LINE-COUNT n is set_line_count( n ) - a page holds n lines of the list besides its header and footer; the classic n counted them too

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 9 | `REPORT zr2c_12_pages NO STANDARD PAGE HEADING LINE-COUNT 6(1)` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 14 | `SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME` | `screen->block_begin( )` |
| 15 | `PARAMETERS p_lines TYPE i DEFAULT 7` | attribute `p_lines`, `screen->parameter( )` |
| 16 | `SELECT-OPTIONS s_skip FOR gv_num NO INTERVALS` | range attribute `s_skip`, `screen->select_option( )` |
| 17 | `SELECTION-SCREEN END OF BLOCK b1` | `screen->block_end( )` |
| 19 | `PARAMETERS p_list RADIOBUTTON GROUP mode DEFAULT 'X'` | attribute `p_list`, `screen->radiobutton( )` |
| 20 | `PARAMETERS p_last RADIOBUTTON GROUP mode` | attribute `p_last`, `screen->radiobutton( )` |
| 22 | `AT SELECTION-SCREEN ON BLOCK b1` | `at_selection_screen_on_block( block )` - WHEN `B1`, the name of block_begin( ) |
| 24 | `MESSAGE 'At most 20 lines' TYPE 'E'` | `message( )` |
| 27 | `AT SELECTION-SCREEN ON RADIOBUTTON GROUP mode` | `at_selection_screen_on_radio( group )` - WHEN `MODE` |
| 29 | `MESSAGE 'A last page needs two lines' TYPE 'E'` | `message( )` |
| 32 | `AT SELECTION-SCREEN ON END OF s_skip` | `at_selection_screen_on_end_of( field )` - WHEN `S_SKIP`, the multiple selection left with OK |
| 34 | `MESSAGE 'Skip at most 3 numbers' TYPE 'E'` | `message( )` |
| 37 | `AT SELECTION-SCREEN ON EXIT-COMMAND` | `at_selection_screen_on_exit( ucomm )` - Back on the selection screen |
| 38 | `MESSAGE 'Selection left' TYPE 'S'` | `message( )` |
| 40 | `TOP-OF-PAGE` | `top_of_page( )` - the header the runtime writes above the list and repeats on every page |
| 41 | `WRITE / 'Numbers - page'` | `write( )` |
| 41 | `WRITE sy-pagno` | `write( )` |
| 42 | `ULINE` | `list( )->uline( )` |
| 44 | `TOP-OF-PAGE DURING LINE-SELECTION` | `top_of_page_line_selection( )` - the header of every secondary list |
| 45 | `WRITE / 'Detail'` | `write( )` |
| 46 | `ULINE` | `list( )->uline( )` |
| 48 | `END-OF-PAGE` | `end_of_page( )` - the footer the runtime writes at the end of every page |
| 49 | `WRITE / 'continued'` | `write( )` |
| 51 | `START-OF-SELECTION` | `start_of_selection( )` |
| 54 | `IF s_skip IS NOT INITIAL AND gv_num IN s_skip` | `z2ui5_cl_cgui_context=>range_check( val range )` - IN outside ABAP SQL |
| 57 | `WRITE / gv_num HOTSPOT` | `write( )`, hotspot |
| 58 | `HIDE gv_num` | `hide = gv_num` at the hotspot of the line, restored in `at_line_selection( )` |
| 62 | `NEW-PAGE NO-HEADING` | `list( )->new_page( )` |
| 63 | `WRITE / 'Last page'` | `write( )` |
| 66 | `END-OF-SELECTION` | `end_of_selection( )` - the runtime runs it after `start_of_selection( )`, after its RETURN too |
| 67 | `WRITE / 'Count:'` | `write( )` |
| 67 | `WRITE gv_count` | `write( )` |
| 69 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 70 | `WRITE / 'Number'` | `write( )` |
| 70 | `WRITE gv_num` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_12` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_12` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_12_PAGES` report = `Z2UI5_CL_CGUI_R2C_12` text = `ZR2C_12_PAGES` semantic_object = `Z2UI5_CL_CGUI_R2C_12` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_12`.
4. Pin the behaviour with ABAP Unit tests before the next change.
