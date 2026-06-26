# Screenshots Guide

This file documents every screenshot needed for the main README.md. Capture these during a live deployment, then place the files here with the exact filenames listed.

---

## Pipeline Screenshots

| Filename | What to capture |
|---|---|
| `pipeline-green.png` | GitHub Actions run with both `code-quality` and `build-scan-push` jobs showing green checkmarks |
| `pipeline-quality-detail.png` | Expanded `code-quality` job showing flake8, pytest, terraform fmt, and hadolint steps all passing |
| `pipeline-scan-block.png` | *(Optional)* A failed run where the ECR scan blocked a build with HIGH/CRITICAL findings |

**Where to go:** `https://github.com/<your-org>/immutable-pipeline/actions`

---

## Amazon ECR Screenshots

| Filename | What to capture |
|---|---|
| `ecr-immutable.png` | ECR repository list showing `fincorp-app` with **Tag immutability: Enabled** and **Scan on push: Enabled** |
| `ecr-scan-results.png` | Image scan findings panel for a pushed image showing the vulnerability summary |
| `ecr-lifecycle.png` | ECR lifecycle policy rules showing the untagged-expire and keep-10-tagged rules |

**Where to go:** AWS Console → ECR → Repositories → fincorp-app

---

## AWS CodeArtifact Screenshots

| Filename | What to capture |
|---|---|
| `codeartifact-domain.png` | CodeArtifact domain `fincorp-artifacts` with its npm and pip repositories listed |
| `codeartifact-packages.png` | Package list inside one repository showing cached upstream packages |
| `codeartifact-policy.png` | Domain permissions policy showing the account-restricted policy JSON |

**Where to go:** AWS Console → CodeArtifact → Domains → fincorp-artifacts

---

## RDS & Security Screenshots

| Filename | What to capture |
|---|---|
| `rds-primary.png` | RDS console showing `fincorp-primary-db` with status **Available** in us-east-1 |
| `rds-encrypted.png` | RDS instance detail page showing **Storage encrypted: Yes** and the KMS key |
| `rds-security-group.png` | The `fincorp-rds-sg` security group inbound rules (port 3306 from VPC CIDR only) |

**Where to go:** AWS Console → RDS → Databases → fincorp-primary-db

---

## AWS Backup Screenshots

| Filename | What to capture |
|---|---|
| `backup-vault-primary.png` | AWS Backup vault `fincorp-backup-vault` in us-east-1 showing recovery points and KMS key |
| `backup-vault-dr.png` | AWS Backup vault `fincorp-dr-vault` in us-west-2 showing cross-region copied recovery points |
| `backup-plan.png` | The `fincorp-backup-plan` showing the daily cron schedule and cross-region copy action |

**Where to go:** AWS Console → AWS Backup → Backup vaults (switch region for DR vault)

---

## DR Failover Screenshots

| Filename | What to capture |
|---|---|
| `dr-script-output.png` | Terminal showing `scripts/dr_failover.sh` running with timestamped step output |
| `rds-dr-restored.png` | RDS console in us-west-2 showing `fincorp-primary-db-dr-restored` with status **Available** |
| `rds-dr-endpoint.png` | Restored instance **Connectivity & security** tab showing the new endpoint URL |

**Where to go:**
1. Run `bash scripts/dr_failover.sh fincorp-primary-db us-east-1 us-west-2` and screenshot the terminal
2. AWS Console (switch to us-west-2) → RDS → Databases

---

## How to Add Screenshots to the README

Each placeholder in README.md looks like:

```markdown
![Description](docs/screenshots/filename.png)
```

Place the actual `.png` file in this directory with the matching filename, commit it, and the image will render in GitHub.
