#!/bin/bash

# Commands to run in AWS CloudShell to get started
cd /home/cloudshell-user

# Download and Install Terraform
wget https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip -O /tmp/terraform.zip
sudo unzip -d /usr/local/bin/ /tmp/terraform.zip

# Get code
git clone https://github.com/bluemountaincyber/opensearch-workshop.git
cd /home/cloudshell-user/opensearch-workshop/aws

# Deploy
terraform init
terraform apply -auto-approve