# Diagram — Git Lifecycle

**Purpose:** Shows the three zones of a Git repository and the commands that move changes between them.
**Phase:** 1 — Secure Engineering Foundations
**Related:** [01-Git-Fundamentals/README.md](../01-Git-Fundamentals/README.md)

---

## Git Workflow — Three Zones

```
┌─────────────────────────────────────────────────────────────────────┐
│                        LOCAL MACHINE                                │
│                                                                     │
│  ┌─────────────────┐    git add    ┌─────────────────┐              │
│  │  WORKING        │──────────────►│  STAGING AREA   │              │
│  │  DIRECTORY      │               │  (Index)        │              │
│  │                 │◄──────────────│                 │              │
│  │  Your files     │  git restore  │  Files selected │              │
│  │  as you edit    │               │  for next commit│              │
│  └─────────────────┘               └────────┬────────┘              │
│                                             │ git commit             │
│                                             ▼                        │
│                                   ┌─────────────────┐               │
│                                   │  LOCAL REPO     │               │
│                                   │  (.git folder)  │               │
│                                   │                 │               │
│                                   │  Commit history │               │
│                                   │  SHA-1 chain    │               │
│                                   │  Branches/Tags  │               │
│                                   └────────┬────────┘               │
└────────────────────────────────────────────┼────────────────────────┘
                                             │ git push
                                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GITHUB (REMOTE)                                │
│                                                                     │
│   Mirror of local history — accessible anywhere — off-site backup   │
│   Portfolio visibility — public or private                          │
└─────────────────────────────────────────────────────────────────────┘

                         git pull / git fetch
              ◄──────────────────────────────────────────
```

---

## Command Reference

| Command | Zone transition | Effect |
|---|---|---|
| `git init` | — → Local repo | Creates .git folder. Tracking begins. |
| `git add <file>` | Working → Staging | Selects changes for next commit |
| `git restore <file>` | Staging → Working | Removes file from staging |
| `git commit -m "message"` | Staging → Local repo | Permanent snapshot with message |
| `git push` | Local repo → Remote | Sends commits to GitHub |
| `git pull` | Remote → Working | Fetches and merges remote changes |
| `git status` | — | Current state of all three zones |
| `git diff` | — | Line-level changes in working directory |
| `git diff --staged` | — | Line-level changes in staging area |
| `git log --oneline` | — | Commit history — newest first |

---

## Nicoliv Energy Context

At Nicoliv Energy, this workflow governs all infrastructure-as-code and configuration changes:

- **Working Directory:** engineer edits a firewall rule or Terraform module
- **Staging:** `git add` selects exactly which changes belong in this commit
- **Commit:** records what changed, who changed it, and when — the IEC 62443-2-1 change management log
- **Push:** change is backed up off-site and available for review

Without this workflow: a pressure anomaly at 2:47 AM has no traceable configuration history. The incident investigation starts from nothing.
