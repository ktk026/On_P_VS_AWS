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


# SSH 접속을 위한 변수
variable "my_ips" {
  type    = list(string)
  default = ["106.248.40.229/32"]
}
