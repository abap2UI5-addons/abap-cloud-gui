// The screen family of the converter - the selection screen: PARAMETERS, SELECT-OPTIONS, blocks, lines, buttons, the texts of the pool. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, hasSeq, isToken, key, kind, lc, literal, nodeText, renderTokens, stmtTokens, uc,
  words,
} from "./abap.mjs";
import { ICONS, declName, shortText } from "./convert-shared.mjs";

export const screenMethods = {

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
  },


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
  },


  screenField(name) {
    return this.screenFields?.has(lc(name));
  },


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
  },


  userCommand(s) {
    const ch = s.getChildren();
    for (let i = 0; i < ch.length - 3; i++) {
      if (isToken(ch[i]) && uc(ch[i].get().getStr()) === "USER" && uc(ch[i + 2].getFirstToken().getStr()) === "COMMAND") {
        return uc(ch[i + 3].getFirstToken().getStr());
      }
    }
    return undefined;
  },


  /** the text of a field of the selection screen - the label set at runtime
   *  while it is set (resolveScreenLabels) */
  labelText(name, text) {
    const v = this.screenLabels?.get(lc(name));
    if (!v) return text;
    return text ? `COND string( WHEN ${v} IS NOT INITIAL THEN ${v} ELSE ${text} )` : v;
  },


  selectionText(name, s, missing) {
    const t = this.pool.selection.get(uc(name));
    if (t) return literal(t);
    if (t === null) return undefined;     // from the DDIC
    missing.push(uc(name));
    return undefined;
  },


  textSymbol(keyText, fallback, at) {
    const t = this.pool.symbols.get(uc(keyText));
    if (t !== undefined) return literal(t);
    if (fallback !== undefined) return literal(fallback);
    this.todo(at, `text symbol TEXT-${uc(keyText)} is not in the text pool - the generated literal \`TEXT-${uc(keyText)}\` needs the real text`);
    return literal(`TEXT-${uc(keyText)}`);
  },


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
  },


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
  },
};
