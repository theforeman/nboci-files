#!/bin/bash

podman manifest create quay.io/lzapletal/nbp1:fedora-40

rm -f ./work/*
podman build -v $(pwd)/work:/root:Z -f Containerfile-fedora-amd64 --platform linux/amd64

podman manifest create quay.io/lzapletal/nbp1:fedora-40-amd64
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --annotation org.pulpproject.netboot.boot=shim.efi \
    --os linux --arch amd64 --os-version fedora-40 \
    --artifact quay.io/lzapletal/nbp1:fedora-40-amd64 ./work/*
podman manifest push quay.io/lzapletal/nbp1:fedora-40-amd64

rm -f ./work/*
podman build -v $(pwd)/work:/root:Z -f Containerfile-fedora-arm64 --platform linux/arm64

podman manifest create quay.io/lzapletal/nbp1:fedora-40-arm64
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --annotation org.pulpproject.netboot.boot=shim.efi \
    --os linux --arch arm64 --os-version fedora-40 \
    --artifact quay.io/lzapletal/nbp1:fedora-40-arm64 ./work/*
podman manifest push quay.io/lzapletal/nbp1:fedora-40-arm64

podman manifest add --all --annotation org.pulpproject.netboot.version=1 quay.io/lzapletal/nbp1:fedora-40 \
    quay.io/lzapletal/nbp1:fedora-40-amd64 \
    quay.io/lzapletal/nbp1:fedora-40-arm64

podman manifest push --all quay.io/lzapletal/nbp1:fedora-40
