// The files the abap2UI5 playground needs beside a converted class to run it:
// the report runtime of src/01, the demo tables SCARR, SPFLI and SFLIGHT and
// the structure SNODETEXT (tools/report2cloud/test/ddic; their rows come from the page, see
// site/playground.mjs). scripts/build-site.mjs writes them to runtime.json.
//
// The playground takes classes, interfaces and database tables - not data
// elements. So a data element of the runtime is written into the table that
// uses it as the built-in type it stands for, and a source naming it names
// that table's field instead (`CONV z2ui5_cgui_var_owner( )` becomes
// `CONV z2ui5_cgui_var-owner( )`, the same type). Anything else the
// playground could not take fails here, by name, rather than on the page.
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

const read = (file) => readFileSync(file, "utf8").replace(/^﻿/, "");
// SNODETEXT is a structure: the node of a tree list (zr2c_46_treelist)
const DEMO_TABLES = ["scarr", "spfli", "sflight", "snodetext"];

/** a data element as built-in DDIC fields, from its abapGit XML */
function builtIn(xml, name) {
  const type = /<DATATYPE>(\w+)<\/DATATYPE>/.exec(xml)?.[1];
  const leng = /<LENG>(\d+)<\/LENG>/.exec(xml)?.[1];
  if (type) return `<DATATYPE>${type}</DATATYPE>${leng ? `\n     <LENG>${leng}</LENG>` : ""}`;
  const domain = /<DOMNAME>(\w+)<\/DOMNAME>/.exec(xml)?.[1];
  const char = /^CHAR(\d+)$/.exec(domain ?? "");
  if (char) return `<DATATYPE>CHAR</DATATYPE>\n     <LENG>${char[1].padStart(6, "0")}</LENG>`;
  if (domain === "TZNTSTMPL") return "<ROLLNAME>TIMESTAMPL</ROLLNAME>";
  throw new Error(`playground runtime: the data element ${name} has no type the playground knows (${domain ?? "no domain"})`);
}

export function runtimeFiles(root) {
  const dir = join(root, "src", "01");
  const names = readdirSync(dir).sort();
  const dtels = new Map();
  for (const f of names.filter((n) => n.endsWith(".dtel.xml"))) {
    const name = f.replace(/\.dtel\.xml$/, "").toUpperCase();
    dtels.set(name, builtIn(read(join(dir, f)), name));
  }
  const fieldOf = new Map();
  const files = [];
  for (const f of names.filter((n) => n.endsWith(".tabl.xml"))) {
    const table = f.replace(/\.tabl\.xml$/, "").toLowerCase();
    const xml = read(join(dir, f)).replace(/<DD03P>[\s\S]*?<\/DD03P>/g, (field) => {
      const m = /<ROLLNAME>(\w+)<\/ROLLNAME>/.exec(field);
      if (!m || !dtels.has(m[1])) return field;
      fieldOf.set(m[1], `${table}-${/<FIELDNAME>(\w+)<\/FIELDNAME>/.exec(field)[1].toLowerCase()}`);
      const typed = field.replace(m[0], dtels.get(m[1]));
      return typed.includes("<ROLLNAME>") ? typed : typed.replace(/\s*<COMPTYPE>E<\/COMPTYPE>/, "");
    });
    files.push({ name: `${table}.tabl.xml`, source: xml });
  }
  for (const name of dtels.keys()) {
    if (!fieldOf.has(name)) throw new Error(`playground runtime: the data element ${name} is used by no table of src/01`);
  }
  const named = new RegExp(`\\b(${[...dtels.keys()].join("|")})\\b(?!-)`, "gi");
  const sources = [];
  for (const f of names) {
    if (/\.(dtel|tabl|clas|intf|devc)\.xml$/.test(f) || f.endsWith(".clas.testclasses.abap")) continue;
    if (!/^[a-z0-9_]+\.(clas|intf)\.abap$/.test(f)) throw new Error(`playground runtime: ${f} is no file the playground takes`);
    sources.push({ name: f, source: read(join(dir, f)).replace(named, (m) => fieldOf.get(m.toUpperCase())) });
  }
  const demo = DEMO_TABLES.map((t) => ({ name: `${t}.tabl.xml`, source: read(join(root, "tools", "report2cloud", "test", "ddic", `${t}.tabl.xml`)) }));
  return [...sources, ...files, ...demo];
}
