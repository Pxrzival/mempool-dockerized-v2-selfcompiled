# Use an Alpine image as the base
FROM alpine:3.18 AS builder

# Install necessary packages for building and running the project
RUN apk update && apk add --no-cache \
    git \
    make \
    g++ \
    libc-dev \
    curl

    # Install Go 1.22 manually
RUN curl -OL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz && \
tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz && \
rm go1.22.0.linux-amd64.tar.gz

# Set Go environment variables
ENV PATH="/usr/local/go/bin:$PATH"

# Set the working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/Pxrzival/bitcoind-exporter.git .

# Compile the project
RUN go build -o bitcoind-exporter

# Expose the port that the application will use
EXPOSE 9999

FROM alpine:3.18 AS final

COPY --from=builder /app/bitcoind-exporter /usr/bin/bitcoind-exporter

ENTRYPOINT [ "/usr/bin/bitcoind-exporter" ]