variable "cluster_name" {
  default = "app-eks"
}

variable "db_username" {
  default = "postgres"
}

variable "db_password" {
  sensitive = true
  default   = "db_password"
}
