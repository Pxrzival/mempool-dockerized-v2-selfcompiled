# Stage 1: Build stage using alpine as a base image
FROM alpine AS build

# Install required dependencies for building Bitcoin
RUN apk --no-cache add autoconf automake libtool boost-dev libevent-dev libffi-dev openssl-dev bash coreutils git cmake && \
    apk --no-cache add --update alpine-sdk build-base curl

# Define the Bitcoin version to build (default is version 26.2)
ARG VERSION=26.2

# Clone the specific version of the Bitcoin source code from the official repository
RUN git clone --depth 1 https://github.com/bitcoin/bitcoin.git --branch v$VERSION --single-branch

# Set the working directory to /bitcoin
WORKDIR /bitcoin

# Build the Bitcoin dependencies, excluding QT (for GUI)
RUN cd /bitcoin/depends; make NO_QT=1

# Download, verify, and install zlib (a compression library needed for the build)
RUN wget https://zlib.net/zlib-1.3.1.tar.gz && \
    echo "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23  zlib-1.3.1.tar.gz" | sha256sum -c && \
    mkdir -p /usr/src/zlib; tar zxvf zlib-1.3.1.tar.gz -C /usr/src && \
    cd /usr/src/zlib-1.3.1; ./configure; make -j"$(($(nproc)+1))"; make -j"$(($(nproc)+1))" install

# Configure the build environment and disable unnecessary features for a leaner Bitcoin build
RUN export CONFIG_SITE=/bitcoin/depends/$(/bitcoin/depends/config.guess)/share/config.site && \
    cd /bitcoin; ./autogen.sh; \
    ./configure --disable-ccache \
    --disable-maintainer-mode \
    --disable-dependency-tracking \
    --enable-reduce-exports --disable-bench \
    --disable-tests \
    --disable-gui-tests \
    --without-gui \
    --without-miniupnpc \
    CFLAGS="-O2 -g0 --static -static -fPIC" \
    CXXFLAGS="-O2 -g0 --static -static -fPIC" \
    LDFLAGS="-s -static-libgcc -static-libstdc++ -Wl,-O2"

# Compile and install Bitcoin with parallel jobs, using one more than the number of available processors
RUN make -j"$(($(nproc)+1))" && \
    make -j"$(($(nproc)+1))" install

# Stage 2: Final stage for the runtime environment
FROM alpine:latest

# Copy the compiled Bitcoin binaries and libraries from the build stage to the final image
COPY --from=build /usr/local /usr/local

# Copy the Bitcoin configuration file from the build stage to the final image
COPY --from=build /bitcoin/share/examples/bitcoin.conf /.bitcoin/bitcoin.conf

# Declare the /.bitcoin directory as a volume to store Bitcoin blockchain data and config
VOLUME ["/.bitcoin"]

# Expose Bitcoin's network ports for peer-to-peer communication, RPC, and testnet
EXPOSE 8332 8333 18332 18333 18444

# Set the entry point to run Bitcoin as a daemon and log output to the console
ENTRYPOINT ["/usr/local/bin/bitcoind", "-printtoconsole"]
