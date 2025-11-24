#!/bin/bash

set -e

pushd terraform
PROJECT_ID=$(terraform output -raw project_id)
terraform destroy -var="project_id=$PROJECT_ID" -auto-approve
popd