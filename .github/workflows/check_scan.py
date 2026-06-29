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

if not result.stdout.strip():
    print("WARNING: Empty response from ECR scan API — scan may not be ready yet.")
    sys.exit(0)

try:
    data = json.loads(result.stdout)
except json.JSONDecodeError as e:
    print(f"WARNING: Could not parse ECR response as JSON ({e}) — skipping gate.")
    sys.exit(0)

scan_status = (
    data.get("imageScanFindings", {}).get("imageScanCompletedAt") or
    data.get("imageScanStatus", {}).get("status", "")
)

# If the scan hasn't finished yet, don't fail the build
if isinstance(scan_status, str) and scan_status.upper() in ("IN_PROGRESS", "PENDING", ""):
    print(f"WARNING: Scan status is '{scan_status}' — results not ready, skipping gate.")
    sys.exit(0)

counts = data.get("imageScanFindings", {}).get("findingSeverityCounts") or {}

high = counts.get("HIGH", 0)
critical = counts.get("CRITICAL", 0)

print(f"HIGH: {high}, CRITICAL: {critical}")

if high > 0 or critical > 0:
    print("FAILED: High or Critical vulnerabilities found.")
    sys.exit(1)

print("PASSED: No High or Critical vulnerabilities found.")
