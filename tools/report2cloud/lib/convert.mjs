// report2cloud - a classic ABAP report as an abap-cloud-gui report class.
//
//   import { convert } from "./lib/convert.mjs";
//   const result = convert(source, { file: "zflights.prog.abap", textpool });
//
// The report is parsed with @abaplint/core, the parser of the ecosystem, and
// rewritten statement by statement: PARAMETERS and SELECT-OPTIONS become
// PUBLIC attributes and the chain of selection_screen( ), the event blocks
// become the methods of z2ui5_cl_cgui_report with the same names, WRITE /
// ULINE / SKIP / FORMAT the calls of the list, CL_SALV_TABLE and
// REUSE_ALV_GRID_DISPLAY one alv( ) chain, MESSAGE message( ), FORMs private
// methods and PERFORM their calls. Everything else - the logic of the report
// - is copied as it is written.
//
// DETERMINISTIC, AND IT REFUSES RATHER THAN GUESSES
//
// The same report gives the same class, byte for byte - no time stamps, no
// heuristics that depend on anything but the source and its text pool. What
// has no counterpart in a browser app (CALL SCREEN, dynpro modules, batch
// input, SUBMIT, native SQL, ...) is refused with the file, the row and the
// column and the reason, the way cap2UI5's abap2js refuses: a conversion
// that comes out is meant to behave as the report did, and one that cannot
// says so instead of producing something that merely compiles. Every
// refusal is collected - the migration report lists all of them at once.
//
// What converts but needs a person or the AI step afterwards - a table that
// is not released on ABAP Cloud, a selection text the source does not carry,
// a formatting option of WRITE the list does not know - is a TODO of the
// migration report, with its position in the generated class.
import { createRequire } from "node:module";
import {
  abaplint, after, child, children, findAll, hasSeq, isToken, key, kind, lc, literal, nodeText,
  partTokens, renderTokens, stmtTokens, uc, unquote, words,
} from "./abap.mjs";
import { classXml, longLines, normalizeAbap } from "./abapgit.mjs";
import { functionKey } from "./textpool.mjs";
import { refusalOf } from "./refusals.mjs";

/** the refusal messages no entry of the catalogue matched - a gap there */
export const UNCATALOGUED = new Set();

const require = createRequire(import.meta.url);
const { Indent } = require("@abaplint/core/build/src/pretty_printer/indent");

// the event blocks of a report
const EVENTS = new Set(["Initialization", "LoadOfProgram", "AtSelectionScreen", "StartOfSelection",
  "EndOfSelection", "AtLineSelection", "AtUserCommand", "TopOfPage", "EndOfPage", "AtPF", "Get"]);

// declarations that are global in a report wherever they stand
const DECL = new Set(["Data", "DataBegin", "DataEnd", "Type", "TypeBegin", "TypeEnd", "IncludeType",
  "Constant", "ConstantBegin", "ConstantEnd", "Tables", "Parameter", "SelectOption", "SelectionScreen",
  "Ranges", "FieldSymbol", "TypePools", "TypePool", "Nodes", "Controls", "StaticBegin", "StaticEnd", "Static",
  "TypeEnum", "TypeEnumBegin", "TypeEnumEnd"]);

// statements with no counterpart - refused wherever they stand
const REFUSED = {
  CallScreen: "CALL SCREEN - the dynpro is not converted (a dynpro of fields is, from the .prog.xml - see the MODULE refusals); else build the screen as an abap2UI5 view or a popup",
  SetScreen: "SET SCREEN - dynpro flow logic has no counterpart",
  CallDialog: "CALL DIALOG - dialog modules have no counterpart",
  CallTransaction: "CALL TRANSACTION - no SAP GUI transaction can be started from a browser app (batch input with USING is no API on ABAP Cloud either); call the released API of the application instead",
  ExecSQL: "EXEC SQL - native SQL is not available on ABAP Cloud; use ABAP SQL on a released CDS view",
  Module: "MODULE - the .prog.xml has no screens (DYNPROS); a dynpro of fields is converted from them",
  Include: "INCLUDE - no such include beside the report (as <include>.prog.abap, the name abapGit writes); put it there, or name its folder with --includes",
  Nodes: "NODES - logical databases have no counterpart; read the data with ABAP SQL",
  Get: "GET - logical database events have no counterpart; read the data with ABAP SQL",
  Reject: "REJECT - logical database statement",
  Controls: "CONTROLS - table controls and tabstrips belong to dynpros",
  GetCursor: "GET CURSOR - not converted; in at_line_selection( ) get_cursor( ) returns field, value, line and offset - port it by hand",
  ReadLine: "READ LINE - not converted; list( )->read_line( ) / read_value( ) read the list back - port it by hand, or keep the data in an internal table",
  ModifyLine: "MODIFY LINE - not converted; list( )->modify_line( ) changes a written line - port it by hand",
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
const POPUPS = new Set(["POPUP_TO_CONFIRM", "POPUP_TO_CONFIRM_STEP", "POPUP_TO_DECIDE", "POPUP_GET_VALUES"]);

// function modules with no counterpart on a browser app - refused
const REFUSED_FUNCTIONS = {
  POPUP_TO_CONFIRM_WITH_MESSAGE: "POPUP_TO_CONFIRM_WITH_MESSAGE waits for the answer and shows a T100 message - use popup_to_decide( ) with the message text and go on in at_user_command( )",
  POPUP_TO_DECIDE_WITH_MESSAGE: "POPUP_TO_DECIDE_WITH_MESSAGE waits for the answer and shows a T100 message - use popup_to_decide( ) with the message text and go on in at_user_command( )",
  POPUP_TO_DECIDE_LIST: "POPUP_TO_DECIDE_LIST waits for the choice - use popup_to_decide( ) with the options and go on in at_user_command( )",
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
const LAYOUT_ONLY = {
  Back: "BACK - the list has no columns",
  Summary: "SUMMARY - the list knows no intensified output",
  Detail: "DETAIL - the list knows no intensified output",
  SetLeft: "SET LEFT SCROLL-BOUNDARY - the list does not scroll horizontally",
  SetMargin: "SET MARGIN - printing is not supported",
  SetBlank: "SET BLANK LINES - the list writes no blank lines",
};

// FORMAT COLOR / WRITE COLOR - the colors of the list are UI5 value states
const COLORS = {
  COL_BACKGROUND: "none", 0: "none", OFF: "none",
  COL_HEADING: "key", 1: "key",
  COL_NORMAL: "none", 2: "none",
  COL_TOTAL: "total", 3: "total",
  COL_KEY: "key", 4: "key",
  COL_POSITIVE: "positive", 5: "positive",
  COL_NEGATIVE: "negative", 6: "negative",
  COL_GROUP: "total", 7: "total",
};
const colorConst = (c) => `z2ui5_cl_cgui_list=>cs_color-${c}`;

// WRITE ... AS ICON with an icon of type pool ICON - the UI5 icon that shows
// the same, from the icons that exist in UI5 1.71
const ICONS = {
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
const LVC_TYPES = {
  lvc_t_row: "z2ui5_cl_cgui_alv=>ty_t_lvc_row", lvc_s_row: "z2ui5_cl_cgui_alv=>ty_s_lvc_row",
  lvc_t_roid: "z2ui5_cl_cgui_alv=>ty_t_lvc_roid", lvc_s_roid: "z2ui5_cl_cgui_alv=>ty_s_lvc_roid",
  lvc_s_col: "z2ui5_cl_cgui_alv=>ty_s_lvc_col",
  // the file table of cl_gui_frontend_services=>file_open_dialog( )
  filetable: "z2ui5_cl_cgui_frontend=>ty_t_file_table", file_table: "z2ui5_cl_cgui_frontend=>ty_s_file_table",
};

// the statements that open and close a block
const OPENERS = new Set(["If", "Case", "Loop", "Do", "While", "SelectLoop", "Try", "At", "AtFirst", "AtLast", "OnChange", "Provide", "LoopAtScreen"]);
const CLOSERS = new Set(["EndIf", "EndCase", "EndLoop", "EndDo", "EndWhile", "EndSelect", "EndTry", "EndAt", "EndOn", "EndProvide"]);

// SAP GUI controls - they need a dynpro container
const GUI_CONTROL = /\bcl_gui_(alv_grid|custom_container|docking_container|splitter_container|dialogbox_container|container|html_viewer|textedit|picture|toolbar|simple_tree|column_tree|list_tree|gos_container|easy_splitter_container)\b/;

// z2ui5_cl_cgui_frontend - CL_GUI_FRONTEND_SERVICES in the browser: its
// constants and methods, the parameters and classic exceptions of each. A
// call of cl_gui_frontend_services=> becomes a call of it when it names
// only these; a test compares the table with the class
export const FRONTEND = {
  constants: ["action_ok", "action_cancel", "filetype_all", "filetype_text", "filetype_excel", "filetype_xml", "filetype_html"],
  methods: {
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
const FRONTEND_FUNCTIONS = { GUI_UPLOAD: "gui_upload", GUI_DOWNLOAD: "gui_download" };

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
    cl_gui_easy_splitter_container: "z2ui5_cl_cgui_gui_easy_split",
    cl_gui_textedit: "z2ui5_cl_cgui_gui_textedit",
    cl_gui_html_viewer: "z2ui5_cl_cgui_gui_html_viewer",
    cl_gui_toolbar: "z2ui5_cl_cgui_gui_toolbar",
    cl_gui_alv_grid: "z2ui5_cl_cgui_gui_alv_grid",
    cl_alv_event_toolbar_set: "z2ui5_cl_cgui_gui_alv_toolbar",
  },
  members: {
    z2ui5_cl_cgui_gui: {
      constants: ["true", "false"],
      attributes: [],
      events: [],
      methods: {
        set_report: { params: ["report"],
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
        dispatch: { params: ["event", "value"],
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
      constants: ["wordwrap_off", "wordwrap_at_windowborder", "wordwrap_at_fixed_position", "dropfile_event_off", "dropfile_event_single", "dropfile_event_multiple"],
      attributes: [],
      events: [],
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
        sapevent_links: { params: ["html"], exceptions: [] },
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
      },
    },
    z2ui5_cl_cgui_gui_toolbar: {
      parent: "z2ui5_cl_cgui_gui",
      constants: ["cntb_btype_button", "cntb_btype_dropdown", "cntb_btype_menu", "cntb_btype_sep", "cntb_btype_group", "cntb_btype_check", "m_id_function_selected", "m_id_dropdown_clicked"],
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
function withoutConstructorArgs(text) {
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
const GRID_VALUE_TYPES = {
  is_layout: "lvc_s_layo", is_variant: "disvariant", is_print: "lvc_s_prnt", is_stable: "lvc_s_stbl",
  it_toolbar_excluding: "ui_functions", it_sort: "lvc_t_sort", it_filter: "lvc_t_filt",
  it_fieldcatalog: "lvc_t_fcat", it_special_groups: "lvc_t_sgrp", it_hyperlink: "lvc_t_hype",
  it_except_qinfo: "lvc_t_qinf",
};
const guiClass = (name) => (Object.hasOwn(GUI.classes, name) ? GUI.classes[name] : undefined);

/** whether a stand-in or one of its parents raises the event */
function guiEvent(cls, name) {
  for (let c = cls; c; c = GUI.members[c]?.parent) if (GUI.members[c]?.events.includes(name)) return true;
  return false;
}

/** the member of a stand-in or of one of its parents - undefined if none has it */
function guiMember(cls, name) {
  for (let c = cls; c; c = GUI.members[c]?.parent) {
    const m = GUI.members[c];
    if (!m) return undefined;
    if (Object.hasOwn(m.methods, name)) return { kind: "method", ...m.methods[name] };
    if (m.constants.includes(name) || m.attributes.includes(name)) return { kind: "attribute" };
  }
  return undefined;
}

// statements a body keeps chained when the report chains them
const CHAINABLE = new Set(["Clear", "Free", "Data", "DataBegin", "DataEnd", "Constant", "Type", "TypeBegin", "TypeEnd", "Static", "FieldSymbol", "Refresh"]);

// the screen fields LOOP AT SCREEN / MODIFY SCREEN can change here, and how
const SCREEN_FLAGS = new Set(["active", "input", "required", "invisible"]);
const SCREEN_FIELDS = new Set(["name", "group1", ...SCREEN_FLAGS]);

// the PUBLIC and PROTECTED methods and attributes of z2ui5_cl_cgui_report -
// a FORM must not take one as method name, a global of the report not as
// attribute name (methods and attributes share one namespace in a class)
const BASE_METHODS = ["cgui_run_in_background",
  "initialization", "selection_screen", "at_selection_screen_output", "at_selection_screen_on",
  "at_selection_screen", "start_of_selection", "end_of_selection", "end_of_page", "at_selection_screen_on_block",
  "at_selection_screen_on_radio", "at_selection_screen_on_end_of", "at_selection_screen_on_help",
  "at_selection_screen_on_exit", "top_of_page", "top_of_page_line_selection", "at_line_selection", "at_link_click",
  "at_tree_node", "at_tree_checkbox", "at_tree_expand_no_children", "at_data_changed", "at_user_command",
  "at_value_request", "value_request_part", "at_alv_value_request", "authority_check",
  "selection_screen_dynnr", "after_call_selection_screen", "write", "format", "get_cursor", "lisel",
  "set_cursor_field", "set_selscreen_status", "list", "alv", "tree", "get_selected_rows", "lsind", "message",
  "message_t100", "messages_from_bapiret", "popup_to_confirm", "popup_to_decide",
  "popup_get_values", "popup_get_values_sval", "popup_values_sval", "popup_answer", "popup_values", "value_help_popup", "vrm_set_values",
  "leave_to_selection_screen", "window", "call_selection_screen", "submit", "set_parameter_id", "get_parameter_id",
  "set_line_count", "set_pf_status", "set_title", "set_variant", "set_variant_store", "set_layout_store", "get_link",
  "current_screen", "dynpro_screen", "dynpro_pbo", "dynpro_pai", "after_call_screen",
  "call_screen", "set_screen", "leave_to_screen", "leave_screen", "screen_left"];
export const RESERVED_METHODS = new Set([...BASE_METHODS, "client", "cs_ucomm", "z2ui5_if_app~main", "main",
  "at_selection_screen_ucomm", "constructor"]);

const BUILTIN_TYPES = new Set(["string", "xstring", "i", "int1", "int2", "int4", "int8", "d", "t", "f", "c", "n",
  "x", "p", "decfloat16", "decfloat34", "utclong", "abap_bool", "any", "data", "simple", "clike", "csequence",
  "xsequence", "numeric", "decfloat", "object", "table", "index", "standard", "sorted", "hashed", "line", "ref",
  "abap_true", "abap_false", "string_table", "sy", "syst", "char1", "boolean", "abap_boolean", "timestamp",
  "timestampl", "sydatum", "syuzeit", "syuname", "symsgid", "symsgty", "symsgno", "symsgv", "sytabix",
  "xsdboolean", "abap_char1", "abap_typekind", "ty_t_cgui_value", "ty_s_cgui_value"]);

// well-known on-premise tables and their released successors on ABAP Cloud
// (a hint for the person or the AI step - verify before using it)
const SUCCESSORS = {
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

class Converter {
  constructor(source, opts) {
    this.source = source.replace(/\r\n?/g, "\n");
    this.lines = this.source.split("\n");
    this.file = opts.file ?? "zreport.prog.abap";
    // where a row of the source came from - an include inlined before the
    // parse (lib/includes.mjs), or the report itself
    this.origin = opts.origin ?? ((row) => ({ file: this.file, row }));
    this.pool = opts.textpool ?? { title: "", symbols: new Map(), selection: new Map() };
    this.deps = opts.deps ?? [];
    this.programName = opts.programName;
    this.className = opts.className;
    // classFor(program) names the class of another report of the input -
    // the one a SUBMIT starts; undefined when the report is not there
    this.classFor = opts.classFor;
    this.refusals = [];
    this.mapped = [];
    this.todos = [];
    this.notes = new Map();
  }

  // ---------------------------------------------------------------- report

  refuse(at, message) {
    const tok = at && (at.getFirstToken ? at.getFirstToken() : at);
    // its entry of the catalogue (lib/refusals.mjs) - why, and the rewrite
    const entry = refusalOf(message);
    if (!entry) UNCATALOGUED.add(message);
    this.refusals.push({ row: tok ? tok.getRow() : 0, col: tok ? tok.getCol() : 0, message, code: entry?.id ?? "other" });
  }

  /** "line 12", or "line 12 of zx_top.prog.abap" for a row of an include */
  where(row) {
    const o = this.origin(row);
    return o.file !== this.file && o.file !== this.file.split("/").pop() ? `line ${o.row} of ${o.file}` : `line ${o.row}`;
  }

  map(s, target) {
    const first = s.getFirstToken();
    let text = renderTokens(stmtTokens(s), new Map(), s.getColon()).replace(/\s+/g, " ");
    if (text.length > 70) text = text.slice(0, 67) + "...";
    const pos = s.getColon() ? partTokens(s)[0] ?? first : first;
    this.mapped.push({ row: pos.getRow(), col: pos.getCol(), classic: text, target });
  }

  todo(s, message) {
    const first = s && s.getFirstToken();
    this.todos.push({ row: first ? first.getRow() : 0, col: first ? first.getCol() : 0, message });
  }

  note(text) {
    this.notes.set(text, (this.notes.get(text) ?? 0) + 1);
  }

  // ----------------------------------------------------------------- parse

  parse() {
    const name = this.programName ?? "zreport";
    const config = abaplint.Config.getDefault().get();
    config.syntax = { version: abaplint.Version.v758, errorNamespace: "." };
    const reg = new abaplint.Registry(new abaplint.Config(JSON.stringify(config)));
    const progFile = `${lc(name).replace(/\//g, "#")}.prog.abap`;
    reg.addFile(new abaplint.MemoryFile(progFile, this.source));
    // the report's classes, interfaces and DDIC objects (lib/deps.mjs) - to
    // type what the report reads of them, never converted
    for (const d of this.deps) if (d.name !== progFile) reg.addFile(new abaplint.MemoryFile(d.name, d.text));
    reg.parse();
    this.program = reg.getObject("PROG", uc(name)) ?? reg.getFirstObject();
    const file = this.program.getABAPFiles()[0];
    this.stmts = file.getStatements().filter((s) => kind(s) !== "Empty");
    this.registry = reg;
  }

  /**
   * A global DATA or CONSTANTS named like a component of the report class -
   * MESSAGE, LIST - becomes an attribute of that name, which the class
   * cannot have. It is renamed in the source before the conversion: the
   * declaration and every field of that name, not a component (wa-message),
   * not a keyword. Parameters and select-options keep their names - the
   * text pool and SUBMIT ... WITH know them - and are refused later.
   * Returns whether the source was changed.
   */
  renameReserved() {
    const scope = new Set();
    let depth = 0;
    for (const s of this.stmts) {
      const k = kind(s);
      if (["Form", "MethodImplementation", "FunctionModule", "ClassImplementation", "ClassDefinition", "Interface"].includes(k)) depth++;
      if (["EndForm", "EndMethod", "EndFunction", "EndClass", "EndInterface"].includes(k)) depth = Math.max(0, depth - 1);
      if (depth || !["Data", "DataBegin", "Constant", "ConstantBegin"].includes(k)) continue;
      const name = lc(declName(s) ?? "");
      if (RESERVED_METHODS.has(name)) scope.add(name);
    }
    if (!scope.size) return false;
    const taken = new Set(this.stmts.flatMap((s) => stmtTokens(s).map((t) => lc(t.getStr()))));
    const renamed = new Map();
    for (const n of scope) {
      let to = `gv_${n}`.slice(0, 30);
      for (let i = 2; taken.has(to); i++) to = `gv_${n}${i}`.slice(0, 30);
      taken.add(to);
      renamed.set(n, to);
    }
    const edits = [];
    for (const s of this.stmts) {
      const parents = tokenParents(s);
      const toks = stmtTokens(s);
      toks.forEach((t, i) => {
        const to = renamed.get(lc(t.getStr()));
        if (!to) return;
        const prev = toks[i - 1];
        if (prev && (["->", "=>", "~"].includes(prev.getStr()) || (prev.getStr() === "-" && prev.constructor.name === "Dash"))) return;
        if (!["Field", "DefinitionName", "FieldSub", "SimpleFieldChain", "FieldChain", "Source", "Target"].includes(parents.get(key(t)))) return;
        edits.push({ row: t.getRow(), col: t.getCol(), len: t.getStr().length, to });
      });
    }
    if (!edits.length) return false;
    const lines = this.source.split("\n");
    edits.sort((a, b) => b.row - a.row || b.col - a.col);
    for (const e of edits) {
      const l = lines[e.row - 1];
      lines[e.row - 1] = l.slice(0, e.col - 1) + e.to + l.slice(e.col - 1 + e.len);
    }
    this.source = lines.join("\n");
    this.lines = lines;
    for (const [from, to] of renamed) {
      this.note(`the global ${uc(from)} is the name of a component of z2ui5_cl_cgui_report - renamed to ${to}`);
    }
    return true;
  }

  /**
   * PARAMETERS p TYPE (name) / SELECT-OPTIONS s FOR (name) whose name is a
   * literal, or a global DATA with a literal VALUE that nothing else names:
   * the type is known when the class is written. TYPE (name) becomes TYPE
   * <type>; FOR (name) needs a data object - a DATA <s>_type TYPE <type>
   * goes before it. A name that is set at runtime stays a refusal.
   * Returns whether the source was changed.
   */
  resolveDynamicTypes() {
    const values = new Map();     // global DATA name -> literal VALUE
    const uses = new Map();       // name -> occurrences outside (name)
    let depth = 0;
    for (const s of this.stmts) {
      const k = kind(s);
      if (["Form", "MethodImplementation", "FunctionModule", "ClassImplementation", "ClassDefinition", "Interface"].includes(k)) depth++;
      if (["EndForm", "EndMethod", "EndFunction", "EndClass", "EndInterface"].includes(k)) depth = Math.max(0, depth - 1);
      const toks = stmtTokens(s);
      if (!depth && k === "Data") {
        const at = toks.findIndex((t) => uc(t.getStr()) === "VALUE");
        const lit = toks[at + 1]?.getStr();
        if (at > 0 && /^['`][^'`]*['`]$/.test(lit ?? "") && toks.length === at + 2) {
          values.set(lc(declName(s) ?? ""), lit.slice(1, -1));
          continue;
        }
      }
      toks.forEach((t, i) => {
        const n = lc(t.getStr());
        if (toks[i - 1]?.getStr() === "(" && toks[i + 1]?.getStr() === ")" && ["TYPE", "LIKE", "FOR"].includes(uc(toks[i - 2]?.getStr() ?? ""))) return;
        uses.set(n, (uses.get(n) ?? 0) + 1);
      });
    }
    const taken = new Set(this.stmts.flatMap((s) => stmtTokens(s).map((t) => lc(t.getStr()))));
    const edits = [];
    for (const s of this.stmts) {
      const k = kind(s);
      if (k !== "Parameter" && k !== "SelectOption") continue;
      const toks = stmtTokens(s);
      const at = toks.findIndex((t, i) => ["TYPE", "LIKE", "FOR"].includes(uc(t.getStr())) && toks[i + 1]?.getStr() === "(" && toks[i + 3]?.getStr() === ")");
      if (at < 0) continue;
      const inner = toks[at + 2].getStr();
      const name = /^'([^']*)'$/.exec(inner)?.[1]
        ?? (values.has(lc(inner)) && !uses.has(lc(inner)) ? values.get(lc(inner)) : undefined);
      if (!name || !/^[A-Za-z_/][\w/]*(-[\w/]+)?$/.test(name.trim())) continue;
      const type = lc(name.trim());
      const open = toks[at + 1];
      const close = toks[at + 3];
      if (close.getRow() !== open.getRow()) continue;
      if (k === "Parameter") {
        // LIKE (name) of a DDIC field is TYPE of it
        edits.push({ row: toks[at].getRow(), col: toks[at].getCol(), len: close.getCol() + 1 - toks[at].getCol(), to: `TYPE ${type}` });
      } else {
        const so = lc(declName(s) ?? "so");
        let helper = `${so}_type`.slice(0, 30);
        for (let i = 2; taken.has(helper); i++) helper = `${so}_type${i}`.slice(0, 30);
        taken.add(helper);
        edits.push({ row: open.getRow(), col: open.getCol(), len: close.getCol() + 1 - open.getCol(), to: helper });
        // the helper on the line of the statement - the rows stay as they are
        const first = toks[0];
        edits.push({ row: first.getRow(), col: first.getCol(), len: 0, to: `DATA ${helper} TYPE ${type}. ` });
      }
      this.note(`${uc(declName(s) ?? "")} ${uc(toks[at].getStr())} (${inner}) - the name is fixed (${uc(type)}), so the field is typed with it when the class is written`);
    }
    if (!edits.length) return false;
    const lines = this.source.split("\n");
    edits.sort((a, b) => b.row - a.row || b.col - a.col);
    for (const e of edits) {
      const l = lines[e.row - 1];
      lines[e.row - 1] = l.slice(0, e.col - 1) + e.to + l.slice(e.col - 1 + e.len);
    }
    this.source = lines.join("\n");
    this.lines = lines;
    return true;
  }

  /**
   * %_p_x_%_app_%-text = '...' - the label of a field of the selection
   * screen set at runtime (in INITIALIZATION, usually). It becomes a global
   * gv_label_<field>, declared on the line of REPORT, and the screen shows
   * it while it is set (screenLabels). Returns whether the source changed.
   */
  resolveScreenLabels() {
    const edits = [];
    const fields = new Set();
    const taken = new Set(this.stmts.flatMap((s) => stmtTokens(s).map((t) => lc(t.getStr()))));
    const names = new Map();
    for (const s of this.stmts) {
      const toks = stmtTokens(s);
      toks.forEach((t, i) => {
        const m = /^%_([\w/]+?)_%_app_%$/i.exec(t.getStr());
        if (!m || toks[i + 1]?.getStr() !== "-" || lc(toks[i + 2]?.getStr() ?? "") !== "text") return;
        const field = lc(m[1]);
        if (!names.has(field)) {
          let v = `gv_label_${field}`.slice(0, 30);
          for (let n = 2; taken.has(v); n++) v = `gv_label${n}_${field}`.slice(0, 30);
          taken.add(v);
          names.set(field, v);
        }
        fields.add(field);
        const last = toks[i + 2];
        edits.push({ row: t.getRow(), col: t.getCol(), len: last.getCol() + last.getStr().length - t.getCol(), to: names.get(field) });
      });
    }
    if (!edits.length) return false;
    // the declarations after REPORT - the rows stay as they are
    const report = this.stmts.find((s) => kind(s) === "Report") ?? this.stmts[0];
    const dot = report.getTokens().at(-1);
    edits.push({ row: dot.getRow(), col: dot.getCol() + 1, len: 0, to: ` ${[...names.values()].map((v) => `DATA ${v} TYPE string.`).join(" ")}` });
    const lines = this.source.split("\n");
    edits.sort((a, b) => b.row - a.row || b.col - a.col);
    for (const e of edits) {
      const l = lines[e.row - 1];
      lines[e.row - 1] = l.slice(0, e.col - 1) + e.to + l.slice(e.col - 1 + e.len);
    }
    this.source = lines.join("\n");
    this.lines = lines;
    this.screenLabels = names;
    this.note(`the labels of ${[...fields].map(uc).join(", ")} set at runtime (%_..._%_app_%-text) - the global ${[...names.values()].join(", ")}, shown while set`);
    return true;
  }

  /** the types abaplint's syntax check gives the variables of the program
   *  scope (name -> abaplint type) - for the inline declarations of the
   *  event blocks; an unknown dependency gives a void type */
  programTypes() {
    if (this.progTypes) return this.progTypes;
    this.progTypes = new Map();
    try {
      const res = new abaplint.SyntaxLogic(this.registry, this.program).run();
      const visit = (n) => {
        if (n.getIdentifier().stype === "program" || n.getIdentifier().stype === "Program" || /program/i.test(String(n.getIdentifier().stype))) {
          for (const [name, v] of Object.entries(n.getData().vars)) this.progTypes.set(lc(name), v.getType());
        }
        for (const c of n.getChildren()) visit(c);
      };
      visit(res.spaghetti.getTop());
    } catch {
      // no types - the inline declarations stay where they are
    }
    return this.progTypes;
  }

  /**
   * An inline declaration in an event block - DATA(x) = ... in
   * INITIALIZATION - is a global of the report: event blocks open no scope.
   * Where another event block, a FORM or a local class reads it, it becomes
   * an attribute of the class, typed as abaplint's syntax check types it
   * (or as the constructor expression names it); the event block assigns
   * it. A type that cannot be told is refused - the class would not compile.
   */
  hoistInlineData() {
    this.hoisted = new Map();          // name -> { decl, tokens: Set of keys }
    const inEvents = [];
    for (const e of this.events) {
      for (const s of e.stmts) for (const d of findAll(s, "InlineData")) inEvents.push({ e, s, d, name: lc(d.getTokens()[2]?.getStr() ?? "") });
    }
    if (!inEvents.length) return;
    // a read of the field - not a keyword of the same name (CLASS, METHODS),
    // and not in a FORM or local class that declares a field of its own
    const reads = (x, name) => {
      const parents = tokenParents(x);
      return stmtTokens(x).some((t) => lc(t.getStr()) === name && parents.get(key(t)) === "Field");
    };
    const declares = (list, name) => list.some((x) => findAll(x, "InlineData").some((d) => lc(d.getTokens()[2]?.getStr() ?? "") === name) ||
      (kind(x) === "Data" && lc(findAll(x, "DefinitionName")[0]?.getFirstToken().getStr() ?? "") === name));
    const elsewhere = (e, name) => {
      const own = [...this.forms.map((f) => f.body), ...this.locals.map((u) => u.stmts)].filter((list) => !declares(list, name));
      const units = [...this.events.filter((x) => x !== e).map((x) => x.stmts), ...own];
      return units.some((list) => list.some((x) => reads(x, name)));
    };
    for (const v of inEvents) {
      if (!v.name || this.hoisted.has(v.name) || this.globalData.has(v.name) || !elsewhere(v.e, v.name)) continue;
      let type = this.inlineType(v);
      if (!type) {
        this.refuse(v.d, `${v.name} is declared inline in an event block and used in another one - event blocks open no scope, so it is a global of the report; its type cannot be told here (a dependency of the report): declare it with DATA in the report`);
        continue;
      }
      this.hoisted.set(v.name, { decl: `DATA ${v.name} ${type}.`, stmt: v.s, keys: new Set(v.d.getTokens().map(key)) });
      this.globalData.add(v.name);
    }
  }

  /** the type of an inline declaration: from the constructor expression,
   *  else from abaplint's syntax check */
  inlineType(v) {
    const text = renderTokens(stmtTokens(v.s)).replace(/\s+/g, " ");
    const name = v.d.getTokens()[2]?.getStr() ?? "";
    const esc = name.replace(/[<>]/g, "\\$&");
    let m = new RegExp(`^DATA\\(\\s*${esc}\\s*\\)\\s*=\\s*NEW\\s+([\\w/]+)\\s*\\(`, "i").exec(text);
    if (m) return `TYPE REF TO ${lc(m[1])}`;
    m = new RegExp(`^DATA\\(\\s*${esc}\\s*\\)\\s*=\\s*(VALUE|CONV|CORRESPONDING|EXACT)\\s+([\\w/]+(?:-[\\w/]+|=>[\\w/]+)*)\\s*\\(`, "i").exec(text);
    if (m) return `TYPE ${lc(m[2])}`;
    m = new RegExp(`^DATA\\(\\s*${esc}\\s*\\)\\s*=\\s*CAST\\s+([\\w/]+)\\s*\\(`, "i").exec(text);
    if (m) return `TYPE REF TO ${lc(m[1])}`;
    const t = this.programTypes().get(lc(name));
    if (!t) return undefined;
    const cls = t.constructor.name;
    if (["VoidType", "UnknownType", "GenericObjectReferenceType", "AnyType", "DataType", "SimpleType"].includes(cls)) return undefined;
    let abap;
    try {
      abap = t.toABAP?.();
    } catch {
      // a type of an unknown dependency deeper inside - a table of it
      return undefined;
    }
    if (!abap || /todo|check_syntax|\bSELECT_/i.test(abap)) return undefined;
    if (cls === "ObjectReferenceType" || cls === "DataReference") return `TYPE ${abap}`;
    return `TYPE ${abap}`;
  }

  run() {
    this.parse();
    if (this.renameReserved()) this.parse();
    if (this.resolveDynamicTypes()) this.parse();
    if (this.resolveScreenLabels()) this.parse();
    this.segment();
    if (!this.programName && this.header) this.programName = lc(this.header.name);
    this.programName = this.programName ?? "zreport";
    this.className = lc(this.className ?? defaultClassName(this.programName));
    this.analyze();
    const out = this.generate();
    return out;
  }

  // ---------------------------------------------------------------- segment

  /** the report as units: the global declarations, the event blocks, the
   *  FORMs and the local classes, each with its statements */
  segment() {
    this.decls = [];
    this.modules = [];      // MODULE ... OUTPUT / INPUT - the dynpro of a grid
    this.events = [];
    this.forms = [];
    this.locals = [];
    this.header = undefined;
    this.lineCount = undefined;
    let current;           // the unit statements go to
    let implicit;          // statements before the first event: START-OF-SELECTION
    let pendingComments = [];

    for (let i = 0; i < this.stmts.length; i++) {
      const s = this.stmts[i];
      const k = kind(s);

      if (k === "Unknown") {
        this.refuse(s, `the parser does not understand this statement - a syntax error, or a statement of a newer release: ${shortText(s)}`);
        continue;
      }
      // The parser expands a macro at every call: the statements of the
      // call follow it here, at the call's position, and are converted like
      // any other. The definition and the call themselves are not carried
      // over - a class has no macros.
      if (k === "MacroCall") {
        this.map(s, "the statements of the macro, expanded at the call");
        continue;
      }
      if (k === "MacroContent") continue;
      if (k === "Comment") {
        // a comment belongs to the statement after it - trailing comments
        // of a block (the banner of the next FORM) are dropped
        pendingComments.push(s);
        continue;
      }
      if (k === "Report" || k === "Program") {
        const name = child(s, "ReportName");
        const msg = child(s, "MessageClass");
        this.header = { name: name ? nodeText(name) : "zreport", messageClass: msg ? uc(nodeText(msg)) : "" };
        // LINE-COUNT n(m): n lines a page, m of them the footer of END-OF-PAGE
        const w = words(s);
        if (hasSeq(w, "LINE", "-", "COUNT")) {
          const pos = s.getChildren().findIndex((c) => isToken(c) && uc(c.get().getStr()) === "COUNT");
          const ints = s.getChildren().slice(pos + 1).filter((c) => kind(c) === "Integer").map((n) => nodeText(n));
          if (ints.length) this.lineCount = { lines: ints[0], footer: ints.length > 1 && ints[1] !== "0", stmt: s };
        }
        this.map(s, "the class, `INHERITING FROM z2ui5_cl_cgui_report`");
        pendingComments = [];
        continue;
      }
      if (k === "Module") {
        // kept for the screen of a cl_gui_alv_grid (resolveGridScreen), else refused
        const end = this.findEnd(i, "EndModule");
        this.modules.push({
          stmt: s, name: lc(nodeText(child(s, "FormName"))), io: words(s).includes("OUTPUT") ? "OUTPUT" : "INPUT",
          body: this.stmts.slice(i + 1, end).filter((x) => kind(x) !== "Empty"),
        });
        i = end;
        current = undefined;
        pendingComments = [];
        continue;
      }
      if (k === "Define") {
        this.map(s, "nothing - the macro is expanded at every call");
        i = this.findEnd(i, "EndOfDefinition");
        pendingComments = [];
        continue;
      }
      if (k === "Form") {
        const end = this.findEnd(i, "EndForm");
        this.forms.push({ stmt: s, body: this.stmts.slice(i + 1, end).filter((x) => kind(x) !== "Empty"), end: this.stmts[end] });
        i = end;
        current = undefined;
        pendingComments = [];
        continue;
      }
      if (["ClassDefinition", "ClassImplementation", "Interface", "ClassDeferred", "InterfaceDeferred",
        "ClassDefinitionLoad", "InterfaceLoad"].includes(k)) {
        let end = i;
        if (k === "ClassDefinition" || k === "ClassImplementation") end = this.findEnd(i, "EndClass");
        if (k === "Interface") end = this.findEnd(i, "EndInterface");
        this.locals.push({ kind: k, stmts: this.stmts.slice(i, end + 1), comments: pendingComments });
        pendingComments = [];
        i = end;
        current = undefined;
        continue;
      }
      if (EVENTS.has(k)) {
        current = { stmt: s, kind: k, stmts: [] };
        this.events.push(current);
        pendingComments = [];
        continue;
      }
      if (DECL.has(k)) {
        // global in a report, wherever it stands - a run of BEGIN OF ... END
        // OF is taken as a whole
        const end = this.declEnd(i);
        // the same DATA x TYPE t in two event blocks declares the one global
        // twice - kept once, an attribute can be declared once only
        const text = (x) => renderTokens(stmtTokens(x)).replace(/\s+/g, " ").toLowerCase();
        const again = end === i && k === "Data" && this.decls.some((x) => kind(x) === "Data" && text(x) === text(s));
        // a comment inside the run (TYPES: a TYPE i, "comment) would cut a
        // chain in two - it is left out
        if (!again) {
          for (let j = i; j <= end; j++) if (j === i || kind(this.stmts[j]) !== "Comment") this.decls.push(this.stmts[j]);
        } else this.note(`DATA ${lc(declName(s) ?? "")} is declared twice the same way - an attribute of the class once`);
        i = end;
        pendingComments = [];
        continue;
      }
      if (!current) {
        // executable statements before the first event belong to
        // START-OF-SELECTION
        if (!implicit) {
          implicit = { stmt: s, kind: "StartOfSelection", implicit: true, stmts: [] };
          this.events.push(implicit);
        }
        current = implicit;
      }
      current.stmts.push(...pendingComments, s);
      pendingComments = [];
    }
  }

  findEnd(i, endKind) {
    for (let j = i + 1; j < this.stmts.length; j++) {
      if (kind(this.stmts[j]) === endKind) return j;
    }
    this.refuse(this.stmts[i], `no ${endKind.replace(/([a-z])([A-Z])/g, "$1 $2").toUpperCase()} for this statement`);
    return this.stmts.length - 1;
  }

  declEnd(i) {
    const begins = { DataBegin: "DataEnd", TypeBegin: "TypeEnd", ConstantBegin: "ConstantEnd", StaticBegin: "StaticEnd", TypeEnumBegin: "TypeEnumEnd" };
    const k = kind(this.stmts[i]);
    if (!begins[k]) return i;
    let depth = 0;
    for (let j = i; j < this.stmts.length; j++) {
      const kj = kind(this.stmts[j]);
      if (kj === k) depth++;
      if (kj === begins[k]) depth--;
      if (depth === 0) return j;
    }
    return i;
  }

  // ---------------------------------------------------------------- analyze

  analyze() {
    this.initializationWithoutScreen();
    this.resolveGridScreen();
    // the names of the report's global data objects and types
    this.globalData = new Set();
    this.globalTypes = new Set();
    for (const s of this.decls) {
      const k = kind(s);
      const name = declName(s);
      if (!name) continue;
      if (["Data", "DataBegin", "Constant", "ConstantBegin", "Parameter", "SelectOption", "Ranges", "Tables"].includes(k)) {
        if (k === "Data" && this.insideBegin(s)) continue;
        this.globalData.add(lc(name));
        if (RESERVED_METHODS.has(lc(name))) {
          this.refuse(s, `${uc(name)} is the name of a component of z2ui5_cl_cgui_report - a global of the report becomes an attribute of the class; rename it in the source first`);
        }
      }
      if (["Type", "TypeBegin"].includes(k) && !this.insideBegin(s)) this.globalTypes.add(lc(name));
    }
    // the fields a SELECTION-SCREEN declares itself - a frame title, a
    // comment, a push button: data of the report as well
    for (const s of this.decls) {
      if (kind(s) !== "SelectionScreen") continue;
      for (const f of findAll(s, "InlineField")) this.globalData.add(lc(nodeText(f)));
    }
    this.globalConstants = new Set(this.decls.filter((s) => ["Constant", "ConstantBegin"].includes(kind(s)) && !this.insideBegin(s))
      .map((s) => lc(declName(s) ?? "")));
    this.localNames = new Set(this.locals.flatMap((u) => u.stmts)
      .filter((s) => ["ClassDefinition", "Interface", "ClassDeferred", "InterfaceDeferred"].includes(kind(s)))
      .map((s) => lc(nodeText(child(s, "ClassName") ?? child(s, "InterfaceName") ?? s.getChildren()[1]))));
    this.hoistInlineData();
    this.planLocalTypes();

    // every identifier of the report - generated names must not collide
    this.identifiers = new Set(this.stmts.flatMap((s) => s.getTokens().map((t) => lc(t.getStr()))));
    this.msgVar = this.identifiers.has("lv_message") ? "lv_r2c_message" : "lv_message";
    this.appClass = this.identifiers.has("lcl_r2c") ? "lcl_r2c_report" : "lcl_r2c";
    this.appRef = `${this.appClass}=>app`;

    // select-options and RANGES have a header line in a report - a method
    // reads and writes it through a work area of its own (ls_<name>)
    this.headerTables = new Set(this.decls.filter((s) => ["SelectOption", "Ranges"].includes(kind(s))).map((s) => lc(declName(s))));
    // A global table with a header line (OCCURS, WITH HEADER LINE) is a
    // table attribute and a work area attribute wa_<name>, because the
    // header line is global in the report: a FORM fills it, another one
    // appends it. BEGIN OF ... OCCURS declares the structure - that
    // structure IS the work area, and the table is declared LIKE a table
    // of it.
    this.globalHeader = new Map();
    for (const s of this.decls) {
      const k = kind(s);
      if (!(k === "Data" || k === "DataBegin") || this.insideBegin(s)) continue;
      if (!hasHeaderLine(s)) continue;
      const name = lc(declName(s));
      const wa = (this.identifiers.has(`wa_${name}`) ? `wa_r2c_${name}` : `wa_${name}`).slice(0, 30);
      this.globalHeader.set(name, { wa, begin: k === "DataBegin" });
      this.headerTables.add(name);
      this.globalData.add(wa);
      this.identifiers.add(wa);
    }
    this.methodWa = new Map();
    this.prelude = new Map();
    this.msgDeclared = new Set();

    this.analyzeForms();
    this.analyzeTables();
    this.analyzeAlv();
    this.analyzeScreen();
    // a local class keeps its source - its containers, text editors and HTML
    // viewers become the stand-ins (localsSource), every other control stays one
    for (const u of this.locals) {
      const text = u.stmts.map((x) => lc(renderTokens(stmtTokens(x)))).join(" ");
      const hit = text.match(GUI_CONTROL);
      if (!hit) continue;
      const missing = [...new Set([...text.matchAll(/\bcl_gui_\w+/g)].map((m) => m[0]))].filter((c) => !guiClass(c) && !["cl_gui_cfw", "cl_gui_frontend_services"].includes(c));
      if (!this.guiVars?.size || missing.length) {
        this.refuse(u.stmts[0], `SAP GUI controls: the local class uses ${missing.length ? missing.join(", ") : `cl_gui_${hit[1]}`} - a local class is copied as it is, its controls have no stand-in there; make them global data of the report or move the class into a class of its own`);
      } else {
        // a handler of an event its stand-in does not raise
        for (const m of text.matchAll(/\bfor\s+event\s+(\w+)\s+of\s+(cl_gui_\w+)/g)) {
          if (guiClass(m[2]) && !guiEvent(guiClass(m[2]), m[1])) {
            this.refuse(u.stmts[0], `SAP GUI controls: the local class handles the event ${m[1]} of ${m[2]} - its stand-in ${guiClass(m[2])} does not raise it`);
            break;
          }
        }
      }
    }
  }

  /** a report without a selection screen goes on with START-OF-SELECTION
   *  right after INITIALIZATION - the runtime clears the output before
   *  start_of_selection( ), so what INITIALIZATION builds (a grid, a list)
   *  goes in front of it */
  initializationWithoutScreen() {
    if (this.decls.some((s) => ["Parameter", "SelectOption", "SelectionScreen"].includes(kind(s)))) return;
    const inits = this.events.filter((e) => e.kind === "Initialization");
    if (!inits.length) return;
    for (const e of inits) {
      e.kind = "StartOfSelection";
      e.fromInit = true;
    }
    this.events = [...inits, ...this.events.filter((e) => !inits.includes(e))];
  }

  insideBegin(s) {
    // a DATA inside DATA BEGIN OF ... END OF is a component, not a variable
    const idx = this.decls.indexOf(s);
    let depth = 0;
    for (let j = 0; j < idx; j++) {
      const k = kind(this.decls[j]);
      if (k === "DataBegin" || k === "TypeBegin" || k === "ConstantBegin") depth++;
      if (k === "DataEnd" || k === "TypeEnd" || k === "ConstantEnd") depth--;
    }
    return depth > 0;
  }

  analyzeForms() {
    this.formByName = new Map();
    const used = new Set(this.forms.map((f) => lc(nodeText(child(f.stmt, "FormName")))));
    for (const f of this.forms) {
      const name = lc(nodeText(child(f.stmt, "FormName")));
      let method = name.replace(/[^a-z0-9_]/g, "_");
      if (RESERVED_METHODS.has(method) || this.globalData.has(method)) method = `form_${method}`.slice(0, 30);
      while (used.has(method) && method !== name) method = `${method.slice(0, 28)}_f`;
      // MODULE x OUTPUT and MODULE x INPUT - the classic allows the name twice
      if (f.module && this.forms.some((g) => g !== f && g.method === method)) method = `${method.slice(0, 26)}_${f.module.io === "OUTPUT" ? "pbo" : "pai"}`;
      f.name = name;
      f.method = method;
      f.params = [];
      const written = new Set(f.body.flatMap((s) => findAll(s, "Target").map((t) => lc(t.getFirstToken().getStr()))));
      for (const [section, k] of [["FormTables", "tables"], ["FormUsing", "using"], ["FormChanging", "changing"]]) {
        const sec = child(f.stmt, section);
        if (!sec) continue;
        for (const p of children(sec, "FormParam")) {
          const byValue = child(p, "PassByValue");
          const nameNode = byValue ? child(byValue, "FormParamName") : child(p, "FormParamName");
          const pname = lc(nodeText(nameNode));
          f.params.push({ name: pname, kind: k, byValue: !!byValue, node: p, written: written.has(pname) });
        }
      }
      const raising = child(f.stmt, "FormRaising");
      f.raising = raising ? children(raising, "ClassName").map((c) => lc(nodeText(c))) : [];
      this.formByName.set(name, f);
    }
  }

  /** TABLES dbtab: kept as a typed work area where the code uses it, dropped
   *  where it only types select-options and parameters */
  analyzeTables() {
    this.tablesKept = new Set();
    const tables = this.decls.filter((s) => kind(s) === "Tables").map((s) => lc(declName(s)));
    if (!tables.length) return;
    // a field of a dynpro is the work area of TABLES
    for (const root of this.dynproFieldRoots()) if (tables.includes(root)) this.tablesKept.add(root);
    const body = [...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body)];
    for (const s of body) {
      if (kind(s) === "Comment") continue;
      if (["Select", "SelectLoop"].includes(kind(s)) && !/\b(INTO|APPENDING)\b/i.test(renderTokens(stmtTokens(s)))) {
        const tabs = findAll(s, "DatabaseTable");
        if (tabs.length === 1 && tables.includes(lc(nodeText(tabs[0])))) this.tablesKept.add(lc(nodeText(tabs[0])));
      }
      const dbTokens = new Set(findAll(s, "DatabaseTable").flatMap((n) => n.getTokens().map(key)));
      for (const t of s.getTokens()) {
        if (dbTokens.has(key(t))) continue;
        const name = lc(t.getStr());
        if (tables.includes(name)) this.tablesKept.add(name);
      }
    }
  }

  /**
   * cl_gui_alv_grid: the grid of a report written since 2005 - a container
   * on a dynpro (or the default screen), the grid in it, a local class with
   * the handlers of its events, CALL SCREEN and the modules of the screen.
   * Here the grid is alv( ) of the runtime: the PBO modules are inlined at
   * CALL SCREEN (the grid shows after the event block), the PAI modules are
   * at_user_command( ) with the OK code as ucomm, and the handler class goes
   * - its methods become at_line_selection( ), at_link_click( ),
   * at_user_command( ) and the functions of the grid's toolbar.
   */
  resolveGridScreen() {
    this.gridVars = new Set();
    this.contVars = new Set();
    this.handlerVars = new Set();
    this.gridHandlers = [];
    this.okVars = new Set();
    const text = (x) => lc(renderTokens(stmtTokens(x)));
    const all = [...this.decls, ...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body), ...this.modules.flatMap((m) => m.body)];
    const containers = "cl_gui_(custom_container|docking_container|container|dialogbox_container|splitter_container|easy_splitter_container)";
    for (const x of all) {
      // DATA(grid) = NEW cl_gui_alv_grid( ... ) - declared where it is created
      if (kind(x) === "Move") {
        const m = /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*new\s+(cl_gui_\w+)\s*\(/.exec(text(x));
        if (m && m[2] === "cl_gui_alv_grid") this.gridVars.add(m[1]);
        else if (m && new RegExp(`^${containers}$`).test(m[2])) this.contVars.add(m[1]);
        continue;
      }
      if (!["Data", "Static"].includes(kind(x))) continue;
      const t = text(x);
      const name = lc(declName(x) ?? "");
      if (/type\s+ref\s+to\s+cl_gui_alv_grid\b/.test(t)) this.gridVars.add(name);
      else if (new RegExp(`type\\s+ref\\s+to\\s+${containers}\\b`).test(t)) this.contVars.add(name);
    }
    if (!this.gridVars.size) {
      // no grid: the containers are no objects of a grid to drop
      this.contVars.clear();
      this.findGuiVars(all);
      this.resolveDynpro();
      return;
    }

    // the handler class: every method a handler of an event of the grid
    const nameOf = (u) => lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1]));
    const handlerClasses = new Set();
    for (const u of this.locals) {
      if (u.kind !== "ClassDefinition") continue;
      const defs = u.stmts.filter((x) => kind(x) === "MethodDef");
      const handlers = defs.filter((x) => /^cl_gui_alv_grid$/i.test(nodeText(child(child(x, "EventHandler") ?? x, "ClassName") ?? x).trim()) && child(x, "EventHandler"));
      if (!handlers.length) continue;
      const cls = nameOf(u);
      if (handlers.length !== defs.length || u.stmts.some((x) => ["Data", "ClassData", "Constant", "Type", "TypeBegin"].includes(kind(x)))) {
        this.refuse(u.stmts[0], `the local class ${cls} handles events of cl_gui_alv_grid and has other methods or attributes - its handlers become methods of the report class; move the rest into a class of its own`);
        continue;
      }
      handlerClasses.add(cls);
      for (const d of handlers) {
        const eh = child(d, "EventHandler");
        this.gridHandlers.push({
          cls, method: lc(nodeText(child(d, "MethodName"))), event: lc(nodeText(child(eh, "EventName"))),
          params: findAll(eh, "MethodParamName").map((x) => lc(nodeText(x))), stmt: d, body: [],
        });
      }
    }
    for (const u of this.locals) {
      if (u.kind !== "ClassImplementation" || !handlerClasses.has(nameOf(u))) continue;
      let cur;
      for (const x of u.stmts.slice(1)) {
        const k = kind(x);
        if (k === "MethodImplementation") {
          const name = lc(nodeText(child(x, "MethodName")));
          cur = this.gridHandlers.find((h) => h.cls === nameOf(u) && h.method === name);
        } else if (k === "EndMethod") cur = undefined;
        else if (cur && k !== "EndClass") cur.body.push(x);
      }
    }
    for (const u of this.locals.filter((x) => handlerClasses.has(nameOf(x)))) {
      this.mapped.push({ row: u.stmts[0].getFirstToken().getRow(), col: 1, classic: renderTokens(stmtTokens(u.stmts[0])), target: "dropped - the handlers of the grid are methods of the report class" });
    }
    this.locals = this.locals.filter((u) => !handlerClasses.has(nameOf(u)));
    for (const x of all) {
      if (!["Data", "Static"].includes(kind(x))) continue;
      const m = /type\s+ref\s+to\s+([\w/]+)/.exec(text(x));
      if (m && handlerClasses.has(m[1])) this.handlerVars.add(lc(declName(x)));
      const name = lc(declName(x) ?? "");
      if (/(type|like)\s+sy\s*-\s*ucomm\b|type\s+syucomm\b/.test(text(x)) || /^(g[vd]?_)?(save_)?ok_?code$|^save_ok$/.test(name)) this.okVars.add(name);
    }

    // CALL SCREEN: the PBO modules in its place, the PAI modules a user command
    if (!this.modules.length) return;
    const calls = [];
    for (const unit of [...this.events.map((e) => e.stmts), ...this.forms.map((f) => f.body)]) {
      unit.forEach((x, i) => { if (kind(x) === "CallScreen") calls.push({ unit, i }); });
    }
    if (calls.length !== 1) {
      for (const m of this.modules) this.refuse(m.stmt, calls.length ? "MODULE - the report calls more than one screen; the screen of one grid is converted" : REFUSED.Module);
      return;
    }
    const { unit, i } = calls[0];
    const call = unit[i];
    const pbo = this.modules.filter((m) => m.io === "OUTPUT");
    unit.splice(i, 1, ...pbo.flatMap((m) => m.body));
    this.map(call, `the PBO module${pbo.length === 1 ? "" : "s"} of the screen, in its place - the grid shows when the event block is done`);
    const after = unit.slice(i + pbo.flatMap((m) => m.body).length).filter((x) => !["Comment", ...CLOSERS].includes(kind(x)));
    if (after.length) this.todo(call, "statements follow CALL SCREEN - they ran when the screen was left; here they run before the grid shows");
    for (const m of this.modules) {
      if (m.io === "OUTPUT") {
        this.map(m.stmt, `inlined at CALL SCREEN - the PBO module ${m.name}, once (the grid is not created anew on every roundtrip)`);
      } else {
        this.map(m.stmt, `\`at_user_command( ucomm )\` - the PAI module ${m.name}, the OK code is ucomm; Back, Exit and Cancel are the runtime's`);
        this.events.push({ stmt: m.stmt, kind: "AtUserCommand", stmts: m.body, pai: true });
      }
    }
    // the OK code fields the PAI module alone reads are ucomm now - gone
    const outside = [...this.events.filter((e) => !e.pai).flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body), ...this.gridHandlers.flatMap((h) => h.body)]
      .flatMap((x) => x.getTokens().map((t) => lc(t.getStr())));
    this.okDropped = new Set([...this.okVars].filter((v) => !outside.includes(v)));
  }

  /**
   * A dynpro of fields - the screens abapGit wrote into the .prog.xml. The
   * modules become private methods, the flow logic the hooks of the
   * runtime: dynpro_screen( ) builds the fields with the selection-screen
   * builder, dynpro_pbo( ) and dynpro_pai( ) call the modules of PROCESS
   * BEFORE OUTPUT and AFTER INPUT, and what followed CALL SCREEN goes on
   * in after_call_screen( ). A screen with a custom control, a subscreen,
   * a table control or a tabstrip, or flow logic with LOOP or CALL
   * SUBSCREEN, is refused.
   */
  resolveDynpro() {
    const bodies = [...this.events.map((e) => e.stmts), ...this.forms.map((f) => f.body), ...this.modules.map((m) => m.body)];
    const screenStmts = bodies.flat().filter((x) => ["CallScreen", "SetScreen", "Leave"].includes(kind(x)));
    const calls = screenStmts.filter((x) => kind(x) === "CallScreen");
    if (!this.modules.length && !calls.length) return;
    const refuseModules = (message) => { for (const m of this.modules) this.refuse(m.stmt, message); };
    const dynpros = new Map((this.pool.dynpros ?? []).map((d) => [d.screen, d]));
    if (!dynpros.size) {
      refuseModules(this.pool.cua || this.pool.title || this.pool.symbols.size
        ? REFUSED.Module
        : "MODULE - the screens are in the .prog.xml (--texts), which was not passed; with it a dynpro of fields is converted");
      return;
    }
    // the screens the report reaches: CALL SCREEN, SET SCREEN, LEAVE TO SCREEN
    const number = (x) => {
      const t = lc(renderTokens(stmtTokens(x)));
      const m = /^(?:call\s+screen|set\s+screen|leave\s+to\s+screen)\s+(['`]?)(\d+)\1(?:\s|$)/.exec(t);
      if (m) return m[2].padStart(4, "0");
      if (/^(call\s+screen|set\s+screen|leave\s+to\s+screen)\s/.test(t)) return null;
      return undefined;
    };
    const reached = new Set();
    for (const x of screenStmts) {
      const nr = number(x);
      if (nr === null) {
        refuseModules(`MODULE - ${uc(renderTokens(stmtTokens(x)).split(/\s+/).slice(0, 2).join(" "))} with a variable - the screens are converted when the report names them`);
        return;
      }
      if (nr && nr !== "0000") reached.add(nr);
    }
    const problems = [];
    const screens = [];
    for (const nr of reached) {
      const d = dynpros.get(nr);
      if (!d) {
        problems.push(`screen ${nr} is not in the .prog.xml`);
        continue;
      }
      const kinds = { CUST_CTRL: "custom control (a SAP GUI control)", SUBSCREEN: "subscreen area", TABLE_CTRL: "table control", STRIP_CTRL: "tabstrip" };
      // a custom control area holds the stand-ins of the SAP GUI controls
      const allowed = ["SCREEN", "RADIOGROUP", ...(this.guiVars?.size ? ["CUST_CTRL"] : [])];
      for (const c of d.containers.filter((x) => !allowed.includes(x.type))) problems.push(`screen ${nr} has a ${kinds[c.type] ?? c.type} ${c.name}`);
      for (const f of d.fields.filter((x) => !DYNPRO_FIELDS.has(x.type))) problems.push(`screen ${nr} has a field ${f.name || f.text} of type ${f.type}`);
      const flow = parseFlow(d.flow);
      problems.push(...flow.problems.map((p) => `screen ${nr}: ${p}`));
      for (const c of [...flow.pbo, ...flow.pai, ...flow.pov]) {
        if (!this.modules.some((m) => m.name === c.module)) problems.push(`screen ${nr} calls MODULE ${c.module}, which is not in the report`);
      }
      screens.push({ ...d, ...flow, okcode: lc(d.fields.find((f) => f.type === "OKCODE")?.name ?? "") });
    }
    if (problems.length) {
      refuseModules(`MODULE - ${[...new Set(problems)].slice(0, 3).join("; ")} - a dynpro of fields is converted (texts, inputs, checkboxes, radio buttons, frames, push buttons)`);
      return;
    }
    screens.sort((a, b) => a.screen.localeCompare(b.screen));
    this.dynpro = { screens, continued: new Set() };
    // the modules: private methods, called by the flow logic
    for (const m of this.modules) {
      const pai = screens.filter((d) => d.pai.some((c) => c.module === m.name));
      const okcodes = new Set(pai.map((d) => d.okcode).filter(Boolean));
      this.forms.push({ stmt: m.stmt, body: m.body, module: m, performed: true, okcode: okcodes.size === 1 ? [...okcodes][0] : undefined });
    }
  }

  /** a checkbox or radio button of a dynpro declared as one character -
   *  abap_bool, the type the frontend shows as a flag (and the type of
   *  checkbox( ) and radiobutton( ), which take it by reference) */
  dynproFlag(s, name, text) {
    if (kind(s) !== "Data" || this.insideBegin(s) || !this.isDynproFlag(name)) return text;
    const typed = text.replace(/\bVALUE\s+'X'/i, "VALUE abap_true").replace(new RegExp(`^(DATA\\s+${name})(?:\\(1\\))?\\s*(?:TYPE\\s+(?:c(?:\\s+LENGTH\\s+1)?|char1|flag|xfeld|boolean|boole_d|abap_boolean))?(?=\\s*(?:VALUE\\b|\\.))`, "i"), "$1 TYPE abap_bool");
    if (typed !== text) this.map(s, "`TYPE abap_bool` - a checkbox or radio button of the dynpro");
    return typed;
  }

  /** a checkbox or radio button of a dynpro, a variable of its own */
  isDynproFlag(name) {
    if (!this.dynpro) return false;
    this.dynproFlags ??= new Set(this.dynpro.screens.flatMap((d) => d.fields)
      .filter((f) => ["CHECK", "RADIO"].includes(f.type) && !f.name.includes("-")).map((f) => lc(f.name)));
    return this.dynproFlags.has(name);
  }

  /** the SAP GUI controls of a report without a grid: name -> the stand-in
   *  class of z2ui5_cl_cgui_gui* (GUI) */
  findGuiVars(all) {
    this.guiVars = new Map();
    // the attributes and method data of the local classes as well
    for (const x of [...all, ...this.locals.flatMap((u) => u.stmts)]) {
      const t = lc(renderTokens(stmtTokens(x)));
      if (kind(x) === "Move") {
        const m = /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*new\s+(cl_gui_\w+)\s*\(/.exec(t);
        if (m && guiClass(m[2])) this.guiVars.set(m[1], guiClass(m[2]));
        continue;
      }
      if (!["Data", "Static", "ClassData"].includes(kind(x)) || this.insideBegin(x)) continue;
      const m = /type\s+ref\s+to\s+(cl_gui_\w+)\b/.exec(t);
      if (m && guiClass(m[1])) this.guiVars.set(lc(declName(x)), guiClass(m[1]));
    }
  }

  /** the event handlers of the local classes: method -> [{ cls, event, of }] */
  guiHandlers() {
    if (this.guiHandlerMap) return this.guiHandlerMap;
    this.guiHandlerMap = new Map();
    for (const u of this.locals.filter((x) => x.kind === "ClassDefinition")) {
      const cls = lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1]));
      for (const x of u.stmts.filter((y) => kind(y) === "MethodDef" && child(y, "EventHandler"))) {
        const eh = child(x, "EventHandler");
        const name = lc(nodeText(child(x, "MethodName")));
        if (!this.guiHandlerMap.has(name)) this.guiHandlerMap.set(name, []);
        this.guiHandlerMap.get(name).push({ cls, event: lc(nodeText(child(eh, "EventName"))), of: lc(nodeText(child(eh, "ClassName"))) });
      }
    }
    return this.guiHandlerMap;
  }

  /** SET HANDLER h->m FOR go_x [ACTIVATION a] - go_x->set_handler( ): the
   *  stand-in keeps the handler, the classic registration would not
   *  survive the roundtrip */
  guiSetHandler(s, b) {
    const ov = this.rewrites(s, b.ctx, b);
    const render = (node) => nodeText(node, ov);
    const sources = children(s, "Source");
    const target = sources[0] && render(sources[0]);
    const activation = sources[1] && render(sources[1]);
    if (/^all\s+instances$/i.test(target ?? "") || words(s).includes("ALL")) {
      this.refuse(s, "SAP GUI controls: SET HANDLER ... FOR ALL INSTANCES - the stand-ins keep the handlers of one control; name the control");
      return;
    }
    const control = lc(target.replace(/^me\s*->\s*/i, "").replace(/^.*->/, ""));
    const cls = this.guiVars.get(control) ?? this.guiVars.get(lc(target));
    const lines = [];
    for (const m of children(s, "MethodSource")) {
      const text = render(m);
      const arrow = /^(.*?)\s*(->|=>)\s*([\w/]+)$/.exec(text);
      if (arrow?.[2] === "=>") {
        this.refuse(s, "SAP GUI controls: SET HANDLER of a static method - the stand-ins call the handler of an object; make it an instance method");
        return;
      }
      const handler = arrow ? arrow[1] : "me";
      const method = lc(arrow ? arrow[3] : text);
      if (!cls) {
        this.refuse(s, `SAP GUI controls: SET HANDLER ${method} FOR ${target} - no SAP GUI control of the report; port this statement by hand`);
        return;
      }
      const candidates = (this.guiHandlers().get(method) ?? []).filter((h) => guiClass(h.of) && guiEvent(cls, h.event));
      if (!candidates.length) {
        this.refuse(s, `SAP GUI controls: SET HANDLER ${method} - no handler FOR EVENT of the control in a local class, or an event its stand-in ${cls} does not raise`);
        return;
      }
      if (handler === "me" && !b.ctx.local) {
        this.refuse(s, `SAP GUI controls: SET HANDLER ${method} outside of a local class - the handler is an object; name it`);
        return;
      }
      lines.push(renderNamedCall(`${target}->set_handler`, [
        { name: "handler", value: handler },
        { name: "method", value: literal(uc(method)) },
        { name: "event", value: literal(uc(candidates[0].event)) },
        ...(activation ? [{ name: "activation", value: activation }] : []),
      ]));
    }
    b.out.push(...lines);
    this.map(s, `\`${target}->set_handler( )\` - the stand-in keeps the handler and calls it for the event of the browser`);
  }

  /** the SAP GUI control classes of a statement that have no stand-in -
   *  the refusal, undefined when every one has */
  guiRefusal(text) {
    const t = lc(text);
    if (!GUI_CONTROL.test(t)) return undefined;
    const missing = [...new Set([...t.matchAll(/\bcl_gui_\w+/g)].map((m) => m[0]))]
      .filter((c) => !guiClass(c) && !["cl_gui_cfw", "cl_gui_frontend_services"].includes(c));
    if (this.guiVars?.size && !missing.length) return undefined;
    if (this.guiVars?.size) return `SAP GUI controls: ${missing.join(", ")} ${missing.length > 1 ? "have" : "has"} no counterpart - the containers, cl_gui_textedit, cl_gui_html_viewer and cl_gui_toolbar have (z2ui5_cl_cgui_gui*)`;
    return "SAP GUI controls (cl_gui_*) need a dynpro container - use alv( ) or an abap2UI5 view";
  }

  /** the calls of the grid stand-in: VALUE #( ... ) of a generic parameter
   *  takes the classic type; refresh_table_display( ) is passed the table
   *  set_table_for_first_display( ) showed - the stand-in shows a copy */
  gridRewrites(toks, ov, ctx) {
    if (!this.guiVars?.size || ![...this.guiVars.values()].includes("z2ui5_cl_cgui_gui_alv_grid")) return;
    const text = toks.map((t) => lc(t.getStr()));
    const own = GUI.members.z2ui5_cl_cgui_gui_alv_grid.methods;
    const gridCall = text.some((t, i) => text[i - 1] === "->" && Object.hasOwn(own, t) && t !== "dispatch");
    if (!gridCall) return;
    for (let i = 2; i < text.length; i++) {
      if (text[i] === "#" && text[i - 1] === "value" && text[i - 2] === "=" && Object.hasOwn(GRID_VALUE_TYPES, text[i - 3])) {
        ov.set(key(toks[i]), GRID_VALUE_TYPES[text[i - 3]]);
      }
    }
    const at = text.findIndex((t, i) => t === "refresh_table_display" && text[i - 1] === "->");
    if (at < 0) return;
    // the grid of another object: its table is not in reach
    if (text[at - 3] === "->" && text[at - 4] !== "me") return;
    const outtab = this.gridOuttab(text[at - 2], ctx);
    if (!outtab) return;
    const changing = `CHANGING it_outtab = ${outtab}`;
    if (text[at + 1] === "(") {
      let depth = 0;
      let close = at + 1;
      for (; close < text.length; close++) {
        if (text[close].endsWith("(")) depth++;
        else if (text[close].startsWith(")") && --depth === 0) break;
      }
      const inner = text.slice(at + 2, close);
      if (inner.length && !inner.some((t) => ["exporting", "changing", "importing"].includes(t))) ov.set(key(toks[at + 1]), "( EXPORTING");
      if (!inner.includes("changing")) ov.set(key(toks[close]), `${changing} )`);
    } else if (!text.includes("changing")) {
      // CALL METHOD grid->refresh_table_display [EXPORTING ...]
      const last = toks[toks.length - 1];
      ov.set(key(last), `${ov.get(key(last)) ?? last.getStr()} ${changing}`);
    }
  }

  /** the table the grid recv shows - it_outtab of its
   *  set_table_for_first_display( ) in the same class (sender: the grid of
   *  that class); undefined when there is none or more than one */
  gridOuttab(recv, ctx = {}) {
    if (!this.gridTables) {
      this.gridTables = [];
      const scan = (stmts, cls) => {
        for (const x of stmts) {
          const t = lc(renderTokens(stmtTokens(x)));
          const m = /([\w/]+)\s*->\s*set_table_for_first_display\b/.exec(t);
          const o = /\bit_outtab\s*=\s*([\w/]+(?:\s*(?:->|-)\s*[\w/]+)*)/.exec(t);
          if (m && o) this.gridTables.push({ cls, var: m[1], outtab: o[1].replace(/\s+/g, "") });
        }
      };
      scan([...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body), ...this.modules.flatMap((m) => m.body)], undefined);
      let cls;
      for (const u of this.locals) {
        if (u.kind === "ClassImplementation") cls = lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1]));
        scan(u.stmts, u.kind === "ClassImplementation" ? cls : undefined);
      }
    }
    const cls = ctx.local?.cls;
    const hits = new Set(this.gridTables.filter((g) => g.cls === cls && (recv === "sender" || g.var === recv)).map((g) => g.outtab));
    return hits.size === 1 ? [...hits][0] : undefined;
  }

  /** what a statement uses of a SAP GUI control that its stand-in does not
   *  have - undefined when it has everything */
  guiCheck(s) {
    if (!this.guiVars?.size) return undefined;
    const toks = stmtTokens(s).map((x) => lc(x.getStr()));
    const used = [];
    const ctors = [];
    for (let i = 0; i < toks.length; i++) {
      const t = toks[i];
      if (guiClass(t) && toks[i + 1] === "=>") {
        const m = guiMember(guiClass(t), toks[i + 2]);
        if (!m) return `${t}=>${toks[i + 2]} has no counterpart in ${guiClass(t)}`;
        if (m.kind === "method") used.push(m);
      }
      if (this.guiVars.has(t) && toks[i + 1] === "->" && toks[i - 1] !== "-" && toks[i - 1] !== "->") {
        const cls = this.guiVars.get(t);
        const m = guiMember(cls, toks[i + 2]);
        if (!m) return `${t}->${toks[i + 2]} has no counterpart in ${cls}`;
        if (m.kind === "method") used.push(m);
      }
      // NEW cl_gui_alv_grid( i_parent = NEW cl_gui_custom_container( ... ) ) - both
      if (t === "new" && guiClass(toks[i + 1])) ctors.push(guiClass(toks[i + 1]));
    }
    // CREATE OBJECT go_x [TYPE cl_gui_y]: the constructor of its class
    if (kind(s) === "CreateObject") {
      const type = /\btype\s+([\w/]+)/.exec(toks.join(" "));
      const target = lc(nodeText(child(s, "Target") ?? s).split(/\s/)[0]);
      const ctor = type && guiClass(type[1]) ? guiClass(type[1]) : this.guiVars.get(target);
      if (ctor) ctors.push(ctor);
    }
    for (const c of ctors) used.push(guiMember(c, "constructor"));
    // a control handed to a method or class of the report's own - that one
    // takes a SAP GUI control, not its stand-in
    if (!used.length && /->|=>|\bnew\b|^create\s+object|^call\s+(function|method)/.test(toks.join(" "))) {
      for (let i = 1; i < toks.length; i++) {
        if (this.guiVars.has(toks[i]) && ["=", "("].includes(toks[i - 1]) && toks[i + 1] !== "->") {
          return `${toks[i]}, a SAP GUI control, is handed to a method that is no stand-in - it takes a cl_gui_* object`;
        }
      }
    }
    if (!used.length) return undefined;
    // the parameters and exceptions named: of one of the methods called
    const known = new Set(["others", "error_message", ...used.flatMap((m) => [...m.params, ...m.exceptions])]);
    const flat = toks.join(" ");
    const head = /^(?:data\s*\(\s*[\w/]+\s*\)|[\w/-]+)\s*=(?!=)/.exec(flat);
    // the components of a VALUE #( ... ) or another constructor expression
    // are no parameters
    const body = withoutConstructorArgs(head ? flat.slice(head[0].length) : flat);
    for (const m of body.matchAll(/(?:^|[(\s])([a-z_][\w]*)\s*=(?![=>])/g)) {
      if (!known.has(m[1])) return `${m[1]} is no parameter of ${used.length > 1 ? "the methods called" : "the method called"} in the stand-in`;
    }
    return undefined;
  }

  /** a variable holding an exception object - CATCH ... INTO it, or
   *  declared TYPE REF TO an exception class or if_message */
  isExceptionVar(name) {
    if (!this.exceptionVars) {
      this.exceptionVars = new Set();
      // the local classes too: their attributes and the CATCH of their methods
      for (const x of [...this.decls, ...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body),
        ...this.modules.flatMap((m) => m.body), ...this.locals.flatMap((u) => u.stmts)]) {
        const t = lc(renderTokens(stmtTokens(x)));
        // CATCH cx_a cx_b ... INTO x - over several lines
        const c = /^catch\b[\s\S]*\binto\s+(?:data\s*\(\s*)?([\w/]+)/.exec(t);
        if (c) this.exceptionVars.add(c[1]);
        const d = /^data\s*:?\s*([\w/]+)\s+type\s+ref\s+to\s+([\w/]+)/.exec(t);
        if (d && /^(\/\w+\/)?[yz]?cx_|^if_message$|^if_t100_message$/.test(d[2])) this.exceptionVars.add(d[1]);
      }
    }
    return this.exceptionVars.has(lc(name));
  }

  /** the roots of the dynpro fields - gs_data of GS_DATA-CARRID */
  dynproFieldRoots() {
    return new Set((this.dynpro?.screens ?? []).flatMap((d) => d.fields).filter((f) => f.name && f.type !== "OKCODE")
      .map((f) => lc(f.name.split("-")[0])));
  }

  /** dynpro_screen( ), dynpro_pbo( ), dynpro_pai( ) - the screens and their flow logic */
  dynproMethods() {
    const { screens } = this.dynpro;
    // PBO calls the OUTPUT module of the name, PAI the INPUT one
    const call = (c, io) => {
      const f = this.forms.find((x) => x.module?.name === c.module && x.module.io === io)
        ?? this.forms.find((x) => x.module?.name === c.module);
      return this.screenForms().has(f.name) ? `${f.method}( current_screen( ) ).` : `${f.method}( ).`;
    };
    const methods = [];
    methods.push({ name: "dynpro_screen", body: caseBody("dynnr", screens.map((d) => ({ field: d.screen, body: this.dynproLayout(d) }))) });
    const pbo = screens.filter((d) => d.pbo.length);
    if (pbo.length) methods.push({ name: "dynpro_pbo", body: caseBody("dynnr", pbo.map((d) => ({ field: d.screen, body: d.pbo.map((c) => call(c, "OUTPUT")) }))) });
    const leftCheck = ["IF screen_left( ) = abap_true.", "  RETURN.", "ENDIF."];
    const pai = screens.filter((d) => d.pai.length || d.okcode);
    if (pai.length) {
      methods.push({
        name: "dynpro_pai",
        body: caseBody("dynnr", pai.map((d) => {
          const body = [];
          if (d.okcode && this.globalData.has(d.okcode.split("-")[0])) body.push(`${d.okcode} = ucomm.`);
          const exits = d.pai.filter((c) => c.cond === "exit");
          if (exits.length) {
            body.push("\" AT EXIT-COMMAND - the functions that leave", "IF ucomm = `BACK` OR ucomm = `EXIT` OR ucomm = `CANC` OR ucomm = `CANCEL`.");
            for (const c of exits) body.push(`  ${call(c, "INPUT")}`, ...leftCheck.map((l) => `  ${l}`));
            body.push("ENDIF.");
          }
          const rest = d.pai.filter((c) => c.cond !== "exit");
          rest.forEach((c, i) => {
            const line = call(c, "INPUT");
            if (c.cond === "input") body.push(`IF ${lc(c.field)} IS NOT INITIAL.`, `  ${line}`, "ENDIF.");
            else if (c.cond === "cursor") body.push("IF ucomm = `PICK`.", `  ${line}`, "ENDIF.");
            else body.push(line);
            if (i < rest.length - 1) body.push(...leftCheck);
          });
          return { field: d.screen, body };
        })),
      });
    }
    if (screens.some((d) => d.pov.length)) this.note("PROCESS ON VALUE-REQUEST of a dynpro - dropped, the field has the standard value help of its type; call the module from at_value_request( ) by hand");
    if (screens.some((d) => d.poh)) this.note("PROCESS ON HELP-REQUEST of a dynpro - dropped, the field has the F1 help of its data element");
    if (screens.some((d) => d.request)) this.note("FIELD ... MODULE ... ON REQUEST / ON CHAIN-REQUEST - the module runs on every roundtrip, not only when the field changed");
    return methods;
  }

  /** the fields of a screen as a chain of the selection-screen builder:
   *  line by line, a text before an input its label, frames blocks */
  dynproLayout(d) {
    const text = (t) => t.replace(/_/g, " ").trim();
    // a custom control area is a line of its own, where its first line is
    const areas = d.containers.filter((c) => c.type === "CUST_CTRL").map((c) => ({ type: "CUSTOM", name: c.name, line: c.line, column: c.column, height: c.height, length: c.length }));
    const fields = [...d.fields.filter((f) => f.type !== "OKCODE" && f.line > 0), ...areas].sort((a, b) => a.line - b.line || a.column - b.column);
    const frames = fields.filter((f) => f.type === "FRAME");
    const frameOf = (f) => frames.filter((r) => r !== f && f.line > r.line && f.line < r.line + r.height && f.column >= r.column && f.column < r.column + r.length)
      .sort((a, b) => b.line - a.line)[0];
    const chain = [];
    const add = (l) => chain.push(l);
    let frame;
    const lines = [...new Set(fields.filter((f) => f.type !== "FRAME").map((f) => f.line))];
    for (const ln of lines) {
      const row = fields.filter((f) => f.line === ln && f.type !== "FRAME");
      const fr = frameOf(row[0]);
      if (fr !== frame) {
        if (frame) add("block_end(");
        if (fr) add(`block_begin( ${literal(text(fr.text))}`);
        frame = fr;
      }
      // a text right before an input is its label
      const items = [];
      for (let i = 0; i < row.length; i++) {
        const f = row[i];
        if (f.type === "TEXT" && row[i + 1]?.type === "TEMPLATE" && text(f.text)) {
          items.push({ ...row[i + 1], label: text(f.text) });
          i++;
        } else items.push(f);
      }
      // the areas after the line, the fields of the line together
      const calls = items.filter((f) => f.type !== "CUSTOM").map((f) => this.dynproField(f, fr)).filter(Boolean);
      if (calls.length > 1) add("line_begin(");
      calls.forEach((c) => add(c));
      if (calls.length > 1) add("line_end(");
      for (const f of items.filter((x) => x.type === "CUSTOM")) add(`custom_control( ${literal(f.name)}`);
    }
    if (frame) add("block_end(");
    if (!chain.length) return [];
    // one call per line, the parameters of a call aligned under its first,
    // each call closed by the next one - the house layout of a chain
    const out = [];
    chain.forEach((c, i) => {
      const head = i === 0 ? "screen->" : "    )->";
      const [first, ...more] = c.split("\n");
      out.push(`${head}${first}`);
      for (const m of more) out.push(`${" ".repeat(head.length)}${m}`);
    });
    out[out.length - 1] += out[out.length - 1].endsWith("(") ? " )." : " ).";
    return out;
  }

  /** one field of a dynpro - a call of the selection-screen builder */
  dynproField(f, frame) {
    const text = (t) => t.replace(/_/g, " ").trim();
    const name = lc(f.name);
    const named = (method, params) => {
      const list = params.filter(([, v]) => v !== undefined);
      if (!list.length) return `${method}(`;
      if (list.length === 1 && ["text", "title"].includes(list[0][0])) return `${method}( ${list[0][1]}`;
      const width = Math.max(...list.map(([n]) => n.length));
      const pad = " ".repeat(method.length + 2);
      return list.map(([n, v], i) => `${i ? pad : `${method}( `}${n.padEnd(width)} = ${v}`).join("\n");
    };
    const modif = f.group1 ? literal(f.group1) : undefined;
    const t = (s) => (s ? literal(s) : undefined);
    switch (f.type) {
      case "TEXT":
        if (!text(f.text)) return undefined;
        return named("comment", [["text", literal(text(f.text))], ["modif_id", modif]]);
      case "TEMPLATE":
        return named("parameter", [["val", name], ["text", t(f.label)],
          ["obligatory", f.required && f.input ? "abap_true" : undefined],
          ["read_only", f.input ? undefined : "abap_true"],
          ["modif_id", modif], ["no_display", f.invisible ? "abap_true" : undefined]]);
      case "CHECK":
        return named("checkbox", [["val", name], ["text", t(text(f.text))], ["modif_id", modif]]);
      case "RADIO":
        return named("radiobutton", [["val", name], ["text", t(text(f.text))],
          ["group", literal(f.cont === "RADIOGROUP" ? radioGroup(f.contName) : `RB${String(frame?.line ?? 0).padStart(2, "0")}`)], ["modif_id", modif]]);
      case "PUSH": {
        const icon = ICONS[lc(f.icon)];
        return named("button", [["text", literal(text(f.text) || f.fcode)], ["event", literal(f.fcode)], ["icon", icon ? literal(icon) : undefined], ["modif_id", modif]]);
      }
      default:
        return undefined;
    }
  }

  /** CALL SCREEN, SET SCREEN, LEAVE SCREEN, LEAVE TO SCREEN and LEAVE
   *  PROGRAM of a report with dynpros - true when the statement is done */
  dynproStatement(s, b, k) {
    if (!["CallScreen", "SetScreen", "Leave"].includes(k)) return false;
    const out = b.out;
    const t = lc(renderTokens(stmtTokens(s)));
    const nr = /^(?:call\s+screen|set\s+screen|leave\s+to\s+screen)\s+['`]?(\d+)/.exec(t)?.[1]?.padStart(4, "0");
    if (k === "CallScreen") {
      out.push(`call_screen( ${literal(nr)} ).`);
      this.map(s, "`call_screen( dynnr )` - the dynpro shows when the event block is done, what follows goes on in `after_call_screen( dynnr )`");
      if (/\bstarting\s+at\b/.test(t)) this.note("CALL SCREEN ... STARTING AT - the dynpro shows on the page, not as a dialog box");
      if (this.dynpro.continued.has(nr) && this.followedByCode(b)) {
        this.refuse(s, `CALL SCREEN ${nr} a second time with statements after it - after_call_screen( ) goes on after one call per screen; port it by hand`);
        return true;
      }
      this.dynpro.continued.add(nr);
      this.continueIn(s, b, {
        field: nr, method: "after_call_screen", ctx: { method: "after_call_screen" },
        what: `CALL SCREEN ${nr}`, where: `after_call_screen( dynnr ) with dynnr ${nr}`,
      });
      return true;
    }
    const leave = b.ctx.method === "dynpro_pai" || b.ctx.form?.module ? ["RETURN."] : [];
    if (k === "SetScreen") {
      out.push(`set_screen( ${literal(nr)} ).`);
      this.map(s, "`set_screen( dynnr )` - the next screen when the PAI is done");
      return true;
    }
    if (/^leave\s+to\s+screen\s/.test(t)) {
      out.push(`leave_to_screen( ${literal(nr)} ).`, ...leave);
      this.map(s, `\`leave_to_screen( dynnr )\`${leave.length ? " and `RETURN` - the modules after it do not run" : ""}${nr === "0000" ? "; screen 0 goes back to where CALL SCREEN stood" : ""}`);
      return true;
    }
    if (/^leave\s+screen$/.test(t)) {
      out.push("leave_screen( ).", ...leave);
      this.map(s, "`leave_screen( )` - the PAI ends, the next screen shows");
      return true;
    }
    return false;
  }

  /** the grid, its container or its handler object - dropped */
  isGridObject(name) {
    return !!(this.gridVars?.has(name) || this.contVars?.has(name) || this.handlerVars?.has(name) || this.okDropped?.has(name));
  }

  /** a statement of the grid, its container or its handler - its plan, or
   *  undefined when it is none of them */
  gridPlan(s, k, flat, seq, si) {
    const objs = new Set([...this.gridVars, ...this.contVars, ...this.handlerVars]);
    const target = child(s, "Target") ? lc(nodeText(child(s, "Target"))).replace(/^data\s*\(\s*([\w/]+)\s*\)$/, "$1") : undefined;
    if ((k === "CreateObject" || (k === "Move" && /=\s*(new|cast)\b/.test(flat))) && objs.has(target)) {
      return { action: "drop", reason: "the grid, its container or the handler object - alv( ) needs none" };
    }
    if (k === "SetHandler") {
      const form = /\bfor\s+([\w/]+)/.exec(flat);
      if (form && this.gridVars.has(form[1])) return { action: "drop", reason: "SET HANDLER of the grid - its handlers are methods of the class" };
    }
    // IF go_container IS INITIAL - the grid is created once: the branch stays
    // the grid of REUSE_ALV_GRID_DISPLAY(_LVC) - for check_changed_data( ), which goes too
    if (k === "CallFunction" && /^call\s+function\s+'get_globals_from_slvc_fullscr'/.test(flat)) {
      const e = /\be_grid\s*=\s*([\w/]+)/.exec(flat);
      if (e && objs.has(e[1])) return { action: "drop", reason: "GET_GLOBALS_FROM_SLVC_FULLSCR - the grid of the ALV display is alv( ), there is no object to get" };
    }
    // CHECK go_grid IS NOT INITIAL - the grid is always there
    if (k === "Check" && /^check\s*:?\s*\(?\s*(not\s+)?([\w/]+)\s+is\s+(not\s+)?(initial|bound)\s*\)?$/.test(flat)) {
      const m = /([\w/]+)\s+is\s/.exec(flat);
      if (objs.has(m[1])) return { action: "drop", reason: "CHECK on the grid object - alv( ) needs none" };
    }
    if (k === "If") {
      const m = /^if\s+\(?\s*(not\s+)?([\w/]+)\s+is\s+(not\s+)?(initial|bound)\s*\)?$/.exec(flat);
      if (m && objs.has(m[2])) {
        const created = (!!m[1] !== !!m[3]) === (m[4] === "bound");   // the branch for the first time
        let depth = 0;
        let elseAt;
        let endAt;
        for (let j = si; j < seq.length; j++) {
          const kj = kind(seq[j]);
          if (OPENERS.has(kj)) depth++;
          if (CLOSERS.has(kj)) depth--;
          if (depth === 1 && kj === "ElseIf") return undefined;
          if (depth === 1 && kj === "Else") elseAt = j;
          if (depth === 0) {
            endAt = j;
            break;
          }
        }
        if (endAt === undefined) return undefined;
        const skip = (a, z) => { for (let j = a; j <= z; j++) this.alvPlan.set(seq[j], { action: "skip" }); };
        if (created) {
          if (elseAt !== undefined) skip(elseAt, endAt - 1);
        } else {
          skip(si + 1, elseAt ?? endAt - 1);
        }
        this.alvPlan.set(seq[endAt], { action: "skip" });
        return { action: "drop", reason: "IF on the grid object - the grid is created once, the branch that creates it stays" };
      }
    }
    if (k === "Call" || k === "Free" || k === "Clear") {
      const m = /^(?:call\s+method\s+)?([\w/]+)\s*->\s*(\w+)/.exec(flat);
      if (k !== "Call" && [...objs].some((o) => new RegExp(`\\b${o}\\b`).test(flat))) return { action: "drop", reason: "FREE / CLEAR of the grid object" };
      if (m && (this.contVars.has(m[1]) || this.handlerVars.has(m[1]))) return { action: "drop", reason: "a method of the container - alv( ) needs none" };
      if (m && this.gridVars.has(m[1])) {
        const p = functionParams(s);
        switch (m[2]) {
          case "set_table_for_first_display": {
            const table = p.get("it_outtab");
            if (!table) {
              this.refuse(s, "set_table_for_first_display( ) without CHANGING it_outtab - not understood");
              return { action: "skip" };
            }
            const plan = { action: "grid", table: nodeText(table.node), tableNode: table.node, todos: [] };
            const fc = p.get("it_fieldcatalog");
            plan.fieldcatVar = fc ? lc(nodeText(fc.node)) : undefined;
            const lay = p.get("is_layout");
            plan.layoutVar = lay ? lc(nodeText(lay.node)) : undefined;
            for (const ignored of ["it_toolbar_excluding", "is_variant", "i_save", "it_sort", "it_filter", "is_print", "i_default", "it_special_groups", "it_hyperlink", "it_except_qinfo"]) {
              if (p.has(ignored)) plan.todos.push(`set_table_for_first_display( ): ${uc(ignored)} has no counterpart in the alv( ) chain and is dropped`);
            }
            return plan;
          }
          case "refresh_table_display": case "check_changed_data": case "set_toolbar_interactive": case "register_edit_event":
          case "set_ready_for_input": case "free": case "set_frontend_layout": case "set_scroll_info_via_id": case "set_current_cell_via_id":
            this.note("the methods of cl_gui_alv_grid that refresh or tune the grid (refresh_table_display, check_changed_data, set_toolbar_interactive, ...) - alv( ) shows the table attribute as it is on every roundtrip");
            return { action: "drop", reason: `${m[2]}( ) of the grid - no counterpart needed` };
          case "get_selected_rows": {
            const rows = p.get("et_index_rows");
            const nos = p.get("et_row_no");
            const lines = [];
            if (rows) lines.push(`${nodeText(rows.node)} = VALUE #( FOR lv_r2c_row IN get_selected_rows( ) ( index = lv_r2c_row ) ).`);
            if (nos) lines.push(`${nodeText(nos.node)} = VALUE #( FOR lv_r2c_row IN get_selected_rows( ) ( row_id = lv_r2c_row ) ).`);
            this.gridSelection = true;
            return { action: "code", lines, reason: "`get_selected_rows( )` - the rows ticked in the selection column of the grid" };
          }
          default:
            this.refuse(s, `${m[2]}( ) of cl_gui_alv_grid - no counterpart in alv( ); port it by hand`);
            return { action: "skip" };
        }
      }
    }
    // any other use of the grid objects has nothing to refer to any more
    const toks = stmtTokens(s).map((t) => lc(t.getStr()));
    const used = toks.find((t, i) => objs.has(t) && (i === 0 || !["-", "->", "=>", "~"].includes(toks[i - 1])));
    if (used && !["Data", "Static"].includes(k)) {
      this.refuse(s, `${used}, the grid object, is used here - alv( ) has no object to refer to; port the statement by hand`);
      return { action: "skip" };
    }
    return undefined;
  }

  /** the functions the toolbar handler of the grid adds to e_object->mt_toolbar */
  gridToolbar(h) {
    const obj = h.params.find((x) => x === "e_object") ?? "e_object";
    const functions = [];
    const was = new Map();
    for (const x of h.body) {
      const k = kind(x);
      const toks = stmtTokens(x).map((t) => t.getStr());
      const flat = lc(toks.join(" "));
      if (k === "Comment" || k === "Data") continue;
      if (k === "Clear") {
        for (const t of toks.slice(1)) was.set(lc(t), {});
        continue;
      }
      let m = /^([\w/]+)\s*-\s*(\w+)\s*=\s*(.+)$/.exec(toks.join(" "));
      // MOVE 'X' TO wa-function - the same as wa-function = 'X'
      const mv = /^MOVE\s+(.+?)\s+TO\s+([\w/]+)\s*-\s*(\w+)$/i.exec(toks.join(" "));
      if (mv) m = [mv[0], mv[2], mv[3], mv[1]];
      if (k === "Move" && m) {
        const cur = was.get(lc(m[1])) ?? {};
        cur[lc(m[2])] = m[3].trim();
        was.set(lc(m[1]), cur);
        continue;
      }
      const onToolbar = new RegExp(`to\\s+${obj}\\s*->\\s*mt_toolbar\\b`).test(flat);
      if (k === "Append" && onToolbar) {
        m = /^append\s+([\w/]+)\s+to\s+/.exec(flat);
        const v = /^APPEND\s+VALUE\s+#\s*\((.*)\)\s+TO\s+/i.exec(toks.join(" "));
        let cur;
        if (v) {
          cur = {};
          for (const pv of v[1].matchAll(/(\w+)\s*=\s*('(?:[^']|'')*'|`(?:[^`]|``)*`|[\w-]+(?:\s*\(\s*\w+\s*\))?)/g)) cur[lc(pv[1])] = pv[2];
        } else if (m) cur = { ...(was.get(m[1]) ?? {}) };
        if (!cur) {
          this.refuse(x, `the toolbar handler ${h.method}: this APPEND is not understood`);
          continue;
        }
        if (/^3$|^'3'$|cntb_btype_sep/.test(lc(cur.butn_type ?? ""))) continue;
        if (!cur.function) {
          this.refuse(x, `the toolbar handler ${h.method}: a button without FUNCTION`);
          continue;
        }
        functions.push(cur);
        continue;
      }
      if ((k === "DeleteInternal" || k === "Modify" || k === "ModifyInternal") && new RegExp(`${obj}\\s*->\\s*mt_toolbar`).test(flat)) {
        this.note("the toolbar handler removes or changes the standard functions of the grid - the grid of the runtime has its own (sort, filter, export)");
        continue;
      }
      this.refuse(x, `the toolbar handler ${h.method}: only buttons appended to ${obj}->mt_toolbar are converted - port this statement by hand`);
    }
    return functions.map((f) => {
      const params = [{ name: "name", value: literal(uc(unquote(f.function))) }];
      if (f.text) params.push({ name: "text", value: this.literalArg(f.text, h.stmt) });
      const icon = f.icon ? ICONS[lc(f.icon)] : undefined;
      if (icon) params.push({ name: "icon", value: literal(icon) });
      else if (f.icon) this.note(`the toolbar of the grid: the icon ${uc(f.icon)} has no UI5 icon in the converter's table - the button shows its text`);
      if (f.quickinfo) params.push({ name: "tooltip", value: this.literalArg(f.quickinfo, h.stmt) });
      return { m: "add_function", params };
    });
  }

  /** the body of a handler of the grid as the body of a method of the
   *  report class: the event parameters renamed after the method's */
  gridHandlerBody(h, ctx, renames) {
    if (h.body.some((x) => /\bme\s*->/i.test(renderTokens(stmtTokens(x))))) {
      this.refuse(h.stmt, `${h.method}: the handler uses me-> - in the report class me is the report; port it by hand`);
      return [];
    }
    const body = this.convertBody(h.body, ctx);
    const out = [];
    for (const l of body) {
      let t = l;
      for (const [re, to] of renames) t = t.replace(re, to);
      out.push(t);
    }
    // the row and column structures of the event, used as a whole (passed
    // to a FORM, CASE e_column_id): rebuilt from row and column
    const column = ctx.method === "at_link_click" ? "column" : undefined;
    const rebuilt = {
      e_row: `z2ui5_cl_cgui_alv=>ty_s_lvc_row( index = row )`, e_row_id: `z2ui5_cl_cgui_alv=>ty_s_lvc_row( index = row )`,
      es_row_no: `z2ui5_cl_cgui_alv=>ty_s_lvc_roid( row_id = row )`,
      ...(ctx.method === "at_user_command" ? {} : {
        e_column: `z2ui5_cl_cgui_alv=>ty_s_lvc_col( ${column ? `fieldname = ${column} ` : ""})`,
        e_column_id: `z2ui5_cl_cgui_alv=>ty_s_lvc_col( ${column ? `fieldname = ${column} ` : ""})`,
      }),
    };
    if (ctx.method === "at_user_command") {
      delete rebuilt.e_row;
      delete rebuilt.e_row_id;
      delete rebuilt.es_row_no;
    }
    const used = (p) => out.some((l) => new RegExp(`\\b${p}\\b`, "i").test(l));
    const decls = h.params.filter((p) => rebuilt[p] && used(p)).map((p) => `DATA(${p}) = VALUE ${rebuilt[p]}.`);
    if (!column && h.params.some((p) => /^e_column(_id)?$/.test(p) && used(p))) {
      this.todo(h.stmt, `${h.method}: the column of a double click is not known - e_column-fieldname is empty; a HOTSPOT_CLICK handler has it`);
    }
    out.unshift(...decls);
    const left = h.params.filter((p) => p !== "sender" && !rebuilt[p] && used(p));
    if (left.length) this.refuse(h.stmt, `${h.method}: ${left.join(", ")} ${left.length > 1 ? "have" : "has"} no counterpart in ${ctx.method}( ) - it knows ${ctx.method === "at_user_command" ? "ucomm" : ctx.method === "at_link_click" ? "row and column" : "the row"} only`);
    if (h.params.includes("sender") && out.some((l) => /\bsender\b/i.test(l))) this.refuse(h.stmt, `${h.method}: sender - the grid object has no counterpart`);
    return [`" the ${uc(h.event)} handler of the grid - ${h.cls}->${h.method}`, ...out];
  }

  /** CL_SALV_TABLE and REUSE_ALV_*: what each statement becomes - looked at
   *  over the whole report first, because the settings of a grid are often
   *  made in another FORM than the one that displays it */
  analyzeAlv() {
    this.alvPlan = new Map();     // statement -> { action: "drop" | "alv" | "skip", ... }
    this.salv = new Map();        // salv variable -> { table, settings, lineSelection }
    const cols = new Map();       // columns variable -> salv variable
    const col = new Map();        // column variable -> { salv, name }
    this.salvVars = new Set();
    const fcat = new Map();       // field catalog table -> [{ name, text, hidden }]
    const fcatWa = new Map();     // field catalog work area -> current column
    this.fcatVars = new Set();
    this.layoutVars = new Set();
    this.alvCallbacks = new Map(); // FORM name -> callback kind
    this.fcat = fcat;
    this.layoutTitle = new Map();  // layout variable -> the title it sets (grid_title)

    // the variables: REF TO cl_salv_*, the field catalog and layout types
    const allStmts = [...this.decls, ...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body)];
    for (const s of allStmts) {
      // DATA(fcat) = VALUE lvc_t_fcat( ... ) - declared where it is filled
      if (kind(s) === "Move") {
        const m = /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*value\s+(slis_t_fieldcat_alv|lvc_t_fcat)\s*\(/.exec(lc(renderTokens(stmtTokens(s))));
        if (m) this.fcatVars.add(m[1]);
        continue;
      }
      if (!["Data", "Static"].includes(kind(s))) continue;
      const text = lc(renderTokens(stmtTokens(s)));
      const name = lc(declName(s) ?? "");
      if (/type\s+ref\s+to\s+c[lx]_salv_/.test(text)) this.salvVars.add(name);
      if (/type\s+(standard\s+table\s+of\s+|table\s+of\s+|line\s+of\s+)?(slis_t_fieldcat_alv|slis_fieldcat_alv|lvc_t_fcat|lvc_s_fcat)\b/.test(text)) this.fcatVars.add(name);
      if (/type\s+(slis_layout_alv|lvc_s_layo|slis_print_alv|disvariant|slis_t_sortinfo_alv|slis_t_event|slis_t_listheader|lvc_t_sort)\b/.test(text)) this.layoutVars.add(name);
    }

    const tryStack = [];
    const seq = [...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body), ...this.gridHandlers.flatMap((h) => h.body)];
    for (let si = 0; si < seq.length; si++) {
      const s = seq[si];
      const k = kind(s);
      const toks = stmtTokens(s).map((t) => t.getStr());
      const flat = lc(toks.join(" "));

      if (k === "Try") { tryStack.push({ stmt: s, clauses: [], cleanup: false }); continue; }
      if (k === "Catch" && tryStack.length) {
        const names = children(s, "ClassName").map((c) => lc(nodeText(c)));
        tryStack[tryStack.length - 1].clauses.push({ stmt: s, names, body: [] });
        continue;
      }
      if (k === "Cleanup" && tryStack.length) { tryStack[tryStack.length - 1].cleanup = true; continue; }
      if (k === "EndTry" && tryStack.length) {
        const t = tryStack.pop();
        let kept = 0;
        for (const c of t.clauses) {
          if (c.names.every((n) => /^cx_salv_/.test(n))) {
            this.alvPlan.set(c.stmt, { action: "skip", reason: "CATCH of a CL_SALV_TABLE exception - alv( ) raises none" });
            for (const b of c.body) this.alvPlan.set(b, { action: "skip" });
          } else {
            kept++;
            if (c.names.some((n) => /^cx_salv_/.test(n))) this.alvPlan.set(c.stmt, { action: "catch", names: c.names.filter((n) => !/^cx_salv_/.test(n)) });
          }
        }
        if (kept === 0 && !t.cleanup && t.clauses.length) {
          this.alvPlan.set(t.stmt, { action: "skip" });
          this.alvPlan.set(s, { action: "skip" });
        }
        continue;
      }
      if (tryStack.length) {
        const t = tryStack[tryStack.length - 1];
        if (t.clauses.length) t.clauses[t.clauses.length - 1].body.push(s);
      }

      if (this.gridVars.size && !this.alvPlan.has(s)) {
        const plan = this.gridPlan(s, k, flat, seq, si);
        if (plan) {
          this.alvPlan.set(s, plan);
          continue;
        }
      }

      // cl_salv_table=>factory( IMPORTING r_salv_table = x CHANGING t_table = itab )
      if (/cl_salv_table\s*=>\s*factory/.test(flat)) {
        const m = /r_salv_table\s*=\s*(?:data\s*\(\s*)?([\w/]+)/.exec(flat);
        const tab = /t_table\s*=\s*([\w/-]+)/.exec(flat);
        if (!m || !tab) {
          this.refuse(s, "cl_salv_table=>factory( ) without r_salv_table and t_table - not understood");
          continue;
        }
        this.salvVars.add(m[1]);
        const tableTok = stmtTokens(s).find((t) => lc(t.getStr()) === tab[1].split("-")[0]);
        this.salv.set(m[1], { table: tab[1], tableTok, settings: [], lineSelection: false, displayed: false, stmt: s });
        this.alvPlan.set(s, { action: "drop", reason: "cl_salv_table=>factory( ) - alv( ) at display( )" });
        continue;
      }

      // a call chain over a SALV object: x->get_columns( )->get_column( 'A' )->set_long_text( ... )
      const chain = salvChain(s);
      if (chain) {
        let ctx;
        let target = chain.target;
        if (this.salv.has(chain.root)) ctx = { level: "salv", salv: chain.root };
        else if (cols.has(chain.root)) ctx = { level: "columns", salv: cols.get(chain.root) };
        else if (col.has(chain.root)) ctx = { level: "column", ...col.get(chain.root) };
        if (ctx) {
          let ok = true;
          for (const c of chain.calls) {
            const salv = this.salv.get(ctx.salv);
            const arg = c.arg;
            switch (`${ctx.level}.${c.name}`) {
              case "salv.get_columns": ctx = { ...ctx, level: "columns" }; break;
              case "columns.get_column":
                ctx = { ...ctx, level: "column", name: arg && /^['`]/.test(arg) ? uc(unquote(arg)) : undefined };
                break;
              case "salv.get_display_settings": ctx = { ...ctx, level: "display" }; break;
              case "salv.get_functions": ctx = { ...ctx, level: "functions" }; break;
              case "salv.get_event": ctx = { ...ctx, level: "event" }; break;
              case "salv.get_sorts": case "salv.get_aggregations": case "salv.get_layout": case "salv.get_selections":
              case "salv.get_filters":
                ctx = { ...ctx, level: "other" }; break;
              case "salv.display":
                salv.displayed = true;
                this.alvPlan.set(s, { action: "alv", salv: ctx.salv });
                break;
              case "display.set_list_header": salv.settings.push({ m: "set_title", arg }); break;
              case "column.set_long_text": case "column.set_medium_text": case "column.set_short_text":
                if (ctx.name) salv.settings.push({ m: "set_column_text", name: ctx.name, arg, rank: c.name });
                else ok = false;
                break;
              case "column.set_visible":
                if (ctx.name && /abap_false|' '|space/.test(lc(arg ?? ""))) salv.settings.push({ m: "set_column_hidden", name: ctx.name });
                else if (!ctx.name) ok = false;
                break;
              case "column.set_technical":
                if (ctx.name && !/abap_false|' '|space/.test(lc(arg ?? ""))) salv.settings.push({ m: "set_column_hidden", name: ctx.name });
                break;
              case "columns.set_optimize": case "functions.set_all": case "functions.set_default": case "display.set_striped_pattern":
              case "column.set_optimized": case "column.set_output_length":
                this.note("CL_SALV_TABLE settings without a counterpart (optimized widths, toolbar functions, striped rows) - the grid sorts and filters by itself");
                break;
              default:
                ok = false;
            }
          }
          if (chain.target) {
            if (ctx.level === "columns") cols.set(target, ctx.salv);
            else if (ctx.level === "column") col.set(target, { salv: ctx.salv, name: ctx.name });
            else if (ctx.level !== "salv") ok = ok && ["display", "functions", "event", "other"].includes(ctx.level);
            this.salvVars.add(target);
          }
          if (!this.alvPlan.has(s)) {
            this.alvPlan.set(s, ok
              ? { action: "drop", reason: "CL_SALV_TABLE setting - in the alv( ) chain" }
              : { action: "drop", reason: "CL_SALV_TABLE call", todo: `CL_SALV_TABLE call without a counterpart in the alv( ) chain, dropped: ${shortText(s)}` });
          }
          continue;
        }
      }

      // SET HANDLER ... FOR salv->get_event( ) - the double click
      if (k === "SetHandler") {
        const m = /for\s+([\w/]+)\s*->\s*get_event/.exec(flat) ?? /for\s+([\w/]+)\s*\./.exec(flat + ".");
        const v = m && (this.salv.has(m[1]) ? m[1] : undefined);
        if (v) {
          this.salv.get(v).lineSelection = true;
          this.alvPlan.set(s, { action: "drop", reason: "SET HANDLER of the SALV events - set_line_selection( )",
            todo: "the ALV event handler is dropped: move the code of its double click handler into at_line_selection( ) - row is the index of the clicked row" });
          continue;
        }
      }

      if (k === "CallFunction") {
        const fm = uc(unquote(nodeText(child(s, "FunctionName")).trim()));
        if (fm === "REUSE_ALV_FIELDCATALOG_MERGE" || fm === "LVC_FIELDCATALOG_MERGE") {
          this.alvPlan.set(s, { action: "drop", reason: `${fm} - the columns come from the table (RTTI)` });
          continue;
        }
        if (/^REUSE_ALV_(GRID|LIST)_DISPLAY(_LVC)?$/.test(fm)) {
          const p = functionParams(s);
          const table = p.get("t_outtab");
          if (!table) {
            this.refuse(s, `${fm} without TABLES t_outtab - not understood`);
            continue;
          }
          const plan = { action: "reuse", fm, table: nodeText(table.node), tableNode: table.node, settings: [], lineSelection: false };
          const title = p.get("i_grid_title") ?? p.get("i_title");
          if (title) plan.settings.push({ m: "set_title", arg: nodeText(title.node) });
          // the field catalog is read when the call is written - it is often
          // built in a FORM further down
          const fc = p.get("it_fieldcat") ?? p.get("it_fieldcat_lvc");
          plan.fieldcatVar = fc ? lc(nodeText(fc.node)) : undefined;
          const ucomm = p.get("i_callback_user_command");
          if (ucomm) {
            plan.lineSelection = true;
            const formName = lc(unquote(nodeText(ucomm.node).trim()));
            this.alvCallbacks.set(formName, { kind: "user_command", stmt: s });
          }
          for (const cb of ["i_callback_pf_status_set", "i_callback_top_of_page", "i_callback_html_top_of_page", "i_callback_html_end_of_list"]) {
            const v = p.get(cb);
            if (!v) continue;
            const formName = lc(unquote(nodeText(v.node).trim()));
            this.alvCallbacks.set(formName, { kind: cb, stmt: s });
          }
          for (const ignored of ["is_layout", "is_layout_lvc", "it_sort", "it_sort_lvc", "it_events", "is_variant", "i_save", "it_filter", "is_print", "it_excluding"]) {
            if (p.has(ignored)) plan.todos = [...(plan.todos ?? []), `${fm}: ${uc(ignored)} has no counterpart in the alv( ) chain and is dropped`];
          }
          this.alvPlan.set(s, plan);
          // IF sy-subrc <> 0 right after it checked the EXCEPTIONS of the
          // function - alv( ) raises none, and sy-subrc is the one of the
          // statement before
          let next = si + 1;
          while (seq[next] && kind(seq[next]) === "Comment") next++;
          if (seq[next] && kind(seq[next]) === "If" && /sy\s*-\s*subrc/i.test(renderTokens(seq[next].getTokens()))) {
            let depth = 0;
            for (let j = next; j < seq.length; j++) {
              const kj = kind(seq[j]);
              if (kj === "If") depth++;
              if (kj === "EndIf") depth--;
              this.alvPlan.set(seq[j], { action: "skip" });
              if (depth === 0) break;
            }
            plan.todos = [...(plan.todos ?? []), `${fm}: the IF sy-subrc after the call checked its EXCEPTIONS - alv( ) raises none, the check is dropped`];
          }
          continue;
        }
      }

      // the field catalog of REUSE_ALV_*: wa-fieldname = 'A', wa-seltext_m = 'T', APPEND wa TO fcat
      const fcatRoot = toks.length ? lc(toks[0]) : "";
      if (this.fcatVars.has(fcatRoot) || toks.some((t, i) => this.fcatVars.has(lc(t)) && (i === 0 || !["-", "->", "=>"].includes(toks[i - 1])))) {
        const m = /^([\w/]+)\s*-\s*(\w+)\s*=\s*(.+)$/.exec(flat);
        const orig = /^[\w/]+\s*-\s*\w+\s*=\s*(.+)$/.exec(toks.join(" "));
        // a block over the field catalog (LOOP AT fcat ASSIGNING <fs> ... ENDLOOP)
        // sets its columns by position - dropped alone, its ENDLOOP would stay
        if (OPENERS.has(k)) {
          this.refuse(s, `${shortText(s)} - a block over the field catalog; alv( ) takes the columns set field by field, port it by hand`);
          continue;
        }
        // a value the alv( ) chain can take where the grid is shown: a literal,
        // a text symbol, a global of the report - not a FORM's parameter
        const fixed = (v) => /^['`]/.test(v) || /^text-\w+$/i.test(v) || this.globalData.has(lc(v.split("-")[0]));
        if (k === "Move" && m && this.fcatVars.has(m[1]) && /^(fieldname|seltext_[lms]|reptext_ddic|scrtext_[lms]|coltext)$/.test(m[2]) && !fixed(orig[1].trim())) {
          this.refuse(s, `the field catalog is filled from ${orig[1].trim()} - alv( ) is set up where the grid is shown, where it is not known; port the field catalog by hand`);
          continue;
        }
        if (k === "Move" && m && this.fcatVars.has(m[1])) {
          const cur = fcatWa.get(m[1]) ?? {};
          if (m[2] === "fieldname") cur.name = uc(unquote(orig[1].trim()));
          else if (/^(seltext_[lms]|reptext_ddic|scrtext_[lms]|coltext)$/.test(m[2])) cur.text = orig[1].trim();
          else if ((m[2] === "no_out" || m[2] === "tech") && /'x'|abap_true/.test(m[3])) cur.hidden = true;
          else if (m[2] === "hotspot" && /'x'|abap_true/.test(m[3])) cur.hotspot = true;
          else if (m[2] === "do_sum" && /'x'|abap_true/.test(m[3])) cur.sum = true;
          else this.note("field catalog settings without a counterpart (output length, key, sums, column position) - the grid takes columns and widths from the table");
          fcatWa.set(m[1], cur);
        } else if (k === "Move" && /^(?:data\s*\(\s*)?([\w/]+)(?:\s*\))?\s*=\s*value\s+[\w/#]+\s*\(/.test(flat)) {
          // fcat = VALUE #( ( fieldname = 'A' coltext = 'T' ) ( ... ) ) - a column per row
          const target = /^(?:data\s*\(\s*)?([\w/]+)/.exec(flat)[1];
          const text = toks.join(" ");
          const rows = valueRows(text.slice(text.search(/\bvalue\b/i)));
          if (this.fcatVars.has(target) && rows) {
            if (!fcat.has(target)) fcat.set(target, []);
            fcat.get(target).push(...rows.map(fcatColumn));
          }
        } else if (k === "Append") {
          const m2 = /^append\s+([\w/]+)\s+to\s+([\w/]+)/.exec(flat);
          const v = /^append\s+value\s+#\s*\((.*)\)\s+to\s+([\w/]+)/i.exec(toks.join(" "));
          if (m2 && this.fcatVars.has(m2[2])) {
            if (!fcat.has(m2[2])) fcat.set(m2[2], []);
            fcat.get(m2[2]).push({ ...(fcatWa.get(m2[1]) ?? {}) });
          } else if (v && this.fcatVars.has(lc(v[2]))) {
            if (!fcat.has(lc(v[2]))) fcat.set(lc(v[2]), []);
            fcat.get(lc(v[2])).push(fcatColumn(v[1]));
          }
        } else if (k === "Clear") {
          for (const v of this.fcatVars) if (new RegExp(`\\b${v}\\b`).test(flat)) fcatWa.set(v, {});
        }
        this.alvPlan.set(s, { action: "drop", reason: "field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain" });
        continue;
      }
      // the layout of the grid: its title; zebra and optimized widths are the runtime's
      {
        const m = /^([\w/]+)\s*-\s*(\w+)\s*=\s*(.+)$/.exec(toks.join(" "));
        if (k === "Move" && m && this.layoutVars.has(lc(m[1]))) {
          const comp = lc(m[2]);
          if (comp === "grid_title" || comp === "window_titlebar") {
            this.layoutTitle.set(lc(m[1]), m[3].trim());
            this.alvPlan.set(s, { action: "drop", reason: "the title of the grid - set_title( ) in the alv( ) chain" });
            continue;
          }
          if (["zebra", "cwidth_opt", "col_opt", "colwidth_optimize", "zebra_pattern", "no_rowmark"].includes(comp)) {
            this.note("ALV layout: zebra stripes and optimized column widths - the grid of the runtime lays itself out");
            this.alvPlan.set(s, { action: "drop", reason: "ALV layout - the grid lays itself out" });
            continue;
          }
        }
      }
      if (toks.some((t, i) => this.layoutVars.has(lc(t)) && (i === 0 || !["-", "->", "=>"].includes(toks[i - 1]))) && k !== "CallFunction") {
        this.alvPlan.set(s, { action: "drop", reason: "ALV layout", todo: `ALV layout, sort or event setting without a counterpart, dropped: ${shortText(s)}` });
        continue;
      }

    }
    // any other use of a SALV object - or of its columns - has nothing to
    // refer to any more: the objects are gone, alv( ) shows the table
    for (const s of seq) {
      if (this.alvPlan.has(s) || ["Data", "Static", "Comment"].includes(kind(s))) continue;
      const toks = stmtTokens(s).map((t) => lc(t.getStr()));
      const used = toks.find((t, i) => this.salv.has(t) || cols.has(t) || col.has(t)
        ? i === 0 || !["-", "->", "=>", "~"].includes(toks[i - 1]) : false);
      if (used) this.refuse(s, `${used}, an object of CL_SALV_TABLE, is used here - alv( ) has no object to refer to; port the statement by hand`);
    }
    // a FORM that only built the field catalog or set up the ALV is empty now
    this.emptyForms = new Set(this.forms.filter((f) => {
      const code = f.body.filter((x) => kind(x) !== "Comment");
      return code.length > 0 && code.every((x) => ["drop", "skip"].includes(this.alvPlan.get(x)?.action));
    }).map((f) => lc(nodeText(child(f.stmt, "FormName")))));
    for (const [name, v] of this.salv) {
      if (!v.displayed) this.todo(v.stmt, `the CL_SALV_TABLE object ${name} is created but never displayed - no alv( ) is generated for it`);
    }
  }

  /** the selection screen: fields, value requests, user commands, HIDE */
  analyzeScreen() {
    this.valueRequest = new Set();
    this.helpRequest = new Set();
    for (const e of this.events) {
      if (e.kind !== "AtSelectionScreen") continue;
      const t = uc(renderTokens(stmtTokens(e.stmt)));
      const m = /ON\s+VALUE-REQUEST\s+FOR\s+([\w/]+)(-LOW|-HIGH)?/.exec(t);
      if (m) this.valueRequest.add(lc(m[1]));
      const h = /ON\s+HELP-REQUEST\s+FOR\s+([\w/]+)(-LOW|-HIGH)?/.exec(t);
      if (h) this.helpRequest.add(lc(h[1]));
    }
    // SELECTION-SCREEN FUNCTION KEY n: its text is set in sscrfields-functxt_0n,
    // a text or an SMP_DYNTXT structure with icon_id / icon_text / text
    this.functionKeys = new Map();     // n -> { text, icon }
    this.screenDrops = new Map();      // statement -> why it is dropped
    this.fkeyVars = new Set();
    const body = [...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body)];
    const dyntxt = new Map();          // variable -> { text, icon }
    for (const x of [...this.decls, ...body]) {
      if (kind(x) === "Data" && /type\s+smp_dyntxt\b/i.test(renderTokens(stmtTokens(x)))) this.fkeyVars.add(lc(declName(x)));
    }
    for (const x of body) {
      if (kind(x) !== "Move" && kind(x) !== "Clear") continue;
      const flat = renderTokens(stmtTokens(x));
      if (kind(x) === "Clear" && [...this.fkeyVars].some((v) => new RegExp(`\\b${v}\\b`, "i").test(flat))) {
        this.screenDrops.set(x, "the text of a function key - function_key( ) in selection_screen( )");
        continue;
      }
      let m = /^([\w/]+)\s*-\s*(icon_id|icon_text|text|quickinfo|path)\s*=\s*(.+)$/i.exec(flat);
      if (m && this.fkeyVars.has(lc(m[1]))) {
        const cur = dyntxt.get(lc(m[1])) ?? {};
        cur[lc(m[2])] = m[3].trim();
        dyntxt.set(lc(m[1]), cur);
        this.screenDrops.set(x, "the text of a function key - function_key( ) in selection_screen( )");
        continue;
      }
      m = /^sscrfields\s*-\s*functxt_0([1-5])\s*=\s*(.+)$/i.exec(flat);
      if (m) {
        const v = m[2].trim();
        const d = dyntxt.get(lc(v));
        const icon = d?.icon_id ? ICONS[lc(d.icon_id)] : undefined;
        this.functionKeys.set(Number(m[1]), d ? { text: d.icon_text ?? d.text, icon, quickinfo: d.quickinfo } : { text: v });
        this.screenDrops.set(x, `the text of FUNCTION KEY ${m[1]} - function_key( ) in selection_screen( )`);
      }
    }
    // SELECTION-SCREEN BEGIN OF TABBED BLOCK tb - a program that selects
    // the tab itself (tb-activetab, tb-dynnr) has no counterpart
    this.tabbedBlocks = new Set(this.decls.filter((x) => kind(x) === "SelectionScreen" && hasSeq(words(x), "BEGIN", "OF", "TABBED", "BLOCK"))
      .map((x) => lc(nodeText(child(x, "BlockName")))));
    // AT SELECTION-SCREEN ON BLOCK b - the runtime knows a block by the name
    // block_begin( ) is given, so the blocks named there get one
    this.onBlocks = new Set(this.events.filter((e) => e.kind === "AtSelectionScreen")
      .map((e) => /ON\s+BLOCK\s+([\w/]+)$/.exec(uc(renderTokens(stmtTokens(e.stmt)))))
      .filter(Boolean).map((m) => m[1]));
    this.blocks = new Map();
    let depth = 0;
    const open = [];
    for (const s of this.decls) {
      if (kind(s) !== "SelectionScreen") continue;
      const w = words(s);
      if (hasSeq(w, "BEGIN", "OF", "BLOCK")) {
        const name = uc(nodeText(child(s, "BlockName")));
        for (const outer of open) this.blocks.get(outer).nested = true;
        this.blocks.set(name, { depth: depth++, nested: false });
        open.push(name);
      } else if (hasSeq(w, "END", "OF", "BLOCK")) {
        open.pop();
        depth--;
      }
    }
    this.screenUcomm = this.decls.some((s) => (kind(s) === "Parameter" && hasSeq(words(s), "USER", "-", "COMMAND"))
      || (kind(s) === "SelectionScreen" && words(s).includes("PUSHBUTTON")));
    const ass = this.events.filter((e) => e.kind === "AtSelectionScreen" && /^AT\s+SELECTION-SCREEN$/.test(uc(renderTokens(stmtTokens(e.stmt)))));
    this.assUcomm = ass.some((e) => e.stmts.some((s) => /\b(sy|sscrfields)\s*-\s*ucomm\b/i.test(renderTokens(s.getTokens()))));
  }

  // --------------------------------------------------------------- generate

  generate() {
    const cls = this.className;
    this.continuations = [];
    // the fields a WRITE ... UNDER refers to - their WRITE gets their name
    this.underTargets = new Set();
    for (const x of this.stmts) {
      if (kind(x) !== "Write") continue;
      const ch = x.getChildren();
      const at = ch.findIndex((c) => isToken(c) && uc(c.get().getStr()) === "UNDER");
      if (at >= 0 && ch[at + 1]) this.underTargets.add(underName(nodeText(ch[at + 1])));
    }
    const pub = [];          // PUBLIC SECTION
    const methods = [];      // { name, def, body: string[] }
    this.methodDefs = [];    // PRIVATE methods
    this.redefined = new Set();
    this.tablesTypes = new Map();

    // the declarations: attributes, types, constants
    const screen = this.declarations(pub);

    // FORMs first - their method names are needed by every PERFORM
    for (const f of this.forms) {
      if (this.alvCallbacks.has(f.name) || this.emptyForms.has(f.name)) continue;
      this.formSignature(f);
    }

    // the event blocks
    const byKind = (k, pred = () => true) => this.events.filter((e) => e.kind === k && pred(e));
    const assText = (e) => uc(renderTokens(stmtTokens(e.stmt)));

    // INITIALIZATION: title, defaults, LOAD-OF-PROGRAM, INITIALIZATION
    {
      const body = [];
      if (this.pool.title) body.push(`set_title( ${literal(this.pool.title)} ).`);
      if (this.lineCount) {
        body.push(`set_line_count( ${this.lineCount.lines} ).`);
        this.note("REPORT ... LINE-COUNT n is set_line_count( n ) - a page holds n lines of the list besides its header and footer; the classic n counted them too");
      }
      body.push(...screen.defaults);
      for (const e of [...byKind("LoadOfProgram"), ...byKind("Initialization")]) {
        this.map(e.stmt, "`initialization( )`");
        if (body.length) body.push("");
        body.push(...this.convertBody(e.stmts, { method: "initialization" }));
      }
      if (body.length) methods.push({ name: "initialization", body });
    }

    if (screen.chain.length) {
      methods.push({ name: "selection_screen", body: screen.chain });
    }
    if (this.dynnrScreens.size) {
      const body = ["CASE dynnr."];
      for (const [nr, d] of this.dynnrScreens) {
        body.push(`  WHEN ${literal(nr)}.`, ...renderScreenChain(d.chain).map((l) => indent(l, 4)));
      }
      body.push("ENDCASE.");
      methods.push({ name: "selection_screen_dynnr", body });
    }
    // the statements after a CALL SELECTION-SCREEN or a popup go on in
    // after_call_selection_screen( dynnr subrc ) / at_user_command( ucomm )
    // (this.continuations, set up at the start of generate( ))

    // AT SELECTION-SCREEN OUTPUT
    {
      const evs = byKind("AtSelectionScreen", (e) => /OUTPUT$/.test(assText(e)));
      if (evs.length) {
        const body = [];
        for (const e of evs) {
          this.map(e.stmt, "`at_selection_screen_output( screen )`");
          body.push(...this.convertBody(e.stmts, { method: "at_selection_screen_output", screenEvent: true }));
        }
        methods.push({ name: "at_selection_screen_output", body });
      }
    }

    // AT SELECTION-SCREEN ON field, ON VALUE-REQUEST, ON BLOCK, ON
    // RADIOBUTTON GROUP, ON END OF, ON EXIT-COMMAND (ON HELP-REQUEST refused)
    const onField = [];
    const onBlock = [];
    const onRadio = [];
    const onEndOf = [];
    const onExit = [];
    const valueRequest = [];
    const onHelp = [];
    for (const e of byKind("AtSelectionScreen")) {
      const t = assText(e);
      if (/^AT\s+SELECTION-SCREEN(\s+OUTPUT)?$/.test(t)) continue;
      let m;
      if ((m = /ON\s+VALUE-REQUEST\s+FOR\s+([\w/]+)(-LOW|-HIGH)?$/.exec(t))) {
        const field = m[1];
        if (!this.screenField(field)) {
          this.refuse(e.stmt, `ON VALUE-REQUEST FOR ${field} - no parameter or select-option of that name`);
          continue;
        }
        const part = m[2] === "-HIGH" ? "high" : "low";
        const before = valueRequest.find((v) => v.field === field);
        // FOR s-low and FOR s-high: one WHEN, value_request_part( ) tells them apart
        if (before && (before.parts[part] || !this.selectOptions.has(lc(field)))) {
          this.refuse(e.stmt, `a second ON VALUE-REQUEST for ${field} - a select-option has one F4 for LOW and one for HIGH`);
          continue;
        }
        this.map(e.stmt, `\`at_value_request( field )\` - WHEN \`${field}\`, the field declared with value_help${before ? ", value_request_part( ) is HIGH or LOW" : ""}`);
        const body = this.convertBody(e.stmts, { method: "at_value_request", valueRequest: true });
        // s_x-low = value in the F4 of a select-option: the header line was
        // the line on the screen - here a work area of the method
        const so = lc(field);
        if (this.selectOptions.has(so) && body.some((l) => new RegExp(`\\b\\w*${so}\\s*-\\s*(low|high)\\s*=`, "i").test(l))) {
          this.todo(e.stmt, `ON VALUE-REQUEST FOR ${field}: ${so}-low / -high = ... wrote the line on the screen - here it is a work area of the method; pick the value with value_help_popup( ), which writes the field asked for`);
        }
        if (before) before.parts[part] = body;
        else valueRequest.push({ field, parts: { [part]: body } });
      } else if ((m = /ON\s+BLOCK\s+([\w/]+)$/.exec(t))) {
        const block = m[1];
        if (!this.blocks.has(block)) {
          this.refuse(e.stmt, `ON BLOCK ${block} - no SELECTION-SCREEN BEGIN OF BLOCK ${block}`);
          continue;
        }
        this.map(e.stmt, `\`at_selection_screen_on_block( block )\` - WHEN \`${block}\`, the name of block_begin( )`);
        if (this.blocks.get(block).nested) this.todo(e.stmt, `ON BLOCK ${block}: the block holds another block - the runtime raises the event for the blocks that hold fields themselves, and a field of the inner block belongs to the inner one only`);
        onBlock.push({ field: block, body: this.convertBody(e.stmts, { method: "at_selection_screen_on_block" }) });
      } else if ((m = /ON\s+RADIOBUTTON\s+GROUP\s+([\w/]+)$/.exec(t))) {
        const group = m[1];
        if (!this.radioGroups?.has(group)) {
          this.refuse(e.stmt, `ON RADIOBUTTON GROUP ${group} - no radio button of that group`);
          continue;
        }
        this.map(e.stmt, `\`at_selection_screen_on_radio( group )\` - WHEN \`${group}\``);
        onRadio.push({ field: group, body: this.convertBody(e.stmts, { method: "at_selection_screen_on_radio" }) });
      } else if ((m = /ON\s+END\s+OF\s+([\w/]+)$/.exec(t))) {
        const field = m[1];
        if (!this.selectOptions?.has(lc(field))) {
          this.refuse(e.stmt, `ON END OF ${field} - no select-option of that name`);
          continue;
        }
        this.map(e.stmt, `\`at_selection_screen_on_end_of( field )\` - WHEN \`${field}\`, the multiple selection left with OK`);
        onEndOf.push({ field, body: this.convertBody(e.stmts, { method: "at_selection_screen_on_end_of" }) });
      } else if (/ON\s+EXIT-COMMAND$/.test(t)) {
        this.map(e.stmt, "`at_selection_screen_on_exit( ucomm )` - Back on the selection screen");
        if (e.stmts.some((x) => /\b(sy|sscrfields)\s*-\s*ucomm\b/i.test(renderTokens(x.getTokens())))) {
          this.todo(e.stmt, "ON EXIT-COMMAND: ucomm is `CGUI_BACK` (cs_ucomm-back) here, not BACK, %EX or RW - check the codes the block compares");
        }
        onExit.push(...this.convertBody(e.stmts, { method: "at_selection_screen_on_exit", ucomm: true }));
      } else if ((m = /ON\s+HELP-REQUEST\s+FOR\s+([\w/]+)(-LOW|-HIGH)?$/.exec(t))) {
        const field = m[1];
        if (!this.screenField(field)) {
          this.refuse(e.stmt, `ON HELP-REQUEST FOR ${field} - no parameter or select-option of that name`);
          continue;
        }
        if (onHelp.some((v) => v.field === field)) {
          this.refuse(e.stmt, `a second ON HELP-REQUEST for ${field} - a select-option has one F1 for LOW and HIGH here`);
          continue;
        }
        this.map(e.stmt, `\`at_selection_screen_on_help( field )\` - WHEN \`${field}\`, the field declared with help_request (an F1 button either way)`);
        onHelp.push({ field, body: this.convertBody(e.stmts, { method: "at_selection_screen_on_help" }) });
      } else if ((m = /ON\s+([\w/]+)$/.exec(t))) {
        const field = m[1];
        if (!this.screenField(field)) {
          this.refuse(e.stmt, `ON ${field} - no parameter or select-option of that name`);
          continue;
        }
        this.map(e.stmt, `\`at_selection_screen_on( field )\` - WHEN \`${field}\``);
        onField.push({ field, body: this.convertBody(e.stmts, { method: "at_selection_screen_on" }) });
      }
    }
    if (onField.length) {
      methods.push({ name: "at_selection_screen_on", body: caseBody("field", onField) });
    }
    if (onBlock.length) methods.push({ name: "at_selection_screen_on_block", body: caseBody("block", onBlock) });
    if (onRadio.length) methods.push({ name: "at_selection_screen_on_radio", body: caseBody("group", onRadio) });
    if (onEndOf.length) methods.push({ name: "at_selection_screen_on_end_of", body: caseBody("field", onEndOf) });
    if (onExit.length) methods.push({ name: "at_selection_screen_on_exit", body: onExit });
    if (onHelp.length) {
      const body = ["CASE field."];
      for (const v of onHelp) body.push(`  WHEN ${literal(v.field)}.`, ...v.body.map((l) => indent(l, 4)));
      body.push("  WHEN OTHERS.", "    super->at_selection_screen_on_help( field ).", "ENDCASE.");
      methods.push({ name: "at_selection_screen_on_help", body });
    }

    // AT SELECTION-SCREEN
    const ass = byKind("AtSelectionScreen", (e) => /^AT\s+SELECTION-SCREEN$/.test(assText(e)));
    if (ass.length) {
      const body = [];
      for (const e of ass) {
        this.map(e.stmt, this.assUcomm
          ? "`at_selection_screen( )` and `at_user_command( )` - both call `at_selection_screen_ucomm( ucomm )`, sy-ucomm becomes ucomm"
          : "`at_selection_screen( )`");
        body.push(...this.convertBody(e.stmts, { method: "at_selection_screen", ucomm: this.assUcomm }));
      }
      if (this.assUcomm) {
        this.methodDefs.push({ name: "at_selection_screen_ucomm", lines: ["    METHODS at_selection_screen_ucomm", "      IMPORTING", "        ucomm TYPE string."] });
        methods.push({ name: "at_selection_screen", body: ["\" F8 - the classic sy-ucomm of Execute", "at_selection_screen_ucomm( `ONLI` )."] });
        this.privateMethods = [...(this.privateMethods ?? []), { name: "at_selection_screen_ucomm", body }];
      } else {
        methods.push({ name: "at_selection_screen", body });
      }
    }

    // TOP-OF-PAGE, TOP-OF-PAGE DURING LINE-SELECTION, END-OF-PAGE: the
    // runtime records what the event writes once - the header when the list
    // gets its first line, the footer after END-OF-SELECTION - and repeats
    // it on every page (NEW-PAGE, LINE-COUNT), &PAGE& the page number. So
    // only a fixed header or footer is converted
    const output = new Set(["Write", "Uline", "Skip", "NewLine", "Format", "Comment"]);
    const pageEvent = (e, what, method) => {
      const bad = e.stmts.find((s) => !output.has(kind(s)));
      if (bad) {
        this.refuse(bad, `${what} with other statements than WRITE, ULINE, SKIP, NEW-LINE and FORMAT - the runtime writes the ${method === "end_of_page" ? "footer" : "header"} once and repeats it on every page; only a fixed one is converted`);
        return false;
      }
      const varying = e.stmts.some((s) => kind(s) === "Write" && findAll(s, "Source").some((src) => {
        const t = lc(nodeText(src));
        return !/^('|`|text-|sy-(pagno|datum|uzeit|title|uname|repid|cprog|sysid|mandt|langu)$)/.test(t) && !/^\d+$/.test(t);
      }));
      if (varying) this.todo(e.stmt, `${what}: the ${method === "end_of_page" ? "footer" : "header"} is written once and repeated on every page - a field in it keeps the value of that moment on every page`);
      return true;
    };
    {
      const top = byKind("TopOfPage", (e) => !/DURING/.test(assText(e)));
      if (top.length && pageEvent(top[0], "TOP-OF-PAGE", "top_of_page")) {
        this.map(top[0].stmt, "`top_of_page( )` - the header the runtime writes above the list and repeats on every page");
        methods.push({ name: "top_of_page", body: this.convertBody(top[0].stmts, { method: "top_of_page", page: true }) });
      }
      for (const more of top.slice(1)) this.refuse(more.stmt, "a second TOP-OF-PAGE");
      const during = byKind("TopOfPage", (e) => /DURING/.test(assText(e)));
      if (during.length && pageEvent(during[0], "TOP-OF-PAGE DURING LINE-SELECTION", "top_of_page_line_selection")) {
        this.map(during[0].stmt, "`top_of_page_line_selection( )` - the header of every secondary list");
        methods.push({ name: "top_of_page_line_selection", body: this.convertBody(during[0].stmts, { method: "top_of_page_line_selection", page: true }) });
      }
      for (const more of during.slice(1)) this.refuse(more.stmt, "a second TOP-OF-PAGE DURING LINE-SELECTION");
      const eop = byKind("EndOfPage");
      if (eop.length && !this.lineCount?.footer) {
        // the classic event ran only when LINE-COUNT n(m) reserved m lines
        for (const x of [eop[0].stmt, ...eop[0].stmts]) this.map(x, "dropped - END-OF-PAGE without footer lines in LINE-COUNT");
        this.todo(eop[0].stmt, "END-OF-PAGE dropped - REPORT reserves no footer lines (LINE-COUNT n(m)), so the classic event never ran; redefine end_of_page( ) for a footer on every page");
      } else if (eop.length && pageEvent(eop[0], "END-OF-PAGE", "end_of_page")) {
        this.map(eop[0].stmt, "`end_of_page( )` - the footer the runtime writes at the end of every page");
        this.todo(eop[0].stmt, "END-OF-PAGE: the runtime ends every page with the footer, the last one too - the classic event ran only when a page was full");
        methods.push({ name: "end_of_page", body: this.convertBody(eop[0].stmts, { method: "end_of_page", page: true }) });
      }
      for (const more of eop.slice(1)) this.refuse(more.stmt, "a second END-OF-PAGE");
    }

    // START-OF-SELECTION + END-OF-SELECTION - the runtime runs
    // end_of_selection( ) after start_of_selection( ), also after its RETURN
    // (or STOP), unless an error message stopped the run
    {
      const body = [];
      const sos = byKind("StartOfSelection");
      if (sos.length || byKind("EndOfSelection").length) body.push(...this.resetGlobals());
      for (const e of sos) {
        if (e.fromInit) this.map(e.stmt, "`start_of_selection( )` - the report has no selection screen: INITIALIZATION went straight on with START-OF-SELECTION");
        else if (!e.implicit) this.map(e.stmt, "`start_of_selection( )`");
        else this.map(e.stmt, "`start_of_selection( )` - statements before the first event block");
        if (body.length) body.push("");
        body.push(...this.convertBody(e.stmts, { method: "start_of_selection" }));
      }
      if (body.length) methods.push({ name: "start_of_selection", body });
      const eos = [];
      for (const e of byKind("EndOfSelection")) {
        this.map(e.stmt, "`end_of_selection( )` - the runtime runs it after `start_of_selection( )`, after its RETURN too");
        if (eos.length) eos.push("");
        eos.push(...this.convertBody(e.stmts, { method: "end_of_selection" }));
      }
      if (eos.length) methods.push({ name: "end_of_selection", body: eos });
    }

    // AT LINE-SELECTION: HIDE restored first, the ALV double click callback
    {
      const evs = byKind("AtLineSelection");
      const callback = this.forms.find((f) => this.alvCallbacks.get(f.name)?.kind === "user_command");
      const dbl = this.gridHandlers.filter((h) => h.event === "double_click");
      if (evs.length || callback || dbl.length) {
        const body = [];
        const deferred = () => this.hideRestore();
        for (const e of evs) {
          this.map(e.stmt, "`at_line_selection( row hide )` - HIDE fields restored from `hide`");
          body.push(...this.convertBody(e.stmts, { method: "at_line_selection", lineSelection: true }));
        }
        if (callback) {
          body.push(...this.alvCallbackBody(callback));
        }
        for (const h of dbl) {
          this.map(h.stmt, "`at_line_selection( row hide )` - the DOUBLE_CLICK handler of the grid, e_row-index is row");
          if (body.length) body.push("");
          body.push(...this.gridHandlerBody(h, { method: "at_line_selection", lineSelection: true }, [
            [/\b(e_row|e_row_id)\s*-\s*index\b/gi, "row"], [/\bes_row_no\s*-\s*row_id\b/gi, "row"],
          ]));
        }
        methods.push({ name: "at_line_selection", body, prelude: deferred });
      }
      const hot = this.gridHandlers.filter((h) => h.event === "hotspot_click");
      if (hot.length) {
        const body = [];
        for (const h of hot) {
          this.map(h.stmt, "`at_link_click( row column )` - the HOTSPOT_CLICK handler of the grid, e_row_id-index is row, e_column_id-fieldname column");
          if (body.length) body.push("");
          body.push(...this.gridHandlerBody(h, { method: "at_link_click", lineSelection: true }, [
            [/\b(e_row_id|e_row)\s*-\s*index\b/gi, "row"], [/\bes_row_no\s*-\s*row_id\b/gi, "row"],
            [/\b(e_column_id|e_column)\s*-\s*fieldname\b/gi, "column"],
          ]));
        }
        methods.push({ name: "at_link_click", body });
      }
      for (const h of this.gridHandlers) {
        if (!["double_click", "hotspot_click", "toolbar", "user_command"].includes(h.event)) {
          this.refuse(h.stmt, h.event === "data_changed" || h.event === "data_changed_finished"
            ? `the ${uc(h.event)} handler of the grid - an edited cell arrives in at_data_changed( row column ); port the handler by hand`
            : `the ${uc(h.event)} handler of the grid - no counterpart in alv( )`);
        } else if (h.event === "toolbar") {
          this.map(h.stmt, "`add_function( )` in the alv( ) chain - the buttons of the TOOLBAR handler; they arrive in `at_user_command( )`");
        }
      }
    }

    // AT USER-COMMAND
    {
      const evs = byKind("AtUserCommand");
      const ucommHandlers = this.gridHandlers.filter((h) => h.event === "user_command");
      if (evs.length || this.assUcomm || ucommHandlers.length) {
        const body = [];
        if (this.assUcomm) body.push("\" a button or USER-COMMAND of the selection screen - the classic AT SELECTION-SCREEN", "at_selection_screen_ucomm( ucomm ).");
        for (const e of evs) {
          if (!e.pai) this.map(e.stmt, "`at_user_command( ucomm )` - sy-ucomm becomes ucomm");
          if (this.assUcomm) this.todo(e.stmt, "AT USER-COMMAND and the user commands of the selection screen both arrive in at_user_command( ) - check that the codes do not overlap");
          if (body.length) body.push("");
          if (e.pai) body.push("\" the PAI module of the screen - the OK code is ucomm");
          body.push(...this.convertBody(e.stmts, { method: "at_user_command", userCommand: true, pai: e.pai }));
        }
        for (const h of ucommHandlers) {
          this.map(h.stmt, "`at_user_command( ucomm )` - the USER_COMMAND handler of the grid, e_ucomm is ucomm");
          if (body.length) body.push("");
          body.push(...this.gridHandlerBody(h, { method: "at_user_command", userCommand: true }, [[/\be_ucomm\b/gi, "ucomm"]]));
        }
        methods.push({ name: "at_user_command", body });
      }
    }

    // AT PFnn: the function key of the standard list status - a WHEN of
    // at_user_command( ), the key a shortcut and a button of the toolbar
    {
      const evs = byKind("AtPF");
      if (evs.length) {
        const entries = [];
        for (const e of evs) {
          const code = uc(assText(e).replace(/^AT\s+/, ""));
          const nr = Number(code.slice(2));
          const key = functionKey(nr);
          if (!key || entries.some((x) => x.field === code)) {
            this.refuse(e.stmt, `AT ${code} - ${key ? "a second block for the key" : "no function key of that number"}`);
            continue;
          }
          this.map(e.stmt, `\`at_user_command( ucomm )\` - WHEN \`${code}\`, the key ${key} a shortcut and a button`);
          entries.push({ field: code, key, body: this.convertBody(e.stmts, { method: "at_user_command", userCommand: true }) });
        }
        if (entries.length) {
          const body = ["\" AT PFnn - the function keys of the list", ...caseBody("ucomm", entries)];
          const existing = methods.find((m) => m.name === "at_user_command");
          if (existing) existing.body.push("", ...body);
          else methods.push({ name: "at_user_command", body });
          this.atPf = entries;
        }
      }
    }

    // AT SELECTION-SCREEN ON VALUE-REQUEST
    if (valueRequest.length) {
      const body = ["CASE field."];
      for (const v of valueRequest) {
        body.push(`  WHEN ${literal(v.field)}.`);
        if (v.parts.low && v.parts.high) {
          body.push("    IF value_request_part( ) = z2ui5_cl_cgui_selscreen=>cs_part-high.", ...v.parts.high.map((l) => indent(l, 6)),
            "    ELSE.", ...v.parts.low.map((l) => indent(l, 6)), "    ENDIF.");
        } else {
          body.push(...(v.parts.low ?? v.parts.high).map((l) => indent(l, 4)));
        }
      }
      body.push("  WHEN OTHERS.", "    super->at_value_request( field ).", "ENDCASE.");
      methods.push({ name: "at_value_request", body });
    }

    // FORMs
    const formMethods = [];
    for (const f of this.forms) {
      if (this.alvCallbacks.has(f.name)) {
        const cb = this.alvCallbacks.get(f.name);
        if (cb.kind !== "user_command") {
          this.todo(f.stmt, `FORM ${f.name} is the ${uc(cb.kind)} callback of the ALV - no counterpart, not converted`);
        }
        continue;
      }
      if (this.emptyForms.has(f.name)) {
        for (const x of f.body) this.statement(x, { out: [], ctx: { method: f.method }, line: [], loopDepth: 0, screenLoopDepth: -1 });
        this.map(f.stmt, "dropped - the FORM only set up the ALV, which the alv( ) chain does now");
        continue;
      }
      this.map(f.stmt, f.module
        ? `private method \`${f.method}( )\` - the module, called by ${f.module.io === "OUTPUT" ? "dynpro_pbo( )" : "dynpro_pai( )"} as the flow logic of the screen did`
        : `private method \`${f.method}( )\``);
      formMethods.push({ name: f.method, body: this.convertBody(f.body, { method: f.method, form: f, screenEvent: this.screenForms().has(f.name), ucommVar: f.okcode }) });
    }
    // AT PFnn without a status of the report's own: the keys on the toolbar
    // of the standard list status. With a SET PF-STATUS the report's status
    // decides - PFnn arrives only when it has the key
    if (this.atPf?.length) {
      const sets = this.stmts.some((x) => kind(x) === "SetPFStatus");
      if (sets) {
        this.todo(this.atPf.length ? byKind("AtPF")[0].stmt : undefined, "AT PFnn with SET PF-STATUS: the status of the report replaces the standard list status - AT PFnn ran only for the keys the status leaves as PFnn; check that the status has them");
      } else {
        const call = renderTableCall("set_pf_status", [
          { name: "functions", lines: this.atPf.map((e) => `( name = ${literal(e.field)} text = ${literal(e.key)} )`) },
          { name: "shortcuts", lines: this.atPf.map((e) => `( key = ${literal(e.key)} ucomm = ${literal(e.field)} )`) },
        ]);
        const init = methods.find((m) => m.name === "initialization");
        const lines = ["\" AT PFnn - the function keys of the standard list status", call];
        if (init) init.body.unshift(...lines, "");
        else methods.push({ name: "initialization", body: lines });
      }
    }

    if (this.dynpro) methods.push(...this.dynproMethods());

    // the continuations - a continuation may hold a call that cuts again
    if (this.continuations.length) {
      const dynnr = [];
      const ucomm = [];
      const screen = [];
      while (this.continuations.length) {
        const c = this.continuations.shift();
        ({ at_user_command: ucomm, after_call_screen: screen }[c.method] ?? dynnr).push({ field: c.field, body: this.convertBody(c.stmts, c.ctx) });
      }
      if (dynnr.length) methods.push({ name: "after_call_selection_screen", body: caseBody("dynnr", dynnr) });
      if (screen.length) methods.push({ name: "after_call_screen", body: caseBody("dynnr", screen) });
      if (ucomm.length) {
        const body = ["\" the answers of the popups - the statements after the CALL FUNCTION", ...caseBody("ucomm", ucomm)];
        const existing = methods.find((m) => m.name === "at_user_command");
        if (existing) existing.body.push("", ...body);
        else methods.push({ name: "at_user_command", body });
      }
    }
    // the local classes - their methods may PERFORM a FORM as well
    const locals = this.localsSource();
    // the handlers of the controls are methods of local classes: the event
    // of a control hands them the instance like every event method
    if (locals.app && [...this.guiHandlers().values()].flat().some((h) => guiClass(h.of))) methods.push({ name: "at_gui_event", body: [] });
    for (const f of this.forms) {
      if (!this.alvCallbacks.has(f.name) && !this.emptyForms.has(f.name) && !f.performed) this.todo(f.stmt, `FORM ${f.name} is not PERFORMed in this report - the private method ${f.method}( ) is unused (abaplint unused_methods)`);
    }

    // the selection screen takes its value helps from the screen pass above
    const restore = methods.find((m) => m.prelude);
    if (restore) {
      const pre = restore.prelude();
      if (pre.length) restore.body.unshift(...pre, "");
    }

    for (const m of methods) this.redefined.add(m.name);

    // ------------------------------------------------------------ class text
    const lines = [];
    lines.push(`CLASS ${cls} DEFINITION PUBLIC`);
    lines.push("  INHERITING FROM z2ui5_cl_cgui_report");
    lines.push("  FINAL");
    lines.push("  CREATE PUBLIC.");
    lines.push("");
    lines.push("  PUBLIC SECTION.");
    lines.push(...pub.map((l) => indent(l, 4)));
    lines.push("");
    lines.push("  PROTECTED SECTION.");
    const order = ["initialization", "selection_screen", "selection_screen_dynnr", "at_selection_screen_output", "at_selection_screen_on",
      "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_on_end_of",
      "at_selection_screen_on_exit", "at_selection_screen_on_help", "at_selection_screen", "start_of_selection", "end_of_selection", "top_of_page",
      "top_of_page_line_selection", "end_of_page", "at_line_selection", "at_link_click", "at_user_command", "at_value_request",
      "after_call_selection_screen", "dynpro_screen", "dynpro_pbo", "dynpro_pai", "at_gui_event", "after_call_screen"];
    methods.sort((a, b) => order.indexOf(a.name) - order.indexOf(b.name));
    for (const m of methods) lines.push(`    METHODS ${m.name} REDEFINITION.`);
    lines.push("");
    lines.push("  PRIVATE SECTION.");
    if (this.privateDataLines.length) {
      lines.push("    \" global data of the report typed with its local classes - local types", "    \" can type the private section only", ...this.privateDataLines.map((l) => indent(l, 4)), "");
    }
    for (const t of this.tablesTypes.values()) lines.push(`    ${t}`);
    if (this.tablesTypes.size && this.methodDefs.length) lines.push("");
    this.methodDefs.forEach((d, i) => {
      if (i > 0) lines.push("");
      lines.push(...d.lines);
    });
    lines.push("ENDCLASS.");
    lines.push("");
    lines.push("");
    lines.push(`CLASS ${cls} IMPLEMENTATION.`);
    const impl = [...methods, ...(this.privateMethods ?? []), ...formMethods];
    for (const m of impl) {
      lines.push("");
      lines.push(`  METHOD ${m.name}.`);
      lines.push("");
      const was = [...(this.methodWa.get(m.name) ?? new Map())].map(([tab, wa]) => `DATA ${wa} LIKE LINE OF ${tab}.`);
      // the local classes reach the report through the instance of the event
      const app = locals.app && methods.includes(m) ? [`${this.appRef} = me.`] : [];
      const globalFs = [...was, ...(this.prelude.get(m.name) ?? []), ...this.fieldSymbolDecls(m.body), ...app];
      for (const l of [...globalFs, ...(globalFs.length ? [""] : []), ...trimBlank(dropEmptyIfs(m.body))]) lines.push(indent(l, 4));
      lines.push("");
      lines.push("  ENDMETHOD.");
    }
    lines.push("");
    lines.push("ENDCLASS.");

    let abap = normalizeAbap(this.reindent(lines.join("\n"), `${cls}.clas.abap`));
    const files = { [`${cls}.clas.abap`]: abap };

    // local classes and interfaces - indented as the house style does, the
    // converted method bodies with them
    if (locals.def) files[`${cls}.clas.locals_def.abap`] = normalizeAbap(this.reindent(locals.def, "zr2c_locals_def.prog.abap"));
    if (locals.imp) files[`${cls}.clas.locals_imp.abap`] = normalizeAbap(this.reindent(locals.imp, "zr2c_locals_imp.prog.abap"));

    files[`${cls}.clas.xml`] = classXml(cls, this.pool.title || `report2cloud - ${this.programName}`);

    for (const [name, text] of Object.entries(files)) {
      for (const l of longLines(text)) {
        this.todos.push({ row: 0, col: 0, file: name, message: `${name}:${l.row} is ${l.length} characters long - abapGit imports at most 255; split the line` });
      }
    }

    const release = this.releaseTodos(files);
    return {
      className: cls,
      programName: this.programName,
      file: this.file,
      files: this.refusals.length ? {} : files,
      draft: files,
      refusals: this.refusals.sort((a, b) => a.row - b.row || a.col - b.col),
      mapped: this.mapped.sort((a, b) => a.row - b.row || a.col - b.col),
      todos: this.todos.filter((t, i, all) => all.findIndex((x) => x.row === t.row && x.col === t.col && x.message === t.message) === i)
        .sort((a, b) => a.row - b.row || a.col - b.col),
      release,
      notes: [...this.notes.entries()].map(([text, count]) => ({ text, count })),
      ok: this.refusals.length === 0,
    };
  }

  screenField(name) {
    return this.screenFields?.has(lc(name));
  }

  // ----------------------------------------------------------- declarations

  /** the PUBLIC SECTION lines, the chain of selection_screen( ) and the
   *  defaults initialization( ) sets */
  declarations(pub) {
    let chain = [];         // { method, params: [{ name, value }], positional }
    const mainChain = chain;
    // SELECTION-SCREEN BEGIN OF SCREEN nnnn: the fields between BEGIN and
    // END are the chain of selection_screen_dynnr( ) for that number
    this.dynnrScreens = new Map();
    this.subscreens = new Map();
    const defaults = [];
    const radioGroups = new Map();
    this.radioGroups = radioGroups;
    this.selectOptions = new Set();
    const fieldTexts = [];
    this.screenFields = new Set();
    // three groups, in this order: what a declaration may refer to comes first
    const sections = { types: [], data: [], screen: [] };
    // the types moved to locals_def and the globals typed with local types
    this.localTypeLines = [];
    this.privateDataLines = [];
    let target = sections.data;
    let sticky;                  // a BEGIN OF ... END OF run going elsewhere
    let stickyDepth = 0;
    const heading = (h) => {
      target = h === "selection screen" ? sections.screen : /types|constants/.test(h) ? sections.types : sections.data;
    };
    const destOf = (s, names) => {
      if (sticky) return sticky;
      if (["Type", "TypeBegin", "Constant", "ConstantBegin", "TypeEnum", "TypeEnumBegin"].includes(kind(s)) && names.some((n) => this.movedTypes.has(n))) return this.localTypeLines;
      if (["Data", "DataBegin"].includes(kind(s)) && names.some((n) => this.privateGlobals.has(n))) return this.privateDataLines;
      return undefined;
    };
    const push = (line) => target.push(line);
    for (let i = 0; i < this.decls.length; i++) {
      const s = this.decls[i];
      const k = kind(s);
      const w = words(s);

      if ((k === "Parameter" || k === "SelectOption") && (child(s, "Dynamic") || /\b(TYPE|FOR)\s*\(/i.test(renderTokens(stmtTokens(s))))) {
        this.refuse(s, `${uc(declName(s) ?? "")} is typed at runtime (TYPE (name) / FOR (name)) - a field of the selection screen is an attribute of the class, typed when the class is written; give it its type`);
        continue;
      }
      if (k === "Parameter") {
        const name = lc(nodeText(child(s, "FieldSub")));
        this.screenFields.add(name);
        const checkbox = hasSeq(w, "AS", "CHECKBOX");
        const radio = w.includes("RADIOBUTTON");
        const ucomm = this.userCommand(s);
        const modif = child(s, "Modif");
        const noDisplay = hasSeq(w, "NO", "-", "DISPLAY");
        const params = [{ name: "val", value: name }];
        const text = this.labelText(name, this.selectionText(name, s, fieldTexts));
        if (text) params.push({ name: "text", value: text });
        let method = "parameter";
        if (checkbox && !noDisplay) method = "checkbox";
        if (radio) {
          method = "radiobutton";
          const group = uc(nodeText(child(s, "RadioGroupName")));
          params.push({ name: "group", value: literal(group) });
          if (!radioGroups.has(group)) radioGroups.set(group, { first: name, defaulted: false, stmt: s });
        }
        const listbox = hasSeq(w, "AS", "LISTBOX");
        if (w.includes("OBLIGATORY") && method === "parameter") params.push({ name: "obligatory", value: "abap_true" });
        if (this.valueRequest.has(name) && method === "parameter") params.push({ name: "value_help", value: "abap_true" });
        if (this.helpRequest.has(name) && method === "parameter") params.push({ name: "help_request", value: "abap_true" });
        if (modif) params.push({ name: "modif_id", value: literal(uc(nodeText(modif))) });
        if (listbox && method === "parameter") params.push({ name: "as_listbox", value: "abap_true" });
        if (ucomm && (method !== "parameter" || listbox)) params.push({ name: "user_command", value: literal(ucomm) });
        if (noDisplay) params.push({ name: "no_display", value: "abap_true" });
        if (method === "parameter") {
          this.fieldOptions(s, w, params);
          if (hasSeq(w, "VALUE", "CHECK")) params.push({ name: "value_check", value: "abap_true" });
        }
        chain.push({ method, params });

        heading("selection screen");
        const type = checkbox || radio ? "TYPE abap_bool" : this.parameterType(s);
        push(`DATA ${name} ${type}.`);

        const def = after(s, "DEFAULT");
        if (def) {
          let value = nodeText(def, this.rewrites(s, {}));
          if (checkbox || radio) {
            if (/^'X'$|^`X`$/i.test(value)) value = "abap_true";
            else value = undefined;
            if (radio && value) radioGroups.get(uc(nodeText(child(s, "RadioGroupName")))).defaulted = true;
          } else if (/^(space|' '|``|'')$/i.test(value)) value = undefined;
          if (value) defaults.push(`${name} = ${value}.`);
        }

        const parts = [`attribute \`${name}\``, `\`screen->${method}( )\``];
        if (w.includes("MATCHCODE")) this.todo(s, `MATCHCODE OBJECT of ${uc(name)}: the runtime reads the search help through the DDIC on premise - on ABAP Cloud there is none; answer F4 in at_value_request( ) with value_help_popup( ) there`);
        this.map(s, parts.join(", "));
        continue;
      }

      if (k === "SelectOption") {
        const name = lc(nodeText(child(s, "FieldSub")));
        this.screenFields.add(name);
        this.selectOptions.add(name);
        const forNode = after(s, "FOR");
        const forText = lc(nodeText(forNode));
        const params = [{ name: "val", value: name }];
        const text = this.labelText(name, this.selectionText(name, s, fieldTexts));
        if (text) params.push({ name: "text", value: text });
        if (w.includes("OBLIGATORY")) params.push({ name: "obligatory", value: "abap_true" });
        if (this.valueRequest.has(name)) params.push({ name: "value_help", value: "abap_true" });
        if (this.helpRequest.has(name)) params.push({ name: "help_request", value: "abap_true" });
        const modif = child(s, "Modif");
        if (modif) params.push({ name: "modif_id", value: literal(uc(nodeText(modif))) });
        if (hasSeq(w, "NO", "-", "DISPLAY")) params.push({ name: "no_display", value: "abap_true" });
        if (hasSeq(w, "NO", "INTERVALS")) params.push({ name: "no_intervals", value: "abap_true" });
        if (hasSeq(w, "NO", "-", "EXTENSION")) params.push({ name: "no_extension", value: "abap_true" });
        this.fieldOptions(s, w, params);
        chain.push({ method: "select_option", params });

        heading("selection screen");
        let forType = forText;
        // FOR <fs>-comp: the type the field symbol is declared with - an
        // attribute cannot be typed with a field symbol
        const fs = /^(<[\w/]+>)(.*)$/.exec(forText);
        if (fs) {
          const decl = (this.globalFieldSymbols ?? []).find((x) => lc(declName(x) ?? "") === fs[1]);
          const m = decl && /\b(TYPE|LIKE)\s+(?:REF\s+TO\s+)?([\w/~=>-]+)/i.exec(renderTokens(stmtTokens(decl)));
          if (m) forType = `${lc(m[2])}${fs[2]}`;
        }
        const root = forType.split("-")[0];
        const like = this.globalData.has(root) && (!this.isTables(root) || this.tablesKept.has(root));
        push(`DATA ${name} ${like ? "LIKE" : "TYPE"} RANGE OF ${forType}.`);

        const defNode = after(s, "DEFAULT");
        if (defNode) {
          const ov = this.rewrites(s, {});
          const low = nodeText(defNode, ov);
          const toNode = after(s, "TO");
          const high = toNode ? nodeText(toNode, ov) : undefined;
          const optIdx = w.indexOf("OPTION");
          const signIdx = w.indexOf("SIGN");
          const tokensAfter = (word) => {
            const ch = s.getChildren();
            const at = ch.findIndex((c) => isToken(c) && uc(c.get().getStr()) === word);
            return at >= 0 ? uc(ch[at + 1].getFirstToken().getStr()) : undefined;
          };
          const option = optIdx >= 0 ? tokensAfter("OPTION") : (high ? "BT" : "EQ");
          const sign = signIdx >= 0 ? tokensAfter("SIGN") : "I";
          defaults.push(`${name} = VALUE #( ( sign = ${literal(sign)} option = ${literal(option)} low = ${low}${high ? ` high = ${high}` : ""} ) ).`);
        }
        if (w.includes("MATCHCODE")) this.todo(s, `MATCHCODE OBJECT of ${uc(name)}: the runtime reads the search help through the DDIC on premise - on ABAP Cloud there is none; answer F4 in at_value_request( ) there`);
        this.map(s, `range attribute \`${name}\`, \`screen->select_option( )\``);
        continue;
      }

      if (k === "SelectionScreen" && hasSeq(w, "BEGIN", "OF", "SCREEN")) {
        const nr = nodeText(child(s, "Integer")).padStart(4, "0");
        let title;
        if (w.includes("TITLE")) {
          const te = child(s, "TextElement");
          const inline = child(s, "InlineField");
          if (te) title = this.textSymbol(nodeText(child(te, "TextElementKey")), undefined, s);
          else if (inline) {
            title = lc(nodeText(inline));
            heading("selection screen");
            push(`DATA ${title} TYPE string.`);
          }
        }
        const d = { nr, title, chain: [], stmt: s, subscreen: w.includes("SUBSCREEN") };
        if (d.subscreen) this.subscreens.set(nr, d);
        else this.dynnrScreens.set(nr, d);
        chain = d.chain;
        this.map(s, d.subscreen
          ? `the fields of subscreen ${nr} - on the tab that names it as DEFAULT SCREEN`
          : `\`selection_screen_dynnr( dynnr screen )\` - WHEN \`${nr}\`${w.includes("WINDOW") ? "" : ", shown as a dialog like AS WINDOW"}`);
        continue;
      }
      if (k === "SelectionScreen" && hasSeq(w, "END", "OF", "SCREEN")) {
        chain = mainChain;
        this.map(s, "`selection_screen_dynnr( )`");
        continue;
      }
      if (k === "SelectionScreen") {
        this.selectionScreen(s, chain, push, heading);
        continue;
      }

      if (k === "Tables") {
        const name = lc(declName(s));
        if (name === "sscrfields") {
          this.map(s, this.assUcomm ? "dropped - sscrfields-ucomm is the ucomm of at_selection_screen_ucomm( )" : "dropped");
          continue;
        }
        if (this.tablesKept.has(name)) {
          this.resetCandidate(s);
          heading("global data of the report");
          push(`DATA ${name} TYPE ${name}.`);
          this.map(s, `typed work area \`DATA ${name} TYPE ${name}\``);
          this.todo(s, `TABLES ${name} is now a work area of type ${uc(name)} - on ABAP Cloud the table must be replaced by a released CDS view (see the release TODOs)`);
        } else {
          this.map(s, "dropped - it only typed the select-options and parameters, which now refer to the DDIC type");
        }
        continue;
      }

      if (k === "TypePools" || k === "TypePool") {
        this.map(s, "dropped - type pools load by themselves");
        continue;
      }

      if (k === "FieldSymbol") {
        // a global field-symbol is declared in every method that uses it
        this.globalFieldSymbols = [...(this.globalFieldSymbols ?? []), s];
        this.map(s, "declared in each method that uses it");
        continue;
      }

      if (REFUSED[k]) {
        this.refuse(s, REFUSED[k]);
        continue;
      }

      if (k === "Data" || k === "DataBegin" || k === "DataEnd" || k === "Type" || k === "TypeBegin" || k === "TypeEnd"
        || k === "Constant" || k === "ConstantBegin" || k === "ConstantEnd" || k === "IncludeType" || k === "Ranges"
        || k === "TypeEnum" || k === "TypeEnumBegin" || k === "TypeEnumEnd") {
        const isType = /^Type/.test(k) || k === "IncludeType";
        const isConst = /^Constant/.test(k);
        const name = lc(declName(s) ?? "");
        if ((k === "Data") && (this.salvVars.has(name) || this.fcatVars.has(name) || this.layoutVars.has(name)) && !this.insideBegin(s)) {
          this.map(s, "dropped - the ALV object, field catalog or layout is the alv( ) chain now");
          continue;
        }
        if (k === "Data" && this.fkeyVars?.has(name)) {
          this.map(s, "dropped - the text of a function key is function_key( ) in selection_screen( )");
          continue;
        }
        if (k === "Data" && (this.isGridObject(name) || this.okDropped?.has(name))) {
          this.map(s, "dropped - the grid, its container and the handler object are the alv( ) chain now");
          continue;
        }
        if (k === "Data" && this.guiRefusal(renderTokens(stmtTokens(s)))) {
          this.refuse(s, this.guiRefusal(renderTokens(stmtTokens(s))));
          continue;
        }
        heading(isType ? "types of the report" : isConst ? "constants of the report" : "global data of the report");
        // a type moved to locals_def, a global typed with a local type
        {
          const names = [lc(declName(s) ?? "")];
          if (s.getColon()) for (let j = i + 1; this.decls[j] && sameColon(this.decls[j], s); j++) names.push(lc(declName(this.decls[j]) ?? ""));
          const dest = destOf(s, names);
          let counted = false;
          if (dest) {
            target = dest;
            if (!sticky && /Begin$/.test(k) && !s.getColon()) {
              sticky = dest;
              stickyDepth = 0;
            } else if (!sticky && /Begin$/.test(k)) {
              // TYPES: BEGIN OF x. INCLUDE STRUCTURE y. TYPES: END OF x. - the
              // chain ends before its END OF: the run goes on after it
              let depth = 0;
              for (let j = i; this.decls[j] && (j === i || sameColon(this.decls[j], s)); j++) {
                if (/Begin$/.test(kind(this.decls[j]))) depth++;
                if (/End$/.test(kind(this.decls[j]))) depth--;
              }
              if (depth > 0) {
                sticky = dest;
                stickyDepth = depth;
                counted = true;
              }
            }
          }
          if (sticky && !counted) {
            if (/Begin$/.test(k)) stickyDepth++;
            if (/End$/.test(k)) stickyDepth--;
          }
        }
        if ((k === "Data" || k === "DataBegin" || k === "Ranges") && !this.insideBegin(s)) this.resetCandidate(s);
        if (k === "Ranges") {
          const forNode = child(s, "SimpleFieldChain2");
          const forText = lc(nodeText(forNode));
          const root = forText.split("-")[0];
          const like = this.globalData.has(root) && (!this.isTables(root) || this.tablesKept.has(root));
          push(`DATA ${name} ${like ? "LIKE" : "TYPE"} RANGE OF ${forText}.`);
          this.map(s, `\`DATA ${name} ... RANGE OF\``);
          continue;
        }
        if (s.getColon()) {
          const group = [s];
          while (this.decls[i + 1] && sameColon(this.decls[i + 1], s)) group.push(this.decls[++i]);
          for (const g of group.slice(1)) {
            if ((kind(g) === "Data" || kind(g) === "DataBegin") && !this.insideBegin(g)) this.resetCandidate(g);
          }
          const text = this.renderDeclGroup(group);
          if (text) push(text);
        } else {
          push(this.dynproFlag(s, name, this.renderDecl(s)));
        }
        if (sticky && stickyDepth === 0) sticky = undefined;
        continue;
      }

      if (k === "StaticBegin" || k === "StaticEnd" || k === "Static") {
        this.refuse(s, "STATICS outside of a FORM - use DATA");
        continue;
      }
    }

    // radio button groups: the first button is selected unless one has DEFAULT 'X'
    for (const [, g] of radioGroups) {
      if (!g.defaulted) defaults.unshift(`${g.first} = abap_true.`);
    }
    if (fieldTexts.length) {
      this.todos.push({ row: 0, col: 0, message: `no selection text in the text pool for ${fieldTexts.join(", ")} - the label is the DDIC label of the type or the field name; pass the .prog.xml (--texts) or set text = in selection_screen( )` });
    }

    // the inline declarations of the event blocks that other blocks read
    for (const [name, h] of this.hoisted ?? []) {
      const local = [...this.localNames].some((n) => new RegExp(`\\b${n}\\b`, "i").test(h.decl));
      if (local) this.privateDataLines.push(h.decl);
      else {
        if (!sections.data.length || !sections.data.some((l) => /^"/.test(l))) { /* the heading is added below */ }
        sections.data.push(h.decl);
      }
      this.map(h.stmt, `the inline declaration of ${name} - an attribute of the class (event blocks open no scope), assigned here`);
    }
    for (const list of Object.values(sections)) alignData(list);
    const blocks = [["types and constants of the report", sections.types], ["global data of the report", sections.data],
      ["selection screen", sections.screen]];
    for (const [title, list] of blocks) {
      if (!list.length) continue;
      if (pub.length) pub.push("");
      pub.push(`" ${title}`, ...list);
    }
    // the subscreens of the tabs: their fields in place of the tab's placeholder
    const splice = (list) => {
      const out = [];
      for (const c of list) {
        if (!c.subscreen) {
          out.push(c);
          continue;
        }
        const d = this.subscreens.get(c.subscreen);
        if (!d) {
          this.refuse(c.stmt, `SELECTION-SCREEN TAB ... DEFAULT SCREEN ${c.subscreen} - no SELECTION-SCREEN BEGIN OF SCREEN ${c.subscreen} AS SUBSCREEN in the report`);
          continue;
        }
        d.used = true;
        out.push(...splice(d.chain));
      }
      return out;
    };
    const resolved = splice(mainChain);
    for (const d of this.dynnrScreens.values()) d.chain = splice(d.chain);
    for (const [nr, d] of this.subscreens) {
      if (!d.used) this.todo(d.stmt, `subscreen ${nr} is on no tab of the report - SELECTION-SCREEN INCLUDE and CALL SUBSCREEN are not converted; its fields are not on the screen`);
    }
    return { chain: renderScreenChain(resolved), defaults };
  }

  /** a global data object start_of_selection( ) may reset (resetGlobals) -
   *  with its start value; a structure with start values in its components
   *  is left alone */
  resetCandidate(s) {
    this.resetList ??= [];
    const name = lc(declName(s) ?? "");
    if (!name || this.salvVars.has(name) || this.fcatVars.has(name) || this.layoutVars.has(name) || this.isGridObject(name)) return;
    let value;
    const v = kind(s) === "Data" ? findAll(s, "Value")[0] : undefined;
    if (v) {
      const text = renderTokens(v.getTokens().slice(1)).trim();
      if (!/^IS\s+INITIAL$/i.test(text)) value = text;
      if (this.isDynproFlag(name) && /^'X'$/i.test(text)) value = "abap_true";
    }
    if (kind(s) === "DataBegin") {
      const end = this.declEnd(this.stmts.indexOf(s));
      const run = this.stmts.slice(this.stmts.indexOf(s), end + 1);
      if (run.some((x) => words(x).includes("VALUE"))) return;
    }
    this.resetList.push({ name, value, row: s.getFirstToken().getRow() });
    const header = this.globalHeader?.get(name);
    if (header) this.resetList.push({ name: header.wa, row: s.getFirstToken().getRow() });
  }

  /**
   * The lines that start a run of start_of_selection( ) with the global data
   * a classic run started with. The classic report is restarted when its
   * list is left: its global data is initial again (or has its VALUE), the
   * selection screen keeps its input. The class keeps every attribute from
   * one Execute to the next - a total summed up in START-OF-SELECTION grew
   * with every run. So every global data object is reset, except the ones
   * the selection phase uses - INITIALIZATION, LOAD-OF-PROGRAM, every AT
   * SELECTION-SCREEN, an F4, and the FORMs they call: the classic restart
   * ran INITIALIZATION again, and AT SELECTION-SCREEN ran before
   * START-OF-SELECTION in the same run.
   */
  resetGlobals() {
    if (!this.resetList?.length) return [];
    const phase = this.events.filter((e) => ["Initialization", "LoadOfProgram", "AtSelectionScreen"].includes(e.kind))
      .flatMap((e) => e.stmts);
    const used = new Set();
    const seenForms = new Set();
    const visit = (stmts) => {
      for (const s of stmts) {
        for (const t of s.getTokens()) used.add(lc(t.getStr()));
        if (kind(s) !== "Perform") continue;
        const f = this.formByName.get(lc(nodeText(child(s, "FormName") ?? s)));
        if (f && !seenForms.has(f.name)) {
          seenForms.add(f.name);
          visit(f.body);
        }
      }
    };
    visit(phase);
    const reset = this.resetList.filter((r) => !used.has(r.name) && !this.screenField(r.name));
    if (!reset.length) return [];
    const lines = ["\" every run starts with the global data of a fresh start - the classic report restarted after its list"];
    const cleared = reset.filter((r) => r.value === undefined).map((r) => r.name);
    if (cleared.length === 1) lines.push(`CLEAR ${cleared[0]}.`);
    else if (cleared.length) lines.push(`CLEAR: ${cleared.join(`,\n       `)}.`);
    for (const r of reset.filter((x) => x.value !== undefined)) lines.push(`${r.name} = ${r.value}.`);
    this.mapped.push({ row: reset[0].row, col: 1, classic: "global data - the report restarted after its list", target: `\`CLEAR\` of ${reset.length} global data object(s) at the start of \`start_of_selection( )\`` });
    return lines;
  }

  isTables(name) {
    return this.decls.some((s) => kind(s) === "Tables" && lc(declName(s)) === name);
  }

  /** the token after the words seq of a statement: MEMORY ID car -> CAR */
  tokenAfter(s, ...seq) {
    const toks = stmtTokens(s).map((t) => t.getStr());
    for (let i = 0; i + seq.length < toks.length; i++) {
      if (seq.every((w, j) => uc(toks[i + j]) === w)) return toks[i + seq.length];
    }
    return undefined;
  }

  /** the options of PARAMETERS / SELECT-OPTIONS that selscreen takes as they
   *  are: LOWER CASE, MEMORY ID, VISIBLE LENGTH, MATCHCODE OBJECT */
  fieldOptions(s, w, params) {
    if (w.includes("LOWER")) params.push({ name: "lower_case", value: "abap_true" });
    const visible = this.tokenAfter(s, "VISIBLE", "LENGTH");
    if (visible && /^\d+$/.test(visible)) params.push({ name: "visible_length", value: visible });
    const memory = this.tokenAfter(s, "MEMORY", "ID");
    if (memory) params.push({ name: "memory_id", value: literal(uc(memory)) });
    const matchcode = this.tokenAfter(s, "MATCHCODE", "OBJECT");
    if (matchcode) params.push({ name: "matchcode", value: literal(uc(matchcode)) });
  }

  userCommand(s) {
    const ch = s.getChildren();
    for (let i = 0; i < ch.length - 3; i++) {
      if (isToken(ch[i]) && uc(ch[i].get().getStr()) === "USER" && uc(ch[i + 2].getFirstToken().getStr()) === "COMMAND") {
        return uc(ch[i + 3].getFirstToken().getStr());
      }
    }
    return undefined;
  }

  /** the text of a field of the selection screen - the label set at runtime
   *  while it is set (resolveScreenLabels) */
  labelText(name, text) {
    const v = this.screenLabels?.get(lc(name));
    if (!v) return text;
    return text ? `COND string( WHEN ${v} IS NOT INITIAL THEN ${v} ELSE ${text} )` : v;
  }

  selectionText(name, s, missing) {
    const t = this.pool.selection.get(uc(name));
    if (t) return literal(t);
    if (t === null) return undefined;     // from the DDIC
    missing.push(uc(name));
    return undefined;
  }

  textSymbol(keyText, fallback, at) {
    const t = this.pool.symbols.get(uc(keyText));
    if (t !== undefined) return literal(t);
    if (fallback !== undefined) return literal(fallback);
    this.todo(at, `text symbol TEXT-${uc(keyText)} is not in the text pool - the generated literal \`TEXT-${uc(keyText)}\` needs the real text`);
    return literal(`TEXT-${uc(keyText)}`);
  }

  parameterType(s) {
    const len = child(s, "ConstantFieldLength");
    let length = len ? nodeText(child(len, "Integer")) : undefined;
    const ch = s.getChildren();
    let typeWord;
    let typeNode;
    for (let i = 0; i < ch.length; i++) {
      if (isToken(ch[i]) && ["TYPE", "LIKE"].includes(uc(ch[i].get().getStr())) && ch[i + 1] && !isToken(ch[i + 1])) {
        typeWord = uc(ch[i].get().getStr());
        typeNode = ch[i + 1];
        break;
      }
    }
    const dec = after(s, "DECIMALS");
    const decimals = dec ? ` DECIMALS ${nodeText(dec)}` : "";
    if (!typeNode) return `TYPE c LENGTH ${length ?? 1}`;
    // TYPE c LENGTH 10 - the LENGTH right after the type, not VISIBLE LENGTH
    const at = ch.indexOf(typeNode);
    if (!length && ch[at + 1] && isToken(ch[at + 1]) && uc(ch[at + 1].get().getStr()) === "LENGTH" && ch[at + 2]) {
      length = nodeText(ch[at + 2]);
    }
    const t = lc(nodeText(typeNode));
    if (typeWord === "LIKE") {
      const root = t.split("-")[0];
      const like = this.globalData.has(root) && (!this.isTables(root) || this.tablesKept.has(root));
      return `${like ? "LIKE" : "TYPE"} ${t}`;
    }
    if (["c", "n", "x", "p"].includes(t) && length) return `TYPE ${t} LENGTH ${length}${decimals}`;
    if (t === "c" && !length) return "TYPE c LENGTH 1";
    return `TYPE ${t}${decimals}`;
  }

  selectionScreen(s, chain, push, heading) {
    const w = words(s);
    const textOf = (node) => {
      if (!node) return undefined;
      if (kind(node) === "TextElement") return this.textSymbol(nodeText(child(node, "TextElementKey")), undefined, s);
      return undefined;
    };
    const textElement = child(s, "TextElement");
    const inline = child(s, "InlineField");
    // a COMMENT, PUSHBUTTON or block TITLE with a field name instead of a
    // text symbol declares that field - the report sets it in INITIALIZATION.
    // A comment and a push button declare it c LENGTH 83, as the classic
    // does whatever their visible length - a method may take it typed so
    const fieldText = (len) => {
      const name = lc(nodeText(inline));
      heading("selection screen");
      push(`DATA ${name} TYPE ${len ? "c LENGTH 83" : "string"}.`);
      return name;
    };
    const lengthOf = () => {
      const int = child(s, "Integer");
      return int ? nodeText(int) : undefined;
    };
    const modif = child(s, "Modif");

    if (hasSeq(w, "BEGIN", "OF", "BLOCK")) {
      let title;
      if (w.includes("TITLE")) title = textOf(textElement) ?? (inline ? fieldText(undefined) : undefined);
      const blockName = uc(nodeText(child(s, "BlockName")));
      if (this.onBlocks.has(blockName)) {
        chain.push({ method: "block_begin", params: [...(title ? [{ name: "title", value: title }] : []), { name: "name", value: literal(blockName) }] });
      } else {
        chain.push({ method: "block_begin", params: title ? [{ value: title }] : [], positional: true });
      }
      if (hasSeq(w, "NO", "INTERVALS")) {
        const last = chain[chain.length - 1];
        if (last.positional) {
          last.params = last.params.map((p) => ({ name: "title", value: p.value }));
          last.positional = false;
        }
        last.params.push({ name: "no_intervals", value: "abap_true" });
      }
      this.map(s, "`screen->block_begin( )`");
    } else if (hasSeq(w, "END", "OF", "BLOCK") && this.openTabbed?.length && uc(nodeText(child(s, "BlockName"))) === this.openTabbed[this.openTabbed.length - 1]) {
      this.openTabbed.pop();
      chain.push({ method: "tabbed_block_end", params: [] });
      this.map(s, "`screen->tabbed_block_end( )`");
    } else if (hasSeq(w, "END", "OF", "BLOCK")) {
      chain.push({ method: "block_end", params: [] });
      this.map(s, "`screen->block_end( )`");
    } else if (hasSeq(w, "BEGIN", "OF", "LINE")) {
      chain.push({ method: "line_begin", params: [] });
      this.map(s, "`screen->line_begin( )`");
    } else if (hasSeq(w, "END", "OF", "LINE")) {
      chain.push({ method: "line_end", params: [] });
      this.map(s, "`screen->line_end( )`");
    } else if (w.includes("COMMENT")) {
      const text = textOf(textElement) ?? (inline ? fieldText(lengthOf()) : literal(""));
      // the comment that opens a line FOR FIELD is the label of the line
      const prev = chain[chain.length - 1];
      if (hasSeq(w, "FOR", "FIELD") && !modif && prev?.method === "line_begin" && !prev.params.length) {
        prev.params.push({ value: text });
        prev.positional = true;
        this.map(s, "the label of `screen->line_begin( )`");
        return;
      }
      const params = [{ name: "text", value: text }];
      if (modif) params.push({ name: "modif_id", value: literal(uc(nodeText(modif))) });
      chain.push({ method: "comment", params, positional: !modif });
      this.map(s, "`screen->comment( )`");
    } else if (w.includes("PUSHBUTTON")) {
      const text = textOf(textElement) ?? (inline ? fieldText(lengthOf()) : literal(""));
      const ucommNode = after(s, "COMMAND");
      const params = [{ name: "text", value: text }];
      const ucomm = this.userCommand(s) ?? (ucommNode ? uc(nodeText(ucommNode)) : "");
      params.push({ name: "event", value: literal(ucomm) });
      if (modif) params.push({ name: "modif_id", value: literal(uc(nodeText(modif))) });
      chain.push({ method: "button", params });
      this.map(s, "`screen->button( )` - its USER-COMMAND arrives in `at_user_command( )`");
    } else if (w.includes("SKIP") || w.includes("ULINE") || w.includes("POSITION")) {
      this.map(s, "dropped - the selection screen has no blank lines, lines or positions");
      this.note("SELECTION-SCREEN SKIP / ULINE / POSITION - the form lays out the fields by itself");
    } else if (hasSeq(w, "FUNCTION", "KEY")) {
      const n = Number(nodeText(child(s, "Integer")));
      const fk = this.functionKeys.get(n);
      const params = [{ name: "number", value: String(n) }, { name: "text", value: fk ? this.literalArg(fk.text ?? `'FC0${n}'`, s) : literal(`FC0${n}`) }];
      if (fk?.icon) params.push({ name: "icon", value: literal(fk.icon) });
      chain.push({ method: "function_key", params });
      if (!fk) this.todo(s, `SELECTION-SCREEN FUNCTION KEY ${n}: no sscrfields-functxt_0${n} = ... in the report - the button reads FC0${n}; give it its text in function_key( )`);
      this.map(s, `\`screen->function_key( )\` - a button of the toolbar raising FC0${n}, which arrives in \`at_user_command( )\` (and AT SELECTION-SCREEN as sscrfields-ucomm)`);
    } else if (hasSeq(w, "BEGIN", "OF", "TABBED", "BLOCK")) {
      chain.push({ method: "tabbed_block_begin", params: [] });
      this.openTabbed = [...(this.openTabbed ?? []), uc(nodeText(child(s, "BlockName")))];
      this.map(s, "`screen->tabbed_block_begin( )` - the tabs that follow");
    } else if (w.includes("TAB")) {
      // the text of the tab: a field the report sets, or a text symbol
      const te = child(s, "TextElement");
      const field = te ? this.textSymbol(nodeText(child(te, "TextElementKey")), undefined, s) : lc(nodeText(child(s, "InlineField")));
      if (!te) {
        const len = nodeText(child(s, "Integer"));
        heading("selection screen");
        push(`DATA ${field} TYPE c LENGTH ${len}.`);
      }
      chain.push({ method: "tab", params: [{ value: field }], positional: true });
      const ints = s.getChildren().filter((c) => kind(c) === "Integer");
      if (w.includes("DEFAULT") && w.includes("SCREEN") && !w.includes("PROGRAM") && ints.length > 1) {
        chain.push({ subscreen: nodeText(ints[ints.length - 1]).padStart(4, "0"), stmt: s });
      } else {
        this.refuse(s, `SELECTION-SCREEN TAB ${field}${w.includes("PROGRAM") ? " ... DEFAULT PROGRAM" : " without DEFAULT SCREEN"} - the subscreen of the tab is set at runtime or in another program; give the tab a DEFAULT SCREEN of this report`);
      }
      if (child(s, "Field")) this.note("SELECTION-SCREEN TAB ... USER-COMMAND - a click on a tab raises no user command here; the tabs switch in the browser");
      this.map(s, `\`screen->tab( ${field} )\` - its text is the field ${field}, set in initialization( ); the fields of its subscreen follow`);
    } else if (w.includes("INCLUDE")) {
      this.refuse(s, "SELECTION-SCREEN INCLUDE - the included selection screen is not part of the input");
    } else if (w.includes("DYNAMIC")) {
      this.refuse(s, "SELECTION-SCREEN DYNAMIC SELECTIONS - logical database selections");
    } else {
      this.refuse(s, `this SELECTION-SCREEN statement is not supported: ${shortText(s)}`);
    }
  }

  /** a global declaration as an attribute: LIKE a DDIC field becomes TYPE */
  renderDecl(s) {
    const ov = this.rewrites(s, {});
    this.likeToType(s, ov);
    this.tableKey(s, ov);
    const after = this.headerDecl(s, ov);
    const t = renderTokens(stmtTokens(s), ov, s.getColon()).replace(/^(\w+)(\s*):\s*/, "$1 ");
    return `${t}.${after.map((l) => `\n${l}`).join("")}`;
  }

  /** a chained declaration in the house layout:
   *    TYPES:
   *      BEGIN OF ty_s_flight,
   *        carrid TYPE c LENGTH 3,
   *      END OF ty_s_flight. */
  renderDeclGroup(all) {
    const keyword = uc(all[0].getFirstToken().getStr());
    const group = all.filter((s) => {
      const name = lc(declName(s) ?? "");
      const alv = kind(s) === "Data" && (this.salvVars.has(name) || this.fcatVars.has(name) || this.layoutVars.has(name) || this.isGridObject(name));
      if (alv) this.map(s, "dropped - the ALV object, field catalog or layout is the alv( ) chain now");
      return !alv;
    });
    if (!group.length) return undefined;
    if (group.length === 1 && !/Begin$|End$/.test(kind(group[0]))) return this.renderDecl(group[0]);
    const lines = [`${keyword}:`];
    const after = [];
    let depth = 1;
    group.forEach((s, i) => {
      const k = kind(s);
      if (/End$/.test(k)) depth--;
      const ov = this.rewrites(s, {});
      this.likeToType(s, ov);
      this.tableKey(s, ov);
      after.push(...this.headerDecl(s, ov));
      const part = renderTokens(partTokens(s), ov);
      lines.push(`${"  ".repeat(depth)}${part.replace(/\n/g, `\n${"  ".repeat(depth)}`)}${i === group.length - 1 ? "." : ","}`);
      if (/Begin$/.test(k)) depth++;
    });
    return [...lines, ...after].join("\n");
  }

  /**
   * A declaration with a header line, as a table without one: OCCURS n and
   * WITH HEADER LINE go, the type becomes a STANDARD TABLE OF the line type
   * with the default key written out (tableKey( ) says why), and the work
   * area that stands for the header line is declared after it - LIKE LINE
   * OF the table, whatever the line type was. BEGIN OF x OCCURS n declares
   * the work area itself, renamed, and the table LIKE a table of it after
   * END OF. Answers the lines that follow the declaration. `local` names
   * the work area of a FORM's own table (declared right after it, where
   * the table is known); a global one has its name from analyze( ).
   */
  headerDecl(s, ov, local) {
    const k = kind(s);
    if (!(k === "Data" || k === "DataBegin" || k === "DataEnd" || k === "Type") || !hasHeaderLine(s, this.beginHeader)) return [];
    const toks = stmtTokens(s);
    const w = toks.map((t) => uc(t.getStr()));
    const name = lc(declName(s) ?? "");
    const header = local ?? this.globalHeader.get(name);
    const nameIdx = toks.findIndex((t) => lc(t.getStr()) === name);
    if (k === "DataBegin") {
      // BEGIN OF itab OCCURS n -> BEGIN OF wa_itab
      if (!header) return [];
      ov.set(key(toks[nameIdx]), header.wa);
      dropWords(toks, w, ov, "OCCURS", 1);
      this.beginHeader = { name, wa: header.wa };
      this.map(s, `\`BEGIN OF ${header.wa}\` - the structure is the work area; the table \`${name}\` is declared LIKE a table of it`);
      return [];
    }
    if (k === "DataEnd") {
      const begin = this.beginHeader;
      if (!begin || begin.name !== name) return [];
      this.beginHeader = undefined;
      ov.set(key(toks[nameIdx]), begin.wa);
      return [`DATA ${name} LIKE STANDARD TABLE OF ${begin.wa} WITH DEFAULT KEY.`];
    }
    // DATA itab TYPE x OCCURS n [WITH HEADER LINE] / TYPE [STANDARD] TABLE OF x WITH HEADER LINE / TYPE ty_tab WITH HEADER LINE
    const occurs = w.indexOf("OCCURS");
    const typeAt = w.findIndex((x, i) => i > nameIdx && (x === "TYPE" || x === "LIKE"));
    if (occurs >= 0 && typeAt >= 0 && !w.slice(typeAt, occurs).includes("TABLE")) {
      const typeTok = toks[typeAt];
      // LIKE a DDIC table (allowed in a report, not in a class) becomes TYPE
      const root = lc(toks[typeAt + 1]?.getStr() ?? "");
      const isData = this.globalData.has(root) || this.currentLocals?.has(root) || this.currentForm?.params.some((p) => p.name === root);
      ov.set(key(typeTok), `${w[typeAt] === "LIKE" && !isData ? "TYPE" : ov.get(key(typeTok)) ?? typeTok.getStr()} STANDARD TABLE OF`);
      const last = toks[occurs - 1];
      ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()} WITH DEFAULT KEY`);
      dropWords(toks, w, ov, "OCCURS", 1);
    } else if (occurs >= 0) {
      dropWords(toks, w, ov, "OCCURS", 1);
      if (!w.includes("KEY")) {
        const last = toks[occurs - 1];
        ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()} WITH DEFAULT KEY`);
      }
    }
    const withAt = w.findIndex((x, i) => x === "WITH" && w[i + 1] === "HEADER" && w[i + 2] === "LINE");
    if (withAt >= 0) {
      // TYPE TABLE OF x -> TYPE STANDARD TABLE OF x (fully_type_itabs)
      const tableAt = w.indexOf("TABLE");
      if (tableAt > 0 && !["STANDARD", "SORTED", "HASHED", "ANY", "INDEX"].includes(w[tableAt - 1])) {
        ov.set(key(toks[tableAt]), `STANDARD ${toks[tableAt].getStr()}`);
      }
      if (w.includes("TABLE") && !w.includes("KEY")) {
        const last = toks[withAt - 1];
        ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()} WITH DEFAULT KEY`);
      }
      for (const t of toks.slice(withAt, withAt + 3)) ov.set(key(t), null);
    }
    if (k === "Type" || !header) return [];
    this.map(s, `\`DATA ${name} ... STANDARD TABLE OF\` and the work area \`${header.wa}\` - the header line is a work area`);
    return [`DATA ${header.wa} LIKE LINE OF ${name}.`];
  }

  /**
   * DATA ... TYPE [STANDARD] TABLE OF x without a key clause: WITH DEFAULT
   * KEY written out. The same table as before - a DATA declaration without a
   * key has the default key - but said, because the abap2UI5 linter
   * (default-key-table) reads the implicit key as a trap: SORT, COLLECT and
   * DELETE ADJACENT DUPLICATES use it unasked.
   */
  tableKey(s, ov) {
    if (kind(s) !== "Data") return;
    for (const tt of findAll(s, "TypeTable")) {
      const toks = tt.getTokens();
      const w = toks.map((t) => uc(t.getStr()));
      if (!w.includes("TABLE") || !w.includes("OF") || ["KEY", "RANGE", "SORTED", "HASHED", "ANY", "INDEX", "OCCURS", "HEADER"].some((x) => w.includes(x))) continue;
      const end = w.indexOf("INITIAL") > 0 ? w.indexOf("INITIAL") - 1 : toks.length - 1;
      const last = toks[end];
      ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()} WITH DEFAULT KEY`);
    }
  }

  likeToType(s, ov) {
    const toks = stmtTokens(s);
    for (let i = 0; i < toks.length - 1; i++) {
      if (uc(toks[i].getStr()) !== "LIKE") continue;
      if (["LINE", "RANGE", "REF", "STANDARD", "SORTED", "HASHED", "TABLE"].includes(uc(toks[i + 1].getStr()))) continue;
      const root = lc(toks[i + 1].getStr());
      const isData = this.globalData.has(root) && (!this.isTables(root) || this.tablesKept.has(root));
      const isLocal = this.currentLocals?.has(root);
      const isParam = this.currentForm?.params.some((p) => p.name === root);
      if (!isData && !isLocal && !isParam && toks[i + 2]?.getStr() === "-") ov.set(key(toks[i]), "TYPE");
    }
  }

  // --------------------------------------------------------------- FORMs

  /** the FORMs that loop at the screen - themselves or in a FORM they perform */
  screenForms() {
    if (this.screenFormSet) return this.screenFormSet;
    const set = new Set();
    const performs = (f) => f.body.filter((x) => kind(x) === "Perform").map((x) => child(x, "FormName")).filter(Boolean).map((n) => lc(nodeText(n)));
    for (const f of this.forms) {
      if (f.body.some((x) => kind(x) === "LoopAtScreen" || kind(x) === "ModifyScreen")) set.add(f.name);
    }
    for (let grown = true; grown;) {
      grown = false;
      for (const f of this.forms) {
        if (!set.has(f.name) && performs(f).some((n) => set.has(n))) {
          set.add(f.name);
          grown = true;
        }
      }
    }
    this.screenFormSet = set;
    return set;
  }

  formSignature(f) {
    this.currentForm = f;
    const imp = [];
    const chg = [];
    for (const p of f.params) {
      const node = p.node;
      let type;
      const ft = child(node, "FormParamType");
      const structure = after(node, "STRUCTURE");
      if (ft) {
        const ov = new Map();
        const toks = ft.getTokens();
        if (uc(toks[0].getStr()) === "LIKE" && toks[1]) {
          const root = lc(toks[1].getStr());
          const isData = this.globalData.has(root) && (!this.isTables(root) || this.tablesKept.has(root));
          if (!isData && !["line", "range", "ref"].includes(root)) ov.set(key(toks[0]), "TYPE");
        }
        // the row and column types of the grid - a FORM a handler passes them to
        toks.forEach((t, i) => {
          if (i > 0 && LVC_TYPES[lc(t.getStr())]) ov.set(key(t), LVC_TYPES[lc(t.getStr())]);
        });
        type = renderTokens(toks, ov).replace(/\s+/g, " ");
        // TABLES p TYPE ty_t names a table type of the report already - TYPE
        // structure or LIKE itab needs a table type of its own
        const named = /^TYPE\s+/i.test(type) && this.isTableType(type.replace(/^TYPE\s+/i, ""));
        if (p.kind === "tables" && !/TABLE/i.test(type) && !named) {
          type = this.tablesType(type.replace(/^(TYPE|LIKE)\s+/i, ""), /^LIKE/i.test(type));
        }
      } else if (structure) {
        let name = lc(nodeText(structure));
        // STRUCTURE itab of a table with a header line names the line - the work area now
        if (this.globalHeader.has(name)) name = this.globalHeader.get(name).wa;
        const isData = this.globalData.has(name.split("-")[0]) && (!this.isTables(name) || this.tablesKept.has(name));
        type = p.kind === "tables" ? this.tablesType(name, isData) : `${isData ? "LIKE" : "TYPE"} ${name}`;
      } else {
        type = p.kind === "tables" ? "TYPE STANDARD TABLE" : "TYPE any";
        if (p.kind !== "tables") this.todo(f.stmt, `FORM ${f.name}: the parameter ${p.name} has no type - TYPE any, give it the type it has`);
      }
      if (/^TYPE p$/i.test(type)) type = this.genericPacked(f, p, type);
      p.type = type;
      if (p.kind === "using" && !p.written) imp.push(`${p.byValue ? `VALUE(${p.name})` : p.name} ${type}`);
      else if (p.kind === "using" && p.byValue) imp.push(`VALUE(${p.name}) ${type}`);
      else {
        if (p.kind === "using") p.promoted = true;
        chg.push(`${p.byValue ? `VALUE(${p.name})` : p.name} ${type}`);
      }
      if (p.kind === "tables") this.checkHeaderLine(f, p);
    }
    // a FORM with LOOP AT SCREEN - called from AT SELECTION-SCREEN OUTPUT -
    // changes the screen of at_selection_screen_output( screen ): it gets it
    if (this.screenForms().has(f.name)) imp.unshift("screen TYPE REF TO z2ui5_cl_cgui_selscreen");
    const lines = [`    METHODS ${f.method}`];
    const section = (title, list) => {
      if (!list.length) return;
      lines.push(`      ${title}`);
      const width = Math.max(...list.map((l) => l.split(" ")[0].length));
      for (const l of list) {
        const [n, ...rest] = l.split(" ");
        lines.push(`        ${n.padEnd(width)} ${rest.join(" ")}`);
      }
    };
    section("IMPORTING", imp);
    section("CHANGING", chg);
    if (f.raising.length) {
      lines.push("      RAISING");
      for (const r of f.raising) lines.push(`        ${r}`);
    }
    lines[lines.length - 1] += ".";
    this.methodDefs.push({ name: f.method, lines });
    this.currentForm = undefined;
  }

  /**
   * A FORM parameter typed with the generic TYPE p. Valid in a method, but
   * the transpiled runtime has no generic packed type (abaplint transpiler:
   * typeTodoPGenericType) and fails to describe the class - before the first
   * screen. When every PERFORM passes the same global data object, the
   * parameter is typed LIKE it, which is the type the FORM worked with;
   * otherwise it stays generic, with a TODO.
   */
  genericPacked(f, p, type) {
    const actuals = new Set();
    let calls = 0;
    for (const s of this.stmts) {
      if (kind(s) !== "Perform" || lc(nodeText(child(s, "FormName") ?? s)) !== f.name) continue;
      calls++;
      const sec = { tables: "PerformTables", using: "PerformUsing", changing: "PerformChanging" };
      const tables = child(s, sec.tables) ? children(child(s, sec.tables)) : [];
      const other = [...(child(s, sec.using) ? children(child(s, sec.using)) : []), ...(child(s, sec.changing) ? children(child(s, sec.changing)) : [])];
      const list = p.kind === "tables" ? tables : other;
      const at = f.params.filter((x) => (x.kind === "tables") === (p.kind === "tables")).indexOf(p);
      if (list[at]) actuals.add(lc(nodeText(list[at])));
    }
    const [only] = actuals;
    if (calls && actuals.size === 1 && /^[a-z_][\w]*$/.test(only) && this.globalData.has(only)
      && (!this.isTables(only) || this.tablesKept.has(only))) {
      this.todo(f.stmt, `FORM ${f.name}: the generic parameter ${p.name} TYPE p is typed LIKE ${only}, the data object every PERFORM passes - the transpiled runtime has no generic packed type`);
      return `LIKE ${only}`;
    }
    this.todo(f.stmt, `FORM ${f.name}: the parameter ${p.name} is the generic TYPE p - valid in a method, but the transpiled abap2UI5 runtime cannot describe the class; give it a complete type (p LENGTH n DECIMALS d)`);
    return type;
  }

  /** a TYPES of the report that declares a table (TYPES x TYPE ... TABLE OF ...) */
  isTableType(name) {
    const n = lc(name);
    return this.decls.some((s) => kind(s) === "Type" && lc(declName(s)) === n && hasSeq(stmtTokens(s).map((t) => lc(t.getStr())), "table", "of"));
  }

  tablesType(structure, isData) {
    const name = `ty_t_${structure.replace(/[^a-z0-9_]/gi, "_")}`.slice(0, 30);
    if (!this.tablesTypes.has(name)) {
      this.tablesTypes.set(name, `TYPES ${name} ${isData ? "LIKE" : "TYPE"} STANDARD TABLE OF ${structure} WITH DEFAULT KEY.`);
    }
    return `TYPE ${name}`;
  }

  /** a TABLES parameter the FORM uses with its header line (tt-f, LOOP AT
   *  tt., APPEND tt., READ TABLE tt ...) gets a work area of the method */
  checkHeaderLine(f, p) {
    for (const s of f.body) {
      const toks = stmtTokens(s).map((t) => lc(t.getStr()));
      const k = kind(s);
      const idx = toks.indexOf(p.name);
      if (idx < 0) continue;
      const next = toks[idx + 1];
      const prev = toks[idx - 1];
      const headerUse = (next === "-" && prev !== "-" && prev !== "->")
        || (k === "Loop" && !toks.some((t) => ["into", "assigning", "reference", "transporting"].includes(t)))
        || (["Append", "Collect", "InsertInternal", "ModifyInternal", "Clear"].includes(k) && toks.length === 2)
        || (k === "ReadTable" && !toks.some((t) => ["into", "assigning", "reference", "transporting"].includes(t)));
      if (headerUse) {
        if (!child(p.node, "FormParamType") && !after(p.node, "STRUCTURE")) {
          this.refuse(s, `the TABLES parameter ${p.name} of FORM ${f.name} is used with its header line, and has no type - a work area needs one; give the parameter a STRUCTURE or a table TYPE first`);
          return;
        }
        f.headerParams ??= new Set();
        f.headerParams.add(p.name);
        this.map(f.stmt, `the TABLES parameter ${p.name} is used with its header line - a work area ls_${p.name} of the method`);
        return;
      }
    }
  }

  // ---------------------------------------------------------------- bodies

  /** the statements of an event block or FORM as the lines of a method */
  convertBody(stmts, ctx) {
    const b = {
      out: [],                    // lines (strings) and write chains (objects)
      ctx,
      color: "none",
      hotspot: false,
      line: [],                   // the write items of the current list line
      msgDeclared: false,
      loopDepth: 0,
      screenLoopDepth: -1,
      screenWa: undefined,
      lastRow: undefined,
      stmts,                      // the statements of the body, and the index of the current one
      index: 0,
      blocks: [],                 // the IF, CASE, LOOP, ... the current statement stands in
      skipTo: undefined,          // set when the rest of the branch went to a continuation
    };
    // FORMAT inside an IF, CASE or loop is state at runtime: the method keeps
    // the color in lv_color, and every write( ) passes it
    let depth = 0;
    for (const s of stmts) {
      const k = kind(s);
      if (CLOSERS.has(k)) depth--;
      if (k === "Format" && depth > 0 && child(s, "Color")) b.runtimeColor = true;
      if (OPENERS.has(k)) depth++;
    }
    if (b.runtimeColor) {
      b.colorVar = this.identifiers.has("lv_color") ? "lv_r2c_color" : "lv_color";
      this.addPrelude(ctx.method, `DATA ${b.colorVar} TYPE string.`);
    }
    this.currentForm = ctx.form;
    this.currentLocals = new Set(stmts.filter((s) => ["Data", "DataBegin", "Constant", "Type", "Ranges", "FieldSymbol"].includes(kind(s)))
      .map((s) => lc(declName(s) ?? "")));
    if (ctx.form) for (const p of ctx.form.params) this.currentLocals.add(p.name);
    // DATA( x ) in a method of a local class: a variable of the method, also
    // when the report has a global x
    if (ctx.local) {
      for (const s of stmts) {
        const toks = stmtTokens(s);
        toks.forEach((t, i) => {
          if (lc(t.getStr()) === "data" && toks[i + 1]?.getStr() === "(" && toks[i + 3]?.getStr() === ")") this.currentLocals.add(lc(toks[i + 2].getStr()));
        });
      }
    }
    // the tables with a header line of this body: a FORM's own (their work
    // area is declared right after them, where the table is known) and the
    // TABLES parameters the FORM uses with their header line (a work area
    // of the method, ls_<name>, declared with the prelude)
    b.localWa = new Map();
    for (const s of stmts) {
      if (kind(s) === "Data" && hasHeaderLine(s)) {
        const name = lc(declName(s) ?? "");
        b.localWa.set(name, (this.identifiers.has(`ls_${name}`) ? `ls_r2c_${name}` : `ls_${name}`).slice(0, 30));
      }
    }
    b.headerParams = new Set(ctx.form?.headerParams ?? []);
    this.currentBody = b;
    // a continuation starts with what the call left: the answer, the values
    let prologue = ctx.prologue?.length ? ctx.prologue : undefined;
    const DECLS = new Set(["Data", "DataBegin", "DataEnd", "FieldSymbol", "Ranges", "Constant", "ConstantBegin", "ConstantEnd", "Type", "TypeBegin", "TypeEnd", "Comment"]);

    for (let i = 0; i < stmts.length; i++) {
      const s = stmts[i];
      // a blank line of the source between two statements stays one
      const first = s.getFirstToken().getRow();
      if (b.lastRow !== undefined && first > b.lastRow + 1 && b.out.length && b.out[b.out.length - 1] !== "") b.out.push("");
      const k = kind(s);
      if (k === "MacroCall" || k === "MacroContent") continue;
      if (this.skipStmts?.has(s)) {
        b.lastRow = s.getLastToken().getRow();
        continue;
      }
      if (prologue && !DECLS.has(k)) {
        if (b.out.length) b.out.push("");
        b.out.push(...prologue);
        prologue = undefined;
      }
      if (k === "Comment") {
        const text = s.getFirstToken().getStr();
        if (b.lastRow === first && b.out.length && typeof b.out[b.out.length - 1] === "string" && b.out[b.out.length - 1] !== "") {
          b.out[b.out.length - 1] += `  ${text}`;
        } else {
          b.out.push(text.startsWith("*") ? `"${text.slice(1)}` : text);
        }
        b.lastRow = s.getLastToken().getRow();
        continue;
      }
      // EXEC SQL ... ENDEXEC is refused as a whole
      if (k === "ExecSQL") {
        this.refuse(s, REFUSED.ExecSQL);
        while (stmts[i + 1] && kind(stmts[i]) !== "EndExec") i++;
        b.lastRow = stmts[i].getLastToken().getRow();
        continue;
      }
      // a chain of WRITEs is one call chain of the list
      if (k === "Write" && !findTo(s)) {
        const group = [s];
        while (s.getColon() && stmts[i + 1] && kind(stmts[i + 1]) === "Write" && sameColon(stmts[i + 1], s) && !findTo(stmts[i + 1])) {
          group.push(stmts[++i]);
        }
        this.writeChain(group, b);
        b.lastRow = group[group.length - 1].getLastToken().getRow();
        continue;
      }
      // CLEAR: a, b. / DATA: a TYPE i, b TYPE string. stay one chain
      if (s.getColon() && CHAINABLE.has(k) && !this.alvPlan.has(s)) {
        const group = [s];
        while (stmts[i + 1] && kind(stmts[i + 1]) === k && sameColon(stmts[i + 1], s) && !this.alvPlan.has(stmts[i + 1])) group.push(stmts[++i]);
        if (group.length > 1 && !group.some((x) => this.headerLineTouches(x))) {
          const text = this.renderChainGroup(group, b);
          if (text) b.out.push(text);
          b.lastRow = group[group.length - 1].getLastToken().getRow();
          continue;
        }
        i -= group.length - 1;
      }
      const refused = this.refusals.length;
      b.index = i;
      if (CLOSERS.has(k)) b.blocks.pop();
      this.statement(s, b);
      if (OPENERS.has(k)) b.blocks.push(k);
      // a refused statement leaves a mark in the draft (--partial)
      if (this.refusals.length > refused) b.out.push(`" report2cloud refused (${this.where(first)}): ${shortText(s).replace(/"/g, "'")}`);
      b.lastRow = s.getLastToken().getRow();
      if (b.skipTo !== undefined) {
        i = b.skipTo - 1;
        b.lastRow = stmts[i].getLastToken().getRow();
        b.skipTo = undefined;
      }
    }
    if (prologue) b.out.push(...prologue);
    this.currentForm = undefined;
    return b.out.flatMap((o) => (typeof o === "string" ? [o] : renderChain(o)));
  }

  /**
   * SUBMIT report [WITH ...] [VIA SELECTION-SCREEN] [USING SELECTION-SET v]
   * [AND RETURN] -> submit( report = the class values = ... ): the runtime
   * starts the class with the values and Back returns here. A WITH p = v
   * is a parameter value, every other comparison a range line - the runtime
   * takes the kind from the attribute of the called class, so the caller
   * need not know whether p is a parameter or a select-option there.
   */
  submit(s, b) {
    const out = b.out;
    const w = words(s);
    const ch = s.getChildren();
    const ov = this.rewrites(s, b.ctx);
    const text = (n) => nodeText(n, ov);
    const wordAt = (i) => (ch[i] && isToken(ch[i]) ? uc(ch[i].get().getStr()) : "");
    if (hasSeq(w, "EXPORTING", "LIST", "TO", "MEMORY")) {
      this.refuse(s, "SUBMIT ... EXPORTING LIST TO MEMORY - the list of the called report is not in memory here; read the data through a method of its class");
      return;
    }
    if (hasSeq(w, "TO", "SAP", "-", "SPOOL") || hasSeq(w, "SPOOL", "PARAMETERS")) {
      this.refuse(s, "SUBMIT ... TO SAP-SPOOL - no spool from a browser app; the runtime prints the list from the browser");
      return;
    }
    if (hasSeq(w, "VIA", "JOB")) {
      this.refuse(s, "SUBMIT ... VIA JOB - no background jobs from a browser app; use a released job API");
      return;
    }
    if (hasSeq(w, "WITH", "-", "FREE", "SELECTIONS")) {
      this.refuse(s, "SUBMIT ... WITH-FREE SELECTIONS - logical database selections have no counterpart");
      return;
    }
    if (hasSeq(w, "USING", "SELECTION", "-", "SCREEN") || hasSeq(w, "USING", "SELECTION", "-", "SETS")) {
      this.refuse(s, "SUBMIT ... USING SELECTION-SCREEN / SELECTION-SETS OF PROGRAM - the class has its standard selection screen and its own variants only");
      return;
    }

    // the report, and the class it became
    const params = [];
    const nameNode = child(s, "IncludeName");
    const dynamic = child(s, "Dynamic");
    let program;
    if (nameNode) {
      program = lc(nodeText(nameNode));
      const known = this.classFor?.(program);
      params.push({ name: "report", value: literal(uc(known ?? defaultClassName(program))) });
      if (!known) this.todo(s, `SUBMIT ${uc(program)}: the report is not part of the input - convert it as well; the class is taken to be ${uc(defaultClassName(program))}, the name report2cloud gives it`);
    } else if (dynamic) {
      params.push({ name: "report", value: text(child(dynamic, "FieldChain") ?? dynamic) });
      this.todo(s, "SUBMIT (name): the field must hold the name of the class the report became - the classic held the report name");
    } else {
      this.refuse(s, `this SUBMIT is not understood: ${shortText(s)}`);
      return;
    }

    // WITH p = v, WITH s IN range, WITH s op v [SIGN x], WITH SELECTION-TABLE t
    const OPTION = { "=": "EQ", EQ: "EQ", NE: "NE", GE: "GE", GT: "GT", LE: "LE", LT: "LT", CP: "CP", NP: "NP", BETWEEN: "BT", INCL: "EQ" };
    const NEGATED = { EQ: "NE", NE: "EQ", BT: "NB", CP: "NP", NP: "CP", GE: "LT", GT: "LE", LE: "GT", LT: "GE" };
    const values = [];
    for (let i = 0; i < ch.length; i++) {
      if (wordAt(i) !== "WITH") continue;
      const nx = ch[i + 1];
      if (nx && kind(nx) === "FieldSub") {
        const name = literal(uc(nodeText(nx)));
        let j = i + 2;
        let negated = false;
        if (wordAt(j) === "NOT") {
          negated = true;
          j++;
        }
        const op = wordAt(j);
        const low = ch[j + 1];
        let high;
        let k = j + 2;
        if (op === "BETWEEN") {
          high = ch[k + 1];
          k += 2;
        }
        const sign = wordAt(k) === "SIGN" ? text(ch[k + 1]) : undefined;
        if (op === "IN") {
          if (negated) {
            this.refuse(s, `SUBMIT ... WITH ${uc(nodeText(nx))} NOT IN - a range cannot be handed over negated`);
            return;
          }
          values.push({ lines: `z2ui5_cl_cgui_variant=>range_lines_get( name = ${name} range = ${text(low)} )` });
          continue;
        }
        let option = OPTION[op];
        if (!option) {
          this.refuse(s, `SUBMIT ... WITH ${uc(nodeText(nx))} ${op} - not a comparison of a range`);
          return;
        }
        if (negated) option = NEGATED[option];
        if ((op === "=" || op === "EQ") && !sign && !negated) {
          values.push(`( name = ${name} kind = z2ui5_cl_cgui_variant=>cs_kind-parameter low = ${text(low)} )`);
        } else {
          values.push(`( name = ${name} kind = z2ui5_cl_cgui_variant=>cs_kind-select_option sign = ${sign ?? "`I`"} option = ${literal(option)} low = ${text(low)}${high ? ` high = ${text(high)}` : ""} )`);
        }
      } else if (wordAt(i + 1) === "SELECTION" && wordAt(i + 3) === "TABLE") {
        values.push({ lines: `z2ui5_cl_cgui_variant=>selection_table_get( ${text(ch[i + 4])} )` });
        this.note("SUBMIT ... WITH SELECTION-TABLE: selection_table_get( ) reads selname, kind, sign, option, low and high of the lines, as RSPARAMS has them");
      }
    }
    // a range or a selection table is many values: the values are collected
    // in a table first - VALUE #( ( LINES OF ... ) ) does not transpile
    const prologue = [];
    if (values.some((v) => typeof v !== "string")) {
      this.submitCount = (this.submitCount ?? 0) + 1;
      const tab = `lt_r2c_submit_${this.submitCount}`;
      const part = `lt_r2c_lines_${this.submitCount}`;
      prologue.push(`DATA ${tab} TYPE z2ui5_cl_cgui_variant=>ty_t_value.`, `DATA ${part} TYPE z2ui5_cl_cgui_variant=>ty_t_value.`, `CLEAR ${tab}.`);
      for (const v of values) {
        // v is the line in parentheses: ( name = ... )
        if (typeof v === "string") prologue.push(`INSERT VALUE #${v} INTO TABLE ${tab}.`);
        else prologue.push(`${part} = ${v.lines}.`, `APPEND LINES OF ${part} TO ${tab}.`);
      }
      values.length = 0;
      params.push({ name: "values", value: tab });
    } else if (values.length) params.push({ name: "values", value: values.length === 1 ? `VALUE #( ${values[0]} )` : "VALUE #(" });
    if (hasSeq(w, "VIA", "SELECTION", "-", "SCREEN")) params.push({ name: "via_selection_screen", value: "abap_true" });
    const setAt = ch.findIndex((c, i) => isToken(c) && uc(c.get().getStr()) === "SET" && wordAt(i - 1) === "-" && wordAt(i - 2) === "SELECTION");
    if (setAt >= 0 && ch[setAt + 1]) params.push({ name: "using_variant", value: text(ch[setAt + 1]) });
    if (hasSeq(w, "LINE", "-", "SIZE") || hasSeq(w, "LINE", "-", "COUNT")) this.note("SUBMIT ... LINE-SIZE / LINE-COUNT - dropped, the called class formats its own list");

    // the call: the values one a line under VALUE #(
    const head = "submit( ";
    const width = Math.max(...params.map((p) => p.name.length));
    const lines = [];
    params.forEach((p, i) => {
      const prefix = `${i ? " ".repeat(head.length) : head}${p.name.padEnd(width)} = `;
      if (p.name === "values" && values.length > 1) {
        const pad = " ".repeat(prefix.length + "VALUE #( ".length);
        lines.push(`${prefix}VALUE #( ${values[0]}`);
        for (const v of values.slice(1)) lines.push(`${pad}${v}`);
        lines[lines.length - 1] += " )";
        return;
      }
      lines.push(`${prefix}${p.value}`);
    });
    out.push(...prologue, `${lines.join("\n")} ).`);
    const andReturn = child(s, "AndReturn");
    this.map(s, andReturn
      ? "`submit( report values )` - the class of the called report starts with the values, Back returns here"
      : "`submit( report values )` and `RETURN` - the classic SUBMIT without AND RETURN ended this report");
    if (!andReturn) {
      out.push("RETURN.");
      if (b.ctx.form) this.todo(s, `SUBMIT without AND RETURN in FORM ${b.ctx.form.name}: RETURN only leaves ${b.ctx.form.method}( ) - the classic ended the report; nothing of the caller ran on`);
    } else if (this.followedByCode(b)) {
      this.todo(s, "the statements after SUBMIT ... AND RETURN ran when the called report came back - here they run before it starts (submit( ) navigates when the method returns); move them to where they belong");
    }
  }

  /**
   * CALL SELECTION-SCREEN nnnn [STARTING AT x y] -> call_selection_screen(
   * dynnr ): the screen opens as a dialog when the method returns, and its
   * answer (sy-subrc 0 or 4) arrives in after_call_selection_screen( dynnr
   * subrc ). So the statements after the call, which read sy-subrc, go on
   * there - cut off the event block and converted as that method's WHEN.
   */
  callSelectionScreen(s, b) {
    const out = b.out;
    const w = words(s);
    const src = child(s, "Source");
    const nr = nodeText(src).replace(/['`]/g, "").padStart(4, "0");
    const d = this.dynnrScreens?.get(nr);
    if (!d) {
      this.refuse(s, `CALL SELECTION-SCREEN ${nr} - no SELECTION-SCREEN BEGIN OF SCREEN ${nr} in the report; the class calls the screens of selection_screen_dynnr( ) only`);
      return;
    }
    const params = [{ name: "dynnr", value: literal(nr) }];
    if (d.title) params.push({ name: "title", value: d.title });
    out.push(renderNamedCall("call_selection_screen", params));
    this.map(s, "`call_selection_screen( dynnr )` - the screen as a dialog; sy-subrc arrives in `after_call_selection_screen( dynnr subrc )`");
    if (hasSeq(w, "STARTING", "AT")) this.note("CALL SELECTION-SCREEN ... STARTING AT - the dialog is centred, the position is dropped");
    if (d.continued && this.followedByCode(b)) {
      this.refuse(s, `a second CALL SELECTION-SCREEN ${nr} with statements after it - after_call_selection_screen( ) goes on after one call per screen; port it by hand`);
      return;
    }
    d.continued = true;
    // the IF / CHECK / CASE right after the call read the dialog's sy-subrc -
    // the subrc of the method; a later sy-subrc is the one of a statement
    // in between
    const { branch } = this.tailOf(b);
    const subrc = new Set();
    const first = branch.findIndex((x) => kind(x) !== "Comment");
    if (first >= 0 && ["If", "Check", "Case"].includes(kind(branch[first]))) {
      subrc.add(branch[first]);
      if (kind(branch[first]) === "If") {
        let depth = 0;
        for (const x of branch.slice(first + 1)) {
          const k = kind(x);
          if (OPENERS.has(k)) depth++;
          if (CLOSERS.has(k)) {
            if (depth === 0) break;
            depth--;
          }
          if (k === "ElseIf" && depth === 0) subrc.add(x);
        }
      }
    }
    this.continueIn(s, b, {
      field: nr, method: "after_call_selection_screen", ctx: { method: "after_call_selection_screen", subrc },
      what: `CALL SELECTION-SCREEN ${nr}`, where: "after_call_selection_screen( dynnr subrc )",
      note: `\`after_call_selection_screen( dynnr subrc )\` - WHEN \`${nr}\`: the statements after CALL SELECTION-SCREEN, sy-subrc is subrc`,
    });
  }

  /** whether statements of the body still run after the current one - the
   *  closers of the blocks it stands in do not count, nor the other
   *  branches of an IF or CASE it stands in */
  followedByCode(b) {
    const { branch, after } = this.tailOf(b);
    return after || branch.some((x) => kind(x) !== "Comment");
  }

  /**
   * What runs after the current statement: `branch`, the statements that
   * follow it in its own branch (up to the ELSE, WHEN or closer of the
   * block it stands in), and `after`, whether anything runs once that block
   * and the ones around it are left - the other branches do not count.
   */
  tailOf(b) {
    const rest = b.stmts.slice(b.index + 1);
    const BRANCH = new Set(["Else", "ElseIf", "When", "WhenOthers", "WhenType", "Catch", "Cleanup"]);
    const branch = [];
    let depth = 0;
    let i = 0;
    for (; i < rest.length; i++) {
      const k = kind(rest[i]);
      if (depth === 0 && (CLOSERS.has(k) || BRANCH.has(k))) break;
      if (OPENERS.has(k)) depth++;
      if (CLOSERS.has(k)) depth--;
      branch.push(rest[i]);
    }
    let skipping = false;
    depth = 0;
    for (; i < rest.length; i++) {
      const k = kind(rest[i]);
      if (k === "Comment") continue;
      if (skipping) {
        if (OPENERS.has(k)) depth++;
        else if (CLOSERS.has(k)) {
          if (depth === 0) skipping = false;
          else depth--;
        }
        continue;
      }
      if (CLOSERS.has(k)) continue;
      if (BRANCH.has(k)) {
        skipping = true;
        depth = 0;
        continue;
      }
      return { branch, after: true };
    }
    return { branch, after: false };
  }

  /**
   * SET PF-STATUS 'S' [EXCLUDING f] -> set_pf_status( functions shortcuts
   * excluding ): the buttons of the application toolbar of status S, with
   * text, icon and tooltip, and its function keys as keyboard shortcuts -
   * read from the GUI status abapGit writes into the .prog.xml. Every
   * function arrives in at_user_command( ) with its code, as sy-ucomm did.
   */
  setPfStatus(s, b) {
    const ov = this.rewrites(s, b.ctx, b);
    const srcs = findAll(s, "Source").filter((n) => s.getChildren().includes(n));
    const w = words(s);
    const nameNode = srcs[0];
    const name = nameNode ? nodeText(nameNode, ov) : "";
    const exclAt = s.getChildren().findIndex((c) => isToken(c) && uc(c.get().getStr()) === "EXCLUDING");
    const excl = exclAt >= 0 ? nodeText(s.getChildren()[exclAt + 1], ov) : undefined;
    if (w.includes("OF") && w.includes("PROGRAM")) {
      this.todo(s, `SET PF-STATUS ${name} OF PROGRAM - the status of another program is not part of the input; set_pf_status( functions = ... ) with its functions by hand`);
      this.map(s, "dropped - SET PF-STATUS OF PROGRAM");
      return;
    }
    // SET PF-STATUS space - back to the standard list status
    if (/^(space|''|``|' ')$/i.test(name)) {
      b.out.push("set_pf_status( VALUE #( ) ).");
      this.map(s, "`set_pf_status( VALUE #( ) )` - the toolbar without functions of the report");
      return;
    }
    if (!/^'[^']*'$/.test(name)) {
      this.todo(s, `SET PF-STATUS ${name}: the status is named at runtime - set_pf_status( functions = ... ) for each status the field may name`);
      this.map(s, "dropped - SET PF-STATUS with a field");
      return;
    }
    const code = uc(unquote(name));
    const cua = this.pool.cua;
    const status = cua?.statuses.get(code);
    if (!status) {
      this.todo(s, cua
        ? `SET PF-STATUS '${code}' dropped - the .prog.xml has no status ${code}; set_pf_status( functions = ... ) adds the functions to the toolbar of the output, each arrives in at_user_command( )`
        : `SET PF-STATUS '${code}' dropped - the GUI status is in the .prog.xml (--texts), which was not passed; set_pf_status( functions = ... ) adds the functions to the toolbar of the output, each arrives in at_user_command( )`);
      this.map(s, "dropped - SET PF-STATUS");
      return;
    }
    const fnLines = status.functions.map((f) => {
      const parts = [`name = ${literal(f.code)}`];
      if (f.text) parts.push(`text = ${literal(f.text)}`);
      const icon = f.icon ? ICONS[lc(f.icon)] : undefined;
      if (icon) parts.push(`icon = ${literal(icon)}`);
      const tip = [f.tooltip ?? (f.text || f.code), f.key ? `(${f.key})` : ""].filter(Boolean).join(" ");
      if (tip) parts.push(`tooltip = ${literal(tip)}`);
      if (f.icon && !icon) this.note(`SET PF-STATUS: the icon ${uc(f.icon)} has no UI5 icon in the converter's table - the button shows its text${f.text ? "" : " (the function code)"}`);
      if (f.icon && !icon && !f.text) parts.splice(1, 0, `text = ${literal(f.code)}`);
      return `( ${parts.join(" ")} )`;
    });
    const params = [{ name: "functions", lines: fnLines }];
    if (status.shortcuts.length) params.push({ name: "shortcuts", lines: status.shortcuts.map((k) => `( key = ${literal(k.key)} ucomm = ${literal(k.code)} )`) });
    if (excl !== undefined) params.push({ name: "excluding", lines: [/^'[^']*'$/.test(excl) ? `VALUE string_table( ( ${literal(uc(unquote(excl)))} ) )` : excl], raw: true });
    b.out.push(renderTableCall("set_pf_status", params));
    if (w.includes("IMMEDIATELY")) this.note("SET PF-STATUS ... IMMEDIATELY - the toolbar shows with the next roundtrip either way");
    this.map(s, `\`set_pf_status( )\` - ${status.functions.length} function(s) of status ${code} on the toolbar, ${status.shortcuts.length} function key(s) as shortcuts; each arrives in \`at_user_command( )\``);
    this.statusSet = true;
  }

  /**
   * SET TITLEBAR 'T' [WITH a b ...] -> set_title( ): the text of title T
   * from the .prog.xml, &1 ... &9 (and a bare &, in turn) replaced by the
   * values in a string template.
   */
  setTitlebar(s, b) {
    const ov = this.rewrites(s, b.ctx, b);
    const srcs = findAll(s, "Source").filter((n) => s.getChildren().includes(n));
    const w = words(s);
    const name = srcs[0] ? nodeText(srcs[0], ov) : "";
    if (w.includes("OF") && w.includes("PROGRAM")) {
      this.todo(s, `SET TITLEBAR ${name} OF PROGRAM - the title of another program is not part of the input; call set_title( ) with its text`);
      this.map(s, "dropped - SET TITLEBAR OF PROGRAM");
      return;
    }
    const withAt = s.getChildren().findIndex((c) => isToken(c) && uc(c.get().getStr()) === "WITH");
    const values = withAt >= 0 ? s.getChildren().slice(withAt + 1).filter((c) => kind(c) === "Source").map((n) => nodeText(n, ov)) : [];
    const text = /^'[^']*'$/.test(name) ? this.pool.cua?.titles.get(uc(unquote(name))) : undefined;
    if (text === undefined) {
      this.todo(s, /^'[^']*'$/.test(name)
        ? `SET TITLEBAR ${name} dropped - ${this.pool.cua ? "the .prog.xml has no such title" : "the titles are in the .prog.xml (--texts), which was not passed"}; call set_title( ) with its text`
        : `SET TITLEBAR ${name}: the title is named at runtime - call set_title( ) with the text of each title the field may name`);
      this.map(s, "dropped - SET TITLEBAR");
      return;
    }
    let next = 0;
    const esc = (t) => t.replace(/[\\|{}]/g, (c) => `\\${c}`);
    let template = "";
    let rest = text;
    const re = /&(\d?)/g;
    let last = 0;
    let m;
    while ((m = re.exec(text))) {
      template += esc(text.slice(last, m.index));
      const idx = m[1] ? Number(m[1]) - 1 : next++;
      template += values[idx] !== undefined ? `{ ${values[idx]} }` : "";
      last = m.index + m[0].length;
    }
    rest = text.slice(last);
    template += esc(rest);
    const value = last === 0 ? literal(text) : `|${template}|`;
    b.out.push(`set_title( ${value} ).`);
    this.map(s, `\`set_title( )\` - the text of title ${uc(unquote(name))}${values.length ? ", the WITH values in a string template" : ""}`);
  }

  /** one statement of a body */
  statement(s, b) {
    const k = kind(s);
    const out = b.out;
    if (this.screenDrops?.has(s)) {
      this.map(s, `dropped - ${this.screenDrops.get(s)}`);
      return;
    }
    if (this.tabbedBlocks?.size) {
      const toks = stmtTokens(s).map((t) => lc(t.getStr()));
      const tb = toks.find((t, i) => this.tabbedBlocks.has(t) && toks[i + 1] === "-" && (i === 0 || !["-", "->", "=>"].includes(toks[i - 1])));
      if (tb) {
        this.todo(s, `${tb}-activetab / -dynnr: the program selects the tab of the tabbed block ${tb} - the user selects it here; dropped`);
        this.map(s, "dropped - the tab of a tabbed block is the user's");
        return;
      }
    }
    const plan = this.alvPlan.get(s);
    if (plan) {
      if (plan.action === "skip") return;
      if (plan.action === "drop") {
        if (plan.todo) this.todo(s, plan.todo);
        this.map(s, `dropped - ${plan.reason}`);
        return;
      }
      if (plan.action === "catch") {
        out.push(`CATCH ${plan.names.join(" ")}${this.catchInto(s)}.`);
        return;
      }
      if (plan.action === "alv") {
        const salv = this.salv.get(plan.salv);
        out.push(...this.alvChain(salv.table, salv.tableTok, salv.settings, salv.lineSelection, s));
        this.map(s, `\`alv( ${salv.table} )\`${salv.settings.length ? " with the column settings" : ""}`);
        return;
      }
      if (plan.action === "code") {
        out.push(...plan.lines);
        this.map(s, plan.reason);
        return;
      }
      if (plan.action === "grid") {
        const settings = [];
        const title = plan.layoutVar && this.layoutTitle.get(plan.layoutVar);
        if (title) settings.push({ m: "set_title", arg: title });
        for (const c of this.fcat.get(plan.fieldcatVar) ?? []) {
          if (!c.name) continue;
          if (c.text) settings.push({ m: "set_column_text", name: c.name, arg: c.text });
          if (c.hidden) settings.push({ m: "set_column_hidden", name: c.name });
          if (c.hotspot) settings.push({ m: "set_column_hotspot", name: c.name });
          if (c.sum) settings.push({ m: "set_column_sum", name: c.name });
        }
        for (const h of this.gridHandlers.filter((x) => x.event === "toolbar")) settings.push(...this.gridToolbar(h));
        if (this.gridSelection) settings.push({ m: "set_selection_mode" });
        const lineSelection = this.gridHandlers.some((x) => x.event === "double_click");
        if (this.gridHandlers.some((x) => x.event === "hotspot_click") && !settings.some((x) => x.m === "set_column_hotspot")) {
          this.todo(s, "the grid has a HOTSPOT_CLICK handler, and the field catalog marks no column as hotspot - set_column_hotspot( ) for the columns it is meant for");
        }
        out.push(...this.alvChain(plan.table, plan.tableNode.getFirstToken(), settings, lineSelection, s));
        for (const t of plan.todos ?? []) this.todo(s, t);
        this.map(s, `\`alv( ${plan.table} )\` - set_table_for_first_display( ) of the grid${settings.length ? ", the field catalog, the title and the toolbar in the chain" : ""}`);
        return;
      }
      if (plan.action === "reuse") {
        const settings = [...plan.settings];
        for (const c of this.fcat.get(plan.fieldcatVar) ?? []) {
          if (!c.name) continue;
          if (c.text) settings.push({ m: "set_column_text", name: c.name, arg: c.text });
          if (c.hidden) settings.push({ m: "set_column_hidden", name: c.name });
          if (c.hotspot) settings.push({ m: "set_column_hotspot", name: c.name });
          if (c.sum) settings.push({ m: "set_column_sum", name: c.name });
        }
        out.push(...this.alvChain(plan.table, plan.tableNode.getFirstToken(), settings, plan.lineSelection, s));
        for (const t of plan.todos ?? []) this.todo(s, t);
        if (plan.lineSelection) this.todo(s, `${plan.fm}: the USER_COMMAND callback is the row click now - its FORM is converted into at_line_selection( )`);
        this.map(s, `\`alv( ${plan.table} )\``);
        return;
      }
    }

    if (b.ctx.pai) {
      const t = lc(renderTokens(stmtTokens(s)));
      const toks = stmtTokens(s).map((x) => lc(x.getStr())).filter((x) => x !== "," && x !== ":");
      if (k === "Clear" && toks.slice(1).every((x) => this.okVars.has(x))) {
        this.map(s, "dropped - the OK code is ucomm, a parameter");
        return;
      }
      if (k === "Move" && toks.length === 3 && this.okVars.has(toks[0]) && (this.okVars.has(toks[2]) || toks[2] === "sy-ucomm")) {
        this.map(s, "dropped - the OK code is ucomm, a parameter");
        return;
      }
      if (k === "SetScreen" || (k === "Leave" && /^leave\s+(to\s+screen\s+0|program|to\s+list-processing)$/.test(t))) {
        if (k === "SetScreen" && !/^set\s+screen\s+0+$/.test(t)) {
          this.refuse(s, "SET SCREEN of another screen - one screen is converted");
          return;
        }
        out.push("leave_to_selection_screen( ).");
        this.map(s, "`leave_to_selection_screen( )` - the screen of the grid is left");
        return;
      }
      if (k === "Leave" && /^leave\s+screen$/.test(t)) {
        this.map(s, "dropped - the screen is left by leave_to_selection_screen( )");
        return;
      }
    }
    if (this.dynpro && this.dynproStatement(s, b, k)) return;
    if (this.guiVars?.size) {
      const t = lc(renderTokens(stmtTokens(s)));
      // FOR ALL INSTANCES of a handler of a control event too - it must not stay and never fire
      const allOfGui = /\bfor\s+all\s+instances\b/.test(t)
        && children(s, "MethodSource").some((m) => (this.guiHandlers().get(lc(nodeText(m)).replace(/^.*(->|=>)\s*/, "")) ?? []).some((h) => guiClass(h.of)));
      if (k === "SetHandler" && (allOfGui || [...this.guiVars.keys()].some((v) => new RegExp(`\\bfor\\s+(me\\s*->\\s*)?${v}\\b`).test(t)))) {
        this.guiSetHandler(s, b);
        return;
      }
      // refresh_table_display( ) of the grid stand-in needs the table
      const refresh = /(?:([\w/]+)\s*->\s*)?([\w/]+)\s*->\s*refresh_table_display\b/.exec(t);
      const foreign = refresh?.[1] && refresh[1] !== "me";
      if (refresh && (this.guiVars.get(refresh[2]) === "z2ui5_cl_cgui_gui_alv_grid" || refresh[2] === "sender") && (foreign || !this.gridOuttab(refresh[2], b.ctx))) {
        this.refuse(s, `SAP GUI controls: ${refresh[2]}->refresh_table_display( ) - the grid shows a copy of its table, and the table set_table_for_first_display( ) gave it is not in reach here; pass it: CHANGING it_outtab = ...`);
        return;
      }
      const bad = !DECL.has(k) && this.guiCheck(s);
      if (bad) {
        this.refuse(s, `SAP GUI controls: ${bad} - port this statement by hand`);
        return;
      }
      if (/^(call\s+method\s+)?cl_gui_cfw\s*=>\s*(flush|update_view)\b/.test(t)) {
        this.map(s, "dropped - cl_gui_cfw=>flush( ): the controls of SAP GUI, nothing to flush in the browser");
        return;
      }
    }
    if (REFUSED[k]) {
      this.refuse(s, REFUSED[k]);
      return;
    }
    if (LAYOUT_ONLY[k]) {
      this.note(LAYOUT_ONLY[k]);
      this.map(s, "dropped - layout only");
      return;
    }

    switch (k) {
      case "Write": {      // WRITE ... TO
        const src = child(s, "Source");
        const target = child(s, "Target");
        const ov = this.rewrites(s, b.ctx);
        out.push(`${nodeText(target, ov)} = |{ ${nodeText(src, ov)} }|.`);
        this.todo(s, "WRITE ... TO: converted to a string template - WRITE TO formats dates, times and numbers in the user's format; add DATE = USER / NUMBER = USER where it matters");
        this.map(s, "string template");
        return;
      }
      case "Position": {
        const n = child(s, "Source");
        this.listCall(b, "position", [{ value: nodeText(n, this.rewrites(s, b.ctx)) }]);
        this.map(s, "`list( )->position( )` - the next write( ) starts at that column");
        return;
      }
      case "Reserve": {
        const n = child(s, "Source");
        this.listCall(b, "reserve", [{ value: nodeText(n, this.rewrites(s, b.ctx)) }]);
        this.map(s, "`list( )->reserve( )` - a new page when fewer lines are left (LINE-COUNT)");
        return;
      }
      case "Window": {
        if (!b.ctx.lineSelection) {
          this.refuse(s, "WINDOW outside of AT LINE-SELECTION - window( ) shows the secondary list a line selection writes in a dialog box");
          return;
        }
        const ov = this.rewrites(s, b.ctx);
        const src = findAll(s, "Source").filter((n) => s.getChildren().includes(n)).map((n) => nodeText(n, ov));
        const diff = (a, z) => (/^\d+$/.test(a) && /^\d+$/.test(z) ? String(Number(z) - Number(a)) : `${z} - ${a}`);
        const params = [];
        if (src.length >= 4) {
          params.push({ name: "columns", value: diff(src[0], src[2]) });
          params.push({ name: "lines", value: diff(src[1], src[3]) });
        }
        b.out.push(params.length ? renderNamedCall("window", params) : "window( ).");
        this.map(s, "`window( )` - the secondary list in a dialog box, ENDING AT minus STARTING AT its size");
        return;
      }
      case "NewLine":
        this.listCall(b, "new_line", []);
        this.map(s, "`list( )->new_line( )`");
        return;
      case "Skip": {
        if (words(s).includes("TO")) {
          const n = child(s, "Source");
          this.listCall(b, "skip_to_line", [{ value: nodeText(n, this.rewrites(s, b.ctx)) }]);
          this.map(s, "`list( )->skip_to_line( )` - empty lines up to that line of the page");
          return;
        }
        const n = child(s, "Source");
        this.listCall(b, "skip", n && nodeText(n) !== "1" ? [{ value: nodeText(n, this.rewrites(s, b.ctx)) }] : []);
        this.map(s, "`list( )->skip( )`");
        return;
      }
      case "Uline":
        if (child(s, "WriteOffsetLength")) this.note("ULINE AT pos(len) - the line spans the list");
        this.listCall(b, "uline", []);
        this.map(s, "`list( )->uline( )`");
        return;
      case "NewPage": {
        const w = words(s);
        if (hasSeq(w, "PRINT", "ON") || hasSeq(w, "PRINT", "OFF")) {
          this.refuse(s, "NEW-PAGE PRINT ON - printing is not supported");
          return;
        }
        // the options as words: NO-HEADING, LINE-COUNT 20, ...
        const opts = w.slice(3).join(" ").replace(/ - /g, "-").split(" ").filter(Boolean);
        const params = [];
        if (opts.includes("NO-HEADING")) params.push({ name: "no_heading", value: "abap_true" });
        const count = child(s, "Source");
        if (opts.includes("LINE-COUNT") && count) params.push({ name: "line_count", value: nodeText(count, this.rewrites(s, b.ctx)) });
        if (opts.some((x) => !["NO-HEADING", "WITH-HEADING", "LINE-COUNT"].includes(x))) {
          this.note("NEW-PAGE options other than NO-HEADING and LINE-COUNT (NO-TITLE, LINE-SIZE, ...) - dropped");
        }
        this.listCall(b, "new_page", params);
        this.map(s, this.events.some((e) => e.kind === "TopOfPage") && !params.some((p) => p.name === "no_heading")
          ? "`list( )->new_page( )` - the runtime repeats the TOP-OF-PAGE header on the new page"
          : "`list( )->new_page( )`");
        return;
      }
      case "Format":
        this.format(s, b);
        return;
      case "Hide":
        this.hide(s, b);
        return;
      case "Message":
        this.message(s, b);
        return;
      case "Perform":
        this.perform(s, b);
        return;
      case "LoopAtScreen": {
        if (b.screenLoopDepth >= 0) {
          this.refuse(s, "LOOP AT SCREEN inside of LOOP AT SCREEN - the screen has one loop at a time");
          return;
        }
        // in a method of a local class, or an event block other than AT
        // SELECTION-SCREEN OUTPUT: the screen of that event while it runs -
        // elsewhere one built afresh, whose changes are not shown
        b.screenSrc = b.ctx.screenEvent ? "screen" : "current_screen( )";
        if (!b.ctx.screenEvent && !b.ctx.local) {
          this.todo(s, "LOOP AT SCREEN outside of AT SELECTION-SCREEN OUTPUT - current_screen( ) is a screen built afresh here, its changes are not shown (as MODIFY SCREEN outside of PBO is not); move the loop to at_selection_screen_output( )");
        }
        const t = lc(renderTokens(stmtTokens(s)));
        const m = /into\s+(?:data\s*\(\s*)?([\w/]+)/.exec(t);
        if (/assigning/.test(t)) {
          this.refuse(s, "LOOP AT SCREEN ASSIGNING - field symbols to screen fields are not converted; use LOOP AT SCREEN with MODIFY SCREEN");
          return;
        }
        b.screenWa = m && /data\s*\(/.test(t) ? m[1] : "ls_screen";
        if (m && !/data\s*\(/.test(t)) {
          this.refuse(s, "LOOP AT SCREEN INTO a declared work area of type SCREEN - write LOOP AT SCREEN (or INTO DATA( ))");
          return;
        }
        b.screenLoopDepth = b.loopDepth;
        b.loopDepth++;
        const tab = this.identifiers.has("lt_screen") ? "lt_r2c_screen" : "lt_screen";
        this.screenTabs ??= new Set();
        const again = this.screenTabs.has(`${b.ctx.method}:${tab}`);
        this.screenTabs.add(`${b.ctx.method}:${tab}`);
        // a second LOOP AT SCREEN of the method reuses the table and the work area
        out.push(again ? `${tab} = ${b.screenSrc}->loop_at_screen( ).` : `DATA(${tab}) = ${b.screenSrc}->loop_at_screen( ).`,
          again ? `LOOP AT ${tab} INTO ${b.screenWa}.` : `LOOP AT ${tab} INTO DATA(${b.screenWa}).`);
        this.map(s, "`LOOP AT screen->loop_at_screen( ) INTO DATA(ls_screen)` - screen-* is ls_screen-*, '0'/'1' are abap_false/abap_true");
        return;
      }
      case "ModifyScreen": {
        if (b.screenLoopDepth < 0) {
          this.refuse(s, "MODIFY SCREEN outside of LOOP AT SCREEN");
          return;
        }
        const t = lc(renderTokens(stmtTokens(s)));
        const m = /from\s+([\w/]+)/.exec(t);
        out.push(`${b.screenSrc ?? "screen"}->modify_screen( ${m ? m[1] : b.screenWa} ).`);
        this.map(s, "`screen->modify_screen( ls_screen )`");
        return;
      }
      case "Loop": case "Do": case "While": case "LoopExtract": case "Provide":
        b.loopDepth++;
        if (k === "Loop") {
          const lines = this.loopWhereIn(s, b);
          if (lines) {
            out.push(...lines);
            return;
          }
        }
        break;
      case "EndLoop": case "EndSelect": case "EndDo": case "EndWhile": case "EndProvide":
        b.loopDepth--;
        if (b.loopDepth === b.screenLoopDepth && k === "EndLoop") {
          b.screenLoopDepth = -1;
          out.push("ENDLOOP.");
          return;
        }
        break;
      case "SetPFStatus":
        this.setPfStatus(s, b);
        return;
      case "SetTitlebar":
        this.setTitlebar(s, b);
        return;
      case "Leave": {
        const t = uc(renderTokens(stmtTokens(s)));
        if (/LEAVE\s+LIST-PROCESSING/.test(t)) {
          out.push("leave_to_selection_screen( ).");
          this.map(s, "`leave_to_selection_screen( )`");
          return;
        }
        if (/LEAVE\s+TO\s+LIST-PROCESSING/.test(t)) {
          this.refuse(s, "LEAVE TO LIST-PROCESSING - the list is shown after start_of_selection( ); write the output there");
          return;
        }
        if (/^LEAVE$/.test(t)) break;
        // the report is left - here the user is back on the selection screen
        if (/^LEAVE\s+(PROGRAM|TO\s+SCREEN\s+0+)$/.test(t)) {
          out.push("leave_to_selection_screen( ).", "RETURN.");
          this.map(s, "`leave_to_selection_screen( )` and `RETURN` - the user is back on the selection screen");
          if (b.ctx.form) this.todo(s, `${t} in FORM ${b.ctx.form.name}: RETURN only leaves ${b.ctx.form.method}( ) - the classic ended the report; the caller goes on, but the list it writes is not shown`);
          return;
        }
        if (/^LEAVE\s+SCREEN$/.test(t)) {
          this.map(s, "dropped - LEAVE SCREEN; the screen is left by the runtime");
          return;
        }
        this.refuse(s, `${t} - the app has no screens or transactions to leave; RETURN ends the event block, leave_to_selection_screen( ) goes back`);
        return;
      }
      case "Stop":
        // STOP ended START-OF-SELECTION and went on with END-OF-SELECTION -
        // as the runtime does after start_of_selection( ) returns
        out.push("RETURN.");
        if (b.ctx.method === "start_of_selection" || b.ctx.method === "end_of_selection") {
          this.map(s, "`RETURN` - the runtime goes on with `end_of_selection( )`, as after STOP");
          return;
        }
        this.todo(s, b.ctx.form
          ? `STOP became RETURN - in FORM ${b.ctx.form.name} it only leaves ${b.ctx.form.method}( ); the classic STOP ended START-OF-SELECTION and went on with END-OF-SELECTION`
          : "STOP became RETURN - it leaves the method, the classic STOP ended the event block");
        this.map(s, "`RETURN`");
        return;
      case "CallFunction":
        if (this.callFunction(s, b)) return;
        break;
      case "Submit":
        this.submit(s, b);
        return;
      case "CallSelectionScreen":
        this.callSelectionScreen(s, b);
        return;
      case "SetCursor": {
        const w = words(s);
        const src = child(s, "Source");
        if (w.includes("FIELD") && src) {
          out.push(`set_cursor_field( ${nodeText(src, this.rewrites(s, b.ctx))} ).`);
          this.map(s, "`set_cursor_field( )` - the selection screen opens with the cursor in that field");
          if (w.includes("OFFSET") || w.includes("LINE")) this.note("SET CURSOR FIELD ... OFFSET / LINE - the cursor goes into the field, the offset and the line are dropped");
        } else {
          this.note("SET CURSOR LINE / at a position - dropped, the list has no cursor the program sets");
          this.map(s, "dropped - SET CURSOR without FIELD");
        }
        return;
      }
      case "Call": case "CreateObject": case "Move": {
        const t = lc(renderTokens(stmtTokens(s)));
        if (/^(call\s+method\s+)?cl_progress_indicator\s*=>/.test(t)) {
          this.note("SAPGUI_PROGRESS_INDICATOR / cl_progress_indicator - dropped, the browser shows a busy indicator while the server works");
          this.map(s, "dropped - the progress indicator of SAP GUI");
          return;
        }
        // sy-lsind = n: the list the line selection writes becomes level n
        if (k === "Move" && /^sy\s*-\s*lsind\s*=/.test(t)) {
          const ov = this.rewrites(s, b.ctx);
          out.push(`set_lsind( ${nodeText(child(s, "Source"), ov)} ).`);
          this.map(s, "`set_lsind( )` - the list written becomes that level, Back returns to the one below");
          if (!b.ctx.lineSelection) this.todo(s, "sy-lsind set outside of AT LINE-SELECTION - set_lsind( ) drops the levels of the secondary lists above it; check that the classic did the same here");
          return;
        }
        {
          const refusal = this.guiRefusal(t);
          if (refusal) {
            this.refuse(s, refusal);
            return;
          }
        }
        if (/^(call\s+method\s+)?cl_gui_cfw\s*=>\s*(flush|update_view)\b/.test(t)) {
          this.map(s, "dropped - cl_gui_cfw=>flush( ): the controls of SAP GUI, nothing to flush in the browser");
          return;
        }
        if (/\bcl_gui_frontend_services\b/.test(t)) {
          const bad = this.frontendCheck(s);
          if (bad) {
            this.refuse(s, `cl_gui_frontend_services - ${bad}; z2ui5_cl_cgui_frontend has the files (file_open_dialog, gui_upload, gui_download, ...) - port this call by hand`);
            return;
          }
          this.note("cl_gui_frontend_services is z2ui5_cl_cgui_frontend - a file the user picks is uploaded in the browser (file_open_dialog( ) in an F4 opens the upload, the F4 runs again with the file), gui_download( ) is a download of the browser");
          this.map(s, "`z2ui5_cl_cgui_frontend=>...` - the same method, parameters and exceptions, for the files in the browser");
          // CALL METHOD x=>m EXPORTING ... is x=>m( EXPORTING ... ) - the
          // functional writing of the house
          const toks = stmtTokens(s);
          const at = toks.findIndex((x, i) => i > 1 && x.getStr() === "=>");
          if (/^call\s+method\b/.test(t) && at > 1 && toks[at + 1]) {
            const ov = this.rewrites(s, b.ctx, b);
            ov.set(key(toks[0]), null);
            ov.set(key(toks[1]), null);
            ov.set(key(toks[at + 1]), `${lc(toks[at + 1].getStr())}(`);
            const last = toks[toks.length - 1];
            ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()} )`);
            out.push(`${renderTokens(toks, ov, s.getColon()).trim()}.`);
            return;
          }
        }
        // CREATE OBJECT go_x EXPORTING ... - NEW #( ... ), the writing of the
        // house (use_new); with EXCEPTIONS, TYPE or AREA HANDLE, or into a
        // field symbol, it stays as it is
        const target = child(s, "Target");
        if (k === "CreateObject" && target && !/\b(exceptions|type|area)\b/.test(t) && !nodeText(target).startsWith("<")) {
          const ov = this.rewrites(s, b.ctx, b);
          // the parameters of the constructor only - not those of a call in a value
          const list = child(s, "ParameterListS");
          const params = (list ? children(list, "ParameterS") : []).map((p) => ({ name: lc(nodeText(child(p, "ParameterName"))), value: nodeText(child(p, "Source"), ov) }));
          const name = nodeText(target, ov);
          out.push(params.length ? renderNamedCall(`${name} = NEW #`, params) : `${name} = NEW #( ).`);
          const stand = this.guiVars?.get(lc(nodeText(target)));
          this.map(s, `\`${name} = NEW #( )\`${stand ? ` - the stand-in ${stand}` : ""}`);
          return;
        }
        break;
      }
      case "Assign": {
        const t = renderTokens(stmtTokens(s));
        if (/\(\s*'\(/.test(t) || /'\([\w/]+\)/.test(t)) {
          this.refuse(s, "ASSIGN of a field of another program ('(PROG)FIELD') - field symbols to screen or foreign program fields are not available in a class or on ABAP Cloud");
          return;
        }
        break;
      }
      case "Select": case "SelectLoop": {
        if (k === "SelectLoop") b.loopDepth++;
        const t = uc(renderTokens(stmtTokens(s)));
        // SELECT COUNT(*) FROM t WHERE ... is no short form - it sets sy-dbcnt
        const countOnly = /^SELECT\s+(SINGLE\s+)?COUNT\s*\(\s*\*\s*\)\s+(UP\s+TO\s+\S+\s+ROWS\s+)?FROM\b/.test(t);
        if (!/\bINTO\b|\bAPPENDING\b/.test(t) && !countOnly) {
          const tabs = findAll(s, "DatabaseTable");
          const tab = tabs.length === 1 ? lc(nodeText(tabs[0])) : undefined;
          if (!tab || !this.tablesKept.has(tab) || findAll(s, "SQLJoin").length) {
            this.refuse(s, "SELECT without INTO - the short form reads into the TABLES work area, which classes do not have; add INTO");
            return;
          }
          // the TABLES work area is an attribute of the class: INTO it
          this.shortForm ??= new Map();
          this.shortForm.set(s, { tab, star: !findAll(s, "SQLField").length });
          this.map(s, `\`SELECT ... INTO @${tab}\` - the short form read into the TABLES work area, an attribute of the class now`);
        }
        break;
      }
      case "Tables":
        this.refuse(s, "TABLES inside a FORM or event block");
        return;
      case "Ranges": {
        const name = lc(declName(s));
        const forText = lc(nodeText(child(s, "SimpleFieldChain2")));
        const root = forText.split("-")[0];
        const like = this.currentLocals.has(root) || (this.globalData.has(root) && (!this.isTables(root) || this.tablesKept.has(root)));
        out.push(`DATA ${name} ${like ? "LIKE" : "TYPE"} RANGE OF ${forText}.`);
        this.map(s, "`DATA ... RANGE OF`");
        return;
      }
      case "Data": {
        const name = lc(declName(s) ?? "");
        if (this.salvVars.has(name) || this.fcatVars.has(name) || this.layoutVars.has(name)
          || this.gridVars.has(name) || this.contVars.has(name) || this.handlerVars.has(name) || this.fkeyVars?.has(name)) {
          this.map(s, "dropped - the ALV object, field catalog or layout is the alv( ) chain now");
          return;
        }
        const t = uc(renderTokens(stmtTokens(s)));
        if (this.guiRefusal(t)) {
          this.refuse(s, this.guiRefusal(t));
          return;
        }
        const ov = this.rewrites(s, b.ctx);
        this.likeToType(s, ov);
        this.tableKey(s, ov);
        const after = b.localWa.has(name) ? this.headerDecl(s, ov, { wa: b.localWa.get(name) }) : [];
        out.push(`${renderTokens(stmtTokens(s), ov, s.getColon()).replace(/^(\w+)(\s*):\s*/, "$1 ")}.`);
        out.push(...after);
        return;
      }
      default:
        break;
    }

    // the screen loop: assignments to unsupported SCREEN fields are dropped
    if (b.screenLoopDepth >= 0) {
      const t = lc(renderTokens(stmtTokens(s)));
      const m = /\bscreen\s*-\s*(\w+)/g;
      let hit;
      while ((hit = m.exec(t))) {
        if (!SCREEN_FIELDS.has(hit[1])) {
          if (k === "Move" && t.startsWith("screen")) {
            this.todo(s, `SCREEN-${uc(hit[1])} has no counterpart (only name, group1, active, input, required, invisible) - the assignment is dropped`);
            this.map(s, "dropped - SCREEN field without a counterpart");
            return;
          }
          this.refuse(s, `SCREEN-${uc(hit[1])} has no counterpart - loop_at_screen( ) has name, group1, active, input, required and invisible`);
          return;
        }
      }
    }

    // the header line of a select-option or RANGES table
    if (this.headerLine(s, b)) return;

    // copied as it is written, with its tokens rewritten
    const ov = this.rewrites(s, b.ctx, b);
    const text = renderTokens(stmtTokens(s), ov, s.getColon()).replace(/^([\w-]+)(\s*):\s*/, "$1 ");
    out.push(`${text}.`);
  }

  /** whether `n` names a table with a header line in the body being written:
   *  a global one (a select-option, RANGES, a DATA with OCCURS or WITH
   *  HEADER LINE) not shadowed by a local, a FORM's own, or a TABLES
   *  parameter used with its header line */
  hasHeader(n) {
    const b = this.currentBody;
    if (b?.localWa?.has(n) || b?.headerParams?.has(n)) return true;
    return this.headerTables.has(n) && !this.currentLocals?.has(n);
  }

  /** a DATA table with a header line (not a select-option or RANGES, whose
   *  bare name stays the range table: `x IN s_id`, `lines( s_id )`) */
  isDataHeader(n) {
    const b = this.currentBody;
    if (b?.localWa?.has(n) || b?.headerParams?.has(n)) return true;
    return this.globalHeader.has(n) && !this.currentLocals?.has(n);
  }

  /** the work area that stands for the header line of `tab` in body `b` */
  headerWa(b, tab) {
    if (b.localWa?.has(tab)) return b.localWa.get(tab);
    const global = this.globalHeader.get(tab);
    if (global && !this.currentLocals?.has(tab)) return global.wa;
    return this.useWa(b.ctx.method, tab);
  }

  /** a statement that names a table with a header line alone - its header
   *  line is written by headerLine( ) */
  headerLineTouches(s) {
    const names = stmtTokens(s).map((t) => lc(t.getStr()));
    return names.some((n, i) => this.hasHeader(n) && names[i + 1] !== "-"
      && (i === 0 || !["-", "->", "=>", "~"].includes(names[i - 1])));
  }

  /** a chained statement of a body, kept chained */
  renderChainGroup(all, b) {
    const colon = all[0].getColon();
    const group = all.filter((s) => {
      const name = lc(declName(s) ?? "");
      const alv = kind(s) === "Data" && (this.salvVars.has(name) || this.fcatVars.has(name) || this.layoutVars.has(name) || this.isGridObject(name));
      if (alv) this.map(s, "dropped - the ALV object, field catalog or layout is the alv( ) chain now");
      return !alv;
    });
    if (!group.length) return undefined;
    const prefix = renderTokens(stmtTokens(group[0]).filter((t) => t.getRow() < colon.getRow() || (t.getRow() === colon.getRow() && t.getCol() < colon.getCol())));
    if (["Clear", "Free", "Refresh"].includes(kind(group[0]))) {
      const parts = group.map((s) => renderTokens(partTokens(s), this.rewrites(s, b.ctx, b)));
      const line = `${prefix}: ${parts.join(", ")}.`;
      if (line.length <= 120) return line;
    }
    const lines = [`${prefix}:`];
    const after = [];
    let depth = 1;
    group.forEach((s, idx) => {
      const k = kind(s);
      if (/End$/.test(k)) depth--;
      const ov = this.rewrites(s, b.ctx, b);
      this.likeToType(s, ov);
      this.tableKey(s, ov);
      const name = lc(declName(s) ?? "");
      if (k === "Data" && b.localWa?.has(name)) after.push(...this.headerDecl(s, ov, { wa: b.localWa.get(name) }));
      const pad = "  ".repeat(depth);
      lines.push(`${pad}${renderTokens(partTokens(s), ov).replace(/\n/g, `\n${pad}`)}${idx === group.length - 1 ? "." : ","}`);
      if (/Begin$/.test(k)) depth++;
    });
    return [...lines, ...after].join("\n");
  }

  addPrelude(method, line) {
    if (!this.prelude.has(method)) this.prelude.set(method, []);
    if (!this.prelude.get(method).includes(line)) this.prelude.get(method).push(line);
  }

  /** the work area that stands for the header line of a select-option or
   *  RANGES table in a method */
  useWa(method, name) {
    const wa = (this.identifiers.has(`ls_${name}`) ? `ls_r2c_${name}` : `ls_${name}`).slice(0, 30);
    if (!this.methodWa.has(method)) this.methodWa.set(method, new Map());
    this.methodWa.get(method).set(name, wa);
    return wa;
  }

  /** APPEND s. / CLEAR s. / REFRESH s. / LOOP AT s. / READ TABLE s ... /
   *  MODIFY s. / INSERT s. / COLLECT s. of a table with header line - true
   *  when the statement was written here */
  headerLine(s, b) {
    const k = kind(s);
    const toks = stmtTokens(s);
    const names = toks.map((t) => lc(t.getStr()));
    const tab = names.find((n, i) => this.hasHeader(n) && (i === 0 || !["-", "->", "=>", "~"].includes(names[i - 1])));
    if (!tab) return false;
    const ov = this.rewrites(s, b.ctx, b);
    const text = () => renderTokens(toks, ov, s.getColon()).replace(/^([\w-]+)(\s*):\s*/, "$1 ");
    const has = (...w) => w.some((x) => names.includes(x));
    const wa = () => this.headerWa(b, tab);
    if (k === "Append" && names.length === 2 && names[1] === tab) {
      b.out.push(`APPEND ${wa()} TO ${tab}.`);
      this.map(s, `\`APPEND ${wa()} TO ${tab}\` - the header line is a work area`);
      return true;
    }
    if (k === "Refresh" && names.length === 2 && names[1] === tab) {
      b.out.push(`CLEAR ${tab}.`);
      return true;
    }
    if (k === "Clear" && names.length === 2 && names[1] === tab) {
      b.out.push(`CLEAR ${wa()}.`);
      this.map(s, `\`CLEAR ${wa()}\` - the header line is a work area`);
      return true;
    }
    if ((k === "Loop" || k === "ReadTable") && !has("into", "assigning", "reference", "transporting")) {
      const src = child(s, k === "Loop" ? "LoopSource" : "SimpleSource2");
      if (src && lc(nodeText(src)) === tab) {
        const last = src.getLastToken();
        if (k === "Loop") ov.set(key(last), `${last.getStr()} INTO ${wa()}`);
        b.out.push(k === "Loop" ? `${text()}.` : `${text()} INTO ${wa()}.`);
        this.map(s, `\`INTO ${wa()}\` - the header line is a work area`);
        return true;
      }
    }
    // COLLECT itab. -> COLLECT wa INTO itab.
    if (k === "Collect" && names.length === 2 && names[1] === tab) {
      b.out.push(`COLLECT ${wa()} INTO ${tab}.`);
      this.map(s, `\`COLLECT ${wa()} INTO ${tab}\` - the header line is a work area`);
      return true;
    }
    // MODIFY itab [INDEX n] [TRANSPORTING ...]. -> MODIFY itab FROM wa ... (the
    // short form in a LOOP changes the current line, as it did)
    if (k === "ModifyInternal" && names[1] === tab && !has("from")) {
      ov.set(key(toks[1]), `${tab} FROM ${wa()}`);
      b.out.push(`${text()}.`);
      this.map(s, `\`MODIFY ${tab} FROM ${wa()}\` - the header line is a work area`);
      return true;
    }
    // INSERT itab [INDEX n]. -> INSERT wa INTO itab INDEX n (the short form
    // in a LOOP inserts before the current line: INDEX sy-tabix; the parser
    // reads the bare `INSERT itab.` as a database insert)
    if ((k === "InsertInternal" || (k === "InsertDatabase" && names.length === 2)) && names[1] === tab && !has("into", "lines")) {
      const at = names.indexOf("index");
      const index = at >= 0 ? renderTokens(toks.slice(at + 1), ov) : (b.loopDepth > 0 ? "sy-tabix" : undefined);
      b.out.push(index ? `INSERT ${wa()} INTO ${tab} INDEX ${index}.` : `INSERT ${wa()} INTO TABLE ${tab}.`);
      this.map(s, `\`INSERT ${wa()} INTO ${tab}\` - the header line is a work area`);
      return true;
    }
    return false;
  }

  catchInto(s) {
    const t = renderTokens(stmtTokens(s));
    const m = /\bINTO\s+(.+)$/i.exec(t);
    return m ? ` INTO ${m[1]}` : "";
  }

  /**
   * The token rewrites of a statement in its method: text symbols become
   * literals, sy-ucomm the ucomm parameter, screen-* the line of
   * loop_at_screen( ), icons of type pool ICON the UI5 icon.
   */
  rewrites(s, ctx = {}, b = undefined) {
    const ov = new Map();
    for (const te of findAll(s, "TextElement")) {
      const toks = te.getTokens();
      ov.set(key(toks[0]), this.textSymbol(nodeText(child(te, "TextElementKey")), undefined, s));
      for (const t of toks.slice(1)) ov.set(key(t), null);
    }
    for (const te of findAll(s, "TextElementString")) {
      const toks = te.getTokens();
      const keyText = nodeText(child(te, "TextElementKey"));
      ov.set(key(toks[0]), this.textSymbol(keyText, unquote(toks[0].getStr()), s));
      for (const t of toks.slice(1)) ov.set(key(t), null);
    }
    const toks = stmtTokens(s);
    let parents;
    for (let i = 0; i < toks.length; i++) {
      const t = lc(toks[i].getStr());
      const prev = i > 0 ? toks[i - 1].getStr() : "";
      // a component follows a Dash that touches its neighbours (wa-f); a
      // subtraction's dash has blanks around it (WDashW) and the name after
      // it is an operand of its own
      const component = (prev === "-" && toks[i - 1].constructor.name === "Dash") || prev === "->" || prev === "=>" || prev === "~";
      if (component) continue;
      // cl_gui_textedit, cl_gui_custom_container, ... - their stand-ins
      if (this.guiVars?.size && guiClass(t)) {
        ov.set(key(toks[i]), guiClass(t));
        continue;
      }
      // cntb_btype_sep of type pool CNTB - the constant of the toolbar's stand-in
      if (this.guiVars?.size && /^cntb_btype_\w+$/.test(t) && guiMember("z2ui5_cl_cgui_gui_toolbar", t)) {
        ov.set(key(toks[i]), `z2ui5_cl_cgui_gui_toolbar=>${t}`);
        continue;
      }
      // cl_gui_frontend_services=>gui_upload, =>action_ok - the frontend
      // services of the runtime, when it has that member
      if (t === "cl_gui_frontend_services" && toks[i + 1]?.getStr() === "=>" && frontendMember(toks[i + 2]?.getStr())) {
        ov.set(key(toks[i]), "z2ui5_cl_cgui_frontend");
        continue;
      }
      const next = toks[i + 1]?.getStr();
      const next2 = lc(toks[i + 2]?.getStr() ?? "");
      if ((ctx.userCommand || ctx.ucomm) && (t === "sy" || t === "sscrfields") && next === "-" && next2 === "ucomm") {
        if (t === "sy" || ctx.ucomm) {
          ov.set(key(toks[i]), "ucomm");
          ov.set(key(toks[i + 1]), null);
          ov.set(key(toks[i + 2]), null);
        }
      }
      if (ctx.pai && this.okVars.has(t)) ov.set(key(toks[i]), "ucomm");
      // DATA( x ) of an inline declaration that became an attribute
      if (t === "data" && toks[i + 1]?.getStr() === "(" && this.hoisted?.size) {
        const h = this.hoisted.get(lc(toks[i + 2]?.getStr() ?? ""));
        if (h && h.keys.has(key(toks[i]))) {
          ov.set(key(toks[i]), null);
          ov.set(key(toks[i + 1]), null);
          ov.set(key(toks[i + 3]), null);
        }
      }
      // in a method of a local class: the report's data through the
      // instance, its constants and types through the class
      if (ctx.local && !ctx.local.declared.has(t) && !this.currentLocals?.has(t) && !ov.has(key(toks[i])) && !this.movedTypes.has(t)) {
        parents ??= tokenParents(s);
        const parent = parents.get(key(toks[i]));
        if (parent === "TypeName" && this.globalTypes.has(t)) ov.set(key(toks[i]), `${this.className}=>${toks[i].getStr()}`);
        else if (parent === "Field" && this.globalConstants.has(t)) ov.set(key(toks[i]), `${this.className}=>${toks[i].getStr()}`);
        else if (parent === "Field" && this.globalData.has(t)) ov.set(key(toks[i]), `${this.appRef}->${toks[i].getStr()}`);
      }
      if (ctx.subrc?.has(s) && t === "sy" && next === "-" && next2 === "subrc") {
        ov.set(key(toks[i]), "subrc");
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
      }
      // a checkbox or radio button of a dynpro is an abap_bool: 'X' and ' ' are abap_true and abap_false
      if (this.isDynproFlag(t) && ["=", "<>", "eq", "ne"].includes(lc(next ?? ""))) {
        const lit = toks[i + 2]?.getStr() ?? "";
        if (/^'X'$/i.test(lit)) ov.set(key(toks[i + 2]), "abap_true");
        else if (/^(' '|''|space)$/i.test(lit)) ov.set(key(toks[i + 2]), "abap_false");
      }
      if (ctx.ucommVar && t === "sy" && next === "-" && next2 === "ucomm") {
        // a PAI module: the OK code field of its screen holds the function
        ov.set(key(toks[i]), ctx.ucommVar);
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
      }
      if (t === "sy" && next === "-" && next2 === "ucomm" && !(ctx.userCommand || ctx.ucomm || ctx.ucommVar) && !this.ucommTodo?.has(s) && !DECL.has(kind(s))) {
        this.ucommTodo = new Set([...(this.ucommTodo ?? []), s]);
        this.todo(s, "sy-ucomm is not set by abap-cloud-gui - the user command arrives as ucomm in at_user_command( ); pass it to where it is read");
      }
      if (t === "sy" && next === "-" && ["repid", "cprog"].includes(next2)) {
        // in a class sy-repid is the class pool (ZCL_X=====CP) - and the
        // transpiled runtime has none; the report read its own name
        ov.set(key(toks[i]), `'${uc(this.programName)}'`);
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
        if (!this.repidNoted) {
          this.repidNoted = true;
          this.note(`sy-repid / sy-cprog are the name of the report, '${uc(this.programName)}' - in a class they name the class pool`);
        }
      }
      // the column and line the list writes at next, the level of the list
      if (t === "sy" && next === "-" && ["colno", "linno", "lsind"].includes(next2)) {
        ov.set(key(toks[i]), { colno: "list( )->current_column( )", linno: "list( )->current_line( )", lsind: "lsind( )" }[next2]);
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
      }
      if (ctx.lineSelection && t === "sy" && next === "-" && ["lilli", "curow"].includes(next2)) {
        ov.set(key(toks[i]), "row");
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
      }
      if (ctx.lineSelection && t === "sy" && next === "-" && next2 === "lisel") {
        ov.set(key(toks[i]), "lisel( )");
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
      }
      if (t === "sy" && next === "-" && next2 === "pagno") {
        // the header and footer are written once - &PAGE& is the number of
        // the page they stand on
        ov.set(key(toks[i]), ctx.page ? "z2ui5_cl_cgui_list=>cv_page" : "list( )->current_page( )");
        ov.set(key(toks[i + 1]), null);
        ov.set(key(toks[i + 2]), null);
      }
      if (b && this.hasHeader(t)) {
        if (next === "-") ov.set(key(toks[i]), this.headerWa(b, t));
        else if (next === "[" && toks[i + 2]?.getStr() === "]") {
          ov.set(key(toks[i + 1]), null);
          ov.set(key(toks[i + 2]), null);
        } else if (this.isDataHeader(t) && headerLineContext(s, toks, i)) ov.set(key(toks[i]), this.headerWa(b, t));
      }
      if (b && b.screenLoopDepth >= 0 && t === "screen" && next === "-") {
        ov.set(key(toks[i]), b.screenWa);
        const field = next2;
        // screen-active = '0' / 1 -> abap_false / abap_true
        const op = toks[i + 3];
        const val = toks[i + 4];
        if (SCREEN_FLAGS.has(field) && op && ["=", "EQ", "<>", "NE"].includes(uc(op.getStr())) && val) {
          const v = val.getStr().replace(/['`]/g, "");
          if (v === "0" || v === "1") ov.set(key(val), v === "1" ? "abap_true" : "abap_false");
          else if (!/^abap_/i.test(v)) this.todo(s, `SCREEN-${uc(field)} is an abap_bool here, not '0' / '1' - check the value ${val.getStr()}`);
        }
        if (field === "name" && op && val && /^'[\w/]+-(LOW|HIGH)'$/i.test(val.getStr())) {
          ov.set(key(val), `'${uc(val.getStr().slice(1, -1).replace(/-(LOW|HIGH)$/i, ""))}'`);
        }
      }
      if (LVC_TYPES[t] && ["type", "of", "like"].includes(lc(prev))) {
        ov.set(key(toks[i]), LVC_TYPES[t]);
        if (/^lvc_/.test(t) && !this.lvcNoted) {
          this.lvcNoted = true;
          this.note("LVC_T_ROW / LVC_S_ROW / LVC_T_ROID - the row types of the classic grid are the types of z2ui5_cl_cgui_alv, with index and row_id as before");
        }
      }
      if (ICONS[t] && !this.globalData.has(t) && !this.currentLocals?.has(t)) {
        ov.set(key(toks[i]), literal(ICONS[t]));
      }
    }
    // x IN range in a condition: range_check( ) - see inCompare( )
    for (const cmp of findAll(s, "Compare")) {
      const text = this.inCompare(cmp, ov);
      if (text === undefined) continue;
      const toks = cmp.getTokens();
      ov.set(key(toks[0]), text);
      for (const t of toks.slice(1)) ov.set(key(t), null);
      this.mapOnce(s, cmp, "`z2ui5_cl_cgui_context=>range_check( val range )` - IN outside ABAP SQL");
    }
    this.strictSql(s, ov);
    this.gridRewrites(toks, ov, ctx);
    return ov;
  }

  /**
   * `x [NOT] IN range` (a Compare, or the ComponentCompare of a LOOP ...
   * WHERE with `prefix` as the work area the component is read from) as a
   * call of z2ui5_cl_cgui_context=>range_check( ) - the samples' rule
   * (AGENTS.md): IN of the transpiled runtime knows I EQ, E EQ and I CP only,
   * and a select-option holds BT, GE, NE, ... On a system both are the same.
   * ABAP SQL keeps its IN (an SQLCompare). undefined when cmp is no IN on a
   * range (`IN ( a, b )` is a value list and stays).
   */
  inCompare(cmp, ov, prefix) {
    const ch = cmp.getChildren();
    const at = ch.findIndex((c) => isToken(c) && uc(c.get().getStr()) === "IN");
    if (at < 0) return undefined;
    const right = ch[at + 1];
    if (!right || isToken(right) || kind(right) !== "Source" || ch.length > at + 2) return undefined;
    const left = ch.slice(0, at).find((c) => !isToken(c));
    if (!left) return undefined;
    const negate = ch.slice(0, at).filter((c) => isToken(c) && uc(c.get().getStr()) === "NOT").length % 2 === 1;
    let val = nodeText(left, ov);
    if (prefix !== undefined) val = lc(val) === "table_line" ? prefix.replace(/(->|-)$/, "") : `${prefix}${val}`;
    return `z2ui5_cl_cgui_context=>range_check( val = ${val} range = ${nodeText(right, ov)} ) = ${negate ? "abap_false" : "abap_true"}`;
  }

  /** map( ) once per node - rewrites( ) runs more than once for a statement */
  mapOnce(s, node, target) {
    this.mappedNodes ??= new Set();
    const k = key(node.getFirstToken());
    if (this.mappedNodes.has(k)) return;
    this.mappedNodes.add(k);
    this.map(s, target);
  }

  /** LOOP AT ... WHERE with an IN on a range: the WHERE becomes a CONTINUE
   *  at the top of the loop (a method call cannot stand in a LOOP WHERE).
   *  Lines, or undefined when the loop has no such condition or no work
   *  area to read the components from. */
  loopWhereIn(s, b) {
    const cond = child(s, "ComponentCond");
    if (!cond || !findAll(cond, "ComponentCompare").some((c) => this.inCompare(c, new Map(), "") !== undefined)) return undefined;
    const target = child(s, "LoopTarget");
    if (!target) return undefined;
    const t = lc(renderTokens(target.getTokens()));
    let m;
    let prefix;
    if ((m = /^into\s+(?:data\s*\(\s*)?([\w/]+)\s*\)?$/.exec(t))) prefix = `${m[1]}-`;
    else if ((m = /^assigning\s+(?:field-symbol\s*\(\s*)?(<[\w/]+>)\s*\)?$/.exec(t))) prefix = `${m[1]}-`;
    else if ((m = /^reference\s+into\s+(?:data\s*\(\s*)?([\w/]+)\s*\)?$/.exec(t))) prefix = `${m[1]}->`;
    else return undefined;
    const ov = this.rewrites(s, b.ctx, b);
    const condOv = new Map(ov);
    for (const cc of findAll(cond, "ComponentCompare")) {
      const text = this.inCompare(cc, ov, prefix);
      const toks = cc.getTokens();
      if (text !== undefined) {
        condOv.set(key(toks[0]), text);
        for (const x of toks.slice(1)) condOv.set(key(x), null);
        continue;
      }
      for (const chain of findAll(cc, "ComponentChainSimple")) {
        const first = chain.getFirstToken();
        const name = lc(first.getStr());
        condOv.set(key(first), name === "table_line" ? prefix.replace(/(->|-)$/, "") : `${prefix}${first.getStr()}`);
      }
    }
    const toks = stmtTokens(s);
    const whereAt = toks.findIndex((x) => uc(x.getStr()) === "WHERE" && !cond.getTokens().includes(x));
    const head = renderTokens(toks.slice(0, whereAt), ov).replace(/\s+$/, "");
    const condText = renderTokens(cond.getTokens(), condOv).replace(/\s*\n\s*/g, " ");
    const single = cond.getChildren().length === 1 && /= abap_(true|false)$/.test(condText) && !/\b(AND|OR)\b/i.test(condText);
    const skipIf = single ? condText.replace(/= abap_(true|false)$/, (m, v) => `= abap_${v === "true" ? "false" : "true"}`) : `NOT ( ${condText} )`;
    this.mapOnce(s, cond, "`LOOP AT ...` and the WHERE as `IF ... CONTINUE. ENDIF.` at the top of the loop - `range_check( )` for the IN");
    this.todo(s, "LOOP AT ... WHERE with IN on a range became a CONTINUE at the top of the loop - sy-subrc after ENDLOOP is 0 when the table has lines, also when none matched");
    return [`${head}.`, `  IF ${skipIf}.`, "    CONTINUE.", "  ENDIF."];
  }

  /** ABAP SQL in strict mode, as ABAP Cloud demands it: host variables
   *  escaped with @, the field list, ORDER BY and GROUP BY separated by
   *  commas. Syntax only - the parser tells a host variable (SQLSource,
   *  SQLTarget) from a column. A statement that escapes already is left as
   *  it is. INTO stays where the report has it: strict mode takes it in front
   *  of WHERE, and abaplint's downport cannot carry `WHERE ... INTO ... UP TO
   *  n ROWS` to 7.02. */
  strictSql(s, ov) {
    if (!["Select", "SelectLoop", "UpdateDatabase", "ModifyDatabase", "InsertDatabase", "DeleteDatabase", "OpenCursor"].includes(kind(s))) return;
    const short = this.shortForm?.get(s);
    if (short) {
      // INTO the work area right after FROM dbtab; a field list goes into
      // its components of the same name, as the short form did
      const last = findAll(s, "DatabaseTable")[0].getLastToken();
      ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()} INTO ${short.star ? "" : "CORRESPONDING FIELDS OF "}@${short.tab}`);
    }
    if (s.getTokens().some((t) => t.getStr().startsWith("@"))) return;
    const escape = (tok) => {
      const k = key(tok);
      ov.set(k, `@${ov.has(k) ? ov.get(k) : tok.getStr()}`);
    };
    let changed = false;
    for (const k of ["SQLSource", "SQLSourceSimple"]) {
      for (const src of findAll(s, k)) {
        const first = src.getChildren()[0];
        if (!first || isToken(first)) continue;
        const inner = first.getChildren()[0];
        if ((kind(first) === "Source" || kind(first) === "SimpleSource3") && inner && !isToken(inner) && kind(inner) === "FieldChain") {
          escape(src.getFirstToken());
          changed = true;
        }
      }
    }
    for (const t of findAll(s, "SQLTarget")) {
      escape(t.getFirstToken());
      changed = true;
    }
    if (short) changed = true;
    if (!changed) return;
    const comma = (tok) => {
      const k = key(tok);
      ov.set(k, `${ov.has(k) ? ov.get(k) : tok.getStr()},`);
    };
    for (const list of findAll(s, "SQLFieldList")) {
      const fields = children(list, "SQLField");
      if (fields.length < 2 || list.getTokens().some((t) => t.getStr() === ",")) continue;
      for (const f of fields.slice(0, -1)) comma(f.getLastToken());
    }
    // ORDER BY a b DESCENDING / GROUP BY a b: an item is a column and the
    // words that follow it
    for (const list of [...findAll(s, "SQLOrderBy"), ...findAll(s, "SQLGroupBy")]) {
      if (list.getTokens().some((t) => t.getStr() === ",")) continue;
      const items = [];
      for (const c of list.getChildren()) {
        if (!isToken(c)) items.push([c]);
        else if (items.length) items[items.length - 1].push(c);
      }
      for (const item of items.slice(0, -1)) comma(item[item.length - 1].getLastToken());
    }
  }

  // ----------------------------------------------------------------- list

  listCall(b, method, params) {
    const item = { method, params, positional: !params.some((p) => p.name) };
    b.out.push({ items: [item] });
    if (method !== "write") b.line = [];
  }

  format(s, b) {
    const w = words(s);
    const color = child(s, "Color");
    if (w.includes("RESET")) {
      b.color = "none";
      b.hotspot = false;
      if (b.runtimeColor) b.out.push(`CLEAR ${b.colorVar}.`);
    }
    if (color) {
      const c = color.getTokens().map((t) => uc(t.getStr()));
      if (c[1] === "=") {
        this.todo(s, "FORMAT COLOR = variable - a dynamic color is not mapped, the list writes without color");
        b.color = "none";
      } else {
        b.color = COLORS[c[1]] ?? "none";
      }
      if (b.runtimeColor) b.out.push(b.color === "none" ? `CLEAR ${b.colorVar}.` : `${b.colorVar} = ${colorConst(b.color)}.`);
    }
    const hs = w.indexOf("HOTSPOT");
    if (hs >= 0) b.hotspot = w[hs + 1] !== "OFF";
    if (w.includes("INTENSIFIED") || w.includes("INVERSE") || w.includes("INPUT") || w.includes("FRAMES")) {
      this.note("FORMAT INTENSIFIED / INVERSE / INPUT - the list knows only the color and hotspots");
    }
    this.map(s, b.runtimeColor ? "`lv_color`, passed to every `write( )` of the method" : "applied to the following `write( )` calls of the method (color, hotspot)");
  }

  /** WRITE: / a, b COLOR 5 HOTSPOT ... - one chain of the list */
  writeChain(group, b) {
    const items = [];
    for (const s of group) {
      const w = words(s);
      const ov = this.rewrites(s, b.ctx, b);
      const offs = child(s, "WriteOffsetLength");
      const slash = w.includes("/") || (offs && offs.getTokens().some((t) => t.getStr().startsWith("/")));
      if (slash) {
        items.push({ method: "new_line", params: [] });
        b.line = [];
      }
      // WRITE AT /pos(len): the column and the width of the item
      let pos;
      let len;
      if (offs) {
        const toks = offs.getTokens().filter((t) => uc(t.getStr()) !== "AT");
        let i = 0;
        const posToks = [];
        if (toks[i] && toks[i].getStr().startsWith("/")) {
          const rest = toks[i].getStr().slice(1);
          if (rest) posToks.push({ text: rest });
          i++;
        }
        while (toks[i] && toks[i].getStr() !== "(") posToks.push(toks[i++]);
        if (toks[i] && toks[i].getStr() === "(") {
          const lenToks = [];
          i++;
          while (toks[i] && toks[i].getStr() !== ")") lenToks.push(toks[i++]);
          if (lenToks.length) len = lenToks.map((t) => (t.text !== undefined ? t.text : renderTokens([t], ov))).join("").replace(/\s+/g, "");
        }
        if (posToks.length) {
          pos = posToks.map((t) => t.text ?? (ov.has(key(t)) ? ov.get(key(t)) : t.getStr())).join("");
        }
        if (len === "*" || len === "**") {
          this.note("WRITE ... (*) / (**) - the length the value needs; the list writes it in its own width");
          len = undefined;
        }
      }
      const src = child(s, "Source");
      if (!src) continue;
      const value = nodeText(src, ov);
      if (hasSeq(w, "AS", "CHECKBOX")) {
        items.push({ method: "write_as_checkbox", params: [{ value }] });
        this.map(s, "`list( )->write_as_checkbox( )`");
        continue;
      }
      if (hasSeq(w, "AS", "ICON")) {
        items.push({ method: "write_as_icon", params: [{ value }] });
        if (!/^`sap-icon:/.test(value)) this.todo(s, `WRITE ${value} AS ICON - write_as_icon( ) takes a UI5 icon (sap-icon://...), not an icon of type pool ICON; map the value`);
        this.map(s, "`list( )->write_as_icon( )`");
        continue;
      }
      const color = child(s, "Color");
      let c = b.color;
      if (color) {
        const ct = color.getTokens().map((t) => uc(t.getStr()));
        if (ct[1] === "=") {
          this.todo(s, "WRITE ... COLOR = variable - a dynamic color is not mapped");
          c = "none";
        } else c = COLORS[ct[1]] ?? "none";
      }
      let hotspot = b.hotspot;
      const hs = w.indexOf("HOTSPOT");
      if (hs >= 0) hotspot = w[hs + 1] !== "OFF";
      const lost = ["CURRENCY", "UNIT", "DECIMALS", "EDIT", "LEFT-JUSTIFIED", "CENTERED",
        "RIGHT-JUSTIFIED", "NO-ZERO", "NO-SIGN", "EXPONENT", "ROUND", "DD/MM/YY", "MM/DD/YY", "DD/MM/YYYY",
        "MM/DD/YYYY", "DDMMYY", "MMDDYY", "YYMMDD", "QUICKINFO", "INPUT", "INVERSE", "TIME", "ENVIRONMENT"];
      const joined = w.join(" ").replace(/ - /g, "-");
      for (const o of lost) {
        if (new RegExp(`(^| )${o.replace(/\//g, "\\/")}( |$)`).test(joined)) this.note(`WRITE ... ${o} - the list writes the value in its default format`);
      }
      const item = { method: "write", params: [{ name: "val", value }] };
      if (pos !== undefined && pos !== "0") item.params.push({ name: "pos", value: lc(pos) });
      if (len !== undefined) item.params.push({ name: "len", value: lc(len) });
      if (hasSeq(w, "NO", "-", "GAP")) item.params.push({ name: "no_gap", value: "abap_true" });
      // UNDER g: the column g was written at - g is written with its name
      const underAt = s.getChildren().findIndex((c) => isToken(c) && uc(c.get().getStr()) === "UNDER");
      if (underAt >= 0) {
        const g = s.getChildren()[underAt + 1];
        item.params.push({ name: "under", value: literal(underName(nodeText(g))) });
      }
      if (this.underTargets?.has(underName(nodeText(src)))) item.params.push({ name: "name", value: literal(underName(nodeText(src))) });
      if (color || !b.runtimeColor) {
        if (c !== "none") item.params.push({ name: "color", value: colorConst(c) });
      } else {
        item.params.push({ name: "color", value: b.colorVar });
      }
      if (hotspot) item.params.push({ name: "hotspot", value: "abap_true" });
      items.push(item);
      b.line.push(item);
      this.map(s, `\`write( )\`${c !== "none" ? ", color" : ""}${hotspot ? ", hotspot" : ""}`);
    }
    if (items.length) b.out.push({ items });
  }

  hide(s, b) {
    const src = child(s, "Source");
    const name = lc(nodeText(src));
    const root = name.split("-")[0];
    if (!this.globalData.has(root)) {
      this.refuse(s, `HIDE ${name} - the field is not a global field of the report, so at_line_selection( ) cannot restore it`);
      return;
    }
    let target = b.line.find((it) => it.params.some((p) => p.name === "hotspot")) ?? b.line[0];
    if (!target) {
      this.refuse(s, "HIDE without a WRITE before it in the same block - the hidden value is attached to the hotspot of the line it follows");
      return;
    }
    if (!target.params.some((p) => p.name === "hotspot")) target.params.push({ name: "hotspot", value: "abap_true" });
    target.hide = [...(target.hide ?? []), name];
    const set = target.hide.join(",");
    if (this.hideSet && !this.hideSet.startsWith(set) && !set.startsWith(this.hideSet)) {
      this.refuse(s, `HIDE of other fields (${target.hide.join(", ")}) than elsewhere (${this.hideSet}) - one set of hidden fields per report is supported`);
      return;
    }
    if (!this.hideSet || set.length > this.hideSet.length) this.hideSet = set;
    // the value of the hotspot: the field, or all fields of the line joined
    const hide = target.hide.length === 1 ? target.hide[0] : `|${target.hide.map((f) => `{ ${f} }`).join("\\t")}|`;
    target.params = target.params.filter((p) => p.name !== "hide");
    target.params.push({ name: "hide", value: hide });
    this.map(s, `\`hide = ${target.hide.join(" ")}\` at the hotspot of the line, restored in \`at_line_selection( )\``);
  }

  hideRestore() {
    if (!this.hideSet) return [];
    const fields = this.hideSet.split(",");
    if (fields.length === 1) return ["\" HIDE - the field the clicked line was written with", `${fields[0]} = hide.`];
    const lines = ["\" HIDE - the fields the clicked line was written with", "SPLIT hide AT |\\t| INTO TABLE DATA(lt_hide)."];
    fields.forEach((f, i) => lines.push(`${f} = VALUE #( lt_hide[ ${i + 1} ] OPTIONAL ).`));
    return lines;
  }

  // -------------------------------------------------------------- messages

  message(s, b) {
    const w = words(s);
    const ov = this.rewrites(s, b.ctx, b);
    if (w.includes("INTO")) {
      // MESSAGE ... INTO is no output - copied, with the message class of
      // REPORT ... MESSAGE-ID written out: a class has no MESSAGE-ID, and the
      // short form e001 names no class of its own
      const src = child(s, "MessageSource");
      const tn = src && child(src, "MessageTypeAndNumber");
      if (tn && !child(src, "MessageClass")) {
        const msgClass = this.header?.messageClass;
        if (!msgClass) {
          this.refuse(s, "MESSAGE without a message class - neither in the statement nor MESSAGE-ID of REPORT");
          return;
        }
        const last = tn.getLastToken();
        ov.set(key(last), `${ov.has(key(last)) ? ov.get(key(last)) : last.getStr()}(${lc(msgClass)})`);
        this.messageClasses = new Set([...(this.messageClasses ?? []), uc(msgClass)]);
        this.map(s, "`MESSAGE ... INTO` with the message class of MESSAGE-ID");
      }
      b.out.push(`${renderTokens(stmtTokens(s), ov)}.`);
      return;
    }
    if (w.includes("RAISING")) {
      this.refuse(s, "MESSAGE ... RAISING - classic exceptions of a FORM or function; raise a class-based exception instead");
      return;
    }
    const typeNode = after(s, "TYPE", "Source");
    const like = after(s, "LIKE", "Source");
    const msgSrc = child(s, "MessageSource");
    const textSrc = child(s, "MessageSourceSource");
    let type;
    let text;
    const lines = [];
    if (msgSrc) {
      // a message of a message class - its text comes through MESSAGE ... INTO
      const tn = child(msgSrc, "MessageTypeAndNumber");
      let head;
      if (tn) {
        const tnText = nodeText(tn);
        const cls = child(msgSrc, "MessageClass");
        const msgClass = cls ? nodeText(cls) : this.header?.messageClass;
        if (!msgClass) {
          this.refuse(s, "MESSAGE without a message class - neither in the statement nor MESSAGE-ID of REPORT");
          return;
        }
        head = `MESSAGE ${lc(tnText)}(${lc(msgClass)})`;
        type = literal(uc(tnText[0]));
        this.messageClasses = new Set([...(this.messageClasses ?? []), uc(msgClass)]);
      } else {
        head = `MESSAGE ${renderTokens(msgSrc.getTokens(), ov)}`;
        const tNode = after(msgSrc, "TYPE");
        type = tNode ? nodeText(tNode, ov) : literal("S");
        const id = after(msgSrc, "ID");
        if (id && /^'/.test(nodeText(id))) this.messageClasses = new Set([...(this.messageClasses ?? []), uc(unquote(nodeText(id)))]);
      }
      const withIdx = s.getChildren().findIndex((c) => isToken(c) && uc(c.get().getStr()) === "WITH");
      const withPart = withIdx >= 0 ? ` WITH ${children(s, "MessageSourceSource").map((n) => nodeText(n, ov)).join(" ")}` : "";
      const into = this.msgDeclared.has(b.ctx.method) ? this.msgVar : `DATA(${this.msgVar})`;
      this.msgDeclared.add(b.ctx.method);
      lines.push(`${head}${withPart} INTO ${into}.`);
      text = this.msgVar;
      this.map(s, "`MESSAGE ... INTO` + `message( )`");
    } else {
      text = nodeText(textSrc, ov);
      // MESSAGE lx_error TYPE 'I' - the text of the exception object
      // an exception object - also the one before it (lx->previous)
      const exc = /^([\w/]+)(\s*->\s*previous)*$/i.exec(text);
      if (exc && this.isExceptionVar(lc(exc[1]))) text = `${text}->get_text( )`;
      type = typeNode ? nodeText(typeNode, ov) : literal("S");
      this.map(s, "`message( )`");
    }
    type = /^'(.)'$/.test(type) ? literal(uc(type[1])) : type;
    let displayLike;
    if (like) {
      displayLike = nodeText(like, ov);
      if (/^['`][EW]['`]$/i.test(displayLike) && /^`[SI]`$/.test(type)) {
        type = literal("W");
        this.note("MESSAGE ... DISPLAY LIKE 'E' - a status or info message displayed as an error becomes a warning (shown in the popover, the run goes on)");
      }
    }
    if (type === "`S`") lines.push(`message( ${text} ).`);
    else lines.push(`message( text = ${text}\n         type = ${type} ).`);
    b.out.push(...lines);
    if (type === "`E`" || type === "`A`") {
      b.out.push("RETURN.");
      if (b.ctx.form && !b.ctx.form.module) this.todo(s, `MESSAGE TYPE ${type[1]} in FORM ${b.ctx.form.name}: the classic message ended the event block, RETURN here only leaves ${b.ctx.form.method}( ) - the runtime still stops the run, but the caller continues`);
    }
    if (type === "`X`") this.todo(s, "MESSAGE TYPE X - a dump; message( ) shows it as an abort message instead");
  }

  // -------------------------------------------------------------- PERFORM

  perform(s, b) {
    const w = words(s);
    const nameNode = child(s, "FormName");
    if (!nameNode || w.includes("IN") || child(s, "IncludeName") || hasSeq(w, "IF", "FOUND") || w.includes("ON")) {
      this.refuse(s, "PERFORM of a FORM of another program, dynamic or ON COMMIT - only FORMs of this report are converted");
      return;
    }
    const name = lc(nodeText(nameNode));
    const f = this.formByName.get(name);
    if (!f) {
      this.refuse(s, `PERFORM ${name} - no FORM ${name} in this report`);
      return;
    }
    if (this.alvCallbacks.has(name)) {
      this.refuse(s, `PERFORM ${name} - the FORM is a callback of the ALV and is not converted to a method`);
      return;
    }
    if (this.emptyForms.has(name)) {
      this.map(s, `dropped - FORM ${name} only set up the ALV`);
      return;
    }
    f.performed = true;
    const ov = this.rewrites(s, b.ctx, b);
    const tables = child(s, "PerformTables") ? children(child(s, "PerformTables")) : [];
    const using = child(s, "PerformUsing") ? children(child(s, "PerformUsing")) : [];
    const changing = child(s, "PerformChanging") ? children(child(s, "PerformChanging")) : [];
    const formTables = f.params.filter((p) => p.kind === "tables");
    const formOther = f.params.filter((p) => p.kind !== "tables");
    const actualOther = [...using, ...changing];
    if (tables.length !== formTables.length || actualOther.length !== formOther.length) {
      this.refuse(s, `PERFORM ${name} passes ${tables.length + actualOther.length} parameters, FORM ${name} has ${f.params.length}`);
      return;
    }
    const imp = [];
    const chg = [];
    if (this.screenForms().has(name)) {
      // performed elsewhere: the screen of AT SELECTION-SCREEN OUTPUT while
      // it runs (a method of a local class called from there), else one
      // built afresh - MODIFY SCREEN outside of PBO is not shown in SAP GUI either
      if (!b.ctx.screenEvent && !b.ctx.local) {
        this.todo(s, `PERFORM ${name} outside of AT SELECTION-SCREEN OUTPUT - the FORM loops at the screen; current_screen( ) is a screen built afresh here, its changes are not shown`);
      }
      imp.push({ name: "screen", value: b.ctx.screenEvent ? "screen" : "current_screen( )" });
    }
    const pairs = [...formTables.map((p, i) => [p, tables[i]]), ...formOther.map((p, i) => [p, actualOther[i]])];
    for (const [p, node] of pairs) {
      const value = nodeText(node, ov);
      // itab[] - the body of the table - is a variable as well
      const isVar = /^[\w/<>~-]+(\[\])?$/.test(value) && !/^\d+$/.test(value) && !findAll(node, "Constant").length;
      const changingParam = p.kind !== "using" || p.promoted;
      if (changingParam && !isVar) {
        this.refuse(s, `PERFORM ${name}: ${value} is passed to ${p.name}, which the FORM changes - a CHANGING parameter of the method needs a variable`);
        return;
      }
      (changingParam ? chg : imp).push({ name: p.name, value });
    }
    const call = renderCall(f.method, imp, chg);
    b.out.push(call);
    this.map(s, `\`${f.method}( )\``);
  }

  // ------------------------------------------------------------- functions

  /**
   * The synchronous popups: POPUP_TO_CONFIRM, POPUP_TO_CONFIRM_STEP and
   * POPUP_TO_DECIDE become popup_to_decide( ) with the two buttons as the
   * options (the answers 1, 2 and A are the classic ones), POPUP_GET_VALUES
   * becomes popup_get_values_sval( ) with its SVAL table. The popup opens
   * when the method returns, and the answer arrives in at_user_command( )
   * with a ucomm of its own - so the statements after the call, in their
   * branch, go on there: the event block is cut at the call.
   */
  popup(s, b, fm) {
    const out = b.out;
    const p = functionParams(s);
    const ov = this.rewrites(s, b.ctx, b);
    const arg = (name) => (p.has(name) ? this.literalArg(nodeText(p.get(name).node, ov), s) : undefined);
    const target = (name) => (p.has(name) ? nodeText(p.get(name).node, ov) : undefined);
    const joined = (...names) => names.map(arg).filter(Boolean).join(" && ` ` && ") || undefined;
    // an option of popup_to_decide( ) is a string: a text literal becomes
    // one, a field is put in a template
    const str = (v) => (/^'(?:[^']|'')*'$/.test(v) ? literal(unquote(v)) : /^`/.test(v) ? v : `|{ ${v} }|`);
    this.popupCount = (this.popupCount ?? 0) + 1;
    const ucomm = `POPUP_${this.popupCount}`;
    const prologue = [];
    let params;
    let method = "popup_to_decide";
    if (fm === "POPUP_TO_CONFIRM") {
      const question = arg("text_question");
      if (!question) {
        this.refuse(s, "POPUP_TO_CONFIRM without TEXT_QUESTION - not understood");
        return;
      }
      params = [{ name: "question", value: question }];
      params.push({ name: "options", value: `VALUE #( ( ${str(arg("text_button_1") ?? "'Yes'")} ) ( ${str(arg("text_button_2") ?? "'No'")} ) )` });
      params.push({ name: "ucomm", value: literal(ucomm) });
      if (arg("titlebar")) params.push({ name: "title", value: arg("titlebar") });
      if (target("answer")) prologue.push(`${target("answer")} = popup_answer( ).`);
    } else if (fm === "POPUP_TO_CONFIRM_STEP") {
      const question = joined("textline1", "textline2");
      if (!question) {
        this.refuse(s, "POPUP_TO_CONFIRM_STEP without TEXTLINE1 - not understood");
        return;
      }
      params = [{ name: "question", value: question }, { name: "options", value: "VALUE #( ( `Yes` ) ( `No` ) )" }, { name: "ucomm", value: literal(ucomm) }];
      if (arg("titel")) params.push({ name: "title", value: arg("titel") });
      // the classic answers were J, N and A
      if (target("answer")) prologue.push(`${target("answer")} = SWITCH #( popup_answer( ) WHEN '1' THEN 'J' WHEN '2' THEN 'N' ELSE 'A' ).`);
    } else if (fm === "POPUP_TO_DECIDE") {
      const question = joined("textline1", "textline2", "textline3");
      if (!question || !arg("text_option1") || !arg("text_option2")) {
        this.refuse(s, "POPUP_TO_DECIDE without TEXTLINE1, TEXT_OPTION1 and TEXT_OPTION2 - not understood");
        return;
      }
      params = [{ name: "question", value: question }];
      params.push({ name: "options", value: `VALUE #( ( ${str(arg("text_option1"))} ) ( ${str(arg("text_option2"))} ) )` });
      params.push({ name: "ucomm", value: literal(ucomm) });
      if (arg("titel")) params.push({ name: "title", value: arg("titel") });
      if (target("answer")) prologue.push(`${target("answer")} = popup_answer( ).`);
    } else {
      // POPUP_GET_VALUES
      method = "popup_get_values_sval";
      const fields = target("fields");
      if (!fields) {
        this.refuse(s, "POPUP_GET_VALUES without TABLES fields - not understood");
        return;
      }
      params = [{ name: "sval", value: fields }, { name: "ucomm", value: literal(ucomm) }];
      if (arg("popup_title")) params.push({ name: "title", value: arg("popup_title") });
      // the classic returncode was A for cancel, else space
      if (target("returncode")) prologue.push(`${target("returncode")} = SWITCH #( popup_answer( ) WHEN 'A' THEN 'A' ELSE space ).`);
      prologue.push(`popup_values_sval( CHANGING sval = ${fields} ).`);
    }
    if (p.has("display_cancel_button") || p.has("cancel_display")) this.note(`${fm} with DISPLAY_CANCEL_BUTTON / CANCEL_DISPLAY - the popup of the runtime has a Cancel button either way (answer A)`);
    out.push(renderNamedCall(method, params));
    // IF sy-subrc <> 0 right after the call checked its EXCEPTIONS - the
    // popup of the runtime raises none, the block is dropped
    const { branch } = this.tailOf(b);
    const first = branch.findIndex((x) => kind(x) !== "Comment");
    if (first >= 0 && kind(branch[first]) === "If" && /\bsy\s*-\s*subrc\b/i.test(renderTokens(stmtTokens(branch[first])))) {
      this.skipStmts ??= new Set();
      let depth = 0;
      for (const x of branch.slice(first)) {
        this.skipStmts.add(x);
        if (OPENERS.has(kind(x))) depth++;
        if (CLOSERS.has(kind(x))) depth--;
        if (depth === 0) break;
      }
      this.map(branch[first], `dropped - the IF sy-subrc after ${fm} checked its EXCEPTIONS, ${method}( ) raises none`);
    }
    this.map(s, `\`${method}( )\` - the answer arrives in \`at_user_command( )\` with ucomm \`${ucomm}\`, where the statements after the call go on`);
    this.continueIn(s, b, {
      field: ucomm, method: "at_user_command", ctx: { method: "at_user_command", userCommand: true }, prologue,
      what: `CALL FUNCTION '${fm}'`, where: `at_user_command( ) with ucomm ${ucomm} (popup_answer( ) is the answer)`,
    });
  }

  /**
   * The statements after the current one, in its branch, go on in another
   * method: the event block is cut at the call (CALL SELECTION-SCREEN, a
   * popup). The local data they use is declared anew there - with a TODO,
   * since a value set before the call is not there any more. Inside a
   * FORM, a loop, or when statements follow the block the call stands in,
   * nothing is cut: a TODO says where to go on.
   */
  continueIn(s, b, { field, method, ctx, prologue = [], what, where, note }) {
    const { branch, after } = this.tailOf(b);
    if (!branch.some((x) => kind(x) !== "Comment") && !after) return;
    const goOn = `the statements after it run before it shows - its answer arrives in ${where}; go on there`;
    if (b.ctx.form) {
      this.todo(s, `${what} in FORM ${b.ctx.form.name}: ${goOn}`);
      return;
    }
    if (after) {
      this.todo(s, `${what}: statements follow the block it stands in, and ${goOn}`);
      return;
    }
    if (b.blocks.some((k) => ["Loop", "Do", "While", "SelectLoop", "LoopAtScreen", "Provide"].includes(k))) {
      this.todo(s, `${what} inside a loop: the loop goes on before it shows - its answer arrives in ${where}; go on there`);
      return;
    }
    // the local data of the block the continuation reads
    const before = b.stmts.slice(0, b.index);
    const used = new Set(branch.flatMap((x) => stmtTokens(x).map((t) => lc(t.getStr()))));
    const decls = [];
    const inline = [];
    for (const x of before) {
      const k = kind(x);
      if (["Data", "FieldSymbol", "Ranges", "Constant", "Type"].includes(k)) {
        const name = lc(declName(x) ?? "");
        if (name && used.has(name)) decls.push(x);
      } else {
        for (const d of findAll(x, "InlineData")) {
          const name = lc(d.getTokens()[2]?.getStr() ?? "");
          if (name && used.has(name)) inline.push(name);
        }
      }
    }
    const names = decls.filter((x) => kind(x) === "Data").map((x) => lc(declName(x)));
    if (names.length) this.todo(s, `${what}: ${names.join(", ")} of the block ${names.length > 1 ? "are" : "is"} declared anew in ${method}( ) - a value set before the call is not there; make it global data if the continuation needs it`);
    if (inline.length) this.todo(s, `${what}: ${inline.join(", ")} ${inline.length > 1 ? "were" : "was"} declared inline before the call - declare ${inline.length > 1 ? "them" : "it"} in ${method}( ) or make ${inline.length > 1 ? "them" : "it"} global data`);
    this.continuations.push({ method, field, stmts: [...decls, ...branch], ctx: { ...ctx, prologue } });
    const first = branch.findIndex((x) => kind(x) !== "Comment");
    if (first >= 0) this.map(branch[first], note ?? `\`${method}( )\` - WHEN \`${field}\`: the statements after ${what}`);
    b.skipTo = b.index + 1 + branch.length;
  }

  /** what z2ui5_cl_cgui_frontend does not have of this statement's calls of
   *  cl_gui_frontend_services - undefined when it has everything */
  frontendCheck(s) {
    const toks = stmtTokens(s);
    for (let i = 0; i + 2 < toks.length; i++) {
      if (lc(toks[i].getStr()) === "cl_gui_frontend_services" && toks[i + 1].getStr() === "=>" && !frontendMember(toks[i + 2].getStr())) {
        return `${lc(toks[i + 2].getStr())} has no counterpart in the browser`;
      }
    }
    const call = /cl_gui_frontend_services\s*=>\s*(\w+)/i.exec(renderTokens(toks));
    const m = call && FRONTEND.methods[lc(call[1])];
    if (!m) return undefined;
    for (const n of findAll(s, "ParameterName").map((x) => lc(nodeText(x)))) {
      // RECEIVING result = ... of a functional method
      if (!m.params.includes(n) && !m.exceptions.includes(n) && n !== "others" && n !== "result") return `${lc(call[1])}( ${n} = ... ) is not supported`;
    }
    return undefined;
  }

  /** CALL FUNCTION 'GUI_UPLOAD' / 'GUI_DOWNLOAD' as the method of
   *  z2ui5_cl_cgui_frontend: EXPORTING and IMPORTING as they are, TABLES
   *  data_tab CHANGING, the EXCEPTIONS kept - sy-subrc stays */
  frontendFunction(s, b, fm) {
    const method = FRONTEND_FUNCTIONS[fm];
    const sig = FRONTEND.methods[method];
    const ov = this.rewrites(s, b.ctx, b);
    const sections = { EXPORTING: [], IMPORTING: [], CHANGING: [], EXCEPTIONS: [] };
    const params = child(s, "FunctionParameters");
    let keyword;
    for (const c of params ? params.getChildren() : []) {
      if (isToken(c)) {
        keyword = uc(c.getFirstToken().getStr());
        continue;
      }
      for (const p of children(c)) {
        const name = lc(nodeText(child(p, "ParameterName") ?? p.getChildren()[0]));
        const value = kind(p) === "ParameterException" ? nodeText(p.getChildren()[p.getChildren().length - 1]) : nodeText(p.getChildren()[p.getChildren().length - 1], ov);
        const shown = name === "others" ? "OTHERS" : name;
        const known = keyword === "EXCEPTIONS" ? name === "others" || sig.exceptions.includes(name) : sig.params.includes(name);
        if (!known) {
          this.refuse(s, `CALL FUNCTION '${fm}' - ${keyword} ${name} has no counterpart in z2ui5_cl_cgui_frontend=>${method}( ); port this call by hand`);
          return;
        }
        // TABLES data_tab is CHANGING, TABLES fieldnames a table it reads
        const section = keyword === "TABLES" ? (name === "data_tab" ? "CHANGING" : "EXPORTING") : keyword;
        sections[section].push({ name: shown, value });
      }
    }
    const head = `z2ui5_cl_cgui_frontend=>${method}( `;
    const width = Math.max(0, ...Object.values(sections).flat().map((p) => p.name.length));
    const lines = [];
    for (const [title, list] of Object.entries(sections)) {
      list.forEach((p, i) => {
        const lead = i === 0 ? title.padEnd(10) : " ".repeat(10);
        lines.push(`${lines.length ? " ".repeat(head.length) : head}${lead} ${p.name.padEnd(width)} = ${p.value}`);
      });
    }
    if (!lines.length) lines.push(head.trimEnd());
    lines[lines.length - 1] += " ).";
    b.out.push(...lines);
    this.note("cl_gui_frontend_services is z2ui5_cl_cgui_frontend - a file the user picks is uploaded in the browser (file_open_dialog( ) in an F4 opens the upload, the F4 runs again with the file), gui_download( ) is a download of the browser");
    this.map(s, `\`z2ui5_cl_cgui_frontend=>${method}( )\` - the function module as the method of the frontend services, its EXCEPTIONS kept`);
  }

  callFunction(s, b) {
    const fm = uc(unquote(nodeText(child(s, "FunctionName")).trim()));
    if (FRONTEND_FUNCTIONS[fm]) {
      this.frontendFunction(s, b, fm);
      return true;
    }
    // the progress of SAP GUI's status bar - the browser shows its own busy indicator
    if (fm === "SAPGUI_PROGRESS_INDICATOR") {
      this.note("SAPGUI_PROGRESS_INDICATOR / cl_progress_indicator - dropped, the browser shows a busy indicator while the server works");
      this.map(s, "dropped - the progress indicator of SAP GUI");
      return true;
    }
    if (POPUPS.has(fm)) {
      this.popup(s, b, fm);
      return true;
    }
    if (fm === "DYNP_VALUES_READ" || fm === "DYNP_VALUES_UPDATE") {
      // the fields of the selection screen are attributes, and every event
      // brings their values along - the table of names reads or writes them
      const tab = functionParams(s).get("dynpfields");
      if (tab) {
        const name = nodeText(tab.node, this.rewrites(s, b.ctx, b));
        this.dynpCount = (this.dynpCount ?? 0) + 1;
        const line = `<ls_r2c_dynp${this.dynpCount}>`;
        const field = `<lv_r2c_dynp${this.dynpCount}>`;
        const read = fm === "DYNP_VALUES_READ";
        b.out.push(`LOOP AT ${name} ASSIGNING FIELD-SYMBOL(${line}).`,
          `  ASSIGN (${line}-fieldname) TO FIELD-SYMBOL(${field}).`,
          "  IF sy-subrc = 0.",
          read ? `    ${line}-fieldvalue = ${field}.` : `    ${field} = ${line}-fieldvalue.`,
          "  ENDIF.",
          "ENDLOOP.");
        this.map(s, `${read ? "read from" : "written to"} the attributes the field names name - \`ASSIGN (fieldname)\``);
        if (/\bEXCEPTIONS\b/i.test(renderTokens(stmtTokens(s)))) {
          this.todo(s, `${fm}: the EXCEPTIONS are gone - a field name that is no attribute is skipped; sy-subrc is the one of the LOOP`);
        }
        return true;
      }
    }
    if (REFUSED_FUNCTIONS[fm]) {
      this.refuse(s, `CALL FUNCTION '${fm}' - ${REFUSED_FUNCTIONS[fm]}`);
      return true;
    }
    if (/^REUSE_ALV_/.test(fm) || /^LVC_/.test(fm)) {
      this.refuse(s, `CALL FUNCTION '${fm}' - only REUSE_ALV_GRID_DISPLAY / REUSE_ALV_LIST_DISPLAY with TABLES t_outtab are converted`);
      return true;
    }
    if (fm === "F4IF_INT_TABLE_VALUE_REQUEST") {
      // in a FORM: called from AT SELECTION-SCREEN ON VALUE-REQUEST, its
      // value_help_popup( ) writes into the field of that event
      if (b.ctx.form && !b.ctx.valueRequest) this.todo(s, `F4IF_INT_TABLE_VALUE_REQUEST in FORM ${b.ctx.form.name}: value_help_popup( ) writes the picked value into the field of the AT SELECTION-SCREEN ON VALUE-REQUEST the FORM is called from - call it from there only`);
      if (!b.ctx.valueRequest && !b.ctx.form) {
        this.refuse(s, "F4IF_INT_TABLE_VALUE_REQUEST outside of AT SELECTION-SCREEN ON VALUE-REQUEST - only an F4 of the selection screen is converted");
        return true;
      }
      const p = functionParams(s);
      const tab = p.get("value_tab");
      const ret = p.get("retfield");
      if (!tab) {
        this.refuse(s, "F4IF_INT_TABLE_VALUE_REQUEST without TABLES value_tab - not understood");
        return true;
      }
      const ov = this.rewrites(s, b.ctx, b);
      const col = ret ? nodeText(ret.node, ov) : undefined;
      const colValue = col && /^'[^']*'$/.test(col) ? literal(uc(unquote(col))) : col;
      const params = [{ name: "tab", value: nodeText(tab.node, ov) }];
      if (colValue) params.push({ name: "col", value: colValue });
      const title = p.get("window_title");
      if (title) params.push({ name: "title", value: nodeText(title.node, ov) });
      b.out.push(renderNamedCall("value_help_popup", params));
      if (p.has("return_tab")) this.todo(s, "F4IF_INT_TABLE_VALUE_REQUEST: value_help_popup( ) writes the picked value into the field itself - the handling of RETURN_TAB after it has nothing to read any more");
      this.map(s, "`value_help_popup( )` - the picked value is written into the field");
      return true;
    }
    return false;
  }

  // ------------------------------------------------------------------ ALV

  alvChain(table, tableTok, settings, lineSelection, s) {
    const root = lc(table.split("-")[0]);
    if (!this.globalData.has(root)) {
      this.todo(s, `alv( ${table} ): the table is no attribute of the class - alv( ) copies it into a data reference, which the draft rebuilds with RTTI on every roundtrip; make it a global DATA of the report`);
    }
    // the last text of a column wins - long over medium over short
    const rank = { set_short_text: 1, set_medium_text: 2, set_long_text: 3 };
    const texts = new Map();
    const hidden = [];
    let title;
    for (const st of settings) {
      if (st.m === "set_title") title = st.arg;
      if (st.m === "set_column_text") {
        const prev = texts.get(st.name);
        if (!prev || (rank[st.rank] ?? 3) >= (rank[prev.rank] ?? 3)) texts.set(st.name, st);
      }
      if (st.m === "set_column_hidden" && !hidden.includes(st.name)) hidden.push(st.name);
    }
    const items = [{ method: "alv", params: [{ value: lc(table) }] }];
    if (title) items.push({ method: "set_title", params: [{ value: this.literalArg(title, s) }] });
    for (const [name, st] of texts) {
      items.push({ method: "set_column_text", params: [{ name: "name", value: literal(name) }, { name: "text", value: this.literalArg(st.arg, s) }] });
    }
    for (const name of hidden) items.push({ method: "set_column_hidden", params: [{ value: literal(name) }] });
    for (const st of settings.filter((x) => x.m === "set_column_hotspot" || x.m === "set_column_sum")) {
      items.push({ method: st.m, params: [{ value: literal(st.name) }] });
    }
    for (const st of settings.filter((x) => x.m === "add_function")) items.push({ method: "add_function", params: st.params });
    if (settings.some((x) => x.m === "set_selection_mode")) items.push({ method: "set_selection_mode", params: [] });
    if (lineSelection) items.push({ method: "set_line_selection", params: [] });
    return renderChain({ items, head: "" });
  }

  /** an argument written in the report - a TEXT-001 becomes its text */
  literalArg(arg, s) {
    const m = /^text-(\w+)$/i.exec(arg.trim());
    if (m) return this.textSymbol(m[1], undefined, s);
    const m2 = /^('(?:[^']|'')*')\((\w+)\)$/.exec(arg.trim());
    if (m2) return this.textSymbol(m2[2], unquote(m2[1]), s);
    return arg.trim();
  }

  /** the USER_COMMAND callback of REUSE_ALV_GRID_DISPLAY as the body of
   *  at_line_selection( ): the ucomm is the double click, the selfield's
   *  tabindex the row */
  alvCallbackBody(f) {
    const [ucomm, selfield] = f.params.map((p) => p.name);
    if (f.params.length !== 2) {
      this.refuse(f.stmt, `FORM ${f.name} is the USER_COMMAND callback of the ALV and needs two parameters (r_ucomm, rs_selfield)`);
      return [];
    }
    this.map(f.stmt, "the ALV USER_COMMAND callback - its body is `at_line_selection( )`, rs_selfield-tabindex is row");
    const body = this.convertBody(f.body, { method: "at_line_selection", lineSelection: true, callback: { ucomm, selfield } });
    const lines = [`" the ALV double click - FORM ${f.name}, the USER_COMMAND callback`];
    if (new RegExp(`\\b${ucomm}\\b`, "i").test(body.join("\n"))) lines.push(`DATA(${ucomm}) = \`&IC1\`.`);
    // rs_selfield-tabindex -> row, -fieldname -> the column of a hotspot
    // (hide), -value -> that cell of the output table; refresh and the
    // stable flags are moot - the ALV is drawn anew on every roundtrip
    const table = this.alvCallbacks.get(f.name)?.stmt && this.alvPlan?.get(this.alvCallbacks.get(f.name).stmt)?.table?.replace(/\[\]$/, "");
    const flag = new RegExp(`^\\s*${selfield}\\s*-\\s*(refresh|row_stable|col_stable|exit)\\s*=\\s*[^.]*\\.\\s*(".*)?$`, "i");
    let column = false;
    let value = false;
    const out = [];
    for (const l of body) {
      const m = flag.exec(l);
      if (m) {
        if (lc(m[1]) === "exit") {
          out.push(`${l.match(/^\s*/)[0]}leave_to_selection_screen( ).`);
          this.todo(f.stmt, `FORM ${f.name}: ${selfield}-exit leaves the ALV - leave_to_selection_screen( ) shows the selection screen again`);
        }
        continue;
      }
      const re = new RegExp(`\\b${selfield}\\s*-\\s*(\\w+)`, "gi");
      let bad;
      out.push(l.replace(re, (all, comp) => {
        const c = lc(comp);
        if (c === "tabindex") return "row";
        if (c === "fieldname") {
          column = true;
          return "hide";
        }
        if (c === "value" && table) {
          column = true;
          value = true;
          return "lv_r2c_value";
        }
        bad = comp;
        return all;
      }));
      if (bad) {
        this.refuse(f.stmt, `FORM ${f.name}: ${selfield}-${bad} has no counterpart - at_line_selection( ) has the row and the column of a hotspot`);
      }
    }
    if (column) {
      this.todo(f.stmt, `FORM ${f.name}: ${selfield}-fieldname is the column of a hotspot click (hide) - a double click on the row has none; mark the columns that need it as hotspots`);
    }
    if (value) {
      lines.push("DATA lv_r2c_value TYPE string.",
        `READ TABLE ${table} INDEX row ASSIGNING FIELD-SYMBOL(<ls_r2c_row>).`,
        "IF sy-subrc = 0 AND hide IS NOT INITIAL.",
        "  ASSIGN COMPONENT hide OF STRUCTURE <ls_r2c_row> TO FIELD-SYMBOL(<lv_r2c_value>).",
        "  IF sy-subrc = 0.",
        "    lv_r2c_value = <lv_r2c_value>.",
        "  ENDIF.",
        "ENDIF.");
    }
    lines.push(...out);
    return lines;
  }

  // --------------------------------------------------------------- locals

  /** whether a declaration of the class - a global, an inline declaration
   *  that became an attribute, a FORM's parameter - is typed with a local
   *  class or interface: then their definitions go to locals_def */
  localsInDecl() {
    const viaDecl = [...this.decls, ...this.forms.map((f) => f.stmt)].some((s) => s.getTokens().some((t) => this.localNames.has(lc(t.getStr()))));
    const viaHoisted = [...(this.hoisted ?? new Map()).values()].some((h) => [...this.localNames].some((n) => new RegExp(`\\b${n}\\b`, "i").test(h.decl)));
    return viaDecl || viaHoisted;
  }

  /**
   * Where the declarations go that local classes are typed with. The local
   * types of a class pool (locals_def) can only be used in the PRIVATE
   * SECTION of the class, and they are read before it. So: a global typed
   * with a local class or interface is a private attribute, and when local
   * definitions are needed by the class (locals_def) and use types or
   * constants of the report, those go to locals_def ahead of them - with
   * every type of the report they build on, and every one built on them.
   */
  planLocalTypes() {
    this.movedTypes = new Set();
    this.privateGlobals = new Set();
    if (!this.locals.length) return;
    const tokensOf = (list) => new Set(list.flatMap((x) => stmtTokens(x).map((t) => lc(t.getStr()))));
    // the top-level TYPES / CONSTANTS of the report with the statements of their run
    const runs = new Map();
    for (let i = 0; i < this.decls.length; i++) {
      const s = this.decls[i];
      const k = kind(s);
      if (!["Type", "TypeBegin", "Constant", "ConstantBegin", "TypeEnum", "TypeEnumBegin"].includes(k) || this.insideBegin(s)) continue;
      const at = this.stmts.indexOf(s);
      const end = this.declEnd(at);
      runs.set(lc(declName(s) ?? ""), this.stmts.slice(at, end + 1));
    }
    const usedInDecl = this.localsInDecl();
    if (usedInDecl) {
      const defs = this.locals.filter((u) => ["ClassDefinition", "Interface"].includes(u.kind));
      const queue = [...tokensOf(defs.flatMap((u) => u.stmts))].filter((t) => runs.has(t));
      while (queue.length) {
        const t = queue.pop();
        if (this.movedTypes.has(t)) continue;
        this.movedTypes.add(t);
        for (const r of tokensOf(runs.get(t))) if (runs.has(r) && !this.movedTypes.has(r)) queue.push(r);
      }
      // a type of the report that builds on a moved one moves as well
      let grew = true;
      while (grew) {
        grew = false;
        for (const [name, run] of runs) {
          if (this.movedTypes.has(name)) continue;
          if ([...tokensOf(run)].some((t) => this.movedTypes.has(t) && t !== name)) {
            this.movedTypes.add(name);
            grew = true;
          }
        }
      }
    }
    const local = new Set([...this.localNames, ...this.movedTypes]);
    for (const s of this.decls) {
      const k = kind(s);
      if (!["Data", "DataBegin", "Parameter", "SelectOption"].includes(k) || this.insideBegin(s)) continue;
      const at = this.stmts.indexOf(s);
      const run = k === "DataBegin" ? this.stmts.slice(at, this.declEnd(at) + 1) : [s];
      if (![...tokensOf(run)].some((t) => local.has(t))) continue;
      if (k === "Parameter" || k === "SelectOption") {
        this.refuse(s, `${uc(declName(s))} is typed with a local type of the report - a field of the selection screen is a public attribute, which a local type cannot type; give it a type of the dictionary or a built-in one`);
        continue;
      }
      this.privateGlobals.add(lc(declName(s) ?? ""));
    }
  }

  /**
   * The local classes and interfaces of the report, as the local types of
   * the class. A method of a local class that writes the list, calls a FORM
   * or uses a global of the report is converted like an event block: the
   * report's data is reached through the instance of the class
   * (lcl_r2c=>app->gv, set at the start of every event method), its
   * constants and types through the class (zcl_x=>c_pi), the methods of the
   * runtime and the FORMs through the instance - the class declares the
   * local class a LOCAL FRIEND for that. Everything else is copied as it is.
   */
  localsSource() {
    if (!this.locals.length) return {};
    const cls = this.className;
    const usedInDecl = this.localsInDecl();
    const isDefUnit = (u) => ["ClassDefinition", "Interface", "ClassDeferred", "InterfaceDeferred"].includes(u.kind);
    const nameOf = (u) => lc(nodeText(child(u.stmts[0], "ClassName") ?? child(u.stmts[0], "InterfaceName") ?? u.stmts[0].getChildren()[1]));
    const REPORT_KINDS = new Set(["Perform", "Write", "Uline", "Skip", "NewLine", "NewPage", "Format", "Hide", "Message",
      "SetPFStatus", "SetTitlebar", "Submit", "CallSelectionScreen", "Leave", "Position", "Reserve", "Window", "Stop",
      "LoopAtScreen", "ModifyScreen"]);
    const reportGlobals = new Set([...this.globalData, ...this.globalTypes, ...this.globalConstants]);
    const formMethods = new Set(this.forms.map((f) => f.method).filter(Boolean));

    // what a local class declares itself: attributes, types, constants,
    // methods and their parameters - those names are its own
    const declaredOf = new Map();
    const methodsOf = new Map();
    for (const u of this.locals) {
      const n = nameOf(u);
      if (!declaredOf.has(n)) declaredOf.set(n, new Set());
      if (!methodsOf.has(n)) methodsOf.set(n, new Set());
      for (const s of u.stmts) {
        // the data of the class - a method is no data, and the parameters of a
        // method are its own (the body adds them): a global of that name is
        // the report's in every other method
        if (["Data", "ClassData", "Constant", "Type", "TypeBegin", "ConstantBegin", "FieldSymbol", "Events", "ClassDataBegin", "DataBegin"].includes(kind(s))) declaredOf.get(n).add(lc(declName(s) ?? ""));
        if (kind(s) === "MethodDef") methodsOf.get(n).add(lc(nodeText(child(s, "MethodName"))));
      }
    }
    // a subclass inherits what its local superclass declares
    for (const u of this.locals.filter((x) => x.kind === "ClassDefinition")) {
      const sup = child(u.stmts[0], "SuperClassName");
      const parent = sup && lc(nodeText(sup));
      if (parent && declaredOf.has(parent)) {
        for (const d of declaredOf.get(parent)) declaredOf.get(nameOf(u)).add(d);
        for (const d of methodsOf.get(parent)) methodsOf.get(nameOf(u)).add(d);
      }
    }
    const usesReport = (s, declared) => {
      const parents = tokenParents(s);
      return stmtTokens(s).some((t) => {
        const v = lc(t.getStr());
        if (!reportGlobals.has(v) || declared.has(v) || this.movedTypes.has(v)) return false;
        const parent = parents.get(key(t));
        return parent === "Field" || (parent === "TypeName" && this.globalTypes.has(v));
      });
    };

    const def = [];
    const imp = [];
    const friends = new Set();
    const persisted = new Set([...this.decls.map((s) => renderTokens(stmtTokens(s))), ...[...(this.hoisted ?? new Map()).values()].map((h) => h.decl)].flatMap((text) => {
      const m = /type\s+ref\s+to\s+([\w/]+)/i.exec(text);
      return m ? [lc(m[1])] : [];
    }));
    // a handler of a SAP GUI control: the stand-in keeps its instance
    for (const list of this.guiVars?.size ? this.guiHandlers().values() : []) for (const h of list) if (guiClass(h.of)) persisted.add(h.cls);
    const copied = new Set();   // rows a chained statement (CLASS: a DEFINITION DEFERRED, b ...) was copied with
    for (const u of this.locals) {
      const n = nameOf(u);
      const declared = declaredOf.get(n) ?? new Set();
      const inDef = usedInDecl && isDefUnit(u);
      // a local class a macro writes: its expansion, a statement per line -
      // the macro is no part of the class
      if (u.stmts[0].getFirstToken().getStart() instanceof abaplint.VirtualPosition) {
        (inDef ? def : imp).push(u.stmts.map((x) => `${renderTokens(stmtTokens(x))}.`).join("\n"));
        this.note("a local class written by a macro is written out as the macro expands it");
        continue;
      }
      const first = u.stmts[0].getFirstToken().getRow();
      // a chain - CLASS: a DEFINITION DEFERRED, b DEFINITION DEFERRED. - is
      // a unit per class, all starting at the row of CLASS: copied once, whole
      const last = u.stmts.length > 1 ? u.stmts[u.stmts.length - 1].getLastToken().getRow()
        : Math.max(...this.locals.filter((x) => x.stmts.length === 1 && x.stmts[0].getFirstToken().getRow() === first).map((x) => x.stmts[0].getLastToken().getRow()));
      if (copied.has(`${first}:${last}`)) continue;
      copied.add(`${first}:${last}`);
      const text = this.lines.slice(first - 1, last);
      const replace = [];   // { from, to (rows of the source), lines }
      const subst = [];     // { row, col, len, text } - a token replaced in place
      // a macro call outside of a converted body: its expansion, written out
      u.stmts.forEach((s, i) => {
        if (kind(s) !== "MacroCall") return;
        const expanded = [];
        for (let j = i + 1; u.stmts[j] && u.stmts[j].getFirstToken().getStart() instanceof abaplint.VirtualPosition; j++) expanded.push(u.stmts[j]);
        const row = s.getFirstToken().getRow();
        const pad = this.lines[row - 1].match(/^\s*/)[0];
        replace.push({ from: row, to: s.getLastToken().getRow(), lines: expanded.map((x) => `${pad}${renderTokens(stmtTokens(x))}.`), macro: true });
      });
      if (u.kind === "ClassImplementation") {
        // the method bodies
        let cur;
        const bodies = [];
        for (const s of u.stmts.slice(1)) {
          const k = kind(s);
          if (k === "MethodImplementation") cur = { name: lc(nodeText(child(s, "MethodName"))), stmt: s, body: [] };
          else if (k === "EndMethod" && cur) {
            cur.end = s;
            bodies.push(cur);
            cur = undefined;
          } else if (cur) cur.body.push(s);
        }
        for (const b of bodies) {
          const params = new Set(this.locals.filter((x) => nameOf(x) === n).flatMap((x) => x.stmts)
            .filter((x) => kind(x) === "MethodDef" && lc(nodeText(child(x, "MethodName"))) === b.name.split("~").pop())
            .flatMap((x) => findAll(x, "MethodParamName").map((p) => lc(nodeText(p)))));
          const own = new Set([...declared, ...params]);
          const needs = b.body.some((x) => REPORT_KINDS.has(kind(x)) || usesReport(x, own)
            || (kind(x) === "CallFunction" && /^'?(POPUP_|REUSE_ALV_|GUI_UPLOAD'|GUI_DOWNLOAD')/i.test(nodeText(child(x, "FunctionName"))))
            || /\bcl_gui_(frontend_services|cfw)\b/i.test(renderTokens(stmtTokens(x)))
            // a SAP GUI control: its stand-in, and its CREATE OBJECT a NEW
            || (this.guiVars?.size && stmtTokens(x).some((t) => guiClass(lc(t.getStr())) || this.guiVars.has(lc(t.getStr()))))
            // an icon of the type pool ICON - the stand-ins take sap-icon:// names
            || (this.guiVars?.size && stmtTokens(x).some((t) => ICONS[lc(t.getStr())]))
            // sender->... in a handler of an event of a control
            || (this.guiVars?.size && /\bsender\s*->/i.test(renderTokens(stmtTokens(x)))));
          if (!needs || !b.body.length) continue;
          const key = `${n}~${b.name}`;
          const body = this.convertBody(b.body, { method: key, local: { cls: n, declared: own } });
          const was = [...(this.methodWa.get(key) ?? new Map())].map(([tab, wa]) => `DATA ${wa} LIKE LINE OF ${tab}.`);
          const pre = [...was, ...(this.prelude.get(key) ?? []), ...this.fieldSymbolDecls(body)];
          const calls = new Set([...BASE_METHODS, ...REPORT_CALLS, ...formMethods].filter((x) => !(methodsOf.get(n) ?? new Set()).has(x)));
          const lines = [...pre, ...trimBlank(body)].map((l) => prefixCalls(l, calls, this.appRef));
          const pad = (this.lines[b.stmt.getFirstToken().getRow() - 1].match(/^\s*/)[0]) + "  ";
          replace.push({ from: b.stmt.getLastToken().getRow() + 1, to: b.end.getFirstToken().getRow() - 1, lines: lines.map((l) => indent(l, pad.length)) });
          friends.add(n);
        }
      } else {
        // the definition: a type or constant of the report through the class
        for (const s of u.stmts) {
          const toks = stmtTokens(s);
          const parents = tokenParents(s);
          toks.forEach((t, i) => {
            const v = lc(t.getStr());
            const prev = i > 0 ? toks[i - 1].getStr() : "";
            // a SAP GUI control: its stand-in
            if (this.guiVars?.size && guiClass(v) && !["-", "->", "~"].includes(prev)) {
              subst.push({ row: t.getRow(), col: t.getCol(), len: t.getStr().length, text: guiClass(v) });
              return;
            }
            if (!reportGlobals.has(v) || declared.has(v) || this.movedTypes.has(v) || ["-", "->", "=>", "~"].includes(prev)) return;
            // only a type or a variable of the statement - not a parameter, a
            // component or a dictionary type that shares the name
            const parent = parents.get(key(t));
            if (parent === "TypeName" ? !this.globalTypes.has(v) : parent !== "Field") return;
            if (this.globalData.has(v) && !this.globalConstants.has(v)) {
              this.refuse(t, `the local class uses ${v}, a global of the report - a local class of the generated class cannot reach the report's attributes; pass it as a parameter`);
              return;
            }
            if (inDef) {
              this.refuse(t, `the local class uses ${v}, a global of the report - a local class of the generated class cannot reach the report's attributes; pass it as a parameter`);
              return;
            }
            subst.push({ row: t.getRow(), col: t.getCol(), len: t.getStr().length, text: `${cls}=>${t.getStr()}` });
          });
        }
      }

      // the copy, with the converted bodies and the replaced tokens
      const out = [];
      let row = first;
      const repl = replace.sort((a, b) => a.from - b.from);
      while (row <= last) {
        const r = repl.find((x) => x.from === row);
        if (r) {
          out.push(...r.lines);
          row = Math.max(r.to, row - 1) + 1;
          continue;
        }
        let line = this.lines[row - 1];
        for (const sb of subst.filter((x) => x.row === row).sort((a, b) => b.col - a.col)) {
          line = line.slice(0, sb.col - 1) + sb.text + line.slice(sb.col - 1 + sb.len);
        }
        out.push(line);
        row++;
      }
      // an instance of a local class the report keeps survives the
      // roundtrip with the app - its class must be serializable
      if (u.kind === "ClassDefinition" && persisted.has(n) && !child(u.stmts[0], "SuperClassName")
        && !u.stmts.some((s) => kind(s) === "InterfaceDef" || /if_serializable_object/i.test(renderTokens(stmtTokens(s))))) {
        const at = out.findIndex((l) => /^\s*PUBLIC\s+SECTION\s*\./i.test(l));
        if (at >= 0) {
          out.splice(at + 1, 0, `${out[at].match(/^\s*/)[0]}  INTERFACES if_serializable_object.`);
          this.note("a local class whose instance the report keeps implements if_serializable_object - the app is serialized between two roundtrips, its attributes with it");
        }
      }
      (inDef ? def : imp).push(out.join("\n"));
      void text;
      this.mapped.push({ row: first, col: 1, classic: renderTokens(stmtTokens(u.stmts[0])).split("\n")[0], target: inDef ? "locals_def" : "locals_imp" });
    }

    // the helper that hands the instance to the local classes, and their friendship
    if (friends.size) {
      const deferred = [...friends].filter((f) => !(usedInDecl && this.locals.some((u) => u.kind === "ClassDefinition" && nameOf(u) === f)));
      const head = [
        `" the instance of the report for its local classes - set at the start of`,
        `" every event method; the local classes reach the report's data through it`,
        `CLASS ${this.appClass} DEFINITION FINAL.`,
        "  PUBLIC SECTION.",
        `    CLASS-DATA app TYPE REF TO ${cls}.`,
        "ENDCLASS.",
        "",
        `CLASS ${this.appClass} IMPLEMENTATION.`,
        "ENDCLASS.",
        "",
        ...deferred.map((f) => `CLASS ${f} DEFINITION DEFERRED.`),
        `CLASS ${cls} DEFINITION LOCAL FRIENDS ${[...friends].join(" ")}.`,
      ];
      imp.unshift(head.join("\n"));
      this.note("local classes that write the list, call a FORM or use a global of the report reach the report through lcl_r2c=>app, the instance of the class - LOCAL FRIENDS of the class, so the FORMs and the methods of the runtime are theirs to call");
    }
    if (this.localTypeLines.length) {
      def.unshift(["\" the types and constants of the report the local classes are typed with", ...this.localTypeLines].join("\n"));
    }
    return { def: def.join("\n\n"), imp: imp.join("\n\n"), app: friends.size > 0 };
  }

  fieldSymbolDecls(body) {
    if (!this.globalFieldSymbols) return [];
    const text = body.join("\n").toLowerCase();
    // a field symbol the method declares itself shadows the global one
    const own = (name) => new RegExp(`${name.replace(/[<>]/g, "\\$&")}\\s+(type|like|structure)\\b`).test(text);
    return this.globalFieldSymbols
      .filter((s) => text.includes(lc(declName(s))) && !own(lc(declName(s))))
      .map((s) => `${renderTokens(stmtTokens(s), new Map(), s.getColon()).replace(/^([\w-]+)(\s*):\s*/, "$1 ")}.`);
  }

  // --------------------------------------------------------- the class text

  /** indent the class as the house style does - two blanks per level, the
   *  lines of a statement kept relative to its first line */
  reindent(text, filename) {
    const reg = new abaplint.Registry();
    reg.addFile(new abaplint.MemoryFile(filename, text));
    reg.parse();
    const file = reg.getFirstObject().getABAPFiles()[0];
    const statements = file.getStatements();
    const expected = new Indent({}).getExpectedIndents(file);
    const lines = text.split("\n");
    const done = new Set();
    for (let i = 0; i < statements.length; i++) {
      const s = statements[i];
      let exp = expected[i];
      // a full-line comment with * lives in the first column - never moved
      if (kind(s) === "Comment" && s.getFirstToken().getStr().startsWith("*")) continue;
      // a comment stands where the statement after it stands - the
      // pretty printer's indent would put one right after a WHEN or ELSE
      // at the level of the CASE or IF
      if (kind(s) === "Comment") {
        let j = i + 1;
        while (statements[j] && kind(statements[j]) === "Comment") j++;
        if (statements[j] && expected[j] !== undefined && expected[j] >= 0) exp = expected[j];
      }
      const row = (s.getColon() ? s.getColon() : s.getFirstToken()).getRow() - 1;
      if (exp === undefined || exp < 0 || done.has(row)) continue;
      const last = s.getLastToken().getRow() - 1;
      const current = lines[row].length - lines[row].trimStart().length;
      const delta = exp - 1 - current;
      if (s.getColon()) {
        // a chained statement: its parts move with the chain's first line
        let end = i;
        while (statements[end + 1] && statements[end + 1].getColon() === s.getColon()) end++;
        const lastRow = statements[end].getLastToken().getRow() - 1;
        for (let r = row; r <= lastRow; r++) if (!done.has(r)) { lines[r] = shift(lines[r], delta); done.add(r); }
        i = end;
        continue;
      }
      for (let r = row; r <= last; r++) {
        if (done.has(r)) continue;
        lines[r] = shift(lines[r], delta);
        done.add(r);
      }
    }
    return lines.join("\n");
  }

  // -------------------------------------------------------- release TODOs

  /** the objects the generated class uses that ABAP Cloud may not release -
   *  database tables, DDIC types, function modules, classes, message classes */
  releaseTodos(files) {
    const name = `${this.className}.clas.abap`;
    const reg = new abaplint.Registry();
    for (const [f, text] of Object.entries(files)) if (f.endsWith(".abap")) reg.addFile(new abaplint.MemoryFile(f, text));
    reg.parse();
    const found = new Map();
    const add = (objKind, objName, tok, file) => {
      const n = lc(objName);
      if (!n || /^z2ui5_/.test(n) || this.localNames.has(n)) return;
      // one entry per name - a table that also types a field is a table
      const prev = found.get(n);
      if (!prev || (prev.kind === "DDIC type" && objKind === "database table")) {
        found.set(n, { kind: objKind, name: uc(n), file, row: prev?.row ?? tok.getRow(), col: prev?.col ?? tok.getCol(), successor: SUCCESSORS[n] });
      }
    };
    const localTypes = new Set([...this.globalTypes, ...this.tablesTypes.keys()]);
    const files0 = [...reg.getObjects()].flatMap((o) => o.getABAPFiles());
    for (const file of files0) {
      for (const s of file.getStatements()) {
        if (["Type", "TypeBegin", "TypeEnum", "TypeEnumBegin"].includes(kind(s))) localTypes.add(lc(declName(s) ?? ""));
        if (["ClassDefinition", "Interface"].includes(kind(s))) localTypes.add(lc(nodeText(child(s, "ClassName") ?? child(s, "InterfaceName") ?? s.getChildren()[1])));
      }
    }
    for (const file of files0) {
      const fname = file.getFilename();
      for (const s of file.getStatements()) {
        const k = kind(s);
        for (const db of findAll(s, "DatabaseTable")) add("database table", nodeText(db), db.getFirstToken(), fname);
        if (k === "CallFunction") {
          const fn = child(s, "FunctionName");
          add("function module", unquote(nodeText(fn).trim()), fn.getFirstToken(), fname);
        }
        for (const t of findAll(s, "TypeName")) {
          const toks = t.getTokens();
          const n = lc(toks[0].getStr());
          if (BUILTIN_TYPES.has(n) || localTypes.has(n) || toks.some((x) => x.getStr() === "=>")) continue;
          add("DDIC type", n, t.getFirstToken(), fname);
        }
        for (const c of findAll(s, "ClassName")) {
          const n = lc(nodeText(c));
          if (/^(cx_root|cx_static_check|cx_dynamic_check|cx_no_check|cx_sy_\w+|me|super)$/.test(n) || localTypes.has(n)) continue;
          add("class", n, c.getFirstToken(), fname);
        }
      }
    }
    for (const m of this.messageClasses ?? []) {
      found.set(`message class ${m}`, { kind: "message class", name: m, file: name, row: 0, col: 0, successor: undefined });
    }
    return [...found.values()].sort((a, b) => a.kind.localeCompare(b.kind) || a.name.localeCompare(b.name));
  }
}

// ------------------------------------------------------------------ helpers

function shortText(s) {
  const t = renderTokens(stmtTokens(s), new Map(), s.getColon()).replace(/\s+/g, " ");
  return t.length > 60 ? `${t.slice(0, 57)}...` : t;
}

function shift(line, delta) {
  if (!line.trim()) return line;
  if (delta >= 0) return " ".repeat(delta) + line;
  const lead = line.length - line.trimStart().length;
  return line.slice(Math.min(-delta, lead));
}

/** DATA a TYPE i. / DATA bb TYPE string. - the names of a run padded */
function alignData(list) {
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

function indent(text, n) {
  if (!text) return "";
  const pad = " ".repeat(n);
  return pad + text.replace(/\n/g, `\n${pad}`);
}

/** an IF sy-subrc whose statements were all dropped - around the CALL
 *  SCREEN of the grid, after the EXCEPTIONS of its first display - goes too */
function dropEmptyIfs(lines) {
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

function trimBlank(lines) {
  let a = 0;
  let b = lines.length;
  while (a < b && lines[a] === "") a++;
  while (b > a && lines[b - 1] === "") b--;
  return lines.slice(a, b);
}

const sameColon = (a, b) => {
  const ca = a.getColon();
  const cb = b.getColon();
  return ca && cb && ca.getRow() === cb.getRow() && ca.getCol() === cb.getCol();
};

const findTo = (s) => children(s, "Target").length > 0;

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
function headerLineContext(s, toks, i) {
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
function dropWords(toks, w, ov, word, n) {
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
export function defaultClassName(program) {
  const p = lc(program);
  const ns = /^(\/\w+\/)(.*)$/.exec(p);
  if (ns) return `${ns[1]}cl_${ns[2]}`.slice(0, 30);
  const m = /^([zy])_?(.*)$/.exec(p);
  return (m ? `${m[1]}cl_${m[2]}` : `zcl_${p}`).slice(0, 30);
}

/** a call chain over a variable: target = root->a( )->b( arg ). */
function salvChain(s) {
  const k = kind(s);
  if (k !== "Call" && k !== "Move") return undefined;
  const toks = stmtTokens(s).map((t) => t.getStr());
  let i = 0;
  let target;
  if (k === "Move") {
    if (toks[1] !== "=" && toks[1] !== "?=") return undefined;
    target = lc(toks[0]);
    i = 2;
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

function chainOf(toks) {
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
function functionParams(s) {
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
function renderTableCall(method, params) {
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
const REPORT_CALLS = ["list", "write", "message", "message_t100", "messages_from_bapiret", "alv", "tree", "set_title",
  "set_pf_status", "set_line_count", "leave_to_selection_screen", "submit", "call_selection_screen", "window",
  "popup_to_confirm", "popup_to_decide", "popup_get_values", "popup_get_values_sval", "popup_values_sval",
  "popup_answer", "popup_values", "value_help_popup", "lsind", "set_lsind", "get_selected_rows", "get_cursor",
  "lisel", "set_parameter_id", "get_parameter_id", "set_cursor_field", "vrm_set_values", "current_screen",
  "call_screen", "set_screen", "leave_to_screen", "leave_screen", "screen_left"];

/**
 * A call of a method of the report class written without its instance -
 * list( ), message( ), a FORM - prefixed with ref-> in a line of converted
 * code of a local class; strings and the text of templates are left alone.
 */
function prefixCalls(line, names, ref) {
  let out = "";
  let i = 0;
  const code = (seg) => seg.replace(/(^|[^\w>~=-])([a-z_][\w]*)\(/gi, (all, pre, name) => (names.has(name.toLowerCase()) ? `${pre}${ref}->${name}(` : all));
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
function tokenParents(s) {
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
function underName(text) {
  const t = text.trim();
  return /^['`]/.test(t) ? unquote(t) : uc(t.replace(/\s+/g, ""));
}

/** the group of radiobutton( ) for a radio group of a dynpro - %A_ISNATV
 *  (the name the screen painter generates) is RB_ISNATV */
const radioGroup = (name) => name.replace(/^%A_?/, "RB_").slice(0, 10) || "RB1";

// the fields of a dynpro the converter builds - texts, inputs, checkboxes,
// radio buttons, frames, push buttons and the OK code field
const DYNPRO_FIELDS = new Set(["TEXT", "TEMPLATE", "CHECK", "RADIO", "FRAME", "PUSH", "OKCODE"]);

/**
 * The flow logic of a dynpro: { pbo, pai, pov: [{ module, cond, field }],
 * poh, request, problems } - cond "exit" for AT EXIT-COMMAND, "input" for
 * ON INPUT (field), "cursor" for AT CURSOR-SELECTION; problems what has no
 * counterpart (LOOP, CALL SUBSCREEN, FIELD ... VALUES / SELECT).
 */
function parseFlow(lines) {
  const flow = { pbo: [], pai: [], pov: [], poh: false, request: false, problems: [] };
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
    if (section === "poh") {
      flow.poh = true;
      continue;
    }
    const m = /^(?:FIELD ([\w-]+) )?MODULE ([\w/]+)(?: (AT EXIT-COMMAND|ON INPUT|ON REQUEST|ON CHAIN-INPUT|ON CHAIN-REQUEST|AT CURSOR-SELECTION|ON \*-INPUT))?$/.exec(st);
    if (m && section) {
      const cond = { "AT EXIT-COMMAND": "exit", "ON INPUT": m[1] ? "input" : undefined, "AT CURSOR-SELECTION": "cursor" }[m[3]];
      if (/REQUEST|CHAIN-INPUT/.test(m[3] ?? "")) flow.request = true;
      flow[section].push({ module: m[2].toLowerCase(), cond, field: m[1] });
      continue;
    }
    if (/^FIELD:? [\w-]+(?:,? [\w-]+)*$/.test(st)) continue;
    flow.problems.push(`${st.split(" ").slice(0, 3).join(" ")} in the flow logic`);
  }
  return flow;
}

/** a row of a field catalog written as components - fieldname = 'A'
 *  coltext = 'T' no_out = abap_true - the column of the alv( ) chain */
function fcatColumn(text) {
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
function valueRows(text) {
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
function caseBody(param, entries) {
  const body = [`CASE ${param}.`];
  for (const e of entries) body.push(`  WHEN ${literal(e.field)}.`, ...e.body.map((l) => indent(l, 4)));
  body.push("ENDCASE.");
  return body;
}

/** whether z2ui5_cl_cgui_frontend has a constant or method of that name */
function frontendMember(name) {
  const n = lc(name ?? "");
  return FRONTEND.constants.includes(n) || Object.hasOwn(FRONTEND.methods, n);
}

function renderCall(method, imp, chg) {
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

function renderNamedCall(method, params) {
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
function renderChain(chain) {
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
function renderScreenChain(calls) {
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

/** convert a classic report into an abap-cloud-gui report class */
/** the messages of the statements and function modules refused as a whole */
export const REFUSED_MESSAGES = () => [...Object.values(REFUSED), ...Object.entries(REFUSED_FUNCTIONS).map(([fm, m]) => `CALL FUNCTION '${fm}' - ${m}`)];

export function convert(source, opts = {}) {
  return new Converter(source, opts).run();
}
