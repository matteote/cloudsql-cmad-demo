# Gemini Agent Instructions

This document provides instructions for the Gemini agent on how to interact with this project.

## About This Project

This project contains the necessary infrastructure as code to demonstrate the Customer-managed Active Directory (CMAD) functionality of Google Cloud SQL for SQL Server.

The project uses Terraform to provision the following Google Cloud resources:
*   A Virtual Private Cloud (VPC) network.
*   A Windows Virtual Machine to act as an Active Directory Domain Controller.
*   A Google Cloud SQL for SQL Server instance to be later joined to Active Directory.

## Getting Started

This project uses Terraform to manage Google Cloud resources. Ensure you have the following prerequisites installed and configured:
*   Google Cloud SDK (`gcloud`)
*   Terraform

Before running any commands, you need to authenticate with Google Cloud and configure your project.

```bash
# Example setup commands (replace with your project-specific values)
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

The `get-lab-info.sh` script might be used to fetch details about the lab environment, such as machine names and credentials, after the resources have been provisioned.

## Project Conventions

*   **Infrastructure:** All infrastructure is defined in Terraform (`.tf` files). Please follow the existing structure and style when modifying the infrastructure.
*   **Scripts:** Shell scripts (`.sh`) and PowerShell scripts (`.ps1`) are used for automation. Maintain the existing style and conventions when editing these files.
*   **Variables:** Terraform variables are defined in `variables.tf`. Avoid hardcoding values in `main.tf` files.

## Deployment and Cleanup

The following scripts are used to deploy and clean up the demo environment.

### Deploying the Environment

The `deploy.sh` script expects two arguments: the GCP Project ID and the GCP Zone, and it runs `terraform apply` to create the resources.

```bash
# Example deployment command
./deploy.sh <YOUR_PROJECT_ID> <YOUR_GCP_ZONE>
```

### Cleaning Up the Environment

The `cleanup.sh` script runs `terraform destroy` to remove all created resources.

```bash
# Example cleanup command
./cleanup.sh
```

### Accessing the Windows VM

The `windows_shell.sh` script can be used to access the Windows VM, via SSH.

### Code repository

The project is tracked using git.
There is a private github repository named matteote/cloudsql-cmad-demo-pri.

## Agent Directives

### What You Can Do

*   You are allowed to read and modify Terraform files (`.tf`), shell scripts (`.sh`), and PowerShell scripts (`.ps1`).
*   You can use `terraform plan` to preview changes.
*   You can create new files and directories as needed.
*   You can interact with github (in the matteote/cloudsql-cmad-demo-pri repository) to fetch, pull, commit and push the repository content.
*   You can interact with github (in the matteote/cloudsql-cmad-demo-pri repository) to manage issues, including creatind, updating, closing and deleting issues..

### What You Cannot Do

*   **Do not run `deploy.sh`, `cleanup.sh`, or execute `terraform apply` or `terraform destroy` without explicit confirmation from the user.** These commands can create, modify, or delete cloud resources and may incur costs.
*   Do not commit any sensitive information, such as credentials or secrets, to the repository.
*   Do not create pull requests.
