# ADR-002 — Remote Authentication: SSH over HTTPS

**Status:** Accepted  
**Date:** 2026-06-04  
**Author:** Maximus Ikengwa  

---

## Context

This repository requires authentication to push commits to GitHub. Two methods are available:

| Method | Description |
|---|---|
| HTTPS + Personal Access Token (PAT) | Token-based credential presented over HTTPS |
| SSH Key Authentication | Asymmetric cryptographic authentication via SSH |

The choice of authentication method directly affects:
- Security posture of the development environment
- Operational friction over the lifetime of the project
- Alignment with production infrastructure patterns

---

## Decision

**Use Ed25519 SSH key authentication for all GitHub operations.**

---

## Rationale

**SSH over HTTPS+PAT:**

| Factor | HTTPS + PAT | SSH Keys | Decision basis |
|---|---|---|---|
| Credential transmission | Token sent on every request | No credential transmitted — digital signature only | SSH eliminates interception risk |
| Expiry | Token expires — requires rotation | No expiry — revoke only when needed | SSH reduces maintenance overhead |
| Credential storage risk | Token stored in credential manager — if manager is compromised, token exposed | Private key never leaves the machine — cannot be extracted via credential manager compromise | SSH provides stronger isolation |
| Enterprise compatibility | Can fail behind SSL-intercepting proxies | SSH (port 22) passes most corporate firewalls | SSH is more reliable in enterprise environments |
| Production alignment | PATs are GitHub-specific | Same key model used for EC2, Linux servers, network devices | SSH scales to production |

**Ed25519 over RSA:**

| Factor | RSA-2048 | Ed25519 | Decision basis |
|---|---|---|---|
| Key size | ~1700 bytes (private) | ~411 bytes (private) | Ed25519 is ~4× smaller |
| Security | 112-bit equivalent | 128-bit equivalent | Ed25519 is stronger |
| Performance | Slower signing and verification | Faster — optimised elliptic curve operations | Ed25519 is more efficient |
| Standard | Legacy — still supported | Current professional standard | Ed25519 is the correct choice for new keys |

---

## Consequences

**Positive:**
- No credentials cross the network — eliminates transmission interception risk
- Per-machine key pairs enable targeted revocation without affecting other machines
- Aligns with production infrastructure authentication model
- No rotation schedule required — revoke on compromise or machine retirement

**Negative:**
- Initial setup requires generating keys, adding public key to GitHub, and testing connection
- Private key security depends on physical machine security — passphrase recommended for shared machines
- Port 22 blocked in some highly restricted networks — workaround: SSH over HTTPS port (`ssh.github.com:443`)

---

## Threat Model

| Threat | Risk | Control | Residual Risk |
|---|---|---|---|
| Credential interception in transit | Attacker captures GitHub token | SSH uses digital signatures — no credential transmitted | None — no credential exists to intercept |
| Stolen private key file | Attacker gains unauthorised repo access | Private key never leaves the machine; passphrase adds encryption at rest | Compromised endpoint — mitigated by immediate key revocation on GitHub |
| Machine loss or theft | Unauthorised access to GitHub | Revoke the specific machine's key from GitHub Settings | Delay between theft and revocation — mitigated by prompt incident response |
| Man-in-the-middle on first connection | Accept wrong host fingerprint | Compare displayed fingerprint against GitHub's published fingerprints before accepting | User error on first connection — mitigated by documentation |
| Shared key across machines | Single key compromise affects all machines | One key pair per machine, named by machine | Process failure — mitigated by documented key management policy |

---

## Compliance Mapping

| Control | Standard | How SSH satisfies it |
|---|---|---|
| Identities and credentials managed | NIST CSF PR.AC-1 | Each machine has a unique, named, revocable credential. No shared credentials. |
| Human user identification and authentication | IEC 62443-3-3 SR 1.1 | Cryptographic proof of identity without password transmission — exceeds password-based authentication requirements for remote access |
| Least privilege | Zero Trust principles | Each key grants access only to authorised repositories. Scope is explicit. |

---

## Review Trigger

Reconsider this decision if:
- A corporate firewall permanently blocks SSH port 22 and port 443 SSH workaround
- Organisational policy mandates HTTPS+PAT with a secrets manager
- Hardware security keys (FIDO2/YubiKey) become the organisational standard — at which point migrate to hardware-bound SSH keys

