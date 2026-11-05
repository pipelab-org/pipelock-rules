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

# Let the generic keystore verification succeed, while keeping the real CLI for
# verification against its embedded key. One bundle must exist: the embedded-key
# step refuses to pass on none.
mkdir -p rules/healthcare-phi-pii published/healthcare-phi-pii bin
cp "$ROOT_DIR/published/healthcare-phi-pii/bundle.yaml" published/healthcare-phi-pii/
cp "$ROOT_DIR/published/healthcare-phi-pii/bundle.yaml.sig" published/healthcare-phi-pii/
TEST_REAL_PIPELOCK="$(command -v pipelock)"
export TEST_REAL_PIPELOCK
cat >bin/pipelock <<'SH'
#!/usr/bin/env bash
if [[ "$1" == verify ]]; then
	exit 0
fi
exec "$TEST_REAL_PIPELOCK" "$@"
SH
cat >bin/make <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x bin/pipelock bin/make
export PATH="$TMP_DIR/bin:$PATH"

expect_pass() {
	if ! env EXPECTED_OFFICIAL_PUBKEY_SHA256="$1" TRUSTED_OFFICIAL_PUBKEY_REF="$2" \
		bash scripts/check-published-signatures.sh >case.log 2>&1; then
		cat case.log >&2
		printf 'FAIL: %s\n' "$3" >&2
		exit 1
	fi
}

# Each refusal must fail for its own reason, so a different guard can't mask it.
expect_fail() {
	if env EXPECTED_OFFICIAL_PUBKEY_SHA256="$1" TRUSTED_OFFICIAL_PUBKEY_REF="$2" \
		bash scripts/check-published-signatures.sh >case.log 2>&1; then
		printf 'FAIL: %s unexpectedly succeeded\n' "$3" >&2
		exit 1
	fi
	if ! grep -qF -- "$4" case.log; then
		cat case.log >&2
		printf 'FAIL: %s failed without the expected reason: %s\n' "$3" "$4" >&2
		exit 1
	fi
}

expect_pass "$expected" '' 'configured digest'
expect_pass '' "$base" 'trusted base pin when configuration is unavailable'
expect_fail '' '' 'missing configuration and trusted base' 'EXPECTED_OFFICIAL_PUBKEY_SHA256 is required'
expect_fail '' HEAD 'symbolic reference instead of exact base commit' 'exact commit SHA'
expect_fail '' 0000000000000000000000000000000000000000 'unavailable base commit' 'exact commit SHA'
expect_fail 0000000000000000000000000000000000000000000000000000000000000000 "$base" \
	'configured digest must stay primary over the trusted base' 'digest mismatch'
git rm -q --cached .github/rules-official/pipelock-official.pub
git -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'Drop public-key fixture'
expect_fail '' "$(git rev-parse HEAD)" 'trusted base commit without an official key' 'cannot read the official public key'
printf 'untrusted replacement public key\n' >.github/rules-official/pipelock-official.pub
expect_fail '' "$base" 'worktree key substitution with unavailable configuration' 'digest mismatch'
expect_fail "$expected" "$base" 'worktree key substitution with configured digest' 'digest mismatch'

# Isolate the independent keyring check against the real embedded key.
cp "$ROOT_DIR/.github/rules-official/pipelock-official.pub" .github/rules-official/
expect_pass '' "$base" 'valid official bundle with an independent embedded keyring'
# The CLI skips hidden and .bak bundle dirs and succeeds on none, so refuse both.
mkdir -p rules/x.bak published/x.bak
cp published/healthcare-phi-pii/bundle.yaml* published/x.bak/
expect_fail '' "$base" 'bundle name the CLI would skip' 'is skipped by rules verify'
rm -rf rules/x.bak published/x.bak
mv rules/healthcare-phi-pii "$TMP_DIR/stash"
expect_fail '' "$base" 'no bundles for the embedded keyring check' 'no bundles staged'
mv "$TMP_DIR/stash" rules/healthcare-phi-pii
printf '\nmodified fixture bytes\n' >>published/healthcare-phi-pii/bundle.yaml
expect_fail '' "$base" 'embedded keyring rejects bytes even when keystore verification passes' \
	'fork bundles must verify against the pinned CLI official keyring'
printf 'published key pin: PASS (configured pin, trusted-base pin, missing input and substitution refusals)\n'
