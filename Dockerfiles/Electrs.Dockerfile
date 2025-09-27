# Base stage using Debian to provide glibc and RocksDB
FROM debian:trixie-slim AS base

RUN apt-get update -qqy \
 && apt-get install -qqy --no-install-recommends \
    librocksdb-dev \
    curl \
    ca-certificates \
    git \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

### Electrum Rust Server ###
FROM base AS electrs-build

# Build dependencies and Cargo from Debian (supports Cargo.lock v4)
RUN apt-get update -qqy \
 && apt-get install -qqy --no-install-recommends \
    cargo \
    build-essential \
    libclang-dev \
 && rm -rf /var/lib/apt/lists/*

# Fetch source from upstream GitHub (no local COPY)
WORKDIR /build
RUN git clone --recurse-submodules --depth=1 https://github.com/romanz/electrs.git
WORKDIR /build/electrs

# Environment for RocksDB
ENV ROCKSDB_INCLUDE_DIR=/usr/include
ENV ROCKSDB_LIB_DIR=/usr/lib

# Build and install electrs
RUN cargo install --locked --path .

# Final stage: thin Debian runtime with glibc
FROM base AS result

# Copy the electrs binary from the build stage
COPY --from=electrs-build /root/.cargo/bin/electrs /usr/bin/electrs

WORKDIR /
CMD ["electrs"]