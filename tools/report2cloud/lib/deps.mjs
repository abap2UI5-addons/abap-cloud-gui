// The dependencies of a report, from the abapGit files of its repository.
//
// A report calls the classes of its repository and reads its tables:
// DATA(lo_log) = zcl_app_factory=>create_logger( ) in INITIALIZATION, read
// in START-OF-SELECTION, is an attribute of the converted class only when
// its type can be told - and abaplint tells it only when zcl_app_factory is
// in the registry. The dependencies go into the registry the report is
// parsed in, next to it; they are context, never converted.
//
// Only what the report names goes in, and what that names in turn: a
// repository of hundreds of classes stays cheap.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { basename, join } from "node:path";

// the abapGit files that type something: classes and interfaces, the DDIC
const KINDS = /^(.+?)\.(clas|intf|tabl|dtel|doma|ttyp|view|ddls|enho)(\..+)?\.(abap|xml|asddls)$/;

/** an index of a repository: object name -> its files { name, text } */
export function dependencyIndex(dirs) {
  const index = new Map();
  const walk = (dir) => {
    let entries;
    try {
      entries = readdirSync(dir);
    } catch {
      return;
    }
    for (const e of entries) {
      if (e === ".git" || e === "node_modules") continue;
      const p = join(dir, e);
      let st;
      try {
        st = statSync(p);
      } catch {
        continue;
      }
      if (st.isDirectory()) walk(p);
      else {
        const m = KINDS.exec(e.toLowerCase());
        // a test class is no dependency
        if (!m || /testclasses/.test(m[3] ?? "")) continue;
        const name = m[1].replace(/#/g, "/");
        if (!index.has(name)) index.set(name, []);
        index.get(name).push({ path: p, name: basename(p) });
      }
    }
  };
  for (const d of dirs) walk(d);
  return index;
}

/** the files of the objects source names, and of what they name - at most
 *  limit objects; [{ name, text }] for convert( { deps } ) */
export function dependenciesOf(source, index, limit = 150) {
  const seen = new Set();
  const files = [];
  const queue = [source];
  while (queue.length && seen.size < limit) {
    const text = queue.shift().toLowerCase();
    for (const m of text.matchAll(/[a-z_/][\w/]*/g)) {
      const name = m[0];
      if (seen.has(name) || !index.has(name)) continue;
      seen.add(name);
      for (const f of index.get(name)) {
        const t = readFileSync(f.path, "utf8");
        files.push({ name: f.name, text: t });
        queue.push(t);
      }
      if (seen.size >= limit) break;
    }
  }
  return files;
}
