data "aws_vpc" "default" {
  provider = aws.primary
  default  = true
}

data "aws_subnets" "default" {
  provider = aws.primary

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "rds" {
  provider    = aws.primary
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL inbound from within VPC only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "primary" {
  provider                = aws.primary
  identifier              = "${var.project_name}-primary-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "fincorp"
  username                = "admin"
  password                = var.db_password
  skip_final_snapshot     = true
  publicly_accessible     = false
  storage_encrypted       = true
  backup_retention_period = 7
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  tags = {
    Name = "${var.project_name}-primary-db"
  }
}
