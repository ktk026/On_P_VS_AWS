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

variable "my_ips" {
  type    = list(string)
  default = ["106.248.40.229/32"]
}

variable "k8s_version" {
  default = "1.34"
}

variable "key_name" {
  default = "key"
}

variable "monitoring_server_ips" {
  type    = list(string)
  default = ["106.248.40.229/32"]
}
