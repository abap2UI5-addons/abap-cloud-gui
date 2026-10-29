# The playground of the site

The site of this repository has its own copy of the
[abap2UI5 playground](https://github.com/abap2UI5/playground), under
`playground/` beside the converter page. There, a classic report runs: put
`zreport.prog.abap` first, optionally with its text pool `zreport.prog.xml`,
and press Run. Run converts the report with report2cloud and starts the class
on the addon's report runtime. The site's page runs it in the
playground's app-only view (`?view=full`), twice: under Samples, a report of
the converter's corpus beside its class, started when it is picked; under
Your own report, the report you paste, started when you press Preview. The full playground with its editor is at `playground/` too.

The abap2UI5 playground itself knows nothing about reports. Everything that
does is in `report2cloud.patch`, applied by `scripts/build-playground.mjs`
onto the playground at its pin (`PIN` there):

| Where (in the playground) | What |
| --- | --- |
| `tools/build-report2cloud.mjs`, `tools/build.mjs`, `package.json` | A build step after the site: `dist/report2cloud/` with the converter bundled on the registry worker's abaplint, the runtime's ABAP for the checks, and the runtime transpiled at build time. The addon is the folder `R2C_ADDON` names: this checkout. |
| `src/editor/transpile-core.mjs` | `transpileObjects()`, which the build step and a Run share. Its ordering and prologue skip the nameless `requires` that a class's local classes bring. |
| `src/editor/registry-*.mjs`, `src/editor/registry.mjs` | `convertReport`: the converter in the registry worker, the runtime's ABAP added to the corpus once. |
| `src/shell/report2cloud.mjs`, `src/shell/run.mjs` | A report as the first file is converted on Run. The class files are compiled in its place; the runtime's chunks are defined before them. Refusals are underlined in the report. The report's own abaplint findings don't block Run: they come from the DDIC of the system it was written for, which isn't here. |
| the demo tables | SCARR, SPFLI and SFLIGHT come with every converted Run, with the rows the addon's runtime tests seed (`tools/report2cloud/test/runtime/seed.mjs`). The flight dates count from today. The test DDIC (`tools/report2cloud/test/ddic`) is in the checks. A table of the same name in the editor replaces the demo one. |
| `src/editor/files.mjs`, `src/shell/deep-link.mjs`, `src/shell/ai-agent.mjs`, `src/shell/export.mjs` | `.prog.abap` / `.prog.xml` as file names, in `?src=` links and in the AI Studio. `.clas.locals_def.abap` / `.clas.locals_imp.abap` are includes of their class. |
| `src/examples/zr2c_*`, `tests/report2cloud.spec.js`, `tests/node/report-files.test.mjs` | Examples and tests (`npm run site:playground -- --test`). |

Nothing of the addon is fetched before the first report is converted.

## Building it

```sh
npm run site                         # build/site
npm run site:playground              # build/site/playground
npm run site:playground -- --test    # and the patch's tests
```

The clone is `build/playground`. Every run puts it back to the pin and
applies the patch again. Its `build/`, `deps/` and `node_modules` stay, so a
second build takes under a minute. The first one takes several: the
framework's downport and the UI5 build.

## A new pin, or a patch that no longer applies

The patch is a diff against the pin. When the build says it does not apply,
the playground moved under it. Make it again on the new pin:

```sh
cd build/playground
git checkout --force --detach <new sha> && git clean -fd
git apply --3way ../../site/playground/report2cloud.patch   # resolve what conflicts
git add -A && git diff --cached HEAD > ../../site/playground/report2cloud.patch
```

Then put the new sha into `PIN` of `scripts/build-playground.mjs`, and run
`npm run site:playground -- --test`.

To change the patch itself, edit the files in `build/playground` after a
build. Then write the diff back as above, without the checkout.
