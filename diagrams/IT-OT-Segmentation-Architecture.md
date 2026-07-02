# Diagram — IT/OT Segmentation Architecture

**Purpose:** Shows the Purdue Model / IEC 62443 segmentation chain from admin workstation through to the isolated OT/control zone, and the security group rule that permits each hop. **Phase:** 2 — AWS Network & Compute **Related:** [04-Terraform/security-groups.tf](../04-Terraform/security-groups.tf)

---

## Segmentation Chain — Four Zones

```
ADMIN WORKSTATION (Internet)
  |  X.X.X.X/32 (admin IP, restricted)
  |  SSH 22
  v
+------------------------------------------------------------+
|  PUBLIC SUBNET -- Purdue Level 4-5 (IT / Enterprise)        |
|  +--------------------------------------------------------+ |
|  |  BASTION EC2                                            | |
|  |  10.0.1.X  (public_a)                                   | |
|  |  sg-0f2cebcd0fb3d31fb                                   | |
|  |                                                          | |
|  |  Ingress: SSH 22 from admin IP only                     | |
|  |  Egress:  HTTPS 443 (patching) + SSH 22 to IDMZ only     | |
|  +--------------------------------------------------------+ |
+------------------------------------------------------------+
  |  SSH 22 -- bastion SG only
  v
+------------------------------------------------------------+
|  PRIVATE-APP SUBNET -- Purdue Level 3.5 (IDMZ Broker)        |
|  +--------------------------------------------------------+ |
|  |  IDMZ EC2                                                | |
|  |  10.0.10.X  (private_app_a)                              | |
|  |  sg-0adbb71908083cc85                                    | |
|  |                                                          | |
|  |  Ingress: SSH 22 from bastion SG only                    | |
|  |  Egress:  SSH 22, Modbus 502, OPC UA 4840 to OT zone only| |
|  +--------------------------------------------------------+ |
+------------------------------------------------------------+
  |  SSH 22, Modbus 502, OPC UA 4840 -- idmz SG only
  v
+------------------------------------------------------------+
|  PRIVATE-DATA SUBNET -- Purdue Level 1-3 (OT / Control)      |
|  +--------------------------------------------------------+ |
|  |  OT_ZONE EC2                                             | |
|  |  10.0.20.X  (private_data_a)                             | |
|  |  sg-0d4c61ba9fe75c593                                    | |
|  |                                                          | |
|  |  Ingress: SSH 22, Modbus 502, OPC UA 4840 (idmz SG only) | |
|  |  Egress:  NONE -- egress = [] explicit, true zero-egress | |
|  +--------------------------------------------------------+ |
+------------------------------------------------------------+
```

No direct path exists from the public internet, or from the bastion, straight to `ot_zone`. The IDMZ tier is a mandatory broker — matching the IDMZ pattern from the CYBA-IT lab's FortiGate build.

## Rule Summary

| Hop | Direction | Protocol / Port | Source restriction |
|---|---|---|---|
| Internet -> bastion | ingress | SSH 22 | `X.X.X.X/32` (admin IP only) |
| bastion -> idmz | egress/ingress | SSH 22 | bastion SG only |
| bastion -> internet | egress | HTTPS 443 | `0.0.0.0/0` (OS patching only) |
| idmz -> ot_zone | egress/ingress | SSH 22 | idmz SG only |
| idmz -> ot_zone | egress/ingress | Modbus TCP 502 | idmz SG only |
| idmz -> ot_zone | egress/ingress | OPC UA 4840 | idmz SG only |
| ot_zone -> anywhere | egress | none | explicit `egress = []`, true zero-egress |

## Why Two ICS Protocols

Modbus TCP (legacy, unauthenticated, widest brownfield install base) and OPC UA (modern, IEC 62541, certificate-based auth) are both represented because real industrial environments rarely run one cleanly — brownfield Modbus devices and greenfield OPC UA modernization typically coexist during a transition period. Designing for both, with different trust postures per protocol, reflects the actual field reality rather than a textbook-clean single-protocol lab.

## Verification

Live-tested July 1, 2026 via SSH agent forwarding: local machine -> bastion (`-A`) -> idmz (`-A`) -> ot_zone, three-hop chain, each hop only possible through its specific security group rule.

## Related

- `security-groups.tf`
- ADR-004 (Terraform), ADR-005 (Remote state)
- `IAM-Debugging-and-SG-Patterns-Field-Guide.md` — documents the Terraform dependency cycle encountered building this chain and the `egress = []` zero-egress technique
