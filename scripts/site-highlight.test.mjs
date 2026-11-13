// The highlighting of the files a conversion shows on the site (site/highlight.mjs).
import { test } from "node:test";
import assert from "node:assert/strict";
import { highlightXml } from "../site/highlight.mjs";

test("XML: the tag and the attribute value each in one span", () => {
  assert.equal(highlightXml(`<a b="c">x</a>`),
    `&lt;<span class="hl-kw">a</span> b=<span class="hl-str">"c"</span>&gt;x&lt;/<span class="hl-kw">a</span>&gt;`);
});
