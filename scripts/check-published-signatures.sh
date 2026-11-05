#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OFFICIAL_PUBKEY="${OFFICIAL_PUBKEY:-.github/rules-official/pipelock-official.pub}"
if [[ ! -r "$OFFICIAL_PUBKEY" ]]; then
	printf 'ERROR: official public key is missing or unreadable: %s\n' "$OFFICIAL_PUBKEY" >&2
	exit 1
fi
EXPECTED_OFFICIAL_PUBKEY_SHA256="${EXPECTED_OFFICIAL_PUBKEY_SHA256:-}"
TRUSTED_OFFICIAL_PUBKEY_REF="${TRUSTED_OFFICIAL_PUBKEY_REF:-}"
using_base_pin=false
if [[ -z "$EXPECTED_OFFICIAL_PUBKEY_SHA256" && -n "$TRUSTED_OFFICIAL_PUBKEY_REF" ]]; then
	# CI supplies the fork PR's target-base SHA from GitHub's event payload.
	# Read that commit's key, never the PR worktree's key, to establish the pin.
	if ! trusted_commit="$(git rev-parse --verify --end-of-options "$TRUSTED_OFFICIAL_PUBKEY_REF^{commit}")" ||
		[[ "$trusted_commit" != "$TRUSTED_OFFICIAL_PUBKEY_REF" ]]; then
		printf 'ERROR: trusted official key reference must be an available exact commit SHA\n' >&2
		exit 1
	fi
	if ! trusted_digest="$(git show "$trusted_commit:.github/rules-official/pipelock-official.pub" | sha256sum)"; then
		printf 'ERROR: cannot read the official public key from the trusted base commit\n' >&2
		exit 1
	fi
	read -r EXPECTED_OFFICIAL_PUBKEY_SHA256 _ <<< "$trusted_digest"
	using_base_pin=true
fi
if [[ -z "$EXPECTED_OFFICIAL_PUBKEY_SHA256" ]]; then
	printf 'ERROR: EXPECTED_OFFICIAL_PUBKEY_SHA256 is required\n' >&2
	exit 1
fi
read -r actual_pubkey_sha256 _ < <(sha256sum "$OFFICIAL_PUBKEY")
if [[ "$actual_pubkey_sha256" != "$EXPECTED_OFFICIAL_PUBKEY_SHA256" ]]; then
	printf 'ERROR: official public key digest mismatch for %s\n' "$OFFICIAL_PUBKEY" >&2
	exit 1
fi

KEYSTORE_DIR="$(mktemp -d)"
trap 'rm -rf "$KEYSTORE_DIR"' EXIT

mkdir -p "$KEYSTORE_DIR/agents/pipelock-official"
cp "$OFFICIAL_PUBKEY" "$KEYSTORE_DIR/agents/pipelock-official/id_ed25519.pub"

status=0

while IFS= read -r bundle_dir; do
	bundle="$(basename "$bundle_dir")"
	bundle_file="published/$bundle/bundle.yaml"
	sig_file="$bundle_file.sig"

	if [[ ! -f "$bundle_file" ]]; then
		printf 'ERROR: %s is missing\n' "$bundle_file" >&2
		status=1
		continue
	fi
	if [[ ! -f "$sig_file" ]]; then
		printf 'ERROR: %s is missing; official bundles must be signed before merge\n' "$sig_file" >&2
		status=1
		continue
	fi

	original_bundle="$KEYSTORE_DIR/$bundle.bundle.yaml"
	cp "$bundle_file" "$original_bundle"
	if ! BUNDLE_NAME="$bundle" make compile >/dev/null; then
		cp "$original_bundle" "$bundle_file"
		printf 'ERROR: failed to compile rules/%s\n' "$bundle" >&2
		status=1
		continue
	fi
	if ! cmp -s "$bundle_file" "$original_bundle"; then
		printf 'ERROR: %s is not up to date with rules/%s; run BUNDLE_NAME=%s make compile\n' "$bundle_file" "$bundle" "$bundle" >&2
		diff -u --label "$bundle_file (before compile)" --label "$bundle_file (after compile)" "$original_bundle" "$bundle_file" >&2 || true
		cp "$original_bundle" "$bundle_file"
		status=1
	fi

	if ! pipelock verify "$bundle_file" --keystore "$KEYSTORE_DIR" --agent pipelock-official >/dev/null; then
		printf 'ERROR: %s does not verify against %s; sign it with the official rules key before merge\n' "$sig_file" "$OFFICIAL_PUBKEY" >&2
		status=1
	fi
done < <(find rules -mindepth 1 -maxdepth 1 -type d | sort)

if [[ "$using_base_pin" == true && "$status" == 0 ]]; then
	# Fork runs also require the independent official key embedded in the pinned
	# Pipelock CLI. A compromised base key alone cannot establish signing trust.
	python3 - "$OFFICIAL_PUBKEY" "$KEYSTORE_DIR" <<'PY'
import base64
import pathlib
import shutil
import sys

key_lines = pathlib.Path(sys.argv[1]).read_text().strip().splitlines()
if len(key_lines) != 2 or key_lines[0] != "pipelock-ed25519-public-v1":
    raise SystemExit("ERROR: unsupported official public key encoding")
key = base64.b64decode(key_lines[1], validate=True)
if len(key) != 32:
    raise SystemExit("ERROR: official Ed25519 public key must contain 32 bytes")
root = pathlib.Path(sys.argv[2])
(root / "official-root.yaml").write_text(
    "rules:\n  trust_embedded_keys: true\n  trusted_keys: []\n"
)
for source in sorted(pathlib.Path("rules").iterdir()):
    if not source.is_dir():
        continue
    stage = root / "official-root" / source.name
    stage.mkdir(parents=True)
    for name in ("bundle.yaml", "bundle.yaml.sig"):
        shutil.copyfile(pathlib.Path("published") / source.name / name, stage / name)
    (stage / "bundle.lock").write_text(
        "unsigned: false\nsigner_fingerprint: " + key.hex() + "\n"
    )
PY
	if ! pipelock rules verify --config "$KEYSTORE_DIR/official-root.yaml" \
		--rules-dir "$KEYSTORE_DIR/official-root"; then
		printf 'ERROR: fork bundles must verify against the pinned CLI official keyring\n' >&2
		status=1
	fi
fi

exit "$status"
