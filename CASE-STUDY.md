# Case Study — Nicoliv Energy

> **Note:** Nicoliv Energy is a fictional organisation modelled on the operational profile of a real Crown-owned gas utility. All architecture, risks, and controls described in this repository use this environment as a consistent threat context. No real organisation's confidential information is represented here.

---

## Organisation Profile

| Attribute | Detail |
|---|---|
| Type | Crown corporation |
| Sector | Energy — natural gas distribution and transmission |
| Scale | Province-wide distribution network; cross-border export |
| Criticality | National Critical Infrastructure — loss of service affects public safety, heating, and industrial operations |

---

## Technology Environment

### IT Environment
- Corporate network: finance, HR, email, enterprise applications
- Windows Active Directory domain
- Remote access via VPN for staff and vendors
- Cloud workloads (migration in progress)

### OT Environment
- SCADA systems controlling gas pressure, flow, and distribution
- Remote Terminal Units (RTUs) at substations and metering points
- Industrial DMZ (IDMZ) separating IT and OT networks
- Purdue Model / IEC 62443 zone architecture
- OT vendor remote access — multiple third parties

### Vendor and Partner Connections
- Utility peers (power, telecommunications)
- Security and monitoring service providers
- Insurance and compliance auditors
- Equipment maintenance vendors requiring remote OT access

---

## Threat Profile

| Threat | Likelihood | Impact |
|---|---|---|
| Ransomware via IT network (lateral movement to OT) | High | Critical — potential loss of gas distribution control |
| Credential theft — VPN or remote access | High | High — unauthorised access to IT/OT boundary |
| Supply chain compromise — vendor remote access | Medium | Critical — vendor has trusted access to OT systems |
| Insider threat — misconfigured change | Medium | High — OT misconfig can cause physical safety event |
| Audit failure — no change trail | Low | High — regulatory consequence, loss of operating licence |

---

## Regulatory and Compliance Context

| Framework | Applicability |
|---|---|
| IEC 62443 | OT/SCADA security — zone architecture, remote access controls, change management |
| NIST CSF | Overall cybersecurity programme structure |
| NERC CIP | Applicable if bulk electric system assets are present |
| Provincial energy regulator | Operating licence conditions including security obligations |

---

## Why This Case Study

A Crown gas utility represents one of the highest-stakes IT/OT security environments:
- Cyber incidents have physical consequences (pressure, flow, safety)
- Regulatory obligations are stringent and licence-dependent
- Vendor access creates a complex trust boundary management problem
- IT/OT convergence is active — the attack surface is expanding

Every technical control documented in this repository is evaluated against this threat context. The question is never just "does this work?" — it is "what does this protect at Nicoliv Energy, and what happens if it fails?"

