// The files of a class as abapGit writes them - what a pull compares against
// (abap2UI5 skill abap-check, section 1): the .xml starts with the UTF-8 BOM,
// the .abap does not; LF only, no tabs, no trailing blanks, exactly one
// newline at the end; at most 255 characters per line, or the import dies
// and leaves an empty class behind. The sidecar escapes the apostrophe as
// &apos;, as the ABAP iXML renderer does.

export const MAX_LINE = 255;

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
