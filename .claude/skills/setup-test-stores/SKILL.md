---
name: setup-test-stores
description: Provision a disposable Jurassic Ninja store for the Maestro smoke suite, connect Jetpack to the developer's own WordPress.com test account, create WooCommerce API keys, and write .maestro/.env.local. Use when Maestro setup is missing, when .env.local points at an expired store, or when a clean store is wanted.
user-invocable: true
allowed-tools: "Bash, Read, mcp__context-a8c__context-a8c-load-provider, mcp__context-a8c__context-a8c-execute-tool"
argument-hint: "[--fresh]"
---

# Set up a Maestro test store

Provisions a Jurassic Ninja (JN) site and configures it as the Maestro lab store.
Site creation is only possible through the `jurassic-ninja` ContextA8C MCP, so this
skill drives that part; everything after "site exists and its password is known" is
handled by `.maestro/scripts/setup-jn-store.sh`, which a developer can also run by
hand against a site created in a browser.

## Prerequisites

- ContextA8C MCP configured with the `jurassic-ninja` provider (see `.agents/rules/context-a8c.md`).
- App credentials present at `~/.configure/woocommerce-ios/secrets/woo_app_credentials.json`.
  If missing, run `rake dependencies`.
- `expect` on PATH (ships with macOS) for password-based SSH.
- A **WordPress.com test account with two-factor authentication disabled**. The OAuth
  password grant used to connect Jetpack cannot answer a 2FA challenge non-interactively.
  Never use a personal or production account. The account is read from `.env.local`, or
  from `MAESTRO_WOO_LAB_WPCOM_EMAIL` / `MAESTRO_WOO_LAB_WPCOM_PASSWORD` in the
  environment; see step 0.

## Steps

0. **Make sure the WordPress.com account is available.** The script needs a test account
   to connect Jetpack to, and it cannot prompt when run by an agent because there is no
   terminal attached; it will exit with a message naming what is missing.

   If `.env.local` has no `MAESTRO_WOO_LAB_WPCOM_EMAIL` / `MAESTRO_WOO_LAB_WPCOM_PASSWORD`,
   stop and ask the user to either add those two lines themselves, or run the script
   directly in their own terminal, where it prompts without echoing:

   ```bash
   .maestro/scripts/setup-jn-store.sh --site <domain>.jurassic.ninja
   ```

   Do not ask the user to paste a password into the conversation, and never pass one as a
   command-line argument.

1. **Check whether setup is already usable.** If `.maestro/.env.local` exists, read
   `MAESTRO_WOO_LAB_JETPACK_STORE_URL` and the consumer key/secret, then probe:

   ```bash
   curl -s -o /dev/null -w '%{http_code}' -u "$CK:$CS" "$STORE/wp-json/wc/v3/products?per_page=1"
   ```

   A `200` means the store is alive and the keys work; report that and stop, unless the
   user passed `--fresh`. Anything else means the store is gone or expired: continue, and
   reuse the existing WP.com account lines rather than asking for them again.

2. **Provision a site.**

   ```
   provision-site  features: {"woocommerce":"true","woocommerce-import-sample-data":"true","jetpack":"true"}
   ```

   Note the returned `domain`.

3. **Fetch its password.**

   ```
   list-sites  domain: <domain>, include_passwords: true, include_config: true
   ```

   `JN_PASSWORD` in the returned config is both the wp-admin and the SSH password. The
   admin username is `demo`.

   Do not echo this value in your reply.

4. **Configure the store.** Pass the password through the environment so it never lands
   in `ps` output:

   ```bash
   JN_SSH_PASS='<JN_PASSWORD>' .maestro/scripts/setup-jn-store.sh --site <domain>
   ```

   The script waits for JN to finish provisioning (it answers HTTP before its plugins
   finish installing), connects Jetpack, creates the API keys, and writes
   `.maestro/.env.local`.

   This assumes `.env.local` already has `MAESTRO_WOO_LAB_WPCOM_EMAIL` and
   `MAESTRO_WOO_LAB_WPCOM_PASSWORD`. If it does not, see step 0.

5. **Report** the store URL and blog ID. Do not print any credential.

## Verifying

```bash
.maestro/scripts/lint-env.py
.maestro/scripts/doctor.sh --app "$APP" --include-tags products --exclude-tags "" --seed --device "$UDID"
```

The doctor should report all credentials present. Scoping by tag is deliberate: with
`--profile phone-full` it also demands the negative-login fixtures, which this skill does
not yet provision, and reports them missing.

## What the provisioned store supports

A fresh store has the WooCommerce sample products, and is known-good for the products
flows and basic dashboard flows.

It has **no orders, customers, or coupons**, and its onboarding profile is unset, so these
are expected to fail against it: `orders_list_and_search`, `dashboard_view_all_analytics`,
`orders_create` (needs `MAESTRO_WOO_EXISTING_CUSTOMER_SEARCH`), and the coupon flows.
Seeding that data is not yet automated.

The negative-login fixtures (`MAESTRO_WOO_NO_JETPACK_*`, `MAESTRO_WOO_NOT_A_WOO_STORE_*`,
`MAESTRO_WOO_WRONG_ACCOUNT_STORE_URL`) are also not provisioned yet, so the login flows
that need them remain unconfigured.

## Notes

- JN sites expire after 7 days of inactivity. Re-run this skill when a store stops
  responding; it reuses the WordPress.com account already in `.env.local`.
- Only test stores and test accounts. Destructive flows publish and delete real data.
- The previous `.env.local` is backed up outside the repository, because `.gitignore`
  matches `.env.local` exactly and a sibling backup file would not be ignored.
