#!/usr/bin/env python3
import subprocess
import boto3
import sys
from pathlib import Path

AWS_REGION = "eu-central-1"
PROJECT = "docker-evo"

# ECR repo names must match terraform/ecr output
REPOS = [
    f"{PROJECT}-frontend",
    f"{PROJECT}-pass-gen"
]

# relative to repo root
FRONTEND_PATH = Path("app/frontend")
BACKEND_PATH = Path("app/pass-gen")

def run(cmd, cwd=None, check=True):
    print(f"$ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=check)

def main():
    print(f"Logging into ECR in region {AWS_REGION} ...")
    # docker login via aws cli (no emojis / unicode)
    # Get ECR endpoint from boto3 to ensure correct registry host
    ecr = boto3.client("ecr", region_name=AWS_REGION)
    auth = ecr.get_authorization_token()
    endpoint = auth["authorizationData"][0]["proxyEndpoint"]

    # Pipe password to docker login
    subprocess.run(
        f"aws ecr get-login-password --region {AWS_REGION} | docker login --username AWS --password-stdin {endpoint}",
        shell=True,
        check=True
    )

    account_id = boto3.client("sts").get_caller_identity()["Account"]
    registry = f"{account_id}.dkr.ecr.{AWS_REGION}.amazonaws.com"

    images = [
        (REPOS[0], FRONTEND_PATH),
        (REPOS[1], BACKEND_PATH)
    ]

    for repo, path in images:
        full_tag = f"{registry}/{repo}:initial"
        print(f"\n--- Building {repo} ---")
        run(["docker", "build", "-t", full_tag, "."], cwd=path)
        print(f"Pushing {full_tag} ...")
        run(["docker", "push", full_tag])

    print("\nAll images built and pushed with tag: 'initial'")

if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
