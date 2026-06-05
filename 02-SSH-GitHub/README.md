# 02 — SSH Authentication & GitHub

**Topic:** SSH Key Authentication + Remote Repository  
**Environment:** Windows 11, PowerShell, Git 2.54.0, GitHub  
**Case Study:** Nicoliv Energy — Crown gas utility (IT/OT environment)  
**Completed:** 2026-06-04  
**Previous:** [01 — Git Fundamentals](../01-Git-Fundamentals/)

---

## Prerequisites

Before starting this section:
- Git installed and configured (see section 01)
- GitHub account created at https://github.com
- PowerShell open and `git --version` returning a version number

---

## Overview

Git lives on your machine. GitHub is a separate server on the internet. They do not automatically know about each other.

This section builds the secure, permanent bridge between them using SSH key authentication — the professional standard used in enterprise environments, cloud infrastructure, and production systems worldwide.

**What this section covers:**
- Why SSH over HTTPS (with honest tradeoffs)
- How SSH authentication actually works
- Generating an Ed25519 key pair
- Registering the public key with GitHub
- Testing the authenticated connection
- Creating and pushing your first professional portfolio repository

---

## The Problem This Solves

GitHub requires proof of identity before accepting any pushed commits. Two authentication methods exist. Understanding why one is clearly superior is the difference between a professional decision and a beginner shortcut.

---

## Architecture

```
SSH Authentication Flow
───────────────────────

Your Machine                          GitHub
─────────────────                     ──────────────────────
                                      
  ┌─────────────┐                     ┌──────────────────┐
  │ Private Key │                     │   Public Key     │
  │ id_ed25519  │                     │  (registered     │
  │ (never      │                     │   in settings)   │
  │  leaves     │                     └────────┬─────────┘
  │  machine)   │                              │
  └──────┬──────┘                              │
         │                                     │
         │  1. Connection attempt              │
         │ ──────────────────────────────────► │
         │                                     │
         │  2. GitHub sends a random challenge │
         │ ◄────────────────────────────────── │
         │                                     │
         │  3. Machine SIGNS challenge         │
         │     using private key               │
         │ ──────────────────────────────────► │
         │                                     │
         │  4. GitHub VERIFIES signature       │
         │     using registered public key     │
         │     Identity confirmed.             │
         │     No password crossed the network.│
         └─────────────────────────────────────┘

Key principle: the private key never leaves your machine.
GitHub verifies a SIGNATURE, not a decrypted secret.
```

> **Technical precision:** SSH authentication uses *digital signatures*, not encryption. The private key signs a challenge; the public key verifies the signature. These are mathematically distinct operations. Conflating signing with encryption is a common error — the distinction matters in security engineering.

---

## Concepts

### SSH (Secure Shell)
A cryptographic network protocol for secure remote communication. Uses asymmetric cryptography — two mathematically linked keys where a signature created by one can only be verified by the other.

### Key Pair
Two files generated together as a matched pair:
- **Private key** (`id_ed25519`) — stays on your machine. Never shared. Never uploaded. If compromised: revoke the public key from GitHub immediately and generate a new pair.
- **Public key** (`id_ed25519.pub`) — registered with servers you want to trust you. Safe to share. Mathematically useless without the matching private key.

### Digital Signature (how SSH auth actually works)
The server generates a random challenge. Your machine creates a signature over that challenge using the private key. The server verifies the signature using the registered public key. Only the real private key produces a valid signature — identity proven. Nothing sensitive crosses the network.

### git remote
A named pointer to a repository on another machine or server. `origin` is the universal conventional name for the primary remote. Every tool, tutorial, and team uses `origin` — deviating creates confusion with no benefit.

### Upstream
The default remote branch your local branch tracks. Set with `-u` on the first push. After that, `git push` alone knows where to send commits.

---

## HTTPS vs SSH — Honest Comparison

| Factor | HTTPS + PAT | SSH Keys |
|---|---|---|
| Initial setup time | ~5 minutes | ~10 minutes |
| Credential expiry | Yes — token has a set expiry date | No — permanent until explicitly revoked |
| Credential storage | Token must be stored securely and rotated | Generate once, register once |
| Corporate firewall compatibility | Can fail — HTTPS traffic may be intercepted or blocked by proxies | Works — SSH (port 22) typically passes corporate firewalls |
| Scales to production | No — PATs are GitHub-specific | Yes — same key model secures EC2, Linux servers, network devices |
| Industry standard | Beginner shortcut | Professional standard |
| Security posture | Credential can be stolen if storage is compromised | Private key never leaves the machine |

> **Decision: SSH.** The additional 5 minutes of setup is a one-time cost. Every professional working at scale uses SSH. The only valid reason to use HTTPS+PAT is a corporate environment that explicitly blocks SSH port 22 — in which case, use HTTPS with a PAT stored in a secrets manager, not in plaintext.

---

## Implementation

### Step 1 — Check for existing SSH keys

```powershell
cd ~
ls ~/.ssh
```

**Output (no keys):**
```
Mode         LastWriteTime    Length  Name
----         -------------    ------  ----
-a----       2025-12-24       1692    known_hosts
-a----       2025-12-24       944     known_hosts.old
```

> **What `known_hosts` is:** every time you SSH into a server for the first time, your machine records that server's public key fingerprint here. On future connections, SSH checks this record. If the fingerprint changed unexpectedly, SSH warns you — this is host-based attack detection (a defence against DNS hijacking and man-in-the-middle attacks). The dates here (2025-12-24) reflect prior lab work on this machine. Not sensitive. Critical to understand.

No `id_ed25519` or `id_rsa` files present — no SSH keys exist. Generate a fresh pair.

---

### Step 2 — Generate the key pair

```powershell
ssh-keygen -t ed25519 -C 'your-email@example.com'
```

**When prompted:**
```
Enter file in which to save the key (~/.ssh/id_ed25519): [press Enter — accept default]
Enter passphrase (empty for no passphrase):              [press Enter — no passphrase]
Enter same passphrase again:                             [press Enter]
```

**Output:**
```
Your identification has been saved in C:\Users\[user]\.ssh\id_ed25519
Your public key has been saved in C:\Users\[user]\.ssh\id_ed25519.pub
The key fingerprint is:
SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx your-email@example.com
```

> **Algorithm — Ed25519 vs RSA:**
> Ed25519 is a modern elliptic curve digital signature algorithm. It produces 256-bit keys that are shorter, faster, and provide stronger security guarantees than RSA-2048 (which produces ~1700-byte private keys vs Ed25519's ~411 bytes — roughly 4× larger for equivalent or lesser security). Ed25519 is the current professional standard for new key generation. RSA remains supported for legacy compatibility but should not be used for new keys.
>
> **Passphrase — why omitted here:**
> A passphrase encrypts the private key file on disk. On a shared workstation or remote server, use one — if the machine is compromised, the key file alone is insufficient. On a personal laptop you physically control, the friction outweighs the marginal benefit. The real protection is physical control of the machine.
>
> **PowerShell quoting — common trap:**
> `ssh-keygen -t ed25519 -C "email@example.com"` with double quotes can produce "Too many arguments" in PowerShell. PowerShell handles double quotes differently from Bash — it may interpret the quoted string as multiple arguments. Use single quotes in PowerShell for literal strings.

---

### Step 3 — Verify the key pair

```powershell
ls ~/.ssh
```

**Output:**
```
Mode         LastWriteTime    Length  Name
----         -------------    ------  ----
-a----       2026-06-04       411     id_ed25519
-a----       2026-06-04       101     id_ed25519.pub
-a----       2025-12-24       1692    known_hosts
-a----       2025-12-24       944     known_hosts.old
```

Two new files dated today. Private key: ~411 bytes. Public key: ~101 bytes.

> The public key is smaller than the private key because it contains only the public component of the key pair — the part GitHub needs to verify signatures. The private key contains both components (for signing) plus metadata.

---

### Step 4 — Copy the public key to clipboard

```powershell
cat ~/.ssh/id_ed25519.pub | clip
```

Silence = success. The public key is on your clipboard.

> **The pipe operator `|`:**
> Sends the *output* of one command as the *input* of the next. `cat` reads the file and outputs the content. `|` intercepts that output. `clip` receives it and places it on the Windows clipboard instead of printing to screen.
>
> The pipe is one of the most powerful primitives in the terminal — it chains simple tools to accomplish complex operations without writing code. You will use it constantly: piping output to `grep` to filter, to `sort`, to `wc -l` to count lines, to redirect into files. Learn to read pipes left to right: *what does the first command produce → what does the second command do with it.*

---

### Step 5 — Register the public key on GitHub

**Navigation:** Profile picture → Settings → SSH and GPG keys → New SSH key

| Field | Value |
|---|---|
| Title | A name identifying this machine — e.g., `laptop-windows` or `home-dell` |
| Key type | Authentication Key |
| Key | Paste (Ctrl+V) |

Click **Add SSH key**. GitHub may prompt for your account password to confirm.

> **Why name by machine, not by purpose:**
> You will accumulate keys over time — personal laptop, work laptop, a server, a CI/CD pipeline. Naming by machine (`laptop-windows`, `aws-ec2-prod`) tells you immediately which key to revoke if a device is lost or decommissioned. Naming by purpose (`github-key`) tells you nothing when you have three of them.
>
> **Principle of least privilege in key management:** each machine or service gets its own key pair. Shared keys mean that revoking access for one entity breaks access for all others sharing that key. One machine, one key — targeted revocation without collateral damage. This is the same principle behind per-vendor credentials at Nicoliv Energy's OT remote access.

---

### Step 6 — Test the connection

```powershell
ssh -T git@github.com
```

**First connection — accept the host fingerprint:**
```
The authenticity of host 'github.com (140.82.112.4)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

**Expected output:**
```
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
Hi Maxilyte! You've successfully authenticated, but GitHub does not provide shell access.
```

> **"does not provide shell access" is not an error.**
> This message confirms two things: (1) your identity was verified successfully, and (2) GitHub is not a general-purpose Linux server you can log into interactively. Git operations over SSH work perfectly. This response is expected and correct.
>
> **The warning line** is GitHub's fingerprint being recorded in your `known_hosts` file. On every future connection, SSH will verify GitHub's fingerprint matches this record. If it ever changes unexpectedly, SSH will refuse the connection and warn you — potential attack detection.
>
> **Verifying GitHub's fingerprint:** GitHub publishes their official SSH key fingerprints at https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints. If you want to verify before accepting, compare the displayed fingerprint against the published one. In a high-security environment, you would always do this.

---

### Step 7 — Create your professional portfolio repository

```powershell
cd ~
mkdir Cyber-Lab-v2
cd Cyber-Lab-v2
git init
notepad README.md
```

Write a README that positions the repository clearly. Every word on this page is visible to anyone who finds your GitHub profile:

```markdown
# Cyber-Lab-v2

**Owner:** Maximus Ikengwa
**Started:** 2026-06-04
**Target profile:** Cloud Security / DevSecOps Engineer with IT/OT Security depth

This repository documents a structured journey from IT professional to Cloud/DevSecOps Engineer.
Every build is documented with the why behind each decision and its business impact,
modelled on a real Crown gas utility environment (Nicoliv Energy).

Built in public. Every commit is real work.
```

```powershell
git add README.md
git commit -m "Initial commit: Cloud/DevSecOps lab — IT/OT security depth, built in public"
```

**Output:**
```
[main (root-commit) a159988] Initial commit: Cloud/DevSecOps lab — IT/OT security depth, built in public
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 README.md
```

> **Why this specific commit message:**
> Commit one is permanent and public. It is the first line a recruiter or engineer reads in the commit history. It must convey in three seconds: what the repo is (Cloud/DevSecOps lab), the differentiator (IT/OT depth), and the working standard (built in public, real work). That is positioning embedded in the version control record.
>
> **Why IT/OT, not just OT:**
> Most cloud engineers have no OT exposure. Most OT engineers cannot build cloud-native DevSecOps pipelines. Both halves of this background are rare and the combination is rarer still. State both. Never undersell a differentiator.

---

### Step 8 — Connect to GitHub and push

On GitHub: create a new empty repository named `Cyber-Lab-v2`. **Do not tick "Add a README" or any other initialisation option.** An empty repository has no commit history — if GitHub creates one, your local history and GitHub's history become incompatible and push fails with a "refusing to merge unrelated histories" error.

```powershell
git remote add origin git@github.com:YourUsername/Cyber-Lab-v2.git
git push -u origin main
```

**Output:**
```
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Delta compression using up to 6 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 686 bytes | 228.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To github.com:YourUsername/Cyber-Lab-v2.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

> **Reading the output:**
> - `Enumerating/Counting/Compressing` — Git packaged your commit objects into a delta-compressed pack before transfer
> - `Writing objects: 3/3, 686 bytes` — only 686 bytes transferred. Git sends object differences, not full file copies. This efficiency compounds — a repo with 10,000 commits does not transfer its entire history on every push, only the new commits.
> - `* [new branch] main -> main` — the `main` branch was created on GitHub and linked to your local `main`
> - `branch 'main' set to track 'origin/main'` — the `-u` flag registered the upstream. `git push` alone is sufficient from now on.

---

### Step 9 — Verify and fix Markdown rendering

Open `https://github.com/YourUsername/Cyber-Lab-v2` in your browser.

Check that:
- The README renders with formatted bold text, not raw `**asterisks**`
- Paragraphs have clear spacing between them
- No lines are running together unexpectedly

> **Markdown rendering rule:** GitHub Markdown requires a blank line between every block element — between paragraphs, between a heading and its body, between bold labels and text. Without blank lines, elements collapse into each other. Always view the rendered result on GitHub after the first push and fix before the repo gets any attention.

If the formatting is wrong, edit the file, add blank lines between elements, then:

```powershell
git add README.md
git commit -m "Fix README markdown formatting"
git push
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Permission denied (publickey)` | Key not registered on GitHub, or wrong key used | Verify the key is in GitHub Settings → SSH keys. Run `ssh -T git@github.com` to test. |
| `Too many arguments` on `ssh-keygen` | PowerShell double-quote parsing | Use single quotes: `-C 'email@example.com'` |
| `refusing to merge unrelated histories` | GitHub repo was initialised with a README | Delete the GitHub repo and recreate it empty, or use `git pull origin main --allow-unrelated-histories` then resolve conflicts |
| `git push` rejected — non-fast-forward | Remote has commits your local doesn't | Run `git pull --rebase origin main` then push again |
| SSH connection timeout | Port 22 blocked by firewall | Try SSH over HTTPS: use `git@ssh.github.com:443` as the host |

---

## Business Impact

SSH key authentication maps directly to enterprise identity and access controls:

| Security Control | SSH Implementation | Enterprise Equivalent at Nicoliv Energy |
|---|---|---|
| No shared secrets | Private key never leaves the machine | Per-vendor certificates for OT remote access |
| Per-endpoint identity | Each machine has its own named key | Endpoint identity in zero-trust architecture |
| Instant revocation | Remove key from GitHub Settings | Revoke a single vendor's access without affecting others |
| No credential in transit | Digital signature only — no secret sent | Eliminates credential interception on OT network perimeter |
| Audit trail | Key registration logged with timestamp | Access event attribution for compliance reporting |
| Least privilege | Each key grants access only to authorised repos | Role-based access scoped to minimum required |

**Compliance mapping:**

| Standard | Control | How SSH satisfies it |
|---|---|---|
| NIST CSF PR.AC-1 | Identities and credentials managed for authorised devices | Each machine has a unique, named key. Revocation is immediate and targeted. No shared credentials. |
| IEC 62443-3-3 SR 1.1 | Human user identification and authentication | Cryptographic proof of identity without password transmission — stronger than password-based authentication for remote access to OT-adjacent systems |

**Interview line:** *"I use SSH key authentication because it eliminates credential interception risk, provides a named and revocable identity per machine, and uses the same cryptographic model — digital signatures — that secures production infrastructure from GitHub repositories to EC2 instances to vendor remote access in OT environments."*

---

## Lessons Learned

| Lesson | What happened | Rule |
|---|---|---|
| `Too many arguments` on keygen | Double quotes in PowerShell parsed incorrectly | Use single quotes for literal strings in PowerShell |
| GitHub repo initialised accidentally | Checked "Add README" on creation | Empty repo on GitHub when pushing existing local history. Initialisation creates a conflicting commit. |
| `git push` rejected | Remote had diverged from local | `git pull --rebase` before pushing when you suspect remote divergence |
| README formatting broken | Missing blank lines between Markdown elements | Always view the rendered result on GitHub after first push |
| `-u` flag forgotten | First push went through but future pushes needed `origin main` | Use `-u` on the first push. Once only. |

---

## References
- OpenSSH: https://www.openssh.com
- Ed25519 algorithm: https://ed25519.cr.yp.to
- GitHub SSH documentation: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- GitHub published SSH fingerprints: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
- NIST CSF PR.AC-1: https://www.nist.gov/cyberframework
- IEC 62443-3-3 SR 1.1 — Human user identification and authentication

---

## Threat Model

| Threat | Risk | Control | Residual Risk |
|---|---|---|---|
| Credential interception in transit | Attacker captures authentication token | SSH digital signature — no credential transmitted | None — nothing to intercept |
| Private key theft | Attacker gains unauthorised repository access | Private key stays on machine; revoke immediately on suspected compromise | Compromised endpoint — key revocation is the incident response |
| Machine loss or theft | Unauthorised GitHub access before key is revoked | Revoke specific machine key from GitHub Settings | Delay between loss and revocation — mitigated by prompt response |
| Wrong host fingerprint accepted | Man-in-the-middle intercepts connection | Compare fingerprint against GitHub's published values before first acceptance | User error on first connection |
| Shared key across multiple machines | Single compromise affects all machines | One key pair per machine, named by machine | Process failure — mitigated by documented key naming policy |

> **At Nicoliv Energy:** vendor remote access into the OT environment follows the same principle — one named credential per vendor per endpoint. Compromise of one vendor's credential does not cascade to others. Revocation is immediate and targeted. SSH key management at the developer level is the same security model at smaller scale.

---

## Related Documents

- [ADR-002 — Remote Authentication: SSH over HTTPS](../decisions/ADR-002-SSH.md)
- [Case Study — Nicoliv Energy](../CASE-STUDY.md)
- [Previous: 01 — Git Fundamentals](../01-Git-Fundamentals/)
