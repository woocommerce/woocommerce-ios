#!/usr/bin/env node
/**
 * Create a Jurassic Ninja site with WooCommerce using Playwright.
 *
 * Usage:
 *   npx playwright install chromium   # first time only
 *   node create-jn-site.js            # default: WooCommerce + Smooth Generator
 *   node create-jn-site.js --no-jetpack  # WooCommerce without Jetpack
 *
 * Outputs JSON to stdout:
 *   { "url": "https://...", "adminUrl": "https://.../wp-admin/", "username": "...", "password": "..." }
 *
 * The script launches a visible browser so the user can authenticate with
 * WordPress.com if needed. Once authenticated, subsequent runs reuse the session.
 */

import path from "node:path";
import { fileURLToPath } from "node:url";

// Playwright is not a local dependency — expected to be installed globally.
let chromium;
try {
  const pw = await import("playwright");
  chromium = pw.chromium;
} catch {
  console.error(
    "Playwright is not installed. Install it with:\n" +
      "  npm install -g playwright && npx playwright install chromium\n"
  );
  process.exit(1);
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const USER_DATA_DIR = path.join(
  process.env.HOME || "/tmp",
  ".woo-smoke-test-browser"
);

async function main() {
  const args = process.argv.slice(2);
  const noJetpack = args.includes("--no-jetpack");

  const features = ["woocommerce", "wc-smooth-generator"];
  const createUrl = `https://jurassic.ninja/create?features=${features.join(",")}`;

  const context = await chromium.launchPersistentContext(USER_DATA_DIR, {
    headless: false,
    args: ["--no-sandbox"],
    viewport: { width: 1280, height: 800 },
  });

  const page = await context.newPage();

  try {
    // Step 1: Navigate to JN create page
    process.stderr.write(`📡 Navigating to ${createUrl}\n`);
    await page.goto(createUrl, { waitUntil: "domcontentloaded", timeout: 30000 });

    // Step 2: Handle WP.com login if needed
    // Keep checking the URL in a loop — the redirect chain may be fast (webauthn)
    // or slow (manual password entry). We poll until we're on jurassic.ninja.
    const maxLoginWait = 180000; // 3 minutes
    const startTime = Date.now();
    let promptedForLogin = false;

    while (Date.now() - startTime < maxLoginWait) {
      const url = page.url();

      if (url.includes("jurassic.ninja")) {
        // We're on JN — either logged in or site is being created
        break;
      }

      if (!promptedForLogin && url.includes("wordpress.com")) {
        process.stderr.write(
          "\n🔐 WordPress.com login required.\n" +
            "   Please log in in the browser window.\n" +
            "   Waiting up to 3 minutes...\n\n"
        );
        promptedForLogin = true;
      }

      await page.waitForTimeout(2000);
    }

    if (!page.url().includes("jurassic.ninja")) {
      process.stderr.write("❌ Timed out waiting for WordPress.com login.\n");
      await context.close();
      process.exit(1);
    }

    // Step 3: Ensure we're on the /create page (not just the homepage)
    // After login, JN may redirect to homepage. Re-navigate to /create.
    if (!page.url().includes("/create") && !page.url().includes("/wp-admin")) {
      process.stderr.write("🔄 Re-navigating to create page after login...\n");
      await page.goto(createUrl, { waitUntil: "domcontentloaded", timeout: 30000 });
    }

    // Step 4: Wait for site provisioning
    // JN creates the site via AJAX and then either:
    // a) Redirects automatically to wp-admin, or
    // b) Shows a "Go to site" button that needs to be clicked
    // We poll the page state to handle both cases.
    process.stderr.write("⏳ Waiting for site provisioning (up to 5 minutes)...\n");

    const provisionStart = Date.now();
    const provisionTimeout = 300000;

    while (Date.now() - provisionStart < provisionTimeout) {
      const url = page.url();

      // Case A: Already redirected to wp-admin
      if (url.includes(".jurassic.ninja") && url.includes("/wp-admin")) {
        break;
      }

      // Case B: Look for the "Go to the Site!" link
      // JN shows this link when provisioning is complete. The href contains
      // the subdomain URL with ?auto_login for automatic authentication.
      const goLink = page.locator('a[href*=".jurassic.ninja"]').filter({
        hasNot: page.locator(':scope[href*="/create"]'),
      });
      if (await goLink.count() > 0) {
        const href = await goLink.first().getAttribute("href");
        const text = await goLink.first().textContent().catch(() => "");
        process.stderr.write(`🔗 Found: "${text.trim()}" → ${href}\n`);
        await goLink.first().click();
        await page.waitForTimeout(5000);
        break;
      }

      await page.waitForTimeout(3000);
    }

    // After clicking "Go to the Site!", we may be on the auto_login URL
    // or already redirected to wp-admin. Wait for the page to settle.
    // The auto_login URL logs us in and redirects to wp-admin.
    if (!page.url().includes("/wp-admin")) {
      process.stderr.write(`📍 Current URL: ${page.url()}\n`);
      process.stderr.write("⏳ Waiting for auto-login redirect to wp-admin...\n");
      try {
        await page.waitForURL("**/wp-admin/**", { timeout: 30000, waitUntil: "domcontentloaded" });
      } catch {
        // If we're on a .jurassic.ninja URL but not wp-admin, navigate there
        const currentUrl = page.url();
        const match = currentUrl.match(/(https?:\/\/[a-z-]+\.jurassic\.ninja)/i);
        if (match) {
          await page.goto(`${match[1]}/wp-admin/`, { waitUntil: "domcontentloaded", timeout: 30000 });
        } else {
          process.stderr.write("❌ Site provisioning timed out — could not find site URL.\n");
          await context.close();
          process.exit(1);
        }
      }
    }

    // Step 5: Extract credentials from the companion plugin notice
    process.stderr.write("🔍 Extracting site credentials...\n");
    await page.waitForTimeout(3000);

    const siteUrl = page.url().replace(/\/wp-admin\/.*$/, "");
    let username = "demo";
    let password = "";

    // The companion plugin shows a notice bar with credentials
    // Try multiple selectors — the notice format varies
    const noticeText = await page
      .locator(".companion-notice, .notice-info, #message, .jn-notice")
      .first()
      .textContent({ timeout: 10000 })
      .catch(() => "");

    const userMatch = noticeText.match(/(?:Username|User):\s*(\S+)/i);
    const passMatch = noticeText.match(/(?:Password|Pass):\s*(\S+)/i);
    if (userMatch) username = userMatch[1];
    if (passMatch) password = passMatch[1];

    // Fallback: check URL params
    if (!password) {
      const urlObj = new URL(page.url());
      if (urlObj.searchParams.has("password")) {
        password = urlObj.searchParams.get("password");
      }
    }

    // Fallback: scan full page body
    if (!password) {
      const bodyText = await page
        .locator("body")
        .textContent({ timeout: 5000 })
        .catch(() => "");
      const bodyMatch = bodyText.match(/(?:Password|Pass):\s*(\S+)/i);
      if (bodyMatch) password = bodyMatch[1];
    }

    const result = {
      url: siteUrl,
      adminUrl: `${siteUrl}/wp-admin/`,
      username,
      password,
      noJetpack,
    };

    process.stdout.write(JSON.stringify(result, null, 2) + "\n");
    process.stderr.write(`\n✅ Site created: ${siteUrl}\n`);
    if (noJetpack) {
      process.stderr.write(
        "   Note: Deactivate Jetpack manually — JN installs it by default.\n"
      );
    }
  } catch (error) {
    process.stderr.write(`\n❌ Error: ${error.message}\n`);
    process.exit(1);
  } finally {
    await context.close();
  }
}

main();
