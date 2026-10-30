(() => {
  "use strict";
  const year = document.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());
  const counter = document.getElementById("page-view-count");
  if (!counter) return;
  const unavailable = () => { counter.textContent = "Unavailable"; };
  const configured = window.PORTFOLIO_COUNTER_CONFIG?.apiBaseUrl;
  if (!configured) { unavailable(); return; }
  let api;
  try {
    api = new URL(configured);
    if (api.protocol !== "https:" || api.username || api.password ||
        api.search || api.hash || api.pathname !== "/") throw new Error("Invalid endpoint");
  } catch { unavailable(); return; }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 3000);
  fetch(new URL("views", api).href, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ page: "home" }), signal: controller.signal,
    credentials: "omit", cache: "no-store", referrerPolicy: "no-referrer"
  }).then(async response => {
    if (!response.ok) throw new Error("Counter unavailable");
    const result = await response.json();
    if (!Number.isSafeInteger(result.views) || result.views < 0) throw new Error("Invalid count");
    counter.textContent = new Intl.NumberFormat("en-US").format(result.views);
  }).catch(unavailable).finally(() => clearTimeout(timeout));
})();
