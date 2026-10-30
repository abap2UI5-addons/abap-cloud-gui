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
// a static import, not a require( ): the converter runs in the browser too
// (the playground of the site, site/)
//
// The converter is one class in ten files: convert.mjs has its core - the
// parse, the segments and the event blocks, the dispatch of a statement,
// the class written at the end - and convert( ); the families of
// statements are convert-<family>.mjs, each an object of methods mixed
// into the prototype below; the tables and the helpers they share are
// convert-shared.mjs, which re-exports here what the CLI and the tests
// import.
import {
  abaplint, after, child, children, findAll, hasSeq, isToken, key, kind, lc, literal, nodeText,
  partTokens, renderTokens, stmtTokens, uc, unquote, words,
} from "./abap.mjs";
import { classXml, longLines, normalizeAbap } from "./abapgit.mjs";
import { refusalOf } from "./refusals.mjs";
import { functionKey } from "./textpool.mjs";
import { Indent } from "@abaplint/core/build/src/pretty_printer/indent.js";
import {
  BUILTIN_TYPES, CHAINABLE, CLOSERS, DECL, EVENTS, GUI, GUI_CONTROL, LAYOUT_ONLY, OPENERS, REFUSED,
  REFUSED_LIST, RESERVED_METHODS, SALV, SCREEN_FIELDS, SUCCESSORS, UNCATALOGUED, batchInput,
  caseBody, declName, defaultClassName, dropEmptyIfs, findTo, frontendName, guiClass, guiEvent,
  hasHeaderLine, indent, lineFieldNames, renderChain, renderNamedCall, renderScreenChain,
  renderTableCall, salvRelations, setSalvMode, sameColon, shift, shortText, tokenParents, trimBlank,
  underName,
} from "./convert-shared.mjs";
import { dynproMethods } from "./convert-dynpro.mjs";
import { guiMethods } from "./convert-gui.mjs";
import { alvMethods } from "./convert-alv.mjs";
import { screenMethods } from "./convert-screen.mjs";
import { listMethods } from "./convert-list.mjs";
import { callsMethods } from "./convert-calls.mjs";
import { functionsMethods } from "./convert-functions.mjs";
import { localsMethods } from "./convert-locals.mjs";
import { declMethods } from "./convert-decl.mjs";
import { rewritesMethods } from "./convert-rewrites.mjs";

export { UNCATALOGUED, FRONTEND, GUI, SALV, RESERVED_METHODS, hasHeaderLine, declName, selectTargetType, defaultClassName, REFUSED_MESSAGES } from "./convert-shared.mjs";

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
    // the classes of the report's repository it hands a SAP GUI control to -
    // converted beside the report (convertGuiClasses( ) of convert( ))
    this.guiDeps = new Set();
    this.programName = opts.programName;
    this.className = opts.className;
    // classFor(program) names the class of another report of the input -
    // the one a SUBMIT starts; undefined when the report is not there
    this.classFor = opts.classFor;
    // the command field of the SAP GUI in the page header - off with
    // commandField: false
    this.commandField = opts.commandField !== false;
    // wrappers: a CALL FUNCTION of a function module with no counterpart
    // calls a method of a wrapper class, written beside the class
    this.wrappers = opts.wrappers === true;
    // successors: a SELECT of a table with a released successor whose
    // columns map one to one reads the successor (lib/successors.mjs)
    this.successors = opts.successors === true;
    this.wrapped = new Map();
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
    out.guiDeps = [...this.guiDeps];
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
      if (["Data", "DataBegin", "Constant", "ConstantBegin", "Parameter", "SelectOption", "Ranges", "Tables", "Controls"].includes(k)) {
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
      const text = salvRelations(u.stmts.map((x) => lc(renderTokens(stmtTokens(x)))).join(" "));
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


  // --------------------------------------------------------------- generate

  generate() {
    const cls = this.className;
    this.continuations = [];
    // the callbacks of the popups - public methods on_popup_n( answer )
    this.callbacks = [];
    // the fields a WRITE ... UNDER refers to - their WRITE gets their name
    this.underTargets = new Set();
    for (const x of this.stmts) {
      if (kind(x) !== "Write") continue;
      const ch = x.getChildren();
      const at = ch.findIndex((c) => isToken(c) && uc(c.get().getStr()) === "UNDER");
      if (at >= 0 && ch[at + 1]) this.underTargets.add(underName(nodeText(ch[at + 1])));
    }
    // GET CURSOR FIELD asks for the name of the field clicked - every WRITE
    // of a data object then writes it with its name
    this.cursorField = this.stmts.some((x) => kind(x) === "GetCursor" && words(x).includes("FIELD"));
    // READ LINE / MODIFY LINE ... FIELD VALUE f - f is written with its name
    this.lineFields = new Set(this.stmts.filter((x) => ["ReadLine", "ModifyLine"].includes(kind(x))).flatMap((x) => lineFieldNames(x)));
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

    if (this.commandField) {
      const init = methods.find((m) => m.name === "initialization");
      const lines = ["\" the command field of the SAP GUI: transactions, /n, /o and OK codes", "set_command_field( )."];
      if (init) init.body.unshift(...lines, "");
      else methods.push({ name: "initialization", body: lines });
    }

    if (this.dynpro) methods.push(...this.dynproMethods());

    // the continuations - a continuation may hold a call that cuts again
    if (this.continuations.length) {
      const dynnr = [];
      const ucomm = [];
      const screen = [];
      while (this.continuations.length) {
        const c = this.continuations.shift();
        if (c.callback) {
          this.callbacks.push({ name: c.method, body: this.convertBody(c.stmts, c.ctx) });
          continue;
        }
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
    // their CLASS-DATA: a roundtrip is a session of its own on a system, the
    // static attributes start initial - the app keeps them in between
    const statics = this.localStatics();
    if (statics.length) {
      const fs = "FIELD-SYMBOLS <lv_cgui_static> TYPE any.";
      methods.push({ name: "cgui_statics_keep", body: [
        "\" the CLASS-DATA of the local classes - kept with the app until the next roundtrip", fs,
        ...statics.flatMap((x) => [`CREATE DATA ${x.attr} LIKE ${x.cls}=>${x.name}.`, `ASSIGN ${x.attr}->* TO <lv_cgui_static>.`, `<lv_cgui_static> = ${x.cls}=>${x.name}.`]),
      ] });
      methods.push({ name: "cgui_statics_restore", body: [
        "\" the CLASS-DATA of the local classes - as the last roundtrip left them", fs,
        ...statics.flatMap((x) => [`IF ${x.attr} IS BOUND.`, `  ASSIGN ${x.attr}->* TO <lv_cgui_static>.`, `  ${x.cls}=>${x.name} = <lv_cgui_static>.`, "ENDIF."]),
      ] });
      this.staticLines = ["\" the CLASS-DATA of the local classes between two roundtrips",
        ...statics.flatMap((x) => [`" ${x.cls}=>${x.name}`, `DATA ${x.attr} TYPE REF TO data.`])];
      this.map(statics[0].stmt, "`cgui_statics_keep( )` / `cgui_statics_restore( )` - the CLASS-DATA of the local classes kept with the app between two roundtrips");
    }
    // the handlers of the controls are methods of local classes: the event
    // of a control hands them the instance like every event method
    // the local classes reach the report through its instance - set once at
    // the start of every roundtrip
    if (locals.app) methods.push({ name: "at_roundtrip_start", body: [`${this.appRef} = me.`] });
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
    if (this.callbacks.length) {
      if (pub.length) lines.push("");
      lines.push("    \" the answers of the popups - the statements after the CALL FUNCTION");
      this.callbacks.forEach((c, i) => {
        if (i > 0) lines.push("");
        lines.push(`    METHODS ${c.name}`, "      IMPORTING", "        answer TYPE string.");
      });
    }
    lines.push("");
    lines.push("  PROTECTED SECTION.");
    const order = ["initialization", "selection_screen", "selection_screen_dynnr", "at_selection_screen_output", "at_selection_screen_on",
      "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_on_end_of",
      "at_selection_screen_on_exit", "at_selection_screen_on_help", "at_selection_screen", "start_of_selection", "end_of_selection", "top_of_page",
      "top_of_page_line_selection", "end_of_page", "at_line_selection", "at_link_click", "at_user_command", "at_value_request",
      "after_call_selection_screen", "dynpro_screen", "dynpro_pbo", "dynpro_pai", "at_gui_event", "after_call_screen", "at_roundtrip_start",
      "cgui_statics_keep", "cgui_statics_restore"];
    methods.sort((a, b) => order.indexOf(a.name) - order.indexOf(b.name));
    for (const m of methods) lines.push(`    METHODS ${m.name} REDEFINITION.`);
    lines.push("");
    lines.push("  PRIVATE SECTION.");
    if (this.privateDataLines.length) {
      lines.push("    \" global data of the report typed with its local classes - local types", "    \" can type the private section only", ...this.privateDataLines.map((l) => indent(l, 4)), "");
    }
    if (this.staticLines?.length) lines.push(...this.staticLines.map((l) => indent(l, 4)), "");
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
    const impl = [...methods, ...this.callbacks, ...(this.privateMethods ?? []), ...formMethods];
    for (const m of impl) {
      lines.push("");
      lines.push(`  METHOD ${m.name}.`);
      lines.push("");
      const was = [...(this.methodWa.get(m.name) ?? new Map())].map(([tab, wa]) => `DATA ${wa} LIKE LINE OF ${tab}.`);
      const globalFs = [...was, ...(this.prelude.get(m.name) ?? []), ...this.fieldSymbolDecls(m.body)];
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
    if (this.wrapped.size) {
      const w = this.wrapperName();
      files[`${w}.clas.abap`] = normalizeAbap(this.reindent(this.wrapperClass(), `${w}.clas.abap`));
      files[`${w}.clas.xml`] = classXml(w, `report2cloud - the function modules of ${this.programName ?? cls}`);
    }

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
      if (k === "SetHandler" && (allOfGui || [...this.guiVars.keys()].some((v) => new RegExp(`\\bfor\\s+([\\w/]+\\s*=>\\s*)?(me\\s*->\\s*)?${v}\\b`).test(t)))) {
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
    // CALL TRANSACTION without batch input is call_transaction( )
    if (REFUSED[k] && !(k === "CallTransaction" && !batchInput(s)) && !["ReadLine", "ModifyLine"].includes(k)) {
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
      case "CallTransaction":
        if (this.callTransaction(s, b)) return;
        break;
      case "ReadLine":
      case "ModifyLine":
        if (!this.lineAccess(s, b)) this.refuse(s, REFUSED[k]);
        return;
      case "CallSelectionScreen":
        this.callSelectionScreen(s, b);
        return;
      case "GetCursor": {
        // GET CURSOR FIELD f VALUE v LINE l OFFSET o in AT LINE-SELECTION -
        // the field, value, line and offset of the click
        const parts = new Map();
        let word;
        for (const c of s.getChildren()) {
          if (isToken(c)) word = uc(c.getFirstToken().getStr());
          else if (kind(c) === "Target" && word) parts.set(word, nodeText(c, this.rewrites(s, b.ctx)));
        }
        const known = ["FIELD", "VALUE", "LINE", "OFFSET"];
        if (!b.ctx.lineSelection || !parts.size || [...parts.keys()].some((w) => !known.includes(w))) {
          this.refuse(s, REFUSED_LIST.GetCursor);
          return;
        }
        const head = "z2ui5_cl_cgui_gui=>get_cursor_field( ";
        const width = Math.max(...[...parts.keys()].map((w) => w.length));
        const lines = [...parts].map(([w, target], i) => `${i === 0 ? `${head}IMPORTING  ` : `${" ".repeat(head.length)}           `}${lc(w).padEnd(width)} = ${target}`);
        lines.push(`${" ".repeat(head.length)}EXCEPTIONS ${"not_on_field".padEnd(width)} = 4 ).`);
        out.push(...lines);
        this.map(s, "`z2ui5_cl_cgui_gui=>get_cursor_field( )` - the field, value, line and offset of the click of the line selection, sy-subrc 4 off a field");
        return;
      }
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
            // =>('CLIPBOARD_EXPORT') is =>clipboard_export(
            if (toks[at + 1].getStr() === "(") {
              ov.set(key(toks[at + 1]), `${frontendName(toks, at - 1)}(`);
              ov.set(key(toks[at + 2]), null);
              ov.set(key(toks[at + 3]), null);
            } else {
              ov.set(key(toks[at + 1]), `${lc(toks[at + 1].getStr())}(`);
            }
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

// the families of statements - one class, the methods by what they convert
Object.assign(Converter.prototype, dynproMethods, guiMethods, alvMethods, screenMethods, listMethods, callsMethods, functionsMethods, localsMethods, declMethods, rewritesMethods);

/** convert a classic report into an abap-cloud-gui report class */

export function convert(source, opts = {}) {
  return convertGuiClasses(convertReport(source, opts), opts);
}

/**
 * The classes of the report's repository the report hands a SAP GUI control
 * to (result.guiDeps): each is converted as a local class of a report of its
 * own would be - its cl_gui_* (and cl_salv_*) the stand-ins, SET HANDLER
 * set_handler( ) - and written beside the report's class under its own name,
 * so the report's calls of it stay as they are. A class whose methods would
 * need the report (WRITE, a FORM, a global of the report) is refused, and so
 * is what its controls use that the stand-ins do not have - at its line in
 * its file. The classes it hands a control to in turn are converted too.
 */
function convertGuiClasses(result, opts, seen = new Set()) {
  const todo = (result.guiDeps ?? []).filter((c) => !seen.has(c));
  for (const cls of todo) seen.add(cls);
  for (const cls of todo) {
    const fileName = `${cls.replace(/\//g, "#")}.clas.abap`;
    const dep = (opts.deps ?? []).find((d) => lc(d.name.split("/").pop()) === fileName);
    if (!dep) continue;
    const sub = convertGuiClass(cls, dep.text.replace(/^\uFEFF/, ""), opts, seen);
    const where = (r) => ({ ...r, row: 0, col: 0, file: fileName, message: `${fileName}${r.row ? `:${r.row}` : ""} - ${r.message}` });
    result.todos.push(...sub.todos.map(where));
    result.release.push(...(sub.release ?? []).filter((r) => !result.release.some((x) => x.kind === r.kind && x.name === r.name)));
    if (sub.refusals.length) {
      result.refusals.push(...sub.refusals.map(where));
      result.ok = false;
      result.files = {};
      continue;
    }
    for (const [name, text] of Object.entries(sub.files)) {
      if (result.ok) result.files[name] = text;
      result.draft[name] = text;
    }
  }
  return result;
}

/** one class of the repository, converted as a local class of a report of
 *  its own - its definition and implementation, its header as it was */
function convertGuiClass(cls, source, opts, seen) {
  const header = /^\s*CLASS\s+[\w/]+\s+DEFINITION\b[^.]*\./im.exec(source);
  if (!header) return { refusals: [{ row: 1, col: 1, message: "the class has no CLASS ... DEFINITION the converter can read" }], todos: [], files: {} };
  // the header a local class can have, on the same lines - the rows stay the class's
  const local = source.replace(header[0], header[0]
    .replace(/\bPUBLIC\b/i, "      ").replace(/\bCREATE\s+(PUBLIC|PROTECTED|PRIVATE)\b/i, (m) => " ".repeat(m.length))
    .replace(/\bSHARED\s+MEMORY\s+ENABLED\b/i, (m) => " ".repeat(m.length)));
  const PRE = "REPORT zr2c_gui_class.\n";
  const sub = convertReport(`${PRE}${local}\n\nSTART-OF-SELECTION.\n`, {
    ...opts, file: "zr2c_gui_class.prog.abap", className: "z2ui5_cl_cgui_r2c_gui_class", programName: "zr2c_gui_class",
    textpool: undefined, deps: (opts.deps ?? []).filter((d) => lc(d.name.split("/").pop()) !== `${cls.replace(/\//g, "#")}.clas.abap`),
  });
  const shift = (r) => ({ ...r, row: Math.max(0, (r.row ?? 0) - 1) });
  const nested = convertGuiClasses(sub, opts, seen);
  const out = { refusals: nested.refusals.map(shift), todos: nested.todos.map(shift), release: nested.release, files: {} };
  if (out.refusals.length) return out;
  const text = [nested.files["z2ui5_cl_cgui_r2c_gui_class.clas.locals_def.abap"], nested.files["z2ui5_cl_cgui_r2c_gui_class.clas.locals_imp.abap"]].filter(Boolean).join("\n");
  const esc = cls.replace(/\//g, "\\/");
  // not CLASS x DEFINITION DEFERRED / LOCAL FRIENDS - the class itself
  const def = new RegExp(`^CLASS ${esc} DEFINITION(?![^.]*\\b(?:DEFERRED|LOAD|LOCAL\\s+FRIENDS)\\b)[^.]*\\.[\\s\\S]*?^ENDCLASS\\.`, "im").exec(text);
  const imp = new RegExp(`^CLASS ${esc} IMPLEMENTATION\\.[\\s\\S]*?^ENDCLASS\\.`, "im").exec(text);
  if (!def || !imp) {
    out.refusals.push({ row: 1, col: 1, message: "the converted class could not be taken out of the conversion - port it by hand" });
    return out;
  }
  // the absolute name of a class of its own (a static handler): no longer
  // a local class of the report's class pool
  const body = `${def[0].replace(/^CLASS\s+[\w/]+\s+DEFINITION\b[^.]*\./i, header[0].trim())}\n\n${imp[0]}\n`
    .replace(/\\CLASS-POOL=Z2UI5_CL_CGUI_R2C_GUI_CLASS\\CLASS=/gi, "\\CLASS=");
  if (/\blcl_r2c\b|\bz2ui5_cl_cgui_r2c_gui_class\b/i.test(body)) {
    out.refusals.push({ row: 1, col: 1, message: "its methods use the report - WRITE, a FORM, a global of the report; in a class of its own they have no report to reach: port those methods by hand" });
    return out;
  }
  const helpers = text.replace(def[0], "").replace(imp[0], "")
    .replace(/^CLASS lcl_r2c DEFINITION[\s\S]*?^ENDCLASS\.\s*/im, "").replace(/^CLASS lcl_r2c IMPLEMENTATION\.[\s\S]*?^ENDCLASS\.\s*/im, "")
    // what only the report's class pool needs: the class deferred, the
    // report class's local friends
    .replace(/^CLASS\s+[\w/]+\s+DEFINITION\s+(?:DEFERRED|LOAD|LOCAL\s+FRIENDS\b[^.]*)\s*\.\s*$/gim, "")
    .replace(/^"[^\n]*\n/gm, "").trim();
  if (helpers && /^CLASS\s/im.test(helpers)) {
    out.refusals.push({ row: 1, col: 1, message: "the conversion needs local types beside the class - port it by hand" });
    return out;
  }
  out.files[`${cls.replace(/\//g, "#")}.clas.abap`] = normalizeAbap(body);
  out.files[`${cls.replace(/\//g, "#")}.clas.xml`] = classXml(cls, `${cls} - its SAP GUI controls on the stand-ins of abap-cloud-gui (report2cloud)`);
  return out;
}

function convertReport(source, opts = {}) {
  // salv: true - the stand-ins of the SALV at once (the tests), false - never
  if (opts.salv === true) {
    setSalvMode(true);
    try {
      return new Converter(source, opts).run();
    } finally {
      setSalvMode(false);
    }
  }
  const result = new Converter(source, opts).run();
  // a SALV object used after display( ) - in a local class, in its handlers:
  // the stand-ins of the SALV instead of alv( )
  // (refused), or a SALV left as it was (a local class is copied as it is)
  const salvLeft = (r) => r.refusals?.some((x) => /, an object of CL_SALV_TABLE, is used here/.test(x.message))
    || r.release?.some((x) => /^(cl|cx|if)_salv_/i.test(x.name ?? ""));
  if (opts.salv !== false && salvLeft(result)) {
    setSalvMode(true);
    try {
      const standin = new Converter(source, { ...opts, salv: true }).run();
      if ((standin.ok && !salvLeft(standin)) || standin.refusals.length < result.refusals.length) return standin;
    } finally {
      setSalvMode(false);
    }
  }
  return result;
}
