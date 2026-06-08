# Phase 2 — Terraform Infrastructure as Code
## From Zero AWS Access to Verified Infrastructure as Code

**Phase status:** Foundation complete  
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

Every known gap is documented. Every gap has a remediation phase. That is the standard applied throughout this portfolio.

---

## Why this phase exists

Phase 1 gave Nicoliv Energy a change accountability platform. Every configuration change tracked. Every author identified. Every reason documented in Git.

Phase 1 solved the question of what changed and who changed it.

Phase 2 solves a harder problem. Who authorised the infrastructure to exist in the first place. Why does that security group have that rule. When was that VPC created and what was the approved design at the time. Can you prove right now that your live environment matches your approved baseline.

Ruth Akinola asked that question at a CAB meeting.

"If a CER auditor asked us to demonstrate that our production cloud environment matches our approved security baseline, how long would it take us to produce that evidence?"

The room went quiet for longer than it should have.

James Whitford said four hours, maybe six. Kenji Watanabe said it depends which baseline you mean. Nneka Okafor said nothing. She wrote it down.

That question is what Phase 2 is built to answer. Not in four hours. In four seconds.

---

## Why Terraform was chosen

Three options were evaluated. The full decision record is in decisions/ADR-004-Terraform.md including detailed tradeoffs and the conditions under which each option would be the correct choice.

| Option | Why it was not chosen |
|---|---|
| AWS Console | No repeatability. No audit trail at the code level. Configuration exists only in AWS. When the resource is deleted the knowledge of how it was built goes with it. |
| AWS CloudFormation | AWS-only. When Nicoliv Energy adds Azure connectivity for Microsoft 365 or hybrid OT monitoring, CloudFormation stops at the AWS boundary. Verbose syntax increases error surface. |
| Terraform | Multi-cloud. Declarative. State-tracked. Version-controlled. The current professional standard for regulated cloud environments. Maps directly to the ServiceNow change control workflow Nicoliv Energy already operates. |

**The decision in one sentence.**

Terraform was selected because the code it produces is simultaneously the infrastructure design, the deployment mechanism, the audit trail, and the drift detection system. No other option produces all four from a single source of truth.

---

## Infrastructure lifecycle

Terraform is not a creation tool. It is a lifecycle management tool.

Most tutorials teach Terraform as: write code, run apply, infrastructure exists. That is 20 percent of the picture.

The full lifecycle of every infrastructure resource looks like this.

**Provision.** Terraform creates the resource. The state file records its existence. Git records the code that defined it. CloudTrail records the API call that created it. Three independent records of the same event.

**Configure.** The resource is updated to its operational state. Each update is a Terraform change. Each change is a commit. When Ruth asks why a security group rule was added three months ago, the commit message and the ServiceNow CHG ticket reference in that message are the answer.

**Operate.** The resource is running. Terraform plan detects drift. If someone modifies the resource manually through the console, the next terraform plan shows the difference between what the code says should exist and what actually exists. That difference is a finding.

**Monitor.** CloudTrail monitors every API call against the resource. Logs flow to S3. In Phase 3 those logs feed into the detection pipeline. Nneka Okafor's team sees anomalous API calls against infrastructure resources as security events, not IT events.

**Patch.** The resource definition changes. The .tf file is updated. Terraform plan shows the modification. Terraform apply executes it. The change is in Git. The change is in CloudTrail. The change is traceable end to end.

**Retire.** The resource is no longer needed. The .tf file is updated to remove it. Terraform plan shows the destruction. Terraform apply destroys it. The destroy event is in Git. The resource is gone from the state file. The CloudTrail record of its deletion exists permanently.

**The principle that connects all six stages.**

Every stage produces evidence. The evidence exists in three places simultaneously. Git records the intent. Terraform state records the current reality. CloudTrail records the AWS-side confirmation. None of the three is sufficient alone. Together they answer any question any auditor can ask.

---

## Prerequisites

Before anything in this phase works, the following must exist and be verified. Every item has a verification step. Do not proceed past any item until it passes.

### 1. AWS Account

**Create an AWS account**

Go to https://aws.amazon.com and click Create an AWS Account.

Use a dedicated email address for the root account. Not your personal Gmail. Not your work email. A dedicated address you control permanently. The root account email is the master key to everything in the account including billing, support, and account closure.

You will need a credit card. AWS Free Tier reduces cost risk but does not eliminate billing risk. Every resource created should be reviewed, tagged, monitored, and destroyed when no longer needed. Terraform can create billable infrastructure quickly. A NAT Gateway left running costs a minimum of $32 per month. Set up a billing alert before writing a single resource.

**Secure the root account immediately**

The root account has unlimited, irrevocable access to everything. You use it once to set up your environment and then you lock it away permanently.

Go to the top right, click your account name, click Security credentials.

Scroll to Multi-factor authentication. Click Assign MFA device. Name it root-mfa. Choose Authenticator app. Scan the QR code with Google Authenticator. Enter two consecutive codes to confirm. Save.

Scroll to Access keys. If any exist, delete them. Root should never authenticate programmatically. A root access key is a skeleton key to your entire account.

Enable IAM user billing access. Go to Account settings. Find IAM user and role access to Billing information. Enable it.

**Verify**

IAM Dashboard, Security recommendations. Two green ticks. Root user has MFA. Root user has no active access keys. If either is missing, fix it before proceeding.

---

### 2. AWS CloudTrail

Enable before creating any resources.

CloudTrail is the independent audit log that records every API call made in your account. Every resource created, modified, or deleted. Every authentication attempt. Every permission denied.

When Ruth Akinola asks who created the VPC that appeared last Tuesday, CloudTrail is the evidence source that answers the question with a timestamp, an IAM identity, and a source IP address. Terraform says what was intended. CloudTrail confirms what AWS actually executed. Those are different truths and both are required.

Go to CloudTrail in the AWS console. Create a trail. Name it management-events-trail. Apply to all regions. Create a new S3 bucket to store logs. Enable log file validation. This creates a hash chain that detects tampering.

CloudTrail management events are free. Enable it before the first terraform apply.

---

### 3. AWS Budget Alert

Set this up before terraform apply.

Go to AWS Billing. Click Budgets. Create a budget. Choose Cost budget. Set the amount to $10. Add your email as the notification target. Set alerts at 50 percent and 100 percent of budget.

When Terraform accidentally creates a resource outside the free tier, you get an email before the bill becomes a problem. Cost governance is not a later phase problem. It is a before-you-start requirement.

---

### 4. IAM User Groups

Create groups before creating users. Groups are how permissions scale. Individual user policies become impossible to audit past five users.

Go to IAM, User groups, Create group.

| Group name | Policy attached | Purpose |
|---|---|---|
| Administrators | AdministratorAccess | Full account access for senior engineers |
| Developers | PowerUserAccess | Build resources, cannot modify IAM or billing |
| ReadOnly | ReadOnlyAccess | Auditors, junior team members |
| SecurityAudit | SecurityAudit | Security team read access across all services |

Never attach policies directly to individual users. Always use groups.

---

### 5. IAM Users

Use separate naming conventions for humans and service accounts. Human users have names. Service accounts have functions. When something runs at 2 AM you need to know immediately whether it was a person or an automated process.

| Username | Type | Groups | Purpose |
|---|---|---|---|
| Doris-Nneka | Human | Administrators | Admin user |
| Junior-dev | Human | Developers, ReadOnly | Junior engineer simulation |
| max.chinazo | Human | Multiple groups, SSO connected | Primary engineering user |
| Nicole-Ebube | Human | Developers, ReadOnly | Developer simulation |
| Senior-dev | Human | Administrators | Senior engineer simulation |
| terraform-runner | Service account | None, direct policy | Terraform automation identity |

---

### 6. The terraform-runner Service Account

This is the machine identity Terraform uses to authenticate to AWS. Not a human user. Does not log into the console. One job: execute infrastructure changes on behalf of Terraform after a human has reviewed and approved the plan.

**Why a dedicated identity and not root**

Root has unlimited access including account closure. A compromised root credential means complete account takeover. At Nicoliv Energy this would mean an attacker could modify the IAM Identity Center configuration, remove MFA requirements, and create backdoor accounts before anyone noticed. A compromised terraform-runner credential means an attacker can create and modify infrastructure resources. Serious. Not catastrophic.

**Why not max.chinazo**

Max.chinazo authenticates through Microsoft Entra ID via SAML 2.0. Terraform cannot use SSO credentials in this phase because SSO produces temporary session tokens through a browser flow that does not work in a non-interactive environment. Static credentials are appropriate for a local development machine controlled by one engineer. Future phases replace static credentials with IAM role assumption and OIDC federation.

**Known risk: AdministratorAccess**

This service account currently has AdministratorAccess. This would not be approved in any production environment under any circumstances. It is used here exclusively to avoid permission errors while the resource set is still being defined during early learning. This is a documented open finding with a Phase 3 remediation target. See the known issues section.

**Create terraform-runner**

Go to IAM, Users, Create user.

Username: terraform-runner. Console access: disabled. Permissions: AdministratorAccess attached directly.

After creation, click terraform-runner, Security credentials tab, Access keys, Create access key. Choose Command Line Interface. Add description tag: terraform-runner-dell3070. Download the CSV immediately. Store it outside your Git repository.

**Credential rotation**

If your access key appears in any chat, email, or screenshot, rotate it immediately. Deactivate and delete the exposed key in IAM. Create a new one. Run aws configure with the new credentials. Verify with aws sts get-caller-identity. This process was tested during this phase when a key appeared in a troubleshooting session. It takes five minutes.

---

### 7. AWS CLI

```powershell
winget install Amazon.AWSCLI
```

Close PowerShell. Open a fresh one.

```powershell
aws --version
```

Expected: aws-cli/2.x.x. You need version 2. Version 1 behaves differently in ways that cause confusing errors.

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

**Common errors**

InvalidClientTokenId: access key ID is wrong. Run aws configure again.

SignatureDoesNotMatch: secret access key is wrong, often because both keys were copied together with the comma separator from the CSV. The secret key is only the value after the comma.

**Verify**

```powershell
aws sts get-caller-identity
```

Confirm the Arn shows terraform-runner. Not root. Not max.chinazo. If it shows anything else, reconfigure before proceeding.

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

## Resource tagging strategy

Every AWS resource created in this phase gets tagged. No exceptions.

Tags answer four questions that come up constantly in cloud operations. What is this resource. Who owns it. What is it costing. Can it be deleted safely. Without tags a list of AWS resources three months from now is an archaeological dig.

| Tag key | Value | Purpose |
|---|---|---|
| Environment | learning | Distinguishes from any future production resources |
| Owner | maximus-ikengwa | Accountability |
| Project | cyber-lab-v2 | Cost allocation |
| Phase | 02-terraform | Which phase created it |
| ManagedBy | terraform | Confirms IaC management, flags manual resources |

The default_tags block in the provider configuration applies these tags to every resource automatically. Write them once. Every resource inherits them. Human error in tagging is eliminated at the source.

```hcl
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

---

## The foundation configuration

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

**required_version = ">= 1.0"**  
Any Terraform version 1.0 or newer can run this code. Older versions refuse. This protects against unexpected behaviour from outdated tooling on a collaborator's machine.

**required_providers**  
Terraform does not know how to talk to AWS natively. The provider is a plugin that translates HCL into AWS API calls. hashicorp/aws is the official provider maintained by HashiCorp.

**version = "~> 5.0"**  
Stay within the 5.x release range. Do not automatically jump to version 6. Breaking changes happen at major versions. This protects your infrastructure from silent breakage during a provider upgrade.

**region = "ca-central-1"**  
This is where ADR-004 lives in code. The decision that Nicoliv Energy data does not leave Canada is enforced here. Not in a policy document. In the configuration itself. If this line is changed to us-east-1, resources start appearing in Virginia. The code is the policy.

**default_tags**  
Every resource this provider creates inherits these four tags automatically. Tagging is not a manual step that gets forgotten under pressure. It is a configuration decision made once.

---

## The complete Terraform workflow

```powershell
terraform fmt
```
Formats .tf files to the canonical style. Run before every commit. Keeps formatting changes separate from logic changes in the Git history.

```powershell
terraform validate
```
Checks syntax and internal consistency without connecting to AWS. Catches errors locally before a network round trip.

```powershell
terraform init
```
Downloads providers, initialises the backend, creates the lock file. Run once per directory. Run again when providers or backend configuration changes.

```powershell
terraform plan
```
Shows exactly what will change. Every resource that will be created, modified, or destroyed. Read the plan completely. If it surprises you, you do not understand your own code well enough yet. Read it until it does not surprise you. When Nneka reviews a change control request, she reads the plan output the same way she reads a ServiceNow CHG ticket. It tells her what is about to happen before it happens.

```powershell
terraform apply
```
Executes the changes. Terraform shows the plan again and asks for confirmation. Type yes. After apply, the state file is updated.

```powershell
terraform destroy
```
Removes everything Terraform built. Shows what it will destroy and asks for confirmation. In a learning environment, destroy after every session unless there is a specific reason to leave resources running. Leaving resources running costs money and creates the drift problem this entire phase was designed to prevent.

**The professional sequence**

```
fmt > validate > plan > review > apply > verify > commit
```

Every time. No shortcuts.

---

## The .gitignore

Created before the first commit. Once something is in Git history, removing it cleanly requires rewriting history. Prevention is the control.

```
.terraform/
*.tfstate
*.tfstate.*
*.tfstate.backup
*.tfvars
crash.log
```

**.terraform/**  
Provider binaries. Around 180MB. Generated by terraform init. Never committed. The lock file tells anyone who clones this repo exactly which version to download.

***.tfstate**  
The most sensitive file in the Terraform setup. It contains resource IDs, IP addresses, and depending on the resources, database passwords in plain text. One accidental commit to a public repository is a security incident. Automated bots scan GitHub continuously for this type of data. They find it within minutes.

***.tfvars**  
Variable files that may contain passwords and account-specific values. Never committed.

**.terraform.lock.hcl is NOT ignored.**  
It is committed intentionally. It pins the exact provider version. It is the reproducibility guarantee that ensures every machine gets provider version 5.100.0, not whatever is current at the time of cloning.

---

## Verification checklist

Every item confirmed before writing the first resource.

| Check | Command | Expected result |
|---|---|---|
| Root MFA enabled | IAM Dashboard | Two green ticks |
| Root has no access keys | IAM Dashboard | Confirmed |
| CloudTrail active | CloudTrail console | Trail recording management events |
| Budget alert set | AWS Budgets | Alert configured at $10 |
| AWS CLI installed | aws --version | aws-cli/2.x.x |
| Correct identity | aws sts get-caller-identity | terraform-runner ARN |
| Correct account | Account field above | Your account ID |
| Correct region | aws configure get region | ca-central-1 |
| Terraform installed | terraform --version | Terraform v1.x.x |
| Terraform initialised | ls .terraform/ | Provider binary present |
| Lock file committed | git log --oneline | Foundation commit visible |
| State file not tracked | git status | No .tfstate files |
| Provider folder not tracked | git status | No .terraform/ folder |
| GitHub shows correct files | Browser | main.tf, .gitignore, .terraform.lock.hcl only |
| Tags configured | Review main.tf | default_tags block present |

---

## Threat model

| Threat | Control | Status | Remediation |
|---|---|---|---|
| State file in public repo | .gitignore excludes all .tfstate before first commit | Mitigated | Phase 3: S3 remote backend with encryption |
| Credentials committed to repo | .tfvars excluded. Credentials in AWS CLI config, not in .tf files. | Mitigated | Phase 4: IAM roles eliminate static credentials |
| AdministratorAccess on terraform-runner | Documented open finding. Dedicated account limits blast radius vs root. | Partial | Phase 3: least-privilege policy |
| Apply without plan review | Manual discipline. Plan reviewed before every apply. | Process control | Phase 4: CI/CD enforces plan as mandatory gate |
| Provider version mismatch | Lock file pinned to exact version and committed | Mitigated | Review on major releases |
| Root account compromise | MFA enabled. No access keys. Dedicated email. | Mitigated | Quarterly verification |
| Untagged resources accumulating cost | default_tags applies tags to all resources automatically | Mitigated | Monthly review |
| Unexpected AWS spend | Budget alert at $10 with email notification | Mitigated | Adjust threshold as resource count grows |
| No independent audit log | CloudTrail enabled before first resource created | Mitigated | Phase 3: encrypted S3 with integrity validation |
| terraform-runner key exposure | Rotation process documented and tested this session | Process control | Phase 4: OIDC federation, no static keys |

---

## Compliance mapping

| Control | Framework | Evidence | How to produce it |
|---|---|---|---|
| Baseline configuration maintained | NIST CSF PR.IP-1 | .tf files are the baseline. Drift shown in plan output. | terraform plan. Zero changes confirms live matches baseline. |
| Configuration change control | NIST CSF PR.IP-3 | Every change is a Git commit with author, timestamp, message. | git log --oneline |
| Least privilege access | NIST CSF PR.AC-4 | terraform-runner is dedicated. Root not used. Known gap documented. | aws sts get-caller-identity |
| Secure configuration | CIS Control 4 | Configurations in code. Deviations detected by plan. | terraform plan output |
| Audit logging | NIST CSF DE.CM-3 | CloudTrail records every API call. Git records every code change. | CloudTrail event history, git log |
| Audit readiness | Canada CCSPA | CloudTrail, Git, and Terraform state together answer any infrastructure question. | terraform show, git log, CloudTrail |

---

## Known open findings

| Finding | Risk | Owner | Target phase |
|---|---|---|---|
| terraform-runner has AdministratorAccess | High in production. Accepted in learning with documented rationale. | Maximus Ikengwa | Phase 3 |
| State file stored locally | Medium. Machine loss requires state reconstruction. | Maximus Ikengwa | Phase 3 |
| No automated plan gate | Medium. Relies on manual discipline. | Maximus Ikengwa | Phase 4 |
| Static access keys for Terraform | Medium. Can be rotated but not session-scoped. | Maximus Ikengwa | Phase 4 |

---

## Repository structure

```
04-Terraform/
├── README.md                  This file
├── main.tf                    Provider configuration, version requirements, default tags
├── .gitignore                 Protects state files, provider binaries, variable files
├── .terraform.lock.hcl        Provider version lock. Committed. Never ignored.
└── .terraform/                Provider binaries. Gitignored. Never committed.
```

---

## ADR reference

See decisions/ADR-004-Terraform.md for the complete decision record including options considered, tradeoffs, and the conditions under which each option would have been the correct choice.

The ADR was written and committed before this phase began. The timestamp on that commit proves the decision preceded the implementation.

---

## Next

A VPC in ca-central-1.

The network foundation that every subsequent resource lives inside. The first real infrastructure resource in this portfolio. Defined in code. Tagged from line one. Planned before applied. CloudTrail recording its creation. Ruth Akinola's question answerable from the moment it exists.

The infrastructure starts in the next commit.
