#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# These cases isolate key-pin selection from compilation and signature checks.
mkdir -p "$TMP_DIR/scripts" "$TMP_DIR/.github/rules-official" "$TMP_DIR/rules"
cp "$ROOT_DIR/scripts/check-published-signatures.sh" "$TMP_DIR/scripts/"
cp "$ROOT_DIR/.github/rules-official/pipelock-official.pub" "$TMP_DIR/.github/rules-official/"
cd "$TMP_DIR"
git init -q
git add .github/rules-official/pipelock-official.pub
git -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'Seed public-key fixture'
base="$(git rev-parse HEAD)"
read -r expected _ < <(sha256sum .github/rules-official/pipelock-official.pub)

expect_pass() {
	if ! env EXPECTED_OFFICIAL_PUBKEY_SHA256="$1" TRUSTED_OFFICIAL_PUBKEY_REF="$2" \
		bash scripts/check-published-signatures.sh >case.log 2>&1; then
		cat case.log >&2
		printf 'FAIL: %s\n' "$3" >&2
		exit 1
	fi
}

expect_fail() {
	if env EXPECTED_OFFICIAL_PUBKEY_SHA256="$1" TRUSTED_OFFICIAL_PUBKEY_REF="$2" \
		bash scripts/check-published-signatures.sh >case.log 2>&1; then
		printf 'FAIL: %s unexpectedly succeeded\n' "$3" >&2
		exit 1
	fi
}

expect_pass "$expected" '' 'configured digest'
expect_pass '' "$base" 'trusted base pin when configuration is unavailable'
expect_fail '' '' 'missing configuration and trusted base'
expect_fail '' HEAD 'symbolic reference instead of exact base commit'
expect_fail '' 0000000000000000000000000000000000000000 'unavailable base commit'
printf 'untrusted replacement public key\n' >.github/rules-official/pipelock-official.pub
expect_fail '' "$base" 'worktree key substitution with unavailable configuration'
expect_fail "$expected" "$base" 'worktree key substitution with configured digest'
printf 'published key pin: PASS (configured pin, trusted-base pin, missing input and substitution refusals)\n'
