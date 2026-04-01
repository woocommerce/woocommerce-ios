#!/usr/bin/env node
/**
 * WooCommerce Smoke Test Credentials MCP Server
 *
 * A local MCP server that handles credential operations without exposing
 * credential values to the AI agent. Reads from macOS Keychain and types
 * into device fields via WDA or simulator pasteboard.
 *
 * Tools:
 *   - check_credentials: Check which keychain entries exist for a store
 *   - type_credential: Type a keychain value into the focused field on a device
 *   - create_order: Create a WooCommerce order using keychain API credentials
 *   - list_stores: List configured store aliases
 *
 * Security: Credential values never appear in tool responses or stdout.
 * All output to stdout is MCP protocol JSON. Diagnostics go to stderr.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync, execFileSync } from "node:child_process";
import https from "node:https";

const SERVICE = "woo-smoke-test";

// ── Known stores and their entries ──────────────────────────────────────────

const STORE_ENTRIES = {
  primary: [
    "store-url",
    "wpcom-email",
    "wpcom-password",
    "api-username",
    "api-password",
  ],
  apple: ["store-url"],
  google: ["store-url"],
  passwordless: ["wpcom-email"],
  "not-woo": ["wpcom-email", "wpcom-password"],
  "wrong-account": ["wpcom-email", "wpcom-password"],
  twofactor: ["store-url", "wpcom-email", "wpcom-password"],
  mailosaur: ["api-key"],
};

// ── Keychain helpers ────────────────────────────────────────────────────────

function readKeychain(account) {
  try {
    return execFileSync(
      "security",
      ["find-generic-password", "-s", SERVICE, "-a", account, "-w"],
      { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }
    ).trim();
  } catch {
    return null;
  }
}

function keychainEntryExists(account) {
  try {
    execFileSync(
      "security",
      ["find-generic-password", "-s", SERVICE, "-a", account],
      { stdio: ["pipe", "pipe", "pipe"] }
    );
    return true;
  } catch {
    return false;
  }
}

// ── Device typing via WDA ────────────────────────────────────────────────────
//
// mobile-mcp runs WDA on both simulators and physical devices. We type by
// POSTing directly to WDA's HTTP API — this keeps the credential value
// inside this process and out of any tool call parameters.
//
// Port discovery: mobile-mcp assigns WDA ports dynamically.
// - Physical devices (via go-ios): typically port 8100
// - Simulators: ports 13001, 13002, etc.
// We scan known ports to find a responsive WDA instance.

const WDA_PORTS = [8100, 13001, 13002, 13003, 13004, 13005];

function getWDASession(port) {
  const wdaHost = `http://localhost:${port}`;
  let statusResp;
  try {
    statusResp = execSync(`curl -sf --max-time 2 ${wdaHost}/status`, {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    });
  } catch {
    return null; // Port not responding
  }
  const status = JSON.parse(statusResp);
  if (status.sessionId) {
    return status.sessionId;
  }
  // No active session — try to create one (physical devices need this).
  try {
    const resp = execSync(
      `curl -sf --max-time 5 -X POST ${wdaHost}/session -H "Content-Type: application/json" -d '{"capabilities":{"alwaysMatch":{}}}'`,
      { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }
    );
    const data = JSON.parse(resp);
    return data.sessionId || (data.value && data.value.sessionId) || null;
  } catch {
    return null;
  }
}

function findWDAPortAndSession(preferredPort) {
  // If a preferred port is specified, try it first.
  if (preferredPort) {
    const sessionId = getWDASession(preferredPort);
    if (sessionId) {
      return { port: preferredPort, sessionId };
    }
  }
  // Scan all known ports.
  for (const port of WDA_PORTS) {
    if (port === preferredPort) continue; // Already tried
    const sessionId = getWDASession(port);
    if (sessionId) {
      return { port, sessionId };
    }
  }
  throw new Error(
    "Could not find or create a WDA session on any known port (" +
    WDA_PORTS.join(", ") + "). " +
    "Ensure mobile-mcp is running and connected to a device/simulator."
  );
}

function typeViaWDA(value, preferredPort) {
  const { port, sessionId } = findWDAPortAndSession(preferredPort);
  const wdaHost = `http://localhost:${port}`;

  // Clear existing text first: get the focused element, then clear it.
  // This avoids phantom characters from placeholder text on physical devices.
  try {
    const activeResp = execSync(
      `curl -sf ${wdaHost}/session/${sessionId}/element/active`,
      { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }
    );
    const activeData = JSON.parse(activeResp);
    const elementId = activeData.value && activeData.value.ELEMENT;
    if (elementId) {
      execSync(
        `curl -sf -X POST ${wdaHost}/session/${sessionId}/element/${elementId}/clear`,
        { stdio: ["pipe", "pipe", "pipe"] }
      );
    }
  } catch {
    // Clear failed — continue anyway, typing may still work
  }

  // Type into the focused element using WDA's keys endpoint.
  // The value is split into individual characters as WDA expects.
  const payload = JSON.stringify({ value: value.split("") });
  try {
    execSync(
      `curl -sf -X POST ${wdaHost}/session/${sessionId}/wda/keys -H "Content-Type: application/json" -d '${payload.replace(/'/g, "'\\''")}'`,
      { stdio: ["pipe", "pipe", "pipe"] }
    );
  } catch {
    throw new Error("WDA typing failed on port " + port + " (session " + sessionId + "). Is a text field focused on the device?");
  }
}

// ── WooCommerce REST API helper ─────────────────────────────────────────────

function wcApiRequest(storeUrl, apiUsername, apiPassword, method, endpoint, data) {
  return new Promise((resolve, reject) => {
    const url = new URL(`/wp-json/wc/v3${endpoint}`, `https://${storeUrl}`);
    const auth = Buffer.from(`${apiUsername}:${apiPassword}`).toString("base64");

    const options = {
      method,
      hostname: url.hostname,
      path: url.pathname + url.search,
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
      },
    };

    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => (body += chunk));
      res.on("end", () => {
        try {
          resolve(JSON.parse(body));
        } catch {
          reject(new Error(`Invalid JSON response: ${res.statusCode}`));
        }
      });
    });

    req.on("error", reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

// ── MCP Server ──────────────────────────────────────────────────────────────

const server = new Server(
  { name: "woo-credentials", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "check_credentials",
      description:
        "Check which keychain entries exist for a smoke test store. Returns the list of missing entries.",
      inputSchema: {
        type: "object",
        properties: {
          store: {
            type: "string",
            description:
              "Store alias to check (e.g. 'primary', 'passwordless', 'not-woo')",
          },
        },
        required: ["store"],
      },
    },
    {
      name: "type_credential",
      description:
        "Type a credential value from the keychain into the currently focused field on the device/simulator via WDA. The credential value is never returned — only a status. Ensure a text field is focused before calling.",
      inputSchema: {
        type: "object",
        properties: {
          account: {
            type: "string",
            description:
              "Keychain account key, e.g. 'primary.wpcom-email' or 'primary.wpcom-password'",
          },
          port: {
            type: "number",
            description:
              "WDA port to target. Use 8100 for physical devices, 13001+ for simulators. If omitted, auto-discovers.",
          },
        },
        required: ["account"],
      },
    },
    {
      name: "create_order",
      description:
        "Create a WooCommerce order on a store using REST API credentials from the keychain. Returns the order ID and status — never the API credentials.",
      inputSchema: {
        type: "object",
        properties: {
          store: {
            type: "string",
            description: "Store alias (e.g. 'primary')",
          },
          product_id: {
            type: "number",
            description: "Product ID to add to the order",
          },
          status: {
            type: "string",
            description: "Order status (default: 'processing')",
            default: "processing",
          },
        },
        required: ["store", "product_id"],
      },
    },
    {
      name: "list_products",
      description:
        "List products from a WooCommerce store using REST API credentials from the keychain. Returns product IDs and names — never the API credentials.",
      inputSchema: {
        type: "object",
        properties: {
          store: {
            type: "string",
            description: "Store alias (e.g. 'primary')",
          },
          per_page: {
            type: "number",
            description: "Number of products to return (default: 5)",
            default: 5,
          },
        },
        required: ["store"],
      },
    },
    {
      name: "list_stores",
      description:
        "List all configured store aliases and their credential types.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "check_credentials": {
      const store = args.store;
      const entries = STORE_ENTRIES[store];
      if (!entries) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Unknown store: ${store}. Valid stores: ${Object.keys(STORE_ENTRIES).join(", ")}`,
              }),
            },
          ],
        };
      }

      const missing = entries.filter(
        (entry) => !keychainEntryExists(`${store}.${entry}`)
      );

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: missing.length === 0 ? "ok" : "missing",
              store,
              missing,
              total: entries.length,
              found: entries.length - missing.length,
            }),
          },
        ],
      };
    }

    case "type_credential": {
      const { account } = args;

      const value = readKeychain(account);
      if (!value) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Keychain entry '${account}' not found. Run setup-keychain.sh to configure.`,
              }),
            },
          ],
        };
      }

      try {
        typeViaWDA(value, args.port);

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ status: "typed" }),
            },
          ],
        };
      } catch (err) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Failed to type credential: ${err.message}`,
              }),
            },
          ],
        };
      }
    }

    case "create_order": {
      const { store, product_id, status: orderStatus = "processing" } = args;

      const storeUrl = readKeychain(`${store}.store-url`);
      const apiUsername = readKeychain(`${store}.api-username`);
      const apiPassword = readKeychain(`${store}.api-password`);

      if (!storeUrl || !apiUsername || !apiPassword) {
        const missing = [];
        if (!storeUrl) missing.push("store-url");
        if (!apiUsername) missing.push("api-username");
        if (!apiPassword) missing.push("api-password");
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Missing keychain entries for store '${store}': ${missing.join(", ")}`,
              }),
            },
          ],
        };
      }

      try {
        const order = await wcApiRequest(
          storeUrl,
          apiUsername,
          apiPassword,
          "POST",
          "/orders",
          {
            status: orderStatus,
            line_items: [{ product_id, quantity: 1 }],
          }
        );

        // Return only non-sensitive order data
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "created",
                order_id: order.id,
                order_number: order.number,
                order_status: order.status,
                total: order.total,
              }),
            },
          ],
        };
      } catch (err) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Failed to create order: ${err.message}`,
              }),
            },
          ],
        };
      }
    }

    case "list_products": {
      const { store, per_page = 5 } = args;

      const storeUrl = readKeychain(`${store}.store-url`);
      const apiUsername = readKeychain(`${store}.api-username`);
      const apiPassword = readKeychain(`${store}.api-password`);

      if (!storeUrl || !apiUsername || !apiPassword) {
        const missing = [];
        if (!storeUrl) missing.push("store-url");
        if (!apiUsername) missing.push("api-username");
        if (!apiPassword) missing.push("api-password");
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Missing keychain entries for store '${store}': ${missing.join(", ")}`,
              }),
            },
          ],
        };
      }

      try {
        const products = await wcApiRequest(
          storeUrl,
          apiUsername,
          apiPassword,
          "GET",
          `/products?per_page=${per_page}&status=publish`,
          null
        );

        if (!Array.isArray(products)) {
          throw new Error(
            `API returned non-array response: ${JSON.stringify(products).slice(0, 200)}`
          );
        }

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "ok",
                products: products.map((p) => ({
                  id: p.id,
                  name: p.name,
                  type: p.type,
                  price: p.price,
                })),
              }),
            },
          ],
        };
      } catch (err) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                message: `Failed to list products: ${err.message}`,
              }),
            },
          ],
        };
      }
    }

    case "list_stores": {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              stores: Object.entries(STORE_ENTRIES).map(([alias, entries]) => ({
                alias,
                credentials: entries,
              })),
            }),
          },
        ],
      };
    }

    default:
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              message: `Unknown tool: ${name}`,
            }),
          },
        ],
      };
  }
});

// ── Start ───────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await server.connect(transport);
process.stderr.write("woo-credentials MCP server running\n");
