# ADR-003 — Remote Repository Platform: GitHub

**Status:** Accepted  
**Date:** 2026-06-04  
**Author:** Maximus Ikengwa  

---

## Context

Git provides local version control.

However, a local repository alone does not provide:
- Off-site backup
- Collaboration
- Remote history synchronisation
- CI/CD integration
- Portfolio visibility

A remote repository platform is required.

Options evaluated:

| Option | Description |
|---|---|
| GitHub | Industry-leading Git platform |
| GitLab | Self-hosted and SaaS Git platform |
| Bitbucket | Atlassian Git platform |
| Local-only Git | No remote repository |

---

## Decision

Use GitHub as the primary remote repository platform.

---

## Rationale

### GitHub over Local-Only Git

A local repository creates a single point of failure. Machine loss or corruption results in complete project loss.

GitHub provides off-site backup, history replication, and recovery capability.

**When local-only is correct:** air-gapped environments where no external connectivity is permitted — classified systems, isolated OT networks, or environments with strict data residency requirements that prohibit any external platform.

---

### GitHub over GitLab

GitLab is technically excellent — stronger built-in CI/CD, an integrated container registry, and a more complete DevSecOps platform out of the box. For a public engineering portfolio, however, GitHub has larger industry adoption, greater recruiter visibility, and a stronger community ecosystem.

**When GitLab is the correct choice:** organisations wanting a fully integrated DevSecOps platform self-hosted behind a firewall; teams that need a single platform for code, CI/CD, container registry, and security scanning without external dependencies; environments where data sovereignty prohibits GitHub.

---

### GitHub over Bitbucket

Bitbucket integrates well with the Atlassian ecosystem (Jira, Confluence). Outside of that ecosystem, it has lower community adoption and reduced recruiter visibility.

**When Bitbucket is the correct choice:** organisations already deeply invested in Atlassian tooling where native Jira integration provides measurable workflow value.

---

## Tradeoffs — When this decision would be wrong

| Scenario | Better platform | Reason |
|---|---|---|
| Strict data residency — code cannot leave the organisation | Self-hosted GitLab or Gitea | GitHub stores data on Microsoft infrastructure |
| Air-gapped or classified environment | Self-hosted Gitea or local-only Git | No external connectivity permitted |
| Organisation fully invested in Atlassian stack | Bitbucket | Native Jira/Confluence integration reduces friction |
| Team needs fully integrated CI/CD + container registry in one platform | GitLab | GitHub requires external integrations; GitLab includes everything natively |
| Regulated industry requiring on-premise audit trail | Self-hosted GitLab | Full control over audit log storage and retention |

---

## Consequences

### Positive
- Remote backup — full history off-site
- Global accessibility
- CI/CD readiness — GitHub Actions available in Phase 4
- Professional portfolio visibility — recruiters default to GitHub profiles
- Collaboration support

### Negative
- Reliance on third-party platform — GitHub controls availability
- Public repositories require strict secret-management discipline
- Internet connectivity required for synchronisation
- Code stored on Microsoft-owned infrastructure — relevant in regulated contexts

---

## Threat Model

| Threat | Risk | Control | Residual Risk |
|---|---|---|---|
| Local machine failure | Project loss | GitHub remote backup | GitHub outage — mitigated by distributed model (any clone is a full backup) |
| Credential compromise | Unauthorised repository access | SSH key authentication (ADR-002) | Endpoint compromise — mitigated by immediate key revocation |
| Accidental secret commit | Credential or key exposure on public repository | `.gitignore` configured before first commit; GitHub secret scanning | Human error bypassing controls |
| Unauthorised modifications | Repository integrity degraded | Branch protection rules; commit signing | Account compromise — mitigated by 2FA and SSH-only access |

---

## Compliance Mapping

| Control | Standard | How GitHub supports it |
|---|---|---|
| Auditability | NIST CSF PR.PT-1 | Complete, immutable commit history — every change attributed and timestamped |
| Change management | IEC 62443-2-1 | Traceable modification record with author, timestamp, and stated reason |
| Recovery | NIST CSF RC.RP | Repository replication enables restoration from any clone |

---

## Business Impact

GitHub transforms Git from personal version control into enterprise change management.

It becomes the system of record for engineering decisions, infrastructure definitions, and operational controls — enabling:
- Infrastructure as Code (Terraform state and definitions)
- DevSecOps pipelines (GitHub Actions)
- Automated security scanning
- Auditable change history for compliance purposes

For a security engineering portfolio specifically, GitHub is the publication platform. The repository is not just where code lives — it is the evidence that the work was done, the decisions were deliberate, and the engineering thinking is real.

---

## Review Trigger

Reconsider this decision if:
- Regulatory requirements mandate self-hosting
- Data sovereignty requirements prohibit GitHub
- The organisation adopts an alternative enterprise Git platform
- GitHub introduces pricing or policy changes that affect public portfolio hosting
