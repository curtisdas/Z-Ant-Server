FROM alpine:latest
# Set up environment variables for architecture detection
ARG TARGETARCH
# Install dependencies
RUN apk add --no-cache curl tar xz zip openssl openssl-dev
# Install Zig based on host architecture
RUN if [ "$TARGETARCH" = "amd64" ] || [ -z "$TARGETARCH" ]; then \
    curl -L https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz -o zig.tar.xz; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    curl -L https://ziglang.org/download/0.14.0/zig-linux-aarch64-0.14.0.tar.xz -o zig.tar.xz; \
    elif [ "$TARGETARCH" = "arm" ]; then \
    curl -L https://ziglang.org/download/0.14.0/zig-linux-armv7a-0.14.0.tar.xz -o zig.tar.xz; \
    else \
    echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    mkdir -p /usr/local/zig && \
    tar -xf zig.tar.xz -C /usr/local/zig --strip-components=1 && \
    rm zig.tar.xz
# Add Zig to PATH
ENV PATH="/usr/local/zig:${PATH}"
# Set up application directory
WORKDIR /app
# Copy the Zig source code into the container
COPY . .
# Build the Zig application
RUN zig build -Doptimize=ReleaseSafe