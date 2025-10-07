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
AWS_ROLE_TO_ASSUME update new one in github secrets has to be inline with current infra deployment!
find iam role aws iam list-roles | grep <role-name-or-prefix>

Then describe it aws iam get-role --role-name <your-gha-oidc-role-name>

make changes to files in the following paths
      - "app/**"
      - "scripts/**"
      - "docker-compose.yml"

add commit push

watch cicd pick it up and pass 

access alb_dns_name address terraform output and see the change made

add manual rollback procedure

clean up