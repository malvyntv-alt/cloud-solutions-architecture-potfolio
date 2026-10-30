import test from "node:test";
import assert from "node:assert/strict";
import vm from "node:vm";
import { readFile } from "node:fs/promises";
const source = await readFile(new URL("../website/counter.js", import.meta.url), "utf8");
async function render(config, fetchResult, reject = false) {
  const count = { textContent: "Loading" };
  const year = { textContent: "" };
  const calls = [];
  const context = {
    document: { getElementById: id => id === "year" ? year : count },
    window: { PORTFOLIO_COUNTER_CONFIG: { apiBaseUrl: config } },
    URL, Intl, Date, AbortController, setTimeout, clearTimeout,
    fetch: async (...args) => {
      calls.push(args);
      if (reject) throw new Error("Network down");
      return fetchResult;
    }
  };
  vm.runInNewContext(source, context);
  await new Promise(resolve => setImmediate(resolve));
  return { count, year, calls };
}
test("configured endpoint records one anonymous view and renders count", async () => {
  const result = await render("https://example.execute-api.us-east-1.amazonaws.com/",
    { ok: true, json: async () => ({ views: 1234 }) });
  assert.equal(result.count.textContent, "1,234");
  assert.equal(result.calls.length, 1);
  assert.equal(result.calls[0][0], "https://example.execute-api.us-east-1.amazonaws.com/views");
  assert.equal(result.calls[0][1].method, "POST");
  assert.equal(result.calls[0][1].credentials, "omit");
  assert.equal(result.year.textContent, String(new Date().getFullYear()));
});
test("missing endpoint leaves the portfolio usable without a request", async () => {
  const result = await render("", null);
  assert.equal(result.count.textContent, "Unavailable");
  assert.equal(result.calls.length, 0);
});
test("invalid and credential-bearing endpoints are not called", async () => {
  for (const url of ["http://example.test", "https://user:pass@example.test", "https://example.test/private"]) {
    const result = await render(url, null);
    assert.equal(result.calls.length, 0);
    assert.equal(result.count.textContent, "Unavailable");
  }
});
test("API or network failure displays fallback and does not retry", async () => {
  for (const reject of [false, true]) {
    const result = await render("https://example.test", { ok: false }, reject);
    assert.equal(result.count.textContent, "Unavailable");
    assert.equal(result.calls.length, 1);
  }
});
test("invalid count is never rendered", async () => {
  for (const views of [-1, "100", Infinity]) {
    const result = await render("https://example.test", { ok: true, json: async () => ({ views }) });
    assert.equal(result.count.textContent, "Unavailable");
  }
});
