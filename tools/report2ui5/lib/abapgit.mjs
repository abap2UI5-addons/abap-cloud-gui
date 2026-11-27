// The files of a class as abapGit writes them - what a pull compares against
// (abap2UI5 skill abap-check, section 1): the .xml starts with the UTF-8 BOM,
// the .abap does not; LF only, no tabs, no trailing blanks, exactly one
// newline at the end; at most 255 characters per line, or the import dies
// and leaves an empty class behind. The sidecar escapes the apostrophe as
// &apos;, as the ABAP iXML renderer does.

export const MAX_LINE = 255;

/** the name of a class's files as abapGit writes them: /abc/cl_x is #abc#cl_x */
export const classFileBase = (className) => className.toLowerCase().replace(/\//g, "#");

const xmlText = (s) => s
  .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  .replace(/"/g, "&quot;").replace(/'/g, "&apos;");

/** The .clas.xml of a class without unit tests. */
export function classXml(className, description) {
  const descript = xmlText(description.slice(0, 60).trim() || className.toLowerCase());
  return "﻿" + `<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="LCL_OBJECT_CLAS" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
   <VSEOCLASS>
    <CLSNAME>${className.toUpperCase()}</CLSNAME>
    <LANGU>E</LANGU>
    <DESCRIPT>${descript}</DESCRIPT>
    <STATE>1</STATE>
    <CLSCCINCL>X</CLSCCINCL>
    <FIXPT>X</FIXPT>
    <UNICODE>X</UNICODE>
   </VSEOCLASS>
  </asx:values>
 </asx:abap>
</abapGit>
`;
}

/** ABAP source the way abapGit serializes it: LF, tabs expanded, no
 *  trailing blanks, one newline at the end. Runs of blank lines become one,
 *  but for the two in front of CLASS ... IMPLEMENTATION, as in the samples. */
export function normalizeAbap(text) {
  const lines = text.replace(/\r\n?/g, "\n").replace(/\t/g, "  ").split("\n").map((l) => l.replace(/\s+$/, ""));
  const out = [];
  for (const line of lines) {
    if (line === "" && (out.length === 0 || out[out.length - 1] === "")) continue;
    if (/^CLASS \S+ IMPLEMENTATION\.$/i.test(line) && out[out.length - 1] === "") out.push("");
    out.push(line);
  }
  while (out.length && out[out.length - 1] === "") out.pop();
  return out.join("\n") + "\n";
}

/** Lines longer than abapGit imports - [{ row, length }]. */
export function longLines(text) {
  return text.split("\n").flatMap((l, i) => (l.length > MAX_LINE ? [{ row: i + 1, length: l.length }] : []));
}

/**
 * The places a line of ABAP can be broken at: the blanks outside of
 * literals, string templates and comments (ABAP is free-format there), where
 * a comment starts, and the character and backquote literals - [start, end]
 * of each, end the closing quote. undefined when the line does not end where
 * it began - inside a literal or a template that goes on in the next line.
 */
function breaksOf(line) {
  const blanks = [];
  const literals = [];
  let comment;
  let i = 0;
  if (line.startsWith("*")) return { blanks, literals, comment: 0 };
  while (i < line.length) {
    const c = line[i];
    if (c === "\"") {
      comment = i;
      break;
    }
    if (c === "'" || c === "`") {
      const start = i;
      i++;
      for (;;) {
        if (i >= line.length) return undefined;
        if (line[i] === c && line[i + 1] === c) i += 2;
        else if (line[i] === c) break;
        else i++;
      }
      literals.push([start, i]);
      i++;
      continue;
    }
    if (c === "|") {
      // a string template, its embedded expressions included: not broken
      let depth = 0;
      i++;
      for (;;) {
        if (i >= line.length) return undefined;
        if (line[i] === "\\" && depth === 0) i += 2;
        else if (line[i] === "{") depth++, i++;
        else if (line[i] === "}") depth--, i++;
        else if (line[i] === "|" && depth === 0) break;
        else i++;
      }
      i++;
      continue;
    }
    if (c === " " && i > 0 && line[i - 1] !== " ") blanks.push(i);
    i++;
  }
  return { blanks, literals, comment };
}

/**
 * Lines over 255 characters broken at a token boundary, the rest of the line
 * on the next one, two blanks further in: at a blank, in front of a comment
 * (a comment that is too long goes on in a comment line of its own), or - a
 * character or backquote literal longer than the line leaves room for - in
 * two literals joined with the literal operator `&`, which is the same
 * literal. Answers the text and the lines it could not break: [{ row, length }]
 * of the text it answers.
 */
export function wrapLongLines(text) {
  const out = [];
  let failed = false;
  for (const line of text.split("\n")) {
    let rest = line;
    const lead = " ".repeat(line.length - line.trimStart().length);
    const cont = `${lead}  `;
    while (rest.length > MAX_LINE) {
      const at = breaksOf(rest);
      if (!at) break;
      const indent = rest.length - rest.trimStart().length;
      // a comment line: the words that do not fit in a comment line of their own
      if (at.comment !== undefined && rest.slice(0, at.comment).trim() === "") {
        const mark = rest[at.comment] === "*" ? "*" : `${" ".repeat(at.comment)}${rest.startsWith("\"!", at.comment) ? "\"!" : "\""}`;
        const cut = rest.lastIndexOf(" ", MAX_LINE);
        if (cut <= at.comment + 1) break;
        out.push(rest.slice(0, cut).trimEnd());
        const next = `${mark} ${rest.slice(cut).trimStart()}`;
        if (next.length >= rest.length) break;
        rest = next;
        continue;
      }
      const points = [...at.blanks, ...(at.comment !== undefined ? [at.comment] : [])].filter((p) => p > indent && p <= MAX_LINE);
      const p = points.length ? Math.max(...points) : undefined;
      if (p !== undefined && cont.length + rest.slice(p).trimStart().length < rest.length) {
        out.push(rest.slice(0, p).trimEnd());
        rest = `${cont}${rest.slice(p).trimStart()}`;
        continue;
      }
      // a literal across the limit: two literals, joined with &
      const lit = at.literals.find(([s, e]) => e >= MAX_LINE - 2 && s < MAX_LINE - 4);
      if (!lit) break;
      const [s, e] = lit;
      const q = rest[s];
      let cut = Math.min(e, MAX_LINE - 3);
      // not between the two quotes of an escaped quote
      const quotesBefore = (n) => {
        let k = 0;
        while (n - 1 - k > s && rest[n - 1 - k] === q) k++;
        return k;
      };
      while (cut > s + 1 && quotesBefore(cut) % 2 === 1) cut--;
      if (cut <= s + 1) break;
      out.push(`${rest.slice(0, cut)}${q} &`);
      rest = `${cont}${q}${rest.slice(cut)}`;
    }
    out.push(rest);
    if (rest.length > MAX_LINE) failed = true;
  }
  const wrapped = out.join("\n");
  return { text: wrapped, failed: failed ? longLines(wrapped) : [] };
}
