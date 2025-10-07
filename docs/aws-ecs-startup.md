(1)
initial bootstrap for remote and oidc
deploy
cd terraform/bootstrap
terraform init
terraform apply

destroy last
cd terraform/bootstrap
terraform destroy

*empty s3 bucket manually if needed
===============
(2)
ecr
deploy 
cd terraform/ecr
terraform init
terraform apply

destroy second to last
cd terraform/ecr
terraform destroy
=========
(3)
push initial images to ecr with "initial tag"

pip install boto3
aws configure # if needed
python scripts/build_and_push_initial.py

destory 3rd to last
empty the ecr repos contents
=======
(4)
ecs deploy
cd terraform/ecs
terraform init
terraform apply

destroy 4th to last
terraform destory
========
