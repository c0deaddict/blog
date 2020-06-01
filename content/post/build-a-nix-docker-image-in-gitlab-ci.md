---
date: "2020-06-01T17:52:08+02:00"
draft: false
title: "Build a Nix docker image in Gitlab CI"
tags: ["nixos", "docker", "gitlab"]
topics: ["nixos"]
---

Frustrated with fetching, checksum checking, and extracting of the
packages in a Dockerfile that I need for a project, this week finally
found a way to build docker images with Nix. Embedded in `nixpkgs`
there are the functions `buildImage` and `buildLayeredImage`. With
these functions you can build docker images that are assembled from
Nix packages. How wonderful is that?

Here is the Nix derivation that I have used:

```nix
with import <nixpkgs> {};

pkgs.dockerTools.buildLayeredImage {
  name = "k8s-deployer";
  tag = "latest";
  created = "now";

  contents = with pkgs; [
    kubectl
    kubernetes-helm
    terraform
    yq
    jq
    bash
    coreutils # mkdir and such
    python3
    moreutils # for sponge
    git
    cacert
    curl
  ];

  extraCommands = ''
    mkdir -p usr/bin
    ln -sf ${pkgs.coreutils}/bin/env usr/bin/env
    mkdir tmp
    chmod 1777 tmp
  '';

  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "/";
  };
}
```

... and here is how to build it in Gitlab CI, and push it to the
Gitlab Container Registry:

```yaml
stages:
  - build

build:
  stage: build
  image: nixos/nix:latest
  script:
    # For pinning:
    # - export NIX_PATH="nixpkgs=https://github.com/NixOS/nixpkgs/archive/ab593d46dc38b9f0f23964120912138c77fa9af4.tar.gz"
    - nix-channel --update
    - nix-build -o image.tar.gz
    - |
      nix run nixpkgs.skopeo -c skopeo \
        --insecure-policy \
        copy \
        --dest-creds $CI_REGISTRY_USER:$CI_REGISTRY_PASSWORD \
        docker-archive:image.tar.gz \
        docker://$CI_REGISTRY_IMAGE:latest
```

This currently always builds from `unstable`, but by uncommenting the
line with `export NIX_PATH=...` you can pin to a specific Nixpkgs
version.

For more examples on how to use `buildImage` and `buildLayeredImage`
see [this link](https://github.com/NixOS/nixpkgs/blob/df928fafd47a6a6f446322d6e1545a71bb965fc6/pkgs/build-support/docker/examples.nix).
