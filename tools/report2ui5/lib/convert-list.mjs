// The list family of the converter - WRITE, FORMAT, HIDE and the list read back. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, hasSeq, isToken, key, kind, lc, literal, nodeText, renderTokens, uc, words,
} from "./abap.mjs";
import { COLORS, colorConst, underName } from "./convert-shared.mjs";

/** the ON / OFF additions of FORMAT and WRITE, as the parameters of write( ) */
const FLAGS = ["hotspot", "intensified", "inverse", "input"];

/** WRITE ... DD/MM/YYYY etc. - the constants of z2ui5_cl_cgui_list=>cs_date_format */
const DATE_FORMATS = {
  "DD/MM/YY": "dd_mm_yy", "MM/DD/YY": "mm_dd_yy", "DD/MM/YYYY": "dd_mm_yyyy", "MM/DD/YYYY": "mm_dd_yyyy",
  DDMMYY: "ddmmyy", MMDDYY: "mmddyy", YYMMDD: "yymmdd",
};

export const listMethods = {

  /**
   * READ LINE n FIELD VALUE f1 [INTO g1] ... [LINE VALUE INTO wa] and
   * MODIFY LINE n FIELD VALUE f1 [FROM g1] ... -> read_list( )->read_field(
   * ) / modify_field( ) per field, by the name the WRITE gave it, EXCEPTIONS
   * no_line = 4 the sy-subrc of the classic. CURRENT LINE in AT
   * LINE-SELECTION is row. False when not converted (refused).
   */
  lineAccess(s, b) {
    const read = kind(s) === "ReadLine";
    const w = words(s);
    const ch = s.getChildren();
    const ov = this.rewrites(s, b.ctx, b);
    const tok = (c) => (isToken(c) ? uc(c.get().getStr()) : undefined);
    if (w.includes("INDEX") || w.includes("PAGE") || (!read && hasSeq(w, "LINE", "VALUE"))) return false;
    let line;
    if (w[1] === "CURRENT") {
      if (!b.ctx.lineSelection || b.ctx.form) return false;
      line = "row";
    } else {
      line = nodeText(ch.find((c) => !isToken(c)), ov);
    }
    // the fields: f [INTO g] (READ) or f [FROM g] (MODIFY) after FIELD VALUE
    const fields = [];
    let into;
    const at = ch.findIndex((c, i) => tok(c) === "VALUE" && tok(ch[i - 1]) === "FIELD");
    if (at >= 0) {
      for (let i = at + 1; i < ch.length; i++) {
        const t = tok(ch[i]);
        if (t === "INTO" || t === "FROM") {
          fields[fields.length - 1].target = nodeText(ch[++i], ov);
          continue;
        }
        // MODIFY ... FIELD FORMAT f INPUT OFF parses as sources
        if (t !== undefined || ["FIELD", "LINE"].includes(uc(nodeText(ch[i]).trim()))) break;
        fields.push({ name: underName(nodeText(ch[i])), target: nodeText(ch[i], ov) });
      }
    }
    const lv = ch.findIndex((c, i) => tok(c) === "VALUE" && tok(ch[i - 1]) === "LINE");
    if (read && lv >= 0) into = nodeText(ch[lv + 2], ov);
    if (!read && (hasSeq(w, "LINE", "FORMAT") || hasSeq(w, "FIELD", "FORMAT"))) {
      this.note("MODIFY LINE ... LINE FORMAT / FIELD FORMAT - dropped, the list keeps the format the WRITE gave");
    }
    const method = read ? "read_field" : "modify_field";
    const call = (f) => {
      const exp = [["line", line], ...(f ? [["name", literal(f.name)]] : []), ...(f && !read ? [["value", f.target]] : [])];
      const chg = f && read ? [["value", f.target]] : [];
      const width = Math.max(...[...exp, ...chg, ["no_line"]].map(([n]) => n.length));
      const head = `read_list( )->${method}( `;
      const kw = "EXCEPTIONS ";
      const rows = [];
      const block = (word, pairs) => pairs.forEach(([n, v], i) => rows.push(`${i ? " ".repeat(kw.length) : word.padEnd(kw.length)}${n.padEnd(width)} = ${v}`));
      block("EXPORTING", exp);
      block("CHANGING", chg);
      block("EXCEPTIONS", [["no_line", "4"]]);
      return rows.map((r, i) => `${i ? " ".repeat(head.length) : head}${r}`).join("\n") + " ).";
    };
    if (into) b.out.push(`${into} = read_list( )->line_text( ${line} ).`);
    if (fields.length) for (const f of fields) b.out.push(call(f));
    else b.out.push(call());
    this.map(s, `\`read_list( )->${method}( )\` - ${read ? "the fields" : "a field"} of line ${line} by the name its WRITE gave it, sy-subrc 4 without such a line`);
    return true;
  },


  // ----------------------------------------------------------------- list

  listCall(b, method, params) {
    const item = { method, params, positional: !params.some((p) => p.name) };
    b.out.push({ items: [item] });
    if (method !== "write") b.line = [];
  },


  /**
   * FORMAT: the color, hotspot, intensified, inverse and input the
   * following write( ) calls of the method pass. In a FORM (or a method of a
   * local class) what its FORMAT set is passed even when it is off - the
   * caller may have set it for the FORM (formatCall( )).
   */
  format(s, b) {
    const w = words(s);
    const color = child(s, "Color");
    const set = (name, value) => {
      b.fmt[name] = value;
      if (b.ctx.form || b.ctx.local) b.fmtSet.add(name);
    };
    if (w.includes("RESET")) {
      b.color = "none";
      if (b.ctx.form || b.ctx.local) b.fmtSet.add("color");
      for (const f of FLAGS) set(f, undefined);
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
      if (b.ctx.form || b.ctx.local) b.fmtSet.add("color");
      if (b.runtimeColor) b.out.push(b.color === "none" ? `CLEAR ${b.colorVar}.` : `${b.colorVar} = ${colorConst(b.color)}.`);
    }
    for (const f of FLAGS) {
      const v = this.flagValue(s, uc(f), b);
      if (v !== null) set(f, v);
    }
    b.lastFormat = s;
    if (w.includes("FRAMES")) this.note("FORMAT FRAMES - dropped, the list draws no frames");
    this.map(s, b.runtimeColor ? "`lv_color`, passed to every `write( )` of the method" : "applied to the following `write( )` calls of the method (color, hotspot, intensified, inverse, input)");
  },


  /**
   * The value of an ON / OFF addition of FORMAT or WRITE (HOTSPOT,
   * INTENSIFIED, ...): "abap_true", undefined for OFF, an expression for
   * `= f`, null when the statement does not have it.
   */
  flagValue(s, word, b) {
    const ch = s.getChildren();
    const at = ch.findIndex((c) => isToken(c) && uc(c.get().getStr()) === word);
    if (at < 0) return null;
    const next = ch[at + 1];
    if (next && isToken(next) && uc(next.get().getStr()) === "OFF") return undefined;
    if (next && isToken(next) && next.get().getStr() === "=" && ch[at + 2]) {
      const v = nodeText(ch[at + 2], this.rewrites(s, b.ctx, b));
      if (/^abap_true$|^'X'$/i.test(v)) return "abap_true";
      if (/^abap_false$|^' '$|^space$|^0$/i.test(v)) return undefined;
      return `xsdbool( ${v} IS NOT INITIAL )`;
    }
    return "abap_true";
  },


  /** the FORM writes to the list - itself or through the FORMs it performs */
  formWrites(name, seen = new Set()) {
    if (seen.has(name)) return false;
    seen.add(name);
    const f = this.formByName.get(name);
    if (!f) return false;
    return f.body.some((x) => ["Write", "Uline", "Skip", "NewLine", "NewPage", "Hide"].includes(kind(x))
      || (kind(x) === "Perform" && child(x, "FormName") && this.formWrites(lc(nodeText(child(x, "FormName"))), seen)));
  },


  /**
   * PERFORM after a FORMAT: the classic FORMAT lasts until the end of the
   * event block, across the FORMs it calls. The format of the caller is set
   * on the list for the call (the write( ) calls of the FORM pass what they
   * do not set themselves) and reset after it - the caller passes its own.
   */
  formatCall(b, name, call) {
    const params = [];
    if (b.runtimeColor) params.push({ name: "color", value: b.colorVar });
    else if (b.color !== "none") params.push({ name: "color", value: colorConst(b.color) });
    for (const f of FLAGS) if (b.fmt[f] !== undefined) params.push({ name: f, value: b.fmt[f] });
    if (!params.length || !this.formWrites(name)) {
      b.out.push(call);
      return;
    }
    b.out.push({ items: [{ method: "format", params }] });
    b.out.push(call);
    b.out.push({ items: [{ method: "format", params: [{ name: "reset", value: "abap_true" }] }] });
  },


  /**
   * The end of a FORM or a method of a local class: a FORMAT still in effect
   * there is the caller's in the classic, which the class cannot give it.
   */
  formatLeft(b) {
    if (!(b.ctx.form || b.ctx.local) || !b.lastFormat) return;
    const on = b.color !== "none" || FLAGS.some((f) => b.fmt[f] !== undefined);
    if (!on) return;
    this.todo(b.lastFormat, `FORMAT is still in effect at the end of ${b.ctx.form ? `FORM ${b.ctx.form.name}` : "the method"} - in the classic it is in effect for the WRITEs of the caller after the call too; the class applies it to the write( ) calls of ${b.ctx.form ? "the FORM" : "the method"} only, set it in the caller (FORMAT there, or COLOR / INTENSIFIED / ... at its WRITEs)`);
  },


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
        // read back by READ LINE: the user ticks it, as WRITE AS CHECKBOX
        // without INPUT OFF lets him
        const name = underName(nodeText(src));
        items.push({ method: "write_as_checkbox", params: this.lineFields.has(name)
          ? [{ name: "val", value }, ...(hasSeq(w, "INPUT", "OFF") ? [] : [{ name: "input", value: "abap_true" }]), { name: "name", value: literal(name) }]
          : [{ value }] });
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
      // HOTSPOT, INTENSIFIED, INVERSE, INPUT: the WRITE's own, else FORMAT's
      const flags = {};
      for (const f of FLAGS) {
        const v = this.flagValue(s, uc(f), b);
        flags[f] = v === null ? b.fmt[f] : v;
      }
      const hotspot = flags.hotspot !== undefined;
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
      if (this.underTargets?.has(underName(nodeText(src))) || this.lineFields.has(underName(nodeText(src)))
          || (this.cursorField && /^[a-z_][\w-]*$/i.test(nodeText(src).trim()))) {
        item.params.push({ name: "name", value: literal(underName(nodeText(src))) });
      }
      if (color || !b.runtimeColor) {
        if (c !== "none" || (!color && b.fmtSet.has("color"))) item.params.push({ name: "color", value: colorConst(c) });
      } else {
        item.params.push({ name: "color", value: b.colorVar });
      }
      for (const f of FLAGS) {
        if (flags[f] !== undefined) item.params.push({ name: f, value: flags[f] });
        else if (b.fmtSet.has(f) || this.flagValue(s, uc(f), b) !== null) item.params.push({ name: f, value: "abap_false" });
      }
      item.params.push(...this.writeOptions(s, ov));
      items.push(item);
      b.line.push(item);
      this.map(s, `\`write( )\`${c !== "none" ? ", color" : ""}${hotspot ? ", hotspot" : ""}`);
    }
    if (items.length) b.out.push({ items });
  },


  /**
   * The format additions of WRITE as the parameters of write( ):
   * CURRENCY, UNIT, DECIMALS, ROUND, NO-ZERO, NO-SIGN, NO-GROUPING,
   * LEFT-JUSTIFIED / CENTERED / RIGHT-JUSTIFIED, USING EDIT MASK, the date
   * formats DD/MM/YYYY ..., TIME ZONE, QUICKINFO. EXPONENT and ENVIRONMENT
   * TIME FORMAT have no counterpart.
   */
  writeOptions(s, ov) {
    const params = [];
    const ch = s.getChildren();
    const word = (c) => (c && isToken(c) ? uc(c.get().getStr()) : undefined);
    const start = ch.indexOf(child(s, "Source"));
    for (let i = start + 1; i < ch.length; i++) {
      const w = word(ch[i]);
      if (!w) continue;
      const arg = (name) => {
        if (ch[i + 1] && !isToken(ch[i + 1])) params.push({ name, value: nodeText(ch[++i], ov) });
      };
      if (["CURRENCY", "UNIT", "DECIMALS", "ROUND", "QUICKINFO"].includes(w)) arg(lc(w));
      else if (w === "EDIT" && word(ch[i + 1]) === "MASK" && word(ch[i - 1]) !== "NO") {
        i++;
        arg("edit_mask");
      } else if (w === "TIME" && word(ch[i + 1]) === "ZONE") {
        i++;
        arg("time_zone");
      } else if (w === "NO" && word(ch[i + 1]) === "-" && ["ZERO", "SIGN", "GROUPING"].includes(word(ch[i + 2]))) {
        params.push({ name: `no_${lc(word(ch[i + 2]))}`, value: "abap_true" });
        i += 2;
      } else if (["LEFT", "RIGHT"].includes(w) && word(ch[i + 1]) === "-" && word(ch[i + 2]) === "JUSTIFIED") {
        params.push({ name: "justify", value: `z2ui5_cl_cgui_list=>cs_justify-${lc(w)}` });
        i += 2;
      } else if (w === "CENTERED") {
        params.push({ name: "justify", value: "z2ui5_cl_cgui_list=>cs_justify-center" });
      } else if (DATE_FORMATS[w]) {
        params.push({ name: "date_format", value: `z2ui5_cl_cgui_list=>cs_date_format-${DATE_FORMATS[w]}` });
      } else if (w === "EXPONENT" || w === "ENVIRONMENT") {
        this.note(`WRITE ... ${w} - the list writes the value in its default format`);
      }
    }
    return params;
  },


  /**
   * HIDE f -> list( )->hide( f ) at the statement: the value travels with
   * the current line as it is when HIDE runs (not when the line was
   * written), and the whole line becomes a hotspot. HIDE: a, b. and HIDEs
   * one after the other are one call, the fields joined with a tab.
   */
  hide(s, b) {
    const src = child(s, "Source");
    const name = lc(nodeText(src));
    const root = name.split("-")[0];
    if (!this.globalData.has(root) || this.currentLocals?.has(root) || b.ctx.local?.declared?.has(root)) {
      this.refuse(s, `HIDE ${name} - the field is not a global field of the report, so at_line_selection( ) cannot restore it`);
      return;
    }
    // the field as this method reads it (a header line is its work area, a
    // method of a local class reads it through the instance) and as
    // at_line_selection( ) of the class restores it
    const value = nodeText(src, this.rewrites(s, b.ctx, b));
    const header = this.globalHeader.get(root);
    const restore = header ? header.wa + name.slice(root.length) : name;
    let at = b.out.length - 1;
    while (at >= 0 && b.out[at] === "") at--;
    const prev = at >= 0 && typeof b.out[at] === "object" && b.out[at].hide && b.out[at].line === b.line ? b.out[at] : undefined;
    if (!prev && b.line.hidden) {
      this.refuse(s, `HIDE ${name} apart from the HIDE before it on the same line - write the HIDE statements of a line one after the other`);
      return;
    }
    const fields = [...(prev?.hide ?? []), restore];
    const prefix = (a, c) => a.every((f, i) => c[i] === f);
    if (this.hideSet && !prefix(fields, this.hideSet) && !prefix(this.hideSet, fields)) {
      this.refuse(s, `HIDE of other fields (${fields.join(", ")}) than elsewhere (${this.hideSet.join(", ")}) - one set of hidden fields per report is supported`);
      return;
    }
    if (!this.hideSet || fields.length > this.hideSet.length) this.hideSet = fields;
    const call = prev ?? { items: [{ method: "hide", params: [], positional: true }], hide: [], values: [], line: b.line };
    call.hide = fields;
    call.values.push(value);
    // the value of the line: the field, or all fields joined
    call.items[0].params = [{ value: call.values.length === 1 ? value : `|${call.values.map((f) => `{ ${f} }`).join("\\t")}|` }];
    if (!prev) {
      b.out.push(call);
      b.line.hidden = true;
    }
    this.map(s, "`list( )->hide( )` - the value of the current line, its texts hotspots; restored in `at_line_selection( )`");
  },


  hideRestore() {
    if (!this.hideSet) return [];
    const fields = this.hideSet;
    // a structure is written component by component - hide_restore( ) types
    // the text back into the field, whatever its type
    if (fields.length === 1) {
      return ["\" HIDE - the field the clicked line was written with",
        `z2ui5_cl_cgui_list=>hide_restore( EXPORTING hide = hide`,
        `                                  CHANGING  val  = ${fields[0]} ).`];
    }
    const lines = ["\" HIDE - the fields the clicked line was written with", "SPLIT hide AT |\\t| INTO TABLE DATA(lt_hide)."];
    fields.forEach((f, i) => lines.push(`${f} = VALUE #( lt_hide[ ${i + 1} ] OPTIONAL ).`));
    return lines;
  },
};
