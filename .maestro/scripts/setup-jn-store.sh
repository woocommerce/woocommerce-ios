#!/bin/bash
# Configure a Jurassic Ninja site as the Maestro lab store.
#
# Connects Jetpack to your own WordPress.com test account, creates WooCommerce
# REST API keys, and writes .maestro/.env.local. Everything site-side runs over
# SSH + wp-cli; only the two WordPress.com calls go over HTTP.
#
# Provision the site first. Either use the /setup-test-stores skill, which does
# this and then calls this script, or create one yourself at
# https://jurassic.ninja/create/?woocommerce&woocommerce-import-sample-data and
# take the admin password from the wp-admin notice the site displays.
#
# Usage:
#   setup-jn-store.sh --site <domain> [--site-password <password>]
#
# Credentials are resolved in this order, so a second run needs no arguments
# beyond --site:
#   1. command-line flags
#   2. existing values in .maestro/.env.local
#   3. an interactive prompt (never echoed, never in shell history)
#
# The WordPress.com account must not have two-factor authentication enabled:
# the OAuth password grant cannot answer a challenge non-interactively.

set -uo pipefail

SITE="" SITE_PASS="" WPCOM_USER="" WPCOM_PASS=""
ADMIN_USER="demo"
ADMIN_ID="1"
ENV_OUT=""
APP_CREDS="$HOME/.configure/woocommerce-ios/secrets/woo_app_credentials.json"

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1m[%s]\033[0m %s\n' "$1" "$2"; }
ok() { printf '  \033[32mok\033[0m %s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --site) SITE="$2"; shift 2 ;;
    --site-password) SITE_PASS="$2"; shift 2 ;;
    --wpcom-user) WPCOM_USER="$2"; shift 2 ;;
    --admin-user) ADMIN_USER="$2"; shift 2 ;;
    --admin-id) ADMIN_ID="$2"; shift 2 ;;
    --env-out) ENV_OUT="$2"; shift 2 ;;
    --app-creds) APP_CREDS="$2"; shift 2 ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$SITE" ] || die "--site is required"
command -v expect >/dev/null || die "expect is required for password-based SSH"
command -v python3 >/dev/null || die "python3 is required"
[ -f "$APP_CREDS" ] || die "app credentials not found: $APP_CREDS (run 'rake dependencies')"

if [ -z "$ENV_OUT" ]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel 2>/dev/null)" || REPO_ROOT=""
  ENV_OUT="${REPO_ROOT:-.}/.maestro/.env.local"
fi

# Read one value out of an env file, tolerating quoting and inline comments.
env_value() {
  [ -f "$ENV_OUT" ] || return 0
  ENV_FILE="$ENV_OUT" ENV_KEY="$1" python3 -c '
import os, re, shlex
path, key = os.environ["ENV_FILE"], os.environ["ENV_KEY"]
for line in open(path, encoding="utf-8"):
    m = re.match(r"\s*" + re.escape(key) + r"=(.*)$", line)
    if m:
        raw = m.group(1).strip()
        try:
            parts = shlex.split(raw, comments=True)
        except ValueError:
            parts = [raw]
        print(parts[0] if parts else "")
        break
'
}

# Secrets are prompted rather than accepted as flags: command-line arguments are
# recorded in shell history and are visible to any process that can run `ps`.
prompt_secret() {
  local __var="$1" __label="$2" __value=""
  printf '  %s: ' "$__label" >&2
  read -rs __value
  printf '\n' >&2
  printf -v "$__var" '%s' "$__value"
}

# Resolution order per value: flag, then environment, then .env.local, then an
# interactive prompt.
[ -n "$SITE_PASS" ]   || SITE_PASS="${JN_SSH_PASS:-}"
[ -n "$SITE_PASS" ]   || SITE_PASS="$(env_value MAESTRO_WOO_LAB_JETPACK_SITE_ADMIN_PASSWORD)"
[ -n "$WPCOM_USER" ]  || WPCOM_USER="${MAESTRO_WOO_LAB_WPCOM_EMAIL:-}"
[ -n "$WPCOM_USER" ]  || WPCOM_USER="$(env_value MAESTRO_WOO_LAB_WPCOM_EMAIL)"
[ -n "$WPCOM_PASS" ]  || WPCOM_PASS="${MAESTRO_WOO_LAB_WPCOM_PASSWORD:-}"
[ -n "$WPCOM_PASS" ]  || WPCOM_PASS="$(env_value MAESTRO_WOO_LAB_WPCOM_PASSWORD)"

# Prompting needs a terminal. Without one (an agent, a pipeline) the reads would
# take EOF and fail several steps later with a misleading message, so say
# exactly what is missing and how to supply it.
if [ -z "$SITE_PASS" ] || [ -z "$WPCOM_USER" ] || [ -z "$WPCOM_PASS" ]; then
  if [ ! -t 0 ]; then
    printf 'error: missing credentials and no terminal to prompt on.\n' >&2
    [ -n "$SITE_PASS" ]  || printf '  site admin password: pass --site-password or set JN_SSH_PASS\n' >&2
    [ -n "$WPCOM_USER" ] || printf '  WordPress.com account: set MAESTRO_WOO_LAB_WPCOM_EMAIL or add it to %s\n' "$(basename "$ENV_OUT")" >&2
    [ -n "$WPCOM_PASS" ] || printf '  WordPress.com password: set MAESTRO_WOO_LAB_WPCOM_PASSWORD or add it to %s\n' "$(basename "$ENV_OUT")" >&2
    printf 'Or run this script directly in a terminal and it will prompt.\n' >&2
    exit 1
  fi
  printf '\nCredentials not found in %s, enter them now.\n' "$(basename "$ENV_OUT")"
fi

[ -n "$SITE_PASS" ] || prompt_secret SITE_PASS "site admin password for $SITE"
if [ -z "$WPCOM_USER" ]; then
  printf '  WordPress.com test account email: ' >&2
  read -r WPCOM_USER
fi
[ -n "$WPCOM_PASS" ] || prompt_secret WPCOM_PASS "WordPress.com password for $WPCOM_USER"

[ -n "$SITE_PASS" ]  || die "no site admin password supplied"
[ -n "$WPCOM_USER" ] || die "no WordPress.com account supplied"
[ -n "$WPCOM_PASS" ] || die "no WordPress.com password supplied"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
chmod 700 "$WORK"

cat > "$WORK/ssh.exp" <<'EXP'
#!/usr/bin/expect -f
set timeout 120
set site [lindex $argv 0]
set pass $env(JN_SSH_PASS)
set cmd  [lindex $argv 1]
log_user 0
spawn ssh -o StrictHostKeyChecking=accept-new -o PubkeyAuthentication=no \
          -o NumberOfPasswordPrompts=1 $site@sftp.wp.com $cmd
expect {
  -re {[Pp]assword:} { send "$pass\r"; log_user 1; exp_continue }
  eof
}
EXP
chmod +x "$WORK/ssh.exp"

# The password goes through the environment rather than argv so it never
# appears in `ps` output.
remote() { JN_SSH_PASS="$SITE_PASS" "$WORK/ssh.exp" "$SITE" "$1" 2>/dev/null | tr -d '\r'; }

# Run PHP on the site. The source is base64-encoded so quoting survives the
# shell/ssh/wp-cli layers, and staged as a file because `wp eval-file -` does
# not read stdin in the wp-cli build JN ships.
remote_php() {
  local php b64
  php="${1//__ADMIN_ID__/$ADMIN_ID}"
  b64="$(printf '%s' "$php" | base64 | tr -d '\n')"
  remote "echo $b64 | base64 -d > /tmp/.jnsetup.php && wp eval-file /tmp/.jnsetup.php; rm -f /tmp/.jnsetup.php"
}

# JN provisions asynchronously and answers HTTP well before its plugins finish
# installing, so poll for the state actually needed rather than for a 200.
step 1/6 "Waiting for $SITE to finish provisioning"
DEADLINE=$(( $(date +%s) + 900 ))
STATE=""
while :; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$SITE/wp-json/" || echo 000)"
  if [ "$code" = "200" ]; then
    STATE="$(remote_php '<?php
echo "WPCLI:ok\n";
echo "WC:" . ( function_exists( "wc_rand_hash" ) ? "active" : "pending" ) . "\n";
echo "JP:" . ( class_exists( "Jetpack" ) ? "active" : "pending" ) . "\n";
echo "USER:" . ( get_user_by( "id", __ADMIN_ID__ ) ? "ok" : "MISSING" ) . "\n";')"
    printf '%s' "$STATE" | grep -q "WC:active" \
      && printf '%s' "$STATE" | grep -q "JP:active" && break
  fi
  if [ "$(date +%s)" -ge "$DEADLINE" ]; then
    printf '  last state: http=%s %s\n' "$code" "$(printf '%s' "$STATE" | tr '\n' ' ')" >&2
    die "site did not finish provisioning within 15 minutes"
  fi
  printf '  still provisioning (http=%s), waiting...\n' "$code"
  sleep 15
done
ok "site is up, WooCommerce and Jetpack active"

step 2/6 "Checking SSH and admin user"
if ! printf '%s' "$STATE" | grep -q "WPCLI:ok"; then
  printf '  remote output: %s\n' "$(printf '%s' "$STATE" | head -3 | tr '\n' ' ')" >&2
  die "could not run wp-cli over SSH. Check the site admin password."
fi
printf '%s' "$STATE" | grep -q "USER:ok" || die "no user with id $ADMIN_ID (try --admin-id)"
ok "ssh and wp-cli working, admin user id $ADMIN_ID present"


# rest_do_request runs as an authenticated admin inside wp-cli, so no cookie or
# REST nonce is needed for the two site-side Jetpack calls.
step 3/6 "Registering the site with Jetpack"
REG="$(remote_php '<?php
wp_set_current_user( __ADMIN_ID__ );
$res = rest_do_request( new WP_REST_Request( "POST", "/jetpack/v4/connection/register" ) );
$d = $res->get_data();
if ( $res->is_error() ) { echo "ERR:" . json_encode( $d ) . "\n"; exit( 1 ); }
$q = array();
parse_str( (string) parse_url( $d["authorizeUrl"], PHP_URL_QUERY ), $q );
echo "BLOGID:" . ( isset( $q["client_id"] ) ? $q["client_id"] : "" ) . "\n";')"
BLOG_ID="$(printf '%s' "$REG" | sed -n 's/^BLOGID:\([0-9][0-9]*\).*/\1/p' | head -1)"
[ -n "$BLOG_ID" ] || die "could not register the site: $(printf '%s' "$REG" | head -3)"
ok "registered, blogID=$BLOG_ID"

step 4/6 "Provisioning the user connection"
PROV="$(remote_php '<?php
wp_set_current_user( __ADMIN_ID__ );
$res = rest_do_request( new WP_REST_Request( "POST", "/jetpack/v4/remote_provision" ) );
$d = $res->get_data();
if ( $res->is_error() ) { echo "ERR:" . json_encode( $d ) . "\n"; exit( 1 ); }
echo "UID:"    . $d["user_id"] . "\n";
echo "SCOPE:"  . $d["scope"]   . "\n";
echo "SECRET:" . $d["secret"]  . "\n";')"
EXT_UID="$(printf '%s' "$PROV" | sed -n 's/^UID:\(.*\)$/\1/p'    | head -1)"
SCOPE="$(printf   '%s' "$PROV" | sed -n 's/^SCOPE:\(.*\)$/\1/p'  | head -1)"
SECRET="$(printf  '%s' "$PROV" | sed -n 's/^SECRET:\(.*\)$/\1/p' | head -1)"
[ -n "$SECRET" ] || die "remote_provision failed: $(printf '%s' "$PROV" | head -3)"
ok "scope and secret obtained (the secret is short-lived)"

# --data-urlencode is required, not stylistic: curl -d sends the body raw, so a
# plus-alias address arrives with the + decoded as a space and the grant fails
# with a misleading "Incorrect username or password".
step 5/6 "Connecting Jetpack to $WPCOM_USER"
CID="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['dotcom_app_id'])" "$APP_CREDS")"
CSEC="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['dotcom_secret'])" "$APP_CREDS")"
TOKRESP="$(curl -s -X POST https://public-api.wordpress.com/oauth2/token \
  --data-urlencode "client_id=$CID" --data-urlencode "client_secret=$CSEC" \
  -d grant_type=password \
  --data-urlencode "username=$WPCOM_USER" --data-urlencode "password=$WPCOM_PASS" \
  -d wpcom_supports_2fa=true -d with_auth_types=true)"
TOKEN="$(printf '%s' "$TOKRESP" | python3 -c "import sys,json;print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)"
if [ -z "$TOKEN" ]; then
  printf '%s\n' "$TOKRESP" | python3 -m json.tool 2>/dev/null | head -6 >&2
  die "could not obtain a WordPress.com token. The account must exist and have 2FA disabled."
fi

curl -s -o /dev/null -X POST "https://public-api.wordpress.com/wpcom/v2/sites/$BLOG_ID/jetpack-remote-connect-user" \
  -H "Authorization: Bearer $TOKEN" \
  --data-urlencode "secret=$SECRET" --data-urlencode "scope=$SCOPE" \
  --data-urlencode "external_user_id=$EXT_UID" --data-urlencode "redirect_uri=https://$SITE"

# That call can return remote_request_timeout and still have succeeded, so
# trust the site's own connection state rather than the response body.
CONN="$(remote_php '<?php
wp_set_current_user( __ADMIN_ID__ );
$d = rest_do_request( new WP_REST_Request( "GET", "/jetpack/v4/connection" ) )->get_data();
echo "USERCONNECTED:" . ( ! empty( $d["isUserConnected"] ) ? "yes" : "no" ) . "\n";
echo "OWNER:" . ( ! empty( $d["hasConnectedOwner"] ) ? "yes" : "no" ) . "\n";')"
printf '%s' "$CONN" | grep -q "USERCONNECTED:yes" || die "the Jetpack user connection did not complete"
ok "isUserConnected=yes, hasConnectedOwner=yes"

# WooCommerce exposes no REST endpoint for API keys, so insert the row the same
# way its own admin-ajax handler does.
step 6/6 "Creating WooCommerce API keys and writing $(basename "$ENV_OUT")"
KEYS="$(remote_php '<?php
$ck = "ck_" . wc_rand_hash();
$cs = "cs_" . wc_rand_hash();
global $wpdb;
$ok = $wpdb->insert( $wpdb->prefix . "woocommerce_api_keys", array(
  "user_id"         => __ADMIN_ID__,
  "description"     => "maestro-smoke",
  "permissions"     => "read_write",
  "consumer_key"    => wc_api_hash( $ck ),
  "consumer_secret" => $cs,
  "truncated_key"   => substr( $ck, -7 ),
), array( "%d", "%s", "%s", "%s", "%s", "%s" ) );
if ( ! $ok ) { echo "ERR:insert failed\n"; exit( 1 ); }
echo "CK:" . $ck . "\n" . "CS:" . $cs . "\n";')"
CK="$(printf '%s' "$KEYS" | sed -n 's/^CK:\(.*\)$/\1/p' | head -1)"
CS="$(printf '%s' "$KEYS" | sed -n 's/^CS:\(.*\)$/\1/p' | head -1)"
[ -n "$CK" ] && [ -n "$CS" ] || die "could not create API keys: $(printf '%s' "$KEYS" | head -3)"

VERIFY="$(curl -s -o /dev/null -w '%{http_code}' -u "$CK:$CS" "https://$SITE/wp-json/wc/v3/products?per_page=1")"
[ "$VERIFY" = "200" ] || die "the API keys do not authenticate (http=$VERIFY)"
ok "keys created and verified as read_write"

if [ -f "$ENV_OUT" ]; then
  BACKUP_DIR="${TMPDIR:-/tmp}"; BACKUP_DIR="${BACKUP_DIR%/}/maestro-env-backups"
  mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
  BACKUP="$BACKUP_DIR/$(basename "$ENV_OUT").$(date +%Y%m%d-%H%M%S).$$"
  cp "$ENV_OUT" "$BACKUP"; chmod 600 "$BACKUP"
  # Deliberately outside the repository: .gitignore matches "**/.env.local"
  # only, so a ".env.local.bak" sibling would not be ignored and could be
  # committed with credentials in it.
  ok "backed up the previous env file to $BACKUP"
fi

mkdir -p "$(dirname "$ENV_OUT")"
SITE="$SITE" ADMIN_USER="$ADMIN_USER" WPCOM_USER="$WPCOM_USER" WPCOM_PASS="$WPCOM_PASS" \
SITE_PASS="$SITE_PASS" CK="$CK" CS="$CS" \
python3 - "$ENV_OUT" <<'PY'
import os, re, sys, pathlib

path = pathlib.Path(sys.argv[1])
values = {
    "MAESTRO_WOO_LAB_JETPACK_STORE_URL": "https://" + os.environ["SITE"],
    "MAESTRO_WOO_LAB_WPCOM_EMAIL": os.environ["WPCOM_USER"],
    "MAESTRO_WOO_LAB_WPCOM_PASSWORD": os.environ["WPCOM_PASS"],
    "MAESTRO_WOO_LAB_JETPACK_SITE_ADMIN_USERNAME": os.environ["ADMIN_USER"],
    "MAESTRO_WOO_LAB_JETPACK_SITE_ADMIN_PASSWORD": os.environ["SITE_PASS"],
    "MAESTRO_WOO_CONSUMER_KEY": os.environ["CK"],
    "MAESTRO_WOO_CONSUMER_SECRET": os.environ["CS"],
}

def quote(value):
    if re.search(r"[\s()\"'!$&|;<>`\\#]", value):
        return "'" + value.replace("'", "'\\''") + "'"
    return value

# Rewrite in place so hand-maintained lines and comments survive.
lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
seen, out = set(), []
for line in lines:
    match = re.match(r"^([A-Z_]+)=", line)
    if match and match.group(1) in values:
        out.append(f"{match.group(1)}={quote(values[match.group(1)])}")
        seen.add(match.group(1))
    else:
        out.append(line)
missing = [k for k in values if k not in seen]
if missing:
    if out and out[-1].strip():
        out.append("")
    out.append("# Written by .maestro/scripts/setup-jn-store.sh")
    out.extend(f"{k}={quote(values[k])}" for k in missing)
path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
path.chmod(0o600)
PY
ok "wrote $ENV_OUT (mode 600)"

printf '\n\033[32mDone.\033[0m Lab store ready: https://%s (blogID %s)\n' "$SITE" "$BLOG_ID"
printf 'Verify with:\n'
printf '  .maestro/scripts/doctor.sh --app "$APP" --include-tags products --exclude-tags "" --seed --device "$UDID"\n'
