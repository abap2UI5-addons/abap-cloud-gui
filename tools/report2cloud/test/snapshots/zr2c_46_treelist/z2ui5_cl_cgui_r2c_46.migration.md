# report2cloud: ZR2C_46_TREELIST → z2ui5_cl_cgui_r2c_46

| | |
|---|---|
| Source | `zr2c_46_treelist.prog.abap` |
| Text pool | `zr2c_46_treelist.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_46.clas.abap`, `z2ui5_cl_cgui_r2c_46.clas.xml` |
| Mapped | 11 construct(s) |
| TODO | 0 |
| Release state to check | 1 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SNODETEXT` | DDIC type | `z2ui5_cl_cgui_r2c_46.clas.abap:8:41` | - |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- RS_TREE_CONSTRUCT / RS_TREE_LIST_DISPLAY are the ALV tree of the report: tree( )->add_node( ) per row of the node table, TLEVEL the hierarchy, NAME and TEXT the text of the node, every node open; a click on a node raises at_tree_node( key value ) with the index of its row as value

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_46_treelist` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 12 | `START-OF-SELECTION` | `start_of_selection( )` |
| 13 | `PERFORM add USING 1 'Airlines' ''` | `add( )` |
| 14 | `PERFORM add USING 2 'LH' 'Lufthansa'` | `add( )` |
| 15 | `PERFORM add USING 3 '0400' 'Frankfurt - New York'` | `add( )` |
| 16 | `PERFORM add USING 3 '0402' 'Frankfurt - New York'` | `add( )` |
| 17 | `PERFORM add USING 2 'AA' 'American Airlines'` | `add( )` |
| 18 | `PERFORM add USING 3 '0017' 'New York - San Francisco'` | `add( )` |
| 20 | `CALL FUNCTION 'RS_TREE_CONSTRUCT' TABLES nodetab = gt_node` | `tree( )->add_node( )` per row of the node table - TLEVEL the hierarchy |
| 24 | `CALL FUNCTION 'RS_TREE_LIST_DISPLAY' EXPORTING callback_program = s...` | dropped - the tree of RS_TREE_CONSTRUCT is the output |
| 28 | `FORM add USING iv_level TYPE i iv_name TYPE c iv_text TYPE c` | private method `add( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_46` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_46` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_46_TREELIST` report = `Z2UI5_CL_CGUI_R2C_46` text = `ZR2C_46_TREELIST` semantic_object = `Z2UI5_CL_CGUI_R2C_46` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_46`.
4. Pin the behaviour with ABAP Unit tests before the next change.
