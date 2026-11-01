// The dynpro family of the converter - the dynpros of the .prog.xml: their fields as a screen of the runtime, the modules as methods, the table controls. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, kind, lc, literal, renderTokens, stmtTokens, uc,
} from "./abap.mjs";
import {
  DYNPRO_FIELDS, GUI, ICONS, REFUSED, caseBody, parseFlow, radioGroup, tcColumns,
} from "./convert-shared.mjs";

export const dynproMethods = {

  /**
   * A dynpro of fields - the screens abapGit wrote into the .prog.xml. The
   * modules become private methods, the flow logic the hooks of the
   * runtime: dynpro_screen( ) builds the fields with the selection-screen
   * builder, dynpro_pbo( ) and dynpro_pai( ) call the modules of PROCESS
   * BEFORE OUTPUT and AFTER INPUT, and what followed CALL SCREEN goes on
   * in after_call_screen( ). A tabstrip is a tabbed block of the
   * builder, a subscreen area subscreen( ), CALL SUBSCREEN in the flow
   * logic call_subscreen( ) / call_subscreen_pai( ), a table control
   * table_control( ) with LOOP WITH CONTROL a line at a time
   * (tableLoop( )). A custom control without the stand-ins, another LOOP
   * of the flow logic or a subscreen of another program is refused.
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
    // a CALL SUBSCREEN reaches its subscreen - with a variable, each one of
    // the report (type I)
    for (const d of dynpros.values()) {
      const flow = parseFlow(d.flow);
      for (const c of flow.pbo.filter((x) => x.subscreen)) {
        const lit = /^'?(\d+)'?$/.exec(c.dynnr ?? "");
        if (lit) reached.add(lit[1].padStart(4, "0"));
        else for (const x of dynpros.values()) if (x.type === "I") reached.add(x.screen);
      }
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
      // a custom control area holds the stand-ins of the SAP GUI controls,
      // a tabstrip its tabs, a subscreen area what CALL SUBSCREEN calls
      const allowed = ["SCREEN", "RADIOGROUP", "STRIP_CTRL", "SUBSCREEN", "TABLE_CTRL", ...(this.guiVars?.size ? ["CUST_CTRL"] : [])];
      for (const c of d.containers.filter((x) => !allowed.includes(x.type))) problems.push(`screen ${nr} has a ${kinds[c.type] ?? c.type} ${c.name}`);
      for (const f of d.fields.filter((x) => !DYNPRO_FIELDS.has(x.type))) problems.push(`screen ${nr} has a field ${f.name || f.text} of type ${f.type}`);
      const flow = parseFlow(d.flow);
      problems.push(...flow.problems.map((p) => `screen ${nr}: ${p}`));
      for (const c of [...flow.pbo, ...flow.pai].filter((x) => x.tableloop)) {
        if (!d.containers.some((x) => x.type === "TABLE_CTRL" && x.name === c.tableloop)) problems.push(`screen ${nr} loops WITH CONTROL ${c.tableloop}, which is no table control of it`);
      }
      for (const t of d.containers.filter((x) => x.type === "TABLE_CTRL")) {
        const cols = tcColumns(d, t.name);
        if (!cols.length) problems.push(`screen ${nr} has a table control ${t.name} without columns`);
        if (cols.length > 16) problems.push(`screen ${nr} has a table control ${t.name} of ${cols.length} columns - 16 are shown`);
        for (const f of d.fields.filter((x) => x.cont === "TABLE_CTRL" && x.contName === t.name && !["TEXT", "TEMPLATE"].includes(x.type))) {
          problems.push(`screen ${nr} has a field ${f.name || f.text} of type ${f.type} in the table control ${t.name}`);
        }
      }
      for (const c of [...flow.pbo, ...flow.pai, ...flow.pov].flatMap((x) => (x.tableloop ? x.modules : [x])).filter((x) => x.module)) {
        if (!this.modules.some((m) => m.name === c.module)) problems.push(`screen ${nr} calls MODULE ${c.module}, which is not in the report`);
      }
      for (const c of [...flow.pbo, ...flow.pai].filter((x) => x.subscreen)) {
        if (!d.containers.some((x) => x.type === "SUBSCREEN" && x.name === c.subscreen)) problems.push(`screen ${nr} calls SUBSCREEN ${c.subscreen}, which is no subscreen area of it`);
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
  },


  /** a checkbox or radio button of a dynpro declared as one character -
   *  abap_bool, the type the frontend shows as a flag (and the type of
   *  checkbox( ) and radiobutton( ), which take it by reference) */
  dynproFlag(s, name, text) {
    if (kind(s) !== "Data" || this.insideBegin(s) || !this.isDynproFlag(name)) return text;
    const typed = text.replace(/\bVALUE\s+'X'/i, "VALUE abap_true").replace(new RegExp(`^(DATA\\s+${name})(?:\\(1\\))?\\s*(?:TYPE\\s+(?:c(?:\\s+LENGTH\\s+1)?|char1|flag|xfeld|boolean|boole_d|abap_boolean))?(?=\\s*(?:VALUE\\b|\\.))`, "i"), "$1 TYPE abap_bool");
    if (typed !== text) this.map(s, "`TYPE abap_bool` - a checkbox or radio button of the dynpro");
    return typed;
  },


  /** a checkbox or radio button of a dynpro, a variable of its own */
  isDynproFlag(name) {
    if (!this.dynpro) return false;
    this.dynproFlags ??= new Set(this.dynpro.screens.flatMap((d) => d.fields)
      .filter((f) => ["CHECK", "RADIO"].includes(f.type) && !f.name.includes("-")).map((f) => lc(f.name)));
    return this.dynproFlags.has(name);
  },


  /** the roots of the dynpro fields - gs_data of GS_DATA-CARRID */
  dynproFieldRoots() {
    return new Set((this.dynpro?.screens ?? []).flatMap((d) => d.fields).filter((f) => f.name && f.type !== "OKCODE")
      .map((f) => lc(f.name.split("-")[0])));
  },


  /** dynpro_screen( ), dynpro_pbo( ), dynpro_pai( ) - the screens and their flow logic */
  dynproMethods() {
    const { screens } = this.dynpro;
    // PBO calls the OUTPUT module of the name, PAI the INPUT one
    const call = (c, io, d) => {
      if (c.tableloop) return this.tableLoop(c, io, d, call);
      if (c.subscreen) {
        const nr = /^'?(\d+)'?$/.exec(c.dynnr ?? "");
        return io === "OUTPUT"
          ? `call_subscreen( area = ${literal(c.subscreen)} dynnr = ${nr ? literal(nr[1].padStart(4, "0")) : lc(c.dynnr)} ).`
          : `call_subscreen_pai( area = ${literal(c.subscreen)} ucomm = ucomm ).`;
      }
      const f = this.forms.find((x) => x.module?.name === c.module && x.module.io === io)
        ?? this.forms.find((x) => x.module?.name === c.module);
      return this.screenForms().has(f.name) ? `${f.method}( current_screen( ) ).` : `${f.method}( ).`;
    };
    const methods = [];
    methods.push({ name: "dynpro_screen", body: caseBody("dynnr", screens.map((d) => ({ field: d.screen, body: this.dynproLayout(d) }))) });
    const pbo = screens.filter((d) => d.pbo.length);
    if (pbo.length) methods.push({ name: "dynpro_pbo", body: caseBody("dynnr", pbo.map((d) => ({ field: d.screen, body: d.pbo.map((c) => call(c, "OUTPUT", d)) }))) });
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
            for (const c of exits) body.push(`  ${call(c, "INPUT", d)}`, ...leftCheck.map((l) => `  ${l}`));
            body.push("ENDIF.");
          }
          const rest = d.pai.filter((c) => c.cond !== "exit");
          rest.forEach((c, i) => {
            const line = call(c, "INPUT", d);
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
  },


  /** LOOP WITH CONTROL of a flow logic - the lines of the table control
   *  one at a time, as the classic loops: in the PBO the modules of the
   *  loop and then the values of the line for the browser, in the PAI the
   *  values the user left into the fields of the line and then the
   *  modules. LOOP AT itab INTO wa reads the line into wa first. */
  tableLoop(c, io, d, call) {
    const tc = lc(c.tableloop);
    const name = literal(c.tableloop);
    const cols = tcColumns(d, c.tableloop);
    const modules = c.modules.map((m) => {
      const line = call(m, io, d);
      return m.cond === "input" ? [`IF ${lc(m.field)} IS NOT INITIAL.`, `  ${line}`, "ENDIF."] : [line];
    }).flat();
    const out = [];
    if (io === "OUTPUT") {
      out.push(`" LOOP${c.itab ? ` AT ${c.itab} INTO ${c.wa}` : ""} WITH CONTROL ${tc} - a line of the table control at a time`, `tablecontrol_begin( ${name} ).`);
      const row = [`tablecontrol_row( name   = ${name}`, `                  values = VALUE #( ${cols.map((x) => `( |{ ${x.field} }| )`).join(" ")} ) ).`];
      if (c.itab) out.push(`LOOP AT ${c.itab} INTO ${c.wa}.`, `  ${tc}-current_line = sy-tabix.`);
      else out.push(`DO ${tc}-lines TIMES.`, `  ${tc}-current_line = sy-index.`);
      out.push(...modules.map((l) => `  ${l}`), ...row.map((l) => `  ${l}`), c.itab ? "ENDLOOP." : "ENDDO.");
      return out.join("\n");
    }
    out.push(`" LOOP${c.itab ? ` AT ${c.itab} INTO ${c.wa}` : ""} WITH CONTROL ${tc} - the lines the table control showed, as the user left them`,
      `DO tablecontrol_count( ${name} ) TIMES.`, `  ${tc}-current_line = sy-index.`);
    if (c.itab) out.push(`  READ TABLE ${c.itab} INTO ${c.wa} INDEX sy-index.`);
    // every field of the line goes back, as the classic transports output
    // fields too
    cols.forEach((x, i) => out.push(`  ${x.field} = tablecontrol_cell( name = ${name} row = sy-index col = ${i + 1} ).`));
    out.push(...modules.map((l) => `  ${l}`), "ENDDO.");
    return out.join("\n");
  },


  /** the fields of a screen as a chain of the selection-screen builder:
   *  line by line, a text before an input its label, frames blocks */
  dynproLayout(d) {
    const text = (t) => t.replace(/_/g, " ").trim();
    // a custom control area is a line of its own, where its first line is;
    // so are a tabstrip and a subscreen area of the screen itself
    const areas = d.containers.filter((c) => ["CUST_CTRL", "STRIP_CTRL", "TABLE_CTRL"].includes(c.type) || (c.type === "SUBSCREEN" && c.parent === "SCREEN"))
      .map((c) => ({ type: { CUST_CTRL: "CUSTOM", STRIP_CTRL: "STRIP", SUBSCREEN: "AREA", TABLE_CTRL: "TABLE" }[c.type], name: c.name, line: c.line, column: c.column, height: c.height, length: c.length }));
    const fields = [...d.fields.filter((f) => f.type !== "OKCODE" && f.line > 0 && f.cont !== "STRIP_CTRL" && f.cont !== "TABLE_CTRL"), ...areas].sort((a, b) => a.line - b.line || a.column - b.column);
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
      const own = ["CUSTOM", "STRIP", "AREA", "TABLE"];
      const calls = items.filter((f) => !own.includes(f.type)).map((f) => this.dynproField(f, fr)).filter(Boolean);
      if (calls.length > 1) add("line_begin(");
      calls.forEach((c) => add(c));
      if (calls.length > 1) add("line_end(");
      for (const f of items.filter((x) => own.includes(x.type))) {
        if (f.type === "CUSTOM") add(`custom_control( ${literal(f.name)}`);
        if (f.type === "AREA") add(`subscreen( ${literal(f.name)}`);
        if (f.type === "TABLE") {
          // the columns in their order: the heading of the column, ready
          // for input, the visible length
          const cols = tcColumns(d, f.name).map((c) => `( ${[`text = ${literal(c.text)}`, ...(c.input ? ["input = abap_true"] : []), ...(c.width ? [`width = ${c.width}`] : [])].join(" ")} )`);
          const title = d.fields.find((x) => x.cont === "TABLE_CTRL" && x.contName === f.name && x.type === "TEXT" && x.title);
          add([`table_control( name    = ${literal(f.name)}`, ...(title ? [`               title   = ${literal(text(title.text))}`] : []),
            `               columns = VALUE #( ${cols.join("\n                                  ")} )`].join("\n"));
        }
        if (f.type !== "STRIP") continue;
        // the tabs in their order, each with its function code and area,
        // then the areas of the tabstrip
        add(`tabbed_block_begin( ${literal(f.name)}`);
        const tabs = d.fields.filter((t) => t.cont === "STRIP_CTRL" && t.contName === f.name && t.type === "PUSH").sort((a, b) => a.line - b.line || a.column - b.column);
        for (const t of tabs) {
          add([`tab( text  = ${literal(text(t.text) || t.fcode || t.name)}`, `     fcode = ${literal(t.fcode || t.name)}`, ...(t.ref ? [`     area  = ${literal(t.ref)}`] : [])].join("\n"));
        }
        for (const a of d.containers.filter((c) => c.type === "SUBSCREEN" && c.parent === f.name)) add(`subscreen( ${literal(a.name)}`);
        add("tabbed_block_end(");
      }
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
  },


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
  },


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
  },
};
