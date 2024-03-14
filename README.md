# Foreman netboot files generators

This repository contains scripts and instructions on how to download and
prepare netboot files for Linux OS provisioning and upload them into OCI
registry via [nboci](https://github.com/osbuild/nboci) utility.

The repository is available at [quay.io/foreman/nboci-files](https://quay.io/repository/foreman/nboci-files).

## Required utilities

* [nboci](https://github.com/osbuild/nboci)
* [cosign](https://github.com/sigstore/cosign)
* `rpm2cpio`
* `cpio`
* `curl`
* `jq`

## Keep this clean

Warning: Do not push the files themselves into this git repository! This place
is only mean for scripts and instructions, upload files directly into the
registry.

All documented commands and scripts download to `work/` subdirectory. Make sure
to clean up after work is done.

Also, consider deleting old tags from the repository and perform garbage
collection regularly in order to keep the repository size within limits in the
registry.

## Foreman nboci-files registry

In order to upload or sign OCI artifacts, you need to have a valid account on
`quay.io` with permissions for `quay.io/foreman/nboci-files`. All upload/sign
commands assume you are signed in:

    nboci login quay.io/foreman/nboci-files
    cosign login quay.io/foreman/nboci-files

## Fedora and Red Hat compatible Linux

Download kernel, initramdisk and stage2 image:

    VERSION=39
    curl -L -O --output-dir work/ "https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Everything/x86_64/os/images/pxeboot/vmlinuz"
    curl -L -O --output-dir work/ "https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Everything/x86_64/os/images/pxeboot/initrd.img"
    curl -L -O --output-dir work/ "https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Everything/x86_64/os/images/install.img"

Download and extract shim:

    ./extract-rpm.sh \
        boot/efi/EFI/fedora/shim.efi \
        "https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Everything/x86_64/os/Packages/s/shim-x64-15.6-2.x86_64.rpm"

Download and extract grub:

    ./extract-rpm.sh \
        boot/efi/EFI/fedora/grubx64.efi \
        "https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Everything/x86_64/os/Packages/g/grub2-efi-x64-2.06-100.fc39.x86_64.rpm"

Download and extract pxelinux:

    ./extract-rpm.sh \
        tftpboot/pxelinux.0 \
        "https://download.fedoraproject.org/pub/fedora/linux/releases/$VERSION/Everything/x86_64/os/Packages/s/syslinux-tftpboot-6.04-0.25.fc39.noarch.rpm"

The `work/` directory should look as follows:

    ls work/
    grubx64.efi  initrd.img  install.img  pxelinux.0  shim.efi  vmlinuz

## Uploading files

Before uploading, double check the contents of the `work/` directory and make
sure you signed into `quay.io`.

Upload the files into Foreman nboci-files container registry:

    nboci --verbose push --repository quay.io/foreman/nboci-files \
        --osname fedora \
        --osversion 39 \
        --osarch x86_64 \
        --entrypoint shim.efi \
        --alt-entrypoint grubx64.efi \
        --legacy-entrypoint pxelinux.0 \
        work/*

Store the generated manifest for record purposes into `manifest` subdirectory and push this change into the git repo:

    skopeo inspect --raw docker://quay.io/foreman/nboci-files:fedora-39-x86_64 | jq > manifests/fedora-39-x86_64

## Signing files

In order to digitally sign any artifacts, you need to get `cosign.key` file and passphrase. To sign the tag:

    cosign sign --key cosign.key -y quay.io/foreman/nboci-files:fedora-39-x86_64

## Pulling files

To pull files from OCI repository, only the `nboci` utility is needed as it
integrates all the required features from `oras` and `cosign` libraries.  To
verify digital signature and pull all files or files from specific tag, do:

    nboci pull --destination /tmp/test -k cosign.pub quay.io/foreman/nboci-files:fedora-39-x86_64
    downloading /tmp/test/fedora/39/x86_64/grubx64.efi
    downloading /tmp/test/fedora/39/x86_64/initrd.img
    downloading /tmp/test/fedora/39/x86_64/install.img
    downloading /tmp/test/fedora/39/x86_64/pxelinux.0
    downloading /tmp/test/fedora/39/x86_64/shim.efi
    downloading /tmp/test/fedora/39/x86_64/vmlinuz

The utility checks file sha sums and only re-downloads files w hich are missing or corrupt.
