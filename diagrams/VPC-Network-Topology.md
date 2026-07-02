# Diagram — VPC Network Topology

**Purpose:** Shows the VPC subnet layout across two Availability Zones and how each tier's route table connects (or doesn't connect) to the internet. **Phase:** 2 — AWS Network & Compute **Related:** [04-Terraform/subnets.tf](../04-Terraform/subnets.tf), [04-Terraform/routing.tf](../04-Terraform/routing.tf)

---

## VPC 10.0.0.0/16 — vpc-0611b97607b5fb7ca

```
                    INTERNET GATEWAY
                    igw-0607d70757da68d3f
                            |
                            v
              +-----------------------------+
              |  PUBLIC ROUTE TABLE          |
              |  rtb-05642feaacc6da2d4       |
              |  0.0.0.0/0 -> IGW             |
              +-----------------------------+
                    |                 |
                    v                 v
        +-------------------+ +-------------------+
        |  public_a         | |  public_b         |
        |  10.0.1.0/24      | |  10.0.2.0/24      |
        |  ca-central-1a    | |  ca-central-1b    |
        |  subnet-06756ffd..| |  subnet-0b3713e2..|
        +-------------------+ +-------------------+


              +-----------------------------+
              |  PRIVATE ROUTE TABLE         |
              |  rtb-0f8122f55c881f1a7       |
              |  no default route            |
              +-----------------------------+
              |        |        |        |
              v        v        v        v
      +-------------+ +-------------+ +-------------+ +-------------+
      | private_app_a| | private_app_b| |private_data_a| |private_data_b|
      | 10.0.10.0/24 | | 10.0.11.0/24 | | 10.0.20.0/24 | | 10.0.21.0/24 |
      | ca-central-1a| | ca-central-1b| | ca-central-1a| | ca-central-1b|
      | subnet-0bd3f2| | subnet-059428| | subnet-0af514| | subnet-0d5598|
      +-------------+ +-------------+ +-------------+ +-------------+
```

## Design Notes

- **2 Availability Zones** for redundancy, even though current EC2 instances only occupy the `-a` side — the `-b` subnets exist for future HA expansion without re-architecting.
- **3-tier CIDR split**, each tier's `.a`/`.b` pair only one octet apart (`10.0.1.0/24` / `10.0.2.0/24`, etc.) for readability, with room in `10.0.0.0/16` for many more tiers or AZs later.
- **Private route table has no default route.** This is intentional, not incomplete — private-app and private-data subnets currently have zero outbound internet path. A NAT Gateway would be required to give private-app egress; private-data (OT zone) is designed to stay fully isolated even after that, matching the zero-egress security group posture (see `IT-OT-Segmentation-Architecture.md`).
- **Public subnets** (`map_public_ip_on_launch = true`) route `0.0.0.0/0` through the Internet Gateway — this is what makes the bastion reachable.

## Build Order

1. `subnets.tf` — 6 subnets, committed `53ffa9a`
2. `routing.tf` — IGW + 2 route tables + 6 associations, committed `e125b83`
3. `security-groups.tf` — segmentation enforcement layer (see `IT-OT-Segmentation-Architecture.md`)
4. `ec2.tf` — compute placed into this topology

## Related

- `subnets.tf`, `routing.tf`
- `IT-OT-Segmentation-Architecture.md` — security group enforcement on top of this topology
- ADR-004 (Terraform), ADR-005 (Remote state)
