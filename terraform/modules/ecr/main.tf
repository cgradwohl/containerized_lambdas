variable "name" {
  type = string
}

resource "aws_ecr_repository" "this" {
  name = var.name
  tags = {
    "project" : var.name
  }
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "name" {
  value = aws_ecr_repository.this.name
}
