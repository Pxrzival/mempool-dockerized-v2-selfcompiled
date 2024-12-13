FROM ubuntu:22.04 AS builder

ARG USER=specter
ARG DIR=/data/

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential libusb-1.0-0-dev libudev-dev libffi-dev libssl-dev \
    rustc cargo libpq-dev ca-certificates python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /specter-desktop
RUN git clone https://github.com/cryptoadvance/specter-desktop.git .

RUN python3 -m pip install --no-cache-dir --upgrade pip

# Ensure you have requirements.txt in the repo
RUN python3 -m pip install --no-cache-dir -r requirements.txt
RUN python3 -m pip install --no-cache-dir .

FROM ubuntu:22.04 AS final

ARG USER=specter
ARG DIR=/data/

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev libudev-dev python3 python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --home "$DIR" --gecos "" "$USER"

USER $USER
RUN mkdir -p "$DIR/.specter/"

COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin

EXPOSE 25441 25442 25443

ENTRYPOINT ["/usr/local/bin/python3", "-m", "cryptoadvance.specter", "server", "--host", "0.0.0.0"]
