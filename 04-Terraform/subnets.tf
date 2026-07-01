# subnets.tf
# Subnets for Cyber-Lab-v2
# 3-tier design across 2 Availability Zones: public, private-app, private-data
#
# Layout:
#   Public        10.0.1.0/24  (ca-central-1a)   10.0.2.0/24  (ca-central-1b)
#   Private-app   10.0.10.0/24 (ca-central-1a)   10.0.11.0/24 (ca-central-1b)
#   Private-data  10.0.20.0/24 (ca-central-1a)   10.0.21.0/24 (ca-central-1b)
#
# Route tables, IGW, and NAT are handled separately — this file only
# establishes the subnets themselves within aws_vpc.main.

# ---------------------------------------------------------------------------
# Public subnets
# ---------------------------------------------------------------------------

# Public subnets assign public IPs on launch by design — this tier is meant
# to host internet-facing resources (bastion, NAT gateway). Flagged by
# Checkov as a general best-practice check but intentional here.
#checkov:skip=CKV_AWS_130:Public tier intentionally assigns public IPs for bastion/NAT placement.
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "cyber-lab-v2-public-a"
    Tier        = "public"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

#checkov:skip=CKV_AWS_130:Public tier intentionally assigns public IPs for bastion/NAT placement.
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ca-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "cyber-lab-v2-public-b"
    Tier        = "public"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# Private-app subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ca-central-1a"

  tags = {
    Name        = "cyber-lab-v2-private-app-a"
    Tier        = "private-app"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ca-central-1b"

  tags = {
    Name        = "cyber-lab-v2-private-app-b"
    Tier        = "private-app"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# Private-data subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "private_data_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ca-central-1a"

  tags = {
    Name        = "cyber-lab-v2-private-data-a"
    Tier        = "private-data"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_subnet" "private_data_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ca-central-1b"

  tags = {
    Name        = "cyber-lab-v2-private-data-b"
    Tier        = "private-data"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}
