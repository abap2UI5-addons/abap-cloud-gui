# report2cloud: ZR2C_07_MESSAGES → z2ui5_cl_cgui_r2c_07

| | |
|---|---|
| Source | `zr2c_07_messages.prog.abap` |
| Text pool | none - texts are placeholders, see the TODOs |
| Result | **converted** - `z2ui5_cl_cgui_r2c_07.clas.abap`, `z2ui5_cl_cgui_r2c_07.clas.xml` |
| Mapped | 15 construct(s) |
| TODO | 2 |
| Release state to check | 1 object(s) |

## TODO

- no selection text in the text pool for P_TYPE, P_NUM - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )
- `zr2c_07_messages.prog.abap:27:7` - text symbol TEXT-001 is not in the text pool - the generated literal `TEXT-001` needs the real text

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `ZR2C` | message class | - | - |

## Not carried over

Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:

- MESSAGE ... DISPLAY LIKE 'E' - a status or info message displayed as an error becomes a warning (shown in the popover, the run goes on)

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 7 | `REPORT zr2c_07_messages MESSAGE-ID zr2c` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 11 | `PARAMETERS p_type TYPE c LENGTH 1 DEFAULT 'S' OBLIGATORY` | attribute `p_type`, `screen->parameter( )` |
| 12 | `PARAMETERS p_num TYPE i DEFAULT 42` | attribute `p_num`, `screen->parameter( )` |
| 14 | `AT SELECTION-SCREEN` | `at_selection_screen( )` |
| 16 | `MESSAGE e010 WITH p_type` | `MESSAGE ... INTO` + `message( )` |
| 19 | `MESSAGE ID 'ZR2C' TYPE 'E' NUMBER '011' WITH p_num 'is negative'` | `MESSAGE ... INTO` + `message( )` |
| 22 | `START-OF-SELECTION` | `start_of_selection( )` |
| 25 | `MESSAGE 'A status message' TYPE 'S'` | `message( )` |
| 27 | `MESSAGE TEXT-001 TYPE 'I'` | `message( )` |
| 29 | `MESSAGE w012(zr2c) WITH p_num` | `MESSAGE ... INTO` + `message( )` |
| 32 | `MESSAGE gv_text TYPE 'S' DISPLAY LIKE 'E'` | `message( )` |
| 34 | `MESSAGE s013 WITH p_num INTO gv_text` | `MESSAGE ... INTO` with the message class of MESSAGE-ID |
| 35 | `WRITE / 'Last message:'(002)` | `write( )` |
| 35 | `WRITE gv_text` | `write( )` |
| 36 | `MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-...` | `MESSAGE ... INTO` + `message( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_07` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_07` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_07_MESSAGES` report = `Z2UI5_CL_CGUI_R2C_07` text = `ZR2C_07_MESSAGES` semantic_object = `Z2UI5_CL_CGUI_R2C_07` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_07`.
4. Pin the behaviour with ABAP Unit tests before the next change.
