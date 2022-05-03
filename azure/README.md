# AWS

## Commands to run in Azure CloudShell to get started

```bash
cd $HOME
```

## Get code

```bash
git clone https://github.com/bluemountaincyber/elastic-workshop.git
cd $HOME/elastic-workshop/azure
```

## Deploy

Set the passwords to something strong as these systems are public-facing by default.

```bash
terraform init
terraform apply -auto-approve -var="az_location=westeurope" -var="elastic_app_password=SuperStrongPassword" -var='elastic_vm_password=Super$trongPassw0rd' -var='victim_vm_password=Super$trongPassw0rd'
```

Output will provide the URL of Kibana. After deployment completes, it still takes roughly 5 minutes until you can access the Kibana app.

Default credentials for Kibana are as follows (unless you changed it during deployment... which is HIGHLY recommended):

- Username: `elastic`

- Password: `CloudSecurity`

## Teardown

```bash
cd $HOME/elastic-workshop/azure
terraform destroy -auto-approve -var="az_location=westeurope" -var="elastic_app_password=SuperStrongPassword" -var='elastic_vm_password=Super$trongPassw0rd' -var='victim_vm_password=Super$trongPassw0rd'
```