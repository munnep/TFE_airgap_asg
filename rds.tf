
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "12"
  instance_class         = "db.t3.large"
  username               = "postgres"
  password               = var.rds_password
  parameter_group_name   = "default.postgres12"
  skip_final_snapshot    = true
  db_name                = "tfe"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.tfe_server_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  identifier             = "${var.tag_prefix}-rds"
  tags = {
    "Name" = var.tag_prefix
  }

  depends_on = [
    aws_s3_object.object_bootstrap
  ]
}

