# Base stage with Alpine Linux
FROM alpine:3.18 AS base

# Install the necessary packages for building and RocksDB
RUN apk add --no-cache \
    rocksdb-dev \
    curl \
    git

### Electrum Rust Server ###
FROM base AS electrs-build

# Install cargo, clang, cmake, and other build dependencies
RUN apk add --no-cache \
    cargo \
    clang \
    cmake \
    build-base \
    linux-headers \
    git

# Set working directory and copy source code
WORKDIR /build

#Clone the repositroy into the path
RUN git clone --recurse-submodules --depth=1 https://github.com/romanz/electrs.git

#Open the repositroy
WORKDIR /build/electrs

# Set environment variables for RocksDB
ENV ROCKSDB_INCLUDE_DIR=/usr/include
ENV ROCKSDB_LIB_DIR=/usr/lib

# Build the electrs binary using Cargo
RUN cargo install --locked --path .

# Final stage: Copy the binary to a fresh Alpine base image
FROM base AS result

# Copy the electrs binary from the build stage
COPY --from=electrs-build /root/.cargo/bin/* /usr/bin/

# Set the working directory (if needed)
WORKDIR /

# Default entry point (if any is needed, customize as per your requirements)
CMD ["./usr/bin/electrs"]