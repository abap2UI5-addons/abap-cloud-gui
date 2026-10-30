// The functions family of the converter - CALL FUNCTION: the frontend services, the refused function modules and the wrapper stubs. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, children, findAll, isToken, key, kind, lc, literal, nodeText, renderTokens,
  stmtTokens, uc, unquote,
} from "./abap.mjs";
import {
  FRONTEND, FRONTEND_FUNCTIONS, FRONTEND_TABLES_OUT, GUI, POPUPS, REFUSED_FUNCTIONS,
  frontendMember, frontendName, functionParams, renderNamedCall,
} from "./convert-shared.mjs";

export const functionsMethods = {

  /** what z2ui5_cl_cgui_frontend does not have of this statement's calls of
   *  cl_gui_frontend_services - undefined when it has everything */
  frontendCheck(s) {
    const toks = stmtTokens(s);
    for (let i = 0; i + 2 < toks.length; i++) {
      if (lc(toks[i].getStr()) === "cl_gui_frontend_services" && toks[i + 1].getStr() === "=>" && !frontendMember(frontendName(toks, i))) {
        return `${frontendName(toks, i)} has no counterpart in the browser`;
      }
    }
    const at = toks.findIndex((t, i) => lc(t.getStr()) === "cl_gui_frontend_services" && toks[i + 1]?.getStr() === "=>");
    const name = at >= 0 ? frontendName(toks, at) : undefined;
    const m = name && FRONTEND.methods[name];
    if (!m) return undefined;
    for (const n of findAll(s, "ParameterName").map((x) => lc(nodeText(x)))) {
      // RECEIVING result = ... of a functional method
      if (!m.params.includes(n) && !m.exceptions.includes(n) && n !== "others" && n !== "result") return `${name}( ${n} = ... ) is not supported`;
    }
    return undefined;
  },


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
        const section = keyword === "TABLES" ? (FRONTEND_TABLES_OUT.has(`${fm}.${name}`) ? "CHANGING" : "EXPORTING") : keyword;
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
    if (/^(SCMS|SSFC)_/.test(fm)) this.note("SCMS_*_TO_* and SSFC_BASE64_* are methods of z2ui5_cl_cgui_frontend - bytes, lines of bytes, text and base64 converted in plain ABAP, the function modules are not released for ABAP Cloud");
    else if (fm === "DP_CREATE_URL") this.note("DP_CREATE_URL is z2ui5_cl_cgui_frontend=>dp_create_url( ) - the URL names a data URI of the bytes, which the picture and the HTML viewer of the browser show");
    else this.note("cl_gui_frontend_services is z2ui5_cl_cgui_frontend - a file the user picks is uploaded in the browser (file_open_dialog( ) in an F4 opens the upload, the F4 runs again with the file), gui_download( ) is a download of the browser");
    this.map(s, `\`z2ui5_cl_cgui_frontend=>${method}( )\` - the function module as the method of the frontend services, its EXCEPTIONS kept`);
  },


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
    // the tree list: the nodes of RS_TREE_CONSTRUCT as the ALV tree of the
    // report, TLEVEL the hierarchy - RS_TREE_LIST_DISPLAY shows it
    if (fm === "RS_TREE_CONSTRUCT") {
      const tab = functionParams(s).get("nodetab");
      if (!tab) {
        this.refuse(s, "RS_TREE_CONSTRUCT without TABLES nodetab - not understood");
        return true;
      }
      const ov = this.rewrites(s, b.ctx, b);
      const nodes = nodeText(tab.node, ov).replace(/\[\]$/, "");
      this.treeCount = (this.treeCount ?? 0) + 1;
      const n = this.treeCount;
      const parents = `lt_r2c_tree_parent${n}`;
      const node = `<ls_r2c_tree_node${n}>`;
      const level = `lv_r2c_tree_level${n}`;
      b.out.push(
        `DATA(lo_r2c_tree${n}) = tree( ).`,
        `DATA ${parents} TYPE STANDARD TABLE OF i WITH EMPTY KEY.`,
        `LOOP AT ${nodes} ASSIGNING FIELD-SYMBOL(${node}).`,
        `  DATA(lv_r2c_tree_row${n}) = sy-tabix.`,
        `  DATA(${level}) = nmax( val1 = 1 val2 = CONV i( ${node}-tlevel ) ).`,
        `  WHILE lines( ${parents} ) >= ${level}.`,
        `    DELETE ${parents} INDEX lines( ${parents} ).`,
        "  ENDWHILE.",
        `  INSERT lo_r2c_tree${n}->add_node( parent   = COND #( WHEN ${parents} IS NOT INITIAL THEN ${parents}[ lines( ${parents} ) ] )`,
        `                                   text     = condense( |{ ${node}-name } { ${node}-text }| )`,
        "                                   expanded = abap_true",
        `                                   value    = |{ lv_r2c_tree_row${n} }| ) INTO TABLE ${parents}.`,
        "ENDLOOP.");
      this.note("RS_TREE_CONSTRUCT / RS_TREE_LIST_DISPLAY are the ALV tree of the report: tree( )->add_node( ) per row of the node table, TLEVEL the hierarchy, NAME and TEXT the text of the node, every node open; a click on a node raises at_tree_node( key value ) with the index of its row as value");
      this.map(s, "`tree( )->add_node( )` per row of the node table - TLEVEL the hierarchy");
      return true;
    }
    if (fm === "RS_TREE_LIST_DISPLAY") {
      const p = functionParams(s);
      const form = p.get("callback_user_command");
      if (form) {
        this.todo(s, `RS_TREE_LIST_DISPLAY: the callback ${nodeText(form.node)} is not called - a click on a node raises at_tree_node( key value ), value the index of its row in the node table; call the FORM's method from a redefinition of at_tree_node( )`);
      }
      this.map(s, "dropped - the tree of RS_TREE_CONSTRUCT is the output");
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
    if (this.wrappers && /^'[^']+'$/.test(nodeText(child(s, "FunctionName")).trim()) && !/^(POPUP_|REUSE_ALV_|LVC_|GUI_|F4IF_)/.test(fm)) {
      this.wrapFunction(s, b, fm);
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
  },


  // ------------------------------------------------------------- wrappers

  wrapperName() {
    return `${this.className.slice(0, 26)}_fmw`;
  },


  /** CALL FUNCTION as the method of the wrapper class: the parameters as
   *  the call passes them, EXPORTING becomes IMPORTING of the method and
   *  IMPORTING EXPORTING, TABLES CHANGING; the EXCEPTIONS stay, so
   *  sy-subrc does */
  wrapFunction(s, b, fm) {
    const ov = this.rewrites(s, b.ctx, b);
    const call = { EXPORTING: [], IMPORTING: [], CHANGING: [], EXCEPTIONS: [] };
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
        const section = keyword === "TABLES" ? "CHANGING" : keyword;
        if (!call[section]) continue;
        call[section].push({ name: name === "others" ? "OTHERS" : name, value, table: keyword === "TABLES" });
      }
    }
    // the method: one per function module, its parameters the union of
    // all its calls
    const method = lc(fm).replace(/^\/(\w+)\//, "$1_").replace(/[^a-z0-9_]/g, "_").slice(0, 30);
    const sig = this.wrapped.get(fm) ?? { method, calls: 0, IMPORTING: new Map(), EXPORTING: new Map(), CHANGING: new Map(), EXCEPTIONS: new Set(), others: false };
    sig.calls++;
    for (const p of call.EXPORTING) sig.IMPORTING.set(p.name, p);
    for (const p of call.IMPORTING) sig.EXPORTING.set(p.name, p);
    for (const p of call.CHANGING) sig.CHANGING.set(p.name, p);
    for (const p of call.EXCEPTIONS) {
      if (p.name === "OTHERS") sig.others = true;
      else if (p.name !== "error_message") sig.EXCEPTIONS.add(p.name);
    }
    this.wrapped.set(fm, sig);

    const head = `${this.wrapperName()}=>${method}( `;
    const width = Math.max(0, ...Object.values(call).flat().map((p) => p.name.length));
    const lines = [];
    for (const [title, list] of Object.entries(call)) {
      list.filter((p) => title !== "EXCEPTIONS" || p.name !== "error_message").forEach((p, i) => {
        const lead = i === 0 ? title.padEnd(10) : " ".repeat(10);
        lines.push(`${lines.length ? " ".repeat(head.length) : head}${lead} ${p.name.padEnd(width)} = ${p.value}`);
      });
    }
    if (!lines.length) lines.push(head.trimEnd());
    lines[lines.length - 1] += " ).";
    b.out.push(...lines);
    if (sig.calls === 2) this.todo(s, `CALL FUNCTION '${fm}' twice: ${this.wrapperName()}=>${method}( ) has the parameters of all calls - a parameter one call leaves out is passed initial; check it against the function module`);
    this.map(s, `\`${this.wrapperName()}=>${method}( )\` - the function module behind a wrapper class, for a person to type and to release for ABAP Cloud`);
  },


  /** the wrapper class of the function modules - a stub: its parameters
   *  are generic until a person types them as the function module does */
  wrapperClass() {
    const w = this.wrapperName();
    const out = [
      `"! The function modules ${this.programName ?? this.className} calls, behind methods - written by report2cloud.`,
      "\"! It stays in a classic package (tier 2) and calls them as they are; the",
      "\"! report class calls the methods. Type every parameter as the function",
      "\"! module does (SE37), then release the class for ABAP Cloud (C1).",
      `CLASS ${w} DEFINITION PUBLIC FINAL CREATE PUBLIC.`, "", "  PUBLIC SECTION.", "",
    ];
    const signature = (sig) => {
      const l = [`    CLASS-METHODS ${sig.method}`];
      const section = (title, map, type) => {
        if (!map.size) return;
        l.push(`      ${title}`);
        for (const p of map.values()) l.push(`        ${p.name} TYPE ${p.table ? "STANDARD TABLE" : type}${title === "IMPORTING" ? " OPTIONAL" : ""}`);
      };
      section("IMPORTING", sig.IMPORTING, "any");
      section("EXPORTING", sig.EXPORTING, "any");
      section("CHANGING", sig.CHANGING, "any");
      const exc = [...sig.EXCEPTIONS, ...(sig.others ? ["error"] : [])];
      if (exc.length) {
        l.push("      EXCEPTIONS");
        for (const e of exc) l.push(`        ${e}`);
      }
      l[l.length - 1] += ".";
      return l;
    };
    for (const [fm, sig] of this.wrapped) out.push(`    " ${fm}`, ...signature(sig), "");
    out.push("ENDCLASS.", "", "", `CLASS ${w} IMPLEMENTATION.`, "");
    for (const [fm, sig] of this.wrapped) {
      out.push(`  METHOD ${sig.method}.`, "", `    CALL FUNCTION '${fm}'`);
      const pass = (title, map) => {
        if (!map.size) return;
        out.push(`      ${title}`);
        for (const p of map.values()) out.push(`        ${p.name} = ${p.name}`);
      };
      pass("EXPORTING", sig.IMPORTING);
      pass("IMPORTING", sig.EXPORTING);
      const changing = new Map([...sig.CHANGING].filter(([, p]) => !p.table));
      const tables = new Map([...sig.CHANGING].filter(([, p]) => p.table));
      pass("CHANGING", changing);
      pass("TABLES", tables);
      const exc = [...sig.EXCEPTIONS];
      if (exc.length || sig.others) {
        out.push("      EXCEPTIONS");
        exc.forEach((e, i) => out.push(`        ${e} = ${i + 1}`));
        out.push(`        OTHERS = ${exc.length + 1}`);
      }
      out[out.length - 1] += ".";
      if (exc.length || sig.others) {
        out.push("    CASE sy-subrc.");
        exc.forEach((e, i) => out.push(`      WHEN ${i + 1}.`, `        RAISE ${e}.`));
        out.push(`      WHEN ${exc.length + 1}.`, `        RAISE ${sig.others ? "error" : exc[exc.length - 1]}.`);
        out.push("    ENDCASE.");
      }
      out.push("", "  ENDMETHOD.", "");
    }
    out.push("ENDCLASS.");
    return out.join("\n");
  },
};
