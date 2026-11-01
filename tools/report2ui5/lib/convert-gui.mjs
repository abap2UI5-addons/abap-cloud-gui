// The gui family of the converter - the SAP GUI controls (cl_gui_*) on the stand-ins, SET HANDLER, the grid in a container and the classes of the repository a control is handed to. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, children, findAll, key, kind, lc, literal, nodeText, renderTokens, stmtTokens, uc,
  unquote, words,
} from "./abap.mjs";
import {
  CLOSERS, GRID_VALUE_TYPES, GUI, GUI_CONTROL, ICONS, OPENERS, REFUSED, SALV, declName,
  functionParams, guiClass, guiEvent, guiMember, renderNamedCall, salvMode, salvRelations,
  withoutConstructorArgs,
} from "./convert-shared.mjs";

export const guiMethods = {

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
  },


  /** the SAP GUI controls of a report without a grid: name -> the stand-in
   *  class of z2ui5_cl_cgui_gui* (GUI) */
  findGuiVars(all) {
    this.guiVars = new Map();
    // the attributes and method data of the local classes as well
    for (const x of [...all, ...this.locals.flatMap((u) => u.stmts)]) {
      const t = lc(renderTokens(stmtTokens(x)));
      if (kind(x) === "Move") {
        const m = /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*new\s+(cl_gui_\w+|cl_salv_\w+)\s*\(/.exec(t);
        if (m && guiClass(m[2])) this.guiVars.set(m[1], guiClass(m[2]));
        // DATA(lo_events) = go_salv->get_event( ): the events of a SALV are the SALV itself
        const ev = /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*(?:me\s*->\s*)?([\w/]+)\s*->\s*get_event\s*\(\s*\)/.exec(t);
        if (ev && this.guiVars.has(ev[2])) this.guiVars.set(ev[1], this.guiVars.get(ev[2]));
        continue;
      }
      // a parameter of a method of a local class - a container handed in
      if (kind(x) === "MethodDef") {
        // not the RETURNING one: a control handed on through a call's result
        // is no handover the checks can follow
        for (const p of t.replace(/\breturning\b[\s\S]*$/, "").matchAll(/(?:!|\bvalue\s*\(\s*)?([\w/]+)\s*\)?\s+type\s+ref\s+to\s+(cl_gui_\w+|cl_salv_\w+)\b/g)) {
          // a container (or any control) to put the class's own controls in
          if (["z2ui5_cl_cgui_gui_container", "z2ui5_cl_cgui_gui"].includes(guiClass(p[2])) && !["type", "ref", "to"].includes(p[1])) this.guiVars.set(p[1], guiClass(p[2]));
        }
        continue;
      }
      if (!["Data", "Static", "ClassData"].includes(kind(x)) || this.insideBegin(x)) continue;
      const m = /type\s+ref\s+to\s+(cl_gui_\w+|cl_salv_\w+)\b/.exec(t);
      if (m && guiClass(m[1])) this.guiVars.set(lc(declName(x)), guiClass(m[1]));
    }
    // a control on the screen itself (cl_gui_container=>default_screen,
    // screen0 - also the container of cl_abap_browser): the list of the run
    // shows it, no dynpro is needed - "%screen" is no variable of the report
    if ([...all, ...this.locals.flatMap((u) => u.stmts)].some((x) => /\bcl_gui_container\s*=>\s*(default_screen|screen0)\b/.test(lc(renderTokens(stmtTokens(x)))))) {
      this.guiVars.set("%screen", "z2ui5_cl_cgui_gui_container");
    }
  },


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
        this.guiHandlerMap.get(name).push({ cls, event: lc(nodeText(child(eh, "EventName"))), of: lc(nodeText(child(eh, "ClassName"))),
          static: /^class-methods\b/i.test(renderTokens(stmtTokens(x))) });
      }
    }
    return this.guiHandlerMap;
  },


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
    // x->get_event( ) of a SALV is the table itself; lcl=>x an attribute of a class
    const control = lc(target.replace(/\s*->\s*get_event\(\s*\)$/i, "").replace(/^me\s*->\s*/i, "").replace(/^.*(->|=>)\s*/, ""));
    const cls = this.guiVars.get(control) ?? this.guiVars.get(lc(target));
    const lines = [];
    for (const m of children(s, "MethodSource")) {
      const text = render(m);
      const arrow = /^(.*?)\s*(->|=>)\s*([\w/]+)$/.exec(text);
      // a static method: the stand-in calls it by its class
      const staticOf = arrow?.[2] === "=>" ? lc(arrow[1]) : undefined;
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
      // SET HANDLER m of a static handler method: called through an object of its class
      const staticMe = !arrow && candidates[0].static ? candidates[0].cls : undefined;
      if (handler === "me" && !b.ctx.local && !staticOf && !staticMe) {
        this.refuse(s, `SAP GUI controls: SET HANDLER ${method} outside of a local class - the handler is an object; name it`);
        return;
      }
      lines.push(renderNamedCall(`${target}->set_handler`, [
        staticOf || staticMe ? this.staticHandler(staticOf ?? staticMe) : { name: "handler", value: handler },
        { name: "method", value: literal(uc(method)) },
        { name: "event", value: literal(uc(candidates[0].event)) },
        ...(activation ? [{ name: "activation", value: activation }] : []),
      ]));
    }
    b.out.push(...lines);
    this.map(s, `\`${target}->set_handler( )\` - the stand-in keeps the handler and calls it for the event of the browser`);
  },


  /** the handler parameter of SET HANDLER lcl=>m: an object of the local
   *  class when it can be created without parameters - a static method is
   *  called through an object too, and RTTI finds its class by the object;
   *  else the class by its absolute name (a system resolves it, the
   *  transpiled runtime does not) or by its name (a global class) */
  staticHandler(cls) {
    const def = this.locals.find((u) => u.kind === "ClassDefinition" && lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1])) === cls);
    if (!def) return { name: "class", value: literal(uc(cls)) };
    const head = lc(renderTokens(stmtTokens(def.stmts[0])));
    const ctor = def.stmts.find((x) => kind(x) === "MethodDef" && lc(nodeText(child(x, "MethodName") ?? x)) === "constructor");
    const mandatory = ctor && /\bimporting\b/i.test(renderTokens(stmtTokens(ctor))) && !/^[^.]*importing(?:\s+\S+\s+type\s+\S+\s+(?:optional|default\s+\S+))+\s*\.?$/i.test(renderTokens(stmtTokens(ctor)));
    if (!/\babstract\b|\bcreate\s+(private|protected)\b/.test(head) && !mandatory) return { name: "handler", value: `NEW ${cls}( )` };
    return { name: "class", value: literal(`\\CLASS-POOL=${uc(this.className)}\\CLASS=${uc(cls)}`) };
  },


  /** the SAP GUI control classes of a statement that have no stand-in -
   *  the refusal, undefined when every one has */
  guiRefusal(text) {
    const t = salvRelations(lc(text));
    // the SALV of the stand-in mode: a class of it the stand-ins do not have
    if (salvMode) {
      const salv = [...new Set([...t.matchAll(/\bcl_salv_\w+/g)].map((m) => m[0]))].filter((c) => !SALV.classes[c]);
      if (salv.length) return `SALV: ${salv.join(", ")} ${salv.length > 1 ? "have" : "has"} no counterpart - the stand-ins (z2ui5_cl_cgui_salv_*) have the table, its columns, settings, functions, selections and events`;
    }
    if (!GUI_CONTROL.test(t)) return undefined;
    const missing = [...new Set([...t.matchAll(/\bcl_gui_\w+/g)].map((m) => m[0]))]
      .filter((c) => !guiClass(c) && !["cl_gui_cfw", "cl_gui_frontend_services"].includes(c));
    if (this.guiVars?.size && !missing.length) return undefined;
    if (this.guiVars?.size) return `SAP GUI controls: ${missing.join(", ")} ${missing.length > 1 ? "have" : "has"} no counterpart - the containers, cl_gui_textedit, cl_gui_html_viewer, cl_gui_toolbar, cl_gui_picture, cl_gui_simple_tree, cl_gui_column_tree, cl_gui_list_tree and cl_gui_alv_grid have (z2ui5_cl_cgui_gui*)`;
    return "SAP GUI controls (cl_gui_*) need a dynpro container - use alv( ) or an abap2UI5 view";
  },


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
  },


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
  },


  /** the classes of the report's repository that use SAP GUI controls or
   *  the SALV - name -> source; the ones a control can be handed to */
  guiDepClasses() {
    this.guiDepMap ??= new Map(this.deps
      .filter((d) => /\.clas\.abap$/.test(d.name) && /\bcl_(gui|salv)_\w+/i.test(d.text))
      .map((d) => [lc(d.name.split("/").pop().replace(/\.clas\.abap$/, "").replace(/#/g, "/")), d.text]));
    return this.guiDepMap;
  },


  /** the variables of the report typed with a class: name -> class */
  refTypes() {
    if (this.refTypeMap) return this.refTypeMap;
    this.refTypeMap = new Map();
    for (const x of this.stmts) {
      const t = lc(renderTokens(stmtTokens(x)));
      const m = /^(?:data|class-data|statics)\s*:?\s*([\w/]+)\s+type\s+ref\s+to\s+([\w/]+)/.exec(t)
        ?? /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*new\s+([\w/]+)\s*\(/.exec(t);
      if (m) this.refTypeMap.set(m[1], m[2]);
    }
    return this.refTypeMap;
  },


  /** the classes of the repository with SAP GUI controls a statement calls -
   *  by name (zcl_x=>m( ), NEW zcl_x( )) or through a variable of theirs: a
   *  local class that inherits from one, an interface of the repository its
   *  classes with controls implement (each of them - which one comes is
   *  not to be told here) */
  guiReceivers(toks) {
    const classes = this.guiDepClasses();
    if (!classes.size) return [];
    const types = this.refTypes();
    const out = new Set();
    const of = (type) => {
      if (!type) return;
      if (classes.has(type)) {
        out.add(type);
        return;
      }
      const sup = this.localSuper(type);
      if (sup) of(sup);
      for (const [name, text] of classes) {
        if (new RegExp(`\\binterfaces\\s+${type.replace(/\//g, "\\/")}\\b`, "i").test(text)) out.add(name);
      }
    };
    for (const t of toks) of(classes.has(t) ? t : types.get(t));
    return [...out];
  },


  /** whether a statement calls a local class of the report - converted as
   *  it is, its controls the stand-ins: it takes the control */
  callsLocalClass(toks) {
    const locals = new Set(this.locals.filter((x) => x.kind === "ClassDefinition")
      .map((u) => lc(nodeText(child(u.stmts[0], "ClassName") ?? u.stmts[0].getChildren()[1]))));
    const types = this.refTypes();
    return toks.some((t, i) => (locals.has(t) && ["=>", "("].includes(toks[i + 1])) || (locals.has(types.get(t)) && toks[i + 1] === "->")
      || (t === "new" && locals.has(toks[i + 1])));
  },


  /** the superclass of a local class of the report */
  localSuper(name) {
    for (const u of this.locals.filter((x) => x.kind === "ClassDefinition")) {
      const m = /^class\s+([\w/]+)\s+definition\b.*?\binheriting\s+from\s+([\w/]+)/.exec(lc(renderTokens(stmtTokens(u.stmts[0]))));
      if (m && m[1] === name) return m[2];
    }
    return undefined;
  },


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
      // go_x = NEW #( ... ) - the class of the control assigned to
      if (t === "new" && toks[i + 1] === "#" && toks[1] === "=" && i === 2 && this.guiVars.has(toks[0])) ctors.push(this.guiVars.get(toks[0]));
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
    // cl_abap_browser=>show_html( container = ... ) - its stand-in takes the
    // container of the stand-ins
    if (!used.length && !toks.includes("cl_abap_browser") && /->|=>|\bnew\b|^create\s+object|^call\s+(function|method)/.test(toks.join(" "))) {
      // an argument of a call: inside its parentheses - not the source of an
      // assignment (me->x = io_x) or a comparison (IF me->x = io_x)
      // (or after the EXPORTING of CREATE OBJECT / CALL METHOD without them)
      let depth = 0;
      for (let i = 1; i < toks.length; i++) {
        if (toks[i - 1] === "(" || (toks[i - 1] === "exporting" && depth === 0)) depth++;
        if (toks[i - 1] === ")") depth--;
        if (depth > 0 && this.guiVars.has(toks[i]) && ["=", "("].includes(toks[i - 1]) && toks[i + 1] !== "->") {
          // a class of the repository that uses the SAP GUI itself: it is
          // converted too, its cl_gui_* the stand-ins, and takes the control
          const receivers = this.guiReceivers(toks);
          if (receivers.length) {
            for (const r of receivers) this.guiDeps.add(r);
            return undefined;
          }
          if (this.callsLocalClass(toks)) return undefined;
          return `${toks[i]}, a SAP GUI control, is handed to a method that is no stand-in - it takes a cl_gui_* object`;
        }
      }
    }
    if (!used.length) return undefined;
    // the parameters and exceptions named: of one of the methods called
    const known = new Set(["others", "error_message", ...used.flatMap((m) => [...m.params, ...m.exceptions])]);
    const flat = toks.join(" ");
    // a chain - x->get_functions( )->add_function( name = ... ): the method
    // whose parameters they are is one of the object returned, the syntax
    // check of the class sees it
    if (/\)\s*->/.test(flat)) return undefined;
    // the target of an assignment - an attribute of a class too (lcl=>x)
    const head = /^(?:data\s*\(\s*[\w/]+\s*\)|[\w/-]+(?:\s*(?:=>|->)\s*[\w/-]+)*)\s*=(?![=>])/.exec(flat);
    // the components of a VALUE #( ... ) or another constructor expression
    // are no parameters
    const body = withoutConstructorArgs(head ? flat.slice(head[0].length) : flat);
    for (const m of body.matchAll(/(?:^|[(\s])([a-z_][\w]*)\s*=(?![=>])/g)) {
      if (!known.has(m[1])) return `${m[1]} is no parameter of ${used.length > 1 ? "the methods called" : "the method called"} in the stand-in`;
    }
    return undefined;
  },


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
  },


  /** the grid, its container or its handler object - dropped */
  isGridObject(name) {
    return !!(this.gridVars?.has(name) || this.contVars?.has(name) || this.handlerVars?.has(name) || this.okDropped?.has(name));
  },


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
  },


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
  },


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
  },
};
