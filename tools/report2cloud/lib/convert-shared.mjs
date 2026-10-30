// The shared half of the converter: the tables (what is refused, mapped,
// the stand-ins, the frontend services, the SALV mapping, the colours and
// icons), and the helpers over the syntax tree and the rendering that the
// families of convert-*.mjs and the Converter of convert.mjs use. Nothing
// here knows the Converter; convert.mjs re-exports what the tests and the
// CLI import.
import {
  after, child, children, findAll, isToken, key, kind, lc, literal, nodeText, renderTokens,
  stmtTokens, uc, unquote, words,
} from "./abap.mjs";

export const UNCATALOGUED = new Set();


// the event blocks of a report
export const EVENTS = new Set(["Initialization", "LoadOfProgram", "AtSelectionScreen", "StartOfSelection",
  "EndOfSelection", "AtLineSelection", "AtUserCommand", "TopOfPage", "EndOfPage", "AtPF", "Get"]);

// declarations that are global in a report wherever they stand
export const DECL = new Set(["Data", "DataBegin", "DataEnd", "Type", "TypeBegin", "TypeEnd", "IncludeType",
  "Constant", "ConstantBegin", "ConstantEnd", "Tables", "Parameter", "SelectOption", "SelectionScreen",
  "Ranges", "FieldSymbol", "TypePools", "TypePool", "Nodes", "Controls", "StaticBegin", "StaticEnd", "Static",
  "TypeEnum", "TypeEnumBegin", "TypeEnumEnd"]);

// statements converted in one place only - refused anywhere else
export const REFUSED_LIST = {
  GetCursor: "GET CURSOR outside of AT LINE-SELECTION, or with LENGTH / AREA - get_cursor( ) returns the field, value, line and offset of the click of a line selection - port it by hand",
};

// statements with no counterpart - refused wherever they stand
export const REFUSED = {
  CallScreen: "CALL SCREEN - the dynpro is not converted (a dynpro of fields is, from the .prog.xml - see the MODULE refusals); else build the screen as an abap2UI5 view or a popup",
  SetScreen: "SET SCREEN - dynpro flow logic has no counterpart",
  CallDialog: "CALL DIALOG - dialog modules have no counterpart",
  CallTransaction: "CALL TRANSACTION ... USING - batch input plays the screens of a transaction, there are none in a browser app and batch input is no API on ABAP Cloud; call the released API of the application instead",
  ExecSQL: "EXEC SQL - native SQL is not available on ABAP Cloud; use ABAP SQL on a released CDS view",
  Module: "MODULE - the .prog.xml has no screens (DYNPROS); a dynpro of fields is converted from them",
  Include: "INCLUDE - no such include beside the report (as <include>.prog.abap, the name abapGit writes); put it there, or name its folder with --includes",
  Nodes: "NODES - logical databases have no counterpart; read the data with ABAP SQL",
  Get: "GET - logical database events have no counterpart; read the data with ABAP SQL",
  Reject: "REJECT - logical database statement",
  Controls: "CONTROLS - table controls and tabstrips belong to dynpros",
  ReadLine: "READ LINE ... INDEX / OF PAGE, READ CURRENT LINE outside AT LINE-SELECTION - not converted; read_list( )->read_field( ) reads a field of a line of the list - port it by hand, or keep the data in an internal table",
  ModifyLine: "MODIFY LINE ... INDEX / OF PAGE / LINE VALUE FROM, MODIFY CURRENT LINE outside AT LINE-SELECTION - not converted; read_list( )->modify_field( ) changes a field of a written line - port it by hand",
  SetUserCommand: "SET USER-COMMAND - triggers no event here",
  PrintControl: "PRINT-CONTROL - printing is not supported",
  CallSubscreen: "CALL SUBSCREEN - dynpro statement",
  Local: "LOCAL - not available in methods",
  ScrollList: "SCROLL LIST - the list has no scroll position",
  Communication: "COMMUNICATION - CPI-C is obsolete",
  CallKernel: "CALL - system functions are not available",
  SystemCall: "SYSTEM-CALL - not available",
  EditorCall: "EDITOR-CALL - SAP GUI editor",
  GenerateReport: "GENERATE REPORT - dynamic programs are not available on ABAP Cloud",
  GenerateSubroutine: "GENERATE SUBROUTINE POOL - dynamic programs are not available on ABAP Cloud",
  InsertReport: "INSERT REPORT - dynamic programs are not available on ABAP Cloud",
  Supply: "SUPPLY - contexts are obsolete",
  Demand: "DEMAND - contexts are obsolete",
  Contexts: "CONTEXTS - contexts are obsolete",
  CreateOLE: "CREATE OBJECT ... OLE - SAP GUI desktop integration",
  CallOLE: "CALL METHOD OF - SAP GUI desktop integration",
  SetProperty: "SET PROPERTY OF - SAP GUI desktop integration",
  GetProperty: "GET PROPERTY OF - SAP GUI desktop integration",
};

// the synchronous popups - a popup of the runtime, the block cut at the call
export const POPUPS = new Set(["POPUP_TO_CONFIRM", "POPUP_TO_CONFIRM_STEP", "POPUP_TO_DECIDE", "POPUP_TO_DECIDE_LIST", "POPUP_GET_VALUES"]);

// function modules with no counterpart on a browser app - refused
export const REFUSED_FUNCTIONS = {
  POPUP_TO_CONFIRM_WITH_MESSAGE: "POPUP_TO_CONFIRM_WITH_MESSAGE waits for the answer and shows a T100 message - use popup_to_decide( ) with the message text and go on in at_user_command( )",
  POPUP_TO_DECIDE_WITH_MESSAGE: "POPUP_TO_DECIDE_WITH_MESSAGE waits for the answer and shows a T100 message - use popup_to_decide( ) with the message text and go on in at_user_command( )",
  POPUP_GET_VALUES_DB_CHECKED: "POPUP_GET_VALUES_DB_CHECKED waits for the input and checks it against the DDIC - use popup_get_values( ) and check in at_user_command( )",
  GUI_DOWNLOAD: "GUI_DOWNLOAD writes to the SAP GUI frontend; offer the file with an abap2UI5 download instead",
  GUI_UPLOAD: "GUI_UPLOAD reads from the SAP GUI frontend; use an abap2UI5 file uploader instead",
  WS_DOWNLOAD: "WS_DOWNLOAD writes to the SAP GUI frontend",
  WS_UPLOAD: "WS_UPLOAD reads from the SAP GUI frontend",
  F4IF_FIELD_VALUE_REQUEST: "F4IF_FIELD_VALUE_REQUEST calls a search help; answer F4 with value_help_popup( ) on a table",
  RS_REFRESH_FROM_SELECTOPTIONS: "RS_REFRESH_FROM_SELECTOPTIONS reads dynpro fields; the attributes hold the values",
  DYNP_VALUES_READ: "DYNP_VALUES_READ without TABLES dynpfields - the attributes hold the values",
  DYNP_VALUES_UPDATE: "DYNP_VALUES_UPDATE without TABLES dynpfields - set the attributes instead",
  BDC_OPEN_GROUP: "batch input sessions have no counterpart on ABAP Cloud",
  BDC_INSERT: "batch input sessions have no counterpart on ABAP Cloud",
  BDC_CLOSE_GROUP: "batch input sessions have no counterpart on ABAP Cloud",
  REUSE_ALV_HIERSEQ_LIST_DISPLAY: "a hierarchical sequential list is not supported by the ALV of abap-cloud-gui",
  REUSE_ALV_POPUP_TO_SELECT: "the ALV popup waits for the selection; use value_help_popup( ) or z2ui5_cl_popup_to_select",
};

// statements that only lay out or decorate a list or screen - dropped, noted
export const LAYOUT_ONLY = {
  Back: "BACK - the list has no columns",
  Summary: "SUMMARY - the list knows no intensified output",
  Detail: "DETAIL - the list knows no intensified output",
  SetLeft: "SET LEFT SCROLL-BOUNDARY - the list does not scroll horizontally",
  SetMargin: "SET MARGIN - printing is not supported",
  SetBlank: "SET BLANK LINES - the list writes no blank lines",
};

// FORMAT COLOR / WRITE COLOR - the colors of the list are UI5 value states
export const COLORS = {
  COL_BACKGROUND: "none", 0: "none", OFF: "none",
  COL_HEADING: "key", 1: "key",
  COL_NORMAL: "none", 2: "none",
  COL_TOTAL: "total", 3: "total",
  COL_KEY: "key", 4: "key",
  COL_POSITIVE: "positive", 5: "positive",
  COL_NEGATIVE: "negative", 6: "negative",
  COL_GROUP: "total", 7: "total",
};
export const colorConst = (c) => `z2ui5_cl_cgui_list=>cs_color-${c}`;

// WRITE ... AS ICON with an icon of type pool ICON - the UI5 icon that shows
// the same, from the icons that exist in UI5 1.71
export const ICONS = {
  icon_increase: "sap-icon://add", icon_decrease: "sap-icon://less",
  icon_okay: "sap-icon://accept", icon_checked: "sap-icon://accept", icon_cancel: "sap-icon://decline",
  icon_incomplete: "sap-icon://decline", icon_green_light: "sap-icon://status-positive",
  icon_yellow_light: "sap-icon://status-critical", icon_red_light: "sap-icon://status-negative",
  icon_led_green: "sap-icon://status-positive", icon_led_yellow: "sap-icon://status-critical",
  icon_led_red: "sap-icon://status-negative", icon_led_inactive: "sap-icon://status-inactive",
  icon_light_out: "sap-icon://status-inactive", icon_delete: "sap-icon://delete",
  icon_create: "sap-icon://create", icon_change: "sap-icon://edit", icon_display: "sap-icon://display",
  icon_warning: "sap-icon://warning", icon_message_warning: "sap-icon://warning",
  icon_error: "sap-icon://error", icon_message_error: "sap-icon://error",
  icon_information: "sap-icon://message-information", icon_message_information: "sap-icon://message-information",
  icon_failure: "sap-icon://error", icon_locked: "sap-icon://locked", icon_unlocked: "sap-icon://unlocked",
  icon_mail: "sap-icon://email", icon_print: "sap-icon://print", icon_refresh: "sap-icon://refresh",
  icon_search: "sap-icon://search", icon_settings: "sap-icon://action-settings",
  icon_system_save: "sap-icon://save", icon_export: "sap-icon://download", icon_filter: "sap-icon://filter",
  icon_sort_up: "sap-icon://sort-ascending", icon_sort_down: "sap-icon://sort-descending",
  icon_detail: "sap-icon://detail-view", icon_insert_row: "sap-icon://add", icon_delete_row: "sap-icon://less",
  icon_copy_object: "sap-icon://copy", icon_check: "sap-icon://accept",
};

// the row types of the classic grid - ABAP Cloud has no LVC types; the ALV
// of the runtime has the same lines
export const LVC_TYPES = {
  lvc_t_row: "z2ui5_cl_cgui_alv=>ty_t_lvc_row", lvc_s_row: "z2ui5_cl_cgui_alv=>ty_s_lvc_row",
  lvc_t_roid: "z2ui5_cl_cgui_alv=>ty_t_lvc_roid", lvc_s_roid: "z2ui5_cl_cgui_alv=>ty_s_lvc_roid",
  lvc_s_col: "z2ui5_cl_cgui_alv=>ty_s_lvc_col",
  // the file table of cl_gui_frontend_services=>file_open_dialog( )
  filetable: "z2ui5_cl_cgui_frontend=>ty_t_file_table", file_table: "z2ui5_cl_cgui_frontend=>ty_s_file_table",
  // the events a SAP GUI control registers - set_registered_events( )
  cntl_simple_events: "z2ui5_cl_cgui_gui=>ty_t_simple_events", cntl_simple_event: "z2ui5_cl_cgui_gui=>ty_s_simple_event",
  // the lines of POPUP_TO_DECIDE_LIST
  spopli: "z2ui5_cl_cgui_popup=>ty_s_spopli",
  // the nodes of cl_gui_simple_tree
  mtreesnode: "z2ui5_cl_cgui_gui_simple_tree=>ty_s_node", tv_nodekey: "z2ui5_cl_cgui_gui_simple_tree=>ty_node_key",
  // the nodes, items and header of cl_gui_column_tree
  treev_node: "z2ui5_cl_cgui_gui_simple_tree=>ty_s_node", treev_ntab: "z2ui5_cl_cgui_gui_simple_tree=>ty_t_node",
  mtreeitm: "z2ui5_cl_cgui_gui_column_tree=>ty_s_item", treev_hhdr: "z2ui5_cl_cgui_gui_column_tree=>ty_s_hhdr",
  tv_itmname: "z2ui5_cl_cgui_gui_column_tree=>ty_item_name",
};

// the statements that open and close a block
export const OPENERS = new Set(["If", "Case", "Loop", "Do", "While", "SelectLoop", "Try", "At", "AtFirst", "AtLast", "OnChange", "Provide", "LoopAtScreen"]);
export const CLOSERS = new Set(["EndIf", "EndCase", "EndLoop", "EndDo", "EndWhile", "EndSelect", "EndTry", "EndAt", "EndOn", "EndProvide"]);

// SAP GUI controls - they need a dynpro container
export const GUI_CONTROL = /\bcl_gui_(alv_grid|custom_container|docking_container|splitter_container|dialogbox_container|container|html_viewer|textedit|picture|toolbar|simple_tree|column_tree|list_tree|gos_container|easy_splitter_container|calendar|abapedit|chart_engine|barchart)\b/;

// z2ui5_cl_cgui_frontend - CL_GUI_FRONTEND_SERVICES in the browser: its
// constants and methods, the parameters and classic exceptions of each. A
// call of cl_gui_frontend_services=> becomes a call of it when it names
// only these; a test compares the table with the class
export const FRONTEND = {
  constants: ["action_ok", "action_cancel", "filetype_all", "filetype_text", "filetype_excel", "filetype_xml", "filetype_html"],
  methods: {
    scms_binary_to_xstring: { params: ["input_length", "first_line", "last_line", "binary_tab", "buffer"],
      exceptions: ["failed"] },
    scms_xstring_to_binary: { params: ["buffer", "append_to_table", "output_length", "binary_tab"],
      exceptions: [] },
    scms_string_to_xstring: { params: ["text", "mimetype", "encoding", "buffer"],
      exceptions: ["failed"] },
    ssfc_base64_encode: { params: ["bindata", "binleng", "b64data"],
      exceptions: ["ssf_krn_error", "ssf_krn_noop", "ssf_krn_nomemory", "ssf_krn_opinv", "ssf_krn_input_data_error", "ssf_krn_invalid_par", "ssf_krn_invalid_parlen"] },
    ssfc_base64_decode: { params: ["b64data", "b64leng", "b64_strict", "bindata"],
      exceptions: ["ssf_krn_error", "ssf_krn_noop", "ssf_krn_nomemory", "ssf_krn_opinv", "ssf_krn_input_data_error", "ssf_krn_invalid_par", "ssf_krn_invalid_parlen"] },
    dp_create_url: { params: ["type", "subtype", "size", "date", "time", "description", "lifetime", "cacheable", "send_data_as_string", "data", "url"],
      exceptions: ["dp_invalid_parameter", "dp_error_put_table", "dp_error_general"] },
    url_content: { params: ["url"],
      exceptions: [] },
    file_open_dialog: { params: ["window_title", "default_extension", "default_filename", "file_filter", "with_encoding", "initial_directory", "multiselection", "file_table", "rc", "user_action", "file_encoding"],
      exceptions: ["file_open_dialog_failed", "cntl_error", "error_no_gui", "not_supported_by_gui"] },
    file_save_dialog: { params: ["window_title", "default_extension", "default_file_name", "with_encoding", "file_filter", "initial_directory", "prompt_on_overwrite", "filename", "path", "fullpath", "user_action", "file_encoding"],
      exceptions: ["cntl_error", "error_no_gui", "not_supported_by_gui", "invalid_default_file_name"] },
    directory_browse: { params: ["window_title", "initial_folder", "selected_folder"],
      exceptions: ["cntl_error", "error_no_gui", "not_supported_by_gui"] },
    gui_upload: { params: ["filename", "filetype", "has_field_separator", "header_length", "read_by_line", "dat_mode", "codepage", "ignore_cerr", "replacement", "virus_scan_profile", "filelength", "header", "data_tab", "isscanperformed"],
      exceptions: ["file_open_error", "file_read_error", "no_batch", "gui_refuse_filetransfer", "invalid_type", "no_authority", "unknown_error", "bad_data_format", "header_not_allowed", "separator_not_allowed", "header_too_long", "unknown_dp_error", "access_denied", "dp_out_of_memory", "disk_full", "dp_timeout", "not_supported_by_gui", "error_no_gui"] },
    gui_download: { params: ["bin_filesize", "filename", "filetype", "append", "write_field_separator", "header", "trunc_trailing_blanks", "write_lf", "col_select", "col_select_mask", "dat_mode", "confirm_overwrite", "no_auth_check", "codepage", "ignore_cerr", "replacement", "write_bom", "trunc_trailing_blanks_eol", "show_transfer_status", "fieldnames", "write_lf_after_last_line", "virus_scan_profile", "filelength", "data_tab"],
      exceptions: ["file_write_error", "no_batch", "gui_refuse_filetransfer", "invalid_type", "no_authority", "unknown_error", "header_not_allowed", "separator_not_allowed", "filesize_not_allowed", "header_too_long", "dp_error_create", "dp_error_send", "dp_error_write", "unknown_dp_error", "access_denied", "dp_out_of_memory", "disk_full", "dp_timeout", "file_not_found", "dataprovider_exception", "control_flush_error", "not_supported_by_gui", "error_no_gui"] },
    get_gui_version: { params: ["version_table", "rc"],
      exceptions: ["get_gui_version_failed", "cant_write_version_table", "gui_no_version", "cntl_error", "error_no_gui", "not_supported_by_gui"] },
    get_file_separator: { params: ["file_separator"],
      exceptions: ["not_supported_by_gui", "error_no_gui", "cntl_error"] },
    get_desktop_directory: { params: ["desktop_directory"],
      exceptions: ["cntl_error", "error_no_gui", "not_supported_by_gui"] },
    get_temp_directory: { params: ["temp_dir"],
      exceptions: ["cntl_error", "error_no_gui", "not_supported_by_gui"] },
    get_sapgui_workdir: { params: ["sapworkdir"],
      exceptions: ["get_sapworkdir_failed", "cntl_error", "error_no_gui", "not_supported_by_gui"] },
    get_system_directory: { params: ["system_directory"],
      exceptions: ["cntl_error", "error_no_gui", "not_supported_by_gui"] },
    directory_list_files: { params: ["directory", "filter", "files_only", "directories_only", "file_table", "count"],
      exceptions: ["cntl_error", "directory_list_files_failed", "wrong_parameter", "error_no_gui", "not_supported_by_gui"] },
    directory_get_current: { params: ["current_directory"],
      exceptions: ["directory_get_current_failed", "cntl_error", "error_no_gui", "not_supported_by_gui"] },
    file_exist: { params: ["file"],
      exceptions: ["cntl_error", "error_no_gui", "wrong_parameter", "not_supported_by_gui"] },
    directory_exist: { params: ["directory"],
      exceptions: ["cntl_error", "error_no_gui", "wrong_parameter", "not_supported_by_gui"] },
    directory_create: { params: ["directory", "rc"],
      exceptions: ["directory_create_failed", "cntl_error", "error_no_gui", "directory_access_denied", "directory_already_exists", "path_not_found", "unknown_error", "not_supported_by_gui", "wrong_parameter"] },
    execute: { params: ["document", "application", "parameter", "default_directory", "maximized", "minimized", "synchronous", "operation"],
      exceptions: ["cntl_error", "error_no_gui", "bad_parameter", "file_not_found", "path_not_found", "file_extension_unknown", "error_execute_failed", "synchronous_failed", "not_supported_by_gui"] },
    clipboard_export: { params: ["no_auth_check", "data", "rc"],
      exceptions: ["cntl_error", "error_no_gui", "not_supported_by_gui", "no_authority"] },
    text_to_table: { params: ["text", "separator", "data_tab"],
      exceptions: [] },
    table_to_text: { params: ["data_tab", "separator", "last_line_end"],
      exceptions: [] },
    set_files: { params: ["files"],
      exceptions: [] },
    file_name: { params: ["path"],
      exceptions: [] },
  },
};

// the function modules of the frontend, as methods of z2ui5_cl_cgui_frontend
export const FRONTEND_FUNCTIONS = { GUI_UPLOAD: "gui_upload", GUI_DOWNLOAD: "gui_download", DP_CREATE_URL: "dp_create_url",
  SCMS_BINARY_TO_XSTRING: "scms_binary_to_xstring", SCMS_XSTRING_TO_BINARY: "scms_xstring_to_binary",
  SCMS_STRING_TO_XSTRING: "scms_string_to_xstring", SSFC_BASE64_ENCODE: "ssfc_base64_encode", SSFC_BASE64_DECODE: "ssfc_base64_decode" };
// the TABLES parameters of FRONTEND_FUNCTIONS that are CHANGING of the method - the others it only reads
export const FRONTEND_TABLES_OUT = new Set(["GUI_UPLOAD.data_tab", "GUI_DOWNLOAD.data_tab", "SCMS_XSTRING_TO_BINARY.binary_tab"]);

/**
 * The stand-ins of the SAP GUI controls (src/01/z2ui5_cl_cgui_gui*) - the
 * class of a report's control becomes one of them, a member of the control
 * they do not have is refused. members are their public constants,
 * attributes and methods with parameters and exceptions; a test compares
 * them with the classes.
 */
export const GUI = {
  classes: {
    cl_gui_control: "z2ui5_cl_cgui_gui",
    cl_gui_container: "z2ui5_cl_cgui_gui_container",
    cl_gui_custom_container: "z2ui5_cl_cgui_gui_container",
    cl_gui_docking_container: "z2ui5_cl_cgui_gui_container",
    cl_gui_splitter_container: "z2ui5_cl_cgui_gui_container",
    cl_gui_dialogbox_container: "z2ui5_cl_cgui_gui_container",
    cl_gui_gos_container: "z2ui5_cl_cgui_gui_container",
    cl_gui_easy_splitter_container: "z2ui5_cl_cgui_gui_easy_split",
    cl_gui_textedit: "z2ui5_cl_cgui_gui_textedit",
    cl_gui_html_viewer: "z2ui5_cl_cgui_gui_html_viewer",
    cl_gui_toolbar: "z2ui5_cl_cgui_gui_toolbar",
    cl_gui_picture: "z2ui5_cl_cgui_gui_picture",
    cl_gui_simple_tree: "z2ui5_cl_cgui_gui_simple_tree",
    cl_gui_column_tree: "z2ui5_cl_cgui_gui_column_tree",
    cl_gui_list_tree: "z2ui5_cl_cgui_gui_list_tree",
    cl_gui_alv_grid: "z2ui5_cl_cgui_gui_alv_grid",
    cl_alv_event_toolbar_set: "z2ui5_cl_cgui_gui_alv_toolbar",
  },
  members: {
    z2ui5_cl_cgui_gui: {
      constants: ["true", "false", "metric_default", "metric_pixel", "metric_mm", "ws_tabstop", "ws_maximizebox", "ws_group", "ws_minimizebox", "ws_thickframe", "ws_sysmenu", "ws_dlgframe", "ws_border", "ws_caption", "ws_maximize", "ws_clipchildren", "ws_clipsiblings", "ws_visible", "ws_child", "visible_true", "visible_false"],
      attributes: [],
      events: [],
      methods: {
        compute_metric_from_dynp: { params: ["metric", "x_or_y", "in"],
          exceptions: [] },
        get_cursor_field: { params: ["field", "value", "line", "offset"],
          exceptions: ["not_on_field"] },
        set_report: { params: ["report"],
          exceptions: [] },
        get_report: { params: [],
          exceptions: [] },
        set_focus: { params: ["control"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_visible: { params: ["visible"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        free: { params: [],
          exceptions: ["cntl_error", "cntl_system_error"] },
        get_id: { params: [],
          exceptions: [] },
        set_handler: { params: ["event", "method", "handler", "class", "activation"],
          exceptions: [] },
        dispatch: { params: ["event", "value", "post"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_container: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["dock_at_left", "dock_at_top", "dock_at_right", "dock_at_bottom", "mode_absolute", "mode_relative", "type_movable", "type_sashvisible", "orientation_vertical", "orientation_horizontal", "lifetime_imode", "lifetime_dynpro", "lifetime_default"],
      attributes: ["default_screen", "screen0", "top_left_container", "bottom_right_container"],
      events: ["close"],
      methods: {
        constructor: { params: ["parent", "container_name", "style", "lifetime", "repid", "dynnr", "no_autodef_progid_dynnr", "side", "extension", "ratio", "metric", "caption", "name", "rows", "columns", "align", "link_dynnr", "link_repid", "orientation", "sash_position", "with_border", "width", "height", "top", "left"],
          exceptions: ["cntl_error", "cntl_system_error", "create_error", "lifetime_error", "lifetime_dynpro_dynpro_link", "cntl_install_error", "illegal_event_combination"] },
        get_container: { params: ["row", "column"],
          exceptions: [] },
        set_row_height: { params: ["id", "height"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_column_width: { params: ["id", "width"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_row_mode: { params: ["mode"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_column_mode: { params: ["mode"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_row_sash: { params: ["id", "type", "value"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_column_sash: { params: ["id", "type", "value"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_extension: { params: ["extension"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_caption: { params: ["caption"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_top: { params: ["top"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_left: { params: ["left"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_width: { params: ["width"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_height: { params: ["height"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        set_metric: { params: ["metric"],
          exceptions: ["cntl_error", "cntl_system_error"] },
        link: { params: ["repid", "dynnr", "container"],
          exceptions: ["cntl_error", "cntl_system_error", "lifetime_dynpro_dynpro_link"] },
      },
    },
    z2ui5_cl_cgui_gui_easy_split: {
      parent: "z2ui5_cl_cgui_gui_container",
      constants: [],
      attributes: [],
      events: [],
      methods: {
        constructor: { params: ["parent", "orientation", "sash_position", "with_border", "lifetime", "name"],
          exceptions: ["cntl_error", "cntl_system_error"] },
      },
    },
    z2ui5_cl_cgui_gui_textedit: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["wordwrap_off", "wordwrap_at_windowborder", "wordwrap_at_fixed_position", "dropfile_event_off", "dropfile_event_single", "dropfile_event_multiple", "event_double_click", "event_f1", "event_f4"],
      attributes: [],
      events: ["f1", "f4", "dblclick"],
      methods: {
        constructor: { params: ["max_number_chars", "style", "wordwrap_mode", "wordwrap_position", "wordwrap_to_linebreak_mode", "filedrop_mode", "parent", "lifetime", "name"],
          exceptions: ["error_cntl_create", "error_cntl_init", "error_cntl_link", "error_dp_create", "gui_type_not_supported"] },
        set_textstream: { params: ["text"],
          exceptions: ["error_cntl_call_method", "not_supported_by_gui"] },
        get_textstream: { params: ["only_when_modified", "text", "is_modified"],
          exceptions: ["error_cntl_call_method", "not_supported_by_gui"] },
        set_text_as_r3table: { params: ["table"],
          exceptions: ["error_dp", "error_dp_create"] },
        get_text_as_r3table: { params: ["only_when_modified", "table", "is_modified"],
          exceptions: ["error_dp", "error_cntl_call_method", "error_dp_create", "potential_data_loss"] },
        set_text_as_stream: { params: ["text"],
          exceptions: ["error_dp", "error_dp_create"] },
        get_text_as_stream: { params: ["only_when_modified", "text", "is_modified"],
          exceptions: ["error_dp", "error_cntl_call_method"] },
        delete_text: { params: [],
          exceptions: ["error_cntl_call_method"] },
        set_readonly_mode: { params: ["readonly_mode"],
          exceptions: ["error_cntl_call_method", "invalid_parameter"] },
        set_toolbar_mode: { params: ["toolbar_mode"],
          exceptions: ["error_cntl_call_method", "invalid_parameter"] },
        set_statusbar_mode: { params: ["statusbar_mode"],
          exceptions: ["error_cntl_call_method", "invalid_parameter"] },
        set_registered_events: { params: ["events"],
          exceptions: ["cntl_error", "cntl_system_error", "illegal_event_combination"] },
        get_selection_pos: { params: ["from_line", "from_pos", "to_line", "to_pos"],
          exceptions: ["error_cntl_call_method"] },
        set_selection_pos: { params: ["from_line", "from_pos", "to_line", "to_pos"],
          exceptions: ["error_cntl_call_method"] },
        set_font_fixed: { params: ["mode"],
          exceptions: ["error_cntl_call_method", "invalid_parameter"] },
        set_wordwrap_behavior: { params: ["wordwrap_mode", "wordwrap_position", "wordwrap_to_linebreak_mode"],
          exceptions: ["error_cntl_call_method"] },
        get_textmodified_status: { params: ["status"],
          exceptions: ["error_cntl_call_method"] },
        set_textmodified_status: { params: ["status"],
          exceptions: ["error_cntl_call_method"] },
      },
    },
    z2ui5_cl_cgui_gui_html_viewer: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["m_id_sapevent"],
      attributes: [],
      events: ["sapevent"],
      methods: {
        constructor: { params: ["shellstyle", "parent", "lifetime", "saphtmlp", "uiflag", "end_session_with_browser", "name", "saphttp", "query_table_disabled"],
          exceptions: ["cntl_error", "cntl_install_error", "dp_install_error", "dp_error"] },
        load_data: { params: ["url", "type", "subtype", "size", "encoding", "charset", "needfiltering", "language", "i_tidyt", "assigned_url", "data_table"],
          exceptions: ["dp_invalid_parameter", "dp_error_general", "cntl_error", "html_syntax_notcorrect"] },
        show_url: { params: ["url", "frame", "in_place"],
          exceptions: ["cntl_error", "cnht_error_not_allowed", "cnht_error_parameter", "dp_error_general"] },
        show_data: { params: ["url", "frame", "in_place"],
          exceptions: ["cntl_error", "cnht_error_not_allowed", "cnht_error_parameter", "dp_error_general"] },
        go_back: { params: [],
          exceptions: ["cntl_error"] },
        go_forward: { params: [],
          exceptions: ["cntl_error"] },
        get_current_url: { params: ["url"],
          exceptions: ["cntl_error"] },
        set_registered_events: { params: ["events"],
          exceptions: ["cntl_error", "cntl_system_error", "illegal_event_combination"] },
        close_document: { params: [],
          exceptions: ["cntl_error"] },
        enable_sapsso: { params: ["enabled"],
          exceptions: ["cntl_error"] },
        show_url_in_browser: { params: ["url"],
          exceptions: ["cntl_error"] },
        detach_url_in_browser: { params: ["url"],
          exceptions: ["cntl_error"] },
        dispatch: { params: [],
          exceptions: [] },
        sapevent_links: { params: ["html"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_table: {
      parent: "z2ui5_cl_cgui_gui",
      constants: [],
      attributes: [],
      events: ["added_function", "double_click", "link_click"],
      methods: {
        factory: { params: ["list_display", "r_container", "container_name", "r_salv_table", "t_table"],
          exceptions: [] },
        constructor: { params: ["container"],
          exceptions: [] },
        display: { params: [],
          exceptions: [] },
        refresh: { params: ["s_stable", "refresh_mode", "t_table"],
          exceptions: [] },
        set_data: { params: ["t_table"],
          exceptions: [] },
        get_columns: { params: [],
          exceptions: [] },
        get_display_settings: { params: [],
          exceptions: [] },
        get_functions: { params: [],
          exceptions: [] },
        get_selections: { params: [],
          exceptions: [] },
        get_sorts: { params: [],
          exceptions: [] },
        get_aggregations: { params: [],
          exceptions: [] },
        get_layout: { params: [],
          exceptions: [] },
        get_filters: { params: [],
          exceptions: [] },
        get_print: { params: [],
          exceptions: [] },
        get_functional_settings: { params: [],
          exceptions: [] },
        get_event: { params: [],
          exceptions: [] },
        set_screen_popup: { params: ["start_column", "end_column", "start_line", "end_line"],
          exceptions: [] },
        set_screen_status: { params: ["report", "pfstatus", "set_functions"],
          exceptions: [] },
        on_grid_command: { params: ["e_ucomm"],
          exceptions: [] },
        on_grid_double_click: { params: ["e_row", "e_column"],
          exceptions: [] },
        on_grid_hotspot: { params: ["e_row_id", "e_column_id"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_columns: {
      constants: [],
      attributes: [],
      events: [],
      methods: {
        constructor: { params: ["line"],
          exceptions: [] },
        get: { params: [],
          exceptions: [] },
        get_column: { params: ["columnname"],
          exceptions: [] },
        set_optimize: { params: ["value"],
          exceptions: [] },
        set_key_fixation: { params: ["value"],
          exceptions: [] },
        set_color_column: { params: ["value"],
          exceptions: [] },
        set_headers_visible: { params: ["value"],
          exceptions: [] },
        set_column_position: { params: ["columnname", "position"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_column: {
      constants: [],
      attributes: ["mv_name", "mv_long", "mv_medium", "mv_short", "mv_hidden", "mv_technical", "mv_hotspot", "mv_key", "mv_length", "mv_tooltip"],
      events: [],
      methods: {
        constructor: { params: ["name"],
          exceptions: [] },
        get_columnname: { params: [],
          exceptions: [] },
        set_long_text: { params: ["value"],
          exceptions: [] },
        set_medium_text: { params: ["value"],
          exceptions: [] },
        set_short_text: { params: ["value"],
          exceptions: [] },
        get_long_text: { params: [],
          exceptions: [] },
        get_medium_text: { params: [],
          exceptions: [] },
        get_short_text: { params: [],
          exceptions: [] },
        set_visible: { params: ["value"],
          exceptions: [] },
        is_visible: { params: [],
          exceptions: [] },
        set_technical: { params: ["value"],
          exceptions: [] },
        set_key: { params: ["value"],
          exceptions: [] },
        set_output_length: { params: ["value"],
          exceptions: [] },
        set_tooltip: { params: ["value"],
          exceptions: [] },
        set_cell_type: { params: ["value"],
          exceptions: [] },
        set_alignment: { params: ["value"],
          exceptions: [] },
        set_optimized: { params: ["value"],
          exceptions: [] },
        set_zero: { params: ["value"],
          exceptions: [] },
        set_lowercase: { params: ["value"],
          exceptions: [] },
        set_specific_group: { params: ["id"],
          exceptions: [] },
        set_color: { params: ["value"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_tree: {
      parent: "z2ui5_cl_cgui_gui",
      constants: [],
      attributes: [],
      events: ["double_click", "link_click", "checkbox_change", "added_function", "expand_empty_folder"],
      methods: {
        factory: { params: ["r_container", "hide_selection_column", "r_salv_tree", "t_table"],
          exceptions: [] },
        constructor: { params: [],
          exceptions: [] },
        display: { params: [],
          exceptions: [] },
        get_nodes: { params: [],
          exceptions: [] },
        get_columns: { params: [],
          exceptions: [] },
        get_tree_settings: { params: [],
          exceptions: [] },
        get_functions: { params: [],
          exceptions: [] },
        get_display_settings: { params: [],
          exceptions: [] },
        get_aggregations: { params: [],
          exceptions: [] },
        get_layout: { params: [],
          exceptions: [] },
        get_selections: { params: [],
          exceptions: [] },
        get_event: { params: [],
          exceptions: [] },
        get_tree: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_nodes: {
      constants: [],
      attributes: [],
      events: [],
      methods: {
        constructor: { params: ["tree"],
          exceptions: [] },
        add_node: { params: ["related_node", "relationship", "data_row", "collapsed_icon", "expanded_icon", "row_style", "text", "visible", "expander", "enabled", "folder"],
          exceptions: [] },
        get_node: { params: ["node_key"],
          exceptions: [] },
        get_all_nodes: { params: [],
          exceptions: [] },
        expand_all: { params: [],
          exceptions: [] },
        collapse_all: { params: [],
          exceptions: [] },
        delete_all: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_node: {
      constants: [],
      attributes: [],
      events: [],
      methods: {
        constructor: { params: ["tree", "key"],
          exceptions: [] },
        to_key: { params: ["key"],
          exceptions: [] },
        get_key: { params: [],
          exceptions: [] },
        get_text: { params: [],
          exceptions: [] },
        set_text: { params: ["value"],
          exceptions: [] },
        get_parent: { params: [],
          exceptions: [] },
        get_first_child: { params: [],
          exceptions: [] },
        get_next_sibling: { params: [],
          exceptions: [] },
        get_children: { params: [],
          exceptions: [] },
        expand: { params: ["complete_subtree", "level"],
          exceptions: [] },
        collapse: { params: [],
          exceptions: [] },
        delete: { params: [],
          exceptions: [] },
        set_folder: { params: ["folder"],
          exceptions: [] },
        set_expander: { params: ["value"],
          exceptions: [] },
        set_collapsed_icon: { params: ["value"],
          exceptions: [] },
        set_expanded_icon: { params: ["value"],
          exceptions: [] },
        set_row_style: { params: ["value"],
          exceptions: [] },
        get_item: { params: ["columnname"],
          exceptions: [] },
        get_hierarchy_item: { params: [],
          exceptions: [] },
        set_type: { params: ["value"],
          exceptions: [] },
        set_checked: { params: ["value"],
          exceptions: [] },
        is_checked: { params: [],
          exceptions: [] },
        set_editable: { params: ["value"],
          exceptions: [] },
        set_enabled: { params: ["value"],
          exceptions: [] },
        set_icon: { params: ["value"],
          exceptions: [] },
        set_value: { params: ["value"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_salv_settings: {
      constants: [],
      attributes: ["mv_title", "mv_striped", "mv_selection_mode", "mt_function", "mv_header", "mv_hierarchy_header"],
      events: [],
      methods: {
        set_grid: { params: ["grid"],
          exceptions: [] },
        set_list_header: { params: ["value"],
          exceptions: [] },
        get_list_header: { params: [],
          exceptions: [] },
        set_striped_pattern: { params: ["value"],
          exceptions: [] },
        set_horizontal_lines: { params: ["value"],
          exceptions: [] },
        set_vertical_lines: { params: ["value"],
          exceptions: [] },
        set_fit_column_to_table_size: { params: ["value"],
          exceptions: [] },
        set_list_header_size: { params: ["value"],
          exceptions: [] },
        set_all: { params: ["value"],
          exceptions: [] },
        set_default: { params: ["value"],
          exceptions: [] },
        add_function: { params: ["name", "icon", "text", "tooltip", "position"],
          exceptions: [] },
        set_function: { params: ["name", "boolean"],
          exceptions: [] },
        set_selection_mode: { params: ["value"],
          exceptions: [] },
        get_selection_mode: { params: [],
          exceptions: [] },
        get_selected_rows: { params: [],
          exceptions: [] },
        set_selected_rows: { params: ["value"],
          exceptions: [] },
        get_current_cell: { params: [],
          exceptions: [] },
        add_sort: { params: ["columnname", "position", "sequence", "subtotal", "group", "obligatory"],
          exceptions: [] },
        add_aggregation: { params: ["columnname", "aggregation"],
          exceptions: [] },
        set_key: { params: ["value"],
          exceptions: [] },
        set_save_restriction: { params: ["value"],
          exceptions: [] },
        set_initial_layout: { params: ["value"],
          exceptions: [] },
        set_header: { params: ["value"],
          exceptions: [] },
        set_hierarchy_header: { params: ["value"],
          exceptions: [] },
        set_hierarchy_tooltip: { params: ["value"],
          exceptions: [] },
        set_hierarchy_size: { params: ["value"],
          exceptions: [] },
        set_hierarchy_icon: { params: ["value"],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_simple_tree: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["node_sel_mode_single", "node_sel_mode_multiple", "relat_first_sibling", "relat_last_sibling", "relat_prev_sibling", "relat_next_sibling", "relat_first_child", "relat_last_child", "eventid_node_double_click", "eventid_expand_no_children", "eventid_selection_changed", "eventid_node_context_menu_req"],
      attributes: [],
      events: ["node_double_click", "expand_no_children", "selection_changed"],
      methods: {
        constructor: { params: ["parent", "node_selection_mode", "hide_selection", "lifetime", "shellstyle", "name"],
          exceptions: ["lifetime_error", "cntl_system_error", "create_error", "failed", "illegal_node_selection_mode"] },
        add_nodes: { params: ["table_structure_name", "node_table"],
          exceptions: ["failed", "error_in_node_table", "dp_error", "table_structure_name_not_found"] },
        delete_all_nodes: { params: [],
          exceptions: ["failed", "cntl_system_error"] },
        delete_node: { params: ["node_key"],
          exceptions: ["failed", "node_not_found", "cntl_system_error"] },
        expand_node: { params: ["node_key", "level_count", "expand_predecessors", "expand_subtree"],
          exceptions: ["failed", "illegal_level_count", "cntl_system_error", "node_not_found", "cannot_expand_leaf"] },
        expand_root_nodes: { params: ["level_count", "expand_subtree"],
          exceptions: ["failed", "illegal_level_count", "cntl_system_error"] },
        collapse_node: { params: ["node_key", "collapse_subtree"],
          exceptions: ["failed", "node_not_found", "cntl_system_error"] },
        collapse_all_nodes: { params: [],
          exceptions: ["failed", "cntl_system_error"] },
        get_selected_node: { params: ["node_key"],
          exceptions: ["failed", "single_node_selection_only", "cntl_system_error"] },
        set_selected_node: { params: ["node_key"],
          exceptions: ["failed", "single_node_selection_only", "node_not_found", "cntl_system_error"] },
        node_set_text: { params: ["node_key", "text"],
          exceptions: ["failed", "node_not_found", "cntl_system_error"] },
        set_registered_events: { params: ["events"],
          exceptions: ["cntl_error", "cntl_system_error", "illegal_event_combination"] },
        view: { params: [],
          exceptions: [] },
        selected: { params: [],
          exceptions: [] },
        columns: { params: [],
          exceptions: [] },
        cells: { params: ["key"],
          exceptions: [] },
        dispatch: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_column_tree: {
      parent: "z2ui5_cl_cgui_gui_simple_tree",
      constants: ["item_class_text", "item_class_checkbox", "item_class_button", "item_class_link", "item_font_default", "item_font_prop", "item_font_fixed", "align_left", "align_center", "align_right", "align_auto", "eventid_item_double_click", "eventid_link_click", "eventid_checkbox_change"],
      attributes: [],
      events: ["item_double_click", "link_click", "checkbox_change"],
      methods: {
        constructor: { params: ["parent", "node_selection_mode", "item_selection", "hierarchy_column_name", "hierarchy_header", "no_hierarchy_column", "hide_selection", "lifetime", "shellstyle", "name"],
          exceptions: ["lifetime_error", "cntl_system_error", "create_error", "illegal_node_selection_mode", "failed", "illegal_column_name"] },
        add_column: { params: ["name", "width", "alignment", "header_text", "header_tooltip", "header_image", "width_pix", "hidden", "disabled", "predecessor_column"],
          exceptions: ["column_exists", "illegal_column_name", "too_many_columns", "illegal_alignment", "different_column_types", "cntl_system_error", "failed", "predecessor_column_not_found"] },
        add_nodes_and_items: { params: ["node_table", "item_table", "item_table_structure_name"],
          exceptions: ["failed", "cntl_system_error", "error_in_tables", "dp_error", "table_structure_name_not_found"] },
        item_set_text: { params: ["node_key", "item_name", "text"],
          exceptions: ["failed", "node_not_found", "item_not_found", "cntl_system_error"] },
        item_set_chosen: { params: ["node_key", "item_name", "chosen"],
          exceptions: ["failed", "node_not_found", "item_not_found", "cntl_system_error"] },
        get_hierarchy_column_name: { params: ["e_hierarchy_column_name"],
          exceptions: [] },
        delete_all_nodes: { params: [],
          exceptions: [] },
        delete_node: { params: [],
          exceptions: [] },
        columns: { params: [],
          exceptions: [] },
        cells: { params: [],
          exceptions: [] },
        dispatch: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_list_tree: {
      parent: "z2ui5_cl_cgui_gui_column_tree",
      constants: [],
      attributes: [],
      events: [],
      methods: {
        constructor: { params: ["parent", "node_selection_mode", "item_selection", "with_headers", "hide_selection", "lifetime", "shellstyle", "name"],
          exceptions: ["lifetime_error", "cntl_system_error", "create_error", "illegal_node_selection_mode", "failed"] },
        add_nodes_and_items: { params: [],
          exceptions: [] },
        columns: { params: [],
          exceptions: [] },
        cells: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_picture: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["display_mode_normal", "display_mode_stretch", "display_mode_fit", "display_mode_normal_center", "display_mode_fit_center", "eventid_picture_click"],
      attributes: [],
      events: ["picture_click"],
      methods: {
        constructor: { params: ["parent", "lifetime", "shellstyle", "name"],
          exceptions: ["error"] },
        load_picture_from_url: { params: ["url", "result"],
          exceptions: ["error"] },
        load_picture_from_url_async: { params: ["url"],
          exceptions: ["error"] },
        load_picture_from_sap_icons: { params: ["icon"],
          exceptions: ["error"] },
        set_display_mode: { params: ["display_mode"],
          exceptions: ["error"] },
        clear_picture: { params: [],
          exceptions: ["error"] },
        set_registered_events: { params: ["events"],
          exceptions: ["cntl_error", "cntl_system_error", "illegal_event_combination"] },
        dispatch: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_toolbar: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["cntb_btype_button", "cntb_btype_dropdown", "cntb_btype_menu", "cntb_btype_sep", "cntb_btype_group", "cntb_btype_check", "m_mode_horizontal", "m_mode_vertical", "m_id_function_selected", "m_id_dropdown_clicked"],
      attributes: [],
      events: ["function_selected", "dropdown_clicked"],
      methods: {
        constructor: { params: ["parent", "shellstyle", "lifetime", "display_mode", "align_right", "name"],
          exceptions: ["cntl_install_error", "cntl_error", "cntb_wrong_version"] },
        add_button: { params: ["fcode", "icon", "is_disabled", "butn_type", "text", "quickinfo", "is_checked"],
          exceptions: ["cntl_error", "cntb_btype_error", "cntb_error_fcode"] },
        add_button_group: { params: ["data_table"],
          exceptions: ["dp_error", "cntb_error_fcode"] },
        set_button_state: { params: ["enabled", "checked", "fcode"],
          exceptions: ["cntl_error", "cntb_error_fcode"] },
        set_button_info: { params: ["fcode", "icon", "text", "quickinfo"],
          exceptions: ["cntl_error", "cntb_error_fcode"] },
        delete_button: { params: ["fcode"],
          exceptions: ["cntl_error", "cntb_error_fcode"] },
        delete_all_buttons: { params: [],
          exceptions: ["cntl_error"] },
        set_registered_events: { params: ["events"],
          exceptions: ["cntl_error", "cntl_system_error", "illegal_event_combination"] },
        dispatch: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_alv_grid: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["mc_fc_excl_all", "mc_fc_detail", "mc_fc_print", "mc_fc_refresh", "mc_fc_loc_cut", "mc_fc_loc_copy", "mc_fc_loc_paste", "mc_fc_loc_undo", "mc_fc_loc_append_row", "mc_fc_loc_insert_row", "mc_fc_loc_delete_row", "mc_fc_loc_copy_row", "mc_fc_sort_asc", "mc_fc_sort_dsc", "mc_fc_find", "mc_fc_filter", "mc_fc_sum", "mc_fc_views", "mc_fc_info", "mc_fc_graph", "mc_mb_export", "mc_mb_variant", "mc_evt_enter", "mc_evt_modified", "mc_style_enabled", "mc_style_disabled", "mc_style_hotspot"],
      attributes: [],
      events: ["double_click", "hotspot_click", "user_command", "toolbar"],
      methods: {
        constructor: { params: ["i_shellstyle", "i_lifetime", "i_parent", "i_appl_events", "i_parentdbg", "i_applogparent", "i_graphicsparent", "i_name", "i_fcat_complete"],
          exceptions: ["error_cntl_create", "error_cntl_init", "error_cntl_link", "error_dp_create"] },
        set_table_for_first_display: { params: ["i_buffer_active", "i_bypassing_buffer", "i_consistency_check", "i_structure_name", "is_variant", "i_save", "i_default", "is_layout", "is_print", "it_special_groups", "it_toolbar_excluding", "it_hyperlink", "it_alv_graphics", "it_except_qinfo", "it_outtab", "it_fieldcatalog", "it_sort", "it_filter"],
          exceptions: ["invalid_parameter_combination", "program_error", "too_many_lines"] },
        refresh_table_display: { params: ["is_stable", "i_soft_refresh", "it_outtab"],
          exceptions: ["finished"] },
        set_frontend_fieldcatalog: { params: ["it_fieldcatalog"],
          exceptions: [] },
        get_frontend_fieldcatalog: { params: ["et_fieldcatalog"],
          exceptions: [] },
        set_frontend_layout: { params: ["is_layout"],
          exceptions: [] },
        get_frontend_layout: { params: ["es_layout"],
          exceptions: [] },
        set_sort_criteria: { params: ["it_sort"],
          exceptions: ["no_fieldcatalog_available"] },
        get_selected_rows: { params: ["et_index_rows", "et_row_no"],
          exceptions: [] },
        show: { params: [],
          exceptions: [] },
        caption: { params: [],
          exceptions: [] },
        set_toolbar_interactive: { params: [],
          exceptions: [] },
        check_changed_data: { params: ["e_valid", "c_refresh"],
          exceptions: [] },
        register_edit_event: { params: ["i_event_id"],
          exceptions: ["error"] },
        set_ready_for_input: { params: ["i_ready_for_input"],
          exceptions: [] },
        dispatch: { params: [],
          exceptions: [] },
      },
    },
    z2ui5_cl_cgui_gui_alv_toolbar: {
      constants: [],
      attributes: ["mt_toolbar"],
      events: [],
      methods: {
      },
    },
  },
};

/** the stand-in of a SAP GUI class - undefined for any other name (also
 *  constructor or toString, which every object has) */
/** text without the arguments of its constructor expressions - VALUE #( a = 1 ),
 *  CONV, CORRESPONDING, COND, SWITCH, REDUCE, FILTER: their components and
 *  conditions are no parameters of a call */
export function withoutConstructorArgs(text) {
  let out = text;
  for (;;) {
    const m = /\b(value|conv|corresponding|cond|switch|reduce|filter|exact|ref|cast)\s+[\w#~=>/-]*\s*\(/.exec(out);
    if (!m) return out;
    let depth = 0;
    let end = m.index + m[0].length - 1;
    for (; end < out.length; end++) {
      if (out[end] === "(") depth++;
      else if (out[end] === ")" && --depth === 0) break;
    }
    out = `${out.slice(0, m.index)}x${out.slice(end + 1)}`;
  }
}

/** the classic types of the generic parameters of the grid stand-in - a
 *  VALUE #( ... ) there has no type to take, it is written with this one */
export const GRID_VALUE_TYPES = {
  is_layout: "lvc_s_layo", is_variant: "disvariant", is_print: "lvc_s_prnt", is_stable: "lvc_s_stbl",
  it_toolbar_excluding: "ui_functions", it_sort: "lvc_t_sort", it_filter: "lvc_t_filt",
  it_fieldcatalog: "lvc_t_fcat", it_special_groups: "lvc_t_sgrp", it_hyperlink: "lvc_t_hype",
  it_except_qinfo: "lvc_t_qinf",
};
// the SALV stand-ins (src/01/z2ui5_cl_cgui_salv_*) - for a report that keeps
// its SALV object and uses it after display( ): an attribute of a local
// class, its event handlers, the rows selected. A report that only sets its
// SALV up and shows it gets alv( ) instead (analyzeAlv( )); the stand-ins
// take over when that refuses (convert( ) runs again with salv: true)
export const SALV = {
  classes: {
    cl_salv_table: "z2ui5_cl_cgui_salv_table", cl_salv_events_table: "z2ui5_cl_cgui_salv_table",
    cl_salv_columns_table: "z2ui5_cl_cgui_salv_columns", cl_salv_columns_list: "z2ui5_cl_cgui_salv_columns",
    cl_salv_columns: "z2ui5_cl_cgui_salv_columns",
    cl_salv_column_table: "z2ui5_cl_cgui_salv_column", cl_salv_column_list: "z2ui5_cl_cgui_salv_column",
    cl_salv_column: "z2ui5_cl_cgui_salv_column",
    cl_salv_display_settings: "z2ui5_cl_cgui_salv_settings", cl_salv_functions_list: "z2ui5_cl_cgui_salv_settings",
    cl_salv_functions: "z2ui5_cl_cgui_salv_settings", cl_salv_selections: "z2ui5_cl_cgui_salv_settings",
    cl_salv_sorts: "z2ui5_cl_cgui_salv_settings", cl_salv_aggregations: "z2ui5_cl_cgui_salv_settings",
    cl_salv_layout: "z2ui5_cl_cgui_salv_settings", cl_salv_filters: "z2ui5_cl_cgui_salv_settings",
    cl_salv_print: "z2ui5_cl_cgui_salv_settings", cl_salv_functional_settings: "z2ui5_cl_cgui_salv_settings",
    cl_salv_tree: "z2ui5_cl_cgui_salv_tree", cl_salv_events_tree: "z2ui5_cl_cgui_salv_tree",
    cl_salv_nodes: "z2ui5_cl_cgui_salv_nodes", cl_salv_node: "z2ui5_cl_cgui_salv_node", cl_salv_item: "z2ui5_cl_cgui_salv_node",
    cl_salv_tree_settings: "z2ui5_cl_cgui_salv_settings", cl_salv_columns_tree: "z2ui5_cl_cgui_salv_columns",
    cl_salv_column_tree: "z2ui5_cl_cgui_salv_column", cl_salv_functions_tree: "z2ui5_cl_cgui_salv_settings",
  },
  // if_salv_c_* - the structures of z2ui5_if_cgui_salv_c
  constants: {
    if_salv_c_selection_mode: "selection_mode", if_salv_c_function_position: "function_position",
    if_salv_c_cell_type: "cell_type", if_salv_c_alignment: "alignment", if_salv_c_sort: "sort",
    if_salv_c_aggregation: "aggregation", if_salv_c_node_relation: "node_relation", if_salv_c_item_type: "item_type",
  },
  types: {
    salv_t_row: "z2ui5_cl_cgui_salv_settings=>ty_t_row", salv_s_cell: "z2ui5_cl_cgui_salv_settings=>ty_s_cell",
    salv_t_column_ref: "z2ui5_cl_cgui_salv_columns=>ty_t_column_ref", salv_s_column_ref: "z2ui5_cl_cgui_salv_columns=>ty_s_column_ref",
    salv_de_function: "z2ui5_cl_cgui_salv_table=>ty_function", salv_de_column: "z2ui5_cl_cgui_salv_table=>ty_column",
    salv_de_row: "i",
    salv_de_node_key: "z2ui5_cl_cgui_salv_node=>ty_node_key", lvc_nkey: "z2ui5_cl_cgui_salv_node=>ty_node_key",
    salv_t_nodes: "z2ui5_cl_cgui_salv_node=>ty_t_node_ref", salv_s_nodes: "z2ui5_cl_cgui_salv_node=>ty_s_node_ref",
  },
};
Object.setPrototypeOf(SALV.classes, null);
Object.setPrototypeOf(SALV.constants, null);
Object.setPrototypeOf(SALV.types, null);

// set while a converter runs with the SALV stand-ins - the conversion is synchronous
export let salvMode = false;
/** an imported binding cannot be assigned - convert.mjs switches the mode here */
export function setSalvMode(on) {
  salvMode = on;
}

export const guiClass = (name) => (Object.hasOwn(GUI.classes, name) ? GUI.classes[name]
  : salvMode && SALV.classes[name] ? SALV.classes[name] : undefined);

/** the SALV tokens of a statement in the stand-in mode - [index, text] pairs
 *  ("" drops a token): cx_salv_* the exception of the stand-ins (once in a
 *  CATCH), if_salv_c_*=>x the constant of z2ui5_if_cgui_salv_c, the SALV
 *  types of the DDIC the types of the stand-ins */
export function salvTokens(toks) {
  if (!salvMode) return [];
  const out = [];
  let cx = false;
  for (let i = 0; i < toks.length; i++) {
    const t = lc(toks[i].getStr());
    const prev = i > 0 ? lc(toks[i - 1].getStr()) : "";
    if (["-", "->", "=>", "~"].includes(prev)) continue;
    if (/^cx_salv_\w+$/.test(t)) {
      out.push([i, cx ? "" : "z2ui5_cx_cgui_salv"]);
      cx = true;
    } else if (SALV.constants[t] && toks[i + 1]?.getStr() === "=>" && toks[i + 2]) {
      out.push([i, "z2ui5_if_cgui_salv_c"], [i + 2, `${SALV.constants[t]}-${lc(toks[i + 2].getStr())}`]);
    } else if (/^(cl_gui_column_tree|cl_gui_list_tree|cl_tree_control_base)$/.test(t) && toks[i + 1]?.getStr() === "=>" && /^relat_/i.test(toks[i + 2]?.getStr() ?? "")) {
      // the relationship of a node of a tree - that of if_salv_c_node_relation
      out.push([i, "z2ui5_if_cgui_salv_c"], [i + 2, `node_relation-${lc(toks[i + 2].getStr()).slice("relat_".length)}`]);
    } else if (t === "if_salv_c_bool_sap" && toks[i + 1]?.getStr() === "=>" && toks[i + 2]) {
      out.push([i, lc(toks[i + 2].getStr()) === "true" ? "abap_true" : "abap_false"], [i + 1, ""], [i + 2, ""]);
    } else if (SALV.types[t] && ["type", "of", "like"].includes(prev)) {
      out.push([i, SALV.types[t]]);
    }
  }
  return out;
}

/** the text without the relat_* constants of the tree controls - in the
 *  stand-in mode they are those of z2ui5_if_cgui_salv_c, no control */
export function salvRelations(text) {
  return salvMode ? text.replace(/\bcl_(gui_column_tree|gui_list_tree|tree_control_base)\s*=>\s*relat_\w+/g, "") : text;
}

/** whether a stand-in or one of its parents raises the event */
export function guiEvent(cls, name) {
  for (let c = cls; c; c = GUI.members[c]?.parent) if (GUI.members[c]?.events.includes(name)) return true;
  return false;
}

/** the member of a stand-in or of one of its parents - undefined if none has it */
export function guiMember(cls, name) {
  let found;
  for (let c = cls; c; c = GUI.members[c]?.parent) {
    const m = GUI.members[c];
    if (!m) return found;
    // a REDEFINITION lists no parameters - they are those of the class that
    // declares the method
    if (Object.hasOwn(m.methods, name)) {
      found = { kind: "method", ...m.methods[name] };
      if (found.params.length || found.exceptions.length) return found;
      continue;
    }
    if (found) return found;
    if (m.constants.includes(name) || m.attributes.includes(name)) return { kind: "attribute" };
  }
  return found;
}

// the constructor operators - the type a token names after one of them
export const CONSTRUCTORS = new Set(["conv", "value", "new", "corresponding", "exact", "cond", "switch", "reduce", "ref", "cast", "filter"]);

// statements a body keeps chained when the report chains them
export const CHAINABLE = new Set(["Clear", "Free", "Data", "DataBegin", "DataEnd", "Constant", "Type", "TypeBegin", "TypeEnd", "Static", "FieldSymbol", "Refresh"]);

// the screen fields LOOP AT SCREEN / MODIFY SCREEN can change here, and how
export const SCREEN_FLAGS = new Set(["active", "input", "required", "invisible"]);
export const SCREEN_FIELDS = new Set(["name", "group1", ...SCREEN_FLAGS]);

// the PUBLIC and PROTECTED methods and attributes of z2ui5_cl_cgui_report -
// a FORM must not take one as method name, a global of the report not as
// attribute name (methods and attributes share one namespace in a class)
export const BASE_METHODS = ["cgui_run_in_background", "at_roundtrip_start",
  "initialization", "selection_screen", "at_selection_screen_output", "at_selection_screen_on",
  "at_selection_screen", "start_of_selection", "end_of_selection", "end_of_page", "at_selection_screen_on_block",
  "at_selection_screen_on_radio", "at_selection_screen_on_end_of", "at_selection_screen_on_help",
  "at_selection_screen_on_exit", "top_of_page", "top_of_page_line_selection", "at_line_selection", "at_link_click",
  "at_tree_node", "at_tree_checkbox", "at_tree_expand_no_children", "at_data_changed", "at_user_command",
  "at_value_request", "value_request_part", "at_alv_value_request", "authority_check",
  "selection_screen_dynnr", "after_call_selection_screen", "write", "format", "get_cursor", "lisel",
  "_msg", "_msg_box", "_popup", "set_prefill_last", "set_fresh_start", "set_job", "set_log", "messages_from_log", "log_display", "set_command_field", "set_catalog", "okcode_execute", "set_cursor_field", "set_selscreen_status", "list", "alv", "tree", "get_selected_rows", "lsind", "message",
  "message_t100", "messages_from_bapiret", "popup_to_confirm", "popup_to_decide",
  "popup_get_values", "popup_get_values_sval", "popup_to_decide_list", "popup_values_sval", "popup_answer", "popup_values", "value_help_popup", "vrm_set_values",
  "leave_to_selection_screen", "window", "call_selection_screen", "submit", "call_transaction", "read_list", "set_parameter_id", "get_parameter_id",
  "set_line_count", "set_pf_status", "set_title", "set_variant", "set_variant_store", "set_layout_store", "get_link",
  "current_screen", "dynpro_screen", "dynpro_pbo", "dynpro_pai", "after_call_screen",
  "call_screen", "set_screen", "leave_to_screen", "leave_screen", "screen_left", "cgui_statics_keep", "cgui_statics_restore"];
export const RESERVED_METHODS = new Set([...BASE_METHODS, "client", "cs_ucomm", "z2ui5_if_app~main", "main",
  "at_selection_screen_ucomm", "constructor"]);

export const BUILTIN_TYPES = new Set(["string", "xstring", "i", "int1", "int2", "int4", "int8", "d", "t", "f", "c", "n",
  "x", "p", "decfloat16", "decfloat34", "utclong", "abap_bool", "any", "data", "simple", "clike", "csequence",
  "xsequence", "numeric", "decfloat", "object", "table", "index", "standard", "sorted", "hashed", "line", "ref",
  "abap_true", "abap_false", "string_table", "sy", "syst", "char1", "boolean", "abap_boolean", "timestamp",
  "timestampl", "sydatum", "syuzeit", "syuname", "symsgid", "symsgty", "symsgno", "symsgv", "sytabix",
  "xsdboolean", "abap_char1", "abap_typekind", "ty_t_cgui_value", "ty_s_cgui_value"]);

// well-known on-premise tables and their released successors on ABAP Cloud
// (a hint for the person or the AI step - verify before using it)
export const SUCCESSORS = {
  sflight: "/DMO/FLIGHT (ABAP Flight Reference Scenario) or a released CDS view of your own",
  scarr: "/DMO/CARRIER (ABAP Flight Reference Scenario)",
  spfli: "/DMO/CONNECTION (ABAP Flight Reference Scenario)",
  sbook: "/DMO/BOOKING (ABAP Flight Reference Scenario)",
  scustom: "/DMO/CUSTOMER (ABAP Flight Reference Scenario)",
  mara: "I_Product", makt: "I_ProductDescription", marc: "I_ProductPlant", mard: "I_ProductStorageLocation",
  t001: "I_CompanyCode", t001w: "I_Plant", kna1: "I_Customer", lfa1: "I_Supplier",
  bkpf: "I_JournalEntry", bseg: "I_JournalEntryItem", acdoca: "I_JournalEntryItem",
  vbak: "I_SalesOrder", vbap: "I_SalesOrderItem", likp: "I_OutboundDelivery", lips: "I_OutboundDeliveryItem",
  vbrk: "I_BillingDocument", vbrp: "I_BillingDocumentItem", ekko: "I_PurchaseOrderAPI01",
  ekpo: "I_PurchaseOrderItemAPI01", eban: "I_PurchaseRequisitionItemAPI01", t005: "I_Country",
  t005t: "I_CountryText", tcurc: "I_Currency", t006: "I_UnitOfMeasure", usr02: "I_User (no direct successor)",
  cl_salv_table: "abap-cloud-gui alv( )", cl_gui_frontend_services: "no successor - no SAP GUI frontend",
};


// ------------------------------------------------------------------ helpers

export function shortText(s) {
  const t = renderTokens(stmtTokens(s), new Map(), s.getColon()).replace(/\s+/g, " ");
  return t.length > 60 ? `${t.slice(0, 57)}...` : t;
}

export function shift(line, delta) {
  if (!line.trim()) return line;
  if (delta >= 0) return " ".repeat(delta) + line;
  const lead = line.length - line.trimStart().length;
  return line.slice(Math.min(-delta, lead));
}

/** DATA a TYPE i. / DATA bb TYPE string. - the names of a run padded */
export function alignData(list) {
  let i = 0;
  while (i < list.length) {
    let j = i;
    while (j < list.length && /^DATA \S+ [^\n]*\.$/.test(list[j]) && !list[j].includes("\n")) j++;
    if (j - i > 1) {
      const width = Math.max(...list.slice(i, j).map((l) => l.split(" ")[1].length));
      for (let r = i; r < j; r++) {
        const [, name, ...rest] = list[r].split(" ");
        list[r] = `DATA ${name.padEnd(width)} ${rest.join(" ")}`;
      }
    }
    i = Math.max(j, i + 1);
  }
}

export function indent(text, n) {
  if (!text) return "";
  const pad = " ".repeat(n);
  return pad + text.replace(/\n/g, `\n${pad}`);
}

/** an IF sy-subrc whose statements were all dropped - around the CALL
 *  SCREEN of the grid, after the EXCEPTIONS of its first display - goes too */
export function dropEmptyIfs(lines) {
  const out = [...lines];
  for (let i = 0; i < out.length; i++) {
    const m = /^(\s*)IF\s+(sy-subrc\s+[^()]*)\.\s*$/i.exec(out[i]);
    if (!m) continue;
    let j = i + 1;
    while (j < out.length && out[j].trim() === "") j++;
    if (j < out.length && new RegExp(`^${m[1]}ENDIF\\.\\s*$`, "i").test(out[j])) {
      out.splice(i, j - i + 1);
      i = Math.max(-1, i - 2);
    }
  }
  return out;
}

export function trimBlank(lines) {
  let a = 0;
  let b = lines.length;
  while (a < b && lines[a] === "") a++;
  while (b > a && lines[b - 1] === "") b--;
  return lines.slice(a, b);
}

export const sameColon = (a, b) => {
  const ca = a.getColon();
  const cb = b.getColon();
  return ca && cb && ca.getRow() === cb.getRow() && ca.getCol() === cb.getCol();
};

export const findTo = (s) => children(s, "Target").length > 0;

/** whether a DATA / TYPES declaration has OCCURS or WITH HEADER LINE -
 *  for the END OF of a BEGIN OF ... OCCURS, `begin` says so */
export function hasHeaderLine(s, begin) {
  const k = kind(s);
  if (k === "DataEnd") return begin !== undefined && begin.name === lc(declName(s) ?? "");
  const w = stmtTokens(s).map((t) => uc(t.getStr()));
  return w.includes("OCCURS") || w.some((x, i) => x === "WITH" && w[i + 1] === "HEADER" && w[i + 2] === "LINE");
}

/**
 * Whether the bare name of a table with a header line at toks[i] means the
 * header line: as the target or source of a MOVE, in a MOVE-CORRESPONDING,
 * as the INTO of a SELECT that is not INTO TABLE, as the FROM of a database
 * INSERT / UPDATE / MODIFY, as a USING or CHANGING of a PERFORM (TABLES
 * passes the table), in a WRITE, a condition, or LIKE it in a declaration
 * (LIKE LINE OF names the table). Everywhere else - LOOP AT, READ TABLE,
 * SORT, DESCRIBE, the TABLES of a PERFORM or a function - the name is the
 * table, as it is in a class.
 */
export function headerLineContext(s, toks, i) {
  const k = kind(s);
  const w = toks.map((t) => lc(t.getStr()));
  const prev = w[i - 1];
  const prev2 = w[i - 2];
  if (w[i + 1] === "[" || (prev === "of" && prev2 === "line") || prev === "in" || (prev === "(" && prev2 === "lines")) return false;
  if (["Move", "MoveCorresponding", "Write", "If", "ElseIf", "Check", "While"].includes(k)) return true;
  if ((k === "Select" || k === "SelectLoop") && (prev === "into" || (prev === "of" && prev2 === "fields")) && w[i - 1] !== "table") return true;
  if (["InsertDatabase", "UpdateDatabase", "ModifyDatabase"].includes(k) && prev === "from") return true;
  if (k === "Perform") {
    for (let j = i - 1; j > 0; j--) {
      if (w[j] === "tables") return false;
      if (w[j] === "using" || w[j] === "changing") return true;
    }
    return false;
  }
  if (["Data", "Type", "Constant", "FieldSymbol", "Static"].includes(k) && prev === "like") return true;
  return false;
}

/** drops the word and the n tokens after it from the rendering */
export function dropWords(toks, w, ov, word, n) {
  const at = w.indexOf(word);
  if (at < 0) return;
  for (const t of toks.slice(at, at + 1 + n)) ov.set(key(t), null);
}

/** the name a declaration declares */
export function declName(s) {
  const k = kind(s);
  if (k === "Data" || k === "Constant" || k === "Static" || k === "ClassData") {
    const dd = child(s, "DataDefinition") ?? s;
    const n = child(dd, "DefinitionName") ?? findAll(s, "DefinitionName")[0];
    return n ? nodeText(n) : undefined;
  }
  if (["DataBegin", "DataEnd", "TypeBegin", "TypeEnd", "ConstantBegin", "ConstantEnd", "Ranges", "Type", "StaticBegin"].includes(k)) {
    const n = findAll(s, "DefinitionName")[0] ?? findAll(s, "NamespaceSimpleName")[0];
    return n ? nodeText(n) : undefined;
  }
  if (k === "Parameter" || k === "SelectOption") return nodeText(child(s, "FieldSub"));
  if (k === "Tables") return nodeText(child(s, "Field"));
  if (k === "FieldSymbol") return nodeText(child(s, "FieldSymbol"));
  if (k === "MethodDef") return nodeText(child(s, "MethodName"));
  return undefined;
}

/** zflight_list -> zcl_flight_list, /abc/flights -> /abc/cl_flights */
/**
 * The type of the inline target of a SELECT from one table - `INTO
 * [TABLE] @DATA(x)` - as the declaration of an attribute: its row the
 * table's (`SELECT *`), a structure of the columns read (a plain field list,
 * an alias each may have), or an integer (`COUNT( * )` alone). Answers
 * { types, data } - the TYPES of the structure, if any, and the TYPE
 * addition - or undefined for anything else (a join, an expression, a
 * subquery): then the declaration is refused as before.
 */
export function selectTargetType(text, name) {
  const t = text.replace(/\s+/g, " ").replace(/\s*\.\s*$/, "");
  const into = new RegExp(`\\bINTO (TABLE )?@DATA\\(\\s*${name.replace(/[<>]/g, "\\$&")}\\s*\\)`, "i").exec(t);
  if (!into) return undefined;
  const table = Boolean(into[1]);
  // SELECT [SINGLE] [DISTINCT] <fields> FROM <t> ... or SELECT FROM <t> FIELDS <fields> ...
  let m = /^SELECT (?:SINGLE )?(?:DISTINCT )?(.+?) FROM ([\w/]+)(?: AS \w+)?(?= |$)(.*)$/i.exec(t);
  let fields;
  let from;
  let rest;
  if (m && !/^FROM\b/i.test(m[1])) [, fields, from, rest] = m;
  else {
    m = /^SELECT (?:SINGLE )?FROM ([\w/]+)(?: AS \w+)? FIELDS (?:DISTINCT )?(.+?) (?=INTO |WHERE |ORDER |GROUP |UP |$)(.*)$/i.exec(t);
    if (!m) return undefined;
    [, from, fields, rest] = m;
  }
  if (/\bJOIN\b/i.test(rest) || /\(/.test(from)) return undefined;
  const tab = lc(from);
  const wrap = (row) => (table ? `TYPE STANDARD TABLE OF ${row} WITH EMPTY KEY` : `TYPE ${row}`);
  const list = fields.trim();
  if (list === "*") return { data: wrap(tab) };
  if (/^COUNT\( ?\* ?\)( AS \w+)?$/i.test(list)) return table ? undefined : { data: "TYPE i" };
  // a comma-separated list (the strict syntax) or a space-separated one,
  // each column a field of the table, with an alias or without
  const words = list.includes(",") ? list.split(/\s*,\s*/) : list.split(" ").reduce((acc, w, i, all) => {
    if (/^AS$/i.test(w) || /^AS$/i.test(all[i - 1] ?? "")) acc[acc.length - 1] += ` ${w}`;
    else acc.push(w);
    return acc;
  }, []);
  const merged = [];
  for (const piece of words) {
    const c = /^(?:[\w/]+~)?([\w/]+)(?: AS ([\w/]+))?$/i.exec(piece.trim());
    if (!c) return undefined;
    merged.push({ field: lc(c[1]), as: lc(c[2] ?? c[1]) });
  }
  if (!merged.length) return undefined;
  if (merged.length === 1 && !table) return { data: `TYPE ${tab}-${merged[0].field}` };
  const ty = `ty_${name}`.slice(0, 30);
  return {
    types: [`TYPES: BEGIN OF ${ty},`, ...merged.map((c) => `         ${c.as} TYPE ${tab}-${c.field},`), `       END OF ${ty}.`],
    data: wrap(ty),
  };
}

export function defaultClassName(program) {
  const p = lc(program);
  const ns = /^(\/\w+\/)(.*)$/.exec(p);
  if (ns) return `${ns[1]}cl_${ns[2]}`.slice(0, 30);
  const m = /^([zy])_?(.*)$/.exec(p);
  return (m ? `${m[1]}cl_${m[2]}` : `zcl_${p}`).slice(0, 30);
}

/** a call chain over a variable: target = root->a( )->b( arg ). */
export function salvChain(s) {
  const k = kind(s);
  if (k !== "Call" && k !== "Move") return undefined;
  const toks = stmtTokens(s).map((t) => t.getStr());
  let i = 0;
  let target;
  if (k === "Move") {
    // DATA(x) = ... - an inline declaration of the target
    const inline = lc(toks[0]) === "data" && toks[1] === "(" && toks[3] === ")";
    const at = inline ? 4 : 1;
    if (toks[at] !== "=" && toks[at] !== "?=") return undefined;
    target = lc(toks[inline ? 2 : 0]);
    i = at + 1;
    // CAST cl_salv_column_table( x->get_column( 'A' ) )
    if (lc(toks[i]) === "cast" && toks[i + 2] === "(") {
      const inner = toks.slice(i + 3, -1);
      const r = chainOf(inner);
      return r ? { target, ...r } : undefined;
    }
  }
  if (k === "Call" && uc(toks[0]) === "CALL" && uc(toks[1]) === "METHOD") {
    // CALL METHOD x->display.
    const rest = toks.slice(2);
    if (rest.length === 3 && rest[1] === "->") return { root: lc(rest[0]), calls: [{ name: lc(rest[2]) }] };
    return undefined;
  }
  const r = chainOf(toks.slice(i));
  return r ? { target, ...r } : undefined;
}

export function chainOf(toks) {
  if (!toks.length || !/^[\w/]+$/.test(toks[0])) return undefined;
  const root = lc(toks[0]);
  const calls = [];
  let i = 1;
  while (i < toks.length) {
    if (toks[i] !== "->" || !toks[i + 1] || toks[i + 2] !== "(") return undefined;
    const name = lc(toks[i + 1]);
    let depth = 0;
    let j = i + 2;
    const arg = [];
    for (; j < toks.length; j++) {
      if (toks[j] === "(" || toks[j].endsWith("(")) depth++;
      if (toks[j] === ")" || toks[j].startsWith(")")) depth--;
      if (depth === 0) break;
      if (j > i + 2) arg.push(toks[j]);
    }
    const argText = arg.join(" ").replace(/^value\s*=\s*/i, "").trim();
    calls.push({ name, arg: argText || undefined });
    i = j + 1;
  }
  return calls.length ? { root, calls } : undefined;
}

/** the parameters of CALL FUNCTION, by lower case name */
export function functionParams(s) {
  const out = new Map();
  for (const k of ["FunctionExportingParameter", "ParameterS", "ParameterT"]) {
    for (const p of findAll(s, k)) {
      const name = lc(nodeText(child(p, "ParameterName")));
      const value = children(p).find((c) => kind(c) !== "ParameterName");
      out.set(name, { node: value });
    }
  }
  return out;
}

/** a call with table parameters, one line of VALUE #( ... ) per row:
 *    set_pf_status( functions = VALUE #( ( ... )
 *                                        ( ... ) )
 *                   shortcuts = VALUE #( ( ... ) ) ). */
export function renderTableCall(method, params) {
  const head = `${method}( `;
  const width = Math.max(...params.map((p) => p.name.length));
  const lines = [];
  params.forEach((p, i) => {
    const prefix = `${i ? " ".repeat(head.length) : head}${p.name.padEnd(width)} = `;
    if (p.raw) {
      lines.push(`${prefix}${p.lines[0]}`);
      return;
    }
    if (!p.lines.length) {
      lines.push(`${prefix}VALUE #( )`);
      return;
    }
    const pad = " ".repeat(prefix.length + "VALUE #( ".length);
    p.lines.forEach((l, j) => lines.push(`${j ? pad : `${prefix}VALUE #( `}${l}`));
    lines[lines.length - 1] += " )";
  });
  return `${lines.join("\n")} ).`;
}

// the tables above are read with any name of the source - a name every
// object has (constructor, toString) is none of theirs
Object.setPrototypeOf(ICONS, null);
Object.setPrototypeOf(LVC_TYPES, null);

// the methods of the runtime the converted code calls, besides BASE_METHODS
export const REPORT_CALLS = ["list", "write", "message", "message_t100", "messages_from_bapiret", "alv", "tree", "set_title",
  "set_pf_status", "set_line_count", "leave_to_selection_screen", "submit", "call_transaction", "read_list", "call_selection_screen", "window",
  "popup_to_confirm", "popup_to_decide", "popup_to_decide_list", "popup_get_values", "popup_get_values_sval", "popup_values_sval",
  "popup_answer", "popup_values", "value_help_popup", "lsind", "set_lsind", "get_selected_rows", "get_cursor",
  "lisel", "set_parameter_id", "get_parameter_id", "set_cursor_field", "vrm_set_values", "current_screen",
  "call_screen", "set_screen", "leave_to_screen", "leave_screen", "screen_left"];

/**
 * A call of a method of the report class written without its instance -
 * list( ), message( ), a FORM - prefixed with ref-> in a line of converted
 * code of a local class; strings and the text of templates are left alone.
 */
export function prefixCalls(line, names, ref, chained = new Set()) {
  let out = "";
  let i = 0;
  const code = (seg) => seg
    .replace(/(^|[^\w>~=-])([a-z_][\w]*)\(/gi, (all, pre, name) => (names.has(name.toLowerCase()) ? `${pre}${ref}->${name}(` : all))
    .replace(/(^|[^\w>~=-])([a-z_][\w]*)\( \)->/gi, (all, pre, name) => (chained.has(name.toLowerCase()) ? `${pre}${ref}->${name}( )->` : all));
  while (i < line.length) {
    const c = line[i];
    if (c === "'" || c === "`") {
      const j = line.indexOf(c, i + 1);
      const end = j < 0 ? line.length : j + 1;
      out += line.slice(i, end);
      i = end;
      continue;
    }
    if (c === '"') {
      out += line.slice(i);
      break;
    }
    if (c === "|") {
      // a string template: the text stays, the expressions in { } are code
      let j = i + 1;
      out += c;
      while (j < line.length && line[j] !== "|") {
        if (line[j] === "\\") {
          out += line.slice(j, j + 2);
          j += 2;
          continue;
        }
        if (line[j] === "{") {
          const close = line.indexOf("}", j);
          const e = close < 0 ? line.length : close + 1;
          out += code(line.slice(j, e));
          j = e;
          continue;
        }
        out += line[j++];
      }
      if (j < line.length) out += "|";
      i = j + 1;
      continue;
    }
    let j = i;
    while (j < line.length && !["'", "`", '"', "|"].includes(line[j])) j++;
    out += code(line.slice(i, j));
    i = j;
  }
  return out;
}

/** the kind of the node each token of a statement hangs from - a variable
 *  hangs from Field, a type from TypeName; a column, a table, a formal
 *  parameter or a component from a node of its own */
export function tokenParents(s) {
  const out = new Map();
  const walk = (n, parent) => {
    if (n.getChildren().length === 0) {
      const t = n.getFirstToken();
      if (t) out.set(key(t), parent);
      return;
    }
    for (const c of n.getChildren()) walk(c, kind(n));
  };
  walk(s, kind(s));
  return out;
}

/** the name WRITE ... UNDER g refers to: the field, or the text of a literal */
export function underName(text) {
  const t = text.trim();
  return /^['`]/.test(t) ? unquote(t) : uc(t.replace(/\s+/g, ""));
}

/** the group of radiobutton( ) for a radio group of a dynpro - %A_ISNATV
 *  (the name the screen painter generates) is RB_ISNATV */
export const radioGroup = (name) => name.replace(/^%A_?/, "RB_").slice(0, 10) || "RB1";

// the fields of a dynpro the converter builds - texts, inputs, checkboxes,
// radio buttons, frames, push buttons and the OK code field
export const DYNPRO_FIELDS = new Set(["TEXT", "TEMPLATE", "CHECK", "RADIO", "FRAME", "PUSH", "OKCODE"]);

/** the columns of table control name of dynpro d, in their order: { field,
 *  text (the heading of its column), input, width } */
export function tcColumns(d, name) {
  const of = d.fields.filter((f) => f.cont === "TABLE_CTRL" && f.contName === name);
  return of.filter((f) => f.type === "TEMPLATE").sort((a, b) => a.column - b.column).map((f) => {
    const head = of.find((h) => h.type === "TEXT" && h.heading && h.column === f.column);
    return { field: lc(f.name), text: (head?.text ?? f.name).replace(/_/g, " ").trim(), input: f.input, width: f.visLength || f.length };
  });
}

/**
 * The flow logic of a dynpro: { pbo, pai, pov: [{ module, cond, field }],
 * poh, request, problems } - cond "exit" for AT EXIT-COMMAND, "input" for
 * ON INPUT (field), "cursor" for AT CURSOR-SELECTION; problems what has no
 * counterpart (LOOP, CALL SUBSCREEN, FIELD ... VALUES / SELECT).
 */
export function parseFlow(lines) {
  const flow = { pbo: [], pai: [], pov: [], poh: false, request: false, problems: [] };
  // LOOP ... WITH CONTROL tc: the modules of the loop go into it
  let loop;
  const source = lines.filter((l) => !/^\s*\*/.test(l)).map((l) => l.replace(/".*$/, "")).join(" ");
  let section;
  for (const raw of source.split(".")) {
    const st = raw.replace(/\s+/g, " ").trim().toUpperCase();
    if (!st) continue;
    const process = /^PROCESS (BEFORE OUTPUT|AFTER INPUT|ON VALUE-REQUEST|ON HELP-REQUEST)$/.exec(st);
    if (process) {
      section = { "BEFORE OUTPUT": "pbo", "AFTER INPUT": "pai", "ON VALUE-REQUEST": "pov", "ON HELP-REQUEST": "poh" }[process[1]];
      continue;
    }
    if (/^(CHAIN|ENDCHAIN)$/.test(st)) continue;
    const lp = /^LOOP(?: AT ([\w-]+)(?: INTO ([\w-]+))?)? WITH CONTROL ([\w-]+)(?: CURSOR [\w-]+)?$/.exec(st);
    if (lp && (section === "pbo" || section === "pai") && !loop) {
      if (lp[1] && !lp[2]) {
        flow.problems.push(`LOOP AT ${lp[1]} WITH CONTROL without INTO - a table with a header line`);
        continue;
      }
      loop = { tableloop: lp[3], itab: lp[1]?.toLowerCase(), wa: lp[2]?.toLowerCase(), modules: [] };
      flow[section].push(loop);
      continue;
    }
    if (st === "ENDLOOP" && loop) {
      loop = undefined;
      continue;
    }
    if (section === "poh") {
      flow.poh = true;
      continue;
    }
    const m = /^(?:FIELD ([\w-]+) )?MODULE ([\w/]+)(?: (AT EXIT-COMMAND|ON INPUT|ON REQUEST|ON CHAIN-INPUT|ON CHAIN-REQUEST|AT CURSOR-SELECTION|ON \*-INPUT))?$/.exec(st);
    if (m && section) {
      const cond = { "AT EXIT-COMMAND": "exit", "ON INPUT": m[1] ? "input" : undefined, "AT CURSOR-SELECTION": "cursor" }[m[3]];
      if (/REQUEST|CHAIN-INPUT/.test(m[3] ?? "")) flow.request = true;
      (loop ? loop.modules : flow[section]).push({ module: m[2].toLowerCase(), cond, field: m[1] });
      continue;
    }
    if (/^FIELD:? [\w-]+(?:,? [\w-]+)*$/.test(st)) continue;
    // CALL SUBSCREEN area INCLUDING prog dynnr in the PBO, CALL SUBSCREEN
    // area in the PAI - a subscreen of this report
    const sub = /^CALL SUBSCREEN ([\w/]+)(?: INCLUDING (\S+) (\S+))?$/.exec(st);
    if (sub && (section === "pbo" ? sub[2] : !sub[2])) {
      if (sub[2] && !/^(SY-REPID|SY-CPROG)$/i.test(sub[2])) {
        flow.problems.push(`CALL SUBSCREEN ${sub[1].toUpperCase()} INCLUDING ${sub[2].toUpperCase()} - a subscreen of another program`);
        continue;
      }
      flow[section].push({ subscreen: sub[1].toUpperCase(), dynnr: sub[3] });
      continue;
    }
    flow.problems.push(`${st.split(" ").slice(0, 3).join(" ")} in the flow logic`);
  }
  return flow;
}

/** a row of a field catalog written as components - fieldname = 'A'
 *  coltext = 'T' no_out = abap_true - the column of the alv( ) chain */
export function fcatColumn(text) {
  const cur = {};
  for (const p of text.matchAll(/(\w+)\s*=\s*('(?:[^']|'')*'|`(?:[^`]|``)*`|[\w-]+)/g)) {
    const comp = lc(p[1]);
    if (comp === "fieldname") cur.name = uc(unquote(p[2]));
    else if (/^(seltext_[lms]|reptext_ddic|scrtext_[lms]|coltext)$/.test(comp)) cur.text = p[2];
    else if ((comp === "no_out" || comp === "tech") && /'x'|abap_true/i.test(p[2])) cur.hidden = true;
    else if (comp === "hotspot" && /'x'|abap_true/i.test(p[2])) cur.hotspot = true;
    else if (comp === "do_sum" && /'x'|abap_true/i.test(p[2])) cur.sum = true;
  }
  return cur;
}

/** the rows of VALUE type( ( ... ) ( ... ) ) - the text inside each row's
 *  parentheses; undefined when the text is no such VALUE */
export function valueRows(text) {
  const open = text.indexOf("(");
  if (open < 0) return undefined;
  const rows = [];
  let depth = 0;
  let start;
  let quote;
  for (let i = open + 1; i < text.length; i++) {
    const c = text[i];
    if (quote) {
      if (c === quote) quote = undefined;
      continue;
    }
    if (c === "'" || c === "`") quote = c;
    else if (c === "(") {
      if (depth === 0) start = i + 1;
      depth++;
    } else if (c === ")") {
      if (depth === 0) return rows;
      depth--;
      if (depth === 0) rows.push(text.slice(start, i));
    }
  }
  return undefined;
}

/** CASE field. WHEN `A`. ... ENDCASE. */
export function caseBody(param, entries) {
  const body = [`CASE ${param}.`];
  for (const e of entries) body.push(`  WHEN ${literal(e.field)}.`, ...e.body.map((l) => indent(l, 4)));
  body.push("ENDCASE.");
  return body;
}

/** whether z2ui5_cl_cgui_frontend has a constant or method of that name */
// the members of z2ui5_cl_cgui_abap_browser - the ones of cl_abap_browser it has
export const ABAP_BROWSER = ["show_html", "show_url", "show_xml", "close_browser", "html_line", "html_table", "small", "medium", "large",
  "xlarge", "landscape", "portrait", "topleft", "topright", "middle", "bottomleft", "bottomright", "navigate_off", "navigate_html"];

// the static methods of z2ui5_cl_cgui_demo_output - the methods of
// cl_demo_output it has
export const DEMO_OUTPUT = ["new", "write", "write_data", "write_text", "write_html", "write_json", "begin_section", "next_section",
  "end_section", "line", "display", "display_data", "display_text", "display_html", "display_json", "clear", "get"];

export function frontendMember(name) {
  const n = lc(name ?? "");
  return FRONTEND.constants.includes(n) || Object.hasOwn(FRONTEND.methods, n);
}

export function renderCall(method, imp, chg) {
  if (!imp.length && !chg.length) return `${method}( ).`;
  if (!chg.length && imp.length === 1) return `${method}( ${imp[0].value} ).`;
  if (!chg.length) return renderNamedCall(method, imp);
  const width = Math.max(...[...imp, ...chg].map((p) => p.name.length));
  const head = `${method}( `;
  const pad = " ".repeat(head.length);
  const lines = [];
  if (imp.length) {
    lines.push(`${head}EXPORTING`);
    for (const p of imp) lines.push(`${pad}  ${p.name.padEnd(width)} = ${p.value}`);
    lines.push(`${pad}CHANGING`);
  } else {
    lines.push(`${head}CHANGING`);
  }
  for (const p of chg) lines.push(`${pad}  ${p.name.padEnd(width)} = ${p.value}`);
  lines[lines.length - 1] += " ).";
  return lines.join("\n");
}

/** the fields READ LINE / MODIFY LINE ... FIELD VALUE name - the names of
 *  their WRITEs */
export function lineFieldNames(s) {
  const ch = s.getChildren();
  const tok = (c) => (isToken(c) ? uc(c.get().getStr()) : undefined);
  const at = ch.findIndex((c, i) => tok(c) === "VALUE" && tok(ch[i - 1]) === "FIELD");
  const out = [];
  if (at < 0) return out;
  for (let i = at + 1; i < ch.length; i++) {
    const t = tok(ch[i]);
    if (t === "INTO" || t === "FROM") {
      i++;
      continue;
    }
    if (t !== undefined || ["FIELD", "LINE"].includes(uc(nodeText(ch[i]).trim()))) break;
    out.push(underName(nodeText(ch[i])));
  }
  return out;
}

/** the member after cl_gui_frontend_services=> at toks[i] - lower case; a
 *  dynamic name in a literal, =>('CLIPBOARD_EXPORT'), as the static one */
export function frontendName(toks, i) {
  const t = toks[i + 2]?.getStr();
  if (t === "(" && /^'\w+'$/.test(toks[i + 3]?.getStr() ?? "") && toks[i + 4]?.getStr() === ")") return lc(unquote(toks[i + 3].getStr()));
  return t === undefined ? undefined : lc(t);
}

/** CALL TRANSACTION ... USING / OPTIONS FROM / MESSAGES INTO - batch input */
export function batchInput(s) {
  const w = words(s);
  return w.includes("USING") || w.includes("OPTIONS") || w.includes("MESSAGES");
}

export function renderNamedCall(method, params) {
  if (params.length === 1 && !params[0].name) return `${method}( ${params[0].value} ).`;
  const width = Math.max(...params.map((p) => p.name.length));
  const head = `${method}( `;
  return params.map((p, i) => `${i ? " ".repeat(head.length) : head}${p.name.padEnd(width)} = ${p.value}`).join("\n") + " ).";
}

/**
 * A call chain in the house layout of the samples: one call per line, the
 * parameters of a call aligned under each other.
 *
 *   write( val     = ls_flight-carrid
 *          hotspot = abap_true
 *       )->write( ls_flight-connid
 *       )->new_line( ).
 */
export function renderChain(chain) {
  const items = chain.items.map((it) => {
    const params = it.params.filter((p) => p.value !== undefined);
    // one parameter is written without its name, as omit_parameter_name asks
    const named = params.length > 1 || (params.length === 1 && params[0].name && params[0].name !== "val" && !it.positional && it.method !== "skip");
    return { ...it, params, named };
  });
  const lines = [];
  items.forEach((it, idx) => {
    const last = idx === items.length - 1;
    let head;
    if (idx === 0) head = ["write", "alv"].includes(it.method) ? `${it.method}(` : `list( )->${it.method}(`;
    else head = `    )->${it.method}(`;
    if (!it.params.length) {
      lines.push(last ? `${head} ).` : head);
      return;
    }
    if (!it.named) {
      lines.push(`${head} ${it.params[0].value}${last ? " )." : ""}`);
      return;
    }
    const width = Math.max(...it.params.map((p) => p.name.length));
    it.params.forEach((p, i) => {
      const prefix = i === 0 ? `${head} ` : " ".repeat(head.length + 1);
      lines.push(`${prefix}${p.name.padEnd(width)} = ${p.value}${last && i === it.params.length - 1 ? " )." : ""}`);
    });
  });
  return [lines.join("\n")];
}

/** the chain of selection_screen( ), as the painter writes it */
export function renderScreenChain(calls) {
  if (!calls.length) return [];
  const lines = [];
  calls.forEach((c, idx) => {
    const last = idx === calls.length - 1;
    const head = idx === 0 ? `screen->${c.method}(` : `    )->${c.method}(`;
    const named = c.params.length > 1 || (c.params.length === 1 && !c.positional && c.params[0].name !== "val");
    if (!c.params.length) {
      lines.push(last ? `${head} ).` : head);
      return;
    }
    if (!named) {
      lines.push(`${head} ${c.params[0].value}${last ? " )." : ""}`);
      return;
    }
    const width = Math.max(...c.params.map((p) => p.name.length));
    c.params.forEach((p, i) => {
      const prefix = i === 0 ? `${head} ` : " ".repeat(head.length + 1);
      lines.push(`${prefix}${p.name.padEnd(width)} = ${p.value}${last && i === c.params.length - 1 ? " )." : ""}`);
    });
  });
  return [lines.join("\n")];
}

/** the messages of the statements and function modules refused as a whole */
export const REFUSED_MESSAGES = () => [...Object.values(REFUSED), ...Object.entries(REFUSED_FUNCTIONS).map(([fm, m]) => `CALL FUNCTION '${fm}' - ${m}`)];
