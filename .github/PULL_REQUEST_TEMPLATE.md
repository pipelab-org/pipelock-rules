## Summary

Brief description of what this PR adds or changes.

## Rules Added/Changed

| Rule ID | Type | Status | Description |
|---------|------|--------|-------------|
| | | | |

## Bundle

- [ ] `pipelock-community`
- [ ] `healthcare-phi-pii`
- [ ] Other:

## Testing

- [ ] `BUNDLE_NAME=<bundle-name> make compile` succeeds
- [ ] `BUNDLE_NAME=<bundle-name> make test-fixtures` passes
- [ ] `BUNDLE_NAME=<bundle-name> make validate` passes
- [ ] Bundle version increased and `compatibility/contract.yaml` updated for each changed published bundle
- [ ] Compiled YAML passes the `yamllint` command in `CONTRIBUTING.md`
- [ ] Regenerated diagrams and `docs/rule-catalog.md` are included where affected
- [ ] `make preflight` passes, or the unavailable prerequisite is named here
- [ ] Maintainer signing completed before merge if this changes `published/<bundle>/bundle.yaml`

## Checklist

- [ ] RE2-compatible regex (no lookahead/lookbehind)
- [ ] True-positive fixture added
- [ ] Fixtures use synthetic credentials and fabricated personal or health data only
- [ ] False-positive fixture added (stable rules)
- [ ] Primary source citation included (stable rules)
- [ ] Rule ID follows naming convention (`{type}-{provider/technique}`)
