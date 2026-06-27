# INC-001 — Credential Exposure: terraform-runner Access Keys

**Date:** 2026-06-14  
**Severity:** High  
**Status:** Resolved  
**Author:** Maximus Ikengwa  
**Repository:** Maxilyte/Cyber-Lab-v2  

---

## What Happened

During Phase 2 Session 1 of the Cyber-Lab-v2 build, the AWS CLI was being
configured for the terraform-runner IAM service account for the first time.
Two configuration errors occurred in sequence, and the troubleshooting process
that followed caused the terraform-runner Access Key ID and Secret Access Key
to become visible in an external chat interface.

The key pair was active at the time of exposure. The account (689546299913)
had terraform-runner configured with AdministratorAccess, meaning the exposed
credential had full programmatic access to the AWS environment.

---

## Timeline

| Time | Event |
|---|---|
| Session start | AWS CLI aws configure initiated for terraform-runner |
| Attempt 1 | Access Key ID typed manually — one character wrong — returned InvalidClientTokenId |
| Attempt 2 | Full CSV row copied including comma separator — secret key field received key ID plus comma plus secret — returned SignatureDoesNotMatch |
| Exposure | During troubleshooting of Attempts 1 and 2, credential values appeared in external chat window |
| T+0 min | Exposure identified |
| T+5 min | Key deactivated, deleted, new key created, aws configure re-run, identity verified |

---

## Root Cause

**Primary cause:** Credential values were shared in an external chat interface
during a troubleshooting session. A chat interface is an external system. Any
credential that enters it must be treated as compromised regardless of the
perceived audience or purpose.

**Contributing cause:** Two prior configuration failures created a debugging
context in which the natural instinct was to share what was on screen to get
help diagnosing the error. The troubleshooting process itself became the
exposure path.

**The configuration errors that created the context:**

Error 1: Manual typing of a 20-character access key ID. One wrong character
produces InvalidClientTokenId with no indication of which character is wrong.
Manual typing of credentials is never appropriate.

Error 2: Copying the entire CSV row instead of the value only. A CSV file
separates fields with commas. Copying the full row copies both the key ID and
the secret joined by a comma. The secret key field must receive only the value
after the comma — nothing else.

---

## Immediate Response

1. Went to AWS Console — IAM — Users — terraform-runner — Security credentials
2. Located the exposed access key
3. Clicked Deactivate — confirmed deactivation
4. Clicked Delete — confirmed deletion
5. Clicked Create access key — selected CLI use case
6. Downloaded new credentials CSV
7. Opened CSV in Notepad — copied key ID only, then secret only (value after comma)
8. Ran aws configure — pasted each value separately from Notepad
9. Ran aws sts get-caller-identity — confirmed terraform-runner identity in account 689546299913
10. Total time from exposure identification to verified clean credential: five minutes

---

## Blast Radius Assessment

| Risk | Assessment |
|---|---|
| Unauthorized use of exposed key | Contained. Key was deactivated and deleted within five minutes of exposure. A deleted key cannot be authenticated against regardless of who has the value. No valid credential existed after deletion. |
| Scope of access if key had been used in the exposure window | Full AdministratorAccess on account 689546299913. This is the open finding that makes least-privilege remediation urgent regardless of this incident. |
| Data at risk | No sensitive data existed in the account at time of exposure. VPC only. No EC2, no S3, no databases. |
| New credential status | New key created, configured, and verified. aws sts get-caller-identity confirmed terraform-runner identity in account 689546299913. New key has not been exposed. |

---

## Behavior Changes Going Forward

**Rule 1: Credentials never enter a chat interface.**
Not for troubleshooting. Not to show an error. Not partially. If the problem
requires showing what is on screen, show the error message and the command
only — never the credential value itself.

**Rule 2: No manual typing of credentials.**
Access Key IDs are 20 characters. Secret Access Keys are 40 characters. One
wrong character produces a misleading error. Open the CSV in Notepad. Paste
from Notepad. Nothing else.

**Rule 3: CSV copy discipline.**
When copying from the credentials CSV, copy the key ID field alone, then the
secret field alone. Never copy the full row. The comma in a CSV file is a
field separator, not part of the value.

**Rule 4: Rotation is immediate and without debate.**
Any credential that has appeared in a chat, email, screenshot, or any surface
outside the terminal and the CSV file is rotated immediately. Not assessed,
not evaluated — rotated. This was practiced correctly in this session. The
habit must hold under pressure.

---

## Controls This Informs

| Finding | Control | Phase |
|---|---|---|
| Exposed key had AdministratorAccess | Scope terraform-runner to least-privilege IAM policy — reduces blast radius of any future exposure | Phase 2 open finding |
| Local state file holds infrastructure record | Remote state (S3 + DynamoDB) removes the local machine as a single point of failure | Phase 2 open finding |
| No automated detection of key misuse | CloudTrail review for the old key ID in the exposure window should be done manually now | Immediate |

---

## Compliance Mapping

| Control | Standard | How this incident relates |
|---|---|---|
| Incident response | NIST CSF RS.RP-1 | Response plan executed: identify, contain (rotate), verify. Five-minute resolution time. |
| Credential management | NIST CSF PR.AC-1 | Exposed credential rotated immediately. Behavior rules documented to prevent recurrence. |
| Audit log review | NIST CSF DE.AE-3 | CloudTrail review of old key activity in the exposure window is a remaining action item. |

---

## Remaining Action Items

- [x] Old key deactivated and deleted — confirmed. New key created, configured,
      and verified with aws sts get-caller-identity. Blast radius contained.
- [ ] Scope terraform-runner IAM policy to least-privilege before any
      additional resources are deployed. (Open finding — Phase 2.)
- [ ] Set up remote state (S3 + DynamoDB) to remove local machine as
      single point of failure. (Open finding — Phase 2.)

---

## Lessons

This incident was handled correctly. The rotation was immediate, the response
was complete, and the account was not compromised. What this document adds is
the root cause analysis and the behavioral rules that prevent recurrence.

The most important lesson is not technical. It is this: the same instinct that
caused the exposure — sharing what is on screen to get help solving a problem
— is a natural and reasonable instinct. The rule is not to suppress that
instinct. The rule is to share error messages and commands, never credential
values. That distinction has to be automatic before the next troubleshooting
session begins.
