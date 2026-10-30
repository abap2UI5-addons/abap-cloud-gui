// The rewrites family of the converter - the rewrites inside a statement: IN on internal tables, strict SQL, the released successors, chains. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  abaplint, after, child, children, findAll, isToken, key, kind, lc, literal, nodeText, partTokens,
  renderTokens, stmtTokens, uc, unquote, words,
} from "./abap.mjs";
import { SUCCESSOR_TABLES } from "./successors.mjs";
import {
  ABAP_BROWSER, CONSTRUCTORS, DECL, DEMO_OUTPUT, ICONS, LVC_TYPES, SALV, SCREEN_FLAGS, declName,
  frontendMember, frontendName, guiClass, guiMember, headerLineContext, salvTokens, tokenParents,
} from "./convert-shared.mjs";

export const rewritesMethods = {

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
  },


  addPrelude(method, line) {
    if (!this.prelude.has(method)) this.prelude.set(method, []);
    if (!this.prelude.get(method).includes(line)) this.prelude.get(method).push(line);
  },


  catchInto(s) {
    const t = renderTokens(stmtTokens(s));
    const m = /\bINTO\s+(.+)$/i.exec(t);
    return m ? ` INTO ${m[1]}` : "";
  },


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
    // the SALV of the stand-in mode - exceptions, constants, types
    for (const [i, text] of salvTokens(toks)) ov.set(key(toks[i]), text === "" ? null : text);
    for (let i = 0; i < toks.length; i++) {
      const t = lc(toks[i].getStr());
      const prev = i > 0 ? toks[i - 1].getStr() : "";
      // a component follows a Dash that touches its neighbours (wa-f); a
      // subtraction's dash has blanks around it (WDashW) and the name after
      // it is an operand of its own
      const component = (prev === "-" && toks[i - 1].constructor.name === "Dash") || prev === "->" || prev === "=>" || prev === "~";
      if (component) continue;
      // cl_gui_textedit, cl_gui_custom_container, ... - their stand-ins
      // (not a token the SALV of the stand-in mode rewrote - cl_gui_column_tree=>relat_*)
      if (this.guiVars?.size && guiClass(t) && !ov.has(key(toks[i]))) {
        ov.set(key(toks[i]), guiClass(t));
        continue;
      }
      // cntb_btype_sep of type pool CNTB - the constant of the toolbar's stand-in
      if (this.guiVars?.size && /^cntb_btype_\w+$/.test(t) && guiMember("z2ui5_cl_cgui_gui_toolbar", t)) {
        ov.set(key(toks[i]), `z2ui5_cl_cgui_gui_toolbar=>${t}`);
        continue;
      }
      // cl_demo_output=>write( ), if_demo_output - the stand-in that writes
      // into the list of the report
      if (t === "cl_demo_output" && toks[i + 1]?.getStr() === "=>" && DEMO_OUTPUT.includes(lc(toks[i + 2]?.getStr() ?? ""))) {
        ov.set(key(toks[i]), "z2ui5_cl_cgui_demo_output");
        continue;
      }
      // cl_abap_browser=>show_html( ) - the stand-in that shows the
      // document in a dialog box or in its container
      if (t === "cl_abap_browser" && toks[i + 1]?.getStr() === "=>" && ABAP_BROWSER.includes(lc(toks[i + 2]?.getStr() ?? ""))) {
        ov.set(key(toks[i]), "z2ui5_cl_cgui_abap_browser");
        continue;
      }
      // cl_gui_cfw=>compute_metric_from_dynp( ) - the size it computes is
      // the value it is given: the browser lays the controls out itself
      if (t === "cl_gui_cfw" && toks[i + 1]?.getStr() === "=>" && lc(toks[i + 2]?.getStr() ?? "") === "compute_metric_from_dynp") {
        ov.set(key(toks[i]), "z2ui5_cl_cgui_gui");
        continue;
      }
      if (t === "if_demo_output") {
        ov.set(key(toks[i]), "z2ui5_if_cgui_demo_output");
        continue;
      }
      // cl_gui_frontend_services=>gui_upload, =>action_ok - the frontend
      // services of the runtime, when it has that member
      if (t === "cl_gui_frontend_services" && toks[i + 1]?.getStr() === "=>" && frontendMember(frontendName(toks, i))) {
        ov.set(key(toks[i]), "z2ui5_cl_cgui_frontend");
        // =>('CLIPBOARD_EXPORT') - a dynamic call of a literal name is the
        // static call of that method
        if (toks[i + 2]?.getStr() === "(") {
          ov.set(key(toks[i + 2]), frontendName(toks, i));
          ov.set(key(toks[i + 3]), null);
          ov.set(key(toks[i + 4]), null);
        }
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
      // after TYPE / OF / LIKE, or the type of a constructor expression - CONV tv_nodekey( ... )
      if (LVC_TYPES[t] && (["type", "of", "like"].includes(lc(prev))
          || (CONSTRUCTORS.has(lc(prev)) && toks[i + 1]?.getStr().startsWith("(")))) {
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
    this.successorSql(s, ov);
    this.strictSql(s, ov);
    this.gridRewrites(toks, ov, ctx);
    return ov;
  },


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
  },


  /** map( ) once per node - rewrites( ) runs more than once for a statement */
  mapOnce(s, node, target) {
    this.mappedNodes ??= new Set();
    const k = key(node.getFirstToken());
    if (this.mappedNodes.has(k)) return;
    this.mappedNodes.add(k);
    this.map(s, target);
  },


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
  },


  /** SELECT from a table of SUCCESSOR_TABLES as the SELECT of its
   *  successor: the table, the columns of the field list under their old
   *  names, those of WHERE, ORDER BY, GROUP BY and HAVING - only when every
   *  column has its counterpart, one table, no join and no SELECT * */
  successorSql(s, ov) {
    if (!this.successors || !["Select", "SelectLoop"].includes(kind(s))) return;
    const tabs = findAll(s, "DatabaseTable");
    if (tabs.length !== 1 || findAll(s, "SQLJoin").length) return;
    const old = lc(nodeText(tabs[0]));
    const succ = SUCCESSOR_TABLES[old];
    if (!succ) return;
    const list = findAll(s, "SQLFieldList")[0];
    if (!list || list.getTokens().some((t) => t.getStr() === "*")) {
      this.todo(s, `SELECT * FROM ${old}: its successor ${succ.name} has other columns - name the columns, the converter reads them from the successor then (--successors)`);
      return;
    }
    const names = findAll(s, "SQLFieldName");
    const aliased = findAll(s, "SQLAliasField");
    const column = (n) => lc(n).replace(/^.*~/, "");
    const missing = [...new Set([...names.map((n) => lc(nodeText(n))), ...aliased.map((n) => column(nodeText(n)))])].filter((c) => !succ.columns[c]);
    if (missing.length) {
      this.todo(s, `SELECT FROM ${old}: ${missing.join(", ")} ${missing.length > 1 ? "have" : "has"} no certain counterpart in ${succ.name} - the table stays`);
      return;
    }
    ov.set(key(tabs[0].getFirstToken()), succ.name);
    for (const f of children(list, "SQLField")) {
      const n = child(f, "SQLFieldName");
      // a column of the field list under its old name - INTO stays as it is
      if (n && f.getChildren().length === 1) ov.set(key(n.getFirstToken()), `${succ.columns[lc(nodeText(n))]} AS ${lc(nodeText(n))}`);
    }
    for (const n of names) if (!ov.has(key(n.getFirstToken()))) ov.set(key(n.getFirstToken()), succ.columns[lc(nodeText(n))]);
    for (const a of aliased) ov.set(key(a.getFirstToken()), `${succ.name}~${succ.columns[column(nodeText(a))]}`);
    this.note(`--successors: a SELECT of ${old} reads ${succ.name}, the columns under their old names - the types of the targets stay those of ${old}; type them with the successor`);
    this.map(s, `\`SELECT ... FROM ${succ.name}\` - the released successor of ${old}, the columns under their old names`);
  },


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
  },
};
