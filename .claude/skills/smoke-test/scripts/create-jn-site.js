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

const { chromium } = require("playwright");
const path = require("path");

const USER_DATA_DIR = path.join(
  process.env.HOME || "/tmp",
  ".woo-smoke-test-browser"
);

async function main() {
  const args = process.argv.slice(2);
  const noJetpack = args.includes("--no-jetpack");

  // Build the feature list
  const features = ["woocommerce", "wc-smooth-generator"];
  // Note: Jurassic Ninja installs Jetpack by default. There's no explicit
  // "no jetpack" toggle — you'd need to deactivate it after creation.
  // The --no-jetpack flag here is a hint for the caller to deactivate JP after.

  const createUrl = `https://jurassic.ninja/create?features=${features.join(",")}`;

  // Use a persistent browser context so WP.com auth session is reused
  const context = await chromium.launchPersistentContext(USER_DATA_DIR, {
    headless: false,
    args: ["--no-sandbox"],
    viewport: { width: 1280, height: 800 },
  });

  const page = await context.newPage();

  try {
    // Navigate to the create page
    await page.goto(createUrl, { waitUntil: "domcontentloaded", timeout: 30000 });

    // Check if we need to authenticate
    // JN redirects to WordPress.com login if not authenticated
    const currentUrl = page.url();
    if (
      currentUrl.includes("wordpress.com/log-in") ||
      currentUrl.includes("wordpress.com/start")
    ) {
      // Print to stderr so it doesn't mix with JSON output
      process.stderr.write(
        "\n🔐 WordPress.com login required.\n" +
          "   Please log in to WordPress.com in the browser window.\n" +
          "   Waiting up to 120 seconds...\n\n"
      );

      // Wait for redirect back to JN after login
      try {
        await page.waitForURL("**/jurassic.ninja/**", { timeout: 120000 });
      } catch {
        process.stderr.write(
          "❌ Timed out waiting for WordPress.com login.\n"
        );
        await context.close();
        process.exit(1);
      }

      // After login redirect, we may need to re-navigate to the create URL
      if (!page.url().includes("/create")) {
        await page.goto(createUrl, { waitUntil: "domcontentloaded", timeout: 30000 });
      }
    }

    // Wait for site provisioning — JN shows a progress indicator then redirects
    // to the new site's wp-admin with a companion notice containing credentials
    process.stderr.write("⏳ Waiting for site provisioning (up to 3 minutes)...\n");

    // JN redirects to the new site after creation. Wait for a URL that looks
    // like a JN site (*.jurassic.ninja)
    await page.waitForURL("**jurassic.ninja/wp-admin/**", {
      timeout: 180000,
      waitUntil: "domcontentloaded",
    });

    // The companion plugin shows a notice with credentials at the top of wp-admin.
    // Look for the notice with site details.
    process.stderr.write("🔍 Extracting site credentials...\n");

    // Wait for the companion notice to appear
    await page.waitForTimeout(3000);

    // Extract credentials from the companion notice
    // The companion plugin adds a notice with text like:
    // "Your site URL: https://xxx.jurassic.ninja | Username: demo | Password: xxx"
    const siteUrl = page.url().replace(/\/wp-admin\/.*$/, "");

    // Try to get credentials from the companion notice
    let username = "demo"; // JN default
    let password = "";

    // Look for the credentials in the admin notice
    const noticeText = await page
      .locator(".companion-notice, .notice-info, #message")
      .first()
      .textContent()
      .catch(() => "");

    // Parse credentials from notice text
    const userMatch = noticeText.match(
      /(?:Username|User):\s*(\S+)/i
    );
    const passMatch = noticeText.match(
      /(?:Password|Pass):\s*(\S+)/i
    );

    if (userMatch) username = userMatch[1];
    if (passMatch) password = passMatch[1];

    // If we couldn't find credentials in the notice, check the URL params
    // JN sometimes passes credentials as URL parameters
    const urlObj = new URL(page.url());
    if (!password && urlObj.searchParams.has("password")) {
      password = urlObj.searchParams.get("password");
    }

    // If still no password, try to find it in the page content
    if (!password) {
      const bodyText = await page.locator("body").textContent().catch(() => "");
      const bodyPassMatch = bodyText.match(/(?:Password|Pass):\s*(\S+)/i);
      if (bodyPassMatch) password = bodyPassMatch[1];
    }

    const result = {
      url: siteUrl,
      adminUrl: `${siteUrl}/wp-admin/`,
      username,
      password,
      noJetpack,
    };

    // Output JSON to stdout
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
