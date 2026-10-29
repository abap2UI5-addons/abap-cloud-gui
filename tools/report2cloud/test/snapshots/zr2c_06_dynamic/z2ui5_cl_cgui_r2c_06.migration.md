# report2cloud: ZR2C_06_DYNAMIC → z2ui5_cl_cgui_r2c_06

| | |
|---|---|
| Source | `zr2c_06_dynamic.prog.abap` |
| Text pool | `zr2c_06_dynamic.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_06.clas.abap`, `z2ui5_cl_cgui_r2c_06.clas.xml` |
| Mapped | 46 construct(s) |
| TODO | 1 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for P_UNIT, P_SOURCE - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- SELECTION-SCREEN SKIP / ULINE / POSITION - the form lays out the fields by itself (2×)
- sy-repid / sy-cprog are the name of the report, 'ZR2C_06_DYNAMIC' - in a class they name the class pool

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_06_dynamic` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 10 | `TABLES sscrfields` | dropped - sscrfields-ucomm is the ucomm of at_selection_screen_ucomm( ) |
| 19 | `SELECTION-SCREEN BEGIN OF BLOCK mode WITH FRAME TITLE TEXT-m01` | `screen->block_begin( )` |
| 20 | `PARAMETERS p_disp RADIOBUTTON GROUP mode DEFAULT 'X' USER-COMMAND mode` | attribute `p_disp`, `screen->radiobutton( )` |
| 21 | `PARAMETERS p_crea RADIOBUTTON GROUP mode` | attribute `p_crea`, `screen->radiobutton( )` |
| 22 | `SELECTION-SCREEN END OF BLOCK mode` | `screen->block_end( )` |
| 24 | `SELECTION-SCREEN BEGIN OF BLOCK data WITH FRAME TITLE TEXT-d01` | `screen->block_begin( )` |
| 25 | `PARAMETERS p_matnr TYPE c LENGTH 18 MODIF ID dis` | attribute `p_matnr`, `screen->parameter( )` |
| 26 | `PARAMETERS p_name TYPE c LENGTH 40 LOWER CASE MODIF ID cre` | attribute `p_name`, `screen->parameter( )` |
| 27 | `PARAMETERS p_qty TYPE i MODIF ID cre` | attribute `p_qty`, `screen->parameter( )` |
| 28 | `SELECTION-SCREEN SKIP 1` | dropped - the selection screen has no blank lines, lines or positions |
| 29 | `SELECTION-SCREEN BEGIN OF LINE` | `screen->line_begin( )` |
| 30 | `SELECTION-SCREEN COMMENT 1(20) TEXT-l01 FOR FIELD p_unit` | the label of `screen->line_begin( )` |
| 31 | `PARAMETERS p_unit TYPE c LENGTH 3 DEFAULT 'PC'` | attribute `p_unit`, `screen->parameter( )` |
| 32 | `SELECTION-SCREEN END OF LINE` | `screen->line_end( )` |
| 33 | `SELECTION-SCREEN COMMENT /1(60) TEXT-c01 MODIF ID cre` | `screen->comment( )` |
| 34 | `PARAMETERS p_source TYPE string NO-DISPLAY` | attribute `p_source`, `screen->parameter( )` |
| 35 | `SELECTION-SCREEN END OF BLOCK data` | `screen->block_end( )` |
| 37 | `SELECTION-SCREEN BEGIN OF BLOCK expert WITH FRAME TITLE TEXT-e01` | `screen->block_begin( )` |
| 38 | `PARAMETERS p_expert AS CHECKBOX USER-COMMAND expert` | attribute `p_expert`, `screen->checkbox( )` |
| 39 | `PARAMETERS p_plant TYPE c LENGTH 4 MODIF ID exp` | attribute `p_plant`, `screen->parameter( )` |
| 40 | `PARAMETERS p_token TYPE c LENGTH 32 LOWER CASE MODIF ID exp` | attribute `p_token`, `screen->parameter( )` |
| 41 | `SELECTION-SCREEN ULINE` | dropped - the selection screen has no blank lines, lines or positions |
| 42 | `SELECTION-SCREEN PUSHBUTTON /1(20) b_reset USER-COMMAND reset` | `screen->button( )` - its USER-COMMAND arrives in `at_user_command( )` |
| 43 | `SELECTION-SCREEN END OF BLOCK expert` | `screen->block_end( )` |
| 45 | `INITIALIZATION` | `initialization( )` |
| 52 | `AT SELECTION-SCREEN OUTPUT` | `at_selection_screen_output( screen )` |
| 53 | `LOOP AT SCREEN` | `LOOP AT screen->loop_at_screen( ) INTO DATA(ls_screen)` - screen-* is ls_screen-*, '0'/'1' are abap_false/abap_true |
| 81 | `MODIFY SCREEN` | `screen->modify_screen( ls_screen )` |
| 84 | `AT SELECTION-SCREEN ON p_qty` | `at_selection_screen_on( field )` - WHEN `P_QTY` |
| 86 | `MESSAGE 'At most 9999 pieces' TYPE 'E'` | `message( )` |
| 89 | `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_plant` | `at_value_request( field )` - WHEN `P_PLANT`, the field declared with value_help |
| 90 | `CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' EXPORTING retfield = '...` | `value_help_popup( )` - the picked value is written into the field |
| 102 | `AT SELECTION-SCREEN` | `at_selection_screen( )` and `at_user_command( )` - both call `at_selection_screen_ucomm( ucomm )`, sy-ucomm becomes ucomm |
| 106 | `MESSAGE 'Selection screen reset' TYPE 'S'` | `message( )` |
| 113 | `START-OF-SELECTION` | `start_of_selection( )` |
| 115 | `WRITE / 'Material created:'` | `write( )` |
| 115 | `WRITE p_name` | `write( )` |
| 115 | `WRITE p_qty` | `write( )` |
| 117 | `WRITE / 'Material displayed:'` | `write( )` |
| 117 | `WRITE p_matnr` | `write( )` |
| 119 | `WRITE / 'Plant:'` | `write( )` |
| 119 | `WRITE p_plant` | `write( )` |
| 119 | `WRITE p_unit` | `write( )` |
| 120 | `WRITE / 'Started by:'` | `write( )` |
| 120 | `WRITE p_source` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_06` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_06` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_06_DYNAMIC` report = `Z2UI5_CL_CGUI_R2C_06` text = `ZR2C_06_DYNAMIC` semantic_object = `Z2UI5_CL_CGUI_R2C_06` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_06`.
4. Pin the behaviour with ABAP Unit tests before the next change.
