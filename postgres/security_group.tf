resource "aws_security_group" "this" {
  name                                = format("postgresql-%s-sg", var.name) 
  vpc_id                              = var.vpc_id
}

resource "aws_security_group_rule" "egress" {
  security_group_id     = aws_security_group.this.id
  type                  = "egress"
  cidr_blocks           = ["0.0.0.0/0"] //TODO - Remove this rule and point to NAT Gateway
  from_port             = 0
  to_port               = 65535
  protocol              = "all" 
}

resource "aws_security_group_rule" "ingress" {
    count                           = length(var.source_security_groups)
    security_group_id               = aws_security_group.this.id
    type                            = "ingress"
    source_security_group_id        = element(var.source_security_groups, count.index)
    from_port                       = 5432
    to_port                         = 5432
    protocol                        = "tcp"
}
