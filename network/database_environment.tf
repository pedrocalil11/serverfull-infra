#Setup Database Environment
resource "aws_subnet" "database" {
    count                           = length(var.database_subnets)
    vpc_id                          = aws_vpc.this.id
    cidr_block                      = element(var.database_subnets, count.index)
    availability_zone               = element(var.azs, count.index)

    tags                            = { "Name" = format( "%s-%s", "database", element(var.azs, count.index) ) }
}
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.this.id
    tags = { "Name" = "database-rt" }
}
resource "aws_route_table_association" "database" {
    count = length(var.database_subnets)

    subnet_id = element(aws_subnet.database.*.id, count.index)
    route_table_id = aws_route_table.database.id
}

resource "aws_route" "database_nat_gateway" {
  route_table_id         = aws_route_table.database.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default_nat_gw.id
  
  timeouts {
    create = "5m"
  }
}