# resource "aws_ecr_repository" "services" {
#   for_each = toset([
#     "app-frontend",
#     "app-api",
#     "app-product",
#     "app-inventory",
#     "app-order",
#     "app-payment",
#     "app-user"
#   ])
#   name         = each.key
#   force_delete = true
# }
