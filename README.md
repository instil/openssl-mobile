# openssl-mobile

This repo provides scripts to build OpenSSL via the Conan, package them for the appropriate platforms and to provide cmake scripts for simple integration. Currently, the scripts support the following platforms.

* iOS 11+
* Android 5.0+
* macOS x86 & arm64
* Linux x86 & arm64

## Building From Source

### Prerequesites (macOS)

Assuming Homebrew is already installed, run the following to install the required dependencies and toolchains:

```
brew install conan
brew install --cask docker
open /Applications/Docker.app
```

### Run

To start building OpenSSL, you can simply run the following command:

```
./build.sh
```

The build script also supports the following arguments

```
--package: packages the headers and binaries into a zip file.
```

## Downloading Prebuilt Binaries

Run the following to download prebuilt binaries for all listed platforms. The script will download the release associated with the current commit you have checked out, otherwise it will download the latest release available.

```
./build.sh
```
