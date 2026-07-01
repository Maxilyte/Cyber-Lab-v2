# routing.tf
# Internet Gateway and route tables for Cyber-Lab-v2
#
# Public route table: routes 0.0.0.0/0 to the IGW, associated with both
# public subnets. This is what actually makes public_a/public_b reachable
# from the internet.
#
# Private route table: no default route yet. Associated with all four
# private subnets. A NAT Gateway route will be added here later when
# outbound internet access for the private tier is needed — not required
# for the lab at this stage.

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "cyber-lab-v2-igw"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# ---------------------------------------------------------------------------
# Public route table
# ---------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "cyber-lab-v2-public-rt"
    Tier        = "public"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Private route table
# No default route yet — private tier has no outbound internet path until
# a NAT Gateway is added. Both private-app and private-data associate to
# this single table for now; split later if app and data need different
# routing policies.
# ---------------------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "cyber-lab-v2-private-rt"
    Tier        = "private"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data_a" {
  subnet_id      = aws_subnet.private_data_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data_b" {
  subnet_id      = aws_subnet.private_data_b.id
  route_table_id = aws_route_table.private.id
}
