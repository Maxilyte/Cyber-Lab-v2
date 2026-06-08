# Phase 2 — Terraform Infrastructure as Code
## From Zero AWS Access to Verified Infrastructure as Code

**Phase status:** Foundation complete. First resource live.
**ADR reference:** decisions/ADR-004-Terraform.md
**Case study:** Nicoliv Energy Crown Gas Utility
**Author:** Maximus Ikengwa
**Last updated:** 2026-06-07

---

## Maturity self-assessment

This is a learning environment. It is not a production environment. They are not judged by the same standard.

| Capability | This phase | Production standard | Remediation phase |
|---|---|---|---|
| Authentication | Static access keys | IAM roles, OIDC federation | Phase 4 |
| Permissions | AdministratorAccess | Least privilege, resource-scoped policy | Phase 3 |
| State storage | Local machine | S3 with encryption, versioning, locking | Phase 3 |
| Change approval | Manual plan review | Automated CI/CD gate | Phase 4 |
| Cost governance | AWS Budget alert | Full tagging, cost allocation, showback | This phase |
| Audit logging | CloudTrail and Git | CloudTrail, Git, and SIEM correlation | Phase 3 |
| Secret management | AWS CLI credentials file | IAM roles, no static keys | Phase 4 |

Every known gap is documented. Every gap has a remediation phase.

---

## Why this phase exists

Phase 1 gave Nicoliv Energy a change accountability platform. Every configuration change tracked. Every author identified. Every reason documented in Git.

Phase 2 solves a harder problem. Who authorised the infrastructure to exist in the first place. Why does that security group have that rule. Can you prove right now that your live environment matches your approved baseline.

Ruth Akinola asked that question at a CAB meeting.

"If a CER auditor asked us to demonstrate that our production cloud environment matches our approved security baseline, how long would it take us to produce that evidence?"

The room went quiet for longer than it should have.

That question is what Phase 2 is built to answer. Not in four hours. In four seconds.

---

## Why Terraform was chosen

Full decision record in decisions/ADR-004-Terraform.md.

| Option | Why not chosen |
|---|---|
| AWS Console | No repeatability. No code-level audit trail. Knowledge disappears when the engineer leaves. |
| AWS CloudFormation | AWS-only. Verbose syntax. Does not extend to Azure when Nicoliv Energy adds hybrid connectivity. |
| Terraform | Multi-cloud. Declarative. State-tracked. Version-controlled. Maps directly to the ServiceNow change control workflow already in operation. |

The decision in one sentence: Terraform produces code that is simultaneously the infrastructure design, the deployment mechanism, the audit trail, and the drift detection system.

---

## Infrastructure lifecycle

Terraform is not a creation tool. It is a lifecycle management tool.

| Stage | What Terraform does | Evidence produced |
|---|---|---|
| Provision | Creates the resource from code | Git commit, state file, CloudTrail CreateX event |
| Configure | Updates the resource to operational state | Git commit with change, CloudTrail ModifyX event |
| Operate | Detects drift between code and live state | terraform plan output showing differences |
| Monitor | CloudTrail records every API call against the resource | CloudTrail event history |
| Patch | Code updated, plan reviewed, apply executed | Git commit, CloudTrail event |
| Retire | Resource removed from code, destroyed on apply | Git commit, CloudTrail DeleteX event, state updated |

Every stage produces evidence in three places. Git records intent. Terraform state records current reality. CloudTrail records AWS confirmation. None sufficient alone. Together they answer any auditor question.

---

## Prerequisites: complete setup sequence

### 1. AWS Account

Go to https://aws.amazon.com. Create an account with a dedicated email address. Not your personal Gmail. Not your work email. A dedicated address you control permanently. The root account email is the master key to the entire account.

You will need a credit card. AWS Free Tier reduces cost risk but does not eliminate billing risk. A NAT Gateway left running costs a minimum of $32 per month. Set up a billing alert before writing a single resource.

**Secure root immediately after account creation**

Click your account name top right. Click Security credentials.

Scroll to Multi-factor authentication. Assign MFA device. Name it root-mfa. Choose Authenticator app. Scan the QR code. Enter two consecutive codes. Save.

Scroll to Access keys. Delete any that exist. Root never authenticates programmatically.

Enable IAM user billing access. Account settings. IAM user and role access to Billing information. Enable.

**Verify:** IAM Dashboard shows two green ticks. Root user has MFA. Root user has no active access keys.

---

### 2. AWS CloudTrail

Enable before creating any resources.

CloudTrail records every API call in your account. Every resource created, modified, deleted. Every authentication attempt.

When Ruth Akinola asks who created a resource, CloudTrail answers with a timestamp, an IAM identity, and a source IP. Terraform says what was intended. CloudTrail confirms what AWS actually executed. Those are different truths and both are required.

Go to CloudTrail. Create a trail. Name it management-events-trail. Apply to all regions. Create a new S3 bucket for logs. Enable log file validation.

CloudTrail management events are free. Enable it before the first terraform apply.

---

### 3. AWS Budget Alert

Go to AWS Billing. Budgets. Create a budget. Cost budget. Amount: $10. Email notification at 50% and 100%.

Cost governance is not a later phase problem. It is a before-you-start requirement.

---

### 4. IAM User Groups

Go to IAM. User groups. Create group.

| Group name | Policy | Purpose |
|---|---|---|
| Administrators | AdministratorAccess | Senior engineers |
| Developers | PowerUserAccess | Build resources, no IAM or billing access |
| ReadOnly | ReadOnlyAccess | Auditors, junior team members |
| SecurityAudit | SecurityAudit | Security team read access |

Always attach policies to groups. Never to individual users.

---

### 5. IAM Users

Use separate naming conventions for humans and service accounts. When something runs at 2 AM you need to know immediately whether it was a person or an automated process.

| Username | Type | Groups | Purpose |
|---|---|---|---|
| Doris-Nneka | Human | Administrators | Admin user |
| Junior-dev | Human | Developers, ReadOnly | Junior engineer simulation |
| max.chinazo | Human | Multiple, SSO connected | Primary engineering user |
| Nicole-Ebube | Human | Developers, ReadOnly | Developer simulation |
| Senior-dev | Human | Administrators | Senior engineer simulation |
| terraform-runner | Service account | None, direct policy | Terraform automation identity |

---

### 6. terraform-runner Service Account

The machine identity Terraform uses to authenticate to AWS. Does not log into the console. One job: execute infrastructure changes after a human reviews and approves the plan.

**Why not root:** Root has unlimited access including account closure. Compromised root means complete account takeover.

**Why not a human account:** Human accounts authenticate through SSO. Terraform needs static credentials for non-interactive execution. Machine processes get machine identities.

**Known risk:** This account currently has AdministratorAccess. This would not be approved in any production environment. It is used here to avoid permission errors during early experimentation. Phase 3 replaces it with a least-privilege policy scoped to portfolio resources.

**Create the account**

IAM. Users. Create user.

Username: terraform-runner
Console access: disabled
Permissions: AdministratorAccess attached directly

After creation, click terraform-runner. Security credentials tab. Access keys. Create access key. Choose Command Line Interface. Add description tag: terraform-runner-dell3070. Download the CSV immediately. Store it outside your Git repository.

**Credential rotation**

If your access key appears in any chat, email, or screenshot, rotate it immediately. Deactivate and delete the exposed key. Create a new one. Reconfigure AWS CLI. Verify with aws sts get-caller-identity. This process was tested during this phase. It takes five minutes.

---

### 7. AWS CLI

```powershell
winget install Amazon.AWSCLI
```

Close PowerShell. Open a fresh one. PATH is only read at terminal start.

```powershell
aws --version
```

Expected: aws-cli/2.x.x. You need version 2.

```powershell
aws configure
```

| Prompt | Value |
|---|---|
| AWS Access Key ID | From terraform-runner CSV |
| AWS Secret Access Key | From terraform-runner CSV |
| Default region name | ca-central-1 |
| Default output format | json |

Open the CSV in Notepad. Right-click to paste in PowerShell. Do not type 40-character keys manually.

**Common errors and exact fixes**

InvalidClientTokenId: access key ID entered incorrectly. Run aws configure again.

SignatureDoesNotMatch: secret access key wrong. Often caused by copying both CSV columns including the comma separator. The secret key is only the value after the comma.

**Verify**

```powershell
aws sts get-caller-identity
```

Confirm the Arn shows terraform-runner. If it shows anything else, reconfigure before proceeding.

---

### 8. Terraform

```powershell
winget install HashiCorp.Terraform
```

Close PowerShell. Open a fresh one.

```powershell
terraform --version
```

Expected: Terraform v1.x.x on windows_amd64.

---

### 9. Initialise the working directory

Create the folder structure.

```powershell
cd ~/Documents/Cyber-Lab-v2
mkdir 04-Terraform
cd 04-Terraform
```

Create main.tf with the foundation configuration.

```powershell
notepad main.tf
```

Paste this exactly.

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"

  default_tags {
    tags = {
      Environment = "learning"
      Owner       = "maximus-ikengwa"
      Project     = "cyber-lab-v2"
      ManagedBy   = "terraform"
    }
  }
}
```

Create .gitignore before terraform init.

```powershell
notepad .gitignore
```

```
.terraform/
*.tfstate
*.tfstate.*
*.tfstate.backup
*.tfvars
crash.log
tfplan
```

Run terraform init.

```powershell
terraform init
```

Expected last line: Terraform has been successfully initialized!

Verify what was created.

```powershell
git status
```

Confirm .terraform/ folder is NOT listed. Confirm .terraform.lock.hcl IS listed.

Commit the foundation.

```powershell
git add main.tf .gitignore .terraform.lock.hcl
git commit -m "Phase 2 init: Terraform foundation with AWS provider pinned to ca-central-1"
git push
```

---

## Resource tagging strategy

Every resource gets tagged. No exceptions.

```hcl
default_tags {
  tags = {
    Environment = "learning"
    Owner       = "maximus-ikengwa"
    Project     = "cyber-lab-v2"
    ManagedBy   = "terraform"
  }
}
```

The default_tags block in the provider applies these to every resource automatically. Write once. Every resource inherits.

---

## The complete Terraform workflow

```powershell
terraform fmt
```
Formats code to canonical style. No output means already formatted. Run before every commit.

```powershell
terraform validate
```
Checks syntax without connecting to AWS. Expected: Success! The configuration is valid.

```powershell
terraform plan -out=tfplan
```
Saves the exact plan to a binary file. The -out flag is not optional. It is the production standard. Review every line before proceeding.

```powershell
terraform apply tfplan
```
Applies the exact saved plan. No confirmation prompt. No deviation from what was reviewed.

```powershell
terraform destroy
```
Removes everything Terraform built. Always destroy after each session unless there is a specific reason to leave resources running.

**The professional sequence every time**

```
fmt > validate > plan -out=tfplan > review > apply tfplan > verify console > verify CloudTrail > commit
```

---

## Building the VPC: workflow followed

### Write the resource

Added to main.tf below the provider block.

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cyber-lab-v2-vpc"
  }
}
```

**resource "aws_vpc" "main":** resource is the Terraform keyword. aws_vpc is the resource type. main is the internal Terraform name used to reference this resource from other resources.

**cidr_block = "10.0.0.0/16":** The IP address range for the entire VPC. 65,536 addresses available. Private range that does not conflict with the public internet.

**enable_dns_hostnames = true:** AWS automatically assigns human-readable DNS names to resources inside the VPC. Essential for service-to-service communication.

**enable_dns_support = true:** Enables the AWS DNS resolver inside the VPC. Works together with dns_hostnames. Always enable both.

**tags Name:** The display name shown in the AWS console. Separate from default_tags which apply automatically.

### Execute the workflow

```powershell
terraform fmt
terraform validate
terraform plan -out=tfplan
```

Review the plan. Confirm: Plan: 1 to add, 0 to change, 0 to destroy.

```powershell
terraform apply tfplan
```

Expected output:
```
aws_vpc.main: Creating...
aws_vpc.main: Still creating... [00m10s elapsed]
aws_vpc.main: Creation complete after 12s [id=vpc-0611b97607b5fb7ca]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### Verify in AWS console

Go to VPC in the AWS console. Confirm region is ca-central-1.

Confirm cyber-lab-v2-vpc appears with IPv4 CIDR 10.0.0.0/16 and state Available.

Note: a second VPC with CIDR 172.31.0.0/16 and no name is the AWS default VPC. AWS creates this automatically in every account. You did not build it.

### Verify in CloudTrail

CloudTrail. Event history. Filter by Event name. Search CreateVpc.

Confirm:
- Event name: CreateVpc
- User name: terraform-runner
- Resource name: vpc-0611b97607b5fb7ca
- Timestamp: matches the apply output time

This is the independent verification. Terraform says it created the resource. CloudTrail confirms AWS executed the API call, when, and under which identity. Those are different truths. Both are required.

### Commit

```powershell
git add main.tf .gitignore
git commit -m "Add VPC resource: cyber-lab-v2-vpc created by terraform-runner in ca-central-1 - 10.0.0.0/16"
git push
```

---

## Current infrastructure state

| Resource | Type | ID | Region | Created |
|---|---|---|---|---|
| cyber-lab-v2-vpc | aws_vpc | vpc-0611b97607b5fb7ca | ca-central-1 | 2026-06-07 |

CloudTrail verification: CreateVpc event recorded at 18:37:49 UTC, June 07 2026. Identity: terraform-runner. Independent confirmation that intent in Git matches execution in AWS.

Ruth Akinola's question is now answerable. Who created that VPC. When. Under what identity. Three seconds. Not four hours.

---

## Threat model

| Threat | Control | Status | Remediation |
|---|---|---|---|
| State file in public repo | .gitignore excludes all .tfstate before first commit | Mitigated | Phase 3: S3 remote backend |
| Credentials committed to repo | .tfvars excluded. Credentials in AWS CLI config only. | Mitigated | Phase 4: IAM roles |
| AdministratorAccess on terraform-runner | Documented open finding. Dedicated account limits blast radius vs root. | Partial | Phase 3 |
| Apply without plan review | -out=tfplan enforced. Saved plan applied. No deviation possible. | Mitigated | Phase 4: CI/CD gate |
| Provider version mismatch | Lock file pinned and committed | Mitigated | Review on major releases |
| Root account compromise | MFA enabled. No access keys. | Mitigated | Quarterly verification |
| Untagged resources | default_tags in provider block | Mitigated | Monthly review |
| Unexpected AWS spend | Budget alert at $10 | Mitigated | Adjust as resources grow |
| No independent audit log | CloudTrail enabled before first resource | Mitigated | Phase 3: encrypted S3 |
| terraform-runner key exposure | Rotation process tested this session | Process control | Phase 4: OIDC |

---

## Compliance mapping

| Control | Framework | Evidence | How to produce |
|---|---|---|---|
| Baseline configuration maintained | NIST CSF PR.IP-1 | .tf files are the baseline. Drift in plan output. | terraform plan. Zero changes confirms match. |
| Configuration change control | NIST CSF PR.IP-3 | Every change is a Git commit. | git log --oneline |
| Least privilege | NIST CSF PR.AC-4 | terraform-runner dedicated. Root not used. Gap documented. | aws sts get-caller-identity |
| Secure configuration | CIS Control 4 | Configurations in code. Deviations detected by plan. | terraform plan output |
| Audit logging | NIST CSF DE.CM-3 | CloudTrail records every API call. Git records every code change. | CloudTrail event history, git log |
| Audit readiness | Canada CCSPA | CloudTrail, Git, Terraform state answer any infrastructure question. | terraform show, git log, CloudTrail |

---

## Known open findings

| Finding | Risk | Owner | Target phase |
|---|---|---|---|
| terraform-runner has AdministratorAccess | High in production. Accepted in learning. | Maximus Ikengwa | Phase 3 |
| State file stored locally | Medium | Maximus Ikengwa | Phase 3 |
| No automated plan gate | Medium | Maximus Ikengwa | Phase 4 |
| Static access keys | Medium | Maximus Ikengwa | Phase 4 |

---

## Repository structure

```
04-Terraform/
├── README.md                  This file
├── main.tf                    Provider configuration, VPC resource, default tags
├── .gitignore                 Protects state files, provider binaries, tfplan, variable files
├── .terraform.lock.hcl        Provider version lock. Committed. Never ignored.
└── .terraform/                Provider binaries. Gitignored. Never committed.
```

---

## ADR reference

See decisions/ADR-004-Terraform.md for the complete decision record.

The ADR was written and committed before this phase began. The timestamp proves the decision preceded the implementation.

---

## Next

Public and private subnets inside the VPC. An internet gateway for public subnet traffic. Security groups defining what can communicate with what.

Each resource follows the same sequence. fmt, validate, plan -out=tfplan, review, apply tfplan, verify in AWS console, verify in CloudTrail, commit.

The network foundation continues in the next commit.
