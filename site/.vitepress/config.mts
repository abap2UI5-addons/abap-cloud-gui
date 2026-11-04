// The site of the repository on GitHub Pages
// (https://abap2ui5-addons.github.io/abap-cloud-gui/), built by
// scripts/build-site.mjs (npm run site) into build/site.
import { defineConfig } from "vitepress";

const REPO = "https://github.com/abap2UI5-addons/abap-cloud-gui";

export default defineConfig({
  title: "abap-cloud-gui",
  description: "Write abap2UI5 apps like classic ABAP reports - and convert the reports you have with report2UI5, here in the browser.",
  lang: "en",
  base: "/abap-cloud-gui/",
  outDir: "../build/site",
  cleanUrls: true,
  lastUpdated: false,
  // the addons logo: SVG where the browser takes it, PNG otherwise
  head: [
    ["link", { rel: "icon", type: "image/svg+xml", href: "/abap-cloud-gui/logo.svg" }],
    ["link", { rel: "icon", type: "image/png", href: "/abap-cloud-gui/favicon.png" }],
  ],
  themeConfig: {
    // the navbar carries abap2UI5's logo, the hero and the favicon the addons logo
    logo: { src: "/abap2ui5.svg", alt: "abap2UI5" },
    nav: [
      { text: "Guide", link: "/guide" },
      { text: "Samples", link: "/samples" },
      { text: "Playground", link: "/playground" },
      {
        text: "Links",
        items: [
          { text: "Releases", link: `${REPO}/releases` },
          { text: "Changelog", link: `${REPO}/blob/main/CHANGELOG.md` },
          { text: "report2UI5", link: `${REPO}/blob/main/tools/report2ui5/README.md` },
          { text: "abap2UI5", link: "https://abap2ui5.github.io/" },
        ],
      },
    ],
    socialLinks: [{ icon: "github", link: REPO }],
    editLink: { pattern: `${REPO}/edit/main/site/:path`, text: "Edit this page on GitHub" },
    search: { provider: "local" },
    footer: {
      message: "MIT licensed - part of <a href=\"https://github.com/abap2UI5-addons\">abap2UI5-addons</a>",
      copyright: "<a href=\"https://github.com/abap2UI5/abap2UI5\">abap2UI5</a>",
    },
  },
});
