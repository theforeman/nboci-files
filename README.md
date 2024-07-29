# Foreman netboot files

This repository contains scripts and instructions on how to download and prepare netboot files for Linux OS provisioning and upload them into OCI registry.

The repository is available at [quay.io/foreman/nboci-files](https://quay.io/repository/foreman/nboci-files).

## Required utilities

* `podman` version 5 or higner (push files)
* `skopeo` (pull files)
* `python` (pull files)

## Pushing files

Fetch files from upstream repositories. Example for Fedora OS:

    podman build -v $(pwd)/work:/root:Z -f Containerfile-fedora-amd64 --platform linux/amd64

Where the Containerfile looks like this:

```
FROM quay.io/fedora/fedora-minimal:40 as builder
ARG name=Fedora
ARG version=40
ARG arch=x64
WORKDIR /root

# Artifacts from kickstart repository.
RUN curl -RLO https://dl.fedoraproject.org/pub/fedora/linux/releases/${version}/Everything/$(uname -m)/os/images/pxeboot/vmlinuz
RUN curl -RLO https://dl.fedoraproject.org/pub/fedora/linux/releases/${version}/Everything/$(uname -m)/os/images/pxeboot/initrd.img
RUN curl -RLO https://dl.fedoraproject.org/pub/fedora/linux/releases/${version}/Everything/$(uname -m)/os/images/install.img

# Artifacts from RPM repository.
RUN microdnf -y install shim-${arch} grub2-efi-${arch} syslinux-tftpboot
RUN cp -p /tftpboot/pxelinux.0 . && cp -p /boot/efi/EFI/fedora/{shim,grub${arch}}.efi .
```

The downloaded files are now in `./work` directory. Create a new manifest and add these files:

```
podman manifest create quay.io/foreman/nboci-files:fedora-40
podman manifest create quay.io/foreman/nboci-files:fedora-40-amd64
podman manifest add --annotation org.pulpproject.netboot.version=1 \
    --os linux --arch amd64 --os-version fedora-40 \
    --artifact quay.io/foreman/nboci-files:fedora-40-amd64 ./work/*
podman manifest push quay.io/foreman/nboci-files:fedora-40-amd64

podman manifest add --all --annotation org.pulpproject.netboot.version=1 quay.io/foreman/nboci-files:fedora-40 \
    quay.io/foreman/nboci-files:fedora-40-amd64 \
```

Multiple architectures can be added into one manifest. The required annotation `org.pulpproject.netboot.version` must be present and set to `1`. Do not commit the files (e.g. `./work/*`) into the git repository.

An example shell script for pushing Fedora AMD64 and ARM64 netboot files is in `push-fedora-40.sh` which can serve as a template for other Red Hat based operating systems. It is recommended to commit those build scripts into the git repository.

## Naming conventions and requirements

* Architecture dependant tag (content manifest): `distro-version-arch`
* Architecture independant tag (index manifest): `distro-version`
* Content manifest operating system must be set to `linux`
* Content manifest operating system version must be set to `distro-version`
* Architecture name must follow the [OCI image index specification](https://github.com/opencontainers/image-spec/blob/main/image-index.md) (GOARCH)
* Both the content and the index manifests must have an annotation named `org.pulpproject.netboot.version` set to `1`
* All files must be added with filename annotation `org.opencontainers.image.title` (this is the podman's default behavior)

## Pulling files

Use the python script which calls `skopeo` command line utility to perform manifest fetching and content pulling:

```
./artifact-pull.py --help
usage: artifact-pull.py [-h] [--dry-run] [--destination DST] REPOSITORY

Extract images from a container repository

positional arguments:
  REPOSITORY            repository name with or without tag

options:
  -h, --help            show this help message and exit
  --dry-run, -n         do not download anything
  --destination DST, -d DST
                        destination directory
```

For example the following command:

    ./artifact-pull.py -d test quay.io/foreman/nboci-files

Creates the following structure:

```
$ tree test
test
├── 333146267ae2411eecde5fdaabb992e309b1114c271fb53472a56e52c7eaaa96
├── e5eeb77caed4f56ed1411e78fbb8a5a0bd50aca9824a765b5339b1a5780bc7b5
└── fedora-40
    ├── amd64
    │   ├── 09cf5df01619676e91e998fac6c456d67ec3cac25ee9244898b59699c588bb86
    │   ├── 44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a
    │   ├── 4723a6b6cf998f0571759569a18e390ba4be4df45dece95d0094a64f4e99a314
    │   ├── 4773d74d87c2371a25883b59a3b6d98d157de46933676706d215015b1130f2d1
    │   ├── 8ea1dd040e9725926ca2db5e30e0022f7c66c369b429b49336e7f95cdaf93ee7
    │   ├── a3b7052d7b2f27ff73c677fde7e16e8664a2151f5bb0e6ade3a392c59f913557
    │   ├── fff4b2feeef35b3a03487a9d38e2f17b2dbd8241325c805a5aece86bcaf4f23a
    │   ├── grubx64.efi -> a3b7052d7b2f27ff73c677fde7e16e8664a2151f5bb0e6ade3a392c59f913557
    │   ├── initrd.img -> 8ea1dd040e9725926ca2db5e30e0022f7c66c369b429b49336e7f95cdaf93ee7
    │   ├── install.img -> 4723a6b6cf998f0571759569a18e390ba4be4df45dece95d0094a64f4e99a314
    │   ├── manifest.json
    │   ├── pxelinux.0 -> fff4b2feeef35b3a03487a9d38e2f17b2dbd8241325c805a5aece86bcaf4f23a
    │   ├── shim.efi -> 4773d74d87c2371a25883b59a3b6d98d157de46933676706d215015b1130f2d1
    │   ├── version
    │   └── vmlinuz -> 09cf5df01619676e91e998fac6c456d67ec3cac25ee9244898b59699c588bb86
    └── arm64
        ├── 44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a
        ├── 57185f8b19ee9b41fafd9e79e0c61902ae9dd25230341c6eef4286923138f5a5
        ├── 73fb5456926a351a6bcf1c6869045825f94282e245b6a512086faa5aba16dd68
        ├── bb698e13aeb440cc89eca6db0b63e1883dfc22ac6cc1904419b03cd971514b93
        ├── f95dc2350aec25c789bd4cf51f025475616d2f38cdb9279e029c264dae695909
        ├── fdec6aeda80f40715b7de42d981828008e3fcd919516d4f0c7cc9bd2fd778c5d
        ├── grubaa64.efi -> 73fb5456926a351a6bcf1c6869045825f94282e245b6a512086faa5aba16dd68
        ├── initrd.img -> f95dc2350aec25c789bd4cf51f025475616d2f38cdb9279e029c264dae695909
        ├── install.img -> fdec6aeda80f40715b7de42d981828008e3fcd919516d4f0c7cc9bd2fd778c5d
        ├── manifest.json
        ├── shim.efi -> bb698e13aeb440cc89eca6db0b63e1883dfc22ac6cc1904419b03cd971514b93
        ├── version
        └── vmlinuz -> 57185f8b19ee9b41fafd9e79e0c61902ae9dd25230341c6eef4286923138f5a5

4 directories, 30 files
```

Under the destination directory, `fedora-40` was created which matches the `--os-version fedora-40` provided and underneeth subdirectories with architectures matching the `--arch` argument when creating the manifest with `podman`. At the lowest level, downloaded blobs are named after their digests and relative symlinks created. Finally, a `manifest.json` is also present.

In the destination directory, manifests stored as digest files are kept as a cache. This allows the tool to skip all downloaded operating systems so it can be used as a synchronization tool to quickly find only new content.

## Keep this clean

Warning: Do not push the files themselves into this git repository! This place
is only mean for scripts and instructions, upload files directly into the
registry.

All documented commands and scripts download to `work/` subdirectory. Make sure
to clean up after work is done.

Also, consider deleting old tags from the repository and perform garbage
collection regularly in order to keep the repository size within limits in the
registry.

## TODO

* Signing of artifacts
* Signature verification
