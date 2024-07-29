#!/bin/bash

OS=fedora
OSVER=fedora-40

podman manifest create quay.io/foreman/nboci-files:$OSVER

rm -f ./work/*
podman build -v $(pwd)/work:/root:Z -f Containerfile-$OS-amd64 --platform linux/amd64

podman manifest create quay.io/foreman/nboci-files:$OSVER-amd64
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --os linux --arch amd64 --os-version $OSVER \
    --artifact quay.io/foreman/nboci-files:$OSVER-amd64 ./work/*
podman manifest push quay.io/foreman/nboci-files:$OSVER-amd64

rm -f ./work/*
podman build -v $(pwd)/work:/root:Z -f Containerfile-$OS-arm64 --platform linux/arm64

podman manifest create quay.io/foreman/nboci-files:$OSVER-arm64
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --os linux --arch arm64 --os-version $OSVER \
    --artifact quay.io/foreman/nboci-files:$OSVER-arm64 ./work/*
podman manifest push quay.io/foreman/nboci-files:$OSVER-arm64

podman manifest add --all --annotation org.pulpproject.netboot.version=1 quay.io/foreman/nboci-files:$OSVER \
    quay.io/foreman/nboci-files:$OSVER-amd64 \
    quay.io/foreman/nboci-files:$OSVER-arm64

podman manifest push --all quay.io/foreman/nboci-files:$OSVER
