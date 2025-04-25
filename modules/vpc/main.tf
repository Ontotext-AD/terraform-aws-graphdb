# Fetch availability zones for the current region
data "aws_availability_zones" "available" {}

locals {
  azs                = var.graphdb_node_count == 1 ? slice(data.aws_availability_zones.available.names, 0, 1) : slice(data.aws_availability_zones.available.names, 0, 3)
  len_public_subnets = max(length(var.vpc_private_subnet_cidrs))

  max_subnet_length = max(
    local.len_public_subnets
  )
}

# GraphDB VPC

resource "aws_vpc" "graphdb_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.vpc_dns_hostnames
  enable_dns_support   = var.vpc_dns_support
}

# GraphDB Internet Gateway

resource "aws_internet_gateway" "graphdb_internet_gateway" {
  vpc_id = aws_vpc.graphdb_vpc.id
}

# GraphDB Subnets

# GraphDB Public Subnet

resource "aws_subnet" "graphdb_public_subnet" {
  count = length(local.azs)

  vpc_id            = aws_vpc.graphdb_vpc.id
  cidr_block        = var.vpc_public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = { "Name" = "${var.resource_name_prefix}-public-subnet-${count.index}" }
}

# GraphDB Private Subnet

resource "aws_subnet" "graphdb_private_subnet" {
  count = length(local.azs)

  vpc_id            = aws_vpc.graphdb_vpc.id
  cidr_block        = var.vpc_private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    "Name" = "${var.resource_name_prefix}-private-subnet-${count.index}"
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
  count = length(local.azs)

  vpc_id = aws_vpc.graphdb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.graphdb_internet_gateway.id
  }

  tags = {
    Name = "${var.resource_name_prefix}-public-route-table-${count.index}"
  }
}

resource "aws_route_table_association" "graphdb_public_route_table_association" {
  count = length(local.azs)

  route_table_id = aws_route_table.graphdb_public_route_table[count.index].id
  subnet_id      = aws_subnet.graphdb_public_subnet[count.index].id
}

# GraphDB Private Route Table

resource "aws_route_table" "graphdb_private_route_table" {
  count = length(local.azs)

  vpc_id = aws_vpc.graphdb_vpc.id

  tags = {
    Name = "${var.resource_name_prefix}-private-route-table-${count.index}"
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
  count = length(local.azs)

  route_table_id = aws_route_table.graphdb_private_route_table[count.index].id
  subnet_id      = aws_subnet.graphdb_private_subnet[count.index].id
}

# GraphDB VPC Flow Logs

resource "aws_flow_log" "graphdb_vpc_flow_log" {
  count = var.vpc_enable_flow_logs ? 1 : 0

  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = var.vpc_flow_log_bucket_arn
  vpc_id               = aws_vpc.graphdb_vpc.id
}

# GraphDB Private Link Service

resource "aws_vpc_endpoint_service" "graphdb_vpc_endpoint_service" {
  count = var.lb_enable_private_access && length(var.network_load_balancer_arns) > 0 ? 1 : 0

  network_load_balancer_arns = var.network_load_balancer_arns
  acceptance_required        = var.vpc_endpoint_service_accept_connection_requests
  allowed_principals         = var.vpc_endpoint_service_allowed_principals
}
