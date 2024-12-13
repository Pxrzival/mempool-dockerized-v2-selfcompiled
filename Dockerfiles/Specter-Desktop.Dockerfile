# Builder stage
FROM python:3.10-slim-bullseye AS builder

# Install build dependencies and system libraries required for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential libusb-1.0-0-dev libudev-dev libffi-dev libssl-dev rustc cargo libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Clone your project or copy it in
# If you have your repository locally, you can use COPY instead:
# COPY . .
RUN git clone https://github.com/cryptoadvance/specter-desktop.git specter-desktop
WORKDIR /app/specter-desktop

# Upgrade pip and install dependencies
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir .

# Final stage
FROM python:3.10-slim-bullseye AS final

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev libudev-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USER=specter
ARG DIR=/data/
RUN adduser --disabled-password --home "$DIR" --gecos "" "$USER"
USER $USER

# Make config directory
RUN mkdir -p "$DIR/.specter/"

# Copy over the virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Expose the ports
EXPOSE 25441 25442 25443

# Start the application
ENTRYPOINT ["python", "-m", "cryptoadvance.specter", "server", "--host", "0.0.0.0"]
