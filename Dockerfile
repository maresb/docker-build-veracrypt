FROM ubuntu:18.04 AS build

LABEL maintainer="Ben Mares <services-docker-build-veracrypt@tensorial.com>" \
      name="docker-build-veracrypt" \
      url="https://github.com/maresb/docker-build-veracrypt" \
      vcs-url="https://github.com/maresb/docker-build-veracrypt"

# Install prerequisites
RUN : \
 && apt-get update \
 && apt-get install -y \
      libfuse-dev \
      yasm \
      build-essential \
      git \
      wget \
      pkg-config \
      libgtk2.0-dev \
;

# Build as a user, not as root.
RUN useradd -m builder
USER builder
WORKDIR /home/builder

# wxWidgets release number and corresponding SHA1SUM
ARG WXWIDGETS_VERSION=3.0.4
ARG WXWIDGETS_SHA1SUM=246561a73ec5b9a5a7aaaaed46b64515dc9039ab

# Download, verify and extract wxWidgets release
RUN : \
 && wget https://github.com/wxWidgets/wxWidgets/releases/download/v${WXWIDGETS_VERSION}/wxWidgets-${WXWIDGETS_VERSION}.tar.bz2 \
 && echo "${WXWIDGETS_SHA1SUM} wxWidgets-${WXWIDGETS_VERSION}.tar.bz2" | sha1sum --check \
 && tar -xjf wxWidgets-${WXWIDGETS_VERSION}.tar.bz2 \
 && rm wxWidgets-${WXWIDGETS_VERSION}.tar.bz2 \
 && mv wxWidgets-${WXWIDGETS_VERSION} wxWidgets \
;

# id of the Veracrypt commit to download
ARG COMMIT_ID=VeraCrypt_1.24-Update4
RUN :  \
 && wget -O veracrypt.tgz https://github.com/veracrypt/VeraCrypt/tarball/$COMMIT_ID \
 && tar xzvf veracrypt.tgz \
 && rm veracrypt.tgz \
 && mv veracrypt* veracrypt \
;

# Optional: Compare GitHub download with PGP-signed source from www.veracrypt.fr.
ARG VERACRYPT_SOURCE_URL=https://launchpad.net/veracrypt/trunk/1.24-update4/+download/VeraCrypt_1.24-Update4_Source.tar.bz2
ARG VERACRYPT_FINGERPRINT=5069A233D55A0EEB174A5FC3821ACD02680D16DE
ARG PGP_SERVER=pgpkeys.mit.edu
RUN : \
 # Download PGP keys from keyserver
   && gpg --keyserver $PGP_SERVER --recv-keys $VERACRYPT_FINGERPRINT \
 # Download source and signature
   && wget $VERACRYPT_SOURCE_URL \
   && wget $VERACRYPT_SOURCE_URL.sig \
 # Verify signature of source download
   && gpg --verify *.sig \
 # Extract source
   && mkdir veracrypt_bz2 \
   && tar -xf *.bz2 -C veracrypt_bz2 \
 # Compare source
   # Write differences to files
     && diff -qr veracrypt_bz2 veracrypt > diff.txt \
   # Verify that the file exists and is not empty
     && test -f diff.txt && test ! -s diff.txt \
   # Clean up
     && rm -rf *.bz2 *.sig *.txt veracrypt_bz2 \
;

# make wxWidgets (NOGUI)
RUN :  \
 # Replace preprocessor macros to achieve build reproducibility
   && find ~/wxWidgets/ -type f | xargs sed -i 's/__DATE__/\"Mar 13 2020\"/g' \
   && find ~/wxWidgets/ -type f | xargs sed -i 's/__TIME__/\"00:00:00\"/g' \
 && cd veracrypt/src \
 && make NOGUI=1 WXSTATIC=1 WX_ROOT=/home/builder/wxWidgets wxbuild \
;

# make VeraCrypt (NOGUI)
RUN : \
 && cd veracrypt/src \
 && make NOGUI=1 WXSTATIC=1 \
 && mv Main/veracrypt Main/veracrypt_nogui \
;

# make wxWidgets
RUN :  \
 && cd veracrypt/src \
 && make clean \
 && make WXSTATIC=1 WX_ROOT=/home/builder/wxWidgets wxbuild \
;

# make VeraCrypt
RUN : \
 && cd veracrypt/src \
 && make clean \
 && make WXSTATIC=1 \
;

COPY print_checksums.sh /home/builder/
RUN bash print_checksums.sh

# Copy the binary into an empty container
FROM scratch as binary-only
COPY --from=build /home/builder/veracrypt/src/Main/veracrypt ./
COPY --from=build /home/builder/veracrypt/src/Main/veracrypt_nogui ./
COPY --from=build /home/builder/veracrypt/License.txt ./VeraCrypt_License.txt
COPY --from=build /home/builder/wxWidgets/docs/licence.txt ./wxWindows_Library_License.txt

# Prevent the error: "Error response from daemon: No command specified"
CMD nothing
