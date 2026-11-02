<!-- The report2UI5 pages: part="samples" (site/samples.md) - the samples of
     the converter's corpus; part="playground" (site/playground.md) - import
     from GitHub, your own report, a whole package. The behavior
     is site/playground.mjs, bundled by scripts/build-site.mjs into
     public/r2u/playground.js: loaded once the component is mounted, and its
     listeners taken down when it is left. The ids are what the script finds
     its elements by. -->
<script setup lang="ts">
import { onBeforeUnmount, onMounted } from "vue";
import { useRouter, withBase } from "vitepress";

defineProps<{ part: "samples" | "playground" }>();
const router = useRouter();

let unmount: (() => void) | undefined;
let left = false;

onMounted(async () => {
  try {
    const url = withBase("/r2u/playground.js");
    const module = await import(/* @vite-ignore */ url);
    if (left) return;
    unmount = await module.mount({ go: (path: string) => router.go(withBase(path)) });
    if (left) unmount?.();
  } catch (e) {
    const status = document.getElementById("status") ?? document.getElementById("s-status");
    if (status) {
      status.className = "status bad";
      status.textContent = `The converter could not be loaded: ${(e as Error)?.message ?? e}`;
    }
  }
});

onBeforeUnmount(() => {
  left = true;
  unmount?.();
});
</script>

<template>
  <div v-if="part === 'samples'" class="r2u">
    <header>
      <h1>Samples</h1>
      <p class="lead">Classic reports of the converter's corpus, converted by report2UI5 here in the page - the
        report and its class side by side, the class running below them as an abap2UI5 app. The converter and the
        abap2UI5 runtime run in your browser, nothing is sent anywhere. To convert a report of your own, go to the
        <a :href="withBase('/playground')">playground</a>.</p>
    </header>

    <section id="samples" class="first">
      <div id="s-status" class="status" role="status"></div>

      <div class="toolbar">
        <label>Sample
          <select id="s-example"></select>
        </label>
        <button id="s-prev" class="button" type="button" aria-label="Previous sample">&larr;</button>
        <button id="s-next" class="button" type="button" aria-label="Next sample">&rarr;</button>
        <button id="s-try" class="button" type="button">Edit it in the playground</button>
      </div>

      <div class="three">
        <div class="pane">
          <div class="pane-head"><span><span class="step-no">1</span> The original report <span id="s-name" class="muted"></span></span></div>
          <pre id="s-source" class="output" tabindex="0"></pre>
        </div>
        <div class="pane">
          <div class="pane-head">
            <span><span class="step-no">2</span> Converted by report2UI5</span>
            <span class="head-actions">
              <button id="s-copy" class="link" type="button">Copy</button>
              <button id="s-download" class="link" type="button">Download</button>
              <button id="s-zip" class="link" type="button" title="The files as the zip abapGit imports offline">abapGit zip</button>
            </span>
          </div>
          <div id="s-tabs" class="tabs" role="tablist"></div>
          <pre id="s-output" class="output" tabindex="0"></pre>
        </div>
        <div class="pane">
          <div class="pane-head"><span><span class="step-no">3</span> Preview - abap2UI5 in your browser</span>
            <span><a id="s-open" class="link" href="https://abap2ui5.github.io/playground/" target="_blank" rel="noopener" hidden>Open in the playground ↗</a>
            <button id="s-restart" class="link" type="button">Start again</button></span>
          </div>
          <div class="app">
            <iframe id="s-app" title="The converted sample, running" src="about:blank"></iframe>
            <div id="s-cover" class="app-cover">Starting...</div>
          </div>
        </div>
      </div>

      <div class="info">
        <div class="card info-card wide-card"><h3>What happened</h3><ol id="s-steps" class="steps"></ol></div>
        <div class="card info-card"><h3>Refused <span id="s-n-refused" class="badge"></span></h3><div id="s-refused" class="muted">Nothing.</div></div>
        <div class="card info-card"><h3>To do <span id="s-n-todo" class="badge"></span></h3><div id="s-todo" class="muted">Nothing.</div></div>
        <div class="card info-card wide-card"><details><summary><h3>Mapped - classic to abap-cloud-gui <span id="s-n-mapped" class="badge"></span></h3></summary><div id="s-mapped" class="muted">Nothing yet.</div></details></div>
      </div>
    </section>

  </div>

  <div v-else class="r2u">
    <header>
      <h1>Playground</h1>
      <p class="lead">Convert a classic ABAP report into a report class of abap-cloud-gui and run it as an abap2UI5
        app. Start from your own source, a GitHub link or the abapGit zip of a package. The converter and the abap2UI5
        runtime run in your browser; an import reads straight from GitHub, nothing is sent anywhere else.
        Ready-made conversions are under <a :href="withBase('/samples')">Samples</a>.</p>
    </header>

    <section id="playground" class="first">
      <h2><span class="step-no">1</span> Start from</h2>
      <div class="switch" role="tablist" data-tabs>
        <button type="button" role="tab" data-tab="src-own" aria-selected="true">Your own source</button>
        <button type="button" role="tab" data-tab="src-gh" aria-selected="false">GitHub link</button>
        <button type="button" role="tab" data-tab="src-zip" aria-selected="false">abapGit zip</button>
      </div>

      <div id="src-own" role="tabpanel">
        <p class="muted">Paste or type a classic report. It is converted as you type and kept in this browser for your
          next visit. Includes and the DDIC of your system are not there; the flight tables SCARR, SPFLI and SFLIGHT
          are, with rows to list.</p>
        <div class="toolbar">
          <label>Class name
            <input id="classname" placeholder="zcl_ + the report name" spellcheck="false">
          </label>
          <button id="convert" class="button" type="button">Convert</button>
          <button id="clear" class="link" type="button">Clear</button>
        </div>
        <div class="editor">
          <pre id="source-hl" class="editor-hl" aria-hidden="true"></pre>
          <textarea id="source" wrap="off" spellcheck="false" aria-label="ABAP report source"
            placeholder="Paste a classic report here - REPORT zmy_report. PARAMETERS ... START-OF-SELECTION. WRITE ...&#10;&#10;It is converted as you type (Ctrl+Enter converts at once)."></textarea>
        </div>
        <details id="texts" class="texts">
          <summary>Text pool <span class="muted">.prog.xml, optional - the selection texts, text symbols and screens</span></summary>
          <textarea id="textpool" wrap="off" spellcheck="false" aria-label="abapGit .prog.xml of the report"
            placeholder="Paste the .prog.xml abapGit wrote for the report - its TPOOL gives the fields their labels, its DYNPROS the screens"></textarea>
        </details>
      </div>

      <div id="src-gh" role="tabpanel" hidden>
        <p class="muted">A link to a <code>.prog.abap</code> of a public repository opens it as your own source, with
          the <code>.prog.xml</code> beside it as its text pool. A link to a repository or a folder converts every
          report in it - with their includes and text pools - and lists them below.</p>
        <div class="toolbar">
          <label class="grow">GitHub link
            <input id="gh-url" type="url" spellcheck="false"
              placeholder="https://github.com/owner/repo/blob/main/src/zreport.prog.abap - or a repository, or …/tree/main/src">
          </label>
          <button id="gh-import" class="button primary" type="button">Import</button>
        </div>
        <p class="muted small">For example:
          <a href="#" data-gh="https://github.com/abap2UI5-addons/abap-cloud-gui/blob/main/tools/report2ui5/test/corpus/zr2c_02_flights.prog.abap">one report</a> ·
          <a href="#" data-gh="https://github.com/abap2UI5-addons/abap-cloud-gui/tree/main/tools/report2ui5/test/corpus">the converter's corpus, as a package</a></p>
        <div id="gh-status" class="status" role="status"></div>
      </div>

      <div id="src-zip" role="tabpanel" hidden>
        <p class="muted">The case a migration really is: not one report, a package of them. Drop the abapGit zip of
          the package (or its .prog.abap and .prog.xml files) - every report is converted with its includes and its
          text pool, in this browser, nothing is uploaded anywhere.</p>
        <div class="toolbar">
          <label class="drop" id="pkg-drop">
            <span id="pkg-drop-text">Drop the zip or the files here, or click to choose</span>
            <input id="pkg-files" type="file" multiple accept=".zip,.abap,.xml" hidden>
          </label>
        </div>
      </div>

      <div id="pkg-result" class="card pkg" hidden>
        <div class="pane-head">
          <span id="pkg-summary"></span>
          <span class="head-actions">
            <button id="pkg-zip" class="link" type="button" disabled title="Every class and its migration report, with summary.md, as the zip abapGit imports offline">abapGit zip of all</button>
            <button id="pkg-clear" class="link" type="button">Clear</button>
          </span>
        </div>
        <p class="muted small">Open a report to convert it on its own, see its class and run it.</p>
        <div class="table-wrap">
          <table id="pkg-table" class="table">
            <thead><tr><th>#</th><th>Report</th><th>Class</th><th>Result</th><th>To do</th><th></th></tr></thead>
            <tbody></tbody>
          </table>
        </div>
      </div>
    </section>

    <section id="converted">
      <div class="pane-head">
        <h2><span class="step-no">2</span> The class report2UI5 writes</h2>
        <span class="head-actions">
          <button id="copy" class="link" type="button">Copy</button>
          <button id="download" class="link" type="button">Download</button>
          <button id="download-all" class="link" type="button" title="The files as the zip abapGit imports offline">abapGit zip</button>
        </span>
      </div>
      <div id="status" class="status" role="status"></div>
      <div id="tabs" class="tabs" role="tablist"></div>
      <pre id="output" class="output" tabindex="0"><span class="muted">The generated class appears here.</span></pre>
    </section>

    <section id="preview">
      <div class="pane-head">
        <h2><span class="step-no">3</span> Preview - abap2UI5 in your browser</h2>
        <span class="head-actions">
          <span id="app-state" class="muted"></span>
          <a id="own-app-open" class="link" href="https://abap2ui5.github.io/playground/" target="_blank" rel="noopener" hidden>Open in the playground ↗</a>
          <button id="run" class="button primary" type="button">Run</button>
        </span>
      </div>
      <div class="app">
        <iframe id="own-app" title="The converted report, running" src="about:blank"></iframe>
        <div id="own-app-cover" class="app-cover">Run starts the class as an abap2UI5 app - the selection screen, Execute (F8), the list.</div>
      </div>
    </section>

    <section id="details">
      <h2><span class="step-no">4</span> The conversion in detail</h2>
      <div class="switch" role="tablist" data-tabs>
        <button type="button" role="tab" data-tab="det-steps" aria-selected="true">What happened</button>
        <button type="button" role="tab" data-tab="det-refused" aria-selected="false">Refused <span id="n-refused" class="badge"></span></button>
        <button type="button" role="tab" data-tab="det-todo" aria-selected="false">To do <span id="n-todo" class="badge"></span></button>
        <button type="button" role="tab" data-tab="det-mapped" aria-selected="false">Mapped <span id="n-mapped" class="badge"></span></button>
        <button type="button" role="tab" data-tab="det-migration" aria-selected="false">Migration report</button>
        <button id="det-tab-pkg" type="button" role="tab" data-tab="det-pkg" aria-selected="false" hidden>Package summary</button>
      </div>
      <div class="card detail">
        <div id="det-steps" role="tabpanel"><ol id="steps" class="steps"></ol></div>
        <div id="det-refused" role="tabpanel" hidden><div id="refused" class="muted">Nothing.</div></div>
        <div id="det-todo" role="tabpanel" hidden><div id="todo" class="muted">Nothing.</div></div>
        <div id="det-mapped" role="tabpanel" hidden><p class="muted small">Classic statement and its counterpart in abap-cloud-gui, by line.</p><div id="mapped" class="muted">Nothing yet.</div></div>
        <div id="det-migration" role="tabpanel" hidden><p class="muted small">The .migration.md, as the CLI writes it.</p><pre id="migration" class="code"></pre></div>
        <div id="det-pkg" role="tabpanel" hidden><p class="muted small">summary.md of the package - the refusals ranked.</p><pre id="pkg-overview" class="code"></pre></div>
      </div>
    </section>
  </div>
</template>
