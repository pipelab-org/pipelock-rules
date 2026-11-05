---
name: Bug Report
about: A rule has a false positive or false negative
title: ''
labels: bug
assignees: ''
---

**Rule ID**
Which rule is affected? (e.g. `dlp-perplexity-api-key`)

**Problem**
Is this a false positive (matches something it shouldn't) or a false negative (misses something it should catch)?

**Synthetic test string**
Provide a nonfunctional example that reproduces the incorrect match or miss. Use fabricated personal or health data and synthetic credentials. Report exploitable bypasses privately as described in SECURITY.md.

```
paste test string here
```

**Expected behavior**
Should this string match or not?

**Pipelock version**
From `pipelock --version`.

**Additional context**
Bundle version and relevant configuration or surrounding text. Remove secrets, private addresses and identifying records before posting.
