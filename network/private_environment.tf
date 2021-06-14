resource "aws_subnet" "private" {
    count                           = length(var.private_subnets)
    vpc_id                          = aws_vpc.this.id
    cidr_block                      = element(var.private_subnets, count.index)
    availability_zone               = element(var.azs, count.index)

    tags                            = { "Name" = format( "%s-%s", "private", element(var.azs, count.index) ) }
}

resource "aws_eip" "nat" {
    vpc      = true
}

resource "aws_nat_gateway" "default_nat_gw" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public[0].id
}

resource "aws_route_table" "private" {
    count = length(var.private_subnets)
    vpc_id = aws_vpc.this.id
    tags = { "Name" = "private-rt" }
}

resource "aws_route_table_association" "private" {
    count = length(var.private_subnets)

    subnet_id = element(aws_subnet.private.*.id, count.index)
    route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(var.private_subnets)##
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default_nat_gw.id
  timeouts {
    create = "5m"
  }
}