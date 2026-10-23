// An app of the runtime test, operated through the abap2UI5 MCP server's app
// client (lib/appclient.mjs): the JSON protocol the UI5 frontend speaks, and
// the agent snapshot v1 as the answer (lib/snapshot.mjs) - fields, actions,
// tables (a value help's TableSelectDialog too), messages (the report's
// message popover too). The snapshot's `texts` are distinct strings for context,
// so the order of a WRITE list is read besides: the client's transport is
// wrapped, every response is applied to a state of our own with the same
// applyResponse the client uses, and lines() reads the list control
// (z2ui5_cl_cgui_list=>render) out of the main view - one string per line.
import { join } from "node:path";
import { pathToFileURL } from "node:url";

export async function createDriver({ mcp, url }) {
  const lib = (f) => import(pathToFileURL(join(mcp, "lib", f)).href);
  const { createAppClient, fetchTransport } = await lib("appclient.mjs");
  const { applyResponse, emptyState, getAt } = await lib("snapshot.mjs");
  const { parseViewXml, parseBinding } = await lib("viewxml.mjs");

  let state = emptyState();
  const http = fetchTransport({ baseUrl: url });
  const client = createAppClient({
    baseUrl: url,
    transport: async (req) => {
      const res = await http(req);
      if (res.status >= 200 && res.status < 300) {
        try {
          state = applyResponse(state, JSON.parse(String(res.body)));
        } catch {
          /* the client reports a response that is no JSON */
        }
      }
      return res;
    },
  });

  const resolve = (value) => {
    const b = parseBinding(value);
    if (!b) return value;
    const path = b.path || (b.parts && b.parts[0] && b.parts[0].path);
    return path ? String(getAt(state.models.MAIN?.data || {}, path) ?? "") : value;
  };

  /** the WRITE list of the main view, line by line: the texts of a line
   *  joined by a blank, `[x]`/`[ ]` a checkbox, `<icon>` an icon, `---` an
   *  ULINE, `` a SKIP, `# title` a NEW-PAGE */
  function lines() {
    const xml = state.slots.MAIN?.xml;
    if (!xml) return [];
    const find = (node) => {
      if (node.local === "VBox" && String(node.attrs.class || "").includes("sapUiSmallMargin")) return node;
      for (const c of node.children) {
        const hit = find(c);
        if (hit) return hit;
      }
      return null;
    };
    const list = find(parseViewXml(xml));
    if (!list) return [];
    const item = (n) => {
      if (n.local === "CheckBox") return resolve(n.attrs.selected) === "true" || resolve(n.attrs.selected) === true ? "[x]" : "[ ]";
      if (n.local === "Icon") return `<${n.attrs.src}>`;
      return resolve(n.attrs.text ?? "");
    };
    // a line with a position: its items stand in boxes of their width, the
    // gaps are empty boxes - the texts are the leaves
    const leaves = (n) => (n.local === "HBox" ? n.children.flatMap(leaves) : [n]);
    return list.children.map((n) => {
      if (n.local === "Toolbar") return "---";
      if (n.local === "Title") return `# ${resolve(n.attrs.text)}`.trim();
      if (n.local === "HBox" && n.attrs.height) return "";
      return n.children.flatMap(leaves).map(item).join(" ").replace(/\s+$/, "");
    });
  }

  return {
    client,
    lines,
    /** the frontend state the responses built: slots (view XML) and models */
    state: () => state,
    start: (app, opts) => client.start(app, opts),
    act: (session, opts) => client.act(session, opts),
    describe: (session) => client.describe(session),
  };
}
