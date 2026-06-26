resource "aws_kms_key" "backup_primary" {
  provider                = aws.primary
  description             = "KMS key for primary backup vault encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-backup-primary-kms"
  }
}

resource "aws_kms_key" "backup_dr" {
  provider                = aws.dr
  description             = "KMS key for DR backup vault encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-backup-dr-kms"
  }
}

resource "aws_iam_role" "backup" {
  provider = aws.primary
  name     = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  provider   = aws.primary
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  provider   = aws.primary
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_vault" "primary" {
  provider    = aws.primary
  name        = "${var.project_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup_primary.arn
}

resource "aws_backup_vault" "dr" {
  provider    = aws.dr
  name        = "${var.project_name}-dr-vault"
  kms_key_arn = aws_kms_key.backup_dr.arn
}

resource "aws_backup_plan" "main" {
  provider = aws.primary
  name     = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 2 * * ? *)"

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn
    }
  }
}

resource "aws_backup_selection" "rds" {
  provider     = aws.primary
  name         = "${var.project_name}-rds-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_db_instance.primary.arn
  ]
}
