# HiQ-Deployment

This repository houses the build scripts needed to create binary and source packages for Huawei HiQ software. It
currently holds build scripts for Mac OS and Fedora (and related Linux distros) for the following HiQ pieces of
software:

- HiQ ProjectQ (Quantum computing compiler and optimizer)
- HiQ Circuit (High performance MPI simulator backend for HiQ ProjectQ)


# Status

| Project      | Mac OS Homebrew | Mac OS MacPorts | Linux (RPM) | Linux (AUR) | Linux (DEB) | Windows (Chocolatey) |
|--------------|-----------------|-----------------|-------------|-------------|-------------|----------------------|
| HiQ ProjectQ | ✅              | ❌ (planned)    | ✅          | ✅          | ✅          | ❌                   |
| HiQ Circuit  | ✅              | ❌ (planned)    | ✅          | ✅          | ✅          | ❌                   |

# Table of contents

Here are some links to other README files within this repository

  - [AUR (ArchLinux) packages](aur/README.md)
  - [DEB packaging](deb/README.md)
  - [Mac OS Homebrew](Formula/README.md)
  - [RPM packaging](rpm/README.md)
