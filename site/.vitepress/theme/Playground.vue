<!-- The report2UI5 playground (site/playground.md): the markup of its three
     sections - the samples, your own report, a whole package. The behavior
     is site/playground.mjs, bundled by scripts/build-site.mjs into
     public/r2u/playground.js: loaded once the component is mounted, and its
     listeners taken down when it is left. The ids are what the script finds
     its elements by. -->
<script setup lang="ts">
import { onBeforeUnmount, onMounted } from "vue";
import { withBase } from "vitepress";

let unmount: (() => void) | undefined;
let left = false;

onMounted(async () => {
  try {
    const url = withBase("/r2u/playground.js");
    const module = await import(/* @vite-ignore */ url);
    if (left) return;
    unmount = await module.mount();
    if (left) unmount?.();
  } catch (e) {
    const status = document.getElementById("status");
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
  <div class="r2u">
    <header>
      <h1>report2UI5 playground</h1>
      <p class="lead">Convert a classic ABAP report into a report class of abap-cloud-gui and run it as an
        abap2UI5 app - the converter and the abap2UI5 runtime run in your browser, nothing is sent anywhere.</p>
      <p class="jump">
        <a href="#samples">Samples</a>
        <a href="#playground">Your own report</a>
        <a href="#package">A whole package</a>
      </p>
    </header>

    <section id="samples">
      <h2>Samples - a classic report, the class it becomes, the app</h2>
      <p class="muted">Each sample is a classic report of the converter's corpus. report2UI5 converts it here
        in the page - the report and its class side by side - and the class starts below them as an abap2UI5 app - the converter and the abap2UI5
        runtime run in your browser, nothing is sent anywhere.</p>

      <div class="toolbar">
        <label>Sample
          <select id="s-example"></select>
        </label>
        <button id="s-prev" class="button" type="button" aria-label="Previous sample">&larr;</button>
        <button id="s-next" class="button" type="button" aria-label="Next sample">&rarr;</button>
        <button id="s-try" class="button" type="button">Edit it below</button>
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

    <section id="playground">
      <h2>Your own report</h2>
      <p class="muted">Paste a classic report of your own. It is converted as you type, and kept in this browser
        for your next visit. <strong>Preview</strong> starts the class as an app. Includes and the DDIC of your
        system are not there; the flight tables SCARR, SPFLI and SFLIGHT are, with rows to list.</p>

      <div class="toolbar">
        <label>Class name
          <input id="classname" placeholder="zcl_ + the report name" spellcheck="false">
        </label>
        <button id="convert" class="button" type="button">Convert</button>
        <button id="run" class="button primary" type="button" aria-pressed="false">Preview</button>
      </div>

      <div id="own-panes" class="two">
        <div class="pane">
          <div class="pane-head"><span><span class="step-no">1</span> Your report <span class="muted">.prog.abap</span></span>
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
        <div class="pane">
          <div class="pane-head">
            <span><span class="step-no">2</span> The class report2UI5 writes</span>
            <span class="head-actions">
              <button id="copy" class="link" type="button">Copy</button>
              <button id="download" class="link" type="button">Download</button>
              <button id="download-all" class="link" type="button" title="The files as the zip abapGit imports offline">abapGit zip</button>
            </span>
          </div>
          <div id="tabs" class="tabs" role="tablist"></div>
          <pre id="output" class="output" tabindex="0"><span class="muted">The generated class appears here.</span></pre>
        </div>
        <div id="preview" class="pane" hidden>
          <div class="pane-head"><span><span class="step-no">3</span> Preview - abap2UI5 in your browser</span>
            <span><span id="app-state" class="muted"></span>
            <a id="app-open" class="link" href="https://abap2ui5.github.io/playground/" target="_blank" rel="noopener" hidden>Open in the playground ↗</a></span>
          </div>
          <div class="app">
            <iframe id="app" title="The converted report, running" src="about:blank"></iframe>
            <div id="app-cover" class="app-cover">Starting...</div>
          </div>
        </div>
      </div>

      <div id="status" class="status" role="status"></div>

      <div class="info">
        <div class="card info-card wide-card">
          <h3>What happened</h3>
          <ol id="steps" class="steps"></ol>
        </div>
        <div class="card info-card"><h3>Refused <span id="n-refused" class="badge"></span></h3><div id="refused" class="muted">Nothing.</div></div>
        <div class="card info-card"><h3>To do <span id="n-todo" class="badge"></span></h3><div id="todo" class="muted">Nothing.</div></div>
        <div class="card info-card wide-card"><h3>Mapped - classic to abap-cloud-gui <span id="n-mapped" class="badge"></span></h3><div id="mapped" class="muted">Nothing yet.</div></div>
        <div class="card info-card wide-card"><details><summary><h3>Migration report <span class="muted">- the .migration.md, as the CLI writes it</span></h3></summary><pre id="migration" class="code"></pre></details></div>
      </div>
    </section>

    <section id="package">
      <h2>A whole package</h2>
      <p class="muted">The case a migration really is: not one report, a package of them. Drop the abapGit zip of
        the package here (or its .prog.abap and .prog.xml files) - every report is converted with its includes and
        its text pool, in this browser, nothing is uploaded anywhere. You get what was converted, what was
        refused, and one abapGit zip with every class and its migration report.</p>
      <div class="toolbar">
        <label class="drop" id="pkg-drop">
          <span id="pkg-drop-text">Drop the zip or the files here, or click to choose</span>
          <input id="pkg-files" type="file" multiple accept=".zip,.abap,.xml" hidden>
        </label>
        <button id="pkg-zip" class="button primary" type="button" disabled title="Every class and its migration report, with summary.md, as the zip abapGit imports offline">abapGit zip</button>
        <button id="pkg-clear" class="link" type="button" hidden>Clear</button>
      </div>
      <div id="pkg-result" hidden>
        <p id="pkg-summary"></p>
        <table id="pkg-table" class="table">
          <thead><tr><th>#</th><th>Report</th><th>Class</th><th>Result</th><th>To do</th></tr></thead>
          <tbody></tbody>
        </table>
        <div class="info">
          <div class="card info-card wide-card"><details><summary><h3>Summary <span class="muted">- summary.md, the refusals ranked</span></h3></summary><pre id="pkg-overview" class="code"></pre></details></div>
        </div>
      </div>
    </section>
  </div>
</template>
