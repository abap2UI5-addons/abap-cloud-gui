# report2cloud: ZR2C_17_STATUS → z2ui5_cl_cgui_r2c_17

| | |
|---|---|
| Source | `zr2c_17_status.prog.abap` |
| Text pool | `zr2c_17_status.prog.xml` |
| Result | **converted** - `z2ui5_cl_cgui_r2c_17.clas.abap`, `z2ui5_cl_cgui_r2c_17.clas.xml` |
| Mapped | 15 construct(s) |
| TODO | 0 |
| Release state to check | 1 object(s) |

## Release state on ABAP Cloud

ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.

| Object | Kind | First use | Released successor (hint) |
|---|---|---|---|
| `SFLIGHT` | database table | `z2ui5_cl_cgui_r2c_17.clas.abap:9:40` | /DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own |

## Mapped

| Line | Classic | abap-cloud-gui |
|---|---|---|
| 8 | `REPORT zr2c_17_status` | the class, `INHERITING FROM z2ui5_cl_cgui_report` |
| 14 | `PARAMETERS p_carrid TYPE sflight-carrid DEFAULT 'LH'` | attribute `p_carrid`, `screen->parameter( )` |
| 15 | `PARAMETERS p_edit AS CHECKBOX` | attribute `p_edit`, `screen->checkbox( )` |
| 17 | `START-OF-SELECTION` | `start_of_selection( )` |
| 22 | `SET PF-STATUS 'LIST' EXCLUDING gt_excl` | `set_pf_status( )` - 2 function(s) of status LIST on the toolbar, 2 function key(s) as shortcuts; each arrives in `at_user_command( )` |
| 23 | `SET TITLEBAR 'T01' WITH p_carrid` | `set_title( )` - the text of title T01, the WITH values in a string template |
| 24 | `PERFORM show` | `show( )` |
| 26 | `AT USER-COMMAND` | `at_user_command( ucomm )` - sy-ucomm becomes ucomm |
| 29 | `PERFORM show` | `show( )` |
| 32 | `SET PF-STATUS 'LIST' EXCLUDING 'DELE'` | `set_pf_status( )` - 2 function(s) of status LIST on the toolbar, 2 function key(s) as shortcuts; each arrives in `at_user_command( )` |
| 33 | `WRITE / 'Flights without bookings deleted'` | `write( )` |
| 36 | `FORM show` | private method `show( )` |
| 41 | `WRITE / gs_flight-connid` | `write( )` |
| 41 | `WRITE gs_flight-fldate` | `write( )` |
| 41 | `WRITE gs_flight-seatsocc` | `write( )` |

## Launchpad tile

The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):

| | |
|---|---|
| Semantic object | `Z2UI5_CL_CGUI_R2C_17` |
| Action | `display` |
| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |
| ID | `z2ui5` |
| Parameter | `app_start` = `Z2UI5_CL_CGUI_R2C_17` |

Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):

```abap
( code = `ZR2C_17_STATUS` report = `Z2UI5_CL_CGUI_R2C_17` text = `ZR2C_17_STATUS` semantic_object = `Z2UI5_CL_CGUI_R2C_17` action = `display` )
```

## Next steps

1. Work through the TODOs above; replace every object of the release table by its released successor.
2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.
3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=z2ui5_cl_cgui_r2c_17`.
4. Pin the behaviour with ABAP Unit tests before the next change.
