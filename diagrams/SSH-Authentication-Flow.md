# Diagram — SSH Authentication Flow

**Purpose:** Shows the Ed25519 digital signature authentication process between a workstation and GitHub.
**Phase:** 1 — Secure Engineering Foundations
**Related:** [02-SSH-GitHub/README.md](../02-SSH-GitHub/README.md), [decisions/ADR-002-SSH.md](../decisions/ADR-002-SSH.md)

---

## Key Pair Generation (one-time setup)

```
ssh-keygen -t ed25519 -C 'email@example.com'
         │
         ├──► id_ed25519       (PRIVATE KEY)
         │    Never shared. Never uploaded.
         │    Used to SIGN challenges.
         │
         └──► id_ed25519.pub   (PUBLIC KEY)
              Safe to share.
              Uploaded to GitHub Settings.
              Used to VERIFY signatures.
```

---

## Authentication Flow (every connection)

```
WORKSTATION                                    GITHUB
───────────                                    ──────

1. Connection attempt
   ────────────────────────────────────────►

2. GitHub sends random challenge
   ◄────────────────────────────────────────

3. Workstation SIGNS challenge
   using private key
   (private key never leaves the machine)
   ────────────────────────────────────────►

4. GitHub VERIFIES signature
   using registered public key
   │
   ├── Valid? ──► Access granted
   └── Invalid? ──► Access denied

5. No password crossed the network at any point.
```

---

## SSH vs HTTPS+PAT

```
HTTPS + PAT                        SSH Keys
────────────────────────────────   ────────────────────────────────
Token sent on every request        No credential transmitted
Token expires — requires rotation  No expiry — revoke on compromise
Token stored in credential manager Private key never leaves machine
One token compromised = access     One key compromised = revoke that
                                   machine only, others unaffected
```

---

## Ed25519 vs RSA

```
RSA-2048                 Ed25519
──────────────────────   ──────────────────────
Private key: ~1700 bytes Private key: ~411 bytes
~112-bit security        ~128-bit security
Slower                   Faster
Legacy — supported       Current standard
```

Use Ed25519 for all new key generation.

---

## Per-Machine Key Model

```
Laptop      ──► Key A (laptop-windows)
Work PC     ──► Key B (work-desktop)
EC2 server  ──► Key C (aws-ec2-prod)

Laptop lost: revoke Key A only.
             Work PC and EC2 unaffected.
```

---

## Nicoliv Energy Context

At Nicoliv Energy, vendor OT access follows the same model:
- Each vendor gets a named, scoped credential for a specific access path
- Access routes through a jump server — no direct connection to OT assets
- Sessions are recorded (IEC 62443 SR 2.8 requirement)
- Credentials revoked immediately on contract expiry or incident
- One vendor's compromise does not affect any other vendor's access path

The SSH key model for GitHub is the same architecture — at developer scale.
