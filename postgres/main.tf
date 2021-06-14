resource "aws_db_subnet_group" "this" {
    name                            = format("%s-subnet-group", var.name)
    description                     = format("Database subnet group for %s", var.name)
    subnet_ids                      = var.database_subnets
}

resource "aws_db_parameter_group" "this" {
    name                            = format("%s-parameter-group", var.name)
    description                     = format("Database parameter group for %s", var.name)
    family                          = "postgres11"
  lifecycle { create_before_destroy = true }
}

resource "aws_db_instance" "this" {
  name                                = format("%smaster", var.name)
  identifier                          = format("%s-master", var.name)

  engine                              = "postgres"
  engine_version                      = "11.10"
  instance_class                      = "db.t2.micro"
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_type                        = "gp2"
  storage_encrypted                   = false
  
  username                            = var.username
  password                            = var.password
  port                                = 5432

  vpc_security_group_ids              = [ aws_security_group.this.id ]
  db_subnet_group_name                = aws_db_subnet_group.this.name
  parameter_group_name                = aws_db_parameter_group.this.name

  multi_az                            = false
  publicly_accessible                 = false

  allow_major_version_upgrade         = true
  auto_minor_version_upgrade          = true
  apply_immediately                   = true
  maintenance_window                  = var.maintenance_window
  skip_final_snapshot                 = false
  copy_tags_to_snapshot               = false
  final_snapshot_identifier           = format("%s-final-snapshot", var.name)

  backup_retention_period             = 7
  backup_window                       = var.backup_window

  ca_cert_identifier                  = "rds-ca-2019"

  deletion_protection                 = false

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }
}