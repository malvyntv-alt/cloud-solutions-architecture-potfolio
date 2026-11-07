import { writeFile, mkdir, copyFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const endpoint = (process.env.COUNTER_API_URL || "").trim();
let apiBaseUrl = "";
if (endpoint) {
  const value = new URL(endpoint);
  if (value.protocol !== "https:" || value.username || value.password ||
      value.search || value.hash || value.pathname !== "/") {
    throw new Error("COUNTER_API_URL must be an HTTPS origin without credentials or a path.");
  }
  apiBaseUrl = value.origin + "/";
}
const output = path.join(root, "build", "site");
await mkdir(output, { recursive: true });
for (const file of ["index.html", "enterpriseiq.html", "enterprise-hybrid-network.html", "counter.js"]) {
  await copyFile(path.join(root, "website", file), path.join(output, file));
}
await writeFile(path.join(output, "counter-config.js"),
  "window.PORTFOLIO_COUNTER_CONFIG = Object.freeze(" + JSON.stringify({ apiBaseUrl }) + ");\n");
console.log("Portfolio built. Counter " + (apiBaseUrl ? "configured." : "disabled until API is configured."));

await copyFile(path.join(root, "../enterpriseiq-gen-ai/docs/portfolio/diagrams/enterpriseiq-aws-architecture.png"), path.join(output, "enterpriseiq-architecture.png"));

for (const [source, target] of [
  ["2026-11-06-live-results.json", "hybrid-network-live-results.json"],
  ["2026-11-06-cleanup.json", "hybrid-network-cleanup.json"]
]) {
  await copyFile(path.join(root, "../enterprise-hybrid-network/docs/evidence", source), path.join(output, target));
}
