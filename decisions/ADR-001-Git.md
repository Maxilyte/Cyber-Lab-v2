# ADR-001 — Version Control: Git

**Status:** Accepted  
**Date:** 2026-06-02  
**Author:** Maximus Ikengwa  

---

## Context

This repository documents a Cloud/DevSecOps engineering journey with a security governance focus. Every build, configuration, and infrastructure component needs to be:

- Tracked with full change history
- Attributable to a specific author and timestamp
- Recoverable to any prior state
- Auditable for compliance purposes

A version control system is required from the start — not as an afterthought.

Three options were evaluated:

| Option | Description |
|---|---|
| Git | Distributed VCS — industry standard |
| SVN (Subversion) | Centralised VCS — legacy enterprise use |
| No version control | Files managed manually |

---

## Decision

**Use Git as the version control system for all content in this repository.**

---

## Rationale

**Git over SVN:**
- Distributed model — full history exists on every clone, not just a central server. No single point of failure.
- Branch and merge model is significantly more capable — enables parallel workstreams, feature branches, pull request workflows.
- Industry standard — every modern CI/CD tool, cloud provider, and security platform integrates with Git natively.
- SVN is legacy. Choosing it introduces friction with every modern tool in the pipeline.

**Git over no version control:**
- Without version control, changes are untracked, unattributable, and unrecoverable.
- Compliance frameworks (NIST CSF PR.PT-1, IEC 62443-2-1) require change logs — Git provides this automatically.
- A portfolio repository with no change history has no credibility. The commit history *is* the evidence.

---

## Consequences

**Positive:**
- Every change is timestamped, attributed, and permanent
- Full history survives machine failure (mirrored on GitHub)
- Enables CI/CD pipeline integration in later phases
- Provides automatic compliance evidence for change management controls

**Negative:**
- Requires learning Git workflow — initial friction
- Commit discipline required — poor commit messages degrade the audit trail
- `.gitignore` must be maintained to prevent accidental secret exposure

---

## Threat Model

| Threat | Risk | Control | Residual Risk |
|---|---|---|---|
| Accidental credential commit | Secrets exposed publicly on GitHub | `.gitignore` configured before first commit | Human error bypassing `.gitignore` — mitigated by GitHub secret scanning alerts |
| Loss of local machine | Work lost permanently | GitHub remote serves as off-site backup | GitHub availability — mitigated by Git's distributed model (any clone is a full backup) |
| Unattributed change | Audit trail breaks | `user.name` and `user.email` configured globally | Shared machine misuse — mitigated by per-user configuration |
| Tampered history | Evidence integrity compromised | SHA-1 hash chain — any modification changes all subsequent hashes | Sophisticated attacker with full repo access — outside threat model for this environment |

---

## Compliance Mapping

| Control | Standard | How Git satisfies it |
|---|---|---|
| Audit log records | NIST CSF PR.PT-1 | Every commit is a timestamped, attributed, immutable record of exactly what changed and why |
| Change management | IEC 62443-2-1 | Git commit history provides the formal change log required for OT system modifications |

---

## Review Trigger

Reconsider this decision if:
- A CI/CD platform with incompatible VCS requirements is adopted
- Regulatory requirements mandate a different audit trail format
- Team size exceeds 50 engineers (at which point Git workflow governance becomes a project in itself)

