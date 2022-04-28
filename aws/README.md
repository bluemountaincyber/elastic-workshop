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
git clone https://github.com/bluemountaincyber/opensearch-workshop.git
cd /home/cloudshell-user/opensearch-workshop/aws
```

## Deploy

```bash
terraform init
terraform apply -auto-approve -var="aws_region=$AWS_DEFAULT_REGION"
```

Output will provide the URL of the OpenSearch Dashboards. After deployment completes, it still takes roughly 5 minutes until you can access the OpenSearch Dashboards app.

Default credentials for OpenSearch Dashboards are:

- Username: `admin`

- Password: `admin`

## Teardown

```bash
cd /home/cloudshell-user/opensearch-workshop/aws
terraform destroy -auto-approve -var="aws_region=$AWS_DEFAULT_REGION"
aws dynamodb delete-table --table-name logstash --region $AWS_DEFAULT_REGION
```