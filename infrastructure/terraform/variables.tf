variable "primary_region" {
  default = "us-east-1"
}

variable "dr_region" {
  default = "us-west-2"
}

variable "project_name" {
  default = "fincorp"
}

variable "db_password" {
  sensitive = true
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}
