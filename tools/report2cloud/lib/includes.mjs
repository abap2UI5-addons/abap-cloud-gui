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
// `INCLUDE x IF FOUND.` without a file is dropped, as the compiler drops it;
// a plain INCLUDE without a file stays in the source and the converter
// refuses it, naming the file it looked for.
import { existsSync, readFileSync } from "node:fs";
import { basename, join } from "node:path";

// a whole-line INCLUDE statement - not INCLUDE TYPE / INCLUDE STRUCTURE,
// which carry a second word before the name
const INCLUDE = /^(\s*)INCLUDE\s+([\w/]+)(\s+IF\s+FOUND)?\s*\.\s*(".*)?$/i;

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
    lines.forEach((line, i) => {
      const m = INCLUDE.exec(line);
      if (m) {
        const name = m[2];
        const upper = name.toUpperCase();
        const found = stack.includes(upper) ? undefined : read?.(name);
        if (found !== undefined) {
          included.push(upper);
          out.push(`${m[1]}" INCLUDE ${upper} - inlined by report2cloud from ${includeFileName(name)}`);
          map.push({ file: from, row: i + 1 });
          walk(found, includeFileName(name), [...stack, upper]);
          out.push(`${m[1]}" end of INCLUDE ${upper}`);
          map.push({ file: from, row: i + 1 });
          return;
        }
        if (m[3]) {
          out.push(`${m[1]}" INCLUDE ${upper} IF FOUND - no such include, dropped by report2cloud`);
          map.push({ file: from, row: i + 1 });
          return;
        }
        missing.push(upper);
      }
      out.push(line);
      map.push({ file: from, row: i + 1 });
    });
  };
  walk(source, basename(file), []);
  return {
    source: `${out.join("\n")}\n`,
    origin: (row) => map[row - 1] ?? { file: basename(file), row },
    included,
    missing,
  };
}

/** a `read( )` over folders of abapGit files, the first that has the include wins */
export function includesFrom(dirs) {
  return (name) => {
    for (const dir of dirs) {
      const path = join(dir, includeFileName(name));
      if (existsSync(path)) return readFileSync(path, "utf8");
    }
    return undefined;
  };
}
