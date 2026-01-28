#!/usr/bin/env bash
set -euo pipefail

# Utility: Get a tenant token via SIWE.
#
# DX principles:
# - PRIVATE_KEY is the default
# - ADDRESS is optional; if omitted we derive it from signer.
# - Foundry --account is supported but only if explicitly chosen.
#
# Required env (typically from .env):
#   API_URL   (e.g. https://api.example.dev)
#   DOMAIN    (e.g. user-panel.example.dev)
#
# Signer inputs (choose one):
#   PRIVATE_KEY=<0x...>              
#   --private-key <0x...>
#   --account <foundry-account-name> (explicit opt-in)
#
# Optional:
#   ADDRESS=<0x...> (if omitted, derived from signer)
#   --print-only    (prints msg + signature + token response debugging)
#   -h|--help

API_URL="${API_URL:-}"
DOMAIN="${DOMAIN:-}"

ACCOUNT_NAME="${ACCOUNT_NAME:-}"
PRIVATE_KEY="${PRIVATE_KEY:-}"
ADDRESS="${ADDRESS:-}"

PRINT_ONLY="false"

usage() {
  cat <<EOF
Usage:
  $0 [--private-key <0x...> | --account <name>] [<0xAddress>]

Examples (recommended):
  PRIVATE_KEY=0xabc... $0
  PRIVATE_KEY=0xabc... $0 0xYourAddress
  $0 --private-key 0xabc...               # derives address automatically

Examples (Foundry account, explicit opt-in):
  $0 --account dev                       # derives address automatically
  $0 --account dev 0xYourAddress

Required env (typically from .env):
  API_URL   (e.g. https://api.example.dev)
  DOMAIN    (e.g. user-panel.example.dev)

Notes:
  - If <0xAddress> is omitted, we derive it from the signer.
  - If both ADDRESS and signer are provided, we sanity-check they match.

EOF
}

fail() {
  echo "Error: $1" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "'$1' not found in PATH"
}

normalize_addr() {
  # Lowercase for comparison
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# --- parse args ------------------------------------------------------------

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --private-key|--pk)
      [[ $# -ge 2 ]] || { echo "Error: --private-key requires a value" >&2; usage; exit 1; }
      PRIVATE_KEY="$2"
      ACCOUNT_NAME=""  # avoid ambiguity
      shift 2
      ;;
    --account)
      [[ $# -ge 2 ]] || { echo "Error: --account requires a value" >&2; usage; exit 1; }
      ACCOUNT_NAME="$2"
      PRIVATE_KEY=""   # avoid ambiguity
      shift 2
      ;;
    --print-only)
      PRINT_ONLY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
      ;;
    -*)
      echo "Error: unknown flag '$1'" >&2
      usage
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# Positional address overrides env ADDRESS
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
  ADDRESS="${POSITIONAL[0]}"
fi

# --- validate env/deps -----------------------------------------------------

[[ -n "$API_URL" ]] || fail "API_URL is not set. Add it to your .env (and export it) or pass it in your environment."
[[ -n "$DOMAIN"  ]] || fail "DOMAIN is not set. Add it to your .env (and export it) or pass it in your environment."

need_cmd curl
need_cmd jq
need_cmd cast
need_cmd sed

# --- signer selection ------------------------------------------------------

SIGN_MODE=""
if [[ -n "$PRIVATE_KEY" ]]; then
  SIGN_MODE="private-key"
elif [[ -n "$ACCOUNT_NAME" ]]; then
  SIGN_MODE="account"
else
  cat >&2 <<EOF
Error: No signer provided.

Recommended (works everywhere):
  PRIVATE_KEY=0xabc... $0

Or:
  $0 --private-key 0xabc...

If you specifically want a Foundry account:
  $0 --account <name>

EOF
  exit 1
fi

# Derive signer address
SIGNER_ADDR=""
if [[ "$SIGN_MODE" == "private-key" ]]; then
  SIGNER_ADDR="$(cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null || true)"
  [[ -n "$SIGNER_ADDR" ]] || fail "Could not derive address from PRIVATE_KEY."
else
  SIGNER_ADDR="$(cast wallet address --account "$ACCOUNT_NAME" 2>/dev/null || true)"
  [[ -n "$SIGNER_ADDR" ]] || fail "Could not derive address from Foundry account '$ACCOUNT_NAME'. (Is it configured in cast?)"
fi

# If ADDRESS omitted, use signer address
if [[ -z "$ADDRESS" ]]; then
  ADDRESS="$SIGNER_ADDR"
fi

# Sanity-check ADDRESS matches signer address
if [[ "$(normalize_addr "$SIGNER_ADDR")" != "$(normalize_addr "$ADDRESS")" ]]; then
  cat >&2 <<EOF
Error: signer address does not match requested ADDRESS.
  Requested ADDRESS: $ADDRESS
  Signer ADDRESS:    $SIGNER_ADDR

Fix:
  - omit the ADDRESS arg/env and we’ll use the signer address automatically, or
  - provide a signer that matches the ADDRESS you want.

EOF
  exit 1
fi

# --- SIWE flow -------------------------------------------------------------

echo "Requesting SIWE message..."
RAW_MESSAGE="$(
  curl -sS -X POST "$API_URL/api/siwe-messages" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg address "$ADDRESS" --arg domain "$DOMAIN" '{address: $address, domain: $domain}')" \
  | jq -r '.msg'
)"

if [[ -z "$RAW_MESSAGE" || "$RAW_MESSAGE" == "null" ]]; then
  fail "could not retrieve SIWE message (.msg was empty/null). Check API_URL/DOMAIN and server logs."
fi

# Convert literal "\n" sequences into actual newlines
MSG="$(printf '%s' "$RAW_MESSAGE" | sed 's/\\n/\n/g')"

echo "Signing SIWE message with cast ($SIGN_MODE) for $ADDRESS ..."
if [[ "$SIGN_MODE" == "private-key" ]]; then
  SIGNATURE="$(cast wallet sign --private-key "$PRIVATE_KEY" "$MSG")"
else
  echo "  account: $ACCOUNT_NAME"
  SIGNATURE="$(cast wallet sign --account "$ACCOUNT_NAME" "$MSG")"
fi

[[ -n "$SIGNATURE" ]] || fail "signature came back empty"

echo "Exchanging signature for token..."
LOGIN_JSON="$(
  curl -sS -X POST "$API_URL/api/auth/login/crypto-native" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg sig "$SIGNATURE" --arg msg "$MSG" '{signature: $sig, message: $msg}')" \
)"

TENANT_TOKEN="$(printf '%s' "$LOGIN_JSON" | jq -r '.token')"
if [[ -z "$TENANT_TOKEN" || "$TENANT_TOKEN" == "null" ]]; then
  if [[ "$PRINT_ONLY" == "true" ]]; then
    echo "---- DEBUG ----" >&2
    echo "ADDRESS=$ADDRESS" >&2
    echo "SIGN_MODE=$SIGN_MODE" >&2
    echo "SIWE_MSG(raw)=$RAW_MESSAGE" >&2
    echo "SIGNATURE=$SIGNATURE" >&2
    echo "LOGIN_JSON=$LOGIN_JSON" >&2
    echo "---- /DEBUG ----" >&2
  fi
  fail "could not retrieve token (.token was empty/null). Check server response above (use --print-only)."
fi

echo "TOKEN: $TENANT_TOKEN"
