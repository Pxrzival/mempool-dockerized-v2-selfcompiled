# Stage 1: Build stage
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

# Clone repository and set working directory
RUN git clone --recurse-submodules --depth=1 https://github.com/ElementsProject/elements.git
WORKDIR /elements

# Build the binary
RUN ./autogen.sh && \
    ./configure \
        --without-gui \
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

# Stage 2: Runtime stage
FROM debian:bookworm-slim AS final

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libevent-2.1-7 \
    libboost-system1.74.0 \
    libboost-filesystem1.74.0 \
    libevent-pthreads-2.1 \
    libboost-chrono1.74.0 \
    libboost-thread1.74.0 \
    libboost-program-options1.74.0 \
    libboost-test1.74.0 \
    libgmp10 \
    libzmq5 \
    libssl3 \
    libffi8 \
    zlib1g \
    sqlite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary from the build stage
COPY --from=builder /usr/local/bin/* /usr/local/bin/

# Default command to run the binary
ENTRYPOINT ["/usr/local/bin/elementsd", "-chain=liquidv1"]
