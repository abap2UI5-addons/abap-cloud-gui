// The decl family of the converter - the declarations: TABLES, header lines, inline data, the types of the report, the FORMs. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  abaplint, after, child, children, findAll, hasSeq, isToken, key, kind, lc, literal, nodeText,
  partTokens, renderTokens, stmtTokens, uc, words,
} from "./abap.mjs";
import {
  GUI, LVC_TYPES, REFUSED, RESERVED_METHODS, alignData, declName, dropWords, hasHeaderLine,
  renderScreenChain, sameColon, selectTargetType, tokenParents,
} from "./convert-shared.mjs";

export const declMethods = {

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
  },


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
    // an inline or DATA declaration, or a parameter of a method
    const declares = (list, name) => list.some((x) => findAll(x, "InlineData").some((d) => lc(d.getTokens()[2]?.getStr() ?? "") === name) ||
      (kind(x) === "Data" && lc(findAll(x, "DefinitionName")[0]?.getFirstToken().getStr() ?? "") === name) ||
      findAll(x, "MethodParamName").some((p) => lc(p.getFirstToken().getStr()) === name));
    // a local class is its definition and its implementation together: an
    // attribute or a parameter of the definition is what the implementation reads
    const classes = new Map();
    for (const u of this.locals) {
      const cls = lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1]));
      classes.set(cls, [...(classes.get(cls) ?? []), ...u.stmts]);
    }
    const elsewhere = (e, name) => {
      const own = [...this.forms.map((f) => f.body), ...classes.values()].filter((list) => !declares(list, name));
      const units = [...this.events.filter((x) => x !== e).map((x) => x.stmts), ...own];
      return units.some((list) => list.some((x) => reads(x, name)));
    };
    for (const v of inEvents) {
      if (!v.name || this.hoisted.has(v.name) || this.globalData.has(v.name) || !elsewhere(v.e, v.name)) continue;
      const type = this.inlineType(v);
      if (!type) {
        this.refuse(v.d, `${v.name} is declared inline in an event block and used in another one - event blocks open no scope, so it is a global of the report; its type cannot be told here (a dependency of the report): declare it with DATA in the report`);
        continue;
      }
      const { types, data } = typeof type === "string" ? { data: type } : type;
      this.hoisted.set(v.name, { decl: `DATA ${v.name} ${data}.`, types, stmt: v.s, keys: new Set(v.d.getTokens().map(key)) });
      this.globalData.add(v.name);
    }
  },


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
    // a static attribute or a constant of a class: LIKE it - the stand-in's
    // where the class has one
    m = new RegExp(`^DATA\\(\\s*${esc}\\s*\\)\\s*=\\s*([\\w/]+)=>([\\w/]+)\\s*\\.?$`, "i").exec(text);
    if (m) return `LIKE ${GUI.classes[lc(m[1])] ?? lc(m[1])}=>${lc(m[2])}`;
    // abaplint leaves the target of a SELECT untyped (SELECT_todo)
    if (/^SELECT\b/i.test(text)) return selectTargetType(text, lc(name));
    const t = this.programTypes().get(lc(name));
    if (!t) return undefined;
    const cls = t.constructor.name;
    // a RETURNING type of the DDIC the repository does not carry (a data
    // element of the system): the class names it as the report's method does
    if (cls === "UnknownType") {
      const unknown = /^([\w/]+) not found/i.exec(t.getError?.() ?? "");
      return unknown && !/^[yz]/i.test(unknown[1]) ? `TYPE ${lc(unknown[1])}` : undefined;
    }
    if (["VoidType", "UnknownType", "GenericObjectReferenceType", "AnyType", "DataType", "SimpleType"].includes(cls)) return undefined;
    let abap;
    try {
      abap = t.toABAP?.();
    } catch {
      // a type of an unknown dependency deeper inside - a table of it
      return undefined;
    }
    if (!abap || /todo|check_syntax|\bSELECT_/i.test(abap)) return undefined;
    // a reference to a class or an interface: its name as the report writes names
    if (/^REF TO [\w/]+$/i.test(abap)) return `TYPE REF TO ${lc(abap.slice(7))}`;
    return `TYPE ${abap}`;
  },


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
  },


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
  },


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

      // CONTROLS ts TYPE TABSTRIP - the tabstrip of a dynpro: its activetab;
      // CONTROLS tc TYPE TABLEVIEW USING SCREEN n - a table control: lines,
      // current_line, top_line
      const ctl = k === "Controls" ? /^controls\s+(\w+)\s+type\s+(tabstrip|tableview\s+using\s+screen\s+\S+)$/i.exec(renderTokens(stmtTokens(s)).replace(/\s*\.$/, "")) : null;
      if (ctl) {
        const type = /^tabstrip$/i.test(ctl[2]) ? "ty_s_tabstrip" : "ty_s_tableview";
        heading("global data of the report");
        push(`DATA ${lc(ctl[1])} TYPE z2ui5_cl_cgui_report=>${type}.`);
        this.map(s, type === "ty_s_tabstrip"
          ? "`TYPE z2ui5_cl_cgui_report=>ty_s_tabstrip` - `activetab` is the function code of the selected tab, as before"
          : "`TYPE z2ui5_cl_cgui_report=>ty_s_tableview` - `lines`, `current_line`, `top_line` as before; the browser shows every line, `cols` is not there");
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
      if (h.types) sections.types.push(...h.types);
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
  },


  isTables(name) {
    return this.decls.some((s) => kind(s) === "Tables" && lc(declName(s)) === name);
  },


  /** the token after the words seq of a statement: MEMORY ID car -> CAR */
  tokenAfter(s, ...seq) {
    const toks = stmtTokens(s).map((t) => t.getStr());
    for (let i = 0; i + seq.length < toks.length; i++) {
      if (seq.every((w, j) => uc(toks[i + j]) === w)) return toks[i + seq.length];
    }
    return undefined;
  },


  /** a global declaration as an attribute: LIKE a DDIC field becomes TYPE */
  renderDecl(s) {
    const ov = this.rewrites(s, {});
    this.likeToType(s, ov);
    this.tableKey(s, ov);
    const after = this.headerDecl(s, ov);
    const t = renderTokens(stmtTokens(s), ov, s.getColon()).replace(/^(\w+)(\s*):\s*/, "$1 ");
    return `${t}.${after.map((l) => `\n${l}`).join("")}`;
  },


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
  },


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
  },


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
  },


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
  },


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
  },


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
  },


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
  },


  /** a TYPES of the report that declares a table (TYPES x TYPE ... TABLE OF ...) */
  isTableType(name) {
    const n = lc(name);
    return this.decls.some((s) => kind(s) === "Type" && lc(declName(s)) === n && hasSeq(stmtTokens(s).map((t) => lc(t.getStr())), "table", "of"));
  },


  tablesType(structure, isData) {
    const name = `ty_t_${structure.replace(/[^a-z0-9_]/gi, "_")}`.slice(0, 30);
    if (!this.tablesTypes.has(name)) {
      this.tablesTypes.set(name, `TYPES ${name} ${isData ? "LIKE" : "TYPE"} STANDARD TABLE OF ${structure} WITH DEFAULT KEY.`);
    }
    return `TYPE ${name}`;
  },


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
  },


  /** whether `n` names a table with a header line in the body being written:
   *  a global one (a select-option, RANGES, a DATA with OCCURS or WITH
   *  HEADER LINE) not shadowed by a local, a FORM's own, or a TABLES
   *  parameter used with its header line */
  hasHeader(n) {
    const b = this.currentBody;
    if (b?.localWa?.has(n) || b?.headerParams?.has(n)) return true;
    return this.headerTables.has(n) && !this.currentLocals?.has(n);
  },


  /** a DATA table with a header line (not a select-option or RANGES, whose
   *  bare name stays the range table: `x IN s_id`, `lines( s_id )`) */
  isDataHeader(n) {
    const b = this.currentBody;
    if (b?.localWa?.has(n) || b?.headerParams?.has(n)) return true;
    return this.globalHeader.has(n) && !this.currentLocals?.has(n);
  },


  /** the work area that stands for the header line of `tab` in body `b` */
  headerWa(b, tab) {
    if (b.localWa?.has(tab)) return b.localWa.get(tab);
    const global = this.globalHeader.get(tab);
    if (global && !this.currentLocals?.has(tab)) return global.wa;
    return this.useWa(b.ctx.method, tab);
  },


  /** a statement that names a table with a header line alone - its header
   *  line is written by headerLine( ) */
  headerLineTouches(s) {
    const names = stmtTokens(s).map((t) => lc(t.getStr()));
    return names.some((n, i) => this.hasHeader(n) && names[i + 1] !== "-"
      && (i === 0 || !["-", "->", "=>", "~"].includes(names[i - 1])));
  },


  /** the work area that stands for the header line of a select-option or
   *  RANGES table in a method */
  useWa(method, name) {
    const wa = (this.identifiers.has(`ls_${name}`) ? `ls_r2c_${name}` : `ls_${name}`).slice(0, 30);
    if (!this.methodWa.has(method)) this.methodWa.set(method, new Map());
    this.methodWa.get(method).set(name, wa);
    return wa;
  },


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
  },
};
