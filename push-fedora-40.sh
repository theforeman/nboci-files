#!/bin/bash

OS=fedora
OSVER=fedora-40
WORKDIR=$PWD/work

# create image index and set the annotation at the index level
# TODO set the artifactType at the index level https://github.com/containers/podman/issues/23598
podman manifest create quay.io/foreman/nboci-files:$OSVER --annotation org.pulpproject.netboot.version=1

mkdir -p "$WORKDIR"
VOLUME1=$(mktemp -d -p "$WORKDIR")

podman build -v "${VOLUME1}:/root:Z" -f Containerfile-$OS-amd64 --platform linux/amd64

# create and add netboot artifacts for amd64 to the image index
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --os linux --arch amd64 --os-version $OSVER \
    --artifact \
    --artifact-type application/vnd.org.pulpproject.netboot.artifact.v1 \
    --artifact-layer-type application/x-netboot-file \
    quay.io/foreman/nboci-files:$OSVER "$VOLUME1"/*

VOLUME2=$(mktemp -d -p "$WORKDIR")
podman build -v "${VOLUME2}:/root:Z" -f Containerfile-$OS-arm64 --platform linux/arm64

# create and add netboot artifacts for arm64 to the image index
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --os linux --arch arm64 --os-version $OSVER \
    --artifact \
    --artifact-type application/vnd.org.pulpproject.netboot.artifact.v1 \
    --artifact-layer-type application/x-netboot-file \
    quay.io/foreman/nboci-files:$OSVER "$VOLUME2"/*

rm -rf "$WORKDIR"

# push image index containing netboot artifacts for different arches
podman manifest push --all --rm quay.io/foreman/nboci-files:$OSVER

# tag child manifests
# going to use skopeo for now https://github.com/containers/podman/issues/23599
# Parse index image, find corresponding child manifests and tag them accordingly
skopeo inspect docker://quay.io/foreman/nboci-files:$OSVER --raw |jq -r '.manifests.[] | "\(.platform.architecture) \(.digest)"' | while read -r i; do ARCH="$(echo "$i" | awk '{print $1}')"; DIGEST="$(echo "$i" | awk '{print $2}')" ; skopeo copy "docker://quay.io/foreman/nboci-files@${DIGEST}" "docker://quay.io/foreman/nboci-files:$OSVER-${ARCH}" ; done
