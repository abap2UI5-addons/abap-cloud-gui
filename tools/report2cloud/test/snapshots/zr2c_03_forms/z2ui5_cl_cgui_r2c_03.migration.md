# report2cloud: ZR2C_03_FORMS → z2ui5_cl_cgui_r2c_03

| | |
|---|---|
| Source | `zr2c_03_forms.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_03.clas.abap`, `z2ui5_cl_cgui_r2c_03.clas.xml` |
| Mapped | 27 construct(s) |
| TODO | 4 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for P_ITEMS, P_DISC, P_VAT - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_03_forms.prog.abap:62:1` - FORM total: the generic parameter iv_discount TYPE p is typed LIKE p_disc, the data object every PERFORM passes - the transpiled runtime has no generic packed type
- `zr2c_03_forms.prog.abap:62:1` - FORM total: the generic parameter cv_net TYPE p is typed LIKE gv_net, the data object every PERFORM passes - the transpiled runtime has no generic packed type
- `zr2c_03_forms.prog.abap:72:3` - LOOP AT ... WHERE with IN on a range became a CONTINUE at the top of the loop - sy-subrc after ENDLOOP is 0 when the table has lines, also when none matched

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_03_forms` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 24 | `PARAMETERS p_items TYPE i DEFAULT 5 OBLIGATORY` | attribute `p_items`, `screen->parameter( )` |
| 25 | `PARAMETERS p_disc TYPE p LENGTH 3 DECIMALS 2 DEFAULT '0.05'` | attribute `p_disc`, `screen->parameter( )` |
| 26 | `PARAMETERS p_vat AS CHECKBOX DEFAULT 'X'` | attribute `p_vat`, `screen->checkbox( )` |
| 28 | `AT SELECTION-SCREEN ON p_items` | `at_selection_screen_on( field )` - WHEN `P_ITEMS` |
| 30 | `MESSAGE 'Between 1 and 50 items' TYPE 'E'` | `message( )` |
| 33 | `START-OF-SELECTION` | `start_of_selection( )` |
| 34 | `PERFORM build_items USING p_items CHANGING gt_items` | `build_items( )` |
| 35 | `PERFORM total TABLES gt_items USING p_disc CHANGING gv_net` | `total( )` |
| 41 | `PERFORM output` | `output( )` |
| 46 | `FORM build_items USING VALUE(iv_count) TYPE i CHANGING ct_items TYP...` | private method `build_items( )` |
| 62 | `FORM total TABLES it_items STRUCTURE gs_template USING iv_discount ...` | private method `total( )` |
| 67 | `RANGES lr_big FOR ls_item-quantity` | `DATA ... RANGE OF` |
| 72 | `LOOP AT it_items INTO ls_item WHERE pos IN lr_pos` | `LOOP AT ...` and the WHERE as `IF ... CONTINUE. ENDIF.` at the top of the loop - `range_check( )` for the IN |
| 73 | `IF ls_item-quantity IN lr_big` | `z2ui5_cl_cgui_context=>range_check( val range )` - IN outside ABAP SQL |
| 84 | `FORM output` | private method `output( )` |
| 87 | `PERFORM write_item USING ls_item` | `write_item( )` |
| 89 | `ULINE` | `list( )->uline( )` |
| 90 | `WRITE / 'Net:'` | `write( )` |
| 90 | `WRITE gv_net` | `write( )` |
| 91 | `WRITE / 'Gross:'` | `write( )` |
| 91 | `WRITE gv_gross` | `write( )` |
| 94 | `FORM write_item USING is_item TYPE ty_item` | private method `write_item( )` |
| 95 | `WRITE / is_item-pos` | `write( )` |
| 95 | `WRITE is_item-product` | `write( )` |
| 95 | `WRITE is_item-quantity` | `write( )` |
| 95 | `WRITE is_item-price` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_03` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_03` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_03_FORMS` report = `Z2UI5_CL_CGUI_R2C_03` text = `ZR2C_03_FORMS` semantic_object = `Z2UI5_CL_CGUI_R2C_03` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_03`.
4. Pin the behaviour with ABAP Unit tests before the next change.
