// The calls family of the converter - SUBMIT, CALL TRANSACTION, CALL SELECTION-SCREEN, PERFORM, the popups and MESSAGE, SET PF-STATUS / TITLEBAR. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, children, findAll, hasSeq, isToken, key, kind, lc, literal, nodeText, renderTokens,
  stmtTokens, uc, unquote, words,
} from "./abap.mjs";
import {
  CLOSERS, GUI, ICONS, OPENERS, batchInput, declName, defaultClassName, functionParams, renderCall,
  renderNamedCall, renderTableCall, shortText,
} from "./convert-shared.mjs";

export const callsMethods = {

  /**
   * SUBMIT report [WITH ...] [VIA SELECTION-SCREEN] [USING SELECTION-SET v]
   * [USING SELECTION-SCREEN dynnr] [AND RETURN] -> submit( report = the class values = ... ): the runtime
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
    if (hasSeq(w, "USING", "SELECTION", "-", "SETS")) {
      this.refuse(s, "SUBMIT ... USING SELECTION-SETS OF PROGRAM - the class has its own variants only");
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
    // USING SELECTION-SCREEN dynnr: the screen of the called class, its
    // selection_screen_dynnr( ) - the token after SCREEN
    const screenAt = ch.findIndex((c, i) => isToken(c) && uc(c.get().getStr()) === "SCREEN" && wordAt(i - 1) === "-" && wordAt(i - 2) === "SELECTION" && wordAt(i - 3) === "USING");
    if (screenAt >= 0 && ch[screenAt + 1]) params.push({ name: "using_selection_screen", value: text(ch[screenAt + 1]) });
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
  },


  /**
   * CALL TRANSACTION code [AND SKIP FIRST SCREEN] -> call_transaction( code
   * skip_first ): the runtime starts the report class of the transaction -
   * the catalog of the installation names it - and Back returns here. With
   * USING (batch input) it stays refused. False when not converted.
   */
  callTransaction(s, b) {
    if (batchInput(s)) return false;
    const w = words(s);
    const ov = this.rewrites(s, b.ctx, b);
    const code = nodeText(child(s, "Source"), ov);
    const skip = hasSeq(w, "SKIP", "FIRST", "SCREEN");
    b.out.push(skip
      ? renderNamedCall("call_transaction", [{ name: "code", value: code }, { name: "skip_first", value: "abap_true" }])
      : renderNamedCall("call_transaction", [{ value: code }]));
    if (w.includes("AUTHORITY")) this.note("CALL TRANSACTION ... WITH / WITHOUT AUTHORITY-CHECK - dropped, the called report class checks its own authorizations");
    this.map(s, `\`call_transaction( )\` - the report class of the transaction${skip ? " runs straight away" : ""} (the catalog of set_catalog( ) names it, else the code is taken as the class), Back returns here`);
    this.todo(s, `CALL TRANSACTION ${code}: the transaction must be in the catalog of the installation (set_catalog( )) with the class its report became - or the code be that class`);
    if (this.followedByCode(b)) {
      this.todo(s, "the statements after CALL TRANSACTION ran when the transaction came back - here they run before it starts (call_transaction( ) navigates when the method returns); move them to where they belong");
    }
    return true;
  },


  /** the literal VALUE of a CONSTANTS of the program named name - of the
   *  report or of one of its local classes; undefined when there is none or
   *  it is not a literal */
  constantValue(name) {
    const want = lc(name);
    for (const x of this.stmts) {
      if (kind(x) !== "Constant" || lc(declName(x) ?? "") !== want) continue;
      const toks = stmtTokens(x);
      const at = toks.findIndex((t) => uc(t.getStr()) === "VALUE");
      const v = at >= 0 ? toks[at + 1]?.getStr() : undefined;
      return v && /^['`]/.test(v) ? v : undefined;
    }
    return undefined;
  },


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
    // a constant names the screen as often as a literal does - its VALUE
    const text = nodeText(src).trim();
    const value = /^[a-z_][\w]*$/i.test(text) ? this.constantValue(text) : undefined;
    const nr = (value ?? text).replace(/['`]/g, "").padStart(4, "0");
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
  },


  /** whether statements of the body still run after the current one - the
   *  closers of the blocks it stands in do not count, nor the other
   *  branches of an IF or CASE it stands in */
  followedByCode(b) {
    const { branch, after } = this.tailOf(b);
    return after || branch.some((x) => kind(x) !== "Comment");
  },


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
  },


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
  },


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
  },


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
  },


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
  },


  // ------------------------------------------------------------- functions

  /**
   * The synchronous popups: POPUP_TO_CONFIRM, POPUP_TO_CONFIRM_STEP and
   * POPUP_TO_DECIDE become popup_to_decide( ) with the two buttons as the
   * options (the answers 1, 2 and A are the classic ones), POPUP_GET_VALUES
   * becomes popup_get_values_sval( ) with its SVAL table. The popup opens
   * when the method returns, and the answer arrives in a method of its own,
   * on_popup_n( answer ), named by then - so the statements after the call,
   * in their branch, go on there: the event block is cut at the call. Where
   * it cannot be cut (a FORM, a loop), the popup gets a ucomm of its own
   * for at_user_command( ) and a TODO.
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
    const callback = `on_popup_${this.popupCount}`;
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
    } else if (fm === "POPUP_TO_DECIDE_LIST") {
      // the lines of T_SPOPLI are the options, the answer is the number of
      // the line or A - as popup_to_decide( ) answers
      const question = joined("textline1", "textline2", "textline3");
      const list = target("t_spopli");
      if (!question || !list) {
        this.refuse(s, "POPUP_TO_DECIDE_LIST without TEXTLINE1 and TABLES t_spopli - not understood");
        return;
      }
      method = "popup_to_decide_list";
      params = [{ name: "question", value: question }, { name: "list", value: list }, { name: "ucomm", value: literal(ucomm) }];
      if (arg("titel")) params.push({ name: "title", value: arg("titel") });
      if (target("answer")) prologue.push(`${target("answer")} = popup_answer( ).`);
      if (p.has("start_col") || p.has("start_row") || p.has("cursorline") || p.has("mark_flag")) {
        this.note("POPUP_TO_DECIDE_LIST ... START_COL / START_ROW / CURSORLINE / MARK_FLAG - dropped, the popup is centred and takes one choice");
      }
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
    // the call names the callback; set back to the ucomm where nothing is cut
    const at = out.length;
    out.push(renderNamedCall(method, params.map((x) => (x.name === "ucomm" ? { name: "then", value: literal(uc(callback)) } : x))));
    // IF sy-subrc <> 0 right after the call checked its EXCEPTIONS - the
    // popup of the runtime raises none, the block is dropped
    const { branch } = this.tailOf(b);
    const first = branch.findIndex((x) => kind(x) !== "Comment");
    // only an IF on sy-subrc alone: one that also asks the answer (IF
    // sy-subrc <> 0 OR lv_answer = 'A') stays - in the callback sy-subrc is 0
    // and the rest of the condition is still the cancel check
    const onSubrcOnly = (x) => {
      const ws = stmtTokens(x).map((t) => uc(t.getStr()));
      return /\bsy\s*-\s*subrc\b/i.test(renderTokens(stmtTokens(x))) && !ws.includes("OR") && !ws.includes("AND");
    };
    if (first >= 0 && kind(branch[first]) === "If" && onSubrcOnly(branch[first])) {
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
    const cut = this.continueIn(s, b, {
      method: callback, callback: true, ctx: { method: callback },
      prologue: prologue.map((l) => l.replace(/\bpopup_answer\( \)/g, "answer")),
      what: `CALL FUNCTION '${fm}'`, where: `at_user_command( ) with ucomm ${ucomm} (popup_answer( ) is the answer)`,
    });
    if (cut) {
      this.map(s, `\`${method}( )\` - the answer arrives in \`${callback}( answer )\`, where the statements after the call go on`);
      return;
    }
    out[at] = renderNamedCall(method, params);
    if (prologue.length) out.push(...prologue.map((l) => `" TODO in at_user_command( ) with ucomm ${ucomm}: ${l}`));
    this.map(s, `\`${method}( )\` - the answer arrives in \`at_user_command( )\` with ucomm \`${ucomm}\``);
  },


  /**
   * The statements after the current one, in its branch, go on in another
   * method: the event block is cut at the call (CALL SELECTION-SCREEN, a
   * popup). The local data they use is declared anew there - with a TODO,
   * since a value set before the call is not there any more. Inside a
   * FORM, a loop, or when statements follow the block the call stands in,
   * nothing is cut: a TODO says where to go on. True when it was cut; a
   * callback continuation becomes a public method callback( answer ).
   */
  continueIn(s, b, { field, method, ctx, prologue = [], what, where, note, callback = false }) {
    const { branch, after } = this.tailOf(b);
    if (!branch.some((x) => kind(x) !== "Comment") && !after) {
      if (!callback) return false;
      // nothing follows - the callback holds the prologue only
      this.continuations.push({ method, field, callback, stmts: [], ctx: { ...ctx, prologue } });
      return true;
    }
    const goOn = `the statements after it run before it shows - its answer arrives in ${where}; go on there`;
    if (b.ctx.form) {
      this.todo(s, `${what} in FORM ${b.ctx.form.name}: ${goOn}`);
      return false;
    }
    if (after) {
      this.todo(s, `${what}: statements follow the block it stands in, and ${goOn}`);
      return false;
    }
    if (b.blocks.some((k) => ["Loop", "Do", "While", "SelectLoop", "LoopAtScreen", "Provide"].includes(k))) {
      this.todo(s, `${what} inside a loop: the loop goes on before it shows - its answer arrives in ${where}; go on there`);
      return false;
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
    this.continuations.push({ method, field, callback, stmts: [...decls, ...branch], ctx: { ...ctx, prologue } });
    const first = branch.findIndex((x) => kind(x) !== "Comment");
    if (first >= 0) this.map(branch[first], note ?? (callback ? `\`${method}( answer )\` - the statements after ${what}` : `\`${method}( )\` - WHEN \`${field}\`: the statements after ${what}`));
    b.skipTo = b.index + 1 + branch.length;
    return true;
  },
};
