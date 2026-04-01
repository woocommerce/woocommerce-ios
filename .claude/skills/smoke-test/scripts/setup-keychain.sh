#!/bin/bash
#
# WooCommerce iOS Smoke Test — Keychain Setup
#
# Stores smoke test credentials in macOS Keychain.
# Run once per machine. Credentials are retrieved at runtime by the smoke test skill.
#
# Usage:
#   ./setup-keychain.sh              # Set up all stores
#   ./setup-keychain.sh --store primary  # Set up just one store
#   ./setup-keychain.sh --check      # Check which entries exist
#   ./setup-keychain.sh --clear      # Remove all entries
#
# See the smoke test credential wiki page for where to find each credential.

set -euo pipefail

SERVICE="woo-smoke-test"
# Placeholder — replace with the actual wiki page URL once published
WIKI_URL="https://wp.me/P91TBi-dNC"

# ── Helpers ──────────────────────────────────────────────────────────────────

store_entry() {
  local account="$1"
  local prompt="$2"
  local secret="${3:-false}"

  if [ "$secret" = "true" ]; then
    read -sp "$prompt: " value; echo
  else
    read -p "$prompt: " value
  fi

  if [ -n "$value" ]; then
    security add-generic-password -U -s "$SERVICE" -a "$account" -w "$value" 2>/dev/null \
      || security add-generic-password -s "$SERVICE" -a "$account" -w "$value"
    echo "  ✓ Stored $account"
  else
    echo "  ⏭ Skipped $account (empty)"
  fi
}

check_entry() {
  local account="$1"
  if security find-generic-password -s "$SERVICE" -a "$account" -w >/dev/null 2>&1; then
    echo "  ✓ $account"
  else
    echo "  ✗ $account (missing)"
  fi
}

# ── Store setup functions ────────────────────────────────────────────────────

setup_primary() {
  echo ""
  echo "── Primary store (inpersonpayments.wpcomstaging.com) ──"
  echo "Used for: login, dashboard, orders, products, payments, hub menu, POS"
  echo ""
  store_entry "primary.store-url"       "Store URL (e.g. inpersonpayments.wpcomstaging.com)"
  store_entry "primary.wpcom-email"     "WP.com email"
  store_entry "primary.wpcom-password"  "WP.com password" true
  store_entry "primary.api-username"    "WordPress application password username"
  store_entry "primary.api-password"    "WordPress application password" true
}

setup_apple() {
  echo ""
  echo "── Apple sign-in store ──"
  echo "Used for: social login — Sign in with Apple test"
  echo ""
  store_entry "apple.store-url" "Store URL for Apple sign-in test"
}

setup_google() {
  echo ""
  echo "── Google sign-in store ──"
  echo "Used for: social login — Sign in with Google test"
  echo ""
  store_entry "google.store-url" "Store URL for Google sign-in test"
}

setup_passwordless() {
  echo ""
  echo "── Passwordless login store (woomobilepasswordlesslogin.wpcomstaging.com) ──"
  echo "Used for: passwordless magic link login test"
  echo ""
  store_entry "passwordless.wpcom-email"    "WP.com email for passwordless account (Mailosaur-routed)"
}

setup_not_woo() {
  echo ""
  echo "── Not-a-WooCommerce store (notawoostore.wordpress.com) ──"
  echo "Used for: login error state — site without WooCommerce"
  echo ""
  store_entry "not-woo.wpcom-email"    "WP.com email"
  store_entry "not-woo.wpcom-password" "WP.com password" true
}

setup_wrong_account() {
  echo ""
  echo "── Wrong account store ──"
  echo "Used for: login error state — account without access to the store"
  echo ""
  store_entry "wrong-account.wpcom-email"    "WP.com email"
  store_entry "wrong-account.wpcom-password" "WP.com password" true
}

setup_twofactor() {
  echo ""
  echo "── 2FA login test account ──"
  echo "Used for: testing login with two-factor authentication"
  echo "Requires a WP.com account with 2FA enabled (TOTP authenticator app)"
  echo ""
  store_entry "twofactor.store-url"      "Store URL (e.g. https://example.wpcomstaging.com)"
  store_entry "twofactor.wpcom-email"    "WP.com email (2FA-enabled account)"
  store_entry "twofactor.wpcom-password" "WP.com password" true
}

setup_mailosaur() {
  echo ""
  echo "── Mailosaur (magic link email retrieval) ──"
  echo ""
  store_entry "mailosaur.api-key" "Mailosaur API key" true
}

# ── Commands ─────────────────────────────────────────────────────────────────

do_check() {
  echo "Checking keychain entries for service: $SERVICE"
  echo ""
  echo "Primary store:"
  check_entry "primary.store-url"
  check_entry "primary.wpcom-email"
  check_entry "primary.wpcom-password"
  check_entry "primary.api-username"
  check_entry "primary.api-password"
  echo ""
  echo "Apple sign-in store:"
  check_entry "apple.store-url"
  echo ""
  echo "Google sign-in store:"
  check_entry "google.store-url"
  echo ""
  echo "Passwordless store:"
  check_entry "passwordless.wpcom-email"
  echo ""
  echo "Not-a-WooCommerce store:"
  check_entry "not-woo.wpcom-email"
  check_entry "not-woo.wpcom-password"
  echo ""
  echo "Wrong account store:"
  check_entry "wrong-account.wpcom-email"
  check_entry "wrong-account.wpcom-password"
  echo ""
  echo "2FA account:"
  check_entry "twofactor.store-url"
  check_entry "twofactor.wpcom-email"
  check_entry "twofactor.wpcom-password"
  echo ""
  echo "Mailosaur:"
  check_entry "mailosaur.api-key"
}

do_clear() {
  echo "Removing all keychain entries for service: $SERVICE"
  local accounts=(
    "primary.store-url" "primary.wpcom-email" "primary.wpcom-password"
    "primary.api-username" "primary.api-password"
    "apple.store-url"
    "google.store-url"
    "passwordless.wpcom-email"
    "not-woo.wpcom-email" "not-woo.wpcom-password"
    "wrong-account.wpcom-email" "wrong-account.wpcom-password"
    "twofactor.store-url" "twofactor.wpcom-email" "twofactor.wpcom-password"
    "mailosaur.api-key"
  )
  for acct in "${accounts[@]}"; do
    if security delete-generic-password -s "$SERVICE" -a "$acct" >/dev/null 2>&1; then
      echo "  ✓ Removed $acct"
    fi
  done
  echo "Done."
}

do_setup() {
  local store="${1:-all}"

  echo "╔══════════════════════════════════════════════════╗"
  echo "║  WooCommerce iOS Smoke Test — Keychain Setup     ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""
  echo "Credential details: $WIKI_URL"
  echo "Press Enter to skip any entry you don't need right now."

  case "$store" in
    all)
      setup_primary
      setup_apple
      setup_google
      setup_passwordless
      setup_not_woo
      setup_wrong_account
      setup_mailosaur
      ;;
    primary)        setup_primary ;;
    apple)          setup_apple ;;
    google)         setup_google ;;
    passwordless)   setup_passwordless ;;
    not-woo)        setup_not_woo ;;
    wrong-account)  setup_wrong_account ;;
    twofactor)      setup_twofactor ;;
    mailosaur)      setup_mailosaur ;;
    *)
      echo "Unknown store: $store"
      echo "Valid stores: primary, apple, google, passwordless, not-woo, wrong-account, twofactor, mailosaur"
      exit 1
      ;;
  esac

  echo ""
  echo "Done. Run with --check to verify stored entries."
}

# ── Main ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
  --check)  do_check ;;
  --clear)  do_clear ;;
  --store)  do_setup "${2:-all}" ;;
  "")       do_setup all ;;
  *)
    echo "Usage: $0 [--store <name>] [--check] [--clear]"
    echo "Stores: primary, apple, google, passwordless, not-woo, wrong-account, twofactor, mailosaur"
    exit 1
    ;;
esac
