data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Pick two AZs for ALB and RDS multi-AZ coverage
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )

  # Build maps pairing each CIDR with an AZ
  public_subnets_map = {
    for idx, cidr in var.public_subnets :
    idx => {
      cidr = cidr
      az   = local.azs[idx % length(local.azs)]
    }
  }

  private_subnets_map = {
    for idx, cidr in var.private_subnets :
    idx => {
      cidr = cidr
      az   = local.azs[idx % length(local.azs)]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-vpc"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-public-${replace(each.value.cidr, ".", "-")}"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-private-${replace(each.value.cidr, ".", "-")}"
      Tier = "private"
    }
  )
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-nat"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-rtb-public"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-rtb-private"
    }
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}
