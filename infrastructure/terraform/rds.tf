resource "aws_db_instance" "primary" {
  provider             = aws.primary
  identifier           = "${var.project_name}-primary-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "fincorp"
  username             = "admin"
  password             = var.db_password
  skip_final_snapshot  = true
  publicly_accessible  = false
  backup_retention_period = 7

  tags = {
    Name = "${var.project_name}-primary-db"
  }
}
