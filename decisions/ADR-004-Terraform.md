# ADR-004 — Use Terraform as the Infrastructure-as-Code Tool

**Status:** Accepted
**Date:** 2026-06-18
**Author:** Maximus Chinazo Ikengwa

## Context

Phase 2 of Cyber-Lab-v2 requires infrastructure to be defined declaratively rather than built through manual console clicks, so the cloud architecture is auditable, reproducible, and consistent with the "infrastructure is the documentation" principle established for this portfolio.

This decision should have been made and documented before any Terraform command was run. It was not. Terraform was installed, the AWS CLI was configured, and a first resource — vpc-0611b97607b5fb7ca (ca-central-1, 10.0.0.0/16) — was built and applied using the canonical workflow (fmt, validate, plan -out=tfplan, review, apply, verify console, verify CloudTrail, commit) before this ADR existed.

That is a real breach of the ADR-before-implementation standard this repository is built on. This ADR is written retroactively, with the gap named explicitly rather than hidden, as the first documented instance of catching and correcting a process violation in this portfolio.

## Decision

Use Terraform as the Infrastructure-as-Code tool for all AWS resources in Cyber-Lab-v2, going forward, with all infrastructure brought under Terraform management exclusively. This decision is not AWS-specific by design: Azure is the confirmed second cloud for this portfolio (see ROADMAP.md, Phase 3, component 10), and Terraform remains the IaC tool of choice across that expansion as well, since its provider model is precisely what makes that extension possible without a second tool decision.

## Rationale

### Terraform over AWS CloudFormation
CloudFormation locks the entire portfolio to a single cloud provider, with zero transferability to a multi-cloud context. Multi-cloud capability is a deliberate priority for this portfolio, not a hypothetical — Terraform's provider model is the reason it was chosen over CloudFormation, not a side benefit.
CloudFormation would be correct inside an organisation already standardized on AWS-native tooling, or one that requires native AWS support without third-party state management.

### Terraform over AWS CDK
CDK generates CloudFormation underneath and requires general-purpose programming language fluency (TypeScript or Python) just to read the infrastructure definition, adding a layer of abstraction between the engineer and the actual resource configuration.
CDK would be correct for a team that already writes infrastructure in the same language as its application code, or that values type safety and unit-testable infrastructure over a declarative syntax.

### Terraform over Pulumi
Pulumi shares CDK's programming-language requirement and has a smaller hiring-market footprint than Terraform, meaning fewer interviewers will recognise it on sight in a portfolio review.
Pulumi would be correct for a team that wants full general-purpose language constructs (loops, conditionals, classes) natively, or that is already standardized on Pulumi.

### Terraform over Ansible
Ansible is a configuration management tool — it changes state on servers that already exist — not a provisioning tool, and it has no equivalent to Terraform's state file for tracking infrastructure drift.
Ansible would be correct for configuring software on top of infrastructure that has already been provisioned, which is a different problem than the one Phase 2 is solving.

## Tradeoffs — When this decision would be wrong

| Scenario | Better choice | Reason |
|---|---|---|
| Target employer or role explicitly requires CDK or Pulumi expertise | CDK or Pulumi | Matching the hiring organisation's actual tooling outweighs general market share |
| Portfolio narrows to a deep AWS-only enterprise context | CloudFormation | Native AWS support without third-party state management overhead |
| The task is configuring existing servers, not provisioning new infrastructure | Ansible | Configuration management problem, not a provisioning problem |
| Local state file security cannot yet be guaranteed | Pause further Terraform expansion until ADR-005 (Remote State) is resolved | Plaintext local state file is an open risk until then |

## Consequences

### Positive
- Multi-cloud transferable skill, recognised across the majority of AWS, Azure, and GCP job postings
- HCL is the most commonly referenced IaC syntax in cloud security and DevSecOps job descriptions
- Declarative model directly supports the "infrastructure is the documentation" principle of this portfolio
- Built-in drift detection via the state file, a concept directly referenced in detection engineering roles

### Negative
- The current local state file holds resource data in plaintext, unencrypted, with no locking — an open risk until ADR-005 resolves it
- The terraform-runner IAM service account currently holds AdministratorAccess, a documented open finding for Phase 3 least-privilege remediation, and the risk of that over-permissioning is amplified by this decision being formalised after the fact rather than before
- HCL has weaker conditional and looping constructs than CDK or Pulumi for complex logic

## Threat Model

| Threat | Risk | Control | Residual Risk |
|---|---|---|---|
| Local state file exposure | Sensitive resource data readable in plaintext if the laptop or repo is compromised | State file excluded via .gitignore, never committed | Remains a single point of failure until a remote encrypted backend exists (ADR-005) |
| terraform-runner over-permissioned (AdministratorAccess) | Any credential compromise grants full account control | Documented as a known open finding for Phase 3 least-privilege remediation | Active until the IAM policy is scoped down |
| No locking on local state | Concurrent applies could corrupt state | Single operator, manual discipline | Eliminated once ADR-005's remote backend with DynamoDB locking is in place |
| Decision formalised retroactively, without a documented failure-mode analysis at build time | Future resources built on an undocumented foundation | This ADR written now, gap named explicitly, used as a case study in Zero to IT | Process integrity restored from this point forward |

## Compliance Mapping

| Control | Standard | How satisfied |
|---|---|---|
| Configuration management | NIST CSF PR.IP-1 (Baseline configuration) | Terraform HCL defines all infrastructure as a versioned, declarative baseline |
| Change management | NIST CSF PR.IP-3 | All changes pass through plan, review, and apply, committed to Git with full history |
| Asset inventory | NIST CSF ID.AM-1 / ID.AM-2 | The Terraform state file, once moved to a remote backend, becomes the authoritative inventory of provisioned resources |
| Secure engineering lifecycle | IEC 62443-4-1 SD (Secure Design practices) | ADR-first discipline mirrors the secure development lifecycle requirement for documented design decisions before implementation |

## Review Trigger

Reconsider this decision if:
- A target employer or specific opportunity requires demonstrated CDK, Pulumi, or CloudFormation expertise specifically
- Azure expansion (confirmed in ROADMAP.md, Phase 3, component 10) reveals that a native Azure IaC tool (Bicep, ARM templates) is genuinely better supported for a specific workload than Terraform's azurerm provider — this would be a scoped exception for that workload, not a reversal of this ADR
- Terraform's licensing terms create a practical adoption barrier, in which case the OpenTofu fork should be evaluated as a substitute
- State management needs (locking, encryption, collaboration) are not resolved by ADR-005 within a reasonable timeframe
