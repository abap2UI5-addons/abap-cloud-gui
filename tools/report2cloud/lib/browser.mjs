// The converted reports in a real browser - the UI5 frontend of abap2UI5,
// in headless Chromium (Playwright), against the transpiled backend of the
// runtime test (test/runtime/backend.mjs). The JSON protocol of the runtime
// test sees what the backend answers; this sees what the user sees: that UI5
// boots, that the views the report runtime writes render, and that nothing
// raises a page error on the way - a view that does not parse, a binding to
// a control that rejects it, a script error.
//
// UI5 comes from the @openui5 packages (devDependencies) - the requests of
// the page for sdk.openui5.org are answered from them, so it runs offline
// and in CI alike. Those are SOURCES: the ui5loader evals its modules and
// the dev bootstrap writes two inline scripts of its own, which the CSP of
// the page refuses - the page this test loads gets 'unsafe-eval' and the two
// hashes added (a system loads the built UI5 from the CDN and needs neither;
// abap2UI5/samples-controls does the same in its e2e smoke).
//
// An app passes when UI5 boots, more than three controls render, no page
// error is raised (environment noise aside: preload, i18n, themes) and no
// response of the backend is an error; with execute it presses Execute of a
// selection screen and checks the same again.

import { createHash } from "node:crypto";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { extname, join } from "node:path";
import { REPO } from "./gate.mjs";

const UI5 = join(REPO, "node_modules", "@openui5");
// the release of the packages - the CDN has the built themes of it
const UI5_VERSION = (() => {
  try {
    return JSON.parse(readFileSync(join(UI5, "sap.m", "package.json"), "utf8")).version;
  } catch {
    return "1.153.0";
  }
})();

// what a page error of an unbundled UI5 is when it is not the app's
const BENIGN = [
  /library-preload/i, /messagebundle/i, /i18n/i, /themes?\/|library(\.css|-parameters)/i,
  /theming\.Parameters|\.properties/i, /failed to load (javascript )?resource/i,
  /Core\.applyTheme|sap\.ui\.getCore/i, /favicon/i, /deprecat/i, /sap-ui-cachebuster/i,
];
const benign = (text) => BENIGN.some((re) => re.test(text));

// the two inline scripts of the dev bootstrap (sap-ui-core.js of the sources)
const DEV_BOOTSTRAP = ['sap.ui.requireSync("sap/ui/core/Core");', "sap.ui.getCore().boot && sap.ui.getCore().boot();"]
  .map((s) => `'sha256-${createHash("sha256").update(s, "utf8").digest("base64")}'`);

/** the CSP of the page, opened for the sources of UI5 */
export function allowSourceUi5(html) {
  return html.replace(/(script-src\s)([^;"]*)/, (m, head, rest) => {
    const inlineOpen = /'unsafe-inline'/.test(rest) && !/'(?:sha(?:256|384|512)-|nonce-)/.test(rest);
    const add = ["'unsafe-eval'", ...(inlineOpen ? [] : DEV_BOOTSTRAP)].filter((t) => !rest.includes(t));
    return add.length ? `${head}${add.join(" ")} ${rest}` : m;
  });
}

const MIME = { ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".xml": "application/xml", ".properties": "text/plain",
  ".html": "text/html", ".png": "image/png", ".gif": "image/gif", ".svg": "image/svg+xml", ".ttf": "font/ttf", ".woff2": "font/woff2" };

let roots;
/** a file of UI5 by its path below /resources/ - undefined when no package has it */
export function ui5File(pathname) {
  roots ??= existsSync(UI5) ? readdirSync(UI5).map((p) => join(UI5, p, "src")).filter((p) => existsSync(p)) : [];
  const at = pathname.indexOf("/resources/");
  if (at < 0) return undefined;
  const rel = pathname.slice(at + "/resources/".length).replace(/^sap-ui-cachebuster\//, "");
  for (const root of roots) {
    const full = join(root, rel);
    if (full.startsWith(root) && existsSync(full) && statSync(full).isFile()) return { body: readFileSync(full), type: MIME[extname(full)] ?? "application/octet-stream" };
  }
  return undefined;
}

/** a new page on the backend at url: UI5 from the packages, the errors of
 *  the page and of the backend collected */
async function openPage(browser, url, viewport = { width: 1280, height: 900 }, themes = false) {
  const context = await browser.newContext({ viewport, ignoreHTTPSErrors: themes });
  const page = await context.newPage();
  const errors = [];
  page.on("pageerror", (e) => { if (!benign(e.message)) errors.push(`page error: ${e.message.split("\n")[0].slice(0, 200)}`); });
  page.on("response", (r) => {
    if (r.url().startsWith(url) && r.status() >= 400) errors.push(`backend ${r.status()}: ${r.url().slice(url.length, url.length + 80)}`);
  });
  await page.route((u) => u.href.startsWith(url), async (route) => {
    if (route.request().resourceType() !== "document") return route.fallback();
    const response = await route.fetch({ timeout: 120_000 }).catch(() => undefined);
    if (!response) return route.abort().catch(() => {});
    if (!(response.headers()["content-type"] ?? "").includes("text/html")) return route.fulfill({ response });
    return route.fulfill({ response, body: allowSourceUi5(await response.text()) });
  });
  await page.route("**://sdk.openui5.org/**", (route) => {
    const path = new URL(route.request().url()).pathname;
    const hit = ui5File(path);
    if (hit) return route.fulfill({ status: 200, contentType: hit.type, body: hit.body });
    // a theme is built from LESS sources the packages have, not the CSS:
    // it comes from the CDN, of the release of the packages
    const at = path.indexOf("/resources/");
    if (themes && at >= 0 && /\/themes\//.test(path)) {
      return route.continue({ url: `https://sdk.openui5.org/${UI5_VERSION}/resources/${path.slice(at + "/resources/".length)}` }).catch(() => route.abort().catch(() => {}));
    }
    return route.fulfill({ status: 404, body: "" });
  });
  return { context, page, errors };
}

/** UI5 up and more than `min` controls rendered - false after the time */
async function rendered(page, min, timeoutMs) {
  return page.waitForFunction((n) => document.querySelectorAll("[data-sap-ui]").length > n, min, { timeout: timeoutMs }).then(() => true, () => false);
}

/** the text of the error popup of abap2UI5, when one shows */
async function errorPopup(page) {
  return page.evaluate(() => {
    const dialog = [...document.querySelectorAll(".sapMDialog")].find((d) => /error|exception|dump/i.test(d.textContent ?? ""));
    return dialog ? dialog.textContent.replace(/\s+/g, " ").trim().slice(0, 240) : "";
  });
}

/** let the roundtrips of the page settle */
async function settle(page) {
  await page.waitForLoadState("networkidle", { timeout: 10_000 }).catch(() => {});
  await page.waitForTimeout(300);
}

/**
 * Start every app of `classes` on the backend at `url` in Chromium. Resolves
 * [{ cls, ok, booted, executed, errors }]. execute: press Execute when the
 * first screen is a selection screen (a button with the text Execute).
 * after(row): awaited after each app - an error it pushes fails the app.
 * themes: the built themes from the CDN (sdk.openui5.org, the release of
 * the packages) - a layout is judged themed only.
 * viewport: the size of the page ({ width, height }); below 600px wide it is
 * a phone, and a page wider than it fails the app.
 */
export async function browserRun(classes, { url, execute = true, timeoutMs = 60_000, viewport, themes = false, after = async () => {}, onLine = () => {} } = {}) {
  const { chromium } = await import("playwright");
  // the Chromium of this Playwright, else REPORT2CLOUD_CHROMIUM or one
  // installed beside it (a sandbox with a browser of another release)
  const own = chromium.executablePath();
  const executablePath = process.env.REPORT2CLOUD_CHROMIUM
    ?? (existsSync(own) ? undefined : ["/opt/pw-browsers/chromium"].find((p) => existsSync(p)));
  // the themes come from the CDN - through the proxy of the environment, if
  // there is one, and to the backend directly
  const proxy = themes && process.env.HTTPS_PROXY ? { server: process.env.HTTPS_PROXY, bypass: "127.0.0.1,localhost" } : undefined;
  const browser = await chromium.launch({ ...(executablePath ? { executablePath } : {}), ...(proxy ? { proxy } : {}) });
  const out = [];
  try {
    for (const cls of classes) {
      const { context, page, errors } = await openPage(browser, url, viewport, themes);
      let booted = false;
      let executed = false;
      // one app at most twice the time - a page that hangs Playwright itself
      // (a dialog, a renderer that does not come back) fails, not the run
      let timer;
      const guard = new Promise((_, rej) => { timer = setTimeout(() => rej(new Error("the app did not finish within the time")), 2 * timeoutMs); });
      try {
        await Promise.race([guard, (async () => {
          await page.goto(`${url.replace(/\/$/, "")}/?app_start=${cls}`, { waitUntil: "domcontentloaded", timeout: timeoutMs });
          booted = await rendered(page, 3, timeoutMs);
          if (!booted) errors.push("UI5 did not render the app within the time");
          await settle(page);
          if (booted && execute) {
            const button = page.locator(".sapMBtn").filter({ hasText: /^\s*Execute/ }).first();
            if (await button.count()) {
              await button.click({ timeout: 10_000 });
              await settle(page);
              executed = true;
            }
          }
          // on a phone the screen fits the width - no page that scrolls sideways
          if (themes && !(await page.evaluate(() => /72/.test(getComputedStyle(document.body).fontFamily)))) {
            errors.push("the theme did not load - the layout is that of no theme");
          }
          if (viewport && viewport.width < 600) {
            // UI5 clips what does not fit - a field or button whose right
            // edge lies beyond the screen cannot be reached
            const cut = await page.evaluate(() => [...document.querySelectorAll(".sapMInputBase, .sapMBtn, .sapMCb, .sapMRb, .sapMSlt")]
              .filter((e) => e.offsetParent !== null && e.getBoundingClientRect().width > 0)
              .filter((e) => e.getBoundingClientRect().right > window.innerWidth + 1)
              .map((e) => e.id || e.className.split(" ")[0]));
            if (cut.length) errors.push(`beyond the right edge of the phone: ${cut.slice(0, 4).join(", ")}`);
            // a short text squeezed until it breaks letter by letter ("t" / "o")
            const squeezed = await page.evaluate(() => [...document.querySelectorAll(".sapMText, .sapMLabel")]
              .filter((e) => e.offsetParent !== null && e.textContent.trim().length > 0 && e.textContent.trim().length <= 12 && !/\s/.test(e.textContent.trim()))
              .filter((e) => e.getBoundingClientRect().height > 1.6 * (parseFloat(getComputedStyle(e).lineHeight) || 18))
              .map((e) => e.textContent.trim()));
            if (squeezed.length) errors.push(`squeezed onto more than one line on the phone: ${squeezed.slice(0, 4).join(", ")}`);
          }
          const popup = await errorPopup(page);
          if (popup) errors.push(`error popup: ${popup}`);
        })()]);
      } catch (e) {
        errors.push(String(e?.message ?? e).split("\n")[0].slice(0, 200));
      } finally {
        clearTimeout(timer);
      }
      await Promise.race([context.close(), new Promise((r) => setTimeout(r, 10_000))]).catch(() => {});
      const row = { cls, ok: false, booted, executed, errors };
      // the caller's look at the backend after the app (that it still runs)
      await after(row);
      row.ok = booted && errors.length === 0;
      onLine(`${row.ok ? "pass" : "FAIL"}  ${cls}${executed ? "  (executed)" : ""}${row.ok ? "" : `  ${errors[0]}`}`);
      out.push(row);
    }
  } finally {
    await browser.close();
  }
  return out;
}
