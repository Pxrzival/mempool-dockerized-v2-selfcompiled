#Stage 1: Build stage
FROM debian:bookworm-slim AS builder

# Install dependencies for building
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
        build-essential \
        autoconf \
        automake \
        libtool \
        libevent-dev \
        pkg-config \
        libboost-all-dev \
        libgmp-dev \
        libzmq3-dev \
        python3 \
        libssl-dev \
        libffi-dev \
        zlib1g-dev \
        sqlite3 \
        git
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*

# Clone repository and set working directory
RUN git clone --recurse-submodules --depth=1 https://github.com/ElementsProject/elements.git

WORKDIR /elements

# Set build flags
#ENV LDFLAGS="-L/usr/lib"
#ENV LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"

# Build the binary
RUN ./autogen.sh && \
    ./configure \
        --without-gui \
        --disable-upnp-default \
        --disable-natpmp \
        --disable-wallet \
        --disable-ccache \
        --disable-dependency-tracking \
        --disable-gui-tests \
        --enable-reduce-exports \
        --disable-bench \
        --disable-tests \
        CFLAGS="-O2 -g0 -fPIC" \
        CXXFLAGS="-O2 -g0 -fPIC" \
        LDFLAGS="-s -Wl,-O2"

RUN make -j"$(nproc)" && \
    make -j"$(nproc)" install
    
    # Stage 2: Runtime stage with Alpine
FROM debian:bookworm-slim AS final
    
    # Copy the binary from the build stage
COPY --from=builder /usr/local/bin/* /usr/local/bin/
    
# Default command to run the binary
ENTRYPOINT ["/usr/local/bin/elementsd", "-chain=liquidv1", "-print-to-console"]
