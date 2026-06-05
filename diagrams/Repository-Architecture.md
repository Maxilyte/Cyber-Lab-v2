# Diagram — Repository Architecture

**Purpose:** Shows the structure of Cyber-Lab-v2 and the purpose of each component.
**Phase:** 1 — Secure Engineering Foundations
**Related:** [README.md](../README.md), [ROADMAP.md](../ROADMAP.md)

---

## Repository Structure — Annotated

```
Cyber-Lab-v2/
│
├── README.md                 THE NORTH STAR
│                             Answers in 15 seconds:
│                             What is this? What is it building toward?
│                             What stage is it at?
│
├── ROADMAP.md                THE PUBLIC COMMITMENT
│                             What is complete (with dates)
│                             What is in progress
│                             What is coming
│
├── CASE-STUDY.md             THE THREAT CONTEXT
│                             Nicoliv Energy environment definition:
│                             business operations, OT/IT architecture,
│                             vendor access model, threat actors,
│                             regulatory obligations
│
├── decisions/                THE THINKING RECORD
│   ├── ADR-001-Git.md        Written BEFORE first commit
│   ├── ADR-002-SSH.md        Written BEFORE SSH setup
│   ├── ADR-003-GitHub.md     Written BEFORE first push
│   └── ADR-NNN...            Written BEFORE each implementation
│
│                             Proves: decisions preceded the work.
│
├── diagrams/                 THE VISUAL RECORD
│   ├── Git-Lifecycle.md      ASCII Phase 1-3
│   ├── SSH-Authentication... ASCII Phase 1-3
│   └── Repository-Arch...    ASCII Phase 1-3
│                             → SVG/PNG Phase 4+ once architecture stabilises
│
├── 01-Git-Fundamentals/      PHASE 1 WORK (complete)
│   └── README.md
│
├── 02-SSH-GitHub/            PHASE 1 WORK (complete)
│   └── README.md
│
└── 03 → 12/                  UPCOMING PHASES
    (same documentation structure applied to each)
```

---

## Document Types and Their Jobs

| Document | Primary audience | Job |
|---|---|---|
| README.md (root) | Everyone | Platform identity in 15 seconds |
| ROADMAP.md | Recruiters, collaborators | Progress and trajectory |
| CASE-STUDY.md | Engineers, architects | Consistent threat context |
| ADR-NNN.md | Engineers, architects | Decision rationale and tradeoffs |
| Phase README.md | Engineers, learners | Full implementation with context |
| Diagrams | Everyone | Visual architecture reference |

---

## The 15-Second Test

| Question | Where the answer lives |
|---|---|
| What is this? | README.md — first paragraph |
| What is it building toward? | README.md — phase structure |
| What is complete? | ROADMAP.md |
| What threat does it address? | CASE-STUDY.md |
| Why were these tools chosen? | decisions/ folder |
| What was actually built? | Phase folders |

If any answer requires opening more than one file, the architecture needs improvement.

---

## Diagram Evolution Strategy

```
Phase 1-3:   ASCII diagrams in .md files
             Fast, version-controlled, readable in Git diffs
             Easy to update as the architecture changes

Phase 4+:    Convert stable diagrams to SVG/PNG
             Visual artifacts for LinkedIn, portfolio, interviews
             Architecture has stabilised — investment in polish justified

Rule: never build polished diagrams for architecture
      that will change next week.
```
