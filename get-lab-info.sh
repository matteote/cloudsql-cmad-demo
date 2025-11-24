#!/bin/bash

set -e

pushd terraform >/dev/null

if [ ! -s "terraform.tfstate" ] || [ $(jq '.resources | length' terraform.tfstate) -eq 0 ]; then
    echo "The environment has not been deployed yet. Please run deploy.sh first."
    popd >/dev/null
    exit 1
fi

echo "Windows Domain Controller details:"
echo "  Name:       $(terraform output -raw instance_name)"
echo "  User:       demo\administrator"
echo "  Password:   $(terraform output -raw admin_password)"
echo ""
echo "Windows Client details:"
echo "  Name:       $(terraform output -raw client_instance_name)"
echo "  User:       demo\administrator"
echo "  Password:   $(terraform output -raw admin_password)"
echo ""
echo "Cloud SQL for SQL Server instance details:"
echo "  Name:       $(terraform output -raw sql_server_instance_name)"
echo "  IP Address: $(terraform output -raw sql_server_ip_address)"
echo "  User:       sqlserver"
echo "  Password:   $(terraform output -raw sql_server_password)"

PROJECT_ID=$(terraform output -raw project_id)
DNS_IP=$(terraform output -raw ip_address)

echo ""
echo "Use this command to enable CMAD on the Cloud SQL instance:"
echo ""
echo "gcloud sql instances patch $(terraform output -raw sql_server_instance_name) \\"
echo "  --active-directory-mode=CUSTOMER_MANAGED_ACTIVE_DIRECTORY \\"
echo "  --active-directory-domain=demo.lab \\"
echo "  --active-directory-organizational-unit=\"OU=CloudSQL,DC=demo,DC=lab\" \\"
echo "  --active-directory-secret-manager-key=projects/$PROJECT_ID/secrets/windows-credentials \\"
echo "  --active-directory-dns-servers=$DNS_IP"

popd >/dev/null
