import subprocess
import json
import sys
import os

region = os.environ.get("AWS_REGION", "us-east-1")
repo = os.environ.get("ECR_REPOSITORY", "fincorp-app")
tag = os.environ.get("IMAGE_TAG")

result = subprocess.run([
    "aws", "ecr", "describe-image-scan-findings",
    "--repository-name", repo,
    "--image-id", f"imageTag={tag}",
    "--region", region,
    "--output", "json"
], capture_output=True, text=True)

print("Raw output:", result.stdout)

data = json.loads(result.stdout)
counts = data.get("imageScanFindings", {}).get("findingSeverityCounts", {}) or {}

high = counts.get("HIGH", 0)
critical = counts.get("CRITICAL", 0)

print(f"HIGH: {high}, CRITICAL: {critical}")

if high > 0 or critical > 0:
    print("FAILED: High or Critical vulnerabilities found.")
    sys.exit(1)

print("PASSED: No High or Critical vulnerabilities found.")
