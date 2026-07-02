# ec2.tf
# EC2 instances for the IT/OT segmentation chain: bastion (public),
# idmz broker (private-app), ot-zone (private-data).
#
# Each instance sits in its matching subnet/tier and attaches only its
# corresponding security group from security-groups.tf — no instance
# has more network access than its zone allows.

# ---------------------------------------------------------------------------
# Key pair
# Public key only — generated locally via `ssh-keygen -t ed25519`,
# matching the Ed25519 convention from ADR-002. Private key never
# touches Terraform or this repo.
# ---------------------------------------------------------------------------

resource "aws_key_pair" "cyber_lab_v2" {
  key_name   = "cyber-lab-v2-ec2"
  public_key = file("${path.module}/cyber-lab-v2-ec2.pub")

  tags = {
    Name        = "cyber-lab-v2-ec2-key"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# AMI lookup — always resolves to the latest Amazon Linux 2023 image at
# plan time rather than pinning a specific (and eventually stale) AMI ID.
# ---------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Bastion instance — public subnet, bastion_sg
# ---------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.cyber_lab_v2.key_name

  tags = {
    Name        = "cyber-lab-v2-bastion"
    Zone        = "it-enterprise"
    PurdueLevel = "4-5"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# IDMZ broker instance — private-app subnet, idmz_sg
# No public IP; reachable only through the bastion.
# ---------------------------------------------------------------------------

resource "aws_instance" "idmz" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_app_a.id
  vpc_security_group_ids = [aws_security_group.idmz.id]
  key_name               = aws_key_pair.cyber_lab_v2.key_name

  tags = {
    Name        = "cyber-lab-v2-idmz"
    Zone        = "idmz-broker"
    PurdueLevel = "3.5"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# OT-zone instance — private-data subnet, ot_zone_sg
# No public IP, no egress at the security group level. Reachable only
# through the idmz broker. This is where Modbus/OPC UA simulation
# would eventually run.
# ---------------------------------------------------------------------------

resource "aws_instance" "ot_zone" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_data_a.id
  vpc_security_group_ids = [aws_security_group.ot_zone.id]
  key_name               = aws_key_pair.cyber_lab_v2.key_name

  tags = {
    Name        = "cyber-lab-v2-ot-zone"
    Zone        = "ot-control"
    PurdueLevel = "1-3"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}
