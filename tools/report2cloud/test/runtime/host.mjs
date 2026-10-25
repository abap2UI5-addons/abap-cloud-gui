// The backend child of the report2cloud runtime test (backend.mjs):
//
//   node host.mjs <runtime dir> <apps dir>     PORT from the environment
//
// Resolves @abap2ui5/node-runtime from the runtime directory, boots the
// build (<apps dir>/init.mjs: the runtime, the tables and their seed rows, the
// classes) and serves it on loopback - mcp-server's lib/npm-host.mjs, for a
// build that is not the server's own apps/.
//
// A roundtrip is a session of its own on a system: the static attributes of
// a class start initial. This process keeps them from one request to the
// next - with FRESH_STATICS (a regular expression of the names the runtime
// gives classes, CLAS-<pool>-<local class>) the CLASS-DATA of those classes
// is cleared before every request, as a system would have it.
import http from "node:http";
import { createRequire } from "node:module";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const [dir, apps] = process.argv.slice(2).map((p) => resolve(p));
const port = Number(process.env.PORT || 3000);
try {
  const req = createRequire(join(dir, "package.json"));
  const runtime = await import(pathToFileURL(req.resolve("@abap2ui5/node-runtime")).href);
  const boot = await import(pathToFileURL(join(apps, "init.mjs")).href);
  if (process.env.FRESH_STATICS) {
    const fresh = new RegExp(process.env.FRESH_STATICS);
    const emit = http.Server.prototype.emit;
    http.Server.prototype.emit = function (event, ...rest) {
      if (event === "request") {
        for (const [name, cls] of Object.entries(globalThis.abap?.Classes ?? {})) {
          if (!fresh.test(name)) continue;
          for (const value of Object.values(cls)) if (typeof value?.clear === "function") value.clear();
        }
      }
      return emit.call(this, event, ...rest);
    };
  }
  await runtime.serve({ port, host: "127.0.0.1" });
  console.log(`report2cloud runtime host: ${boot.devModules.length} module(s)`);
  console.log(`Listening on ${port}`);
} catch (e) {
  console.error(`report2cloud runtime host: ${(e && e.stack) || e}`);
  process.exit(1);
}
