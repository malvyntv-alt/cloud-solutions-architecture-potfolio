resource "aws_ecr_repository" "app" {
  name                 = "${var.project}-app"
  force_delete         = true
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}

resource "aws_ecr_repository" "email" {
  name                 = "${var.project}-email"
  force_delete         = true
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}
