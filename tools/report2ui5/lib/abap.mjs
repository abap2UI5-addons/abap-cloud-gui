// Helpers over the @abaplint/core syntax tree: node kinds, tokens, and the
// renderer that writes a statement back as source - with the spacing and
// line breaks it had, and single tokens replaced where the conversion
// rewrites them (a TEXT-001, a sy-ucomm, a screen-active).
import * as abaplint from "@abaplint/core";

export { abaplint };

export const isToken = (n) => n instanceof abaplint.Nodes.TokenNode || n instanceof abaplint.Nodes.TokenNodeRegex;
export const kind = (n) => n.get().constructor.name;
export const lc = (s) => String(s).toLowerCase();
export const uc = (s) => String(s).toUpperCase();
export const key = (tok) => `${tok.getRow()}:${tok.getCol()}`;

/** the direct child expressions of kind k */
export const children = (n, k) => n.getChildren().filter((c) => !isToken(c) && (!k || kind(c) === k));
export const child = (n, k) => children(n, k)[0];

/** every expression below n of kind k, depth first */
export function findAll(n, k, out = []) {
  for (const c of n.getChildren()) {
    if (isToken(c)) continue;
    if (kind(c) === k) out.push(c);
    findAll(c, k, out);
  }
  return out;
}

/** the upper case words of the tokens directly under a statement - what
 *  tells PARAMETERS ... AS CHECKBOX from PARAMETERS ... TYPE i */
export const words = (n) => n.getChildren().filter(isToken).map((t) => uc(t.get().getStr())).filter((w) => w !== "." && w !== ",");

/** true when the word list holds the words of seq in a row */
export function hasSeq(list, ...seq) {
  for (let i = 0; i + seq.length <= list.length; i++) {
    if (seq.every((w, j) => list[i + j] === w)) return true;
  }
  return false;
}

/** the expression right after the token word in the children of n */
export function after(n, word, k) {
  const ch = n.getChildren();
  for (let i = 0; i < ch.length - 1; i++) {
    if (isToken(ch[i]) && uc(ch[i].get().getStr()) === word) {
      for (let j = i + 1; j < ch.length; j++) {
        if (isToken(ch[j])) {
          if (!k) return ch[j];
          continue;
        }
        if (!k || kind(ch[j]) === k) return ch[j];
        return undefined;
      }
    }
  }
  return undefined;
}

/** a backquote literal, the way the generated code writes texts */
export const literal = (s) => "`" + String(s).replace(/`/g, "``") + "`";

/** the text of a character or backquote literal token, unquoted */
export function unquote(s) {
  if (s.startsWith("`")) return s.slice(1, -1).replace(/``/g, "`");
  if (s.startsWith("'")) return s.slice(1, s.lastIndexOf("'")).replace(/''/g, "'");
  return s;
}

/**
 * The tokens as source text. Tokens on one row keep their distance, a
 * token on a new row starts a new line indented by its distance from the
 * first token (the caller places the first line). `overrides` maps a token
 * key to its replacement, null drops the token. In a chained statement the
 * part after the colon follows the shared prefix with one blank.
 */
export function renderTokens(tokens, overrides = new Map(), colon = undefined) {
  let out = "";
  let prev;
  let refCol = tokens.length ? colOf(tokens[0]) : 1;
  let lineStart = 0;
  for (const tok of tokens) {
    const k = key(tok);
    const repl = overrides.has(k) ? overrides.get(k) : tok.getStr();
    const crossesColon = colon && prev && before(prev, colon) && !before(tok, colon);
    if (prev === undefined) {
      out += repl ?? "";
    } else if (crossesColon) {
      if (repl !== null) {
        out += " ";
        refCol = colOf(tok) - (out.length - lineStart);
        out += repl;
      }
    } else if (rowOf(tok) === rowOf(prev)) {
      // a macro's parameter is longer or shorter than the &n it replaced:
      // the gap of the macro's body may come out negative, and ABAP wants
      // a blank between two tokens, so an expanded statement keeps one
      const gap = colOf(tok) - (colOf(prev) + prev.getStr().length);
      if (repl !== null) out += " ".repeat(Math.max(gap, virtual(tok) && gap <= 0 ? virtualGap(prev, tok) : 0)) + repl;
    } else if (repl !== null) {
      out += "\n";
      lineStart = out.length;
      out += " ".repeat(Math.max(colOf(tok) - refCol, 2)) + repl;
    }
    prev = tok;
  }
  return out;
}

// A token of a statement the parser expanded from a macro call stands at
// the call's position (every token of it), and remembers the position in
// the macro's body as vrow / vcol - which is what the spacing is read from.
const virtual = (tok) => tok.getStart() instanceof abaplint.VirtualPosition;
// Whether a blank stands between two tokens of an expanded statement whose
// body positions do not say (a parameter longer than its &n): the lexer's
// token class does - a Dash, ParenLeft or Plus without a W on that side
// touches its neighbour, and two words never do.
const GLUED = /^W?(Dash|Plus|ParenLeft|ParenRight|BracketLeft|BracketRight|InstanceArrow|StaticArrow|At|Colon|Comma|Punctuation)W?$/;
function virtualGap(prev, tok) {
  const p = prev.constructor.name;
  const t = tok.constructor.name;
  if (p.endsWith("W") || t.startsWith("W")) return 1;
  if (GLUED.test(p) || GLUED.test(t)) return 0;
  return 1;
}
const rowOf = (tok) => (virtual(tok) ? tok.getStart().vrow : tok.getRow());
const colOf = (tok) => (virtual(tok) ? tok.getStart().vcol : tok.getCol());

const before = (a, b) => a.getRow() < b.getRow() || (a.getRow() === b.getRow() && a.getCol() < b.getCol());

/** a statement without its closing period or comma */
export function stmtTokens(s) {
  const toks = s.getTokens();
  const last = toks[toks.length - 1];
  if (last && (last.getStr() === "." || last.getStr() === ",")) return toks.slice(0, -1);
  return toks;
}

/** the tokens of a node, rendered */
export const nodeText = (n, overrides) => renderTokens(isToken(n) ? [n.get()] : n.getTokens(), overrides);

/** the tokens of a chained statement after its colon - or after the first
 *  `skip` tokens of a statement that is not chained */
export function partTokens(s, skip = 1) {
  const toks = stmtTokens(s);
  const colon = s.getColon();
  if (!colon) return toks.slice(skip);
  return toks.filter((t) => !before(t, colon));
}
