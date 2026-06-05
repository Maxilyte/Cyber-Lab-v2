# Cyber-Lab-v2 — Roadmap

**Started:** 2026-06-02  
**Pace:** ~8 effective hours/week  
**Current phase:** Phase 1 — Secure Engineering Foundations

---

## Phase 1 — Secure Engineering Foundations

### Completed
- [x] Git installation and configuration — *2026-06-02*
- [x] Repository creation and commit workflow — *2026-06-02*
- [x] Git history and inspection (`git log`, `git diff`) — *2026-06-02*
- [x] SSH key generation (Ed25519) — *2026-06-04*
- [x] GitHub authentication via SSH — *2026-06-04*
- [x] First professional repository push — *2026-06-04*
- [x] ADR-001 — Git — *2026-06-04*
- [x] ADR-002 — SSH — *2026-06-04*
- [x] Nicoliv Energy case study — *2026-06-04*

### In Progress
- [ ] Repository architecture (root README, folder structure)
- [ ] ADR-003 — GitHub
- [ ] Diagrams — Git lifecycle, SSH authentication flow

**Phase portfolio deliverable:** Structured engineering repository with full ADR documentation, threat models, and case study — readable as a security engineering portfolio from the first click.

---

## Phase 2 — Infrastructure as Code

### Planned
- [ ] Terraform installation and provider configuration
- [ ] AWS provider setup
- [ ] VPC deployment in code
- [ ] Subnets, route tables, internet gateway
- [ ] Security groups
- [ ] EC2 instance deployment
- [ ] Remote state management (S3 + DynamoDB lock)
- [ ] Terraform modules (reusable components)
- [ ] IaC security scanning (tfsec, Checkov)
- [ ] ADR-004 — Terraform

**Phase portfolio deliverable:** Enterprise AWS environment built entirely in Terraform — no manual console configuration.

---

## Phase 3 — AWS Cloud Engineering

### Planned
- [ ] IAM — users, groups, roles, policies, least privilege
- [ ] VPC architecture — public/private subnets, NAT gateways
- [ ] EC2 — Linux server, hardening, security groups
- [ ] S3 — storage, encryption, lifecycle, bucket policies
- [ ] CloudWatch — logging and monitoring
- [ ] Route tables and network flow
- [ ] ADR-005 — AWS

**Phase portfolio deliverable:** Fully documented AWS architecture modelled on Nicoliv Energy network segmentation — IT/OT segmentation concept rebuilt as cloud-native design.

---

## Phase 4 — DevSecOps Automation

### Planned
- [ ] GitHub Actions — pipeline fundamentals
- [ ] Terraform automation — push to deploy
- [ ] Checkov — infrastructure scanning gate
- [ ] Trivy — container and dependency scanning gate
- [ ] tfsec — Terraform-specific scanning gate
- [ ] Secrets management — AWS Secrets Manager
- [ ] Pipeline security review
- [ ] ADR-006 — GitHub Actions

**Phase portfolio deliverable:** DevSecOps pipeline — Push → Scan (tfsec, Checkov, Trivy) → Gate → Deploy. Every push is automatically validated before it reaches infrastructure.

---

## Phase 5 — Containers

### Planned
- [ ] Docker — images, containers, volumes, networking
- [ ] Docker Compose — multi-container applications
- [ ] Docker security hardening
- [ ] Kubernetes fundamentals — pods, deployments, services
- [ ] EKS — managed Kubernetes on AWS
- [ ] Container security — image scanning, RBAC, network policies
- [ ] ADR-007 — Kubernetes

**Phase portfolio deliverable:** Secured cloud-native application platform on EKS, deployed via the Phase 4 pipeline.

---

## Phase 6 — Cloud Detection Engineering

### Planned
- [ ] CloudTrail — API audit logging
- [ ] GuardDuty — threat detection
- [ ] Security Hub — centralised findings
- [ ] AWS Config — compliance posture
- [ ] Detection rules as code (deployed via Terraform)
- [ ] Threat hunting exercises
- [ ] ADR-008 — Detection Platform

**Phase portfolio deliverable:** Cloud-native detection platform deployed as code — GuardDuty, Security Hub, and Config rules all provisioned via Terraform with documented detection rationale.

---

## Phase 7 — AI-Assisted Security Operations

### Planned
- [ ] Alert triage automation — Lambda function
- [ ] LLM integration — incident summarisation
- [ ] Automated risk prioritisation
- [ ] End-to-end pipeline: finding → summary → suggested response
- [ ] ADR-009 — AI Integration

**Phase portfolio deliverable (flagship):**
```
GuardDuty Finding
      ↓
   Lambda
      ↓
     LLM
      ↓
Incident Summary + Suggested Response
```
Fully automated. Deployed via Terraform. Documented with threat model and governance mapping.

---

## Phase 8 — Cyber Resilience & Governance

### Planned
- [ ] GRC operational mapping — controls to frameworks
- [ ] Executive dashboards
- [ ] Risk communication documentation
- [ ] Compliance evidence package (NIST CSF, IEC 62443)
- [ ] Board-level reporting templates
- [ ] Resilience framework documentation

**Phase portfolio deliverable:** End-to-end governance documentation demonstrating the full chain:
```
Telemetry → Detection → Investigation → Governance → Executive Risk Communication
```

---

## Certification Track (parallel)

| Certification | Target timing | Status |
|---|---|---|
| GRC Mastery (Abed Hamdan) | Active | 🔄 In Progress |
| AWS Solutions Architect Associate | Phase 2–3 completion | ⬜ Planned |
| AWS Security Specialty | Phase 6 completion | ⬜ Planned |

---

## End State

At completion this repository demonstrates:

- **Infrastructure as Code** — every environment reproducible from a single `terraform apply`
- **DevSecOps automation** — security gates embedded in every delivery pipeline
- **Cloud security architecture** — network segmentation, IAM, detection, all as code
- **AI-assisted operations** — automated triage from detection to incident summary
- **Governance integration** — every control mapped to NIST CSF and IEC 62443
- **IT/OT security depth** — the differentiator almost nobody in cloud security holds

**Profile at completion:** Cloud Security / DevSecOps Engineer with IT/OT Security depth.
