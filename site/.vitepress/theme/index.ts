// The default theme of VitePress, the colors of abap-cloud-gui and the
// Playground component (site/playground.md).
import DefaultTheme from "vitepress/theme";
import type { Theme } from "vitepress";
import Playground from "./Playground.vue";
import "./custom.css";
import "./playground.css";

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component("Playground", Playground);
  },
} satisfies Theme;
