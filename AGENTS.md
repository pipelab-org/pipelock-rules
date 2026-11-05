# Pipelock Rules contributor guide

This repository publishes signed detection-rule bundles for [Pipelock](https://github.com/pipelab-org/pipelock). Rules extend its data loss prevention (DLP), prompt-injection and MCP tool-poisoning scanners.

## Repository contracts

- Rule definitions are YAML. Build and validation tooling uses Bash, Go and Python.
- Patterns use Go's regexp package with RE2 syntax. Lookaround and backreferences aren't supported. Pipelock applies case-insensitive matching automatically.
- Published bundles use YAML with detached Ed25519 signatures. The existing pipelock-community and healthcare-phi-pii bundles use `format_version: 1`. New bundles use `format_version: 2`; existing bundles migrate only with coordinated content, signature, distribution and compatibility updates.
- `CONTRIBUTING.md` defines rule structure, naming, quality requirements and the complete change sequence. `compatibility/contract.yaml` binds the maintained bundles to their published bytes and recorded reader compatibility.

## Setup and validation

See [CONTRIBUTING.md](CONTRIBUTING.md#prerequisites) for prerequisites. The main tools are GNU Make, Bash, Go, Python 3 and a Pipelock CLI on `PATH`. YAML lint uses the pinned dependencies in `.github/requirements-yamllint.txt`.

Preflight checks the CLI's parsed `major.minor.patch` version against `tested_through_pipelock` in `compatibility/contract.yaml`. Installing the latest Pipelock version isn't a substitute for matching that recorded version. CI builds the commit pinned in `.github/workflows/ci.yaml` and checks its reported version.

```bash
# Compile the default pipelock-community bundle
make compile

# Compile and validate the selected bundle with Pipelock
make validate

# Test compiled patterns against their fixtures
make test-fixtures

# Compile a non-default bundle
BUNDLE_NAME=healthcare-phi-pii make compile

# Test the non-default bundle's compiled patterns
BUNDLE_NAME=healthcare-phi-pii make test-fixtures

# Regenerate diagrams and the rule catalog from compiled bundles
make diagrams

# Check generated diagrams and the catalog without rewriting them
make check-diagrams

# Check diagrams, brand assets, compatibility, schemas and fixtures
make preflight
```

Compile changed bundles before regenerating their diagrams. Keep compatibility metadata current, regenerate assets and `docs/rule-catalog.md`, then run preflight. Generated-output checks detect stale committed files; they don't regenerate them.

Preflight covers every bundle listed in `PREFLIGHT_BUNDLES`. YAML lint, version-history checks, published-signature verification and separate security workflows also run in CI. A passing preflight doesn't replace those checks.

The diagram generator needs only the Python standard library. Changes to rule counts, bundle versions, CI's Pipelock version, signing-key pins or relevant CI job names can affect generated claims. Brand assets come from `assets/mark.svg` through `scripts/render_brand.py`. `make brand` needs Inkscape and ImageMagick to regenerate vectors, rasters and provenance; `make check-brand` checks the committed output.

## Layout

```text
rules/<bundle>/<type>/       One YAML source file per rule
fixtures/<bundle>/<type>/    True-positive and false-positive examples
published/<bundle>/          Compiled bundle.yaml and detached bundle.yaml.sig
compatibility/              Byte-bound bundle and reader-format contracts
docs/rule-catalog.md         Generated list of published rules
assets/                     Generated diagrams and brand assets; mark.svg is the source mark
scripts/compile.sh          Concatenates source rules and emits the bundle header
scripts/test-fixtures.sh    Runs the Go fixture checker
```

The compiler preserves source indentation and emits dlp, injection and tool-poison directories in that order, with files sorted by filename. Use the canonical YAML layout in `CONTRIBUTING.md`. The fixture checker reads a strict single-line representation of IDs, status and regex fields; valid YAML alone doesn't establish that the fixture tooling can read a rule.

## Rules and fixtures

Follow [CONTRIBUTING.md](CONTRIBUTING.md) for rule structure, version increases, compatibility metadata, validation and submission. It also describes the integration needed for a new bundle.

- Rule IDs are unique within a bundle, lowercase and hyphenated, with a type prefix followed by the provider or technique. Keep one rule per source YAML file.
- Prefer specific prefixes and suitable minimum match lengths. Keep patterns readable, such as `[A-Za-z0-9]` instead of `\w` where that expresses the intended format. Include realistic surrounding text in fixtures.
- Stable rules need primary-source references and at least one true-positive and one false-positive fixture string. Experimental rules need a true-positive fixture and an explanation; they may also carry false-positive fixtures.
- Fixture filenames use `<rule-id>-true-positive.txt` and `<rule-id>-false-positive.txt`. Each non-empty line is a test string; there's no comment syntax.
- Positive examples must match and negative examples must not match. Supplied examples establish those cases, not every possible input.
- Use synthetic credentials and fabricated personal or health data. Public fixtures, issues and pull requests mustn't contain live secrets or identifying records.
- `scan_field` is used only for tool-poison rules, selecting name or description. DLP and injection rules omit it.

## Signing and review

Official published bundles are signed with the Pipelock official rules key. Only maintainers with signing-key access sign them. Contributors don't need that access. Maintainers add or refresh `bundle.yaml.sig` on the pull request before merge when published bundle bytes change.

CI checks that committed published bundles match their source rules and verifies their signatures against `.github/rules-official/pipelock-official.pub`. These checks remain required when a contributor can't sign locally. Maintainers review pull requests; CI and review requirements in `CONTRIBUTING.md` apply before merge.

Report vulnerabilities through the private advisory process in [SECURITY.md](SECURITY.md). Ordinary rule-quality reports can use public issues with synthetic reproduction data.
