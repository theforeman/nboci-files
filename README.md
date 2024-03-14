# Foreman netboot files generators

This repository contains scripts and instructions on how to download and
prepare netboot files for Linux OS provisioning and upload them into OCI
registry via [nboci](https://github.com/osbuild/nboci) utility.

## Keep this clean

Warning: Do not push the files themselves into this git repository! This place
is only mean for scripts and instructions, upload files directly into the
registry.

All documented commands and scripts download to `work/` subdirectory. Make sure
to clean up after work is done.

# Fedora and Red Hat compatible Linux

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
