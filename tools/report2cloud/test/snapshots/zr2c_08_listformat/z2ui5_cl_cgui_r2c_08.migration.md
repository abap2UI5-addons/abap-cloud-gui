# report2cloud: ZR2C_08_LISTFORMAT → z2ui5_cl_cgui_r2c_08

| | |
|---|---|
| Source | `zr2c_08_listformat.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_08.clas.abap`, `z2ui5_cl_cgui_r2c_08.clas.xml` |
| Mapped | 27 construct(s) |
| TODO | 1 |
| Release state to check | 0 object(s) |

## TODO

- no selection text in the text pool for P_PAGES - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )

## Release state on ABAP Cloud

The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- FORMAT INTENSIFIED / INVERSE / INPUT - the list knows only the color and hotspots
- WRITE ... DD/MM/YYYY - the list writes the value in its default format
- ULINE AT pos(len) - the line spans the list

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_08_listformat NO STANDARD PAGE HEADING LINE-SIZE 80` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 20 | `PARAMETERS p_pages AS CHECKBOX DEFAULT 'X'` | attribute `p_pages`, `screen->checkbox( )` |
| 22 | `START-OF-SELECTION` | `start_of_selection( )` |
| 27 | `FORMAT COLOR COL_HEADING INTENSIFIED ON` | `lv_color`, passed to every `write( )` of the method |
| 28 | `WRITE /1 'Tasks'` | `write( )`, color |
| 28 | `WRITE 40 sy-datum DD/MM/YYYY` | `write( )`, color |
| 29 | `FORMAT RESET` | `lv_color`, passed to every `write( )` of the method |
| 30 | `ULINE AT /1(60)` | `list( )->uline( )` |
| 33 | `NEW-LINE` | `list( )->new_line( )` |
| 34 | `WRITE gs_task-done AS CHECKBOX` | `list( )->write_as_checkbox( )` |
| 36 | `WRITE icon_okay AS ICON` | `list( )->write_as_icon( )` |
| 37 | `FORMAT COLOR COL_POSITIVE` | `lv_color`, passed to every `write( )` of the method |
| 39 | `WRITE icon_red_light AS ICON` | `list( )->write_as_icon( )` |
| 40 | `FORMAT COLOR COL_NEGATIVE` | `lv_color`, passed to every `write( )` of the method |
| 43 | `WRITE 5(4) gs_task-id NO-GAP` | `write( )`, color |
| 44 | `WRITE 12 gs_task-title HOTSPOT ON` | `write( )`, color, hotspot |
| 45 | `WRITE 45 gs_task-due` | `write( )`, color |
| 46 | `FORMAT COLOR OFF` | `lv_color`, passed to every `write( )` of the method |
| 47 | `HIDE gs_task-id` | `hide = gs_task-id` at the hotspot of the line, restored in `at_line_selection( )` |
| 50 | `SKIP 2` | `list( )->skip( )` |
| 51 | `FORMAT HOTSPOT OFF` | `lv_color`, passed to every `write( )` of the method |
| 52 | `WRITE / 'Open tasks:'` | `write( )` |
| 52 | `WRITE gv_open COLOR 3` | `write( )`, color |
| 55 | `NEW-PAGE` | `list( )->new_page( )` |
| 56 | `WRITE / 'Second page'` | `write( )` |
| 59 | `AT LINE-SELECTION` | `at_line_selection( row hide )` - HIDE fields restored from `hide` |
| 62 | `MESSAGE \|Task { gs_task-id }: { gs_task-title }\| TYPE 'I'` | `message( )` |

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_08`.
4. Pin the behaviour with ABAP Unit tests before the next change.
