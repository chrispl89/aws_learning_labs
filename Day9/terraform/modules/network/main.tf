resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-subnet-public-a" })
}

resource "aws_subnet" "b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr_b
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "${var.name_prefix}-subnet-public-b" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.name_prefix}-rt-public" })
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.b.id
  route_table_id = aws_route_table.public.id
}
