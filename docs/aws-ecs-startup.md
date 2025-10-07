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
(3)
push initial images to ecr with "initial tag"

pip install boto3
aws configure # if needed
python scripts/build_and_push_initial.py
=======