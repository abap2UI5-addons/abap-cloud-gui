// The locals family of the converter - the local classes of the report: their types, statics and source. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  abaplint, child, findAll, key, kind, lc, nodeText, renderTokens, stmtTokens, uc, words,
} from "./abap.mjs";
import {
  BASE_METHODS, GUI, ICONS, REPORT_CALLS, declName, guiClass, indent, prefixCalls, salvTokens,
  tokenParents, trimBlank,
} from "./convert-shared.mjs";

export const localsMethods = {

  // --------------------------------------------------------------- locals

  /** whether a declaration of the class - a global, an inline declaration
   *  that became an attribute, a FORM's parameter - is typed with a local
   *  class or interface: then their definitions go to locals_def */
  localsInDecl() {
    const viaDecl = [...this.decls, ...this.forms.map((f) => f.stmt)].some((s) => s.getTokens().some((t) => this.localNames.has(lc(t.getStr()))));
    const viaHoisted = [...(this.hoisted ?? new Map()).values()].some((h) => [...this.localNames].some((n) => new RegExp(`\\b${n}\\b`, "i").test(h.decl)));
    return viaDecl || viaHoisted;
  },


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
  },


  /**
   * The local classes and interfaces of the report, as the local types of
   * the class. A method of a local class that writes the list, calls a FORM
   * or uses a global of the report is converted like an event block: the
   * report's data is reached through the instance of the class
   * (lcl_r2c=>app->gv, set in at_roundtrip_start( ), first in every roundtrip), its
   * constants and types through the class (zcl_x=>c_pi), the methods of the
   * runtime and the FORMs through the instance - the class declares the
   * local class a LOCAL FRIEND for that. Everything else is copied as it is.
   */
  /** the CLASS-DATA of the local classes the report class can write -
   *  PUBLIC and not READ-ONLY; the others are named in a TODO */
  localStatics() {
    const out = [];
    for (const u of this.locals.filter((x) => x.kind === "ClassDefinition")) {
      const cls = lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1]));
      let section = "PublicSection";
      for (const x of u.stmts) {
        if (["PublicSection", "ProtectedSection", "PrivateSection"].includes(kind(x))) section = kind(x);
        if (kind(x) === "ClassDataBegin") {
          this.todo(x, `CLASS-DATA BEGIN OF in ${cls} - a static structure starts initial in every roundtrip; declare it with a TYPES structure to keep it`);
          continue;
        }
        if (kind(x) !== "ClassData" || this.insideBegin(x)) continue;
        const name = lc(declName(x) ?? "");
        if (!name) continue;
        if (section !== "PublicSection" || words(x).includes("READ-ONLY")) {
          this.todo(x, `CLASS-DATA ${name} of ${cls} is not PUBLIC or READ-ONLY - it starts initial in every roundtrip (a roundtrip is a session of its own); make it PUBLIC to keep it with the app`);
          continue;
        }
        out.push({ cls, name, attr: `mr_cgui_static${out.length + 1}`, stmt: x });
      }
    }
    return out;
  },


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
          const mine = methodsOf.get(n) ?? new Set();
          const calls = new Set([...BASE_METHODS, ...REPORT_CALLS, ...formMethods].filter((x) => !mine.has(x)));
          // a method of the runtime the local class has one of its own name
          // of - list( ), message( ): a call of it stays the local class's,
          // but the chained one, list( )->write( ), is what a WRITE became,
          // and that is the report's
          const chained = new Set([...BASE_METHODS, ...REPORT_CALLS].filter((x) => mine.has(x)));
          const lines = [...pre, ...trimBlank(body)].map((l) => prefixCalls(l, calls, this.appRef, chained));
          const pad = (this.lines[b.stmt.getFirstToken().getRow() - 1].match(/^\s*/)[0]) + "  ";
          replace.push({ from: b.stmt.getLastToken().getRow() + 1, to: b.end.getFirstToken().getRow() - 1, lines: lines.map((l) => indent(l, pad.length)) });
          friends.add(n);
        }
      } else {
        // the definition: a type or constant of the report through the class
        for (const s of u.stmts) {
          const toks = stmtTokens(s);
          const parents = tokenParents(s);
          const salvAt = new Map(salvTokens(toks));
          toks.forEach((t, i) => {
            if (salvAt.has(i)) {
              subst.push({ row: t.getRow(), col: t.getCol(), len: t.getStr().length, text: salvAt.get(i) });
              return;
            }
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
  },


  fieldSymbolDecls(body) {
    if (!this.globalFieldSymbols) return [];
    const text = body.join("\n").toLowerCase();
    // a field symbol the method declares itself shadows the global one
    const own = (name) => new RegExp(`${name.replace(/[<>]/g, "\\$&")}\\s+(type|like|structure)\\b`).test(text);
    return this.globalFieldSymbols
      .filter((s) => text.includes(lc(declName(s))) && !own(lc(declName(s))))
      .map((s) => `${renderTokens(stmtTokens(s), new Map(), s.getColon()).replace(/^([\w-]+)(\s*):\s*/, "$1 ")}.`);
  },
};
