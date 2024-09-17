#!/bin/bash

info() {
    local message="$1"
    echo -e "\033[34m[CLOUDY] $message\033[0m"
}

CONFIG_FILE="$1"

N_VMS=$(jq -r '.N_VMS' $CONFIG_FILE)
INSTANCE_NAME_BASE=$(jq -r '.INSTANCE_NAME_BASE' $CONFIG_FILE)
MACHINE_TYPE=$(jq -r '.MACHINE_TYPE' $CONFIG_FILE)
ZONE=$(jq -r '.ZONE' $CONFIG_FILE)
IMAGE_FAMILY=$(jq -r '.IMAGE_FAMILY' $CONFIG_FILE)
IMAGE_PROJECT=$(jq -r '.IMAGE_PROJECT' $CONFIG_FILE)
BUCKET_NAME=$(jq -r '.BUCKET_NAME' $CONFIG_FILE)
SERVICE_ACCOUNT=$(jq -r '.SERVICE_ACCOUNT' $CONFIG_FILE)
SETUP_SCRIPT=$(jq -r '.SETUP_SCRIPT' $CONFIG_FILE)
BUCKET_ZONE=$(jq -r '.BUCKET_ZONE' $CONFIG_FILE)
REPO_NAME=$(jq -r '.REPO_NAME' $CONFIG_FILE)
REPO_URL=$(jq -r '.REPO_URL' $CONFIG_FILE)
SCRIPT_PATH=$(jq -r '.SCRIPT_PATH' $CONFIG_FILE)
DEPENDENCIES=$(jq -r '.DEPENDENCIES' $CONFIG_FILE)
SCRIPT_ARGS=$(jq -r '.SCRIPT_ARGS' $CONFIG_FILE)

for ((i = 1; i <= N_VMS; i++)); do
    INSTANCE_NAME="$INSTANCE_NAME_BASE-$i"

    info "Creating instance: $INSTANCE_NAME..."
    gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family="$IMAGE_FAMILY" \
        --image-project="$IMAGE_PROJECT" \
        --service-account="$SERVICE_ACCOUNT" \
        --scopes https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/devstorage.full_control

    while ! gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="info Instance ready!" 2>/dev/null; do
        info "Waiting for SSH service to be available..."
        sleep 10
    done

    info "Copying setup script to the VM instance..."
    gcloud compute scp scripts/$SETUP_SCRIPT "$INSTANCE_NAME:~/" --zone="$ZONE"

    info "Running setup script on the VM instance..."
    gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="chmod +x ~/$SETUP_SCRIPT && ~/$SETUP_SCRIPT '$INSTANCE_NAME' '$BUCKET_NAME' '$BUCKET_ZONE' '$REPO_NAME' '$REPO_URL' '$SCRIPT_PATH' '$DEPENDENCIES' '$SCRIPT_ARGS' '$ZONE'"

    info "$INSTANCE_NAME finished!"
done
