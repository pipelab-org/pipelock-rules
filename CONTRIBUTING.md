# Contributing

Rules are welcome via pull request. Each rule must meet the quality bar below before merge.

## Prerequisites

- GNU Make and Bash for build targets and scripts, plus the standard command-line utilities used by those scripts.
- Go for the fixture checker and its tests.
- Python 3 for diagram generation and compatibility checks.
- Pipelock on `PATH` for validation and compatibility tests. Preflight requires its parsed `major.minor.patch` version to match `tested_through_pipelock` in `compatibility/contract.yaml`. A newer version core fails that check. CI builds the Pipelock commit pinned in `.github/workflows/ci.yaml` and checks the reported version.
- `yamllint` for the separate YAML lint check. Install its pinned dependencies with `pip install --require-hashes -r .github/requirements-yamllint.txt` in a Python environment you manage.
- A pattern supported by Go's regexp package (RE2 syntax, without lookaround or backreferences).

Changing brand assets also needs Inkscape and ImageMagick (`magick` or `convert`). `make check-brand` checks committed assets without rendering them; `make brand` regenerates vectors, rasters and their provenance together.

## Contributing Rules to an Existing Bundle

1. Create a YAML file in the appropriate directory:
   - `rules/<bundle-name>/dlp/` for credential, secret, PHI, or PII detection
   - `rules/<bundle-name>/injection/` for prompt injection detection
   - `rules/<bundle-name>/tool-poison/` for MCP tool description poisoning

2. Follow the naming convention:
   - DLP: `{provider}.yaml` or `{provider}-{credential-type}.yaml`
   - Injection: `{technique}.yaml`
   - Tool-poison: `{behavior}.yaml`

3. Add fixtures under `fixtures/<bundle-name>/<type>/`. Each non-empty line is test data, including lines that look like comments. Every rule needs a `<rule-id>-true-positive.txt` file with at least one matching example. Stable rules also need a `<rule-id>-false-positive.txt` file with at least one nonmatching example; experimental rules may include that file too. Use synthetic, nonfunctional credentials and fabricated personal or health data. Issues, fixtures and PR descriptions are public.

4. Increase the selected bundle's version in `scripts/compile.sh` when its source rules change. CI also preserves the bytes associated with an already published bundle name and version; published content changes need a new version. Editing the generated header alone doesn't survive compilation.

5. Compile the selected bundle, then update its version and `bundle_sha256` in `compatibility/contract.yaml` to match `published/<bundle-name>/bundle.yaml`. `sha256sum` prints the digest.

6. Run the selected bundle's fixture and schema checks and CI's YAML lint command:

   ```bash
   BUNDLE_NAME=<bundle-name> make compile
   BUNDLE_NAME=<bundle-name> make test-fixtures
   BUNDLE_NAME=<bundle-name> make validate
   yamllint -d '{extends: default, rules: {line-length: {max: 400}, document-start: disable, truthy: disable, empty-lines: {max: 1}}}' published/<bundle-name>/bundle.yaml
   ```

7. Run `make diagrams` after the compiled bundles and compatibility metadata are current. Include the regenerated `assets/` files and `docs/rule-catalog.md`, then run `make preflight`. Preflight checks diagrams, brand assets, compatibility, schema validation and fixtures for the maintained bundles. YAML lint, version-history checks and signature verification are separate CI checks.

8. Open a pull request with the source, fixtures, compiled bundle, compatibility metadata and generated documentation. Name any validation prerequisite you couldn't run. Maintainers add or refresh the official bundle signature on the PR before merge; contributors don't need signing-key access. CI must pass before merge.

`pipelock-community` is the default bundle, so existing commands such as `make compile` still target it.

## Contributing a New Bundle

Open an issue first so naming, scope, signing-key alignment, and maintenance ownership can be confirmed before code is added. New bundles must use `format_version: 2`, which requires Pipelock v2.2.0 or later. The existing `pipelock-community` and `healthcare-phi-pii` bundles remain on `format_version: 1` until their bundle content, signatures, served copies, and compatibility checks can migrate together.

A new bundle needs compiler, validation and CI integration as well as rule files. Add a bundle-specific case and header emission in `scripts/compile.sh` that produces the complete format-2 header shown below. `make compile` overwrites the selected `published/<bundle-name>/bundle.yaml`; it doesn't preserve a hand-edited header. Add the bundle to `PREFLIGHT_BUNDLES` in `Makefile`, the compatibility-floor and YAML-lint matrices in `.github/workflows/ci.yaml`, and the installer cases in `scripts/test-compatibility-install.sh`. List its `pipelock rules install <bundle-name>` command in the README install section, because `make check-diagrams` rejects a published bundle with no install instructions. Add its byte-bound entry and a format-2 reader-schema identity with a pinned schema digest to `compatibility/contract.yaml`. Extend compatibility tests for that identity. Compile the bundle, run fixture and schema checks, regenerate diagrams and the catalog, and run preflight. Maintainers sign the resulting published bundle on the PR before merge.

The existing validation target installs an unsigned copy under a temporary name. Format-2 bundles need signed validation that preserves their identity, so that path also needs integration before a new bundle can pass preflight.

The compiled header for a new bundle has this shape:

```yaml
format_version: 2
name: example-community-rules
version: "2026.08.0"
author: example-security
description: "Detection rules for Example Security"
homepage: "https://example.com/security/rules"
min_pipelock: "2.2.0"
license: "Apache-2.0"
tier: community
key_id: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
monotonic_version: 1
published_at: "2026-08-25T00:00:00Z"
expires_at: "2027-08-25T00:00:00Z"
required_features:
  - dlp

rules:
  # Rule entries follow the format below.
```

`key_id` is the signing public key as 64 lowercase hex characters. Replace the placeholder with the bundle's signing public key before signing. See the [bundle signing guide](https://github.com/pipelab-org/pipelock/blob/main/docs/rules.md#signing-your-bundle).

`tier` declares the bundle's trust tier. `required_features` lists the Pipelock engine features that every rule in the bundle needs. Increase `monotonic_version` for each published bundle version so Pipelock can reject rollbacks. Write `published_at` and `expires_at` as UTC RFC 3339 timestamps.

New bundles should use this layout:

```text
rules/<bundle-name>/<type>/<rule-file>.yaml
fixtures/<bundle-name>/<type>/<rule-id>-true-positive.txt
fixtures/<bundle-name>/<type>/<rule-id>-false-positive.txt
published/<bundle-name>/bundle.yaml
```

## Rule YAML Format

```yaml
  - id: dlp-example-api-key
    type: dlp
    status: stable
    name: "Example API Key"
    description: "Detects Example.com API keys"
    severity: critical
    confidence: high
    references:
      - "https://example.com/docs/api-keys"
    tags:
      - "provider:example"
      - "owasp-llm:LLM06"
    pattern:
      regex: 'ex_[A-Za-z0-9]{32,}'
```

Use this indentation in source rule files: two spaces before `- id:`, four before rule fields and six before pattern fields. The compiler concatenates these files without reindenting them. The fixture checker and diagram generator read a canonical line format: keep `id` and `status` unquoted, and `regex` single-quoted on one line, with no trailing comments on those lines. Escape an apostrophe inside a single-quoted YAML value by doubling it. Rule IDs are unique within a bundle and use the rule type followed by the provider or technique, in lowercase with hyphens. `type` is `dlp`, `injection` or `tool-poison`; `status` is `stable` or `experimental`; `severity` is `critical`, `high`, `medium` or `low`; `confidence` is `high`, `medium` or `low`. `references` lists primary sources. Only tool-poison rules add `scan_field` under `pattern`, set to `name` or `description`. DLP and injection rules omit it.

## Quality Bar

### Stable rules

- At least one true-positive fixture string that matches the regex
- At least one false-positive fixture string that does NOT match
- A primary source citation (vendor docs, research paper, or security advisory)
- RE2-compatible regex (validated by `make validate`)
- Minimum match length of 8+ characters to reduce false positives

### Experimental rules

- At least one true-positive fixture
- RE2-compatible regex
- A brief note in the description explaining why it's experimental

## Regex Guidelines

- Use RE2 syntax (no lookahead/lookbehind, no backreferences)
- Prefer specific prefixes over broad character classes (`pplx-[A-Za-z0-9]{16,}` is better than `[a-z]{4}-[A-Za-z0-9]+`)
- Set minimum match lengths to reduce false positives
- Test against realistic surrounding text, not just isolated tokens
- Case-insensitive matching is applied automatically by pipelock (`(?i)` prefix)
- Keep regexes readable: prefer `[A-Za-z0-9]` over `\w`.
- Put one rule in each YAML file.

## Rule Types

| Type | `type` value | What it detects | `scan_field` |
|------|-------------|-----------------|-------------|
| DLP | `dlp` | Credentials and secrets in outbound traffic | N/A |
| Injection | `injection` | Prompt injection in fetched content and tool responses | N/A |
| Tool-poison | `tool-poison` | Hidden instructions in MCP tool descriptions | `name` or `description` |

## Pull Requests

- PRs are squash-merged into `main`
- CI must pass: bundle validation, fixture tests, YAML lint
- Official published bundles must be current and signed before merge. Contributors
  don't need signing-key access; maintainers add or refresh `bundle.yaml.sig`
  during review when a PR changes `published/<bundle>/bundle.yaml`.
- All review threads must be resolved before merge

## Development Workflow

Fork the repository, create a branch such as `feat/new-rule-name` or `fix/rule-id`, and follow [Contributing Rules to an Existing Bundle](#contributing-rules-to-an-existing-bundle) before opening a pull request.

## Contributor License Agreement

By submitting a pull request, you agree that your contributions are licensed under the [Apache License 2.0](LICENSE), the same license as this project.

## Security

Report exploitable detection bypasses, resource-exhaustion behavior and other vulnerabilities through [Pipelock Security Advisories](https://github.com/pipelab-org/pipelock/security/advisories). Use public issues for ordinary rule-quality problems that don't disclose an exploitable vulnerability. See [SECURITY.md](SECURITY.md) for reporting details and safe reproduction data.
