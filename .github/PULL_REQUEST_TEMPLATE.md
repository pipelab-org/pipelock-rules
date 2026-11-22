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

## Hub contributions

For a [Hub-only change](https://github.com/pipelab-org/pipelock-rules/blob/main/docs/hub-contributions.md), fill in the admission run URL and the full pull request head SHA. The run must report `ADMIT` from site `main` for that exact SHA. Run admission again after any change to the head or to this description.

- Admission run URL
- Pull request head SHA

Hub admission requires this box to be checked. Leave the wording unchanged.

- [ ] I agree to the PipeLab Terms of Service (https://pipelab.org/terms/) and Hub policies (https://pipelab.org/hub/policies/). I have the rights to submit this material, and the pack files keep their declared license.
