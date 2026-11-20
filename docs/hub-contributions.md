# Hub contributions

The `hub/` directory holds listing metadata and other contribution data for the PipeLab Hub. The official bundle build reads its rules from `rules/` and publishes signed bytes under `published/`.

Keep changes under `hub/` in their own pull request. For an official pack, add the listing under `hub/listings/bundles/` and bind it to the digest of the exact bundle served by the PipeLab registry. Leave edits to the signed bundle and its fixtures in the regular Rules workflow.

The advisory check reports whether the submission is eligible for admission. A maintainer runs admission from the PipeLab site repository and checks that the resulting report says `ADMIT` for the current pull request head before approving a merge.
