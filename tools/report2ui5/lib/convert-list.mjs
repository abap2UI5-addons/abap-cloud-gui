// The list family of the converter - WRITE, FORMAT, HIDE and the list read back. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, hasSeq, isToken, key, kind, lc, literal, nodeText, renderTokens, uc, words,
} from "./abap.mjs";
import { COLORS, colorConst, underName } from "./convert-shared.mjs";

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


  format(s, b) {
    const w = words(s);
    const color = child(s, "Color");
    if (w.includes("RESET")) {
      b.color = "none";
      b.hotspot = false;
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
      if (b.runtimeColor) b.out.push(b.color === "none" ? `CLEAR ${b.colorVar}.` : `${b.colorVar} = ${colorConst(b.color)}.`);
    }
    const hs = w.indexOf("HOTSPOT");
    if (hs >= 0) b.hotspot = w[hs + 1] !== "OFF";
    if (w.includes("INTENSIFIED") || w.includes("INVERSE") || w.includes("INPUT") || w.includes("FRAMES")) {
      this.note("FORMAT INTENSIFIED / INVERSE / INPUT - the list knows only the color and hotspots");
    }
    this.map(s, b.runtimeColor ? "`lv_color`, passed to every `write( )` of the method" : "applied to the following `write( )` calls of the method (color, hotspot)");
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
      let hotspot = b.hotspot;
      const hs = w.indexOf("HOTSPOT");
      if (hs >= 0) hotspot = w[hs + 1] !== "OFF";
      const lost = ["CURRENCY", "UNIT", "DECIMALS", "EDIT", "LEFT-JUSTIFIED", "CENTERED",
        "RIGHT-JUSTIFIED", "NO-ZERO", "NO-SIGN", "EXPONENT", "ROUND", "DD/MM/YY", "MM/DD/YY", "DD/MM/YYYY",
        "MM/DD/YYYY", "DDMMYY", "MMDDYY", "YYMMDD", "QUICKINFO", "INPUT", "INVERSE", "TIME", "ENVIRONMENT"];
      const joined = w.join(" ").replace(/ - /g, "-");
      for (const o of lost) {
        if (new RegExp(`(^| )${o.replace(/\//g, "\\/")}( |$)`).test(joined)) this.note(`WRITE ... ${o} - the list writes the value in its default format`);
      }
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
        if (c !== "none") item.params.push({ name: "color", value: colorConst(c) });
      } else {
        item.params.push({ name: "color", value: b.colorVar });
      }
      if (hotspot) item.params.push({ name: "hotspot", value: "abap_true" });
      items.push(item);
      b.line.push(item);
      this.map(s, `\`write( )\`${c !== "none" ? ", color" : ""}${hotspot ? ", hotspot" : ""}`);
    }
    if (items.length) b.out.push({ items });
  },


  hide(s, b) {
    const src = child(s, "Source");
    const name = lc(nodeText(src));
    const root = name.split("-")[0];
    if (!this.globalData.has(root)) {
      this.refuse(s, `HIDE ${name} - the field is not a global field of the report, so at_line_selection( ) cannot restore it`);
      return;
    }
    let target = b.line.find((it) => it.params.some((p) => p.name === "hotspot")) ?? b.line[0];
    if (!target) {
      this.refuse(s, "HIDE without a WRITE before it in the same block - the hidden value is attached to the hotspot of the line it follows");
      return;
    }
    if (!target.params.some((p) => p.name === "hotspot")) target.params.push({ name: "hotspot", value: "abap_true" });
    target.hide = [...(target.hide ?? []), name];
    const set = target.hide.join(",");
    if (this.hideSet && !this.hideSet.startsWith(set) && !set.startsWith(this.hideSet)) {
      this.refuse(s, `HIDE of other fields (${target.hide.join(", ")}) than elsewhere (${this.hideSet}) - one set of hidden fields per report is supported`);
      return;
    }
    if (!this.hideSet || set.length > this.hideSet.length) this.hideSet = set;
    // the value of the hotspot: the field, or all fields of the line joined
    const hide = target.hide.length === 1 ? target.hide[0] : `|${target.hide.map((f) => `{ ${f} }`).join("\\t")}|`;
    target.params = target.params.filter((p) => p.name !== "hide");
    target.params.push({ name: "hide", value: hide });
    this.map(s, `\`hide = ${target.hide.join(" ")}\` at the hotspot of the line, restored in \`at_line_selection( )\``);
  },


  hideRestore() {
    if (!this.hideSet) return [];
    const fields = this.hideSet.split(",");
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
