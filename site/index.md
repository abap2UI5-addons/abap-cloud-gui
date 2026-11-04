---
layout: home

hero:
  name: abap-cloud-gui
  text: Classic ABAP reports, as UI5 apps
  tagline: Selection screen, WRITE list, ALV grid, START-OF-SELECTION, AT LINE-SELECTION, MESSAGE - write a class that reads like a report and get an app in the browser. On ABAP Cloud and down to 7.02.
  image:
    src: /logo.svg
    alt: abap2UI5 addons
  actions:
    - theme: brand
      text: See the samples
      link: /samples
    - theme: alt
      text: Convert your own report
      link: /playground
    - theme: alt
      text: Guide
      link: /guide
    - theme: alt
      text: Install with abapGit
      link: https://github.com/abap2UI5-addons/abap-cloud-gui#installation

features:
  - title: No SAP GUI on ABAP Cloud
    details: No selection screens, no lists, no CL_SALV_TABLE. A report of ten minutes on premise turns into RAP, CDS and a Fiori app. abap-cloud-gui keeps the report model and renders it with abap2UI5.
  - title: The concepts you know
    details: Event blocks are methods of the same name, PARAMETERS and SELECT-OPTIONS are attributes, write( ) writes the list, alv( ) shows a grid - with drilldown, value helps, variants and messages. No UI5 knowledge needed.
  - title: Converted, not rewritten
    details: report2UI5 converts the user interface of a .prog.abap - the selection screen, the list and the ALV into their counterparts, dynpros and SAP GUI controls into stand-ins. The logic goes over as it is. What it cannot convert it refuses with the line - it never guesses.
    link: /samples
    linkText: See it on the samples
  - title: Measured on the web
    details: Every week the converter runs over the open-source ABAP of the web - the share that converts, the refusals ranked, and how many of the converted reports start in the transpiled runtime.
  - title: Checked like code
    details: abaplint against ABAP Cloud and 7.02, the abap2UI5 linter, ABAP Unit in a transpiled runtime, and a runtime test that drives every converted sample report through the UI5 protocol.
    link: /guide#how-it-is-checked
    linkText: How it is checked
  - title: Open source
    details: MIT licensed, installed with abapGit, part of abap2UI5-addons. Issues and pull requests welcome.
    link: https://github.com/abap2UI5-addons/abap-cloud-gui
    linkText: GitHub
---

<script setup>
// the sections of the playground lived on this page before the site was
// VitePress - its old links (#samples, #playground, #package) lead to the
// samples and the playground now
import { onMounted } from "vue";
import { useRouter, withBase } from "vitepress";

const router = useRouter();
onMounted(() => {
  const { hash } = window.location;
  if (hash === "#samples") router.go(withBase("/samples"));
  else if (["#playground", "#package"].includes(hash)) router.go(withBase(`/playground${hash}`));
});
</script>
