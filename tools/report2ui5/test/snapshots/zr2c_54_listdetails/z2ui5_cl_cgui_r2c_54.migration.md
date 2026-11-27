# report2UI5: ZR2C_54_LISTDETAILS → z2ui5_cl_cgui_r2c_54

| | |
|---|---|
| Source | `zr2c_54_listdetails.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_54.clas.abap`, `z2ui5_cl_cgui_r2c_54.clas.locals_imp.abap`, `z2ui5_cl_cgui_r2c_54.clas.xml` |
| Mapped | 45 construct(s) |
| TODO | 1 |

## TODO

- no selection text in the text pool for P_ID, P_CB, P_LIST, P_TOTAL - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 11 | `REPORT zr2c_54_listdetails NO STANDARD PAGE HEADING` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 27 | `DATA gt_item TYPE ty_item OCCURS 0 WITH HEADER LINE` | `DATA gt_item ... STANDARD TABLE OF` and the work area `wa_gt_item` - the header line is a work area |
| 33 | `PARAMETERS p_id TYPE c LENGTH 3` | attribute `p_id`, `screen->parameter( )` |
| 34 | `PARAMETERS p_cb AS CHECKBOX DEFAULT abap_true` | attribute `p_cb`, `screen->checkbox( )` |
| 35 | `PARAMETERS p_list RADIOBUTTON GROUP out` | attribute `p_list`, `screen->radiobutton( )` |
| 36 | `PARAMETERS p_total RADIOBUTTON GROUP out DEFAULT abap_true` | attribute `p_total`, `screen->radiobutton( )` |
| 38 | `CLASS lcl_lines DEFINITION` | locals_imp |
| 43 | `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_id` | `at_value_request( field )` - WHEN `P_ID`, the field declared with value_help |
| 46 | `CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' EXPORTING retfield = '...` | `value_help_popup( )` - the picked value is written into the field |
| 55 | `IF sy-subrc = 0` | dropped - the IF sy-subrc after F4IF_INT_TABLE_VALUE_REQUEST read RETURN_TAB gt_ret, value_help_popup( ) writes the field itself |
| 60 | `START-OF-SELECTION` | `start_of_selection( )` |
| 63 | `PERFORM mark_due USING gt_item[]` | `mark_due( )` |
| 65 | `FORMAT COLOR COL_HEADING` | applied to the following `write( )` calls of the method (color, hotspot, intensified, inverse, input) |
| 66 | `PERFORM header` | `header( )` |
| 67 | `FORMAT COLOR OFF` | applied to the following `write( )` calls of the method (color, hotspot, intensified, inverse, input) |
| 69 | `LOOP AT gt_item` | `INTO wa_gt_item` - the header line is a work area |
| 70 | `WRITE / gt_item-name` | `write( )` |
| 71 | `WRITE gt_item-amount CURRENCY gt_item-curr NO-ZERO RIGHT-JUSTIFIED` | `write( )` |
| 72 | `WRITE gt_item-due DD/MM/YYYY QUICKINFO 'Due date'` | `write( )` |
| 73 | `HIDE gt_item-id` | `list( )->hide( )` - the value of the current line, its texts hotspots; restored in `at_line_selection( )` |
| 73 | `HIDE gt_item-name` | `list( )->hide( )` - the value of the current line, its texts hotspots; restored in `at_line_selection( )` |
| 80 | `MESSAGE 'List written' TYPE gv_type` | `message( )` |
| 82 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 83 | `PERFORM detail` | `detail( )` |
| 85 | `FORM header` | private method `header( )` |
| 86 | `WRITE / 'Name'` | `write( )` |
| 86 | `WRITE 'Amount'` | `write( )` |
| 86 | `WRITE 'Due'` | `write( )` |
| 87 | `ULINE` | `list( )->uline( )` |
| 90 | `FORM detail` | private method `detail( )` |
| 92 | `WRITE / 'Item'` | `write( )` |
| 92 | `WRITE gt_item-id` | `write( )` |
| 92 | `WRITE gt_item-name` | `write( )` |
| 92 | `WRITE 'line'` | `write( )` |
| 92 | `WRITE sy-lilli` | `write( )` |
| 92 | `WRITE 'starts with'` | `write( )` |
| 92 | `WRITE gv_key` | `write( )` |
| 95 | `FORM mark_due USING ut_item TYPE ty_t_item` | private method `mark_due( )` |
| 105 | `CLASS lcl_lines IMPLEMENTATION` | locals_imp |
| 109 | `LOOP AT gt_item` | `INTO lcl_r2c=>app->wa_gt_item` - the header line is a work area |
| 112 | `SKIP` | `list( )->skip( )` |
| 115 | `WRITE / 'Total'` | `write( )` |
| 115 | `WRITE lv_total INTENSIFIED` | `write( )` |
| 116 | `HIDE gt_item-id` | `list( )->hide( )` - the value of the current line, its texts hotspots; restored in `at_line_selection( )` |
| 116 | `HIDE gt_item-name` | `list( )->hide( )` - the value of the current line, its texts hotspots; restored in `at_line_selection( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_54` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_54` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_54_LISTDETAILS` report = `Z2UI5_CL_CGUI_R2C_54` text = `ZR2C_54_LISTDETAILS` semantic_object = `Z2UI5_CL_CGUI_R2C_54` action = `display` )
```

## Next steps

1. Work through the TODOs above.
2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_54`.
