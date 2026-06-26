data "aws_caller_identity" "current" {
  provider = aws.primary
}

resource "aws_codeartifact_domain" "main" {
  provider = aws.primary
  domain   = "${var.project_name}-artifacts"
}

resource "aws_codeartifact_domain_permissions_policy" "main" {
  provider = aws.primary
  domain   = aws_codeartifact_domain.main.domain

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCurrentAccountOnly"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "codeartifact:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_codeartifact_repository" "npm" {
  provider   = aws.primary
  repository = "${var.project_name}-npm"
  domain     = aws_codeartifact_domain.main.domain

  external_connections {
    external_connection_name = "public:npmjs"
  }
}

resource "aws_codeartifact_repository" "pip" {
  provider   = aws.primary
  repository = "${var.project_name}-pip"
  domain     = aws_codeartifact_domain.main.domain

  external_connections {
    external_connection_name = "public:pypi"
  }
}
