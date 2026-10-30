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
for (const file of ["index.html", "counter.js"]) {
  await copyFile(path.join(root, "website", file), path.join(output, file));
}
await writeFile(path.join(output, "counter-config.js"),
  "window.PORTFOLIO_COUNTER_CONFIG = Object.freeze(" + JSON.stringify({ apiBaseUrl }) + ");\n");
console.log("Portfolio built. Counter " + (apiBaseUrl ? "configured." : "disabled until API is configured."));
