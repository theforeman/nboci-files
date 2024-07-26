# Foreman netboot files generators

This repository contains scripts and instructions on how to download and
prepare netboot files for Linux OS provisioning and upload them into OCI
registry.

The repository is available at [quay.io/foreman/nboci-files](https://quay.io/repository/foreman/nboci-files).

THIS IS WORK IN PROGRESS

## Required utilities

* `podman` version 5 or higner
* `skopeo`
* `python`

## Keep this clean

Warning: Do not push the files themselves into this git repository! This place
is only mean for scripts and instructions, upload files directly into the
registry.

All documented commands and scripts download to `work/` subdirectory. Make sure
to clean up after work is done.

Also, consider deleting old tags from the repository and perform garbage
collection regularly in order to keep the repository size within limits in the
registry.

## Pushing files

`bash -x create.sh`

## Pulling files

`python extract.sh`
