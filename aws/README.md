# AWS

## Commands to run in AWS CloudShell to get started

```bash
cd /home/cloudshell-user
```

## Download and Install Terraform

```bash
wget https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip -O /tmp/terraform.zip
sudo unzip -d /usr/local/bin/ /tmp/terraform.zip
```

## Get code

```bash
git clone https://github.com/bluemountaincyber/elastic-workshop.git
cd /home/cloudshell-user/elastic-workshop/aws
```

## Deploy

Set the password to something strong as this is public-facing by default.

```bash
terraform init
terraform apply -auto-approve -var="aws_region=$AWS_DEFAULT_REGION" -var="elastic_password=SuperStrongPassword"
```

Output will provide the URL of Kibana. After deployment completes, it still takes roughly 5 minutes until you can access the Kibana app.

Default credentials for Kibana are as follows (unless you changed it during deployment... which is HIGHLY recommended):

- Username: `elastic`

- Password: `CloudSecurity`

## Teardown

```bash
cd /home/cloudshell-user/elastic-workshop/aws
terraform destroy -auto-approve -var="aws_region=$AWS_DEFAULT_REGION"
aws dynamodb delete-table --table-name logstash --region $AWS_DEFAULT_REGION
```