resource "aws_codeartifact_domain" "main" {
  provider = aws.primary
  domain   = "${var.project_name}-artifacts"
}

resource "aws_codeartifact_repository" "npm" {
  provider    = aws.primary
  repository  = "${var.project_name}-npm"
  domain      = aws_codeartifact_domain.main.domain

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
