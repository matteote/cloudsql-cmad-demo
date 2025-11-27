#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <project_id> <zone>"
    exit 1
fi

PROJECT_ID=$1
ZONE=$2

START_TIME=$SECONDS

# Check that the specificed project exists
echo "Checking if project '$PROJECT_ID' exists"
if ! gcloud projects describe $PROJECT_ID >/dev/null 2>&1; then
    echo "Error: Project '$PROJECT_ID' not found."
    exit 1
fi

# Enable the Compute API
echo "Checking if Compute API is enabled"
if ! gcloud services list --project=$PROJECT_ID --filter="name:compute.googleapis.com" --format="value(state)" | grep -q "ENABLED"; then
    echo "Enabling Compute API"
    gcloud services enable compute.googleapis.com --project=$PROJECT_ID
    sleep 5
fi

# Determine the region based on the specified zone
echo "Deriving region from zone $ZONE"
REGION=$(gcloud compute zones list --project=$PROJECT_ID --filter "name=$ZONE" --format "value(region)")

if [ -z "$REGION" ]; then
    echo "Error: Invalid zone '$ZONE'"
    exit 1
fi

echo "Using project '$PROJECT_ID', zone '$ZONE', and region '$REGION'"

# Deploy terraform
echo "$(date) - Deploying Terraform"
pushd terraform >/dev/null
echo "$(date) - Initializing Terraform"
terraform init
if ! terraform apply --auto-approve -var="project_id=$PROJECT_ID" -var="zone=$ZONE" -var="region=$REGION"; then
    echo "Terraform apply failed. Retrying in 5 seconds..."
    sleep 5
    terraform apply --auto-approve -var="project_id=$PROJECT_ID" -var="zone=$ZONE" -var="region=$REGION"
fi
INSTANCE_NAME=$(terraform output -raw instance_name)
CLIENT_INSTANCE_NAME=$(terraform output -raw client_instance_name)
popd >/dev/null

# Wait for DC initialization to complete
echo "$(date) - Waiting for the Domain Controller to complete initialization"
while ! gcloud compute instances get-serial-port-output --port 1 --zone=$ZONE --project=$PROJECT_ID $INSTANCE_NAME 2>/dev/null | grep -q "DC fully initialized."; do
    echo "$(date) - Still waiting for the Domain Controller to complete initialization"
    sleep 60
done
echo "$(date) - The Domain Controller is initialized"

# Wait for client initialization to complete
echo "$(date) - Waiting for the client instance to complete initialization"
while ! gcloud compute instances get-serial-port-output --port 1 --zone=$ZONE --project=$PROJECT_ID $CLIENT_INSTANCE_NAME 2>/dev/null | grep -q "Client fully initialized."; do
    echo "$(date) - Still waiting for the client instance to complete initialization"
    sleep 60
done
echo "$(date) - The client instance is initialized"

ELAPSED_TIME=$(($SECONDS - $START_TIME))

echo "Total elapsed time: $(($ELAPSED_TIME/60)) minutes and $(($ELAPSED_TIME%60)) seconds."

echo ""

./get-lab-info.sh
