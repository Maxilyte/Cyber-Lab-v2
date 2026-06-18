# Roadmap — Cyber-Lab-v2

**Last updated:** 2026-06-18
**Current phase:** Phase 2 — Infrastructure as Code
**Pace:** ~8 effective hours/week
**Target completion:** ~28 weeks from start date

---

## Progress

### Phase 1 — Secure Engineering Foundations
*Building the version control, authentication, and documentation infrastructure that every future phase depends on.*

| Component | Status | Completed |
|---|---|---|
| 01 — Git Fundamentals | ✅ Complete | 2026-06-02 |
| 02 — SSH Authentication & GitHub | ✅ Complete | 2026-06-04 |
| 03 — Repository Architecture & Standards | ✅ Complete | 2026-06-04 |

---

### Phase 2 — Infrastructure as Code
*Everything becomes code. No manual console clicks. The infrastructure is the documentation.*

| Component | Status | Completed |
|---|---|---|
| 04 — Terraform Foundations | 🔄 In Progress | ADR-004 accepted 2026-06-18, first VPC live (vpc-0611b97607b5fb7ca) |
| 05 — AWS Core (IAM, VPC, EC2, S3) | ⬜ Upcoming | — |
| 06 — IaC Security Scanning | ⬜ Upcoming | — |

**Portfolio project:** Enterprise AWS environment built entirely in Terraform
**Open item:** ADR-005 — Terraform Remote State (S3 backend + DynamoDB locking) still pending; current state is local only

---

### Phase 3 — Cloud Architecture
*Rebuilding the Purdue Model IT/OT segmentation concept as cloud-native network architecture.*

| Component | Status | Completed |
|---|---|---|
| 07 — VPC Design & Segmentation | ⬜ Upcoming | — |
| 08 — IAM Architecture & Least Privilege | ⬜ Upcoming | — |
| 09 — Network Segmentation (IT/OT analogue) | ⬜ Upcoming | — |
| 10 — Multi-Cloud Extension: Azure (Entra ID federation parity) | 🔒 Future — not active scope | Add only after components 07-09 are complete; extends existing Entra ID/SAML federation from AWS into Azure |

---

### Phase 4 — DevSecOps Automation
*Security gates in the pipeline. Every push is scanned before it deploys.*

| Component | Status | Completed |
|---|---|---|
| 11 — CI/CD Pipeline (GitHub Actions) | ⬜ Upcoming | — |
| 12 — Docker Fundamentals (build/push step in pipeline) | ⬜ Upcoming | — |
| 13 — Security Gates (tfsec, Checkov, Trivy) | ⬜ Upcoming | — |
| 14 — Secrets Management (AWS Secrets Manager) | ⬜ Upcoming | — |

**Portfolio project:** DevSecOps pipeline — Push → Scan → Gate → Deploy

---

### Phase 5 — Cloud Detection Engineering
*Building detection capability as code. Alerts that mean something.*

| Component | Status | Completed |
|---|---|---|
| 15 — GuardDuty | ⬜ Upcoming | — |
| 16 — Security Hub & Config | ⬜ Upcoming | — |
| 17 — Detection as Code | ⬜ Upcoming | — |

**Portfolio project:** Cloud-native detection platform deployed via Terraform

---

### Phase 6 — AI-Assisted Security Operations
*Connecting detection to intelligence. GuardDuty findings to LLM-generated triage summaries.*

| Component | Status | Completed |
|---|---|---|
| 18 — Alert Triage Automation | ⬜ Upcoming | — |
| 19 — LLM Incident Summarisation | ⬜ Upcoming | — |
| 20 — AI-SOC Integration | ⬜ Upcoming | — |

---

### Phase 7 — Cyber Resilience & Governance
*Closing the loop — proving the platform is not just built, but defensible and explainable to leadership.*

| Component | Status | Completed |
|---|---|---|
| 21 — GRC Operational Mapping | ⬜ Upcoming | — |
| 22 — Executive Reporting | ⬜ Upcoming | — |
| 23 — Resilience Framework | ⬜ Upcoming | — |

---

## Notes

- **Platform Engineering (Docker/Kubernetes/Helm/ArgoCD/service mesh) is explicitly out of scope.** It dilutes the IT/OT + Cloud Security/DevSecOps differentiator this portfolio is built around. Docker alone is folded into Phase 4 as a CI/CD component, not its own phase. Revisit only if a specific target role requires it (Review Trigger event, same standard used in the ADRs).
- **Azure is the confirmed second cloud** for the multi-cloud extension, chosen over GCP for direct continuity with the existing Entra ID/SAML federation, stronger fit with the Canadian enterprise/utility sector, and alignment with the IT/OT background this portfolio leverages.
- This roadmap is the single source of truth. Any future planning document (including CLAUDE_OPERATING_SYSTEM.md) should be reconciled against this file, not run in parallel with it.
