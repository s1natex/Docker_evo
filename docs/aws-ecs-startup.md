(1)
initial bootstrap for remote and oidc
deploy
cd terraform/bootstrap
terraform init
terraform apply

destroy
cd terraform/bootstrap
terraform destroy
===============
(2)
ecr
deploy
cd terraform/ecr
terraform init
terraform apply

destroy
cd terraform/ecr
terraform destroy
=========