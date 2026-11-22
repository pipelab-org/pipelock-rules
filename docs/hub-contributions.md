# Hub contributions

The `hub/` directory holds listing metadata and other contribution data for the PipeLab Hub. The official bundle build reads its rules from `rules/` and publishes signed bytes under `published/`.

Keep changes under `hub/` in their own pull request. Check the contributor terms box in the pull request template without changing its wording. Admission refuses a Hub pull request until that box is checked. For an official pack, add the listing under `hub/listings/bundles/` and bind it to the digest of the exact bundle served by the PipeLab registry. Leave edits to the signed bundle and its fixtures in the regular Rules workflow.

The advisory check reports whether the submission is eligible for admission. A maintainer runs admission from the PipeLab site repository and checks that the resulting report says `ADMIT` for the current pull request head, and that the contributor terms box is still checked, before approving a merge. A description edit after the admission run needs a new run.

## Community pack licenses

Every community pack lives at `hub/community/<publisher>/<bundle>/` and carries a `LICENSE` file there. A pack under Apache-2.0, MIT, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD or CC0-1.0 needs a `LICENSE` with that license's complete standard text, plus a `NOTICE` file when the license requires one.

A pack under any other OSI-approved SPDX license needs a maintainer approval before the pack pull request. Record it in `hub/license-approvals.yaml` through a separate maintainer pull request. A contribution pull request that touches that file is refused, so ask for the approval first and open the pack pull request after it merges.

Each approval names the listing, the license, the SHA-256 of the exact `LICENSE` bytes and the pull request that approved it:

```yaml
schema_version: 1
approvals:
  - listing: acme/example-bundle   # <publisher-id>/<bundle-name>
    license: MPL-2.0
    license_sha256: <sha256 of the exact LICENSE bytes>
    approved_in: https://github.com/pipelab-org/pipelock-rules/pull/<n>
```

Compute the hash from the repository root with `sha256sum hub/community/<publisher>/<bundle>/LICENSE`. Any later edit to `LICENSE` voids the approval, so a changed license needs a new approval.

The Hub serves `LICENSE` and `NOTICE` beside the signed bundle as `license.txt` and `notice.txt` and shows them on the listing page. The signed bundle files never change.
