# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Functional Tests

# Get the directory that this script is in - move to tests dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$DIR/../tests" > /dev/null

# Get env vars for workspace from Terraform outputs
source "${DIR}/environments/infrastructure.env"
source "${DIR}/load-env.sh"

# This is called if we are in a CI system and we will login
# with a Service Principal.
if [ -n "${IN_AUTOMATION}" ]
then
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

# Install requirements
pip install -r requirements.txt --disable-pip-version-check -q

BASE_PATH=$(realpath "$DIR/..")

# Pipeline functional test
python run_tests.py \
    --storage_account_url "${BLOB_STORAGE_ACCOUNT_ENDPOINT}" \
    --search_service_endpoint "${AZURE_SEARCH_SERVICE_ENDPOINT}" \
    --search_index "${AZURE_SEARCH_INDEX}" \
    --wait_time_seconds 60 \
    --file_extensions "docx" "pdf" "html" "jpg" "png" "csv" "md" "pptx" "txt" "xlsx" "xml"

# Rest API functional test
python run_api_tests.py \
    --enrichment_service_endpoint "${ENRICHMENT_APPSERVICE_NAME}" \
    --azure_websites_domain "${TF_VAR_azure_websites_domain}"
