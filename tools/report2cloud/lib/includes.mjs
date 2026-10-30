// INCLUDE statements of a report, inlined from the abapGit files beside it.
//
// A grown report is a main program and its includes - the TOP include with
// the globals and the selection screen, F01 with the FORMs - and abapGit
// serializes each include as a PROG of its own: <include>.prog.abap, lower
// case, a namespace slash as #. The converter reads one source, so the
// includes are inlined here, textually and before the parse: the parser then
// sees the report the way the ABAP compiler sees it, macros of a TOP include
// included. Every line of the result remembers where it came from
// (`origin( )`), so a refusal or a TODO still names the include and its own
// line, not a line of a file nobody has.
//
// The chained form `INCLUDE: a, b.` is inlined include by include.
// `INCLUDE x IF FOUND.` without a file is dropped, as the compiler drops it;
// a plain INCLUDE without a file stays in the source and the converter
// refuses it, naming the file it looked for.
// no node:fs here - the site bundles this module for the browser; the
// reader over folders is includes-fs.mjs
const basename = (path) => String(path).split(/[\\/]/).pop();

// a whole-line INCLUDE statement - not INCLUDE TYPE / INCLUDE STRUCTURE,
// which carry a second word before the name
const INCLUDE = /^(\s*)INCLUDE\s+([\w/]+)(\s+IF\s+FOUND)?\s*\.\s*(".*)?$/i;

// the chained form, `INCLUDE: a, b, c.`, over one line or several
const CHAIN = /^(\s*)INCLUDE\s*:/i;
const NAME = /^([\w/]+)(\s+IF\s+FOUND)?$/i;

/** The includes of a chained INCLUDE starting at line `start`, each with the
 *  (1-based) row it is named on, and the index of the line with the period -
 *  or undefined when it is not a chain of include names (then it is left as
 *  it is, and the converter says what it is). */
function includeChain(lines, start) {
  const names = [];
  for (let i = start; i < lines.length; i++) {
    if (/^\*/.test(lines[i])) continue;
    let code = lines[i].replace(/".*$/, "");
    if (i === start) code = code.replace(CHAIN, "");
    const end = /\.\s*$/.test(code);
    for (const piece of code.replace(/\.\s*$/, "").split(",")) {
      const t = piece.trim();
      if (!t) continue;
      const m = NAME.exec(t);
      if (!m) return undefined;
      names.push({ name: m[1], ifFound: Boolean(m[2]), row: i + 1 });
    }
    if (end) return names.length ? { names, last: i } : undefined;
  }
  return undefined;
}

/** abapGit's file name of an include: lower case, a slash as # */
export const includeFileName = (name) => `${name.toLowerCase().replace(/\//g, "#")}.prog.abap`;

/**
 * `source` with its INCLUDE statements replaced by the includes' text,
 * recursively (a cycle is left alone). `read(name)` answers an include's
 * source, or undefined when there is none. Answers the combined source,
 * `origin(row)` -> { file, row } for every row of it, the names included
 * and the names missing.
 */
export function inlineIncludes(source, { file = "zreport.prog.abap", read } = {}) {
  const map = [];
  const out = [];
  const included = [];
  const missing = [];
  const walk = (text, from, stack) => {
    const lines = text.replace(/\r\n?/g, "\n").split("\n");
    // the trailing newline of a file is not a line of its own
    if (lines.length > 1 && lines[lines.length - 1] === "") lines.pop();
    const one = (indent, name, ifFound, row, line) => {
      const upper = name.toUpperCase();
      const found = stack.includes(upper) ? undefined : read?.(name);
      if (found !== undefined) {
        included.push(upper);
        out.push(`${indent}" INCLUDE ${upper} - inlined by report2cloud from ${includeFileName(name)}`);
        map.push({ file: from, row });
        walk(found, includeFileName(name), [...stack, upper]);
        out.push(`${indent}" end of INCLUDE ${upper}`);
        map.push({ file: from, row });
      } else if (ifFound) {
        out.push(`${indent}" INCLUDE ${upper} IF FOUND - no such include, dropped by report2cloud`);
        map.push({ file: from, row });
      } else {
        missing.push(upper);
        out.push(line);
        map.push({ file: from, row });
      }
    };
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const m = INCLUDE.exec(line);
      if (m) {
        one(m[1], m[2], Boolean(m[3]), i + 1, line);
        continue;
      }
      const chain = CHAIN.exec(line);
      if (chain) {
        const parts = includeChain(lines, i);
        if (parts) {
          // each include of the chain on its own, at the line that names it;
          // one without a file a single INCLUDE statement the converter refuses
          for (const p of parts.names) one(chain[1], p.name, p.ifFound, p.row, `${chain[1]}INCLUDE ${p.name}${p.ifFound ? " IF FOUND" : ""}.`);
          i = parts.last;
          continue;
        }
      }
      out.push(line);
      map.push({ file: from, row: i + 1 });
    }
  };
  walk(source, basename(file), []);
  return {
    source: `${out.join("\n")}\n`,
    origin: (row) => map[row - 1] ?? { file: basename(file), row },
    included,
    missing,
  };
}
