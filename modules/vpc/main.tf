# Fetch availability zones for the current region

data "aws_availability_zones" "available" {}

locals {
  azs                = var.graphdb_node_count == 1 ? slice(data.aws_availability_zones.available.names, 0, 1) : slice(data.aws_availability_zones.available.names, 0, 3)
  len_public_subnets = max(length(var.vpc_private_subnet_cidrs))
  max_subnet_length  = max(local.len_public_subnets)
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

  tags = {
    Name = "${var.resource_name_prefix}-public-subnet-${count.index}"
  }
}

# GraphDB Private Subnet

resource "aws_subnet" "graphdb_private_subnet" {
  count = length(local.azs)

  vpc_id            = aws_vpc.graphdb_vpc.id
  cidr_block        = var.vpc_private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.resource_name_prefix}-private-subnet-${count.index}"
  }
}

# Optional TGW Subnets

resource "aws_subnet" "graphdb_tgw_subnet" {
  count             = length(var.tgw_subnet_cidrs)
  vpc_id            = aws_vpc.graphdb_vpc.id
  cidr_block        = var.tgw_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = {
    Name = "${var.resource_name_prefix}-tgw-subnet-${count.index}"
  }
}

# NAT Gateway

locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.max_subnet_length) : 0
}

resource "aws_eip" "graphdb_eip" {
  count = local.nat_gateway_count
}

resource "aws_nat_gateway" "graphdb_nat_gateway" {
  count         = local.nat_gateway_count
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
    Name = "${var.resource_name_prefix}-public-rt-${count.index}"
  }
}

resource "aws_route_table_association" "graphdb_public_association" {
  count = length(local.azs)

  route_table_id = aws_route_table.graphdb_public_route_table[count.index].id
  subnet_id      = aws_subnet.graphdb_public_subnet[count.index].id
}

# GraphDB Private Route Table

resource "aws_route_table" "graphdb_private_route_table" {
  count = length(local.azs)

  vpc_id = aws_vpc.graphdb_vpc.id

  tags = {
    Name = "${var.resource_name_prefix}-private-rt-${count.index}"
  }

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.enable_nat_gateway ? var.single_nat_gateway ? aws_nat_gateway.graphdb_nat_gateway[0].id : aws_nat_gateway.graphdb_nat_gateway[count.index].id : null
    }
  }
}

resource "aws_route_table_association" "graphdb_private_association" {
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

# Private Link Service

resource "aws_vpc_endpoint_service" "graphdb_vpc_endpoint_service" {
  count = var.lb_enable_private_access ? 1 : 0

  network_load_balancer_arns = var.network_load_balancer_arns
  acceptance_required        = var.vpc_endpoint_service_accept_connection_requests
  allowed_principals         = var.vpc_endpoint_service_allowed_principals
}

# Transit Gateway

locals {
  effective_tgw_subnet_ids = length(var.tgw_subnet_ids) > 0 ? var.tgw_subnet_ids : aws_subnet.graphdb_tgw_subnet[*].id
  _private_rt_ids          = aws_route_table.graphdb_private_route_table[*].id

  tgw_route_pairs = (
    var.tgw_id != null && length(var.tgw_client_cidrs) > 0
    ) ? flatten([
      for rt_index, rt_id in local._private_rt_ids : [
        for cidr in var.tgw_client_cidrs : {
          key   = "${rt_index}-${cidr}"
          rt_id = rt_id
          cidr  = cidr
        }
      ]
  ]) : []
}

resource "aws_ec2_transit_gateway_vpc_attachment" "graphdb_tgw_attachment" {
  count              = var.tgw_id != null && length(local.effective_tgw_subnet_ids) > 0 ? 1 : 0
  vpc_id             = aws_vpc.graphdb_vpc.id
  subnet_ids         = local.effective_tgw_subnet_ids
  transit_gateway_id = var.tgw_id

  dns_support            = var.tgw_dns_support
  ipv6_support           = var.tgw_ipv6_support
  appliance_mode_support = var.tgw_appliance_mode_support

  tags = {
    Name = "${var.resource_name_prefix}-tgw-attachment"
  }
}

# Associate the VPC attachment with the specified TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "graphdb_tgw_association" {
  count = var.tgw_id != null && var.tgw_route_table_id != null && coalesce(var.tgw_associate_to_route_table, true) ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.graphdb_tgw_attachment[0].id
  transit_gateway_route_table_id = var.tgw_route_table_id
}

# Enable route propagation from this attachment into that TGW route table
resource "aws_ec2_transit_gateway_route_table_propagation" "graphdb_tgw_propagation" {
  count = var.tgw_id != null && var.tgw_route_table_id != null && coalesce(var.tgw_enable_propagation, true) ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.graphdb_tgw_attachment[0].id
  transit_gateway_route_table_id = var.tgw_route_table_id

  depends_on = [aws_ec2_transit_gateway_route_table_association.graphdb_tgw_association]
}

resource "aws_route" "graphdb_private_tgw_routes" {
  for_each = { for p in local.tgw_route_pairs : p.key => p }

  route_table_id         = each.value.rt_id
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.tgw_id
}
