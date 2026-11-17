// Runs one transpiled program of a build (backend.mjs, `programs`) in a
// process of its own and prints what it wrote: the classic report itself,
// as the semantic test compares its list with the one of its class.
//
//   node program.mjs <apps dir> <program module>
//
// The runtime writes the list to stdout as the program runs; it is caught
// here, and stdout is then one JSON object: { ok, list } or { ok: false,
// error, list }.
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const [apps, program] = process.argv.slice(2);
const write = process.stdout.write.bind(process.stdout);
let list = "";
let result;
await import(pathToFileURL(join(apps, "init.mjs")).href);
process.stdout.write = (chunk) => {
  list += String(chunk);
  return true;
};
try {
  // transpiler 2.14 on runs a program on import only when it is the script
  // node was started with - otherwise it exports the run as $main
  const mod = await import(pathToFileURL(join(apps, program)).href);
  if (typeof mod.$main === "function") await mod.$main();
  list += globalThis.abap.console.get?.() ?? "";
  result = { ok: true, list };
} catch (e) {
  result = { ok: false, error: String(e?.stack || e), list };
}
process.stdout.write = write;
write(JSON.stringify(result));
process.exit(0);
