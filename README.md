# docker-build-s3fs

#### Reproducible VeraCrypt build for Ubuntu 18.04 with Docker

## Downloads

It's best to always check the [VeraCrypt official downloads](https://www.veracrypt.fr/en/Downloads.html) in case a more recent version has been released.

### [Download the resulting binary and applicable licenses](builds/VeraCrypt_1.24-Update4) (rendered from [VeraCrypt_1.24-Update4](https://github.com/veracrypt/VeraCrypt/tree/VeraCrypt_1.24-Update4) release).

It's also recommended that you verify [your preferred checksum](#checksums).

## Links

- GitHub: https://github.com/maresb/docker-build-veracrypt
- Docker Hub: https://hub.docker.com/repository/docker/maresb/docker-build-veracrypt
- VeraCrypt GitHub: https://github.com/veracrypt/VeraCrypt
- VeraCrypt official downloads: https://www.veracrypt.fr/en/Downloads.html

## Legal

This Dockerfile is copyright © 2020 Ben Mares.  (For details, see [LICENSE](LICENSE).)  It builds VeraCrypt from source code. I am in no way affiliated with VeraCrypt, IDRIX or wxWidgets.

By using this Dockerfile, you agree to the terms of the following licenses.

Veracrypt is copyright © 2013-2019 IDRIX, with contributions from several others.  For details, see the [VeraCrypt License](VeraCrypt_License.txt).

VeraCrypt uses the wxWidgets library, which is copyright © 1998-2011 Julian Smart, Robert Roebling et al.  For details, see the [wxWindows Library License](wxWindows_Library_License.txt).


## Introduction

Since there is no official VeraCrypt binary for Ubuntu 18.04, users must either find a binary which they trust, or compile from source.  Trust is a touchy subject when it comes to encryption software (see [Motivation](#motivation)). Compiling from source is time-consuming and disk-consuming.  But thanks to Docker, you can easily verify my build by reproducing it yourself.

## Motivation

When it comes to encryption software, it's difficult to be too careful. (For example, I'd recommend reading about both Crypto AG and the suspicious end of TrueCrypt.)  Even for the official VeraCrypt downloads, there doesn't seem to be a good way to verify that those binaries actually correspond to the source code available on GitHub.  I find it more reassuring to compile from publicly available source code.  (Even if the source code is fine, that is no guarantee that the compiled binary is safe; for example, see "Reflections on Trusting Trust" by Ken Thompson.)

## Challenge

There is only one real subtlety to achieving a reproducible build for VeraCrypt.  That is, that the wxWidgets 3.0 dependency uses the `__DATE__` and `__TIME__` preprocessor macros to store the compile time.  Version 3.1.1 of wxWidgets [introduced a reproducible build mode](https://github.com/wxWidgets/wxWidgets/commit/2f8a343b225e68d62f53c0908560f92b194a49c9), however VeraCrypt is only compatible with 3.0.  As a simple workaround, I replace all occurrences of `__DATE__` and `__TIME__` with a fixed value before preprocessing.

Note: Perhaps it's possible to compile VeraCrypt against some `libwx` package from Ubuntu?  (I tried briefly but was unsuccessful.)

## Build VeraCrypt with Docker

### 1. Compile under Docker.

Complete either a) or b) below.

**a) Either compile locally**

Download `Dockerfile` and change to the corresponding directory.

```
git clone https://github.com/maresb/docker-build-veracrypt.git && cd docker-build-veracrypt
```

Then build VeraCrypt.

```
docker build -t build-veracrypt .
```

**b) Or grab a premade image from Docker Hub**

Pull the image from Docker Hub and retag:
```
docker pull maresb/docker-build-veracrypt
docker image tag maresb/docker-build-veracrypt build-veracrypt
docker rmi maresb/docker-build-veracrypt
```

### 2. Copy the licenses and executables from the image via a temporary container.
```
id=$(docker create build-veracrypt)
docker cp $id:veracrypt .
docker cp $id:veracrypt_nogui .
docker cp $id:VeraCrypt_License.txt .
docker cp $id:wxWindows_Library_License.txt .
docker rm -v $id
```

### 3. Clean up (optional).

```
docker rmi build-veracrypt
docker purge
```

### For debugging,

If the image successfully builds, you can tag the build stage and look inside with
```
docker build -t build-veracrypt:build --target build .
docker run --rm -it build-veracrypt:build /bin/bash
```
Otherwise, in the output of a partial build, look for a line with an arrow directly followed by a hash such as
```
 ---> df7f92f1a162
```
Then you can look inside the image at the corresponding point with
```
docker run --rm -it df7f92f1a162 /bin/bash
```

## Install any missing Ubuntu libraries

In case you are missing any libraries, the following command should install them.

Normal version:
```
sudo apt-get install --no-install-recommends libfuse2 libgtk2.0-0 libsm6
```

No-GUI version:
```
sudo apt-get install --no-install-recommends libfuse2
```

## Give it a try

By running VeraCrypt, you [agree to the licenses](#legal).

You should now be able to run `./veracrypt`, but you should
verify the checksums below.

## Install

You can install VeraCrypt with

```
sudo chmod a+x veracrypt
sudo mv veracrypt /usr/bin/veracrypt
```

To download and install the shortcut and icon,
```
sudo wget -O /usr/share/applications/veracrypt.desktop https://raw.githubusercontent.com/veracrypt/VeraCrypt/master/src/Setup/Linux/veracrypt.desktop
sudo wget -O /usr/share/pixmaps/veracrypt.xpm https://raw.githubusercontent.com/veracrypt/VeraCrypt/master/src/Resources/Icons/VeraCrypt-256x256.xpm
```

# Checksums

### `veracrypt` size and checksum

    $ stat --printf="%s bytes\n" veracrypt
    7627528 bytes

    $ md5sum veracrypt
    97dedcb794032bbd37b3f1553511bba7  veracrypt

    $ sha256sum veracrypt
    fe58f41776b24b386694baa92e5ce1cfc8c53dd31e222a0aa714536ee4fb0e66  veracrypt

    $ b2sum veracrypt
    a37129c1c5790159a5fff4766b2a674e8555fb13d2b42b33eb475233122f45c16b8824e5e8370bd75cfbc976e98c4bbd3e26bc5e7bac21eafadf5798ca4d1fae  veracrypt

### `veracrypt_nogui` size and checksum

    $ stat --printf="%s bytes\n" veracrypt_nogui
    3104200 bytes

    $ md5sum veracrypt_nogui
    c2e9a595f6d768acb0d1476cc7e41002  veracrypt_nogui

    $ sha256sum veracrypt_nogui
    f303c1035c4d2f38af026d0bb4945bd61e94a4726151af5cdb260859940db230  veracrypt_nogui

    $ b2sum veracrypt_nogui
    d532f832964d46a883b26e0d7ad27c1bee56398b7435f0c3923de0901a0e12801b36c447a542e3d4782e87009d53e7c291b91d10d18c2ebab3bf023742433ef1  veracrypt_nogui
