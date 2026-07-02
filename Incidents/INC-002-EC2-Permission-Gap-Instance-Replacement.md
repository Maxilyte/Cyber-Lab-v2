# INC-002: Unintended EC2 Instance Replacement Due to Incomplete Least-Privilege IAM Policy

**Status:** Resolved
**Date:** 2026-07-01
**Severity:** Medium (no security exposure, but unplanned resource destruction and rebuild)
**Author:** Max Ikengwa

## Summary

While deploying the first EC2 compute layer (`ec2.tf` — bastion, idmz, ot_zone instances) under Phase 2, the `terraform-runner` IAM policy was missing several permissions required to fully create and verify EC2 instances. This caused Terraform to successfully launch the instances but fail on follow-up state-reading calls, marking them "tainted." Once all required permissions were finally in place, the next `terraform apply` destroyed and recreated all three instances rather than simply confirming their existing state — resulting in new instance IDs, new host SSH keys, and wasted compute/creation cycles.

No data was lost and no security control was bypassed. The root cause was a gap in IAM scope, not a misconfiguration of the instances or network themselves.

## Timeline

| Time (approx, same session) | Event |
|---|---|
| T+0 | `terraform apply` on `ec2.tf` begins. `aws_key_pair.cyber_lab_v2` fails: `ec2:ImportKeyPair` not permitted. |
| T+1 | `iam.tf` updated to add `ImportKeyPair` / `DeleteKeyPair`. Apply retried. |
| T+2 | Key pair succeeds. `RunInstances` succeeds for all three instances (this action was already permitted). Follow-up read fails: `ec2:DescribeInstanceAttribute` not permitted. All three instances now exist in AWS but are marked tainted in Terraform state. |
| T+3 | `iam.tf` updated to add `DescribeInstanceAttribute`. Apply retried — same error repeats, because `terraform apply` refreshes all existing state (including the three already-created instances) before it can reach the point of applying the IAM policy fix, and that refresh itself fails on the same missing permission, so the fix never actually reaches AWS. |
| T+4 | Diagnosed the refresh-before-apply behavior. Used `terraform apply -target="aws_iam_policy.terraform_runner"` to update only the policy, bypassing the blocked refresh of the tainted instances. |
| T+5 | Waited ~20-30s for IAM propagation. Full `terraform apply` retried — new error: `ec2:DescribeVolumes` not permitted (a different read call than the one just fixed). |
| T+6 | `iam.tf` updated again to add `DescribeVolumes` and proactively `DescribeInstanceCreditSpecifications` (needed for `t3.micro`'s burstable CPU credit read) to avoid a further round-trip. Same targeted-apply + propagation-wait pattern repeated. |
| T+7 | Full `terraform apply` finally succeeds in refreshing state. Because all three instances were still marked tainted from the earlier partial failures, Terraform's plan showed `-/+ destroy and then create replacement` for all three, not just a clean read. |
| T+8 | Applied. All three instances destroyed and recreated cleanly. New instance IDs assigned. Three-hop SSH chain (bastion -> idmz -> ot_zone) re-verified live afterward with no issues. |

## Root Cause

The `terraform-runner` least-privilege IAM policy (established in earlier Phase 2 work, scoped from CloudTrail activity analysis covering network-only resources) had never been exercised against EC2 compute actions before this session. It was missing:

- `ec2:ImportKeyPair`, `ec2:DeleteKeyPair`
- `ec2:DescribeInstanceAttribute`
- `ec2:DescribeVolumes`
- `ec2:DescribeInstanceCreditSpecifications`

AWS's `UnauthorizedOperation` errors only reveal one denied action at a time (Terraform calls actions sequentially and stops at the first denial), so each missing permission surfaced only after the previous one was fixed — there was no way to see the full gap in one pass.

The instance replacement was a **secondary effect**, not the root cause itself: Terraform marks any resource "tainted" if creation partially succeeds but a subsequent read fails. Once tainted, the next successful apply always destroys and recreates rather than reconciling — this is standard Terraform behavior, working as designed, but it meant the end state included unnecessary resource churn that a fully-scoped policy would have avoided entirely.

## Impact

- Three EC2 instances destroyed and recreated (new instance IDs, new host SSH keys — required regenerating known_hosts entries)
- No data loss (instances were freshly provisioned Amazon Linux 2023, no persistent workload yet)
- No security exposure — the segmentation (security groups, subnet placement) was never weakened at any point; the failures were purely IAM read/write permission gaps, not authorization bypasses
- Approximately 3-4 additional `terraform apply` cycles consumed versus a clean single-pass deployment
- No cost impact beyond a few extra minutes of `t3.micro` billing during the destroy/recreate cycle

## Resolution

Added the missing EC2 permissions to `terraform-runner`'s IAM policy (`iam.tf`), applied via targeted apply (`-target`) to work around the refresh-before-apply blocking behavior, waited for IAM propagation between attempts, then ran a full apply to reconcile tainted state. Final result: all three instances live, correctly placed in their intended subnets and security groups, three-hop SSH segmentation chain verified working end to end.

## Prevention

Documented in `IAM-Debugging-and-SG-Patterns-Field-Guide.md`: the full `aws_instance` permission cluster (`RunInstances`, `TerminateInstances`, `StopInstances`, `StartInstances`, `ModifyInstanceAttribute`, `DescribeInstances`, `DescribeInstanceAttribute`, `DescribeInstanceCreditSpecifications`, `DescribeVolumes`, `DescribeInstanceTypes`, `DescribeImages`, `ImportKeyPair`, `DeleteKeyPair`) should be added to a least-privilege policy **proactively**, in one pass, the first time EC2 compute is introduced to a project — rather than discovered reactively, one `UnauthorizedOperation` error at a time. This incident is the direct source of that checklist.

## Tradeoffs — when the response here would be wrong

- If this had been a production environment with live workloads on the affected instances, unplanned destroy/recreate would be unacceptable regardless of cause — the correct response there would have been to halt immediately after the first tainted-resource warning, restore from the last known-good state or manually untaint after confirming the instance was actually healthy in AWS (`terraform untaint`), rather than pushing forward to a clean apply that forces replacement.
- Using `-target` to bypass a blocked refresh is a legitimate recovery technique for exactly this kind of chicken-and-egg permission lockout, but it is explicitly flagged by Terraform as "not for routine use" — repeated reliance on `-target` instead of fixing IAM scope properly would be a process smell, not a fix.

## Related

- `IAM-Debugging-and-SG-Patterns-Field-Guide.md`
- `iam.tf`, `ec2.tf`
- INC-001 (credential exposure, June 14 2026)
