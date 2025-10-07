# Setup and Testing on AWS ECS-Fargate
- ### Run initial Bootstrap for Remote State and OIDC
```
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```
- ### Deploy ECR Registries:
```
cd terraform/ecr
terraform init
terraform plan
terraform apply
```
- ### Manually Build and Push image to ECR with "initial" Tag:
```
pip install boto3
aws configure  # if needed auth
python scripts/build_and_push_initial.py
```
- ### Deploy ECS-Fargate Cluster:
```
cd terraform/ecs
terraform init
terraform plan
terraform apply
```
- ### Access `alb_dns_name` from `terraform output` in the browser
- ### Test the CI/CD Zero-Downtime Deployment:
- Get the `AWS_ROLE_TO_ASSUME` secret:
```
iam role aws iam list-roles | grep <gha-oidc-role-name>
aws iam get-role --role-name <gha-oidc-role-name>
```
- Create `AWS_ROLE_TO_ASSUME` secret on `GitHub Actions Secrets`
- Uncomment `main-ci.yml` and `terraform-ci.yml` Triggers
- Make some changes to the following Folders:
```
- "app/**"
- "scripts/**"
- "docker-compose.yml"

# Recommended: app/frontend/public/index.html
```
- Add -> Commit -> Push to `main` on GitHub
- Watch CI: Test-Build-Publish-Commit new image back to `main`
- Watch CD: Trigger on CI completion and Apply new tasks to AWS ECS-Fargate
- Access `alb_dns_name` from `terraform output` in the browser and see the change with a Zero-Downtime Deployment
- ### For a Manual Rollback using Local Git:
```
git revert HEAD
git push origin HEAD:$(git rev-parse --abbrev-ref HEAD)
# CI/CD will deploy the previous image version to AWS
```
- ### Clean Up:
```
1. Remove AWS_ROLE_TO_ASSUME Secret
2. cd terraform/ecs -- terraform destroy
3. Manually Empty ECR Registries
4. cd terraform/ecr -- terraform destroy
5. Manually Empty S3 Bucket
6. cd terraform/bootstrap
7. Run terraform destroy and see what is blocking
8. Remove Blocking Resources -- terraform state rm <resource>
9. Run terraform destroy -auto-approve -refresh=false -lock=false
10. Verify AWS Cleaned Up
```
