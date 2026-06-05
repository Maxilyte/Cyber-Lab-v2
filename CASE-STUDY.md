# Case Study — Nicoliv Energy

> **Note:** Nicoliv Energy is a fictional organisation. Its operational profile is modelled on publicly available information from real Crown-owned gas utilities operating in western Canada. No real organisation's confidential systems, vulnerabilities, or security posture is represented here. All specific figures, system names, and vendor relationships are fictionalised.

---

## Organisation Overview

| Attribute | Detail |
|---|---|
| Legal name | Nicoliv Energy Incorporated |
| Type | Crown corporation — wholly owned by the provincial government |
| Founded | 1961 |
| Headquarters | Midford, Saskatchewan |
| Mandate | Safe, reliable, and affordable natural gas delivery to residential, commercial, farm, and industrial customers throughout the province |
| Revenue | ~CAD $490 million (2024-25) |
| Employees | ~1,050 across 48 facilities province-wide |
| Service reliability target | 99.99% — maximum 52 minutes unplanned downtime per year |

---

## Why service reliability is a safety obligation, not just a metric

Saskatchewan winters reach −40°C. Natural gas is the primary heating source for the majority of residential and commercial properties in the province. A distribution outage in winter is not an inconvenience — it is a public safety emergency. Loss of heating in occupied buildings at −30°C becomes dangerous within hours. This operational reality shapes every security decision: system availability is a life-safety obligation, not a business preference.

---

## Operational Scale

### Distribution Network
- **71,000 km** of distribution pipeline — serves 93% of provincial communities
- **400,000+** customers: residential, farm, commercial, industrial
- **Pressure regulation stations:** 340 across the province
- **Metering points:** 412,000 active meters

### Transmission Network (subsidiary: NicoTrans)
- **14,800 km** of high-pressure transmission pipeline
- **12 compressor stations** — maintain pressure across long-distance trunk lines
- **4 underground storage facilities** — seasonal gas storage for demand peaks
- **3 gas processing plants** — receives gas from production fields, conditions for distribution

### Key Industrial Customers
- Potash mining operations (multiple sites, northern region)
- Enhanced oil recovery operations (southwestern region)
- Power generation facilities (contracted supply)
- Agricultural processing (grain drying, food processing)

Industrial customers represent 34% of total throughput volume and 61% of revenue. Loss of industrial supply due to a security incident would have immediate and significant financial consequences — and some industrial processes (potash mining) cannot safely restart quickly after an unplanned shutdown.

---

## IT Environment

### Corporate Network
- Windows Active Directory domain — all corporate workstations and servers
- Microsoft 365 tenancy — email, collaboration, document management
- ERP system — SAP (finance, HR, procurement, asset management)
- Customer information system — billing, service requests, account management
- Geographic information system (GIS) — pipeline mapping, asset registry

### Remote Access
- SSL VPN for corporate remote access (field staff, home workers)
- Privileged access workstations (PAWs) for administrative access
- Vendor remote access portal — separate zone, time-limited sessions

### Cloud Presence
- Azure AD (Entra ID) for identity federation
- Azure-hosted development and test environments
- Hybrid connectivity: on-premise data centre + Azure

---

## OT Environment

### Architecture — IEC 62443 Zone Model

```
┌─────────────────────────────────────────────────────────────┐
│  ENTERPRISE ZONE (Level 4)                                  │
│  Corporate IT — ERP, email, business applications           │
│  Standard IT security controls apply                        │
└────────────────────┬────────────────────────────────────────┘
                     │ Controlled conduit — firewall enforced
┌────────────────────▼────────────────────────────────────────┐
│  INDUSTRIAL DMZ (Level 3.5)                                 │
│  Historian servers — operational data aggregation           │
│  Data diodes — unidirectional OT→IT data flow               │
│  Jump servers — authenticated vendor/admin access           │
│  OT patch management servers                                │
└────────────────────┬────────────────────────────────────────┘
                     │ Strict conduit — application-layer inspection
┌────────────────────▼────────────────────────────────────────┐
│  SUPERVISORY ZONE (Level 3)                                 │
│  SCADA servers — central visibility and control             │
│  HMI workstations — operator interfaces                     │
│  Engineering workstations — configuration and programming   │
│  Process historian — real-time and historical data          │
└────────────────────┬────────────────────────────────────────┘
                     │ Minimal conduit — protocol-specific
┌────────────────────▼────────────────────────────────────────┐
│  CONTROL ZONE (Level 2)                                     │
│  PLCs — compressor station automation                       │
│  RTUs — remote terminal units at field sites                │
│  Gas chromatographs — gas quality monitoring                │
│  Flow computers — custody transfer metering                 │
└────────────────────┬────────────────────────────────────────┘
                     │ Physical and logical separation
┌────────────────────▼────────────────────────────────────────┐
│  SAFETY ZONE (Level 1)                                      │
│  Safety Instrumented Systems (SIS)                          │
│  Emergency shutdown systems (ESD)                           │
│  High-integrity pressure protection (HIPPS)                 │
│  Physically isolated — no remote access permitted           │
└─────────────────────────────────────────────────────────────┘
```

### OT Asset Inventory (summary)

| Asset Type | Count | Criticality |
|---|---|---|
| SCADA servers | 6 | Critical |
| HMI workstations | 34 | High |
| Engineering workstations | 8 | High |
| PLCs (compressor stations) | 96 | Critical |
| RTUs (field sites) | 847 | High |
| Flow computers | 412 | High |
| Gas chromatographs | 28 | Medium |
| Safety Instrumented Systems (SIS) | 12 | Critical |
| Process historians | 3 | High |

### OT Communication Protocols
- Modbus TCP/RTU — legacy field device communication
- DNP3 — remote telemetry (RTUs)
- IEC 60870-5-104 — SCADA-to-field communication
- OPC-UA — historian data aggregation
- ICCP — inter-utility data exchange

Many field devices run protocols that have no authentication mechanism. This is a known architectural constraint of operational gas infrastructure — replacing legacy devices is a multi-decade programme, not a one-year project.

---

## Vendor and Partner Access Model

### Operational Technology Vendors (remote access required)

| Vendor Category | Access Type | Scope | Frequency |
|---|---|---|---|
| SCADA platform vendor | Remote desktop to jump server | SCADA servers, HMI workstations | Monthly maintenance + on-call |
| PLC/compressor vendor | Remote desktop to jump server | Compressor station PLCs | Quarterly + emergency |
| RTU manufacturer | Remote to engineering workstation | RTU configuration | Annually + firmware updates |
| Gas chromatograph vendor | Remote desktop | GC systems only | Quarterly calibration |
| Metering systems vendor | Remote to engineering workstation | Flow computers | Semi-annual + on-call |
| Pipeline integrity services | Site access + remote data | GIS, integrity data systems | Project-based |

### Key Partner Connections
- **Provincial power utility** (NicolivPower) — joint infrastructure sharing, cross-billing data exchange
- **Provincial telecom provider** (NicolivTel) — SCADA communications infrastructure (microwave backbone and fibre)
- **Security monitoring provider** (SecurOps) — 24/7 SOC services, SIEM integration
- **Insurance provider** (Veridian Insurance) — annual cyber risk assessment, incident notification obligations
- **Canada Energy Regulator** — regulatory reporting, compliance audit access

### Vendor Access Risk
Vendor remote access into OT systems is the highest-consequence attack vector in Nicoliv Energy's threat model. The Colonial Pipeline incident (2021) began with a compromised VPN credential. At Nicoliv Energy, a vendor with legitimate SCADA access could, if compromised, view or influence gas pressure and flow across the entire provincial network. This is not a theoretical risk — it is the documented attack pattern of state-sponsored adversaries targeting North American energy infrastructure.

---

## Threat Profile

### Primary Threat Actors

| Actor | Category | Motivation | Capability |
|---|---|---|---|
| Nation-state adversaries (Russia, China, Iran) | APT | Strategic disruption, pre-positioning | High — ICS-aware malware, patient, long-dwell |
| Ransomware syndicates (ALPHV, LockBit variants) | Criminal | Financial extortion | Medium-High — increasingly OT-aware |
| Supply chain attackers | Criminal/State | Lateral access via trusted vendor | High — exploits legitimate access paths |
| Insider threat | Internal | Financial gain, grievance, negligence | Medium — access is already present |
| Hacktivists | Ideological | Disruption, publicity | Low-Medium — opportunistic |

### Realistic Incident Scenarios

**Scenario 1 — Ransomware via IT network lateral movement**
Phishing email compromises a corporate workstation. Attacker moves laterally across the IT network over 3–6 weeks. Reaches the industrial DMZ boundary. Deploys ransomware across IT systems. If segmentation fails, OT systems are affected. Compressor stations lose remote visibility. Manual operation required at 12 sites simultaneously.

*Business impact:* $2–8M recovery cost. Potential service interruption. Regulatory investigation. Reputational damage. Winter scenario: public safety emergency.

**Scenario 2 — Vendor credential compromise**
A SCADA vendor employee's laptop is compromised via a separate phishing incident. The vendor's VPN credential and jump server access are harvested. Attacker uses legitimate access to connect to Nicoliv Energy's SCADA environment during a maintenance window. Makes subtle configuration changes to pressure setpoints.

*Business impact:* Pressure anomalies across western distribution zone. 14,000 customers affected. Pipeline integrity investigation required. NEB notification obligation triggered.

**Scenario 3 — Supply chain attack via OT firmware**
A malicious firmware update is distributed through a PLC vendor's legitimate update channel (similar to SolarWinds pattern). 96 compressor station PLCs receive the update during a scheduled maintenance window. Malicious payload activates on a timed trigger.

*Business impact:* Simultaneous compressor station failures across multiple zones. Province-wide pressure drop. Full operational response. Multi-week recovery. Safety event potential.

---

## Regulatory and Compliance Obligations

| Framework | Applicability | Consequence of non-compliance |
|---|---|---|
| The Nicoliv Energy Act (provincial) | Operating mandate, safety obligations | Loss of operating licence |
| Canada Energy Regulator (CER) | Interprovincial pipeline operations | Fines, operational restrictions |
| Critical Cyber Systems Protection Act (CCSPA) | Designated critical infrastructure operator | Mandatory incident reporting, compliance orders |
| IEC 62443 | OT security architecture standard | Regulatory expectation, insurance requirement |
| NIST CSF | Cybersecurity programme framework | Industry standard, board-level governance |
| Saskatchewan Energy Regulator | Provincial distribution operations | Licence conditions |

### Key Regulatory Requirement: CCSPA (Bill C-26)
Canada's Critical Cyber Systems Protection Act designates operators of critical infrastructure — including natural gas utilities — as subject to mandatory cybersecurity programme requirements and incident reporting obligations. Nicoliv Energy must:
- Maintain a documented cybersecurity programme
- Report significant cyber incidents within 72 hours
- Implement supply chain security requirements
- Conduct regular security assessments

---

## Security Objectives

Derived from the threat profile, regulatory obligations, and operational constraints:

| Objective | Priority | Driver |
|---|---|---|
| Maintain IT/OT zone separation | Critical | Prevent ransomware lateral movement to OT |
| Control and audit all vendor remote access | Critical | Vendor compromise is highest-consequence attack vector |
| Maintain change traceability for all OT configurations | Critical | Regulatory obligation + incident investigation capability |
| Detect anomalous behaviour in OT networks | High | Early warning before impact |
| Protect corporate credentials | High | Initial access prevention |
| Maintain operational capability during cyber incident | High | Safety and service continuity |
| Communicate risk in executive-consumable format | Medium | Board-level governance obligation |
| Align security programme to IEC 62443 and NIST CSF | Medium | Regulatory expectation + insurance |

---

## How Nicoliv Energy Is Used in This Repository

Every control documented in this repository is evaluated against Nicoliv Energy's threat context. The standard question in each section:

> *"What does this control protect at Nicoliv Energy, what is the business consequence if it fails, and what regulatory obligation does it satisfy?"*

This creates coherent, continuous documentation rather than isolated technology chapters. The reader is not learning tools — they are solving problems inside a world they understand.

**The thread across all phases:**

| Phase | Technology | Problem at Nicoliv Energy |
|---|---|---|
| 1 | Git | Configuration changes with no attribution or history |
| 1 | SSH | Weak authentication for engineer and vendor access |
| 2 | Terraform | Manual infrastructure deployment creating configuration drift |
| 3 | AWS | Inconsistent cloud security posture across hybrid environment |
| 4 | CI/CD | Security scanning absent from deployment pipeline |
| 5 | Containers | Insecure workload deployment in cloud environment |
| 6 | Detection Engineering | Insufficient visibility into OT-adjacent threat activity |
| 7 | AI Security Operations | Alert volume exceeds analyst capacity — triage is manual |
| 8 | Cyber Resilience & Governance | Technical controls not communicated to board in risk terms |
