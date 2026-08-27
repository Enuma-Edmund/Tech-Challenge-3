# Tech Challenge 3

## Cloud Engineer Coding Challenge 3: Infrastructure as Code with Terraform and Ansible

## Overview

This project demonstrates how **Terraform** and **Ansible** can be used together to provision and configure infrastructure on **Amazon Web Services (AWS)**.

Terraform is responsible for creating the AWS infrastructure, including an EC2 instance, S3 bucket, IAM resources, security group, subnet, and SSH key pair.

After the infrastructure is created, Ansible connects to the EC2 instance through SSH, installs and configures **Nginx**, and deploys a simple web page displaying:

**Hello, World!**

In simple terms:

**Terraform builds the infrastructure, and Ansible configures what runs inside the server.**

---

## Architecture

The project follows this general flow:

```text
Local Computer
      |
      +----------------------+
      |                      |
  Terraform               Ansible
      |                      |
      v                      |
     AWS                     |
      |                      |
      +-- EC2 <--------------+
      +-- S3             SSH :22
      +-- IAM
      +-- Security Group
      +-- Subnet
            |
            v
        EC2 Instance
            |
            v
          Nginx
            |
            v
        index.html
            |
            v
       Hello, World!
            ^
            |
         HTTP :80
            |
         Internet
```

The project source code is version-controlled and stored in a private GitHub repository.

---

## Technologies Used

* **AWS** — Cloud platform where the infrastructure runs.
* **Terraform** — Infrastructure as Code tool used to provision AWS resources.
* **Ansible** — Configuration management tool used to configure the EC2 instance.
* **EC2** — Virtual server hosting the website.
* **S3** — AWS object storage required by the challenge.
* **IAM** — Provides controlled AWS permissions to the EC2 instance.
* **Nginx** — Web server that serves the Hello World page.
* **Git** — Tracks changes to the project.
* **GitHub** — Stores the version-controlled project repository.
* **SSH** — Provides secure remote access to the EC2 instance.

---

## Project Structure

```text
tech-challenge-3/
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── files/
│       └── index.html
│
├── README.md
└── .gitignore
```

The `terraform` directory contains the infrastructure configuration.

The `ansible` directory contains the server configuration and web page.

The `.gitignore` prevents sensitive and unnecessary local files from being committed to Git.

---

## Prerequisites

Before deploying this project, the following are required:

* AWS account
* AWS CLI
* Terraform
* Ansible
* Git
* GitHub account
* SSH
* Code editor such as Visual Studio Code

AWS CLI credentials must also be configured and working.

Authentication can be verified with:

```bash
aws sts get-caller-identity
```

AWS credentials must never be stored directly inside the Terraform configuration or committed to GitHub.

---

# Terraform Infrastructure

Terraform is used to define the **desired AWS infrastructure as code**.

Instead of manually creating each resource through the AWS Console, the infrastructure is described in Terraform files and created automatically.

## EC2

Terraform creates an **Ubuntu 24.04 EC2 instance**.

The EC2 instance is the virtual computer that eventually runs Nginx and hosts the Hello World web page.

The instance uses encrypted storage and requires IMDSv2 for improved metadata security.

## S3

Terraform creates an **S3 bucket** with a generated unique name.

Public access to the bucket is blocked because the S3 bucket does not need to be publicly accessible for this project.

The website itself is hosted by Nginx on EC2 rather than S3.

## Security Group

The Security Group acts as the EC2 instance's virtual firewall.

It allows:

* **SSH (port 22)** only from the administrator's specified public IP address.
* **HTTP (port 80)** from the internet so users can access the website.
* Outbound traffic so the EC2 instance can download required software packages.

## IAM Role

Terraform creates an IAM role for the EC2 instance.

Rather than giving the server broad administrative access, the project follows the **principle of least privilege**.

The EC2 instance receives only the required read permissions for the project's S3 bucket.

An IAM instance profile connects the IAM role to the EC2 instance.

---

# Ansible Configuration

After Terraform creates the infrastructure, **Ansible takes over the server configuration**.

Ansible connects to the EC2 instance through SSH using the Ubuntu user and the project's private SSH key.

## Nginx

The Ansible playbook:

1. Updates Ubuntu's package information.
2. Installs Nginx.
3. Starts the Nginx service.
4. Enables Nginx to start automatically after a reboot.
5. Deploys the custom web page.

Ansible uses a **desired-state approach**. This means the playbook describes how the server should be configured rather than blindly repeating commands every time it runs.

## Hello World Page

The web page is stored locally at:

```text
ansible/files/index.html
```

Ansible copies this file to Nginx's web directory on the EC2 instance.

The resulting website displays:

> # Hello, World!
>
> Deployed with Terraform, Ansible, AWS, and Nginx.

---

# Deployment Instructions

## 1. Configure AWS

Configure AWS CLI credentials:

```bash
aws configure
```

Verify authentication:

```bash
aws sts get-caller-identity
```

---

## 2. Generate an SSH Key

Create a dedicated SSH key pair:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/tech-challenge-3
```

The public key can be provided to AWS.

The private key must remain securely on the local computer and must never be committed to GitHub.

---

## 3. Configure Terraform Variables

Configure the required values, including:

* AWS region
* EC2 instance type
* SSH public key path
* Administrator public IP address

SSH access should use the administrator's IP with `/32` rather than allowing SSH from the entire internet.

---

## 4. Initialize Terraform

Move into the Terraform directory:

```bash
cd terraform
terraform init
```

---

## 5. Format and Validate Terraform

```bash
terraform fmt
terraform validate
```

This ensures the Terraform configuration is formatted correctly and structurally valid.

---

## 6. Preview the Infrastructure

```bash
terraform plan
```

The plan allows the proposed infrastructure changes to be reviewed before anything is created.

---

## 7. Deploy the Infrastructure

```bash
terraform apply
```

Review the proposed changes and enter `yes` when prompted.

After deployment, retrieve the Terraform outputs:

```bash
terraform output
```

The outputs include the EC2 public IP address and website URL.

---

## 8. Configure the Ansible Inventory

Update:

```text
ansible/inventory.ini
```

with the EC2 public IP returned by Terraform.

The inventory tells Ansible which server it should manage and which SSH credentials it should use.

---

## 9. Test Ansible Connectivity

Move into the Ansible directory:

```bash
cd ../ansible
```

Test the connection:

```bash
ansible all -i inventory.ini -m ping
```

A successful connection returns:

```text
"ping": "pong"
```

This confirms that Ansible can connect to the EC2 instance and execute its modules.

---

## 10. Check the Playbook

Before making changes to the server, check the playbook syntax:

```bash
ansible-playbook -i inventory.ini playbook.yml --syntax-check
```

---

## 11. Configure the Server

Run:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Ansible will install and configure Nginx and deploy the Hello World page.

A successful play recap should show:

```text
unreachable=0
failed=0
```

---

## 12. Verify the Website

Retrieve the EC2 public IP from Terraform if necessary:

```bash
cd ../terraform
terraform output -raw ec2_public_ip
```

Open the address in a browser:

```text
http://EC2_PUBLIC_IP
```

The browser should display:

**Hello, World!**

**Deployed with Terraform, Ansible, AWS, and Nginx.**

---

# Terraform Code Explanation

The Terraform configuration performs several jobs.

`providers.tf` defines Terraform's AWS provider and AWS region.

`variables.tf` defines reusable values required by the infrastructure.

`main.tf` defines the AWS infrastructure, including the VPC lookup, subnet, EC2 instance, S3 bucket, IAM resources, SSH key pair, and Security Group.

`outputs.tf` displays important information after deployment, including the EC2 public IP address, DNS name, S3 bucket name, and website URL.

Terraform state keeps track of the infrastructure Terraform currently manages.

---

# Ansible Code Explanation

`inventory.ini` tells Ansible which EC2 server it should manage and how to connect to it.

`playbook.yml` describes the desired configuration of that server.

The playbook updates the Ubuntu package cache, installs Nginx, ensures Nginx is running and enabled, and copies the custom web page to the Nginx web directory.

`files/index.html` contains the Hello World page served to visitors.

Terraform and Ansible therefore have separate responsibilities:

**Terraform = Infrastructure provisioning**

**Ansible = Server configuration**

---

# Verification

The deployment can be verified at several levels.

Terraform infrastructure can be checked using:

```bash
terraform state list
```

Ansible connectivity can be checked using:

```bash
ansible all -i inventory.ini -m ping
```

Nginx can be verified by checking that the service is running.

The final functional test is opening the EC2 public IP address in a browser and confirming that the **Hello, World!** page appears.

The Ansible playbook can also be run a second time to demonstrate **idempotency**. Once the server already matches the requested configuration, Ansible should report most tasks as `ok` rather than repeatedly changing the server.

---

# Security Considerations

Several security practices were included in this project:

* SSH access is restricted to the administrator's public IP.
* S3 public access is blocked.
* AWS credentials are not stored in Terraform source code.
* Private SSH keys are not committed to GitHub.
* Terraform state files are excluded from Git.
* Terraform variable files are excluded from Git.
* The EC2 instance receives AWS permissions through an IAM role.
* The IAM policy follows least privilege by limiting S3 permissions.
* The EC2 root disk is encrypted.
* EC2 Instance Metadata Service Version 2 (IMDSv2) is required.

These controls reduce unnecessary exposure while still allowing the application to function.

---

# Cleanup

When the project is no longer needed, Terraform can remove the infrastructure it created.

From the Terraform directory, run:

```bash
terraform destroy
```

Review the resources Terraform plans to remove and enter:

```text
yes
```

This removes the Terraform-managed AWS resources and prevents unnecessary AWS resources from continuing to run.

---

## Final Result

This project demonstrates an automated infrastructure and configuration workflow:

**Terraform → AWS Infrastructure → EC2 → Ansible → Nginx → Hello World**

Terraform creates the cloud infrastructure, Ansible configures the server, Nginx serves the web page, and GitHub provides version control for the project.

The final result is a publicly accessible **Hello, World!** web page running on an AWS EC2 instance that was provisioned with Terraform and configured with Ansible.

