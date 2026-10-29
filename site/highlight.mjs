// ABAP syntax highlighting for the site - comments, strings, string
// templates, keywords and numbers as spans of HTML. Line by line: a full-line
// comment starts with * in the first column, a comment with " runs to the end
// of the line, '...' and `...` are literals, |...| a template whose { ... }
// is code again. Not a parser: what it does not know stays plain text.

const KEYWORDS = new Set(`
abap_bool abap_false abap_true abstract add alias aliases all and append appending as ascending assign assigning
at authority-check back begin between binary bit-and bit-or blocks by byte-ca call casting case catch changing
char check class class-data class-events class-methods clear close cnt collect commit comment component components
condense constants context continue conv corresponding create cs data default define definition delete deleting
descending describe display do dummy duplicates else elseif end end-of-page end-of-selection endat endcase
endcatch endclass enddo endform endfunction endif endinterface endloop endmethod endmodule endon endprovide
endselect endtry endwhile entries eq event events exact exceptions exit exporting field field-symbol field-symbols
fields final find first for form format frame free friends from function ge get group gt handler hashed having
hide if implementation import importing in include index inheriting initial initialization inner input insert
instance interface interfaces into is join key le leave left length like line line-selection lines list load
local loop lower lt main mapping matchcode me memory message method methods mode modify module move ne new
next no-display no-gap no-zero non-unique not obligatory object occurs of on optional or order others output
parameters perform pf-status position preferred private program protected provide public radiobutton raise
raising range ranges read read-only receiving redefinition ref reference refresh reject replace report reserve
respecting return returning rollback rows screen search section select select-options selection-screen set shift
single size skip sort sorted space split standard start-of-selection static statics structure submit subtract
sum summary super-function supplied switch table tables testing text then times title to top-of-page transporting
try type type-pool type-pools types uline unassign unique unpacking up update upper user-command using value
via when where while width window with with-heading with-title work write zero
`.trim().split(/\s+/));

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const span = (cls, s) => `<span class="hl-${cls}">${esc(s)}</span>`;

/** one stretch of code (no comment, no literal): keywords and numbers */
function words(code) {
  return code.replace(/[A-Za-z_][\w-]*|\d+|[^A-Za-z_\d]+/g, (w, at) => {
    if (/^\d+$/.test(w)) return span("num", w);
    // a keyword is a word on its own - not a part of a name like lv_data, and
    // not a component: lo->write( ), cls=>data, intf~display
    const component = /(->|=>|~)$/.test(code.slice(0, at));
    if (!component && /^[A-Za-z]/.test(w) && KEYWORDS.has(w.toLowerCase())) return span("kw", w);
    return esc(w);
  });
}

/** a line of ABAP as HTML; state carries an open template over lines */
function line(text, state) {
  if (!state.template && /^\*/.test(text)) return span("com", text);
  let out = "";
  let i = 0;
  let code = "";
  const flush = () => {
    out += words(code);
    code = "";
  };
  while (i < text.length) {
    const c = text[i];
    if (state.template) {
      // inside |...|: text up to | or {, an embedded expression in { }
      let j = i;
      while (j < text.length && text[j] !== "|" && text[j] !== "{") j += text[j] === "\\" ? 2 : 1;
      out += span("str", text.slice(i, Math.min(j + (text[j] === "|" ? 1 : 0), text.length)));
      if (j >= text.length) return out;
      if (text[j] === "|") {
        state.template = false;
        i = j + 1;
        continue;
      }
      const close = text.indexOf("}", j);
      const end = close < 0 ? text.length : close;
      out += span("op", "{") + words(text.slice(j + 1, end)) + (close < 0 ? "" : span("op", "}"));
      i = close < 0 ? text.length : close + 1;
      continue;
    }
    if (c === '"') {
      flush();
      return out + span("com", text.slice(i));
    }
    if (c === "'" || c === "`") {
      flush();
      let j = i + 1;
      while (j < text.length && !(text[j] === c && text[j + 1] !== c)) j += text[j] === c ? 2 : 1;
      out += span("str", text.slice(i, j + 1));
      i = j + 1;
      continue;
    }
    if (c === "|") {
      flush();
      state.template = true;
      out += span("str", "|");
      i++;
      continue;
    }
    code += c;
    i++;
  }
  flush();
  return out;
}

/** ABAP source as HTML for a <pre> */
export function highlightAbap(source) {
  const state = { template: false };
  return source.split("\n").map((l) => line(l, state)).join("\n");
}

/** XML as HTML - the tags and the attribute values set apart */
export function highlightXml(source) {
  return esc(source).replace(/(&lt;\/?)([\w:.-]+)/g, `$1<span class="hl-kw">$2</span>`)
    .replace(/("[^"]*")/g, `<span class="hl-str">$1</span>`);
}

/** a file by its name: ABAP, XML or plain */
export function highlightFile(name, text) {
  if (/\.abap$/i.test(name)) return highlightAbap(text);
  if (/\.xml$/i.test(name)) return highlightXml(text);
  return esc(text);
}
