# Security policy

## Reporting a vulnerability

Report exploitable detection bypasses, resource-exhaustion behavior, signature-verification bypasses and rule-distribution supply-chain attacks through [Pipelock Security Advisories](https://github.com/pipelab-org/pipelock/security/advisories/new). Reports with security impact belong there before public disclosure, including false negatives that enable an exploitable bypass.

Ordinary false positives, non-exploitable detection gaps and rule-quality suggestions can use the public issue templates. If you're unsure whether a report exposes a vulnerability, start with a private advisory.

Include the affected rule ID, bundle and Pipelock versions, a description of the behavior, a synthetic reproduction and a suggested fix if you have one. Public examples must use nonfunctional credentials and fabricated personal or health data. Remove secrets, private addresses and identifying records from configuration excerpts and logs.

The rule checker uses Go's regexp package with RE2 syntax. Report excessive resource use with a bounded reproduction and observed results; catastrophic backtracking isn't the execution model used by this checker.

## Response timeline

- Acknowledgment: within 48 hours
- Initial assessment: within 1 week
- Fix and disclosure: coordinated with the reporter, typically within 30 days

## Supported versions

| Version | Supported |
|---------|-----------|
| 2026.x | Yes |
