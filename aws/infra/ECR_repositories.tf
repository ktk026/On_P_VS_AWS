resource "aws_ecr_repository" "services" {
    for_each = toset(var.ecr_repositories)
    name     = each.key

    lifecycle {
        prevent_destroy = true
    }
}

import {
    for_each = toset(var.ecr_repositories)
    to       = aws_ecr_repository.services[each.key]
    id       = each.key
}