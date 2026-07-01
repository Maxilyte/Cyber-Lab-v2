# security-groups.tf
# IT/OT segmentation chain for Cyber-Lab-v2, modeled on the Purdue Model /
# IEC 62443 zone architecture used in the CYBA-IT lab (FortiGate NGFW +
# IDMZ pattern), reimplemented here as AWS security groups.
#
# Chain: admin workstation -> bastion (public) -> idmz (private-app,
# the IT/OT broker) -> ot-zone (private-data, no direct route from
# public or IT, ever).
#
# DEPENDENCY NOTE:
# bastion, idmz, and ot_zone reference each other's security group IDs
# (bastion's egress needs idmz's ID, idmz's ingress needs bastion's ID,
# and the same pattern repeats between idmz and ot_zone). Declaring all
# of this with Terraform's inline ingress/egress blocks creates a real
# dependency cycle — each group would need the other to exist first.
#
# Fix: the "upstream-facing" ingress rule on idmz and ot_zone (the rule
# that lets a lower-trust zone accept traffic from a higher one) is
# split into a standalone aws_vpc_security_group_ingress_rule resource.
# Standalone rule resources are their own objects in the dependency
# graph — they can be created after both security groups already exist,
# which breaks the cycle. Egress rules stay inline since they only
# create a one-directional dependency (bastion -> idmz -> ot_zone),
# which is fine.

# ---------------------------------------------------------------------------
# Bastion SG — Enterprise/IT zone entry point (Purdue Level 4-5)
# Fully inline: its ingress rule is a plain CIDR (no SG reference), and
# its egress only points forward to idmz, so no cycle risk here.
# ---------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  name        = "cyber-lab-v2-bastion-sg"
  description = "Bastion host - SSH entry point from admin workstation only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from admin workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.225.90.176/32"]
  }

  egress {
    description = "HTTPS for OS package updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "SSH forward into IDMZ"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.idmz.id]
  }

  tags = {
    Name        = "cyber-lab-v2-bastion-sg"
    Zone        = "it-enterprise"
    PurdueLevel = "4-5"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# IDMZ SG — IT/OT broker zone (Purdue Level 3.5)
# Egress stays inline (only depends forward on ot_zone). Ingress (from
# bastion) is standalone to avoid the reverse edge back to bastion.
# ---------------------------------------------------------------------------

resource "aws_security_group" "idmz" {
  name        = "cyber-lab-v2-idmz-sg"
  description = "IDMZ broker zone - only path permitted between IT and OT"
  vpc_id      = aws_vpc.main.id

  egress {
    description     = "SSH into OT zone for lab administration"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ot_zone.id]
  }

  egress {
    description     = "Modbus TCP into OT zone"
    from_port       = 502
    to_port         = 502
    protocol        = "tcp"
    security_groups = [aws_security_group.ot_zone.id]
  }

  egress {
    description     = "OPC UA into OT zone"
    from_port       = 4840
    to_port         = 4840
    protocol        = "tcp"
    security_groups = [aws_security_group.ot_zone.id]
  }

  tags = {
    Name        = "cyber-lab-v2-idmz-sg"
    Zone        = "idmz-broker"
    PurdueLevel = "3.5"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# Standalone: idmz accepts SSH from bastion. Split out to break the
# bastion <-> idmz cycle described above.
resource "aws_vpc_security_group_ingress_rule" "idmz_ssh_from_bastion" {
  security_group_id            = aws_security_group.idmz.id
  referenced_security_group_id = aws_security_group.bastion.id
  description                  = "SSH from bastion only"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22

  tags = {
    Name        = "idmz-ssh-from-bastion"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# OT-zone SG — Control zone (Purdue Level 1-3)
# Modbus TCP (legacy, unauthenticated, widest install base) and OPC UA
# (modern, authenticated, IEC 62541) both represented, since real
# brownfield/greenfield transitional environments run both concurrently.
#
# egress = [] is set explicitly (not omitted) so Terraform actively
# manages this attribute and removes AWS's automatic default
# allow-all-outbound rule, which every newly created security group
# receives unless something explicitly clears it. Omitting the egress
# argument entirely would leave that default rule untouched and this
# group would silently allow all outbound traffic despite the intent
# below — the explicit empty list is what actually enforces deny-all.
#
# Ingress is standalone to break the idmz <-> ot_zone cycle.
# ---------------------------------------------------------------------------

resource "aws_security_group" "ot_zone" {
  name        = "cyber-lab-v2-ot-zone-sg"
  description = "OT/control zone - Modbus and OPC UA from IDMZ only, no egress"
  vpc_id      = aws_vpc.main.id

  egress = []

  tags = {
    Name        = "cyber-lab-v2-ot-zone-sg"
    Zone        = "ot-control"
    PurdueLevel = "1-3"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ot_zone_ssh_from_idmz" {
  security_group_id            = aws_security_group.ot_zone.id
  referenced_security_group_id = aws_security_group.idmz.id
  description                  = "SSH from IDMZ for lab administration only"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22

  tags = {
    Name        = "ot-zone-ssh-from-idmz"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ot_zone_modbus_from_idmz" {
  security_group_id            = aws_security_group.ot_zone.id
  referenced_security_group_id = aws_security_group.idmz.id
  description                  = "Modbus TCP from IDMZ"
  ip_protocol                  = "tcp"
  from_port                    = 502
  to_port                      = 502

  tags = {
    Name        = "ot-zone-modbus-from-idmz"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ot_zone_opcua_from_idmz" {
  security_group_id            = aws_security_group.ot_zone.id
  referenced_security_group_id = aws_security_group.idmz.id
  description                  = "OPC UA from IDMZ"
  ip_protocol                  = "tcp"
  from_port                    = 4840
  to_port                      = 4840

  tags = {
    Name        = "ot-zone-opcua-from-idmz"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}
