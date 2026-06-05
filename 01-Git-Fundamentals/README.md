# 01 — Git Fundamentals

**Topic:** Version Control with Git  
**Environment:** Windows 11, PowerShell, Git 2.54.0  
**Case Study:** Nicoliv Energy — Crown gas utility (IT/OT environment)  
**Completed:** 2026-06-02  
**Next:** [02 — SSH Authentication & GitHub](../02-SSH-GitHub/)

---

## Prerequisites

Before starting this section:
- Windows 11 machine with administrator rights
- Internet access for downloading Git
- A text editor (Notepad is sufficient)

---

## Overview

Git is a distributed version control system. It tracks every change to your project as a snapshot, stores the full history locally, and lets you recover any previous state instantly.

This is not a developer convenience. It is a **financial and risk control** — it prevents lost work, enables fast recovery from bad deployments, and produces a permanent audit trail that compliance frameworks require.

**What this section covers:**
- The problem Git solves and why it exists
- Installing Git on Windows with full understanding of every installer decision
- Configuring identity
- The core workflow: edit → stage → commit
- Inspecting changes with `git diff`
- Protecting secrets with `.gitignore`
- Viewing and reading commit history

---

## The Problem Git Solves

Without version control, teams share files by email. Work gets overwritten. Nobody knows what changed, when, or who changed it. A developer costs a company $400–600 per day — losing half a day of five people's work to an overwrite burns over $1,000 on nothing.

Git solves four distinct problems:

| Problem | Without Git | With Git |
|---|---|---|
| Lost work | Files overwritten permanently | Every version recoverable |
| Bad deployment | Hours of manual rollback | Revert in seconds |
| Accountability | No record of who changed what | Permanent attributed history |
| Parallel work | Files collide when shared | Branches merge cleanly |

**At Nicoliv Energy specifically:** every change to a firewall rule, OT system configuration, or security policy must be traceable — who made it, when, and under what authority. A failed audit because change history cannot be proven costs contracts, triggers regulatory investigation, and damages licence to operate. Git is the control that prevents that.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Git Workflow                          │
│                                                         │
│  ┌──────────────┐   git add   ┌──────────────┐          │
│  │   Working    │ ──────────► │   Staging    │          │
│  │  Directory   │             │    Area      │          │
│  │  (your files)│ ◄────────── │  (the box)   │          │
│  └──────────────┘  git restore└──────┬───────┘          │
│                                      │ git commit        │
│                                      ▼                   │
│                             ┌──────────────┐             │
│                             │   Local Repo │             │
│                             │  (.git folder│             │
│                             │   = history) │             │
│                             └──────┬───────┘             │
│                                    │ git push             │
│                                    ▼                      │
│                             ┌──────────────┐             │
│                             │    Remote    │             │
│                             │   (GitHub)   │             │
│                             └──────────────┘             │
└─────────────────────────────────────────────────────────┘
```

> **Why three zones?** The staging area is the key design decision that separates Git from simpler tools. It lets you work on ten things but commit them as three separate, meaningful snapshots — keeping history clean, readable, and auditable.

---

## Concepts

### Repository
A project folder that Git is tracking — the folder plus its entire history. Created by `git init`, which adds a hidden `.git` folder. That folder contains every snapshot ever taken. Delete `.git` and you lose all history; the files remain but the time machine is gone.

### Commit
A snapshot of everything in staging at a specific moment. Every commit is stamped with: author, timestamp, a unique SHA-1 fingerprint (hash), and a message. The hash is immutable — any change to the content changes the hash, making history tamper-evident.

### Staging Area
The preparation zone between your working files and a commit. You explicitly choose what goes into each snapshot using `git add`. This two-step design means your commit history reflects deliberate decisions, not accidental saves.

### HEAD
Your current position in the history. `HEAD -> main` means you are at the most recent commit on the `main` branch. When you switch branches or check out an old commit, HEAD moves.

### Branch
A named pointer to a specific commit. `main` is the default branch. Branching is covered in a later section — for now, think of it as the primary timeline.

---

## Environment Setup

### Step 1 — Verify Git is installed

```powershell
git --version
```

**If installed:**
```
git version 2.54.0.windows.1
```

**If not installed:**
```
git : The term 'git' is not recognized as the name of a cmdlet, function,
script file, or operable program.
```

> **Common trap — spacing:** `git -- version` (with a space) produces the same "not recognized" error even when Git is installed. The correct command is `git --version` — two dashes attached directly to "version" with no space. The terminal executes exactly what you type. One space breaks it.

---

### Step 2 — Install Git on Windows

Download from: `https://git-scm.com/download/win`

Run the installer. Most screens use the correct defaults. The table below covers every screen — decisions that matter are marked.

| Screen | Choice | Action | Why |
|---|---|---|---|
| Default editor | Notepad | **Change** | Vim has no visible way to type or exit — beginners get trapped. Notepad opens, you type, you save, you close. |
| Initial branch name | `main` | **Change** | GitHub defaults to `main`. Leaving this as `master` causes a history conflict on first push. Set once, problem never occurs. |
| PATH environment | Middle (Recommended) | Leave | Adds `git` to Windows PATH so it works in PowerShell, CMD and Git Bash. Without this, "not recognized" persists after install. |
| HTTPS transport | Native Windows Secure Channel | Leave | Uses the OS certificate trust store — auto-updates and trusts company Root CA certs distributed via Active Directory. Works behind corporate firewalls. The OpenSSL option maintains its own cert list and can fail in enterprise networks. |
| SSH executable | Bundled OpenSSH | Leave | Uses Git's own SSH binary. Consistent behaviour regardless of what else is installed on the machine. |
| Git Credential Manager | Checked | Leave | Stores GitHub credentials in the Windows Credential Manager vault — encrypted at rest, never plaintext. Eliminates repeated prompts. |
| Experimental options | Unchecked | Leave | Production machines run stable, tested software. Experiments belong in isolated environments. |

> **Principle:** defaults exist because the makers tuned them for the 95% case. Changing settings you do not understand earns nothing and risks subtle breakage. Change only what you understand and have a reason for.

**After install — open a fresh terminal:**
```powershell
# Close the existing PowerShell window entirely
# Open a new one, then verify:
git --version
```

> **Why a fresh terminal:** the PATH variable — Windows' list of where to find programs — is read once when a terminal starts. The old window opened before Git existed and will never find it. Always open a fresh terminal after installing any tool. This single habit resolves half of all "command not found" problems.

---

### Step 3 — Configure identity

```powershell
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

> **Why:** every commit is permanently stamped with this identity — the "who" in the who-changed-what-when audit trail. `--global` applies to all repositories on this machine; set it once. **No output = success.** In the terminal, silence means the command worked. Errors are always loud.

**Verify:**
```powershell
git config --global user.name
# Output: Your Name

git config --global user.email
# Output: your-email@example.com
```

---

## Implementation — Core Git Workflow

### Step 4 — Create a repository

```powershell
cd ~
mkdir Git-Practice
cd Git-Practice
git init
```

**Output:**
```
Initialized empty Git repository in C:\Users\[user]\Git-Practice/.git/
```

**Verify the hidden `.git` folder exists:**
```powershell
ls -Force
```

**Output:**
```
Mode     LastWriteTime    Length  Name
----     -------------    ------  ----
d--h--   2026-06-02       0       .git
```

> **`d--h--` breakdown:** `d` = directory, `h` = hidden. This folder contains the entire version history. It is hidden by default because users should never edit it directly. `git` commands manage it. Plain `ls` shows nothing; `ls -Force` reveals it. This is the difference between a folder and a repository.

---

### Step 5 — Create a file

```powershell
echo "# My Git Practice" > README.md
ls
```

**Output:**
```
Mode     LastWriteTime    Length  Name
----     -------------    ------  ----
-a----   2026-06-02       38      README.md
```

> **Critical distinction — one arrow vs two:**
> ```
> >   overwrites the entire file (destroys existing content)
> >>  appends to the end of the file (preserves existing content)
> ```
> A single `>` on an existing file wipes it silently. No confirmation, no undo outside of Git. The terminal does exactly what you type.

---

### Step 6 — Inspect before staging

Before staging anything, check what actually changed:

```powershell
git diff
```

**Output (new untracked file shows nothing — use `git status` first):**
```powershell
git status
```

**Output:**
```
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        README.md

nothing added to commit but untracked files present
```

> **`git diff` vs `git status`:**
> - `git status` answers: *what is the state of my working directory and staging area?*
> - `git diff` answers: *exactly what lines changed in tracked files since the last commit?*
> - `git diff --staged` answers: *exactly what lines am I about to commit?*
>
> In daily professional work, you run `git diff --staged` before every commit to verify you are snapshotting exactly what you intend — not more, not less. This habit prevents committing unintended changes or sensitive data.

---

### Step 7 — Stage the file

```powershell
git add README.md
git status
```

**Output:**
```
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   README.md
```

> **Green = staged = ready to commit.** The file moved from "Untracked" to "Changes to be committed." It is now in the staging area — in the box, waiting to be sealed. Nothing is permanent yet. You can still unstage with `git rm --cached README.md` if you change your mind.

---

### Step 8 — Commit

```powershell
git commit -m "Add README file for Git practice"
```

**Output:**
```
[main (root-commit) 05e7c9a] Add README file for Git practice
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 README.md
```

> **Reading the output:**
> - `root-commit` — the first commit; the root of all future history
> - `05e7c9a` — the commit's SHA-1 fingerprint. Unique. Immutable. Any change to content would produce a completely different hash — making history tamper-evident.
> - `1 file changed` — confirms exactly what was in staging
>
> **Commit message convention:** use present tense — "Add" not "Added". A commit message describes what the snapshot *does* to the project, not what you did in the past. Write it for someone with no memory of today — in six months, that person is you.
>
> **Bad:** `update`, `fix`, `changes`, `wip`  
> **Good:** `Add README`, `Fix null pointer in auth handler`, `Remove hardcoded credentials from config`

---

### Step 9 — Protect secrets with `.gitignore`

Before the next commit, create a `.gitignore` file:

```powershell
notepad .gitignore
```

Add these entries and save:

```
# Environment variables and secrets
.env
*.env
secrets.txt
credentials.json

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
*.swp
```

```powershell
git add .gitignore
git commit -m "Add .gitignore to exclude secrets and OS files"
```

> **Why this matters for security professionals specifically:**
> One of the most common real-world security incidents is accidental credential exposure via Git — API keys, passwords, and tokens committed to public repositories. GitHub scans public repos for common secret patterns and notifies services, but by then the credential is already exposed in history.
>
> `.gitignore` tells Git to never track listed files. It does not remove already-committed files — prevention only, not cure. Add it before you commit anything sensitive, not after.
>
> **At Nicoliv Energy:** committing infrastructure credentials, SCADA connection strings, or API keys to a shared repository would be a critical security incident. `.gitignore` is the first line of defence.

---

### Step 10 — Repeat the loop and inspect changes

```powershell
echo "## Purpose" >> README.md
echo "This repo documents my Git learning." >> README.md
```

**Now inspect what changed before staging:**
```powershell
git diff README.md
```

**Output:**
```diff
diff --git a/README.md b/README.md
index 8178c9b..f3a9d4e 100644
--- a/README.md
+++ b/README.md
@@ -1 +1,3 @@
 # My Git Practice
+## Purpose
+This repo documents my Git learning.
```

> **Reading a diff:**
> - Lines starting with `+` (green) — added
> - Lines starting with `-` (red) — removed
> - Lines with no prefix — unchanged context
>
> Always read your diff before committing. This is the habit that catches accidental changes, leftover debug code, and sensitive data before they enter the permanent record.

```powershell
git add README.md
git diff --staged        # final check — what am I about to commit?
git commit -m "Add purpose section to README"
```

---

### Step 11 — View history

```powershell
git log --oneline
```

**Output:**
```
93cbd95 (HEAD -> main) Add purpose section to README
d111ad2 Add .gitignore to exclude secrets and OS files
05e7c9a Add README file for Git practice
```

**For a richer view with branch visualization:**
```powershell
git log --oneline --graph --all
```

> **`HEAD -> main`** — your current position. HEAD is a pointer; `main` is the branch; `93cbd95` is the specific commit you are on.
>
> **`--graph --all`** becomes essential once you have multiple branches — it draws the branching and merging history as ASCII art directly in the terminal. Professional engineers use this constantly.

---

## Business Impact

| Risk | Exposure Without Git | Protection With Git |
|---|---|---|
| Overwritten work | Permanent loss, no recovery | Every version recoverable by hash |
| Bad deployment | Manual rollback — minutes to hours of downtime | `git revert` in seconds |
| Audit failure | No provable change trail | Immutable, timestamped, attributed history |
| Credential exposure | No tracking of what was committed | `.gitignore` prevents; history shows if something slipped |
| Disaster recovery | Dead machine = lost project | Full history on every clone and on GitHub |

**Compliance mapping:**

| Standard | Control | How Git satisfies it |
|---|---|---|
| NIST CSF PR.PT-1 | Audit/log records determined, documented, implemented, reviewed | Every commit is a timestamped, attributed, immutable record of exactly what changed and who changed it — meeting the audit log requirement automatically |
| IEC 62443-2-1 | Security management — change management | Git commit history provides the change log required for OT system modifications — who, what, when, and the stated reason |

**Interview line:** *"We use Git because it protects the business from lost work, enables recovery from a bad deployment in seconds, and automatically generates the immutable change trail that compliance frameworks like NIST CSF and IEC 62443 require — it is a risk control, not just a developer tool."*

---

## Lessons Learned

| Lesson | What happened | Rule |
|---|---|---|
| `git -- version` fails | Space between `--` and `version` | Terminal is literal. No spaces in flags. |
| `-oneline` fails | Single dash before multi-char flag | Short flags use one dash (`-v`). Long flags use two (`--oneline`). |
| "Not recognized" after install | Old terminal window | PATH loads at terminal start. Always open a fresh window after installing. |
| Silence after `git config` | Expected — no output | Terminal is silent on success. Errors are always loud. |
| Committed a secret accidentally | No `.gitignore` set up | Add `.gitignore` before the first real commit. Prevention only. |

---

## References
- Git documentation: https://git-scm.com/doc
- Git Book (free): https://git-scm.com/book/en/v2
- NIST CSF PR.PT-1: https://www.nist.gov/cyberframework
- IEC 62443-2-1 Security management system requirements

---

## Threat Model

| Threat | Risk | Control | Residual Risk |
|---|---|---|---|
| Accidental credential commit | API keys, passwords, or tokens exposed publicly on GitHub | `.gitignore` configured before first commit; `git diff --staged` reviewed before every commit | Human error bypassing `.gitignore` — GitHub secret scanning provides a secondary alert |
| Unattributed change | Audit trail has a gap — compliance evidence is incomplete | `user.name` and `user.email` configured globally before any commit | Shared machine use — mitigated by per-user Git configuration |
| Tampered history | Evidence integrity undermined — change record cannot be trusted | SHA-1 hash chain — any modification changes all subsequent hashes, making tampering detectable | Sophisticated attacker with full repository control — outside this threat model |
| Machine failure | Work lost permanently | GitHub remote serves as off-site backup; every clone is a full copy | GitHub availability — mitigated by Git's distributed model |

> **At Nicoliv Energy:** an unattributed change to a firewall rule or OT system configuration creates a compliance gap under IEC 62443-2-1 change management requirements. Git's identity stamping on every commit closes that gap automatically — provided `user.name` and `user.email` are configured correctly from the start.

---

## Related Documents

- [ADR-001 — Version Control: Git](../decisions/ADR-001-Git.md)
- [Case Study — Nicoliv Energy](../CASE-STUDY.md)
- [Next: 02 — SSH Authentication & GitHub](../02-SSH-GitHub/)
