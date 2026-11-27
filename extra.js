// Render ```mermaid blocks (the README flowchart). pkgdown writes them as <pre class="mermaid"><code>...</code></pre>
// but doesn't load Mermaid, so the diagram source would show as text.
(function () {
  const blocks = document.querySelectorAll("pre.mermaid");
  if (!blocks.length) return;

  blocks.forEach(function (pre) {
    const div = document.createElement("div");
    div.className = "mermaid";
    div.textContent = pre.textContent;
    pre.replaceWith(div);
  });

  const script = document.createElement("script");
  script.src = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js";
  script.onload = function () {
    const dark = document.documentElement.getAttribute("data-bs-theme") === "dark";
    mermaid.initialize({ startOnLoad: false, theme: dark ? "dark" : "default" });
    mermaid.run({ querySelector: "div.mermaid" });
  };
  document.head.appendChild(script);
})();
