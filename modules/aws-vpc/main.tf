# Fetch availability zones for the current region
data "aws_availability_zones" "available" {}

locals {
  tags = {
    Name = "${var.resource_name_prefix}-graphdb"
  }

  azs                = slice(data.aws_availability_zones.available.names, 0, 3)
  len_public_subnets = max(length(var.vpc_private_subnet_cidrs))

  max_subnet_length = max(
    local.len_public_subnets
  )
}

# GraphDB VPC

resource "aws_vpc" "graphdb_vpc" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.vpc_dns_hostnames
  enable_dns_support   = var.vpc_dns_support
}

# GraphDB Internet Gateway

resource "aws_internet_gateway" "graphdb_internet_gateway" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.graphdb_vpc[0].id
}

# GraphDB Subnets

# GraphDB Public Subnet

resource "aws_subnet" "graphdb_public_subnet" {
  count = var.create_vpc ? length(local.azs) : 0

  vpc_id            = aws_vpc.graphdb_vpc[0].id
  cidr_block        = var.vpc_public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = { "Name" = "${local.tags.Name}-public-subnet-${count.index}" }
}

# GraphDB Private Subnet

resource "aws_subnet" "graphdb_private_subnet" {
  count = var.create_vpc ? length(local.azs) : 0

  vpc_id            = aws_vpc.graphdb_vpc[0].id
  cidr_block        = var.vpc_private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    "Name" = "${local.tags.Name}-private-subnet-${count.index}"
  }
}

# GraphDB NАТ Gateway

locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.max_subnet_length) : 0
}

resource "aws_eip" "graphdb_eip" {
  count = var.enable_nat_gateway && (var.single_nat_gateway || length(local.azs) > 0) ? local.nat_gateway_count : 0
}

resource "aws_nat_gateway" "graphdb_nat_gateway" {
  count = var.enable_nat_gateway && (var.single_nat_gateway || length(local.azs) > 0) ? local.nat_gateway_count : 0

  subnet_id     = var.single_nat_gateway ? aws_subnet.graphdb_public_subnet[0].id : aws_subnet.graphdb_public_subnet[count.index].id
  allocation_id = aws_eip.graphdb_eip[var.single_nat_gateway ? 0 : count.index].id
}

# GraphDB Route Tables

# GraphDB Public Route Table

resource "aws_route_table" "graphdb_public_route_table" {
  count = var.create_vpc ? length(local.azs) : 0

  vpc_id = aws_vpc.graphdb_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.graphdb_internet_gateway[0].id
  }

  tags = {
    Name = "${local.tags.Name}-public-route-table-${count.index}"
  }
}

resource "aws_route_table_association" "graphdb_public_route_table_association" {
  count = var.create_vpc ? length(local.azs) : 0

  route_table_id = aws_route_table.graphdb_public_route_table[count.index].id
  subnet_id      = aws_subnet.graphdb_public_subnet[count.index].id
}

# GraphDB Private Route Table

resource "aws_route_table" "graphdb_private_route_table" {
  count = var.create_vpc ? length(local.azs) : 0

  vpc_id = aws_vpc.graphdb_vpc[0].id

  tags = {
    Name = "${local.tags.Name}-private-route-table-${count.index}"
  }

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.enable_nat_gateway ? var.single_nat_gateway ? aws_nat_gateway.graphdb_nat_gateway[0].id : aws_nat_gateway.graphdb_nat_gateway[count.index].id : null
    }
  }
}

resource "aws_route_table_association" "graphdb_private_route_table_association" {
  count = var.create_vpc ? length(local.azs) : 0

  route_table_id = aws_route_table.graphdb_private_route_table[count.index].id
  subnet_id      = aws_subnet.graphdb_private_subnet[count.index].id
}

