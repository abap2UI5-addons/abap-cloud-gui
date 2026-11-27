// The alv family of the converter - CL_SALV_TABLE, ALV function modules and the field catalog as alv( ) of the runtime. Methods of Converter
// (convert.mjs), mixed into its prototype there: `this` is the
// Converter, and what they share with the other families is in
// convert-shared.mjs.
import {
  after, child, children, key, kind, lc, literal, nodeText, renderTokens, stmtTokens, uc, unquote,
} from "./abap.mjs";
import {
  OPENERS, SALV, declName, fcatColumn, functionParams, renderChain, salvChain, salvMode, shortText,
  valueRows,
} from "./convert-shared.mjs";

export const alvMethods = {

  /** CL_SALV_TABLE and REUSE_ALV_*: what each statement becomes - looked at
   *  over the whole report first, because the settings of a grid are often
   *  made in another FORM than the one that displays it */
  analyzeAlv() {
    this.alvPlan = new Map();     // statement -> { action: "drop" | "alv" | "skip", ... }
    this.salv = new Map();        // salv variable -> { table, settings, lineSelection }
    const cols = new Map();       // columns variable -> salv variable
    const col = new Map();        // column variable -> { salv, name }
    const parts = new Map();      // a variable of get_sorts( ), get_display_settings( ), ... -> { salv, level }
    this.salvVars = new Set();
    const fcat = new Map();       // field catalog table -> [{ name, text, hidden }]
    const fcatWa = new Map();     // field catalog work area -> current column
    this.fcatVars = new Set();
    this.layoutVars = new Set();
    this.alvCallbacks = new Map(); // FORM name -> callback kind
    this.fcat = fcat;
    this.layoutTitle = new Map();  // layout variable -> the title it sets (grid_title)
    const sortVars = new Map();    // a sort table or line of the classic ALV -> "table" | "line"
    const sortWa = new Map();      // sort line -> the row it holds now
    this.sortRows = new Map();     // sort table -> [{ name, descending, subtotal }]

    // the variables: REF TO cl_salv_*, the field catalog and layout types
    const allStmts = [...this.decls, ...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body)];
    for (const s of allStmts) {
      // DATA(fcat) = VALUE lvc_t_fcat( ... ) - declared where it is filled
      if (kind(s) === "Move") {
        const m = /^data\s*\(\s*([\w/]+)\s*\)\s*=\s*value\s+(slis_t_fieldcat_alv|lvc_t_fcat)\s*\(/.exec(lc(renderTokens(stmtTokens(s))));
        if (m) this.fcatVars.add(m[1]);
        continue;
      }
      if (!["Data", "Static"].includes(kind(s))) continue;
      const text = lc(renderTokens(stmtTokens(s)));
      const name = lc(declName(s) ?? "");
      if (/type\s+ref\s+to\s+c[lx]_salv_/.test(text) && !salvMode) this.salvVars.add(name);
      if (/type\s+(standard\s+table\s+of\s+|table\s+of\s+|line\s+of\s+)?(slis_t_fieldcat_alv|slis_fieldcat_alv|lvc_t_fcat|lvc_s_fcat)\b/.test(text)) this.fcatVars.add(name);
      // the layout, sort, events, header and print settings of the classic
      // ALV - the tables and their lines; the sort becomes set_sort( )
      const typed = (types) => new RegExp(`(type|like)\\s+((standard\\s+|sorted\\s+|hashed\\s+)?table\\s+of\\s+|line\\s+of\\s+)?(${types})\\b`).test(text);
      if (typed("slis_t_sortinfo_alv|slis_sortinfo_alv|lvc_t_sort|lvc_s_sort")) {
        this.layoutVars.add(name);
        sortVars.set(name, /slis_t_sortinfo_alv|lvc_t_sort|table\s+of/.test(text) ? "table" : "line");
      } else if (typed("slis_layout_alv|lvc_s_layo|slis_print_alv|lvc_s_prnt|disvariant|slis_t_event|slis_alv_event|slis_t_listheader|slis_listheader|slis_t_extab|slis_extab|slis_t_filter_alv|slis_filter_alv|lvc_t_filt|lvc_s_filt|ui_functions")) {
        this.layoutVars.add(name);
      }
    }
    // LIKE LINE OF / LIKE a table of the layout - dropped with it
    for (const s of allStmts) {
      if (!["Data", "Static"].includes(kind(s))) continue;
      const m = /\blike\s+(?:line\s+of\s+)?([\w/]+)/.exec(lc(renderTokens(stmtTokens(s))));
      const name = lc(declName(s) ?? "");
      if (m && this.layoutVars.has(m[1]) && name) {
        this.layoutVars.add(name);
        if (sortVars.has(m[1])) sortVars.set(name, /line\s+of/.test(lc(renderTokens(stmtTokens(s)))) ? "line" : sortVars.get(m[1]));
      }
    }

    const tryStack = [];
    const seq = [...this.events.flatMap((e) => e.stmts), ...this.forms.flatMap((f) => f.body), ...this.gridHandlers.flatMap((h) => h.body)];
    for (let si = 0; si < seq.length; si++) {
      const s = seq[si];
      const k = kind(s);
      const toks = stmtTokens(s).map((t) => t.getStr());
      const flat = lc(toks.join(" "));

      // the stand-ins of the SALV: the TRY stays, its cx_salv_* the stand-in exception
      if (salvMode && ["Try", "Catch", "Cleanup", "EndTry"].includes(k)) continue;
      if (k === "Try") { tryStack.push({ stmt: s, clauses: [], cleanup: false }); continue; }
      if (k === "Catch" && tryStack.length) {
        const names = children(s, "ClassName").map((c) => lc(nodeText(c)));
        tryStack[tryStack.length - 1].clauses.push({ stmt: s, names, body: [] });
        continue;
      }
      if (k === "Cleanup" && tryStack.length) { tryStack[tryStack.length - 1].cleanup = true; continue; }
      if (k === "EndTry" && tryStack.length) {
        const t = tryStack.pop();
        let kept = 0;
        for (const c of t.clauses) {
          if (c.names.every((n) => /^cx_salv_/.test(n))) {
            this.alvPlan.set(c.stmt, { action: "skip", reason: "CATCH of a CL_SALV_TABLE exception - alv( ) raises none" });
            for (const b of c.body) this.alvPlan.set(b, { action: "skip" });
          } else {
            kept++;
            if (c.names.some((n) => /^cx_salv_/.test(n))) this.alvPlan.set(c.stmt, { action: "catch", names: c.names.filter((n) => !/^cx_salv_/.test(n)) });
          }
        }
        if (kept === 0 && !t.cleanup && t.clauses.length) {
          this.alvPlan.set(t.stmt, { action: "skip" });
          this.alvPlan.set(s, { action: "skip" });
        }
        continue;
      }
      if (tryStack.length) {
        const t = tryStack[tryStack.length - 1];
        if (t.clauses.length) t.clauses[t.clauses.length - 1].body.push(s);
      }

      if (this.gridVars.size && !this.alvPlan.has(s)) {
        const plan = this.gridPlan(s, k, flat, seq, si);
        if (plan) {
          this.alvPlan.set(s, plan);
          continue;
        }
      }

      // cl_salv_table=>factory( IMPORTING r_salv_table = x CHANGING t_table = itab )
      if (/cl_salv_table\s*=>\s*factory/.test(flat) && !salvMode) {
        const m = /r_salv_table\s*=\s*(?:data\s*\(\s*)?([\w/]+)/.exec(flat);
        const tab = /t_table\s*=\s*([\w/-]+)/.exec(flat);
        if (!m || !tab) {
          this.refuse(s, "cl_salv_table=>factory( ) without r_salv_table and t_table - not understood");
          continue;
        }
        this.salvVars.add(m[1]);
        const tableTok = stmtTokens(s).find((t) => lc(t.getStr()) === tab[1].split("-")[0]);
        this.salv.set(m[1], { table: tab[1], tableTok, settings: [], lineSelection: false, displayed: false, stmt: s });
        this.alvPlan.set(s, { action: "drop", reason: "cl_salv_table=>factory( ) - alv( ) at display( )" });
        continue;
      }

      // LOOP AT x->get_columns( )->get( ) ASSIGNING <c> - the texts of every
      // column, from its name and its DDIC text: a loop over the columns of
      // the grid after alv( )
      if (k === "Loop") {
        const each = this.salvColumnLoop(s, seq, si);
        if (each) {
          this.salv.get(each.salv).settings.push({ m: "for_each_column", texts: each.texts });
          for (let j = si; j <= each.end; j++) this.alvPlan.set(seq[j], { action: "drop", reason: "the texts of every column - a LOOP over get_columns( ) of the grid after alv( )" });
          si = each.end;
          continue;
        }
      }

      // a call chain over a SALV object: x->get_columns( )->get_column( 'A' )->set_long_text( ... )
      const chain = salvChain(s);
      if (chain) {
        let ctx;
        let target = chain.target;
        if (this.salv.has(chain.root)) ctx = { level: "salv", salv: chain.root };
        else if (cols.has(chain.root)) ctx = { level: "columns", salv: cols.get(chain.root) };
        else if (col.has(chain.root)) ctx = { level: "column", ...col.get(chain.root) };
        else if (parts.has(chain.root)) ctx = { ...parts.get(chain.root) };
        if (ctx) {
          let ok = true;
          for (const c of chain.calls) {
            const salv = this.salv.get(ctx.salv);
            const arg = c.arg;
            switch (`${ctx.level}.${c.name}`) {
              case "salv.get_columns": ctx = { ...ctx, level: "columns" }; break;
              case "columns.get_column":
                ctx = { ...ctx, level: "column", name: arg && /^['`]/.test(arg) ? uc(unquote(arg)) : undefined };
                break;
              case "salv.get_display_settings": ctx = { ...ctx, level: "display" }; break;
              case "salv.get_functions": ctx = { ...ctx, level: "functions" }; break;
              case "salv.get_event": ctx = { ...ctx, level: "event" }; break;
              case "salv.get_sorts": ctx = { ...ctx, level: "sorts" }; break;
              case "salv.get_aggregations": ctx = { ...ctx, level: "aggregations" }; break;
              case "salv.get_layout": case "salv.get_selections":
              case "salv.get_filters": case "salv.get_print": case "salv.get_functional_settings":
                ctx = { ...ctx, level: "other" }; break;
              case "sorts.add_sort": {
                // add_sort( columnname = 'A' sequence = if_salv_c_sort=>sort_down subtotal = abap_true )
                const a = namedArgs(arg, "columnname");
                const name = a.columnname && /^['`]/.test(a.columnname) ? uc(unquote(a.columnname)) : undefined;
                if (!name) ok = false;
                else salv.settings.push({ m: "set_sort", name, descending: /sort_down/i.test(a.sequence ?? ""), subtotal: a.subtotal && isTrue(a.subtotal) });
                break;
              }
              case "aggregations.add_aggregation": {
                const a = namedArgs(arg, "columnname");
                const name = a.columnname && /^['`]/.test(a.columnname) ? uc(unquote(a.columnname)) : undefined;
                const agg = /=>\s*(\w+)$/.exec(a.aggregation ?? "if_salv_c_aggregation=>total")?.[1].toLowerCase();
                const mapped = { total: "sum", average: "average", minimum: "minimum", maximum: "maximum", count: "count" }[agg];
                if (!name || !mapped) ok = false;
                else salv.settings.push({ m: "set_column_aggregation", name, aggregation: mapped });
                break;
              }
              case "columns.set_optimize": salv.settings.push({ m: "set_optimize", val: arg === undefined || isTrue(arg) }); break;
              case "display.set_striped_pattern": salv.settings.push({ m: "set_striped", val: arg === undefined || isTrue(arg) }); break;
              case "column.set_key":
                if (ctx.name) salv.settings.push({ m: "set_column_key", name: ctx.name, val: arg === undefined || isTrue(arg) });
                else ok = false;
                break;
              case "column.set_output_length":
                // a width of n characters - 0.6 em a character, as the list counts
                if (ctx.name && /^\d+$/.test(arg ?? "")) salv.settings.push({ m: "set_column_width", name: ctx.name, width: `${(Number(arg) * 0.6).toFixed(1)}em` });
                else ok = false;
                break;
              case "salv.display":
                salv.displayed = true;
                this.alvPlan.set(s, { action: "alv", salv: ctx.salv });
                break;
              case "display.set_list_header": salv.settings.push({ m: "set_title", arg }); break;
              case "column.set_long_text": case "column.set_medium_text": case "column.set_short_text":
                if (ctx.name) salv.settings.push({ m: "set_column_text", name: ctx.name, arg, rank: c.name });
                else ok = false;
                break;
              case "column.set_visible":
                if (ctx.name && /abap_false|' '|space/.test(lc(arg ?? ""))) salv.settings.push({ m: "set_column_hidden", name: ctx.name });
                else if (!ctx.name) ok = false;
                break;
              case "column.set_technical":
                if (ctx.name && !/abap_false|' '|space/.test(lc(arg ?? ""))) salv.settings.push({ m: "set_column_hidden", name: ctx.name });
                break;
              case "functions.set_all": case "functions.set_default": case "column.set_optimized":
                this.note("CL_SALV_TABLE: the toolbar functions and the optimized width of one column have no counterpart - the grid has its toolbar, sorts and filters by itself, and optimizes every column (set_optimize( ))");
                break;
              default:
                ok = false;
            }
          }
          if (chain.target) {
            if (ctx.level === "columns") cols.set(target, ctx.salv);
            else if (ctx.level === "column") col.set(target, { salv: ctx.salv, name: ctx.name });
            // lo_sorts = go_alv->get_sorts( ) - its calls further down are the chain's
            else if (["get_sorts", "get_aggregations", "get_display_settings", "get_functions"].includes(chain.calls[chain.calls.length - 1].name)) parts.set(target, ctx);
            this.salvVars.add(target);
          }
          if (!this.alvPlan.has(s)) {
            this.alvPlan.set(s, ok
              ? { action: "drop", reason: "CL_SALV_TABLE setting - in the alv( ) chain" }
              : { action: "drop", reason: "CL_SALV_TABLE call", todo: `CL_SALV_TABLE call without a counterpart in the alv( ) chain, dropped: ${shortText(s)}` });
          }
          continue;
        }
      }

      // SET HANDLER ... FOR salv->get_event( ) - the double click
      if (k === "SetHandler") {
        const m = /for\s+([\w/]+)\s*->\s*get_event/.exec(flat) ?? /for\s+([\w/]+)\s*\./.exec(flat + ".");
        const v = m && (this.salv.has(m[1]) ? m[1] : undefined);
        if (v) {
          this.salv.get(v).lineSelection = true;
          this.alvPlan.set(s, { action: "drop", reason: "SET HANDLER of the SALV events - set_line_selection( )",
            todo: "the ALV event handler is dropped: move the code of its double click handler into at_line_selection( ) - row is the index of the clicked row" });
          continue;
        }
      }

      if (k === "CallFunction") {
        const fm = uc(unquote(nodeText(child(s, "FunctionName")).trim()));
        if (fm === "REUSE_ALV_FIELDCATALOG_MERGE" || fm === "LVC_FIELDCATALOG_MERGE") {
          this.alvPlan.set(s, { action: "drop", reason: `${fm} - the columns come from the table (RTTI)` });
          continue;
        }
        if (/^REUSE_ALV_(GRID|LIST)_DISPLAY(_LVC)?$/.test(fm)) {
          const p = functionParams(s);
          const table = p.get("t_outtab");
          if (!table) {
            this.refuse(s, `${fm} without TABLES t_outtab - not understood`);
            continue;
          }
          const plan = { action: "reuse", fm, table: nodeText(table.node), tableNode: table.node, settings: [], lineSelection: false };
          const title = p.get("i_grid_title") ?? p.get("i_title");
          if (title) plan.settings.push({ m: "set_title", arg: nodeText(title.node) });
          // the field catalog is read when the call is written - it is often
          // built in a FORM further down
          const fc = p.get("it_fieldcat") ?? p.get("it_fieldcat_lvc");
          plan.fieldcatVar = fc ? lc(nodeText(fc.node)) : undefined;
          const ucomm = p.get("i_callback_user_command");
          if (ucomm) {
            plan.lineSelection = true;
            const formName = lc(unquote(nodeText(ucomm.node).trim()));
            this.alvCallbacks.set(formName, { kind: "user_command", stmt: s });
          }
          for (const cb of ["i_callback_pf_status_set", "i_callback_top_of_page", "i_callback_html_top_of_page", "i_callback_html_end_of_list"]) {
            const v = p.get(cb);
            if (!v) continue;
            const formName = lc(unquote(nodeText(v.node).trim()));
            this.alvCallbacks.set(formName, { kind: cb, stmt: s });
          }
          const sort = p.get("it_sort") ?? p.get("it_sort_lvc");
          if (sort) plan.sortVar = lc(nodeText(sort.node)).replace(/\[\]$/, "");
          for (const ignored of ["is_layout", "is_layout_lvc", "it_events", "is_variant", "i_save", "it_filter", "is_print", "it_excluding"]) {
            if (p.has(ignored)) plan.todos = [...(plan.todos ?? []), `${fm}: ${uc(ignored)} has no counterpart in the alv( ) chain and is dropped`];
          }
          this.alvPlan.set(s, plan);
          // IF sy-subrc <> 0 right after it checked the EXCEPTIONS of the
          // function - alv( ) raises none, and sy-subrc is the one of the
          // statement before
          let next = si + 1;
          while (seq[next] && kind(seq[next]) === "Comment") next++;
          if (seq[next] && kind(seq[next]) === "If" && /sy\s*-\s*subrc/i.test(renderTokens(seq[next].getTokens()))) {
            let depth = 0;
            for (let j = next; j < seq.length; j++) {
              const kj = kind(seq[j]);
              if (kj === "If") depth++;
              if (kj === "EndIf") depth--;
              this.alvPlan.set(seq[j], { action: "skip" });
              if (depth === 0) break;
            }
            plan.todos = [...(plan.todos ?? []), `${fm}: the IF sy-subrc after the call checked its EXCEPTIONS - alv( ) raises none, the check is dropped`];
          }
          continue;
        }
      }

      // the field catalog of REUSE_ALV_*: wa-fieldname = 'A', wa-seltext_m = 'T', APPEND wa TO fcat
      const fcatRoot = toks.length ? lc(toks[0]) : "";
      if (this.fcatVars.has(fcatRoot) || toks.some((t, i) => this.fcatVars.has(lc(t)) && (i === 0 || !["-", "->", "=>"].includes(toks[i - 1])))) {
        const m = /^([\w/]+)\s*-\s*(\w+)\s*=\s*(.+)$/.exec(flat);
        const orig = /^[\w/]+\s*-\s*\w+\s*=\s*(.+)$/.exec(toks.join(" "));
        // a block over the field catalog (LOOP AT fcat ASSIGNING <fs> ... ENDLOOP)
        // sets its columns by position - dropped alone, its ENDLOOP would stay
        if (OPENERS.has(k)) {
          this.refuse(s, `${shortText(s)} - a block over the field catalog; alv( ) takes the columns set field by field, port it by hand`);
          continue;
        }
        // a value the alv( ) chain can take where the grid is shown: a literal,
        // a text symbol, a global of the report - not a FORM's parameter
        const fixed = (v) => /^['`]/.test(v) || /^text-\w+$/i.test(v) || this.globalData.has(lc(v.split("-")[0]));
        if (k === "Move" && m && this.fcatVars.has(m[1]) && /^(fieldname|seltext_[lms]|reptext_ddic|scrtext_[lms]|coltext)$/.test(m[2]) && !fixed(orig[1].trim())) {
          this.refuse(s, `the field catalog is filled from ${orig[1].trim()} - alv( ) is set up where the grid is shown, where it is not known; port the field catalog by hand`);
          continue;
        }
        if (k === "Move" && m && this.fcatVars.has(m[1])) {
          const cur = fcatWa.get(m[1]) ?? {};
          if (m[2] === "fieldname") cur.name = uc(unquote(orig[1].trim()));
          else if (/^(seltext_[lms]|reptext_ddic|scrtext_[lms]|coltext)$/.test(m[2])) cur.text = orig[1].trim();
          else if ((m[2] === "no_out" || m[2] === "tech") && /'x'|abap_true/.test(m[3])) cur.hidden = true;
          else if (m[2] === "hotspot" && /'x'|abap_true/.test(m[3])) cur.hotspot = true;
          else if (m[2] === "do_sum" && /'x'|abap_true/.test(m[3])) cur.sum = true;
          else if (m[2] === "key" && /'x'|abap_true/.test(m[3])) cur.key = true;
          else if (m[2] === "outputlen" && /^'?\d+'?$/.test(m[3].trim())) cur.width = Number(m[3].trim().replace(/'/g, ""));
          else if (m[2] === "col_pos" && /^'?\d+'?$/.test(m[3].trim())) cur.position = Number(m[3].trim().replace(/'/g, ""));
          else this.note("field catalog settings without a counterpart (the emphasis, the edit mask, the DDIC reference, ...) - the grid takes them from the table");
          fcatWa.set(m[1], cur);
        } else if (k === "Move" && /^(?:data\s*\(\s*)?([\w/]+)(?:\s*\))?\s*=\s*value\s+[\w/#]+\s*\(/.test(flat)) {
          // fcat = VALUE #( ( fieldname = 'A' coltext = 'T' ) ( ... ) ) - a column per row
          const target = /^(?:data\s*\(\s*)?([\w/]+)/.exec(flat)[1];
          const text = toks.join(" ");
          const rows = valueRows(text.slice(text.search(/\bvalue\b/i)));
          if (this.fcatVars.has(target) && rows) {
            if (!fcat.has(target)) fcat.set(target, []);
            fcat.get(target).push(...rows.map(fcatColumn));
          }
        } else if (k === "Append") {
          const m2 = /^append\s+([\w/]+)\s+to\s+([\w/]+)/.exec(flat);
          const v = /^append\s+value\s+#\s*\((.*)\)\s+to\s+([\w/]+)/i.exec(toks.join(" "));
          if (m2 && this.fcatVars.has(m2[2])) {
            if (!fcat.has(m2[2])) fcat.set(m2[2], []);
            fcat.get(m2[2]).push({ ...(fcatWa.get(m2[1]) ?? {}) });
          } else if (v && this.fcatVars.has(lc(v[2]))) {
            if (!fcat.has(lc(v[2]))) fcat.set(lc(v[2]), []);
            fcat.get(lc(v[2])).push(fcatColumn(v[1]));
          }
        } else if (k === "Clear") {
          for (const v of this.fcatVars) if (new RegExp(`\\b${v}\\b`).test(flat)) fcatWa.set(v, {});
        }
        this.alvPlan.set(s, { action: "drop", reason: "field catalog - set_column_text( ) / set_column_hidden( ) in the alv( ) chain" });
        continue;
      }
      // the sort of REUSE_ALV_*: wa-fieldname = 'A', wa-down = 'X', APPEND wa TO sort
      if (toks.some((t, i) => sortVars.has(lc(t)) && (i === 0 || !["-", "->", "=>"].includes(toks[i - 1]))) && k !== "CallFunction" && !["Data", "Static"].includes(k)) {
        const m = /^([\w/]+)\s*-\s*(\w+)\s*=\s*(.+)$/.exec(toks.join(" "));
        const app = /^append\s+([\w/]+)\s+to\s+([\w/]+)$/.exec(flat.replace(/\s*\.$/, ""));
        const val = m && m[3].trim();
        let understood = true;
        if (k === "Move" && m && sortVars.get(lc(m[1])) === "line") {
          const cur = sortWa.get(lc(m[1])) ?? {};
          const comp = lc(m[2]);
          if (comp === "fieldname" && /^['`]/.test(val)) cur.name = uc(unquote(val));
          else if (comp === "down") cur.descending = isTrue(val);
          else if (comp === "up") cur.descending = !isTrue(val) && cur.descending;
          else if (comp === "subtot") cur.subtotal = isTrue(val);
          else if (!["spos", "tabname", "comp", "expa", "group", "obligatory"].includes(comp)) understood = false;
          if (comp === "fieldname" && !/^['`]/.test(val)) understood = false;
          sortWa.set(lc(m[1]), cur);
        } else if (k === "Move" && /^([\w/]+)\s*=\s*value\s+[\w/#]+\s*\(/.test(flat) && sortVars.get(/^([\w/]+)/.exec(flat)[1]) === "table") {
          // sort = VALUE #( ( fieldname = 'A' down = 'X' ) ( ... ) )
          const text = toks.join(" ");
          const rows = valueRows(text.slice(text.search(/\bvalue\b/i))) ?? [];
          const parsed = rows.map((r) => {
            const a = Object.fromEntries([...r.matchAll(/(\w+)\s*=\s*('(?:[^']|'')*'|`(?:[^`]|``)*`|[\w-]+)/g)].map((x) => [lc(x[1]), x[2]]));
            return { name: a.fieldname && /^['`]/.test(a.fieldname) ? uc(unquote(a.fieldname)) : undefined, descending: !!a.down && isTrue(a.down), subtotal: !!a.subtot && isTrue(a.subtot) };
          });
          if (!rows.length || parsed.some((x) => !x.name)) understood = false;
          else this.sortRows.set(/^([\w/]+)/.exec(flat)[1], parsed);
        } else if (k === "Append" && app && sortVars.get(app[1]) === "line" && sortVars.get(app[2]) === "table") {
          if (!this.sortRows.has(app[2])) this.sortRows.set(app[2], []);
          this.sortRows.get(app[2]).push({ ...(sortWa.get(app[1]) ?? {}) });
        } else if (["Clear", "Refresh", "Free"].includes(k)) {
          for (const v of sortVars.keys()) if (new RegExp(`\\b${v}\\b`).test(flat)) {
            if (sortVars.get(v) === "line") sortWa.set(v, {});
            else this.sortRows.set(v, []);
          }
        } else understood = false;
        this.alvPlan.set(s, understood
          ? { action: "drop", reason: "the sort of the ALV - set_sort( ) in the alv( ) chain" }
          : { action: "drop", reason: "the sort of the ALV", todo: `the sort of the ALV is set here in a way set_sort( ) of the alv( ) chain does not take, dropped: ${shortText(s)}` });
        continue;
      }
      // the layout of the grid: its title; zebra and optimized widths are the runtime's
      {
        const m = /^([\w/]+)\s*-\s*(\w+)\s*=\s*(.+)$/.exec(toks.join(" "));
        if (k === "Move" && m && this.layoutVars.has(lc(m[1]))) {
          const comp = lc(m[2]);
          if (comp === "grid_title" || comp === "window_titlebar") {
            this.layoutTitle.set(lc(m[1]), m[3].trim());
            this.alvPlan.set(s, { action: "drop", reason: "the title of the grid - set_title( ) in the alv( ) chain" });
            continue;
          }
          if (["zebra", "cwidth_opt", "col_opt", "colwidth_optimize", "zebra_pattern", "no_rowmark"].includes(comp)) {
            this.note("ALV layout: zebra stripes and optimized column widths - the grid of the runtime lays itself out");
            this.alvPlan.set(s, { action: "drop", reason: "ALV layout - the grid lays itself out" });
            continue;
          }
        }
      }
      if (toks.some((t, i) => this.layoutVars.has(lc(t)) && (i === 0 || !["-", "->", "=>"].includes(toks[i - 1]))) && k !== "CallFunction") {
        this.alvPlan.set(s, { action: "drop", reason: "ALV layout", todo: `ALV layout, sort or event setting without a counterpart, dropped: ${shortText(s)}` });
        continue;
      }

    }
    // any other use of a SALV object - or of its columns - has nothing to
    // refer to any more: the objects are gone, alv( ) shows the table
    for (const s of seq) {
      if (this.alvPlan.has(s) || ["Data", "Static", "Comment"].includes(kind(s))) continue;
      const toks = stmtTokens(s).map((t) => lc(t.getStr()));
      const used = toks.find((t, i) => this.salv.has(t) || cols.has(t) || col.has(t) || parts.has(t)
        ? i === 0 || !["-", "->", "=>", "~"].includes(toks[i - 1]) : false);
      if (used) this.refuse(s, `${used}, an object of CL_SALV_TABLE, is used here - alv( ) has no object to refer to; port the statement by hand`);
    }
    // a FORM that only built the field catalog or set up the ALV is empty now
    this.emptyForms = new Set(this.forms.filter((f) => {
      const code = f.body.filter((x) => kind(x) !== "Comment");
      return code.length > 0 && code.every((x) => ["drop", "skip"].includes(this.alvPlan.get(x)?.action));
    }).map((f) => lc(nodeText(child(f.stmt, "FormName")))));
    for (const [name, v] of this.salv) {
      if (!v.displayed) this.todo(v.stmt, `the CL_SALV_TABLE object ${name} is created but never displayed - no alv( ) is generated for it`);
    }
  },


  /** the alv( ) settings of a column of a classic field catalog */
  fcatSettings(c) {
    const out = [];
    if (!c.name) return out;
    if (c.text) out.push({ m: "set_column_text", name: c.name, arg: c.text });
    if (c.hidden) out.push({ m: "set_column_hidden", name: c.name });
    if (c.hotspot) out.push({ m: "set_column_hotspot", name: c.name });
    if (c.sum) out.push({ m: "set_column_sum", name: c.name });
    if (c.key) out.push({ m: "set_column_key", name: c.name, val: true });
    if (c.width) out.push({ m: "set_column_width", name: c.name, width: `${(c.width * 0.6).toFixed(1)}em` });
    if (c.position) out.push({ m: "set_column_position", name: c.name, position: String(c.position) });
    return out;
  },


  /** IT_SORT of REUSE_ALV_*: set_sort( ) per row the report filled in */
  sortSettings(plan, s) {
    if (!plan.sortVar) return [];
    const rows = this.sortRows.get(plan.sortVar);
    if (!rows?.length) {
      this.todo(s, `${plan.fm}: IT_SORT ${plan.sortVar} is filled in a way the converter does not follow - set_sort( ) in the alv( ) chain, by hand`);
      return [];
    }
    return rows.filter((r) => r.name).map((r) => ({ m: "set_sort", name: r.name, descending: !!r.descending, subtotal: !!r.subtotal }));
  },


  // ------------------------------------------------------------------ ALV

  alvChain(table, tableTok, settings, lineSelection, s) {
    const root = lc(table.split("-")[0]);
    if (!this.globalData.has(root)) {
      this.todo(s, `alv( ${table} ): the table is no attribute of the class - alv( ) copies it into a data reference, which the draft rebuilds with RTTI on every roundtrip; make it a global DATA of the report`);
    }
    // the last text of a column wins - long over medium over short
    const rank = { set_short_text: 1, set_medium_text: 2, set_long_text: 3 };
    const texts = new Map();
    const hidden = [];
    let title;
    for (const st of settings) {
      if (st.m === "set_title") title = st.arg;
      if (st.m === "set_column_text") {
        const prev = texts.get(st.name);
        if (!prev || (rank[st.rank] ?? 3) >= (rank[prev.rank] ?? 3)) texts.set(st.name, st);
      }
      if (st.m === "set_column_hidden" && !hidden.includes(st.name)) hidden.push(st.name);
    }
    const items = [{ method: "alv", params: [{ value: lc(table) }] }];
    if (title) items.push({ method: "set_title", params: [{ value: this.literalArg(title, s) }] });
    for (const [name, st] of texts) {
      items.push({ method: "set_column_text", params: [{ name: "name", value: literal(name) }, { name: "text", value: this.literalArg(st.arg, s) }] });
    }
    for (const name of hidden) items.push({ method: "set_column_hidden", params: [{ value: literal(name) }] });
    for (const st of settings.filter((x) => x.m === "set_column_hotspot" || x.m === "set_column_sum")) {
      items.push({ method: st.m, params: [{ value: literal(st.name) }] });
    }
    for (const st of settings) {
      const bool = (v) => (v ? "abap_true" : "abap_false");
      if (st.m === "set_column_aggregation") {
        items.push(st.aggregation === "sum" ? { method: "set_column_sum", params: [{ value: literal(st.name) }] }
          : { method: st.m, params: [{ name: "name", value: literal(st.name) }, { name: "aggregation", value: `z2ui5_cl_cgui_alv=>cs_aggregation-${st.aggregation}` }] });
      } else if (st.m === "set_sort") {
        items.push({ method: st.m, params: [{ name: "name", value: literal(st.name) },
          ...(st.descending ? [{ name: "descending", value: "abap_true" }] : []), ...(st.subtotal ? [{ name: "subtotal", value: "abap_true" }] : [])], positional: !st.descending && !st.subtotal });
      } else if (st.m === "set_column_key") {
        items.push({ method: st.m, params: [{ name: "name", value: literal(st.name) }, ...(st.val ? [] : [{ name: "val", value: "abap_false" }])], positional: st.val });
      } else if (st.m === "set_column_width") {
        items.push({ method: st.m, params: [{ name: "name", value: literal(st.name) }, { name: "width", value: literal(st.width) }] });
      } else if (st.m === "set_column_position") {
        items.push({ method: st.m, params: [{ name: "name", value: literal(st.name) }, { name: "position", value: st.position }] });
      } else if (st.m === "set_optimize" || st.m === "set_striped") {
        // both are on by default
        if (!st.val) items.push({ method: st.m, params: [{ value: bool(st.val) }] });
      }
    }
    for (const st of settings.filter((x) => x.m === "add_function")) items.push({ method: "add_function", params: st.params });
    if (settings.some((x) => x.m === "set_selection_mode")) items.push({ method: "set_selection_mode", params: [] });
    if (lineSelection) items.push({ method: "set_line_selection", params: [] });
    // a loop over the columns: the text set last, long over medium over short
    const each = settings.filter((x) => x.m === "for_each_column");
    if (!each.length) return renderChain({ items, head: "" });
    const chain = renderChain({ items, head: "" });
    chain[0] = `DATA(lo_alv) = ${chain[0]}`;
    const best = each.flatMap((x) => x.texts).reduce((a, b) => ((rank[b.rank] ?? 3) >= (rank[a.rank] ?? 3) ? b : a));
    return [...chain,
      `LOOP AT lo_alv->get_columns( ${lc(table)} ) INTO DATA(ls_column).`,
      `  lo_alv->set_column_text( name = ls_column-name`,
      `                           text = ${best.expr} ).`,
      "ENDLOOP."];
  },


  /** LOOP AT salv->get_columns( )->get( ) ASSIGNING <c> | INTO c with a
   *  body that only sets the texts of the column (<c>-r_column, or a
   *  variable of it), from its name (get_columnname( )) and its DDIC texts
   *  (get_long_text( ), ...) - { salv, end, texts: [{ rank, expr }] } with
   *  expr in terms of ls_column-name and ls_column-label; undefined else */
  salvColumnLoop(s, seq, si) {
    const flat = lc(renderTokens(stmtTokens(s)));
    const m = /^loop\s+at\s+([\w/]+)\s*->\s*get_columns\s*\(\s*\)\s*->\s*get\s*\(\s*\)\s+(?:assigning\s+(?:field-symbol\s*\(\s*)?(<\w+>)\s*\)?|into\s+(?:data\s*\(\s*)?(\w+)\s*\)?)\s*\.?$/.exec(flat);
    if (!m || !this.salv.has(m[1])) return undefined;
    const row = m[2] ?? m[3];
    const refs = new Set([`${row}-r_column`]);
    const texts = [];
    let depth = 0;
    for (let j = si + 1; j < seq.length; j++) {
      const x = seq[j];
      const k = kind(x);
      if (k === "Loop") depth++;
      if (k === "EndLoop") {
        if (depth-- === 0) return texts.length ? { salv: m[1], end: j, texts } : undefined;
        return undefined;
      }
      if (k === "Comment") continue;
      const t = renderTokens(stmtTokens(x)).replace(/\s+/g, " ").trim();
      // DATA(o_col) = <c>-r_column.
      const alias = /^data\s*\(\s*(\w+)\s*\)\s*=\s*(\S+)\s*\.?$/i.exec(t);
      if (alias && refs.has(lc(alias[2]))) {
        refs.add(lc(alias[1]));
        continue;
      }
      // o_col->set_long_text( expr ).
      const set = /^(\S+?)\s*->\s*set_(long|medium|short)_text\s*\(\s*(.*)\s*\)\s*\.?$/i.exec(t);
      if (!set || !refs.has(lc(set[1]))) return undefined;
      let expr = set[3].trim();
      for (const r of refs) {
        const esc = r.replace(/[<>-]/g, (c) => `\\${c}`);
        expr = expr.replace(new RegExp(`${esc}\\s*->\\s*get_columnname\\s*\\(\\s*\\)`, "gi"), "ls_column-name")
          .replace(new RegExp(`${esc}\\s*->\\s*get_(long|medium|short)_text\\s*\\(\\s*\\)`, "gi"), "ls_column-label");
      }
      // anything else of the column is no text of it
      if ([...refs].some((r) => expr.toLowerCase().includes(r))) return undefined;
      texts.push({ rank: `set_${lc(set[2])}_text`, expr: expr || "``" });
    }
    return undefined;
  },


  /** an argument written in the report - a TEXT-001 becomes its text */
  literalArg(arg, s) {
    const m = /^text-(\w+)$/i.exec(arg.trim());
    if (m) return this.textSymbol(m[1], undefined, s);
    const m2 = /^('(?:[^']|'')*')\((\w+)\)$/.exec(arg.trim());
    if (m2) return this.textSymbol(m2[2], unquote(m2[1]), s);
    return arg.trim();
  },


  /** the USER_COMMAND callback of REUSE_ALV_GRID_DISPLAY as the body of
   *  at_line_selection( ): the ucomm is the double click, the selfield's
   *  tabindex the row */
  alvCallbackBody(f) {
    const [ucomm, selfield] = f.params.map((p) => p.name);
    if (f.params.length !== 2) {
      this.refuse(f.stmt, `FORM ${f.name} is the USER_COMMAND callback of the ALV and needs two parameters (r_ucomm, rs_selfield)`);
      return [];
    }
    this.map(f.stmt, "the ALV USER_COMMAND callback - its body is `at_line_selection( )`, rs_selfield-tabindex is row");
    const body = this.convertBody(f.body, { method: "at_line_selection", lineSelection: true, callback: { ucomm, selfield } });
    const lines = [`" the ALV double click - FORM ${f.name}, the USER_COMMAND callback`];
    if (new RegExp(`\\b${ucomm}\\b`, "i").test(body.join("\n"))) lines.push(`DATA(${ucomm}) = \`&IC1\`.`);
    // rs_selfield-tabindex -> row, -fieldname -> the column of a hotspot
    // (hide), -value -> that cell of the output table; refresh and the
    // stable flags are moot - the ALV is drawn anew on every roundtrip
    const table = this.alvCallbacks.get(f.name)?.stmt && this.alvPlan?.get(this.alvCallbacks.get(f.name).stmt)?.table?.replace(/\[\]$/, "");
    const flag = new RegExp(`^\\s*${selfield}\\s*-\\s*(refresh|row_stable|col_stable|exit)\\s*=\\s*[^.]*\\.\\s*(".*)?$`, "i");
    let column = false;
    let value = false;
    const out = [];
    for (const l of body) {
      const m = flag.exec(l);
      if (m) {
        if (lc(m[1]) === "exit") {
          out.push(`${l.match(/^\s*/)[0]}leave_to_selection_screen( ).`);
          this.todo(f.stmt, `FORM ${f.name}: ${selfield}-exit leaves the ALV - leave_to_selection_screen( ) shows the selection screen again`);
        }
        continue;
      }
      const re = new RegExp(`\\b${selfield}\\s*-\\s*(\\w+)`, "gi");
      let bad;
      out.push(l.replace(re, (all, comp) => {
        const c = lc(comp);
        if (c === "tabindex") return "row";
        if (c === "fieldname") {
          column = true;
          return "hide";
        }
        if (c === "value" && table) {
          column = true;
          value = true;
          return "lv_r2c_value";
        }
        bad = comp;
        return all;
      }));
      if (bad) {
        this.refuse(f.stmt, `FORM ${f.name}: ${selfield}-${bad} has no counterpart - at_line_selection( ) has the row and the column of a hotspot`);
      }
    }
    if (column) {
      this.todo(f.stmt, `FORM ${f.name}: ${selfield}-fieldname is the column of a hotspot click (hide) - a double click on the row has none; mark the columns that need it as hotspots`);
    }
    if (value) {
      lines.push("DATA lv_r2c_value TYPE string.",
        `READ TABLE ${table} INDEX row ASSIGNING FIELD-SYMBOL(<ls_r2c_row>).`,
        "IF sy-subrc = 0 AND hide IS NOT INITIAL.",
        "  ASSIGN COMPONENT hide OF STRUCTURE <ls_r2c_row> TO FIELD-SYMBOL(<lv_r2c_value>).",
        "  IF sy-subrc = 0.",
        "    lv_r2c_value = <lv_r2c_value>.",
        "  ENDIF.",
        "ENDIF.");
    }
    lines.push(...out);
    return lines;
  },
};


/** abap_true, 'X', `X` - not abap_false, ' ', space */
const isTrue = (v) => /^(abap_true|'x'|`x`)$/i.test(String(v).trim());

/** the named arguments of a call as written (a = 1 b = c=>d), by lower case
 *  name; a single unnamed argument is the one named `first` */
function namedArgs(text, first) {
  const out = {};
  if (!text) return out;
  const re = /(?:^|\s)([a-z_]\w*)\s*=(?!>)\s*/gi;
  const hits = [...text.matchAll(re)];
  if (!hits.length) {
    out[first] = text.trim();
    return out;
  }
  hits.forEach((m, i) => {
    out[m[1].toLowerCase()] = text.slice(m.index + m[0].length, i + 1 < hits.length ? hits[i + 1].index : text.length).trim();
  });
  return out;
}
