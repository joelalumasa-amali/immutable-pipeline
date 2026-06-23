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
  default   = "FinCorp2024!"
  sensitive = true
}
