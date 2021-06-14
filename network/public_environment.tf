resource "aws_subnet" "public" {
    count                           = length(var.public_subnets)
    vpc_id                          = aws_vpc.this.id
    cidr_block                      = element(var.public_subnets, count.index)
    availability_zone               = element(var.azs, count.index)
    map_public_ip_on_launch         = true

    tags                            = { "Name" = format( "%s-%s", "public", element(var.azs, count.index) ) }
}
resource "aws_internet_gateway" "this" {
    vpc_id                          = aws_vpc.this.id
    tags                            = { "Name" = "default_igw" }
}
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id
    tags = { "Name" = "public-rt" }
}
resource "aws_route_table_association" "public" {
    count = length(var.public_subnets)

    subnet_id      = element(aws_subnet.public.*.id, count.index)
    route_table_id = aws_route_table.public.id
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}