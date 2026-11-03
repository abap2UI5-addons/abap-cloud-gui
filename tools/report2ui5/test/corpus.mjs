// The test corpus: classic reports in corpus/, each with an optional
// .prog.xml text pool, and the includes of a report beside it the way
// abapGit writes them (a .prog.abap without a REPORT statement, inlined
// before the conversion - lib/includes.mjs). A report zr2c_NN_name converts
// into the class z2ui5_cl_cgui_r2c_NN - a name the repository's
// object_naming rule accepts, so the gate test lints it with the
// repository's config as is.
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { convert } from "../lib/convert.mjs";
import { inlineIncludes } from "../lib/includes.mjs";
import { includesFrom } from "../lib/includes-fs.mjs";
import { parseTextpool } from "../lib/textpool.mjs";
import { migrationReport } from "../lib/report.mjs";

export const HERE = dirname(fileURLToPath(import.meta.url));
export const CORPUS = join(HERE, "corpus");
export const SNAPSHOTS = join(HERE, "snapshots");
export const DDIC = join(HERE, "ddic");
/** src/03 - the corpus classes that run on ABAP Cloud too, as converted: the
 *  test set to pull onto a system with abapGit */
export const TEST_SET = join(HERE, "..", "..", "..", "src", "03");

const isReport = (source) => /^\s*(REPORT|PROGRAM)\b/im.test(source);

export function corpus() {
  return readdirSync(CORPUS).filter((f) => f.endsWith(".prog.abap")).sort().flatMap((file) => {
    const name = file.replace(/\.prog\.abap$/, "");
    const raw = readFileSync(join(CORPUS, file), "utf8");
    if (!isReport(raw)) return [];
    const xml = join(CORPUS, `${name}.prog.xml`);
    const includes = inlineIncludes(raw, { file, read: includesFrom([CORPUS]) });
    return [{
      file,
      name,
      className: `z2ui5_cl_cgui_r2c_${name.slice(5, 7)}`,
      source: includes.source,
      includes,
      texts: existsSync(xml) ? `${name}.prog.xml` : undefined,
      textpool: existsSync(xml) ? parseTextpool(readFileSync(xml, "utf8")) : undefined,
    }];
  });
}

let known;
/** the class of every corpus report, by program name - what a SUBMIT starts */
function classes() {
  known ??= new Map(corpus().map((e) => [e.name, e.className]));
  return known;
}

/** the conversion of a corpus report, and its migration report */
export function convertEntry(entry) {
  const result = convert(entry.source, {
    file: entry.file, className: entry.className, programName: entry.name, textpool: entry.textpool, origin: entry.includes?.origin,
    classFor: (program) => classes().get(program),
  });
  const report = migrationReport(result, { source: entry.file, texts: entry.texts, includes: entry.includes });
  return { result, report };
}

/** the corpus reports whose classes are the test set src/03, by number -
 *  those that read no table and call no API ABAP Cloud lacks, so a pull of
 *  the repository activates everywhere. The converter copies the logic of
 *  a report as it is and does not judge it; the gate test checks that each
 *  of these is clean on ABAP Cloud (abaplint.test.mjs). */
export const CLOUD_READY = new Set([
  "01", "03", "06", "08", "09", "11", "12", "13", "22", "23", "25", "26", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "47", "51", "52", "53",
]);

/** the conversions that belong into the test set src/03 */
export function inTestSet({ result }) {
  return result.ok && CLOUD_READY.has(result.className.slice(-2));
}
