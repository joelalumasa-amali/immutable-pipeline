# The Immutable & Indestructible Pipeline

A secure CI/CD pipeline with immutable artifacts and cross-region disaster recovery for FinCorp, a fictional financial services company.

## Objectives

- Implement a secure CI/CD pipeline that produces immutable artifacts
- Demonstrate a Cross-Region Disaster Recovery (DR) failover within 30 minutes

## Part 1 — Artifact Pipeline

**AWS CodeArtifact** acts as an upstream proxy for npm and pip packages, giving FinCorp control over which packages enter the supply chain.

**Amazon ECR** is configured with Tag Immutability and Image Scanning on push. Once an image is pushed with a given tag (the git commit SHA), it can never be overwritten.

**GitHub Actions pipeline** builds the Docker image, pushes it to ECR, waits for the vulnerability scan, and fails the build if any High or Critical CVEs are found.

## Part 2 — Disaster Recovery

**RDS MySQL** deployed in us-east-1 as the primary database.

**AWS Backup** configured with a daily backup plan and automatic cross-region copy to us-west-2.

**DR simulation:** Primary DB deleted to simulate region failure. Snapshot copied to us-west-2 and restored as a new DB instance. Recovery completed well within the 30-minute RTO.

## Infrastructure (Terraform)

- ECR repository with IMMUTABLE tag mutability and scan on push
- CodeArtifact domain with npm and pip upstream proxies
- RDS MySQL db.t3.micro in us-east-1
- AWS Backup vaults in us-east-1 and us-west-2
- Backup plan with daily schedule and cross-region copy
- IAM role for AWS Backup

## Pipeline Flow

1. Push to main branch triggers GitHub Actions
2. AWS credentials configured via repository secrets
3. Docker image built from app/Dockerfile
4. Image pushed to ECR with immutable commit SHA tag
5. ECR scans image for vulnerabilities
6. Pipeline checks scan results and fails on High/Critical findings
7. Clean builds proceed; vulnerable builds are blocked
