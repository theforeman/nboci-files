#!/usr/bin/python

import os
import json
import os.path

dry_run = True

# {
#     "Repository": "quay.io/lzapletal/nbp1",
#     "Tags": [
#         "fedora-40",
#         "fedora-40-amd64",
#         "fedora-40-arm64",
#         "latest"
#     ]
# }
def list_tags(repo):
    cmd = "skopeo list-tags docker://" + repo
    print(cmd)
    result = os.popen(cmd).read()
    parsed = json.loads(result)
    return parsed['Tags']

# {
#     "schemaVersion": 2,
#     "mediaType": "application/vnd.oci.image.index.v1+json",
#     "manifests": [
#         {
#             "mediaType": "application/vnd.oci.image.manifest.v1+json",
#             "size": 1854,
#             "digest": "sha256:e1ca7a9595bb9c2f62c6ae72e6d4bd999f74a24de708ba7ae6d02ec5f4a3b48e",
#             "platform": {
#                 "architecture": "amd64",
#                 "os": "linux",
#                 "os.version": "fedora-40"
#             },
#             "annotations": {
#                 "org.pulpproject.netboot.version": "1"
#             }
#         },
#         {
#             "mediaType": "application/vnd.oci.image.manifest.v1+json",
#             "size": 1854,
#             "digest": "sha256:0b6d12462cbab923b6b72d0614fabd04435cde7f0595a54e0bc9bef7385e3592",
#             "platform": {
#                 "architecture": "arm64",
#                 "os": "linux",
#                 "os.version": "fedora-40"
#             },
#             "annotations": {
#                 "org.pulpproject.netboot.version": "1"
#             }
#         }
#     ]
# }
def fetch_manifest(repo, tag, dst):
    cmd = "skopeo inspect --raw docker://" + repo + ":" + tag
    print(cmd)
    manifest = os.popen(cmd).read()
    parsed = json.loads(manifest)
    if parsed['schemaVersion'] != 2:
        raise Exception("Invalid schema version")
    if parsed['mediaType'] != "application/vnd.oci.image.index.v1+json":
        raise Exception("Invalid media type")
    
    for manifest in parsed['manifests']:
        if not 'annotations' in manifest or manifest['annotations']['org.pulpproject.netboot.version'] != "1":
            raise Exception("Missing org.pulpproject.netboot.version annotation")
        osver = manifest['platform']['os.version']
        arch = manifest['platform']['architecture']
        if osver == "":
            raise Exception("Missing platform.os.version")
        if arch == "":
            raise Exception("Missing platform.architecture")
        digest = manifest['digest']
        cache_name = os.path.join(dst, digest.split(":")[1])
        if os.path.exists(cache_name):
            print("manifest " + manifest['digest'] + " already downloaded")
            if not dry_run:
                continue
        dir = os.path.join(dst, osver, arch)
        print("downloading manifest " + manifest['digest'] + " to " + dir)
        fetch_image(repo, digest, dir)
        manifest_cache = json.dumps(manifest, indent=4)
        with open(cache_name, "w") as f:
            f.write(manifest_cache)

# {
#   "schemaVersion": 2,
#   "mediaType": "application/vnd.oci.image.manifest.v1+json",
#   "artifactType": "application/vnd.unknown.artifact.v1",
#   "config": {
#     "mediaType": "application/vnd.oci.empty.v1+json",
#     "digest": "sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
#     "size": 2,
#     "data": "e30="
#   },
#   "layers": [
#     {
#       "mediaType": "application/octet-stream",
#       "digest": "sha256:a3b7052d7b2f27ff73c677fde7e16e8664a2151f5bb0e6ade3a392c59f913557",
#       "size": 3972416,
#       "annotations": {
#         "org.opencontainers.image.title": "grubx64.efi"
#       }
#     },
#     ...
#   ]
# }
def fetch_image(repo, tag, dst):
    cmd = "skopeo inspect --raw docker://" + repo + "@" + tag
    print(cmd)
    manifest = os.popen(cmd).read()
    parsed = json.loads(manifest)
    if parsed['schemaVersion'] != 2:
        raise Exception("Invalid schema version")
    if parsed['mediaType'] != "application/vnd.oci.image.manifest.v1+json":
        raise Exception("Invalid media type")

    os.makedirs(dst, exist_ok=True)
    cmd = "skopeo copy docker://" + repo + "@" + tag + " dir:" + dst
    print(cmd)
    if not dry_run:
        os.system(cmd)
    for layer in parsed['layers']:
        if not 'annotations' in layer or not 'org.opencontainers.image.title' in layer['annotations']:
            raise Exception("Missing org.opencontainers.image.title annotation")
        title = layer['annotations']['org.opencontainers.image.title']
        digest = layer['digest']
        digest_without_prefix = digest.split(":")[1]
        if not os.path.exists(os.path.join(dst, title)):
            print("creating symlink " + title + " to " + digest_without_prefix)
            os.symlink(digest_without_prefix, os.path.join(dst, title))

def main():
    fetch_manifest("quay.io/lzapletal/nbp1", "fedora-40", "./test")

if __name__ == "__main__":
    main()
