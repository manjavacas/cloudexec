#!/bin/bash

N_VMS=2

INSTANCE_NAME_BASE="vm-experiment"

MACHINE_TYPE="e2-medium"
ZONE="europe-southwest1-b"

IMAGE_FAMILY="ubuntu-2004-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

SETUP_SCRIPT="setup.sh"

for ((i = 1; i <= N_VMS; i++)); do
    INSTANCE_NAME="$INSTANCE_NAME_BASE-$i"

    echo "Creando instancia: $INSTANCE_NAME..."
    gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family="$IMAGE_FAMILY" \
        --image-project="$IMAGE_PROJECT"

    while ! gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="echo VM preparada" 2>/dev/null; do
        echo "Esperando a que el servicio SSH esté disponible..."
        sleep 10
    done

    echo "Copiando el script de setup a la instancia..."
    gcloud compute scp "$SETUP_SCRIPT" "$INSTANCE_NAME:~/" --zone="$ZONE"

    echo "Ejecutando el script de setup en la instancia..."
    gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="chmod +x ~/setup.sh && ~/setup.sh $INSTANCE_NAME"

    echo "Instancia $INSTANCE_NAME lista y configurada."
done
