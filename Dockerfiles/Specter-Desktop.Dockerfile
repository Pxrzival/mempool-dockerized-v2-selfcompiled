# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

ARG USER=specter
ARG DIR=/data/

FROM python:3.10-slim-bullseye AS builder

ARG VERSION
ARG REPO

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential libusb-1.0-0-dev libudev-dev libffi-dev libssl-dev rustc cargo libpq-dev ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /specter-desktop

# Clone the repository that contains requirements.in and requirements.txt
RUN git clone https://github.com/cryptoadvance/specter-desktop.git . 

# Upgrade pip
RUN pip3 install --no-cache-dir --upgrade pip

# First, install pinned dependencies from requirements.txt
# Assuming requirements.txt is already in the repo
RUN pip3 install --no-cache-dir -r requirements.txt

# Now install the package itself
RUN pip3 install --no-cache-dir .

FROM python:3.10-slim-bullseye AS final

ARG USER
ARG DIR

RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev libudev-dev \
 && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN adduser --disabled-password \
            --home "$DIR" \
            --gecos "" \
            "$USER"

USER $USER

# Make config directory
RUN mkdir -p "$DIR/.specter/"

# Copy over installed Python environment from builder
COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin

# Expose ports
EXPOSE 25441 25442 25443

ENTRYPOINT ["/usr/local/bin/python3", "-m", "cryptoadvance.specter", "server", "--host", "0.0.0.0"]
